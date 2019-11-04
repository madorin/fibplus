unit Unit1;
                                                     
interface

uses
  fib,
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, DB, FIBDataSet, pFIBDataSet, FIBDatabase, pFIBDatabase,
  ExtCtrls, StdCtrls, Grids, DBGrids, pFIBErrorHandler, pFIBSQLLog,
  FIBQuery, pFIBQuery;

type
  TForm1 = class(TForm)
    StatusBar1: TStatusBar;
    db: TpFIBDatabase;
    tr: TpFIBTransaction;
    dt: TpFIBDataSet;
    ds: TDataSource;
    Panel1: TPanel;
    Label1: TLabel;
    DBGrid1: TDBGrid;
    Panel2: TPanel;
    Button2: TButton;
    cmbKindRefresh: TComboBox;
    qryExactRefresh: TpFIBQuery;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Button2Click(Sender: TObject);
    procedure dtBeforeOpen(DataSet: TDataSet);
  private
    FLastVersionFetch:TDateTime;
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
  dt.Open;

end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := MessageDlg('This will end your ' + QuotedStr(Caption) + ' session. Proceed?',
    mtConfirmation, [mbOk, mbCancel], 0) = mrOk;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  case cmbKindRefresh.ItemIndex of
   0: begin
       dt.Refresh;
       ShowMessage('Fetched 1 record')
      end;
   1: begin
       dt.FullRefresh;
       ShowMessage('Fetched '+IntToStr(dt.RecordCount)+' records')
      end;
   2: begin
       qryExactRefresh.Params[0].asDateTime:=FLastVersionFetch;
       dt.RefreshFromQuery(qryExactRefresh,'ID');
       if qryExactRefresh.RecordCount>0 then
        FLastVersionFetch:=qryExactRefresh.FieldByName('LAST_UPDATE').Value;
       ShowMessage('Fetched '+IntToStr(qryExactRefresh.RecordCount)+' records')
      end
  end
end;

procedure TForm1.dtBeforeOpen(DataSet: TDataSet);
begin
  //
  FLastVersionFetch:=db.QueryValue('Select MAX(LAST_UPDATE) from BIGTABLE',0,tr)
end;

end.
