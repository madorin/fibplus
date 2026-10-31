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

unit FIBConditionsEdit;

interface

{$I ..\FIB.inc}

uses
  Windows, Messages, SysUtils, Classes,
{$IFDEF C23}
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls,
  Vcl.ExtCtrls,
  Vcl.StdCtrls,
{$ELSE}
  Graphics, Controls, Forms, Dialogs, ComCtrls, ExtCtrls, StdCtrls,
{$ENDIF}
  fraConditionsEdit, uFIBEditorForm;

type
  TFIBConditionsForm = class(TFIBEditorCustomForm)
    fraEdConditions1: TFIBConditionsFrame;
    procedure FormCreate(Sender: TObject);
  private
  public

  end;

function EditConditions(Value: TStrings): Boolean;

implementation

uses
  FIBEditorsConsts;

{$R *.dfm}

function EditConditions(Value: TStrings): Boolean;
var
  frm: TFIBConditionsForm;
begin
  frm := TFIBConditionsForm.Create(nil);
  with frm do
    try
      fraEdConditions1.PrepareFrame(Value);
      Result := ShowModal = mrOk;
      if Result then
      begin
        fraEdConditions1.ApplyChanges;
      end;
    finally
      frm.Free;
    end;
end;

procedure TFIBConditionsForm.FormCreate(Sender: TObject);
begin
  Caption := FPConditionsCaption;
end;

end.
