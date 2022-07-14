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


procedure TCacheQueries.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  if (Operation=opRemove) and not vInClear then
  if Acomponent is TFIBQuery then
  begin
    FListUsed.Remove(Acomponent);
    FListUnused.Remove(FastTrim(TFIBQuery(Acomponent).SQL.Text));
  end;
  inherited;
end;

procedure TCacheQueries.UnUseQuery(aFIBQuery:TFIBQuery);
var
 i:integer;
begin
 i:=FListUsed.IndexOf(aFIBQuery);
 if i>=0 then
 begin
  FListUsed.Delete(i);
  FListUnused.AddObject(
   FastTrim(aFIBQuery.SQL.Text),aFIBQuery
  );
 end;
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

function TCacheList.GetCacheForDB(aDataBase: TFIBDatabase): TCacheQueries;
var
    j:integer;
begin
  FLock.Acquire;
  try
     with FList do
     for j := 0 to Pred(Count) do    // Iterate
     if TCacheQueries(FList[j]).FFIBDataBase=aDataBase then
     begin
      Result:=TCacheQueries(FList[j]);
      Exit;
     end;
     Result:=TCacheQueries.Create(aDataBase);
     FList.Add(Result);
  finally
   FLock.Release
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
begin
 if(aFIBQuery=nil) or(aFIBQuery.Database=nil) then Exit;
 FLock.Acquire;
 try
  GetCacheForDB(aFIBQuery.Database).UnUseQuery(aFIBQuery);
 finally
  FLock.Release
 end;
end;


function TCacheList.UseQuery(aTransaction: TFIBTransaction;
  const SQLText: string): TFIBQuery;
var
   DB:TFIBDatabase;
begin
 Result:=nil;
// if(aTransaction=nil) or(aTransaction.DefaultDatabase=nil) then Exit;
 if(aTransaction=nil) then Exit;
 DB:=aTransaction.DefaultDatabase;
 if (DB=nil) then
  if  aTransaction.DatabaseCount<>1 then
   Exit
  else
   DB:=aTransaction.Databases[0];

 FLock.Acquire;
 try
   DB.FreeNotification(Self);
   Result:=
    GetCacheForDB(DB).UseQuery(aTransaction,SQLText);
 finally
   FLock.Release;
 end;
end;


procedure TCacheList.FreeUnusedQueries;
var
  i:integer;
begin
 FLock.Acquire;
 try
   for i:=0 to Pred(FList.Count) do
   begin
     TCacheQueries(FList[i]).FListUnused.FullClear
   end;
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

procedure FreeHandleCachedQuery(DB:TFIBDataBase;const SQLText:string);
var
 cq:TCacheQueries;
 i:integer;
begin
 cq:=CacheList.GetCacheForDB(DB);
 if cq<>nil then
 with cq,CacheList do
 begin
   FLock.Acquire;
   try
    if FListUnused.Find(FastTrim(SQLText),i) then
     TFIBQuery(FListUnused.Objects[i]).FreeHandle;
   finally
    FLock.Release
   end;
 end;
end;

procedure ClearQueryCacheList(DB:TFIBDataBase);
var
 cq:TCacheQueries;
 i:integer;
begin
 cq:=CacheList.GetCacheForDB(DB);
 if cq<>nil then
 with cq do
 begin
   CacheList.FLock.Acquire;
   try
     FListUnused.FullClear;
//     for i:=FListUnused.Count-1 downto 0 do
//      TFIBQuery(FListUnused.Objects[i]).Free;
   finally
     CacheList.FLock.Release
   end;
 end;
end;

initialization
 CacheList:=TCacheList.Create(nil);
finalization
 CacheList.Free;
end.


