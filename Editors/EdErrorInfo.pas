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

unit EdErrorInfo;

interface
{$i ..\FIBPlus.inc}

uses
 {$IFDEF WINDOWS}
  TypInfo,Windows, Messages, SysUtils, Classes,
  {$IFDEF D_XE2}
   Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,Vcl.Grids,
   Vcl.DBGrids, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.DBCtrls, Vcl.Buttons, Vcl.Menus,
  {$ELSE}
  Graphics, Controls, Forms, Dialogs,Grids,
  DBGrids, ExtCtrls, StdCtrls, DBCtrls, Buttons, Menus,
  {$ENDIF}

   Db,  uFIBEditorForm

   {$IFDEF D6+}, Variants {$ENDIF}
    ,RegistryUtils

;
 {$ENDIF}

type
  TfrmErrors = class(TFIBEditorCustomForm)
    Panel1: TPanel;
    Panel2: TPanel;
    btnCopyConstraints: TButton;
    chFilt: TCheckBox;
    cmbKindObjs: TComboBox;
    Panel3: TPanel;
    Panel4: TPanel;
    sbDBGrid2: TDBGrid;
    EdFilter: TEdit;
    DataSource1: TDataSource;
    DBText1: TDBText;
    Label1: TLabel;
    Label2: TLabel;
    DataSource2: TDataSource;
    Panel5: TPanel;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    procedure cmbKindObjsChange(Sender: TObject);
    procedure btnCopyConstraintsClick(Sender: TObject);
    procedure EdFilterChange(Sender: TObject);
    procedure qryConstraintsFilterRecord(DataSet: TDataSet;
      var Accept: Boolean);
    procedure chFiltClick(Sender: TObject);
    procedure qryErrorMessagesFilterRecord(DataSet: TDataSet;
      var Accept: Boolean);
    procedure DataSource1DataChange(Sender: TObject; Field: TField);
    procedure sbDBGrid2DblClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    pFIBTransaction1:TComponent;
    qryAllErrors    ,
    qryConstraints,
    qryUniqueIndices,
    qryErrorMessages: TDataSet;
  public
    { Public declarations }
  end;

var
  frmErrors: TfrmErrors;

  procedure ShowErrorInfo( aDataBase:TComponent);

implementation

uses pFIBInterfaces, RTTIRoutines, RegFIBPlusEditors;

{$R *.dfm}

const
 RegSectionName='ErrorRepositoryEditor';



procedure  PrepareDataSetProps(DataSet,Database,Transaction:TComponent);
begin
    SetObjectProp(DataSet,'DataBase',Database);
    SetObjectProp(DataSet,'Transaction',Transaction);
    SetPropValue(DataSet,'AutoCommit','True');
end;



procedure ShowErrorInfo( aDataBase:TComponent);

var
  ts:TStrings;
begin
  frmErrors:= TfrmErrors.Create(nil);
  ts:=TStringList.Create;
  with frmErrors do
  try
    pFIBTransaction1:= expTransactionClass.Create(frmErrors);
    SetObjectProp(pFIBTransaction1,'DefaultDataBase',aDatabase);
    SetEnumProp(pFIBTransaction1,'TimeoutAction','TACommitRetaining');

    qryAllErrors:=TDataSet(expDatasetClass.Create(frmErrors));
    qryConstraints:=TDataSet(expDatasetClass.Create(frmErrors));
    qryUniqueIndices:=TDataSet(expDatasetClass.Create(frmErrors));
    qryErrorMessages:=TDataSet(expDatasetClass.Create(frmErrors));

    PrepareDataSetProps(qryAllErrors,aDatabase,pFIBTransaction1);
    PrepareDataSetProps(qryConstraints,aDatabase,pFIBTransaction1);
    PrepareDataSetProps(qryUniqueIndices,aDatabase,pFIBTransaction1);
    PrepareDataSetProps(qryErrorMessages,aDatabase,pFIBTransaction1);

    qryErrorMessages.OnFilterRecord:=qryErrorMessagesFilterRecord;
    qryConstraints.OnFilterRecord:=qryConstraintsFilterRecord;
    qryAllErrors.OnFilterRecord:=qryConstraintsFilterRecord;
    qryUniqueIndices.OnFilterRecord:=qryConstraintsFilterRecord;


    DataSource1.DataSet:=qryConstraints;
    DataSource2.DataSet:=qryErrorMessages;

    ts.Text:='SELECT  CONSTRAINT_NAME, MESSAGE_STRING,constr_type '#13#10+
    'FROM FIB$ERROR_MESSAGES M '#13#10+
    'WHERE (M.constr_type = :T OR :T=''ALL  ERRORS'')';
    SetObjectProp(qryErrorMessages,'SelectSQL',ts);


    ts.Text:='INSERT INTO FIB$ERROR_MESSAGES(  CONSTRAINT_NAME,  MESSAGE_STRING,   CONSTR_TYPE)'#13#10+
    'VALUES( :CONSTRAINT_NAME,    :MESSAGE_STRING,    :CONSTR_TYPE)';
    SetObjectProp(qryErrorMessages,'InsertSQL',ts);

    ts.Text:='DELETE FROM FIB$ERROR_MESSAGES WHERE  CONSTRAINT_NAME = :OLD_CONSTRAINT_NAME';
    SetObjectProp(qryErrorMessages,'DeleteSQL',ts);
    ts.Text:=
    'UPDATE FIB$ERROR_MESSAGES SET     CONSTRAINT_NAME = :CONSTRAINT_NAME, MESSAGE_STRING = :MESSAGE_STRING'#13#10+
    'WHERE  CONSTRAINT_NAME = :OLD_CONSTRAINT_NAME';
    SetObjectProp(qryErrorMessages,'UpdateSQL',ts);


    ts.Text:=
   'select rdb$index_name rdb$constraint_name, rdb$relation_name from rdb$indices r '#13#10+
   'where rdb$unique_flag=1 and  (rdb$system_flag is null or rdb$system_flag=0)'#13#10+
   'and not exists('#13#10+
   'Select * from rdb$relation_constraints c where r.rdb$index_name=c.rdb$index_name)'#13#10+
   'union Select r.rdb$constraint_name,r.rdb$relation_name from  RDB$RELATION_CONSTRAINTS r'#13#10+
   'order by 1';
    SetObjectProp(qryAllErrors,'SelectSQL',ts);


    ts.Text:=
    'Select r.rdb$constraint_name,r.rdb$relation_name from RDB$RELATION_CONSTRAINTS r'#13#10+
    'where r.rdb$constraint_type =:T order by 1';
    SetObjectProp(qryConstraints,'SelectSQL',ts);

    ts.Text:=
    'select rdb$index_name rdb$constraint_name, rdb$relation_name from rdb$indices r'#13#10+
    'where  rdb$unique_flag=1 and  (rdb$system_flag is null or rdb$system_flag=0)'#13#10+
    'and not exists('#13#10+
    'Select * from rdb$relation_constraints c where r.rdb$index_name=c.rdb$index_name)'#13#10+
    'order by 1';
    SetObjectProp(qryUniqueIndices,'SelectSQL',ts);

    cmbKindObjs.ItemIndex:=0;
    cmbKindObjsChange(cmbKindObjs);
    ShowModal;
  finally
    ts.Free;
    frmErrors.Free
  end;
end;

procedure TfrmErrors.cmbKindObjsChange(Sender: TObject);
var ds:TDataSet;
    ids:  IFIBDataSet;
    s:string;
begin
 case cmbKindObjs.ItemIndex of
  0:  ds:=qryAllErrors;
  5:  ds:=qryUniqueIndices;
 else
  ds:=qryConstraints
 end;
 ObjSupports(ds,IFIBDataSet,ids);
 with ds do
 begin
  s:='';
  case cmbKindObjs.ItemIndex of
//    0: Params[0].asString:='ALL  ERRORS';
    1: s:='PRIMARY KEY';
    2: s:='UNIQUE';
    3: s:='FOREIGN KEY';
    4: s:='CHECK';
  end;
  if s<>'' then
   ids.SetParamValue(0,s);
  Close;
  Open;
  DataSource1.DataSet:=ds;
  ObjSupports(qryErrorMessages,IFIBDataSet,ids);
   case cmbKindObjs.ItemIndex of
    0:  ids.SetParamValue(0,'ALL  ERRORS');
    5:  ids.SetParamValue(0,'UN_INDEX');
   else
    ids.SetParamValue(0,s);
   end;
  qryErrorMessages.Close;
  qryErrorMessages.Open;
 end;
end;

procedure TfrmErrors.btnCopyConstraintsClick(Sender: TObject);
var
   vName:string;
   ids:  IFIBDataSet;
begin
 vName:=sbDBGrid2.DataSource.DataSet.FieldByName('rdb$constraint_name').AsString;
 with qryErrorMessages do
 if not Locate('CONSTRAINT_NAME',vName,[]) then
 begin
  ObjSupports(qryErrorMessages,IFIBDataSet,ids);
  Insert;
  FieldByName('CONSTRAINT_NAME').AsString := vName;
  FieldByName('constr_type').AsString     := VarToStr(ids.ParamValue(0));
  Post
 end;
end;

procedure TfrmErrors.EdFilterChange(Sender: TObject);
begin
 with sbDBGrid2.DataSource.DataSet do
 begin
  Filtered:=False;
  Filtered:=Trim(EdFilter.Text)<>'';
 end;
end;

procedure TfrmErrors.qryConstraintsFilterRecord(DataSet: TDataSet;
  var Accept: Boolean);
begin

  with DataSet do
  begin
   Accept:=Pos(Trim(EdFilter.text),
      UpperCase(FieldByName('rdb$constraint_name').asString)
   )>0;
   if not Accept then
    Accept:=Pos(Trim(EdFilter.text),
      UpperCase(FieldByName('rdb$relation_name').asString)
    )>0;
  end;
end;

procedure TfrmErrors.chFiltClick(Sender: TObject);
begin
 qryErrorMessages.Filtered:=chFilt.Checked; 
end;

procedure TfrmErrors.qryErrorMessagesFilterRecord(DataSet: TDataSet;
  var Accept: Boolean);
begin
 Accept:=qryErrorMessages.FieldByName('CONSTRAINT_NAME').AsString=
   sbDBGrid2.DataSource.DataSet.FieldByName('rdb$constraint_name').asString
end;

procedure TfrmErrors.DataSource1DataChange(Sender: TObject; Field: TField);
begin
  if chFilt.Checked then
  begin
   qryErrorMessages.Filtered:=False;
   qryErrorMessages.Filtered:=True;
  end
end;

procedure TfrmErrors.sbDBGrid2DblClick(Sender: TObject);
begin
 btnCopyConstraintsClick(btnCopyConstraints)
end;


procedure TfrmErrors.FormClose(Sender: TObject; var Action: TCloseAction);
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

if qryErrorMessages.State in [dsEdit,dsInsert] then
 qryErrorMessages.Post;
  
end;

procedure TfrmErrors.FormCreate(Sender: TObject);
var
  v:Variant;
begin


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

end.
