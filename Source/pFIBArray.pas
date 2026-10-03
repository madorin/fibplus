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

unit pFIBArray;

{$I FIBPlus.inc}

interface

uses
  SysUtils, Classes, ibase, IB_Intf, ib_externals, DB, fib, FIBDatabase,
  StdFuncs,
  FIBPlatforms, Variants;

{$IFDEF SUPPORT_ARRAY_FIELD}

type
  // Not TISC_ARRAY_BOUND: its 16-bit bounds can't hold every INTEGER bound of the column
  TArrayBound = record
    Lower, Upper: Integer;
  end;

  TArrayBounds = array of TArrayBound;

  // Array column through slices with an own SDL: full names, not cut like in ISC_ARRAY_DESC
  TpFIBArray = class
  private
    FDatabase: TFIBDatabase;
    FConnectionSerial: Integer;
    FTableName: string;
    FFieldName: string;
    FArrayType: TFieldType;
    // Element as transferred in a slice: BLR type, length in bytes and scale
    FElementType: Integer;
    FElementLength: Integer;
    FElementScale: Integer;
    // of string elements, as fields get it; -1 (InterBase): not in the SDL
    FElementCharSetID: Integer;
    FElementCodePage: Word;
    FBounds: TArrayBounds;
    // SDL up to the bounds: element type and names, the same for every slice
    FSDLHeader: AnsiString;
    FArraySDL: AnsiString;
    procedure LoadMetadata(Transaction: TFIBTransaction);
    function ElementFieldType: TFieldType;
    function SDLCodePage: Word;
    function SDLName(const Name: string): AnsiString;
    function SDLHeader: AnsiString;
    function SliceSDL(const Bounds: TArrayBounds): AnsiString;
    function SliceSize(const Bounds: TArrayBounds): Integer;
    function ElementSize: Integer;
    function CharPad: AnsiChar;
    function ElementBounds(const Indexes: array of Integer): TArrayBounds;
    function ElementOffset(const Indexes: array of Integer): Integer;
    function ReadElement(P: PAnsiChar): Variant;
    procedure WriteElement(const Value: Variant; P: PAnsiChar);
    procedure ConversionError(const Value: Variant);
    function ReadSlice(ID: PISC_QUAD; const SDL: AnsiString; Buffer: PAnsiChar;
      BufferSize: Integer; DBHandle: PISC_DB_HANDLE;
      TRHandle: PISC_TR_HANDLE): Integer;
    procedure CheckStatus(Status: ISC_STATUS);
    function GetDimensionCount: Integer;
    function GetDimension(Index: Integer): TISC_ARRAY_BOUND;
    function GetArraySize: Integer;
    function GetScale: Byte;
  public
    constructor Create(Database: TFIBDatabase; Transaction: TFIBTransaction; const ATableName, AFieldName: string);
    // Read for this column on the current connection
    function Matches(Database: TFIBDatabase; const ATableName, AFieldName: string): Boolean;
    // for FIBQuery: the array with the ID in ArrayID
    function GetArrayValues(ArrayID: TDataBuffer; DBHandle: PISC_DB_HANDLE; TRHandle: PISC_TR_HANDLE): Variant;
    function GetElement(ArrayID: TDataBuffer; const Indexes: array of Integer; DBHandle: PISC_DB_HANDLE; TRHandle: PISC_TR_HANDLE): Variant;
    procedure SetArrayValue(const Value: Variant; var ArrayID: TDataBuffer; DBHandle: PISC_DB_HANDLE; TRHandle: PISC_TR_HANDLE);
    // Whole array in a buffer of ArraySize bytes, with the layout of the slice calls
    procedure InitBuffer(Buffer: PAnsiChar);
    function BufferToVariant(Buffer: PAnsiChar): Variant;
    procedure VariantToBuffer(const Value: Variant; Buffer: PAnsiChar);
    // Raises an error when Indexes don't address an element
    procedure CheckIndexes(const Indexes: array of Integer);
    function GetBufferElement(Buffer: PAnsiChar; const Indexes: array of Integer): Variant;
    procedure SetBufferElement(Buffer: PAnsiChar; const Indexes: array of Integer; const Value: Variant);
    // Reads the array with ID into Buffer, returns 0 for a NULL array
    function GetSlice(ID: PISC_QUAD; Buffer: PAnsiChar; DBHandle: PISC_DB_HANDLE; TRHandle: PISC_TR_HANDLE): Integer;
    // Writes Buffer as a new array, ID gets its (temporary) ID
    procedure PutSlice(Buffer: PAnsiChar; var ID: TISC_QUAD; DBHandle: PISC_DB_HANDLE; TRHandle: PISC_TR_HANDLE);

    property ArrayType: TFieldType read FArrayType;
    property TableName: string read FTableName;
    property FieldName: string read FFieldName;
    property DimensionCount: Integer read GetDimensionCount;
    property Dimension[Index: Integer]: TISC_ARRAY_BOUND read GetDimension;
    property ArraySize: Integer read GetArraySize;
    property Scale: Byte read GetScale;
  end;
{$ENDIF}

implementation

{$IFDEF SUPPORT_ARRAY_FIELD}

uses
  StrUtil, Math, FMTBcd, FIBTypes, FIBQuery, FIBCharSets;

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
    varShortInt, varByte, varSmallint, varWord, varInteger, varLongWord, varInt64: Result := Int64ToFBDecimal(Value);
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

{ TpFIBArray }

constructor TpFIBArray.Create(Database: TFIBDatabase; Transaction: TFIBTransaction; const ATableName, AFieldName: string);
begin
  inherited Create;
  FDatabase := Database;
  FConnectionSerial := Database.ConnectionSerial;
  FTableName := ATableName;
  FFieldName := AFieldName;
  LoadMetadata(Transaction);
  FArrayType := ElementFieldType;
  FSDLHeader := SDLHeader;
  FArraySDL := SliceSDL(FBounds);
end;

function TpFIBArray.Matches(Database: TFIBDatabase; const ATableName, AFieldName: string): Boolean;
begin
  Result := (FConnectionSerial = Database.ConnectionSerial) and (FTableName = ATableName) and
    (FFieldName = AFieldName);
end;

procedure TpFIBArray.LoadMetadata(Transaction: TFIBTransaction);
var
  Query: TFIBQuery;
  CharacterLength, ColumnCharSetID, AttachmentCharSetID: Integer;
begin
  // Not cached: a cached query takes the transaction's database; no COALESCE (InterBase, FB 1.0)
  Query := TFIBQuery.Create(nil);
  try
    Query.Database := FDatabase;
    Query.Transaction := Transaction;
    Query.SQL.Text := 'select f.RDB$FIELD_TYPE, f.RDB$FIELD_LENGTH, f.RDB$FIELD_SCALE, f.RDB$CHARACTER_LENGTH, ' +
      'f.RDB$CHARACTER_SET_ID, d.RDB$LOWER_BOUND, d.RDB$UPPER_BOUND ' + 'from RDB$RELATION_FIELDS rf ' +
      'join RDB$FIELDS f on f.RDB$FIELD_NAME = rf.RDB$FIELD_SOURCE ' +
      'join RDB$FIELD_DIMENSIONS d on d.RDB$FIELD_NAME = f.RDB$FIELD_NAME ' +
      'where rf.RDB$RELATION_NAME = :RELATION_NAME and rf.RDB$FIELD_NAME = :FIELD_NAME ' +
      'order by d.RDB$DIMENSION';
    Query.ParamByName('RELATION_NAME').AsString := FTableName;
    Query.ParamByName('FIELD_NAME').AsString := FFieldName;
    Query.ExecQuery;
    if Query.Eof then
      FIBErrorEx('Array column %s.%s not found', [FTableName, FFieldName]);
    FElementType := Query.Fields[0].AsInteger;
    FElementLength := Query.Fields[1].AsInteger;
    FElementScale := Query.Fields[2].AsInteger;
    if Query.Fields[3].IsNull then
      CharacterLength := FElementLength
    else
      CharacterLength := Query.Fields[3].AsInteger;
    ColumnCharSetID := Query.Fields[4].AsInteger;
    SetLength(FBounds, 0);
    while not Query.Eof do
    begin
      SetLength(FBounds, Length(FBounds) + 1);
      FBounds[High(FBounds)].Lower := Query.Fields[5].AsInteger;
      FBounds[High(FBounds)].Upper := Query.Fields[6].AsInteger;
      Query.Next;
    end;
    Query.Close;
    if FElementType in [blr_text, blr_varying] then
    begin
      // The server converts to the attachment charset, except NONE and OCTETS
      AttachmentCharSetID := FDatabase.Capabilities.AttachmentCharSetID;
      if AttachmentCharSetID < 0 then
        FElementCharSetID := -1
      else if (AttachmentCharSetID = 0) or (ColumnCharSetID in [0, OCTETS_CHARSET_ID]) then
        FElementCharSetID := ColumnCharSetID
      else
        FElementCharSetID := AttachmentCharSetID;
      if FElementCharSetID >= 0 then
        FElementCodePage := FDatabase.Capabilities.TextCodePage(FElementCharSetID)
      else if FDatabase.IsUnicodeConnect then
        FElementCodePage := FIBCodePageUTF8
      else
        FElementCodePage := FIBCodePageSystem;
      // The field length is in bytes of the column charset
      if (FElementCharSetID >= 0) and (FElementCharSetID <> ColumnCharSetID) then
      begin
        Query.SQL.Text := 'select RDB$BYTES_PER_CHARACTER from RDB$CHARACTER_SETS ' +
          'where RDB$CHARACTER_SET_ID = :CHARSET_ID';
        Query.ParamByName('CHARSET_ID').AsInteger := AttachmentCharSetID;
        Query.ExecQuery;
        if not Query.Eof and not Query.Fields[0].IsNull then
          FElementLength := CharacterLength * Query.Fields[0].AsInteger;
        Query.Close;
      end;
    end;
  finally
    Query.Free;
  end;
  // Elements WITH TIME ZONE are transferred as local time of the session time zone,
  // the server converts them
  case FElementType of
    blr_timestamp_tz, blr_ex_timestamp_tz:
      begin
        FElementType := blr_timestamp;
        FElementLength := SizeOf(TISC_QUAD);
      end;
    blr_sql_time_tz, blr_ex_time_tz:
      begin
        FElementType := blr_sql_time;
        FElementLength := SizeOf(ISC_TIME);
      end;
  end;
end;

function TpFIBArray.ElementFieldType: TFieldType;
begin
  case FElementType of
    blr_text, blr_varying: Result := ftString;
    blr_short:
      if FElementScale = 0 then
        Result := ftSmallint
      else
        Result := ftBCD;
    blr_long:
      if FElementScale = 0 then
        Result := ftInteger
      else
        Result := ftBCD;
    blr_int64:
      if FElementScale = 0 then
        Result := ftLargeint
      else
        Result := ftBCD;
    blr_int128, blr_dec64, blr_dec128: Result := ftFMTBcd;
    blr_float, blr_double, blr_d_float: Result := ftFloat;
    blr_timestamp: Result := ftDateTime;
    blr_sql_date: Result := ftDate;
    blr_sql_time: Result := ftTime;
    blr_bool: Result := ftBoolean;
  else
    Result := ftUnknown;
  end;
end;

// SDL names are compared with the metadata unconverted: UTF-8 since Firebird 2.5
function TpFIBArray.SDLCodePage: Word;
begin
  if FDatabase.IsUnicodeConnect or FDatabase.IsFirebirdConnect and ((FDatabase.ServerMajorVersion > 2) or
    (FDatabase.ServerMajorVersion = 2) and (FDatabase.ServerMinorVersion >= 5)) then
    Result := FIBCodePageUTF8
  else
    Result := FDatabase.Capabilities.CodePage;
end;

function TpFIBArray.SDLName(const Name: string): AnsiString;
begin
  Result := EncodeString(Name, SDLCodePage);
  if Length(Result) > 255 then
    FIBErrorEx('Array %s.%s: the name %s is too long', [FTableName, FFieldName, Name]);
end;

// As gen_sdl of the client, but with the full names: writes look the column up by them
function TpFIBArray.SDLHeader: AnsiString;
var
  RelationName, FieldName: AnsiString;
begin
  RelationName := SDLName(FTableName);
  FieldName := SDLName(FFieldName);
  Result := AnsiChar(isc_sdl_version1) + AnsiChar(isc_sdl_struct) + AnsiChar(1);
  case FElementType of
    blr_short, blr_long, blr_int64, blr_quad, blr_int128:
      Result := Result + AnsiChar(FElementType) + AnsiChar(FElementScale and $FF);
    blr_text, blr_cstring, blr_varying:
      begin
        // Without the charset the server converts NONE and OCTETS too ("Malformed string" in UTF8)
        if FElementCharSetID < 0 then
          Result := Result + AnsiChar(FElementType)
        else
        begin
          case FElementType of
            blr_text: Result := Result + AnsiChar(blr_text2);
            blr_cstring: Result := Result + AnsiChar(blr_cstring2);
          else
            Result := Result + AnsiChar(blr_varying2);
          end;
          Result := Result + AnsiChar(FElementCharSetID and $FF) + AnsiChar((FElementCharSetID shr 8) and $FF);
        end;
        Result := Result + AnsiChar(FElementLength and $FF) + AnsiChar((FElementLength shr 8) and $FF);
      end;
  else
    Result := Result + AnsiChar(FElementType);
  end;
  Result := Result + AnsiChar(isc_sdl_relation) + AnsiChar(Length(RelationName))
    + RelationName + AnsiChar(isc_sdl_field) + AnsiChar(Length(FieldName)) + FieldName;
end;

function TpFIBArray.SliceSDL(const Bounds: TArrayBounds): AnsiString;
var
  SDL: AnsiString;

  procedure AddByte(Value: Integer);
  begin
    SDL := SDL + AnsiChar(Value and $FF);
  end;

  procedure AddLiteral(Value: Integer);
  begin
    if (Value >= Low(ShortInt)) and (Value <= High(ShortInt)) then
    begin
      AddByte(isc_sdl_tiny_integer);
      AddByte(Value);
    end
    else if (Value >= Low(SmallInt)) and (Value <= High(SmallInt)) then
    begin
      AddByte(isc_sdl_short_integer);
      AddByte(Value);
      AddByte(Value shr 8);
    end
    else
    begin
      AddByte(isc_sdl_long_integer);
      AddByte(Value);
      AddByte(Value shr 8);
      AddByte(Value shr 16);
      AddByte(Value shr 24);
    end;
  end;

var
  i: Integer;
begin
  SDL := FSDLHeader;
  for i := 0 to High(Bounds) do
  begin
    if Bounds[i].Lower = 1 then
    begin
      AddByte(isc_sdl_do1);
      AddByte(i);
    end
    else
    begin
      AddByte(isc_sdl_do2);
      AddByte(i);
      AddLiteral(Bounds[i].Lower);
    end;
    AddLiteral(Bounds[i].Upper);
  end;
  AddByte(isc_sdl_element);
  AddByte(1);
  AddByte(isc_sdl_scalar);
  AddByte(0);
  AddByte(Length(Bounds));
  for i := 0 to High(Bounds) do
  begin
    AddByte(isc_sdl_variable);
    AddByte(i);
  end;
  AddByte(isc_sdl_eoc);
  Result := SDL;
end;

function TpFIBArray.SliceSize(const Bounds: TArrayBounds): Integer;
var
  i: Integer;
begin
  Result := ElementSize;
  for i := 0 to High(Bounds) do
    Result := Result * (Bounds[i].Upper - Bounds[i].Lower + 1);
end;

// Size of an element in a slice, VARCHAR elements are null terminated strings
function TpFIBArray.ElementSize: Integer;
begin
  Result := FElementLength;
  if FElementType = blr_varying then
    Inc(Result, 2);
end;

function TpFIBArray.CharPad: AnsiChar;
begin
  if FElementCharSetID = OCTETS_CHARSET_ID then
    Result := #0
  else
    Result := ' ';
end;

function TpFIBArray.ElementBounds(const Indexes: array of Integer): TArrayBounds;
var
  i: Integer;
begin
  CheckIndexes(Indexes);
  SetLength(Result, DimensionCount);
  for i := 0 to DimensionCount - 1 do
  begin
    Result[i].Lower := Indexes[i];
    Result[i].Upper := Indexes[i];
  end;
end;

// Offset of the element at Indexes in the buffer of the whole array (row-major)
function TpFIBArray.ElementOffset(const Indexes: array of Integer): Integer;
var
  i: Integer;
begin
  CheckIndexes(Indexes);
  Result := 0;
  for i := 0 to DimensionCount - 1 do
    Result := Result * (FBounds[i].Upper - FBounds[i].Lower + 1) + Indexes[i] - FBounds[i].Lower;
  Result := Result * ElementSize;
end;

procedure TpFIBArray.CheckIndexes(const Indexes: array of Integer);
var
  i: Integer;
begin
  if Length(Indexes) <> DimensionCount then
    FIBErrorEx('Array %s.%s has %d dimension(s), %d index(es) given',
      [FTableName, FFieldName, DimensionCount, Length(Indexes)]);
  for i := 0 to DimensionCount - 1 do
    if (Indexes[i] < FBounds[i].Lower) or (Indexes[i] > FBounds[i].Upper) then
      FIBErrorEx
        ('Array %s.%s: index %d is out of the bounds %d:%d of dimension %d',
          [FTableName, FFieldName, Indexes[i], FBounds[i].Lower, FBounds[i].Upper, i + 1]);
end;

function TpFIBArray.GetDimensionCount: Integer;
begin
  Result := Length(FBounds);
end;

function TpFIBArray.GetDimension(Index: Integer): TISC_ARRAY_BOUND;
begin
  if (Index < 0) or (Index >= DimensionCount) then
    FIBError(feWrongDimension, [Index, FTableName + '.' + FFieldName]);
  if (FBounds[Index].Lower < Low(SmallInt)) or (FBounds[Index].Upper > High(SmallInt)) then
    FIBErrorEx
      ('Array %s.%s: the bounds %d:%d of dimension %d don''t fit TISC_ARRAY_BOUND',
        [FTableName, FFieldName, FBounds[Index].Lower, FBounds[Index].Upper, Index + 1]);
  Result.array_bound_lower := FBounds[Index].Lower;
  Result.array_bound_upper := FBounds[Index].Upper;
end;

function TpFIBArray.GetArraySize: Integer;
begin
  Result := SliceSize(FBounds);
end;

function TpFIBArray.GetScale: Byte;
begin
  Result := -FElementScale;
end;

procedure TpFIBArray.ConversionError(const Value: Variant);
begin
  FIBErrorEx('Array %s.%s: can''t convert "%s" to the element type', [FTableName, FFieldName, VarToStr(Value)]);
end;

function TpFIBArray.ReadElement(P: PAnsiChar): Variant;
var
  S: AnsiString;
  L: Integer;
  Bcd: TBcd;
  TS: TTimeStamp;
  SQLType: Integer;
begin
  case FElementType of
    blr_text, blr_varying:
      begin
        L := 0;
        if FElementType = blr_varying then
          while (L < ElementSize) and (P[L] <> #0) do
            Inc(L)
        else
        begin
          // CHAR padded to the length in bytes; OCTETS with #0, kept as in fields
          L := FElementLength;
          if FElementCharSetID <> OCTETS_CHARSET_ID then
            while (L > 0) and (P[L - 1] = ' ') do
              Dec(L);
        end;
        SetString(S, P, L);
{$IFDEF D2009+}
        Result := DecodeString(S, FElementCodePage);
{$ELSE}
        if FElementCodePage = FIBCodePageUTF8 then
          Result := UTF8Decode(S)
        else
          Result := S;
{$ENDIF}
      end;
    blr_short:
      if FElementScale = 0 then
        Result := PSmallInt(P)^
      else
        Result := PSmallInt(P)^ / IntPower(10, -FElementScale);
    blr_long:
      if FElementScale = 0 then
        Result := PInteger(P)^
      else
        Result := PInteger(P)^ / IntPower(10, -FElementScale);
    blr_int64:
      if FElementScale = 0 then
        Result := PInt64(P)^
      else
      begin
        FBDecimalToBcd(Int64ToFBDecimal(PInt64(P)^, FElementScale), Bcd);
        VarFMTBcdCreate(Result, Bcd);
      end;
    blr_int128, blr_dec64, blr_dec128:
      begin
        case FElementType of
          blr_int128: SQLType := SQL_INT128;
          blr_dec64: SQLType := SQL_DEC16;
        else
          SQLType := SQL_DEC34;
        end;
        // NaN, Infinity and values out of TBcd range are returned as Double, like fields
        if FBRawToBcd(SQLType, FElementScale, P, Bcd) then
          VarFMTBcdCreate(Result, Bcd)
        else
          Result := FBRawToDouble(SQLType, FElementScale, P);
      end;
    blr_float: Result := Double(PSingle(P)^);
    blr_double, blr_d_float: Result := PDouble(P)^;
    blr_sql_date:
      begin
        TS.Date := PISC_DATE(P)^ + IBBuffDateDelta;
        TS.Time := 0;
        Result := VarFromDateTime(TimeStampToDateTime(TS));
      end;
    blr_sql_time: Result := VarFromDateTime(PISC_TIME(P)^ / (MSecsPerDay * 10.0));
    blr_timestamp:
      begin
        TS.Date := PISC_QUAD(P)^.gds_quad_high + IBBuffDateDelta;
        TS.Time := PISC_QUAD(P)^.gds_quad_low div 10;
        Result := VarFromDateTime(TimeStampToDateTime(TS));
      end;
    blr_bool: Result := PByte(P)^ <> 0;
  else
    FIBErrorEx('Array %s.%s: element type %d is not supported', [FTableName, FFieldName, FElementType]);
  end;
end;

procedure TpFIBArray.WriteElement(const Value: Variant; P: PAnsiChar);
var
  S: AnsiString;
  i: Int64;
  TS: TTimeStamp;
  SQLType: Integer;
begin
  // elements can't be NULL, NULL makes the element zero (blank for CHAR)
  if VarIsNull(Value) or VarIsEmpty(Value) then
  begin
    if FElementType = blr_text then
      FillChar(P^, FElementLength, CharPad)
    else
      FillChar(P^, ElementSize, 0);
    Exit;
  end;
  case FElementType of
    blr_text, blr_varying:
      begin
        S := EncodeString(VarToStr(Value), FElementCodePage);
        if Length(S) > FElementLength then
          FIBErrorEx('Array %s.%s: the string "%s" is longer than %d bytes',
            [FTableName, FFieldName, VarToStr(Value), FElementLength]);
        if S <> '' then
          Move(S[1], P^, Length(S));
        // CHAR is padded, VARCHAR is null terminated
        if FElementType = blr_text then
          FillChar(P[Length(S)], FElementLength - Length(S), CharPad)
        else
          FillChar(P[Length(S)], ElementSize - Length(S), 0);
      end;
    blr_short, blr_long, blr_int64:
      begin
        if not VariantToScaled(Value, FElementScale, i) then
          ConversionError(Value);
        case FElementType of
          blr_short:
            if (i < Low(SmallInt)) or (i > High(SmallInt)) then
              ConversionError(Value)
            else
              PSmallInt(P)^ := i;
          blr_long:
            if (i < Low(Integer)) or (i > High(Integer)) then
              ConversionError(Value)
            else
              PInteger(P)^ := i;
        else
          PInt64(P)^ := i;
        end;
      end;
    blr_int128, blr_dec64, blr_dec128:
      begin
        case FElementType of
          blr_int128: SQLType := SQL_INT128;
          blr_dec64: SQLType := SQL_DEC16;
        else
          SQLType := SQL_DEC34;
        end;
        if not FBDecimalToRaw(VariantToDecimal(Value), SQLType, FElementScale, P) then
          ConversionError(Value);
      end;
    blr_float: PSingle(P)^ := Value;
    blr_double, blr_d_float: PDouble(P)^ := Value;
    blr_sql_date: PISC_DATE(P)^ := DateTimeToTimeStamp(VarToDateTime(Value)).Date - IBBuffDateDelta;
    blr_sql_time: PISC_TIME(P)^ := DateTimeToTimeStamp(VarToDateTime(Value)).Time * 10;
    blr_timestamp:
      begin
        TS := DateTimeToTimeStamp(VarToDateTime(Value));
        PISC_QUAD(P)^.gds_quad_high := TS.Date - IBBuffDateDelta;
        PISC_QUAD(P)^.gds_quad_low := TS.Time * 10;
      end;
    blr_bool: PByte(P)^ := Ord(Boolean(Value));
  else
    FIBErrorEx('Array %s.%s: element type %d is not supported', [FTableName, FFieldName, FElementType]);
  end;
end;

procedure TpFIBArray.InitBuffer(Buffer: PAnsiChar);
begin
  if FElementType = blr_text then
    FillChar(Buffer^, ArraySize, CharPad)
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
    Bounds[i * 2] := FBounds[i].Lower;
    Bounds[i * 2 + 1] := FBounds[i].Upper;
    Index[i] := FBounds[i].Lower;
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
    MaxCount := FBounds[i].Upper - FBounds[i].Lower + 1;
    if (Count > MaxCount) or ((i > 0) and (Count <> MaxCount)) then
      FIBErrorEx
        ('Array %s.%s: dimension %d has %d element(s), the value has %d',
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

function TpFIBArray.GetBufferElement(Buffer: PAnsiChar; const Indexes: array of Integer): Variant;
begin
  Result := ReadElement(Buffer + ElementOffset(Indexes));
end;

procedure TpFIBArray.SetBufferElement(Buffer: PAnsiChar; const Indexes: array of Integer; const Value: Variant);
begin
  WriteElement(Value, Buffer + ElementOffset(Indexes));
end;

procedure TpFIBArray.CheckStatus(Status: ISC_STATUS);
begin
  if Status > 0 then
    IbError(FDatabase.ClientLibrary, Self);
end;

// Returns the length read, 0 for a NULL array
function TpFIBArray.ReadSlice(ID: PISC_QUAD; const SDL: AnsiString;
  Buffer: PAnsiChar; BufferSize: Integer; DBHandle: PISC_DB_HANDLE;
  TRHandle: PISC_TR_HANDLE): Integer;
var
  ReturnLength: ISC_LONG;
begin
  ReturnLength := 0;
  CheckStatus(FDatabase.ClientLibrary.isc_get_slice(StatusVector, DBHandle,
    TRHandle, ID, Length(SDL), PAnsiChar(SDL), 0, nil, BufferSize, Pointer(Buffer), @ReturnLength));
  Result := ReturnLength;
end;

function TpFIBArray.GetSlice(ID: PISC_QUAD; Buffer: PAnsiChar; DBHandle: PISC_DB_HANDLE; TRHandle: PISC_TR_HANDLE): Integer;
begin
  Result := ReadSlice(ID, FArraySDL, Buffer, ArraySize, DBHandle, TRHandle);
end;

procedure TpFIBArray.PutSlice(Buffer: PAnsiChar; var ID: TISC_QUAD; DBHandle: PISC_DB_HANDLE; TRHandle: PISC_TR_HANDLE);
begin
  // A new array: put_slice on a stored ID reuses the array the transaction loaded before
  // for that ID (Firebird keeps it until the transaction ends)
  ID.gds_quad_high := 0;
  ID.gds_quad_low := 0;
  CheckStatus(FDatabase.ClientLibrary.isc_put_slice(StatusVector, DBHandle,
    TRHandle, @ID, Length(FArraySDL), PAnsiChar(FArraySDL), 0, nil, ArraySize, Pointer(Buffer)));
end;

function TpFIBArray.GetArrayValues(ArrayID: TDataBuffer; DBHandle: PISC_DB_HANDLE; TRHandle: PISC_TR_HANDLE): Variant;
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

function TpFIBArray.GetElement(ArrayID: TDataBuffer;
  const Indexes: array of Integer; DBHandle: PISC_DB_HANDLE;
  TRHandle: PISC_TR_HANDLE): Variant;
var
  SDL: AnsiString;
  Buffer: TDataBuffer;
begin
  SDL := SliceSDL(ElementBounds(Indexes));
  Buffer := nil;
  FIBAlloc(Buffer, 0, ElementSize + 1);
  try
    if ReadSlice(PISC_QUAD(ArrayID), SDL, PAnsiChar(Buffer), ElementSize, DBHandle, TRHandle) = 0 then
      Result := Null
    else
      Result := ReadElement(PAnsiChar(Buffer));
  finally
    FIBAlloc(Buffer, 0, 0);
  end;
end;

procedure TpFIBArray.SetArrayValue(const Value: Variant; var ArrayID: TDataBuffer; DBHandle: PISC_DB_HANDLE; TRHandle: PISC_TR_HANDLE);
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
