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

begin
  with dt do begin
    DisableControls;
    try
      if dt.Active then Close;
      ParamByName('COUNTRY').SetDefMacroValue;
      ParamByName('DEPT').SetDefMacroValue;
      if (DBLookupComboBox1.Text <> '') and (DBLookupComboBox1.Text <> ' --- ALL ---')
      then ParamByName('COUNTRY').AsString := 'EMP.JOB_COUNTRY = ' + QuotedStr(DBLookupComboBox1.Text);
      if (DBLookupComboBox2.Text = '') or (DBLookupComboBox2.Text = ' --- ALL ---')
      then ParamByName('DEPT').AsString := '';
      Prepare;
      if Assigned(FindParam('DEPT_NO')) then
        ParamByName('DEPT_NO').AsString := dtDept.FBN('F_1').AsString;
      Open;
      Close;
      Open;
      Memo1.Lines.Text := QSelect.ReadySQLText;
    finally
      EnableControls;
    end;
  end;
end;

end.
