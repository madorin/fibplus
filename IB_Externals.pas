{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ InterBase databases                                           }
{                                                               }
{    FIBPlus is based in part on the product                    }
{    Free IB Components, written by Gregory H. Deatz for        }
{    Hoagland, Longo, Moran, Dunst & Doukas Company.            }
{    mailto:gdeatz@hlmdd.com                                    }
{                                                               }
{    Copyright (c) 1998-2007 Devrace Ltd.                       }
{    Written by Serge Buzadzhy (buzz@devrace.com)               }
{                                                               }
{ ------------------------------------------------------------- }
{    FIBPlus home page: http://www.fibplus.com/                 }
{    FIBPlus support  : http://www.devrace.com/support/         }
{ ------------------------------------------------------------- }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit IB_Externals;

{ Some structures, declarations that we need for the IB stuff to work, but
  that aren't really part of the ib header file. }
interface

uses
{$I FIBPlus.inc}


  FIBPlatforms,StdFuncs;
type
  ISC_INT64            = Int64;   { 64 bit signed  }
  Int                  = LongInt; // 32 bit signed

  UInt                 = DWORD;   // 32 bit unsigned
  Long                 = LongInt; // 32 bit signed
  ULong                = DWORD;   // 32 bit unsigned
  Short                = SmallInt;// 16 bit signed
  UShort               = Word;    // 16 bit unsigned
  Float                = Single;  // 32 bit
  UChar                = Byte;    // 8 bit unsigned
  ISC_LONG             = Long;    // 32 bit signed
  UISC_LONG            = ULong;   // 32 bit unsigned
  ISC_BOOLEAN          = SmallInt; { 16 bit signed  }
  {$IFNDEF WIN64}
   ISC_STATUS           = Long;    // 32 bit signed
   UISC_STATUS          = ULong;   // 32 bit unsigned
  {$ELSE}
   ISC_STATUS           = LONG64;    // 64 bit signed
//   UISC_STATUS          = ULONG64;   // 32 bit unsigned
  {$ENDIF}
//  PUISC_STATUS         = ^UISC_STATUS;
  Void                 = Pointer;
  // Delphi "Pointer types"
  PPChar               = ^PAnsiChar;
  PSmallInt            = ^SmallInt;
  PInt                 = ^Int;
  PInteger             = ^Integer;
  PShort               = ^Short;
  PUShort              = ^UShort;
  PLong                = ^Long;
  PULong               = ^ULong;
  PFloat               = ^Float;
  PUChar               = ^UChar;
  PVoid                = ^Pointer;
  PDouble              = ^Double;
  PISC_LONG            = ^ISC_LONG;
  PUISC_LONG           = ^UISC_LONG;
  PISC_STATUS          = ^ISC_STATUS;
  PPISC_STATUS         = ^PISC_STATUS;


  { C Date/Time Structure }
  TCTimeStructure = record
    tm_sec : integer;   // Seconds
    tm_min : integer;   // Minutes
    tm_hour : integer;  // Hour (0--23)
    tm_mday : integer;  // Day of month (1--31)
    tm_mon : integer;   // Month (0--11)
    tm_year : integer;  // Year (calendar year minus 1900)
    tm_wday : integer;  // Weekday (0--6) Sunday = 0)
    tm_yday : integer;  // Day of year (0--365)
    tm_isdst : integer; // 0 if daylight savings time is not in effect)
  end;
  PCTimeStructure = ^TCTimeStructure;
  TM              = TCTimeStructure;
  PTM             = ^TM;

  TISC_VARYING = record
    strlen: Short;
    str: array[0..0] of Char;
  end;

  {***************************}
  {* Some blob ctl structs   *}
  {* from IB help files for  *}
  {* implementing UDFs .     *}
  {* -- Taken from docs, not *}
  {*    in original ibase.h  *}
  {***************************}
  TISC_BlobGetSegment = function(BlobHandle: PInt;
                                 Buffer: PAnsiChar;
                                 BufferSize: Long;
                                 var ResultLength: Long): Short; cdecl;
  TISC_BlobPutSegment = procedure(BlobHandle: PInt;
                                  Buffer: PAnsiChar;
                                  BufferLength: Short); cdecl;
  TBlob = record
    GetSegment         : TISC_BlobGetSegment;
    BlobHandle         : PInt;
    SegmentCount       : Long;
    MaxSegmentLength   : Long;
    TotalSize          : Long;
    PutSegment         : TISC_BlobPutSegment;
  end;
  PBlob = ^TBlob;

const
  // Delphi consts
  // Days of week
  dSun = 1;  dMon = 2;  dTue = 3;  dWed = 4;  dThu = 5;  dFri = 6;  dSat = 7;
  // Months of year
  dJan = 1;  dFeb = 2;  dMar = 3;  dApr = 4;  dMay = 5;  dJun = 6;
  dJul = 7;  dAug = 8;  dSep = 9;  dOct = 10;  dNov = 11;  dDec = 12;
  // C Consts
  cYearOffset = 1900;
  // Days of week
  cSun = 0;  cMon = 1;  cTue = 2;  cWed = 3;  cThu = 4;  cFri = 5;  cSat = 6;
  // Months of year
  cJan = 0;  cFeb = 1;  cMar = 2;  cApr = 3;  cMay = 4;  cJun = 5;
  cJul = 6;  cAug = 7;  cSep = 8;  cOct = 9;  cNov = 10;  cDec = 11;

procedure InitializeTCTimeStructure(var tm_record: TCTimeStructure);

implementation

procedure InitializeTCTimeStructure(var tm_record: TCTimeStructure);
begin
  with tm_record do
  begin
    tm_sec    := 0;
    tm_min    := 0;
    tm_hour   := 0;
    tm_mday   := 0;
    tm_mon    := 0;
    tm_year   := 0;
    tm_wday   := 0;
    tm_yday   := 0;
    tm_isdst  := 0;
  end;
end;


end.
