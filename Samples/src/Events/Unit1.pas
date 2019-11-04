unit Unit1;
                                                     
interface

uses
  Windows, Messages, SysUtils,  Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, DB, FIBDataSet, pFIBDataSet, FIBDatabase, pFIBDatabase,
  ExtCtrls, StdCtrls, Grids, DBGrids, FIBQuery, pFIBQuery, SIBEABase,
  SIBFIBEA;

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
    Button1: TButton;
    qryInsertSale: TpFIBQuery;
    trInsertSale: TpFIBTransaction;
    SIBfibEventAlerter1: TSIBfibEventAlerter;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Button1Click(Sender: TObject);
    procedure SIBfibEventAlerter1EventAlert(Sender: TObject;
      EventName: String; EventCount: Integer);
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
  dt.Open;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := MessageDlg('This will end your ' + QuotedStr(Caption) + ' session. Proceed?',
    mtConfirmation, [mbOk, mbCancel], 0) = mrOk;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
//  CustNo, QantityPO, EmpNo: Integer;
  v: Variant;
const
  paramSql =
  'select ' +
  '  (select first 1 cust_no from customer), ' +
  '  (select first 1 emp_no from employee), ' +
  '  (select count(*) from sales) ' +
  'from rdb$database';
begin
  with qryInsertSale do begin
    v := db.QueryValues(paramSQl);
    ParamByName('PO_NUMBER').AsString := 'V' + '-XX-' + IntToStr(v[2]);
    ParamByName('CUST_NO').AsInteger  := v[0];
    ParamByName('SALES_REP').AsInteger:= v[1];
    ParamByName('QTY_ORDERED').AsInteger:= 5;
    ParamByName('QTY_ORDERED').AsInteger:= 5;
    ParamByName('TOTAL_VALUE').AsInteger:= 2500;
    ExecQuery;
  end;
end;

procedure TForm1.SIBfibEventAlerter1EventAlert(Sender: TObject;
  EventName: String; EventCount: Integer);
//var inf: String;
begin
  ShowMessage(Format('Event received: %s (count: %d)', [EventName, EventCount]));
  if EventName = 'new_order' then begin
    if not MessageDlg('Added New Order. Refresh Sales Data?',
      mtConfirmation, [mbOk, mbCancel], 0) = mrOk then Exit;
    dt.FullRefresh;
  end;
end; 

end.
