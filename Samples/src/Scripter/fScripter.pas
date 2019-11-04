unit fScripter;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, pFIBScripter, ImgList, ComCtrls, ToolWin,pFIBProps
  ;

type
  TForm3 = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    pFIBScripter1: TpFIBScripter;
    StatusBar1: TStatusBar;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ImageList1: TImageList;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    Memo1: TMemo;
    TreeView1: TTreeView;
    Splitter1: TSplitter;
    OpenDialog1: TOpenDialog;
    Panel2: TPanel;
    ProgressBar1: TProgressBar;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    Memo2: TMemo;
    procedure ToolButton1Click(Sender: TObject);
    procedure ToolButton3Click(Sender: TObject);
    procedure ToolButton4Click(Sender: TObject);
    procedure pFIBScripter1BeforeStatementExecute(Sender: TObject; Line,
      StatementNo: Integer; Desc: TStatementDesc; Statement: TStrings);
    procedure pFIBScripter1ExecuteError(Sender: TObject; StatementNo,
      Line: Integer; Statement: TStrings; SQLCode: Integer;
      const Msg: String; var doRollBack, Stop: Boolean);
    procedure TreeView1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ToolButton5Click(Sender: TObject);
    procedure ToolButton6Click(Sender: TObject);
  private
   procedure SelMemoText(PosBeg,PosEnd:TStmtCoord);
   procedure RefreshTree;
  public
    { Public declarations }
  end;

var
  Form3: TForm3;

implementation

{$R *.dfm}

procedure TForm3.RefreshTree;
var
   i: integer ;
   stmt:PStatementDesc;
   NodeObjectTypes: array [0..9] of TTreeNode;
begin
   pFIBScripter1.Script:=Memo1.Lines;
   pFIBScripter1.Parse;
   TreeView1.Items.BeginUpdate;
   TreeView1.Items.Clear;
   NodeObjectTypes[0]:=TreeView1.Items.Add(nil,'Database');
   NodeObjectTypes[1]:=TreeView1.Items.Add(nil,'Domains');
   NodeObjectTypes[2]:=TreeView1.Items.Add(nil,'Tables');
   NodeObjectTypes[3]:=TreeView1.Items.Add(nil,'Views');
   NodeObjectTypes[4]:=TreeView1.Items.Add(nil,'Procedures');
   NodeObjectTypes[5]:=TreeView1.Items.Add(nil,'Triggers');
   NodeObjectTypes[6]:=TreeView1.Items.Add(nil,'Generators');
   NodeObjectTypes[7]:=TreeView1.Items.Add(nil,'Exceptions');
   NodeObjectTypes[8]:=TreeView1.Items.Add(nil,'Functions');
   NodeObjectTypes[9]:=TreeView1.Items.Add(nil,'Indexes');   

   for i:=1 to pFIBScripter1.StatementsCount do
   begin
    stmt:=pFIBScripter1.GetStatement(i,nil);
    case stmt.objType of
     otDatabase:
      TreeView1.Items.AddChildObject(NodeObjectTypes[0],stmt.objName,stmt);

     otDomain:
      TreeView1.Items.AddChildObject(NodeObjectTypes[1],stmt.objName,stmt);
     otTable:
      TreeView1.Items.AddChildObject(NodeObjectTypes[2],stmt.objName,stmt);
     otView:
      TreeView1.Items.AddChildObject(NodeObjectTypes[3],stmt.objName,stmt);
     otTrigger:
      TreeView1.Items.AddChildObject(NodeObjectTypes[5],stmt.objName,stmt);
     otProcedure:
      TreeView1.Items.AddChildObject(NodeObjectTypes[4],stmt.objName,stmt);
     otGenerator:
      TreeView1.Items.AddChildObject(NodeObjectTypes[6],stmt.objName,stmt);
     otException:
      TreeView1.Items.AddChildObject(NodeObjectTypes[7],stmt.objName,stmt);
     otFunction:
      TreeView1.Items.AddChildObject(NodeObjectTypes[8],stmt.objName,stmt);
     otIndex:
      TreeView1.Items.AddChildObject(NodeObjectTypes[9],stmt.objName,stmt);
    end;
   end;
   TreeView1.Items.EndUpdate;
end;


procedure TForm3.ToolButton1Click(Sender: TObject);
begin
 if OpenDialog1.Execute then
  Memo1.Lines.LoadFromFile(OpenDialog1.FileName);
end;

procedure TForm3.ToolButton3Click(Sender: TObject);
begin
 RefreshTree
end;

procedure TForm3.ToolButton4Click(Sender: TObject);
begin
  ToolButton4.Enabled:=False;
  ToolButton5.Enabled:=True;
  try
    pFIBScripter1.Script:=Memo1.Lines;
    Panel2.Visible:=True;
    RefreshTree;
    pFIBScripter1.ExecuteScript;
    Panel2.Visible:=False;
    StatusBar1.Panels[0].Text:=''
  finally
   ToolButton4.Enabled:=True;
   ToolButton5.Enabled:=False;
  end
end;

procedure TForm3.pFIBScripter1BeforeStatementExecute(Sender: TObject; Line,
  StatementNo: Integer; Desc: TStatementDesc; Statement: TStrings);
begin
 StatusBar1.Panels[0].Text:='Execute Statement No '+IntToStr(StatementNo);
 ProgressBar1.Max:=pFIBScripter1.StatementsCount;
 ProgressBar1.Position:=StatementNo;
 Application.ProcessMessages
end;

procedure TForm3.pFIBScripter1ExecuteError(Sender: TObject; StatementNo,
  Line: Integer; Statement: TStrings; SQLCode: Integer; const Msg: String;
  var doRollBack, Stop: Boolean);
begin
 ShowMessage('Error in '#13#10+ Statement.Text)
end;



procedure TForm3.TreeView1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  MyHitTest : THitTests;
begin
  if not (ssDouble in Shift) then
   Exit;
  MyHitTest := TreeView1.GetHitTestInfoAt(X,Y);
  if htOnLabel in  MyHitTest then
  begin
    if Assigned(TreeView1.Selected) and Assigned(TreeView1.Selected.Data) then
    with PStatementDesc(TreeView1.Selected.Data)^ do
     SelMemoText(smdBegin,smdEnd)
  end;
end;

procedure TForm3.SelMemoText(PosBeg, PosEnd: TStmtCoord);
var
  I, SkipChars: Integer;
begin
  SkipChars := 0;
  for I := 0 to PosBeg.Y-1 do
  begin
     SkipChars := SkipChars + Length(Memo1.Lines[I])+2;
  end;

  Memo1.SelStart := SkipChars+PosBeg.X-1;
  Memo1.SelLength := 1;
  Memo1.SetFocus;  
  for I := PosBeg.Y to PosEnd.Y-1 do
  begin
     SkipChars := SkipChars + Length(Memo1.Lines[I])+2;
  end;
  SkipChars := SkipChars+PosEnd.X;
  Memo1.SelLength := SkipChars-Memo1.SelStart;
  Memo1.SetFocus;
end;

procedure TForm3.ToolButton5Click(Sender: TObject);
begin
 pFIBScripter1.Paused:=True;
end;

procedure TForm3.ToolButton6Click(Sender: TObject);
var i:integer;
    p:PStatementDesc;
begin
// pFIBScripter1.ExecuteFromFile('D:\Data\333.sql')
   pFIBScripter1.Script:=Memo1.Lines;
   pFIBScripter1.Parse;
   for i:=1 to pFIBScripter1.StatementsCount do
   begin
     p:=pFIBScripter1.GetStatement(i,Memo2.Lines);
     pFIBScripter1.ExecuteStatement(Memo2.Lines,p,i,Memo2.Lines);
   end;
end;

end.
