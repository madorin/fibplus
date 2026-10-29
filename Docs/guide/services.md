# Services

The service components run administrative tasks on the server: back up and restore a database, make incremental backups, validate and sweep, change database properties, shut a database down and bring it online, manage users, and read the server log, statistics, and server information. They attach to the service manager of a server, not to a database, so they need no `TFIBDatabase`. This article shows the pattern that all of them share, how to read what the server returns and tell success from failure, and the common tasks.

For the members of each class see [FIBServices components](../reference/TFIBServices.md).

The samples use one component of each class, attached as shown in [Attach to the service manager](#attach-to-the-service-manager): `Backup` (`TFIBBackupService`), `Restore` (`TFIBRestoreService`), `NBackup` (`TFIBNBackupService`), `NRestore` (`TFIBNRestoreService`), `Validation` (`TFIBValidationService`), `Config` (`TFIBConfigService`), `Security` (`TFIBSecurityService`), `Props` (`TFIBServerProperties`), and `Stats` (`TFIBStatisticalService`). `Log` is a `TMemo`.

## Requirements

- The unit `FIBServices`. The components exist when `INC_SERVICE_SUPPORT` is defined, which `FIB.inc` does by default.
- A user that the server allows to run the task. The samples log in as `SYSDBA`.
- Parallel workers for backup, restore, and sweep need *Firebird 5+*.

The samples were run against Firebird 5. Backup, restore, the `stdout` backup, and the incremental backup were also run against Firebird 3 and 4.

## Attach to the service manager

Every service component works the same way: set the server and the login, attach, run the task, detach.

```delphi
Backup := TFIBBackupService.Create(nil);
try
  Backup.ServerName := 'dbserver';
  Backup.LoginPrompt := False;
  Backup.Params.Values['user_name'] := 'SYSDBA';
  Backup.Params.Values['password'] := 'masterkey';
  Backup.Active := True;
  // set the properties of the task and start it
  Backup.Active := False;
finally
  Backup.Free;
end;
```

`Backup` is a `TFIBBackupService`. `Active := True` calls `Attach`, `Active := False` calls `Detach`. `Free` detaches a component that is still attached.

- `ServerName` is the host, with an optional port: `dbserver/3051`. Setting it changes `Protocol` from `Local` to `TCP`.
- An empty `ServerName` means `Protocol` `Local`. With a client library that includes the embedded engine, the tasks run in your process on local database files; see [Embedded engine](#embedded-engine).
- The login goes into `Params` as `name=value` lines. Only a few names are allowed; see [Params](../reference/TFIBServices.md#params).
- `LoginPrompt` is `True` by default. `Attach` then shows the login dialog, which needs a dialog unit in the project (see [The login dialog](connections.md#the-login-dialog)); without one, `Attach` raises. Set `LoginPrompt := False` when the login is in `Params`.

`ServerName`, `Protocol`, `LibraryName`, and `Params` cannot change while the component is attached.

## Run a task and read its output

`TFIBConfigService` has one method for each change, and the method runs it at once. The other components start their task with `ServiceStart`. The server runs the task on its own; `ServiceStart` returns when the task has started.

Most tasks return text, one line at a time. Read it with `GetNextLine` until `Eof`:

```delphi
Backup.ServiceStart;
while not Backup.Eof do
begin
  Line := Backup.GetNextLine;
  if not Backup.Eof then
    Log.Lines.Add(Line);
end;
```

`Line` is a `string`. The last call returns an empty string and sets `Eof`. Reading to the end is also the way to wait for the task: after `Eof`, `IsServiceRunning` is `False`.

With `OnTextNotify` assigned, `ServiceStart` reads all lines itself and calls the event for each one, then once more with an empty string. It returns when the task is done.

| Task | Output |
|------|--------|
| Backup | Nothing. With `Verbose`, one line for each step. |
| Restore | Warnings only, for example a smaller page size. With `Verbose`, one line for each step. |
| Validation, sweep | Nothing when nothing is wrong |
| Incremental backup | The time and the page counts |
| Statistics, server log | The text of the report or the log |

## Success and failure

An error raises `EFIBInterBaseError`. Errors that the server finds at the start come from `ServiceStart`: a missing database, a backup file that cannot be created, a database file that already exists. The error does not appear in the output text.

After a server error the component is no longer attached. Set `Active := True` again before the next task:

```delphi
try
  Restore.ServiceStart;
  while not Restore.Eof do
    Restore.GetNextLine;
except
  on E: EFIBInterBaseError do
  begin
    ShowMessage(E.Message);
    Restore.Active := True;
  end;
end;
```

A failure that the server does not report as an error is a backup file that ends too early. The restore stops after the last complete table and ends without an error. The new database stays shut down (single-user maintenance). To catch it, restore with `Verbose` and check that the output reaches the end:

```delphi
function RestoreCompleted(Restore: TFIBRestoreService): Boolean;
begin
  Result := False;
  Restore.Verbose := True;
  Restore.ServiceStart;
  while not Restore.Eof do
    if Pos('finishing, closing, and going home', Restore.GetNextLine) > 0 then
      Result := True;
end;
```

## Back up and restore

`TFIBBackupService` and `TFIBRestoreService` run the server's backup and restore. Paths are as the server sees them. The backup file is written on the server.

```delphi
Backup.DatabaseName := '/var/lib/firebird/data/sales.fdb';
Backup.BackupFile.Text := '/var/backup/sales.fbk';
Backup.ServiceStart;
while not Backup.Eof do
  Backup.GetNextLine;
```

```delphi
Restore.BackupFile.Text := '/var/backup/sales.fbk';
Restore.DatabaseName.Text := '/var/lib/firebird/data/sales_copy.fdb';
Restore.Options := [CreateNewDB, Replace];
Restore.ServiceStart;
while not Restore.Eof do
  Restore.GetNextLine;
```

- `Options` of a restore is `[CreateNewDB]` by default, so the restore fails when the database file exists. Add `Replace` to overwrite it.
- `PageSize` is `0` by default: the database keeps the page size of the backup, as with gbak without `-page`. Set a size to change it.
- A backup in several files, or a database in several files, has one `name=length` line for each file.
- The backup and restore options are in [TFIBBackupService](../reference/TFIBServices.md#tfibbackupservice) and [TFIBRestoreService](../reference/TFIBServices.md#tfibrestoreservice). `ParallelWorkers` (*Firebird 5+*) runs the task with several threads.

### A backup on the client machine

The database must be on the server that runs the service. *Firebird 3+* refuses a `DatabaseName` that points to another server (`unavailable database`), also when the service runs in the embedded engine. So you cannot attach the service to your own machine and back up a remote database to a local file.

Ask the server to send the backup instead: set `BackupFile` to `stdout` and read the data with `GetNextBuf`.

```delphi
Backup.DatabaseName := '/var/lib/firebird/data/sales.fdb';
Backup.BackupFile.Text := 'stdout';
Backup.Verbose := False;
Backup.ServiceStart;
Stream := TFileStream.Create('C:\Backup\Sales.fbk', fmCreate);
try
  while not Backup.Eof do
  begin
    Data := Backup.GetNextBuf;
    if Data <> '' then
      Stream.WriteBuffer(Data[1], Length(Data));
  end;
finally
  Stream.Free;
end;
```

`Stream` is a `TFileStream` and `Data` an `AnsiString`. `GetNextBuf` keeps zero bytes, which `GetNextLine` and `GetNextChunk` would cut. The server refuses `stdout` together with `Verbose` or with more than one backup file. FIBPlus cannot send a local file to the server for a restore; copy the file to the server first, or restore it locally with the embedded engine.

### Embedded engine

With the embedded engine, leave `ServerName` empty and use local paths. The services then work on local files, without a server.

```delphi
Restore.Protocol := Local;
Restore.BackupFile.Text := 'C:\Backup\Sales.fbk';
Restore.DatabaseName.Text := 'C:\Data\Sales.fdb';
```

## Incremental backup

`TFIBNBackupService` runs nbackup on the server. Level 0 copies the whole database. Each higher level copies the pages changed since the last backup of the level below. `TFIBNRestoreService` builds a database from the files of all levels, in order.

```delphi
NBackup.BackUp('/var/lib/firebird/data/sales.fdb', '/var/backup/sales.nbk0', 0);
// later
NBackup.BackUp('/var/lib/firebird/data/sales.fdb', '/var/backup/sales.nbk1', 1);

NRestore.Restore(['/var/backup/sales.nbk0', '/var/backup/sales.nbk1'],
  '/var/lib/firebird/data/sales_nbk.fdb');
```

`TFIBNRestoreService` creates a new database file and raises when the file exists. `BackUp` and `Restore` attach, start the task, and detach; set the server and the login before. They do not read the output. To read it, set `DatabaseName`, `BackupFile`, and `Level`, and use `ServiceStart` and `GetNextLine` as for the other services.

## Validate and sweep

`TFIBValidationService` checks the database structure (`ValidateDB`, `ValidateFull`) or runs a sweep (`SweepDB`). The other options are in [TFIBValidationService](../reference/TFIBServices.md#tfibvalidationservice).

```delphi
Validation.DatabaseName := '/var/lib/firebird/data/sales.fdb';
Validation.Options := [ValidateDB];
try
  Validation.ServiceStart;
  while not Validation.Eof do
    Validation.GetNextLine;
  ShowMessage('No errors found.');
except
  on E: EFIBInterBaseError do
    ShowMessage(E.Message);
end;
```

- A database without errors gives no output.
- When validation finds errors, it raises. The message has the summary, for example `Summary of validation errors` and the number of errors of each kind. The details, with page numbers and table names, go to the server log; read them with [TFIBLogService](#server-log-and-statistics).
- Validation needs the database for itself. While another connection is open, it raises `Secondary server attachments cannot validate databases`. Shut the database down first, see [Shut down and bring online](#shut-down-and-bring-online).

`FetchLimboTransactionInfo` and `FixLimboTransactionErrors` list and resolve the limbo transactions of a two-phase commit.

## Change database properties

`TFIBConfigService` changes one property of `DatabaseName` with each method. `ServiceStart` is not used and raises.

| Change | Method |
|--------|--------|
| Sweep interval | `SetSweepInterval` |
| Page buffers stored in the database | `SetPageBuffers` |
| Forced writes on (`False`) or off (`True`) | `SetAsyncMode` |
| Read-only or read-write | `SetReadOnly` |
| Space reserved on each page for record versions | `SetReserveSpace` |
| SQL dialect | `SetDBSqlDialect` |
| Activate the shadow of the database | `ActivateShadow` |

```delphi
Config.DatabaseName := '/var/lib/firebird/data/sales.fdb';
Config.SetSweepInterval(20000);
Config.SetPageBuffers(4096);
Config.SetAsyncMode(False);
```

### Shut down and bring online

`ShutdownDatabase(Mode, Wait)` shuts the database down, `BringDatabaseOnline` brings it back to normal. `SYSDBA` can still connect to a shut-down database; other users get `Database ... shutdown`. Every mode leaves the database in the state that the header calls *multi-user maintenance*.

| Mode | Effect |
|------|--------|
| `Forced` | Shuts down and closes the open connections |
| `DenyTransaction` | Waits up to `Wait` seconds for the active transactions to end, then shuts down and closes the open connections |
| `DenyAttachment` | Waits up to `Wait` seconds for the other connections to close, then shuts down |

When something is still active after `Wait` seconds, `DenyTransaction` and `DenyAttachment` raise `Database shutdown unsuccessful`, and the database stays online.

```delphi
Config.DatabaseName := '/var/lib/firebird/data/sales.fdb';
Config.ShutdownDatabase(Forced, 0);
try
  // exclusive work, for example a validation
finally
  Config.BringDatabaseOnline;
end;
```

`BringDatabaseOnline` on a database that is online raises. Firebird also has a single-user and a full shutdown; `TFIBConfigService` cannot request them.

## Manage users

`TFIBSecurityService` adds, changes, deletes, and lists the users of the server.

```delphi
Security.UserName := 'REPORTER';
Security.Password := 'secret';
Security.FirstName := 'Report';
Security.AddUser;

Security.UserName := 'REPORTER';
Security.Password := 'new secret';
Security.ModifyUser;

Security.DisplayUser('REPORTER');
if Security.UserInfoCount = 1 then
  ShowMessage(Security.UserInfo[0].FirstName);

Security.UserName := 'REPORTER';
Security.DeleteUser;
```

- `AddUser`, `ModifyUser`, and `DeleteUser` need `UserName`. `ModifyUser` sends only the properties set since the last action. After a successful action the properties other than `UserName` and `SQlRole` are cleared; see [TFIBSecurityService](../reference/TFIBServices.md#tfibsecurityservice).
- `DisplayUsers` reads all users, `DisplayUser` one user, into `UserInfo` and `UserInfoCount`. For an unknown user the count is `0`. The password is never returned.
- Users are managed by the default user manager of the server (`Srp` in a standard *Firebird 3+* installation). There is no property to choose another one; use the `CREATE USER` statement with `USING PLUGIN` for that.
- `SecAdmin := True` gives the user administrator rights in the security database. `SQlRole` does not grant a role to the user. Grant roles with SQL: `GRANT SALES TO REPORTER`.
- An action that fails, for example deleting a user that does not exist, raises and detaches the component.

## Server information, log, and statistics

### Server information

`TFIBServerProperties` reads information about the server with the `Fetch...` methods, or with `Fetch` for the groups in `Options`.

```delphi
Props.FetchVersionInfo;
ShowMessage(Props.VersionInfo.ServerVersion); // for example LI-V5.0.4.1812 Firebird 5.0
Props.FetchDatabaseInfo;
for I := 0 to Props.DatabaseInfo.NoOfDatabases - 1 do
  Log.Lines.Add(Props.DatabaseInfo.DbName[I]);
```

| Group | Method | Contents |
|-------|--------|----------|
| `Version` | `FetchVersionInfo` | Server version and implementation |
| `Database` | `FetchDatabaseInfo` | Number of connections, the databases in use |
| `ConfigParameters` | `FetchConfigParams` | Paths of the server: root, lock files, messages, security database |

`License` and `LicenseMask` are for InterBase. Firebird raises `Feature is not supported` for them, so leave them out of `Options`. *Firebird 5* returns no entries in `ConfigParams.ConfigFileData`.

### Server log and statistics

`TFIBLogService` returns the server log (`firebird.log`), one line at a time. `TFIBStatisticalService` returns the statistics of `DatabaseName`, the same text as `gstat`; `Options` chooses the parts, for example `[HeaderPages]` for the header page.

```delphi
Stats.DatabaseName := '/var/lib/firebird/data/sales.fdb';
Stats.Options := [HeaderPages];
Stats.ServiceStart;
while not Stats.Eof do
  Log.Lines.Add(Stats.GetNextLine);
```

## Errors and pitfalls

- **`Attach` raises "operation cancelled".** `LoginPrompt` is `True` and the project has no login dialog unit. Set `LoginPrompt := False` and put the login in `Params`.
- **The component is detached after an error.** Every server error detaches it. Set `Active := True` before the next task.
- **The task is not finished when `ServiceStart` returns.** Read the output until `Eof`, or assign `OnTextNotify`.
- **A truncated backup restores without an error.** The database stays shut down. Restore with `Verbose` and check the last lines; see [Success and failure](#success-and-failure).
- **The restored database has another page size than the original.** `PageSize` is not `0`. Set it to `0` to keep the page size of the backup.
- **`unavailable database` with a path on another server.** Services work only on databases of their own server. Use a `stdout` backup to get the file on the client.
- **`Secondary server attachments cannot validate databases`.** Close the other connections, or shut the database down.
- **`Database shutdown unsuccessful`.** Connections or transactions were still active after `Wait` seconds. Use `Forced`, or a longer `Wait`.
- **`BringDatabaseOnline` raises.** The database is already online.
- **`License` in `Options` of `TFIBServerProperties`.** Firebird does not support it, and `Fetch` raises.

## See also

- [FIBServices components reference](../reference/TFIBServices.md)
- [Connections](connections.md)
- [Events and monitoring](events-and-monitoring.md)
- [Firebird versions](firebird-versions.md)
