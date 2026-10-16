unit uFIBEditorForm;

interface

{$I ..\FIBPlus.inc}

uses
  Windows, Classes, Variants, {$IFDEF D_XE2}Vcl.Controls, Vcl.Forms{$ELSE}Controls, Forms{$ENDIF};

type
  TFIBEditorCustomForm = class(TForm)
  protected
    procedure ReadState(Reader: TReader); override;
    procedure OnReadError(Reader: TReader; const Message: string; var Handled: Boolean);
  protected
    LastTop, LastLeft, LastWidth, LastHeight: integer;
    procedure ReadPositions;
    procedure SavePositions;
    function IsResizable: Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  TFIBEditorCustomFrame = class(TFrame)
  protected
    procedure ReadState(Reader: TReader); override;
    procedure OnReadError(Reader: TReader; const Message: string; var Handled: Boolean);
  end;

// Sizes are stored in the registry at 96 DPI, so they restore correctly at any scaling
function ScaleToDefaultPPI(Control: TControl; Value: Integer): Integer;
function ScaleFromDefaultPPI(Control: TControl; Value: Integer): Integer;

implementation

uses
  RegistryUtils;

const
  DefaultPPI = 96;

function ControlPPI(Control: TControl): Integer;
begin
{$IFDEF D_27}
  Result := Control.CurrentPPI;
{$ELSE}
  Result := Screen.PixelsPerInch;
{$ENDIF}
end;

function ScaleToDefaultPPI(Control: TControl; Value: Integer): Integer;
begin
  Result := MulDiv(Value, DefaultPPI, ControlPPI(Control));
end;

function ScaleFromDefaultPPI(Control: TControl; Value: Integer): Integer;
begin
  Result := MulDiv(Value, ControlPPI(Control), DefaultPPI);
end;

{ TFIBEditorCustomForm }

constructor TFIBEditorCustomForm.Create(AOwner: TComponent);
begin
  inherited;
  LastTop := -1;
  if not IsResizable then
    Exit;
  ReadPositions;
  if LastTop <> -1 then
  begin
    Position := poDesigned;
    Top := LastTop;
    Left := LastLeft;
    Width := ScaleFromDefaultPPI(Self, LastWidth);
    Height := ScaleFromDefaultPPI(Self, LastHeight);
  end;
end;

destructor TFIBEditorCustomForm.Destroy;
begin
  if IsResizable then
  begin
    LastTop := Top;
    LastLeft := Left;
    LastWidth := ScaleToDefaultPPI(Self, Width);
    LastHeight := ScaleToDefaultPPI(Self, Height);
    SavePositions;
  end;
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

procedure TFIBEditorCustomForm.ReadPositions;
{$IFNDEF NO_REGISTRY}
var
  v: Variant;
  i: integer;
{$ENDIF}
begin
{$IFNDEF NO_REGISTRY}
  v := DefReadFromRegistry(['Software', RegFIBRoot, ClassName], ['Top', 'Left', 'Height', 'Width']);
  if (VarType(v) <> varBoolean) then
    for i := 0 to 3 do
      if v[1, i] then
        case i of
          0: LastTop := v[0, i];
          1: LastLeft := v[0, i];
          2: LastHeight := v[0, i];
          3: LastWidth := v[0, i]
        end;
{$ENDIF}
end;

procedure TFIBEditorCustomForm.ReadState(Reader: TReader);
begin
  Reader.OnError := OnReadError;
  inherited ReadState(Reader)

end;

procedure TFIBEditorCustomForm.SavePositions;
begin
{$IFNDEF NO_REGISTRY}
  DefWriteToRegistry(['Software', RegFIBRoot, ClassName],
    ['Top', 'Left', 'Height', 'Width'], [LastTop, LastLeft, LastHeight, LastWidth]);
{$ENDIF}
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
