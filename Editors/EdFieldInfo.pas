{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ Interbase databases                                           }
{                                                               }
{    FIBPlus is based in part on the product                    }
{    Free IB Components, written by Gregory H. Deatz for        }
{    Hoagland, Longo, Moran, Dunst & Doukas Company.            }
{    mailto:gdeatz@hlmdd.com                                    }
{                                                               }
{    Copyright (c) 1998-2001 Serge Buzadzhy                     }
{    Contact: buzz@devrace.com                                  }
{                                                               }
{ ------------------------------------------------------------- }
{    FIBPlus home page      : http://www.fibplus.net/           }
{    FIBPlus support e-mail : fibplus@devrace.com               }
{ ------------------------------------------------------------- }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit EdFieldInfo;
{$i ..\FIBPlus.inc}

interface

uses
 {$IFDEF WINDOWS}
  Windows, Messages, SysUtils, Classes,
  {$IFDEF D_XE2}
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.Grids,Vcl.DBGrids,       Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.DBCtrls,
  Vcl.Buttons, Vcl.Menus,
  {$ELSE}
  Graphics, Controls, Forms, Dialogs,Grids,DBGrids,
  ExtCtrls, StdCtrls, DBCtrls,Buttons, Menus,
  {$ENDIF}

   Db, pFIBInterfaces,uFIBEditorForm,
  RegistryUtils
   {$IFDEF D6+}, Variants{$ENDIF}
;
 {$ENDIF}


type
  TfrmFields = class(TFIBEditorCustomForm)
    dsQryFL: TDataSource;
    sbDBGrid1: TDBGrid;
    Panel1: TPanel;
    DataSource2: TDataSource;
    Panel2: TPanel;
    Panel3: TPanel;
    sbDBGrid2: TDBGrid;
    EdFilter: TEdit;
    btnCopyFields: TButton;
    chFilt: TCheckBox;
    PopupMenu1: TPopupMenu;
    miTables1: TMenuItem;
    miProcedures1: TMenuItem;
    miUserForms: TMenuItem;
    cmbKindObjs: TComboBox;
    procedure qryTabFieldsBeforeOpen(DataSet: TDataSet);
    procedure btnCopyFieldsClick(Sender: TObject);
    procedure chFiltClick(Sender: TObject);
    procedure qryFLFilterRecord(DataSet: TDataSet; var Accept: Boolean);
    procedure DataSource2DataChange(Sender: TObject; Field: TField);
    procedure miProcedures1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure EdFilterChange(Sender: TObject);
    procedure qrySPsFilterRecord(DataSet: TDataSet; var Accept: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure cmbKindObjsChange(Sender: TObject);
    procedure qryFLAfterOpen(DataSet: TDataSet);
    procedure qryFLNewRecord(DataSet: TDataSet);
    procedure Panel3Resize(Sender: TObject);
    procedure qryFLBeforeClose(DataSet: TDataSet);
    procedure qrySPFieldsBeforeOpen(DataSet: TDataSet);
  private
    FFieldLength:string;
    pFIBTransaction1:TComponent;
    qryFL   :TDataSet;
    qrySPs  :TDataSet;
    qryTabFields:TDataSet;
    qryTabs :TDataSet;
    qrySPFields:TDataSet;
    procedure  PrepareDataSetProps(DataSet,Database,Transaction:TComponent);
  private
   iTr:IFIBTransaction;
   procedure CopyTableFields;
   procedure SaveLoadFieldsDisplaySize(isSave:boolean);
  public
    { Public declarations }
  end;

var
  frmFields: TfrmFields;

procedure ShowFieldInfo( aDataBase:TComponent);

implementation

uses  pFIBEditorsConsts, RegFIBPlusEditors,TypInfo, RTTIRoutines;

{$R *.dfm}

const
 qryFieldLength=
 'select fs.rdb$field_length from rdb$relation_fields f '+
    'join rdb$fields fs on fs.rdb$field_name = f.rdb$field_source '+
    'where f.rdb$relation_name = ''RDB$RELATIONS'''+
    'and f.rdb$field_name=''RDB$RELATION_NAME''';

 qryFR_DataSQL='SELECT * FROM FIB$FIELDS_INFO ORDER BY TABLE_NAME,FIELD_NAME';

 qryTablesSQL='SELECT CAST(''ALIAS'' AS CHAR( %s )) AS RDB$RELATION_NAME '+
 'FROM RDB$DATABASE UNION SELECT  RDB$RELATION_NAME FROM RDB$RELATIONS '+
 'WHERE  RDB$FLAGS = 1 ORDER BY 1';

 qryStoredProcSQL='SELECT  CAST(''ALIAS'' AS CHAR(%s)) AS RDB$RELATION_NAME '+
  'FROM  RDB$DATABASE UNION SELECT  RDB$PROCEDURE_NAME RDB$RELATION_NAME FROM  RDB$PROCEDURES '+
  'ORDER BY 1';





procedure ShowFieldInfo( aDataBase:TComponent);
var
  iDB:IFIBConnect;
  s:string;
  ts:TStrings;
//  m:TMethod;
begin
 frmFields:= TfrmFields.Create(Application);
 ts:=TStringList.Create;
 with frmFields do
 try
  pFIBTransaction1:= expTransactionClass.Create(frmFields);
  if   ObjSupports(pFIBTransaction1,IFIBTransaction,iTr) and ObjSupports(aDataBase,IFIBConnect,iDB) then
  begin
    FFieldLength:=
     iDB.QueryValueAsStr(qryFieldLength,0,['']);
    SetObjectProp(pFIBTransaction1,'DefaultDataBase',aDatabase);
    SetEnumProp(pFIBTransaction1,'TimeoutAction','TACommitRetaining'); 
    qryFL   :=  TDataSet(expDatasetClass.Create(frmFields));
    qrySPs  :=  TDataSet(expDatasetClass.Create(frmFields));
    qrySPFields:=TDataSet(expDatasetClass.Create(frmFields));
    qryTabs:=TDataSet(expDatasetClass.Create(frmFields));
    qryTabFields:=TDataSet(expDatasetClass.Create(frmFields));


    PrepareDataSetProps(qryFL,aDatabase,pFIBTransaction1);
    PrepareDataSetProps(qrySPs,aDatabase,pFIBTransaction1);
    PrepareDataSetProps(qrySPFields,aDatabase,pFIBTransaction1);
    PrepareDataSetProps(qryTabs,aDatabase,pFIBTransaction1);
    PrepareDataSetProps(qryTabFields,aDatabase,pFIBTransaction1);


{    m.Data:=frmFields;
    m.Code:=MethodAddress('qrySPsFilterRecord');
    SetMethodProp(qryTabs,'OnFilterRecord',m);}
    qryTabs.OnFilterRecord:=qrySPsFilterRecord;
    qrySPs.OnFilterRecord:=qrySPsFilterRecord;
    dsQryFL.DataSet:=qryFL;
    DataSource2.DataSet:=qryTabs;
    ts.Text:=qryFR_DataSQL;
    SetObjectProp(qryFL,'SelectSQL',ts);
    ts.Text:=Format(qryTablesSQL,[FFieldLength]);
    SetObjectProp(qryTabs,'SelectSQL',ts);
    ts.Text:=Format(qryStoredProcSQL,[FFieldLength]);
    SetObjectProp(qrySPs,'SelectSQL',ts);
    ts.Text:=qryTabFieldsSQL;
    SetObjectProp(qryTabFields,'SelectSQL',ts);
    ts.Text:= qrySPFieldsSQL;
    SetObjectProp(qrySPFields,'SelectSQL',ts);    
    iTr.StartTransaction;


    SetStringProperty(qryFL,'AutoUpdateOptions.KeyFields','TABLE_NAME;FIELD_NAME');
    SetStringProperty(qryFL,'AutoUpdateOptions.UpdateTableName','FIB$FIELDS_INFO');
    SetValueProperty(qryFL,'AutoUpdateOptions.AutoReWriteSqls',True);
    qryFL.AfterOpen:=qryFLAfterOpen;
    qryFL.BeforeClose:=qryFLBeforeClose;
    qryFL.OnNewRecord:=qryFLNewRecord;
    qryFL.OnFilterRecord:= qryFLFilterRecord;
    
    qryTabFields.BeforeOpen:=qryTabFieldsBeforeOpen;
    qrySPFields.BeforeOpen:=qrySPFieldsBeforeOpen;
    qryFL.Open;
    qryTabs.Open;
    qrySPs.Open;
  end;
  s:=GetStrProp(aDataBase,'DBName');
  Caption := SFieldInfoCaption + ' .' + s + ': FIB$FIELDS_INFO';
  ShowModal;
 finally
  ts.Free;
  frmFields.Free
 end;
end;

procedure  TfrmFields.PrepareDataSetProps(DataSet,Database,Transaction:TComponent);
begin
    SetObjectProp(DataSet,'DataBase',Database);
    SetObjectProp(DataSet,'Transaction',Transaction);
    SetPropValue(DataSet,'AutoCommit','True');    
end;

procedure TfrmFields.qryTabFieldsBeforeOpen(DataSet: TDataSet);
var
   ids:  IFIBDataSet;
begin
 ObjSupports(qryTabFields,IFIBDataSet,ids);
 with qryTabFields do
 begin
  if    DataSource2.DataSet=qryTabs then
   ids.SetParamValue(0,qryTabs.Fields[0].asString)
  else
   ids.SetParamValue(0,qrySPs.Fields[0].asString)
 end;
end;

procedure TfrmFields.CopyTableFields;
var Q:TDataSet;
begin
 qryFL.DisableControls;
 if    DataSource2.DataSet=qryTabs then  Q:=qryTabFields
 else
   Q:=qrySPFields;
 with Q do
 try
   Close;Open; Last; First;
   while not eof do
   begin
     if not qryFL.Locate
     ('TABLE_NAME;FIELD_NAME',
      VarArrayOf([DataSource2.DataSet.Fields[0].asString,Trim(Fields[0].asString)]),[loCaseInsensitive])
     then
     begin
      qryFL.Insert;
      qryFL.FieldByName('TABLE_NAME').asString:=DataSource2.DataSet.Fields[0].asString;
      qryFL.FieldByName('FIELD_NAME').asString:=Trim(Fields[0].asString);
      qryFL.FieldByName('VISIBLE').asInteger:=1;
      qryFL.FieldByName('TRIGGERED').asInteger:=0;            
      qryFL.Post;
     end;
     Next
   end;
 finally
  qryFL.EnableControls;
 end;
end;


procedure TfrmFields.btnCopyFieldsClick(Sender: TObject);
begin
 CopyTableFields
end;

procedure TfrmFields.chFiltClick(Sender: TObject);
begin
 qryFL.Filtered:=chFilt.Checked;
 qryFL.FindField('TABLE_NAME').Visible:=not chFilt.Checked;
end;

procedure TfrmFields.qryFLFilterRecord(DataSet: TDataSet; var Accept: Boolean);
begin
 if chFilt.Checked then
   Accept:=AnsiUpperCase(DataSet.FieldByName('TABLE_NAME').asString)=
    AnsiUpperCase(sbDBGrid2.dataSource.DataSet.Fields[0].asString)
end;

procedure TfrmFields.DataSource2DataChange(Sender: TObject; Field: TField);
begin
 if chFilt.Checked then
 begin
  qryFL.Filtered:=False;
  qryFL.Filtered:=True;
 end
end;

procedure TfrmFields.miProcedures1Click(Sender: TObject);
begin
TMenuItem(Sender).Checked:= not TMenuItem(Sender).Checked;
 if Sender=miTables1  then
 begin
  miProcedures1.Checked:=not miTables1.Checked;
  miUserForms.Checked  :=false;
 end
 else
 if Sender=miProcedures1  then
 begin
    miTables1.Checked    :=not miProcedures1.Checked;
    miUserForms.Checked  :=false;
 end
 else
 if Sender=miUserForms  then
 begin
    miTables1.Checked      :=not miUserForms.Checked;
    miProcedures1.Checked  :=false;
 end ;
 if miTables1.Checked then
   DataSource2.DataSet:=qryTabs
 else
 if miProcedures1.Checked then
   DataSource2.DataSet:=qrySPs

end;


procedure TfrmFields.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 if qryFL.State in [dsEdit,dsInsert] then qryFL.Post;
 iTr.Commit;
{$IFNDEF NO_REGISTRY}
 if WindowState=wsMaximized then
 begin
  WindowState:=wsNormal;
  DefWriteToRegistry(['Software',RegFIBRoot,RegRepository,'FieldInfoEditor'],
      ['Top','Left','Height','Width','Maximized'],
       [Top,Left,Height,Width, True]
  );
 end
 else
  DefWriteToRegistry(['Software',RegFIBRoot,RegRepository,'FieldInfoEditor'],
      ['Top','Left','Height','Width','Maximized'],
       [Top,Left,Height,Width, False]
  );

{$ENDIF}

end;

procedure TfrmFields.EdFilterChange(Sender: TObject);
begin
 with sbDBGrid2.DataSource.DataSet do
 begin
  Filtered:=False;
  Filtered:=Trim(EdFilter.Text)<>'';
 end;
end;


procedure TfrmFields.qrySPsFilterRecord(DataSet: TDataSet;
  var Accept: Boolean);
begin
  with DataSet do
   Accept:=Pos(Trim(EdFilter.text),
            AnsiUpperCase(FieldByName('RDB$RELATION_NAME').asString)
           )>0 
end;

procedure TfrmFields.FormCreate(Sender: TObject);
var
  v:Variant;

begin
 cmbKindObjs.ItemIndex:=0;
  btnCopyFields.Hint := SFieldInfoCopyFieldsHint;
  btnCopyFields.Caption := SFieldInfoCopyFields;
  chFilt.Caption := SFieldInfoFilter;
  cmbKindObjs.Items.Add(SFieldInfoKindTables);
  cmbKindObjs.Items.Add(SFieldInfoProcedures);

  EdFilter.Hint := SFieldInfoFilterHint;
  sbDBGrid2.Hint := SFieldInfoGridHint;

  miTables1.Caption := SFieldInfoTablesItem;
  miProcedures1.Caption :=  SFieldInfoProcedureItem;
  miUserForms.Caption := SFieldInfoUserFormsItem;

{$IFNDEF NO_REGISTRY}
  v:=DefReadFromRegistry(['Software',RegFIBRoot,RegRepository,'FieldInfoEditor'],
      ['Top','Left','Height','Width','Maximized']
  );

  if VarType(v)<>varBoolean then
  begin
    Position:=poDesigned;
    if v[1,0] then Top   :=v[0,0];
    if v[1,1] then Left  :=v[0,1];
    if v[1,2] then Height:=v[0,2];
    if v[1,3] then Width :=v[0,3];
    if v[1,4] and v[0,4] then
     WindowState:=wsMaximized;

  end;
{$ENDIF}
end;

procedure TfrmFields.cmbKindObjsChange(Sender: TObject);
begin

 with cmbKindObjs do
 case ItemIndex of
  1:
  begin
   miTables1.Checked:=False;
   miProcedures1.Checked:=True;
   DataSource2.DataSet:=qrySPs
  end;
 else
  DataSource2.DataSet:=qryTabs;
  miTables1.Checked:=True;
  miProcedures1.Checked:=False;
 end
end;

procedure TfrmFields.qryFLAfterOpen(DataSet: TDataSet);
var
  tf:TField;
begin
  with qryFL do
  begin
    tf:=FindField('FIB$VERSION');
    if tf<>nil then tf.Visible:=False;
    SaveLoadFieldsDisplaySize(False);
  end;
end;

procedure TfrmFields.qryFLNewRecord(DataSet: TDataSet);
begin
 if chFilt.Checked then
  qryFL.FieldByName('TABLE_NAME').asString:=sbDBGrid2.DataSource.DataSet.Fields[0].asString;
end;

procedure TfrmFields.Panel3Resize(Sender: TObject);
begin
  EdFilter.Width := Panel3.Width - 16;
  cmbKindObjs.Width := Panel3.Width - 16;
end;


procedure TfrmFields.SaveLoadFieldsDisplaySize(isSave: boolean);
var
  i: Integer;
  v:variant;
begin
  with qryFL do
  begin
    for i := 0 to FieldCount - 1 do
    if isSave then
    begin
     DefWriteToRegistry(['Software',RegFIBRoot,RegRepository,'FieldInfoEditor',Fields[i].FieldName],
      ['DisplayWidth'],[Fields[i].DisplayWidth]
     )
    end
    else
    begin
     v:=DefReadFromRegistry(['Software',RegFIBRoot,RegRepository,'FieldInfoEditor',Fields[i].FieldName],
      ['DisplayWidth']
     );
     if VarType(v)<>varBoolean then
      if v[1,0] then
      Fields[i].DisplayWidth:=v[0,0];
    end;
  end;
end;

procedure TfrmFields.qryFLBeforeClose(DataSet: TDataSet);
begin
 SaveLoadFieldsDisplaySize(True);
end;


procedure TfrmFields.qrySPFieldsBeforeOpen(DataSet: TDataSet);
var
   ids:  IFIBDataSet;
begin
 ObjSupports(qrySPFields,IFIBDataSet,ids);
 with qrySPFields do
 begin
   ids.SetParamValue(0,qrySPs.Fields[0].asString)
 end;

end;


end.
