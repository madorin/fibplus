# BLOBs and arrays

A BLOB column holds binary or text data of any size. An array column holds a fixed-size, multi-dimensional list of values of one type. FibPlus reads and writes both through `TFIBQuery`, `TFIBDataSet`, and the field classes of a dataset. This article shows how, and how text BLOBs are decoded.

## Requirements and limits

- Array support is compiled in by default (`SUPPORT_ARRAY_FIELD` in `FIBPlus.inc`). Without it, the array members in this article do not exist.
- A BLOB or array is read and written in the transaction of its query or dataset. That transaction must be active, or the query must have `qoStartTransaction` in `Options`.

## BLOB basics

A BLOB column has a *subtype*. Subtype `1` is text. Other subtypes are binary. A negative subtype is user-defined and can have a [filter](#blob-filters).

| Subtype | `TFIBDataSet` field class | Data type |
|---------|---------------------------|-----------|
| `1`, or a subtype listed in `TFIBDatabase.MemoSubtypes` | `TFIBMemoField` | `ftMemo`, or `ftWideMemo` (*Delphi 2007+*) on a Unicode connection with a Unicode column character set, *Firebird 2.1+* |
| any other | `TFIBBlobField` | `ftBlob` |

A BLOB value does not travel with the row. The row carries a BLOB ID, and the content is read from the server when you ask for it.

## Query parameters and columns

Use `TFIBXSQLVAR` members on `Params` and on result columns. In the samples, `Query` is a `TFIBQuery`, `Stream` a `TStream`, `Database` a `TFIBDatabase`, and `DataSet` a `TFIBDataSet`. See [TFIBQuery](../reference/TFIBQuery.md) for the query itself.

### Write a BLOB from a stream

`LoadFromStream` copies the stream into the parameter. The BLOB is created on the server when the statement runs.

```delphi
Query.SQL.Text := 'INSERT INTO DOCUMENT (ID, BODY) VALUES (:ID, :BODY)';
Query.ParamByName('ID').AsInteger := 1;
Query.ParamByName('BODY').LoadFromStream(Stream);
Query.ExecQuery;
```

### Write a BLOB from a file

`LoadFromFile` has two overloads.

- `LoadFromFile(FileName)` reads the whole file into memory and works like `LoadFromStream`: the BLOB is created when the statement runs.
- `LoadFromFile(FileName, Callback)` creates the BLOB on the server at once, in the transaction of the query, and sets the parameter to its ID. The file is read in chunks. `Callback` is a `TCallBackBlobReadWrite` that gets the progress and can stop the transfer.

```delphi
Query.ParamByName('BODY').LoadFromFile('D:\Data\report.pdf');
Query.ExecQuery;
```

For a large file, use the overload with a callback:

```delphi
procedure TMainForm.FileProgress(BlobSize: Integer; BytesProcessing: Integer; var Stop: Boolean);
begin
  Stop := Cancelled;
end;

Query.ParamByName('BODY').LoadFromFile('D:\Data\big.iso', FileProgress);
Query.ExecQuery;
```

`Cancelled` is a `Boolean` field of the form.

### Read a BLOB into a stream or a file

```delphi
Query.SQL.Text := 'SELECT BODY FROM DOCUMENT WHERE ID = :ID';
Query.ParamByName('ID').AsInteger := 1;
Query.ExecQuery;
try
  Query.FN('BODY').SaveToStream(Stream);
finally
  Query.Close;
end;
```

`SaveToFile(FileName, Callback)` writes the BLOB to a file in chunks and reports progress. When a [filter](#blob-filters) exists for the subtype, `SaveToFile` goes through a stream instead, so the filter is applied. `SaveToFileStream(FileName)` always uses a stream.

### Read a text BLOB as a string

For a text BLOB, `AsString`, `AsWideString`, and `AsAnsiString` return the content. `AsVariant` and `Value` return the same text, so do not use them for binary BLOBs.

Setting `AsString` on a parameter works the same way for BLOB parameters. A string longer than 32767 bytes is sent as a BLOB even when the parameter type is not yet known.

`AsString` returns `(BLOB)` instead of raising an error when the content cannot be read, for example when the transaction is not active. It also returns `(BLOB)` for a parameter that holds no stream.

### Code pages of text BLOBs

The server stores a text BLOB in the character set of its column. FibPlus converts between that set and Delphi strings when you use the string properties. The code page comes from `Database.Capabilities.BlobCodePage` for the character set of the column. A BLOB of another subtype is handled in the system code page.

- On *Firebird 2.1+*, `BlobCodePage` returns the same code page as `TextCodePage` for that character set.
- On older servers and on InterBase it returns UTF-8 for Unicode character sets, and the system code page for the others.

For connection and character set settings, see [Connections](connections.md).

## Datasets

A dataset keeps the value of a BLOB or array field on the client until `Post`. `Cancel` discards a change, and `CachedUpdates` works with BLOB and array fields.

### Edit a BLOB field

Use the standard `TBlobField` and `TMemoField` members. The field must be in edit or insert state to write.

```delphi
DataSet.Edit;
TBlobField(DataSet.FieldByName('BODY')).LoadFromFile('D:\Data\report.pdf');
DataSet.Post;
```

`CreateBlobStream(Field, Mode)` returns a stream for a BLOB or array value. Use it when you need `Seek` or partial reads.

`BlobModified(Field)` tells whether the BLOB of the current row has changed.

A memo field returns and accepts text through `AsString`, `AsWideString`, and `AsVariant`. The text is converted with the code page from `BlobFieldCodePage(Field)`, see [Code pages of text BLOBs](#code-pages-of-text-blobs). When that is the system code page and the column has a Unicode character set, the memo field uses UTF-8.

### Progress and cancel

`OnReadBlobField` and `OnWriteBlobField` report `BlobSize` and `Progress` during a BLOB transfer. Set `Stop` to `True` to cancel.

### Computed BLOB fields

A `TFIBBlobField` with `IsClientField` set to `True` is not read from the server. Fill it in `OnFillClientBlob`, which receives a `TFIBBlobStream`. The field is read-only for the user.

### Memory and swap files

- `CacheModelOptions.BlobCacheLimit` limits how many BLOB streams stay in memory. `0` means no limit.
- `TFIBDatabase.BlobSwapSupport` stores BLOB values in files and reads them from there. `BeforeSaveBlobToSwap` and `BeforeLoadBlobFromSwap` let you change or skip the file.

Both are described in [TFIBDataSet](../reference/TFIBDataSet.md) and [TFIBDatabase](../reference/TFIBDatabase.md).

## Arrays

An array column is declared with bounds, for example:

```sql
CREATE TABLE ITEM (
  ID INTEGER NOT NULL PRIMARY KEY,
  PRICES DOUBLE PRECISION [1:3],
  NAMES VARCHAR(20) [0:1, 1:2]
);
```

A value is a Delphi variant array. Its dimensions follow the column: one variant array dimension per column dimension, in the order of the column, with the bounds of the column. Elements are converted to the type of the column (`ElementType`).

| Column element | `ElementType` |
|----------------|---------------|
| `CHAR`, `VARCHAR` | `ftString` |
| `SMALLINT` | `ftSmallint`, or `ftBCD` with a scale |
| `INTEGER` | `ftInteger`, or `ftBCD` with a scale |
| `BIGINT` | `ftLargeint`, or `ftBCD` with a scale |
| `INT128`, `DECFLOAT(16)`, `DECFLOAT(34)` (*Firebird 4+*) | `ftFMTBcd` |
| `FLOAT`, `DOUBLE PRECISION` | `ftFloat` |
| `TIMESTAMP` | `ftDateTime` |
| `DATE` | `ftDate` |
| `TIME` | `ftTime` |
| `BOOLEAN` (*Firebird 3+*) | `ftBoolean` |

Elements of `TIME WITH TIME ZONE` and `TIMESTAMP WITH TIME ZONE` (*Firebird 4+*) are transferred as local time in the session time zone.

Other element types (for example `BLOB`) are not supported and raise an error.

### Describe an array

`TFIBXSQLVAR` and `TFIBArrayField` give `DimensionCount`, `ElementType`, `Dimension[Index]`, and `ArraySize`. `Dimension` uses a zero-based index and returns the lower and upper bound (`array_bound_lower`, `array_bound_upper`). `ArraySize` is the size of the whole array in bytes. `Dimension` raises an error for an index outside `0..DimensionCount - 1`, and when a bound does not fit 16 bits.

Reading these on a `TFIBXSQLVAR` that is not an array raises an error.

### Read an array from a query

`AsVariant` (and `Value`) of an array column returns the whole array as a variant array, or `Null` when the column is null. `GetArrayElement` reads one element without fetching the rest.

```delphi
Query.SQL.Text := 'SELECT PRICES FROM ITEM WHERE ID = :ID';
Query.ParamByName('ID').AsInteger := 1;
Query.ExecQuery;
try
  Prices := Query.FN('PRICES').AsVariant;
  First := Query.FN('PRICES').GetArrayElement([1]);
finally
  Query.Close;
end;
```

`Prices` and `First` are `Variant` variables. `AsString` of an array column returns `(ARRAY)`.

### Write an array from a query

Assign a variant array to the parameter that is bound to the array column. The array is created on the server when the statement runs.

```delphi
// Prices is a Variant
Prices := VarArrayCreate([1, 3], varVariant);
Prices[1] := 9.5;
Prices[2] := 12;
Prices[3] := 20.25;
Query.SQL.Text := 'UPDATE ITEM SET PRICES = :PRICES WHERE ID = :ID';
Query.ParamByName('PRICES').AsVariant := Prices;
Query.ParamByName('ID').AsInteger := 1;
Query.ExecQuery;
```

A parameter that the server does not describe as an array raises an error when the statement runs.

### Arrays in a dataset

`TFIBDataSet` has methods for array fields, see [Arrays](../reference/TFIBDataSet.md#arrays). Writes need edit or insert state.

```delphi
Field := DataSet.FieldByName('PRICES');
Prices := DataSet.ArrayFieldValue(Field);
DataSet.Edit;
DataSet.SetArrayElementValue(Field, 11.5, [2]);
DataSet.Post;
```

`Field` is a `TField` and `Prices` a `Variant`. To clear the array, call `SetArrayValue(Field, Null)`.

### Rules for array values

- The value must be a variant array with the same number of dimensions as the column.
- The first dimension can be shorter than the column. Every other dimension must have exactly the number of elements of the column. Elements that are missing are written as blank (zero, or spaces for `CHAR`; `#0` for `CHAR` of `OCTETS`).
- A longer value raises an error.
- Array elements cannot be `NULL`. A `Null` or empty element is stored as zero, or as spaces for `CHAR` (`#0` for `OCTETS`).
- A string longer than the element length in bytes raises an error. `CHAR` elements are padded, and trailing blanks are removed when you read them (except for `OCTETS`).
- A number that does not fit the element type or scale raises an error.
- String elements use the connection character set. On a `NONE` connection, and for `NONE` and `OCTETS` columns, they use the character set of the column. See [Connections](connections.md).

## BLOB filters

A filter changes the bytes of a BLOB of one user-defined subtype when FibPlus reads or writes it. Register the filter on the database.

```delphi
procedure EncodeNote(var BlobBuffer; var BlobSize: LongInt);
begin
  // BlobBuffer is the PAnsiChar variable that holds the data pointer: PPAnsiChar(@BlobBuffer)^
  // To change the length, ReallocMem that pointer and set BlobSize
end;

procedure DecodeNote(var BlobBuffer; var BlobSize: LongInt);
begin
  // reverse the change of EncodeNote
end;

Database.RegisterBlobFilter(-100, PIBBlobFilterProc(@EncodeNote), PIBBlobFilterProc(@DecodeNote));
```

- The unit `IBBlobFilter` declares `TIBBlobFilterProc` and `PIBBlobFilterProc`.
- The procedure receives the address of the buffer pointer, not of the data. The library allocates the buffer with the Delphi memory manager and frees it after use, so a filter that changes the length must reallocate it with `ReallocMem` and set `BlobSize`.
- `EncodeProc` runs when the BLOB is written to the server, `DecodeProc` when it is read.
- A filter applies only to negative subtypes and to BLOBs that are not empty. Registering a subtype again replaces its procedures.
- `RemoveBlobFilter(BlobSubType)` removes the filter.
- Filters belong to a `TFIBDatabase` and are not stored with the component. Register them in code after creating or loading the database component.

## Pitfalls

- `AsVariant` of a binary BLOB returns text. Use `SaveToStream` for binary data.
- `AsString` hides read errors by returning `(BLOB)`. Check that the transaction is active before you read.
- `LoadFromFile(FileName, Callback)` on a parameter writes the BLOB at once. `LoadFromFile(FileName)` and `LoadFromStream` wait for `ExecQuery`.
- A data-aware grid shows `(ARRAY)` for an array field, or `(Array)` when it is null. Edit arrays through the methods above.
- `CanCloneFromDataSet` is `False` for datasets with `ftBlob` or `ftBytes` fields, see [TFIBDataSet](../reference/TFIBDataSet.md).

## See also

- [TFIBQuery](../reference/TFIBQuery.md), [TFIBDataSet](../reference/TFIBDataSet.md), [TFIBDatabase](../reference/TFIBDatabase.md)
- [Queries and parameters](queries-and-parameters.md)
- [Datasets and caching](datasets-and-caching.md)
- [Connections](connections.md)
