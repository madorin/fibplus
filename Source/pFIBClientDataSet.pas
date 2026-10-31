unit pFIBClientDataSet deprecated 'Use FIBClientDataSet (TFIBClientDataSet)';

interface

uses
  FIBClientDataSet;

type
  TpFIBClientDataSet = FIBClientDataSet.TFIBClientDataSet deprecated 'Use TFIBClientDataSet';
  TpFIBClientBCDField = FIBClientDataSet.TFIBClientBCDField deprecated 'Use TFIBClientBCDField';
  TpFIBDataSetProvider = FIBClientDataSet.TFIBDataSetProvider deprecated 'Use TFIBDataSetProvider';
  TOnApplyUpdateKind = FIBClientDataSet.TFIBApplyUpdateKind;

const
  aukBefore = FIBClientDataSet.aukBefore;
  aukAfter = FIBClientDataSet.aukAfter;

implementation

uses
  Classes;

initialization
  RegisterClassAlias(TFIBClientDataSet, 'TpFIBClientDataSet');
  RegisterClassAlias(TFIBClientBCDField, 'TpFIBClientBCDField');
  RegisterClassAlias(TFIBDataSetProvider, 'TpFIBDataSetProvider');

end.
