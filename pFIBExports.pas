unit pFIBExports;

interface

{$I FIBPlus.inc}

 uses SysUtils,{$IFNDEF D6+}Windows,{$ELSE}FIBPlatforms,{$ENDIF}Classes,
      pFIBInterfaces,FIBDatabase,FIBQuery,FIBDataSet,pFIBDataSet,pFIBQuery,
      StrUtil,pFIBDatabase,SqlTxtRtns, pFIBMetaData;

 type




       TFIBStringer= class(TComponent, IFIBStringer)
       private
         function  FormatIdentifier(Dialect: Integer; const Value: string): string;
         procedure DispositionFromClause(const SQLText:string;var X,Y:integer);
         function  PosCh(aCh:Char; const s:string):integer;
         function  PosCh1(aCh:Char; const s:string; StartPos:integer):integer;
         function  PosCI(const Substr,Str:string):integer;
         function  EmptyStrings(SL:TStrings):boolean;
         function  EquelStrings(const s,s1:string; CaseSensitive:boolean):boolean;
         procedure DeleteEmptyStr(Src:TStrings);//
         procedure AllTables(const SQLText:string;aTables:TStrings; WithSP:boolean =False
           ;WithAliases:boolean =False
         );
         function WordCount(const S: string; const WordDelims: TCharSet): Integer;
         function ExtractWord(Num:integer;const Str: string;const  WordDelims:TCharSet):string;
         function PosInRight(const substr,Str:string;BeginPos:integer):integer;
         function LastChar(const Str:string):Char;
         function TableByAlias(const SQLText,Alias:string):string;
         function  AliasForTable(const SQLText,TableName:string):string;

         function SetOrderClause(const SQLText,Order:string):string;
         function AddToMainWhereClause(const SQLText,Condition:string):string;

       end;

       TMetaDataExtractor=class(TpFIBDBSchemaExtract, IFIBMetaDataExtractor)
       private
          function DBPrimaryKeys(const TableName:string;Transaction:TObject):string;
          function IsCalculatedField(const TableName,FieldName:string;Transaction:TObject):boolean;
          function ObjectDDLTxt(Transaction:TObject;ObjectType:Integer; const ObjectName:string; ForceLoad:boolean=True): string ;
          procedure SetDatabase(aDatabase:TObject);


          function GetTableName(Index:integer): string;
          function GetViewName(Index:integer): string;
          function GetProcedureName(Index:integer): string;
          function GetUDFName(Index:integer): string;
          function GetGeneratorName(Index:integer): string;          
          function ObjectListFields(const ObjectName:string; var DDL:string ;ForceLoad:boolean=True;IncludeOBJName:boolean=False): string ;
       public
         constructor Create(AOwner:TComponent); override;
         destructor Destroy; override;
       end;

       TiSQLParser=class(TSQLParser,ISQLParser)
       protected
    { IInterface }
          function _AddRef: Integer; stdcall;
          function _Release: Integer; stdcall;
       public
//         procedure   SetSQLText(const Value: string);
         function QueryInterface(const IID: TGUID; out Obj): HResult; virtual; stdcall;
         function    iPosInSections(Position:integer):TiSQLSections;
         function    SectionInArray(Section:TiSQLSection ;ArrS:TiSQLSections):boolean;
         function    CutAlias(const SQLString:string;AliasPosition:integer=0):string;
         function    CutTableName(const SQLString:string;AliasPosition:integer=0):string;
         function    AliasForTable(const SQLText,TableName:string):string;
         function  TableByAlias(const SQLText,Alias:string):string;
       end;

       TFIBClassesExporter =class (TComponent, IFIBClassesExporter,IFIBStringer,IFIBMetaDataExtractor,
       ISQLParser
       )
       private
         FStringer:TFIBStringer;
         FMetaDataExtractor:TMetaDataExtractor;
         FSQLParser :TiSQLParser;
         function iGetStringer:IFIBStringer;
         function iGetMetaExtractor:IFIBMetaDataExtractor;
         function iGetSQLParser:ISQLParser;
       public
         constructor Create(AOwner:TComponent); override;
         destructor  Destroy; override;
         property  Stringer:TFIBStringer read FStringer implements IFIBStringer;
         property  MetaDataExtractor:TMetaDataExtractor read FMetaDataExtractor implements IFIBMetaDataExtractor;
         property  SQLParser:TiSQLParser read FSQLParser implements iSQLParser;
       end
       ;





implementation

uses pFIBDataInfo,IB_Services;

var  vFIBClassesExporter:TFIBClassesExporter;




{ TFIBClassesExporter }



constructor TFIBClassesExporter.Create(AOwner: TComponent);
begin
  inherited;
  FIBClassesExporter:=Self;
  FStringer:=TFIBStringer.Create(Self);
  FMetaDataExtractor:=TMetaDataExtractor.Create(Self);
  FSQLParser:=TiSQLParser.Create;
end;

destructor TFIBClassesExporter.Destroy;
begin
  if Self= vFIBClassesExporter then
   vFIBClassesExporter:=nil;
  FSQLParser.Free; 
  inherited;
end;


function TFIBClassesExporter.iGetMetaExtractor: IFIBMetaDataExtractor;
begin
 Result:=FMetaDataExtractor
end;


function TFIBClassesExporter.iGetSQLParser: ISQLParser;
begin
 Result:=FSQLParser
end;

function TFIBClassesExporter.iGetStringer: IFIBStringer;
begin
 Result:=FStringer;
end;





procedure CreateExporter;
begin
   vFIBClassesExporter:=TFIBClassesExporter.Create(nil);
   with vFIBClassesExporter do
   begin
     Name:='FIBClassesExporter'
   end;
end;

{ TFIBStringer }

function TFIBStringer.AddToMainWhereClause(const SQLText,
  Condition: string): string;
begin
  Result:=SqlTxtRtns.AddToWhereClause(SQLText,Condition)
end;

function TFIBStringer.AliasForTable(const SQLText,
  TableName: string): string;
begin
 Result:=SqlTxtRtns.AliasForTable(SQLText,TableName)
end;

procedure TFIBStringer.AllTables(const SQLText: string; aTables: TStrings;
  WithSP, WithAliases: boolean);
begin
  SqlTxtRtns.AllTables(SQLText,aTables,WithSP,WithAliases);
end;

procedure TFIBStringer.DeleteEmptyStr(Src: TStrings);
begin
 StrUtil.DeleteEmptyStr(Src);
end;

procedure TFIBStringer.DispositionFromClause(const SQLText:string;var X,Y:integer);
var
   p:TPosition;
begin
  p:=SqlTxtRtns.DispositionFrom(SQLText);
  X:=P.X;
  Y:=P.Y
end;

function TFIBStringer.EmptyStrings(SL: TStrings): boolean;
begin
 Result:=StrUtil.EmptyStrings(SL)
end;

function TFIBStringer.EquelStrings(const s, s1: string;
  CaseSensitive: boolean): boolean;
begin
 Result:=StrUtil.EquelStrings(s, s1,  CaseSensitive)
end;

function TFIBStringer.ExtractWord(Num: integer; const Str: string;
  const WordDelims: TCharSet): string;
begin
  Result:=StrUtil.ExtractWord(Num, Str,WordDelims)
end;

function TFIBStringer.FormatIdentifier(Dialect: Integer;
  const Value: string): string;
begin
  Result:=StrUtil.FormatIdentifier(Dialect,Value)
end;

function TFIBStringer.LastChar(const Str: string): Char;
begin
 Result:=StrUtil.LastChar(Str)
end;

function TFIBStringer.PosCh(aCh: Char; const s: string): integer;
begin
  Result:=StrUtil.PosCh(aCh,s)
end;

function TFIBStringer.PosCh1(aCh: Char; const s: string;
  StartPos: integer): integer;
begin
   Result:=StrUtil.PosCh1(aCh,s,StartPos)
end;

function TFIBStringer.PosCI(const Substr, Str: string): integer;
begin
 Result:=StrUtil.PosCI(Substr, Str)
end;

function TFIBStringer.PosInRight(const substr, Str: string;
  BeginPos: integer): integer;
begin
 Result:=StrUtil.PosInRight(substr, Str, BeginPos)
end;

function TFIBStringer.SetOrderClause(const SQLText, Order: string): string;
begin
 Result:=SqlTxtRtns.SetOrderClause(SQLText,Order)
end;

function TFIBStringer.TableByAlias(const SQLText, Alias: string): string;
begin
 Result:=SqlTxtRtns.TableByAlias(SQLText,Alias)
end;

function TFIBStringer.WordCount(const S: string;
  const WordDelims: TCharSet): Integer;
begin
 Result:=StrUtil.WordCount(S,WordDelims)
end;

{ TMetaDataExtractor }

constructor TMetaDataExtractor.Create(AOwner: TComponent);
begin
  inherited;
end;

function TMetaDataExtractor.DBPrimaryKeys(const TableName: string;
  Transaction: TObject): string;
begin
 Result:=pFIBDataInfo.DBPrimaryKeyFields(TableName,TFIBTransaction(Transaction))
end;

destructor TMetaDataExtractor.Destroy;
begin

  inherited;
end;

function TMetaDataExtractor.GetGeneratorName(Index: integer): string;
begin
 Result:=Generators[Index].Name
end;

function TMetaDataExtractor.GetProcedureName(Index: integer): string;
begin
 Result:=Procedures[Index].Name
end;

function TMetaDataExtractor.GetTableName(Index: integer): string;
begin
 Result:=Tables[Index].Name
end;

function TMetaDataExtractor.GetUDFName(Index: integer): string;
begin
 Result:=UDFS[Index].Name
end;

function TMetaDataExtractor.GetViewName(Index: integer): string;
begin
 Result:=Views[Index].Name
end;

function TMetaDataExtractor.IsCalculatedField(const TableName,
  FieldName: string; Transaction: TObject): boolean;
var
    vpFIBTableInfo:TpFIBTableInfo;
    vFi:TpFIBFieldInfo;

begin
  ListTableInfo.Clear;
  vpFIBTableInfo:=ListTableInfo.GetTableInfo(TFIBTransaction(Transaction).MainDatabase,TableName,False);
  vFi:=vpFIBTableInfo.FieldInfo(FieldName);
  Result:= (vFi=nil) or  vFi.IsComputed or vFi.IsTriggered ;
end;


function TMetaDataExtractor.ObjectDDLTxt(Transaction:TObject;ObjectType: Integer;
  const ObjectName: string; ForceLoad: boolean): string;
var
 Extractor:TpFIBDBSchemaExtract;
begin
 Result:='';
 if (Transaction=nil ) or (TFIBTransaction(Transaction).DefaultDatabase=nil) then
  Exit;
 Extractor:=TpFIBDBSchemaExtract.Create(nil);
 try
   Extractor.Database:=TFIBTransaction(Transaction).DefaultDatabase;
   Result:=Extractor.GetObjectDDL(TDBObjectType(ObjectType), ObjectName, ForceLoad);
 finally
  Extractor.Free
 end;
end;

function TMetaDataExtractor.ObjectListFields(
  const ObjectName: string; var DDL:string ;ForceLoad: boolean=True;IncludeOBJName:boolean=False): string;
var
   obj:TCustomMetaObject;
   i:integer;
begin
  obj:=FMetaDatabase.GetDBObject(Database,otTable,ObjectName,ForceLoad);
  if obj=nil then
    obj:=FMetaDatabase.GetDBObject(Database,otView,ObjectName,ForceLoad);
  if obj=nil then
    obj:=FMetaDatabase.GetDBObject(Database,otProcedure,ObjectName,ForceLoad);

  Result:='';
  DDL:='';
  if obj=nil then
   Exit;

  if obj is TMetaTable then
  begin
    with TMetaTable(obj) do
    for i:=0 to FieldsCount-1 do
    begin
     if IncludeOBJName then
      DDL:=Result+FormatIdentifier(3,ObjectName)+'.'+ Fields[i].FormatName+#13#10     
     else
      DDL:=Result+Fields[i].FormatName+#13#10;
     Result:=DDL
    end;
  end
  else
  if obj is TMetaView then
  begin
    with TMetaView(obj) do
    for i:=0 to FieldsCount-1 do
    begin
//     DDL:=DDL+Fields[i].AsDDL;
     if IncludeOBJName then
      DDL:=Result+FormatIdentifier(3,ObjectName)+'.'+ Fields[i].FormatName+#13#10
     else
      DDL:=Result+Fields[i].FormatName+#13#10;
     Result:=DDL

    end;
  end
  else
  if obj is TMetaProcedure then
  begin
    with TMetaProcedure(obj) do
    for i:=0 to OutputFieldsCount-1 do
    begin
//     DDL:=DDL+Fields[i].AsDDL;
     if IncludeOBJName then
      DDL:=Result+FormatIdentifier(3,ObjectName)+'.'+ OutputFields[i].FormatName+#13#10
     else
      DDL:=Result+OutputFields[i].FormatName+#13#10;
     Result:=DDL

    end;
  end

end;

procedure TMetaDataExtractor.SetDatabase(aDatabase: TObject);
begin
 if Database<>aDatabase then
   Database:=TFIBDatabase(aDatabase)
end;

{ TiSQLParser }

function TiSQLParser._AddRef: Integer;
begin
    Result := -1   // -1 indicates no reference counting is taking place
end;

function TiSQLParser._Release: Integer;
begin
    Result := -1   // -1 indicates no reference counting is taking place
end;

function TiSQLParser.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
    if GetInterface(IID, Obj) then Result := S_OK
     else Result := E_NOINTERFACE
end;
{
procedure TiSQLParser.SetSQLText(const Value: string);
begin
  SQLText:=Value
end;
 }
function TiSQLParser.iPosInSections(Position: integer): TiSQLSections;
begin
 Result:=TiSQLSections(PosInSections(Position))
end;

function TiSQLParser.SectionInArray(Section: TiSQLSection;
  ArrS: TiSQLSections): boolean;
var
   i,L:integer;
begin
  Result:=False;
  L:=Length(ArrS)-1;
  for i:=0 to L do
  if ArrS[i]=Section then
  begin
    Result:=True; Exit
  end;
end;

function TiSQLParser.TableByAlias(const SQLText, Alias: string): string;
begin
 Result:=SqlTxtRtns.TableByAlias(SQLText, Alias)
end;

function TiSQLParser.CutAlias(const SQLString: string;
  AliasPosition: integer): string;
begin
 Result:=SqlTxtRtns.CutAlias(SQLString,AliasPosition)
end;

function TiSQLParser.CutTableName(const SQLString: string;
  AliasPosition: integer): string;
begin
 Result:=SqlTxtRtns.CutTableName(SQLString,AliasPosition)
end;

function TiSQLParser.AliasForTable(const SQLText,
  TableName: string): string;
begin
 Result:=SqlTxtRtns.AliasForTable(SQLText,TableName)
end;

initialization

 CreateExporter;

finalization
 FIBClassesExporter:=nil;
 if vFIBClassesExporter<>nil then
  vFIBClassesExporter.Free
end.


