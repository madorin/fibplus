# TFIBSession

Holds the session settings that FibPlus sends to the server for an attachment: the statement timeout and the idle timeout. It is the `Session` property of [TFIBDatabase](TFIBDatabase.md). `TFIBDatabase` creates it.

| | |
|---|---|
| Unit | `FIBDatabase` |
| Inherits from | `TPersistent` |

`Database` is a `TFIBDatabase`.

```delphi
Database.Session.StatementTimeout := 30000;
Database.Session.IdleTimeout := 600;
Database.Connected := True;
```

Guides: [Timeouts](../guide/timeouts.md).

## Published properties

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `IdleTimeout` | `Cardinal` | `0` | Seconds after which the server closes an idle attachment (`SET SESSION IDLE TIMEOUT`), *Firebird 4+*. Not sent at design time. Kept while the database is closed and sent on connect; sent at once on a live connection. See [Capabilities](TFIBDatabase.md#capabilities). Not the same as the client-side `TFIBDatabase.Timeout`. |
| `StatementTimeout` | `Cardinal` | `0` | Milliseconds after which the server cancels a statement (`SET STATEMENT TIMEOUT`), *Firebird 4+*. Kept while the database is closed and sent on connect; sent at once on a live connection. `TFIBQuery.StatementTimeout` overrides it per statement. For a cursor the timer runs until the last row is fetched. |

## Run-time properties

| Name | Type | Description |
|------|------|-------------|
| `ActualIdleTimeout` | `Cardinal` | Idle timeout the server holds for the attachment, in seconds. Does not include the `firebird.conf` limit. `0` when not connected or without session timeouts. |
| `ActualStatementTimeout` | `Cardinal` | Statement timeout the server holds for the attachment, in milliseconds. Does not include the `firebird.conf` limit. `0` when not connected or without session timeouts. |
| `Database` | `TFIBDatabase` | The owning database. |

## Methods

| Name | Description |
|------|-------------|
| `Apply` | Send both property values to the server again, zeros included. Does nothing when the database is not connected or while the form is loading. Use it after `ALTER SESSION RESET` or after a `SET` statement sent by other means. |
| `Assign(Source)` | Copy `StatementTimeout` and `IdleTimeout` from another `TFIBSession`. |

## See also

- [TFIBDatabase](TFIBDatabase.md)
- [TFIBQuery](TFIBQuery.md)
- [Timeouts](../guide/timeouts.md)
