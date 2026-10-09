unit pFIBQuery;

{$MESSAGE WARN 'Unit pFIBQuery is deprecated, use FIBQuery (TFIBQuery) and FIBUpdateObject (TFIBUpdateObject)'}

interface

uses
  FIBQuery, FIBUpdateObject;

type
  TpFIBQuery = TFIBQuery deprecated 'Use TFIBQuery';
  TpFIBUpdateObject = TFIBUpdateObject deprecated 'Use TFIBUpdateObject';
  TFIBOrderExecUO = FIBUpdateObject.TFIBOrderExecUO;
  TFIBQueryErrorEvent = FIBQuery.TFIBQueryErrorEvent;

const
  oeBeforeDefault = FIBUpdateObject.oeBeforeDefault;
  oeAfterDefault = FIBUpdateObject.oeAfterDefault;

implementation

uses
  Classes;

initialization
  RegisterClassAlias(TFIBQuery, 'TpFIBQuery');
  RegisterClassAlias(TFIBUpdateObject, 'TpFIBUpdateObject');

end.
