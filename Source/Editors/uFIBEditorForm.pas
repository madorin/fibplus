unit uFIBEditorForm;

interface

{$I ..\FIB.inc}

uses
  Windows, Classes, Variants, {$IFDEF C23}Vcl.Controls, Vcl.Forms{$ELSE}Controls, Forms{$ENDIF};

type
  TFIBEditorCustomForm = class(TForm)
  private
    procedure RestorePosition;
    procedure SavePosition;
    function IsResizable: Boolean;
  protected
    procedure ReadState(Reader: TReader); override;
    procedure OnReadError(Reader: TReader; const Message: string; var Handled: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  TFIBEditorCustomFrame = class(TFrame)
  protected
    procedure ReadState(Reader: TReader); override;
    procedure OnReadError(Reader: TReader; const Message: string; var Handled: Boolean);
  end;

function ControlPPI(Control: TControl): Integer;
// Scales a size designed at 96 DPI to the PPI of the control
function ScaleToPPI(Control: TControl; Value: Integer): Integer;
// Reads the integer at Index from the result of DefReadFromRegistry
function RegistryInteger(const Values: Variant; Index: Integer; out Value: Integer): Boolean;

implementation

uses
  SysUtils, Math, RegUtils, FIBProps;

const
  DefaultPPI = 96;
  PositionValueNames: array[0..5] of string = ('Top', 'Left', 'Height', 'Width', 'Maximized', 'PixelsPerInch');

function ControlPPI(Control: TControl): Integer;
begin
{$IFDEF C34}
  Result := Control.CurrentPPI;
{$ELSE}
  Result := Screen.PixelsPerInch;
{$ENDIF}
end;

function ScaleToPPI(Control: TControl; Value: Integer): Integer;
begin
  Result := MulDiv(Value, ControlPPI(Control), DefaultPPI);
end;

function RegistryInteger(const Values: Variant; Index: Integer; out Value: Integer): Boolean;
begin
  Result := (VarType(Values[1, Index]) = varBoolean) and Values[1, Index] and
    TryStrToInt(VarToStr(Values[0, Index]), Value);
end;

{ TFIBEditorCustomForm }

constructor TFIBEditorCustomForm.Create(AOwner: TComponent);
begin
  inherited;
  if IsResizable then
    RestorePosition;
end;

destructor TFIBEditorCustomForm.Destroy;
begin
  if IsResizable then
    SavePosition;
  inherited;
end;

function TFIBEditorCustomForm.IsResizable: Boolean;
begin
  Result := BorderStyle in [bsSizeable, bsSizeToolWin];
end;

procedure TFIBEditorCustomForm.OnReadError(Reader: TReader; const Message: string; var Handled: Boolean);
begin
  Handled := True
end;

procedure TFIBEditorCustomForm.RestorePosition;
{$IFNDEF NO_REGISTRY}
var
  Values: Variant;
  SavedTop, SavedLeft, SavedHeight, SavedWidth, SavedPPI, Maximized: Integer;
  Bounds, WorkArea: TRect;
{$ENDIF}
begin
{$IFNDEF NO_REGISTRY}
  Values := DefReadFromRegistry(['Software', RegFIBRoot, ClassName], PositionValueNames);
  if VarType(Values) = varBoolean then
    Exit;
  if not (RegistryInteger(Values, 0, SavedTop) and RegistryInteger(Values, 1, SavedLeft) and
    RegistryInteger(Values, 2, SavedHeight) and RegistryInteger(Values, 3, SavedWidth)) then
    Exit;
  // Sizes saved without the PPI come from the raw pixels of older versions
  if not RegistryInteger(Values, 5, SavedPPI) or (SavedPPI <= 0) then
    SavedPPI := ControlPPI(Self);
  SavedHeight := MulDiv(SavedHeight, ControlPPI(Self), SavedPPI);
  SavedWidth := MulDiv(SavedWidth, ControlPPI(Self), SavedPPI);
  if (SavedHeight <= 0) or (SavedWidth <= 0) then
    Exit;

  Bounds := Rect(SavedLeft, SavedTop, SavedLeft + SavedWidth, SavedTop + SavedHeight);
  WorkArea := Screen.MonitorFromRect(Bounds).WorkareaRect;
  SavedWidth := Min(SavedWidth, WorkArea.Right - WorkArea.Left);
  SavedHeight := Min(SavedHeight, WorkArea.Bottom - WorkArea.Top);
  SavedLeft := Max(WorkArea.Left, Min(SavedLeft, WorkArea.Right - SavedWidth));
  SavedTop := Max(WorkArea.Top, Min(SavedTop, WorkArea.Bottom - SavedHeight));

  Position := poDesigned;
  SetBounds(SavedLeft, SavedTop, SavedWidth, SavedHeight);
  if RegistryInteger(Values, 4, Maximized) and (Maximized <> 0) then
    WindowState := wsMaximized;
{$ENDIF}
end;

procedure TFIBEditorCustomForm.SavePosition;
begin
{$IFNDEF NO_REGISTRY}
  // A maximized window keeps the size saved for its normal state
  case WindowState of
    wsNormal:
      DefWriteToRegistry(['Software', RegFIBRoot, ClassName], PositionValueNames,
        [Top, Left, Height, Width, False, ControlPPI(Self)]);
    wsMaximized:
      DefWriteToRegistry(['Software', RegFIBRoot, ClassName], ['Maximized'], [True]);
  end;
{$ENDIF}
end;

procedure TFIBEditorCustomForm.ReadState(Reader: TReader);
begin
  Reader.OnError := OnReadError;
  inherited ReadState(Reader)

end;

{ TFIBEditorCustomFrame }

procedure TFIBEditorCustomFrame.OnReadError(Reader: TReader; const Message: string; var Handled: Boolean);
begin
  Handled := True
end;

procedure TFIBEditorCustomFrame.ReadState(Reader: TReader);
begin
  Reader.OnError := OnReadError;
  inherited ReadState(Reader)
end;

end.
