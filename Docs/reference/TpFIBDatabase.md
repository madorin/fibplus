# TpFIBDatabase

The database component to use in applications. It adds to [TFIBDatabase](TFIBDatabase.md) connection aliases, handling of a lost connection, a schema cache file, connect and transaction events, and helpers to list the queries and datasets that use the connection. This page describes only the additions; for everything else see `TFIBDatabase`.

| | |
|---|---|
| Unit | `pFIBDatabase` |
| Inherits from | `TFIBDatabase` |

The sample uses the components `Database` (`TpFIBDatabase`) and `Transaction` (`TpFIBTransaction`). It waits 10 seconds between attempts to restore a lost connection.

```delphi
procedure TMainForm.DatabaseLostConnect(Database: TFIBDatabase; E: EFIBError;
  var Actions: TOnLostConnectActions; var DoRaise: Boolean);
begin
  Actions := laWaitRestore;
  DoRaise := False;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Database.WaitForRestoreConnect := 10000;
  Database.OnLostConnect := DatabaseLostConnect;
  Database.Connected := True;
end;
```

Guides: [Connections](../guide/connections.md), [Events and monitoring](../guide/events-and-monitoring.md), [Transactions](../guide/transactions.md).

## Published properties

Only the properties that `TpFIBDatabase` adds. The published properties of `TFIBDatabase` are listed on its page.

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `AliasName` | `AnsiString` | | Name of a connection alias. Setting a non-empty name reads the alias, see [Aliases](#aliases). Raises while connected, except while the form loads. |
| `CacheSchemaOptions` | `TCacheSchemaOptions` | | Loading and saving of the schema cache file, see [Schema cache](#schema-cache). |
| `SaveAliasParamsAfterConnect` | `Boolean` | `True` | After a successful `Open`, write the connection parameters to the alias, if `AliasName` is not empty. |
| `WaitForRestoreConnect` | `Cardinal` | `30000` | Interval in milliseconds of the timer that tries to restore a lost connection, see [Lost connection](#lost-connection). The timer is created when the first wait starts. `0` turns the restore timer off and stops a wait in progress. Forms saved by versions before 7.9.1 without a value set in the Object Inspector store `WaitForRestoreConnect = 0`, which keeps the timer off; remove the line to use the default. |
| `About` | `string` | | Library version text. Read-only in effect: writing is ignored and the value is not stored. |

Events are listed in [Events](#events).

## Types

| Type | Definition |
|------|------------|
| `TOnLostConnectActions` | `laTerminateApp`, `laCloseConnect`, `laIgnore`, `laWaitRestore`: what to do about a lost connection, see [Lost connection](#lost-connection). |
| `TFIBLoginEvent` | `procedure(Database: TFIBDatabase; LoginParams: TStrings; var DoConnect: Boolean) of object` |
| `TFIBLostConnectEvent` | `procedure(Database: TFIBDatabase; E: EFIBError; var Actions: TOnLostConnectActions; var DoRaise: Boolean) of object` |
| `TFIBRestoreConnectEvent` | `procedure(Database: TFIBDatabase) of object` |
| `TpFIBAcceptCacheSchema` | `procedure(const ObjName: string; var Accept: Boolean) of object` |

## Aliases

An alias keeps `DBName`, the user name, the character set, the role, and the SQL dialect under a name, so that several applications can share them. The alias is stored in the Windows registry under `HKEY_CURRENT_USER\Software\FIBC_Software\Aliases\<AliasName>`. Without registry support in the build (`NO_REGISTRY`), aliases do nothing.

| Registry value | Property |
|----------------|----------|
| `Database Name` | `DBName` |
| `user_name` | `ConnectParams.UserName` |
| `lc_ctype` | `ConnectParams.CharSet` |
| `sql_role_name` | `ConnectParams.RoleName` |
| `SQL_DIALECT` | `SQLDialect` |
| `CLIENT_LIB` | `LibraryName` |

The password is not stored.

## Schema cache

`CacheSchemaOptions` controls a file that keeps table, dataset, and error message information between runs, so that the application does not read the metadata again. The additional files use the same name with the extensions `.dt` and `.err`.

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `LocalCacheFile` | `string` | | Path of the cache file. |
| `AutoLoadFromFile` | `Boolean` | `False` | After connecting, load the cache from `LocalCacheFile` when the file exists. Not done at design time. |
| `AutoSaveToFile` | `Boolean` | `False` | Save the cache to `LocalCacheFile` before the connection closes. Not done at design time, nor when the database is not connected. |
| `ValidateAfterLoad` | `Boolean` | `True` | Check loaded entries against the server before use. |

`OnAcceptCacheSchema` replaces the built-in check of table entries after loading. It runs once per cached table of this database, with `ObjName` set to the table name. An entry stays in the cache only when the handler sets `Accept` to `True`; `Accept` is `False` on entry, so a handler that does nothing drops every entry. The event is used only when `AutoLoadFromFile` and `ValidateAfterLoad` are `True`. When the handler is used, the cache is saved to the file again after the check.

## Lost connection

When the server drops the attachment (network failure, server shutdown), `TpFIBDatabase` can close the connection without calling the server, raise an event, and try to connect again. The event `OnLostConnect` is called by:

- `TpFibErrorHandler`, when it recognizes a lost connection and its `oeLostConnect` option is set (the default);
- `ExTestConnected`.

`TpFibErrorHandler` passes `laCloseConnect` as the initial `Actions`; `ExTestConnected` passes the value of its parameter. When the handler cannot tell which database is affected, it calls `OnLostConnect` of every `TpFIBDatabase` in the application. In `OnLostConnect` the handler chooses `Actions`; the component then acts on the value after the event returns:

| Action | Effect |
|--------|--------|
| `laCloseConnect` | Close the connection without calling the server: the handle is dropped, queries and datasets are told that the connection is lost, and active transactions end as a rollback without a server call. |
| `laWaitRestore` | As `laCloseConnect`, then start the restore timer. |
| `laTerminateApp` | As `laCloseConnect`, then terminate the application. |
| `laIgnore` | Do nothing. |

`ExTestConnected` raises the error again when the handler sets `DoRaise` to `True`; it starts as `False` there. With `WaitForRestoreConnect` set to `0`, `laWaitRestore` does no more than `laCloseConnect`.

Each timer tick calls `RestoreConnect`: it stops the timer, sets `Connected` to `True`, and calls `AfterRestoreConnect`. A successful `Open` also stops the timer. When connecting fails with an `EFIBError`, `OnErrorRestoreConnect` is called. `Actions` starts as `laWaitRestore` when the timer was running, else as `laIgnore`. Set it to `laWaitRestore` to wait for another interval or to `laTerminateApp` to terminate; any other value stops the attempts. `DoRaise` starts as `False` and is not used.

## Run-time properties

| Name | Type | Description |
|------|------|-------------|
| `FIBDataSets[Index]` | `TFIBCustomDataSet` | Dataset that uses this database, by index. Each dataset is counted once. |
| `FIBQueries[Index]` | `TFIBQuery` | Query that uses this database and does not belong to a dataset, by index. |
| `InRestoreConnect` | `Boolean` | `True` while the restore timer waits and during a `RestoreConnect` attempt. Cleared by `StopWaitRestoreConnect` and when the attempt ends, unless `OnErrorRestoreConnect` chose `laWaitRestore`. |
| `SaveDBParams` | `Boolean` | The same as `SaveAliasParamsAfterConnect`. Forms saved by older versions store this name; they still load. |

## Methods

### Connecting

| Name | Description |
|------|-------------|
| `Open(RaiseExcept)` | Calls `BeforeConnect`; if the handler sets `DoConnect` to `False`, returns without connecting. Then connects as `TFIBDatabase.Open` does and, once connected, loads the schema cache and saves the alias, as described above. Does nothing when already connected. |
| `ReadParamsFromAlias` | Read the alias into the properties. Returns `False` when the alias or its `Database Name` value does not exist. Virtual. Called when `AliasName` is set. |
| `SaveAlias` | Write the connection parameters to the alias. Override of the empty method of `TFIBDatabase`. The procedure `WriteDBParamsToAlias(Database)` of the unit does the same. |

### Lost connection

| Name | Description |
|------|-------------|
| `ExTestConnected(Actions)` | Read the base level from the server. Returns `False` when the database is not connected or the call fails. On failure `OnLostConnect` runs, and the error is raised again if the handler sets `DoRaise` to `True`. |
| `WaitRestoreConnect` | Start the restore timer, creating it on first use. Does nothing when `WaitForRestoreConnect` is `0`. |
| `StopWaitRestoreConnect` | Stop the restore timer. |
| `RestoreConnect(Sender)` | Try to connect now. This is the timer handler and can also be called directly. When connected, only stops the restore timer. |
| `ForceCloseTransactions` | End every transaction of this database with its `TimeoutAction`, forced, ignoring errors. See `TFIBTransaction.OnDatabaseDisconnecting`. |

### Datasets and queries

| Name | Description |
|------|-------------|
| `CloseDataSets` | Close every `TFIBDataSet` that uses this database. |
| `FIBDataSetsCount`, `FIBQueryCount` | Number of entries of `FIBDataSets` and `FIBQueries`. |
| `ApplyUpdates(DataSets)` | Apply cached updates of several datasets in one transaction. Each dataset must be a `TFIBCustomDataSet` that uses this database and the same update transaction (`TFIBCustomDataSet.UpdateTransaction`), else an error is raised. An empty array does nothing. The method calls `ApplyUpdToBase` of each `TpFIBDataSet`, then commits the update transaction (`CommitRetaining` when its `TimeoutAction` is `TACommitRetaining`, else `Commit`), then calls `CommitUpdToCach` on the datasets that are open. |

### Metadata

| Name | Description |
|------|-------------|
| `GetTableNames(TableNames, WithSystem)` | Fill the list with the table names of the database. System tables are included only when `WithSystem` is `True`. Views are not listed. Needs an active connection (`CheckActive`). |
| `GetFieldNames(TableName, FieldNames, WithComputedFields)` | Fill the list with the column names of a table, in field order. Computed columns are left out when `WithComputedFields` is `False`; the default is `True`. In SQL dialect 1 the table name is converted to upper case. |

Both methods read the system tables in the internal transaction of the database and commit it.

## Protected

For descendant authors.

| Name | Description |
|------|-------------|
| `InternalClose(Force, DBinShutDown)` | Override. Does nothing when the database is not connected. Saves the schema cache when `AutoSaveToFile` is set, then closes as `TFIBDatabase` does. |
| `DoOnLostConnect(Database, E, Actions, DoRaise)` | Dynamic. Calls `OnLostConnect` and then acts on `Actions`. |
| `DoOnErrorRestoreConnect(Database, E, Actions)` | Dynamic. Calls `OnErrorRestoreConnect` with `DoRaise` set to `False`; the value it returns is not used. |
| `DoAfterRestoreConnect` | Dynamic. Calls `AfterRestoreConnect`. |
| `CloseLostConnect` | Drop the handle and end the transactions without calling the server. Does nothing when not connected. |
| `CreateRestoreConnectTimer` | Create the restore timer, disabled, with the interval of `WaitForRestoreConnect`. Does nothing when it exists. |

## Events

| Name | Description |
|------|-------------|
| `BeforeConnect` | Before `Open` connects. `LoginParams` is `DBParams`; change it to adjust the connection, or set `DoConnect` to `False` to cancel. `OnLogin` is the same property under an old name and is not stored. |
| `AfterConnect` | After connecting. The same event as `TFIBDatabase.OnConnect`, but stored in the form. |
| `OnLostConnect` | A lost connection was detected. Choose `Actions` and `DoRaise`, see [Lost connection](#lost-connection). |
| `OnErrorRestoreConnect` | A restore attempt failed. Choose `Actions`. |
| `AfterRestoreConnect` | A restore attempt succeeded. |
| `BeforeStartTransaction` | A [TpFIBTransaction](TpFIBTransaction.md) whose `DefaultDatabase` is this database is about to start. `Sender` is the transaction. |
| `AfterStartTransaction` | After `StartTransaction` of the same transaction returned. Also runs when the start was skipped without an error (see `AutoReconnect` in [TFIBTransaction](TFIBTransaction.md#starting-and-ending)). |
| `BeforeEndTransaction` | A `TpFIBTransaction` of this database is about to end. `Action` and `Force` tell how. Runs before the check that the transaction is active. |
| `AfterEndTransaction` | The same transaction ended. |
| `OnAcceptCacheSchema` | A cached table entry is being validated, see [Schema cache](#schema-cache). |

The transaction events run for every `TpFIBTransaction` that has this database as `DefaultDatabase`, in addition to the events of the transaction itself. The database event runs first before a start or end and last after it, see [TpFIBTransaction](TpFIBTransaction.md#events).

## See also

- [TFIBDatabase](TFIBDatabase.md), [TFIBSession](TFIBSession.md)
- [TpFIBTransaction](TpFIBTransaction.md)
- [Connections](../guide/connections.md)
- [Events and monitoring](../guide/events-and-monitoring.md)
