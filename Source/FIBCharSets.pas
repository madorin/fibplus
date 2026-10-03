{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ InterBase databases                                           }
{                                                               }
{  Text of a character set to string and back, through the      }
{  code page of the character set.                              }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit FIBCharSets;

interface

{$I FIBPlus.inc}

uses
  FIBPlatforms;

const
  FIBCodePageSystem = 0;
  FIBCodePageUTF8 = 65001;

// FIBCodePageSystem for NONE, OCTETS and unknown IDs
function FirebirdCharSetCodePage(CharSetID: Integer): Word;
// '' for an unknown ID
function FirebirdCharSetName(CharSetID: Integer): string;

// Before Delphi 2009 only UTF-8 is converted
function DecodeString(Buffer: PAnsiChar; Length: Integer; CodePage: Word): string; overload;
function DecodeString(const Bytes: FIBByteString; CodePage: Word): string; overload;
// Not tagged with CodePage: concatenating tagged AnsiStrings converts them
function EncodeString(const S: string; CodePage: Word): FIBByteString;
// Before Delphi 2009 UTF-8 without the loss of DecodeString
function DecodeWideString(const Bytes: FIBByteString; CodePage: Word): WideString;
{$IFDEF D2009+}
procedure SetStringCodePage(var S: RawByteString; CodePage: Word);
function IsSystemCodePage(CodePage: Word): Boolean;
{$ENDIF}

implementation

uses
  fib, FIBConsts
{$IFDEF D2009+}{$IFNDEF D_XE}, Windows{$ENDIF}{$ENDIF};

type
  TFirebirdCharSet = record
    Name: string;
    CodePage: Word;
  end;

const
  // By RDB$CHARACTER_SET_ID. ISO8859_1/9 as 1252/1254 (printable characters instead of the C1
  // controls), ASCII as the system code page, CYRL is CP1251
  FirebirdCharSets: array [0 .. 69] of TFirebirdCharSet = (
    (Name: 'NONE'; CodePage: FIBCodePageSystem), // 0
    (Name: 'OCTETS'; CodePage: FIBCodePageSystem),
    (Name: 'ASCII'; CodePage: FIBCodePageSystem),
    (Name: 'UNICODE_FSS'; CodePage: FIBCodePageUTF8),
    (Name: 'UTF8'; CodePage: FIBCodePageUTF8),
    (Name: 'SJIS_0208'; CodePage: 932),
    (Name: 'EUCJ_0208'; CodePage: 20932),
    (Name: ''; CodePage: FIBCodePageSystem),
    (Name: ''; CodePage: FIBCodePageSystem),
    (Name: 'DOS737'; CodePage: 737),
    (Name: 'DOS437'; CodePage: 437), // 10
    (Name: 'DOS850'; CodePage: 850),
    (Name: 'DOS865'; CodePage: 865),
    (Name: 'DOS860'; CodePage: 860),
    (Name: 'DOS863'; CodePage: 863),
    (Name: 'DOS775'; CodePage: 775),
    (Name: 'DOS858'; CodePage: 858),
    (Name: 'DOS862'; CodePage: 862),
    (Name: 'DOS864'; CodePage: 864),
    (Name: 'NEXT'; CodePage: FIBCodePageSystem),
    (Name: ''; CodePage: FIBCodePageSystem), // 20
    (Name: 'ISO8859_1'; CodePage: 1252),
    (Name: 'ISO8859_2'; CodePage: 28592),
    (Name: 'ISO8859_3'; CodePage: 28593),
    (Name: ''; CodePage: FIBCodePageSystem),
    (Name: ''; CodePage: FIBCodePageSystem),
    (Name: ''; CodePage: FIBCodePageSystem),
    (Name: ''; CodePage: FIBCodePageSystem),
    (Name: ''; CodePage: FIBCodePageSystem),
    (Name: ''; CodePage: FIBCodePageSystem),
    (Name: ''; CodePage: FIBCodePageSystem), // 30
    (Name: ''; CodePage: FIBCodePageSystem),
    (Name: ''; CodePage: FIBCodePageSystem),
    (Name: ''; CodePage: FIBCodePageSystem),
    (Name: 'ISO8859_4'; CodePage: 28594),
    (Name: 'ISO8859_5'; CodePage: 28595),
    (Name: 'ISO8859_6'; CodePage: 28596),
    (Name: 'ISO8859_7'; CodePage: 28597),
    (Name: 'ISO8859_8'; CodePage: 28598),
    (Name: 'ISO8859_9'; CodePage: 1254),
    (Name: 'ISO8859_13'; CodePage: 28603), // 40
    (Name: ''; CodePage: FIBCodePageSystem),
    (Name: ''; CodePage: FIBCodePageSystem),
    (Name: ''; CodePage: FIBCodePageSystem),
    (Name: 'KSC_5601'; CodePage: 949),
    (Name: 'DOS852'; CodePage: 852),
    (Name: 'DOS857'; CodePage: 857),
    (Name: 'DOS861'; CodePage: 861),
    (Name: 'DOS866'; CodePage: 866),
    (Name: 'DOS869'; CodePage: 869),
    (Name: 'CYRL'; CodePage: 1251), // 50
    (Name: 'WIN1250'; CodePage: 1250),
    (Name: 'WIN1251'; CodePage: 1251),
    (Name: 'WIN1252'; CodePage: 1252),
    (Name: 'WIN1253'; CodePage: 1253),
    (Name: 'WIN1254'; CodePage: 1254),
    (Name: 'BIG_5'; CodePage: 950),
    (Name: 'GB_2312'; CodePage: 936),
    (Name: 'WIN1255'; CodePage: 1255),
    (Name: 'WIN1256'; CodePage: 1256),
    (Name: 'WIN1257'; CodePage: 1257), // 60
    (Name: ''; CodePage: FIBCodePageSystem),
    (Name: ''; CodePage: FIBCodePageSystem),
    (Name: 'KOI8R'; CodePage: 20866),
    (Name: 'KOI8U'; CodePage: 21866),
    (Name: 'WIN1258'; CodePage: 1258),
    (Name: 'TIS620'; CodePage: 874),
    (Name: 'GBK'; CodePage: 936),
    (Name: 'CP943C'; CodePage: 932),
    (Name: 'GB18030'; CodePage: 54936));

function FirebirdCharSetCodePage(CharSetID: Integer): Word;
begin
  if (CharSetID >= Low(FirebirdCharSets)) and (CharSetID <= High(FirebirdCharSets)) then
    Result := FirebirdCharSets[CharSetID].CodePage
  else
    Result := FIBCodePageSystem;
end;

function FirebirdCharSetName(CharSetID: Integer): string;
begin
  if (CharSetID >= Low(FirebirdCharSets)) and (CharSetID <= High(FirebirdCharSets)) then
    Result := FirebirdCharSets[CharSetID].Name
  else
    Result := '';
end;

{$IFDEF D2009+}

const
  WC_NO_BEST_FIT_CHARS = $400;
  GB18030CodePage = 54936;

procedure CodePageError(CodePage: Word);
begin
  FIBErrorEx(SCodePageNotAvailable, [CodePage]);
end;

function ActualCodePage(CodePage: Word): Word;
begin
  if CodePage = FIBCodePageSystem then
    Result := DefaultSystemCodePage
  else
    Result := CodePage;
end;

procedure SetStringCodePage(var S: RawByteString; CodePage: Word);
begin
  SetCodePage(S, ActualCodePage(CodePage), False);
end;

function IsSystemCodePage(CodePage: Word): Boolean;
begin
  Result := ActualCodePage(CodePage) = DefaultSystemCodePage;
end;

function ToUnicode(CodePage: Word; Buffer: PAnsiChar; Length: Integer; Dest: PWideChar; DestLength: Integer): Integer;
begin
{$IFDEF D_XE}
  Result := UnicodeFromLocaleChars(CodePage, 0, Buffer, Length, Dest, DestLength);
{$ELSE}
  Result := MultiByteToWideChar(CodePage, 0, Buffer, Length, Dest, DestLength);
{$ENDIF}
end;

function FromUnicode(CodePage: Word; Source: PWideChar; Length: Integer; Dest: PAnsiChar; DestLength: Integer;
  UsedDefault: PLongBool): Integer;
var
  Flags: Cardinal;
begin
  // UTF-8 and GB18030 accept no flags; no best fit: U+0219 must not become 's'
  if (CodePage = FIBCodePageUTF8) or (CodePage = GB18030CodePage) then
  begin
    Flags := 0;
    UsedDefault := nil;
  end
  else
    Flags := WC_NO_BEST_FIT_CHARS;
{$IFDEF D_XE}
  Result := LocaleCharsFromUnicode(CodePage, Flags, Source, Length, Dest, DestLength, nil, UsedDefault);
{$ELSE}
  Result := WideCharToMultiByte(CodePage, Flags, Source, Length, Dest, DestLength, nil, UsedDefault);
{$ENDIF}
end;

function DecodeString(Buffer: PAnsiChar; Length: Integer; CodePage: Word): string;
var
  L: Integer;
begin
  Result := '';
  if Length <= 0 then
    Exit;
  CodePage := ActualCodePage(CodePage);
  // never more UTF-16 units than bytes
  SetLength(Result, Length);
  L := ToUnicode(CodePage, Buffer, Length, PWideChar(Result), Length);
  if L = 0 then
    CodePageError(CodePage);
  SetLength(Result, L);
end;

function EncodeString(const S: string; CodePage: Word): FIBByteString;
var
  L: Integer;
  UsedDefault: LongBool;
begin
  Result := '';
  if S = '' then
    Exit;
  CodePage := ActualCodePage(CodePage);
  UsedDefault := False;
  L := FromUnicode(CodePage, PWideChar(S), Length(S), nil, 0, @UsedDefault);
  if L = 0 then
    CodePageError(CodePage);
  // as the server does
  if UsedDefault then
    FIBErrorEx(SCannotTransliterate, [Copy(S, 1, 100), CodePage]);
  SetLength(Result, L);
  FromUnicode(CodePage, PWideChar(S), Length(S), PAnsiChar(Result), L, nil);
end;

{$ELSE}

function DecodeString(Buffer: PAnsiChar; Length: Integer; CodePage: Word): string;
begin
  SetString(Result, Buffer, Length);
  if CodePage = FIBCodePageUTF8 then
    Result := UTF8Decode(Result);
end;

function EncodeString(const S: string; CodePage: Word): FIBByteString;
begin
  if CodePage = FIBCodePageUTF8 then
    Result := UTF8Encode(S)
  else
    Result := S;
end;

{$ENDIF}

function DecodeString(const Bytes: FIBByteString; CodePage: Word): string;
begin
  Result := DecodeString(PAnsiChar(Bytes), Length(Bytes), CodePage);
end;

function DecodeWideString(const Bytes: FIBByteString; CodePage: Word): WideString;
begin
{$IFDEF D2009+}
  Result := DecodeString(Bytes, CodePage);
{$ELSE}
  if CodePage = FIBCodePageUTF8 then
    Result := UTF8Decode(Bytes)
  else
    Result := Bytes;
{$ENDIF}
end;

end.
