unit Unit1;
                                                     
interface

uses
  fib,
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, DB, FIBDataSet, pFIBDataSet, FIBDatabase, pFIBDatabase,
  ExtCtrls, StdCtrls, Grids, DBGrids, pFIBErrorHandler, pFIBSQLLog;

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
    Button1: TButton;
    cmbKindWork: TComboBox;
    Button2: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Button1Click(Sender: TObject);
    procedure dbAfterConnect(Sender: TObject);
    procedure dbAfterDisconnect(Sender: TObject);
    procedure cmbKindWorkChange(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private

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
begin
 with dt do try
  if not tr.Active then tr.StartTransaction;
  ApplyUpdToBase;
  tr.CommitRetaining;
  CommitUpdToCach
 except
   if tr.Active then tr.RollBack
 end;
end;

procedure TForm1.dbAfterConnect(Sender: TObject);
begin
  StatusBar1.Panels[0].Text:='Connected'
end;

procedure TForm1.dbAfterDisconnect(Sender: TObject);
begin
  StatusBar1.Panels[0].Text:='Offline'
end;

procedure TForm1.cmbKindWorkChange(Sender: TObject);
begin
  case cmbKindWork.ItemIndex of
   0: begin
       db.AutoReconnect:=True;
       db.Timeout :=300;
       if db.Connected then
        db.Connected :=False
      end;
   1: begin
       db.AutoReconnect:=False;
       db.Timeout :=0;
       if not db.Connected then
        db.Connected :=True
      end;
  end
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
 if dt.Active then dt.Close;
  dt.Open
end;

end.
