unit Unit1;
                                                        
interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, DB, FIBDataSet, pFIBDataSet, FIBDatabase, pFIBDatabase,
  ExtCtrls, StdCtrls, Grids, DBGrids, DBCtrls;

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
    dtCountry: TpFIBDataSet;
    dtDept: TpFIBDataSet;
    dsCountry: TDataSource;
    dsDept: TDataSource;
    DBLookupComboBox1: TDBLookupComboBox;
    Label3: TLabel;
    Label4: TLabel;
    DBLookupComboBox2: TDBLookupComboBox;
    Memo1: TMemo;
    Splitter1: TSplitter;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure DBLookupComboBox1CloseUp(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses FIBQuery;

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
  dtCountry.Open;
  dtDept.Open;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := MessageDlg('This will end your ' + QuotedStr(Caption) + ' session. Proceed?',
    mtConfirmation, [mbOk, mbCancel], 0) = mrOk;
end;

procedure TForm1.DBLookupComboBox1CloseUp(Sender: TObject);
var i: Integer;
begin
  with dt do begin
    DisableControls;
    try
      if dt.Active then Close;
      if Conditions.Count = 0 then begin
        Conditions.AddCondition('by_dept', 'EMP.DEPT_NO = :DEPT_NO', False);
        Conditions.AddCondition('by_country', 'EMP.JOB_COUNTRY = :COUNTRY', False);
      end;
      CancelConditions;
      Conditions.ByName('by_dept').Enabled :=
        (DBLookupComboBox2.Text <> '') and (DBLookupComboBox2.Text <> ' --- ALL ---');

      Conditions.ByName('by_country').Enabled :=
        (DBLookupComboBox1.Text <> '') and (DBLookupComboBox1.Text <> ' --- ALL ---');
      ApplyConditions;
      Prepare;
      for i := 0 to Params.Count - 1 do
        if Params[i].Name = 'DEPT_NO' then Params[i].Value := dtDept.FBN('F_1').Value
        else if Params[i].Name = 'COUNTRY' then Params[i].Value := dtCountry.FBN('F_1').Value;
      Open;

      Memo1.Lines.Text := QSelect.ReadySQLText;
    finally
      EnableControls;
    end;
  end;
end;

end.
