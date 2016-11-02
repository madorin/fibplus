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
{    Written by Serge Buzadzhy (buzz@devrace.com)               }
{                                                               }
{ ------------------------------------------------------------- }
{    FIBPlus home page: http://www.fibplus.com/                 }
{    FIBPlus support  : http://www.devrace.com/support/         }
{ ------------------------------------------------------------- }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit FIBConsts;

interface
uses FIBPlatforms;


ResourceString
  SCantFindApiProc     ='Can''t find procedure %s in %s';
  SCantLoadLibrary     ='Can''t load library %s ';
  SUnknownClientLibrary='Can''t perform operation %s. Unknown client library';
  STransactionForOtherLibrary='%s.'+CLRF+'Transaction can''t work with different client library.';

  SEdErrorPrefix = 'Error of record updating:';
  SEdDeadLockMess = 'Deadlock detected';
  SEdNotExistRecord = 'Record does not exist';
  SEdMultiplyRecord = 'Attempt to edit multiple records';
  SEdUnknownError = 'Unknown error';
  SCantSort = 'Can''t sort. Invalid parameter: Fields[';
  SCantGetInfo = 'Can''t get info for ';
  SDataBaseNotAssigned = 'Database is not assigned';

  SOKButton = '&OK';
  SCancelButton = '&Cancel';

  SDBEditUserName = '&User name';
  SDBEditPassword = '&Password';
  SDBEditSQLRole = 'Rol&e';

  SLoginDlgLoginCaption = 'Database login';
  SLoginDlgDatabase = 'Database:';



  SCompEditDataSet_ID = '.DataSet_ID should be greater than 0';

  SCompEditDataSetInfoNotExists = 'Table FIB$DATASETS_INFO does not exist.';
  SCompEditDataSetInfoForbid    = 'Can''t use FIB$DATASETS_INFO.'+CLRF+
   'urDataSetInfo not included into Database.UseRepositories.';
  SCompEditUnableInsertInfoRecord = 'Error of inserting new information record';
  SCompEditFieldInfoLoadError = 'Error of loading FieldInfo from stream';

  SFIBErrorCloneCursor = 'Unable to open cloned cursor %s from %s. Incompatible field types.';
  SFIBErrorBeforeDisconnectDetail = 'Error of %s.BeforeDisconnect. Probably you are trying to get access to destroyed components. %s';
  SFIBErrorBeforeDisconnect = 'Error of %s.BeforeDisconnect. %s';
  SFIBErrorAfterDisconnectDetail =  'Error of %s.AfterDisconnect. Probably you are trying to get access to destroyed components. %s';
  SFIBErrorAfterDisconnect =  'Error of %s.AfterDisconnect. %s';
  SFIBErrorNoDBLoginDialog = 'Unable to find Database login dialog. ';
  SFIBErrorInstallPropertyEditorPackage = 'Please, install package with property editors.';
  SFIBErrorIncludeDBLoginDialog =  'Please, add FIBDBLoginDlg into USES statement of your project.';
  SFIBErrorCircularLinks = 'Circular link is not allowed.';
  SFIBErrorParamNotExist = 'Parameter "%s" does not exist in %s';
  SFIBErrorWideStringValueTooLong = '%s. Value for WideString Parameter "%s" too long';
  SFIBParamsCountNotEquelValuesCount= '%s. Parameters count is not equel count of parameter values';
  SFIBErrorEOFInComments = 'EOF in comment detected';
  SFIBErrorEOFInString = 'EOF in string detected';
  SFIBErrorParamNameExpected = 'Parameter name expected';
  SFIBErrorInvalidComp = 'Invalid comp value';
  SFIBErrorNotDataSet = '%s is not TpFIBDataSet';
  SFIBErrorNotDataSetDetail = 'Unable to apply %s because %s is not TpFIBDataSet';
  SFIBErrorNotifyEvent = 'Unable to add NotifyEvent';
  SFIBErrorNotifyEventIndexOut = 'EventList: Index out of range';
  SFIBErrorNotifyEventInvalid = 'EventList: Invalid typecast';
  SFIBErrorHandlerExists = 'Instance of TpFIBErroHandler already exists';
  SFIBErrorUnableStreamLoad = '%s: unable to load from stream';
  SFIBErrorAbortUpdates = 'User abort apply updates for %s %s';
  SFIBErrorUnableGetRecordCount = '%s unable to get number of records';
  SFIBErrorUnableLock = 'Unable to lock record. Update query is empty';
  SFIBErrorGenerationError = '%s: unable to generate %s because fields for "%s" do not exist in dataset.';

  SSuccess = 'Successful execution';
  SDelphiException = 'DelphiException %s';
  SNoOptionsSet = 'No Install Options selected';
  SNoDestinationDirectory = 'DestinationDirectory is not set';
  SNosourceDirectory = 'SourceDirectory is not set';
  SNoUninstallFile = 'Uninstall File Name is not set';
  SOptionNeedsClient = '%s component requires Client to function properly';
  SOptionNeedsServer = '%s component requires Server to function properly';
  SInvalidOption = 'Invalid option specified';
  SInvalidOnErrorResult = 'Unexpected onError return value';
  SInvalidOnStatusResult = 'Unexpected onStatus return value';

  reVarNotArray   = 'Variant is not an array.';
  reVarArrayBounds = 'Variant array index out of bounds.';
  reVarArrayCreate = 'Unable to create variant array.';


  { 06/11/02 }
  SFIBStatNoSave = 'Unable to save statistics. Table "FIB$APP_STATISIC" does not exist.';
  SFIBStatNoSaveAppID = 'Unable to save statistics. ApplicationID is unknown.';


  { 09/25/02 }
  // 07.11.2003
  SCompDatabaseNotConnected = 'Database component is not set properly or not connected';
//19.01.2004

  SEInvalidCharsetData='Invalid data charset  %s. Need charset %s';
  SErrorInProc   ='Error in %s procedure %s ';


implementation

end.











