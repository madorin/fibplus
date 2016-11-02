unit SIBAPI;

// SuperIB
// Copyright © 1999 David S. Becker
// dhbecker@jps.net
// www.jps.net/dhbecker/superib

{$I FIBPlus.inc}
interface

uses IB_Intf, SIBGlobals;

type
  // data types used to interface with the InterBase API
  SIB_PVoid                 = ^Pointer;
  SIB_PPChar                = ^PAnsiChar;
  SIB_Long                  = LongInt;
  SIB_PLong                 = ^SIB_Long;
  SIB_UShort                = Word;
  SIB_DBHandle              = SIB_PVoid;
  SIB_PDBHandle             = ^SIB_DBHandle;
  SIB_Status                = SIB_Long;
  SIB_PStatus               = ^SIB_Status;
  SIB_PPStatus              = ^SIB_PStatus;
  SIB_StatusVector          = array[0..19] of SIB_Status;
  SIB_PStatusVector         = ^SIB_StatusVector;
  SIB_PPStatusVector        = ^SIB_PStatusVector;
  SIB_EventCallback         = procedure(P: Pointer; Length: SIB_UShort; Updated: PAnsiChar); cdecl;


function SIB_Free(ClientLibrary:IIBClientLibrary;P: PAnsiChar): SIB_Long;
function SIB_QueEvents(ClientLibrary:IIBClientLibrary;Status: SIB_PStatusVector; DBHandle: SIB_PDBHandle; EventID: SIB_PLong;
 Length: SIB_UShort;EventBuffer: PAnsiChar; Callback:
 SIB_EventCallback; CallbackArg: Pointer
): SIB_Status;
function SIB_CancelEvents(ClientLibrary:IIBClientLibrary;Status: SIB_PStatusVector; DBHandle: SIB_DBHandle; EventID: SIB_PLong): SIB_Status;
procedure SIB_EventCounts(ClientLibrary:IIBClientLibrary;Status: SIB_PStatusVector; Length: SIB_UShort; EventBuffer, ResultBuffer: PAnsiChar);

implementation

uses IB_Externals, ibase;

//---------------------------------------------------------------------------

function SIB_QueEvents(ClientLibrary:IIBClientLibrary;Status: SIB_PStatusVector;
 DBHandle: SIB_PDBHandle; EventID: SIB_PLong; Length: SIB_UShort;
 EventBuffer: PAnsiChar; Callback: SIB_EventCallback; CallbackArg: Pointer): SIB_Status;
begin
  with ClientLibrary do
  Result := isc_que_events( PISC_STATUS( Status ), PISC_DB_HANDLE( DBHandle ),
      PISC_LONG( EventID ),
      Length, EventBuffer,
      TISC_CALLBACK( Callback ), CallbackArg
      );
  Set8087CW(Default8087CW);
end;

//---------------------------------------------------------------------------

function SIB_CancelEvents(ClientLibrary:IIBClientLibrary;Status: SIB_PStatusVector; DBHandle: SIB_DBHandle; EventID: SIB_PLong): SIB_Status;
begin
  with ClientLibrary do
  Result := isc_cancel_events( PISC_STATUS( Status ), PISC_DB_HANDLE( DBHandle ), PISC_LONG( EventID ) );
  Set8087CW(Default8087CW);
end;

//---------------------------------------------------------------------------

procedure SIB_EventCounts(ClientLibrary:IIBClientLibrary;Status: SIB_PStatusVector; Length: SIB_UShort; EventBuffer, ResultBuffer: PAnsiChar);
begin
  ClientLibrary.isc_event_counts( PISC_STATUS( Status ), Length, EventBuffer, ResultBuffer );
  Set8087CW(Default8087CW);
end;

//---------------------------------------------------------------------------


function SIB_Free(ClientLibrary:IIBClientLibrary;P: PAnsiChar): SIB_Long;
begin
 with ClientLibrary do
 if Assigned(P) then
  Result := isc_free(P)
 else
  Result := 0   ;
  Set8087CW(Default8087CW);
end;

end.

