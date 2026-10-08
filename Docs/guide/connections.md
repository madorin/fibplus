# Connections

A connection to a Firebird or InterBase database is a `TFIBDatabase` (or its descendant `TpFIBDatabase`). This article shows how to set the connection parameters and connect, how the login dialog works, what happens when the connection closes or is lost, how character sets and the client library are chosen, and how to check what the server supports.

## Requirements

- A Firebird or InterBase client library on the machine of the application. By default FibPlus loads `fbclient.dll` (`libfbclient.dylib` on macOS); see [Client library](#client-library).
- Features that depend on the server or client version are listed in [Capabilities](#capabilities) and in [Firebird versions](firebird-versions.md).

The examples use the components `Database` (`TFIBDatabase` or `TpFIBDatabase`) and `Transaction` (`TFIBTransaction`).

## Connect in code

Set the database name, the user, the password, and the character set; link a default transaction; then connect.

```delphi
Database.DBName := 'localhost:C:\Data\Sales.fdb';
Database.ConnectParams.UserName := 'SYSDBA';
Database.ConnectParams.Password := 'masterkey';
Database.ConnectParams.CharSet := 'UTF8';
Database.SQLDialect := 3;
Database.DefaultTransaction := Transaction;
Database.Open;
```

`Connected := True` does the same as `Open`. `Close` or `Connected := False` disconnects.

`Open` raises when the attach fails. `Open(False)` returns with `Connected = False` instead, also when the setup of the session after the attach fails. Other errors still raise: a cancelled login dialog, an empty `DBName`, a client library that cannot be loaded, and an already connected database.

```delphi
Database.Open(False);
if not Database.Connected then
  ShowMessage('The database is not available.');
```

`Open` on a `TFIBDatabase` that is already connected raises. `TpFIBDatabase.Open` returns without an error in that case.

The attach, including the login dialog, runs inside a global lock, so connects started in other threads wait for it.

`SQLDialect` is `3` unless you set it. When the database has a lower dialect than `SQLDialect`, `SQLDialect` is lowered to the database dialect after the attach. While connected, a dialect above the database dialect raises.

## Connection parameters

The connection parameters are lines of `DBParams` (`Name=Value`). `ConnectParams` is a typed view on the common ones, and both stay in step. The tables are in the reference: [ConnectParams](../reference/TFIBDatabase.md#connectparams) and [DBParams](../reference/TFIBDatabase.md#dbparams).

| Task | Use |
|------|-----|
| User, password, SQL role | `ConnectParams.UserName`, `Password`, `RoleName` |
| Character set | `ConnectParams.CharSet` |
| Any other DPB parameter | A line in `DBParams`, or `DBParamByDPB[Idx]` with an `isc_dpb_*` constant |
| Client configuration value, *Firebird 3+* | `ConfigParam[Name]`, which writes a `config=Name=Value` line |
| Wire compression, *Firebird 3+* | `ConnectParams.WireCompression`, which writes `config=WireCompression=true` |
| InterBase instead of Firebird | `ConnectParams.IsFirebird := False`, so that Firebird-only parameters are left out |

```delphi
Database.DBParams.Add('sql_role_name=SALES');
Database.ConfigParam['WireCompression'] := 'true';
```

At run time, changing `DBName` or `DBParams` while connected raises. Changing `LibraryName` while connected raises at design time too. The `config` line is left out of the connection when `IsFirebird` is `False`.

### Encrypted databases

For a database that uses a *Firebird 3+* crypt plugin, give the key before connecting with `CryptKey`, or answer the request of the server in `OnCryptKeyRequest`. `CryptKey` is not published, so it is never stored in the form. The event starts with `Key` set to `CryptKey` and runs in the connecting thread.

```delphi
Database.CryptKey := AnsiString('MySecretKey');
Database.Open;
```

## The login dialog

With `UseLoginPrompt` set to `True`, `Open` asks the user for the user name, the password, and the role before it attaches. The dialog starts with the current user name and role from `DBParams`; the password field is empty. After OK, the three values are written to `DBParams` and used for the attach. If the user cancels, `Open` raises an error.

The dialog is not part of `TFIBDatabase`; a dialog unit registers it when the program starts. Add the unit to the `uses` clause of your project:

| Framework | Unit |
|-----------|------|
| VCL | `FIBDBLoginDlg` |
| FireMonkey | `FIB_FMX_DBLoginDlg` (package `FIBPlusFMX`, *Delphi 13*) |

Without such a unit, a connect with `UseLoginPrompt` raises an error that asks you to add `FIBDBLoginDlg` to the `uses` clause.

To show your own dialog, assign a function of type `TpFIBLoginDialog` (unit `fib`) to the global variable `pFIBLoginDialog`. It receives the database name and the current user name, password, and role, and returns `True` to continue.

```delphi
function MyLoginDialog(const ADatabaseName: string;
  var AUserName, APassword, ARoleName: string): Boolean;
begin
  Result := ShowMyLogin(ADatabaseName, AUserName, APassword);
end;

initialization
  pFIBLoginDialog := MyLoginDialog;
```

`ShowMyLogin` stands for your own dialog code. The two dialog units set `pFIBLoginDialog` in their `initialization` section and reset it to `nil` in `finalization`. The `IB_Services` components use the same hook (see [IB_Services components](../reference/TpFIBServices.md)).

### Setting the password in code

`TpFIBDatabase` has the event `BeforeConnect` that runs before every connect, including a restore after a lost connection. `LoginParams` is `DBParams`, and `DoConnect` set to `False` cancels the connect.

```delphi
procedure TMainForm.DatabaseBeforeConnect(Database: TFIBDatabase;
  LoginParams: TStrings; var DoConnect: Boolean);
begin
  LoginParams.Values['password'] := AskForPassword;
end;
```

`AskForPassword` stands for your own code that returns the password.

## Disconnect and check the connection

| Task | Use |
|------|-----|
| Disconnect and end the transactions as their `TimeoutAction` says | `Close` |
| Disconnect and ignore errors | `ForceClose` |
| Find out whether the server still answers | `TestConnected` closes the connection with `ForceClose` and returns `False` if it does not; `PingAttachment` returns `0` when the server answers and raises nothing |

`BeforeDisconnect` and `AfterDisconnect` run around a disconnect; `AddEvent` with `detOnConnect` or `detBeforeDisconnect` adds more handlers. The client-side `Timeout` closes an unused connection; see [Timeouts](timeouts.md#client-side-timeouts). The reference describes every member: [TFIBDatabase](../reference/TFIBDatabase.md#connecting).

## Reconnect

### AutoReconnect

With `AutoReconnect` set to `True`, a component that needs the connection connects again when it is closed. This covers queries, datasets, transactions that start, and several methods of `TFIBDatabase` that call the server. Without `AutoReconnect`, a closed database raises an error at run time in these places.

A transaction whose databases all have `AutoReconnect` also starts itself when a query or dataset needs it and it is not active.

When a reconnect is needed and `ConnectParams.Password` is empty, there is one attempt, with the login dialog. Otherwise the first attempt does not show the dialog, and if it fails a second attempt does. Errors are ignored in both cases (see [Pitfalls](#errors-and-pitfalls)).

`AutoReconnect` acts on a connection that is closed. A connection that the server dropped still looks open until it is closed. To find out, call `TestConnected`, which closes a dead connection; the next use reconnects.

```delphi
Database.AutoReconnect := True;
// later
if not Database.TestConnected then
  Database.Open(False);
```

### Lost connection

`TpFIBDatabase` can handle a dropped connection: it closes the connection without calling the server, calls `OnLostConnect`, and retries with a timer. It does not detect the loss by itself. A `TpFibErrorHandler` component with `oeLostConnect` in `Options` (the default) must exist in the application, or you call `ExTestConnected`; both raise the event. In the handler you choose the action:

```delphi
procedure TMainForm.DatabaseLostConnect(Database: TFIBDatabase; E: EFIBError;
  var Actions: TOnLostConnectActions; var DoRaise: Boolean);
begin
  Actions := laWaitRestore;
  DoRaise := False;
end;
```

`WaitForRestoreConnect` is the retry interval in milliseconds, `30000` by default; `0` turns the retries off. The events, the actions, and the rules for the retries are in the reference: [TpFIBDatabase, Lost connection](../reference/TpFIBDatabase.md#lost-connection). A server idle timeout arrives as a lost connection and is handled in the same way; see [Timeouts](timeouts.md#idle-timeout).

## Connect at design time

At design time you set the parameters in the Object Inspector and can set `Connected` to `True` to work with live data.

`DesignDBOptions` has three options, described in [Types](../reference/TFIBDatabase.md#types). `ddoStoreConnected` (the default) stores `Connected = True` in the form, so the form connects when it loads. `ddoNotSavePassword` leaves the password out of `DBParams` when the form is saved. `ddoIsDefaultDatabase` makes this the database for new components.

`StoreConnected` is the run-time property behind the first option: it is `True` when the database is connected and `ddoStoreConnected` is set, and it decides whether `Connected` is saved in the form. The `Active` state of transactions and datasets is saved only when the database stores its connection, so with `ddoStoreConnected` off they do not open on their own when the form loads.

When the form loads with a stored `Connected = True`, the database connects at the end of loading, and starts a default transaction that was stored as active. A failed connect raises an error at run time. At design time it shows the error and the form still opens.

If you use `ddoNotSavePassword`, set the password in code or with a login prompt before connecting; turn `ddoStoreConnected` off as well, so that the form does not try to connect without it.

## Character sets

The connection character set tells the server in which encoding it exchanges text with your application. Set it with `ConnectParams.CharSet`; the name is converted to upper case. If it is empty, no `lc_ctype` is sent.

```delphi
Database.ConnectParams.CharSet := 'UTF8';
```

Use a character set that can hold all the characters of your users. `UTF8` can hold all of them. The server converts text between the column character set and the connection character set, except for `NONE` and `OCTETS` columns. A character that the target code page cannot hold raises `EFIBClientError` with the message "Cannot transliterate character between character sets", for example a character outside a `WIN1252` connection, instead of being replaced by `?`.

FibPlus converts text between Delphi strings and bytes through the code page of the character set. `Database.Capabilities` reports what it uses for the current connection: `AttachmentCharSetID`, `CodePage`, `MetadataCodePage`, and `TextCodePage` and `BlobCodePage` for a column character set ID. The members are described in [Capabilities](../reference/TFIBDatabase.md#capabilities). A dataset gives the same for its fields: `StringFieldCharSetID`, `StringFieldCodePage`, `BlobFieldCodePage` (see [TFIBDataSet](../reference/TFIBDataSet.md)). The unit `FIBCharSets` converts between IDs, names, and code pages:

```delphi
uses
  FIBCharSets;

ShowMessage(FirebirdCharSetName(Database.Capabilities.AttachmentCharSetID));
ShowMessage(IntToStr(FirebirdCharSetCodePage(Database.Capabilities.AttachmentCharSetID)));
```

`FirebirdCharSetName` returns an empty string for an unknown ID. `FirebirdCharSetCodePage` returns `FIBCodePageSystem` (`0`, the system code page) for `NONE`, `OCTETS`, and unknown IDs.

### Connection with `NONE`

On a `NONE` connection (`ConnectParams.CharSet` is `NONE`), the server does not convert text. FibPlus then decodes each text column with the character set declared for the column, so text of a `WIN1251` column shows as stored. Columns with `NONE` or `OCTETS` use the system code page. Text that was stored from another code page than the column declares appears as stored; to read it right, reinterpret the bytes in SQL:

```sql
cast(cast(C as varchar(20) character set OCTETS) as varchar(20) character set WIN1250)
```

Here `C` is the column and `20` its length.

On a `NONE` connection to *Firebird 2.1+* with ODS 11.1 or later, DDL and the names of metadata objects go in UTF-8; `MetadataCodePage` reports it.

### Limits

- Before Delphi 2009, FibPlus converts only UTF-8; other code pages are passed through.
- The code page must exist on the system; if it does not, an error "Code page %d is not available on this system" is raised.
- When the server does not report the connection character set (always on InterBase), `CodePage` comes from `ConnectParams.CharSet`: UTF-8 for `UTF8` and `UNICODE_FSS`, else the system code page.

## Client library

`LibraryName` is the file name or the path of the client library. The default is `fbclient.dll` (`libfbclient.dylib` on macOS). To use another library, set the property before connecting:

```delphi
Database.LibraryName := 'C:\Firebird\fbclient.dll';
Database.Open;
```

- The library is loaded on the first connect (or when you call `ClientVersion`) and is shared by all databases with the same `LibraryName`.
- You can change `LibraryName` only while the database is closed.
- `LibraryName64` is the library for 64-bit Windows. In a 64-bit Windows program it is used instead of `LibraryName` when it is not empty. *Delphi XE2+*
- All databases that one transaction spans must use the same `LibraryName`; otherwise adding a database to the transaction raises an error.
- On Windows, when `LibraryName` is `fbclient.dll` without a path and it cannot be loaded, `gds32.dll` is loaded instead. A name with a path or another name is not replaced.
- If the library cannot be loaded, the connect raises an operating system error.

Check what was loaded:

```delphi
Caption := Database.LibraryFilePath + ' ' + Database.ClientVersion;
```

`ClientLibrary.Version` gives the product and version as a `TFIBVersion` record (`Product`, `Major`, `Minor`, `Release`, `Build`). Statement timeouts need a client library that exports `fb_dsql_set_timeout` (`fbclient` 4+); see `Capabilities.StatementTimeout`.

## Capabilities

`Database.Capabilities` tells what the current server and client library can do. It is filled when the connection opens and cleared when it closes, so read it after `Open`.

The flags that matter at connect time are `SessionTimeouts` (*Firebird 4+*: session timeouts work), `StatementTimeout` (also needs a client library with per-statement timeouts), and `MaxIdentifierLength`. The members are described in [Capabilities](../reference/TFIBDatabase.md#capabilities).

```delphi
if Database.Capabilities.SessionTimeouts then
  Database.Session.StatementTimeout := 30000;
```

A non-zero timeout stored in a form makes the connect fail on a server without the feature; see [Timeouts](timeouts.md#firebird-3-and-older). The version matrix is in [Firebird versions](firebird-versions.md).

## Errors and pitfalls

- **Reconnect errors are hidden.** `AutoReconnect` ignores the errors of its connect attempts. If they fail, `Connected` stays `False`; `StartTransaction` then returns with the transaction inactive and raises nothing. After such a call check `Database.Connected` or `Transaction.Active`.
- **Changing parameters while connected.** `DBName` and `DBParams` raise at run time while the database is connected, and `LibraryName` raises at any time. Call `Close` first.
- **The password in the form.** `DBParams` is stored in the form with the password. Use `ddoNotSavePassword`, or set the password in code.
- **A stored `Connected = True`.** The form connects while it loads. If the server is not reachable, the program raises an error at start-up. Turn off `ddoStoreConnected` for forms that must start without the server.
- **Login prompt without a dialog unit.** `UseLoginPrompt` needs `FIBDBLoginDlg`, `FIB_FMX_DBLoginDlg`, or your own `pFIBLoginDialog`.
- **Opening twice.** `Open` on a connected `TFIBDatabase` raises; check `Connected` first.
- **Restore timer in old forms.** Forms saved by versions before 7.9.1 without a value set in the Object Inspector store `WaitForRestoreConnect = 0`, so `laWaitRestore` does nothing more than `laCloseConnect`. Remove the line or set the interval.
- **Lost connection without an error handler.** `OnLostConnect` does not fire without a `TpFibErrorHandler` or a call to `ExTestConnected`.
- **Idle timeouts.** A server idle timeout and the client-side `Timeout` both close the connection; they are different settings (see [Timeouts](timeouts.md)).

## See also

- [TFIBDatabase reference](../reference/TFIBDatabase.md)
- [TpFIBDatabase reference](../reference/TpFIBDatabase.md)
- [TFIBSession reference](../reference/TFIBSession.md)
- [Transactions](transactions.md)
- [Timeouts](timeouts.md)
- [Firebird versions](firebird-versions.md)
