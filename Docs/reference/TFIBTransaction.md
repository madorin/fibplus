# TFIBTransaction

Controls one transaction on one or more databases: starts it, ends it, and holds its parameters. Queries and datasets run inside the transaction assigned to them. A transaction can end by itself after a period of inactivity (`Timeout`).

| | |
|---|---|
| Unit | `FIBDatabase` |
| Inherits from | `TComponent` |
| Descendants | `TpFIBTransaction`, which adds events, transaction kinds, and parameter handling |

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

Guides: [Transactions](../guide/transactions.md), [Timeouts](../guide/timeouts.md).

## Published properties

Available in the Object Inspector.

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `Active` | `Boolean` | | `True` while the transaction is started. Setting `True` calls `StartTransaction`; setting `False` calls `Rollback`. Stored in the form only when `Active` is `True` and the main database has `StoreConnected` set. |
| `DefaultDatabase` | `TFIBDatabase` | | Main database of the transaction. Raises if the transaction is active. |
| `TRParams` | `TStrings` | empty | Transaction parameters, one per line. See [Transaction parameters](#transaction-parameters). |
| `Timeout` | `Cardinal` | `0` | Client-side inactivity time in milliseconds. `0` disables it. See [Timeout](#timeout). |
| `TimeoutAction` | `TTransactionAction` | `TARollback` | How the transaction ends on `Timeout`. Also used when the database disconnects and when the component is destroyed. The design-time default comes from `DefTimeOutAction` in `pFIBProps`. See [Types](#types). |
| `WatchUncommitedUpdates` | `Boolean` | `False` | Track whether the transaction has uncommitted changes, see `HasUncommitedUpdates`. |
| `CSMonitorSupport` | `TCSMonitorSupport` | | Monitoring support. Only when compiled with `CSMonitor`. |

## Transaction parameters

`TRParams` holds one parameter per line. Names are case-insensitive, and the prefix `isc_tpb_` is optional (`read_committed` and `isc_tpb_read_committed` are the same). Blank lines are ignored. The list is converted to a transaction parameter buffer on every start.

With an empty list no parameters are sent, and the server uses its defaults. A name that is neither in the table below nor in the list of unsupported names raises `EFIBClientError`. `TRParams` cannot be changed while the transaction is active.

Each line is split at the first `=` without trimming the name, so no spaces are allowed around `=`: `lock_timeout = 5` raises `EFIBClientError` (unknown parameter). The conversion also rewrites the lines of `TRParams` with leading and trailing blanks removed.

| Parameter | Group | Meaning |
|-----------|-------|---------|
| `concurrency` | Isolation | Snapshot isolation. |
| `consistency` | Isolation | Table stability. |
| `read_committed` | Isolation | Read committed. Combine with `rec_version` or `no_rec_version`. |
| `rec_version` | Record version | With `read_committed`: read the latest committed version of a record that has a pending change. |
| `no_rec_version` | Record version | With `read_committed`: wait for, or fail on, a record that has a pending change. |
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

## Types

| Type | Values |
|------|--------|
| `TTransactionAction` | `TARollback`, `TARollbackRetaining`, `TACommit`, `TACommitRetaining` |
| `TTransactionState` | `tsActive`, `tsClosed`, `tsDoRollback`, `tsDoRollbackRetaining`, `tsDoCommit`, `tsDoCommitRetaining`; the `tsDo...` values are set while the transaction is ending |
| `TpFIBTrEventType` | `tetBeforeStartTransaction`, `tetAfterStartTransaction`, `tetBeforeEndTransaction`, `tetAfterEndTransaction`, `tetBeforeDestroy`; selects the list for `AddEvent` and `AddEndEvent` |
| `TEndTrEvent` | `procedure(EndingTR: TFIBTransaction; Action: TTransactionAction; Force: Boolean) of object`; `Force` is `True` when the end cannot be refused (timeout, disconnect, destroy) |

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

## Methods

### Starting and ending

| Name | Description |
|------|-------------|
| `StartTransaction` | Start the transaction on all its databases with one call. Raises if it is already active (`CheckNotInTransaction`) or has no database. At run time, a database that is not connected raises, unless `AutoReconnect` is `True`. With `AutoReconnect`, the database connects first; if that fails, no error is raised and the transaction stays inactive. |
| `Commit` | Commit and end. |
| `CommitRetaining` | Commit and keep the transaction and its cursors open. |
| `Rollback` | Roll back and end. |
| `RollbackRetaining` | Roll back and keep the transaction open. |

When the transaction is not active, each of these methods first calls `CheckInTransaction`. At run time it raises, unless every database has `AutoReconnect` set to `True`; then a transaction is started and ended at once. At design time a transaction is always started first.

*Protected:* `EndTransaction(Action, Force)` is virtual and does the work of all four methods; `TpFIBTransaction` overrides it. `Force` set to `True` ends the transaction even when the server call fails.

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
| `IsReadCommitedTransaction` | `True` if `TRParams` contains `read_committed`. |
| `CloseAllQueryHandles` | Release the statement handle of every attached `TFIBQuery`. |
| `OnDatabaseDisconnecting(Db)` | Called by the database before it disconnects. Ends an active transaction with `TimeoutAction`, forced; a retaining action is replaced by its plain variant. |

### Event lists

| Name | Description |
|------|-------------|
| `AddEvent(Event, EventType)` / `RemoveEvent(Event, EventType)` | Register or remove a `TNotifyEvent` handler. `EventType` is `tetBeforeStartTransaction`, `tetAfterStartTransaction`, or `tetBeforeDestroy`. Other values raise an assertion. |
| `AddEndEvent(Event, EventType)` / `RemoveEndEvent(Event, EventType)` | Register or remove a `TEndTrEvent` handler. `EventType` is `tetBeforeEndTransaction` or `tetAfterEndTransaction`. |

Unlike a published event, these lists take any number of handlers. Components that need to react to a transaction use them.

## Events

| Name | Description |
|------|-------------|
| `OnTimeout` | `Timeout` elapsed and `TimeoutAction` was applied; called after the action. With a retaining action the transaction stays active. |

## See also

- [TFIBDatabase](TFIBDatabase.md)
- [TFIBQuery](TFIBQuery.md), [TFIBDataSet](TFIBDataSet.md)
- [Transactions](../guide/transactions.md)
- [Timeouts](../guide/timeouts.md)
