# Upgrading

This article lists what an existing application must know or do when it moves to a newer FibPlus version: breaking changes, changed behavior, renamed or removed identifiers, deprecated members, and build changes. It does not list bug fixes or new features. For the complete list, see `CHANGELOG.md` in the repository root.

## How to use this page

Find the version you use now, then read every section above it, from the one just after your version up to the version you are moving to. Sections are ordered like the changelog, newest first.

| Version | Status | Notes |
|---------|--------|-------|
| [7.9.1](#791) | 2026-10-09 | |
| [7.9.0](#790) | 2026-10-01 | First release of the community maintained FibPlus. Based on the FIBPlus 7 sources of build 632 (2014-02-17). |

## 7.9.1

### Build

| Change | What to do |
|--------|------------|
| The packages for Delphi 2007 and later write DCU files to `$(BDSCOMMONDIR)\Dcu\FIBPlus\$(Platform)\$(Config)`. | Add that folder to the Library path if you link the DCU files instead of the sources. |
| `FIBPlusFMX` is a new runtime package (Delphi 13) that contains the FireMonkey login dialog `FIB_FMX_DBLoginDlg`. The unit was in no package before. | Add the package to the requires list of an FMX application that uses the dialog. |

### Renamed and removed identifiers

| Old | New | What to do |
|-----|-----|------------|
| `FIBRelease` | `FIBPatchVersion` | Rename. |
| `FIBBuildDate` | `FIBVersionDate` | Rename. The value is an ISO date. |
| `IBASE_DLL` (`ibase`) | `CLIENT_DLL` | Rename. The default value is `fbclient.dll`, see [Client library](#client-library). |
| `v`-prefixed protected fields of `TFIBDatabase` and `TFIBTransaction`: `vInternalTransaction` and the other event list and TPB fields | `F` prefix: `FInternalTransaction`, `FAfterConnectEvents`, `FBeforeDisconnectEvents`, `FBeforeDestroyEvents`, `FBeforeStartTransactionEvents`, `FAfterStartTransactionEvents`, `FBeforeEndTransactionEvents`, `FAfterEndTransactionEvents`, `FDatabaseTRParams`, `FDatabaseTPBs` | Rename in descendants of these classes that use the fields. |
| `TpFIBDatabase.CreateRCTimer` (protected) | `CreateRestoreConnectTimer` | Rename in descendants that call it. |
| `SUPPORT_KOI8_CHARSET`, `StdFuncs.ConvertToCodePage`, `StdFuncs.ConvertFromCodePage` | Removed | Use `FIBCharSets` (`DecodeString`, `EncodeString`). Affects only code that defined the symbol (it was off by default) or calls the functions. |
| `SqlTxtRtns.IBStdCharacterSets`, `IBStdCharSetsCount`, `IBStdCollationsCount` | Removed | Use `FIBCharSets.FirebirdCharSetName`. |

The version constants are untyped and live in the `fib` unit, so you can test them in conditional compilation after `fib` is in the `uses` clause:

```delphi
{$IF (FIBMajorVersion > 7) or ((FIBMajorVersion = 7) and (FIBMinorVersion >= 9))}
  // code for FibPlus 7.9 and later
{$IFEND}
```

### Deprecated members

These members still compile.

| Deprecated | Use instead |
|------------|-------------|
| `TFIBDatabase.FBAttachCharsetID` | `Capabilities.AttachmentCharSetID` |
| `TFIBDatabase.IsKOI8Connect` | `Capabilities.AttachmentCharSetID` |

`Capabilities.AttachmentCharSetID` is read once at connect. It is `-1` when the database is not connected and on InterBase. See [TFIBDatabase](../reference/TFIBDatabase.md).

### Changed behavior

#### Client library

The default `LibraryName` is `fbclient.dll` (Windows); it was `gds32.dll`. This applies to `TFIBDatabase` and `TpFIBServices`, and comes from the global `CLIENT_DLL`. A form saved with the old default does not store `LibraryName`, so it gets the new one.

When `LibraryName` is `fbclient.dll` without a path and that library cannot be loaded, FibPlus loads `gds32.dll`. An application that ships the Firebird client renamed to `gds32.dll` keeps working, but:

- An `fbclient.dll` that Windows finds first (in `System32` or in `PATH`) is loaded instead of the `gds32.dll` next to the program. Ship `fbclient.dll` next to the program, or set `LibraryName` to the full path of the library you ship.
- The plugins of the *Firebird 3+* client, for example `ChaCha` for wire encryption, need a library with the name `fbclient.dll`. A client renamed to `gds32.dll` cannot load them.
- A name with a path, or another name, is never replaced by `gds32.dll`. To keep the old library on purpose, set `LibraryName` to `gds32.dll`, or `CLIENT_DLL := 'gds32.dll'` at startup before any component is created.

`TpFIBDatabase.AliasName` now reads `CLIENT_LIB` of the alias into `LibraryName`. Aliases written by earlier versions (`SaveAliasParamsAfterConnect` is `True` by default) usually hold `gds32.dll`, which then replaces the new default and gets no fallback to `fbclient.dll`. Save the alias again with the right `LibraryName`, or delete its `CLIENT_LIB` value.

`TpFIBScripter` no longer changes `LibraryName` of its database on `CONNECT`, `CREATE DATABASE`, and `DROP DATABASE`; only `SET CLIENTLIB` changes it. A script without `SET CLIENTLIB` that relied on the default library now uses the `LibraryName` set on the database.

#### SQL dialect

The default `SQLDialect` is `3`; it was `1`. It changes:

- `TFIBDatabase` and `TpFIBDatabase` created in code.
- Components dropped on a form at design time, through `DefSQLDialect`. A dialect saved in the FIBPlus preferences is kept.

Forms always store `SQLDialect`, so they keep their value. On a dialect 1 database, `SQLDialect` is lowered to `1` at connect, as before. Code that creates a database in code, connects to a dialect 3 database, and relies on dialect 1 must set `SQLDialect := 1`. Dialect 1 treats text in double quotes as a string literal and `DATE` as a timestamp.

#### `AttachmentID`

`TFIBDatabase.AttachmentID` is an `Int64`, because the attachment ID is `BIGINT` in *Firebird 3+*. It was a `Long`. It returns `0` when the database is not connected; it returned `-1`. Replace comparisons with `-1`. `Database` is a `TFIBDatabase`:

```delphi
if Database.AttachmentID = 0 then
  ShowMessage('Not connected');
```

#### Statistics table

`TFIBSQLLogger.CreateStatisticsTable` creates `FIB$APP_STATISTICS.ATTACHMENT_ID` as `BIGINT` in dialect 3 (`INTEGER` in dialects 1 and 2). Update a table that already exists:

```sql
ALTER TABLE FIB$APP_STATISTICS ALTER ATTACHMENT_ID TYPE BIGINT;
```

`TFIBSQLLogger.StatisticsParams` had no effect before. Parameters that you left out of the set are now not written by `SaveStatisticsToFile`, and `SaveStatisticsToDB` writes `NULL` in their columns. This is a bug fix, listed because it changes what is written.

#### Character sets

Text goes through the code page of its column's character set. These changes can affect data that was stored with a wrong character set or through a mismatched connection.

- A character that the target code page cannot hold raises `Cannot transliterate character between character sets`, for values and for SQL text. Before, it was sent as `?` or as a look-alike. For example, `ș` and `ț` with a comma (Romanian Standard keyboard) do not exist in `WIN1250` and `WIN1252`. Use `UTF8` or another keyboard layout.
- A `NONE` connection decodes a column with its declared character set. Text that was written in another code page, for example cp1250 into a `WIN1252` column, now shows as stored. Repair such data by reinterpreting the bytes:

  ```sql
  cast(cast(C as varchar(n) character set OCTETS) as varchar(n) character set WIN1250)
  ```

- `ISO8859_1` and `ISO8859_9` use code pages 1252 and 1254, so the range `0x80..0x9F` shows `€ “ ” …` instead of control characters. `ASCII` uses the system code page.
- `TFIBStringField.AsAnsiString` (*Delphi 2009+*) returns the column bytes with their code page set. Calculated and lookup `ftString` fields use the system code page.

#### Restoring a lost connection

`TpFIBDatabase.WaitForRestoreConnect` reads its default `30000`; it read `0` until code assigned it. A database created in code whose `OnLostConnect` chooses `laWaitRestore` now tries to connect again every 30 seconds; before, it only closed the connection. A form that never had a value set in the Object Inspector stores `WaitForRestoreConnect = 0` and keeps the old behaviour; remove the line to use the default.

#### Scripter

`TpFIBScripter` skipped the session `SET` statements without an error: `SET STATEMENT TIMEOUT`, `SET SESSION IDLE TIMEOUT`, `SET BIND`, `SET TIME ZONE`, `SET DECFLOAT`, `SET ROLE`, `SET TRUSTED ROLE`, `SET OPTIMIZE`, and `SET SEARCH_PATH`. It now sends them to the server, so a script that contains one of them now runs it. Review old scripts for such statements. These statements have the new `TStmtType` value `sSetSession`. See [Scripting](scripting.md).

## 7.9.0

If you come from an older version, apply these changes first, then the sections above.

### Build

| Change | What to do |
|--------|------------|
| The library sources moved to `Source`, the editors to `Source\Editors`. | Replace the library root with `Source` in the Library path. |
| `pFIBVersion.inc` is renamed to `FIBVersion.inc`. | Change the file name if you include it. |

### Renamed and removed identifiers

| Old | New | What to do |
|-----|-----|------------|
| `FIBPlusVersion`, `FIBPlusBuild`, `FIBCustomBuild`, `FIBPlusBuildDate` | `FIBMajorVersion`, `FIBMinorVersion`, `FIBRelease`, `FIBBuildDate`, `FIBVersionString` | Replace. The old build numbers do not map one to one to the new constants. The 7.9.1 section renames `FIBRelease` and `FIBBuildDate` again. |
| `qDefaultFields` | `DefaultFields` | Rename. |
| `TpStoredProcCollect` | `TFIBStoredProcMetadataCache` | Rename. |
| `CycleReadArray`, `CycleWriteArray` of `VariantRtn` | Removed | Use another way to read and write arrays. |
| Mirror Dataset Tools (MDT) | Removed | Remove it from the application. |

### Deprecated members

These members still compile. Most give a deprecation warning; the `IIBClientLibrary` properties do not, because only their getters are marked `deprecated`.

| Deprecated | Use instead |
|------------|-------------|
| `TFIBDatabase.ClientMajorVersion`, `ClientMinorVersion` | `IIBClientLibrary.Version` |
| `IIBClientLibrary.ClientVersion`, `ClientMinorVersion` | `IIBClientLibrary.Version` |
| `SQL_DATE` | `SQL_TIMESTAMP` |
| `FB3_SQL_BOOLEAN` | `SQL_BOOLEAN` |

### Changed behavior

#### Types and parameters

- `SQL_BOOLEAN` in `ibase.pas` is `32764`, the Firebird 3 `BOOLEAN` type. It was `590`, the InterBase type. Code for InterBase must use `IB_SQL_BOOLEAN`.
- `TFIBXSQLVAR.AsBoolean` of a numeric value is `True` for any non-zero value, whatever the scale.
- `AsDouble` and `AsTime` assigned before `Prepare` are applied when the server type is known. A `Double` assigned to a date or time parameter is converted as a `TDateTime`.
- String parameters encoded in UTF-8 are declared as `UTF8` instead of `UNICODE_FSS` on *Firebird 2.0+* and *InterBase 2007+*.
- `TpFIBArray.Dimension` raises for bounds outside `-32768..32767`. It cut them before.

#### Long identifiers

On *Firebird 4+*, persistent fields and `FIB$FIELDS_INFO` rows that were saved with a cut or an `F_n` name for a column longer than 31 bytes must be renamed. See [Long identifiers](firebird-versions.md#long-identifiers) for the requirements.

#### Queries

- `TFIBQuery` applies `qoAutoCommit` and `qoFreeHandleAfterExecute` when the cursor is done: at `Eof`, `Close`, an SQL change, the next `ExecQuery`, or `Free`. See [TFIBQuery](../reference/TFIBQuery.md).
- Changing `SQL` of an open query closes it.
- `TpFIBStoredProc` builds its SQL from the server metadata. If the database is not connected when `StoredProcName` is set, the SQL is deferred and built on first use after the connection opens. With a connected database it is built at once.

#### Scripter

The script parser was rewritten. It accepts several statements on a line, `EXECUTE BLOCK` and PSQL modules with the `;` terminator, multi-character `SET TERM` terminators, and directives in `ExecuteFromFile`. Check scripts that relied on the old splitting. See [Scripting](scripting.md).

## See also

- `CHANGELOG.md` in the repository root, for the complete list including bug fixes
- [Connections](connections.md)
- [Firebird versions](firebird-versions.md)
- [Timeouts](timeouts.md)
