{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ InterBase databases                                           }
{                                                               }
{  Handling of Firebird specific data types. Currently the      }
{  types introduced in Firebird 4: INT128, DECFLOAT(16/34),     }
{  TIME WITH TIME ZONE and TIMESTAMP WITH TIME ZONE.            }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit FIBTypes;

interface

{$I FIBPlus.inc}

uses
  SysUtils, Math, FMTBcd, ibase;

type
  TFBDecimalKind = (dkFinite, dkInfinity, dkNaN, dkSignalingNaN);

  // Unpacked decimal number: (-1)^Negative * Coefficient * 10^Exponent
  TFBDecimal = record
    Kind: TFBDecimalKind;
    Negative: Boolean;
    Coefficient: string; // decimal digits, no leading zeros, '0' for zero
    Exponent: Integer;
  end;

const
  FBDec16Digits  = 16;
  FBDec34Digits  = 34;
  FBInt128Digits = 39;

  // Time zone IDs
  FBGmtZoneID       = 65535;
  FBOffsetZoneBias  = 1439; // offset zone ID = offset in minutes + 1439
  FBMaxOffsetZoneID = 2 * FBOffsetZoneBias;
  // Not a Firebird ID. Marks a value without an explicit time zone,
  // which is sent to the server as local time of the session time zone.
  FBSessionZoneID = 32768;

  // Firebird uses this date for the conversions of TIME WITH TIME ZONE
  // in region based time zones
  FBTimeTZBaseDate = 58849; // 2020-01-01

  { Generic decimal routines }

function FBDecimalIsZero(const Value: TFBDecimal): Boolean;
procedure FBDecimalRound(var Value: TFBDecimal; DropDigits: Integer);
function FBDecimalRescale(const Value: TFBDecimal; Exponent: Integer): TFBDecimal;
function StrToFBDecimal(const S: string; out Res: TFBDecimal): Boolean;
// Scientific notation like the server output, e.g. 1.5, 1E+3, 1.23E-10
function FBDecimalToStr(const Value: TFBDecimal; DecSep: Char = '.'): string;
// Plain notation without an exponent
function FBDecimalToPlainStr(const Value: TFBDecimal; DecSep: Char = '.'): string;
function FBDecimalToBcd(const Value: TFBDecimal; out Res: TBcd): Boolean;
function BcdToFBDecimal(const Value: TBcd): TFBDecimal;
function FBDecimalToDouble(const Value: TFBDecimal): Double;
function DoubleToFBDecimal(Value: Double): TFBDecimal;
// Truncates the fractional part
function FBDecimalToInt64(const Value: TFBDecimal; out Res: Int64): Boolean;
function Int64ToFBDecimal(Value: Int64; Exponent: Integer = 0): TFBDecimal;

{ INT128 }

function Int128IsNegative(const Value: TFB_I128): Boolean;
function Int128ToFBDecimal(const Value: TFB_I128; Scale: Integer): TFBDecimal;
// Rounds the value to Scale digits. Returns False on overflow.
function FBDecimalToInt128(const Value: TFBDecimal; Scale: Integer; out Res: TFB_I128): Boolean;
function Int128ToStr(const Value: TFB_I128; Scale: Integer; DecSep: Char = '.'): string;

{ DECFLOAT }

function Dec16ToFBDecimal(const Value: TFB_DEC16): TFBDecimal;
function Dec34ToFBDecimal(const Value: TFB_DEC34): TFBDecimal;
// Rounds the value to the precision of the type. Returns False on overflow.
function FBDecimalToDec16(const Value: TFBDecimal; out Res: TFB_DEC16): Boolean;
function FBDecimalToDec34(const Value: TFBDecimal; out Res: TFB_DEC34): Boolean;

{ INT128, DECFLOAT(16) and DECFLOAT(34) in the server format, SQLType is one of
  SQL_INT128, SQL_DEC16, SQL_DEC34 and Scale is used for SQL_INT128 only }

function FBDecimalFromRaw(SQLType, Scale: Integer; Data: Pointer): TFBDecimal;
// Fast path without strings. Returns False for NaN, Infinity and values
// which do not fit TBcd (64 digits, scale up to 63).
function FBRawToBcd(SQLType, Scale: Integer; Data: Pointer; out Res: TBcd): Boolean;
// Truncates the fractional part. Returns False for NaN, Infinity and on overflow.
function FBRawToInt64(SQLType, Scale: Integer; Data: Pointer; out Res: Int64): Boolean;
// Value * 10^-NewScale rounded half away from zero, e.g. NewScale = -4 for Currency.
// Returns False for NaN, Infinity and on overflow.
function FBRawToScaledInt64(SQLType, Scale: Integer; Data: Pointer; NewScale: Integer; out Res: Int64): Boolean;
function FBRawToDouble(SQLType, Scale: Integer; Data: Pointer): Double;
// DECFLOAT values drop the padding zeros of the fraction (7.250 -> 7.25),
// INT128 values are rounded to Scale. Returns False on overflow.
function FBDecimalToRaw(const Value: TFBDecimal; SQLType, Scale: Integer; Data: Pointer): Boolean;
// Same as FBDecimalToRaw(BcdToFBDecimal(Value), ...) without strings
function FBBcdToRaw(const Value: TBcd; SQLType, Scale: Integer; Data: Pointer): Boolean;

{ TBcd }

// Value = Res * 10^Scale. Returns False if Res does not fit Int64,
// Scale is set in any case.
function BcdToInt64Scaled(const Value: TBcd; out Res: Int64; out Scale: Integer): Boolean;

{ Time zones }

function FBIsOffsetZone(ZoneID: Word): Boolean;
function FBOffsetToZoneID(OffsetMinutes: Integer): Word;
function FBZoneIDToOffset(ZoneID: Word): Integer;
// Offset of an offset zone, 0 for region zones (resolved only by the server)
function FBKnownZoneOffset(ZoneID: Word): Integer;
function FBFormatZoneOffset(OffsetMinutes: Integer): string;
// '+02:00' for offset zones, region name for region zones, '' if unknown
function FBTimeZoneName(ZoneID: Word): string;
function FBTimeZoneIDByName(const Name: string; out ZoneID: Word): Boolean;

{ Date and time }

function FBTimeStampToDateTime(const Value: TISC_TIMESTAMP): TDateTime;

{ Values of TIME/TIMESTAMP WITH TIME ZONE in the dataset record cache.
  The cache keeps the extended form fetched from the server. When a local time
  is assigned in a region zone (or without a zone) the UTC fields hold the local
  time and ext_offset is FBUnresolvedOffset: the server resolves it on post. }

const
  FBUnresolvedOffset = $7FFF;

  // Local time in msecs since 0001-01-01, TDateTimeRec.DateTime format
function FBTimeStampTZToMSecs(const Value: TISC_TIMESTAMP_TZ_EX): Double;
// Keeps time_zone, sets the other fields
procedure FBMSecsToTimeStampTZ(const MSecs: Double; var Value: TISC_TIMESTAMP_TZ_EX);
// Local time in msecs since midnight, TDateTimeRec.Time format
function FBTimeTZToMSecs(const Value: TISC_TIME_TZ_EX): Integer;
procedure FBMSecsToTimeTZ(MSecs: Integer; var Value: TISC_TIME_TZ_EX);

function LocalDecimalSeparator: Char;

implementation

{$I FIBTimeZones.inc}

function LocalDecimalSeparator: Char;
begin
  Result := {$IFDEF D_XE3}FormatSettings.{$ENDIF}DecimalSeparator;
end;

{ Generic decimal routines }

procedure StripLeadingZeros(var S: string);
var
  i: Integer;
begin
  i := 1;
  while (i < Length(S)) and (S[i] = '0') do
    Inc(i);
  if i > 1 then
    Delete(S, 1, i - 1);
  if S = '' then
    S := '0';
end;

function FBDecimalIsZero(const Value: TFBDecimal): Boolean;
begin
  Result := (Value.Kind = dkFinite) and (Value.Coefficient = '0');
end;

// Removes DropDigits least significant digits, rounding half away from zero
procedure FBDecimalRound(var Value: TFBDecimal; DropDigits: Integer);
var
  L, i: Integer;
  RoundUp: Boolean;
begin
  if (DropDigits <= 0) or (Value.Kind <> dkFinite) then
    Exit;
  L := Length(Value.Coefficient);
  Inc(Value.Exponent, DropDigits);
  if DropDigits > L then
  begin
    Value.Coefficient := '0';
    Exit;
  end;
  RoundUp := Value.Coefficient[L - DropDigits + 1] >= '5';
  SetLength(Value.Coefficient, L - DropDigits);
  if Value.Coefficient = '' then
    Value.Coefficient := '0';
  if RoundUp then
  begin
    i := Length(Value.Coefficient);
    while (i > 0) and (Value.Coefficient[i] = '9') do
    begin
      Value.Coefficient[i] := '0';
      Dec(i);
    end;
    if i = 0 then
      Value.Coefficient := '1' + Value.Coefficient
    else
      Value.Coefficient[i] := Char(Ord(Value.Coefficient[i]) + 1);
  end;
  StripLeadingZeros(Value.Coefficient);
end;

function FBDecimalRescale(const Value: TFBDecimal; Exponent: Integer): TFBDecimal;
begin
  Result := Value;
  if Result.Kind <> dkFinite then
    Exit;
  if Result.Exponent > Exponent then
  begin
    if Result.Coefficient <> '0' then
      Result.Coefficient := Result.Coefficient + StringOfChar('0', Result.Exponent - Exponent);
    Result.Exponent := Exponent;
  end
  else if Result.Exponent < Exponent then
    FBDecimalRound(Result, Exponent - Result.Exponent);
end;

function StrToFBDecimal(const S: string; out Res: TFBDecimal): Boolean;
var
  i, L, FracDigits, Exp, ExpSign: Integer;
  HasPoint, HasDigits: Boolean;
  Str, UStr: string;
begin
  Result := False;
  Res.Kind := dkFinite;
  Res.Negative := False;
  Res.Coefficient := '0';
  Res.Exponent := 0;
  Str := Trim(S);
  L := Length(Str);
  if L = 0 then
    Exit;
  i := 1;
  if (Str[1] = '-') or (Str[1] = '+') then
  begin
    Res.Negative := Str[1] = '-';
    Inc(i);
  end;
  UStr := UpperCase(Copy(Str, i, MaxInt));
  if (UStr = 'INF') or (UStr = 'INFINITY') then
  begin
    Res.Kind := dkInfinity;
    Result := True;
    Exit;
  end;
  if UStr = 'NAN' then
  begin
    Res.Kind := dkNaN;
    Result := True;
    Exit;
  end;
  if UStr = 'SNAN' then
  begin
    Res.Kind := dkSignalingNaN;
    Result := True;
    Exit;
  end;

  Res.Coefficient := '';
  FracDigits := 0;
  HasPoint := False;
  HasDigits := False;
  while i <= L do
  begin
    case Str[i] of
      '0' .. '9':
        begin
          Res.Coefficient := Res.Coefficient + Str[i];
          HasDigits := True;
          if HasPoint then
            Inc(FracDigits);
        end;
      '.', ',':
        begin
          if HasPoint then
            Exit;
          HasPoint := True;
        end;
      'e', 'E': Break;
    else
      Exit;
    end;
    Inc(i);
  end;
  if not HasDigits then
    Exit;

  Exp := 0;
  if i <= L then
  begin
    // exponent
    Inc(i);
    ExpSign := 1;
    if (i <= L) and ((Str[i] = '-') or (Str[i] = '+')) then
    begin
      if Str[i] = '-' then
        ExpSign := -1;
      Inc(i);
    end;
    if i > L then
      Exit;
    while i <= L do
    begin
      if (Str[i] < '0') or (Str[i] > '9') or (Exp > 100000) then
        Exit;
      Exp := Exp * 10 + Ord(Str[i]) - Ord('0');
      Inc(i);
    end;
    Exp := Exp * ExpSign;
  end;
  StripLeadingZeros(Res.Coefficient);
  Res.Exponent := Exp - FracDigits;
  Result := True;
end;

function SpecialToStr(const Value: TFBDecimal): string;
begin
  case Value.Kind of
    dkInfinity: Result := 'Infinity';
    dkNaN: Result := 'NaN';
    dkSignalingNaN: Result := 'sNaN';
  else
    Result := '';
  end;
  if Value.Negative then
    Result := '-' + Result;
end;

function FBDecimalToStr(const Value: TFBDecimal; DecSep: Char = '.'): string;
var
  n, AdjExp: Integer;
begin
  if Value.Kind <> dkFinite then
  begin
    Result := SpecialToStr(Value);
    Exit;
  end;
  n := Length(Value.Coefficient);
  AdjExp := Value.Exponent + n - 1;
  if (Value.Exponent <= 0) and (AdjExp >= -6) then
    Result := FBDecimalToPlainStr(Value, DecSep)
  else
  begin
    Result := Value.Coefficient[1];
    if n > 1 then
      Result := Result + DecSep + Copy(Value.Coefficient, 2, MaxInt);
    if AdjExp < 0 then
      Result := Result + 'E-' + IntToStr(-AdjExp)
    else
      Result := Result + 'E+' + IntToStr(AdjExp);
    if Value.Negative then
      Result := '-' + Result;
  end;
end;

function FBDecimalToPlainStr(const Value: TFBDecimal; DecSep: Char = '.'): string;
var
  n, IntDigits: Integer;
begin
  if Value.Kind <> dkFinite then
  begin
    Result := SpecialToStr(Value);
    Exit;
  end;
  n := Length(Value.Coefficient);
  if Value.Exponent >= 0 then
  begin
    if Value.Coefficient = '0' then
      Result := '0'
    else
      Result := Value.Coefficient + StringOfChar('0', Value.Exponent);
  end
  else
  begin
    IntDigits := n + Value.Exponent;
    if IntDigits > 0 then
      Result := Copy(Value.Coefficient, 1, IntDigits) + DecSep + Copy(Value.Coefficient, IntDigits + 1, MaxInt)
    else
      Result := '0' + DecSep + StringOfChar('0', -IntDigits) + Value.Coefficient;
  end;
  if Value.Negative then
    Result := '-' + Result;
end;

const
  MaxBcdDigits = 64;
  MaxBcdScale  = 63;

type
  // Decimal digits without strings, used on the hot paths to TBcd
  TFBDigits = record
    Count: Integer; // at least 1, no leading zeros
    Exponent: Integer;
    Negative: Boolean;
    D: array [0 .. MaxBcdDigits + 1] of Byte; // most significant first
  end;

const
  Int64Pow10: array [0 .. 18] of Int64 = (1, 10, 100, 1000, 10000, 100000,
    1000000, 10000000, 100000000, 1000000000, 10000000000, 100000000000,
    1000000000000, 10000000000000, 100000000000000, 1000000000000000,
    10000000000000000, 100000000000000000, 1000000000000000000);
  // exact powers of ten in Double
  DoublePow10: array [0 .. 22] of Double = (1E0, 1E1, 1E2, 1E3, 1E4, 1E5, 1E6,
    1E7, 1E8, 1E9, 1E10, 1E11, 1E12, 1E13, 1E14, 1E15, 1E16, 1E17, 1E18, 1E19,
    1E20, 1E21, 1E22);
  // integers up to 2^53 are exact in Double
  MaxExactDoubleInt = 9007199254740992;

function DigitsIsZero(const V: TFBDigits): Boolean;
begin
  Result := (V.Count = 1) and (V.D[0] = 0);
end;

// Number of least significant digits to drop so the value fits TBcd,
// -1 if the integer part does not fit
function BcdDropDigits(Count, Exponent: Integer): Integer;
var
  IntDigits, FracDigits: Integer;
begin
  Result := 0;
  if Exponent >= 0 then
    Exit;
  IntDigits := Count + Exponent;
  if IntDigits < 1 then
    IntDigits := 1; // leading zero
  FracDigits := -Exponent;
  if FracDigits > MaxBcdScale then
    FracDigits := MaxBcdScale;
  if IntDigits + FracDigits > MaxBcdDigits then
    FracDigits := MaxBcdDigits - IntDigits;
  if FracDigits < 0 then
    Result := -1
  else
    Result := -Exponent - FracDigits;
end;

// Removes DropDigits least significant digits, rounding half away from zero
procedure RoundDigits(var V: TFBDigits; DropDigits: Integer);
var
  i: Integer;
  RoundUp: Boolean;
begin
  Inc(V.Exponent, DropDigits);
  if DropDigits > V.Count then
  begin
    V.Count := 1;
    V.D[0] := 0;
    Exit;
  end;
  RoundUp := V.D[V.Count - DropDigits] >= 5;
  Dec(V.Count, DropDigits);
  if V.Count = 0 then
  begin
    V.Count := 1;
    V.D[0] := 0;
  end;
  if RoundUp then
  begin
    i := V.Count - 1;
    while (i >= 0) and (V.D[i] = 9) do
    begin
      V.D[i] := 0;
      Dec(i);
    end;
    if i < 0 then
    begin
      Move(V.D[0], V.D[1], V.Count);
      V.D[0] := 1;
      Inc(V.Count);
    end
    else
      Inc(V.D[i]);
  end;
end;

// Pads with zeros or rounds to Exponent. Returns False if the digits do not fit
// the buffer.
function RescaleDigits(var V: TFBDigits; Exponent: Integer): Boolean;
var
  Pad: Integer;
begin
  Result := True;
  if V.Exponent > Exponent then
  begin
    if not DigitsIsZero(V) then
    begin
      Pad := V.Exponent - Exponent;
      if V.Count + Pad > Length(V.D) then
      begin
        Result := False;
        Exit;
      end;
      FillChar(V.D[V.Count], Pad, 0);
      Inc(V.Count, Pad);
    end;
    V.Exponent := Exponent;
  end
  else if V.Exponent < Exponent then
    RoundDigits(V, Exponent - V.Exponent);
end;

// Integer part of the value, the fraction is truncated. Returns False on overflow.
function DigitsToInt64(const V: TFBDigits; out Res: Int64): Boolean;
var
  IntDigits, i, Digit: Integer;
begin
  Result := False;
  Res := 0;
  if DigitsIsZero(V) then
  begin
    Result := True;
    Exit;
  end;
  IntDigits := V.Count + V.Exponent;
  if IntDigits > 19 then
    Exit;
  // accumulate negative, the range of Int64 is larger there
  for i := 0 to IntDigits - 1 do
  begin
    if i < V.Count then
      Digit := V.D[i]
    else
      Digit := 0;
    if (i >= 18) and (Res < (Low(Int64) + Digit) div 10) then
      Exit;
    Res := Res * 10 - Digit;
  end;
  if not V.Negative then
  begin
    if Res = Low(Int64) then
      Exit;
    Res := -Res;
  end;
  Result := True;
end;

function DigitsToDouble(const V: TFBDigits): Double;
var
  n, Exp, i, p, Code: Integer;
  M: Int64;
  S, ExpStr: string;
begin
  n := V.Count;
  Exp := V.Exponent;
  while (n > 1) and (V.D[n - 1] = 0) do
  begin
    Dec(n);
    Inc(Exp);
  end;
  if (n <= 15) and (Exp >= -22) and (Exp <= 22) then
  begin
    // exact coefficient and power of ten, the result is rounded once
    M := 0;
    for i := 0 to n - 1 do
      M := M * 10 + V.D[i];
    if Exp < 0 then
      Result := M / DoublePow10[-Exp]
    else
      Result := M * DoublePow10[Exp];
    if V.Negative then
      Result := -Result;
  end
  else
  begin
    // [-]<digits>E<exponent>
    ExpStr := IntToStr(Exp);
    SetLength(S, Ord(V.Negative) + n + 1 + Length(ExpStr));
    p := 1;
    if V.Negative then
    begin
      S[1] := '-';
      p := 2;
    end;
    for i := 0 to n - 1 do
      S[p + i] := Char(Ord('0') + V.D[i]);
    Inc(p, n);
    S[p] := 'E';
    Move(ExpStr[1], S[p + 1], Length(ExpStr) * SizeOf(Char));
    Val(S, Result, Code);
    if Code <> 0 then
      raise EConvertError.Create('Invalid decimal value');
  end;
end;

procedure BcdToDigits(const Value: TBcd; out Res: TFBDigits);
var
  i, n, Nibble: Integer;
begin
  Res.Count := 0;
  Res.Exponent := -(Value.SignSpecialPlaces and $3F);
  n := Value.Precision;
  if n > MaxBcdDigits then
    n := MaxBcdDigits;
  for i := 0 to n - 1 do
  begin
    if i and 1 = 0 then
      Nibble := Value.Fraction[i shr 1] shr 4
    else
      Nibble := Value.Fraction[i shr 1] and $0F;
    // skip the leading zeros
    if (Res.Count > 0) or (Nibble <> 0) then
    begin
      Res.D[Res.Count] := Nibble;
      Inc(Res.Count);
    end;
  end;
  if Res.Count = 0 then
  begin
    Res.Count := 1;
    Res.D[0] := 0;
  end;
  // TBcd has no signed zero
  Res.Negative := ((Value.SignSpecialPlaces and $80) <> 0) and not DigitsIsZero(Res);
end;

// Coefficient of Value into the digits buffer, False if it does not fit
function FBDecimalToDigits(const Value: TFBDecimal; out Res: TFBDigits): Boolean;
var
  i: Integer;
begin
  Res.Count := Length(Value.Coefficient);
  Result := Res.Count <= MaxBcdDigits + 1;
  if not Result then
    Exit;
  Res.Exponent := Value.Exponent;
  Res.Negative := Value.Negative;
  for i := 1 to Res.Count do
    Res.D[i - 1] := Ord(Value.Coefficient[i]) - Ord('0');
end;

function BcdToInt64Scaled(const Value: TBcd; out Res: Int64; out Scale: Integer): Boolean;
var
  i, n, Nibble, Count: Integer;
begin
  Result := False;
  Res := 0;
  Scale := -(Value.SignSpecialPlaces and $3F);
  Count := 0;
  n := Value.Precision;
  if n > MaxBcdDigits then
    n := MaxBcdDigits;
  // accumulate negative, the range of Int64 is larger there
  for i := 0 to n - 1 do
  begin
    if i and 1 = 0 then
      Nibble := Value.Fraction[i shr 1] shr 4
    else
      Nibble := Value.Fraction[i shr 1] and $0F;
    if (Count > 0) or (Nibble <> 0) then
    begin
      Inc(Count);
      if Count > 19 then
        Exit;
      if (Count = 19) and (Res < (Low(Int64) + Nibble) div 10) then
        Exit;
      Res := Res * 10 - Nibble;
    end;
  end;
  if (Value.SignSpecialPlaces and $80) = 0 then
  begin
    if Res = Low(Int64) then
      Exit;
    Res := -Res;
  end;
  Result := True;
end;

function DigitsToBcd(var V: TFBDigits; out Res: TBcd): Boolean;
var
  IntDigits, FracDigits, Drop, Pad, i, n: Integer;
begin
  Result := False;
  FillChar(Res, SizeOf(Res), 0);
  if V.Exponent >= 0 then
  begin
    if (V.Count = 1) and (V.D[0] = 0) then
      V.Exponent := 0;
    if V.Count + V.Exponent > MaxBcdDigits then
      Exit;
    FillChar(V.D[V.Count], V.Exponent, 0);
    Inc(V.Count, V.Exponent);
    V.Exponent := 0;
    IntDigits := V.Count;
    FracDigits := 0;
  end
  else
  begin
    Drop := BcdDropDigits(V.Count, V.Exponent);
    if Drop < 0 then
      Exit;
    if Drop > 0 then
      RoundDigits(V, Drop);
    FracDigits := -V.Exponent;
    IntDigits := V.Count - FracDigits;
    if IntDigits < 1 then
      IntDigits := 1;
  end;
  if IntDigits + FracDigits > MaxBcdDigits then
    Exit;
  Pad := IntDigits + FracDigits - V.Count;
  Res.Precision := IntDigits + FracDigits;
  Res.SignSpecialPlaces := FracDigits;
  if V.Negative and ((V.Count > 1) or (V.D[0] <> 0)) then
    Res.SignSpecialPlaces := Res.SignSpecialPlaces or $80;
  for i := 0 to V.Count - 1 do
  begin
    n := Pad + i;
    if n and 1 = 0 then
      Res.Fraction[n shr 1] := V.D[i] shl 4
    else
      Res.Fraction[n shr 1] := Res.Fraction[n shr 1] or V.D[i];
  end;
  Result := True;
end;

function FBDecimalToBcd(const Value: TFBDecimal; out Res: TBcd): Boolean;
var
  V: TFBDecimal;
  Digits: TFBDigits;
  Drop: Integer;
begin
  Result := False;
  FillChar(Res, SizeOf(Res), 0);
  if Value.Kind <> dkFinite then
    Exit;
  V := Value;
  // bring the coefficient into the digits buffer, rounding like DigitsToBcd
  if Length(V.Coefficient) > MaxBcdDigits then
  begin
    Drop := BcdDropDigits(Length(V.Coefficient), V.Exponent);
    if Drop <= 0 then
      Exit; // too many integer digits
    FBDecimalRound(V, Drop);
  end;
  if FBDecimalToDigits(V, Digits) then
    Result := DigitsToBcd(Digits, Res);
end;

procedure DigitsToFBDecimal(const Digits: TFBDigits; var Res: TFBDecimal);
var
  i: Integer;
begin
  Res.Kind := dkFinite;
  Res.Negative := Digits.Negative; // DECFLOAT has a signed zero
  Res.Exponent := Digits.Exponent;
  SetLength(Res.Coefficient, Digits.Count);
  for i := 0 to Digits.Count - 1 do
    Res.Coefficient[i + 1] := Char(Ord('0') + Digits.D[i]);
end;

function BcdToFBDecimal(const Value: TBcd): TFBDecimal;
var
  Digits: TFBDigits;
begin
  BcdToDigits(Value, Digits);
  DigitsToFBDecimal(Digits, Result);
end;

function FBDecimalToDouble(const Value: TFBDecimal): Double;
var
  Code: Integer;
begin
  case Value.Kind of
    dkInfinity:
      if Value.Negative then
        Result := NegInfinity
      else
        Result := Infinity;
    dkNaN, dkSignalingNaN: Result := NaN;
  else
    Val(FBDecimalToStr(Value), Result, Code);
    if Code <> 0 then
      raise EConvertError.Create('Invalid decimal value');
  end;
end;

// Value in scientific notation with Digits significant digits and '.' as separator
function DoubleToExpStr(Value: Double; Digits: Integer): string;
var
  i: Integer;
begin
  Result := FloatToStrF(Value, ffExponent, Digits, 0);
  // FloatToStrF uses the locale decimal separator
  for i := 1 to Length(Result) do
    if (Result[i] <> '-') and (Result[i] <> '+') and (Result[i] <> 'E') and
      ((Result[i] < '0') or (Result[i] > '9')) then
      Result[i] := '.';
end;

function DoubleToFBDecimal(Value: Double): TFBDecimal;
var
  S: string;
  i, Digits, Code: Integer;
  Back: Double;
begin
  if IsNan(Value) then
  begin
    Result.Kind := dkNaN;
    Result.Negative := False;
    Result.Coefficient := '0';
    Result.Exponent := 0;
    Exit;
  end;
  if IsInfinite(Value) then
  begin
    Result.Kind := dkInfinity;
    Result.Negative := Value < 0;
    Result.Coefficient := '0';
    Result.Exponent := 0;
    Exit;
  end;
  // The shortest representation which converts back to the same Double:
  // no binary noise (0.1 -> 0.1) and no lost digits (1/3 -> 0.3333333333333333)
  for Digits := 15 to 17 do
  begin
    S := DoubleToExpStr(Value, Digits);
    if Digits = 17 then
      Break;
    Val(S, Back, Code);
    if (Code = 0) and (Back = Value) then
      Break;
  end;
  if not StrToFBDecimal(S, Result) then
    raise EConvertError.Create('Invalid floating point value');
  // drop the trailing zeros of the fixed 15 digits
  i := Length(Result.Coefficient);
  while (i > 1) and (Result.Coefficient[i] = '0') do
    Dec(i);
  Inc(Result.Exponent, Length(Result.Coefficient) - i);
  SetLength(Result.Coefficient, i);
  if Result.Coefficient = '0' then
  begin
    Result.Exponent := 0;
    Result.Negative := False;
  end;
end;

function FBDecimalToInt64(const Value: TFBDecimal; out Res: Int64): Boolean;
var
  V: TFBDecimal;
  Digits: TFBDigits;
begin
  Result := False;
  Res := 0;
  if Value.Kind <> dkFinite then
    Exit;
  V := Value;
  // DigitsToInt64 truncates the fraction too, here only a coefficient longer
  // than the digits buffer is truncated first
  if (V.Exponent < 0) and (Length(V.Coefficient) > MaxBcdDigits + 1) then
  begin
    if Length(V.Coefficient) <= -V.Exponent then
      V.Coefficient := '0'
    else
      SetLength(V.Coefficient, Length(V.Coefficient) + V.Exponent);
    V.Exponent := 0;
  end;
  // a longer integer part does not fit Int64 anyway
  if FBDecimalToDigits(V, Digits) then
    Result := DigitsToInt64(Digits, Res);
end;

function Int64ToFBDecimal(Value: Int64; Exponent: Integer = 0): TFBDecimal;
begin
  Result.Kind := dkFinite;
  Result.Negative := Value < 0;
  Result.Exponent := Exponent;
  Result.Coefficient := IntToStr(Value);
  if Result.Negative then
    Delete(Result.Coefficient, 1, 1);
end;

{ INT128 }

function Int128IsNegative(const Value: TFB_I128): Boolean;
begin
  Result := (Value.fb_data[3] and $80000000) <> 0;
end;

procedure Int128Negate(var Value: TFB_I128);
var
  i: Integer;
  c: Int64;
begin
  c := 1;
  for i := 0 to 3 do
  begin
    c := Int64(Cardinal(not Value.fb_data[i])) + c;
    Value.fb_data[i] := Cardinal(c and $FFFFFFFF);
    c := c shr 32;
  end;
end;

function Int128IsZero(const Value: TFB_I128): Boolean;
begin
  Result := (Value.fb_data[0] = 0) and (Value.fb_data[1] = 0) and (Value.fb_data[2] = 0) and (Value.fb_data[3] = 0);
end;

// Unsigned division, returns the remainder
function Int128DivMod(var Value: TFB_I128; Divisor: Cardinal): Cardinal;
var
  i: Integer;
  r, q: Int64;
  r32: Cardinal;
begin
  r := 0;
  for i := 3 downto 0 do
  begin
    r := (r shl 32) or Int64(Value.fb_data[i]);
    if r = 0 then
      Continue; // the limb is already 0
    if Int64Rec(r).Hi = 0 then
    begin
      // 32-bit division is much cheaper than the Int64 one on Win32
      r32 := Int64Rec(r).Lo;
      Value.fb_data[i] := r32 div Divisor;
      r := r32 - Value.fb_data[i] * Divisor;
    end
    else
    begin
      q := r div Divisor;
      Value.fb_data[i] := Cardinal(q);
      r := r - q * Divisor;
    end;
  end;
  Result := Cardinal(r);
end;

// Unsigned Value * Mul + Add, returns False on overflow
function Int128MulAdd(var Value: TFB_I128; Mul, Add: Cardinal): Boolean;
var
  i: Integer;
  c: Int64;
begin
  c := Add;
  for i := 0 to 3 do
  begin
    c := Int64(Value.fb_data[i]) * Mul + c;
    Value.fb_data[i] := Cardinal(c and $FFFFFFFF);
    c := c shr 32;
  end;
  Result := c = 0;
end;

procedure Int128ToDigits(const Value: TFB_I128; Scale: Integer; out Res: TFBDigits);
var
  V: TFB_I128;
  Chunk: Cardinal;
  Tmp: array [0 .. 44] of Byte; // least significant first, 5 chunks of 9 digits
  n, i: Integer;
begin
  Res.Negative := Int128IsNegative(Value);
  V := Value;
  if Res.Negative then
    Int128Negate(V);
  n := 0;
  repeat
    Chunk := Int128DivMod(V, 1000000000);
    for i := 1 to 9 do
    begin
      Tmp[n] := Chunk mod 10;
      Chunk := Chunk div 10;
      Inc(n);
    end;
  until Int128IsZero(V);
  while (n > 1) and (Tmp[n - 1] = 0) do
    Dec(n);
  Res.Count := n;
  for i := 0 to n - 1 do
    Res.D[i] := Tmp[n - 1 - i];
  Res.Exponent := Scale;
  if (n = 1) and (Res.D[0] = 0) then
    Res.Negative := False;
end;

function Int128ToFBDecimal(const Value: TFB_I128; Scale: Integer): TFBDecimal;
var
  Digits: TFBDigits;
begin
  Int128ToDigits(Value, Scale, Digits);
  DigitsToFBDecimal(Digits, Result);
end;

// True if the value fits Int64, i.e. the high 64 bits are the sign extension
function Int128ToInt64(const Value: TFB_I128; out Res: Int64): Boolean;
var
  Ext: Cardinal;
begin
  if (Value.fb_data[1] and $80000000) <> 0 then
    Ext := $FFFFFFFF
  else
    Ext := 0;
  Result := (Value.fb_data[2] = Ext) and (Value.fb_data[3] = Ext);
  Int64Rec(Res).Lo := Value.fb_data[0];
  Int64Rec(Res).Hi := Value.fb_data[1];
end;

// Rounds the value to Scale digits. Returns False on overflow.
function DigitsToInt128(var V: TFBDigits; Scale: Integer; out Res: TFB_I128): Boolean;
var
  i, n: Integer;
  Chunk: Cardinal;
begin
  Result := False;
  FillChar(Res, SizeOf(Res), 0);
  if not RescaleDigits(V, Scale) or (V.Count > FBInt128Digits) then
    Exit;
  // 9 digits at a time
  i := 0;
  while i < V.Count do
  begin
    Chunk := 0;
    n := 0;
    while (i < V.Count) and (n < 9) do
    begin
      Chunk := Chunk * 10 + V.D[i];
      Inc(i);
      Inc(n);
    end;
    if not Int128MulAdd(Res, Cardinal(Int64Pow10[n]), Chunk) then
      Exit;
  end;
  if Int128IsNegative(Res) then
  begin
    // only -2^127 is allowed
    if not(V.Negative and (Res.fb_data[3] = $80000000) and (Res.fb_data[2] = 0)
      and (Res.fb_data[1] = 0) and (Res.fb_data[0] = 0)) then
      Exit;
  end
  else if V.Negative then
    Int128Negate(Res);
  Result := True;
end;

function FBDecimalToInt128(const Value: TFBDecimal; Scale: Integer; out Res: TFB_I128): Boolean;
var
  V: TFBDecimal;
  Digits: TFBDigits;
begin
  Result := False;
  FillChar(Res, SizeOf(Res), 0);
  if Value.Kind <> dkFinite then
    Exit;
  V := FBDecimalRescale(Value, Scale);
  if (Length(V.Coefficient) <= FBInt128Digits) and FBDecimalToDigits(V, Digits) then
    Result := DigitsToInt128(Digits, Scale, Res);
end;

function Int128ToStr(const Value: TFB_I128; Scale: Integer; DecSep: Char = '.'): string;
begin
  Result := FBDecimalToPlainStr(Int128ToFBDecimal(Value, Scale), DecSep);
end;

{ DECFLOAT, IEEE 754 decimal64/decimal128 with densely packed decimal encoding }

// Count <= 16 bits starting at bit Pos, bit 0 is the least significant bit of W[0]
function GetBits(const W: array of Cardinal; Pos, Count: Integer): Cardinal;
var
  Idx, Shift: Integer;
  V: Int64;
begin
  Idx := Pos shr 5;
  Shift := Pos and 31;
  V := Int64(W[Idx]) shr Shift;
  if Shift + Count > 32 then
    V := V or (Int64(W[Idx + 1]) shl (32 - Shift));
  Result := Cardinal(V) and ((Cardinal(1) shl Count) - 1);
end;

// Count <= 16 bits starting at bit Pos
procedure SetBits(var W: array of Cardinal; Pos, Count: Integer; Value: Cardinal);
var
  Idx, Shift: Integer;
  Mask, V: Int64;
begin
  Idx := Pos shr 5;
  Shift := Pos and 31;
  Mask := Int64((Cardinal(1) shl Count) - 1) shl Shift;
  V := Int64(Value and ((Cardinal(1) shl Count) - 1)) shl Shift;
  W[Idx] := (W[Idx] and not Int64Rec(Mask).Lo) or Int64Rec(V).Lo;
  if Shift + Count > 32 then
    W[Idx + 1] := (W[Idx + 1] and not Int64Rec(Mask).Hi) or Int64Rec(V).Hi;
end;

// 10 bit declet -> 0..999
function DPDToBin(D: Cardinal): Cardinal;
var
  d2, d1, d0: Cardinal;
begin
  if (D and $8) = 0 then
  begin
    d2 := (D shr 7) and 7;
    d1 := (D shr 4) and 7;
    d0 := D and 7;
  end
  else
    case (D shr 1) and 3 of
      0:
        begin
          d2 := (D shr 7) and 7;
          d1 := (D shr 4) and 7;
          d0 := 8 + (D and 1);
        end;
      1:
        begin
          d2 := (D shr 7) and 7;
          d1 := 8 + ((D shr 4) and 1);
          d0 := (((D shr 5) and 3) shl 1) or (D and 1);
        end;
      2:
        begin
          d2 := 8 + ((D shr 7) and 1);
          d1 := (D shr 4) and 7;
          d0 := (((D shr 8) and 3) shl 1) or (D and 1);
        end;
    else
      case (D shr 5) and 3 of
        0:
          begin
            d2 := 8 + ((D shr 7) and 1);
            d1 := 8 + ((D shr 4) and 1);
            d0 := (((D shr 8) and 3) shl 1) or (D and 1);
          end;
        1:
          begin
            d2 := 8 + ((D shr 7) and 1);
            d1 := (((D shr 8) and 3) shl 1) or ((D shr 4) and 1);
            d0 := 8 + (D and 1);
          end;
        2:
          begin
            d2 := (D shr 7) and 7;
            d1 := 8 + ((D shr 4) and 1);
            d0 := 8 + (D and 1);
          end;
      else
        d2 := 8 + ((D shr 7) and 1);
        d1 := 8 + ((D shr 4) and 1);
        d0 := 8 + (D and 1);
      end;
    end;
  Result := d2 * 100 + d1 * 10 + d0;
end;

// 0..999 -> 10 bit declet
function BinToDPD(V: Cardinal): Cardinal;
var
  d2, d1, d0: Cardinal;
begin
  d2 := V div 100;
  d1 := (V div 10) mod 10;
  d0 := V mod 10;
  case ((d2 shr 3) shl 2) or ((d1 shr 3) shl 1) or (d0 shr 3) of
    0: Result := (d2 shl 7) or (d1 shl 4) or d0;
    1: Result := (d2 shl 7) or (d1 shl 4) or $8 or (d0 and 1);
    2: Result := (d2 shl 7) or ((d0 and 6) shl 4) or ((d1 and 1) shl 4) or $A or (d0 and 1);
    3: Result := (d2 shl 7) or $40 or ((d1 and 1) shl 4) or $E or (d0 and 1);
    4: Result := ((d0 and 6) shl 7) or ((d2 and 1) shl 7) or (d1 shl 4) or $C or (d0 and 1);
    5: Result := ((d1 and 6) shl 7) or ((d2 and 1) shl 7) or $20 or ((d1 and 1) shl 4) or $E or (d0 and 1);
    6: Result := ((d0 and 6) shl 7) or ((d2 and 1) shl 7) or ((d1 and 1) shl 4) or $E or (d0 and 1);
  else
    Result := ((d2 and 1) shl 7) or $60 or ((d1 and 1) shl 4) or $E or (d0 and 1);
  end;
end;

var
  // declet (10 bits) -> 0..999, filled in the initialization section
  DPDTable: array [0 .. 1023] of Word;

function DecodeDecFloatDigits(const W: array of Cardinal; Declets, ExpBits, Bias: Integer; out Res: TFBDigits): TFBDecimalKind;
var
  TotalBits, i: Integer;
  Comb, ExpHi, Msd, V: Cardinal;

  procedure AddDigit(Digit: Cardinal);
  begin
    // skip the leading zeros
    if (Res.Count > 0) or (Digit <> 0) then
    begin
      Res.D[Res.Count] := Digit;
      Inc(Res.Count);
    end;
  end;

begin
  TotalBits := Length(W) * 32;
  Res.Negative := GetBits(W, TotalBits - 1, 1) = 1;
  Res.Count := 0;
  Res.Exponent := 0;
  Comb := GetBits(W, TotalBits - 6, 5);
  if (Comb and $1E) = $1E then
  begin
    Res.Count := 1;
    Res.D[0] := 0;
    if Comb = $1E then
      Result := dkInfinity
    else if GetBits(W, TotalBits - 7, 1) = 1 then
      Result := dkSignalingNaN
    else
      Result := dkNaN;
    Exit;
  end;
  Result := dkFinite;
  if (Comb and $18) = $18 then
  begin
    ExpHi := (Comb shr 1) and 3;
    Msd := 8 + (Comb and 1);
  end
  else
  begin
    ExpHi := Comb shr 3;
    Msd := Comb and 7;
  end;
  Res.Exponent := Integer((ExpHi shl ExpBits) or GetBits(W, Declets * 10, ExpBits)) - Bias;
  AddDigit(Msd);
  for i := Declets - 1 downto 0 do
  begin
    V := DPDTable[GetBits(W, i * 10, 10)];
    AddDigit(V div 100);
    AddDigit((V div 10) mod 10);
    AddDigit(V mod 10);
  end;
  if Res.Count = 0 then
  begin
    Res.Count := 1;
    Res.D[0] := 0;
  end;
end;

function DecodeDecFloat(const W: array of Cardinal; Declets, ExpBits, Bias: Integer): TFBDecimal;
var
  Digits: TFBDigits;
begin
  Result.Kind := DecodeDecFloatDigits(W, Declets, ExpBits, Bias, Digits);
  if Result.Kind = dkFinite then
    DigitsToFBDecimal(Digits, Result)
  else
  begin
    Result.Negative := Digits.Negative;
    Result.Coefficient := '0';
    Result.Exponent := 0;
  end;
end;

// Zeroes W and sets the sign, NaN and Infinity. Returns False for finite values.
function EncodeDecFloatSpecial(var W: array of Cardinal; Kind: TFBDecimalKind; Negative: Boolean): Boolean;
var
  TotalBits, i: Integer;
begin
  TotalBits := Length(W) * 32;
  for i := 0 to High(W) do
    W[i] := 0;
  if Negative then
    SetBits(W, TotalBits - 1, 1, 1);
  Result := True;
  case Kind of
    dkInfinity: SetBits(W, TotalBits - 6, 5, $1E);
    dkNaN, dkSignalingNaN:
      begin
        SetBits(W, TotalBits - 6, 5, $1F);
        if Kind = dkSignalingNaN then
          SetBits(W, TotalBits - 7, 1, 1);
      end;
  else
    Result := False;
  end;
end;

function EncodeDecFloatDigits(var W: array of Cardinal; var V: TFBDigits; Digits, Declets, ExpBits, Bias: Integer): Boolean;
var
  TotalBits, i, MinExp, MaxExp, Pad: Integer;
  Comb, Msd, ExpHi, q: Cardinal;
  Coef: array [0 .. FBDec34Digits - 1] of Byte; // right aligned coefficient
begin
  Result := False;
  EncodeDecFloatSpecial(W, dkFinite, V.Negative);
  TotalBits := Length(W) * 32;
  MinExp := -Bias;
  MaxExp := 3 * (1 shl ExpBits) - 1 - Bias;
  if V.Count > Digits then
    RoundDigits(V, V.Count - Digits);
  // rounding may produce Digits + 1 digits
  if V.Count > Digits then
    RoundDigits(V, V.Count - Digits);
  if V.Exponent < MinExp then
    RoundDigits(V, MinExp - V.Exponent);
  if V.Exponent > MaxExp then
  begin
    if DigitsIsZero(V) then
      V.Exponent := MaxExp
    else
    begin
      // clamp by padding the coefficient with zeros
      if V.Count + V.Exponent - MaxExp > Digits then
        Exit; // overflow
      RescaleDigits(V, MaxExp);
    end;
  end;

  Pad := Digits - V.Count;
  FillChar(Coef, Pad, 0);
  Move(V.D[0], Coef[Pad], V.Count);
  Msd := Coef[0];
  for i := 0 to Declets - 1 do
    SetBits(W, (Declets - 1 - i) * 10, 10, BinToDPD(Coef[1 + i * 3] * 100 + Coef[2 + i * 3] * 10 + Coef[3 + i * 3]));
  q := Cardinal(V.Exponent + Bias);
  ExpHi := q shr ExpBits;
  SetBits(W, Declets * 10, ExpBits, q and ((Cardinal(1) shl ExpBits) - 1));
  if Msd < 8 then
    Comb := (ExpHi shl 3) or Msd
  else
    Comb := $18 or (ExpHi shl 1) or (Msd and 1);
  SetBits(W, TotalBits - 6, 5, Comb);
  Result := True;
end;

function EncodeDecFloat(var W: array of Cardinal; const Value: TFBDecimal; Digits, Declets, ExpBits, Bias: Integer): Boolean;
var
  V: TFBDecimal;
  D: TFBDigits;
begin
  Result := EncodeDecFloatSpecial(W, Value.Kind, Value.Negative);
  if Result then
    Exit;
  V := Value;
  StripLeadingZeros(V.Coefficient);
  // the digits buffer is limited, round the long coefficients here
  if Length(V.Coefficient) > Digits then
    FBDecimalRound(V, Length(V.Coefficient) - Digits);
  Result := FBDecimalToDigits(V, D) and EncodeDecFloatDigits(W, D, Digits, Declets, ExpBits, Bias);
end;

function Dec16ToFBDecimal(const Value: TFB_DEC16): TFBDecimal;
begin
  Result := DecodeDecFloat(Value.fb_data, 5, 8, 398);
end;

function Dec34ToFBDecimal(const Value: TFB_DEC34): TFBDecimal;
begin
  Result := DecodeDecFloat(Value.fb_data, 11, 12, 6176);
end;

function FBDecimalToDec16(const Value: TFBDecimal; out Res: TFB_DEC16): Boolean;
begin
  Result := EncodeDecFloat(Res.fb_data, Value, FBDec16Digits, 5, 8, 398);
end;

function FBDecimalToDec34(const Value: TFBDecimal; out Res: TFB_DEC34): Boolean;
begin
  Result := EncodeDecFloat(Res.fb_data, Value, FBDec34Digits, 11, 12, 6176);
end;

function FBDecimalFromRaw(SQLType, Scale: Integer; Data: Pointer): TFBDecimal;
begin
  case SQLType of
    SQL_INT128: Result := Int128ToFBDecimal(PFB_I128(Data)^, Scale);
    SQL_DEC16: Result := Dec16ToFBDecimal(PFB_DEC16(Data)^);
  else
    Result := Dec34ToFBDecimal(PFB_DEC34(Data)^);
  end;
end;

function FBRawToDigits(SQLType, Scale: Integer; Data: Pointer; out Res: TFBDigits): TFBDecimalKind;
begin
  case SQLType of
    SQL_INT128:
      begin
        Int128ToDigits(PFB_I128(Data)^, Scale, Res);
        Result := dkFinite;
      end;
    SQL_DEC16: Result := DecodeDecFloatDigits(PFB_DEC16(Data)^.fb_data, 5, 8, 398, Res);
  else
    Result := DecodeDecFloatDigits(PFB_DEC34(Data)^.fb_data, 11, 12, 6176, Res);
  end;
end;

function FBRawToBcd(SQLType, Scale: Integer; Data: Pointer; out Res: TBcd): Boolean;
var
  Digits: TFBDigits;
begin
  if FBRawToDigits(SQLType, Scale, Data, Digits) = dkFinite then
    Result := DigitsToBcd(Digits, Res)
  else
  begin
    FillChar(Res, SizeOf(Res), 0);
    Result := False;
  end;
end;

function FBRawToInt64(SQLType, Scale: Integer; Data: Pointer; out Res: Int64): Boolean;
var
  Digits: TFBDigits;
begin
  if (SQLType = SQL_INT128) and (Scale <= 0) and Int128ToInt64(PFB_I128(Data)^, Res) then
  begin
    // like SQL_INT64
    if Scale < -18 then
      Res := 0
    else
      Res := Res div Int64Pow10[-Scale];
    Result := True;
  end
  else if FBRawToDigits(SQLType, Scale, Data, Digits) = dkFinite then
    Result := DigitsToInt64(Digits, Res)
  else
  begin
    Res := 0;
    Result := False;
  end;
end;

function FBRawToScaledInt64(SQLType, Scale: Integer; Data: Pointer; NewScale: Integer; out Res: Int64): Boolean;
var
  Digits: TFBDigits;
  Drop: Integer;
  p, r: Int64;
begin
  if (SQLType = SQL_INT128) and Int128ToInt64(PFB_I128(Data)^, Res) then
  begin
    Drop := NewScale - Scale;
    if Drop = 0 then
    begin
      Result := True;
      Exit;
    end;
    if (Drop > 0) and (Drop <= 18) then
    begin
      p := Int64Pow10[Drop];
      r := Res mod p;
      Res := Res div p;
      // half away from zero
      if Abs(r) * 2 >= p then
        if r < 0 then
          Dec(Res)
        else
          Inc(Res);
      Result := True;
      Exit;
    end;
    if (Drop < 0) and (-Drop <= 18) and (Res > Low(Int64)) and (Abs(Res) <= High(Int64) div Int64Pow10[-Drop]) then
    begin
      Res := Res * Int64Pow10[-Drop];
      Result := True;
      Exit;
    end;
  end;
  Result := False;
  Res := 0;
  if (FBRawToDigits(SQLType, Scale, Data, Digits) = dkFinite) and RescaleDigits(Digits, NewScale) then
  begin
    Digits.Exponent := 0;
    Result := DigitsToInt64(Digits, Res);
  end;
end;

function FBRawToDouble(SQLType, Scale: Integer; Data: Pointer): Double;
var
  Digits: TFBDigits;
  c: Int64;
begin
  if (SQLType = SQL_INT128) and (Scale <= 0) and (Scale >= -22) and
    Int128ToInt64(PFB_I128(Data)^, c) and (c <= MaxExactDoubleInt) and (c >= -MaxExactDoubleInt) then
  begin
    // exact coefficient and power of ten, the result is rounded once
    Result := c / DoublePow10[-Scale];
    Exit;
  end;
  case FBRawToDigits(SQLType, Scale, Data, Digits) of
    dkFinite: Result := DigitsToDouble(Digits);
    dkInfinity:
      if Digits.Negative then
        Result := NegInfinity
      else
        Result := Infinity;
  else
    Result := NaN;
  end;
end;

function FBBcdToRaw(const Value: TBcd; SQLType, Scale: Integer; Data: Pointer): Boolean;
var
  V: TFBDigits;
begin
  BcdToDigits(Value, V);
  if SQLType = SQL_INT128 then
  begin
    Result := DigitsToInt128(V, Scale, PFB_I128(Data)^);
    Exit;
  end;
  // like FBDecimalToRaw
  while (V.Exponent < 0) and (V.Count > 1) and (V.D[V.Count - 1] = 0) do
  begin
    Dec(V.Count);
    Inc(V.Exponent);
  end;
  if SQLType = SQL_DEC16 then
    Result := EncodeDecFloatDigits(PFB_DEC16(Data)^.fb_data, V, FBDec16Digits, 5, 8, 398)
  else
    Result := EncodeDecFloatDigits(PFB_DEC34(Data)^.fb_data, V, FBDec34Digits, 11, 12, 6176);
end;

function FBDecimalToRaw(const Value: TFBDecimal; SQLType, Scale: Integer; Data: Pointer): Boolean;
var
  V: TFBDecimal;
  L: Integer;
begin
  if SQLType = SQL_INT128 then
  begin
    Result := FBDecimalToInt128(Value, Scale, PFB_I128(Data)^);
    Exit;
  end;
  V := Value;
  L := Length(V.Coefficient);
  while (V.Exponent < 0) and (L > 1) and (V.Coefficient[L] = '0') do
  begin
    Dec(L);
    Inc(V.Exponent);
  end;
  SetLength(V.Coefficient, L);
  if SQLType = SQL_DEC16 then
    Result := FBDecimalToDec16(V, PFB_DEC16(Data)^)
  else
    Result := FBDecimalToDec34(V, PFB_DEC34(Data)^);
end;

{ Time zones }

function FBIsOffsetZone(ZoneID: Word): Boolean;
begin
  Result := ZoneID <= FBMaxOffsetZoneID;
end;

function FBOffsetToZoneID(OffsetMinutes: Integer): Word;
begin
  Result := OffsetMinutes + FBOffsetZoneBias;
end;

function FBZoneIDToOffset(ZoneID: Word): Integer;
begin
  Result := Integer(ZoneID) - FBOffsetZoneBias;
end;

function FBKnownZoneOffset(ZoneID: Word): Integer;
begin
  if FBIsOffsetZone(ZoneID) then
    Result := FBZoneIDToOffset(ZoneID)
  else
    Result := 0;
end;

function FBFormatZoneOffset(OffsetMinutes: Integer): string;
begin
  if OffsetMinutes < 0 then
    Result := Format('-%.2d:%.2d', [-OffsetMinutes div 60, -OffsetMinutes mod 60])
  else
    Result := Format('+%.2d:%.2d', [OffsetMinutes div 60, OffsetMinutes mod 60]);
end;

function FBTimeZoneName(ZoneID: Word): string;
var
  Idx: Integer;
begin
  if FBIsOffsetZone(ZoneID) then
    Result := FBFormatZoneOffset(FBZoneIDToOffset(ZoneID))
  else
  begin
    Idx := FBGmtZoneID - ZoneID;
    if (Idx >= 0) and (Idx < FBTimeZoneNamesCount) then
      Result := FBTimeZoneNames[Idx]
    else
      Result := '';
  end;
end;

const
  IBBuffDateDelta = 678576; // ISC_DATE -> TTimeStamp.Date

function FBTimeStampToDateTime(const Value: TISC_TIMESTAMP): TDateTime;
var
  ts: TTimeStamp;
begin
  ts.Date := Value.timestamp_date + IBBuffDateDelta;
  ts.Time := Value.timestamp_time div 10;
  Result := TimeStampToDateTime(ts);
end;

function CacheOffset(ExtOffset: Smallint): Int64;
begin
  if ExtOffset = FBUnresolvedOffset then
    Result := 0
  else
    Result := Int64(ExtOffset) * 60000;
end;

function FBTimeStampTZToMSecs(const Value: TISC_TIMESTAMP_TZ_EX): Double;
begin
  with Value do
    Result := (Int64(utc_timestamp.timestamp_date) + IBBuffDateDelta) *
      MSecsPerDay + utc_timestamp.timestamp_time div 10 + CacheOffset(ext_offset);
end;

procedure FBMSecsToTimeStampTZ(const MSecs: Double; var Value: TISC_TIMESTAMP_TZ_EX);
var
  Utc: Int64;
begin
  Utc := Round(MSecs);
  if FBIsOffsetZone(Value.time_zone) then
  begin
    Value.ext_offset := FBZoneIDToOffset(Value.time_zone);
    Dec(Utc, Int64(Value.ext_offset) * 60000);
  end
  else
    Value.ext_offset := FBUnresolvedOffset;
  Value.utc_timestamp.timestamp_date := Utc div MSecsPerDay - IBBuffDateDelta;
  Value.utc_timestamp.timestamp_time := (Utc mod MSecsPerDay) * 10;
end;

function FBTimeTZToMSecs(const Value: TISC_TIME_TZ_EX): Integer;
var
  MSecs: Int64;
begin
  MSecs := (Int64(Value.utc_time div 10) + CacheOffset(Value.ext_offset)) mod MSecsPerDay;
  if MSecs < 0 then
    Inc(MSecs, MSecsPerDay);
  Result := MSecs;
end;

procedure FBMSecsToTimeTZ(MSecs: Integer; var Value: TISC_TIME_TZ_EX);
var
  Utc: Int64;
begin
  Utc := MSecs;
  if FBIsOffsetZone(Value.time_zone) then
  begin
    Value.ext_offset := FBZoneIDToOffset(Value.time_zone);
    Dec(Utc, Int64(Value.ext_offset) * 60000);
    Utc := Utc mod MSecsPerDay;
    if Utc < 0 then
      Inc(Utc, MSecsPerDay);
  end
  else
    Value.ext_offset := FBUnresolvedOffset;
  Value.utc_time := Utc * 10;
end;

function FBTimeZoneIDByName(const Name: string; out ZoneID: Word): Boolean;
var
  S: string;
  i, H, M, Sign: Integer;
begin
  Result := False;
  ZoneID := 0;
  S := Trim(Name);
  if S = '' then
    Exit;
  if (S[1] = '+') or (S[1] = '-') then
  begin
    if S[1] = '-' then
      Sign := -1
    else
      Sign := 1;
    i := Pos(':', S);
    if i > 0 then
    begin
      H := StrToIntDef(Copy(S, 2, i - 2), -1);
      M := StrToIntDef(Copy(S, i + 1, MaxInt), -1);
    end
    else
    begin
      H := StrToIntDef(Copy(S, 2, MaxInt), -1);
      M := 0;
    end;
    if (H < 0) or (M < 0) or (M > 59) or (H * 60 + M > FBOffsetZoneBias) then
      Exit;
    ZoneID := FBOffsetToZoneID(Sign * (H * 60 + M));
    Result := True;
    Exit;
  end;
  for i := 0 to FBTimeZoneNamesCount - 1 do
    if AnsiCompareText(FBTimeZoneNames[i], S) = 0 then
    begin
      ZoneID := FBGmtZoneID - i;
      Result := True;
      Exit;
    end;
end;

procedure InitDPDTable;
var
  i: Integer;
begin
  for i := 0 to High(DPDTable) do
    DPDTable[i] := DPDToBin(i);
end;

initialization

InitDPDTable;

end.
