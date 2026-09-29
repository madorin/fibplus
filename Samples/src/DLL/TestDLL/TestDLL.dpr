library TestDLL; 

uses
  SysUtils,
  Classes,
  SIBFIBEA,
  Dialogs,
  Unit1 in 'Unit1.pas' {Form1};

{$R *.res}

var // Added
    SIBfibEventAlerter: TSIBfibEventAlerter; // Added

begin
 SIBfibEventAlerter := TSIBfibEventAlerter.Create(Nil); // Added
// ShowMessage('Is I');
//----------------
// Hangs on this line
  SIBfibEventAlerter.Free; // Added
end.
