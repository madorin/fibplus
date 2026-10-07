# Transactions

Every statement of a Firebird or InterBase database runs inside a transaction. In FibPlus a `TFIBTransaction` component holds the transaction parameters, starts and ends the transaction, and is assigned to the queries and datasets that run in it. This article shows how to choose the isolation level, how to commit and roll back, how queries and datasets start transactions on their own, and what happens to open cursors when a transaction ends.

For the members of the classes see [TFIBTransaction](../reference/TFIBTransaction.md) and [TpFIBTransaction](../reference/TpFIBTransaction.md).

## Requirements

None beyond the usual connection. `lock_timeout` needs *Firebird 2.1+*; on older servers the number is ignored (see [Transaction parameters](../reference/TFIBTransaction.md#transaction-parameters)).

## Connecting the components

The samples use the components `Database`, `Transaction`, and `Query`.

```delphi
Transaction.DefaultDatabase := Database;
Query.Database := Database;
Query.Transaction := Transaction;
```

`Database.DefaultTransaction` names the transaction that `TFIBDatabase.StartTransaction`, `Commit`, `Rollback`, `CommitRetaining`, and `RollbackRetaining` act on. A query or dataset created at run time, with no `Transaction` yet, takes `Database.DefaultTransaction` when you assign its `Database`. A dataset that has no separate update transaction takes `Database.DefaultUpdateTransaction` in the same way.

## Starting a transaction

Start it yourself:

```delphi
Transaction.StartTransaction;
```

or let the queries and datasets start it when they need it:

| Component | Option | Default |
|-----------|--------|---------|
| `TFIBQuery` | `qoStartTransaction` in `Options` | off for a query created at run time |
| `TFIBDataSet` | `poStartTransaction` in `Options` | on for a dataset created at run time |

With the option on, `ExecQuery` (and `Open` of a dataset) starts `Transaction` when it is not active. With the option off, running a statement in an inactive transaction raises `EFIBClientError`, unless every database of the transaction has `AutoReconnect` set to `True`; then the transaction is started for you. The same option starts the dataset's `UpdateTransaction` before a change is sent to the server.

`TFIBTransaction.StartTransaction` raises when the transaction is already active. `TpFIBTransaction.StartTransaction` does nothing in that case.

## Choosing the isolation level

The isolation level, the access mode, and the lock behavior are lines in `TRParams`, one parameter per line. Names are case-insensitive, and the `isc_tpb_` prefix is optional. Write no spaces around `=`.

| Need | `TRParams` |
|------|------------|
| Read the latest committed data, wait for locks | `read_committed`, `rec_version`, `wait` |
| Read the latest committed data, fail on a conflict | `read_committed`, `rec_version`, `nowait` |
| A stable snapshot for the whole transaction | `concurrency` |
| Table stability | `consistency` |
| Read only (reports, lookups) | add `read` |
| Wait for a lock at most 5 seconds, *Firebird 2.1+* | add `lock_timeout=5` |

The full list, including table reservation, is in [Transaction parameters](../reference/TFIBTransaction.md#transaction-parameters). For what each isolation level means on the server, see the Firebird documentation.

```delphi
Transaction.TRParams.Clear;
Transaction.TRParams.Add('read_committed');
Transaction.TRParams.Add('rec_version');
Transaction.TRParams.Add('read');
```

This sample is for a `TFIBTransaction`. A `TpFIBTransaction` replaces these lines at every start unless `TPBMode` is `tpbDefault`, see below.

`TRParams` cannot change while the transaction is active. The parameters are converted when the transaction starts, so a change takes effect with the next start.

### TpFIBTransaction and TPBMode

`TpFIBTransaction` has a `TPBMode` property, and its default is `tpbReadCommitted`. In that mode, and in `tpbRepeatableRead`, every `StartTransaction` clears `TRParams` and writes its own lines. The lines for each mode are in [Transaction mode](../reference/TpFIBTransaction.md#transaction-mode).

Set `TPBMode` to `tpbDefault` before you set `TRParams`, otherwise your lines are lost at the first start:

```delphi
Transaction.TPBMode := tpbDefault;
Transaction.TRParams.Text := 'read_committed'#13#10'rec_version'#13#10'wait';
```

## Commit and rollback

`Commit` and `Rollback` end the transaction. `CommitRetaining` and `RollbackRetaining` keep it active; see [Starting and ending](../reference/TFIBTransaction.md#starting-and-ending). The usual pattern:

```delphi
Transaction.StartTransaction;
try
  Query.ExecQuery;
  Transaction.Commit;
except
  Transaction.Rollback;
  raise;
end;
```

Calling `Commit` or `Rollback` on an inactive transaction raises `EFIBClientError`, unless every database has `AutoReconnect` set to `True`; then a transaction is started and ended at once. Test `Transaction.InTransaction` first when you cannot be sure.

An SQL `COMMIT` or `ROLLBACK` statement executed with `ExecQuery` calls `Transaction.Commit` or `Transaction.Rollback`, so cursors and datasets are affected in the same way.

### Retaining

A retaining operation ends the unit of work but keeps the transaction handle. FibPlus does not close the queries and datasets of the transaction for it (see [Open cursors](#open-cursors-and-the-end-of-a-transaction)), so it is the way to save changes without closing the datasets that show them. A later `Commit` or `Rollback` is still needed to end the transaction.

### Savepoints

A savepoint lets you undo part of an active transaction.

```delphi
Transaction.StartTransaction;
Transaction.SetSavePoint('BeforeImport');
try
  Query.ExecQuery;
except
  Transaction.RollBackToSavePoint('BeforeImport');
  raise;
end;
Transaction.ReleaseSavePoint('BeforeImport');
```

## Automatic commit

### Queries

`qoAutoCommit` in `TFIBQuery.Options` commits the transaction when the statement is done:

- after `ExecQuery` of a statement that has no cursor;
- when the cursor of a `SELECT` is closed. It is closed by `Close`, by a new `ExecQuery`, by a change of `SQL`, when the query is destroyed, and automatically when `Next` reaches the end of the rows.

```delphi
Query.Options := [qoStartTransaction, qoAutoCommit];
Query.SQL.Text := 'UPDATE ACCOUNT SET BALANCE = BALANCE - :Amount WHERE ID = :ID';
Query.Params.ByName['Amount'].AsCurrency := 10;
Query.Params.ByName['ID'].AsInteger := 1;
Query.ExecQuery; // started and committed here
```

The commit is a `Commit`, or a `CommitRetaining` when `Transaction.TimeoutAction` is `TACommitRetaining`. It applies only while the transaction is active and not already ending.

The commit ends the **whole transaction**, not only the statement. Every other cursor in the same transaction closes with it. Do not give `qoAutoCommit` to a query that shares its transaction with queries or datasets that stay open.

### Datasets

`AutoCommit` of a dataset commits `UpdateTransaction` after each `Post` and `Delete` is sent to the server. At the end of `ApplyUpdates` it commits, unless some rows were skipped. It uses `CommitRetaining` when `UpdateTransaction` is the same component as `Transaction`, or when its `TimeoutAction` is `TACommitRetaining`; otherwise it uses `Commit`. Without `AutoCommit`, nothing is committed for you: call `Commit` or `CommitRetaining` yourself.

## Reading and updating with two transactions

A dataset has a `Transaction` for the `SELECT` and an `UpdateTransaction` for the insert, update, and delete statements. When you use two components, a commit of the updates does not touch the cursor that the grid is showing:

```delphi
ReadTransaction.TRParams.Text := 'read_committed'#13#10'rec_version'#13#10'read';
WriteTransaction.TRParams.Text := 'read_committed'#13#10'rec_version'#13#10'write'#13#10'nowait';
DataSet.Transaction := ReadTransaction;
DataSet.UpdateTransaction := WriteTransaction;
DataSet.AutoCommit := True;
DataSet.Open;
```

The components in the sample are `ReadTransaction`, `WriteTransaction`, and a `TpFIBDataSet` named `DataSet`; set `TPBMode` to `tpbDefault` on both if they are `TpFIBTransaction` components. The statement that refreshes a row after `Post` runs in `Transaction` by default. `RefreshTransactionKind` set to `tkUpdateTransaction` runs it in `UpdateTransaction`, which sees the changes the dataset has made even before they are committed.

`TpFIBDataSet.HasUncommitedChanges` is `True` after the dataset sent a change to the server and stays so until `UpdateTransaction` is committed or rolled back, including the retaining variants. `HaveRollbackedChanges` records that such changes were rolled back; it is cleared when the dataset closes or its SQL changes.

## Open cursors and the end of a transaction

A cursor is the open result set of a `SELECT`. The server closes the cursors of a transaction when it ends. FibPlus closes its own cursors first, so the components stay in a consistent state. What the components do depends on the way the transaction ends.

### Commit and Rollback

`Commit` and `Rollback` close the cursors of every query and dataset attached to the transaction before the call goes to the server. A dataset raises its `TransactionEnding` event first, also for the retaining operations; it closes the cursor only on commit and rollback.

| Component | What happens |
|-----------|--------------|
| `TFIBQuery` | An open cursor is closed. |
| `TFIBDataSet` | The dataset closes (`Active` becomes `False`). A grid on it goes empty. |
| `TFIBDataSet` with `poDontCloseAfterEndTransaction` in `Options`, or with `CachedUpdates` | The dataset fetches all remaining rows, closes only the cursor, and stays open on the rows it holds. |

The second row of the dataset case has a price. `FetchAll` reads the whole result into memory before the transaction ends, so use it only for result sets that fit. At design time the dataset always closes. See [Options](../reference/TpFIBDataSet.md#options) for `poDontCloseAfterEndTransaction`.

A plain `TFIBQuery` has no setting to keep its cursor. Read the rows before you end the transaction.

### Retaining operations

`CommitRetaining` and `RollbackRetaining` do not close queries or datasets in FibPlus. The components are notified, but they close their cursors only for `Commit` and `Rollback`. `HasUncommitedUpdates` of the transaction (needs `WatchUncommitedUpdates`) is reset for the retaining operations as well.

### Automatic end

Other events end a transaction, and they follow the rules above, with the action set by `TimeoutAction`:

| Event | Action |
|-------|--------|
| `Timeout` of the transaction elapses | `TimeoutAction`, forced, then `OnTimeout`. A retaining action keeps the cursors. |
| The database disconnects | `TimeoutAction`, forced; a retaining action is replaced by its plain variant, so the cursors close. |
| The transaction component is destroyed | The same as for a disconnect. |

The default is `TARollback`. Choose `TACommit` when the work in the transaction must be saved at an automatic end. A dataset with `poDontCloseAfterEndTransaction` also fetches all rows before its database disconnects. See [Timeouts](timeouts.md#client-side-timeouts) for the timers.

### Running an open query again

`ExecQuery` closes the query's own open cursor before it starts. With `qoAutoCommit` that close is a commit, so a second `ExecQuery` on an open query commits the transaction before it runs.

## Errors and pitfalls

- **A grid goes empty after `Commit`.** The dataset closed with its transaction. Use `CommitRetaining`, a separate `UpdateTransaction` with `AutoCommit`, or `poDontCloseAfterEndTransaction`.
- **`qoAutoCommit` closes other cursors.** It commits the whole transaction. Give such a query its own transaction.
- **A query is closed after the last row.** With `qoAutoCommit` or `qoFreeHandleAfterExecute`, `Next` closes the cursor when it passes the last row, so `Open` is `False` and `Eof` is `True` afterwards.
- **Lost `TRParams` lines.** `TpFIBTransaction` with `TPBMode` other than `tpbDefault` replaces them at every start.
- **Spaces in `TRParams`.** `lock_timeout = 5` raises `EFIBClientError`; write `lock_timeout=5`.
- **`no_savepoint`.** It shares its code with `lock_timeout`. A bare `no_savepoint` is sent as `lock_timeout=10` on *Firebird 2.1+*; do not use it for another purpose.
- **Inactive transaction.** Without `qoStartTransaction` or `poStartTransaction`, a statement raises `EFIBClientError` ("Transaction is not active"). Start the transaction first, or set the option.
- **Uncommitted work at an automatic end.** The default `TimeoutAction` is `TARollback`; a disconnect or a destroyed transaction component rolls back what you did not commit.
- **Silent no-start with `AutoReconnect`.** When the connection cannot be made, `StartTransaction` returns without an error and the transaction stays inactive. Check `InTransaction` when `AutoReconnect` is on.

## See also

- [TFIBTransaction reference](../reference/TFIBTransaction.md)
- [TpFIBTransaction reference](../reference/TpFIBTransaction.md)
- [TFIBQuery reference](../reference/TFIBQuery.md#options)
- [TFIBDataSet reference](../reference/TFIBDataSet.md)
- [Timeouts](timeouts.md)
- [Queries and parameters](queries-and-parameters.md)
- [Datasets and caching](datasets-and-caching.md)
