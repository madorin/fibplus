program ArrayFields1;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Array Fields1';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
