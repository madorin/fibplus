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

unit IB_Services;

interface

{$I FIBPlus.inc}
uses

  SysUtils, Classes,
  ibase, IB_Intf, IB_Externals {$IFDEF D6+}, Variants {$ELSE} ,StdFuncs {$ENDIF};


const
  DefaultBufferSize = 32000;

  SPBPrefix = 'isc_spb_';
  SPBConstantNames: array[1..isc_spb_last_spb_constant] of AnsiString = (
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

  SPBConstantValues: array[1..isc_spb_last_spb_constant] of Integer = (
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
    isc_spb_sql_role_name_mapped_to_server ,
    isc_spb_instance_name_mapped_to_server
  );

{$IFDEF INC_SERVICE_SUPPORT}

type
  TProtocol = (TCP, SPX, NamedPipe, Local);
  TOutputBufferOption = (ByLine, ByChunk);

  TpFIBCustomService = class;

  TLoginEvent = procedure(Database: TpFIBCustomService;
    LoginParams: TStrings) of object;

  TpFIBCustomService = class(TComponent)
  private
    FClientLibrary: IIBClientLibrary;
    FLibraryName: string;
    procedure LoadLibrary;
  private
    FIBLoaded: Boolean;
    FParamsChanged : Boolean;
    FSPB, FQuerySPB : PAnsiChar;
    FSPBLength, FQuerySPBLength : Short;
    // FTraceFlags: TTraceFlags;
    FOnLogin: TLoginEvent;
    FLoginPrompt: Boolean;
    FBufferSize: Integer;
    FOutputBuffer: PAnsiChar;
    FQueryParams: AnsiString;
    FServerName: AnsiString;
    FHandle: TISC_SVC_HANDLE;
    FStreamedActive  : Boolean;
    FOnAttach: TNotifyEvent;
    FOutputBufferOption: TOutputBufferOption;
    FProtocol: TProtocol;
    FParams: TStrings;
    // FGDSLibrary : IGDSLibrary;
    function GetActive: Boolean;
    function GetServiceParamBySPB(const Idx: Integer): String;
    procedure SetActive(const Value: Boolean);
    procedure SetBufferSize(const Value: Integer);
    procedure SetParams(const Value: TStrings);
    procedure SetServerName(const Value: Ansistring);
    procedure SetProtocol(const Value: TProtocol);
    procedure SetServiceParamBySPB(const Idx: Integer;
      const Value: String);
    function IndexOfSPBConst(st: String): Integer;
    procedure ParamsChange(Sender: TObject);
    procedure ParamsChanging(Sender: TObject);
    procedure CheckServerName;
    function Call(ErrCode: ISC_STATUS; RaiseError: Boolean): ISC_STATUS;
    function ParseString(var RunLen: Integer): Ansistring;
    function ParseInteger(var RunLen: Integer): Integer;
    procedure GenerateSPB(sl: TStrings; var SPB: AnsiString; var SPBLength: Short);
    procedure SetLibraryName(const Value: string);
    function StoredLibraryName: Boolean;
  protected
    procedure Loaded; override;
    function Login: Boolean;
    procedure CheckActive;
    procedure CheckInactive;
    property OutputBuffer : PAnsiChar read FOutputBuffer;
    property OutputBufferOption : TOutputBufferOption read FOutputBufferOption write FOutputBufferOption;
    property BufferSize : Integer read FBufferSize write SetBufferSize default DefaultBufferSize;
    procedure InternalServiceQuery;
    property ServiceQueryParams: AnsiString read FQueryParams write FQueryParams;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Attach;
    procedure Detach;
    property Handle: TISC_SVC_HANDLE read FHandle;
    property ServiceParamBySPB[const Idx: Integer]: String read GetServiceParamBySPB
                                                      write SetServiceParamBySPB;
    property ClientLibrary: IIBClientLibrary read FClientLibrary;
    property SSPB:PAnsiChar read FSPB;
  published
    property Active: Boolean read GetActive write SetActive default False;
    property ServerName: Ansistring read FServerName write SetServerName;
    property LibraryName:string read FLibraryName write SetLibraryName stored StoredLibraryName;
    property Protocol: TProtocol read FProtocol write SetProtocol default Local;
    property Params: TStrings read FParams write SetParams;
    property LoginPrompt: Boolean read FLoginPrompt write FLoginPrompt default True;
    // property TraceFlags: TTraceFlags read FTraceFlags write FTraceFlags;
    property OnAttach: TNotifyEvent read FOnAttach write FOnAttach;
    property OnLogin: TLoginEvent read FOnLogin write FOnLogin;
  end;

  TDatabaseInfo = class
  public
    NoOfAttachments: Integer;
    NoOfDatabases: Integer;
    DbName: array of string;
    constructor Create;
    destructor Destroy; override;
  end;

  TLicenseInfo = class
  public
    Key: array of string;
    Id: array of string;
    Desc: array of string;
    LicensedUsers: Integer;
    constructor Create;
    destructor Destroy; override;
  end;

  TLicenseMaskInfo = class
  public
    LicenseMask: Integer;
    CapabilityMask: Integer;
  end;

  TConfigFileData = class
  public
    ConfigFileValue: array of integer;
    ConfigFileKey: array of integer;
    constructor Create;
    destructor Destroy; override;
  end;

  TConfigParams = class
  public
    ConfigFileData: TConfigFileData;
    ConfigFileParams: array of string;
    BaseLocation: string;
    LockFileLocation: string;
    MessageFileLocation: string;
    SecurityDatabaseLocation: string;
    constructor Create;
    destructor Destroy; override;
  end;

  TVersionInfo = class
  public
    ServerVersion: String;
    ServerImplementation: string;
    ServiceVersion: Integer;
  end;

  TPropertyOption = (Database, License, LicenseMask, ConfigParameters, Version);
  TPropertyOptions = set of TPropertyOption;

  TpFIBServerProperties = class(TpFIBCustomService)
  private
    FOptions: TPropertyOptions;
    FDatabaseInfo: TDatabaseInfo;
    FLicenseInfo: TLicenseInfo;
    FLicenseMaskInfo: TLicenseMaskInfo;
    FVersionInfo: TVersionInfo;
    FConfigParams: TConfigParams;
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
    property DatabaseInfo: TDatabaseInfo read FDatabaseInfo;
    property LicenseInfo: TLicenseInfo read FLicenseInfo;
    property LicenseMaskInfo: TLicenseMaskInfo read FLicenseMaskInfo;
    property VersionInfo: TVersionInfo read FVersionInfo;
    property ConfigParams: TConfigParams read FConfigParams;
  published
    property Options : TPropertyOptions read FOptions write FOptions;
  end;

  TpFIBControlService = class (TpFIBCustomService)
  private
    FStartParams: AnsiString;
    FStartSPB: PAnsiChar;
    FStartSPBLength: Integer;
    function GetIsServiceRunning: Boolean;
  protected
    property ServiceStartParams: AnsiString read FStartParams write FStartParams;
    procedure SetServiceStartOptions; virtual;
    procedure ServiceStartAddParam (Value: Ansistring; param: Integer); overload;
    procedure ServiceStartAddParam (Value: Integer; param: Integer); overload;
    procedure InternalServiceStart;

  public
    constructor Create(AOwner: TComponent); override;
    procedure ServiceStart; virtual;
    property IsServiceRunning : Boolean read GetIsServiceRunning;
  end;

  TServiceGetTextNotify = procedure (Sender: TObject; const Text: string) of object;

  TpFIBControlAndQueryService = class (TpFIBControlService)
  private
    FEof: Boolean;
    FAction: Integer;
    FOnTextNotify: TServiceGetTextNotify;
    procedure SetAction(Value: Integer);
  protected
    property Action: Integer read FAction write SetAction;
    property OnTextNotify: TServiceGetTextNotify read FOnTextNotify write FOnTextNotify;
  public
    constructor Create (AOwner: TComponent); override;
    function GetNextLine : String;
    function GetNextChunk : String;
    procedure ServiceStart; override;
    function GetNextBuf: AnsiString;
    property Eof: boolean read FEof;
  published
    property BufferSize;
  end;

 
  TShutdownMode = (Forced, DenyTransaction, DenyAttachment);

  TpFIBConfigService = class(TpFIBControlService)
  private
    FDatabaseName: string;
    procedure SetDatabaseName(const Value: string);
  protected

  public
    procedure ServiceStart; override;
    procedure ShutdownDatabase (Options: TShutdownMode; Wait: Integer);
    procedure SetSweepInterval (Value: Integer);
    procedure SetDBSqlDialect (Value: Integer);
    procedure SetPageBuffers (Value: Integer);
    procedure ActivateShadow;
    procedure BringDatabaseOnline;
    procedure SetReserveSpace (Value: Boolean);
    procedure SetAsyncMode (Value: Boolean);
    procedure SetReadOnly (Value: Boolean);
  published
    property DatabaseName: string read FDatabaseName write SetDatabaseName;
  end;

  TLicensingAction = (LicenseAdd, LicenseRemove);
  TpFIBLicensingService = class(TpFIBControlService)
  private
    FID: String;
    FKey: String;
    FAction: TLicensingAction;
    procedure SetAction(Value: TLicensingAction);
  protected
    procedure SetServiceStartOptions; override;
  public
    procedure AddLicense;
    procedure RemoveLicense;
  published
    property Action: TLicensingAction read FAction write SetAction default LicenseAdd;
    property Key: String read FKey write FKey;
    property ID: String  read FID write FID;
  end;

  TpFIBLogService = class(TpFIBControlAndQueryService)
  private

  protected
    procedure SetServiceStartOptions; override;
  public
  published
    property OnTextNotify;
  end;

  TStatOption = (DataPages, DbLog, HeaderPages, IndexPages, SystemRelations,
                 RecordVersions, StatTables);
  TStatOptions = set of TStatOption;

  TpFIBStatisticalService = class(TpFIBControlAndQueryService)
  private
    FDatabaseName : string;
    FOptions : TStatOptions;
    FTableNames : String;
    procedure SetDatabaseName(const Value: string);
  protected
    procedure SetServiceStartOptions; override;
  public
  published
    property DatabaseName: string read FDatabaseName write SetDatabaseName;
    property Options :  TStatOptions read FOptions write FOptions;
    property TableNames : String read FTableNames write FTableNames;
    property OnTextNotify;
  end;


  TpFIBBackupRestoreService = class(TpFIBControlAndQueryService)
  private
    FVerbose: Boolean;
  protected
  public
  published
    property Verbose : Boolean read FVerbose write FVerbose default False;
    property OnTextNotify;
  end;

  TBackupOption = (IgnoreChecksums, IgnoreLimbo, MetadataOnly, NoGarbageCollection,
    OldMetadataDesc, NonTransportable, ConvertExtTables);
  TBackupOptions = set of TBackupOption;

  TpFIBBackupService = class (TpFIBBackupRestoreService)
  private
    FDatabaseName: string;
    FOptions: TBackupOptions;
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
    property Options : TBackupOptions read FOptions write FOptions;
  end;

  TRestoreOption = (DeactivateIndexes, NoShadow, NoValidityCheck, OneRelationAtATime,
    Replace, CreateNewDB, UseAllSpace, ValidationCheck, OnlyMetadata,
   FixFssMetadata,FixFssData
  );

  TRestoreOptions = set of TRestoreOption;
  TpFIBRestoreService = class (TpFIBBackupRestoreService)
  private
    FDatabaseName: TStrings;
    FBackupFile: TStrings;
    FOptions: TRestoreOptions;
    FPageSize: Integer;
    FPageBuffers: Integer;
    FFixCharset :Ansistring;
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
    property PageSize: Integer read FPageSize write FPageSize default 4096;
    property PageBuffers: Integer read FPageBuffers write FPageBuffers;
    property FixCharset :Ansistring read FFixCharset write FFixCharset;
    property Options : TRestoreOptions read FOptions write FOptions default [CreateNewDB];
  end;

// Firebird 2.5 only  
  TpFIBNBackupService = class (TpFIBControlAndQueryService)
  private
    FDatabaseName: String;
    FLevel: Integer;
    FBackupFile: string;
  protected
    procedure SetServiceStartOptions; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure BackUp(const DBName, BackupName:string; aLevel:integer);
  published
    property BackupFile: string read FBackupFile write FBackupFile;
    property DatabaseName: String read FDatabaseName write FDatabaseName;
    property Level: Integer read FLevel write FLevel default 0;
  end;

// Firebird 2.5 only
  TpFIBNRestoreService = class (TpFIBControlAndQueryService)
  private
    FDatabaseName: string;
    FBackupFiles: TStrings;
    procedure SetBackupFiles(const Value: TStrings);
  protected
    procedure SetServiceStartOptions; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure  Restore(const aBackUpFiles: array of string; const DBName:string);
  published
    property BackupFiles: TStrings read FBackupFiles write SetBackupFiles;
    property DatabaseName: String read FDatabaseName write FDatabaseName;
  end;

  TValidateOption = (LimboTransactions, CheckDB, IgnoreChecksum, KillShadows, MendDB,
    SweepDB, ValidateDB, ValidateFull);
  TValidateOptions = set of TValidateOption;

  TTransactionGlobalAction = (CommitGlobal, RollbackGlobal, RecoverTwoPhaseGlobal,
                             NoGlobalAction);
  TTransactionState = (LimboState, CommitState, RollbackState, UnknownState);
  TTransactionAdvise = (CommitAdvise, RollbackAdvise, UnknownAdvise);
  TServiceTransactionAction = (CommitAction, RollbackAction);

  TLimboTransactionInfo = class
  public
    MultiDatabase: Boolean;
    ID: Integer;
    HostSite: String;
    RemoteSite: String;
    RemoteDatabasePath: String;
    State: TTransactionState;
    Advise: TTransactionAdvise;
    Action: TServiceTransactionAction;
  end;

  TpFIBValidationService = class(TpFIBControlAndQueryService)
  private
    FDatabaseName: string;
    FOptions: TValidateOptions;
    FLimboTransactionInfo: array of TLimboTransactionInfo;
    FGlobalAction: TTransactionGlobalAction;
    procedure SetDatabaseName(const Value: string);
    function GetLimboTransactionInfo(index: integer): TLimboTransactionInfo;
    function GetLimboTransactionInfoCount: integer;

  protected
    procedure SetServiceStartOptions; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure FetchLimboTransactionInfo;
    procedure FixLimboTransactionErrors;
    property LimboTransactionInfo[Index: integer]: TLimboTransactionInfo read GetLimboTransactionInfo;
    property LimboTransactionInfoCount: Integer read GetLimboTransactionInfoCount;

  published
    property DatabaseName: string read FDatabaseName write SetDatabaseName;
    property Options: TValidateOptions read FOptions write FOptions;
    property GlobalAction: TTransactionGlobalAction read FGlobalAction
                                         write FGlobalAction;
    property OnTextNotify;
  end;

  TUserInfo = class
  public
    UserName: string;
    FirstName: string;
    MiddleName: string;
    LastName: string;
    GroupID: Integer;
    UserID: Integer;
  end;

  TSecurityAction = (ActionAddUser, ActionDeleteUser, ActionModifyUser, ActionDisplayUser);
  TSecurityModifyParam = (ModifyFirstName, ModifyMiddleName, ModifyLastName, ModifyUserId,
                         ModifyGroupId, ModifyPassword,ModifySecAdmin);
  TSecurityModifyParams = set of TSecurityModifyParam;

  TpFIBSecurityService = class(TpFIBControlAndQueryService)
  private
    FUserID: Integer;
    FGroupID: Integer;
    FSecAdmin:boolean;
    FFirstName: string;
    FUserName: string;
    FPassword: string;
    FSQLRole: string;
    FLastName: string;
    FMiddleName: string;
    FUserInfo: array of TUserInfo;
    FSecurityAction: TSecurityAction;
    FModifyParams: TSecurityModifyParams;
    procedure ClearParams;
    procedure SetSecurityAction (Value: TSecurityAction);
    procedure SetFirstName (Value: String);
    procedure SetMiddleName (Value: String);
    procedure SetLastName (Value: String);
    procedure SetPassword (Value: String);
    procedure SetUserId (Value: Integer);
    procedure SetGroupId (Value: Integer);
    procedure SetSecAdmin(Value:boolean);
    procedure FetchUserInfo;
    function GetUserInfo(Index: Integer): TUserInfo;
    function GetUserInfoCount: Integer;

  protected
    procedure Loaded; override;
    procedure SetServiceStartOptions; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure DisplayUsers;
    procedure DisplayUser(UserName: string);
    procedure AddUser;
    procedure DeleteUser;
    procedure ModifyUser;
    property  UserInfo[Index: Integer]: TUserInfo read GetUserInfo;
    property  UserInfoCount: Integer read GetUserInfoCount;

  published
    property SecurityAction: TSecurityAction read FSecurityAction
                                             write SetSecurityAction;
    property SQlRole : string read FSQLRole write FSQLrole;
    property UserName : string read FUserName write FUserName;
    property FirstName : string read FFirstName write SetFirstName;
    property MiddleName : string read FMiddleName write SetMiddleName;
    property LastName : string read FLastName write SetLastName;
    property UserID : Integer read FUserID write SetUserID;
    property GroupID : Integer read FGroupID write SetGroupID;
    property Password : string read FPassword write SetPassword;
    property SecAdmin:boolean read FSecAdmin write SetSecAdmin default False;
  end;

{$ENDIF}


implementation

{$IFDEF  INC_SERVICE_SUPPORT}
uses
  StrUtil,
  {$IFNDEF NO_MONITOR}
  FIBSQLMonitor,
  {$ENDIF}
  fib;

{ TpFIBCustomService }

procedure TpFIBCustomService.Attach;
var
  SPB: AnsiString;
  ConnectString: AnsiString;
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
    FIBAlloc(FSPB, 0, FsPBLength);
    Move(SPB[1], FSPB[0], FSPBLength);
  end;
  case FProtocol of
    TCP: ConnectString := FServerName + ':service_mgr'; {do not localize}
    SPX: ConnectString := FServerName + '@service_mgr'; {do not localize}
    NamedPipe: ConnectString := '\\' + FServerName + '\service_mgr'; {do not localize}
    Local: ConnectString := 'service_mgr'; {do not localize}
  end;
  LoadLibrary;
  if Call(FClientLibrary.isc_service_attach(StatusVector, Length(ConnectString),
                         PAnsiChar(ConnectString), @FHandle,
                         FSPBLength, FSPB), False) > 0 then
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

procedure TpFIBCustomService.Loaded;
begin
  inherited Loaded;
  try
    if FStreamedActive and (not Active) then
      Attach;
  except
    on E:Exception do
    if csDesigning in ComponentState then
    begin
      ShowException(E,nil);
    end
    else
      raise;
  end;
end;

function TpFIBCustomService.Login: Boolean;
var
  IndexOfUser, IndexOfPassword, IndexOfRole: Integer;
  Username, Password, RoleName: String;
  LoginParams: TStrings;
begin
  if Assigned(FOnLogin) then begin
    result := True;
    LoginParams := TStringList.Create;
    try
      LoginParams.Assign(Params);
      FOnLogin(Self, LoginParams);
      Params.Assign (LoginParams);
    finally
      LoginParams.Free;
    end;
  end
  else
  begin
    IndexOfUser := IndexOfSPBConst(SPBConstantNames[isc_spb_user_name]);
    if IndexOfUser <> -1 then
      Username := Copy(Params[IndexOfUser],
                                         Pos('=', Params[IndexOfUser]) + 1, {mbcs ok}
                                         Length(Params[IndexOfUser]));
    IndexOfPassword := IndexOfSPBConst(SPBConstantNames[isc_spb_password]);
    if IndexOfPassword <> -1 then
      Password := Copy(Params[IndexOfPassword],
                                         Pos('=', Params[IndexOfPassword]) + 1, {mbcs ok}
                                         Length(Params[IndexOfPassword]));

   IndexOfRole:= IndexOfSPBConst(SPBConstantNames[isc_spb_sql_role_name]);
   if IndexOfRole<>-1 then
    RoleName := Copy(Params[IndexOfRole],
                                       Pos('=', Params[IndexOfRole]) + 1,
                                       Length(Params[IndexOfRole]));
//    if Assigned(LoginDialogExProc) then
//      result := LoginDialogExProc(serverName, Username, Password, false)
//    else
//      Result := false;
    if not Assigned(pFIBLoginDialog) then
     Result := False
    else
     Result := pFIBLoginDialog(ServerName, Username, Password,RoleName);

    if result then
    begin
      IndexOfPassword := IndexOfSPBConst(SPBConstantNames[isc_spb_password]);
      if IndexOfUser = -1 then
        Params.Add(SPBConstantNames[isc_spb_user_name] + '=' + Username)
      else
        Params[IndexOfUser] := SPBConstantNames[isc_spb_user_name] +
                                 '=' + Username;
      if IndexOfPassword = -1 then
        Params.Add(SPBConstantNames[isc_spb_password] + '=' + Password)
      else
        Params[IndexOfPassword] := SPBConstantNames[isc_spb_password] +
                                     '=' + Password;
      if IndexOfRole=-1 then
        Params.Add(SPBConstantNames[isc_spb_sql_role_name] + '=' + RoleName)
      else
        Params[IndexOfRole] := SPBConstantNames[isc_spb_sql_role_name] +
                                     '=' + RoleName;
    end;
  end;
end;

procedure TpFIBCustomService.CheckActive;
begin
  if FStreamedActive and (not Active) then
    Loaded;
  if FHandle = nil then
    FIBError(feServiceActive, [nil]);
end;

procedure TpFIBCustomService.CheckInactive;
begin
  if FHandle <> nil then
    FIBError(feServiceInActive, [nil]);
end;

constructor TpFIBCustomService.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLibraryName := IBASE_DLL;
  // FGDSLibrary := GetGDSLibrary;
  FIBLoaded := False;
  // FGDSLibrary.CheckIBLoaded;
  FIBLoaded := True;
  FProtocol := local;
  FserverName := '';
  FParams := TStringList.Create;
  FParamsChanged := True;
  TStringList(FParams).OnChange := ParamsChange;
  TStringList(FParams).OnChanging := ParamsChanging;
  FSPB := nil;
  FQuerySPB := nil;
  FBufferSize := DefaultBufferSize;
  FHandle := nil;
  FLoginPrompt := True;
  // FTraceFlags := [];
  FOutputbuffer := nil;
  // FGDSLibrary := GetGDSLibrary;
end;

destructor TpFIBCustomService.Destroy;
begin
  if FIBLoaded and Assigned(FClientLibrary) then
  begin
    if FHandle <> nil then
      Detach;
    FreeMem(FSPB);
    FSPB := nil;
  end;
  FreeMem(FOutputBuffer);
  FParams.Free;
  FClientLibrary:=nil;
  // FGDSLibrary := nil;
  inherited Destroy;
end;

procedure TpFIBCustomService.Detach;
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

procedure TpFIBCustomService.LoadLibrary;
begin
  if not Assigned(FClientLibrary) then
    FClientLibrary := IB_Intf.GetClientLibrary(FLibraryName);
end;

function TpFIBCustomService.GetActive: Boolean;
begin
  result := FHandle <> nil;
end;

function TpFIBCustomService.GetServiceParamBySPB(const Idx: Integer): String;
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
      EqualsIdx := Pos('=', result); {mbcs ok}
      if EqualsIdx = 0 then
        result := ''
      else
        result := Copy(result, EqualsIdx + 1, Length(result));
    end;
  end
  else
    result := '';
end;

procedure TpFIBCustomService.InternalServiceQuery;
begin
  FQuerySPBLength := Length(FQueryParams);
  if FQuerySPBLength = 0 then
    FIBError(feQueryParamsError, [nil]);
  FIBAlloc(FQuerySPB, 0, FQuerySPBLength);
  Move(FQueryParams[1], FQuerySPB[0], FQuerySPBLength);
  if (FOutputBuffer = nil) then
    FIBAlloc(FOutputBuffer, 0, FBufferSize);
  try
    LoadLibrary;
    if call(FClientLibrary.isc_service_query(StatusVector, @FHandle, nil, 0, nil,
                           FQuerySPBLength, FQuerySPB,
                           FBufferSize, FOutputBuffer), False) > 0 then
    begin
      FHandle := nil;
      IBError(FClientLibrary, Self);
    end;
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

procedure TpFIBCustomService.SetActive(const Value: Boolean);
begin
  if csReading in ComponentState then
    FStreamedActive := Value
  else
    if Value <> Active then   
      if Value then
        Attach
      else
        Detach;
end;

procedure TpFIBCustomService.SetBufferSize(const Value: Integer);
begin
  if (Value <> FBufferSize) then
  begin
    FBufferSize := Value;
    if FOutputBuffer <> nil then
      FIBAlloc(FOutputBuffer, 0, FBufferSize);
  end;
end;

procedure TpFIBCustomService.SetParams(const Value: TStrings);
begin
  FParams.Assign(Value);
end;

procedure TpFIBCustomService.SetServerName(const Value: AnsiString);
begin
  if FServerName <> Value then
  begin
    CheckInactive;
    FServerName := Value;
    if (FProtocol = Local) and (FServerName <> '') then
      FProtocol := TCP
    else
      if (FProtocol <> Local) and (FServerName = '') then
        FProtocol := Local;
  end;
end;

procedure TpFIBCustomService.SetProtocol(const Value: TProtocol);
begin
  if FProtocol <> Value then
  begin
    CheckInactive;
    FProtocol := Value;
    if (Value = Local) then
      FServerName := '';
  end;
end;

procedure TpFIBCustomService.SetServiceParamBySPB(const Idx: Integer;
  const Value: String);
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

function TpFIBCustomService.IndexOfSPBConst(st: String): Integer;
var
  i, pos_of_str: Integer;
begin
  result := -1;
  for i := 0 to Params.Count - 1 do
  begin
    pos_of_str := Pos(st, Params[i]); {mbcs ok}
    if (pos_of_str = 1) or (pos_of_str = Length(SPBPrefix) + 1) then
    begin
      result := i;
      break;
    end;
  end;
end;

procedure TpFIBCustomService.ParamsChange(Sender: TObject);
begin
  FParamsChanged := True;
end;

procedure TpFIBCustomService.ParamsChanging(Sender: TObject);
begin
  CheckInactive;
end;

procedure TpFIBCustomService.CheckServerName;
begin
  if (FServerName = '') and (FProtocol <> Local) then
    FIBError(feServerNameMissing, [nil]);
end;

function TpFIBCustomService.Call(ErrCode: ISC_STATUS;
  RaiseError: Boolean): ISC_STATUS;
begin
  result := ErrCode;
  if RaiseError and (ErrCode > 0) then
    IBError(FClientLibrary, Self);
end;

function TpFIBCustomService.ParseString(var RunLen: Integer): Ansistring;
var
  Len: UShort;
  tmp: AnsiChar;
begin
  LoadLibrary;
  Len := FClientLibrary.isc_vax_integer(OutputBuffer + RunLen, 2);
  RunLen := RunLen + 2;
  if (Len <> 0) then
  begin
    tmp := OutputBuffer[RunLen + Len];
    OutputBuffer[RunLen + Len] := #0;
    result := AnsiString(PAnsiChar(@OutputBuffer[RunLen]));
    OutputBuffer[RunLen + Len] := tmp;
    RunLen := RunLen + Len;
  end
  else
    result := '';
end;

function TpFIBCustomService.ParseInteger(var RunLen: Integer): Integer;
begin
  LoadLibrary;
  Result := FClientLibrary.isc_vax_integer(OutputBuffer + RunLen, 4);
  RunLen := RunLen + 4;
end;

{
 * GenerateSPB -
 *  Given a string containing a textual representation
 *  of the Service parameters, generate a service
 *  parameter buffer, and return it and its length
 *  in SPB and SPBLength, respectively.
}
procedure TpFIBCustomService.GenerateSPB(sl: TStrings; var SPB: AnsiString;
  var SPBLength: Short);
var
  i, j : Integer;
  SPBVal, SPBServerVal: UShort;
  param_name, param_value: String;
  pval: Integer;
begin
  { The SPB is initially empty, with the exception that
   the SPB version must be the first byte of the string.
  }
  SPBLength := 2;
  SPB := AnsiChar(isc_spb_version);
  SPB := SPB + AnsiChar(isc_spb_current_version);
  { Iterate through the textual service parameters, constructing
   a SPB on-the-fly}
  for i := 0 to sl.Count - 1 do
  begin
   { Get the parameter's name and value from the list,
     and make sure that the name is all lowercase with
     no leading 'isc_spb_' prefix }
    if (Trim(sl.Names[i]) = '') then
      continue;
    param_name := LowerCase(sl.Names[i]); {mbcs ok}
    param_value := Copy(sl[i], Pos('=', sl[i]) + 1, Length(sl[i])); {mbcs ok}
    if (Pos(SPBPrefix, param_name) = 1) then {mbcs ok}
      Delete(param_name, 1, Length(SPBPrefix));
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
      isc_spb_command_line,isc_spb_user_name, isc_spb_password, isc_spb_sql_role_name:
      begin
        SPB := SPB +
               AnsiChar(SPBServerVal) +
               AnsiChar(Length(param_value)) +
               param_value;
        Inc(SPBLength, 2 + Length(param_value));
      end;
      isc_spb_connect_timeout, isc_spb_dummy_packet_interval :
      begin
        pval := StrToInt(String(param_value));
        SPB := SPB + AnsiChar(SPBServerVal) + #4 + PAnsiChar(@pval)[0] + PAnsiChar(@pval)[1] +
               PAnsiChar(@pval)[2] + PAnsiChar(@pval)[3];
        Inc(SPBLength, 6);
      end;

      else
      begin
        if (SPBVal > 0) and
           (SPBVal <= isc_dpb_last_dpb_constant) then
          FIBError(feSPBConstantNotSupported,
                   [SPBConstantNames[SPBVal]])
        else
          FIBError(feSPBConstantUnknown, [SPBVal]);
      end;
    end;
  end;
end;

procedure TpFIBCustomService.SetLibraryName(const Value: string);
begin
  CheckInactive;
  if FLibraryName <> Value then
  begin
    FLibraryName := Value;
    FClientLibrary := nil;
  end;
end;

function TpFIBCustomService.StoredLibraryName: Boolean;
begin
  Result := FLibraryName <> IBASE_DLL;
end;

{ TpFIBServerProperties }
constructor TpFIBServerProperties.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDatabaseInfo := TDatabaseInfo.Create;
  FLicenseInfo := TLicenseInfo.Create;
  FLicenseMaskInfo := TLicenseMaskInfo.Create;
  FVersionInfo := TVersionInfo.Create;
  FConfigParams := TConfigParams.Create;
end;

destructor TpFIBServerProperties.Destroy;
begin
  FDatabaseInfo.Free;
  FLicenseInfo.Free;
  FLicenseMaskInfo.Free;
  FVersionInfo.Free;
  FConfigParams.Free;
  inherited Destroy;
end;

procedure TpFIBServerProperties.ParseConfigFileData(var RunLen: Integer);
begin
  Inc(RunLen);
  with FConfigParams.ConfigFileData do
  begin
    SetLength (ConfigFileValue, Length(ConfigFileValue)+1);
    SetLength (ConfigFileKey, Length(ConfigFileKey)+1);

    ConfigFileKey[High(ConfigFileKey)] := Integer(OutputBuffer[RunLen-1]);
    ConfigFileValue[High(ConfigFileValue)] := ParseInteger(RunLen);
  end;
end;

procedure TpFIBServerProperties.Fetch;
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

procedure TpFIBServerProperties.FetchConfigParams;
var
  RunLen: Integer;

begin
  ServiceQueryParams := AnsiChar(isc_info_svc_get_config) +
                        AnsiChar(isc_info_svc_get_env) +
                        AnsiChar(isc_info_svc_get_env_lock) +
                        AnsiChar(isc_info_svc_get_env_msg) +
                        AnsiChar(isc_info_svc_user_dbpath);

  InternalServiceQuery;
  RunLen := 0;
  While (not (Integer(OutputBuffer[RunLen]) = isc_info_end)) do
  begin
    case Integer(OutputBuffer[RunLen]) of
      isc_info_svc_get_config:
      begin
        FConfigParams.ConfigFileData.ConfigFileKey := nil;
        FConfigParams.ConfigFileData.ConfigFileValue := nil;
        Inc (RunLen);
        while (not (Integer(OutputBuffer[RunLen]) = isc_info_flag_end)) do
          ParseConfigFileData (RunLen);
        if (Integer(OutputBuffer[RunLen]) = isc_info_flag_end) then
          Inc (RunLen);
      end;

      isc_info_svc_get_env:
      begin
        Inc (RunLen);
        FConfigParams.BaseLocation := ParseString(RunLen);
      end;

      isc_info_svc_get_env_lock:
      begin
        Inc (RunLen);
        FConfigParams.LockFileLocation := ParseString(RunLen);
      end;

      isc_info_svc_get_env_msg:
      begin
        Inc (RunLen);
        FConfigParams.MessageFileLocation := ParseString(RunLen);
      end;

      isc_info_svc_user_dbpath:
      begin
        Inc (RunLen);
        FConfigParams.SecurityDatabaseLocation := ParseString(RunLen);
      end;
      else
        FIBError(feOutputParsingError, [nil]);
    end;
  end;
end;

procedure TpFIBServerProperties.FetchDatabaseInfo;
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
    Inc (i);
  end;
end;

procedure TpFIBServerProperties.FetchLicenseInfo;
var
  i, RunLen: Integer;
  done: Integer;
begin
  ServiceQueryParams := AnsiChar(isc_info_svc_get_license) +
                        AnsiChar(isc_info_svc_get_licensed_users);
  InternalServiceQuery;
  RunLen := 0;
  done := 0;
  i := 0;
  FLicenseInfo.key := nil;
  FLicenseInfo.id := nil;
  FLicenseInfo.desc := nil;

  While done < 2 do begin
    Inc(Done);
    Inc(RunLen);
    case Integer(OutputBuffer[RunLen-1]) of
      isc_info_svc_get_license:
      begin
        while (OutputBuffer[RunLen] <> AnsiChar(isc_info_flag_end)) do
        begin
          if (i >= Length(FLicenseInfo.key)) then
          begin
            SetLength(FLicenseInfo.key, i + 10);
            SetLength(FLicenseInfo.id, i + 10);
            SetLength(FLicenseInfo.desc, i + 10);
          end;
          if (OutputBuffer[RunLen] <> AnsiChar(isc_spb_lic_id)) then
              FIBError(feOutputParsingError, [nil]);
          Inc(RunLen);
          FLicenseInfo.id[i] := ParseString(RunLen);
          if (OutputBuffer[RunLen] <> AnsiChar(isc_spb_lic_key)) then
              FIBError(feOutputParsingError, [nil]);
          Inc(RunLen);
          FLicenseInfo.key[i] := ParseString(RunLen);
          if (OutputBuffer[RunLen] <> AnsiChar(7)) then
              FIBError(feOutputParsingError, [nil]);
          Inc(RunLen);
          FLicenseInfo.desc[i] := ParseString(RunLen);
          Inc(i);
        end;
        Inc(RunLen);
        if (Length(FLicenseInfo.key) > i) then
        begin
          SetLength(FLicenseInfo.key, i);
          SetLength(FLicenseInfo.id, i);
          SetLength(FLicenseInfo.desc, i);
        end;
      end;
      isc_info_svc_get_licensed_users:
        FLicenseInfo.LicensedUsers := ParseInteger(RunLen);
      else
        FIBError(feOutputParsingError, [nil]);
    end;
  end;
end;

procedure TpFIBServerProperties.FetchLicenseMaskInfo();
var
  done,RunLen:integer;
begin
  ServiceQueryParams := AnsiChar(isc_info_svc_get_license_mask) +
                        AnsiChar(isc_info_svc_capabilities);
  InternalServiceQuery;
  RunLen := 0;
  done := 0;
  While done <= 1 do
  begin
    Inc(done);
    Inc(RunLen);
    case Integer(OutputBuffer[RunLen-1]) of
      isc_info_svc_get_license_mask:
        FLicenseMaskInfo.LicenseMask := ParseInteger(RunLen);
      isc_info_svc_capabilities:
        FLicenseMaskInfo.CapabilityMask := ParseInteger(RunLen);
      else
        FIBError(feOutputParsingError, [nil]);
    end;
  end;
end;


procedure TpFIBServerProperties.FetchVersionInfo;
var
  RunLen: Integer;
  done: Integer;
begin
  ServiceQueryParams := AnsiChar(isc_info_svc_version) +
                        AnsiChar(isc_info_svc_server_version) +
                        AnsiChar(isc_info_svc_implementation);
  InternalServiceQuery;
  RunLen := 0;
  done := 0;

  While done <= 2 do
  begin
    Inc(done);
    Inc(RunLen);
    case Integer(OutputBuffer[RunLen-1]) of
      isc_info_svc_version:
        FVersionInfo.ServiceVersion := ParseInteger(RunLen);
      isc_info_svc_server_version:
        FVersionInfo.ServerVersion := ParseString(RunLen);
      isc_info_svc_implementation:
        FVersionInfo.ServerImplementation := ParseString(RunLen);
      else
        FIBError(feOutputParsingError, [nil]);
    end;
  end;
end;

{ TpFIBControlService }
procedure TpFIBControlService.SetServiceStartOptions;
begin

end;

function TpFIBControlService.GetIsServiceRunning: Boolean;
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

procedure TpFIBControlService.ServiceStartAddParam (Value: Ansistring; param: Integer);
var
  Len: UShort;
begin
  Len := Length(Value);
  if Len > 0 then
  begin
    FStartParams  := FStartParams +
                     AnsiChar(Param) +
                     PAnsiChar(@Len)[0] +
                     PAnsiChar(@Len)[1] +
                     Value;
  end;
end;

procedure TpFIBControlService.ServiceStartAddParam (Value: Integer; param: Integer);
begin
  FStartParams  := FStartParams +
                   AnsiChar(Param) +
                   PAnsiChar(@Value)[0] +
                   PAnsiChar(@Value)[1] +
                   PAnsiChar(@Value)[2] +
                   PAnsiChar(@Value)[3];
end;

constructor TpFIBControlService.Create(AOwner: TComponent);
begin
  inherited create(AOwner);
  FStartParams := '';
  FStartSPB := nil;
  FStartSPBLength := 0;
end;

procedure TpFIBControlService.InternalServiceStart;
begin
  FStartSPBLength := Length(FStartParams);
  if FStartSPBLength = 0 then
    FIBError(feStartParamsError, [nil]);
  FIBAlloc(FStartSPB, 0, FStartSPBLength);
  Move(FStartParams[1], FStartSPB[0], FstartSPBLength);
  try
    LoadLibrary;
    if call(FClientLibrary.isc_service_start(StatusVector, @FHandle, nil,
                           FStartSPBLength, FStartSPB), False) > 0 then
    begin
      FHandle := nil;
      IBError(FClientLibrary, Self);
    end;
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

procedure TpFIBControlService.ServiceStart;
begin
  CheckActive;
  SetServiceStartOptions;
  InternalServiceStart;
end;

{ TpFIBConfigService }

procedure TpFIBConfigService.ServiceStart;
begin
  FIBError(feUseSpecificProcedures, [nil]);
end;

procedure TpFIBConfigService.ActivateShadow;
begin
  ServiceStartParams  := AnsiChar(isc_action_svc_properties);
  ServiceStartAddParam (FDatabaseName, SPBConstantValues[isc_spb_dbname]);
  ServiceStartAddParam (isc_spb_prp_activate, SPBConstantValues[isc_spb_options]);
  InternalServiceStart;
end;

procedure TpFIBConfigService.BringDatabaseOnline;
begin
  ServiceStartParams  := AnsiChar(isc_action_svc_properties);
  ServiceStartAddParam (FDatabaseName, SPBConstantValues[isc_spb_dbname]);
  ServiceStartAddParam (isc_spb_prp_db_online, SPBConstantValues[isc_spb_options]);
  InternalServiceStart;
end;

procedure TpFIBConfigService.SetAsyncMode(Value: Boolean);
begin
  ServiceStartParams  := AnsiChar(isc_action_svc_properties);
  ServiceStartAddParam (FDatabaseName, SPBConstantValues[isc_spb_dbname]);
  ServiceStartParams := ServiceStartParams +
                        AnsiChar(isc_spb_prp_write_mode);
  if Value then
    ServiceStartParams  := ServiceStartParams +
                           AnsiChar(isc_spb_prp_wm_async)
  else
    ServiceStartParams  := ServiceStartParams +
                           AnsiChar(isc_spb_prp_wm_sync);
  InternalServiceStart;
end;

procedure TpFIBConfigService.SetDatabaseName(const Value: string);
begin
  FDatabaseName := Value;
end;

procedure TpFIBConfigService.SetPageBuffers(Value: Integer);
begin
  ServiceStartParams  := AnsiChar(isc_action_svc_properties);
  ServiceStartAddParam (FDatabaseName, SPBConstantValues[isc_spb_dbname]);
  ServiceStartAddParam (Value, isc_spb_prp_page_buffers);
  InternalServiceStart;
end;

procedure TpFIBConfigService.SetReadOnly(Value: Boolean);
begin
  ServiceStartParams  := AnsiChar(isc_action_svc_properties);
  ServiceStartAddParam (FDatabaseName, SPBConstantValues[isc_spb_dbname]);
  ServiceStartParams := ServiceStartParams +
                         AnsiChar(isc_spb_prp_access_mode);
  if Value then
    ServiceStartParams  := ServiceStartParams +
                           AnsiChar(isc_spb_prp_am_readonly)
  else
    ServiceStartParams  := ServiceStartParams +
                           AnsiChar(isc_spb_prp_am_readwrite);
  InternalServiceStart;
end;

procedure TpFIBConfigService.SetReserveSpace(Value: Boolean);
begin
  ServiceStartParams  := AnsiChar(isc_action_svc_properties);
  ServiceStartAddParam (FDatabaseName, SPBConstantValues[isc_spb_dbname]);
  ServiceStartParams := ServiceStartParams +
                        AnsiChar(isc_spb_prp_reserve_space);
  if Value then
    ServiceStartParams  := ServiceStartParams +
                           AnsiChar(isc_spb_prp_res)
  else
    ServiceStartParams  := ServiceStartParams +
                           AnsiChar(isc_spb_prp_res_use_full);
  InternalServiceStart;
end;

procedure TpFIBConfigService.SetSweepInterval(Value: Integer);
begin
  ServiceStartParams  := AnsiChar(isc_action_svc_properties);
  ServiceStartAddParam (FDatabaseName, SPBConstantValues[isc_spb_dbname]);
  ServiceStartAddParam (Value, isc_spb_prp_sweep_interval);
  InternalServiceStart;
end;

procedure TpFIBConfigService.SetDBSqlDialect(Value: Integer);
begin
  ServiceStartParams  := AnsiChar(isc_action_svc_properties);
  ServiceStartAddParam (FDatabaseName, SPBConstantValues[isc_spb_dbname]);
  ServiceStartAddParam (Value, isc_spb_prp_set_sql_dialect);
  InternalServiceStart;
end;

procedure TpFIBConfigService.ShutdownDatabase(Options: TShutdownMode;
  Wait: Integer);
begin
  ServiceStartParams  := AnsiChar(isc_action_svc_properties);
  ServiceStartAddParam (FDatabaseName, SPBConstantValues[isc_spb_dbname]);
  if (Options = Forced) then
    ServiceStartAddParam (Wait, isc_spb_prp_shutdown_db)
  else if (Options = DenyTransaction) then
    ServiceStartAddParam (Wait, isc_spb_prp_deny_new_transactions)
  else
    ServiceStartAddParam (Wait, isc_spb_prp_deny_new_attachments);
  InternalServiceStart;
end;

{ TpFIBLicensingService }
procedure TpFIBLicensingService.SetAction(Value: TLicensingAction);
begin
  FAction := Value;
  if (Value = LicenseRemove) then
   FID := '';
end;

procedure TpFIBLicensingService.AddLicense;
begin
  Action := LicenseAdd;
  Servicestart;
end;

procedure TpFIBLicensingService.RemoveLicense;
begin
  Action := LicenseRemove;
  Servicestart;
end;

procedure TpFIBLicensingService.SetServiceStartOptions;
begin
  if (FAction = LicenseAdd) then begin
    ServiceStartParams  := AnsiChar(isc_action_svc_add_license);
    ServiceStartAddParam (FKey, isc_spb_lic_key);
    ServiceStartAddParam (FID, isc_spb_lic_id);
  end
  else begin
    ServiceStartParams  := AnsiChar(isc_action_svc_remove_license);
    ServiceStartAddParam (FKey, isc_spb_lic_key);
  end;
end;

{ TpFIBStatisticalService }

procedure TpFIBStatisticalService.SetDatabaseName(const Value: string);
begin
  FDatabaseName := Value;
end;

procedure TpFIBStatisticalService.SetServiceStartOptions;
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
  ServiceStartParams  := AnsiChar(isc_action_svc_db_stats);
  ServiceStartAddParam(FDatabaseName, SPBConstantValues[isc_spb_dbname]);
  ServiceStartAddParam(param, SPBConstantValues[isc_spb_options]);
  if (StatTables in Options) then
    ServiceStartAddParam(FTableNames, SPBConstantValues[isc_spb_command_line]);
end;

{ TpFIBBackupService }
procedure TpFIBBackupService.SetServiceStartOptions;
var
  param, i: Integer;
  value: String;
begin
  if FDatabaseName = '' then
    FIBError(feStartParamsError, [nil]);
  param := 0;
  if (IgnoreChecksums in Options) then
    param := param or isc_spb_bkp_ignore_checksums;
  if (IgnoreLimbo in Options) then
    param := param or isc_spb_bkp_ignore_limbo;
  if (MetadataOnly in Options) then
    param := param or isc_spb_bkp_metadata_only;
  if (NoGarbageCollection in Options) then
    param := param or isc_spb_bkp_no_garbage_collect;
  if (OldMetadataDesc in Options) then
    param := param or isc_spb_bkp_old_descriptions;
  if (NonTransportable in Options) then
    param := param or isc_spb_bkp_non_transportable;
  if (ConvertExtTables in Options) then
    param := param or isc_spb_bkp_convert;
  Action := isc_action_svc_backup;
  ServiceStartParams  := AnsiChar(isc_action_svc_backup);
  ServiceStartAddParam(FDatabaseName, SPBConstantValues[isc_spb_dbname]);
  ServiceStartAddParam(param, SPBConstantValues[isc_spb_options]);
  if Verbose then
    ServiceStartParams := ServiceStartParams + AnsiChar(SPBConstantValues[isc_spb_verbose]);
  if FBlockingFactor > 0 then
    ServiceStartAddParam(FBlockingFactor, isc_spb_bkp_factor);
  for i := 0 to FBackupFile.Count - 1 do
  begin
    if (Trim(FBackupFile[i]) = '') then
      continue;
    if (Pos('=', FBackupFile[i]) <> 0) then
    begin {mbcs ok}
      ServiceStartAddParam(FBackupFile.Names[i], isc_spb_bkp_file);
      value := Copy(FBackupFile[i], Pos('=', FBackupFile[i]) + 1, Length(FBackupFile.Names[i])); {mbcs ok}
      param := StrToInt(value);
      ServiceStartAddParam(param, isc_spb_bkp_length);
    end
    else
      ServiceStartAddParam(FBackupFile[i], isc_spb_bkp_file);
  end;
end;

constructor TpFIBBackupService.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBackupFile := TStringList.Create;
end;

destructor TpFIBBackupService.Destroy;
begin
  FBackupFile.Free;
  inherited Destroy;
end;

procedure TpFIBBackupService.SetBackupFile(const Value: TStrings);
begin
  FBackupFile.Assign(Value);
end;

{ TpFIBRestoreService }

procedure TpFIBRestoreService.SetServiceStartOptions;
var
  param, i: Integer;
  value: String;
begin
  param := 0;
  if (DeactivateIndexes in Options) then
    param := param or isc_spb_res_deactivate_idx;
  if (NoShadow in Options) then
    param := param or isc_spb_res_no_shadow;
  if (NoValidityCheck in Options) then
    param := param or isc_spb_res_no_validity;
  if (OneRelationAtATime in Options) then
    param := param or isc_spb_res_one_at_a_time;
  if (Replace in Options) then
    param := param or isc_spb_res_replace;
  if (CreateNewDB in Options) then
    param := param or isc_spb_res_create;
  if (UseAllSpace in Options) then
    param := param or isc_spb_res_use_all_space;
  if (ValidationCheck in Options) then
    param := param or isc_spb_res_validate;
  if (OnlyMetadata in Options) then
    param := param or isc_spb_bkp_metadata_only;

  Action := isc_action_svc_restore;
  ServiceStartParams  := AnsiChar(isc_action_svc_restore);
  ServiceStartAddParam(param, SPBConstantValues[isc_spb_options]);
  if Verbose then ServiceStartParams := ServiceStartParams + AnsiChar(SPBConstantValues[isc_spb_verbose]);

  if (Length(FFixCharset)>0)  then
  begin
   if (FixFssMetadata in Options) then
    ServiceStartAddParam(FFixCharset, isc_spb_res_fix_fss_metadata);
   if (FixFssData in Options)   then
    ServiceStartAddParam(FFixCharset, isc_spb_res_fix_fss_data);
  end;

  if FPageSize > 0 then
    ServiceStartAddParam(FPageSize, isc_spb_res_page_size);
  if FPageBuffers > 0 then
    ServiceStartAddParam(FPageBuffers, isc_spb_res_buffers);
  for i := 0 to FBackupFile.Count - 1 do
  begin
    if (Trim(FBackupFile[i]) = '') then continue;
    if (Pos('=', FBackupFile[i]) <> 0) then  {mbcs ok}
    begin 
      ServiceStartAddParam(FBackupFile.Names[i], isc_spb_bkp_file);
      value := Copy(FBackupFile[i], Pos('=', FBackupFile[i]) + 1, Length(FBackupFile.Names[i])); {mbcs ok}
      param := StrToInt(value);
      ServiceStartAddParam(param, isc_spb_bkp_length);
    end
    else
      ServiceStartAddParam(FBackupFile[i], isc_spb_bkp_file);
  end;
  for i := 0 to FDatabaseName.Count - 1 do
  begin
    if (Trim(FDatabaseName[i]) = '') then continue;
    if (Pos('=', FDatabaseName[i]) <> 0) then {mbcs ok}
    begin 
      ServiceStartAddParam(FDatabaseName.Names[i], SPBConstantValues[isc_spb_dbname]);
      value := Copy(FDatabaseName[i], Pos('=', FDatabaseName[i]) + 1, Length(FDatabaseName[i])); {mbcs ok}
      param := StrToInt(value);
      ServiceStartAddParam(param, isc_spb_res_length);
    end
    else
      ServiceStartAddParam(FDatabaseName[i], SPBConstantValues[isc_spb_dbname]);
  end;
end;

constructor TpFIBRestoreService.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDatabaseName := TStringList.Create;
  FBackupFile := TStringList.Create;
  Include (FOptions, CreateNewDB);
  FPageSize := 4096;
end;

destructor TpFIBRestoreService.Destroy;
begin
  FDatabaseName.Free;
  FBackupFile.Free;
  inherited Destroy;
end;

procedure TpFIBRestoreService.SetBackupFile(const Value: TStrings);
begin
  FBackupFile.Assign(Value);
end;

procedure TpFIBRestoreService.SetDatabaseName(const Value: TStrings);
begin
  FDatabaseName.Assign(Value);
end;

{TpFIBNBackupService}

procedure TpFIBNBackupService.SetServiceStartOptions;
begin
  if (FDatabaseName = '') or (FBackupFile='')  then
    FIBError(feStartParamsError, [nil]);
  Action := isc_action_svc_nbak;
  ServiceStartParams   := Char(isc_action_svc_nbak);
  ServiceStartAddParam(FDatabaseName, SPBConstantValues[isc_spb_dbname]);
//  ServiceStartAddParam(0, SPBConstantValues[isc_spb_options]);

  ServiceStartAddParam(FBackupFile, isc_spb_nbk_file);
  ServiceStartAddParam(FLevel, isc_spb_nbk_level);
end;


constructor TpFIBNBackupService.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLevel := 0;
end;

procedure TpFIBNBackupService.BackUp(const DBName, BackupName:string; aLevel:integer);
begin
  try
    DatabaseName := DBName;
    BackupFile:=BackupName;
    Level:=aLevel;
    Attach;
    ServiceStart;
  finally
    if Active then Detach;
  end;
end;


{TpFIBNRestoreService}

constructor TpFIBNRestoreService.Create(AOwner: TComponent);
begin
  inherited;
  FBackupFiles:=TStringList.Create;
end;

destructor TpFIBNRestoreService.Destroy;
begin
  FBackupFiles.Free;
  inherited;
end;

procedure TpFIBNRestoreService.SetBackupFiles(const Value: TStrings);
begin
  FBackupFiles.Assign(Value);
end;

procedure TpFIBNRestoreService.SetServiceStartOptions;
var
 i:integer;
begin
  if (FDatabaseName = '') or (FBackupFiles.Count=0)  then
    FIBError(feStartParamsError, [nil]);
  Action := isc_action_svc_nrest;
  ServiceStartParams   := Char(isc_action_svc_nrest);
  ServiceStartAddParam(FDatabaseName, SPBConstantValues[isc_spb_dbname]);
  for i := 0 to FBackupFiles.Count - 1 do
  begin
    if (Trim(FBackupFiles[i]) = '') then
      Continue;
    ServiceStartAddParam(FBackupFiles[i], isc_spb_nbk_file);
  end;
end;

procedure  TpFIBNRestoreService.Restore(const aBackUpFiles: array of string; const DBName:string);
var i:integer;
begin
  DatabaseName:=DBName;
  BackupFiles.Clear;
  for i:=0 to Length(aBackUpFiles) do
   BackupFiles.Add(aBackUpFiles[i]);

  try
    Attach;
    ServiceStart;
  finally
     if Active then Detach;
  end;
end;

{ TpFIBValidationService }
constructor TpFIBValidationService.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

destructor TpFIBValidationService.Destroy;
var
  i : Integer;
begin
  for i := 0 to High(FLimboTransactionInfo) do
    FLimboTransactionInfo[i].Free;
  FLimboTransactionInfo := nil;
  inherited Destroy;
end;

procedure TpFIBValidationService.FetchLimboTransactionInfo;
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
  for i := 0 to High(FLimboTransactionInfo) do
    FLimboTransactionInfo[i].Free;
  FLimboTransactionInfo := nil;
  i := 0;
  while (OutputBuffer[RunLen] <> AnsiChar(isc_info_end)) do
  begin
    if (i >= Length(FLimboTransactionInfo)) then
      SetLength(FLimboTransactionInfo, i + 10);
    if FLimboTransactionInfo[i] = nil then
      FLimboTransactionInfo[i] := TLimboTransactionInfo.Create;
    with FLimboTransactionInfo[i] do
    begin
      if (OutputBuffer[RunLen] = AnsiChar(isc_spb_single_tra_id)) then
      begin
        Inc(RunLen);
        MultiDatabase := False;
        ID := ParseInteger(RunLen);

{        HostSite := ParseString(RunLen);
        if (OutputBuffer[RunLen] <> AnsiChar(isc_spb_tra_state)) then
          FIBError(feOutputParsingError, [nil]);}
        
      end
      else
      begin
        Inc(RunLen);
        MultiDatabase := True;
        ID := ParseInteger(RunLen);
        HostSite := ParseString(RunLen);
        if (OutputBuffer[RunLen] <> AnsiChar(isc_spb_tra_state)) then
          FIBError(feOutputParsingError, [nil]);
        Inc(RunLen);
        Value := OutputBuffer[RunLen];
        Inc(RunLen);
        if (Value = AnsiChar(isc_spb_tra_state_limbo)) then
          State := LimboState
        else
          if (Value = AnsiChar(isc_spb_tra_state_commit)) then
            State := CommitState
          else
            if (Value = AnsiChar(isc_spb_tra_state_rollback)) then
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
          Action:= CommitAction;
        end
        else
          if (Value = AnsiChar(isc_spb_tra_advise_rollback)) then
          begin
            Advise := RollbackAdvise;
            Action := RollbackAction;
          end
          else
          begin
            { if no advice commit as default }
            Advise := UnknownAdvise;
            Action:= CommitAction;
          end;
      end;
      Inc (i);
    end;
  end;
  if (i > 0) then
    SetLength(FLimboTransactionInfo, i+1);
end;

procedure TpFIBValidationService.FixLimboTransactionErrors;
var
  i: Integer;
begin
  ServiceStartParams  := AnsiChar(isc_action_svc_repair);
  ServiceStartAddParam (FDatabaseName, SPBConstantValues[isc_spb_dbname]);
  if (FGlobalAction = NoGlobalAction) then
  begin
    i := 0;
    while (i<Length(FLimboTransactionInfo)) and(FLimboTransactionInfo[i].ID <> 0) do
    begin
      if (FLimboTransactionInfo[i].Action = CommitAction) then
        ServiceStartAddParam (FLimboTransactionInfo[i].ID, isc_spb_rpr_commit_trans)
      else
        ServiceStartAddParam (FLimboTransactionInfo[i].ID, isc_spb_rpr_rollback_trans);                              
      Inc(i);
    end;
  end
  else
  begin
    i := 0;
    if (FGlobalAction = CommitGlobal) then
      while (i<Length(FLimboTransactionInfo)) and (FLimboTransactionInfo[i].ID <> 0) do
      begin
        ServiceStartAddParam (FLimboTransactionInfo[i].ID, isc_spb_rpr_commit_trans);
        Inc(i);
      end
    else
      while (i<Length(FLimboTransactionInfo)) and(FLimboTransactionInfo[i].ID <> 0) do
      begin
        ServiceStartAddParam (FLimboTransactionInfo[i].ID, isc_spb_rpr_rollback_trans);
        Inc(i);
      end;
  end;
  InternalServiceStart;
end;

function TpFIBValidationService.GetLimboTransactionInfo(index: integer): TLimboTransactionInfo;
begin
  if index <= High(FLimboTransactionInfo) then
    result := FLimboTransactionInfo[index]
  else
    result := nil;
end;

function TpFIBValidationService.GetLimboTransactionInfoCount: integer;
begin
  Result := High(FLimboTransactionInfo);
end;

procedure TpFIBValidationService.SetDatabaseName(const Value: string);
begin
  FDatabaseName := Value;
end;

procedure TpFIBValidationService.SetServiceStartOptions;
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
  ServiceStartParams  := AnsiChar(isc_action_svc_repair);
  ServiceStartAddParam (FDatabaseName, SPBConstantValues[isc_spb_dbname]);
  if param > 0 then
    ServiceStartAddParam (param, SPBConstantValues[isc_spb_options]);
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
     if not (MendDB in Options) then
       param := param or isc_spb_rpr_validate_db;
  end;
  if param > 0 then
    ServiceStartAddParam (param, SPBConstantValues[isc_spb_options]);
end;

{ TpFIBSecurityService }
constructor TpFIBSecurityService.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FModifyParams := [];
end;

destructor TpFIBSecurityService.Destroy;
var
  i : Integer;
begin
  for i := 0 to High(FUserInfo) do
    FUserInfo[i].Free;
  FUserInfo := nil;
  inherited Destroy;
end;

procedure TpFIBSecurityService.FetchUserInfo;
var
  i, RunLen: Integer;
begin
  ServiceQueryParams := AnsiChar(isc_info_svc_get_users);
  InternalServiceQuery;
  RunLen := 0;
  if (OutputBuffer[RunLen] <> AnsiChar(isc_info_svc_get_users)) then
    FIBError(feOutputParsingError, [nil]);
  Inc(RunLen);
  for i := 0 to High(FUserInfo) do
    FUserInfo[i].Free;
  FUserInfo := nil;
  i := 0;
  { Don't have any use for the combined length
   so increment past by 2 }
  Inc(RunLen, 2);
  while (OutputBuffer[RunLen] <> AnsiChar(isc_info_end)) do
  begin
    if (i >= Length(FUSerInfo)) then
      SetLength(FUserInfo, i + 10);
    if (OutputBuffer[RunLen] <> AnsiChar(isc_spb_sec_username)) then
      FIBError(feOutputParsingError, [nil]);
    Inc(RunLen);
    if FUserInfo[i] = nil then
      FUserInfo[i] := TUserInfo.Create;
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
    FUserInfo[i].UserId := ParseInteger(RunLen);

    if (OutputBuffer[RunLen] <> AnsiChar(isc_spb_sec_groupid)) then
      FIBError(feOutputParsingError, [nil]);
    Inc(RunLen);
    FUserInfo[i].GroupID := ParseInteger(RunLen);

    Inc (i);
  end;
  if (i > 0) then
    SetLength(FUserInfo, i+1);
end;

function TpFIBSecurityService.GetUserInfo(Index: Integer): TUserInfo;
begin
  if Index <= High(FUSerInfo) then
    result := FUserInfo[Index]
  else
    result := nil;
end;

function TpFIBSecurityService.GetUserInfoCount: Integer;
begin
  Result := High(FUSerInfo);
end;

procedure TpFIBSecurityService.AddUser;
begin
  SecurityAction := ActionAddUser;
  ServiceStart;
end;

procedure TpFIBSecurityService.DeleteUser;
begin
  SecurityAction := ActionDeleteUser;
  ServiceStart;
end;

procedure TpFIBSecurityService.DisplayUsers;
begin
  SecurityAction := ActionDisplayUser;
  ServiceStartParams  := AnsiChar(isc_action_svc_display_user);
  ServiceStartAddParam (UTF8Encode(FSQLRole), SPBConstantValues[isc_spb_sql_role_name]);
  InternalServiceStart;
  FetchUserInfo;
end;

procedure TpFIBSecurityService.DisplayUser(UserName: String);
begin
  SecurityAction := ActionDisplayUser;
  ServiceStartParams  := AnsiChar(isc_action_svc_display_user);
  ServiceStartAddParam (Utf8Encode(UserName), isc_spb_sec_username);
  InternalServiceStart;
  FetchUserInfo;
end;

procedure TpFIBSecurityService.ModifyUser;
begin
  SecurityAction := ActionModifyUser;
  ServiceStart;
end;

procedure TpFIBSecurityService.SetSecurityAction (Value: TSecurityAction);
begin
  FSecurityAction := Value;
  if Value = ActionDeleteUser then
    ClearParams;
end;

procedure TpFIBSecurityService.ClearParams;
begin
  FModifyParams := [];
  FFirstName := '';
  FMiddleName := '';
  FLastName := '';
  FGroupID := 0;
  FUserID := 0;
  FPassword := '';
end;

procedure TpFIBSecurityService.SetFirstName (Value: String);
begin
  FFirstName := Value;
  Include (FModifyParams, ModifyFirstName);
end;

procedure TpFIBSecurityService.SetMiddleName (Value: String);
begin
  FMiddleName := Value;
  Include (FModifyParams, ModifyMiddleName);
end;

procedure TpFIBSecurityService.SetLastName (Value: String);
begin
  FLastName := Value;
  Include (FModifyParams, ModifyLastName);
end;

procedure TpFIBSecurityService.SetPassword (Value: String);
begin
  FPassword := Value;
  Include (FModifyParams, ModifyPassword);
end;

procedure TpFIBSecurityService.SetUserId (Value: Integer);
begin
  FUserId := Value;
  Include (FModifyParams, ModifyUserId);
end;

procedure TpFIBSecurityService.SetGroupId (Value: Integer);
begin
  FGroupId := Value;
  Include (FModifyParams, ModifyGroupId);
end;

procedure TpFIBSecurityService.SetSecAdmin(Value:boolean);
begin
 if  FSecAdmin<>Value then
 begin
  Include (FModifyParams, ModifySecAdmin);
  FSecAdmin:=Value;
 end;
end;

procedure TpFIBSecurityService.Loaded;
begin
  inherited Loaded;
  ClearParams;
end;



procedure TpFIBSecurityService.SetServiceStartOptions;
var
  Len: UShort;

begin
  case FSecurityAction of
    ActionAddUser:
    begin
      Action := isc_action_svc_add_user;
      if ( Pos(' ', FUserName) > 0 ) then
        FIBError(feStartParamsError, [nil]);
      Len := Length(FUserName);
      if (Len = 0) then
        FIBError(feStartParamsError, [nil]);
      ServiceStartParams  := AnsiChar(isc_action_svc_add_user);
      ServiceStartAddParam (UTF8Encode(FUserName), isc_spb_sec_username);
      ServiceStartAddParam (FUserID, isc_spb_sec_userid);
      ServiceStartAddParam (FGroupID, isc_spb_sec_groupid);
      if (ModifySecAdmin in FModifyParams) then
       if FSecAdmin then
        ServiceStartAddParam (1, isc_spb_sec_admin)
       else
        ServiceStartAddParam (0, isc_spb_sec_admin);


      ServiceStartAddParam (UTF8Encode(FPassword), isc_spb_sec_password);
      ServiceStartAddParam (UTF8Encode(FFirstName), isc_spb_sec_firstname);
      ServiceStartAddParam (UTF8Encode(FMiddleName), isc_spb_sec_middlename);
      ServiceStartAddParam (UTF8Encode(FLastName), isc_spb_sec_lastname);
      ServiceStartAddParam (UTF8Encode(FSQLRole), SPBConstantValues[isc_spb_sql_role_name]);
    end;
    ActionDeleteUser:
    begin
      Action := isc_action_svc_delete_user;
      Len := Length(FUserName);
      if (Len = 0) then
        FIBError(feStartParamsError, [nil]);
      ServiceStartParams  := AnsiChar(isc_action_svc_delete_user);
      ServiceStartAddParam (UTF8Encode(FUserName), isc_spb_sec_username);
    end;
    ActionModifyUser:
    begin
      Action := isc_action_svc_modify_user;
      Len := Length(FUserName);
      if (Len = 0) then
        FIBError(feStartParamsError, [nil]);
      ServiceStartParams  := AnsiChar(isc_action_svc_modify_user);
      ServiceStartAddParam (UTF8Encode(FUserName), isc_spb_sec_username);
      if (ModifyUserId in FModifyParams) then
        ServiceStartAddParam (FUserID, isc_spb_sec_userid);
      if (ModifyGroupId in FModifyParams) then
        ServiceStartAddParam (FGroupID, isc_spb_sec_groupid);
      if (ModifyPassword in FModifyParams) then
        ServiceStartAddParam (UTF8Encode(FPassword), isc_spb_sec_password);
      if (ModifyFirstName in FModifyParams) then
        ServiceStartAddParam (UTF8Encode(FFirstName), isc_spb_sec_firstname);
      if (ModifyMiddleName in FModifyParams) then
        ServiceStartAddParam (UTF8Encode(FMiddleName), isc_spb_sec_middlename);
      if (ModifyLastName in FModifyParams) then
        ServiceStartAddParam (UTF8Encode(FLastName), isc_spb_sec_lastname);
      if (ModifySecAdmin in FModifyParams) then
       if FSecAdmin then
        ServiceStartAddParam (1, isc_spb_sec_admin)
       else
        ServiceStartAddParam (0, isc_spb_sec_admin);

      ServiceStartAddParam (UTF8Encode(FSQLRole), SPBConstantValues[isc_spb_sql_role_name]);
    end;
  end;
  ClearParams;
end;

{ TIBUnStructuredService }
constructor TpFIBControlAndQueryService.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FEof := False;
  FAction := 0;
end;

procedure TpFIBControlAndQueryService.SetAction(Value: Integer);
begin
  FEof := False;
  FAction := Value;
end;


function TpFIBControlAndQueryService.GetNextChunk: String;
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
  ServiceQueryParams := AnsiChar(isc_info_svc_to_eof);
  InternalServiceQuery;
  if (OutputBuffer[0] <> AnsiChar(isc_info_svc_to_eof)) then
    FIBError(feOutputParsingError, [nil]);
  LoadLibrary;
  Length := FClientLibrary.isc_vax_integer(OutputBuffer + 1, 2);
  if (OutputBuffer[3 + Length] = AnsiChar(isc_info_truncated)) then
    FEof := False
  else
    if (OutputBuffer[3 + Length] = AnsiChar(isc_info_end)) then
      FEof := True
    else
      FIBError(feOutputParsingError, [nil]);
  OutputBuffer[3 + Length] := #0;
  result := AnsiString(PAnsiChar(@OutputBuffer[3]));
end;

procedure TpFIBControlAndQueryService.ServiceStart;
begin
  inherited;
  if Assigned(FOnTextNotify) then
    while not Eof do FOnTextNotify(Self, GetNextLine);
end;

function TpFIBControlAndQueryService.GetNextLine: String;
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
  Length := FClientLibrary.isc_vax_integer(OutputBuffer + 1, 2);
  if (OutputBuffer[3 + Length] <> AnsiChar(isc_info_end)) then
    FIBError(feOutputParsingError, [nil]);
  if (length <> 0) then
    FEof := False
  else
  begin
    result := '';
    FEof := True;
    exit;
  end;
  OutputBuffer[3 + Length] := #0;
  result := AnsiString(PAnsiChar(@OutputBuffer[3]));
end;

{ TpFIBLogService }

procedure TpFIBLogService.SetServiceStartOptions;
begin
  Action := isc_action_svc_get_ib_log;
  ServiceStartParams  := AnsiChar(isc_action_svc_get_ib_log);
end;

{ TDatabaseInfo }

constructor TDatabaseInfo.Create;
begin
  DbName := nil;
end;

destructor TDatabaseInfo.Destroy;
begin
  DbName := nil;
  inherited Destroy;
end;

{ TLicenseInfo }

constructor TLicenseInfo.Create;
begin
  Key := nil;
  Id := nil;
  Desc := nil;
end;

destructor TLicenseInfo.Destroy;
begin
  Key := nil;
  Id := nil;
  Desc := nil;
  inherited Destroy;
end;

{ TConfigFileData }

constructor TConfigFileData.Create;
begin
  ConfigFileValue := nil;
  ConfigFileKey := nil;
end;

destructor TConfigFileData.Destroy;
begin
  ConfigFileValue := nil;
  ConfigFileKey := nil;
  inherited Destroy;
end;

{ TConfigParams }

constructor TConfigParams.Create;
begin
  ConfigFileData := TConfigFileData.Create;
  ConfigFileParams := nil;
end;

destructor TConfigParams.Destroy;
begin
  ConfigFileData.Free;
  ConfigFileParams := nil;
  inherited Destroy;
end;

{$ENDIF}


function TpFIBControlAndQueryService.GetNextBuf: AnsiString;
var
  ALength: Integer;
begin
  Result := '';
  if (Self.FEof = True) then
    Exit;
  if (Self.FAction = 0) then
    FIBError(feQueryParamsError, [nil]);
  ServiceQueryParams := AnsiChar(isc_info_svc_to_eof);
  InternalServiceQuery;
  if (OutputBuffer[0] <> AnsiChar(isc_info_svc_to_eof)) then
    FIBError(feOutputParsingError, [nil]);
  //LoadLibrary;
  ALength := ClientLibrary.isc_vax_integer(OutputBuffer + 1, 2);
  if (OutputBuffer[3 + ALength] = AnsiChar(isc_info_truncated)) then
    Self.FEof := False
  else
    if (OutputBuffer[3 + ALength] = AnsiChar(isc_info_end)) then
      Self.FEof := True
    else
      FIBError(feOutputParsingError, [nil]);
  SetString(Result, PAnsiChar(@OutputBuffer[3]), ALength);
end;

end.
