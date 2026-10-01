unit Unit1;

interface

{$I FIBPlus.Inc}

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, DB, FIBDataSet, pFIBDataSet, FIBDatabase, pFIBDatabase,
  ExtCtrls, StdCtrls, Grids, DBGrids;

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
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
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

end.
