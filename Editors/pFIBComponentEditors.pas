unit pFIBComponentEditors;

interface

{$I ..\FIBPlus.inc}
uses
   Classes, SysUtils,
   {$IFDEF D_XE2}
    Vcl.Forms,Vcl.Controls,DB,Vcl.Dialogs,
   {$ELSE}
   Forms,Controls,DB,Dialogs,
   {$ENDIF}
   ToCodeEditor,TypInfo,   ColnEdit,
  {$IFDEF D6+}
     DesignEditors,DesignIntf, Variants
  {$else}
     DsgnIntf
  {$ENDIF}
;



type
 TFIBAliasEdit = class(TStringProperty)
    function  GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
 end;

  TFileNameProperty = class(TStringProperty)
  public
    procedure Edit; override;
    function  GetAttributes: TPropertyAttributes; override;
  end;

  TpFIBDatabaseEditor = class(TComponentEditor)
    procedure ExecuteVerb(Index: Integer); override;
    function  GetVerb(Index: Integer): string; override;
    function  GetVerbCount: Integer; override;
  end;

  TpFIBTransactionEditor = class(TComponentEditor)
    procedure ExecuteVerb(Index: Integer); override;
    function  GetVerb(Index: Integer): string; override;
    function  GetVerbCount: Integer; override;
  end;

  TpFIBDeltaReceiverEditor = class(TComponentEditor)
    procedure ExecuteVerb(Index: Integer); override;
    function  GetVerb(Index: Integer): string; override;
    function  GetVerbCount: Integer; override;
  end;

  TFIBConditionsEditor = class(TClassProperty)
  public
    function  GetAttributes: TPropertyAttributes; override;
    procedure Edit; override;
  end;

  TpFIBDataSetOptionsEditor = class(TSetProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure Edit; override;
  end;

  TpFIBAutoUpdateOptionsEditor = class(TClassProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure Edit; override;
  end;

  TEdParamToFields     = class(TClassProperty)
  public
    function  GetAttributes: TPropertyAttributes; override;
    function  GetValue: string; override;
    procedure Edit; override;
  end;

  TKeyFieldNameEdit = class(TStringProperty)
    function  GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;


  TpFIBStoredProcProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

  TGeneratorNameEdit = class(TStringProperty)
  public
    function  GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

  TTableNameEdit = class(TStringProperty)
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

  TTableNameEditDR = class(TStringProperty)
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

 TFIBTrKindEdit = class(TStringProperty)
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
 end;

  TpFIBTRParamsEditor = class(TClassProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    procedure Edit; override;
  end;


  TpFIBQueryEditor = class(TComponentEditor)
    procedure ExecuteVerb(Index: Integer); override;
    function  GetVerb(Index: Integer): string; override;
    function  GetVerbCount: Integer; override;
  end;

  TDataSet_ID_Edit = class(TIntegerProperty)
  public
    function  GetAttributes: TPropertyAttributes; override;
    procedure Edit; override;
  end;

  TFIBSQLsProperties = class(TClassProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    procedure Edit; override;
  end;

  TFIBSQLsProperty = class(TClassProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    procedure Edit; override;
  end;

  
  TFIBGenSQlEd = class(TComponentEditor)
  {$IFDEF D6+}
    DefaultEditor: IComponentEditor;
  {$ELSE}
    DefaultEditor: TComponentEditor;
  {$ENDIF}
  public
{$IFDEF VER100}
    constructor Create(AComponent: TComponent; ADesigner: TFormDesigner); override;
{$ELSE}
  {$IFNDEF D6+}
    constructor Create(AComponent: TComponent; ADesigner: IFormDesigner); override;
  {$ELSE}
    constructor Create(AComponent: TComponent; ADesigner: IDesigner); override;
  {$ENDIF}
{$ENDIF}
    destructor Destroy; override;
    procedure ExecuteVerb(Index: Integer); override;
    function  GetVerb(Index: Integer): string; override;
    function  GetVerbCount: Integer; override;
    procedure SaveDataSetInfo;
  end;

  TpFIBSQLPropEdit =class(TClassProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure Edit; override;
  end;

  TpFIBGeneratorsProperty = class(TPropertyEditor {TClassProperty})
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    procedure Edit; override;
  end;

implementation

uses RegistryUtils, pFIBEditorsConsts, pFIBDBEdit
// , EdFieldInfo
, pFIBInterfaces, pFIBRepositoryOperations, EdFieldInfo, EdErrorInfo,
  pFIBConditionsEdit, EdDataSetInfo, pFIBTrEdit, pFIBDataSetOptions,
  pFIBAutoUpdEditor, RegFIBPlusEditors, RTTIRoutines, FIBSQLEditor,
  EdParamToFields, FIBDataSQLEditor,uFIBScriptForm;


{ TFIBAliasEdit }

type
  IFIBClassesExporter = interface
   ['{AFC7CF1A-EAA5-4584-B47D-BDAD337B4EEC}']
   function iGetStringer:IFIBStringer;
   function iGetMetaExtractor:IFIBMetaDataExtractor;
  end;


function TFIBAliasEdit.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes;
  Result := Result + [paValueList]
end;

procedure TFIBAliasEdit.GetValues(Proc: TGetStrProc);
var i: integer;
  Keys: Variant;
begin
{$IFNDEF NO_REGISTRY}
  if PropCount > 1 then Exit;
  Keys := DefAllSubKey(['Software', RegFIBRoot, 'Aliases']);
  if VarType(Keys) = varBoolean then Exit;
  for i := VarArrayLowBound(Keys, 1) to VarArrayHighBound(Keys, 1) do Proc(Keys[i])
{$ENDIF}  
end;

{ TFileNameProperty }

procedure TFileNameProperty.Edit;
var
  FileOpen: TOpenDialog;
  pName:string;
  pValue:string;

begin
  pName    :=GetPropInfo^.Name;
  pValue   :=GetValue;
  FileOpen := TOpenDialog.Create(Application);
  try
    with Fileopen do
    begin
     if Trim(pValue)<>'' then
//     if DirectoryExists(ExtractFilePath(pValue)) then
      FileOpen.InitialDir:=ExtractFilePath(pValue)
     else
      FileOpen.InitialDir:='c:\';
      if pName='DBName' then
         Filter := 'IB base files|*.gdb|IB7 base files|*.ib|Firebird base files|*.fdb|All files|*.*'
      else
      if pName='CacheFileName' then
       Filter := 'INI|*.ini|All files|*.*'
      else
       Filter := 'DLL|*.dll|All files|*.*';

      if FileExists(pValue) then
       FileName:=pValue;
      if Execute then
        SetValue(Filename);
    end;
  finally
    Fileopen.free;
  end;
end;

function TFileNameProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog, paRevertable];
end;

{ TpFIBDatabaseEditor }


procedure TpFIBDatabaseEditor.ExecuteVerb(Index: Integer);
var
   db:IFIBConnect;
   Script:TStrings;
   Stringer:IFIBStringer;
   Connected:Boolean;
begin
  if  ObjSupports(Component,IFIBConnect,db) then
  case Index of
    0 :if EditFIBDatabase(Component) then
        Designer.Modified;
    1 : begin
         // try to connect
         if not GetPropValue(Component,'Connected',False) then
         begin
          MessageDlg(SCompDatabaseNotConnected, mtConfirmation, [mbOK], 0);
          Exit;
         end;
         if db.QueryValueAsStr(qryExistTable,0,['FIB$FIELDS_INFO'])='0' then
         begin
          if MessageDlg(SCompEditInfoFieldsNotExist, mtConfirmation, [mbOK, mbCancel], 0) <> mrOk
          then Exit;
           AdjustFRepositaryTable(db)
         end
         else
          AdjustFRepositaryTable(db);
         ShowFieldInfo(Component)
        end;
     2:
     begin
         // try to connect
         if not GetPropValue(Component,'Connected',False) then
         begin
          MessageDlg(SCompDatabaseNotConnected, mtConfirmation, [mbOK], 0);
          Exit;
         end;

         if db.QueryValueAsStr(qryExistTable,0,['FIB$ERROR_MESSAGES'])='0' then
         begin
          if MessageDlg(SCompEditErrorTableNotExist, mtConfirmation, [mbOK, mbCancel], 0) <> mrOk
            then Exit;
          CreateErrorRepositoryTable(db);
         end;
         ShowErrorInfo(Component)
     end;
     3:
         begin
         // try to connect
         if not GetPropValue(Component,'Connected',False) then
         begin
          MessageDlg(SCompDatabaseNotConnected, mtConfirmation, [mbOK], 0);
          Exit;
         end;

         if db.QueryValueAsStr(qryExistTable,0,['FIB$DATASETS_INFO'])='0' then
         begin
            if
              MessageDlg(SCompEditInfoTableNotExist, mtConfirmation, [mbOK, mbCancel], 0
              ) <> mrOk
              then Exit;
            CreateDataSetRepositoryTable(db);
         end;
         EditDSInfo(Component);
        end;
     4:
      begin
        Script:=TStringList.Create;
        try
         Connected:=GetPropValue(Component,'Connected',False);
         
         Script.Add('/***************************************');
         Script.Add('        FIBPlus repository tables ');
         Script.Add('***************************************/');
         Script.Add('');

//         if not  Connected or (db.QueryValueAsStr(qryExistDomain,0,['FIB$BOOLEAN'])='0') then
         Script.Add(qryCreateBooleanDomain+';');
//         if not  Connected or (db.QueryValueAsStr(qryGeneratorExist,0,['FIB$FIELD_INFO_VERSION'])='0') then
         Script.Add(qryCreateFieldInfoVersionGen+';');
         Script.Add('');
         Script.Add('/*Fields repository table*/');
         Script.Add('');
         Script.Add(qryCreateTabFieldsRepository+';');
         Script.Add('');
         Script.Add('SET TERM ^;');
         Script.Add(qryCreateFieldRepositoryTriggerBI+' ^');
         Script.Add('');
         Script.Add(qryCreateFieldRepositoryTriggerBU+' ^');
         Script.Add('SET TERM ;^');
         Script.Add('');         
         Script.Add('GRANT SELECT ON TABLE FIB$FIELDS_INFO TO PUBLIC;');
         Script.Add('COMMIT WORKS ;');
         Script.Add('');
         Script.Add('');
         Script.Add('/*Datasets repository table*/');
         Script.Add('');

         Script.Add(qryCreateDataSetsRepository+';');
         Script.Add('');
         Script.Add('SET TERM ^;');
         Script.Add(qryCreateDataSetRepositoryTriggerBI+' ^');
         Script.Add('');
         Script.Add(qryCreateDataSetRepositoryTriggerBU+' ^');
         Script.Add('SET TERM ;^');
         Script.Add('');         
         Script.Add('GRANT SELECT ON TABLE FIB$DATASETS_INFO TO PUBLIC;');
         Script.Add('COMMIT WORKS ;');
         Script.Add('');
         Script.Add('');
         Script.Add('/*Errors repository table*/');
         Script.Add('');
         Script.Add(qryCreateErrorsRepository+';');
         Script.Add('');
         Script.Add('SET TERM ^;');
         Script.Add(qryCreateErrorsRepositoryTriggerBI+' ^');
         Script.Add('');
         Script.Add(qryCreateErrorsRepositoryTriggerBU+' ^');
         Script.Add('SET TERM ;^');         
         Script.Add('');
         Script.Add('GRANT SELECT ON TABLE FIB$ERROR_MESSAGES TO PUBLIC;');
         Script.Add('COMMIT WORKS ;');
         ShowScript('Metadata for repository tables',Component,Script);
        finally
         Script.Free;
        end
      end;

  end;
end;

function TpFIBDatabaseEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0: Result := SCompEditDBEditor;
    1: Result := SCompEditEditFieldInfo;
    2: Result := SCompEditErrorMessages;
    3: Result := SCompEditDataSetInfo;
    4: Result := SRepositoriesScript;
  end;
end;

function TpFIBDatabaseEditor.GetVerbCount: Integer;
begin
    Result := 5
end;

{ TFIBConditionsEditor }

procedure TFIBConditionsEditor.Edit;
var
   Conditions:TObject;
begin
  Conditions:=GetObjectProp(GetComponent(0),'Conditions');
  if Assigned(Conditions) then
    if EditConditions(TStrings(Conditions)) then
      Designer.Modified
end;

function TFIBConditionsEditor.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog] - [paSubProperties];
end;

{ TpFIBTransactionEditor }

procedure TpFIBTransactionEditor.ExecuteVerb(Index: Integer);
begin
 case Index of
  0:  if EditFIBTrParams(Component) then
       Designer.Modified
 end;

end;

function TpFIBTransactionEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0: Result := SCompEditEditTransaction;
  end;
end;

function TpFIBTransactionEditor.GetVerbCount: Integer;
begin
  Result := 1;
end;

{ TpFIBDataSetOptionsEditor }

procedure TpFIBDataSetOptionsEditor.Edit;
var
    pName: string;
    DataSets: array of TDataSet;
    k:integer;
begin
  pName := GetPropInfo^.Name;
  SetLength(DataSets,PropCount);
  for k := 0 to PropCount-1 do
  begin
   DataSets[k]:=GetComponent(k) as TDataSet;
  end;
  if pName = 'Options' then
  begin
   if EditOptions(DataSets, 0) then
    Modified;
  end
  else
   if EditOptions(DataSets, 1) then
    Modified;
end;

function TpFIBDataSetOptionsEditor.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog];
end;

{ TpFIBAutoUpdateOptionsEditor }

procedure TpFIBAutoUpdateOptionsEditor.Edit;
begin
 if  EditAutoUpdateOptions(GetComponent(0) as TDataSet) then
  Modified
end;

function TpFIBAutoUpdateOptionsEditor.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog, paSubProperties];
end;

{ TpFIBStoredProcProperty }

function TpFIBStoredProcProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paValueList, paSortList];
end;

procedure TpFIBStoredProcProperty.GetValues(Proc: TGetStrProc);
var
  StoredProc: TPersistent;
  DB:TObject;
  Qry:TComponent;
  Trans :TComponent;
  iQry:IFIBQuery;
begin
  StoredProc := GetComponent(0) ;
  DB:=GetObjectProp(StoredProc,'Database');
  if not Assigned(DB) then Exit;
  Qry := nil; Trans := nil;
  try
   try
    Trans:= expTransactionClass.Create(nil);
    SetObjectProp(Trans,'DefaultDatabase',DB);

    Qry:= expQueryClass.Create(nil);
    SetPropValue(Qry,'ParamCheck','False');
    SetObjectProp(Qry,'Database',DB);
    SetObjectProp(Qry,'Transaction',Trans);
    AssignStringsToProp(Qry,'SQL','SELECT RDB$PROCEDURE_NAME FROM RDB$PROCEDURES');

    SetPropValue(Trans,'Active','True');


    try
     ObjSupports(Qry,  IFIBQuery,iQry);
     iQry.ExecQuery;

      while not iQry.iEof do
      begin
        Proc(
         Trim(
          VarToStr(iQry.FieldValue('RDB$PROCEDURE_NAME',False))
         )
        );
        iQry.iNext;
      end;
      iQry.Close;
    finally
     SetPropValue(Trans,'Active','False');
    end;
   except
   end 
  finally
    iQry:=nil;
    Qry.Free;
    Trans.Free;
  end;
end;

{ TGeneratorNameEdit }

function TGeneratorNameEdit.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes;
  Result := Result + [paValueList]
end;

type
  THackAutoUpdateOptions= class (TPersistent)
  private
   FOwner     :TComponent;
  end;
  
procedure TGeneratorNameEdit.GetValues(Proc: TGetStrProc);
var
  DB:TObject;
  Dset:TComponent;
  Qry:TComponent;
  Trans :TComponent;
  iQry:IFIBQuery;

begin
  if PropCount > 1 then Exit;
   if not (THackAutoUpdateOptions(GetComponent(0)).FOwner is
     expDatasetClass
   ) then Exit;
  Dset:= THackAutoUpdateOptions(GetComponent(0)).FOwner ;
  DB:= GetObjectProp(Dset,'Database');
  if not Assigned(DB) then Exit;
  Qry := nil; Trans := nil;
  try

    Trans:=   expTransactionClass.Create(nil);
    SetObjectProp(Trans,'DefaultDatabase',DB);

    Qry:=   expQueryClass.Create(nil);
    SetPropValue(Qry,'ParamCheck','False');
    SetObjectProp(Qry,'Database',DB);
    SetObjectProp(Qry,'Transaction',Trans);
    AssignStringsToProp(Qry,'SQL',
     'select RDB$GENERATOR_NAME  from RDB$GENERATORS '+
     'where (RDB$SYSTEM_FLAG is NULL) or (RDB$SYSTEM_FLAG = 0)'+
     ' order by RDB$GENERATOR_NAME'

    );
    SetPropValue(Trans,'Active','True');


    try
     ObjSupports(Qry,  IFIBQuery,iQry);
     iQry.ExecQuery;

      while not iQry.iEof do
      begin
        Proc(
         Trim(
          VarToStr(iQry.FieldValue(0,false))
         )
        );
        iQry.iNext;
      end;
      iQry.Close;
    finally
     SetPropValue(Trans,'Active','False');
    end;
  finally
    iQry:=nil;
    Qry.Free;
    Trans.Free;
  end;

(*{  if not (TAutoUpdateOptions(GetComponent(0)).Owner is TpFIBDataSet) then Exit;
  Dset:= (TAutoUpdateOptions(GetComponent(0)).Owner as TpFIBDataSet);}
  if not Assigned(Dset.Database) then Exit;
  Qry := nil; Trans := nil;
  try
  Trans := TpFIBTransaction.Create(nil);
  Qry := TpFIBQuery.Create(nil);
  Qry.ParamCheck:=false;
  Qry.Database := Dset.Database;
  Trans.DefaultDatabase := Dset.Database;
  Qry.Transaction := Trans;
  Qry.SQL.Text := 'select RDB$GENERATOR_NAME '+
                  'from RDB$GENERATORS '+
  'where (RDB$SYSTEM_FLAG is NULL) or (RDB$SYSTEM_FLAG = 0)'+
                  'order by RDB$GENERATOR_NAME';
  try
   Trans.StartTransaction;
   Qry.ExecQuery;
   lSQLDA := Qry.Current;
     while not Qry.Eof do
     begin
       Proc(Trim(lSQLDA.ByName['RDB$GENERATOR_NAME'].AsString));
       lSQLDA := Qry.Next;
     end;
   Qry.Close;
  finally
   Trans.Commit;
  end;

  finally
    Qry.Free;
    Trans.Free;
  end*)
end;

{ TFIBTrKindEdit }

function TFIBTrKindEdit.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes;
  Result := Result + [paValueList]
end;

procedure TFIBTrKindEdit.GetValues(Proc: TGetStrProc);
var i: integer;
    Keys,v: Variant;
begin
  if PropCount > 1 then Exit;
  Keys := DefAllSubKey(['Software', RegFIBRoot, RegFIBTrKinds]);
  Proc('NoUserKind');
  if VarType(Keys) = varBoolean then Exit;
  for i := VarArrayLowBound(Keys, 1) to VarArrayHighBound(Keys, 1) do
  begin
   v:=DefReadFromRegistry(['Software', RegFIBRoot, RegFIBTrKinds,
    Keys[i]
   ],['Name']);
   if VarType(v) <> varBoolean then
    Proc(v[0,0])
  end;
end;

{ TpFIBTRParamsEditor }

procedure TpFIBTRParamsEditor.Edit;
begin
  if EditFIBTrParams(TComponent(GetComponent(0))) then
      Modified
end;

function TpFIBTRParamsEditor.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog]-[paSubProperties];
end;

function TpFIBTRParamsEditor.GetValue: string;
begin
   Result:='(TTRParams)'
end;

{ TpFIBQueryEditor }

procedure TpFIBQueryEditor.ExecuteVerb(Index: Integer);
begin
  case Index of
    0:
    begin
     if not FindPropInCode(Component,'SQL') then
      if  ShowSQLEdit(Component) then
         Designer.Modified;
     FindPropInCode(Component,'SQL')
    end;
    1: begin
//        TpFIBQuery(Component).CheckValidStatement;
        ShowMessage(SNoErrors);
       end;
  end;


end;

function TpFIBQueryEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0: Result := SEditSQL;
    1: Result := SCheckSQLs;
  end;
end;

function TpFIBQueryEditor.GetVerbCount: Integer;
begin
  Result := 2;
end;

{ TEdParamToFields }

procedure TEdParamToFields.Edit;
var
  P:TObject;
begin
  P:=GetObjectProp(GetComponent(0),'ParamsToFieldsLinks');
  if  Assigned(P) and    
   (THackAutoUpdateOptions(GetComponent(0)).FOwner is TDataSet)
  then
  if ShowEdParamToFields(TDataSet(THackAutoUpdateOptions(GetComponent(0)).FOwner),TStrings(P))
  then
    Designer.Modified
end;

function TEdParamToFields.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog] - [paSubProperties];
end;

function TEdParamToFields.GetValue: string;
var
  P:TObject;
begin
  P:=GetObjectProp(GetComponent(0),'ParamsToFieldsLinks');
  if Assigned(P)   and ((TStrings(P).Count)>0) then
    Result:='(TPARAMS_FIELDS_LINKS)'
  else
   Result:='(TParams_Fields_Links)';

{  if (GetComponent(0) is TAutoUpdateOptions)
   and (TAutoUpdateOptions(GetComponent(0)).ParamsToFieldsLinks.Count>0) then
   Result:='(TPARAMS_FIELDS_LINKS)'
  else
   Result:='(TParams_Fields_Links)'}
end;

{ TKeyFieldNameEdit }

function TKeyFieldNameEdit.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes;
  Result := Result + [paValueList]
end;

procedure TKeyFieldNameEdit.GetValues(Proc: TGetStrProc);
var i: integer;
    Tables: TStrings;
    ds:TDataSet;
    ids:IFIBDataSet;
    Obj:TObject;
    Stringer:IFIBStringer;
    updTableName:string;
    clExp:IFIBClassesExporter;
begin
  if PropCount > 1 then
   Exit;
  ds:=(THackAutoUpdateOptions(GetComponent(0)).FOwner as TDataSet);
  if not ObjSupports(ds,IFIBDataSet,ids) then
   Exit;
  Obj:=GetObjectProp(THackAutoUpdateOptions(GetComponent(0)).FOwner,'Database');
  if not Assigned(Obj) then
//  if not Assigned(TAutoUpdateOptions(GetComponent(0)).FOwner).Database) then
   Exit;

  Tables := TStringList.Create;
  with ds do
  try
   try
    updTableName:=GetPropValue(GetComponent(0), 'UpdateTableName');
    if Trim(updTableName)='' then
    begin
     ShowMessage('Error: UpdateTableName is empty');
     Exit;
    end;
    Supports(FIBClassesExporter,IFIBClassesExporter,clExp);

    Stringer:=clExp.iGetStringer;
    FieldDefs.Update;
    if FieldCount>0 then
      for i := 0 to Pred(FieldCount) do
      begin
        if (Fields[i] is TLargeIntField) or
(Fields[i] is TIntegerField) or ((Fields[i] is TBCDField)and (TBCDField(Fields[i]).Size=0))
        and
          Stringer.EquelStrings(ids.GetRelationTableName(Fields[i]),updTableName,False)
        then
        begin
         Proc(Fields[i].FieldName);
        end;
      end
    else
    begin
{      if not QSelect.Prepared then
       QSelect.Prepare;}
      ids.Prepare; 
      for i := 0 to Pred(FieldDefs.Count) do
      begin
        if (FieldDefs[i].DataType in [ftSmallint, ftInteger]) and
         Stringer.EquelStrings(ids.GetRelationTableName(FieldDefs[i]),UpdTableName,False)
        then
        begin
         Proc(FieldDefs[i].Name);
        end
        else
        if ((FieldDefs[i].DataType =ftBCD) and (FieldDefs[i].Size=0)) and
         Stringer.EquelStrings(ids.GetRelationTableName(FieldDefs[i]),UpdTableName,False)
        then
        begin
         Proc(FieldDefs[i].Name);
        end;
      end;
    end;
   except
   end; 
  finally
    Tables.Free
  end
end;

{ TTableNameEdit }

function TTableNameEdit.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes;
  Result := Result + [paValueList]
end;

procedure TTableNameEdit.GetValues(Proc: TGetStrProc);
var i: integer;
  Tables: TStrings;
  Stringer:IFIBStringer;
  clExp:IFIBClassesExporter;
begin
  if PropCount > 1 then Exit;
  if not (THackAutoUpdateOptions(GetComponent(0)).FOwner is TDataSet) then Exit;
  Tables := TStringList.Create;
  try
    Supports(FIBClassesExporter,IFIBClassesExporter,clExp);
    Stringer:=clExp.iGetStringer;

    Stringer.AllTables(TStrings(GetObjectProp(THackAutoUpdateOptions(GetComponent(0)).FOwner,'SelectSQL')).Text, Tables);
    for i := 0 to Pred(Tables.Count) do Proc(Stringer.ExtractWord(1, Tables[i], [' ']));
  finally
    Tables.Free
  end
end;

//DataSet Editor

procedure ShowDataSetSQLEditor(Component:TComponent;Kind:integer;Designer:IDesigner);
const
    SQLNames:array[0..4] of string =('SelectSQL','InsertSQL','UpdateSQL',
    'DeleteSQL','RefreshSQL'
    );

var
  k:byte;
  ExitToCodeEditor:integer;
begin
   for k:=0 to 4 do
   begin
      SaveModule(Component,SQLNames[k]);
   end;
   if ShowDSSQLEdit(TDataSet(Component),Kind,ExitToCodeEditor) then
   begin
    Designer.Modified;
   end;
   if ExitToCodeEditor>=0 then
   begin
     for k:=0 to 4 do
     begin
      if ExitToCodeEditor<>k then
        if CloseModule(Component,SQLNames[k]) then
         CreatePropInCode(Component,SQLNames[k],
          nil,True
         );
      SaveModule(Component,SQLNames[k]);
     end;
     if ExitToCodeEditor>=0 then
      FindPropInCode(Component,SQLNames[ExitToCodeEditor]);
   end;
end;



type
  PClass = ^TClass;

{$IFDEF VER100}

constructor TFIBGenSQlEd.Create(AComponent: TComponent; ADesigner: TFormDesigner);
{$ELSE}

{$IFNDEF D6+}
constructor TFIBGenSQlEd.Create(AComponent: TComponent; ADesigner: IFormDesigner);
{$ELSE}
 constructor TFIBGenSQlEd.Create(AComponent: TComponent; ADesigner: IDesigner);
{$ENDIF}
{$ENDIF}
var CompClass: TClass;
begin
  inherited Create(AComponent, ADesigner);
  CompClass := PClass(Acomponent)^;
  try
    PClass(AComponent)^ := TDataSet;
    DefaultEditor := GetComponentEditor(AComponent, ADesigner);
  finally
    PClass(AComponent)^ := CompClass;
  end;
end;

destructor TFIBGenSQlEd.Destroy;
begin
{$IFDEF D6+}
//  DefaultEditor._Release;
// DefaultEditor.;
{$ELSE}
  DefaultEditor.Free;
{$ENDIF}
  inherited Destroy
end;


function TFIBGenSQlEd.GetVerbCount: Integer;
begin
  Result := DefaultEditor.GetVerbCount + 4
end;

function TFIBGenSQlEd.GetVerb(Index: Integer): string;
begin
  if Index < DefaultEditor.GetVerbCount then
    Result := DefaultEditor.GetVerb(Index)
  else
    case Index - DefaultEditor.GetVerbCount of
      0: Result := SCompEditSQLGenerator;
      1: Result := SCompSaveToDataSetInfo;
      2: Result := SCompChooseDataSetInfo;
      3: Result := SCheckSQLs;
    end;
end;


procedure TFIBGenSQlEd.ExecuteVerb(Index: Integer);

var SText:string;
    k:integer;
    Reopen:boolean;
    ErrStr:string;
    ids:IFIBDataSet;
    iqry:IFIBQuery;
    idb:IFIBConnect;
    curObj:TObject;
begin
  if   ObjSupports(Component,IFIBDataSet,ids) then
  if Index < DefaultEditor.GetVerbCount then
  with TDataSet(Component) do
  begin
   try
    Reopen:=Active;
    Close;
{    QSelect.FreeHandle;
    if Database<>nil then
     ListTableInfo.ClearForDataBase(Database);}
    ids.Prepare;
    if Reopen then Open;
   except
   end;
   DefaultEditor.ExecuteVerb(Index);
  end
  else
  begin

   SText:=TStrings(GetObjectProp(Component,'SelectSQL')).Text;
   case Index - DefaultEditor.GetVerbCount of
      0: ShowDataSetSQLEditor(Component,0,Designer);
      1: SaveDataSetInfo;
      2:
      begin
        // try to connect
(*        if (not Assigned(TpFibDataSet(Component).DataBase)) or
           (not TpFibDataSet(Component).DataBase.Connected) then
*)
        curObj:=GetObjectProp(Component,'Database');
        if not Assigned(curObj) or
           not GetPropValue(CurObj,'Connected') then
        begin
            MessageDlg(SCompDatabaseNotConnected, mtConfirmation, [mbOK], 0);
            Exit;
        end;

        ObjSupports(curObj,IFIBConnect,idb);
        if idb.QueryValueAsStr(qryExistTable,0,['FIB$DATASETS_INFO'])='0' then
        begin
                    if
              MessageDlg(SCompEditInfoTableNotExist, mtConfirmation, [mbOK, mbCancel], 0
              ) <> mrOk
              then Exit;
            CreateDataSetRepositoryTable(idb);
        end;
        k := GetPropValue(Component,'DataSet_ID',False);
        ChooseDSInfo(TDataSet(Component));
        if k <> GetPropValue(Component,'DataSet_ID',False) then
          Designer.Modified
      end;
      3:
       with TDataSet(Component) do
       begin
         ErrStr:=SErrorIn;
         curObj:=FindComponent('SelectQuery');
         if ObjSupports(curObj,IFIBQuery,iqry) then
         if TStrings(GetObjectProp(Component,'SelectSQL')).Count>0 then
         try
          iqry.CheckValidStatement;
         except
          ErrStr:=ErrStr+'SelectSQL'#13#10;
         end;
         curObj:=FindComponent('UpdateQuery');         
         if ObjSupports(curObj,IFIBQuery,iqry) then
         if TStrings(GetObjectProp(Component,'UpdateSQL')).Count>0 then
         try
          iqry.CheckValidStatement;
         except
          ErrStr:=ErrStr+'UpdateSQL'#13#10;
         end;
         curObj:=FindComponent('DeleteQuery');
         if ObjSupports(curObj,IFIBQuery,iqry) then
         if TStrings(GetObjectProp(Component,'DeleteSQL')).Count>0 then
         try
          iqry.CheckValidStatement;
         except
          ErrStr:=ErrStr+'DeleteSQL'#13#10;
         end;
         curObj:=FindComponent('InsertQuery');
         if ObjSupports(curObj,IFIBQuery,iqry) then
         if TStrings(GetObjectProp(Component,'InsertSQL')).Count>0 then
         try
          iqry.CheckValidStatement;
         except
          ErrStr:=ErrStr+'InsertSQL'#13#10;
         end;
         curObj:=FindComponent('RefreshQuery');
         if ObjSupports(curObj,IFIBQuery,iqry) then
         if TStrings(GetObjectProp(Component,'RefreshSQL')).Count>0 then
         try
          iqry.CheckValidStatement;
         except
          ErrStr:=ErrStr+'RefreshSQL'#13#10;
         end;
         if ErrStr<>SErrorIn then
          ShowMessage(ErrStr)
         else
          ShowMessage(SNoErrors)
       end;
   end;
   if SText<>TStrings(GetObjectProp(Component,'SelectSQL')).Text then
    Designer.Modified;
  end;
end;

const
   ExchangeDelimeter='#$#$';

type THackCondition=class
     private
      FOwner:TObject;
      FEnabled:boolean;
     end;

function GetConditionsExchangeStr(Conditions:TStrings):string;
var
   i:integer;
begin
   Result:='';
   with Conditions do
   for i:=0 to Pred(Count) do
    Result:=Result+
      Names[i]+ExchangeDelimeter+Values[Names[i]]+ExchangeDelimeter+IntToStr(Ord(THackCondition(Objects[i]).FEnabled))+#13#10

end;   

procedure     SaveFIBDataSetInfo(Database,DataSet:TObject;DS_ID:integer);
var
   iDB:IFIBConnect;
begin
 if ObjSupports(Database,IFIBConnect,iDB) then
 begin
  if idb.QueryValueAsStr('SELECT Count(*) FROM FIB$DATASETS_INFO WHERE DS_ID=:DS_ID',0,[DS_ID])='0' then
    idb.Execute('INSERT INTO FIB$DATASETS_INFO (DS_ID,UPDATE_ONLY_MODIFIED_FIELDS) VALUES('+
     IntToStr(DS_ID)+',1)'
    );
   idb.Execute(
    'Update FIB$DATASETS_INFO SET '#13#10+
    'SELECT_SQL='''+TStrings(GetObjectProp(DataSet,'SelectSQL')).Text+''','#13#10+
    'INSERT_SQL='''+TStrings(GetObjectProp(DataSet,'InsertSQL')).Text+''','#13#10+    
    'UPDATE_SQL='''+TStrings(GetObjectProp(DataSet,'UpdateSQL')).Text+''','#13#10+
    'DELETE_SQL='''+TStrings(GetObjectProp(DataSet,'DeleteSQL')).Text+''','#13#10+
    'REFRESH_SQL='''+TStrings(GetObjectProp(DataSet,'RefreshSQL')).Text+''','#13#10+
    'KEY_FIELD='''+GetPropStringValue(Dataset,'AutoUpdateOptions.KeyFields')+''','#13#10+
    'NAME_GENERATOR='''+GetPropStringValue(Dataset,'AutoUpdateOptions.GeneratorName')+''','#13#10+
    'DESCRIPTION='''+GetPropStringValue(Dataset,'Description')+''','#13#10+
    'UPDATE_TABLE_NAME='''+GetPropStringValue(Dataset,'AutoUpdateOptions.UpdateTableName')+''','#13#10+
    'UPDATE_ONLY_MODIFIED_FIELDS='''+IntToStr(GetSubPropValue(Dataset,'AutoUpdateOptions.UpdateOnlyModifiedFields'))+''','#13#10+
    'CONDITIONS='''+GetConditionsExchangeStr(TStrings(GetObjectProp(DataSet,'Conditions')))+''''#13#10+

    'WHERE DS_ID='+IntToStr(DS_ID)
   )
 end
end;
 
procedure TFIBGenSQlEd.SaveDataSetInfo;
var
  vDescription:string;
  DS_ID:integer;
  DB:TObject;
  idb:IFIBConnect;
begin
  DS_ID:=GetPropValue(Component,'DataSet_ID',False);
  with Component do
  if  DS_ID=0 then
   ShowMessage(Name + SCompEditDataSet_ID)
  else
  begin
   DB:=GetObjectProp(Component,'Database');
   if DB=nil then
     ShowMessage(SDataBaseNotAssigned)
   else
   begin
    ObjSupports(DB,IFIBConnect,idb);
    if idb.QueryValueAsStr(qryExistTable,0,['FIB$DATASETS_INFO'])='0' then
    begin
          if
            MessageDlg(SCompEditInfoTableNotExist, mtConfirmation, [mbOK, mbCancel], 0
            ) <> mrOk
            then Exit;
         CreateDataSetRepositoryTable(idb);
    end;
    vDescription:=GetPropValue(Component,'Description');
{    if not InputQuery(SCompEditSaveDataSetProperty, SCompEditDataSetDesc, vDescription) then
     Exit;
//    SetPropValue(Component,'Description',vDescription);}
    SaveFIBDataSetInfo(DB,Component,DS_ID);
   end
  end;
end;


{ TDataSet_ID_Edit }

procedure TDataSet_ID_Edit.Edit;
var
  OldID: integer;
  DB:TObject;
  iDB:iFIBConnect;
begin
  OldID := GetPropValue( GetComponent(0),'DataSet_ID',False);
  DB:=  GetObjectProp(GetComponent(0),'Database');
  if DB=nil  then
   Exit
  else
  if ObjSupports(DB,iFIBConnect,iDB) then
  begin
    if iDB.QueryValueAsStr(qryExistTable,0,['FIB$DATASETS_INFO'])='0' then
    begin
//     if not (urDataSetInfo in DataBase.UseRepositories) then
      if not GetValueInSet(DB,'UseRepositories','urDataSetInfo') then
       raise Exception.Create(SCompEditDataSetInfoForbid);
      if
        MessageDlg(SCompEditInfoTableNotExist, mtConfirmation, [mbOK, mbCancel], 0
        ) <> mrOk
      then
        Exit;
      CreateDataSetRepositoryTable(iDB);
    end;

    ChooseDSInfo(TDataSet(GetComponent(0)));
    if OldID <> GetPropValue( GetComponent(0),'DataSet_ID',False) then
      Modified
  end
end;

function TDataSet_ID_Edit.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog];
end;

{ TFIBSQLsProperties }

function TFIBSQLsProperties.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog,paSubProperties];
end;

function TFIBSQLsProperties.GetValue: string;
begin
 Result := '(SQLs)'
end;

procedure TFIBSQLsProperties.Edit;
begin
  ShowDataSetSQLEditor(TComponent(GetComponent(0)),0,Designer);
end;

{ TFIBSQLsProperty }

type THackSQls=class(TPersistent)
     private
      FOwner     :TComponent;

     end;

procedure TFIBSQLsProperty.Edit;
var  pName:string;
     KindSQL:integer;
begin
   pName:=GetPropInfo^.Name;
   if pName='SelectSQL' then
     KindSQL:=0
   else
   if pName='UpdateSQL' then
     KindSQL:=2
   else
   if pName='InsertSQL' then
     KindSQL:=1
   else
   if pName='DeleteSQL' then
     KindSQL:=3
   else
     KindSQL:=4;
   if not FindPropInCode(THackSQls(GetComponent(0)).FOwner,pName) then
    ShowDataSetSQLEditor(THackSQls(GetComponent(0)).FOwner,KindSQL,Designer);
end;


function TFIBSQLsProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog] - [paSubProperties];
end;

function TFIBSQLsProperty.GetValue: string;
begin
  Result := SCompEditSQLText;
end;



{ TpFIBSQLPropEdit }

procedure TpFIBSQLPropEdit.Edit;
begin
//   if GetComponent(0) is TpFIBQuery then
   begin
    if not FindPropInCode(TComponent(GetComponent(0)),'SQL') then
     if  ShowSQLEdit(TComponent(GetComponent(0))) then
         Modified;
    FindPropInCode(TComponent(GetComponent(0)),'SQL'); 
   end;
end;

function TpFIBSQLPropEdit.GetAttributes: TPropertyAttributes;
begin
 Result := inherited GetAttributes + [paDialog] - [paSubProperties];
end;

{ TTableNameEditDR }

function TTableNameEditDR.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes;
  Result := Result + [paValueList]
end;

const
  QRYTables =
    'SELECT REL.RDB$RELATION_NAME FROM RDB$RELATIONS REL WHERE ' +
    '(REL.RDB$SYSTEM_FLAG <> 1 OR REL.RDB$SYSTEM_FLAG IS NULL) AND ' +
    '(NOT REL.RDB$FLAGS IS NULL) AND ' +
    '(REL.RDB$VIEW_BLR IS NULL) AND ' +
    '(REL.RDB$SECURITY_CLASS STARTING WITH ''SQL$'') ' +
    'ORDER BY REL.RDB$RELATION_NAME';

procedure TTableNameEditDR.GetValues(Proc: TGetStrProc);
var
  edComponent:TPersistent;
  DB:TObject;
  Qry:TComponent;
  Trans :TObject;
  iQry:IFIBQuery;
  trActive:boolean;
begin
  edComponent:= GetComponent(0) ;
  Trans:=GetObjectProp(edComponent,'Transaction');
  if not Assigned(Trans) then Exit;
  trActive:=GetPropValue(Trans,'Active');
  if not trActive then
   SetPropValue(Trans,'Active',True);
  DB:=GetObjectProp(Trans,'DefaultDatabase');
  Qry:= expQueryClass.Create(nil);
  SetPropValue(Qry,'ParamCheck','False');
  SetObjectProp(Qry,'Database',DB);
  SetObjectProp(Qry,'Transaction',Trans);
  AssignStringsToProp(Qry,'SQL',QRYTables);
  try
   try
    try
     ObjSupports(Qry,  IFIBQuery,iQry);
     iQry.ExecQuery;

      while not iQry.iEof do
      begin
        Proc(
         Trim(
          VarToStr(iQry.FieldValue('RDB$RELATION_NAME',False))
         )
        );
        iQry.iNext;
      end;
      iQry.Close;
    finally
     SetPropValue(Trans,'Active','False');
    end;
   except
   end
  finally
   if not trActive then
    SetPropValue(Trans,'Active',False);
   iQry:=nil;
   Qry.Free;
  end;

end;

{ TpFIBDeltaReceiverEditor }

procedure TpFIBDeltaReceiverEditor.ExecuteVerb(Index: Integer);
var
  TableName:string;
  DelTableName,TriggerName:string;
  DB:TObject;
  Qry:TComponent;
  Trans :TObject;
  iQry:IFIBQuery;
  iTrans:IFIBTransaction;
  trActive:boolean;
  ErrMessage:string;
  Script:TStrings;
  Stringer:IFIBStringer;
  clExp:IFIBClassesExporter;  
procedure ExecStatement(const SQL:string);
begin
   AssignStringsToProp(Qry,'SQL',SQL);
   try
     iQry.ExecQuery;
   except
    on E:Exception do
     ErrMessage:=ErrMessage+#13#10+E.Message
   end;
end;

begin
  Trans:=GetObjectProp(Component,'Transaction');
  if not Assigned(Trans) then
  begin
    ShowMessage(SCompEditDeltaReceiverErr2);
    Exit;
  end;

  DB:=GetObjectProp(Trans,'DefaultDatabase');
{  trActive:=GetPropValue(Trans,'Active');
  if not trActive then
   SetPropValue(Trans,'Active',True);
  DB:=GetObjectProp(Trans,'DefaultDatabase');
  Qry:= expQueryClass.Create(nil);
  SetPropValue(Qry,'ParamCheck','False');
  SetObjectProp(Qry,'Database',DB);
  SetObjectProp(Qry,'Transaction',Trans);
  ObjSupports(Qry,  IFIBQuery,iQry);

  ErrMessage:='';}
  Script:=TStringList.Create;
  try
    case Index of
     0:
     begin
       Script.Add('/***************************************');
       Script.Add('Common metadata for TableChangesReader supports');
       if Assigned(DB) then
        Script.Add('Database: '+GetPropStringValue(DB,'DBName'));
       Script.Add('***************************************/');
      Script.Add('');
      Script.Add('CREATE DOMAIN FIB$BIGINT AS BIGINT;');
      Script.Add('CREATE DOMAIN FIB$TIMESTAMP AS TIMESTAMP;');
      Script.Add('CREATE GENERATOR FIB$GEN_COMMIT_NO;');
      Script.Add('CREATE GENERATOR FIB$GEN_TRANSACTION_ID;');
//
      Script.Add('');
      Script.Add('CREATE TABLE FIB$TRANSACTIONS(');
      Script.Add(' TRANSACTION_ID FIB$BIGINT,');
      Script.Add(' COMMIT_NO   FIB$BIGINT ,');
      Script.Add(' COMMIT_TIME    FIB$TIMESTAMP');
      Script.Add(');');
      Script.Add('');
      Script.Add('CREATE  DESCENDING INDEX IDX_FIB$COMMIT_NO ON FIB$TRANSACTIONS (COMMIT_NO);');
      Script.Add('');


      Script.Add('SET TERM ^ ;');
      Script.Add('');
      Script.Add('CREATE PROCEDURE FIB$CLEAR_TRANSACTION_ID ');
      Script.Add('AS BEGIN ');
      Script.Add(' rdb$set_context(''USER_TRANSACTION'',''FIB$TRANSACTION_ID'',NULL);');
      Script.Add('END ^');
      Script.Add('');

      Script.Add('CREATE PROCEDURE FIB$GET_TRANSACTION_ID ( FORCE   SMALLINT )');
      Script.Add('RETURNS ( TRANS_ID   BIGINT) ');
      Script.Add('AS');
      Script.Add('BEGIN ');
      Script.Add(' TRANS_ID=rdb$get_context(''USER_TRANSACTION'',''FIB$TRANSACTION_ID'');');
      Script.Add(' if ((TRANS_ID is NULL) AND (FORCE=1)) then');
      Script.Add(' begin');
      Script.Add('  TRANS_ID=GEN_ID(FIB$GEN_TRANSACTION_ID,1);');
      Script.Add('  rdb$set_context(''USER_TRANSACTION'',''FIB$TRANSACTION_ID'',:TRANS_ID);');
      Script.Add(' end');
      Script.Add(' suspend;');
      Script.Add('END ^');

      Script.Add('');

      Script.Add('CREATE TRIGGER FIB$ON_TRANSACTION_ROLLBACK ');
      Script.Add('ACTIVE ON  TRANSACTION ROLLBACK  POSITION 0');
      Script.Add('AS ');
      Script.Add('BEGIN');
      Script.Add(' EXECUTE PROCEDURE FIB$CLEAR_TRANSACTION_ID;');
      Script.Add('END ^');

      Script.Add('');
      Script.Add('CREATE TRIGGER FIB$ON_TRANSACTION_COMMIT');
      Script.Add('ACTIVE ON  TRANSACTION COMMIT  POSITION 0');
      Script.Add('AS ');
      Script.Add(' DECLARE TRANS_ID BIGINT;');
      Script.Add(' DECLARE COMMIT_NO BIGINT;');
      Script.Add('BEGIN');
      Script.Add('   Select TRANS_ID From FIB$GET_TRANSACTION_ID(0) INTO :TRANS_ID;');
      Script.Add('   if  (NOT TRANS_ID is NULL) then');
      Script.Add('   begin');
      Script.Add('    COMMIT_NO=GEN_ID(FIB$GEN_COMMIT_NO,1);');
      Script.Add('    insert into FIB$TRANSACTIONS (TRANSACTION_ID,COMMIT_NO,COMMIT_TIME)');
      Script.Add('    values(:TRANS_ID,:COMMIT_NO,''NOW'');');
      Script.Add('    EXECUTE PROCEDURE FIB$CLEAR_TRANSACTION_ID;');
      Script.Add('   end');
      Script.Add('END ^');


      Script.Add('');
      Script.Add('COMMIT WORKS ^');

      ShowScript('Common metadata for DeltaReceiver supports',DB,Script);

     end;
     1:
     begin
       TableName:=GetPropStringValue(Component,'TableName');
       if Length(TableName)= 0 then
         ShowMessage(SCompEditDeltaReceiverErr1);

       Script.Add('/***************************************');
       Script.Add('Common metadata for TableChangesReader supports');
       if Assigned(DB) then
        Script.Add('Database: '+GetPropStringValue(DB,'DBName'));
       Script.Add('***************************************/');
      Script.Add('');
      Supports(FIBClassesExporter,IFIBClassesExporter,clExp);
      Stringer:=clExp.iGetStringer;

      DelTableName:=Stringer.FormatIdentifier(3,TableName+'_DELETED');
      TriggerName:=Stringer.FormatIdentifier(3, 'FIB$TRANSLOG_'+TableName);
      TableName:=Stringer.FormatIdentifier(3,TableName);
      Script.Add('ALTER TABLE '+TableName+' ADD FIB$TRANSACTION_ID FIB$BIGINT;');
      Script.Add('ALTER TABLE '+TableName+' ADD FIB$UPDATE_TIME FIB$TIMESTAMP;');
      Script.Add('');
      Script.Add('CREATE TABLE  '+DelTableName+'(');
      Script.Add(' ID                 FIB$BIGINT NOT NULL,');
      Script.Add(' FIB$TRANSACTION_ID FIB$BIGINT,');
      Script.Add(' FIB$DELETED_TIME   FIB$TIMESTAMP');
      Script.Add(' );');
      Script.Add('');
      Script.Add('SET TERM ^ ;');
      Script.Add('');

      Script.Add('CREATE TRIGGER '+TriggerName+' FOR '+TableName);
      Script.Add('ACTIVE BEFORE INSERT OR UPDATE OR DELETE POSITION 0');
      Script.Add('AS');
      Script.Add(' DECLARE VARIABLE TRANS_ID BIGINT;');
      Script.Add('BEGIN');
      Script.Add('  Select TRANS_ID From FIB$GET_TRANSACTION_ID(1) INTO :TRANS_ID;');
      Script.Add('  if (DELETING) then');
      Script.Add('   Insert into '+DelTableName+'(ID,FIB$TRANSACTION_ID,FIB$DELETED_TIME)');
      Script.Add('    values (Old.ID,:TRANS_ID,''NOW'');');
      Script.Add('  else');
      Script.Add('  begin');
      Script.Add('   new.FIB$TRANSACTION_ID=:TRANS_ID;');
      Script.Add('   new.FIB$UPDATE_TIME   =''NOW'';');
      Script.Add('  end');
      Script.Add('END ^');

      Script.Add('');
      Script.Add('COMMIT WORKS ^');

      ShowScript(' Metadata for DeltaReceiver supports',DB,Script);      
     end;
    end;
  finally
   Script.Free;
   if not trActive then
    SetPropValue(Trans,'Active',False);
   iQry:=nil;
   Qry.Free;
  end
end;

function TpFIBDeltaReceiverEditor.GetVerb(Index: Integer): string;
var
 TableName:string;
begin
  case Index of
    0: Result := SCompEditDeltaReceiver1;
    1:
    begin
     TableName:=GetPropStringValue(Component,'TableName');
     Result := Format(SCompEditDeltaReceiver2,[TableName]);
    end
  end;
end;

function TpFIBDeltaReceiverEditor.GetVerbCount: Integer;
begin
 Result:=2;
end;

{ TpFIBGeneratorsProperty }

type
 TPersistentCracker = class(TPersistent);
 
procedure TpFIBGeneratorsProperty.Edit;
var
  Obj: TPersistent;
begin
  Obj := GetComponent(0);
  while (Obj <> nil) and not (Obj is TComponent) do
    Obj := TPersistentCracker(Obj).GetOwner;
  ShowCollectionEditorClass(Designer, TCollectionEditor, TComponent(Obj),
    TCollection(GetOrdValue), 'GeneratorList', [coAdd, coDelete, coMove]);
end;

function TpFIBGeneratorsProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog, paReadOnly ];
end;

function TpFIBGeneratorsProperty.GetValue: string;
begin
//  FmtStr(Result, '(%s)', [GetPropType^.Name]);
  Result:='TGeneratorList'
end;

end.


