unit uFIBEditorForm;

interface
{$i ..\FIBPlus.inc}
  uses Classes,{$IFDEF D6+}Variants, {$ENDIF}{$IFDEF D_XE2}Vcl.Forms{$ELSE}Forms{$ENDIF};

  type
        TFIBEditorCustomForm= class(TForm)
        protected
         procedure ReadState(Reader: TReader); override;
         procedure OnReadError(Reader: TReader; const Message: string; var Handled: Boolean);
        protected
           LastTop, LastLeft,   LastWidth,LastHeight:integer;
           procedure ReadPositions;
           procedure SavePositions;
        public
           constructor Create(AOwner:TComponent);override;
           destructor Destroy; override;
        end;


        TFIBEditorCustomFrame= class(TFrame)
        protected
         procedure ReadState(Reader: TReader); override;
         procedure OnReadError(Reader: TReader; const Message: string; var Handled: Boolean);
        end;


implementation
uses RegistryUtils;
{ TFIBEditorCustomForm }

constructor TFIBEditorCustomForm.Create(AOwner: TComponent);
begin
  inherited;
  LastTop:=-1;
  ReadPositions;

  if LastTop<>-1 then
  begin
    Position:=poDesigned;
    Top   :=LastTop;
    Left  :=LastLeft;
    Width :=LastWidth;
    Height:=LastHeight;
  end;
end;

destructor TFIBEditorCustomForm.Destroy;
begin
  LastTop   :=Top;
  LastLeft  :=Left;
  LastWidth :=Width;
  LastHeight:=Height;
  SavePositions;
  inherited;
end;

procedure TFIBEditorCustomForm.OnReadError(Reader: TReader;
  const Message: string; var Handled: Boolean);
begin
  Handled:=True
end;

procedure TFIBEditorCustomForm.ReadPositions;
{$IFNDEF NO_REGISTRY}
var v:Variant;
    i:integer;
{$ENDIF}
begin
{$IFNDEF NO_REGISTRY}
 v:=
  DefReadFromRegistry(['Software',RegFIBRoot,ClassName],
   ['Top',
    'Left',
    'Height',
    'Width'

   ]
 );
 if (VarType(v)<>varBoolean) then
  for i:=0 to 3 do
   if V[1,i] then
   case i of
    0: LastTop               :=V[0,i];
    1: LastLeft              :=V[0,i];
    2: LastHeight:=V[0,i];
    3: LastWidth :=V[0,i]

   end;

{$ENDIF}

end;

procedure TFIBEditorCustomForm.ReadState(Reader: TReader);
begin
 Reader.OnError:=OnReadError;
 inherited ReadState(Reader)

end;

procedure TFIBEditorCustomForm.SavePositions;
begin
{$IFNDEF NO_REGISTRY}
 DefWriteToRegistry(['Software',RegFIBRoot,ClassName],
   ['Top',
    'Left',
    'Height',
    'Width'
   ],
   [
    LastTop,
    LastLeft,
    LastHeight,
    LastWidth
   ]
 );

{$ENDIF}

end;

{ TFIBEditorCustomFrame }

procedure TFIBEditorCustomFrame.OnReadError(Reader: TReader;
  const Message: string; var Handled: Boolean);
begin
  Handled:=True
end;

procedure TFIBEditorCustomFrame.ReadState(Reader: TReader);
begin
 Reader.OnError:=OnReadError;
 inherited ReadState(Reader)
end;

end.
