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
{    Written by Serge Buzadzhy                                  }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit IB_Externals;

{ Some structures, declarations that we need for the IB stuff to work, but
  that aren't really part of the ib header file. }
interface

uses
{$I FIB.inc}
  FIBPlatforms, StdFuncs;

type
  ISC_INT64 = Int64; { 64 bit signed }
  Int = LongInt; // 32 bit signed
  Long = LongInt; // 32 bit signed
  ULong = DWORD; // 32 bit unsigned
  Short = SmallInt; // 16 bit signed
  UShort = Word; // 16 bit unsigned
  Float = Single; // 32 bit
  UChar = Byte; // 8 bit unsigned
  ISC_LONG = Long; // 32 bit signed
  UISC_LONG = ULong; // 32 bit unsigned
  ISC_BOOLEAN = SmallInt; { 16 bit signed }
{$IFNDEF WIN64}
  ISC_STATUS = Long; // 32 bit signed
{$ELSE}
  ISC_STATUS = LONG64; // 64 bit signed
{$ENDIF}
  // Delphi "Pointer types"
  PSmallInt = ^SmallInt;
  PInt = ^Int;
  PInteger = ^Integer;
  PShort = ^Short;
  PUShort = ^UShort;
  PLong = ^Long;
  PULong = ^ULong;
  PFloat = ^Float;
  PUChar = ^UChar;
  PVoid = ^Pointer;
  PDouble = ^Double;
  PISC_LONG = ^ISC_LONG;
  PUISC_LONG = ^UISC_LONG;
  PISC_STATUS = ^ISC_STATUS;
  PPISC_STATUS = ^PISC_STATUS;

  { C Date/Time Structure }
  TCTimeStructure = record
    tm_sec: Integer; // Seconds
    tm_min: Integer; // Minutes
    tm_hour: Integer; // Hour (0--23)
    tm_mday: Integer; // Day of month (1--31)
    tm_mon: Integer; // Month (0--11)
    tm_year: Integer; // Year (calendar year minus 1900)
    tm_wday: Integer; // Weekday (0--6) Sunday = 0)
    tm_yday: Integer; // Day of year (0--365)
    tm_isdst: Integer; // 0 if daylight savings time is not in effect)
  end;

  PCTimeStructure = ^TCTimeStructure;

implementation

end.
