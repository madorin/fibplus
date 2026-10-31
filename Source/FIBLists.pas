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
{    Written by Serge Buzadzhy                                  }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit FIBLists;

interface

uses
  SysUtils, Classes, FIBPlatforms;
{$I FIB.inc}

type
{$IFDEF C23}
  TFIBList = class(TList)
  private
    function GetPList: PPointerList;
  public
    property List: PPointerList read GetPList;
  end;
{$ELSE}
  TFIBList = TList;
{$ENDIF}

  TFIBCreatableObject = class
  public
    constructor Create; virtual;
  end;

  TFIBCreatableClass = class of TFIBCreatableObject;

  TFIBObjectStringList = class
  private
    FOwner: TObject;
    FList: TStringList;
    FHashList: TList;
    FUseHash: Boolean;
    function GetObject(const Index: Integer): TObject;
    function GetCount: Integer;
    function GetItem(const Index: Integer): string;
    function HashFunc(const Str: string): Integer;
    function FindInHash(const Search: string; var Hash, Index: Integer): Boolean;
  public
    constructor Create(Owner: TObject; aUseHash: Boolean);
    destructor Destroy; override;
    procedure FullClear;
    function FindObject(const ObjName: string; ObjClass: TFIBCreatableClass; var InitRes: Boolean): Integer;
    function Find(const S: string; var Index: Integer): Boolean;
    function AddObject(const S: string; AObject: TObject): Integer;
    function IndexOfObject(AObject: TObject): Integer;
    procedure Remove(const S: string);
    procedure Delete(Index: Integer);

    property Objects[const Index: Integer]: TObject read GetObject;
    property Count: Integer read GetCount;
    property Item[const Index: Integer]: string read GetItem; default;
    property UseHash: Boolean read FUseHash;
  end;

  TFIBSortedIntegerList = class(TObject)
    // Note : Only for Items compatibled with Integer
  private
    FList: TFIBList;
    function GetItem(const Index: Integer): Integer;
    function GetCount: Integer;
  protected
  public
    constructor Create;
    destructor Destroy; override;
    procedure IncValuesInRange(FromValue, ToValue: Integer; Distance: Integer);
    procedure IncValues(FromValue: Integer; Distance: Integer);
    function Add(const Item): Integer;
    function Find(const Item; var Index: Integer): Boolean;
    procedure Remove(const Item);
    procedure Clear;
    function LastItem: Integer;
    property Item[const Index: Integer]: Integer read GetItem; default;
    property Count: Integer read GetCount;
  end;

  TFIBStringCollection = class
  private
    FData: array of array of FIBByteString;
    FHighBounds: Integer;
    FCount: Integer;
    FCapacity: Integer;
    procedure Grow;
    procedure SetCapacity(NewCapacity: Integer);
    function GetValue(X, Y: Integer): FIBByteString;
    procedure SetValue(X, Y: Integer; const Value: FIBByteString);
    function GetPValue(X, Y: Integer): PFIBByteString;
  public
    constructor Create(aHighBounds: Integer);
    destructor Destroy; override;
    function Add: Integer;
    procedure Clear;
    procedure Delete(Index: Integer);
    procedure SetPCharValue(X, Y: Integer; const Value: PAnsiChar; Len: Integer);
    property PValue[X, Y: Integer]: PFIBByteString read GetPValue;
    property Value[X, Y: Integer]: FIBByteString read GetValue write SetValue; default;
    property HighX: Integer read FHighBounds;
    property CountY: Integer read FCount;
    property Capacity: Integer read FCapacity write SetCapacity;
  end;

type
  // Deprecated names of the types renamed in 8.0.0
  TCallObject = TFIBCreatableObject deprecated 'Use TFIBCreatableObject';
  TCallClass = TFIBCreatableClass deprecated 'Use TFIBCreatableClass';
  TObjStringList = TFIBObjectStringList deprecated 'Use TFIBObjectStringList';
  TSortedList = TFIBSortedIntegerList deprecated 'Use TFIBSortedIntegerList';
  TStringCollection = TFIBStringCollection deprecated 'Use TFIBStringCollection';

implementation

uses
  StdFuncs, StrUtil;

{$IFDEF C23}
function TFIBList.GetPList: PPointerList;
begin
  Result := @ inherited List
end;

{$ENDIF}

{ TFIBCreatableObject }
constructor TFIBCreatableObject.Create;
begin
  inherited Create;
end;

{ TFIBObjectStringList }

function TFIBObjectStringList.AddObject(const S: string; AObject: TObject): Integer;
var
  Hash: Integer;
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

function TFIBObjectStringList.IndexOfObject(AObject: TObject): Integer;
begin
  Result := FList.IndexOfObject(AObject);
end;

procedure TFIBObjectStringList.Remove(const S: string);
var
  Index: Integer;
  Hash: Integer;
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

constructor TFIBObjectStringList.Create(Owner: TObject; aUseHash: Boolean);
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

destructor TFIBObjectStringList.Destroy;
begin
  FullClear;
  FList.Free;
  FHashList.Free;
  inherited Destroy;
end;

function TFIBObjectStringList.Find(const S: string; var Index: Integer): Boolean;
var
  Hash: Integer;
begin
  if not UseHash then
    Result := FList.Find(S, Index)
  else
    Result := FindInHash(S, Hash, Index)
end;

function TFIBObjectStringList.FindInHash(const Search: string; var Hash, Index: Integer): Boolean;
var
  L, H, I: Integer;
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
    if Integer(FHashList[I]) < Hash then
      L := I + 1
    else
      H := I - 1;
  end;

  // The items with the same hash (collisions) are next to each other
  Index := L;
  while (Index < FList.Count) and (Integer(FHashList[Index]) = Hash) do
  begin
    if EqualNames(False, Search, FList[Index]) then
    begin
      Result := true;
      Exit;
    end;
    Inc(Index);
  end;

  // Not found: insert position
  Index := L;
end;

function TFIBObjectStringList.FindObject(const ObjName: string; ObjClass: TFIBCreatableClass; var InitRes: Boolean): Integer;
var
  Hash: Integer;
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

procedure TFIBObjectStringList.FullClear;
var
  I: Integer;
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

function TFIBObjectStringList.GetCount: Integer;
begin
  Result := FList.Count
end;

function TFIBObjectStringList.GetItem(const Index: Integer): string;
begin
  Result := FList[Index]
end;

function TFIBObjectStringList.GetObject(const Index: Integer): TObject;
begin
  Result := FList.Objects[Index]
end;

function TFIBObjectStringList.HashFunc(const Str: string): Integer;
var
  I: Integer;
begin
  // All the chars: sampling only some of them made similar SQL texts
  // (e.g. different generator names) collide. Overflow wraps ({$Q-}).
  Result := 0;
  for I := 1 to Length(Str) do
    Result := Result * 37 + Ord(Str[I]);
end;

procedure TFIBObjectStringList.Delete(Index: Integer);
begin
  FList.Delete(Index);
  if FUseHash then
    FHashList.Delete(Index);
end;

{ TFIBSortedIntegerList }

constructor TFIBSortedIntegerList.Create;
begin
  inherited Create;
  FList := TFIBList.Create;
end;

function TFIBSortedIntegerList.Add(const Item): Integer;
begin
  if not Find(Item, Result) then
    FList.Insert(Result, Pointer(Item));
end;

destructor TFIBSortedIntegerList.Destroy;
begin
  FList.Free;
  inherited Destroy;
end;

procedure TFIBSortedIntegerList.IncValuesInRange(FromValue, ToValue: Integer; Distance: Integer);
var
  I: Integer;
  Index: Integer;
  Index1: Integer;
  MaxValue: Integer;
  MinValue: Integer;

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
  if Index1 >= Count then
    Index1 := Count - 1;
  if MaxValue < Integer(FList.List^[Index1]) then
    Dec(Index1);

  for I := Index1 downto Index do
    FList.List^[I] := Pointer(Integer(FList.List^[I]) + Distance)

end;

procedure TFIBSortedIntegerList.IncValues(FromValue: Integer; Distance: Integer);
var
  I: Integer;
  Index: Integer;
begin
  Find(FromValue, Index);
  for I := Count - 1 downto Index do
    FList.List^[I] := Pointer(Integer(FList.List^[I]) + Distance)
end;

function TFIBSortedIntegerList.Find(const Item; var Index: Integer): Boolean;
var
  L, H, I, C: Integer;

  function Compare(I, I1: Integer): Integer;
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
  H := Count - 1;

  while L <= H do
  begin
    I := (L + H) shr 1;
    C := Compare(Integer(FList.List^[I]), Integer(Item));
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

procedure TFIBSortedIntegerList.Remove(const Item);
var
  Index: Integer;
begin
  if Find(Item, Index) then
    FList.Delete(Index);
end;

function TFIBSortedIntegerList.GetItem(const Index: Integer): Integer;
begin
  Result := Integer(FList.List^[Index]);
end;

function TFIBSortedIntegerList.GetCount: Integer;
begin
  Result := Integer(FList.Count)
end;

procedure TFIBSortedIntegerList.Clear;
begin
  FList.Clear
end;

function TFIBSortedIntegerList.LastItem: Integer;
begin
  if Count = 0 then
    Result := -1
  else
    Result := Integer(FList.List^[FList.Count - 1])
end;

{ TFIBStringCollection }

function TFIBStringCollection.Add: Integer;
var
  I: Integer;
  C: Integer;
begin
  if FCapacity = FCount then
    Grow;
  C := Pred(FHighBounds);
  for I := 0 to C do
    Pointer(FData[I][FCount]) := nil;
  Inc(FCount);
  Result := FCount
end;

procedure TFIBStringCollection.Clear;
begin
  Finalize(FData[0], FHighBounds);
  FCount := 0;
  FCapacity := 0;
end;

constructor TFIBStringCollection.Create(aHighBounds: Integer);
begin
  inherited Create;
  FHighBounds := aHighBounds;
  SetLength(FData, aHighBounds);
end;

procedure TFIBStringCollection.Delete(Index: Integer);
var
  I: Integer;
begin
  for I := 0 to Pred(FHighBounds) do
  begin
    Finalize(FData[I][Index]);
    if Index < FCount - 1 then
      Move(FData[I][Index + 1], FData[I][Index], (FCount - Index) * SizeOf(string));
  end;
  Dec(FCount);
end;

destructor TFIBStringCollection.Destroy;
begin
  Clear;
  SetLength(FData, 0);
  inherited;
end;

function TFIBStringCollection.GetPValue(X, Y: Integer): PFIBByteString;
begin
  if (X >= 0) and (X < FHighBounds) and (Y >= 0) and (Y < FCount) then
    Result := @(FData[X][Y])
  else
  begin
    Result := nil
  end;
end;

function TFIBStringCollection.GetValue(X, Y: Integer): FIBByteString;
begin
  Assert(X < FHighBounds, 'Can''t read value to StrCollection. Bad X-Index');
  Assert(Y < FCount, 'Can''t read value to StrCollection. Bad Y-Index');
  Result := FData[X][Y]
end;

procedure TFIBStringCollection.Grow;
begin
  if FCapacity = 0 then
    SetCapacity(128)
  else
    SetCapacity(FCapacity + (FCapacity shr 1));
end;

procedure TFIBStringCollection.SetCapacity(NewCapacity: Integer);
var
  I: Integer;
begin
  for I := 0 to FHighBounds - 1 do
    SetLength(FData[I], NewCapacity);
  FCapacity := NewCapacity;
end;

procedure TFIBStringCollection.SetValue(X, Y: Integer; const Value: FIBByteString);
var
  Len: Integer;
begin
  Assert(X < FHighBounds, 'Can''t write value to StrCollection. Bad X-Index');
  Assert(Y < FCount, 'Can''t write value to StrCollection. Bad Y-Index');
  Len := Length(Value);
  if Len = 0 then
    FData[X][Y] := ''
  else
    SetString(FData[X][Y], PAnsiChar(@Value[1]), Length(Value));
end;

procedure TFIBStringCollection.SetPCharValue(X, Y: Integer; const Value: PAnsiChar; Len: Integer);
begin
  Assert(X < FHighBounds, 'Can''t write value to StrCollection. Bad X-Index');
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
