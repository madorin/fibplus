# Reference

One page per class. Each page lists properties, methods and events with a short description.
For task-oriented explanations, see the [Guide](../guide/).

| Class | Unit | Description |
|-------|------|-------------|
| <img src="../images/icons/TFIBDatabase.png" width="24" height="24" align="absmiddle" alt=""> [TFIBDatabase](TFIBDatabase.md) | `FIBDatabase` | Connection to a Firebird or InterBase database, with aliases, lost-connection handling, and the schema cache. Includes `Capabilities`, `ConnectParams`, and `DBParams`. |
| [TFIBSession](TFIBSession.md) | `FIBDatabase` | Per-connection session settings, such as timeouts. |
| <img src="../images/icons/TFIBTransaction.png" width="24" height="24" align="absmiddle" alt=""> [TFIBTransaction](TFIBTransaction.md) | `FIBDatabase` | Transaction control: start, commit, rollback, parameters and transaction modes, timeout, events. |
| <img src="../images/icons/TFIBQuery.png" width="24" height="24" align="absmiddle" alt=""> [TFIBQuery](TFIBQuery.md) | `FIBQuery` | Executes SQL statements and reads results without a dataset, with error handling for execution. |
| <img src="../images/icons/TFIBDataSet.png" width="24" height="24" align="absmiddle" alt=""> [TFIBDataSet](TFIBDataSet.md) | `FIBDataSet` | Dataset based on `TFIBQuery`, with caching, sorting, generated SQL, update objects, and cached updates. Includes `TFIBCustomDataSet` and the `TFIB...Field` classes. |
| <img src="../images/icons/TFIBStoredProc.png" width="24" height="24" align="absmiddle" alt=""> [TFIBStoredProc](TFIBStoredProc.md) | `FIBStoredProc` | Calls stored procedures. |
| <img src="../images/icons/TFIBUpdateObject.png" width="24" height="24" align="absmiddle" alt=""> [TFIBUpdateObject](TFIBUpdateObject.md) | `FIBDataSet` | Custom statements for dataset insert, update, delete. |
| <img src="../images/icons/TFIBScripter.png" width="24" height="24" align="absmiddle" alt=""> [TFIBScripter](TFIBScripter.md) | `FIBScripter` | Runs SQL scripts, including `SET` statements and terminators. |
| <img src="../images/icons/TFIBSQLMonitor.png" width="24" height="24" align="absmiddle" alt=""> [TFIBSQLMonitor](TFIBSQLMonitor.md) | `FIBSQLMonitor` | Traces SQL activity of the library. |
| <img src="../images/icons/TFIBClientDataSet.png" width="24" height="24" align="absmiddle" alt=""> [TFIBClientDataSet](TFIBClientDataSet.md) | `FIBClientDataSet` | Client dataset and provider for multi-tier applications. |
| <img src="../images/icons/TFIBBackupService.png" width="24" height="24" align="absmiddle" alt=""> [FIBServices components](TFIBServices.md) | `FIBServices` | Service API components: backup, restore, validation, users, statistics. |

## Page template

A class page has these sections, in this order: summary, unit and ancestor, example, guide links, published properties, further sections as the class needs (options, types, run-time properties, methods, events, constants), see also.
Tables use `Name | Type | Default | Description`. Mark version limits inline, for example *Firebird 4+*.
Keep descriptions to one or two sentences; put scenarios and background in the Guide.
