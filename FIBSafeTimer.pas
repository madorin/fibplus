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
{    Written by Serge Buzadzhy (buzz@devrace.com)               }
{                                                               }
{ ------------------------------------------------------------- }
{    FIBPlus home page: http://www.fibplus.com/                 }
{    FIBPlus support  : http://www.devrace.com/support/         }
{ ------------------------------------------------------------- }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit FIBSafeTimer;

interface
{$I FIBPlus.inc}
uses

 {$IFDEF WINDOWS}
  Windows,
 {$ELSE}
  {$IFDEF MACOS}
      Macapi.ObjCRuntime,      Macapi.CocoaTypes,
      Macapi.ObjectiveC,      Macapi.Foundation,
  {$ENDIF}
 {$ENDIF}
  FIBPlatforms,  SyncObjs, SysUtils, Classes;

type

  { TFIBCustomTimer }

  TFIBCustomTimer = class(TComponent)
  private
    FActive: Boolean;
    FSynchronizing:boolean;
   {$IFNDEF MACOS}
     FHandle: Integer;
   {$ENDIF}
    FInterval: Integer;
    FOnTimer: TNotifyEvent;
    procedure SetActive(const Value: Boolean);
    procedure SetInterval(const Value: Integer);
  protected
  {$IFDEF MACOS}
     User:TObject;
  {$ENDIF}
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property  Synchronizing:boolean read FSynchronizing write FSynchronizing;
    property  Enabled: Boolean read FActive write SetActive;
    property  Interval: Integer read FInterval write SetInterval;
    property  OnTimer: TNotifyEvent read FOnTimer write FOnTimer;
  end;



implementation
{$IFDEF D_XE3}
  uses System.Types,System.TypInfo; // for inline funcs
{$ENDIF}

var
  TimerList: TThreadList;

type
  TSyncThread=class(TThread)
  protected
    FTimer:TFIBCustomTimer;
    procedure Execute; override;
    procedure DoOnTimer;
  end;

{$IFDEF WINDOWS}

procedure TimerProc(HWND, uMsg, idEvent, dwTime : Integer); stdcall;
var
  I: Integer;
  Timer: TFIBCustomTimer;
  List:TList;
  st:TSyncThread;
begin
  if TimerList=nil then
    Exit;
  I := 0;
  List:=TimerList.LockList;
  try
    while I < List.Count do
    begin
      Timer := List.Items[I];
      if (Timer <> nil) and (idEvent = Timer.FHandle) and
         (Assigned(Timer.FOnTimer))
      then
      begin
        if not Timer.FSynchronizing or (CurrentThreadID = MainThreadID) then
          Timer.FOnTimer(Timer)
        else
        begin
          st:=TSyncThread.Create(True);
          try
           st.FTimer:=Timer;
           st.Synchronize(st.DoOnTimer);
          finally
           st.Free
          end;
        end ;
        Exit;
      end;
      Inc(I);
    end;
   finally
    TimerList.UnlockList
   end
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
    Owner:TFIBCustomTimer;
    MacNativeTimer: NSTimer;
  public
    function GetObjectiveCClass: PTypeInfo; override;
    procedure timerEvent; cdecl;
    procedure release; cdecl;
  end;


{  threadvar
   FHandleCounter:Cardinal;}

  function TFIBWrapMacTimer.GetObjectiveCClass: PTypeInfo;
  begin
    Result := TypeInfo(ICocoaTimer);
  end;

  procedure TFIBWrapMacTimer.timerEvent;
  var
     st:TSyncThread;
  begin
    if Assigned(Owner.FOnTimer) then
     if not Owner.FSynchronizing or (CurrentThreadID=MainThreadID) then
      Owner.FOnTimer(Owner)
     else
     begin
          st:=TSyncThread.Create(True);
          try
           st.FTimer:=Owner;
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

  procedure MACCreateTimer(AOwner:TFIBCustomTimer;Interval: Integer);
  var
    User: TFIBWrapMacTimer;
    LInterval: NSTimeInterval;
  begin
    User := TFIBWrapMacTimer.Create;
    try
      LInterval := Interval/1000;
      User.MacNativeTimer := TNSTimer.Wrap(TNSTimer.OCClass.scheduledTimerWithTimeInterval(LInterval,
        User.GetObjectID, sel_getUid('timerEvent'), User.GetObjectID, True));
      AOwner.User:=User;
      User.Owner:=AOwner;
    finally
      {user is retained (twice, because it's target), by the timer and }
      {released (twice) on timer invalidation}
      NSObject(User.Super).release;
    end;
  end;

  function MACDestroyTimer(Timer: TFIBCustomTimer): Boolean;
  var
    NativeTimer: NSTimer;
    List:TList;
    i:Integer;
  begin
    Result := False;
    List:=TimerList.LockList;
    try
     i:=List.IndexOf(Timer);
     if i>=0 then
     begin
      NativeTimer:=TFIBWrapMacTimer(Timer.User).MacNativeTimer;
      if Assigned(NativeTimer) then
      begin
       Result := True;
       NativeTimer.invalidate;
       TFIBWrapMacTimer(Timer.User).MacNativeTimer:=nil;
       NativeTimer:=nil;
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

//    TThread.CurrentThread.ThreadID;
  FActive := False;
  FInterval := 1000; {}
  FSynchronizing:=True;
  if TimerList<>nil then
   TimerList.Add(Self);
end;

destructor TFIBCustomTimer.Destroy;
begin
  Enabled := False;
  if TimerList<>nil then
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
     MACCreateTimer(Self,Interval)
  {$ENDIF}
  end;
  FActive := Value;
end;

procedure TFIBCustomTimer.SetInterval(const Value: Integer);
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
begin
 if Assigned(FTimer.OnTimer) then
  FTimer.OnTimer(FTimer)
end;

procedure TSyncThread.Execute;
begin
end;



initialization
  TimerList := TThreadList.Create;
finalization
  TimerList.Free;
  TimerList:=nil;
end.





