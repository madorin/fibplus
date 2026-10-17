unit SIBFIBEA deprecated 'Use FIBEventAlerter (TFIBEventAlerter)';

interface

uses
  FIBEventAlerter;

type
  TSIBfibEventAlerter = TFIBEventAlerter deprecated 'Use TFIBEventAlerter';

implementation

uses
  Classes;

initialization
  RegisterClassAlias(TFIBEventAlerter, 'TSIBfibEventAlerter');

end.
