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
uses IBBlobFilter,zStream
//, DIUclStreams
;

{$I FIBExamples.inc}



{
function UclCompressStream(const AInStream, AOutStream: TStream;
   const ACompressionLevel: Integer = 10;
   const ABufferSize: Cardinal = $1000;
   const AOnProgress: TUclProgress = nil;
   const AUser: Pointer = nil): Boolean;

function UclDeCompressStream(const AInStream, AOutStream: TStream;
   const ABufferSize: Cardinal = $1000;
   const AOnProgress: TUclProgress = nil;
   const AUser: Pointer = nil): Boolean;
}

procedure PackBuffer(var Buffer: PChar; var BufSize: LongInt);
var srcStream, dstStream: TStream;
begin
  srcStream := TMemoryStream.Create;
  dstStream := TMemoryStream.Create;
  try
    srcStream.WriteBuffer(Buffer^, BufSize);
    srcStream.Position := 0;
//    UclCompressStream(srcStream, dstStream);
    GZipStream(srcStream, dstStream, 6);
    srcStream.Free;
    srcStream := nil;
    BufSize := dstStream.Size;
    dstStream.Position := 0;
    ReallocMem(Buffer, BufSize);
    dstStream.ReadBuffer(Buffer^, BufSize);
  finally
    if Assigned(srcStream) then srcStream.Free;
    dstStream.Free;
  end;
end;

procedure UnpackBuffer(var Buffer: PChar; var BufSize: LongInt);
var srcStream,dstStream: TStream;
begin
  srcStream := TMemoryStream.Create;
  dstStream := TMemoryStream.Create;
  try
    srcStream.WriteBuffer(Buffer^, BufSize);
    srcStream.Position := 0;
//    UclDeCompressStream(srcStream, dstStream);
    GunZipStream(srcStream, dstStream);
    srcStream.Free;
    srcStream:=nil;
    BufSize := dstStream.Size;
    dstStream.Position := 0;
    ReallocMem(Buffer, BufSize);
    dstStream.ReadBuffer(Buffer^, BufSize);
  finally
    if assigned(srcStream) then srcStream.Free;
    dstStream.Free;
  end;
end;


procedure TForm1.FormCreate(Sender: TObject);
begin
  db.RegisterBlobFilter(-15, @PackBuffer, @UnpackBuffer);

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
