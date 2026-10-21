{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ InterBase databases                                           }
{                                                               }
{    FIBPlus is based in part on the product                    }
{    Free IB Components, written by Gregory H. Deatz for        }
{    Hoagland, Longo, Moran, Dunst & Doukas Company.            }
{    mailto:gdeatz@hlmdd.com                                    }
{                                                               }
{    Copyright (c) 1998-2007 Devrace Ltd.                       }
{    Written by Serge Buzadzhy                                  }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit FIBDBLoginDlg;

{$I FIB.inc}

interface

uses
  {$IFDEF C23}Vcl.StdCtrls, Vcl.Controls,
  System.Classes, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
{$ENDIF}
  SysUtils{$IFNDEF C23}, Forms, Classes, Controls,
  StdCtrls, ExtCtrls, Dialogs{$ENDIF};

type
  TfrmFIBDBLoginDlg = class(TForm)
    Bevel1: TBevel;
    Label1: TLabel;
    lbDBName: TLabel;
    Bevel2: TBevel;
    Button1: TButton;
    Button2: TButton;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    EdUserName: TEdit;
    EdPassword: TEdit;
    EdRole: TEdit;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

function FIBLoginDialogEx(const ADatabaseName: string; var AUserName, APassword, ARoleName: string): Boolean;

implementation

{$R *.dfm}

uses
  FIB, FIBConsts;

function FIBLoginDialogEx(const ADatabaseName: string; var AUserName, APassword, ARoleName: string): Boolean;
var
  frmFIBDBLoginDlg: TfrmFIBDBLoginDlg;
begin
  frmFIBDBLoginDlg := TfrmFIBDBLoginDlg.Create(nil);
  with frmFIBDBLoginDlg do
    try
      if Length(ADatabaseName) <= 45 then
        lbDBName.Caption := ADatabaseName
      else
        lbDBName.Caption := Copy(ADatabaseName, 1, 10) + '...' +
          Copy(ADatabaseName, Length(ADatabaseName) - 32, MaxInt);
      EdUserName.Text := AUserName;
      EdRole.Text := ARoleName;
      Result := ShowModal = mrOk;
      if Result then
      begin
        AUserName := EdUserName.Text;
        ARoleName := EdRole.Text;
        APassword := EdPassword.Text;
      end;
    finally
      Free;
    end
end;

procedure TfrmFIBDBLoginDlg.FormCreate(Sender: TObject);
begin
  Caption := SLoginDlgCaption;
  Label1.Caption := SLoginDlgDatabase;
  Label2.Caption := SLoginDlgUserName;
  Label3.Caption := SLoginDlgPassword;
  Label4.Caption := SLoginDlgRole;
  Button1.Caption := SLoginDlgOK;
  Button2.Caption := SLoginDlgCancel;
end;

initialization

FIBLoginDialog := FIBLoginDialogEx;

finalization

FIBLoginDialog := nil

end.
