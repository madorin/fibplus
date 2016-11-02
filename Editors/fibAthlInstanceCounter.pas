unit fibAthlInstanceCounter;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Classes;
//  Graphics,
//  Controls,
//  Forms,
//  Dialogs;

const
  CNLEN = 15; // Computer name length
  EventSignature = $EAB6F31C;

type
  TAthlInstanceEventType =
    (
    ieGlobalCreated, // Global notiifcation about instance creation
    ieGlobalDeleted, // Global notiifcation about instance deletion
    ieLocalRequest, // Local request for immeidate update
    ieLocalStatus, // "I'm still alive" local notification
    ieGlobalRequest, // Global request for immeidate update
    ieGlobalStatus // "I'm still alive" global notification
    );

  TAthlInstanceEvent = record
    Signature: DWORD; // $EAB6F31C
    Id: DWORD; // Unique (per-process) ID to suppress duplicates
    Event: TAthlInstanceEventType; // TYpe of event
    Computer: string[CNLEN + 1]; // Name of computer
    LocalIndex: Integer; // Used to form slot name
    InstanceCount: Integer; // The number of instances on computer
    PID: DWORD; // Process ID
  end;
  PAthlInstanceEvent = ^TAthlInstanceEvent;

  TAthlInstanceGlobalInfo = record
    Computer: string[CNLEN + 1]; // Name of computer
    LocalCount: Integer; // Count of instances on the computer
    LastRefresh: TDateTime; // Last time the activity of computer detected
  end;
  PAthlInstanceGlobalInfo = ^TAthlInstanceGlobalInfo;

  TAthlInstanceLocalInfo = record
    PID: DWORD; // Process ID
    LastRefresh: TDateTime; // Last time the activity of process detected
  end;
  PAthlInstanceLocalInfo = ^TAthlInstanceLocalInfo;

  TAthlInstanceCounterThread = class;

  TAthlInstanceCounter = class{(TComponent)}
  private
    { Private declarations }
    _Active: Boolean;
    _UpdateCount: Integer;
    _Interval: Integer;
    _InstanceName: string;
    _OnChange: TNotifyEvent;
    procedure RemoveExpiredInfo;
    procedure SetInterval(const Value: Integer);
    procedure SetInstanceName(const Value: string);
      // delete items older then Now-Interval*3
  private
    _ReceivedEvents: TStringList;
    _ThreadLocalInfo: TThreadList;
    _ThreadGlobalInfo: TThreadList;
    _LocalInfo: TList;
    _GlobalInfo: TList;
    _LockCount: Integer;
    procedure Lock;
    procedure Unlock;
  private
    _ThreadStop: THANDLE;
    _ThreadStopped: THANDLE;
    _Thread: TAthlInstanceCounterThread;
  protected
    { Protected declarations }
    procedure SetActive(Value: Boolean);
    procedure ApplyUpdates;
//    procedure Loaded; override;
  public
    { Public declarations }
    function CountComputers: Integer;
    function CountInstances: Integer;
    procedure RequestUpdate;
  published
    { Published declarations }
    constructor Create{(AComponent: TComponent)}; //override;
    destructor Destroy; override;
    property Active: Boolean read _Active write SetActive;
    procedure BeginUpdates;
    procedure EndUpdates;
    property InstanceName: string read _InstanceName write SetInstanceName;
    property Interval: Integer read _Interval write SetInterval default 10000;
    property OnChange: TNotifyEvent read _OnChange write _OnChange;
  end;

  TAthlInstanceCounterThread = class(TThread)
  private
    _Owner: TAthlInstanceCounter;
    _LocalInfo: TList;
    _GlobalInfo: TList;
    _IntervalTime: TDateTIme;
    _LocalIndex: Integer;
    _Slot: THANDLE;
    _SlotName: string;
    _Changed: Boolean;
    _LockCount: Integer;
    procedure Changed;

    procedure Lock;
    procedure Unlock;

    procedure InitSlot;
    procedure DoneSlot;
    procedure UpdateSlot;

    function GetInstanceEvent(var Event: TAthlInstanceEvent): Boolean;
    procedure ProcessInstanceEvent(const Event: TAthlInstanceEvent);

    function FindLocal(const Event: TAthlInstanceEvent): PAthlInstanceLocalInfo;
    procedure PostLocal(const Event: TAthlInstanceEvent; LocalIndex: Integer);
    procedure PostLocalStatus(LocalIndex: Integer);
    procedure PostLocalRequest;

    function FindGlobal(const Event: TAthlInstanceEvent):
      PAthlInstanceGlobalInfo;
    procedure PostGlobal(const Event: TAthlInstanceEvent; Computer: string;
      LocalIndex: Integer);
    procedure PostGlobalStatus(Computer: string; LocalIndex: Integer);
    procedure PostGlobalRequest;

    procedure InitEvent(var Event: TAthlInstanceEvent);
    procedure DoPostEvent(const Event: TAthlInstanceEvent; SlotName: string);

    procedure ProcessLocalCreated(const Event: TAthlInstanceEvent);
    procedure ProcessLocalDeleted(const Event: TAthlInstanceEvent);
    procedure ProcessGlobalCreated(const Event: TAthlInstanceEvent);
    procedure ProcessGlobalDeleted(const Event: TAthlInstanceEvent);
    procedure ProcessLocalRequest(const Event: TAthlInstanceEvent);
    procedure ProcessLocalStatus(const Event: TAthlInstanceEvent);
    procedure ProcessGlobalRequest(const Event: TAthlInstanceEvent);
    procedure ProcessGlobalStatus(const Event: TAthlInstanceEvent);
  protected
    procedure Execute; override;
  public
    constructor Create(Owner: TAthlInstanceCounter);
  end;

implementation

var
  _LastEventId: Integer;

function LastEventId: Integer;
begin
  result := _LastEventId;
  INC(_LastEventId);
end;

function ComputerName: string;
var
  Buf: array[0..CNLEN] of Char;
  BufSize: DWORD;
begin
  BufSize := CNLEN + 1;
  GetComputerName(Buf, BufSize);
  result := Buf;
end;

//------------------------------------------------------------TAthlInstanceCounter

constructor TAthlInstanceCounter.Create{(AComponent: TComponent)};
begin
  inherited;
  _ReceivedEvents := TStringList.Create;
  _ThreadGlobalInfo := TThreadList.Create;
  _ThreadLocalInfo := TThreadList.Create;
  _Interval := 10000;
  _ThreadStop := CreateEvent(nil, True, False, nil);
  _ThreadStopped := CreateEvent(nil, True, False, nil);
end;

destructor TAthlInstanceCounter.Destroy;
begin
  _UpdateCount := 0;

  Active := False;

  RemoveExpiredInfo;

  _LocalInfo.Free;
  _GlobalInfo.Free;

  _ReceivedEvents.Free;

  CloseHandle(_ThreadStop);
  CloseHandle(_ThreadStopped);

  inherited;
end;

{procedure TAthlInstanceCounter.Loaded;
begin
  inherited;
  ApplyUpdates;
end;
}
procedure TAthlInstanceCounter.Lock;
begin
  _GlobalInfo := _ThreadGlobalInfo.LockList;
  _LocalInfo := _ThreadLocalInfo.LockList;
  INC(_LockCount);
end;

procedure TAthlInstanceCounter.Unlock;
begin
  DEC(_LockCount);
  if _LockCount = 0 then
  begin
    _LocalInfo := nil;
    _GlobalInfo := nil;
  end;
  _ThreadLocalInfo.UnLockList;
  _ThreadGlobalInfo.UnLockList;
end;

procedure TAthlInstanceCounter.RemoveExpiredInfo;
var
  i: Integer;
  Expiration: TDateTime;
  PLI: PAthlInstanceLocalInfo;
  PGI: PAthlInstanceGlobalInfo;
begin
  Lock;
  try
    Expiration := Now - 3 * Interval / 24 / 3600 / 1000;

    for i := _LocalInfo.Count - 1 downto 0 do
    begin
      PLI := _LocalInfo[i];
      if Active and (PLI.LastRefresh > Expiration) then
        continue;
      FreeMem(PLI);
      _LocalInfo.Remove(PLI);
    end;

    for i := _GlobalInfo.Count - 1 downto 0 do
    begin
      PGI := _GlobalInfo[i];
      if Active and (PGI.LastRefresh > Expiration) then
        continue;
      FreeMem(PGI);
      _GlobalInfo.Remove(PGI);
    end;
  finally
    Unlock;
  end;
end;

procedure TAthlInstanceCounter.SetActive(Value: Boolean);
begin
  _Active := Value;
{  if csLoading in ComponentState then
    exit;
  if csDesigning in ComponentState then exit;
}  if _UpdateCount > 0 then
    exit;

  if not Active then
  begin
    if _Thread = nil then
      exit;
    _Thread.Terminate;
    SetEvent(_ThreadStop);
    WaitForSingleObject(_ThreadStopped, INFINITE);
    _Thread := nil;
  end
  else
  begin
    if _Thread <> nil then
      exit;
    ResetEvent(_ThreadStop);
    ResetEvent(_ThreadStopped);
    _Thread := TAthlInstanceCounterThread.Create(Self);
  end;
end;

procedure TAthlInstanceCounter.SetInterval(const Value: Integer);
begin
  if Value < 1000 then
    raise Exception.Create('Interval can''t be smaller then 1000');
  _Interval := Value;
end;

function TAthlInstanceCounter.CountComputers: Integer;
begin
  Lock;
  try
    RemoveExpiredInfo;
    result := _GlobalInfo.Count;
  finally
    Unlock;
  end;
end;

function TAthlInstanceCounter.CountInstances: Integer;
var
  i: Integer;
begin
  result := 0;
  Lock;
  try
    RemoveExpiredInfo;
    for i := _GlobalInfo.Count - 1 downto 0 do
      result := result + PAthlInstanceGlobalInfo(_GlobalInfo[i]).LocalCount;
  finally
    Unlock;
  end;
end;

procedure TAthlInstanceCounter.SetInstanceName(const Value: string);
var
  i: Integer;
begin
  if Length(Value) > 8 then
    raise
      Exception.Create('Instance name is too long (max length is 8 symbols)');

  for i := 1 to Length(Value) do
    if not (Value[i] in ['a'..'z', 'A'..'Z', '0'..'9', '-', '_']) then
      raise Exception.Create('Invalid symbol in InstanceName');

  _InstanceName := Value;
{  if csLoading in ComponentState then
    exit;
  if csDesigning in ComponentState then
    exit;
}  ApplyUpdates;
end;

procedure TAthlInstanceCounter.ApplyUpdates;
begin
{  if csLoading in ComponentState then
    exit;
  if csDesigning in ComponentState then
    exit;
}  if _UpdateCount > 0 then
    exit;
  if not Active then
    exit;
  Active := False;
  Active := True;
end;

procedure TAthlInstanceCounter.BeginUpdates;
begin
  INC(_UpdateCount);
end;

procedure TAthlInstanceCounter.EndUpdates;
begin
  DEC(_UpdateCount);
  if _UpdateCount = 0 then
    ApplyUpdates;
end;

procedure TAthlInstanceCounter.RequestUpdate;
begin
  if not Active then
    exit;
  if _UpdateCount > 0 then
    exit;
  if _Thread = nil then
    exit;
  _Thread.PostGlobalRequest;
end;

//------------------------------------------------------TAthlInstanceCounterThread

constructor TAthlInstanceCounterThread.Create(Owner: TAthlInstanceCounter);
begin
  inherited Create(True);
  _Owner := Owner;
  _IntervalTime := _Owner._Interval / 1000 / 3600 / 24;
  FreeOnTerminate := True;
  Resume;
end;

procedure TAthlInstanceCounterThread.Execute;
var
  Event: TAthlInstanceEvent;
  NextBroadcast: TDateTime;
  NextSlotUpdate: TDateTime;
begin
  InitSlot;
  NextBroadcast := Now + _IntervalTime;
  NextSlotUpdate := Now + 0.5 / 3600 / 24;

  while not Terminated do
  begin
    if Now > NextBroadcast then
    begin
      PostLocalStatus(-1);

      if _LocalIndex < 2 then
        PostGlobalStatus('', -1);

      NextBroadcast := Now + _IntervalTime;

      _Owner.RemoveExpiredInfo;
    end;

    if GetInstanceEvent(Event) then
      ProcessInstanceEvent(Event)
    else
      WaitForSingleObject(_Owner._ThreadStop, 100);

    if Now > NextSlotUpdate then // Attemp to decrease LocalIndex
    begin
      UpdateSlot;
      NextSlotUpdate := Now + 0.5 / 3600 / 24;
    end;
  end;

  DoneSlot;
  SetEvent(_Owner._ThreadStopped);
end;

function TAthlInstanceCounterThread.GetInstanceEvent(var Event:
  TAthlInstanceEvent): Boolean;
var
  Size: DWORD;
  Buf: PAthlInstanceEvent;
  Count: DWORD;
  S: string;
begin
  result := False;
  Lock;
  try
    // Slot is not active
    if _Slot = INVALID_HANDLE_VALUE then
      exit;

    while True do
    begin
      // Check for new messages
      if not GetMailslotInfo(_Slot, nil, Size, nil, nil) then
        exit;

      if Size = MAILSLOT_NO_MESSAGE then
        exit;

      GetMem(Buf, Size);
      try
        if not ReadFile(_Slot, Buf^, Size, Count, nil) then
          exit;

        if Buf.Signature <> EventSignature then
          continue;
        if Count < SizeOf(Event) then
          continue;
        Event := Buf^;
        S := Event.Computer + IntToHex(Event.PID, 8) + IntToHex(Event.Id, 8);

        // Mailslot can get duplicated messages
        // Do not process duplicates twice
        with _Owner._ReceivedEvents do
        begin
          if IndexOf(S) >= 0 then
            continue;
          Add(S);
          while Count > 100 do
            Delete(0);
        end;

        Event := Buf^;
        result := True;
        exit;
      finally
        FreeMem(Buf);
      end;
    end;

  finally
    Unlock;
  end;
end;

procedure TAthlInstanceCounterThread.ProcessInstanceEvent(const Event:
  TAthlInstanceEvent);
begin
  case Event.Event of
    ieGlobalCreated: ProcessGlobalCreated(Event);
    ieGlobalDeleted: ProcessGlobalDeleted(Event);
    ieLocalRequest: ProcessLocalRequest(Event);
    ieLocalStatus: ProcessLocalStatus(Event);
    ieGlobalRequest: ProcessGlobalRequest(Event);
    ieGlobalStatus: ProcessGlobalStatus(Event);
  end;
end;

procedure TAthlInstanceCounterThread.Lock;
begin
  _Owner.Lock;
  INC(_LockCount);
  _LocalInfo := _Owner._LocalInfo;
  _GlobalInfo := _Owner._GlobalInfo;
end;

procedure TAthlInstanceCounterThread.Unlock;
begin
  DEC(_LockCount);
  if _LockCount = 0 then
  begin
    _LocalInfo := nil;
    _GlobalInfo := nil;
  end;
  _Owner.Unlock;

  if _Changed and (_LockCount = 0) then
  begin
    Synchronize(Changed);
    _Changed := False;
  end;
end;

procedure TAthlInstanceCounterThread.ProcessGlobalCreated(const Event:
  TAthlInstanceEvent);
var
  PIGI: PAthlInstanceGLobalInfo;
  SameComputer: Boolean;
  SameProcess: Boolean;
  StatusEvent: TAthlInstanceEvent;
  i: Integer;
begin
  Lock;
  try
    ProcessLocalCreated(Event);

    PIGI := FindGlobal(Event);
    if PIGI = nil then
    begin
      GetMem(PIGI, SizeOF(PIGI^));
      PIGI.Computer := Event.Computer;
      PIGI.LocalCount := 0;
      _GlobalInfo.Add(PIGI);
    end;
    INC(PIGI.LocalCount);
    _Changed := True;
    PIGI.LastRefresh := Now;

    if _LocalIndex > 1 then
      exit;
    SameComputer := Event.Computer = ComputerName;
    SameProcess := SameComputer and (Event.PID = GetCurrentProcessId);

    if SameProcess then
      exit;

    PostLocal(Event, -1);

    if not SameComputer then
    begin
      PostGlobalStatus(Event.Computer, Event.LocalIndex);
    end
    else
    begin
      StatusEvent.Signature := EventSignature;
      StatusEvent.Computer := ComputerName;
      StatusEvent.Id := LastEventId;
      StatusEvent.Event := ieGlobalStatus;
      StatusEvent.LocalIndex := Event.LocalIndex;
      StatusEvent.PID := Event.PID;

      for i := 0 to _GlobalInfo.Count - 1 do
      begin
        PIGI := _GlobalInfo[i];
        StatusEvent.InstanceCount := PIGI.LocalCount;
        PostLocal(StatusEvent, Event.LocalIndex);
      end;
    end;
  finally
    Unlock;
  end;
end;

procedure TAthlInstanceCounterThread.ProcessGlobalDeleted(const Event:
  TAthlInstanceEvent);
var
  PIGI: PAthlInstanceGLobalInfo;
begin
  Lock;
  try
    PIGI := FindGlobal(Event);
    if PIGI = nil then
      exit;

    DEC(PIGI.LocalCount);
    _Changed := True;

    PIGI.LastRefresh := Now;
    if PIGI.LocalCount <= 0 then
    begin
      _GlobalInfo.Remove(PIGI);
      FreeMem(PIGI);
    end;

    if _LocalIndex < 2 then
      PostLocal(Event, -1);

    ProcessLocalDeleted(Event);

  finally
    Unlock;
  end;
end;

procedure TAthlInstanceCounterThread.ProcessGlobalRequest(const Event:
  TAthlInstanceEvent);
begin
  Lock;
  try
    if _LocalIndex > 2 then
      exit;

    PostGlobalStatus(Event.Computer, Event.LocalIndex);

    PostLocalRequest;
  finally
    Unlock;
  end;
end;

procedure TAthlInstanceCounterThread.ProcessGlobalStatus(
  const Event: TAthlInstanceEvent);
var
  PIGI: PAthlInstanceGlobalInfo;
begin
  Lock;
  try
    PIGI := FindGlobal(Event);

    if PIGI <> nil then
    begin
      PIGI.LastRefresh := Now;
      _Changed := _Changed or (PIGI.LocalCount <> Event.InstanceCount);
      PIGI.LocalCount := Event.InstanceCount;
    end
    else
      ProcessGlobalCreated(Event);

    if _LocalIndex < 2 then
      PostLocal(Event, -1);
  finally
    Unlock;
  end;
end;

procedure TAthlInstanceCounterThread.ProcessLocalCreated(
  const Event: TAthlInstanceEvent);
var
  PILI: PAthlInstanceLocalInfo;
begin
  if Event.Computer <> ComputerName then
    exit;

  Lock;
  try
    PILI := FindLocal(Event);
    if PILI <> nil then
      exit;

    GetMem(PILI, SizeOf(PILI^));
    PILI.PID := Event.PID;
    PILI.LastRefresh := Now;
    _LocalInfo.Add(PILI);
  finally
    Unlock;
  end;
end;

procedure TAthlInstanceCounterThread.ProcessLocalDeleted(const Event:
  TAthlInstanceEvent);
var
  PILI: PAthlInstanceLocalInfo;
begin
  if Event.Computer <> ComputerName then
    exit;
  Lock;
  try
    PILI := FindLocal(Event);
    if PILI <> nil then
    begin
      _LocalInfo.Remove(PILI);
      FreeMem(PILI);
    end;
    if Event.LocalIndex < _LocalIndex then
      UpdateSlot;
  finally
    Unlock;
  end;
end;

procedure TAthlInstanceCounterThread.ProcessLocalRequest(const Event:
  TAthlInstanceEvent);
begin
  if Event.PID = GetCurrentProcessId then
    exit;

  Lock;
  try
    PostLocalStatus(Event.LocalIndex);
  finally
    Unlock;
  end;
end;

procedure TAthlInstanceCounterThread.ProcessLocalStatus(const Event:
  TAthlInstanceEvent);
var
  PILI: PAthlInstanceLocalInfo;
begin
  Lock;
  try
    PILI := FindLocal(Event);

    if PILI <> nil then
      PILI.LastRefresh := Now
    else
      ProcessLocalCreated(Event);
  finally
    Unlock;
  end;
end;

function TAthlInstanceCounterThread.FindLocal(const Event: TAthlInstanceEvent):
  PAthlInstanceLocalInfo;
var
  i: Integer;
begin
  if _LocalInfo = nil then
    raise Exception.Create('Internal error: no lock');

  for i := 0 to _LocalInfo.Count - 1 do
  begin
    result := _LocalInfo[i];
    if Event.PID <> Result.PID then
      continue;
    exit;
  end;
  result := nil;
end;

function TAthlInstanceCounterThread.FindGlobal(const Event: TAthlInstanceEvent):
  PAthlInstanceGlobalInfo;
var
  i: Integer;
begin
  if _GlobalInfo = nil then
    raise Exception.Create('Internal error: no lock');

  for i := 0 to _GlobalInfo.Count - 1 do
  begin
    result := _GlobalInfo[i];
    if Event.Computer <> result.Computer then
      continue;
    exit;
  end;
  result := nil;
end;

procedure TAthlInstanceCounterThread.DoPostEvent(const Event:
  TAthlInstanceEvent; SlotName: string);
var
  Slot: THANDLE;
  Count: DWORD;
begin
  Slot := CreateFile
    (
    PChar(SlotName),
    GENERIC_WRITE,
    FILE_SHARE_READ,
    nil,
    OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL,
    0
    );

  if Slot = INVALID_HANDLE_VALUE then
    exit;

  WriteFile(Slot, Event, SizeOf(Event), Count, nil);

  CloseHandle(Slot);
end;

procedure TAthlInstanceCounterThread.PostGlobalStatus(Computer: string;
  LocalIndex: Integer);
var
  Event: TAthlInstanceEvent;
begin
  InitEvent(Event);
  Event.Event := ieGlobalStatus;
  PostGlobal(Event, Computer, LocalIndex);
end;

procedure TAthlInstanceCounterThread.PostLocalStatus(LocalIndex: Integer);
var
  Event: TAthlInstanceEvent;
begin
  InitEvent(Event);
  Event.Event := ieLocalStatus;
  PostLocal(Event, LocalIndex);
  ProcessLocalStatus(Event);
end;

procedure TAthlInstanceCounterThread.PostGlobalRequest;
var
  Event: TAthlInstanceEvent;
begin
  InitEvent(Event);
  Event.Event := ieGlobalRequest;
  PostGlobal(Event, '', -1);
end;

procedure TAthlInstanceCounterThread.PostLocalRequest;
var
  Event: TAthlInstanceEvent;
begin
  InitEvent(Event);
  Event.Event := ieLocalRequest;
  PostLocal(Event, -1);
  ProcessLocalStatus(Event);
end;

procedure TAthlInstanceCounterThread.InitEvent(var Event: TAthlInstanceEvent);
begin
  Lock;
  try
    Event.Signature := EventSignature;
    Event.Computer := ComputerName;
    Event.Id := LastEventId;
    Event.LocalIndex := _LocalIndex;
    Event.InstanceCount := _LocalInfo.Count;
    Event.PID := GetCurrentProcessId;
  finally
    Unlock;
  end;
end;

procedure TAthlInstanceCounterThread.PostLocal(const Event: TAthlInstanceEvent;
  LocalIndex: Integer);
var
  i: Integer;
  SlotName: string;
begin
  if LocalIndex >= 0 then
  begin
    SlotName := '\\' + ComputerName + '\mailslot\' + _Owner.InstanceName + '.';
    DoPostEvent(Event, SlotName + IntToHex(LocalIndex, 3));
  end
  else
  begin
    SlotName := '\\' + ComputerName + '\mailslot\' + _Owner.InstanceName + '.';
    Lock;
    try
      for i := 0 to _LocalInfo.Count + 4 do
      begin
        if i <> _LocalIndex then
          DoPostEvent(Event, SlotName + IntToHex(i, 3));
      end;
    finally
      Unlock;
    end;
  end;
end;

procedure TAthlInstanceCounterThread.PostGlobal(const Event: TAthlInstanceEvent;
  Computer: string; LocalIndex: Integer);
var
  i: Integer;
  SlotName: string;
begin
  if Computer = '' then // Broadcast
  begin
    for i := 0 to 1 do
    begin
      SlotName := '\\*\mailslot\' + _Owner.InstanceName + '.' + IntToHex(i, 3);
      DoPostEvent(Event, SlotName);
    end;
  end
  else
  begin
    SlotName := '\\' + Computer + '\mailslot\' + _Owner.InstanceName + '.' +
      IntToHex(LocalIndex, 3);
    DoPostEvent(Event, SlotName);
  end;
end;

procedure TAthlInstanceCounterThread.InitSlot;
var
  i: Integer;
  Event: TAthlInstanceEvent;
begin
  Lock;
  try
    _LocalIndex := -1;
    for i := 0 to 100 do
      // Unlikely that more then 100 instances run on the same computer
    begin
      _SlotName := '\\.\mailslot\' + _Owner.InstanceName + '.' + IntToHex(i, 3);
      _Slot := CreateMailslot(PChar(_SlotName), 400, 0, nil);
      if _Slot = INVALID_HANDLE_VALUE then
        continue;

      // Successful initiation
      _LocalIndex := i;

      PostLocalRequest;

      InitEvent(Event);
      Event.Event := ieGlobalCreated;
      PostGlobal(Event, '', -1);

      break;
    end;
  finally
    Unlock;
  end;
end;

procedure TAthlInstanceCounterThread.DoneSlot;
var
  Event: TAthlInstanceEvent;
begin
  Lock;
  try
    if _Slot = INVALID_HANDLE_VALUE then
      exit;

    InitEvent(Event);
    Event.Event := ieGlobalDeleted;
    PostGlobal(Event, '', -1);

    CloseHandle(_Slot);
  finally
    Unlock;
  end;
end;

procedure TAthlInstanceCounterThread.UpdateSlot;
var
  i: Integer;
  Slot: THandle;
  S: string;
begin
  Lock;
  try
    for i := 0 to _LocalIndex - 1 do
    begin
      S := '\\.\mailslot\' + _Owner.InstanceName + '.' + IntToHex(i, 3);
      Slot := CreateMailslot(PChar(S), 400, 0, nil);
      if Slot = INVALID_HANDLE_VALUE then
        continue;

      CloseHandle(_Slot);
      _SlotName := S;
      _Slot := Slot;
      _LocalIndex := i;
      break;
    end;
  finally
    Unlock;
  end;
end;

procedure TAthlInstanceCounterThread.Changed;
begin
  if Assigned(_Owner._OnChange) then
    _Owner._OnChange(_Owner);
end;

end.
