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

 uses SysUtils,Classes,FIBPlatforms;
{$I FIBPlus.inc}
type
     {$IFDEF D_XE2}
      TFIBList=class (TList)
      private
       function GetPList:PPointerList;
      public
       property List: PPointerList read GetPList;
      end;
    {$ELSE}
      TFIBList=TList;
    {$ENDIF}

    TCallObject = class
    public
     constructor Create; virtual;
    end;

    TCallClass= class of TCallObject;

    TObjStringList= class
    private
      FOwner:TObject;
      FList :TStringList;
      FHashList:TList;
      FUseHash:boolean;
      function GetObject(const Index:integer):TObject;
      function GetCount: integer;
      function GetItem(const Index: integer): string;
      function HashFunc(Str: PChar): Integer;
      function FindInHash(const Search: string; var Hash,Index: Integer): Boolean;
    public
     constructor Create(Owner:TObject;aUseHash:boolean);
     destructor  Destroy ; override;
     procedure   FullClear;
     function    FindObject(const ObjName:string;ObjClass:TCallClass; var InitRes:boolean):integer;
     function    Find(const S: string; var Index: Integer): Boolean;
     function    AddObject(const S: string; AObject: TObject): Integer;
     procedure   Remove(const S: string);
     procedure   Delete(Index:integer);

     property    Objects[const Index:integer]:TObject read GetObject;
     property    Count:integer read GetCount;
     property    Item[const Index:integer]:string read GetItem; default;
     property    UseHash:boolean read FUseHash;
    end;

     TSortedList=class(TObject)
// Note : Only for Items compatibled with Integer
     private
      FList:TFIBList;
      FTag :integer;
      function    GetItem(const Index:integer):integer;
      function    GetCount:integer;
     protected
     public
      constructor Create;
      destructor  Destroy; override;
      procedure   IncValuesDiapazon(FromValue,ToValue:integer; Distance:integer);      
      procedure   IncValues(FromValue:integer; Distance:integer);
      function    Add(const Item):integer;
      function    Find(const Item; var Index:integer):boolean ;
      function    IndexOf(const Item ):integer;
      procedure   Delete(const Index:integer);
      procedure   Remove(const Item);
      procedure   Clear;
      function    LastItem:integer;
      property    Item[const Index :integer]:integer read GetItem;default;
      property    Count:integer read GetCount;
      property    Tag :integer read FTag write FTag;
     end;



     TStringCollection = class
     private
      FData      :array of array of FIBByteString;
      FHighBounds:integer;
      FCount     :integer;
      FCapacity  :integer;
      procedure   Grow;
      procedure   SetCapacity(NewCapacity:integer);
      function    GetValue(X, Y: integer): FIBByteString;
      procedure   SetValue(X, Y: integer; const Value: FIBByteString);
      function    GetPValue(X, Y: integer): PFIBByteString;
     public
      constructor Create(aHighBounds:integer);
      destructor  Destroy; override;
      function    Add:integer;
      procedure   Clear;
      procedure   Insert(Index: Integer);
      procedure   Delete(Index: Integer);
      procedure   Exchange(X1,X2:integer);
      procedure   SetPCharValue(X, Y: integer; const Value: PAnsiChar;Len:integer);
      property    PValue[X,Y:integer]:PFIBByteString read GetPValue;
      property    Value[X,Y:integer]:FIBByteString read GetValue write SetValue; default;
      property    HighX:integer read FHighBounds;
      property    CountY:integer read FCount;
      property    Capacity  :integer read FCapacity write SetCapacity;
     end;


implementation

uses StdFuncs,StrUtil;


  {$IFDEF D_XE2}
      function TFIBList.GetPList:PPointerList;
      begin
        Result:=@inherited List
      end;

  {$ENDIF}

{ TCallObject }
constructor TCallObject.Create;
begin
 inherited Create;
end;

{ TObjStringList }


function TObjStringList.AddObject(const S: string;
  AObject: TObject): Integer;
var Hash:integer;
begin
 if not UseHash then
  Result:=FList.AddObject(S,AObject)
 else
 begin
   if not FindInHash(S,Hash,Result) then
   begin
    FList.InsertObject(Result,S,AObject);
    FHashList.Insert(Result,Pointer(Hash))
   end;
 end;
end;

procedure TObjStringList.Remove(const S: string);
var Index:integer;
    Hash :integer;
begin
 if not UseHash then
 begin
  Index:=FList.IndexOf(S);
  if Index>-1 then
   FList.Delete(Index);
 end
 else
 begin
   if FindInHash(S,Hash,Index) then
   begin
    FList.Delete(Index);
    FHashList.Delete(Index);
   end;
 end;
end;

constructor TObjStringList.Create(Owner:TObject;aUseHash:boolean);
begin
 inherited Create;
 FOwner:=Owner;
 FList :=TStringList.Create;
 if not aUseHash then
 with  FList do
 begin
  Sorted :=true;
  Duplicates:=dupIgnore;
  FHashList:=nil
 end 
 else
 begin
  FHashList:=TList.Create;
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

function TObjStringList.Find(const S: string; var Index: Integer): Boolean;
var Hash:integer;
begin
 if not UseHash then
  Result:=FList.Find(S,Index)
 else
  Result:=FindInHash(S,Hash,Index)
end;

function TObjStringList.FindInHash(const Search: string; var Hash,
  Index: Integer): Boolean;
var
  L, H, I, C: Integer;
begin
 with FList do
 begin
  Result := False;
  L := 0;
  H := Count - 1;
  Hash:=HashFunc(PChar(Search));
  while (L <= H)  do
  begin
    I := (L + H) shr 1;
    C := Signum(Integer(FHashList[I]) - Hash);
    if C < 0 then
     L := I + 1
    else
    begin
      H := I - 1;
      if C = 0 then
      begin
        Result :=EquelNames(False,Search,FList[I]);
        if not Result then
        begin
         while (I>=0) and (Hash=Integer(FHashList[I]))  do Dec(I);
         Inc(I);
         Result :=EquelNames(False,Search,FList[I]);
        end; 
        while not Result and (Hash=Integer(FHashList[I])) do
        begin
         Inc(I);
         if i<FList.Count then
          Result := EquelNames(False,Search,FList[I])
         else
         begin
          Index := I;
          Exit;
         end;
        end;
        if Result then
        begin
         Index := I;
         Exit;
        end;
      end;
    end;
  end;
  Index := L;
 end;
end;

function  TObjStringList.
 FindObject(const ObjName:string;ObjClass:TCallClass; var InitRes:boolean):integer;
var Hash:integer;
begin
  if not UseHash then
  begin
    with  FList do
    if not Find(ObjName,Result) then
    begin
      InitRes:=true;
      Result:= AddObject(ObjName,ObjClass.Create);
    end
    else
     InitRes:=false;
  end
  else
   if not FindInHash(ObjName,Hash,Result) then
   begin
    InitRes:=true;
    FList.InsertObject(Result,ObjName,ObjClass.Create);
    FHashList.Insert(Result,Pointer(Hash))
   end
   else
     InitRes:=false;
end;

procedure TObjStringList.FullClear;
var i:integer;
begin
  with  FList do
  begin
   for i:=Pred(Count) downto 0 do
   begin
    if (Objects[i] is TComponent) and  (csDestroying in TComponent(Objects[i]).ComponentState) then
      Continue;
    Objects[i].Free;
   end;
   Clear
  end
end;

function TObjStringList.GetCount: integer;
begin
 result:=FList.Count
end;

function TObjStringList.GetItem(const Index: integer): string;
begin
 Result:=FList[Index]
end;

function TObjStringList.GetObject(const Index: integer): TObject;
begin
 Result:=FList.Objects[Index]
end;

function TObjStringList.HashFunc(Str: PChar): Integer;
var
  Off, Len, Skip, I: Integer;
begin
  Result := 0;
  Off := 1;
//  Len := Q_StrLen(Str);
  Len:=Length(Str);
  if Len < 16 then
    for I := (Len - 1) downto 0 do
    begin
      Result := Result * 37 + Ord(Str[Off])-32;
      Inc(Off);
    end
  else
  begin
    { Only sample some characters }
    Skip := Len div 8;
    I := Len - 1;
    while I >= 0 do                               
    begin
      Result := Result * 39+ Ord(Str[Off]) -32;
      Dec(I, Skip);
      Inc(Off, Skip);
    end;
  end;
end;

procedure TObjStringList.Delete(Index: integer);
begin
    FList.Delete(Index);
    if FUseHash then FHashList.Delete(Index);
end;

{ TSortedList }

constructor TSortedList.Create;
begin
 inherited Create;
 FList:=TFIBList.Create;
end;

function TSortedList.Add(const Item): integer;
begin
 if not Find(Item,Result) then
   FList.Insert(Result,Pointer(Item));
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

procedure TSortedList.IncValuesDiapazon(FromValue,ToValue:integer; Distance:integer);
var
    i     :integer;
    Index :integer;
    Index1:integer;
    MaxValue:integer;
    MinValue:integer;
      
begin
 if FList.Count=0 then Exit;
 if FromValue>ToValue then
 begin
   MaxValue:=FromValue;
   MinValue:=ToValue;
 end
 else
 begin
   MaxValue:=ToValue;
   MinValue:=FromValue;
 end;
 Find(MinValue, Index);
 Find(MaxValue, Index1);
 if Index1>=FList.Count then  Index1:=FList.Count-1;
 if MaxValue<Integer(FList.List^[Index1]) then Dec(Index1);

 for i:=Index1 downto Index do
   FList.List^[i]:=Pointer(Integer(FList.List^[i])+Distance)

end;

procedure TSortedList.IncValues(FromValue:integer; Distance:integer);
var
    i:integer;
    Index:integer;
begin
 Find(FromValue, Index);
 for i:=FList.Count-1 downto Index do
  FList.List^[i]:=Pointer(Integer(FList.List^[i])+Distance)
end;

function TSortedList.Find(const Item; var Index: integer): boolean;
var
  L, H, I, C: Integer;

 function Compare(I,I1:integer):integer;
 begin
    if I=I1 then Result:=0  else
    if I>I1 then  Result:=1 else Result:=-1;
 end;
begin
  Result := False;
  L := 0;
  H := FList.Count - 1;
 
 
  while L <= H do
  begin
    I := (L + H) shr 1;
    C:=Compare(Integer(FList.List^[I]),Integer(Item));
    if C < 0 then
     L := I + 1
    else
    begin
      H := I - 1;
      if C = 0 then
        Result := True;
    end;
  end;
  Index := L;
end;

function TSortedList.IndexOf(const Item): integer;
begin
 if not Find(Item,Result) then
  Result:=-1
end;

procedure TSortedList.Remove(const Item);
var Index:integer;
begin
 if Find(Item,Index) then
  FList.Delete(Index);
end;

function TSortedList.GetItem(const Index: integer): integer;
begin
 Result:=Integer(FList.List^[Index]);
end;

function TSortedList.GetCount: integer;
begin
 Result:=FList.Count
end;

procedure TSortedList.Clear;
begin
 FList.Clear
end;

function TSortedList.LastItem: integer;
begin
  if Count=0 then
   Result := -1
  else
   Result :=Integer(FList.List^[FList.Count-1])
end;

{ TStringCollection }

function TStringCollection.Add: integer;
var
  i:integer;
  c:integer;
begin
 if FCapacity=FCount then
  Grow;
 c:=Pred(FHighBounds);
 for i:=0 to c do
  Pointer(FData[i][FCount]) := nil;
 Inc(FCount);
 Result:=FCount
end;

procedure TStringCollection.Clear;
begin
  Finalize(FData[0],FHighBounds);
  FCount := 0;
  FCapacity := 0;
end;

constructor TStringCollection.Create(aHighBounds: integer);
begin
  inherited Create;
  FHighBounds:=aHighBounds;
  SetLength(FData,aHighBounds);
  FCount     :=0;
  FCapacity  :=0;
end;

procedure TStringCollection.Delete(Index: Integer);
var
 i:integer;
begin
  for i:=0 to Pred(FHighBounds) do
  begin
    Finalize(FData[i][Index]);
    if Index<FCount-1 then
     Move(FData[i][Index+1], FData[i][Index],(FCount - Index) * SizeOf(string));
  end;
  Dec(FCount);
end;

destructor TStringCollection.Destroy;
begin
  Clear;
  SetLength(FData,0);
  inherited;
end;

procedure TStringCollection.Exchange(X1, X2: integer);
var
  i:integer;
  p:Pointer;
begin
 for i:=0 to Pred(FHighBounds) do
 begin
  p:=Pointer(FData[i][X1]);
  Pointer(FData[i][X1]):=Pointer(FData[i][X2]);
  Pointer(FData[i][X2]):=p
 end;
end;

function TStringCollection.GetPValue(X, Y: integer): PFIBByteString;
begin
{ Assert(X<=FHighBounds,'Can''t read value to StrCollection. Bad X-Index');
 Assert(Y<FCount,'Can''t read value to StrCollection. Bad Y-Index');}
 if (X<=FHighBounds) and  (Y<FCount) then
  Result:=@(FData[X][Y])
 else
 begin
  Result:=nil
 end;
end;


function TStringCollection.GetValue(X, Y: integer): FIBByteString;
begin
 Assert(X<=FHighBounds,'Can''t read value to StrCollection. Bad X-Index');
 Assert(Y<FCount,'Can''t read value to StrCollection. Bad Y-Index');
 Result:=FData[X][Y]
end;

procedure TStringCollection.Grow;
begin
  if FCapacity=0 then
    SetCapacity(128)
  else
    SetCapacity(FCapacity + (FCapacity shr 1));
end;

procedure TStringCollection.Insert(Index: Integer);
var
  i:integer;
begin
  if FCount = FCapacity then
   Grow;
  if Index < FCount then
  for i:=0 to Pred(FHighBounds) do
  begin
    Move(FData[i][Index], FData[i][Index + 1],(FCount - Index) * SizeOf(string));
    Pointer(FData[i][Index]):=nil;
  end;
  Inc(FCount);
end;

procedure TStringCollection.SetCapacity(NewCapacity:integer);
var
  i:integer;
begin
 for i := 0 to FHighBounds - 1 do
  SetLength(FData[i],NewCapacity);
// SetLength(PStrArray(@FData)^,NewCapacity*FHighBounds);
 FCapacity := NewCapacity;
end;

procedure TStringCollection.SetValue(X, Y: integer; const Value: FIBByteString);
var
  Len:Integer;
begin
 Assert(X<=FHighBounds,'Can''t write value to StrCollection. Bad X-Index');
 Assert(Y<FCount,'Can''t write value to StrCollection. Bad Y-Index');
 Len:=Length(Value);
 if Len=0 then
   FData[X][Y]:=''
 else
  SetString(FData[X][Y],PAnsiChar(@Value[1]),Length(Value));
end;

procedure   TStringCollection.SetPCharValue(X, Y: integer; const Value: PAnsiChar;Len:integer);
begin
 Assert(X<=FHighBounds,'Can''t write value to StrCollection. Bad X-Index');
 Assert(Y<FCount,'Can''t write value to StrCollection. Bad Y-Index');
 if Len<0 then
   SetString(FData[X][Y],Value,Q_StrLen(Value))
 else
 if Len=0 then
  FData[X][Y]:=''
 else
 begin
  SetString(FData[X][Y],Value,Len)
 end;
end;

end.



