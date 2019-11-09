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


unit pFIBInterfaces;

interface

{$I FIBPlus.inc}

uses {$IFDEF D6+} Types, {$ELSE} Windows, {$ENDIF} Classes, DB, StrUtil;

type

  ISQLObject  = interface
   ['{DEA9627C-E35F-40A2-A2F6-3959782CE4AD}']
   function  ParamCount:integer;
   function  ParamName(ParamIndex:integer):string;
   function  FieldsCount:integer;
   function  FieldExist(const FieldName:string; var FieldIndex:integer):boolean;
   function  ParamExist(const ParamName:string; var ParamIndex:integer):boolean;
   function  FieldValue(const FieldName:string; Old:boolean):variant;   overload;
   function  FieldValue(const FieldIndex:integer;Old:boolean):variant; overload;
   function  ParamValue(const ParamName:string):variant;   overload;
   function  ParamValue(const ParamIndex:integer):variant; overload;
   procedure SetParamValue(const ParamIndex:integer; aValue:Variant);
   function  FieldName(FieldIndex:integer):string;
   function  IEof:boolean;
   procedure INext;
  end;


  type
  ISQLStatMaker = interface
  ['{39477B70-12C9-4F70-993E-0E1067A8D649}']
// For Statistics
   function    FixStartTime(const ObjName,VarName:string):Integer;
   function    FixEndTime(const ObjName,VarName:string):Integer;
   function    GetVarInt(const ObjName,VarName:string):Integer;
   function    GetVarStr(const ObjName,VarName:string):string;
   function    IncCounter(const ObjName,VarName:string):Integer;
   procedure   SetNull(const ObjName,VarName:string);
   procedure   SetStringValue(const ObjName,VarName,Value:string);
   function    AddIntValue(const ObjName,VarName:string;Value:integer):integer;
   procedure   SetIntValue(const ObjName,VarName:string;Value:integer);
//
   procedure   AddToStrings(const ObjName,VarName,Value:string);
   procedure   ClearStrings(const ObjName,VarName:string);
   function    GetVarStrings(const ObjName,VarName:string):TStrings;
   procedure   Clear;

   procedure   SetActiveStatistics(const Value:boolean);
   function    GetActiveStatistics:boolean;

   property  ActiveStatistics:boolean read GetActiveStatistics write SetActiveStatistics;
  end;

  TLogFlag = (lfQPrepare, lfQExecute, lfQFetch,
   lfConnect, lfTransact,lfService,lfMisc
  );
  TLogFlags = set of TLogFlag;

  ISQLLogger = interface
  ['{2CB9280F-2324-40CD-BFB4-42C0FD36107F}']
   procedure   SetActiveLogging(const Value:boolean);
   function    GetActiveLogging:boolean;
   function    GetLogFlags :TLogFlags;
   function    GetInstance:TObject;
   procedure   SetLogFlags(Value:TLogFlags);
   procedure   SetDatabase(aDatabase:TObject);
   procedure   WriteData(const ObjectName,OperationName,EventText: string;
    DataType: TLogFlag
   );
   property    ActiveLogging:boolean read GetActiveLogging write SetActiveLogging;
   property    LogFlags:TLogFlags read GetLogFlags write SetLogFlags;
  end;



  IFIBStringer=interface
   ['{6756F6D0-3E0B-4035-81A6-6D2B579312D3}']
//StrUtil
   function FormatIdentifier(Dialect: Integer; const Value: string): string;
   function PosCh(aCh:Char; const s:string):integer;
   function PosCh1(aCh:Char; const s:string; StartPos:integer):integer;
   function PosCI(const Substr,Str:string):integer;
   function  EmptyStrings(SL:TStrings):boolean;
   function  EquelStrings(const s,s1:string; CaseSensitive:boolean):boolean;
   procedure DeleteEmptyStr(Src:TStrings);//
   function PosInRight(const substr,Str:string;BeginPos:integer):integer;
   function LastChar(const Str:string):Char;
   function ExtractWord(Num:integer;const Str: string;const  WordDelims:TCharSet):string;
   function WordCount(const S: string; const WordDelims: TCharSet): Integer;
   //SqlTxtRtns
   function  TableByAlias(const SQLText,Alias:string):string;
   procedure DispositionFromClause(const SQLText:string;var X,Y:integer);
   procedure AllTables(const SQLText:string;aTables:TStrings; WithSP:boolean =False
     ;WithAliases:boolean =False
   );
   function  AliasForTable(const SQLText,TableName:string):string;
   function SetOrderClause(const SQLText,Order:string):string;
   function AddToMainWhereClause(const SQLText,Condition:string):string;
  end;

  IFIBMetaDataExtractor=interface
  ['{0F691E74-EAA3-431E-B33F-01CA62275E33}']
   function DBPrimaryKeys(const TableName:string;Transaction:TObject):string;
   function IsCalculatedField(const TableName,FieldName:string;Transaction:TObject):boolean;
   function ObjectDDLTxt(Transaction:TObject;ObjectType:Integer; const ObjectName:string; ForceLoad:boolean=True): string ;
   function ObjectListFields(const ObjectName:string; var DDL:string ;ForceLoad:boolean=True;IncludeOBJName:boolean=False): string ;   
   function GetTablesCount: Integer;
   function GetProceduresCount: Integer;
   function GetViewsCount: Integer;
   function GetUDFSCount: Integer;

   function GetExceptionsCount: Integer;
   function GetGeneratorsCount: Integer;
   function GetDomainsCount: Integer;
///
   function GetTableName(Index:integer): string;
   function GetViewName(Index:integer): string;
   function GetProcedureName(Index:integer): string;
   function GetUDFName(Index:integer): string;
   function GetGeneratorName(Index:integer): string;   

///
   procedure SetDatabase(Database:TObject);
   procedure LoadObjectNames;
   function GetNamesLoaded: boolean;

   property TablesCount: Integer read GetTablesCount;
   property TableName[Index: Integer]: string read GetTableName;

   property ViewsCount: Integer read GetViewsCount;
   property ViewName[Index: Integer]: string read GetViewName;

   property ProceduresCount: Integer read GetProceduresCount;
   property ProcedureName[Index: Integer]: string read GetProcedureName;

   property UDFSCount: Integer read GetUDFSCount;
   property UDFName[Index: Integer]: string read GetUDFName;   

   property GeneratorsCount: Integer read GetGeneratorsCount;
   property GeneratorsName[Index:Integer]: string read GetGeneratorName;

   property ExceptionsCount: Integer read GetExceptionsCount;
   property DomainsCount: Integer read GetDomainsCount;


   property NamesLoaded :boolean read GetNamesLoaded;            
  end;

  IFIBObject= interface
  end;

  IFIBConnect = interface(IFIBObject)
  ['{95317D9C-18B2-41B0-8C5B-8941561574B2}']
    function GetDatabaseName: string;
    procedure SetDatabaseName(const Value: string);
    procedure SaveAlias;
    function QueryValueAsStr(const aSQL: string; FieldNo: Integer;
        ParamValues:array of variant): string;
    function Execute(const SQL: string): boolean;
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

  IFIBSQLObject= interface(IFIBObject)
  ['{D9361B56-E2FC-4F01-B477-CC655C86C63B}']
   procedure Prepare;
   function  ParamCount:integer;
   function  ParamName(ParamIndex:integer):string;
   function  ParamExist(const ParamName:string; var ParamIndex:integer):boolean;
   function  ParamValue(const ParamName:string):variant;   overload;
   function  ParamValue(const ParamIndex:integer):variant; overload;
   function  DefMacroValue(const MacroName:string):string;
   procedure SetParamValue(const ParamIndex:integer; aValue:Variant); overload;
   procedure SetParamValues(const ParamValues: array of Variant); overload;
   procedure SetParamValues(const ParamNames: string;ParamValues: array of Variant); overload;

   function  FieldsCount:integer;
   function  FieldExist(const FieldName:string; var FieldIndex:integer):boolean;

   function  FieldValue(const FieldName:string; Old:boolean):variant;   overload;
   function  FieldValue(const FieldIndex:integer;Old:boolean):variant; overload;
   function  FieldName(FieldIndex:integer):string;
   function  IEof:boolean;
   procedure INext;
   function  TableAliasForField(const aFieldName:string):string;
  end;

  IFIBDataSet = interface(IFIBSQLObject)
  ['{F13CC688-BAE0-48A0-8FDF-8FA97D3F6577}']
    function  GetRelationTableName(Field:TObject):string;
    function  GetRelationFieldName(Field:TObject):string;
    procedure ParseParamToFieldsLinks(Dest: TStrings);
    function  GetFieldOrigin(Fld:TField):string;
    procedure LoadRepositoryInfo;
  end;

  IFIBQuery  = interface(IFIBSQLObject)
  ['{CA17BA7E-D4BC-4D8C-9D42-E818C6B32324}']
   procedure CheckValidStatement;   // raise error if statement is invalid.
   procedure AddCondition(const Name,Condition: string;  Enabled: boolean);
   function  GetPlan:string;
   procedure ExecQuery;
   procedure Close;
   property Plan:string read GetPlan;
  end;

  TOnScriptStatementExec= procedure(Line:Integer; StatementNo: Integer) of object;

  TiSQLSection = (stUnknown,stSelect, stFields,
    stUpdate,stInsert,stDelete,stExecute, stSet, stComment,
    stFrom, stWhere, stGroupBy, stHaving,
    stUnion,    stPlan, stOrderBy, stForUpdate
  );


  TiSQLSections = array of TiSQLSection;

  IFIBScripter= interface
  ['{246837E8-1E9D-4FB9-94FE-03DBA2B555E3}']
     procedure   SetOnStatExec(CallBack:TOnScriptStatementExec);
     procedure   Parse(Terminator:string=';');
     procedure   ExecuteScript(FromStmt:integer=1);
     procedure   ExecuteFromFile(const FileName: string;Terminator:string=';');
     function    StatementsCount:integer;     
  end;


  ISQLParser = interface
  ['{B9A9DA9B-C258-4653-BE89-CE0C25930A88}']
   procedure   SetSQLText(const Value: string);
   function    iPosInSections(Position:integer):TiSQLSections;
   function    SectionInArray(Section:TiSQLSection ;ArrS:TiSQLSections):boolean;
   function    GetWord(Position:integer; var StartWord:integer ;PartOnly:boolean=False ):string;
   function    GetPrevWord(CurPosition:integer; var PosPrevWord:Integer):string;
   function    GetAllTables(WithSP:boolean=False):TStrings;
   function    CutAlias(const SQLString:string;AliasPosition:integer=0):string;
   function    CutTableName(const SQLString:string;AliasPosition:integer=0):string;
   function    AliasForTable(const SQLText,TableName:string):string;
   function    TableByAlias(const SQLText,Alias:string):string;
  end;

  IFIBClassesExporter = interface
   ['{AFC7CF1A-EAA5-4584-B47D-BDAD337B4EEC}']
   function iGetStringer:IFIBStringer;
   function iGetMetaExtractor:IFIBMetaDataExtractor;
   function iGetSQLParser:ISQLParser;
  end;


var
   FIBClassesExporter:IFIBClassesExporter=nil;
   expDatabaseClass:TComponentClass;
   expDatasetClass:TComponentClass;
   expTransactionClass:TComponentClass;
   expQueryClass      :TComponentClass;
   expServicesClass   :TComponentClass;
   expDeltaReceiverClass:TComponentClass;
   expScripter:TComponentClass;

implementation
uses pFIBDataset,pFIBDatabase,pFIBQuery,IB_Services,pFIBDataRefresh,pFIBScripter;

initialization
 expDatabaseClass:=TpFIBDatabase;
 expTransactionClass:=TpFIBTransaction;
 expDatasetClass:=TpFIBDataSet;
 expQueryClass  :=TpFIBQuery;
 expServicesClass   :=TpFIBCustomService;
 expDeltaReceiverClass:=TpFIBTableChangesReader;
 expScripter:=TpFIBScripter
end.
