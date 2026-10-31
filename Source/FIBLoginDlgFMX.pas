unit FIBLoginDlgFMX;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Rtti, System.Classes,
  System.Variants, FMX.Types, FMX.Controls, FMX.Forms, FMX.Dialogs,
  FMX.StdCtrls, FMX.Edit;

type
  TFIBLoginFormFMX = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    lbDBName: TLabel;
    Panel2: TPanel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    EdUserName: TEdit;
    EdPassword: TEdit;
    EdRole: TEdit;
    Button1: TButton;
    Button2: TButton;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

function FIBLoginDialogFMX(const ADatabaseName: string; var AUserName, APassword, ARoleName: string): Boolean;

implementation

uses
  FIB, FIBConsts;

{$R *.fmx}

function FIBLoginDialogFMX(const ADatabaseName: string; var AUserName, APassword, ARoleName: string): Boolean;
var
  Form: TFIBLoginFormFMX;
begin
  Form := TFIBLoginFormFMX.Create(nil);
  with Form do
    try
      if Length(ADatabaseName) <= 45 then
        lbDBName.Text := ADatabaseName
      else
        lbDBName.Text := Copy(ADatabaseName, 1, 10) + '...' + Copy(ADatabaseName, Length(ADatabaseName) - 32, MaxInt);
      EdUserName.Text := AUserName;
      EdRole.Text := ARoleName;
      ActiveControl := EdPassword;
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

procedure TFIBLoginFormFMX.FormCreate(Sender: TObject);
begin
  Caption := SLoginDlgCaption;
  Label1.Text := SLoginDlgDatabase;
  Label2.Text := SLoginDlgUserName;
  Label3.Text := SLoginDlgPassword;
  Label4.Text := SLoginDlgRole;
  Button1.Text := SLoginDlgOK;
  Button2.Text := SLoginDlgCancel;

end;

initialization

FIBLoginDialog := FIBLoginDialogFMX;

finalization

FIBLoginDialog := nil

end.
