# Datasets and caching

A FibPlus dataset reads rows from the server on demand and keeps them in a record cache, so you can scroll in both directions without another round trip. This article shows how rows are fetched, how to refresh and change them, how `TpFIBDataSet` generates its own SQL, and how the query cache and the metadata cache work.

The samples use these components: `Database` (`TpFIBDatabase`), `Transaction` and `UpdateTransaction` (`TFIBTransaction`), `DataSet` (`TpFIBDataSet`), and in the master-detail sample `MasterDS` and `DetailDS` (`TpFIBDataSet`) and `MasterSource` (`TDataSource`). The fetching and refresh features belong to the base class [TFIBDataSet](../reference/TFIBDataSet.md). Generated SQL, update objects, and `ApplyUpdates` belong to [TpFIBDataSet](../reference/TpFIBDataSet.md).

## Open and fetch

```delphi
DataSet.Database := Database;
DataSet.Transaction := Transaction;
DataSet.SelectSQL.Text := 'SELECT ID, NAME, BALANCE FROM CUSTOMER ORDER BY NAME';
DataSet.Open;
```

The dataset reads a row from the server when a control or your code needs it, and stores the row in the record cache. With the standard cache, rows that were read once stay in the cache until the dataset closes. `AllFetched` is `True` when the server has no more rows.

| Task | Use |
|------|-----|
| Read every row right after `Open` | `poFetchAll` in `Options` |
| Read every remaining row now | `FetchAll` |
| Read a number of rows | `FetchNext(Count)`, which returns the number read |
| Change parameters and run the query again | `CloseOpen(False)` |

```delphi
DataSet.SelectSQL.Text := 'SELECT ID, NAME FROM CUSTOMER WHERE ID > :MinID';
DataSet.Params.ByName['MinID'].AsInteger := 100;
DataSet.Open;
// later
DataSet.Params.ByName['MinID'].AsInteger := 200;
DataSet.CloseOpen(False);
```

### Large result sets

The standard cache keeps every fetched row in memory. For a very large result set:

- `UniDirectional` reads forward only and keeps a window of `BufferChunks` rows.
- `CacheModelOptions.CacheModelKind := cmkLimitedBufferSize` keeps part of the rows and reads the rest with additional queries. It needs an `ORDER BY` clause and has other restrictions; see [Cache model](../reference/TFIBDataSet.md#cache-model).

### Statement timeouts and long fetches

A `SELECT` is cancelled by a statement timeout if its last row is not fetched in time, even when the dataset was opened long before. See [Timeouts](timeouts.md#select-statements-run-until-the-last-row).

## Refresh

| Goal | Use |
|------|-----|
| Re-read the current row | `Refresh`, which runs `RefreshSQL` |
| Re-read the whole result set and return to the current row | `FullRefresh`; it returns to the row only when `RefreshSQL` is not empty |
| Re-read the whole result set and go to a given row | `ReopenLocate('ID')` |
| Re-read the whole result set from the first row | `CloseOpen(False)` |

`RefreshSQL` is a query that returns one row. Its parameters are filled from the fields of the current row that have the same name:

```sql
SELECT ID, NAME, BALANCE FROM CUSTOMER WHERE ID = :ID
```

`Refresh` raises an error when `RefreshSQL` is empty and the dataset has rows. `TpFIBDataSet` can generate `RefreshSQL`, see [Generated SQL](#generated-sql).

These options of `Options` change when a row is refreshed:

- `poRefreshAfterPost` runs `RefreshSQL` after each `Post`, so that values set by triggers appear in the row. It needs a non-empty `RefreshSQL` and the standard cache. It is in the default options.
- `poRefreshAfterDelete` runs `RefreshSQL` after a delete, so it needs a non-empty `RefreshSQL` too. The row stays in the dataset if `RefreshSQL` still returns it.
- `poRefreshDeletedRecord` removes a row from the cache when a refresh finds no row on the server. It works with the standard cache only.

## Change data

A dataset sends a row change with one of three statements: `InsertSQL`, `UpdateSQL`, and `DeleteSQL`. `Insert`, `Edit`, and `Delete` are allowed when the matching statement exists. `TpFIBDataSet` also allows them when it writes the statements again for each post (`UpdateOnlyModifiedFields`, see [Generated SQL](#generated-sql)), when an active update object exists for the kind, or when `CachedUpdates` is on and `OnUpdateRecord` is assigned. `AllowedUpdateKinds` can forbid a kind.

### Statement parameters

A parameter takes the value of the field with the same name in the current row. A prefix chooses the version of the value:

| Parameter | Value |
|-----------|-------|
| `:NAME` | The current value of field `NAME` |
| `:NEW_NAME` | The current value of field `NAME` |
| `:OLD_NAME` | The value `NAME` had before the edit |

A parameter without a matching field takes the value of a parameter of `SelectSQL` with the same name. Use `OLD_` values in the `WHERE` clause, so that the statement finds the row even when the key was edited:

```sql
UPDATE CUSTOMER SET NAME = :NAME, BALANCE = :BALANCE WHERE ID = :OLD_ID
```

### Transactions and commit

The three statements run in `UpdateTransaction`; when you do not assign one, they use `Transaction`. `Transaction` reads the rows. Setting `Database` assigns `Database.DefaultUpdateTransaction` to `UpdateTransaction` when the database has one and the dataset has no separate update transaction yet.

With `AutoCommit := True`, the dataset commits `UpdateTransaction` after each change: `Commit` for a separate update transaction, `CommitRetaining` when `UpdateTransaction` is the same as `Transaction` or its `TimeoutAction` is `TACommitRetaining`. With `AutoCommit := False`, you commit yourself:

```delphi
DataSet.Edit;
DataSet.FieldByName('BALANCE').AsCurrency := 0;
DataSet.Post;
UpdateTransaction.Commit;
```

`HasUncommitedChanges` is `True` while changes were sent but not committed. Check it before you close a form or the application.

### Update objects

A `TpFIBUpdateObject` runs an extra statement when a row is inserted, updated, or deleted. Its `ExecuteOrder` is `oeBeforeDefault` or `oeAfterDefault`: it runs before or after the statement of the dataset. See [TpFIBUpdateObject](../reference/TpFIBUpdateObject.md).

### Errors while posting

`OnPostError` and `OnDeleteError` are the standard `TDataSetErrorEvent` events. They are called when sending the statement fails.

## Generated SQL

`TpFIBDataSet` can write `InsertSQL`, `UpdateSQL`, `DeleteSQL`, and `RefreshSQL` from `SelectSQL`. Set the table the dataset changes, and turn on `AutoReWriteSqls`:

```delphi
DataSet.SelectSQL.Text := 'SELECT ID, NAME, BALANCE FROM CUSTOMER ORDER BY NAME';
DataSet.AutoUpdateOptions.UpdateTableName := 'CUSTOMER';
DataSet.AutoUpdateOptions.AutoReWriteSqls := True;
DataSet.Open;
```

The dataset generates the statements after `Open`, at run time, when the text of `SelectSQL`, `UpdateTableName`, `KeyFields`, or `UseReturningFields` changed since the last generation. Setting `AutoReWriteSqls` alone, after the dataset was opened once, does not trigger it. Only empty statements are generated, unless `CanChangeSQLs` is `True`: then all four are replaced. Nothing is generated when no key field can be found. The statements use `NEW_` and `OLD_` parameters as described above.

| `AutoUpdateOptions` value | Meaning |
|---------------------------|---------|
| `UpdateTableName` | Table to change. Can include an alias. |
| `KeyFields` | Fields of the `WHERE` clause, separated by `;`. When empty, the dataset uses the primary key of the table; if the table has none, all its non-BLOB fields in the dataset. |
| `AutoReWriteSqls` | Generate the statements after `Open`. |
| `CanChangeSQLs` | Allow the dataset to replace statements that are not empty. |
| `UpdateOnlyModifiedFields` | Generate `INSERT` and `UPDATE` again for each post, see below. |
| `SeparateBlobUpdate` | Leave BLOB fields out of the generated `INSERT` and `UPDATE`; send them with a second `UPDATE` after the row. |
| `UseExecuteBlock` | With `CachedUpdates`, `ApplyUpdates` sends the changes in `EXECUTE BLOCK` batches of generated statements (at most 255 each) instead of running the statements of the dataset and its update objects. See [Applying cached updates](../reference/TpFIBDataSet.md#applying-cached-updates). |
| `UseReturningFields` | Add a `RETURNING` clause to the `INSERT` and `UPDATE` made with `AutoReWriteSqls`. |
| `UseRowsClause` | Add `ROWS 1` to generated `INSERT` and `UPDATE`. |

Members of the table that are in the dataset are included. Fields that come from other tables of a join, calculated fields, and computed columns are not. Computed columns are included only with `psCanEditComputedFields` in `PrepareOptions`. The dataset reads the table definition from the server; see [Metadata cache](#metadata-cache).

You can generate the statements yourself with `GenerateSQLs`, or get the text of one statement with `GenerateSQLText`.

### Only the changed fields

With `UpdateOnlyModifiedFields`, the dataset writes the `UPDATE` and `INSERT` again at each `Post`. The `UPDATE` sets only the fields that changed. The `INSERT` lists only the fields that are not null. The statements use the same `NEW_` and `OLD_` parameters. When no field of the table changed, nothing is sent.

The property is `True` only if `AutoReWriteSqls` and `CanChangeSQLs` are `True` when you set it, so set those first. The dataset generates the statements only when `KeyFields` and `UpdateTableName` are not empty.

```delphi
with DataSet.AutoUpdateOptions do
begin
  UpdateTableName := 'CUSTOMER';
  KeyFields := 'ID';
  AutoReWriteSqls := True;
  CanChangeSQLs := True;
  UpdateOnlyModifiedFields := True;
end;
```

In this mode, after `Open` only `RefreshSQL` and `DeleteSQL` are generated. `UseReturningFields` does not apply.

### Generators

`WhenGetGenID` makes the dataset fill a numeric key field from a generator when the field is null:

| `WhenGetGenID` | The dataset reads the generator |
|----------------|---------------------------------|
| `wgNever` (default) | Never |
| `wgOnNewRecord` | When the new row is created, so the key is visible while the user edits |
| `wgBeforePost` | When a new row is posted |

```delphi
with DataSet.AutoUpdateOptions do
begin
  KeyFields := 'ID';
  GeneratorName := 'GEN_CUSTOMER_ID';
  WhenGetGenID := wgBeforePost;
end;
```

`GeneratorStep` is the increment, `1` by default. When you set `UpdateTableName` while `GeneratorName` is empty and `WhenGetGenID` is not `wgNever`, the dataset sets `GeneratorName` to `GEN_` plus the table name plus `_ID`. The prefix and suffix are the variables `DefPrefixGenName` and `DefSufixGenName` in the unit `pFIBProps`.

## Cached updates

With `CachedUpdates := True`, the dataset keeps changes in the record cache and sends them when you call `ApplyUpdates`. Set it while the dataset is closed. It is not allowed with `cmkLimitedBufferSize`.

```delphi
DataSet.CachedUpdates := True;
DataSet.Open;
// the user edits, inserts, and deletes rows
if DataSet.UpdatesPending then
begin
  DataSet.ApplyUpdates;
  UpdateTransaction.Commit;
end;
```

`ApplyUpdates` posts a pending edit, then sends the changed rows in cache order. A row that the dataset sends is marked as applied. With `AutoCommit` set, the update transaction is committed after each inserted or modified row, and once more at the end when no row was skipped; if a later row fails, the earlier rows are already committed. Without `AutoCommit`, you commit. `CancelUpdates` reverts all changes, `RevertRecord` the current row. `CachedUpdateStatus` returns the status of the current row. `CountUpdatesPending` returns the number of changed rows. `UpdateRecordTypes` limits which rows are visible, for example only changed ones.

Three events control `ApplyUpdates`: `OnUpdateRecord`, `OnUpdateError`, and `AfterUpdateRecord`. `OnUpdateRecord` is called for each pending row before the dataset sends it, so you can send the row yourself. `OnUpdateError` is called when sending raises `EFIBError`, and lets you fail, abort, skip, or retry the row. The actions and their effects are in [Applying cached updates](../reference/TpFIBDataSet.md#applying-cached-updates); the event signatures are in [Updates](../reference/TFIBDataSet.md#updates).

A row that `OnUpdateRecord` handled itself keeps its cached status, so it stays pending: the next `ApplyUpdates` calls the handler for it again. Call `CommitUpdToCach` after the transaction commits; it marks all pending rows as applied without sending anything. `UpdatesPending` can be `False` while such rows are still pending.

With `AutoCommit` and `CachedUpdates` both on, each `Post` and each `Delete` is applied and committed at once, so changes do not stay in the cache.

## Master-detail

A detail dataset takes its parameters from the current row of a master dataset. Assign the master through a `TDataSource` and name the parameters like the master fields:

```delphi
MasterSource.DataSet := MasterDS;
DetailDS.SelectSQL.Text := 'SELECT ID, AMOUNT FROM INVOICE WHERE CUSTOMER_ID = :ID';
DetailDS.DataSource := MasterSource;
DetailDS.DetailConditions := [dcForceOpen];
MasterDS.Open;
```

The detail reopens when a master value that its parameters use changes. A parameter named `MAS_ID` is matched to the master field `ID` as well. `DetailConditions` controls opening, closing, and refreshing, for example `dcWaitEndMasterScroll` waits until the master stops scrolling. The rules and the table of conditions are in [Master-detail](../reference/TFIBDataSet.md#master-detail).

## Save and load the record cache

`TpFIBDataSet` can write the rows of the cache to a file or a stream and read them back:

```delphi
DataSet.SaveToFile('customers.cache');
// later, in the same or another run
DataSet.LoadFromFile('customers.cache');
```

`SaveToFile` reads all remaining rows first. `LoadFromFile` opens the dataset with the rows from the file and moves to the first row. It does nothing at design time. It raises an error when the file is not a cache file or has an older format, or when the field count, sizes, or types differ from the dataset. The optional `AddInfo` string is stored in the file and returned by `LoadFromFile`.

## Query cache

FibPlus runs many small internal statements: reading metadata, `GEN_ID`, and the statements behind `TFIBDatabase.QueryValue`. A query cache keeps prepared queries for them, so the statement is prepared once.

- The cache belongs to a `TFIBDatabase` and exists as long as the database component.
- A query is stored under its SQL text, without leading and trailing blanks. One query is kept for each text.
- A query that is in use is not given to another caller. A second caller with the same text gets a new query, and when both are released one of them is freed.
- A query that is taken from the cache is closed first and gets the transaction of the caller.

`TFIBDatabase.Gen_Id`, `QueryValue`, and `QueryValues` take their query from the cache. `QueryValue` and `QueryValues` put the query back only when the statement has parameters; a statement without parameters is freed after the call. Pass `aCacheQuery` as `False` to free the query after use in every case.

```delphi
// CustomerName is a Variant
CustomerName := Database.QueryValue('SELECT NAME FROM CUSTOMER WHERE ID = :ID', 0, [42]);
```

The unit `pFIBCacheQueries` exports `GetQueryForUse` and `FreeQueryForUse` for your own code. `GetQueryForUse` returns `nil` when the transaction is `nil`, or when it has no default database and not exactly one database. The datasets do not use the cache for their own five queries; each dataset owns them.

### Clearing the query cache

Cached queries stay prepared on the server. A prepared statement can keep a table or an index in use, so a DDL statement on that table can fail. Call `Database.ClearQueryCacheList` before DDL to free the unused cached queries of that database.

## Metadata cache

Generated SQL and the `PrepareOptions` that read the field definitions (for example `pfSetRequiredFields`, `pfImportDefaultValues`, `pfSetReadOnlyFields`) need information about tables: computed columns, defaults, domains, and primary keys. FibPlus reads it once for each table and keeps it in a cache that all databases in the process share. An entry is identified by the database name (`DBName`) and the table name.

- At design time the cache is not used: the entry is read again each time, so the IDE sees your changes.
- At run time an entry stays until you clear it. **A table that you alter while the application runs is not read again.**

The cache is in the unit `pFIBDataInfo`:

```delphi
ListTableInfo.ClearForTable('CUSTOMER');
ListTableInfo.ClearForDataBase(Database);
ListTableInfo.Clear;
```

Clearing does not change datasets that are open. The next use of the table reads it from the server again. Stored procedure parameters have a separate process-wide cache in the same unit, `ListSPInfo`, with `Clear` and `ClearSPInfo(Database)`. It is read again at design time.

### Save the metadata to a file

Reading the metadata of many tables takes time at startup. `TpFIBDatabase.CacheSchemaOptions` saves the cache to a file and loads it on the next start:

```delphi
Database.CacheSchemaOptions.LocalCacheFile := 'schema.cache';
Database.CacheSchemaOptions.AutoLoadFromFile := True;
Database.CacheSchemaOptions.AutoSaveToFile := True;
```

| Option | Effect |
|--------|--------|
| `AutoLoadFromFile` | Load the file after the connection is opened, at run time, when the file exists. |
| `AutoSaveToFile` | Save the file when the connection is closed, at run time. |
| `ValidateAfterLoad` (default `True`) | Check each loaded table against the server the first time it is used. A table whose format number or field repository version changed is read again. |

Loading replaces the whole cache. The automatic options and the procedures `SaveSchemaToFile` and `LoadSchemaFromFile` of the unit `FIBDatabase` all write and read two more files with the same name and the extensions `.dt` and `.err`. A file is ignored without an error when it has an unknown or older format, or when it comes from a database that was restored from a backup. Saving an empty cache deletes the file, and write errors are not reported.

When `OnAcceptCacheSchema` is assigned and `ValidateAfterLoad` is `True`, the loaded cache is checked right after loading, and the event is called for each table name. Set `Accept` to `False` to drop the entry. The file is written again after the check.

## Pitfalls

- **Commit or rollback of `Transaction` closes the dataset.** With `CachedUpdates` or `poDontCloseAfterEndTransaction`, the dataset reads all remaining rows first and keeps them. `CommitRetaining` and `RollbackRetaining` do not close it. A disconnect behaves the same way. See [Transactions](transactions.md).
- **`CachedUpdates` needs a closed dataset.** Setting it on an open dataset raises an error. Turning it off on an open dataset calls `CancelUpdates`.
- **`SelectSQL` cannot change while the dataset is open** at run time. Close it first.
- **`UpdateOnlyModifiedFields` stays `False` when set in the wrong order.** Set `AutoReWriteSqls` and `CanChangeSQLs` first.
- **Altered tables are not noticed.** See [Metadata cache](#metadata-cache).
- **Prepared cached queries can block DDL.** See [Clearing the query cache](#clearing-the-query-cache).

## See also

- [TFIBDataSet reference](../reference/TFIBDataSet.md)
- [TpFIBDataSet reference](../reference/TpFIBDataSet.md)
- [TpFIBUpdateObject reference](../reference/TpFIBUpdateObject.md)
- [TpFIBDatabase reference](../reference/TpFIBDatabase.md)
- [Queries and parameters](queries-and-parameters.md)
- [Transactions](transactions.md)
- [Timeouts](timeouts.md)
- [BLOBs and arrays](blobs-and-arrays.md)
