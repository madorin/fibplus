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

{$I FIBPlus.inc}

interface

uses

  Classes, SysUtils, DB, FIBSafeTimer
{$IFDEF WINDOWS}, Windows {$ENDIF}
    , FMTBcd, Variants;

type
  EParserError = class(Exception);
  TCharSet = set of AnsiChar;
  TDynArray = array of variant;
  PDynArray = ^TDynArray;

  TFIBTimer = TFIBCustomTimer;

function ConvertFromBase(sNum: String; iBase: Integer; cDigits: String): Integer;
function ConvertToBase(iNum, iBase: Integer; cDigits: String): String;

function Max(n1, n2: Integer): Integer;
function MaxD(n1, n2: Double): Double;
function Min(n1, n2: Integer): Integer; {$IFDEF D2005+} inline; {$ENDIF}
function MinD(n1, n2: Double): Double;
function Signum(Arg: Integer): Integer; {$IFDEF D2005+} inline; {$ENDIF}
function RandomString(iLength: Integer): String;
// function RandomInteger(iLow, iHigh: Integer): Integer;
function Soundex(st: String): String;
function StripString(const st: String; const CharsToStrip: String): String;
function ClosestWeekday(const d: TDateTime): TDateTime;
function Year(d: TDateTime): Integer;
function Month(d: TDateTime): Integer;
function DayOfYear(d: TDateTime): Integer;
function DayOfMonth(d: TDateTime): Integer;

procedure WeekOfYear(d: TDateTime; var Year, Week: Integer);
function Degree10(Degree: Integer): Extended; {$IFDEF D2005+} inline; {$ENDIF}
function ExtPrecision(Value: Extended): Integer; {$IFDEF D2005+} inline; {$ENDIF}
function RoundExtend(Value: Extended; Decimals: Integer): Extended;

// Comp type stuff

function Int64WithScaleToStr(Value: Int64; Scale: Integer; DSep: Char): string; overload;
function ExtendedToBCD(const Value: Extended; NeedScale: Integer): TBCD;

// end Comp type stuff

function Int64ToBCD(Value: Int64; Scale: Integer; var BCD: TBCD): Boolean;
// {$IFDEF D2005+} inline;{$ENDIF}

function BCDToExtended(BCD: TBCD; var Value: Extended): Boolean;
function BCDToCompWithScale(BCD: TBCD; var Value: Int64; var Scale: byte): Boolean;
function BCDToInt64WithScale(BCD: TBCD; var Value: Int64; var Scale: byte): Boolean;
function BCDToSQLStr(BCD: TBCD): String;
function CompareBCD(const BCD1, BCD2: TBCD): Integer; {$IFDEF D2005+} inline; {$ENDIF}
function fFormatBcd(const Format: string; BCD: TBCD): string;
function FormatNumericString(const Format, Source: string; OneSectionFormat: Boolean = False): string;

function TimeStamp(const aDate, aTime: Integer): TTimeStamp;
function CmpFullName(cmp: TComponent): string;
function CmpInLoadedState(cmp: TComponent): Boolean; {$IFDEF D2005+} inline; {$ENDIF}
procedure FullClearStrings(aStrings: TStrings);

function HookTimeStampToMSecs(const TimeStamp: TTimeStamp): Int64;
function HookTimeStampToDateTime(const TimeStamp: TTimeStamp): TDateTime;
function IBStrToTime(const Str: string): TDateTime;

function IntDateToDateTime(aDate: Integer): TDateTime;
// DB rtns

function FieldOldValAsString(Field: TField; SQLFormat: Boolean): string;

function BCDFieldAsSQLString(Field: TField; OldVal: Boolean): variant;
function BCDFieldAsString(Field: TField; OldVal: Boolean): variant;
function GetBCDFieldData(Field: TField; OldVal: Boolean; var BCD: TBCD): Boolean;

function GetBit(InByte: byte; Index: byte): Boolean; {$IFDEF D2005+} inline; {$ENDIF}
function SetBit(InByte: byte; Index: byte; Value: Boolean): byte;

function HexStr2Int(const S: String): Integer;
function HexStr2IntStr(const S: String): string;

procedure InitFPU;

procedure StreamToVariant(Stream: TMemoryStream; var Value: variant);
procedure StreamToVariantArray(Stream: TMemoryStream; var Value: variant);
function VariantToStream(Value: variant; Stream: TStream): Integer;
{ Length of Blob }

function StringIsDateTimeDefValue(const S: string): Boolean; {$IFDEF D2005+} inline; {$ENDIF}

var
  TempPath: PAnsiChar;
  TempPathLength: Integer;

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

implementation

uses
  FIBConsts, StrUtil;

procedure StreamToVariantArray(Stream: TMemoryStream; var Value: variant);
var
  i: Integer;
begin
  for i := 0 to Stream.Size - 1 do
    PByte(LongInt(TVarData(Value).VArray^.Data) + i)^ := PByte(LongInt(Stream.Memory) + i)^;
end;

procedure StreamToVariant(Stream: TMemoryStream; var Value: variant);
var
  i: Integer;
  vt: TVarType;
begin
  VarClear(Value);
  if Stream.Size > 0 then
  begin
    Stream.Position := 0;
    vt := varByte;
    Value := VarArrayCreate([0, Stream.Size - 1], vt);
    for i := 0 to Stream.Size - 1 do
      PByte(LongInt(TVarData(Value).VArray^.Data) + i)^ := PByte(LongInt(Stream.Memory) + i)^;
  end;
end;

function VariantToStream(Value: variant; Stream: TStream): Integer;
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
      Result := Stream.Size;
    end;
  end;
end;

function StringIsDateTimeDefValue(const S: string): Boolean;
begin
  Result := False;
  if Length(S) > 0 then
    case S[1] of
      'C': Result := (S = 'CURRENT_TIME') or (S = 'CURRENT_TIMESTAMP') or (S = 'CURRENT_DATE');
      'L': Result := (S = 'LOCALTIME') or (S = 'LOCALTIMESTAMP');
      'N': Result := (S = 'NULL') or (S = 'NOW');
      'T': Result := (S = 'TODAY') or (S = 'TOMORROW');
      'Y': Result := (S = 'YESTERDAY');
    end;
end;

type
  THackDS = class(TDataSet);

function FieldOldValAsString(Field: TField; SQLFormat: Boolean): string;
var
  OldState: TDataSetState;
begin
  OldState := Field.DataSet.State;
  try
    THackDS(Field.DataSet).SetTempState(dsOldValue);
    Result := Field.AsString;
  finally
    THackDS(Field.DataSet).RestoreState(OldState);
  end;
{$IFDEF D_XE3}with FormatSettings do {$ENDIF}
    if SQLFormat and (DecimalSeparator <> '.') then
      ReplaceStr(Result, DecimalSeparator, '.')
end;

function GetBCDFieldData(Field: TField; OldVal: Boolean; var BCD: TBCD): Boolean;
var
  OldState: TDataSetState;
begin
  OldState := Field.DataSet.State;
  with THackDS(Field.DataSet) do
    try
      if OldVal and (OldState <> dsOldValue) then
        SetTempState(dsOldValue);
      Result := GetFieldData(Field, @BCD);
    finally
      if OldVal and (OldState <> dsOldValue) then
        RestoreState(OldState);
    end;
end;

function InternalBCDFieldAsString(Field: TField; OldVal, SQLFormat: Boolean): variant;
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

function BCDFieldAsSQLString(Field: TField; OldVal: Boolean): variant;
begin
  Result := InternalBCDFieldAsString(Field, OldVal, true)
end;

function BCDFieldAsString(Field: TField; OldVal: Boolean): variant;
begin
  Result := InternalBCDFieldAsString(Field, OldVal, False)
end;

//
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

function HookTimeStampToMSecs(const TimeStamp: TTimeStamp): Int64;
var
  t: TTimeStamp;
  c: Comp;
begin
  if TimeStamp.Date = 0 then
  begin
    t.Date := 1;
    t.Time := TimeStamp.Time;
    c := TimeStampToMSecs(t) - 86400000;
  end
  else
    c := TimeStampToMSecs(TimeStamp);
  Result := PInt64(@c)^
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

function IBStrToTime(const Str: string): TDateTime;
var
  t: TTimeStamp;
begin
  Result := StrToTime(Str);
  t := DateTimeToTimeStamp(Result);
  t.Date := 0;
  Result := HookTimeStampToDateTime(t);
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

procedure FullClearStrings(aStrings: TStrings);
var
  j: Integer;
begin
  with aStrings do
    for j := 0 to Pred(aStrings.Count) do
    begin
      if Objects[j] <> nil then
        Objects[j].Free;
    end;
  aStrings.Clear;
end;

function Degree10(Degree: Integer): Extended;
begin
  Result := E10[Degree]
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
  // Pr:Integer;
  c: Comp;
begin
  // Pr:=ExtPrecision(Value);
  c := Value * E10[NeedScale];
  Int64ToBCD(PInt64(@c)^, NeedScale, Result);
end;

procedure PutTwoBcdDigits(const Nibble1, Nibble2: byte; var BCD: TBCD; Digit: Integer);
var
  B: byte;
begin
  B := Nibble1 SHL 4;
  B := B OR (Nibble2 AND 15);
  BCD.Fraction[Digit div 2] := B;
end;

{$IFDEF D_XE2}
// CUT FROM Delphi XE

function CurrToBCD(const Curr: Currency; var BCD: TBCD; Precision: Integer = 32; Decimals: Integer = 4): Boolean;
var
  Temp: Currency;
  BcdIndex, StrIndex, StartPos, Digits: Integer;
  B1, B2, DotPos: byte;
  BcdStr: string;
  Dot: Char;

  function GetNextByte(): byte;
  begin
    Result := 0;
    if BcdIndex < StartPos then
      Exit;
    if (StrIndex <= Digits) and (BcdStr[StrIndex] = Dot) then
      Inc(StrIndex);
    if StrIndex <= Digits then
    begin
      Result := byte(BcdStr[StrIndex]) - 48;
      Inc(StrIndex);
    end;
  end;

begin
  Dot := FormatSettings.DecimalSeparator;
  BCD.Precision := Precision;
  BCD.SignSpecialPlaces := Decimals;
  for BcdIndex := 0 to 31 do
    BCD.Fraction[BcdIndex] := 0;
  if Curr = 0 then
  begin
    Result := true;
    Exit;
  end;
  if Curr < 0 then
    Temp := -Curr
  else
    Temp := Curr;
  BcdStr := CurrToStr(Temp);
  Digits := Length(BcdStr);
  DotPos := Pos(Dot, BcdStr);
  if DotPos > 0 then
    StartPos := Precision - ((DotPos - 1) + Decimals)
  else
    StartPos := Precision - (Digits + Decimals);
  StrIndex := 1;
  BcdIndex := 0;
  while BcdIndex < Precision do
  begin
    B1 := GetNextByte();
    Inc(BcdIndex);
    B2 := GetNextByte();
    PutTwoBcdDigits(B1, B2, BCD, BcdIndex - 1);
    Inc(BcdIndex);
  end;
  if Curr < 0 then
    BCD.SignSpecialPlaces := (BCD.SignSpecialPlaces and 63) or (1 shl 7);
  Result := true;
end;

function GetBcdDigit(const BCD: TBCD; Digit: Integer): byte;
begin
  if Digit mod 2 = 0 then
    Result := byte((BCD.Fraction[Digit div 2]) SHR 4)
  else
    Result := byte(byte((BCD.Fraction[Digit div 2]) AND 15));
end;

const
  DValue: array [-10 .. 20] of Currency = (0, 0, 0, 0, 0, 0, 0, 0.0001, 0.001,
    0.01, 0.1, 1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000,
    1000000000, 10000000000, 100000000000, 1000000000000, 10000000000000,
    100000000000000, 0, 0, 0, 0, 0);

  { Currency Value of a Byte for a specific digit column }
function PutCurrencyDigit(Value: byte; Digit: Integer): Currency;
begin
  Result := DValue[Digit] * Value;
end;

function BCDToCurr(const BCD: TBCD; var Curr: Currency): Boolean;
var
  Scale, i: Integer;
  Negative: Boolean;
  B: byte;
begin
  Curr := 0;
  Negative := (BCD.SignSpecialPlaces and (1 shl 7)) <> 0;
  Scale := (BCD.SignSpecialPlaces and 63);
  for i := 0 to BCD.Precision - 1 do
  begin
    B := GetBcdDigit(BCD, i);
    if B <> 0 then
      Curr := Curr + PutCurrencyDigit(B, BCD.Precision - (Scale + i));
  end;
  if Scale > 4 then
  begin { 0.12345 = 0.1234, but 0.123450000001 is rounded up to 0.1235 }
    B := GetBcdDigit(BCD, 4 + (BCD.Precision - Scale));
    if B >= 5 then
      if B > 5 then
        Curr := Curr + 0.0001
      else
        for i := 5 + (BCD.Precision - Scale) to BCD.Precision - 1 do
          if GetBcdDigit(BCD, i) <> 0 then
          begin
            Curr := Curr + 0.0001;
            Break;
          end;
  end;
  if Negative then
    Curr := -Curr;
  Result := true;
end;

{$ENDIF}

function Int64ToBCD(Value: Int64; Scale: Integer; var BCD: TBCD): Boolean;
var
  c: Currency;
begin
  PInt64(@c)^ := Value;
  Result := CurrToBCD(c, BCD);
  with BCD do
  begin
    if Value < 0 then
      SignSpecialPlaces := 128
    else
      SignSpecialPlaces := 0;
    SignSpecialPlaces := Scale + SignSpecialPlaces;
  end;
end;

function BCDToCompWithScale(BCD: TBCD; var Value: Int64; var Scale: byte): Boolean;
begin
  Result := BCDToInt64WithScale(BCD, Value, Scale)
end;

function BCDToInt64WithScale(BCD: TBCD; var Value: Int64; var Scale: byte): Boolean;
var
  Sign: Integer;
  c: Currency;
begin
  with BCD do
  begin
    if Precision = 0 then
    begin
      Result := true;
      Value := 0;
      Exit;
    end;
    if SignSpecialPlaces >= 128 then
    begin
      Sign := -1;
      Scale := SignSpecialPlaces - 128;
    end
    else
    begin
      Sign := 1;
      Scale := SignSpecialPlaces;
    end;
    if Scale >= 64 then
    begin
      // null
      Result := true;
      Value := 0;
      Exit;
    end;
    SignSpecialPlaces := 4;
  end;
  Result := BCDToCurr(BCD, c);
  if Result then
    Value := Sign * PInt64(@c)^;
end;

function BCDToSQLStr(BCD: TBCD): String;
var
  pd: Integer;
begin
  Result := BCDToStr(BCD);
{$IFDEF D_XE3}with FormatSettings do {$ENDIF}
    if DecimalSeparator <> '.' then
    begin
      pd := Pos(DecimalSeparator, Result);
      if pd > 0 then
        Result[pd] := '.';
    end;
end;

const
  ZeroStr = '000000000000000000';

{$IFNDEF D2005+}

function RoundAt(const Value: string; Position: SmallInt): string;

  Procedure RoundChar(const PrevChar: SmallInt; var Carry: Boolean);
  begin
    if Result[PrevChar] in ['0' .. '9'] then
    begin
      if Result[PrevChar] = '9' then
      begin
        Result[PrevChar] := '0';
        Carry := true;
      end
      else
      begin
        Result[PrevChar] := Char(byte(Result[PrevChar]) + 1);
        Carry := False;
      end;
    end;
  end;

var
  c, Dot: Char;
  PrevChar, i, DecPos, DecDigits: SmallInt;
  Carry: Boolean;
  Neg: string;
begin
  Dot := DecimalSeparator;
  if Value[1] = '-' then
  begin
    Result := FastCopy(Value, 2, MaxInt);
    Neg := '-';
  end
  else
  begin
    Result := Value;
    Neg := '';
  end;
  DecPos := Pos(Dot, Result);
  if DecPos > 0 then
    DecDigits := Length(Result) - DecPos
  else
    DecDigits := 0;
  if (DecPos = 0) or (DecDigits <= Position) then
  { nothing to round }
  begin
    Result := Value;
    Exit;
  end;
  if Result[DecPos + Position + 1] < '5' then
  begin
    { no possible rounding required }
    if Position = 0 then
      Result := Neg + Copy(Result, 1, DecPos + Position - 1)
    else
      Result := Neg + Copy(Result, 1, DecPos + Position);
  end
  else
  begin
    Carry := False;
    PrevChar := 1;
    for i := DecPos + DecDigits downto (DecPos + 1 + Position) do
    begin
      c := Result[i];
      PrevChar := i - 1;
      if Result[PrevChar] = Dot then
      begin
        Dec(PrevChar);
        Dec(Position);
      end;
      if (byte(c) >= 53) or Carry then { if '5' or greater }
        RoundChar(PrevChar, Carry);
    end;
    while Carry do
    begin
      if PrevChar >= DecPos then
        Dec(Position);
      Dec(PrevChar);
      if PrevChar = 0 then
        Break;
      if Result[PrevChar] <> Dot then
        RoundChar(PrevChar, Carry);
    end;
    if Carry then
      Result := Neg + '1' + Copy(Result, 1, DecPos + Position)
    else
      Result := Neg + Copy(Result, 1, DecPos + Position);
  end;
end;
{$ENDIF}

function IsZero(const Str: string): Boolean;
var
  i: Integer;
begin
  Result := False;
{$IFDEF D_XE3}with FormatSettings do {$ENDIF}
    for i := 1 to Length(Str) do
    begin
      Result := (Str[i] = '0') or (Str[i] = DecimalSeparator);
      if not Result then
        Exit;
    end;
end;

function FormatNumericString(const Format, Source: string; OneSectionFormat: Boolean = False): string;
type
  TPosType = (pBegin, pBeforeDecimalSep, pAfterDecimalSep, pEnd);

  TLiteral = record
    lBody: string;
    lPos: Integer;
    lPosType: TPosType;
  end;
var
  L, i: Integer;
  NeedDecimalCount: Integer;
  CanHaveDecimalCount: Integer;
  PosDecSepInFormat: Integer;
  PosDecSepInString: Integer;
  vLiterals: array of TLiteral;
const
  cFormatChars = ['#', '0', ',', '.'];

begin
  if Length(Source) = 0 then
  begin
    Result := '';
    Exit;
  end;

  if not OneSectionFormat then
  begin
    i := PosCh(';', Format);
    if i > 0 then
    begin
      case Source[1] of
        '+', '1' .. '9': Result := FormatNumericString(FastCopy(Format, 1, i - 1), Source, true);
      else
        L := PosCh(';', FastCopy(Format, i + 1, MaxInt));
        case Source[1] of
          '0':
            if (L = 0) or not IsZero(Source) then
              Result := FormatNumericString(FastCopy(Format, 1, i - 1), Source, true)
            else
              Result := FormatNumericString(FastCopy(Format, L + i + 1, MaxInt), Source, true)
        else
          if L = 0 then
            Result := FormatNumericString(FastCopy(Format, i + 1, MaxInt), Source, true)
          else
            Result := FormatNumericString(FastCopy(Format, i + 1, L - 1), Source, true)
        end;
      end;
      Exit;
    end;
  end;

  Result := Source;
  L := Length(Format);
{$IFDEF D_XE3}with FormatSettings do {$ENDIF}
    if L > 0 then
    begin
      while (L > 0) and CharInSet(Format[L], [#9, ' ', ';']) do
        Dec(L);
      if L = 0 then
      begin
        Result := '';
        Exit;
      end;
      if not CharInSet(Format[L], cFormatChars) then
      begin
        SetLength(vLiterals, 1);
        vLiterals[0].lBody := '';
        vLiterals[0].lPosType := pEnd;
        i := L;
        while (i > 0) and not CharInSet(Format[i], cFormatChars) do
        begin
          Dec(i);
        end;
        if i = 0 then
        begin
          Result := FastCopy(Format, i + 1, L - i);
          Exit;
        end
        else
          vLiterals[0].lBody := FastCopy(Format, i + 1, L - i);
      end;

      i := 1;
      if (i < L) and not CharInSet(Format[1], cFormatChars) then
      begin
        SetLength(vLiterals, 2);
        vLiterals[1].lBody := '';
        vLiterals[1].lPosType := pBegin;
        while (i < L) and not CharInSet(Format[i], cFormatChars) do
          Inc(i);
        vLiterals[1].lBody := FastCopy(Format, 1, i - 1);
      end;

      PosDecSepInFormat := PosCh('.', Format);
      NeedDecimalCount := 0;
      CanHaveDecimalCount := L - PosDecSepInFormat;
      for i := L downto PosDecSepInFormat do
      begin
        if (NeedDecimalCount = 0) and (Format[i] = '0') then
        begin
          NeedDecimalCount := i - PosDecSepInFormat;
        end
        else if NeedDecimalCount <> 0 then
          if not CharInSet(Format[i], cFormatChars) then
            Dec(NeedDecimalCount);
      end;

      i := PosDecSepInFormat - 1;
      if (i > 1) and not CharInSet(Format[i], cFormatChars) then
      begin
        SetLength(vLiterals, 3);
        vLiterals[2].lPosType := pBeforeDecimalSep;
        while (i > 1) and not CharInSet(Format[i], cFormatChars) do
          Dec(i);
        if i > 1 then
          vLiterals[2].lBody := FastCopy(Format, i + 1, PosDecSepInFormat - i - 1)
        else
          vLiterals[2].lBody := ''
      end;

      i := PosDecSepInFormat + 1;
      if (i < L) and not CharInSet(Format[i], cFormatChars) then
      begin
        SetLength(vLiterals, 4);
        vLiterals[3].lPosType := pAfterDecimalSep;
        while (i < L) and not CharInSet(Format[i], cFormatChars) do
          Inc(i);
        if i < L then
          vLiterals[3].lBody := FastCopy(Format, PosDecSepInFormat + 1, i - PosDecSepInFormat - 1)
        else
          vLiterals[3].lBody := ''
      end;

      PosDecSepInString := Pos(DecimalSeparator, Result);
      if (PosDecSepInString = 0) and (NeedDecimalCount > 0) then
      begin
        Result := Result + DecimalSeparator;
        PosDecSepInString := Length(Result)
      end;
      if (PosDecSepInString > 0) then
      begin
        if Length(Result) - PosDecSepInString < NeedDecimalCount then
        begin
          if NeedDecimalCount > 0 then
            Result := Result + FastCopy(ZeroStr, 1, NeedDecimalCount - (Length(Result) - PosDecSepInString))
        end
        else if Length(Result) - PosDecSepInString > CanHaveDecimalCount then
        begin
          Result := RoundAt(Result, CanHaveDecimalCount)
        end;
      end;
      //
      if Length(vLiterals) > 3 then
      begin
        Result := FastCopy(Result, 1, PosDecSepInString) + vLiterals[3].lBody +
          FastCopy(Result, PosDecSepInString + 1, MaxInt);
      end;

      if Length(vLiterals) > 2 then
      begin
        if PosDecSepInString > 0 then
          Result := FastCopy(Result, 1, PosDecSepInString - 1) + vLiterals[2]
            .lBody + FastCopy(Result, PosDecSepInString, MaxInt)
        else
          Result := Result + vLiterals[2].lBody;
      end;

      if PosCh(',', Format) > 0 then
      begin
        L := 1;
        i := PosDecSepInString - 1;
        if i < 0 then
          i := Length(Result);
{$IFDEF D_XE3}with FormatSettings do {$ENDIF}
          while i > 1 do
          begin
            if L = 3 then
            begin
              if (i <> 2) or not CharInSet(Result[1], ['+', '-']) then
                Result := FastCopy(Result, 1, i - 1) + ThousandSeparator + FastCopy(Result, i, MaxInt);
              L := 0
            end
            else
            begin
              Dec(i);
              Inc(L)
            end;
          end;
      end;
      if Length(vLiterals) > 1 then
        PosDecSepInFormat := PosDecSepInFormat - Length(vLiterals[1].lBody);
      if (PosDecSepInFormat = 1) then
      begin
        if (PosDecSepInString = 2) and (Result[1] = '0') then
          Delete(Result, 1, 1)
        else if (PosDecSepInString = 3) and (Result[1] = '-') and (Result[2] = '0') then
          Delete(Result, 2, 1);
      end;
{$IFDEF D_XE3}with FormatSettings do {$ENDIF}
        if Result[Length(Result)] = DecimalSeparator then
          SetLength(Result, Length(Result) - 1);
      if OneSectionFormat and (Result[1] = '-') then
        Delete(Result, 1, 1);
      if Length(vLiterals) > 0 then
      begin
        Result := Result + vLiterals[0].lBody;
        if Length(vLiterals) > 1 then
        begin
          Result := vLiterals[1].lBody + Result;
        end;
      end;
    end;
end;

function fFormatBcd(const Format: string; BCD: TBCD): string;
begin
  Result := FormatNumericString(Format, BCDToStr(BCD));
end;

function BCDToExtended(BCD: TBCD; var Value: Extended): Boolean;
var
  c: Int64;
  Scale: byte;
begin
  Result := BCDToInt64WithScale(BCD, c, Scale);
  if Result then
    Value := c * E10[-Scale]
end;

function CompareBCD(const BCD1, BCD2: TBCD): Integer;
var
  e1, e2: Extended;
begin
  BCDToExtended(BCD1, e1);
  BCDToExtended(BCD2, e2);
  if e1 = e2 then
    Result := 0
  else if e1 < e2 then
    Result := -1
  else
    Result := 1
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

//
function ConvertFromBase(sNum: String; iBase: Integer; cDigits: String): Integer;
var
  i: Integer;

  function GetValue(c: Char): Integer;
  var
    i: Integer;
  begin
    Result := 0;
    for i := 1 to Length(cDigits) do
      if (cDigits[i] = c) then
      begin
        Result := i - 1;
        Exit;
      end;
  end;

begin
  Result := 0;
  for i := 1 to Length(sNum) do
    Result := (Result * iBase) + GetValue(sNum[i]);
end;

function ConvertToBase(iNum, iBase: Integer; cDigits: String): String;
var
  i, r: Integer;
  S: String;
const
  iLength = 16;
begin
  Result := '';
  SetString(S, nil, iLength);
  i := 0;
  repeat
    r := iNum mod iBase;
    Inc(i);
    if (i > iLength) then
      SetString(S, PChar(S), Length(S) + iLength);
    S[i] := cDigits[r + 1];
    iNum := iNum div iBase;
  until iNum = 0;
  SetString(Result, nil, i);
  for r := 1 to i do
    Result[r] := S[i - r + 1];
end;

function Max(n1, n2: Integer): Integer;
begin
  if (n1 > n2) then
    Result := n1
  else
    Result := n2;
end;

function MaxD(n1, n2: Double): Double;
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

function Signum(Arg: Integer): Integer;
begin
  if Arg > 0 then
    Result := 1
  else if Arg < 0 then
    Result := -1
  else
    Result := 0;
end;

function MinD(n1, n2: Double): Double;
begin
  if (n1 < n2) then
    Result := n1
  else
    Result := n2;
end;

function RandomInteger(iLow, iHigh: Integer): Integer;
begin
  Result := Trunc(Random(iHigh - iLow)) + iLow;
end;

function RandomString(iLength: Integer): String;
begin
  Result := '';
  while Length(Result) < iLength do
    Result := Result + IntToStr(RandomInteger(0, High(Integer)));
  if Length(Result) > iLength then
    Result := FastCopy(Result, 1, iLength);
end;

function Soundex(st: String): String;
var
  code: Char;
  i, j, len: Integer;
begin
  Result := ' 0000';
  if (st = '') then
    Exit;
  Result[1] := UpCase(st[1]);
  j := 2;
  i := 2;
  len := Length(st);
  while (i <= len) and (j < 6) do
  begin
    case st[i] of
      'B', 'F', 'P', 'V', 'b', 'f', 'p', 'v': code := '1';
      'C', 'G', 'J', 'K', 'Q', 'S', 'X', 'Z', 'c', 'g', 'j', 'k', 'q', 's', 'x', 'z': code := '2';
      'D', 'T', 'd', 't': code := '3';
      'L', 'l': code := '4';
      'M', 'N', 'm', 'n': code := '5';
      'R', 'r': code := '6';
    else
      code := '0';
    end; { case }

    if (code <> '0') and (code <> Result[j - 1]) then
    begin
      Result[j] := code;
      Inc(j);
    end;
    Inc(i);
  end;
end;

function StripString(const st: String; const CharsToStrip: String): String;
{ var
  i: Integer; }
begin
  if Pos(CharsToStrip, st) = 0 then
    Result := st
  else
    Result := ReplaceStr(st, CharsToStrip, '');
end;

function ClosestWeekday(const d: TDateTime): TDateTime;
begin
  if (DayOfWeek(d) = 1) then
    Result := d + 1
  else if (DayOfWeek(d) = 7) then
    Result := d + 2
  else
    Result := d;
end;

function Year(d: TDateTime): Integer;
var
  y, m, day: Word;
begin
  DecodeDate(d, y, m, day);
  Result := y;
end;

function Month(d: TDateTime): Integer;
var
  yr, mn, dy: Word;
begin
  DecodeDate(d, yr, mn, dy);
  Result := mn;
end;

function DayOfYear(d: TDateTime): Integer;
var
  yr, mn, dy: Word;
  B: TDateTime;
begin
  DecodeDate(d, yr, mn, dy);
  B := EncodeDate(yr, 1, 1);
  Result := Trunc(d - B);
end;

function DayOfMonth(d: TDateTime): Integer;
var
  yr, mn, dy: Word;
begin
  DecodeDate(d, yr, mn, dy);
  Result := dy;
end;

procedure WeekOfYear(d: TDateTime; var Year, Week: Integer);
var
  yr, mn, dy: Word;
  dow_ybeg: Integer;
  ThisLeapYear, LastLeapYear: Boolean;
begin
  DecodeDate(d, yr, mn, dy);
  // When did the year begin?
  Year := yr;
  dow_ybeg := SysUtils.DayOfWeek(EncodeDate(yr, 1, 1));
  ThisLeapYear := IsLeapYear(yr);
  LastLeapYear := IsLeapYear(yr - 1);
  // Get the Sunday beginning this week.
  Week := (DayOfYear(d) - DayOfWeek(d) + 1);
  (*
    * If the Sunday beginning this week was last year, then
    *   if this year begins on a Wednesday or previous, then
    *     this is most certainly the first week of the year.
    *   if this year begins on a thursday or
    *     last year was a leap year and this year begins on a friday, then
    *     this week is 53 of last year.
    *   Otherwise this week is 52 of last year.
  *)
  if Week <= 0 then
  begin
    if (dow_ybeg <= 4) then
      Week := 1
    else if (dow_ybeg = 5) or (LastLeapYear and (dow_ybeg = 6)) then
    begin
      Week := 53;
      Dec(Year);
    end
    else
    begin
      Week := 52;
      Dec(Year);
    end;
    (* If the Sunday beginning this week falls in this year!!! Yeah
      *   if the year begins on a Sun, Mon, Tue or Wed then
      *     This week # is (Week + 7) div 7
      *   otherwise this week is
      *     Week div 7 + 1.
      *   if the week is > 52 then
      *     if this year began on a wed or this year is leap year and it
      *       began on a tuesday, then set the week to 53.
      *     otherwise set the week to 1 of *next* year.
    *)
  end
  else
  begin
    if (dow_ybeg <= 4) then
      Week := (Week + 6 + dow_ybeg) div 7
    else
      Week := (Week div 7) + 1;
    if Week > 52 then
    begin
      if (dow_ybeg = 4) or (ThisLeapYear and (dow_ybeg = 3)) then
        Week := 53
      else
      begin
        Week := 1;
        Inc(Year);
      end;
    end;
  end;
end;

procedure InitFPU;
var
  Default8087CW: Word;
  asm
    FSTCW Default8087CW
    OR Default8087CW, 0300h
    FLDCW Default8087CW
end;

const
  Hexez: array ['A' .. 'F'] of byte = (10, 11, 12, 13, 14, 15);
  HexezDecimal: array ['0' .. '9'] of byte = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9);

function HexStr2Int(const S: String): Integer;
var
  j: LongInt;
  PStart, pEnd: PChar;
begin
  Result := 0;
  j := 1;
  PStart := Pointer(S);
  pEnd := Pointer(S);
  Inc(pEnd, Length(S) - 1);
  while pEnd >= PStart do
  begin
    case pEnd^ of
      '0': ;
      '1': Inc(Result, j);
      '2': Inc(Result, j * 2);
      '3' .. '9': Inc(Result, j * HexezDecimal[pEnd^]);
      'A' .. 'F': Inc(Result, j * Hexez[pEnd^]);
    end;
    j := j * 16;
    Dec(pEnd)
  end;
end;

function HexStr2IntStr(const S: String): string;
begin
  Result := IntToStr(HexStr2Int(S))
end;

var
  vBits: array [0 .. 7] of byte = (
    1,
    2,
    4,
    8,
    16,
    32,
    64,
    128
  );

function GetBit(InByte: byte; Index: byte): Boolean;
begin
  Result := Boolean(InByte shr Index and 1)
end;

function SetBit(InByte: byte; Index: byte; Value: Boolean): byte;
begin
  if Value then
    Result := InByte or vBits[Index]
  else
    Result := InByte and not vBits[Index]
end;

initialization

Randomize;

end.
