unit zStream;
{
  Адаптер zlib для работы с потоками. Сделан на основе кодов
  freeware библиотеки, предназначенной для работы с файлами
  Delphi Zip v.1.6L By Eric W. Engler, Chris Vleghert(cvleghrt@worldonline.nl).
  Код в данном файле "соответствует" методам компоненты TGzip из DelphiGzip.

  Made by Ivan Ravin (ivan_ra@chat.ru)

  19.04.2002
  Это первая бета версия, с минимальной обработкой ошибок.
  Возможно, и последняя :-)
}
interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  {DsgnIntf,} gzsio, zlib;

const
      BUFLEN = 16384;

type
  TCompressionLevel = 0..9;
  TCompressionType = (Standard,Filtered,HuffmanOnly);

function GZipStream(srcStream,dstStream:TStream;
                    CompressionLevel : TCompressionLevel = 6;
                    CompressionType : TCompressionType = Standard) : integer;
function GunZipStream(srcStream,dstStream:TStream) : integer;

implementation
uses
  zutil, crc, zdeflate, zinflate;

{ gz_compress ----------------------------------------------
# This code comes from minigzip.pas with some changes
# Original:
# minigzip.c -- usage example of the zlib compression library
# Copyright (C) 1995-1998 Jean-loup Gailly.
#
# Pascal tranlastion
# Copyright (C) 1998 by Jacques Nomssi Nzali
#
# 0 - No Error
# 1 - Read Error
# 2 - Write Error
# 3 - gzclose error
-----------------------------------------------------------}
function gz_compress (InStream:TStream; outfile:gzFile): integer;
var
  len   : uInt;
  ioerr : integer;
  buf  : packed array [0..BUFLEN-1] of byte; { Global uses BSS instead of stack }
  errorcode : byte;
  fsize, lensize : longword;

begin
  errorcode := 0;
  fsize := InStream.Size;

  lensize := 0;


  while true do begin

    len := InStream.Read(buf, BUFLEN);

    if (len = 0) then break;

    {$WARNINGS OFF}{Comparing signed and unsigned types}
    if (gzwrite (outfile, @buf, len) <> len) then begin
    {$WARNINGS OFF}
      errorcode := 2;
      break
    end;

  end; {WHILE}

  //closeFile (infile);
  if (gzclose (outfile) <> 0{Z_OK}) then errorcode := 3;

  gz_compress := errorcode;
end;

{ gz_uncompress ----------------------------------------------
# This code comes from minigzip.pas with some changes
# Original:
# minigzip.c -- usage example of the zlib compression library
# Copyright (C) 1995-1998 Jean-loup Gailly.
#
# Pascal tranlastion
# Copyright (C) 1998 by Jacques Nomssi Nzali
#
# 0 - No error
# 1 - Read Error
# 2 - Write Error
# 3 - gzclose Error
-----------------------------------------------------------}
function gz_uncompress (infile:gzFile; outStream:TStream;
					  fsize:longword) : integer;
var
  len     : integer;
  written : uInt;
  buf  : packed array [0..BUFLEN-1] of byte; { Global uses BSS instead of stack }
  errorcode : byte;
  lensize : longword;
begin
  errorcode := 0;
  //FProgress := 0;
  lensize := 0;
  //if FProgressStep > 0 then DoOnProgress;

  while true do begin

    len := gzread (infile, @buf, BUFLEN);
    if (len < 0) then begin
      errorcode := 1;
      break
    end;
    if (len = 0)
      then break;

    written := outStream.Write(buf, len);
    {$WARNINGS OFF}{Comparing signed and unsigned types}
    if (written <> len) then begin
    {$WARNINGS ON}
      errorcode := 2;
      break
    end;

  end; {WHILE}

  if (gzclose (infile) <> 0{Z_OK}) then begin
    //if FWindowOnError then
    //  MessageDlg('gzclose Error.', mtError, [mbAbort], 0);
    errorcode := 3
  end;

  gz_uncompress := errorcode
end;

{ GZipStream ---------------------------------------------------
# Returns 0 - dstStream compressed
#         1 - Could not open srcStream
#         2 - Could not write dstStream
#      >100 - Error-100 in gz_compress
---------------------------------------------------------------}
function GZipStream(srcStream,dstStream:TStream;
                    CompressionLevel : TCompressionLevel = 6;
                    CompressionType : TCompressionType = Standard) : integer;
var outmode : string;
    s : string;
    //infile  : file;
    outfile : gzFile;
    errorcode : integer;
    flags : uInt;
    stream : gz_streamp;
    p : PChar;
    ioerr : integer;
begin
  outmode := 'w  ';
  s := IntToStr(CompressionLevel);
  outmode[2] := s[1];
  case CompressionType of
    Standard    : outmode[3] := ' ';
    HuffmanOnly : outmode[3] := 'h';
    Filtered    : outmode[3] := 'f';
  end;
  flags := 0;

  outfile := gzopen (dstStream, outmode, flags);

  if (outfile = NIL) then begin
    errorcode := 2
  end
  else begin
  { if flags are set then write them }

    stream := gz_streamp(outfile);
    { start compressing }
    errorcode := gz_compress(srcStream, outfile);
    if errorcode <> 0 then errorcode := errorcode+100
    else
     {if FDeleteSource then erase (infile)};
  //	  end
  end;
  GZipStream := errorcode
end;

{ GunZipStream --------------------------------------------------
# Returns 0 - dstStream decompressed
#         1 - Could not open srcStream
#         2 - Could not create dstStream
#         3 - srcStream not a valid gzip-file
---------------------------------------------------------------}
function GunZipStream(srcStream,dstStream:TStream) : integer;
var //len : integer;
	infile : gzFile;
	//outfile : file;
	ioerr : integer;
	errorcode : integer;
	fsize : longword;
	s : gz_streamp;
begin
  errorcode := 0;

  infile := gzopen (srcStream, 'r', 0);
  if (infile = NIL) then begin
    errorcode := 1
  end
  else begin
    s := gz_streamp(infile);
    fsize := s^.gzfile.Size;
    dstStream.Size:=0;
    { We could open all files, so time for uncompressing }
    gz_uncompress (infile, dstStream, fsize);
  end;

  GunZipStream := errorcode
end;

end.
