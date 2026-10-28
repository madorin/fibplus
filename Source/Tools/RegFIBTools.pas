{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ InterBase databases                                           }
{                                                               }
{  Registration of the FIBPlus IDE tools.                       }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit RegFIBTools;

interface

procedure Register;

implementation

{$R FIBToolsImages.res}

uses
  System.SysUtils, System.Classes, System.Generics.Collections, Vcl.Graphics, Vcl.ImgList, Vcl.Controls,
  Vcl.Menus, Vcl.Forms, Vcl.Imaging.pngimage, ToolsAPI, FIB, FIBDatabase, FIBToolsConsts, FIBPreferences, FIBAbout;

type
  TFIBToolsMenuHandler = class(TComponent)
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    procedure PreferencesClick(Sender: TObject);
    procedure AboutClick(Sender: TObject);
  end;

  TFIBDebuggerNotifier = class(TNotifierObject, IOTADebuggerNotifier, IOTADebuggerNotifier90)
  protected
    procedure ProcessCreated(const Process: IOTAProcess);
    procedure ProcessDestroyed(const Process: IOTAProcess);
    procedure BreakpointAdded(const Breakpoint: IOTABreakpoint);
    procedure BreakpointDeleted(const Breakpoint: IOTABreakpoint);
    procedure BreakpointChanged(const Breakpoint: IOTABreakpoint);
    procedure CurrentProcessChanged(const Process: IOTAProcess);
    procedure ProcessStateChanged(const Process: IOTAProcess);
    function BeforeProgramLaunch(const Project: IOTAProject): Boolean;
    procedure ProcessMemoryChanged;
  end;

var
  ToolsImages: TObjectList<TGraphic>;
{$IF CompilerVersion >= 35}
  IconImages: TGraphicArray;
{$ELSE}
  IconBitmap: TBitmap;
{$ENDIF}
  MenuHandler: TFIBToolsMenuHandler;
  MenuRoot: TMenuItem;
  DebuggerNotifierIndex: Integer = -1;
  AboutBoxIndex: Integer = -1;

procedure TFIBToolsMenuHandler.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  // The IDE may destroy its menu before the package is unloaded
  if (Operation = opRemove) and (AComponent = MenuRoot) then
    MenuRoot := nil;
end;

procedure TFIBToolsMenuHandler.PreferencesClick(Sender: TObject);
begin
  ShowFIBPreferences;
end;

procedure TFIBToolsMenuHandler.AboutClick(Sender: TObject);
begin
  ShowFIBAbout;
end;

procedure TFIBDebuggerNotifier.ProcessCreated(const Process: IOTAProcess);
begin
end;

procedure TFIBDebuggerNotifier.ProcessDestroyed(const Process: IOTAProcess);
begin
end;

procedure TFIBDebuggerNotifier.BreakpointAdded(const Breakpoint: IOTABreakpoint);
begin
end;

procedure TFIBDebuggerNotifier.BreakpointDeleted(const Breakpoint: IOTABreakpoint);
begin
end;

procedure TFIBDebuggerNotifier.BreakpointChanged(const Breakpoint: IOTABreakpoint);
begin
end;

procedure TFIBDebuggerNotifier.CurrentProcessChanged(const Process: IOTAProcess);
begin
end;

procedure TFIBDebuggerNotifier.ProcessStateChanged(const Process: IOTAProcess);
begin
end;

function TFIBDebuggerNotifier.BeforeProgramLaunch(const Project: IOTAProject): Boolean;
begin
  if CloseDesignConnections then
    try
      CloseDesignTimeDatabases;
    except
      // The program starts even if a connection fails to close
      Application.HandleException(Self);
    end;
  Result := True;
end;

procedure TFIBDebuggerNotifier.ProcessMemoryChanged;
begin
end;

// Every image given to the IDE is owned by ToolsImages and kept until finalization
{$IF CompilerVersion >= 35}
function LoadToolsImages(const ResourceNames: array of string): TGraphicArray;
var
  Png: TPngImage;
  I: NativeInt;
begin
  SetLength(Result, Length(ResourceNames));
  for I := 0 to High(ResourceNames) do
  begin
    Png := TPngImage.Create;
    ToolsImages.Add(Png);
    Png.LoadFromResourceName(HInstance, ResourceNames[I]);
    Result[I] := Png;
  end;
end;

// Shared by the splash screen and the About box
function ToolsIcon: TGraphicArray;
begin
  if Length(IconImages) = 0 then
    IconImages := LoadToolsImages(['FIB_ICON_24', 'FIB_ICON_36', 'FIB_ICON_48']);
  Result := IconImages;
end;
{$ELSE}
// 24x24, 32-bit with premultiplied alpha, shared by the splash screen and the About box
function ToolsIcon: TBitmap;
var
  Png: TPngImage;
begin
  if not Assigned(IconBitmap) then
  begin
    IconBitmap := TBitmap.Create;
    ToolsImages.Add(IconBitmap);
    Png := TPngImage.Create;
    try
      Png.LoadFromResourceName(HInstance, 'FIB_ICON_24');
      IconBitmap.Assign(Png);
    finally
      Png.Free;
    end;
  end;
  Result := IconBitmap;
end;
{$ENDIF}

function ProductTitle: string;
begin
  Result := Format(SAboutProduct, [FIBVersionString]);
end;

procedure RegisterSplashScreen;
begin
  if Assigned(SplashScreenServices) then
    SplashScreenServices.AddPluginBitmap(ProductTitle, ToolsIcon{$IF CompilerVersion < 35}.Handle{$ENDIF});
end;

{$IF CompilerVersion >= 35}
procedure SetMenuImage(const Services: INTAServices);
begin
  MenuRoot.ImageIndex := Services.AddImage('FIBToolsIcon',
    LoadToolsImages(['FIB_ICON_16', 'FIB_ICON_20', 'FIB_ICON_24', 'FIB_ICON_32']));
end;
{$ELSE}
procedure SetMenuImage(const Services: INTAServices);
var
  ImageList: TImageList;
  Png: TPngImage;
  Bitmap: TBitmap;
begin
  ImageList := TImageList.Create(nil);
  try
    ImageList.ColorDepth := cd32Bit;
    ImageList.SetSize(16, 16);
    Png := TPngImage.Create;
    Bitmap := TBitmap.Create;
    try
      Png.LoadFromResourceName(HInstance, 'FIB_ICON_16');
      Bitmap.Assign(Png);
      ImageList.Add(Bitmap, nil);
    finally
      Bitmap.Free;
      Png.Free;
    end;
    // Copied into the IDE image list
    MenuRoot.ImageIndex := Services.AddImages(ImageList, 'FIBToolsIcon');
  finally
    ImageList.Free;
  end;
end;
{$ENDIF}

procedure RegisterMenu;
var
  Services: INTAServices;
  Item: TMenuItem;
begin
  if not Supports(BorlandIDEServices, INTAServices, Services) then
    Exit;
  MenuHandler := TFIBToolsMenuHandler.Create(nil);
  MenuRoot := TMenuItem.Create(nil);
  MenuRoot.Name := 'FIBToolsMenu';
  MenuRoot.Caption := SToolsMenu;
  SetMenuImage(Services);
  MenuRoot.FreeNotification(MenuHandler);

  Item := TMenuItem.Create(MenuRoot);
  Item.Caption := SToolsPreferencesItem;
  Item.OnClick := MenuHandler.PreferencesClick;
  MenuRoot.Add(Item);

  MenuRoot.Add(NewLine);

  Item := TMenuItem.Create(MenuRoot);
  Item.Caption := SToolsAboutItem;
  Item.OnClick := MenuHandler.AboutClick;
  MenuRoot.Add(Item);

  // Before Configure Tools: the IDE rebuilds the external tool items after it once the packages are loaded
  try
    try
      Services.AddActionMenu('ToolsToolsItem', nil, MenuRoot, False, False);
    except
      Services.AddActionMenu('ToolsMenu', nil, MenuRoot, True, True);
    end;
  except
    FreeAndNil(MenuRoot);
    raise;
  end;
end;

procedure UnregisterMenu;
begin
  MenuRoot.Free;
  MenuRoot := nil;
  FreeAndNil(MenuHandler);
end;

procedure RegisterDebuggerNotifier;
var
  Services: IOTADebuggerServices;
begin
  if Supports(BorlandIDEServices, IOTADebuggerServices, Services) then
    DebuggerNotifierIndex := Services.AddNotifier(TFIBDebuggerNotifier.Create);
end;

procedure UnregisterDebuggerNotifier;
var
  Services: IOTADebuggerServices;
begin
  if (DebuggerNotifierIndex >= 0) and Supports(BorlandIDEServices, IOTADebuggerServices, Services) then
    Services.RemoveNotifier(DebuggerNotifierIndex);
  DebuggerNotifierIndex := -1;
end;

function AboutBoxDescription: string;
begin
  Result := SAboutDescription + sLineBreak + sLineBreak + FIBProjectURL;
end;

{$IF CompilerVersion >= 35}
procedure RegisterAboutBox;
var
  Services: IOTAAboutBoxServices280;
begin
  if Supports(BorlandIDEServices, IOTAAboutBoxServices280, Services) then
    AboutBoxIndex := Services.AddPluginInfo(ProductTitle, AboutBoxDescription, ToolsIcon);
end;
{$ELSE}
procedure RegisterAboutBox;
var
  Services: IOTAAboutBoxServices270;
begin
  if Supports(BorlandIDEServices, IOTAAboutBoxServices270, Services) then
    AboutBoxIndex := Services.AddPluginInfo(ProductTitle, AboutBoxDescription, ToolsIcon.Handle, False, '', '',
      otaafPremultiplied);
end;
{$ENDIF}

procedure UnregisterAboutBox;
var
  Services: IOTAAboutBoxServices;
begin
  if (AboutBoxIndex >= 0) and Supports(BorlandIDEServices, IOTAAboutBoxServices, Services) then
    Services.RemovePluginInfo(AboutBoxIndex);
  AboutBoxIndex := -1;
end;

procedure Register;
begin
  RegisterMenu;
  RegisterDebuggerNotifier;
  RegisterAboutBox;
end;

initialization
  ToolsImages := TObjectList<TGraphic>.Create;
  RegisterSplashScreen;

finalization
  UnregisterAboutBox;
  UnregisterDebuggerNotifier;
  UnregisterMenu;
  ToolsImages.Free;

end.
