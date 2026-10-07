# Reference

One page per class. Each page lists properties, methods and events with a short description.
For task-oriented explanations, see the [Guide](../guide/).

| Class | Unit | Description |
|-------|------|-------------|
| [TFIBDatabase](TFIBDatabase.md) | `FIBDatabase` | Connection to a Firebird or InterBase database. Includes `Capabilities`, `ConnectParams`, and `DBParams`. |
| [TFIBSession](TFIBSession.md) | `FIBDatabase` | Per-connection session settings, such as timeouts. |
| [TFIBTransaction](TFIBTransaction.md) | `FIBDatabase` | Transaction control: start, commit, rollback, parameters, timeout. |
| [TFIBQuery](TFIBQuery.md) | `FIBQuery` | Executes SQL statements and reads results without a dataset. |
| [TFIBDataSet](TFIBDataSet.md) | `FIBDataSet` | Dataset based on `TFIBQuery`, with caching and sorting. Includes `TFIBCustomDataSet` and the `TFIB...Field` classes. |
| [TpFIBDatabase](TpFIBDatabase.md) | `pFIBDatabase` | Database component with aliases, lost-connection handling, and the schema cache. |
| [TpFIBTransaction](TpFIBTransaction.md) | `pFIBDatabase` | Transaction component with transaction modes and events. |
| [TpFIBQuery](TpFIBQuery.md) | `pFIBQuery` | Query component with error handling for execution. |
| [TpFIBStoredProc](TpFIBStoredProc.md) | `pFIBStoredProc` | Calls stored procedures. |
| [TpFIBUpdateObject](TpFIBUpdateObject.md) | `pFIBQuery` | Custom statements for dataset insert, update, delete. |
| [TpFIBDataSet](TpFIBDataSet.md) | `pFIBDataSet` | Dataset with generated SQL, options, update objects, and cached updates. |
| [TpFIBScripter](TpFIBScripter.md) | `pFIBScripter` | Runs SQL scripts, including `SET` statements and terminators. |
| [TFIBSQLMonitor](TFIBSQLMonitor.md) | `FIBSQLMonitor` | Traces SQL activity of the library. |
| [TpFIBClientDataSet](TpFIBClientDataSet.md) | `pFIBClientDataSet` | Client dataset and provider for multi-tier applications. |
| [IB_Services components](TpFIBServices.md) | `IB_Services` | Service API components: backup, restore, validation, users, statistics. |

## Page template

A class page has these sections, in this order: summary, unit and ancestor, example, guide links, published properties, further sections as the class needs (options, types, run-time properties, methods, events, constants), see also.
Tables use `Name | Type | Default | Description`. Mark version limits inline, for example *Firebird 4+*.
Keep descriptions to one or two sentences; put scenarios and background in the Guide.
