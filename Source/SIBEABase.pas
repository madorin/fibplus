unit SIBEABase;

// SuperIB
// Copyright (c) 1999 David S. Becker
// dhbecker@jps.net
// www.jps.net/dhbecker/superib

{$I FIB.inc}
{$T-}

interface

uses
  SysUtils, Classes, SyncObjs, SIBGlobals, SIBAPI, ibase, IB_Intf, IB_Externals;

type
  TFIBEventAlerterThread = class;
  TFIBEventAlertEvent = procedure(Sender: TObject; EventName: string; EventCount: LongInt) of object;
  TFIBEventErrorEvent = procedure(Sender: TObject; E: Exception) of object;

  { TFIBCustomEventAlerter }

  TFIBCustomEventAlerter = class(TComponent)
  protected
    { Private declarations }
    FClientLibrary: IFIBClientLibrary;
    FOnEventAlert: TFIBEventAlertEvent;
    FOnError: TFIBEventErrorEvent;
    FEvents: TStrings;
    FThreads: TList;
    FEndedThreads: TList;
    FNativeHandle: SIB_DBHandle;
    ThreadException: Boolean;
    FVCLSynchro: Boolean;
    // guards FThreads and FEndedThreads, changed by event threads when VCLSynchronize is False
    FLock: TCriticalSection;
    procedure SetEvents(Value: TStrings);
    function GetRegistered: Boolean;
    procedure SetRegistered(const Value: Boolean);
    procedure FreeEndedThreads;
    function TakeThread(out Thread: TFIBEventAlerterThread): Boolean;
    function RemoveThread(Thread: TFIBEventAlerterThread): Boolean;
    procedure AddEndedThread(Thread: TFIBEventAlerterThread);
    function TakeEndedThread(out Thread: TFIBEventAlerterThread): Boolean;
    procedure StopThreads;
    procedure StopThread(Thread: TFIBEventAlerterThread);
    function ThreadFailed(Thread: TFIBEventAlerterThread): Boolean;
  protected
    { Protected declarations }
    procedure SetNativeHandle(const Value: SIB_DBHandle); virtual;
    function GetNativeHandle: SIB_DBHandle; virtual;
    procedure EventChange(Sender: TObject); virtual;
    procedure ThreadEnded(Sender: TObject); virtual;
  public
    { Public declarations }
    constructor Create(Owner: TComponent); override;
    destructor Destroy; override;
    procedure RegisterEvents; virtual;
    procedure UnRegisterEvents; virtual;
    property NativeHandle: SIB_DBHandle read GetNativeHandle write SetNativeHandle;
    property Registered: Boolean read GetRegistered write SetRegistered;
  published
    { Published declarations }
    property VCLSynchronize: Boolean read FVCLSynchro write FVCLSynchro default True;
    property Events: TStrings read FEvents write SetEvents;
    property OnEventAlert: TFIBEventAlertEvent read FOnEventAlert write FOnEventAlert;
    property OnError: TFIBEventErrorEvent read FOnError write FOnError;
  end;

  { TFIBEventAlerterThread }

  TFIBEventAlerterThread = class(TThread)
  private
    { Private declarations }
    // IB API call parameters
    FClientLibrary: IFIBClientLibrary;
    WhichEvent: Integer;
    ErrorBuffer: PAnsiChar;
    ErrorBufferLength: ULong;
    ErrorVector: SIB_PStatusVector;
    StatusVector: SIB_StatusVector;
    EventCounts: SIB_EventCountVector;
    ResultStatus: SIB_Status;
    EventID: SIB_Long;
    DB: SIB_DBHandle;
    EventBuffer: PAnsiChar;
    EventBufferLen: SIB_Short;
    ResultBuffer: PAnsiChar;
    // Local use variables
    Signal: TSimpleEvent;
    EventsReceived, FirstTime: Boolean;
    EventGroup, EventCount: Integer;
    Parent: TFIBCustomEventAlerter;
    FExceptObject: TObject;
    FExceptAddr: Pointer;
    FVCLSynchro: Boolean;
    FRunning: Boolean;
    FQueued: Boolean;
    // removed from the thread list by the alerter: it ends without calling ThreadEnded
    FDetached: Boolean;
    // the alerter was destroyed by a handler of this thread: the thread frees itself
    FOrphan: Boolean;
    // the thread that runs a handler of the alerter for this thread, 0 when none
    FHandlerThreadID: Cardinal;
    function BlockedByCaller: Boolean;
    procedure ReportException;
  protected
    procedure Execute; override;
    procedure DoTerminate; override;
    procedure QueueFirstEvents; virtual;
    procedure StartThread;
    procedure SignalEvent; virtual;
    procedure SignalTerminate; virtual;
    procedure RegisterEvents; virtual;
    procedure UnRegisterEvents; virtual;
    procedure QueueEvents; virtual;
    procedure ProcessEvents; virtual;
    function GetIBErrorString: string; virtual;
    procedure SIBQueEvents; virtual;
    procedure SIBInterpretError; virtual;
    procedure SIBEventCounts; virtual;
    procedure SIBFree; virtual;
    procedure SIBCancelEvents; virtual;
    procedure SIBEventBlock; virtual;
    procedure DoEvent; virtual;
    procedure DoHandleException; virtual;
    procedure DoApplicationHandleException;
    function HandleException: Boolean; virtual;
    procedure UpdateResultBuffer(Length: SIB_UShort; Updated: PAnsiChar); virtual;
  public
    constructor Create(ClientLibrary: IFIBClientLibrary; Owner: TFIBCustomEventAlerter;
      DBHandle: SIB_DBHandle; EventGrp: Integer; TermEvent: TNotifyEvent;
      aVCLSynchro: Boolean); virtual;
    destructor Destroy; override;
  end;

type
  // Deprecated names of the types renamed in 8.0.0
  TSIBEventAlerter = TFIBCustomEventAlerter deprecated 'Use TFIBCustomEventAlerter';
  TSIBEventThread = TFIBEventAlerterThread deprecated 'Use TFIBEventAlerterThread';
  TSIBAlertEvent = TFIBEventAlertEvent deprecated 'Use TFIBEventAlertEvent';

implementation

uses
{$IFNDEF C23}
  Windows,
{$ENDIF}
  FIBPlatforms;

// This is the callback generated by IB when an event occurs.  It passes
// a pointer of our choosing (in this case, a pointer to the event thread
// which registered the callback) as well as an updated resultbuffer
// this callback occurs in a separate thread created by IB, and therefore
// we can't do anything that interacts with the VCL so we simply copy
// the resultbuffer and set a flag to notify the event thread that
// an event was received.  By doing this we effectively bring this separate
// thread back into our event thread, which then uses Synchronize() to
// call the event handler in the main thread -- making it totally VCL safe!
procedure EventCallback(P: Pointer; Length: SIB_UShort; Updated: PAnsiChar); cdecl;
begin
  if (Assigned(P) and Assigned(Updated)) then
  begin
    TFIBEventAlerterThread(P).UpdateResultBuffer(Length, Updated);
    TFIBEventAlerterThread(P).SignalEvent;
  end;
end;

{ TFIBEventAlerterThread }

// stub for synchronizing with main thread
procedure TFIBEventAlerterThread.SIBQueEvents;
begin
  ResultStatus := SIB_QueEvents(FClientLibrary, @StatusVector, @DB, @EventID,
    EventBufferLen, PAnsiChar(EventBuffer), EventCallback, Self);
end;

// stub for synchronizing with main thread
procedure TFIBEventAlerterThread.SIBInterpretError;
begin
  ResultStatus := FClientLibrary.fb_Interpret(ErrorBuffer, ErrorBufferLength, PPISC_STATUS(@ErrorVector));
  Reset8087CW;
end;

// stub for synchronizing with main thread
procedure TFIBEventAlerterThread.SIBEventCounts;
begin
  SIB_EventCounts(FClientLibrary, @EventCounts, EventBufferLen, EventBuffer, ResultBuffer);
end;

// stub for synchronizing with main thread
procedure TFIBEventAlerterThread.SIBFree;
begin
  SIB_Free(FClientLibrary, EventBuffer);
  EventBuffer := nil;
  SIB_Free(FClientLibrary, ResultBuffer);
  ResultBuffer := nil;
end;

// stub for synchronizing with main thread
procedure TFIBEventAlerterThread.SIBCancelEvents;
begin
  ResultStatus := SIB_CancelEvents(FClientLibrary, @StatusVector, @DB, @EventID);
  SIBFree
end;

// stub for synchronizing with main thread

procedure TFIBEventAlerterThread.SIBEventBlock;
var
  EBPArray: Array [1 .. FIBMaxEventBlock] of PAnsiChar;
  EBPArrayStr: Array of AnsiString;
  i: Integer;

  function EBP(Index: Integer): PAnsiChar;
  begin
    Inc(Index, (EventGroup * FIBMaxEventBlock));
    if (Index > Parent.FEvents.Count) then
      Result := nil
    else
    begin
      EBPArrayStr[Index - 1] := AnsiString(Parent.FEvents[Index - 1]);
      Result := PAnsiChar(EBPArrayStr[Index - 1]);
    end;
  end;

begin
  EventCount := (Parent.FEvents.Count - (EventGroup * FIBMaxEventBlock));
  if (EventCount > FIBMaxEventBlock) then
    EventCount := FIBMaxEventBlock;
  SetLength(EBPArrayStr, Parent.FEvents.Count);

  for i := 1 to FIBMaxEventBlock do
  begin
    EBPArray[i] := EBP(i);
  end;
  // at most 15 names of at most 255 bytes, 1 + 15 * 260 bytes
  EventBufferLen := SIB_Short(FClientLibrary.isc_event_block(@EventBuffer, @ResultBuffer,
    Word(EventCount), EBPArray));
end;

// stub for synchronizing with main thread
procedure TFIBEventAlerterThread.DoEvent;

begin
  // unregistered while the call waited for the main thread
  if Terminated then
    Exit;
  FHandlerThreadID := CurrentThreadID;
  try
    Parent.FOnEventAlert(Parent, Parent.FEvents[((EventGroup * FIBMaxEventBlock) + WhichEvent)],
      LongInt(EventCounts[WhichEvent]));
  finally
    FHandlerThreadID := 0;
  end;
end;

// called by the IB event callback to copy an update resultbuffer
// into our own storage space
procedure TFIBEventAlerterThread.UpdateResultBuffer(Length: SIB_UShort; Updated: PAnsiChar);
begin
  Move(Updated[0], ResultBuffer[0], Length);
end;

function TFIBEventAlerterThread.GetIBErrorString: string;
var
  Buffer: array [0 .. 1023] of AnsiChar;
  lastMsg: string;
  errCode: SIB_Status;
begin
  Result := '';
  if Terminated then
    Exit;
  ErrorBuffer := @Buffer;
  ErrorBufferLength := SizeOf(Buffer);
  Buffer[0] := #0;
  ErrorVector := @StatusVector;
  repeat
    if FRunning and FVCLSynchro then
      Synchronize(SIBInterpretError)
    else
      SIBInterpretError;
    errCode := ResultStatus;
    if (AnsiString(lastMsg) <> AnsiString(Buffer)) then
    begin
      lastMsg := string(Buffer);
      if (Length(Result) <> 0) then
        Result := Result + #13#10;
      Result := Result + lastMsg;
    end;
  until (errCode = 0);
end;

// tell IB to queue up the events and begin reporting them
// first time this is called generates a bogus notification
// to initialize the result buffer
procedure TFIBEventAlerterThread.QueueEvents;
begin
  EventsReceived := False;
  if not Terminated then
  begin
    Signal.ResetEvent;
    if FVCLSynchro then
      Synchronize(SIBQueEvents)
    else
      SIBQueEvents;
    if (ResultStatus <> 0) then
      raise EFIBEventAlerterError.Create(GetIBErrorString);
  end;
end;

// registers and queues the events in the calling thread, before the thread starts
procedure TFIBEventAlerterThread.QueueFirstEvents;
begin
  RegisterEvents;
  EventsReceived := False;
  Signal.ResetEvent;
  SIBQueEvents;
  if (ResultStatus <> 0) then
    raise EFIBEventAlerterError.Create(GetIBErrorString);
  FQueued := True;
end;

procedure TFIBEventAlerterThread.StartThread;
begin
{$IFDEF C21}
  Start;
{$ELSE}
  Resume;
{$ENDIF}
end;

// call the event handler for any events received
procedure TFIBEventAlerterThread.ProcessEvents;
var
  i: Integer;
begin
  // find out how many and which events occured
  if Terminated then
    Exit;

  if FVCLSynchro then
    Synchronize(SIBEventCounts)
  else
    SIBEventCounts;
  // the first time we come in here is a bogus initialization call, so don't
  // actually do anything
  if (Assigned(Parent.FOnEventAlert) and (not FirstTime)) then
  begin
    for i := 0 to (EventCount - 1) do
    begin
      // a handler unregistered the events or destroyed the alerter
      if Terminated then
        Exit;
      // if this particular event occured, call the event handler
      if (EventCounts[i] <> 0) then
      begin
        WhichEvent := i;
        if FVCLSynchro then
          Synchronize(DoEvent)
        else
          DoEvent
      end;
    end;
  end;
  FirstTime := False;
end;

// tell IB to cancel the event notification and
// release the various event buffers
procedure TFIBEventAlerterThread.UnRegisterEvents;
begin
  // ResultStatus is not checked: the error may come from a server shutdown
  SIBCancelEvents;
end;

// setup the various event buffers with IB
procedure TFIBEventAlerterThread.RegisterEvents;
begin
  if Terminated then
    Exit;
  EventBuffer := nil;
  ResultBuffer := nil;
  EventBufferLen := 0;
  FirstTime := True;

  // figure out how many events are in the group we've been assigned
  EventCount := (Parent.FEvents.Count - (EventGroup * FIBMaxEventBlock));
  if (EventCount > FIBMaxEventBlock) then
    EventCount := FIBMaxEventBlock;
  SIBEventBlock;
  // For AutoRegistry
end;

// indicate than an event was received, and stop waiting
procedure TFIBEventAlerterThread.SignalEvent;
begin
  EventsReceived := True;
  Signal.SetEvent;

end;

// indicate termination desired, and stop waiting
procedure TFIBEventAlerterThread.SignalTerminate;
begin
  if not Terminated then
  begin
    Terminate;
    Signal.SetEvent;
  end;
end;

// True when the caller is this thread or runs a handler this thread waits for: the caller
// can't wait for the thread to end
function TFIBEventAlerterThread.BlockedByCaller: Boolean;
begin
  Result := (ThreadID = CurrentThreadID) or (FHandlerThreadID = CurrentThreadID);
end;

// runs in the main thread when it is synchronized, otherwise in the event thread
procedure TFIBEventAlerterThread.DoHandleException;
begin
  FHandlerThreadID := CurrentThreadID;
  try
    try
      // the registrations are cancelled first, so the handler can unregister or register again
      if Parent.ThreadFailed(Self) then
        if Assigned(Parent.FOnError) and (FExceptObject is Exception) then
          Parent.FOnError(Parent, Exception(FExceptObject))
        else if FVCLSynchro and Assigned(Classes.ApplicationHandleException) then
          DoApplicationHandleException
        else
          SysUtils.ShowException(FExceptObject, FExceptAddr);
    except
      // an exception raised by the handler
      if FVCLSynchro and Assigned(Classes.ApplicationHandleException) then
        Classes.ApplicationHandleException(Self)
      else
        SysUtils.ShowException(ExceptObject, ExceptAddr);
    end;
  finally
    FHandlerThreadID := 0;
  end;
end;

procedure TFIBEventAlerterThread.DoApplicationHandleException;
var
  E: TObject;
begin
  E := FExceptObject;
  FExceptObject := nil;
  // ApplicationHandleException reads ExceptObject of the main thread; the except block frees E
  try
    raise E at FExceptAddr;
  except
    Classes.ApplicationHandleException(Parent);
  end;
end;

function TFIBEventAlerterThread.HandleException: Boolean;
begin
  // if a thread exception has already occurred, then
  // don't show another one; a thread the alerter stopped reports nothing
  if not FDetached and not Parent.ThreadException then
  begin
    Result := True;
    Parent.ThreadException := True;
    // reported by ReportException, after Execute has left the except block
    if not (ExceptObject is EAbort) then
    begin
      FExceptObject := TObject(AcquireExceptionObject);
      FExceptAddr := ExceptAddr;
    end;
  end
  else
    Result := False;
end;

// calls OnError after the alerter has cancelled the registrations of the failed thread
procedure TFIBEventAlerterThread.ReportException;
begin
  try
    if FVCLSynchro and (Assigned(Parent.FOnError) or Assigned(Classes.ApplicationHandleException)) then
      Synchronize(DoHandleException)
    else
      DoHandleException;
  finally
    FExceptObject.Free;
    FExceptObject := nil;
    FExceptAddr := nil;
  end;
end;

// set everything up with IB and sit in a loop
// waiting for events to be received
procedure TFIBEventAlerterThread.Execute;
begin
  FRunning := True;
  try
    if not FQueued then
    begin
      RegisterEvents;
      QueueEvents;
    end;
    while not Terminated do
    begin
      // wait for an event to be signaled
      Signal.WaitFor(INFINITE);
      if EventsReceived then
      begin
        // handle any events that were received
        ProcessEvents;
        // queue the events
        QueueEvents;
      end;
    end;
    // thread completed OK
    ReturnValue := 0;
  except
    // thread had a problem, if we're the first
    // thread to report handle the problem, return
    // with an error code, otherwise return OK
    if HandleException then
      ReturnValue := 1
    else
      ReturnValue := 0;
  end;
  if Assigned(FExceptObject) then
    ReportException;
  // the alerter was destroyed by a handler and could not free this thread
  if FOrphan then
    FreeOnTerminate := True;
end;

procedure TFIBEventAlerterThread.DoTerminate;
begin
  if not FDetached then
    inherited DoTerminate;
end;

constructor TFIBEventAlerterThread.Create(ClientLibrary: IFIBClientLibrary;
  Owner: TFIBCustomEventAlerter; DBHandle: SIB_DBHandle; EventGrp: Integer;
  TermEvent: TNotifyEvent; aVCLSynchro: Boolean);
begin
  // started by StartThread, after QueueFirstEvents
  inherited Create(True);
  FClientLibrary := ClientLibrary;
  Signal := TSimpleEvent.Create;
  Parent := Owner;
  DB := DBHandle;
  EventGroup := EventGrp;
  OnTerminate := TermEvent;
  FVCLSynchro := aVCLSynchro;
end;

destructor TFIBEventAlerterThread.Destroy;
begin
  try
    UnRegisterEvents;
  except
    // the registration ends with the thread: an error of the cancel is not reported
  end;
  Signal.Free;
  FClientLibrary := nil;
  inherited Destroy;
end;

{ TFIBCustomEventAlerter }

// are there any event threads running
function TFIBCustomEventAlerter.GetRegistered: Boolean;
begin
  Result := (FThreads.Count > 0);
end;

// loop through all the running event threads and kill them
procedure TFIBCustomEventAlerter.UnRegisterEvents;
begin
  FreeEndedThreads;
  if (FThreads.Count = 0) then
    raise EFIBEventAlerterError.Create(SFIBEventsNotRegistered);
  StopThreads;
end;

procedure TFIBCustomEventAlerter.StopThreads;
var
  Thread: TFIBEventAlerterThread;
begin
  // WaitFor runs ThreadEnded of other threads, which removes them from the list
  while TakeThread(Thread) do
    StopThread(Thread);
end;

// a thread that waits for the caller (a handler that unregisters) is freed later
procedure TFIBCustomEventAlerter.StopThread(Thread: TFIBEventAlerterThread);
begin
  Thread.SignalTerminate;
  if Thread.BlockedByCaller then
    AddEndedThread(Thread)
  else
  begin
    Thread.WaitFor;
    Thread.Free;
  end;
end;

function TFIBCustomEventAlerter.TakeThread(out Thread: TFIBEventAlerterThread): Boolean;
begin
  Thread := nil;
  FLock.Enter;
  try
    Result := FThreads.Count > 0;
    if Result then
    begin
      Thread := TFIBEventAlerterThread(FThreads[FThreads.Count - 1]);
      FThreads.Delete(FThreads.Count - 1);
      Thread.FDetached := True;
    end;
  finally
    FLock.Leave;
  end;
end;

function TFIBCustomEventAlerter.RemoveThread(Thread: TFIBEventAlerterThread): Boolean;
var
  Index: TFIBListIndex;
begin
  FLock.Enter;
  try
    Index := FThreads.IndexOf(Thread);
    Result := Index >= 0;
    if Result then
      FThreads.Delete(Index);
  finally
    FLock.Leave;
  end;
end;

procedure TFIBCustomEventAlerter.AddEndedThread(Thread: TFIBEventAlerterThread);
begin
  FLock.Enter;
  try
    FEndedThreads.Add(Thread);
  finally
    FLock.Leave;
  end;
end;

// takes an ended thread that can be freed: not one that waits for the caller
function TFIBCustomEventAlerter.TakeEndedThread(out Thread: TFIBEventAlerterThread): Boolean;
var
  Index: TFIBListIndex;
begin
  Thread := nil;
  Result := False;
  FLock.Enter;
  try
    for Index := FEndedThreads.Count - 1 downto 0 do
      if not TFIBEventAlerterThread(FEndedThreads[Index]).BlockedByCaller then
      begin
        Thread := TFIBEventAlerterThread(FEndedThreads[Index]);
        FEndedThreads.Delete(Index);
        Result := True;
        Break;
      end;
  finally
    FLock.Leave;
  end;
end;

// cancels the registrations after an error of Thread; False when they were already cancelled
function TFIBCustomEventAlerter.ThreadFailed(Thread: TFIBEventAlerterThread): Boolean;
var
  Others: TList;
  Index: TFIBListIndex;
begin
  Others := TList.Create;
  try
    // taken together, so that threads registered meanwhile by another thread are kept
    FLock.Enter;
    try
      Result := FThreads.IndexOf(Thread) >= 0;
      if Result then
      begin
        for Index := 0 to FThreads.Count - 1 do
          if FThreads[Index] <> Thread then
          begin
            TFIBEventAlerterThread(FThreads[Index]).FDetached := True;
            Others.Add(FThreads[Index]);
          end;
        FThreads.Clear;
        Thread.FDetached := True;
        // freed by FreeEndedThreads after the handler has returned
        FEndedThreads.Add(Thread);
      end;
    finally
      FLock.Leave;
    end;
    for Index := Others.Count - 1 downto 0 do
      StopThread(TFIBEventAlerterThread(Others[Index]));
  finally
    Others.Free;
  end;
  ThreadException := False;
end;

// calculate how many event threads we need to hold the events
// and create them
procedure TFIBCustomEventAlerter.RegisterEvents;
var
  i: Integer;
  Index: TFIBListIndex;
  DBH: SIB_DBHandle;
  Thread: TFIBEventAlerterThread;
begin
  FreeEndedThreads;
  if (FThreads.Count = 0) then
  begin
    DBH := NativeHandle;
    if (FEvents.Count > 0) then
    begin
      try
        for i := 0 to ((FEvents.Count - 1) div FIBMaxEventBlock) do
        begin
          Thread := TFIBEventAlerterThread.Create(FClientLibrary, Self, DBH, i, ThreadEnded, FVCLSynchro);
          FLock.Enter;
          try
            FThreads.Add(Thread);
          finally
            FLock.Leave;
          end;
          Thread.QueueFirstEvents;
        end;
      except
        // the threads have not started: Free cancels the groups already queued
        while TakeThread(Thread) do
        begin
          Thread.OnTerminate := nil;
          Thread.Free;
        end;
        raise;
      end;
      // a thread that fails at once waits for the lock to remove itself
      FLock.Enter;
      try
        for Index := 0 to FThreads.Count - 1 do
          TFIBEventAlerterThread(FThreads[Index]).StartThread;
      finally
        FLock.Leave;
      end;
    end;
  end
  else
    raise EFIBEventAlerterError.Create(SFIBEventsAlreadyRegistered);
end;

// validates the event names being assigned
procedure TFIBCustomEventAlerter.EventChange(Sender: TObject);
var
  i: Integer;
  TooLong, AnyEmpty, WasRegistered: Boolean;
  ErrorStr: string;
begin
  ErrorStr := EmptyStr;
  WasRegistered := Registered;
  try
    if WasRegistered then
      UnRegisterEvents;

    TStringList(FEvents).OnChange := nil;
    try
      TooLong := False;
      AnyEmpty := False;
      // loop through all the Ansistring being assigned looking for errors
      for i := (FEvents.Count - 1) downto 0 do
      begin
        if (FEvents[i] = EmptyStr) then
        begin
          // can't have empty strings as events
          AnyEmpty := True;
          FEvents.Delete(i);
        end
        else if (Length(FEvents[i]) > (FIBMaxEventNameLength - 1)) then
        begin
          // can't have strings longer than EVENT_LENGTH
          TooLong := True;
        end;
      end;
      // build the error message
      if AnyEmpty then
        ErrorStr := ErrorStr + SFIBEventsEmptyNames;
      if TooLong then
        ErrorStr := ErrorStr + Format(SFIBEventNamesTooLong, [(FIBMaxEventNameLength - 1)]);

      // and return it
      if (ErrorStr <> EmptyStr) then
        raise EFIBEventAlerterError.Create(ErrorStr);
    finally
      TStringList(FEvents).OnChange := EventChange;
    end;
  finally
    if WasRegistered then
      RegisterEvents;
  end;
end;

procedure TFIBCustomEventAlerter.SetEvents(Value: TStrings);
begin
  FEvents.Assign(Value);
end;

constructor TFIBCustomEventAlerter.Create(Owner: TComponent);
begin
  inherited Create(Owner);

  FEvents := TStringList.Create;
  with TStringList(FEvents) do
  begin
    OnChange := EventChange;
    // assign the routine which validates the event lenghts
    Duplicates := dupIgnore; // don't allow duplicate events
    Sorted := True;
  end;
  FVCLSynchro := True;
  FThreads := TList.Create;
  FEndedThreads := TList.Create;
  FLock := TCriticalSection.Create;
end;

destructor TFIBCustomEventAlerter.Destroy;
var
  Index: TFIBListIndex;
begin
  try
    if Registered then
      UnRegisterEvents;
  except
  end;
  FreeEndedThreads;
  // a handler of these threads destroys the alerter: they free themselves when they end
  for Index := 0 to FEndedThreads.Count - 1 do
  begin
    TFIBEventAlerterThread(FEndedThreads[Index]).FOrphan := True;
    TFIBEventAlerterThread(FEndedThreads[Index]).OnTerminate := nil;
  end;
  FEndedThreads.Free;
  FThreads.Free;
  FLock.Free;
  FEvents.Free;
  FClientLibrary := nil;
  inherited Destroy;
end;

procedure TFIBCustomEventAlerter.SetNativeHandle(const Value: SIB_DBHandle);
var
  WasRegistered: Boolean;
begin
  if (FNativeHandle <> Value) then
  begin
    WasRegistered := Registered;
    if WasRegistered then
      UnRegisterEvents;
    try
      FNativeHandle := Value;
    finally
      if WasRegistered then
        RegisterEvents;
    end;
  end;
end;

procedure TFIBCustomEventAlerter.SetRegistered(const Value: Boolean);
begin
  if Value then
    RegisterEvents
  else
    try
      UnRegisterEvents;
    except
    end
end;

procedure TFIBCustomEventAlerter.ThreadEnded(Sender: TObject);
var
  EndedOnItsOwn: Boolean;
begin
  if (Sender is TFIBEventAlerterThread) then
  begin
    // Remove terminating thread from thread list
    EndedOnItsOwn := RemoveThread(TFIBEventAlerterThread(Sender));

    // if any thread had an exception, then unregister everything
    if (TFIBEventAlerterThread(Sender).ReturnValue = 1) then
    begin
      StopThreads;

      // Clear the thread exception
      ThreadException := False;
    end;
    // The thread waits for this call to return: it is freed later, by FreeEndedThreads
    if EndedOnItsOwn then
      AddEndedThread(TFIBEventAlerterThread(Sender));
  end;
end;

// Frees the threads that ended with an error or were stopped by their handler
procedure TFIBCustomEventAlerter.FreeEndedThreads;
var
  Thread: TFIBEventAlerterThread;
begin
  while TakeEndedThread(Thread) do
    Thread.Free;
end;

function TFIBCustomEventAlerter.GetNativeHandle: SIB_DBHandle;
begin
  Result := FNativeHandle;
end;

end.
