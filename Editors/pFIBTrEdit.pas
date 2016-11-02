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


unit pFIBTrEdit;
{$I ..\FIBPlus.inc}

interface

uses
 {$IFDEF WINDOWS}
  Windows, Messages, SysUtils, Classes,
   {$IFDEF D_XE2}
  Vcl.Graphics, Vcl.Controls, Vcl.Forms,  Vcl.Dialogs, Vcl.ComCtrls, Vcl.ExtCtrls,
  Vcl.StdCtrls,
  {$ELSE}
  Graphics, Controls, Forms,  Dialogs, ComCtrls, ExtCtrls, StdCtrls,
  {$ENDIF}
  uFIBEditorForm ;
 {$ENDIF}

type
  TfrmTransEdit = class(TFIBEditorCustomForm)
    cmbProps: TComboBox;
    Label1: TLabel;
    memParams: TMemo;
    Label2: TLabel;
    Button1: TButton;
    Button2: TButton;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    Bevel1: TBevel;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    procedure cmbPropsChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
  private
   FTransaction:TComponent;
   procedure ReadUsersKinds;
  public
    { Public declarations }
  end;

var
  frmTransEdit: TfrmTransEdit;

  function EditFIBTrParams(Transaction:TComponent):boolean;

implementation

{$R *.dfm}

uses
 {$IFDEF D6+}Variants, {$endif}
  TypInfo,RegistryUtils, pFIBEditorsConsts, RTTIRoutines;

  function  EditFIBTrParams(Transaction:TComponent):boolean;
  var b:boolean;
  begin
   if frmTransEdit=nil then
     frmTransEdit:=TfrmTransEdit.Create(nil);
   with frmTransEdit do
   try
    Caption:= STransEditCaption + ' :'+Transaction.Name+'.';
    FTransaction:=Transaction;

    memParams.Lines.Assign(
         TStrings(GetObjectProp(Transaction,'TRParams'))
    );
    Result:=ShowModal=mrOk;
    if Result then
    begin
      b:=GetPropValue(Transaction,'Active',False);

      if b then
       SetPropValue(Transaction,'Active','False');

      SetEnumProp(Transaction,'TPBMode','tpbDefault');
      AssignStringsToProp(Transaction,'TRParams',memParams.Text);
//      Transaction.TRParams.Text:=memParams.Text;
      if b then
        SetPropValue(Transaction,'Active','True');
    end;
   finally
    frmTransEdit.Free;
    frmTransEdit:=nil;
   end;
  end;

procedure TfrmTransEdit.cmbPropsChange(Sender: TObject);
var v:Variant;
    b:boolean;
begin
 memParams.Clear;
{$IFNDEF NO_REGISTRY}
 v:=  DefReadFromRegistry(
  ['Software',RegFIBRoot,RegFIBTrKinds,IntToStr(cmbProps.ItemIndex)],
   ['Name']
 );

 with memParams.Lines do
 begin
   b:=(VarType(v)<>varBoolean) and (v[0,0]=cmbProps.Text);
   if b then
   begin
    v:=DefReadFromRegistry(['Software',RegFIBRoot,RegFIBTrKinds,IntToStr(cmbProps.ItemIndex)],
     ['Params']);
    b:=(VarType(v)<>varBoolean);
    if b then Text:= v[0,0]
   end;
 end;
{$ELSE}
  b:=False;
{$ENDIF}
  if not b then
  with memParams.Lines do
  case cmbProps.ItemIndex of
    0: begin
        if Assigned(FTransaction) then
          memParams.Lines.Assign(
               TStrings(GetObjectProp(FTransaction,'TRParams'))
          );

  //       memParams.Lines.Assign(FTransaction.TRParams);
       end;
    1: begin
         Add('write');
         Add('nowait');
         Add('rec_version');
         Add('read_committed');
       end;
    2: begin
         Add('write');
         Add('nowait');
         Add('concurrency');
       end;
    3: begin
          Add('read');
         Add('nowait');
         Add('rec_version');
         Add('read_committed');
    end;
  end;
end;

procedure TfrmTransEdit.FormCreate(Sender: TObject);
begin
  ReadUsersKinds;
  cmbProps.ItemIndex:=0;
  cmbPropsChange(nil);

  Caption := STransEditCaption;
  Label1.Caption := STransEditKind;
  Label2.Caption := STransEditSettings;
  Button3.Caption := STransEditNewKind;
  Button4.Caption :=  STransEditSaveKindButton;
  Button5.Caption := STransEditExportButton;
  Button6.Caption := STransEditImportButton;
  OpenDialog1.Filter := STransEditOpenFilter;
  SaveDialog1.Filter := STransEditSaveFilter;
  SaveDialog1.Title := STransEditExportTitle;

  Button1.Caption := SOKButton;
  Button2.Caption := SCancelButton;
end;

procedure TfrmTransEdit.Button3Click(Sender: TObject);
var s:string;
begin
 if InputQuery(STransEditNewKindDialog, STransEditNewKindName ,s) then
 with cmbProps.Items do
  if IndexOf(s)=-1 then
  begin
   Add(s);
   cmbProps.ItemIndex:=Count-1;
  end;
end;

procedure TfrmTransEdit.Button4Click(Sender: TObject);

begin
{$IFNDEF NO_REGISTRY}
  with cmbProps do
  begin
   DefWriteToRegistry(['Software',RegFIBRoot,RegFIBTrKinds,IntToStr(ItemIndex)],
    ['Name'],
    [Text]
   );
   DefWriteToRegistry(['Software',RegFIBRoot,RegFIBTrKinds,IntToStr(ItemIndex)],
    ['Params'],
    [memParams.Text]
   );
  end;
{$ENDIF}
end;

procedure TfrmTransEdit.ReadUsersKinds;
var v,v1:Variant;
    i:integer;
begin
{$IFNDEF NO_REGISTRY}
 v:=DefAllSubKey(['Software',RegFIBRoot,RegFIBTrKinds]);
 if (VarType(v)<>varBoolean) then
 for i:=0 to VarArrayHighBound(v,1) do
 begin
  v1:=
   DefReadFromRegistry(['Software',RegFIBRoot,RegFIBTrKinds,IntToStr(v[i])],
    ['Name']
   );
  if VarType(v1)=varBoolean then Continue;
  if (v[i]<cmbProps.Items.Count) and (i>0) then
   cmbProps.Items[i]:=v1[0,0]
  else
   cmbProps.Items.Add(v1[0,0])
 end;
{$ENDIF}
end;

procedure TfrmTransEdit.Button5Click(Sender: TObject);
begin
  //
{$IFNDEF NO_REGISTRY}
  if SaveDialog1.Execute then
   AltSaveRegKey(SaveDialog1.FileName,
    ['Software',RegFIBRoot,RegFIBTrKinds]
   )
{$ENDIF}   
end;

procedure TfrmTransEdit.Button6Click(Sender: TObject);
begin
{$IFNDEF NO_REGISTRY}
  if OpenDialog1.Execute then
   AltLoadRegKey(OpenDialog1.FileName,
    ['Software',RegFIBRoot,RegFIBTrKinds]
   )
{$ENDIF}
end;

end.


