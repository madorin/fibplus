unit pFIBStoredProc deprecated 'Use FIBStoredProc (TFIBStoredProc)';

interface

uses
  FIBStoredProc;

type
  TpFIBStoredProc = TFIBStoredProc deprecated 'Use TFIBStoredProc';

implementation

uses
  Classes;

initialization
  RegisterClassAlias(TFIBStoredProc, 'TpFIBStoredProc');

end.
