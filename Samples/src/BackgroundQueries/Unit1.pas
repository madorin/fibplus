unit Unit1;
                                                        
interface
{$I FIBPlus.Inc}
uses
  Windows, Messages, SysUtils, {$IFDEF D6+} Variants, {$ENDIF} Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, DB, FIBDataSet, pFIBDataSet, FIBDatabase, pFIBDatabase,
  ExtCtrls, StdCtrls, Grids, DBGrids;

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
    Button2: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
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

uses Unit2, Math;

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

function RandomRange(const AFrom, ATo: Integer): Integer;
begin
  if AFrom > ATo then
    Result := Random(AFrom - ATo) + ATo
  else
    Result := Random(ATo - AFrom) + AFrom;
end;

procedure TForm1.Button1Click(Sender: TObject);
var i: Integer;
const
  sqls: array [1..5] of string = (
    'select * from employee',
    'select * from country',
    'select * from customer',
    'select * from project',
    'select * from department');
begin
  randomize;
  for i := 1 to RandomRange(2, 5) do
    ShowBackgroundQuery(
      'Query #' + IntToStr(i),
      sqls[i], db.DBName, 'sysdba', 'masterkey');
end;

procedure TForm1.Button2Click(Sender: TObject);
var
   sql:string;
begin
  sql:=
  'EXECUTE BLOCK AS'#$D#$A+
  'DECLARE VARIABLE A INTEGER;'#$D#$A+
  'BEGIN'#$D#$A+
  ' A=1;'#$D#$A+
  ' WHILE (A=1) DO'#$D#$A+
  '  A=A+0;'#$D#$A+
  'END';

  ShowBackgroundQuery(
      'Query #' ,
      sql, db.DBName, 'sysdba', 'masterkey');
end;

end.
