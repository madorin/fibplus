unit FIB_FMX_DBLoginDlg;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Rtti, System.Classes,
  System.Variants, FMX.Types, FMX.Controls, FMX.Forms, FMX.Dialogs,
  FMX.StdCtrls, FMX.Edit;

type
  TfmxFIBDBLoginDlg = class(TForm)
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


 function pFIBLoginDialogFMX(const ADatabaseName: string; var AUserName, APassword,ARoleName: string): Boolean;
implementation
 uses fib, FIBConsts;
{$R *.fmx}

var
  frmFIBDBLoginDlgFMX: TfmxFIBDBLoginDlg;

 function pFIBLoginDialogFMX(const ADatabaseName: string;
   var AUserName, APassword,ARoleName: string
 ): Boolean;
  var  frmFIBDBLoginDlg: TfmxFIBDBLoginDlg;
 begin
  frmFIBDBLoginDlg:= TfmxFIBDBLoginDlg.Create(nil);
  with frmFIBDBLoginDlg do
  try
   if Length(ADatabaseName)<=50 then
    lbDBName.Text:= ADatabaseName
   else
    lbDBName.Text:=Copy(ADatabaseName,1,10)+'...'+
      Copy(ADatabaseName,Length(ADatabaseName)-32,MaxInt);
   EdUserName.Text      := AUserName;
   EdRole    .Text      := ARoleName;
   Result:= ShowModal=mrOk;
   if Result then
   begin
     AUserName  := EdUserName.Text;
     ARoleName  := EdRole    .Text;
     APassword  := EdPassword.Text;
   end;
  finally
   Free;
  end
 end;

procedure TfmxFIBDBLoginDlg.FormCreate(Sender: TObject);
begin
  Caption := SLoginDlgLoginCaption;
  Label1.Text := SLoginDlgDatabase;
  Label2.Text := SDBEditUserName;
  Label3.Text := SDBEditPassword;
  Label4.Text  := SDBEditSQLRole;
  Button1.Text := SOKButton;
  Button2.Text := SCancelButton;

end;

initialization
 pFIBLoginDialog  :=pFIBLoginDialogFMX;
finalization
 pFIBLoginDialog  :=nil

end.
