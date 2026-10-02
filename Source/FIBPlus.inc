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

{$DEFINE NO_USE_COMP}
{$DEFINE SUPPORT_ARRAY_FIELD}         // ARRAY field support
{$DEFINE INC_SERVICE_SUPPORT}         // include service components

// {$DEFINE NO_GUI}
// {$DEFINE NO_MONITOR}
// {$DEFINE SUPPORT_IB2007}
// {$DEFINE CSMonitor}
// {$DEFINE IBINSTALL_SUPPORT}
// {$DEFINE UNICODE_TO_STRING_FIELDS}
// {$DEFINE SUPPORT_KOI8_CHARSET}
// {$DEFINE OBSOLETE_PROPS}           // load old dfms
// {$DEFINE USE_DEPRECATE_METHODS1}
// {$DEFINE USE_DEPRECATE_METHODS2}   // FIBDabase.DataSets -> FIBDabase.Bases
// {$DEFINE DFM_VERSION1}             // save dfm in the old format (Conditions and FIBDataSet.Options)

{$IFDEF VER140}
  {$IFDEF BCB} // C++Builder 6
    {$OBJEXPORTALL on}
  {$ENDIF}
{$ENDIF}

// Version defines are cumulative: each one stays active on all newer compilers.
{$IF CompilerVersion >= 14}   {$DEFINE D6+}    {$IFEND} // Delphi 6
{$IF CompilerVersion >= 15}   {$DEFINE D7+}    {$IFEND} // Delphi 7
{$IF CompilerVersion >= 17}   {$DEFINE D2005+} {$IFEND} // Delphi 2005
{$IF CompilerVersion >= 18}   {$DEFINE D2006+} {$IFEND} // Delphi 2006
{$IF CompilerVersion >= 18.5} {$DEFINE D2007+} {$IFEND} // Delphi 2007
{$IF CompilerVersion >= 20}   {$DEFINE D2009+} {$IFEND} // Delphi 2009
{$IF CompilerVersion >= 21}   {$DEFINE D2010+} {$IFEND} // Delphi 2010
{$IF CompilerVersion >= 22}   {$DEFINE D_XE}   {$IFEND} // Delphi XE
{$IF CompilerVersion >= 23}   {$DEFINE D_XE2}  {$IFEND} // Delphi XE2
{$IF CompilerVersion >= 24}   {$DEFINE D_XE3}  {$IFEND} // Delphi XE3
{$IF CompilerVersion >= 25}   {$DEFINE D_XE4}  {$IFEND} // Delphi XE4
{$IF CompilerVersion >= 26}   {$DEFINE D_XE5}  {$IFEND} // Delphi XE5
{$IF CompilerVersion >= 27}   {$DEFINE D_20}   {$IFEND} // Delphi XE6
{$IF CompilerVersion >= 28}   {$DEFINE D_21}   {$IFEND} // Delphi XE7
{$IF CompilerVersion >= 29}   {$DEFINE D_22}   {$IFEND} // Delphi XE8
{$IF CompilerVersion >= 30}   {$DEFINE D_23}   {$IFEND} // Delphi 10 Seattle
{$IF CompilerVersion >= 31}   {$DEFINE D_24}   {$IFEND} // Delphi 10.1 Berlin
{$IF CompilerVersion >= 32}   {$DEFINE D_25}   {$IFEND} // Delphi 10.2 Tokyo
{$IF CompilerVersion >= 33}   {$DEFINE D_26}   {$IFEND} // Delphi 10.3 Rio
{$IF CompilerVersion >= 34}   {$DEFINE D_27}   {$IFEND} // Delphi 10.4 Sydney
{$IF CompilerVersion >= 35}   {$DEFINE D_28}   {$IFEND} // Delphi 11 Alexandria
{$IF CompilerVersion >= 36}   {$DEFINE D_29}   {$IFEND} // Delphi 12 Athens
{$IF CompilerVersion >= 37}   {$DEFINE D_30}   {$IFEND} // Delphi 13 Florence

{$IF CompilerVersion = 17} {$INLINE OFF} {$IFEND} // Delphi 2005 only

{$IF (CompilerVersion >= 18) and (CompilerVersion < 24)} // Delphi 2006 .. XE2
  {$DEFINE TWideDataSet}
{$IFEND}

// Warnings

{$WARN SYMBOL_DEPRECATED OFF}
{$WARN SYMBOL_PLATFORM OFF}

{$IFDEF D7+}
  {$WARN UNSAFE_TYPE OFF}
  {$WARN UNSAFE_CODE OFF}
  {$WARN UNSAFE_CAST OFF}
{$ENDIF}

{$IFDEF D2009+}
  {$WARN WIDECHAR_REDUCED OFF}
  {$WARN IMPLICIT_STRING_CAST OFF}
  {$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$ENDIF}

// Platform

{$IFNDEF LINUX}
  {$IFNDEF NO_GUI}
    {$IFNDEF MACOS}
      {$IFNDEF D_XE2}
        {$DEFINE DIRECT_USE_DB_LOGIN_FORM}
      {$ENDIF}
    {$ENDIF}
  {$ENDIF}
{$ENDIF}

{$IFNDEF D7+}
  {$DEFINE WINDOWS}
{$ENDIF}

{$IFDEF MSWINDOWS}
  {$DEFINE WINDOWS}
{$ELSE}
  {$IFNDEF WINDOWS}
    {$DEFINE NO_WINDOWS}
    {$DEFINE NO_REGISTRY}
    {$DEFINE NO_MONITOR}
    {$DEFINE NO_GUI}
    {$UNDEF SUPPORT_KOI8_CHARSET}
    {$UNDEF SUPPORT_DOS_CHARSET}
  {$ENDIF}
{$ENDIF}

{$IFNDEF D2009+}
  {$UNDEF UNICODE_TO_STRING_FIELDS}
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
