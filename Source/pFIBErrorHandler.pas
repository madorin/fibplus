unit pFIBErrorHandler;

{$MESSAGE WARN 'Unit pFIBErrorHandler is deprecated, use FIBErrorHandler (TFIBErrorHandler)'}

interface

uses
  FIBErrorHandler;

type
  TpFibErrorHandler = TFIBErrorHandler deprecated 'Use TFIBErrorHandler';

implementation

uses
  Classes;

initialization
  RegisterClassAlias(TFIBErrorHandler, 'TpFibErrorHandler');

end.
