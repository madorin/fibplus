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

unit FIBTestInfo;

{$I FIB.inc}

interface

uses
  FIBPlatforms, SysUtils, Classes, FIBInterfaces, FIBLists, StrUtil;

type

  TFIBStatisticsValue = class;
  TFIBStatistics = class;

  TFIBStatistics = class(TObject, IFIBSQLStatisticsMaker)
  private
    FTestVars: TFIBObjectStringList;
    FLogFileName: string;
    FSortVariable: string;
    FAscSort: Boolean;
    FPrintList: TList;
    FPrintListActual: Boolean;
    FLastObjName: string;
    FPosLastObjX: Integer;
    FActiveStatistics: Boolean;
    procedure SetActiveStatistics(const Value: Boolean);
    function GetActiveStatistics: Boolean;
    function FindVariable(const ObjName, VarName: string; var InitRes: Boolean): TFIBPosition;
    function GetVariable(const ObjName, VarName: string; var InitRes: Boolean): TFIBStatisticsValue;
    function GetVariableByInd(Index: TFIBPosition): TFIBStatisticsValue;
    function GetVariableByObjInd(Index: Integer; const VarName: string): TFIBStatisticsValue;
  protected
    function QueryInterface(const IID: TGUID; out Obj): HResult; virtual; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    constructor Create;
    destructor Destroy; override;
    function FixStartTime(const ObjName, VarName: string): Cardinal;
    function FixEndTime(const ObjName, VarName: string): Integer;
    function GetVarInt(const ObjName, VarName: string): Integer;
    function GetVarStr(const ObjName, VarName: string): string;
    function IncCounter(const ObjName, VarName: string): Integer;
    procedure SetStringValue(const ObjName, VarName, Value: string);
    procedure SetIntValue(const ObjName, VarName: string; Value: Integer);
    function AddIntValue(const ObjName, VarName: string; Value: Integer): Integer;

    function GetVarStrings(const ObjName, VarName: string): TStrings;

    function ObjCount: Integer;
    function ObjName(Index: Integer): String;
    procedure Clear;
    procedure SortStatisticsForPrint(const VarName: String; Ascending: Boolean);
    procedure LogVarValues(const ObjName: String; const FileName: String);
    procedure SaveStatisticsToFile(const FileName: String);
    procedure SetLogFileName(const LogName: string);
    function GetLogFileName: string;
    procedure SetLogParamsInc(const VarName: string; IncToLog: Boolean);
    property LogFileName: string read FLogFileName write FLogFileName;
    property Variable[Index: TFIBPosition]: TFIBStatisticsValue read GetVariableByInd;
    property ActiveStatistics: Boolean read GetActiveStatistics write SetActiveStatistics;

  end;

  TFIBStatisticsValue = class(TFIBCreatableObject)
  private
    FValue: Integer;
    FBufValue: Cardinal;
    FStringVal: string;
    FLogStrValue: Boolean;
    FDoLog: Boolean;
    FStrings: TStrings;
  public
    constructor Create; override;
    destructor Destroy; override;
  end;

type
  // Deprecated names of the types renamed in 8.0.0
  TTestInfo = TFIBStatistics deprecated 'Use TFIBStatistics';
  TTestVarValues = TFIBStatisticsValue deprecated 'Use TFIBStatisticsValue';

implementation

{ TFIBStatisticsValue }

constructor TFIBStatisticsValue.Create;
begin
  inherited Create;
  FDoLog := true;
  FStrings := TStringList.Create;
end;

destructor TFIBStatisticsValue.Destroy; // override;
begin
  FStrings.Free;
  inherited Destroy;
end;

{ TFIBStatistics }
constructor TFIBStatistics.Create;
begin
  inherited Create;
  FTestVars := TFIBObjectStringList.Create(Self, true);
  FPrintList := TList.Create;
  FPosLastObjX := -1;
end;

destructor TFIBStatistics.Destroy; // override;
begin
  FTestVars.Free;
  FPrintList.Free;
  inherited Destroy;
end;

function TFIBStatistics.GetVariableByObjInd(Index: Integer; const VarName: string): TFIBStatisticsValue;
var
  Index2: Integer;
  InitRes: Boolean;
begin
  with TFIBObjectStringList(FTestVars.Objects[Index]) do
  begin
    Index2 := FindObject(VarName, TFIBStatisticsValue, InitRes);
    Result := TFIBStatisticsValue(Objects[Index2])
  end;
end;

function TFIBStatistics.FindVariable(const ObjName, VarName: string; var InitRes: Boolean): TFIBPosition;
begin
  with FTestVars do
    if Find(ObjName, Result.x) then
      with TFIBObjectStringList(Objects[Result.x]) do
      begin
        Result.y := FindObject(VarName, TFIBStatisticsValue, InitRes);
        if InitRes then
        begin
          FPrintListActual := false;
          Variable[Result].FValue := 0;
        end;
      end
    else
    begin
      InitRes := true;
      Result.x := AddObject(ObjName, TFIBObjectStringList.Create(nil, false));
      Result.y := TFIBObjectStringList(Objects[Result.x]).AddObject(VarName, TFIBStatisticsValue.Create);
      Variable[Result].FValue := 0;
      FPrintListActual := false;
    end
end;

function TFIBStatistics._AddRef: Integer;
begin
  Result := -1
end;

function TFIBStatistics._Release: Integer;
begin
  Result := -1
end;

function TFIBStatistics.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  Result := E_NOINTERFACE
end;

function TFIBStatistics.GetVariableByInd(Index: TFIBPosition): TFIBStatisticsValue;
begin
  with FTestVars do
    Result := TFIBStatisticsValue(TFIBObjectStringList(Objects[Index.x]).Objects[Index.y])
end;

function TFIBStatistics.GetVariable(const ObjName, VarName: string; var InitRes: Boolean): TFIBStatisticsValue;
var
  FoundPos: TFIBPosition;
begin
  if (FPosLastObjX >= 0) and (ObjName = FLastObjName) then
  begin
    Result := GetVariableByObjInd(FPosLastObjX, VarName);
    InitRes := false;
  end
  else
  begin
    FoundPos := FindVariable(ObjName, VarName, InitRes);
    Result := Variable[FoundPos];
    FLastObjName := ObjName;
    FPosLastObjX := FoundPos.x;
  end;
end;

function TFIBStatistics.IncCounter(const ObjName, VarName: string): Integer;
var
  b: Boolean;
begin
  with GetVariable(ObjName, VarName, b) do
  begin
    if b then
      FValue := 1
    else
      Inc(FValue);
    Result := FValue;
    FLogStrValue := false;
  end
end;

procedure TFIBStatistics.SetLogParamsInc(const VarName: string; IncToLog: Boolean);
var
  b: Boolean;
  i: Integer;
begin
  for i := 0 to Pred(FTestVars.Count) do
    with GetVariable(FTestVars[i], VarName, b) do
    begin
      FDoLog := IncToLog;
    end
end;


function TFIBStatistics.AddIntValue(const ObjName, VarName: string; Value: Integer): Integer;
var
  b: Boolean;
begin
  with GetVariable(ObjName, VarName, b) do
  begin
    if b then
      FValue := Value
    else
      Inc(FValue, Value);
    Result := FValue;
    FLogStrValue := false;
  end
end;

procedure TFIBStatistics.SetIntValue(const ObjName, VarName: string; Value: Integer);
var
  b: Boolean;
begin
  with GetVariable(ObjName, VarName, b) do
  begin
    FValue := Value;
  end
end;

procedure TFIBStatistics.SetStringValue(const ObjName, VarName, Value: string);
var
  b: Boolean;
  tv: TFIBStatisticsValue;
begin
  tv := GetVariable(ObjName, VarName, b);
  with tv do
  begin
    FLogStrValue := true;
    FStringVal := Value;
  end
end;

function TFIBStatistics.FixStartTime(const ObjName, VarName: string): Cardinal;
var
  b: Boolean;
  tv: TFIBStatisticsValue;
begin

  tv := GetVariable(ObjName, VarName, b);
  with tv do
  begin
    FBufValue := FIBGetTickCount;
    Result := FBufValue;
    FLogStrValue := false;
  end
end;

function TFIBStatistics.FixEndTime(const ObjName, VarName: string): Integer;
var
  b: Boolean;
  tv: TFIBStatisticsValue;
begin
  tv := GetVariable(ObjName, VarName, b);
  with tv do
  begin
    // Right also when the tick count wrapped around ($Q- in FIB.inc)
    FValue := Integer(FIBGetTickCount - FBufValue);
    Result := FValue;
    FLogStrValue := false;
  end;
end;

function TFIBStatistics.GetVarStr(const ObjName, VarName: string): string;
var
  b: Boolean;
begin

  with GetVariable(ObjName, VarName, b) do
  begin
    Result := FStringVal;
  end;
end;

function TFIBStatistics.GetVarInt(const ObjName, VarName: string): Integer;
var
  b: Boolean;
begin
  with GetVariable(ObjName, VarName, b) do
  begin
    Result := FValue;
  end;
end;

procedure TFIBStatistics.SaveStatisticsToFile(const FileName: string);
var
  i: Integer;
  VarIndex: Pointer;
begin
  if FPrintListActual then
    for VarIndex in FPrintList do
      LogVarValues(FTestVars[Integer(VarIndex)], FileName)
  else
    for i := 0 to Pred(FTestVars.Count) do
      LogVarValues(FTestVars[i], FileName)
end;

procedure TFIBStatistics.LogVarValues(const ObjName: string; const FileName: string);
var
  F: TextFile;
  S: string;
  x, y: Integer;
begin
  if FileName = '' then
    Exit;
  if not FTestVars.Find(ObjName, x) then
    Exit;
  AssignFile(F, FileName);
  if FileExists(FileName) then
    System.Append(F)
  else
    ReWrite(F);
  with TFIBObjectStringList(FTestVars.Objects[x]) do
    try
      S := ObjName + ' : ';
      Writeln(F, S);
      for y := 0 to Pred(Count) do
        with Variable[Position(x, y)] do
          if FDoLog then
          begin
            S := Item[y] + '=';
            if FLogStrValue then
              S := S + '"' + FStringVal + '"'
            else
              S := S + IntToStr(FValue);
            Writeln(F, S);
          end
    finally
      CloseFile(F);
    end;
end;

function TFIBStatistics.GetLogFileName: string;
begin
  Result := FLogFileName;
end;

procedure TFIBStatistics.SetLogFileName(const LogName: string);
begin
  FLogFileName := LogName;
end;

procedure TFIBStatistics.Clear;
begin
  FTestVars.FullClear;
  FLastObjName := '';
  FPosLastObjX := -1;
  FPrintListActual := false;
end;

function TFIBStatistics.ObjCount: Integer;
begin
  Result := FTestVars.Count
end;

function TFIBStatistics.ObjName(Index: Integer): String;
begin
  Result := FTestVars[Index]
end;

function TFIBStatistics.GetVarStrings(const ObjName, VarName: string): TStrings;
var
  b: Boolean;
begin
  with GetVariable(ObjName, VarName, b) do
  begin
    Result := FStrings;
  end
end;

threadvar SortTestInfo: TFIBStatistics;

function CompareItems(Item1, Item2: Pointer): Integer;
var
  v, v1: TFIBStatisticsValue;
begin
  if SortTestInfo = nil then
    Result := 0
  else
    with SortTestInfo do
    begin
      v := GetVariableByObjInd(Integer(Item1), FSortVariable);
      v1 := GetVariableByObjInd(Integer(Item2), FSortVariable);
      Result := 0;

      if v.FLogStrValue then
      begin
        if v.FStringVal > v1.FStringVal then
          Result := 1
        else if v.FStringVal < v1.FStringVal then
          Result := -1
      end
      else if v.FValue > v1.FValue then
        Result := 1
      else if v.FValue < v1.FValue then
        Result := -1;

      if FAscSort then
        Exit;
      Result := -1 * Result;
    end
end;

procedure TFIBStatistics.SortStatisticsForPrint(const VarName: string; Ascending: Boolean);
var
  i: Integer;
begin
  FSortVariable := VarName;
  FAscSort := Ascending;
  FPrintList.Clear;
  FPrintList.Capacity := FTestVars.Count;
  for i := 0 to Pred(FTestVars.Count) do
    FPrintList.Add(Pointer(i));
  SortTestInfo := Self;
  try
    FPrintList.Sort(CompareItems);
  finally
    SortTestInfo := nil
  end;
  FPrintListActual := true;
end;

function TFIBStatistics.GetActiveStatistics: Boolean;
begin
  Result := FActiveStatistics
end;

procedure TFIBStatistics.SetActiveStatistics(const Value: Boolean);
begin
  FActiveStatistics := Value
end;

end.
