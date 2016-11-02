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
unit fraAutoUpdEditor;

interface

  {$I ..\FIBPlus.inc}
uses
     Windows,SysUtils,

      {$IFDEF D_XE2}
  Vcl.Graphics, Vcl.Controls, Vcl.Forms,  Vcl.Dialogs, Vcl.ComCtrls, Vcl.ExtCtrls,
  Vcl.StdCtrls,
  {$ELSE}
  Graphics, Controls, Forms,  Dialogs, ComCtrls, ExtCtrls, StdCtrls,
  {$ENDIF}
     Db,uFIBEditorForm, Classes
     ;

type
  TFrame=TFIBEditorCustomFrame;// Fake for D5
  TfAutoUpdateOptionForm = class(TFrame)
    GroupBox1: TGroupBox;
    AllowChangeC: TCheckBox;
    AutoGenC: TCheckBox;
    ModFieldsC: TCheckBox;
    PrimaryKeyL: TLabel;
    KeyC: TComboBox;
    GroupBox2: TGroupBox;
    ModTableL: TLabel;
    TableC: TComboBox;
    GenNameL: TLabel;
    GenC: TComboBox;
    WhenGetC: TComboBox;
    Label1: TLabel;
    edGenStep: TEdit;
    procedure AutoGenCClick(Sender: TObject);
    procedure edGenStepKeyPress(Sender: TObject; var Key: Char);
  private
  public
    FDataSet: TDataSet;

    procedure PrepareControls;
    procedure ApplyToDataSet;
  end;



implementation

uses TypInfo,pFIBEditorsConsts, RTTIRoutines, RegFIBPlusEditors,
  pFIBInterfaces
     {$IFDEF D6+}
     ,Variants
     {$ENDIF}
  ;


{$R *.dfm}


procedure TfAutoUpdateOptionForm.AutoGenCClick(Sender: TObject);
begin
  ModFieldsC.Enabled := AutoGenC.Checked;
  if not ModFieldsC.Enabled then ModFieldsC.Checked := False;
end;

procedure TfAutoUpdateOptionForm.PrepareControls;
var
  Qry: TComponent;
  Trans: TComponent;
  DB:TComponent;
  iQry:IFIBQuery;
  SQLText:string;

begin
  PrimaryKeyL.Caption := FPAutoOptEditorPrimaryKey;
  ModTableL.Caption   := FPAutoOptEditorModTable;
  GroupBox1.Caption   := FPAutoOptEditorSQL;
//  AllowChangeC.Caption:= FPAutoOptEditorAllowChange;
  AutoGenC.Caption    := FPAutoOptEditorAutoGen;
  ModFieldsC.Caption  := FPAutoOptEditorModFields;
  GroupBox2.Caption   := FPAutoOptEditorAutoInc;
  GenNameL.Caption    := FPAutoOptEditorGenName;
  WhenGetC.Items.Add(FPAutoOptEditorWhenGet1);
  WhenGetC.Items.Add(FPAutoOptEditorWhenGet2);
  WhenGetC.Items.Add(FPAutoOptEditorWhenGet3);
  SQLText:=TStrings(GetObjectProp(FDataSet,'SelectSQL')).Text;
  FIBClassesExporter.iGetStringer.AllTables(SQLText, TableC.Items);
{ TODO : может ключ поля заполнить + добавить новые опции }

  begin
    AllowChangeC.Checked := GetSubPropValue(FDataSet,'AutoUpdateOptions.CanChangeSQLs');
    AutoGenC.Checked     := GetSubPropValue(FDataSet,'AutoUpdateOptions.AutoReWriteSqls');

    ModFieldsC.Checked   := GetSubPropValue(FDataSet,'AutoUpdateOptions.UpdateOnlyModifiedFields');

    KeyC.Text            := GetSubPropValue(FDataSet,'AutoUpdateOptions.KeyFields');

    TableC.Text          := GetSubPropValue(FDataSet,'AutoUpdateOptions.UpdateTableName');
    GenC.Text            := GetSubPropValue(FDataSet,'AutoUpdateOptions.GeneratorName');

    WhenGetC.ItemIndex   := GetSubPropValue(FDataSet,'AutoUpdateOptions.WhenGetGenID');
    edGenStep.Text       := IntToStr(GetSubPropValue(FDataSet,'AutoUpdateOptions.GeneratorStep'));

  end;


  DB:=TComponent(GetObjectProp(FDataSet,'DataBase'));
  if DB= nil then exit;
//  if FDataSet.Database = nil then exit;
  GenC.Items.Clear;

 Qry := nil; Trans := nil;
 try
  Qry := expQueryClass.Create(nil);
  if not ObjSupports(Qry,IFIBQuery,iQry) then
   Exit;
  Trans:=expTransactionClass.Create(nil);
  SetPropValue(Qry,'ParamCheck','False');
  SetObjectProp(Qry,'Database',DB);
  SetObjectProp(Qry,'Transaction',Trans);
  SetObjectProp(Trans,'DefaultDatabase',DB);
  AssignStringsToProp(Qry,'SQL',
   'select RDB$GENERATOR_NAME '+
                  'from RDB$GENERATORS '+
   'where (RDB$SYSTEM_FLAG is NULL) or (RDB$SYSTEM_FLAG = 0)'+
                  'order by RDB$GENERATOR_NAME'
  );
  try
   SetPropValue(Trans,'Active','True');
   iQry.ExecQuery;

     while not iQry.IEof do
     begin
       GenC.Items.Add(Trim(VarToStr(iQry.FieldValue('RDB$GENERATOR_NAME',False))));
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
 end
end;

procedure TfAutoUpdateOptionForm.edGenStepKeyPress(Sender: TObject;
  var Key: Char);
begin
 if not  (Key in ['0'..'9',Char(VK_DELETE),Char(VK_BACK)]) then Abort;
end;

procedure TfAutoUpdateOptionForm.ApplyToDataSet;
begin
 SetValueProperty(FDataSet,'AutoUpdateOptions.CanChangeSQLs',AllowChangeC.Checked);
 SetValueProperty(FDataSet,'AutoUpdateOptions.AutoReWriteSqls',AutoGenC.Checked);
 SetValueProperty(FDataSet,'AutoUpdateOptions.UpdateOnlyModifiedFields',ModFieldsC.Checked);
 SetValueProperty(FDataSet,'AutoUpdateOptions.KeyFields',KeyC.Text);
 SetValueProperty(FDataSet,'AutoUpdateOptions.UpdateTableName',TableC.Text);
 SetValueProperty(FDataSet,'AutoUpdateOptions.GeneratorName',GenC.Text);
 SetValueProperty(FDataSet,'AutoUpdateOptions.WhenGetGenID',WhenGetC.ItemIndex);
 if edGenStep.Text<>'' then
  SetValueProperty(FDataSet,'AutoUpdateOptions.GeneratorStep',StrToInt(edGenStep.Text));



end;

end.
