unit SIBGlobals;

// SuperIB
// Copyright © 1999 David S. Becker
// dhbecker@jps.net
// www.jps.net/dhbecker/superib

interface
uses SysUtils;

const
  SIB_MAX_EVENT_BLOCK   = 15;   // maximum events handled per block by InterBase
  SIB_MAX_EVENT_LENGTH  = 128;  // maximum event name length

type
  ESIBError = class(Exception);

resourcestring
  SIB_RS_NOT_REGISTERED       = 'Events not registered';
  SIB_RS_ALREADY_REGISTERED   = 'Events already registered';
  SIB_RS_EMPTY_STRINGS        = 'Can not assign empty strings as events.  ';
  SIB_RS_TOO_LONG             = 'Some event were longer than %d and were truncated.  ';
  SIB_RS_FIB_SET_NATIVEHANDLE = 'SIBfibEventAlerter does not allow you to set the NativeHandle property';
  SIB_RS_FIB_NO_DATABASE      = 'Cannot register events, no database assigned or database not connected';

implementation

end.

