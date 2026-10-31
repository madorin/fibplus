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

unit FIBProps;

interface

{$I FIB.inc}
{$J+}

uses
  Classes, SysUtils, DB, IniFiles, FIBPlatforms;

type

  TFIBBlobFieldProcessingEvent = procedure(Field: TBlobField; BlobSize: Integer; Progress: Integer; var Stop: Boolean) of object;

  TFIBOperationMoment = (koBefore, koAfter, koAfterFirstFetch, koOther);

  TFIBSQLTypes = (
    SQLUnknown,
    SQLSelect,
    SQLInsert,
    SQLUpdate,
    SQLDelete,
    SQLDDL,
    SQLGetSegment,
    SQLPutSegment,
    SQLExecProcedure,
    SQLStartTransaction,
    SQLCommit,
    SQLRollback,
    SQLSelectForUpdate,
    SQLSetGenerator,
    SQLSavePointOperation
  );

  TFIBExistObject = (eoYes, eoNo, eoUnknown);

  TFIBPrepareOption = (
    pfSetRequiredFields,
    pfSetReadOnlyFields,
    pfImportDefaultValues,
    psUseBooleanField,
    psUseGuidField,
    psSQLINT64ToBCD,
    psApplyRepositary,
    psGetOrderInfo,
    psAskRecordCount,
    psCanEditComputedFields,
    psSetEmptyStrToNull,
    psSupportUnicodeBlobs,
    psUseLargeIntField
  );
  TFIBPrepareOptions = set of TFIBPrepareOption;

  TFIBDataSetOption = (poTrimCharFields, poRefreshAfterPost, poRefreshDeletedRecord,
    poStartTransaction, poAutoFormatFields, poProtectedEdit, poUseSelectForLock,
    poKeepSorting,
{$IFDEF OBSOLETE_PROPS}
    poAllowChangeSqls,
{$ENDIF}
    poPersistentSorting, poVisibleRecno, poNoForceIsNull, poFetchAll,
    poFreeHandlesAfterClose, poCacheCalcFields, poRefreshAfterDelete,
    poDontCloseAfterEndTransaction);
  TFIBDataSetOptions = set of TFIBDataSetOption;

  TFIBQueryOption = (qoStartTransaction, qoAutoCommit, qoTrimCharFields, qoNoForceIsNull, qoFreeHandleAfterExecute);
  TFIBQueryOptions = set of TFIBQueryOption;

  TFIBDetailCondition = (dcForceOpen, dcIgnoreMasterClose, dcForceMasterRefresh, dcWaitEndMasterScroll);

  TFIBDetailConditions = set of TFIBDetailCondition;
  TFIBFieldOriginRule = (forNoRule, forTableAndFieldName, forClientFieldName, forTableAliasAndFieldName);

  TFIBSQLs = class(TPersistent)
  private
    FOwner: TComponent;
    function GetSelectSQL: TStrings;
    procedure SetSelectSQL(Value: TStrings);
    function GetInsertSQL: TStrings;
    procedure SetInsertSQL(Value: TStrings);
    function GetUpdateSQL: TStrings;
    procedure SetUpdateSQL(Value: TStrings);
    function GetDeleteSQL: TStrings;
    procedure SetDeleteSQL(Value: TStrings);
    function GetRefreshSQL: TStrings;
    procedure SetRefreshSQL(Value: TStrings);
  public
    constructor Create(Owner: TComponent);
    property Owner: TComponent read FOwner;
  published
    property SelectSQL: TStrings read GetSelectSQL write SetSelectSQL;
    property UpdateSQL: TStrings read GetUpdateSQL write SetUpdateSQL;
    property DeleteSQL: TStrings read GetDeleteSQL write SetDeleteSQL;
    property InsertSQL: TStrings read GetInsertSQL write SetInsertSQL;
    property RefreshSQL: TStrings read GetRefreshSQL write SetRefreshSQL;
  end;

  TFIBFormatFields = class(TPersistent)
  private
    FOwner: TComponent;
    FDisplayFormatDateTime: string;
    FDisplayFormatDate: string;
    FDisplayFormatTime: string;
    FDisplayFormatNumeric: string;
    FEditFormatNumeric: string;
    function StoreDfDt: Boolean;
    function StoreDfN: Boolean;
    function StoreEfN: Boolean;
    function StoreDfD: Boolean;
    function StoreDfT: Boolean;
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create(aOwner: TComponent);
  published
    property DateTimeDisplayFormat: string read FDisplayFormatDateTime write FDisplayFormatDateTime stored StoreDfDt;
    property NumericDisplayFormat: string read FDisplayFormatNumeric write FDisplayFormatNumeric stored StoreDfN;
    property NumericEditFormat: string read FEditFormatNumeric write FEditFormatNumeric stored StoreEfN;
    property DisplayFormatDate: string read FDisplayFormatDate write FDisplayFormatDate stored StoreDfD;
    property DisplayFormatTime: string read FDisplayFormatTime write FDisplayFormatTime stored StoreDfT;
  end;

  TFIBWhenGetGenID = (wgNever, wgOnNewRecord, wgBeforePost);
  TFIBReturningField = (rfAll, rfKeyFields, rfBlobFields);
  TFIBReturningFields = set of TFIBReturningField;

  TFIBAutoUpdateOptions = class(TPersistent)
  private
    FOwner: TComponent;
    FUpdateTableName: string;
    FKeyFieldList: TStrings;
    FKeyFields: string;
    FAutoReWriteSqls: Boolean;
    FCanChangeSQLs: Boolean;
    FGeneratorName: string;
    FGeneratorStep: Integer;
    FSelectGenID: Boolean;
    FGenBeforePost: Boolean;
    FUpdateOnlyModifiedFields: Boolean;
    FWhenGetGenID: TFIBWhenGetGenID;
    FParamFieldLinks: TStrings;
    FAutoParamsToFields: Boolean;
    FSeparateBlobUpdate: Boolean;
    FUseExecuteBlock: Boolean; // For CachedUpdates only
    FWhereCondition: string; // Cache where
    FModifiedTable: string;
    FAliasModifiedTable: string;
    FModifiedTableHaveAlias: Boolean;
    FReadySelectSQL: string;
    FReturningFields: TFIBReturningFields;
    FUseRowsClause: Boolean;
    FModified: Boolean;
    procedure SetUpdateTableName(const Value: string);
    procedure SetSelectGenID(Value: Boolean);
    function GetSelectGenID: Boolean;
    function GetGenBeforePost: Boolean;
    procedure SetGenBeforePost(Value: Boolean);
    procedure SetParamFieldLinks(const Value: TStrings);
    procedure SetKeyFields(const Value: string);
    function GetAliasModifiedTable: string;
    function GetModifiedTable: string;
    procedure PrepareUpdateTableStrings;
    procedure SetReturningFields(const Value: TFIBReturningFields);
  protected
    // for compatibility only
    procedure ReadSelectGenID(Reader: TReader);
    procedure ReadGenBeforePost(Reader: TReader);
    procedure AssignTo(Dest: TPersistent); override;
    procedure DefineProperties(Filer: TFiler); override;
  public
    constructor Create(Owner: TComponent);
    destructor Destroy; override;
    function UpdateOnlyModifiedFieldsInEffect: Boolean;
    property Owner: TComponent read FOwner;
    property SelectGenID: Boolean read GetSelectGenID write SetSelectGenID;
    property GenBeforePost: Boolean read GetGenBeforePost write SetGenBeforePost;
    property KeyFieldList: TStrings read FKeyFieldList;
    // Cache Analize results
    property WhereCondition: string read FWhereCondition write FWhereCondition;
    property ModifiedTableName: string read GetModifiedTable;
    property AliasModifiedTable: string read GetAliasModifiedTable;
    property ModifiedTableHaveAlias: Boolean read FModifiedTableHaveAlias;
    property ReadySelectSQL: string read FReadySelectSQL write FReadySelectSQL;
    property Modified: Boolean read FModified write FModified;
  published
    property UpdateTableName: string read FUpdateTableName write SetUpdateTableName;
    property KeyFields: string read FKeyFields write SetKeyFields;
    property AutoReWriteSqls: Boolean read FAutoReWriteSqls write FAutoReWriteSqls default False;
    property CanChangeSQLs: Boolean read FCanChangeSQLs write FCanChangeSQLs default False;
    property GeneratorName: string read FGeneratorName write FGeneratorName;
    property UpdateOnlyModifiedFields: Boolean read FUpdateOnlyModifiedFields write FUpdateOnlyModifiedFields
      default False;
    property WhenGetGenID: TFIBWhenGetGenID read FWhenGetGenID write FWhenGetGenID default wgNever;
    property GeneratorStep: Integer read FGeneratorStep write FGeneratorStep default 1;
    property ParamsToFieldsLinks: TStrings read FParamFieldLinks write SetParamFieldLinks;
    property AutoParamsToFields: Boolean read FAutoParamsToFields write FAutoParamsToFields default False;
    property SeparateBlobUpdate: Boolean read FSeparateBlobUpdate write FSeparateBlobUpdate default False;
    property UseExecuteBlock: Boolean read FUseExecuteBlock write FUseExecuteBlock default False;
    // ^^^ For CachedUpdates only
    property UseReturningFields: TFIBReturningFields read FReturningFields write SetReturningFields default [];
    property UseRowsClause: Boolean read FUseRowsClause write FUseRowsClause default False;
  end;

{$IFDEF SUPPORT_IB2007}
  TFIBInterBaseConnectParams = class(TPersistent)
  private
    FOwner: TComponent;
    function GetInstanceName: string;
    procedure SetInstanceName(const Value: string);
  public
    constructor Create(Owner: TComponent);
  published
    property InstanceName: string read GetInstanceName write SetInstanceName stored False;
  end;
{$ENDIF}

  TFIBUseGeneratorCache = (No, forAll, forGeneratorList);

  TFIBGeneratorParams = class(TNamedItem)
  private
    FStepForCache: Integer;
    FNextValue: Int64;
    FLimit: Int64;
    function StoreStep: Boolean;
  public
    constructor Create(Collection: TCollection); override;
    procedure SaveToFile;
    function NextValue: Int64;
  published
    property StepForCache: Integer read FStepForCache write FStepForCache stored StoreStep;
  end;

  TFIBGeneratorsCache = class(TPersistent)
  private
    FOwner: TComponent;
    FCacheFileName: string;
    FUseGeneratorCache: TFIBUseGeneratorCache;
    FGenerators: TOwnedCollection;
    FDefaultStep: Integer;
    FLoaded: Boolean;
    procedure SetGenerators(const Value: TOwnedCollection);
    function DoSaveGenList: Boolean;
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(Owner: TComponent);
    destructor Destroy; override;
    // Internal use methods
    function IndexOf(const AName: string): Integer;
    function Find(const GenName: string): TFIBGeneratorParams;
    function CanWork(const GenName: string): Boolean;
    function GetStep(const GenName: string): Integer;
    function GetNextValue(const GenName: string): Int64;
    procedure InternalSetGenParams(const GenName: string; Limit: Int64);
    procedure SaveToFile;
    procedure LoadFromFile;
    property Loaded: Boolean read FLoaded;
  public
    procedure AddGenerator(const GenName: string; Limit: Int64);
    procedure RemoveGenerator(const GenName: string);
  published
    property CacheFileName: string read FCacheFileName write FCacheFileName;
    property UseGeneratorCache: TFIBUseGeneratorCache read FUseGeneratorCache write FUseGeneratorCache default No;
    property GeneratorList: TOwnedCollection read FGenerators write SetGenerators stored DoSaveGenList;
    property DefaultStep: Integer read FDefaultStep write FDefaultStep default 50;
  end;

  TFIBConnectParams = class(TPersistent)
  private
    FOwner: TComponent;
    FIsFirebird: Boolean;
{$IFDEF SUPPORT_IB2007}
    FIBParams: TFIBInterBaseConnectParams;
    procedure SetIBParams(const Value: TFIBInterBaseConnectParams);
{$ENDIF}
    function GetUserNameA: string;
    procedure SetUserName(const Value: string);
    function GetRoleName: string;
    procedure SetRoleName(const Value: string);
    function GetPassword: string;
    procedure SetPassword(const Value: string);
    function GetCharSet: string;
    procedure SetCharSet(const Value: string);
    function GetWireCompression: Boolean;
    procedure SetWireCompression(const Value: Boolean);
    function GetParallelWorkers: Integer;
    procedure SetParallelWorkers(const Value: Integer);

  public
    constructor Create(Owner: TComponent);
    destructor Destroy; override;
  published
    property UserName: string read GetUserNameA write SetUserName stored False;
    property RoleName: string read GetRoleName write SetRoleName stored False;
    property Password: string read GetPassword write SetPassword stored False;
    property CharSet: string read GetCharSet write SetCharSet stored False;
    property IsFirebird: Boolean read FIsFirebird write FIsFirebird default True;
    property WireCompression: Boolean read GetWireCompression write SetWireCompression stored False;
    property ParallelWorkers: Integer read GetParallelWorkers write SetParallelWorkers stored False;
{$IFDEF SUPPORT_IB2007}
    property IB2007: TFIBInterBaseConnectParams read FIBParams write SetIBParams;
{$ENDIF}
  end;
{$IFDEF CSMonitor}
  TFIBCSMonitorEnabled = (csmeDisabled, csmeEnabled, csmeDatabaseDriven, csmeTransactionDriven);

  EFIBCSMonitorError = class(Exception);

  TFIBCSMonitorSupport = class(TPersistent)
  private
    FOwner: TComponent;
    FEnabled: TFIBCSMonitorEnabled;
    FIncludeDatasetDescription: Boolean;
    procedure SetEnabled(const Value: TFIBCSMonitorEnabled);
    procedure SetIncludeDatasetDescription(const Value: Boolean);
    function DoStoreEnabled: Boolean;
  public
    constructor Create(aOwner: TComponent);
  published
    property Enabled: TFIBCSMonitorEnabled read FEnabled write SetEnabled stored DoStoreEnabled;
    property IncludeDatasetDescription: Boolean read FIncludeDatasetDescription write SetIncludeDatasetDescription default True;
  end;
{$ENDIF}

  TFIBCacheSchemaOptions = class(TPersistent)
  private
    FLocalCacheFile: string;
    FAutoSaveToFile: Boolean;
    FAutoLoadFromFile: Boolean;
    FValidateAfterLoad: Boolean;
  public
    constructor Create;
    procedure Assign(Source: TPersistent); override;
  published
    property LocalCacheFile: string read FLocalCacheFile write FLocalCacheFile;
    property AutoSaveToFile: Boolean read FAutoSaveToFile write FAutoSaveToFile default False;
    property AutoLoadFromFile: Boolean read FAutoLoadFromFile write FAutoLoadFromFile default False;
    property ValidateAfterLoad: Boolean read FValidateAfterLoad write FValidateAfterLoad default True;
  end;

  TFIBDBParams = class(TStringList)
  private
    FOwner: TComponent;
    procedure ReadData(Reader: TReader);
    procedure WriteData(Writer: TWriter);
  protected
    procedure DefineProperties(Filer: TFiler); override;
  public
    constructor Create(aOwner: TComponent);
  end;

  TFIBDefaultTimeoutAction = (dtaRollback, dtaRollbackRetaining, dtaCommit, dtaCommitRetaining);
  // tpbReadConsistency needs Firebird 4+, older servers raise EFIBClientError at StartTransaction
  TFIBTPBMode = (tpbDefault, tpbReadCommitted, tpbRepeatableRead, tpbReadConsistency);

  TFIBBlobSwapSupport = class(TPersistent)
  private
    FActive: Boolean;
    FAutoValidateSwap: Boolean;
    FSwapDirectory: string;
    FMinBlobSizeToSwap: Integer;
    FTables: TStrings;
    function GetSwapDirectory: string;
    function StoreSwapDir: Boolean;
    procedure SetTables(aTables: TStrings);
    function StoreTables: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    property SwapDirectory: string read GetSwapDirectory;
  published
    property Active: Boolean read FActive write FActive default False;
    property AutoValidateSwap: Boolean read FAutoValidateSwap write FAutoValidateSwap default False;
    property SwapDir: string read FSwapDirectory write FSwapDirectory stored StoreSwapDir;
    property MinBlobSizeToSwap: Integer read FMinBlobSizeToSwap write FMinBlobSizeToSwap default 0;
    property Tables: TStrings read FTables write SetTables stored StoreTables;
  end;

  TFIBConditions = class;

  TFIBCondition = class
  private
    FOwner: TFIBConditions;
    FEnabled: Boolean;
    FInDestroy: Boolean;

    FEnabledFromStream: Boolean;
    FValueFromStream: Boolean;

    function GetName: string;
    function GetValue: string;
    procedure SetValue(const Value: string);
    procedure SetValueFromStream(const Value: string);

    procedure SetName(const Name: string);
    procedure SetEnabled(const Value: Boolean);
    procedure SetEnabledFromStream(const Value: Boolean);
  public
    constructor Create(aOwner: TFIBConditions);
    destructor Destroy; override;
    property Enabled: Boolean read FEnabled write SetEnabled;
    property Name: string read GetName write SetName;
    property Value: string read GetValue write SetValue;
  end;

  TFIBConditionsStateFlag = (csInApply, csInCancel, csInRestorePrimarySQL);
  TFIBConditionsState = set of TFIBConditionsStateFlag;

  TFIBConditions = class(TStringList)
  private
    FFIBQuery: TComponent;
    FApplied: Boolean;
    FPrimarySQL: string;
    FState: TFIBConditionsState;
    function GetEnabledText: string;
    function GetCondition(Index: Integer): TFIBCondition;
  protected
    procedure Put(Index: Integer; const S: string); override;
    procedure DefineProperties(Filer: TFiler); override;
    procedure ReadEnabled(Reader: TReader);
    procedure ReadStrings(Reader: TReader);
    procedure ReadData(Reader: TReader);
    procedure WriteData(Writer: TWriter);

  public
    procedure WriteToExchangeStrings(Dest: TStrings);
    function ExchangeString: string;
    procedure ReadFromExchangeStrings(Source: TStrings);
    procedure ReadFromExchangeString(const Source: string);
  public
    constructor Create(aOwner: TComponent);
    destructor Destroy; override;
    function Add(const S: string): Integer; override;
    function AddObject(const S: string; AObject: TObject): Integer; override;
    procedure Clear; override;
    procedure Delete(Index: Integer); override;
    function AddCondition(const Name, Condition: string; Enabled: Boolean): TFIBCondition;
    function FindCondition(const Name: string): TFIBCondition;
    function ByName(const Name: string): TFIBCondition;
    procedure Remove(const Name: string);
    procedure Apply;
    procedure CancelApply;
    procedure RestorePrimarySQL;
    property Owner: TComponent read FFIBQuery;
    property EnabledText: string read GetEnabledText;
    property Applied: Boolean read FApplied;
    property Condition[Index: Integer]: TFIBCondition read GetCondition; default;
    property PrimarySQL: string read FPrimarySQL write FPrimarySQL;
    property State: TFIBConditionsState read FState;
  end;

  TFIBMemoSubtypes = class
  private
    FActive: Boolean;
    FSubTypes: array of SmallInt;
    FSubTypesStr: string;
    procedure SetSubTypes(const SubTypesStr: string);
  public
    function IsMemoSubtype(aSubtype: SmallInt): Boolean;
    property Active: Boolean read FActive;
  published
    property Subtypes: string read FSubTypesStr write SetSubTypes;
  end;

  TFIBExtendedBoolean = (eFalse, eTrue, eUnknown);

  TFIBFieldInfo = class
  protected
    FIsComputed: Boolean;
    FDefaultValue: string;
    FCanIncToWhereClause: Boolean;
    FDomainName: string;
    FDefaultValueEmptyString: Boolean;
    // Info from FIB$FIELDS_INFO
    FWithAdditionalInfo: Boolean;
    FDisplayLabel: string;
    FVisible: Boolean;
    FEditFormat: string;
    FDisplayFormat: string;
    FIsTriggered: Boolean;
    FOtherInfo: TStrings;
    FDisplayWidth: Integer;
    FCanBeBoolean: TFIBExtendedBoolean;
    FCanBeGUID: TFIBExtendedBoolean;
    FCharSet: Integer;
    function GetCanBeBoolean: Boolean;
    function GetCanBeGUID: Boolean;
    function GetCharSet: string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SaveToStream(Stream: TStream);
    // UTF8: text in UTF-8, as SaveToStream writes it; False for the cache stream version 6
    procedure LoadFromStream(Stream: TStream; FromBegin: Boolean; UTF8: Boolean = True);
    property IsComputed: Boolean read FIsComputed;
    property DefaultValue: string read FDefaultValue;
    property DomainName: string read FDomainName;
    property CanIncToWhereClause: Boolean read FCanIncToWhereClause;
    // Info from FIB$FIELDS_INFO
    property WithAdditionalInfo: Boolean read FWithAdditionalInfo;
    property DisplayLabel: string read FDisplayLabel;
    property Visible: Boolean read FVisible;
    property EditFormat: string read FEditFormat;
    property DisplayFormat: string read FDisplayFormat;
    property IsTriggered: Boolean read FIsTriggered;
    property OtherInfo: TStrings read FOtherInfo;
    property DisplayWidth: Integer read FDisplayWidth;
    property DefaultValueEmptyString: Boolean read FDefaultValueEmptyString;
    property CanBeBoolean: Boolean read GetCanBeBoolean;
    property CanBeGuid: Boolean read GetCanBeGUID;
    property CharSetID: Integer read FCharSet;
    property CharSet: string read GetCharSet;
  end;

  // DataSet defaults
const
  StatDefPrepareOptions = [pfImportDefaultValues, psGetOrderInfo,
    psUseBooleanField, psSetEmptyStrToNull];

  DefaultPrepareOptions: TFIBPrepareOptions = StatDefPrepareOptions;

  StatDefDataSetOptions = [poTrimCharFields, poStartTransaction,
    poAutoFormatFields, poRefreshAfterPost];
  DefaultOptions: TFIBDataSetOptions = StatDefDataSetOptions;

  DefaultDetailConditions: TFIBDetailConditions = [];

  // DataBase Defaults
  DefStoreConnected: Boolean = True;
  DefSynchronizeTime: Boolean = True;
  DefUpperOldNames: Boolean = False;
  DefUseLoginPrompt: Boolean = False;
  DefCharSet: string = '';
  DefSQLDialect: Integer = 3;

  // Transaction Defaults
  DefTimeOutAction: TFIBDefaultTimeoutAction = dtaRollback;
  DefTimeOut: Integer = 0;
  DefTPBMode: TFIBTPBMode = tpbReadCommitted;

  // FIBQuery Defaults
  DefParamCheck: Boolean = True;
  DefGoToFirstRecordOnExecute: Boolean = True;
  DefQueryOptions: TFIBQueryOptions = [];
  // Registry Keys
  RegFIBRoot     = 'FIBC_Software';
  RegFIBTrKinds  = 'Transation Kinds';
  RegPreferences = 'Preferences';
  RegRepository  = 'Repository';
  DefPrefixGenName: string = 'GEN_';
  DefSuffixGenName: string = '_ID';
  DefEmptyStrToNull: Boolean = True;
  // FormatFields Defaults
  FF_UseRuntimeDefaults: Boolean = False;
  RDefDateFormat: string = 'dd.mm.yyyy';
  RDefTimeFormat: string = 'hh:nn';
  RDefDisplayFormatNum: string = '#,##0.';
  RDefEditFormatNum: string = '0.';

  dDefDateFormat: string = 'dd.mm.yyyy';
  dDefTimeFormat: string = 'hh:nn';
  dDefDateTimeFormat: string = 'dd.mm.yyyy hh:nn';
  dDefDisplayFormatNum: string = '#,##0.';
  dDefEditFormatNum: string = '0.';

procedure WriteStrToStream(const s: AnsiString; Stream: TStream);
procedure ReadStrFromStream(const Stream: TStream; var ResStr: AnsiString);
procedure WriteUTF8StrToStream(const S: string; Stream: TStream);
// UTF8 False: the text was written in the system code page (WriteStrToStream)
function ReadUTF8StrFromStream(const Stream: TStream; UTF8: Boolean = True): string;

type
  // Deprecated names of the types renamed in 8.0.0
  TOnBlobFieldProcessing = TFIBBlobFieldProcessingEvent deprecated 'Use TFIBBlobFieldProcessingEvent';
  TKindOnOperation = TFIBOperationMoment deprecated 'Use TFIBOperationMoment';
  TDetailCondition = TFIBDetailCondition deprecated 'Use TFIBDetailCondition';
  TDetailConditions = TFIBDetailConditions deprecated 'Use TFIBDetailConditions';
  TFieldOriginRule = TFIBFieldOriginRule deprecated 'Use TFIBFieldOriginRule';
  TSQLs = TFIBSQLs deprecated 'Use TFIBSQLs';
  TFormatFields = TFIBFormatFields deprecated 'Use TFIBFormatFields';
  TWhenGetGenID = TFIBWhenGetGenID deprecated 'Use TFIBWhenGetGenID';
  TReturningFields = TFIBReturningField deprecated 'Use TFIBReturningField';
  TSetReturningFields = TFIBReturningFields deprecated 'Use TFIBReturningFields';
  TAutoUpdateOptions = TFIBAutoUpdateOptions deprecated 'Use TFIBAutoUpdateOptions';
{$IFDEF SUPPORT_IB2007}
  TIBConnectParams = TFIBInterBaseConnectParams deprecated 'Use TFIBInterBaseConnectParams';
{$ENDIF}
  TUseGeneratorCache = TFIBUseGeneratorCache deprecated 'Use TFIBUseGeneratorCache';
  TGeneratorParams = TFIBGeneratorParams deprecated 'Use TFIBGeneratorParams';
  TGeneratorsCache = TFIBGeneratorsCache deprecated 'Use TFIBGeneratorsCache';
  TConnectParams = TFIBConnectParams deprecated 'Use TFIBConnectParams';
{$IFDEF CSMonitor}
  TCSMonitorEnabled = TFIBCSMonitorEnabled deprecated 'Use TFIBCSMonitorEnabled';
  TCSMonitorSupport = TFIBCSMonitorSupport deprecated 'Use TFIBCSMonitorSupport';
{$ENDIF}
  TCacheSchemaOptions = TFIBCacheSchemaOptions deprecated 'Use TFIBCacheSchemaOptions';
  TDBParams = TFIBDBParams deprecated 'Use TFIBDBParams';
  TTransactionAction1 = TFIBDefaultTimeoutAction deprecated 'Use TFIBDefaultTimeoutAction';
  TTPBMode = TFIBTPBMode deprecated 'Use TFIBTPBMode';
  TBlobSwapSupport = TFIBBlobSwapSupport deprecated 'Use TFIBBlobSwapSupport';
  TConditions = TFIBConditions deprecated 'Use TFIBConditions';
  TCondition = TFIBCondition deprecated 'Use TFIBCondition';
  TConditionsStateFlag = TFIBConditionsStateFlag deprecated 'Use TFIBConditionsStateFlag';
  TConditionsState = TFIBConditionsState deprecated 'Use TFIBConditionsState';
  TMemoSubtypes = TFIBMemoSubtypes deprecated 'Use TFIBMemoSubtypes';
  TExtBoolean = TFIBExtendedBoolean deprecated 'Use TFIBExtendedBoolean';

const
  TARollback1 = dtaRollback deprecated 'Use dtaRollback';
  TARollbackRetaining1 = dtaRollbackRetaining deprecated 'Use dtaRollbackRetaining';
  TACommit1 = dtaCommit deprecated 'Use dtaCommit';
  TACommitRetaining1 = dtaCommitRetaining deprecated 'Use dtaCommitRetaining';

implementation

uses
  FIBDatabase, FIBDataSet, FIBQuery, FIB, ibase, StrUtil, StdFuncs, SqlTxtRtns, FIBCharSets, FIBConsts;

constructor TFIBAutoUpdateOptions.Create;
begin
  inherited Create;
  FOwner := Owner;
  FGenBeforePost := True;
  FGeneratorStep := 1;
  FParamFieldLinks := TStringList.Create;
  FKeyFieldList := TStringList.Create;
end;

destructor TFIBAutoUpdateOptions.Destroy;
begin
  FParamFieldLinks.Free;
  FKeyFieldList.Free;
  inherited Destroy;
end;

procedure TFIBAutoUpdateOptions.AssignTo(Dest: TPersistent);
begin
  if Dest is TFIBAutoUpdateOptions then
    with TFIBAutoUpdateOptions(Dest) do
    begin
      FUpdateTableName := Self.FUpdateTableName;
      FModifiedTable := '';
      FAliasModifiedTable := '';
      // the setter rebuilds KeyFieldList
      KeyFields := Self.FKeyFields;
      FAutoReWriteSqls := Self.FAutoReWriteSqls;
      FCanChangeSQLs := Self.FCanChangeSQLs;
      FGeneratorName := Self.FGeneratorName;
      FGeneratorStep := Self.FGeneratorStep;
      FSelectGenID := Self.FSelectGenID;
      FGenBeforePost := Self.FGenBeforePost;
      FUpdateOnlyModifiedFields := Self.FUpdateOnlyModifiedFields;
      FWhenGetGenID := Self.FWhenGetGenID;
      FParamFieldLinks.Assign(Self.FParamFieldLinks);
      FModifiedTableHaveAlias := Self.FModifiedTableHaveAlias;
      FSeparateBlobUpdate := Self.FSeparateBlobUpdate;
      FAutoParamsToFields := Self.FAutoParamsToFields;
      FUseExecuteBlock := Self.FUseExecuteBlock;
      FReturningFields := Self.FReturningFields;
      FUseRowsClause := Self.FUseRowsClause;
    end
  else
    inherited AssignTo(Dest)
end;

procedure TFIBAutoUpdateOptions.DefineProperties(Filer: TFiler);
begin
  if Filer is TReader then
  begin
    // For oldest dfm
    Filer.DefineProperty('SelectGenID', ReadSelectGenID, nil, False);
    Filer.DefineProperty('GenBeforePost', ReadGenBeforePost, nil, False);
  end;
end;

procedure TFIBAutoUpdateOptions.ReadSelectGenID(Reader: TReader);
begin
  FSelectGenID := Reader.ReadBoolean;
  if FSelectGenID then
    FWhenGetGenID := wgBeforePost
  else
    FWhenGetGenID := wgNever;
end;

procedure TFIBAutoUpdateOptions.ReadGenBeforePost(Reader: TReader);
begin
  FGenBeforePost := Reader.ReadBoolean;
  if not FSelectGenID then
    exit;
  if FGenBeforePost then
    FWhenGetGenID := wgBeforePost
  else
    FWhenGetGenID := wgOnNewRecord
end;

procedure TFIBAutoUpdateOptions.SetUpdateTableName(const Value: string);
var
  MT: string;
begin
  FWhereCondition := '';
  FUpdateTableName := Value;
  FModifiedTable := '';
  FAliasModifiedTable := '';
  FModifiedTableHaveAlias := PosAlias(Value) > 0;

  if (FGeneratorName = '') and (WhenGetGenID <> wgNever) then
  begin
    MT := GetModifiedTable;
    if (Length(MT) > 0) and (MT[1] = '"') then
    begin
      MT := FastCopy(MT, 2, Length(MT) - 2);
      FGeneratorName := '"' + DefPrefixGenName + MT + DefSuffixGenName + '"'
    end
    else
      FGeneratorName := DefPrefixGenName + MT + DefSuffixGenName;
  end;
  FModified := True;
end;

// for compatibility only
function TFIBAutoUpdateOptions.GetSelectGenID: Boolean;
begin
  result := FWhenGetGenID <> wgNever
end;

procedure TFIBAutoUpdateOptions.SetSelectGenID(Value: Boolean);
begin
  if not Value then
    FWhenGetGenID := wgNever
  else if FWhenGetGenID = wgNever then
    FWhenGetGenID := wgBeforePost;
end;

function TFIBAutoUpdateOptions.GetGenBeforePost: Boolean;
begin
  result := FWhenGetGenID in [wgBeforePost, wgNever]
end;

procedure TFIBAutoUpdateOptions.SetGenBeforePost(Value: Boolean);
begin
  if FWhenGetGenID <> wgNever then
    if Value then
      FWhenGetGenID := wgBeforePost
    else
      FWhenGetGenID := wgOnNewRecord;
end;

procedure TFIBAutoUpdateOptions.SetParamFieldLinks(const Value: TStrings);
begin
  FParamFieldLinks.Assign(Value);
  DeleteEmptyStr(FParamFieldLinks)
end;

procedure TFIBAutoUpdateOptions.SetReturningFields(const Value: TFIBReturningFields);
begin
  FReturningFields := Value;
  FModified := True;
end;

const
  DefDateFormat = 'dd.mm.yyyy';
  DefTimeFormat = 'hh:nn';

  // TFIBFormatFields
constructor TFIBFormatFields.Create(aOwner: TComponent);
begin
  FOwner := aOwner;
  if FF_UseRuntimeDefaults then
  begin
    FDisplayFormatDateTime := RDefDateFormat + ' ' + RDefTimeFormat;
    FDisplayFormatNumeric := RDefDisplayFormatNum;
    FEditFormatNumeric := RDefEditFormatNum;
    FDisplayFormatDate := RDefDateFormat;
    FDisplayFormatTime := RDefTimeFormat;
  end
  else if Assigned(FOwner) and (csDesigning in FOwner.ComponentState) and not CmpInLoadedState(FOwner) then
  begin
    FDisplayFormatDateTime := dDefDateTimeFormat;
    FDisplayFormatNumeric := dDefDisplayFormatNum;
    FEditFormatNumeric := dDefEditFormatNum;
    FDisplayFormatDate := dDefDateFormat;
    FDisplayFormatTime := dDefTimeFormat;
  end
  else
  begin
    FDisplayFormatDateTime := DefDateFormat + ' ' + DefTimeFormat;
    FDisplayFormatNumeric := '#,##0.';
    FEditFormatNumeric := '0.';
    FDisplayFormatDate := DefDateFormat;
    FDisplayFormatTime := DefTimeFormat;
  end;
end;

function TFIBFormatFields.StoreDfT: Boolean;
begin
  if FF_UseRuntimeDefaults then
    result := FDisplayFormatTime <> RDefTimeFormat
  else
    result := FDisplayFormatTime <> DefTimeFormat
end;

function TFIBFormatFields.StoreDfD: Boolean;
begin
  if FF_UseRuntimeDefaults then
    result := FDisplayFormatDate <> RDefDateFormat
  else
    result := FDisplayFormatDate <> DefDateFormat;
end;

function TFIBFormatFields.StoreDfDt: Boolean;
begin
  if FF_UseRuntimeDefaults then
    result := FDisplayFormatDateTime <> RDefDateFormat + ' ' + RDefTimeFormat
  else
    result := FDisplayFormatDateTime <> DefDateFormat + ' ' + DefTimeFormat;
end;

function TFIBFormatFields.StoreDfN: Boolean;
begin
  if FF_UseRuntimeDefaults then
    result := FDisplayFormatNumeric <> RDefDisplayFormatNum
  else
    result := FDisplayFormatNumeric <> '#,##0.';
end;

function TFIBFormatFields.StoreEfN: Boolean;
begin
  if FF_UseRuntimeDefaults then
    result := FEditFormatNumeric <> RDefEditFormatNum
  else
    result := FEditFormatNumeric <> '0.';
end;

procedure TFIBFormatFields.AssignTo(Dest: TPersistent);
begin
  if Dest is TFIBFormatFields then
    with TFIBFormatFields(Dest) do
    begin
      FDisplayFormatDateTime := Self.FDisplayFormatDateTime;
      FDisplayFormatDate := Self.FDisplayFormatDate;
      FDisplayFormatTime := Self.FDisplayFormatTime;
      FDisplayFormatNumeric := Self.FDisplayFormatNumeric;
      FEditFormatNumeric := Self.FEditFormatNumeric;
    end
  else
    inherited AssignTo(Dest)
end;

/// TFIBConnectParams

constructor TFIBConnectParams.Create(Owner: TComponent);
begin
  inherited Create;
  FOwner := Owner;
  FIsFirebird := True;
{$IFDEF SUPPORT_IB2007}
  FIBParams := TFIBInterBaseConnectParams.Create(Owner);
{$ENDIF}
end;

destructor TFIBConnectParams.Destroy;
begin
{$IFDEF SUPPORT_IB2007}
  FIBParams.Free;
{$ENDIF}
  inherited Destroy
end;

function TFIBConnectParams.GetUserNameA: string;
begin
  result := '';
  if Assigned(FOwner) and (FOwner is TFIBDataBase) then
    with TFIBDataBase(FOwner) do
    begin
      result := DBParamByDPB[isc_dpb_user_name];
    end;
end;

procedure TFIBConnectParams.SetUserName(const Value: string);
begin
  if Assigned(FOwner) and (FOwner is TFIBDataBase) then
    with TFIBDataBase(FOwner) do
      DBParamByDPB[isc_dpb_user_name] := Value
end;

function TFIBConnectParams.GetRoleName: string;
begin
  result := '';
  if Assigned(FOwner) and (FOwner is TFIBDataBase) then
    with TFIBDataBase(FOwner) do
    begin
      result := DBParamByDPB[isc_dpb_sql_role_name];
    end;
end;

procedure TFIBConnectParams.SetRoleName(const Value: string);
begin
  if Assigned(FOwner) and (FOwner is TFIBDataBase) then
    with TFIBDataBase(FOwner) do
      DBParamByDPB[isc_dpb_sql_role_name] := Value
end;

function TFIBConnectParams.GetPassword: string;
begin
  result := '';
  if Assigned(FOwner) and (FOwner is TFIBDataBase) then
    with TFIBDataBase(FOwner) do
    begin
      result := DBParamByDPB[isc_dpb_password];
    end;
end;

procedure TFIBConnectParams.SetPassword(const Value: string);
begin
  if Assigned(FOwner) and (FOwner is TFIBDataBase) then
    with TFIBDataBase(FOwner) do
      DBParamByDPB[isc_dpb_password] := Value
end;

function TFIBConnectParams.GetCharSet: string;
begin
  result := '';
  if Assigned(FOwner) and (FOwner is TFIBDataBase) then
    with TFIBDataBase(FOwner) do
    begin
      result := DBParamByDPB[isc_dpb_lc_ctype];
    end;
end;

procedure TFIBConnectParams.SetCharSet(const Value: string);
begin
  if Assigned(FOwner) and (FOwner is TFIBDataBase) then
    with TFIBDataBase(FOwner) do
      DBParamByDPB[isc_dpb_lc_ctype] := FastUpperCase(Value)
end;

// Same rules as the boolean values of firebird.conf
function IsConfigTrue(const Value: string): Boolean;
begin
  result := SameText(Value, 'true') or SameText(Value, 'yes') or SameText(Value, 'y') or (StrToIntDef(Value, 0) <> 0);
end;

function TFIBConnectParams.GetWireCompression: Boolean;
begin
  result := Assigned(FOwner) and (FOwner is TFIBDataBase) and
    IsConfigTrue(TFIBDataBase(FOwner).ConfigParam['WireCompression']);
end;

procedure TFIBConnectParams.SetWireCompression(const Value: Boolean);
const
  ConfigValues: array [Boolean] of string = ('', 'true');
begin
  if Assigned(FOwner) and (FOwner is TFIBDataBase) then
    TFIBDataBase(FOwner).ConfigParam['WireCompression'] := ConfigValues[Value];
end;

function TFIBConnectParams.GetParallelWorkers: Integer;
begin
  Result := 0;
  if Assigned(FOwner) and (FOwner is TFIBDataBase) then
    Result := StrToIntDef(TFIBDataBase(FOwner).DBParamByDPB[isc_dpb_parallel_workers], 0);
end;

procedure TFIBConnectParams.SetParallelWorkers(const Value: Integer);
begin
  if Assigned(FOwner) and (FOwner is TFIBDataBase) then
    if Value > 0 then
      TFIBDataBase(FOwner).DBParamByDPB[isc_dpb_parallel_workers] := IntToStr(Value)
    else
      TFIBDataBase(FOwner).DBParamByDPB[isc_dpb_parallel_workers] := '';
end;

{$IFDEF SUPPORT_IB2007}
procedure TFIBConnectParams.SetIBParams(const Value: TFIBInterBaseConnectParams);
begin
  FIBParams.Assign(Value);
end;

{ TFIBInterBaseConnectParams }
constructor TFIBInterBaseConnectParams.Create(Owner: TComponent);
begin
  inherited Create;
  FOwner := Owner
end;

function TFIBInterBaseConnectParams.GetInstanceName: string;
begin
  result := '';
  if Assigned(FOwner) and (FOwner is TFIBDataBase) then
    with TFIBDataBase(FOwner) do
    begin
      result := DBParamByDPB[isc_dpb_instance_name];
    end;
end;

procedure TFIBInterBaseConnectParams.SetInstanceName(const Value: string);
begin
  if Assigned(FOwner) and (FOwner is TFIBDataBase) then
    with TFIBDataBase(FOwner) do
      DBParamByDPB[isc_dpb_instance_name] := Value
end;
{$ENDIF}
{ TFIBSQLs }

constructor TFIBSQLs.Create(Owner: TComponent);
begin
  inherited Create;
  FOwner := Owner;
end;

function TFIBSQLs.GetDeleteSQL: TStrings;
begin
  result := TFIBDataSet(FOwner).DeleteSQL
end;

function TFIBSQLs.GetInsertSQL: TStrings;
begin
  result := TFIBDataSet(FOwner).InsertSQL
end;

function TFIBSQLs.GetRefreshSQL: TStrings;
begin
  result := TFIBDataSet(FOwner).RefreshSQL
end;

function TFIBSQLs.GetSelectSQL: TStrings;
begin
  result := TFIBDataSet(FOwner).SelectSQL
end;

function TFIBSQLs.GetUpdateSQL: TStrings;
begin
  result := TFIBDataSet(FOwner).UpdateSQL
end;

procedure TFIBSQLs.SetDeleteSQL(Value: TStrings);
begin
  TFIBDataSet(FOwner).DeleteSQL := Value
end;

procedure TFIBSQLs.SetInsertSQL(Value: TStrings);
begin
  TFIBDataSet(FOwner).InsertSQL := Value
end;

procedure TFIBSQLs.SetRefreshSQL(Value: TStrings);
begin
  TFIBDataSet(FOwner).RefreshSQL := Value
end;

procedure TFIBSQLs.SetSelectSQL(Value: TStrings);
begin
  TFIBDataSet(FOwner).SelectSQL := Value
end;

procedure TFIBSQLs.SetUpdateSQL(Value: TStrings);
begin
  TFIBDataSet(FOwner).UpdateSQL := Value
end;

{ TFIBCacheSchemaOptions }

constructor TFIBCacheSchemaOptions.Create;
begin
  inherited Create;
  FValidateAfterLoad := True;
end;

procedure TFIBCacheSchemaOptions.Assign(Source: TPersistent);
begin
  if Source is TFIBCacheSchemaOptions then
  begin
    FLocalCacheFile := TFIBCacheSchemaOptions(Source).LocalCacheFile;
    FAutoSaveToFile := TFIBCacheSchemaOptions(Source).AutoSaveToFile;
    FAutoLoadFromFile := TFIBCacheSchemaOptions(Source).AutoLoadFromFile;
    FValidateAfterLoad := TFIBCacheSchemaOptions(Source).ValidateAfterLoad;
  end
  else
    inherited Assign(Source);
end;

{ TFIBDBParams }

constructor TFIBDBParams.Create(aOwner: TComponent);
begin
  inherited Create;
  FOwner := aOwner;
end;

procedure TFIBDBParams.DefineProperties(Filer: TFiler);
  function DoWrite: Boolean;
  begin
    if Filer.Ancestor <> nil then
    begin
      result := True;
      if Filer.Ancestor is TStrings then
        result := not Equals(TStrings(Filer.Ancestor))
    end
    else
      result := Count > 0;
  end;

begin
  Filer.DefineProperty('Strings', ReadData, WriteData, DoWrite);
end;

procedure TFIBDBParams.ReadData(Reader: TReader);
begin
  Reader.ReadListBegin;
  BeginUpdate;
  try
    Clear;
    while not Reader.EndOfList do
      Add(Reader.ReadString);
  finally
    EndUpdate;
  end;
  Reader.ReadListEnd;
end;

procedure TFIBDBParams.WriteData(Writer: TWriter);
var
  I: Integer;
  OldPassword: string;
begin
  if (FOwner is TFIBDataBase) and (ddoNotSavePassword in TFIBDataBase(FOwner).DesignDBOptions) then
  begin
    OldPassword := TFIBDataBase(FOwner).ConnectParams.Password;
    TFIBDataBase(FOwner).ConnectParams.Password := '';
  end;
  try
    Writer.WriteListBegin;
    for I := 0 to Count - 1 do
      Writer.WriteString(Get(I));
    Writer.WriteListEnd;
  finally
    if (FOwner is TFIBDataBase) and (ddoNotSavePassword in TFIBDataBase(FOwner).DesignDBOptions) then
    begin
      TFIBDataBase(FOwner).ConnectParams.Password := OldPassword;
    end;
  end;
end;

{ TFIBConditions }

constructor TFIBConditions.Create(aOwner: TComponent);
begin
  inherited Create;
  FFIBQuery := aOwner;
end;

destructor TFIBConditions.Destroy;
var
  I: Integer;
begin
  for I := Count - 1 downto 0 do
  begin
    Objects[I].Free;
  end;
  inherited Destroy;
end;

procedure TFIBConditions.Put(Index: Integer; const S: string);
begin
  if Index = Count then
    AddObject(S, TFIBCondition.Create(Self))
  else
    inherited Put(Index, S)
end;

function TFIBConditions.Add(const S: string): Integer;
begin
  result := inherited Add(S);
  Objects[result] := TFIBCondition.Create(Self);
end;

function TFIBConditions.AddCondition(const Name, Condition: string; Enabled: Boolean): TFIBCondition;
var
  I: Integer;
begin
  I := IndexOfName(Name);
  if I = -1 then
  begin
    I := Add(Name + '=' + Condition);
    result := TFIBCondition(Objects[I]);
  end
  else
  begin
    result := TFIBCondition(Objects[I]);
    result.Value := Condition;
  end;

  result.FEnabled := Enabled;
  if Enabled then
    FApplied := False
end;

function TFIBConditions.FindCondition(const Name: string): TFIBCondition;
var
  I: Integer;
begin
  I := IndexOfName(Name);
  if I < 0 then
    result := nil
  else
    result := TFIBCondition(Objects[I]);
end;

function TFIBConditions.ByName(const Name: string): TFIBCondition;
begin
  result := FindCondition(Name);
  if result = nil then
    raise Exception.Create('Can''t find Condition ' + Name);
end;

procedure TFIBConditions.Remove(const Name: string);
var
  Ind: Integer;
begin
  Ind := IndexOfName(Name);
  if Ind <> -1 then
  begin
    Delete(Ind);
    FApplied := False
  end;
end;

function TFIBConditions.GetEnabledText: string;
var
  I, c: Integer;
begin
  result := '';
  c := Pred(Count);
  if c < 0 then
    exit;
  for I := 0 to c do
    if TFIBCondition(Objects[I]).Enabled and not IsBlank(Strings[I]) then
    begin
      result := result + '(' + ValueFromStr(Strings[I]) + ')' + sLineBreak;
      result := result + sLineBreak + ' and ';
    end;
  if not IsBlank(result) then
    SetLength(result, Length(result) - 7);
end;

procedure TFIBConditions.Apply;
var
  Wh, Wh1: string;
begin
  with TFIBQuery(FFIBQuery) do
  begin
    BeginModifySQLText;
    Include(FState, csInApply);
    try
      Wh1 := Conditions.EnabledText;
      if IsBlank(FPrimarySQL) then
        FPrimarySQL := SQL.Text
      else
        RestorePrimarySQL;
      if not IsBlank(Wh1) then
      begin
        Wh := GetMainWhereClause;
        if Wh <> '' then
          Wh := Wh + sLineBreak + 'and ' + Wh1
        else
          Wh := Wh1;
        SetMainWhereClause(Wh);
      end;
      FApplied := True;
    finally
      EndModifySQLText;
      Exclude(FState, csInApply);
    end;
  end;
end;

procedure TFIBConditions.CancelApply;
begin
  if (FApplied) and (FState = []) then
    try
      Include(FState, csInCancel);
      RestorePrimarySQL
    finally
      Exclude(FState, csInCancel);
    end;
end;

procedure TFIBConditions.RestorePrimarySQL;
begin
  Include(FState, csInRestorePrimarySQL);
  try
    FApplied := False;
    if not IsBlank(FPrimarySQL) then
      if TFIBQuery(FFIBQuery).SQL.Text <> FPrimarySQL then
        TFIBQuery(FFIBQuery).SQL.Text := FPrimarySQL;
  finally
    Exclude(FState, csInRestorePrimarySQL);
  end
end;

function TFIBConditions.GetCondition(Index: Integer): TFIBCondition;
begin
  if (Index < 0) or (Index >= Count) then
    result := nil
  else
    result := TFIBCondition(Objects[Index]);
end;

function TFIBConditions.AddObject(const S: string; AObject: TObject): Integer;
begin
  if (AObject is TFIBCondition) or (AObject = nil) then
    result := inherited AddObject(S, AObject)
  else
    result := -1
end;

procedure TFIBConditions.Clear;
var
  I: Integer;
begin
  for I := Count - 1 downto 0 do
  begin
    Objects[I].Free;
  end;
  inherited;
end;

procedure TFIBConditions.Delete(Index: Integer);
begin
  if not Condition[Index].FInDestroy then
    Condition[Index].Free
  else
    inherited;
end;

procedure TFIBConditions.DefineProperties(Filer: TFiler);

  function DoWriteConditions: Boolean;
  var
    I: Integer;
  begin
    result := False;
    if (Filer is TReader) then
      exit;
    if (Filer.Ancestor <> nil) then
    begin
      if not(Filer.Ancestor is TFIBConditions) then
        result := False
      else if not Equals(TStrings(Filer.Ancestor)) then
        result := True
      else
      begin
        for I := 0 to Pred(Count) do
          if (TFIBConditions(Filer.Ancestor).Condition[I].Enabled <> Condition[I]
            .Enabled) or (TFIBConditions(Filer.Ancestor).Condition[I].Name <> Condition[I].Name) then
          begin
            result := True;
            exit;
          end;
      end;
    end
    else
    begin
      result := Count > 0;
    end;
  end;

var
  HasData: Boolean;
begin
  Filer.DefineProperty('Strings', ReadStrings, nil, False);
  Filer.DefineProperty('Enabled', ReadEnabled, nil, False);
  if Assigned(FFIBQuery) and (csAncestor in FFIBQuery.ComponentState) and
    not((Filer is TReader) or (Filer is TWriter)) then
    HasData := False
  else
    HasData := DoWriteConditions;
  Filer.DefineProperty('Data', ReadData, WriteData, HasData);
end;

procedure TFIBConditions.ReadEnabled(Reader: TReader);
var
  S: string;
  I, j: Integer;
begin
  S := Reader.ReadString;
  I := 2;
  while I < Length(S) do
  begin
    j := (I div 2) - 1;
    if j < Count then
    begin
      Condition[j].Enabled := S[I] = '1';
      Inc(I, 2)
    end
    else
      exit;
  end
end;

const
  ExchangeDelimeter = '#$#$';

procedure TFIBConditions.WriteToExchangeStrings(Dest: TStrings);
var
  I: Integer;
begin
  for I := 0 to Pred(Count) do
  begin
    Dest.Add(Condition[I].Name + ExchangeDelimeter + Condition[I].Value +
      ExchangeDelimeter + IntToStr(Ord(Condition[I].Enabled)));
  end;
end;

function TFIBConditions.ExchangeString: string;
var
  ts: TStrings;
begin
  ts := TStringList.Create;
  try
    WriteToExchangeStrings(ts);
    result := ts.Text
  finally
    ts.Free
  end;
end;

procedure TFIBConditions.ReadFromExchangeStrings(Source: TStrings);
var
  I: Integer;
  p: Integer;
  CondName, CondBody: string;
  S: string;
begin
  Clear;
  for I := 0 to Pred(Source.Count) do
  begin
    S := Source[I];
    p := Pos(ExchangeDelimeter, S);
    CondName := FastCopy(S, 1, p - 1);
    S := FastCopy(S, p + Length(ExchangeDelimeter), MaxInt);
    p := Pos(ExchangeDelimeter, S);
    CondBody := FastCopy(S, 1, p - 1);
    S := FastCopy(S, p + Length(ExchangeDelimeter), MaxInt);
    AddCondition(CondName, CondBody, FastTrim(S) = '1')
  end;
end;

procedure TFIBConditions.ReadFromExchangeString(const Source: string);
var
  ts: TStrings;
begin
  ts := TStringList.Create;
  try
    ts.Text := Source;
    ReadFromExchangeStrings(ts);
  finally
    ts.Free
  end;
end;

procedure TFIBConditions.ReadStrings(Reader: TReader);
begin
  Reader.ReadListBegin;
  BeginUpdate;
  try
    Clear;
    while not Reader.EndOfList do
    begin
      Add(Reader.ReadString);
    end;
  finally
    EndUpdate;
  end;
  Reader.ReadListEnd;
end;

procedure TFIBConditions.ReadData(Reader: TReader);
var
  N, V: string;
  En: Boolean;
  Index: Integer;
  Deleted: Boolean;
  c: TFIBCondition;
begin
  Reader.ReadListBegin;
  BeginUpdate;
  Deleted := False;
  try
    while not Reader.EndOfList do
    begin
      if Deleted then
      begin
        Remove(Reader.ReadString);
      end
      else
      begin
        N := Reader.ReadString;
        Deleted := (N = '#@DELETED');
        if not Deleted then
        begin
          V := Reader.ReadString;
          En := Reader.ReadBoolean;
          Index := IndexOfName(N);
          if (Index < 0) then
          begin
            if (V <> '0') then
            begin
              if V = '''' then
                V := '';
              c := AddCondition(N, V, En);
              c.FEnabledFromStream := True;
              c.FValueFromStream := True;
            end;
          end
          else
          begin
            if Index >= 0 then
            begin
              if Condition[Index].FEnabledFromStream then
                Condition[Index].SetEnabledFromStream(En);
              if (V <> '0') and Condition[Index].FValueFromStream then
                Condition[Index].SetValueFromStream(V);
            end;
          end;
        end;
      end;
    end;
  finally
    EndUpdate;
  end;
  Reader.ReadListEnd;
end;

procedure TFIBConditions.WriteData(Writer: TWriter);
var
  I, j: Integer;
  Index: Integer;
  N, V: string;

begin
  Writer.WriteListBegin;
  for I := 0 to Count - 1 do
  begin
    N := Names[I];
    if Writer.Ancestor = nil then
    begin
      V := Values[N];
      Writer.WriteString(N);
      if V = '' then
        V := '''';
      Writer.WriteString(V);
      Writer.WriteBoolean(Condition[I].Enabled);
    end
    else
    begin
      Index := TFIBConditions(Writer.Ancestor).IndexOfName(N);
      if Index < 0 then
      begin
        Writer.WriteString(N);
        V := ValueFromStr(Get(I));
        if V = '' then
          V := '''';
        Writer.WriteString(V);
        Writer.WriteBoolean(Condition[I].Enabled);
      end
      else
      begin
        V := ValueFromStr(Get(I));
        if V = ValueFromStr(TFIBConditions(Writer.Ancestor).Strings[Index]) then
          V := '0';
        if (V <> '0') or (Condition[I].Enabled <> TFIBConditions(Writer.Ancestor).Condition[Index].Enabled) then
        begin
          Writer.WriteString(N);
          Writer.WriteString(V);
          Writer.WriteBoolean(Condition[I].Enabled);
        end;
      end;
    end;
  end;
  if (Writer.Ancestor <> nil) then
  begin
    j := 0;
    for I := 0 to TFIBConditions(Writer.Ancestor).Count - 1 do
      if FindCondition(TFIBConditions(Writer.Ancestor).Condition[I].Name) = nil then
      begin
        Inc(j);
        if j = 1 then
          Writer.WriteString('#@DELETED');
        Writer.WriteString(TFIBConditions(Writer.Ancestor).Condition[I].Name);
      end;
  end;
  Writer.WriteListEnd;
end;

{ TFIBCondition }

constructor TFIBCondition.Create(aOwner: TFIBConditions);
begin
  inherited Create;
  FOwner := aOwner;
end;

destructor TFIBCondition.Destroy;
var
  I: Integer;
begin
  if FInDestroy then
    exit;
  FInDestroy := True;
  I := FOwner.IndexOfObject(Self);
  if I >= 0 then
    FOwner.Delete(I);
  inherited Destroy;
end;

function TFIBCondition.GetName: string;
var
  I: Integer;
begin
  I := FOwner.IndexOfObject(Self);
  if I < 0 then
    result := ''
  else
    result := FOwner.Names[I];
end;

function TFIBCondition.GetValue: string;
var
  I: Integer;
begin
  I := FOwner.IndexOfObject(Self);
  if I < 0 then
    result := ''
  else
    result := ValueFromStr(FOwner.Strings[I]);
end;

procedure TFIBCondition.SetEnabled(const Value: Boolean);
begin
  if FEnabled <> Value then
  begin
    FOwner.FApplied := False;
    FEnabled := Value;
    FEnabledFromStream := False;
  end;
end;

procedure TFIBCondition.SetEnabledFromStream(const Value: Boolean);
begin
  SetEnabled(Value);
  FEnabledFromStream := True;
end;

procedure TFIBCondition.SetName(const Name: string);
var
  I: Integer;
begin
  I := FOwner.IndexOfObject(Self);
  if I >= 0 then
    FOwner.Strings[I] := Name + '=' + ValueFromStr(FOwner.Strings[I]);
end;

procedure TFIBCondition.SetValue(const Value: string);
var
  I: Integer;
begin
  I := FOwner.IndexOfObject(Self);
  if (I >= 0) and (FOwner.Strings[I] <> FOwner.Names[I] + '=' + Value) then
  begin
    FOwner.Strings[I] := FOwner.Names[I] + '=' + Value;
    FValueFromStream := False
  end;
end;

procedure TFIBCondition.SetValueFromStream(const Value: string);
begin
  SetValue(Value);
  FValueFromStream := True
end;

function TFIBAutoUpdateOptions.UpdateOnlyModifiedFieldsInEffect: Boolean;
begin
  // The property is kept as assigned, in any order; it works only with these two
  Result := FUpdateOnlyModifiedFields and FAutoReWriteSqls and FCanChangeSQLs;
end;

procedure TFIBAutoUpdateOptions.SetKeyFields(const Value: string);
var
  Pos: Integer;
begin
  FWhereCondition := '';
  FKeyFieldList.Clear;
  Pos := 1;
  while Pos <= Length(Value) do
  begin
    FKeyFieldList.Add(ExtractFieldName(Value, Pos));
  end;
  FKeyFields := Value;
  FModified := True;
end;

{ TFIBBlobSwapSupport }

constructor TFIBBlobSwapSupport.Create;
begin
  inherited Create;
  FSwapDirectory := AppPathTemplate;
  FTables := TStringList.Create;
end;

destructor TFIBBlobSwapSupport.Destroy;
begin
  FTables.Free;
  inherited Destroy;
end;

procedure TFIBBlobSwapSupport.Assign(Source: TPersistent);
begin
  if Source is TFIBBlobSwapSupport then
  begin
    FActive := TFIBBlobSwapSupport(Source).FActive;
    FAutoValidateSwap := TFIBBlobSwapSupport(Source).FAutoValidateSwap;
    FSwapDirectory := TFIBBlobSwapSupport(Source).FSwapDirectory;
    FMinBlobSizeToSwap := TFIBBlobSwapSupport(Source).FMinBlobSizeToSwap;
    FTables.Assign(TFIBBlobSwapSupport(Source).FTables);
  end
  else
    inherited Assign(Source);
end;

function TFIBBlobSwapSupport.GetSwapDirectory: string;
begin
  if not Active then
  begin
    result := '';
    exit;
  end;
  if FastUpperCase(Copy(FSwapDirectory, 1, Length(AppPathTemplate))) = AppPathTemplate then
    result := ApplicationPath + Copy(FSwapDirectory, Length(AppPathTemplate) + 1, MaxInt)
  else
    result := FSwapDirectory;

  if (Length(result) > 0) and (result[Length(result)] <> '\') then
    result := result + '\';
end;

function TFIBBlobSwapSupport.StoreSwapDir: Boolean;
begin
  result := FSwapDirectory <> AppPathTemplate
end;

procedure TFIBBlobSwapSupport.SetTables(aTables: TStrings);
begin
  FTables.Assign(aTables)
end;

function TFIBBlobSwapSupport.StoreTables: Boolean;
begin
  result := Trim(FTables.Text) <> ''
end;

function TFIBAutoUpdateOptions.GetAliasModifiedTable: string;
begin
  PrepareUpdateTableStrings;
  result := FAliasModifiedTable
end;

function TFIBAutoUpdateOptions.GetModifiedTable: string;
begin
  PrepareUpdateTableStrings;
  result := FModifiedTable
end;

procedure TFIBAutoUpdateOptions.PrepareUpdateTableStrings;
var
  Dialect: Integer;
  TableInSQL, TableAlias: string;
begin
  if Length(FModifiedTable) = 0 then
  begin
    if Assigned(FOwner) and Assigned(TFIBDataSet(FOwner).Database) then
      Dialect := TFIBDataSet(FOwner).Database.SQLDialect
    else
      Dialect := 3;
    if FModifiedTableHaveAlias then
    begin
      FModifiedTable := CutTableName(UpdateTableName);
      FAliasModifiedTable := NormalizeIdentifier(Dialect, CutAlias(UpdateTableName));
    end
    else
    begin
      FModifiedTable := UpdateTableName;
      FAliasModifiedTable := UpdateTableName;
      if FOwner <> nil then
      begin
        // AliasForTable compares SQL text: the stored name is looked up as the generated SQL writes it
        if Assigned(TFIBDataSet(FOwner).Database) then
          TableInSQL := EasyFormatIdentifier(Dialect, UpdateTableName, TFIBDataSet(FOwner).Database.EasyFormatsStr)
        else
          TableInSQL := FormatIdentifier(Dialect, UpdateTableName);
        TableAlias := AliasForTable(TFIBDataSet(FOwner).QSelect.ReadySQLText(False), TableInSQL);
        // An alias found in SelectSQL is SQL text: unquoted means uppercase
        if TableAlias <> TableInSQL then
          FAliasModifiedTable := NormalizeIdentifier(Dialect, TableAlias);
      end;
    end;
    if Assigned(FOwner) and Assigned(TFIBDataSet(FOwner).Database) then
      with TFIBDataSet(FOwner).Database do
      begin
        FModifiedTable := EasyFormatIdentifier(SQLDialect, FModifiedTable, EasyFormatsStr);
        FAliasModifiedTable := EasyFormatIdentifier(SQLDialect, FAliasModifiedTable, EasyFormatsStr);
      end;
  end;
end;

{$IFDEF CSMonitor}
{ TFIBCSMonitorSupport }

constructor TFIBCSMonitorSupport.Create(aOwner: TComponent);
begin
  inherited Create;
  FOwner := aOwner;
  FIncludeDatasetDescription := True;
  if (FOwner is TFIBQuery) or (FOwner is TFIBDataSet) then
    FEnabled := csmeTransactionDriven
  else if FOwner is TFIBTransaction then
    FEnabled := csmeDatabaseDriven
  else if FOwner is TFIBDataBase then
    FEnabled := csmeDisabled;

end;

function TFIBCSMonitorSupport.DoStoreEnabled: Boolean;
begin
  if (FOwner is TFIBQuery) or (FOwner is TFIBDataSet) then
    result := FEnabled <> csmeTransactionDriven
  else if FOwner is TFIBTransaction then
    result := FEnabled <> csmeDatabaseDriven
  else if FOwner is TFIBDataBase then
    result := FEnabled <> csmeDisabled
  else
    result := False
end;

procedure TFIBCSMonitorSupport.SetEnabled(const Value: TFIBCSMonitorEnabled);
begin
  if (FOwner is TFIBTransaction) and not(Value in [csmeDisabled, csmeEnabled, csmeDatabaseDriven]) then
    raise EFIBCSMonitorError.Create('This object cannot use this value');
  if (FOwner is TFIBDataBase) and not(Value in [csmeDisabled, csmeEnabled]) then
    raise EFIBCSMonitorError.Create('This object cannot use this value');
  FEnabled := Value;
  if (FOwner is TFIBDataSet) then
    (FOwner as TFIBDataSet).SetCSMonitorSupportToQ;
end;

procedure TFIBCSMonitorSupport.SetIncludeDatasetDescription(const Value: Boolean);
begin
  FIncludeDatasetDescription := Value;
  if (FOwner is TFIBDataSet) then
    (FOwner as TFIBDataSet).SetCSMonitorSupportToQ;
end;

{$ENDIF}

{ TFIBGeneratorParams }
type
  THackOwnedCollection = class(TOwnedCollection);

constructor TFIBGeneratorParams.Create(Collection: TCollection);
begin
  FStepForCache := TFIBGeneratorsCache(THackOwnedCollection(Collection).GetOwner).DefaultStep;
  FNextValue := -1;
  inherited;
end;

function TFIBGeneratorParams.NextValue: Int64;
begin
  result := FNextValue;
  if FNextValue > -1 then
  begin
    Inc(FNextValue);
    if FNextValue > FLimit then
      FNextValue := -1;
    SaveToFile
  end;
end;

procedure TFIBGeneratorParams.SaveToFile;
var
  Ini: TIniFile;
  CacheFileName: string;
begin
  CacheFileName := TFIBGeneratorsCache(THackOwnedCollection(Collection).GetOwner).FCacheFileName;
  if Length(CacheFileName) > 0 then
  begin
    Ini := TIniFile.Create(CacheFileName);
    try
      with Self do
      begin
        Ini.WriteInteger(Name, 'StepForCache', FStepForCache);
        Ini.WriteString(Name, 'NextValue', IntToStr(FNextValue));
        Ini.WriteString(Name, 'Limit', IntToStr(FLimit));
      end;
    finally
      Ini.Free;
    end;
  end
end;

function TFIBGeneratorParams.StoreStep: Boolean;
begin
  result := FStepForCache <> TFIBGeneratorsCache(THackOwnedCollection(Collection).GetOwner).DefaultStep;
end;

{ TFIBGeneratorsCache }

function TFIBGeneratorsCache.CanWork(const GenName: string): Boolean;
begin
  if Length(FCacheFileName) = 0 then
    result := False
  else
    case FUseGeneratorCache of
      No: result := False;
      forAll: result := True;
    else
      result := Find(GenName) <> nil
    end
end;

constructor TFIBGeneratorsCache.Create(Owner: TComponent);
begin
  inherited Create;
  FOwner := Owner;
  FGenerators := TOwnedCollection.Create(Self, TFIBGeneratorParams);
  FDefaultStep := 50
end;

destructor TFIBGeneratorsCache.Destroy;
begin
  FGenerators.Free;
  inherited;
end;

function TFIBGeneratorsCache.Find(const GenName: string): TFIBGeneratorParams;
var
  I: Integer;
begin
  I := IndexOf(GenName);
  if I < 0 then
    result := nil
  else
    result := TFIBGeneratorParams(FGenerators.Items[I]);
end;

function TFIBGeneratorsCache.GetNextValue(const GenName: string): Int64;
var
  GenParams: TFIBGeneratorParams;
begin
  if not Loaded then
    LoadFromFile;
  GenParams := Find(GenName);
  if GenParams <> nil then
    result := GenParams.NextValue
  else
    result := -1;
end;

function TFIBGeneratorsCache.GetOwner: TPersistent;
begin
  result := FOwner;
end;

function TFIBGeneratorsCache.IndexOf(const AName: string): Integer;
begin
  for result := 0 to FGenerators.Count - 1 do
    if AnsiCompareText(TNamedItem(FGenerators.Items[result]).Name, AName) = 0 then
      exit;
  result := -1;
end;

procedure TFIBGeneratorsCache.LoadFromFile;
var
  Ini: TIniFile;
  I: Integer;
  ts: TStrings;
  curGen: TFIBGeneratorParams;
  S: string;
begin
  if Length(FCacheFileName) > 0 then
  begin
    Ini := TIniFile.Create(FCacheFileName);
    ts := TStringList.Create;
    try
      Ini.ReadSections(ts);
      for I := 0 to ts.Count - 1 do
      begin
        curGen := Find(ts[I]);
        if curGen = nil then
          curGen := TFIBGeneratorParams(FGenerators.Add);
        curGen.Name := ts[I];
        curGen.FStepForCache := Ini.ReadInteger(ts[I], 'StepForCache', DefaultStep);
        S := Ini.ReadString(ts[I], 'NextValue', '-1');
        curGen.FNextValue := StrToInt64Def(S, -1);
        S := Ini.ReadString(ts[I], 'Limit', '-1');
        curGen.FLimit := StrToInt64Def(S, -1);
      end;
    finally
      ts.Free;
      Ini.Free;
    end;
  end;
  FLoaded := True;
end;

procedure TFIBGeneratorsCache.SaveToFile;
var
  Ini: TIniFile;
  I: Integer;
begin
  if Length(FCacheFileName) > 0 then
  begin
    Ini := TIniFile.Create(FCacheFileName);
    try
      for I := 0 to FGenerators.Count - 1 do
        with TFIBGeneratorParams(FGenerators.Items[I]) do
        begin
          Ini.WriteInteger(Name, 'StepForCache', FStepForCache);
          Ini.WriteString(Name, 'NextValue', IntToStr(FNextValue));
          Ini.WriteString(Name, 'Limit', IntToStr(FLimit));
        end;
    finally
      Ini.Free;
    end;
  end
end;

procedure TFIBGeneratorsCache.SetGenerators(const Value: TOwnedCollection);
begin
  FGenerators.Assign(Value);
end;

procedure TFIBGeneratorsCache.InternalSetGenParams(const GenName: string; Limit: Int64);
var
  GenParams: TFIBGeneratorParams;
begin
  GenParams := Find(GenName);
  if GenParams = nil then
    if FUseGeneratorCache = forAll then
    begin
      GenParams := TFIBGeneratorParams(FGenerators.Add);
      GenParams.Name := GenName
    end;
  if GenParams <> nil then
  begin
    GenParams.FLimit := Limit;
    GenParams.FNextValue := Limit - GenParams.FStepForCache + 1;
    GenParams.SaveToFile
  end;
end;

function TFIBGeneratorsCache.GetStep(const GenName: string): Integer;
var
  GenParams: TFIBGeneratorParams;
begin
  GenParams := Find(GenName);
  if GenParams <> nil then
    result := GenParams.FStepForCache
  else
    result := DefaultStep
end;

procedure TFIBGeneratorsCache.AddGenerator(const GenName: string; Limit: Int64);
var
  GenParams: TFIBGeneratorParams;
begin
  GenParams := Find(GenName);
  if GenParams = nil then
  begin
    GenParams := TFIBGeneratorParams(FGenerators.Add);
    GenParams.Name := GenName;
    GenParams.FLimit := Limit;
  end;
end;

procedure TFIBGeneratorsCache.RemoveGenerator(const GenName: string);
var
  I: Integer;
begin
  I := IndexOf(GenName);
  if I >= 0 then
    FGenerators.Delete(I)
end;

function TFIBGeneratorsCache.DoSaveGenList: Boolean;
begin
  result := FGenerators.Count > 0
end;

{ TFIBMemoSubtypes }

function TFIBMemoSubtypes.IsMemoSubtype(aSubtype: SmallInt): Boolean;
var
  I: NativeInt;
begin
  result := False;
  for I := 0 to High(FSubTypes) do
    if aSubtype = FSubTypes[I] then
    begin
      result := True;
      Break
    end;

end;

procedure TFIBMemoSubtypes.SetSubTypes(const SubTypesStr: string);
var
  wc, I: Integer;
  SubType: Integer;
  S: string;
begin
  FActive := False;
  wc := WordCount(SubTypesStr, [';']);
  SetLength(FSubTypes, wc);
  FSubTypesStr := '';
  for I := 1 to wc do
  begin
    S := ExtractWord(I, SubTypesStr, [';']);
    SubType := StrToIntDef(S, 1);
    // out of the SMALLINT range: ignored, as text that is not a number
    if (SubType < Low(SmallInt)) or (SubType > High(SmallInt)) then
      SubType := 1;
    FSubTypes[I - 1] := SmallInt(SubType);
    if FSubTypes[I - 1] <> 1 then
    begin
      FActive := True;
      FSubTypesStr := FSubTypesStr + S + ';'
    end;
  end;
  SetLength(FSubTypesStr, Length(FSubTypesStr) - 1)
end;

// StreamRtn
procedure WriteStrToStream(const s: AnsiString; Stream: TStream);
var
  L: Integer;
begin
  L := Length(s);
  with Stream do
  begin
    WriteBuffer(L, SizeOf(Integer));
    if L > 0 then
      WriteBuffer(s[1], L);
  end;
end;

procedure ReadStrFromStream(const Stream: TStream; var ResStr: AnsiString);
var
  L: Integer;
begin
  with Stream do
  begin
    ReadBuffer(L, SizeOf(Integer));
    SetLength(ResStr, L);
    if L > 0 then
      ReadBuffer(ResStr[1], L);
  end;
end;

procedure WriteUTF8StrToStream(const S: string; Stream: TStream);
begin
  WriteStrToStream(UTF8Encode(S), Stream);
end;

function ReadUTF8StrFromStream(const Stream: TStream; UTF8: Boolean = True): string;
var
  S: AnsiString;
begin
  ReadStrFromStream(Stream, S);
  if UTF8 then
    Result := UTF8ToString(S)
  else
    Result := string(S);
end;

constructor TFIBFieldInfo.Create;
begin
  inherited Create;
  FOtherInfo := TStringList.Create;
  FCanBeBoolean := eUnknown;
  FCanBeGUID := eUnknown;
end;

destructor TFIBFieldInfo.Destroy;
begin
  FOtherInfo.Free;
  inherited Destroy;
end;

function TFIBFieldInfo.GetCanBeBoolean: Boolean;
begin
  case FCanBeBoolean of
    eTrue: Result := True;
    eFalse: Result := False;
  else
    Result := PosCI('BOOLEAN', DomainName) > 0;
    FCanBeBoolean := TFIBExtendedBoolean(Result);
  end;
end;

function TFIBFieldInfo.GetCanBeGUID: Boolean;
begin
  case FCanBeGUID of
    eTrue: Result := True;
    eFalse: Result := False;
  else
    Result := PosCI('GUID', DomainName) > 0;
    FCanBeGUID := TFIBExtendedBoolean(Result);
  end;
end;

function TFIBFieldInfo.GetCharSet: string;
begin
  Result := FirebirdCharSetName(FCharSet);
  if Result = '' then
    Result := UnknownStr;
end;

procedure TFIBFieldInfo.SaveToStream(Stream: TStream);
begin
  with Stream do
  begin
    WriteBuffer(FIsComputed, SizeOf(Boolean));
    WriteBuffer(FCanIncToWhereClause, SizeOf(Boolean));
    WriteBuffer(FDefaultValueEmptyString, SizeOf(Boolean));
    WriteBuffer(FWithAdditionalInfo, SizeOf(Boolean));
    WriteBuffer(FVisible, SizeOf(Boolean));
    WriteBuffer(FIsTriggered, SizeOf(Boolean));
    WriteBuffer(FDisplayWidth, SizeOf(Integer));
    WriteBuffer(FCharSet, SizeOf(Integer));
    WriteUTF8StrToStream(FDefaultValue, Stream);
    WriteUTF8StrToStream(FDomainName, Stream);
    WriteUTF8StrToStream(FDisplayLabel, Stream);
    WriteUTF8StrToStream(FEditFormat, Stream);
    WriteUTF8StrToStream(FDisplayFormat, Stream);
    WriteUTF8StrToStream(FOtherInfo.Text, Stream);
  end;
end;

procedure TFIBFieldInfo.LoadFromStream(Stream: TStream; FromBegin: Boolean; UTF8: Boolean = True);
  procedure RaizeErrStream;
  begin
    raise Exception.Create(SCompEditFieldInfoLoadError);
  end;

begin
  with Stream do
  begin
    if FromBegin then
      Seek(0, soFromBeginning);
    ReadBuffer(FIsComputed, SizeOf(Boolean));
    ReadBuffer(FCanIncToWhereClause, SizeOf(Boolean));
    ReadBuffer(FDefaultValueEmptyString, SizeOf(Boolean));
    ReadBuffer(FWithAdditionalInfo, SizeOf(Boolean));
    ReadBuffer(FVisible, SizeOf(Boolean));
    ReadBuffer(FIsTriggered, SizeOf(Boolean));
    ReadBuffer(FDisplayWidth, SizeOf(Integer));
    ReadBuffer(FCharSet, SizeOf(Integer));

    FDefaultValue := ReadUTF8StrFromStream(Stream, UTF8);
    FDomainName := ReadUTF8StrFromStream(Stream, UTF8);
    FDisplayLabel := ReadUTF8StrFromStream(Stream, UTF8);
    FEditFormat := ReadUTF8StrFromStream(Stream, UTF8);
    FDisplayFormat := ReadUTF8StrFromStream(Stream, UTF8);
    FOtherInfo.Text := ReadUTF8StrFromStream(Stream, UTF8);
  end
end;


end.
