# TFIBSQLMonitor

Receives a trace of the library's SQL activity: statement prepare, execute, and fetch, connect and disconnect, and transaction control. Handle `OnSQL` to log what the application sends to the server. The component works only in Windows builds. The unit is not compiled when `NO_MONITOR` is defined; `FIBPlus.inc` defines it for non-Windows targets, and it can be defined by hand (the commented `{$DEFINE NO_MONITOR}` line in `FIBPlus.inc`).

| | |
|---|---|
| Unit | `FIBSQLMonitor` |
| Inherits from | `TFIBCustomSQLMonitor`, which inherits from `TComponent` |

```delphi
procedure TMainForm.SQLMonitorSQL(EventText: string; EventTime: TDateTime);
begin
  LogMemo.Lines.Add(FormatDateTime('hh:nn:ss.zzz', EventTime) + ' ' + EventText);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  SQLMonitor.TraceFlags := [tfQPrepare, tfQExecute];
  SQLMonitor.OnSQL := SQLMonitorSQL;
end;
```

The sample uses a `TFIBSQLMonitor` named `SQLMonitor` and a `TMemo` named `LogMemo`.

Guides: [Events and monitoring](../guide/events-and-monitoring.md).

## Published properties

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `Active` | `Boolean` | `True` | Registers the monitor with the hook. An inactive monitor receives nothing. A monitor created at design time does not register; tracing starts at run time. |
| `TraceFlags` | `TFIBTraceFlags` | `[tfQPrepare, tfQExecute, tfQFetch, tfConnect, tfTransact]` | Kinds of events that reach `OnSQL`. See [Types](#types). |

The default of `TraceFlags` is set in the constructor. `tfService` and `tfMisc` are off by default.

## How it works

Library components such as [TFIBQuery](TFIBQuery.md), [TFIBDatabase](TFIBDatabase.md), and [TFIBTransaction](TFIBTransaction.md) report their activity to a global monitor hook (`MonitorHook`). The hook writes the text into named system objects: shared memory, a mutex, and events named `FIB.SQL.MONITOR.*`. The monitor count and the per-kind reader counters are kept in that shared memory. The hook writes a message only while the shared counters show a reader for that kind of trace and monitoring is enabled.

The counters are updated by `TraceFlags` whether or not `Active` is set, and they count the monitors of every process that uses the library. Events from another process can therefore arrive; the `[Application: <exe name>]` line in the text tells which application wrote the event.

Each monitor receives the message in the thread that created it and calls `OnSQL` when the message kind is in `TraceFlags`.

## Types

`TFIBTraceFlag` values, collected in the set `TFIBTraceFlags`:

| Value | Reports |
|-------|---------|
| `tfQPrepare` | Statement prepare, with the SQL text and the plan. |
| `tfQExecute` | Statement execute, with the SQL text, parameter values, rows affected for `INSERT`, `UPDATE`, and `DELETE`, and the execute time. |
| `tfQFetch` | Each fetched row, with column values. |
| `tfConnect` | Connect and disconnect of a database. |
| `tfTransact` | Start, commit, rollback, the retaining variants, and savepoint operations of a transaction. |
| `tfService` | Attach, detach, query, and start of a service component from [TpFIBServices](TpFIBServices.md). Only when the library is compiled with service support (`INC_SERVICE_SUPPORT`). |
| `tfMisc` | Text sent with `MonitorHook.SendMisc`. |

`TSQLEvent` is the type of `OnSQL`: `procedure(EventText: String; EventTime: TDateTime) of object`.

`TSavePointOperation` (`soSet`, `soRollBack`, `soRelease`) is the parameter of `TFIBSQLMonitorHook.TRSavepoint`, which the transaction calls; application code does not use it.

## Run-time properties

| Name | Type | Description |
|------|------|-------------|
| `Handle` | `HWND` | Window handle that receives the trace messages. `0` at design time. |

## Methods

| Name | Description |
|------|-------------|
| `Release` | Queues a request to free the monitor; the monitor frees itself when its window receives the request. |

## Events

| Name | Description |
|------|-------------|
| `OnSQL` | An event of a kind in `TraceFlags` arrived. `EventText` starts with a line break, then a line `[Application: <exe name>]`, then the text of the event. `EventTime` is the time the event was recorded. Control characters other than tab, line feed, and carriage return are replaced by `#$` and their hexadecimal code. A long event is sent in chunks of about 2000 bytes, so one event can call `OnSQL` several times. |

## Constants

| Name | Value | Description |
|------|-------|-------------|
| `WM_MIN_FIBSQL_MONITOR` | `WM_USER` | Lower bound of the window messages used by the monitor. |
| `WM_MAX_FIBSQL_MONITOR` | `WM_USER + 512` | Upper bound of those messages. |
| `WM_FIBSQL_SQL_EVENT` | `WM_MIN_FIBSQL_MONITOR + 1` | Message that carries one trace event to the monitor window. |
| `CM_RELEASE` | `$B000 + 33` | Message that frees the monitor; sent by `Release`. |

## Global routines

Declared in the unit `FIBSQLMonitor`.

| Name | Description |
|------|-------------|
| `EnableMonitoring` / `DisableMonitoring` | Turn tracing on or off for the application. It is on by default. While off, the library does not build trace messages, except text sent with `SendMisc`, which is queued and then discarded. |
| `MonitoringEnabled` | `True` when tracing is on and either the shared memory of the hook does not exist yet or its monitor count is above zero. |
| `MonitorHook` | Returns the global `TFIBSQLMonitorHook`. |

## TFIBSQLMonitorHook

The library components call the hook; application code needs it only to send its own text.

| Name | Type | Description |
|------|------|-------------|
| `Enabled` | `Boolean` property, default `True` | Turns the hook on or off. Setting it to `False` also stops the hook's writer thread. |
| `SendMisc(Msg)` | method | Sends `Msg` as a `tfMisc` event. |

```delphi
MonitorHook.SendMisc('Import started');
```

The other public methods (`SQLPrepare`, `SQLExecute`, `SQLFetch`, `DBConnect`, `DBDisconnect`, `TRStart`, `TRCommit`, `TRRollback`, and the like) are called by the library and are not meant to be called from application code.

## See also

- [Events and monitoring](../guide/events-and-monitoring.md)
- [TFIBQuery](TFIBQuery.md), [TFIBDatabase](TFIBDatabase.md), [TFIBTransaction](TFIBTransaction.md)
