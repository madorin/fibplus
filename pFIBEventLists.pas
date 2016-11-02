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


unit pFIBEventLists;

interface

{$I FIBPlus.inc}
uses
  SyncObjs,   SysUtils,Classes;

type
  PMethod=^TMethod;


  TCallBackList = class(TComponent)
  private
    FCallBackList:TList;
    FCS:TCriticalSection;
    function    GetCallBackAddr(Index:integer):PMethod;
    function    GetCount: Integer;
  protected
    procedure   Notification(AComponent: TComponent;Operation: TOperation); override;
  public
    constructor Create(AOwner:TComponent); override;
    destructor  Destroy;override;
    function    RegisterCallBack  (const Proc:TMethod ):integer;
    procedure   UnRegisterCallBack(const Proc:TMethod  );
    procedure   UnRegisterCallBacks(ProcOwner:TObject);
    procedure   Delete(Index:Integer);
   function     IndexOfMethod(const Proc:TMethod):integer;
    property    CallBackAddr[Index:integer] :PMethod read GetCallBackAddr;
    property    Count:Integer read GetCount;
  end;




  TNotifyEventList= class(TCallBackList)
  private
   function   Get(Index:integer):TNotifyEvent;
  public
   function   Add(Event:TNotifyEvent):Integer;
   procedure  Remove(Event:TNotifyEvent);
   property   Event[Index:integer]:TNotifyEvent read Get;default;
  end;




implementation

uses FIBConsts;

{ TCallBackList }


constructor TCallBackList.Create(AOwner:TComponent);
begin
  inherited Create(AOwner);
  FCallBackList:=TList.Create;
  FCS:=TCriticalSection.Create;
end;

destructor TCallBackList.Destroy;
var i: integer;
begin
  for i:=0 to Pred(FCallBackList.Count) do  Dispose(FCallBackList[i]);
  FCallBackList.Free;
  FCS.Free;
  inherited Destroy;
end;

function TCallBackList.GetCallBackAddr(Index: integer): PMethod;
begin
 if (Index<0) or (Index>=FCallBackList.Count) then
  Result:=nil
 else
  Result:=FCallBackList[Index]
end;


function  TCallBackList.RegisterCallBack(const Proc:TMethod ):integer;
var
    p:PMethod;
begin
 FCS.Acquire;
 try
   Result:= IndexOfMethod(Proc);
   if Result<0 then
   begin
     New(p);
     p^:=Proc;
     Result:= FCallBackList.Add(p);
     if TObject(Proc.Data) is TComponent then
       TComponent(Proc.Data).FreeNotification(Self);
   end;
 finally
   FCS.Release
 end;
end;

procedure TCallBackList.UnRegisterCallBack(const Proc:TMethod );
var
  i:integer;
begin
 FCS.Acquire;
 try
   for i:=Pred(FCallBackList.Count) downto 0 do
    with PMethod(FCallBackList[i])^ do
    if  (Code=Proc.Code) and (Data=Proc.Data)  then
    begin
      Dispose(FCallBackList[i]);
      FCallBackList.Delete(i);
      Exit;
    end;
 finally
  FCS.Release
 end;
end;

function TCallBackList.GetCount: Integer;
begin
 Result:=FCallBackList.Count
end;

procedure TCallBackList.Notification(AComponent: TComponent;Operation: TOperation);
begin
  if Operation = opRemove then  UnRegisterCallBacks(AComponent);
  inherited Notification(AComponent,Operation);
end;

procedure TCallBackList.UnRegisterCallBacks(ProcOwner: TObject);
var i:integer;
begin
 FCS.Acquire;
 try
   with FCallBackList do
   for i:=Pred(Count) downto 0 do
     if TObject(TMethod(FCallBackList[i]^).Data)=ProcOwner then
     begin
      Dispose(FCallBackList[i]);
      Delete(i);
     end;
 finally
     FCS.Release;
 end;     
end;

function TCallBackList.IndexOfMethod(const Proc: TMethod): integer;
var i:integer;
begin
 Result:=-1;
 for i:=Pred(FCallBackList.Count) downto 0 do
  with PMethod(FCallBackList[i])^ do
  if  (Code=Proc.Code) and (Data=Proc.Data)  then
  begin
   Result:=i;
   Exit;
  end;
end;

procedure TCallBackList.Delete(Index: Integer);
begin
 if (Index>0) and (Index<FCallBackList.Count) then
  FCallBackList.Delete(Index);
end;

{ TNotifyEventList }

function TNotifyEventList.Add(Event: TNotifyEvent): Integer;
begin
 Result:= RegisterCallBack(TMethod(Event)) ;
end;


function TNotifyEventList.Get(Index:integer): TNotifyEvent;
var p:PMethod;
begin
 p:=CallBackAddr[Index];
 if p<>nil then
  Result:=TNotifyEvent(p^)
 else
  Result:=nil
end;

procedure TNotifyEventList.Remove(Event: TNotifyEvent);
begin
 UnRegisterCallBack(TMethod(Event))
end;


end.


