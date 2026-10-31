{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ InterBase databases                                           }
{                                                               }
{    FIBPlus is based in part on the product                    }
{    Free IB Components, written by Gregory H. Deatz for        }
{    Hoagland, Longo, Moran, Dunst & Doukas Company.            }
{    mailto:gdeatz@hlmdd.com                                    }
{                                                               }
{    Copyright (c) 1998-2013 Devrace Ltd.                       }
{    Written by Serge Buzadzhy                                  }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit FIBScripter;

interface

{$I FIB.inc}
{$A2}

uses
  SysUtils, Classes, Types, FIBDatabase, FIBQuery,
  FIB, FIBInterfaces;

type
  TFIBStatementType = (
    sUnknown,
    sInvalid,
    sDML,
    sConnect,
    sDisconnect,
    sReconnect,
    sCreateDatabase,
    sDropDatabase,
    sCommit,
    sRollBack,
    sCreate,
    sAlter,
    sRecreate,
    sDrop,
    sSet,
    sSetGenerator,
    sSetStatistics,
    sDescribe,
    sDeclare,
    sComment,
    sGrant,
    sRunFromFile,
    sBatch { Temp Type },
    sBatchStart,
    sBatchExecute,
    sExecute,
    sInsert,
    sReinsert,
    sDirective,
    sSetSession
  );
  TFIBScriptObjectType = (
    otNone,
    otDatabase,
    otDomain,
    otTable,
    otView,
    otProcedure,
    otTrigger,
    otUDF,
    otException,
    otGenerator,
    otIndex,
    otConstraint,
    otFilter,
    otField,
    otParameter,
    otRole,
    otBlock,
    otUser,
    otPackage,
    otPackageBody,
    otFunction
  );

  TFIBStatementCoord = record
    X: Integer;
    Y: Integer;
  end;

  PFIBStatementCoord = ^TFIBStatementCoord;

  // smdEnd is the last character of the statement text, without the terminator,
  // blanks and comments after it. smdEnd.X=0 means the statement has no terminator
  // (only when ParseScript is called with IgnoreLastTerm=False)
  TFIBStatementDesc = record
    smdBegin: TFIBStatementCoord;
    smdEnd: TFIBStatementCoord;
    smtType: TFIBStatementType;
    objType: TFIBScriptObjectType;
    objName: string;
    DirectiveNum: Integer;
    DirectiveElse: Boolean;
    HasReturning: Boolean;
  end;

  PFIBStatementDesc = ^TFIBStatementDesc;

  TFIBScriptMap = array of TFIBStatementDesc;

  TFIBParseStatementEvent = procedure(Sender: TObject; StatementNo: Integer; Coord: TFIBStatementDesc; SQLText: TStrings) of object;

  TFIBDirectiveState = (dsUnknown, dsTrue, dsFalse);

  TFIBDirectiveDesc = record
    dBegin: TFIBStatementCoord;
    dConditionClose: TFIBStatementCoord;
    dElse: TFIBStatementCoord;
    dEnd: TFIBStatementCoord;
    dState: TFIBDirectiveState;
    OwnerDirectiveNum: Integer;
    OwnerDirectiveElse: Boolean;
    dCondition: string; // text from dBegin to dConditionClose
  end;

  PFIBDirectiveDesc = ^TFIBDirectiveDesc;
  TFIBDirectivesMap = array of TFIBDirectiveDesc;
  PFIBDirectivesMap = array of PFIBDirectiveDesc;

  TFIBParseDisposition = (pdBetweenStatements, pdInStatement, pdInDirective);
  TFIBScriptParserState = (psNormal, psInComment, psInQuote, psInDoubleQuote, psInQString, psInConditional);
  // Words that decide where a statement ends
  TFIBScriptKeyword = (
    kwOther,
    kwAlter,
    kwAs,
    kwBegin,
    kwBlock,
    kwCase,
    kwCreate,
    kwDelete,
    kwEnd,
    kwExecute,
    kwExternal,
    kwFunction,
    kwInsert,
    kwMerge,
    kwOr,
    kwPackage,
    kwProcedure,
    kwRecreate,
    kwReinsert,
    kwSet,
    kwTerm,
    kwTrigger,
    kwUpdate
  );

  // Splits a script into statements in one pass. Lines are scanned as they are
  // added, so a script is parsed either as a whole or while it is read from a file.
  // Coordinates are script lines, the parser holds lines from FFirstLine on.
  TFIBScriptParser = class
  private
    FScript: TStrings;
    FFirstLine: Integer;
    FNextLine: Integer;
    FTerminator: string;
    FTermFirst, FTermFirstLower: Char;
    // first char of FTerminator in both cases
    FStatements: TFIBScriptMap;
    FStatementCount: Integer;
    // started statements, the last one may be incomplete
    FCompleteCount: Integer;
    FTakenCount: Integer; // complete statements returned by NextStatement
    FDirectives: TFIBDirectivesMap;
    FDirectiveCount: Integer;
    FDirectiveStack: array of Integer;
    FCurDirective: Integer;
    FDisposition: TFIBParseDisposition;
    FState: TFIBScriptParserState;
    FQuoteClose: Char;
    FLastSignificant: TFIBStatementCoord; // last character out of blanks and comments
    // Structure of the current statement
    FWordCount: Integer;
    FHeader: array [0 .. 3] of TFIBScriptKeyword; // first words
    FParenDepth: Integer;
    FMayHaveBody: Boolean;
    // CREATE, ALTER, RECREATE or EXECUTE with the ";" terminator
    FExternal: Boolean; // EXTERNAL module, without a PSQL body
    FInBody: Boolean; // in the body of a PSQL module, after AS
    FBlockDepth: Integer; // BEGIN and CASE blocks open in the body
    FLastWordIsEnd: Boolean;
    FCheckReturning: Boolean;
    FInSetTerm: Boolean;
    FNewTerminator: string;
    FNewTerminatorDone: Boolean;
    // Details of the script
    FCurDBName: string;
    FMakeConnectInScript: Boolean;
    FHaveDMLStatements: Boolean;
    FHaveUnknownStatements: Boolean;
    function Line(Y: Integer): string;
    procedure ScanLine(Y: Integer);
    function IsTerminatorAt(const S: string; X: Integer): Boolean;
    function IsModuleHeader: Boolean;
    procedure SetTerminator(const Value: string);
    procedure ProcessWord(const S: string; X, Len: Integer);
    procedure BeginStatement(X, Y: Integer; StmtType: TFIBStatementType);
    procedure EndStatement;
    procedure EndSetTerm;
    procedure BeginDirective(X, Y: Integer);
    procedure CloseDirectiveCondition(X, Y: Integer);
    procedure ElseDirective(X, Y: Integer);
    procedure EndIfDirective(X, Y: Integer);
    function NextTokenPos(TokenPos: TFIBStatementCoord; EndCoord: TFIBStatementCoord): TFIBStatementCoord;
    function GetToken(TokenPos: TFIBStatementCoord; IgnoreQuote: Boolean = True): string;
    procedure SearchObjectType(var stmtDesc: TFIBStatementDesc; var BegSearch: TFIBStatementCoord; ForGrant: Boolean = False);
    procedure ValidateStatement(var stmtDesc: TFIBStatementDesc);
    function StmtTypeNameToType(const TestString: string; Position: Integer): TFIBStatementType;
    function TypeNameToObjectType(const TestString: string; Position: Integer): TFIBScriptObjectType;
  public
    procedure ParseScript(AScript: TStrings; var Terminator: string;
      var ScriptMap: TFIBScriptMap; var DirectivesMap: TFIBDirectivesMap;
      IgnoreLastTerm: Boolean = True);
    // Incremental parsing: BeginParse, then Scan after lines are added to AScript,
    // NextStatement to take the complete statements and DiscardParsed to drop
    // them with their lines. EndParse completes the last statement.
    procedure BeginParse(AScript: TStrings; const Terminator: string);
    procedure Scan;
    procedure EndParse(IgnoreLastTerm: Boolean);
    function NextStatement(var Stmt: PFIBStatementDesc): Boolean;
    procedure DiscardParsed;
    procedure CopyFragment(BegPos, EndPos: TFIBStatementCoord; Dest: TStrings);
    property Terminator: string read FTerminator;
  end;

  TFIBStatementExecuteEvent = procedure(Sender: TObject; Line: Integer;
    StatementNo: Integer; Desc: TFIBStatementDesc; Statement: TStrings) of object;
  TFIBScriptExecErrorEvent = procedure(Sender: TObject; StatementNo: Integer;
    Line: Integer; Statement: TStrings; SQLCode: Integer; const Msg: string;
    var doRollBack: Boolean; var Stop: Boolean) of object;

  TFIBAnsiStringArray = array of AnsiString;

  TFIBScripter = class(TComponent, IFIBScripter)
  private
    FPrepared: Boolean;
    FMakeConnectInScript: Boolean;
    FParser: TFIBScriptParser;
    FScript: TStrings;
    FScriptMap: TFIBScriptMap;
    FLineCountInFile: Integer;
    FRunDepth: Integer; // nesting of ExecuteScript and ExecuteFromFile (INPUT)
    FFileEncoding: TEncoding; // Encoding of the file being run, used by its INPUT files
    procedure DoOnChangeScript(Sender: TObject);
  private
    FDatabase: TFIBDatabase;
    FTransaction: TFIBTransaction;
    FQuery: TFIBQuery;
    FPaused: Boolean;
    FSkipStatement: Boolean;
    FStopStatementNo: Integer;
    FSQLDialect: Integer;
    FLibraryName: string;
    FCharSet: string;
    FAutoDDL: Boolean;
    FBlobFile: string;
    FBlobFileStream: TFileStream;
    FInternalDatabase: Boolean;
    FExternalTransaction: TFIBTransaction;
    FHaveDMLStatements: Boolean;
    FHaveUnknownStatements: Boolean;
    FNeedRestoreForceWrite: Boolean;
    FDBParamsFromCreate: Boolean; // DBParams were replaced by CREATE DATABASE
    FReinsertPrepared: Boolean;
    FLastInsertStatement: string;
  private
    // AutoExecBlock support
    FUseExecBlockForDML: Boolean;
    FBlockStatementCount: Integer;
    FBlockSize: Integer; // bytes in FBlockCodePage
    FBlockMaxSize: Integer;
    FBlockCodePage: Word;
    FExecBlockStatement: TStrings;
    // the last statement added to the block, reported when the block runs
    FBlockLastStmt: TFIBStatementDesc;
    FBlockLastStmtNo: Integer;
    FBlockLastLine: Integer;
    procedure RestartBlock;
    function CanGroupInExecuteBlock(const Stmt: TFIBStatementDesc): Boolean;
    function ExecuteBlockMaxSize(out CodePage: Word): Integer;
    function AddStatementToExecuteBlock(const Stmt: TFIBStatementDesc; StmtNo, Line: Integer; SQLText: TStrings): Boolean;
    function FlushExecBlock: Boolean;
  private
    FOnExecuteError: TFIBScriptExecErrorEvent;
    FBeforeStatementExecute: TFIBStatementExecuteEvent;
    FAfterStatementExecute: TFIBStatementExecuteEvent;
    procedure SetDatabase(const Value: TFIBDatabase);
    procedure SetTransaction(const Value: TFIBTransaction);
    function GetTransaction: TFIBTransaction;
    procedure DoReconnect;
    procedure SetConnectParams(StartToken: TFIBStatementCoord; EndCoord: TFIBStatementCoord; KeepDBParams: Boolean = False);
    procedure TryFillBlobParams;
    function PrepareReinsert(const InsTxt, ReInsTxt: string): string;
    procedure BeginRun(Resume: Boolean);
    procedure EndRun;
    function HandleExecuteError(E: EFIBError; const Stmt: TFIBStatementDesc; StmtNo: Integer; SQLText: TStrings): Boolean;
    procedure ApplyCommand(const Stmt: TFIBStatementDesc; StmtNo, Line: Integer; StmtTxt, SQLText: TStrings);
    function RunStatement(Stmt: PFIBStatementDesc; StmtNo: Integer; StmtTxt: TStrings): Boolean;
    function ExecuteParsed(var StmtNo: Integer; StmtTxt: TStrings): Boolean;
  private
    // IB2007
    FInBatchCollect: Boolean;
    FBatchSQLs: TFIBAnsiStringArray;
    FInternalOnStatementExec: TFIBScriptStatementExecEvent;
    procedure SetOnStatExec(CallBack: TFIBScriptStatementExecEvent);
    // Directives
  private
    FDefines: TStrings;
    FDirectiveConsts: TStrings;
    procedure SetScript(const Value: TStrings);
    procedure SetDefines(const Value: TStrings);
    function DirectiveAllows(DirNum: Integer; InElse: Boolean): Boolean;
    function CalcDirective(Directive: TFIBDirectiveDesc): TFIBDirectiveState;
    function CalcExists(Condition: TStrings): TFIBDirectiveState;
    function CalcIF(Condition: TStrings): TFIBDirectiveState;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure CreateInternalDatabase;
    procedure CopyFragment(BegPos, EndPos: TFIBStatementCoord; Dest: TStrings);

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Parse(Terminator: string = ';');
    procedure ExecuteScript(FromStmt: Integer = 1);
    procedure ExecuteFromFile(const FileName: string; Terminator: string = ';'); overload;
    procedure ExecuteFromFile(const FileName: string; Encoding: TEncoding;
      Terminator: string = ';'); overload;
    function ExecuteStatement(StmtTxt: TStrings; Stmt: PFIBStatementDesc; StmtNo: Integer;
      TmpSQL: TStrings = nil; LineInFile: Integer = -1): Boolean;
    procedure ClearPrepared;
    function StatementsCount: Integer;
    function GetStatement(StmtNo: Integer; Text: TStrings): PFIBStatementDesc;
    function LineCountInCurrentFile: Integer;

    procedure AddDefine(const Def: string);
    procedure DeleteDefine(const Def: string);
    procedure PreparePreDefines;
    property Prepared: Boolean read FPrepared;
    property StopStatementNo: Integer read FStopStatementNo;
    property Query: TFIBQuery read FQuery;
    property MakeConnectInScript: Boolean read FMakeConnectInScript;
    property SkipStatement: Boolean read FSkipStatement write FSkipStatement;
    property Paused: Boolean read FPaused write FPaused;
    property Defines: TStrings read FDefines write SetDefines;
  published
    property Script: TStrings read FScript write SetScript;
    property Database: TFIBDatabase read FDatabase write SetDatabase;
    property Transaction: TFIBTransaction read FExternalTransaction write SetTransaction;
    property OnExecuteError: TFIBScriptExecErrorEvent read FOnExecuteError write FOnExecuteError;
    property AutoDDL: Boolean read FAutoDDL write FAutoDDL default True;
    property BeforeStatementExecute: TFIBStatementExecuteEvent read FBeforeStatementExecute write FBeforeStatementExecute;
    property AfterStatementExecute: TFIBStatementExecuteEvent read FAfterStatementExecute write FAfterStatementExecute;
    property UseExecBlockForDML: Boolean read FUseExecBlockForDML write FUseExecBlockForDML default False;
  end;

function StatementTypeName(tn: TFIBStatementType): string;

// Possible Directives
// $IFDEF,$IFNDEF,$IFEXISTS,$IFNEXISTS,$IFNOTEXISTS,$ELSE,$ENDIF
// $IF,$DEFINE,$UNDEF
const
  dIfDef       = '{$IFDEF';
  dIfNDef      = '{$IFNDEF';
  dIf          = '{$IF';
  dIfExists    = '{$IFEXISTS';
  dIfNExists   = '{$IFNEXISTS';
  dIfNotExists = '{$IFNOTEXISTS';
  dElse        = '{$ELSE';
  dEndIf       = '{$ENDIF';
  dExecBlock   = '{$EXECUTE_BLOCK';
  dDefine      = '{$DEFINE';
  dUnDefine    = '{$UNDEF';

  dSetVar = '{$SET';

  // predefined defnames
const
  srvIsFirebird = 'IS_FIREBIRD';
  // predefined defVARS
  srvMajorVer       = 'SERVER_MAJOR_VER';
  srvMinorVer       = 'SERVER_MINOR_VER';
  dbODSMajorVersion = 'ODS_MAJOR_VER';
  dbODSMinorVersion = 'ODS_MINOR_VER';

type
  // Deprecated names of the types renamed in 8.0.0
  TStmtType = TFIBStatementType deprecated 'Use TFIBStatementType';
  TObjectType = TFIBScriptObjectType deprecated 'Use TFIBScriptObjectType';
  TStmtCoord = TFIBStatementCoord deprecated 'Use TFIBStatementCoord';
  PStmtCoord = PFIBStatementCoord deprecated 'Use PFIBStatementCoord';
  TStatementDesc = TFIBStatementDesc deprecated 'Use TFIBStatementDesc';
  PStatementDesc = PFIBStatementDesc deprecated 'Use PFIBStatementDesc';
  TScriptMap = TFIBScriptMap deprecated 'Use TFIBScriptMap';
  TOnParseStmt = TFIBParseStatementEvent deprecated 'Use TFIBParseStatementEvent';
  TDirectiveState = TFIBDirectiveState deprecated 'Use TFIBDirectiveState';
  TDirectiveDesc = TFIBDirectiveDesc deprecated 'Use TFIBDirectiveDesc';
  PDirectiveDesc = PFIBDirectiveDesc deprecated 'Use PFIBDirectiveDesc';
  TDirectivesMap = TFIBDirectivesMap deprecated 'Use TFIBDirectivesMap';
  PDirectivesMap = PFIBDirectivesMap deprecated 'Use PFIBDirectivesMap';
  TParseDisposition = TFIBParseDisposition deprecated 'Use TFIBParseDisposition';
  TScriptKeyword = TFIBScriptKeyword deprecated 'Use TFIBScriptKeyword';
  TOnStatementExecute = TFIBStatementExecuteEvent deprecated 'Use TFIBStatementExecuteEvent';
  TOnSQLScriptExecError = TFIBScriptExecErrorEvent deprecated 'Use TFIBScriptExecErrorEvent';
  TDynStringArray = TFIBAnsiStringArray deprecated 'Use TFIBAnsiStringArray';
  TParserState = TFIBScriptParserState deprecated 'Use TFIBScriptParserState';

implementation

uses
  StrUtil, SqlTxtRtns, StdFuncs, IB_Intf, FIBCharSets;
{ TFIBScripter }

procedure RaiseParserDirectiveError(const DirName: string; Line: Integer);
begin
  raise Exception.Create('Parse script error.' + sLineBreak + 'Can''t resolve directive  "' + DirName + '"' + sLineBreak + 'Line ' +
    IntToStr(Line));
end;

procedure RaiseInvalidStatement(Line: Integer; StmtTxt: TStrings);
var
  S: string;
begin
  S := 'Parse script error.' + sLineBreak + 'Invalid statement' + sLineBreak + 'Line ' + IntToStr(Line);
  if Assigned(StmtTxt) then
    S := S + sLineBreak + TrimRight(StmtTxt.Text);
  raise Exception.Create(S);
end;

function StatementTypeName(tn: TFIBStatementType): string;
begin
  case tn of
    sUnknown: Result := 'Unknown';
    sInvalid: Result := 'Invalid';
    sDML: Result := 'DML';
    sConnect: Result := 'Connect';
    sDisconnect: Result := 'Disconnect';
    sReconnect: Result := 'Reconnect';
    sCreateDatabase: Result := 'Create database';
    sDropDatabase: Result := 'Drop database';
    sCommit: Result := 'Commit';
    sRollBack: Result := 'Rollback';
    sCreate: Result := 'Create ';
    sAlter: Result := 'Alter ';
    sRecreate: Result := 'Recreate ';
    sDrop: Result := 'Drop ';
    sSet: Result := 'Set ';
    sSetGenerator: Result := 'Set generator';
    sSetStatistics: Result := 'Set statistics';
    sSetSession: Result := 'Set session';
    sDescribe: Result := 'Describe ';
    sDeclare: Result := 'Declare ';
    sComment: Result := 'Comment ';
    sGrant: Result := 'Grant ';
    sRunFromFile: Result := 'Run from file ';
    sInsert, sReinsert: Result := 'DML'
  else
    Result := 'Unknown';
  end

end;

function StmtCoord(X, Y: Integer): TFIBStatementCoord; inline;
begin
  Result.X := X;
  Result.Y := Y;
end;

function IsClause(const EtalonClause: string; const Source: string; Position: Integer): Boolean;
// EtalonClause must be in UpperCase
var
  LenEtalon: Integer;
begin
  Result := IsKeywordAt(EtalonClause, Source, Position);
  LenEtalon := Length(EtalonClause);
  if Result and (Length(Source) - Position >= LenEtalon) then
    Result := CharInSet(Source[Position + LenEtalon], [' ', #13, #9, #10, '/', '-', ';', '^', ',', '}'])
end;

function StrIsIfDirective(const CheckStr: string; X: Integer): Boolean;
begin
  Result := IsClause(dIfDef, CheckStr, X) or IsClause(dIfNDef, CheckStr, X) or
    IsClause(dIf, CheckStr, X) or IsClause(dIfExists, CheckStr, X) or
    IsClause(dIfNExists, CheckStr, X) or IsClause(dIfNotExists, CheckStr, X)

end;

procedure TFIBScripter.ClearPrepared;
begin
  SetLength(FScriptMap, 0);
  FPrepared := False;
end;

procedure TFIBScripter.CopyFragment(BegPos, EndPos: TFIBStatementCoord; Dest: TStrings);
begin
  FParser.CopyFragment(BegPos, EndPos, Dest);
end;

constructor TFIBScripter.Create(AOwner: TComponent);
begin
  inherited;
  FScript := TStringList.Create;
  TStringList(FScript).OnChanging := DoOnChangeScript;
  FParser := TFIBScriptParser.Create;

  FDefines := TStringList.Create;
  FDirectiveConsts := TStringList.Create;
  FExecBlockStatement := TStringList.Create;
  FTransaction := TFIBTransaction.Create(Self);
  FQuery := TFIBQuery.Create(Self);
  FQuery.Transaction := FTransaction;
  FSQLDialect := 3;
  FAutoDDL := True;
end;

procedure TFIBScripter.CreateInternalDatabase;
begin
  if not Assigned(FDatabase) then
  begin
    Database := TFIBDatabase.Create(Self);
    FInternalDatabase := True
  end
end;

destructor TFIBScripter.Destroy;
begin
  FParser.Free;
  FScript.Free;
  FDefines.Free;
  FDirectiveConsts.Free;
  SetLength(FScriptMap, 0);
  FExecBlockStatement.Free;
  if Assigned(FBlobFileStream) then
    FBlobFileStream.Free;
  inherited;
end;

procedure TFIBScripter.DoOnChangeScript(Sender: TObject);
begin
  ClearPrepared
end;

procedure TFIBScripter.DoReconnect;
begin
  if Assigned(FDatabase) then
  begin
    if GetTransaction.InTransaction then
      GetTransaction.Commit;
    FDatabase.Connected := False;
    FDatabase.Connected := True
  end;
end;

function TFIBScripter.CalcIF(Condition: TStrings): TFIBDirectiveState;
type
  TState = (sConstName, sOperator, sValue);
var
  i, L: Integer;
  tmpStr: string;

  cName: string;
  cOper: string;
  cValue: string;
  Value: string;

  cValueF: Double;
  ValueF: Double;

  Expr: string;
  State: TState;
begin
  // only simple expressions
  Result := dsUnknown;
  tmpStr := Condition[0];
  L := Length(tmpStr);
  i := 3;
  while i <= L do
  begin
    if CharInSet(tmpStr[i], [' ', #9, #13, #10]) then
      Break;
    Inc(i)
  end;
  tmpStr := Trim(Copy(Condition.Text, i, MaxInt));
  SetLength(tmpStr, Length(tmpStr) - 1);
  Expr := Trim(tmpStr);
  if Length(Expr) = 0 then
    Exit;

  i := 1;
  State := sConstName;
  cOper := '';
  cValue := '';
  while i <= Length(Expr) do
  begin
    case State of
      sConstName:
        if CharInSet(Expr[i], [' ', #9, #10, #13]) then
        begin
          cName := UpperCase(Copy(Expr, 1, i - 1));
          while (i <= Length(Expr)) and CharInSet(Expr[i], [' ', #9, #10, #13]) do
            Inc(i);
          if (i > Length(Expr)) or not CharInSet(Expr[i], ['=', '>', '<']) then
            raise Exception.Create('Parse script error.' + sLineBreak + 'Can''t resolve condition  "$IF"' + sLineBreak + Expr);
          State := sOperator;
        end
        else if CharInSet(Expr[i], ['=', '>', '<']) then
        begin
          cName := UpperCase(Copy(Expr, 1, i - 1));
          State := sOperator;
        end
        else
          Inc(i);
      sOperator:
        if CharInSet(Expr[i], ['=', '>', '<']) then
        begin
          cOper := cOper + Expr[i];
          Inc(i)
        end
        else
          State := sValue;
      sValue:
        begin
          while (i <= Length(Expr)) and CharInSet(Expr[i], [' ', #9, #10, #13]) do
            Inc(i);
          cValue := Copy(Expr, i, MaxInt);
          Break;
        end;
    end;
  end;
  //
  Value := FDirectiveConsts.Values[cName];
  if Trim(Value) = '' then
    raise Exception.Create('Parse script error.' + sLineBreak + 'Constant don''t exists' + sLineBreak + cName);

  if cOper = '=' then
  begin
    if Value = cValue then
      Result := dsTrue
    else
      Result := dsFalse
  end
  else if cOper = '<>' then
  begin
    if Value <> cValue then
      Result := dsTrue
    else
      Result := dsFalse
  end
  else
  begin
    // May be floats
    Value := StringReplace(Value, '.',
      {$IFDEF C24}FormatSettings.{$ENDIF} DecimalSeparator, []);
    Value := StringReplace(Value, ',',
      {$IFDEF C24}FormatSettings.{$ENDIF} DecimalSeparator, []);
    cValue := StringReplace(cValue, '.',
      {$IFDEF C24}FormatSettings.{$ENDIF} DecimalSeparator, []);
    cValue := StringReplace(cValue, ',',
      {$IFDEF C24}FormatSettings.{$ENDIF} DecimalSeparator, []);

    cValueF := StrToFloat(cValue);
    ValueF := StrToFloat(Value);
    case cOper[1] of

      '>':
        if ValueF < cValueF then
          Result := dsFalse
        else if ValueF > cValueF then
          Result := dsTrue
        else if cOper = '>=' then
          Result := dsTrue
        else
          Result := dsFalse;
      '<':
        if ValueF > cValueF then
          Result := dsFalse
        else if ValueF < cValueF then
          Result := dsTrue
        else if cOper = '<=' then
          Result := dsTrue
        else
          Result := dsFalse;
    end;
  end;
end;

const
  QRYDomainExist = 'select RDB$FIELD_TYPE    FROM RDB$FIELDS    WHERE RDB$FIELD_NAME=:NAME';

  QRYTableExist = 'SELECT REL.RDB$RELATION_NAME FROM RDB$RELATIONS REL WHERE REL.RDB$RELATION_NAME=:NAME  and REL.RDB$VIEW_BLR is null';

  QRYViewExist = 'SELECT REL.RDB$RELATION_NAME FROM RDB$RELATIONS REL WHERE REL.RDB$RELATION_NAME=:NAME  and NOT REL.RDB$VIEW_BLR is null';
  QRYTriggerExist = 'SELECT T.RDB$TRIGGER_NAME    from RDB$TRIGGERS T    WHERE T.RDB$TRIGGER_NAME=:NAME';

  QRYProcedureExist = 'SELECT RDB$PROCEDURE_NAME FROM  RDB$PROCEDURES WHERE RDB$PROCEDURE_NAME=:NAME';
  QRYPackageExist   = 'SELECT RDB$PACKAGE_NAME FROM  RDB$PACKAGES WHERE RDB$PACKAGE_NAME=:NAME';

  QRYExceptionExist = 'SELECT RDB$EXCEPTION_NAME FROM RDB$EXCEPTIONS WHERE  RDB$EXCEPTION_NAME=:NAME';
  QRYGeneratorExist = 'SELECT RDB$GENERATOR_NAME FROM RDB$GENERATORS WHERE RDB$GENERATOR_NAME=:NAME ';
  QRYUdfExist       = 'SELECT RDB$FUNCTION_NAME FROM RDB$FUNCTIONS WHERE  RDB$FUNCTION_NAME=:NAME';
  QRYFunctionExist  = 'SELECT RDB$FUNCTION_NAME FROM RDB$FUNCTIONS WHERE  RDB$FUNCTION_NAME=:NAME';

  QRYRoleExist = 'SELECT RDB$ROLE_NAME FROM RDB$ROLES WHERE RDB$ROLE_NAME =:NAME ';

function TFIBScripter.CalcExists(Condition: TStrings): TFIBDirectiveState;
var
  CheckExists: Boolean;
  i, L: Integer;
  tmpStr: string;
  chObjectType: TFIBScriptObjectType;
  chObjName: string;
  chQryTxt: string;
begin
  Result := dsUnknown;
  tmpStr := Condition[0];
  CheckExists := IsClause(dIfExists, tmpStr, 1);
  if not CheckExists and not IsClause(dIfNExists, tmpStr, 1) and not IsClause(dIfNotExists, tmpStr, 1) then
    Exit;
  L := Length(tmpStr);
  i := 10;
  while i <= L do
  begin
    if CharInSet(tmpStr[i], [' ', #9, #13, #10]) then
      Break;
    Inc(i)
  end;
  tmpStr := Trim(Copy(Condition.Text, i, MaxInt));
  if Length(tmpStr) = 0 then
    Exit;

  chObjectType := otNone;
  case tmpStr[1] of
    'D', 'd':
      if IsClause('DOMAIN', tmpStr, 1) then
      begin
        chObjectType := otDomain;
        chQryTxt := QRYDomainExist;
        L := 7
      end;
    'E', 'e':
      if IsClause('EXCEPTION', tmpStr, 1) then
      begin
        chObjectType := otException;
        chQryTxt := QRYExceptionExist;
        L := 10
      end;
    'F', 'f':
      if IsClause('FUNCTION', tmpStr, 1) then
      begin
        chObjectType := otFunction;
        chQryTxt := QRYFunctionExist;
        L := 9
      end;

    'G', 'g':
      if IsClause('GENERATOR', tmpStr, 1) then
      begin
        chObjectType := otGenerator;
        chQryTxt := QRYGeneratorExist;
        L := 10
      end;
    'P', 'p':
      if IsClause('PROCEDURE', tmpStr, 1) then
      begin
        chObjectType := otProcedure;
        chQryTxt := QRYProcedureExist;
        L := 10
      end
      else if IsClause('PACKAGE', tmpStr, 1) then
      begin
        chObjectType := otPackage;
        chQryTxt := QRYPackageExist;
        L := 8
      end;
    'R', 'r':
      if IsClause('ROLE', tmpStr, 1) then
      begin
        chObjectType := otRole;
        chQryTxt := QRYRoleExist;
        L := 5
      end;

    'T', 't':
      if IsClause('TABLE', tmpStr, 1) then
      begin
        chObjectType := otTable;
        chQryTxt := QRYTableExist;
        L := 6
      end
      else if IsClause('TRIGGER', tmpStr, 1) then
      begin
        chObjectType := otTrigger;
        chQryTxt := QRYTriggerExist;
        L := 8
      end;
    'U', 'u':
      if IsClause('UDF', tmpStr, 1) then
      begin
        chObjectType := otUDF;
        chQryTxt := QRYUdfExist;
        L := 4
      end;
    'V', 'v':
      if IsClause('VIEW', tmpStr, 1) then
      begin
        chObjectType := otView;
        chQryTxt := QRYViewExist;
        L := 5
      end;
  end; // case
  if chObjectType <> otNone then
  begin
    chObjName := Trim(Copy(tmpStr, L, MaxInt));
    SetLength(chObjName, Length(chObjName) - 1);
    chObjName := Trim(chObjName);
    if (chObjName <> '') and (chObjName[1] = '"') then
      chObjName := Copy(chObjName, 2, Length(chObjName) - 2)
    else
      chObjName := UpperCase(chObjName);

    FQuery.SQL.Text := chQryTxt;

    if Assigned(FDatabase) and FDatabase.Connected then
    begin
      FQuery.Params[0].AsString := chObjName;
      if not GetTransaction.InTransaction then
        GetTransaction.StartTransaction;
      FQuery.Close;
      try
        FQuery.ExecQuery;
        if FQuery.Eof xor CheckExists then
          Result := dsTrue
        else
          Result := dsFalse
      finally
        FQuery.Close;
      end;
    end;
  end
  else if IsClause('SELECT', tmpStr, 1) then
  begin
    chQryTxt := tmpStr;
    SetLength(chQryTxt, Length(chQryTxt) - 1);

    if Assigned(FDatabase) and FDatabase.Connected then
    begin
      FQuery.SQL.Text := chQryTxt;
      if not GetTransaction.InTransaction then
        GetTransaction.StartTransaction;
      FQuery.Close;
      try
        FQuery.ExecQuery;
        if FQuery.Eof xor CheckExists then
          Result := dsTrue
        else
          Result := dsFalse
      finally
        FQuery.Close;
      end;
    end;
  end;

end;

function TFIBScripter.CalcDirective(Directive: TFIBDirectiveDesc): TFIBDirectiveState;
var
  TmpSQL: TStrings;
  S: string;
begin
  Result := dsUnknown;
  TmpSQL := TStringList.Create;
  try
    TmpSQL.Text := Directive.dCondition;
    if TmpSQL.Count > 0 then
      if IsClause(dIfDef, TmpSQL[0], 1) then
      begin
        S := Trim(Copy(TmpSQL.Text, 8, MaxInt));
        SetLength(S, Length(S) - 1);
        S := Trim(S);
        if FDefines.IndexOf(UpperCase(S)) >= 0 then
          Result := dsTrue
        else
          Result := dsFalse
      end
      else if IsClause(dIfNDef, TmpSQL[0], 1) then
      begin
        S := Trim(Copy(TmpSQL.Text, 9, MaxInt));
        SetLength(S, Length(S) - 1);
        S := Trim(S);
        if FDefines.IndexOf(UpperCase(S)) >= 0 then
          Result := dsFalse
        else
          Result := dsTrue
      end
      else if IsClause(dIf, TmpSQL[0], 1) then
      begin
        Result := CalcIF(TmpSQL)
      end
      else if IsClause(dIfExists, TmpSQL[0], 1) then
      begin
        Result := CalcExists(TmpSQL)
      end
      else if IsClause(dIfNExists, TmpSQL[0], 1) or IsClause(dIfNotExists, TmpSQL[0], 1) then
      begin
        Result := CalcExists(TmpSQL)
      end
      else
        Result := dsFalse
  finally
    TmpSQL.Free
  end;
end;

function TFIBScripter.DirectiveAllows(DirNum: Integer; InElse: Boolean): Boolean;
var
  D: PFIBDirectiveDesc;
begin
  if (DirNum < 0) or (DirNum >= FParser.FDirectiveCount) then
  begin
    Result := True;
    Exit;
  end;
  D := @FParser.FDirectives[DirNum];
  // the condition is evaluated only when the owner directives allow its branch
  Result := DirectiveAllows(D.OwnerDirectiveNum, D.OwnerDirectiveElse);
  if not Result then
    Exit;
  if D.dState = dsUnknown then
    D.dState := CalcDirective(D^);
  Result := (D.dState = dsTrue) xor InElse;
end;

// False when there is no OnExecuteError handler and the error must propagate
function TFIBScripter.HandleExecuteError(E: EFIBError; const Stmt: TFIBStatementDesc;
  StmtNo: Integer; SQLText: TStrings): Boolean;
var
  DoRollBack: Boolean;
begin
  Result := Assigned(FOnExecuteError);
  if not Result then
    Exit;
  FPaused := True;
  DoRollBack := True;
  FOnExecuteError(Self, StmtNo + 1, Stmt.smdBegin.Y + 1, SQLText, E.SQLCode, E.Message, DoRollBack, FPaused);
  if DoRollBack and GetTransaction.InTransaction then
    GetTransaction.Rollback;
end;

// Runs FQuery.SQL
procedure TFIBScripter.ApplyCommand(const Stmt: TFIBStatementDesc; StmtNo, Line: Integer; StmtTxt, SQLText: TStrings);
begin
  try
    if not GetTransaction.InTransaction then
      GetTransaction.StartTransaction;
    if (Length(FBlobFile) > 0) and (FQuery.ParamCount > 0) then
      TryFillBlobParams;
    FQuery.ExecQuery;
    if Assigned(FInternalOnStatementExec) then
      FInternalOnStatementExec(Line, StmtNo + 1);
    if Assigned(FAfterStatementExecute) then
      FAfterStatementExecute(Self, Line, StmtNo + 1, Stmt, StmtTxt);
    if FAutoDDL and (FQuery.SQLKind = skDDL) then
      FQuery.Transaction.Commit;
  except
    on E: EFIBError do
      if not HandleExecuteError(E, Stmt, StmtNo, SQLText) then
        raise;
  end;
end;

// False when the pending EXECUTE BLOCK, run first, paused the run, so the statement did not run
function TFIBScripter.ExecuteStatement(StmtTxt: TStrings;
  Stmt: PFIBStatementDesc; StmtNo: Integer; TmpSQL: TStrings = nil;
  LineInFile: Integer = -1): Boolean;

  // An object name of DESCRIBE: quoted for COMMENT ON, or as stored in the system tables
  function DescribeName(const TokenPos: TFIBStatementCoord; ForComment: Boolean): string;
  var
    Quoted: Boolean;
  begin
    Quoted := FParser.Line(TokenPos.Y)[TokenPos.X] = '"';
    Result := FParser.GetToken(TokenPos);
    if Quoted then
    begin
      if ForComment then
        Result := '"' + Result + '"';
    end
    else if not ForComment then
      Result := AnsiUpperCase(Result);
  end;

var
  Token, NameToken, OwnerToken: TFIBStatementCoord;
  UseComment: Boolean;
  tmpStr, tmpStr1: string;
  IsInternalTmpSQL: Boolean;
  CanGroup: Boolean;
  WasPaused: Boolean;
  Line: Integer;
  i: Integer;
begin
  Result := True;
  if Stmt <> nil then
  begin
    if FQuery.Open then
      FQuery.Close;
    if TmpSQL = nil then
    begin
      IsInternalTmpSQL := True;
      TmpSQL := TStringList.Create;
    end
    else
      IsInternalTmpSQL := False;
    try
      SkipStatement := (Stmt.DirectiveNum >= 0) and not DirectiveAllows(Stmt.DirectiveNum, Stmt.DirectiveElse);
      if SkipStatement then
        Exit;
      CanGroup := CanGroupInExecuteBlock(Stmt^);
      if not CanGroup and not FlushExecBlock then
      begin
        Result := False;
        Exit;
      end;
      if LineInFile = -1 then
        Line := Stmt.smdBegin.Y + 1
      else
        Line := LineInFile;
      if Assigned(FBeforeStatementExecute) then
        FBeforeStatementExecute(Self, Line, StmtNo + 1, Stmt^, StmtTxt);
      if SkipStatement then
        Exit;
      if Stmt.smtType = sInvalid then
        RaiseInvalidStatement(Line, StmtTxt);

      case Stmt.smtType of
        sCreateDatabase:
          begin
            CreateInternalDatabase;
            Token := FParser.NextTokenPos(Stmt.smdBegin, Stmt.smdEnd);
            Token := FParser.NextTokenPos(Token, Stmt.smdEnd);
            if FDatabase.Connected then
              FDatabase.Close;

            FDatabase.DBName := FParser.GetToken(Token);
            Token := FParser.NextTokenPos(Token, Stmt.smdEnd);
            CopyFragment(Token, Stmt.smdEnd, FDatabase.DBParams);
            FDBParamsFromCreate := True;
            FDatabase.SQLDialect := FSQLDialect;
            if FLibraryName <> '' then
              FDatabase.LibraryName := FLibraryName;
            try
              FDatabase.CreateDatabase;
              PreparePreDefines;
              if FDatabase.NeedUTFEncodeDDL then
              begin
                if FDatabase.Capabilities.AttachmentCharSetID = 0 then
                begin
                  FDatabase.Connected := False;
                  SetConnectParams(Token, Stmt.smdEnd);
                  FDatabase.DBParams.Add('force_write=0');
                  FNeedRestoreForceWrite := True;
                  FDatabase.Connected := True;
                end
              end;
            except
              on E: EFIBError do
                if not HandleExecuteError(E, Stmt^, StmtNo, TmpSQL) then
                  raise;
            end
          end;
        sDropDatabase:
          begin
            CreateInternalDatabase;
            Token := FParser.NextTokenPos(Stmt.smdBegin, Stmt.smdEnd);
            Token := FParser.NextTokenPos(Token, Stmt.smdEnd);
            if FDatabase.Connected then
              FDatabase.Close;
            if FLibraryName <> '' then
              FDatabase.LibraryName := FLibraryName;
            FDatabase.DBName := FParser.GetToken(Token);
            Token := FParser.NextTokenPos(Token, Stmt.smdEnd);
            tmpStr := FParser.GetToken(Token);
            if IsClause('USER', tmpStr, 1) then
            begin
              Token := FParser.NextTokenPos(Token, Stmt.smdEnd);
              tmpStr := FParser.GetToken(Token);
              FDatabase.ConnectParams.UserName := tmpStr;
            end
            else if IsClause('PASSWORD', tmpStr, 1) then
            begin
              Token := FParser.NextTokenPos(Token, Stmt.smdEnd);
              tmpStr := FParser.GetToken(Token);
              FDatabase.ConnectParams.Password := tmpStr;
            end;

            Token := FParser.NextTokenPos(Token, Stmt.smdEnd);
            tmpStr := FParser.GetToken(Token);
            if IsClause('USER', tmpStr, 1) then
            begin
              Token := FParser.NextTokenPos(Token, Stmt.smdEnd);
              tmpStr := FParser.GetToken(Token);
              FDatabase.ConnectParams.UserName := tmpStr;
            end
            else if IsClause('PASSWORD', tmpStr, 1) then
            begin
              Token := FParser.NextTokenPos(Token, Stmt.smdEnd);
              tmpStr := FParser.GetToken(Token);
              FDatabase.ConnectParams.Password := tmpStr;
            end;

            try
              FDatabase.Connected := True;
              FDatabase.DropDatabase;
            except
              on E: EFIBError do
                if not HandleExecuteError(E, Stmt^, StmtNo, TmpSQL) then
                  raise;
            end
          end;
        sDisconnect:
          if Assigned(FDatabase) then
            FDatabase.Connected := False;
        sConnect:
          begin
            CreateInternalDatabase;
            try
              if FDatabase.Connected then
                FDatabase.Close;
              Token := FParser.NextTokenPos(Stmt.smdBegin, Stmt.smdEnd);
              FDatabase.DBName := FParser.GetToken(Token);
              Token := FParser.NextTokenPos(Token, Stmt.smdEnd);
              // An assigned database keeps its DBParams, CONNECT sets only its own clauses
              SetConnectParams(Token, Stmt.smdEnd, not FInternalDatabase and not FDBParamsFromCreate);
              FDBParamsFromCreate := False;
              FDatabase.Connected := True;

              PreparePreDefines;
            except
              on E: EFIBError do
                if not HandleExecuteError(E, Stmt^, StmtNo, TmpSQL) then
                  raise;
            end
          end;
        sCommit:
          if GetTransaction.InTransaction then
            try
              GetTransaction.Commit;
            except
              on E: EFIBError do
                if not HandleExecuteError(E, Stmt^, StmtNo, TmpSQL) then
                  raise;
            end;
        sDirective:
          begin
            if TmpSQL.Count > 0 then
              if IsClause(dExecBlock, TmpSQL[0], 1) then
              begin
                tmpStr := Trim(Copy(TmpSQL.Text, 16, MaxInt));
                SetLength(tmpStr, Length(tmpStr) - 1);
                tmpStr := UpperCase(Trim(tmpStr));
                if IsClause('ON', tmpStr, 1) then
                  FUseExecBlockForDML := True
                else if IsClause('OFF', tmpStr, 1) then
                  FUseExecBlockForDML := False
                else
                  RaiseParserDirectiveError(dExecBlock, Line);
              end
              else if IsClause(dDefine, TmpSQL[0], 1) then
              begin
                tmpStr := Trim(Copy(TmpSQL.Text, 10, MaxInt));
                SetLength(tmpStr, Length(tmpStr) - 1);
                tmpStr := UpperCase(Trim(tmpStr));
                if FDefines.IndexOf(tmpStr) < 0 then
                  FDefines.Add(UpperCase(tmpStr))
              end
              else if IsClause(dUnDefine, TmpSQL[0], 1) then
              begin
                tmpStr := Trim(Copy(TmpSQL.Text, 8, MaxInt));
                SetLength(tmpStr, Length(tmpStr) - 1);
                tmpStr := UpperCase(Trim(tmpStr));
                i := FDefines.IndexOf(tmpStr);
                if i >= 0 then
                  FDefines.Delete(i);
              end
              else if IsClause(dSetVar, TmpSQL[0], 1) then
              begin
                tmpStr := Trim(Copy(TmpSQL.Text, 6, MaxInt));
                SetLength(tmpStr, Length(tmpStr) - 1);
                i := Pos('=', tmpStr);
                if i > 0 then
                begin
                  tmpStr1 := Trim(Copy(tmpStr, i + 1, MaxInt));
                  SetLength(tmpStr, i - 1);
                  tmpStr := Trim(UpperCase(tmpStr));
                  if (Length(tmpStr) > 0) and (Length(tmpStr1) > 0) then
                    FDirectiveConsts.Values[tmpStr] := tmpStr1;
                end
              end
              else
                raise Exception.Create('Unknown directive :' + sLineBreak + 'Line ' +
                  IntToStr(Line) + sLineBreak + TmpSQL.Text);

          end;
        sRollBack:
          if GetTransaction.InTransaction then
            GetTransaction.Rollback;
        sSet:
          begin
            Token := FParser.NextTokenPos(Stmt.smdBegin, Stmt.smdEnd);
            if Token.X > 0 then
            begin
              tmpStr := FParser.GetToken(Token);
              if IsClause('AUTODDL', tmpStr, 1) then
              begin
                Token := FParser.NextTokenPos(Token, Stmt.smdEnd);
                if (Token.X > 0) then
                begin
                  tmpStr := FParser.GetToken(Token);
                  if IsClause('ON', tmpStr, 1) then
                    FAutoDDL := True
                  else if IsClause('OFF', tmpStr, 1) then
                    FAutoDDL := False
                end
              end
              else if IsClause('SQL', tmpStr, 1) then
              begin
                Token := FParser.NextTokenPos(Token, Stmt.smdEnd);
                if (Token.X > 0) then
                begin
                  tmpStr := FParser.GetToken(Token);
                  if IsClause('DIALECT', tmpStr, 1) then
                  begin
                    Token := FParser.NextTokenPos(Token, Stmt.smdEnd);
                    if (Token.X > 0) then
                    begin
                      tmpStr := FParser.GetToken(Token);
                      FSQLDialect := StrToInt(tmpStr)
                    end;
                  end;
                end;
              end
              else if IsClause('NAMES', tmpStr, 1) then
              begin
                Token := FParser.NextTokenPos(Token, Stmt.smdEnd);
                if (Token.X > 0) then
                begin
                  FCharSet := FParser.GetToken(Token);
                end
              end
              else // CLIENTLIB
                if IsClause('CLIENTLIB', tmpStr, 1) then
                begin
                  Token := FParser.NextTokenPos(Token, Stmt.smdEnd);
                  if Token.X <> 0 then
                  begin
                    FLibraryName := FParser.GetToken(Token);
                  end
                end
                else if IsClause('BLOBFILE', tmpStr, 1) then
                begin
                  Token := FParser.NextTokenPos(Token, Stmt.smdEnd);
                  if (Token.X > 0) then
                  begin
                    if Assigned(FBlobFileStream) then
                    begin
                      FBlobFileStream.Free;
                      FBlobFileStream := nil;
                    end;
                    FBlobFile := FParser.GetToken(Token);
                  end
                end;
            end;
          end;
        sReconnect:
          begin
            DoReconnect;
          end;
        sDescribe:
          begin
            Token := FParser.NextTokenPos(Stmt.smdBegin, Stmt.smdEnd);
            if (Token.X > 0) then
            begin
              TmpSQL.Clear;
              case Stmt.objType of
                otDomain:
                  begin
                    tmpStr1 := 'DOMAIN';
                    TmpSQL.Add
                      ('UPDATE RDB$FIELDS SET RDB$DESCRIPTION = :DESCR WHERE (RDB$FIELD_NAME = :FIELD)');
                  end;
                otView, otTable:
                  begin
                    if Stmt.objType = otView then
                      tmpStr1 := 'VIEW'
                    else
                      tmpStr1 := 'TABLE';
                    TmpSQL.Add
                      ('UPDATE RDB$RELATIONS SET RDB$DESCRIPTION = :DESCR ' + 'WHERE RDB$RELATION_NAME = :TABNAME');
                  end;
                otTrigger:
                  begin
                    tmpStr1 := 'TRIGGER';
                    TmpSQL.Add
                      ('UPDATE RDB$TRIGGERS SET RDB$DESCRIPTION = :DESCR WHERE (RDB$TRIGGER_NAME = :TR_NAME)');
                  end;
                otField:
                  begin
                    tmpStr1 := 'COLUMN';
                    TmpSQL.Add
                      ('UPDATE RDB$RELATION_FIELDS SET RDB$DESCRIPTION = :DESCR ' +
                        'WHERE (RDB$RELATION_NAME = :TABNAME) and (RDB$FIELD_NAME = :FIELD)');
                  end;
                otParameter:
                  begin
                    tmpStr1 := 'PARAMETER';
                    TmpSQL.Add
                      ('UPDATE RDB$PROCEDURE_PARAMETERS SET RDB$DESCRIPTION = :DESCR ' +
                        'WHERE (RDB$PROCEDURE_NAME = :PROCNAME) and(RDB$PARAMETER_NAME = :FIELD)');
                  end;
                otProcedure:
                  begin
                    tmpStr1 := 'PROCEDURE';
                    TmpSQL.Add
                      ('UPDATE RDB$PROCEDURES SET RDB$DESCRIPTION = :DESCR ' + 'WHERE (RDB$PROCEDURE_NAME = :PROCNAME)');
                  end;
                otException:
                  begin
                    tmpStr1 := 'EXCEPTION';
                    TmpSQL.Add
                      ('UPDATE RDB$EXCEPTIONS SET RDB$DESCRIPTION = :DESCR ' + 'WHERE (RDB$EXCEPTION_NAME = :EXC_NAME)');
                  end;
                otFunction, otUDF:
                  begin
                    if Stmt.objType = otUDF then
                      tmpStr1 := 'EXTERNAL FUNCTION'
                    else
                      tmpStr1 := 'FUNCTION';
                    TmpSQL.Add
                      ('update RDB$FUNCTIONS set RDB$DESCRIPTION = ?DESC where (RDB$FUNCTION_NAME = ?FUNC_NAME)');
                  end;
                otGenerator:
                  begin
                    tmpStr1 := 'GENERATOR';
                    TmpSQL.Add
                      ('update RDB$GENERATORS SET RDB$DESCRIPTION = ?DESC where (RDB$GENERATOR_NAME = ?GEN_NAME)');
                  end;
                otPackage:
                  begin
                    tmpStr1 := 'PACKAGE';
                    TmpSQL.Add('UPDATE RDB$PACKAGES SET RDB$DESCRIPTION = :DESCR ' +
                      'WHERE (RDB$PACKAGE_NAME = :PACKAGENAME)');
                  end;
              else
                tmpStr := FParser.GetToken(Token);
                raise Exception.Create('Unsupported DESCRIBE type ' + tmpStr)
                // mark as invalid later
              end;

              // DESCRIBE <type> <name> [<owner type> <owner name>] '<text>'
              Token := FParser.NextTokenPos(Token, Stmt.smdEnd);
              NameToken := Token;
              OwnerToken := Token;
              if Stmt.objType in [otField, otParameter] then
              begin
                Token := FParser.NextTokenPos(Token, Stmt.smdEnd);
                Token := FParser.NextTokenPos(Token, Stmt.smdEnd);
                OwnerToken := Token;
              end;
              Token := FParser.NextTokenPos(Token, Stmt.smdEnd);
              // system tables are read only in Firebird 3+, COMMENT ON exists since Firebird 2
              UseComment := Assigned(FDatabase) and FDatabase.Connected and FDatabase.IsFirebirdConnect;
              if UseComment then
              begin
                tmpStr := DescribeName(NameToken, True);
                if Stmt.objType in [otField, otParameter] then
                  tmpStr := DescribeName(OwnerToken, True) + '.' + tmpStr;
                tmpStr1 := 'COMMENT ON ' + tmpStr1 + ' ' + tmpStr + ' IS ';
              end
              else
              begin
                FQuery.SQL.Assign(TmpSQL);
                if Stmt.objType in [otField, otParameter] then
                  FQuery.Params[2].AsString := DescribeName(NameToken, False);
                FQuery.Params[1].AsString := DescribeName(OwnerToken, False);
              end;

              CopyFragment(Token, Stmt.smdEnd, TmpSQL);
              tmpStr := AnsiDequotedStr(TmpSQL.Text, '''');
              if UseComment then
                FQuery.SQL.Text := tmpStr1 + QuotedStr(tmpStr)
              else
                FQuery.Params[0].AsString := tmpStr;
              if not GetTransaction.InTransaction then
                GetTransaction.StartTransaction;
              FQuery.ExecQuery;
            end;
          end;
        sRunFromFile:
          begin
            Token := FParser.NextTokenPos(Stmt.smdBegin, Stmt.smdEnd);
            // FileName
            tmpStr := FParser.GetToken(Token); // FileName
            WasPaused := FPaused; // BeginRun of the file clears it
            ExecuteFromFile(tmpStr, FFileEncoding);
            FPaused := FPaused or WasPaused;
          end;
      else
        case Stmt.smtType of
          sInsert:
            begin
              FLastInsertStatement := TmpSQL.Text;
              FReinsertPrepared := False;
            end;
          sReinsert: TmpSQL.Text := PrepareReinsert(FLastInsertStatement, TmpSQL.Text);
        end;

        if CanGroup and (Length(FBlobFile) > 0) then
        begin
          FQuery.SQL := TmpSQL;
          CanGroup := FQuery.ParamCount = 0; // BLOB file parameters are filled per statement
        end;
        if CanGroup and AddStatementToExecuteBlock(Stmt^, StmtNo, Line, TmpSQL) then
          Exit;
        // the block is full, or the statement runs alone
        if not FlushExecBlock then
        begin
          Result := False;
          Exit;
        end;
        if CanGroup and AddStatementToExecuteBlock(Stmt^, StmtNo, Line, TmpSQL) then
          Exit;
        FQuery.SQL := TmpSQL;
        ApplyCommand(Stmt^, StmtNo, Line, StmtTxt, TmpSQL);
      end;
    finally
      if IsInternalTmpSQL then
        TmpSQL.Free
    end
  end;
end;

// Called in a try block with EndRun in finally, so FRunDepth stays balanced.
// A resumed run keeps the state set by the script (INSERT for REINSERT, dialect, names).
procedure TFIBScripter.BeginRun(Resume: Boolean);
begin
  FPaused := False;
  Inc(FRunDepth);
  if FRunDepth = 1 then
  begin
    RestartBlock;
    FStopStatementNo := 0;
    if not Resume then
    begin
      FLastInsertStatement := '';
      FReinsertPrepared := False;
      FSQLDialect := 3;
      FCharSet := '';
    end;
    PreparePreDefines;
  end;
end;

procedure TFIBScripter.EndRun;
begin
  Dec(FRunDepth);
  if FRunDepth > 0 then // a script run by INPUT goes on with the calling script
    Exit;

  if FNeedRestoreForceWrite and Assigned(FDatabase) and FDatabase.Connected then
  begin
    if GetTransaction.InTransaction then
      GetTransaction.Commit;
    FDatabase.Connected := False;
    FDatabase.DBParams.Values['force_write'] := '1';
    FDatabase.Connected := True;
  end;
  FNeedRestoreForceWrite := False;

  if FInternalDatabase then
  begin
    if GetTransaction.InTransaction then
      GetTransaction.Commit;
    Database := nil;
  end;

  if Assigned(FBlobFileStream) then
  begin
    FBlobFileStream.Free;
    FBlobFileStream := nil;
  end;
end;

// False when the run paused before the statement, see ExecuteStatement
function TFIBScripter.RunStatement(Stmt: PFIBStatementDesc; StmtNo: Integer; StmtTxt: TStrings): Boolean;
begin
  Result := True;
  case Stmt.smtType of
    sBatchStart:
      begin
        FInBatchCollect := True;
        SetLength(FBatchSQLs, 0);
      end;
    sBatchExecute:
      begin
        FInBatchCollect := False;
        if not GetTransaction.InTransaction then
          GetTransaction.StartTransaction;
        if Assigned(FBeforeStatementExecute) then
          FBeforeStatementExecute(Self, Stmt.smdBegin.Y + 1, StmtNo + 1, Stmt^, nil);
        raise Exception.Create('Batch execute support for IB2007 only');
      end;
  else
    if not FInBatchCollect then
      Result := ExecuteStatement(StmtTxt, Stmt, StmtNo, StmtTxt)
    else
    begin
      SetLength(FBatchSQLs, Length(FBatchSQLs) + 1);
      // as TFIBQuery encodes SQL text (InterBase 2007 only: the metadata code page is the same)
      FBatchSQLs[Length(FBatchSQLs) - 1] :=
        EncodeString(StmtTxt.Text, FQuery.Database.Capabilities.CodePage);
    end;
  end;
end;

// Runs the pending EXECUTE BLOCK; False when the block paused the run (the error handler
// left Stop as True, or an event handler of the block set Paused)
function TFIBScripter.FlushExecBlock: Boolean;
var
  WasPaused: Boolean;
begin
  Result := True;
  if FBlockStatementCount = 0 then
    Exit;
  WasPaused := FPaused; // set by an event handler before the block
  FPaused := False;
  FExecBlockStatement.Add('END');
  FQuery.SQL := FExecBlockStatement;
  RestartBlock;
  ApplyCommand(FBlockLastStmt, FBlockLastStmtNo, FBlockLastLine, FQuery.SQL, FQuery.SQL);
  Result := not FPaused;
  FPaused := FPaused or WasPaused;
end;

procedure TFIBScripter.ExecuteScript(FromStmt: Integer = 1);
var
  i: Integer;
  TmpSQL: TStrings;
begin
  if FromStmt < 1 then
    FromStmt := 1;
  if not FPrepared then
    Parse
  else if FromStmt = 1 then
  // conditions are evaluated again, a resumed run keeps them
    for i := 0 to FParser.FDirectiveCount - 1 do
      FParser.FDirectives[i].dState := dsUnknown;

  TmpSQL := TStringList.Create;
  try
    BeginRun(FromStmt > 1);
    i := FromStmt - 1;
    while not FPaused and (i < StatementsCount) do
      if RunStatement(GetStatement(i + 1, TmpSQL), i, TmpSQL) then
        Inc(i);
    // also after a pause: the statements of the block are before StopStatementNo
    if FRunDepth = 1 then
      FlushExecBlock;
    if FPaused then
      FStopStatementNo := i + 1;
  finally
    try
      EndRun;
    finally
      TmpSQL.Free;
    end;
  end;
end;

function TFIBScripter.GetStatement(StmtNo: Integer; Text: TStrings): PFIBStatementDesc;
begin
  if StmtNo > Length(FScriptMap) then
    raise Exception.Create('Statement #' + IntToStr(StmtNo) + ' don''t exist');
  Result := @FScriptMap[StmtNo - 1];
  CopyFragment(Result.smdBegin, Result.smdEnd, Text);
end;

procedure TFIBScripter.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  if Operation = opRemove then
  begin
    if AComponent = FDatabase then
      FDatabase := nil
    else if AComponent = FExternalTransaction then
      FExternalTransaction := nil;
  end;
end;

procedure TFIBScripter.Parse(Terminator: string = ';');
var
  Directives: TFIBDirectivesMap; // the parser keeps them for DirectiveAllows
begin
  FMakeConnectInScript := False;
  FHaveDMLStatements := False;
  FHaveUnknownStatements := False;
  FLibraryName := '';
  FParser.ParseScript(FScript, Terminator, FScriptMap, Directives);
  FPrepared := True;

  FMakeConnectInScript := FParser.FMakeConnectInScript;
  FHaveDMLStatements := FParser.FHaveDMLStatements;
  FHaveUnknownStatements := FParser.FHaveUnknownStatements;
end;

procedure TFIBScripter.SetDatabase(const Value: TFIBDatabase);
begin
  if GetTransaction.InTransaction then
    GetTransaction.Commit;

  if Assigned(FDatabase) then
    if FInternalDatabase and ((Value = nil) or (Value.Owner <> Self)) then
    // Old database -  InternalDatabase
    begin
      FDatabase.Free;
      FInternalDatabase := False;
    end;
  FDatabase := Value;
  FDBParamsFromCreate := False;
  if Assigned(FDatabase) then
    FreeNotification(FDatabase);
  FTransaction.DefaultDatabase := FDatabase;
  if Assigned(FExternalTransaction) then
    FExternalTransaction.DefaultDatabase := FDatabase;
  FQuery.Database := FDatabase;
  FQuery.Transaction := GetTransaction;

end;

procedure TFIBScripter.SetScript(const Value: TStrings);
begin
  FScript.Assign(Value);
end;

procedure TFIBScripter.SetDefines(const Value: TStrings);
var
  i: Integer;
begin
  FDefines.Clear;
  if Value <> nil then
    for i := 0 to Value.Count - 1 do
      if FDefines.IndexOf(UpperCase(Value[i])) < 0 then
        FDefines.Add(UpperCase(Value[i]))
end;

procedure TFIBScripter.AddDefine(const Def: string);
begin
  if FDefines.IndexOf(UpperCase(Def)) < 0 then
    FDefines.Add(UpperCase(Def))
end;

procedure TFIBScripter.DeleteDefine(const Def: string);
var
  i: Integer;
begin
  i := FDefines.IndexOf(UpperCase(Def));
  if i >= 0 then
    FDefines.Delete(i)
end;

procedure TFIBScripter.PreparePreDefines;
var
  i: Integer;
begin
  DeleteDefine(srvIsFirebird);
  i := FDirectiveConsts.IndexOfName(srvMajorVer);
  if i >= 0 then
    FDirectiveConsts.Delete(i);

  i := FDirectiveConsts.IndexOfName(srvMinorVer);
  if i >= 0 then
    FDirectiveConsts.Delete(i);

  i := FDirectiveConsts.IndexOfName(dbODSMajorVersion);
  if i >= 0 then
    FDirectiveConsts.Delete(i);

  i := FDirectiveConsts.IndexOfName(dbODSMinorVersion);
  if i >= 0 then
    FDirectiveConsts.Delete(i);

  if Assigned(FDatabase) and FDatabase.Connected then
    with FDatabase do
    begin
      if IsFirebirdConnect then
        AddDefine(srvIsFirebird);
      FDirectiveConsts.Values[srvMajorVer] := IntToStr(ServerMajorVersion);
      FDirectiveConsts.Values[srvMinorVer] := IntToStr(ServerMinorVersion);
      FDirectiveConsts.Values[dbODSMajorVersion] := IntToStr(ODSMajorVersion);
      FDirectiveConsts.Values[dbODSMinorVersion] := IntToStr(ODSMinorVersion);
    end;
end;

procedure TFIBScripter.SetConnectParams(StartToken: TFIBStatementCoord; EndCoord: TFIBStatementCoord; KeepDBParams: Boolean = False);
var
  Token: TFIBStatementCoord;
  tmpStr: String;
  CharSetGiven: Boolean;
begin
  FDatabase.Connected := False;
  if not KeepDBParams then
    FDatabase.DBParams.Clear;
  CharSetGiven := False;
  Token := StartToken;
  while (Token.X <> 0) do
  begin
    tmpStr := FParser.GetToken(Token);
    if IsClause('USER', tmpStr, 1) then
    begin
      Token := FParser.NextTokenPos(Token, EndCoord);
      if Token.X <> 0 then
        FDatabase.ConnectParams.UserName := FParser.GetToken(Token);
    end
    else if IsClause('PASSWORD', tmpStr, 1) then
    begin
      Token := FParser.NextTokenPos(Token, EndCoord);
      if Token.X <> 0 then
        FDatabase.ConnectParams.Password := FParser.GetToken(Token);
    end
    else if IsClause('ROLE', tmpStr, 1) then
    begin
      Token := FParser.NextTokenPos(Token, EndCoord);
      if Token.X <> 0 then
        FDatabase.ConnectParams.RoleName := FParser.GetToken(Token);
    end
    else if IsClause('SET', tmpStr, 1) then
    begin
      Token := FParser.NextTokenPos(Token, EndCoord);
      if Token.X <> 0 then
      begin
        tmpStr := FParser.GetToken(Token);
        if IsClause('CHARACTER', tmpStr, 1) then
        begin
          Token := FParser.NextTokenPos(Token, EndCoord);
          if (Token.X <> 0) and SameText(FParser.GetToken(Token), 'SET') then
            Token := FParser.NextTokenPos(Token, EndCoord); // SET CHARACTER SET cs
          if Token.X <> 0 then
          begin
            FDatabase.ConnectParams.CharSet := FParser.GetToken(Token);
            CharSetGiven := True;
          end
        end
      end
    end;
    if Token.X <> 0 then
      Token := FParser.NextTokenPos(Token, EndCoord);
  end;
  FDatabase.SQLDialect := FSQLDialect;
  if FLibraryName <> '' then
    FDatabase.LibraryName := FLibraryName;
  if not CharSetGiven and ((FCharSet <> '') or not KeepDBParams) then
    FDatabase.ConnectParams.CharSet := FCharSet;
end;

function TFIBScripter.StatementsCount: Integer;
begin
  Result := Integer(Length(FScriptMap)) // statements of one script text
end;

// True when the rest of the stream is valid UTF-8 with at least one multibyte character
function IsUTF8Text(Stream: TStream): Boolean;
var
  Buffer: TBytes;
  Count, i, Pending: Integer;
  B: Byte;
  HasMultiByte: Boolean;
begin
  Result := False;
  SetLength(Buffer, 65536);
  Pending := 0;
  HasMultiByte := False;
  repeat
    Count := Stream.Read(Buffer[0], Length(Buffer));
    for i := 0 to Count - 1 do
    begin
      B := Buffer[i];
      if Pending > 0 then
      begin
        if B and $C0 <> $80 then
          Exit;
        Dec(Pending);
      end
      else if B >= $80 then
      begin
        if (B >= $C2) and (B <= $DF) then
          Pending := 1
        else if B and $F0 = $E0 then
          Pending := 2
        else if (B >= $F0) and (B <= $F4) then
          Pending := 3
        else
          Exit;
        HasMultiByte := True;
      end;
    end;
  until Count = 0;
  Result := HasMultiByte and (Pending = 0);
end;

// A byte order mark selects the encoding; without one Encoding is used, and when it is nil
// a valid UTF-8 text is read as UTF-8, otherwise as TEncoding.Default.
// The BOM is detected here: TStreamReader.DetectBOM differs between Delphi versions.
function CreateScriptReader(const FileName: string; Encoding: TEncoding;
  out Stream: TFileStream): TStreamReader;
var
  Preamble: TBytes;
  BomEncoding: TEncoding;
  BomLength: Integer;
begin
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    SetLength(Preamble, 4);
    SetLength(Preamble, Stream.Read(Preamble[0], Integer(Length(Preamble))));
    BomEncoding := nil;
    BomLength := TEncoding.GetBufferEncoding(Preamble, BomEncoding);
    if BomLength > 0 then
      Encoding := BomEncoding
    else if Encoding = nil then
    begin
      Stream.Position := 0;
      if IsUTF8Text(Stream) then
        Encoding := TEncoding.UTF8
      else
        Encoding := TEncoding.Default;
    end;
    Stream.Position := BomLength;
    Result := TStreamReader.Create(Stream, Encoding, False);
  except
    FreeAndNil(Stream);
    raise;
  end;
end;

function GetLineCountInFile(const FileName: string; Encoding: TEncoding): Integer;
var
  Stream: TFileStream;
  Reader: TStreamReader;
begin
  Result := 0;
  Reader := CreateScriptReader(FileName, Encoding, Stream);
  try
    while not Reader.EndOfStream do
    begin
      Reader.ReadLine;
      Inc(Result);
    end;
  finally
    Reader.Free;
    Stream.Free;
  end;
end;

// Executes the complete statements of the current parser, False when paused
function TFIBScripter.ExecuteParsed(var StmtNo: Integer; StmtTxt: TStrings): Boolean;
var
  Stmt: PFIBStatementDesc;
begin
  while not FPaused and FParser.NextStatement(Stmt) do
  begin
    FParser.CopyFragment(Stmt.smdBegin, Stmt.smdEnd, StmtTxt);
    if RunStatement(Stmt, StmtNo, StmtTxt) then
      Inc(StmtNo);
  end;
  Result := not FPaused;
end;

// The file is parsed while it is read and every statement is executed as soon
// as it is complete, so only the lines of the current statement are kept.
procedure TFIBScripter.ExecuteFromFile(const FileName: string; Terminator: string = ';');
begin
  ExecuteFromFile(FileName, nil, Terminator);
end;

procedure TFIBScripter.ExecuteFromFile(const FileName: string; Encoding: TEncoding;
  Terminator: string = ';');
var
  Stream: TFileStream;
  Reader: TStreamReader;
  Lines, TmpSQL: TStrings;
  SavedParser: TFIBScriptParser;
  SavedEncoding: TEncoding;
  SavedLineCount, StmtNo: Integer;
begin
  SavedLineCount := FLineCountInFile;
  FLineCountInFile := GetLineCountInFile(FileName, Encoding);
  Reader := CreateScriptReader(FileName, Encoding, Stream);
  Lines := TStringList.Create;
  TmpSQL := TStringList.Create;
  SavedParser := FParser;
  FParser := TFIBScriptParser.Create;
  SavedEncoding := FFileEncoding;
  FFileEncoding := Encoding;
  try
    BeginRun(False);
    FParser.BeginParse(Lines, Terminator);
    StmtNo := 0;
    while not FPaused and not Reader.EndOfStream do
    begin
      Lines.Add(Reader.ReadLine);
      FParser.Scan;
      if ExecuteParsed(StmtNo, TmpSQL) then
        FParser.DiscardParsed;
    end;
    if not FPaused then
    begin
      FParser.EndParse(True);
      ExecuteParsed(StmtNo, TmpSQL);
    end;
    if FRunDepth = 1 then
      FlushExecBlock;
    if FPaused then
      FStopStatementNo := StmtNo + 1;
  finally
    try
      EndRun;
    finally
      FFileEncoding := SavedEncoding;
      // A file run by INPUT gives the line count back to the calling file
      if FRunDepth > 0 then
        FLineCountInFile := SavedLineCount;
      FParser.Free;
      FParser := SavedParser;
      TmpSQL.Free;
      Lines.Free;
      Reader.Free;
      Stream.Free;
    end;
  end;
end;

procedure TFIBScripter.SetTransaction(const Value: TFIBTransaction);
begin
  FExternalTransaction := Value;
  if Value <> nil then
  begin
    if FExternalTransaction.DefaultDatabase <> FDatabase then
      FExternalTransaction.DefaultDatabase := FDatabase;
    FQuery.Transaction := FExternalTransaction;
  end
  else
    FQuery.Transaction := FTransaction;
end;

function TFIBScripter.GetTransaction: TFIBTransaction;
begin
  if Assigned(FExternalTransaction) then
    Result := FExternalTransaction
  else
    Result := FTransaction
end;

function TFIBScripter.LineCountInCurrentFile: Integer;
begin
  Result := FLineCountInFile;
end;

procedure TFIBScripter.SetOnStatExec(CallBack: TFIBScriptStatementExecEvent);
begin
  FInternalOnStatementExec := CallBack
end;

{ TFIBScriptParser }

function IsBlank(C: Char): Boolean; inline;
begin
  Result := CharInSet(C, [' ', #9, #10, #13]);
end;

function IsWordChar(C: Char): Boolean; inline;
begin
  Result := CharInSet(C, ['A' .. 'Z', 'a' .. 'z', '0' .. '9', '_', '$']);
end;

// Compares the word of Len chars at X in S with UpperWord, case insensitive
function SameWord(const S: string; X, Len: Integer; const UpperWord: string): Boolean;
var
  i: Integer;
begin
  Result := Len = Length(UpperWord);
  if Result then
    for i := 1 to Len do
      if UpCase(S[X + i - 1]) <> UpperWord[i] then
      begin
        Result := False;
        Exit;
      end;
end;

function KeywordOf(const S: string; X, Len: Integer): TFIBScriptKeyword;
begin
  Result := kwOther;
  case Len of
    2:
      if SameWord(S, X, Len, 'AS') then
        Result := kwAs
      else if SameWord(S, X, Len, 'OR') then
        Result := kwOr;
    3:
      if SameWord(S, X, Len, 'END') then
        Result := kwEnd
      else if SameWord(S, X, Len, 'SET') then
        Result := kwSet;
    4:
      if SameWord(S, X, Len, 'CASE') then
        Result := kwCase
      else if SameWord(S, X, Len, 'TERM') then
        Result := kwTerm;
    5:
      if SameWord(S, X, Len, 'BEGIN') then
        Result := kwBegin
      else if SameWord(S, X, Len, 'ALTER') then
        Result := kwAlter
      else if SameWord(S, X, Len, 'BLOCK') then
        Result := kwBlock
      else if SameWord(S, X, Len, 'MERGE') then
        Result := kwMerge;
    6:
      if SameWord(S, X, Len, 'CREATE') then
        Result := kwCreate
      else if SameWord(S, X, Len, 'INSERT') then
        Result := kwInsert
      else if SameWord(S, X, Len, 'UPDATE') then
        Result := kwUpdate
      else if SameWord(S, X, Len, 'DELETE') then
        Result := kwDelete;
    7:
      if SameWord(S, X, Len, 'EXECUTE') then
        Result := kwExecute
      else if SameWord(S, X, Len, 'TRIGGER') then
        Result := kwTrigger
      else if SameWord(S, X, Len, 'PACKAGE') then
        Result := kwPackage;
    8:
      if SameWord(S, X, Len, 'RECREATE') then
        Result := kwRecreate
      else if SameWord(S, X, Len, 'FUNCTION') then
        Result := kwFunction
      else if SameWord(S, X, Len, 'EXTERNAL') then
        Result := kwExternal
      else if SameWord(S, X, Len, 'REINSERT') then
        Result := kwReinsert;
    9:
      if SameWord(S, X, Len, 'PROCEDURE') then
        Result := kwProcedure;
  end;
end;

function TFIBScriptParser.Line(Y: Integer): string;
begin
  Result := FScript[Y - FFirstLine];
end;

procedure TFIBScriptParser.SetTerminator(const Value: string);
begin
  if Value = '' then
    FTerminator := ';'
  else
    FTerminator := Value;
  FTermFirst := UpCase(FTerminator[1]);
  FTermFirstLower := LowerCase(FTermFirst)[1];
end;

function TFIBScriptParser.IsTerminatorAt(const S: string; X: Integer): Boolean;
var
  L, i: Integer;
begin
  L := Length(FTerminator);
  Result := (UpCase(S[X]) = FTermFirst) and (X + L - 1 <= Length(S));
  if not Result then
    Exit;
  for i := 2 to L do
    if UpCase(S[X + i - 1]) <> UpCase(FTerminator[i]) then
    begin
      Result := False;
      Exit;
    end;
  // A terminator made of letters is not a part of a word
  if IsWordChar(FTerminator[1]) and (X > 1) and IsWordChar(S[X - 1]) then
    Result := False
  else if IsWordChar(FTerminator[L]) and (X + L <= Length(S)) and IsWordChar(S[X + L]) then
    Result := False;
end;

function TFIBScriptParser.IsModuleHeader: Boolean;
var
  ObjWord: Integer;
begin
  case FHeader[0] of
    kwExecute: Result := FHeader[1] = kwBlock;
    kwCreate, kwAlter, kwRecreate:
      begin
        if (FHeader[0] = kwCreate) and (FHeader[1] = kwOr) and (FHeader[2] = kwAlter) then
          ObjWord := 3
        else
          ObjWord := 1;
        Result := FHeader[ObjWord] in [kwProcedure, kwTrigger, kwFunction, kwPackage];
      end;
  else
    Result := False;
  end;
end;

// Follows the words that decide where the statement ends: SET TERM, and the body
// of a PSQL module, where ";" ends the statement only after the END of the body.
// Other words are only skipped.
procedure TFIBScriptParser.ProcessWord(const S: string; X, Len: Integer);
var
  K: TFIBScriptKeyword;
begin
  if FCheckReturning and SameWord(S, X, Len, 'RETURNING') then
  begin
    FStatements[FStatementCount - 1].HasReturning := True;
    FCheckReturning := False;
  end;
  if (FWordCount > High(FHeader)) and not FInBody and not FMayHaveBody then
    Exit;
  K := KeywordOf(S, X, Len);
  if FWordCount <= High(FHeader) then
  begin
    FHeader[FWordCount] := K;
    if FWordCount = 0 then
    begin
      FMayHaveBody := (FTerminator = ';') and (K in [kwCreate, kwAlter, kwRecreate, kwExecute]);
      FCheckReturning := K in [kwInsert, kwUpdate, kwDelete, kwMerge, kwReinsert];
    end;
  end;
  Inc(FWordCount);
  if FInBody then
  begin
    FLastWordIsEnd := K = kwEnd;
    if K = kwEnd then
    begin
      if FBlockDepth > 0 then
        Dec(FBlockDepth);
    end
    else if K in [kwBegin, kwCase] then
      Inc(FBlockDepth);
  end
  else if (FWordCount = 2) and (FHeader[0] = kwSet) and (K = kwTerm) then
    FInSetTerm := True
  else if FMayHaveBody then
  begin
    if K = kwExternal then // EXTERNAL NAME ... ENGINE ... [AS '<body>']
      FExternal := True
    else if (K = kwAs) and (FParenDepth = 0) and not FExternal and IsModuleHeader then
      FInBody := True;
  end;
end;

procedure TFIBScriptParser.BeginStatement(X, Y: Integer; StmtType: TFIBStatementType);
var
  P: PFIBStatementDesc;
  i: Integer;
begin
  if FStatementCount = Length(FStatements) then
    SetLength(FStatements, FStatementCount + FStatementCount div 2 + 8);
  Inc(FStatementCount);
  P := @FStatements[FStatementCount - 1];
  P.smdBegin := StmtCoord(X, Y);
  P.smdEnd := StmtCoord(0, 0);
  P.smtType := StmtType;
  P.objType := otNone;
  P.objName := '';
  P.DirectiveNum := FCurDirective;
  P.DirectiveElse := (FCurDirective >= 0) and (FDirectives[FCurDirective].dElse.X > 0);
  P.HasReturning := False;

  FDisposition := pdInStatement;
  FLastSignificant := StmtCoord(X, Y);
  FWordCount := 0;
  for i := 0 to High(FHeader) do
    FHeader[i] := kwOther;
  FParenDepth := 0;
  FMayHaveBody := False;
  FExternal := False;
  FInBody := False;
  FBlockDepth := 0;
  FLastWordIsEnd := False;
  FCheckReturning := False;
  FInSetTerm := False;
  FNewTerminator := '';
  FNewTerminatorDone := False;
end;

procedure TFIBScriptParser.EndStatement;
var
  P: PFIBStatementDesc;
begin
  P := @FStatements[FStatementCount - 1];
  P.smdEnd := FLastSignificant;
  if FDisposition = pdInStatement then
  begin
    if P.smtType <> sInvalid then
      ValidateStatement(P^);
    if P.smtType = sDML then
      FHaveDMLStatements := True
    else if P.smtType in [sUnknown, sInvalid] then
      FHaveUnknownStatements := True;
  end;
  FCompleteCount := FStatementCount;
  FDisposition := pdBetweenStatements;
end;

procedure TFIBScriptParser.EndSetTerm;
begin
  if FNewTerminator = '' then
    raise Exception.Create('Parse script error.' + sLineBreak + 'SET TERM without terminator' + sLineBreak + 'Line :' +
      IntToStr(FStatements[FStatementCount - 1].smdBegin.Y + 1));
  SetTerminator(FNewTerminator);
  Dec(FStatementCount); // SET TERM is not executed
  FInSetTerm := False;
  FDisposition := pdBetweenStatements;
end;

procedure TFIBScriptParser.BeginDirective(X, Y: Integer);
var
  D: PFIBDirectiveDesc;
  Owner: Integer;
begin
  if FDirectiveCount = Length(FDirectives) then
    SetLength(FDirectives, FDirectiveCount + FDirectiveCount div 2 + 4);
  Inc(FDirectiveCount);
  D := @FDirectives[FDirectiveCount - 1];
  D.dBegin := StmtCoord(X, Y);
  D.dConditionClose := StmtCoord(0, 0);
  D.dElse := StmtCoord(0, 0);
  D.dEnd := StmtCoord(0, 0);
  D.dState := dsUnknown;
  D.dCondition := '';
  if Length(FDirectiveStack) = 0 then
  begin
    D.OwnerDirectiveNum := -1;
    D.OwnerDirectiveElse := False;
  end
  else
  begin
    Owner := FDirectiveStack[High(FDirectiveStack)];
    D.OwnerDirectiveNum := Owner;
    D.OwnerDirectiveElse := FDirectives[Owner].dElse.X > 0;
  end;
  SetLength(FDirectiveStack, Length(FDirectiveStack) + 1);
  FCurDirective := FDirectiveCount - 1;
  FDirectiveStack[High(FDirectiveStack)] := FCurDirective;
  FState := psInConditional;
end;

procedure TFIBScriptParser.CloseDirectiveCondition(X, Y: Integer);
var
  D: PFIBDirectiveDesc;
  Text: TStrings;
begin
  D := @FDirectives[FCurDirective];
  D.dConditionClose := StmtCoord(X, Y);
  Text := TStringList.Create;
  try
    CopyFragment(D.dBegin, D.dConditionClose, Text);
    D.dCondition := Text.Text;
  finally
    Text.Free;
  end;
  FState := psNormal;
end;

procedure TFIBScriptParser.ElseDirective(X, Y: Integer);
begin
  if Length(FDirectiveStack) = 0 then
    RaiseParserDirectiveError(dElse, Y + 1);
  FDirectives[FDirectiveStack[High(FDirectiveStack)]].dElse := StmtCoord(X, Y);
end;

procedure TFIBScriptParser.EndIfDirective(X, Y: Integer);
begin
  if Length(FDirectiveStack) = 0 then
    RaiseParserDirectiveError(dEndIf, Y + 1);
  FDirectives[FDirectiveStack[High(FDirectiveStack)]].dEnd := StmtCoord(X, Y);
  SetLength(FDirectiveStack, Length(FDirectiveStack) - 1);
  if Length(FDirectiveStack) > 0 then
    FCurDirective := FDirectiveStack[High(FDirectiveStack)]
  else
    FCurDirective := -1;
end;

procedure TFIBScriptParser.ScanLine(Y: Integer);
var
  S: string;
  L, X, E: Integer;
  C: Char;
begin
  S := Line(Y);
  L := Length(S);
  X := 1;
  while X <= L do
  begin
    C := S[X];
    case FState of
      psInComment:
        begin
          while (X < L) and not((S[X] = '*') and (S[X + 1] = '/')) do
            Inc(X);
          if X < L then
          begin
            FState := psNormal;
            Inc(X);
          end
          else
            X := L;
        end;
      psInQuote, psInDoubleQuote:
      // a doubled quote closes and opens the string again
        begin
          while (X <= L) and (S[X] <> FQuoteClose) do
            Inc(X);
          if X <= L then
          begin
            FState := psNormal;
            FLastSignificant := StmtCoord(X, Y);
          end;
        end;
      psInQString:
        begin
          while (X < L) and not((S[X] = FQuoteClose) and (S[X + 1] = '''')) do
            Inc(X);
          if X < L then
          begin
            Inc(X);
            FState := psNormal;
            FLastSignificant := StmtCoord(X, Y);
          end
          else
            X := L;
        end;
      psInConditional:
        if C = '}' then
          CloseDirectiveCondition(X, Y);
    else
      if (C = '-') and (X < L) and (S[X + 1] = '-') then
      begin
        // an item of the script may hold several lines
        while (X < L) and not CharInSet(S[X + 1], [#10, #13]) do
          Inc(X);
      end
      else if (C = '/') and (X < L) and (S[X + 1] = '*') then
      begin
        FState := psInComment;
        Inc(X);
      end
      else
        case FDisposition of
          pdBetweenStatements:
            if C = '{' then
            begin
              if IsClause(dElse, S, X) or IsClause(dEndIf, S, X) then
              begin
                if IsClause(dElse, S, X) then
                  ElseDirective(X, Y)
                else
                  EndIfDirective(X, Y);
                E := X;
                while (E <= L) and (S[E] <> '}') do
                  Inc(E);
                if E > L then
                  RaiseParserDirectiveError('}', Y + 1);
                X := E;
              end
              else if StrIsIfDirective(S, X) then
                BeginDirective(X, Y)
              else
              begin
                if (X < L) and (S[X + 1] = '$') then
                  BeginStatement(X, Y, sDirective)
                else
                  BeginStatement(X, Y, sInvalid);
                FDisposition := pdInDirective;
              end;
            end
            else if ((C = FTermFirst) or (C = FTermFirstLower)) and IsTerminatorAt(S, X) then
              Inc(X, Length(FTerminator) - 1)
            else if not CharInSet(C, [' ', #9, #10, #13, ';', ',', '^', '}']) then
            begin
              if CharInSet(C, ['-', '/']) then
                BeginStatement(X, Y, sInvalid)
              else
                BeginStatement(X, Y, sUnknown);
              Continue; // the character is scanned as a part of the statement
            end;
          pdInDirective:
            if not IsBlank(C) then
            begin
              FLastSignificant := StmtCoord(X, Y);
              if C = '}' then
                EndStatement;
            end;
          pdInStatement:
            if FInSetTerm then
            begin
              // SET TERM <new> <current>, the new terminator may be the current one
              if IsBlank(C) then
                FNewTerminatorDone := FNewTerminator <> ''
              else if (FNewTerminator <> '') and IsTerminatorAt(S, X) then
              begin
                E := Length(FTerminator);
                EndSetTerm;
                Inc(X, E - 1);
              end
              else if FNewTerminatorDone then
                raise Exception.Create('Parse script error.' + sLineBreak +
                  'Invalid SET TERM' + sLineBreak + 'Line :' + IntToStr(Y + 1) +
                  ' Pos:' + IntToStr(X))
              else
                FNewTerminator := FNewTerminator + C;
            end
            else if ((C = FTermFirst) or (C = FTermFirstLower)) and IsTerminatorAt(S, X) and
              (not FInBody or ((FBlockDepth = 0) and FLastWordIsEnd)) then
            begin
              EndStatement;
              Inc(X, Length(FTerminator) - 1);
            end
            else if not IsBlank(C) then
            begin
              FLastSignificant := StmtCoord(X, Y);
              FLastWordIsEnd := False;
              case C of
                '''':
                  begin
                    FState := psInQuote;
                    FQuoteClose := C;
                  end;
                '"':
                  begin
                    FState := psInDoubleQuote;
                    FQuoteClose := C;
                  end;
                '(': Inc(FParenDepth);
                ')':
                  if FParenDepth > 0 then
                    Dec(FParenDepth);
                '{':
                  raise Exception.Create('Parse script error.' + sLineBreak +
                    ' Unexpected symbol "{"' + sLineBreak + 'Line :' + IntToStr(Y + 1) +
                    ' Pos:' + IntToStr(X));
              else
                if CharInSet(C, ['q', 'Q']) and (X + 2 <= L) and (S[X + 1] = '''') then
                begin
                  // q'<delimiter>...<delimiter>'
                  FState := psInQString;
                  case S[X + 2] of
                    '(': FQuoteClose := ')';
                    '[': FQuoteClose := ']';
                    '{':
                      FQuoteClose := '}';
                    '<': FQuoteClose := '>';
                  else
                    FQuoteClose := S[X + 2];
                  end;
                  Inc(X, 2);
                end
                else if IsWordChar(C) then
                begin
                  E := X;
                  while (E < L) and IsWordChar(S[E + 1]) do
                    Inc(E);
                  ProcessWord(S, X, E - X + 1);
                  FLastSignificant := StmtCoord(E, Y);
                  X := E;
                end;
              end;
            end;
        end;
    end;
    Inc(X);
  end;
  if FInSetTerm and (FNewTerminator <> '') then
  // the line ends the new terminator
    FNewTerminatorDone := True;
end;

procedure TFIBScriptParser.BeginParse(AScript: TStrings; const Terminator: string);
begin
  FScript := AScript;
  FFirstLine := 0;
  FNextLine := 0;
  SetTerminator(Terminator);
  SetLength(FStatements, 0);
  FStatementCount := 0;
  FCompleteCount := 0;
  FTakenCount := 0;
  SetLength(FDirectives, 0);
  FDirectiveCount := 0;
  SetLength(FDirectiveStack, 0);
  FCurDirective := -1;
  FDisposition := pdBetweenStatements;
  FState := psNormal;
  FCurDBName := '';
  FMakeConnectInScript := False;
  FHaveDMLStatements := False;
  FHaveUnknownStatements := False;
end;

procedure TFIBScriptParser.Scan;
begin
  while FNextLine < FFirstLine + FScript.Count do
  begin
    ScanLine(FNextLine);
    Inc(FNextLine);
  end;
end;

procedure TFIBScriptParser.EndParse(IgnoreLastTerm: Boolean);
begin
  case FDisposition of
    pdInStatement:
      if FInSetTerm then
        EndSetTerm
      else if IgnoreLastTerm then
        EndStatement;
    pdInDirective:
      if IgnoreLastTerm then
        EndStatement;
  end;
  if Length(FDirectiveStack) > 0 then
    raise Exception.Create('Parse script error.' + sLineBreak + '$ENDIF skipped ' +
      IntToStr(Length(FDirectiveStack)) + ' times');
end;

function TFIBScriptParser.NextStatement(var Stmt: PFIBStatementDesc): Boolean;
begin
  Result := FTakenCount < FCompleteCount;
  if Result then
  begin
    Stmt := @FStatements[FTakenCount];
    Inc(FTakenCount);
  end;
end;

procedure TFIBScriptParser.DiscardParsed;
var
  i, KeepLine: Integer;
begin
  for i := 0 to FStatementCount - FTakenCount - 1 do
    FStatements[i] := FStatements[FTakenCount + i];
  Dec(FStatementCount, FTakenCount);
  Dec(FCompleteCount, FTakenCount);
  FTakenCount := 0;

  KeepLine := FNextLine;
  if FStatementCount > 0 then
    KeepLine := FStatements[0].smdBegin.Y;
  if (FState = psInConditional) and (FDirectives[FCurDirective].dBegin.Y < KeepLine) then
    KeepLine := FDirectives[FCurDirective].dBegin.Y;
  if KeepLine >= FFirstLine + FScript.Count then
    FScript.Clear
  else
    while FFirstLine < KeepLine do
    begin
      FScript.Delete(0);
      Inc(FFirstLine);
    end;
  FFirstLine := KeepLine;
end;

procedure TFIBScriptParser.ParseScript(AScript: TStrings;
  var Terminator: string; var ScriptMap: TFIBScriptMap;
  var DirectivesMap: TFIBDirectivesMap; IgnoreLastTerm: Boolean);
begin
  BeginParse(AScript, Terminator);
  try
    Scan;
    EndParse(IgnoreLastTerm);
  finally
    Terminator := FTerminator;
    ScriptMap := Copy(FStatements, 0, FStatementCount);
    DirectivesMap := Copy(FDirectives, 0, FDirectiveCount);
  end;
end;

procedure TFIBScriptParser.CopyFragment(BegPos, EndPos: TFIBStatementCoord; Dest: TStrings);
var
  Y: Integer;
  S: string;
begin
  if not Assigned(Dest) then
    Exit;
  Dest.Clear;
  if (EndPos.X = 0) and (FScript.Count > 0) then
  begin
    // No terminator, up to the end of the script
    EndPos.Y := FFirstLine + FScript.Count - 1;
    EndPos.X := Length(Line(EndPos.Y));
  end;
  for Y := BegPos.Y to EndPos.Y do
  begin
    S := Line(Y);
    if Y = EndPos.Y then
      S := Copy(S, 1, EndPos.X);
    if Y = BegPos.Y then
      S := Copy(S, BegPos.X, MaxInt);
    Dest.Add(S);
  end;
end;

procedure TFIBScriptParser.SearchObjectType(var stmtDesc: TFIBStatementDesc; var BegSearch: TFIBStatementCoord; ForGrant: Boolean = False);
var
  TmpCoord1: TFIBStatementCoord;
  CurStr: string;
  S: string;

begin
  TmpCoord1 := NextTokenPos(BegSearch, stmtDesc.smdEnd);
  While (TmpCoord1.X <> 0) do
  begin // CREATE UNIQUE ASCENDING INDEX
    CurStr := Line(TmpCoord1.Y);
    if not ForGrant then
    begin
      stmtDesc.objType := TypeNameToObjectType(CurStr, TmpCoord1.X);
      if stmtDesc.objType = otNone then
        TmpCoord1 := NextTokenPos(TmpCoord1, stmtDesc.smdEnd)
      else
        Break
    end
    else
    begin
      // GRANTS
      S := GetToken(TmpCoord1);
      if IsClause('ON', CurStr, TmpCoord1.X) then
      begin
        TmpCoord1 := NextTokenPos(TmpCoord1, stmtDesc.smdEnd);
        stmtDesc.objType := TypeNameToObjectType(CurStr, TmpCoord1.X);
        if stmtDesc.objType <> otNone then
          TmpCoord1 := NextTokenPos(TmpCoord1, stmtDesc.smdEnd);
        stmtDesc.objName := GetToken(TmpCoord1);
        BegSearch := TmpCoord1;
        Exit
      end
      else
        TmpCoord1 := NextTokenPos(TmpCoord1, stmtDesc.smdEnd)
    end;
  end;
  if stmtDesc.objType <> otNone then
    BegSearch := TmpCoord1;
end;

// Sets the type and the object of a complete statement
procedure TFIBScriptParser.ValidateStatement(var stmtDesc: TFIBStatementDesc);
const
  SessionSetWords: array [0 .. 7] of string = ('STATEMENT', 'SESSION', 'BIND', 'DECFLOAT', 'ROLE', 'TRUSTED',
    'OPTIMIZE', 'SEARCH_PATH');
var
  CurStr: string;
  TmpCoord: TFIBStatementCoord;
  i: Integer;
begin
  // Step 1
  CurStr := Line(stmtDesc.smdBegin.Y);
  stmtDesc.smtType := StmtTypeNameToType(CurStr, stmtDesc.smdBegin.X);
  // Step 2
  stmtDesc.objType := otNone;

  case stmtDesc.smtType of
    sConnect:
      begin
        stmtDesc.objType := otDatabase;
        TmpCoord := NextTokenPos(stmtDesc.smdBegin, stmtDesc.smdEnd);
        if TmpCoord.X <> 0 then
        begin
          stmtDesc.objName := GetToken(TmpCoord);
          FCurDBName := stmtDesc.objName;
        end;
        FMakeConnectInScript := True;
      end;
    sReconnect, sDisconnect, sCommit, sRollBack:
      begin
        stmtDesc.objName := FCurDBName;
        stmtDesc.objType := otDatabase;
      end;

    sAlter, sCreate, sDrop, sRecreate, sExecute: // Next Word may be type Object
      begin
        TmpCoord := NextTokenPos(stmtDesc.smdBegin, stmtDesc.smdEnd);
        if TmpCoord.X <> 0 then
        begin
          if stmtDesc.smtType = sExecute then
          begin
            CurStr := GetToken(TmpCoord);
            stmtDesc.smtType := sDML;
            if IsClause('BLOCK', CurStr, 1) then
              stmtDesc.objType := otBlock
            else
              Exit;
          end
          else
          begin
            CurStr := Line(TmpCoord.Y);
            stmtDesc.objType := TypeNameToObjectType(CurStr, TmpCoord.X);
          end;
          case stmtDesc.objType of
            otNone: SearchObjectType(stmtDesc, TmpCoord);
            otDatabase:
              case stmtDesc.smtType of
                sCreate:
                  begin
                    FMakeConnectInScript := True;
                    stmtDesc.smtType := sCreateDatabase;
                  end;
                sDrop: stmtDesc.smtType := sDropDatabase
              end;
          end;

          if stmtDesc.objType <> otBlock then
          begin
            TmpCoord := NextTokenPos(TmpCoord, stmtDesc.smdEnd);
            if TmpCoord.X <> 0 then
              stmtDesc.objName := GetToken(TmpCoord)
            else
              stmtDesc.objName := '';

            if (stmtDesc.objType = otPackage) and IsClause('BODY', stmtDesc.objName, 1) then
            begin
              stmtDesc.objType := otPackageBody;

              TmpCoord := NextTokenPos(TmpCoord, stmtDesc.smdEnd);
              if TmpCoord.X <> 0 then
                stmtDesc.objName := GetToken(TmpCoord)
              else
                stmtDesc.objName := '';
            end;

          end;
          if stmtDesc.smtType = sCreateDatabase then
            FCurDBName := stmtDesc.objName
          else if stmtDesc.smtType = sDropDatabase then
            stmtDesc.objName := FCurDBName;

        end;
      end;
    sDeclare:
      begin
        stmtDesc.objType := otNone;
        TmpCoord := NextTokenPos(stmtDesc.smdBegin, stmtDesc.smdEnd);
        if TmpCoord.X <> 0 then
        begin
          CurStr := Line(TmpCoord.Y);
          if IsClause('EXTERNAL', CurStr, TmpCoord.X) then
            stmtDesc.objType := otUDF
          else if IsClause('FILTER', CurStr, TmpCoord.X) then
            stmtDesc.objType := otFilter;
          case stmtDesc.objType of
            otUDF:
              begin
                TmpCoord := NextTokenPos(TmpCoord, stmtDesc.smdEnd);
                TmpCoord := NextTokenPos(TmpCoord, stmtDesc.smdEnd);
                if TmpCoord.X <> 0 then
                  stmtDesc.objName := GetToken(TmpCoord)
                else
                  stmtDesc.objName := ''
              end;
          end
        end
      end;
    sSet:
      begin
        stmtDesc.objType := otNone;
        TmpCoord := NextTokenPos(stmtDesc.smdBegin, stmtDesc.smdEnd);
        if TmpCoord.X <> 0 then
        begin
          CurStr := Line(TmpCoord.Y);
          if IsClause('GENERATOR', CurStr, TmpCoord.X) then
          begin
            stmtDesc.objType := otGenerator;
            stmtDesc.smtType := sSetGenerator;
          end
          else if IsClause('STATISTICS', CurStr, TmpCoord.X) then
          begin
            stmtDesc.objType := otIndex;
            stmtDesc.smtType := sSetStatistics;
            TmpCoord := NextTokenPos(TmpCoord, stmtDesc.smdEnd);
          end
          else
          begin
            for i := Low(SessionSetWords) to High(SessionSetWords) do
              if IsClause(SessionSetWords[i], CurStr, TmpCoord.X) then
              begin
                stmtDesc.smtType := sSetSession;
                Break;
              end;
            if (stmtDesc.smtType = sSet) and IsClause('TIME', CurStr, TmpCoord.X) then
            begin
              TmpCoord := NextTokenPos(TmpCoord, stmtDesc.smdEnd);
              if TmpCoord.X <> 0 then
                if IsClause('ZONE', Line(TmpCoord.Y), TmpCoord.X) then
                  stmtDesc.smtType := sSetSession;
            end;
          end;

          if stmtDesc.objType <> otNone then
          begin
            TmpCoord := NextTokenPos(TmpCoord, stmtDesc.smdEnd);
            if TmpCoord.X <> 0 then
              stmtDesc.objName := GetToken(TmpCoord)
            else
              stmtDesc.objName := '';
          end;
        end
      end;
    sGrant:
      begin
        TmpCoord := NextTokenPos(stmtDesc.smdBegin, stmtDesc.smdEnd);
        SearchObjectType(stmtDesc, TmpCoord, True)
      end;
    sBatch: // Temporary type
      begin
        TmpCoord := NextTokenPos(stmtDesc.smdBegin, stmtDesc.smdEnd);
        if TmpCoord.X = 0 then
          stmtDesc.smtType := sInvalid
        else
        begin
          CurStr := Line(TmpCoord.Y);
          if IsClause('START', CurStr, TmpCoord.X) then
            stmtDesc.smtType := sBatchStart
          else if IsClause('EXECUTE', CurStr, TmpCoord.X) then
            stmtDesc.smtType := sBatchExecute
          else
            stmtDesc.smtType := sInvalid;
        end;
      end;
    sDescribe, sComment:
      begin
        TmpCoord := NextTokenPos(stmtDesc.smdBegin, stmtDesc.smdEnd);
        if stmtDesc.smtType = sComment then
          TmpCoord := NextTokenPos(TmpCoord, stmtDesc.smdEnd);
        if TmpCoord.X <> 0 then
        begin
          CurStr := Line(TmpCoord.Y);
          stmtDesc.objType := TypeNameToObjectType(CurStr, TmpCoord.X);
          if stmtDesc.objType <> otNone then
          begin
            TmpCoord := NextTokenPos(TmpCoord, stmtDesc.smdEnd);
            if TmpCoord.X <> 0 then
              stmtDesc.objName := GetToken(TmpCoord)
            else
              stmtDesc.objName := '';

            if stmtDesc.smtType = sDescribe then
              case stmtDesc.objType of
                otField, otParameter:
                  begin
                    TmpCoord := NextTokenPos(TmpCoord, stmtDesc.smdEnd);
                    // Table,View or Procedure
                    TmpCoord := NextTokenPos(TmpCoord, stmtDesc.smdEnd);
                    // Object Name
                    if TmpCoord.X <> 0 then
                      stmtDesc.objName := GetToken(TmpCoord) + '.' + stmtDesc.objName
                    else
                      stmtDesc.objName := '';
                  end;
              end;
          end;
        end
      end;
  end;
end;

function TFIBScriptParser.NextTokenPos(TokenPos: TFIBStatementCoord; EndCoord: TFIBStatementCoord): TFIBStatementCoord;
var
  InComment: Boolean;
  i, j, Len: Integer;
  CurStr: string;
  FirstChar: Char;
begin
  CurStr := Line(TokenPos.Y);
  Len := Length(CurStr);
  Result.Y := TokenPos.Y;
  // Skip the token at TokenPos, at least one char
  i := TokenPos.X;
  if i <= Len then
  begin
    FirstChar := CurStr[i];
    if CharInSet(FirstChar, ['''', '"']) then
    begin
      repeat
        Inc(i)
      until (i > Len) or (CurStr[i] = FirstChar);
      Inc(i);
    end
    else
      repeat
        Inc(i)
      until (i > Len) or CharInSet(CurStr[i], [' ', #13, #9, #10, '/', '-', ';']);
  end;
  if i > Len then
  begin
    i := 1;
    Inc(TokenPos.Y);
  end;
  Result.X := 0;
  InComment := False;
  for j := TokenPos.Y to EndCoord.Y do
  begin
    CurStr := Line(j);
    Len := Length(CurStr);
    if (j = EndCoord.Y) and (EndCoord.X < Len) then
      Len := EndCoord.X;
    while i <= Len do
    begin
      if InComment then
      begin
        if (CurStr[i] = '*') and (i < Len) and (CurStr[i + 1] = '/') then
        begin
          InComment := False;
          Inc(i);
        end;
      end
      else
        case CurStr[i] of
          ' ', #13, #9, #10, ';':
            ; // skip
          '-':
            if (i < Len) and (CurStr[i + 1] = '-') then
              // comment up to the end of the line
              while (i < Len) and not CharInSet(CurStr[i + 1], [#10, #13]) do
                Inc(i);
          '/':
            if (i < Len) and (CurStr[i + 1] = '*') then
            begin
              InComment := True;
              Inc(i);
            end;
        else
          Result.Y := j;
          Result.X := i;
          Exit;
        end;
      Inc(i);
    end;
    i := 1;
  end;
end;

function TFIBScriptParser.GetToken(TokenPos: TFIBStatementCoord; IgnoreQuote: Boolean = True): string;
var
  CurStr: string;
  StartPosInStr: Integer;
  EndPosInStr: Integer;
  P: PChar;
  L: Integer;
begin
  CurStr := Line(TokenPos.Y);
  StartPosInStr := TokenPos.X;
  if CharInSet(CurStr[StartPosInStr], ['''', '"']) and IgnoreQuote then
  begin
    EndPosInStr := PosCh1(CurStr[StartPosInStr], CurStr, StartPosInStr + 1);
    if EndPosInStr = 0 then
      raise Exception.Create('Can''t find end token');
    Inc(StartPosInStr);
  end
  else
  begin
    EndPosInStr := StartPosInStr;
    L := Length(CurStr);
    while (EndPosInStr <= L) and not CharInSet(CurStr[EndPosInStr], [#9, #13, #10, ' ', '-', '/', ',', ';', '(']) do
      Inc(EndPosInStr);
  end;

  L := EndPosInStr - StartPosInStr;
  SetLength(Result, L);
  if L > 0 then
  begin
    P := Pointer(CurStr);
    Inc(P, StartPosInStr - 1);
    Move(P^, Result[1], L * SizeOf(Char))
  end;
end;

function TFIBScriptParser.TypeNameToObjectType(const TestString: string; Position: Integer): TFIBScriptObjectType;
begin
  Result := otNone;
  case TestString[Position] of
    'C', 'c':
      if IsClause('CONSTRAINT', TestString, Position) then
        Result := otConstraint
      else if IsClause('COLUMN', TestString, Position) then
        Result := otField;
    'D', 'd':
      if IsClause('DATABASE', TestString, Position) then
        Result := otDatabase
      else if IsClause('DOMAIN', TestString, Position) then
        Result := otDomain;
    'E', 'e':
      if IsClause('EXCEPTION', TestString, Position) then
        Result := otException;

    'F', 'f':
      if IsClause('FIELD', TestString, Position) then
        Result := otField
      else if IsClause('FUNCTION', TestString, Position) then
        Result := otFunction
      else if IsClause('FILTER', TestString, Position) then
        Result := otFilter;
    'G', 'g':
      if IsClause('GENERATOR', TestString, Position) then
        Result := otGenerator;
    'I', 'i':
      if IsClause('INDEX', TestString, Position) then
        Result := otIndex;
    'P', 'p':
      if IsClause('PROCEDURE', TestString, Position) then
        Result := otProcedure
      else if IsClause('PARAMETER', TestString, Position) then
        Result := otParameter
      else if IsClause('PACKAGE', TestString, Position) then
        Result := otPackage;

    'R', 'r':
      if IsClause('ROLE', TestString, Position) then
        Result := otRole;
    'T', 't':
      if IsClause('TABLE', TestString, Position) then
        Result := otTable
      else if IsClause('TRIGGER', TestString, Position) then
        Result := otTrigger;
    'U', 'u':
      if IsClause('USER', TestString, Position) then
        Result := otUser;
    'V', 'v':
      if IsClause('VIEW', TestString, Position) then
        Result := otView;

  end;
end;

function TFIBScriptParser.StmtTypeNameToType(const TestString: string; Position: Integer): TFIBStatementType;
begin
  Result := sUnknown;
  case TestString[Position] of
    'A', 'a': // May be alter
      if IsClause('ALTER', TestString, Position) then
      begin
        Result := sAlter;
      end;
    'B', 'b':
      if IsClause('BATCH', TestString, Position) then
      begin
        Result := sBatch;
      end;
    'C', 'c': // May be Create,Connect,Comment
      if IsClause('CREATE', TestString, Position) then
      begin
        Result := sCreate;
      end
      else if IsClause('COMMIT', TestString, Position) then
      begin
        Result := sCommit;
      end
      else if IsClause('COMMENT', TestString, Position) then
      begin
        Result := sComment;
      end
      else if IsClause('CONNECT', TestString, Position) then
      begin
        Result := sConnect;
      end;
    'D', 'd': // May be drop,describe,declare
      if IsClause('DROP', TestString, Position) then
      begin
        Result := sDrop;
      end
      else if IsClause('DECLARE', TestString, Position) then
      begin
        Result := sDeclare;
      end
      else if IsClause('DESCRIBE', TestString, Position) then
      begin
        Result := sDescribe;
      end
      else if IsClause('DELETE', TestString, Position) then
      begin
        Result := sDML;
      end
      else if IsClause('DISCONNECT', TestString, Position) then
      begin
        Result := sDisconnect;
      end;

    'E', 'e':
      if IsClause('EXECUTE', TestString, Position) then
      begin
        Result := sExecute;
      end;
    'G', 'g':
      if IsClause('GRANT', TestString, Position) then
      begin
        Result := sGrant;
      end;
    'I', 'i': // may be Insert;
      if IsClause('INSERT', TestString, Position) then
      begin
        Result := sInsert;
      end
      else if IsClause('INPUT', TestString, Position) then
      begin
        Result := sRunFromFile;
      end;

    'M', 'm':
      if IsClause('MERGE', TestString, Position) then
      begin
        Result := sDML;
      end;
    'U', 'u':
      if IsClause('UPDATE', TestString, Position) then
      begin
        Result := sDML;
      end;
    'R', 'r':
      if IsClause('RECREATE', TestString, Position) then
      begin
        Result := sRecreate;
      end
      else if IsClause('ROLLBACK', TestString, Position) then
      begin
        Result := sRollBack;
      end
      else if IsClause('RECONNECT', TestString, Position) then
      begin
        Result := sReconnect;
      end
      else if IsClause('REVOKE', TestString, Position) then
      begin
        Result := sGrant;
      end
      else if IsClause('REINSERT', TestString, Position) then
      begin
        Result := sReinsert;
      end;
    'S', 's':
      if IsClause('SET', TestString, Position) then
      begin
        Result := sSet;
      end;
  end;
end;


// Blob File Supports

// A blob file reference is a parameter named H<offset>_<size>, both hexadecimal
function TryParseBlobReference(const ParamName: string; out Offset: Int64; out Size: Integer): Boolean;
var
  Separator: Integer;
  SizeValue: Int64;
begin
  Separator := Pos('_', ParamName);
  Result := (Length(ParamName) > 0) and CharInSet(ParamName[1], ['H', 'h']) and (Separator > 2) and
    TryHexToInt64(Copy(ParamName, 2, Separator - 2), Offset) and
    TryHexToInt64(Copy(ParamName, Separator + 1, MaxInt), SizeValue) and (SizeValue <= MaxInt);
  if Result then
    Size := Integer(SizeValue);
end;

procedure TFIBScripter.TryFillBlobParams;
var
  i, Size: Integer;
  Offset: Int64;
  Data: TMemoryStream;
begin
  for i := FQuery.ParamCount - 1 downto 0 do
    if TryParseBlobReference(FQuery.ParamName(i), Offset, Size) then
      if Size = 0 then
        FQuery.Params[i].Clear
      else
      begin
        Data := TMemoryStream.Create;
        try
          try
            if not Assigned(FBlobFileStream) then
              FBlobFileStream := TFileStream.Create(FBlobFile, fmOpenRead or fmShareDenyWrite);
            FBlobFileStream.Position := Offset;
            Data.CopyFrom(FBlobFileStream, Size);
          except
            on E: EStreamError do
              FIBError(feBlobFileError, [FBlobFile, FQuery.ParamName(i), E.Message]);
          end;
          FQuery.Params[i].LoadFromStream(Data);
        finally
          Data.Free;
        end;
      end;
end;

// Reinsert

function TFIBScripter.PrepareReinsert(const InsTxt, ReInsTxt: string): string;
var
  i, L: Integer;
  StartValues: Integer;
begin
  if FReinsertPrepared then
  begin
    Result := FLastInsertStatement + Copy(ReInsTxt, 9, MaxInt);
    Exit;
  end;

  StartValues := 0;
  L := Length(InsTxt);
  for i := 6 to L do
  begin
    case InsTxt[i] of
      'V', 'v':
        if IsClause('VALUES', InsTxt, i) then
          StartValues := i
    end;
  end;
  if (StartValues > 0) then
  begin
    FReinsertPrepared := True;
    FLastInsertStatement := Copy(InsTxt, 1, StartValues + 5);
    Result := FLastInsertStatement + Copy(ReInsTxt, 9, MaxInt)
  end
  else
    Result := ReInsTxt;
end;

// AutoExecBlock support
procedure TFIBScripter.RestartBlock;
begin
  FBlockStatementCount := 0;
  FBlockSize := 0;
  FExecBlockStatement.Clear;
end;

// Only inside a run, which flushes the block at its end. A user EXECUTE BLOCK or
// EXECUTE PROCEDURE is not nested into a block, nor RETURNING, which needs INTO in PSQL.
function TFIBScripter.CanGroupInExecuteBlock(const Stmt: TFIBStatementDesc): Boolean;
begin
  Result := FUseExecBlockForDML and (FRunDepth > 0) and (Stmt.smtType in [sInsert, sReinsert, sDML]) and
    not Stmt.HasReturning and not IsClause('EXECUTE', FParser.GetToken(Stmt.smdBegin), 1);
end;

// 0 when the text cannot be measured: the statement then runs alone and reports the error
function TFIBScripter.ExecuteBlockMaxSize(out CodePage: Word): Integer;
const
  cMaxSizeLegacy = High(Word);
  cMaxSizeFB3 = 10 * 1024 * 1024;
var
  DB: TFIBDatabase;
begin
  Result := 0;
  CodePage := FIBCodePageSystem;
  DB := FQuery.Database;
  if (DB = nil) or not DB.Connected then
    Exit;
  if not DisableEncodingSQLText then
    CodePage := DB.Capabilities.CodePage;
  if not IsCodePageAvailable(CodePage) then
    Exit;
  if DB.IsFirebirdConnect and (DB.ServerMajorVersion >= 3) and
    (DB.ClientLibrary.Version.Product = fpFirebird) and (DB.ClientLibrary.Version.Major >= 3) then
    Result := cMaxSizeFB3
  else
    Result := cMaxSizeLegacy;
end;

// False when the statement does not fit into the pending block
function TFIBScripter.AddStatementToExecuteBlock(const Stmt: TFIBStatementDesc;
  StmtNo, Line: Integer; SQLText: TStrings): Boolean;
const
  cHeader = 'EXECUTE BLOCK AS BEGIN';
  // the server allows 256 contexts (tables) in a statement
  cMaxStatements = 255;
var
  i, Size, L: Integer;
begin
  Size := FBlockSize;
  if FBlockStatementCount = 0 then
  begin
    FBlockMaxSize := ExecuteBlockMaxSize(FBlockCodePage) - Length('END') - 2;
    Size := Length(cHeader) + 2;
    if Size >= FBlockMaxSize then
    begin
      Result := False;
      Exit;
    end;
  end;
  L := 1; // ';'
  for i := 0 to SQLText.Count - 1 do
    Inc(L, EncodedLength(SQLText[i], FBlockCodePage) + 2);
  Result := (FBlockStatementCount < cMaxStatements) and (Size + L <= FBlockMaxSize);
  if not Result then
    Exit;
  if FBlockStatementCount = 0 then
    FExecBlockStatement.Add(cHeader);
  FExecBlockStatement.AddStrings(SQLText);
  i := FExecBlockStatement.Count - 1;
  FExecBlockStatement[i] := FExecBlockStatement[i] + ';';
  FBlockSize := Size + L;
  Inc(FBlockStatementCount);
  FBlockLastStmt := Stmt;
  FBlockLastStmtNo := StmtNo;
  FBlockLastLine := Line;
end;

end.
