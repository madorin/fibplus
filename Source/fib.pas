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

unit fib;

{$I FIBPlus.inc}
{$T-}

interface

uses
  SyncObjs, SysUtils, Classes, ibase, IB_Intf, ib_externals, Db, FIBPlatforms;

type

  (*
    * It might seem more natural for the EFIBError constructor to
    * include the Msg parameter first, and the ASQLCode second, but
    * to get this to work easily with C++-Builder, the parameter
    * order is switched.
  *)

  TFIBErrorCodes = array of Long;
  TFIBErrorArguments = array of string;

  EFIBError = class(EDatabaseError)
  private
    FSQLCode: Long;
    FIBErrorCode: Long;
    FErrorCodes: TFIBErrorCodes;
    FErrorArguments: array of TFIBErrorArguments; // the string arguments of each item of FErrorCodes
    FErrorNumbers: array of TFIBErrorCodes; // the number arguments of each item of FErrorCodes
    FRaiserName: string; // IMS
    FSQLMessage: string;
    FIBMessage: string;
    FCustomMessage: string; // IMS
    FMsg: string;
    FSQLState: FIBByteString;
    SenderObj: TObject;
    procedure ReadStatusVector(Status: PISC_STATUS; CodePage: Word);
    procedure RebuildMessage; // IMS
    procedure SetSQLMessage(Value: string); // IMS
    procedure SetIBMessage(Value: string); // IMS
    procedure SetCustomMessage(const Value: string); // IMS
    procedure SetMsg(const Value: string); // IMS
  public
    constructor Create(ASQLCode: Long; const aMsg: string; Sender: TObject);
    constructor CreateEx(ASQLCode: Long; const IBMsg, SQLMsg, CstmMsg: string; Sender: TObject);
    property SQLCode: Long read FSQLCode;
    property IBErrorCode: Long read FIBErrorCode;
    // every gds code of the status vector, set for server errors only
    property ErrorCodes: TFIBErrorCodes read FErrorCodes;
    function HasErrorCode(Code: Long): Boolean;
    // the Index-th string argument of the first status vector item with Code, '' without one
    function ErrorArgument(Code: Long; Index: Integer = 0): string;
    // the Index-th number argument of the first status vector item with Code, 0 without one
    function ErrorNumber(Code: Long; Index: Integer = 0): Long;
    function IsStatementTimeout: Boolean;
    property RaiserName: string read FRaiserName write FRaiserName; // IMS
    property SQLState: FIBByteString read FSQLState;
    // IMS - SQLMessage and IBMessage write permissions
    property SQLMessage: string read FSQLMessage write SetSQLMessage;
    property IBMessage: string read FIBMessage write SetIBMessage;
    property CustomMessage: string read FCustomMessage write SetCustomMessage;
    // IMS
    property Msg: string read FMsg write SetMsg; // IMS
  end;

  EFIBInterBaseError = class(EFIBError);
  EFIBClientError = class(EFIBError);

  TIBErrorMessage = (
    ShowSQLCode,
    ShowIBMessage,
    ShowSQLMessage,
    ShowSQLState,
    ShowRaiserName
  );
  TIBErrorMessages = set of TIBErrorMessage;

  TFIBClientError = (
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
    feFB2feature,
    feFeatureNotSupported,
    feParamValueTooLong,
    feParamValueInvalid,
    feBlobFileError
  );

  TStatusVector = array [0 .. 19] of ISC_STATUS;
  PStatusVector = ^TStatusVector;

const
  {$I FIBVersion.inc}
  // For building buffers to send to IB
  CRLF                     = #13#10;
  FIBLocalBufferLength     = 512;
  FIBBigLocalBufferLength  = FIBLocalBufferLength * 2;
  FIBHugeLocalBufferLength = FIBBigLocalBufferLength * 20;
  // Default "Prefix" to show in error messages.

  {$I FIB_MESSAGES.INC}
  DPBPrefix = 'isc_dpb_';
  DPBConstantNames: array [1 .. isc_dpb_last_dpb_constant] of string = (
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
  // IB2007
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
  TPBConstantNames: array [1 .. isc_tpb_last_tpb_constant] of string = (
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
  TpFIBLoginDialog = function(const ADatabaseName: string; var AUserName, APassword, ARoleName: string): Boolean;

const
  SQLDecimalSeparator = '.';

resourcestring
  TrueStr  = 'True';
  FalseStr = 'False';

var
  FIBCS: TCriticalSection;
  // hFIBTLGlobals: DWord_;
  pFIBLoginDialog: TpFIBLoginDialog;

  (* FIBAlloc acts like Realloc, except that it guarantees that
    the "newly" allocated memory is initialized to 0's *)
procedure FIBAlloc(var p; OldSize, NewSize: DWORD);

function FIBVersionString: string;

// Error message routines.
procedure FIBError(ErrMess: TFIBClientError; const Args: array of const);
procedure FIBErrorEx(const ErrMess: string; const Args: array of const);

procedure IBError(ClientLibrary: IIbClientLibrary; Sender: TObject);

procedure RegisterErrorHandler(AErrorHandler: TComponent);
// With a handler, only that handler is unregistered
procedure UnRegisterErrorHandler(AErrorHandler: TComponent = nil);
function ErrorHandlerRegistered: Boolean;

// Manage the thread-local status vector
function StatusVector: PISC_STATUS;
function StatusVectorArray: PStatusVector;
function CheckStatusVector(ErrorCodes: array of ISC_STATUS): Boolean;
function StatusVectorAsText: string;

// Generate a DPB; AllowVersion2 (the client supports isc_dpb_version2) permits values over 255 bytes
procedure GenerateDPB(sl: TStrings; var DPB: AnsiString; var DPBLength: Short; IsFirebird: Boolean;
  AllowVersion2: Boolean = True);
// utf8_filename in DBParams: the strings of the DPB and the database name go in UTF-8
function DPBUsesUTF8(sl: TStrings; IsFirebird: Boolean): Boolean;
// Name in DBParams of a DPB code, '' when unknown
function DPBConstantName(Code: Integer): string;
// lock_read/lock_write table names in NameCodePage (FIBCharSets, 0 the system code page)
procedure GenerateTPB(sl: TStrings; var TPB: AnsiString; var TPBLength: Short; IsFB21orMore: Boolean;
  NameCodePage: Word = 0);
// Manage global options
procedure SetIBErrorMessages(Value: TIBErrorMessages);
function GetIBErrorMessages: TIBErrorMessages;

var
  IBErrorMessages: TIBErrorMessages;

implementation

uses
  IB_ErrorCodes, pFIBErrorHandler, StdFuncs, StrUtil, FIBDatabase, FIBCharSets;

var
  IBErrorHandler: TpFibErrorHandler;
  TPBConstants: TStringList;
  DPBConstants: TStringList;

threadvar FStatusVector: TStatusVector;

procedure FIBAlloc(var p; OldSize, NewSize: DWORD);
begin
  if Pointer(p) = nil then
    GetMem(Pointer(p), NewSize)
  else
    ReallocMem(Pointer(p), NewSize);
  if NewSize > OldSize then
    FillChar((PAnsiChar(p) + OldSize)^, NewSize - OldSize, 0);
end;

function FIBVersionString: string;
begin
  Result := Format('%d.%d.%d %s', [FIBMajorVersion, FIBMinorVersion, FIBPatchVersion, FIBVersionNote]);
end;

/// ErrorHandler

procedure RegisterErrorHandler(AErrorHandler: TComponent);
begin
  if AErrorHandler is TpFibErrorHandler then
    IBErrorHandler := TpFibErrorHandler(AErrorHandler)
end;

procedure UnRegisterErrorHandler(AErrorHandler: TComponent = nil);
begin
  if (AErrorHandler = nil) or (AErrorHandler = IBErrorHandler) then
    IBErrorHandler := nil
end;

function ErrorHandlerRegistered: Boolean;
begin
  Result := (IBErrorHandler <> nil) and not(csDesigning in IBErrorHandler.ComponentState)
end;

(*
  * FIBError -
  *  Given an error code and some possible string arguments, raise
  *  an exception.
*)

procedure FIBError(ErrMess: TFIBClientError; const Args: array of const);
begin
  raise EFIBClientError.Create(Ord(ErrMess), Format(FIBErrorMessages[ErrMess], Args), nil);
end;

procedure FIBErrorEx(const ErrMess: string; const Args: array of const);
begin
  raise EFIBClientError.Create(-1, Format(ErrMess, Args), nil);
end;

(*
  * IBError -
  *  Examine the status vector, and raise an
  *  exception based on the current values in it.
*)

// Bytes that are not valid UTF-8 (the exception texts of Firebird 2.5 on NONE) are in the system code page
function DecodeStatusText(Buffer: PAnsiChar; Length: Integer; CodePage: Word): string;
begin
  if CodePage = FIBCodePageUTF8 then
    Result := DecodeServerText(Buffer, Length)
  else
    Result := DecodeString(Buffer, Length, CodePage);
end;

// The client writes the text of an operating system error code in the system code page
function StatusItemCodePage(Status: PISC_STATUS; CodePage: Word): Word;
begin
  case Status^ of
    isc_arg_unix, isc_arg_dos, isc_arg_win32:
      Result := FIBCodePageSystem;
  else
    Result := CodePage;
  end;
end;

// Every gds code of the status vector and the string and number arguments that follow it; warnings are skipped
procedure EFIBError.ReadStatusVector(Status: PISC_STATUS; CodePage: Word);
var
  Count, Target, Len: Integer;
  Argument: AnsiString;

  procedure AddArgument;
  var
    Last: Integer;
  begin
    if Target < 0 then
      Exit;
    Last := Length(FErrorArguments[Target]);
    SetLength(FErrorArguments[Target], Last + 1);
    FErrorArguments[Target][Last] := DecodeStatusText(PAnsiChar(Argument), Length(Argument), CodePage);
  end;

  procedure AddNumber(Number: Long);
  var
    Last: Integer;
  begin
    if Target < 0 then
      Exit;
    Last := Length(FErrorNumbers[Target]);
    SetLength(FErrorNumbers[Target], Last + 1);
    FErrorNumbers[Target][Last] := Number;
  end;

begin
  Count := 0;
  Target := -1;
  FErrorCodes := nil;
  FErrorArguments := nil;
  FErrorNumbers := nil;
  while Status^ <> isc_arg_end do
    case Status^ of
      isc_arg_gds:
        begin
          Inc(Status);
          SetLength(FErrorCodes, Count + 1);
          SetLength(FErrorArguments, Count + 1);
          SetLength(FErrorNumbers, Count + 1);
          FErrorCodes[Count] := Long(Status^);
          Target := Count;
          Inc(Count);
          Inc(Status);
        end;
      isc_arg_warning:
        begin
          Target := -1;
          Inc(Status, 2);
        end;
      isc_arg_string:
        begin
          Inc(Status);
          Argument := PAnsiChar(Status^);
          AddArgument;
          Inc(Status);
        end;
      isc_arg_cstring:
        begin
          Inc(Status);
          Len := Integer(Status^);
          Inc(Status);
          SetString(Argument, PAnsiChar(Status^), Len);
          AddArgument;
          Inc(Status);
        end;
      isc_arg_number:
        begin
          Inc(Status);
          AddNumber(Long(Status^));
          Inc(Status);
        end;
    else
      Inc(Status, 2); // interpreted, sql_state, system codes: one value
    end;
end;

// Firebird 3+ sends the status vector strings in the attachment charset, in UTF-8 (metadata) on NONE
function StatusVectorCodePage(Sender: TObject): Word;
var
  DB: TFIBDatabase;
begin
  DB := FindDatabaseForObject(Sender);
  if (DB <> nil) and DB.Connected and IsCodePageAvailable(DB.Capabilities.MetadataCodePage) then
    Result := DB.Capabilities.MetadataCodePage
  else
    Result := FIBCodePageSystem;
end;

procedure IBError(ClientLibrary: IIbClientLibrary; Sender: TObject);
var
  SQLCode: Long;
  // vFbSQLState : array[0..FB_sqlstate_bufSize-1] of AnsiChar;
  local_buffer: array [0 .. FIBHugeLocalBufferLength - 1] of AnsiChar;
  vIBMessage: string;
  vSQLMessage: string;
  status_vector: PISC_STATUS;
  IBErrorMessages: TIBErrorMessages;

  vEFIBInterBaseError: EFIBInterBaseError;
  vRaiseExcept: Boolean;
  tmpStr: string;
  L: Integer;
  vSQLState: FIBByteString;
  CodePage, ItemCodePage: Word;
begin
  (*
    * Initialize the working user message.
    * Get a local reference to the status vector.
    * Get a local copy of the IBErrorMessages options.
    * Get the SQL error code.
  *)
  status_vector := StatusVector;
  IBErrorMessages := GetIBErrorMessages;
  SQLCode := ClientLibrary.isc_sqlcode(status_vector);
  // FillChar(vFbSQLState,FB_sqlstate_bufSize,0);
  vSQLState := ClientLibrary.fb_sqlstate(status_vector);
  CodePage := StatusVectorCodePage(Sender);
  vIBMessage := '';
  vSQLMessage := '';
  (*
    * Maybe show the SQL Code
  *)
  (*
    * Maybe show the SQL Error message
  *)
  if (ShowSQLMessage in IBErrorMessages) then
    begin
      ClientLibrary.isc_sql_interprete(SQLCode, local_buffer, FIBBigLocalBufferLength);

      vSQLMessage := string(local_buffer);
      vSQLMessage := ReplaceStr(vSQLMessage, '\n', '');
      if Length(vSQLMessage) > 0 then
        begin
          if (vSQLMessage[1] >= 'a') and (vSQLMessage[1] <= 'z') then
            Dec(vSQLMessage[1], 32);
          if (vSQLMessage[Length(vSQLMessage)] <> '.') then
            vSQLMessage := vSQLMessage + '.' + sLineBreak;
        end;
    end;
  (*
    * Maybe show the interbase error messages
  *)
  vIBMessage := '';
  if (ShowSQLState in IBErrorMessages) and (Length(vSQLState) > 0) then
    vIBMessage := 'SQL error state =' + vSQLState + sLineBreak
  else
    vIBMessage := '';
  if (ShowIBMessage in IBErrorMessages) then
    begin
      ItemCodePage := StatusItemCodePage(status_vector, CodePage);
      L := ClientLibrary.fb_Interpret(local_buffer, FIBHugeLocalBufferLength, @status_vector);
      while (L > 0) do
        begin
          tmpStr := DecodeStatusText(local_buffer, L, ItemCodePage);

          if Length(tmpStr) > 0 then
            begin
              if (tmpStr[1] >= 'a') and (tmpStr[1] <= 'z') then
                Dec(tmpStr[1], 32);
              vIBMessage := vIBMessage + tmpStr;
              if (vIBMessage[Length(vIBMessage)] <> '.') then
                vIBMessage := vIBMessage + '.';
              vIBMessage := vIBMessage + CRLF;
            end;
          ItemCodePage := StatusItemCodePage(status_vector, CodePage);
          L := ClientLibrary.fb_Interpret(local_buffer, FIBHugeLocalBufferLength, @status_vector);
        end;
    end;
  (*
    * Finally raise the exception
  *)
  vRaiseExcept := true;
  vEFIBInterBaseError := EFIBInterBaseError.CreateEx(SQLCode, vIBMessage, vSQLMessage, '', Sender); // '' by IMS
  vEFIBInterBaseError.FSQLState := vSQLState;
  vEFIBInterBaseError.ReadStatusVector(StatusVector, CodePage);
  try
    if ErrorHandlerRegistered then
      IBErrorHandler.DoOnErrorEvent(Sender, vEFIBInterBaseError, vRaiseExcept);
  except
    vEFIBInterBaseError.Free;
    raise;
  end;
  if vRaiseExcept then
    raise vEFIBInterBaseError
  else
    vEFIBInterBaseError.Free;
end;

// Return the status vector for the current thread
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

function StatusVectorAsText: string;
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

// EFIBError

{ IMS }

procedure EFIBError.RebuildMessage;
var
  sn: string;
begin
  sn := '';
  if (ShowRaiserName in IBErrorMessages) and (Length(FRaiserName) > 1) then
    sn := FRaiserName + ':' + sLineBreak;
  if (ShowSQLMessage in IBErrorMessages) then
    sn := sn + FSQLMessage;
  if (ShowIBMessage in IBErrorMessages) then
    sn := sn + FIBMessage;
  if Length(FCustomMessage) > 0 then
    sn := sn + FCustomMessage;
  sn := sn + FMsg;
  Message := sn;
end;

procedure EFIBError.SetSQLMessage(Value: string);
begin
  FSQLMessage := Value;
  RebuildMessage;
end;

procedure EFIBError.SetIBMessage(Value: string);
begin
  FIBMessage := Value;
  RebuildMessage;
end;

procedure EFIBError.SetCustomMessage(const Value: string);
begin
  FCustomMessage := Value;
  RebuildMessage;
end;

procedure EFIBError.SetMsg(const Value: string);
begin
  FMsg := Value;
  RebuildMessage;
end;

{ /IMS }

constructor EFIBError.Create(ASQLCode: Long; const aMsg: string; Sender: TObject);

begin
  if (Sender <> nil) and (Sender is TComponent) then
    FRaiserName := CmpFullName(TComponent(Sender))
  else
    FRaiserName := ''; // IMS

  inherited Create(''); // IMS - (sn+aMsg);
  Msg := aMsg; // IMS
  FSQLCode := ASQLCode;
  // a client error has no server code, the status vector can hold an old one
  if not (Self is EFIBClientError) then
    FIBErrorCode := StatusVectorArray[1];
  SenderObj := Sender;
end;

function EFIBError.HasErrorCode(Code: Long): Boolean;
var
  i: Integer;
begin
  Result := False;
  i := 0;
  while (i <= High(FErrorCodes)) and not Result do
  begin
    Result := FErrorCodes[i] = Code;
    Inc(i);
  end;
end;

function EFIBError.ErrorArgument(Code: Long; Index: Integer = 0): string;
var
  I: Integer;
begin
  for I := 0 to High(FErrorCodes) do
    if FErrorCodes[I] = Code then
    begin
      if (Index >= 0) and (Index <= High(FErrorArguments[I])) then
      begin
        Result := FErrorArguments[I][Index];
        Exit;
      end;
      Break;
    end;
  Result := '';
end;

function EFIBError.ErrorNumber(Code: Long; Index: Integer = 0): Long;
var
  I: Integer;
begin
  for I := 0 to High(FErrorCodes) do
    if FErrorCodes[I] = Code then
    begin
      if (Index >= 0) and (Index <= High(FErrorNumbers[I])) then
      begin
        Result := FErrorNumbers[I][Index];
        Exit;
      end;
      Break;
    end;
  Result := 0;
end;

function EFIBError.IsStatementTimeout: Boolean;
begin
  Result := (FIBErrorCode = isc_cancelled) and (HasErrorCode(isc_req_stmt_timeout) or
    HasErrorCode(isc_att_stmt_timeout) or HasErrorCode(isc_cfg_stmt_timeout));
end;

// Added CstmMsg by IMS
constructor EFIBError.CreateEx(ASQLCode: Long; const IBMsg, SQLMsg, CstmMsg: string; Sender: TObject);
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
  FSQLMessage := SQLMsg;
  FIBMessage := IBMsg;
  // IMS
  FCustomMessage := CstmMsg;
  Create(ASQLCode, '' { sn - IMS } , Sender);
end;

function GetDPBShutParamValue(const ParamString: AnsiString): Integer;
type
  TShutdownWord = record
    Name: string;
    Value: Integer;
  end;
const
  ShutdownWords: array [0 .. 9] of TShutdownWord = (
    (Name: 'attachment'; Value: isc_dpb_shut_attachment),
    (Name: 'cache'; Value: isc_dpb_shut_cache),
    (Name: 'force'; Value: isc_dpb_shut_force),
    (Name: 'transaction'; Value: isc_dpb_shut_transaction),
    (Name: 'mode_mask'; Value: isc_dpb_shut_mode_mask),
    (Name: 'default'; Value: isc_dpb_shut_default),
    (Name: 'normal'; Value: isc_dpb_shut_normal),
    (Name: 'multi'; Value: isc_dpb_shut_multi),
    (Name: 'single'; Value: isc_dpb_shut_single),
    (Name: 'full'; Value: isc_dpb_shut_full)
  );

  function PartValue(const Part: string): Integer;
  var
    i, Code: Integer;
  begin
    for i := Low(ShutdownWords) to High(ShutdownWords) do
      if SameText(Part, ShutdownWords[i].Name) then
      begin
        Result := ShutdownWords[i].Value;
        Exit;
      end;
    Val(Part, Result, Code);
    if (Code <> 0) or (Result < 0) or (Result > High(Byte)) then
      FIBError(feParamValueInvalid, [Part, 'DBParams shutdown']);
  end;

var
  i, PartStart: Integer;
  Params, Part: string;
begin
  Result := 0;
  Params := string(ParamString);
  PartStart := 1;
  for i := 1 to Length(Params) + 1 do
    if (i > Length(Params)) or (Params[i] = ',') or (Params[i] = ';') then
    begin
      Part := Trim(Copy(Params, PartStart, i - PartStart));
      if Part <> '' then
        Result := Result or PartValue(Part);
      PartStart := i + 1;
    end;
end;

function DPBUsesUTF8(sl: TStrings; IsFirebird: Boolean): Boolean;
var
  i, p: Integer;
  Name: string;
begin
  Result := False;
  if IsFirebird then
    for i := 0 to sl.Count - 1 do
    begin
      Name := sl[i];
      p := Pos('=', Name);
      if p > 0 then
        SetLength(Name, p - 1);
      Name := LowerCase(Trim(Name));
      if Pos(DPBPrefix, Name) = 1 then
        Delete(Name, 1, Length(DPBPrefix));
      if Name = 'utf8_filename' then
      begin
        Result := True;
        Exit;
      end;
    end;
end;

(*
  * GenerateDPB -
  *  Given a string containing a textual representation
  *  of the database parameters, generate a database
  *  parameter buffer, and return it and its length
  *  in DPB and DPBLength, respectively.
*)
procedure GenerateDPB(sl: TStrings; var DPB: AnsiString; var DPBLength: Short; IsFirebird: Boolean;
  AllowVersion2: Boolean);
var
  i: Integer;
  j, DPBVal: Integer;
  Dialect: Integer;
  param_name, param_value: AnsiString;
  config: AnsiString;
  Line, Value: string;
  UTF8: Boolean;
  UTF8Value: UTF8String;
  Clumplets: array of record
    Tag: Byte;
    Data: AnsiString;
  end;
  Count: Integer;
  Wide: Boolean;
  Size: Integer;

  // The clumplets are written at the end, when the length format is known
  procedure AddClumplet(Tag: Byte; const Data: AnsiString);
  begin
    if Length(Data) > 255 then
      begin
        if not (IsFirebird and AllowVersion2) then
          FIBError(feParamValueTooLong, [DPBConstantName(Tag), Length(Data), 255]);
        Wide := True;
      end;
    if Count = Length(Clumplets) then
      SetLength(Clumplets, Count + 16);
    Clumplets[Count].Tag := Tag;
    Clumplets[Count].Data := Data;
    Inc(Count);
  end;

  procedure ApplyStrParam;
  begin
    AddClumplet(DPBVal, param_value);
  end;

  // the engine reads 1 to 4 bytes
  procedure ApplyIntParam(IntValue: Integer);
  var
    Data: AnsiString;
  begin
    SetLength(Data, SizeOf(IntValue));
    Move(IntValue, Data[1], SizeOf(IntValue));
    AddClumplet(DPBVal, Data);
  end;

  function LengthBytes(Len: Integer): AnsiString;
  begin
    if Wide then
      begin
        SetLength(Result, 4);
        Move(Len, Result[1], 4);
      end
    else
      Result := AnsiChar(Len);
  end;

begin
  Count := 0;
  Wide := False;
  UTF8 := DPBUsesUTF8(sl, IsFirebird);
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
      Line := Trim(sl[i]);
      if Line = '' then
        Continue;

      j := Pos('=', Line);
      if j = 0 then
        j := Length(Line) + 1;
      param_name := AnsiString(Copy(Line, 1, j - 1));
      Value := Copy(Line, j + 1, MaxInt);
      if UTF8 then
        begin
          UTF8Value := UTF8Encode(Value);
          SetString(param_value, PAnsiChar(UTF8Value), Length(UTF8Value));
        end
      else
        param_value := AnsiString(Value);
      DoLowerCase(param_name);

      if (Pos(DPBPrefix, param_name) = 1) then
        param_name := FastCopy(param_name, Length(DPBPrefix) + 1, MaxInt);
      // Delete(param_name, 1, Length(DPBPrefix));
      (*
      * We want to translate the parameter name to some integer
      * value. We do this by scanning through a list of known
      * database parameter names (DPBConstantNames, defined above).
    *)
      // if DPBConstants.Find(param_name,j) then
      j := NonAnsiIndexOf(DPBConstants, param_name);
      if j > -1 then
        DPBVal := Integer(DPBConstants.Objects[j])
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
          isc_dpb_lc_messages, isc_dpb_lc_ctype, isc_dpb_sql_role_name,
          isc_dpb_sql_dialect, isc_dpb_old_file, isc_dpb_sys_encrypt_password:
          begin
            if DPBVal = isc_dpb_sql_dialect then
              begin
                Dialect := StrToIntDef(Trim(Value), 0);
                if (Dialect < 1) or (Dialect > 3) then
                  FIBError(feParamValueInvalid, [Value, 'DBParams sql_dialect']);
                param_value := AnsiChar(Dialect);
              end;
            ApplyStrParam
          end;
        isc_dpb_instance_name:
          begin
            // or isc_dpb_trusted_role
            if not IsFirebird then
              ApplyStrParam;
          end;
        isc_dpb_session_time_zone, isc_dpb_set_bind, isc_dpb_decfloat_round, isc_dpb_decfloat_traps:
          begin
            if IsFirebird then
              ApplyStrParam;
          end;
        isc_dpb_config:
          begin
            // The client reads only the first isc_dpb_config
            if IsFirebird and (param_value <> '') then
              if config = '' then
                config := param_value
              else
                config := config + #10 + param_value;
          end;
        isc_dpb_set_db_charset:
          begin
            // or isc_dpb_gbak_ods_version
            if IsFirebird then
              ApplyStrParam;
          end;

        isc_dpb_num_buffers, isc_dpb_dbkey_scope, isc_dpb_force_write,
          isc_dpb_no_reserve, isc_dpb_damaged, isc_dpb_verify, isc_dpb_dummy_packet_interval, isc_dpb_connect_timeout,
          isc_dpb_online_dump, isc_dpb_overwrite, isc_dpb_old_file_size, isc_dpb_shutdown_delay:
          ApplyIntParam(StrToInt(param_value));
        isc_dpb_sweep:
          AddClumplet(DPBVal, AnsiChar(isc_dpb_records));
        isc_dpb_sweep_interval:
          ApplyIntParam(StrToInt(param_value));
        isc_dpb_parallel_workers:
          begin
            if IsFirebird then
              ApplyIntParam(StrToInt(param_value));
          end;
        isc_dpb_activate_shadow, isc_dpb_delete_shadow, isc_dpb_begin_log, isc_dpb_quit_log:
          AddClumplet(DPBVal, #0);

        isc_dpb_utf8_filename:
          begin
            // or isc_dpb_archive_database
            if IsFirebird then
              AddClumplet(DPBVal, '');
          end;

        isc_dpb_no_db_triggers:
          begin
            // or isc_dpb_client_interbase_var
            if IsFirebird then
              AddClumplet(DPBVal, #1);
          end;

        //
        isc_dpb_no_garbage_collect, isc_dpb_garbage_collect:
          AddClumplet(DPBVal, #1);
        isc_dpb_shutdown:
          begin
            if Length(param_value) = 0 then
              AddClumplet(DPBVal, '')
            else
              AddClumplet(DPBVal, AnsiChar(GetDPBShutParamValue(param_value)));
          end;
        isc_dpb_online:
          AddClumplet(DPBVal, '');
        else
          begin
            if (DPBVal > 0) and (DPBVal <= isc_dpb_last_dpb_constant) then
              FIBError(feDPBConstantNotSupported, [DPBConstantNames[DPBVal]])
            else
              FIBError(feDPBConstantUnknown, [param_name]);
          end;
      end;
    end;
  if config <> '' then
    AddClumplet(isc_dpb_config, config);

  // version 2 has 4-byte lengths in every clumplet
  if Wide then
    DPB := AnsiChar(isc_dpb_version2)
  else
    DPB := AnsiChar(isc_dpb_version1);
  for i := 0 to Count - 1 do
    DPB := DPB + AnsiChar(Clumplets[i].Tag) + LengthBytes(Length(Clumplets[i].Data)) + Clumplets[i].Data;
  Size := Length(DPB);
  if Size > High(Short) then
    FIBError(feParamValueTooLong, ['DBParams', Size, High(Short)]);
  DPBLength := Size;
end;

(*
  * GenerateTPB -
  *  Given a string containing a textual representation
  *  of the transaction parameters, generate a transaction
  *  parameter buffer, and return it and its length in
  *  TPB and TPBLength, respectively.
*)
procedure GenerateTPB(sl: TStrings; var TPB: AnsiString; var TPBLength: Short; IsFB21orMore: Boolean;
  NameCodePage: Word);
var
  i, j, TPBVal, ParamLength: Integer;
  param_name, param_value: AnsiString;
  TableName: FIBByteString;
  LockTimeout: Integer;
begin
  TPB := '';
  if sl.Count > 0 then
    TPB := AnsiChar(isc_tpb_version3);
  for i := 0 to sl.Count - 1 do
    begin
      sl[i] := FastTrim(sl[i]);
      if sl[i] = '' then
        Continue;
      GetNameAndValue(sl[i], param_name, param_value);
      DoLowerCase(param_name);

      if (Pos(TPBPrefix, param_name) = 1) then
        param_name := FastCopy(param_name, Length(TPBPrefix) + 1, MaxInt);

      if TPBConstants.Find(param_name, j) then
        TPBVal := Integer(TPBConstants.Objects[j])
      else
        TPBVal := 0;
      // Now act on it
      case TPBVal of
        isc_tpb_consistency, isc_tpb_exclusive, isc_tpb_protected,
          isc_tpb_concurrency, isc_tpb_shared, isc_tpb_wait, isc_tpb_nowait,
          isc_tpb_read, isc_tpb_write, isc_tpb_ignore_limbo,
          isc_tpb_read_committed, isc_tpb_rec_version, isc_tpb_no_rec_version,
          isc_tpb_read_consistency, isc_tpb_no_auto_undo { ,isc_tpb_no_savepoint } :
          TPB := TPB + AnsiChar(TPBVal);
        isc_tpb_lock_read, isc_tpb_lock_write:
          begin
            TPB := TPB + AnsiChar(TPBVal);
            // the table name from the line: param_value went through the system code page
            j := PosCh('=', sl[i]);
            if j > 0 then
              TableName := EncodeString(FastCopy(sl[i], j + 1, MaxInt), NameCodePage)
            else
              TableName := '';
            ParamLength := Length(TableName);
            if ParamLength > 255 then
              FIBError(feParamValueTooLong, [string(param_name), ParamLength, 255]);
            TPB := TPB + AnsiChar(ParamLength) + TableName;
          end;
        else
          begin
            if (TPBVal > 0) and (TPBVal <= isc_tpb_last_tpb_constant) then
              begin
                if TPBVal <> isc_tpb_no_savepoint { isc_tpb_lock_timeout } then
                  FIBError(feTPBConstantNotSupported, [TPBConstantNames[TPBVal]])
                else
                  begin
                    if IsFB21orMore then
                      begin
                        // isc_tpb_lock_timeout: 4 bytes, the server checks the range
                        LockTimeout := StrToIntDef(string(param_value), 10);
                        TPB := TPB + AnsiChar(TPBVal) + #4 + PAnsiChar(@LockTimeout)[0] +
                          PAnsiChar(@LockTimeout)[1] + PAnsiChar(@LockTimeout)[2] + PAnsiChar(@LockTimeout)[3];
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
  if Length(TPB) > High(Short) then
    FIBError(feParamValueTooLong, ['TRParams', Length(TPB), High(Short)]);
  TPBLength := Length(TPB);
end;

function DPBConstantName(Code: Integer): string;
var
  Idx: Integer;
begin
  if (Code > 0) and (Code <= isc_dpb_last_dpb_constant) then
    Result := DPBConstantNames[Code]
  else
    begin
      Idx := DPBConstants.IndexOfObject(TObject(Code));
      if Idx = -1 then
        Result := ''
      else
        Result := DPBConstants[Idx];
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
var
  i: Integer;
begin
  TPBConstants := TStringList.Create;
  with TPBConstants do
    begin
      Capacity := isc_tpb_last_tpb_constant;
      for i := 1 to isc_tpb_last_tpb_constant do
        AddObject(TPBConstantNames[i], TObject(i));

      AddObject('lock_timeout', TObject(isc_tpb_lock_timeout));
      AddObject('read_consistency', TObject(isc_tpb_read_consistency));
      Sorted := true;
    end;
end;

procedure InitDPBConstantsList;
var
  i: Integer;
begin
  DPBConstants := TStringList.Create;
  with DPBConstants do
    begin
      Capacity := isc_dpb_last_dpb_constant;
      for i := 1 to isc_dpb_last_dpb_constant do
        AddObject(DPBConstantNames[i], TObject(i));
      AddObject('no_db_triggers', TObject(isc_dpb_no_db_triggers));
      AddObject('set_db_charset', TObject(isc_dpb_set_db_charset));
      AddObject('utf8_filename', TObject(isc_dpb_utf8_filename));
      AddObject('session_time_zone', TObject(isc_dpb_session_time_zone));
      AddObject('set_bind', TObject(isc_dpb_set_bind));
      AddObject('decfloat_round', TObject(isc_dpb_decfloat_round));
      AddObject('decfloat_traps', TObject(isc_dpb_decfloat_traps));
      AddObject('config', TObject(isc_dpb_config));
      AddObject('parallel_workers', TObject(isc_dpb_parallel_workers));
      // Sorted:=true;
    end;
end;

initialization

FIBCS := TCriticalSection.Create; ;
IBErrorMessages := [ShowSQLMessage, ShowIBMessage, ShowSQLState, ShowRaiserName];
InitTPBConstantsList;
InitDPBConstantsList;

finalization

FreeAndNil(TPBConstants);
FreeAndNil(DPBConstants);
FreeAndNil(FIBCS)

end.
