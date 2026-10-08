# TpFIBTransaction

The transaction component to use in applications. It adds to [TFIBTransaction](TFIBTransaction.md) a transaction mode that sets the parameters, named transaction kinds saved at design time, and events around starting and ending the transaction and around the queries that run in it. This page describes only the additions; for everything else see `TFIBTransaction`.

| | |
|---|---|
| Unit | `pFIBDatabase` |
| Inherits from | `TFIBTransaction` |

The sample uses the components `Database` (`TpFIBDatabase`), `Transaction` (`TpFIBTransaction`), and `Query`. It runs queries in a repeatable read transaction.

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

Guides: [Transactions](../guide/transactions.md), [Events and monitoring](../guide/events-and-monitoring.md).

## Published properties

Only the properties that `TpFIBTransaction` adds or changes. The other published properties of `TFIBTransaction` are listed on its page.

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `TPBMode` | `TTPBMode` | `tpbReadCommitted` | Chooses the transaction parameters, see [Transaction mode](#transaction-mode). At design time the initial value of a component dropped on a form comes from `DefTPBMode` in `pFIBProps`. |
| `TRParams` | `TStrings` | | Replaced at every start unless `TPBMode` is `tpbDefault`, see [Transaction mode](#transaction-mode). Stored in the form only when `TPBMode` is `tpbDefault`. For the parameter names see [Transaction parameters](TFIBTransaction.md#transaction-parameters). |
| `UserKindTransaction` | `string` | `NoUserKind` | Name of a transaction kind, see [Transaction kinds](#transaction-kinds). Stored in the form only when it is not `NoUserKind`. |
| `About` | `string` | | Library version text. Writing is ignored and the value is not stored. |

Events are listed in [Events](#events).

## Types

| Type | Definition |
|------|------------|
| `TTPBMode` | `tpbDefault`, `tpbReadCommitted`, `tpbRepeatableRead`, `tpbReadConsistency` |
| `TOnSQLExecute` | `procedure(Query: TFIBQuery; SQLType: TFIBSQLTypes) of object` |

`TEndTrEvent` and `TTransactionAction` are described in [TFIBTransaction](TFIBTransaction.md#types).

## Transaction mode

`TPBMode` decides where the transaction parameters come from.

| Value | `TRParams` at `StartTransaction` |
|-------|----------------------------------|
| `tpbDefault` | Used unchanged. |
| `tpbReadCommitted` | Replaced by `write`, `isc_tpb_nowait`, `read_committed`, `rec_version`. |
| `tpbRepeatableRead` | Replaced by `write`, `isc_tpb_nowait`, `concurrency`. |
| `tpbReadConsistency` | Replaced by `write`, `isc_tpb_nowait`, `read_committed`, `read_consistency`. *Firebird 4+*: on an older server `StartTransaction` raises `EFIBClientError`. |

In the other modes `TRParams` is cleared and filled again on every start, so added lines are lost. To use custom parameters, set `TPBMode` to `tpbDefault`. See [Transaction parameters](TFIBTransaction.md#transaction-parameters) for the names.

On *Firebird 4+* with the default server setting `ReadConsistency = 1`, every read committed transaction runs in read consistency mode, so `tpbReadCommitted` behaves like `tpbReadConsistency` there. The two differ only when the database has `ReadConsistency = 0`.

## Transaction kinds

A transaction kind is a named set of parameters saved in the Windows registry by the design-time tools, under `HKEY_CURRENT_USER\Software\FIBC_Software\Transation Kinds`. Each entry has a `Name` value and a `Params` value.

Setting `UserKindTransaction` at design time, not while the form loads, looks up the entry with that name. When it exists, `TPBMode` becomes `tpbDefault` and `TRParams` takes the saved `Params` text. At run time, and for the name `NoUserKind`, the setter only stores the name. Without registry support in the build (`NO_REGISTRY`) it only stores the name.

## Run-time properties

| Name | Type | Description |
|------|------|-------------|
| `FIBDataSets[Index]` | `TFIBCustomDataSet` | Dataset attached to this transaction, by index. Each dataset is counted once. |
| `FIBQueries[Index]` | `TFIBQuery` | Query attached to this transaction that does not belong to a dataset, by index. |

## Methods

| Name | Description |
|------|-------------|
| `StartTransaction` | Override. Does nothing when the transaction is active. Otherwise applies `TPBMode`, calls the start events around the start, and starts the transaction as `TFIBTransaction.StartTransaction` does. |
| `FIBDataSetsCount`, `FIBQueryCount` | Number of entries of `FIBDataSets` and `FIBQueries`. |
| `DoOnSQLExec(Query, Kind)` | Override. Called by a query attached to the transaction; runs the base behavior, then `BeforeSQLExecute`, `AfterSQLExecute`, or `AfterFirstFetch`. |

*Protected:* `EndTransaction(Action, Force)` is overridden. It calls the end events around `inherited`, so the events run for `Commit`, `Rollback`, the retaining variants, a timeout, a disconnect, and destroying the component.

## Events

| Name | Description |
|------|-------------|
| `BeforeStart` | Before the transaction starts, after `TPBMode` was applied. |
| `AfterStart` | After `StartTransaction` of the base class returned. Also runs when the start was skipped without an error (see `AutoReconnect` in [TFIBTransaction](TFIBTransaction.md#starting-and-ending)). |
| `BeforeEnd` | Before the transaction ends. `Action` and `Force` tell how. Runs before the check that the transaction is active, so it also runs for `Commit` or `Rollback` on an inactive transaction. |
| `AfterEnd` | After the transaction ended. |
| `BeforeSQLExecute` | A query attached to the transaction is about to run. `SQLType` is the statement type. |
| `AfterSQLExecute` | The query ran. |
| `AfterFirstFetch` | The first row of a query cursor was fetched. |

If `DefaultDatabase` is a [TpFIBDatabase](TpFIBDatabase.md#events), its transaction events run too. Before a start or end, the database event runs first, then the transaction event. After a start or end, the transaction event runs first, then the database event. The start events do not run when the transaction is already active.

## See also

- [TFIBTransaction](TFIBTransaction.md)
- [TpFIBDatabase](TpFIBDatabase.md)
- [Transactions](../guide/transactions.md)
