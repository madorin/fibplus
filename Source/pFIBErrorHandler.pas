{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ InterBase databases                                           }
{                                                               }
{    FIBPlus is based in part on the product                    }
{    Free IB Components, written by Gregory H. Deatz for        }
{    Hoagland, Longo, Moran, Dunst & Doukas Company.            }
{    mailto:gdeatz@hlmdd.com                                    }
{                                                               }
{    Copyright (c) 1998-2007 Devrace Ltd.                       }
{    Written by Serge Buzadzhy                                  }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit pFIBErrorHandler;

interface

{$I FIBPlus.inc}

uses
  SysUtils, Classes, Contnrs, SyncObjs, fib, FIBDatabase, pFIBDatabase, IB_ErrorCodes,
  ibase, IB_Intf, IB_Externals, DB, pFIBDataInfo, FIBQuery;

type

  TOptionErrorHandler = (oeException, oeForeignKey, oeLostConnect, oeCheck, oeUniqueViolation);
  TKindIBError = (
    keNoError,
    keException,
    keForeignKey,
    keLostConnect,
    keSecurity,
    keCheck,
    keUniqueViolation,
    keOther,
    keStatementTimeout,
    keCancelled
  );

  TOnFIBErrorEvent = procedure(Sender: TObject; ErrorValue: EFIBError; KindIBError: TKindIBError; var DoRaise: boolean) of object;

  TOptionsErrorHandler = set of TOptionErrorHandler;

  TErrorLexems = class(TPersistent)
  private
    FConstraint: string;
    FIndex: string;
    FException: string;
    FAt: string;
    function StoredConstraintProp: boolean;
    function StoredIndexProp: boolean;
    function StoredExceptionProp: boolean;
    function StoredAtProp: boolean;
  public
    constructor Create;
    procedure Assign(Source: TPersistent); override;
  published
    property Constraint: string read FConstraint write FConstraint stored StoredConstraintProp;
    property Index: string read FIndex write FIndex stored StoredIndexProp;
    property Exception: string read FException write FException stored StoredExceptionProp;
    property At: string read FAt write FAt stored StoredAtProp;
  end;

  // The error last handled in a thread, internal to TpFibErrorHandler
  TFIBHandledError = class
  public
    ThreadID: Cardinal;
    Kind: TKindIBError;
    ConstraintName: string;
    ExceptionName: string;
    ExceptionNumber: Integer;
  end;

  TpFibErrorHandler = class(TComponent)
  private
    FOnFIBErrorEvent: TOnFIBErrorEvent;
    FOptions: TOptionsErrorHandler;
    FErrorLexems: TErrorLexems;
    FHandledErrors: TObjectList; // TFIBHandledError per thread, under FHandledErrorsLock
    FHandledErrorsLock: TCriticalSection;
    FNoHandledError: TFIBHandledError;
    function CurrentHandledError(CanCreate: Boolean): TFIBHandledError;
    procedure DefaultOnError(Sender: TObject; ErrorValue: EFIBError; HandledError: TFIBHandledError;
      var DoRaise: Boolean);
    function ErrorConstraintName(Sender: TObject; ErrorValue: EFIBError): string;
    function GetConstraintName: string;
    function GetExceptionName: string;
    function GetExceptionNumber: Integer;
    function GetLastError: TKindIBError;
    function GetTr(Sender: TObject): TFIBTransaction;
    function MessageConstraintName(const Msg: string): string;
    function RepositoryMessage(Sender: TObject; const ConstraintName: string): string;
    procedure SetErrorLexems(const Value: TErrorLexems);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure DoOnErrorEvent(Sender: TObject; ErrorValue: EFIBError; var DoRaise: Boolean); dynamic; // for internal use
    procedure DoOnLostConnect(DataBase: TFIBDatabase; ErrorValue: EFIBError; var DoRaise: boolean);
    // The error last handled in the calling thread
    property ExceptionNumber: Integer read GetExceptionNumber;
    property LastError: TKindIBError read GetLastError;
    property ConstraintName: string read GetConstraintName;
    property ExceptionName: string read GetExceptionName;
  published
    property OnFIBErrorEvent: TOnFIBErrorEvent read FOnFIBErrorEvent write FOnFIBErrorEvent;
    property Options: TOptionsErrorHandler read FOptions write FOptions default [oeException, oeLostConnect];
    property ErrorLexems: TErrorLexems read FErrorLexems write SetErrorLexems;
  end;

function IsConnectionLost(const IBErrorCode: integer): boolean;
// The database of the object that raised an error, nil when unknown
function FindDatabaseForObject(Sender: TObject): TFIBDatabase;

implementation

uses
  FIBConsts, FIBMiscellaneous, FIBPlatforms, StrUtil{$IFDEF SUPPORT_ARRAY_FIELD}, pFIBArray{$ENDIF};

threadvar
  InRepositoryLookup: Boolean;
  // False in a new thread, which can get the ID, and so the entry, of a finished one
  ErrorHandledInThread: Boolean;

constructor TpFibErrorHandler.Create(AOwner: TComponent);
begin
  if ErrorHandlerRegistered and not(csDesigning in ComponentState) then
    raise Exception.Create(SFIBErrorHandlerExists);
  inherited Create(AOwner);
  FHandledErrors := TObjectList.Create;
  FHandledErrorsLock := TCriticalSection.Create;
  FNoHandledError := TFIBHandledError.Create;
  FNoHandledError.ExceptionNumber := -1;
  RegisterErrorHandler(Self);
  Options := [oeException, oeLostConnect];
  FErrorLexems := TErrorLexems.Create;
end;

destructor TpFibErrorHandler.Destroy;
begin
  UnRegisterErrorHandler(Self);
  FErrorLexems.Free;
  FHandledErrors.Free;
  FHandledErrorsLock.Free;
  FNoHandledError.Free;
  inherited Destroy;
end;

// The entry of a finished thread stays until the handler is freed and is reused with its thread ID
function TpFibErrorHandler.CurrentHandledError(CanCreate: Boolean): TFIBHandledError;
var
  ThreadID: Cardinal;
  I: Integer;
begin
  Result := FNoHandledError;
  if not (CanCreate or ErrorHandledInThread) then
    Exit;
  ErrorHandledInThread := True;
  ThreadID := CurrentThreadID;
  FHandledErrorsLock.Acquire;
  try
    for I := 0 to FHandledErrors.Count - 1 do
    begin
      Result := TFIBHandledError(FHandledErrors[I]);
      if Result.ThreadID = ThreadID then
        Exit;
    end;
    if CanCreate then
    begin
      Result := TFIBHandledError.Create;
      Result.ThreadID := ThreadID;
      FHandledErrors.Add(Result);
    end
    else
      Result := FNoHandledError;
  finally
    FHandledErrorsLock.Release;
  end;
end;

function TpFibErrorHandler.GetConstraintName: string;
begin
  Result := CurrentHandledError(False).ConstraintName;
end;

function TpFibErrorHandler.GetExceptionName: string;
begin
  Result := CurrentHandledError(False).ExceptionName;
end;

function TpFibErrorHandler.GetExceptionNumber: Integer;
begin
  Result := CurrentHandledError(False).ExceptionNumber;
end;

function TpFibErrorHandler.GetLastError: TKindIBError;
begin
  Result := CurrentHandledError(False).Kind;
end;

function IsConnectionLost(const IBErrorCode: integer): boolean;
begin
  case IBErrorCode of
    isc_shutdown, isc_network_error, isc_lost_db_connection,
    // isc_net_connect_err,
    isc_net_connect_listen_err, isc_net_event_connect_err,
      isc_net_event_listen_err, isc_net_read_err, isc_net_write_err, isc_att_shutdown:

      Result := True;
  else
    Result := False;
  end;
end;

type
  THackDatabase = class(TFIBDatabase);

function FindDatabaseForObject(Sender: TObject): TFIBDatabase;
begin
  if Sender is TFIBDatabase then
    Result := TFIBDatabase(Sender)
  else if Sender is TFIBQuery then
    Result := TFIBQuery(Sender).DataBase
  else if Sender is TFIBTransaction then
    Result := TFIBTransaction(Sender).MainDatabase
  else if Sender is TFIBFieldStream then
    Result := TFIBFieldStream(Sender).Database
{$IFDEF SUPPORT_ARRAY_FIELD}
  else if Sender is TpFIBArray then
    Result := TpFIBArray(Sender).Database
{$ENDIF}
  else
    Result := nil;
end;

(*
  * A Firebird 3+ client defers the cursor close, so on a dead attachment
  * reopening fails with isc_dsql_cursor_open_err instead of a lost connection
  * code. Only then the attachment is pinged; returns the lost code or 0.
*)
function HiddenLostConnection(DB: THackDatabase): ISC_STATUS;
begin
  Result := 0;
  if (DB <> nil) and DB.Connected and not(drsInCloseLostConnect in DB.FDatabaseRunState) and
    CheckStatusVector([isc_dsql_cursor_open_err]) then
  begin
    Result := DB.PingAttachment;
    if not IsConnectionLost(Result) then
      Result := 0;
  end;
end;

// A quoted name as Firebird 6 writes it ("PUBLIC"."IDX"): its last part unquoted; anything else as is
function UnquotedObjectName(const Name: string): string;
var
  Len, Position, Start: Integer;
  Part: string;
begin
  Len := Length(Name);
  Position := 1;
  while (Position <= Len) and (Name[Position] = '"') do
  begin
    Part := '';
    repeat
      Inc(Position);
      Start := Position;
      while (Position <= Len) and (Name[Position] <> '"') do
        Inc(Position);
      if Position > Len then
      begin
        Result := Name;
        Exit;
      end;
      Part := Part + Copy(Name, Start, Position - Start);
      Inc(Position);
      // a doubled quote is a quote of the name
      if (Position <= Len) and (Name[Position] = '"') then
        Part := Part + '"'
      else
        Break;
    until False;
    if Position > Len then
    begin
      Result := Part;
      Exit;
    end;
    if Name[Position] <> '.' then
      Break;
    Inc(Position);
  end;
  Result := Name;
end;

// Firebird 6 quotes the names of the status vector; unknown without a connected database
function QuotesStatusVectorNames(Sender: TObject): Boolean;
var
  DB: TFIBDatabase;
begin
  DB := FindDatabaseForObject(Sender);
  Result := (DB = nil) or not DB.Connected or (DB.ServerMajorVersion >= 6);
end;

// The name of a user exception as the server writes it: the argument of the item after isc_except
function ExceptionNameArgument(ErrorValue: EFIBError): string;
var
  Codes: TFIBErrorCodes;
  I: Integer;
begin
  Result := '';
  Codes := ErrorValue.ErrorCodes;
  for I := 0 to High(Codes) - 1 do
  begin
    // ErrorArgument reads the first isc_random item
    if Codes[I] = isc_random then
      Exit;
    if Codes[I] = isc_except then
    begin
      if Codes[I + 1] = isc_random then
        Result := ErrorValue.ErrorArgument(isc_random);
      Exit;
    end;
  end;
end;

procedure TpFibErrorHandler.DefaultOnError(Sender: TObject; ErrorValue: EFIBError; HandledError: TFIBHandledError;
  var DoRaise: Boolean);
var
  p: integer;
  RepositoryText, AtLexem, LowerMessage, ServerName: string;
  vDB: THackDatabase;
  LostCode: ISC_STATUS;
begin
  HandledError.ConstraintName := '';
  HandledError.ExceptionName := '';
  HandledError.ExceptionNumber := -1;
  HandledError.Kind := keOther;
  with ErrorValue do
    case SQLCode of
      sqlcode_unique_violation:
        begin
          case IBErrorCode of
            isc_unique_key_violation, isc_no_dup:
              begin
                HandledError.Kind := keUniqueViolation;
                if oeUniqueViolation in Options then
                begin
                  HandledError.ConstraintName := ErrorConstraintName(Sender, ErrorValue);
                  RepositoryText := RepositoryMessage(Sender, HandledError.ConstraintName);
                  if RepositoryText <> '' then
                    ErrorValue.Message := RepositoryText
                  else
                    ErrorValue.Message := ErrorValue.IBMessage;
                end;
              end;
          end;
        end;
      sqlcode_exception:
        begin
          // Developer exception
          HandledError.Kind := keException;
          if oeException in Options then
          begin
            // the lexem is followed by one separator
            p := Pos(ErrorLexems.FException, AnsiLowerCase(Message));
            if p > 0 then
              Message := FastCopy(Message, p + Length(ErrorLexems.FException) + 1, MaxInt);
            p := Pos(ErrorLexems.FException, AnsiLowerCase(Message));
            if p > 0 then
              Message := FastCopy(Message, p + Length(ErrorLexems.FException) + 1, MaxInt);
            // the number and the name come from the status vector, the message lines are only cut off
            p := PosCh('.', Message);
            if HasErrorCode(isc_except) and (p > 0) and
              (Trim(FastCopy(Message, 1, p - 1)) = IntToStr(ErrorNumber(isc_except))) then
            begin
              HandledError.ExceptionNumber := ErrorNumber(isc_except);
              Message := TrimCLRF(FastCopy(Message, p + 1, MaxInt));
              HandledError.ExceptionName := 'Unknown';
              vDB := THackDatabase(FindDatabaseForObject(Sender));
              if (vDB = nil) or vDB.IsFirebirdConnect and (vDB.ServerMajorVersion >= 2) then
              begin
                ServerName := ExceptionNameArgument(ErrorValue);
                if ServerName <> '' then
                begin
                  if QuotesStatusVectorNames(Sender) then
                    HandledError.ExceptionName := UnquotedObjectName(ServerName)
                  else
                    HandledError.ExceptionName := ServerName;
                  // IBError capitalizes the line and ends it with a dot
                  if AnsiSameText(FastCopy(Message, 1, Length(ServerName)), ServerName) then
                  begin
                    Message := FastCopy(Message, Length(ServerName) + 1, MaxInt);
                    if (Message <> '') and (Message[1] = '.') then
                      Message := FastCopy(Message, 2, MaxInt);
                  end;
                  // the stack trace is the last status item, its frames are split by a bare LF
                  if ErrorLexems.FAt <> '' then
                  begin
                    AtLexem := CRLF + ErrorLexems.FAt + ' ';
                    LowerMessage := AnsiLowerCase(Message);
                    p := Length(LowerMessage) - Length(AtLexem) + 1;
                    while (p > 0) and
                      not CompareMem(@LowerMessage[p], Pointer(AtLexem), Length(AtLexem) * SizeOf(Char)) do
                      Dec(p);
                    if p > 0 then
                      Message := FastCopy(Message, 1, p - 1);
                  end;
                end;
              end;
            end;
          end;
        end;
      sqlcode_foreign_or_create_schema:
        begin
          if (IBErrorCode = isc_foreign_key) then
          begin
            // Is Foreign Key
            HandledError.Kind := keForeignKey;
            HandledError.ConstraintName := ErrorConstraintName(Sender, ErrorValue);
            if oeForeignKey in Options then
            begin
              RepositoryText := RepositoryMessage(Sender, HandledError.ConstraintName);
              if RepositoryText <> '' then
                ErrorValue.Message := RepositoryText;
            end;
          end
        end;
      sqlcode_notpermission: HandledError.Kind := keSecurity;
      sqlcode_checkconstraint:
        begin
          HandledError.Kind := keCheck;
          if oeCheck in Options then
          begin
            HandledError.ConstraintName := ErrorConstraintName(Sender, ErrorValue);
            RepositoryText := RepositoryMessage(Sender, HandledError.ConstraintName);
            if RepositoryText <> '' then
              ErrorValue.Message := RepositoryText
            else
              ErrorValue.Message := ErrorValue.IBMessage;
          end
        end;
    else
      begin
        if IBErrorCode = isc_cancelled then
        begin
          if IsStatementTimeout then
            HandledError.Kind := keStatementTimeout
          else
            HandledError.Kind := keCancelled;
          Exit;
        end;
        vDB := THackDatabase(FindDatabaseForObject(Sender));
        if IsConnectionLost(IBErrorCode) or ((SQLCode = sqlcode_902) and (IBErrorCode = isc_network_error)) then
          LostCode := IBErrorCode
        else
          LostCode := HiddenLostConnection(vDB);
        if LostCode <> 0 then
        begin
          HandledError.Kind := keLostConnect;
          // raised while closing this lost connection
          if (vDB <> nil) and (drsInCloseLostConnect in vDB.FDatabaseRunState) then
            Exit;
          // if (IBErrorCode=isc_shutdown) or (IBErrorCode=isc_att_shutdown) and (FindDatabaseForObject(Sender)<>nil) then
          if (LostCode = isc_shutdown) and (vDB <> nil) and vDB.Connected then
            vDB.InternalClose(True, True);

          if oeLostConnect in Options then
            DoOnLostConnect(vDB, ErrorValue, DoRaise);
        end
      end
    end;
end;

// The constraint of a violation: the argument of its status vector code, exact even with spaces or quotes
function TpFibErrorHandler.ErrorConstraintName(Sender: TObject; ErrorValue: EFIBError): string;
begin
  Result := ErrorValue.ErrorArgument(ErrorValue.IBErrorCode);
  if Result = '' then
    Result := MessageConstraintName(ErrorValue.IBMessage)
  else if QuotesStatusVectorNames(Sender) then
    Result := UnquotedObjectName(Result);
end;

// The next token of Msg from Position; a token in double quotes keeps its spaces
function NextMessageToken(const Msg: string; var Position: Integer; out Token: string; out Quoted: Boolean): Boolean;
const
  Separators = [' ', #9, #10, #13];
var
  Len, Start: Integer;
begin
  Len := Length(Msg);
  while (Position <= Len) and CharInSet(Msg[Position], Separators) do
    Inc(Position);
  Result := Position <= Len;
  if not Result then
    Exit;
  Quoted := Msg[Position] = '"';
  if Quoted then
  begin
    Inc(Position);
    Start := Position;
    while (Position <= Len) and (Msg[Position] <> '"') do
      Inc(Position);
    Token := Copy(Msg, Start, Position - Start);
    Inc(Position);
  end
  else
  begin
    Start := Position;
    while (Position <= Len) and not CharInSet(Msg[Position], Separators) do
      Inc(Position);
    Token := Copy(Msg, Start, Position - Start);
  end;
end;

// The name after the Constraint or Index lexem of the message, for errors without the name in the status vector
function TpFibErrorHandler.MessageConstraintName(const Msg: string): string;
var
  Position: Integer;
  Token, LowerToken: string;
  Quoted: Boolean;
begin
  Result := '';
  Position := 1;
  while NextMessageToken(Msg, Position, Token, Quoted) do
  begin
    if Quoted then
      Continue;
    LowerToken := AnsiLowerCase(Token);
    if (LowerToken = FErrorLexems.FConstraint) or (LowerToken = FErrorLexems.FIndex) then
    begin
      if NextMessageToken(Msg, Position, Token, Quoted) then
      begin
        Result := Token;
        // IBError ends each line with a dot, an unquoted name can end one
        if not Quoted and (Result <> '') and (Result[Length(Result)] = '.') then
          SetLength(Result, Length(Result) - 1);
      end;
      Exit;
    end;
  end;
end;

function TpFibErrorHandler.GetTr(Sender: TObject): TFIBTransaction;
begin
  if Sender is TFIBQuery then
    Result := TFIBQuery(Sender).Transaction
  else if Sender is TFIBDatabase then
    Result := TFIBDatabase(Sender).DefaultTransaction
  else
    Result := nil;
end;

// The message of FIB$ERROR_MESSAGES for ConstraintName; a failed lookup must not replace the error
function TpFibErrorHandler.RepositoryMessage(Sender: TObject; const ConstraintName: string): string;
var
  Tr: TFIBTransaction;
  DB: TFIBDatabase;
begin
  Result := '';
  Tr := GetTr(Sender);
  if (Tr = nil) or not Tr.InTransaction then
    Exit;
  // the database of the failing object, not the default one of a transaction over several databases
  DB := FindDatabaseForObject(Sender);
  if (DB = nil) or (Tr.FindDatabase(DB) < 0) then
    Exit;
  InRepositoryLookup := True;
  try
    try
      Result := ListErrorMessages.ErrorMessage(DB, Tr, ConstraintName);
    except
      Result := '';
    end;
  finally
    InRepositoryLookup := False;
  end;
end;

type
  THackpFIBDatabase = class(TpFIBDatabase);

procedure TpFibErrorHandler.DoOnLostConnect(DataBase: TFIBDatabase; ErrorValue: EFIBError; var DoRaise: boolean);
var
  i: integer;
  Actions: TOnLostConnectActions;
begin
  if DataBase = nil then
    with DatabaseList.LockList do
      try
        for i := 0 to Pred(Count) do
          if TFIBDatabase(Items[i]) is TpFIBDatabase then
            with THackpFIBDatabase(Items[i]) do
            begin
              { if not Connected then
                Continue; }
              Actions := laCloseConnect;
              DoOnLostConnect(TFIBDatabase(Items[i]), ErrorValue, Actions, DoRaise);
            end;
      finally
        DatabaseList.UnlockList;
      end
  else
    // if Database.Connected then
    if DataBase is TpFIBDatabase then
    begin
      Actions := laCloseConnect;
      THackpFIBDatabase(DataBase).DoOnLostConnect(DataBase, ErrorValue, Actions, DoRaise)
    end;
end;

procedure TpFibErrorHandler.DoOnErrorEvent(Sender: TObject; ErrorValue: EFIBError; var DoRaise: Boolean);
var
  vDB: TFIBDatabase;
  HandledError: TFIBHandledError;
  Kind: TKindIBError;
begin
  // an error of the repository lookup goes back to RepositoryMessage untouched
  if InRepositoryLookup then
    Exit;
  HandledError := CurrentHandledError(True);
  DefaultOnError(Sender, ErrorValue, HandledError, DoRaise);
  // a nested error of this thread, in OnLostConnect for example, writes the same entry
  Kind := HandledError.Kind;
  if Assigned(FOnFIBErrorEvent) then
  begin
    FOnFIBErrorEvent(Sender, ErrorValue, Kind, DoRaise);
    if (Kind = keLostConnect) and (not DoRaise) then
    begin
      vDB := FindDatabaseForObject(Sender);
      if not(Assigned(vDB) and (vDB is TpFIBDatabase) and TpFIBDatabase(vDB).InRestoreConnect) then
        Abort;
    end;
  end;
end;

{ TErrorLexems }

constructor TErrorLexems.Create;
begin
  FConstraint := 'constraint';
  FIndex := 'index';
  FException := 'exception';
  FAt := 'at'
end;

function TErrorLexems.StoredAtProp: boolean;
begin
  Result := FAt <> 'at';
end;

function TErrorLexems.StoredConstraintProp: boolean;
begin
  Result := FConstraint <> 'constraint';
end;

function TErrorLexems.StoredExceptionProp: boolean;
begin
  Result := FException <> 'exception';
end;

function TErrorLexems.StoredIndexProp: boolean;
begin
  Result := FIndex <> 'index';
end;

procedure TErrorLexems.Assign(Source: TPersistent);
begin
  if Source is TErrorLexems then
  begin
    FConstraint := TErrorLexems(Source).FConstraint;
    FIndex := TErrorLexems(Source).FIndex;
    FException := TErrorLexems(Source).FException;
    FAt := TErrorLexems(Source).FAt;
  end
  else
    inherited Assign(Source);
end;

procedure TpFibErrorHandler.SetErrorLexems(const Value: TErrorLexems);
begin
  FErrorLexems.Assign(Value);
end;

end.
