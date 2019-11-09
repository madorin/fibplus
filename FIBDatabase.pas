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
{    Written by Serge Buzadzhy (buzz@devrace.com)               }
{                                                               }
{ ------------------------------------------------------------- }
{    FIBPlus home page: http://www.fibplus.com/                 }
{    FIBPlus support  : http://www.devrace.com/support/         }
{ ------------------------------------------------------------- }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit FIBDatabase;

interface
{$I FIBPlus.inc}
{$IFDEF D_XE2}
 {$UNDEF NO_GUI}
 {$UNDEF DIRECT_USE_DB_LOGIN_FORM}
{$ENDIF}
uses
 SysUtils, SyncObjs,Classes,ibase, IB_Intf, IB_Externals,
 pFIBProps,IBBlobFilter, Fib, pFIBEventLists,StdFuncs,
 pFIBInterfaces, FIBPlatforms
  {$IFDEF D6+} ,Variants{$ENDIF}
   {$IFDEF D_XE2}
    ,System.UITypes
   {$ENDIF}
   {$IFDEF FIBPLUS_TRIAL}
    ,Windows
    {$IFDEF D_XE2}
     ,VCL.Dialogs
    {$ELSE}
     ,Dialogs
    {$ENDIF}
   {$ENDIF}
 {$IFDEF DIRECT_USE_DB_LOGIN_FORM}
   ,FIBDBLoginDlg      //IS GUI
 {$ENDIF}
  ;



type


  TFIBDatabase = class;
  TFIBTransaction = class;
  TFIBBase = class;
  TDesignDBOption=(ddoIsDefaultDatabase,ddoStoreConnected,ddoNotSavePassword);
  TDesignDBOptions = set of TDesignDBOption;

  TpFIBDBEventType =(detOnConnect,detBeforeDisconnect,detBeforeDestroy);
  TFIBUseRepository=(urFieldsInfo,urDataSetInfo,urErrorMessagesInfo);
  TFIBUseRepositories=set of TFIBUseRepository;
  TFBContextSpace=(csSystem,csSession,csTransaction);
  TDatabaseRunStateValues=(drsInCloseLostConnect,drsInRestoreLostConnect);
  TDatabaseRunState= set of TDatabaseRunStateValues;
  TBeforeSaveBlobToSwap=procedure(const TableName,FieldName:string;
   { const } RecordKeyValues:array of variant;Stream:TStream;var FileName:string; var CanSave:boolean) of object;

  TAfterSaveLoadBlobSwap=procedure(const TableName,FieldName:string;
   {const }RecordKeyValues:array of variant;const FileName:string) of object;

  TBeforeLoadBlobFromSwap=procedure(const TableName,FieldName:string;
 {    const } RecordKeyValues:array of variant;var FileName:string; var CanLoad:boolean) of object;


  TActionOnIdle=(aiCloseConnect,aiKeepLiveConnect);
  TOnIdleConnect=procedure (Sender:TFIBDatabase; IdleTicks:Cardinal; var Action:TActionOnIdle) of object;

  TIBCharSets=set of byte;
  (* TFIBDatabase *)


 {$IFDEF D_XE2}
  TDoChangeScreenCursor = procedure(NewCursor:Integer; var OldCursor:Integer) of object  ;
 {$ENDIF}

  TFIBDatabase = class(TComponent,IIbClientLibrary,IFIBConnect)
  private
    FSQLLogger:ISQLLogger;
    FSQLStatMaker:ISQLStatMaker;
    FUseRepositories    :TFIBUseRepositories;
    FLibraryName        :string;
    FUseBlrToTextFilter :boolean;
    FClientLibLoaded    :boolean;
    FBlobSwapSupport    :TBlobSwapSupport;
    FBeforeSaveBlobToSwap:TBeforeSaveBlobToSwap;
    FAfterSaveBlobToSwap :TAfterSaveLoadBlobSwap;
    FAfterLoadBlobFromSwap :TAfterSaveLoadBlobSwap;
    FBeforeLoadBlobFromSwap:TBeforeLoadBlobFromSwap;
    FOnIdleConnect:TOnIdleConnect;
    FAutoReconnect:boolean;
    FGenerators :TGeneratorsCache;
    FMemoSubtypes : TMemoSubtypes;
   {$IFDEF D_XE2}
    FLibraryName64        :string;
    FDoChangeScreenCursor: TDoChangeScreenCursor  ;
   {$ENDIF}

    function GetMemoSubtypes :string;
    procedure SetMemoSubtypes(const Value:string);
    procedure SetGenerators(Value:TGeneratorsCache);

    procedure SetLibraryName(const LibName:string);

    function  StoredLibraryName:boolean;
    {$IFDEF D_XE2}
    function  StoredLibraryName64:boolean;
    {$ENDIF}

    procedure LoadLibrary;
    procedure SetBlobSwapSupport(const Value: TBlobSwapSupport);
    procedure SetSQLLogger(const Value: ISQLLogger);
    procedure SetSQLStatMaker(const Value: ISQLStatMaker);

    function GetBusy: boolean;
  protected
    FClientLibrary      :IIBClientLibrary;
    FFIBBases            : TList;                        // TFIBBases attached.
    FTransactions       : TList;                        // TFIBTransactions attached.
    FDBName             : Ansistring;                       // DB's name
    FDBParams           : TDBParams;                     // "Pretty" Parameters to database
    FDBParamsChanged    : Boolean;                      // Flag to determine if DPB must be regenerated
    FDPB                : PAnsiChar;                        // Parameters to DB as passed to IB.
    FDPBLength          : Short;                        // Length of parameter buffer
    FHandle             : TISC_DB_HANDLE;               // DB's handle
    FHandleIsShared     : Boolean;                      // Is the handle shared with another DB?
    FUseLoginPrompt     : Boolean;                      // Show a default login prompt?
    FOnConnect          : TNotifyEvent;                 // Upon successful connection...
    FOnTimeout          : TNotifyEvent;                 // Upon timing out...
    FDefaultTransaction : TFIBTransaction;              // Many transaction components can be specified, but this is the primary, or default one to use.
    FDefaultUpdateTransaction : TFIBTransaction;              //
    FStreamedConnected  : Boolean;                      // Used for delaying the opening of the database.
    FTimer              : TFIBTimer;                       // The timer ID.
    FUserNames          : TStringList;                  // For use only with GetUserNames
    FActiveTransactions : TStringList;                  // For use only with GetActiveTransactions    
    FBackoutCount: TStringList;                         // isc_info_backout_count
    FDeleteCount: TStringList;                          // isc_info_delete_count
    FExpungeCount: TStringList;                         // isc_info_expunge_count
    FInsertCount: TStringList;                          // isc_info_insert_count
    FPurgeCount: TStringList;                           // isc_info_purge_count
    FReadIdxCount: TStringList;                         // isc_info_read_idx_count
    FReadSeqCount: TStringList;                         // isc_info_read_seq_count
    FUpdateCount: TStringList;                          // isc_info_update_count
//IB6
    FSQLDialect:integer;
    FUpperOldNames      : boolean; // compatibility with IB4..5 field names conventions
    FConnectParams:TConnectParams;
    FDesignDBOptions:TDesignDBOptions;
    FBeforeDisconnect:TNotifyEvent;
    FAfterDisconnect:TNotifyEvent;
    FDifferenceTime : double;
    FSynchronizeTime:boolean;
    vInternalTransaction:TFIBTransaction;

    vOnConnected      :TNotifyEventList;
    vBeforeDisconnect :TNotifyEventList;
    vOnDestroy        :TNotifyEventList;

    vAttachmentID :Long;
    FBlobFilters  :TIBBlobFilters;
    FDBFileName   :string;
    FConnectType  :ShortInt;
    FNeedUnicodeFieldsTranslation:boolean;
    FIsUnicodeConnect:boolean;
    FIsKOI8Connect:boolean;
    FIsNoneConnect:boolean;
    FDatabaseRunState :TDatabaseRunState;
    FLastActiveTime:Cardinal;
    FStreammedConnectFail:boolean;
    procedure DBParamsChange(Sender: TObject);
    procedure DBParamsChanging(Sender: TObject);
    function GetConnected: Boolean;                     // Is DB connected?
    function GetDatabaseName: string;
    function GetFIBBase(Index: Integer): TFIBBase;      // Get the indexed FIBBase.
    function GetFIBBasesCount: Integer;                  // Get the number of FIBBase connected.
    function GetDBParamByDPB(const Idx: Integer): string;
    function GetTimeout: Cardinal;                       // Get the timeout
    function GetTransaction(Index: Integer): TFIBTransaction;
    function GetFirstActiveTransaction: TFIBTransaction;
    function GetTransactionCount: Integer;
    function GetActiveTransactionCount: Integer;
    function Login: Boolean;                            // Show login prompt
    procedure SetConnected(Value: Boolean);
    procedure SetDatabaseName(const Value: string);
    procedure SetDBParamByDPB(const Idx: Integer; Value: string);
    procedure SetDBParamByName(const ParName,Value: string);
    procedure SetDBParams(Value: TDBParams);
    procedure SetDefaultTransaction(Value: TFIBTransaction);
    procedure SetDefaultUpdateTransaction(Value: TFIBTransaction);
    procedure CreateTimeoutTimer;
    procedure SetHandle(Value: TISC_DB_HANDLE);
    procedure SetTimeout(Value: Cardinal);
    procedure SetDesignDBOptions(Value:TDesignDBOptions);
    procedure TimeoutConnection(Sender: TObject);
    (* Database Info procedures -- Advanced stuff (translated from isc_database_info) *)
    function GetAllocation: Long; // isc_info_allocation
    function GetBaseLevel: Long; // isc_info_base_level
    function GetDBFileName: Ansistring; // isc_info_db_id
    function GetDBSiteName: Ansistring; // isc_info_db_id
    function GetIsRemoteConnect: boolean; // isc_info_db_id

    function GetDBImplementationNo: Long; // isc_info_implementation
    function GetDBImplementationClass: Long;
    function GetNoReserve: Long;       // isc_info_no_reserve
    function GetODSMinorVersion: Long; // isc_info_ods_minor_version
    function GetODSMajorVersion: Long; // isc_info_ods_version
    function GetPageSize: Long;        // isc_info_page_size
    function GetVersion: string;       // isc_info_info_version
    function GetCurrentMemory: Long;   // isc_info_current_memory
    function GetForcedWrites: Long;    // isc_info_forced_writes
    function GetMaxMemory: Long;       // isc_info_max_memory
    function GetNumBuffers: Long;      // isc_info_num_buffers
    function GetSweepInterval: Long;   // isc_info_sweep_interval
    function GetUserNames: TStringList;// isc_info_user_names
    function GetFetches: Long;// isc_info_fetches
    function GetMarks: Long;  // isc_info_marks
    function GetReads: Long;  // isc_info_reads
    function GetWrites: Long; // isc_info_writes
    function GetBackoutCount: TStringList;// isc_info_backout_count
    function GetDeleteCount: TStringList; // isc_info_delete_count
    function GetExpungeCount: TStringList;// isc_info_expunge_count
    function GetInsertCount: TStringList; // isc_info_insert_count
    function GetPurgeCount: TStringList;  // isc_info_purge_count
    function GetReadIdxCount: TStringList;// isc_info_read_idx_count
    function GetReadSeqCount: TStringList;// isc_info_read_seq_count
    function GetUpdateCount: TStringList; // isc_info_update_count

    function GetTableOperationInfo(const TableName:string; FromStrs:TStrings):integer;

    function GetIndexedReadCount(const TableName:string):integer;
    function GetNonIndexedReadCount(const TableName:string):integer;
    function GetInsertsCount(const TableName:string):integer;
    function GetUpdatesCount(const TableName:string):integer;
    function GetDeletesCount(const TableName:string):integer;

    function GetOperationCounts(DBInfoCommand: Integer; var FOperation: TStringList): TStringList;
    function GetAllModifications:integer;

    function GetLogFile: Long;                   // isc_info_log_file
    function GetCurLogFileName: string;          // isc_info_cur_logfile_name
    function GetCurLogPartitionOffset: Long;     // isc_info_cur_log_part_offset
    function GetNumWALBuffers: Long;             // isc_info_num_wal_buffers
    function GetWALBufferSize: Long;             // isc_info_wal_buffer_size
    function GetWALCheckpointLength: Long;       // isc_info_wal_ckpt_length
    function GetWALCurCheckpointInterval: Long;  // isc_info_wal_cur_ckpt_interval
    function GetWALPrvCheckpointFilename: string;// isc_info_wal_prv_ckpt_fname
    function GetWALPrvCheckpointPartOffset: Long;// isc_info_wal_prv_ckpt_poffset
    function GetWALGroupCommitWaitUSecs: Long;   // isc_info_wal_grpc_wait_usecs
    function GetWALNumIO: Long;                  // isc_info_wal_num_id
    function GetWALAverageIOSize: Long;          // isc_info_wal_avg_io_size
    function GetWALNumCommits: Long;             // isc_info_wal_num_commits
    function GetWALAverageGroupCommitSize: Long; // isc_info_wal_avg_grpc_size

    function GetProtectLongDBInfo(DBInfoCommand: Integer;var Success:boolean): Long;
    function GetStringDBInfo(DBInfoCommand: Integer): string;
    function GetLongDBInfo(DBInfoCommand: Integer): Long;
    function GetAttachmentID  :Long;

//Firebird Info
    function GetActiveTransactions: TStringList; // frb_info_active_transactions
    function GetOldestTransaction: Long;         // frb_info_oldest_transaction
    function GetOldestActive: Long;              // frb_info_oldest_active
    function GetOldestSnapshot: Long;            // frb_info_oldest_snapshot
    function GetFBVersion: string;               // frb_info_firebird_version
    function GetAttachCharset: integer;               // frb_info_att_charset
  private
// Versions
    FServerMajorVersion:integer;
    FServerMinorVersion:integer;
    FServerRelease:integer;
    FServerBuild:integer;
    FNeedUTFDecodeDDL:boolean;
    FIsFB21OrMore :boolean;
    procedure FillServerVersions;
    function GetServerMajorVersion: integer;
    function GetServerMinorVersion: integer;
    function GetServerRelease: integer;
    function GetServerBuild: integer;
  protected
    function GetInternalTransaction:TFIBTransaction; // friend for pFIBDataInfo
    property StreammedConnectFail:boolean read FStreammedConnectFail;

  protected
//IB6
    function  GetDBSQLDialect:Word;
    function GetSQLDialect:Integer;
    procedure SetSQLDialect(const Value: Integer);


    function  GetReadOnly: Long;
    function  GetStoreConnected:boolean;
{$IFDEF     CSMonitor}
  private
    FCSMonitorSupport: TCSMonitorSupport;
    procedure SetCSMonitorSupport(Value:TCSMonitorSupport);
{$ENDIF}
  protected
    FIsFireBirdConnect:boolean;
    FIsIB2007Connect:boolean;    
    function  GetIsFirebirdConnect :boolean;
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation);override;
    procedure InternalClose(Force: Boolean;DBinShutDown:boolean=False); virtual ;
    procedure DoOnConnect;
    procedure DoBeforeDisconnect;
    procedure DoAfterDisconnect;

{$IFDEF USE_DEPRECATE_METHODS1}
    procedure RemoveDataSet(Idx: Integer); deprecated;
    procedure RemoveDataSets;              deprecated;
    function  AddDataSet(ds: TFIBBase): Integer; deprecated;
{$ENDIF}
    procedure RemoveFIBBase(Idx: Integer);
    procedure RemoveFIBBases;
    function  AddFIBBase(ds: TFIBBase): Integer;


    procedure RemoveTransaction(Idx: Integer);
    procedure RemoveTransactions;
    function  AddTransaction(TR: TFIBTransaction): Integer;
    procedure IBFilterBuffer(var BlobBuffer:PAnsiChar;var BlobSize:longint;
                        BlobSubType:integer;ForEncode: boolean);
//IFIBObject
    procedure SaveAlias; virtual;

  public
    procedure AddEvent(Event:TNotifyEvent;EventType:TpFIBDBEventType);
    procedure RemoveEvent(Event:TNotifyEvent;EventType:TpFIBDBEventType);

    procedure RegisterBlobFilter(BlobSubType:integer;
                                 EncodeProc,DecodeProc:PIBBlobFilterProc);
    procedure RemoveBlobFilter(BlobSubType:integer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function   Call(ErrCode: ISC_STATUS; RaiseError: Boolean): ISC_STATUS;

    procedure CheckActive(TryReconnect:boolean=False);                              // Raise error if DB is inactive
    procedure CheckInactive;                            // Raise error if DB is active
    procedure CheckDatabaseName;                        // Raise error if DBName is empty
    procedure Close;


    procedure CreateDatabase;
    property  DBParamByDPB[const Idx: Integer]: string read GetDBParamByDPB
                                                      write SetDBParamByDPB;
    procedure DropDatabase;
    function  FindTransaction(TR: TFIBTransaction): Integer;
    procedure ForceClose;
    function  IndexOfDBConst(const st: string): Integer;       // Get the index of a given constant in DBParams
    procedure Open(RaiseExcept:boolean = True); virtual;
    function  TestConnected: Boolean;
    function  GetServerTime:TDateTime;
//FB
    procedure ShutDown(const ShutParams:array of integer;Delay:integer=0);
    procedure Online;
  public
    function  ClientVersion:string;
    function  ClientMajorVersion:integer;
    function  ClientMinorVersion:integer;
    function  IsFirebirdConnect :boolean;


    function  IsUnicodeConnect  :boolean;
    function  IsIB2007Connect   :boolean;
    function  NeedUTFEncodeDDL  :boolean;
    function  NeedUnicodeFieldsTranslation  :boolean;
    function  NeedUnicodeFieldTranslation(FieldCharacterSet:integer)  :boolean;
{$IFDEF SUPPORT_KOI8_CHARSET}
    function  IsKOI8Connect  :boolean;
{$ENDIF}
{FB2 features}
    function  GetContextVariable(ContextSpace:TFBContextSpace;const VarName:string
     ;aTransaction:TFIBTransaction=nil
    ):Variant;
    procedure SetContextVariable( ContextSpace:TFBContextSpace;const VarName,VarValue:string
    ;aTransaction:TFIBTransaction=nil
    );

   function  CanCancelOperationFB21:boolean;
   procedure CancelOperationFB21(ConnectForCancel:TFIBDatabase=nil);

   procedure RaiseCancelOperations;
   procedure EnableCancelOperations;
   procedure DisableCancelOperations;
//
   function UnicodeCharSets:TIBCharSets;
   function BytesInUnicodeChar(CharSetId:integer):Byte;
   function ReturnDeclaredFieldSize:boolean;
   function MemoSubTypesActive:boolean;
   function IsMemoSubtype(aSubtype: ShortInt):boolean;
   function LibraryFilePath:string;
   (* Properties*)


{$IFDEF USE_DEPRECATE_METHODS1}
    property DataSetCount  : Integer read GetFIBBasesCount;       // deprecated;
    property DataSets[Index: Integer]: TFIBBase  read GetFIBBase; // deprecated;
{$ENDIF}
    property FIBBaseCount: Integer read GetFIBBasesCount;
    property FIBBases[Index: Integer]: TFIBBase  read GetFIBBase;

    property Handle: TISC_DB_HANDLE read FHandle write SetHandle;
    property HandleIsShared: Boolean read FHandleIsShared;
    property TransactionCount: Integer read GetTransactionCount;
    property FirstActiveTransaction:TFIBTransaction read GetFirstActiveTransaction;
    property ActiveTransactionCount: Integer        read GetActiveTransactionCount;
    property Transactions[Index: Integer]: TFIBTransaction read GetTransaction;

    property    IsFB21OrMore :boolean read FIsFB21OrMore;
    (* Database Info properties -- Advanced stuff (translated from isc_database_info) *)
    property AttachmentID: Long read GetAttachmentID; // isc_info_attachment_id
    property Allocation: Long read GetAllocation;     // isc_info_allocation
    property BaseLevel: Long read GetBaseLevel;       // isc_info_base_level
    property DBFileName: Ansistring read GetDBFileName;   // isc_info_db_id
    property DBSiteName: Ansistring read GetDBSiteName;
    property IsRemoteConnect: boolean read GetIsRemoteConnect;
    property DBImplementationNo: Long read GetDBImplementationNo; // isc_info_implementation
    property DBImplementationClass: Long read GetDBImplementationClass;
    property NoReserve: Long read GetNoReserve; // isc_info_no_reserve
    property ODSMinorVersion: Long read GetODSMinorVersion; // isc_info_ods_minor_version
    property ODSMajorVersion: Long read GetODSMajorVersion; // isc_info_ods_version
    property PageSize: Long read GetPageSize;               // isc_info_page_size
    property Version: string read GetVersion;           // isc_info_info_version

    property FBVersion:string read GetFBVersion;
    property FBAttachCharsetID:Integer  read GetAttachCharset;
    
    property ServerMajorVersion:integer read GetServerMajorVersion;
    property ServerMinorVersion:integer read GetServerMinorVersion;
    property ServerBuild:integer read GetServerBuild;
    property ServerRelease:integer read GetServerRelease;

    property CurrentMemory: Long read GetCurrentMemory; // isc_info_current_memory
    property ForcedWrites: Long read GetForcedWrites;   // isc_info_forced_writes
    property MaxMemory: Long read GetMaxMemory;         // isc_info_max_memory
    property NumBuffers: Long read GetNumBuffers;       // isc_info_num_buffers
    property SweepInterval: Long read GetSweepInterval; // isc_info_sweep_interval
    property UserNames: TStringList read GetUserNames;  // isc_info_user_names
    property Fetches: Long read GetFetches; // isc_info_fetches
    property Marks: Long read GetMarks;     // isc_info_marks
    property Reads: Long read GetReads;     // isc_info_reads
    property Writes: Long read GetWrites;   // isc_info_writes
    property BackoutCount: TStringList read GetBackoutCount; // isc_info_backout_count
    property DeleteCount: TStringList read GetDeleteCount;   // isc_info_delete_count
    property ExpungeCount: TStringList read GetExpungeCount; // isc_info_expunge_count
    property InsertCount: TStringList read GetInsertCount;   // isc_info_insert_count
    property PurgeCount: TStringList read GetPurgeCount;     // isc_info_purge_count
    property ReadIdxCount: TStringList read GetReadIdxCount; // isc_info_read_idx_count
    property ReadSeqCount: TStringList read GetReadSeqCount; // isc_info_read_seq_count
    property UpdateCount: TStringList read GetUpdateCount;   // isc_info_update_count

    property IndexedReadCount[const TableName:string]:integer read GetIndexedReadCount;
    property NonIndexedReadCount[const TableName:string]:integer read GetNonIndexedReadCount;
    property InsertsCount[const TableName:string]:integer read GetInsertsCount;
    property UpdatesCount[const TableName:string]:integer read GetUpdatesCount;
    property DeletesCount[const TableName:string]:integer read GetDeletesCount;
    property AllModifications:integer read GetAllModifications;

    property LogFile: Long read GetLogFile;                  // isc_info_log_file
    property CurLogFileName: string read GetCurLogFileName;  // isc_info_cur_logfile_name
    property CurLogPartitionOffset: Long read GetCurLogPartitionOffset; // isc_info_cur_log_part_offset
    property NumWALBuffers: Long read GetNumWALBuffers; // isc_info_num_wal_buffers
    property WALBufferSize: Long read GetWALBufferSize; // isc_info_wal_buffer_size
    property WALCheckpointLength: Long read GetWALCheckpointLength; // isc_info_wal_ckpt_length
    property WALCurCheckpointInterval: Long read GetWALCurCheckpointInterval; // isc_info_wal_cur_ckpt_interval
    property WALPrvCheckpointFilename: string read GetWALPrvCheckpointFilename; // isc_info_wal_prv_ckpt_fname
    property WALPrvCheckpointPartOffset: Long read GetWALPrvCheckpointPartOffset; // isc_info_wal_prv_ckpt_poffset
    property WALGroupCommitWaitUSecs: Long read GetWALGroupCommitWaitUSecs; // isc_info_wal_grpc_wait_usecs
    property WALNumIO: Long read GetWALNumIO;                 // isc_info_wal_num_id
    property WALAverageIOSize: Long read GetWALAverageIOSize; // isc_info_wal_avg_io_size
    property WALNumCommits: Long read GetWALNumCommits;       // isc_info_wal_num_commits
    property WALAverageGroupCommitSize: Long read GetWALAverageGroupCommitSize; // isc_info_wal_avg_grpc_size
//IB6
    property DBSQLDialect:Word read GetDBSQLDialect;
    property ReadOnly     :Long   read GetReadOnly ;
    property DatabaseName: string read GetDatabaseName write SetDatabaseName;

    property DifferenceTime : double read FDifferenceTime ;
//Firebird
    property ServerActiveTransactions  :TStringList read GetActiveTransactions;
    property OldestTransactionID       :Long   read GetOldestTransaction;
    property OldestActiveTransactionID :Long   read GetOldestActive;
    property Busy:boolean read GetBusy;
  public
    procedure StartTransaction;
    procedure Commit;
    procedure Rollback;
    procedure CommitRetaining;
    procedure RollbackRetaining;

    function Gen_Id(const GeneratorName: string; Step: Int64;aTransaction:TFIBTransaction =nil): Int64;
    function Execute(const SQL: string): boolean;

    procedure CreateGUIDDomain;
    function InternalQueryValue(const aSQL: string;FieldNo:integer;
     ParamValues:array of variant; aTransaction:TFIBTransaction; aCacheQuery:boolean): Variant;
    function QueryValue(const aSQL: string;FieldNo: Integer; ATransaction: TFIBTransaction=nil;
     aCacheQuery:Boolean = True): Variant; overload;
    function QueryValue(const aSQL: string;FieldNo:integer;
     ParamValues:array of variant;aTransaction:TFIBTransaction=nil;aCacheQuery:boolean=True):Variant; overload;

    function QueryValues(const aSQL: string;aTransaction:TFIBTransaction=nil
     ;aCacheQuery:boolean=True):Variant; overload;
    function QueryValues(const aSQL: string; ParamValues:array of variant;aTransaction:TFIBTransaction=nil;
     aCacheQuery:boolean=True):Variant; overload;


    function QueryValueAsStr(const aSQL: string;FieldNo:integer):string;overload;
    function QueryValueAsStr(const aSQL: string;FieldNo:integer;
      ParamValues:array of variant):string; overload;

    procedure  ClearQueryCacheList;

    function EasyFormatsStr :boolean;
    property StoreConnected :boolean read GetStoreConnected;
    property ClientLibrary:IIbClientLibrary read FClientLibrary implements IIbClientLibrary;
    property SQLStatisticsMaker:ISQLStatMaker read FSQLStatMaker write SetSQLStatMaker;

  published
    property AutoReconnect:boolean read FAutoReconnect write FAutoReconnect default False;
    property Connected: Boolean read GetConnected write SetConnected stored GetStoreConnected;
    property BlobSwapSupport   :TBlobSwapSupport read FBlobSwapSupport write SetBlobSwapSupport;
    property DBName: string read GetDatabaseName write SetDatabaseName;
    property DBParams: TDBParams read FDBParams write SetDBParams;
    property DefaultTransaction: TFIBTransaction read FDefaultTransaction
                                                 write SetDefaultTransaction;
    property DefaultUpdateTransaction: TFIBTransaction read FDefaultUpdateTransaction
                                                 write SetDefaultUpdateTransaction;

    //IB6
    property SQLDialect : Integer read FSQLDialect write SetSQLDialect;

    property Timeout: Cardinal read GetTimeout write SetTimeout;
    property UseLoginPrompt: Boolean read FUseLoginPrompt write FUseLoginPrompt default False;
    // Events

    property OnTimeout: TNotifyEvent read FOnTimeout write FOnTimeout;
    property UpperOldNames: boolean read FUpperOldNames write FUpperOldNames
     default False; // compatibility with IB4..5 field names conventions

    property BeforeDisconnect:TNotifyEvent read FBeforeDisconnect write FBeforeDisconnect;
    property AfterDisconnect :TNotifyEvent read FAfterDisconnect  write FAfterDisconnect ;
    property ConnectParams  :TConnectParams read FConnectParams write FConnectParams stored False;
    property SynchronizeTime:boolean read FSynchronizeTime write FSynchronizeTime default True;

    property DesignDBOptions:TDesignDBOptions read FDesignDBOptions write SetDesignDBOptions default
     [ddoStoreConnected]
    ;
    property OnConnect: TNotifyEvent read FOnConnect write FOnConnect stored False; // obsolete
    property BeforeSaveBlobToSwap:TBeforeSaveBlobToSwap read FBeforeSaveBlobToSwap write FBeforeSaveBlobToSwap;
    property AfterSaveBlobToSwap:TAfterSaveLoadBlobSwap read FAfterSaveBlobToSwap write FAfterSaveBlobToSwap;
    property AfterLoadBlobFromSwap :TAfterSaveLoadBlobSwap read FAfterLoadBlobFromSwap write FAfterLoadBlobFromSwap;
    property BeforeLoadBlobFromSwap:TBeforeLoadBlobFromSwap read FBeforeLoadBlobFromSwap write FBeforeLoadBlobFromSwap;
    property OnIdleConnect:TOnIdleConnect read FOnIdleConnect write FOnIdleConnect;
    property UseRepositories:TFIBUseRepositories read FUseRepositories write FUseRepositories
     default [urFieldsInfo,urDataSetInfo,urErrorMessagesInfo] ;
    property LibraryName:string read FLibraryName write SetLibraryName stored StoredLibraryName;
    //libfbclient.so MACOS
    {$IFDEF D_XE2}
    property LibraryName64:string read  FLibraryName64 write FLibraryName64 stored StoredLibraryName64;
    {$ENDIF}
    property SQLLogger:ISQLLogger read FSQLLogger write SetSQLLogger;
    property UseBlrToTextFilter :boolean read FUseBlrToTextFilter write FUseBlrToTextFilter default False;
    property GeneratorsCache :TGeneratorsCache read FGenerators write SetGenerators;
    {$IFDEF CSMonitor}
    property CSMonitorSupport: TCSMonitorSupport read FCSMonitorSupport write SetCSMonitorSupport;
    {$ENDIF}
    {$IFDEF D_XE2}
    property DoChangeScreenCursor: TDoChangeScreenCursor read FDoChangeScreenCursor  write FDoChangeScreenCursor;
    {$ENDIF}
  published
    property MemoSubtypes: string read GetMemoSubtypes write SetMemoSubtypes;
  end;

  (* TFIBTransaction *)

  TTransactionAction  =
   (TARollback, TARollbackRetaining,TACommit, TACommitRetaining);
  TTransactionState   =
  (tsActive,tsClosed,tsDoRollback,tsDoRollbackRetaining,tsDoCommit, tsDoCommitRetaining);

  TTransactionRunState=(trsInLoaded);
  TTransactionRunStates=set of TTransactionRunState;

  TpFIBTrEventType =(tetBeforeStartTransaction,tetAfterStartTransaction,
   tetBeforeEndTransaction,tetAfterEndTransaction,tetBeforeDestroy);

  TEndTrEvent=procedure(EndingTR:TFIBTransaction;
   Action: TTransactionAction; Force: Boolean)of object;

  TFIBTransaction = class(TComponent,IFIBTransaction)
  protected
    FCanTimeout         : Boolean;                      // Can the transaction timeout now?
    FDatabases          : TList;                        // TDatabases in transaction.
    FFIBBases           : TList;                        // TFIBBases  attached.
    FDefaultDatabase    : TFIBDatabase;                 // just like DefaultTransaction in FIBDatabase
    FHandle             : TISC_TR_HANDLE;               // TR's handle
    FHandleIsShared     : Boolean;
    FOnTimeout          : TNotifyEvent;                 // When the transaction times out...
    FStreamedActive     : Boolean;
    FTPB                : PAnsiChar;                        // Parameters to TR as passed to IB.
    FTPBLength          : Short;                        // Length of parameter buffer
    FTimer              : TFIBTimer;                       // Timer for timing out transactions.
    FTimeoutAction      : TTransactionAction;           // Rollback or commit at end of timeout?
    FTRParams           : TStrings;                     // Parameters to Transactions.
    FTRParamsChanged    : Boolean;
    FState              : TTransactionState;
    FTransactionID      : integer;
    vOnDestroy          : TNotifyEventList;
    vBeforeStartTransaction : TNotifyEventList;
    vAfterStartTransaction  : TNotifyEventList;

    vBeforeEndTransaction : TCallBackList;
    vAfterEndTransaction  : TCallBackList;
    vTRParams             : array of Ansistring;
    vTPBArray             : array of Ansistring;
    FTransactionRunStates :TTransactionRunStates;
    FHasUncommitedUpdates :boolean;
    FWatchUpdates         :boolean;
{$IFDEF CSMonitor}
    FCSMonitorSupport: TCSMonitorSupport;
    procedure SetCSMonitorSupport(Value:TCSMonitorSupport);    
{$ENDIF}
    function  GetTransactionID: integer;
    function  DoStoreActive:boolean;
    procedure EndTransaction(Action: TTransactionAction; Force: Boolean); virtual;
    // End the transaction using specified method...
    function GetDatabase(Index: Integer): TFIBDatabase; // Get the indexed database
    function GetDatabaseCount: Integer;                 // Get the number of databases in transaction
    function GetFIBBase(Index: Integer): TFIBBase; // Get the indexed Dataset.
    function GetFIBBasesCount: Integer;                  // Get the number of Datasets connected.
    function GetInTransaction: Boolean;                 // Is there an active trans?
    function GetTimeout: Cardinal;

    procedure Loaded; override;
    procedure SetActive(Value: Boolean);
    procedure SetDefaultDatabase(Value: TFIBDatabase);
    procedure SetHandle(Value: TISC_TR_HANDLE);
    procedure SetTimeout(Value: Cardinal);               // Set the timeout
    procedure SetTRParams(Value: TStrings);
    procedure TimeoutTransaction(Sender: TObject);
    procedure TRParamsChange(Sender: TObject);
    procedure TRParamsChanging(Sender: TObject);
    procedure RemoveDatabases;
{$IFDEF USE_DEPRECATE_METHODS1}
    procedure RemoveDataSet(Idx: Integer); deprecated;
    procedure RemoveDataSets;  deprecated;
    function  AddDataSet(ds: TFIBBase): Integer; deprecated;
{$ENDIF}
    procedure RemoveFIBBase(Idx: Integer);
    procedure RemoveFIBBases;
    function  AddFIBBase(ds: TFIBBase): Integer;

    procedure CreateTimeoutTimer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;

    function  MainDatabase:TFIBDatabase;
    function  FindDatabase(db: TFIBDatabase): Integer;
    procedure AddEvent(Event:TNotifyEvent;EventType:TpFIBTrEventType);
    procedure RemoveEvent(Event:TNotifyEvent;EventType:TpFIBTrEventType);

    procedure AddEndEvent(Event:TEndTrEvent;EventType:TpFIBTrEventType);
    procedure RemoveEndEvent(Event:TEndTrEvent;EventType:TpFIBTrEventType);

    procedure DoOnSQLExec(Query:TComponent;Kind:TKindOnOperation); virtual;

    function  AddDatabase(db: TFIBDatabase): Integer; overload;
    function  AddDatabase(db: TFIBDatabase; const aTRParams: string): Integer; overload;     
    procedure RemoveDatabase(Idx: Integer);
    procedure ReplaceDatabase(dbOld,dbNew: TFIBDatabase);


    procedure OnDatabaseDisconnecting(DB: TFIBDatabase);

    function  Call(ErrCode: ISC_STATUS; RaiseError: Boolean): ISC_STATUS;
    procedure CheckDatabasesInList;        // Raise error if no databases in list.
    procedure CheckInTransaction;          // Raise error if not in transaction
    procedure CheckNotInTransaction;       // Raise error if in transaction
    procedure StartTransaction; virtual;
    procedure Commit;           virtual;
    procedure CommitRetaining;  virtual;
    procedure Rollback;         virtual;
    procedure RollbackRetaining;virtual;
    procedure ExecSQLImmediate(const SQLText:Widestring);
    procedure SetSavePoint(const SavePointName:string);
    procedure RollBackToSavePoint(const SavePointName:string);
    procedure ReleaseSavePoint(const SavePointName:string);
    procedure CloseAllQueryHandles;
    function IsReadCommitedTransaction:boolean;
    function IsReadOnly:boolean;
    property DatabaseCount: Integer read GetDatabaseCount;
    property Databases[Index: Integer]: TFIBDatabase read GetDatabase;
{$IFDEF USE_DEPRECATE_METHODS1}
    property DataSetCount: Integer read GetFIBBasesCount;  //deprecated;
    property DataSets[Index: Integer]: TFIBBase read GetFIBBase;  //deprecated;
{$ENDIF}
    property FIBBaseCount: Integer read GetFIBBasesCount;
    property FIBBases[Index: Integer]: TFIBBase  read GetFIBBase;

    property Handle: TISC_TR_HANDLE read FHandle write SetHandle;
    property HandleIsShared: Boolean read FHandleIsShared;
    property InTransaction: Boolean read GetInTransaction;
//    property TPB: PChar read FTPB;
//    property TPBLength: Short read FTPBLength;
    property State: TTransactionState read FState;
    property TransactionID: integer read GetTransactionID;
    property HasUncommitedUpdates :boolean read FHasUncommitedUpdates ;

  published
    property Active: Boolean read GetInTransaction write SetActive stored DoStoreActive;
    property DefaultDatabase: TFIBDatabase read FDefaultDatabase
                                           write SetDefaultDatabase;
    property Timeout: Cardinal read GetTimeout write SetTimeout default 0;
    property TimeoutAction: TTransactionAction read FTimeoutAction write FTimeoutAction default TARollback;
    property TRParams: TStrings read FTRParams write SetTRParams;
    // Events
    property OnTimeout: TNotifyEvent read FOnTimeout write FOnTimeout;
    property WatchUncommitedUpdates :boolean read FWatchUpdates write FWatchUpdates default false;
{$IFDEF CSMonitor}
    property CSMonitorSupport: TCSMonitorSupport read FCSMonitorSupport  write SetCSMonitorSupport;
{$ENDIF}
  end;

  (* TFIBBase *)
  (* Virtually all components in FIB are "descendents" of TFIBBase. *)
  (* It is to more easily manage the database and transaction *)
  (* connections. *)
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
    OnDatabaseFree: TNotifyEvent;
    OnTransactionEnding: TNotifyEvent;
    OnTransactionEnded: TNotifyEvent;
    OnTransactionStarting: TNotifyEvent;
    OnTransactionStarted: TNotifyEvent;

    OnTransactionFree: TNotifyEvent;
    property Database: TFIBDatabase read FDatabase
                                    write SetDatabase;
    property DBHandle: PISC_DB_HANDLE read GetDBHandle;
    property Owner: TObject read FOwner;
    property TRHandle: PISC_TR_HANDLE read GetTRHandle;
    property Transaction: TFIBTransaction read FTransaction
                                          write SetTransaction;
  end;


procedure SaveSchemaToFile(const FileName:string);
function  LoadSchemaFromFile(const FileName:string; const NeedValidate:boolean=True;
 DB:TFIBDatabase=nil
):boolean;


procedure IBFilterBuffer(DataBase:TFIBDataBase;
   var BlobBuffer:PAnsiChar;var BlobSize:longint; BlobSubType:integer;ForEncode: boolean
);

function ExistBlobFilter(DataBase:TFIBDataBase;BlobSubType:integer):boolean;

function  GetConnectedDataBase(const DBName:string ):TFIBDatabase;
procedure CloseAllDatabases;


procedure AssignSQLObjectParams(Dest: ISQLObject; ParamSources : array of ISQLObject);

const
    OCTETS_CHARSET_ID=1;

var DefDataBase        :TFIBDatabase;
    DatabaseList       :TThreadList;
    FIBHideGrantError  :boolean = False;



implementation

uses
{$IFNDEF NO_MONITOR}
  FIBSQLMonitor,
{$ENDIF}
{$IFDEF D_XE3}
  System.Types, // for inline funcs
{$ENDIF}
  FIBMiscellaneous,pFIBDataInfo,FIBQuery, StrUtil,pFIBCacheQueries, FIBConsts;


var
    vConnectCS: TCriticalSection;

procedure AssignSQLObjectParams(Dest: ISQLObject; ParamSources : array of ISQLObject);
var
  i: Integer;
  j: Integer;
  k: Integer;
  c: Integer;
  pName:string;
  OldValue:boolean;
begin
  if Dest=nil then
   Exit;    
  c:=Pred(Dest.ParamCount);
  for i := 0 to c do
  begin
   pName:=Dest.ParamName(i);
    OldValue:=False;
   if IsNewParamName(pName) then
    pName:=FastCopy(pName,5,MaxInt)
   else
   if IsOldParamName(pName) then
   begin
    pName:=FastCopy(pName,5,MaxInt);
    OldValue:=True;
   end;
   for j := Low(ParamSources) to High(ParamSources) do
    if Assigned(ParamSources[j]) then
     if ParamSources[j].FieldExist(pName,k) then
     begin
      Dest.SetParamValue(i,ParamSources[j].FieldValue(k,OldValue))
     end
     else
     if ParamSources[j].ParamExist(Dest.ParamName(i),k) then
     begin
      Dest.SetParamValue(i,ParamSources[j].ParamValue(k))
     end;
  end;
end;



function  GetConnectedDataBase(const DBName:string ):TFIBDatabase;
var i:integer;
begin
 Result:=nil;
 with DatabaseList.LockList do
 try
  for I := 0 to Count - 1 do
   if (TFIBDatabase(Items[i]).DBName=DBName)and (TFIBDatabase(Items[i]).Connected)
   then
   begin
     Result:=TFIBDatabase(Items[i]);
     Break;
   end;
  finally
   DatabaseList.UnLockList
  end;
end;

procedure CloseAllDatabases;
var i:integer;
begin
 with DatabaseList.LockList do
 try
   for i:=0 to Count-1 do
   begin
    if TFIBDatabase(Items[i]).Connected then
     TFIBDatabase(Items[i]).ForceClose
   end;
  finally
   DatabaseList.UnLockList
  end;
end;


procedure IBFilterBuffer(DataBase:TFIBDataBase;
                        var BlobBuffer:PAnsiChar;var BlobSize:longint;
                        BlobSubType:integer;ForEncode: boolean);
begin
  if DataBase.FBlobFilters=nil then
   Exit;
  DataBase.FBlobFilters.IBFilterBuffer(BlobBuffer,BlobSize,BlobSubType,ForEncode);
end;

function ExistBlobFilter(DataBase:TFIBDataBase;BlobSubType:integer):boolean;
var
 anIndex:integer;
begin
  if Assigned(DataBase.FBlobFilters) then
   Result:=DataBase.FBlobFilters.Find(BlobSubType,anIndex)
  else
   Result:=False
end;

procedure SaveSchemaToFile(const FileName:string);
begin
  ListTableInfo.SaveToFile(FileName);
  ListDataSetInfo.SaveToFile(ChangeFileExt(FileName,'.dt'));
  ListErrorMessages.SaveToFile(ChangeFileExt(FileName,'.err'));
end;

function LoadSchemaFromFile(const FileName:string; const NeedValidate:boolean=True;
 DB:TFIBDatabase=nil
):boolean;
begin
  Result:=ListTableInfo.LoadFromFile(FileName,DB);
  ListTableInfo.NeedValidate:=NeedValidate;
  ListDataSetInfo.LoadFromFile(ChangeFileExt(FileName,'.dt'));
  ListDataSetInfo.NeedValidate:=NeedValidate;
  ListErrorMessages.LoadFromFile(ChangeFileExt(FileName,'.err'));
end;

(* TFIBDatabase *)

constructor TFIBDatabase.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLibraryName  := IBASE_DLL;
  FClientLibrary:= nil;
  FFIBBases                            := TList.Create;
  FTransactions                        := TList.Create;
  FDBName                              := '';
  FDBParams                            := TDBParams.Create(Self);
  FDBParamsChanged                     := True;
  TStringList(FDBParams).OnChange      := DBParamsChange;
  TStringList(FDBParams).OnChanging    := DBParamsChanging;

{$IFDEF CSMonitor}
  FCSMonitorSupport := TCSMonitorSupport.Create(Self);
{$ENDIF}  

  FConnectParams  := TConnectParams.Create(Self);
  FDifferenceTime := 0;

  if (csDesigning in ComponentState)   and   not CmpInLoadedState(Self)
  then
  begin
   FSynchronizeTime      :=DefSynchronizeTime;
   FUpperOldNames        :=DefUpperOldNames  ;
   FUseLoginPrompt       :=DefUseLoginPrompt ;
   FConnectParams.CharSet:=DefCharSet;
   FSQLDialect           :=DefSQLDialect;
   if DefStoreConnected then
    FDesignDBOptions     := [ddoStoreConnected]
   else
    FDesignDBOptions     := []
  end
  else
  begin
   FSynchronizeTime      :=True ;
   FUpperOldNames        :=False;
   FUseLoginPrompt       :=False;
   FSQLDialect           :=1;
   FDesignDBOptions      := [ddoStoreConnected]
  end;


  vInternalTransaction:=TFIBTransaction.Create(Self);
  vInternalTransaction.DefaultDataBase:=Self;
  vInternalTransaction.TimeoutAction:=taCommit;
  vInternalTransaction.Timeout      :=1000;

  with vInternalTransaction.TRParams do
  begin
   Text:='write'+#13#10+
         'isc_tpb_nowait'+#13#10+
         'read_committed'+#13#10+
         'rec_version'+#13#10
         ;
  end;
  DatabaseList.Add(Self);
  vOnConnected     :=TNotifyEventList.Create(Self);
  vBeforeDisconnect:=TNotifyEventList.Create(Self);
  vOnDestroy       :=TNotifyEventList.Create(Self);

  vAttachmentID    :=-1;
  FActiveTransactions:=nil;
//  FBlobFilters     :=TIBBlobFilters.Create;
  FUseRepositories :=[urFieldsInfo,urDataSetInfo,urErrorMessagesInfo] ;
  FDBFileName      :='';
  FConnectType     :=0;
  FBlobSwapSupport:=TBlobSwapSupport.Create;

  FGenerators:=TGeneratorsCache.Create(Self);
  FMemoSubtypes:=TMemoSubtypes.Create;
end;

destructor TFIBDatabase.Destroy;
var
  i: Integer;
begin
  Connected:=false;

{$IFDEF CSMonitor}
  FCSMonitorSupport.Free;
{$ENDIF}
  if Assigned(FTimer) then
   SetTimeOut(0);
//    FTimer.Enabled:=False;

  if Assigned(DatabaseList) then
   DatabaseList.Remove(Self);
  if Assigned(vInternalTransaction) then
  with vInternalTransaction do
  begin
    if Active then Commit;
    Free; vInternalTransaction:=nil;
  end;
  if DefDataBase=Self then
    DefDataBase:=nil;


   Timeout := 0;
   if FHandle <> nil then ForceClose;
   for i := Pred(vOnDestroy.Count) downto 0 do
    vOnDestroy.Event[i](Self);

   // Tell Dataset's we're being freed.
   for i := FFIBBases.Count - 1 downto 0 do if FFIBBases[i] <> nil then
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

   if Assigned(FBlobFilters) then
    FBlobFilters     .Free;

   FBlobSwapSupport.Free;
   FGenerators.Free;
   FMemoSubtypes.Free;
   FClientLibrary:=nil;
   inherited Destroy;
end;

procedure TFIBDatabase.SetLibraryName(const LibName:string);
begin
  {$IFNDEF FIBPLUS_TRIAL}
  CheckInactive;
  if FLibraryName<>LibName then
  begin
    FLibraryName  :=LibName;
    FClientLibrary:=nil;
    FClientLibLoaded := False;
{    if Length(FLibraryName)>0 then
     LoadLibrary}
  end;
  {$ELSE}
   ShowMessage('Trial version can''t change library name');
  {$ENDIF}
end;


{$IFDEF D_XE2}
function  TFIBDatabase.StoredLibraryName64:boolean;
begin
  Result:=Trim(FLibraryName64)<>''
end;
{$ENDIF}

function  TFIBDatabase.StoredLibraryName:boolean;
begin
  Result:=FLibraryName<>IBASE_DLL
end;

procedure TFIBDatabase.SetGenerators(Value:TGeneratorsCache);
begin
 FGenerators.Assign(Value)
end;

function TFIBDatabase.GetMemoSubtypes :string;
begin
  Result:=FMemoSubtypes.Subtypes
end;

procedure TFIBDatabase.SetMemoSubtypes(const Value:string);
begin
//  FMemoSubtypes.Assign(Value);
   FMemoSubtypes.Subtypes:=Value
end;

function TFIBDatabase.MemoSubTypesActive:boolean;
begin
  Result:=FMemoSubtypes.Active
end;

function TFIBDatabase.IsMemoSubtype(aSubtype: ShortInt):boolean;
begin
  Result:=FMemoSubtypes.IsMemoSubtype(aSubType)
end;

function TFIBDatabase.LibraryFilePath:string;
begin
  if Assigned(FClientLibrary) then
   Result:=FClientLibrary.LibraryFilePath
  else
   Result:=FLibraryName
end;


procedure TFIBDatabase.SetDesignDBOptions(Value:TDesignDBOptions);
begin
 FDesignDBOptions:=Value;
 if ddoIsDefaultDatabase in FDesignDBOptions then
 begin
   if (DefDataBase<>nil) and (DefDataBase<>Self) then
   with DefDataBase do
    FDesignDBOptions:=FDesignDBOptions-[ddoIsDefaultDatabase];
   if not (csLoading in ComponentState) then
    DefDataBase:=Self
 end
 else
 if DefDataBase=Self then DefDataBase:=nil
end;

function  TFIBDatabase.GetStoreConnected:boolean;
begin
  Result:=Connected and
   (ddoStoreConnected in FDesignDBOptions)
end;

function TFIBDatabase.Call(ErrCode: ISC_STATUS;
  RaiseError: Boolean): ISC_STATUS;
begin
  Set8087CW(Default8087CW);
  Result := ErrCode;
//  FCanTimeout := False;
  if Assigned(FTimer) and FTimer.Enabled then
  begin
   FTimer.Enabled:=False;
   FTimer.Enabled:=True;
   FLastActiveTime:=FIBGetTickCount;
  end;
  if RaiseError and (ErrCode > 0) then
    IBError(Self,Self);
end;

procedure TFIBDatabase.CheckActive(TryReconnect:boolean=False);
var OldUseLoginPrompt:boolean;
begin
  if FStreamedConnected and (not Connected) then
    Loaded;
  if FHandle = nil then
   if not (csDesigning in ComponentState) and not FAutoReconnect  then
   begin
     FIBError(feDatabaseClosed, [CmpFullName(Self)])
   end
   else
     if not Connected and (TryReconnect  or FAutoReconnect) then
     begin
      OldUseLoginPrompt:=FUseLoginPrompt;
      FUseLoginPrompt  :=(ConnectParams.Password='');
      try
       Connected:=true;
      except
       if not FUseLoginPrompt then
       try
        FUseLoginPrompt  :=true;
        Connected:=True;
       except
       end;
      end;
      FUseLoginPrompt:=OldUseLoginPrompt;
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
{$WARNINGS OFF}
function TFIBDatabase.AddDataSet(ds: TFIBBase): Integer;
begin
  Result:=AddFIBBase(ds);
end;
{$WARNINGS ON}
{$ENDIF}

function  TFIBDatabase.AddFIBBase(ds: TFIBBase): Integer;
begin
 Result := FFIBBases.Count;
 FFIBBases.Add(ds)
end;



procedure TFIBDatabase.RegisterBlobFilter(BlobSubType:integer;
                                 EncodeProc,DecodeProc:PIBBlobFilterProc);
begin
 if not Assigned(FBlobFilters) then
  FBlobFilters     :=TIBBlobFilters.Create;
  
 FBlobFilters.RegisterBlobFilter(BlobSubType,EncodeProc,DecodeProc);
end;

procedure TFIBDatabase.RemoveBlobFilter(BlobSubType:integer);
begin
 if Assigned(FBlobFilters) then
  FBlobFilters.RemoveBlobFilter(BlobSubType)
end;

procedure TFIBDatabase.SaveAlias;
begin
  //abstract
end;

procedure TFIBDatabase.IBFilterBuffer(var BlobBuffer:PAnsiChar;var BlobSize:longint;
                        BlobSubType:integer;ForEncode: boolean);
begin
 if Assigned(FBlobFilters) then
  FBlobFilters.IBFilterBuffer(BlobBuffer,BlobSize,BlobSubType,ForEncode);
end;

procedure TFIBDatabase.RemoveEvent(Event:TNotifyEvent;EventType:TpFIBDBEventType);
begin
 case EventType of
  detOnConnect       :  vOnConnected.Remove(Event);
  detBeforeDisconnect:  vBeforeDisconnect.Remove(Event);
  detBeforeDestroy   :  vOnDestroy.Remove(Event);
 end;
end;

procedure  TFIBDatabase.AddEvent(Event:TNotifyEvent;EventType:TpFIBDBEventType);
begin
 case EventType of
  detOnConnect       :  vOnConnected.Add(Event);
  detBeforeDisconnect:  vBeforeDisconnect.Add(Event);
  detBeforeDestroy   :  vOnDestroy.Add(Event);
 end
end;

procedure TFIBDatabase.DoBeforeDisconnect;
var i:integer;
begin
  try
   if Assigned(FBeforeDisconnect) then FBeforeDisconnect(Self);
  except
   on E:Exception do
   if csDestroying in ComponentState then
    raise Exception.Create(
      Format(SFIBErrorBeforeDisconnectDetail, [CmpFullName(Self), E.Message])
    )
   else
    raise Exception.Create(
      Format(SFIBErrorBeforeDisconnect, [CmpFullName(Self), E.Message])
    )
  end;

  with vBeforeDisconnect do
  for i:=0 to Pred(Count) do
  begin
    vBeforeDisconnect.Event[i](Self)
  end;
end;

procedure TFIBDatabase.DoAfterDisconnect;
begin
  try
   if Assigned(FAfterDisconnect) then FAfterDisconnect(Self);
  except
   on E:Exception do
   if csDestroying in ComponentState then
    raise Exception.Create(
      Format(SFIBErrorAfterDisconnectDetail, [CmpFullName(Self), E.Message])
    )
   else
    raise Exception.Create(
      Format(SFIBErrorAfterDisconnect, [CmpFullName(Self), E.Message])
    )
  end;
end;

procedure TFIBDatabase.DoOnConnect;
var
 i:integer;
 vMajorVersion:Integer;
begin
//  LoadLibrary;
  FIsFireBirdConnect:=GetIsFirebirdConnect;
  vMajorVersion:=ServerMajorVersion;
  if not  FIsFireBirdConnect then
   FIsIB2007Connect:=vMajorVersion>=8;

  if not FIsFireBirdConnect or (vMajorVersion<2) then
  begin
    FIsUnicodeConnect:=(FConnectParams.CharSet='UNICODE_FSS')  or  (FConnectParams.CharSet='UTF8');
    FIsNoneConnect   :=(FConnectParams.CharSet='NONE') or (FConnectParams.CharSet='');
    FNeedUnicodeFieldsTranslation:=FIsUnicodeConnect or FIsNoneConnect;
    FNeedUTFDecodeDDL:=False;
{$IFDEF SUPPORT_KOI8_CHARSET}
    FIsKOI8Connect:=False;
{$ENDIF}
  end
  else
  begin
    FIsUnicodeConnect:=FBAttachCharsetID in UnicodeCharSets;
    FIsNoneConnect   :=FBAttachCharsetID =0;
    FNeedUnicodeFieldsTranslation:=FIsUnicodeConnect or FIsNoneConnect;

    FIsFB21OrMore :=(vMajorVersion>2) or ((vMajorVersion=2) and  (GetServerMinorVersion>=1));

    if FNeedUnicodeFieldsTranslation then
    begin
     if FIsFB21OrMore   and ((GetODSMajorVersion>11) or ((GetODSMajorVersion=11) and (GetODSMinorVersion>=1)))
     then
      FNeedUTFDecodeDDL:=True
     else
      FNeedUTFDecodeDDL:=False
    end
    else
      FNeedUTFDecodeDDL:=False;

  {$IFDEF SUPPORT_KOI8_CHARSET}
      FIsKOI8Connect:=FBAttachCharsetID in [chFBKOI8R,chFBKOI8U]
  {$ENDIF}
  end;

  if not (csDesigning in ComponentState) then
   if FBlobSwapSupport.Active and FBlobSwapSupport.AutoValidateSwap and (Length(FBlobSwapSupport.SwapDirectory)>0) then
    ValidateBlobCacheDirectory(Self);

  if Assigned(FOnConnect) then FOnConnect(Self);
  with vOnConnected do
  for i:=0 to Pred(Count) do
  begin
    if not Connected then
     Break;
    vOnConnected.Event[i](Self)
  end;
end;

function TFIBDatabase.AddTransaction(TR: TFIBTransaction): Integer;
begin
  Result := 0;
  while (Result < FTransactions.Count) and (FTransactions[Result] <> nil)
     and (FTransactions[Result] <> TR) //    AddedSource
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
  vAttachmentID:=-1;
  vInternalTransaction.Timeout      :=0;  
end;

procedure TFIBDatabase.CreateDatabase;
var
  tr_handle: TISC_TR_HANDLE;
begin
  // Create database interprets the DBParams string list
  // as mere text. It makes it extremely simple to do this way.
  CheckInactive; // Make sure the database ain't connected.
  LoadLibrary;
  tr_handle := nil;
  Call(
    FClientLibrary.isc_dsql_execute_immediate(StatusVector, @FHandle, @tr_handle, 0,
     PAnsiChar('CREATE DATABASE ''' + FDBName + ''' ' +AnsiString(DBParams.Text)
    ), SQLDialect, nil),
    True
  );

  FServerMajorVersion:=-1; 
  FServerMinorVersion:=-1;
  FServerBuild       :=-1;

  FIsFirebirdConnect:=GetIsFirebirdConnect;
  if  FIsFirebirdConnect and (ServerMajorVersion>=2) then
  begin
      FIsUnicodeConnect:=FBAttachCharsetID in UnicodeCharsets;
      FNeedUnicodeFieldsTranslation:=FIsUnicodeConnect
       or     (FBAttachCharsetID=0);
       ;

      if FNeedUnicodeFieldsTranslation then
      begin
       if (
        (GetServerMajorVersion>2) or ((GetServerMajorVersion=2) and (GetServerMinorVersion>=1))
         ) and ((GetODSMajorVersion>11) or ((GetODSMajorVersion=11) and (GetODSMinorVersion>=1)))
       then
        FNeedUTFDecodeDDL:=True
       else
        FNeedUTFDecodeDDL:=False
      end
      else
        FNeedUTFDecodeDDL:=False;
  end
end;

procedure TFIBDatabase.DropDatabase;
begin
  CheckActive;
  LoadLibrary;
  Call(FClientLibrary.isc_drop_database(StatusVector, @FHandle), True);
  FHandle:=nil
end;

// Set up the FDPBBuffer correctly.
procedure TFIBDatabase.DBParamsChange(Sender: TObject);
begin
  FDBParamsChanged := True;
end;

procedure TFIBDatabase.DBParamsChanging(Sender: TObject);
begin
  if not (csDesigning in ComponentState) then
   CheckInactive;
end;

function TFIBDatabase.FindTransaction(TR: TFIBTransaction): Integer;
begin
  Result := FTransactions.IndexOf(TR);
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
  Result := FFIBBases.Count;
end;

function TFIBDatabase.GetDBParamByDPB(const Idx: Integer): string;
var
  ConstIdx, EqualsIdx: Integer;
begin
  if (Idx > 0) and (Idx <= isc_dpb_last_dpb_constant) then
  begin
    ConstIdx := IndexOfDBConst(DPBConstantNames[Idx]);
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
  Result := FTransactions.Count;
end;

function TFIBDatabase.GetActiveTransactionCount: Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to Pred(FTransactions.Count) do
   if (FTransactions[i] <> nil) and
    TFIBTransaction(FTransactions[i]).InTransaction then
    Inc(Result);
end;


function TFIBDatabase.GetFirstActiveTransaction: TFIBTransaction;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Pred(FTransactions.Count) do
   if (FTransactions[i] <> nil) and TFIBTransaction(FTransactions[i]).InTransaction
    and ((TFIBTransaction(FTransactions[i]).DatabaseCount<2) or (TFIBTransaction(FTransactions[i]).DefaultDatabase=Self))
   then
   begin
     Result:=TFIBTransaction(FTransactions[i]);
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
      break;
    end;
  end;
end;

(*
 * InternalClose -
 *  Close the database connection and all other
 *  attached components that the database
 *  connection is terminating.
 *)
procedure TFIBDatabase.InternalClose(Force: Boolean;DBinShutDown:boolean);
var
  i: Integer;
begin
  (*
   * Check that the database connection is active.
   *)
  CheckActive;
  DoBeforeDisconnect;
  (*
   * Tell all connected transactions that we're disconnecting.
   * This is so transactions can commit/rollback, accordingly
   *)

  for i := 0 to FTransactions.Count - 1 do
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
  for i := 0 to FFIBBases.Count - 1 do
  try
    if FFIBBases[i] <> nil then
     FIBBases[i].FOnDatabaseDisconnecting;
  except
    if not Force then
     raise;
  end;

  (*
   * Disconnect..., and if the force parameter is true, guarantee that
   * the handle is reset to nil.
   *)

    try
      if (not HandleIsShared) and
         (Call(FClientLibrary.isc_detach_database(StatusVector, @FHandle), not Force) > 0) and
         (not Force)
      then
        IbError(Self,Self)
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
  if MonitoringEnabled  then
   if MonitorHook<>nil then
    MonitorHook.DBDisconnect(Self);
{$ENDIF}
  (*
   * Tell all attached components (TFIBBase's) that we have
   * disconnected.
   *)
  for i := 0 to FFIBBases.Count - 1 do
  if FFIBBases[i] <> nil then
    FIBBases[i].FOnDatabaseDisconnected;
  DoAfterDisconnect;
 if Assigned(FSQLLogger) then
  FSQLLogger.WriteData(CmpFullName(Self),'Disconnect','',lfConnect);

end;


{$IFDEF CSMonitor}
procedure TFIBDatabase.SetCSMonitorSupport(Value:TCSMonitorSupport);
begin
 FCSMonitorSupport.Assign(Value)
end;
{$ENDIF}


procedure TFIBDatabase.Loaded;
begin
  inherited Loaded;
  if ddoIsDefaultDatabase in FDesignDBOptions then
    DefDataBase:=Self;
  try
    vInternalTransaction.Name:=Name+'_InternalTransaction';
    if FStreamedConnected and (not Connected) then
    begin
      FStreamedConnected := False;
      Open;
      if Connected then
       if (FDefaultTransaction <> nil) and
         (FDefaultTransaction.FStreamedActive) and
         (not FDefaultTransaction.InTransaction) then
        FDefaultTransaction.StartTransaction;
    end;
  except
    on E:Exception do
    begin
      if not (csDesigning in ComponentState) then
        raise
      else
      begin
        FStreammedConnectFail:=True;
        ShowException(E,nil);
      end;
    end;
  end;
end;

function TFIBDatabase.Login: Boolean;
var
  IndexOfUser, IndexOfPassword,IndexOfRole: Integer;
  Username, Password,RoleName: string;
  XDBName: string;
begin
  if not Assigned(pFIBLoginDialog) then
  begin
   if not Assigned(pFIBLoginDialog) then
    if csDesigning in ComponentState then
     raise Exception.Create(SFIBErrorNoDBLoginDialog + SFIBErrorInstallPropertyEditorPackage)
    else
     raise Exception.Create(SFIBErrorNoDBLoginDialog + SFIBErrorIncludeDBLoginDialog);
  end;

  IndexOfUser := IndexOfDBConst(DPBConstantNames[isc_dpb_user_name]);
  if IndexOfUser <> -1 then
    Username := FastCopy(DBParams[IndexOfUser],
                                       PosCh('=', DBParams[IndexOfUser]) + 1,
                                       Length(DBParams[IndexOfUser]));
  IndexOfPassword := IndexOfDBConst(DPBConstantNames[isc_dpb_password]);
  if IndexOfPassword <> -1 then
    Password := FastCopy(DBParams[IndexOfPassword],
                                       PosCh('=', DBParams[IndexOfPassword]) + 1,
                                       Length(DBParams[IndexOfPassword]));
  IndexOfRole:= IndexOfDBConst(DPBConstantNames[isc_dpb_sql_role_name]);
  if IndexOfRole<>-1 then
    RoleName := FastCopy(DBParams[IndexOfRole],
                                       PosCh('=', DBParams[IndexOfRole]) + 1,
                                       Length(DBParams[IndexOfRole]));
    XDBName := DBName;

  Result := pFIBLoginDialog(XDBName, Username, Password,RoleName);
  if Result then
  begin
      if IndexOfUser = -1 then
        DBParams.Add(DPBConstantNames[isc_dpb_user_name] + '=' + Username)
      else
        DBParams[IndexOfUser] := DPBConstantNames[isc_dpb_user_name] +
                                 '=' + Username;
      if IndexOfPassword = -1 then
        DBParams.Add(DPBConstantNames[isc_dpb_password] + '=' + Password)
      else
        DBParams[IndexOfPassword] := DPBConstantNames[isc_dpb_password] +
                                     '=' + Password;
      if IndexOfRole=-1 then
        DBParams.Add(DPBConstantNames[isc_dpb_sql_role_name] + '=' + RoleName)
      else
        DBParams[IndexOfRole] := DPBConstantNames[isc_dpb_sql_role_name] +
                                     '=' + RoleName;
  end;
end;

procedure TFIBDatabase.Online;
var
   oldParams,u,p:string;
begin
 oldParams:=DBParams.Text;
 try
   u:=ConnectParams.UserName;
   p:=ConnectParams.Password;
   if Connected then Close;
   DBParams.Clear;
   ConnectParams.UserName:=u;
   ConnectParams.Password:=p;
   DBParams.Add('online');
   Open;
   Close;
 finally
  DBParams.Text:=oldParams;
 end;
end;


procedure TFIBDatabase.ShutDown(const ShutParams:array of integer; Delay:integer=0);
var
   oldParams,u,p:string;
   i,L:integer;
begin
{Valid values of ShutParams:
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
 oldParams:=DBParams.Text;
 try
   u:=ConnectParams.UserName;
   p:=ConnectParams.Password;
   if Connected then Close;
   DBParams.Clear;
   ConnectParams.UserName:=u;
   ConnectParams.Password:=p;
   L:=Length(ShutParams);
   if L=0 then
     DBParams.Add('shutdown')
   else
   begin
    u:='shutdown=';
    for i:=0 to L-1 do
     u:=u+IntToStr(ShutParams[i])+',';
    SetLength(u,Length(u)-1);
    DBParams.Add(u);
   end;
   if Delay>0 then
    DBParams.Add('shutdown_delay='+IntToStr(Delay));
   Open;
   Close;
 finally
  DBParams.Text:=oldParams;
 end;
end;

(*
 * Open -
 *  Open a database connection.
 *)


procedure TFIBDatabase.Open(RaiseExcept:boolean = True);
const
  S_OK = 0;

var
  DPB: AnsiString;
  isc_res:ISC_STATUS;
  i: Integer;
  SV: PISC_STATUS;
begin
  // isc_res:=0;
  (*
   * Check that the database is *not* active, and that it
   * has a database name
   *)
  FServerMajorVersion:=-1;
  FServerMinorVersion:=-1;
  FServerBuild       :=-1;
  vConnectCS.Acquire;
//  EnterCriticalSection(vConnectCS);
  try
   CheckInactive;
   CheckDatabaseName;
   LoadLibrary;
  (*
   * Use the canned login prompt if requested.
   *)
  for i := 0 to FFIBBases.Count - 1 do
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
       GenerateDPB(FDBParams, DPB, FDPBLength,FConnectParams.IsFirebird);
       FIBAlloc(FDPB, 0, FDPBLength);
       Move(DPB[1], FDPB[0], FDPBLength);
     end;
     (*
      * Attach to the database, and raise an IB error if
      * the statement doesn't execute correctly.
      *)
     SV:=StatusVector;
     isc_res:=Call(FClientLibrary.isc_attach_database(SV, Length(FDBName),
                            PAnsiChar(FDBName), @FHandle,
                            FDPBLength, FDPB), False);
  finally
   vConnectCS.Release
//   LeaveCriticalSection(vConnectCS);
  end;

  if isc_res > 0 then
  begin
    FHandle := nil;
    if RaiseExcept then
     IbError(Self,Self)
    else
     Exit;
  end;
  vInternalTransaction.Timeout      :=1000;  
  FStreammedConnectFail:=False;
  AttachmentID;
  DPB:=FDPB;

{$IFNDEF NO_MONITOR}
  if MonitoringEnabled  then
   if MonitorHook<>nil then
    MonitorHook.DBConnect(Self);
{$ENDIF}
  FDifferenceTime:=0;
  if DBSQLDialect<SQLDialect then FSQLDialect:=DBSQLDialect;
  if FSynchronizeTime and not (csDesigning in ComponentState) then
   FDifferenceTime:=Now-GetServerTime;
  FConnectType:=0;
  DoOnConnect;
  for i := 0 to FFIBBases.Count - 1 do
  begin
    if not Connected then  Break;
      FIBBases[i].FOnDatabaseConnected;
  end;
 if Assigned(FSQLLogger) then
  FSQLLogger.WriteData(CmpFullName(Self),'Connect','',lfConnect);
end;

function  TFIBDatabase.GetServerTime:TDateTime;
begin
  if FSQLDialect<2 then
    Result:=QueryValue('SELECT CAST(''NOW'' AS DATE) from RDB$DATABASE',0)
  else
    Result:=QueryValue('SELECT CAST(''NOW'' AS TIMESTAMP) from RDB$DATABASE',0)
end;

{$IFDEF USE_DEPRECATE_METHODS1}
{$WARNINGS OFF}
procedure TFIBDatabase.RemoveDataSet(Idx: Integer);
begin
  RemoveFIBBase(Idx);
end;
{$WARNINGS ON}
{$ENDIF}

procedure TFIBDatabase.RemoveFIBBase(Idx: Integer);
var
  ds: TFIBBase;
begin
  if (Idx >= 0) and (FFIBBases[Idx] <> nil) then
  begin
    ds := FIBBases[Idx];
    ds.FDatabase := nil;
    if Idx<FFIBBases.Count-1 then
    begin
     ds := FFIBBases[FFIBBases.Count-1];
     FFIBBases[Idx]:=ds;
     ds.FIndexInDatabase:=Idx;
     FFIBBases.Delete(FFIBBases.Count-1);
    end
    else
     FFIBBases.Delete(Idx);
  end;
end;
{$IFDEF USE_DEPRECATE_METHODS1}
{$WARNINGS OFF}
procedure TFIBDatabase.RemoveDataSets;
begin
 RemoveFIBBases
end;
{$WARNINGS ON}
{$ENDIF}

procedure TFIBDatabase.RemoveFIBBases;
var
  i: Integer;
begin
  for i := FFIBBases.Count - 1 downto 0 do
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
    if TR.FDefaultDatabase=Self then TR.FDefaultDatabase:=nil;
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
  for i := Pred(FTransactions.Count) downto  0 do
   if FTransactions[i] <> nil then
    RemoveTransaction(i);
end;

procedure TFIBDatabase.LoadLibrary;
var
  XLibraryName: Ansistring;
begin
   {$IFDEF D_XE2}
       {$IFDEF WIN64}
         if (FLibraryName<>FLibraryName64) and (Trim(FLibraryName64)<>'') then
          FLibraryName:=FLibraryName64;
       {$ENDIF}
   {$ENDIF}
   if not FClientLibLoaded then
   begin
    XLibraryName:=FLibraryName;
    FClientLibrary:=IB_Intf.GetClientLibrary(XLibraryName);
    FClientLibLoaded:=Assigned(FClientLibrary);
   end;
   if not FClientLibrary.LibraryLoaded then
    FClientLibrary.LoadIBLibrary
end;

procedure TFIBDatabase.SetConnected(Value: Boolean);
begin
  if csReading in ComponentState then
    FStreamedConnected := Value
  else
  if Value then
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
  FDBFileName:=''
end;

procedure TFIBDatabase.SetDBParamByName(const ParName,Value: string);
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
begin
  SetDBParamByName(DPBConstantNames[Idx],Value);
end;

procedure TFIBDatabase.SetDBParams(Value: TDBParams);
begin
  FDBParams.Assign(Value);
end;

procedure TFIBDatabase.SetDefaultTransaction(Value: TFIBTransaction);
begin
  if  (FDefaultTransaction <> Value) then
  if Assigned(Value) then
  begin
    Value.AddDatabase(Self);
    AddTransaction(Value);
    if not Assigned(Value.FDefaultDatabase) then
      Value.FDefaultDatabase:=Self;
  end;
  FDefaultTransaction := Value;
end;

procedure TFIBDatabase.SetDefaultUpdateTransaction(Value: TFIBTransaction);
begin
  if  (FDefaultUpdateTransaction <> Value) then
  if Assigned(Value) then
  begin
    Value.AddDatabase(Self);
    AddTransaction(Value);
    if not Assigned(Value.FDefaultDatabase) then
      Value.FDefaultDatabase:=Self;
  end;
  FDefaultUpdateTransaction  := Value;
end;


procedure TFIBDatabase.CreateTimeoutTimer;
begin
  if not Assigned(FTimer) then
  begin
    FTimer:= TFIBTimer.Create(Self);
    with FTimer do
    begin
      Enabled   := False;
      Interval  := 0;
      OnTimer   := TimeoutConnection;
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
      FTimer:=nil
    end;
  end
  else
  if (Value > 0) then
  begin
    CreateTimeoutTimer;
    FTimer.Interval := Value;
    if not (csDesigning in ComponentState) then
      FTimer.Enabled := True;
  end;
end;

procedure TFIBDatabase.SetHandle(Value: TISC_DB_HANDLE);
begin
  if HandleIsShared then
    Close
  else
    CheckInactive;
  FHandle := Value;
  FHandleIsShared := (Value <> nil);
  if FHandleIsShared then
  begin
   LoadLibrary;
   DoOnConnect
  end;
end;

function TFIBDatabase.TestConnected: Boolean;
begin
  Result := Connected;
  if Result then
  try
    if BaseLevel = 0 then ; // who cares
  except
    ForceClose;
    Result := False;
  end;
end;

procedure TFIBDatabase.TimeoutConnection(Sender: TObject);
var
    ai:TActionOnIdle;
begin
  if Connected then
    begin
      if Assigned(FOnIdleConnect) then
      begin
       ai:=aiCloseConnect;
       FOnIdleConnect(Self,FIBGetTickCount-FLastActiveTime,ai);
       if ai=aiKeepLiveConnect then
        Exit;
      end;
      ForceClose;
      if Assigned(FOnTimeout) then  FOnTimeout(Self);
    end
end;

function  TFIBDatabase.ClientVersion:string;
var p:PAnsiChar;
begin
 LoadLibrary;
 GetMem(p,100);
 try
  FClientLibrary.isc_get_client_version(p);
  Result:=p;
 finally
  FreeMem(p,100)
 end
end;

function  TFIBDatabase.ClientMajorVersion:integer;
begin
  LoadLibrary;
  Result:=FClientLibrary.ClientVersion
end;

function  TFIBDatabase.ClientMinorVersion:integer;
begin
  LoadLibrary;
  Result:=FClientLibrary.ClientMinorVersion
end;

function  TFIBDatabase.GetIsFirebirdConnect :boolean;
begin
  Result:= GetFBVersion<>''
end;

function  TFIBDatabase.IsFirebirdConnect :boolean;
begin
 Result:=FIsFireBirdConnect
end;

function  TFIBDatabase.IsIB2007Connect   :boolean;
begin
 Result:= not FIsFirebirdConnect;
 if Result then
 begin
  Result:= ServerMajorVersion>=8
 end;
end;

function  TFIBDatabase.NeedUTFEncodeDDL  :boolean;
begin
// For FB2.1 and more
     Result:=FNeedUTFDecodeDDL;
end;



function  TFIBDatabase.NeedUnicodeFieldsTranslation  :boolean;
begin
 if not Connected then
  Result:=(FConnectParams.CharSet='UNICODE_FSS') or
   (FConnectParams.CharSet='NONE') or
   (FConnectParams.CharSet='UTF8') or
   (FConnectParams.CharSet='')
 else
  Result:=FNeedUnicodeFieldsTranslation;
end;

function  TFIBDatabase.NeedUnicodeFieldTranslation(FieldCharacterSet:integer)  :boolean;
begin
  if FNeedUTFDecodeDDL or FIsNoneConnect then
   Result:= (FieldCharacterSet in UnicodeCharSets)
  else
  if FIsUnicodeConnect then
   Result:=not (FieldCharacterSet in [0,OCTETS_CHARSET_ID]) // OCTETS,NONE
  else
   Result:=False
end;

function  TFIBDatabase.IsUnicodeConnect  :boolean;
begin
 if not Connected then
  Result:=(FConnectParams.CharSet='UNICODE_FSS') or  (FConnectParams.CharSet='UTF8')
 else
  Result:=FIsUnicodeConnect;
end;

{$IFDEF SUPPORT_KOI8_CHARSET}
function  TFIBDatabase.IsKOI8Connect  :boolean;
begin
 if not Connected then
  Result:=(FConnectParams.CharSet='KOI8R') or  (FConnectParams.CharSet='KOI8U')
 else
  Result:=FIsKOI8Connect;
end;
{$ENDIF}

function  TFIBDatabase.GetContextVariable(ContextSpace:TFBContextSpace;const VarName:string
;aTransaction:TFIBTransaction=nil
):Variant;
var
   NameSpace:string ;
begin
  case ContextSpace of
      csSystem      :NameSpace:='SYSTEM';
      csSession     :NameSpace:='USER_SESSION';
      csTransaction :NameSpace:='USER_TRANSACTION';
  end;

  if IsFirebirdConnect  and (GetServerMajorVersion>=2) then
  begin
    Result:=
     QueryValue('Select rdb$get_context(:NameSpace,:VarName) from rdb$database',
      0,[NameSpace,VarName],aTransaction
     );
    if VarType(Result)=varBoolean then
     Result := null;
  end
  else
   FIBError(feFB2feature,['"rdb$get_context"']);
end;


procedure TFIBDatabase.SetContextVariable(ContextSpace:TFBContextSpace;const VarName,VarValue:string
;aTransaction:TFIBTransaction=nil
);
var
   NameSpace:string ;
begin
  if IsFirebirdConnect  and (GetServerMajorVersion>=2) then
  begin
     case ContextSpace of
      csSystem      :NameSpace:='SYSTEM';
      csSession     :NameSpace:='USER_SESSION';
      csTransaction :NameSpace:='USER_TRANSACTION';
     end;
     QueryValue(
     'Execute block (NameSpace varchar(80) =:N,'#13#10+
      'VarName varchar(80) =:V,  VarValue  varchar(80) =:VV) as '#13#10+
     'begin'#13#10+
      ' rdb$set_context(:NameSpace,:VarName,:VarValue);'#13#10+
     'end',
      -1,[NameSpace,VarName,VarValue],aTransaction
     );
  end
  else
    FIBError(feFB2feature,['"rdb$set_context"']);
end;

//FB2.5
procedure TFIBDatabase.EnableCancelOperations;
begin
 CheckActive;
 Call(FClientLibrary.fb_cancel_operation(StatusVector,@FHandle,fb_cancel_enable),True);
end;

procedure TFIBDatabase.DisableCancelOperations;
begin
 CheckActive;
 Call(FClientLibrary.fb_cancel_operation(StatusVector,@FHandle,fb_cancel_disable),True);
end;

function  TFIBDatabase.CanCancelOperationFB21:boolean;
begin
  Result:= IsFirebirdConnect and  (ServerMajorVersion>=2) and    (ServerMinorVersion>=1) ;  
end;

procedure TFIBDatabase.CancelOperationFB21(ConnectForCancel:TFIBDatabase=nil);
var
   NeedCreateConnect:boolean;
begin
 if Busy then
 begin
    if CanCancelOperationFB21 then
    begin
     NeedCreateConnect:=(ConnectForCancel=nil) or ConnectForCancel.Busy;
     if NeedCreateConnect  then
     begin
      ConnectForCancel:=TFIBDatabase.Create(Self);
      ConnectForCancel.DBName:=DBName;
      ConnectForCancel.DBParams.Assign(DBParams);
      ConnectForCancel.LibraryName:=LibraryName;
      ConnectForCancel.Connected:=True;
     end;
     try
      if not ConnectForCancel.Connected then
       ConnectForCancel.Connected:=True;
      ConnectForCancel.Execute('DELETE FROM MON$STATEMENTS WHERE MON$STATE=1 AND MON$ATTACHMENT_ID='+IntToStr(AttachmentID));
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
  Call(FClientLibrary.fb_cancel_operation(StatusVector,@FHandle,fb_cancel_raise),True);
end;


function TFIBDatabase.UnicodeCharSets:TIBCharSets;
begin
 Result:=[3];     // UNICODE_FSS
// Include(Result,4)    // UTF8
 if Connected then
  if FIsFirebirdConnect then
   Include(Result,4)    // UTF8
  else
  if FIsIB2007Connect then
   Result:=Result+[59,8,64]    // UTF8,UNICODE_BE,UNICODE_LE
end;

function TFIBDatabase.BytesInUnicodeChar(CharSetId:integer):Byte;
begin
 Result:=1; 
 if CharSetId=3 then
  Result:=3     // UNICODE_FSS
 else
 if Connected then
  if FIsFirebirdConnect then
  begin
   if CharSetId=4 then
    Result:=4    // UTF8
  end
  else
  if FIsIB2007Connect then
  begin
   case CharSetId of
    8,64: Result:=2; //UNICODE_BE,UNICODE_LE
    59  : Result:=4;// UTF8
   end;
  end;
end;

function TFIBDatabase.ReturnDeclaredFieldSize:boolean;
begin
  Result:=True;
  if Connected then
   if IsFirebirdConnect and (ServerMajorVersion>=2) then
    Result:=False;
end;

(* Database Info procedures -- Advanced stuff (translated from isc_database_info) *)
function TFIBDatabase.GetAllocation: Long;
begin
  Result := GetLongDBInfo(isc_info_allocation);
end;

function TFIBDatabase.GetBaseLevel: Long;
var
  local_buffer: array[0..FIBLocalBufferLength - 1] of AnsiChar;
  DBInfoCommand: AnsiChar;
begin
  CheckActive;
  DBInfoCommand := AnsiChar(isc_info_base_level);
  Call(ClientLibrary.isc_database_info(StatusVector, @FHandle, 1, @DBInfoCommand,
                         FIBLocalBufferLength, local_buffer), True);
  Result := FClientLibrary.isc_vax_integer(@local_buffer[4], 1);
end;

function TFIBDatabase.GetDBFileName: Ansistring;
var
  local_buffer: array[0..FIBLocalBufferLength - 1] of AnsiChar;
  DBInfoCommand: AnsiChar;
begin
  if FDBFileName='' then
  begin
    CheckActive;
    DBInfoCommand := AnsiChar(isc_info_db_id);
    Call(FClientLibrary.isc_database_info(StatusVector, @FHandle, 1, @DBInfoCommand,
                           FIBLocalBufferLength, local_buffer), True);
    local_buffer[5 + Int(local_buffer[4])] := #0;
    Result := PAnsiChar(@local_buffer[5]);
    FDBFileName := Result
  end
  else
    Result:=FDBFileName
end;

function TFIBDatabase.GetDBSiteName: Ansistring;
var
  local_buffer: array[0..FIBBigLocalBufferLength - 1] of AnsiChar;
  p: PAnsiChar;
  DBInfoCommand: AnsiChar;
begin
  CheckActive;
  DBInfoCommand := AnsiChar(isc_info_db_id);
  Call(FClientLibrary.isc_database_info(StatusVector, @FHandle, 1, @DBInfoCommand,
                        FIBLocalBufferLength, local_buffer), True);
  p := @local_buffer[5 + Int(local_buffer[4])]; // DBSiteName Length
  p := p + Int(p^) + 1;                         // End of DBSiteName
  p^ := #0;                                     // Null it.
  Result := PAnsiChar(@local_buffer[6 + Int(local_buffer[4])]);
end;

function TFIBDatabase.GetIsRemoteConnect: boolean;
var
  local_buffer: array[0..FIBBigLocalBufferLength - 1] of AnsiChar;
  DBInfoCommand: AnsiChar;
begin
  CheckActive;
  if FConnectType=0 then
  begin
    DBInfoCommand := AnsiChar(isc_info_db_id);
    Call(FClientLibrary.isc_database_info(StatusVector, @FHandle, 1, @DBInfoCommand,
                          FIBLocalBufferLength, local_buffer), True);
    FConnectType:=Int(local_buffer[3]);
  end;
  Result:=FConnectType=4
end;

function TFIBDatabase.GetActiveTransactions: TStringList; // isc_info_active_transactions
var
  local_buffer: array[0..FIBBigLocalBufferLength - 1] of AnsiChar;
  DBInfoCommand: AnsiChar;
  i:integer;
  L:integer;
begin
  CheckActive;
  if FActiveTransactions=nil then FActiveTransactions:=TStringList.Create;
  Result:=FActiveTransactions;
  FActiveTransactions.Clear;

  DBInfoCommand := AnsiChar(frb_info_active_transactions);
  Call(FClientLibrary.isc_database_info(StatusVector, @FHandle, 1, @DBInfoCommand,
                        FIBLocalBufferLength, local_buffer), True);
  i:=0;

  while local_buffer[i] = AnsiChar(frb_info_active_transactions) do
  begin
    Inc(i,3);
    L      :=FClientLibrary.isc_vax_integer(@local_buffer[i], 4);
    Result .Add(IntToStr(L));
    Inc(i,4);
  end;
end;

function TFIBDatabase.GetFBVersion: string; //frb_info_firebird_version
var
  local_buffer: array[0..FIBBigLocalBufferLength - 1] of AnsiChar;
  DBInfoCommand: AnsiChar;
begin
  CheckActive;
  DBInfoCommand := AnsiChar(frb_info_firebird_version);
  Call(FClientLibrary.isc_database_info(StatusVector, @FHandle, 1, @DBInfoCommand,
                        FIBLocalBufferLength, local_buffer), True);
  if DBInfoCommand=local_buffer[0] then
  begin
   local_buffer[5 + Int(local_buffer[4])] := #0;
   Result:= PAnsiChar(@local_buffer[5]);
  end
  else
   Result:= '';
end;

function TFIBDatabase.GetAttachCharset:Integer;               // frb_info_att_charset
var
  Success:boolean ;
begin
 Result:=GetProtectLongDBInfo(frb_info_att_charset,Success);
 if not Success then
  Result := -1
end;

procedure TFIBDatabase.FillServerVersions;
var
   VersionStr: string;
   tmpstr:string;
   i:integer;
   PVersion:PInteger;
begin
 CheckActive;
 if FServerMajorVersion=-1 then
 begin
   if IsFirebirdConnect then
     VersionStr:=FBVersion
   else
     VersionStr:=Version;
   tmpStr:='';
   i:=5;
   PVersion:=@FServerMajorVersion;
   while i< Length(VersionStr)  do
   begin
     if VersionStr[i] in ['0'..'9'] then
      tmpStr:=tmpStr+VersionStr[i]
     else
     begin
      if Length(tmpStr)>0 then
       PVersion^:=StrToInt(tmpStr)
      else
       PVersion^:=0;
      tmpStr:=''; 
      if PVersion=@FServerMajorVersion then
       PVersion:=@FServerMinorVersion
      else
      if PVersion=@FServerMinorVersion then
       PVersion:=@FServerRelease
      else
      if PVersion=@FServerRelease then
       PVersion:=@FServerBuild
      else
       Break;
     end;
     Inc(i);
   end;
 end;
end;

function TFIBDatabase.GetServerMajorVersion: integer;
begin
 FillServerVersions;
 Result:=FServerMajorVersion;
end;


function TFIBDatabase.GetServerMinorVersion: integer;
begin
 FillServerVersions;
 Result:=FServerMinorVersion;
end;

function TFIBDatabase.GetInternalTransaction:TFIBTransaction;
begin
 Result:=vInternalTransaction
end;

function TFIBDatabase.GetServerBuild: integer;
begin
 FillServerVersions;
 Result:=FServerBuild;
end;

function TFIBDatabase.GetServerRelease: integer;
begin
 FillServerVersions;
 Result:=FServerRelease;
end;

function TFIBDatabase.GetDBImplementationNo: Long;
var
  local_buffer: array[0..FIBLocalBufferLength - 1] of AnsiChar;
  DBInfoCommand: AnsiChar;
begin
  CheckActive;
  DBInfoCommand := AnsiChar(isc_info_implementation);
  Call(FClientLibrary.isc_database_info(StatusVector, @FHandle, 1, @DBInfoCommand,
                        FIBLocalBufferLength, local_buffer), True);
  Result := FClientLibrary.isc_vax_integer(@local_buffer[3], 1);
end;

function TFIBDatabase.GetOldestTransaction: Long;
var
  Success:boolean;
begin
 Result:=GetProtectLongDBInfo(frb_info_oldest_transaction,Success);
end;

function TFIBDatabase.GetOldestActive: Long;
var
  Success:boolean;
begin
 Result:=GetProtectLongDBInfo(frb_info_oldest_active,Success);
end;

function TFIBDatabase.GetOldestSnapshot: Long;
var
  Success:boolean;
begin
 Result:=GetProtectLongDBInfo(frb_info_oldest_snapshot,Success);
end;


function TFIBDatabase.GetDBImplementationClass: Long;
var
  local_buffer: array[0..FIBLocalBufferLength - 1] of AnsiChar;
  DBInfoCommand: AnsiChar;
begin
  DBInfoCommand := AnsiChar(isc_info_implementation);
  Call(FClientLibrary.isc_database_info(StatusVector, @FHandle, 1, @DBInfoCommand,
                         FIBLocalBufferLength, local_buffer), True);
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

function TFIBDatabase.GetPageSize: Long;
begin
  Result := GetLongDBInfo(isc_info_page_size);
end;

function TFIBDatabase.GetVersion: string;
var
  local_buffer: array[0..FIBBigLocalBufferLength - 1] of AnsiChar;
  DBInfoCommand: AnsiChar;
begin
  DBInfoCommand := AnsiChar(isc_info_version);

  Call(FClientLibrary.isc_database_info(StatusVector, @FHandle, 1, @DBInfoCommand,
                        FIBBigLocalBufferLength, local_buffer), True);
  local_buffer[5 + Int(local_buffer[4])] := #0;
  Result := PAnsiChar(@local_buffer[5]);
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
  local_buffer: array[0..FIBHugeLocalBufferLength - 1] of AnsiChar;
  temp_buffer: array[0..FIBLocalBufferLength - 2] of AnsiChar;
  DBInfoCommand: AnsiChar;
  i, user_length: Integer;
begin
  if FUserNames = nil then FUserNames := TStringList.Create;
  Result := FUserNames;
  DBInfoCommand := AnsiChar(isc_info_user_names);
  Call(FClientLibrary.isc_database_info(StatusVector, @FHandle, 1, @DBInfoCommand,
                        FIBHugeLocalBufferLength, local_buffer), True);
  FUserNames.Clear;
  i := 0;
  while local_buffer[i] = AnsiChar(isc_info_user_names) do
  begin
    Inc(i, 3);
    // skip "isc_info_user_names byte" & two unknown bytes of structure (see below)
    user_length := Long(local_buffer[i]);
    Inc(i,1);
    Move(local_buffer[i], temp_buffer[0], user_length);
    Inc(i, user_length);
    temp_buffer[user_length] := #0;
    FUserNames.Add(Ansistring(temp_buffer));
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
  local_buffer: array[0..FIBHugeLocalBufferLength - 1] of AnsiChar;
  _DBInfoCommand: AnsiChar;
  i, qtd_tables, id_table, qtd_operations: Integer;
begin
  if FOperation = nil then FOperation := TStringList.Create;
  Result := FOperation;
  _DBInfoCommand := AnsiChar(DBInfoCommand);
  Call(FClientLibrary.isc_database_info(StatusVector, @FHandle, 1, @_DBInfoCommand,
                         FIBHugeLocalBufferLength, local_buffer), True);
  FOperation.Clear;
  // 1. 1 byte specifying the item type requested (e.g., isc_info_insert_count).
  // 2. 2 bytes telling how many bytes compose the subsequent value pairs.
  // 3. A pair of values for each table in the database on wich the requested
  //    type of operation has occurred since the database was last attached.
  // Each pair consists of:
  // 1. 2 bytes specifying the table ID.
  // 2. 4 bytes listing the number of operations (e.g., inserts) done on that table.
  qtd_tables := trunc(FClientLibrary.isc_vax_integer(@local_buffer[1],2)/6);
  for i := 0 to qtd_tables - 1 do
  begin
    id_table := FClientLibrary.isc_vax_integer(@local_buffer[3+(i*6)],2);
    qtd_operations := FClientLibrary.isc_vax_integer(@local_buffer[5+(i*6)],4);
    FOperation.Add(IntToStr(id_table)+'='+IntToStr(qtd_operations));
  end;
end;

function TFIBDatabase.GetAllModifications:integer;
var
  local_buffer: array[0..FIBHugeLocalBufferLength - 1] of AnsiChar;
  _DBInfoCommand: AnsiChar;
  i, qtd_tables: Integer;
  j:byte;
begin
  Result := 0;
  for j:=isc_info_insert_count to isc_info_delete_count do
  begin
    _DBInfoCommand:=AnsiChar(j);
    Call(FClientLibrary.isc_database_info(StatusVector, @FHandle, 1, @_DBInfoCommand,
                           FIBHugeLocalBufferLength, local_buffer), True);
    // 1. 1 byte specifying the item type requested (e.g., isc_info_insert_count).
    // 2. 2 bytes telling how many bytes compose the subsequent value pairs.
    // 3. A pair of values for each table in the database on wich the requested
    //    type of operation has occurred since the database was last attached.
    // Each pair consists of:
    // 1. 2 bytes specifying the table ID.
    // 2. 4 bytes listing the number of operations (e.g., inserts) done on that table.
    qtd_tables := trunc(FClientLibrary.isc_vax_integer(@local_buffer[1],2)/6);
    for i := 0 to qtd_tables - 1 do
    begin
      Inc(Result,FClientLibrary.isc_vax_integer(@local_buffer[5+(i*6)],4));
    end;
  end;
end;

function TFIBDatabase.GetBackoutCount: TStringList;
begin
 if FBackoutCount=nil then FBackoutCount:=TStringList.Create;
  Result := GetOperationCounts(isc_info_backout_count,FBackoutCount);
end;

function TFIBDatabase.GetDeleteCount: TStringList;
begin
 if FDeleteCount=nil then FDeleteCount:=TStringList.Create;
  Result := GetOperationCounts(isc_info_delete_count,FDeleteCount);
end;

function TFIBDatabase.GetExpungeCount: TStringList;
begin
 if FExpungeCount=nil then FExpungeCount:=TStringList.Create;
  Result := GetOperationCounts(isc_info_expunge_count,FExpungeCount);
end;

function TFIBDatabase.GetInsertCount: TStringList;
begin
 if FInsertCount=nil then FInsertCount:=TStringList.Create;
  Result := GetOperationCounts(isc_info_insert_count,FInsertCount);
end;


function TFIBDatabase.GetPurgeCount: TStringList;
begin
 if FPurgeCount=nil then FPurgeCount:=TStringList.Create;
  Result := GetOperationCounts(isc_info_purge_count,FPurgeCount);
end;

function TFIBDatabase.GetReadIdxCount: TStringList;
begin
 if FReadIdxCount=nil then
  FReadIdxCount:=TStringList.Create;
 Result := GetOperationCounts(isc_info_read_idx_count,FReadIdxCount);
end;

function TFIBDatabase.GetTableOperationInfo(const TableName:string; FromStrs:TStrings):integer;
var
   vTableID:integer;
   tmpStr:string;
begin
   vTableID:=ListTableInfo.GetTableInfo(Self, TableName, False).TableID[Self];
   tmpStr:=FromStrs.Values[IntToStr(vTableID)];
   if Length(tmpStr) > 0 then
    Result:=StrToInt(tmpStr)
   else
    Result := 0;
end;

function TFIBDatabase.GetIndexedReadCount(const TableName:string):integer;
begin
   GetReadIdxCount;
   Result:=GetTableOperationInfo(TableName,FReadIdxCount)
end;

function TFIBDatabase.GetNonIndexedReadCount(const TableName:string):integer;
begin
  GetReadSeqCount;
  Result:=GetTableOperationInfo(TableName,FReadSeqCount)
end;

function TFIBDatabase.GetInsertsCount(const TableName:string):integer;
begin
  GetInsertCount;
  Result:=GetTableOperationInfo(TableName,FInsertCount)
end;

function TFIBDatabase.GetUpdatesCount(const TableName:string):integer;
begin
  GetUpdateCount;
  Result:=GetTableOperationInfo(TableName,FUpdateCount)
end;

function TFIBDatabase.GetDeletesCount(const TableName:string):integer;
begin
  GetDeleteCount;
  Result:=GetTableOperationInfo(TableName,FDeleteCount)
end;

function TFIBDatabase.GetReadSeqCount: TStringList;
begin
 if FReadSeqCount=nil then FReadSeqCount:=TStringList.Create;
  Result := GetOperationCounts(isc_info_read_seq_count,FReadSeqCount);
end;

function TFIBDatabase.GetUpdateCount: TStringList;
begin
 if FUpdateCount=nil then FUpdateCount:=TStringList.Create;
  Result := GetOperationCounts(isc_info_update_count,FUpdateCount);
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

function TFIBDatabase.GetProtectLongDBInfo
 (DBInfoCommand: Integer;var Success:boolean): Long;
var
  local_buffer: array[0..FIBLocalBufferLength - 1] of AnsiChar;
  length: Integer;
  _DBInfoCommand: AnsiChar;
begin
  _DBInfoCommand := AnsiChar(DBInfoCommand);
  Call(FClientLibrary.isc_database_info(StatusVector, @FHandle, 1, @_DBInfoCommand,
                         FIBLocalBufferLength, local_buffer), True);
  Success:=local_buffer[0] = _DBInfoCommand;
  length := FClientLibrary.isc_vax_integer(@local_buffer[1], 2);
  Result := FClientLibrary.isc_vax_integer(@local_buffer[3], length);

end;

function TFIBDatabase.GetLongDBInfo(DBInfoCommand: Integer): Long;
var Success:boolean;
begin
  Result := GetProtectLongDBInfo(DBInfoCommand,Success)
end;

function TFIBDatabase.GetStringDBInfo(DBInfoCommand: Integer): string;
var
  local_buffer: array[0..FIBBigLocalBufferLength - 1] of AnsiChar;
  _DBInfoCommand: AnsiChar;
begin
  _DBInfoCommand := AnsiChar(DBInfoCommand);
  Call(FClientLibrary.isc_database_info(StatusVector, @FHandle, 1, @_DBInfoCommand,
                         FIBBigLocalBufferLength, local_buffer), True);
  local_buffer[4 + Int(local_buffer[3])] := #0;
  Result := PAnsiChar(@local_buffer[4]);
end;

function TFIBDatabase.GetAttachmentID  :Long;
begin
 if vAttachmentID=-1 then
 begin
  if FHandle=nil then
   Result    :=-1
  else
  begin
    Result:= GetLongDBInfo(isc_info_attachment_id);
    vAttachmentID:=Result;
  end;
 end
 else
  Result:= vAttachmentID;
end;

//Wrappers DBParams

//IB6
function TFIBDatabase.GetDBSQLDialect:Word;
var Success:boolean;
begin
 Result:=GetProtectLongDBInfo(isc_info_db_SQL_dialect,Success);
 if not Success then Result:=1
end;


procedure TFIBDatabase.SetSQLDialect(const Value: Integer);
begin
  if (Value < 1) then FIBError(feSQLDialectInvalid, [nil]);
  if (FHandle = nil) then
    FSQLDialect := Value
  else
  if Value<=DBSQLDialect then
   FSQLDialect := Value
  else
   FIBError(feSQLDialectInvalid, [nil])
end;

function TFIBDatabase.GetSQLDialect:Integer;
begin
 Result:=FSQLDialect
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

function TFIBDatabase.EasyFormatsStr :boolean;
begin
 Result := (SQLDialect<3) or UpperOldNames;
end;

function TFIBDatabase.QueryValueAsStr(const aSQL: string;FieldNo:integer): string;
var
   v:Variant;
begin
 v:=QueryValue(aSQL,FieldNo,nil,true);
 if VarIsNull(v) then
  Result:=''
 else
  Result:=VarAsType(v,varString)
end;

function TFIBDatabase.QueryValueAsStr(const aSQL: string;FieldNo:integer;
        ParamValues:array of variant):string;
var
    v:Variant;
begin
 v:=QueryValue(aSQL,FieldNo,ParamValues,nil,true);
 if VarIsNull(v) then
  Result:=''
 else
  Result:=VarAsType(v,varString)
end;

function TFIBDatabase.InternalQueryValue(const aSQL: string;FieldNo:integer;
  ParamValues:array of variant; aTransaction:TFIBTransaction;aCacheQuery:boolean):Variant;
var Query: TFIBQuery;
    i    :integer;
    c    :integer;

begin
  Result := False;
  if Assigned(aTransaction) then
   Query :=GetQueryForUse(aTransaction,aSQL)
  else
   Query :=GetQueryForUse(vInternalTransaction,aSQL);
  with Query.Params do
   if High(ParamValues)<Count-1 then
    c:=High(ParamValues)
   else
    c:=Count-1;

  with Query do
  try
    if not Transaction.Active then
      Transaction.StartTransaction;
    try
     for i:=0 to c do
      if not VarIsEmpty(ParamValues[i])   then
       Params[i].Value:=ParamValues[i];
     ExecQuery;
     if (Current.Count>0) then
      if (FieldNo>=0) then
      begin
       if Fields[FieldNo].SQLType = SQL_BLOB then
        Result := Fields[FieldNo].AsString
       else
        Result := Fields[FieldNo].Value
      end
      else
      begin
        c:= Pred(Current.Count);
        Result:=VarArrayCreate([0,c],varVariant);
        for i:=0 to c do
         if Fields[i].SQLType = SQL_BLOB then
          Result[i] := Fields[i].AsString
         else
          Result[i] := Fields[i].Value
      end;
    except
     if Transaction.Active then
      Transaction.RollBack;
     raise;
    end
  finally
     if Transaction.InTransaction and (aTransaction=nil) then
      Transaction.Commit;
     if c<0 then
      Query.Free
     else
     if aCacheQuery then
      FreeQueryForUse(Query)
     else
      Query.Free
  end;
end;

function TFIBDatabase.QueryValue(const aSQL: string;FieldNo:integer;aTransaction:TFIBTransaction=nil;
 aCacheQuery:boolean=True):Variant;
begin
 Result := InternalQueryValue(aSQL,FieldNo, [varEmpty],aTransaction,aCacheQuery);
end;


function TFIBDatabase.QueryValue(const aSQL: string;FieldNo:integer;
          ParamValues:array of variant;aTransaction:TFIBTransaction=nil;
aCacheQuery:boolean=True):Variant;
begin
  Result := InternalQueryValue(aSQL,FieldNo, ParamValues,aTransaction,aCacheQuery);
end;

function TFIBDatabase.QueryValues(const aSQL: string;aTransaction:TFIBTransaction=nil;aCacheQuery:boolean=True):Variant;
begin
  Result:= InternalQueryValue(aSQL,-1,[varEmpty],aTransaction,aCacheQuery);
end;

function TFIBDatabase.QueryValues(const aSQL: string;  ParamValues:array of variant;aTransaction:TFIBTransaction=nil;aCacheQuery:boolean=True):Variant;
begin
  Result:= InternalQueryValue(aSQL,-1, ParamValues,aTransaction,aCacheQuery);
end;

function TFIBDatabase.Execute(const SQL: string): boolean;
begin
 try
  QueryValue(SQL,-1,nil,true);
  Result:= True
 except
  Result := False;
 end;
end;

procedure  TFIBDatabase.ClearQueryCacheList;
begin
 pFIBCacheQueries.ClearQueryCacheList(Self)
end;

procedure TFIBDatabase.CreateGUIDDomain;
begin
  Execute('CREATE DOMAIN TGUID AS CHAR(16) CHARACTER SET OCTETS');
end;

function TFIBDatabase.Gen_Id(const GeneratorName: string; Step: Int64;aTransaction:TFIBTransaction =nil): Int64;
var Query: TFIBQuery;
    GenName :string;
    vTransaction:TFIBTransaction;
    ForceOpenTr:boolean;
    NeedSaveGenCache:boolean;
begin
  GenName := EasyFormatIdentifier(SQLDialect, GeneratorName,EasyFormatsStr);
  if FGenerators.CanWork(GenName) and (Step=1) then
  begin
    Result:=FGenerators.GetNextValue(GenName);
    if Result<>-1 then
     Exit;
    NeedSaveGenCache:=True;
    Step:=FGenerators.GetStep(GenName)
  end
  else
   NeedSaveGenCache:=False;

  vTransaction:=FirstActiveTransaction;
  if vTransaction=nil then
   if aTransaction<>nil then
    vTransaction:=aTransaction
   else
    vTransaction:=vInternalTransaction;

  Query :=GetQueryForUse(vTransaction,
    'select gen_id(' + GenName + ', ' + IntToStr(Step) +') from RDB$DATABASE'
  );
  with Query, Transaction do
  try
    ForceOpenTr:=not Transaction.InTransaction;
    if ForceOpenTr then  StartTransaction;
    ExecQuery;
    Result := Fields[0].AsInt64;
   if ForceOpenTr then  Commit;
  finally
   FreeQueryForUse(Query);
  end;
  if NeedSaveGenCache then
  begin
    FGenerators.InternalSetGenParams(GenName,Result);
    Result:=FGenerators.GetNextValue(GenName)
  end;
end;



procedure TFIBDatabase.SetBlobSwapSupport(const Value: TBlobSwapSupport);
begin
  FBlobSwapSupport.Assign(Value);
end;

procedure TFIBDatabase.SetSQLLogger(const Value: ISQLLogger);
begin
  if Assigned(Value) then
  begin
   Value.SetDatabase(Self);
   if (Value.GetInstance is TComponent) then
    TComponent(Value.GetInstance).FreeNotification(Self);
  end;

  FSQLLogger := Value;
end;

procedure TFIBDatabase.SetSQLStatMaker(const Value: ISQLStatMaker);
begin
  FSQLStatMaker := Value;
end;


procedure TFIBDatabase.Notification(AComponent: TComponent;
  Operation: TOperation);
var
   I:IUnknown;
begin
  if Operation=opRemove then
   if Supports(AComponent,ISQLLogger,I) then
   begin
     if I=FSQLLogger then
      FSQLLogger:=nil;
   end;
  inherited;
end;


function TFIBDatabase.GetBusy: boolean;
begin
 if Assigned(FClientLibrary) then
  Result:=FClientLibrary.Busy
 else
  Result:=False
end;

(* TFIBTransaction *)

constructor TFIBTransaction.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
{$IFDEF CSMonitor}
  FCSMonitorSupport := TCSMonitorSupport.Create(Self);
{$ENDIF}  
  
  FDatabases                           := TList.Create;
  FFIBBases                           := TList.Create;
  FHandle                              := nil;
  FTPB                                 := nil;
  FTPBLength                           := 0;
  FTRParams                            := TStringList.Create;
  FTRParamsChanged                     := True;
  TStringList(FTRParams).OnChange      := TRParamsChange;
  TStringList(FTRParams).OnChanging    := TRParamsChanging;
  FTimer                               := nil;
  FState                               := tsClosed;
  FTransactionID                       := 0;
  if (csDesigning in ComponentState)   and not CmpInLoadedState(Self)
  then
  begin
   FTimeOutAction := TTransactionAction(DefTimeOutAction);
   TimeOut        :=0;
   DefaultDataBase:=DefDataBase;
  end
  else
  begin
   FTimeOutAction :=taRollBack;
   TimeOut        :=DefTimeOut;
  end;
  vOnDestroy          := TNotifyEventList.Create(Self);
  vBeforeStartTransaction := TNotifyEventList.Create(Self);
  vAfterStartTransaction  := TNotifyEventList.Create(Self);

  vBeforeEndTransaction := TCallBackList.Create(Self);;
  vAfterEndTransaction  := TCallBackList.Create(Self);;
end;

destructor TFIBTransaction.Destroy;
var
  i: Integer;
begin
  if InTransaction then
  case FTimeoutAction of
    TARollbackRetaining: EndTransaction(TARollback, True);
    TACommitRetaining  : EndTransaction(TACommit, True);  
  else
   EndTransaction(FTimeoutAction, True);
  end;
  for i := Pred(vOnDestroy.Count) downto 0 do
   vOnDestroy.Event[i](Self);
  for i := FFIBBases.Count - 1 downto 0 do
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
  SetLength(vTRParams,0);
  SetLength(vTPBArray,0);
  inherited Destroy;
end;

{$IFDEF CSMonitor}
procedure TFIBTransaction.SetCSMonitorSupport(Value:TCSMonitorSupport);
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
      Enabled  := False;
      Interval := 0;
      OnTimer  := TimeoutTransaction;
    end;
  end;
end;


function TFIBTransaction.DoStoreActive:boolean;
begin
 Result:=Active and MainDatabase.StoreConnected
end;

function TFIBTransaction.Call(ErrCode: ISC_STATUS;
  RaiseError: Boolean): ISC_STATUS;
var
  i: Integer;
begin
  Set8087CW(Default8087CW);
  Result := ErrCode;
  FCanTimeout := False;

  for i := 0 to FDatabases.Count - 1 do
    Databases[i].Call(ErrCode,False); // For reset timer

  if (Result > 0) and RaiseError  then
    IbError(IIbClientLibrary(Databases[0]),Self);
end;

procedure TFIBTransaction.CheckDatabasesInList;
begin
  if GetDatabaseCount = 0 then
    FIBError(feNoDatabasesInTransaction, [CmpFullName(Self)]);
end;

procedure TFIBTransaction.AddEvent(Event:TNotifyEvent;EventType:TpFIBTrEventType);
begin
 case EventType of
  tetBeforeStartTransaction:vBeforeStartTransaction.Add(Event);
  tetAfterStartTransaction :vAfterStartTransaction.Add(Event);
  tetBeforeDestroy         :vOnDestroy.Add(Event);
 else
  Assert(False);
 end;
end;

procedure TFIBTransaction.RemoveEvent(Event:TNotifyEvent;EventType:TpFIBTrEventType);
begin
 case EventType of
  tetBeforeStartTransaction:vBeforeStartTransaction.Remove(Event);
  tetAfterStartTransaction :vAfterStartTransaction.Remove(Event);
  tetBeforeDestroy   :  vOnDestroy.Remove(Event);
 else
  Assert(False);
 end;
end;

procedure TFIBTransaction.AddEndEvent(Event:TEndTrEvent;EventType:TpFIBTrEventType);
begin
 case EventType of
  tetBeforeEndTransaction:vBeforeEndTransaction.RegisterCallBack(TMethod(Event));
  tetAfterEndTransaction :vAfterEndTransaction.RegisterCallBack(TMethod(Event));
 else
  Assert(False);
 end;
end;

procedure TFIBTransaction.RemoveEndEvent(Event:TEndTrEvent;EventType:TpFIBTrEventType);
begin
 case EventType of
  tetBeforeEndTransaction  :vBeforeEndTransaction.UnRegisterCallBack(TMethod(Event));
  tetAfterEndTransaction   :vAfterEndTransaction.UnRegisterCallBack(TMethod(Event));
 else
  Assert(False);  
 end;
end;

procedure TFIBTransaction.CheckInTransaction;
var
   i:integer;
   NeedAutoStart:boolean;
begin
  if FStreamedActive and (not InTransaction) then
    Loaded;
  if (FHandle = nil)  then
   if not (csDesigning in ComponentState)  then
   begin
    NeedAutoStart:=True;
    for i:=0 to Pred(DatabaseCount) do
     if not Databases[i].FAutoReconnect then
     begin
      NeedAutoStart:=False;
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
   Result:=-1
  else
  begin
    i := FindDatabase(db);
    if i <> -1 then
      Result := i
    else
    begin
      if (FDatabases.Count>0) and
       (TFIBDatabase(FDatabases[0]).LibraryName<>db.LibraryName)
      then
      if not (csLoading in ComponentState) then
       raise EAPICallException.CreateFmt(STransactionForOtherLibrary,[CmpFullName(Self)])
      else
      begin
       Result:=-1; Exit;
      end;
      Result := FDatabases.Count;
      db.AddTransaction(Self);
      FDatabases.Add(db);
      SetLength(vTRParams,FDatabases.Count);
      vTRParams[Length(vTRParams)-1]:='';
    end;
  end;
end;

function  TFIBTransaction.AddDatabase(db: TFIBDatabase; const aTRParams: string): Integer;
begin
 Result:=AddDatabase(db);
 if Result>=0 then
  vTRParams[Result]:=aTRParams
end;

{$IFDEF USE_DEPRECATE_METHODS1}
function TFIBTransaction.AddDataSet(ds: TFIBBase): Integer;
begin
  Result:=AddFIBBase(ds);
end;
{$ENDIF}

function  TFIBTransaction.AddFIBBase(ds: TFIBBase): Integer;
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
procedure TFIBTransaction.EndTransaction(Action: TTransactionAction;
  Force: Boolean);
var
  status: ISC_STATUS;
  s:string;

procedure DoBefore;
var
  i: Integer;
begin
  for i := FFIBBases.Count - 1 downto 0 do
   FIBBases[i].FOnTransactionEnding;
  for i := 0 to vBeforeEndTransaction.Count - 1 do
   TEndTrEvent(vBeforeEndTransaction.CallBackAddr[i]^)(Self,Action, Force);
end;

procedure DoAfter;
var
  i: Integer;
begin
  for i :=  FFIBBases.Count - 1 downto 0 do
    FIBBases[i].FOnTransactionEnded;
  for i := 0 to vAfterEndTransaction.Count - 1 do
   TEndTrEvent(vAfterEndTransaction.CallBackAddr[i]^)(Self,Action, Force);

 FHasUncommitedUpdates:=False
end;

begin
  CheckInTransaction;
  if Assigned(MainDatabase.FSQLLogger) then
  begin
    case Action of
     TACommit:
        s:='Commit';
     TARollback:
        s:='RollBack';
     TACommitRetaining:
        s:='CommitRetaining';
    else
        s:='RollBackRetaining';
    end;
       MainDatabase.FSQLLogger.WriteData(
        CmpFullName(Self),s+'(TransactionID='+IntToStr(TransactionID)+') ',
         'TransactionParams:'#13#10+TRParams.Text,lfTransact
       );
  end;

  case Action of
    TARollback, TACommit:
    begin
      if (HandleIsShared) and
         (Action <> FTimeoutAction) and
         (not Force) then
        FIBError(feCantEndSharedTransaction, [nil]);
      if Action=TARollback then
       FState:=tsDoRollback
      else
       FState:=tsDoCommit;
      DoBefore;
      if HandleIsShared then
      begin
        FHandle := nil;
        FHandleIsShared := False;
        status := 0;
      end
      else
      if (Action = TARollback) then
        status := Call(IIbClientLibrary(MainDatabase).isc_rollback_transaction(StatusVector, @FHandle), False)
      else
        status := Call(IIbClientLibrary(MainDatabase).isc_commit_transaction(StatusVector, @FHandle), False);
      if ((Force) and (status > 0)) then
        status := Call(IIbClientLibrary(MainDatabase).isc_rollback_transaction(StatusVector, @FHandle), False);
      if Force then
        FHandle := nil
      else
      if (status > 0) then
        IBError(MainDatabase,Self);
      DoAfter;

      end;
      TACommitRetaining:
      begin
        FState:=tsDoCommitRetaining;
        DoBefore;
        Call(IIbClientLibrary(MainDatabase).isc_commit_retaining(StatusVector, @FHandle), True);
        DoAfter;
      end;
      TARollbackRetaining:
      begin
        FState:=tsDoRollbackRetaining;
        DoBefore;
        Call(IIbClientLibrary(MainDatabase).isc_rollback_retaining(StatusVector, @FHandle), True);
        DoAfter;
      end;
  end;
 {$IFNDEF NO_MONITOR}
   if MonitoringEnabled  then
   case Action of
    TACommit:
     if MonitorHook<>nil then
       MonitorHook.TRCommit(Self);
    TARollback:
     if MonitorHook<>nil then
       MonitorHook.TRRollback(Self);
    TACommitRetaining:
     if MonitorHook<>nil then
      MonitorHook.TRCommitRetaining(Self);
    TARollbackRetaining:
     if MonitorHook<>nil then
      MonitorHook.TRRollbackRetaining(Self);
   end;
 {$ENDIF}
  if InTransaction then
  begin
   FState:=tsActive;
  end
  else
  begin
   FState:=tsClosed ;
   if FTimer<>nil then
    FTimer.Enabled:=False;
   if csDesigning in ComponentState then  CloseAllQueryHandles;
  end;
  FTransactionID:=0;
end;

function TFIBTransaction.GetDatabase(Index: Integer): TFIBDatabase;
begin
  Result := FDatabases[Index];
end;

function TFIBTransaction.GetDatabaseCount: Integer;
begin
  Result := FDatabases.Count;
end;

function  TFIBTransaction.MainDatabase:TFIBDatabase;
begin
  if Assigned(DefaultDatabase) then
   Result:=DefaultDatabase
  else
  if FDatabases.Count=0 then
   Result := nil
  else
   Result :=FDatabases[0];
end;

function TFIBTransaction.GetFIBBase(Index: Integer): TFIBBase;
begin
  Result := FFIBBases[Index];
end;

function TFIBTransaction.GetFIBBasesCount: Integer;
begin
  Result := FFIBBases.Count;
end;

function TFIBTransaction.GetInTransaction: Boolean;
begin
  Result := (FHandle <> nil);
end;

function TFIBTransaction.FindDatabase(db: TFIBDatabase): Integer;
begin
  if db=nil then
   Result := -1
  else
   Result:=FDatabases.IndexOf(db);
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
    i:Integer;
begin
  if (csDesigning in ComponentState) then
   Include( FTransactionRunStates,trsInLoaded);
  try
    inherited Loaded;
    try
     if csDesigning in ComponentState then
      for i:=0 to FDatabases.Count-1 do
       if TFIBDataBase(FDatabases.List[i]).FStreammedConnectFail then
        Exit;

      if FStreamedActive and (not InTransaction) then StartTransaction;
    except
      on E:Exception do
      begin
        if not (csDesigning in ComponentState) then
          raise
        else
        begin
           ShowException(E,nil);
        end;
      end;
    end;
  finally
   FStreamedActive := False;
   Exclude( FTransactionRunStates,trsInLoaded);
  end
end;

procedure TFIBTransaction.OnDatabaseDisconnecting(DB: TFIBDatabase);
begin
  if InTransaction then
    // Force the transaction to end
  if FTimeoutAction= TACommitRetaining then
    EndTransaction(TACommit, True)
  else
  if FTimeoutAction= TARollBackRetaining then
    EndTransaction(TARollBack, True)
  else
    EndTransaction(FTimeoutAction, True);
end;

procedure TFIBTransaction.RemoveDatabase(Idx: Integer);
var
  DB: TFIBDatabase;
begin
  if ((Idx >= 0) and (FDatabases[Idx] <> nil)) then
  begin
    DB := Databases[Idx];
    FDatabases.Delete(Idx);
    DB.FTransactions.Remove(Self);
    if DB.FDefaultTransaction=Self then
     DB.FDefaultTransaction:=nil;
    if DB.FDefaultUpdateTransaction=Self then
     DB.FDefaultUpdateTransaction:=nil;

    if DB = FDefaultDatabase then
      FDefaultDatabase := nil;
  end;
end;

procedure TFIBTransaction.RemoveDatabases;
var
  i: Integer;
begin
  for i := Pred(FDatabases.Count) downto 0 do
    RemoveDatabase(i);
end;

procedure TFIBTransaction.ReplaceDatabase(dbOld,dbNew: TFIBDatabase);
begin
  RemoveDatabase(FindDatabase(dbOld));
  AddDatabase(dbNew)
end;

{$IFDEF USE_DEPRECATE_METHODS1}
{$WARNINGS OFF }
procedure TFIBTransaction.RemoveDataSet(Idx: Integer);
begin
  RemoveFIBBase(Idx);
end;
{$WARNINGS ON }
{$ENDIF}

procedure TFIBTransaction.RemoveFIBBase(Idx: Integer);
var
  ds: TFIBBase;
begin
  if ((Idx >= 0) and (FFIBBases[Idx] <> nil)) then
  begin
    ds := FIBBases[Idx];
    ds.FTransaction := nil;
    if Idx<FFIBBases.Count-1 then
    begin
     ds := FFIBBases[FFIBBases.Count-1];
     FFIBBases[Idx]:=ds;
     ds.FIndexInTransaction:=Idx;
     FFIBBases.Delete(FFIBBases.Count-1);
    end
    else
     FFIBBases.Delete(Idx);
  end;
end;
{$IFDEF USE_DEPRECATE_METHODS1}
{$WARNINGS OFF }
procedure TFIBTransaction.RemoveDataSets;
begin
  RemoveFIBBases
end;
{$WARNINGS ON }
{$ENDIF}

procedure TFIBTransaction.RemoveFIBBases;
var
  i: Integer;
begin
  for i := FFIBBases.Count - 1 downto 0 do
//  if FFIBBases[i] <> nil then
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
  else
  if Value and not InTransaction then
    StartTransaction
  else
  if not Value and InTransaction then
    Rollback;
end;

procedure TFIBTransaction.SetDefaultDatabase(Value: TFIBDatabase);
begin
  CheckNotInTransaction;
  if (Value <> FDefaultDatabase) then
  begin
    if Assigned(Value)  then
     Value.AddTransaction(Self);
    ReplaceDatabase(FDefaultDatabase,Value)
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
{  if Value < 0 then
    FIBError(feTimeoutNegative, [nil])
  else}
  if (Value = 0) then
  begin
    if Assigned(FTimer) then
    begin
      FTimer.Free;
      FTimer:=nil;
    end;
  end
  else
  if (Value > 0) then
  begin
    CreateTimeoutTimer;
    FTimer.Interval := Value;
    if not (csDesigning in ComponentState) and Active then
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
  TPB: Ansistring;
  i: Integer;
  vTRParams1:TStrings;
  vTPBLength:Short;
  vIsFB21orMore:boolean;
begin
    (*
     * Check that we're not already in a transaction.
     * Check that there is at least one database in the list.
     *)

    CheckNotInTransaction;
    CheckDatabasesInList;
    for i := 0 to DatabaseCount - 1 do
    begin
      Databases[i].CheckActive(not (trsInLoaded in FTransactionRunStates));
      if not Databases[i].Connected then
       Exit;
    end;
    vIsFB21orMore:=MainDatabase.FIsFB21orMore;
    (*
     * Make sure that a current TPB is generated.
     *)
      if FTRParamsChanged then
      begin
        FTRParamsChanged := False;
        GenerateTPB(FTRParams, TPB, FTPBLength,vIsFB21orMore);
        FIBAlloc(FTPB, 0, FTPBLength);
        Move(TPB[1], FTPB[0], FTPBLength);
      end;
      GetMem(pteb,DatabaseCount * SizeOf(TISC_TEB));
      vTRParams1:=nil;
      try
        for i := 0 to DatabaseCount - 1 do
        begin
          pteb^[i].db_handle   := @(Databases[i].Handle);
          if vTRParams[i]='' then
          begin
           pteb^[i].tpb_address := FTPB;
           pteb^[i].tpb_length  := FTPBLength;
          end
          else
          begin
           if vTRParams1=nil then
            vTRParams1:=TStringList.Create;
           vTRParams1.Text:=vTRParams[i];

           SetLength(vTPBArray,i+1);
           GenerateTPB(vTRParams1, vTPBArray[i], vTPBLength,vIsFB21orMore);
           if Length(vTPBArray[i])>0 then
           begin
            pteb^[i].tpb_address := @vTPBArray[i][1];
            pteb^[i].tpb_length  := vTPBLength;
           end
           else
           begin
            pteb^[i].tpb_address := FTPB;
            pteb^[i].tpb_length  := FTPBLength;
           end
          end;
        end;
        for i := 0 to FFIBBases.Count - 1 do
         FIBBases[i].FOnTransactionStarting;

        (*
         * Finally, start the transaction
         *)
        if not InTransaction then
        begin
          for i := Pred(vBeforeStartTransaction.Count) downto 0 do
           vBeforeStartTransaction.Event[i](Self);

          if (Call(IIbClientLibrary(MainDatabase).isc_start_multiple(StatusVector, @FHandle,
                                     DatabaseCount, PISC_TEB(pteb)), False) > 0)

          then
          begin
            FHandle := nil;
            if not (trsInLoaded in FTransactionRunStates) then
             IbError(MainDatabase,Self);
          end;
          for i := Pred(vAfterStartTransaction.Count) downto 0 do
           vAfterStartTransaction.Event[i](Self);
        end;

        for i := 0 to FFIBBases.Count - 1 do
          FIBBases[i].FOnTransactionStarted;
     {$IFNDEF NO_MONITOR}
       if MonitoringEnabled  then
        if MonitorHook<>nil then
         MonitorHook.TRStart(Self);
     {$ENDIF}
      finally
        vTRParams1.Free;
        FIBAlloc(pteb, 0, 0);
      end;

    FState:=tsActive;

    if Assigned(MainDatabase.FSQLLogger) then
     MainDatabase.FSQLLogger.WriteData(
      CmpFullName(Self),'StartTransaction(TransactionID='+IntToStr(TransactionID)+')',
      'TransactionParams:'#13#10+TRParams.Text,lfTransact
     );

    if (FTimer<>nil) and  (FTimer.Interval>0) then
     FTimer.Enabled:=True
end;

procedure TFIBTransaction.ExecSQLImmediate(const SQLText:Widestring);
var
 vSQLText:AnsiString;
begin
  CheckInTransaction;
  if MainDatabase.IsUnicodeConnect then
    vSQLText:=UTF8Encode(SQLText)
  else
    vSQLText:=SQLText;
  Call(
    MainDatabase.ClientLibrary.
    isc_dsql_execute_immediate(
     StatusVector, @MainDatabase.Handle, @FHandle, 0,
     PAnsiChar(vSQLText), MainDatabase.SQLDialect, nil
    ),
   True
  );
end;

procedure TFIBTransaction.SetSavePoint(const SavePointName:string);
begin
  ExecSQLImmediate('savepoint '+SavePointName);
  {$IFNDEF NO_MONITOR}
  if MonitoringEnabled  then
    if MonitorHook<>nil then
      MonitorHook.TRSavepoint(Self,SavePointName,soSet)
  {$ENDIF}
end;

procedure TFIBTransaction.RollBackToSavePoint(const SavePointName:string);
begin
  ExecSQLImmediate('rollback to savepoint '+SavePointName);
 {$IFNDEF NO_MONITOR}
   if MonitoringEnabled  then
    if MonitorHook<>nil then
      MonitorHook.TRSavepoint(Self,SavePointName,soRollback)
 {$ENDIF}
end;

procedure TFIBTransaction.ReleaseSavePoint(const SavePointName:string);
begin
  ExecSQLImmediate('release savepoint '+SavePointName);
 {$IFNDEF NO_MONITOR}
   if MonitoringEnabled  then 
    if MonitorHook<>nil then
      MonitorHook.TRSavepoint(Self,SavePointName,soRelease)
 {$ENDIF}
end;

procedure TFIBTransaction.TimeoutTransaction(Sender: TObject);
begin
  if InTransaction then
  begin
    if FCanTimeout then
    begin
      EndTransaction(FTimeoutAction, True);
      if Assigned(FOnTimeout) then  FOnTimeout(Self);
    end
    else
      FCanTimeout := True;
  end;
end;

procedure TFIBTransaction.TRParamsChange(Sender: TObject);
begin
  FTRParamsChanged := True;
end;

procedure TFIBTransaction.TRParamsChanging(Sender: TObject);
begin
  CheckNotInTransaction;
end;

function  TFIBTransaction.GetTransactionID: integer;
var tra_items: AnsiChar;
    tra_info :array [0..31] of AnsiChar;
begin
 if FTransactionID>0 then
 begin
  Result:=FTransactionID; Exit;
 end;
 if FHandle=nil then
 begin
  Result:=0; Exit;
 end;
 if MainDatabase.FDatabaseRunState<>[] then
 begin
  Result:=0; Exit;
 end;

  tra_items:=AnsiChar(isc_info_tra_id);
  Call(IIbClientLibrary(MainDatabase).
   isc_transaction_info(
    StatusVector,@FHandle,
    sizeof (tra_items),
    @tra_items,
    sizeof (tra_info),
    tra_info
   ),true
  );
   Result:=PInteger(tra_info+3)^;
   FTransactionID:=Result
end;

procedure TFIBTransaction.CloseAllQueryHandles;
var i:integer;
begin
  for i :=0  to Pred(FIBBaseCount) do
  begin
    if (FIBBases[i].Owner is TFIBQuery) then
     TFIBQuery(FIBBases[i].Owner).FreeHandle
  end;
end;

function  TFIBTransaction.IsReadCommitedTransaction:boolean;
begin
 Result:=(FTRParams.IndexOf('read_committed')>-1) or
 (FTRParams.IndexOf(TPBPrefix+'read_committed')>-1)
end;

function TFIBTransaction.IsReadOnly:boolean;
begin
 Result:=(FTRParams.IndexOf('read')>-1) or
 (FTRParams.IndexOf(TPBPrefix+'read')>-1)
end;

procedure TFIBTransaction.DoOnSQLExec(Query:TComponent;Kind:TKindOnOperation);
var
   ar:TAllRowsAffected;
begin
 if FWatchUpdates and not FHasUncommitedUpdates and (Query is TFIBQuery) then
 with TFIBQuery(Query) do
  case Kind of
   koAfter:
   if SQLType <> SQLSelect then
   begin
    ar:=AllRowsAffected;
    FHasUncommitedUpdates:=(ar.Updates+ar.Deletes+ar.Inserts)>0;
   end;
   koOther:
   if (SQLType=SQLSelect)  and (qrsInClose in  QueryRunState) then
   begin
     // For select * from SP
    ar:=AllRowsAffected;
    FHasUncommitedUpdates:=(ar.Updates+ar.Deletes+ar.Inserts)>0;
   end;
  end;
 end;

(* TFIBBase *)
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
   if Self.Owner is TComponent  then
    FIBError(feDatabaseNotAssigned, [CmpFullName(TComponent(Self.Owner))])
   else
    FIBError(feDatabaseNotAssigned, ['']);
  FDatabase.CheckActive
end;

procedure TFIBBase.CheckTransaction;
begin
  if FTransaction = nil then
   if Self.Owner is TComponent  then
    FIBError(feTransactionNotAssigned, [CmpFullName(TComponent(Self.Owner))])
   else
    FIBError(feTransactionNotAssigned, [nil]);
  FTransaction.CheckInTransaction;
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
  if Assigned(OnTransactionFree) then    OnTransactionFree(Self);
  // Ensure that FTransaction is nil
  FTransaction := nil;
end;

procedure TFIBBase.SetDatabase(Value: TFIBDatabase);
begin
  if FDatabase=Value then
   Exit;
  if (FDatabase <> nil) then
    FDatabase.RemoveFIBBase(FIndexInDatabase);
  FDatabase := Value;
  if (FDatabase <> nil) then
  begin
//    FClientLibrary:=FDatabase.ClientLibrary;
    FIndexInDatabase := FDatabase.AddFIBBase(Self);
    if (FTransaction = nil)
     and Assigned(Owner) and not CmpInLoadedState(TComponent(Owner))
    then
      Transaction := FDatabase.DefaultTransaction;
  end;
end;

procedure TFIBBase.SetTransaction(Value: TFIBTransaction);
begin
  if FTransaction=Value then
   Exit;
  if (FTransaction <> nil) then
    FTransaction.RemoveFIBBase(FIndexInTransaction);
  FTransaction := Value;
  if (FTransaction <> nil) then
  begin
    FIndexInTransaction := FTransaction.AddFIBBase(Self);
    if (FDatabase=nil) or  (FTransaction.FindDatabase(FDatabase)=-1) then
    begin
     if FTransaction.GetDatabaseCount>0 then
     begin
       Database:=FTransaction.MainDatabase
     end;
    end;
  end;
end;

procedure CleanDatabaseList;
var
  I: Integer;
begin
 with DatabaseList.LockList do
 try
  for I:=0 to Pred(Count) do
    TFIBDatabase(Items[I]).Close;
 finally
   DatabaseList.UnLockList;
   DatabaseList.Free;
   DatabaseList:=nil
 end;
end;


initialization
 vConnectCS:=TCriticalSection.Create;
 DefDataBase :=nil;
 DatabaseList:=TThreadList.Create;
{$IFDEF FIBPLUS_TRIAL}
  if FindWindow( 'TAppBuilder', nil ) <= 0 then
   ShowMessage( 'Thank you very much for evaluating FIBPlus.'+CLRF+CLRF +
    'Please go to http://www.devrace.com and register today.'
   );
{$ENDIF}

finalization
 CleanDatabaseList  ;
 vConnectCS.Free;
end.

