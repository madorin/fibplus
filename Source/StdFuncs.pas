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

(*
  * StdFuncs -
  *   A file chock full of functions that should exist in Delphi, but
  *   dont, like "Max", "GetTempFile", "Soundex", etc...
*)
unit StdFuncs;

{$I FIB.inc}

interface

uses

  Classes, SysUtils, DB, FIBSafeTimer
{$IFDEF WINDOWS}, Windows {$ENDIF}
    , FMTBcd, Variants;

type
  TFIBVariantArray = array of Variant;
  PFIBVariantArray = ^TFIBVariantArray;

  TFIBTimer = TFIBCustomTimer;

function Max(n1, n2: Integer): Integer;
function Min(n1, n2: Integer): Integer; inline;
function RandomString(iLength: Integer): String;
function StripString(const st: String; const CharsToStrip: String): String;
function ExtPrecision(Value: Extended): Integer; inline;
function RoundExtend(Value: Extended; Decimals: Integer): Extended;

// Comp type stuff

function Int64WithScaleToStr(Value: Int64; Scale: Integer; DSep: Char): string; overload;
function ExtendedToBCD(const Value: Extended; NeedScale: Integer): TBCD;

// end Comp type stuff

function Int64ToBCD(Value: Int64; Scale: Integer; var BCD: TBCD): Boolean;
// Value with FromScale decimals as ToScale decimals, rounded half away from zero (half to even with
// HalfToEven, as Round); False on overflow
function RescaleInt64(Value: Int64; FromScale, ToScale: Integer; var Rescaled: Int64;
  HalfToEven: Boolean = False): Boolean;
// Value * 10^Scale (Scale 0..18) rounded half away from zero; False when it doesn't fit Int64
function ExtendedToScaledInt64(Value: Extended; Scale: Integer; var Scaled: Int64): Boolean;
// CurrToStrF of a value scaled by Scale, rounded once to Digits; exact beyond the Currency range
function ScaledCurrToStrF(Value: Int64; Scale: Integer; Format: TFloatFormat; Digits: Integer): string;

function BCDToExtended(BCD: TBCD; var Value: Extended): Boolean;
// Value scaled by Scale decimals (decimals beyond Int64 rounded half away from zero); False on overflow
function BCDToInt64WithScale(BCD: TBCD; var Value: Int64; var Scale: Byte): Boolean;
function BCDToSQLStr(BCD: TBCD): String;
function CompareBCD(const BCD1, BCD2: TBCD): Integer; inline;
function FormatNumericString(const Format, Source: string; OneSectionFormat: Boolean = False): string;

function TimeStamp(const aDate, aTime: Integer): TTimeStamp;
function CmpFullName(cmp: TComponent): string;
function CmpPropPath(Cmp: TComponent; const PropName: string): string;
function CmpInLoadedState(cmp: TComponent): Boolean; inline;

function HookTimeStampToDateTime(const TimeStamp: TTimeStamp): TDateTime;

function IntDateToDateTime(aDate: Integer): TDateTime;
// DB rtns

function BCDFieldAsSQLString(Field: TField; OldVal: Boolean): Variant;
function BCDFieldAsString(Field: TField; OldVal: Boolean): Variant;
function GetBCDFieldData(Field: TField; OldVal: Boolean; var BCD: TBCD): Boolean;
// Fields of DataSet named in FieldNames (separated by ';') added to List
procedure GetDataSetFieldList(DataSet: TDataSet; List: TList; const FieldNames: string);

function GetBit(InByte: Byte; Index: Byte): Boolean; inline;
function SetBit(InByte: Byte; Index: Byte; Value: Boolean): Byte;

function VariantToStream(Value: Variant; Stream: TStream): Integer;
{ Length of Blob }

// S uppercased and trimmed: fractional digits kept by a CURRENT_TIME[(n)], CURRENT_TIMESTAMP[(n)],
// LOCALTIME[(n)] or LOCALTIMESTAMP[(n)] default (server defaults 0 and 3, at most 3), -1 for other values
function DateTimeDefFunctionPrecision(const S: string): Integer;
// Precision 0..2 cuts the milliseconds to that many fractional digits
function TruncateDateTimePrecision(Value: TDateTime; Precision: Integer): TDateTime;
function StringIsDateTimeDefValue(const S: string): Boolean;

const
  E10: array [-18 .. 18] of Double = (1E-18, 1E-17, 1E-16, 1E-15, 1E-14, 1E-13,
    1E-12, 1E-11, 1E-10, 1E-9, 1E-8, 1E-7, 1E-6, 1E-5, 1E-4, 1E-3, 1E-2, 1E-1,
    1, 1E1, 1E2, 1E3, 1E4, 1E5, 1E6, 1E7, 1E8, 1E9, 1E10, 1E11, 1E12, 1E13,
    1E14, 1E15, 1E16, 1E17, 1E18);

  IE10: array [0 .. 18] of Int64 = (1, 10, 100, 1000, 10000, 100000, 1000000,
    10000000, 100000000, 1000000000, 10000000000, 100000000000, 1000000000000,
    10000000000000, 100000000000000, 1000000000000000, 10000000000000000,
    100000000000000000, 1000000000000000000);

const
  AppPathTemplate = '{APP_PATH}';

type
  // Deprecated names of the types renamed in 8.0.0
{$IFDEF WINDOWS}
  TDynArray = TFIBVariantArray deprecated 'Use TFIBVariantArray';
  PDynArray = PFIBVariantArray deprecated 'Use PFIBVariantArray';
{$ENDIF}

implementation

uses
  StrUtil{$IFDEF C24}, Generics.Collections{$ENDIF};

function VariantToStream(Value: Variant; Stream: TStream): Integer;
{ Length of Stream }
var
  B: TVarArrayBound;
  BufSize: Integer;
begin
  Result := 0;
  if not VarIsArray(Value) then
    Exit;
  if not Assigned(Stream) then
    Exit;
  if TVarData(Value).VArray <> nil then
  begin
    B := TVarData(Value).VArray^.Bounds[0];
    if B.ElementCount > 0 then
    begin
      BufSize := B.ElementCount * TVarData(Value).VArray^.ElementSize;
      Stream.Size := BufSize;
      Stream.Position := 0;
      Stream.Write(TVarData(Value).VArray^.Data^, BufSize);
      Result := BufSize;
    end;
  end;
end;

function DateTimeDefFunctionPrecision(const S: string): Integer;
var
  p, i: Integer;
  Name, Digits: string;
begin
  Result := -1;
  p := Pos('(', S);
  if p = 0 then
    Name := S
  else
    Name := Trim(Copy(S, 1, p - 1));
  if (Name = 'CURRENT_TIME') or (Name = 'LOCALTIME') then
    Result := 0
  else if (Name = 'CURRENT_TIMESTAMP') or (Name = 'LOCALTIMESTAMP') then
    Result := 3
  else
    Exit;
  if p = 0 then
    Exit;
  Result := -1;
  if S[Length(S)] <> ')' then
    Exit;
  Digits := Trim(Copy(S, p + 1, Length(S) - p - 1));
  if Digits = '' then
    Exit;
  for i := 1 to Length(Digits) do
    if (Digits[i] < '0') or (Digits[i] > '9') then
      Exit;
  Result := StrToIntDef(Digits, 3);
  // the value of the client keeps milliseconds
  if Result > 3 then
    Result := 3;
end;

function TruncateDateTimePrecision(Value: TDateTime; Precision: Integer): TDateTime;
const
  Divisors: array [0 .. 2] of Integer = (1000, 100, 10);
var
  Stamp: TTimeStamp;
begin
  if (Precision < 0) or (Precision > 2) then
  begin
    Result := Value;
    Exit;
  end;
  Stamp := DateTimeToTimeStamp(Value);
  Stamp.Time := Stamp.Time - Stamp.Time mod Divisors[Precision];
  Result := TimeStampToDateTime(Stamp);
end;

function StringIsDateTimeDefValue(const S: string): Boolean;
begin
  Result := DateTimeDefFunctionPrecision(S) >= 0;
  if not Result and (Length(S) > 0) then
    case S[1] of
      'C': Result := S = 'CURRENT_DATE';
      'N': Result := (S = 'NULL') or (S = 'NOW');
      'T': Result := (S = 'TODAY') or (S = 'TOMORROW');
      'Y': Result := S = 'YESTERDAY';
    end;
end;

type
  THackDS = class(TDataSet);

function GetBCDFieldData(Field: TField; OldVal: Boolean; var BCD: TBCD): Boolean;
var
  OldState: TDataSetState;
{$IFDEF C24}
  Data: TValueBuffer;
{$ENDIF}
begin
  OldState := Field.DataSet.State;
  with THackDS(Field.DataSet) do
    try
      if OldVal and (OldState <> dsOldValue) then
        SetTempState(dsOldValue);
{$IFDEF C24}
      SetLength(Data, SizeOf(TBCD));
      Result := GetFieldData(Field, Data);
      if Result then
        Move(Data[0], BCD, SizeOf(TBCD));
{$ELSE}
      Result := GetFieldData(Field, @BCD);
{$ENDIF}
    finally
      if OldVal and (OldState <> dsOldValue) then
        RestoreState(OldState);
    end;
end;

procedure GetDataSetFieldList(DataSet: TDataSet; List: TList; const FieldNames: string);
{$IFDEF C24}
var
  Fields: TList<TField>;
  Field: TField;
begin
  // TDataSet.GetFieldList(TList) is deprecated (XE3+)
  Fields := TList<TField>.Create;
  try
    DataSet.GetFieldList(Fields, FieldNames);
    for Field in Fields do
      List.Add(Field);
  finally
    Fields.Free;
  end;
end;
{$ELSE}
begin
  DataSet.GetFieldList(List, FieldNames);
end;
{$ENDIF}

function InternalBCDFieldAsString(Field: TField; OldVal, SQLFormat: Boolean): Variant;
var
  BCD: TBCD;
begin
  if GetBCDFieldData(Field, OldVal, BCD) then
  begin
    if SQLFormat then
      Result := BCDToSQLStr(BCD)
    else
      Result := BCDToStr(BCD);
  end
  else
  begin
    Result := UnAssigned;
  end;
end;

function BCDFieldAsSQLString(Field: TField; OldVal: Boolean): Variant;
begin
  Result := InternalBCDFieldAsString(Field, OldVal, true)
end;

function BCDFieldAsString(Field: TField; OldVal: Boolean): Variant;
begin
  Result := InternalBCDFieldAsString(Field, OldVal, False)
end;

function RoundExtend(Value: Extended; Decimals: Integer): Extended;
begin
  Result := System.Int(Value) + Round(Frac(Value) * E10[Decimals]) / E10[Decimals];
end;

function TimeStamp(const aDate, aTime: Integer): TTimeStamp;
begin
  with Result do
  begin
    Time := aTime;
    Date := aDate;
  end;
end;

function HookTimeStampToDateTime(const TimeStamp: TTimeStamp): TDateTime;
var
  t: TTimeStamp;
begin
  if TimeStamp.Date = 0 then
  begin
    t.Date := 1;
    t.Time := TimeStamp.Time;
    Result := TimeStampToDateTime(t) - 1;
  end
  else
    Result := TimeStampToDateTime(TimeStamp)
end;

function IntDateToDateTime(aDate: Integer): TDateTime;
var
  t: TTimeStamp;
begin
  t.Date := aDate;
  t.Time := 0;
  Result := HookTimeStampToDateTime(t);
end;

function CmpFullName(cmp: TComponent): string;
begin
  Result := '';
  while cmp <> nil do
    with cmp do
    begin
      if Name <> '' then
        if Result = '' then
          Result := Name
        else
          Result := Name + '.' + Result;
      cmp := Owner;
    end;
end;

// PropName prefixed with the component path, without a leading dot for an unnamed component
function CmpPropPath(Cmp: TComponent; const PropName: string): string;
begin
  Result := CmpFullName(Cmp);
  if Result = '' then
    Result := PropName
  else
    Result := Result + '.' + PropName;
end;

function CmpInLoadedState(cmp: TComponent): Boolean;
var
  tmpCmp: TComponent;
begin
  tmpCmp := cmp;
  while ((tmpCmp <> nil) and not(csLoading in tmpCmp.ComponentState)) do
  begin
    tmpCmp := tmpCmp.Owner;
  end;
  Result := tmpCmp <> nil;
end;

function ExtPrecision(Value: Extended): Integer;
var
  L, H, i: Integer;
  c: Comp;
  a: Comp;
begin
  L := 0;
  H := 18;
  a := Abs(Int(Value));
  while L <= H do
  begin
    i := (L + H) shr 1;
    c := E10[i] - a;
    if c < 0 then
      L := i + 1
    else
    begin
      H := i - 1;
      if c = 0 then
      begin
        L := i + 1;
        Break
      end;
    end;
  end;
  Result := L
end;

// Comp type stuff

function ExtendedToBCD(const Value: Extended; NeedScale: Integer): TBCD;
var
  c: Comp;
begin
  c := Value * E10[NeedScale];
  Int64ToBCD(PInt64(@c)^, NeedScale, Result);
end;

function Int64ToBCD(Value: Int64; Scale: Integer; var BCD: TBCD): Boolean;
var
  Rest: Int64;
  Digit, Index: Integer;
begin
  // 32 digits, right-aligned; Rest keeps the sign, so Low(Int64) needs no negation
  FillChar(BCD, SizeOf(BCD), 0);
  BCD.Precision := 32;
  Rest := Value;
  Index := 31;
  while Rest <> 0 do
  begin
    Digit := Abs(Rest mod 10);
    if Odd(Index) then
      BCD.Fraction[Index shr 1] := Digit
    else
      BCD.Fraction[Index shr 1] := BCD.Fraction[Index shr 1] or (Digit shl 4);
    Rest := Rest div 10;
    Dec(Index);
  end;
  BCD.SignSpecialPlaces := Byte(Scale);
  if Value < 0 then
    BCD.SignSpecialPlaces := BCD.SignSpecialPlaces or $80;
  Result := True;
end;

function RescaleInt64(Value: Int64; FromScale, ToScale: Integer; var Rescaled: Int64;
  HalfToEven: Boolean): Boolean;
const
  HalfOf1E19 = 5000000000000000000;
var
  Divisor, Remainder: Int64;
  RoundHalfAway: Boolean;
begin
  Result := True;
  if ToScale = FromScale then
    Rescaled := Value
  else if ToScale > FromScale then
    begin
      if Value = 0 then
        Rescaled := 0
      else if ToScale - FromScale > High(IE10) then
        Result := False
      else
        begin
          Divisor := IE10[ToScale - FromScale];
          Result := (Value <= High(Int64) div Divisor) and (Value >= Low(Int64) div Divisor);
          if Result then
            Rescaled := Value * Divisor;
        end;
    end
  else if FromScale - ToScale > High(IE10) + 1 then
    Rescaled := 0
  else if FromScale - ToScale = High(IE10) + 1 then
    begin
      // |Value| < 1E19
      if (Value > HalfOf1E19) or (Value = HalfOf1E19) and not HalfToEven then
        Rescaled := 1
      else if (Value < -HalfOf1E19) or (Value = -HalfOf1E19) and not HalfToEven then
        Rescaled := -1
      else
        Rescaled := 0;
    end
  else
    begin
      Divisor := IE10[FromScale - ToScale];
      Rescaled := Value div Divisor;
      Remainder := (Value mod Divisor) * 2;
      RoundHalfAway := not HalfToEven or Odd(Rescaled);
      if (Remainder > Divisor) or (Remainder = Divisor) and RoundHalfAway then
        Inc(Rescaled)
      else if (Remainder < -Divisor) or (Remainder = -Divisor) and RoundHalfAway then
        Dec(Rescaled);
    end;
end;

function ExtendedToScaledInt64(Value: Extended; Scale: Integer; var Scaled: Int64): Boolean;
const
  // 2^63, exact in floating point
  Int64Limit = 9223372036854775808.0;
var
  Product, IntegerPart: Extended;
begin
  Product := Value * E10[Scale];
  Result := (Product > -2 * Int64Limit) and (Product < 2 * Int64Limit);
  if not Result then
    Exit;
  IntegerPart := Int(Product);
  if Product - IntegerPart >= 0.5 then
    IntegerPart := IntegerPart + 1
  else if Product - IntegerPart <= -0.5 then
    IntegerPart := IntegerPart - 1;
  Result := (IntegerPart >= -Int64Limit) and (IntegerPart < Int64Limit);
  if Result then
    Scaled := Trunc(IntegerPart);
end;

// The format of CurrToStrF for FormatNumericString
function CurrToStrFFormat(Format: TFloatFormat; Digits: Integer): string;
var
  Number, Symbol, Positive, Negative: string;
begin
  Number := '0';
  if Digits > 0 then
    Number := Number + '.' + StringOfChar('0', Digits);
  if Format <> ffCurrency then
    Exit(Number);
  Number := '#,##' + Number;
{$IFDEF C24}with FormatSettings do {$ENDIF}
  begin
    if Pos('"', CurrencyString) = 0 then
      Symbol := '"' + CurrencyString + '"'
    else
      Symbol := '''' + CurrencyString + '''';
    case CurrencyFormat of
      0: Positive := Symbol + Number;
      1: Positive := Number + Symbol;
      2: Positive := Symbol + ' ' + Number;
    else
      Positive := Number + ' ' + Symbol;
    end;
    case NegCurrFormat of
      0: Negative := '(' + Symbol + Number + ')';
      2: Negative := Symbol + '-' + Number;
      3: Negative := Symbol + Number + '-';
      4: Negative := '(' + Number + Symbol + ')';
      5: Negative := '-' + Number + Symbol;
      6: Negative := Number + '-' + Symbol;
      7: Negative := Number + Symbol + '-';
      8: Negative := '-' + Number + ' ' + Symbol;
      9: Negative := '-' + Symbol + ' ' + Number;
      10: Negative := Number + ' ' + Symbol + '-';
      11: Negative := Symbol + ' ' + Number + '-';
      12: Negative := Symbol + ' -' + Number;
      13: Negative := Number + '- ' + Symbol;
      14: Negative := '(' + Symbol + ' ' + Number + ')';
      15: Negative := '(' + Number + ' ' + Symbol + ')';
    else
      Negative := '-' + Symbol + Number;
    end;
  end;
  Result := Positive + ';' + Negative;
end;

function ScaledCurrToStrF(Value: Int64; Scale: Integer; Format: TFloatFormat; Digits: Integer): string;
var
  Rounded: Int64;
  Places: Integer;
begin
  // half to even, as CurrToStrF
  Places := Min(Max(Digits, 0), 4);
  if Scale > Places then
    RescaleInt64(Value, Scale, Places, Rounded, True)
  else
  begin
    Rounded := Value;
    Places := Scale;
  end;
  // Currency has 4 decimals
  if ((Digits <= 4) or (Scale <= 4)) and RescaleInt64(Rounded, Places, 4, Rounded) then
    Result := CurrToStrF(PCurrency(@Rounded)^, Format, Digits)
  else
{$IFDEF C24}with FormatSettings do {$ENDIF}
    Result := FormatNumericString(CurrToStrFFormat(Format, Digits),
      Int64WithScaleToStr(Value, Scale, DecimalSeparator));
end;

function BCDToInt64WithScale(BCD: TBCD; var Value: Int64; var Scale: Byte): Boolean;
var
  Places, FirstDecimal, I, Digit: Integer;

  // Low(Int64) with one decimal less, rounded half away from zero
  function DropLastDecimal: Boolean;
  begin
    Result := Scale > 0;
    if Result then
    begin
      Value := Low(Int64) div 10 - 1;
      Dec(Scale);
    end;
  end;

begin
  Result := True;
  Value := 0;
  Scale := 0;
  // zero precision or null
  if (BCD.Precision = 0) or (BCD.SignSpecialPlaces and $40 <> 0) then
    Exit;
  Places := BCD.SignSpecialPlaces and $3F;
  Scale := Byte(Places);
  FirstDecimal := BCD.Precision - Places;
  // accumulated negative, so that Low(Int64) fits
  for I := 0 to BCD.Precision - 1 do
  begin
    if Odd(I) then
      Digit := BCD.Fraction[I div 2] and $0F
    else
      Digit := BCD.Fraction[I div 2] shr 4;
    if Value >= (Low(Int64) + Digit) div 10 then
      Value := Value * 10 - Digit
    else if I < FirstDecimal then
      Exit(False)
    else
    begin
      // decimals that don't fit: round half away from zero at this digit
      Scale := Byte(I - FirstDecimal);
      if Digit >= 5 then
        if Value > Low(Int64) then
          Dec(Value)
        else if not DropLastDecimal then
          Exit(False);
      Break;
    end;
  end;
  if BCD.SignSpecialPlaces and $80 = 0 then
    if (Value > Low(Int64)) or DropLastDecimal then
      Value := -Value
    else
      Result := False;
end;

// True when the decimal Value from Start has only zeros, as 0.000
function IsZeroDecimal(const Value: string; Start: Integer; DecimalSeparator: Char): Boolean;
var
  I: Integer;
begin
  Result := Start <= Length(Value);
  for I := Start to Length(Value) do
    if (Value[I] <> '0') and (Value[I] <> DecimalSeparator) then
      Exit(False);
end;

// The digits of the unsigned Value from Start rounded half to even to Decimals digits, as FormatCurr
// rounds, without the leading and trailing zeros, and the number of integer digits as FloatToDecimal
// gives it (1.296 to 2 digits: 13, 1; 0.004: none, 0)
procedure RoundDecimalDigits(const Value: string; Start, Decimals: Integer; DecimalSeparator: Char;
  var Digits: string; var Exponent: Integer);
var
  SeparatorPos, IntegerCount, DecimalCount, Next, First, Last, I: Integer;
  Carry: Boolean;
begin
  SeparatorPos := Start;
  while (SeparatorPos <= Length(Value)) and (Value[SeparatorPos] <> DecimalSeparator) do
    Inc(SeparatorPos);
  IntegerCount := SeparatorPos - Start;
  DecimalCount := Max(Min(Length(Value) - SeparatorPos, Decimals), 0);
  // Digits[1] takes the carry of 9.996 -> 10.00
  SetLength(Digits, IntegerCount + DecimalCount + 1);
  Digits[1] := '0';
  if IntegerCount > 0 then
    Move(Value[Start], Digits[2], IntegerCount * SizeOf(Char));
  if DecimalCount > 0 then
    Move(Value[SeparatorPos + 1], Digits[IntegerCount + 2], DecimalCount * SizeOf(Char));
  Carry := False;
  Next := SeparatorPos + Decimals + 1;
  if Next <= Length(Value) then
    if Value[Next] = '5' then
    begin
      I := Next + 1;
      while (I <= Length(Value)) and (Value[I] = '0') do
        Inc(I);
      // a tie rounds up only an odd last digit
      Carry := (I <= Length(Value)) or Odd(Ord(Digits[Length(Digits)]));
    end
    else
      Carry := Value[Next] > '5';
  I := Length(Digits);
  while Carry do
  begin
    if Digits[I] < '9' then
    begin
      Digits[I] := Succ(Digits[I]);
      Carry := False;
    end
    else
      Digits[I] := '0';
    Dec(I);
  end;
  Exponent := IntegerCount + 1;
  First := 1;
  Last := Length(Digits);
  while (First <= Last) and (Digits[First] = '0') do
  begin
    Inc(First);
    Dec(Exponent);
  end;
  while (Last >= First) and (Digits[Last] = '0') do
    Dec(Last);
  if Last < First then
  begin
    Digits := '';
    Exponent := 0;
  end
  else
    Digits := Copy(Digits, First, Last - First + 1);
end;

type
  // The placeholders of a one section numeric format, as FormatFloat scans them
  TNumericFormatScan = record
    DigitCount: Integer;
    DecimalIndex: Integer;
    IntegerZeros: Integer;
    DecimalZeros: Integer;
    ThousandSep: Boolean;
    // an unquoted E+, E-, e+ or e-
    Scientific: Boolean;
  end;

// Position after the quoted text that starts at Start
function SkipFormatQuote(const Format: string; Start: Integer): Integer;
begin
  Result := Start + 1;
  while (Result <= Length(Format)) and (Format[Result] <> Format[Start]) do
    Inc(Result);
  if Result <= Length(Format) then
    Inc(Result);
end;

// Position of the ';' that ends the format section starting at Start, or Length + 1
function NumericFormatSectionEnd(const Format: string; Start: Integer): Integer;
begin
  Result := Start;
  while (Result <= Length(Format)) and (Format[Result] <> ';') do
    if CharInSet(Format[Result], ['''', '"']) then
      Result := SkipFormatQuote(Format, Result)
    else
      Inc(Result);
end;

// The placeholders of the format section from Start to Stop - 1
procedure ScanNumericFormat(const Format: string; Start, Stop: Integer; var Scan: TNumericFormatScan);
var
  I, FirstZero, LastZero: Integer;
begin
  Scan.DigitCount := 0;
  Scan.DecimalIndex := -1;
  FirstZero := MaxInt;
  LastZero := 0;
  Scan.ThousandSep := False;
  Scan.Scientific := False;
  I := Start;
  while I < Stop do
    if CharInSet(Format[I], ['''', '"']) then
      I := SkipFormatQuote(Format, I)
    else
    begin
      case Format[I] of
        '#':
          Inc(Scan.DigitCount);
        '0':
          begin
            if Scan.DigitCount < FirstZero then
              FirstZero := Scan.DigitCount;
            Inc(Scan.DigitCount);
            LastZero := Scan.DigitCount;
          end;
        '.':
          if Scan.DecimalIndex = -1 then
            Scan.DecimalIndex := Scan.DigitCount;
        ',':
          Scan.ThousandSep := True;
        'E', 'e':
          if (I + 1 < Stop) and CharInSet(Format[I + 1], ['+', '-']) then
            Scan.Scientific := True;
      end;
      Inc(I);
    end;
  if Scan.DecimalIndex = -1 then
    Scan.DecimalIndex := Scan.DigitCount;
  // the integer and decimal digits always written ('0' placeholders)
  Scan.IntegerZeros := Max(Scan.DecimalIndex - FirstZero, 0);
  Scan.DecimalZeros := Max(LastZero - Scan.DecimalIndex, 0);
end;

function FormatNumericString(const Format, Source: string; OneSectionFormat: Boolean = False): string;
var
  Scan: TNumericFormatScan;
  Digits: string;
  DecimalSep, ThousandsSep: Char;
  HasSections, UseNegativeSection: Boolean;
  SourceStart, Start, Stop, PositiveStop, NegativeStop, ZeroStart, ZeroStop: Integer;
  Exponent, Len, DigitIndex, DigitDelta, DigitPlace, I, L: Integer;

  procedure Append(C: Char);
  begin
    if Len = Length(Result) then
      SetLength(Result, Len * 2 + 16);
    Inc(Len);
    Result[Len] := C;
  end;

  procedure AppendFormatText(First, Count: Integer);
  begin
    if Count <= 0 then
      Exit;
    if Len + Count > Length(Result) then
      SetLength(Result, (Len + Count) * 2);
    Move(Format[First], Result[Len + 1], Count * SizeOf(Char));
    Inc(Len, Count);
  end;

  procedure WriteDigit(Digit: Char);
  begin
    if DigitPlace = 0 then
      Append(DecimalSep);
    Append(Digit);
    Dec(DigitPlace);
    if Scan.ThousandSep and (DigitPlace > 1) and (DigitPlace mod 3 = 0) then
      Append(ThousandsSep);
  end;

  procedure AddDigit;
  begin
    if DigitIndex <= Length(Digits) then
    begin
      WriteDigit(Digits[DigitIndex]);
      Inc(DigitIndex);
    end
    else if DigitPlace <= -Scan.DecimalZeros then
      Dec(DigitPlace)
    else
      WriteDigit('0');
  end;

  // a '0' or '#' placeholder; the integer digits beyond the placeholders go at the first one
  procedure PutFormatDigit;
  begin
    if DigitDelta < 0 then
    begin
      Inc(DigitDelta);
      if DigitPlace <= Scan.IntegerZeros then
        WriteDigit('0')
      else
        Dec(DigitPlace);
    end
    else
    begin
      while DigitDelta > 0 do
      begin
        AddDigit;
        Dec(DigitDelta);
      end;
      AddDigit;
    end;
  end;

  // FormatFloat of the section: digits beyond Extended don't show in scientific notation; a value
  // that rounds to zero in its section is written as zero, as by FormatFloat
  function FormatScientific(RoundsToZero: Boolean): string;
  var
    Value: Extended;
  begin
    if RoundsToZero then
      Value := 0
    else
      Value := StrToFloat(Source);
    // only the first section writes the sign
    if (Start > 1) or OneSectionFormat then
      Value := Abs(Value);
    Result := FormatFloat(Copy(Format, Start, Stop - Start), Value);
  end;

begin
  if Source = '' then
    Exit('');
{$IFDEF C24}with FormatSettings do {$ENDIF}
  begin
    DecimalSep := DecimalSeparator;
    ThousandsSep := ThousandSeparator;
  end;
  if CharInSet(Source[1], ['+', '-']) then
    SourceStart := 2
  else
    SourceStart := 1;

  Start := 1;
  Stop := Length(Format) + 1;
  PositiveStop := Stop;
  ZeroStart := 0;
  ZeroStop := 0;
  UseNegativeSection := False;
  HasSections := False;
  if not OneSectionFormat then
  begin
    PositiveStop := NumericFormatSectionEnd(Format, 1);
    HasSections := PositiveStop <= Length(Format);
    if HasSections then
    begin
      // as FormatCurr: an empty section falls back to the first one (keeping the sign for a
      // negative value), and a value that rounds to zero takes the zero section
      NegativeStop := NumericFormatSectionEnd(Format, PositiveStop + 1);
      ZeroStart := NegativeStop + 1;
      ZeroStop := NumericFormatSectionEnd(Format, ZeroStart);
      UseNegativeSection := (Source[1] = '-') and (NegativeStop > PositiveStop + 1);
      if (ZeroStop > ZeroStart) and IsZeroDecimal(Source, SourceStart, DecimalSep) then
      begin
        Start := ZeroStart;
        Stop := ZeroStop;
      end
      else if UseNegativeSection then
      begin
        Start := PositiveStop + 1;
        Stop := NegativeStop;
      end
      else
        Stop := PositiveStop;
    end;
  end;
  // an empty format or section: the general format
  if Start >= Stop then
    Exit(Source);
  ScanNumericFormat(Format, Start, Stop, Scan);
  if Scan.Scientific then
    Exit(FormatScientific(False));
  RoundDecimalDigits(Source, SourceStart, Scan.DigitCount - Scan.DecimalIndex, DecimalSep, Digits, Exponent);
  if HasSections and (Digits = '') then
  begin
    if ZeroStop > ZeroStart then
    begin
      Start := ZeroStart;
      Stop := ZeroStop;
    end
    else
    begin
      Start := 1;
      Stop := PositiveStop;
    end;
    if Start >= Stop then
      Exit(Source);
    ScanNumericFormat(Format, Start, Stop, Scan);
    if Scan.Scientific then
      Exit(FormatScientific(True));
  end;

  Len := 0;
  SetLength(Result, Stop - Start + Length(Source) + 8);
  if (Source[1] = '-') and (Digits <> '') and not (OneSectionFormat or UseNegativeSection) then
    Append('-');
  DigitDelta := Exponent - Scan.DecimalIndex;
  if DigitDelta >= 0 then
    DigitPlace := Exponent
  else
    DigitPlace := Scan.DecimalIndex;
  DigitIndex := 1;
  I := Start;
  while I < Stop do
    case Format[I] of
      '0', '#':
        begin
          PutFormatDigit;
          Inc(I);
        end;
      '.', ',':
        Inc(I);
      '''', '"':
        begin
          L := SkipFormatQuote(Format, I);
          // the text up to the closing quote, or to the end
          if (L - 1 > I) and (Format[L - 1] = Format[I]) then
            AppendFormatText(I + 1, L - I - 2)
          else
            AppendFormatText(I + 1, L - I - 1);
          I := L;
        end;
    else
      Append(Format[I]);
      Inc(I);
    end;
  SetLength(Result, Len);
end;

function BCDToExtended(BCD: TBCD; var Value: Extended): Boolean;
var
  c: Int64;
  Scale: Byte;
  Places, I: Integer;
begin
  Result := True;
  if BCDToInt64WithScale(BCD, c, Scale) then
  begin
    Value := c;
    Places := Scale;
  end
  else
  begin
    // the integer part doesn't fit Int64: all digits, approximate
    Value := 0;
    for I := 0 to BCD.Precision - 1 do
      if Odd(I) then
        Value := Value * 10 + (BCD.Fraction[I div 2] and $0F)
      else
        Value := Value * 10 + (BCD.Fraction[I div 2] shr 4);
    if BCD.SignSpecialPlaces and $80 <> 0 then
      Value := -Value;
    Places := BCD.SignSpecialPlaces and $3F;
  end;
  // E10 holds 18 decimals; Value / 10^n rounds once, Value * 10^-n twice (3 * 0.1 <> 0.3)
  while Places > High(E10) do
  begin
    Value := Value / E10[High(E10)];
    Dec(Places, High(E10));
  end;
  Value := Value / E10[Places];
end;

function BCDToSQLStr(BCD: TBCD): String;
var
  pd: Integer;
begin
  Result := BCDToStr(BCD);
{$IFDEF C24}with FormatSettings do {$ENDIF}
    if DecimalSeparator <> '.' then
    begin
      pd := Pos(DecimalSeparator, Result);
      if pd > 0 then
        Result[pd] := '.';
    end;
end;

function CompareBCD(const BCD1, BCD2: TBCD): Integer;
begin
  Result := BcdCompare(BCD1, BCD2);
end;

function Int64WithScaleToStr(Value: Int64; Scale: Integer; DSep: Char): string;
var
  i, j: Integer;
  IntStr, DecStr: string;
  Sign: string;
begin
  if Value = 0 then
  begin
    Result := '0';
    Exit;
  end;
  Result := IntToStr(Value);
  if Scale > 0 then
  begin
    if Result[1] = '-' then
    begin
      Sign := '-';
      Delete(Result, 1, 1);
    end
    else
      Sign := '';
    j := Length(Result) - Scale;
    if j > 0 then
    begin
      IntStr := Sign + FastCopy(Result, 1, j);
      DecStr := FastCopy(Result, j + 1, Length(Result));
    end
    else
    begin
      IntStr := Sign + '0';
      DecStr := MakeStr('0', -j) + Result;
    end;
    Result := IntStr + DSep + DecStr;
    i := Length(Result);
    while Result[i] = '0' do
    begin
      Dec(i);
      if Result[i] = DSep then
      begin
        Dec(i);
        Break;
      end;
    end;
    Delete(Result, i + 1, Length(Result));
  end;
end;

function Max(n1, n2: Integer): Integer;
begin
  if (n1 > n2) then
    Result := n1
  else
    Result := n2;
end;

function Min(n1, n2: Integer): Integer;
begin
  if (n1 < n2) then
    Result := n1
  else
    Result := n2;
end;

function RandomInteger(iLow, iHigh: Integer): Integer;
begin
  Result := Random(iHigh - iLow) + iLow;
end;

function RandomString(iLength: Integer): String;
begin
  Result := '';
  while Length(Result) < iLength do
    Result := Result + IntToStr(RandomInteger(0, High(Integer)));
  if Length(Result) > iLength then
    Result := FastCopy(Result, 1, iLength);
end;

function StripString(const st: String; const CharsToStrip: String): String;
begin
  if Pos(CharsToStrip, st) = 0 then
    Result := st
  else
    Result := ReplaceStr(st, CharsToStrip, '');
end;

var
  Bits: array [0 .. 7] of Byte = (
    1,
    2,
    4,
    8,
    16,
    32,
    64,
    128
  );

function GetBit(InByte: Byte; Index: Byte): Boolean;
begin
  Result := Boolean(InByte shr Index and 1)
end;

function SetBit(InByte: Byte; Index: Byte; Value: Boolean): Byte;
begin
  if Value then
    Result := InByte or Bits[Index]
  else
    Result := InByte and not Bits[Index]
end;

initialization

Randomize;

end.
