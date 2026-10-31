{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ InterBase databases                                           }
{                                                               }
{    FIBPlus is based in part on the product                    }
{    Free IB Components, written by Gregory H. Deatz for        }
{    Hoagland, Longo, Moran, Dunst & Doukas Company.            }
{    mailto:gdeatz@hlmdd.com                                    }
{                                                               }
{    Copyright (c) 1998-2013 Devrace Ltd.                       }
{    Written by Serge Buzadzhy                                  }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit FIBCacheManage;

interface

uses
  SysUtils, FIBLists, Classes, FIBPlatforms;

{$I FIB.inc}

type

  TFIBBlockArray = array [0 .. 0] of PByte;
  PFIBBlockArray = ^TFIBBlockArray;
  TFIBIntegerArray = array [1 .. 1] of Integer;
  PFIBIntegerArray = ^TFIBIntegerArray;

  TFIBRecordPosition = record
    RecordNo: Integer;
    InternalNo: Integer;
  end;

  PFIBRecordPosition = ^TFIBRecordPosition;
  TFIBRecordPositions = array [1 .. 1] of TFIBRecordPosition;
  PFIBRecordPositions = ^TFIBRecordPositions;

  TFIBRecordsCache = class
  private
    FMapRecords: TFIBList;
    FStringData: TFIBStringCollection;
    FLogStringData: TFIBStringCollection;
    FBlocks: TFIBList;
    FChangeLog: TFIBList;
    FChangesPositions: PFIBRecordPositions;
    FOldBufRecordNumber: Integer;
    FOldBuffer: TFIBDataBuffer;
    FBlockSize: Integer;
    FRecordSize: Integer;
    FInOutRecordSize: Integer;
    FRecordCount: Integer;
    FChangesCount: Integer;
    FStringFieldOffsets: PFIBIntegerArray;
    FStringFieldSize: PFIBIntegerArray;
    FRecInBlock: Integer;
    FStrFieldCount: Integer;
    FSaveChangeLog: Boolean;
    procedure SetBlockCount(NewCount: Integer);
    function GetBlockCount: Integer;
    procedure SetChangeLogBlockCount(NewCount: Integer);
    function InternalRecordNo(const RecordNo: Integer): Integer;
    function GetSize: Integer;
    function GetChangePosition(aRecordNo: Integer; Force: Boolean): PFIBRecordPosition;
    function FindChangeRecNo(const ARecno: Integer; var Index: Integer): Boolean;
    procedure InitializeMap;
    function GetChangesBlockCount: Integer;
  public
    constructor Create(aBlockRecCount, aRecordSize, aBlockReadSize, aStrCount: Integer);
    destructor Destroy; override;
    procedure Assign(SourceCache: TFIBRecordsCache);
    function CreateNewBlock: Integer;
    function PrepareMemory(RecordNo: Integer): TFIBDataBuffer;
    function PRecBuffer(const RecordNo: Integer): TFIBDataBuffer;
    function RecordPosition(const RecordNo: Integer; IsInternalRecno: Boolean = False): Integer;
    function RecordBlock(const RecordNo: Integer; ForceAllocMem: Boolean; IsInternalRecno: Boolean = False): Integer;
    procedure SetStrOffset(Index: Integer; Offset, DataSize: Integer);
    procedure ReadRecord(const RecordNo: Integer; var Dest: TFIBDataBuffer);
    procedure ReadRecordBuffer(RecordNo: Integer; var Dest: TFIBDataBuffer; Old: Boolean);
    function GetFieldData(RecordNo, FieldOffSet, StrIndex: Integer; var RecordData: Pointer): Pointer;
    function GetStringFieldData(RecordNo, StrIndex: Integer): Pointer;
    function GetNonStringFieldData(RecordNo, FieldOffSet: Integer; var RecordData: Pointer): Pointer;
    procedure WriteRecord(RecordNo: Integer; const Source: TFIBDataBuffer; ForceAllocMem: Boolean);
    procedure ClearStringValue(Index, RecordNo: Integer);
    procedure SetStringFromPChar(Index, RecordNo: Integer; const Value: PAnsiChar; Len: Integer; Trimming: Boolean);
    procedure SaveOldBuffer(RecordNo: Integer);
    procedure ClearOldBuffer;
    procedure SaveToChangeLog(aRecordNo: Integer);
    function OldBuffer(RecordNo: Integer): TFIBDataBuffer;
    function pRecBuff(RecordNo: Integer): TFIBDataBuffer;
    procedure RevertRecord(aRecordNo: Integer);
    procedure ClearLog;
    procedure SwapRecords(OldRecordNo, NewRecordNo: Integer);
    procedure MoveRecord(OldRecno, NewRecno: Integer);
    procedure SaveToStream(Stream: TStream; SeekBegin: Boolean; CacheSize: Integer = 32 * 1024);
    procedure LoadFromStream(Stream: TStream; SeekBegin: Boolean);
    procedure Insert(RecordNo: Integer);
    procedure CancelInsert(RecordNo: Integer);
    function BookMarkByRecord(RecordNo: Integer): Integer;
    function RecordByBookMark(BookMark: Integer): Integer;
    function BookMarkValid(BookMark: Integer): Boolean;
    property ChangesBlockCount: Integer read GetChangesBlockCount write SetChangeLogBlockCount;
  public
    property BlockCount: Integer read GetBlockCount write SetBlockCount;
    property Size: Integer read GetSize;
    property SaveChangeLog: Boolean read FSaveChangeLog write FSaveChangeLog;
  end;

  EFIBMemoryManagerError = class(Exception);

const
  MinBlockSize = 1024;

type
  // Deprecated names of the types renamed in 8.0.0
  TBlockArray = TFIBBlockArray deprecated 'Use TFIBBlockArray';
  PBlockArray = PFIBBlockArray deprecated 'Use PFIBBlockArray';
  TIntArray = TFIBIntegerArray deprecated 'Use TFIBIntegerArray';
  PIntArray = PFIBIntegerArray deprecated 'Use PFIBIntegerArray';
  TRecordPosition = TFIBRecordPosition deprecated 'Use TFIBRecordPosition';
  PRecordPosition = PFIBRecordPosition deprecated 'Use PFIBRecordPosition';
  TRecPositions = TFIBRecordPositions deprecated 'Use TFIBRecordPositions';
  PRecPositions = PFIBRecordPositions deprecated 'Use PFIBRecordPositions';
  TRecordsCache = TFIBRecordsCache deprecated 'Use TFIBRecordsCache';
  EMemManagerError = EFIBMemoryManagerError deprecated 'Use EFIBMemoryManagerError';

implementation

uses
  StdFuncs, StrUtil;

{ TFIBRecordsCache }

constructor TFIBRecordsCache.Create(aBlockRecCount, aRecordSize, aBlockReadSize, aStrCount: Integer);
var
  aBlockSize: Integer;
begin

  FOldBufRecordNumber := -1;
  FRecordSize := aBlockReadSize;
  FInOutRecordSize := aRecordSize;
  aBlockSize := aBlockRecCount * FRecordSize;
  if aBlockSize < MinBlockSize then
    aBlockSize := MinBlockSize + aRecordSize - (MinBlockSize mod aRecordSize);

  if (aBlockSize < FRecordSize) then
    raise EFIBMemoryManagerError.Create('Incompatible Sizes');
  FBlocks := TFIBList.Create;
  FBlockSize := aBlockSize;
  FRecInBlock := FBlockSize div FRecordSize;
  if aStrCount > 0 then
    begin
      FStrFieldCount := aStrCount;
      FStringData := TFIBStringCollection.Create(aStrCount);
      GetMem(FStringFieldOffsets, aStrCount * SizeOf(Integer));
      GetMem(FStringFieldSize, aStrCount * SizeOf(Integer));
    end;

  GetMem(FOldBuffer, FInOutRecordSize);
  if FInOutRecordSize > 0 then
    FillChar(FOldBuffer[0], FInOutRecordSize, 1); // NullValues
end;

destructor TFIBRecordsCache.Destroy;
var
  i: Integer;
begin
  // nil when the constructor failed
  if FBlocks <> nil then
    for i := 0 to BlockCount - 1 do
      FreeMem(FBlocks.List^[i]);
  for i := 0 to ChangesBlockCount - 1 do
    FreeMem(FChangeLog.List^[i]);

  ReallocMem(FStringFieldOffsets, 0);
  ReallocMem(FChangesPositions, 0);
  ReallocMem(FStringFieldSize, 0);
  FreeMem(FOldBuffer);

  FStringData.Free;
  FLogStringData.Free;

  FBlocks.Free;
  if FChangeLog <> nil then
    FChangeLog.Free;
  FMapRecords.Free;
  inherited;
end;

procedure TFIBRecordsCache.Assign(SourceCache: TFIBRecordsCache);
var
  i, j: Integer;
  ExistingBlockCount: Integer;
  ExistingCheckBlockCount: Integer;
  p: Pointer;
begin
  if FBlockSize <> SourceCache.FBlockSize then
    begin
      for i := 0 to BlockCount - 1 do
        begin
          FreeMem(FBlocks.List^[i]);
        end;
      for i := 0 to ChangesBlockCount - 1 do
        begin
          FreeMem(FChangeLog.List^[i]);
        end;

      FBlocks.Clear;
      if FChangeLog <> nil then
        FChangeLog.Clear;
    end;

  if BlockCount >= SourceCache.BlockCount then
    begin
      for i := BlockCount - 1 downto SourceCache.BlockCount do
        FreeMem(FBlocks.List^[i]);
      FBlocks.Count := SourceCache.BlockCount;
      ExistingBlockCount := SourceCache.BlockCount
    end
  else
    ExistingBlockCount := BlockCount;

  if ChangesBlockCount >= SourceCache.ChangesBlockCount then
    begin
      for i := ChangesBlockCount - 1 downto SourceCache.ChangesBlockCount do
        FreeMem(FChangeLog.List^[i]);
      ExistingCheckBlockCount := SourceCache.ChangesBlockCount
    end
  else
    ExistingCheckBlockCount := ChangesBlockCount;

  FBlockSize := SourceCache.FBlockSize;
  FBlocks.Count := SourceCache.BlockCount;
  ChangesBlockCount := SourceCache.ChangesBlockCount;

  for i := 0 to BlockCount - 1 do
    begin
      if i >= ExistingBlockCount then
        FBlocks.List^[i] := nil;
      if Assigned(FBlocks.List^[i]) then
        begin
          p := FBlocks.List^[i];
          ReallocMem(p, FBlockSize);
          FBlocks.List^[i] := p;
        end
      else
        FBlocks.List^[i] := AllocMem(FBlockSize);
      Move(SourceCache.FBlocks.List^[i]^, FBlocks.List^[i]^, FBlockSize);
    end;

  for i := 0 to ChangesBlockCount - 1 do
    begin
      if i >= ExistingCheckBlockCount then
        FChangeLog.List^[i] := nil;
      p := FChangeLog.List^[i];
      ReallocMem(p, FBlockSize);
      FChangeLog.List^[i] := p;
      Move(SourceCache.FChangeLog.List^[i]^, FChangeLog.List^[i]^, FBlockSize);
    end;

  FChangesCount := SourceCache.FChangesCount;
  ReallocMem(FChangesPositions, FChangesCount * SizeOf(TFIBRecordPosition));
  for i := 1 to FChangesCount do
    begin
      FChangesPositions^[i].RecordNo := SourceCache.FChangesPositions^[i].RecordNo;
      FChangesPositions^[i].InternalNo := SourceCache.FChangesPositions^[i].InternalNo;
    end;

  FStrFieldCount := SourceCache.FStrFieldCount;
  ReallocMem(FStringFieldOffsets, FStrFieldCount * SizeOf(Integer));
  ReallocMem(FStringFieldSize, FStrFieldCount * SizeOf(Integer));

  FreeAndNil(FStringData);
  FreeAndNil(FLogStringData);
  if FStrFieldCount > 0 then
    begin
      for i := 1 to FStrFieldCount do
        begin
          FStringFieldOffsets^[i] := SourceCache.FStringFieldOffsets^[i];
          FStringFieldSize^[i] := SourceCache.FStringFieldSize^[i];
        end;
      FStringData := TFIBStringCollection.Create(FStrFieldCount);
      FStringData.Capacity := SourceCache.FStringData.Capacity;
      for i := 0 to Pred(SourceCache.FStringData.HighX) do
        for j := 0 to Pred(SourceCache.FStringData.CountY) do
          begin
            if i = 0 then
              FStringData.Add;
            FStringData[i, j] := SourceCache.FStringData[i, j];
          end;

      if Assigned(SourceCache.FLogStringData) then
        begin
          FLogStringData := TFIBStringCollection.Create(FStrFieldCount);
          FLogStringData.Capacity := SourceCache.FLogStringData.Capacity;
          for i := 0 to Pred(SourceCache.FLogStringData.HighX) do
            for j := 0 to Pred(SourceCache.FLogStringData.CountY) do
              begin
                if i = 0 then
                  FLogStringData.Add;
                FLogStringData[i, j] := SourceCache.FLogStringData[i, j];
              end;
        end;

    end
  else
    begin
      FStringData := nil;
      FLogStringData := nil;
    end;

  FInOutRecordSize := SourceCache.FInOutRecordSize;
  FRecordSize := SourceCache.FRecordSize;
  FRecInBlock := SourceCache.FRecInBlock;
  FRecordCount := SourceCache.FRecordCount;
  ReallocMem(FOldBuffer, FInOutRecordSize);
  if FInOutRecordSize > 0 then
    Move(SourceCache.FOldBuffer^, FOldBuffer^, FInOutRecordSize);
  FOldBufRecordNumber := SourceCache.FOldBufRecordNumber;
  FSaveChangeLog := SourceCache.FSaveChangeLog;

  // the order of a sorted cache and the inserted records
  if Assigned(SourceCache.FMapRecords) then
  begin
    if FMapRecords = nil then
      FMapRecords := TFIBList.Create;
    FMapRecords.Assign(SourceCache.FMapRecords);
  end
  else
    FreeAndNil(FMapRecords);
end;

procedure TFIBRecordsCache.SetBlockCount(NewCount: Integer);
begin
  if NewCount >= FBlocks.Capacity then
    FBlocks.Capacity := NewCount + 10;
  FBlocks.Count := NewCount
end;

function TFIBRecordsCache.GetBlockCount: Integer;
begin
  Result := Integer(FBlocks.Count)
end;

function TFIBRecordsCache.CreateNewBlock: Integer;
begin
  SetBlockCount(BlockCount + 1);
  FBlocks.List^[BlockCount - 1] := AllocMem(FBlockSize);
  Result := BlockCount;
end;

function TFIBRecordsCache.PrepareMemory(RecordNo: Integer): TFIBDataBuffer;
var
  BlockNo: Integer;
  IRecordNo, i, c: Integer;
begin
  if Assigned(FMapRecords) and (RecordNo > FMapRecords.Count) then
    begin
      c := Integer(FMapRecords.Count); // less than RecordNo
      for i := c to RecordNo - 1 do
        FMapRecords.Add(Pointer(FRecordCount + 1 + i - c));
      FRecordCount := RecordNo;
      if Assigned(FStringData) then
        while (FStringData.CountY < FMapRecords.Count) do
          FStringData.Add
    end
  else if FRecordCount < RecordNo then
    FRecordCount := RecordNo;
  IRecordNo := InternalRecordNo(RecordNo);
  BlockNo := (IRecordNo - 1) div FRecInBlock;
  if BlockNo = BlockCount then
    CreateNewBlock;
  Result := TFIBDataBuffer(FBlocks.List^[BlockNo]) + RecordPosition(IRecordNo, True);
end;

function TFIBRecordsCache.RecordPosition(const RecordNo: Integer; IsInternalRecno: Boolean = False): Integer;
begin
  if IsInternalRecno then
    Result := ((RecordNo - 1) mod FRecInBlock) * FRecordSize
  else
    Result := ((InternalRecordNo(RecordNo) - 1) mod FRecInBlock) * FRecordSize
end;

function TFIBRecordsCache.RecordBlock(const RecordNo: Integer; ForceAllocMem: Boolean; IsInternalRecno: Boolean = False): Integer;
begin
  if ForceAllocMem then
    begin
      PrepareMemory(RecordNo);
      if (RecordNo > FRecordCount) then
        FRecordCount := RecordNo;
    end;
  if IsInternalRecno then
    Result := (RecordNo - 1) div FRecInBlock
  else
    Result := (InternalRecordNo(RecordNo) - 1) div FRecInBlock;
end;

procedure TFIBRecordsCache.ReadRecord(const RecordNo: Integer; var Dest: TFIBDataBuffer);
begin
  ReadRecordBuffer(RecordNo, Dest, False);
end;

function TFIBRecordsCache.PRecBuffer(const RecordNo: Integer): TFIBDataBuffer;
var
  BlockIndex: Integer;
  PosInBlock: Integer;
  IRecordNo: Integer;
begin
  IRecordNo := InternalRecordNo(RecordNo);
  BlockIndex := RecordBlock(IRecordNo, False, True);
  // -1 beyond the map
  if (IRecordNo < 1) or (BlockIndex >= BlockCount) then
    raise EFIBMemoryManagerError.Create('Can''t read Buffer.Incorrect RecordNo');
  PosInBlock := RecordPosition(IRecordNo, True);
  Result := TFIBDataBuffer(FBlocks.List^[BlockIndex]) + PosInBlock;
end;

procedure TFIBRecordsCache.ReadRecordBuffer(RecordNo: Integer; var Dest: TFIBDataBuffer; Old: Boolean);
var
  BlockIndex: Integer;
  PosInBlock: Integer;
  Cache: TFIBDataBuffer;
  i, L: Integer;
  IRecordNo: Integer;
  p: PFIBRecordPosition;
  ss: TFIBStringCollection;
  ps: PFIBByteString;
begin
  IRecordNo := InternalRecordNo(RecordNo);
  if IRecordNo < 1 then
    raise EFIBMemoryManagerError.Create('Can''t read Buffer.Incorrect RecordNo');
  if Old then
    begin
      p := GetChangePosition(IRecordNo, False);
      if not Assigned(p) then
        begin
          ReadRecordBuffer(RecordNo, Dest, False);
          Exit;
        end;
      IRecordNo := p^.InternalNo;
      ss := FLogStringData;
      BlockIndex := (IRecordNo - 1) div FRecInBlock;
      if BlockIndex >= ChangesBlockCount then
        raise EFIBMemoryManagerError.Create('Can''t read LogBuffer.Incorrect RecordNo');
      PosInBlock := ((IRecordNo - 1) mod FRecInBlock) * FRecordSize;
    end
  else
    begin
      ss := FStringData;
      BlockIndex := RecordBlock(IRecordNo, False, True);
      if BlockIndex >= BlockCount then
        raise EFIBMemoryManagerError.Create('Can''t read Buffer.Incorrect RecordNo');
      PosInBlock := RecordPosition(IRecordNo, True);
    end;
  if Old then
    Cache := TFIBDataBuffer(FChangeLog.List^[BlockIndex]) + PosInBlock
  else
    Cache := TFIBDataBuffer(FBlocks.List^[BlockIndex]) + PosInBlock;
  if (FStrFieldCount = 0) then
    Move(Cache^, Dest^, FRecordSize)
  else
    begin
      Move(Cache[0], Dest[0], FStringFieldOffsets^[1]);
      for i := 1 to FStrFieldCount do
        begin
          ps := ss.PValue[i - 1, IRecordNo - 1];
          if ps <> nil then
            begin
              L := Length(ps^);
              if L > FStringFieldSize^[i] then
                begin
                  L := FStringFieldSize^[i];
                  SetLength(ps^, L);
                end;
              PInteger(@Dest[FStringFieldOffsets^[i]])^ := L; // LengthExp
              if (L > 0) then
                begin
                  Move(ps^[1], Dest[FStringFieldOffsets^[i] + SizeOf(Integer)], L);
                end;
              if L < FStringFieldSize^[i] then
                Dest[FStringFieldOffsets^[i] + L + SizeOf(Integer)] := 0;
            end;
        end;
      if FRecordSize > FStringFieldOffsets^[1] then // Blobs
        Move(Cache[FStringFieldOffsets^[1]], Dest[FStringFieldOffsets^[FStrFieldCount] + SizeOf(Integer) +
          FStringFieldSize^[FStrFieldCount]], FRecordSize - FStringFieldOffsets^[1]);
    end;
end;

procedure TFIBRecordsCache.WriteRecord(RecordNo: Integer; const Source: TFIBDataBuffer; ForceAllocMem: Boolean);
var
  BlockIndex: Integer;
  PosInBlock: Integer;
  Cache: TFIBDataBuffer;
  L, i: Integer;
  ps: PFIBByteString;
begin
  BlockIndex := RecordBlock(RecordNo, ForceAllocMem);
  if BlockIndex < BlockCount then
    begin
      PosInBlock := RecordPosition(RecordNo);
      Cache := TFIBDataBuffer(FBlocks.List^[BlockIndex]) + PosInBlock;
      if Source = nil then
        FillChar(Cache^, FRecordSize, 0)
      else
        begin
          if (FStrFieldCount = 0) then
            Move(Source[0], Cache[0], FRecordSize)
          else
            begin
              Move(Source[0], Cache[0], FStringFieldOffsets^[1]);
              Move(Source[FStringFieldOffsets^[FStrFieldCount] + FStringFieldSize^
                [FStrFieldCount] + SizeOf(Integer)], Cache[FStringFieldOffsets^[1]],
                FRecordSize - FStringFieldOffsets^[1]);
            end;
          if Assigned(FStringData) then
            begin
              RecordNo := InternalRecordNo(RecordNo);
              for i := 1 to FStrFieldCount do
                begin
                  if FStringData.CountY <= RecordNo then
                    FStringData.Add;
                  ps := FStringData.PValue[i - 1, RecordNo - 1];
                  L := PInteger(@Source[FStringFieldOffsets^[i]])^;
                  if L <> Length(ps^) then
                    SetLength(ps^, L);
                  if L > 0 then
                    Move(Source[FStringFieldOffsets^[i] + SizeOf(Integer)], ps^[1], L);
                end;
            end
        end;
    end
  else
    raise EFIBMemoryManagerError.Create('Can''t write to Buffer.Incorrect RecordNo');
end;

function TFIBRecordsCache.InternalRecordNo(const RecordNo: Integer): Integer;
begin
  if Assigned(FMapRecords) then
    if RecordNo <= FMapRecords.Count then
      Result := Integer(FMapRecords.List^[RecordNo - 1])
    else
      Result := -1
  else
    Result := RecordNo
end;

function TFIBRecordsCache.GetSize: Integer;
begin
  Result := BlockCount * FBlockSize;
end;

procedure TFIBRecordsCache.SetStrOffset(Index, Offset, DataSize: Integer);
begin
  if Assigned(FStringFieldOffsets) and Assigned(FStringData) then
    if (Index <= FStringData.HighX) and (Index > 0) then
      begin
        FStringFieldOffsets^[Index] := Offset;
        FStringFieldSize^[Index] := DataSize;
      end;
end;

function TFIBRecordsCache.GetStringFieldData(RecordNo, StrIndex: Integer): Pointer;
begin
  // used in new Locate
  if Assigned(FMapRecords) then
    RecordNo := InternalRecordNo(RecordNo + 1) - 1;
  if RecordNo > FStringData.Capacity then
    raise EFIBMemoryManagerError.Create('Can''t read  FieldData .Incorrect RecordNo');
  Result := FStringData.PValue[StrIndex, RecordNo];

end;

function TFIBRecordsCache.GetFieldData(RecordNo, FieldOffSet, StrIndex: Integer; var RecordData: Pointer): Pointer;
var
  BlockIndex: Integer;
  PosInBlock: Integer;
begin
  // Used in Locate

  if Assigned(FMapRecords) then
    RecordNo := InternalRecordNo(RecordNo);

  BlockIndex := (RecordNo - 1) div FRecInBlock;
  if (RecordNo >= 1) and (BlockIndex < FBlocks.Count) then
    begin
      PosInBlock := (RecordNo - 1 - BlockIndex * FRecInBlock) * FRecordSize;
      RecordData := FBlocks.List^[BlockIndex];
      Inc(PByte(RecordData), PosInBlock);
    end
  else
    raise EFIBMemoryManagerError.Create('Can''t read  FieldData .Incorrect RecordNo');
  if (StrIndex = -1) or (FStrFieldCount = 0) then
    begin
      Result := RecordData;
      Inc(PByte(Result), FieldOffSet);
    end
  else
    begin
      if RecordNo > FStringData.Capacity then
        raise EFIBMemoryManagerError.Create
        ('Can''t read  FieldData .Incorrect RecordNo');
      Result := FStringData.PValue[StrIndex, RecordNo - 1];
    end;

end;

function TFIBRecordsCache.GetNonStringFieldData(RecordNo, FieldOffSet: Integer; var RecordData: Pointer): Pointer;
var
  BlockIndex: Integer;
  PosInBlock: Integer;
begin
  // used in new Locate

  if Assigned(FMapRecords) then
    RecordNo := InternalRecordNo(RecordNo + 1) - 1;

  BlockIndex := RecordNo div FRecInBlock;
  if BlockIndex < FBlocks.Count then
    begin
      PosInBlock := (RecordNo - BlockIndex * FRecInBlock) * FRecordSize;

      RecordData := FBlocks.List^[BlockIndex];
      Inc(TFIBDataBuffer(RecordData), PosInBlock)
    end
  else
    raise EFIBMemoryManagerError.Create
    ('Can''t read  FieldData .Incorrect RecordNo'); ;
  Result := RecordData;
  Inc(TFIBDataBuffer(Result), FieldOffSet);
end;

procedure TFIBRecordsCache.ClearStringValue(Index, RecordNo: Integer);
var
  Added: Boolean;
begin
  if Assigned(FStringFieldOffsets) and Assigned(FStringData) then
    begin
      if Assigned(FMapRecords) then
        RecordNo := InternalRecordNo(RecordNo + 1) - 1;
      Added := FStringData.CountY <= RecordNo;
      while FStringData.CountY <= RecordNo do
        FStringData.Add;
      if not Added then
        FStringData.SetPCharValue(Index, RecordNo, '', 0);
    end;
end;

procedure TFIBRecordsCache.SetStringFromPChar(Index, RecordNo: Integer; const Value: PAnsiChar; Len: Integer; Trimming: Boolean);
begin
  if Assigned(FMapRecords) then
    RecordNo := InternalRecordNo(RecordNo + 1) - 1;
  while FStringData.CountY <= RecordNo do
    FStringData.Add;
  if Trimming then
    begin
      if Len < 0 then
        Len := FStringFieldSize^[Index + 1];
      while (Len > 0) and (Value[Len - 1] = ' ') do
        Dec(Len);
      if (Len < FStringFieldSize^[Index + 1]) then
        begin
          Value[Len] := #0;
        end;
    end;
  FStringData.SetPCharValue(Index, RecordNo, Value, Len)
end;

function TFIBRecordsCache.OldBuffer(RecordNo: Integer): TFIBDataBuffer;
begin
  if SaveChangeLog then
    begin
      if RecordNo <= FRecordCount then
        ReadRecordBuffer(RecordNo, FOldBuffer, True)
      else
        ClearOldBuffer
    end
  else
    begin
      if FOldBufRecordNumber <> RecordNo then
        if RecordNo <= FRecordCount then
          SaveOldBuffer(RecordNo)
        else
          ClearOldBuffer
    end;
  Result := FOldBuffer
end;

procedure TFIBRecordsCache.SaveOldBuffer(RecordNo: Integer);
begin
  if SaveChangeLog then
    SaveToChangeLog(RecordNo)
  else
    begin
      if RecordNo <= FRecordCount then
        ReadRecord(RecordNo, FOldBuffer)
      else
        ClearOldBuffer;
      FOldBufRecordNumber := RecordNo;
    end;
end;

procedure TFIBRecordsCache.ClearOldBuffer;
begin
  FillChar(FOldBuffer[0], FInOutRecordSize, 1); // NullValues
end;

procedure TFIBRecordsCache.SaveToChangeLog(aRecordNo: Integer);
var
  p: PFIBRecordPosition;
  BlockIndex: Integer;
  PosInBlock: Integer;
  ChangeBlockIndex: Integer;
  ChangePosInBlock: Integer;
  i: Integer;
  IRecordNo: Integer;
begin
  // for CachedUpdates
  if FChangeLog = nil then
    FChangeLog := TFIBList.Create;
  IRecordNo := InternalRecordNo(aRecordNo);
  BlockIndex := RecordBlock(IRecordNo, False, True);
  PosInBlock := RecordPosition(IRecordNo, True);

  p := GetChangePosition(IRecordNo, True);
  ChangeBlockIndex := (p^.InternalNo - 1) div FRecInBlock;
  ChangePosInBlock := ((p^.InternalNo - 1) mod FRecInBlock) * FRecordSize;

  if (ChangeBlockIndex >= ChangesBlockCount) then
    begin
      SetChangeLogBlockCount(ChangesBlockCount + 1);
      FChangeLog.List^[ChangesBlockCount - 1] := AllocMem(FBlockSize);
      if Assigned(FStringData) and not Assigned(FLogStringData) then
        FLogStringData := TFIBStringCollection.Create(FStrFieldCount);
    end;

  Move(TFIBDataBuffer(FBlocks.List^[BlockIndex])[PosInBlock],
    TFIBDataBuffer(FChangeLog.List^[ChangeBlockIndex])[ChangePosInBlock], FRecordSize);
  if Assigned(FStringData) then
    begin
      if p^.InternalNo >= FLogStringData.CountY then
        FLogStringData.Add;
      for i := 0 to FStringData.HighX - 1 do
        begin
          FLogStringData.Value[i, p^.InternalNo - 1] := FStringData.Value
            [i, IRecordNo - 1];
        end;
    end;
end;

procedure TFIBRecordsCache.SetChangeLogBlockCount(NewCount: Integer);
begin
  if FChangeLog = nil then
    FChangeLog := TFIBList.Create;
  FChangeLog.Count := NewCount
end;

function TFIBRecordsCache.GetChangePosition(aRecordNo: Integer; Force: Boolean): PFIBRecordPosition;
var
  i: Integer;
begin
  if FindChangeRecNo(aRecordNo, i) then
    Result := @FChangesPositions^[i]
  else if not Force then
    Result := nil
  else
    begin
      Inc(FChangesCount);
      ReallocMem(FChangesPositions, FChangesCount * SizeOf(TFIBRecordPosition));
      Move(FChangesPositions[i], FChangesPositions[i + 1], SizeOf(TFIBRecordPosition) * (FChangesCount - i));
      with FChangesPositions^[i] do
        begin
          RecordNo := aRecordNo;
          InternalNo := FChangesCount;
          Result := @FChangesPositions^[i];
        end;
    end;
end;

procedure TFIBRecordsCache.ClearLog;
var
  i: Integer;
begin
  if FChangeLog = nil then
    Exit;
  for i := 0 to ChangesBlockCount - 1 do
    begin
      FreeMem(FChangeLog[i]);
    end;
  FChangeLog.Clear;
  ReallocMem(FChangesPositions, 0);
  FChangesCount := 0
end;

function TFIBRecordsCache.FindChangeRecNo(const ARecno: Integer; var Index: Integer): Boolean;
var
  L, H, i, c: Integer;
  function Compare(i, I1: Integer): Integer;
  begin
    if i = I1 then
      Result := 0
    else if i > I1 then
      Result := 1
    else
      Result := -1;
  end;

begin
  Result := False;
  L := 1;
  H := FChangesCount;
  while L <= H do
    begin
      i := (L + H) shr 1;
      c := Compare(FChangesPositions[i].RecordNo, ARecno);
      if c < 0 then
        L := i + 1
      else
        begin
          H := i - 1;
          if c = 0 then
            Result := True;
        end;
    end;
  Index := L;
end;

procedure TFIBRecordsCache.RevertRecord(aRecordNo: Integer);
var
  Buf: TFIBDataBuffer;
begin
  Buf := OldBuffer(aRecordNo);
  WriteRecord(aRecordNo, Buf, False)
end;

function TFIBRecordsCache.pRecBuff(RecordNo: Integer): TFIBDataBuffer;
var
  BlockIndex: Integer;
  PosInBlock: Integer;
begin
  BlockIndex := RecordBlock(RecordNo, False);
  if BlockIndex < BlockCount then
    begin
      PosInBlock := RecordPosition(RecordNo);
      Result := TFIBDataBuffer(FBlocks.List^[BlockIndex]) + PosInBlock;
    end
  else
    Result := nil;
end;

procedure TFIBRecordsCache.SwapRecords(OldRecordNo, NewRecordNo: Integer);
var
  c: Integer;
begin
  InitializeMap;
  c := Integer(FMapRecords.List^[OldRecordNo]);
  FMapRecords.List^[OldRecordNo] := FMapRecords.List^[NewRecordNo];
  FMapRecords.List^[NewRecordNo] := Pointer(c);
end;

procedure TFIBRecordsCache.MoveRecord(OldRecno, NewRecno: Integer);
var
  Position: Integer;
begin
  if OldRecno = NewRecno then
    Exit;
  if NewRecno > OldRecno then
    Inc(NewRecno);
  InitializeMap;
  Position := Integer(FMapRecords.List^[OldRecno]);
  FMapRecords.Insert(NewRecno, Pointer(Position));
  if OldRecno < NewRecno then
    FMapRecords.Delete(OldRecno)
  else
    FMapRecords.Delete(OldRecno + 1)
end;

procedure TFIBRecordsCache.SaveToStream(Stream: TStream; SeekBegin: Boolean; CacheSize: Integer = 32 * 1024);
var
  i, j, L: Integer;
  p: PFIBByteString;
  CacheStream: TMemoryStream;
  curStream: TStream;
  UseCache: Boolean;

  procedure FlushCache(Force: Boolean; nextCount: Integer);
  begin
    if UseCache then
      if Force or (CacheStream.Position + nextCount >= CacheSize) then
        begin
          // flushed before it grows over CacheSize
          Stream.WriteBuffer(CacheStream.Memory^, Integer(CacheStream.Position));
          CacheStream.Position := 0;
        end;
  end;

  procedure InternalWriteBuffer(const Buffer; Count: LongInt);
  begin
    if Count >= CacheSize then
      begin
        FlushCache(True, 0);
        Stream.WriteBuffer(Buffer, Count);
      end
    else
      begin
        FlushCache(False, Count);
        curStream.Write(Buffer, Count);
      end
  end;

begin
  with Stream do
    begin
      if SeekBegin then
        Seek(0, soFromBeginning);
      UseCache := CacheSize > 0;
      if UseCache then
        begin
          CacheStream := TMemoryStream.Create;
          curStream := CacheStream;
          if CacheSize < 32 * 1024 then
            CacheSize := 32 * 1024;
          CacheStream.Size := CacheSize;
        end
      else
        begin
          CacheStream := nil;
          curStream := Stream;
        end;
    end;
  with curStream do
    try
      i := BlockCount;
      InternalWriteBuffer(i, SizeOf(Integer));
      InternalWriteBuffer(FBlockSize, SizeOf(Integer));
      InternalWriteBuffer(FInOutRecordSize, SizeOf(Integer));
      InternalWriteBuffer(FStrFieldCount, SizeOf(Integer));
      InternalWriteBuffer(FSaveChangeLog, SizeOf(Boolean));
      InternalWriteBuffer(FRecordCount, SizeOf(Integer));

      for i := 0 to BlockCount - 1 do
        begin
          InternalWriteBuffer(FBlocks.List^[i]^, FBlockSize);
        end;

      if FStrFieldCount > 0 then
        begin
          for i := 1 to FStrFieldCount do
            begin
              InternalWriteBuffer(FStringFieldOffsets^[i], SizeOf(Integer));
              InternalWriteBuffer(FStringFieldSize^[i], SizeOf(Integer));
            end;
        end;

      if FStrFieldCount > 0 then
        begin
          for i := 0 to FStrFieldCount - 1 do
            for j := 0 to FRecordCount - 1 do
              begin
                p := FStringData.PValue[i, j];
                L := Length(p^);
                InternalWriteBuffer(L, SizeOf(Integer));
                if L > 0 then
                  InternalWriteBuffer(p^[1], L);
              end;
        end;
      if Assigned(FMapRecords) then
        begin
          L := Integer(FMapRecords.Count); // one entry per record
          InternalWriteBuffer(L, SizeOf(Integer));
          for i := 0 to L - 1 do
            begin
              InternalWriteBuffer(FMapRecords.List^[i], SizeOf(Integer));
            end
        end
      else
        begin
          L := 0;
          InternalWriteBuffer(L, SizeOf(Integer));
        end;
      FlushCache(True, 0);
    finally
      if UseCache then
        CacheStream.Free
    end
end;

procedure TFIBRecordsCache.LoadFromStream(Stream: TStream; SeekBegin: Boolean);
var
  i, j, L: Integer;
  s: FIBByteString;
  p: Pointer;
begin
  for i := 0 to BlockCount - 1 do
    begin
      FreeMem(FBlocks.List^[i]);
    end;
  FBlocks.Clear;
  FMapRecords.Free;
  FMapRecords := nil;
  FStringData.Free;
  FStringData := nil;
  ReallocMem(FStringFieldOffsets, 0);
  ReallocMem(FStringFieldSize, 0);
  FStrFieldCount := 0;
  ClearLog;
  FreeAndNil(FLogStringData);

  with Stream do
    begin
      if SeekBegin then
        Seek(0, soFromBeginning);
      ReadBuffer(i, SizeOf(Integer));
      if i < 0 then
        raise EFIBMemoryManagerError.Create('Can''t load cache: incorrect block count');
      ReadBuffer(FBlockSize, SizeOf(Integer));
      ReadBuffer(FInOutRecordSize, SizeOf(Integer));
      ReadBuffer(FStrFieldCount, SizeOf(Integer));
      ReadBuffer(FSaveChangeLog, SizeOf(Boolean));
      ReadBuffer(FRecordCount, SizeOf(Integer));
      // the records of the blocks have the size given to the constructor
      if (FBlockSize < FRecordSize) or (FInOutRecordSize < 0) or (FStrFieldCount < 0) or (FRecordCount < 0) then
        raise EFIBMemoryManagerError.Create('Can''t load cache: incompatible sizes');
      FRecInBlock := FBlockSize div FRecordSize;
      ReallocMem(FOldBuffer, FInOutRecordSize);
      ClearOldBuffer;
      FOldBufRecordNumber := -1;
      FBlocks.Count := i;
      for i := 0 to BlockCount - 1 do
        FBlocks.List^[i] := nil;
      for i := 0 to BlockCount - 1 do
        begin
          GetMem(p, FBlockSize);
          FBlocks.List^[i] := p;
          ReadBuffer(FBlocks.List^[i]^, FBlockSize);
        end;
      if FStrFieldCount > 0 then
        begin
          FStringData := TFIBStringCollection.Create(FStrFieldCount);
          GetMem(FStringFieldOffsets, FStrFieldCount * SizeOf(Integer));
          GetMem(FStringFieldSize, FStrFieldCount * SizeOf(Integer));
          for i := 1 to FStrFieldCount do
            begin
              ReadBuffer(FStringFieldOffsets^[i], SizeOf(Integer));
              ReadBuffer(FStringFieldSize^[i], SizeOf(Integer));
            end;

          for i := 0 to FStrFieldCount - 1 do
            for j := 0 to FRecordCount - 1 do
              begin
                ReadBuffer(L, SizeOf(Integer));
                if L < 0 then
                  raise EFIBMemoryManagerError.Create('Can''t load cache: incorrect string length');
                SetString(s, nil, L);
                if L > 0 then
                  ReadBuffer(s[1], L);
                if FStringData.CountY <= j then
                  FStringData.Add;
                FStringData.Value[i, j] := s;
              end;
        end;
    end;

  Stream.ReadBuffer(L, SizeOf(Integer));
  if L < 0 then
    raise EFIBMemoryManagerError.Create('Can''t load cache: incorrect record map');
  if L > 0 then
    begin
      FMapRecords := TFIBList.Create;
      FMapRecords.Count := L;

      for i := 0 to L - 1 do
        Stream.ReadBuffer(FMapRecords.List^[i], SizeOf(Integer));
    end

end;

procedure TFIBRecordsCache.InitializeMap;
var
  i: Integer;
begin
  if not Assigned(FMapRecords) then
    begin
      FMapRecords := TFIBList.Create;
      FMapRecords.Count := FRecordCount;
      for i := 0 to FRecordCount - 1 do
        begin
          FMapRecords.List^[i] := Pointer(i + 1);
        end;
    end;
end;

procedure TFIBRecordsCache.Insert(RecordNo: Integer);
begin
  InitializeMap;
  Inc(FRecordCount);
  FMapRecords.Insert(RecordNo, Pointer(FRecordCount));
  if Assigned(FStringData) then
    FStringData.Add;
end;

procedure TFIBRecordsCache.CancelInsert(RecordNo: Integer);
begin
  if Assigned(FMapRecords) then
    begin
      if Integer(FMapRecords.List^[RecordNo - 1]) = FRecordCount then
        Dec(FRecordCount);
      if Assigned(FStringData) then
        FStringData.Delete(Integer(FMapRecords.List^[RecordNo - 1]) - 1);
      FMapRecords.Delete(RecordNo - 1);
    end;
end;

function TFIBRecordsCache.BookMarkByRecord(RecordNo: Integer): Integer;
begin
  Result := InternalRecordNo(RecordNo + 1)
end;

function TFIBRecordsCache.RecordByBookMark(BookMark: Integer): Integer;
begin
  if Assigned(FMapRecords) then
    begin
      if (BookMark <= FMapRecords.Count) and (FMapRecords.List^[BookMark - 1] = Pointer(BookMark)) then
        Result := BookMark - 1
      else
        Result := Integer(FMapRecords.IndexOf(Pointer(BookMark)))
    end
  else
    Result := BookMark - 1
end;

function TFIBRecordsCache.BookMarkValid(BookMark: Integer): Boolean;
begin
  Result := (BookMark > 0);
  if Result then
    begin
      if Assigned(FMapRecords) then
        begin
          Result := (BookMark <= FMapRecords.Count) and (FMapRecords.List^[BookMark - 1] = Pointer(BookMark));
          if not Result then
            Result := FMapRecords.IndexOf(Pointer(BookMark)) > -1
        end
      else
        Result := BookMark <= FRecordCount
    end;
end;

function TFIBRecordsCache.GetChangesBlockCount: Integer;
begin
  if FChangeLog = nil then
    Result := 0
  else
    Result := Integer(FChangeLog.Count)
end;

end.

