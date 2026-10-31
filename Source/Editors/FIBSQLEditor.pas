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
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit FIBSQLEditor;

interface

{$I ..\FIB.inc}

uses
  Windows, Messages, SysUtils, Classes,
{$IFDEF C23}
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls,
  Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.Buttons,
{$ELSE}
  Graphics, Controls, Forms, Dialogs, ComCtrls, ExtCtrls, StdCtrls, Buttons,
{$ENDIF}
  DB, fraSQLEdit, uFIBEditorForm, Variants;

type
  TFIBSQLEditForm = class(TFIBEditorCustomForm)
    fSQLEdit1: TFIBSQLEditFrame;
    Panel1: TPanel;
    btnOK: TBitBtn;
    btnCancel: TBitBtn;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure fSQLEdit1btnShowDDLClick(Sender: TObject);
    procedure fSQLEdit1SpeedButton1Click(Sender: TObject);
  private
    { Public declarations }
  end;

var
  frmSQLEdit: TFIBSQLEditForm;

function ShowSQLEdit(aQuery: TComponent): Boolean;

implementation

{$R *.dfm}

uses
{$IFDEF CODEEDITOR} ToCodeEditor, {$ENDIF} TypInfo, RTTIRoutines, IBSQLSyn,
  FIBInterfaces,
  RegFIBEditors;

function ShowSQLEdit(aQuery: TComponent): Boolean;
var
  ts: TStrings;
begin
  frmSQLEdit := TFIBSQLEditForm.Create(Application);
  try
    with frmSQLEdit do
    begin
      fSQLEdit1.PrepareFrame(TComponent(GetObjectProp(aQuery, 'Database')));
      fSQLEdit1.ReadOptions;
      ts := TStrings(GetObjectProp(aQuery, 'SQL'));
      fSQLEdit1.SQLText := ts.Text;
      fSQLEdit1.FEditedQuery := aQuery;
      Caption := 'SQL edit :' + aQuery.Name;
      Result := ShowModal = mrOk;
      if Result then
        AssignStringsToProp(aQuery, 'SQL', fSQLEdit1.SQLText);
    end;
  finally
    FreeAndNil(frmSQLEdit);
  end;
end;

procedure TFIBSQLEditForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  fSQLEdit1.SaveOptions;
end;

procedure TFIBSQLEditForm.fSQLEdit1btnShowDDLClick(Sender: TObject);
begin
  fSQLEdit1.btnShowDDLClick(Sender);

end;

procedure TFIBSQLEditForm.fSQLEdit1SpeedButton1Click(Sender: TObject);
begin
  fSQLEdit1.SpeedButton1Click(Sender);

end;

end.
