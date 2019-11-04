unit Unit1;
                                                     
interface

uses
  fib,
  Windows, Messages, SysUtils,  Classes, Graphics, Controls, Forms,
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
    Label2: TLabel;
    DBGrid1: TDBGrid;
    pFibErrorHandler1: TpFibErrorHandler;
    Panel2: TPanel;
    Label5: TLabel;
    cmbKindOnLost: TComboBox;
    Label3: TLabel;
    Label4: TLabel;
    Button1: TButton;
    Button2: TButton;
    dtEMP_NO: TFIBSmallIntField;
    dtFIRST_NAME: TFIBStringField;
    dtLAST_NAME: TFIBStringField;
    dtPHONE_EXT: TFIBStringField;
    dtHIRE_DATE: TFIBDateTimeField;
    dtDEPT_NO: TFIBStringField;
    dtJOB_CODE: TFIBStringField;
    dtJOB_GRADE: TFIBSmallIntField;
    dtJOB_COUNTRY: TFIBStringField;
    dtSALARY: TFIBBCDField;
    dtFULL_NAME: TFIBStringField;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure dbAfterRestoreConnect(Database: TFIBDatabase);
    procedure dbErrorRestoreConnect(Database: TFIBDatabase; E: EFIBError;
      var Actions: TOnLostConnectActions);
    procedure dbLostConnect(Database: TFIBDatabase; E: EFIBError;
      var Actions: TOnLostConnectActions);
    procedure pFibErrorHandler1FIBErrorEvent(Sender: TObject;
      ErrorValue: EFIBError; KindIBError: TKindIBError;
      var DoRaise: Boolean);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    AttemptRest: Integer;
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
  cmbKindOnLost.ItemIndex:=0;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := MessageDlg('This will end your ' + QuotedStr(Caption) + ' session. Proceed?',
    mtConfirmation, [mbOk, mbCancel], 0) = mrOk;
end;

procedure TForm1.dbAfterRestoreConnect(Database: TFIBDatabase);
begin
  MessageDlg('Connection restored. You can apply cached updates',
       mtInformation, [mbOk], 0
  );
  Label4.Visible:=false;
  Label3.Visible:=false; 
end;

procedure TForm1.dbErrorRestoreConnect(Database: TFIBDatabase;
  E: EFIBError; var Actions: TOnLostConnectActions);
begin
  Inc(AttemptRest);
  Label4.Caption:=IntToStr(AttemptRest);
  Label4.Refresh
end;

procedure TForm1.dbLostConnect(Database: TFIBDatabase; E: EFIBError;
  var Actions: TOnLostConnectActions);
begin
  case cmbKindOnLost.ItemIndex of
   0: begin
       Actions := laCloseConnect;
       MessageDlg('Connection lost. TpFIBDatabase will be closed!',
        mtInformation, [mbOk], 0
       );
      end;
   1:begin
      Actions := laTerminateApp;
      MessageDlg('Connection lost. Application will be closed!',
       mtInformation, [mbOk], 0
      );
     end;
   2:Actions := laWaitRestore;
  end;
end;

procedure TForm1.pFibErrorHandler1FIBErrorEvent(Sender: TObject;
  ErrorValue: EFIBError; KindIBError: TKindIBError; var DoRaise: Boolean);
begin
  Label4.Visible:=true;
  Label3.Visible:=true;
  if KindIBError = keLostConnect then begin
    DoRaise := false;
//    Abort;
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  with dt do try
  if not Database.Connected then begin
   try
    DataBase.Connected:=true
   except
    MessageDlg('Can''t restore connect',
       mtInformation, [mbOk], 0
    );
    Exit
   end
  end;
  if not tr.Active then tr.StartTransaction;
  ApplyUpdToBase;
  tr.CommitRetaining;
  CommitUpdToCach
 except
   if tr.Active then tr.RollBack
 end;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  db.Close;
end;


end.
