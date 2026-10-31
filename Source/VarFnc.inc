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

{$IFDEF BODY_NUMERIC_COMPARE_EQ}
begin
  case TVarData(v).VType of
    varSmallInt:
      begin
        if P^ = TVarData(v).VSmallInt then
          Result := 0
        else
          if P^ > TVarData(v).VSmallInt then
            Result := 1
          else
            Result := -1
      end;
    varInteger:
      begin
        if P^ = TVarData(v).VInteger then
          Result := 0
        else
          if P^ > TVarData(v).VInteger then
            Result := 1
          else
            Result := -1
      end;
    // exact for the same type; a Single or a Currency on either side sets the precision
    varSingle:
      Result := CompareAsSingles(P^, TVarData(v).VSingle);
    varDouble:
{$IFDEF C_SINGLE}
      Result := -CompareAsSingles(TVarData(v).VDouble, P^);
{$ELSE}
{$IFDEF C_CURRENCY}
      Result := CompareAsCurrencies(P^, TVarData(v).VDouble);
{$ELSE}
      Result := CompareNumbers(P^, TVarData(v).VDouble);
{$ENDIF}
{$ENDIF}
    varCurrency:
{$IFDEF C_FLOAT}
      Result := -CompareAsCurrencies(TVarData(v).VCurrency, P^);
{$ELSE}
      begin
        if P^ = TVarData(v).VCurrency then
          Result := 0
        else
          if P^ > TVarData(v).VCurrency then
            Result := 1
          else
            Result := -1
      end;
{$ENDIF}
    varDate:
      begin
        if P^ = TVarData(v).VDate then
          Result := 0
        else
          if P^ > TVarData(v).VDate then
            Result := 1
          else
            Result := -1
      end;
    varShortInt:
      begin
        if P^ = TVarData(v).VShortInt then
          Result := 0
        else
          if P^ > TVarData(v).VShortInt then
            Result := 1
          else
            Result := -1
      end;
    varByte:
      begin
        if P^ = TVarData(v).VByte then
          Result := 0
        else
          if P^ > TVarData(v).VByte then
            Result := 1
          else
            Result := -1
      end;
    varWord:
      begin
        if P^ = TVarData(v).VWord then
          Result := 0
        else
          if P^ > TVarData(v).VWord then
            Result := 1
          else
            Result := -1
      end;
    varLongWord:
      begin
        if P^ = TVarData(v).VLongWord then
          Result := 0
        else
          if P^ > TVarData(v).VLongWord then
            Result := 1
          else
            Result := -1
      end;
    varInt64:
      begin
        if P^ = TVarData(v).VInt64 then
          Result := 0
        else
          if P^ > TVarData(v).VInt64 then
            Result := 1
          else
            Result := -1
      end;
    varString, varOleStr, varUString:
{$IFDEF C_INT64}
      Result := CompareInt64AndText(P^, VarToStr(V));
{$ELSE}
{$IFDEF C_DATE}
      Result := CompareDateAndText(P^, VarToStr(V));
{$ELSE}
      Result := CompareFloatAndText(P^, VarToStr(V));
{$ENDIF}
{$ENDIF}
    // the Variant compare of a negative Int64 with a UInt64 raises an overflow
    varUInt64:
      if P^ < 0 then
        Result := -1
      else
        Result := CompareAsVariants(P^, V);
    else
      Result := CompareAsVariants(P^, V);
  end;
end;
{$ENDIF}

