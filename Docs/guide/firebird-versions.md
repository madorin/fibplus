# Firebird versions

FibPlus connects to Firebird and InterBase servers of several generations. Some features need a newer server, a newer client library, or both. This article is organized like a changelog: one section per Firebird version, newest first, with the features that version introduced and how FibPlus supports them.

| Version | Features in FibPlus |
|---------|---------------------|
| [Firebird 4.0](#firebird-40) | Session timeouts, statement timeout, long identifiers, read consistency, `INT128`, `DECFLOAT`, time zones |
| [Firebird 3.0](#firebird-30) | `BOOLEAN`, encrypted databases, `config=` lines in `DBParams` |
| [Firebird 2.1](#firebird-21) | Server-side conversion of text BLOBs, metadata in UTF-8 |
| [Firebird 2.0](#firebird-20) | Default values of stored procedure input parameters |
| [InterBase](#interbase) | What is not available |

## Server and client library

Two versions matter:

- The **server** version decides which SQL features and data types exist. `TFIBDatabase.ServerMajorVersion` and `ServerMinorVersion` report it after connecting.
- The **client library** (`fbclient`, `gds32`) decides which API calls and data type conversions are available. `TFIBDatabase.ClientLibrary.Version` gives the product and version as a `TFIBVersion` record (`Product`, `Major`, `Minor`, `Release`, `Build`).

A feature that needs a newer client library does not work with an older one, even when the server supports it. Each feature below states what it needs from the server and from the client library.

In the samples, `Database` is a `TFIBDatabase`, `Query` is a `TFIBQuery`, and `Query.Database` is `Database`.

## Checking what is available

`TFIBDatabase.Capabilities` is filled when the connection opens. Read it instead of comparing version numbers yourself. The members are described in [TFIBDatabase](../reference/TFIBDatabase.md#capabilities).

```delphi
if Database.Capabilities.SessionTimeouts then
  Database.Session.IdleTimeout := 600;
if Database.Capabilities.MaxIdentifierLength > 31 then
  Writeln('Long names are available');
```

For anything `Capabilities` does not cover, read the versions directly:

```delphi
if Database.IsFirebirdConnect and (Database.ServerMajorVersion >= 4) then
  Writeln('Firebird 4 or later');
Writeln(Database.ClientLibrary.Version.Major);
```

`Capabilities` is empty before the first connection: `MaxIdentifierLength` is `0` and the boolean members are `False`.

## Firebird 4.0

### Session timeouts

- **Server:** *Firebird 4+*. **Client library:** any.
- **In FibPlus:** `Session.StatementTimeout` and `Session.IdleTimeout` of `TFIBDatabase` are applied on connect. Check `Capabilities.SessionTimeouts`.
- **Guide:** [Timeouts](timeouts.md), [TFIBSession](../reference/TFIBSession.md).

### Statement timeout of a query or dataset

- **Server:** *Firebird 4+*. **Client library:** `fbclient` with `fb_dsql_set_timeout` (*Firebird 4+*).
- **In FibPlus:** `StatementTimeout` of `TFIBQuery` and the datasets is applied after prepare. Check `Capabilities.StatementTimeout`; it is `False` on a *Firebird 4+* server when the client library is older, while `Capabilities.SessionTimeouts` can still be `True`.
- **Guide:** [Timeouts](timeouts.md); what happens on older servers is in [Timeouts](timeouts.md#firebird-3-and-older).

### Long identifiers

*Firebird 4* raises the limit for names of tables, columns, and parameters from 31 to 63 characters.

- **Server:** *Firebird 4+*. **Client library:** works with any; a client that is not a *Firebird 4+* one makes FibPlus read the names with an extra request.
- **In FibPlus:** long names are supported for columns, parameters, relation aliases, array columns, the field repository, and the editors. `Capabilities.MaxIdentifierLength` is `63` on a *Firebird 4+* server and `31` on others.

Points that matter when you move to a *Firebird 4+* server:

- Names longer than 31 bytes come in full. Before, they were cut or replaced with `F_n`. Rename these to the full column name, or the existing items no longer match the columns:
  - persistent fields of datasets (`FieldName`);
  - `FIB$FIELDS_INFO` rows.
- A client library before *Firebird 4* returns names longer than 31 bytes empty, and a newer one cuts them. FibPlus reads the full names with an additional describe request: with a client before *Firebird 4* on a *Firebird 4+* server for every statement that has columns or parameters, and with a newer client only when a name was cut. Preparing a query therefore costs one more round trip with a *Firebird 3 or older* client.

See also [Upgrading](upgrading.md).

### Read consistency

- **Server:** *Firebird 4+*. **Client library:** any.
- **In FibPlus:** `TPBMode` `tpbReadConsistency` of `TpFIBTransaction`, or `read_consistency` in `TRParams`. Check `Capabilities.ReadConsistency`; on an older server `tpbReadConsistency` raises `EFIBClientError` at `StartTransaction`.
- With the default server setting `ReadConsistency = 1`, every read committed transaction already runs in this mode; `rec_version` and `no_rec_version` are ignored.
- **Reference:** [Transaction mode](../reference/TpFIBTransaction.md#transaction-mode), [Transaction parameters](../reference/TFIBTransaction.md#transaction-parameters).

### New data types

- **Server:** *Firebird 4+*. **Client library:** *Firebird 4+*.
- **In FibPlus:** supported in queries, parameters, and datasets.

| SQL type | Notes |
|----------|-------|
| `INT128`, `NUMERIC`/`DECIMAL` with precision 19 to 38 | In dialect 3, a `TBcd` value that does not fit `BIGINT` is sent as `INT128` |
| `DECFLOAT(16)`, `DECFLOAT(34)` | Values can be NaN or infinity; see `TFIBFMTBCDField` in [TFIBDataSet](../reference/TFIBDataSet.md) |
| `TIME WITH TIME ZONE`, `TIMESTAMP WITH TIME ZONE` | See [Time zones](#time-zones) |

With an older client library, set the `set_bind` DBParams entry so that the server converts the values to the legacy types:

```delphi
Database.DBParams.Add('set_bind=TIME ZONE TO LEGACY');
Database.Connected := True;
```

The DPB parameters `session_time_zone`, `set_bind`, `decfloat_round`, and `decfloat_traps` are sent to Firebird only; FibPlus ignores them on InterBase. Set them in `DBParams` before connecting, as any other parameter.

For queries and parameters in general, see [Queries and parameters](queries-and-parameters.md).

### Time zones

A time zone value has an ID. `TFIBXSQLVAR` reads it through `AsTimeZoneID`, `AsTimeZoneOffset`, `AsTimeZoneName`, and `AsUTCDateTime`, and writes it with `SetAsDateTimeTZ` (by ID or by name). `AsDateTime` of such a value returns the local time in the value's own zone.

```delphi
Query.SQL.Text := 'INSERT INTO EVENTS (STARTED) VALUES (:Started)';
Query.Params.ByName['Started'].SetAsDateTimeTZ(Now, 'Europe/Berlin');
Query.ExecQuery;
```

An ID refers either to an offset zone (`+02:00`) or to a region zone. `FIBTypes` has the helpers: `FBTimeZoneName`, `FBTimeZoneIDByName`, `FBIsOffsetZone`, `FBOffsetToZoneID`, `FBZoneIDToOffset`. The region names come from a table in `FIBTimeZones.inc`, generated from the Firebird source (version 2026d). The offset of a region zone is resolved by the server only; `FBKnownZoneOffset` returns `0` for it.

## Firebird 3.0

### Boolean

- **Server:** *Firebird 3+*. **Client library:** any.
- **In FibPlus:** `SQL_BOOLEAN` in `ibase.pas` is the `BOOLEAN` type. Read and write it with `AsBoolean`. On InterBase 7 and later the type has another code: use the constant `IB_SQL_BOOLEAN` in code that checks `SQLType`. `FB3_SQL_BOOLEAN` is a deprecated alias of `SQL_BOOLEAN`.

### Encrypted databases

- **Server:** *Firebird 3+* with a crypt plugin. **Client library:** `fbclient` that exports `fb_database_crypt_callback`.
- **In FibPlus:** `CryptKey` and `OnCryptKeyRequest` pass the key of an encrypted database to the crypt plugin.
- **Guide:** [Connections](connections.md), [TFIBDatabase](../reference/TFIBDatabase.md).

### `config=` lines in `DBParams`

- **Server:** any. **Client library:** *Firebird 3+* (the code marks `isc_dpb_config` as *Firebird 3+*).
- **In FibPlus:** lines `config=Name=Value` in `DBParams` and `ConfigParam[Name]` pass configuration values to the client. `ConnectParams.WireCompression` writes the `WireCompression` value this way.
- **Guide:** [Connections](connections.md).

## Firebird 2.1

### Character sets

The code page of text is chosen from the character set of the attachment and of the column. Which rules apply depends on the server:

- On *Firebird 2.1+* the server converts text BLOBs to the attachment character set. Older servers send the bytes of the column; FibPlus then uses UTF-8 for the Unicode character sets and the system code page for the rest.
- On *Firebird 2.1+* with ODS 11.1 or later, a `NONE` or Unicode attachment receives metadata names and DDL in UTF-8.
- `Capabilities.AttachmentCharSetID` is read once at connect. It is `-1` on InterBase and when not connected.

**Guide:** [Connections](connections.md).

## Firebird 2.0

### Default values of stored procedure parameters

FibPlus reads the default values of the input parameters of a stored procedure with a query that depends on the ODS version. ODS 11 (*Firebird 2.0*) stores the default with the parameter; ODS 12 (*Firebird 3.0*) adds packages, and the parameters of package procedures are not read. On older ODS versions the default comes from the domain of the parameter.

**Guide:** [TpFIBStoredProc](../reference/TpFIBStoredProc.md).

## InterBase

InterBase has none of the *Firebird 3+* and *Firebird 4+* features above. `Capabilities` reports `False`, `-1`, or `31` for them.

## Pitfalls

- A timeout stored in a DFM breaks the connection to older servers: see [Timeouts](timeouts.md#firebird-3-and-older).
- Persistent fields whose `FieldName` is a name cut to 31 bytes or an `F_n` name stop matching the columns after a move to a *Firebird 4+* server; see [Long identifiers](#long-identifiers).
- A *Firebird 4+* data type with a client library before *Firebird 4* needs `set_bind=TIME ZONE TO LEGACY` or a newer `fbclient`.

## See also

- [Timeouts](timeouts.md)
- [Connections](connections.md)
- [Upgrading](upgrading.md)
- [TFIBDatabase reference](../reference/TFIBDatabase.md)
- [TFIBSession reference](../reference/TFIBSession.md)
