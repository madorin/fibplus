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

unit pFIBConditionsEdit;

interface

{$I ..\FIBPlus.inc}
uses
  Windows, Messages, SysUtils,  Classes,
  {$IFDEF D_XE2}
  Vcl.Graphics, Vcl.Controls, Vcl.Forms,  Vcl.Dialogs, Vcl.ComCtrls, Vcl.ExtCtrls,
  Vcl.StdCtrls,
  {$ELSE}
  Graphics, Controls, Forms,  Dialogs, ComCtrls, ExtCtrls, StdCtrls,
  {$ENDIF}
  fraConditionsEdit,uFIBEditorForm
  {$IFDEF LINUX}
    ,VKCodes
  {$ENDIF}
  ;

type
  TfrmEditCheckStrings = class(TFIBEditorCustomForm)
    fraEdConditions1: TfraEdConditions;
    procedure FormCreate(Sender: TObject);
  private
  public

  end;


function EditConditions(Value:TStrings):boolean;

implementation

uses pFIBEditorsConsts;

{$R *.dfm}

function EditConditions(Value:TStrings):boolean;
var
 frm: TfrmEditCheckStrings;
begin
 frm:= TfrmEditCheckStrings.Create(nil);
 with frm do
 try
  fraEdConditions1.PrepareFrame(Value);
  Result:=ShowModal=mrOk;
  if Result then
  begin
    fraEdConditions1.ApplyChanges;
{    Value.Clear;
    for i:=0 to Pred(ListView1.Items.Count) do
    begin
     Value.AddCondition(ListView1.Items[i].Caption,FTexts[i],ListView1.Items[i].Checked)
    end;}
  end;
 finally
  frm.Free;
 end;
end;


procedure TfrmEditCheckStrings.FormCreate(Sender: TObject);
begin
  Caption := FPConditionsCaption;
end;

end.
