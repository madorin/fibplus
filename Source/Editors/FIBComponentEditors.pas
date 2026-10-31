unit FIBComponentEditors;

interface

{$I ..\FIB.inc}

uses
  Classes, SysUtils,
{$IFDEF C23}
  Vcl.Forms, Vcl.Controls, DB, Vcl.Dialogs,
{$ELSE}
  Forms, Controls, DB, Dialogs,
{$ENDIF}
  ToCodeEditor, TypInfo, ColnEdit,
  DesignEditors, DesignIntf, Variants;

type
  TFIBAliasEdit = class(TStringProperty)
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

  TFIBFileNameProperty = class(TStringProperty)
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
  end;

  TFIBDatabaseEditor = class(TComponentEditor)
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
  end;

  TFIBTransactionEditor = class(TComponentEditor)
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
  end;

  TFIBDeltaReceiverEditor = class(TComponentEditor)
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
  end;

  TFIBConditionsEditor = class(TClassProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure Edit; override;
  end;

  TFIBDataSetOptionsEditor = class(TSetProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure Edit; override;
  end;

  TFIBAutoUpdateOptionsEditor = class(TClassProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure Edit; override;
  end;

  TFIBParamsToFieldsProperty = class(TClassProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    procedure Edit; override;
  end;

  TFIBKeyFieldsProperty = class(TStringProperty)
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

  TFIBStoredProcProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

  TFIBGeneratorNameProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

  TFIBUpdateTableNameProperty = class(TStringProperty)
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

  TFIBDeltaReceiverTableNameProperty = class(TStringProperty)
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

  TFIBTrKindEdit = class(TStringProperty)
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

  TFIBTransactionParamsEditor = class(TClassProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    procedure Edit; override;
  end;

  TFIBQueryEditor = class(TComponentEditor)
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
  end;

  TFIBDataSetIDProperty = class(TIntegerProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
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

  TFIBDataSetEditor = class(TComponentEditor)
    DefaultEditor: IComponentEditor;
  public
    constructor Create(AComponent: TComponent; ADesigner: IDesigner); override;
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
    procedure SaveDataSetInfo;
  end;

  TFIBSQLPropEdit = class(TClassProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure Edit; override;
  end;

  TFIBGeneratorsProperty = class(TPropertyEditor { TClassProperty } )
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    procedure Edit; override;
  end;

implementation

uses
  RegUtils, FIBProps, FIBEditorsConsts, FIBDBEdit, FIBInterfaces, FIBRepositoryOperations, EdFieldInfo, EdErrorInfo,
  FIBConditionsEdit, EdDataSetInfo, FIBTrEdit, FIBDataSetOptions,
  FIBAutoUpdEditor, RegFIBEditors, RTTIRoutines, FIBSQLEditor,
  EdParamToFields, FIBDataSQLEditor, uFIBScriptForm;

{ TFIBAliasEdit }

type
  IFIBClassesExporter = interface
    ['{AFC7CF1A-EAA5-4584-B47D-BDAD337B4EEC}']
    function iGetStringer: IFIBStringer;
    function iGetMetaExtractor: IFIBMetaDataExtractor;
  end;

function TFIBAliasEdit.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes;
  Result := Result + [paValueList]
end;

procedure TFIBAliasEdit.GetValues(Proc: TGetStrProc);
var
  i: Integer;
  Keys: Variant;
begin
{$IFNDEF NO_REGISTRY}
  if PropCount > 1 then
    Exit;
  Keys := DefAllSubKey(['Software', RegFIBRoot, 'Aliases']);
  if VarType(Keys) = varBoolean then
    Exit;
  for i := VarArrayLowBound(Keys, 1) to VarArrayHighBound(Keys, 1) do
    Proc(Keys[i])
{$ENDIF}
end;

{ TFIBFileNameProperty }

procedure TFIBFileNameProperty.Edit;
var
  FileOpen: TOpenDialog;
  pName: string;
  pValue: string;

begin
  pName := GetName;
  pValue := GetValue;
  FileOpen := TOpenDialog.Create(Application);
  try
    with FileOpen do
    begin
      if Trim(pValue) <> '' then
        FileOpen.InitialDir := ExtractFilePath(pValue);
      if pName = 'DBName' then
        Filter := 'IB base files|*.gdb|IB7 base files|*.ib|Firebird base files|*.fdb|All files|*.*'
      else if pName = 'CacheFileName' then
        Filter := 'INI|*.ini|All files|*.*'
      else
        Filter := 'DLL|*.dll|All files|*.*';

      if FileExists(pValue) then
        FileName := pValue;
      if Execute then
        SetValue(FileName);
    end;
  finally
    FileOpen.free;
  end;
end;

function TFIBFileNameProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog, paRevertable];
end;

{ TFIBDatabaseEditor }

procedure TFIBDatabaseEditor.ExecuteVerb(Index: Integer);
var
  DB: IFIBConnect;
  Script: TStrings;
begin
  if ObjSupports(Component, IFIBConnect, DB) then
    case Index of
      0:
        if EditFIBDatabase(Component) then
          Designer.Modified;
      1:
        begin
          // try to connect
          if not GetPropValue(Component, 'Connected', False) then
          begin
            MessageDlg(SCompDatabaseNotConnected, mtConfirmation, [mbOK], 0);
            Exit;
          end;
          if DB.QueryValueAsStr(qryExistTable, 0, ['FIB$FIELDS_INFO']) = '0' then
          begin
            if MessageDlg(SCompEditInfoFieldsNotExist, mtConfirmation, [mbOK, mbCancel], 0) <> mrOk then
              Exit;
            AdjustFieldsRepositoryTable(DB)
          end
          else
            AdjustFieldsRepositoryTable(DB);
          ShowFieldInfo(Component)
        end;
      2:
        begin
          // try to connect
          if not GetPropValue(Component, 'Connected', False) then
          begin
            MessageDlg(SCompDatabaseNotConnected, mtConfirmation, [mbOK], 0);
            Exit;
          end;

          if DB.QueryValueAsStr(qryExistTable, 0, ['FIB$ERROR_MESSAGES']) = '0' then
          begin
            if MessageDlg(SCompEditErrorTableNotExist, mtConfirmation, [mbOK, mbCancel], 0) <> mrOk then
              Exit;
            CreateErrorRepositoryTable(DB);
          end;
          ShowErrorInfo(Component)
        end;
      3:
        begin
          // try to connect
          if not GetPropValue(Component, 'Connected', False) then
          begin
            MessageDlg(SCompDatabaseNotConnected, mtConfirmation, [mbOK], 0);
            Exit;
          end;

          if DB.QueryValueAsStr(qryExistTable, 0, ['FIB$DATASETS_INFO']) = '0' then
          begin
            if MessageDlg(SCompEditInfoTableNotExist, mtConfirmation, [mbOK, mbCancel], 0) <> mrOk then
              Exit;
            CreateDataSetRepositoryTable(DB);
          end;
          EditDSInfo(Component);
        end;
      4:
        begin
          Script := TStringList.Create;
          try
            Script.Add('/***************************************');
            Script.Add('        FIBPlus repository tables ');
            Script.Add('***************************************/');
            Script.Add('');

            Script.Add(qryCreateBooleanDomain + ';');
            Script.Add(qryCreateFieldInfoVersionGen + ';');
            Script.Add('');
            Script.Add('/*Fields repository table*/');
            Script.Add('');
            if GetPropValue(Component, 'Connected', False) then
              Script.Add(Format(qryCreateTabFieldsRepository, [RepositoryNameLength(DB)]) + ';')
            else
              Script.Add(Format(qryCreateTabFieldsRepository, [31]) + ';');
            Script.Add('');
            Script.Add('SET TERM ^;');
            Script.Add(qryCreateFieldRepositoryTriggerBI + ' ^');
            Script.Add('');
            Script.Add(qryCreateFieldRepositoryTriggerBU + ' ^');
            Script.Add('SET TERM ;^');
            Script.Add('');
            Script.Add('GRANT SELECT ON TABLE FIB$FIELDS_INFO TO PUBLIC;');
            Script.Add('COMMIT WORKS ;');
            Script.Add('');
            Script.Add('');
            Script.Add('/*Datasets repository table*/');
            Script.Add('');

            Script.Add(qryCreateDataSetsRepository + ';');
            Script.Add('');
            Script.Add('SET TERM ^;');
            Script.Add(qryCreateDataSetRepositoryTriggerBI + ' ^');
            Script.Add('');
            Script.Add(qryCreateDataSetRepositoryTriggerBU + ' ^');
            Script.Add('SET TERM ;^');
            Script.Add('');
            Script.Add('GRANT SELECT ON TABLE FIB$DATASETS_INFO TO PUBLIC;');
            Script.Add('COMMIT WORKS ;');
            Script.Add('');
            Script.Add('');
            Script.Add('/*Errors repository table*/');
            Script.Add('');
            Script.Add(qryCreateErrorsRepository + ';');
            Script.Add('');
            Script.Add('SET TERM ^;');
            Script.Add(qryCreateErrorsRepositoryTriggerBI + ' ^');
            Script.Add('');
            Script.Add(qryCreateErrorsRepositoryTriggerBU + ' ^');
            Script.Add('SET TERM ;^');
            Script.Add('');
            Script.Add('GRANT SELECT ON TABLE FIB$ERROR_MESSAGES TO PUBLIC;');
            Script.Add('COMMIT WORKS ;');
            ShowScript('Metadata for repository tables', Component, Script);
          finally
            Script.free;
          end
        end;

    end;
end;

function TFIBDatabaseEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0: Result := SCompEditDBEditor;
    1: Result := SCompEditEditFieldInfo;
    2: Result := SCompEditErrorMessages;
    3: Result := SCompEditDataSetInfo;
    4: Result := SRepositoriesScript;
  end;
end;

function TFIBDatabaseEditor.GetVerbCount: Integer;
begin
  Result := 5
end;

{ TFIBConditionsEditor }

procedure TFIBConditionsEditor.Edit;
var
  Conditions: TObject;
begin
  Conditions := GetObjectProp(GetComponent(0), 'Conditions');
  if Assigned(Conditions) then
    if EditConditions(TStrings(Conditions)) then
      Designer.Modified
end;

function TFIBConditionsEditor.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog] - [paSubProperties];
end;

{ TFIBTransactionEditor }

procedure TFIBTransactionEditor.ExecuteVerb(Index: Integer);
begin
  case Index of
    0:
      if EditFIBTrParams(Component) then
        Designer.Modified
  end;

end;

function TFIBTransactionEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0: Result := SCompEditEditTransaction;
  end;
end;

function TFIBTransactionEditor.GetVerbCount: Integer;
begin
  Result := 1;
end;

{ TFIBDataSetOptionsEditor }

procedure TFIBDataSetOptionsEditor.Edit;
var
  pName: string;
  DataSets: array of TDataSet;
  k: Integer;
begin
  pName := GetName;
  SetLength(DataSets, PropCount);
  for k := 0 to PropCount - 1 do
  begin
    DataSets[k] := GetComponent(k) as TDataSet;
  end;
  if pName = 'Options' then
  begin
    if EditOptions(DataSets, 0) then
      Modified;
  end
  else if EditOptions(DataSets, 1) then
    Modified;
end;

function TFIBDataSetOptionsEditor.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog];
end;

{ TFIBAutoUpdateOptionsEditor }

procedure TFIBAutoUpdateOptionsEditor.Edit;
begin
  if EditAutoUpdateOptions(GetComponent(0) as TDataSet) then
    Modified
end;

function TFIBAutoUpdateOptionsEditor.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog, paSubProperties];
end;

{ TFIBStoredProcProperty }

function TFIBStoredProcProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paValueList, paSortList];
end;

procedure TFIBStoredProcProperty.GetValues(Proc: TGetStrProc);
var
  StoredProc: TPersistent;
  DB: TObject;
  Qry: TComponent;
  Trans: TComponent;
  iQry: IFIBQuery;
begin
  StoredProc := GetComponent(0);
  DB := GetObjectProp(StoredProc, 'Database');
  if not Assigned(DB) then
    Exit;
  Qry := nil;
  Trans := nil;
  try
    try
      Trans := expTransactionClass.Create(nil);
      SetObjectProp(Trans, 'DefaultDatabase', DB);

      Qry := expQueryClass.Create(nil);
      SetPropValue(Qry, 'ParamCheck', 'False');
      SetObjectProp(Qry, 'Database', DB);
      SetObjectProp(Qry, 'Transaction', Trans);
      AssignStringsToProp(Qry, 'SQL', 'SELECT RDB$PROCEDURE_NAME FROM RDB$PROCEDURES');

      SetPropValue(Trans, 'Active', 'True');

      try
        ObjSupports(Qry, IFIBQuery, iQry);
        iQry.ExecQuery;

        while not iQry.iEof do
        begin
          Proc(Trim(VarToStr(iQry.FieldValue('RDB$PROCEDURE_NAME', False))));
          iQry.iNext;
        end;
        iQry.Close;
      finally
        SetPropValue(Trans, 'Active', 'False');
      end;
    except
    end
  finally
    iQry := nil;
    Qry.free;
    Trans.free;
  end;
end;

{ TFIBGeneratorNameProperty }

function TFIBGeneratorNameProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes;
  Result := Result + [paValueList]
end;

procedure TFIBGeneratorNameProperty.GetValues(Proc: TGetStrProc);
var
  DB: TObject;
  Dset: TComponent;
  Qry: TComponent;
  Trans: TComponent;
  iQry: IFIBQuery;

begin
  if PropCount > 1 then
    Exit;
  if not(TFIBAutoUpdateOptions(GetComponent(0)).Owner is expDatasetClass) then
    Exit;
  Dset := TFIBAutoUpdateOptions(GetComponent(0)).Owner;
  DB := GetObjectProp(Dset, 'Database');
  if not Assigned(DB) then
    Exit;
  Qry := nil;
  Trans := nil;
  try
    try
      Trans := expTransactionClass.Create(nil);
      SetObjectProp(Trans, 'DefaultDatabase', DB);

      Qry := expQueryClass.Create(nil);
      SetPropValue(Qry, 'ParamCheck', 'False');
      SetObjectProp(Qry, 'Database', DB);
      SetObjectProp(Qry, 'Transaction', Trans);
      AssignStringsToProp(Qry, 'SQL',
        'select RDB$GENERATOR_NAME  from RDB$GENERATORS ' +
        'where (RDB$SYSTEM_FLAG is NULL) or (RDB$SYSTEM_FLAG = 0)' +
        ' order by RDB$GENERATOR_NAME'

        );
      SetPropValue(Trans, 'Active', 'True');

      try
        ObjSupports(Qry, IFIBQuery, iQry);
        iQry.ExecQuery;

        while not iQry.iEof do
        begin
          Proc(Trim(VarToStr(iQry.FieldValue(0, False))));
          iQry.iNext;
        end;
        iQry.Close;
      finally
        SetPropValue(Trans, 'Active', 'False');
      end;
    except
      // no value list when the database cannot be read
    end;
  finally
    iQry := nil;
    Qry.free;
    Trans.free;
  end;
end;

{ TFIBTrKindEdit }

function TFIBTrKindEdit.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes;
  Result := Result + [paValueList]
end;

procedure TFIBTrKindEdit.GetValues(Proc: TGetStrProc);
var
  i: Integer;
  Keys, KindNames: Variant;
begin
  if PropCount > 1 then
    Exit;
  Keys := DefAllSubKey(['Software', RegFIBRoot, RegFIBTrKinds]);
  Proc('NoUserKind');
  if VarType(Keys) = varBoolean then
    Exit;
  for i := VarArrayLowBound(Keys, 1) to VarArrayHighBound(Keys, 1) do
  begin
    KindNames := DefReadFromRegistry(['Software', RegFIBRoot, RegFIBTrKinds, Keys[i]], ['Name']);
    if VarType(KindNames) <> varBoolean then
      Proc(KindNames[0, 0])
  end;
end;

{ TFIBTransactionParamsEditor }

procedure TFIBTransactionParamsEditor.Edit;
begin
  if EditFIBTrParams(TComponent(GetComponent(0))) then
    Modified
end;

function TFIBTransactionParamsEditor.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog] - [paSubProperties];
end;

function TFIBTransactionParamsEditor.GetValue: string;
begin
  Result := '(TTRParams)'
end;

{ TFIBQueryEditor }

procedure TFIBQueryEditor.ExecuteVerb(Index: Integer);
var
  iQry: IFIBQuery;
begin
  case Index of
    0:
      begin
        if not FindPropInCode(Component, 'SQL') then
          if ShowSQLEdit(Component) then
            Designer.Modified;
        FindPropInCode(Component, 'SQL')
      end;
    1:
      if ObjSupports(Component, IFIBQuery, iQry) then
        try
          iQry.CheckValidStatement;
          ShowMessage(SNoErrors);
        except
          on E: Exception do
            ShowMessage(E.Message);
        end;
  end;

end;

function TFIBQueryEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0: Result := SEditSQL;
    1: Result := SCheckSQLs;
  end;
end;

function TFIBQueryEditor.GetVerbCount: Integer;
begin
  Result := 2;
end;

{ TFIBParamsToFieldsProperty }

procedure TFIBParamsToFieldsProperty.Edit;
var
  P: TObject;
begin
  P := GetObjectProp(GetComponent(0), 'ParamsToFieldsLinks');
  if Assigned(P) and (TFIBAutoUpdateOptions(GetComponent(0)).Owner is TDataSet) then
    if ShowEdParamToFields(TDataSet(TFIBAutoUpdateOptions(GetComponent(0)).Owner), TStrings(P)) then
      Designer.Modified
end;

function TFIBParamsToFieldsProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog] - [paSubProperties];
end;

function TFIBParamsToFieldsProperty.GetValue: string;
var
  P: TObject;
begin
  P := GetObjectProp(GetComponent(0), 'ParamsToFieldsLinks');
  if Assigned(P) and ((TStrings(P).Count) > 0) then
    Result := '(TPARAMS_FIELDS_LINKS)'
  else
    Result := '(TParams_Fields_Links)';
end;

{ TFIBKeyFieldsProperty }

function TFIBKeyFieldsProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes;
  Result := Result + [paValueList]
end;

procedure TFIBKeyFieldsProperty.GetValues(Proc: TGetStrProc);
var
  i: Integer;
  ds: TDataSet;
  ids: IFIBDataSet;
  Obj: TObject;
  Stringer: IFIBStringer;
  updTableName: string;
  clExp: IFIBClassesExporter;
begin
  if PropCount > 1 then
    Exit;
  if not(TFIBAutoUpdateOptions(GetComponent(0)).Owner is TDataSet) then
    Exit;
  ds := TDataSet(TFIBAutoUpdateOptions(GetComponent(0)).Owner);
  if not ObjSupports(ds, IFIBDataSet, ids) then
    Exit;
  Obj := GetObjectProp(ds, 'Database');
  if not Assigned(Obj) then
    Exit;

  with ds do
    try
      updTableName := GetPropValue(GetComponent(0), 'UpdateTableName');
      if Trim(updTableName) = '' then
      begin
        ShowMessage('Error: UpdateTableName is empty');
        Exit;
      end;
      Supports(FIBClassesExporter, IFIBClassesExporter, clExp);

      Stringer := clExp.iGetStringer;
      FieldDefs.Update;
      if FieldCount > 0 then
        for i := 0 to Pred(FieldCount) do
        begin
          if ((Fields[i] is TLargeIntField) or (Fields[i] is TIntegerField) or
            ((Fields[i] is TBCDField) and (TBCDField(Fields[i]).Size = 0))) and
            Stringer.EqualStrings(ids.GetRelationTableName(Fields[i]), updTableName, False) then
          begin
            Proc(Fields[i].FieldName);
          end;
        end
      else
      begin
        ids.Prepare;
        for i := 0 to Pred(FieldDefs.Count) do
        begin
          if (FieldDefs[i].DataType in [ftSmallint, ftInteger]) and
            Stringer.EqualStrings(ids.GetRelationTableName(FieldDefs[i]), updTableName, False) then
          begin
            Proc(FieldDefs[i].Name);
          end
          else if ((FieldDefs[i].DataType = ftBCD) and (FieldDefs[i].Size = 0)
            ) and Stringer.EqualStrings(ids.GetRelationTableName(FieldDefs[i]), updTableName, False) then
          begin
            Proc(FieldDefs[i].Name);
          end;
        end;
      end;
    except
    end;
end;

{ TFIBUpdateTableNameProperty }

function TFIBUpdateTableNameProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes;
  Result := Result + [paValueList]
end;

procedure TFIBUpdateTableNameProperty.GetValues(Proc: TGetStrProc);
var
  i: Integer;
  Tables: TStrings;
  Stringer: IFIBStringer;
  clExp: IFIBClassesExporter;
begin
  if PropCount > 1 then
    Exit;
  if not(TFIBAutoUpdateOptions(GetComponent(0)).Owner is TDataSet) then
    Exit;
  Tables := TStringList.Create;
  try
    Supports(FIBClassesExporter, IFIBClassesExporter, clExp);
    Stringer := clExp.iGetStringer;

    Stringer.AllTables
      (TStrings(GetObjectProp(TFIBAutoUpdateOptions(GetComponent(0)).Owner, 'SelectSQL')).Text, Tables);
    for i := 0 to Pred(Tables.Count) do
      Proc(Stringer.ExtractWord(1, Tables[i], [' ']));
  finally
    Tables.free
  end
end;

// DataSet Editor

procedure ShowDataSetSQLEditor(Component: TComponent; Kind: Integer; Designer: IDesigner);
const
  SQLNames: array [0 .. 4] of string = ('SelectSQL', 'InsertSQL', 'UpdateSQL', 'DeleteSQL', 'RefreshSQL');

var
  k: Byte;
  ExitToCodeEditor: Integer;
begin
  for k := 0 to 4 do
  begin
    SaveModule(Component, SQLNames[k]);
  end;
  if ShowDSSQLEdit(TDataSet(Component), Kind, ExitToCodeEditor) then
  begin
    Designer.Modified;
  end;
  if ExitToCodeEditor >= 0 then
  begin
    for k := 0 to 4 do
    begin
      if ExitToCodeEditor <> k then
        if CloseModule(Component, SQLNames[k]) then
          CreatePropInCode(Component, SQLNames[k], nil, True);
      SaveModule(Component, SQLNames[k]);
    end;
    if ExitToCodeEditor >= 0 then
      FindPropInCode(Component, SQLNames[ExitToCodeEditor]);
  end;
end;

type
  PClass = ^TClass;

constructor TFIBDataSetEditor.Create(AComponent: TComponent; ADesigner: IDesigner);
var
  CompClass: TClass;
begin
  inherited Create(AComponent, ADesigner);
  CompClass := PClass(AComponent)^;
  try
    PClass(AComponent)^ := TDataSet;
    DefaultEditor := GetComponentEditor(AComponent, ADesigner);
  finally
    PClass(AComponent)^ := CompClass;
  end;
end;

function TFIBDataSetEditor.GetVerbCount: Integer;
begin
  Result := DefaultEditor.GetVerbCount + 4
end;

function TFIBDataSetEditor.GetVerb(Index: Integer): string;
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

procedure TFIBDataSetEditor.ExecuteVerb(Index: Integer);

var
  SText: string;
  k: Integer;
  Reopen: Boolean;
  ErrStr: string;
  ids: IFIBDataSet;
  iQry: IFIBQuery;
  idb: IFIBConnect;
  curObj: TObject;
begin
  if ObjSupports(Component, IFIBDataSet, ids) then
    if Index < DefaultEditor.GetVerbCount then
      with TDataSet(Component) do
      begin
        try
          Reopen := Active;
          Close;
          ids.Prepare;
          if Reopen then
            Open;
        except
        end;
        DefaultEditor.ExecuteVerb(Index);
      end
    else
    begin

      SText := TStrings(GetObjectProp(Component, 'SelectSQL')).Text;
      case Index - DefaultEditor.GetVerbCount of
        0: ShowDataSetSQLEditor(Component, 0, Designer);
        1: SaveDataSetInfo;
        2:
          begin
            // try to connect
            curObj := GetObjectProp(Component, 'Database');
            if not Assigned(curObj) or not GetPropValue(curObj, 'Connected') then
            begin
              MessageDlg(SCompDatabaseNotConnected, mtConfirmation, [mbOK], 0);
              Exit;
            end;

            ObjSupports(curObj, IFIBConnect, idb);
            if idb.QueryValueAsStr(qryExistTable, 0, ['FIB$DATASETS_INFO']) = '0' then
            begin
              if MessageDlg(SCompEditInfoTableNotExist, mtConfirmation, [mbOK, mbCancel], 0) <> mrOk then
                Exit;
              CreateDataSetRepositoryTable(idb);
            end;
            k := GetPropValue(Component, 'DataSet_ID', False);
            ChooseDSInfo(TDataSet(Component));
            if k <> GetPropValue(Component, 'DataSet_ID', False) then
              Designer.Modified
          end;
        3:
          with TDataSet(Component) do
          begin
            ErrStr := SErrorIn;
            curObj := FindComponent('SelectQuery');
            if ObjSupports(curObj, IFIBQuery, iQry) then
              if TStrings(GetObjectProp(Component, 'SelectSQL')).Count > 0 then
                try
                  iQry.CheckValidStatement;
                except
                  ErrStr := ErrStr + 'SelectSQL'#13#10;
                end;
            curObj := FindComponent('UpdateQuery');
            if ObjSupports(curObj, IFIBQuery, iQry) then
              if TStrings(GetObjectProp(Component, 'UpdateSQL')).Count > 0 then
                try
                  iQry.CheckValidStatement;
                except
                  ErrStr := ErrStr + 'UpdateSQL'#13#10;
                end;
            curObj := FindComponent('DeleteQuery');
            if ObjSupports(curObj, IFIBQuery, iQry) then
              if TStrings(GetObjectProp(Component, 'DeleteSQL')).Count > 0 then
                try
                  iQry.CheckValidStatement;
                except
                  ErrStr := ErrStr + 'DeleteSQL'#13#10;
                end;
            curObj := FindComponent('InsertQuery');
            if ObjSupports(curObj, IFIBQuery, iQry) then
              if TStrings(GetObjectProp(Component, 'InsertSQL')).Count > 0 then
                try
                  iQry.CheckValidStatement;
                except
                  ErrStr := ErrStr + 'InsertSQL'#13#10;
                end;
            curObj := FindComponent('RefreshQuery');
            if ObjSupports(curObj, IFIBQuery, iQry) then
              if TStrings(GetObjectProp(Component, 'RefreshSQL')).Count > 0 then
                try
                  iQry.CheckValidStatement;
                except
                  ErrStr := ErrStr + 'RefreshSQL'#13#10;
                end;
            if ErrStr <> SErrorIn then
              ShowMessage(ErrStr)
            else
              ShowMessage(SNoErrors)
          end;
      end;
      if SText <> TStrings(GetObjectProp(Component, 'SelectSQL')).Text then
        Designer.Modified;
    end;
end;

const
  ExchangeDelimeter = '#$#$';

// SQL string literal with doubled quotes
function QuoteSQLString(const Value: string): string;
begin
  Result := '''' + StringReplace(Value, '''', '''''', [rfReplaceAll]) + '''';
end;

function GetConditionsExchangeStr(Conditions: TStrings): string;
var
  i: Integer;
begin
  Result := '';
  with Conditions do
    for i := 0 to Pred(Count) do
      Result := Result + Names[i] + ExchangeDelimeter + Values[Names[i]] +
        ExchangeDelimeter + IntToStr(Ord(TFIBCondition(Objects[i]).Enabled)) + #13#10

end;

procedure SaveFIBDataSetInfo(Database, DataSet: TObject; DS_ID: Integer);
var
  idb: IFIBConnect;
begin
  if ObjSupports(Database, IFIBConnect, idb) then
  begin
    if idb.QueryValueAsStr
      ('SELECT Count(*) FROM FIB$DATASETS_INFO WHERE DS_ID=:DS_ID', 0, [DS_ID]) = '0' then
      idb.Execute
        ('INSERT INTO FIB$DATASETS_INFO (DS_ID,UPDATE_ONLY_MODIFIED_FIELDS) VALUES(' + IntToStr(DS_ID) + ',1)');
    if Length(GetPropStringValue(DataSet, 'AutoUpdateOptions.KeyFields')) > 68 then
      WidenDataSetKeyField(idb);
    idb.Execute('Update FIB$DATASETS_INFO SET '#13#10 +
      'SELECT_SQL=' + QuoteSQLString(TStrings(GetObjectProp(DataSet, 'SelectSQL')).Text) + ','#13#10 +
      'INSERT_SQL=' + QuoteSQLString(TStrings(GetObjectProp(DataSet, 'InsertSQL')).Text) + ','#13#10 +
      'UPDATE_SQL=' + QuoteSQLString(TStrings(GetObjectProp(DataSet, 'UpdateSQL')).Text) + ','#13#10 +
      'DELETE_SQL=' + QuoteSQLString(TStrings(GetObjectProp(DataSet, 'DeleteSQL')).Text) + ','#13#10 +
      'REFRESH_SQL=' + QuoteSQLString(TStrings(GetObjectProp(DataSet, 'RefreshSQL')).Text) + ','#13#10 +
      'KEY_FIELD=' + QuoteSQLString(GetPropStringValue(DataSet, 'AutoUpdateOptions.KeyFields')) + ','#13#10 +
      'NAME_GENERATOR=' + QuoteSQLString(GetPropStringValue(DataSet, 'AutoUpdateOptions.GeneratorName')) +
      ','#13#10 +
      'DESCRIPTION=' + QuoteSQLString(GetPropStringValue(DataSet, 'Description')) + ','#13#10 +
      'UPDATE_TABLE_NAME=' + QuoteSQLString(GetPropStringValue(DataSet, 'AutoUpdateOptions.UpdateTableName')) +
      ','#13#10 +
      'UPDATE_ONLY_MODIFIED_FIELDS=' + QuoteSQLString(IntToStr(GetSubPropValue(DataSet,
      'AutoUpdateOptions.UpdateOnlyModifiedFields'))) + ','#13#10 +
      'CONDITIONS=' + QuoteSQLString(GetConditionsExchangeStr(TStrings(GetObjectProp(DataSet,
      'Conditions')))) + #13#10 +
      'WHERE DS_ID=' + IntToStr(DS_ID));
  end
end;

procedure TFIBDataSetEditor.SaveDataSetInfo;
var
  DS_ID: Integer;
  DB: TObject;
  idb: IFIBConnect;
begin
  DS_ID := GetPropValue(Component, 'DataSet_ID', False);
  with Component do
    if DS_ID = 0 then
      ShowMessage(Name + SCompEditDataSet_ID)
    else
    begin
      DB := GetObjectProp(Component, 'Database');
      if DB = nil then
        ShowMessage(SDataBaseNotAssigned)
      else
      begin
        ObjSupports(DB, IFIBConnect, idb);
        if idb.QueryValueAsStr(qryExistTable, 0, ['FIB$DATASETS_INFO']) = '0' then
        begin
          if MessageDlg(SCompEditInfoTableNotExist, mtConfirmation, [mbOK, mbCancel], 0) <> mrOk then
            Exit;
          CreateDataSetRepositoryTable(idb);
        end;
        SaveFIBDataSetInfo(DB, Component, DS_ID);
      end
    end;
end;

{ TFIBDataSetIDProperty }

procedure TFIBDataSetIDProperty.Edit;
var
  OldID: Integer;
  DB: TObject;
  idb: IFIBConnect;
begin
  OldID := GetPropValue(GetComponent(0), 'DataSet_ID', False);
  DB := GetObjectProp(GetComponent(0), 'Database');
  if DB = nil then
    Exit
  else if ObjSupports(DB, IFIBConnect, idb) then
  begin
    if idb.QueryValueAsStr(qryExistTable, 0, ['FIB$DATASETS_INFO']) = '0' then
    begin
      if not GetValueInSet(DB, 'UseRepositories', 'urDataSetInfo') then
        raise Exception.Create(SCompEditDataSetInfoForbid);
      if MessageDlg(SCompEditInfoTableNotExist, mtConfirmation, [mbOK, mbCancel], 0) <> mrOk then
        Exit;
      CreateDataSetRepositoryTable(idb);
    end;

    ChooseDSInfo(TDataSet(GetComponent(0)));
    if OldID <> GetPropValue(GetComponent(0), 'DataSet_ID', False) then
      Modified
  end
end;

function TFIBDataSetIDProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog];
end;

{ TFIBSQLsProperties }

function TFIBSQLsProperties.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog, paSubProperties];
end;

function TFIBSQLsProperties.GetValue: string;
begin
  Result := '(SQLs)'
end;

procedure TFIBSQLsProperties.Edit;
begin
  ShowDataSetSQLEditor(TComponent(GetComponent(0)), 0, Designer);
end;

{ TFIBSQLsProperty }

procedure TFIBSQLsProperty.Edit;
var
  pName: string;
  KindSQL: Integer;
begin
  pName := GetName;
  if pName = 'SelectSQL' then
    KindSQL := 0
  else if pName = 'UpdateSQL' then
    KindSQL := 2
  else if pName = 'InsertSQL' then
    KindSQL := 1
  else if pName = 'DeleteSQL' then
    KindSQL := 3
  else
    KindSQL := 4;
  if not FindPropInCode(TFIBSQLs(GetComponent(0)).Owner, pName) then
    ShowDataSetSQLEditor(TFIBSQLs(GetComponent(0)).Owner, KindSQL, Designer);
end;

function TFIBSQLsProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog] - [paSubProperties];
end;

function TFIBSQLsProperty.GetValue: string;
begin
  Result := SCompEditSQLText;
end;

{ TFIBSQLPropEdit }

procedure TFIBSQLPropEdit.Edit;
begin
  begin
    if not FindPropInCode(TComponent(GetComponent(0)), 'SQL') then
      if ShowSQLEdit(TComponent(GetComponent(0))) then
        Modified;
    FindPropInCode(TComponent(GetComponent(0)), 'SQL');
  end;
end;

function TFIBSQLPropEdit.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog] - [paSubProperties];
end;

{ TFIBDeltaReceiverTableNameProperty }

function TFIBDeltaReceiverTableNameProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes;
  Result := Result + [paValueList]
end;

const
  QRYTables = 'SELECT REL.RDB$RELATION_NAME FROM RDB$RELATIONS REL WHERE ' +
    '(REL.RDB$SYSTEM_FLAG <> 1 OR REL.RDB$SYSTEM_FLAG IS NULL) AND ' +
    '(NOT REL.RDB$FLAGS IS NULL) AND ' + '(REL.RDB$VIEW_BLR IS NULL) AND ' +
    '(REL.RDB$SECURITY_CLASS STARTING WITH ''SQL$'') ' +
    'ORDER BY REL.RDB$RELATION_NAME';

procedure TFIBDeltaReceiverTableNameProperty.GetValues(Proc: TGetStrProc);
var
  edComponent: TPersistent;
  DB: TObject;
  Qry: TComponent;
  Trans: TObject;
  iQry: IFIBQuery;
  trActive: Boolean;
begin
  edComponent := GetComponent(0);
  Trans := GetObjectProp(edComponent, 'Transaction');
  if not Assigned(Trans) then
    Exit;
  DB := GetObjectProp(Trans, 'DefaultDatabase');
  if not Assigned(DB) then
    Exit;
  trActive := GetPropValue(Trans, 'Active');
  Qry := nil;
  try
    try
      if not trActive then
        SetPropValue(Trans, 'Active', True);
      Qry := expQueryClass.Create(nil);
      SetPropValue(Qry, 'ParamCheck', 'False');
      SetObjectProp(Qry, 'Database', DB);
      SetObjectProp(Qry, 'Transaction', Trans);
      AssignStringsToProp(Qry, 'SQL', QRYTables);
      ObjSupports(Qry, IFIBQuery, iQry);
      iQry.ExecQuery;

      while not iQry.iEof do
      begin
        Proc(Trim(VarToStr(iQry.FieldValue('RDB$RELATION_NAME', False))));
        iQry.iNext;
      end;
      iQry.Close;
    except
      // no value list when the database cannot be read
    end
  finally
    iQry := nil;
    Qry.free;
    if not trActive then
      SetPropValue(Trans, 'Active', False);
  end;

end;

{ TFIBDeltaReceiverEditor }

procedure TFIBDeltaReceiverEditor.ExecuteVerb(Index: Integer);
var
  TableName: string;
  DelTableName, TriggerName: string;
  DB: TObject;
  Trans: TObject;
  Script: TStrings;
  Stringer: IFIBStringer;
  clExp: IFIBClassesExporter;
begin
  Trans := GetObjectProp(Component, 'Transaction');
  if not Assigned(Trans) then
  begin
    ShowMessage(SCompEditDeltaReceiverErr2);
    Exit;
  end;

  DB := GetObjectProp(Trans, 'DefaultDatabase');
  Script := TStringList.Create;
  try
    case Index of
      0:
        begin
          Script.Add('/***************************************');
          Script.Add('Common metadata for TableChangesReader supports');
          if Assigned(DB) then
            Script.Add('Database: ' + GetPropStringValue(DB, 'DBName'));
          Script.Add('***************************************/');
          Script.Add('');
          Script.Add('CREATE DOMAIN FIB$BIGINT AS BIGINT;');
          Script.Add('CREATE DOMAIN FIB$TIMESTAMP AS TIMESTAMP;');
          Script.Add('CREATE GENERATOR FIB$GEN_COMMIT_NO;');
          Script.Add('CREATE GENERATOR FIB$GEN_TRANSACTION_ID;');
          Script.Add('');
          Script.Add('CREATE TABLE FIB$TRANSACTIONS(');
          Script.Add(' TRANSACTION_ID FIB$BIGINT,');
          Script.Add(' COMMIT_NO   FIB$BIGINT ,');
          Script.Add(' COMMIT_TIME    FIB$TIMESTAMP');
          Script.Add(');');
          Script.Add('');
          Script.Add
            ('CREATE  DESCENDING INDEX IDX_FIB$COMMIT_NO ON FIB$TRANSACTIONS (COMMIT_NO);');
          Script.Add('');

          Script.Add('SET TERM ^ ;');
          Script.Add('');
          Script.Add('CREATE PROCEDURE FIB$CLEAR_TRANSACTION_ID ');
          Script.Add('AS BEGIN ');
          Script.Add
            (' rdb$set_context(''USER_TRANSACTION'',''FIB$TRANSACTION_ID'',NULL);');
          Script.Add('END ^');
          Script.Add('');

          Script.Add
            ('CREATE PROCEDURE FIB$GET_TRANSACTION_ID ( FORCE   SMALLINT )');
          Script.Add('RETURNS ( TRANS_ID   BIGINT) ');
          Script.Add('AS');
          Script.Add('BEGIN ');
          Script.Add
            (' TRANS_ID=rdb$get_context(''USER_TRANSACTION'',''FIB$TRANSACTION_ID'');');
          Script.Add(' if ((TRANS_ID is NULL) AND (FORCE=1)) then');
          Script.Add(' begin');
          Script.Add('  TRANS_ID=GEN_ID(FIB$GEN_TRANSACTION_ID,1);');
          Script.Add
            ('  rdb$set_context(''USER_TRANSACTION'',''FIB$TRANSACTION_ID'',:TRANS_ID);');
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
          Script.Add
            ('   Select TRANS_ID From FIB$GET_TRANSACTION_ID(0) INTO :TRANS_ID;');
          Script.Add('   if  (NOT TRANS_ID is NULL) then');
          Script.Add('   begin');
          Script.Add('    COMMIT_NO=GEN_ID(FIB$GEN_COMMIT_NO,1);');
          Script.Add
            ('    insert into FIB$TRANSACTIONS (TRANSACTION_ID,COMMIT_NO,COMMIT_TIME)');
          Script.Add('    values(:TRANS_ID,:COMMIT_NO,''NOW'');');
          Script.Add('    EXECUTE PROCEDURE FIB$CLEAR_TRANSACTION_ID;');
          Script.Add('   end');
          Script.Add('END ^');

          Script.Add('');
          Script.Add('COMMIT WORKS ^');

          ShowScript('Common metadata for DeltaReceiver supports', DB, Script);

        end;
      1:
        begin
          TableName := GetPropStringValue(Component, 'TableName');
          if Length(TableName) = 0 then
          begin
            ShowMessage(SCompEditDeltaReceiverErr1);
            Exit;
          end;

          Script.Add('/***************************************');
          Script.Add('Metadata of ' + TableName + ' for TableChangesReader supports');
          if Assigned(DB) then
            Script.Add('Database: ' + GetPropStringValue(DB, 'DBName'));
          Script.Add('***************************************/');
          Script.Add('');
          Supports(FIBClassesExporter, IFIBClassesExporter, clExp);
          Stringer := clExp.iGetStringer;

          DelTableName := Stringer.FormatIdentifier(3, TableName + '_DELETED');
          TriggerName := Stringer.FormatIdentifier(3, 'FIB$TRANSLOG_' + TableName);
          TableName := Stringer.FormatIdentifier(3, TableName);
          Script.Add('ALTER TABLE ' + TableName + ' ADD FIB$TRANSACTION_ID FIB$BIGINT;');
          Script.Add('ALTER TABLE ' + TableName + ' ADD FIB$UPDATE_TIME FIB$TIMESTAMP;');
          Script.Add('');
          Script.Add('CREATE TABLE  ' + DelTableName + '(');
          Script.Add(' ID                 FIB$BIGINT NOT NULL,');
          Script.Add(' FIB$TRANSACTION_ID FIB$BIGINT,');
          Script.Add(' FIB$DELETED_TIME   FIB$TIMESTAMP');
          Script.Add(' );');
          Script.Add('');
          Script.Add('SET TERM ^ ;');
          Script.Add('');

          Script.Add('CREATE TRIGGER ' + TriggerName + ' FOR ' + TableName);
          Script.Add('ACTIVE BEFORE INSERT OR UPDATE OR DELETE POSITION 0');
          Script.Add('AS');
          Script.Add(' DECLARE VARIABLE TRANS_ID BIGINT;');
          Script.Add('BEGIN');
          Script.Add
            ('  Select TRANS_ID From FIB$GET_TRANSACTION_ID(1) INTO :TRANS_ID;');
          Script.Add('  if (DELETING) then');
          Script.Add('   Insert into ' + DelTableName + '(ID,FIB$TRANSACTION_ID,FIB$DELETED_TIME)');
          Script.Add('    values (Old.ID,:TRANS_ID,''NOW'');');
          Script.Add('  else');
          Script.Add('  begin');
          Script.Add('   new.FIB$TRANSACTION_ID=:TRANS_ID;');
          Script.Add('   new.FIB$UPDATE_TIME   =''NOW'';');
          Script.Add('  end');
          Script.Add('END ^');

          Script.Add('');
          Script.Add('COMMIT WORKS ^');

          ShowScript(' Metadata for DeltaReceiver supports', DB, Script);
        end;
    end;
  finally
    Script.free;
  end
end;

function TFIBDeltaReceiverEditor.GetVerb(Index: Integer): string;
var
  TableName: string;
begin
  case Index of
    0: Result := SCompEditDeltaReceiver1;
    1:
      begin
        TableName := GetPropStringValue(Component, 'TableName');
        Result := Format(SCompEditDeltaReceiver2, [TableName]);
      end
  end;
end;

function TFIBDeltaReceiverEditor.GetVerbCount: Integer;
begin
  Result := 2;
end;

{ TFIBGeneratorsProperty }

type
  TPersistentCracker = class(TPersistent);

procedure TFIBGeneratorsProperty.Edit;
var
  Obj: TPersistent;
begin
  Obj := GetComponent(0);
  while (Obj <> nil) and not(Obj is TComponent) do
    Obj := TPersistentCracker(Obj).GetOwner;
  ShowCollectionEditorClass(Designer, TCollectionEditor, TComponent(Obj),
    TCollection(GetOrdValue), 'GeneratorList', [coAdd, coDelete, coMove]);
end;

function TFIBGeneratorsProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog, paReadOnly];
end;

function TFIBGeneratorsProperty.GetValue: string;
begin
  // FmtStr(Result, '(%s)', [GetPropType^.Name]);
  Result := 'TGeneratorList'
end;

end.
