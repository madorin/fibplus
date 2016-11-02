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


unit EdDataSetInfo;

interface

uses
{$I ..\FIBPlus.inc}
  Windows, Messages,  Classes,SysUtils,Db,
   {$IFDEF D_XE2}
  Vcl.Graphics, Vcl.Controls, Vcl.Forms,  Vcl.Dialogs, Vcl.ComCtrls, Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.Grids, Vcl.DBGrids,Vcl.DBCtrls,Vcl.Mask,
  {$ELSE}
  Graphics, Controls, Forms,  Dialogs, ComCtrls, ExtCtrls, StdCtrls,
  Grids, DBGrids,DBCtrls,Mask,
  {$ENDIF}

  uFIBEditorForm,  fraConditionsEdit
    {$IFDEF D6+}, Variants {$ENDIF}
   ;



type
  TfrmEdDataSetInfo = class(TFIBEditorCustomForm)
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
    fraEdConditions1: TfraEdConditions;
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
    procedure qryDSInfoFilterRecord(DataSet: TDataSet;
      var Accept: Boolean);
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
   DB:TComponent;
   trDSInfo:TComponent;
   qryDSInfo:TDataSet;
   qryGenerators:TDataSet;
   procedure PrepareDatasetProps(var DataSet:TDataSet);
   procedure PrepareComponents(aDatabase:TComponent);
  private
    FID:integer;
    FCurCond: TStrings;
    procedure PrepareForm;
  public
    { Public declarations }
  end;

var
  frmEdDataSetInfo: TfrmEdDataSetInfo;

function  ChooseDSInfo(ForDataSet:TDataSet):boolean;
procedure EditDSInfo(aDatabase:TComponent);

implementation

uses
 TypInfo,RTTIRoutines, pFIBEditorsConsts, pFIBInterfaces,  RegFIBPlusEditors,RegistryUtils
 {$IFDEF USE_SYN_EDIT}
  SynEdit, SynDBEdit,SynHighlighterSQL
 {$ENDIF}
;

{$R *.dfm}

{$IFDEF USE_SYN_EDIT}
var
    SynSQLSyn1 :TSynSQLSyn;
{$ENDIF}


const
 RegSectionName='DataSetRepositoryEditor';



procedure EditDSInfo(aDatabase:TComponent);
begin
 if not Assigned(aDatabase) then Exit;
 if frmEdDataSetInfo=nil then
 begin
  frmEdDataSetInfo:=TfrmEdDataSetInfo.Create(nil);
  frmEdDataSetInfo.PrepareForm
 end;
// with frmEdDataSetInfo,frmEdDataSetInfo.qryDSInfo do
 with frmEdDataSetInfo do
 try
   PrepareComponents(aDatabase);
  ShowModal;
 finally
   frmEdDataSetInfo.Free;
   frmEdDataSetInfo:=nil
 end;
end;


function ChooseDSInfo(ForDataSet:TDataSet):boolean;
var DBCmp:TObject;
    ids:IFIBDataSet;
begin
 Result:=false;
 if ForDataSet=nil then Exit;
 if frmEdDataSetInfo=nil then
 begin
  frmEdDataSetInfo:=TfrmEdDataSetInfo.Create(nil);
  frmEdDataSetInfo.PrepareForm
 end;
 with frmEdDataSetInfo do
 try
  DBCmp:= GetObjectProp(ForDataSet,'Database');
  PrepareComponents(TComponent(DBCmp));
{  trDSInfo:=
   TComponentClass(FIBClassesExporter.iGetTransactionClass).Create(frmEdDataSetInfo);
  SetObjectProp(trDSInfo,'DefaultDataBase',DBCmp);


  DataBase         :=ForDataSet.DataBase;
  trDSInfo.StartTransaction;
  UpdateTransaction:=trDSInfo;
  try
   Prepare;
  except
   Update2RepositaryTable(trDSInfo);
   trDSInfo.CommitRetaining
  end;}
  qrydsinfo.Open;
  FID:=GetPropValue(ForDataSet,'DataSet_ID',False);
  with qryDSInfo do
  if FID>0 then
   Locate('DS_ID',FID,[]);
   Result:=ShowModal=mrOk;
   if Result then
   begin
    SetPropValue(ForDataSet,'DataSet_ID',qryDSInfo.FieldByName('DS_ID').asInteger);
//    ListDataSetInfo.ClearDSInfo(ForDataSet);
    if ForDataSet.Active then
    begin
     ForDataSet.Close;
     ForDataSet.Open
    end
    else
    begin
     ObjSupports(ForDataSet,IFIBDataSet,ids);
     ids.LoadRepositoryInfo;
    end
   end;
    SetPropValue(trDSInfo,'Active','False');
    qrydsinfo.Filtered:=false;
 finally
   frmEdDataSetInfo.Free;
   frmEdDataSetInfo:=nil
 end;
end;

procedure TfrmEdDataSetInfo.PrepareComponents(aDatabase:TComponent);
begin
  DB:=aDatabase;
  trDSInfo:= expTransactionClass.Create(frmEdDataSetInfo);
  SetObjectProp(trDSInfo,'DefaultDataBase',aDatabase);
//  trDSInfo.DefaultDataBase:=aDatabase;

  PrepareDatasetProps(qryDSInfo);
  PrepareDatasetProps(qryGenerators);
  AssignStringsToProp(qryDSInfo,'SelectSQL',
  'SELECT    FIB.DS_ID,    FIB.DESCRIPTION,    FIB.SELECT_SQL,    FIB.UPDATE_SQL,'+
  '  FIB.INSERT_SQL,    FIB.DELETE_SQL,    FIB.REFRESH_SQL,    FIB.NAME_GENERATOR,'+
  '  FIB.KEY_FIELD,    FIB.UPDATE_TABLE_NAME,    FIB.UPDATE_ONLY_MODIFIED_FIELDS,'+
  '    FIB.CONDITIONS,    FIB.FIB$VERSION '+
  '  FROM    FIB$DATASETS_INFO FIB  ORDER BY 1'
  );

  SetStringProperty(qryDSInfo,'AutoUpdateOptions.KeyFields','DS_ID');
  SetStringProperty(qryDSInfo,'AutoUpdateOptions.UpdateTableName','FIB$DATASETS_INFO');
  SetValueProperty(qryDSInfo,'AutoUpdateOptions.AutoReWriteSqls',True);
  qryDSInfo.AfterDelete:=qryDSInfoAfterDelete;
  qryDSInfo.AfterInsert:=qryDSInfoAfterInsert;
  qryDSInfo.AfterScroll:=qryDSInfoAfterScroll;

  DataSource1.DataSet:=qryDSInfo;
  AssignStringsToProp(qryGenerators,'SelectSQL',
   'SELECT     RDB$GENERATOR_NAME FROM    RDB$GENERATORS '+
   'WHERE RDB$SYSTEM_FLAG IS NULL or RDB$SYSTEM_FLAG <>1 ORDER BY 1'
  );

  SetPropValue(trDSInfo,'Active','True');

  DBEdit2.Items.Clear;
  qryGenerators.Open;
  while not qryGenerators.Eof do
  begin
   DBEdit2.Items.Add(qryGenerators.Fields[0].asString);
   qryGenerators.Next
  end;
  qryDSInfo.Open;
end;

procedure TfrmEdDataSetInfo.qryDSInfoFilterRecord(DataSet: TDataSet;
  var Accept: Boolean);
begin
 Accept:=Trim(Edit1.Text)<>'';
 if not Accept then
 begin
  Accept:=Pos(UpperCase(Edit1.Text),UpperCase(DataSet.FieldByName('DESCRIPTION').asString))>0
 end;
end;

procedure TfrmEdDataSetInfo.Edit1Change(Sender: TObject);
begin
 qryDSInfo.Filtered:=Trim(Edit1.Text)<>''
end;

procedure TfrmEdDataSetInfo.FormCreate(Sender: TObject);
var
  v:Variant;
begin        
  Caption := SEdDataSetInfoCaption;
//  TabSheet1.Caption := SEdDataSetInfoFields;
  Label1.Caption := SEdDataSetInfoKeyField;
  Label2.Caption := SEdDataSetInfoGenerator;
  GroupBox2.Caption := SEdDataSetInfoFilter;
  Button1.Caption := SOKButton;
  Button2.Caption := SCancelButton;
 {$IFDEF USE_SYN_EDIT}
 SynSQLSyn1 :=TSynSQLSyn.Create(Self);
 with SynSQLSyn1 do
 begin
      DefaultFilter:= 'SQL files (*.sql)|*.sql';
      CommentAttri.Foreground := clBlue;
      NumberAttri.Foreground  := clRed ;
      StringAttri.Background  := clInactiveBorder;
      SQLDialect              := sqlInterbase6;
 end;
 {$ENDIF}


  v:=DefReadFromRegistry(['Software',RegFIBRoot,RegRepository,RegSectionName],
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

end;

procedure TfrmEdDataSetInfo.Button1Click(Sender: TObject);
begin
  qryDSInfoBeforeScroll(qryDSInfo);
  if qryDSInfo.State in [dsEdit,dsInsert] then
   qryDSInfo.Post;
//  qryDSInfo.UpdateTransaction.CommitRetaining;
end;

procedure TfrmEdDataSetInfo.Button2Click(Sender: TObject);
begin
 qryDSInfo.Open;
 qryDSInfo.Locate('DS_ID',FID,[]);
end;

procedure TfrmEdDataSetInfo.btnSaveClick(Sender: TObject);
begin
  if qryDSInfo.State in [dsEdit,dsInsert] then
   qryDSInfo.Post;
end;

procedure TfrmEdDataSetInfo.qryDSInfoAfterDelete(DataSet: TDataSet);
begin
 btnSave.Enabled:=True;
end;

procedure TfrmEdDataSetInfo.qryDSInfoAfterInsert(DataSet: TDataSet);
begin
 btnSave.Enabled:=True;
end;

{$IFDEF USE_SYN_EDIT}
 type THackDBSynEdit=class(TDBSynEdit);
{$ENDIF}

procedure TfrmEdDataSetInfo.PrepareForm;
var
 {$IFDEF USE_SYN_EDIT}
   DBMemo: TDBSynEdit;
 {$ELSE}
   DBMemo: TDBMemo;
 {$ENDIF}

procedure CreateMemo;
begin
 {$IFDEF USE_SYN_EDIT}
   DBMemo:=TDBSynEdit.Create(Self);
  {$IFNDEF SYNEDIT_05_2004}
    DBMemo.OnChange:=THackDBSynEdit(DBMemo).NewOnChange;
  {$ENDIF}
   DBMemo.Highlighter:=SynSQLSyn1;
 {$ELSE}
   DBMemo:= TDBMemo.Create(Self);
   DBMemo.ScrollBars:=ssBoth;
 {$ENDIF}
 DBMemo.DataSource:=DataSource1;
 DBMemo.Align     :=alClient;
end;

begin
//  FCurCond:= TConditions.Create(Self);
  FCurCond:=TStringList.Create; 
  CreateMemo;
  DBMemo.DataField:='SELECT_SQL';
  DBMemo.Parent   :=TabSheet2;

  CreateMemo;
  DBMemo.DataField:='INSERT_SQL';
  DBMemo.Parent   :=TabSheet4;

  CreateMemo;
  DBMemo.DataField:='UPDATE_SQL';
  DBMemo.Parent   :=TabSheet3;

  CreateMemo;
  DBMemo.DataField:='DELETE_SQL';
  DBMemo.Parent   :=TabSheet7;

  CreateMemo;
  DBMemo.DataField:='REFRESH_SQL';
  DBMemo.Parent   :=TabSheet5;

end;

procedure TfrmEdDataSetInfo.qryDSInfoAfterScroll(DataSet: TDataSet);
begin
   if Assigned(FCurCond) then
   begin
    FCurCond.Text:=qryDSInfo.FieldByName('CONDITIONS').asString;
    fraEdConditions1.PrepareFrame(FCurCond);
   end;
end;

procedure TfrmEdDataSetInfo.qryDSInfoBeforeScroll(DataSet: TDataSet);
var s:string;
begin
  s:=FCurCond.Text;
  fraEdConditions1.ApplyChanges;
  if FCurCond.Text<>s then
  begin
    if not (qryDSInfo.State in [dsEdit,dsInsert]) then
       qryDSInfo.Edit;
    qryDSInfo.FieldByName('CONDITIONS').asString:=FCurCond.Text;
    qryDSInfo.Post;

  end;
end;

procedure TfrmEdDataSetInfo.qryDSInfoNewRecord(DataSet: TDataSet);
begin
 DataSet.FieldByName('UPDATE_ONLY_MODIFIED_FIELDS').AsInteger:=0
end;

procedure TfrmEdDataSetInfo.Panel2Resize(Sender: TObject);
begin
 DBGrid1.Columns[1].Width:=DBGrid1.Width-90;
end;

procedure TfrmEdDataSetInfo.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
 if WindowState=wsMaximized then
 begin
  WindowState:=wsNormal;
  DefWriteToRegistry(['Software',RegFIBRoot,RegRepository,RegSectionName],
      ['Top','Left','Height','Width','Maximized'],
       [Top,Left,Height,Width, True]
  );
 end
 else
  DefWriteToRegistry(['Software',RegFIBRoot,RegRepository,RegSectionName],
      ['Top','Left','Height','Width','Maximized'],
       [Top,Left,Height,Width, False]
  );
 FCurCond.Free  
end;


procedure TfrmEdDataSetInfo.PrepareDatasetProps(var DataSet:TDataSet);
begin
  DataSet:=TDataSet(expDatasetClass.Create(frmEdDataSetInfo));
  SetObjectProp(DataSet,'DataBase',DB);
  SetObjectProp(DataSet,'Transaction',trDSInfo);
  SetPropValue(DataSet,'AutoCommit','True');
end;

end.
