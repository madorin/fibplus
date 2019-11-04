program LimitedBuffersSize;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Unit2 in 'Unit2.pas' {Form2};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'LimitedBuffersSize';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
