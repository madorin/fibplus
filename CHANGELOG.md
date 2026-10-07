# Changelog

## [7.9.1] - Unreleased

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
- Locate, filters, sorting and bookmarks on string fields of a non-system code
  page; lookup fields with a Unicode result field.
- `UseExecuteBlock`: apostrophes in literals not doubled, non-ASCII text sent
  in the system code page.
- Text BLOB parameters set before `Prepare` sent without their charset; NONE
  and OCTETS text BLOBs decoded as UTF-8 on UTF8 connections.
- A string parameter replaced by `AsInteger` before `Prepare` sent the string.
- Multi-byte charset values (SJIS, GBK, ...) cut in the middle of a character.
- `DisableEncodingSQLText` sent queries with parameters with an empty SQL text.
- `CharacterSet` returned `UNKNOWN` for KOI8R/U, WIN1258, TIS620, GBK, CP943C
  and GB18030.
- `GetExportDataScript` wrote `ftFMTBcd` values with the locale decimal
  separator.
- `StrUtil.FastCopy` read before the string for `Index < 1`; it now calls
  `Copy` on Delphi 2009+.
- The `FIBPlus_XE3` package did not compile: it contained the XML export units,
  which are not in the repository.
- `TpFIBScripter` skipped the session `SET` statements (`STATEMENT TIMEOUT`,
  `SESSION IDLE TIMEOUT`, `BIND`, `TIME ZONE`, `DECFLOAT`, `ROLE`, `TRUSTED
  ROLE`, `OPTIMIZE`, `SEARCH_PATH`) without an error; it now sends them to the
  server, so an old script that contains them now runs them. They have the new
  `TStmtType` value `sSetSession`.

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
