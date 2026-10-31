unit uFontEditor;

interface

{$I ..\FIB.inc}

uses
  Windows, Messages, SysUtils, Classes,
{$IFDEF C23}
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls
{$ELSE}
  Graphics, Controls, Forms, ComCtrls, StdCtrls, Dialogs
{$ENDIF},
  FIBSyntaxMemo, uFIBEditorForm;

type
  TFIBFontEditorForm = class(TFIBEditorCustomForm)
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    lstTokens: TListBox;
    Label1: TLabel;
    Label2: TLabel;
    edColor: TEdit;
    GroupBox1: TGroupBox;
    chBold: TCheckBox;
    chItalic: TCheckBox;
    chUnderLine: TCheckBox;
    edFont: TEdit;
    btnChangeFont: TButton;
    btnChangeColor: TButton;
    FontDialog1: TFontDialog;
    ColorDialog1: TColorDialog;
    TabSheet2: TTabSheet;
    chUseMetaInProposal: TCheckBox;
    procedure lstTokensKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure lstTokensMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure chBoldClick(Sender: TObject);
    procedure btnChangeFontClick(Sender: TObject);
    procedure btnChangeColorClick(Sender: TObject);
    procedure chUseMetaInProposalClick(Sender: TObject);
  private
    FEditor: TMPCustomSyntaxMemo;
    procedure ShowCurrents;
    procedure ChangeFontStyle(Sender: TObject);
    procedure ChangeColor;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;

  public
    { Public declarations }
  end;

var
  frmFontEditor: TFIBFontEditorForm;

procedure ChangeEditorProps(Editor: TMPCustomSyntaxMemo);

implementation

uses
  IBSQLSyn;

{$R *.DFM}

procedure ChangeEditorProps(Editor: TMPCustomSyntaxMemo);
var
  Caller: TForm;
  Form: TFIBFontEditorForm;
begin
  Form := TFIBFontEditorForm.Create(Application);
  frmFontEditor := Form;
  Form.FEditor := Editor;
  Caller := Screen.ActiveForm;
  if fsModal in Caller.FormState then
  begin
    Caller.Enabled := False;
    try
      Form.lstTokens.ItemIndex := 0;
      Form.ShowCurrents;
      Form.Show;
      Form.FreeNotification(Editor);
      Form.SetFocus;
    finally
      Caller.Enabled := True
    end
  end;
end;

procedure TFIBFontEditorForm.lstTokensKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  ShowCurrents
end;

type
  THackWinControl = class(TCustomControl);

procedure TFIBFontEditorForm.ShowCurrents;
var
  CurToken: TToken;
begin
  chUseMetaInProposal.Checked := FEditor.Tag = 0;
  edFont.Text := THackWinControl(FEditor).Font.Name + ' (Size:' + IntToStr(THackWinControl(FEditor).Font.Size) + ')';
  case lstTokens.ItemIndex of
    1: CurToken := tokKeyWord;
    2: CurToken := tokFunction;
    3: CurToken := tokParam;
    4: CurToken := tokTypes;
    5: CurToken := tokILComment;
    6: CurToken := tokString;
    7: CurToken := tokInteger;
  else
    CurToken := tokReservedSiO
  end;
  if CurToken <> tokReservedSiO then
  begin
    chBold.Enabled := True;
    chItalic.Enabled := True;
    chUnderLine.Enabled := True;

    edColor.Color := FEditor.SyntaxAttributes.FontColor[CurToken];
    chBold.Checked := fsBold in FEditor.SyntaxAttributes.FontStyle[CurToken];
    chItalic.Checked := fsItalic in FEditor.SyntaxAttributes.FontStyle
      [CurToken];
    chUnderLine.Checked := fsUnderline in FEditor.SyntaxAttributes.FontStyle
      [CurToken];
  end
  else
  begin
    chBold.Checked := False;
    chItalic.Checked := False;
    chUnderLine.Checked := False;

    chBold.Enabled := False;
    chItalic.Enabled := False;
    chUnderLine.Enabled := False;

    case lstTokens.ItemIndex of
      0: edColor.Color := FEditor.Color;
      8:
        begin
          edColor.Color := FEditor.SelColor;
        end
    end;
  end
end;

procedure TFIBFontEditorForm.lstTokensMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  ShowCurrents
end;

procedure TFIBFontEditorForm.chBoldClick(Sender: TObject);
begin
  ChangeFontStyle(Sender)
end;

procedure TFIBFontEditorForm.chUseMetaInProposalClick(Sender: TObject);
begin
  if chUseMetaInProposal.Checked then
    FEditor.Tag := 0
  else
    FEditor.Tag := 1
end;

procedure TFIBFontEditorForm.ChangeFontStyle(Sender: TObject);
var
  CurToken: TToken;
begin
  case lstTokens.ItemIndex of
    1: CurToken := tokKeyWord;
    2: CurToken := tokFunction;
    3: CurToken := tokParam;
    4: CurToken := tokTypes;
    5: CurToken := tokILComment;
    6: CurToken := tokString;
    7: CurToken := tokInteger;
  else
    CurToken := tokReservedSiO
  end;
  if CurToken <> tokReservedSiO then
  begin
    if TCheckBox(Sender).Checked then
    begin
      if Sender = chBold then
        FEditor.SyntaxAttributes.FontStyle[CurToken] := FEditor.SyntaxAttributes.FontStyle[CurToken] + [fsBold]
      else if Sender = chItalic then
        FEditor.SyntaxAttributes.FontStyle[CurToken] := FEditor.SyntaxAttributes.FontStyle[CurToken] + [fsItalic]
      else if Sender = chUnderLine then
        FEditor.SyntaxAttributes.FontStyle[CurToken] := FEditor.SyntaxAttributes.FontStyle[CurToken] + [fsUnderline];
    end
    else
    begin
      if Sender = chBold then
        FEditor.SyntaxAttributes.FontStyle[CurToken] := FEditor.SyntaxAttributes.FontStyle[CurToken] - [fsBold]
      else if Sender = chItalic then
        FEditor.SyntaxAttributes.FontStyle[CurToken] := FEditor.SyntaxAttributes.FontStyle[CurToken] - [fsItalic]
      else if Sender = chUnderLine then
        FEditor.SyntaxAttributes.FontStyle[CurToken] := FEditor.SyntaxAttributes.FontStyle[CurToken] - [fsUnderline]
    end;
    FEditor.SyntaxAttributes.FontStyle[tokMLCommentBeg] := FEditor.SyntaxAttributes.FontStyle[tokILComment];
    FEditor.SyntaxAttributes.FontStyle[tokMLCommentEND] := FEditor.SyntaxAttributes.FontStyle[tokILComment];
    FEditor.SyntaxAttributes.FontStyle[tokELCommentBeg] := FEditor.SyntaxAttributes.FontStyle[tokILComment];
    FEditor.SyntaxAttributes.FontStyle[tokELCommentEND] := FEditor.SyntaxAttributes.FontStyle[tokILComment];

    FEditor.Invalidate
  end
end;

procedure TFIBFontEditorForm.Notification(AComponent: TComponent; Operation: TOperation);
begin

  inherited;
  if (Operation = opRemove) and (AComponent = FEditor) then
  begin
    Free;
    frmFontEditor := nil
  end
end;

procedure TFIBFontEditorForm.btnChangeFontClick(Sender: TObject);
begin
  if FontDialog1.Execute then
  begin
    THackWinControl(FEditor).Font := FontDialog1.Font;
    ShowCurrents
  end;
end;

procedure TFIBFontEditorForm.btnChangeColorClick(Sender: TObject);
begin
  ColorDialog1.Color := edColor.Color;
  if ColorDialog1.Execute then
  begin
    edColor.Color := ColorDialog1.Color;
    ChangeColor
  end
end;

procedure TFIBFontEditorForm.ChangeColor;
var
  CurToken: TToken;
begin
  case lstTokens.ItemIndex of
    1: CurToken := tokKeyWord;
    2: CurToken := tokFunction;
    3: CurToken := tokParam;
    4: CurToken := tokTypes;
    5: CurToken := tokILComment;
    6: CurToken := tokString;
    7: CurToken := tokInteger;
  else
    CurToken := tokReservedSiO
  end;
  if CurToken <> tokReservedSiO then
  begin
    chBold.Enabled := True;
    chItalic.Enabled := True;
    chUnderLine.Enabled := True;

    FEditor.SyntaxAttributes.FontColor[CurToken] := edColor.Color;

    with FEditor.SyntaxAttributes do
    begin
      FontColor[tokStringEnd] := FontColor[tokString];
      FontStyle[tokStringEnd] := FontStyle[tokString];

      FontColor[tokFloat] := FontColor[tokInteger];
      FontStyle[tokFloat] := FontStyle[tokInteger];

      FontColor[tokMLCommentBeg] := FontColor[tokILComment];
      FontStyle[tokMLCommentBeg] := FontStyle[tokILComment];

      FontColor[tokMLCommentEND] := FontColor[tokILComment];
      FontStyle[tokMLCommentEND] := FontStyle[tokILComment];

      FontColor[tokELCommentBeg] := FontColor[tokILComment];
      FontStyle[tokELCommentBeg] := FontStyle[tokILComment];

      FontColor[tokELCommentEND] := FontColor[tokILComment];
      FontStyle[tokELCommentEND] := FontStyle[tokILComment];

    end

  end
  else
  begin
    case lstTokens.ItemIndex of
      0: FEditor.Color := edColor.Color;
      8: FEditor.SelColor := edColor.Color;
    end;
  end;
  FEditor.Invalidate;
end;

end.
