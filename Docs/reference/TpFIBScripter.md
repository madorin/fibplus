# TpFIBScripter

Splits an SQL script into statements and runs them one by one on a database. It understands the `SET TERM` command, conditional directives, and client commands such as `CONNECT` and `INPUT`, and sends all other statements, including session `SET` statements, to the server. Use it for DDL scripts and data scripts. To run a single statement from code, use [TpFIBQuery](TpFIBQuery.md).

| | |
|---|---|
| Unit | `pFIBScripter` |
| Inherits from | `TComponent` |
| Implements | `IFIBScripter` |

The example uses the components `Database` (`TpFIBDatabase`), `Scripter` (`TpFIBScripter`, with `Scripter.Database` set to `Database`), and `LogMemo` (`TMemo`).

```delphi
procedure TMainForm.ScripterExecuteError(Sender: TObject; StatementNo, Line: Integer;
  Statement: TStrings; SQLCode: Integer; const Msg: string; var DoRollBack, Stop: Boolean);
begin
  LogMemo.Lines.Add(Format('Line %d: %s', [Line, Msg]));
  DoRollBack := False;
  Stop := False;
end;

Scripter.OnExecuteError := ScripterExecuteError;
Scripter.Script.LoadFromFile('update.sql');
Scripter.ExecuteScript;
```

Guides: [Scripting](../guide/scripting.md).

## Published properties

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `Database` | `TpFIBDatabase` | | Database the script runs on. Assigning it commits an active transaction of the scripter first. Without a database, a `CONNECT`, `CREATE DATABASE`, or `DROP DATABASE` statement creates a temporary one; the scripter commits and releases it at the end of the top-level run. |
| `Transaction` | `TpFIBTransaction` | | Transaction for the statements. When it is `nil`, the scripter uses an internal transaction on `Database`. Statements start the transaction when it is not active. |
| `Script` | `TStrings` | | Script text. Changing it discards the parsed script (`Prepared` becomes `False`). |
| `AutoDDL` | `Boolean` | `True` | Commit the transaction after each DDL statement. A `SET AUTODDL` command in the script changes this property and the change stays after the run. |
| `UseExecBlockForDML` | `Boolean` | `False` | Group consecutive `INSERT`, `REINSERT`, `UPDATE`, `DELETE`, `MERGE`, and `EXECUTE` statements into `EXECUTE BLOCK` statements, see [Grouping DML statements](#grouping-dml-statements). The `{$EXECUTE_BLOCK ON}` and `{$EXECUTE_BLOCK OFF}` directives change this property. |

## Run-time properties

| Name | Type | Description |
|------|------|-------------|
| `Prepared` | `Boolean` | `True` after `Parse`, until `Script` changes or `ClearPrepared` is called. Read only. |
| `Paused` | `Boolean` | `True` when the run is stopped. Set it to `True` in an event handler to stop before the next statement. |
| `SkipStatement` | `Boolean` | Set it to `True` in `BeforeStatementExecute` to skip the statement about to run. |
| `StopStatementNo` | `Integer` | Number of the statement at which a paused `ExecuteScript` stopped; pass it to `ExecuteScript` to resume. Set only when another statement follows the pause, see [Pausing and resuming](#pausing-and-resuming). Read only. |
| `MakeConnectInScript` | `Boolean` | `True` when the parsed script contains `CONNECT` or `CREATE DATABASE`. Read only; valid after `Parse`. |
| `Query` | `TpFIBQuery` | The internal query that runs the statements. Read only. |
| `Defines` | `TStrings` | Names defined for `{$IFDEF}`. Assigning a list copies it in upper case. |

## Methods

### Running

| Name | Description |
|------|-------------|
| `ExecuteScript(FromStmt)` | Run the statements of `Script` from statement number `FromStmt` (1-based, default `1`). Calls `Parse` first when the script is not prepared. See [Pausing and resuming](#pausing-and-resuming). |
| `ExecuteFromFile(FileName, Terminator)` | Run a script file without loading it into `Script`. The file is parsed while it is read, so only the current statement is kept in memory. The default terminator is `;`. A run from a file cannot be resumed. |
| `ExecuteStatement(StmtTxt, Stmt, StmtNo, TmpSQL, LineInFile)` | Run one parsed statement; does nothing when `Stmt` is `nil`. `StmtNo` is 0-based; the events receive `StmtNo + 1`. `ExecuteScript` calls it with the statement text as both `StmtTxt` and `TmpSQL`; `TmpSQL` is the text that is run. A `LineInFile` other than `-1` replaces the line number passed to `BeforeStatementExecute` and `AfterStatementExecute`; `OnExecuteError` always receives the parsed line. |

### Parsing

| Name | Description |
|------|-------------|
| `Parse(Terminator)` | Split `Script` into statements and set `Prepared`. The default terminator is `;`; an empty string also means `;`. Raises an `Exception` for an unbalanced `{$ENDIF}`, an invalid `SET TERM`, and an unexpected `{`. |
| `ClearPrepared` | Discard the parsed script. |
| `StatementsCount` | Number of parsed statements. `SET TERM` commands are not counted. |
| `GetStatement(StmtNo, Text)` | Return a `PStatementDesc` for statement `StmtNo` (1-based) and copy its text to `Text`. Raises when the number does not exist. The pointer refers to the parsed script and is not valid after `ClearPrepared` or another `Parse`. |
| `LineCountInCurrentFile` | Number of lines of the file run by the last `ExecuteFromFile`. |

### Directive names

| Name | Description |
|------|-------------|
| `AddDefine(Def)` / `DeleteDefine(Def)` | Add or remove a name for `{$IFDEF}`. Names are compared in upper case. |
| `PreparePreDefines` | Set the predefined names and constants from the connected server, see [Directives](#directives). `ExecuteScript` calls it at the start of a run and after `CONNECT` and `CREATE DATABASE`. |

## Events

| Name | Type | Description |
|------|------|-------------|
| `BeforeStatementExecute` | `TOnStatementExecute` | Before a statement runs. Not called for statements skipped by a directive. Set `SkipStatement` to skip the statement. |
| `AfterStatementExecute` | `TOnStatementExecute` | After a statement that was sent to the server ran without an error. Not called for the commands that the scripter handles itself. |
| `OnExecuteError` | `TOnSQLScriptExecError` | An `EFIBError` was raised by `CONNECT`, `CREATE DATABASE`, `COMMIT`, or a statement sent to the server. See [Error handling](#error-handling). |

## Statement handling

A statement is handled by the scripter or sent to the server, depending on its first words. The type is in `TStatementDesc.smtType`.

| Statement | Handling |
|-----------|----------|
| `CONNECT 'db' [USER u] [PASSWORD p] [ROLE r]` | Closes the database if it is connected, sets `DBName`, user, password, role, SQL dialect, and library name, clears `DBParams`, and connects. The character set is the one set by the last `SET NAMES`; it is empty otherwise. |
| `CREATE DATABASE 'db' ...` | Closes the database if it is connected, sets `DBName`, dialect, and library name, copies the rest of the statement to `DBParams`, and calls `CreateDatabase`. When `NeedUTFEncodeDDL` is true and the attachment character set ID is `0`, it then reconnects with `force_write=0` added to `DBParams`, and the end of the top-level run reconnects again with `force_write` set to `1`. |
| `DROP DATABASE 'db' [USER u] [PASSWORD p]` | Sets `DBName` and library name, connects with the given user and password, and calls `DropDatabase`. |
| `DISCONNECT` | Closes the connection. |
| `RECONNECT` | Commits an active transaction and connects again. |
| `COMMIT`, `ROLLBACK` | Ends the transaction when it is active. |
| `INPUT 'file'` | Runs the file with `ExecuteFromFile` and the terminator `;`. |
| `DESCRIBE` | Sets the description of a domain, table, view, trigger, field, parameter, procedure, exception, function, UDF, generator, or package with an `UPDATE` of its `RDB$DESCRIPTION` column. Other object types raise an `Exception`. |
| `BATCH START`, `BATCH EXECUTE` | Collects the statements between them and runs them as a batch. Needs the `SUPPORT_IB2007` compiler define, which is off in `FIBPlus.inc`; without it `BATCH EXECUTE` raises an `Exception`. |
| `REINSERT` | Takes the text after `REINSERT` and appends it to the previous `INSERT` statement up to its `VALUES`, then runs the result. |
| `SET TERM` | Changes the terminator. Not executed. See [Terminators](#terminators). |
| `SET AUTODDL ON \| OFF` | Sets `AutoDDL`. |
| `SET SQL DIALECT n` | Sets the dialect used by the next `CONNECT` or `CREATE DATABASE`. |
| `SET NAMES cs` | Sets the character set used by the next `CONNECT`. |
| `SET CLIENTLIB 'lib'` | Sets the client library used by the next `CONNECT`, `CREATE DATABASE`, or `DROP DATABASE`. Without it, the database keeps its `LibraryName`. `Parse` clears it. |
| `SET BLOBFILE 'file'` | Sets the file that supplies BLOB parameters, see [BLOB files](#blob-files). |
| `{$...}` | A directive, see [Directives](#directives). |

The scripter sends everything else to the server, including DML, DDL, `GRANT`, `REVOKE`, `COMMENT`, `DECLARE`, `EXECUTE BLOCK`, `SET GENERATOR`, `SET STATISTICS`, and the session `SET` statements. Any other `SET` command is ignored: it is not run and raises no error.

The start of each top-level run resets the dialect to `3` and the character set to empty, so `SET SQL DIALECT` and `SET NAMES` last for one run. A run started from `INPUT` continues with the settings of the calling script.

### Session SET statements

A `SET` statement is sent to the server when the word after `SET` is one of `STATEMENT`, `SESSION`, `BIND`, `DECFLOAT`, `ROLE`, `TRUSTED`, `OPTIMIZE`, or `SEARCH_PATH`, or when it is `TIME ZONE`. Their type is `sSetSession`. Examples:

```sql
SET STATEMENT TIMEOUT 5000 MILLISECOND;
SET SESSION IDLE TIMEOUT 600 SECOND;
SET TIME ZONE 'Europe/Berlin';
```

The settings affect the attachment of the scripter's database. See [Timeouts](../guide/timeouts.md) for the timeout values and `Session.Apply` of [TFIBSession](TFIBSession.md).

## Terminators

The terminator ends a statement. It is `;` unless another one is passed to `Parse` or `ExecuteFromFile`, or the script changes it with `SET TERM`.

```sql
SET TERM ^ ;
CREATE PROCEDURE P AS
BEGIN
  EXECUTE STATEMENT 'DELETE FROM T';
END^
SET TERM ; ^
```

- `SET TERM <new> <current>` ends with the current terminator. The new terminator can be several characters long and can be the same as the current one. A `SET TERM` without a new terminator raises an `Exception`.
- The terminator is not case sensitive. A terminator made of letters is not recognized inside a word.
- With the `;` terminator, a `CREATE`, `ALTER`, `RECREATE`, or `CREATE OR ALTER` of a procedure, trigger, function, or package, and an `EXECUTE BLOCK`, end at the `;` after the final `END` of the body, so `SET TERM` is not needed for them. `EXTERNAL` modules have no body and end at the first `;`.
- A statement at the end of the script without a terminator is run.
- Comments (`--` and `/* */`), quoted strings, and `q'...'` strings do not end a statement. Several statements can share a line.

## Directives

A directive is written in braces and is a statement of its own. The scripter reads the directive when it runs, so a condition sees the objects that earlier statements created.

| Directive | Effect |
|-----------|--------|
| `{$DEFINE name}` / `{$UNDEF name}` | Add or remove a name (upper case). |
| `{$SET name = value}` | Set a constant for `{$IF}`. |
| `{$IFDEF name}`, `{$IFNDEF name}` | Run the block when the name is defined, or is not defined. |
| `{$IF name op value}` | Compare a constant with a value. The operators are `=`, `<>`, `>`, `<`, `>=`, `<=`. `=` and `<>` compare text; the others compare numbers. A constant that is not set raises an `Exception`. |
| `{$IFEXISTS type name}` | Run the block when the object exists. `{$IFNEXISTS}` and `{$IFNOTEXISTS}` do the reverse. The types are `DOMAIN`, `EXCEPTION`, `FUNCTION`, `GENERATOR`, `PROCEDURE`, `PACKAGE`, `ROLE`, `TABLE`, `TRIGGER`, `UDF`, `VIEW`. A name without quotes is converted to upper case. A `SELECT` statement can replace the type and name; the condition is true when it returns a row. |
| `{$ELSE}`, `{$ENDIF}` | End of the first branch, and end of the block. Blocks can be nested. |
| `{$EXECUTE_BLOCK ON}` / `{$EXECUTE_BLOCK OFF}` | Set `UseExecBlockForDML`. |

An unknown directive raises an `Exception`. `ExecuteScript` evaluates the conditions again when it starts from statement 1.

`PreparePreDefines` sets these values from the connected server, and clears them when there is no connection:

| Name | Kind | Value |
|------|------|-------|
| `IS_FIREBIRD` | define | Defined for a Firebird server. |
| `SERVER_MAJOR_VER`, `SERVER_MINOR_VER` | constant | Server version. |
| `ODS_MAJOR_VER`, `ODS_MINOR_VER` | constant | On-disk structure version of the database. |

```sql
{$IFDEF IS_FIREBIRD}
{$IF SERVER_MAJOR_VER >= 4}
SET STATEMENT TIMEOUT 10000;
{$ENDIF}
{$ENDIF}
```

## Error handling

`OnExecuteError` receives the number of the statement (`StatementNo`, 1-based), the line where it starts (`Line`), its text, and the SQL code and message of the `EFIBError`. Without a handler the exception propagates. Other exceptions, such as parse errors, always propagate. So does an `EFIBError` from `DROP DATABASE`, `DESCRIBE`, `RECONNECT`, `DISCONNECT`, an `{$IFEXISTS}` query, and the last `EXECUTE BLOCK` of [Grouping DML statements](#grouping-dml-statements).

| Parameter | Effect |
|-----------|--------|
| `DoRollBack` | `True` on entry for a statement sent to the server; the scripter rolls the transaction back after the handler returns when it is still `True`. The value is not set for `CONNECT`, `CREATE DATABASE`, and `COMMIT`, and is not used there. |
| `Stop` | `True` on entry. Leave it `True` to stop the run; set it to `False` to continue with the next statement. |

A failed `COMMIT` is rolled back after the handler returns.

## Pausing and resuming

`ExecuteScript` returns without an error when `Paused` is `True` before a statement: an error handler left `Stop` as `True`, or an event handler set `Paused`. `StopStatementNo` holds the number of the statement that did not run. After an error, that is the statement after the failed one. The value is set only when a statement follows: if the last statement fails or the last event pauses the run, `Paused` stays `True` but `StopStatementNo` is not updated, so do not resume from it. To resume, fix the cause and call `ExecuteScript(StopStatementNo)`. Conditions are not evaluated again when the start statement is greater than 1.

## BLOB files

After `SET BLOBFILE 'file'`, a statement parameter named `H<offset>_<length>`, with both numbers in hexadecimal, is filled with `<length>` bytes read from `<offset>` in the file. A length of `0` clears the parameter. The file is closed at the end of the run.

## Grouping DML statements

With `UseExecBlockForDML`, consecutive `INSERT`, `REINSERT`, `UPDATE`, `DELETE`, `MERGE`, and `EXECUTE` statements are collected into one `EXECUTE BLOCK`. A block holds at most 255 statements and about 64 K characters. Any other statement, such as `SELECT`, or a statement with BLOB file parameters, ends the block and runs it first. The last block runs at the end of the top-level run.

- A grouped statement raises no `AfterStatementExecute` event.
- A block runs when the next statement or the size limit closes it. `AfterStatementExecute` and `OnExecuteError` then report the statement that triggered the run, not the statement that failed.
- An error in the last block always propagates, and it raises no `AfterStatementExecute` event and does not apply `AutoDDL`.
- A statement longer than the block limit is not run correctly; do not group scripts with such statements.

## Types

| Name | Description |
|------|-------------|
| `TOnStatementExecute` | `procedure(Sender: TObject; Line: Integer; StatementNo: Integer; Desc: TStatementDesc; Statement: TStrings) of object`. `Line` is the 1-based line where the statement starts. |
| `TOnSQLScriptExecError` | `procedure(Sender: TObject; StatementNo: Integer; Line: Integer; Statement: TStrings; SQLCode: Integer; const Msg: string; var doRollBack: boolean; var Stop: boolean) of object` |
| `TStatementDesc` | Record: `smdBegin` and `smdEnd` (`TStmtCoord`, first and last character of the text, without the terminator), `smtType` (`TStmtType`), `objType` (`TObjectType`), `objName`, `DirectiveNum`, `DirectiveElse`. |
| `TStmtCoord` | Record `X`, `Y`: `X` is the 1-based position in the line, `Y` the 0-based line index. |
| `TStmtType` | Statement kind: `sUnknown`, `sInvalid`, `sDML`, `sConnect`, `sDisconnect`, `sReconnect`, `sCreateDatabase`, `sDropDatabase`, `sCommit`, `sRollBack`, `sCreate`, `sAlter`, `sRecreate`, `sDrop`, `sSet`, `sSetGenerator`, `sSetStatistics`, `sSetSession`, `sDescribe`, `sDeclare`, `sComment`, `sGrant`, `sRunFromFile`, `sBatchStart`, `sBatchExecute`, `sExecute`, `sInsert`, `sReinsert`, `sDirective`. `sBatch` is a temporary value of the parser. |
| `TObjectType` | Object named in the statement: `otNone`, `otDatabase`, `otDomain`, `otTable`, `otView`, `otProcedure`, `otTrigger`, `otUDF`, `otException`, `otGenerator`, `otIndex`, `otConstraint`, `otFilter`, `otField`, `otParameter`, `otRole`, `otBlock`, `otUser`, `otPackage`, `otPackageBody`, `otFunction`. |

`StatementTypeName(tn)` returns a display name for a `TStmtType`. Some names end with a blank, such as `'Create '`, and `sDirective`, `sBatchStart`, and `sBatchExecute` return `'Unknown'`.

## See also

- [TpFIBQuery](TpFIBQuery.md), [TpFIBDatabase](TpFIBDatabase.md), [TpFIBTransaction](TpFIBTransaction.md)
- [Scripting](../guide/scripting.md)
- [Timeouts](../guide/timeouts.md)
