# TpFIBStoredProc

Query component that calls a stored procedure by name. It reads the input parameters of the procedure from the database metadata and builds the `EXECUTE PROCEDURE` statement. Use it for parameters created from the metadata; use [TpFIBQuery](TpFIBQuery.md) with `ExecProcedure` or a hand-written `SQL` text otherwise.

| | |
|---|---|
| Unit | `pFIBStoredProc` |
| Inherits from | [TpFIBQuery](TpFIBQuery.md) |

This page lists only what `TpFIBStoredProc` adds or changes. The other members are described in [TpFIBQuery](TpFIBQuery.md) and [TFIBQuery](TFIBQuery.md).

The example uses the components `Database`, `Transaction`, and `StoredProc`, with `StoredProc.Database` and `StoredProc.Transaction` assigned and the database connected.

```delphi
StoredProc.StoredProcName := 'ADD_CUSTOMER';
StoredProc.ParamByName('NAME').AsString := 'Smith';
StoredProc.ExecProc;
Writeln(StoredProc.FN('NEW_ID').AsInteger);
```

Guides: [Queries and parameters](../guide/queries-and-parameters.md).

## Published properties

`TpFIBStoredProc` publishes everything that [TpFIBQuery](TpFIBQuery.md#published-properties) publishes, and this:

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `StoredProcName` | `string` | | Name of the procedure. Setting it replaces `SQL`, see [How the SQL is built](#how-the-sql-is-built). |

## Methods

| Name | Description |
|------|-------------|
| `IsProc` | Returns `True` while the `SQL` build is still deferred, so that `ExecProc` does not skip the call. Otherwise it tests the `SQL` text as `TFIBQuery.IsProc` does. |
| `GetParamDefValue(ParamNo)` / `GetParamDefValue(ParamName)` | Default value of an input parameter, see [Parameter defaults](#parameter-defaults). |
| `Loaded` | Overrides `TComponent.Loaded`. Marks the build as deferred when `StoredProcName` is set and `SQL` is empty. |

## How the SQL is built

The text is `EXECUTE PROCEDURE Name (?ParamName1, ?ParamName2, ...)`, for example `EXECUTE PROCEDURE ADD_CUSTOMER (?NAME)`, with one parameter for each **input** parameter of the procedure, in the order of the procedure declaration. A procedure without input parameters gives `EXECUTE PROCEDURE Name`. Output values are read with `FN` or `Fields` after `ExecProc`.

`Name` is formatted for the dialect of `Database` with its `EasyFormatsStr` setting. The parameters are read from the system tables with a separate transaction, and the result is cached per database name and procedure name.

| Situation | Behavior |
|-----------|----------|
| `StoredProcName` set while `Database` is connected | `SQL` is built at once. At design time the metadata is read again every time, so an altered procedure is picked up. |
| `StoredProcName` set while `Database` is not connected, or not assigned | `SQL` is cleared and the build is deferred. It runs when `Database` is assigned while connected, and before `Prepare`, `ExecQuery`, `ExecuteImmediate`, or the first access to `Params`. |
| Component loaded from a form file | `SQL` is taken from the file. If it is empty and `StoredProcName` is set, the build is deferred. |
| Reading the metadata fails | `SQL` is cleared, so the statement of the previous procedure cannot run, and the build stays deferred. The error is raised. |

Changing `StoredProcName` replaces any `SQL` that was set directly. Changing `Database` assigns the new database and builds a deferred `SQL` when it can.

## Parameter defaults

`GetParamDefValue` returns the default of an input parameter as the source text, for example `5` or `'abc'` (string defaults keep their quotes). A leading `=` or `DEFAULT` is removed. The result is an empty string when the parameter has no default, `ParamNo` is out of range, `StoredProcName` is empty, or `Database` is `nil`.

`ParamNo` is the zero-based index of the input parameter. The `ParamName` overload finds the index with `ParamByName`, which raises when the name is unknown. The name must be an input parameter: for a procedure call, `ParamByName` falls back to the output columns, and an output name gives the index of a column and the default of an unrelated parameter.

The default is read from the procedure parameter on *Firebird 2.0+*. On older servers and on InterBase it comes from the domain of the parameter.

## See also

- [TpFIBQuery](TpFIBQuery.md), [TFIBQuery](TFIBQuery.md)
- [TFIBDatabase](TFIBDatabase.md), [TFIBTransaction](TFIBTransaction.md)
- [Queries and parameters](../guide/queries-and-parameters.md)
