unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, DB, FIBDataSet, FIBDatabase,
  ExtCtrls, StdCtrls, Grids, DBGrids, FIBProps, FIBQuery;

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
    Label3: TLabel;
    DBGrid2: TDBGrid;
    dbOther: TFIBDatabase;
    dtOther: TFIBDataSet;
    dsOther: TDataSource;
    trOther: TFIBTransaction;
    Button1: TButton;
    Button2: TButton;
    trwrite: TFIBTransaction;
    trwriteOther: TFIBTransaction;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure ProtectedDatasetAfterCancel(DataSet: TDataSet);
    procedure ProtectedDataSetAfterPost(DataSet: TDataSet);
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
  dt.PrepareOptions := dt.PrepareOptions;
  Caption := 'FIBPlus Example - ' + Application.Title;
  DB.DBName := DemoDB;
{$IFDEF FBCLIENT.DLL}
  DB.LibraryName := 'fbclient.dll';
{$ENDIF}
  DB.Connected := True;
  dt.Open;
  dt.Options := dt.Options + [poUseSelectForLock];
  dbOther.DBName := DemoDB;
{$IFDEF FBCLIENT.DLL}
  dbOther.LibraryName := 'fbclient.dll';
{$ENDIF}
  dbOther.Connected := True;
  dtOther.Open;
  dtOther.Options := dtOther.Options + [poUseSelectForLock];
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if not DB.Connected then
    Exit;
  DB.CloseDataSets;
  DB.Close;

  dbOther.CloseDataSets;
  dbOther.Connected := False;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := MessageDlg('This will end your ' + QuotedStr(Caption) +
    ' session. Proceed?', mtConfirmation, [mbOk, mbCancel], 0) = mrOk;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  dt.Edit;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  if not dtOther.Locate('EMP_NO', dt.FBN('EMP_NO').AsInteger, []) then
  begin
    ShowMessage('Record not found in second connection');
    Exit;
  end;
  dtOther.Edit;
end;

procedure TForm1.ProtectedDatasetAfterCancel(DataSet: TDataSet);
begin
  if TFIBDataSet(DataSet).UpdateTransaction.InTransaction then
    TFIBDataSet(DataSet).UpdateTransaction.Rollback;
end;

procedure TForm1.ProtectedDataSetAfterPost(DataSet: TDataSet);
begin
  if TFIBDataSet(DataSet).UpdateTransaction.InTransaction then
    TFIBDataSet(DataSet).UpdateTransaction.Commit;
end;

end.
