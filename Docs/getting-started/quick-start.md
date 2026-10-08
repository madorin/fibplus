# Quick start

Connect to a database, run a first query, and show data in a grid. The steps use the `EMPLOYEE` demo database that ships with Firebird and the components `TpFIBDatabase`, `TpFIBTransaction`, `TpFIBQuery`, and `TpFIBDataSet`.

You need:

- FibPlus installed in the IDE, see [Installation](../../README.md#-installation). The components are on the **FIBPlus** page of the Tool Palette.
- A running Firebird server and its client library. FibPlus loads `fbclient.dll` by default on Windows; put it next to the program or set `LibraryName` to its path.
- A VCL application with an empty form.

## 1. Connect

1. Drop a `TpFIBDatabase` and a `TpFIBTransaction` on the form. The names below are `Database` and `Transaction`.
2. Set the properties of `Database`:

   | Property | Value |
   |----------|-------|
   | `DBName` | `localhost:C:\Data\EMPLOYEE.FDB`, the server and the path of the database file on the server |
   | `DBParams` | `user_name=SYSDBA`, `password=masterkey` and `lc_ctype=UTF8`, one per line |
   | `SQLDialect` | `3` |
   | `DefaultTransaction` | `Transaction` |
   | `DefaultUpdateTransaction` | `Transaction` |

3. Set `Transaction.DefaultDatabase` to `Database`.
4. Connect from code, for example in `OnCreate` of the form:

   ```delphi
   procedure TForm1.FormCreate(Sender: TObject);
   begin
     Database.Connected := True;
   end;
   ```

   You can set the same values in code instead of the Object Inspector:

   ```delphi
   Database.DBName := 'localhost:C:\Data\EMPLOYEE.FDB';
   Database.ConnectParams.UserName := 'SYSDBA';
   Database.ConnectParams.Password := 'masterkey';
   Database.ConnectParams.CharSet := 'UTF8';
   ```

   Set the character set to the one your data needs. With `NONE`, text is not converted. See [TFIBDatabase](../reference/TFIBDatabase.md) for `DBParams`, `ConnectParams`, and the other connection properties.

`Database.Connected := True` raises an exception when the connection fails. With `Database.Open(False)`, a failed attach does not raise; check `Connected` afterwards.

## 2. Run a query

Drop a `TpFIBQuery` (`Query`) and a `TMemo` (`Memo1`) on the form and set its `Database` to `Database` and its `Transaction` to `Transaction`.

A query does not start its transaction unless `qoStartTransaction` is in its `Options`, so start it yourself:

```delphi
procedure TForm1.ShowDepartmentEmployees;
begin
  Transaction.StartTransaction;
  try
    Query.SQL.Text := 'SELECT FIRST_NAME, LAST_NAME FROM EMPLOYEE WHERE DEPT_NO = :DeptNo';
    Query.Params.ByName['DeptNo'].AsString := '600';
    Query.ExecQuery;
    try
      while not Query.Eof do
      begin
        Memo1.Lines.Add(Query.FN('FIRST_NAME').AsString + ' ' + Query.FN('LAST_NAME').AsString);
        Query.Next;
      end;
    finally
      Query.Close;
    end;
  finally
    Transaction.Commit;
  end;
end;
```

`ExecQuery` of a `SELECT` opens a cursor and fetches the first row. `Next` fetches the next row. Close the cursor before the transaction ends. Statements that change data work the same way: use `ExecQuery` and commit the transaction when the change is complete. See [TFIBQuery](../reference/TFIBQuery.md) for the members and [Queries and parameters](../guide/queries-and-parameters.md) for the scenarios.

## 3. Show data in a dataset

1. Drop a `TpFIBDataSet` (`DataSet`), a `TDataSource`, and a `TDBGrid` on the form.
2. Set the properties of `DataSet`:

   | Property | Value |
   |----------|-------|
   | `Database` | `Database` |
   | `Transaction` | `Transaction` |
   | `UpdateTransaction` | `Transaction` |
   | `SelectSQL` | `SELECT EMP_NO, FIRST_NAME, LAST_NAME, SALARY FROM EMPLOYEE ORDER BY LAST_NAME` |

3. Set `DataSource.DataSet` to `DataSet` and `DBGrid.DataSource` to `DataSource`.
4. Open the dataset after connecting. Add `DataSet.Open;` to `FormCreate` from step 1:

   ```delphi
   procedure TForm1.FormCreate(Sender: TObject);
   begin
     Database.Connected := True;
     DataSet.Open;
   end;
   ```

   `poStartTransaction` is in `Options` by default, so the dataset starts `Transaction` when it opens. Change `Options` in the Object Inspector to turn it off.

The grid shows the rows. The grid is read-only until the dataset has `InsertSQL`, `UpdateSQL`, and `DeleteSQL`. Fill them in the Object Inspector, or set `AutoUpdateOptions.UpdateTableName`, `AutoUpdateOptions.KeyFields`, and `AutoUpdateOptions.AutoReWriteSqls` to `True` so that the dataset generates them when it opens, see [TpFIBDataSet](../reference/TpFIBDataSet.md#autoupdateoptions). The `DataSetBasic` sample in `Samples\src` shows a dataset with all four statements filled in.

The dataset sends changes to the server with `UpdateTransaction`. They become permanent only when that transaction is committed. Either commit it in your code or set `AutoCommit` to `True`:

```delphi
DataSet.AutoCommit := True;
```

See [TFIBDataSet](../reference/TFIBDataSet.md) and [TpFIBDataSet](../reference/TpFIBDataSet.md) for the members, and [Datasets and caching](../guide/datasets-and-caching.md) for editing scenarios.

## Next steps

- [Transactions](../guide/transactions.md)
- [Reference](../reference/README.md)
