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


unit fib;

{$I FIBPlus.inc}
{$T-}

interface

uses
  SyncObjs,SysUtils, Classes, ibase,IB_Intf, ib_externals,Db,FIBPlatforms;


type

  (*
   * It might seem more natural for the EFIBError constructor to
   * include the Msg parameter first, and the ASQLCode second, but
   * to get this to work easily with C++-Builder, the parameter
   * order is switched.
   *)


  EFIBError                  = class(EDatabaseError)
  private
    FSQLCode: Long;
    FIBErrorCode: Long;
    FRaiserName: string; // IMS
    FSQLMessage :string;
    FIBMessage  :string;
    FCustomMessage: string; // IMS
    FMsg: string;
    FSQLState:FIBByteString;
    SenderObj :TObject;

    procedure RebuildMessage; // IMS
    procedure SetSQLMessage(Value: string); // IMS
    procedure SetIBMessage(Value: string); // IMS
    procedure SetCustomMessage(const Value: string); // IMS
    procedure SetMsg(const Value: string); // IMS
  public
    constructor Create(ASQLCode: Long; const aMsg: String;Sender:TObject);
    constructor CreateEx(ASQLCode: Long; const IBMsg,SQLMsg,CstmMsg: String;Sender:TObject);
    property    SQLCode    : Long read FSQLCode ;
    property    IBErrorCode: Long read FIBErrorCode ;
    property    RaiserName: string read FRaiserName write FRaiserName; // IMS
    property    SQLState:FIBByteString read FSQLState;
    // IMS - SQLMessage and IBMessage write permissions
    property    SQLMessage :string read FSQLMessage write SetSQLMessage;
    property    IBMessage  :string read FIBMessage write SetIBMessage;
    property    CustomMessage: string read FCustomMessage write SetCustomMessage; // IMS
    property    Msg: string read FMsg write SetMsg; // IMS
  end;


  EFIBInterBaseError         = class(EFIBError);
  EFIBClientError            = class(EFIBError);



  TIBErrorMessage            = (ShowSQLCode,
                                ShowIBMessage,
                                ShowSQLMessage,
                                ShowSQLState,
                                ShowRaiserName
                               );
  TIBErrorMessages          = set of TIBErrorMessage;


  TFIBClientError            = (
                                feUnknownError,
                                feNotSupported,
                                feNotPermitted,
                                feFileAccessError,
                                feConnectionTimeout,
                                feCannotSetDatabase,
                                feCannotSetTransaction,
                                feOperationCancelled,
                                feDPBConstantNotSupported,
                                feDPBConstantUnknown,
                                feTPBConstantNotSupported,
                                feTPBConstantUnknown,
                                feDatabaseClosed,
                                feDatabaseOpen,
                                feDatabaseNameMissing,
                                feNotInTransaction,
                                feInTransaction,
                                feTimeoutNegative,
                                feNoDatabasesInTransaction,
                                feUpdateWrongDB,
                                feUpdateWrongTR,
                                feDatabaseNotAssigned,
                                feTransactionNotAssigned,
                                feXSQLDAIndexOutOfRange,
                                feXSQLDANameDoesNotExist,
                                feEOF,
                                feBOF,
                                feInvalidStatementHandle,
                                feDatasetOpen,
                                feDatasetClosed,
                                feUnknownSQLDataType,
                                feInvalidColumnIndex,
                                feInvalidParamColumnIndex,
                                feInvalidDataConversion,
                                feColumnIsNotNullable,
                                feBlobCannotBeRead,
                                feBlobCannotBeWritten,
                                feEmptyQuery,
                                feCannotOpenNonSQLSelect,
                                feNoFieldAccess,
                                feFieldReadOnly,
                                feFieldNotFound,
                                feNotInEditState,
                                feNotEditing,
                                feCannotInsert,
                                feCannotPost,
                                feCannotUpdate,
                                feCannotDelete,
                                feCannotRefresh,
                                feBufferNotSet,
                                feCircularReference,
                                feSQLParseError,
                                feUserAbort,
                                feDataSetUniDirectional,
                                feCannotCreateSharedResource,
                                feWindowsAPIError,
                                feColumnListsDontMatch,
                                feColumnTypesDontMatch,
                                feCantEndSharedTransaction,
                                // Added
                                feNotIsArrayField,
                                feWrongDimension,
                                feSQLDialectInvalid,
                                feIBMissing,
                                feIB60feature,
                                // Added by Serg Vostrikov
                                feInterBaseInstallMissing,
                                feServiceActive,
                                feServiceInActive,
                                feServerNameMissing,
                                feQueryParamsError,
                                feStartParamsError,
                                feOutputParsingError,
                                feUseSpecificProcedures,
                                feSPBConstantNotSupported,
                                feSPBConstantUnknown,
                                feFieldSizeMismatch,

                                feCantUseLimitedCache,
                                feFieldListEmpty,
                                feCantUseField,
                                feFB2feature

                                );

  TStatusVector              = array[0..19] of ISC_STATUS;
  PStatusVector              = ^TStatusVector;

const
  {$I pFIBVersion.inc}

  (* For building buffers to send to IB *)
  CRLF = #13#10;
  FIBLocalBufferLength = 512;
  FIBBigLocalBufferLength = FIBLocalBufferLength * 2;
  FIBHugeLocalBufferLength = FIBBigLocalBufferLength * 20;
  (* Default "Prefix" to show in error messages. *)

  {$I FIB_MESSAGES.INC}

  DPBPrefix = 'isc_dpb_';
  DPBConstantNames: array[1..isc_dpb_last_dpb_constant] of String = (
    'cdd_pathname',
    'allocation',
    'journal',
    'page_size',
    'num_buffers',
    'buffer_length',
    'debug',
    'garbage_collect',
    'verify',
    'sweep',
    'enable_journal',
    'disable_journal',
    'dbkey_scope',
    'number_of_users',
    'trace',
    'no_garbage_collect',
    'damaged',
    'license',
    'sys_user_name',
    'encrypt_key',
    'activate_shadow',
    'sweep_interval',
    'delete_shadow',
    'force_write',
    'begin_log',
    'quit_log',
    'no_reserve',
    'user_name',
    'password',
    'password_enc',
    'sys_user_name_enc',
    'interp',
    'online_dump',
    'old_file_size',
    'old_num_files',
    'old_file',
    'old_start_page',
    'old_start_seqno',
    'old_start_file',
    'drop_walfile',
    'old_dump_id',
    'wal_backup_dir',
    'wal_chkptlen',
    'wal_numbufs',
    'wal_bufsize',
    'wal_grp_cmt_wait',
    'lc_messages',
    'lc_ctype',
    'cache_manager',
    'shutdown',
    'online',
    'shutdown_delay',
    'reserved',
    'overwrite',
    'sec_attach',
    'disable_wal',
    'connect_timeout',
    'dummy_packet_interval',
    'gbak_attach',
    'sql_role_name',
    'set_page_buffers',
    'working_directory',
    'sql_dialect',
    'set_db_readonly',
    'set_db_sql_dialect',
    'gfix_attach',
    'gstat_attach',
//IB2007
    'gbak_ods_version',              
    'gbak_ods_minor_version',        
    'set_group_commit',              
    'gbak_validate',                 
    'client_interbase_var',          
    'admin_option',                  
    'flush_interval',                
    'instance_name',                 
    'old_overwrite',                 
    'archive_database',              
    'archive_journals',              
    'archive_sweep',                 
    'archive_dumps',                 
    'archive_recover',               
    'recover_until',                 
    'force'

  );
  TPBPrefix = 'isc_tpb_';
  TPBConstantNames: array[1..isc_tpb_last_tpb_constant] of String = (
    'consistency',
    'concurrency',
    'shared',
    'protected',
    'exclusive',
    'wait',
    'nowait',
    'read',
    'write',
    'lock_read',
    'lock_write',
    'verb_time',
    'commit_time',
    'ignore_limbo',
    'read_committed',
    'autocommit',
    'rec_version',
    'no_rec_version',
    'restart_requests',
    'no_auto_undo',
    'no_savepoint'
  );


type
TpFIBLoginDialog=
 function (const ADatabaseName: string; var AUserName, APassword,ARoleName: string): Boolean;



const
  SQLDecimalSeparator='.';

resourcestring
  TrueStr='True';
  FalseStr='False';
var
  FIBCS: TCriticalSection;
//  hFIBTLGlobals: DWord_;
  pFIBLoginDialog :TpFIBLoginDialog;

(* FIBAlloc acts like Realloc, except that it guarantees that
   the "newly" allocated memory is initialized to 0's *)
procedure FIBAlloc(var p; OldSize, NewSize: DWORD);
(* Error message routines. *)
procedure FIBError(ErrMess: TFIBClientError; const Args: array of const);
procedure FIBErrorEx(const ErrMess:string; const Args: array of const);

procedure IBError(ClientLibrary:IIbClientLibrary;Sender:TObject);

procedure RegisterErrorHandler(aErrorHandler:TComponent);
procedure UnRegisterErrorHandler;
function ErrorHandlerRegistered:boolean;

(* Manage the thread-local status vector *)
function StatusVector: PISC_STATUS;
function StatusVectorArray: PStatusVector;
function CheckStatusVector(ErrorCodes: array of ISC_STATUS): Boolean;
function StatusVectorAsText: String;

(* Generate a DPB *)
procedure GenerateDPB(sl: TStrings; var DPB: AnsiString; var DPBLength: Short;IsFirebird:boolean);
procedure GenerateTPB(sl: TStrings; var TPB: AnsiString; var TPBLength: Short; IsFB21orMore:boolean);
(* Manage global options *)
procedure SetIBErrorMessages(Value: TIBErrorMessages);
function GetIBErrorMessages: TIBErrorMessages;


var
  IBErrorMessages: TIBErrorMessages;


implementation

uses pFIBErrorHandler,StdFuncs,StrUtil;

var
  IBErrorHandler :TpFibErrorHandler;
  TPBConstants    :TStringList;
  DPBConstants    :TStringList;

threadvar
  FStatusVector : TStatusVector;




procedure FIBAlloc(var p; OldSize, NewSize: DWORD);
begin
  if Pointer(p)=nil then
    GetMem(Pointer(p), NewSize)
  else
    ReallocMem(Pointer(P), NewSize);
  if NewSize>OldSize then
   FillChar((PAnsiChar(p)+OldSize)^,NewSize-OldSize,0);
end;


/// ErrorHandler

procedure RegisterErrorHandler(aErrorHandler:TComponent);
begin
 if aErrorHandler is TpFibErrorHandler then
  IBErrorHandler:=TpFibErrorHandler(aErrorHandler)
end;

procedure UnRegisterErrorHandler;
begin
 IBErrorHandler:=nil
end;

function ErrorHandlerRegistered:boolean;
begin
 Result:= (IBErrorHandler<>nil) and not(csDesigning in IBErrorHandler.ComponentState)
end;
(*
 * FIBError -
 *  Given an error code and some possible string arguments, raise
 *  an exception.
 *)

procedure FIBError(ErrMess: TFIBClientError; const Args: array of const);
begin
  raise EFIBClientError.Create(
          Ord(ErrMess),
          Format(FIBErrorMessages[ErrMess], Args),nil);
end;

procedure FIBErrorEx(const ErrMess:string; const Args: array of const);
begin
  raise EFIBClientError.Create(-1,Format(ErrMess, Args),nil);
end;

(*
 * IBError -
 *  Examine the status vector, and raise an
 *  exception based on the current values in it.
 *)
procedure IBError(ClientLibrary:IIbClientLibrary;Sender:TObject);
var
  sqlcode: Long;
//  vFbSQLState : array[0..FB_sqlstate_bufSize-1] of AnsiChar;
  local_buffer: array[0..FIBHugeLocalBufferLength - 1] of AnsiChar;
  vIBMessage:string;
  vSQLMessage:string;
  status_vector: PISC_STATUS;
  IBErrorMessages: TIBErrorMessages;

  vEFIBInterBaseError                   : EFIBInterBaseError  ;
  vRaiseExcept :boolean;
  tmpStr  :Ansistring;
  L:integer;
  vSQLState:FIBByteString;
begin
  (*
   * Initialize the working user message.
   * Get a local reference to the status vector.
   * Get a local copy of the IBErrorMessages options.
   * Get the SQL error code.
   *)
  status_vector := StatusVector;
  IBErrorMessages := GetIBErrorMessages;
  sqlcode := ClientLibrary.isc_sqlcode(status_vector);
//  FillChar(vFbSQLState,FB_sqlstate_bufSize,0);
  vSQLState:=ClientLibrary.fb_sqlstate(status_vector);
  vIBMessage:='';
  vSQLMessage:='';
  (*
   * Maybe show the SQL Code
   *)
  (*
   * Maybe show the SQL Error message
   *)
  if (ShowSQLMessage in IBErrorMessages) then
  begin
    ClientLibrary.isc_sql_interprete(sqlcode, local_buffer, FIBBigLocalBufferLength);

    vSQLMessage:=string(local_buffer);
    vSQLMessage := ReplaceStr(vSQLMessage, '\n', '');
    if Length(vSQLMessage)>0 then
    begin
     if (vSQLMessage[1] >= 'a') and (vSQLMessage[1] <= 'z') then
      Dec(vSQLMessage[1], 32);
     if (vSQLMessage[Length(vSQLMessage)] <> '.') then
      vSQLMessage := vSQLMessage + '.'+CLRF;
    end;
  end;
  (*
   * Maybe show the interbase error messages
   *)
  vIBMessage:='';
  if (ShowSQLState  in IBErrorMessages) and (Length(vSQLState)>0) then
    vIBMessage:='SQL error state ='+vSQLState+CLRF
  else
    vIBMessage:='';
  if (ShowIBMessage in IBErrorMessages) then
  begin
    L:= ClientLibrary.fb_Interpret(local_buffer, FIBHugeLocalBufferLength,@status_vector);
    while  (L> 0) do
    begin
      SetLength(tmpStr,L);
      Move(local_buffer[0],tmpStr[1],L);


      if Length(tmpStr)>0 then
      begin
        if (tmpStr[1] >= 'a') and (tmpStr[1] <= 'z') then
         Dec(tmpStr[1],32);
        vIBMessage:=vIBMessage+tmpStr;
        if (vIBMessage[Length(vIBMessage)] <> '.') then
          vIBMessage := vIBMessage + '.';
        vIBMessage := vIBMessage + CRLF;
      end;
      L:= ClientLibrary.fb_Interpret(local_buffer, FIBHugeLocalBufferLength,@status_vector);
    end;
  end;
  (*
   * Finally raise the exception
   *)
  vRaiseExcept:=true;
  vEFIBInterBaseError:=EFIBInterBaseError.CreateEx(sqlcode,vIBMessage,vSQLMessage,'',Sender); // '' by IMS
  vEFIBInterBaseError.FSQLState:=vSQLState;
  try
    if ErrorHandlerRegistered   then
     IBErrorHandler.DoOnErrorEvent(Sender,vEFIBInterBaseError,vRaiseExcept);
  except
   vEFIBInterBaseError.Free;
   raise;
  end;
  if vRaiseExcept then
   raise vEFIBInterBaseError
  else
   vEFIBInterBaseError.Free;
end;                         


(* Return the status vector for the current thread *)
function StatusVector: PISC_STATUS;
begin
   Result := PISC_STATUS(@FStatusVector)
end;

function StatusVectorArray: PStatusVector;
begin
  Result := @FStatusVector;
end;


function CheckStatusVector(ErrorCodes: array of ISC_STATUS): Boolean;
var
  p: PISC_STATUS;
  i: Integer;
  procedure NextP(i: Integer);
  begin
    p := PISC_STATUS(PAnsiChar(p) + (i * SizeOf(ISC_STATUS)));
  end;
begin
  p := StatusVector;
  Result := False;
  while (p^ <> 0) and (not Result) do
    case p^ of
      3: NextP(3);
      1, 4:
      begin
        NextP(1);
        i := 0;
        while (i <= High(ErrorCodes)) and (not Result) do
        begin
          Result := p^ = ErrorCodes[i];
          Inc(i);
        end;
        NextP(1);
      end;
    else
        NextP(2);
    end;
end;

function StatusVectorAsText: String;
var
  p: PISC_STATUS;
  function NextP(i: Integer): PISC_STATUS;
  begin
    p := PISC_STATUS(PAnsiChar(p) + (i * SizeOf(ISC_STATUS)));
    Result := p;
  end;
begin
  p := StatusVector;
  Result := '';
  while (p^ <> 0) do
    if (p^ = 3) then
    begin
      Result := Result + Format('%d %d %d', [p^, NextP(1)^, NextP(1)^]) + CRLF;
      NextP(1);
    end
    else
    begin
      Result := Result + Format('%d %d', [p^, NextP(1)^]) + CRLF;
      NextP(1);
    end;
end;

(* EFIBError *)

{ IMS }

procedure EFIBError.RebuildMessage;
var sn: string;
begin
  sn := '';
  if (ShowRaiserName in IBErrorMessages) and (Length(FRaiserName) > 1)
  then sn := FRaiserName + ':'+CLRF;
  if (ShowSQLMessage in IBErrorMessages)
  then sn := sn + FSQLMessage;
  if (ShowIBMessage in IBErrorMessages)
  then sn := sn + FIBMessage;
  if length(FCustomMessage) > 0
  then sn := sn + FCustomMessage;
  sn := sn + FMsg;
  Message := sn;
end;

procedure EFIBError.SetSQLMessage(Value: string);
begin
  FSQLMessage := Value; RebuildMessage;
end;

procedure EFIBError.SetIBMessage(Value: string);
begin
  FIBMessage := Value; RebuildMessage;
end;

procedure EFIBError.SetCustomMessage(const Value: string);
begin
  FCustomMessage := Value; RebuildMessage;
end;

procedure EFIBError.SetMsg(const Value: string);
begin
  FMsg := Value; RebuildMessage;
end;

{ /IMS }

constructor EFIBError.Create(ASQLCode: Long; const aMsg: String;Sender:TObject);

begin
  if (Sender <> nil) and (Sender is TComponent)
  then FRaiserName := CmpFullName(TComponent(Sender))
  else FRaiserName := ''; // IMS

  inherited Create(''); // IMS - (sn+aMsg);
  Msg := aMsg; // IMS
  FSQLCode := ASQLCode;
  FIBErrorCode :=StatusVectorArray[1];
  SenderObj := Sender;
end;

// Added CstmMsg by IMS
constructor EFIBError.CreateEx(ASQLCode: Long; const IBMsg,SQLMsg,CstmMsg: String;Sender:TObject);
// var sn:string;
begin
{ IMS
  if Length(SQLMsg)>0 then
   sn:=SQLMsg
  else
    sn:='';
  if Length(IBMsg)>0 then  sn:=sn+IBMsg;
  // IMS
  if Length(CstmMsg)>0 then sn:=sn+CstmMsg;
}
  FSQLMessage :=SQLMsg;
  FIBMessage  :=IBMsg;
  // IMS
  FCustomMessage := CstmMsg;
  Create(ASQLCode,''{sn - IMS},Sender);
end;

function GetDPBShutParamValue(const ParamString:Ansistring):integer;
var i,j:integer;
    s:Ansistring;

function CurParamValue:integer;
begin
  Result:=-1;
  s:=LowerCase(s);
  case s[1] of
   '0'..'9':
        Result:=StrToInt(s);
   'a': if s='attachment' then
         Result:=isc_dpb_shut_attachment;
   'c': if s='cache' then
         Result:=isc_dpb_shut_cache;
   'f': if s='force' then
          Result:=isc_dpb_shut_force
        else
        if s='full' then
          Result:=isc_dpb_shut_full;

   'm': if s='mode_mask' then
          Result:=isc_dpb_shut_mode_mask
        else
        if s='multi' then
          Result:=isc_dpb_shut_multi;
   'n': if s='normal' then
         Result:=isc_dpb_shut_normal;

   's': if s='single' then
         Result:=isc_dpb_shut_single;

   't':if s='transaction' then
         Result:=isc_dpb_shut_transaction;

  end;
end;

begin
  Result:=0; j:=1;
  for i:=1 to Length(ParamString) do
  begin
    if ParamString[i] in[',',';'] then
    begin
      if (i-j>0) then
      begin
        SetLength(s,i-j);
        Move(ParamString[j],s[1],i-j);
        Result:=Result or  CurParamValue
      end;
      j:=i+1;
    end
  end;
  i:=Length(ParamString);
  if j<i then
  begin
     i:=Length(ParamString);
     SetLength(s,i-j+1);
     Move(ParamString[j],s[1],i-j+1);
     Result:=Result or  CurParamValue
  end;
end;

(*
 * GenerateDPB -
 *  Given a string containing a textual representation
 *  of the database parameters, generate a database
 *  parameter buffer, and return it and its length
 *  in DPB and DPBLength, respectively.
 *)
procedure GenerateDPB(sl: TStrings; var DPB: AnsiString;
  var DPBLength: Short;IsFirebird:boolean);
var
  i : integer;
  j, DPBVal:integer;
  param_name, param_value: AnsiString;
  pval: Integer;

  procedure ApplyStrParam;
  begin
        DPB := DPB +
               AnsiChar(DPBVal) +
               AnsiChar(Length(param_value)) +
               param_value;
        Inc(DPBLength, 2 + Length(param_value));
  end;

begin
  (*
   * The DPB is initially empty, with the exception that
   * the DPB version must be the first byte of the string.
   *)
  DPBLength := 1;
  DPB := AnsiChar(isc_dpb_version1);
  (*
   * Iterate through the textual database parameters, constructing
   * a DPB on-the-fly.
   *)
  for i := 0 to sl.Count - 1 do
  begin
    (*
     * Get the parameter's name and value from the list,
     * and make sure that the name is all lowercase with
     * no leading 'isc_dpb_' prefix
     *)
    sl[i]:=Trim(sl[i]);
    if sl[i]='' then Continue;

    GetNameAndValue(sl[i],param_name,param_value);
    DoLowerCase(param_name);

    if (Pos(DPBPrefix, param_name) = 1) then
       param_name:=FastCopy(param_name,Length(DPBPrefix)+1,MaxInt);
//      Delete(param_name, 1, Length(DPBPrefix));
    (*
     * We want to translate the parameter name to some integer
     * value. We do this by scanning through a list of known
     * database parameter names (DPBConstantNames, defined above).
     *)
//    if DPBConstants.Find(param_name,j) then
    j:= NonAnsiIndexOf(DPBConstants,param_name);
    if j>-1 then
      DPBVal :=Integer(DPBConstants.Objects[j])
    else
      DPBVal := 0;

    (*
     * A database parameter either contains a string value (case 1)
     * or an integer value (case 2)
     * or no value at all (case 3)
     * or an error needs to be generated (case else)
     *)
    case DPBVal of
      isc_dpb_user_name, isc_dpb_password, isc_dpb_password_enc,
      isc_dpb_sys_user_name, isc_dpb_license, isc_dpb_encrypt_key,
      isc_dpb_lc_messages, isc_dpb_lc_ctype,
      isc_dpb_sql_role_name,isc_dpb_sql_dialect,
      isc_dpb_old_file,isc_dpb_sys_encrypt_password:
      begin
        if DPBVal = isc_dpb_sql_dialect then
          param_value[1] := AnsiChar(Ord(param_value[1]) - 48);
        ApplyStrParam
      end;
      isc_dpb_instance_name:
      begin
      // or isc_dpb_trusted_role
       if not IsFirebird then
       begin
        //IB 2007
        ApplyStrParam;
       end
      end;
      isc_dpb_set_db_charset:
      begin
       // or isc_dpb_gbak_ods_version
        if IsFirebird then
        begin
        //FB2
          ApplyStrParam;
        end;
      end;


      isc_dpb_num_buffers, isc_dpb_dbkey_scope, isc_dpb_force_write,
      isc_dpb_no_reserve, isc_dpb_damaged, isc_dpb_verify,
      isc_dpb_dummy_packet_interval, isc_dpb_connect_timeout,
      isc_dpb_online_dump, isc_dpb_overwrite, isc_dpb_old_file_size,isc_dpb_shutdown_delay
      :
      begin
        DPB := DPB +AnsiChar(DPBVal) +#1+AnsiChar(StrToInt(param_value));
        Inc(DPBLength, 3);
      end;
      isc_dpb_sweep:
      begin
        DPB := DPB +AnsiChar(DPBVal) +#1 +AnsiChar(isc_dpb_records);
        Inc(DPBLength, 3);
      end;
      isc_dpb_sweep_interval:
      begin
        pval := StrToInt(param_value);
        DPB := DPB +AnsiChar(DPBVal) +#4 +
               PAnsiChar(@pval)[0] +
               PAnsiChar(@pval)[1] +
               PAnsiChar(@pval)[2] +
               PAnsiChar(@pval)[3];
        Inc(DPBLength, 6);
      end;
      isc_dpb_activate_shadow, isc_dpb_delete_shadow, isc_dpb_begin_log,
      isc_dpb_quit_log:
      begin
        DPB := DPB +AnsiChar(DPBVal) +#1#0;
        Inc(DPBLength, 3);
      end;

      isc_dpb_utf8_filename: // FB2
      begin
      // or isc_dpb_archive_database
        if IsFirebird then
        begin
         DPB := DPB + AnsiChar(DPBVal) + #0;
         Inc(DPBLength, 2);
        end
      end;

      isc_dpb_no_db_triggers: // FB2
      begin
  // or isc_dpb_client_interbase_var
        if IsFirebird then
        begin
         DPB := DPB + AnsiChar(DPBVal) + #1#1;
         Inc(DPBLength, 3);
        end
      end;

      //
      isc_dpb_no_garbage_collect,isc_dpb_garbage_collect:
      begin
        DPB := DPB + AnsiChar(DPBVal) + #1#1;
        Inc(DPBLength, 3);
      end;
      isc_dpb_shutdown:
      begin
        if Length(param_value)=0 then
        begin
         DPB := DPB + AnsiChar(DPBVal) + #0;
         Inc(DPBLength, 2);
        end
        else
        begin
         DPB := DPB + AnsiChar(DPBVal) + #1+
          Ansichar(GetDPBShutParamValue(param_value));
         Inc(DPBLength, 3);
        end;
      end;
      isc_dpb_online:
      begin
        DPB := DPB + AnsiChar(DPBVal) +#0;
        Inc(DPBLength, 2);
      end;
    else
      begin
        if (DPBVal > 0) and (DPBVal <= isc_dpb_last_dpb_constant) then
          FIBError(feDPBConstantNotSupported,[DPBConstantNames[DPBVal]])
        else
          FIBError(feDPBConstantUnknown, [param_name]);
      end;
    end;
  end;
end;

(*
 * GenerateTPB -
 *  Given a string containing a textual representation
 *  of the transaction parameters, generate a transaction
 *  parameter buffer, and return it and its length in
 *  TPB and TPBLength, respectively.
 *)
procedure GenerateTPB(sl: TStrings; var TPB: AnsiString;  var TPBLength: Short; IsFB21orMore:boolean);
var
  i, j, TPBVal, ParamLength: Integer;
  param_name, param_value: AnsiString;
  LT:word;
begin
  TPB := '';
  if (sl.Count = 0) then
    TPBLength := 0
  else
  begin
    TPBLength := sl.Count + 1;
    TPB := TPB + AnsiChar(isc_tpb_version3);
  end;
  for i := 0 to sl.Count - 1 do
  begin
    sl[i]:=FastTrim(sl[i]);
    if sl[i]='' then
    begin
     Dec(TPBLength);
     Continue;
    end;
    GetNameAndValue(sl[i],param_name,param_value);
    DoLowerCase(param_name);

    if (Pos(TPBPrefix, param_name) = 1) then
       param_name:=FastCopy(param_name,Length(TPBPrefix)+1,MaxInt);

    if TPBConstants.Find(param_name,j) then
      TPBVal :=Integer(TPBConstants.Objects[j])
    else
      TPBVal := 0;
    (* Now act on it *)
    case TPBVal of
      isc_tpb_consistency, isc_tpb_exclusive, isc_tpb_protected,
      isc_tpb_concurrency, isc_tpb_shared, isc_tpb_wait, isc_tpb_nowait,
      isc_tpb_read, isc_tpb_write, isc_tpb_ignore_limbo,
      isc_tpb_read_committed, isc_tpb_rec_version, isc_tpb_no_rec_version,
      isc_tpb_no_auto_undo{,isc_tpb_no_savepoint}:
        TPB := TPB + AnsiChar(TPBVal);
      isc_tpb_lock_read, isc_tpb_lock_write:
      begin
        TPB := TPB + AnsiChar(TPBVal);
        // Now set the string parameter
        ParamLength := Length(param_value);
        Inc(TPBLength, ParamLength + 1);
        TPB := TPB + AnsiChar(ParamLength) + param_value;
      end;
    else
      begin
        if (TPBVal > 0) and
           (TPBVal <= isc_tpb_last_tpb_constant) then
        begin
         if TPBVal<>isc_tpb_no_savepoint {isc_tpb_lock_timeout} then
          FIBError(feTPBConstantNotSupported,
                   [TPBConstantNames[TPBVal]])
         else
         begin
          if IsFB21orMore then
          begin
          // isc_tpb_lock_timeout
            TPB := TPB + AnsiChar(TPBVal);
            TPB := TPB + #2 ;
            LT:=StrToIntDef(param_value,10);

           TPB  := TPB  + PAnsiChar(@LT)[0] + PAnsiChar(@LT)[1] ;
           Inc(TPBLength, 1+SizeOf(Word));
          end
          else
           TPB := TPB + AnsiChar(TPBVal); // isc_tpb_no_savepoint
         end;
        end
        else
          FIBError(feTPBConstantUnknown, [param_name]);
      end;
    end;
  end;
end;

procedure SetIBErrorMessages(Value: TIBErrorMessages);
begin

  FIBCS.Acquire;
  try
    IBErrorMessages := Value;
  finally
   FIBCS.Release

  end;
end;

function GetIBErrorMessages: TIBErrorMessages;
begin

  FIBCS.Acquire;
  try
    Result := IBErrorMessages;
  finally
    FIBCS.Release
  end;
end;

procedure InitTPBConstantsList;
var i:integer;
begin
  TPBConstants:= TStringList.Create;
  with TPBConstants do
  begin
   Capacity:=isc_tpb_last_tpb_constant;
   for i:=1 to isc_tpb_last_tpb_constant do
    AddObject(TPBConstantNames[i],TObject(i));

   AddObject('lock_timeout',TObject(isc_tpb_lock_timeout));    
   Sorted:=true;
  end;
end;

procedure InitDPBConstantsList;
var i:integer;
begin
  DPBConstants:= TStringList.Create;
  with DPBConstants do
  begin
   Capacity:=isc_dpb_last_dpb_constant;
   for i:=1 to isc_dpb_last_dpb_constant do
    AddObject(DPBConstantNames[i],TObject(i));

   AddObject('no_db_triggers',TObject(isc_dpb_no_db_triggers));
   AddObject('set_db_charset',TObject(isc_dpb_set_db_charset));
   AddObject('utf8_filename',TObject(isc_dpb_utf8_filename));


  // Sorted:=true;
  end;
end;


initialization
  FIBCS:=TCriticalSection.Create;;
  IBErrorMessages := [ShowSQLMessage, ShowIBMessage,ShowSQLState,ShowRaiserName];
  InitTPBConstantsList;
  InitDPBConstantsList;

finalization
  FreeAndNil(TPBConstants);
  FreeAndNil(DPBConstants);
  FreeAndNil(FIBCS)
end.


