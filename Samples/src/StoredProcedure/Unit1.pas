unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, DB, FIBDataSet, FIBDatabase,
  ExtCtrls, StdCtrls, Grids, DBGrids, FIBQuery, FIBStoredProc;

type
  TForm1 = class(TForm)
    StatusBar1: TStatusBar;
    DB: TFIBDatabase;
    tr: TFIBTransaction;
    dtOrgChart: TFIBDataSet;
    dsOrgChart: TDataSource;
    Panel1: TPanel;
    Label1: TLabel;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    DBGrid1: TDBGrid;
    dtDept: TFIBDataSet;
    spSubTotalBudget: TFIBStoredProc;
    DBGrid2: TDBGrid;
    dsDept: TDataSource;
    Button1: TButton;
    Transaction1: TFIBTransaction;
    procedure FormCreate(Sender: TObject);
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

procedure TForm1.FormCreate(Sender: TObject);
begin
  Caption := 'FIBPlus Example - ' + Application.Title;
  DB.DBName := DemoDB;
{$IFDEF FBCLIENT.DLL}
  DB.LibraryName := 'fbclient.dll';
{$ENDIF}
  DB.Connected := True;

  dtOrgChart.Open;
  dtDept.Open;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := MessageDlg('This will end your ' + QuotedStr(Caption) +
    ' session. Proceed?', mtConfirmation, [mbOk, mbCancel], 0) = mrOk;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  with spSubTotalBudget do
  begin
    Params[0].AsString := dtDept.FBN('DEPT_NO').AsString;
    ExecProc;
    ShowMessageFmt('Total: %m'#10'Avg  : %m'#10'Min  : %m'#10'Max  : %m',
      [FieldByName('TOT_BUDGET').AsCurrency, FieldByName('AVG_BUDGET').AsCurrency, FieldByName('MIN_BUDGET').AsCurrency,
      FieldByName('MAX_BUDGET').AsCurrency]);
  end;
end;

end.
