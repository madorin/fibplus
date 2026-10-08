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

unit pFIBScripter;

interface

{$I FIBPlus.inc}
{$A2}

uses
  SysUtils, Classes, Types, FIBPlatforms, pFIBDatabase, pFIBQuery, FIBQuery,
  fib, pFIBInterfaces;

// {$DEFINE BEZBAZY}
type
  TStmtType = (
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
  TObjectType = (
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

  TStmtCoord = record
    X: Integer;
    Y: Integer;
  end;

  PStmtCoord = ^TStmtCoord;

  // smdEnd is the last character of the statement text, without the terminator,
  // blanks and comments after it. smdEnd.X=0 means the statement has no terminator
  // (only when ParseScript is called with IgnoreLastTerm=False)
  TStatementDesc = record
    smdBegin: TStmtCoord;
    smdEnd: TStmtCoord;
    smtType: TStmtType;
    objType: TObjectType;
    objName: string;
    DirectiveNum: Integer;
    DirectiveElse: boolean;
  end;

  PStatementDesc = ^TStatementDesc;

  TScriptMap = array of TStatementDesc;

  TOnParseStmt = procedure(Sender: TObject; StatementNo: Integer; Coord: TStatementDesc; SQLText: TStrings) of object;

  TDirectiveState = (dsUnknown, dsTrue, dsFalse);

  TDirectiveDesc = record
    dBegin: TStmtCoord;
    dConditionClose: TStmtCoord;
    dElse: TStmtCoord;
    dEnd: TStmtCoord;
    dState: TDirectiveState;
    OwnerDirectiveNum: Integer;
    OwnerDirectiveElse: boolean;
    dCondition: string; // text from dBegin to dConditionClose
  end;

  PDirectiveDesc = ^TDirectiveDesc;
  TDirectivesMap = array of TDirectiveDesc;
  PDirectivesMap = array of PDirectiveDesc;

  TParseDisposition = (pdBetweenStatements, pdInStatement, pdInDirective);
  TParserState = (psNormal, psInComment, psInQuote, psInDoubleQuote, psInQString, psInConditional);
  // Words that decide where a statement ends
  TScriptKeyword = (
    kwOther,
    kwAlter,
    kwAs,
    kwBegin,
    kwBlock,
    kwCase,
    kwCreate,
    kwEnd,
    kwExecute,
    kwExternal,
    kwFunction,
    kwOr,
    kwPackage,
    kwProcedure,
    kwRecreate,
    kwSet,
    kwTerm,
    kwTrigger
  );

  // Splits a script into statements in one pass. Lines are scanned as they are
  // added, so a script is parsed either as a whole or while it is read from a file.
  // Coordinates are script lines, the parser holds lines from FFirstLine on.
  TpFIBScriptParser = class
  private
    FScript: TStrings;
    FFirstLine: Integer;
    FNextLine: Integer;
    FTerminator: string;
    FTermFirst, FTermFirstLower: Char;
    // first char of FTerminator in both cases
    FStatements: TScriptMap;
    FStatementCount: Integer;
    // started statements, the last one may be incomplete
    FCompleteCount: Integer;
    FTakenCount: Integer; // complete statements returned by NextStatement
    FDirectives: TDirectivesMap;
    FDirectiveCount: Integer;
    FDirectiveStack: array of Integer;
    FCurDirective: Integer;
    FDisposition: TParseDisposition;
    FState: TParserState;
    FQuoteClose: Char;
    FLastSignificant: TStmtCoord; // last character out of blanks and comments
    // Structure of the current statement
    FWordCount: Integer;
    FHeader: array [0 .. 3] of TScriptKeyword; // first words
    FParenDepth: Integer;
    FMayHaveBody: boolean;
    // CREATE, ALTER, RECREATE or EXECUTE with the ";" terminator
    FExternal: boolean; // EXTERNAL module, without a PSQL body
    FInBody: boolean; // in the body of a PSQL module, after AS
    FBlockDepth: Integer; // BEGIN and CASE blocks open in the body
    FLastWordIsEnd: boolean;
    FInSetTerm: boolean;
    FNewTerminator: string;
    FNewTerminatorDone: boolean;
    // Details of the script
    FCurDBName: string;
    FMakeConnectInScript: boolean;
    FHaveDMLStatements: boolean;
    FHaveUnknownStatements: boolean;
    function Line(Y: Integer): string;
    procedure ScanLine(Y: Integer);
    function IsTerminatorAt(const S: string; X: Integer): boolean;
    function IsModuleHeader: boolean;
    procedure SetTerminator(const Value: string);
    procedure ProcessWord(const S: string; X, Len: Integer);
    procedure BeginStatement(X, Y: Integer; StmtType: TStmtType);
    procedure EndStatement;
    procedure EndSetTerm;
    procedure BeginDirective(X, Y: Integer);
    procedure CloseDirectiveCondition(X, Y: Integer);
    procedure ElseDirective(X, Y: Integer);
    procedure EndIfDirective(X, Y: Integer);
    function NextTokenPos(TokenPos: TStmtCoord; EndCoord: TStmtCoord): TStmtCoord;
    function GetToken(TokenPos: TStmtCoord; IgnoreQuote: boolean = True): string;
    procedure SearchObjectType(var stmtDesc: TStatementDesc; var BegSearch: TStmtCoord; ForGrant: boolean = False);
    procedure ValidateStatement(var stmtDesc: TStatementDesc);
    function StmtTypeNameToType(const TestString: string; Position: Integer): TStmtType;
    function TypeNameToObjectType(const TestString: string; Position: Integer): TObjectType;
  public
    procedure ParseScript(AScript: TStrings; var Terminator: string;
      var ScriptMap: TScriptMap; var DirectivesMap: TDirectivesMap;
      IgnoreLastTerm: boolean = True);
    // Incremental parsing: BeginParse, then Scan after lines are added to AScript,
    // NextStatement to take the complete statements and DiscardParsed to drop
    // them with their lines. EndParse completes the last statement.
    procedure BeginParse(AScript: TStrings; const Terminator: string);
    procedure Scan;
    procedure EndParse(IgnoreLastTerm: boolean);
    function NextStatement(var Stmt: PStatementDesc): boolean;
    procedure DiscardParsed;
    procedure CopyFragment(BegPos, EndPos: TStmtCoord; Dest: TStrings);
    property Terminator: string read FTerminator;
  end;

  TOnStatementExecute = procedure(Sender: TObject; Line: Integer;
    StatementNo: Integer; Desc: TStatementDesc; Statement: TStrings) of object;
  TOnSQLScriptExecError = procedure(Sender: TObject; StatementNo: Integer;
    Line: Integer; Statement: TStrings; SQLCode: Integer; const Msg: string;
    var doRollBack: boolean; var Stop: boolean) of object;

  TDynStringArray = array of Ansistring;

  // TDynStringArray= array of string;
  TpFIBScripter = class(TComponent, IFIBScripter)
  private
    FPrepared: boolean;
    FMakeConnectInScript: boolean;
    FParser: TpFIBScriptParser;
    FScript: TStrings;
    FScriptMap: TScriptMap;
    FLineCountInFile: Integer;
    FRunDepth: Integer; // nesting of ExecuteScript and ExecuteFromFile (INPUT)
    procedure DoOnChangeScript(Sender: TObject);
  private
    FDatabase: TpFIBDatabase;
    FTransaction: TpFIBTransaction;
    FQuery: TpFIBQuery;
    FPaused: boolean;
    FSkipStatement: boolean;
    FStopStatementNo: Integer;
    FSQLDialect: Integer;
    FLibraryName: string;
    FCharSet: string;
    FAutoDDL: boolean;
    FBlobFile: string;
    FBlobFileStream: TFileStream;
    vInternalDatabase: boolean;
    FExternalTransaction: TpFIBTransaction;
    FHaveDMLStatements: boolean;
    FHaveUnknownStatements: boolean;
    FNeedRestoreForceWrite: boolean;
    vReinsPrepared: boolean;
    vLastInsertStmt: string;
  private
    // AutoExecBlock support
    FUseExecBlockForDML: boolean;
    vBlockContextCount: Integer;
    vBlockSize: Integer;
    FExecBlockStatement: TStrings;
    procedure RestartBlock;
    procedure CloseBlock;
    function AddStatementToExecuteBlock(Stmt: TStrings): boolean;
  private
    FOnExecuteError: TOnSQLScriptExecError;
    FBeforeStatementExecute: TOnStatementExecute;
    FAfterStatementExecute: TOnStatementExecute;
    procedure SetDatabase(const Value: TpFIBDatabase);
    procedure SetTransaction(const Value: TpFIBTransaction);
    function GetTransaction: TpFIBTransaction;
    procedure DoReconnect;
    procedure SetConnectParams(StartToken: TStmtCoord; EndCoord: TStmtCoord);
    procedure TryFillBlobParams;
    function PrepareReinsert(const InsTxt, ReInsTxt: string): string;
    procedure BeginRun;
    procedure EndRun;
    procedure RunStatement(Stmt: PStatementDesc; StmtNo: Integer; StmtTxt: TStrings);
    function ExecuteParsed(var StmtNo: Integer; StmtTxt: TStrings): boolean;
    procedure FlushExecBlock;
  private
    // IB2007
    FInBatchCollect: boolean;
    FBatchSQLs: TDynStringArray;
    FInternalOnStatementExec: TOnScriptStatementExec;
    procedure SetOnStatExec(CallBack: TOnScriptStatementExec);
    // Directives
  private
    FDefines: TStrings;
    FDirectiveConsts: TStrings;
    procedure SetScript(const Value: TStrings);
    procedure SetDefines(const Value: TStrings);
    function DirectiveForbid(DirNum: Integer; InElse: boolean): boolean;
    function CalcDirective(Directive: TDirectiveDesc): TDirectiveState;
    function CalcExists(Condition: TStrings): TDirectiveState;
    function CalcIF(Condition: TStrings): TDirectiveState;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure CreateInternalDatabase;
    procedure CopyFragment(BegPos, EndPos: TStmtCoord; Dest: TStrings);
    procedure DoQueryExecute(SQL: TStrings; ParamValues: array of variant);

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Parse(Terminator: string = ';');
    procedure ExecuteScript(FromStmt: Integer = 1);
    procedure ExecuteFromFile(const FileName: string; Terminator: string = ';');
    procedure ExecuteStatement(StmtTxt: TStrings; Stmt: PStatementDesc; StmtNo: Integer; TmpSQL: TStrings = nil; LineInFile: Integer = -1);
    procedure ClearPrepared;
    function StatementsCount: Integer;
    function GetStatement(StmtNo: Integer; Text: TStrings): PStatementDesc;
    function LineCountInCurrentFile: Integer;

    procedure AddDefine(const Def: string);
    procedure DeleteDefine(const Def: string);
    procedure PreparePreDefines;
    property Prepared: boolean read FPrepared;
    property StopStatementNo: Integer read FStopStatementNo;
    property Query: TpFIBQuery read FQuery;
    property MakeConnectInScript: boolean read FMakeConnectInScript;
    property SkipStatement: boolean read FSkipStatement write FSkipStatement;
    property Paused: boolean read FPaused write FPaused;
    property Defines: TStrings read FDefines write SetDefines;
  published
    property Script: TStrings read FScript write SetScript;
    property Database: TpFIBDatabase read FDatabase write SetDatabase;
    property Transaction: TpFIBTransaction read FExternalTransaction write SetTransaction;
    property OnExecuteError: TOnSQLScriptExecError read FOnExecuteError write FOnExecuteError;
    property AutoDDL: boolean read FAutoDDL write FAutoDDL default True;
    property BeforeStatementExecute: TOnStatementExecute read FBeforeStatementExecute write FBeforeStatementExecute;
    property AfterStatementExecute: TOnStatementExecute read FAfterStatementExecute write FAfterStatementExecute;
    property UseExecBlockForDML: boolean read FUseExecBlockForDML write FUseExecBlockForDML default False;
  end;

function StatementTypeName(tn: TStmtType): string;

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

implementation

uses
  StrUtil, SqlTxtRtns, StdFuncs;
{ TpFIBScripter }

procedure RaiseParserDirectiveError(const DirName: string; Line: Integer);
begin
  raise Exception.Create('Parse script error.' + CLRF + 'Can''t resolve directive  "' + DirName + '"' + CLRF + 'Line ' +
    IntToStr(Line));
end;

function StatementTypeName(tn: TStmtType): string;
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

function StmtCoord(X, Y: Integer): TStmtCoord; {$IFDEF D2009+}inline; {$ENDIF}
begin
  Result.X := X;
  Result.Y := Y;
end;

function IsClause(const EtalonClause: string; const Source: string; Position: Integer): boolean;
// EtalonClause must be if UpperCase
var
  Len: Integer;
  LenEtalon: Byte;
  pSource: PChar;
  pEtalon: PChar;
  pEtalon1: PChar;
begin
  Len := Length(Source);
  LenEtalon := Length(EtalonClause);
  if Len - Position + 1 < LenEtalon then
    Result := False
  else
  begin
    pSource := Pointer(Source);
    Inc(pSource, Position - 1);
    pEtalon := Pointer(EtalonClause);
    pEtalon1 := Pointer(EtalonClause);
    Inc(pEtalon1, LenEtalon);
    Result := True;
    while (pEtalon <> pEtalon1) do
    begin
      if pSource^ <> pEtalon^ then
      begin
        if Byte(pSource^) - 32 <> Byte(pEtalon^) then
        begin
          Result := False;
          Break;
        end;
      end;
      Inc(pSource);
      Inc(pEtalon);
    end;
    if Result and (Len - Position >= LenEtalon) then
      Result := Source[Position + LenEtalon] in [' ', #13, #9, #10, '/', '-', ';', '^', ',', '}']
  end
end;

function StrIsIfDirective(const CheckStr: string; X: Integer): boolean;
begin
  { dIfDef='{$IFDEF';
    dIfNDef='{$IFNDEF';
    dIf    ='{$IF';
    dIfExists  ='{$IFEXISTS';
    dIfNExists  ='{$IFNEXISTS';
    dIfNotExists  ='{$IFNOTEXISTS';
  }
  Result := IsClause(dIfDef, CheckStr, X) or IsClause(dIfNDef, CheckStr, X) or
    IsClause(dIf, CheckStr, X) or IsClause(dIfExists, CheckStr, X) or
    IsClause(dIfNExists, CheckStr, X) or IsClause(dIfNotExists, CheckStr, X)

end;

procedure TpFIBScripter.ClearPrepared;
begin
  SetLength(FScriptMap, 0);
  FPrepared := False;
end;

procedure TpFIBScripter.CopyFragment(BegPos, EndPos: TStmtCoord; Dest: TStrings);
begin
  FParser.CopyFragment(BegPos, EndPos, Dest);
end;

constructor TpFIBScripter.Create(AOwner: TComponent);
begin
  inherited;
  // FUseExecBlockForDML:=True;
  FScript := TStringList.Create;
  TStringList(FScript).OnChanging := DoOnChangeScript;
  FParser := TpFIBScriptParser.Create;

  FDefines := TStringList.Create;
  FDirectiveConsts := TStringList.Create;
  // FDirectiveConsts.Add('A= 11');
  FTransaction := TpFIBTransaction.Create(Self);
  FQuery := TpFIBQuery.Create(Self);
  FQuery.Transaction := FTransaction;
  FSQLDialect := 3;
  FAutoDDL := True;
end;

procedure TpFIBScripter.CreateInternalDatabase;
begin
  if not Assigned(FDatabase) then
  begin
    Database := TpFIBDatabase.Create(Self);
    vInternalDatabase := True
  end
end;

destructor TpFIBScripter.Destroy;
begin
  FParser.Free;
  FScript.Free;
  FDefines.Free;
  FDirectiveConsts.Free;
  SetLength(FScriptMap, 0);
  if Assigned(FExecBlockStatement) then
    FExecBlockStatement.Free;
  if Assigned(FBlobFileStream) then
    FBlobFileStream.Free;
  inherited;
end;

procedure TpFIBScripter.DoOnChangeScript(Sender: TObject);
begin
  ClearPrepared
end;

procedure TpFIBScripter.DoQueryExecute(SQL: TStrings; ParamValues: array of variant);
begin

end;

procedure TpFIBScripter.DoReconnect;
begin
  if Assigned(FDatabase) then
  begin
    if GetTransaction.InTransaction then
      GetTransaction.Commit;
    FDatabase.Connected := False;
    FDatabase.Connected := True
  end;
end;

function TpFIBScripter.CalcIF(Condition: TStrings): TDirectiveState;
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
    if tmpStr[i] in [' ', #9, #13, #10] then
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
        if (Expr[i] in [' ', #9, #10, #13]) then
        begin
          cName := UpperCase(Copy(Expr, 1, i - 1));
          while (i <= Length(Expr)) and (Expr[i] in [' ', #9, #10, #13]) do
            Inc(i);
          if (i > Length(Expr)) or not(Expr[i] in ['=', '>', '<']) then
            raise Exception.Create('Parse script error.' + CLRF + 'Can''t resolve condition  "$IF"' + CLRF + Expr);
          State := sOperator;
        end
        else if (Expr[i] in ['=', '>', '<']) then
        begin
          cName := UpperCase(Copy(Expr, 1, i - 1));
          State := sOperator;
        end
        else
          Inc(i);
      sOperator:
        if (Expr[i] in ['=', '>', '<']) then
        begin
          cOper := cOper + Expr[i];
          Inc(i)
        end
        else
          State := sValue;
      sValue:
        begin
          while (i <= Length(Expr)) and (Expr[i] in [' ', #9, #10, #13]) do
            Inc(i);
          cValue := Copy(Expr, i, MaxInt);
          Break;
        end;
    end;
  end;
  //
  Value := FDirectiveConsts.Values[cName];
  if Trim(Value) = '' then
    raise Exception.Create('Parse script error.' + CLRF + 'Constant don''t exists' + CLRF + cName);

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
      {$IFDEF D_XE3}FormatSettings.{$ENDIF} DecimalSeparator, []);
    Value := StringReplace(Value, ',',
      {$IFDEF D_XE3}FormatSettings.{$ENDIF} DecimalSeparator, []);
    cValue := StringReplace(cValue, '.',
      {$IFDEF D_XE3}FormatSettings.{$ENDIF} DecimalSeparator, []);
    cValue := StringReplace(cValue, ',',
      {$IFDEF D_XE3}FormatSettings.{$ENDIF} DecimalSeparator, []);

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

function TpFIBScripter.CalcExists(Condition: TStrings): TDirectiveState;
var
  CheckExists: boolean;
  i, L: Integer;
  tmpStr: string;
  chObjectType: TObjectType;
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
    if tmpStr[i] in [' ', #9, #13, #10] then
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

{$IFNDEF BEZBAZY}
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
{$ENDIF}
  end
  else if IsClause('SELECT', tmpStr, 1) then
  begin
    chQryTxt := tmpStr;
    SetLength(chQryTxt, Length(chQryTxt) - 1);

{$IFNDEF BEZBAZY}
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
{$ENDIF}
  end;

end;

function TpFIBScripter.CalcDirective(Directive: TDirectiveDesc): TDirectiveState;
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

function TpFIBScripter.DirectiveForbid(DirNum: Integer; InElse: boolean): boolean;
var
  Directives: TDirectivesMap; // of the script being executed
  NeedCalc: PDirectivesMap;
  i, j: Integer;
  vInElse: boolean;
begin
  Directives := FParser.FDirectives;
  if (DirNum >= 0) and (DirNum < FParser.FDirectiveCount) then
  begin
    case Directives[DirNum].dState of
      dsTrue: Result := not InElse;
      dsFalse: Result := InElse;
    else
      // dsUnknown
      begin
        Result := True;
        SetLength(NeedCalc, 1000);
        i := 0;
        j := DirNum;
        while (j > -1) and (Directives[j].dState = dsUnknown) do
        begin
          NeedCalc[i] := @Directives[j];
          j := Directives[j].OwnerDirectiveNum;
          Inc(i)
        end;
        SetLength(NeedCalc, i);
        Dec(i);
        //
        if j > -1 then
        begin
          Result := (Directives[j].dState = dsTrue) xor (NeedCalc[i].OwnerDirectiveElse);
        end;

        //

        while (i >= 0) and Result do
        begin
          if i > 0 then
            vInElse := NeedCalc[i - 1].OwnerDirectiveElse
          else
            vInElse := InElse;
          NeedCalc[i].dState := CalcDirective(NeedCalc[i]^);
          Result := (NeedCalc[i].dState = dsTrue) xor vInElse;
          Dec(i)
        end;
        if not Result then
          if InElse then
            Directives[DirNum].dState := dsTrue
          else
            Directives[DirNum].dState := dsFalse;
      end;
    end;
  end
  else
    Result := True
end;

procedure TpFIBScripter.ExecuteStatement(StmtTxt: TStrings;
  Stmt: PStatementDesc; StmtNo: Integer; TmpSQL: TStrings = nil;
  LineInFile: Integer = -1);
var
  vToken: TStmtCoord;
  tmpStr, tmpStr1: string;
  vIsInternalTmpSQL: boolean;
  doRollBack: boolean;
  MayBeInBlock: boolean;
  skip: boolean;
  i: Integer;

  procedure ApplyCommand;
  begin
    try
{$IFNDEF BEZBAZY}
      if not GetTransaction.InTransaction then
        GetTransaction.StartTransaction;
      if Length(FBlobFile) > 0 then
        if (FQuery.ParamCount > 0) then
          TryFillBlobParams;
      FQuery.ExecQuery;
      if Assigned(FInternalOnStatementExec) then
      begin
        if LineInFile = -1 then
          FInternalOnStatementExec(Stmt.smdBegin.Y + 1, StmtNo + 1)
        else
        begin
          FInternalOnStatementExec(LineInFile, StmtNo + 1);
        end;
      end;

      if Assigned(FAfterStatementExecute) then
      begin
        if LineInFile = -1 then
          FAfterStatementExecute(Self, Stmt.smdBegin.Y + 1, StmtNo + 1, Stmt^, StmtTxt)
        else
        begin
          FAfterStatementExecute(Self, LineInFile, StmtNo + 1, Stmt^, StmtTxt);
        end;
      end;
      if FAutoDDL and (FQuery.SQLKind = skDDL) then
        FQuery.Transaction.Commit;
{$ENDIF}
    except
      on E: EFIBError do
      begin
        if Assigned(FOnExecuteError) then
        begin
          FPaused := True;
          doRollBack := True;
          FOnExecuteError(Self, StmtNo + 1, Stmt.smdBegin.Y + 1, TmpSQL, E.SQLCode, E.Message, doRollBack, FPaused);
          if doRollBack then
            GetTransaction.Rollback;
        end
        else
          raise;
      end
    end;
  end;

begin
  if Stmt <> nil then
  begin
    if FQuery.Open then
      FQuery.Close;
    if TmpSQL = nil then
    begin
      vIsInternalTmpSQL := True;
      TmpSQL := TStringList.Create;
    end
    else
      vIsInternalTmpSQL := False;
    try
      if Stmt.DirectiveNum >= 0 then
      begin
        SkipStatement := not DirectiveForbid(Stmt.DirectiveNum, Stmt.DirectiveElse);
      end
      else
        SkipStatement := False;
      if not SkipStatement then
        if Assigned(FBeforeStatementExecute) then
          if LineInFile = -1 then
            FBeforeStatementExecute(Self, Stmt.smdBegin.Y + 1, StmtNo + 1, Stmt^, StmtTxt)
          else
          begin
            FBeforeStatementExecute(Self, LineInFile, StmtNo + 1, Stmt^, StmtTxt);
          end;
      if SkipStatement then
        Exit;
      MayBeInBlock := FUseExecBlockForDML and (Stmt.smtType in [sReinsert, sInsert, sDML]);

      if FUseExecBlockForDML and not MayBeInBlock then
        if Assigned(FExecBlockStatement) and (vBlockSize > 0) then
        begin
          CloseBlock;
          FQuery.SQL := FExecBlockStatement; // SQL statement
          RestartBlock;
          ApplyCommand;
        end;

      case Stmt.smtType of
        sCreateDatabase:
          begin
            CreateInternalDatabase;
            vToken := FParser.NextTokenPos(Stmt.smdBegin, Stmt.smdEnd);
            vToken := FParser.NextTokenPos(vToken, Stmt.smdEnd);
            if FDatabase.Connected then
              FDatabase.Close;

            FDatabase.DBName := FParser.GetToken(vToken);
            vToken := FParser.NextTokenPos(vToken, Stmt.smdEnd);
            CopyFragment(vToken, Stmt.smdEnd, FDatabase.DBParams);
            FDatabase.SQLDialect := FSQLDialect;
            if FLibraryName <> '' then
              FDatabase.LibraryName := FLibraryName;
{$IFNDEF BEZBAZY}
            try
              FDatabase.CreateDatabase;
              PreparePreDefines;
              if FDatabase.NeedUTFEncodeDDL
              // and (FHaveDMLStatements or FHaveUnknownStatements)
              then
              begin
                if FDatabase.Capabilities.AttachmentCharSetID = 0 then
                begin
                  FDatabase.Connected := False;
                  SetConnectParams(vToken, Stmt.smdEnd);
                  FDatabase.DBParams.Add('force_write=0');
                  FNeedRestoreForceWrite := True;
                  FDatabase.Connected := True;
                end
              end;
            except
              on E: EFIBError do
              begin
                if Assigned(FOnExecuteError) then
                begin
                  FPaused := True;
                  FOnExecuteError(Self, StmtNo + 1, Stmt.smdBegin.Y + 1, TmpSQL,
                    E.SQLCode, E.Message, doRollBack, FPaused);
                end
                else
                  raise;
              end;
            end
{$ENDIF}
          end;
        sDropDatabase:
          begin
            CreateInternalDatabase;
            vToken := FParser.NextTokenPos(Stmt.smdBegin, Stmt.smdEnd);
            vToken := FParser.NextTokenPos(vToken, Stmt.smdEnd);
            if FDatabase.Connected then
              FDatabase.Close;
            if FLibraryName <> '' then
              FDatabase.LibraryName := FLibraryName;
            FDatabase.DBName := FParser.GetToken(vToken);
            vToken := FParser.NextTokenPos(vToken, Stmt.smdEnd);
            tmpStr := FParser.GetToken(vToken);
            if IsClause('USER', tmpStr, 1) then
            begin
              vToken := FParser.NextTokenPos(vToken, Stmt.smdEnd);
              tmpStr := FParser.GetToken(vToken);
              FDatabase.ConnectParams.UserName := tmpStr;
            end
            else if IsClause('PASSWORD', tmpStr, 1) then
            begin
              vToken := FParser.NextTokenPos(vToken, Stmt.smdEnd);
              tmpStr := FParser.GetToken(vToken);
              FDatabase.ConnectParams.Password := tmpStr;
            end;

            vToken := FParser.NextTokenPos(vToken, Stmt.smdEnd);
            tmpStr := FParser.GetToken(vToken);
            if IsClause('USER', tmpStr, 1) then
            begin
              vToken := FParser.NextTokenPos(vToken, Stmt.smdEnd);
              tmpStr := FParser.GetToken(vToken);
              FDatabase.ConnectParams.UserName := tmpStr;
            end
            else if IsClause('PASSWORD', tmpStr, 1) then
            begin
              vToken := FParser.NextTokenPos(vToken, Stmt.smdEnd);
              tmpStr := FParser.GetToken(vToken);
              FDatabase.ConnectParams.Password := tmpStr;
            end;

            FDatabase.Connected := True;
            FDatabase.DropDatabase;
          end;
        sDisconnect: FDatabase.Connected := False;
        sConnect:
          begin
            CreateInternalDatabase;
            try
              if FDatabase.Connected then
                FDatabase.Close;
              vToken := FParser.NextTokenPos(Stmt.smdBegin, Stmt.smdEnd);
              FDatabase.DBName := FParser.GetToken(vToken);
              vToken := FParser.NextTokenPos(vToken, Stmt.smdEnd);
              SetConnectParams(vToken, Stmt.smdEnd);
              FDatabase.Connected := True;

              PreparePreDefines;
            except
              on E: EFIBError do
              begin
                if Assigned(FOnExecuteError) then
                begin
                  FPaused := True;
                  FOnExecuteError(Self, StmtNo + 1, Stmt.smdBegin.Y + 1, TmpSQL,
                    E.SQLCode, E.Message, doRollBack, FPaused);
                end
                else
                  raise;
              end;
            end
          end;
        sCommit:
          if GetTransaction.InTransaction then
            try
              GetTransaction.Commit;
            except
              on E: EFIBError do
              begin
                if Assigned(FOnExecuteError) then
                begin
                  FPaused := True;
                  FOnExecuteError(Self, StmtNo + 1, Stmt.smdBegin.Y + 1, TmpSQL,
                    E.SQLCode, E.Message, doRollBack, FPaused);
                  if GetTransaction.InTransaction then
                    GetTransaction.Rollback
                end
                else
                  raise;
              end;
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
                  RaiseParserDirectiveError(dExecBlock, Stmt.smdBegin.Y);
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
                // tmpStr:=UpperCase(Trim(tmpStr));
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
                raise Exception.Create('Unknown directive :' + CLRF + 'Line ' +
                  IntToStr(Stmt.smdBegin.Y) + CLRF + TmpSQL.Text);

          end;
        sRollBack:
          if GetTransaction.InTransaction then
            GetTransaction.Rollback;
        sSet:
          begin
            vToken := FParser.NextTokenPos(Stmt.smdBegin, Stmt.smdEnd);
            if vToken.X > 0 then
            begin
              tmpStr := FParser.GetToken(vToken);
              if IsClause('AUTODDL', tmpStr, 1) then
              begin
                vToken := FParser.NextTokenPos(vToken, Stmt.smdEnd);
                if (vToken.X > 0) then
                begin
                  tmpStr := FParser.GetToken(vToken);
                  if IsClause('ON', tmpStr, 1) then
                    FAutoDDL := True
                  else if IsClause('OFF', tmpStr, 1) then
                    FAutoDDL := False
                end
              end
              else if IsClause('SQL', tmpStr, 1) then
              begin
                vToken := FParser.NextTokenPos(vToken, Stmt.smdEnd);
                if (vToken.X > 0) then
                begin
                  tmpStr := FParser.GetToken(vToken);
                  if IsClause('DIALECT', tmpStr, 1) then
                  begin
                    vToken := FParser.NextTokenPos(vToken, Stmt.smdEnd);
                    if (vToken.X > 0) then
                    begin
                      tmpStr := FParser.GetToken(vToken);
                      FSQLDialect := StrToInt(tmpStr)
                    end;
                  end;
                end;
              end
              else if IsClause('NAMES', tmpStr, 1) then
              begin
                vToken := FParser.NextTokenPos(vToken, Stmt.smdEnd);
                if (vToken.X > 0) then
                begin
                  FCharSet := FParser.GetToken(vToken);
                end
              end
              else // CLIENTLIB
                if IsClause('CLIENTLIB', tmpStr, 1) then
                begin
                  vToken := FParser.NextTokenPos(vToken, Stmt.smdEnd);
                  if vToken.X <> 0 then
                  begin
                    tmpStr := FParser.GetToken(vToken);
                    FLibraryName := FParser.GetToken(vToken);
                  end
                end
                else if IsClause('BLOBFILE', tmpStr, 1) then
                begin
                  vToken := FParser.NextTokenPos(vToken, Stmt.smdEnd);
                  if (vToken.X > 0) then
                  begin
                    if Assigned(FBlobFileStream) then
                    begin
                      FBlobFileStream.Free;
                      FBlobFileStream := nil;
                    end;
                    FBlobFile := FParser.GetToken(vToken);
                  end
                end;
            end;
          end;
        sReconnect:
          begin
{$IFNDEF BEZBAZY}
            DoReconnect;
{$ENDIF}
          end;
        sDescribe:
          begin
            vToken := FParser.NextTokenPos(Stmt.smdBegin, Stmt.smdEnd);
            if (vToken.X > 0) then
            begin
              TmpSQL.Clear;
              case Stmt.objType of
                otDomain:
                  TmpSQL.Add
                    ('UPDATE RDB$FIELDS SET RDB$DESCRIPTION = :DESCR WHERE (RDB$FIELD_NAME = :FIELD)');
                otView, otTable:
                  begin
                    TmpSQL.Add
                      ('UPDATE RDB$RELATIONS SET RDB$DESCRIPTION = :DESCR ' + 'WHERE RDB$RELATION_NAME = :TABNAME');
                  end;
                otTrigger:
                  TmpSQL.Add
                    ('UPDATE RDB$TRIGGERS SET RDB$DESCRIPTION = :DESCR WHERE (RDB$TRIGGER_NAME = :TR_NAME)');
                otField:
                  TmpSQL.Add
                    ('UPDATE RDB$RELATION_FIELDS SET RDB$DESCRIPTION = :DESCR ' +
                      'WHERE (RDB$RELATION_NAME = :TABNAME) and (RDB$FIELD_NAME = :FIELD)');
                otParameter:
                  TmpSQL.Add
                    ('UPDATE RDB$PROCEDURE_PARAMETERS SET RDB$DESCRIPTION = :DESCR ' +
                      'WHERE (RDB$PROCEDURE_NAME = :PROCNAME) and(RDB$PARAMETER_NAME = :FIELD)');
                otProcedure:
                  TmpSQL.Add
                    ('UPDATE RDB$PROCEDURES SET RDB$DESCRIPTION = :DESCR ' + 'WHERE (RDB$PROCEDURE_NAME = :PROCNAME)');

                otException:
                  TmpSQL.Add
                    ('UPDATE RDB$EXCEPTIONS SET RDB$DESCRIPTION = :DESCR ' + 'WHERE (RDB$EXCEPTION_NAME = :EXC_NAME)');
                otFunction:
                  TmpSQL.Add
                    ('update RDB$FUNCTIONS set RDB$DESCRIPTION = ?DESC where (RDB$FUNCTION_NAME = ?FUNC_NAME)');
                otUDF:
                  TmpSQL.Add
                    ('update RDB$FUNCTIONS set RDB$DESCRIPTION = ?DESC where (RDB$FUNCTION_NAME = ?FUNC_NAME)');

                otGenerator:
                  TmpSQL.Add
                    ('update RDB$GENERATORS SET RDB$DESCRIPTION = ?DESC where (RDB$GENERATOR_NAME = ?GEN_NAME)');
                otPackage:
                  TmpSQL.Add('UPDATE RDB$PACKAGES SET RDB$DESCRIPTION = :DESCR ' +
                    'WHERE (RDB$PACKAGE_NAME = :PACKAGENAME)');

              else
                tmpStr := FParser.GetToken(vToken);
                raise Exception.Create('Unsupported DESCRIBE type ' + tmpStr)
                // mark as invalid later
              end;

              vToken := FParser.NextTokenPos(vToken, Stmt.smdEnd);
              // Object Name
              tmpStr := FParser.GetToken(vToken); // Object Name

              FQuery.SQL.Assign(TmpSQL);

              if Stmt.objType in [otField, otParameter] then
              begin
                FQuery.Params[2].AsString := tmpStr; // Parameter name;
                vToken := FParser.NextTokenPos(vToken, Stmt.smdEnd);
                // Owner object type
                vToken := FParser.NextTokenPos(vToken, Stmt.smdEnd);
                // Owner object name
                FQuery.Params[1].AsString := FParser.GetToken(vToken);
              end
              else
                FQuery.Params[1].AsString := tmpStr; // Object Name
              vToken := FParser.NextTokenPos(vToken, Stmt.smdEnd);

              CopyFragment(vToken, Stmt.smdEnd, TmpSQL);
              FQuery.Params[0].AsString := AnsiDequotedStr(TmpSQL.Text, '''');
{$IFNDEF BEZBAZY}
              if not GetTransaction.InTransaction then
                GetTransaction.StartTransaction;
              FQuery.ExecQuery;
{$ENDIF}
            end;
          end;
        sRunFromFile:
          begin
            vToken := FParser.NextTokenPos(Stmt.smdBegin, Stmt.smdEnd);
            // FileName
            tmpStr := FParser.GetToken(vToken); // FileName
            ExecuteFromFile(tmpStr)
          end;
      else
        case Stmt.smtType of
          sInsert:
            begin
              vLastInsertStmt := TmpSQL.Text;
              vReinsPrepared := False;
            end;
          sReinsert: TmpSQL.Text := PrepareReinsert(vLastInsertStmt, TmpSQL.Text);
        end;

        FQuery.SQL := TmpSQL; // SQL statement
        skip := False;

        if FUseExecBlockForDML and MayBeInBlock then
          if ((Length(FBlobFile) = 0) or (FQuery.ParamCount = 0)) then
          begin
            skip := AddStatementToExecuteBlock(TmpSQL);
            if not skip then
            begin
              FQuery.SQL := FExecBlockStatement; // Force exec block
              RestartBlock;
              AddStatementToExecuteBlock(TmpSQL);
            end
          end
          else // DML with params
            if Assigned(FExecBlockStatement) and (vBlockSize > 0) then
            begin
              CloseBlock;
              FQuery.SQL := FExecBlockStatement; // Force exec block
              RestartBlock;
              ApplyCommand;
              FQuery.SQL := TmpSQL; // Current SQL statement
            end;

        if not skip then
          ApplyCommand
          //
      end;
    finally
      if vIsInternalTmpSQL then
        TmpSQL.Free
    end
  end;
end;

// Called in a try block with EndRun in finally, so FRunDepth stays balanced
procedure TpFIBScripter.BeginRun;
begin
  FPaused := False;
  Inc(FRunDepth);
  if FRunDepth = 1 then
  begin
    vLastInsertStmt := '';
    vReinsPrepared := False;
    FSQLDialect := 3;
    FCharSet := '';
    PreparePreDefines;
  end;
end;

procedure TpFIBScripter.EndRun;
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

  if vInternalDatabase then
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

procedure TpFIBScripter.RunStatement(Stmt: PStatementDesc; StmtNo: Integer; StmtTxt: TStrings);
begin
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
{$IFDEF SUPPORT_IB2007}
        FQuery.ExecuteAsBatch(FBatchSQLs);
{$ELSE}
        raise Exception.Create('Batch execute support for IB2007 only');
{$ENDIF}
        SetLength(FBatchSQLs, 0);
      end;
  else
    if not FInBatchCollect then
      ExecuteStatement(StmtTxt, Stmt, StmtNo, StmtTxt)
    else
    begin
      SetLength(FBatchSQLs, Length(FBatchSQLs) + 1);
      FBatchSQLs[Length(FBatchSQLs) - 1] := StmtTxt.Text;
    end;
  end;
end;

procedure TpFIBScripter.FlushExecBlock;
begin
  if FUseExecBlockForDML and Assigned(FExecBlockStatement) and (vBlockSize > 0) then
  begin
    CloseBlock;
    FQuery.SQL := FExecBlockStatement; // Force execute block
    RestartBlock;
    if not GetTransaction.InTransaction then
      GetTransaction.StartTransaction;
    FQuery.ExecQuery;
  end;
end;

procedure TpFIBScripter.ExecuteScript(FromStmt: Integer = 1);
var
  i: Integer;
  TmpSQL: TStrings;
begin
  if not FPrepared then
    Parse
  else if FromStmt <= 1 then
  // conditions are evaluated again, a resumed run keeps them
    for i := 0 to FParser.FDirectiveCount - 1 do
      FParser.FDirectives[i].dState := dsUnknown;

  TmpSQL := TStringList.Create;
  try
    BeginRun;
    for i := FromStmt - 1 to StatementsCount - 1 do
    begin
      if FPaused then
      begin
        FStopStatementNo := i + 1;
        Exit;
      end;
      RunStatement(GetStatement(i + 1, TmpSQL), i, TmpSQL);
    end;
    if FRunDepth = 1 then
      FlushExecBlock;
  finally
    try
      EndRun;
    finally
      TmpSQL.Free;
    end;
  end;
end;

function TpFIBScripter.GetStatement(StmtNo: Integer; Text: TStrings): PStatementDesc;
begin
  if StmtNo > Length(FScriptMap) then
    raise Exception.Create('Statement #' + IntToStr(StmtNo) + ' don''t exist');
  Result := @FScriptMap[StmtNo - 1];
  CopyFragment(Result.smdBegin, Result.smdEnd, Text);
end;

procedure TpFIBScripter.Notification(AComponent: TComponent; Operation: TOperation);
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

procedure TpFIBScripter.Parse(Terminator: string = ';');
var
  Directives: TDirectivesMap; // the parser keeps them for DirectiveForbid
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

procedure TpFIBScripter.SetDatabase(const Value: TpFIBDatabase);
begin
  if GetTransaction.InTransaction then
    GetTransaction.Commit;

  if Assigned(FDatabase) then
    if vInternalDatabase and ((Value = nil) or (Value.Owner <> Self)) then
    // Old database -  InternalDatabase
    begin
      FDatabase.Free;
      vInternalDatabase := False;
    end;
  FDatabase := Value;
  if Assigned(FDatabase) then
    FreeNotification(FDatabase);
  FTransaction.DefaultDatabase := FDatabase;
  if Assigned(FExternalTransaction) then
    FExternalTransaction.DefaultDatabase := FDatabase;
  FQuery.Database := FDatabase;
  FQuery.Transaction := GetTransaction;

end;

procedure TpFIBScripter.SetScript(const Value: TStrings);
begin
  FScript.Assign(Value);
end;

procedure TpFIBScripter.SetDefines(const Value: TStrings);
var
  i: Integer;
begin
  FDefines.Clear;
  if Value <> nil then
    for i := 0 to Value.Count - 1 do
      if FDefines.IndexOf(UpperCase(Value[i])) < 0 then
        FDefines.Add(UpperCase(Value[i]))
end;

procedure TpFIBScripter.AddDefine(const Def: string);
begin
  if FDefines.IndexOf(UpperCase(Def)) < 0 then
    FDefines.Add(UpperCase(Def))
end;

procedure TpFIBScripter.DeleteDefine(const Def: string);
var
  i: Integer;
begin
  i := FDefines.IndexOf(UpperCase(Def));
  if i >= 0 then
    FDefines.Delete(i)
end;

procedure TpFIBScripter.PreparePreDefines;
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

procedure TpFIBScripter.SetConnectParams(StartToken: TStmtCoord; EndCoord: TStmtCoord);
var
  vToken: TStmtCoord;
  tmpStr: String;
begin
  FDatabase.Connected := False;
  FDatabase.DBParams.Clear;
  vToken := StartToken;
  while (vToken.X <> 0) do
  begin
    tmpStr := FParser.GetToken(vToken);
    if IsClause('USER', tmpStr, 1) then
    begin
      vToken := FParser.NextTokenPos(vToken, EndCoord);
      if vToken.X <> 0 then
        FDatabase.ConnectParams.UserName := FParser.GetToken(vToken);
    end
    else if IsClause('PASSWORD', tmpStr, 1) then
    begin
      vToken := FParser.NextTokenPos(vToken, EndCoord);
      if vToken.X <> 0 then
        FDatabase.ConnectParams.Password := FParser.GetToken(vToken);
    end
    else if IsClause('ROLE', tmpStr, 1) then
    begin
      vToken := FParser.NextTokenPos(vToken, EndCoord);
      if vToken.X <> 0 then
        FDatabase.ConnectParams.RoleName := FParser.GetToken(vToken);
    end
    else if IsClause('SET', tmpStr, 1) then
    begin
      vToken := FParser.NextTokenPos(vToken, EndCoord);
      if vToken.X <> 0 then
      begin
        tmpStr := FParser.GetToken(vToken);
        if IsClause('CHARACTER', tmpStr, 1) then
        begin
          vToken := FParser.NextTokenPos(vToken, EndCoord);
          if vToken.X <> 0 then
          begin
            tmpStr := FParser.GetToken(vToken);
            FDatabase.ConnectParams.CharSet := FParser.GetToken(vToken);
          end
        end
      end
    end;
    if vToken.X <> 0 then
      vToken := FParser.NextTokenPos(vToken, EndCoord);
  end;
  FDatabase.SQLDialect := FSQLDialect;
  if FLibraryName <> '' then
    FDatabase.LibraryName := FLibraryName;
  FDatabase.ConnectParams.CharSet := FCharSet;
end;

function TpFIBScripter.StatementsCount: Integer;
begin
  Result := Length(FScriptMap)
end;

function GetLineCountInFile(const FileName: string): Integer;
var
  F: TextFile;
begin
  Result := 0;
  AssignFile(F, FileName);
  Reset(F);
  try
    repeat
      ReadLn(F);
      Inc(Result)
    until Eof(F);
  finally
    CloseFile(F);
  end;
end;

// Executes the complete statements of the current parser, False when paused
function TpFIBScripter.ExecuteParsed(var StmtNo: Integer; StmtTxt: TStrings): boolean;
var
  Stmt: PStatementDesc;
begin
  Result := True;
  while FParser.NextStatement(Stmt) do
  begin
    if FPaused then
    begin
      FStopStatementNo := StmtNo + 1;
      Result := False;
      Exit;
    end;
    FParser.CopyFragment(Stmt.smdBegin, Stmt.smdEnd, StmtTxt);
    RunStatement(Stmt, StmtNo, StmtTxt);
    Inc(StmtNo);
  end;
end;

// The file is parsed while it is read and every statement is executed as soon
// as it is complete, so only the lines of the current statement are kept.
procedure TpFIBScripter.ExecuteFromFile(const FileName: string; Terminator: string = ';');
var
  F: TextFile;
  S: string;
  Lines, TmpSQL: TStrings;
  SavedParser: TpFIBScriptParser;
  StmtNo: Integer;
begin
  FLineCountInFile := GetLineCountInFile(FileName);
  AssignFile(F, FileName);
  Reset(F);
  Lines := TStringList.Create;
  TmpSQL := TStringList.Create;
  SavedParser := FParser;
  FParser := TpFIBScriptParser.Create;
  try
    BeginRun;
    FParser.BeginParse(Lines, Terminator);
    StmtNo := 0;
    while not Eof(F) do
    begin
      ReadLn(F, S);
      Lines.Add(S);
      FParser.Scan;
      if not ExecuteParsed(StmtNo, TmpSQL) then
        Exit;
      FParser.DiscardParsed;
    end;
    FParser.EndParse(True);
    if ExecuteParsed(StmtNo, TmpSQL) and (FRunDepth = 1) then
      FlushExecBlock;
  finally
    try
      EndRun;
    finally
      FParser.Free;
      FParser := SavedParser;
      TmpSQL.Free;
      Lines.Free;
      CloseFile(F);
    end;
  end;
end;

procedure TpFIBScripter.SetTransaction(const Value: TpFIBTransaction);
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

function TpFIBScripter.GetTransaction: TpFIBTransaction;
begin
  if Assigned(FExternalTransaction) then
    Result := FExternalTransaction
  else
    Result := FTransaction
end;

function TpFIBScripter.LineCountInCurrentFile: Integer;
begin
  Result := FLineCountInFile;
end;

procedure TpFIBScripter.SetOnStatExec(CallBack: TOnScriptStatementExec);
begin
  FInternalOnStatementExec := CallBack
end;

{ TpFIBScriptParser }

function IsBlank(C: Char): boolean; {$IFDEF D2009+}inline; {$ENDIF}
begin
  Result := CharInSet(C, [' ', #9, #10, #13]);
end;

function IsWordChar(C: Char): boolean; {$IFDEF D2009+}inline; {$ENDIF}
begin
  Result := CharInSet(C, ['A' .. 'Z', 'a' .. 'z', '0' .. '9', '_', '$']);
end;

// Compares the word of Len chars at X in S with UpperWord, case insensitive
function SameWord(const S: string; X, Len: Integer; const UpperWord: string): boolean;
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

function KeywordOf(const S: string; X, Len: Integer): TScriptKeyword;
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
        Result := kwBlock;
    6:
      if SameWord(S, X, Len, 'CREATE') then
        Result := kwCreate;
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
        Result := kwExternal;
    9:
      if SameWord(S, X, Len, 'PROCEDURE') then
        Result := kwProcedure;
  end;
end;

function TpFIBScriptParser.Line(Y: Integer): string;
begin
  Result := FScript[Y - FFirstLine];
end;

procedure TpFIBScriptParser.SetTerminator(const Value: string);
begin
  if Value = '' then
    FTerminator := ';'
  else
    FTerminator := Value;
  FTermFirst := UpCase(FTerminator[1]);
  FTermFirstLower := LowerCase(FTermFirst)[1];
end;

function TpFIBScriptParser.IsTerminatorAt(const S: string; X: Integer): boolean;
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

function TpFIBScriptParser.IsModuleHeader: boolean;
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
procedure TpFIBScriptParser.ProcessWord(const S: string; X, Len: Integer);
var
  K: TScriptKeyword;
begin
  if (FWordCount > High(FHeader)) and not FInBody and not FMayHaveBody then
    Exit;
  K := KeywordOf(S, X, Len);
  if FWordCount <= High(FHeader) then
  begin
    FHeader[FWordCount] := K;
    if FWordCount = 0 then
      FMayHaveBody := (FTerminator = ';') and (K in [kwCreate, kwAlter, kwRecreate, kwExecute]);
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

procedure TpFIBScriptParser.BeginStatement(X, Y: Integer; StmtType: TStmtType);
var
  P: PStatementDesc;
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
  FInSetTerm := False;
  FNewTerminator := '';
  FNewTerminatorDone := False;
end;

procedure TpFIBScriptParser.EndStatement;
var
  P: PStatementDesc;
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

procedure TpFIBScriptParser.EndSetTerm;
begin
  if FNewTerminator = '' then
    raise Exception.Create('Parse script error.' + CLRF + 'SET TERM without terminator' + CLRF + 'Line :' +
      IntToStr(FStatements[FStatementCount - 1].smdBegin.Y + 1));
  SetTerminator(FNewTerminator);
  Dec(FStatementCount); // SET TERM is not executed
  FInSetTerm := False;
  FDisposition := pdBetweenStatements;
end;

procedure TpFIBScriptParser.BeginDirective(X, Y: Integer);
var
  D: PDirectiveDesc;
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

procedure TpFIBScriptParser.CloseDirectiveCondition(X, Y: Integer);
var
  D: PDirectiveDesc;
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

procedure TpFIBScriptParser.ElseDirective(X, Y: Integer);
begin
  if Length(FDirectiveStack) = 0 then
    RaiseParserDirectiveError(dElse, Y + 1);
  FDirectives[FDirectiveStack[High(FDirectiveStack)]].dElse := StmtCoord(X, Y);
end;

procedure TpFIBScriptParser.EndIfDirective(X, Y: Integer);
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

procedure TpFIBScriptParser.ScanLine(Y: Integer);
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
        Break
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
                raise Exception.Create('Parse script error.' + CLRF +
                  'Invalid SET TERM' + CLRF + 'Line :' + IntToStr(Y + 1) +
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
                  raise Exception.Create('Parse script error.' + CLRF +
                    ' Unexpected symbol "{"' + CLRF + 'Line :' + IntToStr(Y + 1) +
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

procedure TpFIBScriptParser.BeginParse(AScript: TStrings; const Terminator: string);
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

procedure TpFIBScriptParser.Scan;
begin
  while FNextLine < FFirstLine + FScript.Count do
  begin
    ScanLine(FNextLine);
    Inc(FNextLine);
  end;
end;

procedure TpFIBScriptParser.EndParse(IgnoreLastTerm: boolean);
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
    raise Exception.Create('Parse script error.' + CLRF + '$ENDIF skipped ' +
      IntToStr(Length(FDirectiveStack)) + ' times');
end;

function TpFIBScriptParser.NextStatement(var Stmt: PStatementDesc): boolean;
begin
  Result := FTakenCount < FCompleteCount;
  if Result then
  begin
    Stmt := @FStatements[FTakenCount];
    Inc(FTakenCount);
  end;
end;

procedure TpFIBScriptParser.DiscardParsed;
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

procedure TpFIBScriptParser.ParseScript(AScript: TStrings;
  var Terminator: string; var ScriptMap: TScriptMap;
  var DirectivesMap: TDirectivesMap; IgnoreLastTerm: boolean);
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

procedure TpFIBScriptParser.CopyFragment(BegPos, EndPos: TStmtCoord; Dest: TStrings);
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

procedure TpFIBScriptParser.SearchObjectType(var stmtDesc: TStatementDesc; var BegSearch: TStmtCoord; ForGrant: boolean = False);
var
  TmpCoord1: TStmtCoord;
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
procedure TpFIBScriptParser.ValidateStatement(var stmtDesc: TStatementDesc);
const
  SessionSetWords: array [0 .. 7] of string = ('STATEMENT', 'SESSION', 'BIND', 'DECFLOAT', 'ROLE', 'TRUSTED',
    'OPTIMIZE', 'SEARCH_PATH');
var
  CurStr: string;
  TmpCoord: TStmtCoord;
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

function TpFIBScriptParser.NextTokenPos(TokenPos: TStmtCoord; EndCoord: TStmtCoord): TStmtCoord;
var
  InComment: boolean;
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
              Break; // comment up to the end of the line
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

function TpFIBScriptParser.GetToken(TokenPos: TStmtCoord; IgnoreQuote: boolean = True): string;
var
  CurStr: string;
  StartPosInStr: Integer;
  EndPosInStr: Integer;
  P: PChar;
  L: Integer;
begin
  CurStr := Line(TokenPos.Y);
  StartPosInStr := TokenPos.X;
  if (CurStr[StartPosInStr] in ['''', '"']) and IgnoreQuote then
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
    while (EndPosInStr <= L) and not(CurStr[EndPosInStr] in [#9, #13, #10, ' ', '-', '/', ',', ';', '(']) do
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
  // SetString(Result,@CurStr[StartPosInStr],EndPosInStr-StartPosInStr)
end;

function TpFIBScriptParser.TypeNameToObjectType(const TestString: string; Position: Integer): TObjectType;
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

function TpFIBScriptParser.StmtTypeNameToType(const TestString: string; Position: Integer): TStmtType;
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

procedure TpFIBScripter.TryFillBlobParams;
var
  i: Integer;
  pn: string;
  bPos, Len: Integer;
  m: TMemoryStream;
  p_: Integer;
begin
  with FQuery do
    for i := FQuery.ParamCount - 1 downto 0 do
    begin
      pn := FQuery.ParamName(i);
      if pn[1] in ['H', 'h'] then
      begin
        p_ := Pos('_', pn);
        bPos := HexStr2Int(Copy(pn, 2, p_ - 2));
        Len := HexStr2Int(Copy(pn, p_ + 1, Length(pn) - p_));
        if Len = 0 then
          FQuery.Params[i].Clear
        else
        begin
          if not Assigned(FBlobFileStream) then
            FBlobFileStream := TFileStream.Create(FBlobFile, fmOpenRead, fmShareDenyWrite);
          m := TMemoryStream.Create;
          try
            m.Size := Len;
            m.Position := 0;
            FBlobFileStream.Position := bPos;
            FBlobFileStream.Read(m.Memory^, Len);
            FQuery.Params[i].LoadFromStream(m);
          finally
            m.Free;
          end
        end;
      end;
    end
end;

// Reinsert

function TpFIBScripter.PrepareReinsert(const InsTxt, ReInsTxt: string): string;
var
  i, L: Integer;
  StartValues: Integer;
begin
  if vReinsPrepared then
  begin
    Result := vLastInsertStmt + Copy(ReInsTxt, 9, MaxInt);
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
    vReinsPrepared := True;
    vLastInsertStmt := Copy(InsTxt, 1, StartValues + 5);
    Result := vLastInsertStmt + Copy(ReInsTxt, 9, MaxInt)
  end
  else
    Result := ReInsTxt;
end;

// AutoExecBlock support
procedure TpFIBScripter.RestartBlock;
begin
  vBlockContextCount := 0;
  vBlockSize := 0;
  FExecBlockStatement.Clear;
end;

procedure TpFIBScripter.CloseBlock;
begin
  FExecBlockStatement.Add('END');
end;

function TpFIBScripter.AddStatementToExecuteBlock(Stmt: TStrings): boolean;
var
  i, L: Integer;
begin
  if not Assigned(FExecBlockStatement) then
    FExecBlockStatement := TStringList.Create;
  Result := vBlockContextCount < 255;
  if not Result then
  begin
    FExecBlockStatement.Add('END');
    Exit;
  end;
  if FExecBlockStatement.Count = 0 then
  begin
    vBlockContextCount := 0;
    FExecBlockStatement.Add('EXECUTE BLOCK AS BEGIN');
    vBlockSize := Length(FExecBlockStatement[0]) + 2;
  end;
  L := 0;
  for i := 0 to Stmt.Count - 1 do
    Inc(L, Length(Stmt[i]) + 2);
  Result := (vBlockSize + L + 2 + 1) < High(Word) - 3; // 3 for 'END'
  if Result then
  begin
    FExecBlockStatement.AddStrings(Stmt);
    FExecBlockStatement[FExecBlockStatement.Count - 1] := FExecBlockStatement
      [FExecBlockStatement.Count - 1] + ';';
    Inc(vBlockSize, L);
    Inc(vBlockContextCount);
  end
  else
    FExecBlockStatement.Add('END');
end;

end.
