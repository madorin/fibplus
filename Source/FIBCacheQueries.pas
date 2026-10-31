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
{    Written by Serge Buzadzhy                                  }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit FIBCacheQueries;

interface

{$I FIB.inc}

uses
  SysUtils, Classes, FIBQuery, FIBDatabase, SyncObjs;

function GetQueryForUse(aTransaction: TFIBTransaction; const SQLText: string): TFIBQuery; overload;
function GetQueryForUse(Database: TFIBDataBase; Transaction: TFIBTransaction; const SQLText: string): TFIBQuery; overload;
procedure FreeQueryForUse(aFIBQuery: TFIBQuery);
procedure FreeHandleCachedQuery(DB: TFIBDataBase; const SQLText: string);
procedure ClearQueryCacheList(DB: TFIBDataBase);

implementation

uses
{$IFDEF C24}
  System.Types, // for inline funcs
{$ENDIF}
  SqlTxtRtns, FIBLists, FIBPlatforms, StrUtil;

type

  TFIBQueryCache = class(TComponent)
  private
    FFIBDataBase: TFIBDataBase;
    FListUnused: TFIBObjectStringList;
    FListUsed: TList;
    FInClear: Boolean;
    procedure Clear;
    procedure ClearUnused;
    function UseQuery(aTransaction: TFIBTransaction; const SQLText: string): TFIBQuery;
    procedure UnUseQuery(aFIBQuery: TFIBQuery);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(aFIBDataBase: TFIBDataBase); reintroduce;
    destructor Destroy; override;
  end;

  TFIBQueryCacheList = class(TComponent)
  private
    FList: TList;
    FLock: TCriticalSection;
    function FindCacheForDB(aDataBase: TFIBDataBase): TFIBQueryCache;
    function GetCacheForDB(aDataBase: TFIBDataBase): TFIBQueryCache;
    procedure RemoveDataBase(aDataBase: TFIBDataBase);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function UseQuery(aTransaction: TFIBTransaction; const SQLText: string): TFIBQuery; overload;
    function UseQuery(Database: TFIBDataBase; Transaction: TFIBTransaction; const SQLText: string): TFIBQuery; overload;
    procedure UnUseQuery(aFIBQuery: TFIBQuery);
  end;

var
  CacheList: TFIBQueryCacheList;

// The text as SQL.Text of the query gives it: CRLF line breaks
function CacheKey(const SQLText: string): string;
begin
  Result := FastTrim(AdjustLineBreaks(SQLText));
end;

  { TFIBQueryCache }

procedure TFIBQueryCache.Clear;
var
  i: TFIBListIndex;
begin
  try
    FInClear := true;
    for i := 0 to FListUsed.Count - 1 do
      TObject(FListUsed[i]).Free;
  finally
    FInClear := false;
  end;
end;

constructor TFIBQueryCache.Create(aFIBDataBase: TFIBDataBase);
begin
  inherited Create(nil);
  FFIBDataBase := aFIBDataBase;
  FListUnused := TFIBObjectStringList.Create(nil, true);
  FListUsed := TList.Create;
end;

destructor TFIBQueryCache.Destroy;
begin
  Clear;
  try
    FInClear := true;
    FListUnused.Free;
  finally
    FInClear := false;
  end;
  FListUsed.Free;
  inherited;
end;

procedure TFIBQueryCache.ClearUnused;
var
  i: Integer;
  Query: TObject;
begin
  for i := FListUnused.Count - 1 downto 0 do
  begin
    Query := FListUnused.Objects[i];
    // Removed before Free: if Free raises, no freed query stays in the list
    FListUnused.Delete(i);
    Query.Free;
  end;
end;

procedure TFIBQueryCache.Notification(AComponent: TComponent; Operation: TOperation);
var
  i: Integer;
begin
  if (Operation = opRemove) and (AComponent is TFIBQuery) then
  begin
    // A cached query may be freed by its user, outside of the cache lock.
    // FInClear is set under the lock too.
    CacheList.FLock.Acquire;
    try
      if not FInClear then
      begin
        FListUsed.Remove(AComponent);
        // By object, not by SQL text: an unused query with the same text
        // may be in the list
        i := FListUnused.IndexOfObject(AComponent);
        if i >= 0 then
          FListUnused.Delete(i);
      end;
    finally
      CacheList.FLock.Release;
    end;
  end;
  inherited;
end;

procedure TFIBQueryCache.UnUseQuery(aFIBQuery: TFIBQuery);
var
  i: Integer;
  Key: string;
begin
  if FListUsed.Remove(aFIBQuery) < 0 then
    Exit;

  Key := CacheKey(aFIBQuery.SQL.Text);
  // Two queries with the same SQL were in use at the same time, the list
  // keeps one query per SQL text
  if FListUnused.Find(Key, i) then
    aFIBQuery.Free
  else
    FListUnused.AddObject(Key, aFIBQuery);
end;

function TFIBQueryCache.UseQuery(aTransaction: TFIBTransaction; const SQLText: string): TFIBQuery;
var
  i: Integer;
begin
  if FListUnused.Find(CacheKey(SQLText), i) then
  begin
    Result := TFIBQuery(FListUnused.Objects[i]);
    if Result.Transaction <> aTransaction then
      Result.Transaction := aTransaction;
    FListUsed.Add(Result);
    FListUnused.Delete(i)
  end
  else
  begin
    Result := TFIBQuery.Create(nil);
    Result.FreeNotification(Self);
    with Result do
    begin
      DataBase := FFIBDataBase;
      Transaction := aTransaction;
      SQL.Text := SQLText;
      FListUsed.Add(Result);
    end;
  end;
end;

{ TFIBQueryCacheList }

constructor TFIBQueryCacheList.Create(AOwner: TComponent);
begin
  inherited;
  FList := TList.Create;
  FLock := TCriticalSection.Create
end;

destructor TFIBQueryCacheList.Destroy;
var
  i: TFIBListIndex;
begin
  FLock.Acquire;
  try
    for i := 0 to FList.Count - 1 do
      TObject(FList[i]).Free;
    FList.Free;
    inherited;
  finally
    FLock.Release;
    FLock.Free
  end
end;

function TFIBQueryCacheList.FindCacheForDB(aDataBase: TFIBDataBase): TFIBQueryCache;
var
  i: TFIBListIndex;
begin
  FLock.Acquire;
  try
    for i := 0 to FList.Count - 1 do
    begin
      Result := TFIBQueryCache(FList[i]);
      if Result.FFIBDataBase = aDataBase then
        Exit;
    end;
    Result := nil;
  finally
    FLock.Release;
  end;
end;

function TFIBQueryCacheList.GetCacheForDB(aDataBase: TFIBDataBase): TFIBQueryCache;
begin
  FLock.Acquire;
  try
    Result := FindCacheForDB(aDataBase);
    if Result = nil then
    begin
      // The cache is freed in Notification when the database is destroyed
      aDataBase.FreeNotification(Self);
      Result := TFIBQueryCache.Create(aDataBase);
      FList.Add(Result);
    end;
  finally
    FLock.Release;
  end;
end;

procedure TFIBQueryCacheList.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if (Operation = opRemove) and (AComponent is TFIBDataBase) then
    RemoveDataBase(TFIBDataBase(AComponent));
  inherited;
end;

procedure TFIBQueryCacheList.RemoveDataBase(aDataBase: TFIBDataBase);
var
  i: TFIBListIndex;
begin
  FLock.Acquire;
  try
    for i := FList.Count - 1 downto 0 do
      if TFIBQueryCache(FList[i]).FFIBDataBase = aDataBase then
      begin
        TFIBQueryCache(FList[i]).Free;
        FList.Delete(i)
      end;
  finally
    FLock.Release
  end
end;

procedure TFIBQueryCacheList.UnUseQuery(aFIBQuery: TFIBQuery);
var
  Cache: TFIBQueryCache;
begin
  if (aFIBQuery = nil) or (aFIBQuery.DataBase = nil) then
    Exit;
  FLock.Acquire;
  try
    // No cache for the database: the query doesn't come from the cache
    Cache := FindCacheForDB(aFIBQuery.DataBase);
    if Cache <> nil then
      Cache.UnUseQuery(aFIBQuery);
  finally
    FLock.Release;
  end;
end;

function TFIBQueryCacheList.UseQuery(aTransaction: TFIBTransaction; const SQLText: string): TFIBQuery;
var
  DB: TFIBDataBase;
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
  Result := UseQuery(DB, aTransaction, SQLText);
end;

function TFIBQueryCacheList.UseQuery(Database: TFIBDataBase; Transaction: TFIBTransaction; const SQLText: string): TFIBQuery;
begin
  Result := nil;
  if (Database = nil) or (Transaction = nil) then
    Exit;
  FLock.Acquire;
  try
    Result := GetCacheForDB(Database).UseQuery(Transaction, SQLText);
  finally
    FLock.Release;
  end;
end;

// interface
function GetQueryForUse(aTransaction: TFIBTransaction; const SQLText: string): TFIBQuery;
begin
  Result := CacheList.UseQuery(aTransaction, SQLText);
  if (Result <> nil) and Result.Open then
    Result.Close;
end;

function GetQueryForUse(Database: TFIBDataBase; Transaction: TFIBTransaction; const SQLText: string): TFIBQuery;
begin
  Result := CacheList.UseQuery(Database, Transaction, SQLText);
  if (Result <> nil) and Result.Open then
    Result.Close;
end;

procedure FreeQueryForUse(aFIBQuery: TFIBQuery);
begin
  if aFIBQuery.Open then
    aFIBQuery.Close;
  CacheList.UnUseQuery(aFIBQuery)
end;

procedure FreeHandleCachedQuery(DB: TFIBDataBase; const SQLText: string);
var
  Cache: TFIBQueryCache;
  i: Integer;
begin
  CacheList.FLock.Acquire;
  try
    Cache := CacheList.FindCacheForDB(DB);
    if (Cache <> nil) and Cache.FListUnused.Find(CacheKey(SQLText), i) then
      TFIBQuery(Cache.FListUnused.Objects[i]).FreeHandle;
  finally
    CacheList.FLock.Release;
  end;
end;

procedure ClearQueryCacheList(DB: TFIBDataBase);
var
  Cache: TFIBQueryCache;
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

CacheList := TFIBQueryCacheList.Create(nil);

finalization

CacheList.Free;

end.
