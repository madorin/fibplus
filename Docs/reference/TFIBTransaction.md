# TFIBTransaction

Controls one transaction on one or more databases: starts it, ends it, and holds its parameters. Queries and datasets run inside the transaction assigned to them. A transaction can end by itself after a period of inactivity (`Timeout`). A transaction mode sets the parameters, named transaction kinds can be saved at design time, and events run around starting and ending the transaction and around the queries that run in it.

| | |
|---|---|
| Unit | `FIBDatabase` |
| Inherits from | `TComponent` |
| Deprecated alias | `TpFIBTransaction`, in the unit `pFIBDatabase` |

The sample uses the components `Database`, `Transaction`, and `Query`; `Query.Transaction` is set to `Transaction`.

```delphi
Transaction.DefaultDatabase := Database;
Transaction.TRParams.Text := 'read_committed'#13#10'rec_version'#13#10'nowait';
Transaction.StartTransaction;
try
  Query.ExecQuery;
  Transaction.Commit;
except
  Transaction.Rollback;
  raise;
end;
```

A transaction mode chooses the parameters by name. The sample runs a query in a repeatable read transaction.

```delphi
Transaction.DefaultDatabase := Database;
Transaction.TPBMode := tpbRepeatableRead;
Transaction.StartTransaction;
try
  Query.ExecQuery;
finally
  Transaction.Commit;
end;
```

Guides: [Transactions](../guide/transactions.md), [Timeouts](../guide/timeouts.md), [Events and monitoring](../guide/events-and-monitoring.md).

## Published properties

Available in the Object Inspector.

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `Active` | `Boolean` | | `True` while the transaction is started. Setting `True` calls `StartTransaction`; setting `False` calls `Rollback`. Stored in the form only when `Active` is `True` and the main database has `StoreConnected` set. |
| `DefaultDatabase` | `TFIBDatabase` | | Main database of the transaction. Raises if the transaction is active. |
| `TRParams` | `TStrings` | lines of `tpbReadCommitted` | Transaction parameters, one per line, exactly as they are sent. See [Transaction parameters](#transaction-parameters) and [Transaction mode](#transaction-mode). Stored in the form only when `TPBMode` is `tpbDefault`. |
| `Timeout` | `Cardinal` | `0` | Client-side inactivity time in milliseconds. `0` disables it. See [Timeout](#timeout). |
| `TimeoutAction` | `TTransactionAction` | `TARollback` | How the transaction ends on `Timeout`. Also used when the database disconnects and when the component is destroyed. The design-time default comes from `DefTimeOutAction` in `FIBProps`. See [Types](#types). |
| `WatchUncommitedUpdates` | `Boolean` | `False` | Track whether the transaction has uncommitted changes, see `HasUncommitedUpdates`. |
| `CSMonitorSupport` | `TCSMonitorSupport` | | Monitoring support. Only when compiled with `CSMonitor`. |
| `TPBMode` | `TTPBMode` | `tpbReadCommitted` | Chooses the lines of `TRParams`, see [Transaction mode](#transaction-mode). At design time the initial value of a component dropped on a form comes from `DefTPBMode` in `FIBProps`. |
| `UserKindTransaction` | `string` | `NoUserKind` | Name of a transaction kind, see [Transaction kinds](#transaction-kinds). Stored in the form only when it is not `NoUserKind`. |
| `About` | `string` | | Library version text. Writing is ignored and the value is not stored. |

Events are listed in [Events](#events).

## Transaction parameters

`TRParams` holds one parameter per line. Names are case-insensitive, and the prefix `isc_tpb_` is optional (`read_committed` and `isc_tpb_read_committed` are the same). Blank lines are ignored. The list is converted to a transaction parameter buffer when the transaction starts, and what the list holds is what is sent: see [Transaction mode](#transaction-mode) for the lines a new transaction has.

With an empty list no parameters are sent, and the server uses its defaults (`concurrency`, `wait`, `write`). A name that is neither in the table below nor in the list of unsupported names raises `EFIBClientError`. `TRParams` cannot be changed while the transaction is active.

Each line is split at the first `=` without trimming the name, so no spaces are allowed around `=`: `lock_timeout = 5` raises `EFIBClientError` (unknown parameter).

| Parameter | Group | Meaning |
|-----------|-------|---------|
| `concurrency` | Isolation | Snapshot isolation. |
| `consistency` | Isolation | Table stability. |
| `read_committed` | Isolation | Read committed. Combine with `rec_version`, `no_rec_version`, or `read_consistency`. |
| `rec_version` | Record version | With `read_committed`: read the latest committed version of a record that has a pending change. |
| `no_rec_version` | Record version | With `read_committed`: wait for, or fail on, a record that has a pending change. |
| `read_consistency` | Record version | Read committed where every statement reads one snapshot taken at its start. Implies `read_committed`; cannot be combined with `rec_version` or `no_rec_version`. *Firebird 4+*: an older server rejects the buffer, and on InterBase the code (22) means another parameter. |
| `read` | Access mode | Read-only transaction. |
| `write` | Access mode | Read-write transaction. |
| `wait` | Lock resolution | Wait for a conflicting transaction to end. |
| `nowait` | Lock resolution | Fail at once on a conflict. |
| `lock_timeout=Seconds` | Lock resolution | Wait at most that long on a conflict. *Firebird 2.1+*. See the notes below. |
| `no_savepoint` | Other | Same value as `lock_timeout` (21). See the notes below. |
| `lock_read=Table`, `lock_write=Table` | Table reservation | Reserve a table for reading or writing. Used with `shared`, `protected`, or `exclusive`. |
| `shared`, `protected`, `exclusive` | Table reservation | Sharing mode of the reservation. |
| `ignore_limbo` | Other | Ignore records created by transactions in limbo. |
| `no_auto_undo` | Other | Passed to the server as `isc_tpb_no_auto_undo`. |

The names `verb_time`, `commit_time`, `autocommit`, and `restart_requests` are recognized but not supported; they raise `EFIBClientError`.

`lock_timeout` and `no_savepoint` share the same parameter code, and the conversion treats them alike:

- On *Firebird 2.1+* both are sent as a lock timeout. The seconds come from the value after `=`; a missing or non-numeric value becomes `10`. A bare `no_savepoint` is therefore sent as `lock_timeout=10`.
- The value is limited to 65535 (a `Word`).
- On older servers and on InterBase the code is sent without a value, so the number is ignored.

The sample below uses the `Transaction` component.

```delphi
Transaction.TRParams.Clear;
Transaction.TRParams.Add('read_committed');
Transaction.TRParams.Add('rec_version');
Transaction.TRParams.Add('lock_timeout=5');
```

## Transaction mode

`TPBMode` chooses a preset. The preset writes its lines into `TRParams`, so the list always shows what is sent.

| `TPBMode` | `TRParams` lines |
|-----------|------------------|
| `tpbDefault` | The lines you write. An empty list means the server default (`concurrency`, `wait`, `write`). |
| `tpbReadCommitted` | `write`, `isc_tpb_nowait`, `read_committed`, `rec_version` |
| `tpbRepeatableRead` | `write`, `isc_tpb_nowait`, `concurrency` |
| `tpbReadConsistency` | `write`, `isc_tpb_nowait`, `read_committed`, `read_consistency`. *Firebird 4+*: when the list sent to a database holds `read_consistency` and that server is older, `StartTransaction` raises `EFIBClientError` before the start. |

`tpbReadCommitted` is the default. On *Firebird 4+* with the default server setting `ReadConsistency = 1`, every read committed transaction runs in read consistency mode, so `tpbReadCommitted` behaves like `tpbReadConsistency` there. The two differ only when the database has `ReadConsistency = 0`.

The rule: a preset writes its lines into `TRParams`, and `TRParams` is always exactly what is sent.

- Setting a preset replaces `TRParams` with its lines. This also happens when the component is created and when a form loads.
- `TPBMode` is a preset exactly while its lines are untouched. Any change of `TRParams` sets `TPBMode` to `tpbDefault`. From then on the list is an ordinary list and no start changes it.
- Setting `tpbDefault` on an untouched preset empties `TRParams`. Lines you add afterwards stay as written.
- Setting a preset again after a change drops your own lines and writes the preset lines.
- `TPBMode` and `TRParams` cannot change while the transaction is active; the attempt raises `EFIBClientError` (`feInTransaction`).

How the first change ends the preset:

| Change | Result |
|--------|--------|
| `Clear`, `Text :=`, `Assign`, `TRParams := ...`, `LoadFromFile`, `LoadFromStream` | The list is the new content. |
| `Add`, `Insert`, `AddObject`, `AddStrings` of a line named `read`, `write`, `read_committed`, `rec_version`, `no_rec_version`, `read_consistency`, `concurrency`, `consistency`, `wait`, `nowait`, or `lock_timeout` | The preset lines are removed, then the line is added: these lines mean your own parameters. |
| `Add`, `Insert`, `AddObject`, `AddStrings` of any other line (`no_auto_undo`, `ignore_limbo`, `lock_read=T`, `lock_write=T`, `shared`, `protected`, `exclusive`, or an unknown name) | The line extends the preset. |
| `Delete`, `Strings[i] :=`, `Exchange`, `Move`, `Sort` | Applied to the preset lines as they are. |

The name of a line is the text before `=`, trimmed, in any case, without the prefix `isc_tpb_`. `Values['Name'] := ...` for a name that is not in the list adds an empty line and then changes it, so it always extends the preset; use `Add`. A form of an older version loads in the same way: the lines stored in `TRParams` give `tpbDefault`.

```delphi
Transaction.TRParams.Add('no_auto_undo');
// the lines of tpbReadCommitted and no_auto_undo; TPBMode is tpbDefault

Transaction.TPBMode := tpbReadCommitted;
Transaction.TRParams.Add('read');
Transaction.TRParams.Add('read_committed');
Transaction.TRParams.Add('rec_version');
// only these three lines; TPBMode is tpbDefault
```

FIBPlus does not check the lines against each other. A list that contradicts itself, such as a preset with `read` added after `no_auto_undo`, starts the transaction on the server, which refuses it (`isc_bad_tpb_content`). All presets write `write`, so a read-only transaction needs `read` in its own list, as in the sample above.

`lock_timeout` counts as a wait line because *Firebird 3+* refuses it together with `nowait`, which every preset writes. `Add('lock_timeout=5')` on a preset therefore leaves only that line. Write read committed with a lock timeout in full:

```delphi
Transaction.TRParams.Text := 'write'#13#10'read_committed'#13#10'rec_version'#13#10'lock_timeout=5';
```

Do not change `TRParams` in `BeforeStart` or in `BeforeStartTransaction` of the database. The list is no longer reset at each start, so a line added there is added again at the next start, and the server refuses the duplicate.

## Types

| Type | Values |
|------|--------|
| `TTPBMode` | `tpbDefault`, `tpbReadCommitted`, `tpbRepeatableRead`, `tpbReadConsistency` |
| `TOnSQLExecute` | `procedure(Query: TComponent; SQLType: TFIBSQLTypes) of object` |
| `TTransactionAction` | `TARollback`, `TARollbackRetaining`, `TACommit`, `TACommitRetaining` |
| `TTransactionState` | `tsActive`, `tsClosed`, `tsDoRollback`, `tsDoRollbackRetaining`, `tsDoCommit`, `tsDoCommitRetaining`; the `tsDo...` values are set while the transaction is ending |
| `TFIBTransactionEventType` | `tetBeforeStartTransaction`, `tetAfterStartTransaction`, `tetBeforeEndTransaction`, `tetAfterEndTransaction`, `tetBeforeDestroy`; selects the list for `AddEvent` and `AddEndEvent` |
| `TEndTrEvent` | `procedure(EndingTR: TFIBTransaction; Action: TTransactionAction; Force: Boolean) of object`; `Force` is `True` when the end cannot be refused (timeout, disconnect, destroy) |

## Transaction kinds

A transaction kind is a named set of parameters saved in the Windows registry by the design-time tools, under `HKEY_CURRENT_USER\Software\FIBC_Software\Transation Kinds`. Each entry has a `Name` value and a `Params` value.

Setting `UserKindTransaction` at design time, not while the form loads, looks up the entry with that name. When it exists, `TPBMode` becomes `tpbDefault` and `TRParams` takes the saved `Params` text. At run time, and for the name `NoUserKind`, the setter only stores the name. Without registry support in the build (`NO_REGISTRY`) the setter does nothing.

## Timeout

`Timeout` is a client-side timer. It does not cancel statements on the server; for that see [Timeouts](../guide/timeouts.md).

- The timer starts with the transaction and stops when the transaction ends.
- Every call to the server through the transaction resets the inactivity state. The transaction ends when a whole timer interval passes without such a call, so the real delay is between one and two intervals.
- The transaction ends with `TimeoutAction`, forced, and then `OnTimeout` is called. With a retaining action (`TARollbackRetaining`, `TACommitRetaining`) the transaction performs the retaining operation and stays active.
- Setting `Timeout` to `0` frees the timer.

## Run-time properties

### State

| Name | Type | Description |
|------|------|-------------|
| `InTransaction` | `Boolean` | `True` while the transaction has a handle. |
| `State` | `TTransactionState` | Current state. |
| `TransactionID` | `Integer` | Server transaction ID; `0` when not started, and while the database is closing or restoring a lost connection. Read from the server on first use. |
| `HasUncommitedUpdates` | `Boolean` | `True` after a statement changed rows in this transaction. Needs `WatchUncommitedUpdates`. Reset when the transaction ends, including `CommitRetaining` and `RollbackRetaining`. |
| `Handle` | `TISC_TR_HANDLE` | Native transaction handle. |
| `HandleIsShared` | `Boolean` | `True` when `Handle` was assigned from outside. |

Assigning `Handle` attaches the component to a transaction started elsewhere. Ending such a transaction only releases the handle; no commit or rollback is sent to the server. `Commit` or `Rollback` on a shared handle raises `EFIBClientError` unless the action equals `TimeoutAction`.

### Databases and attached objects

| Name | Type | Description |
|------|------|-------------|
| `DatabaseCount` | `Integer` | Number of databases in the transaction. |
| `Databases[Index]` | `TFIBDatabase` | Database by index. |
| `FIBBaseCount` | `Integer` | Number of queries and datasets attached to the transaction. |
| `FIBBases[Index]` | `TFIBBase` | Attached object by index. |
| `FIBDataSets[Index]` | `TDataSet` | Dataset attached to this transaction, by index. Each dataset is counted once. |
| `FIBQueries[Index]` | `TComponent` | Query attached to this transaction that does not belong to a dataset, by index. |
| `Internal` | `Boolean` | `False` by default. Not published. Cannot change while the transaction is active (`feInTransaction`). With `True` the events of the database (`BeforeStartTransaction`, `AfterStartTransaction`, `BeforeEndTransaction`, `AfterEndTransaction`) are not raised for this transaction; its own events, the SQL monitor, and the SQL logger are not affected. The library sets it on the transactions it creates for its own work. See [Events](#events). |

## Methods

### Starting and ending

| Name | Description |
|------|-------------|
| `StartTransaction` | Start the transaction on all its databases with one call. Raises `EFIBClientError` (`feInTransaction`) if it is already active, before any event runs (`Active := True` on an active transaction does nothing). Raises if it has no database. Calls the start events around the start, see [Events](#events). At run time, a database that is not connected raises, unless `AutoReconnect` is `True`. With `AutoReconnect`, the database connects first; if that fails, no error is raised and the transaction stays inactive. |
| `Commit` | Commit and end. |
| `CommitRetaining` | Commit and keep the transaction and its cursors open. |
| `Rollback` | Roll back and end. |
| `RollbackRetaining` | Roll back and keep the transaction open. |
| `FIBDataSetsCount`, `FIBQueryCount` | Number of entries of `FIBDataSets` and `FIBQueries`. |

When the transaction is not active, each of these methods first calls `CheckInTransaction`. At run time it raises, unless every database has `AutoReconnect` set to `True`; then a transaction is started and ended at once. At design time a transaction is always started first.

*Protected:* `EndTransaction(Action, Force)` is virtual and does the work of all four methods. It calls the end events around the end, so they run for `Commit`, `Rollback`, the retaining variants, a timeout, a disconnect, and destroying the component. `Force` set to `True` ends the transaction even when the server call fails.

Before the end, the transaction calls the `OnTransactionEnding` hook of every attached object (`FIBBases`), and after the end the `OnTransactionEnded` hook. A `TFIBQuery` uses the first hook internally to close its open cursor (when its internal auto-close flag is set) when the transaction commits or rolls back (not on a retaining action). `TFIBDataSet` forwards both hooks to its published events `TransactionEnding` and `TransactionEnded`. Handlers registered with `AddEndEvent` are called at the same two points, right after the hooks. Closing a transaction with an open cursor is covered in [Transactions](../guide/transactions.md).

### Savepoints and SQL

| Name | Description |
|------|-------------|
| `ExecSQLImmediate(SQLText)` | Run one statement without a prepared statement, in this transaction. Returns no rows. |
| `SetSavePoint(Name)` | Run `SAVEPOINT Name`. |
| `RollBackToSavePoint(Name)` | Run `ROLLBACK TO SAVEPOINT Name`. |
| `ReleaseSavePoint(Name)` | Run `RELEASE SAVEPOINT Name`. |

### Databases

| Name | Description |
|------|-------------|
| `AddDatabase(Db)` / `AddDatabase(Db, TRParams)` | Add a database to the transaction and return its index. The second form sets parameters used for that database only. All databases must use the same client library. |
| `RemoveDatabase(Index)` | Remove a database by index. |
| `ReplaceDatabase(OldDb, NewDb)` | Replace one database with another. |
| `FindDatabase(Db)` | Index of the database, or `-1`. |
| `MainDatabase` | `DefaultDatabase`, or the first database of the list. |

### Checks and helpers

| Name | Description |
|------|-------------|
| `CheckDatabasesInList` | Raise if the transaction has no database. |
| `CheckInTransaction` | Ensure the transaction is active. At design time it starts the transaction. At run time it starts it only when every database has `AutoReconnect` set to `True`; otherwise it raises. |
| `CheckNotInTransaction` | Raise if the transaction is active. |
| `IsReadOnly` | `True` if `TRParams` contains `read`. |
| `IsReadCommitedTransaction` | `True` if `TRParams` contains `read_committed` or `read_consistency`. |
| `CloseAllQueryHandles` | Release the statement handle of every attached `TFIBQuery`. |
| `OnDatabaseDisconnecting(Db)` | Called by the database before it disconnects. Ends an active transaction with `TimeoutAction`, forced; a retaining action is replaced by its plain variant. |

### Event lists

| Name | Description |
|------|-------------|
| `AddEvent(Event, EventType)` / `RemoveEvent(Event, EventType)` | Register or remove a `TNotifyEvent` handler. `EventType` is `tetBeforeStartTransaction`, `tetAfterStartTransaction`, or `tetBeforeDestroy`. Other values raise an assertion. |
| `AddEndEvent(Event, EventType)` / `RemoveEndEvent(Event, EventType)` | Register or remove a `TEndTrEvent` handler. `EventType` is `tetBeforeEndTransaction` or `tetAfterEndTransaction`. |

Unlike a published event, these lists take any number of handlers. Components that need to react to a transaction use them.

### Query events

| Name | Description |
|------|-------------|
| `DoOnSQLExec(Query, Kind)` | Called by a query attached to the transaction; runs the base behavior, then `BeforeSQLExecute`, `AfterSQLExecute`, or `AfterFirstFetch`. `Query` is a `TComponent`; `SQLType` is the statement type of a `TFIBQuery`. |

## Events

| Name | Description |
|------|-------------|
| `OnTimeout` | `Timeout` elapsed and `TimeoutAction` was applied; called after the action. With a retaining action the transaction stays active. |
| `BeforeStart` | Before the transaction starts. |
| `AfterStart` | After the transaction started. Does not run when the start was skipped without an error (see `AutoReconnect` in [Starting and ending](#starting-and-ending)); `BeforeStart` has run by then. |
| `BeforeEnd` | Before the transaction ends. `Action` and `Force` tell how. Runs before the check that the transaction is active, so it also runs for `Commit` or `Rollback` on an inactive transaction. |
| `AfterEnd` | After the transaction ended. |
| `BeforeSQLExecute` | A query attached to the transaction is about to run. `SQLType` is the statement type. |
| `AfterSQLExecute` | The query ran. |
| `AfterFirstFetch` | The first row of a query cursor was fetched. |

The events of `DefaultDatabase` (`BeforeStartTransaction`, `AfterStartTransaction`, `BeforeEndTransaction`, `AfterEndTransaction`, see [TFIBDatabase](TFIBDatabase.md#events)) run for the transaction too, in addition to its own events, unless `Internal` is `True`. Before a start or end, the database event runs first, then the transaction event. After a start or end, the transaction event runs first, then the database event. `StartTransaction` on an active transaction raises before any of the start events.

## See also

- [TFIBDatabase](TFIBDatabase.md)
- [TFIBQuery](TFIBQuery.md), [TFIBDataSet](TFIBDataSet.md)
- [Transactions](../guide/transactions.md)
- [Timeouts](../guide/timeouts.md)
