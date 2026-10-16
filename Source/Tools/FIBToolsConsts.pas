{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ InterBase databases                                           }
{                                                               }
{    FIBPlus is based in part on the product                    }
{    Free IB Components, written by Gregory H. Deatz for        }
{    Hoagland, Longo, Moran, Dunst & Doukas Company.            }
{    mailto:gdeatz@hlmdd.com                                    }
{                                                               }
{    Copyright (c) 1998-2001 Serge Buzadzhy                     }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit FIBToolsConsts;

interface

resourcestring
  FPTPrefCaption     = 'FIBPlus Preferences';
  FPTGeneratorPref   = 'Prefix Generator name';
  FPTGeneratorSuf    = 'Sufix Generator name';
  FPTCharSet         = 'C&harSet';
  FPTSQLDialect      = 'S&QL Dialect';
  FPTStoreConnected  = 'Store Connected';
  FPTSyncTime        = 'Synchronize Time ';
  FPTUpperOldNames   = 'Upper Old Names';
  FPTUseLoginPrompt  = 'Use Login Prompt';
  FPTTimeoutAction   = 'Timeout action';
  FPTTimeout         = 'Timeout';
  FPTGotoFirstRecord = 'Go to First Record';
  FPTCheckParam      = 'Check parameters';
  FPTAutoStartTrans  = 'Autostart transaction';
  FPTAutoCommitTrans = 'Autocommit transaction';

  FPTCloseDesignConnections = 'Close design-time connections before the program runs';
  FPTInvalidTimeout         = 'The timeout must be a whole number, 0 or greater';

  SOKButton     = '&OK';
  SCancelButton = '&Cancel';

  SToolsMenu            = 'FIBPlus';
  SToolsPreferencesItem = '&Preferences...';
  SToolsAboutItem       = '&About FIBPlus...';
  SAboutCaption         = 'About FIBPlus';
  SAboutProduct         = 'FIBPlus %s';
  SAboutDescription     = 'Components for direct access to Firebird and InterBase';
  SAboutProjectLink     = 'Project on GitHub';
  SAboutSupportLink     = 'Support FIBPlus';

const
  FIBProjectURL = 'https://github.com/madorin/fibplus';
  FIBSupportURL = 'https://github.com/madorin/fibplus/blob/master/Docs/SPONSORS.md';

implementation

end.
