program Scripter;

uses
  Forms,
  fScripter in 'fScripter.pas' {Form3};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm3, Form3);
  Application.Run;
end.
