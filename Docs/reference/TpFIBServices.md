# IB_Services components

Service components for the Firebird and InterBase Services API (`service_mgr`): back up and restore a database, change database properties, validate and repair, manage users, read statistics and the server log, and query server information. They connect to the server's service manager, not to a database, so they need no `TFIBDatabase`.

| | |
|---|---|
| Unit | `IB_Services` |
| Inherits from | `TpFIBCustomService`, which inherits from `TComponent` |
| Palette page | `FIBPlusServices` |

The components exist only when `INC_SERVICE_SUPPORT` is defined, which `FIBPlus.inc` does by default.

Eleven classes are registered on the palette page: `TpFIBServerProperties`, `TpFIBConfigService`, `TpFIBLicensingService`, `TpFIBLogService`, `TpFIBStatisticalService`, `TpFIBBackupService`, `TpFIBRestoreService`, `TpFIBValidationService`, `TpFIBSecurityService`, `TpFIBNBackupService`, and `TpFIBNRestoreService`. The base classes are not registered. `RegFIBPlus.pas` also registers `TpFIBInstall` and `TpFIBUnInstall` on this page under `IBINSTALL_SUPPORT`, which `FIBPlus.inc` leaves commented out.

```delphi
Backup.ServerName := 'localhost';
Backup.LoginPrompt := False;
Backup.Params.Values['user_name'] := 'SYSDBA';
Backup.Params.Values['password'] := 'masterkey';
Backup.Active := True;
try
  Backup.DatabaseName := 'C:\Data\Sales.fdb';
  Backup.BackupFile.Text := 'C:\Backup\Sales.fbk';
  Backup.Verbose := True;
  Backup.ServiceStart;
  repeat
    Line := Backup.GetNextLine;
    if Line <> '' then
      Writeln(Line);
  until Backup.Eof;
finally
  Backup.Active := False;
end;
```

`Backup` is a `TpFIBBackupService` and `Line` is a `string`. This sample was not run against a server.

## Class overview

| Class | Purpose |
|-------|---------|
| [TpFIBCustomService](#tpfibcustomservice) | Base class: attach to the service manager and detach |
| [TpFIBServerProperties](#tpfibserverproperties) | Read database list, license, configuration, and version of the server |
| [TpFIBControlService](#tpfibcontrolservice) | Base class for services that are started with `ServiceStart` |
| [TpFIBControlAndQueryService](#tpfibcontrolandqueryservice) | Base class for started services that return text output |
| [TpFIBConfigService](#tpfibconfigservice) | Change database properties, shut down, bring online |
| [TpFIBLicensingService](#tpfiblicensingservice) | Add or remove a license key |
| [TpFIBLogService](#tpfiblogservice) | Read the server log |
| [TpFIBStatisticalService](#tpfibstatisticalservice) | Database statistics |
| [TpFIBBackupService](#tpfibbackupservice) | Back up a database |
| [TpFIBRestoreService](#tpfibrestoreservice) | Restore a database from a backup |
| [TpFIBNBackupService](#tpfibnbackupservice) | Incremental backup |
| [TpFIBNRestoreService](#tpfibnrestoreservice) | Restore from incremental backup files |
| [TpFIBValidationService](#tpfibvalidationservice) | Validate, sweep, and repair; handle limbo transactions |
| [TpFIBSecurityService](#tpfibsecurityservice) | Manage users |

`TpFIBBackupRestoreService` sits between `TpFIBControlAndQueryService` and the backup and restore classes. It adds the published `Verbose` and `OnTextNotify`.

The calls of every service are reported to the SQL monitor, unless the library is compiled with `NO_MONITOR`. See [TFIBSQLMonitor](TFIBSQLMonitor.md).

## Using a service

1. Set `ServerName` (or leave it empty for a local connection) and the login parameters in `Params`.
2. Set `Active := True`, or call `Attach`.
3. Set the properties of the service and call `ServiceStart`, or one of the specific methods of the class.
4. For a service that returns text, read the output with `GetNextLine` until `Eof`, or set `OnTextNotify`.
5. Set `Active := False`, or call `Detach`.

`ServiceStart` raises an error when the component is not attached. Most of the service-specific methods (for example the `Set...` methods of `TpFIBConfigService`) start the service directly.

## TpFIBCustomService

Common base class. It owns the connection to the service manager. It does not start any action.

### Published properties

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `Active` | `Boolean` | `False` | `True` while attached. Setting it calls `Attach` or `Detach`. While the form loads, the value is applied after loading; at design time an error is shown instead of raised. |
| `ServerName` | `AnsiString` | | Server host. Setting a name while `Protocol` is `Local` changes `Protocol` to `TCP`; clearing it changes `Protocol` to `Local`. Raises when the component is attached. |
| `Protocol` | `TProtocol` | `Local` | `TCP`, `SPX`, `NamedPipe`, or `Local`. Setting `Local` clears `ServerName`. Raises when the component is attached. |
| `LibraryName` | `string` | the default client library | Client library to load. Stored in the form only when changed. Raises when the component is attached. |
| `Params` | `TStrings` | | Service parameters as `name=value` lines, see [Params](#params). Raises on change when the component is attached. |
| `LoginPrompt` | `Boolean` | `True` | Ask for the login on `Attach`, see [Login](#login). |
| `OnAttach` | `TNotifyEvent` | | After a successful `Attach`. |
| `OnLogin` | `TLoginEvent` | | Called before `Attach` when `LoginPrompt` is `True`. Receives a copy of `Params` that the handler can change. |

`TLoginEvent` is `procedure(Database: TpFIBCustomService; LoginParams: TStrings) of object`.

### Run-time properties

| Name | Type | Description |
|------|------|-------------|
| `Handle` | `TISC_SVC_HANDLE` | Native service handle; `nil` when not attached. |
| `ClientLibrary` | `IIBClientLibrary` | Loaded client library; `nil` until the first call that needs it. |
| `ServiceParamBySPB[Idx]` | `String` | Value of a service parameter by its index in `SPBConstantNames`. Reading returns an empty string when the parameter is missing. Writing an empty string removes it. |
| `SSPB` | `PAnsiChar` | The service parameter buffer built from `Params`. |

### Methods

| Name | Description |
|------|-------------|
| `Attach` | Connect to the service manager. Raises when already attached or when `ServerName` is empty and `Protocol` is not `Local`. Raises `feOperationCancelled` when the login is cancelled. |
| `Detach` | Disconnect. Raises when not attached. |

Destroying a component that is attached detaches it.

### Params

`Params` holds service parameter buffer entries as `name=value` lines. When the buffer is built, the name is converted to lower case and can carry the `isc_spb_` prefix; lines without `=` are skipped. Only these names are accepted; any other name raises an error:

| Name | Value |
|------|-------|
| `user_name` | User name |
| `password` | Password |
| `sql_role_name` | SQL role |
| `command_line` | Command line string |
| `connect_timeout` | Integer |
| `dummy_packet_interval` | Integer |

### Login

When `LoginPrompt` is `True`, `Attach` calls `OnLogin` if it is assigned. Otherwise it calls the login dialog registered in `pFIBLoginDialog` (set up by the login dialog units) with the `user_name`, `password`, and `sql_role_name` entries of `Params`, and writes the result back. The lookup of these entries in `Params` is case-sensitive, so an entry such as `User_Name=` is not found and the dialog path adds a second `user_name=` line. When neither is available, the login counts as cancelled and `Attach` raises `feOperationCancelled`. Set `LoginPrompt := False` and fill `Params` to attach without a dialog.

### Protected members

For authors of descendants.

| Name | Description |
|------|-------------|
| `BufferSize` | Size of the output buffer in bytes, default `DefaultBufferSize` (32000). Published in `TpFIBControlAndQueryService`. |
| `OutputBuffer`, `OutputBufferOption` | The buffer and a `ByLine` or `ByChunk` flag. |
| `ServiceQueryParams`, `InternalServiceQuery` | Set the query items and run `isc_service_query`. |
| `CheckActive`, `CheckInactive` | Raise when not attached, or attached. |
| `Login` | The login step described above. |

## TpFIBServerProperties

Reads information about the server through service queries.

| | |
|---|---|
| Inherits from | `TpFIBCustomService` |

### Published properties

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `Options` | `TPropertyOptions` | | Which groups `Fetch` reads: `Database`, `License`, `LicenseMask`, `ConfigParameters`, `Version`. |

### Run-time properties

Filled by the `Fetch...` methods.

| Name | Type | Description |
|------|------|-------------|
| `DatabaseInfo` | `TDatabaseInfo` | `NoOfAttachments`, `NoOfDatabases`, and `DbName`, an array of the attached database names. |
| `LicenseInfo` | `TLicenseInfo` | `Key`, `Id`, and `Desc` arrays, and `LicensedUsers`. |
| `LicenseMaskInfo` | `TLicenseMaskInfo` | `LicenseMask` and `CapabilityMask`. |
| `VersionInfo` | `TVersionInfo` | `ServerVersion`, `ServerImplementation`, and `ServiceVersion`. |
| `ConfigParams` | `TConfigParams` | `BaseLocation`, `LockFileLocation`, `MessageFileLocation`, `SecurityDatabaseLocation`, and `ConfigFileData` with the `ConfigFileKey` and `ConfigFileValue` arrays. |

### Methods

| Name | Description |
|------|-------------|
| `Fetch` | Run the `Fetch...` method for each group in `Options`. |
| `FetchDatabaseInfo`, `FetchLicenseInfo`, `FetchLicenseMaskInfo`, `FetchConfigParams`, `FetchVersionInfo` | Read one group into the matching property. |

An unexpected reply raises `feOutputParsingError`.

## TpFIBControlService

Base class of services that start an action on the server.

| | |
|---|---|
| Inherits from | `TpFIBCustomService` |

| Name | Type | Description |
|------|------|-------------|
| `ServiceStart` | method | Build the start parameters from the properties and start the action. Raises when not attached. Virtual. |
| `IsServiceRunning` | `Boolean` | `True` while the server still runs the action. Queries the server on each read. |

Descendants override the protected `SetServiceStartOptions`, which fills `ServiceStartParams` (`ServiceStartAddParam` appends one item), and call `InternalServiceStart`. An empty start parameter list raises `feStartParamsError`.

## TpFIBControlAndQueryService

Base class of services that return text, such as backup, restore, statistics, and the log.

| | |
|---|---|
| Inherits from | `TpFIBControlService` |

### Published properties

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `BufferSize` | `Integer` | `32000` | Size of the output buffer in bytes. |

### Run-time properties and methods

| Name | Type | Description |
|------|------|-------------|
| `Eof` | `Boolean` | `True` when all output is read. Reset by each start. |
| `GetNextLine` | `String` | Next output line. Returns an empty string and sets `Eof` when there is no more output. |
| `GetNextChunk` | `String` | Next block of output. Sets `Eof` when the server reports the end. |
| `GetNextBuf` | `AnsiString` | Like `GetNextChunk`, but returns the bytes as read, without cutting at a zero byte. |
| `ServiceStart` | method | Starts the action. When `OnTextNotify` is assigned, it then reads all output and calls the event for each line before returning. |

Calling `GetNextLine`, `GetNextChunk`, or `GetNextBuf` before an action was started raises `feQueryParamsError`.

### Events

`OnTextNotify` is protected in this class. The descendants named below publish it.

| Name | Description |
|------|-------------|
| `OnTextNotify` | `procedure(Sender: TObject; const Text: string) of object`. One call for each output line during `ServiceStart`, followed by one call with an empty string at the end of the output. |

## TpFIBConfigService

Changes database properties. There is no `ServiceStart` for this class; it raises `feUseSpecificProcedures`. Each method below starts one action on `DatabaseName`.

| | |
|---|---|
| Inherits from | `TpFIBControlService` |

### Published properties

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `DatabaseName` | `string` | | Database the actions apply to, as the server sees the path. |

### Methods

| Name | Description |
|------|-------------|
| `ShutdownDatabase(Options, Wait)` | Shut the database down. `Options` is a `TShutdownMode`: `Forced`, `DenyTransaction`, or `DenyAttachment`. `Wait` is sent with the shutdown request. |
| `BringDatabaseOnline` | Bring a shut-down database online. |
| `ActivateShadow` | Activate the database shadow. |
| `SetSweepInterval(Value)` | Set the sweep interval. |
| `SetDBSqlDialect(Value)` | Set the database SQL dialect. |
| `SetPageBuffers(Value)` | Set the default number of page buffers. |
| `SetReserveSpace(Value)` | `True` reserves space on each page for record versions; `False` uses all space. |
| `SetAsyncMode(Value)` | `True` sets asynchronous write mode; `False` sets synchronous. |
| `SetReadOnly(Value)` | `True` sets read-only access mode; `False` sets read-write. |

## TpFIBLicensingService

Adds or removes a license key. For servers that use license keys.

| | |
|---|---|
| Inherits from | `TpFIBControlService` |

### Published properties

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `Action` | `TLicensingAction` | `LicenseAdd` | `LicenseAdd` or `LicenseRemove`. Setting `LicenseRemove` clears `Id`. |
| `Key` | `String` | | License key. |
| `Id` | `String` | | License ID. Sent only when adding. |

### Methods

| Name | Description |
|------|-------------|
| `AddLicense` | Set `Action` to `LicenseAdd` and start. |
| `RemoveLicense` | Set `Action` to `LicenseRemove` and start. |

## TpFIBLogService

Reads the server log. Call `ServiceStart`, then read the lines.

| | |
|---|---|
| Inherits from | `TpFIBControlAndQueryService` |

### Published properties

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `OnTextNotify` | `TServiceGetTextNotify` | | See [TpFIBControlAndQueryService](#tpfibcontrolandqueryservice). |

## TpFIBStatisticalService

Returns database statistics as text.

| | |
|---|---|
| Inherits from | `TpFIBControlAndQueryService` |

### Published properties

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `DatabaseName` | `string` | | Database to analyze. Required; `ServiceStart` raises `feStartParamsError` when empty. |
| `Options` | `TStatOptions` | | What to report, see below. |
| `TableNames` | `String` | | Table names, sent only when `StatTables` is in `Options`. |
| `OnTextNotify` | `TServiceGetTextNotify` | | See [TpFIBControlAndQueryService](#tpfibcontrolandqueryservice). |

`TStatOption` values and the server flag each one sets:

| Value | Flag |
|-------|------|
| `DataPages` | `isc_spb_sts_data_pages` |
| `DbLog` | `isc_spb_sts_db_log` |
| `HeaderPages` | `isc_spb_sts_hdr_pages` |
| `IndexPages` | `isc_spb_sts_idx_pages` |
| `SystemRelations` | `isc_spb_sts_sys_relations` |
| `RecordVersions` | `isc_spb_sts_record_versions` |
| `StatTables` | `isc_spb_sts_table` |

## TpFIBBackupService

Backs up a database with the server's backup service.

| | |
|---|---|
| Inherits from | `TpFIBBackupRestoreService` |

### Published properties

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `DatabaseName` | `string` | | Database to back up. Required; `ServiceStart` raises `feStartParamsError` when empty. |
| `BackupFile` | `TStrings` | | Backup files, one per line. A line is a file name. A line `name=length` also sends a file length, but the code reads only as many characters of the length as the file name has, so use it only with names at least as long as the number. Empty lines are skipped. |
| `BlockingFactor` | `Integer` | | Blocking factor. Sent only when greater than `0`. |
| `Options` | `TBackupOptions` | | Backup flags, see below. |
| `Verbose` | `Boolean` | `False` | Ask the server to list each step in the output. |
| `OnTextNotify` | `TServiceGetTextNotify` | | See [TpFIBControlAndQueryService](#tpfibcontrolandqueryservice). |

`TBackupOption` values and the server flag each one sets:

| Value | Flag |
|-------|------|
| `IgnoreChecksums` | `isc_spb_bkp_ignore_checksums` |
| `IgnoreLimbo` | `isc_spb_bkp_ignore_limbo` |
| `MetadataOnly` | `isc_spb_bkp_metadata_only` |
| `NoGarbageCollection` | `isc_spb_bkp_no_garbage_collect` |
| `OldMetadataDesc` | `isc_spb_bkp_old_descriptions` |
| `NonTransportable` | `isc_spb_bkp_non_transportable` |
| `ConvertExtTables` | `isc_spb_bkp_convert` |

## TpFIBRestoreService

Restores a database from a backup with the server's restore service.

| | |
|---|---|
| Inherits from | `TpFIBBackupRestoreService` |

### Published properties

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `BackupFile` | `TStrings` | | Backup files to read, one per line, as in [TpFIBBackupService](#tpfibbackupservice). |
| `DatabaseName` | `TStrings` | | Database files to create, one per line: a file name, or `name=length`. Empty lines are skipped. |
| `PageSize` | `Integer` | `4096` | Page size of the new database. Sent only when greater than `0`. |
| `PageBuffers` | `Integer` | | Page buffers. Sent only when greater than `0`. |
| `FixCharset` | `AnsiString` | | Character set name for `FixFssMetadata` and `FixFssData`. Both flags are sent only when this is not empty. |
| `Options` | `TRestoreOptions` | `[CreateNewDB]` | Restore flags, see below. |
| `Verbose` | `Boolean` | `False` | Ask the server to list each step in the output. |
| `OnTextNotify` | `TServiceGetTextNotify` | | See [TpFIBControlAndQueryService](#tpfibcontrolandqueryservice). |

`TRestoreOption` values and the server flag each one sets:

| Value | Flag |
|-------|------|
| `DeactivateIndexes` | `isc_spb_res_deactivate_idx` |
| `NoShadow` | `isc_spb_res_no_shadow` |
| `NoValidityCheck` | `isc_spb_res_no_validity` |
| `OneRelationAtATime` | `isc_spb_res_one_at_a_time` |
| `Replace` | `isc_spb_res_replace` |
| `CreateNewDB` | `isc_spb_res_create` |
| `UseAllSpace` | `isc_spb_res_use_all_space` |
| `ValidationCheck` | `isc_spb_res_validate` |
| `OnlyMetadata` | `isc_spb_bkp_metadata_only` |
| `FixFssMetadata` | `isc_spb_res_fix_fss_metadata`, with `FixCharset` |
| `FixFssData` | `isc_spb_res_fix_fss_data`, with `FixCharset` |

## TpFIBNBackupService

Incremental backup. The source comment marks this class as *Firebird 2.5 only*; this was not checked against newer servers.

| | |
|---|---|
| Inherits from | `TpFIBControlAndQueryService` |

### Published properties

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `DatabaseName` | `String` | | Database to back up. |
| `BackupFile` | `string` | | Backup file. Both names are required; `ServiceStart` raises `feStartParamsError` when either is empty. |
| `Level` | `Integer` | `0` | Backup level. |

### Methods

| Name | Description |
|------|-------------|
| `BackUp(DbName, BackupName, aLevel)` | Set the three properties, attach, start, and detach again. |

## TpFIBNRestoreService

Restores a database from incremental backup files. The source comment marks this class as *Firebird 2.5 only*; this was not checked against newer servers.

| | |
|---|---|
| Inherits from | `TpFIBControlAndQueryService` |

### Published properties

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `DatabaseName` | `String` | | Database to create. |
| `BackupFiles` | `TStrings` | | Backup files, one per line. Empty lines are skipped. `ServiceStart` raises `feStartParamsError` when this list or `DatabaseName` is empty. |

### Methods

| Name | Description |
|------|-------------|
| `Restore(aBackUpFiles, DbName)` | Set `DatabaseName` and `BackupFiles`, attach, start, and detach again. Do not use it: its loop runs one element past the end of `aBackUpFiles`. Set `DatabaseName` and `BackupFiles` and call `ServiceStart` instead. |

## TpFIBValidationService

Validates and repairs a database, sweeps it, and lists or resolves limbo transactions.

| | |
|---|---|
| Inherits from | `TpFIBControlAndQueryService` |

### Published properties

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `DatabaseName` | `string` | | Database to check. Required; `ServiceStart` raises `feStartParamsError` when empty. |
| `Options` | `TValidateOptions` | | Validation flags, see below. |
| `GlobalAction` | `TTransactionGlobalAction` | | How `FixLimboTransactionErrors` treats the listed transactions: `CommitGlobal`, `RollbackGlobal`, `RecoverTwoPhaseGlobal`, or `NoGlobalAction`. |
| `OnTextNotify` | `TServiceGetTextNotify` | | See [TpFIBControlAndQueryService](#tpfibcontrolandqueryservice). |

`TValidateOption` values and the server flag each one sets:

| Value | Flag |
|-------|------|
| `SweepDB` | `isc_spb_rpr_sweep_db` |
| `ValidateDB` | `isc_spb_rpr_validate_db` |
| `LimboTransactions` | `isc_spb_rpr_list_limbo_trans` |
| `CheckDB` | `isc_spb_rpr_check_db` |
| `IgnoreChecksum` | `isc_spb_rpr_ignore_checksum` |
| `KillShadows` | `isc_spb_rpr_kill_shadows` |
| `MendDB` | `isc_spb_rpr_mend_db` |
| `ValidateFull` | `isc_spb_rpr_full`; also `isc_spb_rpr_validate_db` when `MendDB` is not set |

### Run-time properties and methods

| Name | Type | Description |
|------|------|-------------|
| `LimboTransactionInfo[Index]` | `TLimboTransactionInfo` | One limbo transaction. `nil` when `Index` is past the end. |
| `LimboTransactionInfoCount` | `Integer` | Number of entries read by `FetchLimboTransactionInfo`; `-1` when none were read. |
| `FetchLimboTransactionInfo` | method | Read the limbo transactions from the server. |
| `FixLimboTransactionErrors` | method | Start a repair that commits or rolls back the listed transactions. With `NoGlobalAction`, each entry uses its own `Action`. With `CommitGlobal`, all are committed; with any other value, all are rolled back. After `FetchLimboTransactionInfo` returned entries, the loop reads one nil entry past the last one and fails with an access violation; do not call it after a fetch. |

`TLimboTransactionInfo` fields: `MultiDatabase`, `Id`, `HostSite`, `RemoteSite`, `RemoteDatabasePath`, `State` (`LimboState`, `CommitState`, `RollbackState`, `UnknownState`), `Advise` (`CommitAdvise`, `RollbackAdvise`, `UnknownAdvise`), and `Action` (`CommitAction`, `RollbackAction`). `HostSite`, `RemoteSite`, `RemoteDatabasePath`, `State`, and `Advise` are filled only for multi-database transactions. Without an advice, `Action` is `CommitAction`.

## TpFIBSecurityService

Manages users in the security database.

| | |
|---|---|
| Inherits from | `TpFIBControlAndQueryService` |

```delphi
Security.Active := True;
try
  Security.UserName := 'REPORTER';
  Security.Password := 'secret';
  Security.FirstName := 'Report';
  Security.AddUser;
  Security.DisplayUsers;
  for I := 0 to Security.UserInfoCount - 1 do
    Writeln(Security.UserInfo[I].UserName);
finally
  Security.Active := False;
end;
```

`Security` is a `TpFIBSecurityService` with its connection parameters set as in the first example, and `I` is an `Integer`. This sample was not run against a server.

### Published properties

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `SecurityAction` | `TSecurityAction` | | `ActionAddUser`, `ActionDeleteUser`, `ActionModifyUser`, or `ActionDisplayUser`. The methods below set it. Setting `ActionDeleteUser` clears `FirstName`, `MiddleName`, `LastName`, `UserID`, `GroupID`, and `Password`. |
| `UserName` | `string` | | User to add, delete, or modify. Required for those actions. A name with a space is rejected when adding. |
| `SQlRole` | `string` | | SQL role sent with the action. Also the role for `DisplayUsers`. |
| `FirstName`, `MiddleName`, `LastName` | `string` | | Name parts. |
| `UserID`, `GroupID` | `Integer` | | Numeric user and group IDs. |
| `Password` | `string` | | Password. |
| `SecAdmin` | `Boolean` | `False` | Marks the user as a security administrator. |

Text values are sent UTF-8 encoded. When modifying, only the properties set since the last action are sent. `UserID` and `GroupID` are always sent when adding. When `ServiceStart` runs (also through `AddUser`, `ModifyUser`, and `DeleteUser`), and when the component finishes loading, `FirstName`, `MiddleName`, `LastName`, `UserID`, `GroupID`, and `Password` are cleared; `UserName`, `SQlRole`, and `SecAdmin` are kept.

### Run-time properties and methods

| Name | Type | Description |
|------|------|-------------|
| `AddUser` | method | Add the user described by the properties. |
| `ModifyUser` | method | Change the properties set since the last action on the user `UserName`. |
| `DeleteUser` | method | Delete the user `UserName`. |
| `DisplayUsers` | method | Read all users into `UserInfo`. Uses `SQlRole`. |
| `DisplayUser(UserName)` | method | Read one user into `UserInfo`. |
| `UserInfo[Index]` | `TUserInfo` | One user: `UserName`, `FirstName`, `MiddleName`, `LastName`, `GroupID`, `UserID`. `nil` when `Index` is past the end. |
| `UserInfoCount` | `Integer` | Number of users read; `-1` when none were read. |

## Install API header

`IB_InstallHeader` declares the types and constants of the InterBase install library (`ibinstall.dll`): option handles, the `isc_install_...` and `isc_uninstall_...` function types, component numbers, and error codes. It has no components and no code of its own, and the service components do not use it. `IB_Intf` and `IB_Install` use it.

## See also

- [TFIBSQLMonitor](TFIBSQLMonitor.md)
- [TFIBDatabase](TFIBDatabase.md)
