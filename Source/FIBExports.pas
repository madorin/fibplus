unit FIBExports;

interface

{$I FIB.inc}

uses
  SysUtils, FIBPlatforms, Classes,
  FIBInterfaces, FIBDatabase, FIBQuery, FIBDataSet,
  StrUtil, SqlTxtRtns, FIBMetaData;

type

  TFIBStringer = class(TComponent, IFIBStringer)
  private
    function FormatIdentifier(Dialect: Integer; const Value: string): string;
    procedure DispositionFromClause(const SQLText: string; var X, Y: Integer);
    function PosCh(aCh: Char; const s: string): Integer;
    function PosCh1(aCh: Char; const s: string; StartPos: Integer): Integer;
    function PosCI(const Substr, Str: string): Integer;
    function EmptyStrings(SL: TStrings): Boolean;
    function EqualStrings(const s, s1: string; CaseSensitive: Boolean): Boolean;
    procedure DeleteEmptyStr(Src: TStrings); //
    procedure AllTables(const SQLText: string; aTables: TStrings; WithSP: Boolean = False; WithAliases: Boolean = False);
    function WordCount(const s: string; const WordDelims: TFIBAnsiCharSet): Integer;
    function ExtractWord(Num: Integer; const Str: string; const WordDelims: TFIBAnsiCharSet): string;
    function PosInRight(const Substr, Str: string; BeginPos: Integer): Integer;
    function LastChar(const Str: string): Char;
    function TableByAlias(const SQLText, Alias: string): string;
    function AliasForTable(const SQLText, TableName: string): string;

    function SetOrderClause(const SQLText, Order: string): string;
    function AddToMainWhereClause(const SQLText, Condition: string): string;

  end;

  TFIBMetaDataExtractor = class(TFIBDBSchemaExtract, IFIBMetaDataExtractor)
  private
    function DBPrimaryKeys(const TableName: string; Transaction: TObject): string;
    function IsCalculatedField(const TableName, FieldName: string; Transaction: TObject): Boolean;
    function ObjectDDLTxt(Transaction: TObject; ObjectType: Integer; const ObjectName: string; ForceLoad: Boolean = True): string;
    procedure SetDatabase(aDatabase: TObject);

    function GetTableName(Index: Integer): string;
    function GetViewName(Index: Integer): string;
    function GetProcedureName(Index: Integer): string;
    function GetUDFName(Index: Integer): string;
    function GetGeneratorName(Index: Integer): string;
    function ObjectListFields(const ObjectName: string; var DDL: string;
      ForceLoad: Boolean = True; IncludeOBJName: Boolean = False): string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  TFIBInterfacedSQLParser = class(TFIBSQLParser, IFIBSQLParser)
  protected
    { IInterface }
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    function QueryInterface(const IID: TGUID; out Obj): HResult; virtual; stdcall;
    function iPosInSections(Position: Integer): TFIBInterfaceSQLSections;
    function CutAlias(const SQLString: string; AliasPosition: Integer = 0): string;
    function CutTableName(const SQLString: string; AliasPosition: Integer = 0): string;
    function AliasForTable(const SQLText, TableName: string): string;
    function TableByAlias(const SQLText, Alias: string): string;
  end;

  TFIBClassesExporter = class(TComponent, IFIBClassesExporter, IFIBStringer,
    IFIBMetaDataExtractor, IFIBSQLParser)
  private
    FStringer: TFIBStringer;
    FMetaDataExtractor: TFIBMetaDataExtractor;
    FSQLParser: TFIBInterfacedSQLParser;
    function iGetStringer: IFIBStringer;
    function iGetMetaExtractor: IFIBMetaDataExtractor;
    function iGetSQLParser: IFIBSQLParser;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Stringer: TFIBStringer read FStringer implements IFIBStringer;
    property MetaDataExtractor: TFIBMetaDataExtractor read FMetaDataExtractor implements IFIBMetaDataExtractor;
    property SQLParser: TFIBInterfacedSQLParser read FSQLParser implements IFIBSQLParser;
  end;

type
  // Deprecated names of the types renamed in 8.0.0
  TMetaDataExtractor = TFIBMetaDataExtractor deprecated 'Use TFIBMetaDataExtractor';
  TiSQLParser = TFIBInterfacedSQLParser deprecated 'Use TFIBInterfacedSQLParser';

implementation

uses
  FIBDataInfo, FIBProps, FIBServices;

var
  ClassesExporterInstance: TFIBClassesExporter;

  { TFIBClassesExporter }

constructor TFIBClassesExporter.Create(AOwner: TComponent);
begin
  inherited;
  FIBClassesExporter := Self;
  FStringer := TFIBStringer.Create(Self);
  FMetaDataExtractor := TFIBMetaDataExtractor.Create(Self);
  FSQLParser := TFIBInterfacedSQLParser.Create;
end;

destructor TFIBClassesExporter.Destroy;
begin
  if Self = ClassesExporterInstance then
    ClassesExporterInstance := nil;
  FSQLParser.Free;
  inherited;
end;

function TFIBClassesExporter.iGetMetaExtractor: IFIBMetaDataExtractor;
begin
  Result := FMetaDataExtractor
end;

function TFIBClassesExporter.iGetSQLParser: IFIBSQLParser;
begin
  Result := FSQLParser
end;

function TFIBClassesExporter.iGetStringer: IFIBStringer;
begin
  Result := FStringer;
end;

procedure CreateExporter;
begin
  ClassesExporterInstance := TFIBClassesExporter.Create(nil);
  with ClassesExporterInstance do
  begin
    Name := 'FIBClassesExporter'
  end;
end;

{ TFIBStringer }

function TFIBStringer.AddToMainWhereClause(const SQLText, Condition: string): string;
begin
  Result := SqlTxtRtns.AddToWhereClause(SQLText, Condition)
end;

function TFIBStringer.AliasForTable(const SQLText, TableName: string): string;
begin
  Result := SqlTxtRtns.AliasForTable(SQLText, TableName)
end;

procedure TFIBStringer.AllTables(const SQLText: string; aTables: TStrings; WithSP, WithAliases: Boolean);
begin
  SqlTxtRtns.AllTables(SQLText, aTables, WithSP, WithAliases);
end;

procedure TFIBStringer.DeleteEmptyStr(Src: TStrings);
begin
  StrUtil.DeleteEmptyStr(Src);
end;

procedure TFIBStringer.DispositionFromClause(const SQLText: string; var X, Y: Integer);
var
  p: TFIBPosition;
begin
  p := SqlTxtRtns.DispositionFrom(SQLText);
  X := p.X;
  Y := p.Y
end;

function TFIBStringer.EmptyStrings(SL: TStrings): Boolean;
begin
  Result := StrUtil.EmptyStrings(SL)
end;

function TFIBStringer.EqualStrings(const s, s1: string; CaseSensitive: Boolean): Boolean;
begin
  Result := StrUtil.EqualStrings(s, s1, CaseSensitive)
end;

function TFIBStringer.ExtractWord(Num: Integer; const Str: string; const WordDelims: TFIBAnsiCharSet): string;
begin
  Result := StrUtil.ExtractWord(Num, Str, WordDelims)
end;

function TFIBStringer.FormatIdentifier(Dialect: Integer; const Value: string): string;
begin
  Result := StrUtil.FormatIdentifier(Dialect, Value)
end;

function TFIBStringer.LastChar(const Str: string): Char;
begin
  Result := StrUtil.LastChar(Str)
end;

function TFIBStringer.PosCh(aCh: Char; const s: string): Integer;
begin
  Result := StrUtil.PosCh(aCh, s)
end;

function TFIBStringer.PosCh1(aCh: Char; const s: string; StartPos: Integer): Integer;
begin
  Result := StrUtil.PosCh1(aCh, s, StartPos)
end;

function TFIBStringer.PosCI(const Substr, Str: string): Integer;
begin
  Result := StrUtil.PosCI(Substr, Str)
end;

function TFIBStringer.PosInRight(const Substr, Str: string; BeginPos: Integer): Integer;
begin
  Result := StrUtil.PosInRight(Substr, Str, BeginPos)
end;

function TFIBStringer.SetOrderClause(const SQLText, Order: string): string;
begin
  Result := SqlTxtRtns.SetOrderClause(SQLText, Order)
end;

function TFIBStringer.TableByAlias(const SQLText, Alias: string): string;
begin
  Result := SqlTxtRtns.TableByAlias(SQLText, Alias)
end;

function TFIBStringer.WordCount(const s: string; const WordDelims: TFIBAnsiCharSet): Integer;
begin
  Result := StrUtil.WordCount(s, WordDelims)
end;

{ TFIBMetaDataExtractor }

constructor TFIBMetaDataExtractor.Create(AOwner: TComponent);
begin
  inherited;
end;

function TFIBMetaDataExtractor.DBPrimaryKeys(const TableName: string; Transaction: TObject): string;
begin
  Result := FIBDataInfo.DBPrimaryKeyFields(TableName, TFIBTransaction(Transaction))
end;

destructor TFIBMetaDataExtractor.Destroy;
begin

  inherited;
end;

function TFIBMetaDataExtractor.GetGeneratorName(Index: Integer): string;
begin
  Result := Generators[Index].Name
end;

function TFIBMetaDataExtractor.GetProcedureName(Index: Integer): string;
begin
  Result := Procedures[Index].Name
end;

function TFIBMetaDataExtractor.GetTableName(Index: Integer): string;
begin
  Result := Tables[Index].Name
end;

function TFIBMetaDataExtractor.GetUDFName(Index: Integer): string;
begin
  Result := UDFS[Index].Name
end;

function TFIBMetaDataExtractor.GetViewName(Index: Integer): string;
begin
  Result := Views[Index].Name
end;

function TFIBMetaDataExtractor.IsCalculatedField(const TableName, FieldName: string; Transaction: TObject): Boolean;
var
  TableInfo: TFIBTableInfo;
  FieldInfo: TFIBFieldInfo;

begin
  // Fresh info of this table only: the cache is shared by all the datasets
  TableInfoCache.ClearForTable(TableName);
  TableInfo := TableInfoCache.GetTableInfo(TFIBTransaction(Transaction).MainDatabase, TableName, False);
  FieldInfo := TableInfo.FieldInfo(FieldName);
  Result := (FieldInfo = nil) or FieldInfo.IsComputed or FieldInfo.IsTriggered;
end;

function TFIBMetaDataExtractor.ObjectDDLTxt(Transaction: TObject; ObjectType: Integer; const ObjectName: string; ForceLoad: Boolean): string;
var
  Extractor: TFIBDBSchemaExtract;
begin
  Result := '';
  if (Transaction = nil) or (TFIBTransaction(Transaction).DefaultDatabase = nil) then
    Exit;
  Extractor := TFIBDBSchemaExtract.Create(nil);
  try
    Extractor.Database := TFIBTransaction(Transaction).DefaultDatabase;
    Result := Extractor.GetObjectDDL(TFIBDBObjectType(ObjectType), ObjectName, ForceLoad);
  finally
    Extractor.Free
  end;
end;

function TFIBMetaDataExtractor.ObjectListFields(const ObjectName: string;
  var DDL: string; ForceLoad: Boolean = True;
  IncludeOBJName: Boolean = False): string;
var
  Obj: TFIBCustomMetaObject;
  i: Integer;
begin
  Obj := FMetaDatabase.GetDBObject(Database, otTable, ObjectName, ForceLoad);
  if Obj = nil then
    Obj := FMetaDatabase.GetDBObject(Database, otView, ObjectName, ForceLoad);
  if Obj = nil then
    Obj := FMetaDatabase.GetDBObject(Database, otProcedure, ObjectName, ForceLoad);

  Result := '';
  DDL := '';
  if Obj = nil then
    Exit;

  if Obj is TFIBMetaTable then
  begin
    with TFIBMetaTable(Obj) do
      for i := 0 to FieldsCount - 1 do
      begin
        if IncludeOBJName then
          DDL := Result + FormatIdentifier(3, ObjectName) + '.' + Fields[i].FormatName + #13#10
        else
          DDL := Result + Fields[i].FormatName + #13#10;
        Result := DDL
      end;
  end
  else if Obj is TFIBMetaView then
  begin
    with TFIBMetaView(Obj) do
      for i := 0 to FieldsCount - 1 do
      begin
        if IncludeOBJName then
          DDL := Result + FormatIdentifier(3, ObjectName) + '.' + Fields[i].FormatName + #13#10
        else
          DDL := Result + Fields[i].FormatName + #13#10;
        Result := DDL

      end;
  end
  else if Obj is TFIBMetaProcedure then
  begin
    with TFIBMetaProcedure(Obj) do
      for i := 0 to OutputFieldsCount - 1 do
      begin
        if IncludeOBJName then
          DDL := Result + FormatIdentifier(3, ObjectName) + '.' + OutputFields
            [i].FormatName + #13#10
        else
          DDL := Result + OutputFields[i].FormatName + #13#10;
        Result := DDL

      end;
  end

end;

procedure TFIBMetaDataExtractor.SetDatabase(aDatabase: TObject);
begin
  if Database <> aDatabase then
    Database := TFIBDatabase(aDatabase)
end;

{ TFIBInterfacedSQLParser }

function TFIBInterfacedSQLParser._AddRef: Integer;
begin
  Result := -1 // -1 indicates no reference counting is taking place
end;

function TFIBInterfacedSQLParser._Release: Integer;
begin
  Result := -1 // -1 indicates no reference counting is taking place
end;

function TFIBInterfacedSQLParser.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := S_OK
  else
    Result := E_NOINTERFACE
end;

function TFIBInterfacedSQLParser.iPosInSections(Position: Integer): TFIBInterfaceSQLSections;
begin
  Result := TFIBInterfaceSQLSections(PosInSections(Position))
end;

function TFIBInterfacedSQLParser.TableByAlias(const SQLText, Alias: string): string;
begin
  Result := SqlTxtRtns.TableByAlias(SQLText, Alias)
end;

function TFIBInterfacedSQLParser.CutAlias(const SQLString: string; AliasPosition: Integer): string;
begin
  Result := SqlTxtRtns.CutAlias(SQLString, AliasPosition)
end;

function TFIBInterfacedSQLParser.CutTableName(const SQLString: string; AliasPosition: Integer): string;
begin
  Result := SqlTxtRtns.CutTableName(SQLString, AliasPosition)
end;

function TFIBInterfacedSQLParser.AliasForTable(const SQLText, TableName: string): string;
begin
  Result := SqlTxtRtns.AliasForTable(SQLText, TableName)
end;

initialization

CreateExporter;

finalization

FIBClassesExporter := nil;
if ClassesExporterInstance <> nil then
  ClassesExporterInstance.Free

end.
