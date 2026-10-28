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

unit FIBErrorHandler;

interface

{$I FIB.inc}

uses
  SysUtils, Classes, Contnrs, SyncObjs, FIB, FIBDatabase, IB_ErrorCodes,
  ibase, IB_Intf, IB_Externals, DB, FIBDataInfo, FIBQuery;

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

  TFIBErrorHandler = class(TComponent)
  private
    type
      // The error last handled in a thread
      THandledError = class
      public
        ThreadID: Cardinal;
        Kind: TKindIBError;
        ConstraintName: string;
        ExceptionName: string;
        ExceptionNumber: Integer;
      end;
  private
    FOnFIBErrorEvent: TOnFIBErrorEvent;
    FOptions: TOptionsErrorHandler;
    FErrorLexems: TErrorLexems;
    FHandledErrors: TObjectList; // THandledError per thread, under FHandledErrorsLock
    FHandledErrorsLock: TCriticalSection;
    FNoHandledError: THandledError;
    function CurrentHandledError(CanCreate: Boolean): THandledError;
    procedure DefaultOnError(Sender: TObject; ErrorValue: EFIBError; HandledError: THandledError;
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
  FIBConsts, FIBMiscellaneous, FIBPlatforms, StrUtil{$IFDEF SUPPORT_ARRAY_FIELD}, FIBArray{$ENDIF};

threadvar
  InRepositoryLookup: Boolean;
  // False in a new thread, which can get the ID, and so the entry, of a finished one
  ErrorHandledInThread: Boolean;

constructor TFIBErrorHandler.Create(AOwner: TComponent);
begin
  if ErrorHandlerRegistered and not(csDesigning in ComponentState) then
    raise Exception.Create(SFIBErrorHandlerExists);
  inherited Create(AOwner);
  FHandledErrors := TObjectList.Create;
  FHandledErrorsLock := TCriticalSection.Create;
  FNoHandledError := THandledError.Create;
  FNoHandledError.ExceptionNumber := -1;
  RegisterErrorHandler(Self);
  Options := [oeException, oeLostConnect];
  FErrorLexems := TErrorLexems.Create;
end;

destructor TFIBErrorHandler.Destroy;
begin
  UnRegisterErrorHandler(Self);
  FErrorLexems.Free;
  FHandledErrors.Free;
  FHandledErrorsLock.Free;
  FNoHandledError.Free;
  inherited Destroy;
end;

// The entry of a finished thread stays until the handler is freed and is reused with its thread ID
function TFIBErrorHandler.CurrentHandledError(CanCreate: Boolean): THandledError;
var
  ThreadID: Cardinal;
  I: Integer;
begin
  if not (CanCreate or ErrorHandledInThread) then
    Exit(FNoHandledError);
  ErrorHandledInThread := True;
  ThreadID := CurrentThreadID;
  FHandledErrorsLock.Acquire;
  try
    for I := 0 to FHandledErrors.Count - 1 do
    begin
      Result := THandledError(FHandledErrors[I]);
      if Result.ThreadID = ThreadID then
        Exit;
    end;
    if CanCreate then
    begin
      Result := THandledError.Create;
      Result.ThreadID := ThreadID;
      FHandledErrors.Add(Result);
    end
    else
      Result := FNoHandledError;
  finally
    FHandledErrorsLock.Release;
  end;
end;

function TFIBErrorHandler.GetConstraintName: string;
begin
  Result := CurrentHandledError(False).ConstraintName;
end;

function TFIBErrorHandler.GetExceptionName: string;
begin
  Result := CurrentHandledError(False).ExceptionName;
end;

function TFIBErrorHandler.GetExceptionNumber: Integer;
begin
  Result := CurrentHandledError(False).ExceptionNumber;
end;

function TFIBErrorHandler.GetLastError: TKindIBError;
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
  else if Sender is TFIBArray then
    Result := TFIBArray(Sender).Database
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
    // an error code: 32 bits on Win64 too
    if not IsConnectionLost(Long(Result)) then
      Result := 0;
  end;
end;

procedure TFIBErrorHandler.DefaultOnError(Sender: TObject; ErrorValue: EFIBError; HandledError: THandledError;
  var DoRaise: Boolean);
var
  p: integer;
  RepositoryText, AtLexem, LowerMessage: string;
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
            p := PosCh('.', Message);
            if p > 0 then
              try
                HandledError.ExceptionNumber := StrToInt(FastCopy(Message, 1, p - 1));
                Message := TrimCLRF(FastCopy(Message, p + 1, MaxInt));
                HandledError.ExceptionName := 'Unknown';
                vDB := THackDatabase(FindDatabaseForObject(Sender));
                if vDB <> nil then
                begin
                  if vDB.IsFirebirdConnect and (vDB.ServerMajorVersion >= 2) then
                  begin
                    p := PosCh('.', Message);
                    if p > 0 then
                    begin
                      HandledError.ExceptionName := FastCopy(Message, 1, p - 1);
                      Message := FastCopy(Message, p + 1, MaxInt);
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
              except
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
        Exit(Name);
      Part := Part + Copy(Name, Start, Position - Start);
      Inc(Position);
      // a doubled quote is a quote of the name
      if (Position <= Len) and (Name[Position] = '"') then
        Part := Part + '"'
      else
        Break;
    until False;
    if Position > Len then
      Exit(Part);
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

// The constraint of a violation: the argument of its status vector code, exact even with spaces or quotes
function TFIBErrorHandler.ErrorConstraintName(Sender: TObject; ErrorValue: EFIBError): string;
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
function TFIBErrorHandler.MessageConstraintName(const Msg: string): string;
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

function TFIBErrorHandler.GetTr(Sender: TObject): TFIBTransaction;
begin
  if Sender is TFIBQuery then
    Result := TFIBQuery(Sender).Transaction
  else if Sender is TFIBDatabase then
    Result := TFIBDatabase(Sender).DefaultTransaction
  else
    Result := nil;
end;

// The message of FIB$ERROR_MESSAGES for ConstraintName; a failed lookup must not replace the error
function TFIBErrorHandler.RepositoryMessage(Sender: TObject; const ConstraintName: string): string;
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

procedure TFIBErrorHandler.DoOnLostConnect(DataBase: TFIBDatabase; ErrorValue: EFIBError; var DoRaise: boolean);
var
  i: integer;
  Actions: TOnLostConnectActions;
  Databases: TList;
  LostDatabase: THackDatabase;
  Listed: boolean;
begin
  if DataBase <> nil then
  begin
    Actions := laCloseConnect;
    THackDatabase(DataBase).DoOnLostConnect(DataBase, ErrorValue, Actions, DoRaise);
    Exit;
  end;
  // a copy: the ping and the handlers run without the list lock
  Databases := TList.Create;
  try
    try
      Databases.Assign(DatabaseList.LockList);
    finally
      DatabaseList.UnlockList;
    end;
    for i := 0 to Databases.Count - 1 do
    begin
      // a handler may have freed it
      try
        Listed := DatabaseList.LockList.IndexOf(Databases[i]) >= 0;
      finally
        DatabaseList.UnlockList;
      end;
      if not Listed then
        Continue;
      LostDatabase := THackDatabase(Databases[i]);
      if LostDatabase.Connected and IsConnectionLost(Long(LostDatabase.PingAttachment)) then
      begin
        Actions := laCloseConnect;
        LostDatabase.DoOnLostConnect(LostDatabase, ErrorValue, Actions, DoRaise);
      end;
    end;
  finally
    Databases.Free;
  end;
end;

procedure TFIBErrorHandler.DoOnErrorEvent(Sender: TObject; ErrorValue: EFIBError; var DoRaise: Boolean);
var
  vDB: TFIBDatabase;
  HandledError: THandledError;
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
      vDB := THackDatabase(FindDatabaseForObject(Sender));
      if not(Assigned(vDB) and vDB.InRestoreConnect) then
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

procedure TFIBErrorHandler.SetErrorLexems(const Value: TErrorLexems);
begin
  FErrorLexems.Assign(Value);
end;

end.
