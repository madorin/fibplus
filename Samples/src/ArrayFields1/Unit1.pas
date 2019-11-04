unit Unit1;
interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
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
    Panel2: TPanel;
    DBGrid1: TDBGrid;
    Panel3: TPanel;
    GroupBox3: TGroupBox;
    DBMemo1: TDBMemo;
    GroupBox2: TGroupBox;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Edit5: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure dtAfterScroll(DataSet: TDataSet);
    procedure dtPostError(DataSet: TDataSet; E: EDatabaseError;
      var Action: TDataAction);
    procedure dtBeforePost(DataSet: TDataSet);
    procedure Edit1Change(Sender: TObject);
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
var
  FInShowArrays: Boolean;


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


procedure TForm1.dtAfterScroll(DataSet: TDataSet);
var v: Variant;
begin
  with dt do
  try
    FInShowArrays := true;
    v := ArrayFieldValue(FieldByName('LANGUAGE_REQ'));
    Edit1.Text := VarToStr(v[1]);
    Edit2.Text := VarToStr(v[2]);
    Edit3.Text := VarToStr(v[3]);
    Edit4.Text := VarToStr(v[4]);
    Edit5.Text := VarToStr(v[5]);
  finally
    FInShowArrays:=False;
  end;
end;

procedure TForm1.dtPostError(DataSet: TDataSet; E: EDatabaseError;
  var Action: TDataAction);
begin
  Action := daAbort;
  MessageDlg('DataSet Post Error!', mtError, [mbOk], 0);
  dt.Refresh;
end;

procedure TForm1.dtBeforePost(DataSet: TDataSet);
begin
  with dt do
    SetArrayValue(FieldByName('LANGUAGE_REQ'),
      VarArrayOf([
         Edit1.Text,
         Edit2.Text,
         Edit3.Text,
         Edit4.Text,
         Edit5.Text]));
end;

procedure TForm1.Edit1Change(Sender: TObject);
begin
  if (dt.State = dsBrowse) and (not FInShowArrays) then
  begin
    dt.Edit;
    dt.Fields[0].AsString := dt.Fields[0].AsString;
  end;
end;

end.
