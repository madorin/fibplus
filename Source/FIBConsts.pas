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

unit FIBConsts;

interface

uses
  fib;

resourcestring

  SCantFindApiProc            = 'Can''t find procedure %s in %s';
  SUnknownClientLibrary       = 'Can''t perform operation %s. Unknown client library';
  STransactionForOtherLibrary = '%s.' + sLineBreak + 'Transaction can''t work with different client library.';
  SCryptKeyTooLong            = 'The crypt key has %d bytes, but the server accepts at most %d';

  SEdErrorPrefix       = 'Error of record updating:';
  SEdDeadLockMess      = 'Deadlock detected';
  SEdNotExistRecord    = 'Record does not exist';
  SEdMultiplyRecord    = 'Attempt to edit multiple records';
  SEdUnknownError      = 'Unknown error';
  SCantSort            = 'Can''t sort. Invalid parameter: Fields[';
  SCantGetInfo         = 'Can''t get info for ';
  SDataBaseNotAssigned = 'Database is not assigned';

  {$IF FIBLocale = 'en'}
    {$I ..\Locales\en\LoginDlg.inc}
  {$ELSEIF FIBLocale = 'cs'}
    {$I ..\Locales\cs\LoginDlg.inc}
  {$ELSEIF FIBLocale = 'de'}
    {$I ..\Locales\de\LoginDlg.inc}
  {$ELSEIF FIBLocale = 'es'}
    {$I ..\Locales\es\LoginDlg.inc}
  {$ELSEIF FIBLocale = 'pl'}
    {$I ..\Locales\pl\LoginDlg.inc}
  {$ELSEIF FIBLocale = 'pt-BR'}
    {$I ..\Locales\pt-BR\LoginDlg.inc}
  {$ELSEIF FIBLocale = 'ro'}
    {$I ..\Locales\ro\LoginDlg.inc}
  {$ELSEIF FIBLocale = 'ru'}
    {$I ..\Locales\ru\LoginDlg.inc}
  {$ELSEIF FIBLocale = 'uk'}
    {$I ..\Locales\uk\LoginDlg.inc}
  {$ELSE}
    {$MESSAGE FATAL 'Unknown FIBLocale in FIBLocale.inc'}
  {$IFEND}

  SCompEditDataSet_ID = '.DataSet_ID should be greater than 0';

  SCompEditDataSetInfoNotExists   = 'Table FIB$DATASETS_INFO does not exist.';
  SCompEditDataSetInfoForbid      = 'Can''t use FIB$DATASETS_INFO.' + sLineBreak + 'urDataSetInfo not included into Database.UseRepositories.';
  SCompEditUnableInsertInfoRecord = 'Error of inserting new information record';
  SCompEditFieldInfoLoadError     = 'Error of loading FieldInfo from stream';

  SFIBErrorCloneCursor                  = 'Unable to open cloned cursor %s from %s. Incompatible field types.';
  SFIBErrorBeforeDisconnectDetail       = 'Error of %s.BeforeDisconnect. Probably you are trying to get access to destroyed components. %s';
  SFIBErrorBeforeDisconnect             = 'Error of %s.BeforeDisconnect. %s';
  SFIBErrorAfterDisconnectDetail        = 'Error of %s.AfterDisconnect. Probably you are trying to get access to destroyed components. %s';
  SFIBErrorAfterDisconnect              = 'Error of %s.AfterDisconnect. %s';
  SFIBErrorNoDBLoginDialog              = 'Unable to find Database login dialog. ';
  SFIBErrorInstallPropertyEditorPackage = 'Please, install package with property editors.';
  SFIBErrorIncludeDBLoginDialog         = 'Please, add FIBDBLoginDlg into USES statement of your project.';
  SFIBErrorCircularLinks                = 'Circular link is not allowed.';
  SFIBErrorParamNotExist                = 'Parameter "%s" does not exist in %s';
  SFIBErrorWideStringValueTooLong       = '%s. Value for WideString Parameter "%s" too long';
  SFIBParamsCountNotEquelValuesCount    = '%s. Parameters count is not equel count of parameter values';
  SFIBErrorEOFInComments                = 'EOF in comment detected';
  SFIBErrorEOFInString                  = 'EOF in string detected';
  SFIBErrorEOFInMacro                   = 'EOF in macro detected';
  SFIBErrorParamNameExpected            = 'Parameter name expected';
  SFIBErrorInvalidComp                  = 'Invalid comp value';
  SFIBErrorNotifyEvent                  = 'Unable to add NotifyEvent';
  SFIBErrorNotifyEventIndexOut          = 'EventList: Index out of range';
  SFIBErrorNotifyEventInvalid           = 'EventList: Invalid typecast';
  SFIBErrorHandlerExists                = 'Instance of TFIBErrorHandler already exists';
  SFIBErrorUnableStreamLoad             = '%s: unable to load from stream';
  SFIBErrorAbortUpdates                 = 'User abort apply updates for %s %s';
  SFIBErrorUnableGetRecordCount         = '%s unable to get number of records';
  SFIBErrorUnableLock                   = 'Unable to lock record. Update query is empty';
  SFIBErrorGenerationError              = '%s: unable to generate %s because fields for "%s" do not exist in dataset.';
  SFIBErrorExecuteBlockField            = '%s: field %s cannot be written as a literal, UseExecuteBlock does not support array and binary BLOB fields.';
  SFIBErrorExecuteBlockRowSize          = '%s: the statement of a record (%d bytes) does not fit in an EXECUTE BLOCK of 64K, UseExecuteBlock cannot apply it.';
  reVarNotArray                         = 'Variant is not an array.';
  reVarArrayBounds                      = 'Variant array index out of bounds.';
  reVarArrayCreate                      = 'Unable to create variant array.';
  SFIBStatNoSave                        = 'Unable to save statistics. Table "FIB$APP_STATISIC" does not exist.';
  SFIBStatNoSaveAppID                   = 'Unable to save statistics. ApplicationID is unknown.';
  SCompDatabaseNotConnected             = 'Database component is not set properly or not connected';
  SEInvalidCharsetData                  = 'Invalid data charset  %s. Need charset %s';
  SErrorInProc                          = 'Error in %s procedure %s ';

implementation

end.
