unit fibCheckSingleLicenseClass;

interface

uses Classes, fibAthlInstanceCounter;

type
  TFuncCallback = procedure;

type
  TCheckLicense = class{(TComponent)}
  private
    FAthlInstanceCounter: TAthlInstanceCounter;
    FIsValid: boolean;
    FInstanceCount: Integer;
    FCallBack: TfuncCallBack;
    procedure Change(Sender: TObject);
    procedure SetCallBack(const Value: TfuncCallBack);
  public
    property IsValid: boolean read FIsValid;
    property InstanceCount: Integer read FInstanceCount;
    constructor Create(License: string);
    destructor Destroy; override;
    property CallBack: TfuncCallBack read FCallBack write SetCallBack;
  end;

implementation

uses
  {Forms, }SysUtils;

{ TCheckLicense }

function GetHash(Str: string): string;
  function ElfHash(const Value: string): Integer;
  var
    i, x: Integer;
  begin
    Result := 0;
    for i := 1 to Length(Value) do
    begin
      Result := (Result shl 4) + Ord(Value[i]);
      x := Result and $F0000000;
      if (x <> 0) then
        Result := Result xor (x shr 24);
      Result := Result and (not x);
    end;
  end;
begin
  Result := Format('%x', [ElfHash(Str)]);
  if Length(Result) > 8 then
    Result := copy(Result, 1, 8);
end;

procedure TCheckLicense.Change(Sender: TObject);
begin
  FIsValid := FAthlInstanceCounter.CountComputers <= 1;
  FInstanceCount := FAthlInstanceCounter.CountComputers;
  if Assigned(FCallBack) then FCallBack;
end;

constructor TCheckLicense.Create(License: string);
begin
//  inherited Create(Application);
  FAthlInstanceCounter := nil;
  FIsValid := True;
  FInstanceCount := 0;
  FCallBack := nil;
  begin
    FAthlInstanceCounter := TAthlInstanceCounter.Create{(Self)};
    with FAthlInstanceCounter do
    begin
      InstanceName := GetHash(License);
      OnChange := Change;
      Interval := 5 * 1000;
      Active := True;
    end;
  end;
end;

destructor TCheckLicense.Destroy;
begin
   if Assigned(FAthlInstanceCounter) then FAthlInstanceCounter.Free;
   inherited;
end;

procedure TCheckLicense.SetCallBack(const Value: TfuncCallBack);
begin
  FCallBack := Value;
end;

initialization
//  CheckLicense := TCheckLicense.Create('CleverFilter');

finalization
//  if Assigned(CheckLicense) then FreeAndNil(CheckLicense);

end.

