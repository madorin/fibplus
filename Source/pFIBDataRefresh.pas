unit pFIBDataRefresh;

{$MESSAGE WARN 'Unit pFIBDataRefresh is deprecated, use FIBDataRefresh (TFIBTableChangesReader)'}

interface

uses
  FIBDataRefresh;

type
  TpFIBTableChangesReader = TFIBTableChangesReader deprecated 'Use TFIBTableChangesReader';

implementation

uses
  Classes;

initialization
  RegisterClassAlias(TFIBTableChangesReader, 'TpFIBTableChangesReader');

end.
