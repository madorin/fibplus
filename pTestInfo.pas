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

{$I FIBPlus.inc}
unit pTestInfo;

interface
uses {$IFNDEF D6+}Windows,{$ELSE}FIBPlatforms,{$ENDIF}SysUtils,Classes,pFIBInterfaces,pFIBLists,StrUtil
;

  type

       TTestVarValues= class;
       TTestInfo=class;


       TTestInfo=class(TObject,ISQLStatMaker)
       private
        FTestVars:TObjStringList;
        FLogFileName  :string;
        FSortVariable :string;
        FAscSort      :boolean;
        FPrintList    :TList;
        FPrintListActual :boolean;
        FLastObjName :string;
        FPosLastObjX  :Integer;
        FActiveStatistics:boolean;
        procedure SetActiveStatistics(const Value:boolean);
        function  GetActiveStatistics:boolean;
        function  FindVariable(const ObjName,VarName:string;var InitRes:boolean):TPosition;
        function  GetVariable(const ObjName,VarName:string;var InitRes:boolean):TTestVarValues;
        function  GetVariableByInd(Index:TPosition):TTestVarValues;
        function  GetVariableByObjInd(Index:integer;const VarName:string):TTestVarValues;
       protected
        function  QueryInterface(const IID: TGUID; out Obj): HResult; virtual; stdcall;
        function _AddRef: Integer; stdcall;
        function _Release: Integer; stdcall;
       public
        constructor Create;
        destructor  Destroy; override;
        function    FixStartTime(const ObjName,VarName:string):Integer;
        function    FixEndTime(const ObjName,VarName:string):Integer;
        function    GetVarInt(const ObjName,VarName:string):Integer;
        function    GetVarStr(const ObjName,VarName:string):string;
        function    IncCounter(const ObjName,VarName:string):Integer;
        procedure   SetNull(const ObjName,VarName:string);
        procedure   SetStringValue(const ObjName,VarName,Value:string);
        procedure   SetIntValue(const ObjName,VarName:string;Value:integer);
        function    AddIntValue(const ObjName,VarName:string;Value:integer):integer;

        procedure   AddToStrings(const ObjName,VarName,Value:string);
        procedure   ClearStrings(const ObjName,VarName:string);
        function    GetVarStrings(const ObjName,VarName:string):TStrings;

        function    ObjCount:integer;
        function    ObjName(Index:integer) :String;
        procedure   Clear;
        procedure   SortStatisticsForPrint(const VarName:String;Ascending:boolean);
        procedure   LogVarValues(const ObjName:String;const FileName:String);
        procedure   SaveStatisticsToFile(const FileName:String);
        procedure   SetLogFileName(const LogName:string);
        function    GetLogFileName:string;
        procedure   SetLogParamsInc(const VarName:string;IncToLog:boolean);
        property    LogFileName:string read FLogFileName write FLogFileName;
        property    Variable[Index:TPosition]:TTestVarValues read GetVariableByInd;
        property    ActiveStatistics:boolean read GetActiveStatistics write SetActiveStatistics;
                
       end;

       TTestVarValues=class (TCallObject)
       private
        FValue:integer;
        FBufValue:integer;
        FStringVal:string;
        FLogStrValue:boolean;
        FDoLog :boolean;
        FStrings:TStrings;
       public
        constructor Create; override;
        destructor  Destroy; override;
       end;



       TTestProc=procedure;
       TTestProcObj=procedure of object;
       TTestFuncStr=function :string;

// Time Test routine functions
procedure TestExecProc(Proc:TTestProc;Count:integer);
procedure TestExecProcObj(Proc:TTestProcObj;Count:integer);
function  TestExecFuncStr(Func:TTestFuncStr;Count:integer):string;



implementation



procedure TestExecProc(Proc:TTestProc;Count:integer);
var i:integer;
begin
 for i:=1 to Count do Proc
end;

procedure TestExecProcObj(Proc:TTestProcObj;Count:integer);
var i:integer;
begin
 for i:=1 to Count do Proc
end;

function  TestExecFuncStr(Func:TTestFuncStr;Count:integer):string;
var i:integer;
begin
 for i:=1 to Count do Result:=Func
end;


{TTestVarValues}

constructor TTestVarValues.Create;
begin
 inherited Create;
 FValue    :=0 ;
 FBufValue :=0 ;
 FStringVal:='';
 FLogStrValue:=false;
 FDoLog      :=true;
 FStrings    :=TStringList.Create;
end;


destructor  TTestVarValues.Destroy; //override;
begin
 FStrings.Free;   
 inherited Destroy;
end;

{TTestInfo}
constructor TTestInfo.Create;
begin
 inherited Create;
 FPrintListActual:=false;
 FTestVars:=TObjStringList.Create(Self,true);
 FLogFileName:='';
 FPrintList  :=TList.Create;
 FLastObjName:='';
end;

destructor  TTestInfo.Destroy; //override;
begin
 FTestVars.Free;
 FPrintList.Free;
 inherited Destroy;
end;


function  TTestInfo.GetVariableByObjInd(Index:integer;const VarName:string):TTestVarValues;
var Index2:integer;
    InitRes:boolean;
begin
  with TObjStringList(FTestVars.Objects[Index]) do
  begin
    Index2:= FindObject(VarName,TTestVarValues,InitRes) ;
    Result:= TTestVarValues(Objects[Index2])
  end;
end;

function TTestInfo.FindVariable(const ObjName,VarName:string; var InitRes:boolean):TPosition;
begin
 with FTestVars do
  if Find(ObjName,Result.x) then
  with TObjStringList(Objects[Result.x]) do
  begin
    Result.y:= FindObject(VarName,TTestVarValues,InitRes) ;
    if InitRes then
    begin
     FPrintListActual:=false;
     Variable[Result].FValue:=0;
    end;
  end
  else
  begin
    InitRes:=true;
    Result.x:= AddObject(ObjName,TObjStringList.Create(nil,false));
    Result.y:=TObjStringList(Objects[Result.x]).AddObject(VarName,TTestVarValues.Create);
    Variable[Result].FValue:=0;
    FPrintListActual:=false;
  end
end;

function TTestInfo._AddRef: Integer;
begin
 Result:=-1
end;

function TTestInfo._Release: Integer;
begin
 Result:=-1
end;

function TTestInfo.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
 Result := E_NOINTERFACE
end;

function  TTestInfo.GetVariableByInd(Index:TPosition):TTestVarValues;
begin
 with FTestVars do
  Result := TTestVarValues(TObjStringList(Objects[Index.x]).Objects[Index.y])
end;

function  TTestInfo.GetVariable(const ObjName,VarName:string;var InitRes:boolean):TTestVarValues;
var
 vi:TPosition;
begin
 if ObjName=FLastObjName then
 begin
   Result:=GetVariableByObjInd(FPosLastObjX,VarName);
   InitRes:=False;
 end
 else
 begin
  vi:=FindVariable(ObjName,VarName,InitRes);
  Result:=Variable[vi];
  FLastObjName:=ObjName;
  FPosLastObjX:=vi.X;
 end;
end;

function TTestInfo.IncCounter(const ObjName,VarName:string):Integer;
var
 b:boolean;
begin
 with GetVariable(ObjName,VarName,b) do
 begin
  if b then FValue:=1 else Inc(FValue);
  Result:=FValue;
  FLogStrValue:=false;
 end
end;

procedure   TTestInfo.SetLogParamsInc(const VarName:string;IncToLog:boolean);
var b:boolean;
    i:integer;
begin
 for i:=0 to Pred(FTestVars.Count) do
 with GetVariable(FTestVars[i],VarName,b) do
 begin
  FDoLog:=IncToLog;
 end
end;


procedure TTestInfo.SetNull(const ObjName,VarName:string);
var
    b:boolean;
    tv:TTestVarValues;    
begin
 tv:= GetVariable(ObjName,VarName,b);
 with tv do
 begin
  FValue   :=0;
  FBufValue:=0;
  FStringVal:='';
 end
end;

function TTestInfo.AddIntValue(const ObjName,VarName:string;Value:integer):integer;
var
 b:boolean;
begin
 with GetVariable(ObjName,VarName,b) do
 begin
  if b then FValue:=Value else Inc(FValue,Value);
  Result:=FValue;
  FLogStrValue:=False;
 end
end;

procedure TTestInfo.SetIntValue(const ObjName,VarName:string;Value:integer);
var b:boolean;
begin
 with GetVariable(ObjName,VarName,b) do
 begin
  FValue:=Value;
 end
end;

procedure TTestInfo.SetStringValue(const ObjName,VarName,Value:string);
var
    b:boolean;
    tv:TTestVarValues;
begin
 tv:= GetVariable(ObjName,VarName,b);
 with  tv  do
 begin
  FLogStrValue:=true;
  FStringVal:=Value;
 end
end;

function TTestInfo.FixStartTime(const ObjName,VarName:string):Integer;
var
    b:boolean;
    tv:TTestVarValues;
begin

 tv:= GetVariable(ObjName,VarName,b);
 with tv  do
 begin
  FBufValue := FIBGetTickCount;
  Result := FBufValue;
  FLogStrValue := false;
 end
end;

{$WARNINGS OFF}
function TTestInfo.FixEndTime(const ObjName,VarName:string):Integer;
var
    b:boolean;
    tv:TTestVarValues;
begin

 tv:= GetVariable(ObjName,VarName,b);
 with  tv do
 begin
  FValue := FIBGetTickCount - FBufValue;
  Result:=FValue;
  FLogStrValue:=false;
 end;
end;
{$WARNINGS ON}

function TTestInfo.GetVarStr(const ObjName,VarName:string):string;
var
    b:boolean;
begin

 with GetVariable(ObjName,VarName,b) do
 begin
  Result:=FStringVal;
 end;
end;

function TTestInfo.GetVarInt(const ObjName,VarName:string):Integer;
var
   b:boolean;
begin
 with GetVariable(ObjName,VarName,b) do
 begin
  Result:=FValue;
 end;
end;

procedure   TTestInfo.SaveStatisticsToFile(const FileName:string);
var
  i:integer;
begin
 if FPrintListActual then
  for i:=0 to Pred(FPrintList.Count) do
   LogVarValues(FTestVars[Integer(FPrintList[i])],FileName)
 else
  for i:=0 to Pred(FTestVars.Count) do
   LogVarValues(FTestVars[i],FileName)
end;

procedure   TTestInfo.LogVarValues(const ObjName:string;const FileName:string);
var
  F: TextFile;
  S: string;
  x,y:integer;
begin
  if FileName='' then Exit;
  if not FTestVars.Find(ObjName,x) then Exit;
  AssignFile(F, FileName);
  if FileExists(FileName) then
   System.Append(F)
  else
   ReWrite(F);
  with TObjStringList(FTestVars.Objects[x]) do
  try
    S:=ObjName+' : ';
    Writeln(F, S);
    for y:=0 to Pred(Count) do
    with Variable[Position(x,y)] do
    if FDoLog then
    begin
      S:=Item[y]+'=';
      if FLogStrValue then
       S:=S+'"'+FStringVal+'"'
      else
       S:=S+IntToStr(FValue);
      Writeln(F, S);
    end
  finally
    CloseFile(F);
  end;
end;


function TTestInfo.GetLogFileName: string;
begin
 Result:=FLogFileName;
end;

procedure TTestInfo.SetLogFileName(const LogName: string);
begin
 FLogFileName:=LogName;
end;

procedure TTestInfo.Clear;
begin
 FTestVars.FullClear;
 FPrintListActual:=false;
end;

function TTestInfo.ObjCount: integer;
begin
 Result:=FTestVars.Count
end;

function TTestInfo.ObjName(Index: integer): String;
begin
 Result:=FTestVars[Index]
end;

procedure TTestInfo.AddToStrings(const ObjName, VarName, Value: string);
var b:boolean;
begin
 with GetVariable(ObjName,VarName,b) do
 begin
  FStrings.Add(Value);
 end
end;

procedure TTestInfo.ClearStrings(const ObjName, VarName: string);
var b:boolean;
begin
 with GetVariable(ObjName,VarName,b) do
 begin
  FStrings.Clear;
 end
end;

function TTestInfo.GetVarStrings(const ObjName, VarName: string): TStrings;
var b:boolean;
begin
 with GetVariable(ObjName,VarName,b) do
 begin
  Result:=FStrings;
 end
end;



threadvar SortTestInfo:TTestInfo;

function CompareItems(Item1, Item2: Pointer):integer;
var v,v1:TTestVarValues;
begin
 if SortTestInfo=nil then Result:=0
 else
 with SortTestInfo do
 begin
  v :=GetVariableByObjInd(Integer(Item1),FSortVariable);
  v1:=GetVariableByObjInd(Integer(Item2),FSortVariable);
  Result:=0;

  if v.FLogStrValue then
  begin
   if v.FStringVal>v1.FStringVal then Result:=1
   else
   if v.FStringVal<v1.FStringVal then Result:=-1
  end
  else
   if v.FValue>v1.FValue then  Result:=1
   else
    if v.FValue<v1.FValue then Result:=-1;

  if FAscSort then   Exit;
  Result:=-1*Result;
 end
end;

procedure TTestInfo.SortStatisticsForPrint(const VarName: string; Ascending: boolean);
var i:integer;
begin
 FSortVariable :=VarName;
 FAscSort      :=Ascending;
 FPrintList.Clear;
 FPrintList.Capacity:=FTestVars.Count;
 for i:=0 to Pred(FTestVars.Count) do FPrintList.Add(Pointer(i));
 SortTestInfo:=Self;
 try
  FPrintList.Sort(CompareItems);
 finally
  SortTestInfo:=nil
 end;
 FPrintListActual:=true;
end;


function TTestInfo.GetActiveStatistics: boolean;
begin
 Result:=FActiveStatistics
end;

procedure TTestInfo.SetActiveStatistics(const Value: boolean);
begin
 FActiveStatistics:=Value
end;


end.


