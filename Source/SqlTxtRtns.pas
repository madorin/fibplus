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

unit SqlTxtRtns;

{$I FIBPlus.inc}

interface

uses
  SysUtils, Classes, FIBPlatforms, StrUtil, DB, Variants;

type

  TSQLKind = (
    skUnknown,
    skSelect,
    skUpdate,
    skInsert,
    skDelete,
    skExecuteProc,
    skDDL,
    skExecuteBlock,
    skUpdateOrInsert
  );
  TParserState = (sNormal, sQuote, sComment, sFBComment, sQuoteSingle);
  TOnScanSQLText = procedure(Position: integer; var StopScan: boolean) of object;
  TChars = set of AnsiChar;

  TSQLSection = (
    stUnknown,
    stSelect,
    stFields,
    stUpdate,
    stInsert,
    stDelete,
    stExecute,
    stSet,
    stComment,
    stFrom,
    stWhere,
    stGroupBy,
    stHaving,
    stUnion,
    stPlan,
    stOrderBy,
    stForUpdate
  );

  TSQLSections = array of TSQLSection;

  TSQLParser = class
  private
    FState: TParserState;
    FResultPos: integer;
    FBracketOpened: integer;
    FSQLText: string;
    FLen: integer;
    FReserved: integer;
    FReserved1: integer;
    FScanInBrackets: boolean;
    FFirstPos: integer;
    FSQLKind: TSQLKind;
    FCanParamsCheck: boolean;
    FTables: TStrings;
    FBracketOpenedBeforeScan: integer;
    // the main SELECT, after the WITH clause of a CTE
    FSelectPos: Integer;
  protected
    procedure SetSQLText(const Value: string);
    function IsClause(Position: integer; const Clause: string): boolean;
    function GetSQLKind: TSQLKind;
    procedure IsOrderBegin(Position: integer; var Yes: boolean);
    procedure IsGroupBegin(Position: integer; var Yes: boolean);
    procedure IsByBegin(Position: integer; var Yes: boolean);
    procedure IsHaving(Position: integer; var Yes: boolean);
    procedure IsMainOrderBegin(Position: integer; var Yes: boolean);
    procedure IsMainGroupBegin(Position: integer; var Yes: boolean);
    procedure IsFromBegin(Position: integer; var Yes: boolean);
    procedure IsWhereBegin(Position: integer; var Yes: boolean);
    procedure IsWhereEnd(Position: integer; var Yes: boolean);

    procedure IsMainWhereBegin(Position: integer; var Yes: boolean);
    procedure IsMainFromBegin(Position: integer; var Yes: boolean);
    procedure IsFromEnd(Position: integer; var Yes: boolean);
    procedure IsOrderEnd(Position: Integer; var Yes: Boolean);
    procedure IsGroupEnd(Position: Integer; var Yes: Boolean);
    procedure IsMainSelectBegin(Position: Integer; var Yes: Boolean);
    procedure IsPlanBegin(Position: integer; var Yes: boolean);
    procedure IsPlanEnd(Position: integer; var Yes: boolean);
    procedure IsSetBegin(Position: integer; var Yes: boolean);
    procedure IsIntoBegin(Position: integer; var Yes: boolean);
    procedure IsUpdateBegin(Position: integer; var Yes: boolean);

    function IsSelect(Position: integer): boolean;
    function IsUpdate(Position: integer): boolean;
    function IsDelete(Position: integer): boolean;
    function IsInsert(Position: integer): boolean;
    function IsExecute(Position: integer): boolean;
    function IsExecuteProc(Position: integer): boolean;
    function IsExecuteBlock(Position: integer): boolean;

    function IsDDL: boolean;

  public
    constructor Create; overload;
    constructor Create(const aSQLText: string); overload;
    destructor Destroy; override;
    procedure FillMainTables(WithSP: boolean = False);
    procedure ScanText(FromPosition: integer; Proc: TOnScanSQLText);

    function PosInSections(Position: integer): TSQLSections; overload;
    function PosInSections(ScanFrom, Position: integer; var EndScan: integer): TSQLSections; overload;

    function DispositionMainFrom: TPosition;
    function MainFrom: string;
    function ModifiedTables: string;

    function OrderText(var StartPos, EndPos: integer): string;
    function OrderClause: string;
    function SetOrderClause(const Value: string): string;
    function GetOrderInfo(NullsFirstDef: boolean = False): Variant;
    function GroupByText(var StartPos, EndPos: integer): string;
    function GroupByClause: string;
    function SetGroupClause(const Value: string): string;

    function GetFieldsClause: string;
    function SetFieldsClause(const NewFields: string): string;

    function WhereClause(N: integer; var StartPos, EndPos: integer): string;
    function SetWhereClause(N: integer; const Value: string): string;
    function SetMainWhereClause(const Value: string): string;
    function MainWhereClause(var StartPos, EndPos: integer): string;
    function WhereCount: integer;
    function MainWhereIndex: integer;
    function AddToMainWhere(const NewClause: string; ForceCLRF: boolean = True): string;

    function PlanCount: integer;
    function PlanText(N: integer; var StartPos, EndPos: integer): string;

    function MainPlanIndex: integer;
    function MainPlanText(var StartPos, EndPos: integer): string;
    function SetMainPlan(const Text: string): string;
    function GetMainPlan: string;

    function RecCountSQLText: string;
    function GetAllTables(WithSP: boolean = False): TStrings;

    function GetWord(Position: integer; var StartWord: integer; PartOnly: boolean = False): string;
    function GetPrevWord(CurPosition: integer; var PosPrevWord: integer): string;
  public
    property SQLText: string read FSQLText write SetSQLText;
    property Len: integer read FLen write FLen;
    property FirstPos: integer read FFirstPos;
    property MainPlanClause: string read GetMainPlan;
    property SQLKind: TSQLKind read FSQLKind;
    property CanParamsCheck: boolean read FCanParamsCheck;
  end;

const
  SpaceStr    = '    ';
  ForceNewStr = #13#10 + SpaceStr;
  QuotMarks   = #39;

function DispositionFrom(const SQLText: string): TPosition;
procedure AllSQLTables(SQLText: string; aTables: TStrings; WithSP: boolean = False; WithAliases: boolean = False);
procedure AllTables(const SQLText: string; aTables: TStrings; WithSP: boolean = False; WithAliases: boolean = False);

function TableByAlias(const SQLText, Alias: string): string;
function AliasForTable(const SQLText, TableName: string): string;

function FullFieldName(const SQLText, aFieldName: string): string;
function FieldNameFromSelect(const SQLText, FieldName: string): string;
function AddToWhereClause(const SQLText, NewClause: string; ForceCLRF: boolean = True): string;
function GetWhereClause(const SQLText: string; N: integer; var StartPos, EndPos: integer): string;
function WhereCount(const SQLText: string): integer;
function MainWhereIndex(const SQLText: string): integer;
function MainFrom(const SQLText: string): string;
function MainWhereClause(const SQLText: string): string;
function GetOrderInfo(const SQLText: string; NullsFirstDef: boolean = False): Variant;
function OrderStringTxt(const SQLText: string; var StartPos, EndPos: integer): string;

function SetOrderClause(const SQLText, NewClause: string): string;
procedure SetOrderString(SQLText: TStrings; const OrderTxt: string);
//

function PrepareConstraint(Src: TStrings): string;

function CountSelect(const SrcSQL: string): string;
function FieldsClause(const SrcSQL: string): string;
function SetFirstClause(const SrcSQL: string; FirstCount: integer): string;
function GetModifyTable(const SQLText: string; WithAlias: boolean = False): string;
function GetSQLKind(const SQLText: string): TSQLKind;
//

function GetLinkFieldName(const SQLText, ParamName: string): string;
function GetFieldByAlias(const SQLText, FieldName: string): string;
function IsWhereBeginPos(const SQLText: string; Position: integer): boolean;
function IsWhereEndPos(const SQLText: string; Position: integer): boolean;
function PosInSections(const SQLText: string; Position: integer): TSQLSections;

function InvertOrderClause(const OrderText: string): string;
function IsEquelSQLNames(const Name1, Name2: string): boolean;

function CutTableName(const SQLString: string; AliasPosition: integer = 0): string;
function CutAlias(const SQLString: string; AliasPosition: integer = 0): string;
function PosAlias(const SQLString: string): integer;
function FieldNameForSQL(const TableAlias, FieldName: string): string;
function FieldUsedInClause(const TableAlias, FieldName, Clause: string): boolean;

function ChangeToSQLDecimalSeparator(const Source: string): string;
function SQLStringLiteral(const S: string): string;
// x'0A1B...', Firebird 2.5+
function SQLHexLiteral(const Data; Size: Integer): string;
function FieldValueToStr(Field: TField; Old: Boolean = False): string;
procedure GetExportDataScript(DataSet: TDataSet; const TableName: string;
  OutPut: TStrings; UseFieldNames: boolean = True; FieldList: string = '');
procedure GetExportDataScriptToFile(DataSet: TDataSet; const TableName: string;
  const FileName: string; UseFieldNames: boolean = True;
  FieldList: string = '');

function GenerateInsertRow(DataSet: TDataSet; TableName: string; var fNames: string; FieldList: TList = nil): string;

const
  CharsAfterClause  = [' ', #13, #9, #10, #0, ';', '(', '/', '-', '"', '^'];
  CharsBeforeClause = [' ', #10, ')', #9, #13, '"'];
  endLexem = ['+', ')', '(', '*', '/', '|', ',', '=', '>', '<', '-', '!', '^',
    '~', ',', ';'];
  UnknownStr = 'UNKNOWN';

function ParseMacroString(const MacroString: string; aMacroChar: Char; var DefValue: string): string;
function PosClause(const Clause, SQLText: string): integer;
// True when Source has the uppercase Keyword at Position; only 'a'..'z' also match 'A'..'Z'
function IsKeywordAt(const Keyword, Source: string; Position: Integer): Boolean;

const
  BeginWhere = ' WHERE ';

implementation

uses
  StdFuncs;

function IsKeywordAt(const Keyword, Source: string; Position: Integer): Boolean;
var
  i: Integer;
  SourceChar: Char;
begin
  Result := False;
  if (Position < 1) or (Length(Source) - Position + 1 < Length(Keyword)) then
    Exit;
  for i := 1 to Length(Keyword) do
  begin
    SourceChar := Source[Position + i - 1];
    if (SourceChar <> Keyword[i]) and
      not ((SourceChar >= 'a') and (SourceChar <= 'z') and (Ord(SourceChar) - 32 = Ord(Keyword[i]))) then
      Exit;
  end;
  Result := True;
end;

function InternalIsClause(const EtalonClause: string; const Source: string; Position: integer): boolean;
// EtalonClause must be in UpperCase
var
  LenEtalon: Integer;
begin
  if (Position > 1) and not CharInSet(Source[Position - 1], CharsBeforeClause + ['(', ',', '/', '*', ';']) then
  begin
    Result := False;
    Exit
  end;
  Result := IsKeywordAt(EtalonClause, Source, Position);
  LenEtalon := Length(EtalonClause);
  if Result and (Length(Source) - Position >= LenEtalon) then
    Result := CharInSet(Source[Position + LenEtalon], CharsAfterClause + ['*', ')', ','])
end;

function SkipBlanks(const SQLText: string; Position: Integer): Integer;
begin
  Result := Position;
  while (Result <= Length(SQLText)) and CharInSet(SQLText[Result], [' ', #9, #10, #13]) do
    Inc(Result);
end;

// ROWS, OFFSET n ROW(S), FETCH FIRST/NEXT, WITH LOCK, RETURNING: clauses after WHERE, GROUP BY, ORDER BY
function IsTailClauseAt(const SQLText: string; Position: Integer): Boolean;
var
  P: Integer;
begin
  Result := False;
  if (Position < 1) or (Position > Length(SQLText)) then
    Exit;
  case SQLText[Position] of
    'R', 'r':
      Result := InternalIsClause('ROWS', SQLText, Position) or InternalIsClause('RETURNING', SQLText, Position);
    'O', 'o':
      if InternalIsClause('OFFSET', SQLText, Position) then
      begin
        P := SkipBlanks(SQLText, Position + 6);
        while (P <= Length(SQLText)) and not CharInSet(SQLText[P], [' ', #9, #10, #13]) do
          Inc(P);
        P := SkipBlanks(SQLText, P);
        Result := InternalIsClause('ROW', SQLText, P) or InternalIsClause('ROWS', SQLText, P);
      end;
    'F', 'f':
      if InternalIsClause('FETCH', SQLText, Position) then
      begin
        P := SkipBlanks(SQLText, Position + 5);
        Result := InternalIsClause('FIRST', SQLText, P) or InternalIsClause('NEXT', SQLText, P);
      end;
    'W', 'w':
      if InternalIsClause('WITH', SQLText, Position) then
        Result := InternalIsClause('LOCK', SQLText, SkipBlanks(SQLText, Position + 4));
  end;
end;

procedure SkipCommentsAndBlanks(const SQLText: string; Len: integer; var Position: integer);
var
  Start: Integer;
begin
  while (Position < Len) and CharInSet(SQLText[Position], CharsAfterClause - ['"']) do
  begin
    Start := Position;
    while (Position <= Len) and CharInSet(SQLText[Position], (CharsAfterClause - ['/', '-', '"'])) do
      Inc(Position);
    if (Position < Len) and (SQLText[Position] = '-') and (SQLText[Position + 1] = '-') then
    begin
      while (Position <= Len) and not CharInSet(SQLText[Position], [#13, #10]) do
        Inc(Position);
    end;
    if (Position < Len) and (SQLText[Position] = '/') and (SQLText[Position + 1] = '*') then
    begin
      Inc(Position, 2);
      while (Position < Len) and not((SQLText[Position] = '*') and (SQLText[Position + 1] = '/')) do
        Inc(Position);
      Inc(Position, 2);
    end;
    // a '-' or '/' that does not start a comment
    if Position = Start then
      Break;
  end;
end;

function ParseMacroString(const MacroString: string; aMacroChar: Char; var DefValue: string): string;
var
  PosDef: integer;
begin
  // For FIBPlus Macro
  PosDef := PosCh('%', MacroString);
  if PosDef = 0 then
  begin
    if (MacroString <> '') and (MacroString[1] = aMacroChar) then
      Result := MacroString
    else
      Result := aMacroChar + MacroString;
  end
  else
  begin
    Result := Copy(MacroString, 1, PosDef - 1);
    DefValue := Copy(MacroString, PosDef + 1, Length(MacroString) - PosDef);
    if MacroString[1] <> aMacroChar then
      Result := aMacroChar + Result
  end;
end;

function PosClause(const Clause, SQLText: string): integer;
begin
  Result := PosExtCI(Clause, SQLText, CharsBeforeClause, CharsAfterClause, False);
end;

function IsEquelSQLNames(const Name1, Name2: string): boolean;
begin
  if (Length(Name1) > 0) and (Length(Name2) > 0) then
  begin
    case Name1[1] of
      '"':
        if Name2[1] <> '"' then
        begin
          Result := Copy(Name1, 2, Length(Name1) - 2) = UpperCase(Name2)
        end
        else
          Result := Name1 = Name2
    else // else case
      if Name2[1] = '"' then
        Result := ('"' + Name1 + '"' = Name2) or ('"' + UpperCase(Name1) + '"' = Name2)
      else
        // Quotes don't exist
        Result := UpperCase(Name1) = UpperCase(Name2)
    end
  end
  else
    Result := True; // Unknown
end;

function RemoveSP(const FromStr: string; OnlyArguments: boolean = False): string;
var
  pBrIn, pBrOut: integer;
  cBrIn, cBrOut: integer;
begin
  Result := FromStr;
  pBrIn := PosCh('(', FromStr);
  if pBrIn = 0 then
    Exit;
  while pBrIn > 0 do
  begin
    pBrOut := pBrIn + 1;
    cBrIn := 1;
    cBrOut := 0;
    while (cBrOut < cBrIn) do
    begin
      if pBrOut > Length(Result) then
        Exit;
      if Result[pBrOut] = ')' then
        Inc(cBrOut)
      else if Result[pBrOut] = '(' then
        Inc(cBrIn);
      Inc(pBrOut);
    end;
    if not OnlyArguments then
    begin
      while (pBrIn > 1) and not CharInSet(Result[pBrIn], [',']) do
        Dec(pBrIn);
      while (pBrOut <= Length(Result)) and not CharInSet(Result[pBrOut], [',']) do
        Inc(pBrOut);
    end;
    System.Delete(Result, pBrIn, pBrOut - pBrIn);
    pBrIn := PosCh('(', Result);
  end;
end;

function RemoveComments(const SQLText: string): string;
var
  Len: integer;
  Position, RLen: integer;
  State: TParserState;

  procedure WriteResultChar;
  begin
    Inc(RLen);
    Result[RLen] := SQLText[Position];
  end;

begin
  Len := Length(SQLText);
  Position := 1;
  RLen := 0;
  SetLength(Result, Len);
  State := sNormal;

  while (Position <= Len) do
  begin
    case State of
      sNormal:
        begin
          case SQLText[Position] of
            '"':
              begin
                State := sQuote;
                WriteResultChar;
              end;
            '''':
              begin
                State := sQuoteSingle;
                WriteResultChar;
              end;
            '-':
              begin
                if (Position < Len) and (SQLText[Position + 1] = '-') then
                  State := sFBComment
                else
                  WriteResultChar;
              end;
            '/':
              begin
                if (Position < Len) and (SQLText[Position + 1] = '*') then
                  State := sComment
                else
                  WriteResultChar;
              end;
          else
            WriteResultChar;
          end;
        end;
      sQuote:
        begin
          WriteResultChar;
          if (SQLText[Position] = '"') then
            State := sNormal;
        end;
      sQuoteSingle:
        begin
          WriteResultChar;
          if (SQLText[Position] = '''') then
            State := sNormal;
        end;
      sComment:
        if (SQLText[Position] = '*') then
        begin
          if (Position < Len) and (SQLText[Position + 1] = '/') then
          begin
            State := sNormal;
            Inc(Position);
            // the comment separates the tokens around it
            Inc(RLen);
            Result[RLen] := ' ';
          end;
        end;
      sFBComment:
        if CharInSet(SQLText[Position], [#13, #10]) then
        begin
          State := sNormal;
          WriteResultChar;
        end;
    end;
    Inc(Position);
  end;
  SetLength(Result, RLen);
end;

function RemoveJoins(const FromStr: string): string;
var
  pON, pComa, pJOIN: integer;
  tmpStr: string;
begin
  Result := FromStr;
  pJOIN := PosClause('JOIN', Result);
  if pJOIN = 0 then
    Exit;
  Result := Copy(Result, 1, pJOIN - 1) + ', ' + Copy(Result, pJOIN + 5, MaxInt);
  Result := ReplaceCIStr(Result, ' LEFT ', ' ', False);
  Result := ReplaceCIStr(Result, ' RIGHT ', ' ', False);
  Result := ReplaceCIStr(Result, ' FULL ', ' ', False);
  Result := ReplaceCIStr(Result, ' INNER ', ' ', False);
  Result := ReplaceCIStr(Result, ' OUTER ', ' ', False);
  Result := ReplaceCIStr(Result, ' CROSS ', ' ', False);
  Result := ReplaceCIStr(Result, ' NATURAL ', ' ', False);
  Result := ReplaceCIStr(Result, ' JOIN ', ' , ', False);
  pON := PosClause('ON', Result);
  tmpStr := '';
  while pON > 0 do
  begin
    tmpStr := Copy(Result, pON + 2, MaxInt);
    pComa := Pos(',', tmpStr);
    SetLength(Result, pON - 1);
    if pComa > 0 then
    begin
      Result := Result + Copy(tmpStr, pComa, MaxInt)
    end;
    pON := PosClause('ON', Result);
  end;
end;

function DispositionFrom(const SQLText: string): TPosition;
var
  Parser: TSQLParser;
begin
  Parser := TSQLParser.Create(SQLText);
  try
    Result := Parser.DispositionMainFrom;
  finally
    Parser.Free
  end
end;

function CountSelect(const SrcSQL: string): string;
var
  Parser: TSQLParser;
begin
  Parser := TSQLParser.Create(SrcSQL);
  try
    Result := Parser.RecCountSQLText;
  finally
    Parser.Free
  end;
end;

function FieldsClause(const SrcSQL: string): string;
var
  Parser: TSQLParser;
begin
  Parser := TSQLParser.Create(SrcSQL);
  try
    Result := Parser.GetFieldsClause;
  finally
    Parser.Free
  end;
end;

function SetFirstClause(const SrcSQL: string; FirstCount: integer): string;
var
  Parser: TSQLParser;
  pb: integer;
begin
  // IF FIRST DON'T EXIST
  Parser := TSQLParser.Create(SrcSQL);
  Result := SrcSQL;
  try
    if Parser.SQLKind = skSelect then
      if PosClause('FIRST', SrcSQL) = 0 then
      begin
        pb := Parser.FSelectPos + 6;
        Insert(' FIRST ' + IntToStr(FirstCount) + ' ', Result, pb)
      end
      else
      begin
        // ?
      end;
  finally
    Parser.Free
  end;
end;

function GetModifyTable(const SQLText: string; WithAlias: boolean = False): string;
var
  StartCut, EndCut, l: integer;
  Parser: TSQLParser;
begin
  Parser := TSQLParser.Create(SQLText);
  try
    Result := FastTrim(Parser.ModifiedTables);
    l := Length(Result);
    if not WithAlias and (l > 0) then
    begin
      StartCut := 1;
      if Result[StartCut] = '"' then
      begin
        Inc(StartCut);
        EndCut := StartCut + 1;
        while EndCut <= l do
        begin
          if (Result[EndCut] = '"') and (EndCut < l) and (Result[EndCut + 1] = '"') then
            Inc(EndCut, 2)
          else if Result[EndCut] = '"' then
          begin
            Dec(EndCut);
            Break
          end
          else
            Inc(EndCut);
        end;
        Result := StringReplace(FastCopy(Result, StartCut, EndCut - StartCut + 1), '""', '"', [rfReplaceAll]);
      end
      else
      begin
        EndCut := StartCut;
        while EndCut < l do
        begin
          if CharInSet(Result[EndCut + 1], CharsAfterClause - ['"']) then
          begin
            Break
          end
          else
            Inc(EndCut);
        end;
        if l > EndCut then
          SetLength(Result, EndCut);
        Result := FastUpperCase(Result);
      end;
    end;
  finally
    Parser.Free
  end;
end;

function PosAlias(const SQLString: string): integer;
var
  i: integer;
  InQuote1, InQuote2: boolean;
begin
  Result := 0;
  InQuote1 := False;
  InQuote2 := False;
  for i := 1 to Length(SQLString) do
  begin
    case SQLString[i] of
      ' ', #10, #13, #9:
        if not InQuote1 and not InQuote2 then
        begin
          Result := i;
          Break;
        end;
      '"':
        if not InQuote2 then
          InQuote1 := not InQuote1;
      '''':
        if not InQuote1 then
          InQuote2 := not InQuote2;
    end;
  end;
  if Result > 0 then
    while (Result < Length(SQLString)) and CharInSet(SQLString[Result], CharsAfterClause - ['"']) do
      Inc(Result);

end;

function FieldUsedInClause(const TableAlias, FieldName, Clause: string): boolean;
begin
  { TODO : FieldUsedInClause }
  Result := False;
end;

function FieldNameForSQL(const TableAlias, FieldName: string): string;
begin
  if Length(TableAlias) > 0 then
    Result := FormatIdentifier(3, TableAlias) + '.' + FormatIdentifier(3, FieldName)
  else
    Result := FormatIdentifier(3, FieldName);
end;

function CutTableName(const SQLString: string; AliasPosition: integer = 0): string;
var
  p: integer;
begin
  if AliasPosition = 0 then
    p := PosAlias(SQLString)
  else
    p := AliasPosition;
  if p = 0 then
    Result := Trim(SQLString)
  else
    Result := Trim(Copy(SQLString, 1, p - 1));
end;

function CutAlias(const SQLString: string; AliasPosition: integer = 0): string;
var
  p: integer;
begin
  if AliasPosition = 0 then
    p := PosAlias(SQLString)
  else
    p := AliasPosition;
  // skip the keyword of "Table AS Alias"
  if (p > 0) and (p + 2 <= Length(SQLString)) then
    if CharInSet(SQLString[p], ['A', 'a']) and CharInSet(SQLString[p + 1], ['S', 's']) and
      CharInSet(SQLString[p + 2], CharsAfterClause) then
      Inc(p, 2);
  if p = 0 then
    Result := Trim(SQLString)
  else
    Result := Trim(Copy(SQLString, p, MaxInt));
end;

procedure RemoveAliases(ListOfTables: TStrings);
var
  i: integer;
begin
  for i := 0 to ListOfTables.Count - 1 do
  begin
    ListOfTables[i] := CutTableName(ListOfTables[i]);
  end
end;

procedure AllTables(const SQLText: string; aTables: TStrings; WithSP: boolean = False; WithAliases: boolean = False);
var
  Parser: TSQLParser;
begin
  Parser := TSQLParser.Create(SQLText);
  with Parser do
    try
      FillMainTables(WithSP);
      aTables.Assign(FTables);
      if not WithAliases then
        RemoveAliases(aTables);
    finally
      Parser.Free
    end;
end;

procedure AllSQLTables(SQLText: string; aTables: TStrings; WithSP: boolean = False; WithAliases: boolean = False);
var
  Parser: TSQLParser;
begin
  Parser := TSQLParser.Create(SQLText);
  with Parser do
    try
      GetAllTables(WithSP);
      aTables.Assign(FTables);
      if not WithAliases then
        RemoveAliases(aTables);

    finally
      Parser.Free
    end;
end;

function AliasForTable(const SQLText, TableName: string): string;
var
  ts: TStrings;
  i, p: integer;
  tmpStr: string;
begin
  Result := TableName;
  ts := TStringList.Create;
  try
    AllTables(SQLText, ts, True, True);
    for i := 0 to Pred(ts.Count) do
    begin
      p := PosAlias(ts[i]);
      if p > 0 then
        tmpStr := CutTableName(ts[i], p)
      else
        tmpStr := Trim(ts[i]);

      if IsEquelSQLNames(tmpStr, TableName) then
      begin
        // Is first table including

        Result := CutAlias(ts[i], p);
        Exit;
      end
    end;
  finally
    ts.Free
  end;
end;

function TableByAlias(const SQLText, Alias: string): string;
var
  ts: TStrings;
  i, p: integer;
  tmpStr: string;
  tmpStr1: string;
begin
  Result := '';
  ts := TStringList.Create;
  tmpStr1 := '';
  try
    AllTables(SQLText, ts, True, True);
    for i := 0 to Pred(ts.Count) do
    begin
      p := PosAlias(ts[i]);
      if p > 0 then
        tmpStr := CutAlias(ts[i], p)
      else
        tmpStr := Trim(ts[i]);

      if IsEquelSQLNames(tmpStr, Alias) then
      begin
        Result := CutTableName(ts[i], p);
        Break;
      end
      else if Length(tmpStr1) = 0 then
      begin
        tmpStr1 := CutTableName(ts[i], p);
        if not IsEquelSQLNames(Alias, tmpStr1) then
          tmpStr1 := '';
      end;
    end;
    if (Length(Result) = 0) and (Length(tmpStr1) > 0) then
      Result := tmpStr1
  finally
    ts.Free
  end;
end;

function FullFieldName(const SQLText, aFieldName: string): string;
var
  p: integer;
  TableName: string;
  FieldName: string;
begin
  p := Pos('.', aFieldName);
  if p = 0 then
    Result := aFieldName
  else
  begin
    TableName := TableByAlias(SQLText, Copy(aFieldName, 1, p - 1));
    if (Length(TableName) = 0) then
      Result := aFieldName
    else if (Length(TableName) = 0) then
      Result := aFieldName
    else
    begin
      FieldName := Trim(Copy(aFieldName, p + 1, MaxInt));
      if (Length(FieldName) > 0) then
        if FieldName[1] = '"' then
          FieldName := Copy(FieldName, 2, Length(FieldName) - 2)
        else
          FieldName := UpperCase(FieldName);

      if (TableName[1] <> '"') then
        Result := UpperCase(TableName) + '.' + FieldName
      else
        Result := Copy(TableName, 2, Length(TableName) - 2) + '.' + FieldName
    end;
  end;
end;

function FieldNameFromSelect(const SQLText, FieldName: string): string;
var
  p, pb, pe: integer;
begin
  if Length(FieldName) = 0 then
    Result := FieldName
  else if PosCh('.', FieldName) > 0 then
    Result := FieldName
  else
  begin
    if FieldName[1] = '"' then
      p := PosInSubstrExt(FieldName, SQLText, 1, Length(SQLText),
        endLexem + CharsAfterClause + ['.'], endLexem + CharsAfterClause)
    else
      p := PosInSubstrCIExt(FieldName, SQLText, 1, Length(SQLText),
        endLexem + CharsAfterClause + ['.'], endLexem + CharsAfterClause);

    if p > 0 then
    begin
      pb := p - 1;
      while (pb > 0) and CharInSet(SQLText[pb], [' ', #10, #9, #13]) do
        Dec(pb);
      if (pb > 0) and (SQLText[pb] = '.') then
      begin
        pe := pb - 1;
        while (pe > 0) and CharInSet(SQLText[pe], [' ', #10, #9, #13]) do
          Dec(pe);
        if pe > 0 then
        begin
          pb := pe;
          while (pb > 0) and not CharInSet(SQLText[pb], ['(', ' ', #10, #9, #13]) do
            Dec(pb);
          Inc(pb);
          Result := FastCopy(SQLText, pb, pe - pb + 1) + '.' + FastCopy(SQLText, p, Length(FieldName));
        end
        else
          Result := FastCopy(SQLText, p, Length(FieldName));
      end
      else
        Result := FastCopy(SQLText, p, Length(FieldName));
    end
    else
      Result := FieldName;
  end;
end;

function MainWhereIndex(const SQLText: string): integer;
var
  Parser: TSQLParser;
begin
  Parser := TSQLParser.Create(SQLText);
  try
    Result := Parser.MainWhereIndex;
  finally
    Parser.Free
  end;
end;

function MainFrom(const SQLText: string): string;
var
  Parser: TSQLParser;
begin
  Parser := TSQLParser.Create(SQLText);
  try
    Result := Parser.MainFrom;
  finally
    Parser.Free
  end;
end;

function MainWhereClause(const SQLText: string): string;
var
  Parser: TSQLParser;
  i, j: integer;
begin
  Parser := TSQLParser.Create(SQLText);
  try
    Result := Parser.MainWhereClause(i, j);
  finally
    Parser.Free
  end;
end;

function WhereCount(const SQLText: string): integer;
var
  Parser: TSQLParser;
begin
  Parser := TSQLParser.Create(SQLText);
  try
    Result := Parser.WhereCount;
  finally
    Parser.Free
  end;
end;

function OrderStringTxt(const SQLText: string; var StartPos, EndPos: integer): string;
var
  Parser: TSQLParser;
begin
  Parser := TSQLParser.Create(SQLText);
  try
    Result := Parser.OrderText(StartPos, EndPos);
  finally
    Parser.Free
  end
end;

function GetSQLKind(const SQLText: string): TSQLKind;
var
  Parser: TSQLParser;
begin
  Parser := TSQLParser.Create(SQLText);
  try
    Result := Parser.SQLKind;
  finally
    Parser.Free
  end
end;

type
  TSQLTextParts = array of string;

// Position of one of Chars outside quotes and parentheses (comments removed before), 0 if none
function TopLevelPos(const Chars: TSysCharSet; const Text: string; From: Integer = 1): Integer;
var
  I, Depth: Integer;
  Quote: Char;
begin
  Result := 0;
  Depth := 0;
  Quote := #0;
  for I := From to Length(Text) do
    if Quote <> #0 then
    begin
      if Text[I] = Quote then
        Quote := #0;
    end
    else
      case Text[I] of
        '"', '''':
          Quote := Text[I];
        '(':
          Inc(Depth);
        ')':
          Dec(Depth);
      else
        if (Depth = 0) and CharInSet(Text[I], Chars) then
        begin
          Result := I;
          Exit;
        end;
      end;
end;

// The non-empty trimmed parts of Text between the top-level Delimiter chars
function SplitTopLevel(const Text: string; Delimiter: Char): TSQLTextParts;
var
  Start, P: Integer;
  Part: string;
begin
  SetLength(Result, 0);
  Start := 1;
  repeat
    P := TopLevelPos([AnsiChar(Delimiter)], Text, Start);
    if P = 0 then
      Part := Trim(Copy(Text, Start, MaxInt))
    else
      Part := Trim(Copy(Text, Start, P - Start));
    if Part <> '' then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := Part;
    end;
    Start := P + 1;
  until P = 0;
end;

function TSQLParser.GetOrderInfo(NullsFirstDef: boolean = False): Variant;
var
  StartPos, EndPos: integer;
  OrderClauseText: string;
  i, wc, p, l: integer;
  bufStr: string;
  TName, FName: string;
  wc1: integer;
  Items: TSQLTextParts;
begin
  OrderClauseText := Trim(RemoveComments(OrderText(StartPos, EndPos)));
  Items := SplitTopLevel(OrderClauseText, ',');
  wc := Length(Items);
  if wc < 1 then
    Result := null
  else
  begin
    Result := VarArrayCreate([0, wc - 1, 0, 2], varVariant);
    for i := 1 to wc do
    begin
      bufStr := Items[i - 1];
      p := TopLevelPos(['.'], bufStr);
      if p > 0 then
      begin
        TName := FastTrim(Copy(bufStr, 1, p - 1));
        if Length(TName) > 0 then
          if TName[1] <> '"' then
            TName := FastUpperCase(TName);
        FName := FastTrim(Copy(bufStr, p + 1, MaxInt));
        if Length(FName) > 0 then
          if FName[1] <> '"' then
            FName := FastUpperCase(FName);
        bufStr := TName + '.' + FName;
      end;

      wc1 := WordCount(bufStr, CharsAfterClause);
      if wc1 > 0 then
      begin

        p := PosClause('NULLS', bufStr);
        if p > 0 then
        begin
          wc1 := p;
          Inc(p, 5);
          l := Length(bufStr);
          while (p <= l) and CharInSet(bufStr[p], CharsAfterClause) do
            Inc(p);
          if p < l then
            Result[i - 1, 2] := CharInSet(bufStr[p], ['F', 'f']); // NULLS FIRST
          SetLength(bufStr, wc1 - 1);
        end
        else
        begin

          Result[i - 1, 2] := NullsFirstDef
        end;

        p := PosClause('DESC', bufStr);
        if p = 0 then
          p := PosClause('DESCENDING', bufStr);
        Result[i - 1, 1] := p = 0;
        if p > 0 then
          SetLength(bufStr, p - 1)
        else
        begin
          p := PosClause('ASC', bufStr);
          if p = 0 then
            p := PosClause('ASCENDING', bufStr);
          if p > 0 then
            SetLength(bufStr, p - 1);
        end;
        p := PosClause('COLLATE', bufStr);
        if p > 0 then
          SetLength(bufStr, p - 1);
        Result[i - 1, 0] := FastTrim(bufStr);
      end;
    end;
  end;
end;

function GetOrderInfo(const SQLText: string; NullsFirstDef: boolean = False): Variant;
var
  Parser: TSQLParser;
begin
  Parser := TSQLParser.Create(SQLText);
  try
    Result := Parser.GetOrderInfo(NullsFirstDef);
  finally
    Parser.Free;
  end;
end;

procedure SetOrderString(SQLText: TStrings; const OrderTxt: string);
begin
  SQLText.Text := SetOrderClause(SQLText.Text, OrderTxt);
end;

function SetOrderClause(const SQLText, NewClause: string): string;
var
  StartPos, EndPos: integer;
  Old: string;
begin
  Old := SqlTxtRtns.OrderStringTxt(SQLText, StartPos, EndPos);
  if StartPos > 0 then
    if Length(NewClause) > 0 then
      Result := ReplaceStrInSubstr(SQLText, Old, ' ' + NewClause + ' ', StartPos, EndPos)
    else
      Result := FastCopy(SQLText, 1, StartPos - 1) + ' ' + FastCopy(SQLText, EndPos + 1, MaxInt)
  else if Length(NewClause) > 0 then
    Result := SQLText + ' ORDER BY ' + NewClause
  else
    Result := SQLText
end;

function GetWhereClause(const SQLText: string; N: integer; var StartPos, EndPos: integer): string;
var
  Parser: TSQLParser;
begin
  Parser := TSQLParser.Create(SQLText);
  try
    Result := Parser.WhereClause(N, StartPos, EndPos);
  finally
    Parser.Free
  end
end;

function AddToWhereClause(const SQLText, NewClause: string; ForceCLRF: boolean = True): string;
var
  Parser: TSQLParser;
begin
  Parser := TSQLParser.Create(SQLText);
  try
    Result := Parser.AddToMainWhere(NewClause, ForceCLRF);
  finally
    Parser.Free
  end;
end;

function PrepareConstraint(Src: TStrings): string;
var
  i, pos_no: integer;
begin
  Result := FastTrim(Src.Text);
  pos_no := PosCh('(', Result) + 1;
  Result := FastCopy(Result, pos_no, Length(Result));
  pos_no := -1;
  for i := Length(Result) downto 1 do
    if Result[i] = ')' then
    begin
      pos_no := i;
      Break;
    end;
  SetLength(Result, pos_no - 1);
  Result := ReplaceStr(FastCopy(Result, pos_no, Length(Result) - pos_no), '"', QuotMarks)
end;

{ TSQLParser }

constructor TSQLParser.Create;
begin
  FTables := TStringList.Create;
  FFirstPos := 1;
  FSelectPos := 1;
  inherited Create;
end;

constructor TSQLParser.Create(const aSQLText: string);
begin
  Create;
  SQLText := aSQLText;
end;

destructor TSQLParser.Destroy;
begin
  FTables.Free;
  inherited;
end;

procedure TSQLParser.IsFromEnd(Position: integer; var Yes: boolean);
var
  p: integer;
begin
  if FBracketOpenedBeforeScan < FBracketOpened then
  begin
    Yes := False;
    Exit;
  end;

  p := Position;
  Yes := p = Len;
  if Yes then
    Exit;
  if p > Len then
    Exit;
  if CharInSet(SQLText[p], [' ', #9, #13, #10]) then
  begin
    if (Len - p) > 1 then
      case SQLText[p + 1] of
        'F', 'f': // FOR UPDATE
          Yes := InternalIsClause('FOR', SQLText, p + 1);
        'G', 'g': // GROUP BY
          Yes := InternalIsClause('GROUP', SQLText, p + 1);
        'H', 'h': // HAVING
          Yes := InternalIsClause('HAVING', SQLText, p + 1);
        'O', 'o': // ORDER BY
          Yes := InternalIsClause('ORDER', SQLText, p + 1);
        'P', 'p': // PLAN
          Yes := InternalIsClause('PLAN', SQLText, p + 1);
        'U', 'u': // UNION
          Yes := InternalIsClause('UNION', SQLText, p + 1);
        'W', 'w': // WHERE
          Yes := InternalIsClause('WHERE', SQLText, p + 1);
      end;
    if not Yes and ((Len - p) > 1) then
      Yes := IsTailClauseAt(SQLText, p + 1);
  end
end;

procedure TSQLParser.IsOrderEnd(Position: Integer; var Yes: Boolean);
begin
  Yes := (FBracketOpenedBeforeScan >= FBracketOpened) and (Position > 1) and
    CharInSet(SQLText[Position - 1], CharsBeforeClause) and
    (InternalIsClause('FOR', SQLText, Position) or IsTailClauseAt(SQLText, Position));
end;

procedure TSQLParser.IsGroupEnd(Position: Integer; var Yes: Boolean);
begin
  Yes := (FBracketOpenedBeforeScan >= FBracketOpened) and (Position > 1) and
    CharInSet(SQLText[Position - 1], CharsBeforeClause) and
    (InternalIsClause('HAVING', SQLText, Position) or InternalIsClause('PLAN', SQLText, Position) or
    InternalIsClause('ORDER', SQLText, Position) or InternalIsClause('UNION', SQLText, Position) or
    InternalIsClause('FOR', SQLText, Position) or IsTailClauseAt(SQLText, Position));
end;

procedure TSQLParser.IsMainSelectBegin(Position: Integer; var Yes: Boolean);
begin
  Yes := (FBracketOpened = 0) and InternalIsClause('SELECT', SQLText, Position);
end;

procedure TSQLParser.IsSetBegin(Position: integer; var Yes: boolean);
begin
  Yes := InternalIsClause('SET', SQLText, Position);
end;

procedure TSQLParser.IsUpdateBegin(Position: integer; var Yes: boolean);
begin
  Yes := IsUpdate(Position);
end;

procedure TSQLParser.IsFromBegin(Position: Integer; var Yes: Boolean);
begin
  Yes := InternalIsClause('FROM', SQLText, Position);
end;

procedure TSQLParser.IsMainFromBegin(Position: Integer; var Yes: Boolean);
begin
  Yes := (FBracketOpened = 0);
  if Yes then
    IsFromBegin(Position, Yes);
end;

procedure TSQLParser.IsIntoBegin(Position: integer; var Yes: boolean);
begin
  Yes := InternalIsClause('INTO', SQLText, Position);
end;

procedure TSQLParser.IsPlanBegin(Position: integer; var Yes: boolean);
begin
  Yes := InternalIsClause('PLAN', SQLText, Position);
  if Yes and (FReserved > 0) then
  begin
    Inc(FReserved1);
    Yes := FReserved1 = FReserved
  end;
end;

procedure TSQLParser.IsPlanEnd(Position: integer; var Yes: boolean);
var
  p: integer;
begin
  if FBracketOpenedBeforeScan < FBracketOpened then
  begin
    Yes := False;
    Exit;
  end;
  p := Position;
  Yes := p = Len;
  if Yes then
    Exit;
  if p > Len then
    Exit;
  if CharInSet(SQLText[p], [' ', #9, #13, #10]) then
  begin
    if (Len - p) > 1 then
      case SQLText[p + 1] of
        'O', 'o': // ORDER BY
          Yes := InternalIsClause('ORDER', SQLText, p + 1);
      end;
  end
end;

procedure TSQLParser.IsWhereBegin(Position: integer; var Yes: boolean);
begin
  Yes := IsWhereBeginPos(SQLText, Position);
  if Yes and (FReserved > 0) then
  begin
    Inc(FReserved1);
    Yes := FReserved1 = FReserved
  end;
end;

procedure TSQLParser.IsWhereEnd(Position: integer; var Yes: boolean);
begin
  if FBracketOpenedBeforeScan < FBracketOpened then
  begin
    Yes := False;
    Exit;
  end;
  Yes := IsWhereEndPos(SQLText, Position)
end;

procedure TSQLParser.IsMainWhereBegin(Position: integer; var Yes: boolean);
begin
  Yes := FBracketOpened = 0;
  if Yes then
    IsWhereBegin(Position, Yes)
end;

procedure TSQLParser.ScanText(FromPosition: integer; Proc: TOnScanSQLText);
var
  j: integer;
  StopScan: boolean;
begin
  if not Assigned(Proc) then
    Exit;
  FState := sNormal;
  FResultPos := 0;
  // a scan from the start is outside any bracket, whatever an earlier scan left
  if FromPosition <= FFirstPos then
    FBracketOpened := 0;
  FBracketOpenedBeforeScan := FBracketOpened;
  for j := FromPosition to Len do
  begin
    case SQLText[j] of
      '(':
        if not(FState in [sComment, sFBComment, sQuote, sQuoteSingle]) then
        begin
          Inc(FBracketOpened);
        end;
      ')':
        if not(FState in [sComment, sFBComment, sQuote, sQuoteSingle]) then
        begin
          if (FScanInBrackets and (FBracketOpened - 1 < FBracketOpenedBeforeScan)) then
          begin
            FResultPos := j;
            Break
          end
          else
            Dec(FBracketOpened);
        end;
      '"':
        if not(FState in [sComment, sFBComment, sQuoteSingle]) then
          if FState = sQuote then
            FState := sNormal
          else
            FState := sQuote;
      '''':
        if not(FState in [sComment, sFBComment, sQuote]) then
          if FState = sQuoteSingle then
            FState := sNormal
          else
            FState := sQuoteSingle;
      '*':
        if not(FState in [sQuote, sQuoteSingle, sFBComment]) then
        begin
          if FState = sComment then
          begin
            if (j < Len) and (FSQLText[j + 1] = '/') then
              FState := sNormal
          end
          else if (j > 1) and (FSQLText[j - 1] = '/') then
            FState := sComment
        end;
      '-':
        if FState = sNormal then
        begin
          if (j < Len) and (FSQLText[j + 1] = '-') then
            FState := sFBComment
        end;
    else
      case FState of
        sNormal:
          begin
            StopScan := False;
            Proc(j, StopScan);
            if StopScan then
            begin
              FResultPos := j;
              Break
            end;
          end;
        sFBComment:
          if CharInSet(FSQLText[j], [#13, #10]) then
          begin
            // the line break that ends the comment is a blank before the next clause
            FState := sNormal;
            StopScan := False;
            Proc(j, StopScan);
            if StopScan then
            begin
              FResultPos := j;
              Break
            end;
          end;
      end
    end;
  end;

  if (FResultPos = 0) and (FState = sNormal) then
  begin
    StopScan := False;
    Proc(Len, StopScan);
    if StopScan then
    begin
      FResultPos := Len;
    end;
  end;
  FReserved := 0;
end;

procedure TSQLParser.SetSQLText(const Value: string);
begin
  FSQLText := Value;
  FTables.Clear;
  FLen := Length(FSQLText);
  FFirstPos := 1;
  SkipCommentsAndBlanks(FSQLText, FLen, FFirstPos);
  FSQLKind := GetSQLKind;
end;

procedure TSQLParser.IsOrderBegin(Position: integer; var Yes: boolean);
begin
  Yes := InternalIsClause('ORDER', SQLText, Position);
end;

procedure TSQLParser.IsMainOrderBegin(Position: integer; var Yes: boolean);
begin
  Yes := FBracketOpened = 0;
  if Yes then
    IsOrderBegin(Position, Yes)
end;

procedure TSQLParser.IsGroupBegin(Position: integer; var Yes: boolean);
begin
  Yes := InternalIsClause('GROUP', SQLText, Position);
end;

procedure TSQLParser.IsMainGroupBegin(Position: integer; var Yes: boolean);
begin
  Yes := FBracketOpened = 0;
  if Yes then
    IsGroupBegin(Position, Yes)
end;

function TSQLParser.IsClause(Position: integer; const Clause: string): boolean;
begin
  Result := InternalIsClause(Clause, SQLText, Position)
end;

procedure TSQLParser.IsByBegin(Position: integer; var Yes: boolean);
begin
  Yes := IsClause(Position, 'BY')
end;

procedure TSQLParser.IsHaving(Position: integer; var Yes: boolean);
begin
  Yes := IsClause(Position, 'HAVING')
end;

function TSQLParser.DispositionMainFrom: TPosition;
begin
  Result.X := 0;
  Result.Y := 0;
  ScanText(FFirstPos, IsMainFromBegin);
  if FResultPos = 0 then
    Exit;
  Result.X := FResultPos;
  ScanText(Result.X + 5, IsFromEnd);
  if FResultPos = 0 then
    Result.Y := Len
  else
    Result.Y := FResultPos;
end;

function TSQLParser.MainFrom: string;
var
  p: TPosition;
begin
  p := DispositionMainFrom;
  if p.X > 0 then
    if p.Y = Length(SQLText) then
      Result := FastCopy(SQLText, p.X + 5, MaxInt)
    else
      Result := FastCopy(SQLText, p.X + 5, p.Y - p.X - 5)
  else
    Result := ''
end;

function TSQLParser.PosInSections(Position: integer): TSQLSections;
var
  temp: integer;
begin
  Result := PosInSections(1, Position, temp)
end;

function TSQLParser.PosInSections(ScanFrom, Position: integer; var EndScan: integer): TSQLSections;
var
  i: integer;

  MayBe1: TSQLSections;
  BracketOpenedBeforeScan: Integer;
  b: boolean;

  procedure AddArray(NewArray: TSQLSections);
  var
    j, k: integer;
  begin
    SetLength(Result, Length(Result) + Length(NewArray));
    k := 1;
    for j := Length(NewArray) - 1 downto 0 do
    begin
      Result[Length(Result) - k] := NewArray[j];
      Inc(k);
    end;
  end;

begin
  FState := sNormal;
  SetLength(MayBe1, 0);
  SetLength(Result, 0);

  if ScanFrom = 1 then
  begin
    FBracketOpened := 0;
    BracketOpenedBeforeScan := 0
  end
  else
    BracketOpenedBeforeScan := FBracketOpened;

  i := ScanFrom;
  while i <= Position do
  begin
    case SQLText[i] of
      '(':
        if not(FState in [sComment, sFBComment, sQuote, sQuoteSingle]) then
        begin
          Inc(FBracketOpened);
          MayBe1 := PosInSections(i + 1, Position, EndScan);
          if EndScan >= Position then
          begin
            AddArray(MayBe1);
            Exit
          end
          else
          begin
            i := EndScan;
            Continue;
          end;
        end;
      ')':
        if not(FState in [sComment, sFBComment, sQuote, sQuoteSingle]) then
        begin
          Dec(FBracketOpened);
          if FBracketOpened = BracketOpenedBeforeScan then
          begin
            EndScan := i + 1;
            Exit;
          end;
        end;
      '"':
        if not(FState in [sComment, sFBComment, sQuoteSingle]) then
          if FState = sQuote then
            FState := sNormal
          else
            FState := sQuote;
      '''':
        if not(FState in [sComment, sFBComment, sQuote]) then
          if FState = sQuoteSingle then
            FState := sNormal
          else
            FState := sQuoteSingle;
      '*':
        if not(FState in [sQuote, sQuoteSingle, sFBComment]) then
        begin
          if FState = sComment then
          begin
            if (i < Len) and (FSQLText[i + 1] = '/') then
              FState := sNormal
          end
          else if (i > 1) and (FSQLText[i - 1] = '/') then
            FState := sComment
        end;
      '-':
        if FState = sNormal then
        begin
          if (i < Len) and (FSQLText[i + 1] = '-') then
            FState := sFBComment
        end;
    else
      if FState <> sNormal then
      begin
        if (FState = sFBComment) and CharInSet(SQLText[i], [#13, #10]) then
          FState := sNormal;
      end
      else if IsSelect(i) then
      begin
        SetLength(Result, Length(Result) + 2);
        Result[Length(Result) - 2] := stSelect;
        Result[Length(Result) - 1] := stFields;
        Inc(i, 5);
      end
      else if IsUpdate(i) then
      begin
        SetLength(Result, Length(Result) + 2);
        Result[Length(Result) - 2] := stUpdate;
        Result[Length(Result) - 1] := stSet;
        Inc(i, 5);
      end
      else if IsDelete(i) then
      begin
        SetLength(Result, Length(Result) + 2);
        Result[Length(Result) - 2] := stDelete;
        Result[Length(Result) - 1] := stFrom;
        Inc(i, 5);
      end
      else if IsInsert(i) then
      begin
        SetLength(Result, Length(Result) + 2);
        Result[Length(Result) - 2] := stInsert;
        Result[Length(Result) - 1] := stFrom;
        Inc(i, 5);
      end
      else if IsExecute(i) then
      begin
        SetLength(Result, Length(Result) + 2);
        Result[Length(Result) - 2] := stExecute;
        Result[Length(Result) - 1] := stFrom;
        Inc(i, 6);
      end
      else
      begin
        b := False;
        IsFromBegin(i, b);
        if b then
        begin
          if Length(Result) = 0 then
            SetLength(Result, 1);
          Result[Length(Result) - 1] := stFrom;
          Inc(i, 3);
        end
        else
        begin
          IsWhereBegin(i, b);
          if b then
          begin
            if Length(Result) = 0 then
              SetLength(Result, 1);
            Result[Length(Result) - 1] := stWhere;
            Inc(i, 4);
          end
          else
          begin
            IsOrderBegin(i, b);
            if b then
            begin
              if Length(Result) = 0 then
                SetLength(Result, 1);
              Result[Length(Result) - 1] := stOrderBy;
              Inc(i, 4);
            end
            else
            begin
              IsPlanBegin(i, b);
              if b then
              begin
                if Length(Result) = 0 then
                  SetLength(Result, 1);
                Result[Length(Result) - 1] := stPlan;
                Inc(i, 3);
              end
              else if IsClause(i, 'GROUP') then
              begin
                if Length(Result) = 0 then
                  SetLength(Result, 1);
                Result[Length(Result) - 1] := stGroupBy;
                Inc(i, 5);
              end;
            end
          end;
        end;
      end;

    end;
    Inc(i);
    EndScan := i
  end;
end;

function TSQLParser.ModifiedTables: string;
var
  Start: integer;
  l: integer;
  tmpStr: string;

  procedure CutTable;
  var
    p: integer;
    InQuote: boolean;
  begin
    l := 0;
    InQuote := False;
    SkipCommentsAndBlanks(SQLText, Len, Start);
    for p := Start to Len do
    begin
      case SQLText[p] of
        '-', '/':
          if InQuote then
            Inc(l)
          else
            Break;
        '"':
          begin
            InQuote := not InQuote;
            Inc(l);
            // a doubled quote inside the name does not end it
            if not InQuote and ((p = Len) or (SQLText[p + 1] <> '"')) then
              Break
          end;
        '(':
          if InQuote then
            Inc(l)
          else
            Break;
      else
        if InQuote or not CharInSet(SQLText[p], CharsAfterClause) then
          Inc(l)
        else
          Break;
      end; // end case
    end;
    Result := FastCopy(SQLText, Start, l);
  end;

begin
  case SQLKind of
    skUpdate:
      begin
        Start := FFirstPos + 6;

        CutTable;
        tmpStr := Result;
        Start := Start + l;
        CutTable;
        if FastUpperCase(Result) <> 'SET' then
          Result := tmpStr + ' ' + Result
        else
          Result := tmpStr;
      end;
    skInsert:
      begin
        ScanText(FFirstPos + 7, IsIntoBegin);
        if FResultPos > 0 then
        begin
          Start := FResultPos + 5;
          CutTable;
        end
        else
          Result := 'Unknown'
      end; // skInsert
    skDelete:
      begin
        ScanText(FFirstPos, IsFromBegin);
        if FResultPos > 0 then
        begin
          Start := FResultPos + 4;
          CutTable;
          tmpStr := Result;
          Start := Start + l;
          CutTable;
          if FastUpperCase(Result) <> 'WHERE' then
            Result := tmpStr + ' ' + Result
          else
            Result := tmpStr;
        end
        else
          Result := 'Unknown';
      end;
    skUpdateOrInsert:
      begin
        ScanText(FFirstPos + 6, IsIntoBegin);
        if FResultPos > 0 then
        begin
          Start := FResultPos + 5;
          CutTable;
        end
        else
          Result := 'Unknown'
      end;
  end;
end;

function TSQLParser.OrderText(var StartPos, EndPos: integer): string;
var
  byPos: Integer;
begin
  Result := '';
  StartPos := 0;
  EndPos := 0;
  ScanText(FFirstPos, IsMainOrderBegin);
  if FResultPos = 0 then
    Exit;
  StartPos := FResultPos;
  ScanText(FResultPos + 5, IsByBegin);
  if FResultPos = 0 then
    Exit;
  byPos := FResultPos;
  // ROWS, OFFSET/FETCH, FOR UPDATE, WITH LOCK follow the ORDER BY list
  ScanText(byPos + 2, IsOrderEnd);
  if FResultPos = 0 then
  begin
    Result := FastCopy(SQLText, byPos + 2, MaxInt);
    EndPos := Length(SQLText);
  end
  else
  begin
    Result := FastCopy(SQLText, byPos + 2, FResultPos - byPos - 2);
    EndPos := FResultPos - 1;
  end;
end;

function TSQLParser.OrderClause: string;
var
  StartPos, EndPos: integer;
begin
  Result := OrderText(StartPos, EndPos)
end;

function TSQLParser.SetOrderClause(const Value: string): string;
var
  StartPos, EndPos: integer;
begin
  OrderText(StartPos, EndPos);
  if StartPos = 0 then
  begin
    if FastTrim(Value) = '' then
      Result := SQLText
    else
      Result := FastTrim(SQLText) + sLineBreak + 'ORDER BY ' + Value;
  end
  else
  begin
    if FastTrim(Value) = '' then
      Result := FastCopy(SQLText, 1, StartPos - 1)
    else if SQLText[StartPos - 1] <> #10 then
      Result := FastCopy(SQLText, 1, StartPos - 1) + sLineBreak + 'ORDER BY ' + Value
    else
      Result := FastCopy(SQLText, 1, StartPos - 1) + 'ORDER BY ' + Value;
    // ROWS, OFFSET/FETCH, FOR UPDATE, WITH LOCK
    if (EndPos > 0) and (EndPos < Length(SQLText)) then
      Result := Result + sLineBreak + TrimLeft(FastCopy(SQLText, EndPos + 1, MaxInt));
  end;
end;

function TSQLParser.GroupByText(var StartPos, EndPos: integer): string;
var
  byPos: integer;
begin
  Result := '';
  StartPos := 0;
  EndPos := 0;
  ScanText(FFirstPos, IsMainGroupBegin);
  if FResultPos = 0 then
    Exit;
  StartPos := FResultPos;
  ScanText(FResultPos + 5, IsByBegin);
  if FResultPos = 0 then
    Exit;
  byPos := FResultPos;
  ScanText(byPos + 2, IsGroupEnd);
  if FResultPos = 0 then
  begin
    Result := FastCopy(SQLText, byPos + 2, MaxInt);
    EndPos := Length(SQLText);
  end
  else
  begin
    Result := FastCopy(SQLText, byPos + 2, FResultPos - byPos - 2);
    EndPos := FResultPos - 1;
  end;
end;

function TSQLParser.GroupByClause: string;
var
  StartPos, EndPos: integer;
begin
  Result := GroupByText(StartPos, EndPos);
end;

function TSQLParser.SetGroupClause(const Value: string): string;
var
  StartPos, EndPos: integer;
  StartPosO, EndPosO: integer;
begin
  GroupByText(StartPos, EndPos);
  if StartPos = 0 then
  begin
    if FastTrim(Value) = '' then
      Result := SQLText
    else
    begin
      ScanText(FFirstPos, IsHaving);
      if FResultPos <> 0 then
        StartPosO := FResultPos
      else
      begin
        MainPlanText(StartPosO, EndPosO);
        if StartPosO = 0 then
          OrderText(StartPosO, EndPosO);
      end;
      if StartPosO = 0 then
        Result := FastTrim(SQLText) + sLineBreak + 'GROUP BY ' + Value
      else
        Result := FastTrim(FastCopy(SQLText, 1, StartPosO - 1)) + sLineBreak +
          'GROUP BY ' + Value + sLineBreak + FastCopy(SQLText, StartPosO, MaxInt)
    end;
  end
  else if FastTrim(Value) = '' then
    Result := FastCopy(SQLText, 1, StartPos - 1) + FastCopy(SQLText, EndPos + 1, MaxInt)
  else
  begin
    if SQLText[StartPos - 1] <> #10 then
      Result := FastCopy(SQLText, 1, StartPos - 1) + sLineBreak + 'GROUP BY ' + Value
    else
      Result := FastCopy(SQLText, 1, StartPos - 1) + 'GROUP BY ' + Value;
    // HAVING, PLAN, ORDER BY and the rest after the GROUP BY list
    if (EndPos > 0) and (EndPos < Length(SQLText)) then
      Result := Result + sLineBreak + TrimLeft(FastCopy(SQLText, EndPos + 1, MaxInt));
  end;
end;

function TSQLParser.GetFieldsClause: string;
var
  pb: integer;
  pe: integer;
begin
  if SQLKind <> skSelect then
    Result := ''
  else
  begin
    pe := DispositionMainFrom.X - 1;
    if pe < 0 then
      pe := Length(SQLText);
    pb := FSelectPos + 6;
    while (pb <= Length(SQLText)) and CharInSet(SQLText[pb], [#13, #10, #9, ' ']) do
      Inc(pb);
    while (pe >= 1) and CharInSet(SQLText[pe], [#13, #10, #9, ' ']) do
      Dec(pe);
    Result := FastCopy(SQLText, pb, pe - pb + 1);
  end;
end;

function TSQLParser.SetFieldsClause(const NewFields: string): string;
var
  pb: integer;
  pe: integer;
begin
  if SQLKind <> skSelect then
    Result := SQLText
  else
  begin
    pe := DispositionMainFrom.X;
    if pe = 0 then
      pe := Length(SQLText) + 1;
    pb := FSelectPos + 5;
    Result := FastCopy(SQLText, 1, pb) + sLineBreak + NewFields + sLineBreak + FastCopy(SQLText, pe, MaxInt);
  end;
end;

function TSQLParser.WhereClause(N: integer; var StartPos, EndPos: integer): string;
var
  StartPos1: integer;
begin
  if N < 0 then
  begin
    Result := '';
    StartPos := 0;
    EndPos := 0;
    Exit;
  end;

  Result := '';
  StartPos := 0;
  EndPos := 0;
  FReserved := N; // N- number where clause
  FReserved1 := 0;
  ScanText(FFirstPos, IsWhereBegin);
  if FResultPos > 0 then
  begin
    StartPos := FResultPos;
    StartPos1 := FResultPos + 5;
    FScanInBrackets := FBracketOpened > 0;
    while (StartPos1 <= Len) and CharInSet(SQLText[StartPos1], (CharsAfterClause - ['(', '/', '-', '"'])) do
      Inc(StartPos1);
    ScanText(StartPos1, IsWhereEnd);
    FScanInBrackets := False;
    EndPos := FResultPos;
    if EndPos > 0 then
    begin
      if EndPos <> Length(SQLText) then
        Dec(EndPos);
      while (EndPos > 0) and CharInSet(SQLText[EndPos], (CharsAfterClause - ['(', '/', '"'])) do
        Dec(EndPos);
      Result := FastCopy(SQLText, StartPos1, EndPos - StartPos1 + 1);
    end
    else
      StartPos := 0;
  end;
end;

function TSQLParser.SetWhereClause(N: integer; const Value: string): string;
var
  StartPos, EndPos: integer;
begin
  WhereClause(N, StartPos, EndPos);
  if StartPos = 0 then
    Result := SQLText
  else
  begin
    if IsEmptyStr(Value) then
      Result := FastCopy(SQLText, 1, StartPos - 1) + sLineBreak + FastCopy(SQLText, EndPos + 1, MaxInt)
    else
    begin
      if SQLText[StartPos - 1] <> #10 then
        Result := FastCopy(SQLText, 1, StartPos - 1) + sLineBreak + 'WHERE ' + Value
      else
        Result := FastCopy(SQLText, 1, StartPos - 1) + 'WHERE ' + Value;
      if SQLText[EndPos + 1] <> #13 then
        Result := Result + sLineBreak + FastCopy(SQLText, EndPos + 1, MaxInt)
      else
        Result := Result + FastCopy(SQLText, EndPos + 1, MaxInt);
    end;
  end;
end;

function TSQLParser.SetMainWhereClause(const Value: string): string;
var
  p: integer;
begin
  p := MainWhereIndex;
  if p > 0 then
    Result := SetWhereClause(p, Value)
  else
    Result := AddToMainWhere(Value, False);
end;

function TSQLParser.WhereCount: integer;
begin
  Result := 0;
  FReserved := 0;
  repeat
    ScanText(FResultPos + 5, IsWhereBegin);
    if FResultPos > 0 then
      Inc(Result);
  until FResultPos = 0;
end;

function TSQLParser.PlanCount: integer;
begin
  Result := 0;
  FReserved := 0;
  repeat
    ScanText(FResultPos + 5, IsPlanBegin);
    if FResultPos > 0 then
      Inc(Result);
  until FResultPos = 0;
end;

function TSQLParser.PlanText(N: integer; var StartPos, EndPos: integer): string;
var
  InBrackets: Boolean;
begin
  if N < 0 then
  begin
    Result := '';
    StartPos := 0;
    EndPos := 0;
    Exit;
  end;

  Result := '';
  StartPos := 0;
  EndPos := 0;
  FReserved1 := 0;
  FResultPos := 0;
  FReserved := N; // N- number plan clause
  ScanText(FFirstPos, IsPlanBegin);
  if FResultPos > 0 then
  begin
    StartPos := FResultPos + 5;
    InBrackets := FBracketOpened > 0;
    FScanInBrackets := InBrackets;
    while (StartPos <= Len) and CharInSet(SQLText[StartPos], CharsAfterClause - ['(']) do
      Inc(StartPos);
    ScanText(StartPos, IsPlanEnd);
    FScanInBrackets := False;
    EndPos := FResultPos;
    if EndPos > 0 then
    begin
      // the plan is the last text: its closing bracket is the last character
      if not InBrackets and (EndPos = Len) and not CharInSet(SQLText[Len], CharsAfterClause) then
        Inc(EndPos);
      Dec(EndPos);
      while (EndPos > 0) and CharInSet(SQLText[EndPos], CharsAfterClause) do
        Dec(EndPos);
      Result := FastCopy(SQLText, StartPos, EndPos - StartPos + 1)
    end
    else
      StartPos := 0;
  end;
end;

function TSQLParser.MainPlanIndex: integer;
var
  p: integer;
begin
  p := 0;
  Result := -1;
  FReserved := 0;
  FReserved1 := 0;
  FResultPos := FFirstPos;
  repeat
    ScanText(FResultPos + 5, IsPlanBegin);
    if FResultPos > 0 then
    begin
      Inc(p);
      if FBracketOpened = 0 then
      begin
        Result := p;
        Exit;
      end;
    end;
  until FResultPos = 0;
end;

function TSQLParser.MainPlanText(var StartPos, EndPos: integer): string;
begin
  Result := PlanText(MainPlanIndex, StartPos, EndPos)
end;

function TSQLParser.SetMainPlan(const Text: string): string;
var
  StartPos, EndPos: integer;
begin
  MainPlanText(StartPos, EndPos);
  if StartPos > 0 then
  begin
    if not IsEmptyStr(Text) then
      Result := FastCopy(SQLText, 1, StartPos - 1) + Text + FastCopy(SQLText, EndPos + 1, MaxInt)
    else
      Result := FastCopy(SQLText, 1, StartPos - 6) + FastCopy(SQLText, EndPos + 1, MaxInt)
  end
  else if IsEmptyStr(Text) then
    Result := SQLText
  else
  begin
    OrderText(StartPos, EndPos);
    if StartPos > 0 then
    begin
      Result := FastCopy(SQLText, 1, StartPos - 1);
      if Result[Length(Result)] <> #10 then
        Result := Result + sLineBreak;
      Result := Result + 'PLAN ' + Text + sLineBreak + FastCopy(SQLText, StartPos, MaxInt)
    end
    else if SQLText[Length(SQLText)] <> #10 then
      Result := SQLText + sLineBreak + 'PLAN ' + Text
    else
      Result := SQLText + 'PLAN ' + Text
  end;
end;

function TSQLParser.GetMainPlan: string;
var
  StartPos, EndPos: integer;
begin
  Result := MainPlanText(StartPos, EndPos)
end;

function TSQLParser.MainWhereIndex: integer;
var
  p: integer;
begin
  p := 0;
  Result := -1;
  FResultPos := 0;
  FBracketOpened := 0;
  repeat
    ScanText(FResultPos + 1, IsWhereBegin);
    if FResultPos > 0 then
    begin
      Inc(p);
      if FBracketOpened = 0 then
      begin
        Result := p;
        Exit;
      end;
    end;
  until FResultPos = 0;
end;

function TSQLParser.AddToMainWhere(const NewClause: string; ForceCLRF: boolean): string;
var
  p: integer;
  StartPos, EndPos: integer;
  Separator: string;
begin
  Separator := iifStr(ForceCLRF, ForceNewStr, '');
  if IsBlank(NewClause) then
  begin
    Result := SQLText;
    Exit
  end;
  p := MainWhereIndex;
  if p >= 0 then
  begin
    WhereClause(p, StartPos, EndPos);
    Result := FastCopy(SQLText, 1, StartPos + 4) + '( ' +
      FastCopy(SQLText, StartPos + 5, EndPos - StartPos - 4) + Separator +
      ' ) and ( ' + NewClause + ' )' + Separator + FastCopy(SQLText, EndPos + 1, MaxInt);
  end
  else
  begin
    p := DispositionMainFrom.Y;
    // no FROM: at the end, the server reports the error
    if p = 0 then
      p := Length(SQLText);
    Result := FastCopy(SQLText, 1, p) + #13#10 + BeginWhere + Separator + NewClause +
      #13#10 + FastCopy(SQLText, p + 1, MaxInt)
  end
end;

function TSQLParser.IsSelect(Position: integer): boolean;
begin
  Result := InternalIsClause('SELECT', SQLText, Position);
end;

function TSQLParser.IsUpdate(Position: integer): boolean;
begin
  Result := InternalIsClause('UPDATE', SQLText, Position);
end;

function TSQLParser.IsDelete(Position: integer): boolean;
begin
  Result := InternalIsClause('DELETE', SQLText, Position);
end;

function TSQLParser.IsInsert(Position: integer): boolean;
begin
  Result := InternalIsClause('INSERT', SQLText, Position);
end;

function TSQLParser.IsExecute(Position: integer): boolean;
begin
  Result := InternalIsClause('EXECUTE', SQLText, Position);
end;

function TSQLParser.IsExecuteBlock(Position: integer): boolean;
var
  AfterKeywordPos: Integer;
begin
  if not IsExecute(Position) then
    Result := False
  else
  begin
    AfterKeywordPos := Position + 7;
    SkipCommentsAndBlanks(SQLText, Len, AfterKeywordPos);
    Result := InternalIsClause('BLOCK', SQLText, AfterKeywordPos);
  end;
end;

function TSQLParser.IsExecuteProc(Position: integer): boolean;
var
  AfterKeywordPos: Integer;
begin
  if not IsExecute(Position) then
    Result := False
  else
  begin
    AfterKeywordPos := Position + 7;
    SkipCommentsAndBlanks(SQLText, Len, AfterKeywordPos);
    Result := InternalIsClause('PROCEDURE', SQLText, AfterKeywordPos);
  end;
end;

function TSQLParser.IsDDL: boolean;
var
  AfterKeywordPos: Integer;

begin
  Result := (Len > 0) and ((FFirstPos = 1) or CharInSet(SQLText[FFirstPos - 1], CharsBeforeClause));
  if Result then
    case SQLText[FFirstPos] of
      'A', 'a':
        begin
          Result := InternalIsClause('ALTER', SQLText, FFirstPos);
        end;
      'C', 'c':
        begin
          Result := InternalIsClause('CREATE', SQLText, FFirstPos);
          if not Result then
            Result := InternalIsClause('COMMENT', SQLText, FFirstPos);
        end;
      'D', 'd':
        begin
          Result := InternalIsClause('DROP', SQLText, FFirstPos);
          if not Result then
            Result := InternalIsClause('DECLARE', SQLText, FFirstPos);
        end;
      'G', 'g':
        begin
          Result := InternalIsClause('GRANT', SQLText, FFirstPos);
        end;
      'R', 'r':
        begin
          Result := InternalIsClause('RECREATE', SQLText, FFirstPos);
          if not Result then
            Result := InternalIsClause('REVOKE', SQLText, FFirstPos);
        end;
      'S', 's':
        begin
          Result := False;
          if InternalIsClause('SET', SQLText, FFirstPos) then
          begin
            AfterKeywordPos := FFirstPos + 4;
            while (AfterKeywordPos <= Len) and CharInSet(SQLText[AfterKeywordPos], CharsBeforeClause) do
              Inc(AfterKeywordPos);
            Result := InternalIsClause('GENERATOR', SQLText, AfterKeywordPos);
          end;
        end;
    else
      Result := False;
    end;
end;

function TSQLParser.GetSQLKind: TSQLKind;
var
  j: integer;

  // WITH cte AS (...) SELECT: the SELECT outside the brackets
  function SelectAfterWith: Boolean;
  begin
    FBracketOpened := 0;
    ScanText(FFirstPos + 4, IsMainSelectBegin);
    Result := FResultPos > 0;
    if Result then
      FSelectPos := FResultPos;
    FBracketOpened := 0;
  end;

begin
  FSelectPos := FFirstPos;
  if IsSelect(FFirstPos) then
    Result := skSelect
  else if (FFirstPos < Len) and InternalIsClause('WITH', SQLText, FFirstPos) and
    SelectAfterWith then
    Result := skSelect
  else if IsUpdate(FFirstPos) then
  begin
    Result := skUpdate;
    j := FFirstPos + 6;
    SkipCommentsAndBlanks(SQLText, Len, j);
    if IsClause(j, 'OR') then
      Result := skUpdateOrInsert;
  end
  else if IsDelete(FFirstPos) then
    Result := skDelete
  else if IsInsert(FFirstPos) then
    Result := skInsert
  else if IsExecuteProc(FFirstPos) then
    Result := skExecuteProc
  else if IsExecuteBlock(FFirstPos) then
    Result := skExecuteBlock
  else if IsDDL then
    Result := skDDL
  else
    Result := skUnknown;
  FCanParamsCheck := Result <> skDDL;
end;

function TSQLParser.RecCountSQLText: string;
var
  fr: TPosition;
  StartWhere, EndWhere: integer;
  wh: string;
begin
  Result := '';
  if SQLKind <> skSelect then
    Exit;
  fr := DispositionMainFrom;
  if fr.X = 0 then
    Exit;
  // the WITH clause of a CTE stays before the count
  Result := FastCopy(SQLText, FFirstPos, FSelectPos - FFirstPos) +
    'Select Count(*) ' + FastCopy(SQLText, fr.X, fr.Y - fr.X + 1);
  wh := MainWhereClause(StartWhere, EndWhere);
  if wh <> '' then
    Result := Result + #13#10 + BeginWhere + wh;
end;

function TSQLParser.MainWhereClause(var StartPos, EndPos: integer): string;
begin
  FResultPos := 0;
  Result := WhereClause(MainWhereIndex, StartPos, EndPos)
end;

procedure TSQLParser.FillMainTables(WithSP: boolean = False);
var
  FromPos: TPosition;
  FromTxt: string;
  i, p, p1: integer;
  tmpStr: string;
  wc: integer;
  InQuote: boolean;
begin
  FTables.Clear;
  FromPos := DispositionMainFrom;
  if FromPos.X > 0 then
    if FromPos.Y = Length(SQLText) then
      FromTxt := FastCopy(SQLText, FromPos.X + 5, MaxInt)
    else
      FromTxt := FastCopy(SQLText, FromPos.X + 5, FromPos.Y - FromPos.X - 5)
  else
    FromTxt := '';
  if Length(FromTxt) = 0 then
    Exit;
  FromTxt := RemoveComments(FromTxt);
  i := 1;
  p := 0;
  SetLength(tmpStr, Length(FromTxt));
  InQuote := False;
  while i <= Length(FromTxt) do
  begin
    if not InQuote and CharInSet(FromTxt[i], CharsAfterClause - ['(', '"']) then
    begin
      if p = 0 then
        Inc(i)
      else if CharInSet(FromTxt[i - 1], CharsAfterClause - ['(', '"']) then
        Inc(i)
      else
      begin
        Inc(p);
        tmpStr[p] := ' ';
        Inc(i);
      end;
    end
    else
    begin
      Inc(p);
      tmpStr[p] := FromTxt[i];
      Inc(i);
      if tmpStr[p] = '"' then
        InQuote := not InQuote;
    end;
  end;
  if (p > 0) and (tmpStr[p] = ' ') then
    Dec(p);
  SetLength(tmpStr, p);
  FromTxt := tmpStr;
  FromTxt := RemoveJoins(FromTxt);
  if PosCh('(', FromTxt) > 0 then
    FromTxt := RemoveSP(FromTxt, WithSP);
  wc := WordCount(FromTxt, [',']);
  for i := 1 to wc do
  begin
    tmpStr := ExtractWord(i, FromTxt, [',']);
    DoTrim(tmpStr);
    if Length(tmpStr) > 0 then
    begin
      p := PosCh1('"', tmpStr, 2);
      if p = 0 then
        tmpStr := UpperCase(tmpStr)
      else
      begin
        p1 := PosCh1('"', tmpStr, p + 1);
        case tmpStr[1] of
          '"':
            begin
              if p1 = 0 then
              begin
                DoUpperCase(tmpStr, p + 1, MaxInt);
              end;
            end;
        else
          DoUpperCase(tmpStr, 1, p - 1);
          if p1 = 0 then
          begin
            DoUpperCase(tmpStr, p + 1, MaxInt);
          end;
        end;
      end;
      FTables.Add(tmpStr);
    end;
  end;
end;

function TSQLParser.GetAllTables(WithSP: boolean = False): TStrings;
begin
  if FTables.Count = 0 then
  begin
    case SQLKind of //
      skSelect:
        begin
          FillMainTables(WithSP);
        end;
    else
      FTables.Text := ModifiedTables;
    end;
  end;
  Result := FTables
end;

function GetFieldByAlias(const SQLText, FieldName: string): string;
var
  p: integer;
  cBracket: integer;
  Step: Byte;
  FieldsClauseTxt: string;
  OnlyNumeric: boolean;
begin
  FieldsClauseTxt := FieldsClause(SQLText);
  p := PosExtCI(FieldName, FieldsClauseTxt, CharsBeforeClause, CharsAfterClause + [',']);
  if p = 0 then
    p := PosExtCI('"' + FieldName + '"', FieldsClauseTxt, CharsBeforeClause, CharsAfterClause + [',']);

  Dec(p);
  if p <= 0 then
  begin
    Result := '';
    Exit;
  end
  else if FieldsClauseTxt[p] = '"' then
    Dec(p);

  while (p > 0) and CharInSet(FieldsClauseTxt[p], CharsAfterClause) do
    Dec(p);

  if (p = 0) or (FieldsClauseTxt[p] = ',') then
  begin
    Result := FieldName;
    Exit;
  end;
  if p > 3 then
  begin
    if CharInSet(FieldsClauseTxt[p], ['S', 's']) then
      if CharInSet(FieldsClauseTxt[p - 1], ['A', 'a']) then
        if CharInSet(FieldsClauseTxt[p - 2], CharsAfterClause + [')']) then
          Dec(p, 2);
  end;
  while (p > 0) and CharInSet(FieldsClauseTxt[p], CharsAfterClause + [#10]) do
    Dec(p);
  if (p = 0) or (FieldsClauseTxt[p] = ',') then
  begin
    Result := FieldName;
    Exit;
  end;
  if FieldsClauseTxt[p] <> ')' then
  begin
    Result := '';
    Step := 1;
    (* Step
      1 - Fill name and wait '.'
      2 - wait '.'
      3 - Skip ' '
      4 - Fill name and wait ' '

    *)

    while (p > 0) do
    begin
      case FieldsClauseTxt[p] of
        ',': Break;
        '.':
          begin
            if Step in [1, 2] then
              Step := 3;
            Result := FieldsClauseTxt[p] + Result;
          end;
      else
        if not CharInSet(FieldsClauseTxt[p], CharsAfterClause) then
        begin
          case Step of
            2: Break;
            3: Step := 4
          end;
          Result := FieldsClauseTxt[p] + Result;
        end
        else
          case Step of
            1: Step := 2;
            4: Break
          end
      end;
      Dec(p);
    end;
  end
  else
  begin
    cBracket := 1;
    Result := '';
    Dec(p);
    while (cBracket > 0) and (p > 0) do
    begin
      if FieldsClauseTxt[p] = '(' then
        Dec(cBracket)
      else if FieldsClauseTxt[p] = ')' then
        Inc(cBracket);
      if (cBracket > 0) then
        Result := FieldsClauseTxt[p] + Result;
      Dec(p);
    end;
    while (p > 0) and CharInSet(FieldsClauseTxt[p], CharsAfterClause + [#10]) do
      Dec(p);
    while (p > 0) and not CharInSet(FieldsClauseTxt[p], CharsAfterClause + [',']) do
    begin
      Result := FieldsClauseTxt[p] + Result;
      Dec(p);
    end;
  end;
  case Length(Result) of
    2:
      if CharInSet(Result[1], ['O', 'o']) and CharInSet(Result[2], ['R', 'r']) then
        Result := '';
    3:
      if CharInSet(Result[1], ['A', 'a']) and CharInSet(Result[2], ['N', 'n']) and CharInSet(Result[3], ['D', 'd']) then
        Result := '';
  end;

  if Length(Result) = 8 then
    if (Result[1] in ['D', 'd']) and (Result[2] in ['I', 'i']) and
      (Result[3] in ['S', 's']) and (Result[4] in ['T', 't']) and
      (Result[5] in ['I', 'i']) and (Result[6] in ['N', 'n']) and
      (Result[7] in ['C', 'c']) and (Result[8] in ['T', 't']) then
    begin
      Result := FieldName;
      Exit;
    end;
  OnlyNumeric := True;
  for p := 1 to Length(Result) do
    if not(Result[p] in ['0' .. '9']) then
    begin
      OnlyNumeric := False;
      Break
    end;
  if OnlyNumeric then
    Result := FieldName;

end;

function GetLinkFieldName(const SQLText, ParamName: string): string;
var
  Ind: integer;
  wh: string;
  StartPos, EndPos: integer;
  c, p: integer;
begin
  Result := '';
  c := WhereCount(SQLText);
  Ind := 1;
  while Ind <= c do
  begin
    wh := GetWhereClause(SQLText, Ind, StartPos, EndPos);
    p := PosExtCI(':' + ParamName, wh, CharsBeforeClause + endLexem, CharsAfterClause + endLexem) - 1;
    if p < 0 then
      p := PosExt(':"' + ParamName + '"', wh, CharsBeforeClause + endLexem, CharsAfterClause + endLexem) - 1;
    while (p > 0) and CharInSet(wh[p], CharsBeforeClause + endLexem + [':', #13]) do
      Dec(p);
    if p > 0 then
    begin
      while (p > 0) and not CharInSet(wh[p], CharsBeforeClause + endLexem + [':', '.']) do
      begin
        Result := wh[p] + Result;
        Dec(p);
      end;
      Exit;
    end;

    p := PosExtCI('?' + ParamName, wh, CharsBeforeClause + endLexem, CharsAfterClause + endLexem) - 1;
    while (p > 0) and CharInSet(wh[p], CharsBeforeClause + endLexem + ['?', #13]) do
      Dec(p);
    if p > 0 then
    begin
      while (p > 0) and not CharInSet(wh[p], CharsBeforeClause + endLexem + ['?']) do
      begin
        Result := wh[p] + Result;
        Dec(p);
      end;
      Exit;
    end;
    Inc(Ind);
  end;
end;

function IsWhereBeginPos(const SQLText: string; Position: integer): boolean;
begin
  Result := (Position > 1) and CharInSet(SQLText[Position - 1],
    CharsBeforeClause) and InternalIsClause('WHERE', SQLText, Position);
end;

function IsWhereEndPos(const SQLText: string; Position: integer): boolean;
var
  p: integer;
  Len: integer;
begin
  Len := Length(SQLText);
  p := Position;
  Result := p = Len;
  if Result then
    Exit;
  if (Len > p) and (p > 1) and CharInSet(SQLText[p - 1], CharsBeforeClause) then
  begin
    if (Len - p) > 1 then
      case SQLText[p] of
        'F', 'f': // FOR UPDATE
          Result := InternalIsClause('FOR', SQLText, p);
        'G', 'g': // GROUP BY
          Result := InternalIsClause('GROUP', SQLText, p);
        'H', 'h': // HAVING
          Result := InternalIsClause('HAVING', SQLText, p);

        'O', 'o': // ORDER BY
          Result := InternalIsClause('ORDER', SQLText, p);
        'P', 'p': // PLAN
          Result := InternalIsClause('PLAN', SQLText, p);
        'S', 's': Result := InternalIsClause('START', SQLText, p);
        'U', 'u': Result := InternalIsClause('UNION', SQLText, p);
      end;
    if not Result then
      Result := IsTailClauseAt(SQLText, p);
  end
end;

function PosInSections(const SQLText: string; Position: integer): TSQLSections;
var
  SQLPars: TSQLParser;
begin
  SQLPars := TSQLParser.Create(SQLText);
  try
    Result := SQLPars.PosInSections(Position)
  finally
    SQLPars.Free
  end;
end;

function InvertOrderClause(const OrderText: string): string;
const
  Blanks = [' ', #9, #10, #13];
var
  Items: TSQLTextParts;
  i, P, E, ExprEnd: Integer;
  Item, Word, Collation, Nulls, Expected: string;
  Ascending: Boolean;
begin
  Result := '';
  Items := SplitTopLevel(RemoveComments(OrderText), ',');
  for i := 0 to High(Items) do
  begin
    // expr [COLLATE name] [ASC[ENDING] | DESC[ENDING]] [NULLS FIRST | LAST]
    Item := Items[i];
    ExprEnd := 0;
    Collation := '';
    Nulls := '';
    Expected := '';
    Ascending := True;
    P := 1;
    while P <= Length(Item) do
    begin
      E := TopLevelPos(Blanks, Item, P);
      if E = 0 then
        E := Length(Item) + 1;
      Word := Copy(Item, P, E - P);
      if Expected = 'COLLATE' then
      begin
        Collation := Collation + ' ' + Word;
        Expected := '';
      end
      else if Expected = 'NULLS' then
      begin
        if SameText(Word, 'FIRST') then
          Nulls := ' NULLS LAST'
        else
          Nulls := ' NULLS FIRST';
        Expected := '';
      end
      else if P > 1 then
      begin
        Word := UpperCase(Word);
        if (Word = 'COLLATE') or (Word = 'NULLS') then
        begin
          if Word = 'COLLATE' then
            Collation := Copy(Item, P, E - P);
          Expected := Word;
        end
        else if (Word = 'ASC') or (Word = 'ASCENDING') then
          Ascending := True
        else if (Word = 'DESC') or (Word = 'DESCENDING') then
          Ascending := False
        else
          Word := '';
        if (Word <> '') and (ExprEnd = 0) then
          ExprEnd := P;
      end;
      P := SkipBlanks(Item, E);
    end;
    if ExprEnd > 0 then
      Item := TrimRight(Copy(Item, 1, ExprEnd - 1));
    if Collation <> '' then
      Item := Item + ' ' + Collation;
    if Ascending then
      Item := Item + ' desc';
    if i > 0 then
      Result := Result + ', ';
    Result := Result + Item + Nulls;
  end;
end;

function ChangeToSQLDecimalSeparator(const Source: string): string;
begin
{$IFDEF D_XE3}with FormatSettings do {$ENDIF}
    if DecimalSeparator = '.' then
      Result := Source
    else
    begin
      Result := ReplaceStr(Source, DecimalSeparator, '.')
    end;
end;

function SQLStringLiteral(const S: string): string;
begin
  if Pos('''', S) > 0 then
    Result := '''' + ReplaceStr(S, '''', '''''') + ''''
  else
    Result := '''' + S + '''';
end;

function SQLHexLiteral(const Data; Size: Integer): string;
const
  HexDigits: array [0 .. 15] of Char = '0123456789ABCDEF';
var
  i: Integer;
  P: PByte;
begin
  SetLength(Result, Size * 2 + 3);
  Result[1] := 'x';
  Result[2] := '''';
  P := @Data;
  for i := 0 to Size - 1 do
  begin
    Result[2 * i + 3] := HexDigits[P^ shr 4];
    Result[2 * i + 4] := HexDigits[P^ and 15];
    Inc(P);
  end;
  Result[Size * 2 + 3] := '''';
end;

function FieldValueToStr(Field: TField; Old: Boolean): string;
var
  v: Variant;
  Guid: TGUID;
  P: Pointer;
  Bytes: FIBByteString;
begin
  if Old then
    v := Field.OldValue
  else
    v := Field.Value;

  if VarIsNull(v) or VarIsEmpty(v) then
    Result := 'NULL'
  else
  begin
    case Field.DataType of
      ftBCD, ftFloat, ftFMTBcd: Result := ChangeToSQLDecimalSeparator(VarToStr(v));
      // quoted ':' : FormatDateTime replaces a bare ':' with the locale time separator
      ftDate: Result := '''' + FormatDateTime('yyyy-mm-dd', VarToDateTime(v)) + '''';
      ftTime: Result := '''' + FormatDateTime('hh":"nn":"ss.zzz', VarToDateTime(v)) + '''';
      ftDateTime: Result := '''' + FormatDateTime('yyyy-mm-dd hh":"nn":"ss.zzz', VarToDateTime(v)) + '''';
      ftString, ftWideString, ftMemo, ftWideMemo, ftFmtMemo: Result := SQLStringLiteral(VarToStr(v));
      ftBlob, ftGraphic, ftTypedBinary, ftBytes, ftVarBytes:
        if VarIsArray(v) then
        begin
          P := VarArrayLock(v);
          try
            Result := SQLHexLiteral(P^, VarArrayHighBound(v, 1) - VarArrayLowBound(v, 1) + 1);
          finally
            VarArrayUnlock(v);
          end;
        end
        else
        begin
          Bytes := FIBByteString(v);
          Result := SQLHexLiteral(PAnsiChar(Bytes)^, Length(Bytes));
        end;
      ftGuid:
        begin
          // CHAR(16) OCTETS column: the bytes of the TGUID, as a parameter sends them
          Guid := StringToGUID(VarToStr(v));
          Result := SQLHexLiteral(Guid, SizeOf(Guid));
        end;
    else
      Result := VarToStr(v)
    end
  end;
end;

function GenerateInsertRow(DataSet: TDataSet; TableName: string; var fNames: string; FieldList: TList = nil): string;
var
  i, c, l, L1: integer;
  fValues, fValue: string;
  fGenerateNames: boolean;
  fCutFieldName: string;
begin
  fGenerateNames := fNames = '';
  if fGenerateNames then
    fNames := '(';
  l := 255;
  SetLength(fValues, l);
  L1 := 7;
  Move('values(', fValues[1], 7 * SizeOf(Char));
  c := DataSet.FieldCount - 1;
  for i := 0 to c do
    if (DataSet.Fields[i].FieldKind = fkData) and
      ((FieldList = nil) or (FieldList.IndexOf(DataSet.Fields[i]) > -1)) then
    begin
      if fGenerateNames then
      begin
        if DataSet.Fields[i].Origin = '' then
          fNames := fNames + FormatIdentifier(3, DataSet.Fields[i].FieldName) + ','
        else
        begin
          fCutFieldName := Copy(DataSet.Fields[i].FieldName, Pos('.', DataSet.Fields[i].FieldName) + 1, 100);
          fNames := fNames + FormatIdentifier(3, fCutFieldName) + ','
        end;
      end;
      fValue := FieldValueToStr(DataSet.Fields[i]);
      // the value and the ',' after it
      if L1 + Length(fValue) + 1 > l then
      begin
        l := (L1 + Length(fValue) + 1) * 2;
        SetLength(fValues, l);
      end;
      Move(fValue[1], fValues[L1 + 1], Length(fValue) * SizeOf(Char));
      Inc(L1, Length(fValue) + 1);
      fValues[L1] := ',';
    end;
  fValues[L1] := ')';
  SetLength(fValues, L1);
  if fGenerateNames then
    fNames[Length(fNames)] := ')';
  Result := 'Insert into ' + TableName + fNames + fValues + ';';
end;

procedure InternalGetExportDataScript(DataSet: TDataSet;
  const TableName: string; OutPut: TStrings; UseFieldNames: boolean = True;
  FieldList: string = ''; FileName: string = '');
var
  ContextCount: integer;
  Block: TStrings;
  BlockSize: integer;
  InsertRow: string;
  fFieldNames: string;
  fl: TList;
  vForceStrings: boolean;
  FileStream: TStream;

  procedure FlushToFile;
  begin
    OutPut.SaveToStream(FileStream);
  end;

  procedure DoEndBlock;
  begin
    Block.Add('END^');
    ContextCount := 0;
    OutPut.AddStrings(Block);
    Block.Clear;
    BlockSize := 0;
    if FileName <> '' then
      FlushToFile;
    if vForceStrings then
      OutPut.Clear
  end;

begin
  if ((OutPut = nil) and (FileName = '')) or (DataSet = nil) or not DataSet.Active then
    Exit;
  vForceStrings := OutPut = nil;
  FileStream := nil;
  if vForceStrings then
    OutPut := TStringList.Create;
  // a new file: the script of an earlier export is not kept
  if FileName <> '' then
    try
      FileStream := TFileStream.Create(FileName, fmCreate);
    except
      if vForceStrings then
        OutPut.Free;
      raise;
    end;
  OutPut.Clear;
  OutPut.Capacity := 100000;
  OutPut.Add('SET TERM ^ ;');
  Block := TStringList.Create;
  if FieldList = '' then
    fl := nil
  else
  begin
    fl := TList.Create;
    DataSet.GetFieldList(fl, FieldList)
  end;
  if UseFieldNames then
    fFieldNames := ''
  else
    fFieldNames := ' ';
  with DataSet do
    try
      ContextCount := 0;
      DisableControls;
      First;
      while not eof do
      begin
        if ContextCount = 0 then
        begin
          Block.Clear;
          BlockSize := 0;
          Block.Add('EXECUTE BLOCK AS BEGIN');
          Inc(BlockSize, Length(Block[0]) + 2);
        end;
        InsertRow := GenerateInsertRow(DataSet, TableName, fFieldNames, fl);
        // a row longer than a block gets a block of its own
        if (ContextCount = 0) or (BlockSize + Length(InsertRow) + 2 + 4 < High(Word)) then
        begin
          Inc(BlockSize, Length(InsertRow) + 2);
          Inc(ContextCount);
          Block.Add(InsertRow);
          if ContextCount > 254 then
            DoEndBlock;
          Next
        end
        else
          DoEndBlock;
      end;
      if Block.Count > 0 then
        DoEndBlock;
    finally
      EnableControls;
      FileStream.Free;
      fl.Free;
      if vForceStrings then
        OutPut.Free
      else
        OutPut.Capacity := OutPut.Count;
      Block.Free
    end;
end;

procedure GetExportDataScript(DataSet: TDataSet; const TableName: string;
  OutPut: TStrings; UseFieldNames: boolean = True; FieldList: string = '');
begin
  InternalGetExportDataScript(DataSet, TableName, OutPut, UseFieldNames, FieldList);
end;

procedure GetExportDataScriptToFile(DataSet: TDataSet; const TableName: string;
  const FileName: string; UseFieldNames: boolean = True;
  FieldList: string = '');
begin
  InternalGetExportDataScript(DataSet, TableName, nil, UseFieldNames, FieldList, FileName);
end;

function TSQLParser.GetWord(Position: integer; var StartWord: integer; PartOnly: boolean): string;
var
  i: integer;
  StartLine: integer;
  InQuoted: boolean;
begin
  Result := '';
  StartWord := -1;
  if (Position > 0) and (Position <= Length(FSQLText)) then
  begin
    StartLine := Position;

    while (StartLine > 1) and not(FSQLText[StartLine] in [#13, #10]) do
      Dec(StartLine);

    InQuoted := False;
    for i := StartLine to Position - 1 do
      InQuoted := InQuoted xor (FSQLText[i] = '"');

    if not InQuoted then
      if FSQLText[Position] in endLexem + CharsAfterClause - ['.', '"'] then
      begin
        StartWord := Position;
        while FSQLText[StartWord] in [' ', #9, #13, #10] do
          Dec(StartWord);
        Exit;
      end;

    StartWord := Position;
    if not PartOnly then
    begin
      for i := Position + 1 to Length(FSQLText) do
        if not InQuoted and (FSQLText[i] in endLexem + CharsAfterClause + ['.'] - ['"']) then
          Break
        else
          case FSQLText[i] of
            '"':
              begin
                if InQuoted then
                  Result := Result + FSQLText[i];
                Break
              end;
          else
            Result := Result + FSQLText[i];
          end
    end;

    for i := Position downto 1 do
    begin
      if not InQuoted and (FSQLText[i] in endLexem + CharsAfterClause - ['.', '"']) then
        Break
      else
        case FSQLText[i] of
          '.':
            begin
              if InQuoted then
              begin
                Result := FSQLText[i] + Result;
                StartWord := i;
              end
              else if i = Position then
              begin
                Result := FSQLText[i] + Result;
                StartWord := i;
                Break
              end
              else
                Break
            end;
          '"':
            begin
              if InQuoted then
              begin
                Result := FSQLText[i] + Result;
                StartWord := i;
                if i <> Position then
                  Break
              end
              else
                Break
            end
        else
          Result := FSQLText[i] + Result;
          StartWord := i;
        end;
    end;

  end;
end;

function TSQLParser.GetPrevWord(CurPosition: integer; var PosPrevWord: integer): string;
var

  StartPos: integer;
begin
  Result := '';

  GetWord(CurPosition, StartPos, True);
  if StartPos <= 1 then
  begin
    PosPrevWord := -1;
    Exit;
  end;

  Dec(StartPos);
  Result := GetWord(StartPos, PosPrevWord, True);

end;

end.
