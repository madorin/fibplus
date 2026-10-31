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
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit EdDataSetInfo;

interface

uses
{$I ..\FIB.inc}
  Windows, Messages, Classes, SysUtils, Db,
{$IFDEF C23}
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls,
  Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.Grids, Vcl.DBGrids, Vcl.DBCtrls, Vcl.Mask,
{$ELSE}
  Graphics, Controls, Forms, Dialogs, ComCtrls, ExtCtrls, StdCtrls,
  Grids, DBGrids, DBCtrls, Mask,
{$ENDIF}
  uFIBEditorForm, fraConditionsEdit, Variants;

type
  TFIBDataSetInfoForm = class(TFIBEditorCustomForm)
    DataSource1: TDataSource;
    PageControl1: TPageControl;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;
    TabSheet5: TTabSheet;
    TabSheet6: TTabSheet;
    Panel1: TPanel;
    Button1: TButton;
    Button2: TButton;
    btnSave: TButton;
    TabSheet7: TTabSheet;
    TabSheet8: TTabSheet;
    fraEdConditions1: TFIBConditionsFrame;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    DBEdit1: TDBEdit;
    DBEdit2: TDBComboBox;
    DBEdit3: TDBEdit;
    DBCheckBox1: TDBCheckBox;
    Panel2: TPanel;
    GroupBox2: TGroupBox;
    Edit1: TEdit;
    DBGrid1: TDBGrid;
    Splitter1: TSplitter;
    procedure qryDSInfoFilterRecord(DataSet: TDataSet; var Accept: Boolean);
    procedure Edit1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure qryDSInfoAfterDelete(DataSet: TDataSet);
    procedure qryDSInfoAfterInsert(DataSet: TDataSet);
    procedure qryDSInfoAfterScroll(DataSet: TDataSet);
    procedure qryDSInfoBeforeScroll(DataSet: TDataSet);
    procedure qryDSInfoNewRecord(DataSet: TDataSet);
    procedure Panel2Resize(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    Db: TComponent;
    trDSInfo: TComponent;
    qryDSInfo: TDataSet;
    qryGenerators: TDataSet;
    procedure PrepareDatasetProps(var DataSet: TDataSet);
    procedure PrepareComponents(aDatabase: TComponent);
  private
    FID: Integer;
    FCurCond: TStrings;
    procedure PrepareForm;
  public
    { Public declarations }
  end;

var
  frmEdDataSetInfo: TFIBDataSetInfoForm;

function ChooseDSInfo(ForDataSet: TDataSet): Boolean;
procedure EditDSInfo(aDatabase: TComponent);

implementation

uses
  TypInfo, RTTIRoutines, FIBEditorsConsts, FIBInterfaces, RegFIBEditors;

{$R *.dfm}

procedure EditDSInfo(aDatabase: TComponent);
begin
  if not Assigned(aDatabase) then
    Exit;
  if frmEdDataSetInfo = nil then
  begin
    frmEdDataSetInfo := TFIBDataSetInfoForm.Create(nil);
    frmEdDataSetInfo.PrepareForm
  end;
  with frmEdDataSetInfo do
    try
      PrepareComponents(aDatabase);
      ShowModal;
    finally
      frmEdDataSetInfo.Free;
      frmEdDataSetInfo := nil
    end;
end;

function ChooseDSInfo(ForDataSet: TDataSet): Boolean;
var
  DBCmp: TObject;
  ids: IFIBDataSet;
begin
  Result := false;
  if ForDataSet = nil then
    Exit;
  if frmEdDataSetInfo = nil then
  begin
    frmEdDataSetInfo := TFIBDataSetInfoForm.Create(nil);
    frmEdDataSetInfo.PrepareForm
  end;
  with frmEdDataSetInfo do
    try
      DBCmp := GetObjectProp(ForDataSet, 'Database');
      PrepareComponents(TComponent(DBCmp));
      qryDSInfo.Open;
      FID := GetPropValue(ForDataSet, 'DataSet_ID', false);
      with qryDSInfo do
        if FID > 0 then
          Locate('DS_ID', FID, []);
      Result := ShowModal = mrOk;
      if Result then
      begin
        SetPropValue(ForDataSet, 'DataSet_ID', qryDSInfo.FieldByName('DS_ID').asInteger);
        if ForDataSet.Active then
        begin
          ForDataSet.Close;
          ForDataSet.Open
        end
        else
        begin
          ObjSupports(ForDataSet, IFIBDataSet, ids);
          ids.LoadRepositoryInfo;
        end
      end;
      SetPropValue(trDSInfo, 'Active', 'False');
      qryDSInfo.Filtered := false;
    finally
      frmEdDataSetInfo.Free;
      frmEdDataSetInfo := nil
    end;
end;

procedure TFIBDataSetInfoForm.PrepareComponents(aDatabase: TComponent);
begin
  Db := aDatabase;
  trDSInfo := expTransactionClass.Create(frmEdDataSetInfo);
  SetObjectProp(trDSInfo, 'DefaultDataBase', aDatabase);

  PrepareDatasetProps(qryDSInfo);
  PrepareDatasetProps(qryGenerators);
  AssignStringsToProp(qryDSInfo, 'SelectSQL',
    'SELECT    FIB.DS_ID,    FIB.DESCRIPTION,    FIB.SELECT_SQL,    FIB.UPDATE_SQL,' +
    '  FIB.INSERT_SQL,    FIB.DELETE_SQL,    FIB.REFRESH_SQL,    FIB.NAME_GENERATOR,' +
    '  FIB.KEY_FIELD,    FIB.UPDATE_TABLE_NAME,    FIB.UPDATE_ONLY_MODIFIED_FIELDS,' +
    '    FIB.CONDITIONS,    FIB.FIB$VERSION ' +
    '  FROM    FIB$DATASETS_INFO FIB  ORDER BY 1');

  SetStringProperty(qryDSInfo, 'AutoUpdateOptions.KeyFields', 'DS_ID');
  SetStringProperty(qryDSInfo, 'AutoUpdateOptions.UpdateTableName', 'FIB$DATASETS_INFO');
  SetValueProperty(qryDSInfo, 'AutoUpdateOptions.AutoReWriteSqls', True);
  qryDSInfo.AfterDelete := qryDSInfoAfterDelete;
  qryDSInfo.AfterInsert := qryDSInfoAfterInsert;
  qryDSInfo.AfterScroll := qryDSInfoAfterScroll;

  DataSource1.DataSet := qryDSInfo;
  AssignStringsToProp(qryGenerators, 'SelectSQL',
    'SELECT     RDB$GENERATOR_NAME FROM    RDB$GENERATORS ' +
    'WHERE RDB$SYSTEM_FLAG IS NULL or RDB$SYSTEM_FLAG <>1 ORDER BY 1');

  SetPropValue(trDSInfo, 'Active', 'True');

  DBEdit2.Items.Clear;
  qryGenerators.Open;
  while not qryGenerators.Eof do
  begin
    DBEdit2.Items.Add(qryGenerators.Fields[0].asString);
    qryGenerators.Next
  end;
  qryDSInfo.Open;
end;

procedure TFIBDataSetInfoForm.qryDSInfoFilterRecord(DataSet: TDataSet; var Accept: Boolean);
begin
  Accept := Trim(Edit1.Text) <> '';
  if not Accept then
  begin
    Accept := Pos(UpperCase(Edit1.Text), UpperCase(DataSet.FieldByName('DESCRIPTION').asString)) > 0
  end;
end;

procedure TFIBDataSetInfoForm.Edit1Change(Sender: TObject);
begin
  qryDSInfo.Filtered := Trim(Edit1.Text) <> ''
end;

procedure TFIBDataSetInfoForm.FormCreate(Sender: TObject);
begin
  Caption := SEdDataSetInfoCaption;
  Label1.Caption := SEdDataSetInfoKeyField;
  Label2.Caption := SEdDataSetInfoGenerator;
  GroupBox2.Caption := SEdDataSetInfoFilter;
  Button1.Caption := SOKButton;
  Button2.Caption := SCancelButton;
end;

procedure TFIBDataSetInfoForm.Button1Click(Sender: TObject);
begin
  qryDSInfoBeforeScroll(qryDSInfo);
  if qryDSInfo.State in [dsEdit, dsInsert] then
    qryDSInfo.Post;
end;

procedure TFIBDataSetInfoForm.Button2Click(Sender: TObject);
begin
  qryDSInfo.Open;
  qryDSInfo.Locate('DS_ID', FID, []);
end;

procedure TFIBDataSetInfoForm.btnSaveClick(Sender: TObject);
begin
  if qryDSInfo.State in [dsEdit, dsInsert] then
    qryDSInfo.Post;
end;

procedure TFIBDataSetInfoForm.qryDSInfoAfterDelete(DataSet: TDataSet);
begin
  btnSave.Enabled := True;
end;

procedure TFIBDataSetInfoForm.qryDSInfoAfterInsert(DataSet: TDataSet);
begin
  btnSave.Enabled := True;
end;

procedure TFIBDataSetInfoForm.PrepareForm;
var
  DBMemo: TDBMemo;
  procedure CreateMemo;
  begin
    DBMemo := TDBMemo.Create(Self);
    DBMemo.ScrollBars := ssBoth;
    DBMemo.DataSource := DataSource1;
    DBMemo.Align := alClient;
  end;

begin
  FCurCond := TStringList.Create;
  CreateMemo;
  DBMemo.DataField := 'SELECT_SQL';
  DBMemo.Parent := TabSheet2;

  CreateMemo;
  DBMemo.DataField := 'INSERT_SQL';
  DBMemo.Parent := TabSheet4;

  CreateMemo;
  DBMemo.DataField := 'UPDATE_SQL';
  DBMemo.Parent := TabSheet3;

  CreateMemo;
  DBMemo.DataField := 'DELETE_SQL';
  DBMemo.Parent := TabSheet7;

  CreateMemo;
  DBMemo.DataField := 'REFRESH_SQL';
  DBMemo.Parent := TabSheet5;

end;

procedure TFIBDataSetInfoForm.qryDSInfoAfterScroll(DataSet: TDataSet);
begin
  if Assigned(FCurCond) then
  begin
    FCurCond.Text := qryDSInfo.FieldByName('CONDITIONS').asString;
    fraEdConditions1.PrepareFrame(FCurCond);
  end;
end;

procedure TFIBDataSetInfoForm.qryDSInfoBeforeScroll(DataSet: TDataSet);
var
  s: string;
begin
  s := FCurCond.Text;
  fraEdConditions1.ApplyChanges;
  if FCurCond.Text <> s then
  begin
    if not(qryDSInfo.State in [dsEdit, dsInsert]) then
      qryDSInfo.Edit;
    qryDSInfo.FieldByName('CONDITIONS').asString := FCurCond.Text;
    qryDSInfo.Post;

  end;
end;

procedure TFIBDataSetInfoForm.qryDSInfoNewRecord(DataSet: TDataSet);
begin
  DataSet.FieldByName('UPDATE_ONLY_MODIFIED_FIELDS').asInteger := 0
end;

procedure TFIBDataSetInfoForm.Panel2Resize(Sender: TObject);
begin
  DBGrid1.Columns[1].Width := DBGrid1.Width - ScaleToPPI(Self, 90);
end;

procedure TFIBDataSetInfoForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FCurCond.Free
end;

procedure TFIBDataSetInfoForm.PrepareDatasetProps(var DataSet: TDataSet);
begin
  DataSet := TDataSet(expDatasetClass.Create(frmEdDataSetInfo));
  SetObjectProp(DataSet, 'DataBase', Db);
  SetObjectProp(DataSet, 'Transaction', trDSInfo);
  SetPropValue(DataSet, 'AutoCommit', 'True');
end;

end.
