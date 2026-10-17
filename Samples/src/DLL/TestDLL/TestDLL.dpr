library TestDLL;

uses
  SysUtils,
  Classes,
  FIBEventAlerter,
  Dialogs,
  Unit1 in 'Unit1.pas' {Form1};

{$R *.res}

var // Added
  FIBEventAlerter: TFIBEventAlerter; // Added

begin
  FIBEventAlerter := TFIBEventAlerter.Create(Nil); // Added
  // ShowMessage('Is I');
  // ----------------
  // Hangs on this line
  FIBEventAlerter.Free; // Added

end.
