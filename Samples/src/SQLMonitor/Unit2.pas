unit Unit2;

interface
{$I FIBPlus.Inc}
uses
  Windows, Messages, SysUtils, {$IFDEF D6+} Variants, {$ENDIF} Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, FIBSQLMonitor, ExtCtrls, StdCtrls;

type
  TForm2 = class(TForm)
    StatusBar1: TStatusBar;
    FIBSQLMonitor1: TFIBSQLMonitor;
    Panel1: TPanel;
    Label2: TLabel;
    Panel2: TPanel;
    Label1: TLabel;
    chkPrepare: TCheckBox;
    chkExecute: TCheckBox;
    chkFetch: TCheckBox;
    chkConnect: TCheckBox;
    chkTransact: TCheckBox;
    chkService: TCheckBox;
    chkMisc: TCheckBox;
    Panel3: TPanel;
    Label3: TLabel;
    Button1: TButton;
    Button2: TButton;
    Memo1: TMemo;
    Label4: TLabel;
    lblQty: TLabel;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FIBSQLMonitor1SQL(EventText: String; EventTime: TDateTime);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure chkPrepareClick(Sender: TObject);
    procedure chkExecuteClick(Sender: TObject);
    procedure chkFetchClick(Sender: TObject);
    procedure chkConnectClick(Sender: TObject);
    procedure chkTransactClick(Sender: TObject);
    procedure chkServiceClick(Sender: TObject);
    procedure chkMiscClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

var
  FSQLQty: Integer;

procedure TForm2.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := MessageDlg('This will end your "FIBPlus SQL Monitor" session. Proceed?',
    mtConfirmation, [mbOk, mbCancel], 0) = mrOk;
end;

procedure TForm2.FIBSQLMonitor1SQL(EventText: String;
  EventTime: TDateTime);
begin
  Memo1.Lines.Add(
    Format('%s >> %s', [DatetimeToStr(EventTime), EventText]));
  Inc(FSQLQty);
  lblQty.Caption := IntToStr(FSQLQty);
end;

procedure TForm2.Button1Click(Sender: TObject);
begin
  FIBSQLMonitor1.Active := not FIBSQLMonitor1.Active;
  if not FIBSQLMonitor1.Active then begin
    Button1.Caption := 'Start';
    Memo1.Lines.Add('Monitor Stoped at ' + DatetimeToStr(Now));
  end else begin
    Button1.Caption := 'Stop';
    FSQLQty := 0; lblQty.Caption := IntToStr(FSQLQty);
    Memo1.Lines.Add('Monitor Started at ' + DatetimeToStr(Now));
  end;
end;

procedure TForm2.Button2Click(Sender: TObject);
begin
  FSQLQty := 0; lblQty.Caption := IntToStr(FSQLQty);
  Memo1.Lines.Clear;
end;

procedure TForm2.chkPrepareClick(Sender: TObject);
begin
  if chkPrepare.Checked
  then FIBSQLMonitor1.TraceFlags := FIBSQLMonitor1.TraceFlags + [tfQPrepare]
  else FIBSQLMonitor1.TraceFlags := FIBSQLMonitor1.TraceFlags - [tfQPrepare];
end;

procedure TForm2.chkExecuteClick(Sender: TObject);
begin
  if chkPrepare.Checked
  then FIBSQLMonitor1.TraceFlags := FIBSQLMonitor1.TraceFlags + [tfQExecute]
  else FIBSQLMonitor1.TraceFlags := FIBSQLMonitor1.TraceFlags - [tfQExecute];
end;

procedure TForm2.chkFetchClick(Sender: TObject);
begin
  if TCheckBox(Sender).Checked
  then FIBSQLMonitor1.TraceFlags := FIBSQLMonitor1.TraceFlags + [tfQFetch]
  else FIBSQLMonitor1.TraceFlags := FIBSQLMonitor1.TraceFlags - [tfQFetch];
end;

procedure TForm2.chkConnectClick(Sender: TObject);
begin
  if TCheckBox(Sender).Checked
  then FIBSQLMonitor1.TraceFlags := FIBSQLMonitor1.TraceFlags + [tfConnect]
  else FIBSQLMonitor1.TraceFlags := FIBSQLMonitor1.TraceFlags - [tfConnect];
end;

procedure TForm2.chkTransactClick(Sender: TObject);
begin
  if TCheckBox(Sender).Checked
  then FIBSQLMonitor1.TraceFlags := FIBSQLMonitor1.TraceFlags + [tfTransact]
  else FIBSQLMonitor1.TraceFlags := FIBSQLMonitor1.TraceFlags - [tfTransact];
end;

procedure TForm2.chkServiceClick(Sender: TObject);
begin  
  if TCheckBox(Sender).Checked
  then FIBSQLMonitor1.TraceFlags := FIBSQLMonitor1.TraceFlags + [tfService]
  else FIBSQLMonitor1.TraceFlags := FIBSQLMonitor1.TraceFlags - [tfService];
end;

procedure TForm2.chkMiscClick(Sender: TObject);
begin
  if TCheckBox(Sender).Checked
  then FIBSQLMonitor1.TraceFlags := FIBSQLMonitor1.TraceFlags + [tfMisc]
  else FIBSQLMonitor1.TraceFlags := FIBSQLMonitor1.TraceFlags - [tfMisc];
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  FIBSQLMonitor1.Active := False;
  FIBSQLMonitor1.TraceFlags := [];
  Memo1.Lines.Clear;
end;

end.
