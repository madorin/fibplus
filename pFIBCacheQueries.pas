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
  SysUtils, Classes, FIBQuery, FIBDatabase, SyncObjs;

function GetQueryForUse(aTransaction: TFIBTransaction; const SQLText: string): TFIBQuery;
procedure FreeQueryForUse(aFIBQuery: TFIBQuery);
procedure FreeHandleCachedQuery(DB: TFIBDataBase; const SQLText: string);
procedure ClearQueryCacheList(DB: TFIBDataBase);

implementation

uses
{$IFDEF D_XE3}
  System.Types, // for inline funcs
{$ENDIF}
  SqlTxtRtns, pFIBLists, StrUtil;

type

  TCacheQueries = class(TComponent)
  private
    FFIBDataBase: TFIBDataBase;
    FListUnused: TObjStringList;
    FListUsed: TList;
    vInClear: boolean;
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

  TCacheList = class(TComponent)
  private
    FList: TList;
    FLock: TCriticalSection;
    function FindCacheForDB(aDataBase: TFIBDataBase): TCacheQueries;
    function GetCacheForDB(aDataBase: TFIBDataBase): TCacheQueries;
    procedure RemoveDataBase(aDataBase: TFIBDataBase);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function UseQuery(aTransaction: TFIBTransaction; const SQLText: string): TFIBQuery;
    procedure UnUseQuery(aFIBQuery: TFIBQuery);
    procedure FreeUnusedQueries;
  end;

var
  CacheList: TCacheList;

  { TCacheQueries }

procedure TCacheQueries.Clear;
var
  i: integer;
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

constructor TCacheQueries.Create(aFIBDataBase: TFIBDataBase);
begin
  inherited Create(nil);
  FFIBDataBase := aFIBDataBase;
  FListUnused := TObjStringList.Create(nil, true);
  FListUsed := TList.Create;
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
  i: integer;
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

procedure TCacheQueries.Notification(AComponent: TComponent; Operation: TOperation);
var
  i: integer;
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

procedure TCacheQueries.UnUseQuery(aFIBQuery: TFIBQuery);
var
  i: integer;
  Key: string;
begin
  i := FListUsed.IndexOf(aFIBQuery);
  if i < 0 then
    Exit;
  FListUsed.Delete(i);

  Key := FastTrim(aFIBQuery.SQL.Text);
  // Two queries with the same SQL were in use at the same time, the list
  // keeps one query per SQL text
  if FListUnused.Find(Key, i) then
    aFIBQuery.Free
  else
    FListUnused.AddObject(Key, aFIBQuery);
end;

function TCacheQueries.UseQuery(aTransaction: TFIBTransaction; const SQLText: string): TFIBQuery;
var
  i: integer;
begin
  if FListUnused.Find(FastTrim(SQLText), i) then
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

{ TCacheList }

constructor TCacheList.Create(AOwner: TComponent);
begin
  inherited;
  FList := TList.Create;
  FLock := TCriticalSection.Create
end;

destructor TCacheList.Destroy;
var
  i: integer;
begin
  FLock.Acquire;
  try
    with FList do
      for i := 0 to Pred(Count) do
        TObject(FList[i]).Free;
    FList.Free;
    inherited;
  finally
    FLock.Release;
    FLock.Free
  end
end;

function TCacheList.FindCacheForDB(aDataBase: TFIBDataBase): TCacheQueries;
var
  i: integer;
begin
  FLock.Acquire;
  try
    for i := 0 to FList.Count - 1 do
    begin
      Result := TCacheQueries(FList[i]);
      if Result.FFIBDataBase = aDataBase then
        Exit;
    end;
    Result := nil;
  finally
    FLock.Release;
  end;
end;

function TCacheList.GetCacheForDB(aDataBase: TFIBDataBase): TCacheQueries;
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

procedure TCacheList.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if (Operation = opRemove) and (AComponent is TFIBDataBase) then
    RemoveDataBase(TFIBDataBase(AComponent));
  inherited;
end;

procedure TCacheList.RemoveDataBase(aDataBase: TFIBDataBase);
var
  i: integer;
begin
  FLock.Acquire;
  try
    with FList do
      for i := Pred(Count) downto 0 do
        if TCacheQueries(FList[i]).FFIBDataBase = aDataBase then
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

function TCacheList.UseQuery(aTransaction: TFIBTransaction; const SQLText: string): TFIBQuery;
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

  FLock.Acquire;
  try
    Result := GetCacheForDB(DB).UseQuery(aTransaction, SQLText);
  finally
    FLock.Release;
  end;
end;

procedure TCacheList.FreeUnusedQueries;
var
  i: integer;
begin
  FLock.Acquire;
  try
    for i := 0 to FList.Count - 1 do
      TCacheQueries(FList[i]).ClearUnused;
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

procedure FreeQueryForUse(aFIBQuery: TFIBQuery);
begin
  if aFIBQuery.Open then
    aFIBQuery.Close;
  CacheList.UnUseQuery(aFIBQuery)
end;

procedure FreeHandleCachedQuery(DB: TFIBDataBase; const SQLText: string);
var
  Cache: TCacheQueries;
  i: integer;
begin
  CacheList.FLock.Acquire;
  try
    Cache := CacheList.FindCacheForDB(DB);
    if (Cache <> nil) and Cache.FListUnused.Find(FastTrim(SQLText), i) then
      TFIBQuery(Cache.FListUnused.Objects[i]).FreeHandle;
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

CacheList := TCacheList.Create(nil);

finalization

CacheList.Free;

end.
