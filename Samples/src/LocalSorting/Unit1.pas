unit Unit1;

interface
{$I FIBPlus.Inc}
uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, DBGrids, Db, FIBDatabase, pFIBDatabase, FIBDataSet, pFIBDataSet,
  StdCtrls, ComCtrls, ExtCtrls;

type

  TOrderStringList = class(TStringList)
  protected
    function GetAscending(Index: Integer): boolean;
    procedure SetAscending (Index: Integer; Value: boolean);
  public
    property Ascending[Index: Integer]: boolean read GetAscending write SetAscending;
  end;

  TForm1 = class(TForm)
    Button1: TButton;
    Panel1: TPanel;
    Label1: TLabel;
    Label3: TLabel;
    DBGrid1: TDBGrid;
    StatusBar1: TStatusBar;
    db: TpFIBDatabase;
    tr: TpFIBTransaction;
    ds: TDataSource;
    dt: TpFIBDataSet;
    Button2: TButton;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    procedure DBGrid1TitleClick(Column: TColumn);
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure RadioButton1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    SortFields: TOrderStringList;
    procedure ReSort;
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}
{$I FIBExamples.inc}

{ TOrderStringList }

function TOrderStringList.GetAscending(Index: Integer): boolean;
begin
  Result := boolean(integer(Objects[Index]));
end;

procedure TOrderStringList.SetAscending(Index: Integer; Value: boolean);
begin
  Objects[Index] := pointer(integer(Value));
end;

{ TMainForm }
procedure TForm1.DBGrid1TitleClick(Column: TColumn);
const OrderStr: array [boolean] of string = ('(DESC)', '(ASC)');
var aField: string;
    aFieldIndex: integer;
begin
  aField := Column.FieldName;
  aFieldIndex := SortFields.IndexOf(aField);

  if aFieldIndex = -1 then begin
    SortFields.Add(aField);
    SortFields.Ascending[SortFields.Count - 1] := true;

    Column.Field.DisplayLabel := Column.Field.FieldName + OrderStr[true];
  end
  else begin
    SortFields.Ascending[aFieldIndex] := not SortFields.Ascending[aFieldIndex];

    Column.Field.DisplayLabel := Column.Field.FieldName +
       OrderStr[SortFields.Ascending[aFieldIndex]];
  end;
  ReSort;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Caption := 'FIBPlus Example - ' + Application.Title;
  db.DBName := 'localhost:' + ExtractFileDir(Application.ExeName) + '\db\'+DemoDB;
  {$IFDEF FBCLIENT.DLL}
   db.LibraryName:='fbclient.dll';
  {$ENDIF}
  
  db.Connected := True;

  dt.OnCompareFieldValues := dt.StdAnsiCompareString;
  dt.Open;

  SortFields := TOrderStringList.Create;
end;

procedure TForm1.ReSort;
var Orders: array of boolean;
    Index: Integer;
begin
  if SortFields.Count = 0 then begin
    dt.CloseOpen(false);
    exit;
  end;

  SetLength(Orders, SortFields.Count);

  for Index := 0 to pred(SortFields.Count) do
     Orders[Index] := SortFields.Ascending[Index];

  dt.DoSortEx(SortFields, Orders);
end;

procedure TForm1.Button1Click(Sender: TObject);
var aField: string;
    aFieldIndex: integer;
begin
  aField := DBGrid1.SelectedField.FieldName;
  aFieldIndex := SortFields.IndexOf(aField);

  if aFieldIndex <> -1 then begin
    SortFields.Delete(aFieldIndex);
    DBGrid1.SelectedField.DisplayLabel := aField;
    ReSort;
  end;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := MessageDlg('This will end your ' + QuotedStr(Caption) + ' session. Proceed?',
    mtConfirmation, [mbOk, mbCancel], 0) = mrOk;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if not db.Connected then Exit;
  SortFields.Free;
end;

procedure TForm1.RadioButton1Click(Sender: TObject);
begin
  dt.Close;
  if RadioButton1.Checked
  then dt.OnCompareFieldValues := nil
  else dt.OnCompareFieldValues := dt.StdAnsiCompareString;
  dt.Open;
end;

end.
