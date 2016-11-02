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
{    Written by Serge Buzadzhy (buzz@devrace.com)               }
{                                                               }
{ ------------------------------------------------------------- }
{    FIBPlus home page: http://www.fibplus.com/                 }
{    FIBPlus support  : http://www.devrace.com/support/         }
{ ------------------------------------------------------------- }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit pFIBScripter;

interface
{$I FIBPlus.inc}
{$IFDEF D6+}
{$A2}
{$ENDIF}
 uses SysUtils,Classes{$IFDEF D6+},Types{$ENDIF}
  ,FIBPlatforms,pFIBDatabase,pFIBQuery,FIBQuery,fib,pFIBInterfaces
 ;

//{$DEFINE BEZBAZY}
type
  TStmtType = (sUnknown,sInvalid,sDML,
     sConnect, sDisconnect, sReconnect,
     sCreateDatabase,sDropDatabase,
     sCommit, sRollBack,
     sCreate, sAlter,sRecreate, sDrop,  sSet, sSetGenerator,sSetStatistics,sDescribe,sDeclare,
     sComment,sGrant,sRunFromFile,sBatch {Temp Type},sBatchStart,sBatchExecute, sExecute,

     sInsert,sReinsert , sDirective
    );
  TObjectType =
    (otNone,otDatabase,otDomain,otTable,otView,otProcedure,otTrigger,
     otUDF,otException,otGenerator,otIndex,
     otConstraint,  otFilter,otField,otParameter,otRole,otBlock,otUser ,otPackage,otPackageBody,otFunction
    );


  TStmtCoord=record
   X: Word;
   Y: Integer;
  end;
  PStmtCoord=^TStmtCoord;

  TValidationInfo=record
    smdEnd    :TStmtCoord;
    Active    :boolean;
    BeginExist:boolean;
    BegCount:integer;
  end;
  PValidationInfo=^TValidationInfo;

  TStatementDesc = record
    smdBegin:TStmtCoord;
    smdEnd  :TStmtCoord;
    smtType :TStmtType;
    objType :TObjectType;
    objName :string;
    DirectiveNum:integer ;
    DirectiveElse:boolean;
  end;
  PStatementDesc=^TStatementDesc;

  TScriptMap= array of TStatementDesc;



  TOnParseStmt = procedure(Sender: TObject;StatementNo: Integer; Coord:TStatementDesc;
   SQLText:TStrings) of object;



  TDirectiveState = (dsUnknown,dsTrue,dsFalse);
  TDirectiveDesc = record
    dBegin:TStmtCoord;
    dConditionClose:TStmtCoord;
    dElse :TStmtCoord;
    dEnd  :TStmtCoord;
    dState: TDirectiveState;
    OwnerDirectiveNum:integer;
    OwnerDirectiveElse:boolean;
  end;
  PDirectiveDesc=^TDirectiveDesc;
  TDirectivesMap= array of TDirectiveDesc;
  PDirectivesMap= array of PDirectiveDesc;


  TpFIBScriptParser = class
  private
    FScript:TStrings;
    FTemp  :TStrings;
    FCurDBName:string;
    FMakeConnectInScript:boolean;
    FHaveDMLStatements   :boolean;
    FHaveUnknownStatements:boolean;
    FValidationInfo:TValidationInfo;
    function  NextTokenPos(TokenPos:TStmtCoord; EndCoord:TStmtCoord ):TStmtCoord;
    function  GetToken(TokenPos:TStmtCoord;IgnoreQuote:boolean=True):string;
    procedure SearchObjectType(var stmtDesc:TStatementDesc;var BegSearch:TStmtCoord;ForGrant:boolean=False);
    function  ValidateStatement(var stmtDesc:TStatementDesc;const NeedCheckCanEnd:boolean ):boolean;
    function  StmtTypeNameToType(const TestString:string; Position:integer):TStmtType;
    function  TypeNameToObjectType(const TestString:string; Position:integer):TObjectType;
  public
   constructor Create;
   destructor  Destroy; override;
   procedure ParseScript(AScript:TStrings;var Terminator:string;
     var FScriptMap:TScriptMap; var  FCDMap: TDirectivesMap;IgnoreLastTerm:boolean=True
   );

  end;


  TOnStatementExecute = procedure(Sender: TObject;Line:Integer; StatementNo: Integer;  Desc:TStatementDesc;
    Statement: TStrings) of object;
  TOnSQLScriptExecError = procedure(Sender: TObject; StatementNo: Integer;
    Line:Integer; Statement: TStrings; SQLCode: Integer; const Msg: string;
    var doRollBack:boolean;  var Stop: Boolean) of object;

  TDynStringArray= array of Ansistring;

  //TDynStringArray= array of string;
  TpFIBScripter=class(TComponent,IFIBScripter)
  private
     FPrepared:boolean;
     FMakeConnectInScript:boolean;
     FParser:TpFIBScriptParser;
     FScript:TStrings;
     FScriptMap:TScriptMap;
     FDirectivesMap:TDirectivesMap;
     FLineCountInFile:integer;
     procedure DoOnChangeScript(Sender: TObject);
  private
     FDatabase   :TpFIBDatabase;
     FTransaction:TpFIBTransaction;
     FQuery      :TpFIBQuery;
     FPaused     :Boolean;
     FSkipStatement:Boolean;
     FStopStatementNo:integer;
     FSQLDialect :integer;
     FLibraryName:string;
     FCharSet    :string;
     FAutoDDL    :boolean;
     FBlobFile   :string;
     FBlobFileStream:TFileStream;
     vInternalDatabase:boolean;
     FExternalTransaction:TpFIBTransaction;
     FHaveDMLStatements   :boolean;
     FHaveUnknownStatements:boolean;
     FNeedRestoreForceWrite:boolean;
     vReinsPrepared:boolean;
     vLastInsertStmt:string;
 private
 // AutoExecBlock support
     FUseExecBlockForDML:boolean;
     vBlockContextCount:integer;
     vBlockSize:integer;
     FExecBlockStatement:TStrings;
     procedure RestartBlock;
     procedure CloseBlock;
     function  AddStatementToExecuteBlock(Stmt:TStrings):boolean;
  private
     FOnExecuteError:TOnSQLScriptExecError;
     FBeforeStatementExecute:TOnStatementExecute;
     FAfterStatementExecute :TOnStatementExecute;
     procedure SetDatabase(const Value: TpFIBDatabase);
     procedure SetTransaction(const Value: TpFIBTransaction);
     function  GetTransaction:TpFIBTransaction;
     procedure DoReconnect;
     procedure SetConnectParams(StartToken:TStmtCoord;EndCoord:TStmtCoord);
     procedure TryFillBlobParams;
     function  PrepareReinsert(const InsTxt,ReInsTxt:string):string;
  private
  //IB2007
      FInBatchCollect:boolean;
      FBatchSQLs :TDynStringArray;
      FInternalOnStatementExec:TOnScriptStatementExec;
      procedure   SetOnStatExec(CallBack:TOnScriptStatementExec);
  //Directives
  private
      FDefines:TStrings;
      FDirectiveConsts:TStrings;
      procedure SetScript(const Value: TStrings);
      procedure SetDefines(const Value: TStrings);
      function  DirectiveForbid(DirNum:integer; InElse:boolean):boolean;
      function  CalcDirective(Directive:TDirectiveDesc):TDirectiveState;
      function  CalcExists(Condition:TStrings):TDirectiveState;
      function  CalcIF(Condition:TStrings):TDirectiveState;
  protected
      procedure Notification(AComponent: TComponent;
       Operation: TOperation); override;
      procedure CreateInternalDatabase;
      procedure CopyFragment(BegPos,EndPos:TStmtCoord;Dest:TStrings);
      procedure DoQueryExecute(SQL:TStrings;ParamValues:array of variant);

  public
     constructor Create(AOwner:TComponent); override;
     destructor  Destroy;override;
     procedure   Parse(Terminator:string=';');
     procedure   ExecuteScript(FromStmt:integer=1);
     procedure   ExecuteFromFile(const FileName: string;Terminator:string=';');
     procedure   ExecuteStatement(StmtTxt:TStrings;stmt:PStatementDesc;StmtNo:integer;
      TmpSQL:TStrings=nil;LineInFile:integer=-1
     );
     procedure   ClearPrepared;
     function    StatementsCount:integer;
     function    GetStatement(StmtNo:integer;Text:TStrings):PStatementDesc;
     function    LineCountInCurrentFile:integer;

     procedure   AddDefine(const Def:string);
     procedure   DeleteDefine(const Def:string);
     procedure   PreparePreDefines;
     property    Prepared:boolean read FPrepared;
     property    StopStatementNo:Integer read FStopStatementNo;
     property    Query:TpFIBQuery read FQuery;
     property    MakeConnectInScript:boolean read FMakeConnectInScript;
     property SkipStatement: Boolean read FSkipStatement write FSkipStatement;
     property Paused: Boolean read FPaused write FPaused;
     property Defines:TStrings read FDefines write SetDefines;
  published
     property Script:TStrings read FScript write SetScript;
     property Database:TpFIBDatabase read FDatabase write SetDatabase;
     property Transaction: TpFIBTransaction read FExternalTransaction write SetTransaction;
     property OnExecuteError:TOnSQLScriptExecError
       read FOnExecuteError write FOnExecuteError;
     property AutoDDL :boolean read FAutoDDL write FAutoDDL default True;
     property BeforeStatementExecute:TOnStatementExecute read FBeforeStatementExecute write
      FBeforeStatementExecute;
     property AfterStatementExecute:TOnStatementExecute read FAfterStatementExecute write
      FAfterStatementExecute      ;
     property UseExecBlockForDML:boolean read FUseExecBlockForDML write FUseExecBlockForDML default false;
  end;

  function StatementTypeName(tn:TStmtType):string;

 //  Possible Directives
 // $IFDEF,$IFNDEF,$IFEXISTS,$IFNEXISTS,$IFNOTEXISTS,$ELSE,$ENDIF
 //$IF,$DEFINE,$UNDEF
 const
   dIfDef='{$IFDEF';
   dIfNDef='{$IFNDEF';
   dIf    ='{$IF';
   dIfExists  ='{$IFEXISTS';
   dIfNExists  ='{$IFNEXISTS';
   dIfNotExists  ='{$IFNOTEXISTS';
   dElse='{$ELSE';
   dEndIf='{$ENDIF';
   dExecBlock='{$EXECUTE_BLOCK';
   dDefine='{$DEFINE';
   dUnDefine='{$UNDEF';

   dSetVar='{$SET';
 //predefined defnames
 const srvIsFirebird='IS_FIREBIRD';
  //predefined defVARS
       srvMajorVer='SERVER_MAJOR_VER';
       srvMinorVer='SERVER_MINOR_VER';
       dbODSMajorVersion='ODS_MAJOR_VER';
       dbODSMinorVersion='ODS_MINOR_VER';

implementation
uses  StrUtil,SqlTxtRtns,StdFuncs;
{ TpFIBScripter }
type
   TParseDisposition= (pdBetweenStatements,pdInStatement,pdInDirective);
   TParserState =(psNormal,psInComment,psInFBComment,psInQuote,psInDoubleQuote,psInConditional);


procedure RaiseParserDirectiveError(const DirName:string;Line:integer);
begin
 raise
  Exception.Create('Parse script error.'+CLRF+'Can''t resolve directive  "'+DirName+'"'+CLRF+
           'Line ' +IntToStr(Line)
  );
end;


  function StatementTypeName(tn:TStmtType):string;
  begin
   case tn of
     sUnknown: Result:='Unknown';
     sInvalid: Result:='Invalid';
     sDML: Result:='DML';
     sConnect: Result:='Connect';
     sDisconnect:     Result:='Disconnect';
     sReconnect:     Result:='Reconnect';
     sCreateDatabase: Result:='Create database';
     sDropDatabase: Result:='Drop database';
     sCommit: Result:='Commit';
     sRollBack:  Result:='Rollback';
     sCreate: Result:='Create ';
     sAlter:   Result:='Alter ';
     sRecreate:Result:='Recreate ';
     sDrop:Result:='Drop ';
     sSet:Result:='Set ';
     sSetGenerator: Result:='Set generator';
     sSetStatistics: Result:='Set statistics';
     sDescribe :Result:='Describe ';
     sDeclare  :Result:='Declare ';
     sComment :Result:='Comment ';
     sGrant    : Result:='Grant ';
     sRunFromFile: Result:='Run from file ';
     sInsert,sReinsert : Result:='DML'
   else
     Result:='Unknown';
   end

  end;

function StmtCoord(X:Word;Y:Integer):TStmtCoord;
begin
  Result.X := X;
  Result.Y := Y;
end;


function IsClause( const EtalonClause:string; const Source:string;
 Position:integer
):boolean;
 // EtalonClause must be if UpperCase
var
  Len:Integer;
  LenEtalon:Byte;
  pSource:PChar;
  pEtalon:PChar;
  pEtalon1:PChar;
begin
 Len:=Length(Source);
 LenEtalon:=Length(EtalonClause);
 if Len-Position+1<LenEtalon then
   Result:=False
 else
 begin
    pSource:=Pointer(Source);
    Inc(pSource,Position-1);
    pEtalon:=Pointer(EtalonClause);
    pEtalon1:=Pointer(EtalonClause);
    Inc(pEtalon1,LenEtalon);
    Result:=True;
    while (pEtalon<>pEtalon1) do
    begin
      if pSource^<>pEtalon^ then
      begin
          if Byte(pSource^)-32<>Byte(pEtalon^) then
          begin
            Result:=False;
            Break;
          end;
      end;
      Inc(pSource);
      Inc(pEtalon);
    end;
    if Result and (Len-Position>=LenEtalon) then
      Result:=Source[Position+LenEtalon] in [' ',#13,#9,#10,'/','-',';','^',',','}']
 end
end;

function StrIsIfDirective(const CheckStr:string;X:integer):boolean;
begin
{   dIfDef='{$IFDEF';
   dIfNDef='{$IFNDEF';
   dIf    ='{$IF';
   dIfExists  ='{$IFEXISTS';
   dIfNExists  ='{$IFNEXISTS';
   dIfNotExists  ='{$IFNOTEXISTS';
}
   Result:=IsClause(dIfDef,CheckStr,x) or IsClause(dIfNDef,CheckStr,x) or
    IsClause(dIf,CheckStr,x) or IsClause(dIfExists,CheckStr,x) or
    IsClause(dIfNExists,CheckStr,x) or IsClause(dIfNotExists,CheckStr,x)


end;



procedure TpFIBScripter.ClearPrepared;
begin
 SetLength(FScriptMap,0);
 SetLength(FDirectivesMap,0);
 FPrepared:=False;
end;

procedure TpFIBScripter.CopyFragment(BegPos, EndPos: TStmtCoord;
  Dest: TStrings);
var
 y1:Integer;
 L:Word;
 CurStr:String;
begin
  if Assigned(Dest) then
  begin
    Dest.Clear;
    if (EndPos.X=0) and (FScript.Count>0) then
    begin
    // End term don't exist
     EndPos.Y:=FScript.Count-1;
     EndPos.X:=Length(FScript[FScript.Count-1])
    end;

    for y1:=BegPos.Y to EndPos.Y do
    begin
      CurStr:=FScript[y1];
      if y1=BegPos.Y then   // First line
      begin
        if BegPos.Y=EndPos.Y then
         L:=EndPos.X-BegPos.X+1
        else
         L:=Length(CurStr)-BegPos.X+1;
        if L<>Length(CurStr) then
         Dest.Add(Copy(CurStr,BegPos.X,L))
        else
         Dest.Add(CurStr)
      end
      else
      if y1=EndPos.Y then   // Last line
      begin
         L:=EndPos.X;
        if L<>Length(CurStr) then
         Dest.Add(Copy(CurStr,1,L))
        else
         Dest.Add(CurStr)
      end
      else
         Dest.Add(CurStr)
    end;
  end;
end;

constructor TpFIBScripter.Create(AOwner:TComponent);
begin
  inherited;
//  FUseExecBlockForDML:=True;
  FScript:=TStringList.Create;
  TStringList(FScript).OnChanging:=DoOnChangeScript;
  FParser:=TpFIBScriptParser.Create;

  FDefines:=TStringList.Create;
  FDirectiveConsts:=TStringList.Create;
//  FDirectiveConsts.Add('A= 11');
  FTransaction:=TpFIBTransaction.Create(Self);
  FQuery      :=TpFIBQuery.Create(Self);
  FQuery.Transaction:=FTransaction;
  FSQLDialect:=3;
  FAutoDDL:=True;
  FBlobFileStream:=nil;
end;

procedure TpFIBScripter.CreateInternalDatabase;
begin
 if not Assigned(FDatabase) then
 begin
  Database:=TpFIBDatabase.Create(Self);
  vInternalDatabase:=True
 end
end;

destructor TpFIBScripter.Destroy;
begin
  FParser.Free;
  FScript.Free;
  FDefines.Free;
  FDirectiveConsts.Free;
  SetLength(FScriptMap,0);
  SetLength(FDirectivesMap,0);
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

procedure TpFIBScripter.DoQueryExecute(SQL:TStrings;
  ParamValues: array of variant);
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

{$IFNDEF D6+}
// Copy from SysUtils (D6+)
function AnsiDequotedStr(const S: string; AQuote: Char): string;
var
  LText: PChar;
begin
  LText := PChar(S);
  Result := AnsiExtractQuotedStr(LText, AQuote);
  if Result = '' then
    Result := S;
end;
{$ENDIF}



function  TpFIBScripter.CalcIF(Condition:TStrings):TDirectiveState;
type
    TState=(sConstName,sOperator,sValue);
var
   i,L:integer;
   tmpStr:string;

   cName:string;
   cOper:string;
   cValue:string;
   Value:string;

   cValueF:Double;
   ValueF:Double;

   Expr:string;
   State:TState;
begin
// only simple expressions
   Result:=dsUnknown;
   tmpStr:=Condition[0];
   L:=Length(tmpStr);
   I:=3;
   while I <= L do
   begin
     if tmpStr[I] in [' ',#9,#13,#10] then
      Break;
     Inc(I)
   end;
   tmpStr:=Trim(Copy(Condition.Text,I,MaxInt));
   SetLength(tmpStr,Length(tmpStr)-1);
   Expr:=Trim(tmpStr);
   if Length(Expr)=0 then
    Exit;

   I:=1;
   State:=sConstName;
   cOper:=''; cValue:='';
   while I<=Length(Expr) do
   begin
    case State of
     sConstName:
       if (Expr[I] in [' ',#9,#10,#13]) then
       begin
        cName:=UpperCase(Copy(Expr,1,I-1));
        while (I<=Length(Expr)) and (Expr[I] in [' ',#9,#10,#13]) do
         Inc(I);
        if (I>Length(Expr)) or not (Expr[I] in ['=','>','<']) then
          raise Exception.Create('Parse script error.'+CLRF+'Can''t resolve condition  "$IF"'+CLRF+
            Expr
          );
        State:=sOperator;
       end
       else
       if (Expr[I] in ['=','>','<']) then
       begin
        cName:=UpperCase(Copy(Expr,1,I-1));
        State:=sOperator;
       end
       else
        Inc(I);
     sOperator:
       if (Expr[I] in ['=','>','<']) then
       begin
        cOper:=cOper+Expr[I];
        Inc(I)
       end
       else
        State:=sValue;
      sValue:
       begin
         while (I<=Length(Expr)) and (Expr[I] in [' ',#9,#10,#13]) do
          Inc(I);
         cValue:=Copy(Expr,I,MaxInt);
         Break;
       end;
    end;
   end;
   //
   Value:=FDirectiveConsts.Values[cName];
   if Trim(Value)='' then
    raise Exception.Create('Parse script error.'+CLRF+'Constant don''t exists'+CLRF+
      cName
    );


   if cOper='=' then
   begin
     if Value=cValue then
      Result:=dsTrue
     else
      Result:=dsFalse
   end
   else
   if cOper='<>' then
   begin
     if Value<>cValue then
      Result:=dsTrue
     else
      Result:=dsFalse
   end
   else
   begin
   // May be floats
     Value :=StringReplace(Value,'.',{$IFDEF D_XE3}FormatSettings.{$ENDIF} DecimalSeparator,[]);
     Value :=StringReplace(Value,',',{$IFDEF D_XE3}FormatSettings.{$ENDIF} DecimalSeparator,[]);
     cValue:=StringReplace(cValue,'.',{$IFDEF D_XE3}FormatSettings.{$ENDIF} DecimalSeparator,[]);
     cValue:=StringReplace(cValue,',',{$IFDEF D_XE3}FormatSettings.{$ENDIF} DecimalSeparator,[]);

     cValueF:=StrToFloat(cValue);
     ValueF:=StrToFloat(Value);
     case cOper[1] of

      '>':
        if ValueF<cValueF then
         Result:=dsFalse
        else
        if cValueF>cValueF  then
         Result:=dsTrue
        else
        if cOper='>=' then
          Result:=dsTrue
        else
          Result:=dsFalse;
      '<':
        if ValueF>cValueF then
         Result:=dsFalse
        else
        if ValueF<cValueF  then
         Result:=dsTrue
        else
        if cOper='<=' then
          Result:=dsTrue
        else
          Result:=dsFalse;
     end;
   end;
end;

const
  QRYDomainExist =
    'select RDB$FIELD_TYPE    FROM RDB$FIELDS    WHERE RDB$FIELD_NAME=:NAME';

  QRYTableExist =
    'SELECT REL.RDB$RELATION_NAME FROM RDB$RELATIONS REL WHERE REL.RDB$RELATION_NAME=:NAME  and REL.RDB$VIEW_BLR is null';

  QRYViewExist =
    'SELECT REL.RDB$RELATION_NAME FROM RDB$RELATIONS REL WHERE REL.RDB$RELATION_NAME=:NAME  and NOT REL.RDB$VIEW_BLR is null';
  QRYTriggerExist =
   'SELECT T.RDB$TRIGGER_NAME    from RDB$TRIGGERS T    WHERE T.RDB$TRIGGER_NAME=:NAME';

  QRYProcedureExist =
    'SELECT RDB$PROCEDURE_NAME FROM  RDB$PROCEDURES WHERE RDB$PROCEDURE_NAME=:NAME';
  QRYPackageExist =
    'SELECT RDB$PACKAGE_NAME FROM  RDB$PACKAGES WHERE RDB$PACKAGE_NAME=:NAME';

  QRYExceptionExist =
    'SELECT RDB$EXCEPTION_NAME FROM RDB$EXCEPTIONS WHERE  RDB$EXCEPTION_NAME=:NAME';
  QRYGeneratorExist =
  'SELECT RDB$GENERATOR_NAME FROM RDB$GENERATORS WHERE RDB$GENERATOR_NAME=:NAME ';
  QRYUdfExist =
  'SELECT RDB$FUNCTION_NAME FROM RDB$FUNCTIONS WHERE  RDB$FUNCTION_NAME=:NAME';
  QRYFunctionExist =
  'SELECT RDB$FUNCTION_NAME FROM RDB$FUNCTIONS WHERE  RDB$FUNCTION_NAME=:NAME';

  QRYRoleExist =
  'SELECT RDB$ROLE_NAME FROM RDB$ROLES WHERE RDB$ROLE_NAME =:NAME ';


function  TpFIBScripter.CalcExists(Condition:TStrings):TDirectiveState;
var
   CheckExists:boolean;
   i,L:integer;
   tmpStr:string;
   chObjectType:TObjectType;
   chObjName:string;
   chQryTxt:string;
begin
   Result:=dsUnknown;
   tmpStr:=Condition[0];
   CheckExists:=IsClause(dIfExists, tmpStr,1) ;
   if not CheckExists and not IsClause(dIfNExists, tmpStr,1)
      and  not  IsClause(dIfNotExists, tmpStr,1)
   then
    Exit;
   L:=Length(tmpStr);
   I:=10;
   while I <= L do
   begin
     if tmpStr[I] in [' ',#9,#13,#10] then
      Break;
     Inc(I)
   end;
   tmpStr:=Trim(Copy(Condition.Text,I,MaxInt));
   if Length(tmpStr)=0 then
    Exit;

   chObjectType:=otNone;
   case tmpStr[1] of
   'D','d':  if IsClause('DOMAIN', tmpStr,1)  then
             begin
               chObjectType:=otDomain;
               chQryTxt:=QRYDomainExist;
               L:=7
             end;
   'E','e':
             if IsClause('EXCEPTION', tmpStr,1)  then
             begin
               chObjectType:=otException;
               chQryTxt:=QRYExceptionExist;
               L:=10
             end;
   'F','f':
             if IsClause('FUNCTION', tmpStr,1)  then
             begin
               chObjectType:=otFunction;
               chQryTxt:=QRYFunctionExist;
               L:=9
             end;

   'G','g':
             if IsClause('GENERATOR', tmpStr,1)  then
             begin
               chObjectType:=otGenerator;
               chQryTxt:=QRYGeneratorExist;
               L:=10
             end;
   'P','p':
             if IsClause('PROCEDURE', tmpStr,1)  then
             begin
               chObjectType:=otProcedure;
               chQryTxt:=QRYProcedureExist;
               L:=10
             end
             else
             if IsClause('PACKAGE', tmpStr,1)  then
             begin
               chObjectType:=otPackage;
               chQryTxt:=QRYPackageExist;
               L:=8
             end;
   'R','r':
             if IsClause('ROLE', tmpStr,1)  then
             begin
               chObjectType:=otRole;
               chQryTxt:=QRYRoleExist;
               L:=5
             end;

   'T','t':
             if IsClause('TABLE', tmpStr,1)  then
             begin
               chObjectType:=otTable;
               chQryTxt:=QRYTableExist;
               L:=6
             end
             else
             if IsClause('TRIGGER', tmpStr,1)  then
             begin
               chObjectType:=otTrigger;
               chQryTxt:=QRYTriggerExist;
               L:=8
             end;
   'U','u':
             if IsClause('UDF', tmpStr,1)  then
             begin
               chObjectType:=otUDF;
               chQryTxt:=QRYUdfExist;
               L:=4
             end;
   'V','v':
             if IsClause('VIEW', tmpStr,1)  then
             begin
               chObjectType:=otView;
               chQryTxt:=QRYViewExist;
               L:=5
             end;
   end; // case
   if chObjectType<>otNone then
   begin
    chObjName:=Trim(Copy(tmpStr,L,MaxInt));
    SetLength(chObjName,Length(chObjName)-1);
    chObjName:=Trim(chObjName);
    if (chObjName<>'') and (chObjName[1]='"') then
      chObjName:=Copy(chObjName,2,Length(chObjName)-2)
    else
      chObjName:=UpperCase(chObjName);

    FQuery.SQL.Text:=chQryTxt;

{$IFNDEF BEZBAZY}
    if Assigned(FDatabase) and FDatabase.Connected then
    begin
      FQuery.Params[0].AsString:=chObjName;
       if not GetTransaction.InTransaction then
         GetTransaction.StartTransaction;
       FQuery.Close;
       try
         FQuery.ExecQuery;
         if FQuery.Eof xor CheckExists then
          Result:= dsTrue
         else
          Result:= dsFalse
       finally
        FQuery.Close;
       end;
    end;
{$ENDIF}
   end
   else
   if IsClause('SELECT', tmpStr,1)  then
   begin
    chQryTxt:=tmpStr;
    SetLength(chQryTxt,Length(chQryTxt)-1);

{$IFNDEF BEZBAZY}
    if Assigned(FDatabase) and FDatabase.Connected then
    begin
      FQuery.SQL.Text:=chQryTxt;
     if not GetTransaction.InTransaction then
       GetTransaction.StartTransaction;
     FQuery.Close;
     try
       FQuery.ExecQuery;
       if FQuery.Eof xor CheckExists then
        Result:= dsTrue
       else
        Result:= dsFalse
     finally
      FQuery.Close;
     end;
    end;
{$ENDIF}

   end;



end;

function  TpFIBScripter.CalcDirective(Directive:TDirectiveDesc):TDirectiveState;
var
 TmpSQL:TStrings;
 s:string;
begin
 Result:=dsUnknown;
 TmpSQL:=TStringList.Create;
 try
  CopyFragment(Directive.dBegin,Directive.dConditionClose,TmpSQL);
  if TmpSQL.Count>0 then
    if IsClause(dIfDef, TmpSQL[0],1) then
    begin
     s:=Trim(Copy(TmpSQL.Text,8,MaxInt));
     SetLength(s,Length(s)-1);
     s:=Trim(s);
     if FDefines.IndexOf(UpperCase(s))>=0 then
      Result:=dsTrue
     else
      Result:=dsFalse
    end
    else
    if IsClause(dIfNDef, TmpSQL[0],1) then
    begin
     s:=Trim(Copy(TmpSQL.Text,9,MaxInt));
     SetLength(s,Length(s)-1);
     s:=Trim(s);
     if FDefines.IndexOf(UpperCase(s))>=0 then
      Result:=dsFalse
     else
      Result:=dsTrue
    end
    else
    if IsClause(dIf, TmpSQL[0],1) then
    begin
     Result:=CalcIF(TmpSQL)
    end
    else
    if IsClause(dIfExists, TmpSQL[0],1) then
    begin
     Result:=CalcExists(TmpSQL)
    end
    else
    if IsClause(dIfNExists, TmpSQL[0],1) or IsClause(dIfNotExists, TmpSQL[0],1) then
    begin
     Result:=CalcExists(TmpSQL)
    end
    else
     Result:=dsFalse
 finally
   TmpSQL.Free
 end;
end;

function  TpFIBScripter.DirectiveForbid(DirNum:integer; InElse:boolean):boolean;
var

 NeedCalc:PDirectivesMap;
 i,j:Integer;
 vInElse:boolean;
begin
 if (DirNum>=0) and (DirNum<Length(FDirectivesMap)) then
 begin
    case FDirectivesMap[DirNum].dState of
    dsTrue: Result:= not InElse;
    dsFalse: Result:= InElse;
    else
    //dsUnknown
      begin
        Result:=True;
        SetLength(NeedCalc,1000);
        i:=0;
        j:=DirNum;
        while (j>-1) and (FDirectivesMap[j].dState=dsUnknown) do
        begin
         NeedCalc[i]:=@FDirectivesMap[j];
         j:=FDirectivesMap[j].OwnerDirectiveNum;
         Inc(i)
        end;
        SetLength(NeedCalc,I);
        Dec(I)  ;
//
       if j>-1 then
       begin
          Result:=(FDirectivesMap[j].dState=dsTrue) xor (NeedCalc[I].OwnerDirectiveElse);
       end;

//

        while (i>=0) and Result do
        begin
          if i>0 then
           vInElse:=NeedCalc[i-1].OwnerDirectiveElse
          else
           vInElse:=InElse;
          NeedCalc[i].dState:=CalcDirective(NeedCalc[i]^);
          Result:= (NeedCalc[i].dState=dsTrue) xor  vInElse;
          Dec(I)
        end;
        if not Result then
         if  InElse then
          FDirectivesMap[DirNum].dState:=dsTrue
         else
          FDirectivesMap[DirNum].dState:=dsFalse;
      end;
    end;
 end
 else
  Result:=True
end;

procedure   TpFIBScripter.ExecuteStatement(StmtTxt:TStrings;stmt:PStatementDesc;
 StmtNo:integer; TmpSQL:TStrings=nil;LineInFile:integer=-1);
var
   vToken:TStmtCoord;
   tmpStr,tmpStr1:string;
   vIsInternalTmpSQL:boolean;
   doRollBack:boolean;
   MayBeInBlock:boolean;
   skip:boolean;
   i:Integer;

procedure ApplyCommand;
begin
     try
{$IFNDEF BEZBAZY}
       if not GetTransaction.InTransaction then
        GetTransaction.StartTransaction;
       if Length(FBlobFile)>0 then
        if (FQuery.ParamCount>0) then
         TryFillBlobParams;
       FQuery.ExecQuery;
       if Assigned(FInternalOnStatementExec) then
       begin
         if LineInFile=-1 then
          FInternalOnStatementExec(stmt.smdBegin.Y+1,StmtNo+1)
         else
         begin
          FInternalOnStatementExec(LineInFile,StmtNo+1);
         end;
       end;

       if Assigned(FAfterStatementExecute) then
       begin
         if LineInFile=-1 then
          FAfterStatementExecute(Self,stmt.smdBegin.Y+1,StmtNo+1,stmt^,StmtTxt)
         else
         begin
          FAfterStatementExecute(Self,LineInFile,StmtNo+1,stmt^,StmtTxt);
         end;
       end;
       if FAutoDDL  and (FQuery.SQLKind=skDDL) then
        FQuery.Transaction.Commit;
{$ENDIF}
     except
      on E :EFIBError do
      begin
       if Assigned(FOnExecuteError) then
       begin
        FPaused:=True;
        doRollBack:=True;
        FOnExecuteError(Self,StmtNo+1,stmt.smdBegin.Y+1,TmpSQL,E.SQLCode,E.Message,doRollBack,FPaused);
        if doRollBack then
          GetTransaction.Rollback;
       end
       else
        raise;
      end
     end;
end;

begin
 if stmt<>nil then
 begin
   if FQuery.Open then
    FQuery.Close;
   if TmpSQL=nil then
   begin
    vIsInternalTmpSQL:=True;
    TmpSQL:=TStringList.Create;
   end
   else
    vIsInternalTmpSQL:=False;
   try
    if stmt.DirectiveNum>=0 then
    begin
     SkipStatement:= not DirectiveForbid(stmt.DirectiveNum,stmt.DirectiveElse);
    end
    else
     SkipStatement:=False;
    if not SkipStatement  then
    if Assigned(FBeforeStatementExecute) then
     if LineInFile=-1 then
      FBeforeStatementExecute(Self,stmt.smdBegin.Y+1,StmtNo+1,stmt^,StmtTxt)
     else
     begin
      FBeforeStatementExecute(Self,LineInFile,StmtNo+1,stmt^,StmtTxt);
     end;
    if SkipStatement then
      Exit;
   MayBeInBlock:=FUseExecBlockForDML  and (stmt.smtType in [sReinsert,sInsert,sDML]);

   if FUseExecBlockForDML and  not  MayBeInBlock then
      if Assigned(FExecBlockStatement) and (vBlockSize>0) then
      begin
         CloseBlock;
         FQuery.SQL:=FExecBlockStatement;     // SQL statement
         RestartBlock;
         ApplyCommand;
      end;

    case stmt.smtType of
     sCreateDatabase:
     begin
        CreateInternalDatabase;
        vToken:=FParser.NextTokenPos(stmt.smdBegin, stmt.smdEnd);
        vToken:=FParser.NextTokenPos(vToken, stmt.smdEnd);
        if FDatabase.Connected then
         FDatabase.Close;

        FDataBase.DBName:=FParser.GetToken(vToken);
        vToken:=FParser.NextTokenPos(vToken, stmt.smdEnd);
        CopyFragment(vToken,stmt.smdEnd,FDataBase.DBParams);
        FDatabase.SQLDialect:=FSQLDialect;
        FDatabase.LibraryName:=FLibraryName;
{$IFNDEF BEZBAZY}
       try
        FDatabase.CreateDatabase;
        PreparePreDefines;
        if FDatabase.NeedUTFEncodeDDL// and (FHaveDMLStatements or FHaveUnknownStatements)
        then
        begin
          if FDatabase.FBAttachCharsetID=0 then
          begin
            FDatabase.Connected:=False;
            SetConnectParams(vToken,stmt.smdEnd);
            FDatabase.DBParams.Add('force_write=0');
            FNeedRestoreForceWrite:=True;
            FDatabase.Connected:=True;
          end
        end;
       except
          on E :EFIBError do
          begin
           if Assigned(FOnExecuteError) then
           begin
            FPaused:=True;
            FOnExecuteError(Self,StmtNo+1,stmt.smdBegin.Y+1,TmpSQL,E.SQLCode,E.Message,doRollBack,FPaused);
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
       vToken:=FParser.NextTokenPos(stmt.smdBegin, stmt.smdEnd);
       vToken:=FParser.NextTokenPos(vToken, stmt.smdEnd);
       if FDatabase.Connected then
         FDatabase.Close;
       FDatabase.LibraryName:=FLibraryName;
       FDataBase.DBName:=FParser.GetToken(vToken);
       vToken:=FParser.NextTokenPos(vToken, stmt.smdEnd);
       tmpStr:=FParser.GetToken(vToken);
       if IsClause('USER',tmpStr,1) then
       begin
        vToken:=FParser.NextTokenPos(vToken, stmt.smdEnd);
        tmpStr:=FParser.GetToken(vToken);
        FDatabase.ConnectParams.UserName:=tmpStr;
       end
       else
       if IsClause('PASSWORD',tmpStr,1) then
       begin
        vToken:=FParser.NextTokenPos(vToken, stmt.smdEnd);
        tmpStr:=FParser.GetToken(vToken);
        FDatabase.ConnectParams.Password:=tmpStr;
       end;

       vToken:=FParser.NextTokenPos(vToken, stmt.smdEnd);
       tmpStr:=FParser.GetToken(vToken);
       if IsClause('USER',tmpStr,1) then
       begin
        vToken:=FParser.NextTokenPos(vToken, stmt.smdEnd);
        tmpStr:=FParser.GetToken(vToken);
        FDatabase.ConnectParams.UserName:=tmpStr;
       end
       else
       if IsClause('PASSWORD',tmpStr,1) then
       begin
        vToken:=FParser.NextTokenPos(vToken, stmt.smdEnd);
        tmpStr:=FParser.GetToken(vToken);
        FDatabase.ConnectParams.Password:=tmpStr;
       end;

       FDatabase.Connected:=True;
       FDatabase.DropDatabase;
     end;
     sDisconnect:
       FDatabase.Connected:=False;
     sConnect:
     begin
      CreateInternalDatabase;
      try
        if FDatabase.Connected then
         FDatabase.Close;
        vToken:=FParser.NextTokenPos(stmt.smdBegin, stmt.smdEnd);
        FDataBase.DBName:=FParser.GetToken(vToken);
        vToken:=FParser.NextTokenPos(vToken, stmt.smdEnd);
        SetConnectParams(vToken,stmt.smdEnd);
        FDatabase.Connected:=True;

        PreparePreDefines;
      except
        on E :EFIBError do
        begin
         if Assigned(FOnExecuteError) then
         begin
          FPaused:=True;
          FOnExecuteError(Self,StmtNo+1,stmt.smdBegin.Y+1,TmpSQL,E.SQLCode,E.Message,doRollBack,FPaused);
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
        on E :EFIBError do
        begin
         if Assigned(FOnExecuteError) then
         begin
          FPaused:=True;
          FOnExecuteError(Self,StmtNo+1,stmt.smdBegin.Y+1,TmpSQL,E.SQLCode,E.Message,doRollBack,FPaused);
          if GetTransaction.InTransaction then
            GetTransaction.RollBack
         end
         else
          raise;
        end;
      end;
     sDirective:
     begin
       if TmpSQL.Count>0 then
        if IsClause(dExecBlock,TmpSQL[0],1) then
        begin
         tmpStr:=Trim(Copy(TmpSQL.Text,16,MaxInt));
         SetLength(tmpStr,Length(tmpStr)-1);
         tmpStr:=UpperCase(Trim(tmpStr));
         if IsClause('ON',tmpStr,1) then
          FUseExecBlockForDML:=True
         else
         if IsClause('OFF',tmpStr,1) then
          FUseExecBlockForDML:=False
         else
          RaiseParserDirectiveError(dExecBlock,stmt.smdBegin.Y);
        end
        else
        if IsClause(dDefine,TmpSQL[0],1) then
        begin
         tmpStr:=Trim(Copy(TmpSQL.Text,10,MaxInt));
         SetLength(tmpStr,Length(tmpStr)-1);
         tmpStr:=UpperCase(Trim(tmpStr));
         if FDefines.IndexOf(tmpStr)<0 then
          FDefines.Add(UpperCase(tmpStr))
        end
        else
        if IsClause(dUnDefine,TmpSQL[0],1) then
        begin
         tmpStr:=Trim(Copy(TmpSQL.Text,8,MaxInt));
         SetLength(tmpStr,Length(tmpStr)-1);
         tmpStr:=UpperCase(Trim(tmpStr));
         i:=FDefines.IndexOf(tmpStr);
         if i>=0 then
          FDefines.Delete(i);
        end
        else
        if IsClause(dSetVar,TmpSQL[0],1) then
        begin
         tmpStr:=Trim(Copy(TmpSQL.Text,6,MaxInt));
         SetLength(tmpStr,Length(tmpStr)-1);
//         tmpStr:=UpperCase(Trim(tmpStr));
         i:=Pos('=',tmpStr);
         if i>0 then
         begin
          tmpStr1:=Trim(Copy(TmpStr,i+1,MaxInt));
          SetLength(TmpStr,i-1);
          TmpStr:=Trim(UpperCase(TmpStr));
          if (Length(TmpStr)>0) and (Length(TmpStr1)>0)  then
           FDirectiveConsts.Values[TmpStr]:=tmpStr1;
         end
        end
         else
          raise Exception.Create('Unknown directive :'+CLRF+
           'Line '+IntToStr(stmt.smdBegin.Y)+CLRF+
           TmpSQL.Text
          );


     end;
     sRollBack:
      if GetTransaction.InTransaction then
        GetTransaction.Rollback;
     sSet:
     begin
      vToken:=FParser.NextTokenPos(stmt.smdBegin, stmt.smdEnd);
      if vToken.X>0 then
      begin
       tmpStr:=FParser.GetToken(vToken);
       if IsClause('AUTODDL',tmpStr,1) then
       begin
        vToken:=FParser.NextTokenPos(vToken, stmt.smdEnd);
        if (vToken.X>0) then
        begin
          tmpStr:=FParser.GetToken(vToken);
          if IsClause('ON',tmpStr,1) then
           FAutoDDL:=True
          else
          if IsClause('OFF',tmpStr,1) then
           FAutoDDL:=False
        end
       end
       else
       if IsClause('SQL',tmpStr,1) then
       begin
        vToken:=FParser.NextTokenPos(vToken, stmt.smdEnd);
        if (vToken.X>0) then
        begin
          tmpStr:=FParser.GetToken(vToken);
          if IsClause('DIALECT',tmpStr,1) then
          begin
           vToken:=FParser.NextTokenPos(vToken, stmt.smdEnd);
           if (vToken.X>0) then
           begin
            tmpStr:=FParser.GetToken(vToken);
            FSQLDialect:=StrToInt(tmpStr)
           end;
          end;
        end;
       end
       else
       if IsClause('NAMES',tmpStr,1) then
       begin
        vToken:=FParser.NextTokenPos(vToken, stmt.smdEnd);
        if (vToken.X>0) then
        begin
         FCharSet:=FParser.GetToken(vToken);
        end
       end
       else //CLIENTLIB
       if IsClause('CLIENTLIB',tmpStr,1) then
       begin
        vToken:=FParser.NextTokenPos(vToken, stmt.smdEnd);
        if vToken.X<>0 then
        begin
         tmpStr:=FParser.GetToken(vToken);
         FLibraryName:= FParser.GetToken(vToken);
        end
       end
       else
       if IsClause('BLOBFILE',tmpStr,1) then
       begin
        vToken:=FParser.NextTokenPos(vToken, stmt.smdEnd);
        if (vToken.X>0) then
        begin
         if Assigned(FBlobFileStream) then
         begin
          FBlobFileStream.Free;
          FBlobFileStream:=nil;
         end;
         FBlobFile:=FParser.GetToken(vToken);
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
       vToken:=FParser.NextTokenPos(stmt.smdBegin, stmt.smdEnd);
       if (vToken.X>0) then
       begin
        tmpSQL.Clear;
        case stmt.objType of
         otDomain:
          tmpSQL.Add('UPDATE RDB$FIELDS SET RDB$DESCRIPTION = :DESCR WHERE (RDB$FIELD_NAME = :FIELD)');
         otView,otTable:
         begin
          tmpSQL.Add('UPDATE RDB$RELATIONS SET RDB$DESCRIPTION = :DESCR '+
           'WHERE RDB$RELATION_NAME = :TABNAME');
         end;
         otTrigger:
          tmpSQL.Add(
           'UPDATE RDB$TRIGGERS SET RDB$DESCRIPTION = :DESCR WHERE (RDB$TRIGGER_NAME = :TR_NAME)');
         otField:
          tmpSQL.Add('UPDATE RDB$RELATION_FIELDS SET RDB$DESCRIPTION = :DESCR '+
           'WHERE (RDB$RELATION_NAME = :TABNAME) and (RDB$FIELD_NAME = :FIELD)');
         otParameter:
          tmpSQL.Add('UPDATE RDB$PROCEDURE_PARAMETERS SET RDB$DESCRIPTION = :DESCR '+
           'WHERE (RDB$PROCEDURE_NAME = :PROCNAME) and(RDB$PARAMETER_NAME = :FIELD)');
         otProcedure:
           tmpSQL.Add('UPDATE RDB$PROCEDURES SET RDB$DESCRIPTION = :DESCR '+
            'WHERE (RDB$PROCEDURE_NAME = :PROCNAME)');

         otException:
           tmpSQL.Add('UPDATE RDB$EXCEPTIONS SET RDB$DESCRIPTION = :DESCR '+
            'WHERE (RDB$EXCEPTION_NAME = :EXC_NAME)');
         otFunction:
          tmpSQL.Add(
           'update RDB$FUNCTIONS set RDB$DESCRIPTION = ?DESC where (RDB$FUNCTION_NAME = ?FUNC_NAME)'
          );
         otUDF:
          tmpSQL.Add(
           'update RDB$FUNCTIONS set RDB$DESCRIPTION = ?DESC where (RDB$FUNCTION_NAME = ?FUNC_NAME)'
          );

         otGenerator:
          tmpSQL.Add(
           'update RDB$GENERATORS SET RDB$DESCRIPTION = ?DESC where (RDB$GENERATOR_NAME = ?GEN_NAME)'
          );
         otPackage:
           tmpSQL.Add('UPDATE RDB$PACKAGES SET RDB$DESCRIPTION = :DESCR '+
            'WHERE (RDB$PACKAGE_NAME = :PACKAGENAME)');

        else
         tmpStr:=FParser.GetToken(vToken) ;
         raise Exception.Create('Unsupported DESCRIBE type '+tmpStr) // mark as invalid later
        end;


        vToken:=FParser.NextTokenPos(vToken, stmt.smdEnd); // Object Name
        tmpStr:=FParser.GetToken(vToken) ; // Object Name

        FQuery.SQL.Assign(tmpSQL);

        if stmt.objType in [otField,otParameter] then
        begin
         FQuery.Params[2].AsString:=tmpStr; // Parameter name;
         vToken:=FParser.NextTokenPos(vToken, stmt.smdEnd); // Owner object type
         vToken:=FParser.NextTokenPos(vToken, stmt.smdEnd); // Owner object name
         FQuery.Params[1].AsString:=FParser.GetToken(vToken);
        end
        else
         FQuery.Params[1].AsString:=tmpStr; // Object Name
         vToken:=FParser.NextTokenPos(vToken, stmt.smdEnd);

         CopyFragment(vToken,stmt.smdEnd,TmpSQL);
         FQuery.Params[0].AsString := AnsiDequotedStr(TmpSQL.Text,'''');
{$IFNDEF BEZBAZY}
         if not GetTransaction.InTransaction then
           GetTransaction.StartTransaction;
         FQuery.ExecQuery;
{$ENDIF}
       end;
     end;
     sRunFromFile:
     begin
       vToken:=FParser.NextTokenPos(stmt.smdBegin, stmt.smdEnd); // FileName
       tmpStr:=FParser.GetToken(vToken) ; // FileName
       ExecuteFromFile(tmpStr)
     end;
    else
       case stmt.smtType of
        sInsert:
         begin
          vLastInsertStmt:=TmpSQL.Text;
          vReinsPrepared := False;
         end;
        sReinsert :
         TmpSQL.Text:=PrepareReinsert(vLastInsertStmt,TmpSQL.Text);
       end;


     FQuery.SQL:=TmpSQL;     // SQL statement
     skip:=False;

     if FUseExecBlockForDML and  MayBeInBlock then
      if((Length(FBlobFile)=0) or  (FQuery.ParamCount=0)) then
      begin
         skip:=AddStatementToExecuteBlock(TmpSQL);
         if not skip then
         begin
           FQuery.SQL:=FExecBlockStatement;     // Force exec block
           RestartBlock;
           AddStatementToExecuteBlock(TmpSQL);
         end
      end
      else // DML with params
      if Assigned(FExecBlockStatement) and (vBlockSize>0) then
      begin
         CloseBlock;
         FQuery.SQL:=FExecBlockStatement;  // Force exec block
         RestartBlock;
         ApplyCommand;
         FQuery.SQL:=TmpSQL;     // Current SQL statement
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

procedure TpFIBScripter.ExecuteScript(FromStmt:integer=1);
var
   i:integer;
   sc:Integer;
   stmt:PStatementDesc;
   TmpSQL:TStrings;
begin
  vLastInsertStmt:='';
  vReinsPrepared:=False;

  FPaused:=False;
  if not FPrepared then
   Parse;

  FSQLDialect:=3;
  FCharSet   :='';
  TmpSQL:=TStringList.Create;
  try
    sc:=StatementsCount-1;
    for i:=FromStmt-1 to sc do
    begin
     if FPaused  then
     begin
      FStopStatementNo:=i+1;
      Exit;
     end;

     stmt:=GetStatement(i+1,TmpSQL);
     case stmt.smtType of
      sBatchStart:
      begin
       FInBatchCollect:=True;
       SetLength(FBatchSQLs,0)
      end;
      sBatchExecute:
      begin
       FInBatchCollect:=False;
       if not GetTransaction.InTransaction then
          GetTransaction.StartTransaction;

       if Assigned(FBeforeStatementExecute) then
        FBeforeStatementExecute(Self,stmt.smdBegin.Y+1,i+1,stmt^,nil);
 {$IFDEF SUPPORT_IB2007}
       FQuery.ExecuteAsBatch(FBatchSQLs);
 {$ELSE}
       raise
        Exception.Create('Batch execute support for IB2007 only');
 {$ENDIF}
       SetLength(FBatchSQLs,0)
      end
     else
      if not FInBatchCollect then
       ExecuteStatement(TmpSQL,stmt,i,TmpSQL)
      else
      begin
       SetLength(FBatchSQLs,Length(FBatchSQLs)+1);
       FBatchSQLs[Length(FBatchSQLs)-1]:=TmpSQL.Text;
      end
     end
    end;

   if FUseExecBlockForDML then
      if Assigned(FExecBlockStatement) and (vBlockSize>0) then
      begin
         CloseBlock;
         FQuery.SQL:=FExecBlockStatement;     // Force execute block
         RestartBlock;
         if not GetTransaction.InTransaction then
          GetTransaction.StartTransaction;
         FQuery.ExecQuery;
      end;

  finally
   if Assigned(Database) and FNeedRestoreForceWrite and Database.Connected then
   begin
    if GetTransaction.InTransaction then
      GetTransaction.Commit;

    Database.Connected:=False;
    Database.DBParams.Values['force_write']:='1';
    Database.Connected:=True;
   end;


   if vInternalDatabase then
   begin
     if GetTransaction.InTransaction then
      GetTransaction.Commit;
     Database:=nil;
   end   ;



   TmpSQL.Free;
   if Assigned(FBlobFileStream) then
   begin
    FBlobFileStream.Free;
    FBlobFileStream:=nil;
   end;
  end;
end;

function TpFIBScripter.GetStatement(StmtNo: integer;
  Text: TStrings): PStatementDesc;
begin
  if StmtNo>Length(FScriptMap) then
   raise
     Exception.Create('Statement ¹'+IntToStr(StmtNo)+' don''t exist');
  Result:=@FScriptMap[StmtNo-1];
  CopyFragment(Result.smdBegin,Result.smdEnd,Text);
end;

procedure TpFIBScripter.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if Operation = opRemove then
  begin
    if AComponent = FDatabase then
      FDatabase := nil
    else
    if AComponent = FExternalTransaction then
      FExternalTransaction:=nil;
  end;
end;

procedure TpFIBScripter.Parse(Terminator:string=';');
begin
 FMakeConnectInScript:=False;
 FHaveDMLStatements    :=False;
 FHaveUnknownStatements:=False;
 FLibraryName   := 'gds32.dll';
 FParser.ParseScript(FScript,Terminator,FScriptMap,FDirectivesMap );
 FPrepared:=True;

 FMakeConnectInScript:=FParser.FMakeConnectInScript;
 FHaveDMLStatements    :=FParser.FHaveDMLStatements;
 FHaveUnknownStatements:=FParser.FHaveUnknownStatements;
end;

procedure TpFIBScripter.SetDatabase(const Value: TpFIBDatabase);
begin
  if GetTransaction.InTransaction then
   GetTransaction.Commit;

  if Assigned(FDatabase) then
   if vInternalDatabase and
    ((Value=nil) or (Value.Owner<>Self)) then // Old database -  InternalDatabase
   begin
    FDatabase.Free;
    vInternalDatabase:=False;
   end;
  FDatabase := Value;
  if Assigned(FDatabase) then
    FreeNotification(FDatabase);
  FTransaction.DefaultDatabase:=FDatabase;
  if Assigned(FExternalTransaction) then
   FExternalTransaction.DefaultDatabase:=FDatabase;
  FQuery.Database:=FDatabase;
  FQuery.Transaction:=GetTransaction;

end;

procedure TpFIBScripter.SetScript(const Value: TStrings);
begin
  FScript.Assign(Value);
end;

procedure TpFIBScripter.SetDefines(const Value: TStrings);
var
  i:integer;
begin
  FDefines.Clear;
  if Value<>nil then
   for I := 0 to Value.Count-1 do
    if FDefines.IndexOf(UpperCase(Value[i]))<0 then
     FDefines.Add(UpperCase(Value[i]))
end;


procedure TpFIBScripter.AddDefine(const Def:string);
begin
   if FDefines.IndexOf(UpperCase(Def))<0 then
     FDefines.Add(UpperCase(Def))
end;

procedure TpFIBScripter.DeleteDefine(const Def:string);
var
 i:integer;
begin
   i:= FDefines.IndexOf(UpperCase(Def));
   if i>=0 then
     FDefines.Delete(i)
end;


procedure   TpFIBScripter.PreparePreDefines;
var I:Integer;
begin
  DeleteDefine(srvIsFirebird);
  I:= FDirectiveConsts.IndexOfName( srvMajorVer);
  if I>=0 then
   FDirectiveConsts.Delete(I);

  I:= FDirectiveConsts.IndexOfName(srvMinorVer);
  if I>=0 then
   FDirectiveConsts.Delete(I);

  I:= FDirectiveConsts.IndexOfName(dbODSMajorVersion);
  if I>=0 then
   FDirectiveConsts.Delete(I);

  I:= FDirectiveConsts.IndexOfName(dbODSMinorVersion);
  if I>=0 then
   FDirectiveConsts.Delete(I);

  if Assigned(FDatabase) and FDatabase.Connected then
  with FDatabase do
  begin
    if IsFirebirdConnect then
       AddDefine(srvIsFirebird);
    FDirectiveConsts.Values[srvMajorVer]:=IntToStr(ServerMajorVersion);
    FDirectiveConsts.Values[srvMinorVer]:=IntToStr(ServerMinorVersion);
    FDirectiveConsts.Values[dbODSMajorVersion]:=IntToStr(ODSMajorVersion);
    FDirectiveConsts.Values[dbODSMinorVersion]:=IntToStr(ODSMinorVersion);
  end;
end;

procedure TpFIBScripter.SetConnectParams(StartToken: TStmtCoord;EndCoord:TStmtCoord);
var
   vToken:TStmtCoord;
   tmpStr:String;
begin
      FDataBase.Connected:=False;
      FDataBase.DBParams.Clear;
      vToken:=StartToken;
      while  (vToken.X<>0) do
      begin
       tmpStr:=FParser.GetToken(vToken);
       if IsClause('USER',tmpStr,1) then
       begin
        vToken:=FParser.NextTokenPos(vToken, EndCoord);
        if vToken.X<>0 then
         FDataBase.ConnectParams.UserName:=FParser.GetToken(vToken);
       end
       else
       if IsClause('PASSWORD',tmpStr,1) then
       begin
        vToken:=FParser.NextTokenPos(vToken, EndCoord);
        if vToken.X<>0 then
         FDataBase.ConnectParams.Password:=FParser.GetToken(vToken);
       end
       else
       if IsClause('ROLE',tmpStr,1) then
       begin
        vToken:=FParser.NextTokenPos(vToken, EndCoord);
        if vToken.X<>0 then
         FDataBase.ConnectParams.RoleName:=FParser.GetToken(vToken);
       end
       else
       if IsClause('SET',tmpStr,1) then
       begin
        vToken:=FParser.NextTokenPos(vToken, EndCoord);
        if vToken.X<>0 then
        begin
         tmpStr:=FParser.GetToken(vToken);
         if IsClause('CHARACTER',tmpStr,1) then
         begin
          vToken:=FParser.NextTokenPos(vToken, EndCoord);
          if vToken.X<>0 then
          begin
           tmpStr:=FParser.GetToken(vToken);
           FDataBase.ConnectParams.CharSet:=FParser.GetToken(vToken);
          end
         end
        end
       end;
       if vToken.X<>0 then
        vToken:=FParser.NextTokenPos(vToken, EndCoord);
      end;
      FDatabase.SQLDialect:=FSQLDialect;
      if FLibraryName<>'' then
       FDataBase.LibraryName:= FLibraryName;
      FDatabase.ConnectParams.CharSet:=FCharSet;
end;

function TpFIBScripter.StatementsCount: integer;
begin
 Result:=Length(FScriptMap)
end;

function  GetLineCountInFile(const FileName:string):integer;
var
  F: TextFile;
begin
  Result:=0;
  AssignFile(F, FileName);
  Reset(F);
  try
    repeat
      ReadLn(F);
      Inc(Result)
    until EOF(F);
  finally
    CloseFile(F);
  end;
end;

procedure TpFIBScripter.ExecuteFromFile(const FileName: string;Terminator:string=';');
var
  F: TextFile;
  S: string;
  vStatement: TStrings;
  FullScript:TStrings;
  Map:TScriptMap;
  CDMap:TDirectivesMap;
  i,j:integer;
  PredTerm:string;
  vRunStatement:TStrings;
  MapIndex:integer;
begin
  vLastInsertStmt:='';
  vReinsPrepared:=False;
  FLineCountInFile:=GetLineCountInFile(FileName);
  FPaused:=False;
  AssignFile(F, FileName);
  Reset(F);
  vStatement:=TStringList.Create;
  vRunStatement:=TStringList.Create;
  FullScript:=FScript;
  i:=0; j:=0; S:='';
  try
    PreparePreDefines;
    FParser.FScript:=vStatement;
    FScript:=vStatement;
    repeat
      if FPaused then
      begin
       FStopStatementNo:=i+1;
       Exit;
      end;
      if Length(S)>0 then
       vStatement.Add(S);
      ReadLn(F, S);
      vStatement.Add(S);
      Inc(j);
      PredTerm:=Terminator;
      if  Pos(Terminator,S)>0 then
       FParser.ParseScript(vStatement,Terminator,Map,CDMap,False);
      S:='';
      if (Length(Map)>=1) and (Map[0].smdEnd.X>0) then
      begin
       case Map[0].smtType of
        sBatchStart:
        begin
         vStatement.Clear;
         FInBatchCollect:=True;
         SetLength(FBatchSQLs,0)
        end;
        sBatchExecute:
        begin
         vStatement.Clear;
         FInBatchCollect:=False;
         if not GetTransaction.InTransaction then
            GetTransaction.StartTransaction;
         if Assigned(FBeforeStatementExecute) then
          FBeforeStatementExecute(Self,j,i+1,Map[0],nil);
 {$IFDEF SUPPORT_IB2007}
       FQuery.ExecuteAsBatch(FBatchSQLs);
       SetLength(Map,0);
 {$ELSE}
       raise
        Exception.Create('Batch execute support for IB2007 only');
 {$ENDIF}
         SetLength(FBatchSQLs,0)
        end
       else
          if not FInBatchCollect then
          begin
           MapIndex:=0;
           while MapIndex<Length(Map) do
           begin
            if (Map[MapIndex].smdEnd.X>0) then
            begin
             CopyFragment(Map[MapIndex].smdBegin,Map[MapIndex].smdEnd,vRunStatement);
             ExecuteStatement(vRunStatement,@Map[MapIndex],i,vRunStatement,j);
            end
            else
              S:=Copy(vStatement[vStatement.Count-1],Map[MapIndex].smdBegin.X,MaxInt);
            Inc(MapIndex)
           end;
           SetLength(Map,0)
          end
          else
          begin
           SetLength(FBatchSQLs,Length(FBatchSQLs)+1);
           FBatchSQLs[Length(FBatchSQLs)-1]:=vStatement.Text;
          end;
          vStatement.Clear;
       end;
       Inc(i)
      end
      else
      if Terminator<>PredTerm then // change terminator
      begin
       vStatement.Clear;
       Inc(i)
      end;
    until EOF(F);
  finally
   CloseFile(F);

   FParser.FScript:=FullScript;
   FScript:=FullScript;

   vStatement.Free;
   vRunStatement.Free;

   if FNeedRestoreForceWrite then
   begin
    Database.Connected:=False;
    Database.DBParams.Values['force_write']:='1';
    Database.DBParams.Values['no_reserve']:='0';
    Database.Connected:=True;
   end;

   if vInternalDatabase then
   begin
     if GetTransaction.InTransaction then
      GetTransaction.Commit;
     Database:=nil;
   end   ;

   if Assigned(FBlobFileStream) then
   begin
    FBlobFileStream.Free;
    FBlobFileStream:=nil;
   end;
  end;
end;

procedure TpFIBScripter.SetTransaction(const Value: TpFIBTransaction);
begin
  FExternalTransaction:= Value;
  if Value<>nil then
  begin
  if FExternalTransaction.DefaultDatabase<>FDatabase then
     FExternalTransaction.DefaultDatabase:=FDatabase;
   FQuery.Transaction:=FExternalTransaction;
  end
  else
   FQuery.Transaction:=FTransaction;
end;

function TpFIBScripter.GetTransaction: TpFIBTransaction;
begin
 if Assigned(FExternalTransaction) then
  Result:=FExternalTransaction
 else
  Result:=FTransaction
end;

function TpFIBScripter.LineCountInCurrentFile: integer;
begin
 Result:=FLineCountInFile;
end;

procedure TpFIBScripter.SetOnStatExec(CallBack: TOnScriptStatementExec);
begin
 FInternalOnStatementExec:=CallBack
end;

{ TpFIBScriptParser }



procedure TpFIBScriptParser.ParseScript(AScript: TStrings;var Terminator:string;
    var FScriptMap:TScriptMap;var  FCDMap: TDirectivesMap;IgnoreLastTerm:boolean);
type TTermState=(ttNorma,ttMayBeChange,ttWaitChange);

var
   x,y:integer;
   pd:TParseDisposition;
   CurStr:String;
   lCurStr:integer;
   State:TParserState;
   TermState:TTermState;
   NewTerminator:string;
   CurStmt:Integer;
   vCanEndStmt:boolean;
   CurDirective,LastDirective  :integer;
   DirectivesStack: array of integer;

procedure FixBeginStatement;
var
 L:Integer;
begin
  Inc(CurStmt);
  pd:=pdInStatement;
  L:=Length(FScriptMap);
  if L<CurStmt then
  begin
   if L>64 then
    Inc(L,L div 4)
   else
   if L>8 then
    Inc(L,16)
   else
    Inc(L,4);
   SetLength(FScriptMap,L);
  end;
  FScriptMap[CurStmt-1].smdBegin:=StmtCoord(X,Y);
  FScriptMap[CurStmt-1].DirectiveNum:=CurDirective;
  if CurDirective>=0 then
  FScriptMap[CurStmt-1].DirectiveElse:=
   (FCDMap[CurDirective].dElse.X>0) or (FCDMap[CurDirective].dElse.Y>0)
end;

procedure FixBeginDirective;
var
 L:Integer;
 newDir:PDirectiveDesc;
begin
  Inc(LastDirective);
  L:=Length(FCDMap);
  if L<LastDirective then
  begin
   if L>64 then
    Inc(L,L div 4)
   else
   if L>8 then
    Inc(L,16)
   else
    Inc(L,4);
   SetLength(FCDMap,L);
  end;

  newDir:=@FCDMap[LastDirective-1];
  newDir.dBegin:=StmtCoord(X,Y);
  if Length(DirectivesStack)=0 then
   newDir.OwnerDirectiveNum:=-1
  else
  begin
   newDir.OwnerDirectiveNum:=DirectivesStack[Length(DirectivesStack)-1];
   newDir.OwnerDirectiveElse:=     (FCDMap[newDir.OwnerDirectiveNum].dElse.X>0)
    or (FCDMap[newDir.OwnerDirectiveNum].dElse.Y>0)
  end;
   // Push
  SetLength(DirectivesStack,Length(DirectivesStack)+1);
  CurDirective:=LastDirective-1;
  DirectivesStack[Length(DirectivesStack)-1]:=CurDirective;

end;

procedure FixConditionCloseDirective;
begin
//
 if Length(DirectivesStack)>0 then
 begin
  FCDMap[DirectivesStack[Length(DirectivesStack)-1]].dConditionClose:=StmtCoord(X,Y)
 end
 else
  RaiseParserDirectiveError('}',Y);
end;



procedure FixElseDirective;
begin
//
 if Length(DirectivesStack)>0 then
  FCDMap[DirectivesStack[Length(DirectivesStack)-1]].dElse:=StmtCoord(X,Y)
 else
  RaiseParserDirectiveError(dElse,Y);
end;

procedure FixEndIfDirective;
begin
//
 if Length(DirectivesStack)>0 then
 begin
  FCDMap[DirectivesStack[Length(DirectivesStack)-1]].dEnd:=StmtCoord(X,Y);
  if Length(DirectivesStack)>0 then
   CurDirective:=DirectivesStack[Length(DirectivesStack)-1]-1
  else
   CurDirective:=-1;
  SetLength(DirectivesStack,Length(DirectivesStack)-1); // Pop
 end
 else
  RaiseParserDirectiveError(dEndIf,Y);
end;

var
 L:integer;

begin
  FCurDBName:='';
//Term str
//  NewTerminator:=Terminator;
  NewTerminator:='';
  FScript:=AScript;
  TermState:=ttNorma;
  pd:=pdBetweenStatements;
  State:=psNormal;
  L:=FScript.Count div 16;
  if L<3 then
   L:=3;
  SetLength(FScriptMap,L);


  CurStmt:=0;
  LastDirective:=0;
  CurDirective:=-1;
  vCanEndStmt:=True;
 try
  for y:=0 to Pred(FScript.Count) do
  begin
   CurStr:=FScript.Strings[y];
   lCurStr:=Length(CurStr);
//    for x:=1 to lCurStr do
   x:=0;
   if lCurStr>0 then
//   while x <= lCurStr do
   while x < lCurStr do
   begin
    Inc(x);
    case pd of
     pdBetweenStatements :
     case State of
      psNormal:
       case  CurStr[x] of
        '-': if (x<lCurStr) and (CurStr[x+1]='-') then
              Break // FBComment
             else
             begin
              FixBeginStatement;
              FScriptMap[CurStmt-1].smtType:=sInvalid;
             end;
        '/': if (x<lCurStr) and (CurStr[x+1]='*') then
              State:=psInComment
             else
             begin
              FixBeginStatement;
              FScriptMap[CurStmt-1].smtType:=sInvalid;
             end;
        ' ',#13,#10,#9: ;
        'S','s':// May be set
        if IsClause('SET',CurStr,x) then
        begin
          FixBeginStatement;
          TermState:=ttMayBeChange;
          FScriptMap[CurStmt-1].smtType:=sSet;
        end
        else
        begin
          FixBeginStatement;
          FScriptMap[CurStmt-1].smtType:=sUnknown;
        end;
        '{':
          if  IsClause(dElse,CurStr,x) then
          begin
           FixElseDirective;
           Inc(x,6)
          end
          else
          if  IsClause(dEndIf,CurStr,x) then
          begin
           FixEndIfDirective;
           Inc(x,7)
          end
          else
{          if (x<lCurStr+4) and (CurStr[x+1]='$') and
             (CurStr[x+2] in ['I','i']) and
             (CurStr[x+3] in ['F','f'])}
           if  StrIsIfDirective(CurStr,x) then
           begin
              State:=psInConditional;
              FixBeginDirective
           end
           else
           begin
            FixBeginStatement;
            pd:=pdInDirective;
            if (x<lCurStr+1) and (CurStr[x+1]='$')  then
             FScriptMap[CurStmt-1].smtType:=sDirective
            else
             FScriptMap[CurStmt-1].smtType:=sInvalid;
           end;
       else
//Term str
//        if CurStr[x]<>NewTerminator then
        if not IsClause(NewTerminator,CurStr,x) then
        begin
          FixBeginStatement;
          FScriptMap[CurStmt-1].smtType:=sUnknown;
        end
       end; // case CurStr[x]
      psInComment:
         case  CurStr[x] of
          '/': if (x>1) and (CurStr[x-1]='*') then
                 State:=psNormal;
         end;
      psInConditional:
         case  CurStr[x] of
          '}': begin
                FixConditionCloseDirective;
                State:=psNormal;
               end;
         end;

     end; // end case state
    pdInDirective:
     case CurStr[x] of
     '}':
         begin
          FScriptMap[CurStmt-1].smdEnd:=StmtCoord(X,Y);
          pd:=pdBetweenStatements
         end
     end;
    pdInStatement:  //  case pd
     case State of
      psNormal:
         case CurStr[x] of
          '''':  State:=psInQuote;
          '"' :  State:=psInDoubleQuote;
          '-' : if (x<lCurStr) and (CurStr[x+1]='-') then
                 Break; // FBComment
          '/': if (x<lCurStr) and (CurStr[x+1]='*') then
              State:=psInComment;
          'T','t': if (TermState=ttMayBeChange) and IsClause('TERM',CurStr,x) then
                   begin
                    TermState:=ttWaitChange;
                    Inc(x,4)
                   end;
          '{':
          begin
            raise Exception.Create('Parse script error.'+CLRF+' Unexpected symbol "{"'+CLRF+
             'Line :'+IntToStr(y+1)+' Pos:'+IntToStr(x)
            );
          end;
         else // else case
          if (TermState=ttWaitChange) and not (CurStr[x] in [' ',#13,#10,#9])
          and not IsClause(Terminator,CurStr,x)
//Term str
          then
          begin
           NewTerminator:=NewTerminator+CurStr[x]
          end;
          if  IsClause(Terminator,CurStr,x) then
          begin
           if (TermState=ttWaitChange) then
           begin
             Terminator:=NewTerminator;
             NewTerminator:='';
             TermState:=ttNorma;
             Dec(CurStmt) //
           end
           else
           begin
            TermState:=ttNorma;
            if (X>1) or (Y=0) then
             FScriptMap[CurStmt-1].smdEnd:=StmtCoord(X-1,Y)
            else
             FScriptMap[CurStmt-1].smdEnd:=StmtCoord(Length(FScript[Y-1]),Y-1);
             if FScriptMap[CurStmt-1].smtType<>sInvalid then
              vCanEndStmt:=ValidateStatement(FScriptMap[CurStmt-1],Terminator=';');
           end;
           if vCanEndStmt then
           begin
            pd:=pdBetweenStatements;
            if FScriptMap[CurStmt-1].smtType =sDML then
             FHaveDMLStatements:=True
            else
            if FScriptMap[CurStmt-1].smtType in [sUnknown,sInvalid] then
             FHaveUnknownStatements:=True
           end
           else
            FScriptMap[CurStmt-1].smdEnd.X:=0;
          end;
         end;
      psInComment:
         case  CurStr[x] of
          '/': if (x>1) and (CurStr[x-1]='*') then
                 State:=psNormal;
         end;
      psInQuote:
         case  CurStr[x] of
          '''':  State:=psNormal;
         end;
      psInDoubleQuote:
         case  CurStr[x] of
          '"':  State:=psNormal;
         end;
     end;
    end; // end case pd
   end
  end;
 finally

   SetLength(FScriptMap,CurStmt);
   SetLength(FCDMap,LastDirective);
   FValidationInfo.Active:=False;
   if IgnoreLastTerm  then
    if Length(FScriptMap)>0 then
     if  (FScriptMap[CurStmt-1].smdEnd.X=0)  then // End term don't exist
     begin
      FScriptMap[CurStmt-1].smdEnd.X:=Length(FScript[FScript.Count-1]);
      FScriptMap[CurStmt-1].smdEnd.Y:=FScript.Count-1;
      ValidateStatement(FScriptMap[CurStmt-1],False)
     end;

   if  Length(DirectivesStack)>0 then
   begin
      raise Exception.Create('Parse script error.'+CLRF+'$ENDIF skipped '+
       IntToStr(Length(DirectivesStack))+' times'
      );
   end
 end
end;

//================
constructor TpFIBScriptParser.Create;
begin
  inherited;
  FTemp  :=TStringList.Create;
end;

destructor TpFIBScriptParser.Destroy;
begin
  FTemp.Free;
  inherited;
end;

procedure TpFIBScriptParser.SearchObjectType(var stmtDesc:TStatementDesc;var BegSearch:TStmtCoord;ForGrant:boolean=False);
var
  TmpCoord1:TStmtCoord;
  CurStr:string;
  S:string;

begin
   TmpCoord1:=NextTokenPos(BegSearch,stmtDesc.smdEnd);
   While (TmpCoord1.X<>0) do
   begin                 // CREATE UNIQUE ASCENDING INDEX
     CurStr:=FScript[TmpCoord1.Y];
     if not ForGrant then
     begin
       stmtDesc.objType:=TypeNameToObjectType(CurStr,TmpCoord1.X);
       if stmtDesc.objType=otNone then
        TmpCoord1:=NextTokenPos(TmpCoord1,stmtDesc.smdEnd)
       else
        Break
     end
     else
     begin
     // GRANTS
      S:=GetToken(TmpCoord1);
      if IsClause('ON',CurStr,TmpCoord1.X) then
      begin
        TmpCoord1:=NextTokenPos(TmpCoord1,stmtDesc.smdEnd);
        stmtDesc.objType:=TypeNameToObjectType(CurStr,TmpCoord1.X);
        if stmtDesc.objType<>otNone then
         TmpCoord1:=NextTokenPos(TmpCoord1,stmtDesc.smdEnd);
        stmtDesc.objName:=GetToken(TmpCoord1);
        BegSearch:=TmpCoord1;
        Exit
      end
      else
        TmpCoord1:=NextTokenPos(TmpCoord1,stmtDesc.smdEnd)
     end;
   end;
   if stmtDesc.objType<>otNone then
     BegSearch:=TmpCoord1;
end;

function   TpFIBScriptParser.ValidateStatement(var stmtDesc: TStatementDesc;const NeedCheckCanEnd:boolean ):boolean;
var
   CurStr:string;
   TmpCoord:TStmtCoord;
   DeltaProcessed:boolean;

procedure ValidateDelta;
var
   ExistAs:boolean;
   BegCount:integer;
   StrIndex:integer;
begin
   DeltaProcessed:=False;
   if NeedCheckCanEnd then
    if  (stmtDesc.objType in [otProcedure,otTrigger,otBlock,otPackage,otPackageBody,otFunction]) and (stmtDesc.smtType<>sDrop) then
    begin
      DeltaProcessed:=True;
      Result:=False;
      if FValidationInfo.Active then
      begin
       TmpCoord:=FValidationInfo.smdEnd;
       BegCount:=FValidationInfo.BegCount;
      end
      else
      begin
        BegCount:=0;
        ExistAs:=False;
        TmpCoord:=NextTokenPos(TmpCoord,stmtDesc.smdEnd);
        StrIndex:=-1;
        While (TmpCoord.X<>0) do
        begin
           if TmpCoord.Y<>StrIndex then
           begin
            StrIndex:=TmpCoord.Y;
            CurStr:=FScript[StrIndex];
           end;
           if IsClause('AS',CurStr,TmpCoord.X) then
           begin
            ExistAs:=True;
           end
           else
           if IsClause('BEGIN',CurStr,TmpCoord.X) then
           begin
            BegCount:=1;
            FValidationInfo.Active:=True;
            FValidationInfo.BeginExist:=True;
            FValidationInfo.BegCount:=1;
            FValidationInfo.smdEnd:=stmtDesc.smdEnd;
            Inc(FValidationInfo.smdEnd.X);
            Break;
           end;
           TmpCoord:=NextTokenPos(TmpCoord,stmtDesc.smdEnd);
        end;

        if (BegCount=0) then
        begin
        // Before first begin
         if not ExistAs then  // ALTER TRIGGER INACTIVE
           Result:=True
         else
         begin
          FValidationInfo.smdEnd:=stmtDesc.smdEnd;
          Inc(FValidationInfo.smdEnd.X)
         end;
          FValidationInfo.Active:=not Result;
          FValidationInfo.BeginExist:=False;
          FValidationInfo.BegCount:=0;
         Exit;
        end;
      end;


      TmpCoord:=NextTokenPos(TmpCoord,stmtDesc.smdEnd);
      StrIndex:=-1;
      While (TmpCoord.X<>0) do
      begin
        if TmpCoord.Y<>StrIndex then
        begin
            StrIndex:=TmpCoord.Y;
            CurStr:=FScript[StrIndex];
        end;

         if IsClause('BEGIN',CurStr,TmpCoord.X) or IsClause('CASE',CurStr,TmpCoord.X)
         then
          if FValidationInfo.BeginExist then
           Inc(BegCount)
          else
          begin
           if IsClause('BEGIN',CurStr,TmpCoord.X) then
            FValidationInfo.BeginExist:=True;
           BegCount  :=1;
          end
         else
         if IsClause('END',CurStr,TmpCoord.X) then
          Dec(BegCount);
         if (BegCount=0) and FValidationInfo.BeginExist then
         begin
          Result:=True;
          FValidationInfo.Active:=False;
          Exit;
         end;
         TmpCoord:=NextTokenPos(TmpCoord,stmtDesc.smdEnd);
      end;

      if not FValidationInfo.Active then
       FValidationInfo.Active:=True;
       FValidationInfo.BegCount:=BegCount;
       FValidationInfo.smdEnd:=stmtDesc.smdEnd;
       Inc(FValidationInfo.smdEnd.X)
    end;
end;

begin
   Result:=True;
   ValidateDelta;
   if DeltaProcessed then
     Exit;
// Step 1
   CurStr:=FScript.Strings[stmtDesc.smdBegin.Y];
   stmtDesc.smtType:=StmtTypeNameToType(CurStr,stmtDesc.smdBegin.X);
// Step 2
   stmtDesc.objType:=otNone;

   case stmtDesc.smtType of
    sConnect  :
    begin
      stmtDesc.objType:=otDatabase;
      TmpCoord:=NextTokenPos(stmtDesc.smdBegin,stmtDesc.smdEnd);
      if TmpCoord.X<>0 then
      begin
        stmtDesc.objName:=GetToken(TmpCoord);
        FCurDBName:=stmtDesc.objName;
      end;
      FMakeConnectInScript:=True;
    end;
    SReconnect,sDisconnect,sCommit,sRollback:
    begin
      stmtDesc.objName:=FCurDBName;
      stmtDesc.objType:=otDatabase;
    end;

    sAlter,sCreate,sDrop,sRecreate,sExecute: // Next Word may be type Object
    begin
     TmpCoord:=NextTokenPos(stmtDesc.smdBegin,stmtDesc.smdEnd);
     if TmpCoord.X<>0 then
     begin
       if  stmtDesc.smtType=sExecute then
       begin
         CurStr:=GetToken(TmpCoord);
         stmtDesc.smtType:=sDML;
         if IsClause('BLOCK',CurStr,1) then
          stmtDesc.objType:=otBlock
         else
          Exit;
       end
       else
       begin
        CurStr:=FScript[TmpCoord.Y];
        stmtDesc.objType:=TypeNameToObjectType(CurStr,TmpCoord.X);
       end ;
       case stmtDesc.objType of
        otNone:
         SearchObjectType(stmtDesc,TmpCoord);
        otDatabase: case stmtDesc.smtType of
                     sCreate:
                     begin
                      FMakeConnectInScript:=True;
                      stmtDesc.smtType:=sCreateDatabase;
                     end;
                     sDrop  : stmtDesc.smtType:=sDropDatabase
                    end;
       end;

       if  stmtDesc.objType<>otBlock then
       begin
        TmpCoord:=NextTokenPos(TmpCoord,stmtDesc.smdEnd);
          if TmpCoord.X<>0 then
           stmtDesc.objName:=GetToken(TmpCoord)
          else
           stmtDesc.objName:='';

        if (stmtDesc.objType = otPackage) and IsClause('BODY',stmtDesc.objName,1) then
        begin
          stmtDesc.objType := otPackageBody;

          TmpCoord:=NextTokenPos(TmpCoord,stmtDesc.smdEnd);
          if TmpCoord.X<>0 then
           stmtDesc.objName:=GetToken(TmpCoord)
          else
           stmtDesc.objName:='';
        end;


       end;
       if  stmtDesc.smtType=sCreateDatabase then
        FCurDBName:=stmtDesc.objName
       else
       if  stmtDesc.smtType=sDropDatabase then
        stmtDesc.objName:=FCurDBName;


        ValidateDelta;
      end;
    end;
    sDeclare:
    begin
     stmtDesc.objType:=otNone;
     TmpCoord:=NextTokenPos(stmtDesc.smdBegin,stmtDesc.smdEnd);
     if TmpCoord.X<>0 then
     begin
       CurStr:=FScript[TmpCoord.Y];
       if IsClause('EXTERNAL',CurStr,TmpCoord.X) then
         stmtDesc.objType:=otUDF
       else
       if IsClause('FILTER',CurStr,TmpCoord.X) then
         stmtDesc.objType:=otFilter;
       case stmtDesc.objType of
         otUDF:
         begin
           TmpCoord:=NextTokenPos(TmpCoord,stmtDesc.smdEnd);
           TmpCoord:=NextTokenPos(TmpCoord,stmtDesc.smdEnd);
           if TmpCoord.X<>0 then
            stmtDesc.objName:=GetToken(TmpCoord)
           else
            stmtDesc.objName:=''
         end;
       end
     end
    end;
    sSet:
    begin
     stmtDesc.objType:=otNone;
     TmpCoord:=NextTokenPos(stmtDesc.smdBegin,stmtDesc.smdEnd);
     if TmpCoord.X<>0 then
     begin
       CurStr:=FScript[TmpCoord.Y];
       if IsClause('GENERATOR',CurStr,TmpCoord.X) then
       begin
         stmtDesc.objType:=otGenerator;
         stmtDesc.smtType:=sSetGenerator;
       end
       else
       if IsClause('STATISTICS',CurStr,TmpCoord.X) then
       begin
         stmtDesc.objType:=otIndex;
         stmtDesc.smtType:=sSetStatistics;
         TmpCoord:=NextTokenPos(TmpCoord,stmtDesc.smdEnd);
       end;




       if stmtDesc.objType<>otNone then
       begin
         TmpCoord:=NextTokenPos(TmpCoord,stmtDesc.smdEnd);
         if TmpCoord.X<>0 then
          stmtDesc.objName:=GetToken(TmpCoord)
         else
          stmtDesc.objName:='';
       end;
     end
    end;
    sGrant:
    begin
     TmpCoord:=NextTokenPos(stmtDesc.smdBegin,stmtDesc.smdEnd);
     SearchObjectType(stmtDesc,TmpCoord,True)
    end
    ;
    sBatch: // Temporary type
    begin
     TmpCoord:=NextTokenPos(stmtDesc.smdBegin,stmtDesc.smdEnd);
     CurStr:=FScript[TmpCoord.Y];
     if IsClause('START',CurStr,TmpCoord.X) then
     begin
      stmtDesc.smtType:=sBatchStart;
//      FInBatchCollect:=True;
     end
     else
     if IsClause('EXECUTE',CurStr,TmpCoord.X) then
     begin
      stmtDesc.smtType:=sBatchExecute;
//      FInBatchCollect:=False
     end
     else
      stmtDesc.smtType:=sInvalid;
    end;
    sDescribe,sComment:
    begin
     TmpCoord:=NextTokenPos(stmtDesc.smdBegin,stmtDesc.smdEnd);
     if stmtDesc.smtType=sComment then
      TmpCoord:=NextTokenPos(TmpCoord,stmtDesc.smdEnd);
     if TmpCoord.X<>0 then
     begin
       stmtDesc.objType:=TypeNameToObjectType(CurStr,TmpCoord.X);
       if stmtDesc.objType<>otNone then
       begin
         TmpCoord:=NextTokenPos(TmpCoord,stmtDesc.smdEnd);
         if TmpCoord.X<>0 then
           stmtDesc.objName:=GetToken(TmpCoord)
         else
           stmtDesc.objName:='';

         if stmtDesc.smtType=sDescribe then
         case stmtDesc.objType of
          otField,otParameter:
          begin
           TmpCoord:=NextTokenPos(TmpCoord,stmtDesc.smdEnd); // Table,View or Procedure
           TmpCoord:=NextTokenPos(TmpCoord,stmtDesc.smdEnd); // Object Name
           if TmpCoord.X<>0 then
            stmtDesc.objName:=GetToken(TmpCoord)+'.'+stmtDesc.objName
           else
            stmtDesc.objName:='';
          end;
         end;
       end;
     end
    end;
   end;
end;


function TpFIBScriptParser.NextTokenPos(TokenPos: TStmtCoord;EndCoord:TStmtCoord): TStmtCoord;
var
  State:TParserState;
  i:Word;
  j:Integer;
  CurStr:string;
  lCurStr:integer;
  FirstChar:Char;
begin
  CurStr:=FScript[TokenPos.Y];
  lCurStr:=Length(CurStr);
  Result.X:=lCurStr;
  if LCurStr>0 then
  begin
    FirstChar:=CurStr[TokenPos.X];
    for i:=TokenPos.X to lCurStr do // Skip first Token
      if FirstChar in ['''','"'] then
      begin
        if i> TokenPos.X then
         if CurStr[i] =FirstChar then
         begin
          Result.X:=i+1;
          Break
         end
      end
      else
      if CurStr[i] in [' ',#13,#9,#10,'/','-',';'] then
      begin
        Result.X:=i;
        Break
      end
  end;
  if Result.X=lCurStr then
  begin
   i:=1;
   Inc(TokenPos.Y)
  end
  else
   i:= Result.X;
  Result.X:=0;
  State:=psNormal;
  for j:=TokenPos.Y to EndCoord.Y do
  begin
   CurStr:=FScript[j];
   if TokenPos.Y<>EndCoord.Y then
    lCurStr:=Length(CurStr)
   else
    lCurStr:=EndCoord.X;
   while i<=lCurStr do
   begin
     case State of
      psNormal:
      case CurStr[i] of
       ' ',#13,#9,#10,';':; //Skip
       '-':if (i<lCurStr) and (CurStr[i+1]='-') then
                 Break; // FBComment
       '/':if (i<lCurStr) and (CurStr[i+1]='*') then
             State:=psInComment;
      else
       Result.Y:=j;
       Result.X:=i;
       Exit
      end;
      psInComment:
         case  CurStr[i] of
          '/': if (i>1) and (CurStr[i-1]='*') then
                 State:=psNormal;
         end;
     end;
     Inc(i)
   end;
   i:=1;
  end;
end;

function TpFIBScriptParser.GetToken(TokenPos: TStmtCoord;IgnoreQuote:boolean=True): string;
var
   CurStr:string;
   StartPosInStr:Word;
   EndPosInStr:Word;
   p:PChar;
   L:integer;
begin
   CurStr:=FScript[TokenPos.Y];
   StartPosInStr:=TokenPos.X;
   if (CurStr[StartPosInStr] in ['''','"']) and IgnoreQuote then
   begin
    EndPosInStr:=PosCh1(CurStr[StartPosInStr],CurStr,StartPosInStr+1);
    if EndPosInStr=0 then
     raise
        Exception.Create('Can''t find end token');
    Inc(StartPosInStr);
   end
   else
   begin
    EndPosInStr:=StartPosInStr;
    L:=Length(CurStr);
    while (EndPosInStr<=L) and
     not (CurStr[EndPosInStr] in [#9,#13,#10,' ','-','/',',',';','('])
    do
     Inc(EndPosInStr);
   end;


    L:=EndPosInStr-StartPosInStr;
    SetLength(Result,L);
    if L>0 then
    begin
     p:=Pointer(CurStr);
     Inc(p,StartPosInStr-1);
     Move(p^,Result[1],L*SizeOf(Char))
    end;
//    SetString(Result,@CurStr[StartPosInStr],EndPosInStr-StartPosInStr)
end;

function TpFIBScriptParser.TypeNameToObjectType(
  const TestString:string; Position:integer): TObjectType;
begin
 Result:=otNone;
 case TestString[Position] of
  'C','c':
       if IsClause('CONSTRAINT',TestString,Position) then
         Result:=otConstraint
       else
       if IsClause('COLUMN',TestString,Position) then
         Result:=otField;
  'D','d':
       if IsClause('DATABASE',TestString,Position) then
          Result:=otDatabase
       else
       if IsClause('DOMAIN',TestString,Position) then
         Result:=otDomain;
  'E','e':
       if IsClause('EXCEPTION',TestString,Position) then
         Result:=otException;

  'F','f':
       if IsClause('FIELD',TestString,Position) then
         Result:=otField
       else
       if IsClause('FUNCTION',TestString,Position) then
         Result:=otFunction
       else
       if IsClause('FILTER',TestString,Position) then
         Result:=otFilter;
   'G','g':
       if IsClause('GENERATOR',TestString,Position) then
         Result:=otGenerator;
   'I','i':
       if IsClause('INDEX',TestString,Position) then
         Result:=otIndex;
   'P','p':
       if IsClause('PROCEDURE',TestString,Position) then
         Result:=otProcedure
       else
       if IsClause('PARAMETER',TestString,Position) then
         Result:=otParameter
       else
       if IsClause('PACKAGE',TestString,Position) then
         Result:=otPackage;

   'R','r':
       if IsClause('ROLE',TestString,Position) then
         Result:=otRole;
   'T','t':
       if IsClause('TABLE',TestString,Position) then
          Result:=otTable
       else
       if IsClause('TRIGGER',TestString,Position) then
         Result:=otTrigger;
   'U','u':
          if IsClause('USER',TestString,Position) then
           Result:=otUser;
   'V','v':
       if IsClause('VIEW',TestString,Position) then
          Result:=otView;

 end;
end;

function TpFIBScriptParser.StmtTypeNameToType(
  const TestString: string; Position: integer): TStmtType;
begin
   Result:=sUnknown;
   case TestString[Position] of
    'A','a': // May be alter
         if IsClause('ALTER',TestString,Position) then
         begin
          Result:=sAlter;
         end;
    'B','b':
         if IsClause('BATCH',TestString,Position) then
         begin
           Result:=sBatch ;
         end;
    'C','c': // May be Create,Connect,Comment
         if IsClause('CREATE',TestString,Position) then
         begin
           Result:=sCreate ;
         end
         else
         if IsClause('COMMIT',TestString,Position) then
         begin
           Result:=sCommit;
         end
         else
         if IsClause('COMMENT',TestString,Position) then
         begin
          Result:=sComment;
         end
         else
         if IsClause('CONNECT',TestString,Position) then
         begin
          Result:=sConnect;
         end;
     'D','d':// May be drop,describe,declare
         if IsClause('DROP',TestString,Position) then
         begin
          Result:=sDrop;
         end
         else
         if IsClause('DECLARE',TestString,Position) then
         begin
          Result:=sDeclare;
         end
         else
         if IsClause('DESCRIBE',TestString,Position) then
         begin
          Result:=sDescribe;
         end
         else
         if IsClause('DELETE',TestString,Position) then
         begin
          Result:=sDML;
         end
         else
         if IsClause('DISCONNECT',TestString,Position) then
         begin
          Result:=sDisconnect;
         end;

     'E','e':
         if IsClause('EXECUTE',TestString,Position) then
         begin
          Result:=sExecute;
         end;
     'G','g':
         if IsClause('GRANT',TestString,Position) then
         begin
          Result:=sGrant;
         end;
     'I','i': // may be Insert;
         if IsClause('INSERT',TestString,Position) then
         begin
          Result:=sInsert;
         end
         else
         if IsClause('INPUT',TestString,Position) then
         begin
          Result:=sRunFromFile;
         end;


     'M','m':
         if IsClause('MERGE',TestString,Position) then
         begin
          Result:=sDML;
         end;
     'U','u':
         if IsClause('UPDATE',TestString,Position) then
         begin
          Result:=sDML;
         end;
     'R','r':
      if IsClause('RECREATE',TestString,Position) then
      begin
        Result:=sRecreate;
      end
      else
      if IsClause('ROLLBACK',TestString,Position) then
      begin
        Result:=sRollBack;
      end
      else
      if IsClause('RECONNECT',TestString,Position) then
      begin
        Result:=sReconnect;
      end
      else
      if IsClause('REVOKE',TestString,Position) then
      begin
        Result:=sGrant;
      end
      else
      if IsClause('REINSERT',TestString,Position) then
      begin
        Result:=sReinsert;
      end;
     'S','s':
      if IsClause('SET',TestString,Position) then
      begin
        Result:=sSet;
      end;
   end;
end;


// Blob File Supports

procedure TpFIBScripter.TryFillBlobParams;
var
   i:Integer;
   pn:string;
   bPos,Len:Integer;
   m:TMemoryStream;
   p_:integer;
begin
  with FQuery do
  for i:=FQuery.ParamCount-1 downto 0 do
  begin
    pn:=FQuery.ParamName(i);
    if pn[1] in ['H','h'] then
    begin
     p_:= Pos('_', pn);
     bPos := HexStr2Int(Copy(pn, 2, p_-2));
     Len  := HexStr2Int(Copy(pn, p_+1, Length(pn)-p_));
     if Len=0 then
      FQuery.Params[i].Clear
     else
     begin
      if not Assigned(FBlobFileStream) then
       FBlobFileStream:=TFileStream.Create(FBlobFile,fmOpenRead{$IFDEF D6+},fmShareDenyWrite{$ENDIF});
      m := TMemoryStream.Create;
      try
       m.Size := Len;
       m.Position:=0;
       FBlobFileStream.Position:=bPos;
       FBlobFileStream.Read(m.Memory^,Len);
       FQuery.Params[i].LoadFromStream(m);
      finally
       m.Free;
      end
     end;
    end;
  end
end;

//Reinsert

function  TpFIBScripter.PrepareReinsert(const InsTxt,ReInsTxt:string):string;
var I,L:integer;
    StartValues:integer;
begin
  if vReinsPrepared then
  begin
   Result:=vLastInsertStmt+Copy(ReInsTxt,9,MaxInt);
   Exit;
  end;

  StartValues:=0;
  L:=Length(InsTxt);
  for I := 6 to L do
  begin
    case InsTxt[i] of
     'V','v':
       if IsClause('VALUES',InsTxt,I) then
         StartValues:=I
    end;
  end;
  if (StartValues>0) then
  begin
   vReinsPrepared :=True;
   vLastInsertStmt:=Copy(InsTxt,1,StartValues+5);
   Result:=vLastInsertStmt+Copy(ReInsTxt,9,MaxInt)
  end
  else
   Result:=ReInsTxt;
end;

 // AutoExecBlock support
procedure TpFIBScripter.RestartBlock;
begin
     vBlockContextCount:=0;
     vBlockSize:=0;
     FExecBlockStatement.Clear;
end;

procedure TpFIBScripter.CloseBlock;
begin
 FExecBlockStatement.Add('END');
end;

function  TpFIBScripter.AddStatementToExecuteBlock(Stmt:TStrings):boolean;
var i,L:integer;
begin
 if not Assigned(FExecBlockStatement) then
   FExecBlockStatement:=TStringList.Create;
 Result:=vBlockContextCount<255;
 if not Result then
 begin
  FExecBlockStatement.Add('END');
  Exit;
 end;
 if FExecBlockStatement.Count=0 then
 begin
    vBlockContextCount:=0;
    FExecBlockStatement.Add('EXECUTE BLOCK AS BEGIN');
    vBlockSize:=Length(FExecBlockStatement[0])+2;
 end;
 L:=0;
 for I := 0 to stmt.Count-1 do
  Inc(L,Length(stmt[I])+2);
 Result:=(vBlockSize+L+2+1)<High(Word)-3; // 3 for 'END'
 if Result then
 begin
  FExecBlockStatement.AddStrings(Stmt);
  FExecBlockStatement[FExecBlockStatement.Count-1]:=
    FExecBlockStatement[FExecBlockStatement.Count-1]+';';
  Inc(vBlockSize,L);
  Inc(vBlockContextCount);
 end
 else
  FExecBlockStatement.Add('END');
end;

end.
