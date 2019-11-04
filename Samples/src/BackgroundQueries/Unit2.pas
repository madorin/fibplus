unit Unit2;

interface
{$I FIBPlus.Inc}
uses
  Windows, Messages, SysUtils, {$IFDEF D6+} Variants, {$ENDIF} Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Buttons, StdCtrls, Grids, DBGrids, DB, FIBDatabase,
  pFIBDatabase, FIBDataSet, pFIBDataSet;

type
  TThreadStatus=(tsWorking,tsEndSuccess,tsEndError);
  TThreadSQLForm = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    BitBtn1: TBitBtn;
    DBGrid1: TDBGrid;
    ds: TDataSource;
    dba: TpFIBDatabase;
    dt: TpFIBDataSet;
    tra: TpFIBTransaction;
    memSQL: TMemo;
    Label1: TLabel;
    Timer1: TTimer;
    Label2: TLabel;
    Label3: TLabel;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Timer1Timer(Sender: TObject);
  private
    FThreadActive:TThreadStatus;
    procedure SetThreadStatus(aThreadActive:TThreadStatus);
  public
    property  ThreadStatus:TThreadStatus read FThreadActive ;
  end;

  //
  procedure ShowBackgroundQuery(FormCaption: string; Qry: String;
    DBPath, UserName, Password: string);

implementation

{$R *.dfm}
{$I FIBExamples.inc}

const
  cTopStart  = 100;
  cTopDelta  = 25;
  cLeftStart = 100;
  cLeftDelta = 25;

var
  FTop, FLeft, MaxTop, MaxLeft: Word;

type
  TFIBQueryThread = class(TThread)
  private
    FQuery: TpFIBDataSet;
    FDataS: TDataSource;
    FQueryException: Exception;
    FForm:TThreadSQLForm;
    procedure HookUpUI;
    procedure QueryError;
    procedure StartSQL;    
  protected
    procedure Execute; override;
  public
    constructor Create(Q: TpFIBDataSet; D: TDataSource; Form:TThreadSQLForm); virtual;
    destructor  Destroy; override;
  end;

procedure TThreadSQLForm.FormShow(Sender: TObject);
begin
  if FLeft + cLeftDelta > MaxLeft
    then Left := cLeftStart else Left := FLeft + cLeftDelta;
  if FTop + cTopDelta > MaxTop
    then Top := cTopStart else Top := FTop + cTopDelta;
  FLeft := Left; FTop := Top;
end;

////////////////////////////////////////////////////////////////////////////////
procedure ShowBackgroundQuery(FormCaption: string; Qry: String; DBPath,
  UserName, Password: string);
var
  F: TThreadSQLForm;
begin
  F:=TThreadSQLForm.Create(Application);
  with F do begin
    Caption := FormCaption;
    with dba do begin
      DBName := DBPath;
      DBParams.Add(Format('user_name=%s',[UserName]));
      DBParams.Add(Format('password=%s',[Password]));
     {$IFDEF FBCLIENT.DLL}
      LibraryName:='fbclient.dll';
     {$ENDIF}

      Connected := True;
    end;
    with dt do begin
      Database := dba;
      dt.Transaction := tra;
      dt.UpdateTransaction := tra;
      SelectSQL.Clear;
      SelectSQL.Text := Qry;
    end;
    memSQL.Lines.Text := Qry;
    Label1.Caption:='Start Execute';
    Show;
    TFIBQueryThread.Create(dt, ds,F);
  end;
end;

procedure TThreadSQLForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

{ TFIBQueryThread }
////////////////////////////////////////////////////////////////////////////////
constructor TFIBQueryThread.Create(Q: TpFIBDataSet; D: TDataSource; Form:TThreadSQLForm);
begin
  inherited Create(True);
  FQuery:= Q; FDataS := D;
  FForm:=Form;
  FreeOnTerminate := True;
  Resume;
end;

destructor TFIBQueryThread.Destroy;
begin

  inherited;
end;

procedure TFIBQueryThread.Execute;
begin
  Synchronize(StartSQL);
  try
    FQuery.Open;
    Synchronize(HookUpUI);
  except
    FQueryException := ExceptObject as Exception;
    Synchronize(QueryError);
  end;
end;

procedure TFIBQueryThread.StartSQL;
begin
FForm.SetThreadStatus(tsWorking)
end;

procedure TFIBQueryThread.HookUpUI;
begin
  FDataS.DataSet := FQuery;
  FForm.SetThreadStatus(tsEndSuccess)
end;

procedure TFIBQueryThread.QueryError;
begin
  FForm.SetThreadStatus(tsEndError);
  Application.ShowException(FQueryException);
end;

procedure TThreadSQLForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
 CanClose:=FThreadActive<>tsWorking ;
 if not CanClose then
 begin
   if dba.IsFirebirdConnect and (dba.ServerMajorVersion>=2) then
   begin
    if (dba.ServerMinorVersion>=1) then
    begin
     if MessageDlg('Do You Want cancel Query?',
       mtConfirmation, [mbYes, mbNo], 0) = mrYes
     then
      if  (dba.ServerMinorVersion<5) then
       dba.CancelOperationFB21()
      else
      begin
        dba.RaiseCancelOperations
      end
    end
   end
   else
    ShowMessage('Sorry, I can''t cancel query'#13#10+
      'It support for FB2.1 and later Firebrird version'
    )

 end;
end;

procedure TThreadSQLForm.SetThreadStatus(aThreadActive: TThreadStatus);
begin
  FThreadActive:=aThreadActive;
  case aThreadActive of
   tsWorking: Label1.Caption:='SQL Executed';
   tsEndSuccess: Label1.Caption:='SQL success';
   tsEndError: Label1.Caption:='SQL error';
  end;
  if FThreadActive<> tsWorking then
   Timer1.Enabled:=False
end;

procedure TThreadSQLForm.Timer1Timer(Sender: TObject);
begin
 Label2.Caption:=IntToStr(StrToInt(Label2.Caption)+1)
end;

initialization
  FLeft := 100; FTop  := 100;
  MaxTop  := Screen.Height - 50;
  MaxLeft := Screen.Width  - 50;

end.
