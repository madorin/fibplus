unit SIBGlobals;

// SuperIB
// Copyright (c) 1999 David S. Becker
// dhbecker@jps.net
// www.jps.net/dhbecker/superib

{$I FIB.inc}

interface

uses
  SysUtils;

const
  FIBMaxEventBlock      = 15;  // maximum events handled per block by InterBase
  FIBMaxEventNameLength = 128; // maximum event name length

type
  EFIBEventAlerterError = class(Exception);

resourcestring
  SFIBEventsNotRegistered         = 'Events not registered';
  SFIBEventsAlreadyRegistered     = 'Events already registered';
  SFIBEventsEmptyNames            = 'Can not assign empty strings as events.  ';
  SFIBEventNamesTooLong           = 'Some event names are longer than %d characters.  ';
  SFIBEventAlerterSetNativeHandle = 'TFIBEventAlerter does not allow you to set the NativeHandle property';
  SFIBEventAlerterNoDatabase      = 'Cannot register events, no database assigned or database not connected';

type
  // Deprecated names of the types renamed in 8.0.0
  ESIBError = EFIBEventAlerterError deprecated 'Use EFIBEventAlerterError';

implementation

end.
