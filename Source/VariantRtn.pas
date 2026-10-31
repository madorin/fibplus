{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ InterBase databases                                           }
{                                                               }
{    FIBPlus is based in part on the product                    }
{    Free IB Components, written by Gregory H. Deatz for        }
{    Hoagland, Longo, Moran, Dunst & Doukas Company.            }
{    mailto:gdeatz@hlmdd.com                                    }
{                                                               }
{    Copyright (c) 1998-2011 Devrace Ltd.                       }
{    Written by Serge Buzadzhy                                  }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit VariantRtn;

interface

{$I FIB.inc}

uses

  SysUtils, FIBPlatforms, Variants;

function EasyCompareVarArray1(FirstArray, SecondArray: Variant; HighBound: Integer): Boolean;

function CompareVariantsEQ(const v, v1: Variant): Boolean;
function CompareVariants(const v, v1: Variant): Integer;

function CompareWideStringAndVariant(P: Pointer; const v: Variant): Integer;

implementation

uses
  FIBConsts;

// CompareRnts
function GetVariantData(const v: Variant): Pointer;
begin
  case TVarData(v).VType of
    varSmallInt: result := @TVarData(v).VSmallInt;
    varInteger: result := @TVarData(v).VInteger;
    varSingle: result := @TVarData(v).VSingle;
    varInt64: result := @TVarData(v).VInt64;

    varShortInt: result := @TVarData(v).VShortInt;
    varWord: result := @TVarData(v).VWord;
    varLongWord: result := @TVarData(v).VLongWord;
    varByte: result := @TVarData(v).VByte;
    varDouble: result := @TVarData(v).VDouble;
    varCurrency: result := @TVarData(v).VCurrency;
    varDate: result := @TVarData(v).VDate;
    varOleStr: result := TVarData(v).VOleStr;
    varBoolean: result := @TVarData(v).VBoolean;
    varVariant, varByRef: result := GetVariantData(PVariant(@TVarData(v).VPointer)^);
    varString: result := TVarData(v).VString;
    varUString: result := TVarData(v).VUString;
  else
    result := nil;
  end;
end;

function CompareAsVariants(const V, V1: Variant): Integer;
begin
  if V = V1 then
    Result := 0
  else
    if V > V1 then
      Result := 1
    else
      Result := -1;
end;

function CompareNumbers(const Value, Number: Extended): Integer;
begin
  if Value = Number then
    Result := 0
  else
    if Value > Number then
      Result := 1
    else
      Result := -1;
end;

// Value rounded to the precision of a Single key
function CompareAsSingles(const Value: Extended; Key: Single): Integer;
const
  MaxSingleValue = 3.4028234663852886e+38;
var
  S: Single;
begin
  if Abs(Value) > MaxSingleValue then
    Result := CompareNumbers(Value, Key)
  else
  begin
    S := Value;
    Result := CompareNumbers(S, Key);
  end;
end;

// Key rounded to the 4 decimals of a Currency value
function CompareAsCurrencies(const Value: Currency; const Key: Extended): Integer;
var
  C: Currency;
begin
  if Abs(Key) >= 922337203685477 then
    Result := CompareNumbers(Value, Key)
  else
  begin
    C := Key;
    if Value = C then
      Result := 0
    else
      if Value > C then
        Result := 1
      else
        Result := -1;
  end;
end;

function CompareTexts(const ValueText, Text: string): Integer;
begin
  Result := AnsiCompareStr(ValueText, Text);
  if Result > 0 then
    Result := 1
  else
    if Result < 0 then
      Result := -1;
end;

// A text that is not a number is compared with the number as text, without raising
function CompareFloatAndText(const Value: Extended; const Text: string): Integer;
var
  Number: Extended;
begin
  if TryStrToFloat(Text, Number) then
    Result := CompareNumbers(Value, Number)
  else
    Result := CompareTexts(FloatToStr(Value), Text);
end;

function CompareInt64AndText(const Value: Int64; const Text: string): Integer;
var
  Number: Int64;
begin
  if TryStrToInt64(Text, Number) then
  begin
    if Value = Number then
      Result := 0
    else
      if Value > Number then
        Result := 1
      else
        Result := -1;
  end
  else
    Result := CompareFloatAndText(Value, Text);
end;

// A text that is neither a number nor a date is compared with the date as text
function CompareDateAndText(const Value: TDateTime; const Text: string): Integer;
var
  Number: Extended;
  Date: TDateTime;
begin
  if TryStrToFloat(Text, Number) then
    Result := CompareNumbers(Value, Number)
  else
    if TryStrToDateTime(Text, Date) then
      Result := CompareNumbers(Value, Date)
    else
      Result := CompareTexts(DateTimeToStr(Value), Text);
end;

{$DEFINE BODY_NUMERIC_COMPARE_EQ}

// P^ holds a value of an integer type up to 32 bits; strings are parsed as floats
function CompareWidenedIntegerAndVariant(P: PInt64; const V: Variant): Integer;
{$I VarFnc.inc}
{$DEFINE C_FLOAT}
function ComparePSingleAndVariant(P: PSingle; const V: Variant): Integer;
{$DEFINE C_SINGLE}
{$I VarFnc.inc}
{$UNDEF C_SINGLE}
function ComparePDoubleAndVariant(P: PDouble; const V: Variant): Integer;
{$I VarFnc.inc}
{$UNDEF C_FLOAT}
function ComparePCurrencyAndVariant(P: PCurrency; const V: Variant): Integer;
{$DEFINE C_CURRENCY}
{$I VarFnc.inc}
{$UNDEF C_CURRENCY}
function ComparePDateAndVariant(P: PDateTime; const V: Variant): Integer;
{$DEFINE C_DATE}
{$I VarFnc.inc}
{$UNDEF C_DATE}
function ComparePInt64AndVariant(P: PInt64; const V: Variant): Integer;
{$DEFINE C_INT64}
{$I VarFnc.inc}
{$UNDEF C_INT64}
{$UNDEF BODY_NUMERIC_COMPARE_EQ}

// the Variant compare of a UInt64 with a negative integer raises an overflow
function CompareUInt64AndVariant(const V, V1: Variant): Integer;
begin
  case TVarData(V1).VType of
    varShortInt, varSmallInt, varInteger, varInt64:
      if V1 < 0 then
      begin
        Result := 1;
        Exit;
      end;
  end;
  Result := CompareAsVariants(V, V1);
end;

function ComparePIntegerAndVariant(P: PInteger; const V: Variant): Integer;
var
  Value: Int64;
begin
  Value := P^;
  Result := CompareWidenedIntegerAndVariant(@Value, V);
end;

function ComparePSmallAndVariant(P: PSmallInt; const V: Variant): Integer;
var
  Value: Int64;
begin
  Value := P^;
  Result := CompareWidenedIntegerAndVariant(@Value, V);
end;

function ComparePByteAndVariant(P: PByte; const V: Variant): Integer;
var
  Value: Int64;
begin
  Value := P^;
  Result := CompareWidenedIntegerAndVariant(@Value, V);
end;

function ComparePShortAndVariant(P: PShortInt; const V: Variant): Integer;
var
  Value: Int64;
begin
  Value := P^;
  Result := CompareWidenedIntegerAndVariant(@Value, V);
end;

function ComparePWordAndVariant(P: PWord; const V: Variant): Integer;
var
  Value: Int64;
begin
  Value := P^;
  Result := CompareWidenedIntegerAndVariant(@Value, V);
end;

function ComparePLongWordAndVariant(P: PLongWord; const V: Variant): Integer;
var
  Value: Int64;
begin
  Value := P^;
  Result := CompareWidenedIntegerAndVariant(@Value, V);
end;

                      function CompareWideStringAndVariantEQ(P: Pointer; const v: Variant): Boolean;
                      begin
                        case VarType(v) of
                          varString: result := WideString(P) = string(AnsiString(TVarData(v).VString));
                          varOleStr: result := WideString(P) = WideString(TVarData(v).VOleStr);
                          varUString: result := WideString(P) = string(TVarData(v).VUString);
                        else
                          result := WideString(P) = VarToStr(v);
                        end;
                      end;

                      function CompareStringAndVariantEQ(P: Pointer; const v: Variant): Boolean;
                      begin
                        case VarType(v) of
                          varString: result := AnsiString(P) = AnsiString(TVarData(v).VString);
                          varOleStr: result := WideString(AnsiString(P)) = WideString(TVarData(v).VOleStr);
                          varUString: result := string(AnsiString(P)) = string(TVarData(v).VUString);
                        else
                          result := string(AnsiString(P)) = VarToStr(v);
                        end;
                      end;

                      function CompareWideStringAndVariant(P: Pointer; const v: Variant): Integer;
                      begin
                        case VarType(v) of
                          varString:
                            begin
                              if WideString(P) = string(AnsiString(TVarData(v).VString)) then
                                result := 0
                              else if WideString(P) > string(AnsiString(TVarData(v).VString)) then
                                result := 1
                              else
                                result := -1;
                            end;
                          varOleStr:
                            begin
                              if WideString(P) = WideString(TVarData(v).VOleStr) then
                                result := 0
                              else if WideString(P) > WideString(TVarData(v).VOleStr) then
                                result := 1
                              else
                                result := -1;
                            end;
                          varUString:
                            begin
                              if WideString(P) = string(TVarData(v).VUString) then
                                result := 0
                              else if WideString(P) > string(TVarData(v).VUString) then
                                result := 1
                              else
                                result := -1;
                            end;
                        else
                          if WideString(P) = VarToStr(v) then
                            result := 0
                          else if WideString(P) > VarToStr(v) then
                            result := 1
                          else
                            result := -1;
                        end;
                      end;

                      // P is the AnsiString of a varString variant: decoded with its code page
                      function CompareStringAndVariant(P: Pointer; const v: Variant): Integer;
                      var
                        s: UnicodeString;
                      begin
                        case VarType(v) of
                          varString:
                            begin
                              if AnsiString(P) = AnsiString(TVarData(v).VString) then
                                result := 0
                              else if AnsiString(P) > AnsiString(TVarData(v).VString) then
                                result := 1
                              else
                                result := -1
                            end;
                          varOleStr:
                            begin
                              if WideString(AnsiString(P)) = WideString(TVarData(v).VOleStr) then
                                result := 0
                              else if WideString(AnsiString(P)) > WideString(TVarData(v).VOleStr) then
                                result := 1
                              else
                                result := -1
                            end;
                          varUString:
                            begin
                              s := UnicodeString(AnsiString(P));
                              if s = UnicodeString(TVarData(v).VUString) then
                                result := 0
                              else
                              begin
                                if s > UnicodeString(TVarData(v).VUString) then
                                  result := 1
                                else
                                  result := -1;
                              end
                            end
                        else
                          if string(AnsiString(P)) = VarToStr(v) then
                            result := 0
                          else if string(AnsiString(P)) > VarToStr(v) then
                            result := 1
                          else
                            result := -1;
                        end;
                      end;

                      function CompareVariants(const v, v1: Variant): Integer;
                      begin
                        case TVarData(v).VType of
                          varSmallInt:
                            result := ComparePSmallAndVariant
                              (GetVariantData(v), v1);
                          varInteger:
                            result := ComparePIntegerAndVariant
                              (GetVariantData(v), v1);
                          varSingle:
                            result := ComparePSingleAndVariant
                              (GetVariantData(v), v1);
                          varDouble:
                            result := ComparePDoubleAndVariant
                              (GetVariantData(v), v1);
                          varCurrency:
                            result := ComparePCurrencyAndVariant
                              (GetVariantData(v), v1);
                          varDate:
                            result := ComparePDateAndVariant
                              (GetVariantData(v), v1);
                          varOleStr:
                            result := CompareWideStringAndVariant
                              (GetVariantData(v), v1);
                          varShortInt:
                            result := ComparePShortAndVariant
                              (GetVariantData(v), v1);
                          varByte:
                            result := ComparePByteAndVariant
                              (GetVariantData(v), v1);
                          varWord:
                            result := ComparePWordAndVariant
                              (GetVariantData(v), v1);
                          varLongWord:
                            result := ComparePLongWordAndVariant
                              (GetVariantData(v), v1);
                          varInt64:
                            result := ComparePInt64AndVariant
                              (GetVariantData(v), v1);
                          varString:
                            result := CompareStringAndVariant
                              (GetVariantData(v), v1);
                          varUInt64:
                            result := CompareUInt64AndVariant(v, v1);
                        else
                          result := CompareAsVariants(v, v1);
                        end;
                      end;

                      function CompareVariantsEQ(const v, v1: Variant): Boolean;
                      begin
                        case TVarData(v).VType of
                          varSmallInt:
                            result := ComparePSmallAndVariant
                              (GetVariantData(v), v1) = 0;
                          varInteger:
                            result := ComparePIntegerAndVariant
                              (GetVariantData(v), v1) = 0;
                          varSingle:
                            result := ComparePSingleAndVariant
                              (GetVariantData(v), v1) = 0;
                          varDouble:
                            result := ComparePDoubleAndVariant
                              (GetVariantData(v), v1) = 0;
                          varCurrency:
                            result := ComparePCurrencyAndVariant
                              (GetVariantData(v), v1) = 0;
                          varDate:
                            result := ComparePDateAndVariant
                              (GetVariantData(v), v1) = 0;
                          varOleStr:
                            result := CompareWideStringAndVariantEQ
                              (GetVariantData(v), v1);
                          varShortInt:
                            result := ComparePShortAndVariant
                              (GetVariantData(v), v1) = 0;
                          varByte:
                            result := ComparePByteAndVariant
                              (GetVariantData(v), v1) = 0;
                          varWord:
                            result := ComparePWordAndVariant
                              (GetVariantData(v), v1) = 0;
                          varLongWord:
                            result := ComparePLongWordAndVariant
                              (GetVariantData(v), v1) = 0;
                          varInt64:
                            result := ComparePInt64AndVariant
                              (GetVariantData(v), v1) = 0;
                          varString:
                            result := CompareStringAndVariantEQ
                              (GetVariantData(v), v1);
                          varUInt64:
                            result := CompareUInt64AndVariant(v, v1) = 0;
                        else
                          result := v = v1;
                        end;
                      end;

                      function EasyCompareVarArray1(FirstArray, SecondArray: Variant; HighBound: Integer): Boolean;
                      var
                        j: Integer;
                        v, v1: Variant;
                      begin
                        result := False;
                        try
                          for j := HighBound downto 0 do
                          begin
                            v1 := SecondArray[j];
                            v := FirstArray[j];
                            if VarIsEmpty(v) then
                              v := Null;
                            if VarIsEmpty(v1) then
                              v1 := Null;

                            if (VarIsNull(v) xor VarIsNull(v1)) or (v <> v1) then
                              Exit;
                          end;
                          result := True
                        except
                        end
                      end;

end.
