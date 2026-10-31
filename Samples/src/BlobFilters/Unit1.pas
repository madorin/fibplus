unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, DB, FIBDataSet, FIBDatabase,
  ExtCtrls, StdCtrls, Grids, DBGrids, DBCtrls;

type
  TForm1 = class(TForm)
    StatusBar1: TStatusBar;
    DB: TFIBDatabase;
    tr: TFIBTransaction;
    dt: TFIBDataSet;
    ds: TDataSource;
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    DBGrid1: TDBGrid;
    Panel2: TPanel;
    DBMemo1: TDBMemo;
    Button1: TButton;
    OpenDialog1: TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses
  IBBlobFilter, ZLib;

{$I FIBExamples.inc}

// The library passes the buffer pointer and frees the buffer with FreeMem
procedure PackBuffer(var Buffer: Pointer; var BufSize: LongInt);
var
  Data: Pointer;
  Size: Integer;
begin
  ZCompress(Buffer, BufSize, Data, Size);
  FreeMem(Buffer);
  Buffer := Data;
  BufSize := Size;
end;

procedure UnpackBuffer(var Buffer: Pointer; var BufSize: LongInt);
var
  Data: Pointer;
  Size: Integer;
begin
  ZDecompress(Buffer, BufSize, Data, Size);
  FreeMem(Buffer);
  Buffer := Data;
  BufSize := Size;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  DB.RegisterBlobFilter(-15, PFIBBlobFilterProc(@PackBuffer), PFIBBlobFilterProc(@UnpackBuffer));

  Caption := 'FIBPlus Example - ' + Application.Title;
  DB.DBName := DemoDB;
{$IFDEF FBCLIENT.DLL}
  DB.LibraryName := 'fbclient.dll';
{$ENDIF}
  DB.Connected := True;
  dt.Open;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := MessageDlg('This will end your ' + QuotedStr(Caption) +
    ' session. Proceed?', mtConfirmation, [mbOk, mbCancel], 0) = mrOk;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  if not OpenDialog1.Execute then
    Exit;
  dt.Append;
  dt.FBN('NAME').AsString := OpenDialog1.FileName;
  TBlobField(dt.FBN('BLOBDATA')).LoadFromFile(OpenDialog1.FileName);
  dt.Post;
end;

end.
