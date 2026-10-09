unit pFIBScripter;

{$MESSAGE WARN 'Unit pFIBScripter is deprecated, use FIBScripter (TFIBScripter)'}

interface

uses
  FIBScripter;

type
  TpFIBScripter = TFIBScripter deprecated 'Use TFIBScripter';
  TpFIBScriptParser = TFIBScriptParser deprecated 'Use TFIBScriptParser';

implementation

uses
  Classes;

initialization
  RegisterClassAlias(TFIBScripter, 'TpFIBScripter');

end.
