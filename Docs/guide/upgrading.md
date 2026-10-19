# Upgrading

This article lists what an existing application must know or do when it moves to a newer FIBPlus version: breaking changes, changed behavior, renamed or removed identifiers, deprecated members, and build changes. It does not list bug fixes or new features. For the complete list, see [CHANGELOG.md](../../CHANGELOG.md) in the repository root.

## How to use this page

Find the version you use now, then read every section above it, from the one just after your version up to the version you are moving to. Sections are ordered like the changelog, newest first.

| Version | Status | Notes |
|---------|--------|-------|
| [8.0.0](#800) | Unreleased | Dataset, client dataset, database, transaction, query, service components, array, update object, scripter, stored procedure, error handler, table changes reader and schema extract classes renamed from `TpFIB...` to `TFIB...`. |
| [7.9.1](#791) | 2026-10-09 | Text in the code page of each column's character set, *Firebird 4+* statement and idle timeouts and read consistency, *Firebird 5+* parallel workers, an FMX login dialog package, and many bug fixes. |
| [7.9.0](#790) | 2026-10-01 | First release of the community maintained FIBPlus. Based on the FIBPlus 7 sources of build 632 (2014-02-17). |

## 8.0.0

### Build

| Change | What to do |
|--------|------------|
| Delphi 6, 7, 2005, 2006, 2007 and C++Builder 6 to 2007 are no longer supported; their packages are removed. Compiling with them stops with a fatal message. | Stay on 7.9.x, or move to Delphi 2009 or later. |
| The compiler version symbols of `FIBPlus.inc` are renamed to `C<CompilerVersion>`: `D2010+` → `C21`, `D_XE` → `C22`, `D_XE2` → `C23`, `D_XE3` → `C24`, `D_XE4` → `C25`, `D_XE5` → `C26`, `D_20`..`D_29` → `C27`..`C36`, `D_30` → `C37`. `TWideDataSet` (Delphi 2009 to XE2) is removed: test `{$IFNDEF C24}`. | Only for code that includes `FIBPlus.inc` and tests these symbols: rename them. |

### Renamed and removed identifiers

| Old | New | What to do |
|-----|-----|------------|
| `StrUtil.CharInSet`, `FIBPlatforms.WideCompareStr` (declared only for compilers before Delphi 2009) | Removed | Nothing: `SysUtils` declares both. |
| `IWideStringField` with its properties `WideDisplayText`/`WideText`, implemented by `TFIBMemoField` (`GetWideDisplayText`, `GetWideEditText`, `SetWideEditText`), for the TNT controls | Removed | Use `DisplayText`, `Text` or `AsString`. |
| `FIBCharSets.DecodeWideString` | `DecodeString` | Rename; assign the result to a `WideString` if the type matters. |
| `AsComp` of `TFIBBCDField`, `TFIBClientBCDField`, `TFIBXSQLVAR` (compiled only without `NO_USE_COMP`, which `FIBPlus.inc` always defined) | Removed | Use `AsBcd` or `AsInt64`. |
| Unit `pFIBScripter` | `FIBScripter` | Change the `uses` clause. The old unit still compiles and gives a warning. |
| `TpFIBScripter` | `TFIBScripter` | Rename. The old name is a deprecated alias of the same class. |
| `TpFIBScriptParser` | `TFIBScriptParser` | Rename. The old name is a deprecated alias of the same class. |
| Unit `pFIBStoredProc` | `FIBStoredProc` | Change the `uses` clause. The old unit still compiles and gives a warning. |
| `TpFIBStoredProc` | `TFIBStoredProc` | Rename. The old name is a deprecated alias of the same class. |
| Unit `pFIBErrorHandler` | `FIBErrorHandler` | Change the `uses` clause. The old unit still compiles and gives a warning. |
| `TpFibErrorHandler` | `TFIBErrorHandler` | Rename. The old name is a deprecated alias of the same class. |
| Unit `pFIBDataRefresh` | `FIBDataRefresh` | Change the `uses` clause. The old unit still compiles and gives a warning. |
| `TpFIBTableChangesReader` | `TFIBTableChangesReader` | Rename. The old name is a deprecated alias of the same class. |
| Unit `pFIBMetaData` | `FIBMetaData` | Change the `uses` clause. The old unit still compiles, gives a warning, and exports the types, the values of the enumerated types, the constants and `FullExtractDDL`. |
| `TpFIBDBSchemaExtract` | `TFIBDBSchemaExtract` | Rename. The old name is a deprecated alias of the same class in `pFIBMetaData`. |
| Unit `pFIBQuery` | `FIBQuery`, `FIBDataSet` | Change the `uses` clause. The old unit still compiles and gives a warning. |
| `TpFIBQuery` | `TFIBQuery` | Rename. The old name is a deprecated alias of the same class. |
| `TpFIBUpdateObject` | `TFIBUpdateObject` (unit `FIBDataSet`) | Rename. The old name is a deprecated alias of the same class. |
| `TpFIBQueryOption`, `TpFIBQueryOptions` | `TFIBQueryOption`, `TFIBQueryOptions` | Rename. The old names are deprecated aliases of the same types in `pFIBProps`. |
| `TFIBQuery.FN` (missing column returned `nil`) | `TFIBQuery.FindField` | `FN` now raises for a missing column, as `TpFIBQuery.FN` did. Replace `FN` with `FindField` where you test the result for `nil`. |
| IDE preferences of the query (registry key `pFIBQuery`) | registry key `FIBQuery` | The saved design-time defaults for new queries (`ParamCheck`, `GoToFirstRecordOnExecute`, `Options`) are not read from the old key. Set them again once in the FIBPlus preferences. |
| Unit `pFIBDataSet` | `FIBDataSet` | Change the `uses` clause. The old unit still compiles and gives a warning. |
| `TpFIBDataSet` | `TFIBDataSet` | Rename. The old name is a deprecated alias of the same class. |
| `TLockStatus`, `TLockErrorEvent`, `TCachRefreshKind`, `TOnGetSQLTextProc`, `TIncludeFieldsToSQL`, `FieldInArray` (unit `pFIBDataSet`) | The same names in `FIBDataSet` | Change the `uses` clause. The old unit exports them as aliases. |
| `TFIBUpdateObject.DataSet: TFIBDataSet` | `TFIBCustomDataSet` | Any FIBPlus dataset is accepted. Code that reads the property needs a cast to `TFIBDataSet` to use the published members, and `QSelect`, `Params`, `Prepared` and similar are protected in `TFIBCustomDataSet`. |
| `TpFIBFieldInfo` (units `pFIBDataInfo`, `FIBDataSet`) | `TFIBFieldInfo` (unit `FIBProps`) | Rename, also in handlers of `TDataSetsContainer.OnApplyFieldRepository`. The old name is a deprecated alias in `pFIBProps`. |
| `TOnBlobFieldProcessing` (`FIBDataSet`) | Declared in `FIBProps` | `FIBDataSet` exports it, so code that uses it compiles without a change. |
| `TExtBoolean` (`pFIBDataInfo`) | Declared in `FIBProps` | Internal type. The `FIBDataInfo` routines that took `TFIBDataSet` now take `TFIBCustomDataSet`. |
| `SFIBErrorNotDataSet`, `SFIBErrorNotDataSetDetail` (`FIBConsts`) | Removed | Nothing raises them any more. |
| `TFIBTableInfo.TableName`, `TFIBFieldInfo.DefaultValue`, `DomainName`, `DisplayLabel`, `EditFormat`, `DisplayFormat` (`AnsiString`) | `string` | Nothing for most code. Assigning them to an `AnsiString` loses the characters outside the system code page, as before. `TFIBFieldInfo.LoadFromStream` has a new `UTF8` parameter (default `True`, the format `SaveToStream` writes now). |
| `StrUtil.TFastStringStream` (an alias of `TStringStream` on Delphi XE5 and later, an own class before), parameter of `GenerateDDLText`, `GenerateObjectDDL` and the other DDL methods of `FIBMetaData` | `TStringStream` | Rename in descendants that override these methods. Create the stream with `TEncoding.Unicode`, as `GetAsDDL` does, to keep the characters outside the system code page. |
| `TpFIBDataSetOptionsEditor` | `TFIBDataSetOptionsEditor` | Rename in design-time code that registers it. |
| IDE preferences of the dataset (registry key `pFIBDataSet`) | registry key `FIBDataSet` | The saved design-time defaults for new datasets (`Options`, `PrepareOptions`, `DetailConditions`, default formats, generator name prefix and suffix) are not read from the old key. Set them again once in the FIBPlus preferences. |
| Unit `pFIBDatabase` | `FIBDatabase` | Change the `uses` clause. The old unit still compiles and gives a warning. |
| `TpFIBDatabase` | `TFIBDatabase` | Rename. The old name is a deprecated alias of the same class. |
| `TpFIBTransaction` | `TFIBTransaction` | Rename. The old name is a deprecated alias of the same class. |
| `TFIBLoginEvent`, `TOnLostConnectActions` (`laTerminateApp`, `laCloseConnect`, `laIgnore`, `laWaitRestore`), `TFIBLostConnectEvent`, `TFIBRestoreConnectEvent`, `TOnSQLExecute`, `WriteDBParamsToAlias` (unit `pFIBDatabase`) | The same names in `FIBDatabase` | Change the `uses` clause. The old unit exports them as aliases. |
| `TpFIBAcceptCacheSchema` | `TFIBAcceptCacheSchemaEvent` (unit `FIBDatabase`) | Rename. The old unit keeps the old name as a deprecated alias. |
| `TOnSQLExecute = procedure(Query: TFIBQuery; SQLType: TFIBSQLTypes) of object` | `procedure(Query: TComponent; SQLType: TFIBSQLTypes) of object` | Change the parameter type of the handlers you assign in code (`BeforeSQLExecute`, `AfterSQLExecute`, `AfterFirstFetch`). A handler bound in a form keeps working at run time; the IDE reports it as incompatible until you change it. |
| `FIBDataSets[Index]: TFIBCustomDataSet`, `FIBQueries[Index]: TFIBQuery` (of `TpFIBDatabase` and `TpFIBTransaction`) | `FIBDataSets[Index]: TDataSet`, `FIBQueries[Index]: TComponent` | Cast the result to `TFIBCustomDataSet` or `TFIBQuery`. The items and their order are the same. |
| `TFIBSQLTypes` and its 15 values (`SQLUnknown` ...) in `FIBQuery` | Declared in `FIBProps` | `FIBQuery` exports the type and the values, so code that uses only `FIBQuery` compiles without a change. |
| `TpFIBDatabaseEditor`, `TpFIBTransactionEditor`, `TpFIBTRParamsEditor` | `TFIBDatabaseEditor`, `TFIBTransactionEditor`, `TFIBTRParamsEditor` | Rename in design-time code that registers them. |
| IDE preferences of the database and the transaction (registry keys `pFIBDataBase`, `pFIBTransaction`) | registry keys `FIBDatabase`, `FIBTransaction` | The saved design-time defaults for new databases and transactions are not read from the old keys. Set them again once in the FIBPlus preferences. |
| Unit `pFIBProps` | `FIBProps` | Change the `uses` clause. The old unit still compiles, gives a warning, and exports the types, the values of the enumerated types (`poTrimCharFields`, `qoAutoCommit`, `tpbReadCommitted` ...) and the constants. |
| Writable defaults in `pFIBProps`: `DefaultOptions`, `DefaultPrepareOptions`, `DefaultDetailConditions`, `DefTPBMode`, `DefTimeOutAction`, `DefQueryOptions`, `DefCharSet`, `DefSQLDialect`, the `RDef...` and `dDef...` formats and the others | The same names, only in `FIBProps` | Add `FIBProps` to the `uses` clause of code that reads or sets them. The old unit cannot export a variable. |
| `TpFIBDsOption`, `TpFIBDsOptions` | `TFIBDataSetOption`, `TFIBDataSetOptions` | Rename. The old names are deprecated aliases in `pFIBProps`; the values (`poTrimCharFields` ...) are the same. |
| `TpPrepareOption`, `TpPrepareOptions` | `TFIBPrepareOption`, `TFIBPrepareOptions` | Rename. The old names are deprecated aliases in `pFIBProps`; the values (`pfImportDefaultValues` ...) are the same. |
| `TpFIBExistObject` | `TFIBExistObject` | Rename. The old name is a deprecated alias in `pFIBProps`. |
| `TpFIBDBEventType`, `TpFIBTrEventType` (unit `FIBDatabase`) | `TFIBDatabaseEventType`, `TFIBTransactionEventType` | Rename. The old names are deprecated aliases in `pFIBDatabase`, no longer in `FIBDatabase`. Calls like `AddEvent(Handler, detOnConnect)` do not name the type and need no change. |
| `TpSQLKind` (unit `FIBDataSet`) | `TFIBSQLKind` | Rename. The old name is a deprecated alias in `pFIBDataSet`, no longer in `FIBDataSet`. |
| Unit `pFIBSQLLog` | `FIBSQLLog` | Change the `uses` clause. The old unit still compiles and gives a warning. |
| `TpFIBStatistics` | `TFIBSQLLogger` | Rename. The old name is a deprecated alias in `pFIBSQLLog`. |
| Unit `pFIBDataInfo` | `FIBDataInfo` | Change the `uses` clause. The old unit stops the compilation with a message that names the new unit. |
| `TpFIBTableInfo`, `TpFIBTableInfoCollect`, `TpDataSetInfo`, `TpDataSetInfoCollect`, `TpErrorMessage`, `TpErrorMessagesCollect` (`pFIBDataInfo`) | `TFIBTableInfo`, `TFIBTableInfoCache`, `TFIBDataSetInfo`, `TFIBDataSetInfoCache`, `TFIBErrorMessage`, `TFIBErrorMessageCache` (`FIBDataInfo`) | Rename. No aliases. The variables `ListTableInfo`, `ListDataSetInfo` and `ListErrorMessages` keep their names. |
| Design-time units `pFIBComponentEditors`, `pFIBAutoUpdEditor` | `FIBComponentEditors`, `FIBAutoUpdEditor` | Change the `uses` clause of design-time code. There are no old units. |
| `TpFIBSQLPropEdit`, `TpFIBAutoUpdateOptionsEditor`, `TpFIBGeneratorsProperty`, `TpFIBDeltaReceiverEditor` | `TFIBSQLPropEdit`, `TFIBAutoUpdateOptionsEditor`, `TFIBGeneratorsProperty`, `TFIBDeltaReceiverEditor` | Rename in design-time code that registers them. |
| Units `pFIBLists`, `pFIBCacheQueries`, `pFIBEventLists`, `pFIBFieldsDescr`, `pFIBExports`, `pFIBInterfaces`, `pTestInfo` | `FIBLists`, `FIBCacheQueries`, `FIBEventLists`, `FIBFieldsDescr`, `FIBExports`, `FIBInterfaces`, `FIBTestInfo` | Change the `uses` clause. The old units stop the compilation with a message that names the new unit. The names inside the units are the same. |
| Include file `pFIBMacroComp.inc` | `FIBMacroComp.inc` | Only for code that includes it. |
| Design-time units `pFIBConditionsEdit`, `pFIBDBEdit`, `pFIBDataSetOptions`, `pFIBEditorsConsts`, `pFIBPreferences`, `pFIBRepositoryOperations`, `pFIBSyntaxMemo`, `pFIBTrEdit` | The same names without `p` | Change the `uses` clause of design-time code. There are no old units. `FIBPreferences` is in the `FIBTools` package (Delphi 10.4 and later). |
| Unit `pFIBClientDataSet` | `FIBClientDataSet` | Change the `uses` clause. The old unit still compiles and gives a warning. |
| `TpFIBClientDataSet`, `TpFIBDataSetProvider`, `TpFIBClientBCDField` | `TFIBClientDataSet`, `TFIBDataSetProvider`, `TFIBClientBCDField` | Rename. The old names are deprecated aliases of the same classes in `pFIBClientDataSet`. |
| Unit `IB_Services` | `FIBServices` | Change the `uses` clause. The old unit still compiles, gives a warning, and exports the types, the values of the enumerated types (`IgnoreLimbo`, `SweepDB`, `ActionAddUser` ...), `DefaultBufferSize` and `SPBPrefix`. |
| `TpFIBCustomService`, `TpFIBServerProperties`, `TpFIBControlService`, `TpFIBControlAndQueryService`, `TpFIBConfigService`, `TpFIBLogService`, `TpFIBStatisticalService`, `TpFIBBackupRestoreService`, `TpFIBBackupService`, `TpFIBRestoreService`, `TpFIBNBackupService`, `TpFIBNRestoreService`, `TpFIBValidationService`, `TpFIBSecurityService` | The same names with `TFIB` instead of `TpFIB` | Rename. The old names are deprecated aliases of the same classes in `IB_Services`. |
| `TFIBLicensingService`, `TpFIBLicensingService`, `TLicensingAction` (`LicenseAdd`, `LicenseRemove`) | Removed | The service added and removed InterBase license keys; Firebird has none, and InterBase registers licenses with its License Manager. Delete the component from forms and code: a form that contains it no longer loads. |
| Units `IB_Install`, `IB_InstallHeader`, `TpFIBInstall`, `TpFIBUnInstall`, `LoadIBInstallLibrary`, `FreeIBInstallLibrary`, `CheckIBInstallLoaded` and the `isc_install_...` variables (`IB_Intf`), symbol `IBINSTALL_SUPPORT`, `feInterBaseInstallMissing`, the messages `SCantLoadLibrary`, `SSuccess`, `SDelphiException`, `SNoOptionsSet`, `SNoDestinationDirectory`, `SNosourceDirectory`, `SNoUninstallFile`, `SOptionNeedsClient`, `SOptionNeedsServer`, `SInvalidOption`, `SInvalidOnErrorResult`, `SInvalidOnStatusResult` (`FIBConsts`) | Removed | They wrapped the InterBase 6 install library `ibinstall.dll`, which Firebird does not have. Remove them from the `uses` clause and the code. |
| `SPBConstantNames`, `SPBConstantValues` (`IB_Services`) | The same names, only in `FIBServices` | Add `FIBServices` to the `uses` clause of code that reads them. The old unit cannot export a typed constant. |
| `TFIBSQLMonitorHook.ServiceAttach`, `ServiceDetach`, `ServiceQuery`, `ServiceStart` (parameter `TpFIBCustomService`) | Parameter `TFIBCustomService` | The same class; rename in descendants that override them. |
| Unit `pFIBArray` | `FIBArray` | Change the `uses` clause. The old unit still compiles and gives a warning. |
| `TpFIBArray` | `TFIBArray` | Rename. The old name is a deprecated alias of the same class in `pFIBArray`. |
| `TFIBXSQLVAR.FIBArray`, `TFIBArrayStream.FIBArray` | `ArrayInfo` | Rename. The property had the name of the new unit `FIBArray`. There is no old name. |
| Unit `SIBFIBEA` | `FIBEventAlerter` | Change the `uses` clause. The old unit still compiles and gives a warning. |
| `TSIBfibEventAlerter` | `TFIBEventAlerter` | Rename. The old name is a deprecated alias of the same class in `SIBFIBEA`. |
| Variable `pFIBLoginDialog`, type `TpFIBLoginDialog` (unit `fib`) | `FIBLoginDialog`, `TFIBLoginDialogFunc` | Rename in code that installs its own login dialog (`pFIBLoginDialog := MyLoginDialog`) or tests the variable. There are no old names: a variable cannot have a deprecated alias, so the old code does not compile. |
| `pFIBLoginDialogEx` (`FIBDBLoginDlg`), `pFIBLoginDialogFMX` (`FIB_FMX_DBLoginDlg`) | `FIBLoginDialogEx`, `FIBLoginDialogFMX` | Rename in code that calls them. There are no old names. |

Forms that contain one of the old component classes still load. The classes `TpFIBDataSet`, `TpFIBDatabase`, `TpFIBTransaction`, `TpFIBClientDataSet`, `TpFIBDataSetProvider`, the field class `TpFIBClientBCDField`, `TpFIBDBSchemaExtract`, `TSIBfibEventAlerter` and the service components are registered by the units `pFIBDataSet`, `pFIBDatabase`, `pFIBClientDataSet`, `pFIBMetaData`, `SIBFIBEA` and `IB_Services`, so keep them linked (in a `uses` clause) until the form is saved again. The next time you save the form, the IDE writes the new class name. The old unit and names are removed in a later major version.

### Changed behavior

#### `TFIBDataSet` is the former `TpFIBDataSet`

The component on the palette was `TpFIBDataSet`. Its code is now in `TFIBCustomDataSet`, and `TFIBDataSet` (which had no code of its own) publishes the same properties as `TpFIBDataSet`, in the same order. A form that holds `TpFIBDataSet` loads as `TFIBDataSet` and nothing changes for it. You only notice the change when the code creates a `TFIBDataSet` or derives from `TFIBDataSet` or `TFIBCustomDataSet` directly: it now gets what the palette dataset always had.

- `CanEdit`, `CanInsert`, and `CanDelete` are also `True` when an update object of that kind is active, when SQL generation is on (`UpdateOnlyModifiedFields`, `AutoReWriteSqls`, `CanChangeSQLs`, `KeyFields`, and `UpdateTableName` all set), or with `CachedUpdates` and an `OnUpdateRecord` handler. Before, only a non-empty `InsertSQL`, `UpdateSQL`, or `DeleteSQL` allowed the change.
- `Post` and `Delete` run the update objects and the statements generated from `AutoUpdateOptions`. `ApplyUpdates`, `RefreshFromQuery`, `LockRecord`, `SaveToFile`, `OpenWP`, and the other members of `TpFIBDataSet` are available.
- `RecNo`, `RecordCount`, and `IsSequenced` follow `poVisibleRecno` and `psAskRecordCount`.
- Opening loads the repository settings of `DataSet_ID` (`psApplyRepositary`) and applies the field formats of `DefaultFormats`, and the events are sent to `Container` and to the global container.
- `ParamByName` and `FindParam` of the dataset exist; `FindParam` starts the transaction.
- `Prepare` no longer prepares `RefreshSQL` at design time.
- Each dataset creates two internal queries (record count and lock) and four lists. No server round trip is added.

A class that derives from `TpFIBDataSet` and overrides its virtual methods (`AddedFilterRecord`, `UpdateFieldsProps`, `IncGenerator`, `RecordCountFromSrv`, `DoOnApplyDefaultValue`) keeps working; the methods have the same signatures.

#### `TFIBDatabase` and `TFIBTransaction` are the former `TpFIBDatabase` and `TpFIBTransaction`

The components on the palette were `TpFIBDatabase` and `TpFIBTransaction`. Their code is now in `TFIBDatabase` and `TFIBTransaction`, which publish the same properties and events as the old classes, in the same order. A form that holds the old classes loads as the new ones, and `SaveDBParams` and `OnLogin` still load. You only notice the change when the code creates a `TFIBDatabase` or a `TFIBTransaction` directly or derives from them: they now get what the palette classes always had. The changes in behavior are these.

- `Open` on a connected database does nothing; it raised. `ForceClose` on a closed database does nothing; it raised.
- `StartTransaction` on an active transaction raises `EFIBClientError` (`feInTransaction`) for every transaction, before any event runs. `TpFIBTransaction` did nothing. `Active := True` on an active transaction still does nothing. Check `InTransaction` before `StartTransaction` where the transaction may be active.
- `AfterStart` and `AfterStartTransaction` run only when the transaction started. `TpFIBTransaction` also raised them when the start was skipped without an error (a database that could not be connected with `AutoReconnect`); `BeforeStart` still runs in that case.
- `BeforeConnect` (and `OnLogin`), the schema cache, and the alias on `Open` work for every connection. Nothing runs unless it is set: `CacheSchemaOptions` is off and `AliasName` is empty.
- `DifferenceTime` is used for every database when a new row gets a client time as its default value.
- Lost-connection handling by `TFIBErrorHandler` applies to every connection, see below.
- `CacheSchemaOptions := Value` in code copies the values into the existing object. It replaced the object before.

#### `TPBMode` and `TRParams`

A preset now writes its lines into `TRParams`, and `TRParams` is always exactly what is sent. The old `TpFIBTransaction` replaced `TRParams` at every start in a preset mode, and `TFIBTransaction` never did. The rule is in [Transaction mode](../reference/TFIBTransaction.md#transaction-mode).

- A new transaction has the lines of `tpbReadCommitted` in `TRParams` instead of an empty list. A `TFIBTransaction` created in code with untouched `TRParams` starts read committed with `nowait`, where it started with `concurrency` and `wait` (the server default of an empty list).
- A `TpFIBTransaction` with a preset whose `TRParams` were changed in code: the change was dropped at the start. Now it is used, and `TPBMode` reads `tpbDefault`.
- Write the access, isolation, and wait lines first, or use `Text :=`. After an extra line such as `no_auto_undo` the list is an ordinary list, and a later `read` or `nowait` conflicts with the preset lines: the server refuses the start.
- `lock_timeout` needs the full list, because *Firebird 3+* refuses it together with `nowait`, which every preset writes. `Add('lock_timeout=5')` on a preset leaves only that line. For a read-only transaction put `read` in `TRParams`; all presets write `write`.
- `TPBMode` cannot be set on an active transaction (`feInTransaction`). It was accepted and used at the next start. The same holds for `TRParams`.
- Do not change `TRParams` in `BeforeStart` or `BeforeStartTransaction`. The list is not reset at each start, so a line added there is added again at the next start, and the server refuses the duplicate. Set `TRParams` once, before the start.
- A form of an old `TFIBTransaction` with stored `TRParams.Strings` loads with those lines and `TPBMode` `tpbDefault`. Forms are saved in the same format as before.
- When the list sent to a database holds `read_consistency` and the server does not support it, `StartTransaction` raises `EFIBClientError` before the start. The list of a database is its own text from `AddDatabase(Db, TRParams)` when that is not empty, else `TRParams`.

#### Internal transactions

`TFIBTransaction.Internal` is new: public, not published, `False` by default. The events of the database (`BeforeStartTransaction`, `AfterStartTransaction`, `BeforeEndTransaction`, `AfterEndTransaction`) were raised only for `TpFIBTransaction`. Now they are raised for every transaction whose `DefaultDatabase` is the database, except for a transaction with `Internal` set to `True`. The library sets `Internal` on the transactions it creates for its own work (metadata, BLOB information, the internal transaction of the database, the SQL logger). A handler of these events now also sees a `TFIBTransaction` created in code. The transaction of `TFIBScripter` is not internal.

The transaction of the SQL logger uses `nowait` and no longer the server default `wait`: a lock conflict on its insert raises.

#### Lost connection

`TFIBErrorHandler` runs the lost-connection action (`OnLostConnect`, default `laCloseConnect`) on the database of the failing object: a database, a query, a transaction, or a BLOB stream. When the object gives no database (BLOB routines called without a sender, service components), the handler no longer acts on every database of the process. It pings each connected database and acts on those that report a lost connection. A lost service connection closes no database. This also changes applications with several `TpFIBDatabase` connections: only the database that was lost is closed and gets `OnLostConnect`. Every `TFIBDatabase` is handled now, not only `TpFIBDatabase`.

#### Role name in quotes

`TFIBDatabase` now sends `SQLDialect` in the DPB (`isc_dpb_sql_dialect`). Without it the server took dialect 1 for the attachment and uppercased the role name even inside quotes. A role written without quotes (`sql_role_name=MyRole`) is still uppercased (`MYROLE`), as before. A role written in quotes keeps its case: `sql_role_name="MyRole"` now selects a role created as `CREATE ROLE "MyRole"`. If the role was created without quotes (stored as `MYROLE`) and `DBParams` has it in quotes with other case, the connection now has no role (`CURRENT_ROLE` is `NONE`), without an error. Remove the quotes, write the name in uppercase, or add `sql_dialect=1` to `DBParams` for the old behavior.

## 7.9.1

### Build

| Change | What to do |
|--------|------------|
| The packages write DCU files to `$(BDSCOMMONDIR)\Dcu\FIBPlus\$(Platform)\$(Config)`. | Add that folder to the Library path if you link the DCU files instead of the sources. |
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
  // code for FIBPlus 7.9 and later
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

When `LibraryName` is `fbclient.dll` without a path and that library cannot be loaded, FIBPlus loads `gds32.dll`. An application that ships the Firebird client renamed to `gds32.dll` keeps working, but:

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
- `TFIBStringField.AsAnsiString` returns the column bytes with their code page set. Calculated and lookup `ftString` fields use the system code page.

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

- [CHANGELOG.md](../../CHANGELOG.md) in the repository root, for the complete list including bug fixes
- [Connections](connections.md)
- [Firebird versions](firebird-versions.md)
- [Timeouts](timeouts.md)
