# FIBPlus samples

Small VCL applications, one per feature. The project group `src\pgFIBPlusExamples.groupproj` contains all of them except `GUID_UDF`, which is a server library, and `UnicodeFSS`. The project files are for Delphi 2009 and later; in older versions open the `.dpr` files.

## Before you run them

1. Install the FIBPlus packages and add `Source` to the library path, as described in the [main README](../README.md). Some samples also use units from `Source\Editors`.
2. Add the alias `fibplus_samples` to `databases.conf` in the Firebird folder, pointing to the file the database will be created in, and restart the server:

   ```
   fibplus_samples = <FIBPlus folder>\Samples\db\employee.fdb
   ```

3. Create the database from `db\metadata.sql`. Its `CREATE DATABASE` statement uses the alias. The script was extracted with IBExpert and uses its `SET CLIENTLIB` command, so run it in IBExpert, or remove this line before you run it in `isql`.
4. Build the samples. The executables are written to the `Samples` folder.

All samples, at design time and at run time, connect to `localhost:fibplus_samples` as `SYSDBA` with the password `masterkey`, through `fbclient.dll`. The run-time connection string is the `DemoDB` constant in `src\FIBExamples.inc`; change it there to use another server or path. Change the user and password in the `TpFIBDatabase` component if your server uses other ones.

The database is the Firebird `employee` database with extra tables for the samples: `BIGTABLE` and `BIGTABLE_DETAIL`, `BLOBFLT`, and the FIBPlus repository tables `FIB$DATASETS_INFO`, `FIB$FIELDS_INFO`, `FIB$ERROR_MESSAGES` and `FIB$APP_STATISTICS`.

## Datasets

| Sample | Shows |
|--------|-------|
| `DataSetBasic` | A `TpFIBDataSet` with `SelectSQL`, `InsertSQL`, `UpdateSQL`, `DeleteSQL` and `RefreshSQL` filled in at design time. |
| `DataSetOptions` | `Options` and `PrepareOptions` of `TpFIBDataSet`. The button opens the options editor and reopens the dataset with the new options. Run `SQLMonitor` beside it to see the statements that each option issues. |
| `AutoUpdateOptions` | A dataset that generates its modifying statements at run time from `AutoUpdateOptions`: table `EMPLOYEE`, key `EMP_NO`, generator `EMP_NO_GEN` read before post, and only the modified fields in `UPDATE`. |
| `MasterDetail` | Customers and their sales in a master-detail pair (`DataSource` of the detail dataset). Posting a customer refreshes its sales. |
| `RefreshDataSet` | Three ways to refresh `BIGTABLE`: `Refresh` of the current record, `FullRefresh`, and `RefreshFromQuery` with a query that reads only the rows changed since the last fetch (`LAST_UPDATE`). |
| `LimitedBuffersSize` | `CacheModelOptions.CacheModelKind = cmkLimitedBufferSize`, which keeps only `BufferChunks` records in memory. The two tabs open `BIGTABLE` in the normal and the limited mode. `BIGTABLE` has 10,000 rows; the button fills it with more (1,000,000 by default) through the `GEN_BIGTABLE_CONTENT` procedure. |
| `StoredProcedure` | The first tab selects from the `ORG_CHART` procedure in a `TpFIBDataSet`. The button on the second tab runs `SUB_TOT_BUDGET` in a `TpFIBStoredProc` for the current department and shows the total, average, minimum and maximum budget. |
| `ArrayFields1` | Reading the `LANGUAGE_REQ` array field with `ArrayFieldValue` into edit boxes, and writing it back with `SetArrayValue` before post. |
| `ArrayFields2` | The same array, selected as separate elements `LANGUAGE_REQ[1]` to `[5]` and packed back into the array before post. |

## Sort, filter and search

| Sample | Shows |
|--------|-------|
| `LocalSorting` | Sorting on the client with `DoSortEx` by clicking the grid titles, on several fields and in both directions. The radio buttons switch `OnCompareFieldValues` between the default comparison and `StdAnsiCompareString`. |
| `LocalFiltering` | Filtering on the client with the `Filter` property or with `OnFilterRecord`, with or without case sensitivity. |
| `ServerFilteringContitions` | Filtering on the server with `Conditions`: the conditions are added, enabled and applied with `ApplyConditions`, and the memo shows the resulting SQL. |
| `ServerFilteringMacroses` | The same filter built with macros in `SelectSQL` instead of conditions. |

## Editing and transactions

| Sample | Shows |
|--------|-------|
| `PotectedEditing` | `poProtectedEdit` with `poUseSelectForLock`, which locks the record when editing starts (pessimistic locking). The same `EMPLOYEE` table is open in two connections; edit a record in one of them, then try to edit the same record in the other. |
| `OfflineWork` | Cached updates while disconnected. In offline mode `AutoReconnect` is on and the connection closes after 300 ms of inactivity; edit the grid and apply the updates, and the dataset reconnects to write them with `ApplyUpdToBase` and `CommitUpdToCach`. |
| `ConnectionLost` | Handling a lost connection with `TpFibErrorHandler`, `OnLostConnect` and cached updates. Stop the server or break the connection, choose what to do in the combo box (close the connection, close the application, or wait for the connection to come back), and apply the cached updates when it is restored. |

## Repositories

| Sample | Shows |
|--------|-------|
| `FieldsRepository` | The fields repository (`FIB$FIELDS_INFO`): display labels, visibility and formats of the fields, and an `EDIT_MASK` value read in `TDataSetsContainer.OnApplyFieldRepository`. The button opens the repository editor. |
| `DataSetRepository` | The dataset repository (`FIB$DATASETS_INFO`): the button picks a dataset description and the dataset opens with its SQL. |
| `ErrorMessagesRepository` | The error messages repository (`FIB$ERROR_MESSAGES`) and `TpFibErrorHandler`: inserting an empty employee breaks several constraints, and the handler shows the custom message for each. The other button opens the repository editor. |

## Events, monitoring and logging

| Sample | Shows |
|--------|-------|
| `Events` | `TSIBfibEventAlerter`. The button inserts an order into `SALES` with a `TpFIBQuery`; the trigger posts the event `new_order`, and the application receives it and offers to refresh the dataset. It also uses `TpFIBDatabase.QueryValues`. |
| `SQLMonitor` | A monitor that receives the statements of other FIBPlus applications through `TFIBSQLMonitor`, with a check box for each trace flag. Start it, then run another sample. |
| `SQLLogger` | `TFIBSQLLogger`: runs random statements, writes them to `test.log` and saves the statistics to `FIB$APP_STATISTICS`, shown in the grid. |
| `BackgroundQueries` | Opening datasets in background threads, each with its own connection and window. The second button runs an endless `EXECUTE BLOCK`; closing its window cancels the statement (Firebird 2.1 and later). |

## Other

| Sample | Shows |
|--------|-------|
| `BlobFilters` | A client BLOB filter registered with `RegisterBlobFilter` for sub type -15, which compresses `BLOBFLT.BLOBDATA` with `TCompressionStream` and `TDecompressionStream` from the `ZLib` unit of Delphi. The button loads a file into a new record. The table key is a GUID filled by `TFIBGuidField` (`poUseGuidField`). Wire compression (`ConnectParams.WireCompression`, Firebird 3+) compresses only the traffic; the filter also keeps the data compressed in the database, but then only clients with the same filter can read it. |
| `Scripter` | `TpFIBScripter`: loading a script, parsing it into a tree of objects (double-click a node to select its statement), and running it whole, with pause, or statement by statement. |
| `DLL\DLLMain`, `DLL\TestDLL` | Sharing a connection with a DLL: the application passes `TpFIBDatabase.Handle` to `testdll.dll`, which assigns it to its own `TpFIBDatabase`. Add `ibase` to `uses` for the `TISC_DB_HANDLE` type. |
| `UnicodeFSS`, `UnicodeFSS_2009` | A connection with `lc_ctype=UNICODE_FSS` and three ways to find a Unicode string: `Locate` on the string field, and `Locate` on the ID read with `QueryValue`, with the string as a parameter or inside the SQL text. `UnicodeFSS` needs the TNT Unicode Controls; `UnicodeFSS_2009` uses the standard controls of Delphi 2009 and later. Both need a table `UNICODE_TABLE (ID, UNICODE_STRING)` with a `UNICODE_FSS` string column, which `metadata.sql` does not create. |
| `GUID_UDF` | A UDF library with a `CreateGUID` function, declared in `GUID_UDF.SQL`. Firebird 2.1 and later have the built-in `GEN_UUID()`, and Firebird 4 and later disable UDFs by default. |
