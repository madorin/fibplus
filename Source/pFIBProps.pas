unit pFIBProps deprecated 'Use FIBProps';

interface

{$I FIB.inc}

uses
  Classes, FIBProps;

type
  TpFIBExistObject = FIBProps.TFIBExistObject deprecated 'Use TFIBExistObject';
  TpPrepareOption = FIBProps.TFIBPrepareOption deprecated 'Use TFIBPrepareOption';
  TpPrepareOptions = FIBProps.TFIBPrepareOptions deprecated 'Use TFIBPrepareOptions';
  TpFIBDsOption = FIBProps.TFIBDataSetOption deprecated 'Use TFIBDataSetOption';
  TpFIBDsOptions = FIBProps.TFIBDataSetOptions deprecated 'Use TFIBDataSetOptions';
  TpFIBQueryOption = FIBProps.TFIBQueryOption deprecated 'Use TFIBQueryOption';
  TpFIBQueryOptions = FIBProps.TFIBQueryOptions deprecated 'Use TFIBQueryOptions';
  TpFIBFieldInfo = FIBProps.TFIBFieldInfo deprecated 'Use TFIBFieldInfo';
  TOnBlobFieldProcessing = FIBProps.TOnBlobFieldProcessing;
  TKindOnOperation = FIBProps.TKindOnOperation;
  TFIBSQLTypes = FIBProps.TFIBSQLTypes;
  TFIBExistObject = FIBProps.TFIBExistObject;
  TFIBPrepareOption = FIBProps.TFIBPrepareOption;
  TFIBPrepareOptions = FIBProps.TFIBPrepareOptions;
  TFIBDataSetOption = FIBProps.TFIBDataSetOption;
  TFIBDataSetOptions = FIBProps.TFIBDataSetOptions;
  TFIBQueryOption = FIBProps.TFIBQueryOption;
  TFIBQueryOptions = FIBProps.TFIBQueryOptions;
  TDetailCondition = FIBProps.TDetailCondition;
  TDetailConditions = FIBProps.TDetailConditions;
  TFieldOriginRule = FIBProps.TFieldOriginRule;
  TSQLs = FIBProps.TSQLs;
  TFormatFields = FIBProps.TFormatFields;
  TWhenGetGenID = FIBProps.TWhenGetGenID;
  TReturningFields = FIBProps.TReturningFields;
  TSetReturningFields = FIBProps.TSetReturningFields;
  TAutoUpdateOptions = FIBProps.TAutoUpdateOptions;
{$IFDEF SUPPORT_IB2007}
  TIBConnectParams = FIBProps.TIBConnectParams;
{$ENDIF}
  TUseGeneratorCache = FIBProps.TUseGeneratorCache;
  TGeneratorParams = FIBProps.TGeneratorParams;
  TGeneratorsCache = FIBProps.TGeneratorsCache;
  TConnectParams = FIBProps.TConnectParams;
{$IFDEF CSMonitor}
  TCSMonitorEnabled = FIBProps.TCSMonitorEnabled;
  EFIBCSMonitorError = FIBProps.EFIBCSMonitorError;
  TCSMonitorSupport = FIBProps.TCSMonitorSupport;
{$ENDIF}
  TCacheSchemaOptions = FIBProps.TCacheSchemaOptions;
  TDBParams = FIBProps.TDBParams;
  TTransactionAction1 = FIBProps.TTransactionAction1;
  TTPBMode = FIBProps.TTPBMode;
  TBlobSwapSupport = FIBProps.TBlobSwapSupport;
  TConditions = FIBProps.TConditions;
  TCondition = FIBProps.TCondition;
  TConditionsStateFlag = FIBProps.TConditionsStateFlag;
  TConditionsState = FIBProps.TConditionsState;
  TMemoSubtypes = FIBProps.TMemoSubtypes;
  TExtBoolean = FIBProps.TExtBoolean;
  TFIBFieldInfo = FIBProps.TFIBFieldInfo;

const
  koBefore = FIBProps.koBefore;
  koAfter = FIBProps.koAfter;
  koAfterFirstFetch = FIBProps.koAfterFirstFetch;
  koOther = FIBProps.koOther;
  SQLUnknown = FIBProps.SQLUnknown;
  SQLSelect = FIBProps.SQLSelect;
  SQLInsert = FIBProps.SQLInsert;
  SQLUpdate = FIBProps.SQLUpdate;
  SQLDelete = FIBProps.SQLDelete;
  SQLDDL = FIBProps.SQLDDL;
  SQLGetSegment = FIBProps.SQLGetSegment;
  SQLPutSegment = FIBProps.SQLPutSegment;
  SQLExecProcedure = FIBProps.SQLExecProcedure;
  SQLStartTransaction = FIBProps.SQLStartTransaction;
  SQLCommit = FIBProps.SQLCommit;
  SQLRollback = FIBProps.SQLRollback;
  SQLSelectForUpdate = FIBProps.SQLSelectForUpdate;
  SQLSetGenerator = FIBProps.SQLSetGenerator;
  SQLSavePointOperation = FIBProps.SQLSavePointOperation;
  eoYes = FIBProps.eoYes;
  eoNo = FIBProps.eoNo;
  eoUnknown = FIBProps.eoUnknown;
  pfSetRequiredFields = FIBProps.pfSetRequiredFields;
  pfSetReadOnlyFields = FIBProps.pfSetReadOnlyFields;
  pfImportDefaultValues = FIBProps.pfImportDefaultValues;
  psUseBooleanField = FIBProps.psUseBooleanField;
  psUseGuidField = FIBProps.psUseGuidField;
  psSQLINT64ToBCD = FIBProps.psSQLINT64ToBCD;
  psApplyRepositary = FIBProps.psApplyRepositary;
  psGetOrderInfo = FIBProps.psGetOrderInfo;
  psAskRecordCount = FIBProps.psAskRecordCount;
  psCanEditComputedFields = FIBProps.psCanEditComputedFields;
  psSetEmptyStrToNull = FIBProps.psSetEmptyStrToNull;
  psSupportUnicodeBlobs = FIBProps.psSupportUnicodeBlobs;
  psUseLargeIntField = FIBProps.psUseLargeIntField;
  poTrimCharFields = FIBProps.poTrimCharFields;
  poRefreshAfterPost = FIBProps.poRefreshAfterPost;
  poRefreshDeletedRecord = FIBProps.poRefreshDeletedRecord;
  poStartTransaction = FIBProps.poStartTransaction;
  poAutoFormatFields = FIBProps.poAutoFormatFields;
  poProtectedEdit = FIBProps.poProtectedEdit;
  poUseSelectForLock = FIBProps.poUseSelectForLock;
  poKeepSorting = FIBProps.poKeepSorting;
{$IFDEF OBSOLETE_PROPS}
  poAllowChangeSqls = FIBProps.poAllowChangeSqls;
{$ENDIF}
  poPersistentSorting = FIBProps.poPersistentSorting;
  poVisibleRecno = FIBProps.poVisibleRecno;
  poNoForceIsNull = FIBProps.poNoForceIsNull;
  poFetchAll = FIBProps.poFetchAll;
  poFreeHandlesAfterClose = FIBProps.poFreeHandlesAfterClose;
  poCacheCalcFields = FIBProps.poCacheCalcFields;
  poRefreshAfterDelete = FIBProps.poRefreshAfterDelete;
  poDontCloseAfterEndTransaction = FIBProps.poDontCloseAfterEndTransaction;
  qoStartTransaction = FIBProps.qoStartTransaction;
  qoAutoCommit = FIBProps.qoAutoCommit;
  qoTrimCharFields = FIBProps.qoTrimCharFields;
  qoNoForceIsNull = FIBProps.qoNoForceIsNull;
  qoFreeHandleAfterExecute = FIBProps.qoFreeHandleAfterExecute;
  dcForceOpen = FIBProps.dcForceOpen;
  dcIgnoreMasterClose = FIBProps.dcIgnoreMasterClose;
  dcForceMasterRefresh = FIBProps.dcForceMasterRefresh;
  dcWaitEndMasterScroll = FIBProps.dcWaitEndMasterScroll;
  forNoRule = FIBProps.forNoRule;
  forTableAndFieldName = FIBProps.forTableAndFieldName;
  forClientFieldName = FIBProps.forClientFieldName;
  forTableAliasAndFieldName = FIBProps.forTableAliasAndFieldName;
  wgNever = FIBProps.wgNever;
  wgOnNewRecord = FIBProps.wgOnNewRecord;
  wgBeforePost = FIBProps.wgBeforePost;
  rfAll = FIBProps.rfAll;
  rfKeyFields = FIBProps.rfKeyFields;
  rfBlobFields = FIBProps.rfBlobFields;
  No = FIBProps.No;
  forAll = FIBProps.forAll;
  forGeneratorList = FIBProps.forGeneratorList;
{$IFDEF CSMonitor}
  csmeDisabled = FIBProps.csmeDisabled;
  csmeEnabled = FIBProps.csmeEnabled;
  csmeDatabaseDriven = FIBProps.csmeDatabaseDriven;
  csmeTransactionDriven = FIBProps.csmeTransactionDriven;
{$ENDIF}
  TARollback1 = FIBProps.TARollback1;
  TARollbackRetaining1 = FIBProps.TARollbackRetaining1;
  TACommit1 = FIBProps.TACommit1;
  TACommitRetaining1 = FIBProps.TACommitRetaining1;
  tpbDefault = FIBProps.tpbDefault;
  tpbReadCommitted = FIBProps.tpbReadCommitted;
  tpbRepeatableRead = FIBProps.tpbRepeatableRead;
  tpbReadConsistency = FIBProps.tpbReadConsistency;
  csInApply = FIBProps.csInApply;
  csInCancel = FIBProps.csInCancel;
  csInRestorePrimarySQL = FIBProps.csInRestorePrimarySQL;
  eFalse = FIBProps.eFalse;
  eTrue = FIBProps.eTrue;
  eUnknown = FIBProps.eUnknown;
  StatDefPrepareOptions = FIBProps.StatDefPrepareOptions;
  StatDefDataSetOptions = FIBProps.StatDefDataSetOptions;
  RegFIBRoot = FIBProps.RegFIBRoot;
  RegFIBTrKinds = FIBProps.RegFIBTrKinds;
  RegPreferences = FIBProps.RegPreferences;
  RegRepository = FIBProps.RegRepository;

procedure WriteStrToStream(const s: AnsiString; Stream: TStream); deprecated 'Use FIBProps.WriteStrToStream';
procedure ReadStrFromStream(const Stream: TStream; var ResStr: AnsiString); deprecated 'Use FIBProps.ReadStrFromStream';

implementation

procedure WriteStrToStream(const s: AnsiString; Stream: TStream);
begin
  FIBProps.WriteStrToStream(s, Stream);
end;

procedure ReadStrFromStream(const Stream: TStream; var ResStr: AnsiString);
begin
  FIBProps.ReadStrFromStream(Stream, ResStr);
end;

end.
