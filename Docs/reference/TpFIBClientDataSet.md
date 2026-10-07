# TpFIBClientDataSet

A `TClientDataSet` for the client side of a multi-tier application whose server publishes a [TpFIBDataSet](TpFIBDataSet.md) through a provider. It adds parameterized open, transaction control through the application server, and a `BCD` field class that keeps the scale of `NUMERIC` and `DECIMAL` values. The unit also holds `TpFIBDataSetProvider`, the provider for the server side.

| | |
|---|---|
| Unit | `pFIBClientDataSet` |
| Inherits from | `TClientDataSet` |
| Related classes | `TpFIBDataSetProvider` (inherits from `TDataSetProvider`), `TpFIBClientBCDField` (inherits from `TBCDField`) |

```delphi
ClientDataSet.ProviderName := 'CustomerProvider';
ClientDataSet.OpenWP([42]);
// edit rows, then
if ClientDataSet.ApplyUpdates(0) = 0 then
  ClientDataSet.Commit
else
  ClientDataSet.RollBack;
```

The sample uses a `TpFIBClientDataSet` named `ClientDataSet`, connected to an application server that exports a provider named `CustomerProvider`.

Guides: [Datasets and caching](../guide/datasets-and-caching.md).

## Published properties

`TpFIBClientDataSet` adds none. The published properties are those of `TClientDataSet`.

## Run-time properties

`TpFIBClientDataSet` adds none. It implements the `ISQLObject` interface of the library (`pFIBInterfaces`), so another FibPlus object can take parameter values from it, as it does from a dataset. The interface methods are protected.

## Methods

| Name | Description |
|------|-------------|
| `OpenWP(ParamValues)` | Assigns `ParamValues` to `Params` in order, then calls `Open`. Extra values are ignored; parameters without a value keep theirs. |
| `Commit` | Asks the application server to commit the transaction of the provider's dataset. Does nothing when `AppServer` is not assigned. |
| `RollBack` | Asks the application server to roll that transaction back. Does nothing when `AppServer` is not assigned. |
| `TransactionIsActive` | Calls the application server with the command `FIB$GET_INTRANSACTION` and returns the result. Returns `False` when `AppServer` is not assigned. |

`Commit` and `RollBack` call `AppServer.AS_Execute` with the command text `FIB$COMMIT` or `FIB$ROLLBACK` and the current `ProviderName`. The provider's dataset must be a `TpFIBDataSet`: it recognizes these commands and runs `UpdateTransaction.Commit` or `UpdateTransaction.RollBack`.

The three transaction methods send a command text to the provider. The standard `TDataSetProvider` accepts a command text from a client only when `poAllowCommandText` is in the provider's `Options`; otherwise it raises an error. This rule comes from the standard provider, not from FibPlus.

## TpFIBClientBCDField

`TpFIBClientDataSet` creates this field class for `ftBCD` fields (`GetFieldClass`). The field is also registered by the component package. It holds the value as an `Int64` scaled by `Size`.

| Name | Type | Description |
|------|------|-------------|
| `AsInt64` | `Int64` | Value as an integer; with a non-zero `Size` the value is rounded. |
| `AsExtended` | `Extended` | Value as a floating-point number. |
| `AsComp` | `Comp` | Value as `Comp`. Compiled only when `NO_USE_COMP` is not defined; `FIBPlus.inc` defines it, so the property is absent in the default configuration. |
| `Value` | `Extended` | Same as `AsExtended`. |

`AsVariant` returns an `Int64` when `Size` is `0`, a `Currency` when `Size` is `4`, and an `Extended` otherwise. `Assign` takes the value from another `TField`, and clears the field when the source is `nil`.

## TpFIBDataSetProvider

The provider for the server side. It replaces the resolver of `TDataSetProvider` and the way the provider finds the record to change. When the key has several fields, `BCD` fields with a scale other than 4 are compared as strings. It has no published properties of its own; use it in place of `TDataSetProvider` and set `DataSet` to a [TpFIBDataSet](TpFIBDataSet.md).

| Name | Visibility | Description |
|------|------------|-------------|
| `CreateResolver` | protected | Returns an internal resolver for the dataset when `ResolveToDataSet` is `True`; otherwise a descendant of `TSQLResolver` that adds nothing. |
| `FindRecord(Source, Delta, UpdateMode)` | protected | Locates the changed row in `Source`. The fields used depend on `UpdateMode`: `upWhereKeyOnly` uses fields with `pfInKey` in `ProviderFlags`; `upWhereAll` uses fields with `pfInWhere`; `upWhereChanged` uses fields with `pfInKey` and fields that have a new value. Skips `BLOB`, `bytes`, and object fields. Raises a database error when no fields are selected. |
| `UpdateRecord(Source, Delta, BlobsOnly, KeyOnly)` | protected | Copies the values of `Source` back into `Delta`. With `KeyOnly`, the first lookup uses `upWhereKeyOnly`, otherwise the provider's `UpdateMode`. With `BlobsOnly`, only `BLOB` fields whose new value is null are copied. Raises `SRecordChanged` when the first lookup or the second lookup (by key only) fails. |

The internal resolver applies each change to the dataset: an insert appends and posts a row; an update locates the row, edits, and posts it; a delete locates the row and deletes it. When the row cannot be found it raises the database error `SRecordChanged` (record changed by another user). A failure while posting cancels the edit and re-raises the exception.

## See also

- [TpFIBDataSet](TpFIBDataSet.md), [TFIBDataSet](TFIBDataSet.md)
- [Datasets and caching](../guide/datasets-and-caching.md)
