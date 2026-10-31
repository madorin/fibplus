unit pFIBDataRefresh deprecated 'Use FIBDataRefresh (TFIBTableChangesReader)';

interface

uses
  FIBDataRefresh;

type
  TpFIBTableChangesReader = TFIBTableChangesReader deprecated 'Use TFIBTableChangesReader';
  TChangesCount = FIBDataRefresh.TFIBChangesCount;

implementation

uses
  Classes;

initialization
  RegisterClassAlias(TFIBTableChangesReader, 'TpFIBTableChangesReader');

end.
