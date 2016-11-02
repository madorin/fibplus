// SuperIB
// Copyright © 1999 David S. Becker
// dhbecker@jps.net
// www.jps.net/dhbecker/superib


unit SIBFIBEA;


interface

uses Classes, SIBEABase, SIBAPI, FIBDatabase;

type
  { TSIBfibEventAlerter }

  TSIBfibEventAlerter = class(TSIBEventAlerter)
  private
    FDatabase: TFIBDatabase;
    FAutoRegister: Boolean;
    procedure SetDatabase(const Value: TFIBDatabase);
    procedure SetAutoRegister(const Value: Boolean);
    function  CanRegisterEvents:boolean;
  protected
    function  GetNativeHandle: SIB_DBHandle; override;
    procedure SetNativeHandle(const Value: SIB_DBHandle); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Loaded; override;
    procedure ValidateDatabase(DB: TFIBDatabase); virtual;
    procedure AfterConnect(Sender:TObject);
    procedure BeforeDisconnect(Sender:TObject);

  public
    constructor Create(Owner: TComponent); override;
    destructor Destroy; override;
  published
    property Database: TFIBDatabase read FDatabase write SetDatabase;
    property AutoRegister: Boolean read FAutoRegister write SetAutoRegister default False;

  end;

implementation
uses
 SysUtils, SIBGlobals;

resourcestring
  SIB_RS_FIB_SET_NATIVEHANDLE = 'SIBfibEventAlerter does not allow you to set the NativeHandle property';
  SIB_RS_FIB_NO_DATABASE      = 'Cannot register events, no database assigned or database not connected';


{ TSIBfibEventAlerter }

// we need to know when the component is deleted and clear out the property
procedure TSIBfibEventAlerter.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if (Operation = opRemove) and (AComponent = FDatabase) then
  begin
    Database := nil;
  end;
  inherited;
end;

procedure TSIBfibEventAlerter.Loaded;
begin
 if FAutoRegister and CanRegisterEvents then
   RegisterEvents;
 inherited;
end;

// Retrieve the native InterBase handle from the FreeIBComponents
function TSIBfibEventAlerter.GetNativeHandle: SIB_DBHandle;
begin
  ValidateDatabase(FDatabase);
  Result := SIB_DBHandle(FDatabase.Handle);
  FClientLibrary:=FDatabase.ClientLibrary;  
end;

procedure TSIBfibEventAlerter.SetNativeHandle(const Value: SIB_DBHandle);
begin
  raise ESIBError.Create(SIB_RS_FIB_SET_NATIVEHANDLE);
end;

constructor TSIBfibEventAlerter.Create(Owner: TComponent);
begin
  inherited;
  FAutoRegister := False;
  FDatabase     := nil;
  FClientLibrary:= nil;
end;


destructor TSIBfibEventAlerter.Destroy;
begin
  Database := nil; // For unregister connect(disconnect) events
  inherited;
end;


procedure TSIBfibEventAlerter.SetDatabase(const Value: TFIBDatabase);
var
  WasRegistered: Boolean;
begin
  if (Value <> FDatabase) then
  begin
    WasRegistered := Registered;
    if WasRegistered then  UnRegisterEvents;

    if Assigned(FDatabase) and not (csDesigning in ComponentState)
    and not (csDestroying in FDatabase.ComponentState)
     then
    begin
      FDatabase.RemoveEvent( AfterConnect, detOnConnect );
      FDatabase.RemoveEvent( BeforeDisconnect, detBeforeDisconnect );
      FClientLibrary:=nil;
    end;

    FDatabase := Value;
    if Assigned(FDatabase) and not (csDesigning in ComponentState) then
      try
        FDatabase.AddEvent(AfterConnect,detOnConnect);
        FDatabase.AddEvent(BeforeDisconnect,detBeforeDisconnect);
      finally
        if WasRegistered then  RegisterEvents;
      end;
  end;
end;

// this routine is used to verify that the database is assigned and connected
procedure TSIBfibEventAlerter.ValidateDatabase(DB: TFIBDatabase);
begin
  if ((not Assigned(DB)) or (not DB.Connected)) then
    raise ESIBError.Create(SIB_RS_FIB_NO_DATABASE);
end;


function  TSIBfibEventAlerter.CanRegisterEvents:boolean;
begin
 Result:=(not (csDesigning in ComponentState)) and
//       (not (csLoading in ComponentState)) and
        (not Registered) and Assigned(Database) and Database.Connected ;
end;

procedure TSIBfibEventAlerter.SetAutoRegister(const Value: Boolean);
begin
  FAutoRegister := Value;
  if FAutoRegister and CanRegisterEvents then
    RegisterEvents;
end;


procedure TSIBfibEventAlerter.AfterConnect(Sender: TObject);
begin
 if ((not (csDesigning in ComponentState)) and Assigned(FDatabase)) then
 if (FAutoRegister and (not Registered)) then   RegisterEvents;
end;

procedure TSIBfibEventAlerter.BeforeDisconnect(Sender: TObject);
begin
 if ((not (csDesigning in ComponentState)) and Assigned(FDatabase)) then
  if Registered then UnRegisterEvents
end;

end.

