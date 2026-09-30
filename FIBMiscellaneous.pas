{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ InterBase databases                                           }
{                                                               }
{    FIBPlus is based in part on the product                    }
{    Free IB Components, written by Gregory H. Deatz for        }
{    Hoagland, Longo, Moran, Dunst & Doukas Company.            }
{    mailto:gdeatz@hlmdd.com                                    }
{                                                               }
{    Copyright (c) 1998-2013 Devrace Ltd.                       }
{    Written by Serge Buzadzhy (buzz@devrace.com)               }
{                                                               }
{ ------------------------------------------------------------- }
{    FIBPlus home page: http://www.fibplus.com/                 }
{    FIBPlus support  : http://www.devrace.com/support/         }
{ ------------------------------------------------------------- }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}


unit FIBMiscellaneous;


interface

{$I FIBPlus.inc}
uses
 {$IFDEF WINDOWS}
   Windows, // For Inline functions
 {$ENDIF}

  SysUtils,SyncObjs, Classes, ibase,IB_Intf,IB_Externals,
  DB, fib, FIBDatabase, FIBQuery, StdFuncs,IB_ErrorCodes,FIBPlatforms
  {$IFDEF SUPPORT_ARRAY_FIELD}, pFIBArray{$ENDIF};

const
  DefaultBlobSegmentSize = High(Word);

type
  // Value of a BLOB or ARRAY field of a record, kept on the client between reads and writes
  // until it is stored on the server (at Post). Descendants load and store the value.
  TFIBFieldStream = class(TStream)
  protected
    FDatabase: TFIBDatabase;
    FTransaction: TFIBTransaction;
    FUpdateTransaction: TFIBTransaction;
    FBlobID: TISC_QUAD;
    FBuffer: PAnsiChar;
    FDataSize: Long;
    FOldBuffer: PAnsiChar;
    FOldDataSize: Long;
    FInitialized: Boolean;
    FMode: TBlobStreamMode;
    FModified: Boolean;
    FPosition: Long;
    FStreamList: TList;
    FIndexInList: Integer;
    FFieldNo: Integer;
    FNeedSaveOldBuffer: Boolean;
    FIsClientField: Boolean;
    procedure DoOnDatabaseFree(Sender: TObject);
    // Reads the value with FBlobID from the server into the buffer
    procedure Load(CallBack: TCallBackBlobReadWrite); virtual; abstract;
    // Writes the buffer to the server as a new value, FBlobID gets its ID
    procedure Store(CallBack: TCallBackBlobReadWrite); virtual; abstract;
    procedure DoAfterInitialize; virtual;
    procedure CreateEmpty;
    procedure EnsureInitialized(CallBack: TCallBackBlobReadWrite = nil);
    function GetDatabase: TFIBDatabase;
    function GetDBHandle: PISC_DB_HANDLE;
    function GetTransaction: TFIBTransaction;
    function GetUpdateTransaction: TFIBTransaction;
    function GetTRHandle: PISC_TR_HANDLE;
    function GetUpdateTRHandle: PISC_TR_HANDLE;
    procedure CheckHandles(ReadTransaction: Boolean = True);
    procedure SetBlobID(const Value: TISC_QUAD);
    procedure ReplaceBlobID(const Value: TISC_QUAD); virtual;
    procedure SetDatabase(Value: TFIBDatabase);
    procedure SetMode(Value: TBlobStreamMode);
    procedure SetTransaction(Value: TFIBTransaction);
    procedure SetUpdateTransaction(Value: TFIBTransaction);
    procedure SaveOldBuffer;
  public
    constructor CreateNew(AFieldNo: Integer; AStreamList: TList);
    destructor Destroy; override;
    function Call(ErrCode: ISC_STATUS; RaiseError: Boolean): ISC_STATUS;
    procedure CheckReadable;
    procedure CheckWritable;
    procedure DoFinalize(ClearModified, ForceWrite: Boolean;
      CallBack: TCallBackBlobReadWrite = nil); virtual;
    procedure Finalize;
    procedure Cancel;
    procedure FreeOldBuffer;
    procedure DeInitialize;
    function Read(var Buffer; Count: Longint): Longint; override;
    function ReadOldBuffer(var Buffer; Count: Longint): Longint;
    function Seek(Offset: Longint; Origin: Word): Longint; override;
    function DoSeek(Offset: Longint; Origin: Word; CallBack: TCallBackBlobReadWrite): Longint;
    function SeekInOldBuffer(Offset: Longint; Origin: Word): Longint;
    procedure SetSize(NewSize: Long); override;
    procedure Truncate;
    function Write(const Buffer; Count: Longint): Longint; override;
    // ARRAY values are stored as blobs too, their IDs are blob IDs
    property BlobID: TISC_QUAD read FBlobID write SetBlobID;
    property Database: TFIBDatabase read GetDatabase write SetDatabase;
    property DBHandle: PISC_DB_HANDLE read GetDBHandle;
    property Mode: TBlobStreamMode read FMode write SetMode;
    property Modified: Boolean read FModified;
    property Transaction: TFIBTransaction read GetTransaction write SetTransaction;
    property UpdateTransaction: TFIBTransaction read GetUpdateTransaction write SetUpdateTransaction;
    property TRHandle: PISC_TR_HANDLE read GetTRHandle;
    property UpdateTRHandle: PISC_TR_HANDLE read GetUpdateTRHandle;
    property FieldNo: Integer read FFieldNo;
    property IndexInList: Integer read FIndexInList;
    property IsClientField: Boolean read FIsClientField write FIsClientField;
  end;

  (* TFIBBlobStream *)
  TFIBBlobStream = class(TFIBFieldStream)
  private
    FBlobMaxSegmentSize: Long;
    FBlobNumSegments: Long;
    FBlobType: Short;              // 0 = segmented, 1 = streamed.
    FBlobSubType: Long;
    FBlobHandle: TISC_BLOB_HANDLE;
    FTableName: AnsiString;
    FFieldName: AnsiString;
    FKeyValues: TDynArray;
    FLoadedFromCache: Boolean;
    FCharSet: Integer;
    function GetRecKeyValuesAsStr: string;
  protected
    procedure Load(CallBack: TCallBackBlobReadWrite); override;
    procedure Store(CallBack: TCallBackBlobReadWrite); override;
    procedure DoAfterInitialize; override;
    procedure GetBlobInfo;
    procedure OpenBlob(CallBack: TCallBackBlobReadWrite = nil);
    procedure ReplaceBlobID(const Value: TISC_QUAD); override;
    function GetAsString: AnsiString;
    function GetAsWideString: WideString;
  public
    constructor CreateNew(AFieldNo: Integer; AStreamList: TList;
      const ATableName: string = ''; const AFieldName: string = '';
      PKeyValues: PDynArray = nil); reintroduce;
    constructor Create;
    procedure InternalSetCharSet(Value: Integer); // Internal Use only
    destructor Destroy; override;
    procedure DoFinalize(ClearModified, ForceWrite: Boolean;
      CallBack: TCallBackBlobReadWrite = nil); override;
    procedure CloseBlob;
    function LoadFromFile(const FileName: string; IsCacheFile: Boolean = False): Boolean;
    function LoadFromStream(Stream: TStream; IsCacheStream: Boolean = False): Boolean;
    function GenerateSwapFileName(ForceDir: Boolean): string;
    procedure SaveToSwapFile;
    procedure SaveToFile(const FileName: string; FullInfo: Boolean = False);
    procedure SaveToStream(Stream: TStream; IsCacheStream: Boolean = False);
    // For big blobs
    function FileToBlob(const FileName: string; CallBack: TCallBackBlobReadWrite = nil): TISC_QUAD;
    procedure BlobToFile(const FileName: string; CallBack: TCallBackBlobReadWrite = nil);
    property BlobInitialized: Boolean read FInitialized;
    property Handle: TISC_BLOB_HANDLE read FBlobHandle;
    property BlobHandle: TISC_BLOB_HANDLE read FBlobHandle;
    property BlobMaxSegmentSize: Long read FBlobMaxSegmentSize;
    property BlobNumSegments: Long read FBlobNumSegments;
    property BlobSize: Long read FDataSize;
    property BlobType: Short read FBlobType;
    property BlobSubType: Long read FBlobSubType write FBlobSubType;
    property AsString: AnsiString read GetAsString;
    property AsWideString: WideString read GetAsWideString;
    property FieldName: AnsiString read FFieldName write FFieldName;
    property TableName: AnsiString read FTableName write FTableName;
    property RecordKeyValues: TDynArray read FKeyValues write FKeyValues;
  end;

{$IFDEF SUPPORT_ARRAY_FIELD}
  // The whole ARRAY value, with the layout of the slice calls (see TpFIBArray)
  TFIBArrayStream = class(TFIBFieldStream)
  private
    FArray: TpFIBArray;
  protected
    procedure Load(CallBack: TCallBackBlobReadWrite); override;
    procedure Store(CallBack: TCallBackBlobReadWrite); override;
  public
    constructor CreateNew(AFieldNo: Integer; AStreamList: TList; AArray: TpFIBArray); reintroduce;
    property FIBArray: TpFIBArray read FArray;
  end;
{$ENDIF}

// Blob routine functions
  TBlobInfo= record
   NumSegments, MaxSegmentSize, TotalSize: Long;
   BlobType :Short;
  end;

  function GetBlobInfoRec(DB:TFIBDatabase; TR:TFIBTransaction;blob_id : TISC_QUAD; var Success :boolean ):TBlobInfo;

  procedure GetBlobInfo(ClientLibrary:IIbClientLibrary; hBlobHandle: PISC_BLOB_HANDLE;
    var NumSegments, MaxSegmentSize, TotalSize: Long; var BlobType: Short);
  procedure ReadBlob(ClientLibrary:IIbClientLibrary; hBlobHandle: PISC_BLOB_HANDLE; var Buffer: PAnsiChar;
    var BlobSize: Long;CallBack:TCallBackBlobReadWrite=nil);
  procedure WriteBlob(ClientLibrary:IIbClientLibrary; hBlobHandle: PISC_BLOB_HANDLE; Buffer: PAnsiChar;
    BlobSize: Long;CallBack:TCallBackBlobReadWrite=nil);

  function BlobExist(ClientLibrary:IIbClientLibrary; DBHandle:TISC_DB_HANDLE;
   TRHandle:TISC_TR_HANDLE;blob_id : TISC_QUAD
  ):boolean;

function FileToBlob(const FileName:string;Database:TFIBDatabase;Transaction:TFIBTransaction;
cb: TCallBackBlobReadWrite
):TISC_QUAD;

procedure BlobToFile(BlobID:TISC_QUAD;const FileName:string;Database:TFIBDatabase;Transaction:TFIBTransaction;
cb: TCallBackBlobReadWrite
);



type

  (* TFIBOutputDelimitedFile *)
  TFIBFileOutputStream= class(TFIBBatchOutputStream)
  protected
    FFile:TFileStream;
    FBuffer:PAnsiChar;
    FBuffPos:integer;
    procedure CloseFile;
    procedure FlushBuf(Force:boolean; Count:integer);
    function  WriteValue(const ValBuffer; Count: Longint):Integer;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  TFIBOutputDelimitedFile = class(TFIBFileOutputStream)
  protected
//    FFile:TFileStream;
    FOutputTitles: Boolean;
    FColDelimiter,
    FRowDelimiter: string;
    st :string;
    val: string;
    procedure CloseFile;
{    procedure PrepareBuffer;
    procedure FlushBuf(Force:boolean; Count:integer);
    function  WriteValue(const ValBuffer; Count: Longint):Integer;}
  public
    procedure ReadyStream; override;
    function WriteColumns: Boolean; override;
    property ColDelimiter: string read FColDelimiter write FColDelimiter;
    property OutputTitles: Boolean read FOutputTitles
                                   write FOutputTitles;
    property RowDelimiter: string read FRowDelimiter write FRowDelimiter;
  end;

  (* TFIBInputDelimitedFile *)
  TFIBInputDelimitedFile = class(TFIBBatchInputStream)
  protected
    FColDelimiter,
    FRowDelimiter: string;
    FEOF: Boolean;
    FFile: TFileStream;
    FLookAhead: Char;
    FReadBlanksAsNull: Boolean;
    FSkipTitles: Boolean;
  public
    destructor Destroy; override;
    function GetColumn(var Col: AnsiString): Integer;
    function ReadParameters: Boolean; override;
    procedure ReadyStream; override;
    property ColDelimiter: string read FColDelimiter write FColDelimiter;
    property ReadBlanksAsNull: Boolean read FReadBlanksAsNull
                                       write FReadBlanksAsNull;
    property RowDelimiter: string read FRowDelimiter write FRowDelimiter;
    property SkipTitles: Boolean read FSkipTitles write FSkipTitles;
  end;


  (* TFIBOutputRawFile *)
  TFIBOutputRawFile = class(TFIBFileOutputStream)

  public
    constructor Create;
    constructor CreateEx(aVersion:integer;const CharSet:string);
    procedure  ReadyStream; override;
    function   WriteColumns: Boolean; override;
  end;

 (* TFIBInputRawFile *)
  TFIBInputRawFile = class(TFIBBatchInputStream)
  protected
//    FHandle: THandle;
    FFile:TFileStream;
    FMap:TList;
    SkippedLen:array of integer;
    procedure CloseFile;
  public
    destructor Destroy; override;
    function  ReadParameters: Boolean; override;
    procedure ReadyStream; override;

  end;


var
  NullQUID:TISC_QUAD;

 function EquelQUADs(const Value1,Value2:TISC_QUAD):boolean;
 procedure ValidateBlobCacheDirectory(Database:TFIBDataBase);

implementation

uses
  StrUtil,FIBDataSet,IBBlobFilter,FIBConsts
  {$IFDEF MACOS}
   ,Posix.Unistd
  {$ENDIF}
    ,Variants, pFIBProps
  ;

 function EquelQUADs(const Value1,Value2:TISC_QUAD):boolean;
 begin
   Result:=
      (Value1.gds_quad_high=Value2.gds_quad_high)
   and
      (Value1.gds_quad_low=Value2.gds_quad_low)
 end;

var
   SwapVersion:integer=1;
   BlobCacheSignature:Ansistring='FIB$BLOB_BODY';
   BlobCacheOperation: TCriticalSection;

procedure DoValidateBlobCacheFile(Database:TFIBDataBase; Transaction:TFIBTransaction;const FileName:string);
var
  Stream: TStream;
  tmpStr:Ansistring;
  tmpInt:integer;
  tmpBlobId:TISC_QUAD;
  vFileIsValid:boolean;

begin
  vFileIsValid:=False;
  BlobCacheOperation.Acquire;
try
  Stream := TFileStream.Create(FileName, fmOpenRead);
  try
     Stream.Position := 0;
     SetLength(tmpStr,Length(BlobCacheSignature));
     Stream.Read(tmpStr[1],Length(BlobCacheSignature));
     if tmpStr=BlobCacheSignature then
     begin
       Stream.Read(tmpInt,SizeOf(tmpInt));
       if tmpInt=SwapVersion then
       begin
        Stream.Read(tmpBlobId,SizeOf(TISC_QUAD));
        if  not Transaction.DefaultDatabase.Connected then
          Transaction.DefaultDatabase.Connected:=True;

        if not Transaction.InTransaction then
          Transaction.StartTransaction;
        vFileIsValid:=
         BlobExist(Database.ClientLibrary,
          Database.Handle,Transaction.Handle,tmpBlobId
         );
       end;
     end;
  finally
    Stream.Free;
  end;
except
end;
try
 if not vFileIsValid then
   DeleteFile(FileName);
finally
  BlobCacheOperation.Release;
end;
end;

procedure DoValidateBlobCacheDirectory(Database:TFIBDataBase; Transaction:TFIBTransaction; const Dir:string);
var
  sr: TSearchRec;
  FileAttrs: Integer;

begin
   FileAttrs:=faAnyFile;
   if FindFirst(Dir+'*.blb', FileAttrs, sr) = 0 then
   begin
      repeat
        if (sr.Attr and FileAttrs) = sr.Attr then
        begin
         DoValidateBlobCacheFile(Database,Transaction,Dir+sr.Name);
        end;
      until FindNext(sr) <> 0;
      FindClose(sr);
   end;
   FileAttrs:=faDirectory;
   if FindFirst(Dir+'*', FileAttrs, sr) = 0 then
   begin
      repeat
        if (sr.Attr and FileAttrs) = sr.Attr then
         if (sr.Name<>'.') and (sr.Name<>'..') then
           DoValidateBlobCacheDirectory(Database,Transaction,Dir+sr.Name+'\');
      until FindNext(sr) <> 0;
      FindClose(sr);
   end;

end;

type

  TValidateBlobCacheThread = class(TThread)
  private
    FDatabase:TFIBDataBase;
    FTransaction:TFIBTransaction;
    FCacheDir:string;

  protected
    procedure Execute; override;
  public
    constructor Create(Database:TFIBDataBase);
    destructor Destroy; override;
  end;

{ TValidateBlobCacheThread }

constructor TValidateBlobCacheThread.Create(Database: TFIBDataBase);
begin
  FDatabase:=TFIBDatabase.Create(nil);
  with FDatabase do
  begin
    if  Database.IsRemoteConnect then
     DBName  :=Database.DBName
    else
     DBName  :='localhost:'+Database.DBName;
    DBParams:=Database.DBParams;
    UseLoginPrompt:=False;
    SynchronizeTime:=False;
    Name:='dbValidateBlobCache';
    LibraryName:=Database.LibraryName;
    CryptKey := Database.CryptKey;
    OnCryptKeyRequest := Database.OnCryptKeyRequest;
//    Connected:=True;
  end;

  FTransaction:=TFIBTransaction.Create(nil);
  with FTransaction do
  begin
    DefaultDatabase:=FDatabase;
    Name:='trValidateBlobCache';
    TRParams.Add('read');
    TRParams.Add('isc_tpb_nowait');    
    TRParams.Add('read_committed');
    TRParams.Add('rec_version');
  end;
  FCacheDir:=Database.BlobSwapSupport.SwapDirectory;
  FreeOnTerminate:=True;
  inherited Create(False);
end;

destructor TValidateBlobCacheThread.Destroy;
begin
  if FTransaction.InTransaction then
   FTransaction.Commit;
  FTransaction.Free;
  FDatabase.Connected:=False;
  FDatabase.Free;
  inherited Destroy;
end;

procedure TValidateBlobCacheThread.Execute;
begin
  DoValidateBlobCacheDirectory(FDatabase,FTransaction,FCacheDir);
end;

procedure ValidateBlobCacheDirectory(Database:TFIBDataBase);
begin
  if not Assigned(Database) or not (Database.Connected)
   or (Length(Database.BlobSwapSupport.SwapDirectory) = 0)
   or not DirectoryExists(Database.BlobSwapSupport.SwapDirectory)
  then
   Exit;
 TValidateBlobCacheThread.Create(Database);
end;

function GetBlobInfoRec(DB:TFIBDatabase;TR:TFIBTransaction; blob_id : TISC_QUAD;var Success :boolean ):TBlobInfo;
var
 BlobHandle: TISC_BLOB_HANDLE;
begin
 if not Assigned(DB) or not Assigned(TR) or not TR.Active then
 begin
  Success:=False; Exit;
 end;
 if not Assigned(DB.ClientLibrary) then
 raise
    EAPICallException.Create(Format(SUnknownClientLibrary,['GetBlobInfo']));

 BlobHandle:=nil;
 Success :=
  DB.ClientLibrary.isc_open_blob2(
   StatusVector, @DB.Handle, @TR.Handle, @BlobHandle,@blob_id, 0, nil)=0;
 if Success  then
 with Result do 
 begin
   GetBlobInfo(DB.ClientLibrary,@BlobHandle, NumSegments, MaxSegmentSize, TotalSize,BlobType);
   DB.ClientLibrary.isc_close_blob(StatusVector,@BlobHandle)
 end
 else
  FillChar(Result,SizeOf(Result),0);
end;

procedure GetBlobInfo(ClientLibrary:IIbClientLibrary; hBlobHandle: PISC_BLOB_HANDLE;
  var NumSegments, MaxSegmentSize, TotalSize: Long; var BlobType: Short);
var
  items: array[0..3] of AnsiChar;
  results: array[0..99] of AnsiChar;
  i, item_length: Integer;
  item: Integer;
begin
  if not Assigned(ClientLibrary) then
  raise
    EAPICallException.Create(Format(SUnknownClientLibrary,['GetBlobInfo']));

  items[0] := AnsiChar(isc_info_blob_num_segments);
  items[1] := AnsiChar(isc_info_blob_max_segment);
  items[2] := AnsiChar(isc_info_blob_total_length);
  items[3] := AnsiChar(isc_info_blob_type);

  if ClientLibrary.isc_blob_info(StatusVector, hBlobHandle, 4, @items[0], SizeOf(results),
                    @results[0]) > 0 then
    IBError(ClientLibrary,nil);

  i := 0;
  while (i < SizeOf(results)) and (results[i] <> AnsiChar(isc_info_end)) do
  begin
    item := Integer(results[i]); Inc(i);
    item_length := ClientLibrary.isc_vax_integer(@results[i], 2); Inc(i, 2);
    case item of
      isc_info_blob_num_segments:
        NumSegments := ClientLibrary.isc_vax_integer(@results[i], item_length);
      isc_info_blob_max_segment:
        MaxSegmentSize := ClientLibrary.isc_vax_integer(@results[i], item_length);
      isc_info_blob_total_length:
        TotalSize := ClientLibrary.isc_vax_integer(@results[i], item_length);
      isc_info_blob_type:
        BlobType := ClientLibrary.isc_vax_integer(@results[i], item_length);
    end;
    Inc(i, item_length);
  end;
end;


procedure OldReadBlob(ClientLibrary:IIbClientLibrary; hBlobHandle: PISC_BLOB_HANDLE; var Buffer: PAnsiChar;
    var BlobSize: Long;CallBack:TCallBackBlobReadWrite=nil);
var
  BytesRead, SegLen: UShort;
  LocalBuffer: PAnsiChar;
  AllReadBytes:integer;
  Stop:boolean;
begin
  if not Assigned(ClientLibrary) then
  raise
    EAPICallException.Create(Format(SUnknownClientLibrary,['ReadBlob']));

  LocalBuffer := Buffer;
  if BlobSize<DefaultBlobSegmentSize then
   SegLen:=BlobSize // Avoid IB2007 bug
  else
   SegLen := DefaultBlobSegmentSize;
  AllReadBytes:=0;
  Stop:=False;
  while (AllReadBytes<BlobSize) do
  begin
    if (AllReadBytes + SegLen > BlobSize) then
     SegLen :=BlobSize-AllReadBytes ;
    if not ((ClientLibrary.isc_get_segment(
               StatusVector, hBlobHandle, @BytesRead, SegLen,
               LocalBuffer) = 0) or
            (StatusVectorArray[1] = isc_segment)) then
      IBError(ClientLibrary,nil);
    Inc(LocalBuffer, BytesRead);
    Inc(AllReadBytes,BytesRead);
    if Assigned(CallBack) then
      CallBack(BlobSize,AllReadBytes,Stop);
    if Stop then
      Exit;
  end;
end;

procedure ReadBlob(ClientLibrary:IIbClientLibrary; hBlobHandle: PISC_BLOB_HANDLE; var Buffer: PAnsiChar;
 var BlobSize: Long;CallBack:TCallBackBlobReadWrite=nil);
var
  vBlobSize:Long;
  BytesRead, SegLen: UShort;
  LocalBuffer: PAnsiChar;
  Stop:boolean;
begin
// Don't work correctly for FB1.5 local connect
  if not Assigned(ClientLibrary) then
  raise
    EAPICallException.Create(Format(SUnknownClientLibrary,['ReadBlob']));
  Stop:=False;
  vBlobSize:=0;
  LocalBuffer := Buffer;
  while True do
  begin
   if vBlobSize=BlobSize then
     SegLen:=0
   else
   if BlobSize<DefaultBlobSegmentSize then
    SegLen:=BlobSize // Avoid IB2007 bug
   else
    SegLen := DefaultBlobSegmentSize;
   case  ClientLibrary.isc_get_segment(
               StatusVector, hBlobHandle, @BytesRead, SegLen,
               LocalBuffer) of
    0,isc_segment:
    begin
     Inc(LocalBuffer, BytesRead);
     Inc(vBlobSize,BytesRead);
     if Assigned(CallBack) then
      CallBack(BlobSize,vBlobSize,Stop);
     if Stop then
      Exit;
    end;
    isc_segstr_eof:
    begin
       if vBlobSize<BlobSize then
        ReallocMem(Buffer,vBlobSize);
       Inc(vBlobSize,BytesRead);
       BlobSize:=vBlobSize;
       if Assigned(CallBack) then
        CallBack(BlobSize,vBlobSize,Stop);
       Exit;
    end
   else
    IBError(ClientLibrary,nil);
   end;
  end;
end;
 
procedure WriteBlob(ClientLibrary:IIbClientLibrary; hBlobHandle: PISC_BLOB_HANDLE; Buffer: PAnsiChar;
  BlobSize: Long;CallBack:TCallBackBlobReadWrite=nil);
var
  CurPos, SegLen: Long;
  Stop:boolean;
begin
  if not Assigned(ClientLibrary) then
  raise
    EAPICallException.Create(Format(SUnknownClientLibrary,['WriteBlob']));
  Stop:=False;
  CurPos := 0;
  SegLen := DefaultBlobSegmentSize;
  while (CurPos < BlobSize) do
  begin
    if (CurPos + SegLen > BlobSize) then
      SegLen := BlobSize - CurPos;
    if ClientLibrary.isc_put_segment(StatusVector, hBlobHandle, SegLen,
         PAnsiChar(@Buffer[CurPos])) > 0 then
      IBError(ClientLibrary,nil);
    Inc(CurPos, SegLen);
    if Assigned(CallBack) then
     CallBack(BlobSize,CurPos,Stop);

    if Stop then
    begin
      ClientLibrary.isc_cancel_blob(StatusVector, hBlobHandle);
      Exit;
    end;

  end;
end;

function BlobExist(ClientLibrary:IIbClientLibrary; DBHandle:TISC_DB_HANDLE;
   TRHandle:TISC_TR_HANDLE;blob_id : TISC_QUAD
):boolean;
var
 BlobHandle: TISC_BLOB_HANDLE;
begin
  if not Assigned(ClientLibrary) then
  raise
    EAPICallException.Create(Format(SUnknownClientLibrary,['BlobExist']));
 BlobHandle:=nil;    
 Result:=
  ClientLibrary.isc_open_blob2(
   StatusVector, @DBHandle, @TRHandle, @BlobHandle,@blob_id, 0, nil)=0;

 if Result then
  ClientLibrary.isc_close_blob(StatusVector,@BlobHandle)
end;

function FileToBlob(const FileName:string;Database:TFIBDatabase;Transaction:TFIBTransaction;
cb: TCallBackBlobReadWrite
):TISC_QUAD;
var  fs: TFIBBlobStream;
begin
 fs := TFIBBlobStream.CreateNew(0, nil);
 try
   fs.Database := Database;
   fs.Transaction := Transaction;
   fs.Mode := bmReadWrite;
   Result:=fs.FileToBlob(FileName,cb)
 finally
   fs.Free;
 end;
end;


procedure BlobToFile(BlobID:TISC_QUAD;const FileName:string;Database:TFIBDatabase;Transaction:TFIBTransaction;
cb: TCallBackBlobReadWrite
);
var  fs: TFIBBlobStream;
begin
 fs := TFIBBlobStream.CreateNew(0, nil);
 try
   fs.Database := Database;
   fs.Transaction := Transaction;
   fs.Mode := bmRead;
   fs.BlobID:=BlobID;
   fs.BlobToFile(FileName,cb)
 finally
   fs.Free;
 end;
end;

procedure TFIBFieldStream.DoOnDatabaseFree(Sender: TObject);
begin
  FDatabase := nil;
  FTransaction := nil;
end;

constructor TFIBFieldStream.CreateNew(AFieldNo: Integer; AStreamList: TList);
begin
  inherited Create;
  FStreamList := AStreamList;
  FFieldNo := AFieldNo;
  FNeedSaveOldBuffer := True;
  if Assigned(FStreamList) then
    FIndexInList := FStreamList.Add(Self);
end;

destructor TFIBFieldStream.Destroy;
begin
  SetSize(0);
  ReallocMem(FOldBuffer, 0);
  FOldBuffer := nil;
  FOldDataSize := 0;
  if Assigned(FStreamList) then
    with FStreamList do
    begin
      // the last stream takes the place of this one
      if FIndexInList < Count - 1 then
      begin
        FStreamList[FIndexInList] := FStreamList[Count - 1];
        TFIBFieldStream(FStreamList[FIndexInList]).FIndexInList := FIndexInList;
      end;
      Delete(Count - 1);
    end;
  inherited Destroy;
end;

function TFIBFieldStream.Call(ErrCode: ISC_STATUS; RaiseError: Boolean): ISC_STATUS;
begin
  Result := 0;
  if Transaction <> nil then
    Result := Transaction.Call(ErrCode, RaiseError)
  else
  if RaiseError and (ErrCode > 0) then
    IBError(FDatabase.ClientLibrary, Self);
end;

procedure TFIBFieldStream.CheckReadable;
begin
  if FMode = bmWrite then
    FIBError(feBlobCannotBeRead, [nil]);
end;

procedure TFIBFieldStream.CheckWritable;
begin
  if (FMode = bmRead) and not IsClientField then
    FIBError(feBlobCannotBeWritten, [nil]);
end;

procedure TFIBFieldStream.CreateEmpty;
begin
  CheckWritable;
  FBlobID.gds_quad_high := 0;
  FBlobID.gds_quad_low := 0;
  Truncate;
end;

procedure TFIBFieldStream.DoAfterInitialize;
begin
end;

procedure TFIBFieldStream.EnsureInitialized(CallBack: TCallBackBlobReadWrite = nil);
begin
  if FInitialized then
    Exit;
  if FIsClientField then
  begin
    FInitialized := True;
    Exit;
  end;
  case FMode of
    bmWrite:
      CreateEmpty;
    bmReadWrite:
      if (FBlobID.gds_quad_high = 0) and (FBlobID.gds_quad_low = 0) then
        CreateEmpty
      else
        Load(CallBack);
  else
    Load(CallBack);
  end;
  FInitialized := True;
  DoAfterInitialize;
end;

// ClearModified: the value is already stored, the cache becomes unmodified only
procedure TFIBFieldStream.DoFinalize(ClearModified, ForceWrite: Boolean;
  CallBack: TCallBackBlobReadWrite = nil);
begin
  if not FInitialized or (FMode = bmRead) or (not FModified and not ForceWrite) then
    Exit;
  if ClearModified then
  begin
    FNeedSaveOldBuffer := True;
    FModified := False;
    Exit;
  end;
  CheckHandles(False);
  Store(CallBack);
end;

procedure TFIBFieldStream.Finalize;
begin
  DoFinalize(False, False);
  DoFinalize(True, False);
end;

procedure TFIBFieldStream.Cancel;
begin
  if FInitialized and Modified then
  begin
    SetSize(FOldDataSize);
    if FDataSize > 0 then
      Move(FOldBuffer[0], FBuffer[0], FDataSize);
    FModified := False;
    FNeedSaveOldBuffer := True;
    FreeMem(FOldBuffer);
    FOldBuffer := nil;
    FOldDataSize := 0;
  end;
end;

procedure TFIBFieldStream.DeInitialize;
begin
  FreeOldBuffer;
  if FDataSize > 0 then
  begin
    SetSize(0);
    FInitialized := False;
  end;
end;

procedure TFIBFieldStream.FreeOldBuffer;
begin
  if Assigned(FOldBuffer) then
  begin
    ReallocMem(FOldBuffer, 0);
    FOldDataSize := 0;
  end;
  // the current value is the one to restore on the next Cancel
  FNeedSaveOldBuffer := True;
end;

function TFIBFieldStream.GetDatabase: TFIBDatabase;
begin
  Result := FDatabase;
end;

function TFIBFieldStream.GetDBHandle: PISC_DB_HANDLE;
begin
  if Assigned(FDatabase) and Assigned(FDatabase.Handle) then
    Result := @FDatabase.Handle
  else
    Result := nil;
end;

function TFIBFieldStream.GetTransaction: TFIBTransaction;
begin
  Result := FTransaction;
end;

function TFIBFieldStream.GetUpdateTransaction: TFIBTransaction;
begin
  if Assigned(FUpdateTransaction) then
    Result := FUpdateTransaction
  else
    Result := FTransaction;
end;

function TFIBFieldStream.GetUpdateTRHandle: PISC_TR_HANDLE;
begin
  if Assigned(FUpdateTransaction) then
    Result := @FUpdateTransaction.Handle
  else
    Result := GetTRHandle;
end;

function TFIBFieldStream.GetTRHandle: PISC_TR_HANDLE;
begin
  if Assigned(FTransaction) and Assigned(FTransaction.Handle) then
    Result := @FTransaction.Handle
  else
    Result := nil;
end;

procedure TFIBFieldStream.CheckHandles(ReadTransaction: Boolean = True);
begin
  if GetDBHandle = nil then
  begin
    if not Assigned(Database) then
      FIBError(feDatabaseNotAssigned, ['BlobStream'])
    else
      FIBError(feDatabaseClosed, ['BlobStream']);
  end
  else
  if ReadTransaction then
  begin
    if GetTRHandle = nil then
      if not Assigned(Transaction) then
        FIBError(feTransactionNotAssigned, ['BlobStream'])
      else
        FIBError(feNotInTransaction, ['BlobStream']);
  end
  else
  if GetUpdateTRHandle = nil then
    if not Assigned(FUpdateTransaction) then
      FIBError(feTransactionNotAssigned, ['BlobStream'])
    else
      FIBError(feNotInTransaction, ['BlobStream']);
end;

function TFIBFieldStream.Read(var Buffer; Count: Longint): Longint;
begin
  CheckReadable;
  EnsureInitialized;
  if Count <= 0 then
  begin
    Result := 0;
    Exit;
  end;
  if FPosition + Count > FDataSize then
    Result := FDataSize - FPosition
  else
    Result := Count;
  Move(FBuffer[FPosition], Buffer, Result);
  Inc(FPosition, Result);
end;

function TFIBFieldStream.ReadOldBuffer(var Buffer; Count: Longint): Longint;
begin
  if Assigned(FOldBuffer) then
  begin
    if Count > FOldDataSize then
      Result := FOldDataSize
    else
      Result := Count;
    Move(FOldBuffer[0], Buffer, Result);
  end
  else
    Result := Read(Buffer, Count);
end;

function TFIBFieldStream.Seek(Offset: Longint; Origin: Word): Longint;
begin
  Result := DoSeek(Offset, Origin, nil);
end;

function TFIBFieldStream.DoSeek(Offset: Longint; Origin: Word;
  CallBack: TCallBackBlobReadWrite): Longint;
begin
  EnsureInitialized(CallBack);
  case Origin of
    soFromBeginning:
      FPosition := Offset;
    soFromCurrent:
      Inc(FPosition, Offset);
    soFromEnd:
      FPosition := FDataSize + Offset;
  end;
  Result := FPosition;
end;

function TFIBFieldStream.SeekInOldBuffer(Offset: Longint; Origin: Word): Longint;
begin
  if Assigned(FOldBuffer) then
    Result := FOldDataSize
  else
    Result := Seek(Offset, Origin);
end;

// Called from the refresh of a posted record
procedure TFIBFieldStream.ReplaceBlobID(const Value: TISC_QUAD);
begin
  FBlobID := Value;
  FModified := False;
end;

procedure TFIBFieldStream.SetBlobID(const Value: TISC_QUAD);
begin
  FBlobID := Value;
  FInitialized := False;
end;

procedure TFIBFieldStream.SetDatabase(Value: TFIBDatabase);
begin
  FDatabase := Value;
  FInitialized := False;
end;

procedure TFIBFieldStream.SetMode(Value: TBlobStreamMode);
begin
  FMode := Value;
  FInitialized := False;
end;

procedure TFIBFieldStream.SetSize(NewSize: Long);
begin
  if NewSize <> FDataSize then
  begin
    ReallocMem(FBuffer, NewSize);
    FDataSize := NewSize;
    // Guarantee that FBuffer is nil, if size is 0.
    if NewSize = 0 then
      FBuffer := nil;
  end;
end;

procedure TFIBFieldStream.SetUpdateTransaction(Value: TFIBTransaction);
begin
  FUpdateTransaction := Value;
end;

procedure TFIBFieldStream.SetTransaction(Value: TFIBTransaction);
begin
  FInitialized := False;
  FTransaction := Value;
end;

procedure TFIBFieldStream.SaveOldBuffer;
begin
  FreeMem(FOldBuffer);
  FOldBuffer := FBuffer;
  FOldDataSize := FDataSize;
  FBuffer := nil;
  FDataSize := 0;
  FNeedSaveOldBuffer := False;
end;

procedure TFIBFieldStream.Truncate;
begin
  FModified := True;
  if FNeedSaveOldBuffer then
    SaveOldBuffer
  else
    SetSize(0);
end;

function TFIBFieldStream.Write(const Buffer; Count: Longint): Longint;
begin
  CheckWritable;
  EnsureInitialized;
  if FNeedSaveOldBuffer then
    SaveOldBuffer;
  Result := Count;
  if Count <= 0 then
    Exit;
  if FPosition + Count > FDataSize then
    SetSize(FPosition + Count);
  Move(Buffer, FBuffer[FPosition], Count);
  Inc(FPosition, Count);
  FModified := True;
end;

(* TFIBBlobStream *)
constructor TFIBBlobStream.CreateNew(AFieldNo: Integer; AStreamList: TList;
  const ATableName: string = ''; const AFieldName: string = '';
  PKeyValues: PDynArray = nil);
begin
  inherited CreateNew(AFieldNo, AStreamList);
  FCharSet := -1;
  FTableName := AnsiString(ATableName);
  FFieldName := AnsiString(AFieldName);
  if PKeyValues <> nil then
    FKeyValues := PKeyValues^
  else
    SetLength(FKeyValues, 0);
end;

constructor TFIBBlobStream.Create;
begin
  CreateNew(-1, nil);
end;

procedure TFIBBlobStream.InternalSetCharSet(Value: Integer);
begin
  FCharSet := Value;
end;

destructor TFIBBlobStream.Destroy;
begin
  CloseBlob;
  inherited Destroy;
end;

procedure TFIBBlobStream.CloseBlob;
begin
  if (FBlobHandle <> nil) and
    (Call(FDatabase.ClientLibrary.isc_close_blob(StatusVector, @FBlobHandle), False) > 0)
  then
    IBError(FDatabase.ClientLibrary, Self);
  FBlobHandle := nil;
  FInitialized := False;
end;

procedure TFIBBlobStream.Load(CallBack: TCallBackBlobReadWrite);
begin
  OpenBlob(CallBack);
end;

procedure TFIBBlobStream.DoAfterInitialize;
begin
  SaveToSwapFile;
end;

procedure TFIBBlobStream.DoFinalize(ClearModified, ForceWrite: Boolean;
  CallBack: TCallBackBlobReadWrite = nil);
begin
  if FInitialized and (FMode <> bmRead) and (FModified or ForceWrite) then
    FLoadedFromCache := False;
  inherited DoFinalize(ClearModified, ForceWrite, CallBack);
end;

procedure TFIBBlobStream.Store(CallBack: TCallBackBlobReadWrite);
var
  Temp: PAnsiChar;
  SizeBeforeFilter: Integer;
  Filtered: Boolean;
begin
  Call(FDatabase.ClientLibrary.isc_create_blob2(StatusVector, DBHandle, UpdateTRHandle,
    @FBlobHandle, @FBlobID, 0, nil), True);
  Filtered := ExistBlobFilter(Database, FBlobSubType);
  SizeBeforeFilter := FDataSize;
  Temp := nil;
  if Filtered then
  begin
    // the filtered value is written, the buffer keeps the original one
    ReallocMem(Temp, FDataSize);
    Move(FBuffer[0], Temp[0], FDataSize);
    IBFilterBuffer(Database, FBuffer, FDataSize, FBlobSubType, True);
  end;
  FIBMiscellaneous.WriteBlob(FDatabase.ClientLibrary, @FBlobHandle, FBuffer, FDataSize, CallBack);
  Call(FDatabase.ClientLibrary.isc_close_blob(StatusVector, @FBlobHandle), True);
  if Filtered then
  begin
    FDataSize := SizeBeforeFilter;
    FreeMem(FBuffer);
    FBuffer := Temp;
  end;
end;

procedure TFIBBlobStream.GetBlobInfo;
var
  iBlobSize: Long;
begin
  FIBMiscellaneous.GetBlobInfo(FDatabase.ClientLibrary,@FBlobHandle,
   FBlobNumSegments, FBlobMaxSegmentSize,    iBlobSize, FBlobType
  );
  SetSize(iBlobSize);
end;

function TFIBBlobStream.LoadFromFile(const Filename: string;IsCacheFile:boolean=False):boolean;
var
  Stream: TStream;
begin
 BlobCacheOperation.Acquire;
 try
   if not FileExists(FileName) then
   begin
      Result := False;
      Exit;
   end;
   try
    Stream := TFileStream.Create(FileName, fmOpenRead);
    try
      Result:=LoadFromStream(Stream,IsCacheFile);
      FLoadedFromCache:= Result and IsCacheFile;
    finally
      Stream.Free;
    end;
   except
     Result := False;
   end;
 finally
  BlobCacheOperation.Release;
 end
end;


var
 blr_bpb : array[0..6] of Ansichar = (AnsiChar(isc_bpb_version1),
     AnsiChar(isc_bpb_source_type), AnsiChar(1), AnsiChar(isc_blob_blr),
      AnsiChar(isc_bpb_target_type), AnsiChar(1), AnsiChar(isc_BLOB_text)
 );


procedure TFIBBlobStream.OpenBlob(CallBack:TCallBackBlobReadWrite=nil);
var
 FileName:string;
 CanLoadFromFile:boolean;
begin
  CheckReadable;
  CheckHandles;

  if (FBlobSubType >1)and  (FBlobSubType <9) and (FDatabase.UseBlrToTextFilter) then
  begin
   blr_bpb[3]:=AnsiChar(FBlobSubType);
   Call(FDatabase.ClientLibrary.isc_open_blob2(
    StatusVector, DBHandle, TRHandle, @FBlobHandle,@FBlobID, 7, blr_bpb), True
   )
  end
  else
   Call(FDatabase.ClientLibrary.isc_open_blob2(
    StatusVector, DBHandle, TRHandle, @FBlobHandle,@FBlobID, 0, nil), True
   );
  try
    GetBlobInfo;
    SetSize(FDataSize);
//Swap
      with Database.BlobSwapSupport,Database do
      begin
      if  not (csDesigning in ComponentState) then
       if Active and (Length(SwapDirectory) > 0)
        and ((Tables.Count=0) or (Tables.IndexOf(FTableName)>=0))
       then
       begin
         FileName:=GenerateSwapFileName(False);
         CanLoadFromFile:=True;
         if Assigned(BeforeLoadBlobFromSwap) then
          BeforeLoadBlobFromSwap(FTableName,FFieldName,RecordKeyValues,FileName,CanLoadFromFile);
        if CanLoadFromFile then
        begin
         if LoadFromFile(FileName,True) then
         begin
           FInitialized := True;
           Call(FDatabase.ClientLibrary.isc_close_blob(StatusVector, @FBlobHandle), True);
           if Assigned(AfterLoadBlobFromSwap) then
            AfterLoadBlobFromSwap(FTableName,FFieldName,RecordKeyValues,FileName);
           Exit;
         end
         else
         begin
           BlobCacheOperation.Acquire;
           try
            DeleteFile(FileName)
           finally
            BlobCacheOperation.Release;
           end;
         end;
        end;
       end;
      end;
//End Swap

    if FDatabase.NeedUTFEncodeDDL   then
     FIBMiscellaneous.ReadBlob(FDatabase.ClientLibrary,@FBlobHandle, FBuffer, FDataSize,CallBack)
    else
     FIBMiscellaneous.OldReadBlob(FDatabase.ClientLibrary,@FBlobHandle, FBuffer, FDataSize,CallBack);
    IBFilterBuffer(Database,FBuffer, FDataSize, FBlobSubType, False);
  except
    Call(FDatabase.ClientLibrary.isc_close_blob(StatusVector, @FBlobHandle), False);
    raise;
  end;
  Call(FDatabase.ClientLibrary.isc_close_blob(StatusVector, @FBlobHandle), True);
end;

function TFIBBlobStream.GetRecKeyValuesAsStr:string;
var
  i,L:integer;
begin
 Result := '';
 L:=Length(FKeyValues)-1;
 for i:=0 to L do
  Result:= Result+VarToStr(FKeyValues[i])+'_';
 SetLength( Result,Length(Result)-1);
end;

function  TFIBBlobStream.GenerateSwapFileName(ForceDir:boolean):string;
var
  ExistDir:boolean;
begin
  with Database.BlobSwapSupport do
    Result:= SwapDirectory+FTableName+'\'+FFieldName+'\';
  if ForceDir then
  begin
   ExistDir:= ForceDirectories(Result);
  end
  else
   ExistDir:= DirectoryExists(Result);
  if not ExistDir then
   Result:=''
  else
  begin
    Result:= Result+GetRecKeyValuesAsStr+'.blb';
  end;
end;

procedure TFIBBlobStream.SaveToSwapFile;
var
 FileName:string;
 CanSave:boolean;
begin
  if not FLoadedFromCache then
    with Database.BlobSwapSupport,Database do
    begin
    if  not (csDesigning in ComponentState) then
     if Active and (Length(SwapDirectory) > 0)
       and ((Tables.Count=0) or (Tables.IndexOf(FTableName)>=0))
     then
       if (FDataSize>=MinBlobSizeToSwap) and (FBlobID.gds_quad_high <> 0) then
       begin
        FileName:=GenerateSwapFileName(True);
        CanSave:=True;
        if Assigned(BeforeSaveBlobToSwap) then
        begin
         BeforeSaveBlobToSwap(FTableName,FFieldName,RecordKeyValues,
          Self,FileName,CanSave
         );
        end;

        if CanSave and (Length(FileName)>0) then
        begin
          SaveToFile(Filename,True);
         if Assigned(AfterSaveBlobToSwap) then
          AfterSaveBlobToSwap(FTableName,FFieldName,RecordKeyValues,FileName);
        end;

       end;
    end;
end;

procedure TFIBBlobStream.SaveToFile(const Filename: string;FullInfo:boolean=False);
var
  Stream: TStream;
begin
 if FullInfo and (Length(FKeyValues)=0) or (Length(FTableName)=0) then
  Exit;
 BlobCacheOperation.Acquire;
 try
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    SaveToStream(Stream,FullInfo);
  finally
    Stream.Free;
  end;
 except
 end;
 BlobCacheOperation.Release
end;


procedure TFIBBlobStream.SaveToStream(Stream: TStream;IsCacheStream:boolean=False);
var
   L:integer;
   KeyCount:integer;
   vFiltered:boolean;
   Temp:PAnsiChar;
   TempSize:integer;
   tmpStr:Ansistring;
begin
  CheckReadable;
  EnsureInitialized;
//  Stream.Size:=0;
  if FDataSize <> 0 then
  begin
    Seek(0, soFromBeginning);
    if IsCacheStream then
    begin
      KeyCount:=Length(FKeyValues);
      Stream.Write(BlobCacheSignature[1],Length(BlobCacheSignature));
      Stream.Write(SwapVersion,SizeOf(SwapVersion));
      Stream.Write(FBlobID,SizeOf(TISC_QUAD));
      TempSize:=FDataSize;
      vFiltered:=ExistBlobFilter(Database,FBlobSubType);
      if  vFiltered  then
      begin
        GetMem(Temp, TempSize);
        Move(FBuffer[0], Temp[0], TempSize);
        IBFilterBuffer(Database,Temp, TempSize, FBlobSubType, True);
      end;

      Stream.Write(TempSize,SizeOf(TempSize));
      Stream.Write(KeyCount,SizeOf(KeyCount));
      L:=Length(FTableName);
      Stream.Write(L,SizeOf(L));
      if L>0 then
       Stream.Write(FTableName[1],L);

      L:=Length(FFieldName);
      Stream.Write(L,SizeOf(L));
      if L>0 then
       Stream.Write(FFieldName[1],L);

      tmpStr:=GetRecKeyValuesAsStr;
      L:=Length(tmpStr);
      Stream.Write(L,SizeOf(L));
      if L>0 then
       Stream.Write(tmpStr[1],L);
      if  vFiltered  then
      begin
       try
        Stream.WriteBuffer(Temp^, TempSize);
       finally
       FreeMem(Temp);
       end;
      end
      else
       Stream.WriteBuffer(FBuffer^, FDataSize);
    end
    else
     Stream.WriteBuffer(FBuffer^, FDataSize);
  end;
end;

function   TFIBBlobStream.LoadFromStream(Stream: TStream;IsCacheStream:boolean=False):boolean;
var
   tmpStr,tmpStr1:Ansistring;
   tmpInt:integer;
   tmpBlobId:TISC_QUAD;
   KeyCount:integer;
begin
  Result := False;
  if IsCacheStream then
  begin
     Stream.Position := 0;
     SetLength(tmpStr,Length(BlobCacheSignature));
     Stream.Read(tmpStr[1],Length(BlobCacheSignature));
     if tmpStr<>BlobCacheSignature then
      Exit;
     Stream.Read(tmpInt,SizeOf(tmpInt));
     if tmpInt<>SwapVersion then
      Exit;
     Stream.Read(tmpBlobId,SizeOf(TISC_QUAD));
{     if not EquelQUADs(tmpBlobId,FBlobID)  then
      Exit;}
     if PInt64(@tmpBlobId)^<>PInt64(@FBlobID)^  then
      Exit;
     Stream.Read(tmpInt,SizeOf(tmpInt));
     if tmpInt<>FDataSize then
      Exit;
     Stream.Read(KeyCount,SizeOf(KeyCount));
     if KeyCount<>Length(FKeyValues) then
      Exit;
     Stream.Read(tmpInt,SizeOf(tmpInt));
     if tmpInt>0 then
     begin
       SetLength(tmpStr,tmpInt);
       Stream.Read(tmpStr[1],tmpInt);
       if FTableName<>tmpStr then
        Exit;
     end;
     Stream.Read(tmpInt,SizeOf(tmpInt));
     if tmpInt>0 then
     begin
       SetLength(tmpStr,tmpInt);
       Stream.Read(tmpStr[1],tmpInt);
       if FFieldName<>tmpStr then
        Exit;
     end;
     tmpStr:=GetRecKeyValuesAsStr;
     Stream.Read(tmpInt,SizeOf(tmpInt));
     if Length(tmpStr) <> tmpInt then
       Exit;
     if tmpInt>0 then
     begin
       SetLength(tmpStr1,tmpInt);
       Stream.Read(tmpStr1[1],tmpInt);
     end
     else
      tmpStr1:='';
     if tmpStr<>tmpStr1 then
      Exit;

    if FDataSize <> 0 then
    begin
     Stream.ReadBuffer(FBuffer^, FDataSize);
     if ExistBlobFilter(Database,FBlobSubType) then
      IBFilterBuffer(Database,FBuffer, FDataSize, FBlobSubType, false);
    end;
    Result := True;
  end
  else
  begin
    if not FIsClientField then
     CheckWritable;
    EnsureInitialized;
    Stream.Position := 0;
    SetSize(Stream.Size);
    if FDataSize <> 0 then
     Stream.ReadBuffer(FBuffer^, FDataSize);
    FModified := True;
    Result := True;
  end;
end;

procedure TFIBBlobStream.ReplaceBlobID(const Value: TISC_QUAD);
begin
  inherited ReplaceBlobID(Value);
  SaveToSwapFile;
end;

function  TFIBBlobStream.GetAsString: Ansistring;
begin
  CheckReadable;
  EnsureInitialized;
  if FDataSize <> 0 then
    begin
      Seek(0, soFromBeginning);
      SetString(Result, nil, FDataSize);
      ReadBuffer(Result[1], FDataSize);

      if (FBlobSubType=1) and Database.NeedUTFEncodeDDL  then
      begin

       if FCharSet in Database.UnicodeCharsets then
         Result:=UTF8Decode(Result)
       else
       if  Database.IsUnicodeConnect then
        Result:=UTF8Decode(Result)
      end;
    end
  else
    Result:='';
end;

function  TFIBBlobStream.GetAsWideString: Widestring;
var
  s:AnsiString;
begin
  CheckReadable;
  EnsureInitialized;
  if FDataSize <> 0 then
    begin
      Seek(0, soFromBeginning);
      SetString(s, nil, FDataSize);
      ReadBuffer(s[1], FDataSize);

      if (FBlobSubType=1) and Database.NeedUTFEncodeDDL  then
      begin
       if FCharSet in Database.UnicodeCharsets then
         Result:=UTF8Decode(s)
       else
       if  Database.IsUnicodeConnect then
        Result:=UTF8Decode(s)
       else
        Result:=s
      end
      else
        Result:=s
    end
  else
    Result:='';
end;


procedure TFIBBlobStream.BlobToFile(const FileName:string;CallBack:TCallBackBlobReadWrite=nil);
var
    f:TFileStream;
    iBlobSize,vBlobSize:integer;
    BytesRead, SegLen: UShort;
    LocalBuffer: PAnsiChar;
    Stop:boolean;

begin
// For big blob fields
  Stop:=False;
  CheckReadable;
  CheckHandles;
  Call(FDatabase.ClientLibrary.isc_open_blob2(
    StatusVector, DBHandle, TRHandle, @FBlobHandle,@FBlobID, 0, nil), True
  );
  FIBMiscellaneous.GetBlobInfo(FDatabase.ClientLibrary,@FBlobHandle,
   FBlobNumSegments, FBlobMaxSegmentSize,    iBlobSize, FBlobType
  );
  if iBlobSize>0 then
  begin
   f:=TFileStream.Create(Filename, fmCreate or fmShareDenyWrite);
   GetMem(LocalBuffer,DefaultBlobSegmentSize);

   try
    vBlobSize:=0;
    while True do
    begin
     if vBlobSize=iBlobSize then
       SegLen:=0
     else
     if iBlobSize<DefaultBlobSegmentSize then
      SegLen:=iBlobSize // Avoid IB2007 bug
     else
      SegLen := DefaultBlobSegmentSize;


     case  FDatabase.ClientLibrary.isc_get_segment(
                 StatusVector, @FBlobHandle, @BytesRead, SegLen,
                 LocalBuffer) of
      0,isc_segment:
      begin
       f.WriteBuffer(LocalBuffer^,BytesRead);
       Inc(vBlobSize,BytesRead);
       if Assigned(CallBack) then
        CallBack(iBlobSize,vBlobSize,Stop);
       if Stop then
        Exit;
      end;
      isc_segstr_eof:
      begin
         Inc(vBlobSize,BytesRead);
         f.WriteBuffer(LocalBuffer^,BytesRead);
         if Assigned(CallBack) then
          CallBack(iBlobSize,vBlobSize,Stop);
         Exit;
      end
     else
      IBError(FDatabase.ClientLibrary,nil);
     end;

    end;

   finally
     FreeMem(LocalBuffer);
     f.Free;
   end;
  end;
end;

function  TFIBBlobStream.FileToBlob(const FileName:string;CallBack:TCallBackBlobReadWrite=nil):TISC_QUAD;
var
    f:TFileStream;
    seg:LongInt;
    Stop:Boolean;
    CurPos:integer;
begin
// For big blob fields
  Result.gds_quad_high:=0;
  Result.gds_quad_low :=0;
  if FileExists(FileName) then
  begin
   EnsureInitialized(CallBack);

   f:=TFileStream.Create(Filename, fmOpenRead or fmShareDenyWrite);
   SetSize(DefaultBlobSegmentSize);
   seg:=DefaultBlobSegmentSize;
   try
    Call(FDatabase.ClientLibrary.isc_create_blob2(StatusVector, DBHandle, UpdateTRHandle, @FBlobHandle,
       @FBlobID, 0, nil), True);
    CurPos:=0; Stop:=False;
    while seg<>0 do
    begin
     seg:=f.Read(FBuffer^,DefaultBlobSegmentSize);
     FIBMiscellaneous.WriteBlob(FDatabase.ClientLibrary,@FBlobHandle, FBuffer, seg,nil);
     Inc(CurPos,seg);
     if Assigned(CallBack) then
      CallBack(f.Size,CurPos,Stop);
     if Stop then
        Break;
    end;
    if Stop then
     Call(FDatabase.ClientLibrary.isc_cancel_blob(StatusVector, @FBlobHandle), True)
    else
     Call(FDatabase.ClientLibrary.isc_close_blob(StatusVector, @FBlobHandle), True);
   finally
    f.Free;
   end;
   Result:=FBlobID
  end;
end;

{$IFDEF SUPPORT_ARRAY_FIELD}
constructor TFIBArrayStream.CreateNew(AFieldNo: Integer; AStreamList: TList; AArray: TpFIBArray);
begin
  inherited CreateNew(AFieldNo, AStreamList);
  FArray := AArray;
end;

procedure TFIBArrayStream.Load(CallBack: TCallBackBlobReadWrite);
begin
  CheckReadable;
  CheckHandles;
  SetSize(FArray.ArraySize);
  if FArray.GetSlice(@FBlobID, FBuffer, DBHandle, TRHandle) = 0 then
    SetSize(0);
end;

procedure TFIBArrayStream.Store(CallBack: TCallBackBlobReadWrite);
begin
  // an empty value is NULL
  if FDataSize = 0 then
  begin
    FBlobID.gds_quad_high := 0;
    FBlobID.gds_quad_low := 0;
  end
  else
  if FDataSize <> FArray.ArraySize then
    FIBErrorEx('Array %s.%s: the value has %d bytes instead of %d',
      [FArray.TableName, FArray.FieldName, FDataSize, FArray.ArraySize])
  else
    FArray.PutSlice(FBuffer, FBlobID, DBHandle, UpdateTRHandle);
end;
{$ENDIF}

(*
 * TFIBOutputDelimitedFile
 *)

procedure TFIBOutputDelimitedFile.CloseFile;
begin
  if FFile<>nil then
  begin
   FlushBuf(True,0);  
   FFile.Free;
   FFile:=nil
  end;
end;


const NULL_TERMINATOR = #0;
      TAB  = #9;
      CR   = #13;
      LF   = #10;
      cBufSize=1024*32;




procedure TFIBOutputDelimitedFile.ReadyStream;
var
  i: Integer;
  st: string;
begin
  if FColDelimiter = '' then
    FColDelimiter := TAB;
  if FRowDelimiter = '' then
    FRowDelimiter := CRLF;
  CloseFile;
  FFile:=TFileStream.Create(Filename,fmCreate);
  if FOutputTitles then
  begin
    for i := 0 to Columns.Count - 1 do
      if i = 0 then
        st := string(Columns[i].Data^.aliasname)
      else
        st := st + FColDelimiter + string(Columns[i].Data^.aliasname);
    st := st + FRowDelimiter;
//    FFile.Write(st[1],Length(st)*SizeOf(Char));
    WriteValue(st[1],Length(st)*SizeOf(Char));
  end;
end;


function TFIBOutputDelimitedFile.WriteColumns: Boolean;
var
  i: Integer;
  BytesWritten: DWORD;
  L,CL:integer;
  LenCDel,LenRDel:integer;
begin
  Result := False;
  if FFile <> nil then
  begin
    L:=1000;
    SetLength(st,L);
    CL:=0;
    LenCDel:=Length(FColDelimiter);
    LenRDel:=Length(FRowDelimiter);
    for i := 0 to Columns.Count - 1 do
    begin
      if i > 0 then
      begin
       if CL+LenCDel>L then
       begin
        Inc(L,LenCDel);
        SetLength(st,L);
       end;
       System.Move(FColDelimiter[1],st[CL+1],LenCDel*SizeOf(Char));
       Inc(CL,LenCDel)
      end;
      val:=StripString(Columns[i].AsString,FColDelimiter);
      val:=StripString(val,FRowDelimiter);
      if Length(Val)>0 then
      begin
        if CL+Length(val)>L then
        begin
          Inc(L,Length(val));
          SetLength(st,L);
        end;
        System.Move(val[1],st[CL+1],Length(val)*SizeOf(Char));
        Inc(CL,Length(val))
      end;
    end;

     if CL+LenRDel>L then
     begin
      Inc(L,LenRDel);
      SetLength(st,L);
     end;
     System.Move(FRowDelimiter[1],st[CL+1],LenRDel*SizeOf(Char));
     Inc(CL,LenRDel);
     SetLength(st,CL);

    BytesWritten:=WriteValue(st[1],Length(st)*SizeOf(Char));
    if BytesWritten = DWORD(Length(st)*SizeOf(Char)) then
      Result := True;
  end
end;

(*
 * TFIBInputDelimitedFile
 *)
destructor TFIBInputDelimitedFile.Destroy;
begin
  FFile.Free;
  inherited Destroy;
end;

function TFIBInputDelimitedFile.GetColumn(var Col: ansistring): Integer;
var
  c: Char;
  BytesRead: Integer;

  procedure ReadInput;
  begin
    if FLookAhead <> NULL_TERMINATOR then
    begin
      c := FLookAhead;
      BytesRead := SizeOf(Char);
      FLookAhead := NULL_TERMINATOR;
    end
    else
      BytesRead := FFile.Read(c, SizeOf(Char));
  end;

  procedure CheckCRLF(Delimiter: string);
  begin
    if (c = CR) and (PosCh(LF, Delimiter) > 0) then
    begin
      BytesRead := FFile.Read(c, SizeOf(Char));
      if (BytesRead = SizeOf(Char)) and (c <> LF) then
        FLookAhead := c
    end;
  end;

begin
  Col := '';
  Result := 0;
  ReadInput;
  while BytesRead <> 0 do
  begin
    if Pos(c, FColDelimiter) > 0 then
    begin
      CheckCRLF(FColDelimiter);
      Result := 1;
      break;
    end
    else
    if Pos(c, FRowDelimiter) > 0 then
    begin
      CheckCRLF(FRowDelimiter);
      Result := 2;
      break;
    end
    else
      Col := Col + c;
    ReadInput;
  end;
end;

function TFIBInputDelimitedFile.ReadParameters: Boolean;
var
  i, curcol: Integer;
  Col: ansistring;
begin
  Result := False;
  if not FEOF then
  begin
    curcol := 0;
    repeat
      i := GetColumn(Col);
      if (i = 0) then FEOF := True;
      if (curcol < Params.Count) then
      begin
        try
          if (Col = '') then
            case Params[curcol].ServerSQLType of
              SQL_TEXT,SQL_VARYING:
               if ReadBlanksAsNull then
                 Params[curcol].IsNull := True
               else
                Params[curcol].AsString := '';
            else
              Params[curcol].IsNull := True
            end
          else
             Params[curcol].AsString := Col;
          Inc(curcol);
        except
          on E: Exception do
          begin
            if not (FEOF and (curcol = Params.Count)) then
              raise;
          end;
        end;
      end;
    until (FEOF) or (i = 2);
    Result := ((FEOF) and (curcol = Params.Count)) or (not FEOF);
  end;
end;

procedure TFIBInputDelimitedFile.ReadyStream;
var
    col : ansistring;
   curcol : Integer;    
begin
  if FColDelimiter = '' then    FColDelimiter := TAB;
  if FRowDelimiter = '' then    FRowDelimiter := CRLF;
  FLookAhead := NULL_TERMINATOR;
  FEOF := False;
  if FFile <> nil then  FFile.Free;
  FFile := TFileStream.Create(FFilename, fmOpenRead or fmShareDenyWrite);
  if FSkipTitles then
  begin
    curcol := 0;
    while curcol < Params.Count do
    begin
      GetColumn(Col);
      Inc(CurCol)
    end;
  end;
end;


(* TFIBOutputRawFile *)

constructor TFIBOutputRawFile.CreateEx(aVersion:integer;const CharSet:string);
begin
// aVersion is deprecated
   inherited Create;
   FVersion:=3;
   FCharset:=CharSet
end;



constructor TFIBOutputRawFile.Create;
begin
   inherited Create;
   FVersion:=3;
end;

const
    SignRowFile:Ansistring='FIB$BATCH_ROW';



procedure TFIBOutputRawFile.ReadyStream;
var
    st: Ansistring;
    i,L: Integer;

begin
  FFile:=TFileStream.Create(Filename,fmCreate);
  begin
//   FFile.Write(SignRowFile[1], Length(SignRowFile));
   WriteValue(SignRowFile[1], Length(SignRowFile));
   st:=IntToStr(FVersion);
   WriteValue(st[1], 1);
   if FVersion>=2 then
   begin
//     FFile.Write(Columns.Count, SizeOf(Columns.Count));
     WriteValue(Columns.Count, SizeOf(Columns.Count));
     for i := 0 to Columns.Count - 1 do
     with Columns[i].Data^ do
     begin
       st := aliasname;
       L:=Length(st);
       WriteValue(L, SizeOf(L));
       WriteValue(st[1], L);
       WriteValue(sqltype,SizeOf(sqltype));
       WriteValue(sqlsubtype,SizeOf(sqlsubtype));
       WriteValue(sqlscale,SizeOf(sqlscale));
       WriteValue(sqllen,SizeOf(sqllen));

     end;
     if FVersion>2 then
     begin
      L:=Length(FCharset);
      WriteValue(L, SizeOf(L));
      if L>0 then
       WriteValue(FCharset[1], L);
     end
   end;
   FState  :=bsFileReady
  end;
end;

function TFIBOutputRawFile.WriteColumns: Boolean;
var
  i: Integer;
  BytesWritten: DWORD;
  b:boolean;
  Buffer :TDataBuffer;
  bs : TMemoryStream;
  Bytes: integer;
begin
  Result := False;
  bs :=nil;
  if FFile <> nil then
  try
    FState :=bsInProcess;
    for i := 0 to Columns.Count - 1 do
    begin
      b:=Columns[i].IsNull;
      BytesWritten:=WriteValue(b, SizeOf(Boolean));
      if BytesWritten<> SizeOf(Boolean) then
       Exit;
      if not b then
      with Columns[i].Data^ do
      begin
       Buffer :=sqldata;
       case sqltype and (not 1) of
        SQL_VARYING:
         Bytes:=sqllen+2;
        SQL_BLOB: begin
                   if bs=nil then
                    bs := TMemoryStream.Create;
                   Columns[i].SaveToStream(bs);
                   Bytes := bs.Size;
                   WriteValue(Bytes,SizeOf(Integer));
                   Buffer :=bs.Memory;
                  end;
       else
        Bytes:=sqllen
       end;
       BytesWritten:=WriteValue(Buffer[0],  Bytes );
       if BytesWritten <> DWORD(Bytes) then
        Exit;
      end;
    end;
    Result := True;
  finally
    bs.Free;
  end;
end;

(* TFIBInputRawFile *)

procedure TFIBInputRawFile.CloseFile;
begin
  if FFile<>nil then
  begin
   FFile.Free;
   FFile:=nil
  end;
end;

destructor TFIBInputRawFile.Destroy;
begin
  CloseFile;
  if Assigned(FMap) then
   FMap.Free;
  SetLength(SkippedLen,0);       
  inherited;
end;

function TFIBInputRawFile.ReadParameters: Boolean;
var
  i: Integer;
  BytesRead: DWORD;
  b:boolean;
  Bytes:DWORD;
  Buffer :TDataBuffer;
  bs : TMemoryStream;

function ReadParam(CurPar:TFIBXSQLVAR; DataLen:integer):boolean;
begin
    BytesRead:=FFile.Read(b, SizeOf(Boolean));
    if BytesRead<> SizeOf(Boolean) then
    begin
     Result := False;
     Exit;
    end
    else
     Result := True;
    if CurPar=nil then
    begin
     if not b then
     begin
      if DataLen<0 then       // It is Blob
       BytesRead:=FFile.Read(DataLen, SizeOf(Integer));
       FFile.Seek(DataLen,1)
//      FileSeek(FHandle,DataLen,1);
     end
    end
    else
    begin
      CurPar.IsNull:=b;
      if not b then
      with CurPar.Data^ do
      begin
       Buffer :=sqldata;
       case sqltype and (not 1) of
        SQL_VARYING: Bytes:=sqllen+2;
        SQL_BLOB:
         begin
           if bs=nil then
             bs := TMemoryStream.Create;
            BytesRead:=FFile.Read(Bytes, SizeOf(Integer));
            CurPar.IsNull:=Bytes=0;
            if CurPar.IsNull then
               Exit;
            bs.Size:=Bytes;
            Buffer :=bs.Memory;
         end;
       else
        Bytes:=sqllen;
       end;
        BytesRead:=FFile.Read(Buffer ^, Bytes);
       if BytesRead <> Bytes then    Exit;
       if (sqltype and (not 1))=SQL_BLOB  then
         CurPar.LoadFromStream(bs);
      end;
    end;
end;

begin
  if not (FVersion in [1,2,3]) then
   FVersion:=1;
  Result := False;
  bs :=nil;
  if FFile<>nil then
  try
    FState :=bsInProcess;
    if FVersion=1 then
    begin
      for i := 0 to Params.Count - 1 do
        if not ReadParam(Params[i],0) then
         Exit;
      Result := True;
    end
    else
    begin
      if not Assigned(FMap) then
       Result := False
      else
      begin
       for i := 0 to FMap.Count - 1 do
       begin
        if Assigned(FMap[i]) then
        begin
         if not ReadParam(TFIBXSQLVAR(FMap[i]),0) then
          Exit;
        end
        else
         ReadParam(TFIBXSQLVAR(FMap[i]),SkippedLen[i])
       end;
       Result := True;
      end;
    end;
  finally
   bs.Free
  end;
end;

procedure TFIBInputRawFile.ReadyStream;
var
    ast:AnsiString;
    s:Ansistring;
    BytesRead:DWORD;
    L,pc:integer;
    CurPar:TFIBXSQLVAR;
    SQLVAR:PXSQLVAR;
    i:integer;

function Skip:Short;
var
    sqlType:Short;
begin
   BytesRead:=FFile.Read(sqlType,SizeOf(Short));
   BytesRead:=FFile.Read(Result,SizeOf(Short));
   BytesRead:=FFile.Read(Result,SizeOf(Short));
   BytesRead:=FFile.Read(Result,SizeOf(Short));
   case sqltype and (not 1)  of
    SQL_VARYING : Inc(Result,2);
    SQL_BLOB    :
    begin
     Result:=-1;
    end;
   end;
end;

begin
  CloseFile;
  FFile:=TFileStream.Create(Filename,fmOpenRead);
{  if FHandle = INVALID_HANDLE_VALUE then
  begin
   FHandle := 0 ;
   FState  :=bsInError;
  end
  else}
  begin
   SetLength(ast,Length(SignRowFile));
   BytesRead:=FFile.Read(ast[1],Length(SignRowFile));
   if (BytesRead<> DWORD(Length(SignRowFile))) or (ast<>SignRowFile) then
   begin
    CloseFile;
    FState  := bsInError;
   end
   else
   begin
    BytesRead:=FFile.Read(ast[1],1);
    FVersion:=StrToInt(ast[1]);
    if FVersion>1 then
    begin
     if Assigned(FMap) then
       FMap.Free;

     BytesRead:=FFile.Read(pc, SizeOf(pc));
     SetLength(SkippedLen,pc);
     FMap:=TList.Create;
     FMap.Capacity:=pc;

     for i:=1 to pc do
     begin
       BytesRead:=FFile.Read(L, SizeOf(L));
       SetLength(s,L);
       if L>0 then
         BytesRead:=FFile.Read(s[1], L);
       CurPar:=Params.ByName[s];
       FMap.Add(CurPar);

       if CurPar=nil then
         SkippedLen[i-1]:=Skip
       else
       begin
        SkippedLen[i-1]:=0;
        SQLVAR:= CurPar.AsXSQLVAR;
        if SQLVAR<>nil then
        begin
         FFile.Read(SQLVAR^.sqltype,SizeOf(Short));
         FFile.Read(SQLVAR^.sqlsubtype,SizeOf(Short));
         FFile.Read(SQLVAR^.sqlscale,SizeOf(Short));
         FFile.Read(SQLVAR^.sqllen,SizeOf(Short));

         if SQLVAR^.sqltype and (not 1) =SQL_VARYING then
          ReallocMem(SQLVAR^.sqldata,SQLVAR^.sqllen+2)
         else
          ReallocMem(SQLVAR^.sqldata,SQLVAR^.sqllen);
        end
        else
         SkippedLen[i-1]:=Skip;
       end
     end;
    end;
     if FVersion>2 then
     begin
//Charset
      FFile.Read(L, SizeOf(L));
      if L>0 then
      begin
       SetLength(FCharset,L);
       FFile.Read(FCharset[1], L);
      end;
      FState  :=bsFileReady
     end;
    FState  :=bsFileReady
   end;
  end;
end;


{ TFIBFileOutputStream }

procedure TFIBFileOutputStream.CloseFile;
begin
  if FFile<>nil then
  begin
   FlushBuf(True,0);  
   FFile.Free;
   FFile:=nil
  end;
end;

constructor TFIBFileOutputStream.Create;
begin
  GetMem(FBuffer,cBufSize);
  FBuffPos:=0;  
  inherited;
end;

destructor TFIBFileOutputStream.Destroy;
begin
  CloseFile;
  if FBuffer <> nil then
   FreeMem(FBuffer);
  inherited Destroy;
end;

procedure TFIBFileOutputStream.FlushBuf(Force: boolean; Count: integer);
begin
   if Force or (FBuffPos+Count>=cBufSize) then
   begin
    FFile.Write(FBuffer^,FBuffPos);
    FBuffPos:=0
   end;
end;

function TFIBFileOutputStream.WriteValue(const ValBuffer;
  Count: Integer): Integer;
begin
  FlushBuf(False,Count);
  if Count>cBufSize then
  begin
   FlushBuf(True,0);
   Result:= FFile.Write(ValBuffer,Count)
  end
  else
  begin
   System.Move(ValBuffer, Pointer(Longint(FBuffer) + FBuffPos)^, Count);
   Inc(FBuffPos,Count);
   Result:= Count;
  end
end;

initialization
  FillChar(NullQUID,SizeOf(NullQUID),0);
  BlobCacheOperation:=TCriticalSection.Create;
finalization
  FreeAndNil(BlobCacheOperation);

end.

