# Changelog

## [7.9.2] - Unreleased

### Added

- `EFIBError.ErrorArgument(Code, Index)`: a string argument of the status
  vector, for example the constraint name of `isc_unique_key_violation`.
- `ListErrorMessages.ErrorMessage` and `GetQueryForUse` (`pFIBCacheQueries`)
  have an overload with the database, for a transaction over several
  databases. `FindDatabaseForObject` (`pFIBErrorHandler`) is public.

### Changed

- The Delphi XE, XE6 and XE8 packages are named like those of XE2 to XE7:
  `FIBPlus_XE`, `FIBPlus_XE6` and `FIBPlus_XE8` (before: `FIBPlus2011`,
  `FIBPlus_D20` and `FIBPlus_D22`), with the editors `FIBPlusEditors_XE`,
  `FIBPlusEditors_XE6` and `FIBPlusEditors_XE8`, and have project groups. The
  duplicate `FIBPlus_D21` and `FIBPlusEditors_D21` of the XE7 packages are
  removed. Packages that require an old name must require the new one.

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
  long lock table names in `TRParams` and values in the `TpFIBServices`
  `Params`, a clear error names the parameter.
- Numeric `DBParams` (`num_buffers`, `dummy_packet_interval`,
  `connect_timeout`, `old_file_size`, `shutdown_delay`, `force_write` and the
  other flags) were written in one byte, so a value over 255 was cut
  (`num_buffers=2048` sent 0). They are now written in 4 bytes.
- `lock_read`/`lock_write` table names in `TRParams` were sent in the system
  code page; the server takes them in the charset of the connection, so a
  non-ASCII table name was not found or was a malformed string. They are now
  sent in the metadata code page of the connection, and in UTF-8 to Firebird 2.1
  to 2.5, which look them up in the stored names without converting them.
- `TFIBTransaction`: a database of a multi-database transaction without its own parameters got
  the `lock_read`/`lock_write` table names in the code page of `MainDatabase`, and the TPB was
  not rebuilt when the metadata code page changed.
- `TFIBTransaction`: `lock_timeout` was sent in 2 bytes, so a value from 65536
  up was cut (65546 started the transaction with a timeout of 10 seconds). It is
  sent in 4 bytes; Firebird 2.5 and later check the range.
- `LibraryName` of `TFIBDatabase` went through the system code page: a client
  library in a folder with a name outside it could not be loaded.
- `DBParams`: a last `shutdown` value of one character (`shutdown=2`) was ignored, and an unknown
  word or a word with spaces (`shutdown=force, full`) set every bit of the value. The words are
  now trimmed; an unknown word or a number over 255 raises the new `feParamValueInvalid`.
- macOS: `FreeIBLibrary` did not unload the client library, also at program exit.

#### Queries and parameters

- `TFIBQuery` fields and parameters: `AsInteger` of a `BIGINT`, a scaled number
  or a double out of the `Integer` range, and `AsShort` out of the `SMALLINT`
  range, returned a cut value (5000000000 gave 705032704); they raise an
  invalid data conversion error, as for `INT128`.
- `TFIBQuery` parameters: `Assign` of a BLOB of more than 32767 bytes to a
  parameter that is not a BLOB sent a cut length (70000 bytes became 4464); it
  raises an error now. `AsInt64` in SQL dialect 1 or 2 sent the value cut to 32
  bits; out of that range it is sent as a double. A `LongWord` variant over
  `MaxInt` was sent as a negative number when passed by reference and raised
  `EVariantOverflowError` when passed by value; both are sent as a `BIGINT`.
- A string over 32767 bytes for a `VARCHAR` parameter was sent as a blob of the
  column charset subtype, so the server reported "Filter not found to convert
  type 4 to type 1" instead of a string truncation.
- A text BLOB parameter set with `AsString` before `Prepare` read `(BLOB)`
  after `ExecQuery`; it now returns the string, as when it is set after
  `Prepare`.
- A parameter set before `Prepare` could be converted to the server type twice,
  when another parameter was set before a new `Prepare`.
- `StopFetching` in `TFIBQuery.OnSQLFetch` and `BeforeFetchRecord` made `Next`
  return `nil` but left `Eof` at `False`, so a `while not Eof` loop did not end.
  It is now a final stop: `Eof` is set as at the end of the data.
- `TFIBQuery` fields and parameters of a date, time, number or boolean type on
  Delphi 2009 and later: `AsString` passed the formatted text through the
  system code page, so locale texts outside it (for example the AM/PM
  designators) became `?`.
- `AsTimeZoneName` of a `TIME` or `TIMESTAMP WITH TIME ZONE` value in a region
  unknown to the built-in time zone table was empty, and `AsString` ended with
  a blank. It is now the offset of the value (`+02:00`).
- Macros: an old form macro (`@Name`) followed by a tab took the rest of the
  text up to the next space into its name, and one at the very end of the text
  was not replaced. A new form macro (`@@Name@`) without the closing `@` went
  to the server as it was; it now raises "EOF in macro detected".
- `AsInteger`, `AsInt64` and `AsShort` on a `BOOLEAN` parameter sent an integer, and the server
  raised "Incompatible column/host variable data type"; a value other than zero is now sent as
  `True`, as `AsBoolean` reads it, before and after `Prepare`.
- A parameter used twice, for a BLOB and for a `VARCHAR` or a column of another charset, sent
  the BLOB ID with the subtype of the other column ("Filter not found to convert type 4 to
  type 1").
- Win64: `BatchOutput` to a delimited or a raw file raised an access violation, which it reports
  only as `False`, and left the file empty.

#### Datasets and fields

- Win64: `TFIBGuidField.AsGuid` and `AsString` (`GUIDAsString` of `StrUtil`) raised an access
  violation: the destination address was kept in 32 bits.
- `TpFIBDataSet`: a value out of range in a persistent float field of a
  `NUMERIC` stored as `INTEGER` or `SMALLINT` (for example 30000000 in a
  `NUMERIC(9,2)`) was stored cut (-12949672.96); it raises an error now. A
  generator value out of the `INTEGER` range for an `INTEGER` key field
  (`AutoUpdateOptions`) was cut; the field raises an error now.
- `TpFIBDataSetProvider`: `RefreshRecord` of the client dataset wrote a NULL `NUMERIC` of the
  source as a number (0 or garbage).
- `PSGetCommandText` of `IProviderSupport` returned an empty string on Delphi
  XE3 and later; it returns the select SQL or the pending provider command, as
  `PSGetCommandTextW` does on Delphi 2006 to XE2.
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
- `CompareVariants` on Delphi 2009 and later: a `WideString` compared with a `varString`
  variant, and a number compared with a numeric `varString` (`'25'`), read the bytes of the
  `AnsiString` as UTF-16 (wrong result or "not a valid floating point value").
- `CompareVariantsEQ` (`VariantRtn`) returned `False` for two equal
  `AnsiString` (`varString`) variants on Delphi 2009 and later.
- After `DoSort`, reopening the dataset without `poPersistentSorting` kept
  `Sorted` and `SortedFields` of the local sort, while the rows came in the
  server order. With `psGetOrderInfo` they are now read again from the `ORDER BY`
  of the query.
- Changing `psUseGuidField` in `PrepareOptions` after the first open had no
  effect: the field stayed a `TFIBStringField`. The field definitions are now
  read again, as for `psUseBooleanField`.
- `TpFIBDataSet.CacheRefreshByArrMap` read past the end of the shorter of the two field arrays.
- `TFIBDatabase.MemoSubtypes` kept the sub types in a byte, so for example
  `-1000` also matched the sub type 24.
- `Post` called again from the dataset's own `BeforePost` recursed until the stack overflowed;
  it is now ignored, and a `Post` from `AfterPost` still posts.
- SQL generation under `AutoUpdateOptions.UpdateOnlyModifiedFields`: an inserted row with all
  fields null was never written (`No Action`) although the dataset showed it as posted; it is
  now `INSERT ... DEFAULT VALUES`. The `INSERT` and `UPDATE` made for each post had no
  `RETURNING` of `UseReturningFields`; with `rfAll` an `INSERT` also returns the null columns
  the server filled. `UseRowsClause` put `ROWS 1` on the `INSERT` and after `RETURNING`, which
  Firebird rejects; it now goes only on the `UPDATE`, before `RETURNING`. `GenerateSQLText`
  and `GenerateSQLTextNoParams` with `skMerge` made a broken statement; they now make
  `UPDATE OR INSERT ... MATCHING` on the key fields.
- `ApplyUpdates` of a `TClientDataSet` over a `TpFIBDataSet` sent the text `No Action` of
  `InsertSQL`, `UpdateSQL`, `DeleteSQL` or an update object to the server (syntax error); the
  row now counts as applied with nothing sent, and a `No Action` delete runs no update object,
  as a direct post or delete.
- `CompareVariants` (sorting, `Locate`): a number compared with a Unicode string variant (every
  string variant on Delphi 2009 and later), a `Boolean`, a `UInt64` or an `FMTBcd` variant was
  taken as equal.
- FIBPlus fields in a dataset that is not FIBPlus (e.g. persistent fields copied to a
  `TClientDataSet`): the first read of a `TFIBStringField` could raise an access violation,
  `AsNativeData` and `AsOctetsData` of the string fields wrote into the memory of that dataset,
  and `TFIBWideStringField` did not work there at all. `TFIBDateTimeField.AsTimeStamp` gave a
  wrong value in `OnValidate`, or raised `EIntOverflow` there when assigned.
  `TFIBFloatField.Scale` and `AsFloat :=` read garbage, and the value of a `TFIBArrayField` was
  lost. `GetBlobInfo`, `Blob_ID` and `ArrayID` raise a clear error there.
- `DisplayFormat` and `EditFormat` of `TFIBBCDField` and `TpFIBClientBCDField` on a rounded
  value: the zeros of the carry were dropped (`0.00` on 1.296 gave `1.3`), the thousand
  separators stayed where they were before the carry (`#,##0.00` on 9999.996 gave `1,0000`), a
  format without a decimal point kept the decimals, literals after the digits counted as
  decimals (`$ #,##0.00 USD` did not round), the trailing zeros of the optional `#` decimals
  were kept, the section was chosen before rounding (`0.0;(0.0)` on -0.004 gave `(0.0)`), an
  empty negative section was not handled, and the sign went after a leading literal (`$ -1.00`
  instead of `-$ 1.00`).
- Calculated `TFIBBCDField`: `AsExtended`, `AsInt64` and `FieldModified` read the `TBcd` of the
  value into an `Int64` (access violation or a wrong value), and `AsExtended :=` wrote an
  `Int64` over it.
- `AsCurrency` of `TFIBBCDField` and `TpFIBClientBCDField`: a value out of the `Currency` range
  (a `NUMERIC(18,0)` of 123456789012345678) gave a wrong number or raised `EInvalidOp`, and a
  value with more than 4 decimals was not rounded exactly. It is exact now and raises
  `EOverflow` out of the range. `AsFloat` and `AsLargeInt` don't go through `Currency`, and
  `TFIBBCDField.Value` of such a value is an `FMTBcd` variant.
- `TFIBBCDField.AsBCD :=` rescaled through floating point and wrote an out of range value;
  `TpFIBClientBCDField.AsBCD` and `AsBCD :=` went through `Currency` (4 decimals,
  `EConvertError` out of its range). Both are exact now, rounded half away from zero to the
  scale of the field, and raise `EOverflow` out of the range.
- `TpFIBClientBCDField.AsInt64 :=` stored the value as already scaled (77 on a scale 2 field
  stored 0.77), `TFIBBCDField.AsInt64 :=` and `TpFIBClientBCDField.AsInt64` lost digits on
  Win64, and `AsLargeInt :=` of both fields failed beyond 9.2E14.
- `TpFIBClientDataSet` ignored the scale of a stored BCD value with fewer decimals than the
  field.

#### Events

- Win64: the event thread of `TSIBfibEventAlerter` gave the client a status vector of 32-bit
  entries, while the client writes 64-bit ones: an error while registering or cancelling events
  could overwrite the handles of the thread. The event counts have their own array now.
- An error while registering events (an invalid database handle, a server whose events port
  can't be reached) ended the event thread without a message; it is now reported like an error
  after the registration.
- `UnRegisterEvents` raised `EListError` when another event thread ended with an error while it
  waited for a thread to stop.
- An event thread that ended with an error was never freed: its events stayed queued and its
  buffers leaked. It is freed on the next register or unregister or when the alerter is
  destroyed. Its error text is read with `fb_interpret` where the client has it.

#### Errors and messages

- The error message cache (`ListErrorMessages`, used by `TpFibErrorHandler` for
  the messages of `FIB$ERROR_MESSAGES`) was not thread safe: errors handled in
  several threads at once could raise access violations. `FIB$VERSION` was
  checked once per process for all databases, so the stale messages of a second
  database, or of a schema cache file loaded later, were shown; each database is
  now checked on its first use and after a load. Constraint names that differ
  only in case no longer share one cached message.
- `TpFibErrorHandler.LastError`, `ConstraintName`, `ExceptionName` and
  `ExceptionNumber` were shared by all threads: an error in one thread changed
  them while another read them. They are now kept per thread.
- Creating a second `TpFibErrorHandler` raised, and also unregistered the first
  one, which then no longer handled any error.
- `TpFibErrorHandler`: when the lookup of a constraint in `FIB$ERROR_MESSAGES`
  failed (the table dropped, a transaction that is not active), its error
  replaced the violation, with its own `LastError`, `ConstraintName` and
  `OnFIBErrorEvent`. The violation now keeps the message it has without a row
  in the table.
- `TpFibErrorHandler`: in a transaction over several databases, a violation in
  a database other than the default one of the transaction was looked up in
  `FIB$ERROR_MESSAGES` of the default database and cached under it. The lookup
  now uses the database of the failing statement. The server version that
  decides whether `ExceptionName` is read was also taken from the default
  database; without one, `ExceptionName` was `Unknown` and the message kept the
  name and the stack trace.
- `TpFibErrorHandler.ConstraintName` was parsed from the message: a name with
  spaces or quotes was cut, and it was empty for a message in another language
  or without `ShowIBMessage`. It is now the exact name from the status vector,
  without the quotes and the schema that Firebird 6 adds there.
- Server error messages (`Message`, `IBMessage`) and
  `TpFibErrorHandler.ConstraintName` and `ExceptionName` were decoded in the
  system code page, so non-ASCII names and exception texts were garbled outside
  it. They are now decoded in the charset of the connection (UTF-8 on a `NONE`
  connection, where the server sends the metadata charset). Firebird 2.5 sends
  the names in UTF-8 and the exception texts in the charset of the connection,
  so on a connection that is not `UTF8` or `NONE` the names stay garbled there.
  The server errors of array fields and of `TFIBBlobStream.BlobToFile` now also
  give their database, for the decoding and for `OnLostConnect`.
- `TpFibErrorHandler`: the message of a user exception was cut at an "at" in its
  text, or kept the stack trace (`At procedure ...`). The SQL monitor and the
  SQL logger got the message after the error handler changed it; they now show
  the server text with the stack trace.
- `EFIBClientError.IBErrorCode` had the code of an earlier server error of the
  thread: after a statement timeout a client error had `isc_cancelled`, so
  `TpFibErrorHandler` took it for a cancelled statement. It is now 0.
- Russian messages (`Resources\Russian\FIB_Messages.inc`): an unknown DPB or
  TPB constant raised an `EConvertError` ("Format ... invalid or incompatible
  with argument") instead of its message.
- Typos and stray blanks in the English and Russian messages; two Russian
  messages (`feCantUseField`, `feFeatureNotSupported`) had a wrong grammar.

#### Services

- Security service (`TpFIBSecurityService`) with a Firebird 3+ client library:
  the user name, password, first, middle and last name and role were encoded in
  UTF-8 and then converted again by the client from the system code page, so
  every non-ASCII character was stored garbled (`é` as `Ã©`). They are now sent
  in the system code page, which the client converts; on Delphi 2009 and later
  a character outside it raises "Cannot transliterate" instead of being sent as
  `?`.
- Text the server sends back was decoded in the system code page: the output of
  the services (`GetNextLine`, `GetNextChunk`), `TpFIBSecurityService.UserInfo`,
  the attached database names and the other strings of
  `TpFIBServerProperties`, and `TFIBDatabase.UserNames`, `Version`,
  `FBVersion` and the other text database info. A Linux server sends file names
  in UTF-8 and Firebird 3+ user names are UTF-8, so non-ASCII names were
  garbled. They are now decoded as UTF-8 when the bytes are valid UTF-8, else
  in the system code page (a Windows server).
- A service start parameter of 65536 bytes or more was dropped or sent with a
  wrong length; it raises an error now. A `BufferSize` of 65536 or more was cut
  to 2 bytes (65536 gave "Unexpected Output buffer value"); the service API gets
  at most 65535 bytes.

#### Schema cache

- A schema cache file that could not be written completely (disk full, ...)
  was left truncated, and the next `Open` with `AutoLoadFromFile` failed
  reading it. The file is now deleted instead.

#### Schema extract

- DDL generated by `TpFIBDBSchemaExtract` (`GetDDLText`, `GetObjectDDL`) on
  Delphi XE5 and later: characters outside the system code page in names,
  defaults and procedure bodies became `?`, and a DDL under 10 KB was padded
  with `#0` to 10240 characters. The DDL stream is now created with
  `TEncoding.Unicode`.
- Script of `TpFIBDBSchemaExtract.GetDDLText`: the roles, external functions,
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
- A generator value over 2147483647 was wrong
  (`TMetaGenerator.Value` is `Int64`). When `LoadOptions.DBObjects` had no
  `otTable`, the views had no columns and their triggers were not written. A
  procedure, function or external function got the parameters of a packaged
  one with the same name, and `GetObjectDDL(otUDF)` could take a packaged or
  PSQL function. `CREATE FUNCTION`, `RETURNS` and `COMPUTED BY` had two
  spaces. The script has no empty `UNIQUE`, `CHECKS` or `TRIGGERS` sections.
- Reloading or clearing the metadata leaked the previous meta objects, and
  `GetObjectDDL` of a database trigger leaked one object on each call.
- `TpFIBDBSchemaExtract.GetObjectDDL` of a package or a PSQL function on a server before
  Firebird 3 raised "Table unknown" instead of returning an empty string.

#### Scripter

- `TpFIBScripter` with `UseExecBlockForDML`: an `INSERT`, `UPDATE`, `DELETE` or
  `MERGE` with `RETURNING` was grouped into an `EXECUTE BLOCK`, where it needs
  `INTO`, so the whole block failed. Such a statement now runs alone; the new
  `TStatementDesc.HasReturning` field marks it.
- `TpFIBScripter` with `UseExecBlockForDML`: the size limit of an
  `EXECUTE BLOCK` counted characters, so with UTF8 and non-ASCII text a block
  could be over the 64 KB the server accepts. The limit is now in bytes of the
  connection charset, and 10 MB with a Firebird 3 or later server and client.
- `TpFIBScripter` cut a statement at a `--` comment when the script was added
  as one item with several lines (e.g. `Script.Add` of a multi-line string):
  the comment ran to the end of the item, not of the line
  ([#95](https://github.com/madorin/fibplus/issues/95)).
- `TpFIBScripter` with `SET BLOBFILE`: every parameter whose name starts with `H` (`:HIRE_DATE`)
  was read from the blob file, and lowercase hex digits of a reference were read as 0. Only
  `H<offset>_<size>` in hex digits is a reference now. A reference past the end of the file
  loaded zeros; it raises the new `feBlobFileError`, with the file and the parameter.
- `TpFIBScripter`, the SQL parser (`SqlTxtRtns`) and the SQL editor highlighting took any
  character 32 codes above a keyword letter for that letter: `{DIFDEF X}` was read as
  `{$IFDEF X}`, `RDBDGET_CONTEXT` was highlighted as `RDB$GET_CONTEXT`, and a non-ASCII letter
  could match an ASCII one. Only `a`..`z` now match `A`..`Z`.
- `TpFIBScripter.ExecuteFromFile` passed a UTF-8 byte order mark to the parser, so the first
  statement failed; the mark is skipped (the file is still read in the system code page).
- `TpFIBScripter.LineCountInCurrentFile` kept the line count of a file run by `INPUT` after it
  returned to the calling file.

#### SQL monitor

- SQL monitor: non-ASCII text could arrive garbled, through the system code
  page or a chunk of a long event cut inside a character.

#### Helper units

- Win64: `StreamToVariant` and `StreamToVariantArray` (`StdFuncs`) cut the
  memory addresses to 32 bits (access violation), and so did the "nested
  datasets" error of `TpFIBClientDataSet` with the address of its message.
- `StringAsGUID` (`StrUtil`) rejected lowercase hex digits and read some other characters (`G`,
  a space, `/`, `:`, `@`) as 0. `HexStr2Int` (`StdFuncs`) reads lowercase hex digits.
- `TCallBackList.Delete` ignored the index 0 and did not free the deleted entry.
- `BCDToInt64WithScale` (`StdFuncs`) dropped the leading digit of 19 digit values, never
  reported an overflow, and left `Scale` unset for a zero precision `TBcd`. `BCDToExtended` gave
  a wrong value for an integer part beyond `Int64`, so `CompareBCD` compared garbage.

#### IDE, editors and packages

- `pFIBArray` did not compile on Delphi 10.1 Berlin: "Invalid typecast" in
  `TpFIBArray.ReadElement` ([#94](https://github.com/madorin/fibplus/issues/94)).
- The editors did not save text and some integer settings: the font name,
  style and charset and the syntax highlighting styles of the SQL editor, and
  the user transaction kinds of the transaction editor were lost when the IDE
  was closed (the font charset on every version, the rest on Delphi 2009 and
  later).
- `DataSet_ID` property editor: when the `FIB$DATASETS_INFO` table did not
  exist, it refused to create it ("urDataSetInfo not included into
  Database.UseRepositories") although `urDataSetInfo` was in `UseRepositories`,
  unless all three repositories were enabled.
- Transaction editor: a saved transaction kind whose parameters were missing
  from the registry could raise "Variant is not an array"; the check no longer
  depends on Delphi short-circuiting a `Variant` expression.
- Transaction editor: loading the transaction kinds from a file turned only the first `#` of the
  parameters into a line break.
- Dataset editor, **AutoUpdateOptions**: the generator step accepted a `.`.
- SQL editor: on Delphi 2009 and later the characters U+0080 to U+00FF were
  measured as the character of the same byte in the system code page (all of
  them on a Central European or Cyrillic Windows), so the text after them was
  drawn at a wrong offset.
- SQL editor: a mouse click in a line with characters outside Latin-1 (Cyrillic) put the caret
  in a wrong column (Delphi 2009 and later).
- SQL editor: selecting with the mouse in an editor without lines raised an
  "index out of bounds" error.
- SQL editor: a code completion item chosen on the empty line after the last
  line was sometimes not inserted.
- SQL editor: a line number after a keyword was drawn in bold.
- SQL editor: on a line longer than 65535 characters the words after that
  position were highlighted at a wrong place.
- Conditions editor: a narrow conditions list auto-sized its column instead of
  shrinking it.
- SQL editor: copy and paste of several lines with their sections pasted the characters outside
  the system code page as garbage, and cut the text on a double-byte code page (932, 936). On
  Delphi 2009 and later the data is now also put in UTF-16; the old `MP_SYN_MEMO` data still
  pastes and is still written for older editors.
- SQL editor: a `LiteralDecimalPoint` outside Latin-1 split the numbers in the highlighting.
- SQL editor: pasting text with sections raised an access violation, every paste dropped the
  sections of the editor, sections stayed at their rows when lines were inserted or deleted
  above them, and a paste of plain text did not set `Modified`.
- SQL editor: undo dropped all the sections of the editor, only the text came back.
- SQL editors, **Edit in code editor**: on Delphi 2005 and later the SQL tab was named without
  the designer extension (`Form1.Query1.SQL` instead of `dfm.Form1.Query1.SQL`), so the IDE
  could not find the component of the tab ("Unable to find component") and the edited text was
  not written back to the property.

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
