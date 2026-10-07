# TpFIBUpdateObject

An extra statement that a [TpFIBDataSet](TpFIBDataSet.md) runs when it posts an insert, an update, or a delete. Use it to change other tables or call a procedure in the same step as the dataset's own statement. An update object has an `SQL` text like any query and is attached to one dataset.

| | |
|---|---|
| Unit | `pFIBQuery` |
| Inherits from | [TpFIBQuery](TpFIBQuery.md) |

This page lists only what `TpFIBUpdateObject` adds or changes. The other members are described in [TpFIBQuery](TpFIBQuery.md) and [TFIBQuery](TFIBQuery.md).

The example writes an audit row after every update of `DataSet`. It uses the components `DataSet` (a `TpFIBDataSet`) and `AuditObject` (a `TpFIBUpdateObject`). `AuditObject` takes `Database` and `Transaction` from `DataSet` when `DataSet` is assigned. The parameters `OLD_ID` and `NEW_NAME` are filled from the record, see [Parameters](#parameters).

```delphi
AuditObject.SQL.Text :=
  'INSERT INTO AUDIT (CUSTOMER_ID, NAME) VALUES (:OLD_ID, :NEW_NAME)';
AuditObject.KindUpdate := ukModify;
AuditObject.ExecuteOrder := oeAfterDefault;
AuditObject.DataSet := DataSet;
```

Guides: [Datasets and caching](../guide/datasets-and-caching.md).

## Published properties

`TpFIBUpdateObject` publishes everything that [TpFIBQuery](TpFIBQuery.md#published-properties) publishes, and these:

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `DataSet` | `TFIBDataSet` | | Dataset that runs the object. Must be a `TpFIBDataSet`, otherwise an exception is raised. Assigning it registers the object with the dataset and copies `Database` and `Transaction` from the dataset when they are not set. |
| `KindUpdate` | `TUpdateKind` | `ukModify` | Operation the object belongs to: `ukModify`, `ukInsert`, or `ukDelete`. |
| `ExecuteOrder` | `TFIBOrderExecUO` | `oeBeforeDefault` | Whether the object runs before or after the dataset's own statement, see [Types](#types). |
| `OrderInList` | `Integer` | | Position among the objects of the same `KindUpdate`. Objects with a lower value run first. |
| `Active` | `Boolean` | `True` | When `False`, the dataset skips the object. |

## Types

`TFIBOrderExecUO` is the position of the object relative to the dataset's own statement:

| Value | Meaning |
|-------|---------|
| `oeBeforeDefault` | Runs before the `INSERT`, `UPDATE`, or `DELETE` statement of the dataset. |
| `oeAfterDefault` | Runs after it. |

## Methods

| Name | Description |
|------|-------------|
| `Apply` | Runs the update objects of `DataSet` for the current record, see [Running by hand](#running-by-hand). |
| `ChangeOrderInList(NewOrder)` | Sets `OrderInList` without re-registering the object. Called by the dataset when it renumbers its list; for internal use. |

## How a dataset uses update objects

The order of execution (before the dataset's own statement, the statement, after it), the skip rule for an empty `SQL` or `No Action`, the read-back of returned rows, and the effect on `CanEdit`, `CanInsert`, and `CanDelete` are described in [TpFIBDataSet](TpFIBDataSet.md#update-objects). `ApplyUpdates` runs the objects through the same code as a direct post or delete.

Two points are specific to the object:

- When the dataset's own `DeleteSQL` starts with `No Action`, a delete runs no update object at all, before or after.
- The `Transaction` copied by `DataSet` is the `Transaction` of the dataset, not its `UpdateTransaction`. The dataset starts its update transaction before an object runs, when needed.

With `AutoUpdateOptions.SeparateBlobUpdate`, the dataset creates its own update object with `oeAfterDefault` for the `BLOB` columns. Its `KindUpdate` follows the operation: `ukInsert` while an insert is posted, `ukModify` for an update.

### Parameters

For a direct post, a delete, or `ApplyUpdates`, parameter values come from the record. The name of a parameter decides which value is used:

| Parameter name | Value |
|----------------|-------|
| `OLD_Field` | `Field` before the change |
| `NEW_Field` | `Field` after the change |
| `Field` | `Field` of the current record |
| `MAS_Field` | `Field` of the current record of the master dataset (`DataSource.DataSet`) |

The prefixes are case-insensitive.

### Provider path

`TpFIBDataSet.PSUpdateRecord`, used when the dataset serves a [TpFIBDataSetProvider](TpFIBClientDataSet.md#tpfibdatasetprovider), also runs update objects, with these differences:

- An object runs when it is `Active`, its `ExecuteOrder` matches, and its `SQL` is not empty. The text `No Action` is not tested.
- Only the parameters `Field`, `NEW_Field`, and `OLD_Field` are filled. `MAS_Field` is not supported.
- No returned row is read back.
- When `OnUpdateRecord` is assigned, the update objects are not run.

### Running by hand

`Apply` does nothing when the object is not `Active`, has no `DataSet`, or has an empty `SQL`. Otherwise it calls the dataset to run **all** its update objects with the same `KindUpdate` and `ExecuteOrder` as this object for the active record, not this object alone.

## See also

- [TpFIBQuery](TpFIBQuery.md), [TFIBQuery](TFIBQuery.md)
- [TpFIBDataSet](TpFIBDataSet.md), [TFIBDataSet](TFIBDataSet.md)
- [Datasets and caching](../guide/datasets-and-caching.md)
