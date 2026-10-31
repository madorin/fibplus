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
  SPreferencesCaption               = 'FIBPlus Preferences';
  SPreferencesGeneratorPrefix       = 'Prefix Generator name';
  SPreferencesGeneratorSuffix       = 'Suffix Generator name';
  SPreferencesCharSet               = 'C&harSet';
  SPreferencesSQLDialect            = 'S&QL Dialect';
  SPreferencesStoreConnected        = 'Store Connected';
  SPreferencesSyncTime              = 'Synchronize Time ';
  SPreferencesUpperOldNames         = 'Upper Old Names';
  SPreferencesUseLoginPrompt        = 'Use Login Prompt';
  SPreferencesTimeoutAction         = 'Timeout action';
  SPreferencesTimeout               = 'Timeout';
  SPreferencesGotoFirstRecord       = 'Go to First Record';
  SPreferencesCheckParams           = 'Check parameters';
  SPreferencesAutoStartTransaction  = 'Autostart transaction';
  SPreferencesAutoCommitTransaction = 'Autocommit transaction';

  SPreferencesCloseDesignConnections = 'Close design-time connections before the program runs';
  SPreferencesInvalidTimeout         = 'The timeout must be a whole number, 0 or greater';

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
