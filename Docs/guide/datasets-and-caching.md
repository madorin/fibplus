# Datasets and caching

A FIBPlus dataset reads rows from the server on demand and keeps them in a record cache, so you can scroll in both directions without another round trip. This article shows how rows are fetched, how to refresh and change them, how to lock a row while it is edited, how `TFIBDataSet` generates its own SQL, how to sort, filter, and search on the client, how to change only the record cache, and how the query cache and the metadata cache work.

The samples use these components: `Database` (`TFIBDatabase`), `Transaction` and `UpdateTransaction` (`TFIBTransaction`), `DataSet` (`TFIBDataSet`), and in the master-detail sample `MasterDS` and `DetailDS` (`TFIBDataSet`) and `MasterSource` (`TDataSource`). Fetching, refresh, generated SQL, update objects, and `ApplyUpdates` are all members of [TFIBDataSet](../reference/TFIBDataSet.md).

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

`Refresh` raises an error when `RefreshSQL` is empty and the dataset has rows. `TFIBDataSet` can generate `RefreshSQL`, see [Generated SQL](#generated-sql).

These options of `Options` change when a row is refreshed:

- `poRefreshAfterPost` runs `RefreshSQL` after each `Post`, so that values set by triggers appear in the row. It needs a non-empty `RefreshSQL` and the standard cache. It is in the default options.
- `poRefreshAfterDelete` runs `RefreshSQL` after a delete, so it needs a non-empty `RefreshSQL` too. The row stays in the dataset if `RefreshSQL` still returns it.
- `poRefreshDeletedRecord` removes a row from the cache when a refresh finds no row on the server. It works with the standard cache only.

## Change data

A dataset sends a row change with one of three statements: `InsertSQL`, `UpdateSQL`, and `DeleteSQL`. `Insert`, `Edit`, and `Delete` are allowed when the matching statement exists. They are also allowed when the dataset writes the statements again for each post (`UpdateOnlyModifiedFields`, see [Generated SQL](#generated-sql)), when an active update object exists for the kind, or when `CachedUpdates` is on and `OnUpdateRecord` is assigned. `AllowedUpdateKinds` can forbid a kind.

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

A `TFIBUpdateObject` runs an extra statement when a row is inserted, updated, or deleted. Its `ExecuteOrder` is `oeBeforeDefault` or `oeAfterDefault`: it runs before or after the statement of the dataset. See [TFIBUpdateObject](../reference/TFIBUpdateObject.md).

### Errors while posting

`OnPostError` and `OnDeleteError` are the standard `TDataSetErrorEvent` events. They are called when sending the statement fails.

### Lock a row while it is edited

Without a lock, a user can edit a row for minutes and learn at `Post` that another user changed it in the meantime (`Update conflicts with concurrent update`). With `poProtectedEdit` in `Options`, the dataset locks the row on the server when the edit starts, so the conflict shows at once.

```delphi
DataSet.UpdateTransaction := UpdateTransaction;
DataSet.Options := DataSet.Options + [poProtectedEdit];
DataSet.AutoCommit := True;
```

When an unmodified row goes into edit, the dataset:

1. Locks the row in `UpdateTransaction` with an `UPDATE` that sets a column to its own value, or with `SELECT ... FOR UPDATE WITH LOCK` when `poUseSelectForLock` is also set.
2. Reads the row again with `RefreshSQL`, so the user edits the values that are committed now.

The dataset takes the table and the key from `UpdateSQL`, or from `AutoUpdateOptions` when it generates its statements (see [Generated SQL](#generated-sql)). The details are in [Locking](../reference/TFIBDataSet.md#locking).

When another transaction holds a lock on the row, `Edit` raises an `Exception` whose message says that a deadlock was detected, and the dataset stays in browse state. The error is not an `EFIBError`. With the default `nowait` update transaction it comes at once.

The lock lasts until `UpdateTransaction` ends. `Cancel` does not release it, and neither does `Post`. `Commit` or `Rollback` of the update transaction does; with `AutoCommit` the commit after `Post` releases the lock. Keep the update transaction short.

| Task | Use |
|------|-----|
| Lock the current row from code | `LockRecord`; `LockRecord(False)` returns a `TLockStatus` instead of raising, for example `lsDeadLock` |
| Change the message, or abort or retry the edit | `OnLockError`: `daAbort` ends `Edit` with a silent `EAbort`, `daRetry` tries again |
| Lock with your own statement | `OnLockSQLText` |

## Generated SQL

`TFIBDataSet` can write `InsertSQL`, `UpdateSQL`, `DeleteSQL`, and `RefreshSQL` from `SelectSQL`. Set the table the dataset changes, and turn on `AutoReWriteSqls`:

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
| `UseExecuteBlock` | With `CachedUpdates`, `ApplyUpdates` sends the changes in `EXECUTE BLOCK` batches of generated statements (at most 255 each) instead of running the statements of the dataset and its update objects. See [Applying cached updates](../reference/TFIBDataSet.md#applying-cached-updates). |
| `UseReturningFields` | Add a `RETURNING` clause to the `INSERT` and `UPDATE` made with `AutoReWriteSqls`. |
| `UseRowsClause` | Add `ROWS 1` to the generated `UPDATE`, before `RETURNING`. |

Members of the table that are in the dataset are included. Fields that come from other tables of a join, calculated fields, and computed columns are not. Computed columns are included only with `psCanEditComputedFields` in `PrepareOptions`. The dataset reads the table definition from the server; see [Metadata cache](#metadata-cache).

You can generate the statements yourself with `GenerateSQLs`, or get the text of one statement with `GenerateSQLText`.

### Only the changed fields

With `UpdateOnlyModifiedFields`, the dataset writes the `UPDATE` and `INSERT` again at each `Post`. The `UPDATE` sets only the fields that changed. The `INSERT` lists only the fields that are not null; when all are null, it is `INSERT INTO <table> DEFAULT VALUES`. The statements use the same `NEW_` and `OLD_` parameters. When no field of the table changed in an edited row, nothing is sent.

The property is in effect only while `AutoReWriteSqls` and `CanChangeSQLs` are `True`, whatever the assignment order. The dataset generates the statements only when `KeyFields` and `UpdateTableName` are not empty.

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

In this mode, after `Open` only `RefreshSQL` and `DeleteSQL` are generated. The statements made for each post get the `RETURNING` clause of `UseReturningFields`; `rfAll` returns the written columns of an `UPDATE`, and every column of an `INSERT`, so the values the server filled in for the null fields come back.

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

`GeneratorStep` is the increment, `1` by default. When you set `UpdateTableName` while `GeneratorName` is empty and `WhenGetGenID` is not `wgNever`, the dataset sets `GeneratorName` to `GEN_` plus the table name plus `_ID`. The prefix and suffix are the variables `DefPrefixGenName` and `DefSufixGenName` in the unit `FIBProps`.

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

`ApplyUpdates` posts a pending edit, then sends the changed rows in cache order. A row that the dataset sends is marked as applied. With `AutoCommit` set, the update transaction is committed once at the end, also when rows were skipped; if a row fails, the rows applied before it are committed before the error is raised. Without `AutoCommit`, you commit. `CancelUpdates` reverts all changes, `RevertRecord` the current row. `CachedUpdateStatus` returns the status of the current row. `CountUpdatesPending` returns the number of changed rows. `UpdateRecordTypes` limits which rows are visible, for example only changed ones.

Three events control `ApplyUpdates`: `OnUpdateRecord`, `OnUpdateError`, and `AfterUpdateRecord`. `OnUpdateRecord` is called for each pending row before the dataset sends it, so you can send the row yourself. `OnUpdateError` is called when sending raises `EFIBError`, and lets you fail, abort, skip, or retry the row. The actions and their effects are in [Applying cached updates](../reference/TFIBDataSet.md#applying-cached-updates); the event signatures are in [Updates](../reference/TFIBDataSet.md#updates).

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

## Sort, filter, and search

A dataset can sort, filter, and search the rows of its record cache without asking the server. This suits result sets that fit in memory. For large result sets, let the server do the work: an `ORDER BY` or `WHERE` built with [macros](queries-and-parameters.md#macros) or [conditions](queries-and-parameters.md#conditions), and a new `Open`.

The members are in [Sorting](../reference/TFIBDataSet.md#sorting), [Locating](../reference/TFIBDataSet.md#locating), and [Locate options](../reference/TFIBDataSet.md#locate-options).

### Sort on the client

```delphi
DataSet.DoSort(['CITY', 'LAST_NAME'], [True, False]);
```

The first array names the fields, the second gives the direction of each one: `True` for ascending. `DoSort` posts a pending edit and **fetches all rows** first. The current row stays current. Null values come first in ascending order.

| Task | Use |
|------|-----|
| Is the dataset sorted, and by what | `Sorted`, `SortedFields` (`CITY;LAST_NAME`), `SortFieldsCount`, `SortFieldInfo(1)` |
| Fill the sort information from the `ORDER BY` of `SelectSQL` | `psGetOrderInfo` in `PrepareOptions`, on by default |
| Move an edited or inserted row to its sorted position at `Post` | `poKeepSorting` in `Options` |
| Sort the rows again after the dataset is opened again | `poPersistentSorting` in `Options` |
| Forget the sort | `DoSort([], [])`; the rows keep their order |

Without `poKeepSorting`, a posted row stays where it is, and `Sorted` becomes `False`. Without `poPersistentSorting`, a dataset that is opened again shows the rows in the order of the server. With it, the dataset sorts them again, so it also fetches all rows again.

Strings are compared by the rules of the Windows locale, so national letters sort in their place. For the Romanian locale the order is `alfa`, `ana`, `Ana`, `Ärger`, `Beta`, `Stan`, `Ştefan`, `Tudor`: letters first, then case. For another order, assign `OnCompareFieldValues`. This handler ignores case:

```delphi
function TMainForm.CompareNoCase(Field: TField; const S1, S2: Variant): Integer;
begin
  if (Field.DataType in [ftString, ftWideString]) and not VarIsNull(S1) and not VarIsNull(S2) then
    Result := AnsiCompareText(S1, S2)
  else
    Result := DataSet.StdCompareValues(Field, S1, S2);
end;

DataSet.OnCompareFieldValues := CompareNoCase;
```

`StdCompareValues` is the default comparison. The functions `AnsiCompareString` and `StdAnsiCompareString` were needed for national letters in versions before Unicode Delphi; the default comparison does that now.

### Filter on the client

`Filter` and `Filtered` work as in any `TDataSet`. The filter applies to the rows in the cache and to each row that is fetched later; it does not fetch all rows.

```delphi
DataSet.Filter := 'CITY = ''Iasi'' and UPPER(LAST_NAME) like ''ION%''';
DataSet.Filtered := True;
```

| Syntax | Example |
|--------|---------|
| Comparison, `and`, `or`, `not`, arithmetic | `(ID > 10) and not (ID + 1 = 20)` |
| Null test | `CITY is null` |
| List | `ID in (1, 2, 3)` |
| SQL mask, `%` for any characters and `_` for one | `NAME like 'Ion_%'` |
| Starts with, unless `foNoPartialCompare` is in `FilterOptions` | `NAME = 'Ion*'` |
| String functions | `UPPER`, `LOWER`, `TRIM`, `TRIMLEFT`, `TRIMRIGHT`, `SUBSTRING(NAME, 1, 3)` |
| Date functions | `YEAR`, `MONTH`, `DAY`, `HOUR`, `MINUTE`, `SECOND`, `DATE` |

`foCaseInsensitive` in `FilterOptions` ignores case in comparisons. A function of a null value is null, and a comparison with a null operand (`=`, `<>`, `>`, `>=`, `<`, `<=`, `LIKE`, `IN`) does not match, as in SQL; `IS NULL` matches null values. `not` negates the result, so `not (D = 5)` matches a null `D`. An unknown function, for example `TIME`, raises when the filter is applied.

`OnFilterRecord` runs for the rows that `Filter` accepts, so a row must pass both. `RecordCount` counts all cached rows; `VisibleRecordCount` counts the rows that pass the filter. With `poVisibleRecno` in `Options`, `RecordCount` and `RecNo` count only the visible rows, which a grid scroll bar needs.

### Search

`Locate`, `LocateNext`, and `LocatePrior` search the rows and fetch more rows from the server when needed. `ExtLocate`, `ExtLocateNext`, and `ExtLocatePrior` take more options:

```delphi
if DataSet.ExtLocate('LAST_NAME', 'Ion%', [eloWildCards, eloCaseInsensitive]) then
  repeat
    // the current row matches
  until not DataSet.ExtLocateNext('LAST_NAME', 'Ion%', [eloWildCards, eloCaseInsensitive]);
```

| Option | When it helps |
|--------|---------------|
| `eloCaseInsensitive`, `eloPartialKey`, `eloWildCards` | Matching of string keys, as above |
| `eloInFetchedRecords` | Search only the rows already fetched, without reading more from the server |
| `eloInSortedDS` | The dataset is sorted by the key fields: the search uses the sort order |
| `eloNearest` | With `eloInSortedDS`, when nothing matches, go to the row where the key would be; the function still returns `False` |

`FindFirst`, `FindNext`, `FindPrior`, and `FindLast` are not implemented and always return `False`. Use `ExtLocate` and its `Next` and `Prior` forms instead.

With `CacheModelKind` `cmkLimitedBufferSize`, `Locate` and `ExtLocate` run a query on the server, and only the first three options apply.

## Save and load the record cache

`TFIBDataSet` can write the rows of the cache to a file or a stream and read them back:

```delphi
DataSet.SaveToFile('customers.cache');
// later, in the same or another run
DataSet.LoadFromFile('customers.cache');
```

`SaveToFile` reads all remaining rows first. `LoadFromFile` opens the dataset with the rows from the file and moves to the first row. It does nothing at design time. It raises an error when the file is not a cache file or has an older format, or when the field count, sizes, or types differ from the dataset. The optional `AddInfo` string is stored in the file and returned by `LoadFromFile`.

## Change only the record cache

The `Cache...` methods change the rows in the record cache and send nothing to the server. The rows keep the unmodified status, so `ApplyUpdates` and `UpdatesPending` ignore them. The methods take field indexes. They are listed in [Record cache](../reference/TFIBDataSet.md#record-cache).

### A table in memory

`CacheOpen` prepares `SelectSQL` but does not run it: the dataset opens empty, with the fields of the select list. A select from `RDB$DATABASE` with `CAST` describes the fields:

```delphi
DataSet.SelectSQL.Text :=
  'SELECT CAST(0 AS INTEGER) ID, CAST('''' AS VARCHAR(255)) NAME FROM RDB$DATABASE';
DataSet.CacheOpen;
DataSet.CacheAppend([0, 1], [1, 'one']);
DataSet.CacheAppend([0, 1], [2, 'two']);
DataSet.First;
DataSet.CacheInsert([0, 1], [3, 'three']); // before the current row
DataSet.CacheEdit([1], ['THREE']);
DataSet.CacheDelete;
```

The prepare needs a connection and starts `Transaction`. Sorting and filtering work on these rows as usual. `Open` runs the query and replaces them; `Close` drops them.

The dataset has no statements, so `Edit`, `Insert`, and `Append` raise `Cannot modify a read-only dataset`. To let the user edit the rows in a grid, set `CachedUpdates` before `CacheOpen` and assign an `OnUpdateRecord` handler; the posted rows then stay in the cache as pending changes, and nothing is sent until `ApplyUpdates`.

For a table that the user edits freely, with a log of the changes, a `TClientDataSet` is the general tool. [TFIBClientDataSet](../reference/TFIBClientDataSet.md) is the client side of a multi-tier application.

### Show changes made elsewhere

When a stored procedure, another dataset, or another user changed rows, you can bring the cache up to date without reopening the dataset:

| Change | Use |
|--------|-----|
| A row was inserted and you know its key | `CacheInsert([0], [NewID])`, then `Refresh`, which reads the row with `RefreshSQL`; or `CacheAppend(NewID, True)` |
| A row was deleted | Move to it, then `CacheDelete` |
| Another dataset has the new values of the current row | `CacheRefresh(OtherDataSet, frkEdit, nil)` copies the fields with the same names; `CacheRefreshByArrMap` takes a map |
| A query or dataset returns several changed rows | `RefreshFromQuery` or `RefreshFromDataSet` with the key fields: the rows found in the cache are updated, the others are inserted. With `IsDeletedRecords` set to `True`, the rows found are deleted instead |

```delphi
// NewID was returned by the procedure that inserted the row
DataSet.CacheInsert([0], [NewID]);
DataSet.Refresh;
```

In this sample the key is the first field (index `0`). `CacheAppend(NewID, True)` always sets the first field. `RefreshSQL` must find the row by the key.

## BOOLEAN and GUID domains

Two `PrepareOptions` give a column a field class by the name of its domain. Both look at the domain of the table column, so the domain name must contain the word.

| Option | Column | Field |
|--------|--------|-------|
| `psUseBooleanField`, on by default | `SMALLINT` or `INTEGER` with a domain whose name contains `BOOLEAN` | `TFIBBooleanField` |
| `psUseGuidField`, off by default | `CHAR(16) CHARACTER SET OCTETS` with a domain whose name contains `GUID` | `TFIBGuidField` |

```sql
CREATE DOMAIN FIB$BOOLEAN AS SMALLINT DEFAULT 1 NOT NULL CHECK (VALUE IN (0, 1));
CREATE DOMAIN FIB$GUID AS CHAR(16) CHARACTER SET OCTETS;
```

The boolean domain is for databases that must run on servers before *Firebird 3*. A native `BOOLEAN` column becomes a `TFIBBooleanField` without any option; see [Boolean](firebird-versions.md#boolean).

A `TFIBGuidField` shows the value as text, `{4E46EF02-B207-4C8E-A41A-2FBCA07C11F9}`, and `AsGuid` reads and writes a `TGUID`. A new row gets a new GUID in the field when it is created, so a GUID key needs no generator.

```delphi
DataSet.PrepareOptions := DataSet.PrepareOptions + [psUseGuidField];
DataSet.Open;
DataSet.Append; // the GUID field already has a new value
```

Change `psUseGuidField` and `psUseBooleanField` only while the dataset is closed: the dataset reads its field definitions again, and on an open dataset the change raises an error. Persistent fields created with the old type must be created again.

## Query cache

FIBPlus runs many small internal statements: reading metadata, `GEN_ID`, and the statements behind `TFIBDatabase.QueryValue`. A query cache keeps prepared queries for them, so the statement is prepared once.

- The cache belongs to a `TFIBDatabase` and exists as long as the database component.
- A query is stored under its SQL text, without leading and trailing blanks. One query is kept for each text.
- A query that is in use is not given to another caller. A second caller with the same text gets a new query, and when both are released one of them is freed.
- A query that is taken from the cache is closed first and gets the transaction of the caller.

`TFIBDatabase.Gen_Id`, `QueryValue`, and `QueryValues` take their query from the cache. `QueryValue` and `QueryValues` put the query back only when the statement has parameters; a statement without parameters is freed after the call. Pass `aCacheQuery` as `False` to free the query after use in every case.

```delphi
// CustomerName is a Variant
CustomerName := Database.QueryValue('SELECT NAME FROM CUSTOMER WHERE ID = :ID', 0, [42]);
```

The unit `FIBCacheQueries` exports `GetQueryForUse` and `FreeQueryForUse` for your own code. `GetQueryForUse` returns `nil` when the transaction is `nil`, or when it has no default database and not exactly one database. The overload `GetQueryForUse(Database, Transaction, SQLText)` takes the database explicitly, for a transaction over several databases; it returns `nil` when either is `nil`. The datasets do not use the cache for their own five queries; each dataset owns them.

### Clearing the query cache

Cached queries stay prepared on the server. A prepared statement can keep a table or an index in use, so a DDL statement on that table can fail. Call `Database.ClearQueryCacheList` before DDL to free the unused cached queries of that database.

## Metadata cache

Generated SQL and the `PrepareOptions` that read the field definitions (for example `pfSetRequiredFields`, `pfImportDefaultValues`, `pfSetReadOnlyFields`) need information about tables: computed columns, defaults, domains, and primary keys. FIBPlus reads it once for each table and keeps it in a cache that all databases in the process share. An entry is identified by the database name (`DBName`) and the table name.

- At design time the cache is not used: the entry is read again each time, so the IDE sees your changes.
- At run time an entry stays until you clear it. **A table that you alter while the application runs is not read again.**

The cache is in the unit `FIBDataInfo`:

```delphi
ListTableInfo.ClearForTable('CUSTOMER');
ListTableInfo.ClearForDataBase(Database);
ListTableInfo.Clear;
```

Clearing does not change datasets that are open. The next use of the table reads it from the server again. Stored procedure parameters have a separate process-wide cache in the same unit, `ListSPInfo`, with `Clear` and `ClearSPInfo(Database)`. It is read again at design time.

### Save the metadata to a file

Reading the metadata of many tables takes time at startup. `TFIBDatabase.CacheSchemaOptions` saves the cache to a file and loads it on the next start:

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
- **Altered tables are not noticed.** See [Metadata cache](#metadata-cache).
- **Prepared cached queries can block DDL.** See [Clearing the query cache](#clearing-the-query-cache).
- **`DoSort` on a large result set.** It fetches all rows first. Sort on the server with `ORDER BY` instead.
- **`FindFirst` and `FindNext` return `False`.** They are not implemented. Use `ExtLocate` and `ExtLocateNext`.
- **`RecordCount` with a filter.** It counts all cached rows. Use `VisibleRecordCount`, or set `poVisibleRecno`.
- **A locked row stays locked after `Cancel`.** With `poProtectedEdit` the lock ends only with the update transaction. See [Lock a row while it is edited](#lock-a-row-while-it-is-edited).
- **A dataset opened with `CacheOpen` is read-only.** Use the `Cache...` methods, or `CachedUpdates` with `OnUpdateRecord`. See [A table in memory](#a-table-in-memory).

## See also

- [TFIBDataSet reference](../reference/TFIBDataSet.md)
- [TFIBUpdateObject reference](../reference/TFIBUpdateObject.md)
- [TFIBDatabase reference](../reference/TFIBDatabase.md)
- [Queries and parameters](queries-and-parameters.md)
- [Transactions](transactions.md)
- [Timeouts](timeouts.md)
- [BLOBs and arrays](blobs-and-arrays.md)
