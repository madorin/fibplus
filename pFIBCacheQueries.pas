{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ InterBase databases                                           }
{                                                               }
{    FIBPlus is based in part on the product                    }
{    Free IB Components, written by Gregory H. Deatz for        }
{    Hoagland, Longo, Moran, Dunst & Doukas Company.            }
{    mailto:gdeatz@hlmdd.com                                    }
{                                                               }
{    Copyright (c) 1998-2007 Devrace Ltd.                       }
{    Written by Serge Buzadzhy (buzz@devrace.com)               }
{                                                               }
{ ------------------------------------------------------------- }
{    FIBPlus home page: http://www.fibplus.com/                 }
{    FIBPlus support  : http://www.devrace.com/support/         }
{ ------------------------------------------------------------- }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}


unit pFIBCacheQueries;

interface

{$I FIBPlus.inc}
 uses
  SysUtils,Classes,FIBQuery,FIBDatabase,SyncObjs;

function  GetQueryForUse(aTransaction:TFIBTransaction; const SQLText:string):TFIBQuery;
procedure FreeQueryForUse(aFIBQuery:TFIBQuery);
procedure FreeHandleCachedQuery(DB:TFIBDataBase;const SQLText:string);
procedure ClearQueryCacheList(DB:TFIBDataBase);

implementation

 uses
 {$IFDEF D_XE3}
  System.Types, // for inline funcs
 {$ENDIF}
  SqlTxtRtns,pFIBLists,StrUtil;

 type

      TCacheQueries=class(TComponent)
      private
       FFIBDataBase:TFIBDataBase;
       FListUnused :TObjStringList;
       FListUsed   :TList;
       vInClear    :boolean;
       procedure   Clear;
       procedure   ClearUnused;
       function    UseQuery(aTransaction:TFIBTransaction;
                    const SQLText:string
                   ):TFIBQuery;
       procedure   UnUseQuery(aFIBQuery:TFIBQuery);
      protected
       procedure   Notification(AComponent: TComponent; Operation: TOperation);override;
      public
       constructor Create(aFIBDataBase:TFIBDataBase); reintroduce;
       destructor  Destroy; override;
      end;


      TCacheList =class(TComponent)
      private
       FList:TList;
       FLock: TCriticalSection;
       function    FindCacheForDB(aDataBase:TFIBDatabase):TCacheQueries;
       function    GetCacheForDB(aDataBase:TFIBDatabase):TCacheQueries;
       procedure   RemoveDataBase(aDataBase:TFIBDatabase);
      protected
       procedure   Notification(AComponent: TComponent; Operation: TOperation);override;
      public
       constructor Create(AOwner:TComponent);override;
       destructor  Destroy; override;

       function  UseQuery(aTransaction:TFIBTransaction;  const SQLText:string):TFIBQuery;
       procedure UnUseQuery(aFIBQuery:TFIBQuery);
       procedure FreeUnusedQueries;
      end;


var
 CacheList:TCacheList;

{ TCacheQueries }

procedure TCacheQueries.Clear;
var i:integer;
begin
  try
   vInClear := true;
   with FListUsed do
   for i := 0 to Pred(Count) do
     TObject(FListUsed[i]).Free;
  finally
   vInClear := false;  
  end;
end;

constructor TCacheQueries.Create(aFIBDataBase:TFIBDataBase);
begin
  inherited Create(nil);
  FFIBDataBase:=aFIBDataBase;
  FListUnused :=TObjStringList.Create(nil,true);
  FListUsed   :=TList.Create;
end;

destructor TCacheQueries.Destroy;
begin
  Clear;
  try
   vInClear := true;
   FListUnused.Free;
  finally
   vInClear := false;
  end;
  FListUsed.Free;
  inherited;
end;


procedure TCacheQueries.ClearUnused;
var
  I: Integer;
  Query: TObject;
begin
  for I := FListUnused.Count - 1 downto 0 do
  begin
    Query := FListUnused.Objects[I];
    // Removed before Free: if Free raises, no freed query stays in the list
    FListUnused.Delete(I);
    Query.Free;
  end;
end;

procedure TCacheQueries.Notification(AComponent: TComponent;
  Operation: TOperation);
var
  I: Integer;
begin
  if (Operation = opRemove) and (AComponent is TFIBQuery) then
  begin
    // A cached query may be freed by its user, outside of the cache lock.
    // vInClear is set under the lock too.
    CacheList.FLock.Acquire;
    try
      if not vInClear then
      begin
        FListUsed.Remove(AComponent);
        // By object, not by SQL text: an unused query with the same text
        // may be in the list
        I := FListUnused.IndexOfObject(AComponent);
        if I >= 0 then
          FListUnused.Delete(I);
      end;
    finally
      CacheList.FLock.Release;
    end;
  end;
  inherited;
end;

procedure TCacheQueries.UnUseQuery(aFIBQuery: TFIBQuery);
var
  I: Integer;
  Key: string;
begin
  I := FListUsed.IndexOf(aFIBQuery);
  if I < 0 then
    Exit;
  FListUsed.Delete(I);

  Key := FastTrim(aFIBQuery.SQL.Text);
  // Two queries with the same SQL were in use at the same time, the list
  // keeps one query per SQL text
  if FListUnused.Find(Key, I) then
    aFIBQuery.Free
  else
    FListUnused.AddObject(Key, aFIBQuery);
end;

function TCacheQueries.UseQuery(
  aTransaction: TFIBTransaction; const SQLText: string
): TFIBQuery;
var i:integer;
begin
 if FListUnused.Find(FastTrim(SQLText),i) then
 begin
  Result:=TFIBQuery(FListUnused.Objects[i]);
  if Result.Transaction<>aTransaction then
   Result.Transaction:=aTransaction;
  FListUsed.Add(Result);
  FListUnused.Delete(i)
 end
 else
 begin
   Result:=TFIBQuery.Create(nil);
   Result.FreeNotification(Self);
   with Result do
   begin
     DataBase:=FFIBDataBase;
     Transaction:=aTransaction;
     SQl.Text :=SQlText;
     FListUsed.Add(Result);
   end;    
 end;
end;

{ TCacheList }

constructor TCacheList.Create(AOwner: TComponent);
begin
  inherited;
  FList:=TList.Create;
  FLock:=TCriticalSection.Create
end;

destructor TCacheList.Destroy;
var
  i:integer;
begin
  FLock.Acquire;
  try
   with FList do
    for i := 0 to Pred(Count) do  TObject(FList[i]).Free;
    FList.Free;
   inherited;
  finally
    FLock.Release;
    FLock.Free
  end
end;

function TCacheList.FindCacheForDB(aDataBase: TFIBDatabase): TCacheQueries;
var
  I: Integer;
begin
  FLock.Acquire;
  try
    for I := 0 to FList.Count - 1 do
    begin
      Result := TCacheQueries(FList[I]);
      if Result.FFIBDataBase = aDataBase then
        Exit;
    end;
    Result := nil;
  finally
    FLock.Release;
  end;
end;

function TCacheList.GetCacheForDB(aDataBase: TFIBDatabase): TCacheQueries;
begin
  FLock.Acquire;
  try
    Result := FindCacheForDB(aDataBase);
    if Result = nil then
    begin
      // The cache is freed in Notification when the database is destroyed
      aDataBase.FreeNotification(Self);
      Result := TCacheQueries.Create(aDataBase);
      FList.Add(Result);
    end;
  finally
    FLock.Release;
  end;
end;

procedure TCacheList.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
 if (Operation=opRemove)and (AComponent is TFIBDatabase) then
  RemoveDataBase(TFIBDatabase(AComponent));
 inherited;
end;

procedure TCacheList.RemoveDataBase(aDataBase: TFIBDatabase);
var i:integer;
begin
 FLock.Acquire;
 try
   with FList do
   for i := Pred(Count) downto 0 do
   if TCacheQueries(FList[i]).FFIBDataBase=aDataBase then
   begin
    TCacheQueries(FList[i]).Free;
    Delete(i)
   end;
 finally
   FLock.Release
 end
end;

procedure TCacheList.UnUseQuery(aFIBQuery: TFIBQuery);
var
  Cache: TCacheQueries;
begin
  if (aFIBQuery = nil) or (aFIBQuery.Database = nil) then
    Exit;
  FLock.Acquire;
  try
    // No cache for the database: the query doesn't come from the cache
    Cache := FindCacheForDB(aFIBQuery.Database);
    if Cache <> nil then
      Cache.UnUseQuery(aFIBQuery);
  finally
    FLock.Release;
  end;
end;


function TCacheList.UseQuery(aTransaction: TFIBTransaction;
  const SQLText: string): TFIBQuery;
var
  DB: TFIBDatabase;
begin
  Result := nil;
  if aTransaction = nil then
    Exit;
  DB := aTransaction.DefaultDatabase;
  if DB = nil then
  begin
    if aTransaction.DatabaseCount <> 1 then
      Exit;
    DB := aTransaction.Databases[0];
  end;

  FLock.Acquire;
  try
    Result := GetCacheForDB(DB).UseQuery(aTransaction, SQLText);
  finally
    FLock.Release;
  end;
end;


procedure TCacheList.FreeUnusedQueries;
var
  I: Integer;
begin
  FLock.Acquire;
  try
    for I := 0 to FList.Count - 1 do
      TCacheQueries(FList[I]).ClearUnused;
  finally
    FLock.Release;
  end;
end;

// interface
function
 GetQueryForUse(aTransaction:TFIBTransaction; const SQLText:string):TFIBQuery;
begin
 Result:=CacheList.UseQuery(aTransaction,SQLText);
 if (Result<>nil)  and Result.Open then Result.Close;
end;

procedure FreeQueryForUse(aFIBQuery:TFIBQuery);
begin
  if aFIBQuery.Open then
   aFIBQuery.Close;
  CacheList.UnUseQuery(aFIBQuery)
end;

procedure FreeHandleCachedQuery(DB: TFIBDataBase; const SQLText: string);
var
  Cache: TCacheQueries;
  I: Integer;
begin
  CacheList.FLock.Acquire;
  try
    Cache := CacheList.FindCacheForDB(DB);
    if (Cache <> nil) and Cache.FListUnused.Find(FastTrim(SQLText), I) then
      TFIBQuery(Cache.FListUnused.Objects[I]).FreeHandle;
  finally
    CacheList.FLock.Release;
  end;
end;

procedure ClearQueryCacheList(DB: TFIBDataBase);
var
  Cache: TCacheQueries;
begin
  CacheList.FLock.Acquire;
  try
    Cache := CacheList.FindCacheForDB(DB);
    if Cache <> nil then
      Cache.ClearUnused;
  finally
    CacheList.FLock.Release;
  end;
end;

initialization
 CacheList:=TCacheList.Create(nil);
finalization
 CacheList.Free;
end.


