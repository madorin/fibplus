{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ Interbase databases                                           }
{                                                               }
{    FIBPlus is based in part on the product                    }
{    Free IB Components, written by Gregory H. Deatz for        }
{    Hoagland, Longo, Moran, Dunst & Doukas Company.            }
{    mailto:gdeatz@hlmdd.com                                    }
{                                                               }
{    Copyright (c) 1998-2004 Serge Buzadzhy                     }
{    Contact: buzz@devrace.com                                  }
{                                                               }
{ ------------------------------------------------------------- }
{    FIBPlus home page      : http://www.fibplus.net/           }
{    FIBPlus support e-mail : fibplus@devrace.com               }
{ ------------------------------------------------------------- }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit ToCodeEditor;

interface
{$I ..\FIBPlus.inc}
uses
 Classes,ToolsAPI, IStreams;

type
  TStringsModuleCreator = class(TInterfacedObject, IOTACreator, IOTAModuleCreator)
  private
    FFileName: string;
    FStream: TStringStream;
    FAge: TDateTime;
  public
    constructor Create(const FileName: string; Stream: TStringStream; Age: TDateTime);
    destructor Destroy; override;
    { IOTACreator }
    function GetCreatorType: string;
    function GetExisting: Boolean;
    function GetFileSystem: string;
    function GetOwner: IOTAModule;
    function GetUnnamed: Boolean;
    { IOTAModuleCreator }
    function GetAncestorName: string;
    function GetImplFileName: string;
    function GetIntfFileName: string;
    function GetFormName: string;
    function GetMainForm: Boolean;
    function GetShowForm: Boolean;
    function GetShowSource: Boolean;
    function NewFormFile(const FormIdent, AncestorIdent: string): IOTAFile;
    function NewImplSource(const ModuleIdent, FormIdent, AncestorIdent: string): IOTAFile;
    function NewIntfSource(const ModuleIdent, FormIdent, AncestorIdent: string): IOTAFile;
    procedure FormCreated(const FormEditor: IOTAFormEditor);
  end;

  TOTAFile = class(TInterfacedObject, IOTAFile)
  private
    FSource: string;
    FAge: TDateTime;
  public
    constructor Create(const ASource: string; AAge: TDateTime);
    { IOTAFile }
    function GetSource: string;
    function GetAge: TDateTime;
  end;

  function FindPropInCode(Component:TComponent;const PropName:string):boolean;
  function CreatePropInCode(Component:TComponent;const PropName:string;PropValue:TStrings;
   aModified:boolean
  ):boolean;
  procedure SaveCloseModule(const Ident:string);
  procedure SaveModule(const Ident:string); overload;
  procedure SaveModule(Component:TComponent;const PropName:string); overload;
  function CloseModule(const Ident:string):boolean;overload;
  function CloseModule(Component:TComponent;const PropName:string):boolean; overload;

  procedure SetSQLPropertiesHighlights;

implementation

uses SysUtils, TypInfo,StFilSys,
{$IFDEF D_XE2}
Vcl.Forms,Vcl.Controls,
{$ELSE}
Forms,Controls,
{$ENDIF}
ToCodeEditorIntfs ;

{$IFDEF D9+}
const
 cDfmExt='dfm';
{$ENDIF}

type
  TToCodeEditor= class(TComponent,IStringsToCodeEditor)
  private
    function ICreatePropInCode(Component:TComponent;const PropName:string;PropValue:TStrings;
     aModified:boolean
    ):boolean;
  end;

{ TOTAFile }

constructor TOTAFile.Create(const ASource: string; AAge: TDateTime);
begin
  inherited Create;
  FSource := ASource;
  FAge := AAge;
end;

function TOTAFile.GetAge: TDateTime;
begin
  Result := FAge;
end;

function TOTAFile.GetSource: string;
begin
  Result := FSource;
end;

{ TStringsModuleCreator }

constructor TStringsModuleCreator.Create(const FileName: string; Stream: TStringStream;
  Age: TDateTime);
begin
  inherited Create;
  FFileName := FileName;
  FStream := Stream;
  FAge := Age;
end;

destructor TStringsModuleCreator.Destroy;
begin
  FStream.Free;
  inherited;
end;

procedure TStringsModuleCreator.FormCreated(const FormEditor: IOTAFormEditor);
begin
  { Nothing to do }
end;

function TStringsModuleCreator.GetAncestorName: string;
begin
  Result := '';
end;

function TStringsModuleCreator.GetCreatorType: string;
begin
  Result := sText;
end;

function TStringsModuleCreator.GetExisting: Boolean;
begin
  Result := False;
end;

function TStringsModuleCreator.GetFileSystem: string;
begin
  Result := sTStringsFileSystem;
end;

function TStringsModuleCreator.GetFormName: string;
begin
  Result := '';
end;

function TStringsModuleCreator.GetImplFileName: string;
begin
  Result := FFileName;
end;

function TStringsModuleCreator.GetIntfFileName: string;
begin
  Result := '';
end;

function TStringsModuleCreator.GetMainForm: Boolean;
begin
  Result := False;
end;

function TStringsModuleCreator.GetOwner: IOTAModule;
begin
  Result := nil;
end;

function TStringsModuleCreator.GetShowForm: Boolean;
begin
  Result := False;
end;

function TStringsModuleCreator.GetShowSource: Boolean;
begin
  Result := True;
end;

function TStringsModuleCreator.GetUnnamed: Boolean;
begin
  Result := False;
end;

function TStringsModuleCreator.NewFormFile(const FormIdent,
  AncestorIdent: string): IOTAFile;
begin
  Result := nil;
end;

function TStringsModuleCreator.NewImplSource(const ModuleIdent, FormIdent,
  AncestorIdent: string): IOTAFile;
begin
  Result := TOTAFile.Create(FStream.DataString, FAge);
end;

function TStringsModuleCreator.NewIntfSource(const ModuleIdent, FormIdent,
  AncestorIdent: string): IOTAFile;
begin
  Result := nil;
end;

function FindPropInCode(Component:TComponent;const PropName:string):boolean;
var
  Ident: string;
  Module: IOTAModule;
  ModuleServices: IOTAModuleServices;
begin
  Result:=False;
  if (Component.Owner=nil)  then
   Exit;
  ModuleServices := BorlandIDEServices as IOTAModuleServices;
  {$IFDEF D9+}
   Ident := cDfmExt+DotSep+Component.Owner.Name + DotSep +
      Component.Name + DotSep + PropName;
  {$ELSE}
   Ident := Component.Owner.Name + DotSep +
      Component.Name + DotSep + PropName;
  {$ENDIF}
  Module := ModuleServices.FindModule(Ident);
  if (Module <> nil) and (Module.GetModuleFileCount > 0) then
  begin
    Module.GetModuleFileEditor(0).Show;
    Result:=True;
  end;
end;

procedure SaveModule(const Ident:string);
var
  Module: IOTAModule;
begin
  if not Assigned(BorlandIDEServices) then
   Exit;

  Module := (BorlandIDEServices as IOTAModuleServices).FindModule(Ident);
  if (Module <> nil) then
  try
   Module.Save(False, True);
  finally
   Module:=nil
  end;
end;

procedure SaveModule(Component:TComponent;const PropName:string);
begin
  SaveModule(Component.Owner.Name + DotSep + Component.Name + DotSep + PropName);
end;

procedure SaveCloseModule(const Ident:string);
var
  Module: IOTAModule;
begin
  Module := (BorlandIDEServices as IOTAModuleServices).FindModule(Ident);
  if (Module <> nil) then
  try
   Module.Save(False, True);
   Module.Close;
  finally
   Module:=nil
  end;
end;

function CloseModule(const Ident:string):boolean;
var
  Module: IOTAModule;
begin
  Module := (BorlandIDEServices as IOTAModuleServices).FindModule(Ident);
  if (Module <> nil) then
  try
   Result:=Module.Close;
  finally
   Module:=nil
  end
  else
    Result := False;
end;

function CloseModule(Component:TComponent;const PropName:string):boolean;
begin
 Result:= CloseModule(Component.Owner.Name + DotSep + Component.Name + DotSep + PropName);
end;

function CreatePropInCode(Component:TComponent;const PropName:string;PropValue:TStrings;
 aModified:boolean
):boolean;
var
  Ident: string;
  Module: IOTAModule;
  Editor: IOTAEditor;
  ModuleServices: IOTAModuleServices;
  Stream: TStringStream;
  Age: TDateTime;
  pName:string;
begin
  Result:=False;
  if (Component.Owner=nil)  then
   Exit;
  ModuleServices := BorlandIDEServices as IOTAModuleServices;

  pName:=PropName;
  case pName[1] of

   'D':  if pName='DeleteQuery' then
           pName:='DeleteSQL';
   'I':  if pName='InsertQuery' then
           pName:='InsertSQL';
   'R':  if pName='RefreshQuery' then
           pName:='RefreshSQL';
   'S':  if pName='SelectQuery' then
           pName:='SelectSQL';
   'U':  if pName='UpdateQuery' then
           pName:='UpdateSQL';

  end;

  {$IFDEF D9+}
   Ident := cDfmExt+DotSep+Component.Owner.Name + DotSep +
      Component.Name + DotSep + pName;
  {$ELSE}
   Ident := Component.Owner.Name + DotSep +
      Component.Name + DotSep + pName;
  {$ENDIF}

//  Ident := Component.Owner.Name + DotSep + Component.Name + DotSep + PropName;
  SaveCloseModule(Ident);
  {$IFDEF D6+}
      // this used to be done in LibMain's TLibrary.Create but now its done here
      //  the unregister is done over in ComponentDesigner's finalization
    StFilSys.Register;
  {$ENDIF}
  Stream := TStringStream.Create('');

  if not Assigned(PropValue) then
   TObject(PropValue):=GetObjectProp(Component,pName,TStrings) ;
  if not Assigned(PropValue) then
   Exit;

  PropValue.SaveToStream(Stream);
  Stream.Position := 0;
  Age := Now;
  Module := ModuleServices.CreateModule(TStringsModuleCreator.Create(Ident, Stream, Age));
  if Module <> nil then
  begin
    with StringsFileSystem.GetTStringsProperty(Ident, Component, pName) do
      DiskAge := DateTimeToFileDate(Age);
    Editor := Module.GetModuleFileEditor(0);
    if aModified then
      Editor.MarkModified
    else
      Module.Save(False,True);
    Result:=True;
  end;
end;


procedure SetSQLPropertiesHighlights;
const
  SQLProps=';selectsql;insertsql;deletesql;refreshsql;updatesql;';
begin
 {$IFNDEF D7+}
 if Assigned(BorlandIDEServices) then
 with (BorlandIDEServices as IOTAEditorServices).EditOptions do
 begin
  if Pos(SQLProps,SyntaxHighlightTypes[shSQL])=0 then
   SyntaxHighlightTypes[shSQL]:=SyntaxHighlightTypes[shSQL]+
    SQLProps
 end;
 {$ELSE}
 if Assigned(BorlandIDEServices) then
 with (BorlandIDEServices as IOTAEditorServices).GetEditOptionsForFile('*.SQL') do
 begin
   if Pos(SQLProps,Extensions)=0 then
    Extensions:=Extensions+SQLProps
 end;

 {$ENDIF}
end;

{ TToCodeEditor }

function TToCodeEditor.ICreatePropInCode(Component: TComponent;
  const PropName: string; PropValue: TStrings;
  aModified: boolean): boolean;
begin
 Result:=CreatePropInCode(Component, PropName,PropValue,  aModified)
end;


initialization
  StringsToCodeEditor:=TToCodeEditor.Create(nil);
  SetSQLPropertiesHighlights;
finalization
  StringsToCodeEditor:=nil
end.
