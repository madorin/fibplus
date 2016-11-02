unit uFIBSQLHelper;

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
    pFIBInterfaces  ,  RegFIBPlusEditors, uFIBEditorForm, Htmlview;

type
  TfrmSQLHelper = class(TFIBEditorCustomForm)
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
  private
    FViewer: THTMLViewer;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  frmSQLHelper: TfrmSQLHelper;

  procedure ShowSQLHelp(KeyString:string='';asSubModal:boolean =False);

implementation

{$R *.dfm}


  procedure ShowSQLHelp(KeyString:string='';asSubModal:boolean =False);
  var
     Caller:TForm;
  begin
     if frmSQLHelper=nil then
      frmSQLHelper:=TfrmSQLHelper.Create(Application);
     Caller:=Screen.ActiveForm;
     if fsModal in Caller.FormState then
//     if (Caller.FormState=TFormState(fsVisible)) then
     begin
      Caller.Enabled:=False;
      try
       with frmSQLHelper do
       begin
        FViewer.LoadFromFile('D:\works\dlibs\FIBPlus\Editors\bpl\DOCS\SelectRef.html');
        WindowState:=wsNormal;
        Show ;
       end
      finally
       Caller.Enabled:=True
      end
     end;
  end;


constructor TfrmSQLHelper.Create(AOwner: TComponent);
begin
  inherited;
  FViewer:=THTMLViewer.Create(Self);
  FViewer.Align:=alClient;
  FViewer.Parent:=Self;
  FViewer.DefBackground:=clWhite
end;

procedure TfrmSQLHelper.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin

 Action:=caFree;
 frmSQLHelper:=nil
end;

procedure TfrmSQLHelper.FormDestroy(Sender: TObject);
begin
  frmSQLHelper:=nil
end;

end.
