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

unit FIBEventLists;

interface

{$I FIB.inc}

uses
  SyncObjs, SysUtils, Classes;

type
  PFIBMethod = ^TMethod;

  TFIBCallbackList = class(TComponent)
  private
    FCallBackList: TList;
    FCS: TCriticalSection;
    function GetCallBackAddr(Index: Integer): PFIBMethod;
    function GetCount: Integer;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function RegisterCallBack(const Proc: TMethod): Integer;
    procedure UnRegisterCallBack(const Proc: TMethod);
    procedure UnRegisterCallBacks(ProcOwner: TObject);
    procedure Delete(Index: Integer);
    function IndexOfMethod(const Proc: TMethod): Integer;
    property CallBackAddr[Index: Integer]: PFIBMethod read GetCallBackAddr;
    property Count: Integer read GetCount;
  end;

  TFIBNotifyEventList = class(TFIBCallbackList)
  private
    function Get(Index: Integer): TNotifyEvent;
  public
    function Add(Event: TNotifyEvent): Integer;
    procedure Remove(Event: TNotifyEvent);
    property Event[Index: Integer]: TNotifyEvent read Get; default;
  end;

type
  // Deprecated names of the types renamed in 8.0.0
  PMethod = PFIBMethod deprecated 'Use PFIBMethod';
  TCallBackList = TFIBCallbackList deprecated 'Use TFIBCallbackList';
  TNotifyEventList = TFIBNotifyEventList deprecated 'Use TFIBNotifyEventList';

implementation

uses
  FIBConsts;

{ TFIBCallbackList }

constructor TFIBCallbackList.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCallBackList := TList.Create;
  FCS := TCriticalSection.Create;
end;

destructor TFIBCallbackList.Destroy;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    Dispose(FCallBackList[i]);
  FCallBackList.Free;
  FCS.Free;
  inherited Destroy;
end;

function TFIBCallbackList.GetCallBackAddr(Index: Integer): PFIBMethod;
begin
  if (Index < 0) or (Index >= FCallBackList.Count) then
    Result := nil
  else
    Result := FCallBackList[Index]
end;

function TFIBCallbackList.RegisterCallBack(const Proc: TMethod): Integer;
var
  p: PFIBMethod;
begin
  FCS.Acquire;
  try
    Result := IndexOfMethod(Proc);
    if Result < 0 then
    begin
      New(p);
      p^ := Proc;
      Result := Count;
      FCallBackList.Add(p);
      if TObject(Proc.Data) is TComponent then
        TComponent(Proc.Data).FreeNotification(Self);
    end;
  finally
    FCS.Release
  end;
end;

procedure TFIBCallbackList.UnRegisterCallBack(const Proc: TMethod);
var
  i: Integer;
begin
  FCS.Acquire;
  try
    for i := Count - 1 downto 0 do
      with PFIBMethod(FCallBackList[i])^ do
        if (Code = Proc.Code) and (Data = Proc.Data) then
        begin
          Dispose(FCallBackList[i]);
          FCallBackList.Delete(i);
          Exit;
        end;
  finally
    FCS.Release
  end;
end;

function TFIBCallbackList.GetCount: Integer;
begin
  Result := Integer(FCallBackList.Count)
end;

procedure TFIBCallbackList.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if Operation = opRemove then
    UnRegisterCallBacks(AComponent);
  inherited Notification(AComponent, Operation);
end;

procedure TFIBCallbackList.UnRegisterCallBacks(ProcOwner: TObject);
var
  i: Integer;
begin
  FCS.Acquire;
  try
    for i := Count - 1 downto 0 do
      if TObject(PFIBMethod(FCallBackList[i])^.Data) = ProcOwner then
      begin
        Dispose(FCallBackList[i]);
        FCallBackList.Delete(i);
      end;
  finally
    FCS.Release;
  end;
end;

function TFIBCallbackList.IndexOfMethod(const Proc: TMethod): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := Count - 1 downto 0 do
    with PFIBMethod(FCallBackList[i])^ do
      if (Code = Proc.Code) and (Data = Proc.Data) then
      begin
        Result := i;
        Exit;
      end;
end;

procedure TFIBCallbackList.Delete(Index: Integer);
begin
  FCS.Acquire;
  try
    if (Index >= 0) and (Index < FCallBackList.Count) then
    begin
      Dispose(PFIBMethod(FCallBackList[Index]));
      FCallBackList.Delete(Index);
    end;
  finally
    FCS.Release;
  end;
end;

{ TFIBNotifyEventList }

function TFIBNotifyEventList.Add(Event: TNotifyEvent): Integer;
begin
  Result := RegisterCallBack(TMethod(Event));
end;

function TFIBNotifyEventList.Get(Index: Integer): TNotifyEvent;
var
  p: PFIBMethod;
begin
  p := CallBackAddr[Index];
  if p <> nil then
    Result := TNotifyEvent(p^)
  else
    Result := nil
end;

procedure TFIBNotifyEventList.Remove(Event: TNotifyEvent);
begin
  UnRegisterCallBack(TMethod(Event))
end;

end.
