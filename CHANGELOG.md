# Changelog

## [8.0.0] - Unreleased

### Added

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
- The design time packages `dclFIBCore` and `dclFIBTools` can be installed in
  the 64-bit IDE of Delphi 12.3 and 13 (Win64 platform).

#### Schema extract

- `TFIBDBSchemaExtract` and `FullExtractDDL` write the descriptions as
  `COMMENT ON` (database, domains, tables and views with their columns,
  indices and triggers, procedures and functions with their parameters,
  generators, exceptions, external functions, roles, packages with their
  procedures and functions, database triggers): in a `COMMENTS` section before
  the final `COMMIT WORK` of `GetDDLText`, and after the DDL of the object in
  `GetObjectDDL` and `AsDDL`. They are written while `DDLTextOptions` has the
  new option `dtoIncludeComments` (on by default) and the server has
  `COMMENT ON` (Firebird 2.0 and later). The meta objects have a `Description`
  property. A description longer than a string literal in the charset of the
  connection (65535 bytes on Firebird 3 and later, a 65533 bytes statement
  before) is written as a `/* ... */` note, since `COMMENT ON` takes only a
  literal.
- `TMetaPackage.Procedures` and `Functions` (with `ProceduresCount` and
  `FunctionsCount`): the routines of a package, with their parameters.

#### Errors

- `EFIBError.ErrorArgument(Code, Index)`: a string argument of the status
  vector, for example the constraint name of `isc_unique_key_violation`.

#### Scripter

- `TFIBScripter.ExecuteFromFile(FileName, Encoding)` reads a script file without a byte order
  mark in the given encoding (e.g. `TEncoding.UTF8`); a UTF-8 or UTF-16 BOM still selects the
  encoding, and its `INPUT` files get the same encoding.

#### Events

- `TFIBEventAlerter.OnError(Sender, E)` receives the errors of a running event thread (a lost
  connection), in the main thread when `VCLSynchronize` is `True`. Without a handler the error
  goes to `Classes.ApplicationHandleException` in the main thread (`Application.OnException` or
  the error dialog) instead of `SysUtils.ShowException`; with `VCLSynchronize = False`, or
  without an application object, it is still shown with `SysUtils.ShowException`.

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
- A failed reconnect raises: `AutoReconnect` and `CheckActive(True)` raise the
  error of the last connect attempt (it was swallowed), and `StartTransaction`
  raises `feDatabaseClosed` when a database is still not connected (it
  returned with the transaction inactive), also while a form loads in the IDE.
  `Commit`, `Rollback` and the retaining variants of an inactive transaction
  raise `feNotInTransaction` before `BeforeEnd` (with `AutoReconnect` and at
  design time they started and ended a transaction), and `CheckInTransaction`
  no longer starts the transaction; queries still start it as before. See
  [Upgrading](Docs/guide/upgrading.md#failed-reconnects-and-inactive-transactions).
- `TFIBErrorHandler` runs the lost-connection action on the database of the
  failing object (a database, a query, a transaction or a BLOB stream) for every
  `TFIBDatabase`. Without a database it pings each connected database and acts
  only on those that report a lost connection, instead of on every database of
  the process; a lost service connection closes no database.

#### Events

- `TFIBEventAlerter.RegisterEvents` queues the first events in the calling thread, before the
  event threads start: an error (an invalid handle, a server whose events port can't be reached)
  raises from `RegisterEvents` and `Registered := True`, and the groups already queued are
  cancelled. With `AutoRegister` the error raises from `Database.Open`, with the database
  connected; see [Upgrading](Docs/guide/upgrading.md#event-registration-errors).

#### Client library

- `TFIBDatabase.ClientMajorVersion` and `ClientMinorVersion` (deprecated) return
  `isc_get_client_major_version`/`isc_get_client_minor_version` of the client library: the same
  values, but a client without these functions (InterBase 6.0 and older) raises an error; see
  [Upgrading](Docs/guide/upgrading.md#800).

#### Build

- The packages are renamed: the runtime package is `FIBCore` (`FIBCore_Dxx`
  before 10.4) and its design time package `dclFIBCore` (`dclFIBCore_Dxx`),
  with `dcl` before the name of the runtime package, as in Delphi and other
  libraries; the editors packages are merged into it. The old and new names
  are in [Upgrading](Docs/guide/upgrading.md#packages).
  - Delphi 10.4 and later have one package of each kind for all versions,
    through `{$LIBSUFFIX AUTO}`, in `Packages\FIB.groupproj`: `FIBCore`
    (`FIBCore270.bpl` to `FIBCore370.bpl`), `dclFIBCore`, `dclFIBTools` (was
    `FIBTools`) and `FIBFMX` (was `FIBPlusFMX`), which is also built for
    Delphi 10.4 to 12.
  - Delphi 2009 to 10.3 Rio have `FIBCore_Dxx` and `dclFIBCore_Dxx`, named
    after the package version, from `FIBCore_D12` (Delphi 2009) to
    `FIBCore_D26` (10.3 Rio), in `FIB_Dxx.groupproj`. The duplicate packages
    of Delphi XE7 are merged into `FIBCore_D21` and `dclFIBCore_D21`.
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
- The packages write DCU files to `$(BDSCOMMONDIR)\Dcu\FIB\$(Platform)\$(Config)`
  instead of `$(BDSCOMMONDIR)\Dcu\FIBPlus\$(Platform)\$(Config)`.

#### Types and signatures

- On Delphi XE6 and later `TFIBDataSet` no longer redeclares `DefaultFields`:
  the `TDataSet` function gives the same result and the compiler reports it as
  deprecated, use `Fields.LifeCycles`. Delphi 2009 to XE5 keep the property.
- `TFIBDataSet.FetchNext` takes an `Integer` count (was `DWORD`), like
  `RecordCount`: a negative count fetches no row (it fetched all the rows).
  `ISQLStatMaker.FixStartTime` and `TTestInfo.FixStartTime` return the tick
  count as `Cardinal` (was `Integer`).
- On Delphi XE3 and later `TFIBCustomDataSet` and `TFIBClientDataSet` override only the
  `TValueBuffer` overload of `DataConvert` (the deprecated `Pointer` one stays for Delphi 2009
  to XE2), and on XE4 and later `TFIBCustomDataSet` overrides `GetCalcFields(TRecBuf)` instead
  of `GetCalcFields(TRecordBuffer)`. Code calling the deprecated `TField.GetData`/`SetData`
  with a pointer and `NativeFormat = False` gets the `TDataSet` conversion; see
  [Upgrading](Docs/guide/upgrading.md#800).
- Text types: `TFIBDatabase.AliasName`, `DBFileName` and `DBSiteName`,
  `TFIBCustomService.ServerName`, `TFIBRestoreService.FixCharset`, `SPBConstantNames`,
  `TFIBBlobStream.TableName` and `FieldName` are `string` (were `AnsiString`), and so are the
  file name of `TFIBQuery.BatchInputRawFile`/`BatchOutputRawFile`, the column of
  `TFIBInputDelimitedFile.GetColumn` and the name and value of `StrUtil.GetNameAndValue`. The
  protected `ServiceStartAddParam` takes a `string` and encodes it; `GenerateTPB` has a new
  `NameCodePage` parameter (default the system code page); see
  [Upgrading](Docs/guide/upgrading.md#800).
- `FIBAlloc` takes `NativeInt` sizes (was `DWORD`). `TFIBCustomTimer.Interval` (`FIBSafeTimer`,
  alias `TFIBTimer` in `StdFuncs`) and `TFIBDataSet.WaitEndMasterInterval` are `Cardinal` (were
  `Integer`), like `TTimer.Interval`. `IIbClientLibrary.isc_interprete` and `fb_Interpret` return
  `ISC_LONG` (were `ISC_STATUS`, 64 bits on Win64), as the client library. The `Length` of
  `SIB_QueEvents` and `SIB_EventCounts` is `SIB_Short` (was `SIB_UShort`), as in the client API.
  `SIB_Status` (`SIBAPI`) is `ISC_STATUS` (was `SIB_Long`, 32 bits on Win64), so the event status
  vector has the entries the client writes. `IIBClientLibrary.isc_event_counts` and
  `Tisc_event_counts` take a `PUISC_LONG` (was `PISC_STATUS`), as `ISC_ULONG*` in the C header,
  and `SIB_EventCounts` a `SIB_PEventCountVector`.
  `TFIBDatabase.IsMemoSubtype` and `TMemoSubtypes.IsMemoSubtype` take a `SmallInt` (was
  `ShortInt`), and `TFIBFieldDescrList.LoadFromStream` an `Integer` version (was `Byte`).

#### Queries and errors

- `TFIBQuery.BatchOutput`, `BatchOutputRawFile` and `TFIBDatabase.Execute` raise their errors
  instead of returning `False` (`Execute` always returns `True`); `BatchOutput` and `BatchInput`
  return `False` only when there is nothing to do (another statement type, stream not ready).
  A charset mismatch in `BatchInput` raises `EFIBClientError` (`feBatchCharsetMismatch`)
  instead of `Exception`, and `ExecWPS(ParamSource, True)` calls `OnBatching` and runs the row
  again on `beRetry`, as `BatchInput`. `TFIBDatabase.CreateGUIDDomain` creates the domain only
  when it doesn't exist, and raises the other errors; see
  [Upgrading](Docs/guide/upgrading.md#batch-and-execute-errors).
- `AsString`, `AsAnsiString` and `AsWideString` of a BLOB column raise the read error, as
  `TBlobField.AsString`, instead of returning `(BLOB)`; a BLOB parameter without a value returns
  an empty string; see [Upgrading](Docs/guide/upgrading.md#blob-text-read-errors).

#### Fields

- `AsInt64` of `TFIBBCDField` rounds half to even, as `TBCDField.AsLargeInt` (it truncated).
  `TFIBClientBCDField.AsInt64` rounds the same way, now exactly, without going through
  floating point.
- `DisplayFormat` and `EditFormat` of `TFIBBCDField` and `TFIBClientBCDField` round half to even,
  as `TBCDField` and `TFMTBCDField` do: `0` on 2.5 gives `2`, on 3.5 `4` (it rounded half up).
  All the decimals of the value are used, not 4 as by `Currency`.
- `DisplayText` of `TFIBBCDField` and `TFIBClientBCDField` with a `DisplayFormat` (and `Text`
  with an `EditFormat`) is about 2.5 times faster: `FormatNumericString` (`StdFuncs`) rounds the
  value once and builds the text without copying the format sections.

#### Schema extract

- `TFIBDBSchemaExtract.DDLTextOptions` is `[dtoIncludeComments]` by default
  (was `[]`), and `TMetaDataBase` and `ExtGenerateDDLText` use
  `DefDDLTextOptions` (`dtoIncludeComments` added). Forms saved with
  `DDLTextOptions = []` keep writing no comments; see
  [Upgrading](Docs/guide/upgrading.md#800).
- `TMetaGenerator.Value` is `Int64` (was `Integer`). `FieldsCount` and the
  index of `Fields` of `TMetaConstraint` (primary keys, unique constraints,
  indices, foreign keys), and `ForFieldsCount` and `ForFields` of
  `TMetaForeignKey`, are `Integer` (were `Word`), as in the rest of the meta
  objects.

#### Editors

- The editors, the login dialog and the samples use Segoe UI instead of
  MS Sans Serif, a bitmap font without anti-aliasing; their layouts are
  adjusted to the new font.
- The dialogs of fixed size (connection, transaction, dataset options and the
  others) no longer remember their size and position and open centered on the
  screen; the resizable editors still do, also when maximized, and a saved
  position outside the screen is moved onto it.

#### Samples

- The descriptions of the samples, and how to create the demo database, are in
  [Samples/README.md](Samples/README.md) instead of the Word documents in
  `Samples\doc`.
- All samples connect to the Firebird alias `localhost:fibplus_samples`, set
  once in `Samples\src\FIBExamples.inc`, instead of fixed database paths.
- `BlobFilters` compresses with `System.ZLib` instead of the bundled PasZLib,
  which no longer compiled. `DataSetRepository` has a project file and is in
  the project group, and the **Execute** check box of `SQLMonitor` turns the
  execute trace on and off by its own state instead of that of **Prepare**.

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
- `TMetaTable.GenerateDDLTextOnlyTable` (protected): use `GenerateObjectDDL`.
- `StrUtil.TFastStringStream`: the DDL methods of `FIBMetaData`
  (`GenerateDDLText`, `GenerateObjectDDL` and the others) take a
  `TStringStream`; see [Upgrading](Docs/guide/upgrading.md#800).
- `TFIBLicensingService` (InterBase license keys) and the units `IB_Install` and
  `IB_InstallHeader` with `TpFIBInstall` and `TpFIBUnInstall` (InterBase 6 install
  library `ibinstall.dll`, never registered: `IBINSTALL_SUPPORT` was off) with their
  messages in `FIBConsts`. Firebird has neither; see
  [Upgrading](Docs/guide/upgrading.md#800).

### Fixed

#### Connection and transactions

- `utf8_filename` in `DBParams` was sent, but the database name, user name,
  password and role stayed in the system code page, so non-ASCII values were
  garbled or rejected. With `utf8_filename` they are now sent in UTF-8, and
  `TFIBDatabase.DBName` keeps characters outside the system code page. The
  Firebird client still converts the file name to the system code page before
  it parses it.
- A `DBParams` value over 255 bytes (several `config=` lines, or a long non-ASCII
  password with `utf8_filename`) had its one-byte length wrapped and made a
  corrupt DPB. With a Firebird 3+ client the DPB is now sent as
  `isc_dpb_version2` (4-byte lengths) when a value needs it; otherwise, and for
  long lock table names in `TRParams` and values in the `TFIBServices` `Params`,
  a clear error names the parameter.
- Numeric `DBParams` (`num_buffers`, `dummy_packet_interval`,
  `connect_timeout`, `old_file_size`, `shutdown_delay`, `force_write` and the
  other flags) were written in one byte, so a value over 255 was cut
  (`num_buffers=2048` sent 0). They are now written in 4 bytes.
- A quoted role name in `DBParams` (`sql_role_name="MixRole"`) lost its case and
  the connection had no role: without a dialect in the DPB the server takes
  dialect 1 and uppercases it. `SQLDialect` is now sent in the DPB, unless
  `DBParams` has `sql_dialect`. A role without quotes is still uppercased; see
  [Upgrading](Docs/guide/upgrading.md#role-name-in-quotes).
- `lock_read`/`lock_write` table names in `TRParams` were sent in the system code page; the
  server takes them in the charset of the connection, so a non-ASCII table name was not found or
  was a malformed string. They are now sent in the metadata code page of the connection, and in
  UTF-8 to Firebird 2.1 to 2.5, which look them up in the stored names without converting them.
- `TFIBTransaction`: the transaction parameters were not rebuilt when the connection reopened
  with another charset, so the `lock_read`/`lock_write` table names kept the old code page; a
  database of a multi-database transaction without its own parameters got the names in the code
  page of `MainDatabase`.
- `TFIBTransaction`: `lock_timeout` was sent in 2 bytes, so a value from 65536 up was cut
  (65546 started the transaction with a timeout of 10 seconds). It is sent in 4 bytes; Firebird 2.5
  and later check the range.
- `LibraryName` of `TFIBDatabase` went through the system code page: a client library in a
  folder with a name outside it could not be loaded.
- macOS: the client library was never unloaded, neither by `IIBClientLibrary.FreeIBLibrary` nor
  at program exit.
- `DBParams`: a last `shutdown` value of one character (`shutdown=2`) was ignored, and an unknown
  word or a word with spaces (`shutdown=force, full`) set every bit of the value. The words are
  now trimmed; an unknown word or a number over 255 raises the new `feParamValueInvalid`.
- Without `utf8_filename`, a `DBParams` value or a `DBName` with a character outside the system
  code page was sent with `?` in its place (a non-ASCII password failed as a wrong password). It
  raises the new `feCantTransliterateParam`, which names the parameter but not the value; see
  [Upgrading](Docs/guide/upgrading.md#characters-outside-the-system-code-page).
- `TFIBDatabase.CreateDatabase` sent a character of `DBName` or `DBParams` outside the system
  code page as `?` (a wrong file name or password); it raises `feCantTransliterateParam` too.
- `TFIBDatabase.QueryValues` of a statement without parameters (also `EXECUTE PROCEDURE`) kept it
  in the query cache when it returned a row, while `QueryValue` freed it. Only a statement with
  parameters is cached now, as documented; `aCacheQuery` allows the caching.

#### Queries and parameters

- `TFIBQuery` fields and parameters: `AsInteger` of a `BIGINT`, a scaled number or a double out of
  the `Integer` range, and `AsShort` out of the `SMALLINT` range, returned a cut value
  (5000000000 gave 705032704); they raise an invalid data conversion error, as for `INT128`.
- `TFIBQuery` parameters: `Assign` of a BLOB of more than 32767 bytes to a parameter that is not
  a BLOB sent a cut length (70000 bytes became 4464); it raises an error now. `AsInt64` in SQL
  dialect 1 or 2 sent the value cut to 32 bits; out of that range it is sent as a double. A
  `LongWord` variant over `MaxInt` was sent as a negative number when passed by reference and
  raised `EVariantOverflowError` when passed by value; both are sent as a `BIGINT`.
- A string over 32767 bytes for a `VARCHAR` parameter was sent as a blob of the
  column charset subtype, so the server reported "Filter not found to convert
  type 4 to type 1" instead of a string truncation.
- A text BLOB parameter set with `AsString` before `Prepare` read `(BLOB)`
  after `ExecQuery`; it now returns the string, as when it is set after
  `Prepare`.
- `AsInteger`, `AsInt64`, `AsShort` and an integer `AsVariant` on a `BOOLEAN` parameter raised
  "Incompatible column/host variable data type"; a value other than zero is now `True`, as
  `AsBoolean`. Set before `Prepare`, these setters now also convert to the parameter's type, so
  an integer for a `DATE` or `TIMESTAMP` parameter becomes a `TDateTime` day number, as with
  `AsDouble` ([Upgrading](Docs/guide/upgrading.md#integer-parameter-values)).
- A parameter used twice in the statement, once for a BLOB and once for a `VARCHAR` or another
  charset, got the BLOB ID with the subtype of the other column ("Filter not found to convert
  type 4 to type 1"); every occurrence now declares the subtype and charset of the value.
- `StopFetching` in `TFIBQuery.OnSQLFetch` and `BeforeFetchRecord` made `Next`
  return `nil` but left `Eof` at `False`, so a `while not Eof` loop did not end.
  It is now a final stop: `Eof` is set as at the end of the data.
- `TFIBQuery.TransactionEnding` and `TransactionEnded` were published but never called; they are
  now called before and after the transaction of the query ends, as in `TFIBDataSet`.
- `TFIBQuery` fields and parameters of a date, time, number or boolean type: `AsString` passed
  the formatted text through the system code page, so locale texts outside it (for example the
  AM/PM designators) became `?`.
- `AsTimeZoneName` of a `TIME` or `TIMESTAMP WITH TIME ZONE` value in a region
  unknown to the built-in time zone table was empty, and `AsString` ended with
  a blank. It is now the offset of the value (`+02:00`).
- Macros: an old form macro (`@Name`) followed by a tab took the rest of the
  text up to the next space into its name, and one at the very end of the text
  was not replaced. A new form macro (`@@Name@`) without the closing `@` went
  to the server as it was; it now raises "EOF in macro detected".
- `TFIBInputDelimitedFile` read the UTF-16 file of `TFIBOutputDelimitedFile` through the system
  code page: characters outside it became `?` or a similar letter. `BatchInputRawFile` and
  `BatchOutputRawFile` could not use a file name outside the system code page.
- The raw batch file kept the column names in the system code page: a name outside it became
  `?` and its parameter was not found, so `BatchInputRawFile` left it `NULL`. Raw file version 4,
  the default of `BatchOutputRawFile`, keeps them in UTF-8; versions 1 to 3 are still read, a
  newer version raises `feFormatVersionNotSupported`; see
  [Upgrading](Docs/guide/upgrading.md#dataset-streams-and-batch-files).
- Win64: `TFIBQuery.BatchOutput` to a `TFIBOutputDelimitedFile` or a raw file
  (`BatchOutputRawFile`) raised an access violation, kept the buffer address in 32 bits, and
  returned `False` with an empty file, so a `BatchInput` from it inserted no row.

#### Datasets and fields

- Win64: `TFIBGuidField.AsGuid` and `AsString` (`GUIDAsString` of `StrUtil`) raised an access
  violation: the destination address was kept in 32 bits.
- `TFIBArrayField.AsBytes` and `AsByteArray` (Delphi XE3 and later) returned wrong bytes and
  wrote past their buffer (the `ftBytes` conversion took the value for an `OleVariant`); they
  return the 8 bytes of the array id.
- `TFIBDataSet`: a value out of range in a persistent float field of a `NUMERIC` stored as
  `INTEGER` or `SMALLINT` (for example 30000000 in a `NUMERIC(9,2)`) was stored cut
  (-12949672.96); it raises an error now. A generator value out of the `INTEGER` range for an
  `INTEGER` key field (`AutoUpdateOptions`) was cut; the field raises an error now.
- `TFIBDataSetProvider`: `RefreshRecord` of the client dataset wrote a NULL `NUMERIC` of the
  source as a number (0 or garbage).
- `ApplyUpdates` of a `TClientDataSet` over a `TFIBDataSet` sent the text `No Action` of
  `InsertSQL`, `UpdateSQL`, `DeleteSQL` or an update object to the server (syntax error); the
  row now counts as applied with nothing sent, and a `No Action` delete runs no update object, as
  a direct post or delete.
- FIBPlus fields in a dataset that is not FIBPlus (e.g. persistent fields copied to a
  `TClientDataSet`): the first read of a `TFIBStringField` could raise an access violation, and
  `TFIBDateTimeField.AsTimeStamp` gave a wrong value in `OnValidate`, or raised `EIntOverflow`
  there when it was assigned. `AsNativeData` and `AsOctetsData` of the string fields wrote into
  the memory of that dataset, `TFIBWideStringField` did not work there at all,
  `TFIBFloatField.Scale` and `AsFloat :=` and `TFIBTimeField.ShowMsec` in `OnValidate` read
  garbage, and the value of a `TFIBArrayField` was lost. `GetBlobInfo`, `Blob_ID` and `ArrayID`
  raise a clear error there.
- `TFIBBCDField.AsBCD :=` rescaled through floating point and stored an out of range value
  without an error; a value with 19 significant digits lost its leading digit. It is exact now,
  rounded half away from zero to the scale of the field, and raises `EOverflow` out of the range.
  `CompareBCD` and `BCDToExtended` (`StdFuncs`) handle values with more than 18 decimals or an
  integer part beyond `Int64`.
- `DisplayFormat` and `EditFormat` of `TFIBBCDField` and `TFIBClientBCDField` with sections or a
  leading literal: the minus sign went after the literal (`$ -1,00`, `FormatCurr` gives
  `-$ 1,00`), a value that rounds to zero took the negative section (`0.0;(0.0)` on -0.004 gave
  `(0,0)`), and an empty negative or zero section did not fall back to the first one.
- `DisplayFormat` and `EditFormat` of `TFIBBCDField` and `TFIBClientBCDField` with quoted text or
  without a `0` before the decimal point: the text was shown with its quotes (`"Neg" 0.0`), a `;`
  in quotes split the sections, and `#.##` kept the zero integer part (`0,05`, `FormatCurr`
  gives `,05`, and an empty text for zero). Text between the digits was dropped (`0" x "0`).
- `DisplayFormat` and `EditFormat` of `TFIBBCDField` and `TFIBClientBCDField` when the value is
  rounded: the zeros of the carry were dropped (`0.00` on 1.296 gave `1.3`, on 0.996 `1`), the
  thousand separators stayed where they were before the carry (`#,##0.00` on 9999.996 gave
  `1.0000`), a format without a decimal point kept one decimal, and literals after the digits
  counted as decimals (`$ #,##0.00 USD` did not round). The trailing zeros of the optional `#`
  decimals are dropped, as by `FormatCurr` (`0.##` on 1.5 gives `1.5`).
- Calculated `TFIBBCDField`: `AsExtended` and `AsInt64` read the `TBcd` of the value into an
  `Int64` (access violation or a wrong value), and `AsExtended :=` wrote an `Int64` over it.
- `AsCurrency` of `TFIBBCDField` and `TFIBClientBCDField`: a value out of the `Currency` range (a
  `NUMERIC(18,0)` of 123456789012345678) gave a wrong number or raised `EInvalidOp`, and a value
  with more than 4 decimals was not rounded exactly (999999999999.99999 gave
  1000000000000.0001). It is exact now and raises `EOverflow` out of the range; `AsFloat` and
  `AsLargeInt` don't go through `Currency`, and `TFIBBCDField.Value` of such a value is an
  `FMTBcd` variant.
- `TFIBClientBCDField.AsBCD` and `AsBCD :=` went through `Currency`, like `TBCDField`: 4
  decimals, `EConvertError` out of its range. They are exact now, rounded half away from zero
  to the scale of the field, and an `FMTBcd` variant is assigned through `AsBCD`.
- `TFIBClientBCDField.AsInt64 :=` stored the value as already scaled (77 on a scale 2 field
  stored 0.77); it stores 77.00 now and raises `EOverflow` out of the range of the field.
- `AsLargeInt :=` of `TFIBBCDField` and `TFIBClientBCDField` went through `Currency` and raised an
  error beyond its range (9e14), and `TFIBBCDField.AsInt64 :=` went through floating point (digits
  lost on Win64). Both are exact now and raise `EOverflow` out of the range of the field.
- `TFIBClientBCDField.AsBCD` read in the `OnValidate` of the field returned 0 instead of the
  new value (Delphi XE3 and later).
- `PSGetCommandText` of `IProviderSupport` returned an empty string on Delphi
  XE3 and later; it returns the select SQL or the pending provider command, as
  `PSGetCommandTextW` did on Delphi 2009 to XE2.
- `Locate` on a `TIMESTAMP` or `TIMESTAMP WITH TIME ZONE` field did not find a
  value with milliseconds given as a `Double` (e.g. `EncodeDate(...) +
  EncodeTime(...)`), and could miss a `TIMESTAMP WITH TIME ZONE` value by a
  rounding difference. The values are now compared in milliseconds; only a text
  key ignores them.
- `Locate` with several `TIMESTAMP` keys: a text key for one of them made the
  others ignore the milliseconds of the row, so a `TDateTime` key with
  milliseconds was not found. Only the field of the text key ignores them now.
- `AnsiCompareString` as `OnCompareFieldValues` took every field that is not
  `ftString` or `ftFixedChar` (e.g. a UTF8 column) for equal, so `DoSort` gave
  a random order. A NULL in a string field was also taken for equal
  to every value. These fields and NULLs are now compared as by
  `StdCompareValues`.
- `CompareVariants` (sorting, `Locate`): a `varSingle` variant was compared through the bytes of
  a `Double`, so 2 and a `Single` 2 were not equal.
- `CompareVariants`: a `WideString` compared with a `varString` variant, and a number compared
  with a numeric `varString` (`'25'`), read the bytes of the `AnsiString` as UTF-16 (wrong result
  or "not a valid floating point value").
- `CompareVariantsEQ` (`VariantRtn`) returned `False` for two equal `AnsiString` (`varString`)
  variants.
- `CompareVariants` and `CompareVariantsEQ` (sorting): a number compared with a string variant
  (`varUString`, every string on Delphi 2009 and later), a `Boolean`, a `UInt64` or an `FMTBcd`
  variant was taken for equal. The string is now parsed as a `WideString` is, and the other
  types are compared as variants.
- After `DoSort`, reopening the dataset without `poPersistentSorting` kept
  `Sorted` and `SortedFields` of the local sort, while the rows came in the
  server order. With `psGetOrderInfo` they are now read again from the `ORDER BY`
  of the query.
- Changing `psUseGuidField` in `PrepareOptions` after the first open had no
  effect: the field stayed a `TFIBStringField`. The field definitions are now
  read again, as for `psUseBooleanField`.
- `TFIBDataSet.CacheRefreshByArrMap` read past the end of the shorter of the two field arrays.
- `BlobSwapSupport`: with a table or field name outside the system code page the swap file was
  not written (the path had `?` in it).
- `TFIBDataSet.SaveToStream` kept the field, relation and alias names in the system code page,
  so names outside it became `?` after `LoadFromStream`. Stream version 8 keeps them in UTF-8, as
  the data packets of `TClientDataSet`; version 7 is still read, a newer version raises
  `feFormatVersionNotSupported`. The BLOB swap files keep the table and field names and the key
  values in UTF-8 too (swap version 2; older swap files are written again); see
  [Upgrading](Docs/guide/upgrading.md#dataset-streams-and-batch-files).
- `TableAliasForField` of `TFIBQuery` and `TFIBDataSet` returns the alias unquoted, as the server
  stores it (`MyAlias` for `"MyAlias"`), as `GetRelationTableName` returns the table; it was
  quoted when the alias needed quotes. After `LoadFromStream` the last field had no alias; see
  [Upgrading](Docs/guide/upgrading.md#table-alias-of-a-field).
- `TFIBDatabase.MemoSubtypes` kept the sub types in a byte, so for example `-1000` also matched
  the sub type 24.
- SQL generation: `AutoUpdateOptions.UpdateOnlyModifiedFields` stayed `False` when assigned
  before `AutoReWriteSqls` and `CanChangeSQLs`; it now keeps the value, and the new
  `UpdateOnlyModifiedFieldsInEffect` tells whether it applies. The `INSERT` and `UPDATE` made
  for each post under it had no `RETURNING` of `UseReturningFields`; `GenerateSQLText` with
  `skMerge` made a broken statement, it now makes `UPDATE OR INSERT ... MATCHING` on the key
  fields, which it inserts also with `ifsOnlyBlob`. Under `UpdateOnlyModifiedFields` an
  inserted row with all fields null was never written (`No Action`); it is now
  `INSERT ... DEFAULT VALUES`, and `rfAll` also returns the null columns the server filled.
  `UseRowsClause` put `ROWS 1` on the `INSERT` and after `RETURNING`, which Firebird rejects;
  it now goes only on the `UPDATE`, before `RETURNING`
  ([Upgrading](Docs/guide/upgrading.md#generated-statements)).
- `GenerateSQLText` on a dataset without field objects failed with `rfBlobFields` and ignored
  `ifsNoBlob` and `ifsOnlyBlob`; it now takes the BLOB columns from the field definitions.
- Under `UpdateOnlyModifiedFields` the per-post `InsertSQL` and `UpdateSQL` were assigned, and
  so prepared, again at each post although the text was the same. The same for the statement of
  the BLOB columns with `SeparateBlobUpdate`.
- Without `poRefreshAfterPost`, `OldValue` after a post gave the values before the edit, and
  after an insert the values of another row, so `GenerateSQLText(skModify)` under
  `UpdateOnlyModifiedFields` gave an `UPDATE` instead of `No Action`. The old values are now
  the posted row, as with `poRefreshAfterPost`
  ([Upgrading](Docs/guide/upgrading.md#generated-statements)).
- `Post` called again from the dataset's own `BeforePost` recursed until the stack overflowed;
  it is now ignored, and a `Post` from `AfterPost` still posts.
- `ApplyUpdates` with `AutoCommit` committed after each inserted or modified row; it now
  commits once, at the end, also when rows were skipped (they stay cached), and before an error
  is raised.
- `Filter`: a comparison with a NULL operand matched in some cases (a row with NULL `D` matched
  `D <> 5`, `GETDATE() > D` and `D < 5`, two NULL fields matched `A = B`, and a NULL Boolean
  field matched the filter `B`); as in SQL and the VCL `TClientDataSet`, `=`, `<>`, `>`, `>=`,
  `<`, `<=`, `LIKE` and `IN` no longer match when an operand is NULL; see
  [Upgrading](Docs/guide/upgrading.md#null-in-filter-comparisons).

#### Events

- Win64: the event alerter (`TFIBEventAlerter`) gave the client a status vector of 32-bit
  entries, while the client writes 64-bit ones: an error while registering or cancelling events
  could overwrite the handles of the event thread. The event counts, which the client writes as
  32-bit values, have their own array now.
- An error while registering events (an invalid database handle, a server whose events port
  can't be reached) ended the event thread without a message; it is now raised by
  `RegisterEvents` (see Changed).
- `UnRegisterEvents` raised `EListError` when another event thread ended with an error while it
  waited for a thread to stop.
- An event thread that ended with an error was never freed: its events stayed queued and its
  buffers leaked. It is freed on the next register or unregister or when the alerter is
  destroyed. The error text is read with `fb_interpret` and the buffer length where the client
  has it.

#### Errors and messages

- The error message cache (`ListErrorMessages`, used by `TFIBErrorHandler` for
  the messages of `FIB$ERROR_MESSAGES`) was not thread safe: errors handled in
  several threads at once could raise access violations. With a schema cache
  file, `FIB$VERSION` was checked once per process for all databases, so the
  stale messages of a second database, or of a file loaded later, were shown;
  each database is now checked on its first use and after a load, and also
  after a restore that lowered its versions. Constraint names that differ only
  in case no longer share one cached message.
- `TFIBErrorHandler.LastError`, `ConstraintName`, `ExceptionName` and
  `ExceptionNumber` were shared by all threads: an error in one thread changed
  them while another read them. They are now kept per thread.
- Creating a second `TFIBErrorHandler` raised, and also unregistered the first
  one, which then no longer handled any error.
- `TFIBErrorHandler`: when the lookup of a constraint in `FIB$ERROR_MESSAGES`
  failed (the table dropped, a transaction that is not active), its error
  replaced the violation, with its own `LastError`, `ConstraintName` and
  `OnFIBErrorEvent`. The violation now keeps the message it has without a row
  in the table.
- `TFIBErrorHandler`: in a transaction over several databases, a violation in
  a database other than the default one of the transaction was looked up in
  `FIB$ERROR_MESSAGES` of the default database (with its `UseRepositories`)
  and cached under it. The lookup now uses the database of the failing
  statement; `ListErrorMessages.ErrorMessage` takes the database as its first
  parameter, and `GetQueryForUse` has an overload with the database.
  The server version that decides whether `ExceptionName` is read was also
  taken from the default database; without one, and for a user exception
  raised on commit, `ExceptionName` was `Unknown` and the message kept the
  name and the stack trace.
- `TFIBErrorHandler.ConstraintName` was parsed from the message: a name with
  spaces or quotes was cut, and it was empty for a message in another language
  or without `ShowIBMessage`. It is now the exact name from the status vector,
  without the quotes and the schema that Firebird 6 adds there.
- Server error messages (`Message`, `IBMessage`), `EFIBError.ErrorArgument`
  and `TFIBErrorHandler.ConstraintName` and `ExceptionName` were decoded in the
  system code page, so non-ASCII names and exception texts were garbled
  outside it. They are now decoded in the charset of the connection (UTF-8 on
  a `NONE` connection, where the server sends the metadata charset). Firebird
  2.5 sends the names in UTF-8 and the exception texts in the charset of the
  connection, so on a connection that is not `UTF8` or `NONE` the names stay
  garbled there. The server errors of array fields and of
  `TFIBBlobStream.BlobToFile` now also give their database, for the decoding
  and for `OnLostConnect`.
- `TFIBErrorHandler`: the message of a user exception was cut at an "at" in its
  text, or kept the stack trace (`At procedure ...`). The SQL monitor and the
  SQL logger got the message after the error handler changed it; they now show
  the server text with the stack trace.
- `EFIBClientError.IBErrorCode` had the code of an earlier server error of the
  thread: after a statement timeout a client error had `isc_cancelled`, so
  `TFIBErrorHandler` took it for a cancelled statement. It is now 0.
- Russian messages (`Locales\ru\Errors.inc`): an unknown DPB or
  TPB constant raised an `EConvertError` ("Format ... invalid or incompatible
  with argument") instead of its message. The file was in code page 1251 and
  compiled to garbled text on a machine with another system code page; it is
  now UTF-8. The message of `feCantEndSharedTransaction` said something else
  than the English one, and `feCantUseField` had a grammar error.
- English messages: typos ("functonality", "equel", "an Firebird 2"), the
  space before the colon in "%s :Transaction is not active" and the others,
  and "Column types ... is not array field".

#### Services

- Security service (`TFIBSecurityService`) with a Firebird 3+ client library: the user name,
  password, first, middle and last name and role were encoded in UTF-8 and then converted again
  by the client from the system code page, so every non-ASCII character was stored garbled (`é`
  as `Ã©`). The text parameters of the services (also database and file names, and `Params` of
  the attachment) are now sent in the system code page, which the client converts; a character
  outside it raises `feCantTransliterateParam`, which names the parameter but not the value (a
  password), instead of being sent as `?`. An older client library
  does not convert: with it the server gets the names in the system code page of the client.
- Text the server sends back was decoded in the system code page: the output of the services
  (`GetNextLine`, `GetNextChunk`), `TFIBSecurityService.UserInfo`, the attached database names
  and the other strings of `TFIBServerProperties`, and `TFIBDatabase.DBFileName`, `DBSiteName`,
  `UserNames` and `Version`. A Linux server sends file names in UTF-8 and Firebird 3+ user
  names are UTF-8, so non-ASCII names were garbled. They are now decoded as UTF-8 when the bytes
  are valid UTF-8, else in the system code page (a Windows server).
- A service start parameter of 65536 bytes or more was dropped or sent with a wrong length; it
  raises an error now. A `BufferSize` of 65536 or more was cut to 2 bytes (65536 gave "Unexpected
  Output buffer value"); the service API gets at most 65535 bytes.
- `TFIBRestoreService.PageSize` was `4096` by default and always sent, so a database with larger
  pages was restored with 4096-byte pages. The default is `0`, which keeps the page size of the
  backup as gbak does without `-page`; see [Upgrading](Docs/guide/upgrading.md#restore-page-size).

#### Schema cache

- The metadata, dataset info and error message caches (`ListTableInfo`,
  `ListDataSetInfo`, `ListErrorMessages`) kept the database name in the system
  code page: with a name outside it no entry was found, and each
  `GetTableInfo` read the metadata again and added an entry. They also lost
  the texts outside it: table and column names, primary key fields, defaults,
  labels and formats of the metadata cache (a non-ASCII default value of a
  column came back as `?`), the SQL texts, key field, generator, update table,
  description and conditions of `FIB$DATASETS_INFO` and the constraint names
  and messages of `FIB$ERROR_MESSAGES`. They are now kept as `string` and the
  cache files are saved in UTF-8; files saved by older versions are still read
  ([Upgrading](Docs/guide/upgrading.md#schema-cache-files)).
- A schema cache file that could not be written completely (disk full, ...)
  was left truncated, and the next `Open` with `AutoLoadFromFile` failed
  reading it. The file is now deleted instead.

#### Schema extract

- DDL generated by `TFIBDBSchemaExtract` (`GetDDLText`, `GetObjectDDL`) on
  Delphi XE5 and later: characters outside the system code page in names,
  defaults and procedure bodies became `?`, and a DDL under 10 KB was padded
  with `#0` to 10240 characters. The DDL is now written to a `TStringStream`
  created with `TEncoding.Unicode`.
- Script of `TFIBDBSchemaExtract.GetDDLText`: the roles, external functions,
  generators, exceptions, tables, views and database triggers were followed by
  an extra `;`, the triggers of a view were created twice, the objects of a
  previous `GetObjectDDL` were written again, the `RETURNS` clause of every
  function after the first held its first parameter, identity columns lost
  `GENERATED ... AS IDENTITY`, the system domains `MON$...` of Firebird 4 and
  later were created, and index and trigger names were not quoted.
  `TMetaProcedure.PackageName` held the procedure body after `LoadMetaData`.
- `GetObjectDDL` and `AsDDL`: the DDL of a domain had no terminator and that
  of a package ended with `;;`. Before a `LoadMetaData`, `GetObjectDDL` ignored
  `DDLTextOptions` (for example `dtoDecodeDomains`), lost identity columns
  and took a packaged procedure of the same name.
- A generator value over 2147483647 was wrong. When
  `LoadOptions.DBObjects` had no `otTable`, the views had no columns and their
  triggers were not written. A procedure, function or external function got the
  parameters of a packaged one with the same name, and `GetObjectDDL(otUDF)`
  could take a packaged or PSQL function. `CREATE FUNCTION`, `RETURNS` and
  `COMPUTED BY` had two spaces. The script has no empty `UNIQUE`, `CHECKS` or
  `TRIGGERS` sections.
- Reloading or clearing the metadata leaked the previous meta objects, and
  `GetObjectDDL` of a database trigger leaked one object on each call.
- `TFIBDBSchemaExtract.GetObjectDDL` of a package or a PSQL function on a server before
  Firebird 3 raised "Table unknown" instead of returning an empty string.

#### Scripter

- `TFIBScripter` with `UseExecBlockForDML`: an `INSERT`, `UPDATE`, `DELETE` or
  `MERGE` with `RETURNING` was grouped into an `EXECUTE BLOCK`, where it needs
  `INTO`, so the whole block failed. Such a statement now runs alone; the new
  `TStatementDesc.HasReturning` field marks it.
- `TFIBScripter` with `UseExecBlockForDML`: the size limit of an
  `EXECUTE BLOCK` counted characters, so with UTF8 and non-ASCII text a block
  could be over the 64 KB the server accepts. The limit is now in bytes of the
  connection charset, and 10 MB with a Firebird 3 or later server and client.
- `TFIBScripter` cut a statement at a `--` comment when the script was added
  as one item with several lines (e.g. `Script.Add` of a multi-line string):
  the comment ran to the end of the item, not of the line
  ([#95](https://github.com/madorin/fibplus/issues/95); also in 7.9.2).
- `TFIBScripter` with `SET BLOBFILE`: every parameter whose name starts with `H` (`:HIRE_DATE`)
  was read from the blob file, and lowercase hex digits of a reference were read as 0. Only
  `H<offset>_<size>` in hex digits is a reference now. A reference past the end of the file loaded
  zeros, and a read error stopped the script with the bare stream error: both raise the new
  `feBlobFileError`, with the file and the parameter, and reach `OnExecuteError`.
- `TFIBScripter`, the SQL parser (`SqlTxtRtns`) and the SQL editor highlighting took any
  character 32 codes above a keyword letter for that letter: `{DIFDEF X}` was read as
  `{$IFDEF X}`, `RDBDGET_CONTEXT` was highlighted as `RDB$GET_CONTEXT`, and a non-ASCII letter
  could match an ASCII one (`Ѧ` as `F`). Only `a`..`z` now match `A`..`Z`.
- `TFIBScripter` sent statements it could not parse (starting with `-`, `/` or a bare `{`) to
  the server; they now raise a parse error.
- `TFIBScripter`: `SET CHARACTER` in `CONNECT` was replaced by the `SET NAMES` charset, and a
  `CONNECT` on an assigned `Database` cleared its `DBParams`. `CONNECT` now keeps the
  `DBParams` and sets only its own clauses (and `SET NAMES`, when given).
- `TFIBScripter.ExecuteFromFile` read the file in the system code page and passed a byte order
  mark to the parser; a UTF-8 or UTF-16 BOM now selects the encoding, as in
  `TStrings.LoadFromFile`.

#### SQL monitor

- SQL monitor: non-ASCII text could arrive garbled, through the system code
  page or a chunk of a long event cut inside a character.

#### Helper units

- Win64: `StreamToVariant` and `StreamToVariantArray` (`StdFuncs`) cut the memory addresses to
  32 bits (access violation), and so did the "nested datasets" error of `TFIBClientDataSet` with
  the address of its message.
- `StringAsGUID` (`StrUtil`) rejected lowercase hex digits and read some other characters (`G`,
  `x`, a space) as 0. `HexStr2Int` (`StdFuncs`) reads lowercase hex digits.
- `TCallBackList.Delete` ignored the index 0 and did not free the deleted entry.

#### IDE, editors and packages

- `FIBArray` did not compile on Delphi 10.1 Berlin: "Invalid typecast" in
  `TFIBArray.ReadElement`
  ([#94](https://github.com/madorin/fibplus/issues/94); also in 7.9.2).
- The editors did not save text and some integer settings on Delphi 2009 and
  later: the font name, style and charset and the syntax highlighting styles of
  the SQL editor, and the user transaction kinds of the transaction editor were
  lost when the IDE was closed.
- Editors at a display scaling over 100%: the saved size of a window was
  restored in pixels of 100%, so the window was too small for its content
  (sizes are now saved with the DPI of the window); the **Cancel** button of
  the SQL editors and of the dataset repository editor was partly off the
  form; the gutter of the SQL editor (line numbers, bookmarks, breakpoints,
  section boxes, the click area of the breakpoints) was not scaled.
- `DataSet_ID` property editor: when the `FIB$DATASETS_INFO` table did not
  exist, it refused to create it ("urDataSetInfo not included into
  Database.UseRepositories") although `urDataSetInfo` was in `UseRepositories`,
  unless all three repositories were enabled.
- Transaction editor: loading the transaction kinds from a file turned only the first `#` of the
  parameters into a line break.
- Dataset editor, **AutoUpdateOptions**: the generator step accepted a `.`.
- SQL editor: the characters U+0080 to U+00FF were measured as the character of the same byte in
  the system code page (all of them on a Central European or Cyrillic Windows), so the text after
  them was drawn at a wrong offset.
- SQL editor: a mouse click in a line with characters outside Latin-1 (Cyrillic) put the caret
  in a wrong column.
- SQL editor: selecting with the mouse in an editor without lines raised an
  "index out of bounds" error.
- SQL editor: a code completion item chosen on the empty line after the last
  line was sometimes not inserted.
- SQL editor: the line numbers covered the breakpoint glyphs, and a line
  number after a keyword was drawn in bold.
- SQL editor: on a line longer than 65535 characters the words after that position were
  highlighted at a wrong place.
- SQL editor: copy and paste of several lines with their sections pasted the characters outside
  the system code page as garbage, and cut the text on a double-byte code page (932, 936). The
  data is now UTF-16 in the new clipboard format `FIBSyntaxMemoUnicode`; the old `MP_SYN_MEMO`
  data still pastes.
- SQL editor: a `LiteralDecimalPoint` outside Latin-1 split the numbers in the highlighting.
- SQL editor: pasting text with sections raised an access violation, every paste dropped the
  sections of the editor, sections stayed at their rows when lines were inserted or deleted
  above them, and a paste of plain text did not set `Modified`.
- SQL editor: undo dropped all the sections of the editor, only the text came back.
- SQL editors, **Edit in code editor**: the SQL tab was named without the designer extension
  (`Form1.Query1.SQL` instead of `dfm.Form1.Query1.SQL`), so the IDE could not find the component
  of the tab ("Unable to find component") and the edited text was not written back to the
  property.

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

#### Connection and database

- `TpFIBDatabase.ApplyUpdates` raised an access violation for an empty array
  and read invalid memory for a dataset that is not a `TFIBCustomDataSet`.
- `TpFIBDatabase.InRestoreConnect` stayed `True` after a successful restore or
  a reconnect during the wait, and `TransactionID` returned 0 for transactions
  started after it. It was cleared while the timer waited again after a failed
  attempt, and the timer kept running when `OnErrorRestoreConnect` chose to
  stop.
- `TpFIBDatabase.WaitForRestoreConnect` read 0 and `laWaitRestore` did nothing
  until code assigned the property; the default 30000 now applies. Forms
  saved by earlier versions without a value set store
  `WaitForRestoreConnect = 0`, which keeps the timer off.
- `TpFIBDatabase.OnErrorRestoreConnect` got an uninitialized `DoRaise`.
- `TpFIBDatabase`: an alias did not read back its `CLIENT_LIB` into
  `LibraryName`. Aliases saved by earlier versions usually hold `gds32.dll`,
  see the upgrading guide.
- `TpFIBDatabase` saved the schema cache (`AutoSaveToFile`) on `ForceClose`
  when not connected.
- `DBParamByDPB` with a code above 83 (such as `isc_dpb_config`) read an empty
  value and wrote a parameter with a name out of the table range.

#### Character sets

- Locate, filters, sorting and bookmarks on string fields of a non-system code
  page; lookup fields with a Unicode result field.
- Multi-byte charset values (SJIS, GBK, ...) cut in the middle of a character.
- `CharacterSet` returned `UNKNOWN` for KOI8R/U, WIN1258, TIS620, GBK, CP943C
  and GB18030.
- `CharacterSet` of a text BLOB column returned the charset with the BLOB
  subtype as ID (`OCTETS`), and numeric columns returned `NONE`, `OCTETS` or
  `ASCII`; columns that are not CHAR, VARCHAR or text BLOB return `UNKNOWN`.

#### Queries and parameters

- Text BLOB parameters set before `Prepare` sent without their charset; NONE
  and OCTETS text BLOBs decoded as UTF-8 on UTF8 connections.
- A string parameter replaced by `AsInteger` before `Prepare` sent the string.
- A BOOLEAN parameter set with `AsString := 'true'` / `'false'` before `Prepare`
  raised "Invalid data conversion".
- `AsQuad` assigned after a long `AsString` was replaced by the string at the
  execute.
- `DisableEncodingSQLText` sent queries with parameters with an empty SQL text.
- `TpFIBQuery.ExecProcedure` wrote two spaces between `EXECUTE` and `PROCEDURE`.
- `BatchOutputRawFile` ignored its `Version` argument and always wrote version 3.

#### Datasets and fields

- Array fields kept the descriptor of a previous connection.
- `Locate` with a Currency key on NUMERIC(10..18) columns with a scale did not
  find values above 2^53 (e.g. 12345678901234.5678).
- `pfImportDefaultValues`: `CURRENT_TIME(n)`, `CURRENT_TIMESTAMP(n)`,
  `LOCALTIME(n)` and `LOCALTIMESTAMP(n)` defaults failed with a conversion error
  on insert. The value keeps the fractional digits of the default, as the
  server does: `CURRENT_TIME` and `LOCALTIME` without a precision no longer get
  milliseconds.
- `RecordFieldAsFloat` read past the last record for `RecNumber = RecordCount`,
  and on a filtered dataset for a visible number past the end; it returns 0.
- `AutoUpdateOptions.Assign` did not copy `UseExecuteBlock`, `UseReturningFields`
  and `UseRowsClause`, and left `KeyFieldList` empty. Assigning the
  `AutoUpdateOptions` property replaced the object instead of copying it, which
  leaked the old one and freed the shared one twice.
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
- `TFIBTimeField` and `TFIBDateTimeField` with `ShowMsec` wrote milliseconds
  without leading zeros: 5 ms showed as `.5` instead of `.005`.
- `GetExportDataScript` wrote `ftFMTBcd` values with the locale decimal
  separator.
- `GetExportDataScript` wrote dates in the locale format, left memo values
  unquoted and GUID values as text instead of the 16 bytes of the column.
- `TBlobSwapSupport` could not be assigned (`TFIBDatabase.BlobSwapSupport`).
- `TpFIBClientDataSet.TransactionIsActive` always raised "Invalid argument":
  `TpFIBDataSet` did not return the transaction state to the client. After a
  failed `Commit` or `RollBack`, the next execute without a command text ran
  the commit or rollback again instead of the dataset's SQL.

#### Services

- `FixLimboTransactionErrors` raised an access violation after
  `FetchLimboTransactionInfo` returned entries. `LimboTransactionInfoCount`
  and `UserInfoCount` returned -1 for an empty list; `LimboTransactionInfo`
  and `UserInfo` raise `EListError` for an index out of range instead of
  returning `nil`.
- `FixLimboTransactionErrors` rolled back the transactions with
  `RecoverTwoPhaseGlobal`; it now sends them to two-phase recovery.
- `TpFIBNRestoreService.Restore` read one element past the end of the file
  array.
- `TpFIBBackupService` and `TpFIBRestoreService`: a `name=length` line sent a
  length cut to as many digits as the name has characters.
- `TpFIBSecurityService`: `SecAdmin` was sent only when its value changed, so
  setting it again on the next `AddUser` or `ModifyUser` had no effect, and a
  failed call cleared the properties. Setting `SecAdmin` is now always sent;
  the properties, `SecAdmin` included, are cleared only after a successful
  call.
- Service `Params` entries (`ServiceParamBySPB`, login dialog) were looked up
  case-sensitively, and `password` also matched `password_enc`.

#### Scripter

- `TpFIBScripter`: `StopStatementNo` was not set by a pause at the last
  statement and kept the value of an earlier run; `ExecuteScript(0)` raised an
  access violation.
- `TpFIBScripter` with `UseExecBlockForDML`: a statement too long for a block
  was dropped; `EXECUTE BLOCK` and `EXECUTE PROCEDURE` statements were nested
  into a block.
- `TpFIBScripter` with `UseExecBlockForDML`: an error in the last
  `EXECUTE BLOCK` always propagated, without `OnExecuteError`.
- `TpFIBScripter` with `UseExecBlockForDML`: `OnExecuteError` and
  `AfterStatementExecute` of a block reported the statement after the block,
  which ran even when `Stop` was set; they report the last statement of the
  block, and `AfterStatementExecute` is called once per block.
- `TpFIBScripter` with `UseExecBlockForDML`: after a pause, and after
  `ExecuteStatement` outside a run, the pending block was sent only by the next
  run, even of another script.
- `TpFIBScripter`: `OnExecuteError` got an undefined `DoRollBack` for
  `CONNECT`, `CREATE DATABASE` and `COMMIT`, and was not called for
  `DROP DATABASE`; a failed `COMMIT` is kept when the handler sets `DoRollBack`
  to `False`.
- `TpFIBScripter`: a resumed run lost the `INSERT` used by `REINSERT`,
  `SET SQL DIALECT` and `SET NAMES`; a pause set before `INPUT` was ignored.
- `TpFIBScripter`: `CONNECT`, `CREATE DATABASE` and `DROP DATABASE` replaced
  the `LibraryName` of the database with the default library. It is changed
  only by `SET CLIENTLIB`.
- `TpFIBScripter` skipped the session `SET` statements (`STATEMENT TIMEOUT`,
  `SESSION IDLE TIMEOUT`, `BIND`, `TIME ZONE`, `DECFLOAT`, `ROLE`, `TRUSTED
  ROLE`, `OPTIMIZE`, `SEARCH_PATH`) without an error; it now sends them to the
  server, so an old script that contains them now runs them. They have the new
  `TStmtType` value `sSetSession`.

#### SQL monitor and logger

- `TFIBSQLMonitor.Release` raised an access violation before the first traced
  event, and the monitor was never freed while no monitor reader was active.
  Queries traced from several threads could free the SQL monitor writer thread
  while another thread used it; freeing the last monitor could hang; messages
  left at shutdown leaked.
- `Database.SQLLogger := nil` left the logger attached, so statistics were
  still collected; moving a logger to another database left it on the first.
- `TFIBSQLLogger.SaveStatisticsToDB` and `CreateStatisticsTable` roll back
  when a statement fails, instead of committing the rows inserted before it
  or leaving the transaction active.
- `TFIBSQLLogger.StatisticsParams` had no effect. The parameters left out are
  not written by `SaveStatisticsToFile`, and `SaveStatisticsToDB` writes NULL
  in their columns (`MAXTIME_PARAMS` follows `fspMaxTimeExecute`).
- SQL monitor: the fields of a fetch trace are on separate indented lines, as
  the parameters of an execute trace; a failed prepare names the query with
  its full owner path, as a failed execute.

#### Errors and events

- `TpFibErrorHandler`: assigning `ErrorLexems` did not copy `Exception` and
  `At`; lexems of another length than the default cut the exception message
  in the wrong place; `ExceptionName` kept the value of an earlier exception.
- `TSIBfibEventAlerter`: the error for too long event names said they were
  truncated; they are not.

#### Packages, editors and helper units

- The `FIBPlus_XE3` package did not compile: it contained the XML export units,
  which are not in the repository.
- User transaction kinds saved in the transaction editor shifted to another
  kind when a predefined kind was added.
- `StrUtil.FastCopy` read before the string for `Index < 1`; it now calls
  `Copy` on Delphi 2009+.

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
