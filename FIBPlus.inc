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
{    Written by Serge Buzadzhy (buzz@devrace.com)               }
{                                                               }
{ ------------------------------------------------------------- }
{    FIBPlus home page: http://www.fibplus.com/                 }
{    FIBPlus support  : http://www.devrace.com/support/         }
{ ------------------------------------------------------------- }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

{$DEFINE INTERNAL}
// {$DEFINE NO_GUI}
// {$DEFINE FIBPLUS_TRIAL}
// {$DEFINE SUPPORT_IB2007}
{$DEFINE NO_USE_COMP }

//{$DEFINE CSMonitor}
//{$DEFINE IBINSTALL_SUPPORT}
//{$DEFINE UNICODE_TO_STRING_FIELDS}

// {$DEFINE SUPPORT_KOI8_CHARSET}

//{$ENDIF}

// {$DEFINE NO_MONITOR}


//{$DEFINE LONG_METADATA_NAMES}

//{$DEFINE OBSOLETE_PROPS}
(*For load old dfms*)

//{$DEFINE NO_GUI}

//{$DEFINE USE_DEPRECATE_METHODS1}
//{$DEFINE USE_DEPRECATE_METHODS2}
(* FIBDabase.DataSets ->  FIBDabase.Bases*)



//{$DEFINE DFM_VERSION1}
(* This define for save dfm with old format  *)
(*Conditions and FIBDataSet.Options*)

{$DEFINE SUPPORT_ARRAY_FIELD}
(* This define for ARRAY FIELD SUPPORT  *)
{$DEFINE INC_SERVICE_SUPPORT}
(* This define for include  service components  *)



{$IFDEF VER130}
  {$IFDEF BCB}			// C++Buider 5.0
  {$ObjExportAll on}
  {$ENDIF}
{$ENDIF}

{$IFDEF VER140}
  {$DEFINE D6+}
  {$IFDEF BCB}			// C++Buider 6.0
  {$ObjExportAll on}
  {$ENDIF}
{$ENDIF}

{$IFDEF VER150}
  {$DEFINE D7+}
{$ENDIF}

// Delphi 2005 defines
{$IFDEF VER170}
  {$DEFINE D2005+}
  {$INLINE OFF}
{$ENDIF}

// Delphi 2006
{$IFDEF VER180}
  {$DEFINE D2006+}
  {$DEFINE TWideDataSet}
{$ENDIF}

// Delphi 2007
{$IFDEF VER185}
  {$DEFINE D2007+}
  {$DEFINE TWideDataSet}
{$ENDIF}

// Delphi 2009
{$IFDEF VER200}
  {$DEFINE D2009+}
  {$DEFINE TWideDataSet}
{$ENDIF}

// Delphi 2010
{$IFDEF VER210}
  {$DEFINE D2010+}
  {$DEFINE TWideDataSet}
//  {$WARNINGS  OFF}
{$ENDIF}

// Delphi 2011
{$IFDEF VER220}
  {$DEFINE D_XE}
  {$DEFINE TWideDataSet}
{$ENDIF}

// Delphi XE2
{$IFDEF VER230}
  {$DEFINE D_XE2}
  {$DEFINE TWideDataSet}
{$ENDIF}

// Delphi XE3
{$IFDEF VER240}
  {$DEFINE D_XE3}
{$ENDIF}

// Delphi XE4
{$IFDEF VER250}
  {$DEFINE D_XE4}
{$ENDIF}

// Delphi XE5
{$IFDEF VER260}
  {$DEFINE D_XE5}
{$ENDIF}

// Delphi XE6
{$IFDEF VER270}
  {$DEFINE D_20}
{$ENDIF}

// Delphi XE7
{$IFDEF VER280}
  {$DEFINE D_21}
{$ENDIF}

// Delphi XE8
{$IFDEF VER290}
  {$DEFINE D_22}
{$ENDIF}

// DX10
{$IFDEF VER300}
  {$DEFINE D_23}
{$ENDIF}

// DX10.1
{$IFDEF VER310}
  {$DEFINE D_24}
{$ENDIF}

// DX10.2
{$IFDEF VER320}
  {$DEFINE D_25}
{$ENDIF}

// DX10.3
{$IFDEF VER330}
  {$DEFINE D_26}
{$ENDIF}

// DX10.4
{$IFDEF VER340}
  {$DEFINE D_27}
{$ENDIF}

// DX11
{$IFDEF VER350}
  {$DEFINE D_28}
{$ENDIF}

// DX12
{$IFDEF VER360}
  {$DEFINE D_29}
{$ENDIF}

//---------------------------------

{$IFDEF D_29}
  {$DEFINE D_28}
{$ENDIF}

{$IFDEF D_28}
  {$DEFINE D_27}
{$ENDIF}

{$IFDEF D_27}
  {$DEFINE D_26}
{$ENDIF}

{$IFDEF D_26}
  {$DEFINE D_25}
{$ENDIF}

{$IFDEF D_25}
  {$DEFINE D_24}
{$ENDIF}

{$IFDEF D_24}
  {$DEFINE D_23}
{$ENDIF}

{$IFDEF D_23}
  {$DEFINE D_22}
{$ENDIF}

{$IFDEF D_22}
  {$DEFINE D_21}
{$ENDIF}

{$IFDEF D_21}
  {$DEFINE D_20}
{$ENDIF}

{$IFDEF D_20}
  {$DEFINE D_XE5}
{$ENDIF}

{$IFDEF D_XE5}
  {$DEFINE D_XE4}
{$ENDIF}

{$IFDEF D_XE4}
  {$DEFINE D_XE3}
{$ENDIF}

{$IFDEF D_XE3}
  {$DEFINE D_XE2}
{$ENDIF}

{$IFDEF D_XE2}
  {$DEFINE D_XE}
{$ENDIF}

{$IFDEF D_XE}
  {$DEFINE D2010+}
{$ENDIF}

{$IFDEF D2010+}
  {$DEFINE D2009+}
{$ENDIF}

{$IFDEF D2009+}
  {$DEFINE D2007+}
{$ENDIF}

{$IFDEF D2007+}
  {$DEFINE D2006+}
{$ENDIF}

{$IFDEF D2006+}
  {$DEFINE D2005+}
{$ENDIF}

{$IFDEF D2005+}
  {$DEFINE D7+}
{$ENDIF}

{$IFDEF D7+}
  {$DEFINE D6+}
  {$WARN UNSAFE_TYPE OFF}
  {$WARN UNSAFE_CODE OFF}
  {$WARN UNSAFE_CAST OFF}
  {$WARN SYMBOL_PLATFORM OFF}
//  {$WARNINGS  OFF}
// {$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$ENDIF}

{$IFDEF D2009+}
 {$WARN WIDECHAR_REDUCED OFF}
 {$WARN IMPLICIT_STRING_CAST OFF}
 {$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$ENDIF}

{$IFDEF D6+}
  {$WARN SYMBOL_DEPRECATED OFF}
  {$WARN SYMBOL_PLATFORM OFF}
{$ENDIF}


(* {$IFNDEF LINUX}
   {$DEFINE MSWINDOWS}
 {$ELSE}
   {$DEFINE NO_MONITOR}
   {$DEFINE NO_REGISTRY}
   {$UNDEF SUPPORT_KOI8_CHARSET}
   {$UNDEF SUPPORT_DOS_CHARSET}
 {$ENDIF}
*)

{$IFNDEF LINUX}
 {$IFNDEF  NO_GUI}
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

 {$IFNDEF D2009}
 {$UNDEF UNICODE_TO_STRING_FIELDS}
 {$ENDIF}

 
(*
 * Compiler defines
 *)

{$A+}                           (* Aligned records: On *)
{$B-}                           (* Short circuit boolean expressions: Off *)
{$G+}                           (* Imported data: On *)
{$H+}                           (* Huge Strings: On *)
{$J-}                           (* Modification of Typed Constants: Off *)
{$M+}                           (* Generate run-time type information: On *)
{$Q-}                           (* Overflow checks: Off *)
{$R-}                           (* Range checks: Off *)
{$T+}                           (* Typed address: On *)
{$U+}                           (* Pentim-safe FDIVs: On *)
{$X+}                           (* Extended syntax: On *)
{$Z1}                           (* Minimum Enumeration Size: 1 Byte *)

