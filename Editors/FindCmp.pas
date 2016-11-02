unit FindCmp;

interface
{$I ..\FIBPlus.inc}
{$IFDEF D6+}
 {$WARN UNIT_DEPRECATED OFF}
{$ENDIF}
uses
  SysUtils, Windows,    EditIntf, ExptIntf,
  ToolsAPI,  Classes,
   {$IFDEF D_XE2}
  Vcl.Graphics, Vcl.Controls, Vcl.Forms,  Vcl.Dialogs, Vcl.ComCtrls, Vcl.ExtCtrls,
  Vcl.StdCtrls,Vcl.Menus,
  {$ELSE}
  Graphics, Controls, Forms,  Dialogs, ComCtrls, ExtCtrls, StdCtrls,Menus,
  {$ENDIF}


  TypInfo,StFilSys;

type

TFindComponentExpert=class(TIExpert)
private
  OI:TForm;                            
  FCurrentUnit:string;

  function  GetOI:TForm;
  function  CmpNameFromFullPath(const Path:string):string;

public
  constructor Create; virtual;
  destructor  Destroy; override;

  function  GetIDString: string; override;
  function  GetName: string; override;
  function  GetState: TExpertState; override;
  function  GetAuthor: string; override;
  function  GetComment: string; override;
  function  GetPage: string; override;
  function  GetStyle: TExpertStyle; override;
  function  GetMenuText: string; override;
  function  GetGlyph: HICON; override;

  procedure Execute; override;
  procedure DoSearchComponents(InCurrentFormOnly:boolean);

  function  CurrentWordInEdit: string;
  function  FindComponentInForm(MI:IOTAModuleInfo;var UnitName, ComponentName:string;
   var aFormName:string; ComponentNames:TStrings; var FormIntf:IOTAFormEditor
  ):boolean;

  function  DoComponentFocus(aProject:IOTAProject;const Path:string):boolean; 
  function  DoComponentFocus1(FormIntf:IOTAFormEditor;const ComponentName:string):boolean;

  procedure ShowOI;
end;

function GetCurrentProjectGroup: IOTAProjectGroup;
function GetActiveProject: IOTAProject;
function GetActiveProjectShortName:string;
function GetActiveProjectName:string;
function UnitForFormA(const aFormName:string):string;
function UnitInActiveProject(const UnitName:string):boolean;
function GetCurUnitName:string;

function GetIOTAModule(const FileName:string):IOTAModule;


procedure Register;

var
  FindComponentExpert:TFindComponentExpert;

implementation

uses
  uFrmSearchResult ;

//------------------------------------------------------------------------------
procedure Register;
begin
 {$IFNDEF FIBPLUS_TRIAL}
  RegisterLibraryExpert(TFindComponentExpert.Create);
 {$ENDIF}  
end;
//------------------------------------------------------------------------------
constructor TFindComponentExpert.Create;
begin
  inherited Create;
  FindComponentExpert:=Self;
  OI:=GetOI;
end;
//------------------------------------------------------------------------------
destructor TFindComponentExpert.Destroy;
begin
  inherited Destroy;
end;
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
function TFindComponentExpert.GetPage: string;
begin
  Result:=''; // Only for experts by type Form & Project
end;
//------------------------------------------------------------------------------
function TFindComponentExpert.GetMenuText: string;
begin
   // Only for experts by type Form Standart
end;
//------------------------------------------------------------------------------
function TFindComponentExpert.GetComment: string;
begin
  // Only for experts by type Form & Project
end;
//------------------------------------------------------------------------------
function TFindComponentExpert.GetStyle: TExpertStyle;
begin
  Result:=esAddIn;
end;
//------------------------------------------------------------------------------
function TFindComponentExpert.GetAuthor: string;
begin
  Result:='Plotnikov Yuri & Serge Buzadzhy';// Only for experts by type Form & Project
end;
//------------------------------------------------------------------------------
function TFindComponentExpert.GetGlyph: HICON;
begin
  Result:=0; // Only for experts by type Form & Project
end;
//------------------------------------------------------------------------------
function TFindComponentExpert.GetName: string;
begin
  Result:='Find Component(s)';
end;
//------------------------------------------------------------------------------
function TFindComponentExpert.GetState: TExpertState;
begin
  Result:=[esEnabled];
end;
//------------------------------------------------------------------------------
function TFindComponentExpert.GetIDString: string;
begin
  Result:='{B1A9B8BF-38F6-42DD-8849-04BBC794D7BF}'
end;

function    TFindComponentExpert.CurrentWordInEdit: string;
const
  LexemSymbols=['A'..'Z','a'..'z', '_', '0'..'9'];
var
   iWSep1, iWSep2:      Integer;

  CurPos :     TOTACharPos;
  CursorPos :TOTAEditPos;

  pstrBuf: PAnsiChar;
  s:AnsiString;
  isStringsPropFile:boolean;
  FSystem:string;
  curModule:IOTAModule;
  curEditor:IOTAEditor;
  EditView:IOTAEditView;
  EditReader:IOTAEditReader;
  II:IUnknown;
begin
  Result := '';
  FCurrentUnit:=GetCurUnitName;

  If FCurrentUnit='' then
   Exit; // No module

  if Copy(UpperCase(FCurrentUnit),Length(FCurrentUnit)-3,MaxInt)='DFM' then
  begin // this is a form
    Exit;
  end;


  curModule:=(BorlandIDEServices as IOTAModuleServices).CurrentModule;

  if not Assigned(curModule) then
   Exit;

  FSystem:=curModule.FileSystem;
  isStringsPropFile:=FSystem=sTStringsFileSystem;
  if isStringsPropFile then
  begin
    FCurrentUnit:=UpperCase(FCurrentUnit);
    {$IFDEF D9+}
       FCurrentUnit:=Copy(FCurrentUnit,5,MaxInt);
    {$ENDIF}
    iWSep2:=1;
    for iWSep1:=Length(FCurrentUnit)-3 downto 1 do
    begin
      if FCurrentUnit[iWSep1]=DotSep then
      begin
        iWSep2:=iWSep1;
        Break
      end;
    end;
    SetLength(FCurrentUnit,iWSep2-1);

    iWSep2:=0;
    for iWSep1:=Length(FCurrentUnit) downto 1 do
    begin
      if FCurrentUnit[iWSep1]=DotSep then
      begin
        iWSep2:=iWSep1;
        Break
      end;
    end;
    FCurrentUnit:=Copy(FCurrentUnit,iWSep2+1,MaxInt);
    Result:=FCurrentUnit;
    Exit;
  end;

  {$IFDEF D6+}
   curEditor:=curModule.CurrentEditor;
  {$ELSE}
   for iWSep1:=curModule.GetModuleFileCount-1 downto 0 do
   begin
    curEditor:=curModule.GetModuleFileEditor(iWSep1);
    if Supports(curEditor,IOTASourceEditor,II) then
     Break;
   end;
  {$ENDIF}
  if not Supports(curEditor,IOTASourceEditor,II) then
   Exit;
  if (curEditor as IOTASourceEditor).GetEditViewCount=0 then
    Exit;
  EditView:=(curEditor as IOTASourceEditor).GetEditView(0);

  EditReader:=(curEditor as IOTASourceEditor).CreateReader;
  GetMem(pstrBuf,2000);
  try
   CursorPos:=EditView.CursorPos;
   EditView.ConvertPos(True,CursorPos,CurPos);
   CursorPos.Col:=CurPos.CharIndex;
   CurPos.CharIndex:=0;
   EditReader.GetText(EditView.CharPosToPos(CurPos),pstrBuf,2000);
   iWSep1:=CursorPos.Col;
   if not(pstrBuf[iWSep1] in LexemSymbols) then
    if (iWSep1>0) and (pstrBuf[iWSep1-1] in LexemSymbols) then
     Dec(iWSep1)
    else
     if (pstrBuf[iWSep1+1] in LexemSymbols) then
      Inc(iWSep1)
     else
       Exit;
   iWSep2:=iWSep1;

   while (iWSep1>0) and (pstrBuf[iWSep1-1] in LexemSymbols) do
     Dec(iWSep1);

   while (iWSep2<2000) and (pstrBuf[iWSep2+1] in LexemSymbols) do
    Inc(iWSep2);


   SetLength(s,iWSep2-iWSep1+1);
   if iWSep2>=iWSep1 then
     Move(pstrBuf[iWSep1],s[1],iWSep2-iWSep1+1);

   Result:=s
  finally
    FreeMem(pstrBuf,2000);
  end;
end;

function GetIOTAModule(const FileName:string):IOTAModule;
var
  Services: IOTAModuleServices;
  I: Integer;
begin
  Result := nil;
  Services := BorlandIDEServices as IOTAModuleServices;
  for I := 0 to Services.ModuleCount - 1 do
  begin
    if Services.Modules[I].FileName=FileName then
    begin
        Result:=Services.Modules[I];
        Break;
    end;
  end;
end;



function GetFormEditor(Module: IOTAModule): IOTAFormEditor;
var
 i,j:integer;
 s:string;
 FormModule:IOTAModule;
begin
  Result := nil;
  if not Assigned(Module) then
   Exit;
  for i := 0 to Module.GetModuleFileCount - 1 do
  begin
   if Supports(Module.GetModuleFileEditor(i), IOTAFormEditor, Result) then
    Exit;
  end;
  s:=Module.GetFileSystem;
  if s='' then
  else
  begin
    s:=Module.FileName;
    {$IFDEF D9+}
     s:=Copy(s,5,MaxInt);
    {$ENDIF}
    j:=Length(s);
    for i := 1 to Length(s)  do
    begin
      if s[i]=DotSep then
      begin
        j:=i-1;
        Break
      end;
    end;
    SetLength(s,j);
    FormModule:=(BorlandIDEServices as IOTAModuleServices).FindFormModule(s);
    if Assigned(FormModule) then
    begin
      for i := 0 to FormModule.GetModuleFileCount - 1 do
      begin
       if Supports(FormModule.GetModuleFileEditor(i), IOTAFormEditor, Result) then
        Exit;
      end;
      FormModule:=nil
    end;
  end;

end;
//------------------------------------------------------------------------------

function  TFindComponentExpert.FindComponentInForm(MI:IOTAModuleInfo;var UnitName, ComponentName:string;
   var aFormName:string; ComponentNames:TStrings;var FormIntf:IOTAFormEditor
):boolean;
var
  ModuleIntf: IOTAModule;
  Forced:boolean;
  RootComponent:IOTAComponent;
  CmpIntf:IOTAComponent;
  i:integer;
  CurName:string;
begin
  Result:= False;
  Forced:=False;
  FormIntf:=nil;
  if MI=nil then
   ModuleIntf:=GetIOTAModule(UnitName)
  else
  begin
   UnitName:=MI.FormName;
   if  Length(UnitName)=0 then
    Exit;
   UnitName:=MI.FileName;
   ModuleIntf:=GetIOTAModule(UnitName);
   if (ModuleIntf=nil) and (UnitName<>'') then
   begin
     ModuleIntf:=MI.OpenModule;
     Forced:=True;
   end;
  end;
  FormIntf  :=GetFormEditor(ModuleIntf);
  try
   if Assigned(FormIntf) then
   begin
     RootComponent  :=FormIntf.GetRootComponent;
     RootComponent.GetPropValueByName('Name',aFormName);
     for i:=0 to Pred(RootComponent.GetComponentCount) do
     begin
       RootComponent.GetComponent(i).GetPropValueByName('Name',CurName);
//       if Pos(ComponentName,UpperCase(CurName))=1 then
       if ComponentName=UpperCase(CurName) then
       begin
        ComponentNames.Add(aFormName+'.'+CurName+
         ':'+RootComponent.GetComponent(i).GetComponentType+'#UNIT#'+UnitName);
        Result := True;
        Exit;
       end;
     end;
   end;
  finally
   if (ModuleIntf<>nil) and Forced then
    ModuleIntf.CloseModule(True);
   ModuleIntf:=nil;
   if not Result then
    FormIntf  :=nil;
   CmpIntf   :=nil
  end;
end;

procedure TFindComponentExpert.DoSearchComponents(InCurrentFormOnly:boolean);//(Sender: TIMenuItemIntf);
var
  i,j,c:integer;
  strBuf: string;
  ModuleIntf: IOTAModule;
  FormName:string;
  UnitName:string;
  ComponentNames:TStrings;
  Pr:IOTAProject;
  FormIntf:IOTAFormEditor;
  MI:IOTAModuleInfo;
begin
  strBuf:=CurrentWordInEdit;
  if strBuf='' then
   Exit;
  strBuf:=UpperCase(strBuf);
  ComponentNames:=TStringList.Create;
  try
    UnitName:=GetCurUnitName;
    ModuleIntf:=GetIOTAModule(UnitName);
    if not InCurrentFormOnly  then
    begin
      {$IFDEF D6+}
       c:=Pred(ModuleIntf.OwnerModuleCount);
      {$ELSE}
       c:=Pred(ModuleIntf.OwnerCount);
      {$ENDIF}

      for i:=0 to c do
      begin
       {$IFDEF D6+}
        if Supports(ModuleIntf.OwnerModules[i],IOTAProject,Pr) then
       {$ELSE}
        if Supports(ModuleIntf.Owners[i],IOTAProject,Pr) then
       {$ENDIF}
         for j:=0 to Pr.GetModuleCount-1 do
         begin
          MI:=Pr.GetModule(j);
          if Assigned(MI) then
           FindComponentInForm(MI,UnitName,strBuf,
            FormName,ComponentNames,FormIntf
           )
         end;

      end;
    end
    else
     FindComponentInForm(nil,UnitName,strBuf,
           FormName,ComponentNames,FormIntf
     );

     if ComponentNames.Count>0 then
     case ComponentNames.Count of
        1:
         begin
            if Assigned(FormIntf) then
            begin
             strBuf:=CmpNameFromFullPath(ComponentNames[0]);
             DoComponentFocus1(FormIntf,strBuf);
            end;
         end;
     else
        ShowSearchResult(ComponentNames);
     end;
  finally
   ComponentNames.Free;
   FormIntf:=nil
  end;
end;
//------------------------------------------------------------------------------
procedure TFindComponentExpert.Execute;// this is MUST to be
begin
end;


function GetIOTAModuleInfo(aProject:IOTAProject;const FileName:string):IOTAModuleInfo;
var
  I: Integer;
  tmp:IOTAModuleInfo;
begin                 
  Result := nil;
  try
    for I := 0 to aProject.GetModuleCount - 1 do
    begin
      tmp:=aProject.GetModule(I);
      if tmp.FileName=FileName then
      begin
          Result:=tmp;
          Break;
      end;
    end;
  finally
   tmp:=nil
  end;
end;


function GetCurrentProjectGroup: IOTAProjectGroup;
 var  Services: IOTAModuleServices;
      Module  : IOTAModule;
      I: Integer;
begin
 Result := nil;
 Services := BorlandIDEServices as IOTAModuleServices;
 try
   for I := 0 to Services.ModuleCount - 1 do
   begin
    Module := Services.Modules[I];
    if Module.QueryInterface(IOTAProjectGroup, Result) = S_OK then
     break;
   end;
  finally
   Services :=nil
  end;
end;

function GetActiveProject: IOTAProject;
var
 pg:IOTAProjectGroup;
begin
 pg:=GetCurrentProjectGroup;
 try
   if Assigned(pg) then
      Result:=pg.ActiveProject
   else
      Result:=nil;
  finally
   pg:=nil
  end;
end;

function GetActiveProjectShortName:string;
var
 ap:IOTAProject;
begin
    ap:=GetActiveProject;
    if Assigned(ap) then
      Result:=ExtractFileName(ap.FileName)
    else
      Result:='Unknown project';
end;

function GetActiveProjectName:string;
var
 ap:IOTAProject;
begin
 ap:=GetActiveProject;
 try
    if Assigned(ap) then
      Result:=ap.FileName
    else
      Result:='Unknown project';
 finally
  ap:=nil
 end;
end;

function UnitForFormA(const aFormName:string):string;
var
   ap:IOTAProject;
   mi:IOTAModuleInfo;
   I:Integer;
begin
 Result:='';
 ap:=GetActiveProject;
 try
     if Assigned(ap) then
     begin
      for I := 0 to ap.GetModuleCount - 1 do
      begin
        mi:=aP.GetModule(I);
        if MI.FormName=aFormName then
        begin
          Result:=MI.FileName;
          Exit
        end;
      end;
    end;
  finally
   ap:=nil
  end  
end;

function UnitInActiveProject(const UnitName:string):boolean;
var
   ap:IOTAProject;
   mi:IOTAModuleInfo;
   I:Integer;
begin
  Result:=False;
  ap:=GetActiveProject;
  try
     if Assigned(ap) then
     begin
      for I := 0 to ap.GetModuleCount - 1 do
      begin
        mi:=aP.GetModule(I);
        if MI.FileName=UnitName then
        begin
          Result:=True;
          Exit
        end;
      end;
    end;
  finally
   ap:=nil;
   mi:=nil
  end;
end;

function GetCurUnitName:string;
var
   M:IOTAModule;
begin
  Result:='';
  M:=(BorlandIDEServices as IOTAModuleServices).CurrentModule;
  try
     if Assigned(M) then
     begin
       Result:=M.FileName
     end;
  finally
   M:=nil
  end;
end;

function  TFindComponentExpert.DoComponentFocus(aProject:IOTAProject;const Path:string):boolean;
var
   p,p1:integer;
   UnitName:string;
   ModuleIntf: IOTAModule;
   FormIntf:IOTAFormEditor;
   CmpIntf:IOTAComponent;
   ComponentName:string;
   MInfo:IOTAModuleInfo;
   CurProjGroup:IOTAProjectGroup;
begin
   Result := False;
   if not Assigned(aProject) then
   try
     CurProjGroup:=GetCurrentProjectGroup;
     if Assigned(CurProjGroup) then
     begin
       for p:=0 to Pred(CurProjGroup.ProjectCount) do
       begin
         Result:=DoComponentFocus(CurProjGroup.Projects[p],Path);
         if Result then
          Exit;
       end;
     end;

   finally
     CurProjGroup:=nil;
   end;
   if not Assigned(aProject) then
    Exit;     

   p:=Pos('#UNIT#', Path);
   UnitName     :=Copy(Path,p+6,MaxInt);
   p:=Pos(':',Path);
   p1:=Pos('.',Path);
   ComponentName:=Copy(Path,p1+1,p-p1-1);
   ModuleIntf:=GetIOTAModule(UnitName);
   if not Assigned(ModuleIntf) then
   begin
     MInfo:=GetIOTAModuleInfo(aProject,UnitName);
     if assigned(MInfo) then
      ModuleIntf:=MInfo.OpenModule
   end;
   if Assigned(ModuleIntf) then
   try
     FormIntf  :=GetFormEditor(ModuleIntf);
     CmpIntf:=FormIntf.FindComponent(ComponentName);
     if Assigned(CmpIntf) then
     begin
       CmpIntf.Select(False);
       ShowOI;
       FormIntf.Show;
       Result := True;
     end;
   finally
    MInfo     :=nil;
    ModuleIntf:=nil;
    FormIntf  :=nil;
    CmpIntf   :=nil;
   end;
end;

procedure TFindComponentExpert.ShowOI;
begin
   if OI <>nil then
   begin
     OI.Enabled:=True;
     if OI.Enabled then
     begin
      OI.Show;
     end;
   end;
end;

function TFindComponentExpert.GetOI: TForm;
var
     j : integer;
begin
    Result := nil;
    with Screen do
    for J := 0 to Pred(FormCount) do
     if Forms[j].ClassName = 'TPropertyInspector' then
     begin
      Result := Forms[j];
      Break
     end;
end;

function   TFindComponentExpert.CmpNameFromFullPath(const Path:string):string;
var
 p,p1:Integer;
begin
   p:=Pos(':',Path);
   p1:=Pos('.',Path);
   Result:=Copy(Path,p1+1,p-p1-1);
end;

function TFindComponentExpert.DoComponentFocus1(FormIntf: IOTAFormEditor;
  const ComponentName: string): boolean;
var
    CmpIntf:IOTAComponent;
begin
  CmpIntf:=FormIntf.FindComponent(ComponentName);
  if Assigned(CmpIntf) then
  try
     CmpIntf.Select(False);
     ShowOI;
     FormIntf.Show;
     Result := True;
  finally
   CmpIntf:=nil
  end
  else
    Result := False;
end;


initialization
finalization
 FindComponentExpert:=nil
end.


