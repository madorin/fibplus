unit Unit1;
                                                     
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, DB, FIBDataSet, pFIBDataSet, FIBDatabase, pFIBDatabase,
  ExtCtrls, StdCtrls, Grids, DBGrids, DBCtrls, FIBQuery,
  pFIBQuery, pFIBSQLLog, Shellapi;

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
    Splitter1: TSplitter;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    DBMemo1: TDBMemo;
    DBMemo2: TDBMemo;
    Button1: TButton;
    pFIBQuery1: TpFIBQuery;
    pFIBDataSet1: TpFIBDataSet;
    FIBSQLLogger1: TFIBSQLLogger;
    dtID: TFIBIntegerField;
    dtAPP_ID: TFIBStringField;
    dtSQL_TEXT: TFIBBlobField;
    dtEXECUTECOUNT: TFIBIntegerField;
    dtPREPARECOUNT: TFIBIntegerField;
    dtSUMTIMEEXECUTE: TFIBIntegerField;
    dtAVGTIMEEXECUTE: TFIBIntegerField;
    dtMAXTIMEEXECUTE: TFIBIntegerField;
    dtMAXTIME_PARAMS: TFIBBlobField;
    dtLASTTIMEEXECUTE: TFIBIntegerField;
    dtLOG_DATE: TFIBDateTimeField;
    dtCMP_NAME: TFIBStringField;
    dtATTACHMENT_ID: TFIBIntegerField;
    Button2: TButton;
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

uses Math;

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

  FIBSQLLogger1.LogFileName := ExtractFileDir(Application.ExeName) + '\test.log';
  FIBSQLLogger1.ForceSaveLog:=True;
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

procedure TForm1.Button1Click(Sender: TObject);
const
  sqltexts: array [1..10] of string = (
  'select * from customer',
  'select * from employee',
  'select * from project',
  'select * from phone_list',
  'select * from department',
  'update customer set cust_no = cust_no where cust_no > 100',
  'update employee set emp_no = emp_no',
  'select * from org_chart',
  'select * from SUB_TOT_BUDGET(''000'')',
  'select * from SALARY_HISTORY');
var i, x: Integer; sqltxt: String;
begin
  Randomize;
  FIBSQLLogger1.ActiveStatistics := True;
  FIBSQLLogger1.ActiveLogging := True;
  for i := 1 to 30 do begin
    x := RandomRange(1, 10);
    sqltxt := sqltexts[x];
    if pFIBDataSet1.Active then pFIBDataSet1.Close;
    if pos('update', sqltxt) > 0 then begin
      pFIBQuery1.SQL.Text := sqltxt;
      pFIBQuery1.ExecQuery;
    end else begin
      pFIBDataSet1.SelectSQL.Text := sqltxt;
      pFIBDataSet1.Open;
    end;
  end;
  FIBSQLLogger1.ActiveStatistics := False;
  FIBSQLLogger1.ActiveLogging := False;
  FIBSQLLogger1.SaveStatisticsToDB(1);
  FIBSQLLogger1.SaveLog;
  dt.FullRefresh;
end;

end.
