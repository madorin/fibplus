unit Unit1;
                                                     
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, DB, FIBDataSet, pFIBDataSet, FIBDatabase, pFIBDatabase,
  ExtCtrls, StdCtrls, Grids, DBGrids, Provider, DBClient;

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
    TntDBGrid1: TDBGrid;
    Panel2: TPanel;
    Label3: TLabel;
    Label4: TLabel;
    TntEdit1: TEdit;
    Label5: TLabel;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}
uses StrUtil,SqlTxtRtns;

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
  dt.Locate('UNICODE_STRING', TntEdit1.Text, []);
end;

procedure TForm1.Button2Click(Sender: TObject);
var v: variant;
begin
  v := db.QueryValue('select id from unicode_table where unicode_string = :str',
    0, [TntEdit1.Text]);
  if varIsNull(v) then Exit;
  dt.Locate('ID', v, []);
end;

procedure TForm1.Button3Click(Sender: TObject);
var v: variant;
begin
  v := db.QueryValue('select id from unicode_table where unicode_string = ' +
    '''' + TntEdit1.Text + '''', 0);

  if varIsNull(v) then Exit;
  dt.Locate('ID', v, []);
end;

end.
