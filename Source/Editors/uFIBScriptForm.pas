unit uFIBScriptForm;

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
  FIBInterfaces, RegFIBEditors, uFIBEditorForm;

type
  TFIBScriptForm = class(TFIBEditorCustomForm)
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
    iViewSQL: IFIBSQLTextEditor;
    viewSQL: TWinControl;
    DB: TObject;
    FScripter: TObject;
    iScripter: IFIBScripter;
    FReadOnly: Boolean;
    procedure ExecProgress(Line: Integer; StatementNo: Integer);
    procedure PrepareForm(ForReadOnly: Boolean = false);
  public
    destructor Destroy; override;
    procedure ChangeScript(const ACaption, s: String);
  end;

  TFIBNestedScriptForm = class(TFIBScriptForm);

var
  frmScript: TFIBScriptForm;

  frmScript1: TFIBNestedScriptForm;

procedure ShowScript(const ACaption: string; Database: TObject;
  Script: TStrings; ForReadOnly: Boolean = false; asSubModal: Boolean = false);
procedure ShowScriptEx(const ACaption: string; Database: TObject;
  Script: TStrings; ForReadOnly: Boolean = false; asSubModal: Boolean = false;
  ClassCase: Integer = 0);

implementation

{$R *.DFM}

uses
  RTTIRoutines, TypInfo;

procedure ShowScriptEx(const ACaption: string; Database: TObject;
  Script: TStrings; ForReadOnly: Boolean = false; asSubModal: Boolean = false;
  ClassCase: Integer = 0);
var
  Caller: TForm;
  Form: TFIBScriptForm;
begin
  case ClassCase of
    1:
      begin
        Form := TFIBNestedScriptForm.Create(Application);
        frmScript1 := TFIBNestedScriptForm(Form);
      end
  else
    Form := TFIBScriptForm.Create(Application);
    frmScript := Form
  end;

  Form.Caption := ACaption;
  Form.DB := Database;
  Form.FReadOnly := ForReadOnly;
  Form.PrepareForm(ForReadOnly);
  if Script <> nil then
    Form.iViewSQL.Lines := Script;
  if not asSubModal then
  begin
    Form.ShowModal;
  end
  else
  begin
    Caller := Screen.ActiveForm;
    if fsModal in Caller.FormState then
    begin
      Caller.Enabled := false;
      try
        Form.Show;
        Form.SetFocus;
      finally
        Caller.Enabled := True
      end
    end;

  end;
end;

procedure ShowScript(const ACaption: string; Database: TObject;
  Script: TStrings; ForReadOnly: Boolean = false; asSubModal: Boolean = false);
begin
  ShowScriptEx(ACaption, Database, Script, ForReadOnly, asSubModal);
end;

type
  THackWinControl = class(TCustomControl);
  { TFIBScriptForm }

procedure TFIBScriptForm.PrepareForm(ForReadOnly: Boolean = false);
begin
  btnExec.Enabled := Assigned(DB);
  viewSQL := TWinControl(TComponentClass(GetSQLTextEditor).Create(Self));
  ObjSupports(viewSQL, IFIBSQLTextEditor, iViewSQL);

  FScripter := expScripter.Create(Self);
  ObjSupports(FScripter, IFIBScripter, iScripter);
  iViewSQL.ReadOnly := FReadOnly;
  if FReadOnly then
    btnExec.Enabled := false;
  with THackWinControl(viewSQL) do
  begin
    Parent := Self;
    Font.Name := 'Courier New';
    Font.Size := 10;
    Align := alClient;
    SendToBack;
  end;

end;

procedure TFIBScriptForm.btnSaveClick(Sender: TObject);
begin
  if SaveDialog1.Execute then
    iViewSQL.Lines.SaveToFile(SaveDialog1.FileName)
end;

destructor TFIBScriptForm.Destroy;
begin
  iViewSQL := nil;
  iScripter := nil;
  frmScript := nil;
  inherited;
end;

procedure TFIBScriptForm.btnOpenClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
    iViewSQL.Lines.LoadFromFile(OpenDialog1.FileName)

end;

procedure TFIBScriptForm.btnExecClick(Sender: TObject);
begin
  SetObjectProp(FScripter, 'Database', DB);
  AssignStringsToProp(FScripter, 'Script', iViewSQL.Lines.Text);
  iScripter.SetOnStatExec(ExecProgress);
  iScripter.ExecuteScript();
  StatusBar1.SimpleText := ''
end;

procedure TFIBScriptForm.ExecProgress(Line, StatementNo: Integer);
begin
  StatusBar1.SimpleText := 'Execute  ' + IntToStr(StatementNo) + ' statement ' +
    'from ' + IntToStr(iScripter.StatementsCount);
  Application.ProcessMessages
end;

procedure TFIBScriptForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin

  Action := caFree;
  if Self = frmScript then
    frmScript := nil
end;

procedure TFIBScriptForm.ChangeScript(const ACaption, s: String);
begin
  Caption := ACaption;
  iViewSQL.Lines.Text := s
end;

procedure TFIBScriptForm.FormDestroy(Sender: TObject);
begin
  if Self = frmScript then
    frmScript := nil
  else if Self = frmScript1 then
    frmScript1 := nil
end;

initialization

end.
