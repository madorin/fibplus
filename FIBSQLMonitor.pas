{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ InterBase databases                                           }
{                                                               }
{    FIBPlus is based in part on the product                    }
{    Free IB Components, written by Gregory H. Deatz for        }
{    Hoagland, Longo, Moran, Dunst & Doukas Company.            }
{    mailto:gdeatz@hlmdd.com                                    }
{                                                               }
{    Copyright (c) 1998-2007 Devrace Ltd.                       }
{    Written by Serge Buzadzhy (buzz@devrace.com)               }
{                                                               }
{ ------------------------------------------------------------- }
{    FIBPlus home page: http://www.fibplus.com/                 }
{    FIBPlus support  : http://www.devrace.com/support/         }
{ ------------------------------------------------------------- }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}


unit FIBSQLMonitor;

interface

{$I FIBPlus.inc}
{$IFNDEF NO_MONITOR}
uses

  SysUtils, Windows, Messages, Classes, FIBQuery,ibase,
  FIBDataSet, FIBDatabase
  {$IFDEF  INC_SERVICE_SUPPORT}
  ,IB_Services
  {$ENDIF}
;



const
  WM_MIN_FIBSQL_MONITOR = WM_USER;
  WM_MAX_FIBSQL_MONITOR = WM_USER + 512;
  WM_FIBSQL_SQL_EVENT   = WM_MIN_FIBSQL_MONITOR + 1;
  CM_RELEASE            = $B000 + 33; // cut from Controls

type
  TFIBCustomSQLMonitor = class;
  TFIBTraceFlag = (tfQPrepare, tfQExecute, tfQFetch,
   tfConnect, tfTransact,tfService,tfMisc
  );
  TFIBTraceFlags = set of TFIBTraceFlag;

 { TFIBSQLMonitor }
  TSQLEvent = procedure(EventText: String; EventTime : TDateTime) of object;

  TFIBCustomSQLMonitor = class(TComponent)
  private
    FHWnd: HWND;
    FOnSQLEvent: TSQLEvent;
    FTraceFlags: TFIBTraceFlags;
    FActive: Boolean;
    procedure MonitorWndProc(var Message : TMessage);
    procedure SetActive(const Value: Boolean);
    procedure SetTraceFlags(aTraceFlags:TFIBTraceFlags);
  protected
    property OnSQL: TSQLEvent read FOnSQLEvent write FOnSQLEvent;
    property TraceFlags: TFIBTraceFlags read FTraceFlags write SetTraceFlags;
    property Active    : Boolean read FActive write SetActive default true;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure  Release;
    property   Handle : HWND read FHwnd;    
  end;

  TFIBSQLMonitor = class(TFIBCustomSQLMonitor)
  published
    property OnSQL;
    property TraceFlags;
    property Active;
  end;

  TSavePointOperation=(soSet,soRollBack,soRelease);

  { TFIBSQLMonitorHook }
  TFIBSQLMonitorHook = class(TObject)
  private
    FActive: Boolean;
    vEventsCreated : Boolean;
    procedure CreateEvents;
  protected
    procedure WriteSQLData(const Text: String; DataType: TFIBTraceFlag);
  public
    constructor Create;
    destructor Destroy; override;
    procedure TerminateWriteThread;
    function  SQLString(k:integer):Byte;     
    procedure RegisterMonitor(SQLMonitor : TFIBCustomSQLMonitor);
    procedure UnregisterMonitor(SQLMonitor : TFIBCustomSQLMonitor);
    procedure ReleaseMonitor(Arg : TFIBCustomSQLMonitor);
    procedure SQLPrepare(qry: TFIBQuery); virtual;
    procedure SQLExecute(qry: TFIBQuery; const AdditionalMessage:string ); virtual;
    procedure SQLFetch(qry: TFIBQuery); virtual;
    procedure DBConnect(db: TFIBDatabase); virtual;
    procedure DBDisconnect(db: TFIBDatabase); virtual;
    procedure TRStart(tr: TFIBTransaction); virtual;
    procedure TRCommit(tr: TFIBTransaction); virtual;
    procedure TRSavepoint(tr: TFIBTransaction; const SavePointName:string;
     Operation:TSavePointOperation); virtual;
    procedure TRCommitRetaining(tr: TFIBTransaction); virtual;
    procedure TRRollback(tr: TFIBTransaction); virtual;
    procedure TRRollbackRetaining(tr: TFIBTransaction); virtual;
   {$IFDEF  INC_SERVICE_SUPPORT}
    procedure ServiceAttach(service: TpFIBCustomService); virtual;
    procedure ServiceDetach(service: TpFIBCustomService); virtual;
    procedure ServiceQuery(service: TpFIBCustomService); virtual;
    procedure ServiceStart(service: TpFIBCustomService); virtual;
   {$ENDIF}
    procedure SendMisc(Msg : String);
    function  GetEnabled: Boolean;
    function  GetMonitorCount : Integer;
    procedure SetEnabled(const Value: Boolean);
    property Enabled : Boolean read GetEnabled write SetEnabled default true;
  end;


function  MonitorHook: TFIBSQLMonitorHook;
procedure EnableMonitoring;
procedure DisableMonitoring;
function  MonitoringEnabled: Boolean;
{$ENDIF}
implementation

{$IFNDEF NO_MONITOR}
uses
  {$IFNDEF D6+}
   Forms,
  {$ENDIF}


{$IFDEF D_XE3}
  System.Types, // for inline funcs
{$ENDIF}
  fib, StdFuncs,StrUtil;

type

  TFIBTraceObject = Class(TObject)
  private
    FDataType : TFIBTraceFlag;
    FMsg : String;
    FTimeStamp : TDateTime;
    FIsUnicodeVersion:boolean;
  public
    constructor Create(const Msg : String; DataType : TFIBTraceFlag);
  end;

  TReleaseObject = Class(TObject)
  private
    FHandle : THandle;
  public
    constructor Create(Handle : THandle);
  end;

  TMonitorWriterThread = class(TThread)
  private
    StopExec:boolean;
    FMonitorMsgs : TList;
  protected
    procedure Lock;
    Procedure Unlock;
    procedure BeginWrite;
    procedure EndWrite;
    procedure Execute; override;
    procedure WriteToBuffer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure WriteSQLData(const Msg : String; DataType : TFIBTraceFlag);
    procedure ReleaseMonitor(HWnd : THandle);
  end;

  TMonitorReaderThread = class(TThread)
  private
    st : TFIBTraceObject;
    FMonitors : TList;
  protected
    procedure BeginRead;
    procedure EndRead;
    procedure ReadSQLData;
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;
    procedure  AddMonitor(Arg : TFIBCustomSQLMonitor);
    procedure  RemoveMonitor(Arg : TFIBCustomSQLMonitor);

  end;

const
  MonitorHookNames: array[0..5] of String = (
    'FIB.SQL.MONITOR.Mutex',
    'FIB.SQL.MONITOR.SharedMem',
    'FIB.SQL.MONITOR.WriteEvent',
    'FIB.SQL.MONITOR.WriteFinishedEvent',
    'FIB.SQL.MONITOR.ReadEvent',
    'FIB.SQL.MONITOR.ReadFinishedEvent'
  );
  cMonitorHookSize = 2048;
  cMaxBufferSize = cMonitorHookSize - (9 * SizeOf(Integer)) - SizeOf(TDateTime)
  - 2*SizeOf(Byte)
  ;
  cDefaultTimeout = 1000; // 1 seconds

var
  FSharedBuffer,
  FWriteLock,
  FWriteEvent,
  FWriteFinishedEvent,
  FReadEvent,
  FReadFinishedEvent : THandle;
  FBuffer : PAnsiChar;
  FMonitorCount,
  FReaderCount,
  FTraceDataType,
  FQPrepareReaderCount,
  FQExecuteReaderCount,
  FQFetchReaderCount,
  FConnectReaderCount,
  FTransactReaderCount,
  FBufferSize : PInteger;
  FTimeStamp  : PDateTime;
  FIsUnicodeVersion : PBoolean;
  FReserved  : PByte;

  FFIBWriterThread : TMonitorWriterThread;
  FFIBReaderThread : TMonitorReaderThread;
  _MonitorHook: TFIBSQLMonitorHook;
  bDone: Boolean;
  CS : TRTLCriticalSection;
  bEnabledMonitoring:boolean;
{ TFIBCustomSQLMonitor }


{$IFDEF D6+}
{$WARN SYMBOL_DEPRECATED OFF}
{$ENDIF}
constructor TFIBCustomSQLMonitor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FActive := true;
  if not (csDesigning in ComponentState) then
  begin
    FHWnd := AllocateHWnd(MonitorWndProc);
    MonitorHook.RegisterMonitor(self);
  end;
  TraceFlags := [tfqPrepare .. tfTransact];
end;


destructor TFIBCustomSQLMonitor.Destroy;
begin
  if not (csDesigning in ComponentState) then
  begin
   if (tfQPrepare in TraceFlags)   then
    InterlockedDecrement(FQPrepareReaderCount^);
   if (tfQExecute in TraceFlags)   then
    InterlockedDecrement(FQExecuteReaderCount^);
   if (tfQFetch in TraceFlags)     then
    InterlockedDecrement(FQFetchReaderCount^);

   if (tfConnect in TraceFlags)  then
    InterlockedDecrement(FConnectReaderCount^);
   if (tfTransact in TraceFlags) then
    InterlockedDecrement(FTransactReaderCount^);

   if FActive then
      MonitorHook.UnregisterMonitor(self);
    DeallocateHwnd(FHWnd);
  end;
  inherited Destroy;
end;
{$IFDEF D6+}
 {$WARN SYMBOL_DEPRECATED ON}
{$ENDIF}



{$IFDEF D2009+}
  {$WARN SYMBOL_DEPRECATED OFF}
{$ENDIF}  
procedure TFIBCustomSQLMonitor.MonitorWndProc(var Message: TMessage);
var
  st : TFIBTraceObject;
begin
  case Message.Msg of
    WM_FIBSQL_SQL_EVENT:
    begin
      st := TFIBTraceObject(Message.LParam);
      if (Assigned(FOnSQLEvent)) and
         (st.FDataType in FTraceFlags) then
      begin
       if st.FIsUnicodeVersion then
       begin
        FOnSQLEvent(UTF8Decode(st.FMsg) , st.FTimeStamp);
       end
       else
        FOnSQLEvent(st.FMsg, st.FTimeStamp);
      end;
      st.Free;
    end;
    CM_RELEASE :
      Free;
  else
      Message.Result := DefWindowProc(FHWnd, Message.Msg, Message.WParam, Message.LParam);
  end;
end;


procedure TFIBCustomSQLMonitor.Release;
begin
  MonitorHook.ReleaseMonitor(self);
end;

procedure TFIBCustomSQLMonitor.SetActive(const Value: Boolean);
begin
  if Value <> FActive then
  begin
    FActive := Value;
    if not (csDesigning in ComponentState) then
      if FActive then
        Monitorhook.RegisterMonitor(self)
      else
        MonitorHook.UnregisterMonitor(self);
  end;
end;

procedure TFIBCustomSQLMonitor.SetTraceFlags(aTraceFlags:TFIBTraceFlags);
begin
 if not (csDesigning in ComponentState) then
 begin
  if (tfQPrepare in TraceFlags) and not (tfQPrepare in aTraceFlags)
  then
   InterlockedDecrement(FQPrepareReaderCount^)
  else
  if (not (tfQPrepare in TraceFlags)) and (tfQPrepare in aTraceFlags)
  then
   InterlockedIncrement(FQPrepareReaderCount^);

  if (tfQExecute in TraceFlags) and not (tfQExecute in aTraceFlags)
  then
   InterlockedDecrement(FQExecuteReaderCount^)
  else
  if (not (tfQExecute in TraceFlags)) and (tfQExecute in aTraceFlags)
  then
   InterlockedIncrement(FQExecuteReaderCount^);

  if (tfQFetch in TraceFlags) and not (tfQFetch in aTraceFlags)
  then
   InterlockedDecrement(FQFetchReaderCount^)
  else
  if (not (tfQFetch in TraceFlags)) and (tfQFetch in aTraceFlags)
  then
   InterlockedIncrement(FQFetchReaderCount^);

  if (tfConnect in TraceFlags) and not (tfConnect in aTraceFlags)
  then
   InterlockedDecrement(FConnectReaderCount^)
  else
  if (not (tfConnect in TraceFlags)) and (tfConnect in aTraceFlags)
  then
   InterlockedIncrement(FConnectReaderCount^);

  if (tfTransact in TraceFlags) and not (tfTransact in aTraceFlags)
  then
   InterlockedDecrement(FTransactReaderCount^)
  else
  if (not (tfTransact in TraceFlags)) and (tfTransact in aTraceFlags)
  then
   InterlockedIncrement(FTransactReaderCount^);
 end;
 fTraceFlags:=aTraceFlags
end;

{ TFIBSQLMonitorHook }

constructor TFIBSQLMonitorHook.Create;
begin
  inherited Create;
  vEventsCreated := false;

  FActive := true;
  if not vEventsCreated then
  try
    CreateEvents;
  except
    Enabled := false;
    Exit;
  end;
end;

procedure TFIBSQLMonitorHook.CreateEvents;
var
  Sa : TSecurityAttributes;
  Sd : TSecurityDescriptor;
  MapError: Integer;

{$IFDEF VER100}
const
  SECURITY_DESCRIPTOR_REVISION = 1;
{$ENDIF}

  function OpenLocalEvent(Idx: Integer): THandle;
  begin
    Result := OpenEvent(EVENT_ALL_ACCESS, true, PChar(MonitorHookNames[Idx]));
    if Result = 0 then
      FIBError(feCannotCreateSharedResource, [GetLastError]);
  end;

  function CreateLocalEvent(Idx: Integer; InitialState: Boolean): THandle;
  begin
    Result := CreateEvent(@sa, true, InitialState, PChar(MonitorHookNames[Idx]));
    if Result = 0 then
      FIBError(feCannotCreateSharedResource, [GetLastError]);
  end;

begin
  InitializeSecurityDescriptor(@Sd,SECURITY_DESCRIPTOR_REVISION);
  SetSecurityDescriptorDacl(@Sd,true,nil,false);
  Sa.nLength := SizeOf(Sa);
  Sa.lpSecurityDescriptor := @Sd;
  Sa.bInheritHandle := true;

  FSharedBuffer := CreateFileMapping(INVALID_HANDLE_VALUE, @sa, PAGE_READWRITE,
                       0, cMonitorHookSize, PChar(MonitorHookNames[1]));

  MapError:=GetLastError;
  if  MapError= ERROR_ALREADY_EXISTS then
  begin
    FSharedBuffer := OpenFileMapping(FILE_MAP_ALL_ACCESS, false, PChar(MonitorHookNames[1]));
    if (FSharedBuffer = 0) then
      FIBError(feCannotCreateSharedResource, [GetLastError]);

  end
  else
  begin
    FWriteLock := CreateMutex(@sa, False, PChar(MonitorHookNames[0]));
    FWriteEvent := CreateLocalEvent(2, False);
    FWriteFinishedEvent := CreateLocalEvent(3, True);
    FReadEvent := CreateLocalEvent(4, False);
    FReadFinishedEvent := CreateLocalEvent(5, False);
  end;
  FBuffer := MapViewOfFile(FSharedBuffer, FILE_MAP_ALL_ACCESS, 0, 0, 0);
  if FBuffer = nil then
      FIBError(feCannotCreateSharedResource, [GetLastError]);

  FMonitorCount := PInteger(FBuffer + cMonitorHookSize - SizeOf(Integer));
  FReaderCount  := PInteger(PAnsiChar(FMonitorCount)      -   SizeOf(Integer));
  FTraceDataType:= PInteger(PAnsiChar(FMonitorCount)      - 2*SizeOf(Integer));
  FBufferSize   := PInteger(PAnsiChar(FMonitorCount)      - 3*SizeOf(Integer));
  FQPrepareReaderCount:=PInteger(PAnsiChar(FMonitorCount) - 4*SizeOf(Integer));
  FQExecuteReaderCount:=PInteger(PAnsiChar(FMonitorCount) - 5*SizeOf(Integer));
  FQFetchReaderCount  :=PInteger(PAnsiChar(FMonitorCount) - 6*SizeOf(Integer));
  FConnectReaderCount :=PInteger(PAnsiChar(FMonitorCount) - 7*SizeOf(Integer));
  FTransactReaderCount:=PInteger(PAnsiChar(FMonitorCount) - 8*SizeOf(Integer));
  FTimeStamp    := PDateTime(PAnsiChar(FTransactReaderCount)- SizeOf(TDateTime));
  FIsUnicodeVersion := PBoolean(PAnsiChar(FTimeStamp)- SizeOf(Byte));
  FReserved    := PByte(PAnsiChar(FIsUnicodeVersion)- SizeOf(Byte));

  if  MapError= ERROR_ALREADY_EXISTS then
  begin
    FWriteLock  := OpenMutex(MUTEX_ALL_ACCESS, False, PChar(MonitorHookNames[0]));
    FWriteEvent := OpenLocalEvent(2);
    FWriteFinishedEvent := OpenLocalEvent(3);
    FReadEvent  := OpenLocalEvent(4);
    FReadFinishedEvent  := OpenLocalEvent(5);
  end
  else
  begin
    FMonitorCount^       :=0;
    FReaderCount^        :=0;
    FBufferSize^         :=0;
    FQPrepareReaderCount^:=0;
    FQExecuteReaderCount^:=0;
    FQFetchReaderCount^  :=0;
    FConnectReaderCount^ :=0;
    FTransactReaderCount^:=0;
  end;

  if FMonitorCount^ < 0 then
    FMonitorCount^ := 0;
  if FReaderCount^ < 0 then
    FReaderCount^ := 0;
  vEventsCreated := true;
end;

function  TFIBSQLMonitorHook.SQLString(k:integer):Byte;
begin
  Result:=127
end;

procedure TFIBSQLMonitorHook.DBConnect(db: TFIBDatabase);
var
  st : String;
begin
  if FActive and  bEnabledMonitoring and (GetMonitorCount>0)
  and (FConnectReaderCount^>0)
  then
  begin
    st := db.Name + ': [Connect]'; {do not localize}
    WriteSQLData(st, tfConnect);
  end;
end;

procedure TFIBSQLMonitorHook.DBDisconnect(db: TFIBDatabase);
var
  st: String;
begin
  if FActive and  bEnabledMonitoring and (GetMonitorCount>0)
  and (FConnectReaderCount^>0)
  then
  begin
    st := db.Name + ': [Disconnect]'; {do not localize}
    WriteSQLData(st, tfConnect);
  end;
end;

destructor TFIBSQLMonitorHook.Destroy;
begin
  if vEventsCreated then
  begin
    UnmapViewOfFile(FBuffer);
    CloseHandle(FSharedBuffer);
    CloseHandle(FWriteEvent);
    CloseHandle(FWriteFinishedEvent);
    CloseHandle(FReadEvent);
    CloseHandle(FReadFinishedEvent);
    CloseHandle(FWriteLock);
  end;
  inherited Destroy;
end;

function TFIBSQLMonitorHook.GetEnabled: Boolean;
begin
  Result := FActive;
end;

function TFIBSQLMonitorHook.GetMonitorCount: Integer;
begin
  if FMonitorCount=nil
  then
   Result:=0
  else
  Result := FMonitorCount^;
end;

procedure TFIBSQLMonitorHook.RegisterMonitor(SQLMonitor: TFIBCustomSQLMonitor);
begin
  if not vEventsCreated then
  try
    CreateEvents;
  except
    SQLMonitor.Active := false;
  end;
  if not Assigned(FFIBReaderThread) then
    FFIBReaderThread := TMonitorReaderThread.Create;
  FFIBReaderThread.AddMonitor(SQLMonitor);
end;

procedure TFIBSQLMonitorHook.ReleaseMonitor(Arg: TFIBCustomSQLMonitor);
begin
  FFIBWriterThread.ReleaseMonitor(Arg.FHWnd);
end;

procedure TFIBSQLMonitorHook.SendMisc(Msg: String);
begin
  if FActive then
    WriteSQLData(Msg, tfMisc);
end;

{$IFDEF  INC_SERVICE_SUPPORT}
procedure TFIBSQLMonitorHook.ServiceAttach(service: TpFIBCustomService);
var
  st: String;
begin
  if FActive and  bEnabledMonitoring and (GetMonitorCount>0)
  then
  begin
    st := service.Name + ': [Attach]'; {do not localize}
    WriteSQLData(st, tfService);
  end;
end;

procedure TFIBSQLMonitorHook.ServiceDetach(service: TpFIBCustomService);
var
  st: String;
begin
  if FActive and  bEnabledMonitoring and (GetMonitorCount>0)
  then
  begin
    st := service.Name + ': [Detach]'; {do not localize}
    WriteSQLData(st, tfService);
  end;
end;

procedure TFIBSQLMonitorHook.ServiceQuery(service: TpFIBCustomService);
var
  st: String;
begin
  if FActive and  bEnabledMonitoring and (GetMonitorCount>0)
  then
  begin
    st := service.Name + ': [Query]'; {do not localize}
    WriteSQLData(st, tfService);
  end;
end;

procedure TFIBSQLMonitorHook.ServiceStart(service: TpFIBCustomService);
var
  st: String;
begin
  if FActive and  bEnabledMonitoring and (GetMonitorCount>0)
  then
  begin
    st := service.Name + ': [Start]'; {do not localize}
    WriteSQLData(st, tfService);
  end;
end;

{$ENDIF}

procedure TFIBSQLMonitorHook.SetEnabled(const Value: Boolean);
begin
  if FActive <> Value then
    FActive := Value;
  if (not FActive) and (Assigned(FFIBWriterThread)) then
  begin
    FFIBWriterThread.Terminate;
    FFIBWriterThread.WaitFor;
    FFIBWriterThread.Free;
    FFIBWriterThread:=nil;
  end;
end;


procedure TFIBSQLMonitorHook.SQLExecute(qry: TFIBQuery;const AdditionalMessage:string );
var
  st: Ansistring;
  i: Integer;
  Q: TISC_QUAD;
begin
  if FActive and  bEnabledMonitoring  and (GetMonitorCount>0)
  and (FQExecuteReaderCount^>0)
  then
  begin
    if qry.Owner is TFIBCustomDataSet then
      st := TFIBCustomDataSet(qry.Owner).Name +'.'+qry.Name
    else
      st := qry.Name;
    st := st + ': [Execute] ' + UTF8Encode(qry.ReadySQLText(False)); {do not localize}

   if qry.Params.Count > 0 then
   begin
    for i := 0 to qry.Params.Count - 1 do
    with qry.Params[i] do
    begin
        st := st + CRLF + '  ' + Name + ' = ';
        try
          if IsNull then
            st := st + '<NULL>' {do not localize}
          else
           if (SQLType = (SQL_TEXT)) or (SQLType =(SQL_VARYING)) then
            st := st +''''+ UTF8Encode(AsString)+''''
           else
           if ((SQLType and (not 1))= SQL_BLOB) then
           begin
            Q:=AsQuad;
            st := st + '<BLOB> (BLOB_ID='+IntToStr(Q.gds_quad_high)+','+IntToStr(Q.gds_quad_low)+')'
           end
           else
           if ((SQLType and (not 1)) =(SQL_ARRAY)) then
            st := st + '<ARRAY>'
           else
             st := st + AsString;
        except
          st := st + '<Can''t print value>';
        end;
    end;
   end;
    if qry.SQLType in [SQLInsert, SQLUpdate, SQLDelete] then
      st:=st + CRLF + 'Rows Affected:  ' +IntToStr(qry.RowsAffected);
    if Length(AdditionalMessage )>0 then
     st:=st +CRLF +AdditionalMessage;
    st:=st +CRLF +'Execute tick count '+ IntToStr(qry.CallTime);
//    ast:=Utf8Encode( st);
    WriteSQLData( st, tfQExecute);
//    WriteSQLData(st, tfQExecute);
  end;
end;

procedure TFIBSQLMonitorHook.SQLFetch(qry: TFIBQuery);
var
  st: AnsiString;
  i:integer;  
begin
  if FActive and  bEnabledMonitoring and (GetMonitorCount>0)
  and (FQFetchReaderCount^>0)
  then
  begin
    if qry.Owner is TFIBCustomDataSet then
      st := TFIBCustomDataSet(qry.Owner).Name
    else
      st := qry.Name;
    st := st + ': [Fetch] ' + UTF8Encode(qry.ReadySQLText(False)); {do not localize}
    for i:=0 to Pred(qry.Current.Count) do
    begin
     st:=st+qry.Fields[i].Name+' = ';
     if qry.Fields[i].IsNull then
       st := st + 'NULL'
     else
       st := st + UTF8Encode(qry.Fields[i].asWideString);
     st:=st+CRLF;
    end;
    st:=CRLF+st;

    if (qry.Eof) then
      st := st + CRLF + '  End of file reached';
    WriteSQLData(st, tfQFetch);
  end;
end;

procedure TFIBSQLMonitorHook.SQLPrepare(qry: TFIBQuery);
var
  st: AnsiString;
begin
  if FActive and  bEnabledMonitoring and (GetMonitorCount>0)
  and (FQPrepareReaderCount^>0)
  then
  begin
    if qry.Owner is TFIBCustomDataSet then
      st := TFIBCustomDataSet(qry.Owner).Name
    else
      st := qry.Name;
    st := st + ': [Prepare] ' + UTF8Encode(qry.ReadySQLText(False)) + CRLF; {do not localize}
    try
      st := st + '  Plan: ' + qry.Plan; {do not localize}
    except
      st := st + '  Plan: Can''t retrieve plan ';
    end;
    WriteSQLData(st, tfQPrepare);
  end;
end;

procedure TFIBSQLMonitorHook.TRCommit(tr: TFIBTransaction);
var
  st: String;
begin
  if FActive and  bEnabledMonitoring  and (GetMonitorCount>0)
  and (FTransactReaderCount^>0)
  then
  begin
    if Assigned(tr.DefaultDatabase)
    then
    begin
      st := tr.Name + ': [Commit (Hard commit)]('+
       IntToStr(tr.TransactionID)+')';
      WriteSQLData(st, tfTransact);
    end;
  end;
end;

procedure TFIBSQLMonitorHook.TRSavepoint(tr: TFIBTransaction;
 const SavePointName:string; Operation:TSavePointOperation);
var
  st: String;
begin
  if FActive and  bEnabledMonitoring  and (GetMonitorCount>0)
  and (FTransactReaderCount^>0)
  then
  begin
    if Assigned(tr.DefaultDatabase)
    then
    begin
      st:=tr.Name +': Transaction('+IntToStr(tr.TransactionID)+') -';
      case Operation of
       soSet:
        st := st+' [SetSavePoint("'+SavePointName+'")]';
       soRollBack:
        st := st+' [RollBackToSavePoint("'+SavePointName+'")]';
       soRelease:
        st := st+' [ReleaseSavePoint("'+SavePointName+'")]';
      end;
      WriteSQLData(st, tfTransact);
    end;
  end;
end;

procedure TFIBSQLMonitorHook.TRCommitRetaining(tr: TFIBTransaction);
var
  st: String;
begin
  if FActive and  bEnabledMonitoring and (GetMonitorCount>0)
   and (FTransactReaderCount^>0)
  then
  begin
    if Assigned(tr.DefaultDatabase)
    then
    begin
      st := tr.Name + ': [Commit retaining (Soft commit)]('+
       IntToStr(tr.TransactionID)+')';
      WriteSQLData(st, tfTransact);
    end;
  end;
end;

procedure TFIBSQLMonitorHook.TRRollback(tr: TFIBTransaction);
var
  st: String;
begin
  if FActive and  bEnabledMonitoring and (GetMonitorCount>0)
   and (FTransactReaderCount^>0)
  then
  begin
    if Assigned(tr.DefaultDatabase)
    then
    begin
      st := tr.Name + ': [Rollback]('+
       IntToStr(tr.TransactionID)+')';
      WriteSQLData(st, tfTransact);
    end;
  end;
end;

procedure TFIBSQLMonitorHook.TRRollbackRetaining(tr: TFIBTransaction);
var
  st: String;
begin
  if FActive and  bEnabledMonitoring  and (GetMonitorCount>0)
   and (FTransactReaderCount^>0)
  then
  begin
    if Assigned(tr.DefaultDatabase)
    then
    begin
      st := tr.Name + ': [Rollback retaining (Soft rollback)]('+
       IntToStr(tr.TransactionID)+')';
      WriteSQLData(st, tfTransact);
    end;
  end;
end;

procedure TFIBSQLMonitorHook.TRStart(tr: TFIBTransaction);
var
  st: String;
begin
  if FActive and  bEnabledMonitoring and  bEnabledMonitoring and (GetMonitorCount>0)
   and (FTransactReaderCount^>0)
  then
  begin
    if Assigned(tr.DefaultDatabase)
    then
    begin
      st := tr.Name + ': [Start transaction]('+
       IntToStr(tr.TransactionID)+')';
      WriteSQLData(st, tfTransact);
    end;
  end;
end;

procedure TFIBSQLMonitorHook.UnregisterMonitor(SQLMonitor: TFIBCustomSQLMonitor);
begin
  FFIBReaderThread.RemoveMonitor(SQLMonitor);
  if FFIBReaderThread.FMonitors.Count = 0 then
  begin
    FFIBReaderThread.Terminate;
    if not Assigned(FFIBWriterThread) then
    begin
      FFIBWriterThread := TMonitorWriterThread.Create;
    end;
    FFIBWriterThread.WriteSQLData(' ', tfMisc);
    FFIBReaderThread.WaitFor;
    FFIBReaderThread.Free;
    FFIBReaderThread:=nil;
  end;
end;

procedure TFIBSQLMonitorHook.WriteSQLData(const Text: String;
  DataType: TFIBTraceFlag);
var
 vText:string;
begin
  if not vEventsCreated then
  try
    CreateEvents;
  except
    Enabled := false;
    Exit;
  end;
  vText := CRLF + '[Application: ' +  ExtractFileName(ParamStr(0))+ ']' + CRLF + Text; {do not localize}
  if not Assigned(FFIBWriterThread) then
    FFIBWriterThread := TMonitorWriterThread.Create;
  FFIBWriterThread.WriteSQLData(vText, DataType);
end;


procedure TFIBSQLMonitorHook.TerminateWriteThread;
begin
  if Assigned(FFIBWriterThread) then
  begin
   FFIBWriterThread.Free;
   FFIBWriterThread:=nil
  end;
end;

{ TMonitorWriterThread }

constructor TMonitorWriterThread.Create;

begin
  StopExec:=False;
  FMonitorMsgs := TList.Create;
  inherited Create(False);
{  if FMonitorCount^ <> 0 then
   Resume;}
  {$IFNDEF D6+}
  if FMonitorCount^ = 0 then
   Suspend;
  {$ENDIF}
end;

destructor TMonitorWriterThread.Destroy;
var Msg:TObject;
begin
  {$IFNDEF D6+}
   Resume;
  {$ENDIF}
  inherited Destroy;  
  if FMonitorMsgs.Count>0 then
  begin
   Msg:=FMonitorMsgs[0];
   FMonitorMsgs.Delete(0);
   Msg.Free;
  end;
  FMonitorMsgs.Free;


end;

procedure TMonitorWriterThread.Execute;
begin
  while  (((not Terminated) and (not bDone)) or
        (FMonitorMsgs.Count <> 0)) and not StopExec do
  begin
    if (FMonitorCount^ = 0) then
    begin
     while FMonitorMsgs.Count <> 0 do
     begin
       TObject(FMonitorMsgs[0]).Free;
       FMonitorMsgs.Delete(0);
//       FMonitorMsgs.Remove(FMonitorMsgs[0]);
     end;

     {$IFNDEF D6+}
      Suspend;
     {$ELSE}
       Sleep(50)
     {$ENDIF}
    end
    else
      if FMonitorMsgs.Count <> 0 then
      begin
        if (TObject(FMonitorMsgs.Items[0]) is TReleaseObject)
//or (not bEnabledMonitoring )         
        then
          PostMessage(TReleaseObject(FMonitorMsgs.Items[0]).FHandle, CM_RELEASE, 0, 0)
        else
        begin
          if bEnabledMonitoring  then
           WriteToBuffer
          else
          begin
//            WriteToBuffer;

            BeginWrite;
            TFIBTraceObject(FMonitorMsgs[0]).Free;
            FMonitorMsgs.Delete(0);
            EndWrite;
          end;
        end;
      end
      else
     {$IFNDEF D6+}
        Suspend
     {$ELSE}
       Sleep(50)
     {$ENDIF}
  end;
end;

procedure TMonitorWriterThread.Lock;
begin
  WaitForSingleObject(FWriteLock, INFINITE);
end;

procedure TMonitorWriterThread.Unlock;
begin
  ReleaseMutex(FWriteLock);
end;

procedure TMonitorWriterThread.WriteSQLData(const Msg : String; DataType: TFIBTraceFlag);
begin
  if (FMonitorCount^ <> 0)   then
  begin
    FMonitorMsgs.Add(TFIBTraceObject.Create(Msg, DataType));
   {$IFNDEF D6+}
    Resume;
   {$ENDIF}
  end
  else
  begin
   FreeAndNil(FFIBWriterThread)
  end;
end;

procedure TMonitorWriterThread.BeginWrite;
begin
  Lock;
end;

procedure TMonitorWriterThread.EndWrite;
begin
  {
   * 1. Wait to end the write until all registered readers have
   *    started to wait for a write event
   * 2. Block all of those waiting for the write to finish.
   * 3. Block all of those waiting for all readers to finish.
   * 4. Unblock all readers waiting for a write event.
   * 5. Wait until all readers have finished reading.
   * 6. Now, block all those waiting for a write event.
   * 7. Unblock all readers waiting for a write to be finished.
   * 8. Unlock the mutex.
   }
  while WaitForSingleObject(FReadEvent, cDefaultTimeout) = WAIT_TIMEOUT do
  begin
    if FMonitorCount^ > 0 then
      InterlockedDecrement(FMonitorCount^);
    if (FReaderCount^ = FMonitorCount^ - 1) or (FMonitorCount^ = 0) then
      SetEvent(FReadEvent);
  end;
  ResetEvent(FWriteFinishedEvent);
  ResetEvent(FReadFinishedEvent);
  SetEvent(FWriteEvent); { Let all readers pass through. }
  while WaitForSingleObject(FReadFinishedEvent, cDefaultTimeout) = WAIT_TIMEOUT do
    if (FReaderCount^ = 0) or (InterlockedDecrement(FReaderCount^) = 0) then
      SetEvent(FReadFinishedEvent);
  ResetEvent(FWriteEvent);
  SetEvent(FWriteFinishedEvent);
  Unlock;
end;

procedure TMonitorWriterThread.WriteToBuffer;
var
  i, len: Integer;
  Text : AnsiString;
  ps   :PString;
begin
  Lock;
  try
    if FMonitorCount^ = 0 then
       FMonitorMsgs.Remove(FMonitorMsgs[0])
    else
    begin
      ps    :=@TFIBTraceObject(FMonitorMsgs[0]).FMsg;
      Text  := '';
      for i := 1 to length(ps^) do
      begin
       if ord(ps^[i]) in [0..8,$B,$C,$E..31] then
        Text := Text + '#$'+IntToHex(ord(ps^[i]),2)
       else
        Text := Text + ps^[i];
      end;
      i := 1;
      len := Length(Text);
      while (len > 0) do
      begin
        BeginWrite;
        try
          FTraceDataType^ := Integer(TFIBTraceObject(FMonitorMsgs[0]).FDataType);
          FTimeStamp^ := TFIBTraceObject(FMonitorMsgs[0]).FTimeStamp;
          FIsUnicodeVersion^:=True;
          FBufferSize^ := Min(len, cMaxBufferSize);
          Move(Text[i], FBuffer[0], FBufferSize^);
          Inc(i, cMaxBufferSize);
          Dec(len, cMaxBufferSize);
        finally
          EndWrite;
        end;
      end;
    end;
    if FMonitorMsgs.Count>0 then
    begin
      TFIBTraceObject(FMonitorMsgs[0]).Free;
      FMonitorMsgs.Delete(0);
    end;
  finally
    Unlock;
  end;
end;


procedure TMonitorWriterThread.ReleaseMonitor(HWnd: THandle);
begin
  FMonitorMsgs.Add(TReleaseObject.Create(HWnd));
end;

{ TFIBTraceObject }

constructor TFIBTraceObject.Create(const Msg : string; DataType: TFIBTraceFlag);
begin
  FMsg := Msg;
  FDataType := DataType;
  FTimeStamp := Now;
end;

{TReleaseObject}

constructor TReleaseObject.Create(Handle: THandle);
begin
  FHandle := Handle;
end;

{ReaderThread}

procedure TMonitorReaderThread.AddMonitor(Arg: TFIBCustomSQLMonitor);
begin
  EnterCriticalSection(CS);
  if FMonitors.IndexOf(Arg) < 0 then
    FMonitors.Add(Arg);
  LeaveCriticalSection(CS);
end;

procedure TMonitorReaderThread.BeginRead;
begin
  {
   * 1. Wait for the "previous" write event to complete.
   * 2. Increment the number of readers.
   * 3. if the reader count is the number of interested readers, then
   *    inform the system that all readers are ready.
   * 4. Finally, wait for the FWriteEvent to signal.
   }
  WaitForSingleObject(FWriteFinishedEvent, INFINITE);
  InterlockedIncrement(FReaderCount^);
  if FReaderCount^ = FMonitorCount^ then
    SetEvent(FReadEvent);
  WaitForSingleObject(FWriteEvent, INFINITE);
end;

constructor TMonitorReaderThread.Create;
begin
  inherited Create(true);
  st := TFIBTraceObject.Create('', tfMisc);
  FMonitors := TList.Create;
  InterlockedIncrement(FMonitorCount^);
  Resume;
end;

destructor TMonitorReaderThread.Destroy;
begin
  inherited Destroy;
  if FMonitorCount^ > 0 then
    InterlockedDecrement(FMonitorCount^);
  FMonitors.Free;
  st.Free;

end;

procedure TMonitorReaderThread.EndRead;
begin
  if InterlockedDecrement(FReaderCount^) = 0 then
  begin
    ResetEvent(FReadEvent);
    SetEvent(FReadFinishedEvent);
  end;
end;


procedure TMonitorReaderThread.Execute;
var
  i : Integer;
  FTemp : TFIBTraceObject;
begin
  while (not Terminated) and (not bDone) do
  begin
    ReadSQLData;
    if not IsBlank(st.FMsg) then
      for i := 0 to FMonitors.Count - 1 do
      begin
        FTemp := TFIBTraceObject.Create(st.FMsg,  st.FDataType);
        FTemp.FIsUnicodeVersion:=st.FIsUnicodeVersion;
        PostMessage(TFIBCustomSQLMonitor(FMonitors[i]).Handle,
          WM_FIBSQL_SQL_EVENT,  0, LPARAM(FTemp)
        );
      end;
  end;
end;

procedure TMonitorReaderThread.ReadSQLData;
begin
  st.FMsg := '';
  BeginRead;
  if not bDone then
  try
    SetString(st.FMsg, PAnsiChar(FBuffer), FBufferSize^);
    st.FDataType := TFIBTraceFlag(FTraceDataType^);
    st.FTimeStamp := TDateTime(FTimeStamp^);
    st.FIsUnicodeVersion:=FIsUnicodeVersion^;
    FIsUnicodeVersion^:=False;
  finally
    EndRead;
  end;
end;

procedure TMonitorReaderThread.RemoveMonitor(Arg: TFIBCustomSQLMonitor);
begin
  EnterCriticalSection(CS);
  FMonitors.Remove(Arg);
  LeaveCriticalSection(CS);
end;



function MonitorHook: TFIBSQLMonitorHook;
begin
{  if not bEnabledMonitoring then
  begin
   Result :=nil; Exit;
  end;}
  if (_MonitorHook = nil) and (not bDone) then
  begin
    EnterCriticalSection(CS);
    if (_MonitorHook = nil) and (not bDone) then
    begin
      _MonitorHook := TFIBSQLMonitorHook.Create;
    end;
    LeaveCriticalSection(CS);
  end;
  Result := _MonitorHook
end;

procedure EnableMonitoring;
begin
  bEnabledMonitoring:=true;
end;

procedure DisableMonitoring;
begin
  bEnabledMonitoring  :=false;
end;

function MonitoringEnabled: Boolean;
begin
  Result := bEnabledMonitoring and ((FMonitorCount=nil) or(FMonitorCount^>0));
end;


initialization
{$IFNDEF NO_MONITOR}
  InitializeCriticalSection(CS);
  _MonitorHook := nil;
  FFIBWriterThread := nil;
  FFIBReaderThread := nil;
  bDone := False;
  bEnabledMonitoring:=true;
{$ENDIF}
finalization
{$IFNDEF NO_MONITOR}
  try
     bDone := True;
     FreeAndNil(FFIBReaderThread);
     {$IFDEF D6+}
     if Assigned(FFIBWriterThread) then
     begin
      FFIBWriterThread.StopExec:=True;
      FFIBWriterThread.Terminate;
      FFIBWriterThread.WaitFor;
     end;
     {$ELSE}
      if Assigned(FFIBWriterThread) and not FFIBWriterThread.Suspended then
       FFIBWriterThread.Suspend;
     {$ENDIF}
     FreeAndNil(FFIBWriterThread);
     if Assigned(_MonitorHook) then   _MonitorHook.Free;
  finally
    _MonitorHook := nil;
    DeleteCriticalSection(CS);
  end;
{$ENDIF}
{$ENDIF}
end.



