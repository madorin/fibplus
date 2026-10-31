unit pFIBArray deprecated 'Use FIBArray (TFIBArray)';

interface

{$I FIB.inc}

uses
  FIBArray;

{$IFDEF SUPPORT_ARRAY_FIELD}
type
  TpFIBArray = FIBArray.TFIBArray deprecated 'Use TFIBArray';
  TArrayBound = FIBArray.TFIBArrayBound;
  TArrayBounds = FIBArray.TFIBArrayBounds;
  TFIBArray = FIBArray.TFIBArray;
{$ENDIF}

implementation

end.
