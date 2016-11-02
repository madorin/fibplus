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

unit FIBSQLEditor;

interface

{$I ..\FIBPlus.inc}
uses
  Windows, Messages, SysUtils, Classes,
   {$IFDEF D_XE2}
  Vcl.Graphics, Vcl.Controls, Vcl.Forms,  Vcl.Dialogs, Vcl.ComCtrls, Vcl.ExtCtrls,
  Vcl.StdCtrls,Vcl.Buttons,
  {$ELSE}
  Graphics, Controls, Forms,  Dialogs, ComCtrls, ExtCtrls, StdCtrls,Buttons,
  {$ENDIF}

  DB,fraSQLEdit, uFIBEditorForm
  {$IFDEF D6+}
   ,Variants
  {$ENDIF}
  ;

type
  TfrmSQLEdit = class(TFIBEditorCustomForm)
    fSQLEdit1: TfSQLEdit;
    Panel1: TPanel;
    btnOK: TBitBtn;
    btnCancel: TBitBtn;
    procedure Panel1Resize(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure fSQLEdit1btnShowDDLClick(Sender: TObject);
    procedure fSQLEdit1SpeedButton1Click(Sender: TObject);
  private
    procedure SetProposal;
  public
    { Public declarations }
  end;

var
  frmSQLEdit: TfrmSQLEdit;

  function ShowSQLEdit(aQuery:TComponent):boolean;

implementation

{$R *.dfm}
uses
{$IFDEF CODEEDITOR} ToCodeEditor,{$ENDIF} TypInfo, RTTIRoutines, IBSQLSyn,pFIBInterfaces,
  RegFIBPlusEditors;

var
   LastTop, LastLeft,   LastWidth,LastHeight:integer;



function ShowSQLEdit(aQuery:TComponent):boolean;
var
   ts:TStrings;
begin
 {$IFNDEF INTERNAL}
 {$ifdef FIBPLUS_TRIAL}
  {$I include\aspr_crypt_begin1.inc}
  ShowMessage( 'Thank you very much for evaluating FIBPlus.'#10#13#10#13 +
    'Please go to http://www.devrace.com and register today.');
  {$I include\aspr_crypt_end1.inc}
 {$ENDIF}
 {$ENDIF}

    frmSQLEdit:= TfrmSQLEdit.Create(Application);
    with frmSQLEdit do
    begin

//     fSQLEdit1.PrepareFrame(aQuery.Database);

     fSQLEdit1.PrepareFrame(TComponent(GetObjectProp(aQuery,'Database')));
     fSQLEdit1.ReadOptions;
     ts:=TStrings(GetObjectProp(aQuery,'SQL'));
     fSQLEdit1.SQLText:=ts.Text;
     fSQLEdit1.vEditedQuery:=aQuery;
     Caption:='SQL edit :'+aQuery.Name;
{     if   LastTop>-1 then
     begin
         Position:= poDesigned;
         Top :=LastTop;
         Left:=LastLeft;
         Width :=LastWidth;
         Height:=LastHeight;
     end;}
     SetProposal;
     Result:=ShowModal = mrOk;
     if Result then
      AssignStringsToProp(aQuery,'SQL',fSQLEdit1.SQLText);
     Free
    end;
end;

procedure TfrmSQLEdit.Panel1Resize(Sender: TObject);
begin
 btnCancel.Left:=Panel1.Width-80;
 btnOK.Left    :=btnCancel.Left-btnOK.Width-5;
end;

procedure TfrmSQLEdit.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 LastTop   :=Top;
 LastLeft  :=Left;
 LastWidth :=Width;
 LastHeight:=Height;
 fSQLEdit1.SaveOptions;
end;

procedure TfrmSQLEdit.fSQLEdit1btnShowDDLClick(Sender: TObject);
begin
  fSQLEdit1.btnShowDDLClick(Sender);

end;

procedure TfrmSQLEdit.SetProposal;
var
   i:integer;
   ts,ts1:TStrings;
   DDLExtractor1:IFIBMetaDataExtractor;
   Stringer:IFIBStringer;
   v:Variant;
begin
{ if (fSQLEdit1.FDatabase=nil) then
 begin
// or not GetPropValue(fSQLEdit1.FDatabase,'Connected')
  fSQLEdit1.iViewSQL.ISetProposalItems(DefProposalShadow[0],DefProposalShadow[1]);
  Exit;
 end;
 v:=GetPropValue(fSQLEdit1.FDatabase,'Connected');
 v:=VarToStr(v)='True';
 if not v then
 begin
  fSQLEdit1.iViewSQL.ISetProposalItems(DefProposalShadow[0],DefProposalShadow[1]);
  Exit;
 end;

 DDLExtractor1:=FIBClassesExporter.iGetMetaExtractor;
 DDLExtractor1.SetDatabase(fSQLEdit1.FDatabase);
 DDLExtractor1.LoadObjectNames;
 Stringer:=FIBClassesExporter.iGetStringer;

 ts:=TStringList.Create;
 ts1:=TStringList.Create;
 with DDLExtractor1 do
 try
  ts.Assign(DefProposalShadow[0]);
  ts1.Assign(DefProposalShadow[1]);
  for i:=0 to  Pred(TablesCount) do
  begin
   ts.Add('table '+ProposalDelimiterShadow+'M '+Stringer.FormatIdentifier(3,TableName[i]));
   ts1.Add(Stringer.FormatIdentifier(3,TableName[i]));
  end;

  for i:=0 to  Pred(ViewsCount) do
  begin
   ts.Add('view '+ProposalDelimiterShadow+'O '+Stringer.FormatIdentifier(3,ViewName[i]));
   ts1.Add(Stringer.FormatIdentifier(3,ViewName[i]));
  end;

  for i:=0 to  Pred(ProceduresCount) do
  begin
   ts.Add('procedure '+ProposalDelimiterShadow+'N '+Stringer.FormatIdentifier(3,ProcedureName[i]));
   ts1.Add(Stringer.FormatIdentifier(3,ProcedureName[i]));
  end;

  for i:=0 to  Pred(UDFSCount) do
  begin
   ts.Add('udf '+ProposalDelimiterShadow+'T '+Stringer.FormatIdentifier(3,UDFName[i]));
   ts1.Add(Stringer.FormatIdentifier(3,UDFName[i]));
  end;
  fSQLEdit1.iViewSQL.ISetProposalItems(ts,ts1);
//  SynMemo.SetProposalItems(ts);
 finally
  ts.Free;
  ts1.Free;
 end}
end;

procedure TfrmSQLEdit.fSQLEdit1SpeedButton1Click(Sender: TObject);
begin
  fSQLEdit1.SpeedButton1Click(Sender);

end;

initialization
  LastTop:=-1;

end.
