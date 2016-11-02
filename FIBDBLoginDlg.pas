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
{    Written by Serge Buzadzhy (buzz@devrace.com)               }
{                                                               }
{ ------------------------------------------------------------- }
{    FIBPlus home page: http://www.fibplus.com/                 }
{    FIBPlus support  : http://www.devrace.com/support/         }
{ ------------------------------------------------------------- }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}
{$I FIBPlus.inc}
unit FIBDBLoginDlg;

interface


uses {$IFDEF D_XE2}Vcl.StdCtrls, Vcl.Controls,
     System.Classes, Vcl.Forms,Vcl.Dialogs,Vcl.ExtCtrls,
     {$ENDIF}
  SysUtils{$IFNDEF D_XE2}, Forms, Classes,  Controls,
  StdCtrls, ExtCtrls,Dialogs{$ENDIF};



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


 function pFIBLoginDialogEx(const ADatabaseName: string; var AUserName, APassword,ARoleName: string): Boolean;

implementation

{$R *.dfm}
uses fib, FIBConsts;

 function pFIBLoginDialogEx(const ADatabaseName: string;
   var AUserName, APassword,ARoleName: string
 ): Boolean;
  var  frmFIBDBLoginDlg: TfrmFIBDBLoginDlg;
 begin
  frmFIBDBLoginDlg:= TfrmFIBDBLoginDlg.Create(nil);
  with frmFIBDBLoginDlg do
  try
   if Length(ADatabaseName)<=45 then
    lbDBName.Caption:= ADatabaseName
   else
    lbDBName.Caption:=Copy(ADatabaseName,1,10)+'...'+
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
 
procedure TfrmFIBDBLoginDlg.FormCreate(Sender: TObject);
begin
  Caption := SLoginDlgLoginCaption;
  Label1.Caption := SLoginDlgDatabase;
  Label2.Caption := SDBEditUserName;
  Label3.Caption := SDBEditPassword;
  Label4.Caption := SDBEditSQLRole;
  Button1.Caption := SOKButton;
  Button2.Caption := SCancelButton;
end;

initialization
 pFIBLoginDialog  :=pFIBLoginDialogEx;
finalization
 pFIBLoginDialog  :=nil
end.

