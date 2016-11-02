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
{    Written by Serge Buzadzhy (buzz@devrace.com)               }
{                                                               }
{ ------------------------------------------------------------- }
{    FIBPlus home page: http://www.fibplus.com/                 }
{    FIBPlus support  : http://www.devrace.com/support/         }
{ ------------------------------------------------------------- }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit VariantRtn;

interface

{$I FIBPlus.inc}

uses


   SysUtils,FIBPlatforms   {$IFDEF D6+}, Variants{$ENDIF};

{$IFDEF SUPPORT_ARRAY_FIELD}
type

// CallBack procedures definitions
      TProcReadElementValue=procedure (Value:Variant; IndexValue:array of integer;
       const HighBoundInd:integer;
       Var Continue:boolean
      );
      TProcWriteElementValue=
       procedure (OldValue:Variant; IndexValue:array of integer;
        Var NewValue:Variant;  Var Continue:boolean
       );
//  End CallBack procedures definitions



function CycleReadArray(vArray:Variant;CallBackProc:TProcReadElementValue):boolean;
function CycleWriteArray(var vArray:Variant;CallBackProc:TProcWriteElementValue):boolean;
 {$ENDIF}
function CompareVarArray1(vArray1,vArray2:Variant):boolean;
function EasyCompareVarArray1(vArray1,vArray2:Variant;HighBound:integer):boolean;
function NeedCastForCompare(const v,v1:Variant):boolean;

{$IFNDEF D6+}
function VarTypeIsNumeric(const AVarType: word): Boolean;
function VarIsNumeric(const V: Variant): Boolean;
{$ENDIF}

function CompareVariantsEQ(const v,v1:Variant):boolean;
function CompareVariants(const v,v1:Variant):Integer;

function ComparePDoubleAndVariant(P:PDouble;const v:Variant):Integer;
function ComparePIntegerAndVariant(P:PInteger;const v:Variant):Integer;
function ComparePInt64AndVariant(P:PInt64;const v:Variant):Integer;
function ComparePByteAndVariant(P:PByte;const v:Variant):Integer;
function ComparePDateAndVariant(P:PDateTime;const v:Variant):Integer;
function ComparePSmallAndVariant(P:PSmallInt;const v:Variant):Integer;
function CompareWideStringAndVariant(P:Pointer;const v:Variant):Integer;
function ComparePCurrencyAndVariant(P:PCurrency;const v:Variant):Integer;
function ComparePShortAndVariant(P:PShortInt;const v:Variant):Integer;

implementation
uses FIBConsts;


{$IFNDEF D6+}
{$I SysVariantD5.inc}
{$ENDIF}

// CompareRnts
function GetVariantData(const v: Variant):Pointer;
begin
  case TVarData(v).VType of
    varSmallInt:
     result:=@TVarData(v).VSmallInt;
    varInteger:
      result:=@TVarData(v).VInteger;
    varSingle :
      result:=@TVarData(v).VSingle;
{$IFDEF D6+}
    varInt64:
     result:=@TVarData(v).VInt64;

    varShortInt:
      result:=@TVarData(v).VShortInt;
    varWord:
      result:=@TVarData(v).VWord;
    varLongWord:
      result:=@TVarData(v).VLongWord;
{$ENDIF}
    varByte:
      result:=@TVarData(v).VByte;
    varDouble  : result:=@TVarData(v).VDouble;
    varCurrency: result:=@TVarData(v).VCurrency;
    varDate    : result:=@TVarData(v).VDate;
    varOleStr  : result:=TVarData(v).VOleStr;
    varBoolean : result:=@TVarData(v).VBoolean;
    varVariant,varByRef: result:=GetVariantData(PVariant(@TVarData(v).VPointer)^);
    varString  : result:=TVarData(v).VString;
{$IFDEF D2009+}
    varUString :  result:=TVarData(v).VUString;
{$ENDIF}    
  else
    result := nil;
  end;
end;



{$DEFINE BODY_NUMERIC_COMPARE_EQ}
{$WARNINGS OFF}
function ComparePIntegerAndVariant(P:PInteger;const v:Variant):Integer;
{$I VarFnc.inc}

function ComparePSmallAndVariant(P:PSmallInt;const v:Variant):Integer;
{$I VarFnc.inc}


function ComparePSingleAndVariant(P:PSingle;const v:Variant):Integer;
{$I VarFnc.inc}

function ComparePDoubleAndVariant(P:PDouble;const v:Variant):Integer;
{$I VarFnc.inc}

function ComparePCurrencyAndVariant(P:PCurrency;const v:Variant):Integer;
{$I VarFnc.inc}


function ComparePDateAndVariant(P:PDateTime;const v:Variant):Integer;
{$I VarFnc.inc}


function ComparePInt64AndVariant(P:PInt64;const v:Variant):Integer;
{$DEFINE C_INT64}
{$I VarFnc.inc}
{$UNDEF C_INT64}

function ComparePByteAndVariant(P:PByte;const v:Variant):Integer;
{$I VarFnc.inc}



function ComparePShortAndVariant(P:PShortInt;const v:Variant):Integer;
{$I VarFnc.inc}
{$IFDEF D6+}
function ComparePWordAndVariant(P:PWord;const v:Variant):Integer;
{$I VarFnc.inc}

function ComparePLongWordAndVariant(P:PLongWord;const v:Variant):Integer;
{$I VarFnc.inc}
{$ENDIF}

{$WARNINGS ON}
{$UNDEF BODY_NUMERIC_COMPARE_EQ}

function CompareWideStringAndVariantEQ(P:Pointer;const v:Variant):boolean;
begin
   case VarType(v) of
    varString:    result:=WideString(P)=string(TVarData(v).VString);
    varOleStr:    result:=WideString(P)=WideString(TVarData(v).VOleStr);
{$IFDEF D2009+}
    varUString :  result:=WideString(P)=string(TVarData(v).VUString);
{$ENDIF}

   else
     Result := WideString(P)=VarToStr(V);
   end;
end;

function CompareStringAndVariantEQ(P:Pointer;const v:Variant):boolean;
begin
   case VarType(v) of
    varString:    result:=AnsiString(P)=String(TVarData(v).VString);
    varOleStr:    result:=AnsiString(P)=WideString(TVarData(v).VOleStr);
{$IFDEF D2009+}
    varUString :  result:=AnsiString(P)=string(TVarData(v).VUString);
{$ENDIF}

   else
     result := AnsiString(P)=VarToStr(V);
   end;
end;


function CompareWideStringAndVariant(P:Pointer;const v:Variant):Integer;
begin
   case VarType(v) of
    varString:
    begin
      if WideString(P)=string(TVarData(v).VString) then
        Result := 0
      else
      if WideString(P)>string(TVarData(v).VString) then
       Result:=1
      else
       Result := -1;
    end;
    varOleStr:
    begin
      if WideString(P)=WideString(TVarData(v).VOleStr) then
        Result := 0
      else
      if WideString(P)>WideString(TVarData(v).VOleStr) then
       Result:=1
      else
       Result := -1;
    end;
{$IFDEF D2009+}
    varUString :
    begin
      if WideString(P)=string(TVarData(v).VUString) then
        Result := 0
      else
      if WideString(P)>string(TVarData(v).VUString) then
       Result:=1
      else
       Result := -1;
    end;
{$ENDIF}

   else
    if WideString(P)=VarToStr(V) then
      Result :=0
    else
    if WideString(P)>VarToStr(V) then
       Result:=1
    else
      Result := -1;
   end;
end;


{$WARNINGS OFF}
function CompareStringAndVariant(P:Pointer;const v:Variant):Integer;
{$IFDEF D2009+}
var
    s:UnicodeString;
{$ENDIF}
begin
   case VarType(v) of
    varString:
    begin
     if AnsiString(P)=AnsiString(TVarData(v).VString) then
      Result :=0
     else
     if AnsiString(P)>AnsiString(TVarData(v).VString) then
      Result :=1
     else
      Result :=-1
    end;
    varOleStr:
    begin
     if AnsiString(P)=WideString(TVarData(v).VOleStr) then
      Result :=0
     else
     if AnsiString(P)>WideString(TVarData(v).VOleStr) then
      Result :=1
     else
      Result :=-1
    end;
   {$IFDEF D2009+}
    varUString:
    begin
     s:=AnsiString(P);
     if s=UnicodeString(TVarData(v).vUString) then
      Result :=0
     else
     begin
       if s>UnicodeString(TVarData(v).vUString) then
         Result:= 1
       else
        Result := -1;
     end
    end
   {$ENDIF}
   else
     if AnsiString(P)=VarToStr(V) then
      Result :=0
     else
     if AnsiString(P)>VarToStr(V) then
       Result:=1
     else
      Result := -1;
   end;
end;




{$WARNINGS ON}

function CompareVariants(const v,v1:Variant):Integer;
begin
 case TVarData(v).VType of
  varSmallInt:
   result:=ComparePSmallAndVariant(GetVariantData(v),v1);
  varInteger :
   result:=ComparePIntegerAndVariant(GetVariantData(v),v1);
  varSingle  :
   result:=ComparePSingleAndVariant(GetVariantData(v),v1);
  varDouble  :
   result:=ComparePDoubleAndVariant(GetVariantData(v),v1);
  varCurrency:
   result:=ComparePCurrencyAndVariant(GetVariantData(v),v1);
  varDate    :
   result:=ComparePDateAndVariant(GetVariantData(v),v1);
  varOleStr:
    result:=CompareWideStringAndVariant(GetVariantData(v),v1);
{$IFDEF D6+}
  varShortInt:
   result:=ComparePShortAndVariant(GetVariantData(v),v1);
  varByte    :
   result:=ComparePByteAndVariant(GetVariantData(v),v1);
  varWord    :
   result:=ComparePWordAndVariant(GetVariantData(v),v1);
  varLongWord:
   result:=ComparePLongWordAndVariant(GetVariantData(v),v1);
  varInt64   :
   result:=ComparePInt64AndVariant(GetVariantData(v),v1);
{$ENDIF}
//{$IFNDEF D_XE}
  varString  :
   result:=CompareStringAndVariant(GetVariantData(v),v1);
//{$ENDIF}
 else
   if v=v1 then
    Result := 0
   else
   if v>v1 then
    Result:=1
   else
    Result:=-1
 end;
end;

function CompareVariantsEQ(const v,v1:Variant):boolean;
begin
 case TVarData(v).VType of
  varSmallInt:
   result:=ComparePSmallAndVariant(GetVariantData(v),v1)=0;
  varInteger :
   result:=ComparePIntegerAndVariant(GetVariantData(v),v1)=0;
  varSingle  :
   result:=ComparePSingleAndVariant(GetVariantData(v),v1)=0;
  varDouble  :
   result:=ComparePDoubleAndVariant(GetVariantData(v),v1)=0;
  varCurrency:
   result:=ComparePCurrencyAndVariant(GetVariantData(v),v1)=0;
  varDate    :
   result:=ComparePDateAndVariant(GetVariantData(v),v1)=0;
  varOleStr:
    result:=CompareWideStringAndVariantEQ(GetVariantData(v),v1);
{$IFDEF D6+}
  varShortInt:
   result:=ComparePShortAndVariant(GetVariantData(v),v1)=0;
  varByte    :
   result:=ComparePByteAndVariant(GetVariantData(v),v1)=0;
  varWord    :
   result:=ComparePWordAndVariant(GetVariantData(v),v1)=0;
  varLongWord:
   result:=ComparePLongWordAndVariant(GetVariantData(v),v1)=0;
  varInt64   :
   result:=ComparePInt64AndVariant(GetVariantData(v),v1)=0;
{$ENDIF}
  varString  :
   result:=CompareStringAndVariantEQ(GetVariantData(v),v1);
 else
   result:=v=v1;
 end;
end;
//////
function NeedCastForCompare(const v,v1:Variant):boolean;
begin
  case VarType(v) of
   varDate:   Result:= not (VarIsNumeric(v1) or (VarType(v1)=varDate));
   varBoolean:Result:= VarType(v1)<>varBoolean;
  else
   case VarType(v1) of
    varDate   : Result:= not (VarIsNumeric(v) {or (VarType(v)=varDate)});
    varBoolean: Result:= True;    
   else
    Result:= (VarIsNumeric(v1) xor VarIsNumeric(v))
   end 
  end;
end;

function EasyCompareVarArray1( vArray1,vArray2:Variant;HighBound:integer)
 :boolean;
var
 j:integer;
 v,v1:Variant;
begin
 Result:=False;
 try
    for j:= HighBound downto 0 do
    begin
      v1:=vArray2[j];
      v :=vArray1[j];
      if VarIsEmpty(v) then  v  := Null;
      if VarIsEmpty(v1) then v1 := Null;

      if (VarIsNull(v) xor VarIsNull(v1)) or (v<>v1) then
       Exit;
    end;
    Result:=True
 except
 end
end;

function CompareVarArray1(vArray1,vArray2:Variant):boolean;
var j,l,h:integer;
begin
 Result:=False;
 try
  if VarIsArray(vArray1) and VarIsArray(vArray2) then
  begin
    h:=VarArrayHighBound(vArray1,1);
    l:=VarArrayLowBound(vArray1,1);
    for j:=l to h do
    begin
      if vArray1[j]<>vArray2[j] then
       Exit;
    end;
    Result:=True
  end
 except
 end
end;
{$IFDEF SUPPORT_ARRAY_FIELD}


  
function NextElements(v: Variant;var CurIndex:array of Integer): boolean;
var
  Dimensions: integer;
  i: integer;
begin
  Result := False;
  Dimensions := VarArrayDimCount(v);
  for i := Dimensions-1 downto 0 do
  begin
    if CurIndex[i] = VarArrayHighBound(v,i+1) then
    begin
      CurIndex[i] := VarArrayLowBound(v,i+1);
    end
    else
    begin
      CurIndex[i] := CurIndex[i]+1;
      Result := True;
      Exit;
    end;
  end;
end;




function CycleReadArray(vArray:Variant;CallBackProc:TProcReadElementValue):boolean;
var
  Value:Variant;
  CurIndex:array of Integer;
  DimCount,I:Integer;
begin
 Result:=false;
 if not Assigned(CallBackProc) then Exit;
 if not VarIsArray(vArray) then Exit;

 DimCount := VarArrayDimCount(vArray);
 SetLength(CurIndex,DimCount);
 for i:=0 to DimCount-1 do
  CurIndex[i]:= VarArrayLowBound(vArray,i+1);

// InitializationCurIndexArray(vArray,CurIndex);


  repeat
    Value:= VarArrayGet(vArray, CurIndex);
    Result:=true;
    CallBackProc(Value,CurIndex,DimCount-1,Result);
    if not Result then Exit;
    if not NextElements(vArray,CurIndex) then Break;
  until False;
end;



function CycleWriteArray
 (var vArray:Variant;CallBackProc:TProcWriteElementValue):boolean;
var
  OldValue,NewValue: Variant;
  CurIndex:array of Integer;
  DimCount,I:Integer;

begin
// vArray - Variant array of Variant
 Result:=false;
 if not Assigned(CallBackProc) then Exit;

 DimCount := VarArrayDimCount(vArray);
 SetLength(CurIndex,DimCount);
 for i:=0 to DimCount-1 do
  CurIndex[i]:= VarArrayLowBound(vArray,i+1);

// InitializationCurIndexArray(vArray,CurIndex);
 repeat
    OldValue:=VarArrayGet(vArray, CurIndex);
    Result:=true;
    CallBackProc(OldValue,CurIndex,NewValue,Result);
    if not Result then Exit;
    VarArrayPut(vArray, NewValue, CurIndex );
    if not NextElements(vArray,CurIndex) then Break;
 until False;
end;

{$ENDIF}
end.





