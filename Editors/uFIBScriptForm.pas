unit uFIBScriptForm;

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
    pFIBInterfaces  ,  RegFIBPlusEditors, uFIBEditorForm
  ;

type
  TfrmScript = class(TFIBEditorCustomForm)
    Panel1: TPanel;
    btnSave: TSpeedButton;
    SaveDialog1: TSaveDialog;
    btnExec: TSpeedButton;
    btnOpen: TSpeedButton;
    OpenDialog1: TOpenDialog;
    StatusBar1: TStatusBar;
    procedure btnSaveClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure btnExecClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
  private
  protected
    iViewSQL:IFIBSQLTextEditor;
    viewSQL: TWinControl;
    DB:TObject;
    vScripter:TObject;
    iScripter:IFIBScripter;
    FReadOnly:boolean;
    procedure ExecProgress(Line:Integer; StatementNo: Integer);
    procedure PrepareForm(ForReadOnly:boolean = false);
  public
    destructor Destroy; override;
    procedure ChangeScript(const ACaption,s:String);
  end;

  TfrmScript1=class(TFrmScript);
  PForm=^TfrmScript;
var
  frmScript: TfrmScript;

  frmScript1: TfrmScript1;

  procedure ShowScript(const aCaption:string; Database:TObject; Script:TStrings;ForReadOnly:boolean = false; asSubModal:boolean =False );
  procedure ShowScriptEx( const aCaption:string; Database:TObject; Script:TStrings;ForReadOnly:boolean = false;
  asSubModal:boolean =False ;ClassCase:integer=0);

implementation
{$R *.DFM}

uses    RTTIRoutines,TypInfo;

{var
   LastTop, LastLeft,   LastWidth,LastHeight:integer;
  }
  procedure ShowScriptEx( const aCaption:string; Database:TObject; Script:TStrings;ForReadOnly:boolean = false; asSubModal:boolean =False;
    ClassCase:integer=0
   );
  var
     Caller:TForm;
     Form: TfrmScript;
  begin
    case ClassCase of
     1: begin
         Form:= TfrmScript1.Create(Application);
         frmScript1:=TfrmScript1(Form);
        end
    else
     Form:= TfrmScript.Create(Application);
     frmScript:=Form
    end;

    Form.Caption:=aCaption;
    Form.DB:=Database;
    Form.FReadOnly:=ForReadOnly;
    Form.PrepareForm(ForReadOnly);
    if Script<>nil then
     Form.iViewSQL .Lines:=Script;
    if not asSubModal then
    begin
 {    if   LastTop>-1 then
     with Form do
     begin
         Top :=LastTop;
         Left:=LastLeft;
         Width :=LastWidth;
         Height:=LastHeight;
     end;
  }
     Form.ShowModal;
//     frmScript.Free
    end
    else
    begin
{     if   LastTop>-1 then
     with frmScript do
     begin
         Top :=LastTop;
         Left:=LastLeft;
         Width :=LastWidth;
         Height:=LastHeight;
     end;
 }
     Caller:=Screen.ActiveForm;
     if fsModal in Caller.FormState then
//     if (Caller.FormState=TFormState(fsVisible)) then
     begin
      Caller.Enabled:=False;
      try
//       frmScript.FormStyle:=fsStayOnTop;
       Form.Show ;
       Form.SetFocus;
      finally
       Caller.Enabled:=True
      end
     end;

    end;
  end;

  procedure ShowScript(const aCaption:string;Database:TObject; Script:TStrings;ForReadOnly:boolean = false; asSubModal:boolean =False);
  begin
    ShowScriptEx(aCaption,Database,Script,ForReadOnly,asSubModal)  ; 
  end;


type THackWinControl=class(TCustomControl);
{ TfrmScript }

procedure TfrmScript.PrepareForm(ForReadOnly:boolean = false);
begin
   btnExec.Enabled:=Assigned(DB);
   viewSQL:=TWinControl(TComponentClass(GetSQLTextEditor).Create(Self));
   ObjSupports(viewSQL, IFIBSQLTextEditor,   iViewSQL);

   vScripter:=expScripter.Create(Self);
   ObjSupports(vScripter, IFIBScripter,   iScripter);
   iViewSQL.ReadOnly:=FReadOnly;
   if  FReadOnly then
     btnExec.Enabled:=False;
   with THackWinControl(viewSQL) do
   begin
     Parent:=Self;
     Font.Name:='Courier New';
     Font.Size:=10;
     Align:=alClient;
     SendToBack;
   end;

end;

procedure TfrmScript.btnSaveClick(Sender: TObject);
begin
 if  SaveDialog1.Execute then
  iViewSQL.Lines.SaveToFile(SaveDialog1.FileName)
end;

destructor TfrmScript.Destroy;
begin
  iViewSQL:=nil;
  iScripter:=nil;
  frmScript:=nil;
  inherited;
end;

procedure TfrmScript.btnOpenClick(Sender: TObject);
begin
 if  OpenDialog1.Execute then
  iViewSQL.Lines.LoadFromFile(OpenDialog1.FileName)

end;

procedure TfrmScript.btnExecClick(Sender: TObject);
begin
//
  SetObjectProp(vScripter,'Database',DB);
  AssignStringsToProp(vScripter,'Script',iViewSQL.Lines.Text);
  iScripter.SetOnStatExec(ExecProgress);
  iScripter.ExecuteScript();
  StatusBar1.SimpleText:=''
end;

procedure TfrmScript.ExecProgress(Line, StatementNo: Integer);
begin
 StatusBar1.SimpleText:='Execute  '+IntToStr(StatementNo)+' statement '+
  'from '+IntToStr(iScripter.StatementsCount);
 Application.ProcessMessages
end;

procedure TfrmScript.FormClose(Sender: TObject; var Action: TCloseAction);
begin

  Action:=caFree        ;
  if Self =   frmScript then
   frmScript:=nil
end;


procedure TfrmScript.ChangeScript(const ACaption, s: String);
begin
  Caption:=ACaption;
  iViewSQL .Lines.Text:=s
end;

procedure TfrmScript.FormDestroy(Sender: TObject);
begin
 if Self =   frmScript then
  frmScript:=nil
 else
 if Self =   frmScript1 then
  frmScript1:=nil
end;

initialization

end.
