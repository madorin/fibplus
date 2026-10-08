# Events and monitoring

FibPlus has four tools that tell your application, or you, what is going on:

| Tool | Component | Use it to |
|------|-----------|-----------|
| Database events | `TSIBfibEventAlerter` | React to events that the server posts with `POST_EVENT` |
| Error handling | `TpFibErrorHandler` | Classify server errors, replace messages, handle a lost connection |
| SQL monitor | `TFIBSQLMonitor` | Watch the statements that the library sends, live |
| SQL log and statistics | `TFIBSQLLogger` | Write the statements to a file and measure how long they take |

The sections below follow this order.

## Requirements

- `TSIBfibEventAlerter` needs a connected `TFIBDatabase`.
- Only one `TpFibErrorHandler` can exist in an application at run time. Creating a second one raises an exception.
- `TFIBSQLMonitor` works only in Windows builds. The unit is not compiled when `NO_MONITOR` is defined; see [TFIBSQLMonitor](../reference/TFIBSQLMonitor.md).
- `TFIBSQLLogger` has no platform limit.

## Database events

A database event is a name that the server posts, for example from a trigger. An application that has registered for that name is notified. This replaces polling a table for changes.

Raise the event on the server:

```sql
SET TERM ^ ;
CREATE TRIGGER ORDERS_AI FOR ORDERS
ACTIVE AFTER INSERT POSITION 0
AS
BEGIN
  POST_EVENT 'NEW_ORDER';
END^
SET TERM ; ^
```

### Listen for an event

The unit is `SIBFIBEA` (the base class `TSIBEventAlerter` is in `SIBEABase`). The sample uses a `TSIBfibEventAlerter` named `EventAlerter` and a `TpFIBDatabase` named `Database`.

```delphi
procedure TMainForm.FormCreate(Sender: TObject);
begin
  EventAlerter.Database := Database;
  EventAlerter.Events.Add('NEW_ORDER');
  EventAlerter.AutoRegister := True;
  Database.Connected := True;
end;

procedure TMainForm.EventAlerterEventAlert(Sender: TObject; EventName: string; EventCount: Longint);
begin
  StatusBar.SimpleText := Format('%s: %d', [EventName, EventCount]);
end;
```

With `AutoRegister` set, the alerter registers its events after the database connects. Without it, call `RegisterEvents` yourself while the database is connected. In both cases the alerter cancels a registration before the database disconnects, so after a reconnect the events are not registered unless `AutoRegister` is set, and a call to `UnRegisterEvents` after the disconnect raises `ESIBError`.

| Member | Description |
|--------|-------------|
| `Database` | The `TFIBDatabase` to listen on. |
| `Events` | Event names to listen for. |
| `AutoRegister` | Register after connect. Default `False`. |
| `VCLSynchronize` | Run `OnEventAlert` in the main thread. Default `True`. |
| `Registered` | `True` while the events are registered. |
| `RegisterEvents` / `UnRegisterEvents` | Start or stop listening. |
| `OnEventAlert(Sender, EventName, EventCount)` | One call for each event name that fired, with the number of times it fired. |

### Rules for event names

- The list is sorted and ignores duplicates.
- An empty name is removed and raises `ESIBError`.
- A name of 128 characters or more raises `ESIBError`. The longest valid name has 127 characters.
- The library registers up to 15 names per block and starts one thread for each block.
- Changing `Events` while registered cancels the registration and registers the new list.

### Threads

`OnEventAlert` runs in the main thread because `VCLSynchronize` is `True`. Set it to `False` to run the handler in the event thread; then the handler must not touch the VCL without its own synchronization.

The first notification after a registration only initializes the event buffers. It does not call `OnEventAlert`.

### Errors and pitfalls

- `RegisterEvents` raises `ESIBError` when the events are already registered, and when no database is assigned or the database is not connected.
- `UnRegisterEvents` raises `ESIBError` when the events are not registered. Setting `Registered := False` ignores that error.
- When an event thread fails, the alerter cancels all registrations and shows the exception with `SysUtils.ShowException`.

## Error handling

Without an error handler, a server error raises `EFIBError` in the calling code. When a `TpFibErrorHandler` exists, the library passes every server error to it first. The handler:

1. sets `LastError` (a `TKindIBError`) and extracts details, depending on `Options`;
2. calls `OnFIBErrorEvent`, where you can change the message or suppress the exception;
3. lets the library raise the exception when `DoRaise` is still `True`.

The unit is `pFIBErrorHandler`. Drop one `TpFibErrorHandler` on a data module or the main form. It registers itself; there are no properties to link.

### Error kinds

| `LastError` | Meaning |
|-------------|---------|
| `keNoError` | No error has been handled yet. |
| `keException` | A user exception raised with `EXCEPTION` in a trigger or procedure (SQL code -836). |
| `keForeignKey` | A foreign key violation. |
| `keCheck` | A `CHECK` constraint violation (SQL code -297). |
| `keUniqueViolation` | A primary or unique key violation (SQL code -803). |
| `keSecurity` | A permission error (SQL code -551). |
| `keLostConnect` | The connection to the server is lost. |
| `keStatementTimeout` | The server cancelled the statement because of its timeout. See [Timeouts](timeouts.md). |
| `keCancelled` | The operation was cancelled for another reason. |
| `keOther` | Any other error. |

### Options

`Options` is a set of `TOptionErrorHandler`. The default is `[oeException, oeLostConnect]`.

| Value | Effect |
|-------|--------|
| `oeException` | For `keException`, extract the exception number into `ExceptionNumber` and the text into the message. On *Firebird 2+*, also extract the exception name into `ExceptionName`. |
| `oeForeignKey` | Replace the message with the text stored for the constraint, when there is one. Without a stored text the message stays as it is. |
| `oeCheck` | Set `ConstraintName` and replace the message with the stored text. Without a stored text, the message becomes the server message (`IBMessage`) only. |
| `oeUniqueViolation` | The same as `oeCheck`, for a unique key violation. |
| `oeLostConnect` | On a lost connection, call the `OnLostConnect` event of the `TpFIBDatabase` components. See [Lost connection](#lost-connection). |

`ConstraintName` is set for a foreign key violation even when `oeForeignKey` is off.

### Handle errors by kind

The sample uses a `TpFibErrorHandler` named `ErrorHandler`.

```delphi
procedure TMainForm.ErrorHandlerFIBErrorEvent(Sender: TObject; ErrorValue: EFIBError;
  KindIBError: TKindIBError; var DoRaise: Boolean);
begin
  case KindIBError of
    keException:
      ErrorValue.Message := Format('Rule %d (%s): %s',
        [ErrorHandler.ExceptionNumber, ErrorHandler.ExceptionName, ErrorValue.Message]);
    keUniqueViolation:
      ErrorValue.Message := 'This value already exists: ' + ErrorHandler.ConstraintName;
    keStatementTimeout:
      ErrorValue.Message := 'The query took too long.';
  end;
end;
```

`ConstraintName` is empty for a unique key violation unless `oeUniqueViolation` is in `Options`; add it first, for example `ErrorHandler.Options := ErrorHandler.Options + [oeUniqueViolation]`.

The exception is still raised, with the new message. Show it where you handle exceptions, for example in `Application.OnException`. Setting `DoRaise` to `False` suppresses the exception, and the calling code continues; do this only when you handle the situation completely.

For `keLostConnect`, `DoRaise := False` ends the call with a silent `EAbort`, unless the database is already restoring the connection.

| Member | Description |
|--------|-------------|
| `LastError` | Kind of the last handled error. |
| `ExceptionNumber`, `ExceptionName` | Number and name of a user exception. Valid for `keException` when `oeException` is set; `ExceptionNumber` is `-1` otherwise. |
| `ConstraintName` | Constraint of a foreign key, check, or unique violation, see [Options](#options). |
| `ErrorLexems` | Words that the handler looks for in the server message: `Constraint`, `Index`, `Exception`, `At`. Written in lower case. Defaults: `constraint`, `index`, `exception`, `at`. |
| `OnFIBErrorEvent(Sender, ErrorValue, KindIBError, DoRaise)` | Called after the handler classified the error. |

### Custom messages for constraints

With `oeForeignKey`, `oeCheck`, or `oeUniqueViolation`, the handler looks up the constraint name in the table `FIB$ERROR_MESSAGES` of the database. A row has a `CONSTRAINT_NAME` and a `MESSAGE_STRING`.

```sql
INSERT INTO FIB$ERROR_MESSAGES (CONSTRAINT_NAME, MESSAGE_STRING)
VALUES ('UNQ_CUSTOMER_NAME', 'A customer with this name already exists.');
```

The lookup needs the table to exist and `urErrorMessagesInfo` to be in `TFIBDatabase.UseRepositories` (it is by default). Found messages are cached in the application. Without a row for the constraint, a foreign key violation keeps its message; a unique or check violation gets the server message only.

### Lost connection

A lost connection is detected from the server error code. After a failed cursor reopen (a *Firebird 3+* client defers the cursor close) the handler also pings the attachment to find out whether it is lost. With `oeLostConnect`, the handler calls `OnLostConnect` of the `TpFIBDatabase` (unit `pFIBDatabase`) that raised the error. If the error does not belong to a database, it calls the event of every `TpFIBDatabase`.

Set `Actions` in the event. `laCloseConnect` is the value when you do not change it.

- `laCloseConnect` closes the connection locally, without calls to the server.
- `laWaitRestore` closes it and starts a timer that tries to connect again.
- `laIgnore` does nothing.
- `laTerminateApp` closes the connection and terminates the application.

The timer interval is `WaitForRestoreConnect`, `30000` ms by default. With `0`, as stored by forms saved before 7.9.1, `laWaitRestore` does nothing more than `laCloseConnect`. The details of each action are in [Lost connection](../reference/TpFIBDatabase.md#lost-connection).

```delphi
procedure TMainForm.DatabaseLostConnect(ADatabase: TFIBDatabase; E: EFIBError;
  var Actions: TOnLostConnectActions; var DoRaise: Boolean);
begin
  Actions := laWaitRestore;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Database.WaitForRestoreConnect := 10000;
  Database.OnLostConnect := DatabaseLostConnect;
end;
```

`OnLostConnect` has its own `DoRaise`. It decides whether the original error is raised, and by default the call that found the lost connection raises. After each connect attempt, `AfterRestoreConnect` runs on success and `OnErrorRestoreConnect` on failure. See [TpFIBDatabase](../reference/TpFIBDatabase.md) and [Connections](connections.md).

## SQL monitor

`TFIBSQLMonitor` shows the SQL activity of the library as text events: what is prepared, executed, and fetched, and how connections and transactions behave. It needs no change in the database or in the code that runs the statements. Use it to check which SQL a dataset really sends, which parameter values it uses, and how long a statement takes.

### Trace your own application

Drop a `TFIBSQLMonitor` on a form, write an `OnSQL` handler, and choose what to trace. The unit is `FIBSQLMonitor`. The sample uses a `TFIBSQLMonitor` named `SQLMonitor` and a `TMemo` named `LogMemo`.

```delphi
procedure TMainForm.SQLMonitorSQL(EventText: string; EventTime: TDateTime);
begin
  LogMemo.Lines.Add(FormatDateTime('hh:nn:ss.zzz', EventTime) + ' ' + EventText);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  SQLMonitor.TraceFlags := [tfQExecute, tfTransact];
  SQLMonitor.OnSQL := SQLMonitorSQL;
end;
```

Tracing starts at run time. A monitor at design time does not receive events.

`OnSQL` is called in the thread that created the monitor. Create the monitor in the main thread to update the user interface directly.

### Choose the trace flags

`TraceFlags` selects which kinds of events reach `OnSQL`. The default is prepare, execute, fetch, connect, and transaction events. See [Types](../reference/TFIBSQLMonitor.md#types) for all values.

| Question | Flags |
|----------|-------|
| Which SQL is sent, with which parameters and how long does it take? | `tfQExecute` |
| Which access plan does the server use? | `tfQPrepare` |
| Where does a transaction start and end? | `tfTransact` |
| When does the application connect? | `tfConnect` |
| What values does a cursor return? | `tfQFetch` |

`tfQFetch` produces an event for every fetched row. Turn it on only while you investigate a specific cursor.

You can change `TraceFlags` while the application runs, for example from a menu item. Set `Active` to `False` to stop the monitor without freeing it.

### Read the trace

Each event starts with a line break and a line `[Application: <exe name>]`. The next line starts with the name of the component that reports (shown as `<name>` below) and a marker for the kind. The exact text can differ in small details, such as line breaks, so search for the markers instead of parsing the lines.

| Event | Text |
|-------|------|
| Prepare | `<query name>: [Prepare] <SQL>`, then `Plan: <plan>`. A failed prepare reports `[Prepare]` with the error message instead of the SQL. |
| Execute | `<query name>: [Execute] <SQL>`, then one line `NAME = value` for each parameter, `Rows Affected:` for `INSERT`, `UPDATE`, and `DELETE`, and `Execute tick count <ms>`. |
| Failed execute | The execute event above, then a second event with `[Execute]` and the error message. |
| Fetch | `<query name>: [Fetch] <SQL>` with the column values `NAME = value` and, at the end of the cursor, `End of file reached`. |
| Connect | `<database name>: [Connect]` and `<database name>: [Disconnect]`. |
| Transaction | `<transaction name>: [Start transaction](<id>)`, `[Commit (Hard commit)]`, `[Commit retaining (Soft commit)]`, `[Rollback]`, `[Rollback retaining (Soft rollback)]`, and the savepoint operations. |
| Session | `<database name>: [Session] <statement>`, reported with `tfQExecute`, when the library itself sends a session statement such as the timeout settings. See [Timeouts](timeouts.md). |

For a query that belongs to a dataset, the name can include the dataset name. Null parameters are shown as `<NULL>`, and `BLOB` and array parameters as `<BLOB>` with the identifier, and `<ARRAY>`.

### Long events

A long event can arrive in several `OnSQL` calls, and only the first one has the `[Application: ...]` line. Do not assume that one call is one statement. See the `OnSQL` row in [Events](../reference/TFIBSQLMonitor.md#events) for the chunk size and the replacement of control characters.

### Several applications

The monitor receives the events of other processes that use the library, not only of its own application. The `[Application: ...]` line tells which one wrote the event. A small separate program with a `TFIBSQLMonitor` can therefore show the SQL of another FibPlus application without changing it. See [How it works](../reference/TFIBSQLMonitor.md#how-it-works) for the shared counters.

### Switch tracing off

| To | Do |
|----|----|
| Stop one monitor | Set `Active := False`. |
| Stop all tracing in the application | Call `DisableMonitoring`. `EnableMonitoring` turns it on again. |
| Check the state | `MonitoringEnabled`; it is also `False` while no monitor is registered, see [Global routines](../reference/TFIBSQLMonitor.md#global-routines). |

The routines are in the unit `FIBSQLMonitor`, like `TFIBTraceFlag` and `MonitorHook`. Tracing is on by default. The library builds a message only when some monitor asks for that kind of event, so an application without a monitor does not pay for it.

### Send your own text

`MonitorHook.SendMisc` adds your own marker to the trace, for example before a long operation. Put `tfMisc` into `TraceFlags` to receive it.

```delphi
MonitorHook.SendMisc('Import started');
```

## SQL log and statistics

`TFIBSQLLogger` is attached to one `TFIBDatabase` and works inside the application. It differs from the SQL monitor in three ways: it can write to a file, you filter entries in code, and it can collect statistics for each statement. Use the monitor to look at the SQL while you develop; use the logger when the application has to keep a record.

### Write a log

Attach the logger with `Database.SQLLogger`, then switch logging on. `ActiveLogging` is `False` by default, so nothing is logged until you set it. The unit is `pFIBSQLLog`. The sample uses a `TFIBSQLLogger` named `Logger` and a `TpFIBDatabase` named `Database`.

```delphi
Logger.ApplicationID := 'ORDERS';
Logger.LogFileName := 'C:\Logs\orders-sql.log';
Logger.LogFlags := [lfQPrepare, lfQExecute, lfTransact];
Database.SQLLogger := Logger;
Logger.ActiveLogging := True;
Logger.ForceSaveLog := True;
```

A logger serves one database. Assigning it to another database detaches it from the first. A database has one logger.

Each entry contains the application identifier, the component name, the operation with the date and time, and the text: the SQL, the parameter values, or the transaction parameters.

| Member | Description |
|--------|-------------|
| `ActiveLogging` | Turns logging on. Default `False`. |
| `LogFlags` | Kinds of entries: `lfQPrepare`, `lfQExecute`, `lfQFetch`, `lfConnect`, `lfTransact`. Default: `[lfQPrepare, lfQExecute, lfConnect, lfTransact]`. |
| `LogFileName` | File that `SaveLog` appends to. |
| `ForceSaveLog` | Write each entry to the file at once. Default `False`. |
| `ApplicationID` | Text for the `Application:` line of every entry. |
| `SaveLog` | Append the collected entries to the file and clear the list. |
| `OnLogEvent` | Called for each entry before it is stored. Set `WriteToLog` to `False` to skip it. |

`lfService` and `lfMisc` exist in the `TLogFlag` type, but the library does not write entries of these kinds.

Without `ForceSaveLog`, entries stay in memory until you call `SaveLog`. They are lost when the component is destroyed without a call. At design time, nothing is logged.

Filter entries in `OnLogEvent`:

```delphi
procedure TMainForm.LoggerLogEvent(const ObjectName, Operation, EventText: string;
  DataType: TLogFlag; cApplication: string; EventTime: TDateTime; var WriteToLog: Boolean);
begin
  WriteToLog := Pos('AUDIT', EventText) > 0;
end;
```

### Collect statistics

The logger counts, for every distinct SQL text, how often it was prepared and executed and how long the executions took. Switch it on with `ActiveStatistics`. Times are in milliseconds.

```delphi
Database.SQLLogger := Logger;
Logger.ActiveStatistics := True;
// ... run the application ...
Logger.SortStatisticsForPrint(scMaxTimeExecute, False);
Logger.SaveStatisticsToFile('C:\Logs\orders-stat.txt');
```

`scMaxTimeExecute` is a constant of the unit `FIBQuery`.

| Member | Description |
|--------|-------------|
| `ActiveStatistics` | Turns the collection on. Default `False`. |
| `StatisticsParams` | Values to collect: `fspExecuteCount`, `fspPrepareCount`, `fspSumTimeExecute`, `fspAvgTimeExecute`, `fspMaxTimeExecute`, `fspLastTimeExecute`. Default: all. A value that is not selected is not written to the file and is stored as `NULL` in the database. |
| `SortStatisticsForPrint(VarName, Ascending)` | Sorts the statements for `SaveStatisticsToFile` by one value. Use the `sc...` constants of `FIBQuery`, for example `scSumTimeExecute`. |
| `SaveStatisticsToFile(FileName)` | Appends the statistics to a text file. |
| `Clear` | Deletes the collected statistics. It does not delete log entries. |

### Save statistics to the database

`SaveStatisticsToDB` inserts one row for every statement into the table `FIB$APP_STATISTICS`. The database must be connected, and `ApplicationID` must not be empty. The table created by `CreateStatisticsTable` has `APP_ID VARCHAR(12)`, so keep `ApplicationID` within 12 characters; a longer value is probably rejected by the insert (not run).

```delphi
if not Logger.ExistStatisticsTable then
  Logger.CreateStatisticsTable;
Logger.SaveStatisticsToDB(500);
```

`ExistStatisticsTable` checks whether the table exists. `CreateStatisticsTable` creates the table, a generator, and a trigger, so the user needs the right to create them. The parameter of `SaveStatisticsToDB` is a limit in milliseconds: only statements whose slowest execution took at least that long are saved. The default `0` saves all of them. The call does not clear the statistics; call `Clear` to start a new period.

## See also

- [TFIBSQLMonitor](../reference/TFIBSQLMonitor.md)
- [TpFIBDatabase](../reference/TpFIBDatabase.md), [TFIBDatabase](../reference/TFIBDatabase.md)
- [Timeouts](timeouts.md), [Connections](connections.md), [Transactions](transactions.md)
