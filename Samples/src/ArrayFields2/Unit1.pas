unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, DB, FIBDataSet, pFIBDataSet, FIBDatabase, pFIBDatabase,
  ExtCtrls, StdCtrls, Grids, DBGrids, pFIBProps, DBCtrls, Mask;

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
    DBEdit1: TDBEdit;
    DBEdit2: TDBEdit;
    DBEdit3: TDBEdit;
    DBEdit4: TDBEdit;
    DBEdit5: TDBEdit;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure dtPostError(DataSet: TDataSet; E: EDatabaseError;
      var Action: TDataAction);
    procedure dtBeforePost(DataSet: TDataSet);
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
  dt.Open;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := MessageDlg('This will end your ' + QuotedStr(Caption) + ' session. Proceed?',
    mtConfirmation, [mbOk, mbCancel], 0) = mrOk;
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
    if (FBN('LR1').NewValue <> FBN('LR1').OldValue)
      or (FBN('LR2').NewValue <> FBN('LR2').OldValue)
      or (FBN('LR3').NewValue <> FBN('LR3').OldValue)
      or (FBN('LR4').NewValue <> FBN('LR4').OldValue)
      or (FBN('LR5').NewValue <> FBN('LR5').OldValue)
    then
      SetArrayValue(FBN('LANGUAGE_REQ'),
        VarArrayOf([
         FBN('LR1').AsString,
         FBN('LR2').AsString,
         FBN('LR3').AsString,
         FBN('LR4').AsString,
         FBN('LR5').AsString]));
end;

end.
