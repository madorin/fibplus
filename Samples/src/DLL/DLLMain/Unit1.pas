unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, DB, FIBDataSet, pFIBDataSet, FIBDatabase, pFIBDatabase,
  ExtCtrls, StdCtrls, Grids, DBGrids, ibase;

type
  TForm1 = class(TForm)
    StatusBar1: TStatusBar;
    DB: TpFIBDatabase;
    tr: TpFIBTransaction;
    dt: TpFIBDataSet;
    ds: TDataSource;
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    DBGrid1: TDBGrid;
    Button1: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}
{$I FIBExamples.inc}

type
  TShowFormFromDLL = procedure(AppHandle: THandle; DBHandle: TISC_DB_HANDLE); stdcall;
  TDisconnectInDLL = procedure; stdcall;
  EDLLLoadError = class(Exception);

procedure TForm1.FormCreate(Sender: TObject);
begin
  Caption := 'FIBPlus Example - ' + Application.Title;
  DB.DBName := 'localhost:' + ExtractFileDir(Application.ExeName) + '\db\' + DemoDB;
{$IFDEF FBCLIENT.DLL}
  DB.LibraryName := 'fbclient.dll';
{$ENDIF}
  DB.Connected := True;

  dt.Open;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if not DB.Connected then
    Exit;
  DB.CloseDataSets;
  DB.Close;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := MessageDlg('This will end your ' + QuotedStr(Caption) +
    ' session. Proceed?', mtConfirmation, [mbOk, mbCancel], 0) = mrOk;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  DLLHandle: THandle;
  ShowFormFromDLL: TShowFormFromDLL;

  ExePath: string;
begin
  ExePath := ExtractFilePath(Application.ExeName);
  DLLHandle := LoadLibrary(PChar(ExePath + 'testdll.dll'));
  try
    if DLLHandle <= 0 then
      MessageDlg('Error loading ' + QuotedStr(ExePath + 'testdll.dll'), mtError, [mbOk], 0);

    @ShowFormFromDLL := GetProcAddress(DLLHandle, 'ShowFormFromDLL');

    if Assigned(ShowFormFromDLL) then
      ShowFormFromDLL(Application.Handle, DB.Handle)
    else
      MessageDlg('Error execute ShowFormFromDLL', mtError, [mbOk], 0);

  finally
    Application.ProcessMessages;
    FreeLibrary(DLLHandle);
  end;
end;

end.
