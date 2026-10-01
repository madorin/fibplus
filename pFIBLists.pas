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

unit pFIBLists;

interface

uses
  SysUtils, Classes, FIBPlatforms;
{$I FIBPlus.inc}

type
{$IFDEF D_XE2}
  TFIBList = class(TList)
  private
    function GetPList: PPointerList;
  public
    property List: PPointerList read GetPList;
  end;
{$ELSE}

  TFIBList = TList;
{$ENDIF}

  TCallObject = class
  public
    constructor Create; virtual;
  end;

  TCallClass = class of TCallObject;

  TObjStringList = class
  private
    FOwner: TObject;
    FList: TStringList;
    FHashList: TList;
    FUseHash: boolean;
    function GetObject(const Index: integer): TObject;
    function GetCount: integer;
    function GetItem(const Index: integer): string;
    function HashFunc(const Str: string): integer;
    function FindInHash(const Search: string; var Hash, Index: integer): boolean;
  public
    constructor Create(Owner: TObject; aUseHash: boolean);
    destructor Destroy; override;
    procedure FullClear;
    function FindObject(const ObjName: string; ObjClass: TCallClass; var InitRes: boolean): integer;
    function Find(const S: string; var Index: integer): boolean;
    function AddObject(const S: string; AObject: TObject): integer;
    function IndexOfObject(AObject: TObject): integer;
    procedure Remove(const S: string);
    procedure Delete(Index: integer);

    property Objects[const Index: integer]: TObject read GetObject;
    property Count: integer read GetCount;
    property Item[const Index: integer]: string read GetItem; default;
    property UseHash: boolean read FUseHash;
  end;

  TSortedList = class(TObject)
    // Note : Only for Items compatibled with Integer
  private
    FList: TFIBList;
    FTag: integer;
    function GetItem(const Index: integer): integer;
    function GetCount: integer;
  protected
  public
    constructor Create;
    destructor Destroy; override;
    procedure IncValuesDiapazon(FromValue, ToValue: integer; Distance: integer);
    procedure IncValues(FromValue: integer; Distance: integer);
    function Add(const Item): integer;
    function Find(const Item; var Index: integer): boolean;
    function IndexOf(const Item): integer;
    procedure Delete(const Index: integer);
    procedure Remove(const Item);
    procedure Clear;
    function LastItem: integer;
    property Item[const Index: integer]: integer read GetItem; default;
    property Count: integer read GetCount;
    property Tag: integer read FTag write FTag;
  end;

  TStringCollection = class
  private
    FData: array of array of FIBByteString;
    FHighBounds: integer;
    FCount: integer;
    FCapacity: integer;
    procedure Grow;
    procedure SetCapacity(NewCapacity: integer);
    function GetValue(X, Y: integer): FIBByteString;
    procedure SetValue(X, Y: integer; const Value: FIBByteString);
    function GetPValue(X, Y: integer): PFIBByteString;
  public
    constructor Create(aHighBounds: integer);
    destructor Destroy; override;
    function Add: integer;
    procedure Clear;
    procedure Insert(Index: integer);
    procedure Delete(Index: integer);
    procedure Exchange(X1, X2: integer);
    procedure SetPCharValue(X, Y: integer; const Value: PAnsiChar; Len: integer);
    property PValue[X, Y: integer]: PFIBByteString read GetPValue;
    property Value[X, Y: integer]: FIBByteString read GetValue write SetValue; default;
    property HighX: integer read FHighBounds;
    property CountY: integer read FCount;
    property Capacity: integer read FCapacity write SetCapacity;
  end;

implementation

uses
  StdFuncs, StrUtil;

{$IFDEF D_XE2}

function TFIBList.GetPList: PPointerList;
begin
  Result := @ inherited List
end;

{$ENDIF}

{ TCallObject }
constructor TCallObject.Create;
begin
  inherited Create;
end;

{ TObjStringList }

function TObjStringList.AddObject(const S: string; AObject: TObject): integer;
var
  Hash: integer;
begin
  if not UseHash then
    Result := FList.AddObject(S, AObject)
  else
  begin
    if not FindInHash(S, Hash, Result) then
    begin
      FList.InsertObject(Result, S, AObject);
      FHashList.Insert(Result, Pointer(Hash))
    end;
  end;
end;

function TObjStringList.IndexOfObject(AObject: TObject): integer;
begin
  Result := FList.IndexOfObject(AObject);
end;

procedure TObjStringList.Remove(const S: string);
var
  Index: integer;
  Hash: integer;
begin
  if not UseHash then
  begin
    Index := FList.IndexOf(S);
    if Index > -1 then
      FList.Delete(Index);
  end
  else
  begin
    if FindInHash(S, Hash, Index) then
    begin
      FList.Delete(Index);
      FHashList.Delete(Index);
    end;
  end;
end;

constructor TObjStringList.Create(Owner: TObject; aUseHash: boolean);
begin
  inherited Create;
  FOwner := Owner;
  FList := TStringList.Create;
  if not aUseHash then
    with FList do
    begin
      Sorted := true;
      Duplicates := dupIgnore;
      FHashList := nil
    end
  else
  begin
    FHashList := TList.Create;
    FUseHash := aUseHash
  end;
end;

destructor TObjStringList.Destroy;
begin
  FullClear;
  FList.Free;
  FHashList.Free;
  inherited Destroy;
end;

function TObjStringList.Find(const S: string; var Index: integer): boolean;
var
  Hash: integer;
begin
  if not UseHash then
    Result := FList.Find(S, Index)
  else
    Result := FindInHash(S, Hash, Index)
end;

function TObjStringList.FindInHash(const Search: string; var Hash, Index: integer): boolean;
var
  L, H, I: integer;
begin
  Result := False;
  Hash := HashFunc(Search);

  // First item with a hash >= Hash. The hashes are compared, not subtracted:
  // they cover the whole Integer range and the difference would overflow,
  // breaking the order of the list.
  L := 0;
  H := FList.Count - 1;
  while L <= H do
  begin
    I := (L + H) shr 1;
    if integer(FHashList[I]) < Hash then
      L := I + 1
    else
      H := I - 1;
  end;

  // The items with the same hash (collisions) are next to each other
  Index := L;
  while (Index < FList.Count) and (integer(FHashList[Index]) = Hash) do
  begin
    if EquelNames(False, Search, FList[Index]) then
    begin
      Result := true;
      Exit;
    end;
    Inc(Index);
  end;

  // Not found: insert position
  Index := L;
end;

function TObjStringList.FindObject(const ObjName: string; ObjClass: TCallClass; var InitRes: boolean): integer;
var
  Hash: integer;
begin
  if not UseHash then
  begin
    with FList do
      if not Find(ObjName, Result) then
      begin
        InitRes := true;
        Result := AddObject(ObjName, ObjClass.Create);
      end
      else
        InitRes := False;
  end
  else if not FindInHash(ObjName, Hash, Result) then
  begin
    InitRes := true;
    FList.InsertObject(Result, ObjName, ObjClass.Create);
    FHashList.Insert(Result, Pointer(Hash))
  end
  else
    InitRes := False;
end;

procedure TObjStringList.FullClear;
var
  I: integer;
  Obj: TObject;
begin
  // Backwards: freeing an object may remove it from the list
  // (FreeNotification of the list owner)
  for I := FList.Count - 1 downto 0 do
  begin
    Obj := FList.Objects[I];
    if (Obj is TComponent) and (csDestroying in TComponent(Obj).ComponentState) then
      Continue;
    Obj.Free;
  end;
  FList.Clear;
  if FUseHash then
    FHashList.Clear;
end;

function TObjStringList.GetCount: integer;
begin
  Result := FList.Count
end;

function TObjStringList.GetItem(const Index: integer): string;
begin
  Result := FList[Index]
end;

function TObjStringList.GetObject(const Index: integer): TObject;
begin
  Result := FList.Objects[Index]
end;

function TObjStringList.HashFunc(const Str: string): integer;
var
  I: integer;
begin
  // All the chars: sampling only some of them made similar SQL texts
  // (e.g. different generator names) collide. Overflow wraps ({$Q-}).
  Result := 0;
  for I := 1 to Length(Str) do
    Result := Result * 37 + Ord(Str[I]);
end;

procedure TObjStringList.Delete(Index: integer);
begin
  FList.Delete(Index);
  if FUseHash then
    FHashList.Delete(Index);
end;

{ TSortedList }

constructor TSortedList.Create;
begin
  inherited Create;
  FList := TFIBList.Create;
end;

function TSortedList.Add(const Item): integer;
begin
  if not Find(Item, Result) then
    FList.Insert(Result, Pointer(Item));
end;

procedure TSortedList.Delete(const Index: integer);
begin
  FList.Delete(Index);
end;

destructor TSortedList.Destroy;
begin
  FList.Free;
  inherited Destroy;
end;

procedure TSortedList.IncValuesDiapazon(FromValue, ToValue: integer; Distance: integer);
var
  I: integer;
  Index: integer;
  Index1: integer;
  MaxValue: integer;
  MinValue: integer;

begin
  if FList.Count = 0 then
    Exit;
  if FromValue > ToValue then
  begin
    MaxValue := FromValue;
    MinValue := ToValue;
  end
  else
  begin
    MaxValue := ToValue;
    MinValue := FromValue;
  end;
  Find(MinValue, Index);
  Find(MaxValue, Index1);
  if Index1 >= FList.Count then
    Index1 := FList.Count - 1;
  if MaxValue < integer(FList.List^[Index1]) then
    Dec(Index1);

  for I := Index1 downto Index do
    FList.List^[I] := Pointer(integer(FList.List^[I]) + Distance)

end;

procedure TSortedList.IncValues(FromValue: integer; Distance: integer);
var
  I: integer;
  Index: integer;
begin
  Find(FromValue, Index);
  for I := FList.Count - 1 downto Index do
    FList.List^[I] := Pointer(integer(FList.List^[I]) + Distance)
end;

function TSortedList.Find(const Item; var Index: integer): boolean;
var
  L, H, I, C: integer;

  function Compare(I, I1: integer): integer;
  begin
    if I = I1 then
      Result := 0
    else if I > I1 then
      Result := 1
    else
      Result := -1;
  end;

begin
  Result := False;
  L := 0;
  H := FList.Count - 1;

  while L <= H do
  begin
    I := (L + H) shr 1;
    C := Compare(integer(FList.List^[I]), integer(Item));
    if C < 0 then
      L := I + 1
    else
    begin
      H := I - 1;
      if C = 0 then
        Result := true;
    end;
  end;
  Index := L;
end;

function TSortedList.IndexOf(const Item): integer;
begin
  if not Find(Item, Result) then
    Result := -1
end;

procedure TSortedList.Remove(const Item);
var
  Index: integer;
begin
  if Find(Item, Index) then
    FList.Delete(Index);
end;

function TSortedList.GetItem(const Index: integer): integer;
begin
  Result := integer(FList.List^[Index]);
end;

function TSortedList.GetCount: integer;
begin
  Result := FList.Count
end;

procedure TSortedList.Clear;
begin
  FList.Clear
end;

function TSortedList.LastItem: integer;
begin
  if Count = 0 then
    Result := -1
  else
    Result := integer(FList.List^[FList.Count - 1])
end;

{ TStringCollection }

function TStringCollection.Add: integer;
var
  I: integer;
  C: integer;
begin
  if FCapacity = FCount then
    Grow;
  C := Pred(FHighBounds);
  for I := 0 to C do
    Pointer(FData[I][FCount]) := nil;
  Inc(FCount);
  Result := FCount
end;

procedure TStringCollection.Clear;
begin
  Finalize(FData[0], FHighBounds);
  FCount := 0;
  FCapacity := 0;
end;

constructor TStringCollection.Create(aHighBounds: integer);
begin
  inherited Create;
  FHighBounds := aHighBounds;
  SetLength(FData, aHighBounds);
end;

procedure TStringCollection.Delete(Index: integer);
var
  I: integer;
begin
  for I := 0 to Pred(FHighBounds) do
  begin
    Finalize(FData[I][Index]);
    if Index < FCount - 1 then
      Move(FData[I][Index + 1], FData[I][Index], (FCount - Index) * SizeOf(string));
  end;
  Dec(FCount);
end;

destructor TStringCollection.Destroy;
begin
  Clear;
  SetLength(FData, 0);
  inherited;
end;

procedure TStringCollection.Exchange(X1, X2: integer);
var
  I: integer;
  p: Pointer;
begin
  for I := 0 to Pred(FHighBounds) do
  begin
    p := Pointer(FData[I][X1]);
    Pointer(FData[I][X1]) := Pointer(FData[I][X2]);
    Pointer(FData[I][X2]) := p
  end;
end;

function TStringCollection.GetPValue(X, Y: integer): PFIBByteString;
begin
  { Assert(X<=FHighBounds,'Can''t read value to StrCollection. Bad X-Index');
    Assert(Y<FCount,'Can''t read value to StrCollection. Bad Y-Index'); }
  if (X <= FHighBounds) and (Y < FCount) then
    Result := @(FData[X][Y])
  else
  begin
    Result := nil
  end;
end;

function TStringCollection.GetValue(X, Y: integer): FIBByteString;
begin
  Assert(X <= FHighBounds, 'Can''t read value to StrCollection. Bad X-Index');
  Assert(Y < FCount, 'Can''t read value to StrCollection. Bad Y-Index');
  Result := FData[X][Y]
end;

procedure TStringCollection.Grow;
begin
  if FCapacity = 0 then
    SetCapacity(128)
  else
    SetCapacity(FCapacity + (FCapacity shr 1));
end;

procedure TStringCollection.Insert(Index: integer);
var
  I: integer;
begin
  if FCount = FCapacity then
    Grow;
  if Index < FCount then
    for I := 0 to Pred(FHighBounds) do
    begin
      Move(FData[I][Index], FData[I][Index + 1], (FCount - Index) * SizeOf(string));
      Pointer(FData[I][Index]) := nil;
    end;
  Inc(FCount);
end;

procedure TStringCollection.SetCapacity(NewCapacity: integer);
var
  I: integer;
begin
  for I := 0 to FHighBounds - 1 do
    SetLength(FData[I], NewCapacity);
  // SetLength(PStrArray(@FData)^,NewCapacity*FHighBounds);
  FCapacity := NewCapacity;
end;

procedure TStringCollection.SetValue(X, Y: integer; const Value: FIBByteString);
var
  Len: integer;
begin
  Assert(X <= FHighBounds, 'Can''t write value to StrCollection. Bad X-Index');
  Assert(Y < FCount, 'Can''t write value to StrCollection. Bad Y-Index');
  Len := Length(Value);
  if Len = 0 then
    FData[X][Y] := ''
  else
    SetString(FData[X][Y], PAnsiChar(@Value[1]), Length(Value));
end;

procedure TStringCollection.SetPCharValue(X, Y: integer; const Value: PAnsiChar; Len: integer);
begin
  Assert(X <= FHighBounds, 'Can''t write value to StrCollection. Bad X-Index');
  Assert(Y < FCount, 'Can''t write value to StrCollection. Bad Y-Index');
  if Len < 0 then
    SetString(FData[X][Y], Value, Q_StrLen(Value))
  else if Len = 0 then
    FData[X][Y] := ''
  else
  begin
    SetString(FData[X][Y], Value, Len)
  end;
end;

end.
