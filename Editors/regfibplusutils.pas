{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ Interbase databases                                           }
{                                                               }
{    FIBPlus is based in part on the product                    }
{    Free IB Components, written by Gregory H. Deatz for        }
{    Hoagland, Longo, Moran, Dunst & Doukas Company.            }
{    mailto:gdeatz@hlmdd.com                                    }
{                                                               }
{    Copyright (c) 1998-2001 Serge Buzadzhy                     }
{    Contact: buzz@devrace.com                                  }
{                                                               }
{ ------------------------------------------------------------- }
{    FIBPlus home page      : http://www.fibplus.net/           }
{    FIBPlus support e-mail : fibplus@devrace.com               }
{ ------------------------------------------------------------- }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}
unit regfibplusutils;

interface

{$I fibplus.inc}
uses forms, menus, classes, sysutils, db, dialogs, controls,
{$IFNDEF  D6+}
  dsgnintf,
{$ELSE}
  DesignIntf,
{$ENDIF}
  pfibdsgnviewsqls, pfibpreferences, fib

  ;

implementation

uses FIBDatabase, FIBToolsConsts, ShellAPI, Mapi, Windows, ExtCtrls, FindCmp, ToolsAPI;


type
    TDebuggerNotifier= class(TComponent,IOTADebuggerNotifier)
     procedure ProcessCreated({$IFDEF D2009+}const {$ENDIF}Process: IOTAProcess);
     procedure ProcessDestroyed({$IFDEF D2009+}const {$ENDIF}Process: IOTAProcess);
     procedure BreakpointAdded({$IFDEF D2009+}const {$ENDIF}Breakpoint: IOTABreakpoint);
     procedure BreakpointDeleted({$IFDEF D2009+}const {$ENDIF}Breakpoint: IOTABreakpoint);
     procedure AfterSave;
     procedure BeforeSave;
     procedure Destroyed;
     procedure Modified;
    end;



 procedure TDebuggerNotifier.AfterSave;
 begin

 end;

 procedure TDebuggerNotifier.BeforeSave;
 begin

 end;

 procedure TDebuggerNotifier.Destroyed;
 begin

 end;

 procedure TDebuggerNotifier.Modified;
 begin

 end;

 procedure TDebuggerNotifier.ProcessCreated({$IFDEF D2009+}const {$ENDIF}Process: IOTAProcess);
 begin
//   ShowMessage('Process Created '+IntToStr(Process.ProcessId));
   if bCloseDesignConnect then
   begin
     CloseAllDatabases
   end;
 end;

 procedure TDebuggerNotifier.ProcessDestroyed({$IFDEF D2009+}const {$ENDIF}Process: IOTAProcess);
 begin

 end;

 procedure TDebuggerNotifier.BreakpointAdded({$IFDEF D2009+}const {$ENDIF}Breakpoint: IOTABreakpoint);
 begin

 end;

 procedure TDebuggerNotifier.BreakpointDeleted({$IFDEF D2009+}const {$ENDIF}Breakpoint: IOTABreakpoint);
 begin

 end;






type
  TFakeObj = class
  private
    FTimer:TTimer;
    mi :TMenuItem;
    mi1:TMenuItem;
    procedure miOnClick(Sender: TObject);
    procedure OnTimer(Sender: TObject);
  public
    constructor Create;
    destructor Destroy; override;
  end;

var
  FakeObj: TFakeObj;
  MiRoot: TMenuItem;

constructor TFakeObj.Create;
begin
  inherited Create;
  FTimer:=TTimer.Create(nil);
  FTimer.OnTimer:=OnTimer;
  FTimer.Enabled:=True;
end;

destructor TFakeObj.Destroy;
begin
  FTimer.Free;
  inherited Destroy;
end;

procedure TFakeObj.OnTimer(Sender: TObject);
begin
  mi.ShortCut:=ShortCut(Word('W'),[ssCtrl]);
  mi1.ShortCut:=ShortCut(Word('W'),[ssCtrl,ssShift]);
  FTimer.Enabled:=False;
  FTimer.Free;
  FTimer:=nil
end;

function SendMail(ARecepients, ASubject, AMessage, AFiles: string): Integer;

var
  {$IFNDEF D4+}
  Msg: TMapiMessage;
  DFile, CFile: TMapiFileDesc;
  ToRec: TMapiRecipDesc;
  {$ELSE}
  Msg: MapiMessage;
  DFile, CFile: MapiFileDesc;
  ToRec: MapiRecipDesc;
  {$ENDIF}
  Flags: Cardinal;
begin
  ToRec.ulReserved := 0;
  ToRec.ulRecipClass := 0;
  ToRec.lpszName := PAnsiChar('');
  //ToRec.lpszAddress := PAnsiChar(ARecepients);  
  ToRec.lpszAddress := PAnsiChar(PChar(ARecepients));
  ToRec.ulRecipClass := MAPI_TO;
  ToRec.ulEIDSize := 0;

  DFile.ulReserved := 0;
  DFile.flFlags := 0;
  {$IFNDEF D4+}
  DFile.nPosition := $FFFF;
  {$ELSE}
  DFile.nPosition := $FFFFFFFF;
  {$ENDIF}
  //DFile.lpszPathName := PAnsiChar(AFiles);   
  DFile.lpszPathName := PAnsiChar(PChar(AFiles));
  DFile.lpszFileName := nil;
  DFile.lpFileType := nil;

  CFile.ulReserved := 0;
  CFile.flFlags := 0;
  {$IFNDEF D4+}
  CFile.nPosition := $FFFF;
  {$ELSE}
  CFile.nPosition := $FFFFFFFF;
  {$ENDIF}
  CFile.lpszPathName := '';
  CFile.lpszFileName := nil;
  CFile.lpFileType := nil;

  Msg.ulReserved := 0;
  //Msg.lpszSubject := PAnsiChar(ASubject);
  //Msg.lpszNoteText := PAnsiChar(AMessage);
  Msg.lpszSubject := PAnsiChar(PChar(ASubject));
  Msg.lpszNoteText := PAnsiChar(PChar(AMessage));

  Msg.lpszMessageType := nil;
  Msg.lpszDateReceived := nil;
  Msg.lpszConversationID := nil;
  Msg.flFlags := 0;
  Msg.lpOriginator := nil;
  Msg.nRecipCount := 1;
  Msg.lpRecips := @ToRec;
  Msg.nFileCount := 0;
  Msg.lpFiles := @CFile;
  Flags := MAPI_LOGON_UI or MAPI_NEW_SESSION;
  Flags := Flags or MAPI_DIALOG;
  Result := MAPISendMail(0, 0, Msg, Flags, 0);
end;

const
  constVerFileDescription: PChar = 'StringFileInfo\040904E4\FileDescription'; // do not localize
  constVerFileVersion = 'StringFileInfo\040904E4\FileVersion'; // do not localize
  constFIBPlusEngNews = 'news://news.better-office.com/de.news.devrace.fibplus.eng'; // do not localize
  constFIBPlusRusNews = 'news://news.better-office.com/de.news.devrace.fibplus.rus'; // do not localize
  constFIBPlusEmail = 'fibplus@devrace.com'; // do not localize

function GetIDEEnviropment: string;
var
  S: string;
  n, Len: UINT;
  Buf: PChar;
  Value: PChar;
begin
  S := Application.ExeName;
  {$IFNDEF D4+}
  n := GetFileVersionInfoSize(PWideChar(S), n);
  {$ELSE}
  n := GetFileVersionInfoSize(PChar(S), Cardinal(n));
  {$ENDIF}
  if n > 0 then
  begin
    Buf := AllocMem(n);
    GetFileVersionInfo(PChar(S), 0, n, Buf);
    {$IFNDEF D4+}
    if VerQueryValue(Buf, constVerFileDescription, pointer(Value), Len) then
    {$ELSE}
    if VerQueryValue(Buf, constVerFileDescription, Pointer(Value), Cardinal(Len)) then
    {$ENDIF}
      if Length(Value) > 0 then
        Result := Value;
    FreeMem(Buf, n);
  end
end;

function GetIDEVersion: string;
var
  S: string;
  n, Len: Integer;
  Buf: PChar;
  Value: PChar;
begin
  S := Application.ExeName;
  {$IFNDEF D4+}
  n := GetFileVersionInfoSize(PWideChar(S), Cardinal(n));
  {$ELSE}
  n := GetFileVersionInfoSize(PChar(S), Cardinal(n));
  {$ENDIF}
  if n > 0 then
  begin
    Buf := AllocMem(n);
    GetFileVersionInfo(PChar(S), 0, n, Buf);
    {$IFNDEF D4+}
    if VerQueryValue( Buf, constVerFileVersion, Pointer(Value), Cardinal(Len)) then
    {$ELSE}
    if VerQueryValue(Buf, constVerFileVersion, Pointer(Value), Cardinal(Len)) then
    {$ENDIF}
      if Length(Value) > 0 then
        Result := Value;
    FreeMem(Buf, n);
  end
end;

function GetIDEInfo: string;
begin
  Result := Format('%s %s', [GetIDEEnviropment, GetIDEVersion]);
end;

function GetFIBPlusVersion: string;
begin
  Result := Format(FPBuildMenu, [FIBPlusVersion, FIBPlusBuild, FIBCustomBuild]);
end;

procedure TFakeObj.miOnClick(Sender: TObject);
begin
  case TMenuItem(Sender).Tag of
    2: ShowAllSQLs;
    3: ShowFIBPreferences;
    4: ShellExecute(Application.Handle, '', constFIBPlusEngNews, nil, nil, SW_SHOWNORMAL);
    5: ShellExecute(Application.Handle, '', constFIBPlusRusNews, nil, nil, SW_SHOWNORMAL);
    6: SendMail(constFIBPlusEmail, Format('Bug-report [%s, IDE: %s]', [GetFIBPlusVersion, GetIDEInfo]), '', ''); // do not localize
    7: SendMail(constFIBPlusEmail, Format('Suggestions [%s, IDE: %s]', [GetFIBPlusVersion, GetIDEInfo]), '', ''); // do not localize
    8: SendMail(constFIBPlusEmail, Format('Information request [%s, IDE: %s]', [GetFIBPlusVersion, GetIDEInfo]), '', ''); // do not localize
    9: FindComponentExpert.DoSearchComponents(True);
    10:FindComponentExpert.DoSearchComponents(False);
  end;
end;

procedure RegisterFIBUtils;
var
  Menu: TMainMenu;
  cmp: TComponent;
  mi1: TMenuItem;

  function AddItem(Root: TMenuItem; const aCaption: string;
   anOnClick:TNotifyEvent;
    aTag: Integer): TMenuItem;
  begin
    Result := NewItem(aCaption, 0, False, True, anOnClick, 0, '');
    Result.Tag := aTag;
    Root.Add(Result);
  end;

begin
  with Application do
    if (MainForm <> nil) then
    begin
      cmp := MainForm.FindComponent('MainMenu1');
      if cmp = nil then begin
        ShowMessage(ErrInstallMess);
        Exit;
      end;
      Menu := TMainMenu(cmp);
      MiRoot := NewItem(FPFIBPlusMenu, 0, False, True, nil, 0, 'miRootFIBPlusUtils');
      Menu.Items.Insert(8, MiRoot);

      AddItem(MiRoot, FPpreferencesMenu, FakeObj.miOnClick, 3);
      AddItem(MiRoot, FPSQLNavigator, FakeObj.miOnClick, 2);

      FakeObj.mi:=AddItem(MiRoot, FPFindComponent,FakeObj.miOnClick, 9);
      FakeObj.mi1:=AddItem(MiRoot, FPFindComponents,FakeObj.miOnClick, 10);


      // Feedback and newsgroups
      mi1 := AddItem(MiRoot, FPNewsgroups,nil, 0);
      AddItem(mi1, FPNewsgroupsEnglish, FakeObj.miOnClick, 4);
      AddItem(mi1, FPNewsgroupsRussian,FakeObj.miOnClick, 5);
      mi1 := AddItem(MiRoot, FPFeedback,nil, 0);
      AddItem(mi1, FPFeedbackBug, FakeObj.miOnClick, 6);
      AddItem(mi1, FPFeedbackSuggestions, FakeObj.miOnClick, 7);
      AddItem(mi1, FPFeedbackInformation, FakeObj.miOnClick, 8);

      mi1 := NewLine;
      MiRoot.Add(mi1);

      AddItem(MiRoot, Format(FPBuildMenu, [FIBPlusVersion, FIBPlusBuild, FIBCustomBuild]) ,nil, 0);
    end
    else ShowMessage(ErrInstallMess);
end;

procedure UnRegisterFIBUtils;
begin
  MiRoot.Free
end;

var
   dn:TDebuggerNotifier;
   idn:integer;
initialization
  dn:=TDebuggerNotifier.Create(nil);
  idn:= (BorlandIDEServices as IOTADebuggerServices).AddNotifier(dn);
  FakeObj := TFakeObj.Create;
  RegisterFIBUtils;

finalization
  (BorlandIDEServices as IOTADebuggerServices).RemoveNotifier(idn);
  UnRegisterFIBUtils;
  FakeObj.Free;
end.

