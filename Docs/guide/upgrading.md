# Upgrading

This article lists what an existing application must know or do when it moves to a newer FIBPlus version: breaking changes, changed behavior, renamed or removed identifiers, deprecated members, and build changes. It does not list bug fixes or new features. For the complete list, see [CHANGELOG.md](../../CHANGELOG.md) in the repository root.

## How to use this page

Find the version you use now, then read every section above it, from the one just after your version up to the version you are moving to. Sections are ordered like the changelog, newest first.

| Version | Status | Notes |
|---------|--------|-------|
| [8.0.0](#800) | Unreleased | Delphi 2009 or later. Classes and units renamed from `TpFIB...` and `pFIB...` to `TFIB...` and `FIB...` (the old names stay as deprecated aliases), the `TpFIB...` components merged into the `TFIB...` ones, packages renamed, `TRParams` filled by `TPBMode`, translated error messages. |
| [7.9.1](#791) | 2026-10-09 | Text in the code page of each column's character set, *Firebird 4+* statement and idle timeouts and read consistency, *Firebird 5+* parallel workers, an FMX login dialog package, and many bug fixes. |
| [7.9.0](#790) | 2026-10-01 | First release of the community maintained FIBPlus. Based on the FIBPlus 7 sources of build 632 (2014-02-17). |

## 8.0.0

### Build

| Change | What to do |
|--------|------------|
| Delphi 6, 7, 2005, 2006, 2007 and C++Builder 6 to 2007 are no longer supported; their packages are removed. Compiling with them stops with a fatal message. | Stay on 7.9.x, or move to Delphi 2009 or later. |
| The include file `FIBPlus.inc` is renamed to `FIB.inc`. | Change `{$I FIBPlus.inc}` to `{$I FIB.inc}` in code that includes it. |
| The unit `fib` is renamed to `FIB` (`Source\FIB.pas`). | Nothing in Delphi code: unit names ignore the case. In C++Builder, include `FIB.hpp` instead of `fib.hpp` where the file system is case-sensitive. |
| The login dialog units `FIBDBLoginDlg` and `FIB_FMX_DBLoginDlg` are renamed to `FIBLoginDlg` and `FIBLoginDlgFMX`. The form classes `TfrmFIBDBLoginDlg` and `TfmxFIBDBLoginDlg` are now `TFIBLoginForm` and `TFIBLoginFormFMX`. | Change the `uses` clause: `FIBDBLoginDlg` → `FIBLoginDlg`, `FIB_FMX_DBLoginDlg` → `FIBLoginDlgFMX`. |
| `Source\FIB_MESSAGES.INC` moved to `Locales\en\Errors.inc`, and `Resources\Russian` to `Locales\ru`. The language of the messages and of the login dialog is set in `Source\FIBLocale.inc`, for example `FIBLocale = 'ru';`; see [Localization](localization.md). | If you copied a translation over `Source\FIB_MESSAGES.INC`, set its code in `FIBLocale.inc` instead. `FIB.pas` and `FIBConsts.pas` include the files from `..\Locales`, so keep the `Locales` folder next to `Source`. |
| The compiler version symbols of `FIB.inc` are renamed to `C<CompilerVersion>`: `D2010+` → `C21`, `D_XE` → `C22`, `D_XE2` → `C23`, `D_XE3` → `C24`, `D_XE4` → `C25`, `D_XE5` → `C26`, `D_20`..`D_29` → `C27`..`C36`, `D_30` → `C37`. `TWideDataSet` (Delphi 2009 to XE2) is removed: test `{$IFNDEF C24}`. | Only for code that includes `FIB.inc` and tests these symbols: rename them. |
| `D6+`, `D7+`, `D2005+`, `D2006+`, `D2007+`, `D2009+` and `NO_USE_COMP` are removed from `FIB.inc`. With Delphi 2009 and later they were always defined. | Only for code that includes `FIB.inc`: a test of these symbols now takes the other branch without a warning. Keep the code of the `{$IFDEF D2009+}` branch (or of `{$IFDEF NO_USE_COMP}`) and remove the test. |
| The `FIB.inc` switches `USE_DEPRECATE_METHODS2` and `DFM_VERSION1` are removed, with what they enabled: `OnUserEvent` and `ReceiveEvents` of the dataset, `UserEvent`, `NotifyDataSets` and `OnUserEvent` of `TDataSetsContainer`, `TUserEvent`, and forms saved in the old format. | They no longer compiled. Nothing to do. |
| The packages write DCU files to `$(BDSCOMMONDIR)\Dcu\FIB\$(Platform)\$(Config)` instead of `$(BDSCOMMONDIR)\Dcu\FIBPlus\$(Platform)\$(Config)`. | If the Library path has the old folder, replace it with the new one, and delete the old folder. |

### Packages

The runtime package is `FIBCore` (`FIBCore_Dxx` before 10.4) and its design time package is `dclFIBCore` (`dclFIBCore_Dxx`): a design time package has the name of the runtime package it registers, with `dcl` before it. Delphi 10.4 and later have one package of each kind for all versions (`{$LIBSUFFIX AUTO}`) in `FIB.groupproj`. Older versions have the [package version](https://docwiki.embarcadero.com/RADStudio/en/Compiler_Versions) in the name (`FIBCore_D12` for 120) and the project groups `FIB_Dxx.groupproj`.

| Delphi | Old | New |
|--------|-----|-----|
| 10.4 to 13 | `FIBPlus_D27`..`FIBPlus_D37` | `FIBCore` (`FIBCore270.bpl`..`FIBCore370.bpl`) |
| 10.4 to 13 | `FIBPlusFMX` (Delphi 13 only) | `FIBFMX` (`FIBFMX270.bpl`..`FIBFMX370.bpl`) |
| 10.4 to 13 | `DclFIBPlus_Dxx`, `FIBPlusEditors_Dxx` | `dclFIBCore` (`dclFIBCore270.bpl`..`dclFIBCore370.bpl`) |
| XE6 to 10.3 | `FIBPlus_D20`..`FIBPlus_D26` | `FIBCore_D20`..`FIBCore_D26` |
| XE2 to XE5, XE7 | `FIBPlus_XE2`..`FIBPlus_XE5`, `FIBPlus_XE7` | `FIBCore_D16`..`FIBCore_D19`, `FIBCore_D21` |
| 2009, 2010, XE | `FIBPlus2009`, `FIBPlus2010`, `FIBPlus2011` | `FIBCore_D12`, `FIBCore_D14`, `FIBCore_D15` |
| 2009 to 10.3 | `DclFIBPlus_Dxx`, `FIBPlusEditors...` | `dclFIBCore_Dxx` |

- In **Component > Install Packages**, remove the old packages, then build and install the new ones from the project group.
- Applications built with runtime packages: replace the old name in the runtime packages list and deploy the new BPL.
- Packages that require the old runtime package (your own, or third-party ones such as the EhLib and FastReport FIBPlus packages and the Data Abstract FIBPlus driver) must require the new one.
- The design-time defaults saved in the FIBPlus preferences are read by `dclFIBTools` (Delphi 10.4 and later). Without it installed, new components get the built-in defaults.

### Renamed classes and units

Classes, types and units lost the `p` of their names. The old units below stay as deprecated units: a `uses` clause that names one compiles with a warning, and the old names are deprecated aliases declared in the old unit. Forms with the old component classes load while the old unit is linked, and the IDE writes the new class names the next time the form is saved. The old units and names are removed in a later major version.

| Old unit | New unit | Old names → new names |
|----------|----------|-----------------------|
| `pFIBDataSet` | `FIBDataSet` | `TpFIBDataSet` → `TFIBDataSet`, `TpSQLKind` → `TFIBSQLKind` (`TpSQLKind` was declared in `FIBDataSet` before: code that uses it with only `FIBDataSet` must use the new name or add `pFIBDataSet`). Also exports `TLockStatus`, `TLockErrorEvent`, `TCachRefreshKind`, `TOnGetSQLTextProc`, `TIncludeFieldsToSQL`, `FieldInArray`. |
| `pFIBDatabase` | `FIBDatabase` | `TpFIBDatabase` → `TFIBDatabase`, `TpFIBTransaction` → `TFIBTransaction`, `TpFIBDBEventType` → `TFIBDatabaseEventType`, `TpFIBTrEventType` → `TFIBTransactionEventType` (both were declared in `FIBDatabase` before: code that uses them with only `FIBDatabase` must use the new names or add `pFIBDatabase`), `TpFIBAcceptCacheSchema` → `TFIBAcceptCacheSchemaEvent`. Also exports `TFIBLoginEvent`, `TOnLostConnectActions` (`laTerminateApp` ...), `TFIBLostConnectEvent`, `TFIBRestoreConnectEvent`, `TOnSQLExecute`, `WriteDBParamsToAlias`. |
| `pFIBQuery` | `FIBQuery`, `FIBDataSet` | `TpFIBQuery` → `TFIBQuery`, `TpFIBUpdateObject` → `TFIBUpdateObject` (in `FIBDataSet`). |
| `pFIBStoredProc` | `FIBStoredProc` | `TpFIBStoredProc` → `TFIBStoredProc`. |
| `pFIBScripter` | `FIBScripter` | `TpFIBScripter` → `TFIBScripter`, `TpFIBScriptParser` → `TFIBScriptParser`. |
| `pFIBErrorHandler` | `FIBErrorHandler` | `TpFibErrorHandler` → `TFIBErrorHandler`. |
| `pFIBDataRefresh` | `FIBDataRefresh` | `TpFIBTableChangesReader` → `TFIBTableChangesReader`. |
| `pFIBProps` | `FIBProps` | `TpFIBDsOption(s)` → `TFIBDataSetOption(s)`, `TpPrepareOption(s)` → `TFIBPrepareOption(s)`, `TpFIBQueryOption(s)` → `TFIBQueryOption(s)`, `TpFIBExistObject` → `TFIBExistObject`, `TpFIBFieldInfo` → `TFIBFieldInfo` (also in handlers of `TDataSetsContainer.OnApplyFieldRepository`). Also exports the types, the values of the enumerated types (`poTrimCharFields`, `qoAutoCommit`, `tpbReadCommitted` ...), the constants and the writable defaults (`DefaultOptions`, `DefaultPrepareOptions`, `DefaultDetailConditions`, `DefTPBMode`, `DefQueryOptions`, `DefSQLDialect`, the `RDef...` and `dDef...` formats and the others); an assignment through the old unit changes the value in `FIBProps`. |
| `pFIBMetaData` | `FIBMetaData` | `TpFIBDBSchemaExtract` → `TFIBDBSchemaExtract`. Also exports the types, the values of the enumerated types, the constants and `FullExtractDDL`. |
| `pFIBSQLLog` | `FIBSQLLog` | `TpFIBStatistics` → `TFIBSQLLogger`. |
| `pFIBClientDataSet` | `FIBClientDataSet` | `TpFIBClientDataSet` → `TFIBClientDataSet`, `TpFIBDataSetProvider` → `TFIBDataSetProvider`, `TpFIBClientBCDField` → `TFIBClientBCDField`. |
| `pFIBArray` | `FIBArray` | `TpFIBArray` → `TFIBArray`. |
| `IB_Services` | `FIBServices` | `TpFIBCustomService`, `TpFIBServerProperties`, `TpFIBControlService`, `TpFIBControlAndQueryService`, `TpFIBConfigService`, `TpFIBLogService`, `TpFIBStatisticalService`, `TpFIBBackupRestoreService`, `TpFIBBackupService`, `TpFIBRestoreService`, `TpFIBNBackupService`, `TpFIBNRestoreService`, `TpFIBValidationService`, `TpFIBSecurityService` → the same names with `TFIB`. Also exports the types, the values of the enumerated types (`IgnoreLimbo`, `SweepDB`, `ActionAddUser` ...), `DefaultBufferSize`, `SPBPrefix`, `SPBConstantNames` and `SPBConstantValues`; an assignment through the old unit changes the value in `FIBServices`. |
| `SIBFIBEA` | `FIBEventAlerter` | `TSIBfibEventAlerter` → `TFIBEventAlerter`. |

These have no old name, so the code that uses them must change:

| Old | New | What to do |
|-----|-----|------------|
| Variable `pFIBLoginDialog`, type `TpFIBLoginDialog` (unit `fib`), functions `pFIBLoginDialogEx` (`FIBLoginDlg`) and `pFIBLoginDialogFMX` (`FIBLoginDlgFMX`) | `FIBLoginDialog`, `TFIBLoginDialogFunc`, `FIBLoginDialogEx`, `FIBLoginDialogFMX` | Rename in code that installs its own login dialog, tests the variable or calls the functions. |
| Texts of the login dialog in `FIBConsts`: `SLoginDlgLoginCaption`, `SDBEditUserName`, `SDBEditPassword`, `SDBEditSQLRole`, `SOKButton`, `SCancelButton` | `SLoginDlgCaption`, `SLoginDlgUserName`, `SLoginDlgPassword`, `SLoginDlgRole`, `SLoginDlgOK`, `SLoginDlgCancel` (`SLoginDlgDatabase` keeps its name) | Rename in code that uses them, for example an own login dialog. They are now translated with `FIBLocale`. |
| `TFIBXSQLVAR.FIBArray`, `TFIBArrayStream.FIBArray` | `ArrayInfo` | Rename. The property had the name of the new unit `FIBArray`. |
| Units `pFIBDataInfo`, `pFIBLists`, `pFIBCacheQueries`, `pFIBEventLists`, `pFIBFieldsDescr`, `pFIBExports`, `pFIBInterfaces`, `pTestInfo` | The same names without `p` (`FIBTestInfo` for `pTestInfo`) | Change the `uses` clause. The old units stop the compilation with a message that names the new unit. The names inside the units are the same, except those of the next row. `TpFIBFieldInfo` (now `TFIBFieldInfo`), `TExtBoolean` and its values `eFalse`, `eTrue`, `eUnknown` of `pFIBDataInfo` are in `FIBProps`: replace `pFIBDataInfo` with `FIBDataInfo`, and add `FIBProps` when you use them. |
| Include file `pFIBMacroComp.inc` | `FIBMacroComp.inc` | Change the `{$I}` directive. The old file is gone: the build fails with "File not found". |
| `TpFIBTableInfo`, `TpFIBTableInfoCollect`, `TpDataSetInfo`, `TpDataSetInfoCollect`, `TpErrorMessage`, `TpErrorMessagesCollect` (`pFIBDataInfo`) | `TFIBTableInfo`, `TFIBTableInfoCache`, `TFIBDataSetInfo`, `TFIBDataSetInfoCache`, `TFIBErrorMessage`, `TFIBErrorMessageCache` (`FIBDataInfo`) | Rename. The variables `ListTableInfo`, `ListDataSetInfo` and `ListErrorMessages` keep their names. |
| Design-time units `pFIBComponentEditors`, `pFIBAutoUpdEditor`, `pFIBConditionsEdit`, `pFIBDBEdit`, `pFIBDataSetOptions`, `pFIBEditorsConsts`, `pFIBPreferences`, `pFIBRepositoryOperations`, `pFIBSyntaxMemo`, `pFIBTrEdit`; `RegFIBPlus`, `RegFIBPlusEditors` | The same names without `p`; `RegFIB`, `RegFIBEditors` | Change the `uses` clause of design-time code. `FIBPreferences` is in the `dclFIBTools` package (Delphi 10.4 and later). |
| Editors `TpFIBDataSetOptionsEditor`, `TpFIBDatabaseEditor`, `TpFIBTransactionEditor`, `TpFIBTRParamsEditor`, `TpFIBSQLPropEdit`, `TpFIBAutoUpdateOptionsEditor`, `TpFIBGeneratorsProperty`, `TpFIBDeltaReceiverEditor` | The same names with `TFIB` | Rename in design-time code that registers them. |
| IDE preferences in the registry keys `pFIBDataSet`, `pFIBQuery`, `pFIBDataBase`, `pFIBTransaction` | Keys `FIBDataSet`, `FIBQuery`, `FIBDatabase`, `FIBTransaction` | The saved design-time defaults for new components are not read from the old keys. Set them again once in the FIBPlus preferences (**Tools > FIBPlus > Preferences...**). They are read only by `dclFIBTools` (Delphi 10.4 and later): without it installed, they are not applied. |

### Changed types and signatures

| Old | New | What to do |
|-----|-----|------------|
| `TFIBQuery.FN` (missing column returned `nil`) | `TFIBQuery.FindField` | `FN` now raises for a missing column, as `TpFIBQuery.FN` did. Replace `FN` with `FindField` where you test the result for `nil`. |
| `TFIBUpdateObject.DataSet: TFIBDataSet` | `TFIBCustomDataSet` | Any FIBPlus dataset is accepted. Code that reads the property needs a cast to `TFIBDataSet` to use the published members, and `QSelect`, `Params`, `Prepared` and similar are protected in `TFIBCustomDataSet`. |
| `TOnSQLExecute = procedure(Query: TFIBQuery; SQLType: TFIBSQLTypes) of object` | `procedure(Query: TComponent; SQLType: TFIBSQLTypes) of object` | Change the parameter type of the handlers you assign in code (`BeforeSQLExecute`, `AfterSQLExecute`, `AfterFirstFetch`). A handler bound in a form keeps working at run time; the IDE reports it as incompatible until you change it. |
| `FIBDataSets[Index]: TFIBCustomDataSet`, `FIBQueries[Index]: TFIBQuery` (of `TpFIBDatabase` and `TpFIBTransaction`) | `FIBDataSets[Index]: TDataSet`, `FIBQueries[Index]: TComponent` | Cast the result to `TFIBCustomDataSet` or `TFIBQuery`. The items and their order are the same. |
| `TFIBSQLTypes` and its values (`FIBQuery`), `TOnBlobFieldProcessing` (`FIBDataSet`), `TExtBoolean` (`pFIBDataInfo`) | Declared in `FIBProps` | `FIBQuery` and `FIBDataSet` export `TFIBSQLTypes` and `TOnBlobFieldProcessing`, so that code compiles without a change. `FIBDataInfo` does not export `TExtBoolean`: add `FIBProps`. The `FIBDataInfo` routines that took `TFIBDataSet` now take `TFIBCustomDataSet`. |
| `TFIBTableInfo.TableName`, `TFIBFieldInfo.DefaultValue`, `DomainName`, `DisplayLabel`, `EditFormat`, `DisplayFormat`, `TFIBErrorMessage.ErrorMsg` (`AnsiString`) | `string` | Nothing for most code. Assigning them to an `AnsiString` loses the characters outside the system code page, as before. `TFIBFieldInfo.LoadFromStream` has a new `UTF8` parameter (default `True`, the format `SaveToStream` writes now). |
| `StrUtil.TFastStringStream` (an alias of `TStringStream` on Delphi XE5 and later, an own class before), parameter of `GenerateDDLText`, `GenerateObjectDDL` and the other DDL methods of `FIBMetaData` | `TStringStream` | Rename in descendants that override these methods. Create the stream with `TEncoding.Unicode`, as `GetAsDDL` does, to keep the characters outside the system code page. |
| `TFIBSQLMonitorHook.ServiceAttach`, `ServiceDetach`, `ServiceQuery`, `ServiceStart` (parameter `TpFIBCustomService`) | Parameter `TFIBCustomService` | The same class; rename in descendants that override them. |
| `ListErrorMessages.ErrorMessage(Tr, ErrorName)` (`TFIBErrorMessageCache`) | `ErrorMessage(DB, Tr, ErrorName)` | Pass the database whose `FIB$ERROR_MESSAGES` is read; it must be one of the databases of `Tr`. |
| `TFIBDataSet.FetchNext(FetchCount: DWORD)` | `FetchNext(FetchCount: Integer)` | Nothing for most code. A negative count fetches no row; it fetched all the rows: call `FetchAll` instead. |
| `FixStartTime: Integer` of `ISQLStatMaker` and `TTestInfo` | `FixStartTime: Cardinal` | Change the result type in classes that implement `ISQLStatMaker`. |
| `TFIBDataSet.DefaultFields` (redeclared by FIBPlus) | *Delphi XE6+*: `TDataSet.DefaultFields` | The compiler reports it as deprecated; use `Fields.LifeCycles`. The result is the same. Delphi 2009 to XE5 keep the FIBPlus property. |
| `TFIBDatabase.ClientMajorVersion`, `ClientMinorVersion` (deprecated) | Read from `isc_get_client_major_version` and `isc_get_client_minor_version` | The same values. A client library without these functions (InterBase 6.0 and older) raises `EAPICallException`. Use `ClientLibrary.Version`. |
| `DataConvert(Field, Source, Dest: Pointer; ToNative)` of `TFIBCustomDataSet` (public) and `TFIBClientDataSet`, `GetCalcFields(Buffer: TRecordBuffer)` of `TFIBCustomDataSet` | Delphi XE3 and later: `DataConvert(Field, Source: TValueBuffer; var Dest: TValueBuffer; ToNative)`; XE4 and later: `GetCalcFields(Buffer: TRecBuf)` | Override the new overloads in descendants. Code calling the deprecated `TField.GetData`/`SetData` with a pointer and `NativeFormat = False` gets the `TDataSet` conversion. |
| `TFIBDatabase.AliasName`, `DBFileName`, `DBSiteName`; `TFIBCustomService.ServerName`, `TFIBRestoreService.FixCharset`; `TFIBBlobStream.TableName`, `FieldName`; `SPBConstantNames`; `TFIBFieldDescr.fdRelationTable`, `fdRelationField`, `fdTableAlias` (`AnsiString`) | `string` | Nothing for most code. `DBFileName`, `DBSiteName` and the text of the services are decoded as UTF-8 when the server sends valid UTF-8, else in the system code page. |
| `TFIBQuery.BatchInputRawFile(FileName: AnsiString)`, `BatchOutputRawFile(FileName: AnsiString; ...)`, `TFIBInputDelimitedFile.GetColumn(var Col: AnsiString)` | `string` parameters | Pass a `string`; an `AnsiString` variable for `GetColumn` must become a `string`. |
| `TFIBControlService.ServiceStartAddParam(Value: AnsiString; Param)` (protected) | `ServiceStartAddParam(const Value: string; Param)` | The value is encoded in the system code page. A `UTF8String` (`UTF8Encode`) still converts right; an `AnsiString` filled with UTF-8 bytes does not: pass the text, the Firebird 3+ client converts the system code page to UTF-8 itself. |
| `StrUtil.GetNameAndValue(S; var Name, Value: AnsiString)` | `var Name, Value: string` | Declare the variables as `string`. |
| `GenerateTPB(sl, TPB, TPBLength, IsFB21orMore)` (`FIB`) | New last parameter `NameCodePage: Word = 0` | Nothing: `TFIBTransaction` passes the metadata code page of the connection for the `lock_read`/`lock_write` table names; the default is the system code page. |
| `FIBAlloc(var p; OldSize, NewSize: DWORD)` (`FIB`) | `OldSize, NewSize: NativeInt` | Nothing for most code. |
| `TFIBCustomTimer.Interval: Integer` (`FIBSafeTimer`, alias `TFIBTimer` in `StdFuncs`), `TFIBDataSet.WaitEndMasterInterval: Integer` | `Cardinal`, like `TTimer.Interval` | Use 0, not a negative value, for no delay: a negative variable now becomes a long interval. |
| `IIbClientLibrary.isc_interprete`, `fb_Interpret` returning `ISC_STATUS` | `ISC_LONG` | The same type on Win32. On Win64 change the result type in classes that implement `IIbClientLibrary`. |
| `TFIBDatabase.IsMemoSubtype(aSubtype: ShortInt)`, `TMemoSubtypes.IsMemoSubtype` | `aSubtype: SmallInt` | Nothing. |
| `SIB_QueEvents`, `SIB_EventCounts` (`SIBAPI`) with `Length: SIB_UShort` | `Length: SIB_Short` | Nothing: the event buffer of `isc_event_block` is far below 32767 bytes. |
| `SIB_Status = SIB_Long` (`SIBAPI`, the entries of `SIB_StatusVector`) | `ISC_STATUS` | Nothing on Win32. On Win64 the vector has 64-bit entries, as the client writes them. |
| `IIBClientLibrary.isc_event_counts(status_vector: PISC_STATUS; ...)`, `Tisc_event_counts` (`ibase`); `SIB_EventCounts(...; Status: SIB_PStatusVector; ...)` | `event_counts: PUISC_LONG`, as `ISC_ULONG*` in the C header; `Counts: SIB_PEventCountVector` | Pass an array of `UISC_LONG` (the counts are 32-bit values, also on Win64) and change the parameter type in classes that implement `IIBClientLibrary`. |
| `TFIBFieldDescrList.LoadFromStream(Stream; StreamVersion: Byte)` | `StreamVersion: Integer` | Nothing. |

### Removed identifiers

| Removed | What to do |
|---------|------------|
| `StrUtil.CharInSet`, `FIBPlatforms.WideCompareStr` (declared only for compilers before Delphi 2009) | Nothing: `SysUtils` declares both. |
| `IWideStringField` with its properties `WideDisplayText`/`WideText`, implemented by `TFIBMemoField` (`GetWideDisplayText`, `GetWideEditText`, `SetWideEditText`), for the TNT controls | Use `DisplayText`, `Text` or `AsString`. |
| `FIBCharSets.DecodeWideString` | Use `DecodeString`; assign the result to a `WideString` if the type matters. |
| `AsComp` of `TFIBBCDField`, `TFIBClientBCDField`, `TFIBXSQLVAR` (compiled only without `NO_USE_COMP`, which `FIBPlus.inc` always defined) | Use `AsBcd` or `AsInt64`. |
| `SFIBErrorNotDataSet`, `SFIBErrorNotDataSetDetail` (`FIBConsts`) | Nothing: nothing raises them any more. |
| `SCodePageNotAvailable`, `SCannotTransliterate` (`FIBConsts`) | The errors are `feCodePageNotAvailable` and `feCantTransliterate` now; see [Codes of client errors](#codes-of-client-errors). |
| `TFIBLicensingService`, `TpFIBLicensingService`, `TLicensingAction` (`LicenseAdd`, `LicenseRemove`) | The service added and removed InterBase license keys; Firebird has none, and InterBase registers licenses with its License Manager. Delete the component from forms and code: a form that contains it no longer loads. |
| `TMetaTable.GenerateDDLTextOnlyTable` (protected) | Call `GenerateObjectDDL`, then write the terminator. |
| Editors units `FindCmp` and `uFrmSearchResult` (**Find Component**, which no menu opened) | Remove them from the `uses` clause of design-time code. |
| Editors unit `RegistryUtils` | Use `RegUtils`, which has the same routines (`DefReadFromRegistry`, `DefWriteToRegistry` and the others). |
| Units `IB_Install`, `IB_InstallHeader`, `TpFIBInstall`, `TpFIBUnInstall`, `LoadIBInstallLibrary`, `FreeIBInstallLibrary`, `CheckIBInstallLoaded` and the `isc_install_...` variables (`IB_Intf`), symbol `IBINSTALL_SUPPORT`, `feInterBaseInstallMissing`, the messages `SCantLoadLibrary`, `SSuccess`, `SDelphiException`, `SNoOptionsSet`, `SNoDestinationDirectory`, `SNosourceDirectory`, `SNoUninstallFile`, `SOptionNeedsClient`, `SOptionNeedsServer`, `SInvalidOption`, `SInvalidOnErrorResult`, `SInvalidOnStatusResult` (`FIBConsts`) | They wrapped the InterBase 6 install library `ibinstall.dll`, which Firebird does not have. Remove them from the `uses` clause and the code. |

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
- `AfterStart` and `AfterStartTransaction` run only when the transaction started. `TpFIBTransaction` also raised them when the start was skipped without an error (a database that could not be connected with `AutoReconnect`); that start raises now, see [Failed reconnects and inactive transactions](#failed-reconnects-and-inactive-transactions). `BeforeStart` still runs in that case.
- `BeforeConnect` (and `OnLogin`), the schema cache, and the alias on `Open` work for every connection. Nothing runs unless it is set: `CacheSchemaOptions` is off and `AliasName` is empty.
- `DifferenceTime` is used for every database when a new row gets a client time as its default value.
- Lost-connection handling by `TFIBErrorHandler` applies to every connection, see below.
- `CacheSchemaOptions := Value` in code copies the values into the existing object. It replaced the object before.

#### Failed reconnects and inactive transactions

Errors of a reconnect are no longer hidden, and ending an inactive transaction no longer starts one.

- With `AutoReconnect` (and `CheckActive(True)`), a failed connect raises the error of the last attempt from the call that needed the connection. It was swallowed and `Connected` stayed `False`.
- `StartTransaction` raises `EFIBClientError` (`feDatabaseClosed`) when a database of the transaction is still not connected. It returned with the transaction inactive. A form with a stored active transaction and a closed database shows the error in the IDE while it loads.
- `Commit`, `Rollback`, `CommitRetaining`, and `RollbackRetaining` of an inactive transaction raise `feNotInTransaction` before `BeforeEnd` and the database's `BeforeEndTransaction` run. With `AutoReconnect` on every database, and at design time, they started and ended a transaction. Test `InTransaction` first where the transaction may be inactive.
- `CheckInTransaction` only raises; it no longer starts the transaction. Queries, datasets, `ExecSQLImmediate`, and `TFIBDatabase.ApplyUpdates` still start it at design time and with `AutoReconnect`, as before.

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

#### Event registration errors

`TFIBEventAlerter.RegisterEvents` queues the first events in the calling thread, before the event threads start. An error there (an invalid database handle, a server whose events port can't be reached through a firewall or a Docker port mapping) now raises from `RegisterEvents` and from `Registered := True`, and the alerter stays unregistered. Before, the event thread ended and showed the error with `ShowException`, and `RegisterEvents` returned as if the events were registered. With `AutoRegister` the error raises from `Database.Open` (or `Connected := True`; when a form with a connected database is loaded, the form is not created) with the database already connected. `Open` completes the connect before it raises: the other handlers added with `AddEvent(..., detOnConnect)`, the connect notifications of the components, the SQL log entry and the end of `Open` (the schema cache file, `SaveAliasParamsAfterConnect`, the end of a restore-connect wait) run first, then `Open` raises the first error of these handlers. Put `Open` in a `try..except` that handles `ESIBError` (`SIBGlobals`), or register the events yourself after `Open`.

Errors of a running event thread, such as a lost connection, go to the new `OnError` event. Without a handler they go to `Classes.ApplicationHandleException` in the main thread (`Application.OnException` or the error dialog), not to `SysUtils.ShowException`; with `VCLSynchronize = False` they still go to `SysUtils.ShowException`. `OnError` runs after the alerter has cancelled all registrations: `Registered` is already `False` there, so `UnRegisterEvents` in the handler raises "Events not registered"; `Registered := False` does nothing, and `RegisterEvents` registers again.

#### Role name in quotes

`TFIBDatabase` now sends `SQLDialect` in the DPB (`isc_dpb_sql_dialect`). Without it the server took dialect 1 for the attachment and uppercased the role name even inside quotes. A role written without quotes (`sql_role_name=MyRole`) is still uppercased (`MYROLE`), as before. A role written in quotes keeps its case: `sql_role_name="MyRole"` now selects a role created as `CREATE ROLE "MyRole"`. If the role was created without quotes (stored as `MYROLE`) and `DBParams` has it in quotes with other case, the connection now has no role (`CURRENT_ROLE` is `NONE`), without an error. Remove the quotes, write the name in uppercase, or add `sql_dialect=1` to `DBParams` for the old behavior.

#### Schema cache files

The schema cache files (`CacheSchemaOptions.LocalCacheFile` and its `.dt` and `.err` files, `SaveSchemaToFile`) keep their texts in UTF-8. Files saved by older versions are still read. Older versions ignore the new `.err` file, but read the other two as text in the system code page and garble the characters outside ASCII (SQL texts, defaults, labels), so delete these files when you go back to an older version.

#### Dataset streams and batch files

`TFIBDataSet.SaveToStream` (and `SaveToFile`) writes stream version 8 and `BatchOutputRawFile` writes raw file version 4: the field, relation, alias and parameter names are in UTF-8, as in the data packets of `TClientDataSet`, no longer in the system code page, where the characters outside it became `?`. Streams of version 7 and raw files of versions 1 to 3 written by older versions are still read; a newer version raises `feFormatVersionNotSupported`. Older versions can't read the new streams and files: pass `Version = 3` to `BatchOutputRawFile` for a file that 7.x must read. The BLOB swap files (`BlobSwapSupport`) have a new version as well: the files written before are not used and are written again on the next read.

#### Codes of client errors

The errors of array fields and parameters, of the conversion to a code page, of the `ORDER BY` of a dataset with a limited cache and of the metadata load had `SQLCode` -1 and an English text. They now have their own value in `TFIBClientError` (`feArrayColumnNotFound` to `feCantLoadMetadata`), `SQLCode` is its ordinal, and the text follows `FIBLocale`. Code that tested `SQLCode = -1` for them must test the new value, for example `E.SQLCode = Ord(feArrayValueNotArray)`.

A feature that the client library doesn't support raises `feClientFeatureNotSupported` ("... is not supported by the client library ..."), no longer `feFeatureNotSupported`, which stays for a feature that the server doesn't support.

#### Schema extract

- `GetDDLText`, `GetObjectDDL`, `AsDDL` and `FullExtractDDL` write the descriptions as `COMMENT ON` statements; see the [changelog](../../CHANGELOG.md). `TFIBDBSchemaExtract.DDLTextOptions` is `[dtoIncludeComments]` by default, and `DefDDLTextOptions` of `TMetaDataBase` has it too. A form saved before has `DDLTextOptions = []` stored and writes no comments: add `dtoIncludeComments` in the Object Inspector. Remove the option to get the old output.
- `LoadOptions.DBObjects` defaults to `DefObjects`, which now has `otStoredFunctions` and `otPackage`, also for `TMetaDataBase` and `FullExtractDDL`. A form saved with the old default stores no value and now extracts the PSQL functions and packages too; a set chosen in the Object Inspector stays. Remove the two values to get the old output.
- The script of `GetDDLText` writes the database and DDL triggers at the end, and with *Firebird 3+* a generator as `CREATE GENERATOR g START WITH n` (with `INCREMENT BY m` when the step is not 1) before `SET GENERATOR`. Tools that compare scripts made by different versions show these differences.
- `TMetaGenerator.Value` is `Int64`. Code that assigns it to an `Integer` still compiles but cuts values over 2147483647: use an `Int64` variable.
- `DDLTextOptions` of the component is kept by its meta database (`GetMetaDataBase.DDLTextOptions`); the protected field `FDDLTextOptions` is removed. Descendants use the property.
- `GetObjectDDL` of a package or a PSQL function returns an empty string on a server before Firebird 3; it raised "Table unknown". The DDL text also changes in details (terminators, quoting, single spaces): tools that compare scripts made by different versions show these differences.
- `LoadMetaData`, `Clear` and a new `Database` free the meta objects of the previous load; they were leaked before. Don't keep a `TMetaTable`, `TMetaProcedure` or other meta object across these calls: take it again from `Tables`, `Procedures` or `ObjectByName`.

#### Non-ASCII text in server errors

`Message`, `IBMessage` and `ErrorArgument` of a server error and `TFIBErrorHandler.ConstraintName` and `ExceptionName` are decoded in the charset of the connection, no longer in the system code page. Code that decoded them again (for example `UTF8ToString(RawByteString(E.Message))` on a UTF8 connection) must stop doing so.

#### Values out of range

Some values that were cut without an error now raise one; see the [changelog](../../CHANGELOG.md):
`AsInteger` and `AsShort` of `TFIBQuery` fields and parameters out of the range of the type, a
BLOB of more than 32767 bytes assigned to a parameter that is not a BLOB, a value out of the
range of a persistent float field of a `NUMERIC` stored as `INTEGER` or `SMALLINT`, a generator
value out of the range of an `INTEGER` key field, a service start parameter of 65536 bytes or
more. `lock_timeout` of `TRParams` is checked by Firebird 2.5 and later (1 to 32767). Use `AsInt64`,
`BIGINT` columns or a smaller value.

#### `Post` from `BeforePost`

A `Post` called again from the dataset's own `BeforePost` returns without doing anything; the
outer `Post` posts the record. Before, it recursed until the stack overflowed. `Edit` and `Post`
in `AfterPost` still post again.

#### Commit of `ApplyUpdates`

With `CachedUpdates` and `AutoCommit`, `ApplyUpdates` commits the update transaction once, after
the last row; it committed after each inserted or modified row. A row skipped by `OnUpdateError`
or `OnUpdateRecord` (`uaSkip`) stays in the cache, and the rows applied before and after it are
committed. When an error stops `ApplyUpdates`, the rows applied before it are committed before the
error is raised, as they were before, because the cache marks them as applied. The failing row
itself is rolled back to a savepoint when it ran more than one statement (update objects,
`OnUpdateRecord`, `poRefreshAfterDelete`), so none of its work is committed; this needs
*Firebird 2+* and an update transaction whose `MainDatabase` is the database of the dataset.
Without the savepoint such a row leaves the transaction uncommitted.

A `Post` or `Delete` with `CachedUpdates` and `AutoCommit` commits once. When it fails, the rows it
applied are rolled back to a savepoint (with the same conditions) and stay pending in the cache;
before, the rows applied before the error were committed.

The refresh after a post or a delete (`poRefreshAfterPost`, `poRefreshAfterDelete`) reads the row
in `UpdateTransaction` while it is active; it read it in `Transaction`. With a separate update
transaction that is not committed yet, the refresh now sees the posted row: an inserted row no
longer vanishes, and a deleted row no longer stays.

#### Generated statements

- `AutoUpdateOptions.UpdateOnlyModifiedFields` keeps the assigned value. Assigned before
  `AutoReWriteSqls` and `CanChangeSQLs`, it was reset to `False`; now the dataset generates the
  `INSERT` and `UPDATE` for each post once the other two are `True`. Remove the line from the
  form if you relied on the old order. `UpdateOnlyModifiedFieldsInEffect` returns whether it
  applies.
- Under `UpdateOnlyModifiedFields`, a new row without any field set was not written (`No Action`)
  although the dataset showed it as posted; it is now inserted with `DEFAULT VALUES`.
- `UseRowsClause` adds `ROWS 1` only to the generated `UPDATE`; the `INSERT` and `UPDATE OR
  INSERT` no longer get it.
- Without `poRefreshAfterPost`, `OldValue` after a post returns the posted values, as with
  `poRefreshAfterPost`; it returned the values before the edit. In `AfterPost`, `OldValue`
  now equals `Value`: code that compares them there (an audit log) must read the old values in
  `BeforePost`.
- A table alias without quotes in `AutoUpdateOptions.UpdateTableName` means the uppercase name,
  as in SQL: `'T a'` matches `from T a`, no longer `from T "a"`. Write the alias as in
  `SelectSQL` (`'T "a"'`).

#### NULL in `Filter` comparisons

A row whose operand of `=`, `<>`, `>`, `>=`, `<`, `<=`, `LIKE` or `IN` is NULL no longer matches
the `Filter`, as in SQL and the VCL `TClientDataSet`. Before, `STATUS <> 'closed'`,
`GETDATE() > D` and `D < 5` also matched a NULL field, `A = B` matched when both were NULL,
`S like '%'` matched a NULL `S`, and a NULL Boolean field matched the filter `B`. Add
`or (STATUS is null)` to keep such rows. `not` still negates the result, so `not (D = 5)` and
`not B` match a NULL `D` or `B`.

#### Numbers compared with text

`CompareVariants` and `CompareVariantsEQ` (`VariantRtn`), used by the local sort and `Locate`,
compare a number or a date with a string variant by its text: a text that is a number is
compared as a number, a date text with a date as a date (`'01.01.2024'`), and any other text
(`'abc'`, or `'1.5'` where the decimal separator is `,`) as text, without an error. Before, a
number and a `string` variant were taken for equal, and an `AnsiString` or `WideString` text that
is not a number raised `EConvertError`.

#### Integer parameter values

`AsInteger`, `AsInt64` and `AsShort` assigned before `Prepare` are converted to the parameter type
at `Prepare`, as `AsDouble` and `AsVariant` already were: a `BOOLEAN` parameter gets `True` for a
value other than zero, a `DATE` or `TIMESTAMP` parameter the `TDateTime` with that day number.
Before, the value was sent as an integer and the server raised a conversion error.

#### `StopFetching`

`StopFetching` set in `TFIBQuery.OnSQLFetch` or `TFIBDataSet.BeforeFetchRecord` now ends the fetch for good: `Eof` is set as at the end of the data, and with `qoAutoCommit` or `qoFreeHandleAfterExecute` the query is closed. Before, `Next` returned `nil` but `Eof` stayed `False`, so a later fetch could go on, and code used it as a pause. A `TFIBDataSet` sets `AllFetched` and keeps the cached rows as the whole result until it is reopened. To pause a `TFIBQuery`, stop calling `Next`; to read the rest of a dataset later, don't set `StopFetching`.

#### Scripter

- `TFIBScripter` raises "Parse script error. Invalid statement" for a statement it can't parse
  (starting with `-`, `/` or a bare `{`); it sent it to the server. The error is not passed to
  `OnExecuteError`. A `BeforeStatementExecute` handler can still skip the statement.
- `CONNECT` on an assigned `Database` keeps its `DBParams` and sets only the clauses of the
  statement: a missing `USER`, `PASSWORD` or `ROLE` keeps the value of the database. The charset
  of `CONNECT` is no longer replaced by an earlier `SET NAMES`.
- `ExecuteFromFile` detects a UTF-8 or UTF-16 BOM; a file without one is still read in the system
  code page. Pass the encoding of such files to the new `ExecuteFromFile(FileName, Encoding)`.

#### Batch and Execute errors

`TFIBDatabase.Execute` raises the error of the statement; it returned `False`. Code that runs a statement which may fail harmlessly (a `DROP` of an object that may not exist) needs a `try`/`except` around `Execute`; `if not Execute(...)` checks never see `False` any more. `TFIBQuery.BatchOutput` and `BatchOutputRawFile` raise the errors of the query and of the stream, the cursor is still closed; `False` from `BatchOutput` and `BatchInput` only means that there was nothing to do (another statement type, or the stream is not ready). A charset mismatch in `BatchInput` raises `EFIBClientError` with `SQLCode = Ord(feBatchCharsetMismatch)` instead of `Exception`.

`ExecWPS(ParamSource, True)` calls `OnBatching` with `boInput` for each row, and runs the row again when `OnBatchError` answers `beRetry` (it went on with the next row). A handler that answers `beRetry` for an error that stays must change its answer, or the row is run forever.

#### BLOB text read errors

`AsString`, `AsAnsiString` and `AsWideString` of a BLOB column raise the error when the content can't be read (for example when the transaction is not active); they returned `(BLOB)`. A BLOB parameter without a value returns an empty string instead of `(BLOB)`.

`TFIBQuery.BlobToStrings` and `BlobAsString` read the text as `AsString` does, in the charset of the column, and raise the read error; `BlobToStrings` returned `False` and `BlobAsString` an empty string. `BlobAsString` no longer ends with a line break.

#### Restore page size

`TFIBRestoreService.PageSize` is `0` by default (it was `4096`): the database is restored with
the page size of the backup. A form that kept the old default stores no value and now loads `0`;
a value set in the form stays. Set `PageSize := 4096` for the old result.

#### Characters outside the system code page

Without `utf8_filename`, a `DBParams` value or a `DBName` with a character outside the system code
page raises `feCantTransliterateParam` on `Open`; it was sent with `?` in its place, so a
non-ASCII password failed as a wrong password. The services raise the same error for their
`Params` and text start parameters. The message names the parameter, not the value. Add
`utf8_filename` to `DBParams` to send the values in UTF-8. `CreateDatabase` raises the same error
also with `utf8_filename`: the Firebird client reads the `CREATE DATABASE` text in the system
code page.

#### Table alias of a field

`TableAliasForField` of `TFIBQuery` and `TFIBDataSet` and `TableAliasForFieldByName` return the
alias as the server stores it, unquoted: `MyAlias` for `"MyAlias"`, `т` for `"т"`. Code that puts
the result into SQL text must format it with `FormatIdentifier(3, Alias)`. `Field.Origin` with
`FieldOriginRule = forTableAliasAndFieldName` changes the same way (`т.NAME` instead of
`"т".NAME`).

#### QueryValue in a passed transaction

An error in `TFIBDatabase.QueryValue` or `QueryValues` no longer rolls back the transaction passed
in `aTransaction`; it stays active with the work done in it before the call, and the caller
decides whether to commit or roll it back. Code that called `QueryValue` in its own transaction
and relied on the rollback after an error must call `Rollback` itself. Without `aTransaction`
nothing changes: the internal transaction is committed, or rolled back on an error.

`TFIBDatabase.Gen_Id` runs in `aTransaction` when one is passed; it ran in `FirstActiveTransaction`
when the database had an active transaction. Without `aTransaction` it still takes
`FirstActiveTransaction`, else the internal transaction.

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
| `qDefaultFields` | `DefaultFields` | Rename. On Delphi XE6 and later `TDataSet.DefaultFields` is deprecated: use `Fields.LifeCycles`. |
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
