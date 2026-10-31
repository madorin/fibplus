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
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit ToCodeEditor;

interface

{$I ..\FIB.inc}

uses
  Classes, ToolsAPI, IStreams;

type
  TFIBStringsModuleCreator = class(TInterfacedObject, IOTACreator,
    IOTAModuleCreator)
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

  TFIBOTAFile = class(TInterfacedObject, IOTAFile)
  private
    FSource: string;
    FAge: TDateTime;
  public
    constructor Create(const ASource: string; AAge: TDateTime);
    { IOTAFile }
    function GetSource: string;
    function GetAge: TDateTime;
  end;

function FindPropInCode(Component: TComponent; const PropName: string): Boolean;
function CreatePropInCode(Component: TComponent; const PropName: string; PropValue: TStrings; aModified: Boolean): Boolean;
procedure SaveCloseModule(const Ident: string);
procedure SaveModule(const Ident: string); overload;
procedure SaveModule(Component: TComponent; const PropName: string); overload;
function CloseModule(const Ident: string): Boolean; overload;
function CloseModule(Component: TComponent; const PropName: string): Boolean; overload;

procedure SetSQLPropertiesHighlights;

implementation

uses
  SysUtils, TypInfo, DesignIntf, StFilSys,
{$IFDEF C23}
  Vcl.Forms, Vcl.Controls,
{$ELSE}
  Forms, Controls,
{$ENDIF}
  ToCodeEditorIntfs;

type
  TFIBToCodeEditor = class(TComponent, IFIBStringsToCodeEditor)
  private
    function ICreatePropInCode(Component: TComponent; const PropName: string; PropValue: TStrings; aModified: Boolean): Boolean;
  end;

  { TFIBOTAFile }

constructor TFIBOTAFile.Create(const ASource: string; AAge: TDateTime);
begin
  inherited Create;
  FSource := ASource;
  FAge := AAge;
end;

function TFIBOTAFile.GetAge: TDateTime;
begin
  Result := FAge;
end;

function TFIBOTAFile.GetSource: string;
begin
  Result := FSource;
end;

{ TFIBStringsModuleCreator }

constructor TFIBStringsModuleCreator.Create(const FileName: string; Stream: TStringStream; Age: TDateTime);
begin
  inherited Create;
  FFileName := FileName;
  FStream := Stream;
  FAge := Age;
end;

destructor TFIBStringsModuleCreator.Destroy;
begin
  FStream.Free;
  inherited;
end;

procedure TFIBStringsModuleCreator.FormCreated(const FormEditor: IOTAFormEditor);
begin
  { Nothing to do }
end;

function TFIBStringsModuleCreator.GetAncestorName: string;
begin
  Result := '';
end;

function TFIBStringsModuleCreator.GetCreatorType: string;
begin
  Result := sText;
end;

function TFIBStringsModuleCreator.GetExisting: Boolean;
begin
  Result := False;
end;

function TFIBStringsModuleCreator.GetFileSystem: string;
begin
  Result := sTStringsFileSystem;
end;

function TFIBStringsModuleCreator.GetFormName: string;
begin
  Result := '';
end;

function TFIBStringsModuleCreator.GetImplFileName: string;
begin
  Result := FFileName;
end;

function TFIBStringsModuleCreator.GetIntfFileName: string;
begin
  Result := '';
end;

function TFIBStringsModuleCreator.GetMainForm: Boolean;
begin
  Result := False;
end;

function TFIBStringsModuleCreator.GetOwner: IOTAModule;
begin
  Result := nil;
end;

function TFIBStringsModuleCreator.GetShowForm: Boolean;
begin
  Result := False;
end;

function TFIBStringsModuleCreator.GetShowSource: Boolean;
begin
  Result := True;
end;

function TFIBStringsModuleCreator.GetUnnamed: Boolean;
begin
  Result := False;
end;

function TFIBStringsModuleCreator.NewFormFile(const FormIdent, AncestorIdent: string): IOTAFile;
begin
  Result := nil;
end;

function TFIBStringsModuleCreator.NewImplSource(const ModuleIdent, FormIdent, AncestorIdent: string): IOTAFile;
begin
  Result := TFIBOTAFile.Create(FStream.DataString, FAge);
end;

function TFIBStringsModuleCreator.NewIntfSource(const ModuleIdent, FormIdent, AncestorIdent: string): IOTAFile;
begin
  Result := nil;
end;

// The IDE strings file system resolves "ext.Form.Component.Property", ext being the designer extension
function PropModuleIdent(Component: TComponent; const PropName: string): string;
var
  Designer: IDesigner;
  Extension: string;
begin
  Extension := 'dfm';
  if Supports(FindRootDesigner(Component), IDesigner, Designer) and
    (Designer.GetDesignerExtension <> '') then
    Extension := Designer.GetDesignerExtension;
  if Component.Owner <> nil then
    Result := Extension + DotSep + Component.Owner.Name
  else
    Result := Extension + DotSep;
  Result := Result + DotSep + Component.Name + DotSep + PropName;
end;

function FindPropInCode(Component: TComponent; const PropName: string): Boolean;
var
  Ident: string;
  Module: IOTAModule;
  ModuleServices: IOTAModuleServices;
begin
  Result := False;
  if (Component.Owner = nil) then
    Exit;
  ModuleServices := BorlandIDEServices as IOTAModuleServices;
  Ident := PropModuleIdent(Component, PropName);
  Module := ModuleServices.FindModule(Ident);
  if (Module <> nil) and (Module.GetModuleFileCount > 0) then
  begin
    Module.GetModuleFileEditor(0).Show;
    Result := True;
  end;
end;

procedure SaveModule(const Ident: string);
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
      Module := nil
    end;
end;

procedure SaveModule(Component: TComponent; const PropName: string);
begin
  SaveModule(PropModuleIdent(Component, PropName));
end;

procedure SaveCloseModule(const Ident: string);
var
  Module: IOTAModule;
begin
  Module := (BorlandIDEServices as IOTAModuleServices).FindModule(Ident);
  if (Module <> nil) then
    try
      Module.Save(False, True);
      Module.Close;
    finally
      Module := nil
    end;
end;

function CloseModule(const Ident: string): Boolean;
var
  Module: IOTAModule;
begin
  Module := (BorlandIDEServices as IOTAModuleServices).FindModule(Ident);
  if (Module <> nil) then
    try
      Result := Module.Close;
    finally
      Module := nil
    end
  else
    Result := False;
end;

function CloseModule(Component: TComponent; const PropName: string): Boolean;
begin
  Result := CloseModule(PropModuleIdent(Component, PropName));
end;

function CreatePropInCode(Component: TComponent; const PropName: string; PropValue: TStrings; aModified: Boolean): Boolean;
var
  Ident: string;
  Module: IOTAModule;
  Editor: IOTAEditor;
  ModuleServices: IOTAModuleServices;
  Stream: TStringStream;
  Age: TDateTime;
  pName: string;
begin
  Result := False;
  if (Component.Owner = nil) then
    Exit;
  ModuleServices := BorlandIDEServices as IOTAModuleServices;

  pName := PropName;
  case pName[1] of

    'D':
      if pName = 'DeleteQuery' then
        pName := 'DeleteSQL';
    'I':
      if pName = 'InsertQuery' then
        pName := 'InsertSQL';
    'R':
      if pName = 'RefreshQuery' then
        pName := 'RefreshSQL';
    'S':
      if pName = 'SelectQuery' then
        pName := 'SelectSQL';
    'U':
      if pName = 'UpdateQuery' then
        pName := 'UpdateSQL';

  end;

  Ident := PropModuleIdent(Component, pName);
  SaveCloseModule(Ident);
  // this used to be done in LibMain's TLibrary.Create but now its done here
  // the unregister is done over in ComponentDesigner's finalization
  StFilSys.Register;

  if not Assigned(PropValue) then
    TObject(PropValue) := GetObjectProp(Component, pName, TStrings);
  if not Assigned(PropValue) then
    Exit;

  Stream := TStringStream.Create('');
  PropValue.SaveToStream(Stream);
  Stream.Position := 0;
  Age := Now;
  Module := ModuleServices.CreateModule(TFIBStringsModuleCreator.Create(Ident, Stream, Age));
  if Module <> nil then
  begin
    with StringsFileSystem.GetTStringsProperty(Ident, Component, pName) do
      DiskAge := DateTimeToFileDate(Age);
    Editor := Module.GetModuleFileEditor(0);
    if aModified then
      Editor.MarkModified
    else
      Module.Save(False, True);
    Result := True;
  end;
end;

const
  SQLProps = ';selectsql;insertsql;deletesql;refreshsql;updatesql;';

var
  SQLPropsAdded: Boolean = False;
  ToCodeEditorInstance: TFIBToCodeEditor;

procedure SetSQLPropertiesHighlights;
begin
  if Assigned(BorlandIDEServices) then
    with (BorlandIDEServices as IOTAEditorServices).GetEditOptionsForFile
      ('*.SQL') do
    begin
      if Pos(SQLProps, Extensions) = 0 then
      begin
        Extensions := Extensions + SQLProps;
        SQLPropsAdded := True;
      end;
    end;
end;

procedure ResetSQLPropertiesHighlights;
var
  P: Integer;
begin
  if SQLPropsAdded and Assigned(BorlandIDEServices) then
    with (BorlandIDEServices as IOTAEditorServices).GetEditOptionsForFile
      ('*.SQL') do
    begin
      P := Pos(SQLProps, Extensions);
      if P > 0 then
        Extensions := Copy(Extensions, 1, P - 1) + Copy(Extensions, P + Length(SQLProps), MaxInt);
    end;
end;

{ TFIBToCodeEditor }

function TFIBToCodeEditor.ICreatePropInCode(Component: TComponent; const PropName: string; PropValue: TStrings; aModified: Boolean): Boolean;
begin
  Result := CreatePropInCode(Component, PropName, PropValue, aModified)
end;

initialization

ToCodeEditorInstance := TFIBToCodeEditor.Create(nil);
StringsToCodeEditor := ToCodeEditorInstance;
SetSQLPropertiesHighlights;

finalization

StringsToCodeEditor := nil;
FreeAndNil(ToCodeEditorInstance);
try
  ResetSQLPropertiesHighlights;
except
end;

end.
