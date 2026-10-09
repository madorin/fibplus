unit pFIBStoredProc;

{$MESSAGE WARN 'Unit pFIBStoredProc is deprecated, use FIBStoredProc (TFIBStoredProc)'}

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
