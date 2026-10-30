{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ InterBase databases                                           }
{                                                               }
{    FIBPlus is based in part on the product                    }
{    Free IB Components, written by Gregory H. Deatz for        }
{    Hoagland, Longo, Moran, Dunst & Doukas Company.            }
{    mailto:gdeatz@hlmdd.com                                    }
{                                                               }
{    Copyright (c) 1998-2013 Devrace Ltd.                       }
{    Written by Serge Buzadzhy                                  }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit FIBDatabase;

interface

{$I FIB.inc}
{$IFDEF C23}
{$UNDEF NO_GUI}
{$UNDEF DIRECT_USE_DB_LOGIN_FORM}
{$ENDIF}

uses
  SysUtils, SyncObjs, Classes, DB, ibase, IB_Intf, IB_Externals,
  FIBProps, IBBlobFilter, FIB, FIBEventLists, StdFuncs,
  FIBInterfaces, FIBPlatforms, Variants
{$IFDEF C23}
  , System.UITypes
{$ENDIF}
{$IFDEF DIRECT_USE_DB_LOGIN_FORM}
  , FIBLoginDlg // IS GUI
{$ENDIF}
  ;

type

  TFIBDatabase = class;
  TFIBTransaction = class;
  TFIBBase = class;
  TDesignDBOption = (ddoIsDefaultDatabase, ddoStoreConnected, ddoNotSavePassword);
  TDesignDBOptions = set of TDesignDBOption;

  TFIBDatabaseEventType = (detOnConnect, detBeforeDisconnect, detBeforeDestroy);
  TFIBUseRepository = (urFieldsInfo, urDataSetInfo, urErrorMessagesInfo);
  TFIBUseRepositories = set of TFIBUseRepository;
  TFBContextSpace = (csSystem, csSession, csTransaction);
  TDatabaseRunStateValues = (drsInCloseLostConnect, drsInRestoreLostConnect, drsInClose);
  TDatabaseRunState = set of TDatabaseRunStateValues;
  TBeforeSaveBlobToSwap = procedure(const TableName, FieldName: string;
  { const } RecordKeyValues: array of variant; Stream: TStream;
    var FileName: string; var CanSave: Boolean) of object;

  TAfterSaveLoadBlobSwap = procedure(const TableName, FieldName: string;
  { const } RecordKeyValues: array of variant; const FileName: string)
  of object;

  TBeforeLoadBlobFromSwap = procedure(const TableName, FieldName: string;
  { const } RecordKeyValues: array of variant; var FileName: string;
    var CanLoad: Boolean) of object;

  TActionOnIdle = (aiCloseConnect, aiKeepLiveConnect);
  TOnIdleConnect = procedure(Sender: TFIBDatabase; IdleTicks: Cardinal; var Action: TActionOnIdle) of object;

  TFIBLoginEvent = procedure(Database: TFIBDatabase; LoginParams: TStrings; var DoConnect: Boolean) of object;
  TFIBAcceptCacheSchemaEvent = procedure(const ObjName: string; var Accept: Boolean) of object;

  TOnLostConnectActions = (laTerminateApp, laCloseConnect, laIgnore, laWaitRestore);
  TFIBLostConnectEvent = procedure(Database: TFIBDatabase; E: EFIBError;
    var Actions: TOnLostConnectActions; var DoRaise: Boolean) of object;
  TFIBRestoreConnectEvent = procedure(Database: TFIBDatabase) of object;

  TTransactionAction = (TARollback, TARollbackRetaining, TACommit, TACommitRetaining);
  TEndTrEvent = procedure(EndingTR: TFIBTransaction; Action: TTransactionAction; Force: Boolean) of object;

  TIBCharSets = set of Byte;

  // What the connection supports and how it is set up; Close keeps the code pages (open datasets)
  TFIBDatabaseCapabilities = class
  private
    FMaxIdentifierLength: Integer;
    FSessionTimeouts: Boolean;
    FReadConsistency: Boolean;
    FStatementTimeout: Boolean;
    FAttachmentCharSetID: Integer;
    FFirebird: Boolean;
    FBlobsConverted: Boolean;
    // values in the column charset: NONE, Firebird 1.x not Unicode
    FCharSetPerColumn: Boolean;
    FUnicodeCharSets: TIBCharSets;
    FCodePage: Word;
    FMetadataCodePage: Word;
    FTPBCodePage: Word;
    procedure Clear;
    procedure Update(Database: TFIBDatabase);
    procedure UpdateCodePages(Database: TFIBDatabase);
  public
    constructor Create;
    // Of values sent in CharSetID (sqlsubtype)
    function TextCodePage(CharSetID: Integer): Word;
    // Of text BLOBs sent in CharSetID (sqlscale)
    function BlobCodePage(CharSetID: Integer): Word;
    // Characters of a metadata name: 63 on Firebird 4 and later, else 31
    property MaxIdentifierLength: Integer read FMaxIdentifierLength;
    // Firebird 4+ server: Session.StatementTimeout and Session.IdleTimeout
    property SessionTimeouts: Boolean read FSessionTimeouts;
    // Firebird 4+ server: read_consistency in the TPB, TPBMode tpbReadConsistency
    property ReadConsistency: Boolean read FReadConsistency;
    // also fb_dsql_set_timeout in the client (fbclient 4+): TFIBQuery and TFIBDataSet.StatementTimeout
    property StatementTimeout: Boolean read FStatementTimeout;
    // -1 when unknown (InterBase), 0 is NONE
    property AttachmentCharSetID: Integer read FAttachmentCharSetID;
    // SQL text
    property CodePage: Word read FCodePage;
    // DDL and the names the server sends; UTF-8 on NONE (metadata is not converted)
    property MetadataCodePage: Word read FMetadataCodePage;
    // Table names of lock_read and lock_write in the TPB
    property TPBCodePage: Word read FTPBCodePage;
  end;

  // Live state of the attachment; values are kept while disconnected and sent on connect
  TFIBSession = class(TPersistent)
  private
    FDatabase: TFIBDatabase;
    FStatementTimeout: Cardinal;
    FIdleTimeout: Cardinal;
    procedure SetStatementTimeout(Value: Cardinal);
    procedure SetIdleTimeout(Value: Cardinal);
    function GetActualStatementTimeout: Cardinal;
    function GetActualIdleTimeout: Cardinal;
    function IsLive: Boolean;
    procedure Execute(const SQL: AnsiString);
    procedure SendStatementTimeout(Value: Cardinal);
    procedure SendIdleTimeout(Value: Cardinal);
    procedure ApplyOnConnect;
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(Database: TFIBDatabase);
    procedure Assign(Source: TPersistent); override;
    // Sends all values to the server again, e.g. after ALTER SESSION RESET or a SET sent by SQL
    procedure Apply;
    property Database: TFIBDatabase read FDatabase;
    // the attachment value on the server, without the firebird.conf limit
    property ActualStatementTimeout: Cardinal read GetActualStatementTimeout;
    // the attachment value on the server, without the firebird.conf limit
    property ActualIdleTimeout: Cardinal read GetActualIdleTimeout;
  published
    // ms, Firebird 4+; TFIBQuery.StatementTimeout overrides it per statement
    // also open cursors: the timer runs until EOF
    property StatementTimeout: Cardinal read FStatementTimeout write SetStatementTimeout default 0;
    // s, Firebird 4+; the server closes the idle attachment (TFIBDatabase.Timeout is client-side)
    property IdleTimeout: Cardinal read FIdleTimeout write SetIdleTimeout default 0;
  end;

// TFIBDatabase

{$IFDEF C23}
  TDoChangeScreenCursor = procedure(NewCursor: Integer; var OldCursor: Integer) of object;
{$ENDIF}

  TFIBDatabase = class(TComponent, IIbClientLibrary, IFIBConnect)
  private
    FSQLLogger: ISQLLogger;
    FSQLStatMaker: ISQLStatMaker;
    FUseRepositories: TFIBUseRepositories;
    FLibraryName: string;
    FUseBlrToTextFilter: Boolean;
    FClientLibLoaded: Boolean;
    FBlobSwapSupport: TBlobSwapSupport;
    FBeforeSaveBlobToSwap: TBeforeSaveBlobToSwap;
    FAfterSaveBlobToSwap: TAfterSaveLoadBlobSwap;
    FAfterLoadBlobFromSwap: TAfterSaveLoadBlobSwap;
    FBeforeLoadBlobFromSwap: TBeforeLoadBlobFromSwap;
    FOnIdleConnect: TOnIdleConnect;
    FAutoReconnect: Boolean;
    FGenerators: TGeneratorsCache;
    FMemoSubtypes: TMemoSubtypes;
    FCryptKey: FIBByteString;
    FOnCryptKeyRequest: TFIBCryptKeyRequestEvent;
    FCryptKeyCallback: TFIBCryptKeyCallback;
{$IFDEF C23}
    FLibraryName64: string;
    FDoChangeScreenCursor: TDoChangeScreenCursor;
{$ENDIF}
    FRestoreConnectTimer: TFIBTimer;
    FWaitForRestoreConnect: Cardinal;
    FAliasName: string;
    FSaveAliasParamsAfterConnect: Boolean;
    FBeforeConnect: TFIBLoginEvent;
    FOnLostConnect: TFIBLostConnectEvent;
    FOnErrorRestoreConnect: TFIBLostConnectEvent;
    FAfterRestoreConnect: TFIBRestoreConnectEvent;
    FBeforeStartTransaction: TNotifyEvent;
    FAfterStartTransaction: TNotifyEvent;
    FBeforeEndTransaction: TEndTrEvent;
    FAfterEndTransaction: TEndTrEvent;
    FCacheSchemaOptions: TCacheSchemaOptions;
    FOnAcceptCacheSchema: TFIBAcceptCacheSchemaEvent;
    procedure SetAliasName(const Value: string);
    procedure SetWaitForRestoreConnect(Value: Cardinal);
    procedure SetCacheSchemaOptions(Value: TCacheSchemaOptions);
    function GetFIBDataSet(Index: Integer): TDataSet;
    function GetFIBQuery(Index: Integer): TComponent;
    function GetFIBVersion: string;
    procedure SetFIBVersion(const Value: string);
    function GetInRestoreConnect: Boolean;
    procedure AfterOpen;
    procedure DoCryptKeyRequest(Sender: TObject; const Data: FIBByteString; var Key: FIBByteString);

    function GetMemoSubtypes: string;
    procedure SetMemoSubtypes(const Value: string);
    procedure SetGenerators(Value: TGeneratorsCache);

    procedure SetLibraryName(const LibName: string);

    function StoredLibraryName: Boolean;
{$IFDEF C23}
    function StoredLibraryName64: Boolean;
{$ENDIF}
    procedure LoadLibrary;
    procedure SetBlobSwapSupport(const Value: TBlobSwapSupport);
    procedure SetSQLLogger(const Value: ISQLLogger);
    procedure SetSQLStatMaker(const Value: ISQLStatMaker);

    function GetBusy: Boolean;
  protected
    FClientLibrary: IIbClientLibrary;
    FFIBBases: TList; // TFIBBases attached.
    FTransactions: TList; // TFIBTransactions attached.
    FDBName: string; // DB's name
    FDBParams: TDBParams; // "Pretty" Parameters to database
    FDBParamsChanged: Boolean; // Flag to determine if DPB must be regenerated
    FDPB: PAnsiChar; // Parameters to DB as passed to IB.
    FDPBLength: Short; // Length of parameter buffer
    FHandle: TISC_DB_HANDLE; // DB's handle
    FHandleIsShared: Boolean; // Is the handle shared with another DB?
    FUseLoginPrompt: Boolean; // Show a default login prompt?
    FOnConnect: TNotifyEvent; // Upon successful connection...
    FOnTimeout: TNotifyEvent; // Upon timing out...
    FDefaultTransaction: TFIBTransaction;
    // Many transaction components can be specified, but this is the primary, or default one to use.
    FDefaultUpdateTransaction: TFIBTransaction; //
    FStreamedConnected: Boolean;
    // Used for delaying the opening of the database.
    FTimer: TFIBTimer; // The timer ID.
    FUserNames: TStringList; // For use only with GetUserNames
    FActiveTransactions: TStringList; // For use only with GetActiveTransactions
    FBackoutCount: TStringList; // isc_info_backout_count
    FDeleteCount: TStringList; // isc_info_delete_count
    FExpungeCount: TStringList; // isc_info_expunge_count
    FInsertCount: TStringList; // isc_info_insert_count
    FPurgeCount: TStringList; // isc_info_purge_count
    FReadIdxCount: TStringList; // isc_info_read_idx_count
    FReadSeqCount: TStringList; // isc_info_read_seq_count
    FUpdateCount: TStringList; // isc_info_update_count
    // IB6
    FSQLDialect: Integer;
    FUpperOldNames: Boolean;
    // compatibility with IB4..5 field names conventions
    FConnectParams: TConnectParams;
    FDesignDBOptions: TDesignDBOptions;
    FBeforeDisconnect: TNotifyEvent;
    FAfterDisconnect: TNotifyEvent;
    FDifferenceTime: Double;
    FSynchronizeTime: Boolean;
    FInternalTransaction: TFIBTransaction;

    FAfterConnectEvents: TNotifyEventList;
    FBeforeDisconnectEvents: TNotifyEventList;
    FBeforeDestroyEvents: TNotifyEventList;

    FAttachmentID: Int64;
    FConnectionSerial: Integer;
    FBlobFilters: TIBBlobFilters;
    FDBFileName: string;
    FConnectType: Byte;
    FNeedUnicodeFieldsTranslation: Boolean;
    FIsUnicodeConnect: Boolean;
    FIsNoneConnect: Boolean;
    FDatabaseRunState: TDatabaseRunState;
    FLastActiveTime: Cardinal;
    FStreammedConnectFail: Boolean;
    procedure DBParamsChange(Sender: TObject);
    procedure DBParamsChanging(Sender: TObject);
    function GetConnected: Boolean; // Is DB connected?
    function GetDatabaseName: string;
    function GetFIBBase(Index: Integer): TFIBBase; // Get the indexed FIBBase.
    function GetFIBBasesCount: Integer; // Get the number of FIBBase connected.
    function GetDBParamByDPB(const Idx: Integer): string;
    function FindConfigParam(const Name: string; out Value: string): Integer;
    function GetConfigParam(const Name: string): string;
    function GetTimeout: Cardinal; // Get the timeout
    function GetTransaction(Index: Integer): TFIBTransaction;
    function GetFirstActiveTransaction: TFIBTransaction;
    function GetTransactionCount: Integer;
    function GetActiveTransactionCount: Integer;
    function Login: Boolean; // Show login prompt
    procedure SetConnected(Value: Boolean);
    procedure SetDatabaseName(const Value: string);
    procedure SetDBParamByDPB(const Idx: Integer; Value: string);
    procedure SetDBParamByName(const ParName, Value: string);
    procedure SetConfigParam(const Name: string; const Value: string);
    procedure SetDBParams(Value: TDBParams);
    procedure SetDefaultTransaction(Value: TFIBTransaction);
    procedure SetDefaultUpdateTransaction(Value: TFIBTransaction);
    procedure CreateTimeoutTimer;
    procedure SetHandle(Value: TISC_DB_HANDLE);
    procedure SetTimeout(Value: Cardinal);
    procedure SetDesignDBOptions(Value: TDesignDBOptions);
    procedure TimeoutConnection(Sender: TObject);
    // Database Info procedures -- Advanced stuff (translated from isc_database_info)
    function GetAllocation: Long; // isc_info_allocation
    function GetBaseLevel: Long; // isc_info_base_level
    function GetDBFileName: string; // isc_info_db_id
    function GetDBSiteName: string; // isc_info_db_id
    function GetIsRemoteConnect: Boolean; // isc_info_db_id

    function GetDBImplementationNo: Long; // isc_info_implementation
    function GetDBImplementationClass: Long;
    function GetNoReserve: Long; // isc_info_no_reserve
    function GetODSMinorVersion: Long; // isc_info_ods_minor_version
    function GetODSMajorVersion: Long; // isc_info_ods_version
    function ReadUTF8Metadata: Boolean;
    function GetPageSize: Long; // isc_info_page_size
    function GetVersion: string; // isc_info_info_version
    function GetCurrentMemory: Long; // isc_info_current_memory
    function GetForcedWrites: Long; // isc_info_forced_writes
    function GetMaxMemory: Long; // isc_info_max_memory
    function GetNumBuffers: Long; // isc_info_num_buffers
    function GetSweepInterval: Long; // isc_info_sweep_interval
    function GetUserNames: TStringList; // isc_info_user_names
    function GetFetches: Long; // isc_info_fetches
    function GetMarks: Long; // isc_info_marks
    function GetReads: Long; // isc_info_reads
    function GetWrites: Long; // isc_info_writes
    function GetBackoutCount: TStringList; // isc_info_backout_count
    function GetDeleteCount: TStringList; // isc_info_delete_count
    function GetExpungeCount: TStringList; // isc_info_expunge_count
    function GetInsertCount: TStringList; // isc_info_insert_count
    function GetPurgeCount: TStringList; // isc_info_purge_count
    function GetReadIdxCount: TStringList; // isc_info_read_idx_count
    function GetReadSeqCount: TStringList; // isc_info_read_seq_count
    function GetUpdateCount: TStringList; // isc_info_update_count

    function GetTableOperationInfo(const TableName: string; FromStrs: TStrings): Integer;

    function GetIndexedReadCount(const TableName: string): Integer;
    function GetNonIndexedReadCount(const TableName: string): Integer;
    function GetInsertsCount(const TableName: string): Integer;
    function GetUpdatesCount(const TableName: string): Integer;
    function GetDeletesCount(const TableName: string): Integer;

    function GetOperationCounts(DBInfoCommand: Integer; var FOperation: TStringList): TStringList;
    function GetAllModifications: Integer;

    function GetLogFile: Long; // isc_info_log_file
    function GetCurLogFileName: string; // isc_info_cur_logfile_name
    function GetCurLogPartitionOffset: Long; // isc_info_cur_log_part_offset
    function GetNumWALBuffers: Long; // isc_info_num_wal_buffers
    function GetWALBufferSize: Long; // isc_info_wal_buffer_size
    function GetWALCheckpointLength: Long; // isc_info_wal_ckpt_length
    function GetWALCurCheckpointInterval: Long;
    // isc_info_wal_cur_ckpt_interval
    function GetWALPrvCheckpointFilename: string; // isc_info_wal_prv_ckpt_fname
    function GetWALPrvCheckpointPartOffset: Long;
    // isc_info_wal_prv_ckpt_poffset
    function GetWALGroupCommitWaitUSecs: Long; // isc_info_wal_grpc_wait_usecs
    function GetWALNumIO: Long; // isc_info_wal_num_id
    function GetWALAverageIOSize: Long; // isc_info_wal_avg_io_size
    function GetWALNumCommits: Long; // isc_info_wal_num_commits
    function GetWALAverageGroupCommitSize: Long; // isc_info_wal_avg_grpc_size

    function GetProtectLongDBInfo(DBInfoCommand: Integer; var Success: Boolean): Long;
    function GetStringDBInfo(DBInfoCommand: Integer): string;
    function GetLongDBInfo(DBInfoCommand: Integer): Long;
    function GetInt64DBInfo(DBInfoCommand: Integer): Int64;
    function GetAttachmentID: Int64;

    // Firebird Info
    function GetActiveTransactions: TStringList; // frb_info_active_transactions
    function GetOldestTransaction: Long; // frb_info_oldest_transaction
    function GetOldestActive: Long; // frb_info_oldest_active
    function GetOldestSnapshot: Long; // frb_info_oldest_snapshot
    function GetFBVersion: string; // frb_info_firebird_version
    function GetCreationDate: TDateTime; // frb_info_creation_date
  private
    // Versions
    FServerMajorVersion: Integer;
    FServerMinorVersion: Integer;
    FServerRelease: Integer;
    FServerBuild: Integer;
    FNeedUTFDecodeDDL: Boolean;
    FIsFB21OrMore: Boolean;
    // Firebird 2.1 and later with ODS 11.1 and later: the metadata is stored in UTF-8
    FUTF8Metadata: Boolean;
    FCapabilities: TFIBDatabaseCapabilities;
    FSession: TFIBSession;
    procedure SetSession(Value: TFIBSession);
    procedure InitAttachment;
    procedure DropAttachment;
    procedure RaiseFeatureNotSupported(const Feature: string; ByClientLibrary: Boolean);
    procedure FillServerVersions;
    function GetServerMajorVersion: Integer;
    function GetServerMinorVersion: Integer;
    function GetServerRelease: Integer;
    function GetServerBuild: Integer;
  protected
    function GetInternalTransaction: TFIBTransaction; // friend for FIBDataInfo
    property StreammedConnectFail: Boolean read FStreammedConnectFail;

  protected
    // IB6
    function GetDBSQLDialect: Word;
    function GetSQLDialect: Integer;
    procedure SetSQLDialect(const Value: Integer);

    function GetReadOnly: Long;
    function GetStoreConnected: Boolean;
{$IFDEF     CSMonitor}
  private
    FCSMonitorSupport: TCSMonitorSupport;
    procedure SetCSMonitorSupport(Value: TCSMonitorSupport);
{$ENDIF}
  protected
    FIsFireBirdConnect: Boolean;
    FIsIB2007Connect: Boolean;
    function GetIsFirebirdConnect: Boolean;
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure InternalClose(Force: Boolean; DBinShutDown: Boolean = False); virtual;
    procedure AbandonServerHandles;
    procedure DoOnConnect;
    procedure DoBeforeDisconnect;
    procedure DoAfterDisconnect;

{$IFDEF USE_DEPRECATE_METHODS1}
    procedure RemoveDataSet(Idx: Integer); deprecated;
    procedure RemoveDataSets; deprecated;
    function AddDataSet(ds: TFIBBase): Integer; deprecated;
{$ENDIF}
    procedure RemoveFIBBase(Idx: Integer);
    procedure RemoveFIBBases;
    function AddFIBBase(ds: TFIBBase): Integer;

    procedure RemoveTransaction(Idx: Integer);
    procedure RemoveTransactions;
    function AddTransaction(TR: TFIBTransaction): Integer;
    procedure IBFilterBuffer(var BlobBuffer: PAnsiChar; var BlobSize: LongInt; BlobSubType: Integer; ForEncode: Boolean);
    procedure CloseLostConnect;
    procedure DoOnLostConnect(Database: TFIBDatabase; E: EFIBError; var Actions: TOnLostConnectActions;
      var DoRaise: Boolean); dynamic;
    procedure DoOnErrorRestoreConnect(Database: TFIBDatabase; E: EFIBError; var Actions: TOnLostConnectActions); dynamic;
    procedure DoAfterRestoreConnect; dynamic;
    function GetAfterConnect: TNotifyEvent;
    procedure SetAfterConnect(Method: TNotifyEvent);
    procedure CreateRestoreConnectTimer;
    procedure ReadSaveDBParams(Reader: TReader);
    procedure DefineProperties(Filer: TFiler); override;

  public
    procedure AddEvent(Event: TNotifyEvent; EventType: TFIBDatabaseEventType);
    procedure RemoveEvent(Event: TNotifyEvent; EventType: TFIBDatabaseEventType);

    procedure RegisterBlobFilter(BlobSubType: Integer; EncodeProc, DecodeProc: PIBBlobFilterProc);
    procedure RemoveBlobFilter(BlobSubType: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Call(ErrCode: ISC_STATUS; RaiseError: Boolean): ISC_STATUS;

    procedure CheckActive(TryReconnect: Boolean = False);
    // Raise error if DB is inactive
    procedure CheckInactive; // Raise error if DB is active
    procedure CheckDatabaseName; // Raise error if DBName is empty
    procedure Close;

    procedure CreateDatabase;
    property DBParamByDPB[const Idx: Integer]: string read GetDBParamByDPB write SetDBParamByDPB;
    property ConfigParam[const Name: string]: string read GetConfigParam write SetConfigParam;
    procedure DropDatabase;
    function FindTransaction(TR: TFIBTransaction): Integer;
    procedure ForceClose;
    function IndexOfDBConst(const st: string): Integer;
    // Get the index of a given constant in DBParams
    procedure Open(RaiseExcept: Boolean = True); virtual;
    function ReadParamsFromAlias: Boolean; dynamic;
    // IFIBObject
    procedure SaveAlias; virtual;
    function ExTestConnected(Actions: TOnLostConnectActions): Boolean;
    procedure WaitRestoreConnect;
    procedure StopWaitRestoreConnect;
    procedure RestoreConnect(Sender: TObject);
    procedure GetTableNames(TableNames: TStrings; WithSystem: Boolean);
    procedure GetFieldNames(const TableName: string; FieldNames: TStrings; WithComputedFields: Boolean = True);
    procedure ApplyUpdates(const DataSets: array of TDataSet);
    procedure ForceCloseTransactions;
    procedure CloseDataSets;
    function FIBQueryCount: Integer;
    function FIBDataSetsCount: Integer;
    property FIBDataSets[Index: Integer]: TDataSet read GetFIBDataSet;
    property FIBQueries[Index: Integer]: TComponent read GetFIBQuery;
    property SaveDBParams: Boolean read FSaveAliasParamsAfterConnect write FSaveAliasParamsAfterConnect default True;
    property InRestoreConnect: Boolean read GetInRestoreConnect;
    function TestConnected: Boolean;
    function PingAttachment: ISC_STATUS;
    function GetServerTime: TDateTime;
    // FB
    procedure ShutDown(const ShutParams: array of Integer; Delay: Integer = 0);
    procedure Online;
  public
    function ClientVersion: string;
    // 6.3 on every Firebird client, use ClientLibrary.Version
    function ClientMajorVersion: Integer; deprecated;
    function ClientMinorVersion: Integer; deprecated;
    function IsFirebirdConnect: Boolean;
    // EFIBClientError for a non-zero value the server or the client library can't apply; 0 never raises
    procedure RequireSessionTimeouts(const PropName: string; Value: Cardinal);
    // FIBNoStatementTimeout never raises without SessionTimeouts: there is no attachment value then
    procedure RequireStatementTimeout(const PropName: string; Value: Cardinal);
    procedure RequireReadConsistency(const PropName: string);

    function IsUnicodeConnect: Boolean;
    function IsIB2007Connect: Boolean;
    function NeedUTFEncodeDDL: Boolean;
    function NeedUnicodeFieldsTranslation: Boolean;
    function NeedUnicodeFieldTranslation(FieldCharacterSet: Integer): Boolean;
    function IsKOI8Connect: Boolean; deprecated;
    { FB2 features }
    function GetContextVariable(ContextSpace: TFBContextSpace; const VarName: string; aTransaction: TFIBTransaction = nil): variant;
    procedure SetContextVariable(ContextSpace: TFBContextSpace; const VarName, VarValue: string; aTransaction: TFIBTransaction = nil);

    function CanCancelOperationFB21: Boolean;
    procedure CancelOperationFB21(ConnectForCancel: TFIBDatabase = nil);

    procedure RaiseCancelOperations;
    procedure EnableCancelOperations;
    procedure DisableCancelOperations;
    //
    function UnicodeCharSets: TIBCharSets;
    function UTF8CharSetID: Integer;
    function BytesInUnicodeChar(CharSetId: Integer): Byte;
    function ReturnDeclaredFieldSize: Boolean;
    function MemoSubTypesActive: Boolean;
    function IsMemoSubtype(aSubtype: SmallInt): Boolean;
    function LibraryFilePath: string;

{$IFDEF USE_DEPRECATE_METHODS1}
    property DataSetCount: Integer read GetFIBBasesCount; // deprecated;
    property DataSets[Index: Integer]: TFIBBase read GetFIBBase; // deprecated;
{$ENDIF}
    property FIBBaseCount: Integer read GetFIBBasesCount;
    property FIBBases[Index: Integer]: TFIBBase read GetFIBBase;

    property Handle: TISC_DB_HANDLE read FHandle write SetHandle;
    property HandleIsShared: Boolean read FHandleIsShared;
    property TransactionCount: Integer read GetTransactionCount;
    property FirstActiveTransaction: TFIBTransaction read GetFirstActiveTransaction;
    property ActiveTransactionCount: Integer read GetActiveTransactionCount;
    property Transactions[Index: Integer]: TFIBTransaction read GetTransaction;

    property IsFB21OrMore: Boolean read FIsFB21OrMore;
    property Capabilities: TFIBDatabaseCapabilities read FCapabilities;
    // Database Info properties -- Advanced stuff (translated from isc_database_info)
    property AttachmentID: Int64 read GetAttachmentID; // isc_info_attachment_id, 0 when not connected
    // Unique in the process per connection, kept after Close
    property ConnectionSerial: Integer read FConnectionSerial;
    property Allocation: Long read GetAllocation; // isc_info_allocation
    property BaseLevel: Long read GetBaseLevel; // isc_info_base_level
    property DBFileName: string read GetDBFileName; // isc_info_db_id
    property DBSiteName: string read GetDBSiteName;
    property IsRemoteConnect: Boolean read GetIsRemoteConnect;
    property DBImplementationNo: Long read GetDBImplementationNo;
    // isc_info_implementation
    property DBImplementationClass: Long read GetDBImplementationClass;
    property NoReserve: Long read GetNoReserve; // isc_info_no_reserve
    property ODSMinorVersion: Long read GetODSMinorVersion;
    // isc_info_ods_minor_version
    property ODSMajorVersion: Long read GetODSMajorVersion;
    // isc_info_ods_version
    property PageSize: Long read GetPageSize; // isc_info_page_size
    property Version: string read GetVersion; // isc_info_info_version

    property FBVersion: string read GetFBVersion;
    // Capabilities.AttachmentCharSetID
    function FBAttachCharsetID: Integer; deprecated;

    property ServerMajorVersion: Integer read GetServerMajorVersion;
    property ServerMinorVersion: Integer read GetServerMinorVersion;
    property ServerBuild: Integer read GetServerBuild;
    property ServerRelease: Integer read GetServerRelease;

    property CurrentMemory: Long read GetCurrentMemory;
    // isc_info_current_memory
    property ForcedWrites: Long read GetForcedWrites; // isc_info_forced_writes
    property MaxMemory: Long read GetMaxMemory; // isc_info_max_memory
    property NumBuffers: Long read GetNumBuffers; // isc_info_num_buffers
    property SweepInterval: Long read GetSweepInterval;
    // isc_info_sweep_interval
    property UserNames: TStringList read GetUserNames; // isc_info_user_names
    property Fetches: Long read GetFetches; // isc_info_fetches
    property Marks: Long read GetMarks; // isc_info_marks
    property Reads: Long read GetReads; // isc_info_reads
    property Writes: Long read GetWrites; // isc_info_writes
    property BackoutCount: TStringList read GetBackoutCount;
    // isc_info_backout_count
    property DeleteCount: TStringList read GetDeleteCount;
    // isc_info_delete_count
    property ExpungeCount: TStringList read GetExpungeCount;
    // isc_info_expunge_count
    property InsertCount: TStringList read GetInsertCount;
    // isc_info_insert_count
    property PurgeCount: TStringList read GetPurgeCount; // isc_info_purge_count
    property ReadIdxCount: TStringList read GetReadIdxCount;
    // isc_info_read_idx_count
    property ReadSeqCount: TStringList read GetReadSeqCount;
    // isc_info_read_seq_count
    property UpdateCount: TStringList read GetUpdateCount;
    // isc_info_update_count

    property IndexedReadCount[const TableName: string]: Integer read GetIndexedReadCount;
    property NonIndexedReadCount[const TableName: string]: Integer read GetNonIndexedReadCount;
    property InsertsCount[const TableName: string]: Integer read GetInsertsCount;
    property UpdatesCount[const TableName: string]: Integer read GetUpdatesCount;
    property DeletesCount[const TableName: string]: Integer read GetDeletesCount;
    property AllModifications: Integer read GetAllModifications;

    property LogFile: Long read GetLogFile; // isc_info_log_file
    property CurLogFileName: string read GetCurLogFileName;
    // isc_info_cur_logfile_name
    property CurLogPartitionOffset: Long read GetCurLogPartitionOffset;
    // isc_info_cur_log_part_offset
    property NumWALBuffers: Long read GetNumWALBuffers;
    // isc_info_num_wal_buffers
    property WALBufferSize: Long read GetWALBufferSize;
    // isc_info_wal_buffer_size
    property WALCheckpointLength: Long read GetWALCheckpointLength;
    // isc_info_wal_ckpt_length
    property WALCurCheckpointInterval: Long read GetWALCurCheckpointInterval;
    // isc_info_wal_cur_ckpt_interval
    property WALPrvCheckpointFilename: string read GetWALPrvCheckpointFilename;
    // isc_info_wal_prv_ckpt_fname
    property WALPrvCheckpointPartOffset: Long read GetWALPrvCheckpointPartOffset; // isc_info_wal_prv_ckpt_poffset
    property WALGroupCommitWaitUSecs: Long read GetWALGroupCommitWaitUSecs;
    // isc_info_wal_grpc_wait_usecs
    property WALNumIO: Long read GetWALNumIO; // isc_info_wal_num_id
    property WALAverageIOSize: Long read GetWALAverageIOSize;
    // isc_info_wal_avg_io_size
    property WALNumCommits: Long read GetWALNumCommits;
    // isc_info_wal_num_commits
    property WALAverageGroupCommitSize: Long read GetWALAverageGroupCommitSize;
    // isc_info_wal_avg_grpc_size
    // IB6
    property DBSQLDialect: Word read GetDBSQLDialect;
    property ReadOnly: Long read GetReadOnly;
    property DatabaseName: string read GetDatabaseName write SetDatabaseName;

    property DifferenceTime: Double read FDifferenceTime;
    // Firebird
    property ServerActiveTransactions: TStringList read GetActiveTransactions;
    property OldestTransactionID: Long read GetOldestTransaction;
    property OldestActiveTransactionID: Long read GetOldestActive;
    // In the session time zone (FB4+) or server local time, 0 if unsupported
    property CreationDate: TDateTime read GetCreationDate;
    property Busy: Boolean read GetBusy;
    // Not published, the key must not be stored in the form
    property CryptKey: FIBByteString read FCryptKey write FCryptKey;
  public
    procedure StartTransaction;
    procedure Commit;
    procedure Rollback;
    procedure CommitRetaining;
    procedure RollbackRetaining;

    function Gen_Id(const GeneratorName: string; Step: Int64; aTransaction: TFIBTransaction = nil): Int64;
    function Execute(const SQL: string): Boolean;

    procedure CreateGUIDDomain;
    function InternalQueryValue(const aSQL: string; FieldNo: Integer;
      ParamValues: array of variant; aTransaction: TFIBTransaction;
      aCacheQuery: Boolean): variant;
    function QueryValue(const aSQL: string; FieldNo: Integer;
      aTransaction: TFIBTransaction = nil; aCacheQuery: Boolean = True)
    : variant; overload;
    function QueryValue(const aSQL: string; FieldNo: Integer;
      ParamValues: array of variant; aTransaction: TFIBTransaction = nil;
      aCacheQuery: Boolean = True): variant; overload;

    function QueryValues(const aSQL: string; aTransaction: TFIBTransaction = nil; aCacheQuery: Boolean = True): variant; overload;
    function QueryValues(const aSQL: string; ParamValues: array of variant;
      aTransaction: TFIBTransaction = nil; aCacheQuery: Boolean = True)
    : variant; overload;

    function QueryValueAsStr(const aSQL: string; FieldNo: Integer): string; overload;
    function QueryValueAsStr(const aSQL: string; FieldNo: Integer; ParamValues: array of variant): string; overload;

    procedure ClearQueryCacheList;

    function EasyFormatsStr: Boolean;
    property StoreConnected: Boolean read GetStoreConnected;
    property ClientLibrary: IIbClientLibrary read FClientLibrary implements IIbClientLibrary;
    property SQLStatisticsMaker: ISQLStatMaker read FSQLStatMaker write SetSQLStatMaker;

  published
    property AutoReconnect: Boolean read FAutoReconnect write FAutoReconnect default False;
    property Connected: Boolean read GetConnected write SetConnected stored GetStoreConnected;
    property BlobSwapSupport: TBlobSwapSupport read FBlobSwapSupport write SetBlobSwapSupport;
    property DBName: string read GetDatabaseName write SetDatabaseName;
    property DBParams: TDBParams read FDBParams write SetDBParams;
    property DefaultTransaction: TFIBTransaction read FDefaultTransaction write SetDefaultTransaction;
    property DefaultUpdateTransaction: TFIBTransaction read FDefaultUpdateTransaction write SetDefaultUpdateTransaction;

    // IB6
    property SQLDialect: Integer read FSQLDialect write SetSQLDialect;

    property Timeout: Cardinal read GetTimeout write SetTimeout;
    property UseLoginPrompt: Boolean read FUseLoginPrompt write FUseLoginPrompt default False;
    // Events

    property OnTimeout: TNotifyEvent read FOnTimeout write FOnTimeout;
    property UpperOldNames: Boolean read FUpperOldNames write FUpperOldNames
    default False; // compatibility with IB4..5 field names conventions

    property BeforeDisconnect: TNotifyEvent read FBeforeDisconnect write FBeforeDisconnect;
    property AfterDisconnect: TNotifyEvent read FAfterDisconnect write FAfterDisconnect;
    property ConnectParams: TConnectParams read FConnectParams write FConnectParams stored False;
    property Session: TFIBSession read FSession write SetSession;
    property SynchronizeTime: Boolean read FSynchronizeTime write FSynchronizeTime default True;

    property DesignDBOptions: TDesignDBOptions read FDesignDBOptions write SetDesignDBOptions default [ddoStoreConnected];
    property OnConnect: TNotifyEvent read FOnConnect write FOnConnect stored False; // obsolete
    property BeforeSaveBlobToSwap: TBeforeSaveBlobToSwap read FBeforeSaveBlobToSwap write FBeforeSaveBlobToSwap;
    property AfterSaveBlobToSwap: TAfterSaveLoadBlobSwap read FAfterSaveBlobToSwap write FAfterSaveBlobToSwap;
    property AfterLoadBlobFromSwap: TAfterSaveLoadBlobSwap read FAfterLoadBlobFromSwap write FAfterLoadBlobFromSwap;
    property BeforeLoadBlobFromSwap: TBeforeLoadBlobFromSwap read FBeforeLoadBlobFromSwap write FBeforeLoadBlobFromSwap;
    property OnIdleConnect: TOnIdleConnect read FOnIdleConnect write FOnIdleConnect;
    // Called in the connecting thread, inside the global connect lock; Key starts as CryptKey
    property OnCryptKeyRequest: TFIBCryptKeyRequestEvent read FOnCryptKeyRequest write FOnCryptKeyRequest;
    property UseRepositories: TFIBUseRepositories read FUseRepositories
    write FUseRepositories default [urFieldsInfo, urDataSetInfo,
      urErrorMessagesInfo];
    property LibraryName: string read FLibraryName write SetLibraryName stored StoredLibraryName;
    // libfbclient.so MACOS
{$IFDEF C23}
    property LibraryName64: string read FLibraryName64 write FLibraryName64 stored StoredLibraryName64;
{$ENDIF}
    property SQLLogger: ISQLLogger read FSQLLogger write SetSQLLogger;
    property UseBlrToTextFilter: Boolean read FUseBlrToTextFilter write FUseBlrToTextFilter default False;
    property GeneratorsCache: TGeneratorsCache read FGenerators write SetGenerators;
{$IFDEF CSMonitor}
    property CSMonitorSupport: TCSMonitorSupport read FCSMonitorSupport write SetCSMonitorSupport;
{$ENDIF}
{$IFDEF C23}
    property DoChangeScreenCursor: TDoChangeScreenCursor read FDoChangeScreenCursor write FDoChangeScreenCursor;
{$ENDIF}
  published
    property MemoSubtypes: string read GetMemoSubtypes write SetMemoSubtypes;
    property CacheSchemaOptions: TCacheSchemaOptions read FCacheSchemaOptions write SetCacheSchemaOptions;
    property AliasName: string read FAliasName write SetAliasName;
    property WaitForRestoreConnect: Cardinal read FWaitForRestoreConnect write SetWaitForRestoreConnect default 30000;
    property SaveAliasParamsAfterConnect: Boolean read FSaveAliasParamsAfterConnect write FSaveAliasParamsAfterConnect default True;
    property BeforeConnect: TFIBLoginEvent read FBeforeConnect write FBeforeConnect;
    property AfterConnect: TNotifyEvent read GetAfterConnect write SetAfterConnect;
    property OnLostConnect: TFIBLostConnectEvent read FOnLostConnect write FOnLostConnect;
    property OnErrorRestoreConnect: TFIBLostConnectEvent read FOnErrorRestoreConnect write FOnErrorRestoreConnect;
    property AfterRestoreConnect: TFIBRestoreConnectEvent read FAfterRestoreConnect write FAfterRestoreConnect;
    property BeforeStartTransaction: TNotifyEvent read FBeforeStartTransaction write FBeforeStartTransaction;
    property AfterStartTransaction: TNotifyEvent read FAfterStartTransaction write FAfterStartTransaction;
    property BeforeEndTransaction: TEndTrEvent read FBeforeEndTransaction write FBeforeEndTransaction;
    property AfterEndTransaction: TEndTrEvent read FAfterEndTransaction write FAfterEndTransaction;
    property About: string read GetFIBVersion write SetFIBVersion stored False;
    property OnLogin: TFIBLoginEvent read FBeforeConnect write FBeforeConnect stored False; // obsolete
    property OnAcceptCacheSchema: TFIBAcceptCacheSchemaEvent read FOnAcceptCacheSchema write FOnAcceptCacheSchema;
  end;

  // TFIBTransaction

  TTransactionState = (tsActive, tsClosed, tsDoRollback, tsDoRollbackRetaining, tsDoCommit, tsDoCommitRetaining);

  TTransactionRunState = (trsInLoaded);
  TTransactionRunStates = set of TTransactionRunState;

  TFIBTransactionEventType = (
    tetBeforeStartTransaction,
    tetAfterStartTransaction,
    tetBeforeEndTransaction,
    tetAfterEndTransaction,
    tetBeforeDestroy
  );

  TOnSQLExecute = procedure(Query: TComponent; SQLType: TFIBSQLTypes) of object;

  TFIBTransaction = class(TComponent, IFIBTransaction)
  private
    FTPBMode: TTPBMode;
    FWritingPreset: Boolean;
    FReadConsistencyParams: Boolean;
    FInternal: Boolean;
    FBeforeStart: TNotifyEvent;
    FAfterStart: TNotifyEvent;
    FBeforeEnd: TEndTrEvent;
    FAfterEnd: TEndTrEvent;
    FBeforeSQLExecute: TOnSQLExecute;
    FAfterSQLExecute: TOnSQLExecute;
    FAfterFirstFetch: TOnSQLExecute;
    FUserKindTransaction: string;
    function EndPreset: Boolean;
    procedure SetTPBMode(Value: TTPBMode);
    procedure SetInternal(Value: Boolean);
    function StoreTRParams: Boolean;
    function StoreUserKindTransaction: Boolean;
    procedure SetUserKindTransaction(const Value: string);
    function GetFIBDataSet(Index: Integer): TDataSet;
    function GetFIBQuery(Index: Integer): TComponent;
    function GetFIBVersion: string;
    procedure SetFIBVersion(const Value: string);
    procedure DoBeforeStart;
    procedure DoAfterStart;
  protected
    FCanTimeout: Boolean; // Can the transaction timeout now?
    FDatabases: TList; // TDatabases in transaction.
    FFIBBases: TList; // TFIBBases  attached.
    FDefaultDatabase: TFIBDatabase;
    // just like DefaultTransaction in FIBDatabase
    FHandle: TISC_TR_HANDLE; // TR's handle
    FHandleIsShared: Boolean;
    FOnTimeout: TNotifyEvent; // When the transaction times out...
    FStreamedActive: Boolean;
    FTPB: PAnsiChar; // Parameters to TR as passed to IB.
    FTPBLength: Short; // Length of parameter buffer
    FTPBCodePage: Word; // Code page of the names in FTPB
    FTimer: TFIBTimer; // Timer for timing out transactions.
    FTimeoutAction: TTransactionAction; // Rollback or commit at end of timeout?
    FTRParams: TStrings; // Parameters to Transactions.
    FTRParamsChanged: Boolean;
    FState: TTransactionState;
    FTransactionID: Integer;
    FBeforeDestroyEvents: TNotifyEventList;
    FBeforeStartTransactionEvents: TNotifyEventList;
    FAfterStartTransactionEvents: TNotifyEventList;

    FBeforeEndTransactionEvents: TCallBackList;
    FAfterEndTransactionEvents: TCallBackList;
    FDatabaseTRParams: array of string;
    FDatabaseTPBs: array of AnsiString;
    FTransactionRunStates: TTransactionRunStates;
    FHasUncommitedUpdates: Boolean;
    FWatchUpdates: Boolean;
{$IFDEF CSMonitor}
    FCSMonitorSupport: TCSMonitorSupport;
    procedure SetCSMonitorSupport(Value: TCSMonitorSupport);
{$ENDIF}
    function GetTransactionID: Integer;
    function DoStoreActive: Boolean;
    procedure EndTransaction(Action: TTransactionAction; Force: Boolean); virtual;
    // End the transaction using specified method...
    function GetDatabase(Index: Integer): TFIBDatabase;
    // Get the indexed database
    function GetDatabaseCount: Integer;
    // Get the number of databases in transaction
    function GetFIBBase(Index: Integer): TFIBBase; // Get the indexed Dataset.
    function GetFIBBasesCount: Integer; // Get the number of Datasets connected.
    function GetInTransaction: Boolean; // Is there an active trans?
    function GetTimeout: Cardinal;

    procedure Loaded; override;
    procedure SetActive(Value: Boolean);
    procedure SetDefaultDatabase(Value: TFIBDatabase);
    procedure SetHandle(Value: TISC_TR_HANDLE);
    procedure SetTimeout(Value: Cardinal); // Set the timeout
    procedure SetTRParams(Value: TStrings);
    procedure TimeoutTransaction(Sender: TObject);
    procedure TRParamsChange(Sender: TObject);
    procedure TRParamsChanging(Sender: TObject);
    procedure RemoveDatabases;
{$IFDEF USE_DEPRECATE_METHODS1}
    procedure RemoveDataSet(Idx: Integer); deprecated;
    procedure RemoveDataSets; deprecated;
    function AddDataSet(ds: TFIBBase): Integer; deprecated;
{$ENDIF}
    procedure RemoveFIBBase(Idx: Integer);
    procedure RemoveFIBBases;
    function AddFIBBase(ds: TFIBBase): Integer;

    procedure CreateTimeoutTimer;
    // Starts it at design time or when every database has AutoReconnect, else raises
    procedure EnsureInTransaction;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function MainDatabase: TFIBDatabase;
    function FindDatabase(db: TFIBDatabase): Integer;
    procedure AddEvent(Event: TNotifyEvent; EventType: TFIBTransactionEventType);
    procedure RemoveEvent(Event: TNotifyEvent; EventType: TFIBTransactionEventType);

    procedure AddEndEvent(Event: TEndTrEvent; EventType: TFIBTransactionEventType);
    procedure RemoveEndEvent(Event: TEndTrEvent; EventType: TFIBTransactionEventType);

    procedure DoOnSQLExec(Query: TComponent; Kind: TKindOnOperation); virtual;

    function AddDatabase(db: TFIBDatabase): Integer; overload;
    function AddDatabase(db: TFIBDatabase; const aTRParams: string): Integer; overload;
    procedure RemoveDatabase(Idx: Integer);
    procedure ReplaceDatabase(dbOld, dbNew: TFIBDatabase);

    procedure OnDatabaseDisconnecting(db: TFIBDatabase);

    function Call(ErrCode: ISC_STATUS; RaiseError: Boolean): ISC_STATUS;
    procedure CheckDatabasesInList; // Raise error if no databases in list.
    procedure CheckInTransaction; // Raise error if not in transaction
    procedure CheckNotInTransaction; // Raise error if in transaction
    procedure StartTransaction; virtual;
    procedure Commit; virtual;
    procedure CommitRetaining; virtual;
    procedure Rollback; virtual;
    procedure RollbackRetaining; virtual;
    procedure ExecSQLImmediate(const SQLText: WideString);
    procedure SetSavePoint(const SavePointName: string);
    procedure RollBackToSavePoint(const SavePointName: string);
    procedure ReleaseSavePoint(const SavePointName: string);
    procedure CloseAllQueryHandles;
    function IsReadCommitedTransaction: Boolean;
    function IsReadOnly: Boolean;
    function FIBQueryCount: Integer;
    function FIBDataSetsCount: Integer;
    property FIBDataSets[Index: Integer]: TDataSet read GetFIBDataSet;
    property FIBQueries[Index: Integer]: TComponent read GetFIBQuery;
    // The database events (BeforeStartTransaction, ...) are not raised for it
    property Internal: Boolean read FInternal write SetInternal;
    property DatabaseCount: Integer read GetDatabaseCount;
    property Databases[Index: Integer]: TFIBDatabase read GetDatabase;
{$IFDEF USE_DEPRECATE_METHODS1}
    property DataSetCount: Integer read GetFIBBasesCount; // deprecated;
    property DataSets[Index: Integer]: TFIBBase read GetFIBBase; // deprecated;
{$ENDIF}
    property FIBBaseCount: Integer read GetFIBBasesCount;
    property FIBBases[Index: Integer]: TFIBBase read GetFIBBase;

    property Handle: TISC_TR_HANDLE read FHandle write SetHandle;
    property HandleIsShared: Boolean read FHandleIsShared;
    property InTransaction: Boolean read GetInTransaction;
    // property TPB: PChar read FTPB;
    // property TPBLength: Short read FTPBLength;
    property State: TTransactionState read FState;
    property TransactionID: Integer read GetTransactionID;
    property HasUncommitedUpdates: Boolean read FHasUncommitedUpdates;

  published
    property Active: Boolean read GetInTransaction write SetActive stored DoStoreActive;
    property DefaultDatabase: TFIBDatabase read FDefaultDatabase write SetDefaultDatabase;
    property Timeout: Cardinal read GetTimeout write SetTimeout default 0;
    property TimeoutAction: TTransactionAction read FTimeoutAction write FTimeoutAction default TARollback;
    property TRParams: TStrings read FTRParams write SetTRParams stored StoreTRParams;
    // Events
    property OnTimeout: TNotifyEvent read FOnTimeout write FOnTimeout;
    property WatchUncommitedUpdates: Boolean read FWatchUpdates write FWatchUpdates default False;
{$IFDEF CSMonitor}
    property CSMonitorSupport: TCSMonitorSupport read FCSMonitorSupport write SetCSMonitorSupport;
{$ENDIF}
    property BeforeStart: TNotifyEvent read FBeforeStart write FBeforeStart;
    property AfterStart: TNotifyEvent read FAfterStart write FAfterStart;
    property BeforeEnd: TEndTrEvent read FBeforeEnd write FBeforeEnd;
    property AfterEnd: TEndTrEvent read FAfterEnd write FAfterEnd;
    // A preset writes its lines into TRParams; any change of TRParams makes it tpbDefault
    property TPBMode: TTPBMode read FTPBMode write SetTPBMode default tpbReadCommitted;
    property UserKindTransaction: string read FUserKindTransaction write SetUserKindTransaction stored StoreUserKindTransaction;
    property About: string read GetFIBVersion write SetFIBVersion stored False;
    property AfterSQLExecute: TOnSQLExecute read FAfterSQLExecute write FAfterSQLExecute;
    property BeforeSQLExecute: TOnSQLExecute read FBeforeSQLExecute write FBeforeSQLExecute;
    property AfterFirstFetch: TOnSQLExecute read FAfterFirstFetch write FAfterFirstFetch;
  end;

  // TFIBBase
  // Virtually all components in FIB are "descendents" of TFIBBase.
  // It is to more easily manage the database and transaction
  // connections.
  TFIBBase = class(TObject)
  protected
    FDatabase: TFIBDatabase;
    FIndexInDatabase: Integer;
    FTransaction: TFIBTransaction;
    FIndexInTransaction: Integer;
    FOwner: TObject;
    procedure FOnDatabaseConnecting;
    procedure FOnDatabaseConnected;

    procedure FOnDatabaseDisconnecting;
    procedure FOnDatabaseDisconnected;
    procedure FOnDatabaseConnectionLost;

    procedure FOnTransactionStarting;
    procedure FOnTransactionStarted;

    procedure FOnDatabaseFree;
    procedure FOnTransactionEnding;
    procedure FOnTransactionEnded;
    procedure FOnTransactionFree;
    function GetDBHandle: PISC_DB_HANDLE;
    function GetTRHandle: PISC_TR_HANDLE;
    procedure SetDatabase(Value: TFIBDatabase);
    procedure SetTransaction(Value: TFIBTransaction);
  public
    constructor Create(AOwner: TObject);
    destructor Destroy; override;
    procedure CheckDatabase; virtual;
    procedure CheckTransaction; virtual;
  public // properties
    OnDatabaseConnecting: TNotifyEvent;
    OnDatabaseConnected: TNotifyEvent;

    OnDatabaseDisconnecting: TNotifyEvent;
    OnDatabaseDisconnected: TNotifyEvent;
    // forget server handles without calling the API
    OnDatabaseConnectionLost: TNotifyEvent;
    OnDatabaseFree: TNotifyEvent;
    OnTransactionEnding: TNotifyEvent;
    OnTransactionEnded: TNotifyEvent;
    OnTransactionStarting: TNotifyEvent;
    OnTransactionStarted: TNotifyEvent;

    OnTransactionFree: TNotifyEvent;
    property Database: TFIBDatabase read FDatabase write SetDatabase;
    property DBHandle: PISC_DB_HANDLE read GetDBHandle;
    property Owner: TObject read FOwner;
    property TRHandle: PISC_TR_HANDLE read GetTRHandle;
    property Transaction: TFIBTransaction read FTransaction write SetTransaction;
  end;

procedure SaveSchemaToFile(const FileName: string);
function LoadSchemaFromFile(const FileName: string; const NeedValidate: Boolean = True; db: TFIBDatabase = nil): Boolean;

procedure IBFilterBuffer(Database: TFIBDatabase; var BlobBuffer: PAnsiChar;
  var BlobSize: LongInt; BlobSubType: Integer; ForEncode: Boolean);

function ExistBlobFilter(Database: TFIBDatabase; BlobSubType: Integer): Boolean;

function GetConnectedDataBase(const DBName: string): TFIBDatabase;
procedure CloseAllDatabases;
procedure CloseDesignTimeDatabases;
procedure WriteDBParamsToAlias(Database: TFIBDatabase);
// A transaction of the library itself: read committed, nowait, no database events
function CreateInternalTransaction(Database: TFIBDatabase; ReadOnly: Boolean; AOwner: TComponent = nil): TFIBTransaction;

procedure AssignSQLObjectParams(Dest: ISQLObject; ParamSources: array of ISQLObject);

const
  OCTETS_CHARSET_ID      = 1;
  UNICODE_FSS_CHARSET_ID = 3;
  FB_UTF8_CHARSET_ID     = 4;  // Firebird 2.0 and later
  IB_UTF8_CHARSET_ID     = 59; // InterBase 2007 and later

var
  DefDataBase: TFIBDatabase;
  DatabaseList: TThreadList;
  FIBHideGrantError: Boolean = False;

implementation

uses
{$IFNDEF NO_MONITOR}
  FIBSQLMonitor,
{$ENDIF}
{$IFDEF C24}
  System.Types, // for inline funcs
{$ENDIF}
{$IFNDEF NO_REGISTRY}
  RegUtils,
{$ENDIF}
  FIBMiscellaneous, FIBDataInfo, FIBQuery, FIBDataSet, StrUtil, FIBCacheQueries,
  FIBConsts, FIBTypes, FIBCharSets, IB_ErrorCodes;

type
{$IFNDEF NO_MONITOR}
  THackMonitorHook = class(TFIBSQLMonitorHook);
{$ENDIF}

  TFIBTransactionParams = class(TStringList)
  private
    FTransaction: TFIBTransaction;
  protected
    procedure InsertItem(Index: Integer; const S: string; AObject: TObject); override;
    procedure Put(Index: Integer; const S: string); override;
    procedure PutObject(Index: Integer; AObject: TObject); override;
  public
    function AddObject(const S: string; AObject: TObject): Integer; override;
    procedure Clear; override;
    procedure Delete(Index: Integer); override;
    procedure Exchange(Index1, Index2: Integer); override;
    procedure Move(CurIndex, NewIndex: Integer); override;
    procedure CustomSort(Compare: TStringListSortCompare); override;
  end;

var
  vConnectCS: TCriticalSection;
  LastConnectionSerial: Integer = 0;

function NextConnectionSerial: Integer;
begin
  vConnectCS.Acquire;
  try
    Inc(LastConnectionSerial);
    Result := LastConnectionSerial;
  finally
    vConnectCS.Release;
  end;
end;

procedure AssignSQLObjectParams(Dest: ISQLObject; ParamSources: array of ISQLObject);
var
  i: Integer;
  j: NativeInt;
  k: Integer;
  c: Integer;
  pName: string;
  OldValue: Boolean;
begin
  if Dest = nil then
    Exit;
  c := Pred(Dest.ParamCount);
  for i := 0 to c do
    begin
      pName := Dest.ParamName(i);
      OldValue := False;
      if IsNewParamName(pName) then
        pName := FastCopy(pName, 5, MaxInt)
      else if IsOldParamName(pName) then
        begin
          pName := FastCopy(pName, 5, MaxInt);
          OldValue := True;
        end;
      for j := Low(ParamSources) to High(ParamSources) do
        if Assigned(ParamSources[j]) then
          if ParamSources[j].FieldExist(pName, k) then
            begin
              Dest.SetParamValue(i, ParamSources[j].FieldValue(k, OldValue))
            end
          else if ParamSources[j].ParamExist(Dest.ParamName(i), k) then
            begin
              Dest.SetParamValue(i, ParamSources[j].ParamValue(k))
            end;
    end;
end;

function GetConnectedDataBase(const DBName: string): TFIBDatabase;
var
  i: TFIBListIndex;
begin
  Result := nil;
  with DatabaseList.LockList do
    try
      for i := 0 to Count - 1 do
        if (TFIBDatabase(Items[i]).DBName = DBName) and (TFIBDatabase(Items[i]).Connected) then
          begin
            Result := TFIBDatabase(Items[i]);
            Break;
          end;
    finally
      DatabaseList.UnLockList
    end;
end;

procedure CloseAllDatabases;
var
  i: TFIBListIndex;
begin
  with DatabaseList.LockList do
    try
      for i := 0 to Count - 1 do
        begin
          if TFIBDatabase(Items[i]).Connected then
            TFIBDatabase(Items[i]).ForceClose
        end;
    finally
      DatabaseList.UnLockList
    end;
end;

procedure CloseDesignTimeDatabases;
var
  I: TFIBListIndex;
  Database: TFIBDatabase;
begin
  with DatabaseList.LockList do
    try
      for I := 0 to Count - 1 do
      begin
        Database := TFIBDatabase(Items[I]);
        if Database.Connected and (csDesigning in Database.ComponentState) then
          Database.ForceClose;
      end;
    finally
      DatabaseList.UnlockList;
    end;
end;

{$IFNDEF NO_REGISTRY}
procedure WriteDBParamsToAlias(Database: TFIBDatabase);
begin
  with Database do
    DefWriteToRegistry(['Software', RegFIBRoot, 'Aliases', AliasName],
      ['Database Name', DPBConstantNames[isc_dpb_user_name], DPBConstantNames[isc_dpb_lc_ctype],
      DPBConstantNames[isc_dpb_sql_role_name], 'SQL_DIALECT', 'CLIENT_LIB'],
      [DBName, DBParamByDPB[isc_dpb_user_name], DBParamByDPB[isc_dpb_lc_ctype],
      DBParamByDPB[isc_dpb_sql_role_name], IntToStr(SQLDialect), LibraryName]);
end;

{$ELSE}
procedure WriteDBParamsToAlias(Database: TFIBDatabase);
begin

end;
{$ENDIF}

function CreateInternalTransaction(Database: TFIBDatabase; ReadOnly: Boolean; AOwner: TComponent = nil): TFIBTransaction;
const
  Access: array [Boolean] of string = ('write', 'read');
begin
  Result := TFIBTransaction.Create(AOwner);
  try
    Result.Internal := True;
    Result.TPBMode := tpbDefault;
    Result.TRParams.Text := Access[ReadOnly] + #13#10'nowait'#13#10'read_committed'#13#10'rec_version';
    Result.DefaultDatabase := Database;
  except
    Result.Free;
    raise;
  end;
end;

// Distinct datasets, or queries that belong to no dataset, attached to a database or a transaction
procedure CollectAttached(ForObj: TComponent; DataSets: Boolean; List: TList);
var
  i, BaseCount: Integer;
  Base: TFIBBase;
  Item: TComponent;
begin
  if ForObj is TFIBDatabase then
    BaseCount := TFIBDatabase(ForObj).FIBBaseCount
  else
    BaseCount := TFIBTransaction(ForObj).FIBBaseCount;
  for i := 0 to BaseCount - 1 do
  begin
    if ForObj is TFIBDatabase then
      Base := TFIBDatabase(ForObj).FIBBases[i]
    else
      Base := TFIBTransaction(ForObj).FIBBases[i];
    if (Base = nil) or not(Base.Owner is TFIBQuery) then
      Continue;
    Item := TFIBQuery(Base.Owner);
    if (Item.Owner is TFIBCustomDataSet) <> DataSets then
      Continue;
    if DataSets then
      Item := Item.Owner;
    if List.IndexOf(Item) = -1 then
      List.Add(Item);
  end;
end;

function AttachedCount(ForObj: TComponent; DataSets: Boolean): Integer;
var
  List: TList;
begin
  List := TList.Create;
  try
    CollectAttached(ForObj, DataSets, List);
    Result := Integer(List.Count); // at most FIBBaseCount items
  finally
    List.Free;
  end;
end;

function AttachedItem(ForObj: TComponent; DataSets: Boolean; Index: Integer): TComponent;
var
  List: TList;
begin
  Result := nil;
  if Index < 0 then
    Exit;
  List := TList.Create;
  try
    CollectAttached(ForObj, DataSets, List);
    if Index < List.Count then
      Result := TComponent(List[Index]);
  finally
    List.Free;
  end;
end;

// Name of a TRParams line: text before '=', lower case, without isc_tpb_
function TPBLineName(const S: string): string;
var
  P: Integer;
begin
  P := Pos('=', S);
  if P > 0 then
    Result := Copy(S, 1, P - 1)
  else
    Result := S;
  Result := LowerCase(Trim(Result));
  if Pos(TPBPrefix, Result) = 1 then
    Delete(Result, 1, Length(TPBPrefix));
end;

// Access, isolation and wait lines replace the lines of a TPBMode preset instead of extending it
function ReplacesPreset(const S: string): Boolean;
const
  Names: array [0 .. 10] of string = ('read', 'write', 'read_committed', 'rec_version', 'no_rec_version',
    'read_consistency', 'concurrency', 'consistency', 'wait', 'nowait', 'lock_timeout');
var
  Name: string;
  i: Integer;
begin
  Name := TPBLineName(S);
  Result := True;
  for i := Low(Names) to High(Names) do
    if Name = Names[i] then
      Exit;
  Result := False;
end;

function HasParamsLine(Params: TStrings; const Name: string): Boolean;
var
  i: Integer;
begin
  Result := True;
  for i := 0 to Params.Count - 1 do
    if TPBLineName(Params[i]) = Name then
      Exit;
  Result := False;
end;

function TFIBTransactionParams.AddObject(const S: string; AObject: TObject): Integer;
begin
  // here and not only in InsertItem: the result is the index in the emptied list
  if FTransaction.EndPreset and ReplacesPreset(S) then
    inherited Clear;
  Result := inherited AddObject(S, AObject);
end;

procedure TFIBTransactionParams.Clear;
begin
  FTransaction.EndPreset;
  inherited Clear;
end;

procedure TFIBTransactionParams.InsertItem(Index: Integer; const S: string; AObject: TObject);
begin
  if FTransaction.EndPreset and ReplacesPreset(S) then
  begin
    inherited Clear;
    Index := 0;
  end;
  inherited InsertItem(Index, S, AObject);
end;

// The edits below end the preset before they run: inside BeginUpdate/EndUpdate (Move is one)
// OnChange comes too late and a following insert would still see the preset

procedure TFIBTransactionParams.Put(Index: Integer; const S: string);
begin
  FTransaction.EndPreset;
  inherited Put(Index, S);
end;

procedure TFIBTransactionParams.PutObject(Index: Integer; AObject: TObject);
begin
  FTransaction.EndPreset;
  inherited PutObject(Index, AObject);
end;

procedure TFIBTransactionParams.Delete(Index: Integer);
begin
  FTransaction.EndPreset;
  inherited Delete(Index);
end;

procedure TFIBTransactionParams.Exchange(Index1, Index2: Integer);
begin
  FTransaction.EndPreset;
  inherited Exchange(Index1, Index2);
end;

procedure TFIBTransactionParams.Move(CurIndex, NewIndex: Integer);
begin
  FTransaction.EndPreset;
  inherited Move(CurIndex, NewIndex);
end;

procedure TFIBTransactionParams.CustomSort(Compare: TStringListSortCompare);
begin
  FTransaction.EndPreset;
  inherited CustomSort(Compare);
end;

procedure IBFilterBuffer(Database: TFIBDatabase; var BlobBuffer: PAnsiChar;
  var BlobSize: LongInt; BlobSubType: Integer; ForEncode: Boolean);
begin
  if Database.FBlobFilters = nil then
    Exit;
  Database.FBlobFilters.IBFilterBuffer(BlobBuffer, BlobSize, BlobSubType, ForEncode);
end;

function ExistBlobFilter(Database: TFIBDatabase; BlobSubType: Integer): Boolean;
var
  anIndex: Integer;
begin
  if Assigned(Database.FBlobFilters) then
    Result := Database.FBlobFilters.Find(BlobSubType, anIndex)
  else
    Result := False
end;

procedure SaveSchemaToFile(const FileName: string);
begin
  ListTableInfo.SaveToFile(FileName);
  ListDataSetInfo.SaveToFile(ChangeFileExt(FileName, '.dt'));
  ListErrorMessages.SaveToFile(ChangeFileExt(FileName, '.err'));
end;

function LoadSchemaFromFile(const FileName: string; const NeedValidate: Boolean = True; db: TFIBDatabase = nil): Boolean;
begin
  Result := ListTableInfo.LoadFromFile(FileName, db);
  ListTableInfo.NeedValidate := NeedValidate;
  ListDataSetInfo.LoadFromFile(ChangeFileExt(FileName, '.dt'));
  ListDataSetInfo.NeedValidate := NeedValidate;
  ListErrorMessages.LoadFromFile(ChangeFileExt(FileName, '.err'));
end;

{ TFIBDatabaseCapabilities }

constructor TFIBDatabaseCapabilities.Create;
begin
  inherited Create;
  Clear;
end;

procedure TFIBDatabaseCapabilities.Clear;
begin
  FMaxIdentifierLength := 0;
  FSessionTimeouts := False;
  FReadConsistency := False;
  FStatementTimeout := False;
  FAttachmentCharSetID := -1;
end;

procedure TFIBDatabaseCapabilities.Update(Database: TFIBDatabase);
var
  Success, Firebird4: Boolean;
begin
  Firebird4 := Database.IsFirebirdConnect and (Database.ServerMajorVersion >= 4);
  // Firebird 4+ opens only ODS 13+
  if Firebird4 then
    FMaxIdentifierLength := 63
  else
    FMaxIdentifierLength := 31;
  FSessionTimeouts := Firebird4;
  FReadConsistency := Firebird4;
  FStatementTimeout := FSessionTimeouts and Database.ClientLibrary.HasStatementTimeout;
  FAttachmentCharSetID := -1;
  if Database.IsFirebirdConnect then
  begin
    FAttachmentCharSetID := Database.GetProtectLongDBInfo(frb_info_att_charset, Success);
    if not Success then
      FAttachmentCharSetID := -1;
  end;
end;

// After DoOnConnect/CreateDatabase set the Unicode flags
procedure TFIBDatabaseCapabilities.UpdateCodePages(Database: TFIBDatabase);
begin
  FFirebird := Database.FIsFireBirdConnect;
  FBlobsConverted := Database.FIsFireBirdConnect and Database.FIsFB21OrMore;
  FCharSetPerColumn := Database.FIsNoneConnect or
    (FFirebird and (FAttachmentCharSetID < 0) and not Database.FIsUnicodeConnect);
  FUnicodeCharSets := Database.UnicodeCharSets;
  if FAttachmentCharSetID >= 0 then
    FCodePage := FirebirdCharSetCodePage(FAttachmentCharSetID)
  else if StringInArray(Database.ConnectParams.CharSet, ['UTF8', 'UNICODE_FSS']) then
    FCodePage := FIBCodePageUTF8
  else
    FCodePage := FIBCodePageSystem;
  if Database.FNeedUTFDecodeDDL then
    FMetadataCodePage := FIBCodePageUTF8
  else
    FMetadataCodePage := FCodePage;
  // Firebird 2.1-2.5 look the TPB table names up in the UTF-8 metadata unconverted
  if Database.FUTF8Metadata and (Database.ServerMajorVersion < 3) then
    FTPBCodePage := FIBCodePageUTF8
  else
    FTPBCodePage := FMetadataCodePage;
end;

function TFIBDatabaseCapabilities.TextCodePage(CharSetID: Integer): Word;
begin
  // the server converts to the attachment charset, except NONE and OCTETS
  if (CharSetID = 0) or (CharSetID = OCTETS_CHARSET_ID) then
    Result := FIBCodePageSystem
  else if not FCharSetPerColumn then
    Result := FCodePage
  else if FFirebird then
    Result := FirebirdCharSetCodePage(CharSetID)
  else if (CharSetID > 0) and (CharSetID < 256) and (CharSetID in FUnicodeCharSets) then
    Result := FIBCodePageUTF8
  else
    Result := FIBCodePageSystem;
end;

function TFIBDatabaseCapabilities.BlobCodePage(CharSetID: Integer): Word;
begin
  if FBlobsConverted then
    Result := TextCodePage(CharSetID)
  // older servers send the bytes of the column
  else if (CharSetID >= 0) and (CharSetID < 256) and (CharSetID in FUnicodeCharSets) then
    Result := FIBCodePageUTF8
  else
    Result := FIBCodePageSystem;
end;

{ TFIBSession }

constructor TFIBSession.Create(Database: TFIBDatabase);
begin
  inherited Create;
  FDatabase := Database;
end;

function TFIBSession.GetOwner: TPersistent;
begin
  Result := FDatabase;
end;

procedure TFIBSession.Assign(Source: TPersistent);
begin
  if Source is TFIBSession then
  begin
    StatementTimeout := TFIBSession(Source).StatementTimeout;
    IdleTimeout := TFIBSession(Source).IdleTimeout;
  end
  else
    inherited Assign(Source);
end;

// The server is only known while connected; a DFM being loaded is applied later on connect
function TFIBSession.IsLive: Boolean;
begin
  Result := FDatabase.Connected and not (csLoading in FDatabase.ComponentState);
end;

procedure TFIBSession.Execute(const SQL: AnsiString);
var
  NilTransaction: TISC_TR_HANDLE;
begin
  NilTransaction := nil;
  FDatabase.Call(FDatabase.FClientLibrary.isc_dsql_execute_immediate(StatusVector,
    @FDatabase.FHandle, @NilTransaction, 0, PAnsiChar(SQL), Word(FDatabase.SQLDialect), nil), True);
{$IFNDEF NO_MONITOR}
  if MonitoringEnabled then
    if MonitorHook <> nil then
      THackMonitorHook(MonitorHook).WriteSQLData(CmpFullName(FDatabase) + ': [Session] ' + string(SQL), tfQExecute);
{$ENDIF}
  if Assigned(FDatabase.SQLLogger) then
    FDatabase.SQLLogger.WriteData(CmpFullName(FDatabase), 'Session:', string(SQL), lfQExecute);
end;

// Raises before the caller stores the value; sends only when the server supports it
procedure TFIBSession.SendStatementTimeout(Value: Cardinal);
begin
  FDatabase.RequireSessionTimeouts(CmpPropPath(FDatabase, 'Session.StatementTimeout'), Value);
  if FDatabase.Capabilities.SessionTimeouts then
    Execute('SET STATEMENT TIMEOUT ' + AnsiString(IntToStr(Int64(Value))) + ' MILLISECOND');
end;

procedure TFIBSession.SendIdleTimeout(Value: Cardinal);
begin
  FDatabase.RequireSessionTimeouts(CmpPropPath(FDatabase, 'Session.IdleTimeout'), Value);
  // the server would close the IDE's attachment; like TFIBDatabase.Timeout
  if csDesigning in FDatabase.ComponentState then
    Exit;
  if FDatabase.Capabilities.SessionTimeouts then
    Execute('SET SESSION IDLE TIMEOUT ' + AnsiString(IntToStr(Int64(Value))) + ' SECOND');
end;

procedure TFIBSession.SetStatementTimeout(Value: Cardinal);
begin
  if FStatementTimeout = Value then
    Exit;
  if IsLive then
    SendStatementTimeout(Value);
  FStatementTimeout := Value;
end;

procedure TFIBSession.SetIdleTimeout(Value: Cardinal);
begin
  if FIdleTimeout = Value then
    Exit;
  if IsLive then
    SendIdleTimeout(Value);
  FIdleTimeout := Value;
end;

// A new session starts at 0, so zero values cost no round trip
procedure TFIBSession.ApplyOnConnect;
begin
  if FStatementTimeout <> 0 then
    SendStatementTimeout(FStatementTimeout);
  if FIdleTimeout <> 0 then
    SendIdleTimeout(FIdleTimeout);
end;

// Zero values are sent too, so the server ends up exactly at the property values
procedure TFIBSession.Apply;
begin
  if not IsLive then
    Exit;
  SendStatementTimeout(FStatementTimeout);
  SendIdleTimeout(FIdleTimeout);
end;

function TFIBSession.GetActualStatementTimeout: Cardinal;
begin
  Result := 0;
  if FDatabase.Connected and FDatabase.Capabilities.SessionTimeouts then
    Result := Cardinal(FDatabase.GetInt64DBInfo(fb_info_statement_timeout_att));
end;

function TFIBSession.GetActualIdleTimeout: Cardinal;
begin
  Result := 0;
  if FDatabase.Connected and FDatabase.Capabilities.SessionTimeouts then
    Result := Cardinal(FDatabase.GetInt64DBInfo(fb_info_ses_idle_timeout_att));
end;

// TFIBDatabase

constructor TFIBDatabase.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLibraryName := CLIENT_DLL;
  FFIBBases := TList.Create;
  FTransactions := TList.Create;
  FDBParams := TDBParams.Create(Self);
  FDBParamsChanged := True;
  TStringList(FDBParams).OnChange := DBParamsChange;
  TStringList(FDBParams).OnChanging := DBParamsChanging;

{$IFDEF CSMonitor}
  FCSMonitorSupport := TCSMonitorSupport.Create(Self);
{$ENDIF}
  FConnectParams := TConnectParams.Create(Self);
  FCapabilities := TFIBDatabaseCapabilities.Create;
  FSession := TFIBSession.Create(Self);
  FSaveAliasParamsAfterConnect := True;
  FWaitForRestoreConnect := 30000;
  FCacheSchemaOptions := TCacheSchemaOptions.Create;

  if (csDesigning in ComponentState) and not CmpInLoadedState(Self) then
    begin
      FSynchronizeTime := DefSynchronizeTime;
      FUpperOldNames := DefUpperOldNames;
      FUseLoginPrompt := DefUseLoginPrompt;
      FConnectParams.CharSet := DefCharSet;
      FSQLDialect := DefSQLDialect;
      if DefStoreConnected then
        FDesignDBOptions := [ddoStoreConnected]
      else
        FDesignDBOptions := []
    end
  else
    begin
      FSynchronizeTime := True;
      FSQLDialect := 3;
      FDesignDBOptions := [ddoStoreConnected]
    end;

  FInternalTransaction := TFIBTransaction.Create(Self);
  FInternalTransaction.Internal := True;
  FInternalTransaction.TPBMode := tpbDefault;
  FInternalTransaction.DefaultDatabase := Self;
  FInternalTransaction.TimeoutAction := TACommit;
  FInternalTransaction.Timeout := 1000;

  with FInternalTransaction.TRParams do
    begin
      Text := 'write' + #13#10 + 'isc_tpb_nowait' + #13#10 + 'read_committed' + #13#10 + 'rec_version' + #13#10;
    end;
  DatabaseList.Add(Self);
  FAfterConnectEvents := TNotifyEventList.Create(Self);
  FBeforeDisconnectEvents := TNotifyEventList.Create(Self);
  FBeforeDestroyEvents := TNotifyEventList.Create(Self);

  FAttachmentID := 0;
  // FBlobFilters     :=TIBBlobFilters.Create;
  FUseRepositories := [urFieldsInfo, urDataSetInfo, urErrorMessagesInfo];
  FBlobSwapSupport := TBlobSwapSupport.Create;

  FGenerators := TGeneratorsCache.Create(Self);
  FMemoSubtypes := TMemoSubtypes.Create;
end;

destructor TFIBDatabase.Destroy;
var
  i: Integer;
begin
  Connected := False;

{$IFDEF CSMonitor}
  FCSMonitorSupport.Free;
{$ENDIF}
  if Assigned(FTimer) then
    SetTimeout(0);
  // FTimer.Enabled:=False;

  if Assigned(DatabaseList) then
    DatabaseList.Remove(Self);
  if Assigned(FInternalTransaction) then
    with FInternalTransaction do
      begin
        if Active then
          Commit;
        Free;
        FInternalTransaction := nil;
      end;
  if DefDataBase = Self then
    DefDataBase := nil;

  Timeout := 0;
  if FHandle <> nil then
    ForceClose;
  for i := Pred(FBeforeDestroyEvents.Count) downto 0 do
    FBeforeDestroyEvents.Event[i](Self);

  // Tell Dataset's we're being freed.
  for i := FIBBaseCount - 1 downto 0 do
    if FFIBBases[i] <> nil then
      FIBBases[i].FOnDatabaseFree;
  // Make sure that all DataSets are removed from the list.
  RemoveFIBBases;
  // Make sure all transactions are removed from the list.
  // As they are removed, they will remove the db's entry in each
  // respective transaction.
  RemoveTransactions;
  FIBAlloc(FDPB, 0, 0);
  FDBParams.Free;
  FFIBBases.Free;
  FUserNames.Free;
  FTransactions.Free;
  FBackoutCount.Free;
  FDeleteCount.Free;
  FExpungeCount.Free;
  FInsertCount.Free;
  FPurgeCount.Free;
  FReadIdxCount.Free;
  FReadSeqCount.Free;
  FUpdateCount.Free;
  FConnectParams.Free;
  FCapabilities.Free;
  FSession.Free;

  if Assigned(FBlobFilters) then
    FBlobFilters.Free;

  FBlobSwapSupport.Free;
  FGenerators.Free;
  FMemoSubtypes.Free;
  FCryptKeyCallback.Free;
  FClientLibrary := nil;
  FCacheSchemaOptions.Free;
  inherited Destroy;
end;

procedure TFIBDatabase.SetLibraryName(const LibName: string);
begin
  CheckInactive;
  if FLibraryName <> LibName then
    begin
      FLibraryName := LibName;
      FClientLibrary := nil;
      FClientLibLoaded := False;
      // the DPB version depends on the client
      FDBParamsChanged := True;
      { if Length(FLibraryName)>0 then
      LoadLibrary }
    end;
end;

{$IFDEF C23}
function TFIBDatabase.StoredLibraryName64: Boolean;
begin
  Result := Trim(FLibraryName64) <> ''
end;
{$ENDIF}

function TFIBDatabase.StoredLibraryName: Boolean;
begin
  Result := FLibraryName <> CLIENT_DLL
end;

procedure TFIBDatabase.SetGenerators(Value: TGeneratorsCache);
begin
  FGenerators.Assign(Value)
end;

function TFIBDatabase.GetMemoSubtypes: string;
begin
  Result := FMemoSubtypes.Subtypes
end;

procedure TFIBDatabase.SetMemoSubtypes(const Value: string);
begin
  // FMemoSubtypes.Assign(Value);
  FMemoSubtypes.Subtypes := Value
end;

function TFIBDatabase.MemoSubTypesActive: Boolean;
begin
  Result := FMemoSubtypes.Active
end;

function TFIBDatabase.IsMemoSubtype(aSubtype: SmallInt): Boolean;
begin
  Result := FMemoSubtypes.IsMemoSubtype(aSubtype)
end;

function TFIBDatabase.LibraryFilePath: string;
begin
  if Assigned(FClientLibrary) then
    Result := FClientLibrary.LibraryFilePath
  else
    Result := FLibraryName
end;

procedure TFIBDatabase.SetDesignDBOptions(Value: TDesignDBOptions);
begin
  FDesignDBOptions := Value;
  if ddoIsDefaultDatabase in FDesignDBOptions then
    begin
      if (DefDataBase <> nil) and (DefDataBase <> Self) then
        with DefDataBase do
          FDesignDBOptions := FDesignDBOptions - [ddoIsDefaultDatabase];
      if not(csLoading in ComponentState) then
        DefDataBase := Self
    end
  else if DefDataBase = Self then
    DefDataBase := nil
end;

function TFIBDatabase.GetStoreConnected: Boolean;
begin
  Result := Connected and (ddoStoreConnected in FDesignDBOptions)
end;

function TFIBDatabase.Call(ErrCode: ISC_STATUS; RaiseError: Boolean): ISC_STATUS;
begin
  Reset8087CW;
  Result := ErrCode;
  // FCanTimeout := False;
  if Assigned(FTimer) and FTimer.Enabled then
    begin
      FTimer.Enabled := False;
      FTimer.Enabled := True;
      FLastActiveTime := FIBGetTickCount;
    end;
  if RaiseError and (ErrCode > 0) then
    IBError(Self, Self);
end;

procedure TFIBDatabase.CheckActive(TryReconnect: Boolean = False);
var
  OldUseLoginPrompt: Boolean;
begin
  if FStreamedConnected and (not Connected) then
    Loaded;
  if FHandle = nil then
    if not(csDesigning in ComponentState) and not FAutoReconnect then
      begin
        FIBError(feDatabaseClosed, [CmpFullName(Self)])
      end
    else if not Connected and (TryReconnect or FAutoReconnect) then
      begin
        OldUseLoginPrompt := FUseLoginPrompt;
        FUseLoginPrompt := (ConnectParams.Password = '');
        try
          try
            Connected := True;
          except
            // Ask for the login only after a login error, else keep the original error
            on E: Exception do
              begin
                if FUseLoginPrompt or not Assigned(FIBLoginDialog) or not (E is EFIBError) or
                  not EFIBError(E).HasErrorCode(isc_login) then
                  raise;
                FUseLoginPrompt := True;
                Connected := True;
              end;
          end;
        finally
          FUseLoginPrompt := OldUseLoginPrompt;
        end;
      end;
end;

procedure TFIBDatabase.CheckInactive;
begin
  if FHandle <> nil then
    FIBError(feDatabaseOpen, [nil]);
end;

procedure TFIBDatabase.CheckDatabaseName;
begin
  if (FDBName = '') then
    FIBError(feDatabaseNameMissing, [nil]);
end;

{$IFDEF USE_DEPRECATE_METHODS1}
function TFIBDatabase.AddDataSet(ds: TFIBBase): Integer;
begin
  Result := AddFIBBase(ds);
end;
{$ENDIF}

function TFIBDatabase.AddFIBBase(ds: TFIBBase): Integer;
begin
  Result := FIBBaseCount;
  FFIBBases.Add(ds)
end;

procedure TFIBDatabase.RegisterBlobFilter(BlobSubType: Integer; EncodeProc, DecodeProc: PIBBlobFilterProc);
begin
  if not Assigned(FBlobFilters) then
    FBlobFilters := TIBBlobFilters.Create;

  FBlobFilters.RegisterBlobFilter(BlobSubType, EncodeProc, DecodeProc);
end;

procedure TFIBDatabase.RemoveBlobFilter(BlobSubType: Integer);
begin
  if Assigned(FBlobFilters) then
    FBlobFilters.RemoveBlobFilter(BlobSubType)
end;

procedure TFIBDatabase.CreateRestoreConnectTimer;
begin
  if not Assigned(FRestoreConnectTimer) then
  begin
    FRestoreConnectTimer := TFIBTimer.Create(Self);
    FRestoreConnectTimer.Enabled := False;
    FRestoreConnectTimer.Interval := FWaitForRestoreConnect;
    FRestoreConnectTimer.OnTimer := RestoreConnect;
  end;
end;

function TFIBDatabase.GetAfterConnect: TNotifyEvent;
begin
  Result := OnConnect
end;

procedure TFIBDatabase.SetAfterConnect(Method: TNotifyEvent);
begin
  OnConnect := Method
end;

procedure TFIBDatabase.SetAliasName(const Value: string);
begin
  if not(csLoading in ComponentState) then
    CheckInactive;
  FAliasName := Value;
  if FAliasName <> '' then
    ReadParamsFromAlias
end;

procedure TFIBDatabase.SetWaitForRestoreConnect(Value: Cardinal);
begin
  FWaitForRestoreConnect := Value;
  if not Assigned(FRestoreConnectTimer) then
    Exit;
  if Value = 0 then
    StopWaitRestoreConnect
  else
    FRestoreConnectTimer.Interval := Value;
end;

// Alias Works

{$IFNDEF NO_REGISTRY}
function TFIBDatabase.ReadParamsFromAlias: Boolean;
var
  Values: Variant;
  i: Integer;
begin
  Values := DefReadFromRegistry(['Software', RegFIBRoot, 'Aliases', FAliasName],
    ['Database Name', DPBConstantNames[isc_dpb_user_name],
    DPBConstantNames[isc_dpb_lc_ctype], DPBConstantNames[isc_dpb_sql_role_name], 'SQL_DIALECT', 'CLIENT_LIB']);
  Result := VarType(Values) <> varBoolean;
  if not Result then
    Exit; // Don't exist
  for i := 0 to 5 do
  begin
    if Values[1, i] then
      case i of
        0: DBName := Values[0, i];
        1: DBParamByDPB[isc_dpb_user_name] := Values[0, i];
        2: DBParamByDPB[isc_dpb_lc_ctype] := Values[0, i];
        3: DBParamByDPB[isc_dpb_sql_role_name] := Values[0, i];
        4: SQLDialect := Values[0, i];
        5: LibraryName := Values[0, i]
      end
    else if i = 0 then
      Result := False
  end;
end;

{$ELSE}
function TFIBDatabase.ReadParamsFromAlias: Boolean;
begin
  Result := False;
end;
{$ENDIF}

procedure TFIBDatabase.SaveAlias;
begin
  WriteDBParamsToAlias(Self)
end;

procedure TFIBDatabase.ForceCloseTransactions;
var
  i: Integer;
begin
  for i := 0 to TransactionCount - 1 do
  begin
    try
      if FTransactions[i] <> nil then
        Transactions[i].OnDatabaseDisconnecting(Self);
    except
    end;
  end;
end;

procedure TFIBDatabase.AfterOpen;
begin
  StopWaitRestoreConnect;
  if FCacheSchemaOptions.AutoLoadFromFile and not(csDesigning in ComponentState) and
    FileExists(FCacheSchemaOptions.LocalCacheFile) then
    if Assigned(FOnAcceptCacheSchema) and FCacheSchemaOptions.ValidateAfterLoad then
    begin
      if LoadSchemaFromFile(FCacheSchemaOptions.LocalCacheFile, True, Self) then
      begin
        ListTableInfo.ValidateSchema(Self, FOnAcceptCacheSchema);
        SaveSchemaToFile(FCacheSchemaOptions.LocalCacheFile);
      end
    end
    else
    begin
      LoadSchemaFromFile(FCacheSchemaOptions.LocalCacheFile, FCacheSchemaOptions.ValidateAfterLoad, Self);
    end;
  if FSaveAliasParamsAfterConnect and (FAliasName <> '') then
    SaveAlias;
end;

procedure TFIBDatabase.SetCacheSchemaOptions(Value: TCacheSchemaOptions);
begin
  FCacheSchemaOptions.Assign(Value);
end;

// Lost Connection works

function TFIBDatabase.ExTestConnected(Actions: TOnLostConnectActions): Boolean;
var
  DoRaise: Boolean;
begin
  Result := Connected;
  if Result then
  begin
    try
      BaseLevel;
    except
      on E: EFIBError do
      begin
        Result := False;
        DoRaise := False;
        DoOnLostConnect(Self, E, Actions, DoRaise);
        if DoRaise then
          raise
      end
    end;
  end;
end;

procedure TFIBDatabase.DoOnLostConnect(Database: TFIBDatabase; E: EFIBError; var Actions: TOnLostConnectActions; var DoRaise: Boolean);
begin
  if Assigned(FOnLostConnect) then
    FOnLostConnect(Self, E, Actions, DoRaise);
  if Actions = laTerminateApp then
  begin
    CloseLostConnect;
    if CallTerminateProcs then
      TerminateApplication;
    // PostQuitMessage(0); //  Application.Terminate
  end;
  if Actions in [laCloseConnect, laWaitRestore] then
    CloseLostConnect;
  if Actions = laWaitRestore then
    WaitRestoreConnect;
end;

procedure TFIBDatabase.DoOnErrorRestoreConnect(Database: TFIBDatabase; E: EFIBError; var Actions: TOnLostConnectActions);
var
  DoRaise: Boolean;
begin
  DoRaise := False;
  if Assigned(FOnErrorRestoreConnect) then
    FOnErrorRestoreConnect(Self, E, Actions, DoRaise);
end;

procedure TFIBDatabase.DoAfterRestoreConnect;
begin
  if Assigned(FAfterRestoreConnect) then
    FAfterRestoreConnect(Self);
end;

procedure TFIBDatabase.CloseLostConnect;
begin
  // closed already or being closed
  if not Connected or (drsInCloseLostConnect in FDatabaseRunState) then
    Exit;
  Include(FDatabaseRunState, drsInCloseLostConnect);
  try
    // Let's avoid of calls IB Api
    FHandle := nil;
    AbandonServerHandles;
  finally
    Exclude(FDatabaseRunState, drsInCloseLostConnect);
  end;
end;

procedure TFIBDatabase.RestoreConnect(Sender: TObject);
var
  Actions: TOnLostConnectActions;
  Restored: Boolean;
begin
  if Connected then
  begin
    StopWaitRestoreConnect;
    Exit;
  end;
  if Assigned(FRestoreConnectTimer) and FRestoreConnectTimer.Enabled then
  begin
    FRestoreConnectTimer.Enabled := False;
    Actions := laWaitRestore
  end
  else
    Actions := laIgnore;
  Restored := False;
  Include(FDatabaseRunState, drsInRestoreLostConnect);
  try
    try
      Connected := True;
      // BeforeConnect can cancel the connect without an error
      Restored := Connected;
    except
      on E: EFIBError do
        DoOnErrorRestoreConnect(Self, E, Actions);
    end;
  finally
    Exclude(FDatabaseRunState, drsInRestoreLostConnect);
  end;
  if Restored then
    DoAfterRestoreConnect
  else
    case Actions of
      laWaitRestore:
        WaitRestoreConnect;
    else
      // OnLostConnect may have restarted the timer during the attempt
      StopWaitRestoreConnect;
      if (Actions = laTerminateApp) and CallTerminateProcs then
        TerminateApplication;
    end;
end;

procedure TFIBDatabase.WaitRestoreConnect;
begin
  if FWaitForRestoreConnect = 0 then
    Exit;
  CreateRestoreConnectTimer;
  Include(FDatabaseRunState, drsInRestoreLostConnect);
  FRestoreConnectTimer.Enabled := True;
end;

procedure TFIBDatabase.StopWaitRestoreConnect;
begin
  Exclude(FDatabaseRunState, drsInRestoreLostConnect);
  if Assigned(FRestoreConnectTimer) then
    FRestoreConnectTimer.Enabled := False;
end;

function TFIBDatabase.GetInRestoreConnect: Boolean;
begin
  Result := drsInRestoreLostConnect in FDatabaseRunState
end;

function TFIBDatabase.GetFIBDataSet(Index: Integer): TDataSet;
begin
  Result := TDataSet(AttachedItem(Self, True, Index))
end;

function TFIBDatabase.FIBDataSetsCount: Integer;
begin
  Result := AttachedCount(Self, True)
end;

procedure TFIBDatabase.GetTableNames(TableNames: TStrings; WithSystem: Boolean);
const
  TablesSQL = 'Select RDB$RELATION_NAME from RDB$RELATIONS ' +
    'where RDB$VIEW_BLR is NULL @SYS ' + 'ORDER BY RDB$RELATION_NAME';
var
  qry: TFIBQuery;
begin
  CheckActive;
  qry := GetQueryForUse(FInternalTransaction, TablesSQL);
  TableNames.Clear;
  with qry do
    try
      Close;
      Options := [qoStartTransaction, qoTrimCharFields];
      TableNames.BeginUpdate;
      if not WithSystem then
        Params[0].asString := 'and RDB$SYSTEM_FLAG = 0'
      else
        Params[0].asString := '';
      ExecQuery;
      while not Eof do
      begin
        TableNames.Add(Fields[0].asString);
        Next;
      end;
    finally
      if FInternalTransaction.Active then
        FInternalTransaction.Commit;
      TableNames.EndUpdate;
      qry.FreeHandle;
      FreeQueryForUse(qry);
    end;
end;

procedure TFIBDatabase.GetFieldNames(const TableName: string; FieldNames: TStrings; WithComputedFields: Boolean = True);
const
  cFieldsSQL = 'Select RDB$FIELD_NAME  from RDB$RELATION_FIELDS R ' +
    'where R.RDB$RELATION_NAME = :TN ORDER BY R.RDB$FIELD_POSITION ';

  cFieldsSQL1 = 'Select R.RDB$FIELD_NAME  from  RDB$RELATION_FIELDS R ' +
    'join rdb$fields R2 on (R.RDB$FIELD_SOURCE = R2.RDB$FIELD_NAME) ' +
    'where R.RDB$RELATION_NAME = :TN AND R2.RDB$COMPUTED_SOURCE IS NULL ORDER BY R.RDB$FIELD_POSITION';

var
  qry: TFIBQuery;
  FieldsSQL: string;
begin
  CheckActive;
  if WithComputedFields then
    FieldsSQL := cFieldsSQL
  else
    FieldsSQL := cFieldsSQL1;

  qry := GetQueryForUse(FInternalTransaction, FieldsSQL);
  FieldNames.Clear;
  with qry do
    try
      Close;
      Options := [qoStartTransaction, qoTrimCharFields];
      FieldNames.BeginUpdate;
      if SQLDialect = 1 then
        Params[0].asString := UpperCase(TableName)
      else
        Params[0].asString := TableName;

      // Params[0].asString:=FormatIdentifier(SQLDialect, TableName);
      ExecQuery;
      while not Eof do
      begin
        FieldNames.Add(Fields[0].asString);
        Next;
      end;
    finally
      if FInternalTransaction.Active then
        FInternalTransaction.Commit;
      FieldNames.EndUpdate;
      qry.FreeHandle;
      FreeQueryForUse(qry);
    end;
end;

procedure TFIBDatabase.CloseDataSets;
var
  Index: Integer;
begin
  for Index := FIBBaseCount - 1 downto 0 do
    if FIBBases[Index] <> nil then
      if (FIBBases[Index].Owner is TFIBDataSet) then
        TFIBDataSet(FIBBases[Index].Owner).Close;
end;

function TFIBDatabase.FIBQueryCount: Integer;
begin
  Result := AttachedCount(Self, False);
end;

function TFIBDatabase.GetFIBQuery(Index: Integer): TComponent;
begin
  Result := AttachedItem(Self, False, Index);
end;

procedure TFIBDatabase.ApplyUpdates(const DataSets: array of TDataSet);
var
  i: NativeInt;
  DS: TFIBCustomDataSet;
  TR: TFIBTransaction;
begin
  if Length(DataSets) = 0 then
    Exit;
  TR := nil;
  for i := 0 to High(DataSets) do
  begin
    if not (DataSets[i] is TFIBCustomDataSet) then
      FIBError(feUpdateWrongDB, [CmpFullName(DataSets[i])]);
    DS := TFIBCustomDataSet(DataSets[i]);
    if DS.Database <> Self then
      FIBError(feUpdateWrongDB, [CmpFullName(DS)]);
    if i = 0 then
      TR := DS.UpdateTransaction;
    if (TR = nil) or (DS.UpdateTransaction <> TR) then
      FIBError(feUpdateWrongTR, [CmpFullName(DS)]);
  end;
  TR.EnsureInTransaction;
  for i := 0 to High(DataSets) do
    if DataSets[i] is TFIBCustomDataSet then
      TFIBCustomDataSet(DataSets[i]).ApplyUpdToBase;
  if TR.TimeoutAction = TACommitRetaining then
    TR.CommitRetaining
  else
    TR.Commit;
  for i := 0 to High(DataSets) do
    if (DataSets[i] is TFIBCustomDataSet) and (DataSets[i].Active) then
      TFIBCustomDataSet(DataSets[i]).CommitUpdToCach;
end;

function TFIBDatabase.GetFIBVersion: string;
begin
  Result := FIBVersionString;
end;

procedure TFIBDatabase.SetFIBVersion(const Value: string);
begin

end;

procedure TFIBDatabase.ReadSaveDBParams(Reader: TReader);
begin
  SaveAliasParamsAfterConnect := Reader.ReadBoolean;
end;

procedure TFIBDatabase.DefineProperties(Filer: TFiler);
begin
  inherited;
  if Filer is TReader then
  begin
    // For oldest dfm
    Filer.DefineProperty('SaveDBParams', ReadSaveDBParams, nil, False);
  end;
end;

procedure TFIBDatabase.IBFilterBuffer(var BlobBuffer: PAnsiChar; var BlobSize: LongInt; BlobSubType: Integer; ForEncode: Boolean);
begin
  if Assigned(FBlobFilters) then
    FBlobFilters.IBFilterBuffer(BlobBuffer, BlobSize, BlobSubType, ForEncode);
end;

procedure TFIBDatabase.RemoveEvent(Event: TNotifyEvent; EventType: TFIBDatabaseEventType);
begin
  case EventType of
    detOnConnect: FAfterConnectEvents.Remove(Event);
    detBeforeDisconnect: FBeforeDisconnectEvents.Remove(Event);
    detBeforeDestroy: FBeforeDestroyEvents.Remove(Event);
  end;
end;

procedure TFIBDatabase.AddEvent(Event: TNotifyEvent; EventType: TFIBDatabaseEventType);
begin
  case EventType of
    detOnConnect: FAfterConnectEvents.Add(Event);
    detBeforeDisconnect: FBeforeDisconnectEvents.Add(Event);
    detBeforeDestroy: FBeforeDestroyEvents.Add(Event);
  end
end;

procedure TFIBDatabase.DoBeforeDisconnect;
var
  i: Integer;
begin
  try
    if Assigned(FBeforeDisconnect) then
      FBeforeDisconnect(Self);
  except
    on E: Exception do
      if csDestroying in ComponentState then
        raise Exception.Create(Format(SFIBErrorBeforeDisconnectDetail, [CmpFullName(Self), E.Message]))
      else
        raise Exception.Create(Format(SFIBErrorBeforeDisconnect, [CmpFullName(Self), E.Message]))
  end;

  with FBeforeDisconnectEvents do
    for i := 0 to Pred(Count) do
      begin
        FBeforeDisconnectEvents.Event[i](Self)
      end;
end;

procedure TFIBDatabase.DoAfterDisconnect;
begin
  try
    if Assigned(FAfterDisconnect) then
      FAfterDisconnect(Self);
  except
    on E: Exception do
      if csDestroying in ComponentState then
        raise Exception.Create(Format(SFIBErrorAfterDisconnectDetail, [CmpFullName(Self), E.Message]))
      else
        raise Exception.Create(Format(SFIBErrorAfterDisconnect, [CmpFullName(Self), E.Message]))
  end;
end;

// Reads the server and sends the Session values; on an error the new attachment is
// dropped without disconnect events, like a failed attach
procedure TFIBDatabase.InitAttachment;
begin
  FIsFireBirdConnect := GetIsFirebirdConnect;
  FCapabilities.Update(Self);
  try
    FSession.ApplyOnConnect;
  except
    DropAttachment;
    raise;
  end;
end;

procedure TFIBDatabase.DropAttachment;
var
  Status: TStatusVector;
begin
  // own status vector: the one being raised must stay intact
  if not FHandleIsShared then
    FClientLibrary.isc_detach_database(PISC_STATUS(@Status), @FHandle);
  FHandle := nil;
  FHandleIsShared := False;
  FCapabilities.Clear;
end;

procedure TFIBDatabase.DoOnConnect;
var
  i: Integer;
  vMajorVersion: Integer;
begin
  vMajorVersion := ServerMajorVersion;
  if not FIsFireBirdConnect then
    FIsIB2007Connect := vMajorVersion >= 8;

  if not FIsFireBirdConnect or (vMajorVersion < 2) then
    begin
      FIsUnicodeConnect := (FConnectParams.CharSet = 'UNICODE_FSS') or (FConnectParams.CharSet = 'UTF8');
      FIsNoneConnect := (FConnectParams.CharSet = 'NONE') or (FConnectParams.CharSet = '');
      FNeedUnicodeFieldsTranslation := FIsUnicodeConnect or FIsNoneConnect;
      FNeedUTFDecodeDDL := False;
      FIsFB21OrMore := False;
      FUTF8Metadata := False;
    end
  else
    begin
      FIsUnicodeConnect := (FCapabilities.AttachmentCharSetID >= 0) and
        (FCapabilities.AttachmentCharSetID in UnicodeCharSets);
      FIsNoneConnect := FCapabilities.AttachmentCharSetID = 0;
      FNeedUnicodeFieldsTranslation := FIsUnicodeConnect or FIsNoneConnect;

      FIsFB21OrMore := (vMajorVersion > 2) or ((vMajorVersion = 2) and (GetServerMinorVersion >= 1));
      FUTF8Metadata := ReadUTF8Metadata;
      FNeedUTFDecodeDDL := FNeedUnicodeFieldsTranslation and FUTF8Metadata;
    end;
  FCapabilities.UpdateCodePages(Self);

  if not(csDesigning in ComponentState) then
    if FBlobSwapSupport.Active and FBlobSwapSupport.AutoValidateSwap and
      (Length(FBlobSwapSupport.SwapDirectory) > 0) then
      ValidateBlobCacheDirectory(Self);

  if Assigned(FOnConnect) then
    FOnConnect(Self);
  with FAfterConnectEvents do
    for i := 0 to Pred(Count) do
      begin
        if not Connected then
          Break;
        FAfterConnectEvents.Event[i](Self)
      end;
end;

function TFIBDatabase.AddTransaction(TR: TFIBTransaction): Integer;
begin
  Result := 0;
  while (Result < FTransactions.Count) and (FTransactions[Result] <> nil) and
    (FTransactions[Result] <> TR) // AddedSource
  do
    Inc(Result);
  if (Result = FTransactions.Count) then
    FTransactions.Add(TR)
  else
    FTransactions[Result] := TR;
end;

procedure TFIBDatabase.Close;
begin
  if Connected then
    InternalClose(False);
  FInternalTransaction.Timeout := 0;
end;

procedure TFIBDatabase.CreateDatabase;
var
  tr_handle: TISC_TR_HANDLE;
  Statement: AnsiString;
begin
  // Create database interprets the DBParams string list
  // as mere text. It makes it extremely simple to do this way.
  CheckInactive; // Make sure the database ain't connected.
  FAttachmentID := 0;
  LoadLibrary;
  tr_handle := nil;
  // The client reads the statement in the system code page: it has no utf8_filename
  Statement := 'CREATE DATABASE ' + EncodeParam('DBName', QuotedStr(FDBName), FIBCodePageSystem) + ' ' +
    EncodeParam('DBParams', DBParams.Text, FIBCodePageSystem);
  Call(FClientLibrary.isc_dsql_execute_immediate(StatusVector, @FHandle,
    @tr_handle, 0, PAnsiChar(Statement), Word(SQLDialect), nil), True);
  FConnectionSerial := NextConnectionSerial;

  FServerMajorVersion := -1;
  FServerMinorVersion := -1;
  FServerBuild := -1;

  InitAttachment;
  FIsFB21OrMore := False;
  FUTF8Metadata := False;
  if FIsFireBirdConnect and (ServerMajorVersion >= 2) then
    begin
      FIsUnicodeConnect := (FCapabilities.AttachmentCharSetID >= 0) and
        (FCapabilities.AttachmentCharSetID in UnicodeCharSets);
      FIsNoneConnect := FCapabilities.AttachmentCharSetID = 0;
      FNeedUnicodeFieldsTranslation := FIsUnicodeConnect or FIsNoneConnect;
      FIsFB21OrMore := (GetServerMajorVersion > 2) or ((GetServerMajorVersion = 2) and (GetServerMinorVersion >= 1));
      FUTF8Metadata := ReadUTF8Metadata;
      FNeedUTFDecodeDDL := FNeedUnicodeFieldsTranslation and FUTF8Metadata;
    end;
  FCapabilities.UpdateCodePages(Self);
end;

procedure TFIBDatabase.DropDatabase;
begin
  CheckActive;
  LoadLibrary;
  Call(FClientLibrary.isc_drop_database(StatusVector, @FHandle), True);
  FHandle := nil;
  FCapabilities.Clear;
end;

// Set up the FDPBBuffer correctly.
procedure TFIBDatabase.DBParamsChange(Sender: TObject);
begin
  FDBParamsChanged := True;
end;

procedure TFIBDatabase.DBParamsChanging(Sender: TObject);
begin
  if not(csDesigning in ComponentState) then
    CheckInactive;
end;

function TFIBDatabase.FindTransaction(TR: TFIBTransaction): Integer;
begin
  Result := Integer(FTransactions.IndexOf(TR));
end;

procedure TFIBDatabase.ForceClose;
begin
  InternalClose(True);
end;

function TFIBDatabase.GetConnected: Boolean;
begin
  Result := FHandle <> nil;
end;

function TFIBDatabase.GetDatabaseName: string;
begin
  Result := FDBName;
end;

function TFIBDatabase.GetFIBBase(Index: Integer): TFIBBase;
begin
  Result := FFIBBases[Index];
end;

function TFIBDatabase.GetFIBBasesCount: Integer;
begin
  Result := Integer(FFIBBases.Count);
end;

function TFIBDatabase.GetDBParamByDPB(const Idx: Integer): string;
var
  ConstIdx, EqualsIdx: Integer;
  ConstName: string;
begin
  ConstName := DPBConstantName(Idx);
  if ConstName <> '' then
    begin
      ConstIdx := IndexOfDBConst(ConstName);
      if ConstIdx = -1 then
        Result := ''
      else
        begin
          Result := DBParams[ConstIdx];
          EqualsIdx := PosCh('=', Result);
          if EqualsIdx = 0 then
            Result := ''
          else
            Result := FastCopy(Result, EqualsIdx + 1, Length(Result));
        end;
    end
  else
    Result := '';
end;

function TFIBDatabase.FindConfigParam(const Name: string; out Value: string): Integer;
var
  i, EqualsIdx: Integer;
  S, ParName: string;
begin
  for i := 0 to DBParams.Count - 1 do
    begin
      S := Trim(DBParams[i]);
      EqualsIdx := PosCh('=', S);
      if EqualsIdx = 0 then
        Continue;
      ParName := FastCopy(S, 1, EqualsIdx - 1);
      if not SameText(ParName, 'config') and not SameText(ParName, DPBPrefix + 'config') then
        Continue;
      S := FastCopy(S, EqualsIdx + 1, Length(S));
      EqualsIdx := PosCh('=', S);
      if (EqualsIdx > 0) and SameText(Trim(FastCopy(S, 1, EqualsIdx - 1)), Name) then
        begin
          Value := Trim(FastCopy(S, EqualsIdx + 1, Length(S)));
          Result := i;
          Exit;
        end;
    end;
  Value := '';
  Result := -1;
end;

function TFIBDatabase.GetConfigParam(const Name: string): string;
begin
  FindConfigParam(Name, Result);
end;

function TFIBDatabase.GetTimeout: Cardinal;
begin
  if Assigned(FTimer) then
    Result := FTimer.Interval
  else
    Result := 0;
end;

function TFIBDatabase.GetTransaction(Index: Integer): TFIBTransaction;
begin
  Result := FTransactions[Index];
end;

function TFIBDatabase.GetTransactionCount: Integer;
begin
  Result := Integer(FTransactions.Count);
end;

function TFIBDatabase.GetActiveTransactionCount: Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to TransactionCount - 1 do
    if (FTransactions[i] <> nil) and TFIBTransaction(FTransactions[i]).InTransaction then
      Inc(Result);
end;

function TFIBDatabase.GetFirstActiveTransaction: TFIBTransaction;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to TransactionCount - 1 do
    if (FTransactions[i] <> nil) and TFIBTransaction(FTransactions[i])
      .InTransaction and ((TFIBTransaction(FTransactions[i]).DatabaseCount < 2)
      or (TFIBTransaction(FTransactions[i]).DefaultDatabase = Self)) then
      begin
        Result := TFIBTransaction(FTransactions[i]);
        Exit;
      end;
end;

function TFIBDatabase.IndexOfDBConst(const st: string): Integer;
var
  i, pos_of_str: Integer;
begin
  Result := -1;
  for i := 0 to DBParams.Count - 1 do
    begin
      pos_of_str := PosCI(st, DBParams[i]);
      if (pos_of_str = 1) or (pos_of_str = Length(DPBPrefix) + 1) then
        begin
          Result := i;
          Break;
        end;
    end;
end;

(*
  * InternalClose -
  *  Close the database connection and all other
  *  attached components that the database
  *  connection is terminating.
  *  DBinShutDown: the attachment is dead, calls on it would reach the error
  *  handler and close again (#24), so handles are only forgotten.
*)
procedure TFIBDatabase.InternalClose(Force: Boolean; DBinShutDown: Boolean);
var
  i: Integer;
  OldRunState: TDatabaseRunState;
begin
  if not Connected then
    Exit;
  // the error handler may close again while closing
  if drsInClose in FDatabaseRunState then
    Exit;
  if FCacheSchemaOptions.AutoSaveToFile and not(csDesigning in ComponentState) then
    SaveSchemaToFile(FCacheSchemaOptions.LocalCacheFile);
  (*
    * Check that the database connection is active.
  *)
  CheckActive;
  if DBinShutDown then
    Force := True;
  OldRunState := FDatabaseRunState;
  Include(FDatabaseRunState, drsInClose);
  if DBinShutDown then
    Include(FDatabaseRunState, drsInCloseLostConnect);
  try
    DoBeforeDisconnect;
    if DBinShutDown then
      AbandonServerHandles;
    (*
      * Tell all connected transactions that we're disconnecting.
      * This is so transactions can commit/rollback, accordingly
    *)

    for i := 0 to TransactionCount - 1 do
      try
        if FTransactions[i] <> nil then
          Transactions[i].OnDatabaseDisconnecting(Self);
      except
        if not Force then
          raise;
      end;

    (*
      * Tell all attached components (TFIBBase's) that we're
      * disconnecting
    *)
    for i := 0 to FIBBaseCount - 1 do
      try
        if FFIBBases[i] <> nil then
          FIBBases[i].FOnDatabaseDisconnecting;
      except
        if not Force then
          raise;
      end;

    (*
      * Disconnect..., and if the force parameter is true, guarantee that
      * the handle is reset to nil. A dead attachment is detached too, to
      * release the client resources.
    *)

    try
      if (not HandleIsShared) and (Call(FClientLibrary.isc_detach_database(StatusVector, @FHandle),
        not Force) > 0) and (not Force) then
        IBError(Self, Self)
      else
        begin
          FHandle := nil;
          FHandleIsShared := False;
        end;
    except
      FHandle := nil;
      FHandleIsShared := False;
    end;

{$IFNDEF NO_MONITOR}
    if MonitoringEnabled then
      if MonitorHook <> nil then
        MonitorHook.DBDisconnect(Self);
{$ENDIF}
    (*
      * Tell all attached components (TFIBBase's) that we have
      * disconnected.
    *)
    for i := 0 to FIBBaseCount - 1 do
      if FFIBBases[i] <> nil then
        FIBBases[i].FOnDatabaseDisconnected;
    FCapabilities.Clear;
    DoAfterDisconnect;
    if Assigned(FSQLLogger) then
      FSQLLogger.WriteData(CmpFullName(Self), 'Disconnect', '', lfConnect);
  finally
    // only own states: the error handler may have started a restore
    if not(drsInCloseLostConnect in OldRunState) then
      Exclude(FDatabaseRunState, drsInCloseLostConnect);
    Exclude(FDatabaseRunState, drsInClose);
  end;
end;

(*
  * AbandonServerHandles -
  *  Forget the handles of a dead attachment without calling the API.
  *  Statements first, so that datasets notified by the transaction end
  *  don't fetch from it.
*)
procedure TFIBDatabase.AbandonServerHandles;
var
  i: Integer;
begin
  for i := 0 to FIBBaseCount - 1 do
    try
      if FFIBBases[i] <> nil then
        FIBBases[i].FOnDatabaseConnectionLost;
    except
    end;
  for i := 0 to TransactionCount - 1 do
    if (FTransactions[i] <> nil) and Transactions[i].InTransaction then
      with Transactions[i] do
        try
          // a shared handle is only forgotten by EndTransaction
          FHandleIsShared := True;
          EndTransaction(TARollback, True);
        except
          FHandle := nil;
          FHandleIsShared := False;
          FState := tsClosed;
        end;
end;

{$IFDEF CSMonitor}
procedure TFIBDatabase.SetCSMonitorSupport(Value: TCSMonitorSupport);
begin
  FCSMonitorSupport.Assign(Value)
end;
{$ENDIF}

procedure TFIBDatabase.Loaded;
begin
  inherited Loaded;
  if ddoIsDefaultDatabase in FDesignDBOptions then
    DefDataBase := Self;
  try
    FInternalTransaction.Name := Name + '_InternalTransaction';
    if FStreamedConnected and (not Connected) then
      begin
        FStreamedConnected := False;
        Open;
        if Connected then
          if (FDefaultTransaction <> nil) and (FDefaultTransaction.FStreamedActive) and
            (not FDefaultTransaction.InTransaction) then
            FDefaultTransaction.StartTransaction;
      end;
  except
    on E: Exception do
      begin
        if not(csDesigning in ComponentState) then
          raise
        else
          begin
            FStreammedConnectFail := True;
            ShowException(E, nil);
          end;
      end;
  end;
end;

function TFIBDatabase.Login: Boolean;
var
  IndexOfUser, IndexOfPassword, IndexOfRole: Integer;
  Username, Password, RoleName: string;
  XDBName: string;
begin
  if not Assigned(FIBLoginDialog) then
    begin
      if not Assigned(FIBLoginDialog) then
        if csDesigning in ComponentState then
          raise Exception.Create(SFIBErrorNoDBLoginDialog + SFIBErrorInstallPropertyEditorPackage)
        else
          raise Exception.Create(SFIBErrorNoDBLoginDialog + SFIBErrorIncludeDBLoginDialog);
    end;

  IndexOfUser := IndexOfDBConst(DPBConstantNames[isc_dpb_user_name]);
  if IndexOfUser <> -1 then
    Username := FastCopy(DBParams[IndexOfUser], PosCh('=', DBParams[IndexOfUser]) + 1, Length(DBParams[IndexOfUser]));
  IndexOfPassword := IndexOfDBConst(DPBConstantNames[isc_dpb_password]);
  if IndexOfPassword <> -1 then
    Password := FastCopy(DBParams[IndexOfPassword], PosCh('=', DBParams[IndexOfPassword]) + 1,
      Length(DBParams[IndexOfPassword]));
  IndexOfRole := IndexOfDBConst(DPBConstantNames[isc_dpb_sql_role_name]);
  if IndexOfRole <> -1 then
    RoleName := FastCopy(DBParams[IndexOfRole], PosCh('=', DBParams[IndexOfRole]) + 1, Length(DBParams[IndexOfRole]));
  XDBName := DBName;

  Result := FIBLoginDialog(XDBName, Username, Password, RoleName);
  if Result then
    begin
      if IndexOfUser = -1 then
        DBParams.Add(DPBConstantNames[isc_dpb_user_name] + '=' + Username)
      else
        DBParams[IndexOfUser] := DPBConstantNames[isc_dpb_user_name] + '=' + Username;
      if IndexOfPassword = -1 then
        DBParams.Add(DPBConstantNames[isc_dpb_password] + '=' + Password)
      else
        DBParams[IndexOfPassword] := DPBConstantNames[isc_dpb_password] + '=' + Password;
      if IndexOfRole = -1 then
        DBParams.Add(DPBConstantNames[isc_dpb_sql_role_name] + '=' + RoleName)
      else
        DBParams[IndexOfRole] := DPBConstantNames[isc_dpb_sql_role_name] + '=' + RoleName;
    end;
end;

procedure TFIBDatabase.Online;
var
  oldParams, u, p: string;
begin
  oldParams := DBParams.Text;
  try
    u := ConnectParams.Username;
    p := ConnectParams.Password;
    if Connected then
      Close;
    DBParams.Clear;
    ConnectParams.Username := u;
    ConnectParams.Password := p;
    DBParams.Add('online');
    Open;
    Close;
  finally
    DBParams.Text := oldParams;
  end;
end;

procedure TFIBDatabase.ShutDown(const ShutParams: array of Integer; Delay: Integer = 0);
var
  oldParams, u, p: string;
  i: NativeInt;
begin
  { Valid values of ShutParams:
    ibase.pas

    isc_dpb_shut_cache             =          1;
    isc_dpb_shut_attachment        =          2;
    isc_dpb_shut_transaction       =          4;
    isc_dpb_shut_force             =          8;

    //FB 2.0 shutdown attachment

    isc_dpb_shut_mode_mask=$70;

    isc_dpb_shut_default=$0;
    isc_dpb_shut_normal = $10;
    isc_dpb_shut_multi = $20;
    isc_dpb_shut_single = $30;
    isc_dpb_shut_full = $40;
  }
  oldParams := DBParams.Text;
  try
    u := ConnectParams.Username;
    p := ConnectParams.Password;
    if Connected then
      Close;
    DBParams.Clear;
    ConnectParams.Username := u;
    ConnectParams.Password := p;
    if Length(ShutParams) = 0 then
      DBParams.Add('shutdown')
    else
      begin
        u := 'shutdown=';
        for i := 0 to High(ShutParams) do
          u := u + IntToStr(ShutParams[i]) + ',';
        SetLength(u, Length(u) - 1);
        DBParams.Add(u);
      end;
    if Delay > 0 then
      DBParams.Add('shutdown_delay=' + IntToStr(Delay));
    Open;
    Close;
  finally
    DBParams.Text := oldParams;
  end;
end;

(*
  * Open -
  *  Open a database connection.
*)

procedure TFIBDatabase.Open(RaiseExcept: Boolean = True);
const
  S_OK = 0;

var
  DPB: AnsiString;
  isc_res: ISC_STATUS;
  i: Integer;
  SV: PISC_STATUS;
  UseCryptKey: Boolean;
  DoConnect: Boolean;
  AttachName: AnsiString;
  UTF8Name: UTF8String;
begin
  if Connected then
    Exit;
  DoConnect := True;
  if Assigned(FBeforeConnect) then
    FBeforeConnect(Self, DBParams, DoConnect);
  if not DoConnect then
    Exit;
  // isc_res:=0;
  (*
    * Check that the database is *not* active, and that it
    * has a database name
  *)
  FServerMajorVersion := -1;
  FServerMinorVersion := -1;
  FServerBuild := -1;
  vConnectCS.Acquire;
  // EnterCriticalSection(vConnectCS);
  try
    CheckInactive;
    FAttachmentID := 0;
    CheckDatabaseName;
    LoadLibrary;
    (*
      * Use the canned login prompt if requested.
    *)
    for i := 0 to FIBBaseCount - 1 do
      begin
        if FFIBBases[i] <> nil then
          FIBBases[i].FOnDatabaseConnecting;
      end;

    if FUseLoginPrompt and not Login then
      FIBError(feOperationCancelled, [nil]);
    (*
      * Generate a new DPB if necessary
    *)
    if FDBParamsChanged then
      begin
        FDBParamsChanged := False;
        // without sql_dialect the server takes dialect 1 and uppercases a quoted role name
        GenerateDPB(FDBParams, DPB, FDPBLength, FConnectParams.IsFirebird, FSQLDialect,
          (FClientLibrary.Version.Product = fpFirebird) and (FClientLibrary.Version.Major >= 3));
        FIBAlloc(FDPB, 0, FDPBLength);
        Move(DPB[1], FDPB[0], FDPBLength);
      end;
    (*
      * Attach to the database, and raise an IB error if
      * the statement doesn't execute correctly.
    *)
    if DPBUsesUTF8(FDBParams, FConnectParams.IsFirebird) then
      begin
        UTF8Name := UTF8Encode(FDBName);
        SetString(AttachName, PAnsiChar(UTF8Name), Length(UTF8Name));
      end
    else
      AttachName := EncodeParam('DBName', FDBName, FIBCodePageSystem);
    SV := StatusVector;
    // The crypt callback is per thread, set only around this attachment
    UseCryptKey := (FCryptKey <> '') or Assigned(FOnCryptKeyRequest);
    if UseCryptKey then
      begin
        if FCryptKeyCallback = nil then
          FCryptKeyCallback := TFIBCryptKeyCallback.Create(Self, DoCryptKeyRequest);
        Call(FCryptKeyCallback.Activate(FClientLibrary, SV), True);
      end;
    try
      // length 0: null terminated
      isc_res := Call(FClientLibrary.isc_attach_database(SV, 0,
        PAnsiChar(AttachName), @FHandle, FDPBLength, FDPB), False);
    finally
      if UseCryptKey then
        FCryptKeyCallback.Deactivate(FClientLibrary);
    end;
  finally
    vConnectCS.Release
    // LeaveCriticalSection(vConnectCS);
  end;

  if isc_res > 0 then
    begin
      FHandle := nil;
      if RaiseExcept then
        begin
          // More precise than the server's "missing crypt key"
          if UseCryptKey then
            FCryptKeyCallback.RaiseRequestError;
          IBError(Self, Self);
        end
      else
        Exit;
    end;
  // the Session SQL runs in the dialect of the database
  if DBSQLDialect < SQLDialect then
    FSQLDialect := DBSQLDialect;
  try
    InitAttachment;
  except
    if RaiseExcept then
      raise;
    // a failed init can leave the attachment open
    if Connected then
      AfterOpen;
    Exit;
  end;
  FConnectionSerial := NextConnectionSerial;
  FInternalTransaction.Timeout := 1000;
  FStreammedConnectFail := False;
  AttachmentID;

{$IFNDEF NO_MONITOR}
  if MonitoringEnabled then
    if MonitorHook <> nil then
      MonitorHook.DBConnect(Self);
{$ENDIF}
  FDifferenceTime := 0;
  if FSynchronizeTime and not(csDesigning in ComponentState) then
    FDifferenceTime := Now - GetServerTime;
  FConnectType := 0;
  DoOnConnect;
  for i := 0 to FIBBaseCount - 1 do
    begin
      if not Connected then
        Break;
      FIBBases[i].FOnDatabaseConnected;
    end;
  if Assigned(FSQLLogger) then
    FSQLLogger.WriteData(CmpFullName(Self), 'Connect', '', lfConnect);
  if Connected then
    AfterOpen;
end;

procedure TFIBDatabase.DoCryptKeyRequest(Sender: TObject; const Data: FIBByteString; var Key: FIBByteString);
begin
  Key := FCryptKey;
  if Assigned(FOnCryptKeyRequest) then
    FOnCryptKeyRequest(Self, Data, Key);
end;

function TFIBDatabase.GetServerTime: TDateTime;
begin
  if FSQLDialect < 2 then
    Result := QueryValue('SELECT CAST(''NOW'' AS DATE) from RDB$DATABASE', 0)
  else
    Result := QueryValue
      ('SELECT CAST(''NOW'' AS TIMESTAMP) from RDB$DATABASE', 0)
end;

{$IFDEF USE_DEPRECATE_METHODS1}
procedure TFIBDatabase.RemoveDataSet(Idx: Integer);
begin
  RemoveFIBBase(Idx);
end;
{$ENDIF}

procedure TFIBDatabase.RemoveFIBBase(Idx: Integer);
var
  ds: TFIBBase;
begin
  if (Idx >= 0) and (FFIBBases[Idx] <> nil) then
    begin
      ds := FIBBases[Idx];
      ds.FDatabase := nil;
      if Idx < FFIBBases.Count - 1 then
        begin
          ds := FFIBBases[FFIBBases.Count - 1];
          FFIBBases[Idx] := ds;
          ds.FIndexInDatabase := Idx;
          FFIBBases.Delete(FFIBBases.Count - 1);
        end
      else
        FFIBBases.Delete(Idx);
    end;
end;
{$IFDEF USE_DEPRECATE_METHODS1}
procedure TFIBDatabase.RemoveDataSets;
begin
  RemoveFIBBases
end;
{$ENDIF}

procedure TFIBDatabase.RemoveFIBBases;
var
  i: Integer;
begin
  for i := FIBBaseCount - 1 downto 0 do
    RemoveFIBBase(i);
end;

procedure TFIBDatabase.RemoveTransaction(Idx: Integer);
var
  TR: TFIBTransaction;
begin
  if ((Idx >= 0) and (FTransactions[Idx] <> nil)) then
    begin
      TR := Transactions[Idx];
      FTransactions.Delete(Idx);
      TR.FDatabases.Remove(Self);
      if TR.FDefaultDatabase = Self then
        TR.FDefaultDatabase := nil;
      if TR = FDefaultTransaction then
        FDefaultTransaction := nil;
      if TR = FDefaultUpdateTransaction then
        FDefaultUpdateTransaction := nil;
    end;
end;

procedure TFIBDatabase.RemoveTransactions;
var
  i: Integer;
begin
  for i := TransactionCount - 1 downto 0 do
    if FTransactions[i] <> nil then
      RemoveTransaction(i);
end;

procedure TFIBDatabase.LoadLibrary;
begin
{$IFDEF C23}
{$IFDEF WIN64}
  if (FLibraryName <> FLibraryName64) and (Trim(FLibraryName64) <> '') then
    FLibraryName := FLibraryName64;
{$ENDIF}
{$ENDIF}
  if not FClientLibLoaded then
    begin
      FClientLibrary := IB_Intf.GetClientLibrary(FLibraryName);
      FClientLibLoaded := Assigned(FClientLibrary);
    end;
  if not FClientLibrary.LibraryLoaded then
    FClientLibrary.LoadIBLibrary
end;

procedure TFIBDatabase.SetConnected(Value: Boolean);
begin
  if csReading in ComponentState then
    FStreamedConnected := Value
  else if Value then
    begin
      Open
    end
  else
    Close;
end;

procedure TFIBDatabase.SetDatabaseName(const Value: string);
begin
  if FDBName <> Value then
    begin
      if csDesigning in ComponentState then
        Close
      else
        CheckInactive;
      FDBName := Value;
    end;
  FDBFileName := ''
end;

procedure TFIBDatabase.SetDBParamByName(const ParName, Value: string);
var
  ConstIdx: Integer;
begin
  ConstIdx := IndexOfDBConst(ParName);
  if (Value = '') then
    begin
      if ConstIdx <> -1 then
        DBParams.Delete(ConstIdx);
    end
  else
    begin
      if (ConstIdx = -1) then
        DBParams.Add(ParName + '=' + Value)
      else
        DBParams[ConstIdx] := ParName + '=' + Value;
    end;
end;

procedure TFIBDatabase.SetDBParamByDPB(const Idx: Integer; Value: string);
var
  ConstName: string;
begin
  ConstName := DPBConstantName(Idx);
  if ConstName = '' then
    FIBError(feDPBConstantUnknown, [IntToStr(Idx)]);
  SetDBParamByName(ConstName, Value);
end;

procedure TFIBDatabase.SetConfigParam(const Name: string; const Value: string);
var
  ParamIdx: Integer;
  OldValue: string;
begin
  ParamIdx := FindConfigParam(Name, OldValue);
  if Value = '' then
    begin
      if ParamIdx <> -1 then
        DBParams.Delete(ParamIdx);
    end
  else if ParamIdx = -1 then
    DBParams.Add('config=' + Name + '=' + Value)
  else
    DBParams[ParamIdx] := 'config=' + Name + '=' + Value;
end;

procedure TFIBDatabase.SetDBParams(Value: TDBParams);
begin
  FDBParams.Assign(Value);
end;

procedure TFIBDatabase.SetDefaultTransaction(Value: TFIBTransaction);
begin
  if (FDefaultTransaction <> Value) then
    if Assigned(Value) then
      begin
        Value.AddDatabase(Self);
        AddTransaction(Value);
        if not Assigned(Value.FDefaultDatabase) then
          Value.FDefaultDatabase := Self;
      end;
  FDefaultTransaction := Value;
end;

procedure TFIBDatabase.SetDefaultUpdateTransaction(Value: TFIBTransaction);
begin
  if (FDefaultUpdateTransaction <> Value) then
    if Assigned(Value) then
      begin
        Value.AddDatabase(Self);
        AddTransaction(Value);
        if not Assigned(Value.FDefaultDatabase) then
          Value.FDefaultDatabase := Self;
      end;
  FDefaultUpdateTransaction := Value;
end;

procedure TFIBDatabase.CreateTimeoutTimer;
begin
  if not Assigned(FTimer) then
    begin
      FTimer := TFIBTimer.Create(Self);
      with FTimer do
        begin
          Enabled := False;
          Interval := 0;
          OnTimer := TimeoutConnection;
        end;
    end;
end;

procedure TFIBDatabase.SetTimeout(Value: Cardinal);
begin
  if (Value = 0) then
    begin
      if Assigned(FTimer) then
        begin
          FTimer.Free;
          FTimer := nil
        end;
    end
  else if (Value > 0) then
    begin
      CreateTimeoutTimer;
      FTimer.Interval := Value;
      if not(csDesigning in ComponentState) then
        FTimer.Enabled := True;
    end;
end;

procedure TFIBDatabase.SetHandle(Value: TISC_DB_HANDLE);
begin
  if HandleIsShared then
    Close
  else
    CheckInactive;
  FAttachmentID := 0;
  FHandle := Value;
  FHandleIsShared := (Value <> nil);
  if FHandleIsShared then
    begin
      FConnectionSerial := NextConnectionSerial;
      // read again from the shared attachment
      FServerMajorVersion := -1;
      FServerMinorVersion := -1;
      FServerBuild := -1;
      LoadLibrary;
      InitAttachment;
      DoOnConnect
    end;
end;

(*
  * PingAttachment -
  *  0 if the server answers, else the error code. Raises nothing and
  *  bypasses the error handler, so it's safe while handling an error.
*)
function TFIBDatabase.PingAttachment: ISC_STATUS;
var
  Status: TStatusVector;
  DBInfoCommand: AnsiChar;
  local_buffer: array [0 .. 31] of AnsiChar;
begin
  Result := 0;
  if not Connected then
    Exit;
  DBInfoCommand := AnsiChar(isc_info_base_level);
  if FClientLibrary.isc_database_info(PISC_STATUS(@Status), @FHandle, 1,
    @DBInfoCommand, SizeOf(local_buffer), local_buffer) > 0 then
    Result := Status[1];
end;

function TFIBDatabase.TestConnected: Boolean;
begin
  Result := Connected;
  if Result then
    try
      if BaseLevel = 0 then; // who cares
    except
      ForceClose;
      Result := False;
    end;
end;

procedure TFIBDatabase.TimeoutConnection(Sender: TObject);
var
  ai: TActionOnIdle;
begin
  if Connected then
    begin
      if Assigned(FOnIdleConnect) then
        begin
          ai := aiCloseConnect;
          FOnIdleConnect(Self, FIBGetTickCount - FLastActiveTime, ai);
          if ai = aiKeepLiveConnect then
            Exit;
        end;
      ForceClose;
      if Assigned(FOnTimeout) then
        FOnTimeout(Self);
    end
end;

function TFIBDatabase.ClientVersion: string;
var
  p: PAnsiChar;
begin
  LoadLibrary;
  GetMem(p, 100);
  try
    FClientLibrary.isc_get_client_version(p);
    Result := string(p);
  finally
    FreeMem(p, 100)
  end
end;

// The API version of the client (6.3 for Firebird 3 and later), not the product version
function TFIBDatabase.ClientMajorVersion: Integer;
begin
  LoadLibrary;
  Result := FClientLibrary.isc_get_client_major_version;
end;

function TFIBDatabase.ClientMinorVersion: Integer;
begin
  LoadLibrary;
  Result := FClientLibrary.isc_get_client_minor_version;
end;

function TFIBDatabase.GetIsFirebirdConnect: Boolean;
begin
  Result := GetFBVersion <> ''
end;

function TFIBDatabase.IsFirebirdConnect: Boolean;
begin
  Result := FIsFireBirdConnect
end;

procedure TFIBDatabase.RaiseFeatureNotSupported(const Feature: string; ByClientLibrary: Boolean);
begin
  if not IsFirebirdConnect then
    FIBError(feFeatureNotSupported, [Feature, 'InterBase'])
  else if ByClientLibrary then
    FIBError(feClientFeatureNotSupported, [Feature, ClientLibrary.LibraryName])
  else
    FIBError(feFeatureNotSupported, [Feature, Format('Firebird %d.%d', [ServerMajorVersion, ServerMinorVersion])]);
end;

procedure TFIBDatabase.RequireSessionTimeouts(const PropName: string; Value: Cardinal);
begin
  if (Value <> 0) and not FCapabilities.SessionTimeouts then
    RaiseFeatureNotSupported(PropName, False);
end;

procedure TFIBDatabase.RequireStatementTimeout(const PropName: string; Value: Cardinal);
begin
  if (Value = 0) or FCapabilities.StatementTimeout then
    Exit;
  if not FCapabilities.SessionTimeouts then
  begin
    if Value <> FIBNoStatementTimeout then
      RaiseFeatureNotSupported(PropName, False);
  end
  else
    RaiseFeatureNotSupported(PropName, True);
end;

procedure TFIBDatabase.RequireReadConsistency(const PropName: string);
begin
  if not FCapabilities.ReadConsistency then
    RaiseFeatureNotSupported(PropName, False);
end;

function TFIBDatabase.IsIB2007Connect: Boolean;
begin
  Result := not FIsFireBirdConnect;
  if Result then
    begin
      Result := ServerMajorVersion >= 8
    end;
end;

function TFIBDatabase.NeedUTFEncodeDDL: Boolean;
begin
  // For FB2.1 and more
  Result := FNeedUTFDecodeDDL;
end;

function TFIBDatabase.NeedUnicodeFieldsTranslation: Boolean;
begin
  if not Connected then
    Result := (FConnectParams.CharSet = 'UNICODE_FSS') or
      (FConnectParams.CharSet = 'NONE') or (FConnectParams.CharSet = 'UTF8') or (FConnectParams.CharSet = '')
  else
    Result := FNeedUnicodeFieldsTranslation;
end;

function TFIBDatabase.NeedUnicodeFieldTranslation(FieldCharacterSet: Integer): Boolean;
begin
  if FNeedUTFDecodeDDL or FIsNoneConnect then
    Result := (FieldCharacterSet in UnicodeCharSets)
  else if FIsUnicodeConnect then
    Result := not(FieldCharacterSet in [0, OCTETS_CHARSET_ID]) // OCTETS,NONE
  else
    Result := False
end;

function TFIBDatabase.IsUnicodeConnect: Boolean;
begin
  if not Connected then
    Result := (FConnectParams.CharSet = 'UNICODE_FSS') or (FConnectParams.CharSet = 'UTF8')
  else
    Result := FIsUnicodeConnect;
end;

function TFIBDatabase.IsKOI8Connect: Boolean;
begin
  if not Connected then
    Result := (FConnectParams.CharSet = 'KOI8R') or (FConnectParams.CharSet = 'KOI8U')
  else
    Result := FCapabilities.AttachmentCharSetID in [63, 64]; // KOI8R, KOI8U
end;

function TFIBDatabase.GetContextVariable(ContextSpace: TFBContextSpace;
  const VarName: string; aTransaction: TFIBTransaction = nil): variant;
var
  NameSpace: string;
begin
  case ContextSpace of
    csSystem: NameSpace := 'SYSTEM';
    csSession: NameSpace := 'USER_SESSION';
    csTransaction: NameSpace := 'USER_TRANSACTION';
  end;

  if IsFirebirdConnect and (GetServerMajorVersion >= 2) then
    begin
      Result := QueryValue
        ('Select rdb$get_context(:NameSpace,:VarName) from rdb$database', 0, [NameSpace, VarName], aTransaction);
      if VarType(Result) = varBoolean then
        Result := null;
    end
  else
    FIBError(feFB2feature, ['"rdb$get_context"']);
end;

procedure TFIBDatabase.SetContextVariable(ContextSpace: TFBContextSpace;
  const VarName, VarValue: string; aTransaction: TFIBTransaction = nil);
var
  NameSpace: string;
begin
  if IsFirebirdConnect and (GetServerMajorVersion >= 2) then
    begin
      case ContextSpace of
        csSystem: NameSpace := 'SYSTEM';
        csSession: NameSpace := 'USER_SESSION';
        csTransaction: NameSpace := 'USER_TRANSACTION';
      end;
      QueryValue('Execute block (NameSpace varchar(80) =:N,'#13#10 +
        'VarName varchar(80) =:V,  VarValue  varchar(80) =:VV) as '#13#10 +
        'begin'#13#10 + ' rdb$set_context(:NameSpace,:VarName,:VarValue);'#13#10 +
        'end', -1, [NameSpace, VarName, VarValue], aTransaction);
    end
  else
    FIBError(feFB2feature, ['"rdb$set_context"']);
end;

// FB2.5
procedure TFIBDatabase.EnableCancelOperations;
begin
  CheckActive;
  Call(FClientLibrary.fb_cancel_operation(StatusVector, @FHandle, fb_cancel_enable), True);
end;

procedure TFIBDatabase.DisableCancelOperations;
begin
  CheckActive;
  Call(FClientLibrary.fb_cancel_operation(StatusVector, @FHandle, fb_cancel_disable), True);
end;

function TFIBDatabase.CanCancelOperationFB21: Boolean;
begin
  Result := IsFirebirdConnect and ((ServerMajorVersion > 2) or (ServerMajorVersion = 2) and (ServerMinorVersion >= 1));
end;

procedure TFIBDatabase.CancelOperationFB21(ConnectForCancel: TFIBDatabase = nil);
var
  NeedCreateConnect: Boolean;
begin
  if Busy then
    begin
      if CanCancelOperationFB21 then
        begin
          NeedCreateConnect := (ConnectForCancel = nil) or ConnectForCancel.Busy;
          if NeedCreateConnect then
            begin
              ConnectForCancel := TFIBDatabase.Create(Self);
              ConnectForCancel.DBName := DBName;
              ConnectForCancel.DBParams.Assign(DBParams);
              ConnectForCancel.LibraryName := LibraryName;
              ConnectForCancel.CryptKey := CryptKey;
              ConnectForCancel.OnCryptKeyRequest := OnCryptKeyRequest;
              ConnectForCancel.Connected := True;
            end;
          try
            if not ConnectForCancel.Connected then
              ConnectForCancel.Connected := True;
            ConnectForCancel.Execute
            ('DELETE FROM MON$STATEMENTS WHERE MON$STATE=1 AND MON$ATTACHMENT_ID=' + IntToStr(AttachmentID));
          finally
            if NeedCreateConnect then
              begin
                ConnectForCancel.Close;
                ConnectForCancel.Free
              end;
          end
        end;
    end
end;

procedure TFIBDatabase.RaiseCancelOperations;
begin
  CheckActive;
  if Busy then
    Call(FClientLibrary.fb_cancel_operation(StatusVector, @FHandle, fb_cancel_raise), True);
end;

function TFIBDatabase.UnicodeCharSets: TIBCharSets;
begin
  Result := [3]; // UNICODE_FSS
  // Include(Result,4)    // UTF8
  if Connected then
    if FIsFireBirdConnect then
      Include(Result, 4) // UTF8
    else if FIsIB2007Connect then
      Result := Result + [59, 8, 64] // UTF8,UNICODE_BE,UNICODE_LE
end;

function TFIBDatabase.UTF8CharSetID: Integer;
// Character set of the strings encoded by UTF8Encode
begin
  if FIsFireBirdConnect and (ServerMajorVersion >= 2) then
    Result := FB_UTF8_CHARSET_ID
  else if FIsIB2007Connect then
    Result := IB_UTF8_CHARSET_ID
  else
    Result := UNICODE_FSS_CHARSET_ID;
end;

function TFIBDatabase.BytesInUnicodeChar(CharSetId: Integer): Byte;
begin
  Result := 1;
  if CharSetId = 3 then
    Result := 3 // UNICODE_FSS
  else if Connected then
    if FIsFireBirdConnect then
      begin
        if CharSetId = 4 then
          Result := 4 // UTF8
      end
    else if FIsIB2007Connect then
      begin
        case CharSetId of
          8, 64: Result := 2; // UNICODE_BE,UNICODE_LE
          59: Result := 4; // UTF8
        end;
      end;
end;

function TFIBDatabase.ReturnDeclaredFieldSize: Boolean;
begin
  Result := True;
  if Connected then
    if IsFirebirdConnect and (ServerMajorVersion >= 2) then
      Result := False;
end;

// Database Info procedures -- Advanced stuff (translated from isc_database_info)
function TFIBDatabase.GetAllocation: Long;
begin
  Result := GetLongDBInfo(isc_info_allocation);
end;

function TFIBDatabase.GetBaseLevel: Long;
var
  local_buffer: array [0 .. FIBLocalBufferLength - 1] of AnsiChar;
  DBInfoCommand: AnsiChar;
begin
  CheckActive;
  DBInfoCommand := AnsiChar(isc_info_base_level);
  Call(ClientLibrary.isc_database_info(StatusVector, @FHandle, 1,
    @DBInfoCommand, FIBLocalBufferLength, local_buffer), True);
  Result := FClientLibrary.isc_vax_integer(@local_buffer[4], 1);
end;

function TFIBDatabase.GetDBFileName: string;
var
  local_buffer: array [0 .. FIBLocalBufferLength - 1] of AnsiChar;
  DBInfoCommand: AnsiChar;
begin
  if FDBFileName = '' then
    begin
      CheckActive;
      DBInfoCommand := AnsiChar(isc_info_db_id);
      Call(FClientLibrary.isc_database_info(StatusVector, @FHandle, 1,
        @DBInfoCommand, FIBLocalBufferLength, local_buffer), True);
      Result := DecodeServerText(@local_buffer[5], Int(local_buffer[4]));
      FDBFileName := Result
    end
  else
    Result := FDBFileName
end;

function TFIBDatabase.GetDBSiteName: string;
var
  local_buffer: array [0 .. FIBBigLocalBufferLength - 1] of AnsiChar;
  p: PAnsiChar;
  DBInfoCommand: AnsiChar;
begin
  CheckActive;
  DBInfoCommand := AnsiChar(isc_info_db_id);
  Call(FClientLibrary.isc_database_info(StatusVector, @FHandle, 1,
    @DBInfoCommand, FIBLocalBufferLength, local_buffer), True);
  p := @local_buffer[5 + Int(local_buffer[4])]; // DBSiteName Length
  Result := DecodeServerText(p + 1, Int(p^));
end;

function TFIBDatabase.GetIsRemoteConnect: Boolean;
var
  local_buffer: array [0 .. FIBBigLocalBufferLength - 1] of AnsiChar;
  DBInfoCommand: AnsiChar;
begin
  CheckActive;
  if FConnectType = 0 then
    begin
      DBInfoCommand := AnsiChar(isc_info_db_id);
      Call(FClientLibrary.isc_database_info(StatusVector, @FHandle, 1,
        @DBInfoCommand, FIBLocalBufferLength, local_buffer), True);
      FConnectType := Byte(local_buffer[3]);
    end;
  Result := FConnectType = 4
end;

function TFIBDatabase.GetActiveTransactions: TStringList;
// isc_info_active_transactions
var
  local_buffer: array [0 .. FIBBigLocalBufferLength - 1] of AnsiChar;
  DBInfoCommand: AnsiChar;
  i: Integer;
  L: Integer;
begin
  CheckActive;
  if FActiveTransactions = nil then
    FActiveTransactions := TStringList.Create;
  Result := FActiveTransactions;
  FActiveTransactions.Clear;

  DBInfoCommand := AnsiChar(frb_info_active_transactions);
  Call(FClientLibrary.isc_database_info(StatusVector, @FHandle, 1,
    @DBInfoCommand, FIBLocalBufferLength, local_buffer), True);
  i := 0;

  while local_buffer[i] = AnsiChar(frb_info_active_transactions) do
    begin
      Inc(i, 3);
      L := FClientLibrary.isc_vax_integer(@local_buffer[i], 4);
      Result.Add(IntToStr(L));
      Inc(i, 4);
    end;
end;

function TFIBDatabase.GetFBVersion: string; // frb_info_firebird_version
var
  local_buffer: array [0 .. FIBBigLocalBufferLength - 1] of AnsiChar;
  DBInfoCommand: AnsiChar;
begin
  CheckActive;
  DBInfoCommand := AnsiChar(frb_info_firebird_version);
  Call(FClientLibrary.isc_database_info(StatusVector, @FHandle, 1,
    @DBInfoCommand, FIBLocalBufferLength, local_buffer), True);
  if DBInfoCommand = local_buffer[0] then
    Result := DecodeServerText(@local_buffer[5], Int(local_buffer[4]))
  else
    Result := '';
end;

function TFIBDatabase.FBAttachCharsetID: Integer;
begin
  Result := FCapabilities.AttachmentCharSetID;
end;

function TFIBDatabase.GetCreationDate: TDateTime;
var
  local_buffer: array [0 .. FIBLocalBufferLength - 1] of AnsiChar;
  DBInfoCommand: AnsiChar;
  ts: TISC_TIMESTAMP;
begin
  CheckActive;
  DBInfoCommand := AnsiChar(frb_info_creation_date);
  Call(FClientLibrary.isc_database_info(StatusVector, @FHandle, 1,
    @DBInfoCommand, FIBLocalBufferLength, local_buffer), True);
  // Other tag: not supported (FB < 2.0, InterBase)
  if (local_buffer[0] = DBInfoCommand) and (FClientLibrary.isc_vax_integer(@local_buffer[1], 2)
    = SizeOf(TISC_TIMESTAMP)) then
    begin
      ts.timestamp_date := FClientLibrary.isc_vax_integer(@local_buffer[3], 4);
      ts.timestamp_time := ISC_TIME(FClientLibrary.isc_vax_integer(@local_buffer[7], 4));
      Result := FBTimeStampToDateTime(ts);
    end
  else
    Result := 0;
end;

procedure TFIBDatabase.FillServerVersions;
var
  VersionStr: string;
  tmpstr: string;
  i: Integer;
  PVersion: PInteger;
begin
  CheckActive;
  if FServerMajorVersion = -1 then
    begin
      if IsFirebirdConnect then
        VersionStr := FBVersion
      else
        VersionStr := Version;
      tmpstr := '';
      i := 5;
      PVersion := @FServerMajorVersion;
      while i < Length(VersionStr) do
        begin
          if CharInSet(VersionStr[i], ['0' .. '9']) then
            tmpstr := tmpstr + VersionStr[i]
          else
            begin
              if Length(tmpstr) > 0 then
                PVersion^ := StrToInt(tmpstr)
              else
                PVersion^ := 0;
              tmpstr := '';
              if PVersion = @FServerMajorVersion then
                PVersion := @FServerMinorVersion
              else if PVersion = @FServerMinorVersion then
                PVersion := @FServerRelease
              else if PVersion = @FServerRelease then
                PVersion := @FServerBuild
              else
                Break;
            end;
          Inc(i);
        end;
    end;
end;

function TFIBDatabase.GetServerMajorVersion: Integer;
begin
  FillServerVersions;
  Result := FServerMajorVersion;
end;

function TFIBDatabase.GetServerMinorVersion: Integer;
begin
  FillServerVersions;
  Result := FServerMinorVersion;
end;

function TFIBDatabase.GetInternalTransaction: TFIBTransaction;
begin
  Result := FInternalTransaction
end;

function TFIBDatabase.GetServerBuild: Integer;
begin
  FillServerVersions;
  Result := FServerBuild;
end;

function TFIBDatabase.GetServerRelease: Integer;
begin
  FillServerVersions;
  Result := FServerRelease;
end;

function TFIBDatabase.GetDBImplementationNo: Long;
var
  local_buffer: array [0 .. FIBLocalBufferLength - 1] of AnsiChar;
  DBInfoCommand: AnsiChar;
begin
  CheckActive;
  DBInfoCommand := AnsiChar(isc_info_implementation);
  Call(FClientLibrary.isc_database_info(StatusVector, @FHandle, 1,
    @DBInfoCommand, FIBLocalBufferLength, local_buffer), True);
  Result := FClientLibrary.isc_vax_integer(@local_buffer[3], 1);
end;

function TFIBDatabase.GetOldestTransaction: Long;
var
  Success: Boolean;
begin
  Result := GetProtectLongDBInfo(frb_info_oldest_transaction, Success);
end;

function TFIBDatabase.GetOldestActive: Long;
var
  Success: Boolean;
begin
  Result := GetProtectLongDBInfo(frb_info_oldest_active, Success);
end;

function TFIBDatabase.GetOldestSnapshot: Long;
var
  Success: Boolean;
begin
  Result := GetProtectLongDBInfo(frb_info_oldest_snapshot, Success);
end;

function TFIBDatabase.GetDBImplementationClass: Long;
var
  local_buffer: array [0 .. FIBLocalBufferLength - 1] of AnsiChar;
  DBInfoCommand: AnsiChar;
begin
  DBInfoCommand := AnsiChar(isc_info_implementation);
  Call(FClientLibrary.isc_database_info(StatusVector, @FHandle, 1,
    @DBInfoCommand, FIBLocalBufferLength, local_buffer), True);
  Result := FClientLibrary.isc_vax_integer(@local_buffer[4], 1);
end;

function TFIBDatabase.GetNoReserve: Long;
begin
  Result := GetLongDBInfo(isc_info_no_reserve);
end;

function TFIBDatabase.GetODSMinorVersion: Long;
begin
  Result := GetLongDBInfo(isc_info_ods_minor_version);
end;

function TFIBDatabase.GetODSMajorVersion: Long;
begin
  Result := GetLongDBInfo(isc_info_ods_version);
end;

function TFIBDatabase.ReadUTF8Metadata: Boolean;
var
  ODSMajor: Integer;
begin
  // ODS 12 and later come with Firebird 3 and later: no round trip
  Result := FIsFB21OrMore and (ServerMajorVersion >= 3);
  if FIsFB21OrMore and not Result then
  begin
    ODSMajor := GetODSMajorVersion;
    Result := (ODSMajor > 11) or ((ODSMajor = 11) and (GetODSMinorVersion >= 1));
  end;
end;

function TFIBDatabase.GetPageSize: Long;
begin
  Result := GetLongDBInfo(isc_info_page_size);
end;

function TFIBDatabase.GetVersion: string;
var
  local_buffer: array [0 .. FIBBigLocalBufferLength - 1] of AnsiChar;
  DBInfoCommand: AnsiChar;
begin
  DBInfoCommand := AnsiChar(isc_info_version);

  Call(FClientLibrary.isc_database_info(StatusVector, @FHandle, 1,
    @DBInfoCommand, FIBBigLocalBufferLength, local_buffer), True);
  Result := DecodeServerText(@local_buffer[5], Int(local_buffer[4]));
end;

function TFIBDatabase.GetCurrentMemory: Long;
begin
  Result := GetLongDBInfo(isc_info_current_memory);
end;

function TFIBDatabase.GetForcedWrites: Long;
begin
  Result := GetLongDBInfo(isc_info_forced_writes);
end;

function TFIBDatabase.GetMaxMemory: Long;
begin
  Result := GetLongDBInfo(isc_info_max_memory);
end;

function TFIBDatabase.GetNumBuffers: Long;
begin
  Result := GetLongDBInfo(isc_info_num_buffers);
end;

function TFIBDatabase.GetSweepInterval: Long; // isc_info_sweep_interval
begin
  Result := GetLongDBInfo(isc_info_sweep_interval);
end;

function TFIBDatabase.GetUserNames: TStringList;
var
  local_buffer: array [0 .. FIBHugeLocalBufferLength - 1] of AnsiChar;
  DBInfoCommand: AnsiChar;
  i, user_length: Integer;
begin
  if FUserNames = nil then
    FUserNames := TStringList.Create;
  Result := FUserNames;
  DBInfoCommand := AnsiChar(isc_info_user_names);
  Call(FClientLibrary.isc_database_info(StatusVector, @FHandle, 1,
    @DBInfoCommand, FIBHugeLocalBufferLength, local_buffer), True);
  FUserNames.Clear;
  i := 0;
  while local_buffer[i] = AnsiChar(isc_info_user_names) do
    begin
      Inc(i, 3);
      // skip "isc_info_user_names byte" & two unknown bytes of structure (see below)
      user_length := Long(local_buffer[i]);
      Inc(i, 1);
      FUserNames.Add(DecodeServerText(@local_buffer[i], user_length));
      Inc(i, user_length);
    end;
end;

function TFIBDatabase.GetFetches: Long;
begin
  Result := GetLongDBInfo(isc_info_fetches);
end;

function TFIBDatabase.GetReadOnly: Long;
begin
  Result := GetLongDBInfo(isc_info_db_read_only);
end;

function TFIBDatabase.GetMarks: Long;
begin
  Result := GetLongDBInfo(isc_info_marks);
end;

function TFIBDatabase.GetReads: Long;
begin
  Result := GetLongDBInfo(isc_info_reads);
end;

function TFIBDatabase.GetWrites: Long;
begin
  Result := GetLongDBInfo(isc_info_writes);
end;

function TFIBDatabase.GetOperationCounts(DBInfoCommand: Integer; var FOperation: TStringList): TStringList;
var
  local_buffer: array [0 .. FIBHugeLocalBufferLength - 1] of AnsiChar;
  _DBInfoCommand: AnsiChar;
  i, qtd_tables, id_table, qtd_operations: Integer;
begin
  if FOperation = nil then
    FOperation := TStringList.Create;
  Result := FOperation;
  _DBInfoCommand := AnsiChar(DBInfoCommand);
  Call(FClientLibrary.isc_database_info(StatusVector, @FHandle, 1,
    @_DBInfoCommand, FIBHugeLocalBufferLength, local_buffer), True);
  FOperation.Clear;
  // 1. 1 byte specifying the item type requested (e.g., isc_info_insert_count).
  // 2. 2 bytes telling how many bytes compose the subsequent value pairs.
  // 3. A pair of values for each table in the database on wich the requested
  // type of operation has occurred since the database was last attached.
  // Each pair consists of:
  // 1. 2 bytes specifying the table ID.
  // 2. 4 bytes listing the number of operations (e.g., inserts) done on that table.
  qtd_tables := FClientLibrary.isc_vax_integer(@local_buffer[1], 2) div 6;
  for i := 0 to qtd_tables - 1 do
    begin
      id_table := FClientLibrary.isc_vax_integer(@local_buffer[3 + (i * 6)], 2);
      qtd_operations := FClientLibrary.isc_vax_integer
        (@local_buffer[5 + (i * 6)], 4);
      FOperation.Add(IntToStr(id_table) + '=' + IntToStr(qtd_operations));
    end;
end;

function TFIBDatabase.GetAllModifications: Integer;
var
  local_buffer: array [0 .. FIBHugeLocalBufferLength - 1] of AnsiChar;
  _DBInfoCommand: AnsiChar;
  i, qtd_tables: Integer;
  j: Byte;
begin
  Result := 0;
  for j := isc_info_insert_count to isc_info_delete_count do
    begin
      _DBInfoCommand := AnsiChar(j);
      Call(FClientLibrary.isc_database_info(StatusVector, @FHandle, 1,
        @_DBInfoCommand, FIBHugeLocalBufferLength, local_buffer), True);
      // 1. 1 byte specifying the item type requested (e.g., isc_info_insert_count).
      // 2. 2 bytes telling how many bytes compose the subsequent value pairs.
      // 3. A pair of values for each table in the database on wich the requested
      // type of operation has occurred since the database was last attached.
      // Each pair consists of:
      // 1. 2 bytes specifying the table ID.
      // 2. 4 bytes listing the number of operations (e.g., inserts) done on that table.
      qtd_tables := FClientLibrary.isc_vax_integer(@local_buffer[1], 2) div 6;
      for i := 0 to qtd_tables - 1 do
        begin
          Inc(Result, FClientLibrary.isc_vax_integer(@local_buffer [5 + (i * 6)], 4));
        end;
    end;
end;

function TFIBDatabase.GetBackoutCount: TStringList;
begin
  if FBackoutCount = nil then
    FBackoutCount := TStringList.Create;
  Result := GetOperationCounts(isc_info_backout_count, FBackoutCount);
end;

function TFIBDatabase.GetDeleteCount: TStringList;
begin
  if FDeleteCount = nil then
    FDeleteCount := TStringList.Create;
  Result := GetOperationCounts(isc_info_delete_count, FDeleteCount);
end;

function TFIBDatabase.GetExpungeCount: TStringList;
begin
  if FExpungeCount = nil then
    FExpungeCount := TStringList.Create;
  Result := GetOperationCounts(isc_info_expunge_count, FExpungeCount);
end;

function TFIBDatabase.GetInsertCount: TStringList;
begin
  if FInsertCount = nil then
    FInsertCount := TStringList.Create;
  Result := GetOperationCounts(isc_info_insert_count, FInsertCount);
end;

function TFIBDatabase.GetPurgeCount: TStringList;
begin
  if FPurgeCount = nil then
    FPurgeCount := TStringList.Create;
  Result := GetOperationCounts(isc_info_purge_count, FPurgeCount);
end;

function TFIBDatabase.GetReadIdxCount: TStringList;
begin
  if FReadIdxCount = nil then
    FReadIdxCount := TStringList.Create;
  Result := GetOperationCounts(isc_info_read_idx_count, FReadIdxCount);
end;

function TFIBDatabase.GetTableOperationInfo(const TableName: string; FromStrs: TStrings): Integer;
var
  vTableID: Integer;
  tmpstr: string;
begin
  vTableID := ListTableInfo.GetTableInfo(Self, TableName, False).TableID[Self];
  tmpstr := FromStrs.Values[IntToStr(vTableID)];
  if Length(tmpstr) > 0 then
    Result := StrToInt(tmpstr)
  else
    Result := 0;
end;

function TFIBDatabase.GetIndexedReadCount(const TableName: string): Integer;
begin
  GetReadIdxCount;
  Result := GetTableOperationInfo(TableName, FReadIdxCount)
end;

function TFIBDatabase.GetNonIndexedReadCount(const TableName: string): Integer;
begin
  GetReadSeqCount;
  Result := GetTableOperationInfo(TableName, FReadSeqCount)
end;

function TFIBDatabase.GetInsertsCount(const TableName: string): Integer;
begin
  GetInsertCount;
  Result := GetTableOperationInfo(TableName, FInsertCount)
end;

function TFIBDatabase.GetUpdatesCount(const TableName: string): Integer;
begin
  GetUpdateCount;
  Result := GetTableOperationInfo(TableName, FUpdateCount)
end;

function TFIBDatabase.GetDeletesCount(const TableName: string): Integer;
begin
  GetDeleteCount;
  Result := GetTableOperationInfo(TableName, FDeleteCount)
end;

function TFIBDatabase.GetReadSeqCount: TStringList;
begin
  if FReadSeqCount = nil then
    FReadSeqCount := TStringList.Create;
  Result := GetOperationCounts(isc_info_read_seq_count, FReadSeqCount);
end;

function TFIBDatabase.GetUpdateCount: TStringList;
begin
  if FUpdateCount = nil then
    FUpdateCount := TStringList.Create;
  Result := GetOperationCounts(isc_info_update_count, FUpdateCount);
end;

function TFIBDatabase.GetLogFile: Long;
begin
  Result := GetLongDBInfo(isc_info_logfile);
end;

function TFIBDatabase.GetCurLogFileName: string;
begin
  Result := GetStringDBInfo(isc_info_cur_logfile_name);
end;

function TFIBDatabase.GetCurLogPartitionOffset: Long;
begin
  Result := GetLongDBInfo(isc_info_cur_log_part_offset);
end;

function TFIBDatabase.GetNumWALBuffers: Long;
begin
  Result := GetLongDBInfo(isc_info_num_wal_buffers);
end;

function TFIBDatabase.GetWALBufferSize: Long;
begin
  Result := GetLongDBInfo(isc_info_wal_buffer_size);
end;

function TFIBDatabase.GetWALCheckpointLength: Long;
begin
  Result := GetLongDBInfo(isc_info_wal_ckpt_length);
end;

function TFIBDatabase.GetWALCurCheckpointInterval: Long;
begin
  Result := GetLongDBInfo(isc_info_wal_cur_ckpt_interval);
end;

function TFIBDatabase.GetWALPrvCheckpointFilename: string;
begin
  Result := GetStringDBInfo(isc_info_wal_prv_ckpt_fname);
end;

function TFIBDatabase.GetWALPrvCheckpointPartOffset: Long;
begin
  Result := GetLongDBInfo(isc_info_wal_prv_ckpt_poffset);
end;

function TFIBDatabase.GetWALGroupCommitWaitUSecs: Long;
begin
  Result := GetLongDBInfo(isc_info_wal_grpc_wait_usecs);
end;

function TFIBDatabase.GetWALNumIO: Long;
begin
  Result := GetLongDBInfo(isc_info_wal_num_io);
end;

function TFIBDatabase.GetWALAverageIOSize: Long;
begin
  Result := GetLongDBInfo(isc_info_wal_avg_io_size);
end;

function TFIBDatabase.GetWALNumCommits: Long;
begin
  Result := GetLongDBInfo(isc_info_wal_num_commits);
end;

function TFIBDatabase.GetWALAverageGroupCommitSize: Long;
begin
  Result := GetLongDBInfo(isc_info_wal_avg_grpc_size);
end;

function TFIBDatabase.GetProtectLongDBInfo(DBInfoCommand: Integer; var Success: Boolean): Long;
var
  local_buffer: array [0 .. FIBLocalBufferLength - 1] of AnsiChar;
  Length: Short;
  _DBInfoCommand: AnsiChar;
begin
  _DBInfoCommand := AnsiChar(DBInfoCommand);
  Call(FClientLibrary.isc_database_info(StatusVector, @FHandle, 1,
    @_DBInfoCommand, FIBLocalBufferLength, local_buffer), True);
  Success := local_buffer[0] = _DBInfoCommand;
  Length := Short(FClientLibrary.isc_vax_integer(@local_buffer[1], 2));
  Result := FClientLibrary.isc_vax_integer(@local_buffer[3], Length);

end;

function TFIBDatabase.GetLongDBInfo(DBInfoCommand: Integer): Long;
var
  Success: Boolean;
begin
  Result := GetProtectLongDBInfo(DBInfoCommand, Success)
end;

function TFIBDatabase.GetStringDBInfo(DBInfoCommand: Integer): string;
var
  local_buffer: array [0 .. FIBBigLocalBufferLength - 1] of AnsiChar;
  _DBInfoCommand: AnsiChar;
begin
  _DBInfoCommand := AnsiChar(DBInfoCommand);
  Call(FClientLibrary.isc_database_info(StatusVector, @FHandle, 1,
    @_DBInfoCommand, FIBBigLocalBufferLength, local_buffer), True);
  Result := DecodeServerText(@local_buffer[4], Int(local_buffer[3]));
end;

function TFIBDatabase.GetInt64DBInfo(DBInfoCommand: Integer): Int64;
var
  local_buffer: array [0 .. FIBLocalBufferLength - 1] of AnsiChar;
  Length: Short;
  _DBInfoCommand: AnsiChar;
begin
  _DBInfoCommand := AnsiChar(DBInfoCommand);
  Call(FClientLibrary.isc_database_info(StatusVector, @FHandle, 1,
    @_DBInfoCommand, FIBLocalBufferLength, local_buffer), True);
  Length := Short(FClientLibrary.isc_vax_integer(@local_buffer[1], 2));
  Result := FClientLibrary.isc_portable_integer(@local_buffer[3], Length);
end;

function TFIBDatabase.GetAttachmentID: Int64;
begin
  // The cached value is reset whenever a new handle is obtained (Open,
  // CreateDatabase, SetHandle), so it never outlives its attachment
  if FHandle = nil then
    Result := 0
  else
    begin
      if FAttachmentID = 0 then
        FAttachmentID := GetInt64DBInfo(isc_info_attachment_id);
      Result := FAttachmentID;
    end;
end;

// Wrappers DBParams

// IB6
function TFIBDatabase.GetDBSQLDialect: Word;
var
  Success: Boolean;
begin
  Result := Word(GetProtectLongDBInfo(isc_info_db_SQL_dialect, Success));
  if not Success then
    Result := 1
end;

procedure TFIBDatabase.SetSQLDialect(const Value: Integer);
begin
  if (Value < 1) then
    FIBError(feSQLDialectInvalid, [nil]);
  if (FHandle <> nil) and (Value > DBSQLDialect) then
    FIBError(feSQLDialectInvalid, [nil]);
  // sent in the DPB
  if FSQLDialect <> Value then
    FDBParamsChanged := True;
  FSQLDialect := Value;
end;

function TFIBDatabase.GetSQLDialect: Integer;
begin
  Result := FSQLDialect
end;

procedure TFIBDatabase.StartTransaction;
begin
  if DefaultTransaction = nil then
    FIBError(feTransactionNotAssigned, [nil]);
  DefaultTransaction.StartTransaction;
end;

procedure TFIBDatabase.Commit;
begin
  if DefaultTransaction = nil then
    FIBError(feTransactionNotAssigned, [CmpFullName(Self)]);
  DefaultTransaction.Commit;
end;

procedure TFIBDatabase.Rollback;
begin
  if DefaultTransaction = nil then
    FIBError(feTransactionNotAssigned, [CmpFullName(Self)]);
  DefaultTransaction.Rollback;
end;

procedure TFIBDatabase.CommitRetaining;
begin
  if DefaultTransaction = nil then
    FIBError(feTransactionNotAssigned, [CmpFullName(Self)]);
  DefaultTransaction.CommitRetaining;
end;

procedure TFIBDatabase.RollbackRetaining;
begin
  if DefaultTransaction = nil then
    FIBError(feTransactionNotAssigned, [CmpFullName(Self)]);
  DefaultTransaction.RollbackRetaining;
end;

function TFIBDatabase.EasyFormatsStr: Boolean;
begin
  Result := (SQLDialect < 3) or UpperOldNames;
end;

function TFIBDatabase.QueryValueAsStr(const aSQL: string; FieldNo: Integer): string;
var
  v: variant;
begin
  v := QueryValue(aSQL, FieldNo, nil, True);
  if VarIsNull(v) then
    Result := ''
  else
    Result := VarAsType(v, varString)
end;

function TFIBDatabase.QueryValueAsStr(const aSQL: string; FieldNo: Integer; ParamValues: array of variant): string;
var
  v: variant;
begin
  v := QueryValue(aSQL, FieldNo, ParamValues, nil, True);
  if VarIsNull(v) then
    Result := ''
  else
    Result := VarAsType(v, varString)
end;

function TFIBDatabase.InternalQueryValue(const aSQL: string; FieldNo: Integer;
  ParamValues: array of variant; aTransaction: TFIBTransaction;
  aCacheQuery: Boolean): variant;
var
  Query: TFIBQuery;
  i: Integer;
  c: Integer;
  HasParams: Boolean;

begin
  Result := False;
  if Assigned(aTransaction) then
    Query := GetQueryForUse(aTransaction, aSQL)
  else
    Query := GetQueryForUse(FInternalTransaction, aSQL);
  HasParams := Query.Params.Count > 0;
  c := Query.Params.Count - 1;
  if High(ParamValues) < c then
    c := Integer(High(ParamValues));

  with Query do
    try
      if not Transaction.Active then
        Transaction.StartTransaction;
      try
        for i := 0 to c do
          if not VarIsEmpty(ParamValues[i]) then
            Params[i].Value := ParamValues[i];
        ExecQuery;
        if (Current.Count > 0) then
          if (FieldNo >= 0) then
            begin
              if Fields[FieldNo].SQLType = SQL_BLOB then
                Result := Fields[FieldNo].AsString
              else
                Result := Fields[FieldNo].Value
            end
          else
            begin
              c := Pred(Current.Count);
              Result := VarArrayCreate([0, c], varVariant);
              for i := 0 to c do
                if Fields[i].SQLType = SQL_BLOB then
                  Result[i] := Fields[i].AsString
                else
                  Result[i] := Fields[i].Value
            end;
      except
        if Transaction.Active then
          Transaction.Rollback;
        raise;
      end
    finally
      if Transaction.InTransaction and (aTransaction = nil) then
        Transaction.Commit;
      if HasParams and aCacheQuery then
        FreeQueryForUse(Query)
      else
        Query.Free;
    end;
end;

function TFIBDatabase.QueryValue(const aSQL: string; FieldNo: Integer;
  aTransaction: TFIBTransaction = nil; aCacheQuery: Boolean = True): variant;
begin
  Result := InternalQueryValue(aSQL, FieldNo, [varEmpty], aTransaction, aCacheQuery);
end;

function TFIBDatabase.QueryValue(const aSQL: string; FieldNo: Integer;
  ParamValues: array of variant; aTransaction: TFIBTransaction = nil;
  aCacheQuery: Boolean = True): variant;
begin
  Result := InternalQueryValue(aSQL, FieldNo, ParamValues, aTransaction, aCacheQuery);
end;

function TFIBDatabase.QueryValues(const aSQL: string; aTransaction: TFIBTransaction = nil; aCacheQuery: Boolean = True): variant;
begin
  Result := InternalQueryValue(aSQL, -1, [varEmpty], aTransaction, aCacheQuery);
end;

function TFIBDatabase.QueryValues(const aSQL: string;
  ParamValues: array of variant; aTransaction: TFIBTransaction = nil;
  aCacheQuery: Boolean = True): variant;
begin
  Result := InternalQueryValue(aSQL, -1, ParamValues, aTransaction, aCacheQuery);
end;

// raises on errors; the Boolean is kept for IFIBConnect
function TFIBDatabase.Execute(const SQL: string): Boolean;
begin
  QueryValue(SQL, -1, nil, True);
  Result := True;
end;

procedure TFIBDatabase.ClearQueryCacheList;
begin
  FIBCacheQueries.ClearQueryCacheList(Self)
end;

procedure TFIBDatabase.CreateGUIDDomain;
begin
  if QueryValue('SELECT COUNT(*) FROM RDB$FIELDS WHERE RDB$FIELD_NAME = ''TGUID''', 0) = 0 then
    Execute('CREATE DOMAIN TGUID AS CHAR(16) CHARACTER SET OCTETS');
end;

function TFIBDatabase.Gen_Id(const GeneratorName: string; Step: Int64; aTransaction: TFIBTransaction = nil): Int64;
var
  Query: TFIBQuery;
  GenName: string;
  vTransaction: TFIBTransaction;
  ForceOpenTr: Boolean;
  NeedSaveGenCache: Boolean;
begin
  GenName := EasyFormatIdentifier(SQLDialect, GeneratorName, EasyFormatsStr);
  if FGenerators.CanWork(GenName) and (Step = 1) then
    begin
      Result := FGenerators.GetNextValue(GenName);
      if Result <> -1 then
        Exit;
      NeedSaveGenCache := True;
      Step := FGenerators.GetStep(GenName)
    end
  else
    NeedSaveGenCache := False;

  vTransaction := FirstActiveTransaction;
  if vTransaction = nil then
    if aTransaction <> nil then
      vTransaction := aTransaction
    else
      vTransaction := FInternalTransaction;

  Query := GetQueryForUse(vTransaction, 'select gen_id(' + GenName + ', ' + IntToStr(Step) + ') from RDB$DATABASE');
  with Query, Transaction do
    try
      ForceOpenTr := not Transaction.InTransaction;
      if ForceOpenTr then
        StartTransaction;
      ExecQuery;
      Result := Fields[0].AsInt64;
      if ForceOpenTr then
        Commit;
    finally
      FreeQueryForUse(Query);
    end;
  if NeedSaveGenCache then
    begin
      FGenerators.InternalSetGenParams(GenName, Result);
      Result := FGenerators.GetNextValue(GenName)
    end;
end;

procedure TFIBDatabase.SetBlobSwapSupport(const Value: TBlobSwapSupport);
begin
  FBlobSwapSupport.Assign(Value);
end;

procedure TFIBDatabase.SetSession(Value: TFIBSession);
begin
  FSession.Assign(Value);
end;

procedure TFIBDatabase.SetSQLLogger(const Value: ISQLLogger);
var
  OldLogger: ISQLLogger;
begin
  if FSQLLogger = Value then
    Exit;
  // cleared first: the logger's SetDatabase calls back here
  OldLogger := FSQLLogger;
  FSQLLogger := nil;
  if Assigned(OldLogger) then
  begin
    if OldLogger.GetInstance is TComponent then
      TComponent(OldLogger.GetInstance).RemoveFreeNotification(Self);
    OldLogger.SetDatabase(nil);
  end;
  if Assigned(Value) then
  begin
    Value.SetDatabase(Self);
    if Value.GetInstance is TComponent then
      TComponent(Value.GetInstance).FreeNotification(Self);
  end;
  FSQLLogger := Value;
end;

procedure TFIBDatabase.SetSQLStatMaker(const Value: ISQLStatMaker);
begin
  FSQLStatMaker := Value;
end;

procedure TFIBDatabase.Notification(AComponent: TComponent; Operation: TOperation);
var
  i: IUnknown;
begin
  if Operation = opRemove then
    if Supports(AComponent, ISQLLogger, i) then
      begin
        if i = FSQLLogger then
          FSQLLogger := nil;
      end;
  inherited;
end;

function TFIBDatabase.GetBusy: Boolean;
begin
  if Assigned(FClientLibrary) then
    Result := FClientLibrary.Busy
  else
    Result := False
end;

// TFIBTransaction

constructor TFIBTransaction.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
{$IFDEF CSMonitor}
  FCSMonitorSupport := TCSMonitorSupport.Create(Self);
{$ENDIF}
  FDatabases := TList.Create;
  FFIBBases := TList.Create;
  FTRParams := TFIBTransactionParams.Create;
  TFIBTransactionParams(FTRParams).FTransaction := Self;
  FTRParamsChanged := True;
  TStringList(FTRParams).OnChange := TRParamsChange;
  TStringList(FTRParams).OnChanging := TRParamsChanging;
  FState := tsClosed;
  if (csDesigning in ComponentState) and not CmpInLoadedState(Self) then
    begin
      FTimeoutAction := TTransactionAction(DefTimeOutAction);
      DefaultDatabase := DefDataBase;
    end
  else if DefTimeOut > 0 then
    Timeout := Cardinal(DefTimeOut);
  FBeforeDestroyEvents := TNotifyEventList.Create(Self);
  FBeforeStartTransactionEvents := TNotifyEventList.Create(Self);
  FAfterStartTransactionEvents := TNotifyEventList.Create(Self);

  FBeforeEndTransactionEvents := TCallBackList.Create(Self); ;
  FAfterEndTransactionEvents := TCallBackList.Create(Self); ;
  FUserKindTransaction := 'NoUserKind';
  if (csDesigning in ComponentState) and ((Owner <> nil) and not(csLoading in Owner.ComponentState)) then
    TPBMode := DefTPBMode
  else
    TPBMode := tpbReadCommitted;
end;

// True when an untouched preset was ended by this call
function TFIBTransaction.EndPreset: Boolean;
begin
  Result := (FTPBMode <> tpbDefault) and not FWritingPreset;
  if Result then
  begin
    CheckNotInTransaction;
    FTPBMode := tpbDefault;
  end;
end;

procedure TFIBTransaction.SetInternal(Value: Boolean);
begin
  if Value = FInternal then
    Exit;
  // the database would get a start event without the end event, or the reverse
  CheckNotInTransaction;
  FInternal := Value;
end;

procedure TFIBTransaction.SetTPBMode(Value: TTPBMode);
begin
  if Value = FTPBMode then
    Exit;
  CheckNotInTransaction;
  if Value = tpbDefault then
    // ends the preset: FTPBMode becomes tpbDefault
    FTRParams.Clear
  else
  begin
    FWritingPreset := True;
    FTRParams.BeginUpdate;
    try
      FTRParams.Clear;
      FTRParams.Add('write');
      FTRParams.Add('isc_tpb_nowait');
      case Value of
        tpbReadCommitted:
          begin
            FTRParams.Add('read_committed');
            FTRParams.Add('rec_version');
          end;
        tpbRepeatableRead:
          FTRParams.Add('concurrency');
        tpbReadConsistency:
          begin
            FTRParams.Add('read_committed');
            FTRParams.Add('read_consistency');
          end;
      end;
    finally
      FTRParams.EndUpdate;
      FWritingPreset := False;
    end;
    FTPBMode := Value;
  end;
end;

function TFIBTransaction.StoreTRParams: Boolean;
begin
  Result := FTPBMode = tpbDefault;
end;

function TFIBTransaction.FIBDataSetsCount: Integer;
begin
  Result := AttachedCount(Self, True);
end;

function TFIBTransaction.FIBQueryCount: Integer;
begin
  Result := AttachedCount(Self, False);
end;

function TFIBTransaction.GetFIBDataSet(Index: Integer): TDataSet;
begin
  Result := TDataSet(AttachedItem(Self, True, Index));
end;

function TFIBTransaction.GetFIBQuery(Index: Integer): TComponent;
begin
  Result := AttachedItem(Self, False, Index);
end;

procedure TFIBTransaction.SetUserKindTransaction(const Value: string);
{$IFNDEF NO_REGISTRY}
var
  RegName: string;
  v: Variant;
{$ENDIF}
begin
{$IFNDEF NO_REGISTRY}
  FUserKindTransaction := Value;
  if (csLoading in ComponentState) or not(csDesigning in ComponentState) or (FUserKindTransaction = 'NoUserKind') then
    Exit;
  RegName := GetKeyForParValue('Software\' + RegFIBRoot + '\' + RegFIBTrKinds, 'Name', FUserKindTransaction);
  if RegName = '' then
    Exit;
  v := DefReadFromRegistry(['Software', RegFIBRoot, RegFIBTrKinds, RegName], ['Params']);
  if VarType(v) = varBoolean then
    Exit;
  TPBMode := tpbDefault;
  TRParams.Text := v[0, 0]
{$ENDIF}
end;

function TFIBTransaction.StoreUserKindTransaction: Boolean;
begin
  Result := FUserKindTransaction <> 'NoUserKind';
end;

function TFIBTransaction.GetFIBVersion: string;
begin
  Result := FIBVersionString;
end;

procedure TFIBTransaction.SetFIBVersion(const Value: string);
begin

end;

procedure TFIBTransaction.DoBeforeStart;
begin
  if (FDefaultDatabase <> nil) and not FInternal and Assigned(FDefaultDatabase.FBeforeStartTransaction) then
    FDefaultDatabase.FBeforeStartTransaction(Self);
  if Assigned(FBeforeStart) then
    FBeforeStart(Self);
end;

procedure TFIBTransaction.DoAfterStart;
begin
  if Assigned(FAfterStart) then
    FAfterStart(Self);
  if (FDefaultDatabase <> nil) and not FInternal and Assigned(FDefaultDatabase.FAfterStartTransaction) then
    FDefaultDatabase.FAfterStartTransaction(Self);
end;

destructor TFIBTransaction.Destroy;
var
  i: Integer;
begin
  if InTransaction then
    case FTimeoutAction of
      TARollbackRetaining: EndTransaction(TARollback, True);
      TACommitRetaining: EndTransaction(TACommit, True);
      else
        EndTransaction(FTimeoutAction, True);
    end;
  for i := Pred(FBeforeDestroyEvents.Count) downto 0 do
    FBeforeDestroyEvents.Event[i](Self);
  for i := FIBBaseCount - 1 downto 0 do
    FIBBases[i].FOnTransactionFree;
  RemoveFIBBases;
  RemoveDatabases;
  FIBAlloc(FTPB, 0, 0);
  FTRParams.Free;
  FFIBBases.Free;
  FDatabases.Free;
{$IFDEF CSMonitor}
  FCSMonitorSupport.Free;
{$ENDIF}
  SetLength(FDatabaseTRParams, 0);
  SetLength(FDatabaseTPBs, 0);
  inherited Destroy;
end;

{$IFDEF CSMonitor}
procedure TFIBTransaction.SetCSMonitorSupport(Value: TCSMonitorSupport);
begin
  FCSMonitorSupport.Assign(Value)
end;
{$ENDIF}

procedure TFIBTransaction.CreateTimeoutTimer;
begin
  if not Assigned(FTimer) then
    begin
      FTimer := TFIBTimer.Create(Self);
      with FTimer do
        begin
          Enabled := False;
          Interval := 0;
          OnTimer := TimeoutTransaction;
        end;
    end;
end;

function TFIBTransaction.DoStoreActive: Boolean;
begin
  Result := Active and MainDatabase.StoreConnected
end;

function TFIBTransaction.Call(ErrCode: ISC_STATUS; RaiseError: Boolean): ISC_STATUS;
var
  i: Integer;
begin
  Reset8087CW;
  Result := ErrCode;
  FCanTimeout := False;

  for i := 0 to DatabaseCount - 1 do
    Databases[i].Call(ErrCode, False); // For reset timer

  if (Result > 0) and RaiseError then
    IBError(IIbClientLibrary(Databases[0]), Self);
end;

procedure TFIBTransaction.CheckDatabasesInList;
begin
  if GetDatabaseCount = 0 then
    FIBError(feNoDatabasesInTransaction, [CmpFullName(Self)]);
end;

procedure TFIBTransaction.AddEvent(Event: TNotifyEvent; EventType: TFIBTransactionEventType);
begin
  case EventType of
    tetBeforeStartTransaction: FBeforeStartTransactionEvents.Add(Event);
    tetAfterStartTransaction: FAfterStartTransactionEvents.Add(Event);
    tetBeforeDestroy: FBeforeDestroyEvents.Add(Event);
    else
      Assert(False);
  end;
end;

procedure TFIBTransaction.RemoveEvent(Event: TNotifyEvent; EventType: TFIBTransactionEventType);
begin
  case EventType of
    tetBeforeStartTransaction: FBeforeStartTransactionEvents.Remove(Event);
    tetAfterStartTransaction: FAfterStartTransactionEvents.Remove(Event);
    tetBeforeDestroy: FBeforeDestroyEvents.Remove(Event);
    else
      Assert(False);
  end;
end;

procedure TFIBTransaction.AddEndEvent(Event: TEndTrEvent; EventType: TFIBTransactionEventType);
begin
  case EventType of
    tetBeforeEndTransaction: FBeforeEndTransactionEvents.RegisterCallBack(TMethod(Event));
    tetAfterEndTransaction: FAfterEndTransactionEvents.RegisterCallBack(TMethod(Event));
    else
      Assert(False);
  end;
end;

procedure TFIBTransaction.RemoveEndEvent(Event: TEndTrEvent; EventType: TFIBTransactionEventType);
begin
  case EventType of
    tetBeforeEndTransaction: FBeforeEndTransactionEvents.UnRegisterCallBack(TMethod(Event));
    tetAfterEndTransaction: FAfterEndTransactionEvents.UnRegisterCallBack(TMethod(Event));
    else
      Assert(False);
  end;
end;

procedure TFIBTransaction.CheckInTransaction;
begin
  if FStreamedActive and (not InTransaction) then
    Loaded;
  if FHandle = nil then
    FIBError(feNotInTransaction, [CmpFullName(Self)]);
end;

procedure TFIBTransaction.EnsureInTransaction;
var
  i: Integer;
  NeedAutoStart: Boolean;
begin
  if FStreamedActive and (not InTransaction) then
    Loaded;
  if (FHandle = nil) then
    if not(csDesigning in ComponentState) then
      begin
        NeedAutoStart := True;
        for i := 0 to Pred(DatabaseCount) do
          if not Databases[i].FAutoReconnect then
            begin
              NeedAutoStart := False;
              Break
            end;
        if NeedAutoStart then
          StartTransaction
        else
          FIBError(feNotInTransaction, [CmpFullName(Self)])
      end
    else
      StartTransaction;
end;

procedure TFIBTransaction.CheckNotInTransaction;
begin
  if (FHandle <> nil) then
    FIBError(feInTransaction, [CmpFullName(Self)]);
end;

function TFIBTransaction.AddDatabase(db: TFIBDatabase): Integer;
var
  i: Integer;
begin
  if not Assigned(db) then
    Result := -1
  else
    begin
      i := FindDatabase(db);
      if i <> -1 then
        Result := i
      else
        begin
          if (FDatabases.Count > 0) and (TFIBDatabase(FDatabases[0]).LibraryName <> db.LibraryName) then
            if not(csLoading in ComponentState) then
              raise EAPICallException.CreateFmt(STransactionForOtherLibrary, [CmpFullName(Self)])
            else
              begin
                Result := -1;
                Exit;
              end;
          Result := DatabaseCount;
          db.AddTransaction(Self);
          FDatabases.Add(db);
          SetLength(FDatabaseTRParams, FDatabases.Count);
          FDatabaseTRParams[Length(FDatabaseTRParams) - 1] := '';
        end;
    end;
end;

function TFIBTransaction.AddDatabase(db: TFIBDatabase; const aTRParams: string): Integer;
begin
  Result := AddDatabase(db);
  if Result >= 0 then
    FDatabaseTRParams[Result] := aTRParams
end;

{$IFDEF USE_DEPRECATE_METHODS1}
function TFIBTransaction.AddDataSet(ds: TFIBBase): Integer;
begin
  Result := AddFIBBase(ds);
end;
{$ENDIF}

function TFIBTransaction.AddFIBBase(ds: TFIBBase): Integer;
begin
  Result := 0;
  while (Result < FFIBBases.Count) and (FFIBBases[Result] <> nil) do
    Inc(Result);
  if (Result = FFIBBases.Count) then
    FFIBBases.Add(ds)
  else
    FFIBBases[Result] := ds;
end;

procedure TFIBTransaction.Commit;
begin
  EndTransaction(TACommit, False);
end;

procedure TFIBTransaction.CommitRetaining;
begin
  EndTransaction(TACommitRetaining, False);
end;

(*
  * EndTransaction -
  *  End a transaction ...
*)
procedure TFIBTransaction.EndTransaction(Action: TTransactionAction; Force: Boolean);
var
  Status: ISC_STATUS;
  S: string;

  procedure DoBefore;
  var
    i: Integer;
  begin
    for i := FIBBaseCount - 1 downto 0 do
      FIBBases[i].FOnTransactionEnding;
    for i := 0 to FBeforeEndTransactionEvents.Count - 1 do
      TEndTrEvent(FBeforeEndTransactionEvents.CallBackAddr[i]^)(Self, Action, Force);
  end;

  procedure DoAfter;
  var
    i: Integer;
  begin
    for i := FIBBaseCount - 1 downto 0 do
      FIBBases[i].FOnTransactionEnded;
    for i := 0 to FAfterEndTransactionEvents.Count - 1 do
      TEndTrEvent(FAfterEndTransactionEvents.CallBackAddr[i]^)(Self, Action, Force);

    FHasUncommitedUpdates := False
  end;

begin
  CheckInTransaction;
  if (FDefaultDatabase <> nil) and not FInternal and Assigned(FDefaultDatabase.FBeforeEndTransaction) then
    FDefaultDatabase.FBeforeEndTransaction(Self, Action, Force);
  if Assigned(FBeforeEnd) then
    FBeforeEnd(Self, Action, Force);
  if Assigned(MainDatabase.FSQLLogger) then
    begin
      case Action of
        TACommit: S := 'Commit';
        TARollback: S := 'RollBack';
        TACommitRetaining: S := 'CommitRetaining';
        else
          S := 'RollBackRetaining';
      end;
      MainDatabase.FSQLLogger.WriteData(CmpFullName(Self), S + '(TransactionID=' +
        IntToStr(TransactionID) + ') ', 'TransactionParams:'#13#10 + TRParams.Text, lfTransact);
    end;

  case Action of
    TARollback, TACommit:
      begin
        if (HandleIsShared) and (Action <> FTimeoutAction) and (not Force) then
          FIBError(feCantEndSharedTransaction, [nil]);
        if Action = TARollback then
          FState := tsDoRollback
        else
          FState := tsDoCommit;
        DoBefore;
        if HandleIsShared then
          begin
            FHandle := nil;
            FHandleIsShared := False;
            Status := 0;
          end
        else if (Action = TARollback) then
          Status := Call(IIbClientLibrary(MainDatabase).isc_rollback_transaction(StatusVector, @FHandle), False)
        else
          Status := Call(IIbClientLibrary(MainDatabase).isc_commit_transaction(StatusVector, @FHandle), False);
        if ((Force) and (Status > 0)) then
          Status := Call(IIbClientLibrary(MainDatabase).isc_rollback_transaction(StatusVector, @FHandle), False);
        if Force then
          FHandle := nil
        else if (Status > 0) then
          IBError(MainDatabase, Self);
        DoAfter;

      end;
    TACommitRetaining:
      begin
        FState := tsDoCommitRetaining;
        DoBefore;
        Call(IIbClientLibrary(MainDatabase).isc_commit_retaining(StatusVector, @FHandle), True);
        DoAfter;
      end;
    TARollbackRetaining:
      begin
        FState := tsDoRollbackRetaining;
        DoBefore;
        Call(IIbClientLibrary(MainDatabase).isc_rollback_retaining(StatusVector, @FHandle), True);
        DoAfter;
      end;
  end;
{$IFNDEF NO_MONITOR}
  if MonitoringEnabled then
    case Action of
      TACommit:
        if MonitorHook <> nil then
          MonitorHook.TRCommit(Self);
      TARollback:
        if MonitorHook <> nil then
          MonitorHook.TRRollback(Self);
      TACommitRetaining:
        if MonitorHook <> nil then
          MonitorHook.TRCommitRetaining(Self);
      TARollbackRetaining:
        if MonitorHook <> nil then
          MonitorHook.TRRollbackRetaining(Self);
    end;
{$ENDIF}
  if InTransaction then
    begin
      FState := tsActive;
    end
  else
    begin
      FState := tsClosed;
      if FTimer <> nil then
        FTimer.Enabled := False;
      if csDesigning in ComponentState then
        CloseAllQueryHandles;
    end;
  FTransactionID := 0;
  if Assigned(FAfterEnd) then
    FAfterEnd(Self, Action, Force);
  if (FDefaultDatabase <> nil) and not FInternal and Assigned(FDefaultDatabase.FAfterEndTransaction) then
    FDefaultDatabase.FAfterEndTransaction(Self, Action, Force);
end;

function TFIBTransaction.GetDatabase(Index: Integer): TFIBDatabase;
begin
  Result := FDatabases[Index];
end;

function TFIBTransaction.GetDatabaseCount: Integer;
begin
  Result := Integer(FDatabases.Count);
end;

function TFIBTransaction.MainDatabase: TFIBDatabase;
begin
  if Assigned(DefaultDatabase) then
    Result := DefaultDatabase
  else if FDatabases.Count = 0 then
    Result := nil
  else
    Result := FDatabases[0];
end;

function TFIBTransaction.GetFIBBase(Index: Integer): TFIBBase;
begin
  Result := FFIBBases[Index];
end;

function TFIBTransaction.GetFIBBasesCount: Integer;
begin
  Result := Integer(FFIBBases.Count);
end;

function TFIBTransaction.GetInTransaction: Boolean;
begin
  Result := (FHandle <> nil);
end;

function TFIBTransaction.FindDatabase(db: TFIBDatabase): Integer;
begin
  if db = nil then
    Result := -1
  else
    Result := Integer(FDatabases.IndexOf(db));
end;

function TFIBTransaction.GetTimeout: Cardinal;
begin
  if Assigned(FTimer) then
    Result := FTimer.Interval
  else
    Result := 0;
end;

procedure TFIBTransaction.Loaded;
var
  i: Integer;
begin
  if (csDesigning in ComponentState) then
    Include(FTransactionRunStates, trsInLoaded);
  try
    inherited Loaded;
    try
      if csDesigning in ComponentState then
        for i := 0 to DatabaseCount - 1 do
          if Databases[i].FStreammedConnectFail then
            Exit;

      if FStreamedActive and (not InTransaction) then
        StartTransaction;
    except
      on E: Exception do
        begin
          if not(csDesigning in ComponentState) then
            raise
          else
            begin
              ShowException(E, nil);
            end;
        end;
    end;
  finally
    FStreamedActive := False;
    Exclude(FTransactionRunStates, trsInLoaded);
  end
end;

procedure TFIBTransaction.OnDatabaseDisconnecting(db: TFIBDatabase);
begin
  if InTransaction then
    // Force the transaction to end
    if FTimeoutAction = TACommitRetaining then
      EndTransaction(TACommit, True)
    else if FTimeoutAction = TARollbackRetaining then
      EndTransaction(TARollback, True)
    else
      EndTransaction(FTimeoutAction, True);
end;

procedure TFIBTransaction.RemoveDatabase(Idx: Integer);
var
  db: TFIBDatabase;
begin
  if ((Idx >= 0) and (FDatabases[Idx] <> nil)) then
    begin
      db := Databases[Idx];
      FDatabases.Delete(Idx);
      db.FTransactions.Remove(Self);
      if db.FDefaultTransaction = Self then
        db.FDefaultTransaction := nil;
      if db.FDefaultUpdateTransaction = Self then
        db.FDefaultUpdateTransaction := nil;

      if db = FDefaultDatabase then
        FDefaultDatabase := nil;
    end;
end;

procedure TFIBTransaction.RemoveDatabases;
var
  i: Integer;
begin
  for i := DatabaseCount - 1 downto 0 do
    RemoveDatabase(i);
end;

procedure TFIBTransaction.ReplaceDatabase(dbOld, dbNew: TFIBDatabase);
begin
  RemoveDatabase(FindDatabase(dbOld));
  AddDatabase(dbNew)
end;

{$IFDEF USE_DEPRECATE_METHODS1}
procedure TFIBTransaction.RemoveDataSet(Idx: Integer);
begin
  RemoveFIBBase(Idx);
end;
{$ENDIF}

procedure TFIBTransaction.RemoveFIBBase(Idx: Integer);
var
  ds: TFIBBase;
begin
  if ((Idx >= 0) and (FFIBBases[Idx] <> nil)) then
    begin
      ds := FIBBases[Idx];
      ds.FTransaction := nil;
      if Idx < FFIBBases.Count - 1 then
        begin
          ds := FFIBBases[FFIBBases.Count - 1];
          FFIBBases[Idx] := ds;
          ds.FIndexInTransaction := Idx;
          FFIBBases.Delete(FFIBBases.Count - 1);
        end
      else
        FFIBBases.Delete(Idx);
    end;
end;
{$IFDEF USE_DEPRECATE_METHODS1}
procedure TFIBTransaction.RemoveDataSets;
begin
  RemoveFIBBases
end;
{$ENDIF}

procedure TFIBTransaction.RemoveFIBBases;
var
  i: Integer;
begin
  for i := FIBBaseCount - 1 downto 0 do
    // if FFIBBases[i] <> nil then
    RemoveFIBBase(i);
end;

procedure TFIBTransaction.Rollback;
begin
  EndTransaction(TARollback, False);
end;

procedure TFIBTransaction.RollbackRetaining;
begin
  EndTransaction(TARollbackRetaining, False);
end;

procedure TFIBTransaction.SetActive(Value: Boolean);
begin
  if csReading in ComponentState then
    FStreamedActive := Value
  else if Value and not InTransaction then
    StartTransaction
  else if not Value and InTransaction then
    Rollback;
end;

procedure TFIBTransaction.SetDefaultDatabase(Value: TFIBDatabase);
begin
  CheckNotInTransaction;
  if (Value <> FDefaultDatabase) then
    begin
      if Assigned(Value) then
        Value.AddTransaction(Self);
      ReplaceDatabase(FDefaultDatabase, Value);
      // the TPB depends on the server version (lock_timeout)
      FTRParamsChanged := True;
    end;
  FDefaultDatabase := Value;
end;

procedure TFIBTransaction.SetHandle(Value: TISC_TR_HANDLE);
begin
  if (HandleIsShared) then
    EndTransaction(TimeoutAction, True)
  else
    CheckNotInTransaction;
  FHandle := Value;
  FHandleIsShared := (Value <> nil);
end;

procedure TFIBTransaction.SetTimeout(Value: Cardinal);
begin
  { if Value < 0 then
    FIBError(feTimeoutNegative, [nil])
    else }
  if (Value = 0) then
    begin
      if Assigned(FTimer) then
        begin
          FTimer.Free;
          FTimer := nil;
        end;
    end
  else if (Value > 0) then
    begin
      CreateTimeoutTimer;
      FTimer.Interval := Value;
      if not(csDesigning in ComponentState) and Active then
        FTimer.Enabled := True;
    end;
end;

procedure TFIBTransaction.SetTRParams(Value: TStrings);
begin
  FTRParams.Assign(Value);
end;

(*
  * StartTransaction -
  *  Start a transaction....
*)
procedure TFIBTransaction.StartTransaction;
var
  pteb: PISC_TEB_ARRAY;
  TPB: AnsiString;
  i: Integer;
  vTRParams1: TStrings;
  DatabaseParams: TStrings;
  ReadConsistency: Boolean;
  vTPBLength: Short;
  vIsFB21orMore: Boolean;
begin
  (*
    * Check that we're not already in a transaction.
    * Check that there is at least one database in the list.
  *)

  CheckNotInTransaction;
  DoBeforeStart;
  CheckDatabasesInList;
  for i := 0 to DatabaseCount - 1 do
    begin
      Databases[i].CheckActive(not(trsInLoaded in FTransactionRunStates));
      if not Databases[i].Connected then
        FIBError(feDatabaseClosed, [CmpFullName(Databases[i])]);
    end;
  vIsFB21orMore := MainDatabase.FIsFB21OrMore;
  (*
    * Make sure that a current TPB is generated.
  *)
  if FTRParamsChanged or (FTPBCodePage <> MainDatabase.Capabilities.TPBCodePage) then
    begin
      GenerateTPB(FTRParams, TPB, FTPBLength, vIsFB21orMore, MainDatabase.Capabilities.TPBCodePage);
      FIBAlloc(FTPB, 0, FTPBLength);
      Move(TPB[1], FTPB[0], FTPBLength);
      FReadConsistencyParams := HasParamsLine(FTRParams, 'read_consistency');
      FTPBCodePage := MainDatabase.Capabilities.TPBCodePage;
      // only now: GenerateTPB raises for a wrong line and the next start must build it again
      FTRParamsChanged := False;
    end;
  GetMem(pteb, DatabaseCount * SizeOf(TISC_TEB));
  vTRParams1 := nil;
  try
    for i := 0 to DatabaseCount - 1 do
      begin
        pteb^[i].db_handle := @(Databases[i].Handle);
        if (FDatabaseTRParams[i] = '') and (Databases[i].Capabilities.TPBCodePage = FTPBCodePage) then
          begin
            ReadConsistency := FReadConsistencyParams;
            pteb^[i].tpb_address := FTPB;
            pteb^[i].tpb_length := FTPBLength;
          end
        else
          begin
            if FDatabaseTRParams[i] = '' then
              DatabaseParams := FTRParams
            else
            begin
              if vTRParams1 = nil then
                vTRParams1 := TStringList.Create;
              vTRParams1.Text := FDatabaseTRParams[i];
              DatabaseParams := vTRParams1;
            end;
            ReadConsistency := HasParamsLine(DatabaseParams, 'read_consistency');

            SetLength(FDatabaseTPBs, i + 1);
            GenerateTPB(DatabaseParams, FDatabaseTPBs[i], vTPBLength, vIsFB21orMore,
              Databases[i].Capabilities.TPBCodePage);
            if Length(FDatabaseTPBs[i]) > 0 then
              begin
                pteb^[i].tpb_address := @FDatabaseTPBs[i][1];
                pteb^[i].tpb_length := vTPBLength;
              end
            else
              begin
                ReadConsistency := FReadConsistencyParams;
                pteb^[i].tpb_address := FTPB;
                pteb^[i].tpb_length := FTPBLength;
              end
          end;
        if ReadConsistency then
          Databases[i].RequireReadConsistency('TRParams read_consistency');
      end;
    for i := 0 to FIBBaseCount - 1 do
      FIBBases[i].FOnTransactionStarting;

    (*
      * Finally, start the transaction
    *)
    if not InTransaction then
      begin
        for i := Pred(FBeforeStartTransactionEvents.Count) downto 0 do
          FBeforeStartTransactionEvents.Event[i](Self);

        if (Call(IIbClientLibrary(MainDatabase).isc_start_multiple(StatusVector,
          @FHandle, Short(DatabaseCount), PISC_TEB(pteb)), False) > 0)

        then
          begin
            FHandle := nil;
            IBError(MainDatabase, Self);
          end;
        for i := Pred(FAfterStartTransactionEvents.Count) downto 0 do
          FAfterStartTransactionEvents.Event[i](Self);
      end;

    for i := 0 to FIBBaseCount - 1 do
      FIBBases[i].FOnTransactionStarted;
{$IFNDEF NO_MONITOR}
    if MonitoringEnabled then
      if MonitorHook <> nil then
        MonitorHook.TRStart(Self);
{$ENDIF}
  finally
    vTRParams1.Free;
    FIBAlloc(pteb, 0, 0);
  end;

  FState := tsActive;

  if Assigned(MainDatabase.FSQLLogger) then
    MainDatabase.FSQLLogger.WriteData(CmpFullName(Self),
      'StartTransaction(TransactionID=' + IntToStr(TransactionID) + ')',
      'TransactionParams:'#13#10 + TRParams.Text, lfTransact);

  if (FTimer <> nil) and (FTimer.Interval > 0) then
    FTimer.Enabled := True;
  if InTransaction then
    DoAfterStart;
end;

procedure TFIBTransaction.ExecSQLImmediate(const SQLText: WideString);
var
  vSQLText: AnsiString;
begin
  EnsureInTransaction;
  vSQLText := EncodeString(SQLText, MainDatabase.Capabilities.CodePage);
  Call(MainDatabase.ClientLibrary.isc_dsql_execute_immediate(StatusVector,
    @MainDatabase.Handle, @FHandle, 0, PAnsiChar(vSQLText), Word(MainDatabase.SQLDialect), nil), True);
end;

procedure TFIBTransaction.SetSavePoint(const SavePointName: string);
begin
  ExecSQLImmediate('savepoint ' + SavePointName);
{$IFNDEF NO_MONITOR}
  if MonitoringEnabled then
    if MonitorHook <> nil then
      MonitorHook.TRSavepoint(Self, SavePointName, soSet)
{$ENDIF}
end;

procedure TFIBTransaction.RollBackToSavePoint(const SavePointName: string);
begin
  ExecSQLImmediate('rollback to savepoint ' + SavePointName);
{$IFNDEF NO_MONITOR}
  if MonitoringEnabled then
    if MonitorHook <> nil then
      MonitorHook.TRSavepoint(Self, SavePointName, soRollback)
{$ENDIF}
end;

procedure TFIBTransaction.ReleaseSavePoint(const SavePointName: string);
begin
  ExecSQLImmediate('release savepoint ' + SavePointName);
{$IFNDEF NO_MONITOR}
  if MonitoringEnabled then
    if MonitorHook <> nil then
      MonitorHook.TRSavepoint(Self, SavePointName, soRelease)
{$ENDIF}
end;

procedure TFIBTransaction.TimeoutTransaction(Sender: TObject);
begin
  if InTransaction then
    begin
      if FCanTimeout then
        begin
          EndTransaction(FTimeoutAction, True);
          if Assigned(FOnTimeout) then
            FOnTimeout(Self);
        end
      else
        FCanTimeout := True;
    end;
end;

procedure TFIBTransaction.TRParamsChange(Sender: TObject);
begin
  FTRParamsChanged := True;
  EndPreset;
end;

procedure TFIBTransaction.TRParamsChanging(Sender: TObject);
begin
  CheckNotInTransaction;
end;

function TFIBTransaction.GetTransactionID: Integer;
var
  tra_items: AnsiChar;
  tra_info: array [0 .. 31] of AnsiChar;
begin
  if FTransactionID > 0 then
    begin
      Result := FTransactionID;
      Exit;
    end;
  if FHandle = nil then
    begin
      Result := 0;
      Exit;
    end;
  if MainDatabase.FDatabaseRunState * [drsInCloseLostConnect, drsInRestoreLostConnect] <> [] then
    begin
      Result := 0;
      Exit;
    end;

  tra_items := AnsiChar(isc_info_tra_id);
  Call(IIbClientLibrary(MainDatabase).isc_transaction_info(StatusVector,
    @FHandle, SizeOf(tra_items), @tra_items, SizeOf(tra_info), tra_info), True);
  Result := PInteger(tra_info + 3)^;
  FTransactionID := Result
end;

procedure TFIBTransaction.CloseAllQueryHandles;
var
  i: Integer;
begin
  for i := 0 to Pred(FIBBaseCount) do
    begin
      if (FIBBases[i].Owner is TFIBQuery) then
        TFIBQuery(FIBBases[i].Owner).FreeHandle
    end;
end;

function TFIBTransaction.IsReadCommitedTransaction: Boolean;
begin
  // read_consistency alone also starts a read committed transaction
  Result := HasParamsLine(FTRParams, 'read_committed') or HasParamsLine(FTRParams, 'read_consistency');
end;

function TFIBTransaction.IsReadOnly: Boolean;
begin
  Result := HasParamsLine(FTRParams, 'read');
end;

procedure TFIBTransaction.DoOnSQLExec(Query: TComponent; Kind: TKindOnOperation);
var
  ar: TAllRowsAffected;
begin
  if FWatchUpdates and not FHasUncommitedUpdates and (Query is TFIBQuery) then
    with TFIBQuery(Query) do
      case Kind of
        koAfter:
          if SQLType <> SQLSelect then
            begin
              ar := AllRowsAffected;
              FHasUncommitedUpdates := (ar.Updates + ar.Deletes + ar.Inserts) > 0;
            end;
        koOther:
          if (SQLType = SQLSelect) and (qrsInClose in QueryRunState) then
            begin
              // For select * from SP
              ar := AllRowsAffected;
              FHasUncommitedUpdates := (ar.Updates + ar.Deletes + ar.Inserts) > 0;
            end;
      end;
  if Query is TFIBQuery then
    case Kind of
      koBefore:
        if Assigned(FBeforeSQLExecute) then
          FBeforeSQLExecute(Query, TFIBQuery(Query).SQLType);
      koAfter:
        if Assigned(FAfterSQLExecute) then
          FAfterSQLExecute(Query, TFIBQuery(Query).SQLType);
      koAfterFirstFetch:
        if Assigned(FAfterFirstFetch) then
          FAfterFirstFetch(Query, TFIBQuery(Query).SQLType);
    end;
end;

// TFIBBase
constructor TFIBBase.Create(AOwner: TObject);
begin
  FOwner := AOwner;
end;

destructor TFIBBase.Destroy;
begin
  SetDatabase(nil);
  SetTransaction(nil);
  inherited;
end;

procedure TFIBBase.CheckDatabase;
begin
  if (FDatabase = nil) then
    if Self.Owner is TComponent then
      FIBError(feDatabaseNotAssigned, [CmpFullName(TComponent(Self.Owner))])
    else
      FIBError(feDatabaseNotAssigned, ['']);
  FDatabase.CheckActive
end;

procedure TFIBBase.CheckTransaction;
begin
  if FTransaction = nil then
    if Self.Owner is TComponent then
      FIBError(feTransactionNotAssigned, [CmpFullName(TComponent(Self.Owner))])
    else
      FIBError(feTransactionNotAssigned, [nil]);
  FTransaction.EnsureInTransaction;
end;

function TFIBBase.GetDBHandle: PISC_DB_HANDLE;
begin
  CheckDatabase;
  Result := @FDatabase.Handle;
end;

function TFIBBase.GetTRHandle: PISC_TR_HANDLE;
begin
  CheckTransaction;
  Result := @FTransaction.Handle;
end;

procedure TFIBBase.FOnDatabaseConnecting;
begin
  if Assigned(OnDatabaseConnecting) then
    OnDatabaseConnecting(Self);
end;

procedure TFIBBase.FOnDatabaseConnected;
begin
  if Assigned(OnDatabaseConnected) then
    OnDatabaseConnected(Self);
end;

procedure TFIBBase.FOnDatabaseDisconnecting;
begin
  if Assigned(OnDatabaseDisconnecting) then
    OnDatabaseDisconnecting(Self);
end;

procedure TFIBBase.FOnDatabaseDisconnected;
begin
  if Assigned(OnDatabaseDisconnected) then
    OnDatabaseDisconnected(Self);
end;

procedure TFIBBase.FOnDatabaseConnectionLost;
begin
  if Assigned(OnDatabaseConnectionLost) then
    OnDatabaseConnectionLost(Self);
end;

procedure TFIBBase.FOnDatabaseFree;
begin
  if Assigned(OnDatabaseFree) then
    OnDatabaseFree(Self);
  // Ensure that FDatabase is nil
  SetDatabase(nil);
  SetTransaction(nil);
end;

procedure TFIBBase.FOnTransactionStarting;
begin
  if Assigned(OnTransactionStarting) then
    OnTransactionStarting(FTransaction);
end;

procedure TFIBBase.FOnTransactionStarted;
begin
  if Assigned(OnTransactionStarted) then
    OnTransactionStarted(FTransaction);
end;

procedure TFIBBase.FOnTransactionEnding;
begin
  if Assigned(OnTransactionEnding) then
    OnTransactionEnding(FTransaction);
end;

procedure TFIBBase.FOnTransactionEnded;
begin
  if Assigned(OnTransactionEnded) then
    OnTransactionEnded(FTransaction);
end;

procedure TFIBBase.FOnTransactionFree;
begin
  if Assigned(OnTransactionFree) then
    OnTransactionFree(Self);
  // Ensure that FTransaction is nil
  FTransaction := nil;
end;

procedure TFIBBase.SetDatabase(Value: TFIBDatabase);
begin
  if FDatabase = Value then
    Exit;
  if (FDatabase <> nil) then
    FDatabase.RemoveFIBBase(FIndexInDatabase);
  FDatabase := Value;
  if (FDatabase <> nil) then
    begin
      // FClientLibrary:=FDatabase.ClientLibrary;
      FIndexInDatabase := FDatabase.AddFIBBase(Self);
      if (FTransaction = nil) and Assigned(Owner) and not CmpInLoadedState(TComponent(Owner)) then
        Transaction := FDatabase.DefaultTransaction;
    end;
end;

procedure TFIBBase.SetTransaction(Value: TFIBTransaction);
begin
  if FTransaction = Value then
    Exit;
  if (FTransaction <> nil) then
    FTransaction.RemoveFIBBase(FIndexInTransaction);
  FTransaction := Value;
  if (FTransaction <> nil) then
    begin
      FIndexInTransaction := FTransaction.AddFIBBase(Self);
      if (FDatabase = nil) or (FTransaction.FindDatabase(FDatabase) = -1) then
        begin
          if FTransaction.GetDatabaseCount > 0 then
            begin
              Database := FTransaction.MainDatabase
            end;
        end;
    end;
end;

procedure CleanDatabaseList;
var
  i: TFIBListIndex;
begin
  with DatabaseList.LockList do
    try
      for i := 0 to Pred(Count) do
        TFIBDatabase(Items[i]).Close;
    finally
      DatabaseList.UnLockList;
      DatabaseList.Free;
      DatabaseList := nil
    end;
end;

initialization

vConnectCS := TCriticalSection.Create;
DefDataBase := nil;
DatabaseList := TThreadList.Create;

finalization

CleanDatabaseList;
vConnectCS.Free;

end.
