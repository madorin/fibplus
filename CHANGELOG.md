# Changelog

## [8.0.0] - Unreleased

### Added

#### IDE tools

- `dclFIBTools` design time package for Delphi 10.4 Sydney and later: one
  `Packages\dclFIBTools.dpk` for all versions (`dclFIBTools270.bpl` to
  `dclFIBTools370.bpl`, through `{$LIBSUFFIX AUTO}`). It is
  optional and is in the `FIB` project group. It needs only `FIB`
  ([#67](https://github.com/madorin/fibplus/issues/67)).
- The **Tools > FIBPlus** menu with **Preferences...** and **About FIBPlus...**.
  FIBPlus is also shown on the IDE splash screen and in the IDE About box.
- **Preferences** is reachable from the IDE (the dialog was in the
  editors package but no menu opened it). The options `psCanEditComputedFields`,
  `psSupportUnicodeBlobs`, `poNoForceIsNull`, `poFreeHandlesAfterClose`,
  `poRefreshAfterDelete`, `poDontCloseAfterEndTransaction`, `qoTrimCharFields`,
  `qoNoForceIsNull` and `qoFreeHandleAfterExecute` can now be set as design time
  defaults.
- **Close design-time connections before the program runs** in Preferences: the
  IDE closes the connections of the design time components before **Run** and
  **Run without debugging**, so the program doesn't compete with them for the
  database. Connections opened by code running in the IDE stay open.
- The design time packages `dclFIB` and `dclFIBTools` can be installed in
  the 64-bit IDE of Delphi 12.3 and 13 (Win64 platform).

#### Localization

- Translations of the FIBPlus error messages in Portuguese (Brazil), Spanish,
  German, Ukrainian, Czech, Polish and Romanian, in
  `Locales\<code>\Errors.inc` (`pt-BR`, `es`, `de`, `uk`, `cs`, `pl`,
  `ro`), beside the Russian one (`ru`); see
  [Localization](Docs/guide/localization.md).
- The VCL and FMX login dialogs are translated in the same languages
  (`Locales\<code>\LoginDlg.inc`), and their fields are wider for the longer
  texts. The hotkeys of **User name**, **Password** and **Role** move to
  their fields.
- The errors of array fields and parameters, of the conversion to a code
  page, of the `ORDER BY` of a dataset with a limited cache and of the
  metadata load are translated too: they have their own `TFIBClientError`
  values (`feArrayColumnNotFound` to `feCantLoadMetadata`) instead of
  `SQLCode` -1 and an English text. A feature missing in the client library
  raises `feClientFeatureNotSupported`, whose text names the library in the
  language of the messages; see
  [Upgrading](Docs/guide/upgrading.md#codes-of-client-errors).
- The locale is set in `Source\FIBLocale.inc`, for example
  `FIBLocale = 'ro';` (`'en'` by default); an unknown code stops the build.
  `FIBLocale` is also a constant of the unit `FIB`.
  `Source\FIB_MESSAGES.INC` moved to `Locales\en\Errors.inc` and
  `Resources\Russian` to `Locales\ru`, so a translation is no longer copied
  over it, and the `Resources` folder is removed; see
  [Upgrading](Docs/guide/upgrading.md#800).

### Changed

The lists of old and new names, and what an application has to change, are in
[Upgrading](Docs/guide/upgrading.md#800).

#### Renamed classes and units

- Classes, types and units lost the `p` of their names: `TpFIBDataSet` in
  `pFIBDataSet` is now `TFIBDataSet` in `FIBDataSet`, and the same for the
  database, transaction, query, update object, stored procedure, scripter,
  error handler, client dataset, array, schema extract and the other classes.
  The service components are now `TFIB...Service` in `FIBServices` (was
  `IB_Services`), `TpFIBStatistics` is now `TFIBSQLLogger`, and
  `TSIBfibEventAlerter` in `SIBFIBEA` is now `TFIBEventAlerter` in
  `FIBEventAlerter`.
- Most existing code compiles without a change: the main old units
  (`pFIBDataSet`, `pFIBDatabase`, `IB_Services`, `SIBFIBEA` and the others)
  stay as deprecated units with the old names as deprecated aliases, and forms
  with the old class names load while the old unit is linked. They will be
  removed in a later major version.
- Without an old name, so the code needs a change: the login dialog hook
  (`pFIBLoginDialog` is now `FIBLoginDialog`), the property `FIBArray` of
  `TFIBXSQLVAR` and `TFIBArrayStream` (now `ArrayInfo`), the writable defaults
  of `FIBProps` and the typed constants of `FIBServices`, the helper units
  (`pFIBDataInfo`, `pFIBLists` and the others stop the compilation with a
  message that names the new unit), the design-time units and editors.
  `TpFIBDBEventType`, `TpFIBTrEventType` and `TpSQLKind` are now only in
  `pFIBDatabase` and `pFIBDataSet`.
- The IDE preferences are stored under registry keys without the `p`
  (`FIBDataSet`, `FIBQuery`, `FIBDatabase`, `FIBTransaction`): set them again
  once in the FIBPlus preferences.

#### Merged components

- `TpFIBDataSet`, `TpFIBQuery`, `TpFIBUpdateObject`, `TpFIBDatabase` and
  `TpFIBTransaction` are merged into `TFIBDataSet`, `TFIBQuery`,
  `TFIBUpdateObject`, `TFIBDatabase` and `TFIBTransaction`, which publish the
  properties and events of both classes. The code of the dataset is in
  `TFIBCustomDataSet`.
- `TFIBDataSet` now behaves like `TpFIBDataSet` did: SQL generation, update
  objects, cached updates routines, record locking, visible record numbers,
  field properties and repository of `DataSet_ID`, and events sent to
  `Container`. `Prepare` no longer prepares `RefreshSQL` at design time.
- `TFIBQuery` has now `Description`, `OnExecuteError`, `About`, `ExecProc`,
  `ExecProcedure`, `BlobToStrings`, `BlobAsString` and `FieldIsNull`, and
  publishes `BeforeExecute` and `AfterExecute`. `FN` raises for a missing
  column like `FieldByName` (it returned `nil`); use `FindField` to get `nil`.
- `TFIBDatabase` and `TFIBTransaction` now have the aliases, the schema cache,
  the lost-connection restore and the connect and transaction events for every
  connection. `Open` on a connected database and `ForceClose` on a closed one
  do nothing. `StartTransaction` on an active transaction raises
  `feInTransaction` (`TpFIBTransaction` did nothing); `Active := True` still
  does nothing. `AfterStart` and `AfterStartTransaction` are raised only when
  the transaction started. `CacheSchemaOptions :=` in code copies the values.
- Types that moved with the merge: `TFIBUpdateObject`, `TLockStatus`,
  `TCachRefreshKind` and the other dataset types are in `FIBDataSet`;
  `TFIBLoginEvent`, `TOnLostConnectActions`, `TOnSQLExecute` and the other
  connection types are in `FIBDatabase`; `TFIBFieldInfo`,
  `TOnBlobFieldProcessing` and `TFIBSQLTypes` are in `FIBProps`.
- Changed signatures: `TOnSQLExecute` has the parameter `Query: TComponent`
  (it was `TFIBQuery`); `FIBDataSets[Index]` and `FIBQueries[Index]` of the
  database and the transaction return `TDataSet` and `TComponent`;
  `TFIBUpdateObject.DataSet` has the type `TFIBCustomDataSet` and accepts any
  FIBPlus dataset. The messages `SFIBErrorNotDataSet` and
  `SFIBErrorNotDataSetDetail` are removed.

#### Transactions and lost connection

- `TPBMode` writes the lines of its preset into `TRParams`, and `TRParams` is
  always exactly what is sent; any change of `TRParams` sets `TPBMode` to
  `tpbDefault`. A new transaction has the lines of `tpbReadCommitted` instead
  of an empty list, so a `TFIBTransaction` with untouched `TRParams` starts
  read committed with `nowait` instead of `concurrency` and `wait`. `TPBMode`
  and `TRParams` cannot change on an active transaction (`feInTransaction`),
  and `TRParams` must not be changed in `BeforeStart`. The rules for adding
  lines to a preset (`lock_timeout` and the others) are in
  [Upgrading](Docs/guide/upgrading.md#tpbmode-and-trparams).
- `TFIBTransaction.Internal` is new. The database events
  `BeforeStartTransaction`, `AfterStartTransaction`, `BeforeEndTransaction` and
  `AfterEndTransaction` are raised for every transaction of the database (they
  were raised only for `TpFIBTransaction`), except those with `Internal` set to
  `True`, which the library sets on its own transactions.
- `TFIBErrorHandler` runs the lost-connection action on the database of the
  failing object (a database, a query, a transaction or a BLOB stream) for every
  `TFIBDatabase`. Without a database it pings each connected database and acts
  only on those that report a lost connection, instead of on every database of
  the process; a lost service connection closes no database.

#### Editors

- The editors, the login dialog and the samples use Segoe UI instead of
  MS Sans Serif, a bitmap font without anti-aliasing; their layouts are
  adjusted to the new font.
- The dialogs of fixed size (connection, transaction, dataset options and the
  others) no longer remember their size and position and open centered on the
  screen; the resizable editors still do, also when maximized, and a saved
  position outside the screen is moved onto it.

#### Build

- `FIBPlus.inc` is renamed to `FIB.inc`, and `RegFIBPlus`, `RegFIBPlusEditors`
  and `RegFIBPlus.dcr` to `RegFIB`, `RegFIBEditors` and `RegFIB.dcr`.
- The unit `fib` is renamed to `FIB` (`FIB.pas`), like the other units with the
  `FIB` prefix. Delphi code compiles without a change.
- The login dialog units `FIBDBLoginDlg` and `FIB_FMX_DBLoginDlg` are renamed
  to `FIBLoginDlg` and `FIBLoginDlgFMX`, and their forms to `TFIBLoginForm` and
  `TFIBLoginFormFMX`.
- The compiler version symbols of `FIB.inc` are named after
  `CompilerVersion`: `C21` (Delphi 2010) to `C37` (Delphi 13) replace `D2010+`,
  `D_XE`..`D_XE5` and `D_20`..`D_30`; `TWideDataSet` is removed (`C24` not
  defined).
- The packages are renamed: the runtime package is `FIB`, the design time
  packages start with `dcl`, as in Delphi and other libraries, and the editors
  packages are merged into them; the old and new names are in
  [Upgrading](Docs/guide/upgrading.md#packages).
  - Delphi 10.4 and later have one package of each kind for all versions,
    through `{$LIBSUFFIX AUTO}`, in `Packages\FIB.groupproj`: `FIB`
    (`FIB270.bpl` to `FIB370.bpl`), `dclFIB`, `dclFIBTools` (was `FIBTools`)
    and `FIBFMX` (was `FIBPlusFMX`), which is also built for Delphi 10.4 to 12.
  - Delphi 2009 to 10.3 Rio have `FIB_Dxx` and `dclFIB_Dxx`, named after the
    package version, from `FIB_D12` (Delphi 2009) to `FIB_D26` (10.3 Rio), in
    `FIB_Dxx.groupproj`. The duplicate packages of Delphi XE7 are merged into
    `FIB_D21` and `dclFIB_D21`.
- The packages write DCU files to `$(BDSCOMMONDIR)\Dcu\FIB\$(Platform)\$(Config)`
  instead of `$(BDSCOMMONDIR)\Dcu\FIBPlus\$(Platform)\$(Config)`.

### Removed

- Support for Delphi 6, 7, 2005, 2006, 2007 and C++Builder 6 to 2007 (the
  non-Unicode compilers), their packages, the Kylix code and the TNT controls
  interface `IWideStringField`; the minimum is Delphi 2009.
- `FIBCharSets.DecodeWideString`: use `DecodeString`.
- `TFIBMemoField.WideDisplayText` and `WideText` of `IWideStringField`,
  `AsComp` of `TFIBBCDField`, `TFIBClientBCDField` and `TFIBXSQLVAR`, and the
  polyfills `StrUtil.CharInSet` and `FIBPlatforms.WideCompareStr` (`SysUtils`
  declares both); see [Upgrading](Docs/guide/upgrading.md#800).
- The samples `UnicodeFSS` (TNT controls) and `UnicodeFSS_2009`.
- `StrUtil.TFastStringStream`: the DDL methods of `FIBMetaData`
  (`GenerateDDLText`, `GenerateObjectDDL` and the others) take a
  `TStringStream`; see [Upgrading](Docs/guide/upgrading.md#800).
- `TFIBLicensingService` (InterBase license keys) and the units `IB_Install` and
  `IB_InstallHeader` with `TpFIBInstall` and `TpFIBUnInstall` (InterBase 6 install
  library `ibinstall.dll`, never registered: `IBINSTALL_SUPPORT` was off) with their
  messages in `FIBConsts`. Firebird has neither; see
  [Upgrading](Docs/guide/upgrading.md#800).

### Fixed

- `PSGetCommandText` of `IProviderSupport` returned an empty string on Delphi
  XE3 and later; it returns the select SQL or the pending provider command, as
  `PSGetCommandTextW` did on Delphi 2009 to XE2.
- Editors at a display scaling over 100%: the saved size of a window was
  restored in pixels of 100%, so the window was too small for its content
  (sizes are now saved with the DPI of the window); the **Cancel** button of
  the SQL editors and of the dataset repository editor was partly off the
  form; the gutter of the SQL editor (line numbers, bookmarks, breakpoints,
  section boxes, the click area of the breakpoints) was not scaled.
- The editors did not save text and some integer settings on Delphi 2009 and
  later: the font name, style and charset and the syntax highlighting styles of
  the SQL editor, and the user transaction kinds of the transaction editor were
  lost when the IDE was closed.
- SQL editor: the line numbers covered the breakpoint glyphs, and a line
  number after a keyword was drawn in bold.
- SQL editor: selecting with the mouse in an editor without lines raised an
  "index out of bounds" error.
- `TFIBScripter` cut a statement at a `--` comment when the script was added
  as one item with several lines (e.g. `Script.Add` of a multi-line string):
  the comment ran to the end of the item, not of the line
  ([#95](https://github.com/madorin/fibplus/issues/95); also in 7.9.2).
- `FIBArray` did not compile on Delphi 10.1 Berlin: "Invalid typecast" in
  `TFIBArray.ReadElement`
  ([#94](https://github.com/madorin/fibplus/issues/94); also in 7.9.2).
- SQL monitor: non-ASCII text could arrive garbled, through the system code
  page or a chunk of a long event cut inside a character.
- `TFIBErrorHandler`: the message of a user exception was cut at an "at" in its
  text, or kept the stack trace (`At procedure ...`). The SQL monitor and the
  SQL logger got the message after the error handler changed it; they now show
  the server text with the stack trace.
- `TFIBScripter` with `UseExecBlockForDML`: an `INSERT`, `UPDATE`, `DELETE` or
  `MERGE` with `RETURNING` was grouped into an `EXECUTE BLOCK`, where it needs
  `INTO`, so the whole block failed. Such a statement now runs alone; the new
  `TStatementDesc.HasReturning` field marks it.
- `TFIBScripter` with `UseExecBlockForDML`: the size limit of an
  `EXECUTE BLOCK` counted characters, so with UTF8 and non-ASCII text a block
  could be over the 64 KB the server accepts. The limit is now in bytes of the
  connection charset, and 10 MB with a Firebird 3 or later server and client.
- Russian messages (`Locales\ru\Errors.inc`): an unknown DPB or
  TPB constant raised an `EConvertError` ("Format ... invalid or incompatible
  with argument") instead of its message. The file was in code page 1251 and
  compiled to garbled text on a machine with another system code page; it is
  now UTF-8. The message of `feCantEndSharedTransaction` said something else
  than the English one, and `feCantUseField` had a grammar error.
- English messages: typos ("functonality", "equel", "an Firebird 2"), the
  space before the colon in "%s :Transaction is not active" and the others,
  and "Column types ... is not array field".
- A string over 32767 bytes for a `VARCHAR` parameter was sent as a blob of the
  column charset subtype, so the server reported "Filter not found to convert
  type 4 to type 1" instead of a string truncation.
- `Locate` on a `TIMESTAMP` or `TIMESTAMP WITH TIME ZONE` field did not find a
  value with milliseconds given as a `Double` (e.g. `EncodeDate(...) +
  EncodeTime(...)`), and could miss a `TIMESTAMP WITH TIME ZONE` value by a
  rounding difference. The values are now compared in milliseconds; only a text
  key ignores them.
- `utf8_filename` in `DBParams` was sent, but the database name, user name,
  password and role stayed in the system code page, so non-ASCII values were
  garbled or rejected. With `utf8_filename` they are now sent in UTF-8, and
  `TFIBDatabase.DBName` keeps characters outside the system code page. The
  Firebird client still converts the file name to the system code page before
  it parses it.
- A quoted role name in `DBParams` (`sql_role_name="MixRole"`) lost its case and
  the connection had no role: without a dialect in the DPB the server takes
  dialect 1 and uppercases it. `SQLDialect` is now sent in the DPB, unless
  `DBParams` has `sql_dialect`. A role without quotes is still uppercased; see
  [Upgrading](Docs/guide/upgrading.md#role-name-in-quotes).
- The metadata and dataset info caches (`ListTableInfo`, `ListDataSetInfo`)
  kept the database name in the system code page: with a name outside it no
  entry was found, and each `GetTableInfo` read the metadata again and added
  an entry. The metadata cache also lost table and column names, primary key
  fields, defaults, labels and formats outside it (a non-ASCII default value
  of a column came back as `?`). They are now kept as `string` and the cache
  files are saved in UTF-8; files saved by older versions are still read
  ([Upgrading](Docs/guide/upgrading.md#800)).
- `EFIBClientError.IBErrorCode` had the code of an earlier server error of the
  thread: after a statement timeout a client error had `isc_cancelled`, so
  `TFIBErrorHandler` took it for a cancelled statement. It is now 0.
- Numeric `DBParams` (`num_buffers`, `dummy_packet_interval`,
  `connect_timeout`, `old_file_size`, `shutdown_delay`, `force_write` and the
  other flags) were written in one byte, so a value over 255 was cut
  (`num_buffers=2048` sent 0). They are now written in 4 bytes.
- Macros: an old form macro (`@Name`) followed by a tab took the rest of the
  text up to the next space into its name, and one at the very end of the text
  was not replaced. A new form macro (`@@Name@`) without the closing `@` went
  to the server as it was; it now raises "EOF in macro detected".
- `AsTimeZoneName` of a `TIME` or `TIMESTAMP WITH TIME ZONE` value in a region
  unknown to the built-in time zone table was empty, and `AsString` ended with
  a blank. It is now the offset of the value (`+02:00`).
- A text BLOB parameter set with `AsString` before `Prepare` read `(BLOB)`
  after `ExecQuery`; it now returns the string, as when it is set after
  `Prepare`.
- DDL generated by `TFIBDBSchemaExtract` (`GetDDLText`, `GetObjectDDL`) on
  Delphi XE5 and later: characters outside the system code page in names,
  defaults and procedure bodies became `?`, and a DDL under 10 KB was padded
  with `#0` to 10240 characters. The DDL is now written to a `TStringStream`
  created with `TEncoding.Unicode`.
- `AnsiCompareString` as `OnCompareFieldValues` took every field that is not
  `ftString` or `ftFixedChar` (e.g. a UTF8 column) for equal, so `DoSort` gave
  a random order. A NULL in a string field was also taken for equal
  to every value. These fields and NULLs are now compared as by
  `StdCompareValues`.
- `Locate` with several `TIMESTAMP` keys: a text key for one of them made the
  others ignore the milliseconds of the row, so a `TDateTime` key with
  milliseconds was not found. Only the field of the text key ignores them now.
- After `DoSort`, reopening the dataset without `poPersistentSorting` kept
  `Sorted` and `SortedFields` of the local sort, while the rows came in the
  server order. With `psGetOrderInfo` they are now read again from the `ORDER BY`
  of the query.
- Changing `psUseGuidField` in `PrepareOptions` after the first open had no
  effect: the field stayed a `TFIBStringField`. The field definitions are now
  read again, as for `psUseBooleanField`.

## [7.9.1] - 2026-10-09

### Added

#### Character sets

- Text goes through the code page of its column's charset (fields, parameters,
  text BLOBs, dataset fields, array elements, SQL text, object names), not only
  UTF-8 or the system code page: e.g. WIN1251 data on a Western Windows no
  longer comes as `?` or mojibake.
  - Unit `FIBCharSets` (`FirebirdCharSetCodePage`, `FirebirdCharSetName`,
    `DecodeString`, `EncodeString`); `TFIBDatabase.Capabilities`: `AttachmentCharSetID`,
    `CodePage`, `MetadataCodePage`, `TextCodePage`, `BlobCodePage`;
    `TFIBDatabase.ConnectionSerial`; `TFIBCustomDataSet.StringFieldCharSetID`,
    `StringFieldCodePage`, `BlobFieldCodePage`.
- Unlike FireDAC and IBDAC (UTF-8 or the system code page only): any Firebird
  charset, per column also on NONE connections; NONE/OCTETS columns kept as
  bytes on UTF8 connections; array elements in the column charset; DDL and
  names in UTF-8 on NONE; an error instead of `?` for characters the charset
  can't hold.

#### Packages

- `FIBPlusFMX` runtime package for Delphi 13 with the FireMonkey login dialog
  `FIB_FMX_DBLoginDlg`, which was in no package. Its name has no version
  suffix: the BPL gets one through `{$LIBSUFFIX AUTO}` (`FIBPlusFMX370.bpl`).

#### Timeouts

Firebird 4+ statement and idle timeouts; details in `Docs/guide/timeouts.md`.

- `TFIBDatabase.Session`: `StatementTimeout` (ms, every statement of the
  attachment) and `IdleTimeout` (s), sent after connect and when changed.
  `Apply` sends them again (e.g. after `ALTER SESSION RESET`);
  `ActualStatementTimeout` / `ActualIdleTimeout` read them from the server.
  `IdleTimeout` is not sent at design time.
- `TFIBQuery.StatementTimeout` and `TpFIBDataSet.StatementTimeout` (ms, through
  `fb_dsql_set_timeout`) replace the session value for one statement;
  `FIBNoStatementTimeout` opts a statement out of it.
- For a `SELECT` the timer runs until the last row is fetched, so a dataset
  browsed in a grid can fail on a later scroll. In interactive applications set
  the timeouts per query, or opt the browsing datasets out.
- A non-zero value the server or the client library can't apply raises
  `EFIBClientError` (`feFeatureNotSupported`); 0 never raises. A value stored in
  a DFM makes `Open` fail on Firebird 3 and older (`Open(False)` returns with
  `Connected = False`). `Capabilities.SessionTimeouts` and
  `Capabilities.StatementTimeout` tell what is available.
- `EFIBError.ErrorCodes`, `HasErrorCode` and `IsStatementTimeout`;
  `keStatementTimeout` and `keCancelled` in `TKindIBError`. An idle timeout
  arrives as a lost connection.

#### Read consistency

Firebird 4+ read committed transactions where every statement reads one
snapshot taken at its start.

- `read_consistency` in `TRParams` (`isc_tpb_read_consistency`).
- `TpFIBTransaction.TPBMode` `tpbReadConsistency` sends `write`, `nowait`,
  `read_committed` and `read_consistency`; on a server older than Firebird 4
  `StartTransaction` raises `EFIBClientError` (`feFeatureNotSupported`).
  `tpbReadCommitted` stays the default: with the server default
  `ReadConsistency = 1` it already runs in this mode on Firebird 4+.
- `Capabilities.ReadConsistency` and `TFIBDatabase.RequireReadConsistency`;
  `IsReadCommitedTransaction` also recognizes `read_consistency`.
- A ReadConsistency kind in the transaction editor.

#### Parallel workers

Firebird 5+ parallel workers for sweep, index creation, backup and restore; the
server limits them with `MaxParallelWorkers` in `firebird.conf` (default 1).

- `parallel_workers` in `DBParams` and the typed `ConnectParams.ParallelWorkers`
  (0 removes the line). The parameter is sent to Firebird only; Firebird 3 and 4
  ignore it.
- `ParallelWorkers` on `TpFIBBackupService`, `TpFIBRestoreService` and
  `TpFIBValidationService` (sweep, sent only with `SweepDB`). It is sent only
  when greater than 0; a Firebird 3 or 4 server rejects it.

### Changed

- `FIBRelease` is renamed to `FIBPatchVersion`.
- `FIBBuildDate` is renamed to `FIBVersionDate` and uses the ISO date format.
- Version constants are untyped and can be used in `{$IF}` directives.
- `TFIBDatabase.AttachmentID` is `Int64`, read with `isc_portable_integer`
  (the attachment ID is `BIGINT` in Firebird 3+), and is 0 instead of -1 when
  not connected ([#34](https://github.com/madorin/fibplus/issues/34)).
- `TFIBSQLLogger.CreateStatisticsTable` creates `FIB$APP_STATISTICS.ATTACHMENT_ID`
  as `BIGINT` in dialect 3. An existing table can be updated with
  `ALTER TABLE FIB$APP_STATISTICS ALTER ATTACHMENT_ID TYPE BIGINT`.
- Protected fields of `TFIBDatabase` and `TFIBTransaction` are renamed from the
  `v` prefix to `F`: `FInternalTransaction`, `FAfterConnectEvents`,
  `FBeforeDisconnectEvents`, `FBeforeDestroyEvents`,
  `FBeforeStartTransactionEvents`, `FAfterStartTransactionEvents`,
  `FBeforeEndTransactionEvents`, `FAfterEndTransactionEvents`,
  `FDatabaseTRParams`, `FDatabaseTPBs`.
- The protected `TpFIBDatabase.CreateRCTimer` is renamed to
  `CreateRestoreConnectTimer`.
- A character the target code page can't hold raises "Cannot transliterate
  character between character sets" (values and SQL text) instead of being
  sent as `?` or a look-alike, e.g. `ș`/`ț` with comma (Romanian Standard
  keyboard) on WIN1250/WIN1252: use UTF8 or the Romanian Legacy keyboard.
- NONE connections decode a column with its declared charset, so text written
  in another code page (e.g. cp1250 into a WIN1252 column) shows as stored.
  Repair by reinterpreting the bytes:
  `cast(cast(C as varchar(n) character set OCTETS) as varchar(n) character set WIN1250)`.
- ISO8859_1/ISO8859_9 go through code pages 1252/1254 (`€ “ ” …` instead of
  the C1 controls), ASCII through the system code page.
- `TFIBStringField.AsAnsiString` (Delphi 2009+) returns the column bytes with
  their code page set; calculated and lookup `ftString` fields use the system
  code page.
- `TFIBDatabase.FBAttachCharsetID` is a deprecated function, use
  `Capabilities.AttachmentCharSetID` (read once at connect, -1 when not
  connected or on InterBase); `IsKOI8Connect` is deprecated.
- `IIBClientLibrary.ClientVersion` and `ClientMinorVersion` are deprecated
  functions instead of properties, so using them gives a warning; use `Version`.
  Classes implementing the interface must add them.
- The default client library is `fbclient.dll` instead of `gds32.dll`
  (`TFIBDatabase.LibraryName`, `TpFIBServices.LibraryName`). The global
  `IBASE_DLL` is renamed to `CLIENT_DLL`. When `fbclient.dll` without a path
  can't be loaded, `gds32.dll` is loaded, so applications shipped with
  `gds32.dll` keep working. Forms saved with the old default don't store
  `LibraryName` and get the new one.
- The default `SQLDialect` is 3 instead of 1: in `TFIBDatabase` created in code,
  for new components dropped at design time (`DefSQLDialect`; a value saved in
  the preferences is kept), and in the SQL editor without a database. Forms
  always store `SQLDialect`, so they keep their value. On a dialect 1 database
  the dialect is lowered to 1 at connect, as before.
- The packages for Delphi 2007 and later write DCU files to
  `$(BDSCOMMONDIR)\Dcu\FIBPlus\$(Platform)\$(Config)` instead of
  `.\$(Platform)\$(Config)`: the folder next to the packages was shared by all
  Delphi versions, so they overwrote each other's DCU files.

### Removed

- `SUPPORT_KOI8_CHARSET` and `StdFuncs.ConvertToCodePage`/`ConvertFromCodePage`.
- `SqlTxtRtns.IBStdCharacterSets`, `IBStdCharSetsCount` and
  `IBStdCollationsCount`: use `FIBCharSets.FirebirdCharSetName`.

### Fixed

- `TFIBSQLLogger.StatisticsParams` had no effect. The parameters left out are
  not written by `SaveStatisticsToFile`, and `SaveStatisticsToDB` writes NULL
  in their columns (`MAXTIME_PARAMS` follows `fspMaxTimeExecute`).
- `TFIBSQLLogger.SaveStatisticsToDB` and `CreateStatisticsTable` roll back
  when a statement fails, instead of committing the rows inserted before it
  or leaving the transaction active.
- Array fields kept the descriptor of a previous connection.
- `TpFIBScripter`: `CONNECT`, `CREATE DATABASE` and `DROP DATABASE` replaced
  the `LibraryName` of the database with the default library. It is changed
  only by `SET CLIENTLIB`.
- Locate, filters, sorting and bookmarks on string fields of a non-system code
  page; lookup fields with a Unicode result field.
- `UseExecuteBlock`: apostrophes in literals not doubled, non-ASCII text sent
  in the system code page.
- `UseExecuteBlock`: dates, times and timestamps are written as ISO literals
  (they depended on the locale); TIME / TIMESTAMP WITH TIME ZONE values keep
  their zone (they were moved to the session zone); memo, GUID and emulated
  BOOLEAN values and memo text of a column charset on a NONE connection are
  written correctly. More than 255 records, or a block over 64K bytes (counted
  in bytes, not characters), failed with "Token unknown". A record posted without
  changes with `UpdateOnlyModifiedFields` failed with "Token unknown"; an insert
  without values writes `DEFAULT VALUES`. Deleted records stayed pending after
  the apply. `OnUpdateError` was called twice for a failed block, and the records
  of a skipped block lost their pending state. A record that does not fit in a
  block, and array and binary BLOB fields, now raise a clear error.
- Text BLOB parameters set before `Prepare` sent without their charset; NONE
  and OCTETS text BLOBs decoded as UTF-8 on UTF8 connections.
- A string parameter replaced by `AsInteger` before `Prepare` sent the string.
- Multi-byte charset values (SJIS, GBK, ...) cut in the middle of a character.
- `DisableEncodingSQLText` sent queries with parameters with an empty SQL text.
- `CharacterSet` returned `UNKNOWN` for KOI8R/U, WIN1258, TIS620, GBK, CP943C
  and GB18030.
- `GetExportDataScript` wrote `ftFMTBcd` values with the locale decimal
  separator.
- `GetExportDataScript` wrote dates in the locale format, left memo values
  unquoted and GUID values as text instead of the 16 bytes of the column.
- `StrUtil.FastCopy` read before the string for `Index < 1`; it now calls
  `Copy` on Delphi 2009+.
- The `FIBPlus_XE3` package did not compile: it contained the XML export units,
  which are not in the repository.
- `TpFIBScripter` skipped the session `SET` statements (`STATEMENT TIMEOUT`,
  `SESSION IDLE TIMEOUT`, `BIND`, `TIME ZONE`, `DECFLOAT`, `ROLE`, `TRUSTED
  ROLE`, `OPTIMIZE`, `SEARCH_PATH`) without an error; it now sends them to the
  server, so an old script that contains them now runs them. They have the new
  `TStmtType` value `sSetSession`.
- `Locate` with a Currency key on NUMERIC(10..18) columns with a scale did not
  find values above 2^53 (e.g. 12345678901234.5678).
- `pfImportDefaultValues`: `CURRENT_TIME(n)`, `CURRENT_TIMESTAMP(n)`,
  `LOCALTIME(n)` and `LOCALTIMESTAMP(n)` defaults failed with a conversion error
  on insert. The value keeps the fractional digits of the default, as the
  server does: `CURRENT_TIME` and `LOCALTIME` without a precision no longer get
  milliseconds.
- A BOOLEAN parameter set with `AsString := 'true'` / `'false'` before `Prepare`
  raised "Invalid data conversion".
- `AsQuad` assigned after a long `AsString` was replaced by the string at the
  execute.
- User transaction kinds saved in the transaction editor shifted to another
  kind when a predefined kind was added.
- `DBParamByDPB` with a code above 83 (such as `isc_dpb_config`) read an empty
  value and wrote a parameter with a name out of the table range.
- `TpFIBDatabase`: an alias did not read back its `CLIENT_LIB` into
  `LibraryName`. Aliases saved by earlier versions usually hold `gds32.dll`,
  see the upgrading guide.
- `TpFIBDatabase.OnErrorRestoreConnect` got an uninitialized `DoRaise`.
- `TpFIBDatabase.InRestoreConnect` stayed `True` after a successful restore or
  a reconnect during the wait, and `TransactionID` returned 0 for transactions
  started after it. It was cleared while the timer waited again after a failed
  attempt, and the timer kept running when `OnErrorRestoreConnect` chose to
  stop.
- `TpFIBDatabase.ApplyUpdates` raised an access violation for an empty array
  and read invalid memory for a dataset that is not a `TFIBCustomDataSet`.
- `TpFIBDatabase` saved the schema cache (`AutoSaveToFile`) on `ForceClose`
  when not connected.
- `TpFIBDatabase.WaitForRestoreConnect` read 0 and `laWaitRestore` did nothing
  until code assigned the property; the default 30000 now applies. Forms
  saved by earlier versions without a value set store
  `WaitForRestoreConnect = 0`, which keeps the timer off.
- `TpFIBNRestoreService.Restore` read one element past the end of the file
  array.
- `TpFIBBackupService` and `TpFIBRestoreService`: a `name=length` line sent a
  length cut to as many digits as the name has characters.
- Service `Params` entries (`ServiceParamBySPB`, login dialog) were looked up
  case-sensitively, and `password` also matched `password_enc`.
- `FixLimboTransactionErrors` raised an access violation after
  `FetchLimboTransactionInfo` returned entries. `LimboTransactionInfoCount`
  and `UserInfoCount` returned -1 for an empty list; `LimboTransactionInfo`
  and `UserInfo` raise `EListError` for an index out of range instead of
  returning `nil`.
- `FixLimboTransactionErrors` rolled back the transactions with
  `RecoverTwoPhaseGlobal`; it now sends them to two-phase recovery.
- `TpFIBSecurityService`: `SecAdmin` was sent only when its value changed, so
  setting it again on the next `AddUser` or `ModifyUser` had no effect, and a
  failed call cleared the properties. Setting `SecAdmin` is now always sent;
  the properties, `SecAdmin` included, are cleared only after a successful
  call.
- `TpFIBQuery.ExecProcedure` wrote two spaces between `EXECUTE` and `PROCEDURE`.
- `BatchOutputRawFile` ignored its `Version` argument and always wrote version 3.
- `TFIBTimeField` and `TFIBDateTimeField` with `ShowMsec` wrote milliseconds
  without leading zeros: 5 ms showed as `.5` instead of `.005`.
- `RecordFieldAsFloat` read past the last record for `RecNumber = RecordCount`,
  and on a filtered dataset for a visible number past the end; it returns 0.
- `TBlobSwapSupport` could not be assigned (`TFIBDatabase.BlobSwapSupport`).
- `AutoUpdateOptions.Assign` did not copy `UseExecuteBlock`, `UseReturningFields`
  and `UseRowsClause`, and left `KeyFieldList` empty. Assigning the
  `AutoUpdateOptions` property replaced the object instead of copying it, which
  leaked the old one and freed the shared one twice.
- `CharacterSet` of a text BLOB column returned the charset with the BLOB
  subtype as ID (`OCTETS`), and numeric columns returned `NONE`, `OCTETS` or
  `ASCII`; columns that are not CHAR, VARCHAR or text BLOB return `UNKNOWN`.
- `TFIBSQLMonitor.Release` raised an access violation before the first traced
  event, and the monitor was never freed while no monitor reader was active.
  Queries traced from several threads could free the SQL monitor writer thread
  while another thread used it; freeing the last monitor could hang; messages
  left at shutdown leaked.
- SQL monitor: the fields of a fetch trace are on separate indented lines, as
  the parameters of an execute trace; a failed prepare names the query with
  its full owner path, as a failed execute.
- `TpFibErrorHandler`: assigning `ErrorLexems` did not copy `Exception` and
  `At`; lexems of another length than the default cut the exception message
  in the wrong place; `ExceptionName` kept the value of an earlier exception.
- `Database.SQLLogger := nil` left the logger attached, so statistics were
  still collected; moving a logger to another database left it on the first.
- `TSIBfibEventAlerter`: the error for too long event names said they were
  truncated; they are not.
- `TpFIBScripter`: `StopStatementNo` was not set by a pause at the last
  statement and kept the value of an earlier run; `ExecuteScript(0)` raised an
  access violation.
- `TpFIBScripter`: `OnExecuteError` got an undefined `DoRollBack` for
  `CONNECT`, `CREATE DATABASE` and `COMMIT`, and was not called for
  `DROP DATABASE`; a failed `COMMIT` is kept when the handler sets `DoRollBack`
  to `False`.
- `TpFIBScripter`: a resumed run lost the `INSERT` used by `REINSERT`,
  `SET SQL DIALECT` and `SET NAMES`; a pause set before `INPUT` was ignored.
- `TpFIBScripter` with `UseExecBlockForDML`: an error in the last
  `EXECUTE BLOCK` always propagated, without `OnExecuteError`.
- `TpFIBScripter` with `UseExecBlockForDML`: `OnExecuteError` and
  `AfterStatementExecute` of a block reported the statement after the block,
  which ran even when `Stop` was set; they report the last statement of the
  block, and `AfterStatementExecute` is called once per block.
- `TpFIBScripter` with `UseExecBlockForDML`: after a pause, and after
  `ExecuteStatement` outside a run, the pending block was sent only by the next
  run, even of another script.
- `TpFIBScripter` with `UseExecBlockForDML`: a statement too long for a block
  was dropped; `EXECUTE BLOCK` and `EXECUTE PROCEDURE` statements were nested
  into a block.
- `TpFIBClientDataSet.TransactionIsActive` always raised "Invalid argument":
  `TpFIBDataSet` did not return the transaction state to the client. After a
  failed `Commit` or `RollBack`, the next execute without a command text ran
  the commit or rollback again instead of the dataset's SQL.

## [7.9.0] - 2026-10-01

First release of the community maintained FIBPlus. It is based on the last
Devrace sources (FIBPlus 7, build 632, 2014-02-17) and includes all the changes
made since the repository was created in November 2016.

### Added

#### Firebird 3, 4 and 5 support

- Data types of Firebird 3/4+: `BOOLEAN`, `INT128`, `NUMERIC`/`DECIMAL(19..38)`,
  `DECFLOAT(16/34)`, `TIME`/`TIMESTAMP WITH TIME ZONE` in queries, parameters
  and datasets ([#90](https://github.com/madorin/fibplus/pull/90)).
  - New unit `FIBTypes`: `INT128` and `DECFLOAT` conversions to and from
    `TBcd`, `Int64`, `Currency`, `Double` and strings, time zone helpers.
  - `TFIBXSQLVAR`: `AsTimeZoneID`, `AsTimeZoneOffset`, `AsTimeZoneName`,
    `AsUTCDateTime`, `SetAsDateTimeTZ` and raw setters for the new types.
  - `TFIBFMTBCDField` for `ftFMTBcd` fields, reading NaN/Infinity and values
    out of the `TBcd` range.
  - DPB parameters `session_time_zone`, `set_bind`, `decfloat_round`,
    `decfloat_traps`; metadata DDL for the new types.
- `LOCALTIME` and `LOCALTIMESTAMP` column defaults
  ([#87](https://github.com/madorin/fibplus/issues/87)).
- Identifiers of up to 63 characters (Firebird 4+) for columns, parameters,
  relation aliases, array columns, the field repository and the editors.
- `TFIBDatabase.Capabilities` with `MaxIdentifierLength`, and
  `IIBClientLibrary.Version` with the product and version of the client
  library.
- `TFIBDatabase.CryptKey` and `OnCryptKeyRequest` to pass the key of a database
  encrypted with a Firebird 3+ crypt plugin from the client
  ([#45](https://github.com/madorin/fibplus/issues/45)).
- `TFIBDatabase.ConfigParam[Name]`, `config=Name=Value` lines in `DBParams` and
  `ConnectParams.WireCompression` ([#49](https://github.com/madorin/fibplus/issues/49)).
- `TFIBDatabase.CreationDate` ([#19](https://github.com/madorin/fibplus/issues/19)).
- SQL reserved keywords up to Firebird 5.0 and the Firebird 3 internal
  functions in `StrUtil` ([#52](https://github.com/madorin/fibplus/pull/52)).
- Array parameters of `TFIBQuery` (`AsVariant := VarArrayOf([...])`,
  `SetArrayValue`).
- `TFIBXSQLVAR.GetArrayElement` for arrays of any number of dimensions.

#### IDE and packages

- Packages for Delphi XE6, XE7, XE8, 10 Seattle, 10.1 Berlin, 10.2 Tokyo,
  10.3 Rio, 10.4 Sydney, 11 Alexandria, 12 Athens and 13 Florence.
- Separate runtime and design time packages (`FIBPlus_Dxx`, `DclFIBPlus_Dxx`,
  `FIBPlusEditors_Dxx`), Win64 target support
  ([#33](https://github.com/madorin/fibplus/issues/33),
  [#64](https://github.com/madorin/fibplus/issues/64)).
- Russian resources ([#3](https://github.com/madorin/fibplus/pull/3)).
- Sample applications and documentation collected from public forums.
- Installation steps in README ([#66](https://github.com/madorin/fibplus/issues/66)).

### Changed

- The library sources moved to the `Source` folder and the editors to
  `Source\Editors`. Replace the library root with `Source` in the Library path.
- `SQL_BOOLEAN` in `ibase.pas` is now `32764` (Firebird 3 `BOOLEAN`) instead of
  `590` (InterBase). InterBase code must use `IB_SQL_BOOLEAN`.
  `FB3_SQL_BOOLEAN` is a deprecated alias of `SQL_BOOLEAN`.
- `TFIBXSQLVAR.AsBoolean` of a number is `True` for any non-zero value.
- `AsDouble` and `AsTime` assigned before `Prepare` are applied once the server
  type is known; a `Double` assigned to a date/time parameter is converted as
  `TDateTime`.
- Firebird 4+ types need a Firebird 4+ client library; with older clients use
  `set_bind=TIME ZONE TO LEGACY`.
- `TFIBQuery` applies `qoAutoCommit` and `qoFreeHandleAfterExecute` when the
  cursor is done (Eof, Close, SQL change, next `ExecQuery`, Free). Changing the
  SQL of an open query closes it. `GoToFirstRecordOnExecute` fetches before
  `AfterExecute` again, as in 7.5 ([#4](https://github.com/madorin/fibplus/issues/4),
  [#9](https://github.com/madorin/fibplus/issues/9)).
- `TpFIBStoredProc` builds its SQL when the database is connected instead of
  when `StoredProcName` is set ([#70](https://github.com/madorin/fibplus/pull/70)).
  `TpStoredProcCollect` is renamed to `TFIBStoredProcMetadataCache`.
- `TpFIBScripter`: the script parser is rewritten. Several statements on a line,
  `EXECUTE BLOCK` and PSQL modules with the `;` terminator, multi-character
  `SET TERM` terminators and directives in `ExecuteFromFile` are supported
  ([#88](https://github.com/madorin/fibplus/pull/88),
  [#42](https://github.com/madorin/fibplus/issues/42)).
- Array field values are kept on the client until `Post`, like BLOB values, so
  `Cancel` and `CachedUpdates` work for arrays. `TpFIBArray` works on buffers of
  the whole array.
- String parameters encoded in UTF-8 are declared as `UTF8` instead of
  `UNICODE_FSS` on Firebird 2.0+ and InterBase 2007+
  ([#53](https://github.com/madorin/fibplus/issues/53)).
- The schema cache reads the table metadata with fewer queries
  ([#74](https://github.com/madorin/fibplus/issues/74)).
- `TFIBDatabase.AttachmentID` returns `-1` while the database is not connected.
- `CancelOperationFB21` works on Firebird 3.0 and later.
- `TpFIBClientDataSet`, `TpFIBDataSetProvider` and `TpFIBClientBCDField` are
  registered by the design time package ([#51](https://github.com/madorin/fibplus/issues/51)).
- Packages build in the Release configuration by default; DCU files go to
  `.\$(Platform)\$(Config)`.
- Delphi sources use CRLF line endings through `.gitattributes`
  ([#84](https://github.com/madorin/fibplus/issues/84)).
- `TFIBDatabase.ClientMajorVersion`, `ClientMinorVersion`,
  `IIBClientLibrary.ClientVersion` and `SQL_DATE` are deprecated.
- Names over 31 bytes (Firebird 4+) come in full: persistent fields and
  `FIB$FIELDS_INFO` rows saved with the cut or `F_n` names must be renamed.
  With a Firebird 3 or older client, preparing a query costs one more round
  trip on Firebird 4+ servers.
- The raw export of `FIBMiscellaneous` writes non-ASCII names in the system code
  page; files written before are read as before.
- `TpFIBArray.Dimension` raises for bounds outside -32768..32767 instead of
  cutting them.
- `qDefaultFields` is removed, use `DefaultFields`.
- Version constants: `FIBMajorVersion`, `FIBMinorVersion`, `FIBRelease` and
  `FIBVersionString` replace `FIBPlusVersion`, `FIBPlusBuild` and
  `FIBCustomBuild`; `pFIBVersion.inc` is renamed to `FIBVersion.inc`.

### Removed

- Support for compilers older than Delphi 6 and the non-functional
  C++Builder-only packages; C++Builder uses the files generated by the Delphi
  packages.
- MDT (Mirror Dataset Tools).
- The unfinished SQL help viewer of the SQL editor.
- `CycleReadArray` and `CycleWriteArray` of `VariantRtn`.

### Fixed

#### Connection and client library

- `fb_shutdown` is called before the client library is unloaded
  ([#17](https://github.com/madorin/fibplus/issues/17)).
- Stack overflow in `TpFibErrorHandler` on a database shutdown; lost
  connections on Firebird 3+ are detected
  ([#24](https://github.com/madorin/fibplus/issues/24)).
- `AttachmentID` kept the ID of an old attachment after a reconnection
  ([#34](https://github.com/madorin/fibplus/issues/34)).
- Data event parameter type on Win64.
- Packages support check of `pFIBMetaData` ([#12](https://github.com/madorin/fibplus/issues/12)).

#### Queries and parameters

- Statements with `qoAutoCommit` failed on the first fetch or were never
  committed ([#4](https://github.com/madorin/fibplus/issues/4),
  [#9](https://github.com/madorin/fibplus/issues/9)).
- Long string parameters set before `Prepare` were not encoded, "Malformed
  string" on UTF8 BLOBs ([#54](https://github.com/madorin/fibplus/issues/54)).
- Characters outside the BMP (e.g. emoji) stored corrupted in UTF-8 parameters
  ([#53](https://github.com/madorin/fibplus/issues/53)).
- "Invalid pointer operation" and missed lookups in the query cache
  ([#62](https://github.com/madorin/fibplus/issues/62)).
- `TpFIBStoredProc` failed when the database was not connected, mixed up the
  parameters of procedures after a failed read and returned no parameter
  defaults on Firebird 2.0+ ([#70](https://github.com/madorin/fibplus/pull/70)).
- Firebird 3 `BOOLEAN` read and written through `AsBoolean` and `AsVariant`
  ([#63](https://github.com/madorin/fibplus/pull/63),
  [#27](https://github.com/madorin/fibplus/issues/27)).
- `NUMERIC(18)` values lost their last digits on Win64.
- Column names longer than 31 bytes were cut or replaced with `F_n`.

#### Datasets and fields

- Memory corruption and wrong values in field `OnValidate`
  ([#83](https://github.com/madorin/fibplus/issues/83),
  [#77](https://github.com/madorin/fibplus/issues/77),
  [#57](https://github.com/madorin/fibplus/issues/57),
  [#30](https://github.com/madorin/fibplus/issues/30)).
- `InsertRecord` and `AppendRecord` did nothing
  ([#36](https://github.com/madorin/fibplus/issues/36)).
- Stack overflow when posting the master from the detail `BeforePost`
  ([#8](https://github.com/madorin/fibplus/issues/8)).
- Automatic fields with `CloseOpen` and `CreateCalcField`
  ([#58](https://github.com/madorin/fibplus/pull/58),
  [#10](https://github.com/madorin/fibplus/issues/10)).
- `RefreshFromQuery` and `RefreshFromDataSet` appended records, raised access
  violations and lost the current record ([#59](https://github.com/madorin/fibplus/issues/59)).
- Unbalanced `DisableControls` in `GotoBookmark` with an invalid bookmark
  ([#79](https://github.com/madorin/fibplus/issues/79)).
- Bookmarks with `TIME`/`TIMESTAMP` key fields in limited cache mode.
- BLOB values lost on `Cancel` after `Post` and with `BlobCacheLimit`.
- Sorting with an empty list of fields ([#23](https://github.com/madorin/fibplus/issues/23)).
- `TFIBBCDField.GetAsVariant` for small sizes ([#26](https://github.com/madorin/fibplus/issues/26)).
- `TpFIBClientBCDField.Value` returned 0 instead of Null
  ([#71](https://github.com/madorin/fibplus/issues/71)).
- `TFIBWideStringField.GetAsString` of calculated and lookup fields
  ([#73](https://github.com/madorin/fibplus/issues/73)).
- `TFIBWideStringField.CopyData` and `AsNativeData`/`AsOctetsData` overwrote
  the record buffer.
- Field defs size regression in `InternalInitFieldDefs`.
- Missing `override` of `SetBookmarkData` ([#13](https://github.com/madorin/fibplus/pull/13)).
- Limited buffer cache mode, broken by the MDT removal
  ([#48](https://github.com/madorin/fibplus/issues/48)).
- Default time format ([#18](https://github.com/madorin/fibplus/pull/18)).

#### Local filters

- `IN` lists with more than about 40 values and function arguments
  ([#85](https://github.com/madorin/fibplus/issues/85)).
- Unicode characters in single-value lists, e.g. `UPPER(NAME) = '...'`
  ([#5](https://github.com/madorin/fibplus/issues/5)).
- A function of NULL raised a conversion error; `SUBSTRING` with a start
  position below 1 or without length.
- Out of memory in `TrimPositions` ([#50](https://github.com/madorin/fibplus/issues/50)).

#### Array fields

- Posting a changed array field failed on Firebird 3+ with "Unsupported
  conversion to target type ARRAY".
- Element conversion of `FLOAT`, scaled `NUMERIC`/`DECIMAL`, `BIGINT`,
  milliseconds of `TIME`/`TIMESTAMP` and `CHAR`/`VARCHAR` elements.
- `isc_array_get_slice` truncated the pointer on Win64; errors of the array
  calls were not checked.
- NULL arrays, values with wrong dimensions, string elements of single byte
  character set columns on UTF8 connections.
- Array descriptors of reused query variables.

#### Scripter

- Statements terminated on a line after an empty line were not executed
  ([#88](https://github.com/madorin/fibplus/pull/88)).
- `EXECUTE BLOCK` and PSQL subroutines split at `;`
  ([#42](https://github.com/madorin/fibplus/issues/42)).
- Directives, comments and lines over 65535 characters.

#### Schema cache and repository

- Cache file loaded and deleted on every other start with
  `ValidateAfterLoad` ([#74](https://github.com/madorin/fibplus/issues/74)).
- `ValidateSchema` validated the entries of other databases
  ([#74](https://github.com/madorin/fibplus/issues/74)).
- Repository state reused by a new database component at the same address.

#### Packages and editors

- Custom field classes not registered after the package split
  ([#39](https://github.com/madorin/fibplus/issues/39)).
- Unit paths of the Delphi 2007/2010 packages
  ([#6](https://github.com/madorin/fibplus/pull/6),
  [#28](https://github.com/madorin/fibplus/issues/28)) and unused references
  ([#11](https://github.com/madorin/fibplus/issues/11)).
- `UnitSyntaxMemo` references ([#69](https://github.com/madorin/fibplus/issues/69)).
- Editor cursor not shown in older Delphi versions
  ([#80](https://github.com/madorin/fibplus/issues/80),
  [#81](https://github.com/madorin/fibplus/pull/81)).
- Compiler warnings and hints ([#15](https://github.com/madorin/fibplus/pull/15)).

[7.9.1]: https://github.com/madorin/fibplus/releases/tag/v7.9.1
[7.9.0]: https://github.com/madorin/fibplus/releases/tag/v7.9.0
