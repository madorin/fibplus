{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ Interbase databases                                           }
{                                                               }
{    FIBPlus is based in part on the product                    }
{    Free IB Components, written by Gregory H. Deatz for        }
{    Hoagland, Longo, Moran, Dunst & Doukas Company.            }
{    mailto:gdeatz@hlmdd.com                                    }
{                                                               }
{    Copyright (c) 1998-2004 Serge Buzadzhy                     }
{    Contact: buzz@devrace.com                                  }
{                                                               }
{ ------------------------------------------------------------- }
{    FIBPlus home page      : http://www.fibplus.net/           }
{    FIBPlus support e-mail : fibplus@devrace.com               }
{ ------------------------------------------------------------- }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit FIBDataSQLEditor;

interface

{$I ..\FIBPlus.inc}
uses
  Windows, Messages, SysUtils, {$IFDEF D6+}Variants, {$ENDIF}Classes,
   {$IFDEF D_XE2}
  Vcl.Graphics, Vcl.Controls, Vcl.Forms,  Vcl.Dialogs, Vcl.ComCtrls, Vcl.ExtCtrls,
  Vcl.StdCtrls,Vcl.Buttons,
  {$ELSE}
  Graphics, Controls, Forms,  Dialogs, ComCtrls, ExtCtrls, StdCtrls,Buttons,
  {$ENDIF}

  fraSQLEdit, DB,
  fraDSSQLEdit,uFIBEditorForm;

type
  TfrmDstSQLedit = class(TFIBEditorCustomForm)
    Panel1: TPanel;
    btnOK: TBitBtn;
    btnCancel: TBitBtn;
    fSQLsEdit: TfDSSQLEdit;
    procedure Panel1Resize(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    procedure ReadOptions;
    procedure SaveOptions;
    procedure SaveFieldsOrigins(aDataSet:TDataSet);
  public
    { Public declarations }
  end;

var
  frmDstSQLedit: TfrmDstSQLedit;

  function ShowDSSQLsEdit(aDataSet:TDataSet;var ExitToCodeEditor:integer):boolean;
  function ShowDSSQLEdit(aDataSet:TDataSet;KindSQL:integer; var ExitToCodeEditor:integer):boolean; overload;
  function ShowDSSQLEdit(aDataSet:TDataSet;KindSQL:integer ):boolean; overload;

implementation

{$R *.dfm}
 uses  TypInfo, RegistryUtils, RTTIRoutines, pFIBInterfaces;

var
   LastTop, LastLeft,   LastWidth,LastHeight:integer;

const
   RegFIBSQLEdOptions='SQLEditor';



  function ShowDSSQLEdit(aDataSet:TDataSet;KindSQL:integer;var ExitToCodeEditor:integer):boolean;
  var
   ForceClose:boolean;
   Modified  :boolean;
  begin
    frmDstSQLedit:= TfrmDstSQLedit.Create(Application);
    with frmDstSQLedit do
    begin
     with fSQLsEdit do
     begin
       vDataSet:=aDataSet;
       PrepareFrame( TComponent(GetObjectProp(aDataSet,'Database')),
         TStrings(GetObjectProp(aDataSet,'SelectSQL')).Text,
         TStrings(GetObjectProp(aDataSet,'InsertSQL')).Text,
         TStrings(GetObjectProp(aDataSet,'UpdateSQL')).Text,
         TStrings(GetObjectProp(aDataSet,'DeleteSQL')).Text,
         TStrings(GetObjectProp(aDataSet,'RefreshSQL')).Text
       );
     end;
       ReadOptions;
       if   LastTop>-1 then
       begin
         Position:=poDesigned;
         Top :=LastTop;
         Left:=LastLeft;
         Width :=LastWidth;
         Height:=LastHeight;
       end;

     Caption:='SQL edit :'+aDataSet.Name;
     case KindSQL of
       0: fSQLsEdit.pgCtrl.ActivePage:=fSQLsEdit.shSelect;
     else
      fSQLsEdit.pgCtrl.ActivePage  :=fSQLsEdit.shModifySQLs;
      fSQLsEdit.grSQLKind.ItemIndex:=KindSQL-1
     end;
     fSQLsEdit.SetProposal;
     Result:=ShowModal in [mrOk,mrYes];


     ExitToCodeEditor:=-1;
     if Result then
     begin
      if ModalResult=mrYes then
      begin
       if fSQLsEdit.pgCtrl.ActivePageIndex=0 then
        ExitToCodeEditor:=0
       else
        ExitToCodeEditor:=fSQLsEdit.grSQLKind.ItemIndex+1;
      end
      else
       ExitToCodeEditor:=-1;
      ForceClose:=aDataSet.Active;
      if ForceClose then
        aDataSet.Close;
      Modified:=TStrings(GetObjectProp(aDataSet,'SelectSQL')).Text<>fSQLsEdit.SelectSQLEdit.SQLText;
      if Modified then
       AssignStringsToProp(aDataSet,'SelectSQL',fSQLsEdit.SelectSQLEdit.SQLText);
//       aDataSet.SelectSQL.Text:=fSQLsEdit.SelectSQLEdit.SQLText;
      if TStrings(GetObjectProp(aDataSet,'InsertSQL')).Text<>fSQLsEdit.FInsertSQL then
      begin
       AssignStringsToProp(aDataSet,'InsertSQL',fSQLsEdit.FInsertSQL);
       Modified:=True;
      end;
      if TStrings(GetObjectProp(aDataSet,'UpdateSQL')).Text<>fSQLsEdit.FUpdateSQL then
      begin
       AssignStringsToProp(aDataSet,'UpdateSQL',fSQLsEdit.FUpdateSQL);
       Modified:=True;
      end;
      if TStrings(GetObjectProp(aDataSet,'DeleteSQL')).Text<>fSQLsEdit.FDeleteSQL  then
      begin
         AssignStringsToProp(aDataSet,'DeleteSQL',fSQLsEdit.FDeleteSQL);
         Modified:=True;
      end;
      if TStrings(GetObjectProp(aDataSet,'RefreshSQL')).Text<>fSQLsEdit.FRefreshSQL then
      begin
         AssignStringsToProp(aDataSet,'RefreshSQL',fSQLsEdit.FRefreshSQL);
         Modified:=True;
      end;
      Result:=Modified;
      if fSQLsEdit.chFieldOrigin.Checked then
       SaveFieldsOrigins(aDataSet);
      if ForceClose then
       aDataSet.Open;
     end;
     Free
    end;
  end;

function ShowDSSQLsEdit(aDataSet:TDataSet;var ExitToCodeEditor:integer):boolean;
begin
   Result:= ShowDSSQLEdit(aDataSet,0,ExitToCodeEditor);
end;

function ShowDSSQLEdit(aDataSet:TDataSet;KindSQL:integer ):boolean;
var
 ExitToCodeEditor:integer;
begin
   Result:= ShowDSSQLEdit(aDataSet,0,ExitToCodeEditor);
end;

procedure TfrmDstSQLedit.Panel1Resize(Sender: TObject);
begin
 btnCancel.Left:=Panel1.Width-80;
 btnOK.Left    :=btnCancel.Left-btnOK.Width-5;
end;




procedure TfrmDstSQLedit.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
 LastTop :=Top;
 LastLeft:=Left;
 LastWidth:=Width;
 LastHeight:=Height;
 SaveOptions;
end;



procedure TfrmDstSQLedit.ReadOptions;

{$IFNDEF NO_REGISTRY}
var v:Variant;
    i:integer;
{$ENDIF}
begin
{$IFNDEF NO_REGISTRY}
 v:=
  DefReadFromRegistry(['Software',RegFIBRoot,RegFIBSQLEdOptions],
   ['Top',
    'Left',
    'Height',
    'Width',
    'Origins'
   ]
 );
 if (VarType(v)<>varBoolean) then
  for i:=0 to 4 do
   if V[1,i] then
   case i of
    0: LastTop               :=V[0,i];
    1: LastLeft              :=V[0,i];
    2: LastHeight:=V[0,i];
    3: LastWidth :=V[0,i];
    4: fSQLsEdit.chFieldOrigin.Checked:=V[0,i]
   end;
 fSQLsEdit.ReadOptions;

{$ENDIF}
end;



procedure TfrmDstSQLedit.SaveOptions;
begin
{$IFNDEF NO_REGISTRY}
 DefWriteToRegistry(['Software',RegFIBRoot,RegFIBSQLEdOptions],
   ['Top',
    'Left',
    'Height',
    'Width',
    'Origins'
   ],
   [
    LastTop,
    LastLeft,
    LastHeight,
    LastWidth,
    fSQLsEdit.chFieldOrigin.Checked
   ]
 );
 fSQLsEdit.SaveOptions;
{$ENDIF}


end;

procedure TfrmDstSQLedit.SaveFieldsOrigins(aDataSet:TDataSet);
var
 i:integer;
 vConnected:boolean;
 ids:IFIBDataSet;
begin
 with aDataSet do
 begin
   if DefaultFields or (not Active and (FieldCount=0)) then
    Exit;
   vConnected:=Assigned(GetObjectProp(aDataSet,'Database')) and
    GetPropValue(GetObjectProp(aDataSet,'Database'),'Connected');
   if not vConnected then
     Exit;
   if ObjSupports(aDataSet,IFIBDataSet,ids) then
   for i:=0 to Pred(FieldCount) do
     Fields[i].Origin:=ids.GetFieldOrigin(Fields[i]);
 end;
end;

initialization
  LastTop:=-1;
end.
