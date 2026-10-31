unit pFIBScripter deprecated 'Use FIBScripter (TFIBScripter)';

interface

uses
  FIBScripter;

type
  TpFIBScripter = TFIBScripter deprecated 'Use TFIBScripter';
  TpFIBScriptParser = TFIBScriptParser deprecated 'Use TFIBScriptParser';
  TStmtType = FIBScripter.TFIBStatementType;
  TObjectType = FIBScripter.TFIBScriptObjectType;
  TStmtCoord = FIBScripter.TFIBStatementCoord;
  PStmtCoord = FIBScripter.PFIBStatementCoord;
  TStatementDesc = FIBScripter.TFIBStatementDesc;
  PStatementDesc = FIBScripter.PFIBStatementDesc;
  TScriptMap = FIBScripter.TFIBScriptMap;
  TOnParseStmt = FIBScripter.TFIBParseStatementEvent;
  TDirectiveState = FIBScripter.TFIBDirectiveState;
  TDirectiveDesc = FIBScripter.TFIBDirectiveDesc;
  PDirectiveDesc = FIBScripter.PFIBDirectiveDesc;
  TDirectivesMap = FIBScripter.TFIBDirectivesMap;
  PDirectivesMap = FIBScripter.PFIBDirectivesMap;
  TParseDisposition = FIBScripter.TFIBParseDisposition;
  TParserState = FIBScripter.TFIBScriptParserState;
  TScriptKeyword = FIBScripter.TFIBScriptKeyword;
  TOnStatementExecute = FIBScripter.TFIBStatementExecuteEvent;
  TOnSQLScriptExecError = FIBScripter.TFIBScriptExecErrorEvent;
  TDynStringArray = FIBScripter.TFIBAnsiStringArray;

const
  sUnknown = FIBScripter.sUnknown;
  sInvalid = FIBScripter.sInvalid;
  sDML = FIBScripter.sDML;
  sConnect = FIBScripter.sConnect;
  sDisconnect = FIBScripter.sDisconnect;
  sReconnect = FIBScripter.sReconnect;
  sCreateDatabase = FIBScripter.sCreateDatabase;
  sDropDatabase = FIBScripter.sDropDatabase;
  sCommit = FIBScripter.sCommit;
  sRollBack = FIBScripter.sRollBack;
  sCreate = FIBScripter.sCreate;
  sAlter = FIBScripter.sAlter;
  sRecreate = FIBScripter.sRecreate;
  sDrop = FIBScripter.sDrop;
  sSet = FIBScripter.sSet;
  sSetGenerator = FIBScripter.sSetGenerator;
  sSetStatistics = FIBScripter.sSetStatistics;
  sDescribe = FIBScripter.sDescribe;
  sDeclare = FIBScripter.sDeclare;
  sComment = FIBScripter.sComment;
  sGrant = FIBScripter.sGrant;
  sRunFromFile = FIBScripter.sRunFromFile;
  sBatch = FIBScripter.sBatch;
  sBatchStart = FIBScripter.sBatchStart;
  sBatchExecute = FIBScripter.sBatchExecute;
  sExecute = FIBScripter.sExecute;
  sInsert = FIBScripter.sInsert;
  sReinsert = FIBScripter.sReinsert;
  sDirective = FIBScripter.sDirective;
  sSetSession = FIBScripter.sSetSession;
  otNone = FIBScripter.otNone;
  otDatabase = FIBScripter.otDatabase;
  otDomain = FIBScripter.otDomain;
  otTable = FIBScripter.otTable;
  otView = FIBScripter.otView;
  otProcedure = FIBScripter.otProcedure;
  otTrigger = FIBScripter.otTrigger;
  otUDF = FIBScripter.otUDF;
  otException = FIBScripter.otException;
  otGenerator = FIBScripter.otGenerator;
  otIndex = FIBScripter.otIndex;
  otConstraint = FIBScripter.otConstraint;
  otFilter = FIBScripter.otFilter;
  otField = FIBScripter.otField;
  otParameter = FIBScripter.otParameter;
  otRole = FIBScripter.otRole;
  otBlock = FIBScripter.otBlock;
  otUser = FIBScripter.otUser;
  otPackage = FIBScripter.otPackage;
  otPackageBody = FIBScripter.otPackageBody;
  otFunction = FIBScripter.otFunction;
  dsUnknown = FIBScripter.dsUnknown;
  dsTrue = FIBScripter.dsTrue;
  dsFalse = FIBScripter.dsFalse;
  pdBetweenStatements = FIBScripter.pdBetweenStatements;
  pdInStatement = FIBScripter.pdInStatement;
  pdInDirective = FIBScripter.pdInDirective;
  psNormal = FIBScripter.psNormal;
  psInComment = FIBScripter.psInComment;
  psInQuote = FIBScripter.psInQuote;
  psInDoubleQuote = FIBScripter.psInDoubleQuote;
  psInQString = FIBScripter.psInQString;
  psInConditional = FIBScripter.psInConditional;
  kwOther = FIBScripter.kwOther;
  kwAlter = FIBScripter.kwAlter;
  kwAs = FIBScripter.kwAs;
  kwBegin = FIBScripter.kwBegin;
  kwBlock = FIBScripter.kwBlock;
  kwCase = FIBScripter.kwCase;
  kwCreate = FIBScripter.kwCreate;
  kwEnd = FIBScripter.kwEnd;
  kwExecute = FIBScripter.kwExecute;
  kwExternal = FIBScripter.kwExternal;
  kwFunction = FIBScripter.kwFunction;
  kwOr = FIBScripter.kwOr;
  kwPackage = FIBScripter.kwPackage;
  kwProcedure = FIBScripter.kwProcedure;
  kwRecreate = FIBScripter.kwRecreate;
  kwSet = FIBScripter.kwSet;
  kwTerm = FIBScripter.kwTerm;
  kwTrigger = FIBScripter.kwTrigger;
  dIfDef = FIBScripter.dIfDef;
  dIfNDef = FIBScripter.dIfNDef;
  dIf = FIBScripter.dIf;
  dIfExists = FIBScripter.dIfExists;
  dIfNExists = FIBScripter.dIfNExists;
  dIfNotExists = FIBScripter.dIfNotExists;
  dElse = FIBScripter.dElse;
  dEndIf = FIBScripter.dEndIf;
  dExecBlock = FIBScripter.dExecBlock;
  dDefine = FIBScripter.dDefine;
  dUnDefine = FIBScripter.dUnDefine;
  dSetVar = FIBScripter.dSetVar;
  srvIsFirebird = FIBScripter.srvIsFirebird;
  srvMajorVer = FIBScripter.srvMajorVer;
  srvMinorVer = FIBScripter.srvMinorVer;
  dbODSMajorVersion = FIBScripter.dbODSMajorVersion;
  dbODSMinorVersion = FIBScripter.dbODSMinorVersion;

function StatementTypeName(tn: TStmtType): string; deprecated 'Use FIBScripter.StatementTypeName';

implementation

uses
  Classes;

function StatementTypeName(tn: TStmtType): string;
begin
  Result := FIBScripter.StatementTypeName(tn);
end;

initialization
  RegisterClassAlias(TFIBScripter, 'TpFIBScripter');

end.
