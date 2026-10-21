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

unit FIBAutoUpdEditor;

interface

{$I ..\FIB.inc}

uses
  Windows,
  SysUtils, Classes,
{$IFDEF C23}
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls,
  Vcl.ExtCtrls,
  Vcl.StdCtrls,
{$ELSE}
  Graphics, Controls, Forms, Dialogs, ComCtrls, ExtCtrls, StdCtrls,
{$ENDIF}
  Db, fraAutoUpdEditor, uFIBEditorForm;

type

  TFIBAutoUpdateOptionForm = class(TFIBEditorCustomForm)
    OkB: TButton;
    CancelB: TButton;
    fAutoUpdateOptionForm1: TfAutoUpdateOptionForm;
    procedure FormCreate(Sender: TObject);
  private
  public
    { Public declarations }
  end;

function EditAutoUpdateOptions(aDataSet: TDataSet): boolean;

implementation

uses
  FIBEditorsConsts;

{$R *.dfm}

function EditAutoUpdateOptions(aDataSet: TDataSet): boolean;
var
  aForm: TFIBAutoUpdateOptionForm;
begin
  Result := False;
  if aDataSet = nil then
    exit;

  aForm := TFIBAutoUpdateOptionForm.Create(Application);
  try
    with aForm, aForm.fAutoUpdateOptionForm1 do
    begin
      Caption := Format(Caption, [aDataSet.Name]);
      FDataSet := aDataSet;
      PrepareControls;
      Result := ShowModal = mrOk;
      if Result then
        ApplyToDataSet
    end;
  finally
    aForm.Free;
  end;
end;

procedure TFIBAutoUpdateOptionForm.FormCreate(Sender: TObject);
begin
  Caption := FPAutoOptEditorCaption;
  OkB.Caption := SOKButton;
  CancelB.Caption := SCancelButton;
end;

end.
