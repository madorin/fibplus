# Scripting

`TpFIBScripter` runs an SQL script statement by statement. It splits the text into statements, handles `SET TERM`, executes the statements on the server, and reports errors through events. Use it for database creation and update scripts, and for scripts exported by other tools.

The examples use a `TpFIBDatabase` named `Database`, a `TpFIBTransaction` named `Transaction`, a `TpFIBScripter` named `Scripter`, and a `TMemo` named `LogMemo` on a form `TMainForm`. Member details are in the [TpFIBScripter reference](../reference/TpFIBScripter.md).

## Running a script

Assign the database and the transaction, put the text in `Script`, and call `ExecuteScript`:

```delphi
Scripter.Database := Database;
Scripter.Transaction := Transaction;
Scripter.Script.LoadFromFile('update.sql');
Scripter.ExecuteScript;
Transaction.Commit;
```

- The scripter has its own query (`Query`) and its own transaction. Set `Transaction` to run the script in a transaction of yours; otherwise the internal one is used.
- `ExecuteScript` parses the script when it is not parsed yet. Changing `Script` discards the parsed statements.
- The last statement runs even if it has no terminator.
- With an assigned `Database`, DML is not committed at the end of the run. Commit the transaction yourself, or put `COMMIT` in the script. When the script creates its own database with `CONNECT` or `CREATE DATABASE`, the scripter commits and releases that database at the end of the run.
- While `AutoDDL` is `True` (the default), the scripter commits the transaction after each DDL statement. That commit includes any DML that was not committed before. A script can switch it with `SET AUTODDL ON` and `SET AUTODDL OFF`.

To run a script from a file without loading it into `Script`, use `ExecuteFromFile`. It reads the file line by line and runs each statement as soon as it is complete, so large files do not need much memory:

```delphi
Scripter.ExecuteFromFile('C:\Scripts\data.sql');
Scripter.ExecuteFromFile('C:\Scripts\procs.sql', '^^'); // initial terminator
```

A script can include another one with `INPUT 'file'`, which runs `ExecuteFromFile` with the `;` terminator.

## Terminators and `SET TERM`

The default terminator is `;`. `SET TERM <new> <current>` changes it, as in `isql`. The `SET TERM` statement is not sent to the server.

```sql
SET TERM ^^ ;

CREATE PROCEDURE P_HELLO
AS
BEGIN
  EXECUTE PROCEDURE P_OTHER;
END^^

SET TERM ; ^^
```

- A terminator can have several characters. It is matched without regard to case. A terminator made of letters is not recognized inside a longer word.
- Terminators inside string literals (including `q'...'` literals), quoted identifiers, and comments (`--` and `/* */`) do not end a statement.
- Several statements can be on one line, and one statement can span many lines.
- While the terminator is `;`, the parser also follows the structure of `CREATE`, `ALTER`, `RECREATE`, and `CREATE OR ALTER` of a procedure, trigger, function, or package, and of `EXECUTE BLOCK`. A `;` inside the body does not end the statement; the statement ends at the `;` after the `END` of the body. A module declared `EXTERNAL` has no body and ends at the first `;`.
- `SET TERM` without a new terminator raises an exception while the script is parsed.

To start with another terminator, call `Parse` yourself before `ExecuteScript`:

```delphi
Scripter.Parse('^^');
Scripter.ExecuteScript;
```

See [Terminators](../reference/TpFIBScripter.md#terminators) in the reference.

## Statements the scripter handles

The scripter runs script-control statements such as `CONNECT`, `COMMIT`, `INPUT`, and `SET AUTODDL` itself and sends all other statements to the server through `Query`. [Statement handling](../reference/TpFIBScripter.md#statement-handling) in the reference lists which statement is handled how.

A script can connect by itself. Without an assigned `Database`, `CONNECT` creates an internal one:

```sql
SET SQL DIALECT 3;
SET NAMES UTF8;
CONNECT 'localhost:C:\Data\shop.fdb' USER 'SYSDBA' PASSWORD 'masterkey';
```

`SET SQL DIALECT` and `SET CLIENTLIB` take effect at the next `CONNECT` or `CREATE DATABASE` of the same run (`SET CLIENTLIB` also at `DROP DATABASE`). `SET NAMES` applies to `CONNECT` only, and to the reconnect after `CREATE DATABASE` when the script needs UTF-8 DDL. They do not change a database that is already connected. At the start of every run the dialect is reset to 3 and the character set to none.

### SET statements that go to the server

Session settings such as timeouts and the time zone are sent to the server, so a script can set up the session it runs in. The reference lists them in [Session SET statements](../reference/TpFIBScripter.md#session-set-statements). Write the unit in timeout statements:

```sql
SET STATEMENT TIMEOUT 60 SECOND;
```

The server must support the statement. For the timeouts, see [Timeouts](timeouts.md); after a script changes them, `Session.Apply` sends the values of the session properties again.

A `SET` statement that the scripter does not know is skipped without an error. Older versions of FibPlus also skipped the session settings, so an old script that contains them now runs them.

## Directives

A directive is written in braces, like a statement, and is not sent to the server. Directives let one script serve several databases: `{$DEFINE}`, `{$UNDEF}`, `{$IFDEF}`, `{$IFNDEF}`, `{$SET}`, `{$IF}`, `{$IFEXISTS}`, `{$IFNEXISTS}`, `{$IFNOTEXISTS}`, `{$ELSE}`, `{$ENDIF}`, and `{$EXECUTE_BLOCK}`. Conditions can be nested. The syntax of each one is in [Directives](../reference/TpFIBScripter.md#directives) in the reference.

```sql
{$IFNEXISTS TABLE CUSTOMER}
CREATE TABLE CUSTOMER (ID INTEGER NOT NULL PRIMARY KEY, NAME VARCHAR(60));
{$ENDIF}

{$IF SERVER_MAJOR_VER >= 4}
SET STATEMENT TIMEOUT 60 SECOND;
{$ENDIF}
```

When the scripter is connected, it defines `IS_FIREBIRD` when the server is Firebird, and sets the constants `SERVER_MAJOR_VER`, `SERVER_MINOR_VER`, `ODS_MAJOR_VER`, and `ODS_MINOR_VER`. They are refreshed at the start of a run, after `CONNECT`, and after `CREATE DATABASE`.

Fill `Defines` from code with `AddDefine` and `DeleteDefine` before a run to select branches. Names defined in a script stay in `Defines` after the run.

```delphi
Scripter.AddDefine('DEMO_DATA');
Scripter.ExecuteScript;
```

Pitfalls with directives:

- A condition that reads a server constant or checks an object needs a connected database when the run starts, or a `CONNECT` earlier in the script. Without a connection, `{$IF SERVER_MAJOR_VER ...}` raises an exception, and the `{$IFEXISTS}` family is neither true nor false: the statements of the `{$IFEXISTS}` branch are skipped and the `{$ELSE}` branch runs.
- Names and constants are not case sensitive, but the value in `{$IF NAME = value}` is compared as written.
- `{$IFEXISTS}` is true when the object exists or the `SELECT` returns a row. `{$IFNEXISTS}` and `{$IFNOTEXISTS}` are true when it does not exist or the `SELECT` returns no row.
- A directive that is not in the list raises an exception when it is reached. An `{$IF...}` without `{$ENDIF}` raises an exception when the script is parsed.

## Events and error handling

`BeforeStatementExecute` and `AfterStatementExecute` report each statement with its number and starting line, both counted from 1. `BeforeStatementExecute` is not called for a statement that a directive excludes. In its handler, set `Scripter.SkipStatement := True` to skip the statement. `AfterStatementExecute` is called only after a statement that was run through `Query`.

Without `OnExecuteError`, an `EFIBError` propagates out of `ExecuteScript`. With a handler, the scripter calls it when a statement sent to the server fails, and when `CONNECT`, `CREATE DATABASE`, `DROP DATABASE`, or `COMMIT` fails. An `EFIBError` from other statements, for example `DESCRIBE`, `RECONNECT`, or the query of an `{$IFEXISTS}` condition, still propagates.

The handler sets two parameters. `DoRollBack` starts as `True` and rolls back the scripter's transaction, so earlier uncommitted statements of that transaction are lost too. `Stop` starts as `True` and stops the run; set it to `False` to go on with the next statement.

```delphi
procedure TMainForm.ScripterExecuteError(Sender: TObject; StatementNo, Line: Integer;
  Statement: TStrings; SQLCode: Integer; const Msg: string; var DoRollBack, Stop: Boolean);
begin
  LogMemo.Lines.Add(Format('Statement %d, line %d: %s', [StatementNo, Line, Msg]));
  DoRollBack := False;
  Stop := False;
end;
```

After a stop, `Paused` is `True`. Fix the problem and continue with `ExecuteScript(Scripter.StopStatementNo)`, which is the number of the statement after the one that failed. `ExecuteFromFile` cannot be continued; after a stop, the file is closed and the call returns.

Syntax errors in the script (`SET TERM` without a terminator, an unknown directive, an unclosed `{$IF}`) raise ordinary exceptions, not through `OnExecuteError`.

## Many INSERT statements

Set `UseExecBlockForDML` to `True`, or put `{$EXECUTE_BLOCK ON}` in the script, to send consecutive `INSERT` and other DML statements to the server in `EXECUTE BLOCK` groups. A group holds at most 255 statements and about 64 KB of text. A group is sent when it is full, when a statement of another kind follows, and at the end of the run. `EXECUTE BLOCK` and `EXECUTE PROCEDURE` statements are not grouped. See [Grouping DML statements](../reference/TpFIBScripter.md#grouping-dml-statements).

`BeforeStatementExecute` is still called for every statement, but `AfterStatementExecute` is called once per group, with the number of its last statement.

## Inspecting a script

`Parse` splits the script without running it. `StatementsCount` and `GetStatement` give access to the result:

```delphi
var
  I: Integer;
  Text: TStrings;
  Desc: PStatementDesc;
begin
  Text := TStringList.Create;
  try
    Scripter.Parse;
    for I := 1 to Scripter.StatementsCount do
    begin
      Desc := Scripter.GetStatement(I, Text);
      LogMemo.Lines.Add(StatementTypeName(Desc.smtType) + ': ' + Text[0]);
    end;
  finally
    Text.Free;
  end;
end;
```

## See also

- [TpFIBScripter reference](../reference/TpFIBScripter.md)
- [TpFIBDatabase](../reference/TpFIBDatabase.md), [TpFIBTransaction](../reference/TpFIBTransaction.md)
- [Timeouts](timeouts.md)
- [Transactions](transactions.md)
