unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, DB, FIBDataSet, FIBDatabase,
  ExtCtrls, StdCtrls, Grids, DBGrids, FIBQuery, SIBEABase,
  FIBEventAlerter;

type
  TForm1 = class(TForm)
    StatusBar1: TStatusBar;
    DB: TFIBDatabase;
    tr: TFIBTransaction;
    dt: TFIBDataSet;
    ds: TDataSource;
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    DBGrid1: TDBGrid;
    Button1: TButton;
    qryInsertSale: TFIBQuery;
    trInsertSale: TFIBTransaction;
    FIBEventAlerter1: TFIBEventAlerter;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Button1Click(Sender: TObject);
    procedure FIBEventAlerter1EventAlert(Sender: TObject; EventName: String; EventCount: Integer);
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
  DB.DBName := DemoDB;
{$IFDEF FBCLIENT.DLL}
  DB.LibraryName := 'fbclient.dll';
{$ENDIF}
  DB.Connected := True;
  dt.Open;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := MessageDlg('This will end your ' + QuotedStr(Caption) +
    ' session. Proceed?', mtConfirmation, [mbOk, mbCancel], 0) = mrOk;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  // CustNo, QantityPO, EmpNo: Integer;
  v: Variant;
const
  paramSql = 'select ' + '  (select first 1 cust_no from customer), ' +
    '  (select first 1 emp_no from employee), ' +
    '  (select count(*) from sales) ' + 'from rdb$database';
begin
  with qryInsertSale do
  begin
    v := DB.QueryValues(paramSql);
    ParamByName('PO_NUMBER').AsString := 'V' + '-XX-' + IntToStr(v[2]);
    ParamByName('CUST_NO').AsInteger := v[0];
    ParamByName('SALES_REP').AsInteger := v[1];
    ParamByName('QTY_ORDERED').AsInteger := 5;
    ParamByName('QTY_ORDERED').AsInteger := 5;
    ParamByName('TOTAL_VALUE').AsInteger := 2500;
    ExecQuery;
  end;
end;

procedure TForm1.FIBEventAlerter1EventAlert(Sender: TObject; EventName: String; EventCount: Integer);
// var inf: String;
begin
  ShowMessage(Format('Event received: %s (count: %d)', [EventName, EventCount]));
  if EventName = 'new_order' then
  begin
    if not MessageDlg('Added New Order. Refresh Sales Data?', mtConfirmation, [mbOk, mbCancel], 0) = mrOk then
      Exit;
    dt.FullRefresh;
  end;
end;

end.
