# TFIBQuery

Executes an SQL statement on a Firebird or InterBase database and gives access to its parameters and result rows, without a `TDataSet`. Use it for commands, stored procedures, and for reading rows in code. For data-aware controls use [TFIBDataSet](TFIBDataSet.md).

| | |
|---|---|
| Unit | `FIBQuery` |
| Inherits from | `TComponent`; implements `ISQLObject` and `IFIBQuery` |
| Descendants | `TpFIBQuery`, which adds more options and error handling; `TpFIBStoredProc`; `TpFIBUpdateObject` |

`Query` is a `TFIBQuery` with `Database` and `Transaction` assigned.

```delphi
Query.SQL.Text := 'SELECT NAME FROM CUSTOMER WHERE ID = :ID';
Query.Params.ByName['ID'].AsInteger := 42;
Query.ExecQuery;
try
  while not Query.Eof do
  begin
    Writeln(Query.FN('NAME').AsString);
    Query.Next;
  end;
finally
  Query.Close;
end;
```

Guides: [Queries and parameters](../guide/queries-and-parameters.md), [Transactions](../guide/transactions.md), [Timeouts](../guide/timeouts.md).

## Published properties

Available in the Object Inspector. The published events are listed under [Events](#events).

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `Database` | `TFIBDatabase` | | Connection the statement runs on. Changing it releases a prepared statement. At design time it is initialized to the default database (`DefDataBase`). |
| `Transaction` | `TFIBTransaction` | | Transaction the statement runs in. |
| `SQL` | `TStrings` | | Statement text. When `ParamCheck` is `True`, `:Name` parameters are parsed from it. |
| `ParamCheck` | `Boolean` | `True` | Parse `:Name` parameters from `SQL`. Set to `False` when the text contains colons that are not parameters. |
| `GoToFirstRecordOnExecute` | `Boolean` | `True` | Position on the first row after `ExecQuery` of a `SELECT`. |
| `StatementTimeout` | `Cardinal` | `0` | Server-side limit in milliseconds, *Firebird 4+*, for `SELECT`, `INSERT`, `UPDATE`, `DELETE` and `EXECUTE PROCEDURE`. `0` uses `Database.Session.StatementTimeout`; `FIBNoStatementTimeout` ignores the session value for this statement (the `firebird.conf` limit still applies). See [Timeouts](../guide/timeouts.md). |
| `Options` | `TpFIBQueryOptions` | `[]` | Behavior flags, see [Options](#options). The initial value comes from `DefQueryOptions` at design time and is empty at run time. |
| `Conditions` | `TConditions` | | Named `WHERE` conditions. `TFIBQuery` does not apply them by itself: call `Conditions.Apply` after enabling or disabling conditions. `Apply` joins the enabled conditions to the main `WHERE` clause with `and`. Assigning `SQL` or `MainWhereClause` discards the applied conditions, and `Apply` must be called again. |
| `CSMonitorSupport` | `TCSMonitorSupport` | | Adds monitoring text to the statement. Only when compiled with `CSMonitor`. |

## Options

`TpFIBQueryOptions` is a set of:

| Value | Effect |
|-------|--------|
| `qoStartTransaction` | Start `Transaction` automatically when it is not active. |
| `qoAutoCommit` | Commit the transaction after the statement completes: after `ExecQuery` without a cursor, or when a cursor is closed or reaches its end. Uses `CommitRetaining` when `Transaction.TimeoutAction` is `TACommitRetaining`, otherwise `Commit`. Only when the transaction is active. |
| `qoTrimCharFields` | Trim trailing blanks of `CHAR` values. |
| `qoNoForceIsNull` | Do not rewrite a comparison with a null parameter. Without this option, `= :Param` becomes `IS NULL`, and `<>`, `!=`, `^=`, `~=` become `IS NOT NULL`, when the parameter is null and sits inside a `WHERE` clause. Parameters used in expressions and outside `WHERE` are not rewritten. |
| `qoFreeHandleAfterExecute` | Release the statement handle after `ExecQuery` without a cursor, or when a cursor is closed or reaches its end. |

Each flag is saved in the form file as its own `qoXxx` entry.

## Run-time properties

### State

| Name | Type | Description |
|------|------|-------------|
| `Open` | `Boolean` | `True` while a cursor is open. |
| `Prepared` | `Boolean` | `True` after `Prepare`. |
| `Eof` | `Boolean` | `True` when the cursor is closed or no more rows can be fetched. |
| `Bof` | `Boolean` | `True` before the first row. |
| `QueryRunState` | `TQueryRunState` | Set of `qrsInPrepare`, `qrsInExecute`, `qrsInClose`; tells what the query is doing now. |
| `Handle` | `TISC_STMT_HANDLE` | Native statement handle. |
| `DBHandle`, `TRHandle` | pointers | Native database and transaction handles. |

### Results

| Name | Type | Description |
|------|------|-------------|
| `Fields[Idx]` | `TFIBXSQLVAR` | Column of the current row by index. |
| `FldByName[Name]` | `TFIBXSQLVAR` | Column by name, raises when missing; the default property. |
| `FieldIndex[Name]` | `Integer` | Index of a column by name, or `-1`. |
| `RecordCount` | `Integer` | Rows fetched so far. |
| `RowsAffected` | `Integer` | Rows changed by the last statement. |
| `AllRowsAffected` | `TAllRowsAffected` | Counts of selected, inserted, updated, and deleted rows. |
| `Plan` | `string` | Access plan of the prepared statement. |
| `CallTime` | `Cardinal` | Duration of the last `ExecQuery`, in milliseconds. |

### Parameters and SQL

| Name | Type | Description |
|------|------|-------------|
| `Params` | `TFIBXSQLDA` | Statement parameters. |
| `SQLType` | `TFIBSQLTypes` | Statement type as reported by the server: select, insert, update, and so on. |
| `SQLKind` | `TSQLKind` | Statement kind as parsed from the text. |
| `ModifyTable` | `string` | Table the statement changes. |
| `MainWhereClause` | `string` | Main `WHERE` clause. Setting it rewrites the SQL. |
| `WhereClause[Index]` | `string` | One `WHERE` clause by index. |
| `WhereClausesCount` | `Integer` | Number of `WHERE` clauses. |
| `IndexMainWhere` | `Integer` | Index of the main `WHERE` clause among `WhereClause[]`, or `-1` when there is none. |
| `OrderClause` | `string` | `ORDER BY` text. |
| `GroupByClause` | `string` | `GROUP BY` text. |
| `FieldsClause` | `string` | Column list of the `SELECT`. |
| `PlanClause` | `string` | `PLAN` text. |
| `CursorName` | `string` | Name for a positioned cursor (`WHERE CURRENT OF`). Set at prepare for `SELECT ... FOR UPDATE`; a random name is generated when it is empty. |
| `SQLTextChangeCount` | `Integer` | Increases each time the effective SQL changes. |
| `MacroChanged` | `Boolean` | A macro value changed since the last execution, `ApplyMacro`, or `SQL` change. |
| `ProcExecuted` | `Boolean` | An `EXECUTE PROCEDURE` statement ran. |

## Methods

### Running

| Name | Description |
|------|-------------|
| `Prepare` | Prepare the statement on the server. Called by `ExecQuery` when needed. |
| `ExecQuery` | Run the statement. For a `SELECT`, opens a cursor and fetches the first row. A DDL statement (`SQLKind` `skDDL`) goes through `ExecuteImmediate`. |
| `ExecuteImmediate` | Run the text with `isc_dsql_execute_immediate`, without keeping a prepared statement. Returns no rows. |
| `ExecuteAsBatch` / `ExecuteAsBatch(SQLs)` | *InterBase 2007 only*, when compiled with `SUPPORT_IB2007`; does nothing on other connections. Sends several statements in one call with `isc_dsql_batch_execute_immed`. Without arguments it splits `SQL.Text` on `;`; with an array it sends those statements. |
| `ExecWP(Values)` | Set parameters from an array in order, then `ExecQuery`. |
| `ExecWP(Names, Values)` | Same, with parameter names separated by `;`. The number of names must equal the number of values. |
| `ExecWPS(Source, AllRecords)` / `ExecWPS(Sources)` | Fill the parameters from `ISQLObject` sources, such as another query or dataset, then `ExecQuery`. A parameter takes the value of the column with the same name, otherwise of a source parameter with that name; with several sources, a later source overrides an earlier one. A `NEW_` or `OLD_` prefix on the parameter name is ignored when matching columns (`OLD_` reads the old value). With `AllRecords = True` (default) the statement runs once per source row until `IEof`, advancing with `INext`; `OnBatchError` handles failures, and `beRetry` continues with the next row. With `False`, or with the array overload, it runs once. |
| `Next` | Fetch the next row. Returns `Current`, or `nil` at the end of the data or when `OnSQLFetch` stops the fetch. |
| `Close` | Close the cursor. |
| `FreeHandle` | Release the statement on the server. The next run prepares again. |

### Reading and writing values

| Name | Description |
|------|-------------|
| `FieldByName(Name)` | Column by name. Raises when the column does not exist. |
| `FN(Name)` | Column by name, or `nil` when missing. `TpFIBQuery.FN` raises instead, like `FieldByName`. |
| `FindField(Name)` | Column by name, or `nil`. |
| `FieldByOrigin(Table, Field)` | Column by source table and field. |
| `ParamByName(Name)` | Parameter by name. For an `EXECUTE PROCEDURE` statement it falls back to the output column of that name. Raises when neither exists. |
| `FindParam(Name)` | Parameter by name, or `nil`. |
| `SetParamValues(Values)` / `SetParamValues(Names, Values)` | Set parameters from an array without executing. |
| `Current` | `TFIBXSQLDA` of the current row. |
| `FieldCount`, `ParamCount` | Number of columns and parameters. |
| `SQLFieldName(Name)` | Column as `Alias.SourceField` with formatted identifiers, or an empty string when the column is missing or has no source table. Prepares the statement if needed. |
| `TableAliasForField(Index)` / `TableAliasForField(Name)` / `TableAliasForFieldByName(Name)` | Alias of the source table of a column, or an empty string. Only the index overload prepares the statement itself; prepare first when using a name. |

### SQL text and macros

| Name | Description |
|------|-------------|
| `BeginModifySQLText` / `EndModifySQLText` | Batch several clause changes into one rewrite of the SQL. |
| `CountModifySQLText` | Current nesting depth of `BeginModifySQLText`. |
| `ApplyMacro` | Substitute macro values into the text. |
| `RestoreMacroDefaultValues` | Set macros back to their defaults. |
| `ReadySQLText` | The statement text with macro values substituted and null comparisons rewritten (see `qoNoForceIsNull`), as sent to the server. |
| `IsProc` | `True` when the trimmed `SQL` text begins with `EXECUTE` and a space. Virtual. |
| `AssignProperties(Source)` | Copy settings from another query. |

### Batch operations

| Name | Description |
|------|-------------|
| `BatchInput(Stream)` | Run the statement once for each row read from a `TFIBBatchInputStream`. Returns `False` without reading unless the statement is `INSERT`, `UPDATE`, `DELETE` or `EXECUTE PROCEDURE`. For batch file version 3 and later it raises an `Exception` when the file character set differs from `Database.ConnectParams.Charset`. |
| `BatchOutput(Stream)` | Execute a `SELECT` and write every row to a `TFIBBatchOutputStream`. The cursor must be closed first or the call raises. Returns `False` for any other statement type. Any exception raised while executing or writing is caught, the cursor is closed and `False` is returned. |
| `BatchInputRawFile(File)` / `BatchOutputRawFile(File, Version)` | The same with a raw batch file. `BatchOutputRawFile` ignores `Version` and always writes version 3. Neither reports the result. |
| `BatchToQuery(ToQuery, Mappings)` | Run `ToQuery` once per row of this query's result. `Mappings` holds `ParamName=ColumnName` lines. Columns without a mapping go to the parameter with the same name, and columns without a matching parameter are skipped. `Mappings = nil` maps by identical names. |

`BatchInput`, `BatchOutput` and `BatchToQuery` call `OnBatching` for each row. `BatchInput` and `BatchToQuery` handle failures with `OnBatchError`; `BatchOutput` does not use it. `ExecWPS` does not call `OnBatching`.

### Checks

| Name | Description |
|------|-------------|
| `CheckClosed(Op)` / `CheckOpen(Op)` | Raise if the cursor is open, or closed. |
| `CheckValidStatement` | Prepare the statement to validate it, connecting and starting a transaction temporarily if needed. Raises when the statement cannot be prepared. |

### ISQLObject

`ISQLObject` is the interface that `ExecWPS` reads from and writes to. `TFIBQuery` implements it with these members:

| Name | Description |
|------|-------------|
| `ParamName(Index)`, `FieldName(Index)`, `FieldsCount` | Names and count of parameters and columns. `FieldsCount` equals `FieldCount`. |
| `FieldExist(Name, Index)`, `ParamExist(Name, Index)` | Look up a column or parameter by name and return its index. |
| `FieldValue(Name, Old)`, `FieldValue(Index, Old)` | Value of a column. `Old` is ignored. |
| `ParamValue(Name)`, `ParamValue(Index)`, `SetParamValue(Index, Value)` | Read and write a parameter value. |
| `DefMacroValue(Name)` | Default value of a macro. |
| `IEof`, `INext` | Same as `Eof` and `Next`. |

## Events

`OnSQLChanging`, `AfterFirstFetch`, `OnBatching`, `OnBatchError`, `TransactionEnding` and `TransactionEnded` are published. `BeforeExecute`, `AfterExecute` and `OnSQLFetch` are public properties only; `TpFIBQuery` publishes the first two.

| Name | Description |
|------|-------------|
| `BeforeExecute` / `AfterExecute` | Before and after the statement runs. |
| `AfterFirstFetch` | On the first `Next` after an execute, also when the result is empty. With `GoToFirstRecordOnExecute` set to `False` it fires on the first explicit `Next`. |
| `OnSQLChanging` | The `SQL` text is about to change. |
| `OnSQLFetch` | Before each fetch. `RecordNumber` is the number of rows fetched so far. Set `StopFetching` to make `Next` return `nil` without fetching; `Eof` stays `False`. |
| `TransactionEnding` / `TransactionEnded` | Not called by the library. An open cursor is closed automatically when its transaction commits or rolls back. |
| `OnBatching` | During a batch operation, for each row. Set `BatchAction`: continue, stop, or skip. |
| `OnBatchError` | A batch row failed. Set `BatchErrorAction`: fail, abort, retry, or ignore. |

## Constants

| Name | Description |
|------|-------------|
| `FIBNoStatementTimeout` | `StatementTimeout` value that ignores `Session.StatementTimeout`; the `firebird.conf` limit still applies. |

## See also

- [TFIBDatabase](TFIBDatabase.md), [TFIBTransaction](TFIBTransaction.md), [TFIBDataSet](TFIBDataSet.md)
- [TpFIBQuery](TpFIBQuery.md)
- [Timeouts](../guide/timeouts.md)
