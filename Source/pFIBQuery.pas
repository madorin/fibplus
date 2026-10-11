unit pFIBQuery deprecated 'Use FIBQuery (TFIBQuery) and FIBDataSet (TFIBUpdateObject)';

interface

uses
  FIBQuery, FIBDataSet;

type
  TpFIBQuery = TFIBQuery deprecated 'Use TFIBQuery';
  TpFIBUpdateObject = TFIBUpdateObject deprecated 'Use TFIBUpdateObject';
  TFIBOrderExecUO = FIBDataSet.TFIBOrderExecUO;
  TFIBQueryErrorEvent = FIBQuery.TFIBQueryErrorEvent;

const
  oeBeforeDefault = FIBDataSet.oeBeforeDefault;
  oeAfterDefault = FIBDataSet.oeAfterDefault;

implementation

uses
  Classes;

initialization
  RegisterClassAlias(TFIBQuery, 'TpFIBQuery');
  RegisterClassAlias(TFIBUpdateObject, 'TpFIBUpdateObject');

end.
