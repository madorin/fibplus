# TpFIBDataSet

The dataset to use in applications. It adds to [TFIBDataSet](TFIBDataSet.md): SQL statements generated from the table and key fields, key generators, update objects, applying cached updates, record locking, metadata-driven field properties, and saving the record cache to a file. It is the dataset that is registered on the component palette; `TFIBDataSet` is not.

| | |
|---|---|
| Unit | `pFIBDataSet` |
| Inherits from | `TFIBDataSet` |

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

This page lists what `TpFIBDataSet` adds. For the members inherited from `TFIBDataSet` (`Params`, `Locate`, `FetchAll`, `CachedUpdates`, `DetailConditions`, and so on) see [TFIBDataSet](TFIBDataSet.md).

Guides: [Datasets and caching](../guide/datasets-and-caching.md), [Transactions](../guide/transactions.md), [Timeouts](../guide/timeouts.md).

## Published properties

Available in the Object Inspector. `TpFIBDataSet` publishes the same properties as `TFIBDataSet` (`Options`, `PrepareOptions`, `AutoUpdateOptions`, `DetailConditions`, `SelectSQL`, and the others listed there) and the properties below. It also publishes `Filtered` and `OnFilterRecord`.

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `About` | `string` | | Shows the library version. Not stored; assigning has no effect. |
| `Container` | `TDataSetsContainer` | | Container (unit `DSContainer`) that receives the dataset events. See [Events](#events). |
| `DataSet_ID` | `Integer` | `0` | Number of the row in the repository table `FIB$DATASETS_INFO` that holds the SQL texts and update settings of this dataset. Can be changed only while the dataset is closed. A non-zero value turns `psApplyRepositary` on. See [DataSet_ID and the repository](#dataset_id-and-the-repository). |
| `DefaultFormats` | `TFormatFields` | see [Default formats](#default-formats) | Display and edit formats applied to fields when `poAutoFormatFields` is set. |
| `Description` | `string` | | Free text. Stored in the `DESCRIPTION` column of the repository row, and replaced from it when the row is loaded. |
| `StatementTimeout` | `Cardinal` | `0` | Published here; declared in `TFIBCustomDataSet`. See [TFIBDataSet](TFIBDataSet.md#statement-timeout). |

`DeleteSQL`, `InsertSQL`, `RefreshSQL`, `SelectSQL`, and `UpdateSQL` are declared again with the same meaning as in `TFIBDataSet`.

### Default formats

`TFormatFields` has five string properties. The values below are the defaults for a dataset created at run time or loaded from a form; the design-time defaults of a new component and the run-time defaults selected by `FF_UseRuntimeDefaults` come from typed constants in `pFIBProps` that have the same values.

| Name | Default | Applied to |
|------|---------|------------|
| `DateTimeDisplayFormat` | `dd.mm.yyyy hh:nn` | `ftDateTime` fields: `DisplayFormat` |
| `DisplayFormatDate` | `dd.mm.yyyy` | `ftDate` fields: `DisplayFormat` |
| `DisplayFormatTime` | `hh:nn` | `ftTime` fields: `DisplayFormat` |
| `NumericDisplayFormat` | `#,##0.` | Scaled numeric fields: `DisplayFormat` |
| `NumericEditFormat` | `0.` | Scaled numeric fields: `EditFormat` |

The formats are used when the dataset opens, only for a field whose own `DisplayFormat` (or `EditFormat`) is empty. The numeric formats apply to `ftSmallint`, `ftInteger`, and `ftFloat` fields with a negative scale, and to `ftBCD` fields that are not currency and have `Size` above `0`. A format that ends with `.` gets as many zeros as the scale (`#,##0.` becomes `#,##0.00` for scale 2). A format whose `.` is followed by one character repeats that character as many times as the scale. Any other format is used as it is.

## Options

`Options`, `PrepareOptions`, `DetailConditions`, and `AutoUpdateOptions` are properties of `TFIBDataSet`; their values are defined in unit `pFIBProps`.

Each flag of `Options`, `PrepareOptions`, and `DetailConditions` is stored in the form file as its own boolean entry. The entry is written only when the value differs from the standard default (or from the ancestor form, in an inherited form). The *DFM entry* column gives the name of the entry; it differs from the enumeration name for some flags.

### Dataset options

`Options` is a set of `TpFIBDsOption`. The standard default is `[poTrimCharFields, poStartTransaction, poAutoFormatFields, poRefreshAfterPost]`, see [Defaults](#defaults).

| Value | DFM entry | Effect |
|-------|-----------|--------|
| `poAutoFormatFields` | `oAutoFormatFields` | Apply `DefaultFormats` to date, time, and scaled numeric fields when the dataset opens. |
| `poCacheCalcFields` | `oCacheCalcFields` | Keep the values of calculated fields with each row in the record cache. |
| `poDontCloseAfterEndTransaction` | `oDontAutoClose` | When `Transaction` commits or rolls back, or the database disconnects, fetch all rows and close the cursor instead of closing the dataset. `CachedUpdates` has the same effect. Reading a BLOB of the dataset starts the transaction and opens the connection if they are closed. |
| `poFetchAll` | `oFetchAll` | Fetch all rows after the dataset opens. |
| `poFreeHandlesAfterClose` | `oFreeHandlesAfterClose` | Release the prepared statements on the server (`UnPrepare`) after the dataset closes. |
| `poKeepSorting` | `oKeepSorting` | When a row is posted and the dataset is sorted, move the row to the place its sort fields give. Without it, posting a row clears the sort information, and `Sorted` becomes `False`. With `cmkLimitedBufferSize` the order is always kept. |
| `poNoForceIsNull` | `oNoForceIsNull` | Sets `qoNoForceIsNull` on `QSelect`, `QInsert`, `QUpdate`, and `QDelete`: a null parameter is not rewritten to `IS NULL`. `QRefresh` is not changed. |
| `poPersistentSorting` | `oPersistentSorting` | When the dataset opens again after a client sort (`DoSort`), sort the new rows in the same way. When the `SelectSQL` text changed, the sort is kept only if its fields are still in the dataset. Without the option, the sort information is dropped when the text changed. |
| `poProtectedEdit` | `oProtectedEdit` | Pessimistic locking. Before the first edit of a row, lock it on the server (see [LockRecord](#locking)) and read it again with `RefreshSQL`. When `RefreshSQL` or `UpdateSQL` is empty and `AutoReWriteSqls` or `UpdateOnlyModifiedFields` is set, the statement is generated first. Without `CachedUpdates` and `AutoCommit`, a posted row keeps the modified status until the update transaction commits, so editing it again does not lock it again. |
| `poRefreshAfterDelete` | `oRefreshAfterDelete` | After the delete statement runs, read the row again with `RefreshSQL`. The row stays in the cache when `RefreshSQL` still returns it (a logical delete); otherwise it is removed. Without the option, the row is always removed. |
| `poRefreshAfterPost` | `oRefreshAfterPost` | After an insert or update is sent to the server, read the row again with `RefreshSQL`, so values set by triggers and defaults appear. With `cmkStandard` it needs a non-empty `RefreshSQL`. With `cmkLimitedBufferSize` the option starts the refresh of the cache part (`DoInternalRefresh`) after each post. |
| `poRefreshDeletedRecord` | `oRefreshDeletedRecord` | When a refresh with `RefreshSQL` finds no row, remove the row from the cache. Only with `cmkStandard`. |
| `poStartTransaction` | `oStartTransaction` | Start `Transaction` and `UpdateTransaction` when they are not active and a statement needs them. Also sets `qoStartTransaction` on `QSelect`, `QInsert`, `QUpdate`, and `QDelete`. |
| `poTrimCharFields` | `oTrimCharFields` | Remove trailing blanks from `CHAR` values when a field is read. |
| `poUseSelectForLock` | `oUseSelectForLock` | `LockRecord` locks with `SELECT ... FOR UPDATE WITH LOCK` instead of a no-op `UPDATE`. |
| `poVisibleRecno` | `oVisibleRecno` | With `Filtered`, `RecNo` and `RecordCount` count only the rows that pass the filter, and `IsSequenced` follows the visible rows. Without it they count all cached rows. |

### Prepare options

`PrepareOptions` is a set of `TpPrepareOption`. It tells the dataset what to read from the metadata. The standard default is `[pfImportDefaultValues, psGetOrderInfo, psUseBooleanField, psSetEmptyStrToNull]`.

Changing `psUseBooleanField`, `psSQLINT64ToBCD`, or `psUseLargeIntField` needs a closed dataset; when the dataset is already prepared, its field definitions are read again.

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
   - for date and time fields, `NOW`, `CURRENT_TIME`, `CURRENT_TIMESTAMP`, `LOCALTIME`, and `LOCALTIMESTAMP` give the client time, `TODAY` and `CURRENT_DATE` the client date, and `TOMORROW` and `YESTERDAY` the next and previous date; when the database is a `TpFIBDatabase`, its `DifferenceTime` is subtracted first;
   - for string fields, `USER` and `CURRENT_USER` give the user name of the connection, `ROLE` and `CURRENT_ROLE` its role, and a quoted text gives the text without quotes;
   - any other expression is assigned as text.

A key field that is filled from a generator (`WhenGetGenID`) is skipped.

### Detail conditions

`DetailConditions` is a set of `TDetailCondition`: `dcForceMasterRefresh`, `dcForceOpen`, `dcIgnoreMasterClose`, `dcWaitEndMasterScroll`. The standard default is `[]`. The effect of each value is in [TFIBDataSet](TFIBDataSet.md#master-detail). The *DFM entry* names are `dcForceMasterRefresh`, `dcForceOpen`, `dcIgnoreMasterClose`, and `WaitEndMasterScroll`.

### Defaults

The standard defaults are the constants `StatDefDataSetOptions` and `StatDefPrepareOptions` in `pFIBProps`. The writable typed constants `DefaultOptions`, `DefaultPrepareOptions`, and `DefaultDetailConditions` start with the same values.

| Dataset created | `Options`, `PrepareOptions` | `DetailConditions` |
|-----------------|-----------------------------|--------------------|
| At design time, dropped on a form | `DefaultOptions`, `DefaultPrepareOptions` | `DefaultDetailConditions` |
| At run time, or loaded from a form file | `StatDefDataSetOptions`, `StatDefPrepareOptions` | `[]` |

`DefaultOptions`, `DefaultPrepareOptions`, and `DefaultDetailConditions` are changed by the design-time preferences, so they set the starting values of new components in the IDE only. Changing them in an application has no effect on datasets created at run time.

Other writable typed constants in `pFIBProps` that affect `TpFIBDataSet`:

| Constant | Default | Used for |
|----------|---------|----------|
| `DefPrefixGenName`, `DefSufixGenName` | `GEN_`, `_ID` | Generator name built when `UpdateTableName` is set, see [AutoUpdateOptions](#autoupdateoptions). |
| `FF_UseRuntimeDefaults` | `False` | When `True`, `DefaultFormats` start with `RDefDateFormat`, `RDefTimeFormat`, `RDefDisplayFormatNum`, and `RDefEditFormatNum` instead of the other defaults. |
| `RDefDateFormat`, `RDefTimeFormat`, `RDefDisplayFormatNum`, `RDefEditFormatNum` | `dd.mm.yyyy`, `hh:nn`, `#,##0.`, `0.` | See above. |
| `dDefDateFormat`, `dDefTimeFormat`, `dDefDateTimeFormat`, `dDefDisplayFormatNum`, `dDefEditFormatNum` | `dd.mm.yyyy`, `hh:nn`, `dd.mm.yyyy hh:nn`, `#,##0.`, `0.` | `DefaultFormats` of a component dropped at design time. |

### AutoUpdateOptions

`AutoUpdateOptions` is a `TAutoUpdateOptions` object (unit `pFIBProps`). It controls generated statements, key generators, and the link between parameters and fields. All members in the first table are published.

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
| `UpdateOnlyModifiedFields` | `Boolean` | `False` | Generate `INSERT` and `UPDATE` for each post from the changed fields only: unchanged fields in `UPDATE`, null fields in `INSERT`. The value is `True` only if `AutoReWriteSqls` and `CanChangeSQLs` are `True` when it is assigned, so assign those first. |
| `UpdateTableName` | `string` | | Table, with an optional alias, that generated statements change. |
| `UseExecuteBlock` | `Boolean` | `False` | `ApplyUpdates` collects the cached changes in `EXECUTE BLOCK` batches and sends them with `ExecSQLImmediate`. The statements are generated from `UpdateTableName` and `KeyFields` with the values as literals; `InsertSQL`, `UpdateSQL`, `DeleteSQL`, and update objects are not used. A batch holds up to 255 statements and less than 64 KB of text. Intended for `CachedUpdates` (comment in the code). See [Applying cached updates](#applying-cached-updates). |
| `UseReturningFields` | `TSetReturningFields` | `[]` | Add a `RETURNING` clause to generated `INSERT` and `UPDATE`: `rfAll` returns every written column, `rfKeyFields` the key columns, `rfBlobFields` the written BLOB columns. After the statement runs, the row is read back when its statement type is select, execute procedure, or select for update. Applies to statements made by `GenerateSQLs`; with `UpdateOnlyModifiedFields` the statements made for each post have no `RETURNING`. |
| `UseRowsClause` | `Boolean` | `False` | Append `ROWS 1` on a new line to generated `INSERT` and `UPDATE` statements. It is also appended after the text `No Action`. |
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

Generation needs `UpdateTableName`, a table known to the metadata, and key fields that exist in the dataset and belong to the table. A key field is left out of the `WHERE` clause when its column is a BLOB or an array. Statements use parameters named `NEW_<field>` for new values and `OLD_<field>` for the values the row had when it was read, written as `?NEW_NAME` and `?OLD_ID`. When no field qualifies, the statement text is `No Action` and the dataset sends nothing for it.

- The `INSERT` and `UPDATE` statements list the data fields whose column belongs to `UpdateTableName`. Computed columns are skipped unless `psCanEditComputedFields` is set.
- `DELETE` removes the row with the key condition.
- `RefreshSQL` is `SelectSQL` with the key condition added and without `ORDER BY`.

With `AutoReWriteSqls` and without `UpdateOnlyModifiedFields`, `GenerateSQLs` runs when the dataset opens. With `UpdateOnlyModifiedFields`, `RefreshSQL` and `DeleteSQL` are generated when the dataset opens, and `InsertSQL` and `UpdateSQL` are generated again before each post (`AutoGenerateSQLText`).

#### DataSet_ID and the repository

`FIB$DATASETS_INFO` is a table in the database that stores dataset settings by number. A dataset with `DataSet_ID` set and `psApplyRepositary` on loads its row the first time it is prepared and each time `DataSet_ID` changed. The load replaces `SelectSQL`, `InsertSQL`, `UpdateSQL`, `DeleteSQL`, and `RefreshSQL` when the stored text is not empty. It always replaces `Description`, `Conditions`, and these `AutoUpdateOptions` members: `KeyFields`, `GeneratorName`, `UpdateOnlyModifiedFields` (effective only if `AutoReWriteSqls` and `CanChangeSQLs` are already `True`), and `UpdateTableName`. It also sets `WhenGetGenID` to `wgNever` when the key field or the generator is not stored, and to `wgBeforePost` when both are stored and `WhenGetGenID` was `wgNever`.

The row is read through the database component: `UseRepositories` of the database must contain `urDataSetInfo`, and the table must exist; otherwise the load raises an exception. When the table has no row for `DataSet_ID`, no error is raised and the code goes on with empty stored values. The settings are cached per database name and `DataSet_ID`. Field settings come from `FIB$FIELDS_INFO` when `urFieldsInfo` is in `UseRepositories`: `DisplayLabel`, `DisplayWidth`, `Visible`, and the display and edit formats are applied to the fields (see `OnApplyFieldRepository`). The column `TRIGGERED` of that table is what `pfSetRequiredFields` reads.

## Update objects

An update object (`TpFIBUpdateObject`) is a query that runs together with the dataset's own statement for one kind of change. It is linked to the dataset through its `DataSet` property, which calls `AddUpdateObject`. `TpFIBDataSet` has no property that lists them. The update object has `KindUpdate` (`ukModify`, `ukInsert`, or `ukDelete`), `ExecuteOrder` (`oeBeforeDefault` or `oeAfterDefault`), `OrderInList`, and `Active`; see [TpFIBUpdateObject](TpFIBUpdateObject.md).

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

With `CachedUpdates`, changes stay in the record cache. `ApplyUpdates` sends them to the server. `UpdateRecordTypes`, `CancelUpdates`, `RevertRecord`, and `CachedUpdateStatus` are in [TFIBDataSet](TFIBDataSet.md#editing-and-cached-updates).

```delphi
DataSet.CachedUpdates := True;
DataSet.Open;
DataSet.Edit;
DataSet.FieldByName('NAME').AsString := 'New name';
DataSet.Post;
DataSet.ApplyUpdates;
Transaction.Commit;
```

In both samples `DataSet` is a `TpFIBDataSet`, `Database` a `TpFIBDatabase`, and `Transaction` a `TpFIBTransaction`. The second sample assumes that `UpdateSQL` is set or generated (see [AutoUpdateOptions](#autoupdateoptions)) and that `Transaction` is also the update transaction of the dataset.

`ApplyUpdates` posts a pending edit, starts `UpdateTransaction` when `poStartTransaction` is set, and visits the rows from the first. For each row with a cached status of modified, inserted, or deleted it does the following:

1. When `OnUpdateRecord` is assigned, call it with `UpdateAction` set to `uaFail`; call it again while the handler sets `uaRetry`. Without a handler the action is `uaApply`.
2. When the action is `uaApply` or `uaRetry`, run the statements for the row, but only when `CanEdit`, `CanInsert`, or `CanDelete` allows it. Without `UseExecuteBlock` these are the update objects and the dataset statement, see [Update objects](#update-objects). With `UseExecuteBlock` the row is added to an `EXECUTE BLOCK` batch instead, see below. Then the action becomes `uaApplied`, and `AfterUpdateRecord` is called with `Resume` set to `True`. When the handler sets `Resume` to `False`, `ApplyUpdates` ends with a silent `EAbort`; the remaining rows are not sent, and a batch that was not sent yet is dropped.
3. When `EFIBError` is raised in step 1 or 2, call `OnUpdateError` with `UpdateAction` set to `uaFail`. Other exceptions are not passed to the event.

At the end of a normal run, `UpdatesPending` is `True` only when `OnUpdateError` chose `uaSkip` for some row. When it is `False` and `AutoCommit` is set, the update transaction is committed. The client fields are recalculated. When `ApplyUpdates` ends with an exception or `EAbort`, `UpdatesPending` stays `True`.

Without `UseExecuteBlock`, the insert and update statement of a row ends with an `AutoCommit` commit of the update transaction (`CommitRetaining` when it is the same as `Transaction`, or when its `TimeoutAction` is `TACommitRetaining`). This happens after each inserted or modified row, even with `CachedUpdates`; a delete is committed this way only without `CachedUpdates`. Rows that were committed stay committed when a later row fails or is skipped.

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

## Run-time properties

| Name | Type | Description |
|------|------|-------------|
| `AllRecordCount` | `Integer` | Row count from the server count query of `psAskRecordCount`; `0` when the option is off. Inserted rows increase it. |
| `HasUncommitedChanges` | `Boolean` | `True` after the dataset sent a change to the server, until the update transaction ends or the `SelectSQL` text changes. |
| `HaveRollbackedChanges` | `Boolean` | `True` after the update transaction was rolled back with uncommitted changes of this dataset. Cleared when the `SelectSQL` text changes and when the dataset closes. |
| `VisibleRecno` | `Integer` | `RecNo` counted among the rows that pass the filter. Used as `RecNo` when `poVisibleRecno` is set. |

## Methods

### Opening and parameters

| Name | Description |
|------|-------------|
| `FindParam(ParamName)` | Parameter of `SelectSQL` by name, or `nil`. Starts the transaction first. |
| `OpenWP(ParamValues)` / `OpenWP(ParamNames, ParamValues)` | Set the parameters, then `Open`. The first form sets parameters by position; it sets nothing when the array is empty. The second takes the names as a string. |
| `OpenWPS(ParamSources)` | Take parameter values from `ISQLObject` sources, then `Open`. |
| `ParamByName(ParamName)` | Parameter of `SelectSQL` by name. Raises when missing. |
| `ParamCount` | Number of parameters. |
| `ParamNameCount(aParamName)` | Number of parameters with this name. |
| `ParseParamToFieldsLinks(Dest)` | Add `FieldName=ParamName` lines to `Dest`: for each parameter, the field name found before the operator that precedes the parameter in a `WHERE` clause of `SelectSQL`. With a table alias, the name of the matching dataset field is used. |
| `Prepare` | Inherited behavior, and when `psApplyRepositary` is set and `DataSet_ID` is not `0`, load the repository row first. At design time it also prepares the update, insert, and delete statements. Raises when `SelectSQL` is empty. |
| `RecordCountFromSrv` | Run the count query and return its result. `0` when the transaction is not active. |
| `ReOpenWP(...)`, `ReOpenWPS(...)` | `Close`, then `OpenWP` or `OpenWPS` with the same arguments. |

### Generated SQL

| Name | Description |
|------|-------------|
| `AllKeyFields(TableName)` | Names of all non-BLOB dataset fields that belong to the table, separated by `;`. |
| `AutoGenerateSQLText(ForState)` | Generate `UpdateSQL` (`dsEdit`) or `InsertSQL` (`dsInsert`) from the changed fields, when `UpdateOnlyModifiedFields`, `KeyFields`, and `UpdateTableName` are set; then update the BLOB update object. Called before a post. |
| `CanGenerateSQLs` | `True` when `UpdateTableName` is not empty. |
| `GenerateSQLs` | Generate `DeleteSQL`, `UpdateSQL`, `InsertSQL`, and `RefreshSQL` from `UpdateTableName` and `KeyFields`. Fills `KeyFields` first when empty. Does nothing when no key field is found. See `CanChangeSQLs`. |
| `GenerateSQLText(TableName, KeyFieldNames, SK, IncludeFields, ReturningFields)` | Statement text for one table and kind (`TpSQLKind`, see [TFIBDataSet](TFIBDataSet.md#types)); the code handles `skModify`, `skInsert`, `skDelete`, and `skRefresh`. `IncludeFields` is `ifsAllFields` (default), `ifsNoBlob`, or `ifsOnlyBlob`. Returns an empty string when the table is not known or `KeyFieldNames` has no field, and `No Action` when no field qualifies. Raises when no key field of the table remains. |
| `GenerateSQLTextNoParams(TableName, KeyFieldNames, SK)` | The same for `skModify`, `skInsert`, `skDelete`, and `skRefresh`, with the current and old values written as literals. Returns an empty string when no field qualifies. |
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

`CanEdit`, `CanInsert`, and `CanDelete` are `True` when the `TFIBDataSet` rule allows the change, or an active update object of that kind exists, or generation of statements is active (`UpdateOnlyModifiedFields`, `AutoReWriteSqls`, `CanChangeSQLs`, `KeyFields`, and `UpdateTableName` all set), or `CachedUpdates` is on with an `OnUpdateRecord` handler; and the kind is in `AllowedUpdateKinds`. `Insert` and `Edit` are also allowed while the dataset refreshes its cache.

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

### Batch

| Name | Description |
|------|-------------|
| `BatchAllRecordsToQuery(ToQuery)` | Run `BatchRecordToQuery` for every row from the first. The position is restored. |
| `BatchRecordToQuery(ToQuery)` | Take the parameters of `ToQuery` from the current row (fields of the same name), then run it. |

### Save and load

| Name | Description |
|------|-------------|
| `LoadFromFile(FileName)` / `LoadFromFile(FileName, AddInfo)` | `LoadFromStream` from a file, then read the sort information from `SelectSQL`. |
| `LoadFromStream(Stream, SeekBegin)` / `LoadFromStream(Stream, SeekBegin, AddInfo)` | Read the field definitions and rows written by `SaveToStream` and open the dataset if it is closed. Moves to the first row. `AddInfo` returns the string saved with the data. Does nothing at design time. Raises when the stream signature or version (7 or later) is wrong, or the stream does not fit the fields. |
| `SaveToFile(FileName, AddInfo)` | `SaveToStream` into a new file. |
| `SaveToStream(Stream, SeekBegin, AddInfo)` | Fetch all rows, then write the signature `FIB$DATASET`, the field definitions, the cache, and `AddInfo`. With `SeekBegin`, go to the start of the stream first. |

## Events

`OnUpdateRecord`, `OnUpdateError`, and `AfterUpdateRecord` are published by `TFIBDataSet` and are described in [Applying cached updates](#applying-cached-updates). The events of `TDataSet` and `TFIBDataSet` are not repeated.

| Name | Description |
|------|-------------|
| `OnApplyDefaultValue` | A new row gets the value of a field from its `DefaultExpression`. Set `Applied` to `True` when the handler supplies the value. See [New row defaults](#new-row-defaults). |
| `OnApplyFieldRepository` | After the settings of `FIB$FIELDS_INFO` are applied to a field (`psApplyRepositary`). `FieldInfo` is the `TpFIBFieldInfo` of the column. |
| `OnAskRecordCount` | `psAskRecordCount` needs the count query. Set `SQLText` to a query that returns the number of rows; leave it empty for the default. Its parameters are filled from the parameters of `SelectSQL` by name. |
| `OnDeleteError`, `OnPostError` | Same as the `TDataSet` events. The handlers of the global container and the dataset's container run before them. |
| `OnFilterRecord` | `TDataSet` event, published. Runs after the text `Filter` accepts the row, only when `Filtered` is `True`. |
| `OnLockError` | `LockRecord` failed with `RaiseErr`. The handler can change `ErrorMessage` and set `Action` to `daFail` (raise, the default), `daAbort`, or `daRetry`. |
| `OnLockSQLText` | `LockRecord` asks for the lock statement. Set `SQLText` to replace the generated text. Parameters are filled from the current row by field name; the `OLD_` prefix gives the old value. |

The events `BeforeOpen`, `AfterOpen`, `BeforeClose`, `AfterClose`, `BeforeInsert`, `AfterInsert`, `BeforeEdit`, `AfterEdit`, `BeforePost`, `AfterPost`, `BeforeCancel`, `AfterCancel`, `BeforeDelete`, `AfterDelete`, `BeforeScroll`, `AfterScroll`, `OnNewRecord`, `OnCalcFields`, `BeforeRefresh`, and `AfterRefresh` are also reported to the containers. First the global container (the one with `IsGlobalContainer`, one per thread) receives them in `OnDataSetEvent`, then the container in `Container`. `OnPostError` and `OnDeleteError` go to `OnDataSetError` of the containers, `OnApplyDefaultValue` and `OnApplyFieldRepository` to the events of the same name, and sorting asks `OnCompareFieldValues` of the containers first.

Protected, for descendants:

| Name | Description |
|------|-------------|
| `AddedFilterRecord(DataSet, Accept)` | Virtual and empty. Called last when a row passes `Filter` and `OnFilterRecord`, only when `Filtered` is `True`; set `Accept` to `False` to hide the row. |
| `ClearModifFlags(Kind, NeedRefreshFields)` | Set the cached status of all rows. `Kind` `0` is `CommitUpdToCach`; `1` makes every row that is not unmodified or `cusDeletedApplied` unmodified (used by `poProtectedEdit`). |
| `InternalDeleteRecord(Qry, Buff)` | Override. Runs the delete update objects and `DeleteSQL`, then applies `poRefreshAfterDelete` and `AutoCommit`. Returns at once when `DeleteSQL` is `No Action`. |
| `InternalPostRecord(Qry, Buff)` | Override. Runs the update objects and the insert or update statement, applies `poRefreshAfterPost`, and commits with `AutoCommit` (also with `CachedUpdates`). |
| `DoOnApplyDefaultValue(Field, Applied)` | Dynamic. Raises the containers' events and `OnApplyDefaultValue`. |
| `UpdateFieldsProps` | Virtual. Applies `DefaultFormats`, `PrepareOptions`, and repository settings to the fields. Runs when the dataset opens. |

## Types

| Type | Values |
|------|--------|
| `TAutoUpdateOptions` | Class, see [AutoUpdateOptions](#autoupdateoptions) |
| `TCachRefreshKind` | `frkEdit`, `frkInsert` |
| `TDetailCondition`, `TDetailConditions` | See [Detail conditions](#detail-conditions); set of `TDetailCondition` |
| `TFIBOrderExecUO` | `oeBeforeDefault`, `oeAfterDefault` (unit `pFIBQuery`) |
| `TFormatFields` | Class, see [Default formats](#default-formats) |
| `TIncludeFieldsToSQL` | `ifsAllFields`, `ifsNoBlob`, `ifsOnlyBlob` |
| `TLockErrorEvent` | `procedure(DataSet: TDataSet; LockError: TLockStatus; var ErrorMessage: string; var Action: TDataAction) of object` |
| `TLockStatus` | `lsSuccess`, `lsDeadLock`, `lsNotExist`, `lsMultiply`, `lsUnknownError` |
| `TOnApplyDefaultValue` | `procedure(DataSet: TDataSet; Field: TField; var Applied: Boolean) of object` (unit `DSContainer`) |
| `TOnApplyFieldRepository` | `procedure(DataSet: TDataSet; Field: TField; FieldInfo: TpFIBFieldInfo) of object` (unit `DSContainer`) |
| `TOnGetSQLTextProc` | `procedure(DataSet: TFIBDataSet; var SQLText: string) of object` |
| `TpFIBDsOption`, `TpFIBDsOptions` | See [Dataset options](#dataset-options); set of `TpFIBDsOption` |
| `TpPrepareOption`, `TpPrepareOptions` | See [Prepare options](#prepare-options); set of `TpPrepareOption` |
| `TReturningFields`, `TSetReturningFields` | `rfAll`, `rfKeyFields`, `rfBlobFields`; set of `TReturningFields` |
| `TWhenGetGenID` | `wgNever`, `wgOnNewRecord`, `wgBeforePost` |

`TLockStatus` values: `lsSuccess` for one row locked, `lsNotExist` for no row, `lsMultiply` for more than one row, `lsDeadLock` for a deadlock or lock conflict, and `lsUnknownError` for any other error.

## See also

- [TFIBDataSet](TFIBDataSet.md), [TFIBQuery](TFIBQuery.md), [TFIBTransaction](TFIBTransaction.md)
- [TpFIBUpdateObject](TpFIBUpdateObject.md), [TpFIBQuery](TpFIBQuery.md)
- [TpFIBClientDataSet](TpFIBClientDataSet.md), which uses the provider support of this class
- [Datasets and caching](../guide/datasets-and-caching.md)
- [Timeouts](../guide/timeouts.md)
