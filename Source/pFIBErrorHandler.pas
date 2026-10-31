unit pFIBErrorHandler deprecated 'Use FIBErrorHandler (TFIBErrorHandler)';

interface

uses
  FIBErrorHandler;

type
  TpFibErrorHandler = TFIBErrorHandler deprecated 'Use TFIBErrorHandler';
  TOptionErrorHandler = FIBErrorHandler.TFIBErrorHandlerOption;
  TKindIBError = FIBErrorHandler.TFIBErrorKind;
  TOnFIBErrorEvent = FIBErrorHandler.TFIBErrorEvent;
  TOptionsErrorHandler = FIBErrorHandler.TFIBErrorHandlerOptions;
  TErrorLexems = FIBErrorHandler.TFIBErrorLexemes;

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
