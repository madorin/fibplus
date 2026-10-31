{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ InterBase databases                                           }
{                                                               }
{    FIBPlus is based in part on the product                    }
{    Free IB Components, written by Gregory H. Deatz for        }
{    Hoagland, Longo, Moran, Dunst & Doukas Company.            }
{    mailto:gdeatz@hlmdd.com                                    }
{                                                               }
{    Copyright (c) 1998-2009 Devrace Ltd.                       }
{    Written by Serge Buzadzhy                                  }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit FIBSafeTimer;

interface

{$I FIB.inc}

uses

{$IFDEF WINDOWS}
  Windows,
{$ELSE}
{$IFDEF MACOS}
  Macapi.ObjCRuntime, Macapi.CocoaTypes,
  Macapi.ObjectiveC, Macapi.Foundation,
{$ENDIF}
{$ENDIF}
  FIBPlatforms, SyncObjs, SysUtils, Classes;

type

  { TFIBCustomTimer }

  TFIBCustomTimer = class(TComponent)
  private
    FActive: Boolean;
    FSynchronizing: Boolean;
{$IFNDEF MACOS}
    FHandle: NativeUInt;
{$ENDIF}
    FInterval: Cardinal;
    FOnTimer: TNotifyEvent;
    procedure SetActive(const Value: Boolean);
    procedure SetInterval(const Value: Cardinal);
  protected
{$IFDEF MACOS}
    User: TObject;
{$ENDIF}
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Synchronizing: Boolean read FSynchronizing write FSynchronizing;
    property Enabled: Boolean read FActive write SetActive;
    property Interval: Cardinal read FInterval write SetInterval;
    property OnTimer: TNotifyEvent read FOnTimer write FOnTimer;
  end;

implementation

{$IFDEF C24}
uses
  System.Types, System.TypInfo; // for inline funcs
{$ENDIF}

var
  TimerList: TThreadList;

type
  TSyncThread = class(TThread)
  protected
    FTimer: TFIBCustomTimer;
{$IFDEF WINDOWS}
    FHandle: NativeUInt;
{$ENDIF}
    procedure Execute; override;
    procedure DoOnTimer;
  end;

{$IFDEF WINDOWS}
// the event runs without the list lock: it can synchronize, show a dialog or create timers
procedure TimerProc(Wnd: HWND; Msg: UINT; idEvent: NativeUInt; Time: DWORD); stdcall;
var
  I: Integer;
  Timer: TFIBCustomTimer;
  List: TList;
  st: TSyncThread;
  Event: TNotifyEvent;
  Synchronizing: Boolean;
begin
  if TimerList = nil then
    Exit;
  Timer := nil;
  Event := nil;
  Synchronizing := False;
  List := TimerList.LockList;
  try
    for I := 0 to List.Count - 1 do
      if (List.Items[I] <> nil) and (TFIBCustomTimer(List.Items[I]).FHandle = idEvent) then
      begin
        Timer := List.Items[I];
        Event := Timer.FOnTimer;
        Synchronizing := Timer.FSynchronizing;
        Break;
      end;
  finally
    TimerList.UnlockList
  end;
  if not Assigned(Event) then
    Exit;
  if not Synchronizing or (CurrentThreadID = MainThreadID) then
    Event(Timer)
  else
  begin
    st := TSyncThread.Create(True);
    try
      st.FTimer := Timer;
      st.FHandle := idEvent;
      st.Synchronize(st.DoOnTimer);
    finally
      st.Free
    end;
  end;
end;
{$ENDIF}
{$IFDEF MACOS}
type
  TTimerProc = procedure of object;

  ICocoaTimer = interface(NSObject)
    ['{5AF4F553-FFB8-4ED1-AAC0-D6F33DCB6AAC}']
    procedure timerEvent; cdecl;
    procedure release; cdecl;
  end;

  TFIBWrapMacTimer = class(TOCLocal)
  private
    Owner: TFIBCustomTimer;
    MacNativeTimer: NSTimer;
  public
    function GetObjectiveCClass: PTypeInfo; override;
    procedure timerEvent; cdecl;
    procedure release; cdecl;
  end;

  { threadvar
    FHandleCounter:Cardinal; }

function TFIBWrapMacTimer.GetObjectiveCClass: PTypeInfo;
begin
  Result := TypeInfo(ICocoaTimer);
end;

procedure TFIBWrapMacTimer.timerEvent;
var
  st: TSyncThread;
begin
  if Assigned(Owner.FOnTimer) then
    if not Owner.FSynchronizing or (CurrentThreadID = MainThreadID) then
      Owner.FOnTimer(Owner)
    else
    begin
      st := TSyncThread.Create(True);
      try
        st.FTimer := Owner;
        st.Synchronize(st.DoOnTimer);
      finally
        st.Free
      end;
    end
end;

procedure TFIBWrapMacTimer.release;
var
  RC: Integer;
begin
  RC := NSObject(Super).retainCount;
  NSObject(Super).release;
  if RC = 1 then
    Destroy;
end;

procedure MACCreateTimer(AOwner: TFIBCustomTimer; Interval: Cardinal);
var
  User: TFIBWrapMacTimer;
  LInterval: NSTimeInterval;
begin
  User := TFIBWrapMacTimer.Create;
  try
    LInterval := Interval / 1000;
    User.MacNativeTimer := TNSTimer.Wrap(TNSTimer.OCClass.scheduledTimerWithTimeInterval(LInterval,
      User.GetObjectID, sel_getUid('timerEvent'), User.GetObjectID, True));
    AOwner.User := User;
    User.Owner := AOwner;
  finally
    { user is retained (twice, because it's target), by the timer and }
    { released (twice) on timer invalidation }
    NSObject(User.Super).release;
  end;
end;

function MACDestroyTimer(Timer: TFIBCustomTimer): Boolean;
var
  NativeTimer: NSTimer;
  List: TList;
  I: Integer;
begin
  Result := False;
  List := TimerList.LockList;
  try
    I := List.IndexOf(Timer);
    if I >= 0 then
    begin
      NativeTimer := TFIBWrapMacTimer(Timer.User).MacNativeTimer;
      if Assigned(NativeTimer) then
      begin
        Result := True;
        NativeTimer.invalidate;
        TFIBWrapMacTimer(Timer.User).MacNativeTimer := nil;
        NativeTimer := nil;
      end;
    end;
  finally
    TimerList.UnlockList
  end;
end;
{$ENDIF}
{ TFIBCustomTimer }

constructor TFIBCustomTimer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FInterval := 1000;
  FSynchronizing := True;
  if TimerList <> nil then
    TimerList.Add(Self);
end;

destructor TFIBCustomTimer.Destroy;
begin
  Enabled := False;
  if TimerList <> nil then
    TimerList.Remove(Self);
  inherited;
end;

procedure TFIBCustomTimer.SetActive(const Value: Boolean);
begin
  if FActive = Value then
    Exit;
  if FActive then
  begin
{$IFDEF WINDOWS}
    KillTimer(0, FHandle);
    FHandle := 0;
{$ENDIF}
{$IFDEF MACOS}
    MACDestroyTimer(Self);
{$ENDIF}
  end;
  if Value then
  begin
{$IFDEF WINDOWS}
    FHandle := SetTimer(0, 0, FInterval, @TimerProc);
{$ENDIF}
{$IFDEF MACOS}
    MACCreateTimer(Self, Interval)
{$ENDIF}
  end;
  FActive := Value;
end;

procedure TFIBCustomTimer.SetInterval(const Value: Cardinal);
var
  OldEnabled: Boolean;
begin
  OldEnabled := Enabled;
  Enabled := False;
  FInterval := Value;
  Enabled := OldEnabled;
end;

{ TSyncThread }

procedure TSyncThread.DoOnTimer;
{$IFDEF WINDOWS}
var
  Event: TNotifyEvent;
  List: TList;
{$ENDIF}
begin
{$IFDEF WINDOWS}
  // the main thread may have freed or stopped the timer while the call waited
  Event := nil;
  if TimerList = nil then
    Exit;
  List := TimerList.LockList;
  try
    if (List.IndexOf(FTimer) >= 0) and (FTimer.FHandle = FHandle) then
      Event := FTimer.FOnTimer;
  finally
    TimerList.UnlockList
  end;
  if Assigned(Event) then
    Event(FTimer)
{$ELSE}
  if Assigned(FTimer.OnTimer) then
    FTimer.OnTimer(FTimer)
{$ENDIF}
end;

procedure TSyncThread.Execute;
begin
end;

initialization

TimerList := TThreadList.Create;

finalization

TimerList.Free;
TimerList := nil;

end.
