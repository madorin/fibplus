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


{*******************************************************}
{                                                       }
{ This unit based on  StrUtils.pas from RX Library      }
{ and SoWldStr.pas from SOHOLIB                         }
{                                                       }
{*******************************************************}

unit StrUtil;

interface

{$I FIBPlus.inc}

uses
  SysUtils, Classes {$IFDEF WINDOWS}, Windows {$ENDIF};

type

  TPosition = record
    X: Longint;
    Y: Longint;
  end;

  {$IFDEF D_XE5}

  TFastStringStream = TStringStream;

  {$ELSE}

  TFastStringStream = class(TStream)
  private
    FDataString: string;
    FPosition: Integer;
    FSize: Integer;
    FActualLength: Integer;
    FElementSize: Integer;
    function GetDataString: string;
  protected
    procedure SetSize(aNewSize: Longint); override;
    procedure Grow(Min: Integer = 0);
    function CurMemory: Pointer;
  public
    constructor Create(const AString: string);
    destructor Destroy; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    function ReadString(Count: Longint): string;
    function Seek(Offset: Longint; Origin: Word): Longint; override;
    procedure PackData;
    function Write(const Buffer; Count: Longint): Longint; override;
    procedure WriteString(const AString: string);
    property DataString: string read GetDataString;
  end;
  {$ENDIF}

type
  TCharSet = set of AnsiChar;

function Position(AX, AY: Integer): TPosition;
// from RX
function MakeStr(C: Char; N: Integer): string;
function StrAsFloat(S: string): double;

function ToClientDateFmt(D: string; caseFmt: Byte): string;
function ExtractWord(Num: Integer; const Str: string; const WordDelims: TCharSet): string;
// function ExtractLastWord(const Str: String;const  WordDelims:TCharSet):String;
function WordCount(const S: string; const WordDelims: TCharSet): Integer;
// from SOHOLIB

function AnsiUpperCaseA(const S: AnsiString): AnsiString;
function CompareStrWA(const S1: string; const S2: AnsiString): Integer;
// function AnsiCompareTextWA(const S1,S2: Pointer): Integer;
function AnsiCompareTextAA(const S1, S2: AnsiString): Integer;

function WildStringCompare(FirstString, SecondString: string): Boolean;
function MaskCompare(const AString, Mask: String): Boolean;
function SQLMaskCompare(const AString, Mask: String): Boolean; {$IFDEF D6+} overload; {$ENDIF}
function SQLMaskCompareAW(const AString: AnsiString; const Mask: string): Boolean;
function SQLMaskCompareAA(const AString, Mask: AnsiString): Boolean; {$IFDEF D6+}
function SQLMaskCompare(const AString, Mask: Widestring): Boolean; overload; {$ENDIF}
// function WldIndexOf(ts:TStrings;const Value:AnsiString;CaseSensitive:Boolean):Integer;

// from Me

function TrimCLRF(const S: String): String;

{ procedure CopyChars(const Src:Ansistring; var  Dest:Ansistring;
  StartInSrc,StartInDest,Count:Integer
  ); }
function ReplaceStr(const S, Srch, Replace: string): string;

function ReplaceStrInSubstr(const Source: string; const Srch, Replace: string; BeginPos, EndPos: Integer): string;
function ReplaceCIStr(const S, Srch, Replace: string; Ansi: Boolean = True): string;
function ReplaceStrCIInSubstr(const Source: string; const Srch, Replace: string; BeginPos, EndPos: Integer): string;

function FastUpperCase(const S: string): string; {$IFDEF D2007+} inline; {$ENDIF}
procedure DoUpperCase(var S: string; FirstPos: Integer = 1; LastPos: Integer = 0);
{$IFDEF   D2009+}
procedure DoAnsiUpperCase(var S: AnsiString); overload;
{$ENDIF}
procedure DoAnsiUpperCase(var S: string); overload;

procedure DoWideUpperCase(var S: Widestring);
procedure DoUtf8Decode(const S: PAnsiChar; StrLen: Integer; var ws: Widestring); overload;
procedure DoUtf8Decode(const S: AnsiString; var ws: Widestring); overload;
procedure DoUtf8Decode(const S: variant; var ws: Widestring); overload;
function EquelStrings(const S, S1: string; CaseSensitive: Boolean): Boolean;

function iifStr(Condition: Boolean; const Str1, Str2: string): string;
function iifVariant(Condition: Boolean; const Var1, Var2: variant): Variant;
function StrOnMask(const StrIn, MaskIn, MaskOut: string): string;
function StrIsInteger(const Str: string): Boolean;

function FormatIdentifierValue(Dialect: Integer; const Value: string): string; {$IFDEF D2007+} inline; {$ENDIF}
function FormatIdentifier(Dialect: Integer; const Value: string): string; {$IFDEF D2007+} inline; {$ENDIF}
function NormalizeName(Dialect: Integer; const Name: string): string; {$IFDEF D2007+} inline; {$ENDIF}
function EasyFormatIdentifier(Dialect: Integer; const Value: string; DoEasy: Boolean): string; {$IFDEF D2007+} inline;
{$ENDIF}
function EquelNames(CI: Boolean; const Value, Value1: String): Boolean; {$IFDEF D2007+} inline; {$ENDIF}
function NeedQuote(const Name: string): Boolean;
function EasyNeedQuote(const Name: string): Boolean;

function PosCh(aCh: Char; const S: string): Integer;
function PosCh1(aCh: Char; const S: string; StartPos: Integer): Integer; overload;
{$IFDEF   D2009+}
function PosCh1(aCh: AnsiChar; const S: AnsiString; StartPos: Integer): Integer; overload;
{$ENDIF}
function PosCI(const Substr, Str: string): Integer; {$IFDEF D2007+} inline;
{$ENDIF}
function PosExt(const Substr, Str: string; BegSub, EndSub: TCharSet): Integer; {$IFDEF D2009+} inline; {$ENDIF}
function PosExtCI(const Substr, Str: string; BegSub, EndSub: TCharSet; AnsiUpper: Boolean = True): Integer;

function PosInSubstr(const Substr, Str: string; BeginPos, EndPos: Integer): Integer;

function PosInRight(const Substr, Str: string; BeginPos: Integer): Integer;

function PosInSubstrCI(const SearchStr, Str: string; BeginPos, EndPos: Integer): Integer;

function PosInSubstrExt(const SearchStr: string; Str: string; BeginPos, EndPos: Integer;
  BegSub, EndSub: TCharSet): Integer;

function PosInSubstrCIExt(const SearchStr, Str: string; BeginPos, EndPos: Integer; BegSub, EndSub: TCharSet): Integer;

function FirstPos(Search: array of Char; const InString: string): Integer; overload;
{$IFDEF D2009+}
function FirstPos(Search: array of AnsiChar; const InString: AnsiString): Integer; overload;
{$ENDIF}
function LastChar(const Str: string): Char;

function QuotedStr(const S: string): string;
function CutQuote(const S: String): string;

function StringInArray(const S: string; const a: array of string): Boolean;
function IsBlank(const Str: string): Boolean;
function IsBeginPartStr(const PartStr, TargetStr: AnsiString): Boolean;
{$IFDEF D6+} overload; {$ENDIF}
{$IFDEF D2009+}
function IsBeginPartStrWA(const PartStr: string; const TargetStr: AnsiString): Boolean;
{$ENDIF}
function IsBeginPartStrVarA(const PartStr: variant; const TargetStr: AnsiString): Boolean;
{$IFDEF D6+}
function IsBeginPartStr(const PartStr, TargetStr: Widestring): Boolean; overload;
{$ENDIF}
// Ansistring procedures
procedure DoLowerCase(var Str: string); overload;
{$IFDEF D2009+}
procedure DoLowerCase(var Str: AnsiString); overload;
{$ENDIF}
procedure DoTrim(var Str: string);

// procedure DoTrimTo(const Source:Ansistring ;var Dest:Ansistring);
function VarTrimRight(const Str: variant): variant;
procedure DoTrimRight(var Str: string); overload;
procedure DoTrimRight(var Str: Widestring); overload;
{$IFDEF D2009+}
procedure DoTrimRight(var Str: AnsiString); overload;
{$ENDIF}
procedure DoCopy(const Source: string; var Dest: string; Index, Count: Integer); overload;
{$IFDEF D2009+}
procedure DoCopy(const Source: AnsiString; var Dest: AnsiString; Index, Count: Integer); overload;
{$ENDIF}
// function  StrTrimmedLen(Str:PChar):Integer;

function FastTrim(const S: string): string;
function FastCopy(const S: String; Index: Integer; Count: Integer): String; overload;
{$IFDEF D2009+}
function FastCopy(const S: AnsiString; Index: Integer; Count: Integer): AnsiString; overload;
{$ENDIF}
// TStringList functions

procedure SLDifference(ASL, BSL: TStringList; ResultSL: TStrings);
function EmptyStrings(SL: TStrings): Boolean;
procedure DeleteEmptyStr(Src: TStrings);
function NonAnsiSortCompareStrings(SL: TStringList; Index1, Index2: Integer): Integer;
function FindInDiapazon(SL: TStringList; const S: String; const StartIndex, EndIndex: Integer; AnsiCompare: Boolean;
  var Index: Integer): Boolean;
function NonAnsiIndexOf(SL: TStringList; const S: string): Integer; // Non Ansi

procedure GetNameAndValue(const S: string; var Name, Value: AnsiString);

function StrToDateFmt(const ADate, Fmt: string): TDateTime;
function DateToSQLStr(const ADate: TDateTime): string;
function ValueFromStr(const Str: string): string;

{$IFNDEF D6+}
function WideUpperCase(const S: Widestring): Widestring;
{$ENDIF}
function Q_StrLen(P: PAnsiChar): Cardinal;

function IsOldParamName(const ParamName: string): Boolean;
function IsNewParamName(const ParamName: string): Boolean;
function IsMasParamName(const ParamName: string): Boolean;

function GUIDAsString(const AGUID: TGUID): AnsiString; // fast GUIDToString
procedure GUIDAsStringToPChar(const AGUID: PGUID; Dest: PAnsiChar);
function StringAsGUID(const AStr: AnsiString): TGUID;
function CompareStrAndGuid(GUID: PGUID; const Str: AnsiString): Integer;
function CompareStrAndGuidP(GUID: PGUID; const Str: PAnsiString): Integer;
function IsEqualGUIDs(const guid1, guid2: TGUID): Boolean;

{ Thanks to Anton Tril }

function IsNumericStr(const Str: string): Boolean;
function IsEmptyStr(const Str: string): Boolean;
function CompareStrTrimmed(const Str1, Str2: PChar; Len: Integer): Integer;

{$IFNDEF D2009+}
function CharInSet(C: AnsiChar; const CharSet: TSysCharSet): Boolean;
{$ENDIF}

implementation

uses SysConst
  {$IFNDEF D6+}
    , StdFuncs
  {$ELSE}
    , Variants
  {$ENDIF}
    ;

{$IFNDEF D2009+}

function CharInSet(C: AnsiChar; const CharSet: TSysCharSet): Boolean;
begin
  Result := C in CharSet;
end;
{$ENDIF}
{$IFNDEF D6+}

type
  IntegerArray = array [0 .. $EFFFFFF] of Integer;
  PIntegerArray = ^IntegerArray;
  {$ENDIF}

function IsNumericStr(const Str: string): Boolean;
var
  pStr, pStrEnd: PChar;
begin
  if Length(Str) = 0 then
  begin
    Result := False;
    Exit;
  end;
  pStr := Pointer(Str);
  pStrEnd := Pointer(Str);
  Inc(pStrEnd, Length(Str));
  while (pStr < pStrEnd) and CharInSet(pStr^, ['+', '-']) do
    Inc(pStr);
  if pStr = pStrEnd then
  begin
    Result := False;
    Exit;
  end;
  while pStr < pStrEnd do
  begin
    if CharInSet(pStr^, ['0' .. '9', '.']) then
      Inc(pStr)
    else
    begin
      Result := False;
      Exit;
    end;
  end;
  Result := True;
end;

function IsEmptyStr(const Str: string): Boolean;
var
  pStr, pStrEnd: PChar;
begin
  if Length(Str) = 0 then
  begin
    Result := True;
    Exit;
  end;
  pStr := Pointer(Str);
  pStrEnd := Pointer(Str);
  Inc(pStrEnd, Length(Str));
  while (pStr < pStrEnd) do
  begin
    if pStr^ > ' ' then
    begin
      Result := False;
      Exit;
    end;
    Inc(pStr);
  end;
  Result := True;
end;

function CompareStrTrimmed(const Str1, Str2: PChar; Len: Integer): Integer;
var
  i: Integer;
begin
  // Str2 must be trimmed
  while Str2[Len - 1] < #33 do
    Dec(Len);
  i := 0;
  while i < Len do
  begin
    if Str1[i] > Str2[i] then
    begin
      Result := 1;
      Exit;
    end
    else if Str1[i] < Str2[i] then
    begin
      Result := -1;
      Exit;
    end
    else
      Inc(i)
  end;
  Result := 0;
end;

function CompareStrAndGuid(GUID: PGUID; const Str: AnsiString): Integer;
begin
  Result := CompareStr(Str, GUIDAsString(GUID^))
end;

function CompareStrAndGuidP(GUID: PGUID; const Str: PAnsiString): Integer;
begin
  Result := CompareStr(Str^, GUIDAsString(GUID^))
end;

function CompareStrWA(const S1: string; const S2: AnsiString): Integer;
begin
  // Result :=CompareStr(S1,S2)
  if S1 <> S2 then
    Result := 1
  else
    Result := 0
end;

function AnsiCompareTextAA(const S1, S2: AnsiString): Integer;
begin
  Result := AnsiCompareText(S1, S2)
end;

function AnsiUpperCaseA(const S: AnsiString): AnsiString;
begin
  Result := AnsiUpperCase(S)
end;

function IsEqualGUIDs(const guid1, guid2: TGUID): Boolean;
var
  a, b: PIntegerArray;
begin
  a := PIntegerArray(@guid1);
  b := PIntegerArray(@guid2);
  Result := (a^[0] = b^[0]) and (a^[1] = b^[1]) and (a^[2] = b^[2]) and (a^[3] = b^[3]);
end;

type
  TGUIDBytes = record
    F0, F1, F2, F3, F4, F5, F6, F7, F8, F9, FA, FB, FC, FD, FE, FF: byte;
  end;

  {$R+}
  {$IFNDEF D6+}

resourcestring
  SInvalidGUID = '''%s'' is not a valid GUID value';
  {$ENDIF}

const

  Int2HexHash: Array [0 .. 255] of Word = ($3030, $3130, $3230, $3330, $3430, $3530, $3630, $3730, $3830, $3930, $4130,
    $4230, $4330, $4430, $4530, $4630, $3031, $3131, $3231, $3331, $3431, $3531, $3631, $3731, $3831, $3931, $4131,
    $4231, $4331, $4431, $4531, $4631, $3032, $3132, $3232, $3332, $3432, $3532, $3632, $3732, $3832, $3932, $4132,
    $4232, $4332, $4432, $4532, $4632, $3033, $3133, $3233, $3333, $3433, $3533, $3633, $3733, $3833, $3933, $4133,
    $4233, $4333, $4433, $4533, $4633, $3034, $3134, $3234, $3334, $3434, $3534, $3634, $3734, $3834, $3934, $4134,
    $4234, $4334, $4434, $4534, $4634, $3035, $3135, $3235, $3335, $3435, $3535, $3635, $3735, $3835, $3935, $4135,
    $4235, $4335, $4435, $4535, $4635, $3036, $3136, $3236, $3336, $3436, $3536, $3636, $3736, $3836, $3936, $4136,
    $4236, $4336, $4436, $4536, $4636, $3037, $3137, $3237, $3337, $3437, $3537, $3637, $3737, $3837, $3937, $4137,
    $4237, $4337, $4437, $4537, $4637, $3038, $3138, $3238, $3338, $3438, $3538, $3638, $3738, $3838, $3938, $4138,
    $4238, $4338, $4438, $4538, $4638, $3039, $3139, $3239, $3339, $3439, $3539, $3639, $3739, $3839, $3939, $4139,
    $4239, $4339, $4439, $4539, $4639, $3041, $3141, $3241, $3341, $3441, $3541, $3641, $3741, $3841, $3941, $4141,
    $4241, $4341, $4441, $4541, $4641, $3042, $3142, $3242, $3342, $3442, $3542, $3642, $3742, $3842, $3942, $4142,
    $4242, $4342, $4442, $4542, $4642, $3043, $3143, $3243, $3343, $3443, $3543, $3643, $3743, $3843, $3943, $4143,
    $4243, $4343, $4443, $4543, $4643, $3044, $3144, $3244, $3344, $3444, $3544, $3644, $3744, $3844, $3944, $4144,
    $4244, $4344, $4444, $4544, $4644, $3045, $3145, $3245, $3345, $3445, $3545, $3645, $3745, $3845, $3945, $4145,
    $4245, $4345, $4445, $4545, $4645, $3046, $3146, $3246, $3346, $3446, $3546, $3646, $3746, $3846, $3946, $4146,
    $4246, $4346, $4446, $4546, $4646);

function StringAsGUID(const AStr: AnsiString): TGUID;
const
  Hex2IntHash: Array [0 .. 70] of byte = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 0, 0, 0, 0, 0, 0,
    10, 11, 12, 13, 14, 15);

begin
  { Thanks to Anton Tril }
  if (Length(AStr) <> 38) or (AStr[1] <> '{') or (AStr[38] <> '}') or (AStr[10] <> '-') or (AStr[15] <> '-') or
    (AStr[20] <> '-') or (AStr[25] <> '-') then
  begin
    raise EConvertError.CreateResFmt(PResStringRec(@SInvalidGUID), [AStr]);
  end;
  try
    TGUIDBytes(Result).F3 := Hex2IntHash[byte(AStr[2])] shl 4 or Hex2IntHash[byte(AStr[3])];
    TGUIDBytes(Result).F2 := Hex2IntHash[byte(AStr[4])] shl 4 or Hex2IntHash[byte(AStr[5])];
    TGUIDBytes(Result).F1 := Hex2IntHash[byte(AStr[6])] shl 4 or Hex2IntHash[byte(AStr[7])];
    TGUIDBytes(Result).F0 := Hex2IntHash[byte(AStr[8])] shl 4 or Hex2IntHash[byte(AStr[9])];
    // -
    TGUIDBytes(Result).F5 := Hex2IntHash[byte(AStr[11])] shl 4 or Hex2IntHash[byte(AStr[12])];
    TGUIDBytes(Result).F4 := Hex2IntHash[byte(AStr[13])] shl 4 or Hex2IntHash[byte(AStr[14])];
    // -
    TGUIDBytes(Result).F7 := Hex2IntHash[byte(AStr[16])] shl 4 or Hex2IntHash[byte(AStr[17])];
    TGUIDBytes(Result).F6 := Hex2IntHash[byte(AStr[18])] shl 4 or Hex2IntHash[byte(AStr[19])];
    // -
    TGUIDBytes(Result).F8 := Hex2IntHash[byte(AStr[21])] shl 4 or Hex2IntHash[byte(AStr[22])];
    TGUIDBytes(Result).F9 := Hex2IntHash[byte(AStr[23])] shl 4 or Hex2IntHash[byte(AStr[24])];
    // -
    TGUIDBytes(Result).FA := Hex2IntHash[byte(AStr[26])] shl 4 or Hex2IntHash[byte(AStr[27])];
    TGUIDBytes(Result).FB := Hex2IntHash[byte(AStr[28])] shl 4 or Hex2IntHash[byte(AStr[29])];
    TGUIDBytes(Result).FC := Hex2IntHash[byte(AStr[30])] shl 4 or Hex2IntHash[byte(AStr[31])];
    TGUIDBytes(Result).FD := Hex2IntHash[byte(AStr[32])] shl 4 or Hex2IntHash[byte(AStr[33])];
    TGUIDBytes(Result).FE := Hex2IntHash[byte(AStr[34])] shl 4 or Hex2IntHash[byte(AStr[35])];
    TGUIDBytes(Result).FF := Hex2IntHash[byte(AStr[36])] shl 4 or Hex2IntHash[byte(AStr[37])];
  except
    raise EConvertError.CreateResFmt(PResStringRec(@SInvalidGUID), [AStr]);
  end;
end;
{$R-}

procedure GUIDAsStringToPChar(const AGUID: PGUID; Dest: PAnsiChar);
var
  P: Cardinal;
begin
  P := Cardinal(Dest);
  PByte(P)^ := Ord('{');
  Inc(P);
  PWord(P)^ := Int2HexHash[TGUIDBytes(AGUID^).F3];
  Inc(P, 2);
  PWord(P)^ := Int2HexHash[TGUIDBytes(AGUID^).F2];
  Inc(P, 2);
  PWord(P)^ := Int2HexHash[TGUIDBytes(AGUID^).F1];
  Inc(P, 2);
  PWord(P)^ := Int2HexHash[TGUIDBytes(AGUID^).F0];
  Inc(P, 2);
  PByte(P)^ := Ord('-');
  Inc(P);
  PWord(P)^ := Int2HexHash[TGUIDBytes(AGUID^).F5];
  Inc(P, 2);
  PWord(P)^ := Int2HexHash[TGUIDBytes(AGUID^).F4];
  Inc(P, 2);
  PByte(P)^ := Ord('-');
  Inc(P);
  PWord(P)^ := Int2HexHash[TGUIDBytes(AGUID^).F7];
  Inc(P, 2);
  PWord(P)^ := Int2HexHash[TGUIDBytes(AGUID^).F6];
  Inc(P, 2);
  PByte(P)^ := Ord('-');
  Inc(P);
  PWord(P)^ := Int2HexHash[TGUIDBytes(AGUID^).F8];
  Inc(P, 2);
  PWord(P)^ := Int2HexHash[TGUIDBytes(AGUID^).F9];
  Inc(P, 2);
  PByte(P)^ := Ord('-');
  Inc(P);
  PWord(P)^ := Int2HexHash[TGUIDBytes(AGUID^).FA];
  Inc(P, 2);
  PWord(P)^ := Int2HexHash[TGUIDBytes(AGUID^).FB];
  Inc(P, 2);
  PWord(P)^ := Int2HexHash[TGUIDBytes(AGUID^).FC];
  Inc(P, 2);
  PWord(P)^ := Int2HexHash[TGUIDBytes(AGUID^).FD];
  Inc(P, 2);
  PWord(P)^ := Int2HexHash[TGUIDBytes(AGUID^).FE];
  Inc(P, 2);
  PWord(P)^ := Int2HexHash[TGUIDBytes(AGUID^).FF];
  Inc(P, 2);
  PByte(P)^ := Ord('}');
end;

function GUIDAsString(const AGUID: TGUID): AnsiString;
begin
  SetLength(Result, 38);
  GUIDAsStringToPChar(@AGUID, PAnsiChar(Result))
end;

function IsOldParamName(const ParamName: string): Boolean;
begin
  Result := (Length(ParamName) > 4) and CharInSet(ParamName[1], ['O', 'o']) and (ParamName[4] = '_') and
    CharInSet(ParamName[2], ['L', 'l']) and CharInSet(ParamName[3], ['D', 'd'])
end;

function IsNewParamName(const ParamName: string): Boolean;
begin
  Result := (Length(ParamName) > 4) and CharInSet(ParamName[1], ['N', 'n']) and (ParamName[4] = '_') and
    CharInSet(ParamName[2], ['E', 'e']) and CharInSet(ParamName[3], ['W', 'w'])
end;

function IsMasParamName(const ParamName: string): Boolean;
begin
  Result := (Length(ParamName) > 4) and CharInSet(ParamName[1], ['M', 'm']) and (ParamName[4] = '_') and
    CharInSet(ParamName[2], ['A', 'a']) and CharInSet(ParamName[3], ['S', 's'])
end;

function StrToDateFmt(const ADate, Fmt: string): TDateTime;
var
  OldShortDateFormat: string;
begin
  {$IFDEF D_XE3}with FormatSettings do {$ENDIF}
  begin
    OldShortDateFormat := {$IFDEF D_XE3}FormatSettings.{$ENDIF}ShortDateFormat;
    try
      ShortDateFormat := Fmt;
      Result := StrToDateTime(ADate);
    finally
      ShortDateFormat := OldShortDateFormat;
    end
  end;
end;

function DateToSQLStr(const ADate: TDateTime): string;
var
  Year, Month, Day: Word;
begin
  DecodeDate(ADate, Year, Month, Day);
  Result := IntToStr(Day) + '.' + IntToStr(Month) + '.' + IntToStr(Year)
end;

function ValueFromStr(const Str: string): string;
var
  P: Integer;
begin
  P := PosCh('=', Str);
  if P = 0 then
    Result := ''
  else
    Result := Copy(Str, P + 1, MaxInt)
end;

{$IFDEF D6+}

function IsBeginPartStr(const PartStr, TargetStr: Widestring): Boolean;
var
  i, L: Integer;
begin
  L := Length(PartStr);
  if L = 0 then
    Result := True
  else if L > Length(TargetStr) then
    Result := False
  else
  begin
    for i := 1 to L do
      if PartStr[i] <> TargetStr[i] then
      begin
        Result := False;
        Exit;
      end;
    Result := True;
  end;
end;
{$ENDIF}
{$IFDEF D2009+}

function IsBeginPartStrWA(const PartStr: string; const TargetStr: AnsiString): Boolean;
var
  i, L: Integer;
  wTargStr: Widestring;
begin
  L := Length(PartStr);
  if L = 0 then
    Result := True
  else if L > Length(TargetStr) then
    Result := False
  else
  begin
    wTargStr := TargetStr;
    for i := 1 to L do
      if PartStr[i] <> wTargStr[i] then
      begin
        Result := False;
        Exit;
      end;
    Result := True;
  end;
end;
{$ENDIF}

function IsBeginPartStrVarA(const PartStr: variant; const TargetStr: AnsiString): Boolean;
begin
  {$IFDEF D2009+}
  Result := IsBeginPartStrWA(PartStr, TargetStr)
  {$ELSE}
  Result := IsBeginPartStr(PartStr, TargetStr)
  {$ENDIF}
end;

function IsBeginPartStr(const PartStr, TargetStr: AnsiString): Boolean;
var
  i, L: Integer;
begin
  L := Length(PartStr);
  if L = 0 then
    Result := True
  else if L > Length(TargetStr) then
    Result := False
  else
  begin
    for i := 1 to L do
      if PartStr[i] <> TargetStr[i] then
      begin
        Result := False;
        Exit;
      end;
    Result := True;
  end;
end;

function IsBlank(const Str: string): Boolean;
var
  L: Integer;
begin
  L := Length(Str);
  while (L > 0) and (Str[L] <= ' ') do
    Dec(L);
  Result := L = 0;
end;

{$IFDEF D2009+}

procedure DoLowerCase(var Str: AnsiString);
var
  i: Integer;
begin
  for i := Length(Str) downto 1 do
    if (Str[i] >= 'A') and (Str[i] <= 'Z') then
      Inc(Str[i], 32)
end;
{$ENDIF}

procedure DoLowerCase(var Str: string);
var
  i: Integer;
begin
  for i := Length(Str) downto 1 do
    if (Str[i] >= 'A') and (Str[i] <= 'Z') then
      Inc(Str[i], 32)
end;

procedure TrimPositions(const Str: string; var Left, Right: Integer);
begin
  Right := Length(Str);
  if Right = 0 then
  begin
    Left := 0;
    Exit;
  end;
  Left := 1;
  while (Right > 0) and (Str[Right] <= ' ') do
    Dec(Right);
  while (Left <= Right) and (Str[Left] <= ' ') do
    Inc(Left);
end;

procedure DoTrim(var Str: string);
var
  Left, Right: Integer;
begin
  TrimPositions(Str, Left, Right);
  if Right < Length(Str) then
    SetLength(Str, Right);
  if Left > 1 then
    Delete(Str, 1, Left - 1);
end;

function VarTrimRight(const Str: variant): Variant;
var
  i: Integer;
  ws: Widestring;
  S: string;
begin
  case VarType(Str) of
    varOleStr:
      begin
        ws := Str;
        i := Length(ws);
        if (i > 0) and (ws[i] <> ' ') then
        begin
          Result := ws;
          Exit;
        end;
        while (i > 0) and (ws[i] = ' ') do
          Dec(i);
        Result := Copy(ws, 1, i);
      end;
  else
    begin
      S := Str;
      i := Length(S);
      if (i > 0) and (S[i] <> ' ') then
      begin
        Result := S;
        Exit;
      end;
      while (i > 0) and (S[i] = ' ') do
        Dec(i);
      Result := Copy(S, 1, i);
    end
  end;
end;

procedure DoTrimRight(var Str: string);
var
  i: Integer;
begin
  i := Length(Str);
  while (i > 0) and (Str[i] = ' ') do
    Dec(i);
  if i < Length(Str) then
    SetLength(Str, i)
end;

procedure DoTrimRight(var Str: Widestring);
var
  i: Integer;
begin
  i := Length(Str);
  while (i > 0) and (Str[i] = ' ') do
    Dec(i);
  if i < Length(Str) then
    SetLength(Str, i)
end;

{$IFDEF D2009+}

procedure DoTrimRight(var Str: AnsiString);
var
  i: Integer;
  P, p1: PAnsiChar;
begin
  { I := Length(Str);
    while (I > 0) and (Str[I] <= ' ') do Dec(I);
    if I< Length(Str) then  SetLength(Str,I) }

  i := Length(Str);
  if i > 0 then
  begin
    P := PAnsiChar(Pointer(Str));
    p1 := P;
    Inc(p1, i - 1);
    if p1^ = ' ' then
    begin
      repeat
        Dec(p1);
        if p1^ <> ' ' then
        begin
          SetLength(Str, p1 - P + 1);
          Exit
        end;
      until (p1 = P);
      Str := '';
    end
  end
end;

{$ENDIF}
{$IFDEF D2009+}

procedure DoCopy(const Source: AnsiString; var Dest: AnsiString; Index, Count: Integer);
var
  L: Integer;
begin
  L := Length(Source) - Index + 1;
  if L > Count then
    L := Count;
  if L <= 0 then
    Dest := ''
  else
  begin
    if Length(Dest) <> L then
      SetLength(Dest, L);
    Move(Source[Index], Dest[1], L * SizeOf(AnsiChar));
  end;
end;
{$ENDIF}

procedure DoCopy(const Source: string; var Dest: string; Index, Count: Integer);
var
  L: Integer;
begin
  L := Length(Source) - Index + 1;
  if L > Count then
    L := Count;
  if L <= 0 then
    Dest := ''
  else
  begin
    if Length(Dest) <> L then
      SetLength(Dest, L);
    Move(Source[Index], Dest[1], L * SizeOf(Char));
  end;
end;

function FastTrim(const S: string): string;
var
  i, L: Integer;
begin
  L := Length(S);
  i := 1;
  while (i <= L) and (S[i] <= ' ') do
    Inc(i);

  if i > L then
    Result := ''
  else
  begin
    while S[L] <= ' ' do
      Dec(L);
    if (i > 1) or (L < Length(S)) then
    begin
      SetLength(Result, L - i + 1);
      Move(S[i], Result[1], (L - i + 1) * SizeOf(Char));
    end
    else
      Result := S
  end;
end;

function FastCopy(const S: string; Index: Integer; Count: Integer): string;
var
  L: Integer;
begin
  L := Length(S);
  if (Index > L) or (Count <= 0) then
    Result := ''
  else
  begin
    if (Count - L + Index) > 0 then
      Count := L - Index + 1;
    SetLength(Result, Count);
    Move(S[Index], Result[1], Count * SizeOf(Char));
  end;
end;

{$IFDEF D2009+}

function FastCopy(const S: AnsiString; Index: Integer; Count: Integer): AnsiString;
var
  L: Integer;
begin
  L := Length(S);
  if (Index > L) or (Count <= 0) then
    Result := ''
  else
  begin
    if (Count - L + Index) > 0 then
      Count := L - Index + 1;
    SetLength(Result, Count);
    Move(S[Index], Result[1], Count * SizeOf(AnsiChar));
  end;
end;
{$ENDIF}

function StringInArray(const S: string; const a: array of String): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := Low(a) to High(a) do
  begin
    Result := EquelNames(False, S, a[i]);
    if Result then
      Exit;
  end;
end;

function FormatIdentifierValue(Dialect: Integer; const Value: string): string;
begin
  if Dialect = 1 then
    Result := FastUpperCase(FastTrim(Value))
  else
    Result := Value;
end;

function EquelNames(CI: Boolean; const Value, Value1: string): Boolean;
begin
  if Length(Value) <> Length(Value1) then
    Result := False
  else
  begin
    if CI then
      Result := AnsiCompareText(Value, Value1) = 0
    else
      Result := Value = Value1
  end;
end;

function EasyFormatIdentifier(Dialect: Integer; const Value: string; DoEasy: Boolean): string;
var
  b: Boolean;
begin
  if Dialect = 1 then
    Result := UpperCase(FastTrim(Value))
  else
  begin
    if DoEasy then
      b := EasyNeedQuote(Value)
    else
      b := NeedQuote(Value);
    if b then
      if (Length(Value) > 0) and (Value[1] <> '"') then
        Result := '"' + Value + '"'
      else
        Result := Value
    else if (Length(Value) > 0) and (Value[1] <> '"') then
      Result := UpperCase(Value)
    else
      Result := Value
  end;
end;

function FormatIdentifier(Dialect: Integer; const Value: string): string;
begin
  if Dialect = 1 then
    Result := UpperCase(Trim(Value))
  else if NeedQuote(Value) then
    Result := '"' + Value + '"'
  else
    Result := Value
end;

function NormalizeName(Dialect: Integer; const Name: string): string;
begin
  if Dialect < 3 then
    Result := UpperCase(Name)
  else if (Length(Name) > 0) and (Name[1] = '"') then
    Result := Name
  else
    Result := UpperCase(Name)
end;

{$IFDEF CPUX86}

function Q_StrScan(const S: AnsiString; Ch: AnsiChar; StartPos: Integer): Integer;
asm


  TEST    EAX,EAX
  JE      @@qt
  PUSH    EDI
  MOV     EDI,EAX
  LEA     EAX,[ECX-1]
  MOV     ECX,[EDI-4]
  SUB     ECX,EAX
  JLE     @@m1
  PUSH    EDI
  ADD     EDI,EAX
  MOV     EAX,EDX
  POP     EDX
  REPNE   SCASB
  JNE     @@m1
  MOV     EAX,EDI
  SUB     EAX,EDX
  POP     EDI
  RET
@@m1:   POP     EDI
  XOR     EAX,EAX
@@qt:
end;
{$ELSE}

function Q_StrScan(const S: AnsiString; Ch: AnsiChar; StartPos: Integer): Integer;
var
  i, L: Integer;
begin
  L := Length(S);
  for i := StartPos to L do
    if S[i] = Ch then
    begin
      Result := i;
      Exit;
    end;
  Result := 0;

end;

{$ENDIF}

function PosCh(aCh: Char; const S: string): Integer;
begin
  // Result:=Q_StrScan(s,aCh,1)
  Result := Pos(aCh, S)
end;

function PosCh1(aCh: AnsiChar; const S: AnsiString; StartPos: Integer): Integer;
begin
  Result := Q_StrScan(S, aCh, StartPos)

end;

{$IFDEF D2009+}

function PosCh1(aCh: Char; const S: string; StartPos: Integer): Integer;
var
  i: Integer;
begin
  for i := StartPos to Length(S) do
    if S[i] = aCh then
    begin
      Result := i;
      Exit;
    end;
  Result := 0
end;
{$ENDIF}

function PosCI(const Substr, Str: string): Integer;
begin
  Result := Pos(FastUpperCase(Substr), FastUpperCase(Str));
end;

function PosExt(const Substr, Str: string; BegSub, EndSub: TCharSet): Integer;
var
  P, L, l1: Integer;
begin
  Result := 0;
  P := Pos(Substr, Str);
  L := Length(Str);
  l1 := Length(Substr);
  while P > 0 do
  begin
    if ((P = 1) or CharInSet(Str[P - 1], BegSub)) and (CharInSet(Str[P + l1], EndSub) or (P + l1 > L)) then
    begin
      Result := P;
      Exit;
    end;
    P := PosInSubstr(Substr, Str, P + l1, L)
  end;
end;

function PosExtCI(const Substr, Str: string; BegSub, EndSub: TCharSet; AnsiUpper: Boolean = True): Integer;
begin
  if AnsiUpper then
    Result := PosExt(AnsiUpperCase(Substr), AnsiUpperCase(Str), BegSub, EndSub)
  else
    Result := PosExt(FastUpperCase(Substr), FastUpperCase(Str), BegSub, EndSub)
end;

function PosInRight(const Substr, Str: string; BeginPos: Integer): Integer;
begin
  Result := PosInSubstr(Substr, Str, BeginPos, MaxInt);
end;

function PosInSubstr(const Substr, Str: string; BeginPos, EndPos: Integer): Integer;
var
  Ch, ch1: Char;
  i, j: Integer;
  LSubStrLen, LStrLen: Integer;
  LSearch: Integer;
  MayBe: Boolean;
begin
  Result := 0;
  LSubStrLen := Length(Substr);
  if EndPos > Length(Str) then
    LStrLen := Length(Str)
  else
    LStrLen := EndPos;
  LSearch := LStrLen - LSubStrLen + 1;
  if (LStrLen = 0) or (LSubStrLen = 0) or (LSearch < 0) then
    Exit;

  Ch := Substr[1];
  ch1 := Substr[LSubStrLen];
  Dec(LSubStrLen);
  i := BeginPos;
  repeat
    while (i <= LSearch) and not((Str[i] = Ch) and (Str[i + LSubStrLen] = ch1)) do
    begin
      Inc(i);
    end;
    if i <= LSearch then
    begin
      MayBe := True;
      for j := LSubStrLen downto 3 do
      begin
        if Str[i + j - 1] <> Substr[j] then
        begin
          MayBe := False;
          Break
        end;
      end;
      if MayBe and ((LSubStrLen < 2) or (Substr[2] = Str[i + 1])) then
      begin
        Result := i;
        Exit;
      end;
      Inc(i);
    end
    else
      Exit;
  until False;
end;

function PosInSubstrExt(const SearchStr: string; Str: string; BeginPos, EndPos: Integer;
  BegSub, EndSub: TCharSet): Integer;
var
  P, L, l1: Integer;
begin
  Result := 0;
  P := PosInSubstr(SearchStr, Str, BeginPos, EndPos);
  L := Length(Str);
  l1 := Length(SearchStr);
  while P > 0 do
  begin
    if ((P = 1) or CharInSet(Str[P - 1], BegSub)) and (CharInSet(Str[P + l1], EndSub) or (P + l1 = L)) then
    begin
      Result := P;
      Exit;
    end;
    P := PosInSubstr(SearchStr, Str, P + l1, EndPos)
  end;
end;

function PosInSubstrCIExt(const SearchStr, Str: string; BeginPos, EndPos: Integer; BegSub, EndSub: TCharSet): Integer;
begin
  Result := PosInSubstrExt(AnsiUpperCase(SearchStr), AnsiUpperCase(Str), BeginPos, EndPos, BegSub, EndSub)
end;

function PosInSubstrCI(const SearchStr, Str: string; BeginPos, EndPos: Integer): Integer;
begin
  Result := PosInSubstr(AnsiUpperCase(SearchStr), AnsiUpperCase(Str), BeginPos, EndPos)
end;

function MakeStr(C: Char; N: Integer): string;
var
  i: Integer;
begin
  if N < 1 then
    Result := ''
  else
  begin
    SetLength(Result, N);
    // FillChar(Result[1], Length(Result)*SizeOf(Char), C);
    for i := 1 to N do
      Result[i] := C
  end;
end;

function StrAsFloat(S: string): double;
var
  i: Integer;
  AlterChar: Char;
begin
  if {$IFDEF D_XE3}FormatSettings.{$ENDIF}DecimalSeparator = '.' then
    AlterChar := ','
  else
    AlterChar := '.';
  for i := 1 to Length(S) do
  begin
    if S[i] = AlterChar then
      S[i] := {$IFDEF D_XE3}FormatSettings.{$ENDIF}DecimalSeparator
  end;
  Result := StrToFloat(S)
end;

function StrDDMMMYYYY(const D: string; var D1: string): Boolean;
begin
  Result := True;
  if Pos('JAN', D) <> 0 then
  begin
    D1 := ReplaceStr(D1, 'JAN', '01')
  end
  else if Pos('FEB', D) <> 0 then
    D1 := ReplaceStr(D, 'FEB', '02')
  else if Pos('MAR', D) <> 0 then
    D1 := ReplaceStr(D, 'MAR', '03')
  else if Pos('APR', D) <> 0 then
    D1 := ReplaceStr(D, 'APR', '04')
  else if Pos('MAY', D) <> 0 then
    D1 := ReplaceStr(D, 'MAY', '05')
  else if Pos('JUN', D) <> 0 then
    D1 := ReplaceStr(D, 'JUN', '06')
  else if Pos('JUL', D) <> 0 then
    D1 := ReplaceStr(D, 'JUL', '07')
  else if Pos('AUG', D) <> 0 then
    D1 := ReplaceStr(D, 'AUG', '08')
  else if Pos('SEP', D) <> 0 then
    D1 := ReplaceStr(D, 'SEP', '09')
  else if Pos('OCT', D) <> 0 then
    D1 := ReplaceStr(D, 'OCT', '10')
  else if Pos('NOV', D) <> 0 then
    D1 := ReplaceStr(D, 'NOV', '11')
  else if Pos('DEC', D) <> 0 then
    D1 := ReplaceStr(D, 'DEC', '12')
  else
    Result := False;
  if Result then
    D1 := ReplaceStr(D, '-',
      {$IFDEF D_XE3}FormatSettings.{$ENDIF}DateSeparator);
end;

function ToClientDateFmt(D: string; caseFmt: byte): string;
var
  Client_dateseparator, Client_timeseparator: Char;
  Client_LongDateFormat, Client_shortdateformat, Client_ShortTimeFormat: string;
  vD: TDateTime;
  IsKeyWord: Boolean;

begin
  if IsBlank(D) then
  begin
    Result := '';
    Exit;
  end;
  {$IFDEF D_XE3}with FormatSettings do {$ENDIF}
  begin
    Client_dateseparator := DateSeparator;
    Client_shortdateformat := ShortDateFormat;
    Client_timeseparator := TimeSeparator;
    Client_ShortTimeFormat := ShortTimeFormat;
    Client_LongDateFormat := LongDateFormat;
  end;

  IsKeyWord := False;
  Result := '';
  {$IFDEF D_XE3}with FormatSettings do {$ENDIF}
    try
      if caseFmt < 2 then
        if Pos('.', D) <> 0 then
        begin
          DateSeparator := '.';
          ShortDateFormat := 'dd.mm.yyyy';
        end
        else if Pos('/', D) <> 0 then
        begin
          DateSeparator := '/';
          ShortDateFormat := 'mm/dd/yyyy';
        end
        else if Pos('-', D) <> 0 then
        begin
          if StrDDMMMYYYY(D, D) then
            ShortDateFormat := 'dd.mm.yyyy'
          else
          begin
            DateSeparator := '/';
            D := ReplaceStr(D, '-', DateSeparator);
            ShortDateFormat := 'yyyy/mm/dd';
          end;
        end
        else
        begin
          Result := UpperCase(D);
          Exit;
        end;
      TimeSeparator := ':';
      ShortTimeFormat := 'h:m:s';
      case caseFmt of
        0:
          vD := StrToDateTime(D);
        1:
          vD := StrToDate(D);
        2:
          vD := StrToTime(D);
      else
        vD := StrToDateTime(D);
      end;
      if not IsKeyWord then
        case caseFmt of
          0:
            Result := DateTimeToStr(vD);
          1:
            Result := DateToStr(vD);
          2:
            Result := TimeToStr(vD);
        end

    finally
      LongDateFormat := Client_LongDateFormat;
      DateSeparator := Client_dateseparator;
      ShortDateFormat := Client_shortdateformat;
      TimeSeparator := Client_timeseparator;
      ShortTimeFormat := Client_ShortTimeFormat;
    end;
end;

function TrimCLRF(const S: string): string;
var
  P, p1: Integer;
begin

  p1 := Length(S);
  if p1 = 0 then
  begin
    Result := S;
    Exit;
  end;

  P := 1;
  while CharInSet(S[P], [' ', #13, #10, #9]) and (P < p1) do
    Inc(P);
  while CharInSet(S[p1], [' ', #13, #10, #9]) and (p1 > 0) do
    Dec(p1);
  if (p1 < Length(S)) or (P > 1) then
    Result := FastCopy(S, P, p1 - P + 1)
  else
    Result := S;
end;

procedure CopyChars(const Src: string; var Dest: string; StartInSrc, StartInDest, Count: Integer);
begin
  Move(Src[StartInSrc], Dest[StartInDest], Count * SizeOf(Char));
end;

function InternalReplaceStr(const S, S1, Srch, Replace: string): string;
var
  i, K, j, L, LR: Integer;
  LastLen: Integer;
  Diff: Integer;
  PosInResult: Integer;
  RCount: Integer;
label Again;

  procedure DoReplace(const Src: string; var PosInResult: Integer);
  begin
    if K = 0 then
    begin
      if Diff <> 0 then
        CopyChars(Src, Result, j, 1, i - 1);
      CopyChars(Replace, Result, 1, i, LR);
      PosInResult := i - 1 + LR;
      Inc(RCount);
    end
    else
    begin
      if Diff > 0 then
      begin
        Inc(LastLen, Diff);
        SetLength(Result, LastLen);
      end
      else
        Inc(RCount);
      if Diff <> 0 then
        CopyChars(Src, Result, j, PosInResult + 1, i - K - L);
      CopyChars(Replace, Result, 1, PosInResult + i - K - L + 1, LR);
      Inc(PosInResult, i - K - L + LR)
    end;

  end;

begin
  i := Pos(Srch, S1);
  if i = 0 then
    Result := S
  else
  begin
    L := Length(Srch);
    LR := Length(Replace);
    Diff := LR - L;
    K := 0;
    LastLen := Length(S);
    if Diff = 0 then
      Result := S
    else
    begin
      if Diff <= 0 then
        RCount := 0
      else
        Inc(LastLen, Diff);
      SetString(Result, nil, LastLen);
    end;

    j := 1;
    DoReplace(S, PosInResult);
    j := i + L;

  Again:
    K := i;
    i := PosInRight(Srch, S1, j);
    if i > 0 then
    begin
      DoReplace(S, PosInResult);
      j := i + L;
      goto Again;
    end;
    if Diff <> 0 then
      CopyChars(S, Result, j, PosInResult + 1, Length(S) - j + 1);
    if Diff < 0 then
      SetLength(Result, Length(S) + Diff * RCount);
  end;
end;

function ReplaceCIStr(const S, Srch, Replace: string; Ansi: Boolean = True): string;
begin
  if Ansi then
    Result := InternalReplaceStr(S, AnsiUpperCase(S), AnsiUpperCase(Srch), Replace)
  else
    Result := InternalReplaceStr(S, UpperCase(S), UpperCase(Srch), Replace)
end;

function ReplaceStr(const S, Srch, Replace: string): string;
begin
  Result := InternalReplaceStr(S, S, Srch, Replace)
end;

function ReplaceStrCIInSubstr(const Source: string; const Srch, Replace: string; BeginPos, EndPos: Integer): string;
var
  S: string;
begin
  S := ReplaceCIStr(Copy(Source, BeginPos, EndPos - BeginPos + 1), Srch, Replace);
  Result := Copy(Source, 1, BeginPos - 1) + S + Copy(Source, EndPos + 1, MaxInt);
end;

function ReplaceStrInSubstr(const Source: string; const Srch, Replace: string; BeginPos, EndPos: Integer): string;
var
  S: string;
begin
  S := ReplaceStr(Copy(Source, BeginPos, EndPos - BeginPos + 1), Srch, Replace);
  Result := Copy(Source, 1, BeginPos - 1) + S + Copy(Source, EndPos + 1, MaxInt);
end;

procedure DoUpperCase(var S: string; FirstPos: Integer = 1; LastPos: Integer = 0);
var
  i: Integer;
begin
  if (LastPos = 0) or (LastPos > Length(S)) then
    LastPos := Length(S);
  for i := LastPos downto FirstPos do
    if (S[i] >= 'a') and (S[i] <= 'z') then
      Dec(S[i], 32);
end;

procedure DoAnsiUpperCase(var S: AnsiString);
{$IFDEF WINDOWS}
var
  Len: Integer;
  {$ENDIF}
begin
  {$IFDEF WINDOWS}
  Len := Length(S);
  if Len > 0 then
    CharUpperBuffA(PAnsiChar(S), Len);
  {$ELSE}
  S := AnsiUpperCase(S)
  {$ENDIF}
end;

{$IFDEF D2009+}

procedure DoAnsiUpperCase(var S: string); overload;
begin
  S := AnsiUpperCase(S)
end;
{$ENDIF}

procedure DoWideUpperCase(var S: Widestring);
{$IFDEF WINDOWS}
var
  Len: Integer;
  {$ENDIF}
begin
  {$IFDEF WINDOWS}
  Len := Length(S);
  if Len > 0 then
    CharUpperBuffW(Pointer(S), Len);
  {$ELSE}
  S := WideUpperCase(S)
  {$ENDIF}
end;

{$WARNINGS OFF}

procedure DoUtf8Decode(const S: PAnsiChar; StrLen: Integer; var ws: Widestring);
var
  L: Integer;
begin
  if S = '' then
    Exit;
  SetLength(ws, StrLen);

  L := Utf8ToUnicode(PWideChar(ws), Length(ws) + 1, S, StrLen);
  if L > 0 then
    SetLength(ws, L - 1)
  else
    ws := '';
end;

procedure DoUtf8Decode(const S: AnsiString; var ws: Widestring);
begin
  {$IFDEF D2009+}
  ws := UTF8ToString(S)
  {$ELSE}
  ws := UTF8Decode(S)
  {$ENDIF}
end;

procedure DoUtf8Decode(const S: variant; var ws: Widestring);
begin
  {$IFDEF D2009+}
  ws := UTF8ToString(S)
  {$ELSE}
  ws := UTF8Decode(S)
  {$ENDIF}
end;

{$WARNINGS ON}

{
  procedure DoUtf8Decode(const s:variant; var ws:WideString);
  begin
  ws:=UTF8ToString(S)
  //UTF8Decode(s)

  end;
}
function FastUpperCase(const S: string): string;
var
  L: Integer;
  Source, Dest: PChar;
  EndSourse: PChar;
begin
  L := Length(S);
  SetLength(Result, L);
  Source := Pointer(S);
  EndSourse := Pointer(S);
  Inc(EndSourse, L);
  Dest := Pointer(Result);
  while EndSourse <> Source do
  begin
    if (Source^ >= 'a') and (Source^ <= 'z') then
      Dest^ := Char(byte(Source^) - 32)
    else
      Dest^ := Source^;
    Inc(Source);
    Inc(Dest);
  end;
end;

function EquelStrings(const S, S1: string; CaseSensitive: Boolean): Boolean;
var
  L: Integer;
  Source, Dest: PChar;
begin
  if CaseSensitive then
  begin
    Result := S = S1;
    Exit;
  end;
  L := Length(S);
  if L <> Length(S1) then
  begin
    Result := False;
    Exit;
  end;
  Source := Pointer(S);
  Dest := Pointer(S1);
  while L <> 0 do
  begin
    if Source^ > Dest^ then
    begin
      if (byte(Source^) - 32) <> byte(Dest^) then
      begin
        Result := False;
        Exit;
      end;
    end
    else if Source^ < Dest^ then
    begin
      if (byte(Source^) + 32) <> byte(Dest^) then
      begin
        Result := False;
        Exit;
      end;
    end;
    Inc(Source);
    Inc(Dest);
    Dec(L);
  end;
  Result := True;
end;

function ExtractWord(Num: Integer; const Str: string; const WordDelims: TCharSet): string;
var
  SLen, i: Integer;
  wc: Integer;
begin
  Result := '';
  i := 1;
  wc := 0;
  SLen := Length(Str);
  while i <= SLen do
  begin
    while (i <= SLen) and CharInSet(Str[i], WordDelims) do
      Inc(i);
    if i <= SLen then
      Inc(wc);
    if wc = Num then
      Break;
    while (i <= SLen) and not CharInSet(Str[i], WordDelims) do
      Inc(i);
  end;
  if (wc = 0) and (Num = 1) then
    Result := Str
  else if wc <> 0 then
  begin
    wc := i; // word start
    while (i < SLen) do
    begin
      Inc(i);
      if CharInSet(Str[i], WordDelims) then
      begin
        Dec(i);
        Break
      end;
    end;
    // I =End word position
    SLen := i - wc + 1; // result length
    SetLength(Result, SLen);
    if SLen > 0 then
      Move(Str[wc], Result[1], SLen * SizeOf(Char))
  end;
end;

{
  function ExtractLastWord(const Str:  String;const  WordDelims:TCharSet):String;
  var
  SLen, I: Cardinal;
  begin
  Result := '';
  SLen := Length(Str);
  while CharInSet(Str[SLen] , WordDelims) and (SLen>0) do
  Dec(SLen);
  for i:= SLen downto 1 do
  begin
  if not CharInSet(Str[I] ,WordDelims) then
  Result := Str[I]+Result
  else
  Exit
  end;
  end;
}
function WordCount(const S: string; const WordDelims: TCharSet): Integer;
var
  SLen, i: Cardinal;
begin
  Result := 0;
  i := 1;
  SLen := Length(S);
  while i <= SLen do
  begin
    while (i <= SLen) and CharInSet(S[i], WordDelims) do
      Inc(i);
    if i <= SLen then
      Inc(Result);
    while (i <= SLen) and not CharInSet(S[i], WordDelims) do
      Inc(i);
  end;
end;

function iifStr(Condition: Boolean; const Str1, Str2: string): string;
begin
  if Condition then
    Result := Str1
  else
    Result := Str2
end;

function iifVariant(Condition: Boolean; const Var1, Var2: variant): variant;
begin
  if Condition then
    Result := Var1
  else
    Result := Var2
end;

{$IFDEF D2009+}

function FirstPos(Search: array of Char; const InString: string): Integer;
var
  i: Integer;
  p1: Integer;
begin
  Result := 0;
  for i := Low(Search) to High(Search) do
  begin
    p1 := PosCh(Search[i], InString);
    if (p1 <> 0) then
      if (p1 < Result) or (Result = 0) then
        Result := p1
  end;
end;
{$ENDIF}

function FirstPos(Search: array of AnsiChar; const InString: AnsiString): Integer;
var
  i: Integer;
  p1: Integer;
begin
  Result := 0;
  for i := Low(Search) to High(Search) do
  begin
    // p1:=Q_StrScan(InString,Search[i],1);
    p1 := PosCh1(Search[i], InString, 1);
    if (p1 <> 0) then
      if (p1 < Result) or (Result = 0) then
        Result := p1
  end;
end;

function DoResultLine(const aLine: string): string;
var
  i, j: Integer;
  L: Integer;
begin
  if aLine = '' then
  begin
    Result := '';
    Exit;
  end;
  L := Length(aLine);
  if L = 1 then
  begin
    Result := aLine;
    Exit;
  end;

  i := 1;
  j := 0;
  SetLength(Result, L);
  while i <= L do
  begin
    if ((i < L) or (aLine[i] <> '*')) or ((j > 0) and (Result[j] <> '*')) then
    begin
      Inc(j);
      Result[j] := aLine[i];
    end;

    case aLine[i] of
      '*':
        repeat
          Inc(i);
        until not CharInSet(aLine[i], ['*', '?']) or (i = L);
      else
        Inc(i);
    end;

  end;
  SetLength(Result, j);
end;

function WildStringCompare(FirstString, SecondString: string): Boolean;
  function WildCompare(const FLine, SLine: string; OnlyOne: Boolean): Boolean;
  var
    K: Integer;
    l1, l2: Integer;
    p1, p2: Integer;

    function Different(const FLine, SLine: string; l1, l2: Integer): Boolean;
    begin
      if (l1 > 0) and (l2 > 0) then
      begin
        Result := (SLine[1] <> '*') and (SLine[1] <> '?') and (FLine[1] <> SLine[1]) and (FLine[1] <> '*') and
          (FLine[1] <> '?');

      end
      else
      begin
        Result := ((l1 = 0) and (SLine <> '*')) or ((l2 = 0) and (FLine <> '*'));
      end;
    end;

    function Identical(const FLine, SLine: string): Boolean;
    begin
      Result := (SLine = '*') or (FLine = '*') or (FLine = SLine)
    end;

  begin
    if Identical(FLine, SLine) then
    begin
      Result := True;
      Exit;
    end;
    Result := False;

    l1 := Length(FLine);
    l2 := Length(SLine);
    if Different(FLine, SLine, l1, l2) then
      Exit;

    if not CharInSet(SLine[1], ['*', '?']) and not CharInSet(FLine[1], ['*', '?']) then
    begin
      p1 := FirstPos(['?', '*'], FLine);
      if p1 = 0 then
        p1 := l1 + 1;
      p2 := FirstPos(['?', '*'], SLine);
      if p2 = 0 then
        p2 := l2 + 1;
      if p2 < p1 then
        p1 := p2;
      if (FastCopy(FLine, 1, p1 - 1) <> FastCopy(SLine, 1, p1 - 1)) then
        Result := False
      else
        Result := WildCompare(FastCopy(FLine, p1, l1), FastCopy(SLine, p1, l2), OnlyOne);
      Exit;
    end;

    if (FLine[1] = '*') then
    begin
      for K := 1 to l2 do
        if CharInSet(SLine[K], ['*', FLine[2], '?']) then
        begin
          Result := WildCompare(FastCopy(FLine, 2, l1 - 1), FastCopy(SLine, K, l2 - K + 1), OnlyOne);
          if Result then
            Exit
        end;
    end;

    if (SLine[1] = '*') then
      for K := 1 to l1 do
        if CharInSet(FLine[K], ['*', SLine[2], '?']) then
        begin
          Result := WildCompare(FastCopy(FLine, K, l1 - K + 1), FastCopy(SLine, 2, l2 - 1), OnlyOne);
          if Result then
            Exit
        end;

    if (SLine[1] <> '*') and ((FLine[1] <> '*')) and ((FLine[1] = SLine[1]) or ((SLine[1] = '?') or ((FLine[1] = '?'))))
    then
      Result := WildCompare(FastCopy(FLine, 2, l1 - 1), FastCopy(SLine, 2, l2 - 1), OnlyOne);
  end;

begin
  FirstString := DoResultLine(FirstString);
  SecondString := DoResultLine(SecondString);
  Result := WildCompare(FirstString, SecondString, False);
end;

function DoMaskCompare(const AString, Mask: string; MaskChars: array of Char): Boolean;

  function WildCompare1(const FLine, Mask: string): Boolean;
  var
    K: Integer;
    l1, l2: Integer;
    p1: Integer;

    function Different(const FLine, Mask: string; l1, l2: Integer): Boolean;
    begin
      if (l1 > 0) and (l2 > 0) then
      begin
        Result := not CharInSet(Mask[1], [MaskChars[0], MaskChars[1]]) and (FLine[1] <> Mask[1])
      end
      else
      begin
        Result := ((l1 = 0) and (Mask <> MaskChars[0])) or (l2 = 0)
      end;
    end;

    function Identical(const FLine, Mask: string): Boolean;
    begin
      Result := (Mask = MaskChars[0]) or (FLine = Mask)
    end;

  begin
    if Identical(FLine, Mask) then
    begin
      Result := True;
      Exit;
    end;
    Result := False;

    l1 := Length(FLine);
    l2 := Length(Mask);
    if Different(FLine, Mask, l1, l2) then
      Exit;

    if not CharInSet(Mask[1], [MaskChars[0], MaskChars[1]]) then
    begin
      p1 := FirstPos([MaskChars[0], MaskChars[1]], Mask);
      if p1 = 0 then
      begin
        Result := FLine = Mask
      end
      else if (FastCopy(FLine, 1, p1 - 1) <> FastCopy(Mask, 1, p1 - 1)) then
        Result := False
      else
        Result := WildCompare1(Copy(FLine, p1, l1), Copy(Mask, p1, l2));
      Exit;
    end;

    if (Mask[1] = MaskChars[0]) then
      for K := 1 to l1 do
        if (FLine[K] = Mask[2]) then
        begin
          Result := WildCompare1(Copy(FLine, K, l1 - K + 1), Copy(Mask, 2, l2 - 1));
          if Result then
            Exit
        end;

    if (Mask[1] <> MaskChars[0]) and ((FLine[1] = Mask[1]) or (Mask[1] = MaskChars[1])) then
      Result := WildCompare1(Copy(FLine, 2, l1 - 1), FastCopy(Mask, 2, l2 - 1));
  end;

begin // MaskCompare
  Result := WildCompare1(AString, DoResultLine(Mask));
end;

function SQLMaskCompare(const AString, Mask: string): Boolean;
begin
  Result := DoMaskCompare(AString, Mask, ['%', '_']);
end;

function SQLMaskCompareAW(const AString: AnsiString; const Mask: string): Boolean;
begin
  Result := DoMaskCompare(string(AString), Mask, ['%', '_']);
end;

{$WARNINGS OFF}

function SQLMaskCompareAA(const AString, Mask: AnsiString): Boolean;
begin
  Result := DoMaskCompare(string(AString), Mask, ['%', '_']);
end;
{$WARNINGS ON}
{$IFDEF D6+}

function SQLMaskCompare(const AString, Mask: Widestring): Boolean;
begin
  Result := DoMaskCompare(AString, Mask, ['%', '_']);
end;
{$ENDIF}

function MaskCompare(const AString, Mask: string): Boolean;
begin
  Result := DoMaskCompare(AString, Mask, ['*', '?']);
end;

function StrOnMask(const StrIn, MaskIn, MaskOut: string): string;
var
  K, j, Len: Integer;
begin
  Len := Length(StrIn);
  Result := '';
  for j := 1 to Len do
  begin
    K := PosCh(StrIn[j], MaskIn);
    if K = 0 then
      Result := Result + StrIn[j]
    else if Length(MaskOut) > K then
      Result := Result + MaskOut[K]
  end;
end;

function StrIsInteger(const Str: string): Boolean;
var
  L, i: Integer;
begin
  L := Length(Str);
  Result := False;
  for i := 1 to L do
  begin
    Result := CharInSet(Str[i], ['0', '1' .. '9']);
    if Result then
      Exit;
  end;
end;

function LastChar(const Str: string): Char;
var
  L: Integer;
begin
  L := Length(Str);
  if L > 0 then
    Result := Str[L]
  else
    Result := #0;
end;

function QuotedStr(const S: string): string;
var
  i: Integer;
begin
  Result := S;
  for i := Length(Result) downto 1 do
    if Result[i] = '''' then
      Insert('''', Result, i);
  Result := '''' + Result + '''';
end;

function CutQuote(const S: string): string;
var
  i: Integer;
  QuoteChar: Char;
  LastPos: Integer;
begin
  Result := S;
  QuoteChar := '&';
  LastPos := -1;
  for i := Length(Result) downto 1 do
    case Result[i] of
      '''', '"':
        begin
          QuoteChar := Result[i];
          LastPos := i;
          Break;
        end;
      ' ', #9, #13, #10:
        ;
    else
      Exit;
    end;
  for i := 1 to LastPos - 1 do
    case Result[i] of
      '''', '"':
        if Result[i] = QuoteChar then
        begin
          Result := FastCopy(Result, i + 1, LastPos - i - 1);
          Exit;
        end;
      ' ', #9, #13, #10:
        ;
    else
      Exit;
    end;
end;

function EmptyStrings(SL: TStrings): Boolean;
var
  i, L: Integer;
begin
  Result := SL.Count = 0;
  if not Result then
  begin
    L := SL.Count - 1;
    for i := 0 to L do
    begin
      Result := (Length(SL[i]) = 0) or (Length(Trim(SL[i])) = 0);
      if not Result then
        Exit;
    end;
  end;
end;

procedure DeleteEmptyStr(Src: TStrings);
var
  i: Integer;
begin
  i := 0;
  while i < Src.Count do
  begin
    if Src[i] = '' then
      Src.Delete(i)
    else
      Inc(i)
  end;
end;

function NonAnsiSortCompareStrings(SL: TStringList; Index1, Index2: Integer): Integer;
begin
  {$IFDEF D6+}
  if SL.CaseSensitive then
    Result := CompareStr(SL[Index1], SL[Index2])
  else
    {$ENDIF}
    Result := CompareText(SL[Index1], SL[Index2]);
end;

type
  THackStringList = class(TStrings)
  private
    {$IFNDEF D_XE2}
    FList: PStringItemList;
    {$ELSE}
    FList: TStringItemList;
    {$ENDIF}
    FCount: Integer;
  end;

function NonAnsiIndexOf(SL: TStringList; const S: string): Integer; // Non Ansi
var
  C: Integer;
begin
  C := THackStringList(SL).FCount - 1;
  for Result := 0 to C do
    {$IFNDEF D_XE2}
    if THackStringList(SL).FList^[Result].FString = S then
    {$ELSE}
    if THackStringList(SL).FList[Result].FString = S then
      {$ENDIF}
      Exit;
  Result := -1;
end;

function FindInDiapazon(SL: TStringList; const S: string; const StartIndex, EndIndex: Integer; AnsiCompare: Boolean;
  var Index: Integer): Boolean;
var
  L, H, i, C: Integer;
  function CompareStrings(const S1, S2: string): Integer;
  begin
    if AnsiCompare then
    begin
      {$IFDEF D6+}
      if SL.CaseSensitive then
        Result := AnsiCompareStr(S1, S2)
      else
        {$ENDIF}
        Result := AnsiCompareText(S1, S2);
    end
    else
    begin
      {$IFDEF D6+}
      if SL.CaseSensitive then
        Result := CompareStr(S1, S2)
      else
        {$ENDIF}
        Result := CompareText(S1, S2);
    end;
  end;

begin
  Result := False;
  with SL do
  begin
    if StartIndex < 0 then
      L := 0
    else
      L := StartIndex;
    if EndIndex >= Count then
      H := Count - 1
    else
      H := EndIndex;
    while L <= H do
    begin
      i := (L + H) shr 1;
      C := CompareStrings(Strings[i], S);
      if C < 0 then
        L := i + 1
      else
      begin
        H := i - 1;
        if C = 0 then
        begin
          Result := True;
          if Duplicates <> dupAccept then
            L := i;
        end;
      end;
    end;
    Index := L;
  end;

end;

procedure SLDifference(ASL, BSL: TStringList; ResultSL: TStrings);
var
  i, C, j: Integer;
begin
  ResultSL.Clear;
  C := Pred(ASL.Count);
  if not BSL.Sorted then
    for i := 0 to C do
    begin
      if BSL.IndexOf(ASL[i]) = -1 then
        ResultSL.AddObject(ASL[i], ASL.Objects[i])
    end
  else
    for i := 0 to C do
    begin
      if not BSL.Find(ASL[i], j) then
        ResultSL.AddObject(ASL[i], ASL.Objects[i])
    end
end;

{$WARNINGS OFF}

procedure GetNameAndValue(const S: string; var Name, Value: AnsiString);
var
  pEq: Integer;
begin
  pEq := PosCh('=', S);
  if pEq = 0 then
  begin
    Name := S;
    Value := ''
  end
  else
  begin
    Name := FastCopy(S, 1, pEq - 1);
    Value := FastCopy(S, pEq + 1, Length(S))
  end;
end;

var
  KeyWordsIndexes: array ['A' .. 'Z', 'A' .. 'Z', 0 .. 1] of Word;
  KeyWords: TStringList;

const
  NonQuotedChars = ['_', '$', '%', '#'];

function InternalNeedQuote(const Name: string; Easy: Boolean): Boolean;
{$IFDEF D2007+} inline; {$ENDIF}
var
  i, L: Integer;
  ch1, Ch2: Char;
begin
  Result := Name <> '';
  if not Result then
    Exit;
  Result := Name[1] <> '"';
  if not Result then
    Exit;
  L := Length(Name);
  for i := 1 to L do
  begin
    Result := ((Name[i] < 'A') or (Name[i] > 'Z')) and ((Name[i] < '0') or (Name[i] > '9')) and
      ((i = 1) or not CharInSet(Name[i], NonQuotedChars));
    if Result and (Easy and (Name[i] >= 'a') and (Name[i] <= 'z')) then
      Result := False;
    if Result then
      Exit;
  end;
  ch1 := Name[1];
  if (ch1 >= '0') and (ch1 <= '9') then
  begin
    Result := True;
    Exit;
  end;
  if L > 1 then
  begin
    Ch2 := Name[2];
    if (Ch2 >= '0') and (Ch2 <= '9') then
    begin
      Result := False;
      Exit;
    end;
    if Easy then
    begin
      if (ch1 >= 'a') and (ch1 <= 'z') then
        Dec(ch1, 32);
      if (Ch2 >= 'a') and (Ch2 <= 'z') then
        Dec(Ch2, 32);
    end;
    Result := FindInDiapazon(KeyWords, Name, KeyWordsIndexes[ch1, Ch2, 0], KeyWordsIndexes[ch1, Ch2, 1], False, i)
  end;
end;

function NeedQuote(const Name: string): Boolean;
begin
  Result := InternalNeedQuote(Name, False);
end;

function EasyNeedQuote(const Name: string): Boolean;
begin
  Result := InternalNeedQuote(Name, True);
end;
{$IFNDEF D6+}

function WideUpperCase(const S: Widestring): Widestring;
var
  Len: Integer;
begin
  Len := Length(S);
  SetString(Result, PWideChar(S), Len);
  if Len > 0 then
    CharUpperBuffW(Pointer(Result), Len);
end;
{$ENDIF}
{$IFDEF CPUX86}

function Q_StrLen(P: PAnsiChar): Cardinal; assembler;
asm
  TEST    EAX,EAX
  JE      @@qt
  PUSH    EBX
  LEA     EDX,[EAX+1]
@L1:    MOV     EBX,[EAX]
  ADD     EAX,4
  LEA     ECX,[EBX-$01010101]
  NOT     EBX
  AND     ECX,EBX
  AND     ECX,$80808080
  JZ      @L1
  TEST    ECX,$00008080
  JZ      @L2
  SHL     ECX,16
  SUB     EAX,2
@L2:    SHL     ECX,9
  SBB     EAX,EDX
  POP     EBX
@@qt:
end;
{$ELSE}

function Q_StrLen(P: PAnsiChar): Cardinal;
begin
  Result := StrLen(P)
end;
{$ENDIF}

const
  InternalFunctionCount = 32;
  DefKeywordsCount = 280;
  DefTypesCount = 17;

  InternalFunctions: array [0 .. InternalFunctionCount - 1] of AnsiString = ('AVG', 'CAST', 'COUNT', 'GEN_ID', 'MAX',
    'MIN', 'SUM', 'UPPER',
    // Additional FB and YA
    'IIF', 'SUBSTRING',
    // FB3 (https://firebirdsql.org/file/documentation/release_notes/html/en/3_0/bk02ch09s05.html)
    'ACOSH', 'ASINH', 'ATANH', 'COSH', 'SINH', 'TANH', 'VAR_SAMP', 'VAR_POP', 'STDDEV_SAMP', 'STDDEV_POP', 'COVAR_SAMP',
    'COVAR_POP', 'CORR', 'REGR_AVGX', 'REGR_AVGY', 'REGR_COUNT', 'REGR_INTERCEPT', 'REGR_R2', 'REGR_SLOPE', 'REGR_SXX',
    'REGR_SXY', 'REGR_SYY');
  DefKeywords: array [0 .. DefKeywordsCount - 1] of AnsiString = ('ACTIVE', 'ADD', 'AFTER', 'ALL', 'ALTER', 'AND',
    'ANY', 'AS', 'ASC', 'ASCENDING', 'AT', 'AUTO', 'AUTODDL', 'BASED', 'BASENAME', 'BASE_NAME', 'BEFORE', 'BEGIN',
    'BETWEEN', 'BLOBEDIT', 'BUFFER', 'BY', 'CASE', 'CACHE', 'CHARACTER_LENGTH', 'CHAR_LENGTH', 'CHECK',
    'CHECK_POINT_LEN', 'CHECK_POINT_LENGTH', 'COLLATE', 'COLLATION', 'COLUMN', 'COMMIT', 'COMMITED', 'COMPILETIME',
    'COMPUTED', 'CROSS', 'CLOSE', 'CONDITIONAL', 'CONNECT', 'CONSTRAINT', 'CONTAINING', 'CONTINUE', 'CREATE', 'CURRENT',
    'CURRENT_DATE', 'CURRENT_TIME', 'CURRENT_TIMESTAMP', 'CURSOR', 'DATABASE', 'DAY', 'DB_KEY', 'DEBUG', 'DEC',
    'DECLARE', 'DEFAULT', 'DELETE', 'DESC', 'DESCENDING', 'DESCRIBE', 'DESCRIPTOR', 'DISCONNECT', 'DISTINCT', 'DO',
    'DOMAIN', 'DROP', 'ECHO', 'EDIT', 'ELSE', 'END', 'ENTRY_POINT', 'ESCAPE', 'EVENT', 'EXCEPTION', 'EXECUTE', 'EXISTS',
    'EXIT', 'EXTERN', 'EXTERNAL', 'EXTRACT', 'FALSE', 'FETCH', 'FILE', 'FILTER', 'FOR', 'FOREIGN', 'FOUND', 'FROM',
    'FULL', 'FUNCTION', 'GDSCODE', 'GENERATOR', 'GLOBAL', 'GOTO', 'GRANT', 'GROUP', 'GROUP_COMMIT_WAIT',
    'GROUP_COMMIT_WAIT_TIME', 'HAVING', 'HELP', 'HOUR', 'IF', 'IMMEDIATE', 'IN', 'INACTIVE', 'INDEX', 'INDICATOR',
    'INIT', 'INNER', 'INPUT', 'INPUT_TYPE', 'INSERT', 'INT', 'INTO', 'IS', 'ISOLATION', 'ISQL', 'JOIN', 'KEY',
    'LC_MESSAGES', 'LC_TYPE', 'LEFT', 'LENGTH', 'LEV', 'LEVEL', 'LIKE', 'LOGFILE', 'LOG_BUFFER_SIZE', 'LOG_BUF_SIZE',
    'LONG', 'MANUAL', 'MAXIMUM', 'MAXIMUM_SEGMENT', 'MAX_SEGMENT', 'MERGE', 'MESSAGE', 'MINIMUM', 'MINUTE',
    'MODULE_NAME', 'MONTH', 'NAMES', 'NATIONAL', 'NATURAL', 'NCHAR', 'NO', 'NOAUTO', 'NOT', 'NULL', 'NUM_LOG_BUFFS',
    'NUM_LOG_BUFFERS', 'OCTET_LENGTH', 'OF', 'ON', 'ONLY', 'OPEN', 'OPTION', 'OR', 'ORDER', 'OUTER', 'OUTPUT',
    'OUTPUT_TYPE', 'OVERFLOW', 'PAGE', 'PAGELENGTH', 'PAGES', 'PAGE_SIZE', 'PARAMETER', 'PASSWORD', 'PLAN', 'POSITION',
    'POST_EVENT', 'PRECISION', 'PREPARE', 'PROCEDURE', 'PROTECTED', 'PRIMARY', 'PRIVILEGES', 'PUBLIC', 'QUIT',
    'RAW_PARTITIONS', 'READ', 'REAL', 'RECORD_VERSION', 'REFERENCES', 'RELEASE', 'RESERV', 'RESERVING', 'RETAIN',
    'RETURN', 'RETURNING_VALUES', 'RETURNS', 'REVOKE', 'RIGHT', 'ROLLBACK', 'ROWS', 'RUNTIME', 'SAVEPOINT', 'SCHEMA',
    'SECOND', 'SEGMENT', 'SELECT', 'SEQUENCE', 'SET', 'SHADOW', 'SHARED', 'SHELL', 'SHOW', 'SIMILAR', 'SINGULAR',
    'SIZE', 'SNAPSHOT', 'SOME', 'SORT', 'SQL', 'SQLCODE', 'SQLERROR', 'SQLWARNING', 'STABILITY', 'STARTING', 'STARTS',
    'STATEMENT', 'STATIC', 'STATISTICS', 'SUB_TYPE', 'SUSPEND', 'TABLE', 'TERMINATOR', 'THEN', 'TO', 'TRANSACTION',
    'TRANSLATE', 'TRANSLATION', 'TRIGGER', 'TRIM', 'TRUE', 'TYPE', 'UNCOMMITTED', 'UNION', 'UNIQUE', 'UNKNOWN',
    'UPDATE', 'USER', 'USING', 'VALUE', 'VALUES', 'VARIABLE', 'VARYING', 'VERSION', 'VIEW', 'WAIT', 'WEEKDAY', 'WHEN',
    'WHENEVER', 'WHERE', 'WHILE', 'WITH', 'WORK', 'WRITE', 'YEAR', 'YEARDAY',
    // Additional
    'FIRST', 'SKIP', 'RECREATE', 'CURRENT_USER', 'CURRENT_ROLE', 'PLANONLY', 'LIMIT', 'SECONDS', 'ROWS', 'PERCENT',
    'TIES', 'NEW', 'OLD', 'CURRENT_CONNECTION', 'CURRENT_TRANSACTION',

    'INSERTING', 'UPDATING', 'DELETING', 'ROW_COUNT', 'FREE_IT');

  DefTypes: array [0 .. DefTypesCount - 1] of AnsiString = ('BLOB', 'AnsiChar', 'CHARACTER', 'DATE', 'DECIMAL',
    'DOUBLE', 'FLOAT', 'INTEGER', 'NUMERIC', 'SMALLINT', 'TIME', 'TIMESTAMP', 'VARCHAR',
    // Additional
    'INT64', 'BIGINT', 'BOOLEAN', 'CSTRING');

var
  vI: Integer;
  OldChar: Char;
  OldChar1: Char;

{$IFNDEF D_XE5}
{ TFastStringStream }

constructor TFastStringStream.Create(const AString: string);
begin
  inherited Create;
  FElementSize := SizeOf(Char);
  WriteString(AString);;
  FPosition := 0;
end;

destructor TFastStringStream.Destroy;
begin
  FDataString := '';
  inherited Destroy
end;

function TFastStringStream.GetDataString: string;
begin
  Result := FDataString;
  SetLength(Result, FActualLength)
end;

function TFastStringStream.CurMemory: Pointer;
begin
  if (FPosition < FSize) and (FPosition >= 0) then
    Result := @(FDataString[FPosition + 1])
  else
    Result := nil
end;

procedure TFastStringStream.Grow(Min: Integer);
begin
  if FSize < 1024 then
    if Min < 1024 then
      SetSize(1024)
    else
      SetSize(FSize + Min)
  else
  begin
    if Min < (FSize div 4) then
      SetSize((FSize + (FSize div 4)))
    else
      SetSize(FSize + Min)
  end
end;

procedure TFastStringStream.PackData;
begin
  SetSize(FActualLength)
end;

function TFastStringStream.Read(var Buffer; Count: Integer): Longint;
var
  FMemory: Pointer;
begin
  Result := FSize - FPosition;
  if Result > 0 then
  begin
    if Result > Count then
      Result := Count;
    FMemory := CurMemory;
    Move(PChar(FMemory)^, Buffer, Result * SizeOf(Char));
    Inc(FPosition, Result);
  end;
end;

function TFastStringStream.ReadString(Count: Integer): string;
var
  Len: Integer;
  FMemory: Pointer;
begin
  Len := FSize - FPosition;
  if Len > Count then
    Len := Count;
  FMemory := CurMemory;
  SetString(Result, PChar(FMemory), Len);
  Inc(FPosition, Len);
end;

function TFastStringStream.Seek(Offset: Integer; Origin: Word): Longint;
begin
  case Origin of
    soFromBeginning:
      FPosition := Offset;
    soFromCurrent:
      FPosition := FPosition + Offset;
    soFromEnd:
      FPosition := FSize - Offset;
  end;
  if FPosition > FSize then
    FPosition := FSize
  else if FPosition < 0 then
    FPosition := 0;
  Result := FPosition;
end;

procedure TFastStringStream.SetSize(aNewSize: Integer);
begin
  if aNewSize <> FSize then
  begin
    SetLength(FDataString, aNewSize);
    FSize := aNewSize;
    if FPosition > aNewSize then
      FPosition := aNewSize;
    if FActualLength > aNewSize then
      FActualLength := aNewSize;
  end;
end;

function TFastStringStream.Write(const Buffer; Count: Integer): Longint;
var
  FMemory: Pointer;
begin
  Result := Count;
  if Result > 0 then
  begin
    if FPosition + Result > FSize then
      Grow(Result);
    FMemory := CurMemory;
    Move(Buffer, PChar(FMemory)^, Result * FElementSize);
    Inc(FPosition, Result);
    if FPosition > FActualLength then
      FActualLength := FPosition;
  end
end;

procedure TFastStringStream.WriteString(const AString: string);
begin
  {$IFNDEF   D2009+}
  Write(PChar(AString)^, Length(AString))
  {$ELSE}
  if StringCodePage(AString) = StringCodePage(FDataString) then
    Write(PChar(AString)^, Length(AString))
  else
  begin
    FDataString := FDataString + AString;
    SetSize(Length(FDataString));
    FActualLength := Length(FDataString);
    FElementSize := StringElementSize(FDataString);
  end;
  {$ENDIF}
end;

{$ENDIF}

function Position(AX, AY: Integer): TPosition;
begin
  Result.X := AX;
  Result.Y := AY;
end;

initialization

  KeyWords := TStringList.Create;
  for vI := 0 to InternalFunctionCount - 1 do
    KeyWords.Add(InternalFunctions[vI]);
  for vI := 0 to DefKeywordsCount - 1 do
    KeyWords.Add(DefKeywords[vI]);
  for vI := 0 to DefTypesCount - 1 do
    KeyWords.Add(DefTypes[vI]);
  KeyWords.CustomSort(NonAnsiSortCompareStrings);
  OldChar := 'A';
  OldChar1 := 'A';
  KeyWordsIndexes['A', 'A', 0] := 0;
  for vI := 0 to KeyWords.Count - 1 do
    if (OldChar <> KeyWords[vI][1]) or (OldChar1 <> KeyWords[vI][2]) then
    begin
      KeyWordsIndexes[OldChar, OldChar1, 1] := vI - 1;
      KeyWordsIndexes[KeyWords[vI][1], KeyWords[vI][2], 0] := vI;
      OldChar := KeyWords[vI][1];
      OldChar1 := KeyWords[vI][2];
    end;
  KeyWordsIndexes[OldChar, OldChar1, 1] := KeyWords.Count - 1;

finalization

  KeyWords.Free

end.
