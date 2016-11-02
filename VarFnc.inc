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
{$IFDEF BODY_NUMERIC_COMPARE_EQ}
begin
  case TVarData(v).VType of
   varSmallInt:
   begin
    if P^=TVarData(v).VSmallInt then
     Result:=0
    else
    if P^>TVarData(v).VSmallInt then
     Result:=1
    else
     Result:=-1
   end;
   varInteger :
   begin
    if P^=TVarData(v).VInteger then
     Result:=0
    else
    if P^>TVarData(v).VInteger then
     Result:=1
    else
     Result:=-1
   end;
   varSingle  :
   begin
    if Abs(P^-TVarData(v).VDouble)<1E-11 then
     Result:=0
    else
    if P^>TVarData(v).VSingle then
     Result:=1
    else
     Result:=-1
   end;
   varDouble  :
   begin
    if Abs(P^-TVarData(v).VDouble)<1E-11 then
     Result:=0
    else
    if P^>TVarData(v).VDouble then
     Result:=1
    else
     Result:=-1
   end;
   varCurrency:
   begin
    if P^=TVarData(v).VCurrency then
     Result:=0
    else
    if P^>TVarData(v).VCurrency then
     Result:=1
    else
     Result:=-1
   end;
   varDate    :
   begin
    if P^=TVarData(v).VDate then
     Result:=0
    else
    if P^>TVarData(v).VDate then
     Result:=1
    else
     Result:=-1
   end;
   varOleStr  :
{$IFDEF C_INT64}
   begin
    if P^=StrToInt64(WideString(TVarData(V).VOleStr)) then
     Result:=0
    else
    if P^>StrToInt64(WideString(TVarData(V).VOleStr)) then
     Result:=1
    else
     Result:=-1
   end;
{$ELSE}
   begin
    if P^=StrToFloat(WideString(TVarData(V).VOleStr)) then
     Result:=0
    else
    if P^>StrToFloat(WideString(TVarData(V).VOleStr)) then
     Result:=1
    else
     Result:=-1
   end;
{$ENDIF} 
{$IFDEF D6+}
   varShortInt:
   begin
    if P^=TVarData(v).VShortInt then
     Result:=0
    else
    if P^>TVarData(v).VShortInt then
     Result:=1
    else
     Result:=-1
   end;
   varByte    :
   begin
    if P^=TVarData(v).VByte then
     Result:=0
    else
    if P^>TVarData(v).VByte then
     Result:=1
    else
     Result:=-1
   end;
   varWord    :
   begin
    if P^=TVarData(v).VWord then
     Result:=0
    else
    if P^>TVarData(v).VWord then
     Result:=1
    else
     Result:=-1
   end;
   varLongWord:
   begin
    if P^=TVarData(v).VLongWord then
     Result:=0
    else
    if P^>TVarData(v).VLongWord then
     Result:=1
    else
     Result:=-1
   end;
   varInt64   :
   begin
    if P^=TVarData(v).VInt64 then
     Result:=0
    else
    if P^>TVarData(v).VInt64 then
     Result:=1
    else
     Result:=-1
   end;
{$ENDIF}
    varString  :
{$IFDEF C_INT64}
   begin
    if P^=StrToInt64(string(TVarData(V).VString)) then
     Result:=0
    else
    if P^>StrToInt64(string(TVarData(V).VString)) then
     Result:=1
    else
     Result:=-1
   end;
{$ELSE}
   begin
    if P^=StrToFloat(string(TVarData(V).VString)) then
     Result:=0
    else
    if P^>StrToFloat(string(TVarData(V).VString)) then
     Result:=1
    else
     Result:=-1
   end;
{$ENDIF}
  else
    result := 0;
  end;
end;
{$ENDIF}