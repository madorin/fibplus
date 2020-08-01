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
unit DBParsers;

interface
{$I FIBPlus.inc}
 uses SysUtils,Classes,DB,DBCommon,DbConsts,FIBPlatforms

  {$IFDEF D6+}  ,Variants,FMTBcd{$ENDIF}
 ;

 type

  TStrToDateFmt = function (const ADate,Fmt:string):TDateTime;
  TMatchesMask  = function (const S1, Mask: string): Boolean;

  TExpressionParser = class(TExprParser)
  private
    FExpressionText  :string;
    FDataSet:TDataSet;
    FStrToDateFmt    :TStrToDateFmt;
    FMatchesMask     :TMatchesMask;
    FFilteredFields  :TStringList;
    function  FieldByName(const FieldName:string):TField;
    function  VarResult :Boolean;
  public
    constructor Create(DataSet: TDataSet; const Text: string;
      Options: TFilterOptions; ParserOptions: TParserOptions;
      const FieldName: string; DepFields: TBits; FieldMap: TFieldMap;
     aStrToDateFmt:TStrToDateFmt=nil;
     aMatchesMask :TMatchesMask=nil
    );
    destructor Destroy; override;
    procedure ResetFields;
    function  BooleanResult: Boolean;
    property  StrToDateFmt:TStrToDateFmt read FStrToDateFmt write FStrToDateFmt;
    property  MatchesMask :TMatchesMask read FMatchesMask write FMatchesMask;
    property  ExpressionText :string read FExpressionText;
  end;


implementation

{ TExpressionParser}
 uses StrUtil {$IFDEF D6+} ,StdFuncs {$ENDIF};


constructor TExpressionParser.Create(DataSet: TDataSet; const Text: string;
  Options: TFilterOptions; ParserOptions: TParserOptions;
  const FieldName: string; DepFields: TBits; FieldMap: TFieldMap;
  aStrToDateFmt:TStrToDateFmt=nil;
  aMatchesMask :TMatchesMask=nil
);
begin
 try
  inherited Create(DataSet,Text,  Options,ParserOptions,  FieldName,DepFields,FieldMap);
 except
  on e: Exception do
  begin
    e.Message:='Can''t parse Filter for: '+CLRF+e.Message;
    raise;
  end;
 end;
 FExpressionText  :=Text; 
 FDataSet:=DataSet;
 FStrToDateFmt:=aStrToDateFmt;
 FMatchesMask :=aMatchesMask;
 FFilteredFields  :=TStringList.Create;
 with FFilteredFields do
 begin
   Sorted:=true;
   Duplicates:=dupIgnore
 end;    // with
end;

destructor TExpressionParser.Destroy;
begin
  FFilteredFields.Free;
  inherited;
end;


function  TExpressionParser.FieldByName(const FieldName:string):TField;
var
 i:integer;
begin
 if FFilteredFields.Find(FieldName,i) then
  Result:=TField(FFilteredFields.Objects[i])
 else
 begin
  Result:=FDataSet.FieldByName(FieldName);
  FFilteredFields.AddObject(FieldName,Result)
 end;
end;



{$WARNINGS OFF}
function  TExpressionParser.VarResult :Boolean;
var
  iLiteralStart: Word;
  
  function ParseNode(pfdStart, pfd: PAnsiChar): Variant;
  var
    I, Z,AD: Integer;
    Year, Mon, Day, Hour, Min, Sec, MSec: Word;
    iClass: NODEClass;
    iOperator: TCANOperator;
    pArg1,pArg2: PAnsiChar;
    Arg1,Arg2: Variant;
    FieldName: String;
    DataType: TFieldType;
    DataOfs: integer;
    ts: TTimeStamp;
    Cur: Currency;
    PartLength: Word;
    IgnoreCase: Word;
    S1,S2: Variant;
    S :string;
    {$IFDEF D2009+}
    us:UnicodeString;
    {$ENDIF}
    null1,null2:boolean;
    p,p1:integer;
  type
    PWordBool = ^WordBool;
  begin
    iClass := NODEClass(PInteger(@pfd[0])^);
    iOperator := TCANOperator(PInteger(@pfd[4])^);
    Inc(pfd, CANHDRSIZE);

    case iClass of
      nodeFIELD:
        case iOperator of
          coFIELD2:
            begin
              DataOfs := iLiteralStart + PWord(@pfd[2])^;
              pArg1 := pfdStart;
              Inc(pArg1, DataOfs);
              FieldName := string(pArg1);
              with FieldByName(FieldName) do
               {$IFNDEF D6+}
                   Result := FieldByName(FieldName).Value               
               {$ELSE}
                 case DataType of
                  ftBCD:
                   if IsNull then
                    Result:=Null
                   else
                    Result:=FieldByName(FieldName).Value
                 else
                   Result := FieldByName(FieldName).Value
                 end
               {$ENDIF}
            end;
        else
            DatabaseError(SExprIncorrect);
        end;
      nodeCONST:
        case iOperator of
          coCONST2:
            begin
             {$IFDEF D2007+}
              if PWord(@pfd[0])^ = $1007 then
               DataType := ftWideString
              else
             {$ENDIF}              
               DataType := TFieldType(PWord(@pfd[0])^);
              DataOfs := iLiteralStart + PWord(@pfd[4])^;
              pArg1 := pfdStart;
              Inc(pArg1, DataOfs);
              case DataType of
                ftSmallInt, ftWord:
                  Result := PWord(pArg1)^;
                ftInteger, ftAutoInc:
                  Result := PInteger(pArg1)^;
                ftFloat, ftCurrency:
                  Result := PDouble(pArg1)^;
                ftString, ftFixedChar:
                  Result := string(pArg1);
               {$IFDEF D2009+}
                ftWideString:
                begin
                  SetLength(us,PWord(pArg1)^ div 2);
                  Move(pArg1[2],us[1],PWord(pArg1)^) ;
                  Result:=us
                end;
               {$ENDIF}                
                ftDate:
                  begin
                    ts.Date := PInteger(pArg1)^;
                    ts.Time := 0;
                   {$IFDEF D6+}
                    Result := HookTimeStampToDateTime(ts);
                   {$ELSE}
                    Result := TimeStampToDateTime(ts);
                   {$ENDIF}
                  end;
                ftTime:
                  begin
                    ts.Date := 0;
                    ts.Time := PInteger(pArg1)^;;
                   {$IFDEF D6+}
                    Result := HookTimeStampToDateTime(ts);
                   {$ELSE}
                    Result := TimeStampToDateTime(ts);
                   {$ENDIF}
                  end;
                ftDateTime:
                begin
                  ts  :=MSecsToTimeStamp(PDouble(pArg1)^);
                 {$IFDEF D6+}
                    Result := HookTimeStampToDateTime(ts);
                 {$ELSE}
                    Result := TimeStampToDateTime(ts);
                 {$ENDIF}
                end;
                ftBoolean:
                  Result := PWordBool(pArg1)^;
                ftBCD:
                  begin
                    BCDToCurr(PBCD(pArg1)^, Cur);
                    Result := Cur;
                  end;
                {$IFDEF D6+}
                ftLargeInt:
                  Result := PInt64(pArg1)^;
                {$ENDIF}  
              else
                  DatabaseError(SExprIncorrect);
              end;
            end;
        end;
      nodeUNARY:
        begin
          pArg1 := pfdStart;
          Inc(pArg1, CANEXPRSIZE + PWord(@pfd[0])^);

          case iOperator of
            coISBLANK,coNOTBLANK:
              begin
                Arg1 := ParseNode(pfdStart, pArg1);
                Result := VarIsEmpty(Arg1) or VarIsNull(Arg1);
                if iOperator = coNOTBLANK then
                  Result := not Result;
              end;
            coNOT:
              Result := not WordBool(ParseNode(pfdStart, pArg1));
            coMINUS:
              Result := - ParseNode(pfdStart, pArg1);
            coUPPER:
              Result := AnsiUpperCase(VarToStr(ParseNode(pfdStart, pArg1)));
            coLOWER:
              Result := AnsiLowerCase(VarToStr(ParseNode(pfdStart, pArg1)));
          end;
        end;
      nodeBINARY:
        begin
          pArg1 := pfdStart;
          Inc(pArg1, CANEXPRSIZE + PWord(@pfd[0])^);
          pArg2 := pfdStart;
          Inc(pArg2, CANEXPRSIZE + PWord(@pfd[2])^);
          case iOperator of
            coAssign:Result := ParseNode(pfdStart, pArg1) ;
            coEQ:
              Result := ParseNode(pfdStart, pArg1) = ParseNode(pfdStart, pArg2);
            coNE:
              Result := ParseNode(pfdStart, pArg1) <> ParseNode(pfdStart, pArg2);
            coGT:
              Result := ParseNode(pfdStart, pArg1) > ParseNode(pfdStart, pArg2);
            coGE:
              Result := ParseNode(pfdStart, pArg1) >= ParseNode(pfdStart, pArg2);
            coLT:
              Result := ParseNode(pfdStart, pArg1) < ParseNode(pfdStart, pArg2);
            coLE:
              Result := ParseNode(pfdStart, pArg1) <= ParseNode(pfdStart, pArg2);
            coOR:
              Result := WordBool(ParseNode(pfdStart, pArg1)) or WordBool(ParseNode(pfdStart, pArg2));
            coAND:
              Result := WordBool(ParseNode(pfdStart, pArg1)) and WordBool(ParseNode(pfdStart, pArg2));
            coADD:
              Result := ParseNode(pfdStart, pArg1) + ParseNode(pfdStart, pArg2);
            coSUB:
              Result := ParseNode(pfdStart, pArg1) - ParseNode(pfdStart, pArg2);
            coMUL:
              Result := ParseNode(pfdStart, pArg1) * ParseNode(pfdStart,pArg2);
            coDIV:
              Result := ParseNode(pfdStart,pArg1) / ParseNode(pfdStart,pArg2);
            coMOD,coREM:
              Result := ParseNode(pfdStart,pArg1) mod ParseNode(pfdStart,pArg2);
            coIN:
              begin
                Arg1 := ParseNode(PfdStart, pArg1);
                Arg2 := ParseNode(PfdStart, pArg2);
                if VarIsArray(Arg2) then
                begin
                  Result := False;
                  AD:=VarArrayHighBound(Arg2, 1);
                  for I:=0 to AD do
                  begin
                    if VarIsEmpty(Arg2[I]) then break;
                    Result := (Arg1 = Arg2[I]);
                    if Result then break;
                  end;
                end
                else
                  Result := (Arg1 = Arg2);
              end;
            coLike:
              if Assigned(FMatchesMask) then
               Result :=
                FMatchesMask(
                  VarToStr(ParseNode(pfdStart, pArg1)),
                  VarToStr(ParseNode(pfdStart, pArg2))
                )
              else
               DatabaseError(SExprIncorrect);
          else
              DatabaseError(SExprIncorrect);
          end;
        end;
      nodeCOMPARE:
        begin
          IgnoreCase := PWord(@pfd[0])^;
          PartLength := PWord(@pfd[2])^;
          pArg1 := pfdStart + CANEXPRSIZE + PWord(@pfd[4])^;
          pArg2 := pfdStart + CANEXPRSIZE + PWord(@pfd[6])^;

          S1 := ParseNode(pfdStart, pArg1);
          S2 := ParseNode(pfdStart, pArg2);
          null1:=VarIsNull(S1);
          null2:=VarIsNull(S2);
          if (null1 <> null2) then
          begin
           Result :=iOperator=coNE;
           Exit;
          end
          else
          if null1 then
          begin
           Result :=iOperator<>coNE;
           Exit;
          end ;
          if IgnoreCase <> 0 then
          begin
            S1 := AnsiUpperCase(S1);
            S2 := AnsiUpperCase(S2);
          end;
          if (PartLength > 0) and (iOperator<>coLIKE) then
          begin
            S1 := Copy(S1, 1, PartLength);
            S2 := Copy(S2, 1, PartLength);
          end;
          case iOperator of
            coEQ:
              Result := S1 = S2;
            coNE:
              Result := S1 <> S2;
            coLIKE:
             if Assigned(FMatchesMask) then
              Result := FMatchesMask(S1, S2)
             else
              DatabaseError(SExprIncorrect)
          else
              DatabaseError(SExprIncorrect);
          end;
        end;
      nodeFUNC:
        case iOperator of
          coFUNC2:
            begin
              pArg1 := pfdStart;
              Inc(pArg1, iLiteralStart + PWord(@pfd[0])^);
              S :=AnsiUpperCase(pArg1);
              if Length(S) = 0 then
                DatabaseErrorFmt(SExprExpected, [S]);

              pArg2 := pfdStart;
              Inc(pArg2, CANEXPRSIZE + PWord(@pfd[2])^);
             case S[1] of    //
                'D':if S = 'DAY' then
                    begin
                      DecodeDate(VarToDateTime(ParseNode(pfdStart, pArg2)), Year, Mon, Day);
                      Result := Day;
                    end
                    else
                    if S = 'DATE' then
                    begin
                      Result := ParseNode(pfdStart, pArg2);
                      if VarIsArray(Result) then
                       if Assigned(FStrToDateFmt) then
                        Result := FStrToDateFmt(VarToStr(Result[1]), VarToStr(Result[0]))
                       else
                        DatabaseError(SExprIncorrect)
                      else
                        Result := Integer(Trunc(VarToDateTime(Result)));
                    end
                    else
                      DatabaseErrorFmt(SExprExpected, [S]);
                'G': if S = 'GETDATE' then  Result := Now
                     else
                      DatabaseErrorFmt(SExprExpected, [S]);
                'H':if S = 'HOUR' then
                    begin
                     DecodeTime(VarToDateTime(ParseNode(pfdStart, pArg2)), Hour, Min, Sec, MSec);
                     Result := Hour;
                    end
                    else
                     DatabaseErrorFmt(SExprExpected, [S]);
                'M':if S = 'MONTH' then
                    begin
                      DecodeDate(VarToDateTime(ParseNode(pfdStart, pArg2)), Year, Mon, Day);
                      Result := Mon;
                    end
                    else
                    if S = 'MINUTE' then
                    begin
                      DecodeTime(VarToDateTime(ParseNode(pfdStart, pArg2)), Hour, Min, Sec, MSec);
                      Result := Min;
                    end
                    else
                     DatabaseErrorFmt(SExprExpected, [S]);
                'U': if S = 'UPPER' then
                      Result := AnsiUpperCase(VarToStr(ParseNode(pfdStart, pArg2)))
                     else
                      DatabaseErrorFmt(SExprExpected, [S]);
                'L': if S = 'LOWER' then
                      Result := AnsiLowerCase(VarToStr(ParseNode(pfdStart, pArg2)))
                     else
                      DatabaseErrorFmt(SExprExpected, [S]);
                'Y': if S = 'YEAR' then
                     begin
                      DecodeDate(VarToDateTime(ParseNode(pfdStart, pArg2)), Year, Mon, Day);
                      Result := Year;
                     end
                     else
                      DatabaseErrorFmt(SExprExpected, [S]);
                'S': if S = 'SUBSTRING' then
                     begin
                      Result := ParseNode(pfdStart, pArg2);
                      if VarType(Result[1]) in [varSmallint,varInteger,varDouble,varSingle] then
                      begin
                       p :=Integer(Result[1]);
                       p1:=Integer(Result[2]);
                      end
                      else
                      begin
                       S:=VarToStr(Result[1]);
                       p:=PosCh(',',S);
                       p1:=0;
                       if p>0 then
                       begin
                         p1:=StrToInt(FastCopy(S,p+1,1000));
                         p :=StrToInt(FastCopy(S,1,p-1));
                       end
                       else
                        DatabaseErrorFmt(SExprExpected, [S]);
                      end;
                      Result := FastCopy(VarToStr(Result[0]), p, p1);
                     end
                     else
                     if S = 'SECOND' then
                     begin
                        DecodeTime(VarToDateTime(ParseNode(pfdStart, pArg2)), Hour, Min, Sec, MSec);
                        Result := Sec;
                     end
                     else
                      DatabaseErrorFmt(SExprExpected, [S]);
                'T':
                     case Length(S) of
                      4: if S = 'TRIM' then
                          Result := FastTrim(VarToStr(ParseNode(pfdStart, pArg2)))
                         else
                         DatabaseErrorFmt(SExprExpected, [S]);
                      8: if S = 'TRIMLEFT' then
                          Result := TrimLeft(VarToStr(ParseNode(pfdStart, pArg2)))
                         else
                          DatabaseErrorFmt(SExprExpected, [S]);
                      9: if S = 'TRIMRIGHT' then
                          Result := TrimRight(VarToStr(ParseNode(pfdStart, pArg2)))
                         else
                          DatabaseErrorFmt(SExprExpected, [S]);
                     end;

             else
                DatabaseErrorFmt(SExprExpected, [S]);
             end
            end
        else
            DatabaseError(SExprIncorrect);
        end;
      nodeLISTELEM:
        case iOperator of
          coLISTELEM2:
            begin
              Result := VarArrayCreate ([0, 50], VarVariant); // Create VarArray for ListElements Values
              pArg1 := pfdStart;
              Inc(pArg1, CANEXPRSIZE + PWord(@pfd[0])^);

              I := 0;
              repeat
                Arg1 := ParseNode(PfdStart, pArg1);
                if VarIsArray(Arg1) then
                begin
                  Z:=0;
                  while not VarIsEmpty(Arg1[Z]) do
                  begin
                    Result[I] := Arg1[Z];
                    Inc(I); Inc(Z);
                  end;
                end
                else
                begin
                  Result[I] := Arg1;
                  Inc(I);
                end;

                pArg1 := pfdStart;
                Inc(pArg1, CANEXPRSIZE + PWord(@pfd[I*2])^);
              until NODEClass(PInteger(@pArg1[0])^) <> NodeListElem;

              if I<2 then
                Result := VarAsType(Result[0], varString);
            end;
        else
            DatabaseError(SExprIncorrect);
        end;
    end;
  end;
var
  pfdStart, pfd: PAnsiChar;
begin
  pfdStart := Addr(FilterData[0]);
  pfd := pfdStart;
  iLiteralStart := PWord(@pfd[8])^;
  Inc(pfd, 10);
  Result := ParseNode(pfdStart, pfd);
end;
{$WARNINGS ON}
function TExpressionParser.BooleanResult: Boolean;
var
   V:Variant;
begin
  V:=VarResult;
  Result :=WordBool(V)
end;

procedure TExpressionParser.ResetFields;
begin
 FFilteredFields.Clear
end;

end.

