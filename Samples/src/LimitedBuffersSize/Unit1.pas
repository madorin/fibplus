unit Unit1;
                                                     
interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, DB, FIBDataSet, pFIBDataSet, FIBDatabase, pFIBDatabase,
  ExtCtrls, StdCtrls, Grids, DBGrids;

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
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    DBGrid1: TDBGrid;
    DBGrid2: TDBGrid;
    dtLim: TpFIBDataSet;
    dsLim: TDataSource;
    Button1: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure PageControl1Change(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses Unit2;

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
  PageControl1Change(nil);
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := MessageDlg('This will end your ' + QuotedStr(Caption) + ' session. Proceed?',
    mtConfirmation, [mbOk, mbCancel], 0) = mrOk;
end;

procedure TForm1.PageControl1Change(Sender: TObject);
begin
  if PageControl1.ActivePageIndex = 1 then begin
    if dt.Active then dt.Close;
    dtLim.Open;
  end else begin
    if dtLim.Active then dtLim.Close;
    dt.Open;
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  sCnt: string; iCnt: Integer;
begin
  sCnt := '1000000';
  if not InputQuery('Input record count',
    'record count for large table (recommended 500000 - 1000000)', sCnt)
  then Exit;
  try iCnt := StrToInt(sCnt)
  except
    ShowMessage('Enter valid integer value'); Exit;
  end;

  db.CloseDataSets;

  Form2 := TForm2.Create(Application);
  Form2.Show;
  try
    //deactivate indexes
    Form2.Label1.Caption := 'ALTER INDEX IDX_BIGTABLE_NAME INACTIVE';
    Application.ProcessMessages;
    db.Execute('ALTER INDEX IDX_BIGTABLE_NAME INACTIVE');

    Form2.Label1.Caption := 'ALTER INDEX IDX_BIGTABLE_NAME_DESC INACTIVE';
    Application.ProcessMessages;
    db.Execute('ALTER INDEX IDX_BIGTABLE_NAME_DESC INACTIVE');

    Form2.Label1.Caption := 'ALTER INDEX IDX_BIGTABLE_DETAIL_BIGTABLE_ID INACTIVE';
    Application.ProcessMessages;
    db.Execute('ALTER INDEX IDX_BIGTABLE_DETAIL_BIGTABLE_ID INACTIVE');

    //fill tables
    Form2.Label1.Caption := 'SELECT * FROM GEN_BIGTABLE_CONTENT(' + sCnt + ')';
    Application.ProcessMessages;
//    db.Execute('EXECUTE PROCEDURE GEN_BIGTABLE_CONTENT(' + sCnt + ')');
    Form2.dtGenData.Close;
    Form2.Stop:=False;
    Form2.dtGenData.Params[0].asString:=sCnt;
    Form2.lbProgress.Visible:=True;
    Form2.ProgressBar1.Visible:=True;
    Form2.dtGenData.Open;
    while not Form2.dtGenData.eof and not Form2.Stop do
     Form2.dtGenData.Next;
    Form2.dtGenData.Transaction.Commit;
    Form2.lbProgress.Visible:=False;
    Form2.ProgressBar1.Visible:=False;
    //activate indexes
    Form2.Label1.Caption := 'ALTER INDEX IDX_BIGTABLE_NAME ACTIVE';
    Application.ProcessMessages;
    db.Execute('ALTER INDEX IDX_BIGTABLE_NAME ACTIVE');

    Form2.Label1.Caption := 'ALTER INDEX IDX_BIGTABLE_NAME_DESC ACTIVE';
    Application.ProcessMessages;
    db.Execute('ALTER INDEX IDX_BIGTABLE_NAME_DESC ACTIVE');

    Form2.Label1.Caption := 'ALTER INDEX IDX_BIGTABLE_DETAIL_BIGTABLE_ID ACTIVE';
    Application.ProcessMessages;
    db.Execute('ALTER INDEX IDX_BIGTABLE_DETAIL_BIGTABLE_ID ACTIVE');
  finally
    Form2.Hide;
    Form2.Free;
  end;

  db.Close;
  db.Open;

  PageControl1Change(nil);
end;

end.
