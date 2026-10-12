# Reference

One page per class. Each page lists properties, methods and events with a short description.
For task-oriented explanations, see the [Guide](../guide/).

| Class | Unit | Description |
|-------|------|-------------|
| [TFIBDatabase](TFIBDatabase.md) | `FIBDatabase` | Connection to a Firebird or InterBase database, with aliases, lost-connection handling, and the schema cache. Includes `Capabilities`, `ConnectParams`, and `DBParams`. |
| [TFIBSession](TFIBSession.md) | `FIBDatabase` | Per-connection session settings, such as timeouts. |
| [TFIBTransaction](TFIBTransaction.md) | `FIBDatabase` | Transaction control: start, commit, rollback, parameters and transaction modes, timeout, events. |
| [TFIBQuery](TFIBQuery.md) | `FIBQuery` | Executes SQL statements and reads results without a dataset, with error handling for execution. |
| [TFIBDataSet](TFIBDataSet.md) | `FIBDataSet` | Dataset based on `TFIBQuery`, with caching, sorting, generated SQL, update objects, and cached updates. Includes `TFIBCustomDataSet` and the `TFIB...Field` classes. |
| [TFIBStoredProc](TFIBStoredProc.md) | `FIBStoredProc` | Calls stored procedures. |
| [TFIBUpdateObject](TFIBUpdateObject.md) | `FIBDataSet` | Custom statements for dataset insert, update, delete. |
| [TFIBScripter](TFIBScripter.md) | `FIBScripter` | Runs SQL scripts, including `SET` statements and terminators. |
| [TFIBSQLMonitor](TFIBSQLMonitor.md) | `FIBSQLMonitor` | Traces SQL activity of the library. |
| [TFIBClientDataSet](TFIBClientDataSet.md) | `FIBClientDataSet` | Client dataset and provider for multi-tier applications. |
| [FIBServices components](TFIBServices.md) | `FIBServices` | Service API components: backup, restore, validation, users, statistics. |

## Page template

A class page has these sections, in this order: summary, unit and ancestor, example, guide links, published properties, further sections as the class needs (options, types, run-time properties, methods, events, constants), see also.
Tables use `Name | Type | Default | Description`. Mark version limits inline, for example *Firebird 4+*.
Keep descriptions to one or two sentences; put scenarios and background in the Guide.
