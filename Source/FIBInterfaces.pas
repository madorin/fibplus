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

unit FIBInterfaces;

interface

{$I FIB.inc}

uses
  Types, Classes, DB, StrUtil;

const
  // Command texts of TFIBClientDataSet, run by TFIBDataSet on the application server
  FIBCommitCommand = 'FIB$COMMIT';
  FIBRollbackCommand = 'FIB$ROLLBACK';
  FIBInTransactionCommand = 'FIB$GET_INTRANSACTION';
  FIBInTransactionParam = 'Active';

type

  IFIBParamSource = interface
    ['{DEA9627C-E35F-40A2-A2F6-3959782CE4AD}']
    function ParamCount: Integer;
    function ParamName(ParamIndex: Integer): string;
    function FieldsCount: Integer;
    function FieldExist(const FieldName: string; var FieldIndex: Integer): Boolean;
    function ParamExist(const ParamName: string; var ParamIndex: Integer): Boolean;
    function FieldValue(const FieldName: string; Old: Boolean): Variant; overload;
    function FieldValue(const FieldIndex: Integer; Old: Boolean): Variant; overload;
    function ParamValue(const ParamName: string): Variant; overload;
    function ParamValue(const ParamIndex: Integer): Variant; overload;
    procedure SetParamValue(const ParamIndex: Integer; aValue: Variant);
    function FieldName(FieldIndex: Integer): string;
    function IEof: Boolean;
    procedure INext;
  end;

type
  IFIBSQLStatisticsMaker = interface
    ['{39477B70-12C9-4F70-993E-0E1067A8D649}']
    // For Statistics
    function FixStartTime(const ObjName, VarName: string): Cardinal;
    function FixEndTime(const ObjName, VarName: string): Integer;
    function GetVarInt(const ObjName, VarName: string): Integer;
    function GetVarStr(const ObjName, VarName: string): string;
    function IncCounter(const ObjName, VarName: string): Integer;
    procedure SetStringValue(const ObjName, VarName, Value: string);
    function AddIntValue(const ObjName, VarName: string; Value: Integer): Integer;
    procedure SetIntValue(const ObjName, VarName: string; Value: Integer);
    //
    function GetVarStrings(const ObjName, VarName: string): TStrings;
    procedure Clear;

    procedure SetActiveStatistics(const Value: Boolean);
    function GetActiveStatistics: Boolean;

    property ActiveStatistics: Boolean read GetActiveStatistics write SetActiveStatistics;
  end;

  TFIBLogFlag = (
    lfQPrepare,
    lfQExecute,
    lfQFetch,
    lfConnect,
    lfTransact,
    lfService,
    lfMisc
  );
  TFIBLogFlags = set of TFIBLogFlag;

  IFIBSQLLogger = interface
    ['{2CB9280F-2324-40CD-BFB4-42C0FD36107F}']
    procedure SetActiveLogging(const Value: Boolean);
    function GetActiveLogging: Boolean;
    function GetLogFlags: TFIBLogFlags;
    function GetInstance: TObject;
    procedure SetLogFlags(Value: TFIBLogFlags);
    procedure SetDatabase(aDatabase: TObject);
    procedure WriteData(const ObjectName, OperationName, EventText: string; DataType: TFIBLogFlag);
    property ActiveLogging: Boolean read GetActiveLogging write SetActiveLogging;
    property LogFlags: TFIBLogFlags read GetLogFlags write SetLogFlags;
  end;

  IFIBStringer = interface
    ['{6756F6D0-3E0B-4035-81A6-6D2B579312D3}']
    // StrUtil
    function FormatIdentifier(Dialect: Integer; const Value: string): string;
    function PosCh(aCh: Char; const s: string): Integer;
    function PosCh1(aCh: Char; const s: string; StartPos: Integer): Integer;
    function PosCI(const Substr, Str: string): Integer;
    function EmptyStrings(SL: TStrings): Boolean;
    function EqualStrings(const s, s1: string; CaseSensitive: Boolean): Boolean;
    procedure DeleteEmptyStr(Src: TStrings); //
    function PosInRight(const Substr, Str: string; BeginPos: Integer): Integer;
    function LastChar(const Str: string): Char;
    function ExtractWord(Num: Integer; const Str: string; const WordDelims: TFIBAnsiCharSet): string;
    function WordCount(const s: string; const WordDelims: TFIBAnsiCharSet): Integer;
    // SqlTxtRtns
    function TableByAlias(const SQLText, Alias: string): string;
    procedure DispositionFromClause(const SQLText: string; var X, Y: Integer);
    procedure AllTables(const SQLText: string; aTables: TStrings; WithSP: Boolean = False; WithAliases: Boolean = False);
    function AliasForTable(const SQLText, TableName: string): string;
    function SetOrderClause(const SQLText, Order: string): string;
    function AddToMainWhereClause(const SQLText, Condition: string): string;
  end;

  IFIBMetaDataExtractor = interface
    ['{0F691E74-EAA3-431E-B33F-01CA62275E33}']
    function DBPrimaryKeys(const TableName: string; Transaction: TObject): string;
    function IsCalculatedField(const TableName, FieldName: string; Transaction: TObject): Boolean;
    function ObjectDDLTxt(Transaction: TObject; ObjectType: Integer; const ObjectName: string; ForceLoad: Boolean = True): string;
    function ObjectListFields(const ObjectName: string; var DDL: string;
      ForceLoad: Boolean = True; IncludeOBJName: Boolean = False): string;
    function GetTablesCount: Integer;
    function GetProceduresCount: Integer;
    function GetViewsCount: Integer;
    function GetUDFSCount: Integer;

    function GetExceptionsCount: Integer;
    function GetGeneratorsCount: Integer;
    function GetDomainsCount: Integer;
    ///
    function GetTableName(Index: Integer): string;
    function GetViewName(Index: Integer): string;
    function GetProcedureName(Index: Integer): string;
    function GetUDFName(Index: Integer): string;
    function GetGeneratorName(Index: Integer): string;

    ///
    procedure SetDatabase(Database: TObject);
    procedure LoadObjectNames;
    function GetNamesLoaded: Boolean;

    property TablesCount: Integer read GetTablesCount;
    property TableName[Index: Integer]: string read GetTableName;

    property ViewsCount: Integer read GetViewsCount;
    property ViewName[Index: Integer]: string read GetViewName;

    property ProceduresCount: Integer read GetProceduresCount;
    property ProcedureName[Index: Integer]: string read GetProcedureName;

    property UDFSCount: Integer read GetUDFSCount;
    property UDFName[Index: Integer]: string read GetUDFName;

    property GeneratorsCount: Integer read GetGeneratorsCount;
    property GeneratorsName[Index: Integer]: string read GetGeneratorName;

    property ExceptionsCount: Integer read GetExceptionsCount;
    property DomainsCount: Integer read GetDomainsCount;

    property NamesLoaded: Boolean read GetNamesLoaded;
  end;

  IFIBObject = interface
  end;

  IFIBConnect = interface(IFIBObject)
    ['{95317D9C-18B2-41B0-8C5B-8941561574B2}']
    function GetDatabaseName: string;
    procedure SetDatabaseName(const Value: string);
    procedure SaveAlias;
    function QueryValueAsStr(const aSQL: string; FieldNo: Integer; ParamValues: array of Variant): string;
    function Execute(const SQL: string): Boolean;
    procedure Commit;
    function IsFirebirdConnect: Boolean;
    property DBName: string read GetDatabaseName write SetDatabaseName;
  end;

  IFIBTransaction = interface(IFIBObject)
    ['{CD6DEB7B-7A2A-43DB-B3F2-8D6206E49BEE}']
    procedure StartTransaction;
    procedure Commit;
    procedure CommitRetaining;
    procedure Rollback;
    procedure RollbackRetaining;
  end;

  IFIBSQLObject = interface(IFIBObject)
    ['{D9361B56-E2FC-4F01-B477-CC655C86C63B}']
    procedure Prepare;
    function ParamCount: Integer;
    function ParamName(ParamIndex: Integer): string;
    function ParamExist(const ParamName: string; var ParamIndex: Integer): Boolean;
    function ParamValue(const ParamName: string): Variant; overload;
    function ParamValue(const ParamIndex: Integer): Variant; overload;
    function DefMacroValue(const MacroName: string): string;
    procedure SetParamValue(const ParamIndex: Integer; aValue: Variant); overload;
    procedure SetParamValues(const ParamValues: array of Variant); overload;
    procedure SetParamValues(const ParamNames: string; ParamValues: array of Variant); overload;

    function FieldsCount: Integer;
    function FieldExist(const FieldName: string; var FieldIndex: Integer): Boolean;

    function FieldValue(const FieldName: string; Old: Boolean): Variant; overload;
    function FieldValue(const FieldIndex: Integer; Old: Boolean): Variant; overload;
    function FieldName(FieldIndex: Integer): string;
    function IEof: Boolean;
    procedure INext;
    function TableAliasForField(const aFieldName: string): string;
  end;

  IFIBDataSet = interface(IFIBSQLObject)
    ['{F13CC688-BAE0-48A0-8FDF-8FA97D3F6577}']
    function GetRelationTableName(Field: TObject): string;
    function GetRelationFieldName(Field: TObject): string;
    procedure ParseParamToFieldsLinks(Dest: TStrings);
    function GetFieldOrigin(Fld: TField): string;
    procedure LoadRepositoryInfo;
  end;

  IFIBQuery = interface(IFIBSQLObject)
    ['{CA17BA7E-D4BC-4D8C-9D42-E818C6B32324}']
    procedure CheckValidStatement; // raise error if statement is invalid.
    procedure AddCondition(const Name, Condition: string; Enabled: Boolean);
    function GetPlan: string;
    procedure ExecQuery;
    procedure Close;
    property Plan: string read GetPlan;
  end;

  TFIBScriptStatementExecEvent = procedure(Line: Integer; StatementNo: Integer) of object;

  TFIBInterfaceSQLSection = (
    stUnknown,
    stSelect,
    stFields,
    stUpdate,
    stInsert,
    stDelete,
    stExecute,
    stSet,
    stComment,
    stFrom,
    stWhere,
    stGroupBy,
    stHaving,
    stUnion,
    stPlan,
    stOrderBy,
    stForUpdate
  );

  TFIBInterfaceSQLSections = array of TFIBInterfaceSQLSection;

  IFIBScripter = interface
    ['{246837E8-1E9D-4FB9-94FE-03DBA2B555E3}']
    procedure SetOnStatExec(CallBack: TFIBScriptStatementExecEvent);
    procedure Parse(Terminator: string = ';');
    procedure ExecuteScript(FromStmt: Integer = 1);
    procedure ExecuteFromFile(const FileName: string; Terminator: string = ';');
    function StatementsCount: Integer;
  end;

  IFIBSQLParser = interface
    ['{B9A9DA9B-C258-4653-BE89-CE0C25930A88}']
    procedure SetSQLText(const Value: string);
    function iPosInSections(Position: Integer): TFIBInterfaceSQLSections;
    function GetWord(Position: Integer; var StartWord: Integer; PartOnly: Boolean = False): string;
    function GetPrevWord(CurPosition: Integer; var PosPrevWord: Integer): string;
    function GetAllTables(WithSP: Boolean = False): TStrings;
    function CutAlias(const SQLString: string; AliasPosition: Integer = 0): string;
    function CutTableName(const SQLString: string; AliasPosition: Integer = 0): string;
    function AliasForTable(const SQLText, TableName: string): string;
    function TableByAlias(const SQLText, Alias: string): string;
  end;

  IFIBClassesExporter = interface
    ['{AFC7CF1A-EAA5-4584-B47D-BDAD337B4EEC}']
    function iGetStringer: IFIBStringer;
    function iGetMetaExtractor: IFIBMetaDataExtractor;
    function iGetSQLParser: IFIBSQLParser;
  end;

var
  FIBClassesExporter: IFIBClassesExporter = nil;
  expDatabaseClass: TComponentClass;
  expDatasetClass: TComponentClass;
  expTransactionClass: TComponentClass;
  expQueryClass: TComponentClass;
  expServicesClass: TComponentClass;
  expDeltaReceiverClass: TComponentClass;
  expScripter: TComponentClass;

type
  // Deprecated names of the types renamed in 8.0.0
  ISQLObject = IFIBParamSource deprecated 'Use IFIBParamSource';
  ISQLStatMaker = IFIBSQLStatisticsMaker deprecated 'Use IFIBSQLStatisticsMaker';
  ISQLLogger = IFIBSQLLogger deprecated 'Use IFIBSQLLogger';
  ISQLParser = IFIBSQLParser deprecated 'Use IFIBSQLParser';
  TLogFlag = TFIBLogFlag deprecated 'Use TFIBLogFlag';
  TLogFlags = TFIBLogFlags deprecated 'Use TFIBLogFlags';
  TOnScriptStatementExec = TFIBScriptStatementExecEvent deprecated 'Use TFIBScriptStatementExecEvent';
  TiSQLSection = TFIBInterfaceSQLSection deprecated 'Use TFIBInterfaceSQLSection';
  TiSQLSections = TFIBInterfaceSQLSections deprecated 'Use TFIBInterfaceSQLSections';

implementation

uses
  FIBDataSet, FIBQuery, FIBDatabase, FIBServices, FIBDataRefresh,
  FIBScripter;

initialization

expDatabaseClass := TFIBDatabase;
expTransactionClass := TFIBTransaction;
expDatasetClass := TFIBDataSet;
expQueryClass := TFIBQuery;
expServicesClass := TFIBCustomService;
expDeltaReceiverClass := TFIBTableChangesReader;
expScripter := TFIBScripter

end.
