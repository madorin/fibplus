Unit ZUtil;

{
  Copyright (C) 1998 by Jacques Nomssi Nzali
  For conditions of distribution and use, see copyright notice in readme.txt
}

interface

{$I zconf.inc}
{ Type declarations }

type
  { Byte   = usigned char;  8 bits }
  Bytef = byte;
  charf = byte;

{$IFDEF FPC}
  int = longint;
{$ELSE}
  int = integer;
{$ENDIF}
  intf = int;
{$IFDEF MSDOS}
  uInt = Word;
{$ELSE}
{$IFDEF FPC}
  uInt = longint; { 16 bits or more }
{$INFO Cardinal}
{$ELSE}
  uInt = cardinal; { 16 bits or more }
{$ENDIF}
{$ENDIF}
  uIntf = uInt;

  Long = longint;
{$IFDEF Delphi5}
  uLong = cardinal;
{$ELSE}
  // uLong  = LongInt;      { 32 bits or more }
  uLong = LongWord; { DelphiGzip: LongInt is Signed, longword not }
{$ENDIF}
  uLongf = uLong;

  voidp = pointer;
  voidpf = voidp;
  pBytef = ^Bytef;
  pIntf = ^intf;
  puIntf = ^uIntf;
  puLong = ^uLongf;

  ptr2int = uInt;
  { a pointer to integer casting is used to do pointer arithmetic.
    ptr2int must be an integer type and sizeof(ptr2int) must be less
    than sizeof(pointer) - Nomssi }

const
{$IFDEF MAXSEG_64K}
  MaxMemBlock = $FFFF;
{$ELSE}
  MaxMemBlock = MaxInt;
{$ENDIF}

type
  zByteArray = array [0 .. (MaxMemBlock div SizeOf(Bytef)) - 1] of Bytef;
  pzByteArray = ^zByteArray;

type
  zIntfArray = array [0 .. (MaxMemBlock div SizeOf(intf)) - 1] of intf;
  pzIntfArray = ^zIntfArray;

type
  zuIntArray = array [0 .. (MaxMemBlock div SizeOf(uInt)) - 1] of uInt;
  PuIntArray = ^zuIntArray;

  { Type declarations - only for deflate }

type
  uch = byte;
  uchf = uch; { FAR }
  ush = Word;
  ushf = ush;
  ulg = longint;

  unsigned = uInt;

  pcharf = ^charf;
  puchf = ^uchf;
  pushf = ^ushf;

type
  zuchfArray = zByteArray;
  puchfArray = ^zuchfArray;

type
  zushfArray = array [0 .. (MaxMemBlock div SizeOf(ushf)) - 1] of ushf;
  pushfArray = ^zushfArray;

procedure zmemcpy(destp: pBytef; sourcep: pBytef; len: uInt);
function zmemcmp(s1p, s2p: pBytef; len: uInt): int;
procedure zmemzero(destp: pBytef; len: uInt);
procedure zcfree(opaque: voidpf; ptr: voidpf);
function zcalloc(opaque: voidpf; items: uInt; size: uInt): voidpf;

implementation

{$IFDEF ver80}
{$DEFINE Delphi16}
{$ENDIF}
{$IFDEF ver70}
{$DEFINE HugeMem}
{$ENDIF}
{$IFDEF ver60}
{$DEFINE HugeMem}
{$ENDIF}
{$IFDEF CALLDOS}

uses
  WinDos;
{$ENDIF}
{$IFDEF Delphi16}

uses
  WinTypes,
  WinProcs;
{$ENDIF}
{$IFNDEF FPC}
{$IFDEF DPMI}

uses
  WinAPI;
{$ENDIF}
{$ENDIF}
{$IFDEF CALLDOS}

{ reduce your application memory footprint with $M before using this }
function dosAlloc(size: longint): pointer;
var
  regs: TRegisters;
begin
  regs.bx := (size + 15) div 16; { number of 16-bytes-paragraphs }
  regs.ah := $48; { Allocate memory block }
  msdos(regs);
  if regs.Flags and FCarry <> 0 then
    dosAlloc := NIL
  else
    dosAlloc := ptr(regs.ax, 0);
end;

function dosFree(P: pointer): boolean;
var
  regs: TRegisters;
begin
  dosFree := FALSE;
  regs.bx := Seg(P^); { segment }
  if Ofs(P) <> 0 then
    exit;
  regs.ah := $49; { Free memory block }
  msdos(regs);
  dosFree := (regs.Flags and FCarry = 0);
end;
{$ENDIF}

type
  LH = record
    L, H: Word;
  end;

{$IFDEF HugeMem}
{$DEFINE HEAP_LIST}
{$ENDIF}
{$IFDEF HEAP_LIST}
  { --- to avoid Mark and Release --- }
const
  MaxAllocEntries = 50;

type
  TMemRec = record
    orgvalue, value: pointer;
    size: longint;
  end;

const
  allocatedCount: 0 .. MaxAllocEntries = 0;

var
  allocatedList: array [0 .. MaxAllocEntries - 1] of TMemRec;

function NewAllocation(ptr0, ptr: pointer; memsize: longint): boolean;
begin
  if (allocatedCount < MaxAllocEntries) and (ptr0 <> NIL) then
  begin
    with allocatedList[allocatedCount] do
    begin
      orgvalue := ptr0;
      value := ptr;
      size := memsize;
    end;
    Inc(allocatedCount); { we don't check for duplicate }
    NewAllocation := TRUE;
  end
  else
    NewAllocation := FALSE;
end;
{$ENDIF}
{$IFDEF HugeMem}

{ The code below is extremely version specific to the TP 6/7 heap manager!! }
type
  PFreeRec = ^TFreeRec;

  TFreeRec = record
    next: PFreeRec;
    size: pointer;
  end;

type
  HugePtr = voidpf;

procedure IncPtr(var P: pointer; count: Word);
{ Increments pointer }
begin
  Inc(LH(P).L, count);
  if LH(P).L < count then
    Inc(LH(P).H, SelectorInc); { $1000 }
end;

procedure DecPtr(var P: pointer; count: Word);
{ decrements pointer }
begin
  if count > LH(P).L then
    dec(LH(P).H, SelectorInc);
  dec(LH(P).L, count);
end;

procedure IncPtrLong(var P: pointer; count: longint);
{ Increments pointer; assumes count > 0 }
begin
  Inc(LH(P).H, SelectorInc * LH(count).H);
  Inc(LH(P).L, LH(count).L);
  if LH(P).L < LH(count).L then
    Inc(LH(P).H, SelectorInc);
end;

procedure DecPtrLong(var P: pointer; count: longint);
{ Decrements pointer; assumes count > 0 }
begin
  if LH(count).L > LH(P).L then
    dec(LH(P).H, SelectorInc);
  dec(LH(P).L, LH(count).L);
  dec(LH(P).H, SelectorInc * LH(count).H);
end;
{ The next section is for real mode only }

function Normalized(P: pointer): pointer;
var
  count: Word;
begin
  count := LH(P).L and $FFF0;
  Normalized := ptr(LH(P).H + (count shr 4), LH(P).L and $F);
end;

procedure FreeHuge(var P: HugePtr; size: longint);
const
  blocksize = $FFF0;
var
  block: Word;
begin
  while size > 0 do
  begin
    { block := minimum(size, blocksize); }
    if size > blocksize then
      block := blocksize
    else
      block := size;

    dec(size, block);
    freemem(P, block);
    IncPtr(P, block); { we may get ptr($xxxx, $fff8) and 31 bytes left }
    P := Normalized(P); { to free, so we must normalize }
  end;
end;

function FreeMemHuge(ptr: pointer): boolean;
var
  i: integer; { -1..MaxAllocEntries }
begin
  FreeMemHuge := FALSE;
  i := allocatedCount - 1;
  while (i >= 0) do
  begin
    if (ptr = allocatedList[i].value) then
    begin
      with allocatedList[i] do
        FreeHuge(orgvalue, size);

      Move(allocatedList[i + 1], allocatedList[i], SizeOf(TMemRec) * (allocatedCount - 1 - i));
      dec(allocatedCount);
      FreeMemHuge := TRUE;
      break;
    end;
    dec(i);
  end;
end;

procedure GetMemHuge(var P: HugePtr; memsize: longint);
const
  blocksize = $FFF0;
var
  size: longint;
  prev, free: PFreeRec;
  save, temp: pointer;
  block: Word;
begin
  P := NIL;
  { Handle the easy cases first }
  if memsize > maxavail then
    exit
  else if memsize <= blocksize then
  begin
    getmem(P, memsize);
    if not NewAllocation(P, P, memsize) then
    begin
      freemem(P, memsize);
      P := NIL;
    end;
  end
  else
  begin
    size := memsize + 15;

    { Find the block that has enough space }
    prev := PFreeRec(@freeList);
    free := prev^.next;
    while (free <> heapptr) and (ptr2int(free^.size) < size) do
    begin
      prev := free;
      free := prev^.next;
    end;

    { Now free points to a region with enough space; make it the first one and
      multiple allocations will be contiguous. }

    save := freeList;
    freeList := free;
    { In TP 6, this works; check against other heap managers }
    while size > 0 do
    begin
      { block := minimum(size, blocksize); }
      if size > blocksize then
        block := blocksize
      else
        block := size;
      dec(size, block);
      getmem(temp, block);
    end;

    { We've got what we want now; just sort things out and restore the
      free list to normal }

    P := free;
    if prev^.next <> freeList then
    begin
      prev^.next := freeList;
      freeList := save;
    end;

    if (P <> NIL) then
    begin
      { return pointer with 0 offset }
      temp := P;
      if Ofs(P^) <> 0 Then
        P := ptr(Seg(P^) + 1, 0); { hack }
      if not NewAllocation(temp, P, memsize + 15) then
      begin
        FreeHuge(temp, size);
        P := NIL;
      end;
    end;

  end;
end;

{$ENDIF}

procedure zmemcpy(destp: pBytef; sourcep: pBytef; len: uInt);
begin
  Move(sourcep^, destp^, len);
end;

function zmemcmp(s1p, s2p: pBytef; len: uInt): int;
var
  j: uInt;
  source, dest: pBytef;
begin
  source := s1p;
  dest := s2p;
  for j := 0 to pred(len) do
  begin
    if (source^ <> dest^) then
    begin
      zmemcmp := 2 * Ord(source^ > dest^) - 1;
      exit;
    end;
    Inc(source);
    Inc(dest);
  end;
  zmemcmp := 0;
end;

procedure zmemzero(destp: pBytef; len: uInt);
begin
  FillChar(destp^, len, 0);
end;

procedure zcfree(opaque: voidpf; ptr: voidpf);
{$IFDEF Delphi16}
var
  Handle: THandle;
{$ENDIF}
{$IFDEF FPC}
var
  memsize: uInt;
{$ENDIF}
begin
{$IFDEF DPMI}
  { h := } GlobalFreePtr(ptr);
{$ELSE}
{$IFDEF CALL_DOS}
  dosFree(ptr);
{$ELSE}
{$IFDEF HugeMem}
  FreeMemHuge(ptr);
{$ELSE}
{$IFDEF Delphi16}
  Handle := GlobalHandle(LH(ptr).H); { HiWord(LongInt(ptr)) }
  GlobalUnLock(Handle);
  GlobalFree(Handle);
{$ELSE}
{$IFDEF FPC}
  dec(puIntf(ptr));
  memsize := puIntf(ptr)^;
  freemem(ptr, memsize + SizeOf(uInt));
{$ELSE}
  freemem(ptr); { Delphi 2,3,4 }
{$ENDIF}
{$ENDIF}
{$ENDIF}
{$ENDIF}
{$ENDIF}
end;

function zcalloc(opaque: voidpf; items: uInt; size: uInt): voidpf;
var
  P: voidpf;
  memsize: uLong;
{$IFDEF Delphi16}
  Handle: THandle;
{$ENDIF}
begin
  memsize := uLong(items) * size;
{$IFDEF DPMI}
  P := GlobalAllocPtr(gmem_moveable, memsize);
{$ELSE}
{$IFDEF CALLDOS}
  P := dosAlloc(memsize);
{$ELSE}
{$IFDEF HugeMem}
  GetMemHuge(P, memsize);
{$ELSE}
{$IFDEF Delphi16}
  Handle := GlobalAlloc(HeapAllocFlags, memsize);
  P := GlobalLock(Handle);
{$ELSE}
{$IFDEF FPC}
  getmem(P, memsize + SizeOf(uInt));
  puIntf(P)^ := memsize;
  Inc(puIntf(P));
{$ELSE}
  getmem(P, memsize); { Delphi: p := AllocMem(memsize); }
{$ENDIF}
{$ENDIF}
{$ENDIF}
{$ENDIF}
{$ENDIF}
  zcalloc := P;
end;

end.
