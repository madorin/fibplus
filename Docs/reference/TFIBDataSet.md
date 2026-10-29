# <img src="../images/icons/TFIBDataSet.png" width="32" height="32" align="absmiddle" alt=""> TFIBDataSet

The dataset to use in applications, and the one on the component palette. It reads rows through a `TFIBQuery` and keeps them in a record cache, so that scrolling in both directions, sorting, and locating need no further round trip. It can generate its SQL statements from the table and key fields, take keys from generators, run update objects, apply cached updates, lock records, set field properties from the metadata, and save the record cache to a file. Use it for data-aware controls. For commands and for reading rows in code without a `TDataSet`, use [TFIBQuery](TFIBQuery.md).

| | |
|---|---|
| Unit | `FIBDataSet` |
| Inherits from | `TFIBCustomDataSet` (the implementation lives there), then `TDataSet` |
| Deprecated alias | `TpFIBDataSet`, in the unit `pFIBDataSet` |

```delphi
DataSet.Database := Database;
DataSet.Transaction := Transaction;
DataSet.SelectSQL.Text := 'SELECT ID, NAME FROM CUSTOMER WHERE ID > :MinID ORDER BY NAME';
DataSet.Params.ByName['MinID'].AsInteger := 100;
DataSet.Open;
if DataSet.Locate('NAME', 'Smith', [loCaseInsensitive, loPartialKey]) then
  ShowMessage(DataSet.FBN('ID').AsString);
```

In the example, `DataSet` is a `TFIBDataSet`, and `Database` and `Transaction` are the `TFIBDatabase` and `TFIBTransaction` it uses.

A dataset can also write its own statements:

```delphi
DataSet.Database := Database;
DataSet.Transaction := Transaction;
DataSet.SelectSQL.Text := 'SELECT ID, NAME FROM CUSTOMER';
with DataSet.AutoUpdateOptions do
begin
  UpdateTableName := 'CUSTOMER';
  KeyFields := 'ID';
  AutoReWriteSqls := True;
  GeneratorName := 'GEN_CUSTOMER_ID';
  WhenGetGenID := wgBeforePost;
end;
DataSet.Open;
```

Only `SelectSQL` is written among the SQL statements. When the dataset opens, it fills `InsertSQL`, `UpdateSQL`, `DeleteSQL`, and `RefreshSQL`; a new row gets its `ID` from the generator when it is posted. The sample needs a table `CUSTOMER` with a key `ID` and a generator `GEN_CUSTOMER_ID`.

This page lists what `TFIBDataSet` and `TFIBCustomDataSet` add to `TDataSet`. Members inherited from `TDataSet` (`Open`, `Close`, `Fields`, `Bookmark`, `Filter`, and so on) are not repeated. All the code is in `TFIBCustomDataSet`; `TFIBDataSet` only publishes the properties and events, as `TCustomX` and `TX` do in the VCL.

Guides: [Datasets and caching](../guide/datasets-and-caching.md), [Queries and parameters](../guide/queries-and-parameters.md), [Transactions](../guide/transactions.md), [Timeouts](../guide/timeouts.md), [BLOBs and arrays](../guide/blobs-and-arrays.md).

## Published properties

Available in the Object Inspector. Besides the properties below, `TFIBDataSet` publishes the standard `TDataSet` ones (`Active`, `AutoCalcFields`, `Filter`, `FilterOptions`, `Filtered`), the `Before...` / `After...` events, `OnFilterRecord`, `OnNewRecord`, `OnCalcFields`, `OnDeleteError`, `OnEditError`, and `OnPostError`.

### Connection and transactions

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `AutoCommit` | `Boolean` | `False` | Commit `UpdateTransaction` after each change is sent to the server. Uses `CommitRetaining` when `UpdateTransaction` is the same as `Transaction`, or when its `TimeoutAction` is `TACommitRetaining`. |
| `Database` | `TFIBDatabase` | | Connection the dataset runs on. The dataset must be closed to change it. |
| `RefreshTransactionKind` | `TTransactionKind` | `tkReadTransaction` | Transaction that runs `RefreshSQL`: `tkReadTransaction` uses `Transaction`, `tkUpdateTransaction` uses `UpdateTransaction`. |
| `Transaction` | `TFIBTransaction` | | Transaction for `SelectSQL` and, by default, `RefreshSQL`. The dataset must be closed to change it. Without a separate `UpdateTransaction`, the insert, update, delete, and refresh statements use it too. |
| `UpdateTransaction` | `TFIBTransaction` | | Transaction for `InsertSQL`, `UpdateSQL`, and `DeleteSQL`. |

### SQL statements

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `Conditions` | `TConditions` | | Named `WHERE` conditions of `SelectSQL` that can be switched on and off; see [TFIBQuery](TFIBQuery.md#published-properties). |
| `DeleteSQL` | `TStrings` | | Statement that deletes a row. |
| `InsertSQL` | `TStrings` | | Statement that inserts a new row. |
| `RefreshSQL` | `TStrings` | | Query that reads one row again after `Refresh` or a change. |
| `SelectSQL` | `TStrings` | | Query that returns the rows. `:Name` parameters are available through `Params`. |
| `SQLs` | `TSQLs` | | Groups the five statements into one sub-object. Not stored in the DFM. |
| `UpdateSQL` | `TStrings` | | Statement that updates a row. |

`Insert`, `Edit`, and `Delete` are allowed under the rules in [Editing permissions](#editing-permissions). The dataset can generate the statements, see [AutoUpdateOptions](#autoupdateoptions). Changing the text of `SelectSQL` at run time raises an error while the dataset is open; at design time it closes the dataset.

### Behavior

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `AllowedUpdateKinds` | `TUpdateKinds` | `[ukModify, ukInsert, ukDelete]` | Kinds of change the dataset allows. At run time, when preparing the insert, update, or delete statement fails with a permission error and the global variable `FIBHideGrantError` (unit `FIBDatabase`, default `False`) is `True`, that kind is removed. Nothing is removed at design time, and a failed `RefreshSQL` removes nothing. |
| `AutoUpdateOptions` | `TAutoUpdateOptions` | | Settings for generated SQL, generators, and key fields. See [AutoUpdateOptions](#autoupdateoptions). |
| `CachedUpdates` | `Boolean` | `False` | Keep changes in the cache until they are applied. Turning it on needs a closed dataset and is refused with `cmkLimitedBufferSize`. Turning it off on an open dataset is allowed and calls `CancelUpdates`. |
| `CacheModelOptions` | `TCacheModelOptions` | | Record cache settings, see [Cache model](#cache-model). |
| `CSMonitorSupport` | `TCSMonitorSupport` | | Adds monitoring text to the statements. Only when compiled with `CSMonitor`. |
| `DataSource` | `TDataSource` | | Master dataset source. Parameters of `SelectSQL` named like master fields are filled from it. A circular reference raises an error. |
| `DetailConditions` | `TDetailConditions` | `[]` | How a detail dataset follows its master, see [Master-detail](#master-detail). Saved in the DFM as individual boolean entries. |
| `FieldOriginRule` | `TFieldOriginRule` | `forTableAndFieldName` | How `Field.Origin` is filled when the dataset opens. `forNoRule` leaves it empty. |
| `Options` | `TFIBDataSetOptions` | `[poTrimCharFields, poStartTransaction, poAutoFormatFields, poRefreshAfterPost]` | Behavior flags, see [Options](#options). The default is `DefaultOptions` for a component dropped at design time and `StatDefDataSetOptions` at run time (unit `FIBProps`). Saved in the DFM as individual boolean entries. |
| `PrepareOptions` | `TFIBPrepareOptions` | `[pfImportDefaultValues, psGetOrderInfo, psUseBooleanField, psSetEmptyStrToNull]` | What the dataset reads from the metadata when it prepares, such as required fields and `BOOLEAN` and GUID mapping. The initial value is `DefaultPrepareOptions` for a component dropped at design time and `StatDefPrepareOptions` otherwise. See [Prepare options](#prepare-options). Saved in the DFM as individual boolean entries. |
| `SQLScreenCursor` | `TCursor` | `crDefault` | Screen cursor shown during long operations: prepare, open, fetch, `FetchAll`, `Clone`, and the refresh in `cmkLimitedBufferSize`. From Delphi XE2 the change goes through `Database.DoChangeScreenCursor` and does nothing when that is not assigned. Not available when compiled with `NO_GUI`. |
| `StatementTimeout` | `Cardinal` | `0` | Statement time limit in milliseconds, *Firebird 4+*. See [Statement timeout](#statement-timeout). |
| `UniDirectional` | `Boolean` | `False` | Read forward only. The cache keeps a window of `BufferChunks` records instead of all rows. Can be changed only while the dataset is closed. `ReopenLocate` and `FullRefresh` (standard cache) raise. |
| `UpdateRecordTypes` | `TFIBUpdateRecordTypes` | `[cusUnmodified, cusModified, cusInserted]` | Rows with these cached update statuses are visible. Setting it moves to the first row when the dataset is active. Ignored with `cmkLimitedBufferSize`. |

### Repository and containers

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `About` | `string` | | Shows the library version. Not stored; assigning has no effect. |
| `Container` | `TDataSetsContainer` | | Container (unit `DSContainer`) that receives the dataset events. See [Events](#events). |
| `DataSet_ID` | `Integer` | `0` | Number of the row in the repository table `FIB$DATASETS_INFO` that holds the SQL texts and update settings of this dataset. Can be changed only while the dataset is closed. A non-zero value turns `psApplyRepositary` on. See [DataSet_ID and the repository](#dataset_id-and-the-repository). |
| `DefaultFormats` | `TFormatFields` | see [Default formats](#default-formats) | Display and edit formats applied to fields when `poAutoFormatFields` is set. |
| `Description` | `string` | | Free text. Stored in the `DESCRIPTION` column of the repository row, and replaced from it when the row is loaded. |

### Default formats

`TFormatFields` has five string properties. The values below are the defaults for a dataset created at run time or loaded from a form; the design-time defaults of a new component and the run-time defaults selected by `FF_UseRuntimeDefaults` come from typed constants in `FIBProps` that have the same values.

| Name | Default | Applied to |
|------|---------|------------|
| `DateTimeDisplayFormat` | `dd.mm.yyyy hh:nn` | `ftDateTime` fields: `DisplayFormat` |
| `DisplayFormatDate` | `dd.mm.yyyy` | `ftDate` fields: `DisplayFormat` |
| `DisplayFormatTime` | `hh:nn` | `ftTime` fields: `DisplayFormat` |
| `NumericDisplayFormat` | `#,##0.` | Scaled numeric fields: `DisplayFormat` |
| `NumericEditFormat` | `0.` | Scaled numeric fields: `EditFormat` |

The formats are used when the dataset opens, only for a field whose own `DisplayFormat` (or `EditFormat`) is empty. The numeric formats apply to `ftSmallint`, `ftInteger`, and `ftFloat` fields with a negative scale, and to `ftBCD` fields that are not currency and have `Size` above `0`. A format that ends with `.` gets as many zeros as the scale (`#,##0.` becomes `#,##0.00` for scale 2). A format whose `.` is followed by one character repeats that character as many times as the scale. Any other format is used as it is.

## Options

`Options`, `PrepareOptions`, `DetailConditions`, and `AutoUpdateOptions` are published properties; their values are defined in unit `FIBProps`.

Each flag of `Options`, `PrepareOptions`, and `DetailConditions` is stored in the form file as its own boolean entry. The entry is written only when the value differs from the standard default (or from the ancestor form, in an inherited form). The *DFM entry* column gives the name of the entry; it differs from the enumeration name for some flags.

### Dataset options

`Options` is a set of `TFIBDataSetOption`. The standard default is `[poTrimCharFields, poStartTransaction, poAutoFormatFields, poRefreshAfterPost]`, see [Defaults](#defaults).

| Value | DFM entry | Effect |
|-------|-----------|--------|
| `poAutoFormatFields` | `oAutoFormatFields` | Apply `DefaultFormats` to date, time, and scaled numeric fields when the dataset opens. |
| `poCacheCalcFields` | `oCacheCalcFields` | Keep the values of calculated fields with each row in the record cache. |
| `poDontCloseAfterEndTransaction` | `oDontAutoClose` | When `Transaction` commits or rolls back, or the database disconnects, fetch all rows and close the cursor instead of closing the dataset. `CachedUpdates` has the same effect. Reading a BLOB of the dataset starts the transaction and opens the connection if they are closed. |
| `poFetchAll` | `oFetchAll` | Fetch all rows after the dataset opens. |
| `poFreeHandlesAfterClose` | `oFreeHandlesAfterClose` | Release the prepared statements on the server (`UnPrepare`) after the dataset closes. |
| `poKeepSorting` | `oKeepSorting` | When a row is posted and the dataset is sorted, move the row to the place its sort fields give. Without it, posting a row clears the sort information, and `Sorted` becomes `False`. With `cmkLimitedBufferSize` the order is always kept. |
| `poNoForceIsNull` | `oNoForceIsNull` | Sets `qoNoForceIsNull` on `QSelect`, `QInsert`, `QUpdate`, and `QDelete`: a null parameter is not rewritten to `IS NULL`. `QRefresh` is not changed. |
| `poPersistentSorting` | `oPersistentSorting` | When the dataset opens again after a client sort (`DoSort`), sort the new rows in the same way. When the `SelectSQL` text changed, the sort is kept only if its fields are still in the dataset. Without the option, the local sort ends when the dataset is closed: after the open, the sort information is the `ORDER BY` of the query with `psGetOrderInfo`, or empty. |
| `poProtectedEdit` | `oProtectedEdit` | Pessimistic locking. Before the first edit of a row, lock it on the server (see [LockRecord](#locking)) and read it again with `RefreshSQL`. When `RefreshSQL` or `UpdateSQL` is empty and `AutoReWriteSqls` or `UpdateOnlyModifiedFields` is set, the statement is generated first. Without `CachedUpdates` and `AutoCommit`, a posted row keeps the modified status until the update transaction commits, so editing it again does not lock it again. |
| `poRefreshAfterDelete` | `oRefreshAfterDelete` | After the delete statement runs, read the row again with `RefreshSQL`. The row stays in the cache when `RefreshSQL` still returns it (a logical delete); otherwise it is removed. Without the option, the row is always removed. |
| `poRefreshAfterPost` | `oRefreshAfterPost` | After an insert or update is sent to the server, read the row again with `RefreshSQL`, so values set by triggers and defaults appear. With `cmkStandard` it needs a non-empty `RefreshSQL`. With `cmkLimitedBufferSize` the option starts the refresh of the cache part (`DoInternalRefresh`) after each post. |
| `poRefreshDeletedRecord` | `oRefreshDeletedRecord` | When a refresh with `RefreshSQL` finds no row, remove the row from the cache. Only with `cmkStandard`. |
| `poStartTransaction` | `oStartTransaction` | Start `Transaction` and `UpdateTransaction` when they are not active and a statement needs them. Also sets `qoStartTransaction` on `QSelect`, `QInsert`, `QUpdate`, and `QDelete`. |
| `poTrimCharFields` | `oTrimCharFields` | Remove trailing blanks from `CHAR` values when a field is read. |
| `poUseSelectForLock` | `oUseSelectForLock` | `LockRecord` locks with `SELECT ... FOR UPDATE WITH LOCK` instead of a no-op `UPDATE`. |
| `poVisibleRecno` | `oVisibleRecno` | With `Filtered`, `RecNo` and `RecordCount` count only the rows that pass the filter, and `IsSequenced` follows the visible rows. Without it they count all cached rows. |

### Prepare options

`PrepareOptions` is a set of `TFIBPrepareOption`. It tells the dataset what to read from the metadata. The standard default is `[pfImportDefaultValues, psGetOrderInfo, psUseBooleanField, psSetEmptyStrToNull]`.

Changing `psUseBooleanField`, `psUseGuidField`, `psSQLINT64ToBCD`, or `psUseLargeIntField` needs a closed dataset; when the dataset is already prepared, its field definitions are read again.

| Value | DFM entry | Effect |
|-------|-----------|--------|
| `pfImportDefaultValues` | `poImportDefaultValues` | Set `DefaultExpression` of each field to the default of its column. A new row is filled from it, see [New row defaults](#new-row-defaults). |
| `pfSetReadOnlyFields` | `poSetReadOnlyFields` | Make a data field read-only when its column does not belong to the table that the dataset changes. That table is `AutoUpdateOptions.UpdateTableName` with `AutoReWriteSqls`; otherwise the table of `UpdateSQL`, or of `InsertSQL` when `UpdateSQL` is empty. Without `AutoReWriteSqls` it is skipped when `CachedUpdates` is on and `OnUpdateRecord` is assigned. Also makes computed columns read-only unless `psCanEditComputedFields` is set. |
| `pfSetRequiredFields` | `poSetRequiredFields` | Set `Required` on `NOT NULL` columns that have no default value and are not marked as set by a trigger (`TRIGGERED` in `FIB$FIELDS_INFO`, read only when `urFieldsInfo` is in `UseRepositories`). The value is assigned, so `Required` is also cleared for other fields. |
| `psApplyRepositary` | `poApplyRepositary` | Use the repository tables. Load the dataset settings of `DataSet_ID` and apply the field settings of `FIB$FIELDS_INFO`. See [DataSet_ID and the repository](#dataset_id-and-the-repository). |
| `psAskRecordCount` | `poAskRecordCount` | Before the dataset opens, run `SELECT COUNT(*) FROM (<SelectSQL>)` on the server (other servers use a rewritten query) and keep the result in `AllRecordCount`. `RecordCount` and the scroll bar then show the total before all rows are fetched. `OnAskRecordCount` can supply the SQL. Needs an active `Transaction`; otherwise the count is `0`. |
| `psCanEditComputedFields` | `poCanEditComputedFields` | Computed columns are not made read-only, and generated `INSERT` and `UPDATE` statements include them. |
| `psGetOrderInfo` | `poGetOrderInfo` | Read the `ORDER BY` of `SelectSQL` to fill the sort information (`Sorted`, `SortedFields`). `cmkLimitedBufferSize` reads it regardless. |
| `psSetEmptyStrToNull` | `poEmptyStrToNull` | Initial value of `EmptyStrToNull` of the string fields: an empty string is stored as `NULL`. |
| `psSQLINT64ToBCD` | `poSQLINT64ToBCD` | A scaled 64-bit `NUMERIC` with a scale beyond 4 becomes `TFIBBCDField` and not a floating point field. |
| `psSupportUnicodeBlobs` | `poSupportUnicodeBlobs` | Read the character set of text `BLOB` columns from the metadata. A column in a Unicode character set (`Database.UnicodeCharSets`) is then decoded as UTF-8 when the code page would otherwise be the system one. The character set of the column is also read when `Database.NeedUTFEncodeDDL` is `True`. |
| `psUseBooleanField` | `poUseBooleanField` | A `SMALLINT` or `INTEGER` column whose domain name contains `BOOLEAN` becomes `TFIBBooleanField`. |
| `psUseGuidField` | `poUseGuidField` | A 16-byte string column whose domain name contains `GUID` becomes `TFIBGuidField`. |
| `psUseLargeIntField` | `poUseLargeIntField` | `BIGINT` (scale 0) becomes `TFIBLargeIntField`. Without it, it becomes `TFIBBCDField`. |

#### New row defaults

When a new row is created, each field gets its value in this order:

1. When `AutoUpdateOptions.ParamsToFieldsLinks` has an entry for the field, the value of the linked `SelectSQL` parameter.
2. For a `TFIBStringField` whose column default is an empty string, an empty string.
3. For a `TFIBGuidField`, a new GUID.
4. When `DefaultExpression` is not empty, `OnApplyDefaultValue` is called. If it leaves `Applied` as `False`, the value comes from the expression:
   - the text `NULL` leaves the field empty;
   - for date and time fields, `NOW`, `CURRENT_TIME`, `CURRENT_TIMESTAMP`, `LOCALTIME`, and `LOCALTIMESTAMP` give the client time, `TODAY` and `CURRENT_DATE` the client date, and `TOMORROW` and `YESTERDAY` the next and previous date; the `DifferenceTime` of the database is subtracted first;
   - for string fields, `USER` and `CURRENT_USER` give the user name of the connection, `ROLE` and `CURRENT_ROLE` its role, and a quoted text gives the text without quotes;
   - any other expression is assigned as text.

A key field that is filled from a generator (`WhenGetGenID`) is skipped.

### Defaults

The standard defaults are the constants `StatDefDataSetOptions` and `StatDefPrepareOptions` in `FIBProps`. The writable typed constants `DefaultOptions`, `DefaultPrepareOptions`, and `DefaultDetailConditions` start with the same values.

| Dataset created | `Options`, `PrepareOptions` | `DetailConditions` |
|-----------------|-----------------------------|--------------------|
| At design time, dropped on a form | `DefaultOptions`, `DefaultPrepareOptions` | `DefaultDetailConditions` |
| At run time, or loaded from a form file | `StatDefDataSetOptions`, `StatDefPrepareOptions` | `[]` |

`DefaultOptions`, `DefaultPrepareOptions`, and `DefaultDetailConditions` are changed by the design-time preferences, so they set the starting values of new components in the IDE only. Changing them in an application has no effect on datasets created at run time.

Other writable typed constants in `FIBProps` that affect `TFIBDataSet`:

| Constant | Default | Used for |
|----------|---------|----------|
| `DefPrefixGenName`, `DefSufixGenName` | `GEN_`, `_ID` | Generator name built when `UpdateTableName` is set, see [AutoUpdateOptions](#autoupdateoptions). |
| `FF_UseRuntimeDefaults` | `False` | When `True`, `DefaultFormats` start with `RDefDateFormat`, `RDefTimeFormat`, `RDefDisplayFormatNum`, and `RDefEditFormatNum` instead of the other defaults. |
| `RDefDateFormat`, `RDefTimeFormat`, `RDefDisplayFormatNum`, `RDefEditFormatNum` | `dd.mm.yyyy`, `hh:nn`, `#,##0.`, `0.` | See above. |
| `dDefDateFormat`, `dDefTimeFormat`, `dDefDateTimeFormat`, `dDefDisplayFormatNum`, `dDefEditFormatNum` | `dd.mm.yyyy`, `hh:nn`, `dd.mm.yyyy hh:nn`, `#,##0.`, `0.` | `DefaultFormats` of a component dropped at design time. |

### AutoUpdateOptions

`AutoUpdateOptions` is a `TAutoUpdateOptions` object (unit `FIBProps`). It controls generated statements, key generators, and the link between parameters and fields. All members in the first table are published.

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `AutoParamsToFields` | `Boolean` | `False` | After the dataset opens, and when the `SelectSQL` text changed since the last time, fill `ParamsToFieldsLinks` with `ParseParamToFieldsLinks`. |
| `AutoReWriteSqls` | `Boolean` | `False` | Generate `InsertSQL`, `UpdateSQL`, `DeleteSQL`, and `RefreshSQL` when the dataset opens at run time, if the `SelectSQL` text, `UpdateTableName`, `KeyFields`, or `UseReturningFields` changed. See [Generated statements](#generated-statements). |
| `CanChangeSQLs` | `Boolean` | `False` | Allow generation to replace a statement that is not empty. Without it, only empty statements are generated. |
| `GeneratorName` | `string` | | Generator for the key field. When empty and `WhenGetGenID` is not `wgNever` at the moment `UpdateTableName` is set, it becomes `GEN_<table>_ID` (quoted when the table name is). |
| `GeneratorStep` | `Integer` | `1` | Second argument of `GEN_ID`. |
| `KeyFields` | `string` | | Names of the dataset fields that identify a row, separated by `;`. Used in the `WHERE` clause of generated statements and, with `cmkLimitedBufferSize`, as the bookmark key. When empty, generation takes the primary key of the table, then all non-BLOB fields of the table. |
| `ParamsToFieldsLinks` | `TStrings` | | Lines `FieldName=ParamName`. A new row takes the value of the field from that parameter of `SelectSQL`, which fills a detail row from the master. |
| `SeparateBlobUpdate` | `Boolean` | `False` | Generated `INSERT` and `UPDATE` statements leave out the BLOB fields. An internal update object writes them with a separate `UPDATE` after the main statement. |
| `UpdateOnlyModifiedFields` | `Boolean` | `False` | Generate `INSERT` and `UPDATE` for each post from the changed fields only: unchanged fields in `UPDATE`, null fields in `INSERT`. An `INSERT` with no field set is `INSERT INTO <table> DEFAULT VALUES`; an unchanged `UPDATE` is `No Action`. In effect only while `AutoReWriteSqls` and `CanChangeSQLs` are also `True` (`UpdateOnlyModifiedFieldsInEffect`); the property keeps the assigned value, in any order. |
| `UpdateTableName` | `string` | | Table, with an optional alias, that generated statements change. |
| `UseExecuteBlock` | `Boolean` | `False` | `ApplyUpdates` collects the cached changes in `EXECUTE BLOCK` batches and sends them with `ExecSQLImmediate`. The statements are generated from `UpdateTableName` and `KeyFields` with the values as literals; `InsertSQL`, `UpdateSQL`, `DeleteSQL`, and update objects are not used. A batch holds up to 255 statements and less than 64 KB of text. Intended for `CachedUpdates` (comment in the code). See [Applying cached updates](#applying-cached-updates). |
| `UseReturningFields` | `TSetReturningFields` | `[]` | Add a `RETURNING` clause to generated `INSERT` and `UPDATE`: `rfAll` returns every written column (in an `INSERT` made with `UpdateOnlyModifiedFields`, also the null columns left to the server defaults), `rfKeyFields` the key columns, `rfBlobFields` the written BLOB columns. After the statement runs, the row is read back when its statement type is select, execute procedure, or select for update. Applies to statements made by `GenerateSQLs` and, with `UpdateOnlyModifiedFields`, to those made for each post. |
| `UseRowsClause` | `Boolean` | `False` | Add `ROWS 1` on a new line to generated `UPDATE` statements, before the `RETURNING` clause. Firebird accepts no `ROWS` in `INSERT`; the generated `DELETE` has none either. |
| `WhenGetGenID` | `TWhenGetGenID` | `wgNever` | When to take the key from the generator: `wgNever`, `wgOnNewRecord` (when the row is created), `wgBeforePost` (before the insert is posted; the `Required` flag of the key field is cleared when the row is created). The key field must be numeric and empty; see `IncGenerator`. |

Run-time members of `TAutoUpdateOptions`:

| Name | Type | Description |
|------|------|-------------|
| `AliasModifiedTable` | `string` | Alias of the table to change, as used in generated statements. |
| `GenBeforePost`, `SelectGenID` | `Boolean` | Compatibility with old form files. They read and write `WhenGetGenID`: `SelectGenID` is `True` unless `wgNever`; `GenBeforePost` selects `wgBeforePost` over `wgOnNewRecord`. |
| `KeyFieldList` | `TStrings` | `KeyFields` as a list. |
| `ModifiedTableName` | `string` | `UpdateTableName` without the alias, formatted for the SQL dialect of the database. |
| `ModifiedTableHaveAlias` | `Boolean` | `True` when `UpdateTableName` contains an alias. |

`ReadySelectSQL`, `WhereCondition`, and `Modified` are caches of the generator. `WhereCondition` and `ReadySelectSQL` are cleared when the text of any of the dataset statements changes.

#### Generated statements

Generation needs `UpdateTableName`, a table known to the metadata, and key fields that exist in the dataset and belong to the table. A key field is left out of the `WHERE` clause when its column is a BLOB or an array. Statements use parameters named `NEW_<field>` for new values and `OLD_<field>` for the values the row had when it was read, written as `?NEW_NAME` and `?OLD_ID`. When no field qualifies, the statement text is `No Action` and the dataset sends nothing for it; an `INSERT` becomes `INSERT INTO <table> DEFAULT VALUES` instead.

- The `INSERT` and `UPDATE` statements list the data fields whose column belongs to `UpdateTableName`. Computed columns are skipped unless `psCanEditComputedFields` is set.
- `DELETE` removes the row with the key condition.
- `RefreshSQL` is `SelectSQL` with the key condition added and without `ORDER BY`.

With `AutoReWriteSqls` and without `UpdateOnlyModifiedFields`, `GenerateSQLs` runs when the dataset opens. With `UpdateOnlyModifiedFields`, `RefreshSQL` and `DeleteSQL` are generated when the dataset opens, and `InsertSQL` and `UpdateSQL` are generated again before each post (`AutoGenerateSQLText`).

#### DataSet_ID and the repository

`FIB$DATASETS_INFO` is a table in the database that stores dataset settings by number. A dataset with `DataSet_ID` set and `psApplyRepositary` on loads its row the first time it is prepared and each time `DataSet_ID` changed. The load replaces `SelectSQL`, `InsertSQL`, `UpdateSQL`, `DeleteSQL`, and `RefreshSQL` when the stored text is not empty. It always replaces `Description`, `Conditions`, and these `AutoUpdateOptions` members: `KeyFields`, `GeneratorName`, `UpdateOnlyModifiedFields` (in effect only with `AutoReWriteSqls` and `CanChangeSQLs`), and `UpdateTableName`. It also sets `WhenGetGenID` to `wgNever` when the key field or the generator is not stored, and to `wgBeforePost` when both are stored and `WhenGetGenID` was `wgNever`.

The row is read through the database component: `UseRepositories` of the database must contain `urDataSetInfo`, and the table must exist; otherwise the load raises an exception. When the table has no row for `DataSet_ID`, no error is raised and the code goes on with empty stored values. The settings are cached per database name and `DataSet_ID`. Field settings come from `FIB$FIELDS_INFO` when `urFieldsInfo` is in `UseRepositories`: `DisplayLabel`, `DisplayWidth`, `Visible`, and the display and edit formats are applied to the fields (see `OnApplyFieldRepository`). The column `TRIGGERED` of that table is what `pfSetRequiredFields` reads.
## Cache model

`CacheModelOptions` is a `TCacheModelOptions` object. Changing `CacheModelKind` needs an inactive dataset.

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `BlobCacheLimit` | `Integer` | `0` | Number of BLOB streams kept open in memory at once. When more are opened, the least recently used unmodified one is released. `0` means no limit. |
| `BufferChunks` | `Integer` | `32` | Records per cache block. A block is at least 1024 bytes, so it can hold more records than this value. A value of `0` or less restores the default. With `cmkLimitedBufferSize` the minimum is `100`. Can be changed only while the dataset is closed. |
| `CacheModelKind` | `TCacheModelKind` | `cmkStandard` | `cmkStandard` keeps every fetched row in the cache. `cmkLimitedBufferSize` keeps only a part and reads other parts from the server with additional queries. |
| `PlanForDescSQLs` | `string` | | `PLAN` text added to the internal descending queries of `cmkLimitedBufferSize`. |

`cmkLimitedBufferSize` requires an `ORDER BY` clause in `SelectSQL`, no `CachedUpdates`, no parameter named `NEW_...`, and either `AutoCommit` or the same transaction for `Transaction` and `UpdateTransaction`. Otherwise setting it raises an error. `Locate`, `Lookup`, and the `Locate...` family work differently in this mode, see [Locating](#locating).

## Master-detail

A detail dataset has `DataSource` set to the master.

- When the master opens, the detail opens or reopens only if it is already active or `dcForceOpen` is set.
- When the master closes, the detail closes, unless `dcIgnoreMasterClose` is set.
- When the master row changes, the detail reopens if a master value that its parameters use is different, or if a macro of `SelectSQL` changed.

A parameter is matched to the master field with the same name, or with the name after a `MAS_` prefix.

| `TDetailCondition` | Effect |
|--------------------|--------|
| `dcForceMasterRefresh` | Refresh the master row after a row of the detail is deleted (not with `CachedUpdates`) or refreshed (not in edit or insert state). |
| `dcForceOpen` | Open the detail when the master changes, even if it is closed. |
| `dcIgnoreMasterClose` | Do not close the detail when the master closes. |
| `dcWaitEndMasterScroll` | Wait until the master has stopped scrolling for `WaitEndMasterInterval` before reopening the detail. |

Each flag of `DetailConditions` is stored in the form file as its own boolean entry, named `dcForceMasterRefresh`, `dcForceOpen`, `dcIgnoreMasterClose`, and `WaitEndMasterScroll`. The standard default is `[]`.

## Update objects

An update object (`TFIBUpdateObject`) is a query that runs together with the dataset's own statement for one kind of change. It is linked to the dataset through its `DataSet` property, which calls `AddUpdateObject`. `TFIBDataSet` has no property that lists them. The update object has `KindUpdate` (`ukModify`, `ukInsert`, or `ukDelete`), `ExecuteOrder` (`oeBeforeDefault` or `oeAfterDefault`), `OrderInList`, and `Active`; see [TFIBUpdateObject](TFIBUpdateObject.md).

When a row is posted or deleted, the dataset runs, for that kind of change:

1. the active update objects with `oeBeforeDefault`, in the order of `OrderInList`;
2. its own statement (`InsertSQL`, `UpdateSQL`, or `DeleteSQL`);
3. the active update objects with `oeAfterDefault`.

An update object that has an empty `SQL` or the text `No Action` is skipped. For an insert or update, a `No Action` statement of the dataset skips only that statement. For a delete, a `DeleteSQL` of `No Action` ends the delete at once, so the update objects do not run either. Parameters are filled from the row in the same way as for the dataset's own statements (`NEW_` and `OLD_` prefixes). After an update object runs, the row is read back when its statement type is select, execute procedure, or select for update. `Insert`, `Edit`, and `Delete` are allowed when an active update object of that kind exists, even if the matching SQL property is empty.

| Name | Description |
|------|-------------|
| `AddUpdateObject(Value)` | Add an update object to the list of its `KindUpdate`, at its `OrderInList` position. Returns the position, or `-1` for `nil`. |
| `ExecUpdateObjects(KindUpdate, Buff, aExecuteOrder)` | Run the active update objects of one kind and order for a record buffer. For internal use. |
| `ExistActiveUO(KindUpdate)` | `True` when at least one update object of that kind is active. |
| `RemoveUpdateObject(Value)` | Remove an update object from the list. |

## Applying cached updates

With `CachedUpdates`, changes stay in the record cache. `ApplyUpdates` sends them to the server. `UpdateRecordTypes`, `CancelUpdates`, `RevertRecord`, and `CachedUpdateStatus` are in [Editing and cached updates](#editing-and-cached-updates).

```delphi
DataSet.CachedUpdates := True;
DataSet.Open;
DataSet.Edit;
DataSet.FieldByName('NAME').AsString := 'New name';
DataSet.Post;
DataSet.ApplyUpdates;
Transaction.Commit;
```

In both samples `DataSet` is a `TFIBDataSet`, `Database` a `TFIBDatabase`, and `Transaction` a `TFIBTransaction`. The second sample assumes that `UpdateSQL` is set or generated (see [AutoUpdateOptions](#autoupdateoptions)) and that `Transaction` is also the update transaction of the dataset.

`ApplyUpdates` posts a pending edit, starts `UpdateTransaction` when `poStartTransaction` is set, and visits the rows from the first. For each row with a cached status of modified, inserted, or deleted it does the following:

1. When `OnUpdateRecord` is assigned, call it with `UpdateAction` set to `uaFail`; call it again while the handler sets `uaRetry`. Without a handler the action is `uaApply`.
2. When the action is `uaApply` or `uaRetry`, run the statements for the row, but only when `CanEdit`, `CanInsert`, or `CanDelete` allows it. Without `UseExecuteBlock` these are the update objects and the dataset statement, see [Update objects](#update-objects). With `UseExecuteBlock` the row is added to an `EXECUTE BLOCK` batch instead, see below. Then the action becomes `uaApplied`, and `AfterUpdateRecord` is called with `Resume` set to `True`. When the handler sets `Resume` to `False`, `ApplyUpdates` ends with a silent `EAbort`; the remaining rows are not sent, and a batch that was not sent yet is dropped.
3. When `EFIBError` is raised in step 1 or 2, call `OnUpdateError` with `UpdateAction` set to `uaFail`. Other exceptions are not passed to the event.

At the end of a normal run, `UpdatesPending` is `True` only when `OnUpdateError` chose `uaSkip` for some row. With `AutoCommit`, the update transaction is committed at the end, also when rows were skipped, and before an exception is raised (the rows applied before it are marked applied). The client fields are recalculated. When `ApplyUpdates` ends with an exception or `EAbort`, `UpdatesPending` stays `True`.

The `AutoCommit` commit uses `CommitRetaining` when the update transaction is the same as `Transaction`, or when its `TimeoutAction` is `TACommitRetaining`. Rows are not committed one by one during `ApplyUpdates`; without `CachedUpdates`, each posted or deleted row is committed.

Cached status after the statements ran, without `UseExecuteBlock`:

- An inserted or modified row becomes unmodified.
- A deleted row becomes `cusDeletedApplied`, except when `poRefreshAfterDelete` is set and `RefreshSQL` still returns the row (it keeps `cusDeleted`), and when `DeleteSQL` is `No Action` (the row keeps `cusDeleted` and the delete update objects do not run).

`ApplyUpdToBase` leaves the statuses as they were.

| Action | Returned by `OnUpdateRecord` | Chosen in `OnUpdateError` |
|--------|------------------------------|---------------------------|
| `uaApply` | The dataset runs its own statements for the row. | Run the statements for the row (again). |
| `uaRetry` | Call the handler again. | Run the statements for the row again. |
| `uaApplied` | Nothing more is done for the row. | The row counts as done. `AfterUpdateRecord` is not called. |
| `uaSkip` | Nothing more is done for the row. `UpdatesPending` is not set. | Skip the row and go on. `UpdatesPending` is `True` at the end. |
| `uaFail` | Nothing more is done for the row. No error is raised. | Raise the original error again. |
| `uaAbort` | Nothing more is done for the row. No error is raised. | Raise `EAbort` with the message of the error. |

When the error came from `OnUpdateRecord` and `OnUpdateError` chooses `uaApply` or `uaRetry`, processing continues with step 2. `ApplyUpdates` does not change the cached status of a row for which `OnUpdateRecord` returns anything other than `uaApply` or `uaRetry`.

With `UseExecuteBlock`, the code behaves as follows:

- The batch holds statements made by `GenerateSQLTextNoParams` from `UpdateTableName` and `KeyFields`. `InsertSQL`, `UpdateSQL`, `DeleteSQL`, and the update objects are not used, and no `AutoCommit` commit happens per row.
- A batch is sent with `ExecSQLImmediate` when the next statement does not fit, and once at the end. A batch holds at most 255 statements.
- `AfterUpdateRecord` runs when a row is added to the batch, before the batch is sent.
- When a batch that is sent while a row is added fails, `OnUpdateError` is called with the `UpdateKind` of the row being added. If it leaves `uaFail`, the error is raised again inside the row loop and `OnUpdateError` is called a second time for the same error; `uaApply` or `uaRetry` there runs the row again. The batch sent at the end uses the kind of the last row.
- After a batch is sent, the rows registered in it become unmodified (never `cusDeletedApplied`). The registration is also done after `OnUpdateError` chose `uaSkip` for the batch, so skipped rows are marked unmodified too. A delete statement that fits in the current batch is not registered, so its row keeps `cusDeleted`.

| Name | Description |
|------|-------------|
| `ApplyUpdates` | Send the cached changes as described above. Same as `ApplyUpdToBase(False)`. |
| `ApplyUpdToBase(DontChangeCacheFlags)` | The same loop. With `DontChangeCacheFlags` `True` (the default) the rows keep their cached status. Call `CommitUpdToCach` after the transaction commits. |
| `CommitUpdToCach` | Clear the cached update status: inserted and modified rows become unmodified, deleted rows become `cusDeletedApplied`. `UpdatesPending` becomes `False`. |

With `AutoCommit` and `CachedUpdates`, each `Post` and `Delete` runs `ApplyUpdToBase`, commits the update transaction, and runs `CommitUpdToCach`. The last call is made also when `OnUpdateError` chose `uaSkip`, so skipped rows are then marked applied and `UpdatesPending` is `False`.

## Types

| Type | Values |
|------|--------|
| `TAutoUpdateOptions` | Class, see [AutoUpdateOptions](#autoupdateoptions) |
| `TCachedUpdateStatus` | `cusUnmodified`, `cusModified`, `cusInserted`, `cusDeleted`, `cusUninserted`, `cusDeletedApplied` |
| `TCacheModelKind` | `cmkStandard`, `cmkLimitedBufferSize` |
| `TCachRefreshKind` | `frkEdit`, `frkInsert` |
| `TCompareFieldValues` | `function(Field: TField; const S1, S2: Variant): Integer of object` |
| `TDetailCondition`, `TDetailConditions` | See [Master-detail](#master-detail); set of `TDetailCondition` |
| `TEndTrEvent` | `procedure(EndingTR: TFIBTransaction; Action: TTransactionAction; Force: Boolean) of object` (unit `FIBDatabase`) |
| `TFIBAfterUpdateRecordEvent` | `procedure(DataSet: TDataSet; UpdateKind: TUpdateKind; var Resume: Boolean) of object` |
| `TFIBOrderExecUO` | `oeBeforeDefault`, `oeAfterDefault` (unit `FIBDataSet`) |
| `TFIBUpdateAction` | `uaFail`, `uaAbort`, `uaSkip`, `uaRetry`, `uaApply`, `uaApplied` |
| `TFIBUpdateErrorEvent` | `procedure(DataSet: TDataSet; E: EFIBError; UpdateKind: TUpdateKind; var UpdateAction: TFIBUpdateAction) of object` |
| `TFIBUpdateRecordEvent` | `procedure(DataSet: TDataSet; UpdateKind: TUpdateKind; var UpdateAction: TFIBUpdateAction) of object` |
| `TFIBUpdateRecordTypes` | Set of `TCachedUpdateStatus` |
| `TFieldOriginRule` | `forNoRule`, `forTableAndFieldName`, `forClientFieldName`, `forTableAliasAndFieldName` |
| `TFormatFields` | Class, see [Default formats](#default-formats) |
| `TIncludeFieldsToSQL` | `ifsAllFields`, `ifsNoBlob`, `ifsOnlyBlob` |
| `TLockErrorEvent` | `procedure(DataSet: TDataSet; LockError: TLockStatus; var ErrorMessage: string; var Action: TDataAction) of object` |
| `TLockStatus` | `lsSuccess`, `lsDeadLock`, `lsNotExist`, `lsMultiply`, `lsUnknownError` |
| `TOnApplyDefaultValue` | `procedure(DataSet: TDataSet; Field: TField; var Applied: Boolean) of object` (unit `DSContainer`) |
| `TOnApplyFieldRepository` | `procedure(DataSet: TDataSet; Field: TField; FieldInfo: TFIBFieldInfo) of object` (unit `DSContainer`) |
| `TOnBlobFieldProcessing` | `procedure(Field: TBlobField; BlobSize: Integer; Progress: Integer; var Stop: Boolean) of object` (unit `FIBProps`) |
| `TOnFetchRecord` | `procedure(FromQuery: TFIBQuery; RecordNumber: Integer; var StopFetching: Boolean) of object` |
| `TOnFillClientBlob` | `procedure(DataSet: TFIBCustomDataSet; Field: TFIBBlobField; Stream: TFIBBlobStream) of object` |
| `TOnGetSQLTextProc` | `procedure(DataSet: TFIBDataSet; var SQLText: string) of object` |
| `TFIBDataSetOption`, `TFIBDataSetOptions` | See [Dataset options](#dataset-options); set of `TFIBDataSetOption` |
| `TFIBPrepareOption`, `TFIBPrepareOptions` | See [Prepare options](#prepare-options); set of `TFIBPrepareOption` |
| `TFIBSQLKind` | `skModify`, `skInsert`, `skDelete`, `skRefresh`, `skMerge` |
| `TReturningFields`, `TSetReturningFields` | `rfAll`, `rfKeyFields`, `rfBlobFields`; set of `TReturningFields` |
| `TSortFieldInfo` | Record: `FieldName`, `InDataSetIndex`, `InOrderIndex`, `Asc`, `NullsFirst` |
| `TTransactionKind` | `tkReadTransaction`, `tkUpdateTransaction` |
| `TUpdateKinds` | Set of `TUpdateKind` (`ukModify`, `ukInsert`, `ukDelete`) |
| `TWhenGetGenID` | `wgNever`, `wgOnNewRecord`, `wgBeforePost` |

`TLockStatus` values: `lsSuccess` for one row locked, `lsNotExist` for no row, `lsMultiply` for more than one row, `lsDeadLock` for a deadlock or lock conflict, and `lsUnknownError` for any other error.

### Locate options

`TExtLocateOptions` is a set of:

| Value | Effect |
|-------|--------|
| `eloCaseInsensitive` | Ignore case for string fields. |
| `eloInFetchedRecords` | Search only the rows that are already fetched. |
| `eloInSortedDS` | Search by the sort order. Used only when sort information exists (`Sorted`), the key fields are the first sort fields in sort order, and no key field is a string or GUID field combined with `eloCaseInsensitive`; otherwise ignored. |
| `eloNearest` | With `eloInSortedDS`, when nothing matches, move to the nearest row. The function still returns `False`. |
| `eloPartialKey` | A string key matches the start of the value. Wins over `eloWildCards` when both are set. |
| `eloWildCards` | A string key is an SQL mask: `%` matches any characters, `_` one character. |

`Locate`, `LocateNext`, and `LocatePrior` take the `TLocateOptions` of `TDataSet`. Of these, only `loCaseInsensitive` and `loPartialKey` are used; they map to `eloCaseInsensitive` and `eloPartialKey`.

## Run-time properties

### Statement timeout

| Name | Type | Description |
|------|------|-------------|
| `StatementTimeout` | `Cardinal` | Milliseconds, *Firebird 4+*. `0` uses `Database.Session.StatementTimeout`; `FIBNoStatementTimeout` disables the limit. Also assigned to the `TFIBQuery` components the dataset owns. A non-zero value raises `EFIBClientError` when the server or client library cannot apply it. See [Timeouts](../guide/timeouts.md). |

### State

| Name | Type | Description |
|------|------|-------------|
| `AllFetched` | `Boolean` | `True` when the query has no more rows to fetch. |
| `BufferChunks` | `Integer` | Same as `CacheModelOptions.BufferChunks`. |
| `CachedActive` | `Boolean` | `True` while the dataset is open after `CacheOpen`. |
| `CacheSize` | `Integer` | Size of the record cache in bytes (allocated blocks times block size). |
| `CountUpdatesPending` | `Integer` | Number of rows with pending cached updates. |
| `DBHandle`, `TRHandle` | pointers | Native database and transaction handles. |
| `DefaultFields` | `Boolean` | Delphi 2009 to XE5: `True` when the field list is generated and not defined in the form. Unlike the `TDataSet` flag, it is correct also while the dataset is inactive. On XE6 and later the deprecated `TDataSet.DefaultFields` gives the same result; use `Fields.LifeCycles`. |
| `Prepared` | `Boolean` | `True` after `Prepare`. |
| `StatementType` | `TFIBSQLTypes` | Type of the `SelectSQL` statement as reported by the server. |
| `UpdatesPending` | `Boolean` | `True` when cached updates are waiting. |
| `AllRecordCount` | `Integer` | Row count from the server count query of `psAskRecordCount`; `0` when the option is off. Inserted rows increase it. |
| `HasUncommitedChanges` | `Boolean` | `True` after the dataset sent a change to the server, until the update transaction ends or the `SelectSQL` text changes. |
| `HaveRollbackedChanges` | `Boolean` | `True` after the update transaction was rolled back with uncommitted changes of this dataset. Cleared when the `SelectSQL` text changes and when the dataset closes. |
| `VisibleRecno` | `Integer` | `RecNo` counted among the rows that pass the filter. Used as `RecNo` when `poVisibleRecno` is set. |
| `WaitEndMasterInterval` | `Cardinal` | Milliseconds for `dcWaitEndMasterScroll` and `OnEndScroll`. Default `300`. The detail timer reads it at each master change. The `OnEndScroll` timer reads it once, when the event is assigned; a later change has no effect on it. The property is not published, so handlers loaded from a DFM use `300`. |
| `WaitEndMasterScroll` | `Boolean` | `True` when `dcWaitEndMasterScroll` is on; setting it changes `DetailConditions`. |

### Queries and parameters

| Name | Type | Description |
|------|------|-------------|
| `Params` | `TFIBXSQLDA` | Parameters of `SelectSQL`. |
| `QSelect`, `QInsert`, `QUpdate`, `QDelete`, `QRefresh` | `TFIBQuery` | The internal queries behind the five SQL properties. |
| `RelationTables` | `TStringList` | Names of the tables the fields come from. Filled when the dataset opens. |

### SQL clauses

These properties read and rewrite parts of `SelectSQL` through `QSelect`; see [TFIBQuery](TFIBQuery.md#parameters-and-sql). Because they change the text of `SelectSQL`, the dataset must be closed.

| Name | Type | Description |
|------|------|-------------|
| `FieldsClause` | `string` | Column list. |
| `GroupByClause` | `string` | `GROUP BY` text. |
| `MainWhereClause` | `string` | Main `WHERE` clause. |
| `OrderClause` | `string` | `ORDER BY` text. |
| `PlanClause` | `string` | `PLAN` text. |

### Sorting information

| Name | Type | Description |
|------|------|-------------|
| `SortFields` | `Variant` | Internal description of the sort fields; `Null` when not sorted. Use the methods in [Sorting](#sorting). |
| `Sorted` | `Boolean` | `True` when sort information is available: from the `ORDER BY` of `SelectSQL` when `psGetOrderInfo` is set, or from `DoSort`. |

## Methods

### Opening, preparing, and transactions

| Name | Description |
|------|-------------|
| `CacheOpen` | Open without executing `SelectSQL`. |
| `CanCloneFromDataSet(DataSet)` | `True` when field count, types, sizes, and kinds match, and there are no `ftBlob` or `ftBytes` fields. |
| `Clone(DataSet, RecreateFields, FullCopyProperties)` | Copy the field structure and the fetched rows of an open `TFIBCustomDataSet`, and open without running the query. With `FullCopyProperties`, copy the component properties first. |
| `CloseOpen(DoFetchAll)` | Close and open again, keeping automatic fields. Fetches all rows when `DoFetchAll` is `True`. Opens a closed dataset. |
| `OpenAsClone(DataSet)` | Open with a copy of the rows of another open dataset, see `Clone`. Raises when the field lists do not match and the fields are not automatic. |
| `Prepare` | Start the transaction if `poStartTransaction` is set, prepare `SelectSQL`, and read the field definitions. When `psApplyRepositary` is set and `DataSet_ID` is not `0`, load the repository row first. At design time it also prepares the update, insert, and delete statements. Raises if `SelectSQL` is empty. |
| `StartTransaction` | Assign the default `Database` and `Transaction` when missing, and start `Transaction` if it is not active and `poStartTransaction` is set. |
| `UnPrepare` | Release all five statements on the server. |

### Fetching and refreshing

| Name | Description |
|------|-------------|
| `DisableCalcFields` / `EnableCalcFields` | Suspend and resume calculated fields. Calls nest; the last `EnableCalcFields` recalculates. |
| `DisableCloseOpenEvents` / `EnableCloseOpenEvents` | Suspend and resume the `BeforeOpen`, `BeforeClose`, and `AfterClose` events, and the release of statements by `poFreeHandlesAfterClose`. Calls nest. |
| `DisableScrollEvents` / `EnableScrollEvents` | Suspend and resume `BeforeScroll` and `AfterScroll`. Calls nest. |
| `FetchAll` | Read all remaining rows into the cache, keeping the current position. |
| `FetchNext(FetchCount)` | Read up to `FetchCount` more rows; returns the number read. |
| `FullRefresh` | Run the query again and return to the current row. In the standard cache it calls `ReopenLocate('')`: when `RefreshSQL` is empty or does not find the row, the dataset reopens at the first row. With `cmkLimitedBufferSize`, refresh the part around the current row with `RefreshSQL`. |
| `Refresh` | Inherited. Runs `RefreshSQL` for the current row. |
| `RefreshClientFields(ForceCalc)` | Recompute calculated and lookup fields. |
| `RefreshFilters` | Apply `Filter` again: recomputes the client fields, then moves to the first row if the current row changed. |
| `ReopenLocate(LocateFieldNames)` | Reopen the dataset and locate the row that had the values of `LocateFieldNames` (a `;` list). When empty, the non-BLOB data fields of the current row are used, provided `RefreshSQL` is set and finds the row. Not allowed with `UniDirectional`. |

### Editing and cached updates

| Name | Description |
|------|-------------|
| `BlobModified(Field)` | `True` when the BLOB value of the current row was changed. |
| `CacheDelete` | Remove the current row from the cache and mark it `cusDeletedApplied`, without sending any statement to the server. |
| `CachedUpdateStatus` | `TCachedUpdateStatus` of the current row. |
| `CancelUpdates` | Cancel the edit in progress and revert all cached changes. |
| `MoveRecord(OldRecno, NewRecno, NeedResync)` | Move a row inside the cache; fetches all rows when `NewRecno` is beyond the fetched part. |
| `RecordModified(Value)` | Set the `Modified` flag of the dataset, not of a row. |
| `RevertRecord` | Revert the cached changes of the current row. Only with `CachedUpdates`. |
| `SetRecordPosInBuffer(NewPos)` | Move the active record inside the data-aware buffer without scroll events. Returns the new position. |
| `SwapRecords(Recno1, Recno2)` | Swap two cached rows. Numbers are 1-based. Ignores positions out of range. |
| `Undelete` | Bring back a row deleted in the cache but not yet applied, or a row inserted and then deleted. |
| `UpdateStatus` | `TUpdateStatus` of the current row. |

### Locating

All `Locate` methods post a pending edit first, honor `Filter`, and return `False` on an empty dataset.

| Name | Description |
|------|-------------|
| `ExtLocate(KeyFields, KeyValues, Options)` | Like `Locate` with `TExtLocateOptions`, see [Locate options](#locate-options). |
| `ExtLocateNext(KeyFields, KeyValues, Options)` / `ExtLocatePrior(KeyFields, KeyValues, Options)` | `ExtLocate` from the next or previous row. Return `False` at the end or beginning. |
| `Locate(KeyFields, KeyValues, Options)` | Inherited signature with `TLocateOptions`. Searches the cache from the first row, fetching more rows as needed, and centers the found row. |
| `LocateNext(KeyFields, KeyValues, Options)` / `LocatePrior(KeyFields, KeyValues, Options)` | `Locate` from the next or previous row. Return `False` at the end or beginning. |
| `Lookup(KeyFields, KeyValues, ResultFields)` | Value of `ResultFields` for the first matching row, or `Null`. The cursor position does not change. In the standard cache the match is exact and case-sensitive, without options. |

With `cmkLimitedBufferSize`:

- `Locate` and `ExtLocate` run a query on the server. Only `eloCaseInsensitive`, `eloPartialKey`, and `eloWildCards` apply; the other options are ignored.
- `LocateNext`, `LocatePrior`, and their `Ext` forms search the fetched rows first, then the server.
- `Lookup` searches the fetched rows first, then runs a query.

### Sorting

| Name | Description |
|------|-------------|
| `AnsiCompareString`, `StdAnsiCompareString`, `StdCompareValues` | Comparison functions with the signature of `OnCompareFieldValues`. |
| `DoSort(Fields, Ordering)` | Sort the cached rows on the client. `Fields` holds field indexes, names, or `TField` objects; `Ordering` has `True` for ascending, per field. Fetches all rows first and posts a pending edit. |
| `DoSortEx(Fields, Ordering)` | The same with an `array of Integer` of field indexes, or a `TStrings` of field names. |
| `IsSortedField(Field, FieldSortOrder)` | `True` and fills `FieldSortOrder` when `Field` is a sort field. |
| `SortedFields` | Sort field names as a `;` list. |
| `SortFieldInfo(OrderIndex)` | `TSortFieldInfo` of a sort field by its 1-based position. For an invalid index, `FieldName` is `'Unknown'` and `InOrderIndex` is `-1`. |
| `SortFieldsCount` | Number of sort fields. |
| `SortInfoIsValid` | `True` when sort fields are set and every one exists in the dataset. |

### Fields and metadata

| Name | Description |
|------|-------------|
| `AllFieldValues` | Values of all fields of the current row as a variant array. |
| `AssignProperties(Source)` | Copy the component properties from another dataset. The dataset must be closed. |
| `BlobFieldCodePage(Field)` / `StringFieldCodePage(Field)` | Code page for a text BLOB or a string column. |
| `CopyFieldsProperties(Source, Destination)` | Copy display settings, constraints, and formats between fields with the same name. |
| `CopyFieldsStructure(Source, RecreateFields)` | Copy field definitions from another dataset; the dataset must be closed. |
| `CreateBlobStream(Field, Mode)` | Stream for a BLOB or array value; see [BLOBs and arrays](../guide/blobs-and-arrays.md). |
| `CreateCalcField(FieldClass, aName, aFieldName, aSize)` | Create a calculated field. |
| `CreateCalcFieldAs(Field)` | Create a field with the same kind and lookup settings as `Field`. |
| `CreateLookUpField(FieldClass, aName, aFieldName, aSize, aLookupDataSet, aKeyFields, aLookupKeyFields, aLookupResultField)` | Create a lookup field. |
| `DomainForField(Fld)` | Domain name of the column. `Fld` is an index or a name. |
| `FBN(FieldName)` | `FieldByName` with a cache; raises when the field is missing. |
| `FieldByOrigin(aOrigin)` / `FieldByOrigin(TableName, FieldName)` | Field by its source table and column. The one-argument form takes `TABLE.FIELD`. |
| `FieldByRelName(FName)` | Field by source column name. |
| `FN(FieldName)` | `FindField` with a cache; returns `nil` when missing. A name in double quotes is looked up without the quotes. |
| `GetFieldOrigin(Fld)` | Origin text for a field, according to `FieldOriginRule`. |
| `GetRecordFieldInfo(Field, TableName, FieldName, RecordKeyValues)` | Table, column, and primary key values of the current row for a field. Returns `False` when the table has no primary key or a key column is not in the dataset. |
| `GetRelationFieldName(Field)` / `GetRelationTableName(Field)` | Source column and table of a field or field definition. |
| `IsComputedField(Fld)` | `True` for a computed column. `Fld` is an index or a name. |
| `PrimaryKeyFields(TableName, RelFieldName)` | Dataset field names (or table column names) of the primary key of `TableName`, as a `;` list. Empty when a key column is not in the dataset. |
| `RecordFieldValue(Field, RecNumber)` / `RecordFieldValue(Field, aBookmark)` | Value of a field in a cached row, without moving. `RecNumber` is 1-based. Requires an active dataset, and raises for a row outside the cached part with `cmkLimitedBufferSize`. `Null` for an invalid bookmark. |
| `SQLFieldName(aFieldName)` | Name of a field as written in the SQL. |
| `StringFieldCharSetID(Field)` | Character set ID of a string column, or `-1` for calculated and lookup fields. |
| `TableAliasForField(aFieldName)` | Table alias used for a field in `SelectSQL`. |

### Arrays

Available when array support is compiled in.

| Name | Description |
|------|-------------|
| `ArrayFieldValue(Field)` | Array value of the current row as a variant array. |
| `GetElementFromValue(Field, Indexes)` | One element of the array. |
| `SetArrayElementValue(Field, Value, Indexes)` | Change one element. |
| `SetArrayValue(Field, Value)` | Set the whole array. `Null` or empty clears it. Requires edit or insert state. |

### SQL text, parameters, and master-detail

| Name | Description |
|------|-------------|
| `ApplyConditions(Reopen)` | Close, apply the switched-on `Conditions` to `SelectSQL`, and optionally open again. |
| `CancelConditions` | Close and remove the applied conditions. |
| `DisableMasterSource` / `EnableMasterSource` | Ignore and again follow changes of the master. Calls nest. |
| `MasterSourceDisabled` | `True` while master changes are ignored. |
| `ReadySelectText` | `SelectSQL` after macros and conditions, as sent to the server. |
| `RestoreMacroDefaultValues` | Set the macros of `SelectSQL` back to their defaults. |
| `SetParamValues(ParamValues)` / `SetParamValues(ParamNames, ParamValues)` | Set the parameters of `SelectSQL` from arrays. |

### Parameters and opening

| Name | Description |
|------|-------------|
| `FindParam(ParamName)` | Parameter of `SelectSQL` by name, or `nil`. Starts the transaction first. |
| `OpenWP(ParamValues)` / `OpenWP(ParamNames, ParamValues)` | Set the parameters, then `Open`. The first form sets parameters by position; it sets nothing when the array is empty. The second takes the names as a string. |
| `OpenWPS(ParamSources)` | Take parameter values from `ISQLObject` sources, then `Open`. |
| `ParamByName(ParamName)` | Parameter of `SelectSQL` by name. Raises when missing. |
| `ParamNameCount(aParamName)` | Number of parameters with this name. |
| `ParseParamToFieldsLinks(Dest)` | Add `FieldName=ParamName` lines to `Dest`: for each parameter, the field name found before the operator that precedes the parameter in a `WHERE` clause of `SelectSQL`. With a table alias, the name of the matching dataset field is used. |
| `RecordCountFromSrv` | Run the count query and return its result. `0` when the transaction is not active. |
| `ReOpenWP(...)`, `ReOpenWPS(...)` | `Close`, then `OpenWP` or `OpenWPS` with the same arguments. |

### Generated SQL

| Name | Description |
|------|-------------|
| `AllKeyFields(TableName)` | Names of all non-BLOB dataset fields that belong to the table, separated by `;`. |
| `AutoGenerateSQLText(ForState)` | Generate `UpdateSQL` (`dsEdit`) or `InsertSQL` (`dsInsert`) from the changed fields, when `UpdateOnlyModifiedFields`, `KeyFields`, and `UpdateTableName` are set; then update the BLOB update object. Called before a post. |
| `CanGenerateSQLs` | `True` when `UpdateTableName` is not empty. |
| `GenerateSQLs` | Generate `DeleteSQL`, `UpdateSQL`, `InsertSQL`, and `RefreshSQL` from `UpdateTableName` and `KeyFields`. Fills `KeyFields` first when empty. Does nothing when no key field is found. See `CanChangeSQLs`. |
| `GenerateSQLText(TableName, KeyFieldNames, SK, IncludeFields, ReturningFields)` | Statement text for one table and kind (`TFIBSQLKind`, see [Types](#types)); `skMerge` makes `UPDATE OR INSERT ... MATCHING` on the key fields. `IncludeFields` is `ifsAllFields` (default), `ifsNoBlob`, or `ifsOnlyBlob`; `skMerge` always includes the key fields. Returns an empty string when the table is not known or `KeyFieldNames` has no field, and `No Action` when no field qualifies (`INSERT ... DEFAULT VALUES` for `skInsert`). Raises when no key field of the table remains. |
| `GenerateSQLTextNoParams(TableName, KeyFieldNames, SK)` | The same for `skModify`, `skInsert`, `skDelete`, `skRefresh`, and `skMerge`, with the current and old values written as literals. An `skInsert` without fields is `INSERT INTO <table> DEFAULT VALUES`; otherwise it returns an empty string when no field qualifies. |
| `GenerateSQLTextWA(TableName, SK, IncludeFields)` | `GenerateSQLText` with `AllKeyFields(TableName)` as the key, so the `WHERE` clause compares all fields. |
| `GenerateUpdateBlobsSQL` | With `SeparateBlobUpdate` and BLOB fields, create or update the internal update object that writes them. |
| `IncGenerator` | Virtual. When `WhenGetGenID` is not `wgNever` and the key field (`KeyField`) is numeric and empty, set it with `Database.Gen_Id(GeneratorName, GeneratorStep, Transaction)`. Called when a row is created (`wgOnNewRecord`) or before it is posted (`wgBeforePost`). |
| `KeyField` | The field named by `KeyFields`; a single name only. `nil` when missing. |
| `SqlTextGenID` | `SELECT GEN_ID(<GeneratorName>,1) FROM RDB$DATABASE`. |

### Locking

| Name | Description |
|------|-------------|
| `LockRecord(RaiseErr)` | Lock the current row in the update transaction and return a `TLockStatus`. The statement is the text from `OnLockSQLText` if set. Otherwise it is `SELECT 0 FROM <table> WHERE <key> FOR UPDATE WITH LOCK` with `poUseSelectForLock`, and an `UPDATE` that sets a field of the table to its own value without it. When no field of the table is in the dataset, `UpdateSQL` itself is run. The key comes from `AutoUpdateOptions.KeyFieldList` when `UpdateSQL` is empty, or when `AutoReWriteSqls` and `UpdateOnlyModifiedFields` are both set; otherwise from the `WHERE` clause of `UpdateSQL`. It raises when the key source is `KeyFieldList` and `AutoReWriteSqls` is off or the list is empty. With `RaiseErr` and a failure, `OnLockError` can change the message or choose the action (`daFail` raises, `daAbort` aborts, `daRetry` tries again). |

### Editing permissions

`CanEdit`, `CanInsert`, and `CanDelete` are `True` when the statement for the change exists (`UpdateSQL`, `InsertSQL`, or `DeleteSQL` is not empty; with `CachedUpdates` a row inserted in the cache can also be edited when `UpdateSQL` is empty), or an active update object of that kind exists, or generation of statements is active (`UpdateOnlyModifiedFields`, `AutoReWriteSqls`, `CanChangeSQLs`, `KeyFields`, and `UpdateTableName` all set), or `CachedUpdates` is on with an `OnUpdateRecord` handler; and the kind is in `AllowedUpdateKinds`. `Insert` and `Edit` are also allowed while the dataset refreshes its cache.

### Record cache

These methods change the cache only. They send no statement and do not mark a row as changed.

| Name | Description |
|------|-------------|
| `CacheAppend(aFields, Values)` / `CacheAppend(Value, DoRefresh)` | Append a row. The first form takes field indexes and values. The second sets the first field and, with `DoRefresh`, reads the row again with `RefreshSQL`. |
| `CacheEdit(aFields, Values)` | Change fields of the current row by index. |
| `CacheInsert(aFields, Values)` / `CacheInsert(Value, DoRefresh)` | Insert a row before the current one, like `CacheAppend`. |
| `CacheModify(aFields, Values, KindModify)` | Base of the three above. `KindModify` is `0` to edit, `1` to insert, `2` to append. The dataset must be in browse state. |
| `CacheRefresh(FromDataSet, Kind, FieldMap)` | Copy the current row of `FromDataSet` into the current row, by field name or through `FieldMap` (`SourceName=DestName` lines). `Kind` is `frkEdit` or `frkInsert`. Read-only fields are also written. The row gets the unmodified status. |
| `CacheRefreshByArrMap(FromDataSet, Kind, SourceFields, DestFields)` | `CacheRefresh` with the map given as two arrays. |
| `RefreshFromDataSet(RefreshDataSet, KeyFields, IsDeletedRecords, DoAdditionalRefreshRec)` | For each row of `RefreshDataSet` (opened when closed), find the row with the same `KeyFields`: delete it from the cache when `IsDeletedRecords` is `True`, otherwise update it with `CacheRefresh`; a row that is not found is inserted, unless `IsDeletedRecords`. With `DoAdditionalRefreshRec`, each row is then read again with `RefreshSQL`. The filter is switched off during the search, and the current row is restored by its key. |
| `RefreshFromQuery(RefreshQuery, KeyFields, IsDeletedRecords, DoAdditionalRefreshRec)` | The same with the rows of a `TFIBQuery`, executed after its parameters are set from the dataset parameters of the same name. With `DoAdditionalRefreshRec`, only the key fields are taken from the query. |

### Records and fields

| Name | Description |
|------|-------------|
| `CloneCurRecord(IgnoreFields)` | `CloneRecord` for the current row. |
| `CloneRecord(SrcRecord, IgnoreFields)` | Insert a new row, or use the one being inserted, and copy the data fields of the cached row `SrcRecord` (1-based) into it. `IgnoreFields` is an open array of field indexes, names, `TField` objects, or `TStrings`. Does nothing when `SrcRecord` is out of range. |
| `FieldByFieldNo(FieldNo)` | Field by `FieldNo`. |
| `RecordFieldAsFloat(Field, RecNumber, IsVisibleRecordNum)` | Value of a field in a cached row as `Double`, without moving. `RecNumber` is zero-based. With `IsVisibleRecordNum` (default `True`) it counts only the rows that pass the filter. Returns `0` when `RecNumber` is above the number of cached rows. |
| `RecordStatus(RecNumber)` | `TUpdateStatus` of a cached row; `RecNumber` is zero-based. A removed row gives `usDeleted`. |
| `VisibleRecordCount` | Number of rows that pass the filter among the cached rows. Without a filter, `RecordCount`. |
| `VisibleRecnoToRecno(VisRN)` | Convert a row number counted among visible rows into one counted among all cached rows. |

### Save and load

| Name | Description |
|------|-------------|
| `LoadFromFile(FileName)` / `LoadFromFile(FileName, AddInfo)` | `LoadFromStream` from a file, then read the sort information from `SelectSQL`. |
| `LoadFromStream(Stream, SeekBegin)` / `LoadFromStream(Stream, SeekBegin, AddInfo)` | Read the field definitions and rows written by `SaveToStream` and open the dataset if it is closed. Moves to the first row. `AddInfo` returns the string saved with the data. Does nothing at design time. Raises when the stream signature or version (7 or later) is wrong, or the stream does not fit the fields. |
| `SaveToFile(FileName, AddInfo)` | `SaveToStream` into a new file. |
| `SaveToStream(Stream, SeekBegin, AddInfo)` | Fetch all rows, then write the signature `FIB$DATASET`, the field definitions, the cache, and `AddInfo`. With `SeekBegin`, go to the start of the stream first. |

### `ISQLObject` members

`TFIBCustomDataSet` implements `ISQLObject`, so a dataset can be a parameter source for `TFIBQuery.ExecWPS`. All members work on `SelectSQL` and on the current row.

| Name | Description |
|------|-------------|
| `DefMacroValue(MacroName)` | Default value of a macro of `SelectSQL`. |
| `FieldExist(FieldName, FieldIndex)`, `FieldsCount`, `FieldName(FieldIndex)`, `FieldValue(FieldName, Old)` / `FieldValue(FieldIndex, Old)` | Fields of the current row. With `Old`, `FieldValue` returns the old value of the field. |
| `IEof`, `INext` | `Eof` and `Next`. |
| `ParamCount`, `ParamExist(ParamName, ParamIndex)`, `ParamName(ParamIndex)`, `ParamValue(ParamName)` / `ParamValue(ParamIndex)`, `SetParamValue(ParamIndex, aValue)` | Parameters of `SelectSQL`. |

### Batch and export

| Name | Description |
|------|-------------|
| `BatchAllRecordsToQuery(ToQuery)` | Run `BatchRecordToQuery` for every row from the first. The position is restored. |
| `BatchRecordToQuery(ToQuery)` | Take the parameters of `ToQuery` from the current row (fields of the same name), then run it. |
| `BatchInput(InputObject, SQLKind)` | Run `InsertSQL` (default), `UpdateSQL`, `DeleteSQL`, or `RefreshSQL` for each row of a `TFIBBatchInputStream`. `SQLKind` is `skInsert`, `skModify`, `skDelete`, or `skRefresh`. |
| `BatchOutput(OutputObject)` | Run a copy of `SelectSQL` with the current parameter values and write the rows to a `TFIBBatchOutputStream`. |
| `ExportDataToScript(OutPut, TableName, AllFields)` | Write the rows as SQL statements for `TableName` into `OutPut`. `TableName` defaults to `AutoUpdateOptions.UpdateTableName`. Without `AllFields`, only fields of that table are written. |
| `ExportDataToScriptFile(FileName, TableName, AllFields)` | The same into a file. |

### Checks

| Name | Description |
|------|-------------|
| `CheckDatasetClosed(Reason)` / `CheckDatasetOpen(Reason)` | Raise if the dataset is open, or inactive. |
| `CheckNotUniDirectional` | Raise if `UniDirectional` is set. |

## Events

Events of `TDataSet` (`BeforeOpen`, `AfterPost`, `OnNewRecord`, and so on) are published as usual. Added events:

### Fetching and fields

| Name | Description |
|------|-------------|
| `AfterFetchRecord` | After a row is stored in the cache. Setting `StopFetching` ends the fetch, keeps the row, and ends with a silent `EAbort`. `FromQuery` can also be `QRefresh`. With `UniDirectional` or `cmkLimitedBufferSize`, `RecordNumber` is already reduced modulo `BufferChunks`. |
| `BeforeFetchRecord` | Called by `QSelect` before it requests the next row from the server; `RecordNumber` is the number of rows already fetched. Setting `StopFetching` ends the fetch: no more rows are read, `QSelect.Eof` and `AllFetched` are set, and the cached rows are the whole result until the dataset is reopened. |
| `OnCompareFieldValues` | Compares two values for sorting. See `TCompareFieldValues`. |
| `OnDisableControls` / `OnEnableControls` | `DisableControls` and `EnableControls` changed the state of the controls. |
| `OnEndScroll` | The dataset has not scrolled for `WaitEndMasterInterval` milliseconds. The timer restarts on each `AfterScroll`, which is skipped while scroll events are disabled, but a timer started earlier can still fire after `DisableScrollEvents`. |
| `OnFieldChange` | A field value changed. |
| `OnFillClientBlob` | Fills a BLOB field that has `IsClientField` set. |
| `OnGetRecordError` | A database error while reading a row. Set `Action` to `daFail` (default, raises) or `daAbort`. |
| `OnReadBlobField` / `OnWriteBlobField` | Progress of a BLOB read or write. Set `Stop` to cancel. |

### Dataset behavior and containers

| Name | Description |
|------|-------------|
| `OnApplyDefaultValue` | A new row gets the value of a field from its `DefaultExpression`. Set `Applied` to `True` when the handler supplies the value. See [New row defaults](#new-row-defaults). |
| `OnApplyFieldRepository` | After the settings of `FIB$FIELDS_INFO` are applied to a field (`psApplyRepositary`). `FieldInfo` is the `TFIBFieldInfo` of the column. |
| `OnAskRecordCount` | `psAskRecordCount` needs the count query. Set `SQLText` to a query that returns the number of rows; leave it empty for the default. Its parameters are filled from the parameters of `SelectSQL` by name. |
| `OnDeleteError`, `OnPostError` | Same as the `TDataSet` events. The handlers of the global container and the dataset's container run before them. |
| `OnFilterRecord` | `TDataSet` event, published. Runs after the text `Filter` accepts the row, only when `Filtered` is `True`. |
| `OnLockError` | `LockRecord` failed with `RaiseErr`. The handler can change `ErrorMessage` and set `Action` to `daFail` (raise, the default), `daAbort`, or `daRetry`. |
| `OnLockSQLText` | `LockRecord` asks for the lock statement. Set `SQLText` to replace the generated text. Parameters are filled from the current row by field name; the `OLD_` prefix gives the old value. |

The events `BeforeOpen`, `AfterOpen`, `BeforeClose`, `AfterClose`, `BeforeInsert`, `AfterInsert`, `BeforeEdit`, `AfterEdit`, `BeforePost`, `AfterPost`, `BeforeCancel`, `AfterCancel`, `BeforeDelete`, `AfterDelete`, `BeforeScroll`, `AfterScroll`, `OnNewRecord`, `OnCalcFields`, `BeforeRefresh`, and `AfterRefresh` are also reported to the containers. First the global container (the one with `IsGlobalContainer`, one per thread) receives them in `OnDataSetEvent`, then the container in `Container`. `OnPostError` and `OnDeleteError` go to `OnDataSetError` of the containers, `OnApplyDefaultValue` and `OnApplyFieldRepository` to the events of the same name, and sorting asks `OnCompareFieldValues` of the containers first.

#### Protected, for descendants

| Name | Description |
|------|-------------|
| `AddedFilterRecord(DataSet, Accept)` | Virtual and empty. Called last when a row passes `Filter` and `OnFilterRecord`, only when `Filtered` is `True`; set `Accept` to `False` to hide the row. |
| `ClearModifFlags(Kind, NeedRefreshFields)` | Set the cached status of all rows. `Kind` `0` is `CommitUpdToCach`; `1` makes every row that is not unmodified or `cusDeletedApplied` unmodified (used by `poProtectedEdit`). |
| `InternalDeleteRecord(Qry, Buff)` | Override. Runs the delete update objects and `DeleteSQL`, then applies `poRefreshAfterDelete` and `AutoCommit`. Returns at once when `DeleteSQL` is `No Action`. |
| `InternalPostRecord(Qry, Buff)` | Override. Runs the update objects and the insert or update statement, applies `poRefreshAfterPost`, and commits with `AutoCommit` when `CachedUpdates` is off. |
| `DoOnApplyDefaultValue(Field, Applied)` | Dynamic. Raises the containers' events and `OnApplyDefaultValue`. |
| `UpdateFieldsProps` | Virtual. Applies `DefaultFormats`, `PrepareOptions`, and repository settings to the fields. Runs when the dataset opens. |

### Updates

These three events are raised only by `ApplyUpdates`, once for each pending row. The rules for the `UpdateAction` values are in [Applying cached updates](#applying-cached-updates).

| Name | Description |
|------|-------------|
| `AfterUpdateRecord` | Called after a row was sent (not after `uaApplied`, `uaSkip`, `uaFail`, or `uaAbort` from `OnUpdateRecord`). Setting `Resume` to `False` ends `ApplyUpdates` with a silent `EAbort`. Rows after it are not sent, and an unsent `EXECUTE BLOCK` batch is dropped. |
| `OnUpdateError` | Called when sending a row, the `OnUpdateRecord` or `AfterUpdateRecord` handler, or an `EXECUTE BLOCK` batch raises `EFIBError`. `UpdateAction` is `uaFail` on entry. `uaFail` re-raises the error, and `uaAbort` raises `EAbort` with the message of the error. `uaSkip` leaves the row pending. `uaApply` and `uaRetry` send the row again. `uaApplied` counts the row as done. |
| `OnUpdateRecord` | Called for each pending row before it is sent. `UpdateAction` is `uaFail` before each call. Set it to `uaApply` to let the dataset run its statements (also the action when no handler is set), `uaApplied` or `uaSkip` to send nothing, or `uaRetry` to call the event again. `uaFail` and `uaAbort` send nothing and raise no error. |

### Connection and transactions

| Name | Description |
|------|-------------|
| `AfterEndTransaction` / `BeforeEndTransaction` | `Transaction` ends; parameters are the transaction, the action, and `Force`. |
| `AfterEndUpdateTransaction` / `BeforeEndUpdateTransaction` | `UpdateTransaction` ends; same parameters. |
| `AfterStartTransaction` / `BeforeStartTransaction` | `Transaction` starts. |
| `AfterStartUpdateTransaction` / `BeforeStartUpdateTransaction` | `UpdateTransaction` starts. |
| `DatabaseDisconnected`, `DatabaseFree` | The database disconnected, or is being freed. |
| `DatabaseDisconnecting` | The database is about to disconnect. The dataset has already closed, or fetched all rows when `CachedUpdates` or `poDontCloseAfterEndTransaction` is set. |
| `TransactionEnded`, `TransactionFree` | `Transaction` ended, or is being freed. |
| `TransactionEnding` | `Transaction` is about to end, also for the retaining operations. The cursor closes only on commit and rollback. Raised before the dataset closes, or fetches all rows and closes the cursor under `CachedUpdates` or `poDontCloseAfterEndTransaction`. |

## Constants

| Name | Description |
|------|-------------|
| `vBufferCacheSize` | Default `BufferChunks`, `32`. |
| `vMinBufferChunksForLimCache` | Minimum `BufferChunks` for `cmkLimitedBufferSize`, `100`. |

`FIBNoStatementTimeout` is documented in [TFIBQuery](TFIBQuery.md#constants).

## Field classes

The dataset creates these `TField` descendants for the columns of `SelectSQL`. Members that come from the `TField` base classes are not repeated. Which `TFieldType` a column gets depends on the server type and on `PrepareOptions`.

| Class | Created for | Added members |
|-------|-------------|---------------|
| `TFIBArrayField` | `ftBytes` (array columns), when array support is compiled in | `DimensionCount`, `ElementType`, `Dimension[Index]`, `ArraySize`, `ArrayID`. Its text is `(ARRAY)`, or `(Array)` when null. |
| `TFIBBCDField` | `ftBCD`: `BIGINT` (scale 0) unless `psUseLargeIntField` is set, and scaled 64-bit `NUMERIC` with scale up to 4, or any scale with `psSQLINT64ToBCD` | `AsInt64` (whole part), `AsBcd`, `AsExtended`, `Value`, `FieldModified`, and in-place arithmetic: `AddExtended`, `SubtractExtended`, `MultiplyExtended`, `DivideExtended`, `AddBCD`, `SubtractBCD`, `MultiplyBCD`, `DivideBCD`. Published: `Size` (default `8`). |
| `TFIBBlobField` | `ftBlob`, `ftFmtMemo`, `ftParadoxOle`, `ftDBaseOle`, `ftTypedBinary` | `SubType`, `Blob_ID`, `GetBlobInfo`. Published: `IsClientField` (default `False`): the value is not read from the server but filled in `OnFillClientBlob`. |
| `TFIBBooleanField` | `ftBoolean` | Published: `StringTrue`, `StringFalse` (text used by `AsString`). `SetAsString` also accepts `1`, `T`, `0`, `F`. A `SMALLINT` or `INTEGER` column also becomes a boolean field when `psUseBooleanField` is set and its metadata allows it. |
| `TFIBDateField` | `ftDate` | |
| `TFIBDateTimeField` | `ftDateTime` | `AsTimeStamp`. Published: `ShowMsec` (default `False`). |
| `TFIBFloatField` | `ftFloat` | `Scale` (read-only). Published: `RoundByScale` (default `True`): a value assigned to a field with a decimal scale is rounded to that scale. Assigning a value out of range raises a range error for a scaled `SMALLINT` or `INTEGER` column. |
| `TFIBFMTBCDField` | `ftFMTBcd`: `INT128`, `NUMERIC(19..38)`, `DECFLOAT(16)`, `DECFLOAT(34)` (*Firebird 4+*) | A `DECFLOAT` value that `TBcd` cannot hold (`NaN`, `Infinity`, more than 64 digits) is read as text by `AsString` and `DisplayText`, and as `Double` by `AsFloat` and `Value`; `AsBCD`, `AsCurrency`, `AsInteger`, and `AsLargeInt` raise a conversion error for it. |
| `TFIBGuidField` | `ftGuid` | `AsGuid`. |
| `TFIBIntegerField` | `ftInteger` | `AsBoolean`: `True` for a value above `0`; setting it writes `1` or `0`. |
| `TFIBLargeIntField` | `ftLargeint` | `OldValue` as `Int64`. |
| `TFIBMemoField` | `ftMemo`, `ftWideMemo` | `SubType`, `Blob_ID`, `GetBlobInfo`. |
| `TFIBSmallIntField` | `ftSmallint` | `AsBoolean`: `True` for a value above `0`; setting it writes `1` or `0`. |
| `TFIBStringField` | `ftString` | `IsDBKey` (`True` for a `DB_KEY` column), `SqlSubType`, `CharacterSet` (name), `AsNativeData` and `AsOctetsData` (raw bytes; `AsOctetsData` can be set), `DefaultValueEmptyString`. Published: `EmptyStrToNull`. |
| `TFIBTimeField` | `ftTime` | Published: `ShowMsec` (default `False`): append the milliseconds to the text when they are not zero. |
| `TFIBWideStringField` | `ftWideString` | `SqlSubType`, `CharacterSet`, `CollateNumber`, `AsNativeData`. Published: `EmptyStrToNull`. |

`ftGraphic` fields use the standard `TGraphicField`.

`EmptyStrToNull` takes its initial value from `psSetEmptyStrToNull` in `PrepareOptions`. When it is `True`, an empty string assigned to the field is stored as `NULL`, except for a `NOT NULL` column whose default is an empty string.

## See also

- [TFIBQuery](TFIBQuery.md), [TFIBDatabase](TFIBDatabase.md), [TFIBTransaction](TFIBTransaction.md)
- [TFIBUpdateObject](TFIBUpdateObject.md)
- [TFIBClientDataSet](TFIBClientDataSet.md), which uses the provider support of this class
- [Datasets and caching](../guide/datasets-and-caching.md)
- [Timeouts](../guide/timeouts.md)
