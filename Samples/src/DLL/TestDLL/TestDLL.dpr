library TestDLL; 

uses
  SysUtils,
  Classes,
  SIBFIBEA,
  Dialogs,
  Unit1 in 'Unit1.pas' {Form1};

{$R *.res}

var // Добавлено
    SIBfibEventAlerter: TSIBfibEventAlerter; // Добавлено

begin
 SIBfibEventAlerter := TSIBfibEventAlerter.Create(Nil); // Добавлено
// ShowMessage('Is I');
//----------------
// На этой строчке - зависание
  SIBfibEventAlerter.Free; // Добавлено
end.
