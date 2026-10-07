# Queries and parameters

`TFIBQuery` runs one SQL statement and gives you its parameters and result rows without a `TDataSet`. This article shows how to prepare and execute statements, pass parameters, use macros and conditions, call stored procedures, and move many rows with the batch methods. For data-aware controls use a dataset instead, see [Datasets and caching](datasets-and-caching.md).

The samples use these components: `Database` (`TpFIBDatabase`), `Transaction` (`TpFIBTransaction`), and `Query`, `SourceQuery`, `TargetQuery` (all `TpFIBQuery`), with `Database` and `Transaction` assigned to each query. `StoredProc` is a `TpFIBStoredProc` and `NewId` is an `Integer` variable. The samples assume that the connection is open and that `Transaction` is started, unless a sample starts it itself; see [The transaction](#the-transaction). Members of `TFIBQuery` are listed in the [reference](../reference/TFIBQuery.md).

## Running a statement

Set the text in `SQL` and call `ExecQuery`. A statement that returns no rows, such as `INSERT`, runs and finishes. A `SELECT` opens a cursor and, by default, fetches the first row.

```delphi
Query.SQL.Text := 'UPDATE CUSTOMER SET ACTIVE = 0 WHERE LAST_ORDER < :Limit';
Query.ParamByName('Limit').AsDateTime := EncodeDate(2024, 1, 1);
Query.ExecQuery;
ShowMessage(IntToStr(Query.RowsAffected) + ' rows changed');
Transaction.Commit;
```

`ExecQuery` prepares the statement when it is not prepared yet. Call `Prepare` yourself only when you need the statement metadata (`Params`, `Fields`, `Plan`) before the first run. Changing `SQL` releases the prepared statement, and the next `ExecQuery` prepares again. To keep a statement prepared, leave `SQL` alone and change only the parameter values. Two kinds of value change also prepare again: a change of a macro value (see [Macros](#macros)), and a switch between null and not null of a parameter that FibPlus can rewrite to `IS NULL` (see [Null in WHERE conditions](#null-in-where-conditions)). The second case does not occur with `qoNoForceIsNull`.

DDL statements (`CREATE`, `ALTER`, `DROP`, and so on) run through `ExecuteImmediate`. `ExecQuery` does this for you when it recognizes the statement as DDL.

### The transaction

The query runs in `Transaction`. Without help, the transaction must already be started when the statement is prepared; otherwise the call raises an error. The exception is a transaction whose databases all have `AutoReconnect` turned on, which `ExecQuery` starts for you.

Two options in `Options` take over part of the work, see [Options](../reference/TFIBQuery.md#options):

| Option | Effect |
|--------|--------|
| `qoStartTransaction` | Starts `Transaction` before the statement is prepared when it is not active |
| `qoAutoCommit` | Commits after the statement completes: after `ExecQuery` without a cursor, or on `Close` of a cursor |

With `qoAutoCommit` the commit is a retaining commit when `Transaction.TimeoutAction` is `TACommitRetaining`. Otherwise it is a full commit. See [Transactions](transactions.md) for isolation levels and for what a commit does to open cursors.

### Reading rows

After `ExecQuery` of a `SELECT`, the first row is current. Read columns with `FieldByName` and fetch further rows with `Next`. `Eof` becomes `True` after the last row.

```delphi
Query.SQL.Text := 'SELECT ID, NAME FROM CUSTOMER ORDER BY NAME';
Query.ExecQuery;
try
  while not Query.Eof do
  begin
    Writeln(Query.FieldByName('ID').AsInteger, ' ', Query.FieldByName('NAME').AsString);
    Query.Next;
  end;
finally
  Query.Close;
end;
```

- If you set `GoToFirstRecordOnExecute` to `False`, no row is current after `ExecQuery`. Call `Next` before the first read.
- `Fields[Index]` reads a column by position. `FindField` returns `nil` instead of raising when the column does not exist.
- Call `Close` when you stop before `Eof`. When `qoAutoCommit` or `qoFreeHandleAfterExecute` is set, the cursor also closes by itself at the end of the rows.

`TFIBQuery.FN` is a short form of `FieldByName`, but on `TFIBQuery` it returns `nil` for a missing column, while `TpFIBQuery.FN` raises like `FieldByName`. Use `FieldByName` when you want the error.

## Parameters

A `:Name` or `?Name` in the statement text is a parameter. With `ParamCheck` set to `True` (the default), FibPlus finds the parameters when you change `SQL`. Set `ParamCheck` to `False` when the text must be sent unchanged, even if it contains colons or macro characters. Then `Params` is empty.

### Setting values

`ParamByName` and `Params.ParamByName` find a parameter by name and raise an error if it does not exist. `FindParam` and `Params.ByName` return `nil` instead, so check the result before you use it. Unquoted names are not case sensitive.

```delphi
Query.SQL.Text := 'INSERT INTO CUSTOMER (ID, NAME, CREDIT) VALUES (:ID, :NAME, :CREDIT)';
Query.ParamByName('ID').AsInteger := 42;
Query.ParamByName('NAME').AsString := 'Acme';
Query.ParamByName('CREDIT').IsNull := True;
Query.ExecQuery;
```

Each parameter has typed accessors such as `AsString`, `AsInteger`, `AsInt64`, `AsCurrency`, `AsDouble`, `AsDateTime`, `AsBoolean`, and `AsVariant`. Set `IsNull` to `True` to pass `NULL`. For BLOB and array parameters see [BLOBs and arrays](blobs-and-arrays.md).

`Params[Index]` addresses parameters by position, following the order of the text. Macros are part of `Params` too and take a position in the same order, see [Macros](#macros).

### Setting values and running in one call

| Method | Use |
|--------|-----|
| `SetParamValues` | Set values without running; positional, or with a `;` separated name list |
| `ExecWP` | `SetParamValues`, then `ExecQuery` |

```delphi
Query.ExecWP([42, 'Acme', Null]);                           // by position
Query.ExecWP('ID;NAME;CREDIT', [43, 'Globex', 1500.5]);     // by name
```

With a name list, the number of names must equal the number of values, or the call raises an error. By position, surplus values are ignored and missing ones leave the remaining parameters unchanged. For a statement with macros, use the name list: a positional call writes the first value into the first macro.

### Repeating a statement

A prepared statement is reused when `SQL` does not change. Set new values and call `ExecQuery` again. The sample starts the transaction itself.

```delphi
Query.SQL.Text := 'INSERT INTO CUSTOMER (ID, NAME) VALUES (:ID, :NAME)';
Transaction.StartTransaction;
try
  Query.ExecWP([1, 'Alpha']);
  Query.ExecWP([2, 'Beta']);
  Query.ExecWP([3, 'Gamma']);
  Transaction.Commit;
except
  Transaction.Rollback;
  raise;
end;
```

### Parameters from another object

`ExecWPS` takes the parameter values from an object that implements `ISQLObject`, such as another query or a dataset. A parameter is filled from the source column with the same name, or, if there is none, from the source parameter with the same name. With `AllRecords` set to `True` (the default), it runs the statement once for every remaining row of the source and moves the source to the next row each time.

```delphi
// SourceQuery is an open SELECT; Query is an INSERT with the same column names as parameters
Query.ExecWPS(SourceQuery);
```

If a row fails and `OnBatchError` is assigned, the handler can answer `beFail` (raise the error again) or `beAbort` (stop with `EAbort`). Any other answer, including `beRetry`, continues with the next row; the row is not run again. `ExecWPS` does not call `OnBatching`. The `OnBatchError` handler is described under [Events](#events).

### Null in WHERE conditions

`WHERE NAME = :Name` never matches when `:Name` is `NULL`. By default FibPlus rewrites such a comparison to `IS NULL` at execution time when the parameter is null and sits in the `WHERE` clause. The operators `<>`, `!=`, `^=`, and `~=` become `IS NOT NULL`. Add `qoNoForceIsNull` to `Options` to turn this off and send the text as written.

## Macros

A macro puts text into the statement before it is prepared. Use it for the parts that parameters cannot replace, for example a table name or an `ORDER BY` list. Macros need `ParamCheck` set to `True`.

A macro name starts with `@`, which is the macro character. Two forms are recognized in the text. A macro that is not closed as shown is not recognized and breaks the statement, so an old form macro must be followed by a blank or line break, not by a tab or the end of the text:

| Form | Ends at | Example |
|------|---------|---------|
| `@@Name@` | The closing `@` | `SELECT * FROM @@Table@ WHERE ID = :ID` |
| `@Name` | The next blank or line break | `SELECT * FROM @Table WHERE ID = :ID` |

A default value follows the name after `%`, for example `@@Table%CUSTOMER@`. A macro whose default starts with `#` is a quoted macro. The `#` is dropped from the default, and every value of the macro is put in single quotes unless it already starts with a quote.

The value is a parameter of `Params` with the macro name, without `@`. Macros and parameters share one list in the order of the text, so `Params.Count` includes the macros:

```delphi
Query.SQL.Text := 'SELECT * FROM @@Table%CUSTOMER@ WHERE ID = :ID';
Query.ParamByName('Table').AsString := 'SUPPLIER';
Query.ParamByName('ID').AsInteger := 7;
Query.ExecQuery;
```

When a macro value changed since the last run, `Prepare` builds the statement text again and prepares it again. You do not need to call `ApplyMacro` before `ExecQuery`; call it when you need the parameters of the new text before running. `RestoreMacroDefaultValues` sets every macro back to its default. `ReadySQLText` returns the text with macro values substituted and null comparisons rewritten.

Other macros are inserted unchanged. Quoted macros get quotes, but quotes inside the value are not doubled. Never fill a macro from user input without checking it.

## Conditions

`Conditions` holds named `WHERE` conditions that you can switch on and off. `Conditions.Apply` rewrites the main `WHERE` clause: the original clause, if any, joined by `and` with every enabled condition. `Conditions.CancelApply` restores the original text.

```delphi
Query.SQL.Text := 'SELECT * FROM ORDERS';
Query.Conditions.AddCondition('OpenOnly', 'STATUS = 0', True);
Query.Conditions.AddCondition('Recent', 'ORDER_DATE > :Since', False);
Query.Conditions.ByName('Recent').Enabled := True;
Query.Conditions.Apply;
Query.ParamByName('Since').AsDateTime := Date - 30;
Query.ExecQuery;
```

`TFIBQuery` does not call `Apply` by itself. Call it after you change a condition and before you run the query. Assigning new text to `SQL` discards the applied conditions; call `Apply` again if you still need them. Setting `OrderClause`, `GroupByClause`, or `FieldsClause` keeps applied conditions.

To read or change one clause without conditions, use `MainWhereClause`, `WhereClause[Index]`, and `OrderClause`. Each assignment rewrites `SQL`, which closes the query and releases the prepared statement. `BeginModifySQLText` and `EndModifySQLText` around several changes defer the re-parse of parameters and macros until `EndModifySQLText`.

## Stored procedures

Three ways to call a procedure:

| Way | When |
|-----|------|
| `TpFIBStoredProc` | A procedure you call often. Set `StoredProcName`; the component builds the `EXECUTE PROCEDURE` text from the metadata. |
| `TpFIBQuery.ExecProcedure` | A one-off call by name from code. |
| A `SELECT` statement | A selectable procedure that returns rows. |

### TpFIBStoredProc

```delphi
StoredProc.StoredProcName := 'ADD_CUSTOMER';
StoredProc.ParamByName('NAME').AsString := 'Acme';
StoredProc.ExecProc;
NewId := StoredProc.FN('NEW_ID').AsInteger;
```

`StoredProcName` builds the statement text when the database is connected. If the database is not connected yet, the text is built when it first is needed. `ExecProc` runs the statement. See [TpFIBStoredProc](../reference/TpFIBStoredProc.md) for the members this class adds.

Output parameters are read as columns of the query (`FN`, `FieldByName`, `Fields`) after execution. `ParamByName` also finds an output parameter of a procedure call when no input parameter has that name.

`GetParamDefValue` returns the default value declared for a parameter. Parameter defaults exist since *Firebird 2+*.

### ExecProcedure

`ExecProcedure` writes the `EXECUTE PROCEDURE` text, sets the values by position, and runs it:

```delphi
Query.ExecProcedure('ADD_CUSTOMER', ['Acme']);
```

Pass one value for each input parameter, in the order of the procedure declaration.

### Selectable procedures

A procedure that returns rows is selected like a table. Use an ordinary query:

```sql
SELECT * FROM GET_ORDERS(:CustomerId)
```

## Batch operations

The batch methods run one statement for many rows without a dataset.

| Method | What it does |
|--------|--------------|
| `BatchToQuery(ToQuery, Mappings)` | Runs `Query` (a `SELECT`) and executes `ToQuery` once for every row, with the row as parameters |
| `BatchInput(Stream)` | Executes the statement once for every row read from a `TFIBBatchInputStream` |
| `BatchOutput(Stream)` | Writes the rows of a `SELECT` to a `TFIBBatchOutputStream` |
| `BatchInputRawFile(File)`, `BatchOutputRawFile(File)` | `BatchInput` and `BatchOutput` with the raw file format |

`BatchInput` works for `INSERT`, `UPDATE`, `DELETE`, and `EXECUTE PROCEDURE` statements; `BatchOutput` works for a `SELECT`. For another statement type, both return `False` and do nothing. `BatchOutput` also raises an error when the query is already open.

The stream classes are in the unit `FIBMiscellaneous`: `TFIBInputDelimitedFile` and `TFIBOutputDelimitedFile` for delimited text files, `TFIBInputRawFile` and `TFIBOutputRawFile` for the raw format. You can also derive your own class from `TFIBBatchInputStream` or `TFIBBatchOutputStream`. Set `FileName` on the stream before the call. The delimited output separates columns with a tab unless you set `ColDelimiter`. In the sample, `Output` is a `TFIBOutputDelimitedFile` variable and `SourceQuery` holds a closed `SELECT`:

```delphi
Output := TFIBOutputDelimitedFile.Create;
try
  Output.FileName := 'customers.txt';
  if not SourceQuery.BatchOutput(Output) then
    ShowMessage('The export failed');
finally
  Output.Free;
end;
```

A column is matched to a parameter of the same name. `Mappings` in `BatchToQuery` changes that: each line is `ParamName=ColumnName`. Pass `nil` to use the names as they are.

```delphi
Mappings := TStringList.Create;
try
  Mappings.Add('CUSTOMER_NAME=NAME');
  SourceQuery.SQL.Text := 'SELECT ID, NAME FROM CUSTOMER';
  TargetQuery.SQL.Text := 'INSERT INTO CUSTOMER_COPY (ID, CUSTOMER_NAME) VALUES (:ID, :CUSTOMER_NAME)';
  SourceQuery.BatchToQuery(TargetQuery, Mappings);
finally
  Mappings.Free;
end;
```

The raw file methods write and read a binary file with the column data. `BatchOutputRawFile` always writes format version 3, whatever you pass for `Version`. That format records the connection character set, and `BatchInput` raises an error when it differs from the character set of the current connection.

### Events

| Event | Called | Used by | Your answer |
|-------|--------|---------|-------------|
| `OnBatching` | For each row | `BatchInput`, `BatchOutput`, `BatchToQuery` | `BatchAction`: `baContinue`, `baStop`, or `baSkip` |
| `OnBatchError` | When a row fails with `EFIBError` | `BatchInput`, `BatchToQuery`, `ExecWPS` | `BatchErrorAction`: `beFail`, `beAbort`, `beRetry`, or `beIgnore` |

`beFail` (the default) raises the error again, `beAbort` ends silently with `EAbort`, `beRetry` runs the row again, and `beIgnore` goes to the next row. Without an `OnBatchError` handler the error is raised. `ExecWPS` honors only `beFail` and `beAbort`, see [Parameters from another object](#parameters-from-another-object). `BatchOutput` does not call `OnBatchError`.

```delphi
procedure TMainForm.QueryBatchError(E: EFIBError; var BatchErrorAction: TBatchErrorAction);
begin
  Memo1.Lines.Add(E.Message);
  BatchErrorAction := beIgnore;
end;
```

## Errors and pitfalls

- **Colons in the text.** A `:` inside a quoted string or a comment is not a parameter. Elsewhere it starts one. Set `ParamCheck` to `False` for a statement that must be sent unchanged.
- **Not in a transaction.** `ExecQuery` on a query whose transaction is not started raises an error, unless you set `qoStartTransaction`. See [The transaction](#the-transaction).
- **Open cursor.** Running `ExecQuery` on an open query closes the cursor first. Close cursors before you end the transaction, see [Transactions](transactions.md).
- **Missing parameter or column.** `ParamByName` and `FieldByName` raise; `FindParam`, `Params.ByName`, and `FindField` return `nil`.
- **`BatchOutput` hides errors.** It catches every exception while it runs, closes the query, and returns `False`. Check the result.
- **Handling failures of one statement.** `TpFIBQuery` has the event `OnExecuteError`. Set its `Action` to `daRetry` to run the statement again, `daAbort` to cancel silently, or `daFail` to raise. See [TpFIBQuery](../reference/TpFIBQuery.md).
- **Long statements.** To stop a statement that runs too long, use a statement timeout, see [Timeouts](timeouts.md).

## See also

- [TFIBQuery reference](../reference/TFIBQuery.md)
- [TpFIBQuery](../reference/TpFIBQuery.md), [TpFIBStoredProc](../reference/TpFIBStoredProc.md)
- [Transactions](transactions.md)
- [BLOBs and arrays](blobs-and-arrays.md)
- [Datasets and caching](datasets-and-caching.md)
- [Timeouts](timeouts.md)
