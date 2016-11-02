{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ Interbase databases                                           }
{                                                               }
{    FIBPlus is based in part on the product                    }
{    Free IB Components, written by Gregory H. Deatz for        }
{    Hoagland, Longo, Moran, Dunst & Doukas Company.            }
{    mailto:gdeatz@hlmdd.com                                    }
{                                                               }
{    Copyright (c) 1998-2001 Serge Buzadzhy                     }
{    Contact: buzz@devrace.com                                  }
{                                                               }
{ ------------------------------------------------------------- }
{    FIBPlus home page      : http://www.fibplus.net/           }
{    FIBPlus support e-mail : fibplus@devrace.com               }
{ ------------------------------------------------------------- }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit FIBToolsConsts;

interface

ResourceString
  ErrInstallMess = 'FIBPlusTools are not installed';
  FPFIBPlusMenu = 'FIBP&lus';
  FPPreferencesMenu = '&Preferences...';
  FPSQLNavigator = 'SQL &Navigator...';
  FPBuildMenu = 'FIBPlus %d.%d.%d';
  FPFindComponent='Find component in current form';
  FPFindComponents='Find component in project forms';

  FPTPrefCaption = 'FIBPlus Preferences';
  FPTGeneratorPref = 'Prefix Generator name';
  FPTGeneratorSuf = 'Sufix Generator name';
  FPTCharSet = 'C&harSet';
  FPTSQLDialect = 'S&QL Dialect';
  FPTStoreConnected = 'Store Connected';
  FPTSyncTime = 'Synchronize Time ';
  FPTUpperOldNames = 'Upper Old Names';
  FPTUseLoginPromt = 'Use Login Prompt';
  FPTTimeoutAction = 'Timeout action';
  FPTTimeout = 'Timeout';
  FPTGotoFirstRecord = 'Go to First Record';
  FPTCheckParam = 'Check parameters';
  FPTAutoStartTrans = 'Autostart transaction';
  FPTAutoCommitTrans = 'Autocommit transaction';

  FPTNavCaption = 'FIBPlus SQL Navigator';
  FPTNavGetFormsButtonHint = 'Scan all forms from active project';
  FPTNavCloseFormsButtonHint = 'Close forms opened from SQLnavigator';
  FPTNavSaveSQLButtonHint = 'Save selected SQLs';
  FPTNavFindButtonHint = 'Find in SQLs';
  FPTNavCheckButtonHint = 'Check selected SQLs ';
  FPTNavSaveCallsHint = 'Save project calls to descriptions';
  FPTNavHideSearchButtonHint = 'Hide Search Result';
  FPTNavShowOIButtonHint = 'Show object inspector';
  FPTNavSearchResults = 'Search Result for ""';
  FPTNavSelectAllItem = 'Select All';
  FPTNavUnselectAllItem = 'Unselect All';
  FPTNavGotoCurrentItem = 'Goto current component';
  FPTNavShowResultsItem = 'Show Search Result';
  FPTNavHideResultsItem = 'Hide Search Result';
  FPTNavCopyToClipboardItem = 'Copy to Clipboard';
  FPTNavSaveAllItem = 'Save all SQLs';
  FPTNavSaveSelectSQlItem = 'Save only SelectSQL';
  FPTNavSaveCallsItem = 'Save project calls to descriptions';
  FPTNavClearCallsItem = 'Clear project calls from descriptions';
  FPTNavOptions = 'Options';
  FPTNavIncludeMachineItem = 'Include Machine Name into descriptions';
  FPTNavSQLFilter = 'SQL files (*.sql)|*.sql';
  FPTNavSearchResultCaption = 'Search Result for "%s"';
  FPTNavNotFound = '%s not found';
  FPTNavUnableToGoto = 'Unable to go to component';
  FPTNavProjectsNotExist = 'Table "FIB$PROJECTS" does not exist in %s';



  { 09/25/02 }
  FPNewsgroups = 'Join FIBPlus newsgroups';
  FPNewsgroupsEnglish = 'English';
  FPNewsgroupsRussian = 'Russian';
  FPFeedback = 'Feedback';
  FPFeedbackBug = 'Bug-report';
  FPFeedbackSuggestions = 'Suggestions';
  FPFeedbackInformation = 'Information request';

  FPAutoOptEditorCaption = '%s - AutoUpdateOptions Editor';
  FPAutoOptEditorPrimaryKey = 'Primary key field(s):';
  FPAutoOptEditorModTable = 'Modifying table';
  FPAutoOptEditorSQL = ' SQL generation ';
  FPAutoOptEditorAutoGen = 'Auto generation of modifying queries after DataSet opening';
  FPAutoOptEditorModFields = 'Include in UpdateSQL only modified fields';
  FPAutoOptEditorAutoInc = ' Auto increment options ';
  FPAutoOptEditorGenName = 'Generator Name';
  FPAutoOptEditorWhenGet1 = 'Do not get generator value';
  FPAutoOptEditorWhenGet2 = 'Get new generator value when inserting of new record';
  FPAutoOptEditorWhenGet3 = 'Get new generator value before posting of new record';

  FPConditionsCaption = 'Edit Conditions';
  FPConditionsText = ' Condition text ';
  FPConditionsNames = ' Condition Names ';
  FPConditionsColumnConditions = 'Conditions';
  FPConditionsDelete = '&Delete';
  FPConditionsAdd = '&Add';
  FPConditionsClear = 'C&lear';

  FPOptionsCaption = '%s - Options, PrepareOptions';
  FPOptionsPage = 'Options';
  FPOptionsTrimChars = 'Trim char fields';
  FPOptionsRefresh = 'Refresh current record after posting';
  FPOptionsRefreshDelete = 'Delete non existing records from local buffer';
  FPOptionsAutoStart = 'Auto start transaction before opening';
  FPOptionsApplyFormats = 'Apply DefaultFormats to DisplayFormat and EditFormat';
  FPOptionsIdleUpdate = 'Execute idle update before record editing';
  FPOptionsKeepSort = 'Place modified record according to sorting order';
  FPOptionsRestoreSort = 'Restore local sorting after re-opening';

  FPOptionsPreparePage = 'PrepareOptions';
  FPOptionsSetRequired = 'Set Required property in TField components according to NOT NULL state';
  FPOptionsSetReadOnly = 'Set ReadOnly property in TField components for calculated fields';
  FPOptionsSetDefault = 'Set Default property of TField components according to table description';
  FPOptionsEmulateBoolean = 'Emulate boolean fields';
  FPOptionsCreateBCD = 'Create TBCDField instances for INT64 fields with any scale (SQLDialect 3)';
  FPOptionsApplyRepository = 'Apply FIBPlus Repository options to field propetries, queries, etc';
  FPOptionsSortFields = 'Fill SortFields property using ORDER BY clause';
  FPOptionsRecordCount = 'Get record count without fetching all records';

  SOKButton = '&OK';
  SCancelButton = '&Cancel';

implementation

end.


