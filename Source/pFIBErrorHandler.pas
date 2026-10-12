unit pFIBErrorHandler deprecated 'Use FIBErrorHandler (TFIBErrorHandler)';

interface

uses
  FIBErrorHandler;

type
  TpFibErrorHandler = TFIBErrorHandler deprecated 'Use TFIBErrorHandler';
  TOptionErrorHandler = FIBErrorHandler.TOptionErrorHandler;
  TKindIBError = FIBErrorHandler.TKindIBError;
  TOnFIBErrorEvent = FIBErrorHandler.TOnFIBErrorEvent;
  TOptionsErrorHandler = FIBErrorHandler.TOptionsErrorHandler;
  TErrorLexems = FIBErrorHandler.TErrorLexems;

const
  oeException = FIBErrorHandler.oeException;
  oeForeignKey = FIBErrorHandler.oeForeignKey;
  oeLostConnect = FIBErrorHandler.oeLostConnect;
  oeCheck = FIBErrorHandler.oeCheck;
  oeUniqueViolation = FIBErrorHandler.oeUniqueViolation;
  keNoError = FIBErrorHandler.keNoError;
  keException = FIBErrorHandler.keException;
  keForeignKey = FIBErrorHandler.keForeignKey;
  keLostConnect = FIBErrorHandler.keLostConnect;
  keSecurity = FIBErrorHandler.keSecurity;
  keCheck = FIBErrorHandler.keCheck;
  keUniqueViolation = FIBErrorHandler.keUniqueViolation;
  keOther = FIBErrorHandler.keOther;
  keStatementTimeout = FIBErrorHandler.keStatementTimeout;
  keCancelled = FIBErrorHandler.keCancelled;

function IsConnectionLost(const IBErrorCode: Integer): Boolean; deprecated 'Use FIBErrorHandler.IsConnectionLost';

implementation

uses
  Classes;

function IsConnectionLost(const IBErrorCode: Integer): Boolean;
begin
  Result := FIBErrorHandler.IsConnectionLost(IBErrorCode);
end;

initialization
  RegisterClassAlias(TFIBErrorHandler, 'TpFibErrorHandler');

end.
