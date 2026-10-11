unit pFIBMetaData deprecated 'Use FIBMetaData (TFIBDBSchemaExtract)';

interface

uses
  Classes, FIBDatabase, FIBMetaData;

type
  TpFIBDBSchemaExtract = FIBMetaData.TFIBDBSchemaExtract deprecated 'Use TFIBDBSchemaExtract';
  TDBObjectType = FIBMetaData.TDBObjectType;
  TDBObjectTypes = FIBMetaData.TDBObjectTypes;
  TTableChildType = FIBMetaData.TTableChildType;
  TTableChildTypes = FIBMetaData.TTableChildTypes;
  TViewChildType = FIBMetaData.TViewChildType;
  TViewChildTypes = FIBMetaData.TViewChildTypes;
  TProcedureChild = FIBMetaData.TProcedureChild;
  TProcedureChilds = FIBMetaData.TProcedureChilds;
  TUDFChild = FIBMetaData.TUDFChild;
  TUDFChilds = FIBMetaData.TUDFChilds;
  TRoleChild = FIBMetaData.TRoleChild;
  TTriggerType = FIBMetaData.TTriggerType;
  TTriggerAction = FIBMetaData.TTriggerAction;
  TTriggerActions = FIBMetaData.TTriggerActions;
  TIndexOrder = FIBMetaData.TIndexOrder;
  TForeignKeyRule = FIBMetaData.TForeignKeyRule;
  TFIBFieldType = FIBMetaData.TFIBFieldType;
  TPrivilege = FIBMetaData.TPrivilege;
  TPrivileges = FIBMetaData.TPrivileges;
  TNotifyLoadMetaData = FIBMetaData.TNotifyLoadMetaData;
  TDDLTextOption = FIBMetaData.TDDLTextOption;
  TDDLTextOptions = FIBMetaData.TDDLTextOptions;
  TCustomMetaObject = FIBMetaData.TCustomMetaObject;
  TMetaObjectClass = FIBMetaData.TMetaObjectClass;
  TMetaDomain = FIBMetaData.TMetaDomain;
  TMetaTable = FIBMetaData.TMetaTable;
  TMetaDataItem = FIBMetaData.TMetaDataItem;
  TCustomMetaGrant = FIBMetaData.TCustomMetaGrant;
  TMetaViewGrant = FIBMetaData.TMetaViewGrant;
  TMetaTableGrant = FIBMetaData.TMetaTableGrant;
  TMetaProcGrant = FIBMetaData.TMetaProcGrant;
  TMetaRoleGrant = FIBMetaData.TMetaRoleGrant;
  TMetaGenerator = FIBMetaData.TMetaGenerator;
  TArrBounds = FIBMetaData.TArrBounds;
  TMetaField = FIBMetaData.TMetaField;
  TMetaProcField = FIBMetaData.TMetaProcField;
  TMetaProcInField = FIBMetaData.TMetaProcInField;
  TMetaProcOutField = FIBMetaData.TMetaProcOutField;
  TMetaTableField = FIBMetaData.TMetaTableField;
  TMetaConstraint = FIBMetaData.TMetaConstraint;
  TMetaPrimaryKey = FIBMetaData.TMetaPrimaryKey;
  TMetaUniqueConstraint = FIBMetaData.TMetaUniqueConstraint;
  TMetaForeignKey = FIBMetaData.TMetaForeignKey;
  TMetaCheckConstraint = FIBMetaData.TMetaCheckConstraint;
  TMetaIndex = FIBMetaData.TMetaIndex;
  TCustomMetaTrigger = FIBMetaData.TCustomMetaTrigger;
  TMetaTableTrigger = FIBMetaData.TMetaTableTrigger;
  TMetaViewTrigger = FIBMetaData.TMetaViewTrigger;
  TMetaDBTrigger = FIBMetaData.TMetaDBTrigger;
  TMetaView = FIBMetaData.TMetaView;
  TMetaProcedure = FIBMetaData.TMetaProcedure;
  TMetaStoredFunc = FIBMetaData.TMetaStoredFunc;
  TMetaPackage = FIBMetaData.TMetaPackage;
  TMetaException = FIBMetaData.TMetaException;
  TMetaUDFField = FIBMetaData.TMetaUDFField;
  TMetaUDF = FIBMetaData.TMetaUDF;
  TMetaRole = FIBMetaData.TMetaRole;
  TMetaDataBase = FIBMetaData.TMetaDataBase;
  TFIBDBSchemaExtract = FIBMetaData.TFIBDBSchemaExtract;
  TLoadOptions = FIBMetaData.TLoadOptions;

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
  DefTableChilds = FIBMetaData.DefTableChilds;
  DefViewChilds = FIBMetaData.DefViewChilds;

procedure FullExtractDDL(DB: TFIBDatabase; Dest: TStrings); deprecated 'Use FIBMetaData.FullExtractDDL';

implementation

procedure FullExtractDDL(DB: TFIBDatabase; Dest: TStrings);
begin
  FIBMetaData.FullExtractDDL(DB, Dest);
end;

initialization
  RegisterClassAlias(TFIBDBSchemaExtract, 'TpFIBDBSchemaExtract');

end.
