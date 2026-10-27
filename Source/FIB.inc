{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ InterBase databases                                           }
{                                                               }
{    FIBPlus is based in part on the product                    }
{    Free IB Components, written by Gregory H. Deatz for        }
{    Hoagland, Longo, Moran, Dunst & Doukas Company.            }
{    mailto:gdeatz@hlmdd.com                                    }
{                                                               }
{    Copyright (c) 1998-2012 Devrace Ltd.                       }
{    Written by Serge Buzadzhy                                  }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

// Library options

{$DEFINE SUPPORT_ARRAY_FIELD}         // ARRAY field support
{$DEFINE INC_SERVICE_SUPPORT}         // include service components

// {$DEFINE NO_GUI}
// {$DEFINE NO_MONITOR}
// {$DEFINE SUPPORT_IB2007}
// {$DEFINE CSMonitor}
// {$DEFINE UNICODE_TO_STRING_FIELDS}
// {$DEFINE OBSOLETE_PROPS}           // load old dfms
// {$DEFINE USE_DEPRECATE_METHODS1}
// {$DEFINE USE_DEPRECATE_METHODS2}   // FIBDabase.DataSets -> FIBDabase.Bases
// {$DEFINE DFM_VERSION1}             // save dfm in the old format (Conditions and FIBDataSet.Options)

// The locale of the error messages and of the login dialog is set in FIBLocale.inc

{$IF CompilerVersion < 20}
  {$MESSAGE FATAL 'FIBPlus 8 needs Delphi 2009 or later'}
{$IFEND}

// C<n> = CompilerVersion >= n, active on all newer compilers (VER<n>0 is the exact version).
{$IF CompilerVersion >= 21} {$DEFINE C21} {$IFEND} // Delphi 2010
{$IF CompilerVersion >= 22} {$DEFINE C22} {$IFEND} // Delphi XE
{$IF CompilerVersion >= 23} {$DEFINE C23} {$IFEND} // Delphi XE2
{$IF CompilerVersion >= 24} {$DEFINE C24} {$IFEND} // Delphi XE3
{$IF CompilerVersion >= 25} {$DEFINE C25} {$IFEND} // Delphi XE4
{$IF CompilerVersion >= 26} {$DEFINE C26} {$IFEND} // Delphi XE5
{$IF CompilerVersion >= 27} {$DEFINE C27} {$IFEND} // Delphi XE6
{$IF CompilerVersion >= 28} {$DEFINE C28} {$IFEND} // Delphi XE7
{$IF CompilerVersion >= 29} {$DEFINE C29} {$IFEND} // Delphi XE8
{$IF CompilerVersion >= 30} {$DEFINE C30} {$IFEND} // Delphi 10 Seattle
{$IF CompilerVersion >= 31} {$DEFINE C31} {$IFEND} // Delphi 10.1 Berlin
{$IF CompilerVersion >= 32} {$DEFINE C32} {$IFEND} // Delphi 10.2 Tokyo
{$IF CompilerVersion >= 33} {$DEFINE C33} {$IFEND} // Delphi 10.3 Rio
{$IF CompilerVersion >= 34} {$DEFINE C34} {$IFEND} // Delphi 10.4 Sydney
{$IF CompilerVersion >= 35} {$DEFINE C35} {$IFEND} // Delphi 11 Alexandria
{$IF CompilerVersion >= 36} {$DEFINE C36} {$IFEND} // Delphi 12 Athens
{$IF CompilerVersion >= 37} {$DEFINE C37} {$IFEND} // Delphi 13 Florence

// Warnings

{$WARN SYMBOL_DEPRECATED OFF}
{$WARN UNSAFE_TYPE OFF}
{$WARN UNSAFE_CODE OFF}
{$WARN UNSAFE_CAST OFF}
{$WARN IMPLICIT_STRING_CAST OFF}
{$WARN IMPLICIT_STRING_CAST_LOSS OFF}

// Platform

{$IFNDEF NO_GUI}
  {$IFNDEF C23}
    {$DEFINE DIRECT_USE_DB_LOGIN_FORM}
  {$ENDIF}
{$ENDIF}

{$IFDEF MSWINDOWS}
  {$DEFINE WINDOWS}
{$ELSE}
  {$IFNDEF WINDOWS}
    {$DEFINE NO_WINDOWS}
    {$DEFINE NO_REGISTRY}
    {$DEFINE NO_MONITOR}
    {$DEFINE NO_GUI}
  {$ENDIF}
{$ENDIF}

// Compiler options

{$A+} // Aligned records: On
{$B-} // Short circuit boolean expressions: Off
{$G+} // Imported data: On
{$H+} // Huge strings: On
{$J-} // Modification of typed constants: Off
{$M+} // Generate run-time type information: On
{$Q-} // Overflow checks: Off
{$R-} // Range checks: Off
{$T+} // Typed address: On
{$U+} // Pentium-safe FDIVs: On
{$X+} // Extended syntax: On
{$Z1} // Minimum enumeration size: 1 byte
