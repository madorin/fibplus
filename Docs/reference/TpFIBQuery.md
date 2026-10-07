# TpFIBQuery

Query component for the component palette. It adds an error event, procedure call helpers, and text BLOB readers to [TFIBQuery](TFIBQuery.md). Use it as the default query component; use `TFIBQuery` for queries created in code that need none of this.

| | |
|---|---|
| Unit | `pFIBQuery` |
| Inherits from | [TFIBQuery](TFIBQuery.md) |
| Descendants | [TpFIBStoredProc](TpFIBStoredProc.md), [TpFIBUpdateObject](TpFIBUpdateObject.md) |

This page lists only what `TpFIBQuery` adds or changes. Preparing, executing, parameters, `Options`, and the other members are described in [TFIBQuery](TFIBQuery.md).

The example calls a stored procedure with two input values and reads an output value. It uses the components `Database`, `Transaction`, and `Query`, with `Query.Database` and `Query.Transaction` assigned.

```delphi
Query.ExecProcedure('ADD_CUSTOMER', ['Smith', 42]);
Writeln(Query.FN('NEW_ID').AsInteger);
```

Guides: [Queries and parameters](../guide/queries-and-parameters.md).

## Published properties

`TpFIBQuery` publishes everything that [TFIBQuery](TFIBQuery.md#published-properties) publishes, and these:

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `Description` | `string` | | Free text stored with the component. |
| `About` | `string` | | Read-only version string of the library (`FIBVersionString`). Writing it has no effect, and it is not stored in the form file. |

## Run-time properties

`TpFIBQuery` adds no run-time properties.

## Methods

### Running

| Name | Description |
|------|-------------|
| `ExecQuery` | Overrides `TFIBQuery.ExecQuery`. Runs the statement and passes an `EFIBError` to `OnExecuteError` when the event is assigned, see [Handling execution errors](#handling-execution-errors). |
| `ExecProc` | Runs `ExecQuery` only when the statement is an `EXECUTE ...` statement (`IsProc`). Does nothing otherwise. |
| `ExecProcedure(ProcName)` | Sets `SQL` to `EXECUTE PROCEDURE ProcName` and runs it. The text is not changed when it is already set. |
| `ExecProcedure(ProcName, InputParams)` | Sets `SQL` to `EXECUTE PROCEDURE ProcName(?P0, ?P1, ...)` with one parameter for each element of `InputParams`, prepares the statement, assigns the values in order with `AsVariant`, and runs it. Read output values with `FN` or `Fields`. |

`ProcName` is inserted into the text as given. It is not quoted or formatted. For a procedure whose parameters come from the database metadata, use [TpFIBStoredProc](TpFIBStoredProc.md).

`IsProc` (a public virtual method of `TFIBQuery`) is `True` when the left-trimmed `SQL` text begins with `EXECUTE` and a space, in any case. An `EXECUTE BLOCK` statement also counts as a procedure call.

### Reading values

| Name | Description |
|------|-------------|
| `FN(Name)` | Column by name. Hides `TFIBQuery.FN`: this one raises when the column does not exist, the base one returns `nil`. A variable declared as `TFIBQuery` calls the base method. |
| `FieldIsNull(Field)` | Returns `Field.IsNull`. |
| `BlobToStrings(BlobFieldName, Destination)` | Loads a text `BLOB` column of the current row into `Destination`. Returns `False` when the cursor is not open, `Destination` is `nil`, the column does not exist, the column is not a `BLOB` with the text subtype, or reading fails. No exception is raised. |
| `BlobAsString(BlobFieldName)` | The same as one string. Returns an empty string when `BlobToStrings` returns `False`. |

## Events

| Name | Description |
|------|-------------|
| `OnExecuteError` | `ExecQuery` raised an `EFIBError`. Set `Action` to choose what happens. |
| `BeforeExecute` / `AfterExecute` | Published here; defined in [TFIBQuery](TFIBQuery.md#events). |

### Handling execution errors

`OnExecuteError` has the type `TFIBQueryErrorEvent`:

```delphi
procedure(pFIBQuery: TpFIBQuery; E: EFIBError; var Action: TDataAction) of object;
```

`Action` is `daFail` when the event is called.

| Action | Result |
|--------|--------|
| `daFail` | The exception is raised again. |
| `daAbort` | A silent exception (`Abort`) ends the call. |
| `daRetry` | The statement runs again. Nothing limits the number of retries. |

The event is called for `EFIBError` only. Other exceptions are raised as they are. Without a handler, `ExecQuery` behaves as in `TFIBQuery`.

```delphi
procedure TMainForm.QueryExecuteError(pFIBQuery: TpFIBQuery; E: EFIBError; var Action: TDataAction);
begin
  if E.IsStatementTimeout then
    Action := daAbort;
end;
```

## See also

- [TFIBQuery](TFIBQuery.md)
- [TpFIBStoredProc](TpFIBStoredProc.md), [TpFIBUpdateObject](TpFIBUpdateObject.md)
- [Queries and parameters](../guide/queries-and-parameters.md)
