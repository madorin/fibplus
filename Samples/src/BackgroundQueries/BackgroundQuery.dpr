program BackgroundQuery;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Unit2 in 'Unit2.pas' {ThreadSQLForm};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'BackgroundQueries';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
