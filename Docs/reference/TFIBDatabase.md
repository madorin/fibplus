# TFIBDatabase

Connection to a Firebird or InterBase database. It loads the client library, attaches to the database, keeps the list of transactions and datasets that use the connection, and reads server information. Every `TFIBQuery`, `TFIBDataSet`, and `TFIBTransaction` needs a `TFIBDatabase`.

| | |
|---|---|
| Unit | `FIBDatabase` |
| Inherits from | `TComponent` |
| Descendants | `TpFIBDatabase`, which adds aliases, restoring a lost connection, the schema cache, and transaction events |

```delphi
Database.DBName := 'localhost:C:\Data\Sales.fdb';
Database.ConnectParams.UserName := 'SYSDBA';
Database.ConnectParams.Password := 'masterkey';
Database.ConnectParams.CharSet := 'UTF8';
Database.DefaultTransaction := Transaction;
Database.Connected := True;
```

The sample uses the components `Database` (`TFIBDatabase`) and `Transaction` (`TFIBTransaction`).

Guides: [Connections](../guide/connections.md), [Transactions](../guide/transactions.md), [Timeouts](../guide/timeouts.md), [Firebird versions](../guide/firebird-versions.md).

## Published properties

Available in the Object Inspector. When the component is dropped on a form at design time, `SynchronizeTime`, `UpperOldNames`, `UseLoginPrompt`, `SQLDialect`, `ConnectParams.CharSet`, and `DesignDBOptions` take their initial values from the design-time default settings (`Def*` variables of `pFIBProps`).

### Connection

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `AutoReconnect` | `Boolean` | `False` | When a component needs the connection and it is closed, connect again. The `UseLoginPrompt` value is ignored for this and restored afterwards. With an empty `ConnectParams.Password` there is one attempt, with the login dialog. With a password the first attempt has no dialog; if it fails, a second attempt is made with the dialog. Connect errors are swallowed in both cases. |
| `Connected` | `Boolean` | | Opens or closes the connection. While the form loads, the value is kept and applied after loading. |
| `ConnectParams` | `TConnectParams` | | Typed access to common `DBParams` entries, see [ConnectParams](#connectparams). |
| `DBName` | `string` | | Database name as passed to the client library, for example `server:C:\Data\Sales.fdb`. When the value changes, it raises while connected at run time; at design time it closes the connection. `DatabaseName` is the same property under another name. |
| `DBParams` | `TDBParams` | | Database parameters, one `Name=Value` per line, see [DBParams](#dbparams). Changing them at run time while connected raises. |
| `LibraryName` | `string` | `fbclient.dll` (`libfbclient.dylib` on macOS) | Client library to load. Raises while connected. Stored in the form only when it differs from the default. On Windows, `fbclient.dll` without a path falls back to `gds32.dll` when it cannot be loaded. |
| `LibraryName64` | `string` | | Client library for 64-bit Windows. Used instead of `LibraryName` when it is not empty. *Delphi XE2+* |
| `OnCryptKeyRequest` | `TFIBCryptKeyRequestEvent` | | Called during connect when the server asks for a key of an encrypted database. `Key` starts as `CryptKey`. Runs in the connecting thread, inside the global connect lock. |
| `UseLoginPrompt` | `Boolean` | `False` | Show the login dialog before connecting. Needs a login dialog unit in the application, for example `FIBDBLoginDlg`. |

### Session and server

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `Session` | `TFIBSession` | | Statement and idle timeouts sent to the server, see [TFIBSession](TFIBSession.md). |
| `SQLDialect` | `Integer` | `3` | SQL dialect of the connection. Values below `1` raise. While connected the value cannot exceed the dialect of the database. After connecting, a value above the database dialect is lowered to it. |
| `SynchronizeTime` | `Boolean` | `True` | At connect, measure the difference between the client clock and the server time into `DifferenceTime`. Not done at design time. |
| `UpperOldNames` | `Boolean` | `False` | Name conventions of InterBase 4 and 5. Together with `SQLDialect` below `3` it decides the result of `EasyFormatsStr`. |

### Transactions

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `DefaultTransaction` | `TFIBTransaction` | | Transaction used by `StartTransaction`, `Commit`, `Rollback`, and the retaining variants. |
| `DefaultUpdateTransaction` | `TFIBTransaction` | | Update transaction that a dataset takes over when this database is assigned to it, unless the dataset already has its own. |

### Client-side timeout

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `Timeout` | `Cardinal` | `0` | Milliseconds without activity after which the client closes the connection. `0` turns it off. The timer is not started at design time. See [Timeouts](../guide/timeouts.md#client-side-timeouts). |

### Design time and repositories

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `DesignDBOptions` | `TDesignDBOptions` | `[ddoStoreConnected]` | See [Types](#types). |
| `MemoSubtypes` | `string` | | BLOB subtypes, separated by `;`, that a dataset treats as text (memo) fields besides subtype `1`. A value of `1` in the list is ignored. |
| `UseRepositories` | `TFIBUseRepositories` | `[urFieldsInfo, urDataSetInfo, urErrorMessagesInfo]` | Which repository tables FibPlus reads, see [Types](#types). |

### BLOB handling and logging

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `BlobSwapSupport` | `TBlobSwapSupport` | | Stores BLOB values in files and reads them from there. Not used at design time. Properties: `Active` (`False`); `AutoValidateSwap` (`False`): on connect, when swapping is active and the swap directory exists, starts a thread that validates the swap files; `SwapDir` (`{APP_PATH}`, the application directory); `MinBlobSizeToSwap` (`0`); `Tables`: limits swapping to the listed tables, all tables when empty. At run time `SwapDirectory` gives the resolved directory with a trailing backslash, or an empty string when `Active` is `False`. |
| `SQLLogger` | `ISQLLogger` | | Component that receives a log of connects, statements, and session commands. |
| `UseBlrToTextFilter` | `Boolean` | `False` | Open BLOBs of subtypes `2` to `8` with a BLR-to-text filter. |

### Client and IDE hooks

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `CSMonitorSupport` | `TCSMonitorSupport` | | Monitoring text for statements. Only when compiled with `CSMonitor`. |
| `DoChangeScreenCursor` | `TDoChangeScreenCursor` | | Called by datasets to change the screen cursor while they run SQL; allows replacing the cursor handling. *Delphi XE2+* |
| `GeneratorsCache` | `TGeneratorsCache` | | Client-side cache of generator values, used by `Gen_Id` when `Step` is `1`. Properties: `CacheFileName`, `DefaultStep` (`50`), `GeneratorList`, `UseGeneratorCache` (`No`, `forAll`, `forGeneratorList`). Methods: `AddGenerator(GenName, Limit)` adds an entry to the list unless it exists; `RemoveGenerator(GenName)` removes one. |

## Types

| Type | Values |
|------|--------|
| `TDesignDBOptions` | Set of `ddoIsDefaultDatabase` (this database is the default for components created at design time; only one database can have it), `ddoStoreConnected` (store `Connected = True` in the form), `ddoNotSavePassword` (leave the password out of `DBParams` when the form is saved). |
| `TFIBUseRepositories` | Set of `urFieldsInfo` (`FIB$FIELDS_INFO`), `urDataSetInfo` (`FIB$DATASETS_INFO`), `urErrorMessagesInfo` (`FIB$ERROR_MESSAGES`). |
| `TFBContextSpace` | `csSystem`, `csSession`, `csTransaction`: the `SYSTEM`, `USER_SESSION`, and `USER_TRANSACTION` namespaces. |
| `TpFIBDBEventType` | `detOnConnect`, `detBeforeDisconnect`, `detBeforeDestroy`: the lists used by `AddEvent` and `RemoveEvent`. |
| `TActionOnIdle` | `aiCloseConnect`, `aiKeepLiveConnect`: the answer of `OnIdleConnect`. |
| `TIBCharSets` | `set of Byte` of character set IDs. |

## ConnectParams

`ConnectParams` reads and writes entries of `DBParams`, so both views stay in step. The property is not stored in the form (`stored False`), and neither are its values, including `IsFirebird` and `IB2007`; the form stores `DBParams`.

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `CharSet` | `string` | | Connection character set (`lc_ctype`). The value is converted to upper case. |
| `IsFirebird` | `Boolean` | `True` | `False` for InterBase: Firebird-only parameters (such as `config` and `session_time_zone`) are left out of the connection parameters. |
| `Password` | `string` | | Password (`password`). |
| `RoleName` | `string` | | SQL role (`sql_role_name`). |
| `UserName` | `string` | | User name (`user_name`). |
| `WireCompression` | `Boolean` | `False` | *Firebird 3+*. Writes `WireCompression` as `config=WireCompression=true` in `DBParams`, or removes it. |
| `IB2007` | `TIBConnectParams` | | InterBase 2007 options (`InstanceName`). Only when compiled with `SUPPORT_IB2007`. |

## DBParams

`DBParams` holds one entry per line, in the form `Name=Value` or `Name` alone. The names are the DPB parameter names, such as `user_name`, `password`, `lc_ctype`, `sql_role_name`. A line `config=Name=Value` passes a configuration value to the client (for example `config=WireCompression=true`); `ConfigParam` reads and writes these lines.

`DBParams` is also the text that `CreateDatabase` appends to `CREATE DATABASE`, and the source of the parameters of `ShutDown` and `Online`.

## Capabilities

`Capabilities` tells what the current connection supports. It is a `TFIBDatabaseCapabilities` object, read-only, filled when the connection opens and cleared when it closes. The code page values stay after `Close`, so that open datasets can still convert their text.

| Name | Type | Description |
|------|------|-------------|
| `AttachmentCharSetID` | `Integer` | Character set ID of the attachment as the server reports it. `-1` when unknown (InterBase, or not connected); `0` is `NONE`. |
| `BlobCodePage(CharSetID)` | `Word` | Code page of a text BLOB whose character set ID is `CharSetID` (the `sqlscale` of the column). |
| `CodePage` | `Word` | Code page of the SQL text and of text values in the attachment character set. |
| `MaxIdentifierLength` | `Integer` | Characters allowed in a metadata name: `63` on *Firebird 4+*, otherwise `31`. `0` when not connected. |
| `MetadataCodePage` | `Word` | Code page of DDL and of the names the server sends. UTF-8 when metadata is sent in UTF-8 (a `NONE` or Unicode attachment on *Firebird 2.1+* with ODS 11.1 or later); otherwise `CodePage`. |
| `SessionTimeouts` | `Boolean` | `True` on a *Firebird 4+* server: `Session.StatementTimeout` and `Session.IdleTimeout` work. |
| `StatementTimeout` | `Boolean` | `True` when `SessionTimeouts` is `True` and the client library supports per-statement timeouts (`fbclient` 4+): `TFIBQuery.StatementTimeout` and `TpFIBDataSet.StatementTimeout` work. |
| `TextCodePage(CharSetID)` | `Word` | Code page of a text value whose character set ID is `CharSetID` (the `sqlsubtype` of the column). The system code page for `NONE` and `OCTETS`; the attachment code page when the server converts the text; otherwise the code page of the column character set. |

```delphi
if Database.Capabilities.SessionTimeouts then
  Database.Session.StatementTimeout := 30000;
```

## Run-time properties

### State

| Name | Type | Description |
|------|------|-------------|
| `ActiveTransactionCount` | `Integer` | Number of transactions of this database that are active. |
| `AttachmentID` | `Int64` | Attachment ID on the server; `0` when not connected. |
| `Busy` | `Boolean` | `True` while the client library runs a call. |
| `Capabilities` | `TFIBDatabaseCapabilities` | See [Capabilities](#capabilities). |
| `ClientLibrary` | `IIbClientLibrary` | The loaded client library. `ClientLibrary.Version` gives product and version as a `TFIBVersion` record. |
| `ConnectionSerial` | `Integer` | Number of the connection, unique in the process; kept after `Close`. |
| `FIBBaseCount`, `FIBBases[Index]` | `Integer`, `TFIBBase` | Queries and datasets (`TFIBBase` objects) attached to this database. |
| `FirstActiveTransaction` | `TFIBTransaction` | First active transaction of this database, or `nil`. A transaction that spans several databases counts only if this database is its `DefaultDatabase`. |
| `Handle` | `TISC_DB_HANDLE` | Native database handle. Assigning a non-nil handle makes the database use an existing attachment; `Close` does not detach it. A handle can be assigned only while the database is not connected, or while it uses a shared handle. |
| `HandleIsShared` | `Boolean` | `True` when `Handle` was assigned from outside. |
| `TransactionCount`, `Transactions[Index]` | `Integer`, `TFIBTransaction` | Transactions linked to this database. |

### Connection and encryption

| Name | Type | Description |
|------|------|-------------|
| `ConfigParam[Name]` | `string` | *Firebird 3+*. Value of the `config=Name=Value` line of `DBParams`. Writing an empty value removes the line. |
| `CryptKey` | `FIBByteString` | Key for a database encrypted with a *Firebird 3+* crypt plugin. Not published, so it is not stored in the form. |
| `DBParamByDPB[Idx]` | `string` | Value of a `DBParams` entry by `isc_dpb_*` constant; an empty value removes the entry. |
| `StoreConnected` | `Boolean` | `True` when `Connected` is stored in the form: connected and `ddoStoreConnected` set. |

### Server information

Values come from the server while connected.

| Name | Type | Description |
|------|------|-------------|
| `BaseLevel`, `DBSQLDialect`, `ReadOnly`, `NoReserve` | `Long`, `Word`, `Long`, `Long` | Base level, database dialect, read-only flag, and page reserve of the database. |
| `CreationDate` | `TDateTime` | Date the database was created, as the server reports it. `0` if the server does not report it. |
| `DBFileName`, `DBSiteName`, `IsRemoteConnect` | `AnsiString`, `AnsiString`, `Boolean` | File and host from `isc_info_db_id`, and whether the connection is remote. |
| `DBImplementationClass`, `DBImplementationNo` | `Long` | Server implementation and class. |
| `DifferenceTime` | `Double` | Client clock minus server time, in days, measured at connect when `SynchronizeTime` is `True`; otherwise `0`. |
| `FBVersion` | `string` | Firebird version string of the server. |
| `IsFB21OrMore` | `Boolean` | `True` for *Firebird 2.1+*. |
| `ODSMajorVersion`, `ODSMinorVersion` | `Long` | On-disk structure version. |
| `OldestActiveTransactionID`, `OldestTransactionID` | `Long` | Oldest active and oldest transaction. |
| `PageSize` | `Long` | Page size in bytes. |
| `ServerActiveTransactions` | `TStringList` | IDs of the transactions active on the server. |
| `ServerMajorVersion`, `ServerMinorVersion`, `ServerRelease`, `ServerBuild` | `Integer` | Server version parts, read from `FBVersion` (Firebird) or `Version` (InterBase). |
| `Version` | `string` | Version string from the `isc_info_version` item. |

Statistics and tuning values, each read with the matching `isc_info_*` item:

| Name | Type |
|------|------|
| `Allocation`, `CurrentMemory`, `ForcedWrites`, `MaxMemory`, `NumBuffers`, `SweepInterval` | `Long` |
| `Fetches`, `Marks`, `Reads`, `Writes` | `Long` |
| `BackoutCount`, `DeleteCount`, `ExpungeCount`, `InsertCount`, `PurgeCount`, `ReadIdxCount`, `ReadSeqCount`, `UpdateCount` | `TStringList` (one `TableID=Count` line per table) |
| `DeletesCount[Table]`, `IndexedReadCount[Table]`, `InsertsCount[Table]`, `NonIndexedReadCount[Table]`, `UpdatesCount[Table]` | `Integer` |
| `AllModifications` | `Integer` |
| `UserNames` | `TStringList` |

Write-ahead log values (`LogFile`, `CurLogFileName`, `CurLogPartitionOffset`, `NumWALBuffers`, `WALBufferSize`, `WALCheckpointLength`, `WALCurCheckpointInterval`, `WALPrvCheckpointFilename`, `WALPrvCheckpointPartOffset`, `WALGroupCommitWaitUSecs`, `WALNumIO`, `WALAverageIOSize`, `WALNumCommits`, `WALAverageGroupCommitSize`) read the matching `isc_info_*` items.

### Logging and statistics

| Name | Type | Description |
|------|------|-------------|
| `SQLStatisticsMaker` | `ISQLStatMaker` | Component that collects statement statistics. |

## Methods

### Connecting

| Name | Description |
|------|-------------|
| `Open(RaiseExcept)` | Connect. With `RaiseExcept = False`, a failed attach or a failed session setup returns with `Connected = False` instead of raising. Reads the server version, fills `Capabilities`, and sends the `Session` values. `RaiseExcept` is `True` by default. |
| `Close` | Disconnect. Ends the active transactions of this database as their `TimeoutAction` says (retaining actions end without retaining), then detaches. Errors raise. |
| `ForceClose` | The same as `Close`, but errors while ending transactions and detaching are ignored and the handle is always reset. |
| `TestConnected` | Read a value from the server. If that fails, close the connection with `ForceClose` and return `False`. |
| `PingAttachment` | Return `0` if the server answers, else the error code. Raises nothing; safe to call while handling an error. |
| `CheckActive(TryReconnect)` | If a `Connected = True` stored in the form is still pending, open it first. When the database is closed: at run time without `AutoReconnect` it raises, and `TryReconnect` has no effect; at design time it does not raise. It tries to connect when `AutoReconnect` is `True`, or when `TryReconnect` is `True` at design time, with the attempts described for `AutoReconnect`; connect errors are swallowed. |
| `CheckInactive` | Raise if the database is connected. |
| `CheckDatabaseName` | Raise if `DBName` is empty. |
| `FindTransaction(TR)` | Index of `TR` in `Transactions`, or `-1`. |
| `IndexOfDBConst(Name)` | Index of the first `DBParams` entry that starts with the name, with or without the `isc_dpb_` prefix; `-1` when there is none. |

### Database administration

| Name | Description |
|------|-------------|
| `CreateDatabase` | Run `CREATE DATABASE` with `DBName` and the text of `DBParams`. The new attachment is open afterwards. Raises if already connected. |
| `DropDatabase` | Delete the connected database. |
| `ShutDown(ShutParams, Delay)` | Connect with the `shutdown` parameter built from the `isc_dpb_shut_*` values in `ShutParams`, and with `shutdown_delay` when `Delay` is greater than `0`; then disconnect. Only the user name and password of the old parameters are kept for the call; `DBParams` is restored afterwards. |
| `Online` | Bring a shut down database online with the `online` parameter, in the same way as `ShutDown`. |

### Transactions

| Name | Description |
|------|-------------|
| `StartTransaction`, `Commit`, `Rollback`, `CommitRetaining`, `RollbackRetaining` | Call the same method of `DefaultTransaction`. Raise when `DefaultTransaction` is not set. |

### Running SQL

`QueryValue`, `QueryValues`, and `InternalQueryValue` run in `aTransaction` when one is passed. Otherwise they use the internal transaction of the database, start it if needed, and commit it afterwards; a transaction that is passed in is never committed by them. `Execute`, `QueryValueAsStr`, `CreateGUIDDomain`, and `GetServerTime` have no `aTransaction` parameter and always use the internal transaction. `Gen_Id` has its own rule, below.

| Name | Description |
|------|-------------|
| `Execute(SQL)` | Run a statement and return `True`. Any exception is swallowed and gives `False`. |
| `Gen_Id(GeneratorName, Step, aTransaction)` | Next value of a generator. With `Step = 1` and a usable `GeneratorsCache`, values come from the client cache; otherwise the method runs `gen_id(Name, Step)`. It runs in `FirstActiveTransaction` if there is one, else in `aTransaction`, else in the internal transaction; it starts and commits a transaction only if the one it uses is not active. |
| `QueryValue(SQL, FieldNo, [ParamValues], aTransaction, aCacheQuery)` | Run a query and return one column of the first row as a `Variant`. `ParamValues` fill the parameters in order. BLOB values come back as strings. `aCacheQuery` keeps the prepared query for reuse. |
| `QueryValues(SQL, [ParamValues], aTransaction, aCacheQuery)` | Like `QueryValue` for all columns: a `Variant` array. |
| `QueryValueAsStr(SQL, FieldNo, [ParamValues])` | Like `QueryValue`, as a string; `Null` gives an empty string. |
| `InternalQueryValue(SQL, FieldNo, ParamValues, aTransaction, aCacheQuery)` | The implementation of the methods above. |
| `ClearQueryCacheList` | Clear the cached prepared queries of this database. |
| `CreateGUIDDomain` | Run `CREATE DOMAIN TGUID AS CHAR(16) CHARACTER SET OCTETS` through `Execute`, so errors, for example an existing domain, are swallowed. |
| `GetServerTime` | Current time of the server. |
| `GetContextVariable(ContextSpace, VarName, aTransaction)` | Value from `rdb$get_context`. *Firebird 2+*; raises on older servers and on InterBase. |
| `SetContextVariable(ContextSpace, VarName, VarValue, aTransaction)` | Set a value with `rdb$set_context`. *Firebird 2+*. |

### Cancelling operations

| Name | Description |
|------|-------------|
| `CanCancelOperationFB21` | `True` on a *Firebird 2.1+* server. |
| `CancelOperationFB21(ConnectForCancel)` | While the client library is busy, delete the running statement of this attachment from `MON$STATEMENTS` through a second connection. Uses `ConnectForCancel` if it is given and not busy; otherwise creates a temporary connection with the same parameters. |
| `EnableCancelOperations`, `DisableCancelOperations` | Allow or forbid cancellation of the attachment through `fb_cancel_operation`. |
| `RaiseCancelOperations` | While the client library is busy, cancel the running call through `fb_cancel_operation`. |

### Character sets

| Name | Description |
|------|-------------|
| `BytesInUnicodeChar(CharSetId)` | Bytes per character. `UNICODE_FSS` (ID 3) gives `3`. While connected, also `4` for `UTF8` on Firebird, and `2` or `4` for the InterBase 2007 sets. Otherwise `1`. |
| `EasyFormatsStr` | `True` when `SQLDialect` is below `3` or `UpperOldNames` is `True`. |
| `IsIB2007Connect` | `True` for an *InterBase 2007+* server. |
| `IsFirebirdConnect` | `True` for a Firebird server. |
| `IsUnicodeConnect` | `True` for a Unicode attachment. Before connecting it reads `ConnectParams.CharSet` (`UTF8`, `UNICODE_FSS`). |
| `IsMemoSubtype(Subtype)`, `MemoSubTypesActive` | Whether a BLOB subtype is in `MemoSubtypes`, and whether the list has any entries. |
| `NeedUnicodeFieldsTranslation`, `NeedUnicodeFieldTranslation(CharacterSet)` | Whether text values need translation: for all fields, or for a field with that character set ID. For all fields it is `True` for a Unicode or `NONE` attachment; before connecting it reads `ConnectParams.CharSet`. |
| `NeedUTFEncodeDDL` | `True` when metadata is sent in UTF-8. |
| `ReturnDeclaredFieldSize` | `False` on a connected *Firebird 2+* server, else `True`. |
| `UnicodeCharSets` | Set of Unicode character set IDs: `3`, plus `4` on a connected Firebird server, or `8`, `59`, `64` on a connected InterBase 2007 server. |
| `UTF8CharSetID` | ID of the UTF-8 character set for this server. |

### Client library and extensions

| Name | Description |
|------|-------------|
| `ClientVersion` | Version string of the client library. |
| `LibraryFilePath` | Full path of the loaded client library, or `LibraryName` when none is loaded. |
| `RegisterBlobFilter(BlobSubType, EncodeProc, DecodeProc)`, `RemoveBlobFilter(BlobSubType)` | Add or remove a client-side BLOB filter for a subtype. |
| `AddEvent(Event, EventType)`, `RemoveEvent(Event, EventType)` | Add or remove a handler in the list for `detOnConnect`, `detBeforeDisconnect`, or `detBeforeDestroy`. Several handlers can share a list. |
| `Call(ErrCode, RaiseError)` | Wrapper for client library calls: restarts the `Timeout` timer and raises the server error when `RaiseError` is `True`. For code that calls the API directly. |
| `RequireSessionTimeouts(PropName, Value)`, `RequireStatementTimeout(PropName, Value)` | Raise `EFIBClientError` (`feFeatureNotSupported`) for a non-zero `Value` that the server or the client library cannot apply; `0` never raises. `RequireStatementTimeout` also never raises for `FIBNoStatementTimeout` when `Capabilities.SessionTimeouts` is `False`. `Session` calls `RequireSessionTimeouts`; `TFIBQuery` and `TFIBDataSet` call `RequireStatementTimeout`. |

### Deprecated

| Name | Use instead |
|------|-------------|
| `ClientMajorVersion`, `ClientMinorVersion` | `ClientLibrary.Version` |
| `FBAttachCharsetID` | `Capabilities.AttachmentCharSetID` |
| `IsKOI8Connect` | `Capabilities.AttachmentCharSetID` |

## Protected

For descendant authors. `TpFIBDatabase` overrides `InternalClose` and `SaveAlias`.

| Name | Description |
|------|-------------|
| `InternalClose(Force, DBinShutDown)` | Virtual. The implementation of `Close` and `ForceClose`; `DBinShutDown` marks a dead attachment whose handles are only forgotten. |
| `SaveAlias` | Virtual. Does nothing here; `TpFIBDatabase` writes the `DBParams` to its alias. |
| `DoOnConnect` | Reads the character set state into `Capabilities`, then runs `OnConnect` and the `detOnConnect` list. |
| `DoBeforeDisconnect`, `DoAfterDisconnect` | Run `BeforeDisconnect` with the `detBeforeDisconnect` list, and `AfterDisconnect`. |
| `Loaded` | Makes this the default database if `ddoIsDefaultDatabase` is set, and opens the connection if `Connected` was stored in the form. |

## Events

| Name | Description |
|------|-------------|
| `AfterDisconnect` | After the connection closed. |
| `AfterLoadBlobFromSwap` | After a BLOB was loaded from a swap file. |
| `AfterSaveBlobToSwap` | After a BLOB was saved to a swap file. |
| `BeforeDisconnect` | Before the connection closes, while transactions are still active. An exception raised here is re-raised with the component name added. |
| `BeforeLoadBlobFromSwap` | Before a BLOB is loaded from a swap file. Set `FileName` to change the file; set `CanLoad` to `False` to skip the file. |
| `BeforeSaveBlobToSwap` | Before a BLOB is saved to a swap file. Set `FileName` to change the file; set `CanSave` to `False` to skip saving. |
| `OnConnect` | After connecting. Obsolete; use `AddEvent` with `detOnConnect`. Not stored in the form. |
| `OnIdleConnect` | The `Timeout` timer expired. Set `Action` to `aiKeepLiveConnect` to keep the connection; `IdleTicks` is the time since the last activity. |
| `OnTimeout` | After the client closed the connection because of `Timeout`. |

## See also

- [TFIBSession](TFIBSession.md), [TFIBTransaction](TFIBTransaction.md), [TFIBQuery](TFIBQuery.md), [TFIBDataSet](TFIBDataSet.md)
- [TpFIBDatabase](TpFIBDatabase.md)
- [Connections](../guide/connections.md)
- [Timeouts](../guide/timeouts.md)
