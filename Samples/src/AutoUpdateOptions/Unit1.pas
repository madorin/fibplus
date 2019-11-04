unit Unit1;

interface
{$I FIBPlus.Inc}
uses
  Windows, Messages, SysUtils, {$IFDEF D6+} Variants, {$ENDIF}Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, DB, FIBDataSet, pFIBDataSet, FIBDatabase, pFIBDatabase,
  ExtCtrls, StdCtrls, Grids, DBGrids, pFIBProps, DBCtrls;

type
  TForm1 = class(TForm)
    StatusBar1: TStatusBar;
    db: TpFIBDatabase;
    tr: TpFIBTransaction;
    dt: TpFIBDataSet;
    ds: TDataSource;
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
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
  db.DBName := 'localhost:' + ExtractFileDir(Application.ExeName) + '\db\'+DemoDB;
  {$IFDEF FBCLIENT.DLL}
   db.LibraryName:='fbclient.dll';
  {$ENDIF}
  
  db.Connected := True;

  dt.SelectSQL.Text := 'SELECT * FROM EMPLOYEE';
//  dt.SelectSQL.Text := 'SELECT * FROM employee "emp"';
  dt.AutoUpdateOptions.AutoReWriteSqls := True;
  dt.AutoUpdateOptions.CanChangeSQLs   := True;
  dt.AutoUpdateOptions.UpdateOnlyModifiedFields := True;
  dt.AutoUpdateOptions.UpdateTableName := 'EMPLOYEE';
//  dt.AutoUpdateOptions.UpdateTableName := '"EMPLOYEE"';
  dt.AutoUpdateOptions.KeyFields       := 'EMP_NO';
  dt.AutoUpdateOptions.GeneratorName   := 'EMP_NO_GEN';
  dt.AutoUpdateOptions.WhenGetGenID    := wgBeforePost;

  dt.Open;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if not db.Connected then Exit;
  db.CloseDataSets;
  db.Close;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := MessageDlg('This will end your ' + QuotedStr(Caption) + ' session. Proceed?',
    mtConfirmation, [mbOk, mbCancel], 0) = mrOk;
end;

end.
