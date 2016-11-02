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
{    Written by Serge Buzadzhy (buzz@devrace.com)               }
{                                                               }
{ ------------------------------------------------------------- }
{    FIBPlus home page: http://www.fibplus.com/                 }
{    FIBPlus support  : http://www.devrace.com/support/         }
{ ------------------------------------------------------------- }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit FIBCacheManage;


interface
 uses SysUtils,pFIBLists,Classes,FIBPlatforms;

{$I FIBPlus.inc}
type



  TBlockArray =array[0..0] of PByte;
  PBlockArray =^TBlockArray;
  TIntArray   =array[1..1] of integer;
  PIntArray   =^TIntArray;

  TRecordPosition = record
   RecordNo  :integer;
   InternalNo:integer;
  end;
  PRecordPosition=^TRecordPosition;
  TRecPositions = array[1..1] of TRecordPosition;
  PRecPositions =^TRecPositions;

  TRecordsCache = class
  private
   FMapRecords    :TFIBList;
   FStringData    :TStringCollection;
   FLogStringData :TStringCollection;
   FBlocks     :TFIBList;
   FChangeLog  :TFIBList;
   FChangesPositions: PRecPositions;
   FOldBufRecordNumber:integer;
   FOldBuffer  :TDataBuffer;
   FBlockSize  :integer;
   FRecordSize :Integer;
   FInOutRecordSize:integer;
   FRecordCount :integer;
   FChangesCount:integer;
   FStringFieldOffsets :PIntArray;
   FStringFieldSize    :PIntArray;
   FRecInBlock    :Integer;
   FStrFieldCount :Word;
   FSaveChangeLog :boolean;
   procedure   SetBlockCount(NewCount: Integer);
   function    GetBlockCount:integer;
   procedure   SetChangeLogBlockCount(NewCount: Integer);
   function    InternalRecordNo(const RecordNo: integer):integer;
   function    GetSize: integer;
   function    GetChangePosition(aRecordNo: integer; Force:boolean):PRecordPosition;
//   procedure   ReadRecordBuffer(RecordNo:integer;var Dest:PChar;Old:boolean);
   function    FindChangeRecNo(const ARecno:integer; var Index:integer):boolean ;
   procedure   InitializeMap;
   function    GetChangesBlockCount: integer;

  public
   constructor Create(aBlockRecCount,aRecordSize,aBlockReadSize,aStrCount:integer);
   destructor  Destroy; override;

   procedure   Assign(SourceCache:TRecordsCache);
   function    CreateNewBlock:integer;
   function    PrepareMemory(RecordNo:integer):TDataBuffer;
   function    MemoryPrepared(RecordNo:integer):boolean;
   function    PRecBuffer(const RecordNo:integer; Old: boolean):TDataBuffer;
   function    RecordPosition(const RecordNo:integer;IsInternalRecno:boolean=False):integer;
   function    RecordBlock(const RecordNo:integer;ForceAllocMem: boolean;IsInternalRecno:boolean=False):integer;
   procedure   SetStrOffset(Index:integer;Offset,DataSize:integer);
   function    Capacity:integer;
   procedure   ReadRecord(const RecordNo:integer;var Dest:TDataBuffer);
   procedure   ReadRecordBuffer(RecordNo:integer;var Dest:TDataBuffer;Old:boolean);
   function    GetFieldData(RecordNo,FieldOffSet,StrIndex:integer;Var RecordData:Pointer):Pointer;
   function    GetStringFieldData(RecordNo,StrIndex:integer):Pointer;
   function    GetNonStringFieldData(RecordNo,FieldOffSet:integer;Var RecordData:Pointer):Pointer;
   procedure   ShiftMapValues(Distance:integer);


   procedure   WriteRecord(RecordNo:integer;const Source:TDataBuffer;ForceAllocMem: boolean);
   procedure   WriteField(RecordNo,FieldOffSet:integer;const Data:TDataBuffer;SizeData:integer);
   procedure   SetStringValue(Index,RecordNo:integer; const Value:string);
   procedure   SetStringFromPChar(Index,RecordNo:integer; const Value:PAnsiChar; Len:integer;Triming:boolean);
   procedure   SaveOldBuffer  (RecordNo:integer);
   procedure   ClearOldBuffer;
   procedure   SaveToChangeLog(aRecordNo:integer);
   function    OldBuffer(RecordNo:integer):TDataBuffer;
   function    pRecBuff(RecordNo:integer):TDataBuffer;
   procedure   RevertRecord(aRecordNo:integer);
   procedure   ClearLog;

   procedure   SwapRecords(OldRecordNo,NewRecordNo:integer);
   procedure   MoveRecord(OldRecno,NewRecno:integer);


   procedure   SaveToStream(Stream:TStream; SeekBegin :boolean;CacheSize:integer=32*1024);
   procedure   LoadFromStream(Stream:TStream; SeekBegin :boolean );
   procedure   Insert(RecordNo:integer);
   procedure   CancelInsert(RecordNo:integer);
   function    BookMarkByRecord(RecordNo:integer):integer;
   function    RecordByBookMark(BookMark:integer):integer;
   function    BookMarkValid(BookMark:integer):boolean;
   property    ChangesBlockCount:integer read GetChangesBlockCount write SetChangeLogBlockCount; 
  public
   property    RecordSize:Integer read FRecordSize;
   property    BlockCount:integer read GetBlockCount write SetBlockCount;
   property    RecordCount:integer read FRecordCount;
   property    Size:integer read GetSize;
   property    SaveChangeLog :boolean read FSaveChangeLog  write FSaveChangeLog;
  end;

  EMemManagerError=class(Exception);

const
  MinBlockSize=1024;

implementation

uses StdFuncs,StrUtil;
{ TRecordsCache }

{$IFNDEF D6+}
type
 PInteger=^Integer;
{$ENDIF}
constructor TRecordsCache.Create(aBlockRecCount,aRecordSize,aBlockReadSize,aStrCount:integer);
var
    aBlockSize:integer;
begin

 FOldBufRecordNumber:=-1;
 FRecordSize      :=aBlockReadSize;
 FInOutRecordSize :=aRecordSize;
 aBlockSize       :=aBlockRecCount*FRecordSize ;
 if aBlockSize<MinBlockSize then
   aBlockSize:=MinBlockSize+ aRecordSize-(MinBlockSize mod aRecordSize);

 if (aBlockSize < FRecordSize) then
  raise EMemManagerError.Create('Incompatible Sizes');
 FBlocks        :=nil;
 FBlocks        :=TFIBList.Create;
 FBlockSize     :=aBlockSize;
 FRecordCount:=0;
 FRecInBlock :=FBlockSize div FRecordSize;
 FLogStringData :=nil;
 if aStrCount>0 then
 begin
   FStrFieldCount :=aStrCount;
   FStringData    :=TStringCollection.Create(aStrCount);
   GetMem(FStringFieldOffsets , aStrCount * SizeOf(Integer));
   GetMem(FStringFieldSize    , aStrCount * SizeOf(Integer));
 end
 else
 begin
   FStrFieldCount :=0;
   FStringData :=nil;
   FStringFieldOffsets:=nil;
 end;

 GetMem(FOldBuffer , FInOutRecordSize);
 if FInOutRecordSize>0 then
  FillChar(FOldBuffer[0],FInOutRecordSize,1); // NullValues

 FChangeLog    :=nil;
 FChangesPositions:=nil;

 FChangesCount :=0;
 FSaveChangeLog:=False;
 FMapRecords  :=nil;
end;

destructor TRecordsCache.Destroy;
var
  i:integer;
begin
  for i := 0 to BlockCount - 1 do
   FreeMem(FBlocks.List^[i]);
  for i := 0 to ChangesBlockCount - 1 do
   FreeMem(FChangeLog.List^[i]);

  ReallocMem(FStringFieldOffsets,0);
  ReallocMem(FChangesPositions,0);
  ReallocMem(FStringFieldSize,0);
  FreeMem(FOldBuffer);

  FStringData    .Free;
  FLogStringData .Free;

  FBlocks    .Free;
  if FChangeLog<>nil then
   FChangeLog .Free;
  FMapRecords.Free;
  inherited;
end;



procedure TRecordsCache.Assign(SourceCache: TRecordsCache);
var
    i,j:integer;
    ExistingBlockCount:integer;
    ExistingCheckBlockCount:integer;
    p:Pointer;
begin
  if FBlockSize<>SourceCache.FBlockSize then
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
    if FChangeLog<>nil then
     FChangeLog.Clear;
  end;

  if BlockCount>=SourceCache.BlockCount then
  begin
    for i := BlockCount-1 downto SourceCache.BlockCount do
      FreeMem(FBlocks.List^[i]);
    FBlocks.Count:=SourceCache.BlockCount;
    ExistingBlockCount:=SourceCache.BlockCount
  end
  else
   ExistingBlockCount:=BlockCount;


  if ChangesBlockCount>=SourceCache.ChangesBlockCount then
  begin
    for i := ChangesBlockCount-1 downto SourceCache.ChangesBlockCount  do
      FreeMem(FChangeLog.List^[i]);
    ExistingCheckBlockCount:=SourceCache.ChangesBlockCount
  end
  else
   ExistingCheckBlockCount:=ChangesBlockCount;

    FBlockSize:=SourceCache.FBlockSize;
    FBlocks.Count:=SourceCache.BlockCount;
    ChangesBlockCount:=SourceCache.ChangesBlockCount;

    for i := 0 to BlockCount - 1 do
    begin
      if i>=ExistingBlockCount then
       FBlocks.List^[i]:=nil;
      if Assigned(FBlocks.List^[i]) then
      begin
        p:=FBlocks.List^[i];
        ReallocMem(p,FBlockSize);
        FBlocks.List^[i]:=p;
      end
      else
       FBlocks.List^[i]:=AllocMem(FBlockSize);
      Move(SourceCache.FBlocks.List^[i]^,FBlocks.List^[i]^,FBlockSize);
    end;

    for i := 0 to ChangesBlockCount - 1 do
    begin
      if i>=ExistingCheckBlockCount then FChangeLog.List^[i]:=nil;
      p:=FChangeLog.List^[i];
      ReallocMem(p,FBlockSize);
      FChangeLog.List^[i]:=p;
      Move(SourceCache.FChangeLog.List^[i]^,FChangeLog.List^[i]^,FBlockSize);
    end;

  FChangesCount:=SourceCache.FChangesCount;
  ReallocMem(FChangesPositions,FChangesCount* SizeOf(TRecordPosition));
  for i := 1 to FChangesCount do
  begin
   FChangesPositions^[i].RecordNo:=SourceCache.FChangesPositions^[i].RecordNo;
   FChangesPositions^[i].InternalNo:=SourceCache.FChangesPositions^[i].InternalNo;
  end;

  FStrFieldCount :=SourceCache.FStrFieldCount;
  ReallocMem(FStringFieldOffsets , FStrFieldCount * SizeOf(Integer));
  ReallocMem(FStringFieldSize    , FStrFieldCount * SizeOf(Integer));


  FStringData.Free;
  FLogStringData .Free;
  if FStrFieldCount>0 then
  begin
    for i := 1 to FStrFieldCount do
    begin
      FStringFieldOffsets^[i]:=SourceCache.FStringFieldOffsets^[i];
      FStringFieldSize^[i]   :=SourceCache.FStringFieldSize^[i];
    end;
    FStringData   :=TStringCollection.Create(FStrFieldCount);
    FStringData.Capacity:=SourceCache.FStringData.Capacity;
    for i := 0 to Pred(SourceCache.FStringData.HighX) do
     for j := 0 to Pred(SourceCache.FStringData.CountY) do
     begin
      if i=0 then FStringData.Add;
      FStringData[i,j]:=SourceCache.FStringData[i,j];
     end;

    if Assigned(SourceCache.FLogStringData) then
    begin
     FLogStringData:=TStringCollection.Create(FStrFieldCount);
     FLogStringData.Capacity:=SourceCache.FLogStringData.Capacity;
      for i := 0 to Pred(SourceCache.FLogStringData.HighX) do
       for j := 0 to Pred(SourceCache.FLogStringData.CountY) do
       begin
        if i=0 then FLogStringData.Add;
        FLogStringData[i,j]:=SourceCache.FLogStringData[i,j];
       end;
    end;
      
  end
  else
  begin
   FStringData:=nil;
   FLogStringData:=nil;
  end;

  FInOutRecordSize:=SourceCache.FInOutRecordSize;
  FRecordSize     :=SourceCache.FRecordSize     ;
  FRecInBlock     :=SourceCache.FRecInBlock     ;
  FRecordCount    :=SourceCache.FRecordCount     ;
  ReallocMem(FOldBuffer , FInOutRecordSize);

end;

procedure TRecordsCache.SetBlockCount(NewCount: Integer);
begin
  if NewCount>=FBlocks.Capacity then
   FBlocks.Capacity:=NewCount+10;
  FBlocks.Count:=NewCount
end;

function  TRecordsCache.GetBlockCount:integer;
begin
 Result:=FBlocks.Count
end;

function  TRecordsCache.CreateNewBlock:integer;
begin
  SetBlockCount(BlockCount+1);
  FBlocks.List^[BlockCount-1]:=AllocMem(FBlockSize);
  Result:=BlockCount;
end;

function    TRecordsCache.MemoryPrepared(RecordNo:integer):boolean;
begin
 if Assigned(FMapRecords) then
   Result := (RecordNo<FMapRecords.Count)
 else
   Result := RecordNo<FRecordCount;
end;

function  TRecordsCache.PrepareMemory(RecordNo:integer):TDataBuffer;
var
 BlockNo:integer;
 IRecordNo,i,c     :integer;
begin
 if Assigned(FMapRecords) and (RecordNo>FMapRecords.Count) then
 begin
  c:=FMapRecords.Count;
  for i:=c to RecordNo-1 do
   FMapRecords.Add(Pointer(FRecordCount+1+i-c));
  FRecordCount:=FMapRecords.Count ;
  if Assigned(FStringData) then
   while (FStringData.CountY<FMapRecords.Count) do
    FStringData.Add
 end
 else
  if FRecordCount<RecordNo then   FRecordCount:=RecordNo;
 IRecordNo:=InternalRecordNo(RecordNo);
 BlockNo:=(IRecordNo-1) div FRecInBlock;
 if BlockNo=BlockCount then
  CreateNewBlock;
 Result:=TDataBuffer(FBlocks.List^[BlockNo])+RecordPosition(IRecordNo,True);
end;

function TRecordsCache.RecordPosition(const RecordNo: integer;IsInternalRecno:boolean=False): integer;
begin
  if IsInternalRecno then
   Result  := ((RecordNo-1) mod FRecInBlock)*FRecordSize  
  else
   Result  := ((InternalRecordNo(RecordNo)-1) mod FRecInBlock)*FRecordSize
end;


function TRecordsCache.Capacity:integer;
begin
 Result:= (FBlockSize div FRecordSize)*BlockCount;
end;

function TRecordsCache.RecordBlock(const RecordNo: integer;ForceAllocMem: boolean;IsInternalRecno:boolean=False): integer;
begin
 if ForceAllocMem then
 begin
  PrepareMemory(RecordNo);
  if (RecordNo>FRecordCount)  then
   FRecordCount:=RecordNo;
 end;
 if IsInternalRecno then
  Result    := (RecordNo-1) div FRecInBlock 
 else
  Result    := (InternalRecordNo(RecordNo)-1) div FRecInBlock;
end;


procedure TRecordsCache.ReadRecord(const RecordNo: integer; var Dest: TDataBuffer);
begin
 ReadRecordBuffer(RecordNo,  Dest,False);
end;

function TRecordsCache.PRecBuffer(const RecordNo:integer; Old: boolean):TDataBuffer;
var
   BlockIndex:integer;
   PosInBlock:integer;
   IRecordNo:integer;
begin
  IRecordNo:=InternalRecordNo(RecordNo);
  BlockIndex:=RecordBlock(IRecordNo,False,True);
  if BlockIndex>=BlockCount then
     raise EMemManagerError.Create('Can''t read Buffer.Incorrect RecordNo');
  PosInBlock:=RecordPosition(IRecordNo,True);
  Result :=TDataBuffer(FBlocks.List^[BlockIndex])+PosInBlock;
end;


procedure TRecordsCache.ReadRecordBuffer(RecordNo: integer;
  var Dest: TDataBuffer; Old: boolean);
var
   BlockIndex:integer;
   PosInBlock:integer;
   Cache:TDataBuffer;
   i,L:integer;
   IRecordNo:integer;
   p:PRecordPosition;
   ss:TStringCollection;
   ps:PFIBByteString;
begin
  IRecordNo:=InternalRecordNo(RecordNo);
  if Old then
  begin
    p:=GetChangePosition(IRecordNo,False);
    if not Assigned(p) then
    begin
     ReadRecordBuffer(RecordNo, Dest,False);
     Exit;
    end;
    IRecordNo:=p^.InternalNo;
    ss:=FLogStringData;
    BlockIndex:=(IRecordNo-1) div FRecInBlock;
    if BlockIndex>=ChangesBlockCount then
     raise EMemManagerError.Create('Can''t read LogBuffer.Incorrect RecordNo');
   PosInBlock:= ((IRecordNo-1) mod FRecInBlock)*FRecordSize;
  end
  else
  begin
    ss:=FStringData;
    BlockIndex:=RecordBlock(IRecordNo,False,True);
    if BlockIndex>=BlockCount then
     raise EMemManagerError.Create('Can''t read Buffer.Incorrect RecordNo');
    PosInBlock:=RecordPosition(IRecordNo,True);
  end;
  if Old  then
   Cache:=TDataBuffer(FChangeLog.List^[BlockIndex])+PosInBlock
  else
   Cache:=TDataBuffer(FBlocks.List^[BlockIndex])+PosInBlock;
  if (FStrFieldCount=0) then
   Move(Cache^,Dest^,FRecordSize)
  else
  begin
    Move(Cache[0],Dest[0],FStringFieldOffsets^[1]);
    for i := 1 to FStrFieldCount do
    begin
      ps:=ss.PValue[i-1,IRecordNo-1];
      if ps<>nil then
      begin
      L:=Length(ps^);
      if L>FStringFieldSize^[i] then
      begin
       L:=FStringFieldSize^[i];
       SetLength(ps^,L);       
      end;
      PInteger(@Dest[FStringFieldOffsets^[i]])^:=L; // LengthExp
      if (L>0)  then
      begin
       Move(ps^[1],Dest[FStringFieldOffsets^[i]+SizeOf(Integer)],L);
      end;
      if L<FStringFieldSize^[i] then
	   {$IFDEF D2009+}
	     Dest[FStringFieldOffsets^[i]+L+SizeOf(Integer)]:=0;
	   {$ELSE}
	     Dest[FStringFieldOffsets^[i]+L+SizeOf(Integer)]:=#0;
	   {$ENDIF}
     end;
    end;
    if FRecordSize>FStringFieldOffsets^[1] then //Blobs
     Move(Cache[FStringFieldOffsets^[1]],
      Dest[FStringFieldOffsets^[FStrFieldCount]+SizeOf(Integer)+FStringFieldSize^[FStrFieldCount]],
      FRecordSize-FStringFieldOffsets^[1]
     );
  end;
end;

procedure TRecordsCache.WriteRecord(RecordNo: integer;
  const Source: TDataBuffer; ForceAllocMem: boolean );
var
   BlockIndex:integer;
   PosInBlock:integer;
   Cache:TDataBuffer;
   L,i:integer;
   ps:PFIBByteString;
begin
  BlockIndex:=RecordBlock(RecordNo,ForceAllocMem);
  if BlockIndex<BlockCount then
  begin
    PosInBlock:=RecordPosition(RecordNo);
    Cache:=TDataBuffer(FBlocks.List^[BlockIndex])+PosInBlock;
    if Source=nil then
     FillChar(Cache^,FRecordSize,0)
    else
    begin
     if (FStrFieldCount=0) then
      Move(Source[0],Cache[0],FRecordSize)
     else
     begin
      Move(Source[0],Cache[0],FStringFieldOffsets^[1]);
      Move(Source[FStringFieldOffsets^[FStrFieldCount]+FStringFieldSize^[FStrFieldCount]+SizeOf(Integer)],
       Cache[FStringFieldOffsets^[1]],   FRecordSize-FStringFieldOffsets^[1]
      );
     end;
     if Assigned(FStringData) then
     begin
       RecordNo:=InternalRecordNo(RecordNo);
       for i := 1 to FStrFieldCount do
       begin
         if FStringData.CountY<=RecordNo then
          FStringData.Add;
         ps:=FStringData.PValue[i-1,RecordNo-1];
         L:=PInteger(@Source[FStringFieldOffsets^[i]])^;
         if L<>Length(ps^) then
          SetLength(ps^,L);
         if L>0 then
          Move(Source[FStringFieldOffsets^[i]+SizeOf(Integer)],ps^[1],L);
       end;
     end
    end;
  end
  else
   raise EMemManagerError.Create('Can''t write to Buffer.Incorrect RecordNo');
end;



function TRecordsCache.InternalRecordNo(const RecordNo: integer): Integer;
begin
 if Assigned(FMapRecords) then
  if RecordNo<=FMapRecords.Count then
   Result :=Integer(FMapRecords.List^[RecordNo-1])
  else
   Result := -1
 else
  Result :=RecordNo
end;



function TRecordsCache.GetSize: integer;
begin
 Result:=BlockCount*FBlockSize;
end;

procedure TRecordsCache.SetStrOffset(Index, Offset,DataSize: integer);
begin
 if Assigned(FStringFieldOffsets) and Assigned(FStringData )then
 if (Index<=FStringData.HighX) and (Index>0) then
 begin
     FStringFieldOffsets^[Index]:=Offset;
     FStringFieldSize^[Index]   :=DataSize;
 end;
end;


procedure TRecordsCache.WriteField(RecordNo, FieldOffSet: integer;
  const Data: TDataBuffer; SizeData: integer);
var
 BlockIndex:integer;
 PosInBlock:integer;
 Cache:TDataBuffer;
begin
  BlockIndex:=RecordBlock(RecordNo,False);
  if BlockIndex<BlockCount then
  begin
    PosInBlock:=RecordPosition(RecordNo);
    Cache:=TDataBuffer(FBlocks.List^[BlockIndex])+PosInBlock+FieldOffSet;
    if Data=nil then
     FillChar(Cache^,SizeData,0)
    else
     Move(Data[0],Cache^,SizeData);
  end
  else
   raise EMemManagerError.Create('Can''t write to Field to Buffer.Incorrect RecordNo');
end;

function  TRecordsCache.GetStringFieldData(RecordNo,StrIndex:integer):Pointer;
begin
// used in new Locate
  if Assigned(FMapRecords) then
   RecordNo :=InternalRecordNo(RecordNo+1)-1;
  if RecordNo>FStringData.Capacity then
      raise EMemManagerError.Create('Can''t read  FieldData .Incorrect RecordNo');
   Result:=FStringData.PValue[StrIndex,RecordNo];

end;

function TRecordsCache.GetFieldData(  RecordNo,FieldOffSet,StrIndex:integer;
 var RecordData:Pointer ):Pointer;
var
 BlockIndex:integer;
 PosInBlock:integer;
begin
// Used in Locate

  if Assigned(FMapRecords) then
   RecordNo :=InternalRecordNo(RecordNo);

  BlockIndex:=(RecordNo-1) div FRecInBlock;
  if BlockIndex<FBlocks.Count then
  begin
      PosInBlock:=(RecordNo-1-BlockIndex*FRecInBlock)*FRecordSize;
      RecordData:=FBlocks.List^[BlockIndex];
      Inc(PByte(RecordData),PosInBlock);
  end
  else
     raise EMemManagerError.Create('Can''t read  FieldData .Incorrect RecordNo');
  if (StrIndex=-1) or (FStrFieldCount=0)  then
  begin
      Result:=RecordData;
      Inc(PByte(Result),FieldOffSet);
  end
  else
  begin
    if  RecordNo>FStringData.Capacity then
      raise EMemManagerError.Create('Can''t read  FieldData .Incorrect RecordNo');
    Result:=FStringData.PValue[StrIndex,RecordNo-1];
  end;

end;

function    TRecordsCache.GetNonStringFieldData(RecordNo,FieldOffSet:integer;Var RecordData:Pointer):Pointer;
var
 BlockIndex:integer;
 PosInBlock:integer;
begin
// used in new Locate

  if Assigned(FMapRecords) then
   RecordNo :=InternalRecordNo(RecordNo+1)-1;

  BlockIndex:=RecordNo div FRecInBlock;
  if BlockIndex<FBlocks.Count then
  begin
//    PosInBlock:=(RecordNo mod FRecInBlock)*FRecordSize;
    PosInBlock:=(RecordNo-BlockIndex*FRecInBlock)*FRecordSize;

    RecordData:=FBlocks.List^[BlockIndex];
    Inc(TDataBuffer(RecordData),PosInBlock)
  end
  else
     raise EMemManagerError.Create('Can''t read  FieldData .Incorrect RecordNo');
   ;
  Result:=RecordData;
  Inc(TDataBuffer(Result),FieldOffSet);
end;


procedure TRecordsCache.SetStringValue(Index, RecordNo: integer;
  const Value: string);
var
  i,L:integer;
  Added:Boolean;

begin
 if Assigned(FStringFieldOffsets) and Assigned(FStringData)then
 begin

  if Assigned(FMapRecords) then
   RecordNo:=InternalRecordNo(RecordNo+1)-1;
  Added:=FStringData.CountY<=RecordNo;
  while FStringData.CountY<=RecordNo do
    FStringData.Add;

  L:= Length(Value);
  if L=0 then
  begin
   if not Added then
    FStringData.SetPCharValue(Index,RecordNo,'',0)
//    FStringData.Value[Index,RecordNo]:=''
  end
  else
  if FStringFieldSize^[Index+1]<L then
  begin
  // For char Fields
   i:=FStringFieldSize^[Index+1];
   while (i>0) and (Value[i]<=' ') do  Dec(i);
  { if i<FStringFieldSize^[Index+1] then
   begin
    DoCopy(Value,FStringData.PValue[Index,RecordNo]^,1,i)
   end
   else}
    FStringData.Value[Index,RecordNo]:=Value;
  end
  else
  if (Value[L]=' ') then
   FStringData.Value[Index,RecordNo]:=TrimRight(Value)
  else
   FStringData.Value[Index,RecordNo]:=Value
 end;
end;

procedure TRecordsCache.SetStringFromPChar(Index,RecordNo:integer; const Value:PAnsiChar;
 Len:integer; Triming:boolean
);
begin
  if Assigned(FMapRecords) then
   RecordNo:=InternalRecordNo(RecordNo+1)-1;
  while FStringData.CountY<=RecordNo do
    FStringData.Add;
  if Triming then
  begin
   if Len<0 then
    Len:=FStringFieldSize^[Index+1];
   while (Len>0) and (Value[Len-1]=' ') do
    Dec(Len);
   if (Len<FStringFieldSize^[Index+1]) then
   begin
     Value[Len]:=#0;
   end;
  end;
  FStringData.SetPCharValue(Index,RecordNo,Value,Len)
end;

function TRecordsCache.OldBuffer(RecordNo:integer): TDataBuffer;
begin
 if SaveChangeLog then
 begin
  if RecordNo<=FRecordCount then
   ReadRecordBuffer(RecordNo,FOldBuffer,True)
  else
   ClearOldBuffer
 end
 else
 begin
   if FOldBufRecordNumber<>RecordNo then
    if RecordNo<=FRecordCount then
     SaveOldBuffer(RecordNo)
    else
     ClearOldBuffer
 end;
 Result:=FOldBuffer
end;


procedure TRecordsCache.SaveOldBuffer(RecordNo: integer);
begin
 if SaveChangeLog then
   SaveToChangeLog(RecordNo)
 else
 begin
  if RecordNo<=FRecordCount then
   ReadRecord(RecordNo,FOldBuffer)
  else
   ClearOldBuffer;
  FOldBufRecordNumber:=RecordNo;
 end;
end;

procedure TRecordsCache.ClearOldBuffer;
begin
  FillChar(FOldBuffer[0],FInOutRecordSize,1); // NullValues
end;

procedure TRecordsCache.SaveToChangeLog(aRecordNo: integer);
var
   p:PRecordPosition;
   BlockIndex:integer;
   PosInBlock:integer;
   ChangeBlockIndex:integer;
   ChangePosInBlock:integer;
   i:integer;
   IRecordNo:integer;
begin
// for CachedUpdates
 if FChangeLog=nil then
  FChangeLog:=TFIBList.Create;
 IRecordNo:=InternalRecordNo(aRecordNo);
 BlockIndex:=RecordBlock(IRecordNo,False,True);
 PosInBlock:=RecordPosition(IRecordNo,True);

 p:=GetChangePosition(IRecordNo,True);
 ChangeBlockIndex:=(p^.InternalNo-1) div FRecInBlock;
 ChangePosInBlock:=((p^.InternalNo-1) mod FRecInBlock)*FRecordSize;

// if ((p^.InternalNo mod FRecInBlock)=1) and (BlockIndex>=ChangesBlockCount) then
 if (ChangeBlockIndex>=ChangesBlockCount) then
 begin
   SetChangeLogBlockCount(ChangesBlockCount+1);
   FChangeLog.List^[ChangesBlockCount-1]:=AllocMem(FBlockSize);
   if Assigned(FStringData) and not Assigned(FLogStringData) then
      FLogStringData    :=TStringCollection.Create(FStrFieldCount);
 end;


 Move(TDataBuffer(FBlocks.List^[BlockIndex])[PosInBlock],TDataBuffer(FChangeLog.List^[ChangeBlockIndex])[ChangePosInBlock],FRecordSize);
 if Assigned(FStringData) then
 begin
   if p^.InternalNo>=FLogStringData.CountY then FLogStringData.Add;
   for I := 0 to FStringData.HighX-1 do
   begin
    FLogStringData.Value[i,p^.InternalNo-1]:=FStringData.Value[i,IRecordNo-1];
   end;
 end;
end;

procedure TRecordsCache.SetChangeLogBlockCount(NewCount: Integer);
begin
  if FChangeLog=nil then  FChangeLog:=TFIBList.Create;
  FChangeLog.Count:=NewCount
end;

function TRecordsCache.GetChangePosition(aRecordNo: integer; Force:boolean): PRecordPosition;
var
   i:integer;
begin
 if FindChangeRecNo(aRecordNo,i) then
  Result:=@FChangesPositions^[i]
 else
 if not Force then
  Result := nil
 else
 begin
   Inc(FChangesCount);
   ReallocMem(FChangesPositions  , FChangesCount * SizeOf(TRecordPosition));
   Move(FChangesPositions[i],FChangesPositions[i+1],SizeOf(TRecordPosition)*(FChangesCount-i));
   with  FChangesPositions^[i] do
   begin
     RecordNo  :=aRecordNo;
     InternalNo:=FChangesCount;
     Result    :=@FChangesPositions^[i];
   end;
 end;
end;


procedure TRecordsCache.ClearLog;
var i:integer;
begin
  if FChangeLog=nil then  Exit;
  for i := 0 to ChangesBlockCount - 1 do
  begin
    FreeMem(FChangeLog[i]);
  end;
  FChangeLog.Clear;
  ReallocMem(FChangesPositions,0);
  FChangesCount     :=0
end;

function TRecordsCache.FindChangeRecNo(const ARecno:integer;
  var Index: integer): boolean;
var
  L, H, I, C: Integer;
 function Compare(I,I1:integer):integer;
 begin
    if I=I1 then Result:=0  else
    if I>I1 then  Result:=1 else Result:=-1;
 end;
begin
  Result := False;
  L := 1;
  H := FChangesCount;
  while L <= H do
  begin
    I := (L + H) shr 1;
    C:=Compare(FChangesPositions[I].RecordNo,ARecno);
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


procedure TRecordsCache.RevertRecord(aRecordNo: integer);
var
  Buf:TDataBuffer;
begin
 Buf:=OldBuffer(aRecordNo);
 WriteRecord(aRecordNo,Buf,False)
end;

function TRecordsCache.pRecBuff(RecordNo: integer): TDataBuffer;
var
   BlockIndex:integer;
   PosInBlock:integer;
begin
  BlockIndex:=RecordBlock(RecordNo,False);
  if BlockIndex<BlockCount then
  begin
    PosInBlock:=RecordPosition(RecordNo);
    Result := TDataBuffer(FBlocks.List^[BlockIndex])+PosInBlock;
  end
  else
    Result := nil;
end;


procedure TRecordsCache.SwapRecords(OldRecordNo, NewRecordNo: integer);
var
 c:Integer;
begin
 InitializeMap;
 c:=Integer(FMapRecords.List^[OldRecordNo]);
 FMapRecords.List^[OldRecordNo]:=FMapRecords.List^[NewRecordNo];
 FMapRecords.List^[NewRecordNo]:=Pointer(c);
end;

procedure   TRecordsCache.MoveRecord(OldRecno,NewRecno:integer);
var
 Position:integer;
begin
 if OldRecno=NewRecno then
  Exit;
 if NewRecno>OldRecno then
  Inc(NewRecno);
 InitializeMap;
 Position:=Integer(FMapRecords.List^[OldRecNo]);
 FMapRecords.Insert(NewRecNo,Pointer(Position));
 if OldRecNo<NewRecNo then
  FMapRecords.Delete(OldRecno)
 else
  FMapRecords.Delete(OldRecno+1)
end;

{.$DEFINE REL}
{$IFDEF REL}
procedure TRecordsCache.SaveToStream(Stream: TStream; SeekBegin: boolean;CacheSize:integer=32*1024);
const
  DefDelta:integer =   32*1024 ;
//  DefDelta:integer =   0 ;
var
  i,j,L:integer;
  P:PFIBByteString;
  sp:Int64;
begin

  with Stream do
  begin
   if SeekBegin then  Seek(0,soFromBeginning);

   if (DefDelta>0) and (Size-Position<BlockCount*FBlockSize) then
   begin
     sp:=Position;
     if FBlocks.Count*FBlockSize<DefDelta then
      Size:=Size+DefDelta
     else
      Size:=Size+FBlocks.Count*FBlockSize;
     Position:=sp;      // For FileStream
   end;
   i:=BlockCount;
   WriteBuffer(i,SizeOf(Integer));
   WriteBuffer(FBlockSize ,SizeOf(Integer));
   WriteBuffer(FInOutRecordSize ,SizeOf(Integer));
   WriteBuffer(FStrFieldCount ,SizeOf(Integer));
   WriteBuffer(FSaveChangeLog ,SizeOf(Boolean));
   WriteBuffer(FRecordCount  ,SizeOf(Integer));

   for i := 0 to BlockCount - 1 do
    WriteBuffer(FBlocks.List^[i]^,FBlockSize);

   if FStrFieldCount>0 then
   begin
    for i := 1 to FStrFieldCount do
    begin
     WriteBuffer(FStringFieldOffsets^[i]  ,SizeOf(Integer));
     WriteBuffer(FStringFieldSize^[i]  ,SizeOf(Integer));
    end;
   end;

  if FStrFieldCount>0 then
  begin
    if (DefDelta>0) and (Size-Position<FStrFieldCount*256) then
    begin
     sp:=Stream.Position;
     Stream.Size:=Stream.Size+DefDelta;
     Stream.Position:=sp; // For FileStream
    end;
     for i := 0 to FStrFieldCount - 1 do
      for j := 0 to FRecordCount - 1 do
      begin
       p:=FStringData.PValue[i,j];
       L:=Length(P^);
       if (DefDelta>0) and (Stream.Size-(Stream.Position+L)<100) then
       begin
        sp:=Stream.Position;
        Stream.Size:=Stream.Size+DefDelta;
        Stream.Position:=sp;            // For FileStream
       end;
       WriteBuffer(L,SizeOf(Integer));
       if L>0 then
        WriteBuffer(P^[1], L);
      end;
    end;
  if Assigned(FMapRecords) then
  begin
   Stream.WriteBuffer(FMapRecords.Count,SizeOf(Integer));
   for i := 0 to FMapRecords.Count - 1 do
    Stream.WriteBuffer(FMapRecords.List^[i],SizeOf(Integer));
  end
  else
  begin
   L:=0;
   Stream.WriteBuffer(L,SizeOf(Integer));
  end;
//  Apply real stream size
  Stream.Size:=Stream.Position;
 end
end;
{$ELSE}

procedure TRecordsCache.SaveToStream(Stream: TStream; SeekBegin: boolean;CacheSize:integer=32*1024);
var
  i,j,L:integer;
  P:PFIBByteString;
  CacheStream:TMemoryStream;
  curStream:TStream;
  UseCache:boolean;

  procedure FlushCache(Force:boolean; nextCount:integer);
  begin
   if UseCache then
   if Force or (CacheStream.Position+nextCount>=CacheSize) then
   begin
    Stream.WriteBuffer(CacheStream.Memory^, CacheStream.Position);
    CacheStream.Position:=0;
   end;
  end;

  procedure InternalWriteBuffer(const Buffer; Count: Longint);
  begin
   if Count>=CacheSize then
   begin
    FlushCache(True,0);
    Stream.WriteBuffer(Buffer  ,Count);
   end
   else
   begin
    FlushCache(False,Count);
    curStream.Write(Buffer  ,Count);
   end
  end;

begin
   with Stream do
   begin
     if SeekBegin then
      Seek(0,soFromBeginning);
//     CacheSize:=0;
     UseCache:=CacheSize>0;
     if  UseCache then
     begin
      CacheStream:=TMemoryStream.Create;
      curStream:=CacheStream;
      if CacheSize<32*1024 then
       CacheSize:=32*1024;
      CacheStream.Size:=CacheSize;
     end
     else
     begin
      CacheStream:=nil;
      curStream:=Stream  ;
     end;
   end;
  with curStream do
  try
   i:=BlockCount;
   InternalWriteBuffer(i,SizeOf(Integer));
   InternalWriteBuffer(FBlockSize ,SizeOf(Integer));
   InternalWriteBuffer(FInOutRecordSize ,SizeOf(Integer));
   InternalWriteBuffer(FStrFieldCount ,SizeOf(Integer));
   InternalWriteBuffer(FSaveChangeLog ,SizeOf(Boolean));
   InternalWriteBuffer(FRecordCount  ,SizeOf(Integer));

   for i := 0 to BlockCount - 1 do
   begin
    InternalWriteBuffer(FBlocks.List^[i]^,FBlockSize);
   end;

   if FStrFieldCount>0 then
   begin
    for i := 1 to FStrFieldCount do
    begin
     InternalWriteBuffer(FStringFieldOffsets^[i]  ,SizeOf(Integer));
     InternalWriteBuffer(FStringFieldSize^[i]  ,SizeOf(Integer));
    end;
   end;

  if FStrFieldCount>0 then
  begin
     for i := 0 to FStrFieldCount - 1 do
      for j := 0 to FRecordCount - 1 do
      begin
       p:=FStringData.PValue[i,j];
       L:=Length(P^);
       InternalWriteBuffer(L,SizeOf(Integer));
       if L>0 then
        InternalWriteBuffer(P^[1], L);
      end;
    end;
  if Assigned(FMapRecords) then
  begin
   InternalWriteBuffer(FMapRecords.Count,SizeOf(Integer));
   for i := 0 to FMapRecords.Count - 1 do
   begin
    InternalWriteBuffer(FMapRecords.List^[i],SizeOf(Integer));
   end
  end
  else
  begin
   L:=0;
   InternalWriteBuffer(L,SizeOf(Integer));
  end;
  FlushCache(True,0);
 finally
  if UseCache then
   CacheStream.Free
 end
end;

{$ENDIF}


procedure TRecordsCache.LoadFromStream(Stream: TStream;
  SeekBegin: boolean);
var
  i,j,L:integer;
  s:FIBByteString;
  p:Pointer;
begin
  for i := 0 to BlockCount - 1 do
  begin
    FreeMem(FBlocks.List^[i]);
  end;
  FBlocks.Clear;
  FMapRecords.Free;
  FMapRecords:=nil;
  FStringData .Free;
  FStringData :=nil;
  FStringFieldOffsets:=nil;

  with Stream do
  begin
   if SeekBegin then  Seek(0,soFromBeginning);
   ReadBuffer(i,SizeOf(Integer));
   FBlocks.Count:=i;
   ReadBuffer(FBlockSize ,SizeOf(Integer));
   ReadBuffer(FInOutRecordSize ,SizeOf(Integer));
   ReadBuffer(FStrFieldCount ,SizeOf(Integer));
   ReadBuffer(FSaveChangeLog ,SizeOf(Boolean));
   ReadBuffer(FRecordCount  ,SizeOf(Integer));
   for i := 0 to BlockCount - 1 do
   begin
    GetMem(p,FBlockSize);
    FBlocks.List^[i]:=p;
    ReadBuffer(FBlocks.List^[i]^,FBlockSize);
   end;
   if FStrFieldCount>0 then
   begin
    FStringData    :=TStringCollection.Create(FStrFieldCount);
    GetMem(FStringFieldOffsets , FStrFieldCount * SizeOf(Integer));
    GetMem(FStringFieldSize    , FStrFieldCount * SizeOf(Integer));
    for i := 1 to FStrFieldCount do
    begin
     ReadBuffer(FStringFieldOffsets^[i]  ,SizeOf(Integer));
     ReadBuffer(FStringFieldSize^[i]  ,SizeOf(Integer));
    end;

    for i := 0 to FStrFieldCount - 1 do
     for j := 0 to FRecordCount - 1 do
     begin 
       ReadBuffer(L,SizeOf(Integer));
       SetString(S, nil, L);
       Stream.Read(S[1], L);
       if FStringData.CountY<=j then FStringData.Add;
       FStringData.Value[i,j]:=s;
     end;
   end;  
  end;

  Stream.ReadBuffer(L,SizeOf(Integer));
  if L>0 then
  begin
   FMapRecords      :=TFIBList.Create;
   FMapRecords.Count:=L;

   for i := 0 to L - 1 do
    Stream.ReadBuffer(FMapRecords.List^[i],SizeOf(Integer));
  end

end;



procedure TRecordsCache.InitializeMap;
var
  i:Integer;
begin
  if not Assigned(FMapRecords) then
  begin
    FMapRecords      :=TFIBList.Create;
    FMapRecords.Count:=FRecordCount;
    for i := 0 to FMapRecords.Count - 1  do
    begin
      FMapRecords.List^[i]:=Pointer(i+1);
    end;
  end;
end;

procedure TRecordsCache.ShiftMapValues(Distance:integer);
var
  i:integer;
begin
  if not   Assigned(FMapRecords)  then
   InitializeMap;
  if Assigned(FMapRecords) then
  begin
    for i := 0 to FMapRecords.Count - 1  do
    begin
      FMapRecords.List^[i]:=Pointer(Integer(FMapRecords.List^[i])+Distance);
    end;
  end;
end;


procedure TRecordsCache.Insert(RecordNo: integer);
begin
 InitializeMap;
 Inc(FRecordCount);
 FMapRecords.Insert(RecordNo,Pointer(FRecordCount));
 if Assigned(FStringData) then
  FStringData.Add;
end;

procedure TRecordsCache.CancelInsert(RecordNo: integer);
begin
 if Assigned(FMapRecords) then
 begin
   if Integer(FMapRecords.List^[RecordNo-1])=FRecordCount then
    Dec(FRecordCount);
   if Assigned(FStringData) then
    FStringData.Delete(Integer(FMapRecords.List^[RecordNo-1])-1);
   FMapRecords.Delete(RecordNo-1);
 end;
end;

function TRecordsCache.BookMarkByRecord(RecordNo: integer): integer;
begin    
   Result:=InternalRecordNo(RecordNo+1)
end;

function TRecordsCache.RecordByBookMark(BookMark: integer): integer;
begin
 if Assigned(FMapRecords) then
 begin
  if (BookMark<=FMapRecords.Count) and (FMapRecords.List^[BookMark-1]=Pointer(BookMark)) then
   Result:=BookMark-1
  else
   Result:=FMapRecords.IndexOf(Pointer(BookMark))
 end
 else
  Result :=BookMark-1
end;

function TRecordsCache.BookMarkValid(BookMark: integer): boolean;
begin
 Result:=(BookMark>-1) ;
 if Result then
 begin
   if Assigned(FMapRecords) then
   begin
    Result:=(BookMark<FMapRecords.Count) and (FMapRecords.List^[BookMark-1]=Pointer(BookMark));
    if not Result then
     Result:=FMapRecords.IndexOf(Pointer(BookMark))>-1
   end
   else
    Result :=BookMark<=FRecordCount
 end;
end;

function TRecordsCache.GetChangesBlockCount: integer;
begin
 if FChangeLog=nil then
  Result := 0
 else
  Result:=FChangeLog.Count
end;

initialization

finalization

end.
