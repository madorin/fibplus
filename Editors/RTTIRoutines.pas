unit RTTIRoutines;

{$I ..\FIBPlus.inc}
interface
uses
  TypInfo,Classes,SysUtils,
  {$IFDEF D6+}
     DesignEditors,DesignIntf, Variants
  {$else}
     DsgnIntf
  {$ENDIF}
;

type
   TProperty= record
    Obj:TObject;
    PropName:string
   end;


 function  GetProperty(Instance: TObject; const PropName: string):TProperty;

 function  GetPropStringValue(Instance: TObject; const PropName: string):string;
 procedure SetStringProperty(Instance: TObject; const PropName,Value: string);
 procedure SetValueProperty(Instance: TObject; const PropName: string;Value:Variant);
 procedure AssignStringsToProp(Instance: TObject; const PropName,Strings:string);
 function  GetSubPropValue(Instance: TObject; const PropName: string):Variant;
 function  GetSubPropObject(Instance: TObject; const PropName: string):TObject;

//tkSet Prop
 function GetMaxValueSet(Instance: TObject; const PropName:string):integer;
 function GetValueInSet(Instance: TObject; const PropName,ValueName:string):boolean;

type
   TSupportsFunc=function (const Instance: TObject; const IID: TGUID; out Intf): Boolean;

var
   ObjSupports:TSupportsFunc;

implementation

 function GetProperty(Instance: TObject; const PropName: string):TProperty;
 var
    j:integer;
    tmpObject:TObject;
    tmpStr:string;
    tmpStr1:string;

 begin
    j:=Pos('.',PropName);
    if j=0 then
    begin
      Result.Obj:=Instance;
      Result.PropName:=PropName
    end
    else
    begin
     tmpStr1:=PropName;
     tmpObject:=Instance;
     while j>0 do
     begin
      tmpStr:=Copy(tmpStr1,1,j-1);
      tmpObject:=GetObjectProp(tmpObject,tmpStr);
      if not Assigned(tmpObject) then
      begin
       Result.Obj:=nil;
       Exit;
      end;
      tmpStr1:=Copy(tmpStr1,j+1,MaxInt);
      j:=Pos('.',tmpStr1);
     end;
      Result.Obj:=tmpObject;
      Result.PropName:=tmpStr1
    end
 end;

 function GetPropStringValue(Instance: TObject; const PropName: string):string;
 var
    Prop:TProperty;
 begin
   Prop:=GetProperty(Instance,PropName);
   Result:=GetStrProp(Prop.Obj,Prop.PropName)
 end;

 function  GetSubPropValue(Instance: TObject; const PropName: string):Variant;
 var
    Prop:TProperty;
 begin
   Prop:=GetProperty(Instance,PropName);
   Result:=GetPropValue(Prop.Obj,Prop.PropName,False)
 end;

 function  GetSubPropObject(Instance: TObject; const PropName: string):TObject;
 var
    Prop:TProperty;
 begin
   Prop:=GetProperty(Instance,PropName);
   Result:=GetObjectProp(Prop.Obj,Prop.PropName)
 end;

 procedure SetStringProperty(Instance: TObject; const PropName,Value: string);
 var
    Prop:TProperty;
 begin
   Prop:=GetProperty(Instance,PropName);
   SetStrProp(Prop.Obj,Prop.PropName,Value)
 end;

 procedure SetValueProperty(Instance: TObject; const PropName: string;Value:Variant);
 var
    Prop:TProperty;
 begin
   Prop:=GetProperty(Instance,PropName);
   SetPropValue(Prop.Obj,Prop.PropName,Value)
 end;

procedure AssignStringsToProp(Instance: TObject; const PropName,Strings:string);
var
   ts:TStringList;
   Prop:TProperty;
   Obj:TObject;
begin
 ts:=TStringList.Create;
 Prop:=GetProperty(Instance,PropName);
 try
  ts.Text:=Strings;
  Obj:=GetObjectProp(Prop.Obj,Prop.PropName);
  if Obj is TPersistent then
   TPersistent(Obj).Assign(ts);
//  SetObjectProp(Prop.Obj,Prop.PropName,ts);
 finally
  ts.Free;
 end;

{ ts:=TStringList.Create;
 Prop:=GetProperty(Instance,PropName);
 try
  ts.Text:=Strings;
  SetObjectProp(Prop.Obj,Prop.PropName,ts);
 finally
  ts.Free;
 end;}
end;


function GetMaxValueSet(Instance: TObject; const PropName:string):integer;
var
  EnumType: PTypeInfo;
  PropType:PTypeInfo;
  PropInfo: PPropInfo;
begin
    PropInfo := GetPropInfo(Instance, PropName);
    PropType := PPropInfo(PropInfo)^.PropType^;
    EnumType := GetTypeData(PropType)^.CompType^;
    Result   := GetTypeData(EnumType).MaxValue;
end;


 function GetValueInSet(Instance: TObject; const PropName,ValueName:string):boolean;
 var
    Prop:TProperty;
    P:integer;
    Str:String;
 begin
    Prop:=GetProperty(Instance,PropName);
    Str:=GetPropValue(Prop.Obj,PropName,True);
    P:=Pos(ValueName,Str);
    if P<=1 then
      Result:=False
    else
     Result:= (Str[P-1] in ['[',',']) and (Str[P+Length(ValueName)] in [']',','])
 end;

{$IFNDEF D6+}
function Supports(const Instance: TObject; const IID: TGUID; out Intf): Boolean;
var
  LUnknown: IUnknown;
begin
  Result := (Instance <> nil) and
            ((Instance.GetInterface(IUnknown, LUnknown) and SysUtils.Supports(LUnknown, IID, Intf)) or
             Instance.GetInterface(IID, Intf));
end;
{$ENDIF}
initialization

ObjSupports:=Supports
end.
