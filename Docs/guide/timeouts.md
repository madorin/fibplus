# Timeouts

FibPlus has two kinds of timeouts that are easy to confuse:

| Kind | Where it runs | Properties |
|------|---------------|------------|
| **Server-side** (*Firebird 4+*) | The server cancels a statement or closes an attachment | `Session.StatementTimeout`, `Session.IdleTimeout`, `TFIBQuery.StatementTimeout`, `TpFIBDataSet.StatementTimeout` |
| **Client-side** | A timer in your application closes a connection or ends a transaction | `TFIBDatabase.Timeout`, `TFIBTransaction.Timeout` |

This article covers the server-side timeouts first, then the client-side ones.

## Requirements

| Feature | Needs |
|---------|-------|
| `Session.StatementTimeout`, `Session.IdleTimeout` | *Firebird 4+* |
| `TFIBQuery.StatementTimeout`, `TpFIBDataSet.StatementTimeout` | *Firebird 4+* **and** a `fbclient` 4+ library (`fb_dsql_set_timeout`) |

The samples use `Database` (a `TpFIBDatabase`) and `Query` and `Report` (two `TpFIBQuery` components), with `Database` and a transaction assigned.

Check what is available at run time:

```delphi
if Database.Capabilities.SessionTimeouts then
  Database.Session.StatementTimeout := 30000;
if Database.Capabilities.StatementTimeout then
  Query.StatementTimeout := 5000;
```

A non-zero value the server or the client library cannot apply raises `EFIBClientError` (`feFeatureNotSupported`). A value of `0` never raises.

## Statement timeout

A statement that runs longer than its timeout is cancelled by the server.

### For every statement of a connection

`TFIBDatabase.Session` ([TFIBSession](../reference/TFIBSession.md)) holds the session values. `Session.StatementTimeout` is in **milliseconds**. It is sent to the server as `SET STATEMENT TIMEOUT` right after connecting and every time you change it on a live connection.

```delphi
Database.Session.StatementTimeout := 30000; // 30 s for all statements
Database.Connected := True;
```

### For one query or dataset

`TFIBQuery.StatementTimeout` and `TpFIBDataSet.StatementTimeout` (milliseconds) replace the session value for that statement. The value is applied after the statement is prepared.

| Value | Meaning |
|-------|---------|
| `0` (default) | The session value applies |
| `1..` | This many milliseconds, instead of the session value |
| `FIBNoStatementTimeout` | No timeout for this statement, even if the session has one |

```delphi
Query.StatementTimeout := 2000;                      // this query: 2 s
Report.StatementTimeout := FIBNoStatementTimeout;    // this one: never times out
```

`FIBNoStatementTimeout` ignores the session value only. A limit set in `firebird.conf` still applies.

On a `TpFIBDataSet` the value is also passed to its internal queries (refresh and similar). Statements that come from the shared query cache keep the session value, so a dataset's timeout does not leak to other users of the cache.

Only DML is timed: `SELECT`, `INSERT`, `UPDATE`, `DELETE`, and `EXECUTE PROCEDURE`. DDL statements ignore the setting.

### SELECT statements run until the last row

For a `SELECT`, the timer runs until the **last row is fetched** (EOF), not until the first row arrives. A dataset that a user browses in a grid can therefore fail with a timeout on a later scroll, long after `Open` returned.

In interactive applications:

- set timeouts per query, not on the session; or
- opt browsing datasets out with `FIBNoStatementTimeout`.

## Idle timeout

`Session.IdleTimeout` is in **seconds**. The server closes the attachment after it has been idle for that long. It is sent as `SET SESSION IDLE TIMEOUT`.

```delphi
Database.Session.IdleTimeout := 600; // close after 10 minutes without activity
```

- The value is **not** sent at design time, so the IDE connection is not closed under you.
- When the server closes the attachment, your application sees a lost connection. `TpFIBDatabase` does not detect it by itself; see [Lost connection](connections.md#lost-connection) for the handler it needs.
- This is separate from the client-side [`TFIBDatabase.Timeout`](#client-side-timeouts).

## Reading and re-applying session values

`Session.ActualStatementTimeout` and `Session.ActualIdleTimeout` return the values the server holds for the attachment, which can differ from the property values. They do not include limits from `firebird.conf`.

Call `Session.Apply` after something resets the session, for example `ALTER SESSION RESET`, or after a `SET` statement you sent yourself. It sends both property values again, zeros included, so the server ends up exactly at the property values. Values stored while disconnected are kept and sent on connect. See [TFIBSession](../reference/TFIBSession.md).

## Handling a timeout

A cancelled statement raises `EFIBError`. Use these members to tell it apart from other errors:

```delphi
try
  Query.ExecQuery;
except
  on E: EFIBError do
    if E.IsStatementTimeout then
      ShowMessage('The query took too long.')
    else
      raise;
end;
```

| Member | Description |
|--------|-------------|
| `EFIBError.IsStatementTimeout` | `True` if the server cancelled the statement because of its timeout |
| `EFIBError.HasErrorCode(Code)` | `True` if the status vector contains that code |
| `EFIBError.ErrorCodes` | Every code of the status vector; set for server errors only |

If you use `TpFibErrorHandler`, `keStatementTimeout` and `keCancelled` identify these cases in `TKindIBError`.

## Firebird 3 and older

Timeouts need *Firebird 4+*. A non-zero timeout stored in a DFM makes connecting fail on older servers: `Database.Open` raises, and `Database.Open(False)` returns with `Connected = False`. Set timeouts in code behind a `Capabilities` check if the same application runs against several Firebird versions.

## Client-side timeouts

These timers run in your application and need no particular server version.

| Property | Event | Effect |
|----------|-------|--------|
| `TFIBDatabase.Timeout` (ms) | `OnTimeout` | Closes the connection after that long without activity |
| `TFIBTransaction.Timeout` (ms) | `OnTimeout` | Applies `TimeoutAction` after one to two intervals without server calls in the transaction |
| `TFIBTransaction.TimeoutAction` | | `TARollback` (default) or `TACommit`, and the retaining variants |

A client-side timeout acts on the application's connection or transaction. It does **not** cancel a statement already running on the server; use a statement timeout for that.

## See also

- [TFIBQuery reference](../reference/TFIBQuery.md)
- [Transactions](transactions.md)
- [Firebird versions](firebird-versions.md)
