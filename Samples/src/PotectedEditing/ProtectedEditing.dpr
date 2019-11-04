program ProtectedEditing;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'ProtectedEdit';
  Application.HelpFile := 'D:\BORLAND\D7\Help\d7com.hlp';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
