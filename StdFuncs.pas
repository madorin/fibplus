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

(*
 * StdFuncs -
 *   A file chock full of functions that should exist in Delphi, but
 *   dont, like "Max", "GetTempFile", "Soundex", etc...
 *)
unit StdFuncs;

{$I FIBPlus.inc}

interface

uses

 Classes, SysUtils,DB,FIBSafeTimer
 {$IFDEF WINDOWS},Windows {$ENDIF}
 {$IFDEF D6+},FMTBcd, Variants{$ENDIF};


type
  EParserError = class(Exception);
  TCharSet = set of AnsiChar;
  TDynArray = array of variant;
  PDynArray=^TDynArray;



 TFIBTimer = TFIBCustomTimer;


function ConvertFromBase(sNum: String; iBase: Integer; cDigits: String): Integer;
function ConvertToBase(iNum, iBase: Integer; cDigits: String): String;




function Max(n1, n2: Integer): Integer;
function MaxD(n1, n2: Double): Double;
function Min(n1, n2: Integer): Integer;{$IFDEF D2005+} inline;{$ENDIF}
function MinD(n1, n2: Double): Double;
function Signum(Arg:Integer) :Integer; {$IFDEF D2005+} inline;{$ENDIF}

function RandomString(iLength: Integer): String;
//function RandomInteger(iLow, iHigh: Integer): Integer;
function Soundex(st: String): String;
function StripString(const st: String; const CharsToStrip: String): String;
function ClosestWeekday(const d: TDateTime): TDateTime;
function Year(d: TDateTime): Integer;
function Month(d: TDateTime): Integer;
function DayOfYear(d: TDateTime): Integer;
function DayOfMonth(d: TDateTime): Integer;

procedure WeekOfYear(d: TDateTime; var Year, Week: Integer);
function  Degree10(Degree:integer):Extended;{$IFDEF D2005+} inline;{$ENDIF}
function  ExtPrecision(Value:Extended) :integer;{$IFDEF D2005+} inline;{$ENDIF}
function  RoundExtend(Value: Extended;Decimals:integer): Extended;

// Comp type stuff


function  Int64WithScaleToStr(Value: Int64;Scale:integer;DSep:Char): string; overload;
function  ExtendedToBCD(const Value:Extended;NeedScale:integer):TBCD;

//end Comp type stuff

function  Int64ToBCD(Value: Int64;Scale:integer; var BCD: TBcd ): Boolean; // {$IFDEF D2005+} inline;{$ENDIF}


function  BCDToExtended(BCD: TBcd; var Value: Extended): Boolean;
function  BCDToCompWithScale(BCD: TBcd; var Value: Int64;var Scale:byte): Boolean;
function  BCDToInt64WithScale(BCD: TBcd; var Value: Int64;var Scale:byte): Boolean;
{$IFNDEF D6+}
function  BCDToStr(BCD: TBcd): String;
{$ENDIF}
function  BCDToSQLStr(BCD: TBcd): String;
function  CompareBCD(const BCD1,BCD2: TBcd): integer;{$IFDEF D2005+} inline;{$ENDIF}
{$IFDEF D6+}
function  fFormatBcd(const Format: string; Bcd: TBcd): string;
function  FormatNumericString(const Format,Source: string; OneSectionFormat:boolean=False ): string;
{$ENDIF}




function  TimeStamp(const aDate,aTime:integer):TTimeStamp;
function  CmpFullName(cmp:TComponent):string;
function  CmpInLoadedState(Cmp:TComponent):boolean;  {$IFDEF D2005+} inline;{$ENDIF}
procedure FullClearStrings(aStrings:TStrings);

function HookTimeStampToMSecs(const TimeStamp:TTimeStamp): Int64;
function HookTimeStampToDateTime(const TimeStamp: TTimeStamp): TDateTime;
function IBStrToTime(const Str:string):TDateTime;

function IntDateToDateTime(aDate:integer):TDateTime;
//DB rtns


function FieldOldValAsString(Field:TField;SQLFormat:boolean):string;

function BCDFieldAsSQLString(Field:TField;OldVal:boolean):variant;
function BCDFieldAsString(Field:TField;OldVal:boolean):variant;
function GetBCDFieldData(Field:TField;OldVal:boolean; var BCD:TBcd):boolean;

function GetBit(InByte:Byte; Index:byte):Boolean;{$IFDEF D2005+} inline;{$ENDIF}
function SetBit(InByte:Byte; Index:byte; value :Boolean):Byte;

function HexStr2Int(const S: String): Integer;
function HexStr2IntStr(const S: String): string;

{$IFNDEF D6+}
type
  PBoolean      = ^Boolean;
function CreateGUID(out Guid: TGUID): HResult;
//function IsEqualGUID(const guid1, guid2: TGUID): Boolean;  stdcall;  {$EXTERNALSYM IsEqualGUID}
function Utf8ToUnicode(Dest: PWideChar; MaxDestChars: Cardinal; Source: PChar; SourceBytes: Cardinal): Cardinal;

function DirectoryExists(const Name: string): Boolean;
function ForceDirectories(Dir: string): Boolean;

{$ENDIF}
procedure InitFPU;


procedure StreamToVariant(Stream:TMemoryStream; var Value : Variant);
procedure StreamToVariantArray(Stream:TMemoryStream; var Value : Variant);
function  VariantToStream(Value : Variant;Stream:TStream): integer; {Length of Blob}

function  StringIsDateTimeDefValue(const s:string):boolean; {$IFDEF D2005+} inline;{$ENDIF}

{$IFNDEF D6+}
// Cut from system.pas Delphi 6
 function Utf8Encode(const WS: WideString): String;
 function Utf8Decode(const S: String): WideString;
{$ENDIF}

{$IFDEF WINDOWS}
function ConvertFromCodePage( const Source : string; FromCodePage:LongWord) : WideString;
function ConvertToCodePage(const Source : WideString; ToCodePage : LongWord) : string;
{$ENDIF}

var
  TempPath: PAnsiChar;
  TempPathLength: Integer;

const
    E10:array [-18..18] of Double =
     ( 1E-18,1E-17, 1E-16, 1E-15, 1E-14, 1E-13, 1E-12, 1E-11,
       1E-10, 1E-9, 1E-8, 1E-7, 1E-6, 1E-5, 1E-4, 1E-3,1E-2, 1E-1,
       1,
       1E1, 1E2, 1E3, 1E4, 1E5, 1E6, 1E7, 1E8,1E9, 1E10,
       1E11, 1E12, 1E13, 1E14, 1E15, 1E16, 1E17, 1E18
      );


    IE10:array [0..18] of int64 =
     (
       1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000,1000000000,
       10000000000,100000000000,1000000000000,10000000000000,100000000000000,
       1000000000000000,10000000000000000,100000000000000000,1000000000000000000
      );
      
const
   AppPathTemplate='{APP_PATH}';


implementation

uses FIBConsts,StrUtil;




{$IFDEF WINDOWS}
function ConvertToCodePage(const Source : WideString;
                           ToCodePage : LongWord) : string;
var
      L :integer;
begin
   L := Length(Source);
   SetLength(Result,L);
   if
   {$IFDEF D2007+}
    WideCharToMultiByte(ToCodePage, 0,  PWideChar(Source), L, PAnsiChar(AnsiString(Result)), L, nil, nil)=0
    {$ELSE}
    WideCharToMultiByte(ToCodePage, 0,  PWideChar(Source), L, PChar(Result), L, nil, nil)=0
    {$ENDIF}
   then
    Result:=Source
end;

function ConvertFromCodePage(const Source : string; FromCodePage:LongWord) : WideString;
var
      L :integer;
begin
  L := Length(Source);
  SetLength(Result,L);
  if
  {$IFDEF D2007+}
   MultiByteToWideChar(FromCodePage, 0,  PAnsiChar(AnsiString(Source)), L, PWideChar(Result), L)=0
  {$ELSE}
   MultiByteToWideChar(FromCodePage, 0,  PChar(Source), L, PWideChar(Result), L)=0
  {$ENDIF}
  then
    Result :=Source
end;
{$ENDIF}


{$IFNDEF D6+}
// Cut from system.pas Delphi 6
function UnicodeToUtf8(Dest: PChar; MaxDestBytes: Cardinal; Source: PWideChar; SourceChars: Cardinal): Cardinal;
var
  i, count: Cardinal;
  c: Cardinal;
begin
  Result := 0;
  if Source = nil then Exit;
  count := 0;
  i := 0;
  if Dest <> nil then
  begin
    while (i < SourceChars) and (count < MaxDestBytes) do
    begin
      c := Cardinal(Source[i]);
      Inc(i);
      if c <= $7F then
      begin
        Dest[count] := Char(c);
        Inc(count);
      end
      else if c > $7FF then
      begin
        if count + 3 > MaxDestBytes then
          break;
        Dest[count] := Char($E0 or (c shr 12));
        Dest[count+1] := Char($80 or ((c shr 6) and $3F));
        Dest[count+2] := Char($80 or (c and $3F));
        Inc(count,3);
      end
      else //  $7F < Source[i] <= $7FF
      begin
        if count + 2 > MaxDestBytes then
          break;
        Dest[count] := Char($C0 or (c shr 6));
        Dest[count+1] := Char($80 or (c and $3F));
        Inc(count,2);
      end;
    end;
    if count >= MaxDestBytes then count := MaxDestBytes-1;
    Dest[count] := #0;
  end
  else
  begin
    while i < SourceChars do
    begin
      c := Integer(Source[i]);
      Inc(i);
      if c > $7F then
      begin
        if c > $7FF then
          Inc(count);
        Inc(count);
      end;
      Inc(count);
    end;
  end;
  Result := count+1;  // convert zero based index to byte count
end;

function Utf8Encode(const WS: WideString): String;
var
  L: Integer;
  Temp: String;
begin
  Result := '';
  if WS = '' then Exit;
  SetLength(Temp, Length(WS) * 3); // SetLength includes space for null terminator

  L := UnicodeToUtf8(PChar(Temp), Length(Temp)+1, PWideChar(WS), Length(WS));
  if L > 0 then
    SetLength(Temp, L-1)
  else
    Temp := '';
  Result := Temp;
end;

function Utf8ToUnicode(Dest: PWideChar; MaxDestChars: Cardinal; Source: PChar; SourceBytes: Cardinal): Cardinal;
var
  i, count: Cardinal;
  c: Byte;
  wc: Cardinal;
begin
  if Source = nil then
  begin
    Result := 0;
    Exit;
  end;
  Result := Cardinal(-1);
  count := 0;
  i := 0;
  if Dest <> nil then
  begin
    while (i < SourceBytes) and (count < MaxDestChars) do
    begin
      wc := Cardinal(Source[i]);
      Inc(i);
      if (wc and $80) <> 0 then
      begin
        wc := wc and $3F;
        if i > SourceBytes then Exit;           // incomplete multibyte char
        if (wc and $20) <> 0 then
        begin
          c := Byte(Source[i]);
          Inc(i);
          if (c and $C0) <> $80 then  Exit;     // malformed trail byte or out of range char
          if i > SourceBytes then Exit;         // incomplete multibyte char
          wc := (wc shl 6) or (c and $3F);
        end;
        c := Byte(Source[i]);
        Inc(i);
        if (c and $C0) <> $80 then Exit;       // malformed trail byte

        Dest[count] := WideChar((wc shl 6) or (c and $3F));
      end
      else
        Dest[count] := WideChar(wc);
      Inc(count);
    end;
	if count >= MaxDestChars then count := MaxDestChars-1;
	Dest[count] := #0;
  end
  else
  begin
	while (i <= SourceBytes) do
	begin
	  c := Byte(Source[i]);
	  Inc(i);
	  if (c and $80) <> 0 then
	  begin
		if (c and $F0) = $F0 then Exit;  // too many bytes for UCS2
		if (c and $40) = 0 then Exit;    // malformed lead byte
		if i > SourceBytes then Exit;         // incomplete multibyte char

		if (Byte(Source[i]) and $C0) <> $80 then Exit;  // malformed trail byte
		Inc(i);
		if i > SourceBytes then Exit;         // incomplete multibyte char
		if ((c and $20) <> 0) and ((Byte(Source[i]) and $C0) <> $80) then Exit; // malformed trail byte
		Inc(i);
	  end;
	  Inc(count);
	end;
  end;
  Result := count+1;
end;

function Utf8Decode(const S: String): WideString;
var
  L: Integer;
  Temp: WideString;
begin
  Result := '';
  if S = '' then Exit;
  SetLength(Temp, Length(S));

  L := Utf8ToUnicode(PWideChar(Temp), Length(Temp)+1, PChar(S), Length(S));
  if L > 0 then
    SetLength(Temp, L-1)
  else
    Temp := '';
  Result := Temp;
end;

{$ENDIF}


procedure StreamToVariantArray(Stream:TMemoryStream; var Value : Variant);
var
  i : integer;
begin
  for i := 0 to Stream.Size - 1 do
   PByte(LongInt(TVarData(Value).VArray^.Data)+i)^ := PByte(LongInt(Stream.Memory)+i)^ ;
end;

procedure StreamToVariant(Stream:TMemoryStream; var Value : Variant);
var
  i : integer;
  {$IFDEF D6+}
   vt  :TVarType;
  {$ELSE}
   vt  :Integer;
  {$ENDIF}
begin
 VarClear(Value);
 if Stream.Size > 0 then
 begin
  Stream.Position:=0;
  vt:=varByte;
  Value := VarArrayCreate([0, Stream.Size-1],vt);
  for i := 0 to Stream.Size - 1 do
   PByte(LongInt(TVarData(Value).VArray^.Data)+i)^ := PByte(LongInt(Stream.Memory)+i)^ ;
 end;
end;

function VariantToStream(Value : Variant;Stream:TStream): integer; {Length of Stream}
var
    B : TVarArrayBound;
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
      BufSize:=B.ElementCount*TVarData(Value).VArray^.ElementSize;
      Stream.Size:=BufSize;
      Stream.Position:=0;
      Stream.Write(TVarData(Value).VArray^.Data^, BufSize );
      Result := Stream.Size;
     end;
   end;
end;


function  StringIsDateTimeDefValue(const s:string):boolean;
begin
  Result := False;
  if Length(s) > 0 then
  case s[1] of
    'C': Result:=(s='CURRENT_TIME') or (s='CURRENT_TIMESTAMP') or (s='CURRENT_DATE');
    'N': Result:=(s='NULL') or (s='NOW');
    'T': Result:=(s='TODAY') or (s='TOMORROW'); 
    'Y': Result:=(s='YESTERDAY');
  end;
end;

{$IFNDEF D6+}

resourcestring
  SCannotCreateDir = 'Unable to create directory';

{$EXTERNALSYM CoCreateGuid}
function CoCreateGuid(out guid: TGUID): HResult; stdcall; external 'ole32.dll' name 'CoCreateGuid';

function CreateGUID(out Guid: TGUID): HResult;
begin
  Result := CoCreateGuid(Guid);
end;
{$ENDIF}

type THackDS=class(TDataSet);


function FieldOldValAsString(Field:TField;SQLFormat:boolean):string;
var
    OldState:TDataSetState;
begin
  OldState:=Field.DataSet.State;
  try
    THackDS(Field.DataSet).SetTempState(dsOldValue);
    Result:=Field.AsString;
  finally
    THackDS(Field.DataSet).RestoreState(OldState);
  end;
  {$IFDEF D_XE3}with FormatSettings do{$ENDIF}
  if SQLFormat and (DecimalSeparator<>'.') then
   ReplaceStr(Result,DecimalSeparator,'.')
end;


function GetBCDFieldData(Field:TField;OldVal:boolean; var BCD:TBcd):boolean;
var
    OldState:TDataSetState;
begin
  OldState:=Field.DataSet.State;
  with THackDS(Field.DataSet) do
  try
    if OldVal and (OldState<>dsOldValue) then
     SetTempState(dsOldValue);
    Result:=GetFieldData(Field,@Bcd);
  finally
    if OldVal and (OldState<>dsOldValue) then
     RestoreState(OldState);
  end;
end;


function InternalBCDFieldAsString(Field:TField;OldVal,SQLFormat:boolean):variant;
var
    Bcd :TBcd;
begin
  if GetBCDFieldData(Field,OldVal,Bcd) then
  begin
     if SQLFormat then
      Result:=BCDToSQLStr(BCD)
     else
      Result:=BCDToStr(BCD);
  end
  else
  begin
     Result:=UnAssigned;
  end;
end;

function BCDFieldAsSQLString(Field:TField;OldVal:boolean):variant;
begin
 Result:= InternalBCDFieldAsString(Field,OldVal,true)
end;

function BCDFieldAsString(Field:TField;OldVal:boolean):variant;
begin
 Result:= InternalBCDFieldAsString(Field,OldVal,false)
end;

//
function RoundExtend(Value: Extended;Decimals:integer): Extended;
begin
 Result:=
  System.Int(Value)+Round(Frac(Value)*E10[Decimals])/E10[Decimals];
end;

function TimeStamp(const aDate,aTime:integer):TTimeStamp;
begin
  with Result do
  begin
    Time:=aTime;
    Date:=aDate;
  end;
end;

function HookTimeStampToMSecs(const TimeStamp:TTimeStamp): Int64;
var t:TTimeStamp;
    c:Comp;
begin
  if TimeStamp.Date=0 then
  begin
   t.Date:=1;
   t.Time:=TimeStamp.Time;
   c:=TimeStampToMSecs(t)-86400000;
  end
  else
   c:=TimeStampToMSecs(TimeStamp);
  Result:=PInt64(@c)^
end;


function HookTimeStampToDateTime(const TimeStamp: TTimeStamp): TDateTime;
var
 t:TTimeStamp;
begin
 if TimeStamp.Date=0 then
 begin
  t.Date:=1;
  t.Time:=TimeStamp.Time;
  Result:=TimeStampToDateTime(t)-1;
 end
 else
  Result:=TimeStampToDateTime(TimeStamp)
end;

function  IBStrToTime(const Str:string):TDateTime;
var
 t:TTimeStamp;
begin
  Result:=StrToTime(Str);
  t:=DateTimeToTimeStamp(Result);
  t.Date:=0;
  Result:=HookTimeStampToDateTime(t);
end;


function IntDateToDateTime(aDate:integer):TDateTime;
var
 t:TTimeStamp;
begin
  t.Date:=aDate;
  t.Time:=0;
  Result:=HookTimeStampToDateTime(t);
end;

function CmpFullName(cmp:TComponent):string;
begin
 result:='';
 while cmp<>nil do
 with cmp do
 begin
  if Name<>'' then
  if Result='' then
   result:=Name
  else
   result:=Name+'.'+Result;
  cmp:=Owner;
 end;
end;

function CmpInLoadedState(Cmp:TComponent):boolean;
var tmpCmp       :TComponent;
begin
    tmpCmp       :=Cmp;
    while   ((tmpCmp<>nil) and  not (csLoading in tmpCmp.ComponentState))  do
    begin
     tmpCmp:=tmpCmp.Owner;
    end;
    Result:=tmpCmp<>nil;
end;

procedure FullClearStrings(aStrings:TStrings);
var
  j: Integer;
begin
 with aStrings do
 for j := 0 to Pred(aStrings.Count) do
 begin
   if Objects[j]<>nil then Objects[j].Free;
 end;
  aStrings.Clear;
end;


function Degree10(Degree:integer):Extended;
begin
  Result:=E10[Degree]
end;

function  ExtPrecision(Value:Extended) :integer;
var
  L, H, I: Integer;
  c:comp;
  a:comp;
begin
  L := 0;
  H := 18;
  a := Abs(Int(Value));
  while L <= H do
  begin
    I := (L + H) shr 1;
    C := E10[I]-a;
    if C < 0 then
     L := I + 1
    else
    begin
      H := I - 1;
      if C = 0 then
      begin
        L := I+1;
        Break
      end;
    end;
  end;
  Result:=L
end;

// Comp type stuff


function ExtendedToBCD(const Value:Extended;NeedScale:integer):TBCD;
var
//   Pr:Integer;
   c:Comp;
begin
//   Pr:=ExtPrecision(Value);
   c:=Value*E10[NeedScale];
   Int64ToBCD(PInt64(@C)^,NeedScale,Result);
end;

procedure PutTwoBcdDigits(const Nibble1, Nibble2: Byte; var Bcd: TBcd; Digit: Integer);
var
  b: Byte;
begin
  b := Nibble1 SHL 4;
  b := b OR (Nibble2 AND 15);
  Bcd.Fraction[Digit div 2] := b;
end;


{$IFDEF D_XE2}
//CUT FROM Delphi XE

function CurrToBCD(const Curr: Currency; var BCD: TBcd; Precision: Integer = 32;
  Decimals: Integer = 4): Boolean;
var
  Temp: Currency;
  BcdIndex, StrIndex, StartPos, Digits: Integer;
  B1, B2, DotPos: Byte;
  BcdStr: string;
  Dot: Char;

  function GetNextByte(): Byte;
  begin
    Result := 0;
    if BcdIndex < StartPos then
       Exit;
    if (StrIndex <= Digits) and (BcdStr[StrIndex] = Dot) then
      Inc(StrIndex);
    if StrIndex <= Digits then
    begin
      Result := Byte(BcdStr[StrIndex]) - 48;
      Inc(StrIndex);
    end;
  end;

begin
  Dot := FormatSettings.DecimalSeparator;
  Bcd.Precision := Precision;
  Bcd.SignSpecialPlaces := Decimals;
  for BcdIndex := 0 to 31 do
    Bcd.Fraction[BcdIndex] := 0;
  if Curr = 0 then
  begin
    Result := True;
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
    PutTwoBcdDigits(B1, B2, Bcd, BcdIndex-1);
    Inc(BcdIndex);
  end;
  if Curr < 0 then
    Bcd.SignSpecialPlaces := (Bcd.SignSpecialPlaces and 63) or (1 shl 7);
  Result := True;
end;


function GetBcdDigit(const Bcd: TBcd; Digit: Integer): Byte;
begin
  if Digit mod 2 = 0 then
    Result := Byte((Bcd.Fraction[Digit div 2]) SHR 4)
  else
    Result := Byte(Byte((Bcd.Fraction[Digit div 2]) AND 15));
end;

const
 DValue: array[-10..20] of Currency = (0, 0, 0, 0, 0, 0, 0,
                                     0.0001, 0.001, 0.01, 0.1, 1,
                                     10,
                                     100,
                                     1000,
                                     10000,
                                     100000,
                                     1000000,
                                     10000000,
                                     100000000,
                                     1000000000,
                                     10000000000,
                                     100000000000,
                                     1000000000000,
                                     10000000000000,
                                     100000000000000,
                                     0, 0, 0, 0, 0);


{ Currency Value of a Byte for a specific digit column }
function PutCurrencyDigit(Value: Byte; Digit: Integer): Currency;
begin
  Result := DValue[Digit] * Value;
end;

function BCDToCurr(const BCD: TBcd; var Curr: Currency): Boolean;
var
  Scale, I: Integer;
  Negative: Boolean;
  b: Byte;
begin
  Curr := 0;
  Negative := (Bcd.SignSpecialPlaces and (1 shl 7)) <> 0;
  Scale := (Bcd.SignSpecialPlaces and 63);
  for I := 0 to Bcd.Precision -1 do
  begin
    b := GetBcdDigit(Bcd, I);
    if b <> 0 then
      Curr := Curr + PutCurrencyDigit(b, Bcd.Precision - (Scale + I));
  end;
  if Scale > 4 then
  begin  { 0.12345 = 0.1234, but 0.123450000001 is rounded up to 0.1235 }
    b := GetBcdDigit(Bcd, 4 + (Bcd.Precision - Scale));
    if b >= 5 then
      if b > 5 then
        Curr := Curr + 0.0001
      else
        for I := 5 + (Bcd.Precision - Scale)  to Bcd.Precision -1 do
          if GetBcdDigit(Bcd, I) <> 0 then
          begin
            Curr := Curr + 0.0001;
            break;
          end;
  end;
  if Negative then
    Curr := -Curr;
  Result := True;
end;


{$ENDIF}


function  Int64ToBCD(Value: Int64;Scale:integer; var BCD: TBcd ): Boolean;
var
 c:Currency;
begin
  c:=Value/1E4;
  Result:= CurrToBCD(c,BCD);
  with BCD do
  begin
   if Value<0 then
    SignSpecialPlaces:=128
   else
    SignSpecialPlaces:=0;
   SignSpecialPlaces :=Scale+SignSpecialPlaces;
  end;
end;



function  BCDToCompWithScale(BCD: TBcd; var Value: Int64;var Scale:byte): Boolean;
begin
 Result:=BCDToInt64WithScale(BCD, Value,Scale)
end;

function  BCDToInt64WithScale(BCD: TBcd; var Value: Int64;var Scale:byte): Boolean;
var Sign:integer;
    c:Currency;
begin
 with BCD do
 begin
  if Precision=0 then
  begin
   Result:=true;
   Value:=0;
   Exit;
  end;
  if SignSpecialPlaces>=128 then
  begin
   Sign:=-1;
   Scale:=SignSpecialPlaces-128;
  end
  else
  begin
   Sign :=1 ;
   Scale:=SignSpecialPlaces;
  end;
  if Scale>=64 then
  begin
  // null
   Result:=true;
   Value:=0;
   Exit;
  end;
   SignSpecialPlaces:=4;
 end;
 Result:=BCDToCurr(BCD,C);
 if Result then
  Value :=Sign*PInt64(@C)^;
end;


function  BCDToSQLStr(BCD: TBcd): String;
var
   pd:integer;
begin
 Result:=BcdToStr(BCD);
 {$IFDEF D_XE3}with FormatSettings do{$ENDIF}
 if DecimalSeparator<>'.' then
 begin
   pd:=Pos(DecimalSeparator,Result);
   if pd>0 then
    Result[pd]:='.';
 end;
end;

const
    ZeroStr='000000000000000000';

{$IFDEF D6+}

{$IFNDEF D2005+}
function RoundAt(const Value: string; Position: SmallInt): string;

  Procedure RoundChar(const PrevChar: SmallInt; var Carry: Boolean);
  begin
    if Result[PrevChar] in ['0' .. '9'] then
    begin
      if Result[PrevChar] = '9' then
      begin
        Result[PrevChar] := '0';
        Carry := True;
      end else
      begin
        Result[PrevChar] := Char(Byte(Result[PrevChar]) + 1);
        Carry := False;
      end;
    end;
  end;

var
  C, Dot: Char;
  PrevChar, I, DecPos, DecDigits: SmallInt;
  Carry: Boolean;
  Neg: string;
begin
  Dot := DecimalSeparator;
  if Value[1] = '-' then
  begin
    Result := FastCopy(Value, 2, MaxInt);
    Neg := '-';
  end else
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
      Result := Neg + Copy(Result, 1, DecPos + Position -1)
    else
      Result := Neg + Copy(Result, 1, DecPos + Position);
  end else
  begin
    Carry := False;
    PrevChar := 1;
    for I := DecPos + DecDigits downto (DecPos + 1 + Position) do
    begin
      C := Result[I];
      PrevChar := I-1;
      if Result[PrevChar] = Dot then
      begin
        Dec(PrevChar);
        Dec(Position);
      end;
      if (Byte(C) >= 53) or Carry then { if '5' or greater }
        RoundChar(PrevChar, Carry);
    end;
    while Carry do
    begin
      if PrevChar >= DecPos then
        Dec(Position);
      Dec(PrevChar);
      if PrevChar = 0 then
        break;
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

function IsZero(const Str:string):boolean;
var
  i:integer;
begin
 Result:=False;
 {$IFDEF D_XE3}with FormatSettings do{$ENDIF}
 for i:=1 to Length(Str) do
 begin
   Result:=(Str[i] ='0') or (Str[i]=DecimalSeparator);
   if not Result then
    Exit;
 end;
end;

function  FormatNumericString(const Format,Source: string; OneSectionFormat:boolean=False ): string;
type
   TPosType=(pBegin,pBeforeDecimalSep,pAfterDecimalSep,pEnd);
   TLiteral=record
     lBody:string;
     lPos :integer;
     lPosType:TPosType;
   end;
var
    L,i:integer;
    NeedDecimalCount:integer;
    CanHaveDecimalCount:integer;
    PosDecSepInFormat:integer;
    PosDecSepInString:integer;
    vLiterals:array of TLiteral;
const
  cFormatChars = ['#', '0', ',', '.'];

begin
 if Length(Source) = 0 then
 begin
  Result:='';
  Exit;
 end;

 if not OneSectionFormat then
 begin
  i:=PosCh(';',Format);
  if i>0 then
  begin
    case  Source[1]  of
    '+','1'..'9':
     Result:=FormatNumericString(FastCopy(Format,1,i-1),Source, True);
    else
     L:=PosCh(';',FastCopy(Format,i+1,MaxInt));
     case Source[1] of
      '0':
       if (L=0) or not IsZero(Source) then
        Result:=FormatNumericString(FastCopy(Format,1,i-1),Source, True)
       else
        Result:=FormatNumericString(FastCopy(Format,L+i+1,MaxInt),Source, True)
     else
       if L=0 then
         Result:=FormatNumericString(FastCopy(Format,i+1,MaxInt),Source, True)
       else
         Result:=FormatNumericString(FastCopy(Format,i+1,L-1),Source, True)
     end;
    end;
    Exit;
  end;
 end;


 Result:=Source;
 L:=Length(Format);
 {$IFDEF D_XE3}with FormatSettings do{$ENDIF}
 if L>0 then
 begin
   while (L>0) and CharInSet(Format[L] , [#9,' ',';']) do
    Dec(L);
   if L=0 then
   begin
    Result := '';
    Exit;
   end;
   if not CharInSet(Format[L] ,cFormatChars) then
   begin
     SetLength(vLiterals,1);
     vLiterals[0].lBody:='';
     vLiterals[0].lPosType:=pEnd;
     i:=L;
     while (i>0) and not CharInSet(Format[i] , cFormatChars) do
     begin
       Dec(i);
     end;
     if i=0 then
     begin
        Result:=FastCopy(Format,i+1,L-i);
        Exit;
     end
     else
      vLiterals[0].lBody:=FastCopy(Format,i+1,L-i);
   end;

   i:=1;
   if (i<L) and not CharInSet(Format[1] , cFormatChars) then
   begin
    SetLength(vLiterals,2);
    vLiterals[1].lBody:='';
    vLiterals[1].lPosType:=pBegin;
    while (i<L) and not CharInSet(Format[i] , cFormatChars) do
     Inc(I);
    vLiterals[1].lBody:=FastCopy(Format,1,I-1);
   end;

   PosDecSepInFormat:=PosCh('.',Format);
   NeedDecimalCount:=0;
   CanHaveDecimalCount:=L-PosDecSepInFormat;
   for i:=L downto PosDecSepInFormat do
   begin
    if (NeedDecimalCount=0) and(Format[i]='0') then
    begin
      NeedDecimalCount:=i-PosDecSepInFormat;
    end
    else
    if NeedDecimalCount<>0 then
     if not CharInSet(Format[i] , cFormatChars) then
      Dec(NeedDecimalCount);
   end;

   i:= PosDecSepInFormat-1;
   if (i>1)and not CharInSet(Format[i] , cFormatChars) then
   begin
     SetLength(vLiterals,3);
     vLiterals[2].lPosType:=pBeforeDecimalSep;
     while (i>1)and not CharInSet(Format[i] , cFormatChars) do
      Dec(i);
     if i>1 then
      vLiterals[2].lBody:=FastCopy(Format,i+1,PosDecSepInFormat-i-1)
     else                                 
      vLiterals[2].lBody:=''
   end;

   i:= PosDecSepInFormat+1;
   if (i<L)and not CharInSet(Format[i] , cFormatChars) then
   begin
     SetLength(vLiterals,4);
     vLiterals[3].lPosType:=pAfterDecimalSep;
     while (i<L)and not CharInSet(Format[i] , cFormatChars) do
      Inc(i);
     if i<L then
      vLiterals[3].lBody:=FastCopy(Format,PosDecSepInFormat+1,i-PosDecSepInFormat-1)
     else
      vLiterals[3].lBody:=''
   end;

   PosDecSepInString:=Pos(DecimalSeparator,Result);
   if (PosDecSepInString=0) and (NeedDecimalCount>0) then
   begin
    Result:=Result+DecimalSeparator;
    PosDecSepInString:=Length(Result)
   end;
   if (PosDecSepInString>0) then
   begin
     if Length(Result)-PosDecSepInString<NeedDecimalCount then
     begin
        if NeedDecimalCount>0 then
         Result:=
          Result+FastCopy(ZeroStr,1,NeedDecimalCount-(Length(Result)-PosDecSepInString))
     end
     else
     if Length(Result)-PosDecSepInString>CanHaveDecimalCount then
     begin
      Result:=RoundAt(Result,CanHaveDecimalCount)
     end;
   end;
   //
   if Length(vLiterals)>3 then
   begin
      Result:= FastCopy(Result,1,PosDecSepInString)+vLiterals[3].lBody+
        FastCopy(Result,PosDecSepInString+1,MaxInt)
      ;
   end;

   if Length(vLiterals)>2 then
   begin
     if PosDecSepInString>0 then
      Result:= FastCopy(Result,1,PosDecSepInString-1)+vLiterals[2].lBody+
        FastCopy(Result,PosDecSepInString,MaxInt)
     else
      Result:= Result+vLiterals[2].lBody;
   end;

   if PosCh(',',Format)>0 then
   begin
    L:=1;
    i:=PosDecSepInString-1;
    if i<0 then
      i:=Length(Result);
    {$IFDEF D_XE3}with FormatSettings do{$ENDIF}
    while i>1 do
    begin
      if L=3 then
      begin
        if (i<>2) or not CharInSet(Result[1] , ['+','-']) then
        Result:=FastCopy(Result,1,i-1)+ThousandSeparator+FastCopy(Result,i,MaxInt);
        L:=0
      end
      else
      begin
       Dec(i);
       Inc(L)
      end;
    end;
   end;
   if Length(vLiterals)>1 then
    PosDecSepInFormat:=PosDecSepInFormat-Length(vLiterals[1].lBody);
   if (PosDecSepInFormat=1) then
   begin
     if (PosDecSepInString=2)  and (Result[1]='0')   then
       Delete(Result,1,1)
     else
     if (PosDecSepInString=3) and (Result[1]='-') and (Result[2]='0')   then
       Delete(Result,2,1);
   end;
   {$IFDEF D_XE3}with FormatSettings do{$ENDIF}
   if Result[Length(Result)]=DecimalSeparator then
    SetLength(Result,Length(Result)-1);
   if OneSectionFormat and (Result[1]='-') then
     Delete(Result,1,1);
   if Length(vLiterals)>0 then
   begin
    Result:= Result+vLiterals[0].lBody;
    if Length(vLiterals)>1 then
    begin
      Result:= vLiterals[1].lBody+Result;
    end;
   end;
 end;
end;
function  fFormatBcd(const Format: string; Bcd: TBcd): string;
begin
 Result:=FormatNumericString(Format,BCDToStr(Bcd));
end;
{$ENDIF}

function  BCDToExtended(BCD: TBcd; var Value: Extended): Boolean;
var c:Int64;
    Scale:byte;
begin
 Result:= BCDToInt64WithScale(BCD,c,Scale);
 if Result then
  Value :=C*E10[-Scale]
end;

function  CompareBCD(const BCD1,BCD2: TBcd): integer;
var e1,e2:extended;
begin
 BCDToExtended(Bcd1,e1);
 BCDToExtended(Bcd2,e2);
 if e1=e2 then
  Result:=0
 else
 if e1<e2 then
  Result:=-1
 else
  Result:=1
end;






function  Int64WithScaleToStr(Value: Int64;Scale:integer;DSep:Char): string;
var i,j:integer;
    IntStr,DecStr:string;
    sign:string;
begin
 if Value=0 then
 begin
  Result:='0';
  Exit;
 end;
 Result:= IntToStr(Value);
 if Scale>0 then
 begin
   if Result[1]='-' then
   begin
    sign:='-';
    Delete(Result,1,1);
   end
   else
    sign:='';
  j:=Length(Result)-Scale ;
  if j>0 then
  begin
    IntStr:=sign+ FastCopy(Result,1,j);
    DecStr:=FastCopy(Result,j+1,Length(Result));
  end
  else
  begin
   IntStr:=sign+'0';
   DecStr:=MakeStr('0',-j)+Result;
  end;
  Result:= IntStr+DSep+DecStr;
  i:=Length(Result);
  while Result[i] = '0' do
  begin
    Dec(i);
    if Result[i]=DSep then
    begin
     Dec(i);Break;
    end;
  end;
   Delete(Result,i+1,Length(Result));
 end;
end;


{$IFNDEF D6+}
function  BCDToStr(BCD: TBcd): String;

var  c:Int64;
     Scale:byte;
begin
 if BCDToInt64WithScale(BCD,c,Scale) then
  Result:=Int64WithScaleToStr(c,Scale,DecimalSeparator)
 else
  Result:=''
end;
{$ENDIF}


//
function ConvertFromBase(sNum: String; iBase: Integer; cDigits: String): Integer;
var
  i: Integer;

  function GetValue(c: Char): Integer;
  var
    i: Integer;
  begin
    result := 0;
    for i := 1 to Length(cDigits) do
      if (cDigits[i] = c) then
      begin
        result := i - 1;
        exit;
      end;
  end;

begin
  result := 0;
  for i := 1 to Length(sNum) do
    result := (result * iBase) + GetValue(sNum[i]);
end;

function ConvertToBase(iNum, iBase: Integer; cDigits: String): String;
var
  i, r: Integer;
  s: String;
const
  iLength = 16;
begin
  result := '';
  SetString(s, nil, iLength);
  i := 0;
  repeat
    r := iNum mod iBase;
    Inc(i);
    if (i > iLength) then
      SetString(s, PChar(s), Length(s) + iLength);
    s[i] := cDigits[r + 1];
    iNum := iNum div iBase;
  until iNum = 0;
  SetString(result, nil, i);
  for r := 1 to i do
    result[r] := s[i - r + 1];
end;



function Max(n1, n2: Integer): Integer;
begin
  if (n1 > n2) then
    result := n1
  else
    result := n2;
end;

function MaxD(n1, n2: Double): Double;
begin
  if (n1 > n2) then
    result := n1
  else
    result := n2;
end;

function Min(n1, n2: Integer): Integer;
begin
  if (n1 < n2) then
    result := n1
  else
    result := n2;
end;

function Signum(Arg:Integer) :integer;
begin
 if Arg>0 then Result:=1 else
  if Arg<0 then Result:=-1  else  Result:=0;
end;

function MinD(n1, n2: Double): Double;
begin
  if (n1 < n2) then
    result := n1
  else
    result := n2;
end;

function RandomInteger(iLow, iHigh: Integer): Integer;
begin
  result := Trunc(Random(iHigh - iLow)) + iLow;
end;

function RandomString(iLength: Integer): String;
begin
  result := '';
  while Length(result) < iLength do
    result := result + IntToStr(RandomInteger(0, High(Integer)));
  if Length(Result) > iLength then
    Result := FastCopy(result, 1, iLength);
end;


function Soundex(st: String): String;
var
  code: Char;
  i, j, len: Integer;
begin
  result := ' 0000';
  if (st = '') then exit;
  result[1] := UpCase(st[1]);
  j := 2;                   
  i := 2;
  len := Length(st);
  while (i <= len) and (j < 6) do
  begin
    case st[i] of
      'B', 'F', 'P', 'V', 'b', 'f', 'p', 'v' : code := '1';
      'C', 'G', 'J', 'K', 'Q', 'S', 'X', 'Z',
      'c', 'g', 'j', 'k', 'q', 's', 'x', 'z' : code := '2';
      'D', 'T', 'd', 't' :                     code := '3';
      'L', 'l' :                               code := '4';
      'M', 'N', 'm', 'n' :                     code := '5';
      'R', 'r' :                               code := '6';
    else
      code := '0';
    end; {case}

    if (code <> '0') and (code <> result[j - 1]) then
    begin
      result[j] := code;
      inc(j);
    end;
    inc(i);
  end;
end;

function StripString(const st: String; const CharsToStrip: String): String;
{var
  i: Integer;}
begin
  if Pos(CharsToStrip,st) = 0 then
   Result:=st
  else
   Result:=ReplaceStr(st,CharsToStrip,'');
end;

function ClosestWeekday(const d: TDateTime): TDateTime;
begin
  if (DayOfWeek(d) = 1) then
    result := d + 1
  else
  if (DayOfWeek(d) = 7) then
    result := d + 2
  else
    result := d;
end;

function Year(d: TDateTime): Integer;
var
  y, m, day: Word;
begin
  DecodeDate(d, y, m, day);
  result := y;
end;

function Month(d: TDateTime): Integer;
var
  yr, mn, dy: Word;
begin
  DecodeDate(d, yr, mn, dy);
  result := mn;
end;

function DayOfYear(d: TDateTime): Integer;
var
  yr, mn, dy: Word;
  b: TDateTime;
begin
  DecodeDate(d, yr, mn, dy);
  b := EncodeDate(yr, 1, 1);
  result := Trunc(d - b);
end;

function DayOfMonth(d: TDateTime): Integer;
var
  yr, mn, dy: Word;
begin
  DecodeDate(d, yr, mn, dy);
  result := dy;
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
    else
    if (dow_ybeg = 5) or (LastLeapYear and (dow_ybeg = 6)) then
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
    Hexez: array ['A'..'F'] of Byte = (10,11,12,13,14,15);
    HexezDecimal: array ['0'..'9'] of Byte = (0,1,2,3,4,5,6,7,8,9);

  function HexStr2Int(const S: String): Integer;
  var
    J: LongInt;
    PStart,PEnd:PChar;
  begin
    Result := 0;
    J := 1;
    PStart:=Pointer(S);
    PEnd  :=Pointer(S);
    Inc(PEnd,Length(S)-1);
    while PEnd>=PStart do
    begin
     case PEnd^ of
      '0':;
      '1': Inc(Result, J);
      '2': Inc(Result, J*2);
      '3'..'9': Inc(Result, J*HexezDecimal[PEnd^]);
      'A'..'F': Inc(Result, J*Hexez[PEnd^]);
     end;
     J:=J*16;
     Dec(PEnd)
    end;
  end;

  function HexStr2IntStr(const S: String): string;
  begin
   Result:=IntToStr(HexStr2Int(S))
  end;

var
 vBits: array[0..7]of byte =(1,2,4,8,16,32,64,128);


function GetBit(InByte:Byte; Index:byte):Boolean;
begin
 Result:= Boolean(InByte shr Index and 1)
end;

function SetBit(InByte:Byte; Index:byte; Value :Boolean):Byte;
begin
  if Value then
   Result:=InByte or vBits[Index]
  else
   Result:=InByte and not vBits[Index]
end;




{$IFNDEF D6+}
function DirectoryExists(const Name: string): Boolean;
var
  Code: Integer;
begin
  Code := GetFileAttributes(PChar(Name));
  Result := (Code <> -1) and (FILE_ATTRIBUTE_DIRECTORY and Code <> 0);
end;

function ForceDirectories(Dir: string): Boolean;
begin
  Result := True;
  if Length(Dir) = 0 then
    raise Exception.CreateRes(Integer(@SCannotCreateDir));
  Dir := ExcludeTrailingBackslash(Dir);
  if (Length(Dir) < 3) or DirectoryExists(Dir)
    or (ExtractFilePath(Dir) = Dir) then Exit; // avoid 'xyz:\' problem.
  Result := ForceDirectories(ExtractFilePath(Dir)) and CreateDir(Dir);
end;
{$ENDIF}

initialization
  Randomize;
end.





