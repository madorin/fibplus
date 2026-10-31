unit pFIBMetaData deprecated 'Use FIBMetaData (TFIBDBSchemaExtract)';

interface

uses
  Classes, FIBDatabase, FIBMetaData;

type
  TpFIBDBSchemaExtract = FIBMetaData.TFIBDBSchemaExtract deprecated 'Use TFIBDBSchemaExtract';
  TDBObjectType = FIBMetaData.TFIBDBObjectType;
  TDBObjectTypes = FIBMetaData.TFIBDBObjectTypes;
  TTableChildType = FIBMetaData.TFIBTableChildType;
  TTableChildTypes = FIBMetaData.TFIBTableChildTypes;
  TViewChildType = FIBMetaData.TFIBViewChildType;
  TViewChildTypes = FIBMetaData.TFIBViewChildTypes;
  TProcedureChild = FIBMetaData.TFIBProcedureChild;
  TProcedureChilds = FIBMetaData.TFIBProcedureChildren;
  TUDFChild = FIBMetaData.TFIBUDFChild;
  TUDFChilds = FIBMetaData.TFIBUDFChildren;
  TRoleChild = FIBMetaData.TFIBRoleChild;
  TTriggerType = FIBMetaData.TFIBTriggerType;
  TTriggerAction = FIBMetaData.TFIBTriggerAction;
  TTriggerActions = FIBMetaData.TFIBTriggerActions;
  TIndexOrder = FIBMetaData.TFIBIndexOrder;
  TForeignKeyRule = FIBMetaData.TFIBForeignKeyRule;
  TFIBFieldType = FIBMetaData.TFIBFieldType;
  TPrivilege = FIBMetaData.TFIBPrivilege;
  TPrivileges = FIBMetaData.TFIBPrivileges;
  TNotifyLoadMetaData = FIBMetaData.TFIBLoadMetaDataEvent;
  TDDLTextOption = FIBMetaData.TFIBDDLTextOption;
  TDDLTextOptions = FIBMetaData.TFIBDDLTextOptions;
  TCustomMetaObject = FIBMetaData.TFIBCustomMetaObject;
  TMetaObjectClass = FIBMetaData.TFIBMetaObjectClass;
  TMetaDomain = FIBMetaData.TFIBMetaDomain;
  TMetaTable = FIBMetaData.TFIBMetaTable;
  TMetaDataItem = FIBMetaData.TFIBMetaDataItem;
  TCustomMetaGrant = FIBMetaData.TFIBCustomMetaGrant;
  TMetaViewGrant = FIBMetaData.TFIBMetaViewGrant;
  TMetaTableGrant = FIBMetaData.TFIBMetaTableGrant;
  TMetaProcGrant = FIBMetaData.TFIBMetaProcedureGrant;
  TMetaRoleGrant = FIBMetaData.TFIBMetaRoleGrant;
  TMetaGenerator = FIBMetaData.TFIBMetaGenerator;
  TArrBounds = FIBMetaData.TFIBMetaArrayBounds;
  TFieldDimensions = FIBMetaData.TFIBFieldDimensions;
  TCustomMetaField = FIBMetaData.TFIBCustomMetaField;
  TMetaField = FIBMetaData.TFIBMetaField;
  TMetaProcField = FIBMetaData.TFIBMetaProcedureField;
  TMetaProcInField = FIBMetaData.TFIBMetaProcedureInField;
  TMetaProcOutField = FIBMetaData.TFIBMetaProcedureOutField;
  TMetaTableField = FIBMetaData.TFIBMetaTableField;
  TMetaConstraint = FIBMetaData.TFIBMetaConstraint;
  TMetaPrimaryKey = FIBMetaData.TFIBMetaPrimaryKey;
  TMetaUniqueConstraint = FIBMetaData.TFIBMetaUniqueConstraint;
  TMetaForeignKey = FIBMetaData.TFIBMetaForeignKey;
  TMetaCheckConstraint = FIBMetaData.TFIBMetaCheckConstraint;
  TMetaIndex = FIBMetaData.TFIBMetaIndex;
  TCustomMetaTrigger = FIBMetaData.TFIBCustomMetaTrigger;
  TMetaTableTrigger = FIBMetaData.TFIBMetaTableTrigger;
  TMetaViewTrigger = FIBMetaData.TFIBMetaViewTrigger;
  TMetaDBTrigger = FIBMetaData.TFIBMetaDBTrigger;
  TMetaView = FIBMetaData.TFIBMetaView;
  TMetaProcedure = FIBMetaData.TFIBMetaProcedure;
  TMetaStoredFunc = FIBMetaData.TFIBMetaStoredFunction;
  TMetaPackage = FIBMetaData.TFIBMetaPackage;
  TMetaException = FIBMetaData.TFIBMetaException;
  TMetaUDFField = FIBMetaData.TFIBMetaUDFField;
  TMetaUDF = FIBMetaData.TFIBMetaUDF;
  TMetaRole = FIBMetaData.TFIBMetaRole;
  TMetaDataBase = FIBMetaData.TFIBMetaDatabase;
  TFIBDBSchemaExtract = FIBMetaData.TFIBDBSchemaExtract;
  TLoadOptions = FIBMetaData.TFIBMetaLoadOptions;

const
  DefTerminator = FIBMetaData.DefTerminator;
  ProcTerminator = FIBMetaData.ProcTerminator;
  otDomain = FIBMetaData.otDomain;
  otTable = FIBMetaData.otTable;
  otView = FIBMetaData.otView;
  otProcedure = FIBMetaData.otProcedure;
  otGenerator = FIBMetaData.otGenerator;
  otException = FIBMetaData.otException;
  otUDF = FIBMetaData.otUDF;
  otRole = FIBMetaData.otRole;
  otDBTrigger = FIBMetaData.otDBTrigger;
  otStoredFunctions = FIBMetaData.otStoredFunctions;
  otPackage = FIBMetaData.otPackage;
  otDatabase = FIBMetaData.otDatabase;
  soTableFields = FIBMetaData.soTableFields;
  soPrimaryKey = FIBMetaData.soPrimaryKey;
  soForeignKey = FIBMetaData.soForeignKey;
  soTableTriggers = FIBMetaData.soTableTriggers;
  soUniqueConstr = FIBMetaData.soUniqueConstr;
  soIndex = FIBMetaData.soIndex;
  soCheckConstr = FIBMetaData.soCheckConstr;
  soTableGrants = FIBMetaData.soTableGrants;
  soViewFields = FIBMetaData.soViewFields;
  soViewTriggers = FIBMetaData.soViewTriggers;
  soViewGrants = FIBMetaData.soViewGrants;
  soProcFieldIn = FIBMetaData.soProcFieldIn;
  soProcFieldOut = FIBMetaData.soProcFieldOut;
  soProcGrants = FIBMetaData.soProcGrants;
  soUDFField = FIBMetaData.soUDFField;
  soRoleGrants = FIBMetaData.soRoleGrants;
  ttBefore = FIBMetaData.ttBefore;
  ttAfter = FIBMetaData.ttAfter;
  ttON = FIBMetaData.ttON;
  taInsert = FIBMetaData.taInsert;
  taUpdate = FIBMetaData.taUpdate;
  taDelete = FIBMetaData.taDelete;
  taConnect = FIBMetaData.taConnect;
  taDisconnect = FIBMetaData.taDisconnect;
  taTransactionStart = FIBMetaData.taTransactionStart;
  taTransactionCommit = FIBMetaData.taTransactionCommit;
  taTransactionRollback = FIBMetaData.taTransactionRollback;
  IoDescending = FIBMetaData.IoDescending;
  IoAscending = FIBMetaData.IoAscending;
  fkrRestrict = FIBMetaData.fkrRestrict;
  fkrCascade = FIBMetaData.fkrCascade;
  fkrSetNull = FIBMetaData.fkrSetNull;
  fkrSetDefault = FIBMetaData.fkrSetDefault;
  fftUnKnown = FIBMetaData.fftUnKnown;
  fftNumeric = FIBMetaData.fftNumeric;
  fftChar = FIBMetaData.fftChar;
  fftVarchar = FIBMetaData.fftVarchar;
  fftCstring = FIBMetaData.fftCstring;
  fftSmallint = FIBMetaData.fftSmallint;
  fftInteger = FIBMetaData.fftInteger;
  fftQuad = FIBMetaData.fftQuad;
  fftFloat = FIBMetaData.fftFloat;
  fftDoublePrecision = FIBMetaData.fftDoublePrecision;
  fftTimestamp = FIBMetaData.fftTimestamp;
  fftBlob = FIBMetaData.fftBlob;
  fftBlobId = FIBMetaData.fftBlobId;
  fftDate = FIBMetaData.fftDate;
  fftTime = FIBMetaData.fftTime;
  fftInt64 = FIBMetaData.fftInt64;
  fftBoolean = FIBMetaData.fftBoolean;
  fftInt128 = FIBMetaData.fftInt128;
  fftDecFloat = FIBMetaData.fftDecFloat;
  fftTimeTZ = FIBMetaData.fftTimeTZ;
  fftTimestampTZ = FIBMetaData.fftTimestampTZ;
  goSelect = FIBMetaData.goSelect;
  goInsert = FIBMetaData.goInsert;
  goUpdate = FIBMetaData.goUpdate;
  goDelete = FIBMetaData.goDelete;
  goReferences = FIBMetaData.goReferences;
  goExecuteProc = FIBMetaData.goExecuteProc;
  goRole = FIBMetaData.goRole;
  dtoUseCreateDB = FIBMetaData.dtoUseCreateDB;
  dtoUseSetClientLib = FIBMetaData.dtoUseSetClientLib;
  dtoUseSetTerm = FIBMetaData.dtoUseSetTerm;
  dtoDecodeDomains = FIBMetaData.dtoDecodeDomains;
  dtoIncludeGrants = FIBMetaData.dtoIncludeGrants;
  DefObjects = FIBMetaData.DefObjects;
  DefTableChilds = FIBMetaData.DefTableChildTypes;
  DefViewChilds = FIBMetaData.DefViewChildTypes;

procedure FullExtractDDL(DB: TFIBDatabase; Dest: TStrings); deprecated 'Use FIBMetaData.FullExtractDDL';

implementation

procedure FullExtractDDL(DB: TFIBDatabase; Dest: TStrings);
begin
  FIBMetaData.FullExtractDDL(DB, Dest);
end;

initialization
  RegisterClassAlias(TFIBDBSchemaExtract, 'TpFIBDBSchemaExtract');

end.
