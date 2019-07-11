unit IBSQLSyn;

interface
 uses
         SysUtils,Classes,pFIBSyntaxMemo;

{
 procedure   FIBSQLTokens(Sender: TObject;
               StartPos,EndPos :Integer;
               const Line       : string;  var Token : TToken
             );

 procedure AddToSyntaxAttributes(N:TMPSyntaxAttributes);
 }
 procedure RegisterSyntax;
 function  IsReservedWord(const Line:string):boolean;

 procedure PrepareProposalItems(var PI:TMPProposalItems);
 procedure ProposalInternalFunctionsItems(ts1,ts2:TStrings);

var
    DefProposalShadow:TMPProposalItems;
    ProposalDelimiterShadow:string;

const
    tokKeyWord          = tokUser;
    tokFunction         = tokUser - 1;
    tokTypes            = tokUser - 2;
    tokParam            = tokUser - 3;
    
implementation
          {$IFDEF VER230}
  {$DEFINE D4+}
  {$DEFINE D5+}
  {$DEFINE D6+}
  {$DEFINE D7+}
  {$DEFINE D9+} //2006
  {$DEFINE D10+} //2007
  {$DEFINE D11+}//2009
  {$DEFINE D12+}//2010
  {$DEFINE D13+}
  {$DEFINE D_XE2}
  {$WARN UNSAFE_TYPE OFF}
  {$WARN UNSAFE_CODE OFF}
  {$WARN UNSAFE_CAST OFF}
  {$WARN SYMBOL_PLATFORM OFF}
  {$WARNINGS  OFF}
{$ENDIF}
 {$I ..\FIBPlus.inc}
uses
 {$IFDEF D_XE2}
  Vcl.Graphics
  {$ELSE}
  Graphics
  {$ENDIF}

;

function IsClause( const EtalonClause:string; const Source:string;
 Position:integer;EndPosition:integer
):boolean;
 // 1 аргумент обязан быть написан в uppercase. Это эталон
var
  Len:Integer;
  LenEtalon:Byte;
  pSource:PChar;
  pEtalon:PChar;
  pEtalon1:PChar;
begin
 Len:=EndPosition-Position+1;
 LenEtalon:=Length(EtalonClause);
// if Len-Position+1<LenEtalon then
 if Len<>LenEtalon then
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
        // все что не между 'a'..'z' должно отсеяться на пред проверке
          if Byte(pSource^)-32<>Byte(pEtalon^) then
          begin
            Result:=False;
            Break;
          end;
      end;
      Inc(pSource);
      Inc(pEtalon);
    end;
 end
end;



const
  InternalFunctionCount = 35;
  DefKeywordsCount = 281;

  DefTypesCount = 17;

  InternalFunctions: array [0..InternalFunctionCount-1] of string =
   ('AVG',    'CAST',    'COUNT',    'GEN_ID',
    'MAX',    'MIN',     'SUM',      'UPPER',
//Additional FB and YA
    'ABS','ASCII_CHAR','ASCII_VAL','BIN_OR','BIN_XOR','BIT_LENGTH', 'CHAR_LENGTH' , 'CHARACTER_LENGTH' ,'CEIL','COALESCE',
    'DATEADD',
    'EXTRACT',    'GEN_UUID','LIST','LOWER','NULLIF','TRIM','IIF','POSITION','REPLACE' ,'REVERSE','RIGHT' ,  'SUBSTRING',
     'OCTET_LENGTH',
    'RDB$SET_CONTEXT','RDB$GET_CONTEXT','TRUNC'

   );
  DefKeywords: array [0..DefKeywordsCount-1] of string = ('ACTIVE','ADD','AFTER','ALL','ALTER','AND','ANY',
    'AS','ASC','ASCENDING','AT','AUTO','AUTODDL','BASED','BASENAME','BASE_NAME','BEFORE',
    'BEGIN','BETWEEN',
    'BLOBEDIT','BUFFER','BY','BLOCK','CASE','CHARACTER_LENGTH','CHAR_LENGTH','CHECK',
    'CHECK_POINT_LENGTH','COLLATE','COLLATION','COLUMN','COMMIT',
    'COMMITED','COMPILETIME','COMPUTED','CROSS','CLOSE','CONDITIONAL','CONNECT','CONSTRAINT',
    'CONTAINING','CONTINUE','CREATE','CURRENT','CURRENT_DATE','CURRENT_TIME',
    'CURRENT_TIMESTAMP','CURSOR','DATABASE','DAY','DB_KEY','DEBUG','DEC','DECLARE','DEFAULT',
    'DELETE','DESC','DESCENDING','DESCRIBE','DESCRIPTOR','DISCONNECT','DISTINCT','DO',
    'DOMAIN','DROP','ECHO','EDIT','ELSE','END','ENTRY_POINT','ESCAPE','EVENT','EXCEPTION',
    'EXECUTE','EXISTS','EXIT','EXTERN','EXTERNAL',

    'FETCH','FILE','FILTER','FOR',
    'FOREIGN','FOUND','FROM','FULL',
    'FUNCTION','GDSCODE','GENERATOR','GLOBAL','GOTO','GRANT',
    'GROUP',
    'GROUP_COMMIT_WAIT_TIME',
    'HAVING','HELP','HOUR','IF',
    'IMMEDIATE','IN','INACTIVE','INDEX',
    'INDICATOR','INIT','INNER',
    'INPUT','INPUT_TYPE',
    'INSERT','INT','INTO','IS','ISOLATION','ISQL','JOIN',
    'KEY','LC_MESSAGES','LC_TYPE','LEFT',
    'LENGTH','LEV','LEVEL','LIKE','LOG_BUFFER_SIZE','LONG','MANUAL',
    'MAXIMUM','MAXIMUM_SEGMENT','MAX_SEGMENT','MERGE','MESSAGE','MINIMUM','MINUTE',
    'MODULE_NAME','MONTH','NAMES','NATIONAL','NATURAL','NCHAR','NO','NOAUTO','NOT','NULL',
    'NUM_LOG_BUFFERS','OCTET_LENGTH','OF','ON','ONLY','OPEN','OPTION','OR',
    'ORDER','OUTER','OUTPUT','OUTPUT_TYPE','OVERFLOW',
    'PAGE','PAGELENGTH','PAGES','PAGE_SIZE','PARAMETER','PASSWORD',
    'PLAN',
    'POSITION','POST_EVENT','PRECISION','PREPARE','PROCEDURE',
    'PROTECTED','PRIMARY','PRIVILEGES','PUBLIC','QUIT','READ','REAL',
    'RECORD_VERSION','REFERENCES','RELEASE','RESERV','RESERVING','RETAIN','RETURN',
    'RETURNING_VALUES','RETURNS','REVOKE','RIGHT',
    'ROLLBACK','ROWS','RUNTIME','SAVEPOINT','SCHEMA','SECOND',
    'SEGMENT','SELECT','SEQUENCE',
    'SET','SHADOW','SHARED','SHELL','SHOW','SIMILAR','SINGULAR','SIZE','SNAPSHOT','SOME',
    'SORT','SQL','SQLCODE','SQLERROR','SQLWARNING','STABILITY','STARTING','STARTS',
    'STATEMENT','STATIC','STATISTICS','SUB_TYPE','SUSPEND','TABLE','TERM','THEN','TO',
    'TRANSACTION','TRANSLATE','TRANSLATION','TRIGGER','TRUE','TYPE','UNCOMMITTED',
    'UNION', 'UNIQUE','UNKNOWN','UPDATE','USER','USING','VALUE','VALUES',
    'VARIABLE','VARYING','VERSION','VIEW',
    'WAIT','WEEKDAY','WHEN','WHENEVER','WHERE','WHILE','WITH',
    'WORKS','WRITE','YEAR','YEARDAY',
//Additional
    'FIRST','SKIP','RECREATE','CURRENT_USER',
    'CURRENT_ROLE','PLANONLY','LIMIT','SECONDS',
    'ROWS',
    'PERCENT','TIES','NEW','OLD',
    'CURRENT_CONNECTION', 'CURRENT_TRANSACTION',

    'INSERTING','UPDATING','DELETING','ROW_COUNT','FREE_IT','MATCHING','MATCHED','RETURNING',
    'CASCADE','NULLS','LAST','LEAVE',
    'LEADING','TRAILING','BOTH'

    );


  DefProposalCountDML=98;
  DefProposalKeywordsDML: array [0..DefProposalCountDML-1] of string =
    ('ALL','ANY',
    'AS','ASC','ASCENDING',
    'BEGIN','BETWEEN', 'BOTH',
    'BY','BLOCK','CASE',
    'CURRENT_CONNECTION', 'CURRENT_TRANSACTION',
    'CURRENT_DATE','CURRENT_USER',  'CURRENT_ROLE','CURRENT_TIME',
    'CROSS JOIN','CONTAINING',
    'CURRENT_TIMESTAMP','DAY',
    'DELETE FROM','DESC','DESCENDING','DISTINCT',
    'ELSE','END','ESCAPE',
    'EXECUTE PROCEDURE',
    'EXECUTE BLOCK',
    'EXECUTE STATEMENT',
    'EXISTS',
    'FIRST','FROM','FULL','FULL JOIN @@| ON()@',
    'GROUP BY',
    'HAVING','HOUR',
    'IN', 'INNER',   'INNER JOIN @@| ON()@', 'INSERT','INSERT INTO ','INTO','IS',    'INSERTING',
    'JOIN', 'JOIN @@| ON()@',
    'LAST','LEFT','LEFT JOIN @@| ON()@',  'LIKE',
    'LEADING',
    'MATCHED','MATCHING','MERGE','MINUTE',    'MONTH',
    'NOT','NULL', 'NULLS FIRST', 'NULLS LAST',
    'OF','OR', 'ORDER BY','OUTER JOIN @@| ON()@',

    'PLAN',    'PROCEDURE',

    'RELEASE SAVEPOINT@@(|)@', 'RETURNING','RIGHT','RIGHT JOIN',
    'ROWS',
    'SAVEPOINT@@(|)@','SECOND', 'SECONDS',   'SELECT',
    'SET','SINGULAR',
    'SKIP',    'SOME',    'STARTING WITH',    'STATEMENT',

    'THEN','TO',   'TIES', 'TRAILING',
    'UNION', 'UPDATE',
    'VALUES',

    'WEEKDAY','WHEN','WHERE','WHILE','WITH',
    'YEAR','YEARDAY'
    );

  DefTypes: array [0..DefTypesCount-1] of string =
  ('BLOB','CHAR','CHARACTER','DATE','DECIMAL','DOUBLE','FLOAT','INTEGER',
    'NUMERIC','SMALLINT','TIME','TIMESTAMP','VARCHAR',
//Additional
    'INT64', 'BIGINT', 'BOOLEAN', 'CSTRING');


 type
   TDynArray=array of Integer;

  var
    TabKeyWords: array['A'..'Z','A'..'Z'] of TDynArray;
    TabTypes:array['A'..'Z','A'..'Z'] of TDynArray;
    TabFunctions:array['A'..'Z','A'..'Z'] of TDynArray;


 function  IsReservedWord(const Line:string):boolean;
 var
   i,j:integer;
   ch,ch1:Char;
   L:integer;
 begin
   Result:=False;
   L:=Length(Line);
   if L=0 then
     Exit;

    ch:=Line[1];

    if (Ch >= 'a') and (Ch <= 'z') then Dec(Ch, 32);
    ch1:=Line[2];
    if (Ch1 >= 'a') and (Ch1 <= 'z') then Dec(Ch1, 32);

    if (Ch>='A')  and (Ch<='Z') and (Ch1>='A')  and (Ch1<='Z') then
    begin

     J:=Length(TabKeyWords[Ch,Ch1])-1;
     for i:=0 to J do
      if IsClause(DefKeywords[TabKeyWords[ch,ch1][i]],Line,1,L) then
      begin
          Result:=True;
          Exit
      end;

     J:=Length(TabTypes[Ch,Ch1])-1;
     for i:=0 to J do
      if IsClause(DefTypes[TabTypes[ch,ch1][i]],Line,1,L) then
      begin
          Result:=True;
          Exit
      end;

     J:=Length(TabFunctions[Ch,Ch1])-1;
     for i:=0 to J do
      if IsClause(InternalFunctions[TabFunctions[ch,ch1][i]],Line,1,L) then
      begin
          Result:=True;
          Exit
      end;

   end;

 end;

 procedure   FIBSQLTokens(Sender: TObject;
               StartPos,EndPos :Integer;
               const Line       : string; var Token : TToken
             );
 var
   i,j:integer;
   ch,ch1:Char;
 begin
   if EndPos-StartPos<1 then
     Exit;

    ch:=Line[StartPos];
    if ch in ['?',':'] then
    begin
     Token := TToken(tokParam);
     Exit;
    end;

    if (Ch >= 'a') and (Ch <= 'z') then Dec(Ch, 32);
    ch1:=Line[StartPos+1];
    if (Ch1 >= 'a') and (Ch1 <= 'z') then Dec(Ch1, 32);

    if (Ch>='A')  and (Ch<='Z') and (Ch1>='A')  and (Ch1<='Z') then
    begin
     J:=Length(TabKeyWords[Ch,Ch1])-1;
     for i:=0 to J do
      if IsClause(DefKeywords[TabKeyWords[ch,ch1][i]],Line,StartPos,EndPos) then
      begin
          Token := TToken(tokKeyWord);
          Exit
      end;

     J:=Length(TabTypes[Ch,Ch1])-1;
     for i:=0 to J do
      if IsClause(DefTypes[TabTypes[ch,ch1][i]],Line,StartPos,EndPos) then
      begin
        Token := TToken(tokTypes);
        Exit
      end;

     J:=Length(TabFunctions[Ch,Ch1])-1;
     for i:=0 to J do
      if IsClause(InternalFunctions[TabFunctions[ch,ch1][i]],Line,StartPos,EndPos) then
      begin
        Token := TToken(tokFunction);
        Exit
      end;

    end;  
 end;

  procedure AddToSyntaxAttributes(N:TMPSyntaxAttributes);
  begin
        with N do begin
            FontColor[tokKeyWord] := clBlack;
            FontStyle[tokKeyWord] := [fsBold];
            FontColor[tokParam]   := clPurple;
            FontStyle[tokParam] := [fsBold];
            LiteralILCompilerDirective:='';
            LiteralMLCommentBeg:='';
            LiteralMLCommentEnd:='';
            LiteralILComment:='--';
            LiteralELCommentBeg:='/*';
            LiteralELCommentEnd:='*/';
            CopyAttrs(tokKeyWord, [tokFunction,tokTypes]);
            ParseOptions:=ParseOptions-[poHasHexPrefix,poHasMLCompDir,poHasReference,poHasDereference];
        end;
  end;

 procedure InitTabKeyWords;
 var i,j:integer;
     c,c1:Char;
 begin
  for i:=0 to DefKeywordsCount-1 do
   begin
     c:=DefKeywords[i][1];
     c1:=DefKeywords[i][2];
     j:=Length(TabKeyWords[c,c1]);
     SetLength(TabKeyWords[c,c1],j+1);
     TabKeyWords[c,c1][j]:=i
   end;

  for i:=0 to DefTypesCount-1 do
   begin
     c:=DefTypes[i][1];
     c1:=DefTypes[i][2];
     j:=Length(TabTypes[c,c1]);
     SetLength(TabTypes[c,c1],j+1);
     TabTypes[c,c1][j]:=i
   end;

  for i:=0 to InternalFunctionCount-1 do
   begin
     c:=InternalFunctions[i][1];
     c1:=InternalFunctions[i][2];
     j:=Length(TabFunctions[c,c1]);
     SetLength(TabFunctions[c,c1],j+1);
     TabFunctions[c,c1][j]:=i
   end;


 end;

//

 procedure ProposalInternalFunctionsItems(ts1,ts2:TStrings);
 var
  i:Integer;
 begin
   ts1.Clear;
   ts2.Clear;

   for i:=0 to InternalFunctionCount-1 do
   begin
    ts2.Add(InternalFunctions[i]+'@@( | )@');
    if i<7 then
     ts1.Add('function '+ProposalDelimiter+'B '+InternalFunctions[i])
   else
     ts1.Add('function (FB) '+ProposalDelimiter+'N '+InternalFunctions[i]);
   end;
 end;


 procedure PrepareProposalItems(var PI:TMPProposalItems);
 var
  i:Integer;
  s:string;
  p:integer;
 begin
   PI[0].Clear;
   PI[1].Clear;

   for i:=0 to InternalFunctionCount-1 do
   begin
    PI[1].Add(InternalFunctions[i]+'@@( | )@');
    if i<7 then
     PI[0].Add('function '+ProposalDelimiter+'B '+InternalFunctions[i])
   else
     PI[0].Add('function (FB) '+ProposalDelimiter+'N '+InternalFunctions[i]);
   end;

  for i:=0 to DefProposalCountDML-1 do
   begin
     s:=DefProposalKeyWordsDML[i];
     p:=Pos('@',s);
     if p>0 then
       s:=Copy(s,1,p-1);
     PI[0].Add('SQL '+ProposalDelimiter+' '+s);
     PI[1].Add(DefProposalKeyWordsDML[i]);
   end;

  for i:=0 to DefTypesCount-1 do
   begin
     s:=DefTypes[i];
     p:=Pos('@',s);
     if p>0 then
       s:=Copy(s,1,p-1);
     PI[0].Add('Type '+ProposalDelimiter+'D'+' '+s);
     PI[1].Add(DefTypes[i]);
   end;

 end;

 procedure RegisterSyntax;
 begin
  DefUserTokenEventProc:=FIBSQLTokens;
  DefAddSyntaxAttributes:=AddToSyntaxAttributes;
  PrepareProposalItems(DefProposal);
 end;


initialization
 DefProposalShadow:=DefProposal;
 ProposalDelimiterShadow:=ProposalDelimiter;
 tokUserWords:=[
    tokKeyWord,    tokFunction,    tokTypes   ,    tokParam
 ];
 InitTabKeyWords
end.




