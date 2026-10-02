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

unit DBParsers;

interface

{$I FIBPlus.inc}

uses
  SysUtils, Classes, DB, DBCommon, DbConsts, FIBPlatforms, Variants, FMTBcd;

type

  TStrToDateFmt = function(const ADate, Fmt: string): TDateTime;
  TMatchesMask = function(const S1, Mask: string): Boolean;

  TExpressionParser = class(TExprParser)
  private
    FExpressionText: string;
    FDataSet: TDataSet;
    FStrToDateFmt: TStrToDateFmt;
    FMatchesMask: TMatchesMask;
    FFilteredFields: TStringList;
    function FieldByName(const FieldName: string): TField;
    function VarResult: Boolean;
  public
    constructor Create(DataSet: TDataSet; const Text: string;
      Options: TFilterOptions; ParserOptions: TParserOptions;
      const FieldName: string; DepFields: TBits; FieldMap: TFieldMap;
      aStrToDateFmt: TStrToDateFmt = nil; aMatchesMask: TMatchesMask = nil);
    destructor Destroy; override;
    procedure ResetFields;
    function BooleanResult: Boolean;
    property StrToDateFmt: TStrToDateFmt read FStrToDateFmt write FStrToDateFmt;
    property MatchesMask: TMatchesMask read FMatchesMask write FMatchesMask;
    property ExpressionText: string read FExpressionText;
  end;

implementation

uses
  StrUtil, StdFuncs;

{ TExpressionParser }

constructor TExpressionParser.Create(DataSet: TDataSet; const Text: string;
  Options: TFilterOptions; ParserOptions: TParserOptions;
  const FieldName: string; DepFields: TBits; FieldMap: TFieldMap;
  aStrToDateFmt: TStrToDateFmt = nil; aMatchesMask: TMatchesMask = nil);
begin
  try
    inherited Create(DataSet, Text, Options, ParserOptions, FieldName, DepFields, FieldMap);
    // 16-bit offsets: nodes or literals over 64K would be truncated
    if DataSize - PWord(@FilterData[8])^ > High(Word) then
      DatabaseError('Filter expression is too long');
  except
    on e: Exception do
      begin
        e.Message := 'Can''t parse Filter for: ' + CLRF + e.Message;
        raise;
      end;
  end;
  FExpressionText := Text;
  FDataSet := DataSet;
  FStrToDateFmt := aStrToDateFmt;
  FMatchesMask := aMatchesMask;
  FFilteredFields := TStringList.Create;
  with FFilteredFields do
    begin
      Sorted := true;
      Duplicates := dupIgnore
    end; // with
end;

destructor TExpressionParser.Destroy;
begin
  FFilteredFields.Free;
  inherited;
end;

function TExpressionParser.FieldByName(const FieldName: string): TField;
var
  i: Integer;
begin
  if FFilteredFields.Find(FieldName, i) then
    Result := TField(FFilteredFields.Objects[i])
  else
    begin
      Result := FDataSet.FieldByName(FieldName);
      FFilteredFields.AddObject(FieldName, Result)
    end;
end;

{$WARNINGS OFF}

function TExpressionParser.VarResult: Boolean;
var
  iLiteralStart: Word;

  // List node operands: value offset, next node offset (0 for the last)
  function NextListElem(pfdStart, pfd: PAnsiChar): PAnsiChar;
  begin
    Result := nil;
    if PWord(@pfd[2])^ <> 0 then
      begin
        Result := pfdStart + CANEXPRSIZE + PWord(@pfd[2])^;
        if NODEClass(PInteger(Result)^) <> nodeLISTELEM then
          DatabaseError(SExprIncorrect);
        Inc(Result, CANHDRSIZE);
      end;
  end;

  function HasNull(const V: Variant): Boolean;
  var
    i: Integer;
  begin
    Result := VarIsNull(V);
    if VarIsArray(V) then
      for i := VarArrayLowBound(V, 1) to VarArrayHighBound(V, 1) do
        if VarIsNull(V[i]) then
          begin
            Result := true;
            Exit;
          end;
  end;

  function ParseNode(pfdStart, pfd: PAnsiChar): Variant;
  var
    i, Count, AD: Integer;
    Year, Mon, Day, Hour, Min, Sec, MSec: Word;
    iClass: NODEClass;
    iOperator: TCANOperator;
    pArg1, pArg2: PAnsiChar;
    Arg1, Arg2, Args: Variant;
    DT: TDateTime;
    FieldName: string;
    DataType: TFieldType;
    DataOfs: Integer;
    ts: TTimeStamp;
    Cur: Currency;
    PartLength: Word;
    IgnoreCase: Word;
    S1, S2: Variant;
    S: string;
{$IFDEF D2009+}
    us: UnicodeString;
{$ENDIF}
    null1, null2: Boolean;
    p, p1: Integer;
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
                case DataType of
                  ftBCD:
                    if IsNull then
                      Result := Null
                    else
                      Result := FieldByName(FieldName).Value
                  else
                    Result := FieldByName(FieldName).Value
                end
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
                ftSmallInt, ftWord: Result := PWord(pArg1)^;
                ftInteger, ftAutoInc: Result := PInteger(pArg1)^;
                ftFloat, ftCurrency: Result := PDouble(pArg1)^;
                ftString, ftFixedChar: Result := string(pArg1);
{$IFDEF D2009+}
                ftWideString:
                  begin
                    SetLength(us, PWord(pArg1)^ div 2);
                    Move(pArg1[2], us[1], PWord(pArg1)^);
                    Result := us
                  end;
{$ENDIF}
                ftDate:
                  begin
                    ts.Date := PInteger(pArg1)^;
                    ts.Time := 0;
                    Result := HookTimeStampToDateTime(ts);
                  end;
                ftTime:
                  begin
                    ts.Date := 0;
                    ts.Time := PInteger(pArg1)^; ;
                    Result := HookTimeStampToDateTime(ts);
                  end;
                ftDateTime:
                  begin
                    ts := MSecsToTimeStamp(PDouble(pArg1)^);
                    Result := HookTimeStampToDateTime(ts);
                  end;
                ftBoolean: Result := PWordBool(pArg1)^;
                ftBCD:
                  begin
                    BCDToCurr(PBCD(pArg1)^, Cur);
                    Result := Cur;
                  end;
                ftLargeInt: Result := PInt64(pArg1)^;
                ftFMTBcd: VarFMTBcdCreate(Result, PBCD(pArg1)^);
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
            coISBLANK, coNOTBLANK:
              begin
                Arg1 := ParseNode(pfdStart, pArg1);
                Result := VarIsEmpty(Arg1) or VarIsNull(Arg1);
                if iOperator = coNOTBLANK then
                  Result := not Result;
              end;
            coNOT: Result := not WordBool(ParseNode(pfdStart, pArg1));
            coMINUS: Result := -ParseNode(pfdStart, pArg1);
            coUPPER: Result := AnsiUpperCase(VarToStr(ParseNode(pfdStart, pArg1)));
            coLOWER: Result := AnsiLowerCase(VarToStr(ParseNode(pfdStart, pArg1)));
          end;
        end;
      nodeBINARY:
        begin
          pArg1 := pfdStart;
          Inc(pArg1, CANEXPRSIZE + PWord(@pfd[0])^);
          pArg2 := pfdStart;
          Inc(pArg2, CANEXPRSIZE + PWord(@pfd[2])^);
          case iOperator of
            coAssign: Result := ParseNode(pfdStart, pArg1);
            coEQ: Result := ParseNode(pfdStart, pArg1) = ParseNode(pfdStart, pArg2);
            coNE: Result := ParseNode(pfdStart, pArg1) <> ParseNode(pfdStart, pArg2);
            coGT: Result := ParseNode(pfdStart, pArg1) > ParseNode(pfdStart, pArg2);
            coGE: Result := ParseNode(pfdStart, pArg1) >= ParseNode(pfdStart, pArg2);
            coLT: Result := ParseNode(pfdStart, pArg1) < ParseNode(pfdStart, pArg2);
            coLE: Result := ParseNode(pfdStart, pArg1) <= ParseNode(pfdStart, pArg2);
            coOR: Result := WordBool(ParseNode(pfdStart, pArg1)) or WordBool(ParseNode(pfdStart, pArg2));
            coAND: Result := WordBool(ParseNode(pfdStart, pArg1)) and WordBool(ParseNode(pfdStart, pArg2));
            coADD: Result := ParseNode(pfdStart, pArg1) + ParseNode(pfdStart, pArg2);
            coSUB: Result := ParseNode(pfdStart, pArg1) - ParseNode(pfdStart, pArg2);
            coMUL: Result := ParseNode(pfdStart, pArg1) * ParseNode(pfdStart, pArg2);
            coDIV: Result := ParseNode(pfdStart, pArg1) / ParseNode(pfdStart, pArg2);
            coMOD, coREM: Result := ParseNode(pfdStart, pArg1) mod ParseNode(pfdStart, pArg2);
            coIN:
              begin
                Arg1 := ParseNode(pfdStart, pArg1);
                Arg2 := ParseNode(pfdStart, pArg2);
                if VarIsArray(Arg2) then
                  begin
                    Result := False;
                    AD := VarArrayHighBound(Arg2, 1);
                    for i := 0 to AD do
                      begin
                        if VarIsEmpty(Arg2[i]) then
                          break;
                        Result := (Arg1 = Arg2[i]);
                        if Result then
                          break;
                      end;
                  end
                else
                  Result := (Arg1 = Arg2);
              end;
            coLike:
              if Assigned(FMatchesMask) then
                Result := FMatchesMask(VarToStr(ParseNode(pfdStart, pArg1)), VarToStr(ParseNode(pfdStart, pArg2)))
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
          null1 := VarIsNull(S1);
          null2 := VarIsNull(S2);
          if (null1 <> null2) then
            begin
              Result := iOperator = coNE;
              Exit;
            end
          else if null1 then
            begin
              Result := iOperator <> coNE;
              Exit;
            end;
          if IgnoreCase <> 0 then
            begin
              S1 := AnsiUpperCase(S1);
              S2 := AnsiUpperCase(S2);
            end;
          if (PartLength > 0) and (iOperator <> coLike) then
            begin
              S1 := Copy(S1, 1, PartLength);
              S2 := Copy(S2, 1, PartLength);
            end;
          case iOperator of
            coEQ: Result := S1 = S2;
            coNE: Result := S1 <> S2;
            coLike:
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
              S := AnsiUpperCase(pArg1);
              if S = 'GETDATE' then
                begin
                  Result := Now;
                  Exit;
                end;
              // TExprParser accepts TIME and aggregates too, not supported here
              if Pos(';' + S + ';',
                ';DAY;DATE;HOUR;MONTH;MINUTE;UPPER;LOWER;YEAR;' +
                'SUBSTRING;SECOND;TRIM;TRIMLEFT;TRIMRIGHT;') = 0 then
                DatabaseErrorFmt(SExprExpected, [S]);

              pArg2 := pfdStart;
              Inc(pArg2, CANEXPRSIZE + PWord(@pfd[2])^);
              Args := ParseNode(pfdStart, pArg2);
              if VarIsArray(Args) then
                Arg1 := Args[0]
              else
                Arg1 := Args;
              // as in SQL, a function of NULL is NULL
              if HasNull(Args) then
                Result := Null
              else if S = 'UPPER' then
                Result := AnsiUpperCase(VarToStr(Arg1))
              else if S = 'LOWER' then
                Result := AnsiLowerCase(VarToStr(Arg1))
              else if S = 'TRIM' then
                Result := FastTrim(VarToStr(Arg1))
              else if S = 'TRIMLEFT' then
                Result := TrimLeft(VarToStr(Arg1))
              else if S = 'TRIMRIGHT' then
                Result := TrimRight(VarToStr(Arg1))
              else if S = 'SUBSTRING' then
                begin
                  // SUBSTRING(Str, From[, Count]) or SUBSTRING(Str, 'From,Count')
                  if VarIsNumeric(Args[1]) then
                    begin
                      p := Args[1];
                      if VarIsEmpty(Args[2]) then
                        p1 := MaxInt
                      else
                        p1 := Args[2];
                    end
                  else
                    begin
                      S := VarToStr(Args[1]);
                      p := PosCh(',', S);
                      if p = 0 then
                        DatabaseErrorFmt(SExprExpected, [S]);
                      p1 := StrToInt(FastCopy(S, p + 1, 1000));
                      p := StrToInt(FastCopy(S, 1, p - 1));
                    end;
                  // Copy is safe for From < 1, FastCopy is not
                  Result := Copy(VarToStr(Arg1), p, p1);
                end
              else if S = 'DATE' then
                begin
                  if VarIsArray(Args) then
                    if Assigned(FStrToDateFmt) then
                      Result := FStrToDateFmt(VarToStr(Args[1]), VarToStr(Args[0]))
                    else
                      DatabaseError(SExprIncorrect)
                  else
                    Result := Integer(Trunc(VarToDateTime(Arg1)));
                end
              else
                begin
                  DT := VarToDateTime(Arg1);
                  DecodeDate(DT, Year, Mon, Day);
                  DecodeTime(DT, Hour, Min, Sec, MSec);
                  if S = 'YEAR' then
                    Result := Year
                  else if S = 'MONTH' then
                    Result := Mon
                  else if S = 'DAY' then
                    Result := Day
                  else if S = 'HOUR' then
                    Result := Hour
                  else if S = 'MINUTE' then
                    Result := Min
                  else
                    Result := Sec;
                end;
            end
          else
            DatabaseError(SExprIncorrect);
        end;
      nodeLISTELEM:
        case iOperator of
          coLISTELEM2:
            begin
              Count := 0;
              pArg2 := pfd;
              while pArg2 <> nil do
                begin
                  Inc(Count);
                  pArg2 := NextListElem(pfdStart, pArg2);
                end;
              // trailing Unassigned element marks the end of the list
              Result := VarArrayCreate([0, Count], varVariant);
              i := 0;
              pArg2 := pfd;
              while pArg2 <> nil do
                begin
                  Result[i] := ParseNode(pfdStart, pfdStart + CANEXPRSIZE + PWord(@pArg2[0])^);
                  Inc(i);
                  pArg2 := NextListElem(pfdStart, pArg2);
                end;

              // a single value is returned as a string scalar, NULL as is
              if Count = 1 then
                if VarIsNull(Result[0]) then
                  Result := Null
                else
                  Result := VarAsType(Result[0],
                    {$IFDEF D2009+}varUString{$ELSE}varString{$ENDIF});
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
  V: Variant;
begin
  V := VarResult;
  Result := WordBool(V)
end;

procedure TExpressionParser.ResetFields;
begin
  FFilteredFields.Clear
end;

end.
