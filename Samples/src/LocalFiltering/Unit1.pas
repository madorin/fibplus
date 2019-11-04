unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, DB, FIBDataSet, pFIBDataSet, FIBDatabase, pFIBDatabase,
  ExtCtrls, StdCtrls, Grids, DBGrids, DBCtrls, IB_Services;

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
    trwrite: TpFIBTransaction;
    Panel2: TPanel;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    ComboBox1: TComboBox;
    Label3: TLabel;
    Edit1: TEdit;
    Label4: TLabel;
    chkIgnoreCase: TCheckBox;
    Button1: TButton;
    Button2: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure dtFilterRecord(DataSet: TDataSet; var Accept: Boolean);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
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
var i: Integer;
begin
  Caption := 'FIBPlus Example - ' + Application.Title;
  db.DBName := 'localhost:' + ExtractFileDir(Application.ExeName) + '\db\'+DemoDB;
  {$IFDEF FBCLIENT.DLL}
   db.LibraryName:='fbclient.dll';
  {$ENDIF}

  db.Connected := True;
  dt.Open;
  ComboBox1.Clear;
  for i := 0 to dt.Fields.Count - 1 do
    ComboBox1.Items.Add(dt.Fields[i].DisplayName);
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

procedure TForm1.dtFilterRecord(DataSet: TDataSet; var Accept: Boolean);
begin
  if chkIgnoreCase.Checked
  then Accept := DataSet.FieldByName(ComboBox1.Text).AsString = Edit1.Text
  else Accept := AnsiUpperCase(DataSet.FieldByName(ComboBox1.Text).AsString) =
    AnsiUpperCase(Edit1.Text);
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  if (Trim(ComboBox1.Text) = '') or (Trim(Edit1.Text) = '') then Exit;
  with dt do begin
    Filtered := False;
    Filter   := '';
    OnFilterRecord := nil;

    if RadioButton1.Checked
    then Filter := Format('[%s] = %s', [ComboBox1.Text, QuotedStr(Edit1.Text)])
    else OnFilterRecord := dtFilterRecord;

    if chkIgnoreCase.Checked then
      FilterOptions := FilterOptions + [foCaseInsensitive]; 

    Filtered := True;
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  dt.Filtered := False;
  dt.Filter   := '';
  dt.OnFilterRecord := nil;
end;

end.

