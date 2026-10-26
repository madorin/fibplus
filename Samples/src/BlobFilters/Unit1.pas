unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, DB, FIBDataSet, pFIBDataSet, FIBDatabase, pFIBDatabase,
  ExtCtrls, StdCtrls, Grids, DBGrids, DBCtrls;

type
  TForm1 = class(TForm)
    StatusBar1: TStatusBar;
    DB: TpFIBDatabase;
    tr: TpFIBTransaction;
    dt: TpFIBDataSet;
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
procedure SetBuffer(var Buffer: Pointer; var BufSize: LongInt; Data: TMemoryStream);
begin
  ReallocMem(Buffer, Data.Size);
  Move(Data.Memory^, Buffer^, Data.Size);
  BufSize := Data.Size;
end;

procedure PackBuffer(var Buffer: Pointer; var BufSize: LongInt);
var
  Dst: TMemoryStream;
  Z: TCompressionStream;
begin
  Dst := TMemoryStream.Create;
  try
    Z := TCompressionStream.Create(clDefault, Dst);
    try
      Z.WriteBuffer(Buffer^, BufSize);
    finally
      Z.Free;
    end;
    SetBuffer(Buffer, BufSize, Dst);
  finally
    Dst.Free;
  end;
end;

procedure UnpackBuffer(var Buffer: Pointer; var BufSize: LongInt);
var
  Src, Dst: TMemoryStream;
  Z: TDecompressionStream;
  Chunk: array [0 .. 4095] of Byte;
  Count: Integer;
begin
  Src := TMemoryStream.Create;
  Dst := TMemoryStream.Create;
  try
    Src.WriteBuffer(Buffer^, BufSize);
    Src.Position := 0;
    Z := TDecompressionStream.Create(Src);
    try
      repeat
        Count := Z.Read(Chunk, SizeOf(Chunk));
        Dst.WriteBuffer(Chunk, Count);
      until Count = 0;
    finally
      Z.Free;
    end;
    SetBuffer(Buffer, BufSize, Dst);
  finally
    Src.Free;
    Dst.Free;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  DB.RegisterBlobFilter(-15, PIBBlobFilterProc(@PackBuffer), PIBBlobFilterProc(@UnpackBuffer));

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
