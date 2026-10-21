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
{    Written by Serge Buzadzhy                                  }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit FIBPlatforms;

interface

{$I FIB.inc}

uses
{$IFDEF C23}
  System.UITypes, System.Types,
{$ENDIF}
{$IFDEF WINDOWS}
  Windows, Messages, SysUtils;
{$ENDIF}
{$IFDEF MACOS}
Classes, SysUtils, Macapi.CoreServices, Macapi.Mach, Macapi.Foundation,
  Macapi.AppKit, Macapi.CocoaTypes;
{$ENDIF MACOS}

type

  FIBByteString = RawByteString;
  TDataBuffer = PByte;
  PFIBByteString = ^FIBByteString;

  DWORD = LongWord;
{$EXTERNALSYM DWORD}
  LONG64 = Int64;

function FIBGetTickCount: Cardinal;
procedure TerminateApplication;
function ApplicationPath: string;
function CurrentThreadID: DWORD;

const
  ZeroData = 0;

implementation

{$IFDEF WINDOWS}
function FIBGetTickCount: Cardinal;
begin
  Result := Windows.GetTickCount;
end;

procedure TerminateApplication;
begin
  PostQuitMessage(0);
end;

function ApplicationPath: string;
begin
  Result := ExtractFilePath(ParamStr(0))
end;

function CurrentThreadID: DWORD;
begin
  Result := GetCurrentThreadID
end;
{$ENDIF}

{$IFDEF MACOS}
function FIBGetTickCount: Cardinal;
begin
  Result := AbsoluteToNanoseconds(mach_absolute_time) div 1000000;
end;

procedure TerminateApplication;
var
  NSApp: NSApplication;
begin
  NSApp := TNSApplication.Wrap(TNSApplication.OCClass.sharedApplication);
  if Assigned(NSApp) then
    NSApp.terminate(nil);
  NSApp := nil
end;

function ApplicationPath: string;
var
  MainBundle: NSBundle;
begin
  MainBundle := TNSBundle.Wrap(TNSBundle.OCClass.MainBundle);
  if Assigned(MainBundle) then
    Result := ExtractFilePath(MainBundle.bundlePath.UTF8String)
  else
    Result := '';
  MainBundle := nil;
end;

function CurrentThreadID: DWORD;
begin
  Result := TThread.CurrentThread.ThreadID
end;

{$ENDIF}

end.
