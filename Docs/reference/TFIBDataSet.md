# TFIBDataSet

A `TDataSet` for Firebird and InterBase that reads rows through a `TFIBQuery` and keeps them in a record cache, so that scrolling in both directions, sorting, and locating need no further round trip. Use it for data-aware controls. For commands and for reading rows in code without a `TDataSet`, use [TFIBQuery](TFIBQuery.md).

| | |
|---|---|
| Unit | `FIBDataSet` |
| Inherits from | `TFIBCustomDataSet` (the implementation lives there), then `TDataSet` |
| Descendants | `TpFIBDataSet`, which adds generated SQL, update objects, `ApplyUpdates`, and more |

```delphi
DataSet.Database := Database;
DataSet.Transaction := Transaction;
DataSet.SelectSQL.Text := 'SELECT ID, NAME FROM CUSTOMER WHERE ID > :MinID ORDER BY NAME';
DataSet.Params.ByName['MinID'].AsInteger := 100;
DataSet.Open;
if DataSet.Locate('NAME', 'Smith', [loCaseInsensitive, loPartialKey]) then
  ShowMessage(DataSet.FBN('ID').AsString);
```

In the example, `DataSet` is a `TFIBDataSet` (or `TpFIBDataSet`), and `Database` and `Transaction` are the `TFIBDatabase` and `TFIBTransaction` it uses.

This page lists what `TFIBDataSet` and `TFIBCustomDataSet` add to `TDataSet`. Members inherited from `TDataSet` (`Open`, `Close`, `Fields`, `Bookmark`, `Filter`, and so on) are not repeated.

Guides: [Datasets and caching](../guide/datasets-and-caching.md), [Queries and parameters](../guide/queries-and-parameters.md), [Transactions](../guide/transactions.md), [Timeouts](../guide/timeouts.md), [BLOBs and arrays](../guide/blobs-and-arrays.md).

## Published properties

Available in the Object Inspector. Besides the properties below, `TFIBDataSet` publishes the standard `TDataSet` ones (`Active`, `AutoCalcFields`, `Filter`, `FilterOptions`) and the `Before...` / `After...` events.

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

In `TFIBDataSet`, `Insert`, `Edit`, and `Delete` are allowed only when `InsertSQL`, `UpdateSQL`, and `DeleteSQL` respectively are not empty; with `CachedUpdates`, a row inserted in the cache can also be edited when `UpdateSQL` is empty. `TpFIBDataSet` can generate the statements. Changing the text of `SelectSQL` at run time raises an error while the dataset is open; at design time it closes the dataset.

### Behavior

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `AllowedUpdateKinds` | `TUpdateKinds` | `[ukModify, ukInsert, ukDelete]` | Kinds of change the dataset allows. At run time, when preparing the insert, update, or delete statement fails with a permission error and the global variable `FIBHideGrantError` (unit `FIBDatabase`, default `False`) is `True`, that kind is removed. Nothing is removed at design time, and a failed `RefreshSQL` removes nothing. |
| `AutoUpdateOptions` | `TAutoUpdateOptions` | | Settings for generated SQL, generators, and key fields. See [TpFIBDataSet](TpFIBDataSet.md#autoupdateoptions). |
| `CachedUpdates` | `Boolean` | `False` | Keep changes in the cache until they are applied. Turning it on needs a closed dataset and is refused with `cmkLimitedBufferSize`. Turning it off on an open dataset is allowed and calls `CancelUpdates`. |
| `CacheModelOptions` | `TCacheModelOptions` | | Record cache settings, see [Cache model](#cache-model). |
| `CSMonitorSupport` | `TCSMonitorSupport` | | Adds monitoring text to the statements. Only when compiled with `CSMonitor`. |
| `DataSource` | `TDataSource` | | Master dataset source. Parameters of `SelectSQL` named like master fields are filled from it. A circular reference raises an error. |
| `DetailConditions` | `TDetailConditions` | `[]` | How a detail dataset follows its master, see [Master-detail](#master-detail) and [TpFIBDataSet](TpFIBDataSet.md#detail-conditions). Saved in the DFM as individual boolean entries. |
| `FieldOriginRule` | `TFieldOriginRule` | `forTableAndFieldName` | How `Field.Origin` is filled when the dataset opens. `forNoRule` leaves it empty. |
| `Options` | `TpFIBDsOptions` | `[poTrimCharFields, poStartTransaction, poAutoFormatFields, poRefreshAfterPost]` | Behavior flags, see [TpFIBDataSet](TpFIBDataSet.md#options). The default is `DefaultOptions` for a component dropped at design time and `StatDefDataSetOptions` at run time (unit `pFIBProps`). Saved in the DFM as individual boolean entries. |
| `PrepareOptions` | `TpPrepareOptions` | `[pfImportDefaultValues, psGetOrderInfo, psUseBooleanField, psSetEmptyStrToNull]` | What the dataset reads from the metadata when it prepares, such as required fields and `BOOLEAN` and GUID mapping. The initial value is `DefaultPrepareOptions` for a component dropped at design time and `StatDefPrepareOptions` otherwise. See [TpFIBDataSet](TpFIBDataSet.md#prepare-options). Saved in the DFM as individual boolean entries. |
| `SQLScreenCursor` | `TCursor` | `crDefault` | Screen cursor shown during long operations: prepare, open, fetch, `FetchAll`, `Clone`, and the refresh in `cmkLimitedBufferSize`. From Delphi XE2 the change goes through `Database.DoChangeScreenCursor` and does nothing when that is not assigned. Not available when compiled with `NO_GUI`. |
| `UniDirectional` | `Boolean` | `False` | Read forward only. The cache keeps a window of `BufferChunks` records instead of all rows. Can be changed only while the dataset is closed. `ReopenLocate` and `FullRefresh` (standard cache) raise. |
| `UpdateRecordTypes` | `TFIBUpdateRecordTypes` | `[cusUnmodified, cusModified, cusInserted]` | Rows with these cached update statuses are visible. Setting it moves to the first row when the dataset is active. Ignored with `cmkLimitedBufferSize`. |

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

## Types

| Type | Values |
|------|--------|
| `TCacheModelKind` | `cmkStandard`, `cmkLimitedBufferSize` |
| `TCachedUpdateStatus` | `cusUnmodified`, `cusModified`, `cusInserted`, `cusDeleted`, `cusUninserted`, `cusDeletedApplied` |
| `TFIBAfterUpdateRecordEvent` | `procedure(DataSet: TDataSet; UpdateKind: TUpdateKind; var Resume: Boolean) of object` |
| `TCompareFieldValues` | `function(Field: TField; const S1, S2: Variant): Integer of object` |
| `TEndTrEvent` | `procedure(EndingTR: TFIBTransaction; Action: TTransactionAction; Force: Boolean) of object` (unit `FIBDatabase`) |
| `TFieldOriginRule` | `forNoRule`, `forTableAndFieldName`, `forClientFieldName`, `forTableAliasAndFieldName` |
| `TFIBUpdateAction` | `uaFail`, `uaAbort`, `uaSkip`, `uaRetry`, `uaApply`, `uaApplied` |
| `TFIBUpdateErrorEvent` | `procedure(DataSet: TDataSet; E: EFIBError; UpdateKind: TUpdateKind; var UpdateAction: TFIBUpdateAction) of object` |
| `TFIBUpdateRecordEvent` | `procedure(DataSet: TDataSet; UpdateKind: TUpdateKind; var UpdateAction: TFIBUpdateAction) of object` |
| `TFIBUpdateRecordTypes` | Set of `TCachedUpdateStatus` |
| `TOnBlobFieldProcessing` | `procedure(Field: TBlobField; BlobSize: Integer; Progress: Integer; var Stop: Boolean) of object` |
| `TOnFetchRecord` | `procedure(FromQuery: TFIBQuery; RecordNumber: Integer; var StopFetching: Boolean) of object` |
| `TOnFillClientBlob` | `procedure(DataSet: TFIBCustomDataSet; Field: TFIBBlobField; Stream: TFIBBlobStream) of object` |
| `TpSQLKind` | `skModify`, `skInsert`, `skDelete`, `skRefresh`, `skMerge` |
| `TSortFieldInfo` | Record: `FieldName`, `InDataSetIndex`, `InOrderIndex`, `Asc`, `NullsFirst` |
| `TTransactionKind` | `tkReadTransaction`, `tkUpdateTransaction` |
| `TUpdateKinds` | Set of `TUpdateKind` (`ukModify`, `ukInsert`, `ukDelete`) |

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
| `StatementTimeout` | `Cardinal` | Milliseconds, *Firebird 4+*. `0` uses `Database.Session.StatementTimeout`; `FIBNoStatementTimeout` disables the limit. Also assigned to the `TFIBQuery` components the dataset owns. A non-zero value raises `EFIBClientError` when the server or client library cannot apply it. Published in `TpFIBDataSet`. See [Timeouts](../guide/timeouts.md). |

### State

| Name | Type | Description |
|------|------|-------------|
| `AllFetched` | `Boolean` | `True` when the query has no more rows to fetch. |
| `BufferChunks` | `Integer` | Same as `CacheModelOptions.BufferChunks`. |
| `CachedActive` | `Boolean` | `True` while the dataset is open after `CacheOpen`. |
| `CacheSize` | `Integer` | Size of the record cache in bytes (allocated blocks times block size). |
| `CountUpdatesPending` | `Integer` | Number of rows with pending cached updates. |
| `DBHandle`, `TRHandle` | pointers | Native database and transaction handles. |
| `DefaultFields` | `Boolean` | `True` when the field list is generated and not defined in the form. Unlike the `TDataSet` flag before Delphi XE6, it is correct also while the dataset is inactive. |
| `Prepared` | `Boolean` | `True` after `Prepare`. |
| `StatementType` | `TFIBSQLTypes` | Type of the `SelectSQL` statement as reported by the server. |
| `UpdatesPending` | `Boolean` | `True` when cached updates are waiting. |
| `WaitEndMasterInterval` | `Integer` | Milliseconds for `dcWaitEndMasterScroll` and `OnEndScroll`. Default `300`. The detail timer reads it at each master change. The `OnEndScroll` timer reads it once, when the event is assigned; a later change has no effect on it. The property is not published, so handlers loaded from a DFM use `300`. |
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
| `Prepare` | Start the transaction if `poStartTransaction` is set, prepare `SelectSQL`, and read the field definitions. Raises if `SelectSQL` is empty. |
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
| `BeforeFetchRecord` | Called by `QSelect` before it requests the next row from the server; `RecordNumber` is the number of rows already fetched. Setting `StopFetching` makes the fetch return no row, and `Eof` is not set. |
| `OnCompareFieldValues` | Compares two values for sorting. See `TCompareFieldValues`. |
| `OnDisableControls` / `OnEnableControls` | `DisableControls` and `EnableControls` changed the state of the controls. |
| `OnEndScroll` | The dataset has not scrolled for `WaitEndMasterInterval` milliseconds. The timer restarts on each `AfterScroll`, which is skipped while scroll events are disabled, but a timer started earlier can still fire after `DisableScrollEvents`. |
| `OnFieldChange` | A field value changed. |
| `OnFillClientBlob` | Fills a BLOB field that has `IsClientField` set. |
| `OnGetRecordError` | A database error while reading a row. Set `Action` to `daFail` (default, raises) or `daAbort`. |
| `OnReadBlobField` / `OnWriteBlobField` | Progress of a BLOB read or write. Set `Stop` to cancel. |

### Updates

These three events are raised only by `TpFIBDataSet.ApplyUpdates`, once for each pending row. The rules for the `UpdateAction` values are in [TpFIBDataSet](TpFIBDataSet.md#applying-cached-updates).

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
| `TFIBBCDField` | `ftBCD`: `BIGINT` (scale 0) unless `psUseLargeIntField` is set, and scaled 64-bit `NUMERIC` with scale up to 4, or any scale with `psSQLINT64ToBCD` | `AsInt64` (whole part), `AsBcd`, `AsExtended`, `AsComp` (when available), `Value`, `FieldModified`, and in-place arithmetic: `AddExtended`, `SubtractExtended`, `MultiplyExtended`, `DivideExtended`, `AddBCD`, `SubtractBCD`, `MultiplyBCD`, `DivideBCD`. Published: `Size` (default `8`). |
| `TFIBBlobField` | `ftBlob`, `ftFmtMemo`, `ftParadoxOle`, `ftDBaseOle`, `ftTypedBinary` | `SubType`, `Blob_ID`, `GetBlobInfo`. Published: `IsClientField` (default `False`): the value is not read from the server but filled in `OnFillClientBlob`. |
| `TFIBBooleanField` | `ftBoolean` | Published: `StringTrue`, `StringFalse` (text used by `AsString`). `SetAsString` also accepts `1`, `T`, `0`, `F`. A `SMALLINT` or `INTEGER` column also becomes a boolean field when `psUseBooleanField` is set and its metadata allows it. |
| `TFIBDateField` | `ftDate` | |
| `TFIBDateTimeField` | `ftDateTime` | `AsTimeStamp`. Published: `ShowMsec` (default `False`). |
| `TFIBFloatField` | `ftFloat` | `Scale` (read-only). Published: `RoundByScale` (default `True`): a value assigned to a field with a decimal scale is rounded to that scale. Assigning a value out of range raises a range error for a scaled `SMALLINT` or `INTEGER` column. |
| `TFIBFMTBCDField` | `ftFMTBcd`: `INT128`, `NUMERIC(19..38)`, `DECFLOAT(16)`, `DECFLOAT(34)` (*Firebird 4+*) | A `DECFLOAT` value that `TBcd` cannot hold (`NaN`, `Infinity`, more than 64 digits) is read as text by `AsString` and `DisplayText`, and as `Double` by `AsFloat` and `Value`; `AsBCD`, `AsCurrency`, `AsInteger`, and `AsLargeInt` raise a conversion error for it. |
| `TFIBGuidField` | `ftGuid` | `AsGuid`. |
| `TFIBIntegerField` | `ftInteger` | `AsBoolean`: `True` for a value above `0`; setting it writes `1` or `0`. |
| `TFIBLargeIntField` | `ftLargeint` | `OldValue` as `Int64`. |
| `TFIBMemoField` | `ftMemo`, `ftWideMemo` (*Delphi 2007+*) | `SubType`, `Blob_ID`, `GetBlobInfo`; implements `IWideStringField`. |
| `TFIBSmallIntField` | `ftSmallint` | `AsBoolean`: `True` for a value above `0`; setting it writes `1` or `0`. |
| `TFIBStringField` | `ftString` | `IsDBKey` (`True` for a `DB_KEY` column), `SqlSubType`, `CharacterSet` (name), `AsNativeData` and `AsOctetsData` (raw bytes; `AsOctetsData` can be set), `DefaultValueEmptyString`. Published: `EmptyStrToNull`. |
| `TFIBTimeField` | `ftTime` | Published: `ShowMsec` (default `False`): append the milliseconds to the text when they are not zero. |
| `TFIBWideStringField` | `ftWideString` | `SqlSubType`, `CharacterSet`, `CollateNumber`, `AsNativeData`. Published: `EmptyStrToNull`. |

`ftGraphic` fields use the standard `TGraphicField`.

`EmptyStrToNull` takes its initial value from `psSetEmptyStrToNull` in `PrepareOptions`. When it is `True`, an empty string assigned to the field is stored as `NULL`, except for a `NOT NULL` column whose default is an empty string.

## See also

- [TFIBQuery](TFIBQuery.md), [TFIBDatabase](TFIBDatabase.md), [TFIBTransaction](TFIBTransaction.md)
- [TpFIBDataSet](TpFIBDataSet.md)
- [Datasets and caching](../guide/datasets-and-caching.md)
- [Timeouts](../guide/timeouts.md)
