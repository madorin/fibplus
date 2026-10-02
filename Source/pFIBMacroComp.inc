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

// Macro substitution emulation for the compiler.

{$IFDEF FP_STDCALL}
  {$IFDEF WINDOWS} stdcall; {$ENDIF}
  {$IFDEF LINUX} cdecl; {$ENDIF}
  {$IFDEF MACOS} cdecl; {$ENDIF}
{$ENDIF}
