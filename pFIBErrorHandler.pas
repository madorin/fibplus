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
{    Written by Serge Buzadzhy (buzz@devrace.com)               }
{                                                               }
{ ------------------------------------------------------------- }
{    FIBPlus home page: http://www.fibplus.com/                 }
{    FIBPlus support  : http://www.devrace.com/support/         }
{ ------------------------------------------------------------- }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit pFIBErrorHandler;

interface
{$I FIBPlus.inc}
uses
  SysUtils, Classes, fib, FIBDatabase, pFIBDatabase, IB_ErrorCodes,
  ibase, IB_Intf, IB_Externals, DB, pFIBDataInfo, FIBQuery;

type

  TOptionErrorHandler = (oeException, oeForeignKey, oeLostConnect, oeCheck,
    oeUniqueViolation
    );
  TKindIBError = (keNoError, keException, keForeignKey, keLostConnect,
    keSecurity, keCheck, keUniqueViolation, keOther
    );

  TOnFIBErrorEvent = procedure(Sender: TObject; ErrorValue: EFIBError;
    KindIBError: TKindIBError;
    var DoRaise: boolean
    ) of object;

  TOptionsErrorHandler = set of TOptionErrorHandler;

  TErrorLexems = class(TPersistent)
  private
   FConstraint:string;
   FIndex     :string;
   FException :string;
   FAt        :string;
   function StoredConstraintProp:boolean;
   function StoredIndexProp:boolean;
    function StoredExceptionProp: Boolean;
    function StoredAtProp: Boolean;
  public
   constructor Create;
  published
   property Constraint:string read FConstraint write FConstraint  stored StoredConstraintProp;
   property Index     :string read FIndex write FIndex stored StoredIndexProp;
   property Exception :string read FException write FException stored StoredExceptionProp;
   property At        :string read FAt write FAt stored StoredAtProp;
  end;

  TpFibErrorHandler = class(TComponent)
  private
    FLastError: TKindIBError;
    FOnFIBErrorEvent: TOnFIBErrorEvent;
    FOptions: TOptionsErrorHandler;
    FExceptionNumber: integer;
    FConstraintName: string;
    FExceptionName :string;
    FErrorLexems:TErrorLexems;
    procedure DefaultOnError(Sender: TObject; ErrorValue: EFIBError;
      var DoRaise: boolean);
    function GetConstraintName(const Msg: string): string;
    function GetTr(Sender: TObject): TFIBTransaction;
    procedure SetErrorLexems(const Value: TErrorLexems);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure DoOnErrorEvent(Sender: TObject; ErrorValue: EFIBError;
      var DoRaise: boolean); dynamic; // for internal use
    procedure DoOnLostConnect(DataBase:TFIBDatabase;ErrorValue: EFIBError;var DoRaise:boolean);
    property ExceptionNumber: integer read FExceptionNumber;
    property LastError: TKindIBError read FLastError;
    property ConstraintName: string read FConstraintName;
    property ExceptionName :string  read FExceptionName;
  published
    property OnFIBErrorEvent: TOnFIBErrorEvent read FOnFIBErrorEvent write
      FOnFIBErrorEvent;
    property Options: TOptionsErrorHandler read FOptions write FOptions
      default [oeException, oeLostConnect]
      ;
    property ErrorLexems:TErrorLexems read FErrorLexems write SetErrorLexems;
  end;

function IsConnectionLost(const IBErrorCode: integer): boolean;

implementation

uses FIBConsts, StrUtil;

constructor TpFibErrorHandler.Create(AOwner: TComponent);
begin
  if ErrorHandlerRegistered and not (csDesigning in ComponentState) then
    raise Exception.Create(SFIBErrorHandlerExists);
  inherited Create(AOwner);
  RegisterErrorHandler(Self);
  Options := [oeException, oeLostConnect];
  FLastError := keNoError;
  FErrorLexems:=TErrorLexems.Create;
end;

destructor TpFibErrorHandler.Destroy;
begin
  FErrorLexems.Free;
  UnRegisterErrorHandler;
  inherited Destroy;
end;



function IsConnectionLost(const IBErrorCode: integer): boolean;
begin
  case IBErrorCode of
    isc_shutdown,isc_network_error, isc_lost_db_connection, //isc_net_connect_err,
    isc_net_connect_listen_err, isc_net_event_connect_err,
    isc_net_event_listen_err,isc_net_read_err, isc_net_write_err,isc_att_shutdown:
    
     Result := True;
  else
    Result := False;
  end;
end;

type
  THackDatabase = class(TFIBDatabase);

function FindDatabaseForObject(Sender: TObject):THackDatabase;
begin
  if Sender is TFIBDataBase then
   Result:=THackDatabase(Sender)
  else
  if Sender is TFIBQuery then
   Result:=THackDatabase(TFIBQuery(Sender).Database)
  else
  if Sender is TFIBTransaction then
   Result:=THackDatabase(TFIBTransaction(Sender).MainDatabase)
  else
   Result := nil;       
end;

procedure TpFibErrorHandler.DefaultOnError(Sender: TObject;
  ErrorValue: EFIBError;
  var DoRaise: boolean);
var
  p: integer;
  s: string;
  CurTr:TFIBTransaction;
begin
  FConstraintName  := '';
  FExceptionNumber := -1;
  FLastError       := keOther;
  with ErrorValue do
   case SQLCode of
    sqlcode_unique_violation :
    begin
      case IBErrorCode of
       isc_unique_key_violation,isc_no_dup:
        begin
          FLastError := keUniqueViolation;
          if oeUniqueViolation in Options then
          begin
            FConstraintName := GetConstraintName(ErrorValue.IBMessage);
            if (GetTr(Sender) <> nil) then
              s := ListErrorMessages.ErrorMessage(GetTr(Sender), FConstraintName);
            if s <> '' then
            begin
              ErrorValue.Message := s;
              Exit;
            end;
            ErrorValue.Message := ErrorValue.IBMessage;
          end;
        end ;
      end;
    end;
    sqlcode_exception:
      begin
        //Developer exception
        FLastError := keException;
        if oeException in Options then
        begin
          p := Pos(ErrorLexems.FException, AnsiLowerCase(Message));
          if p > 0 then
            Message := FastCopy(Message, p + 10, MaxInt);
          p := Pos(ErrorLexems.FException, AnsiLowerCase(Message));
          if p > 0 then
            Message := FastCopy(Message, p + 10, MaxInt);
          p := PosCh('.', Message);
          if p > 0 then
          try
            FExceptionNumber := StrToInt(FastCopy(Message, 1, p - 1));
            Message := TrimCLRF(FastCopy(Message, p + 1, MaxInt));
            FExceptionName:='Unknown';
            CurTr:=GetTr(Sender);
            if CurTr<>nil then
            begin
              if CurTr.DefaultDatabase.IsFirebirdConnect and (
               CurTr.DefaultDatabase.ServerMajorVersion>=2
              ) then
              begin
                p := PosCh('.', Message);
                if p>0 then
                begin
                 FExceptionName:=FastCopy(Message,1, p - 1);
                 Message:=FastCopy(Message, p + 1,MaxInt);
                 p:=Pos(ErrorLexems.FAt, AnsiLowerCase(Message));
                 if (p>0) and (p<Length(Message)-3) and (Message[p+2]= ' ') then
                  Message:=FastCopy(Message,1,p-1);
                   
                end;
              end;                
            end;              
          except
          end;
        end;
      end ;
    sqlcode_foreign_or_create_schema:
     begin
      if  (IBErrorCode = isc_foreign_key) then
      begin
         // Is Foreign Key
        FLastError := keForeignKey;
        FConstraintName := GetConstraintName(ErrorValue.IBMessage);
        if (oeForeignKey in Options) and (GetTr(Sender) <> nil) then
        begin
          s := ListErrorMessages.ErrorMessage(GetTr(Sender), FConstraintName);
          if s <> '' then
            ErrorValue.Message := s;
        end;
      end
     end;
    sqlcode_notpermission:
      FLastError := keSecurity;
    sqlcode_checkconstraint:
      begin
        FLastError := keCheck;
        if oeCheck in Options then
        begin
          FConstraintName := GetConstraintName(ErrorValue.IBMessage);
          if (GetTr(Sender) <> nil) then
            s := ListErrorMessages.ErrorMessage(GetTr(Sender), FConstraintName);
          if s <> '' then
          begin
            ErrorValue.Message := s;
            Exit;
          end;
          ErrorValue.Message := ErrorValue.IBMessage;
        end
      end;
   else
    if IsConnectionLost(IBErrorCode) or
      ((SQLCode = sqlcode_902) and (IBErrorCode = isc_network_error)) then
    begin
     // if (IBErrorCode=isc_shutdown) or (IBErrorCode=isc_att_shutdown) and (FindDatabaseForObject(Sender)<>nil) then
      if (IBErrorCode=isc_shutdown) and (FindDatabaseForObject(Sender)<>nil) then
       FindDatabaseForObject(Sender).InternalClose(True,True);

      FLastError := keLostConnect;
      if oeLostConnect in Options then
        DoOnLostConnect(FindDatabaseForObject(Sender),ErrorValue,DoRaise);
    end
   end;
end;

function TpFibErrorHandler.GetConstraintName(const Msg: string): string;
var
  i: integer;
  lcLexem, Lexem: string;
  InConstrName: boolean;
begin
  Lexem := '';
  InConstrName := False;
  for i := 1 to Length(Msg) do
    case Msg[i] of
      ' ', #13, #10:
        begin
          lcLexem := AnsiLowerCase(Lexem);
          if (lcLexem = FErrorLexems.FConstraint) or (lcLexem = FErrorLexems.FIndex) then
          begin
            InConstrName := True;
            Lexem := '';
          end
          else
          if not InConstrName then
            Lexem := ''
          else
            Break
        end;
    else
      if Msg[i] <> '"' then
        Lexem := Lexem + Msg[i]
    end;
  Result := Lexem;
  if (Length(Result) > 0) and (Result[Length(Result)] = '.') then
    SetLength(Result, Length(Result) - 1)
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

type
  THackpFIBDatabase = class(TpFIBDatabase);


procedure TpFibErrorHandler.DoOnLostConnect(DataBase:TFIBDatabase;ErrorValue: EFIBError;var DoRaise:boolean);
var
  i: integer;
  Actions: TOnLostConnectActions;
begin
  if DataBase=nil then
    with DatabaseList.LockList do
    try
      for i := 0 to Pred(Count) do
        if TFIBDatabase(Items[i]) is TpFIBDatabase then
          with THackpFIBDatabase(Items[i]) do
          begin
{            if not Connected then
              Continue;}
            Actions := laCloseConnect;
            DoOnLostConnect(TFIBDatabase(Items[i]), ErrorValue, Actions,DoRaise);
          end;
    finally
      DatabaseList.UnlockList;
    end
  else
//  if Database.Connected then
  begin
   Actions := laCloseConnect;
   THackpFIBDatabase(DataBase).DoOnLostConnect(DataBase, ErrorValue, Actions,DoRaise)
  end;
end;

procedure TpFibErrorHandler.
  DoOnErrorEvent(Sender: TObject; ErrorValue: EFIBError; var DoRaise: boolean);
var
 vDB:TFIBDatabase;
begin
  DefaultOnError(Sender, ErrorValue, DoRaise);
  if Assigned(FOnFIBErrorEvent) then
  begin
    FOnFIBErrorEvent(Sender, ErrorValue, LastError, DoRaise);
    if (LastError=keLostConnect) and (not DoRaise) then
    begin
      vDB:=FindDatabaseForObject(Sender);
      if not (Assigned(vDB) and (vDB is TpFIBDatabase) and
         TpFIBDatabase(vDB).InRestoreConnect)
      then
       Abort;
    end;
  end;
end;

{ TErrorLexems }

constructor TErrorLexems.Create;
begin
 FConstraint:='constraint';
 FIndex     :='index';
 FException :='exception';
 FAt        :='at'
end;

function TErrorLexems.StoredAtProp: Boolean;
begin
 Result:=  FAt<>'at';
end;

function TErrorLexems.StoredConstraintProp: boolean;
begin
 Result:=  FConstraint<>'constraint';
end;

function TErrorLexems.StoredExceptionProp: Boolean;
begin
 Result:= FException<>'exception';
end;

function TErrorLexems.StoredIndexProp: boolean;
begin
 Result:= FIndex<>'index';
end;

procedure TpFibErrorHandler.SetErrorLexems(const Value: TErrorLexems);
begin
  FErrorLexems.FConstraint:=Value.FConstraint;
  FErrorLexems.FIndex:=Value.FIndex;
end;

end.

