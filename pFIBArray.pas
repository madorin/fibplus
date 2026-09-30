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



unit pFIBArray;
{$I FIBPlus.inc}

interface

uses
  SysUtils, Classes, ibase, IB_Intf, ib_externals, DB, fib, FIBDatabase, StdFuncs,
  FIBPlatforms, Variants;

{$IFDEF SUPPORT_ARRAY_FIELD}
type
  TpFIBArray = class
  private
    FDatabase: TFIBDatabase;
    FCharSet: string;
    FArrayType: TFieldType;
    FTableName: AnsiString;
    FFieldName: AnsiString;
    FArrayDesc: TISC_ARRAY_DESC;
    procedure CheckStatus(Status: ISC_STATUS);
    function DescScale: Integer;
    function ElementSize: Integer;
    function ReadElement(P: PAnsiChar): Variant;
    procedure WriteElement(const Value: Variant; P: PAnsiChar);
    procedure ConversionError(const Value: Variant);
    function ElementDesc(const Indexes: array of Integer): TISC_ARRAY_DESC;
    function ElementOffset(const Indexes: array of Integer): Integer;
    function GetDimensionCount: Integer;
    function GetDimension(Index: Integer): TISC_ARRAY_BOUND;
    function GetSliceSize(const Desc: TISC_ARRAY_DESC): Integer;
    function GetArraySize: Integer;
    function GetStoredElement(ArrayID: TDataBuffer; const Desc: TISC_ARRAY_DESC;
      DBHandle: PISC_DB_HANDLE; TRHandle: PISC_TR_HANDLE): Variant;
    function GetScale: Byte;
    procedure AdjustStringLength(Transaction: TFIBTransaction);
  public
    constructor Create(Database: TFIBDatabase; Transaction: TFIBTransaction;
      const ATableName, AFieldName: string);
    // The descriptor fits the column and the character set of the connection
    function Matches(Database: TFIBDatabase; const ATableName, AFieldName: string): Boolean;
    // for FIBQuery: the array with the ID in ArrayID
    function GetArrayValues(ArrayID: TDataBuffer;
      DBHandle: PISC_DB_HANDLE; TRHandle: PISC_TR_HANDLE): Variant;
    function GetElement(ArrayID: TDataBuffer; const Indexes: array of Integer;
      DBHandle: PISC_DB_HANDLE; TRHandle: PISC_TR_HANDLE): Variant;
    procedure SetArrayValue(const Value: Variant; var ArrayID: TDataBuffer;
      DBHandle: PISC_DB_HANDLE; TRHandle: PISC_TR_HANDLE);
    // Whole array in a buffer of ArraySize bytes, with the layout of the slice calls
    procedure InitBuffer(Buffer: PAnsiChar);
    function BufferToVariant(Buffer: PAnsiChar): Variant;
    procedure VariantToBuffer(const Value: Variant; Buffer: PAnsiChar);
    // Raises an error when Indexes don't address an element
    procedure CheckIndexes(const Indexes: array of Integer);
    function GetBufferElement(Buffer: PAnsiChar; const Indexes: array of Integer): Variant;
    procedure SetBufferElement(Buffer: PAnsiChar; const Indexes: array of Integer;
      const Value: Variant);
    // Reads the array with ID into Buffer, returns 0 for a NULL array
    function GetSlice(ID: PISC_QUAD; Buffer: PAnsiChar;
      DBHandle: PISC_DB_HANDLE; TRHandle: PISC_TR_HANDLE): Integer;
    // Writes Buffer as a new array, ID gets its (temporary) ID
    procedure PutSlice(Buffer: PAnsiChar; var ID: TISC_QUAD;
      DBHandle: PISC_DB_HANDLE; TRHandle: PISC_TR_HANDLE);

    property ArrayType: TFieldType read FArrayType;
    property TableName: AnsiString read FTableName;
    property FieldName: AnsiString read FFieldName;
    property DimensionCount: Integer read GetDimensionCount;
    property Dimension[Index: Integer]: TISC_ARRAY_BOUND read GetDimension;
    property ArraySize: Integer read GetArraySize;
    property Scale: Byte read GetScale;
  end;
{$ENDIF}

implementation

{$IFDEF SUPPORT_ARRAY_FIELD}
uses
  StrUtil, Math, FMTBcd, FIBTypes;

const
  // ISC_DATE 0 (1858-11-17) as TTimeStamp.Date
  IBBuffDateDelta = 678576;

// Next index of a Variant array in row-major order, False after the last element
function NextIndex(const Value: Variant; var Index: array of Integer): Boolean;
var
  i: Integer;
begin
  Result := True;
  for i := High(Index) downto 0 do
    if Index[i] < VarArrayHighBound(Value, i + 1) then
    begin
      Inc(Index[i]);
      Exit;
    end
    else
      Index[i] := VarArrayLowBound(Value, i + 1);
  Result := False;
end;

function VariantToDecimal(const Value: Variant): TFBDecimal;
var
  C: Currency;
  S: string;
begin
  case VarType(Value) of
    varShortInt, varByte, varSmallint, varWord, varInteger, varLongWord, varInt64:
      Result := Int64ToFBDecimal(Value);
    varCurrency:
    begin
      C := Value;
      Result := Int64ToFBDecimal(PInt64(@C)^, -4);
    end;
    varString, varOleStr{$IFDEF D2009+}, varUString{$ENDIF}:
    begin
      S := StringReplace(Trim(VarToStr(Value)), LocalDecimalSeparator, '.', []);
      if not StrToFBDecimal(S, Result) then
        Result := DoubleToFBDecimal(Value);
    end;
  else
    if VarIsFMTBcd(Value) then
      Result := BcdToFBDecimal(VarToBcd(Value))
    else
      Result := DoubleToFBDecimal(Value);
  end;
end;

// Value * 10^-Scale rounded half away from zero
function VariantToScaled(const Value: Variant; Scale: Integer; out Res: Int64): Boolean;
var
  D: TFBDecimal;
begin
  D := FBDecimalRescale(VariantToDecimal(Value), Scale);
  Result := D.Kind = dkFinite;
  if Result then
  begin
    D.Exponent := 0;
    Result := FBDecimalToInt64(D, Res);
  end;
end;

constructor TpFIBArray.Create(Database: TFIBDatabase; Transaction: TFIBTransaction;
  const ATableName, AFieldName: string);
begin
  inherited Create;
  FDatabase := Database;
  FCharSet := Database.ConnectParams.CharSet;
  FTableName := AnsiString(ATableName);
  FFieldName := AnsiString(AFieldName);
  CheckStatus(FDatabase.ClientLibrary.isc_array_lookup_bounds(StatusVector, @Database.Handle,
    @Transaction.Handle, PAnsiChar(FTableName), PAnsiChar(FFieldName), @FArrayDesc));
  if FArrayDesc.array_desc_dtype in [blr_text, blr_varying] then
    AdjustStringLength(Transaction);
  with FArrayDesc do
  begin
    case array_desc_dtype of
      blr_text, blr_varying:
        FArrayType := ftString;
      blr_short:
        if DescScale = 0 then
          FArrayType := ftSmallint
        else
          FArrayType := ftBCD;
      blr_long:
        if DescScale = 0 then
          FArrayType := ftInteger
        else
          FArrayType := ftBCD;
      blr_int64:
        if DescScale = 0 then
          FArrayType := ftLargeint
        else
          FArrayType := ftBCD;
      blr_int128, blr_dec64, blr_dec128:
        FArrayType := ftFMTBcd;
      blr_float, blr_double, blr_d_float:
        FArrayType := ftFloat;
      blr_timestamp, blr_timestamp_tz, blr_ex_timestamp_tz:
        FArrayType := ftDateTime;
      blr_sql_date:
        FArrayType := ftDate;
      blr_sql_time, blr_sql_time_tz, blr_ex_time_tz:
        FArrayType := ftTime;
      blr_bool:
        FArrayType := ftBoolean;
    else
      FArrayType := ftUnknown;
    end;
    // Elements WITH TIME ZONE are transferred as local time of the session time zone,
    // the server converts them
    case array_desc_dtype of
      blr_timestamp_tz, blr_ex_timestamp_tz:
      begin
        array_desc_dtype := blr_timestamp;
        array_desc_length := SizeOf(TISC_QUAD);
      end;
      blr_sql_time_tz, blr_ex_time_tz:
      begin
        array_desc_dtype := blr_sql_time;
        array_desc_length := SizeOf(ISC_TIME);
      end;
    end;
  end;
end;

// String elements are transferred in the connection character set, but the descriptor has
// the length in bytes of the column character set: CHAR(5) NONE is 5 bytes, one character in UTF8
procedure TpFIBArray.AdjustStringLength(Transaction: TFIBTransaction);
var
  Info: Variant;
  Length: Integer;
begin
  Info := FDatabase.QueryValues(
    'select coalesce(f.RDB$CHARACTER_LENGTH, f.RDB$FIELD_LENGTH), cs.RDB$BYTES_PER_CHARACTER ' +
    'from RDB$RELATION_FIELDS rf ' +
    'join RDB$FIELDS f on f.RDB$FIELD_NAME = rf.RDB$FIELD_SOURCE ' +
    'join RDB$CHARACTER_SETS cs on cs.RDB$CHARACTER_SET_ID = :CHARSET_ID ' +
    'where rf.RDB$RELATION_NAME = :RELATION_NAME and rf.RDB$FIELD_NAME = :FIELD_NAME',
    [FDatabase.FBAttachCharsetID, string(FTableName), string(FFieldName)], Transaction);
  if not VarIsArray(Info) or VarIsNull(Info[0]) or VarIsNull(Info[1]) then
    Exit;
  Length := Info[0] * Info[1];
  if Length > FArrayDesc.array_desc_length then
    FArrayDesc.array_desc_length := Length;
end;

function TpFIBArray.Matches(Database: TFIBDatabase; const ATableName, AFieldName: string): Boolean;
begin
  Result := (FDatabase = Database) and (FTableName = AnsiString(ATableName)) and
    (FFieldName = AnsiString(AFieldName)) and (FCharSet = Database.ConnectParams.CharSet);
end;

procedure TpFIBArray.CheckStatus(Status: ISC_STATUS);
begin
  if Status > 0 then
    IbError(FDatabase.ClientLibrary, Self);
end;

function TpFIBArray.DescScale: Integer;
begin
  Result := ShortInt(Ord(FArrayDesc.array_desc_scale));
end;

// Size of an element in the slice buffer, VARCHAR elements are null terminated strings
function TpFIBArray.ElementSize: Integer;
begin
  Result := FArrayDesc.array_desc_length;
  if FArrayDesc.array_desc_dtype = blr_varying then
    Inc(Result, 2);
end;

procedure TpFIBArray.ConversionError(const Value: Variant);
begin
  FIBErrorEx('Array %s.%s: can''t convert "%s" to the element type',
    [FTableName, FFieldName, VarToStr(Value)]);
end;

// Descriptor of the slice with the single element at Indexes
function TpFIBArray.ElementDesc(const Indexes: array of Integer): TISC_ARRAY_DESC;
var
  i: Integer;
begin
  if Length(Indexes) <> DimensionCount then
    FIBErrorEx('Array %s.%s has %d dimension(s), %d index(es) given',
      [FTableName, FFieldName, DimensionCount, Length(Indexes)]);
  Result := FArrayDesc;
  for i := 0 to DimensionCount - 1 do
  begin
    if (Indexes[i] < Dimension[i].array_bound_lower) or
      (Indexes[i] > Dimension[i].array_bound_upper)
    then
      FIBErrorEx('Array %s.%s: index %d is out of the bounds %d:%d of dimension %d',
        [FTableName, FFieldName, Indexes[i], Dimension[i].array_bound_lower,
        Dimension[i].array_bound_upper, i + 1]);
    Result.array_desc_bounds[i].array_bound_lower := Indexes[i];
    Result.array_desc_bounds[i].array_bound_upper := Indexes[i];
  end;
end;

// Offset of the element at Indexes in the buffer of the whole array (row-major)
function TpFIBArray.ElementOffset(const Indexes: array of Integer): Integer;
var
  i: Integer;
begin
  ElementDesc(Indexes);
  Result := 0;
  for i := 0 to DimensionCount - 1 do
    Result := Result * (Dimension[i].array_bound_upper - Dimension[i].array_bound_lower + 1) +
      Indexes[i] - Dimension[i].array_bound_lower;
  Result := Result * ElementSize;
end;

function TpFIBArray.GetScale: Byte;
begin
  Result := -DescScale;
end;

function TpFIBArray.GetDimensionCount: Integer;
begin
  Result := FArrayDesc.array_desc_dimensions;
end;

function TpFIBArray.GetDimension(Index: Integer): TISC_ARRAY_BOUND;
begin
  if (Index >= 0) and (Index < DimensionCount) then
    Result := FArrayDesc.array_desc_bounds[Index]
  else
    FIBError(feWrongDimension, [Index, FTableName + '.' + FFieldName]);
end;

function TpFIBArray.GetSliceSize(const Desc: TISC_ARRAY_DESC): Integer;
var
  i: Integer;
begin
  Result := ElementSize;
  for i := 0 to DimensionCount - 1 do
    Result := Result *
      (Desc.array_desc_bounds[i].array_bound_upper - Desc.array_desc_bounds[i].array_bound_lower + 1);
end;

function TpFIBArray.GetArraySize: Integer;
begin
  Result := GetSliceSize(FArrayDesc);
end;

function TpFIBArray.ReadElement(P: PAnsiChar): Variant;
var
  S: AnsiString;
  L: Integer;
  Bcd: TBcd;
  TS: TTimeStamp;
  SQLType: Integer;
begin
  with FArrayDesc do
    case array_desc_dtype of
      blr_text, blr_varying:
      begin
        L := 0;
        if array_desc_dtype = blr_varying then
          while (L < ElementSize) and (P[L] <> #0) do
            Inc(L)
        else
        begin
          // CHAR elements come padded to the length in bytes
          L := array_desc_length;
          while (L > 0) and (P[L - 1] = ' ') do
            Dec(L);
        end;
        SetString(S, P, L);
        if FDatabase.IsUnicodeConnect then
          {$IFDEF D2009+}
          Result := UTF8ToString(S)
          {$ELSE}
          Result := UTF8Decode(S)
          {$ENDIF}
        else
          Result := S;
      end;
      blr_short:
        if DescScale = 0 then
          Result := PSmallInt(P)^
        else
          Result := PSmallInt(P)^ / IntPower(10, -DescScale);
      blr_long:
        if DescScale = 0 then
          Result := PInteger(P)^
        else
          Result := PInteger(P)^ / IntPower(10, -DescScale);
      blr_int64:
        if DescScale = 0 then
          Result := PInt64(P)^
        else
        begin
          FBDecimalToBcd(Int64ToFBDecimal(PInt64(P)^, DescScale), Bcd);
          VarFMTBcdCreate(Result, Bcd);
        end;
      blr_int128, blr_dec64, blr_dec128:
      begin
        case array_desc_dtype of
          blr_int128:
            SQLType := SQL_INT128;
          blr_dec64:
            SQLType := SQL_DEC16;
        else
          SQLType := SQL_DEC34;
        end;
        // NaN, Infinity and values out of TBcd range are returned as Double, like fields
        if FBRawToBcd(SQLType, DescScale, P, Bcd) then
          VarFMTBcdCreate(Result, Bcd)
        else
          Result := FBRawToDouble(SQLType, DescScale, P);
      end;
      blr_float:
        Result := Double(PSingle(P)^);
      blr_double, blr_d_float:
        Result := PDouble(P)^;
      blr_sql_date:
      begin
        TS.Date := PISC_DATE(P)^ + IBBuffDateDelta;
        TS.Time := 0;
        Result := VarFromDateTime(TimeStampToDateTime(TS));
      end;
      blr_sql_time:
        Result := VarFromDateTime(PISC_TIME(P)^ / (MSecsPerDay * 10.0));
      blr_timestamp:
      begin
        TS.Date := PISC_QUAD(P)^.gds_quad_high + IBBuffDateDelta;
        TS.Time := PISC_QUAD(P)^.gds_quad_low div 10;
        Result := VarFromDateTime(TimeStampToDateTime(TS));
      end;
      blr_bool:
        Result := PByte(P)^ <> 0;
    else
      FIBErrorEx('Array %s.%s: element type %d is not supported',
        [FTableName, FFieldName, array_desc_dtype]);
    end;
end;

procedure TpFIBArray.WriteElement(const Value: Variant; P: PAnsiChar);
var
  S: AnsiString;
  I: Int64;
  TS: TTimeStamp;
  SQLType: Integer;
begin
  with FArrayDesc do
  begin
    // elements can't be NULL, NULL makes the element zero (blank for CHAR)
    if VarIsNull(Value) or VarIsEmpty(Value) then
    begin
      if array_desc_dtype = blr_text then
        FillChar(P^, array_desc_length, ' ')
      else
        FillChar(P^, ElementSize, 0);
      Exit;
    end;
    case array_desc_dtype of
      blr_text, blr_varying:
      begin
        if FDatabase.IsUnicodeConnect then
          S := UTF8Encode(VarToStr(Value))
        else
          S := AnsiString(VarToStr(Value));
        if Length(S) > array_desc_length then
          FIBErrorEx('Array %s.%s: the string "%s" is longer than %d bytes',
            [FTableName, FFieldName, VarToStr(Value), array_desc_length]);
        if S <> '' then
          Move(S[1], P^, Length(S));
        // CHAR is padded, VARCHAR is null terminated
        if array_desc_dtype = blr_text then
          FillChar(P[Length(S)], array_desc_length - Length(S), ' ')
        else
          FillChar(P[Length(S)], ElementSize - Length(S), 0);
      end;
      blr_short, blr_long, blr_int64:
      begin
        if not VariantToScaled(Value, DescScale, I) then
          ConversionError(Value);
        case array_desc_dtype of
          blr_short:
            if (I < Low(SmallInt)) or (I > High(SmallInt)) then
              ConversionError(Value)
            else
              PSmallInt(P)^ := I;
          blr_long:
            if (I < Low(Integer)) or (I > High(Integer)) then
              ConversionError(Value)
            else
              PInteger(P)^ := I;
        else
          PInt64(P)^ := I;
        end;
      end;
      blr_int128, blr_dec64, blr_dec128:
      begin
        case array_desc_dtype of
          blr_int128:
            SQLType := SQL_INT128;
          blr_dec64:
            SQLType := SQL_DEC16;
        else
          SQLType := SQL_DEC34;
        end;
        if not FBDecimalToRaw(VariantToDecimal(Value), SQLType, DescScale, P) then
          ConversionError(Value);
      end;
      blr_float:
        PSingle(P)^ := Value;
      blr_double, blr_d_float:
        PDouble(P)^ := Value;
      blr_sql_date:
        PISC_DATE(P)^ := DateTimeToTimeStamp(VarToDateTime(Value)).Date - IBBuffDateDelta;
      blr_sql_time:
        PISC_TIME(P)^ := DateTimeToTimeStamp(VarToDateTime(Value)).Time * 10;
      blr_timestamp:
      begin
        TS := DateTimeToTimeStamp(VarToDateTime(Value));
        PISC_QUAD(P)^.gds_quad_high := TS.Date - IBBuffDateDelta;
        PISC_QUAD(P)^.gds_quad_low := TS.Time * 10;
      end;
      blr_bool:
        PByte(P)^ := Ord(Boolean(Value));
    else
      FIBErrorEx('Array %s.%s: element type %d is not supported',
        [FTableName, FFieldName, array_desc_dtype]);
    end;
  end;
end;

procedure TpFIBArray.InitBuffer(Buffer: PAnsiChar);
begin
  if FArrayDesc.array_desc_dtype = blr_text then
    FillChar(Buffer^, ArraySize, ' ')
  else
    FillChar(Buffer^, ArraySize, 0);
end;

function TpFIBArray.BufferToVariant(Buffer: PAnsiChar): Variant;
var
  i: Integer;
  Bounds, Index: array of Integer;
  P: PAnsiChar;
begin
  SetLength(Bounds, DimensionCount * 2);
  SetLength(Index, DimensionCount);
  for i := 0 to DimensionCount - 1 do
  begin
    Bounds[i * 2] := Dimension[i].array_bound_lower;
    Bounds[i * 2 + 1] := Dimension[i].array_bound_upper;
    Index[i] := Dimension[i].array_bound_lower;
  end;
  Result := VarArrayCreate(Bounds, varVariant);
  P := Buffer;
  repeat
    VarArrayPut(Result, ReadElement(P), Index);
    Inc(P, ElementSize);
  until not NextIndex(Result, Index);
end;

procedure TpFIBArray.VariantToBuffer(const Value: Variant; Buffer: PAnsiChar);
var
  i, Count, MaxCount: Integer;
  Index: array of Integer;
  P: PAnsiChar;
begin
  if not VarIsArray(Value) then
    FIBErrorEx('Array %s.%s: the value is not an array', [FTableName, FFieldName]);
  if VarArrayDimCount(Value) <> DimensionCount then
    FIBErrorEx('Array %s.%s has %d dimension(s), the value has %d',
      [FTableName, FFieldName, DimensionCount, VarArrayDimCount(Value)]);
  // elements are written in row-major order from the start of the array, so only the first
  // dimension may be shorter than declared
  for i := 0 to DimensionCount - 1 do
  begin
    Count := VarArrayHighBound(Value, i + 1) - VarArrayLowBound(Value, i + 1) + 1;
    MaxCount := Dimension[i].array_bound_upper - Dimension[i].array_bound_lower + 1;
    if (Count > MaxCount) or ((i > 0) and (Count <> MaxCount)) then
      FIBErrorEx('Array %s.%s: dimension %d has %d element(s), the value has %d',
        [FTableName, FFieldName, i + 1, MaxCount, Count]);
  end;
  // elements missing in the value are blank
  InitBuffer(Buffer);
  SetLength(Index, DimensionCount);
  for i := 0 to DimensionCount - 1 do
    Index[i] := VarArrayLowBound(Value, i + 1);
  P := Buffer;
  repeat
    WriteElement(VarArrayGet(Value, Index), P);
    Inc(P, ElementSize);
  until not NextIndex(Value, Index);
end;

procedure TpFIBArray.CheckIndexes(const Indexes: array of Integer);
begin
  ElementDesc(Indexes);
end;

function TpFIBArray.GetBufferElement(Buffer: PAnsiChar; const Indexes: array of Integer): Variant;
begin
  Result := ReadElement(Buffer + ElementOffset(Indexes));
end;

procedure TpFIBArray.SetBufferElement(Buffer: PAnsiChar; const Indexes: array of Integer;
  const Value: Variant);
begin
  WriteElement(Value, Buffer + ElementOffset(Indexes));
end;

function TpFIBArray.GetSlice(ID: PISC_QUAD; Buffer: PAnsiChar;
  DBHandle: PISC_DB_HANDLE; TRHandle: PISC_TR_HANDLE): Integer;
begin
  Result := ArraySize;
  CheckStatus(FDatabase.ClientLibrary.isc_array_get_slice(StatusVector, DBHandle, TRHandle,
    ID, @FArrayDesc, Pointer(Buffer), @Result));
end;

procedure TpFIBArray.PutSlice(Buffer: PAnsiChar; var ID: TISC_QUAD;
  DBHandle: PISC_DB_HANDLE; TRHandle: PISC_TR_HANDLE);
var
  ArrSize: Integer;
begin
  ArrSize := ArraySize;
  // A new array: put_slice on a stored ID reuses the array the transaction loaded before
  // for that ID (Firebird keeps it until the transaction ends)
  ID.gds_quad_high := 0;
  ID.gds_quad_low := 0;
  CheckStatus(FDatabase.ClientLibrary.isc_array_put_slice(StatusVector, DBHandle, TRHandle,
    @ID, @FArrayDesc, Pointer(Buffer), @ArrSize));
end;

function TpFIBArray.GetStoredElement(ArrayID: TDataBuffer; const Desc: TISC_ARRAY_DESC;
  DBHandle: PISC_DB_HANDLE; TRHandle: PISC_TR_HANDLE): Variant;
var
  SliceSize: Integer;
  Buffer: TDataBuffer;
begin
  SliceSize := GetSliceSize(Desc);
  Buffer := nil;
  FIBAlloc(Buffer, 0, SliceSize + 1);
  try
    CheckStatus(FDatabase.ClientLibrary.isc_array_get_slice(StatusVector, DBHandle, TRHandle,
      PISC_QUAD(ArrayID), @Desc, Pointer(Buffer), @SliceSize));
    if SliceSize = 0 then
      Result := Null
    else
      Result := ReadElement(PAnsiChar(Buffer));
  finally
    FIBAlloc(Buffer, 0, 0);
  end;
end;

function TpFIBArray.GetArrayValues(ArrayID: TDataBuffer;
  DBHandle: PISC_DB_HANDLE; TRHandle: PISC_TR_HANDLE): Variant;
var
  Buffer: TDataBuffer;
begin
  Buffer := nil;
  FIBAlloc(Buffer, 0, ArraySize + 1);
  try
    if GetSlice(PISC_QUAD(ArrayID), PAnsiChar(Buffer), DBHandle, TRHandle) = 0 then
      Result := Null
    else
      Result := BufferToVariant(PAnsiChar(Buffer));
  finally
    FIBAlloc(Buffer, 0, 0);
  end;
end;

function TpFIBArray.GetElement(ArrayID: TDataBuffer; const Indexes: array of Integer;
  DBHandle: PISC_DB_HANDLE; TRHandle: PISC_TR_HANDLE): Variant;
begin
  Result := GetStoredElement(ArrayID, ElementDesc(Indexes), DBHandle, TRHandle);
end;

procedure TpFIBArray.SetArrayValue(const Value: Variant; var ArrayID: TDataBuffer;
  DBHandle: PISC_DB_HANDLE; TRHandle: PISC_TR_HANDLE);
var
  Buffer: TDataBuffer;
begin
  Buffer := nil;
  FIBAlloc(Buffer, 0, ArraySize + 1);
  try
    VariantToBuffer(Value, PAnsiChar(Buffer));
    PutSlice(PAnsiChar(Buffer), PISC_QUAD(ArrayID)^, DBHandle, TRHandle);
  finally
    FIBAlloc(Buffer, 0, 0);
  end;
end;
{$ENDIF}

end.
