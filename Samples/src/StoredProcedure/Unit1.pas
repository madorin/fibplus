unit Unit1;
                                                     
interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, DB, FIBDataSet, pFIBDataSet, FIBDatabase, pFIBDatabase,
  ExtCtrls, StdCtrls, Grids, DBGrids, FIBQuery, pFIBQuery, pFIBStoredProc;

type
  TForm1 = class(TForm)
    StatusBar1: TStatusBar;
    db: TpFIBDatabase;
    tr: TpFIBTransaction;
    dtOrgChart: TpFIBDataSet;
    dsOrgChart: TDataSource;
    Panel1: TPanel;
    Label1: TLabel;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    DBGrid1: TDBGrid;
    dtDept: TpFIBDataSet;
    spSubTotalBudget: TpFIBStoredProc;
    DBGrid2: TDBGrid;
    dsDept: TDataSource;
    Button1: TButton;
    pFIBTransaction1: TpFIBTransaction;
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
  db.DBName := 'localhost:' + ExtractFileDir(Application.ExeName) + '\db\'+DemoDB;
  {$IFDEF FBCLIENT.DLL}
   db.LibraryName:='fbclient.dll';
  {$ENDIF}

  db.Connected := True;

  dtOrgChart.Open;
  dtDept.Open;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := MessageDlg('This will end your ' + QuotedStr(Caption) + ' session. Proceed?',
    mtConfirmation, [mbOk, mbCancel], 0) = mrOk;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  with spSubTotalBudget do begin
    Params[0].AsString := dtDept.FBN('DEPT_NO').AsString;
    ExecProc;
    ShowMessageFmt('Total: %m'#10'Avg  : %m'#10'Min  : %m'#10'Max  : %m',
      [FieldByName('TOT_BUDGET').AsCurrency, FieldByName('AVG_BUDGET').AsCurrency,
       FieldByName('MIN_BUDGET').AsCurrency, FieldByName('MAX_BUDGET').AsCurrency]);
  end;
end;

end.
