unit pFIBEditorsConsts;

interface

const

(************************************)
(** Database parameter block stuff **)
(************************************)

  isc_dpb_version1               =          1;
  isc_dpb_cdd_pathname           =          1;
  isc_dpb_allocation             =          2;
  isc_dpb_journal                =          3;
  isc_dpb_page_size              =          4;
  isc_dpb_num_buffers            =          5;
  isc_dpb_buffer_length          =          6;
  isc_dpb_debug                  =          7;
  isc_dpb_garbage_collect        =          8;
  isc_dpb_verify                 =          9;
  isc_dpb_sweep                  =         10;
  isc_dpb_enable_journal         =         11;
  isc_dpb_disable_journal        =         12;
  isc_dpb_dbkey_scope            =         13;
  isc_dpb_number_of_users        =         14;
  isc_dpb_trace                  =         15;
  isc_dpb_no_garbage_collect     =         16;
  isc_dpb_damaged                =         17;
  isc_dpb_license                =         18;
  isc_dpb_sys_user_name          =         19;
  isc_dpb_encrypt_key            =         20;
  isc_dpb_activate_shadow        =         21;
  isc_dpb_sweep_interval         =         22;
  isc_dpb_delete_shadow          =         23;
  isc_dpb_force_write            =         24;
  isc_dpb_begin_log              =         25;
  isc_dpb_quit_log               =         26;
  isc_dpb_no_reserve             =         27;
  isc_dpb_user_name              =         28;
  isc_dpb_password               =         29;
  isc_dpb_password_enc           =         30;
  isc_dpb_sys_user_name_enc      =         31;
  isc_dpb_interp                 =         32;
  isc_dpb_online_dump            =         33;
  isc_dpb_old_file_size          =         34;
  isc_dpb_old_num_files          =         35;
  isc_dpb_old_file               =         36;
  isc_dpb_old_start_page         =         37;
  isc_dpb_old_start_seqno        =         38;
  isc_dpb_old_start_file         =         39;
  isc_dpb_drop_walfile           =         40;
  isc_dpb_old_dump_id            =         41;
  isc_dpb_wal_backup_dir         =         42;
  isc_dpb_wal_chkptlen           =         43;
  isc_dpb_wal_numbufs            =         44;
  isc_dpb_wal_bufsize            =         45;
  isc_dpb_wal_grp_cmt_wait       =         46;
  isc_dpb_lc_messages            =         47;
  isc_dpb_lc_ctype               =         48;
  isc_dpb_cache_manager          =         49;
  isc_dpb_shutdown               =         50;
  isc_dpb_online                 =         51;
  isc_dpb_shutdown_delay         =         52;
  isc_dpb_reserved               =         53;
  isc_dpb_overwrite              =         54;
  isc_dpb_sec_attach             =         55;
  isc_dpb_disable_wal            =         56;
  isc_dpb_connect_timeout        =         57;
  isc_dpb_dummy_packet_interval  =         58;
  isc_dpb_gbak_attach            =         59;
  isc_dpb_sql_role_name          =         60;
  isc_dpb_set_page_buffers       =         61;
  isc_dpb_working_directory      =         62;
  isc_dpb_SQL_dialect            =         63;
  isc_dpb_set_db_readonly        =         64;
  isc_dpb_set_db_SQL_dialect     =         65;
  isc_dpb_gfix_attach		 =         66;
  isc_dpb_gstat_attach		 =         67;
//IB 2007
  isc_dpb_gbak_ods_version       =         68;
  isc_dpb_gbak_ods_minor_version =         69;
  isc_dpb_set_group_commit	     =         70;
  isc_dpb_gbak_validate          =         71;
  isc_dpb_client_interbase_var	 =         72;
  isc_dpb_admin_option           =         73;
  isc_dpb_flush_interval         =         74;
  isc_dpb_instance_name	  	     =         75;
  isc_dpb_old_overwrite          =         76;
  isc_dpb_archive_database       =         77;
  isc_dpb_archive_journals       =         78;
  isc_dpb_archive_sweep          =         79;
  isc_dpb_archive_dumps          =         80;
  isc_dpb_archive_recover        =         81;
  isc_dpb_recover_until          =         82;
  isc_dpb_force                  =         83;
//

  isc_dpb_last_dpb_constant      =         isc_dpb_force;

  DPBConstantNames: array[1..isc_dpb_last_dpb_constant] of String = (
    'cdd_pathname',
    'allocation',
    'journal',
    'page_size',
    'num_buffers',
    'buffer_length',
    'debug',
    'garbage_collect',
    'verify',
    'sweep',
    'enable_journal',
    'disable_journal',
    'dbkey_scope',
    'number_of_users',
    'trace',
    'no_garbage_collect',
    'damaged',
    'license',
    'sys_user_name',
    'encrypt_key',
    'activate_shadow',
    'sweep_interval',
    'delete_shadow',
    'force_write',
    'begin_log',
    'quit_log',
    'no_reserve',
    'user_name',
    'password',
    'password_enc',
    'sys_user_name_enc',
    'interp',
    'online_dump',
    'old_file_size',
    'old_num_files',
    'old_file',
    'old_start_page',
    'old_start_seqno',
    'old_start_file',
    'drop_walfile',
    'old_dump_id',
    'wal_backup_dir',
    'wal_chkptlen',
    'wal_numbufs',
    'wal_bufsize',
    'wal_grp_cmt_wait',
    'lc_messages',
    'lc_ctype',
    'cache_manager',
    'shutdown',
    'online',
    'shutdown_delay',
    'reserved',
    'overwrite',
    'sec_attach',
    'disable_wal',
    'connect_timeout',
    'dummy_packet_interval',
    'gbak_attach',
    'sql_role_name',
    'set_page_buffers',
    'working_directory',
    'sql_dialect',
    'set_db_readonly',
    'set_db_sql_dialect',
    'gfix_attach',
    'gstat_attach',
//IB2007
    'gbak_ods_version',              
    'gbak_ods_minor_version',        
    'set_group_commit',              
    'gbak_validate',                 
    'client_interbase_var',          
    'admin_option',                  
    'flush_interval',                
    'instance_name',                 
    'old_overwrite',                 
    'archive_database',              
    'archive_journals',              
    'archive_sweep',                 
    'archive_dumps',                 
    'archive_recover',               
    'recover_until',                 
    'force'

  );

ResourceString

  SCompEditEditFieldInfo = 'Edit field information table';
  SCompEditErrorMessages = 'Edit error messages table';
  SRepositoriesScript = 'Metadata for repository tables';
  SScriptExecutor     = 'Execute script';

  SDBEditCaption = 'Connection Properties';
  SDBEditServerGroup = ' Server ';
  SDBEditServer = '&Server';
  SDBEditNetProtocol = '&Network protocol';
  SDBEditDatabase = '&Database';
  SDBEditAlias = '&Alias name';
  SDBEditLocal = '&Local engine';
  SDBEditRemote = '&Remote server';
  SDBEditBrowse = '&Browse';
  SDBEditConnectParams = 'Connection Parameters';
  SDBEditUserName = '&User name';
  SDBEditPassword = '&Password';
  SDBEditSQLRole = 'Rol&e';
  SDBEditConnectCharSet = 'C&harSet';
  SDBEditSQLDialect = 'S&QL Dialect';
  SDBEditLoginPromt = 'Use lo&gin prompt';
  SDBEditTestButton = '&Test';
  SDBEditGDBFilter =
   'IB/FB Database Files (*.gdb;*.ib;*.fdb)|*.gdb;*.ib;*.fdb|'+
   'Interbase Database Files (*.gdb)|*.gdb|'+
   'Firebird Database Files (*.fdb)|*.fdb|'+
   'Interbase7 Database Files (*.ib)|*.ib|All files (*.*)|*.*';
  SDBEditSuccessConnection = 'Connection is successful';
  SCompDatabaseNotConnected = 'Database component is not set properly or not connected';
  SCompEditInfoFieldsNotExist = 'Table FIB$FIELDS_INFO does not exist. Would you like to create it?';
  SCompEditInfoTableNotExist  = 'Table FIB$DATASETS_INFO does not exist. Would you like to create it?';
  SCompEditErrorTableNotExist = 'Table FIB$ERROR_MESSAGES does not exist. Would you like to create it?';
  
  SOKButton = '&OK';
  SCancelButton = '&Cancel';

//FieldRepository Editor
  SFieldInfoCaption = 'Developers Data Repository';
  SFieldInfoCopyFieldsHint = 'Copy fields from current meta-object';
  SFieldInfoCopyFields = '&Copy fields';
  SFieldInfoFilter = '&Filter by current meta-object';
  SFieldInfoKindTables = 'Tables/Views';
  SFieldInfoProcedures = 'Stored Procedures';
  SFieldInfoFilterHint = 'Filter text';
  SFieldInfoGridHint = 'List of tables or stored procedures';


  SFieldInfoTablesItem = 'Tables';
  SFieldInfoProcedureItem = 'Procedures';
  SFieldInfoUserFormsItem = 'User forms';
// Error repository 


//Conditions Edit frame
  FPConditionsCaption = 'Edit Conditions';
  FPConditionsText = ' Condition text ';
  FPConditionsNames = ' Condition Names ';
  FPConditionsColumnConditions = 'Conditions';
  FPConditionsDelete = '&Delete';
  FPConditionsAdd = '&Add';
  FPConditionsClear = 'C&lear';
//Dataset Repository editor
  SEdDataSetInfoCaption = 'Choose DataSet repository information';
  SEdDataSetInfoFields = 'Other fields';
  SEdDataSetInfoKeyField = 'Key field';
  SEdDataSetInfoGenerator = 'Generator';
  SEdDataSetInfoFilter = 'Filter';

//Transaction Editor
  SCompEditEditTransaction    = 'Edit transaction parameters';
  STransEditCaption = 'Transaction Editor';
  STransEditKind = 'Kind of transaction';
  STransEditSettings = '&Settings:';
  STransEditNewKind = '&New kind';
  STransEditSaveKindButton = '&Save kind';
  STransEditExportButton = '&Export to INI';
  STransEditImportButton = '&Import from INI';
  STransEditOpenFilter = 'Transaction kinds *.trk|*.trk|*.ini |*.ini';
  STransEditSaveFilter = 'Transaction kinds *.trk|*.trk';
  STransEditExportTitle = 'Export transaction settings to file';
  STransEditNewKindDialog = 'Input new kind of transaction';
  STransEditNewKindName = 'Name of kind';

// Dataset Options Editor

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
  FPVisibleRecno = 'Recno for visible records only';

//AutoUpdateOptions
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

//SQL generator
  SGenSQLCaption = 'FIBPlus SQL Generator';
  SGenSQLOptions = 'Options';
  SGenSQLGetFieldsButton = 'Get &table fields';
  SGenSQLGenerateButton = '&Generate SQLs';
  SGenSQLClearButton = '&Clear SQLs';
  SGenSQLOnSaveGroup = 'On save SQLs';
  SGenSQLCheckSQLHint = 'Check SQLs before saving properties';
  SGenSQLCheckSQL = 'Check SQLs';
  SGenSQLFieldOriginHint = 'Save fields origin';
  SGenSQLFieldOrigin = 'Field origins';
  SGenSQLGeneratorOptions = 'Options of SQLs generation';
  SGenSQLPrimaryHint = 'Use only primary key in where clause';
  SGenSQLPrimary = 'Where by primary key';
  SGenSQLNonUpdatePrimaryHint = 'Not to change primary key in UpdateSQL';
  SGenSQLNonUpdatePrimary = 'Not to update primary key';
  SGenSQLDefaultSymbol = 'Use '#39'?'#39' for parameters';
  SGenSQLCheckButton = 'C&heck SQLs';
  SGenSQLKeyFields = 'Key fields';
  SGenSQLUpdateFields = 'Update fields';
  SGenSQL_SQLsTabs = 'SQLs';
  SGenSQLStatement = 'Statement &type';
  SGenSQLMakeSQLTab = 'Make SQL';
  SGenSQLFilterBy = 'Filter by';
  SGenSQLAlias = 'Table alias';
  SGenSQLTablesColumn = 'Tables';
  SGenSQLView1 = 'No Objects';
  SGenSQLView2 = 'Tables/Views';
  SGenSQLView3 = 'Stored Procedures';
  SGenSQLTargetMemo = 'Target memo';
  SGenSQLOutput1 = 'Add to buffer memo';
  SGenSQLOutput2 = 'Replace SelectSQL ';
  SGenSQLOutput3 = 'Add as JOIN to SelectSQL';
  SGenSQLSaveAllButton = 'Save &all';
  SGenSQLReplaceButton = 'Re&place "*"';
  SGenSQLCheckErrorButton = 'Check &error';
  SGenSQLSaveSQLButtonHint = 'Save current SQL';
  SReplaceSQL          = '&Replace Select SQL text';
  SGenSQLSaveSQLButton = '&Save SQL';
  SGenSQLErrorPreffix = 'Error in %s';
  SGenSQLEmpty = 'SQL is empty';
  SGenSQLCorrectSQL = 'SQL is correct';
  SGenSQLFromNotFound = 'Clause "FROM" is not found';


  SCheckSQLs ='Check SQLs';
  SEditSQL   ='Edit SQL text';
  SNoErrors  ='No Errors';
  SErrorIn   ='Error in :';
  SEInvalidCharsetData='Invalid data charset  %s. Need charset %s';
  SErrorInProc   ='Error in %s procedure %s '#13#10;
//Dataset Editor
  SCompEditDBEditor = 'Database Editor';
  SCompEditSQLGenerator = 'SQL Generator';
  SCompSaveToDataSetInfo = 'Save to dataSets repository table';
  SCompChooseDataSetInfo = 'Choose from dataSets repository table';
  SCompEditDataSetInfo = 'Edit dataSets repository table';
  SCompEditDataSet_ID = '.DataSet_ID should be greater than 0';
  SCompEditSQLText          = '(SQL Text)';
  SCompEditStatTableExist   = 'Statistic table already exists.';
  SCompEditStatTableCreated = 'Statistic table has been created successfully.';
  SCompEditCreateStatTable  = 'Create statistic table';
  SCompEditDataSetInfoNotExists = 'Table FIB$DATASETS_INFO does not exist.';
  SCompEditDataSetInfoForbid    = 'Can''t use FIB$DATASETS_INFO.'#13#10+
   'urDataSetInfo not included into Database.UseRepositories.';
  SCompEditUnableInsertInfoRecord = 'Error of inserting new information record';
  SCompEditSaveDataSetProperty = 'Save FIBDataSet properties';
  SCompEditDataSetDesc = 'Set dataset description';
  SCompEditFieldInfoLoadError = 'Error of loading FieldInfo from stream';
  SDataBaseNotAssigned = 'Database is not assigned';
  SCompEditDeltaReceiver1='Create common triggers';
  SCompEditDeltaReceiver2='Create  triggers for table %s';
  SCompEditDeltaReceiverErr1='Can''t create triggers. Table name is empty.';
  SCompEditDeltaReceiverErr2='Can''t create triggers. Transaction not assigned.';
//SQL texts
const
   qryExistTable= 'select COUNT(RDB$RELATION_NAME)'#13#10+
                      'from RDB$RELATIONS where RDB$FLAGS = 1'#13#10+
                      'and RDB$RELATION_NAME=?RT';
   qryExistField='Select Count(*) from RDB$RELATION_FIELDS'#13#10+
    'where    RDB$RELATION_NAME= :TABNAME and RDB$FIELD_NAME =:FIELDNAME';

   qryExistDomain=    'Select Count(*) FROM RDB$FIELDS FLD'#13#10 +
       'WHERE FLD.RDB$FIELD_NAME = ?DOMAIN' ;
   qryCreateBooleanDomain=
    'CREATE DOMAIN FIB$BOOLEAN AS SMALLINT DEFAULT 1 NOT NULL CHECK (VALUE IN (0,1))';
   qryCreateFieldInfoVersionGen ='CREATE GENERATOR FIB$FIELD_INFO_VERSION';

   qryTabFieldsSQL=' Select RDB$FIELD_NAME from  RDB$RELATION_FIELDS '+
     'where  RDB$RELATION_NAME=?tabName order by RDB$FIELD_POSITION';

   qrySPFieldsSQL='select RDB$PARAMETER_NAME, RDB$PARAMETER_NUMBER, RDB$PARAMETER_TYPE '+
   'from RDB$PROCEDURE_PARAMETERS WHERE RDB$PROCEDURE_NAME=?PN  AND RDB$PARAMETER_TYPE=1';


   qryGeneratorExist='    Select COUNT(*) from RDB$GENERATORS   where  RDB$GENERATOR_NAME=:GEN_NAME';

   qryCreateTabFieldsRepository=
       'CREATE TABLE FIB$FIELDS_INFO (TABLE_NAME VARCHAR(31) NOT NULL,'#13#10+
       ' FIELD_NAME VARCHAR(31) NOT NULL,'#13#10+
       ' DISPLAY_LABEL VARCHAR(25),'#13#10+
       ' VISIBLE FIB$BOOLEAN DEFAULT 1 NOT NULL,'#13#10+
       ' DISPLAY_FORMAT VARCHAR(15),'#13#10+
       ' EDIT_FORMAT VARCHAR(15),'#13#10+
       ' TRIGGERED FIB$BOOLEAN DEFAULT 0 NOT NULL,'#13#10+
       ' CONSTRAINT PK_FIB$FIELDS_INFO PRIMARY KEY (TABLE_NAME, FIELD_NAME)'#13#10+
       ')';

   qryCreateFieldRepositoryTriggerBI=
       ' CREATE TRIGGER FIB$FIELDS_INFO_BI FOR FIB$FIELDS_INFO '#13#10+
       ' ACTIVE BEFORE INSERT POSITION 0 AS '+#13#10+
       ' BEGIN '+#13#10+
       '  NEW.FIB$VERSION=GEN_ID(FIB$FIELD_INFO_VERSION,1);'+#13#10+
       ' END';

   qryCreateFieldRepositoryTriggerBU=
       ' CREATE TRIGGER FIB$FIELDS_INFO_BU FOR FIB$FIELDS_INFO '#13#10+
       ' ACTIVE BEFORE UPDATE POSITION 0 AS '+#13#10+
       ' BEGIN '+#13#10+
       '  NEW.FIB$VERSION=GEN_ID(FIB$FIELD_INFO_VERSION,1);'+#13#10+
       ' END';


   qryCreateDataSetsRepository=
       'CREATE TABLE FIB$DATASETS_INFO ('#13#10+
       ' DS_ID INTEGER NOT NULL,'#13#10+
       ' DESCRIPTION VARCHAR(40),'+
       ' SELECT_SQL BLOB sub_type 1 segment size 80,'#13#10+
       ' UPDATE_SQL BLOB sub_type 1 segment size 80,'#13#10+
       ' INSERT_SQL BLOB sub_type 1 segment size 80,'#13#10+
       ' DELETE_SQL BLOB sub_type 1 segment size 80,'#13#10+
       ' REFRESH_SQL BLOB sub_type 1 segment size 80,'#13#10+
       ' NAME_GENERATOR VARCHAR(68), '#13#10+
       ' KEY_FIELD VARCHAR(68),'#13#10+
       ' UPDATE_TABLE_NAME  VARCHAR(68),'#13#10+
       ' UPDATE_ONLY_MODIFIED_FIELDS  FIB$BOOLEAN NOT NULL,'#13#10+
       ' CONDITIONS  BLOB sub_type 1 segment size 80,'#13#10+
       ' FIB$VERSION  INTEGER,'#13#10+
       ' CONSTRAINT PK_FIB$DATASETS_INFO PRIMARY KEY (DS_ID)'#13#10+
       ')';

   qryCreateDataSetRepositoryTriggerBI=
       ' CREATE TRIGGER FIB$DATASETS_INFO_BI FOR FIB$DATASETS_INFO '#13#10+
       ' ACTIVE BEFORE INSERT POSITION 0 AS '+#13#10+
       ' BEGIN '+#13#10+
       '  NEW.FIB$VERSION=GEN_ID(FIB$FIELD_INFO_VERSION,1);'+#13#10+
       ' END';

   qryCreateDataSetRepositoryTriggerBU=
       ' CREATE TRIGGER FIB$DATASETS_INFO_BU FOR FIB$DATASETS_INFO '#13#10+
       ' ACTIVE BEFORE UPDATE POSITION 0 AS '#13#10+
       ' BEGIN '+#13#10+
       '  NEW.FIB$VERSION=GEN_ID(FIB$FIELD_INFO_VERSION,1);'+#13#10+
       ' END';

   qryCreateErrorsRepository=
      'CREATE TABLE FIB$ERROR_MESSAGES ('#13#10+
      ' CONSTRAINT_NAME  VARCHAR(67) NOT NULL,'#13#10+
      ' MESSAGE_STRING   VARCHAR(100),'#13#10+
      ' FIB$VERSION      INTEGER,'#13#10+
      ' CONSTR_TYPE      VARCHAR(11) DEFAULT ''UNIQUE'' NOT NULL,'#13#10+
      ' CONSTRAINT PK_FIB$ERROR_MESSAGES PRIMARY KEY (CONSTRAINT_NAME)'#13#10+
      ')';

   qryCreateErrorsRepositoryTriggerBI=
       ' CREATE TRIGGER FIB$ERROR_MESSAGES_BI FOR FIB$ERROR_MESSAGES '#13#10+
       ' ACTIVE BEFORE INSERT POSITION 0 AS '#13#10+
       ' BEGIN '+#13#10+
       '  NEW.FIB$VERSION=GEN_ID(FIB$FIELD_INFO_VERSION,1);'+#13#10+
       ' END';

   qryCreateErrorsRepositoryTriggerBU=
       ' CREATE TRIGGER FIB$ERROR_MESSAGES_BU FOR FIB$ERROR_MESSAGES '#13#10+
       ' ACTIVE BEFORE UPDATE POSITION 0 AS '#13#10+
       ' BEGIN '+#13#10+
       '  NEW.FIB$VERSION=GEN_ID(FIB$FIELD_INFO_VERSION,1);'+#13#10+
       ' END';

implementation

end.
