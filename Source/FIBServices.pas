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

unit FIBServices;

interface

{$I FIB.inc}

uses

  SysUtils, Classes,
  ibase, IB_Intf, IB_Externals, Variants, FIBPlatforms;

const
  DefaultBufferSize = 32000;

  SPBPrefix = 'isc_spb_';
  SPBConstantNames: array [1 .. isc_spb_last_spb_constant] of string = (
    'user_name',
    'sys_user_name',
    'sys_user_name_enc',
    'password',
    'password_enc',
    'command_line',
    'db_name',
    'verbose',
    'options',
    'connect_timeout',
    'dummy_packet_interval',
    'sql_role_name',
    'instance_name'
  );

  SPBConstantValues: array [1 .. isc_spb_last_spb_constant] of Integer = (
    isc_spb_user_name_mapped_to_server,
    isc_spb_sys_user_name_mapped_to_server,
    isc_spb_sys_user_name_enc_mapped_to_server,
    isc_spb_password_mapped_to_server,
    isc_spb_password_enc_mapped_to_server,
    isc_spb_command_line_mapped_to_server,
    isc_spb_dbname_mapped_to_server,
    isc_spb_verbose_mapped_to_server,
    isc_spb_options_mapped_to_server,
    isc_spb_connect_timeout_mapped_to_server,
    isc_spb_dummy_packet_interval_mapped_to_server,
    isc_spb_sql_role_name_mapped_to_server,
    isc_spb_instance_name_mapped_to_server
  );

{$IFDEF INC_SERVICE_SUPPORT}
type
  TFIBProtocol = (TCP, SPX, NamedPipe, Local);
  TFIBOutputBufferOption = (ByLine, ByChunk);

  TFIBCustomService = class;

  TFIBServiceLoginEvent = procedure(Database: TFIBCustomService; LoginParams: TStrings) of object;

  TFIBCustomService = class(TComponent)
  private
    FClientLibrary: IFIBClientLibrary;
    FLibraryName: string;
    procedure LoadLibrary;
  private
    FIBLoaded: Boolean;
    FParamsChanged: Boolean;
    FSPB, FQuerySPB: PAnsiChar;
    FSPBLength, FQuerySPBLength: Integer;
    FOnLogin: TFIBServiceLoginEvent;
    FLoginPrompt: Boolean;
    FBufferSize: Integer;
    FOutputBuffer: PAnsiChar;
    FQueryParams: AnsiString;
    FServerName: string;
    FHandle: TISC_SVC_HANDLE;
    FStreamedActive: Boolean;
    FOnAttach: TNotifyEvent;
    FOutputBufferOption: TFIBOutputBufferOption;
    FProtocol: TFIBProtocol;
    FParams: TStrings;
    function GetActive: Boolean;
    function GetServiceParamBySPB(const Idx: Integer): String;
    procedure SetActive(const Value: Boolean);
    procedure SetBufferSize(const Value: Integer);
    procedure SetParams(const Value: TStrings);
    procedure SetServerName(const Value: string);
    procedure SetProtocol(const Value: TFIBProtocol);
    procedure SetServiceParamBySPB(const Idx: Integer; const Value: String);
    function IndexOfSPBConst(st: String): Integer;
    procedure ParamsChange(Sender: TObject);
    procedure ParamsChanging(Sender: TObject);
    procedure CheckServerName;
    function Call(ErrCode: ISC_STATUS; RaiseError: Boolean): ISC_STATUS;
    function ParseString(var RunLen: Integer): string;
    function ParseInteger(var RunLen: Integer): Integer;
    procedure GenerateSPB(sl: TStrings; var SPB: AnsiString; var SPBLength: Integer);
    procedure SetLibraryName(const Value: string);
    function StoredLibraryName: Boolean;
  protected
    procedure Loaded; override;
    function Login: Boolean;
    procedure CheckActive;
    procedure CheckInactive;
    procedure RaiseServiceError;
    property OutputBuffer: PAnsiChar read FOutputBuffer;
    property OutputBufferOption: TFIBOutputBufferOption read FOutputBufferOption write FOutputBufferOption;
    property BufferSize: Integer read FBufferSize write SetBufferSize default DefaultBufferSize;
    procedure InternalServiceQuery;
    property ServiceQueryParams: AnsiString read FQueryParams write FQueryParams;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Attach;
    procedure Detach;
    property Handle: TISC_SVC_HANDLE read FHandle;
    property ServiceParamBySPB[const Idx: Integer]: String read GetServiceParamBySPB write SetServiceParamBySPB;
    property ClientLibrary: IFIBClientLibrary read FClientLibrary;
    property SSPB: PAnsiChar read FSPB;
  published
    property Active: Boolean read GetActive write SetActive default False;
    property ServerName: string read FServerName write SetServerName;
    property LibraryName: string read FLibraryName write SetLibraryName stored StoredLibraryName;
    property Protocol: TFIBProtocol read FProtocol write SetProtocol default Local;
    property Params: TStrings read FParams write SetParams;
    property LoginPrompt: Boolean read FLoginPrompt write FLoginPrompt default True;
    property OnAttach: TNotifyEvent read FOnAttach write FOnAttach;
    property OnLogin: TFIBServiceLoginEvent read FOnLogin write FOnLogin;
  end;

  TFIBServerDatabaseInfo = class
  public
    NoOfAttachments: Integer;
    NoOfDatabases: Integer;
    DbName: array of string;
    destructor Destroy; override;
  end;

  TFIBLicenseInfo = class
  public
    Key: array of string;
    Id: array of string;
    Desc: array of string;
    LicensedUsers: Integer;
    destructor Destroy; override;
  end;

  TFIBLicenseMaskInfo = class
  public
    LicenseMask: Integer;
    CapabilityMask: Integer;
  end;

  TFIBConfigFileData = class
  public
    ConfigFileValue: array of Integer;
    ConfigFileKey: array of Integer;
    destructor Destroy; override;
  end;

  TFIBConfigParams = class
  public
    ConfigFileData: TFIBConfigFileData;
    ConfigFileParams: array of string;
    BaseLocation: string;
    LockFileLocation: string;
    MessageFileLocation: string;
    SecurityDatabaseLocation: string;
    constructor Create;
    destructor Destroy; override;
  end;

  TFIBServerVersionInfo = class
  public
    ServerVersion: String;
    ServerImplementation: string;
    ServiceVersion: Integer;
  end;

  TFIBServerPropertyOption = (Database, License, LicenseMask, ConfigParameters, Version);
  TFIBServerPropertyOptions = set of TFIBServerPropertyOption;

  TFIBServerProperties = class(TFIBCustomService)
  private
    FOptions: TFIBServerPropertyOptions;
    FDatabaseInfo: TFIBServerDatabaseInfo;
    FLicenseInfo: TFIBLicenseInfo;
    FLicenseMaskInfo: TFIBLicenseMaskInfo;
    FVersionInfo: TFIBServerVersionInfo;
    FConfigParams: TFIBConfigParams;
    procedure ParseConfigFileData(var RunLen: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Fetch;
    procedure FetchDatabaseInfo;
    procedure FetchLicenseInfo;
    procedure FetchLicenseMaskInfo;
    procedure FetchConfigParams;
    procedure FetchVersionInfo;
    property DatabaseInfo: TFIBServerDatabaseInfo read FDatabaseInfo;
    property LicenseInfo: TFIBLicenseInfo read FLicenseInfo;
    property LicenseMaskInfo: TFIBLicenseMaskInfo read FLicenseMaskInfo;
    property VersionInfo: TFIBServerVersionInfo read FVersionInfo;
    property ConfigParams: TFIBConfigParams read FConfigParams;
  published
    property Options: TFIBServerPropertyOptions read FOptions write FOptions;
  end;

  TFIBControlService = class(TFIBCustomService)
  private
    FStartParams: AnsiString;
    FStartSPB: PAnsiChar;
    FStartSPBLength: Integer;
    function GetIsServiceRunning: Boolean;
  protected
    property ServiceStartParams: AnsiString read FStartParams write FStartParams;
    procedure SetServiceStartOptions; virtual;
    procedure ServiceStartAddParam(const Value: string; param: Integer); overload;
    procedure ServiceStartAddParam(Value: Integer; param: Integer); overload;
    procedure ServiceStartAddFiles(Files: TStrings; FileParam, LengthParam: Integer);
    procedure InternalServiceStart;

  public
    procedure ServiceStart; virtual;
    property IsServiceRunning: Boolean read GetIsServiceRunning;
  end;

  TFIBServiceGetTextEvent = procedure(Sender: TObject; const Text: string) of object;

  TFIBControlAndQueryService = class(TFIBControlService)
  private
    FEof: Boolean;
    // bytes of a character cut at the end of the last chunk
    FChunkTail: FIBByteString;
    FAction: Integer;
    FOnTextNotify: TFIBServiceGetTextEvent;
    procedure SetAction(Value: Integer);
  protected
    property Action: Integer read FAction write SetAction;
    property OnTextNotify: TFIBServiceGetTextEvent read FOnTextNotify write FOnTextNotify;
  public
    function GetNextLine: String;
    function GetNextChunk: String;
    procedure ServiceStart; override;
    function GetNextBuf: AnsiString;
    property Eof: Boolean read FEof;
  published
    property BufferSize;
  end;

  TFIBShutdownMode = (Forced, DenyTransaction, DenyAttachment);

  TFIBConfigService = class(TFIBControlService)
  private
    FDatabaseName: string;
    procedure SetDatabaseName(const Value: string);
  protected

  public
    procedure ServiceStart; override;
    procedure ShutdownDatabase(Options: TFIBShutdownMode; Wait: Integer);
    procedure SetSweepInterval(Value: Integer);
    procedure SetDBSqlDialect(Value: Integer);
    procedure SetPageBuffers(Value: Integer);
    procedure ActivateShadow;
    procedure BringDatabaseOnline;
    procedure SetReserveSpace(Value: Boolean);
    procedure SetAsyncMode(Value: Boolean);
    procedure SetReadOnly(Value: Boolean);
  published
    property DatabaseName: string read FDatabaseName write SetDatabaseName;
  end;

  TFIBLogService = class(TFIBControlAndQueryService)
  private

  protected
    procedure SetServiceStartOptions; override;
  public
  published
    property OnTextNotify;
  end;

  TFIBStatisticsOption = (
    DataPages,
    DbLog,
    HeaderPages,
    IndexPages,
    SystemRelations,
    RecordVersions,
    StatTables
  );
  TFIBStatisticsOptions = set of TFIBStatisticsOption;

  TFIBStatisticalService = class(TFIBControlAndQueryService)
  private
    FDatabaseName: string;
    FOptions: TFIBStatisticsOptions;
    FTableNames: String;
    procedure SetDatabaseName(const Value: string);
  protected
    procedure SetServiceStartOptions; override;
  public
  published
    property DatabaseName: string read FDatabaseName write SetDatabaseName;
    property Options: TFIBStatisticsOptions read FOptions write FOptions;
    property TableNames: String read FTableNames write FTableNames;
    property OnTextNotify;
  end;

  TFIBBackupRestoreService = class(TFIBControlAndQueryService)
  private
    FVerbose: Boolean;
    FParallelWorkers: Integer;
  protected
  public
  published
    property ParallelWorkers: Integer read FParallelWorkers write FParallelWorkers default 0;
    property Verbose: Boolean read FVerbose write FVerbose default False;
    property OnTextNotify;
  end;

  TFIBBackupOption = (
    IgnoreChecksums,
    IgnoreLimbo,
    MetadataOnly,
    NoGarbageCollection,
    OldMetadataDesc,
    NonTransportable,
    ConvertExtTables
  );
  TFIBBackupOptions = set of TFIBBackupOption;

  TFIBBackupService = class(TFIBBackupRestoreService)
  private
    FDatabaseName: string;
    FOptions: TFIBBackupOptions;
    FBackupFile: TStrings;
    FBlockingFactor: Integer;
    procedure SetBackupFile(const Value: TStrings);
  protected
    procedure SetServiceStartOptions; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

  published
    { a name=value pair of filename and length }
    property BackupFile: TStrings read FBackupFile write SetBackupFile;
    property BlockingFactor: Integer read FBlockingFactor write FBlockingFactor;
    property DatabaseName: string read FDatabaseName write FDatabaseName;
    property Options: TFIBBackupOptions read FOptions write FOptions;
  end;

  TFIBRestoreOption = (
    DeactivateIndexes,
    NoShadow,
    NoValidityCheck,
    OneRelationAtATime,
    Replace,
    CreateNewDB,
    UseAllSpace,
    ValidationCheck,
    OnlyMetadata,
    FixFssMetadata,
    FixFssData
  );

  TFIBRestoreOptions = set of TFIBRestoreOption;

  TFIBRestoreService = class(TFIBBackupRestoreService)
  private
    FDatabaseName: TStrings;
    FBackupFile: TStrings;
    FOptions: TFIBRestoreOptions;
    FPageSize: Integer;
    FPageBuffers: Integer;
    FFixCharset: string;
    procedure SetBackupFile(const Value: TStrings);
    procedure SetDatabaseName(const Value: TStrings);
  protected
    procedure SetServiceStartOptions; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    { a name=value pair of filename and length }
    property DatabaseName: TStrings read FDatabaseName write SetDatabaseName;
    property BackupFile: TStrings read FBackupFile write SetBackupFile;
    property PageSize: Integer read FPageSize write FPageSize default 0;
    property PageBuffers: Integer read FPageBuffers write FPageBuffers;
    property FixCharset: string read FFixCharset write FFixCharset;
    property Options: TFIBRestoreOptions read FOptions write FOptions default [CreateNewDB];
  end;

  // Firebird 2.5 and later
  TFIBNBackupService = class(TFIBControlAndQueryService)
  private
    FDatabaseName: String;
    FLevel: Integer;
    FBackupFile: string;
  protected
    procedure SetServiceStartOptions; override;
  public
    procedure BackUp(const DbName, BackupName: string; aLevel: Integer);
  published
    property BackupFile: string read FBackupFile write FBackupFile;
    property DatabaseName: String read FDatabaseName write FDatabaseName;
    property Level: Integer read FLevel write FLevel default 0;
  end;

  // Firebird 2.5 and later
  TFIBNRestoreService = class(TFIBControlAndQueryService)
  private
    FDatabaseName: string;
    FBackupFiles: TStrings;
    procedure SetBackupFiles(const Value: TStrings);
  protected
    procedure SetServiceStartOptions; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Restore(const aBackUpFiles: array of string; const DbName: string);
  published
    property BackupFiles: TStrings read FBackupFiles write SetBackupFiles;
    property DatabaseName: String read FDatabaseName write FDatabaseName;
  end;

  TFIBValidateOption = (
    LimboTransactions,
    CheckDB,
    IgnoreChecksum,
    KillShadows,
    MendDB,
    SweepDB,
    ValidateDB,
    ValidateFull
  );
  TFIBValidateOptions = set of TFIBValidateOption;

  TFIBLimboGlobalAction = (CommitGlobal, RollbackGlobal, RecoverTwoPhaseGlobal, NoGlobalAction);
  TFIBLimboTransactionState = (LimboState, CommitState, RollbackState, UnknownState);
  TFIBLimboTransactionAdvise = (CommitAdvise, RollbackAdvise, UnknownAdvise);
  TFIBLimboTransactionAction = (CommitAction, RollbackAction);

  TFIBLimboTransactionInfo = class
  public
    MultiDatabase: Boolean;
    Id: Integer;
    HostSite: String;
    RemoteSite: String;
    RemoteDatabasePath: String;
    State: TFIBLimboTransactionState;
    Advise: TFIBLimboTransactionAdvise;
    Action: TFIBLimboTransactionAction;
  end;

  TFIBValidationService = class(TFIBControlAndQueryService)
  private
    FDatabaseName: string;
    FOptions: TFIBValidateOptions;
    FParallelWorkers: Integer;
    FLimboTransactionInfo: array of TFIBLimboTransactionInfo;
    FGlobalAction: TFIBLimboGlobalAction;
    procedure SetDatabaseName(const Value: string);
    procedure ClearLimboTransactionInfo;
    function GetLimboTransactionInfo(Index: Integer): TFIBLimboTransactionInfo;
    function GetLimboTransactionInfoCount: Integer;

  protected
    procedure SetServiceStartOptions; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure FetchLimboTransactionInfo;
    procedure FixLimboTransactionErrors;
    property LimboTransactionInfo[Index: Integer]: TFIBLimboTransactionInfo read GetLimboTransactionInfo;
    property LimboTransactionInfoCount: Integer read GetLimboTransactionInfoCount;

  published
    property DatabaseName: string read FDatabaseName write SetDatabaseName;
    property Options: TFIBValidateOptions read FOptions write FOptions;
    property ParallelWorkers: Integer read FParallelWorkers write FParallelWorkers default 0;
    property GlobalAction: TFIBLimboGlobalAction read FGlobalAction write FGlobalAction;
    property OnTextNotify;
  end;

  TFIBUserInfo = class
  public
    UserName: string;
    FirstName: string;
    MiddleName: string;
    LastName: string;
    GroupID: Integer;
    UserID: Integer;
  end;

  TFIBSecurityAction = (ActionAddUser, ActionDeleteUser, ActionModifyUser, ActionDisplayUser);
  TFIBSecurityModifyParam = (
    ModifyFirstName,
    ModifyMiddleName,
    ModifyLastName,
    ModifyUserId,
    ModifyGroupId,
    ModifyPassword,
    ModifySecAdmin
  );
  TFIBSecurityModifyParams = set of TFIBSecurityModifyParam;

  TFIBSecurityService = class(TFIBControlAndQueryService)
  private
    FUserID: Integer;
    FGroupID: Integer;
    FSecAdmin: Boolean;
    FFirstName: string;
    FUserName: string;
    FPassword: string;
    FSQLRole: string;
    FLastName: string;
    FMiddleName: string;
    FUserInfo: array of TFIBUserInfo;
    FSecurityAction: TFIBSecurityAction;
    FModifyParams: TFIBSecurityModifyParams;
    procedure ClearParams;
    procedure SetSecurityAction(Value: TFIBSecurityAction);
    procedure SetFirstName(Value: String);
    procedure SetMiddleName(Value: String);
    procedure SetLastName(Value: String);
    procedure SetPassword(Value: String);
    procedure SetUserId(Value: Integer);
    procedure SetGroupId(Value: Integer);
    procedure SetSecAdmin(Value: Boolean);
    procedure FetchUserInfo;
    procedure ClearUserInfo;
    function GetUserInfo(Index: Integer): TFIBUserInfo;
    function GetUserInfoCount: Integer;

  protected
    procedure Loaded; override;
    procedure SetServiceStartOptions; override;
  public
    destructor Destroy; override;
    procedure DisplayUsers;
    procedure DisplayUser(UserName: string);
    procedure AddUser;
    procedure DeleteUser;
    procedure ModifyUser;
    procedure ServiceStart; override;
    property UserInfo[Index: Integer]: TFIBUserInfo read GetUserInfo;
    property UserInfoCount: Integer read GetUserInfoCount;

  published
    property SecurityAction: TFIBSecurityAction read FSecurityAction write SetSecurityAction;
    property SQlRole: string read FSQLRole write FSQLRole;
    property UserName: string read FUserName write FUserName;
    property FirstName: string read FFirstName write SetFirstName;
    property MiddleName: string read FMiddleName write SetMiddleName;
    property LastName: string read FLastName write SetLastName;
    property UserID: Integer read FUserID write SetUserId;
    property GroupID: Integer read FGroupID write SetGroupId;
    property Password: string read FPassword write SetPassword;
    property SecAdmin: Boolean read FSecAdmin write SetSecAdmin default False;
  end;

{$ENDIF}

type
  // Deprecated names of the types renamed in 8.0.0
{$IFDEF INC_SERVICE_SUPPORT}
  TProtocol = TFIBProtocol deprecated 'Use TFIBProtocol';
  TOutputBufferOption = TFIBOutputBufferOption deprecated 'Use TFIBOutputBufferOption';
  TLoginEvent = TFIBServiceLoginEvent deprecated 'Use TFIBServiceLoginEvent';
  TDatabaseInfo = TFIBServerDatabaseInfo deprecated 'Use TFIBServerDatabaseInfo';
  TLicenseInfo = TFIBLicenseInfo deprecated 'Use TFIBLicenseInfo';
  TLicenseMaskInfo = TFIBLicenseMaskInfo deprecated 'Use TFIBLicenseMaskInfo';
  TConfigFileData = TFIBConfigFileData deprecated 'Use TFIBConfigFileData';
  TConfigParams = TFIBConfigParams deprecated 'Use TFIBConfigParams';
  TVersionInfo = TFIBServerVersionInfo deprecated 'Use TFIBServerVersionInfo';
  TPropertyOption = TFIBServerPropertyOption deprecated 'Use TFIBServerPropertyOption';
  TPropertyOptions = TFIBServerPropertyOptions deprecated 'Use TFIBServerPropertyOptions';
  TServiceGetTextNotify = TFIBServiceGetTextEvent deprecated 'Use TFIBServiceGetTextEvent';
  TShutdownMode = TFIBShutdownMode deprecated 'Use TFIBShutdownMode';
  TStatOption = TFIBStatisticsOption deprecated 'Use TFIBStatisticsOption';
  TStatOptions = TFIBStatisticsOptions deprecated 'Use TFIBStatisticsOptions';
  TBackupOption = TFIBBackupOption deprecated 'Use TFIBBackupOption';
  TBackupOptions = TFIBBackupOptions deprecated 'Use TFIBBackupOptions';
  TRestoreOption = TFIBRestoreOption deprecated 'Use TFIBRestoreOption';
  TRestoreOptions = TFIBRestoreOptions deprecated 'Use TFIBRestoreOptions';
  TValidateOption = TFIBValidateOption deprecated 'Use TFIBValidateOption';
  TValidateOptions = TFIBValidateOptions deprecated 'Use TFIBValidateOptions';
  TTransactionGlobalAction = TFIBLimboGlobalAction deprecated 'Use TFIBLimboGlobalAction';
  TTransactionAdvise = TFIBLimboTransactionAdvise deprecated 'Use TFIBLimboTransactionAdvise';
  TServiceTransactionAction = TFIBLimboTransactionAction deprecated 'Use TFIBLimboTransactionAction';
  TLimboTransactionInfo = TFIBLimboTransactionInfo deprecated 'Use TFIBLimboTransactionInfo';
  TUserInfo = TFIBUserInfo deprecated 'Use TFIBUserInfo';
  TSecurityAction = TFIBSecurityAction deprecated 'Use TFIBSecurityAction';
  TSecurityModifyParam = TFIBSecurityModifyParam deprecated 'Use TFIBSecurityModifyParam';
  TSecurityModifyParams = TFIBSecurityModifyParams deprecated 'Use TFIBSecurityModifyParams';
  TTransactionState = TFIBLimboTransactionState deprecated 'Use TFIBLimboTransactionState';
{$ENDIF}

implementation

{$IFDEF  INC_SERVICE_SUPPORT}
uses
  RTLConsts, StrUtil, FIBCharSets,
{$IFNDEF NO_MONITOR}
  FIBSQLMonitor,
{$ENDIF}
  FIB;

// Lower case, without the 'isc_spb_' prefix, as in SPBConstantNames
function NormalizeSPBName(const Name: String): String;
begin
  Result := LowerCase(Name);
  if Pos(SPBPrefix, Result) = 1 then
    Delete(Result, 1, Length(SPBPrefix));
end;

// The service API takes 2-byte lengths
function ServiceBufferLength(BufferLength: Integer; const Name: string): Word;
begin
  if BufferLength > High(Word) then
    FIBError(feParamValueTooLong, [Name, BufferLength, High(Word)]);
  Result := Word(BufferLength);
end;

{ TFIBCustomService }

procedure TFIBCustomService.Attach;
var
  SPB: AnsiString;
  ConnectString: string;
  AnsiConnectString: FIBByteString;
begin
  CheckInactive;
  CheckServerName;

  if FLoginPrompt and not Login then
    FIBError(feOperationCancelled, [nil]);

  { Generate a new SPB if necessary }
  if FParamsChanged then
  begin
    FParamsChanged := False;
    GenerateSPB(FParams, SPB, FSPBLength);
    FIBAlloc(FSPB, 0, FSPBLength);
    Move(SPB[1], FSPB[0], FSPBLength);
  end;
  case FProtocol of
    TCP: ConnectString := FServerName + ':service_mgr'; { do not localize }
    SPX: ConnectString := FServerName + '@service_mgr'; { do not localize }
    NamedPipe: ConnectString := '\\' + FServerName + '\service_mgr'; { do not localize }
    Local: ConnectString := 'service_mgr'; { do not localize }
  end;
  LoadLibrary;
  AnsiConnectString := EncodeString(ConnectString, FIBCodePageSystem);
  // length 0: null terminated
  if Call(FClientLibrary.isc_service_attach(StatusVector, 0, PAnsiChar(AnsiConnectString), @FHandle,
    ServiceBufferLength(FSPBLength, 'Params'), FSPB), False) > 0 then
  begin
    FHandle := nil;
    IBError(FClientLibrary, Self);
  end;

  if Assigned(FOnAttach) then
    FOnAttach(Self);
{$IFNDEF NO_MONITOR}
  MonitorHook.ServiceAttach(Self);
{$ENDIF}
end;

procedure TFIBCustomService.Loaded;
begin
  inherited Loaded;
  try
    if FStreamedActive and (not Active) then
      Attach;
  except
    on E: Exception do
      if csDesigning in ComponentState then
      begin
        ShowException(E, nil);
      end
      else
        raise;
  end;
end;

function TFIBCustomService.Login: Boolean;
var
  IndexOfUser, IndexOfPassword, IndexOfRole: Integer;
  UserName, Password, RoleName: String;
  LoginParams: TStrings;
begin
  if Assigned(FOnLogin) then
  begin
    result := True;
    LoginParams := TStringList.Create;
    try
      LoginParams.Assign(Params);
      FOnLogin(Self, LoginParams);
      Params.Assign(LoginParams);
    finally
      LoginParams.Free;
    end;
  end
  else
  begin
    IndexOfUser := IndexOfSPBConst(SPBConstantNames[isc_spb_user_name]);
    if IndexOfUser <> -1 then
      UserName := Copy(Params[IndexOfUser], Pos('=', Params[IndexOfUser]) + 1, { mbcs ok } Length(Params[IndexOfUser]));
    IndexOfPassword := IndexOfSPBConst(SPBConstantNames[isc_spb_password]);
    if IndexOfPassword <> -1 then
      Password := Copy(Params[IndexOfPassword], Pos('=', Params[IndexOfPassword]) + 1, { mbcs ok }
        Length(Params[IndexOfPassword]));

    IndexOfRole := IndexOfSPBConst(SPBConstantNames[isc_spb_sql_role_name]);
    if IndexOfRole <> -1 then
      RoleName := Copy(Params[IndexOfRole], Pos('=', Params[IndexOfRole]) + 1, Length(Params[IndexOfRole]));
    if not Assigned(FIBLoginDialog) then
      result := False
    else
      result := FIBLoginDialog(ServerName, UserName, Password, RoleName);

    if result then
    begin
      IndexOfPassword := IndexOfSPBConst(SPBConstantNames[isc_spb_password]);
      if IndexOfUser = -1 then
        Params.Add(SPBConstantNames[isc_spb_user_name] + '=' + UserName)
      else
        Params[IndexOfUser] := SPBConstantNames[isc_spb_user_name] + '=' + UserName;
      if IndexOfPassword = -1 then
        Params.Add(SPBConstantNames[isc_spb_password] + '=' + Password)
      else
        Params[IndexOfPassword] := SPBConstantNames[isc_spb_password] + '=' + Password;
      if IndexOfRole = -1 then
        Params.Add(SPBConstantNames[isc_spb_sql_role_name] + '=' + RoleName)
      else
        Params[IndexOfRole] := SPBConstantNames[isc_spb_sql_role_name] + '=' + RoleName;
    end;
  end;
end;

procedure TFIBCustomService.CheckActive;
begin
  if FStreamedActive and (not Active) then
    Loaded;
  if FHandle = nil then
    FIBError(feServiceActive, [nil]);
end;

procedure TFIBCustomService.CheckInactive;
begin
  if FHandle <> nil then
    FIBError(feServiceInActive, [nil]);
end;

constructor TFIBCustomService.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLibraryName := CLIENT_DLL;
  FIBLoaded := True;
  FProtocol := local;
  FParams := TStringList.Create;
  FParamsChanged := True;
  TStringList(FParams).OnChange := ParamsChange;
  TStringList(FParams).OnChanging := ParamsChanging;
  FBufferSize := DefaultBufferSize;
  FLoginPrompt := True;
end;

destructor TFIBCustomService.Destroy;
begin
  if FIBLoaded and Assigned(FClientLibrary) and (FHandle <> nil) then
    try
      Detach;
    except
      // Detach releases the handle also on an error, the rest is freed below
    end;
  FreeMem(FSPB);
  FSPB := nil;
  FreeMem(FOutputBuffer);
  FParams.Free;
  FClientLibrary := nil;
  inherited Destroy;
end;

procedure TFIBCustomService.Detach;
begin
  CheckActive;
  LoadLibrary;
  if (Call(FClientLibrary.isc_service_detach(StatusVector, @FHandle), False) > 0) then
  begin
    FHandle := nil;
    IBError(FClientLibrary, Self);
  end
  else
    FHandle := nil;
{$IFNDEF NO_MONITOR}
  MonitorHook.ServiceDetach(Self);
{$ENDIF}
end;

// Raises the error of the last call of the service API. The service is detached
// first, a handle cleared without isc_service_detach keeps the attachment on the server.
procedure TFIBCustomService.RaiseServiceError;
var
  DetachStatus: array [0 .. 19] of ISC_STATUS;
begin
  try
    IBError(FClientLibrary, Self);
  except
    if FHandle <> nil then
      FClientLibrary.isc_service_detach(@DetachStatus[0], @FHandle);
    FHandle := nil;
    raise;
  end;
end;

procedure TFIBCustomService.LoadLibrary;
begin
  if not Assigned(FClientLibrary) then
    FClientLibrary := IB_Intf.GetClientLibrary(FLibraryName);
end;

function TFIBCustomService.GetActive: Boolean;
begin
  result := FHandle <> nil;
end;

function TFIBCustomService.GetServiceParamBySPB(const Idx: Integer): String;
var
  ConstIdx, EqualsIdx: Integer;
begin
  if (Idx > 0) and (Idx <= isc_spb_last_spb_constant) then
  begin
    ConstIdx := IndexOfSPBConst(SPBConstantNames[Idx]);
    if ConstIdx = -1 then
      result := ''
    else
    begin
      result := Params[ConstIdx];
      EqualsIdx := Pos('=', result); { mbcs ok }
      if EqualsIdx = 0 then
        result := ''
      else
        result := Copy(result, EqualsIdx + 1, Length(result));
    end;
  end
  else
    result := '';
end;

procedure TFIBCustomService.InternalServiceQuery;
var
  OutputLength: Integer;
begin
  FQuerySPBLength := Length(FQueryParams);
  if FQuerySPBLength = 0 then
    FIBError(feQueryParamsError, [nil]);
  FIBAlloc(FQuerySPB, 0, FQuerySPBLength);
  Move(FQueryParams[1], FQuerySPB[0], FQuerySPBLength);
  if (FOutputBuffer = nil) then
    FIBAlloc(FOutputBuffer, 0, FBufferSize);
  // the API fills at most 65535 bytes
  OutputLength := FBufferSize;
  if OutputLength > High(Word) then
    OutputLength := High(Word);
  try
    LoadLibrary;
    if Call(FClientLibrary.isc_service_query(StatusVector, @FHandle, nil, 0, nil,
      ServiceBufferLength(FQuerySPBLength, 'QueryParams'), FQuerySPB, Word(OutputLength), FOutputBuffer),
      False) > 0 then
      RaiseServiceError;
  finally
    FreeMem(FQuerySPB);
    FQuerySPB := nil;
    FQuerySPBLength := 0;
    FQueryParams := '';
  end;
{$IFNDEF NO_MONITOR}
  MonitorHook.ServiceQuery(Self);
{$ENDIF}
end;

procedure TFIBCustomService.SetActive(const Value: Boolean);
begin
  if csReading in ComponentState then
    FStreamedActive := Value
  else if Value <> Active then
    if Value then
      Attach
    else
      Detach;
end;

procedure TFIBCustomService.SetBufferSize(const Value: Integer);
begin
  if (Value <> FBufferSize) then
  begin
    FBufferSize := Value;
    if FOutputBuffer <> nil then
      FIBAlloc(FOutputBuffer, 0, FBufferSize);
  end;
end;

procedure TFIBCustomService.SetParams(const Value: TStrings);
begin
  FParams.Assign(Value);
end;

procedure TFIBCustomService.SetServerName(const Value: string);
begin
  if FServerName <> Value then
  begin
    CheckInactive;
    FServerName := Value;
    if (FProtocol = Local) and (FServerName <> '') then
      FProtocol := TCP
    else if (FProtocol <> Local) and (FServerName = '') then
      FProtocol := Local;
  end;
end;

procedure TFIBCustomService.SetProtocol(const Value: TFIBProtocol);
begin
  if FProtocol <> Value then
  begin
    CheckInactive;
    FProtocol := Value;
    if (Value = Local) then
      FServerName := '';
  end;
end;

procedure TFIBCustomService.SetServiceParamBySPB(const Idx: Integer; const Value: String);
var
  ConstIdx: Integer;
begin
  ConstIdx := IndexOfSPBConst(SPBConstantNames[Idx]);
  if (Value = '') then
  begin
    if ConstIdx <> -1 then
      Params.Delete(ConstIdx);
  end
  else
  begin
    if (ConstIdx = -1) then
      Params.Add(SPBConstantNames[Idx] + '=' + Value)
    else
      Params[ConstIdx] := SPBConstantNames[Idx] + '=' + Value;
  end;
end;

function TFIBCustomService.IndexOfSPBConst(st: String): Integer;
var
  i: Integer;
begin
  for i := 0 to Params.Count - 1 do
    if NormalizeSPBName(Params.Names[i]) = st then
    begin
      Result := i;
      Exit;
    end;
  Result := -1;
end;

procedure TFIBCustomService.ParamsChange(Sender: TObject);
begin
  FParamsChanged := True;
end;

procedure TFIBCustomService.ParamsChanging(Sender: TObject);
begin
  CheckInactive;
end;

procedure TFIBCustomService.CheckServerName;
begin
  if (FServerName = '') and (FProtocol <> Local) then
    FIBError(feServerNameMissing, [nil]);
end;

function TFIBCustomService.Call(ErrCode: ISC_STATUS; RaiseError: Boolean): ISC_STATUS;
begin
  result := ErrCode;
  if RaiseError and (ErrCode > 0) then
    IBError(FClientLibrary, Self);
end;

function TFIBCustomService.ParseString(var RunLen: Integer): string;
var
  Len: UShort;
begin
  LoadLibrary;
  // unsigned: isc_vax_integer extends the sign of the 2 bytes
  Len := Word(FClientLibrary.isc_vax_integer(OutputBuffer + RunLen, 2));
  RunLen := RunLen + 2;
  result := DecodeServerText(OutputBuffer + RunLen, Len);
  RunLen := RunLen + Len;
end;

function TFIBCustomService.ParseInteger(var RunLen: Integer): Integer;
begin
  LoadLibrary;
  result := FClientLibrary.isc_vax_integer(OutputBuffer + RunLen, 4);
  RunLen := RunLen + 4;
end;

{
  * GenerateSPB -
  *  Given a string containing a textual representation
  *  of the Service parameters, generate a service
  *  parameter buffer, and return it and its length
  *  in SPB and SPBLength, respectively.
}
procedure TFIBCustomService.GenerateSPB(sl: TStrings; var SPB: AnsiString; var SPBLength: Integer);
var
  i, j: Integer;
  SPBVal, SPBServerVal: Integer;
  param_name, param_value: String;
  AnsiValue: FIBByteString;
  pval: Integer;
begin
  { The SPB is initially empty, with the exception that
    the SPB version must be the first byte of the string.
  }
  SPBLength := 2;
  SPB := AnsiChar(isc_spb_version);
  SPB := SPB + AnsiChar(isc_spb_current_version);
  { Iterate through the textual service parameters, constructing
    a SPB on-the-fly }
  for i := 0 to sl.Count - 1 do
  begin
    { Get the parameter's name and value from the list,
      and make sure that the name is all lowercase with
      no leading 'isc_spb_' prefix }
    if (Trim(sl.Names[i]) = '') then
      continue;
    param_name := NormalizeSPBName(sl.Names[i]);
    param_value := Copy(sl[i], Pos('=', sl[i]) + 1, Length(sl[i])); { mbcs ok }
    { We want to translate the parameter name to some integer
      value. We do this by scanning through a list of known
      service parameter names (SPBConstantNames, defined above). }
    SPBVal := 0;
    SPBServerVal := 0;
    { Find the parameter }
    for j := 1 to isc_spb_last_spb_constant do
      if (param_name = SPBConstantNames[j]) then
      begin
        SPBVal := j;
        SPBServerVal := SPBConstantValues[j];
        break;
      end;
    case SPBVal of
      isc_spb_command_line, isc_spb_user_name, isc_spb_password, isc_spb_sql_role_name:
        begin
          AnsiValue := EncodeParam(param_name, param_value, FIBCodePageSystem);
          if Length(AnsiValue) > 255 then
            FIBError(feParamValueTooLong, [param_name, Length(AnsiValue), 255]);
          SPB := SPB + AnsiChar(SPBServerVal) + AnsiChar(Length(AnsiValue)) + AnsiValue;
          Inc(SPBLength, 2 + Length(AnsiValue));
        end;
      isc_spb_connect_timeout, isc_spb_dummy_packet_interval:
        begin
          pval := StrToInt(param_value);
          SPB := SPB + AnsiChar(SPBServerVal) + #4 + PAnsiChar(@pval)[0] +
            PAnsiChar(@pval)[1] + PAnsiChar(@pval)[2] + PAnsiChar(@pval)[3];
          Inc(SPBLength, 6);
        end;

    else
      begin
        if (SPBVal > 0) and (SPBVal <= isc_spb_last_spb_constant) then
          FIBError(feSPBConstantNotSupported, [SPBConstantNames[SPBVal]])
        else
          FIBError(feSPBConstantUnknown, [param_name]);
      end;
    end;
  end;
end;

procedure TFIBCustomService.SetLibraryName(const Value: string);
begin
  CheckInactive;
  if FLibraryName <> Value then
  begin
    FLibraryName := Value;
    FClientLibrary := nil;
  end;
end;

function TFIBCustomService.StoredLibraryName: Boolean;
begin
  Result := FLibraryName <> CLIENT_DLL;
end;

{ TFIBServerProperties }
constructor TFIBServerProperties.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDatabaseInfo := TFIBServerDatabaseInfo.Create;
  FLicenseInfo := TFIBLicenseInfo.Create;
  FLicenseMaskInfo := TFIBLicenseMaskInfo.Create;
  FVersionInfo := TFIBServerVersionInfo.Create;
  FConfigParams := TFIBConfigParams.Create;
end;

destructor TFIBServerProperties.Destroy;
begin
  FDatabaseInfo.Free;
  FLicenseInfo.Free;
  FLicenseMaskInfo.Free;
  FVersionInfo.Free;
  FConfigParams.Free;
  inherited Destroy;
end;

procedure TFIBServerProperties.ParseConfigFileData(var RunLen: Integer);
begin
  Inc(RunLen);
  with FConfigParams.ConfigFileData do
  begin
    SetLength(ConfigFileValue, Length(ConfigFileValue) + 1);
    SetLength(ConfigFileKey, Length(ConfigFileKey) + 1);

    ConfigFileKey[High(ConfigFileKey)] := Integer(OutputBuffer[RunLen - 1]);
    ConfigFileValue[High(ConfigFileValue)] := ParseInteger(RunLen);
  end;
end;

procedure TFIBServerProperties.Fetch;
begin
  if (Database in Options) then
    FetchDatabaseInfo;
  if (License in Options) then
    FetchLicenseInfo;
  if (LicenseMask in Options) then
    FetchLicenseMaskInfo;
  if (ConfigParameters in Options) then
    FetchConfigParams;
  if (Version in Options) then
    FetchVersionInfo;
end;

procedure TFIBServerProperties.FetchConfigParams;
var
  RunLen: Integer;

begin
  ServiceQueryParams := AnsiChar(isc_info_svc_get_config) +
    AnsiChar(isc_info_svc_get_env) + AnsiChar(isc_info_svc_get_env_lock) +
    AnsiChar(isc_info_svc_get_env_msg) + AnsiChar(isc_info_svc_user_dbpath);

  InternalServiceQuery;
  RunLen := 0;
  While (not(Integer(OutputBuffer[RunLen]) = isc_info_end)) do
  begin
    case Integer(OutputBuffer[RunLen]) of
      isc_info_svc_get_config:
        begin
          FConfigParams.ConfigFileData.ConfigFileKey := nil;
          FConfigParams.ConfigFileData.ConfigFileValue := nil;
          Inc(RunLen);
          while (not(Integer(OutputBuffer[RunLen]) = isc_info_flag_end)) do
            ParseConfigFileData(RunLen);
          if (Integer(OutputBuffer[RunLen]) = isc_info_flag_end) then
            Inc(RunLen);
        end;

      isc_info_svc_get_env:
        begin
          Inc(RunLen);
          FConfigParams.BaseLocation := ParseString(RunLen);
        end;

      isc_info_svc_get_env_lock:
        begin
          Inc(RunLen);
          FConfigParams.LockFileLocation := ParseString(RunLen);
        end;

      isc_info_svc_get_env_msg:
        begin
          Inc(RunLen);
          FConfigParams.MessageFileLocation := ParseString(RunLen);
        end;

      isc_info_svc_user_dbpath:
        begin
          Inc(RunLen);
          FConfigParams.SecurityDatabaseLocation := ParseString(RunLen);
        end;
    else
      FIBError(feOutputParsingError, [nil]);
    end;
  end;
end;

procedure TFIBServerProperties.FetchDatabaseInfo;
var
  i, RunLen: Integer;
begin
  ServiceQueryParams := AnsiChar(isc_info_svc_svr_db_info);
  InternalServiceQuery;
  if (OutputBuffer[0] <> AnsiChar(isc_info_svc_svr_db_info)) then
    FIBError(feOutputParsingError, [nil]);
  RunLen := 1;
  if (OutputBuffer[RunLen] <> AnsiChar(isc_spb_num_att)) then
    FIBError(feOutputParsingError, [nil]);
  Inc(RunLen);
  FDatabaseInfo.NoOfAttachments := ParseInteger(RunLen);
  if (OutputBuffer[RunLen] <> AnsiChar(isc_spb_num_db)) then
    FIBError(feOutputParsingError, [nil]);
  Inc(RunLen);
  FDatabaseInfo.NoOfDatabases := ParseInteger(RunLen);
  FDatabaseInfo.DbName := nil;
  SetLength(FDatabaseInfo.DbName, FDatabaseInfo.NoOfDatabases);
  i := 0;
  while (OutputBuffer[RunLen] <> AnsiChar(isc_info_flag_end)) do
  begin
    if (OutputBuffer[RunLen] <> AnsiChar(SPBConstantValues[isc_spb_dbname])) then
      FIBError(feOutputParsingError, [nil]);
    Inc(RunLen);
    FDatabaseInfo.DbName[i] := ParseString(RunLen);
    Inc(i);
  end;
end;

procedure TFIBServerProperties.FetchLicenseInfo;
var
  i, RunLen: Integer;
  done: Integer;
begin
  ServiceQueryParams := AnsiChar(isc_info_svc_get_license) + AnsiChar(isc_info_svc_get_licensed_users);
  InternalServiceQuery;
  RunLen := 0;
  done := 0;
  i := 0;
  FLicenseInfo.Key := nil;
  FLicenseInfo.Id := nil;
  FLicenseInfo.Desc := nil;

  While done < 2 do
  begin
    Inc(done);
    Inc(RunLen);
    case Integer(OutputBuffer[RunLen - 1]) of
      isc_info_svc_get_license:
        begin
          while (OutputBuffer[RunLen] <> AnsiChar(isc_info_flag_end)) do
          begin
            if (i >= Length(FLicenseInfo.Key)) then
            begin
              SetLength(FLicenseInfo.Key, i + 10);
              SetLength(FLicenseInfo.Id, i + 10);
              SetLength(FLicenseInfo.Desc, i + 10);
            end;
            if (OutputBuffer[RunLen] <> AnsiChar(isc_spb_lic_id)) then
              FIBError(feOutputParsingError, [nil]);
            Inc(RunLen);
            FLicenseInfo.Id[i] := ParseString(RunLen);
            if (OutputBuffer[RunLen] <> AnsiChar(isc_spb_lic_key)) then
              FIBError(feOutputParsingError, [nil]);
            Inc(RunLen);
            FLicenseInfo.Key[i] := ParseString(RunLen);
            if (OutputBuffer[RunLen] <> AnsiChar(7)) then
              FIBError(feOutputParsingError, [nil]);
            Inc(RunLen);
            FLicenseInfo.Desc[i] := ParseString(RunLen);
            Inc(i);
          end;
          Inc(RunLen);
          if (Length(FLicenseInfo.Key) > i) then
          begin
            SetLength(FLicenseInfo.Key, i);
            SetLength(FLicenseInfo.Id, i);
            SetLength(FLicenseInfo.Desc, i);
          end;
        end;
      isc_info_svc_get_licensed_users: FLicenseInfo.LicensedUsers := ParseInteger(RunLen);
    else
      FIBError(feOutputParsingError, [nil]);
    end;
  end;
end;

procedure TFIBServerProperties.FetchLicenseMaskInfo();
var
  done, RunLen: Integer;
begin
  ServiceQueryParams := AnsiChar(isc_info_svc_get_license_mask) + AnsiChar(isc_info_svc_capabilities);
  InternalServiceQuery;
  RunLen := 0;
  done := 0;
  While done <= 1 do
  begin
    Inc(done);
    Inc(RunLen);
    case Integer(OutputBuffer[RunLen - 1]) of
      isc_info_svc_get_license_mask: FLicenseMaskInfo.LicenseMask := ParseInteger(RunLen);
      isc_info_svc_capabilities: FLicenseMaskInfo.CapabilityMask := ParseInteger(RunLen);
    else
      FIBError(feOutputParsingError, [nil]);
    end;
  end;
end;

procedure TFIBServerProperties.FetchVersionInfo;
var
  RunLen: Integer;
  done: Integer;
begin
  ServiceQueryParams := AnsiChar(isc_info_svc_version) + AnsiChar(isc_info_svc_server_version) +
    AnsiChar(isc_info_svc_implementation);
  InternalServiceQuery;
  RunLen := 0;
  done := 0;

  While done <= 2 do
  begin
    Inc(done);
    Inc(RunLen);
    case Integer(OutputBuffer[RunLen - 1]) of
      isc_info_svc_version: FVersionInfo.ServiceVersion := ParseInteger(RunLen);
      isc_info_svc_server_version: FVersionInfo.ServerVersion := ParseString(RunLen);
      isc_info_svc_implementation: FVersionInfo.ServerImplementation := ParseString(RunLen);
    else
      FIBError(feOutputParsingError, [nil]);
    end;
  end;
end;

{ TFIBControlService }
procedure TFIBControlService.SetServiceStartOptions;
begin

end;

function TFIBControlService.GetIsServiceRunning: Boolean;
var
  RunLen: Integer;
begin
  ServiceQueryParams := AnsiChar(isc_info_svc_running);
  InternalServiceQuery;
  if (OutputBuffer[0] <> AnsiChar(isc_info_svc_running)) then
    FIBError(feOutputParsingError, [nil]);
  RunLen := 1;
  if (ParseInteger(RunLen) = 1) then
    result := True
  else
    result := False;
end;

// In the system code page: the client converts it to UTF-8 (no isc_spb_utf8_filename at attach)
procedure TFIBControlService.ServiceStartAddParam(const Value: string; param: Integer);
var
  Bytes: FIBByteString;
  Len: Integer;
  ParamName: string;
begin
  ParamName := Format('ServiceStartParams (%d)', [param]);
  Bytes := EncodeParam(ParamName, Value, FIBCodePageSystem);
  Len := Length(Bytes);
  // a 2-byte length
  if Len > High(Word) then
    FIBError(feParamValueTooLong, [ParamName, Len, High(Word)]);
  if Len > 0 then
    FStartParams := FStartParams + AnsiChar(param) + PAnsiChar(@Len)[0] + PAnsiChar(@Len)[1] + Bytes;
end;

procedure TFIBControlService.ServiceStartAddParam(Value: Integer; param: Integer);
begin
  FStartParams := FStartParams + AnsiChar(param) + PAnsiChar(@Value)[0] +
    PAnsiChar(@Value)[1] + PAnsiChar(@Value)[2] + PAnsiChar(@Value)[3];
end;

// Each line is a file name, or name=length for a multi-file backup or database
procedure TFIBControlService.ServiceStartAddFiles(Files: TStrings; FileParam, LengthParam: Integer);
var
  i, EqualsPos: Integer;
  Line: String;
begin
  for i := 0 to Files.Count - 1 do
  begin
    Line := Files[i];
    if Trim(Line) = '' then
      Continue;
    EqualsPos := Pos('=', Line);
    if EqualsPos = 0 then
      ServiceStartAddParam(Line, FileParam)
    else
    begin
      ServiceStartAddParam(Trim(Copy(Line, 1, EqualsPos - 1)), FileParam);
      ServiceStartAddParam(StrToInt(Trim(Copy(Line, EqualsPos + 1, MaxInt))), LengthParam);
    end;
  end;
end;

procedure TFIBControlService.InternalServiceStart;
begin
  CheckActive;
  FStartSPBLength := Length(FStartParams);
  if FStartSPBLength = 0 then
    FIBError(feStartParamsError, [nil]);
  FIBAlloc(FStartSPB, 0, FStartSPBLength);
  Move(FStartParams[1], FStartSPB[0], FStartSPBLength);
  try
    LoadLibrary;
    if Call(FClientLibrary.isc_service_start(StatusVector, @FHandle, nil,
      ServiceBufferLength(FStartSPBLength, 'StartParams'), FStartSPB), False) > 0 then
      RaiseServiceError;
  finally
    FreeMem(FStartSPB);
    FStartSPB := nil;
    FStartSPBLength := 0;
    FStartParams := '';
  end;
{$IFNDEF NO_MONITOR}
  MonitorHook.ServiceStart(Self);
{$ENDIF}
end;

procedure TFIBControlService.ServiceStart;
begin
  CheckActive;
  SetServiceStartOptions;
  InternalServiceStart;
end;

{ TFIBConfigService }

procedure TFIBConfigService.ServiceStart;
begin
  FIBError(feUseSpecificProcedures, [nil]);
end;

procedure TFIBConfigService.ActivateShadow;
begin
  ServiceStartParams := AnsiChar(isc_action_svc_properties);
  ServiceStartAddParam(FDatabaseName, SPBConstantValues[isc_spb_dbname]);
  ServiceStartAddParam(isc_spb_prp_activate, SPBConstantValues[isc_spb_options]);
  InternalServiceStart;
end;

procedure TFIBConfigService.BringDatabaseOnline;
begin
  ServiceStartParams := AnsiChar(isc_action_svc_properties);
  ServiceStartAddParam(FDatabaseName, SPBConstantValues[isc_spb_dbname]);
  ServiceStartAddParam(isc_spb_prp_db_online, SPBConstantValues[isc_spb_options]);
  InternalServiceStart;
end;

procedure TFIBConfigService.SetAsyncMode(Value: Boolean);
begin
  ServiceStartParams := AnsiChar(isc_action_svc_properties);
  ServiceStartAddParam(FDatabaseName, SPBConstantValues[isc_spb_dbname]);
  ServiceStartParams := ServiceStartParams + AnsiChar(isc_spb_prp_write_mode);
  if Value then
    ServiceStartParams := ServiceStartParams + AnsiChar(isc_spb_prp_wm_async)
  else
    ServiceStartParams := ServiceStartParams + AnsiChar(isc_spb_prp_wm_sync);
  InternalServiceStart;
end;

procedure TFIBConfigService.SetDatabaseName(const Value: string);
begin
  FDatabaseName := Value;
end;

procedure TFIBConfigService.SetPageBuffers(Value: Integer);
begin
  ServiceStartParams := AnsiChar(isc_action_svc_properties);
  ServiceStartAddParam(FDatabaseName, SPBConstantValues[isc_spb_dbname]);
  ServiceStartAddParam(Value, isc_spb_prp_page_buffers);
  InternalServiceStart;
end;

procedure TFIBConfigService.SetReadOnly(Value: Boolean);
begin
  ServiceStartParams := AnsiChar(isc_action_svc_properties);
  ServiceStartAddParam(FDatabaseName, SPBConstantValues[isc_spb_dbname]);
  ServiceStartParams := ServiceStartParams + AnsiChar(isc_spb_prp_access_mode);
  if Value then
    ServiceStartParams := ServiceStartParams + AnsiChar(isc_spb_prp_am_readonly)
  else
    ServiceStartParams := ServiceStartParams + AnsiChar(isc_spb_prp_am_readwrite);
  InternalServiceStart;
end;

procedure TFIBConfigService.SetReserveSpace(Value: Boolean);
begin
  ServiceStartParams := AnsiChar(isc_action_svc_properties);
  ServiceStartAddParam(FDatabaseName, SPBConstantValues[isc_spb_dbname]);
  ServiceStartParams := ServiceStartParams + AnsiChar(isc_spb_prp_reserve_space);
  if Value then
    ServiceStartParams := ServiceStartParams + AnsiChar(isc_spb_prp_res)
  else
    ServiceStartParams := ServiceStartParams + AnsiChar(isc_spb_prp_res_use_full);
  InternalServiceStart;
end;

procedure TFIBConfigService.SetSweepInterval(Value: Integer);
begin
  ServiceStartParams := AnsiChar(isc_action_svc_properties);
  ServiceStartAddParam(FDatabaseName, SPBConstantValues[isc_spb_dbname]);
  ServiceStartAddParam(Value, isc_spb_prp_sweep_interval);
  InternalServiceStart;
end;

procedure TFIBConfigService.SetDBSqlDialect(Value: Integer);
begin
  ServiceStartParams := AnsiChar(isc_action_svc_properties);
  ServiceStartAddParam(FDatabaseName, SPBConstantValues[isc_spb_dbname]);
  ServiceStartAddParam(Value, isc_spb_prp_set_sql_dialect);
  InternalServiceStart;
end;

procedure TFIBConfigService.ShutdownDatabase(Options: TFIBShutdownMode; Wait: Integer);
begin
  ServiceStartParams := AnsiChar(isc_action_svc_properties);
  ServiceStartAddParam(FDatabaseName, SPBConstantValues[isc_spb_dbname]);
  if (Options = Forced) then
    ServiceStartAddParam(Wait, isc_spb_prp_shutdown_db)
  else if (Options = DenyTransaction) then
    ServiceStartAddParam(Wait, isc_spb_prp_deny_new_transactions)
  else
    ServiceStartAddParam(Wait, isc_spb_prp_deny_new_attachments);
  InternalServiceStart;
end;

{ TFIBStatisticalService }

procedure TFIBStatisticalService.SetDatabaseName(const Value: string);
begin
  FDatabaseName := Value;
end;

procedure TFIBStatisticalService.SetServiceStartOptions;
var
  param: Integer;
begin
  if FDatabaseName = '' then
    FIBError(feStartParamsError, [nil]);
  param := 0;
  if (DataPages in Options) then
    param := param or isc_spb_sts_data_pages;
  if (DbLog in Options) then
    param := param or isc_spb_sts_db_log;
  if (HeaderPages in Options) then
    param := param or isc_spb_sts_hdr_pages;
  if (IndexPages in Options) then
    param := param or isc_spb_sts_idx_pages;
  if (SystemRelations in Options) then
    param := param or isc_spb_sts_sys_relations;
  if (RecordVersions in Options) then
    param := param or isc_spb_sts_record_versions;
  if (StatTables in Options) then
    param := param or isc_spb_sts_table;

  Action := isc_action_svc_db_stats;
  ServiceStartParams := AnsiChar(isc_action_svc_db_stats);
  ServiceStartAddParam(FDatabaseName, SPBConstantValues[isc_spb_dbname]);
  ServiceStartAddParam(param, SPBConstantValues[isc_spb_options]);
  if (StatTables in Options) then
    ServiceStartAddParam(FTableNames, SPBConstantValues[isc_spb_command_line]);
end;

{ TFIBBackupService }
procedure TFIBBackupService.SetServiceStartOptions;
var
  Param: Integer;
begin
  if FDatabaseName = '' then
    FIBError(feStartParamsError, [nil]);
  Param := 0;
  if (IgnoreChecksums in Options) then
    Param := Param or isc_spb_bkp_ignore_checksums;
  if (IgnoreLimbo in Options) then
    Param := Param or isc_spb_bkp_ignore_limbo;
  if (MetadataOnly in Options) then
    Param := Param or isc_spb_bkp_metadata_only;
  if (NoGarbageCollection in Options) then
    Param := Param or isc_spb_bkp_no_garbage_collect;
  if (OldMetadataDesc in Options) then
    Param := Param or isc_spb_bkp_old_descriptions;
  if (NonTransportable in Options) then
    Param := Param or isc_spb_bkp_non_transportable;
  if (ConvertExtTables in Options) then
    Param := Param or isc_spb_bkp_convert;
  Action := isc_action_svc_backup;
  ServiceStartParams := AnsiChar(isc_action_svc_backup);
  ServiceStartAddParam(FDatabaseName, SPBConstantValues[isc_spb_dbname]);
  ServiceStartAddParam(Param, SPBConstantValues[isc_spb_options]);
  if Verbose then
    ServiceStartParams := ServiceStartParams + AnsiChar(SPBConstantValues[isc_spb_verbose]);
  if FBlockingFactor > 0 then
    ServiceStartAddParam(FBlockingFactor, isc_spb_bkp_factor);
  if ParallelWorkers > 0 then
    ServiceStartAddParam(ParallelWorkers, isc_spb_bkp_parallel_workers);
  ServiceStartAddFiles(FBackupFile, isc_spb_bkp_file, isc_spb_bkp_length);
end;

constructor TFIBBackupService.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBackupFile := TStringList.Create;
end;

destructor TFIBBackupService.Destroy;
begin
  FBackupFile.Free;
  inherited Destroy;
end;

procedure TFIBBackupService.SetBackupFile(const Value: TStrings);
begin
  FBackupFile.Assign(Value);
end;

{ TFIBRestoreService }

procedure TFIBRestoreService.SetServiceStartOptions;
var
  Param: Integer;
begin
  Param := 0;
  if (DeactivateIndexes in Options) then
    Param := Param or isc_spb_res_deactivate_idx;
  if (NoShadow in Options) then
    Param := Param or isc_spb_res_no_shadow;
  if (NoValidityCheck in Options) then
    Param := Param or isc_spb_res_no_validity;
  if (OneRelationAtATime in Options) then
    Param := Param or isc_spb_res_one_at_a_time;
  if (Replace in Options) then
    Param := Param or isc_spb_res_replace;
  if (CreateNewDB in Options) then
    Param := Param or isc_spb_res_create;
  if (UseAllSpace in Options) then
    Param := Param or isc_spb_res_use_all_space;
  if (ValidationCheck in Options) then
    Param := Param or isc_spb_res_validate;
  if (OnlyMetadata in Options) then
    Param := Param or isc_spb_bkp_metadata_only;

  Action := isc_action_svc_restore;
  ServiceStartParams := AnsiChar(isc_action_svc_restore);
  ServiceStartAddParam(Param, SPBConstantValues[isc_spb_options]);
  if Verbose then
    ServiceStartParams := ServiceStartParams + AnsiChar(SPBConstantValues[isc_spb_verbose]);

  if (Length(FFixCharset) > 0) then
  begin
    if (FixFssMetadata in Options) then
      ServiceStartAddParam(FFixCharset, isc_spb_res_fix_fss_metadata);
    if (FixFssData in Options) then
      ServiceStartAddParam(FFixCharset, isc_spb_res_fix_fss_data);
  end;

  if FPageSize > 0 then
    ServiceStartAddParam(FPageSize, isc_spb_res_page_size);
  if FPageBuffers > 0 then
    ServiceStartAddParam(FPageBuffers, isc_spb_res_buffers);
  if ParallelWorkers > 0 then
    ServiceStartAddParam(ParallelWorkers, isc_spb_res_parallel_workers);
  ServiceStartAddFiles(FBackupFile, isc_spb_bkp_file, isc_spb_bkp_length);
  ServiceStartAddFiles(FDatabaseName, SPBConstantValues[isc_spb_dbname], isc_spb_res_length);
end;

constructor TFIBRestoreService.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDatabaseName := TStringList.Create;
  FBackupFile := TStringList.Create;
  Include(FOptions, CreateNewDB);
  FPageSize := 0;
end;

destructor TFIBRestoreService.Destroy;
begin
  FDatabaseName.Free;
  FBackupFile.Free;
  inherited Destroy;
end;

procedure TFIBRestoreService.SetBackupFile(const Value: TStrings);
begin
  FBackupFile.Assign(Value);
end;

procedure TFIBRestoreService.SetDatabaseName(const Value: TStrings);
begin
  FDatabaseName.Assign(Value);
end;

{ TFIBNBackupService }

procedure TFIBNBackupService.SetServiceStartOptions;
begin
  if (FDatabaseName = '') or (FBackupFile = '') then
    FIBError(feStartParamsError, [nil]);
  Action := isc_action_svc_nbak;
  ServiceStartParams := AnsiChar(isc_action_svc_nbak);
  ServiceStartAddParam(FDatabaseName, SPBConstantValues[isc_spb_dbname]);
  ServiceStartAddParam(FBackupFile, isc_spb_nbk_file);
  ServiceStartAddParam(FLevel, isc_spb_nbk_level);
end;

procedure TFIBNBackupService.BackUp(const DbName, BackupName: string; aLevel: Integer);
begin
  try
    DatabaseName := DbName;
    BackupFile := BackupName;
    Level := aLevel;
    Attach;
    ServiceStart;
  finally
    if Active then
      Detach;
  end;
end;

{ TFIBNRestoreService }

constructor TFIBNRestoreService.Create(AOwner: TComponent);
begin
  inherited;
  FBackupFiles := TStringList.Create;
end;

destructor TFIBNRestoreService.Destroy;
begin
  FBackupFiles.Free;
  inherited;
end;

procedure TFIBNRestoreService.SetBackupFiles(const Value: TStrings);
begin
  FBackupFiles.Assign(Value);
end;

procedure TFIBNRestoreService.SetServiceStartOptions;
var
  i: Integer;
begin
  if (FDatabaseName = '') or (FBackupFiles.Count = 0) then
    FIBError(feStartParamsError, [nil]);
  Action := isc_action_svc_nrest;
  ServiceStartParams := AnsiChar(isc_action_svc_nrest);
  ServiceStartAddParam(FDatabaseName, SPBConstantValues[isc_spb_dbname]);
  for i := 0 to FBackupFiles.Count - 1 do
  begin
    if (Trim(FBackupFiles[i]) = '') then
      continue;
    ServiceStartAddParam(FBackupFiles[i], isc_spb_nbk_file);
  end;
end;

procedure TFIBNRestoreService.Restore(const aBackUpFiles: array of string; const DbName: string);
var
  FileName: string;
begin
  DatabaseName := DbName;
  BackupFiles.Clear;
  for FileName in aBackUpFiles do
    BackupFiles.Add(FileName);

  try
    Attach;
    ServiceStart;
  finally
    if Active then
      Detach;
  end;
end;

{ TFIBValidationService }
constructor TFIBValidationService.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

destructor TFIBValidationService.Destroy;
begin
  ClearLimboTransactionInfo;
  inherited Destroy;
end;

procedure TFIBValidationService.ClearLimboTransactionInfo;
var
  i: NativeInt;
begin
  for i := 0 to High(FLimboTransactionInfo) do
    FLimboTransactionInfo[i].Free;
  FLimboTransactionInfo := nil;
end;

procedure TFIBValidationService.FetchLimboTransactionInfo;
var
  i, RunLen: Integer;
  Value: AnsiChar;
begin
  ServiceQueryParams := AnsiChar(isc_info_svc_limbo_trans);
  InternalServiceQuery;
  RunLen := 0;
  if (OutputBuffer[RunLen] <> AnsiChar(isc_info_svc_limbo_trans)) then
    FIBError(feOutputParsingError, [nil]);
  Inc(RunLen, 3);
  ClearLimboTransactionInfo;
  i := 0;
  try
    while (OutputBuffer[RunLen] <> AnsiChar(isc_info_end)) do
    begin
      if (i >= Length(FLimboTransactionInfo)) then
        SetLength(FLimboTransactionInfo, i + 10);
      FLimboTransactionInfo[i] := TFIBLimboTransactionInfo.Create;
      with FLimboTransactionInfo[i] do
      begin
        if (OutputBuffer[RunLen] = AnsiChar(isc_spb_single_tra_id)) then
        begin
          Inc(RunLen);
          MultiDatabase := False;
          Id := ParseInteger(RunLen);
        end
        else
        begin
          Inc(RunLen);
          MultiDatabase := True;
          Id := ParseInteger(RunLen);
          HostSite := ParseString(RunLen);
          if (OutputBuffer[RunLen] <> AnsiChar(isc_spb_tra_state)) then
            FIBError(feOutputParsingError, [nil]);
          Inc(RunLen);
          Value := OutputBuffer[RunLen];
          Inc(RunLen);
          if (Value = AnsiChar(isc_spb_tra_state_limbo)) then
            State := LimboState
          else if (Value = AnsiChar(isc_spb_tra_state_commit)) then
            State := CommitState
          else if (Value = AnsiChar(isc_spb_tra_state_rollback)) then
            State := RollbackState
          else
            State := UnknownState;
          RemoteSite := ParseString(RunLen);
          RemoteDatabasePath := ParseString(RunLen);
          Value := OutputBuffer[RunLen];
          Inc(RunLen);
          if (Value = AnsiChar(isc_spb_tra_advise_commit)) then
          begin
            Advise := CommitAdvise;
            Action := CommitAction;
          end
          else if (Value = AnsiChar(isc_spb_tra_advise_rollback)) then
          begin
            Advise := RollbackAdvise;
            Action := RollbackAction;
          end
          else
          begin
            { if no advice commit as default }
            Advise := UnknownAdvise;
            Action := CommitAction;
          end;
        end;
        Inc(i);
      end;
    end;
  except
    ClearLimboTransactionInfo;
    raise;
  end;
  SetLength(FLimboTransactionInfo, i);
end;

procedure TFIBValidationService.FixLimboTransactionErrors;
var
  i: NativeInt;
  RepairParam: Integer;
begin
  ServiceStartParams := AnsiChar(isc_action_svc_repair);
  ServiceStartAddParam(FDatabaseName, SPBConstantValues[isc_spb_dbname]);
  for i := 0 to High(FLimboTransactionInfo) do
  begin
    case FGlobalAction of
      CommitGlobal:
        RepairParam := isc_spb_rpr_commit_trans;
      RollbackGlobal:
        RepairParam := isc_spb_rpr_rollback_trans;
      RecoverTwoPhaseGlobal:
        RepairParam := isc_spb_rpr_recover_two_phase;
    else
      if FLimboTransactionInfo[i].Action = CommitAction then
        RepairParam := isc_spb_rpr_commit_trans
      else
        RepairParam := isc_spb_rpr_rollback_trans;
    end;
    ServiceStartAddParam(FLimboTransactionInfo[i].Id, RepairParam);
  end;
  InternalServiceStart;
end;

function TFIBValidationService.GetLimboTransactionInfo(Index: Integer): TFIBLimboTransactionInfo;
begin
  if (Index < 0) or (Index > High(FLimboTransactionInfo)) then
    raise EListError.CreateFmt(SListIndexError, [Index]);
  Result := FLimboTransactionInfo[Index];
end;

function TFIBValidationService.GetLimboTransactionInfoCount: Integer;
begin
  Result := Integer(Length(FLimboTransactionInfo));
end;

procedure TFIBValidationService.SetDatabaseName(const Value: string);
begin
  FDatabaseName := Value;
end;

procedure TFIBValidationService.SetServiceStartOptions;
var
  param: Integer;
begin
  Action := isc_action_svc_repair;
  if FDatabaseName = '' then
    FIBError(feStartParamsError, [nil]);
  param := 0;
  if (SweepDB in Options) then
    param := param or isc_spb_rpr_sweep_db;
  if (ValidateDB in Options) then
    param := param or isc_spb_rpr_validate_db;
  ServiceStartParams := AnsiChar(isc_action_svc_repair);
  ServiceStartAddParam(FDatabaseName, SPBConstantValues[isc_spb_dbname]);
  if param > 0 then
    ServiceStartAddParam(param, SPBConstantValues[isc_spb_options]);
  if (SweepDB in Options) and (FParallelWorkers > 0) then
    ServiceStartAddParam(FParallelWorkers, isc_spb_rpr_par_workers);
  param := 0;
  if (LimboTransactions in Options) then
    param := param or isc_spb_rpr_list_limbo_trans;
  if (CheckDB in Options) then
    param := param or isc_spb_rpr_check_db;
  if (IgnoreChecksum in Options) then
    param := param or isc_spb_rpr_ignore_checksum;
  if (KillShadows in Options) then
    param := param or isc_spb_rpr_kill_shadows;
  if (MendDB in Options) then
    param := param or isc_spb_rpr_mend_db;
  if (ValidateFull in Options) then
  begin
    param := param or isc_spb_rpr_full;
    if not(MendDB in Options) then
      param := param or isc_spb_rpr_validate_db;
  end;
  if param > 0 then
    ServiceStartAddParam(param, SPBConstantValues[isc_spb_options]);
end;

{ TFIBSecurityService }
destructor TFIBSecurityService.Destroy;
begin
  ClearUserInfo;
  inherited Destroy;
end;

procedure TFIBSecurityService.ClearUserInfo;
var
  i: NativeInt;
begin
  for i := 0 to High(FUserInfo) do
    FUserInfo[i].Free;
  FUserInfo := nil;
end;

procedure TFIBSecurityService.FetchUserInfo;
var
  i, RunLen: Integer;
begin
  ServiceQueryParams := AnsiChar(isc_info_svc_get_users);
  InternalServiceQuery;
  RunLen := 0;
  if (OutputBuffer[RunLen] <> AnsiChar(isc_info_svc_get_users)) then
    FIBError(feOutputParsingError, [nil]);
  Inc(RunLen);
  ClearUserInfo;
  i := 0;
  { Don't have any use for the combined length
    so increment past by 2 }
  Inc(RunLen, 2);
  try
    while (OutputBuffer[RunLen] <> AnsiChar(isc_info_end)) do
    begin
      if (i >= Length(FUserInfo)) then
        SetLength(FUserInfo, i + 10);
      if (OutputBuffer[RunLen] <> AnsiChar(isc_spb_sec_username)) then
        FIBError(feOutputParsingError, [nil]);
      Inc(RunLen);
      FUserInfo[i] := TFIBUserInfo.Create;
      FUserInfo[i].UserName := ParseString(RunLen);
      if (OutputBuffer[RunLen] <> AnsiChar(isc_spb_sec_firstname)) then
        FIBError(feOutputParsingError, [nil]);
      Inc(RunLen);
      FUserInfo[i].FirstName := ParseString(RunLen);
      if (OutputBuffer[RunLen] <> AnsiChar(isc_spb_sec_middlename)) then
        FIBError(feOutputParsingError, [nil]);
      Inc(RunLen);
      FUserInfo[i].MiddleName := ParseString(RunLen);
      if (OutputBuffer[RunLen] <> AnsiChar(isc_spb_sec_lastname)) then
        FIBError(feOutputParsingError, [nil]);
      Inc(RunLen);
      FUserInfo[i].LastName := ParseString(RunLen);
      if (OutputBuffer[RunLen] <> AnsiChar(isc_spb_sec_userId)) then
        FIBError(feOutputParsingError, [nil]);
      Inc(RunLen);
      FUserInfo[i].UserID := ParseInteger(RunLen);

      if (OutputBuffer[RunLen] <> AnsiChar(isc_spb_sec_groupid)) then
        FIBError(feOutputParsingError, [nil]);
      Inc(RunLen);
      FUserInfo[i].GroupID := ParseInteger(RunLen);

      Inc(i);
    end;
  except
    ClearUserInfo;
    raise;
  end;
  SetLength(FUserInfo, i);
end;

function TFIBSecurityService.GetUserInfo(Index: Integer): TFIBUserInfo;
begin
  if (Index < 0) or (Index > High(FUserInfo)) then
    raise EListError.CreateFmt(SListIndexError, [Index]);
  Result := FUserInfo[Index];
end;

function TFIBSecurityService.GetUserInfoCount: Integer;
begin
  Result := Integer(Length(FUserInfo));
end;

procedure TFIBSecurityService.AddUser;
begin
  SecurityAction := ActionAddUser;
  ServiceStart;
end;

procedure TFIBSecurityService.DeleteUser;
begin
  SecurityAction := ActionDeleteUser;
  ServiceStart;
end;

procedure TFIBSecurityService.DisplayUsers;
begin
  SecurityAction := ActionDisplayUser;
  ServiceStartParams := AnsiChar(isc_action_svc_display_user);
  ServiceStartAddParam(FSQLRole, SPBConstantValues[isc_spb_sql_role_name]);
  InternalServiceStart;
  FetchUserInfo;
end;

procedure TFIBSecurityService.DisplayUser(UserName: String);
begin
  SecurityAction := ActionDisplayUser;
  ServiceStartParams := AnsiChar(isc_action_svc_display_user);
  ServiceStartAddParam(UserName, isc_spb_sec_username);
  InternalServiceStart;
  FetchUserInfo;
end;

procedure TFIBSecurityService.ModifyUser;
begin
  SecurityAction := ActionModifyUser;
  ServiceStart;
end;

procedure TFIBSecurityService.SetSecurityAction(Value: TFIBSecurityAction);
begin
  FSecurityAction := Value;
  if Value = ActionDeleteUser then
    ClearParams;
end;

procedure TFIBSecurityService.ClearParams;
begin
  FModifyParams := [];
  FFirstName := '';
  FMiddleName := '';
  FLastName := '';
  FGroupID := 0;
  FUserID := 0;
  FPassword := '';
  FSecAdmin := False;
end;

procedure TFIBSecurityService.SetFirstName(Value: String);
begin
  FFirstName := Value;
  Include(FModifyParams, ModifyFirstName);
end;

procedure TFIBSecurityService.SetMiddleName(Value: String);
begin
  FMiddleName := Value;
  Include(FModifyParams, ModifyMiddleName);
end;

procedure TFIBSecurityService.SetLastName(Value: String);
begin
  FLastName := Value;
  Include(FModifyParams, ModifyLastName);
end;

procedure TFIBSecurityService.SetPassword(Value: String);
begin
  FPassword := Value;
  Include(FModifyParams, ModifyPassword);
end;

procedure TFIBSecurityService.SetUserId(Value: Integer);
begin
  FUserID := Value;
  Include(FModifyParams, ModifyUserId);
end;

procedure TFIBSecurityService.SetGroupId(Value: Integer);
begin
  FGroupID := Value;
  Include(FModifyParams, ModifyGroupId);
end;

procedure TFIBSecurityService.SetSecAdmin(Value: Boolean);
begin
  FSecAdmin := Value;
  Include(FModifyParams, ModifySecAdmin);
end;

procedure TFIBSecurityService.Loaded;
begin
  inherited Loaded;
  ClearParams;
end;

procedure TFIBSecurityService.SetServiceStartOptions;
begin
  case FSecurityAction of
    ActionAddUser:
      begin
        Action := isc_action_svc_add_user;
        if (Pos(' ', FUserName) > 0) then
          FIBError(feStartParamsError, [nil]);
        if FUserName = '' then
          FIBError(feStartParamsError, [nil]);
        ServiceStartParams := AnsiChar(isc_action_svc_add_user);
        ServiceStartAddParam(FUserName, isc_spb_sec_username);
        ServiceStartAddParam(FUserID, isc_spb_sec_userId);
        ServiceStartAddParam(FGroupID, isc_spb_sec_groupid);
        if (ModifySecAdmin in FModifyParams) then
          if FSecAdmin then
            ServiceStartAddParam(1, isc_spb_sec_admin)
          else
            ServiceStartAddParam(0, isc_spb_sec_admin);

        ServiceStartAddParam(FPassword, isc_spb_sec_password);
        ServiceStartAddParam(FFirstName, isc_spb_sec_firstname);
        ServiceStartAddParam(FMiddleName, isc_spb_sec_middlename);
        ServiceStartAddParam(FLastName, isc_spb_sec_lastname);
        ServiceStartAddParam(FSQLRole, SPBConstantValues[isc_spb_sql_role_name]);
      end;
    ActionDeleteUser:
      begin
        Action := isc_action_svc_delete_user;
        if FUserName = '' then
          FIBError(feStartParamsError, [nil]);
        ServiceStartParams := AnsiChar(isc_action_svc_delete_user);
        ServiceStartAddParam(FUserName, isc_spb_sec_username);
      end;
    ActionModifyUser:
      begin
        Action := isc_action_svc_modify_user;
        if FUserName = '' then
          FIBError(feStartParamsError, [nil]);
        ServiceStartParams := AnsiChar(isc_action_svc_modify_user);
        ServiceStartAddParam(FUserName, isc_spb_sec_username);
        if (ModifyUserId in FModifyParams) then
          ServiceStartAddParam(FUserID, isc_spb_sec_userId);
        if (ModifyGroupId in FModifyParams) then
          ServiceStartAddParam(FGroupID, isc_spb_sec_groupid);
        if (ModifyPassword in FModifyParams) then
          ServiceStartAddParam(FPassword, isc_spb_sec_password);
        if (ModifyFirstName in FModifyParams) then
          ServiceStartAddParam(FFirstName, isc_spb_sec_firstname);
        if (ModifyMiddleName in FModifyParams) then
          ServiceStartAddParam(FMiddleName, isc_spb_sec_middlename);
        if (ModifyLastName in FModifyParams) then
          ServiceStartAddParam(FLastName, isc_spb_sec_lastname);
        if (ModifySecAdmin in FModifyParams) then
          if FSecAdmin then
            ServiceStartAddParam(1, isc_spb_sec_admin)
          else
            ServiceStartAddParam(0, isc_spb_sec_admin);

        ServiceStartAddParam(FSQLRole, SPBConstantValues[isc_spb_sql_role_name]);
      end;
  end;
end;

// Each add or modify starts from cleared params; a failed call keeps them for a retry
procedure TFIBSecurityService.ServiceStart;
begin
  inherited ServiceStart;
  ClearParams;
end;

{ TIBUnStructuredService }
procedure TFIBControlAndQueryService.SetAction(Value: Integer);
begin
  FEof := False;
  FChunkTail := '';
  FAction := Value;
end;

// Bytes at the end of S that start a UTF-8 character but do not complete it
function IncompleteUTF8Tail(const S: FIBByteString): Integer;
var
  i, First, Need: Integer;
begin
  Result := 0;
  First := Length(S) - 2;
  if First < 1 then
    First := 1;
  for i := Length(S) downto First do
    if Byte(S[i]) >= $C0 then
    begin
      if Byte(S[i]) >= $F0 then
        Need := 4
      else if Byte(S[i]) >= $E0 then
        Need := 3
      else
        Need := 2;
      if Length(S) - i + 1 < Need then
        Result := Length(S) - i + 1;
      Exit;
    end
    else if Byte(S[i]) < $80 then
      Exit;
end;

function TFIBControlAndQueryService.GetNextChunk: String;
var
  Length, Tail: Integer;
  Bytes: FIBByteString;
begin
  if (FEof = True) then
  begin
    result := '';
    exit;
  end;
  if (FAction = 0) then
    FIBError(feQueryParamsError, [nil]);
  ServiceQueryParams := AnsiChar(isc_info_svc_to_eof);
  InternalServiceQuery;
  if (OutputBuffer[0] <> AnsiChar(isc_info_svc_to_eof)) then
    FIBError(feOutputParsingError, [nil]);
  LoadLibrary;
  // unsigned: isc_vax_integer extends the sign of the 2 bytes
  Length := Word(FClientLibrary.isc_vax_integer(OutputBuffer + 1, 2));
  if (OutputBuffer[3 + Length] = AnsiChar(isc_info_truncated)) then
    FEof := False
  else if (OutputBuffer[3 + Length] = AnsiChar(isc_info_end)) then
    FEof := True
  else
    FIBError(feOutputParsingError, [nil]);
  SetString(Bytes, PAnsiChar(@OutputBuffer[3]), Length);
  Bytes := FChunkTail + Bytes;
  if FEof then
    Tail := 0
  else
    Tail := IncompleteUTF8Tail(Bytes);
  FChunkTail := Copy(Bytes, System.Length(Bytes) - Tail + 1, Tail);
  result := DecodeServerText(PAnsiChar(Bytes), System.Length(Bytes) - Tail);
end;

procedure TFIBControlAndQueryService.ServiceStart;
begin
  inherited;
  if Assigned(FOnTextNotify) then
    while not Eof do
      FOnTextNotify(Self, GetNextLine);
end;

function TFIBControlAndQueryService.GetNextLine: String;
var
  Length: Integer;
begin
  if (FEof = True) then
  begin
    result := '';
    exit;
  end;
  if (FAction = 0) then
    FIBError(feQueryParamsError, [nil]);
  ServiceQueryParams := AnsiChar(isc_info_svc_line);
  InternalServiceQuery;
  if (OutputBuffer[0] <> AnsiChar(isc_info_svc_line)) then
    FIBError(feOutputParsingError, [nil]);
  LoadLibrary;
  // unsigned: isc_vax_integer extends the sign of the 2 bytes
  Length := Word(FClientLibrary.isc_vax_integer(OutputBuffer + 1, 2));
  if (OutputBuffer[3 + Length] <> AnsiChar(isc_info_end)) then
    FIBError(feOutputParsingError, [nil]);
  if (Length <> 0) then
    FEof := False
  else
  begin
    result := '';
    FEof := True;
    exit;
  end;
  result := DecodeServerText(OutputBuffer + 3, Length);
end;

{ TFIBLogService }

procedure TFIBLogService.SetServiceStartOptions;
begin
  Action := isc_action_svc_get_ib_log;
  ServiceStartParams := AnsiChar(isc_action_svc_get_ib_log);
end;

{ TFIBServerDatabaseInfo }

destructor TFIBServerDatabaseInfo.Destroy;
begin
  DbName := nil;
  inherited Destroy;
end;

{ TFIBLicenseInfo }

destructor TFIBLicenseInfo.Destroy;
begin
  Key := nil;
  Id := nil;
  Desc := nil;
  inherited Destroy;
end;

{ TFIBConfigFileData }

destructor TFIBConfigFileData.Destroy;
begin
  ConfigFileValue := nil;
  ConfigFileKey := nil;
  inherited Destroy;
end;

{ TFIBConfigParams }

constructor TFIBConfigParams.Create;
begin
  ConfigFileData := TFIBConfigFileData.Create;
end;

destructor TFIBConfigParams.Destroy;
begin
  ConfigFileData.Free;
  ConfigFileParams := nil;
  inherited Destroy;
end;

function TFIBControlAndQueryService.GetNextBuf: AnsiString;
var
  ALength: Integer;
begin
  result := '';
  if (Self.FEof = True) then
    exit;
  if (Self.FAction = 0) then
    FIBError(feQueryParamsError, [nil]);
  ServiceQueryParams := AnsiChar(isc_info_svc_to_eof);
  InternalServiceQuery;
  if (OutputBuffer[0] <> AnsiChar(isc_info_svc_to_eof)) then
    FIBError(feOutputParsingError, [nil]);
  // unsigned: isc_vax_integer extends the sign of the 2 bytes
  ALength := Word(ClientLibrary.isc_vax_integer(OutputBuffer + 1, 2));
  if (OutputBuffer[3 + ALength] = AnsiChar(isc_info_truncated)) then
    Self.FEof := False
  else if (OutputBuffer[3 + ALength] = AnsiChar(isc_info_end)) then
    Self.FEof := True
  else
    FIBError(feOutputParsingError, [nil]);
  SetString(result, PAnsiChar(@OutputBuffer[3]), ALength);
  // bytes kept by GetNextChunk
  if FChunkTail <> '' then
  begin
    result := FChunkTail + result;
    FChunkTail := '';
  end;
end;

{$ENDIF}

end.
