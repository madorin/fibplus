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

unit FIBPlatforms;

interface
{$I FIBPlus.inc}
uses
{$IFDEF D_XE2}
 System.UITypes,System.Types,
{$ENDIF}
  {$IFDEF WINDOWS}
   Windows,Messages,SysUtils;
  {$ENDIF}

  {$IFDEF MACOS}
   Classes,SysUtils,Macapi.CoreServices,Macapi.Mach,Macapi.Foundation,Macapi.AppKit,Macapi.CocoaTypes;
  {$ENDIF MACOS}


{$IFDEF WINDOWS}
const
   CLRF =#13#10;
{$ELSE}
const
   CLRF =#10;
{$ENDIF}
type

 {$IFDEF D2009+}
  FIBByteString=RawByteString;
  TDataBuffer=PByte;
 {$ELSE}
  FIBByteString=Ansistring;
  TDataBuffer=PChar ;
 {$ENDIF}
  PFIBByteString=^FIBByteString;


   DWORD = LongWord;
  {$EXTERNALSYM DWORD}

   LONG64 = Int64;
{$IFNDEF D6+}
   PInteger=^Integer;
   PWORD   = ^Word;
   PDouble =^Double;
   PByte   =^Byte;
   PSmallInt=^SmallInt;
   PShortInt=^ShortInt;
   PSingle=^Single;
   HRESULT = type Longint;
{$ENDIF}

 function FIBGetTickCount: Cardinal;
 procedure TerminateApplication;
 function ApplicationPath:string;
 function CurrentThreadID:DWORD;

{$IFNDEF D7+}
function WideCompareStr(const S1, S2: WideString): Integer;
{$ENDIF}
const
{$IFDEF D2009+}
 ZeroData=0;
{$ELSE}
 ZeroData=#0;
{$ENDIF}

implementation

{$IFNDEF D7+}
function DumbItDownFor95(const S1, S2: WideString; CmpFlags: Integer): Integer;
var
  a1, a2: AnsiString;
begin
  a1 := s1;
  a2 := s2;
  Result := CompareStringA(LOCALE_USER_DEFAULT, CmpFlags, PChar(a1), Length(a1),
    PChar(a2), Length(a2)) - 2;
end;

function WideCompareStr(const S1, S2: WideString): Integer;

begin
  SetLastError(0);
  Result := CompareStringW(LOCALE_USER_DEFAULT, 0, PWideChar(S1), Length(S1),
    PWideChar(S2), Length(S2)) - 2;
  case GetLastError of
    0: ;
    ERROR_CALL_NOT_IMPLEMENTED: Result := DumbItDownFor95(S1, S2, 0);
  else
    RaiseLastWin32Error;
  end;
end;
{$ENDIF}

 {$IFDEF WINDOWS}
   function FIBGetTickCount: Cardinal;
   begin
      Result := Windows.GetTickCount;
   end;

   procedure TerminateApplication;
   begin
      PostQuitMessage(0);
   end;
   function ApplicationPath:string;
   begin
    Result:=ExtractFilePath(ParamStr(0))
   end;

   function CurrentThreadID:DWORD;
   begin
    Result:=GetCurrentThreadID
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
       NSApp:=TNSApplication.Wrap(TNSApplication.OCClass.sharedApplication);
       if Assigned(NSApp) then
        NSApp.terminate(nil);
       NSApp:=nil
   end;

    function ApplicationPath:string;
    var
     MainBundle: NSBundle;
    begin
     MainBundle:=TNSBundle.Wrap(TNSBundle.OCClass.mainBundle);
     if Assigned(MainBundle)  then
       Result:=ExtractFilePath(MainBundle.bundlePath.UTF8String)
     else
       Result:='';
     MainBundle:=nil;
    end;

   function CurrentThreadID:DWORD;
   begin
    Result:=TThread.CurrentThread.ThreadID
   end;

 {$ENDIF}



end.



