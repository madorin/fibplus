unit IB_Services deprecated 'Use FIBServices';

interface

{$I FIBPlus.inc}

uses
  FIBServices;

{$IFDEF INC_SERVICE_SUPPORT}
type
  TpFIBCustomService = FIBServices.TFIBCustomService deprecated 'Use TFIBCustomService';
  TpFIBServerProperties = FIBServices.TFIBServerProperties deprecated 'Use TFIBServerProperties';
  TpFIBControlService = FIBServices.TFIBControlService deprecated 'Use TFIBControlService';
  TpFIBControlAndQueryService = FIBServices.TFIBControlAndQueryService deprecated 'Use TFIBControlAndQueryService';
  TpFIBConfigService = FIBServices.TFIBConfigService deprecated 'Use TFIBConfigService';
  TpFIBLicensingService = FIBServices.TFIBLicensingService deprecated 'Use TFIBLicensingService';
  TpFIBLogService = FIBServices.TFIBLogService deprecated 'Use TFIBLogService';
  TpFIBStatisticalService = FIBServices.TFIBStatisticalService deprecated 'Use TFIBStatisticalService';
  TpFIBBackupRestoreService = FIBServices.TFIBBackupRestoreService deprecated 'Use TFIBBackupRestoreService';
  TpFIBBackupService = FIBServices.TFIBBackupService deprecated 'Use TFIBBackupService';
  TpFIBRestoreService = FIBServices.TFIBRestoreService deprecated 'Use TFIBRestoreService';
  TpFIBNBackupService = FIBServices.TFIBNBackupService deprecated 'Use TFIBNBackupService';
  TpFIBNRestoreService = FIBServices.TFIBNRestoreService deprecated 'Use TFIBNRestoreService';
  TpFIBValidationService = FIBServices.TFIBValidationService deprecated 'Use TFIBValidationService';
  TpFIBSecurityService = FIBServices.TFIBSecurityService deprecated 'Use TFIBSecurityService';
  TProtocol = FIBServices.TProtocol;
  TOutputBufferOption = FIBServices.TOutputBufferOption;
  TFIBCustomService = FIBServices.TFIBCustomService;
  TLoginEvent = FIBServices.TLoginEvent;
  TDatabaseInfo = FIBServices.TDatabaseInfo;
  TLicenseInfo = FIBServices.TLicenseInfo;
  TLicenseMaskInfo = FIBServices.TLicenseMaskInfo;
  TConfigFileData = FIBServices.TConfigFileData;
  TConfigParams = FIBServices.TConfigParams;
  TVersionInfo = FIBServices.TVersionInfo;
  TPropertyOption = FIBServices.TPropertyOption;
  TPropertyOptions = FIBServices.TPropertyOptions;
  TFIBServerProperties = FIBServices.TFIBServerProperties;
  TFIBControlService = FIBServices.TFIBControlService;
  TServiceGetTextNotify = FIBServices.TServiceGetTextNotify;
  TFIBControlAndQueryService = FIBServices.TFIBControlAndQueryService;
  TShutdownMode = FIBServices.TShutdownMode;
  TFIBConfigService = FIBServices.TFIBConfigService;
  TLicensingAction = FIBServices.TLicensingAction;
  TFIBLicensingService = FIBServices.TFIBLicensingService;
  TFIBLogService = FIBServices.TFIBLogService;
  TStatOption = FIBServices.TStatOption;
  TStatOptions = FIBServices.TStatOptions;
  TFIBStatisticalService = FIBServices.TFIBStatisticalService;
  TFIBBackupRestoreService = FIBServices.TFIBBackupRestoreService;
  TBackupOption = FIBServices.TBackupOption;
  TBackupOptions = FIBServices.TBackupOptions;
  TFIBBackupService = FIBServices.TFIBBackupService;
  TRestoreOption = FIBServices.TRestoreOption;
  TRestoreOptions = FIBServices.TRestoreOptions;
  TFIBRestoreService = FIBServices.TFIBRestoreService;
  TFIBNBackupService = FIBServices.TFIBNBackupService;
  TFIBNRestoreService = FIBServices.TFIBNRestoreService;
  TValidateOption = FIBServices.TValidateOption;
  TValidateOptions = FIBServices.TValidateOptions;
  TTransactionGlobalAction = FIBServices.TTransactionGlobalAction;
  TTransactionState = FIBServices.TTransactionState;
  TTransactionAdvise = FIBServices.TTransactionAdvise;
  TServiceTransactionAction = FIBServices.TServiceTransactionAction;
  TLimboTransactionInfo = FIBServices.TLimboTransactionInfo;
  TFIBValidationService = FIBServices.TFIBValidationService;
  TUserInfo = FIBServices.TUserInfo;
  TSecurityAction = FIBServices.TSecurityAction;
  TSecurityModifyParam = FIBServices.TSecurityModifyParam;
  TSecurityModifyParams = FIBServices.TSecurityModifyParams;
  TFIBSecurityService = FIBServices.TFIBSecurityService;
{$ENDIF}

const
  DefaultBufferSize = FIBServices.DefaultBufferSize;
  SPBPrefix = FIBServices.SPBPrefix;
{$IFDEF INC_SERVICE_SUPPORT}
  TCP = FIBServices.TCP;
  SPX = FIBServices.SPX;
  NamedPipe = FIBServices.NamedPipe;
  Local = FIBServices.Local;
  ByLine = FIBServices.ByLine;
  ByChunk = FIBServices.ByChunk;
  Database = FIBServices.Database;
  License = FIBServices.License;
  LicenseMask = FIBServices.LicenseMask;
  ConfigParameters = FIBServices.ConfigParameters;
  Version = FIBServices.Version;
  Forced = FIBServices.Forced;
  DenyTransaction = FIBServices.DenyTransaction;
  DenyAttachment = FIBServices.DenyAttachment;
  LicenseAdd = FIBServices.LicenseAdd;
  LicenseRemove = FIBServices.LicenseRemove;
  DataPages = FIBServices.DataPages;
  DbLog = FIBServices.DbLog;
  HeaderPages = FIBServices.HeaderPages;
  IndexPages = FIBServices.IndexPages;
  SystemRelations = FIBServices.SystemRelations;
  RecordVersions = FIBServices.RecordVersions;
  StatTables = FIBServices.StatTables;
  IgnoreChecksums = FIBServices.IgnoreChecksums;
  IgnoreLimbo = FIBServices.IgnoreLimbo;
  MetadataOnly = FIBServices.MetadataOnly;
  NoGarbageCollection = FIBServices.NoGarbageCollection;
  OldMetadataDesc = FIBServices.OldMetadataDesc;
  NonTransportable = FIBServices.NonTransportable;
  ConvertExtTables = FIBServices.ConvertExtTables;
  DeactivateIndexes = FIBServices.DeactivateIndexes;
  NoShadow = FIBServices.NoShadow;
  NoValidityCheck = FIBServices.NoValidityCheck;
  OneRelationAtATime = FIBServices.OneRelationAtATime;
  Replace = FIBServices.Replace;
  CreateNewDB = FIBServices.CreateNewDB;
  UseAllSpace = FIBServices.UseAllSpace;
  ValidationCheck = FIBServices.ValidationCheck;
  OnlyMetadata = FIBServices.OnlyMetadata;
  FixFssMetadata = FIBServices.FixFssMetadata;
  FixFssData = FIBServices.FixFssData;
  LimboTransactions = FIBServices.LimboTransactions;
  CheckDB = FIBServices.CheckDB;
  IgnoreChecksum = FIBServices.IgnoreChecksum;
  KillShadows = FIBServices.KillShadows;
  MendDB = FIBServices.MendDB;
  SweepDB = FIBServices.SweepDB;
  ValidateDB = FIBServices.ValidateDB;
  ValidateFull = FIBServices.ValidateFull;
  CommitGlobal = FIBServices.CommitGlobal;
  RollbackGlobal = FIBServices.RollbackGlobal;
  RecoverTwoPhaseGlobal = FIBServices.RecoverTwoPhaseGlobal;
  NoGlobalAction = FIBServices.NoGlobalAction;
  LimboState = FIBServices.LimboState;
  CommitState = FIBServices.CommitState;
  RollbackState = FIBServices.RollbackState;
  UnknownState = FIBServices.UnknownState;
  CommitAdvise = FIBServices.CommitAdvise;
  RollbackAdvise = FIBServices.RollbackAdvise;
  UnknownAdvise = FIBServices.UnknownAdvise;
  CommitAction = FIBServices.CommitAction;
  RollbackAction = FIBServices.RollbackAction;
  ActionAddUser = FIBServices.ActionAddUser;
  ActionDeleteUser = FIBServices.ActionDeleteUser;
  ActionModifyUser = FIBServices.ActionModifyUser;
  ActionDisplayUser = FIBServices.ActionDisplayUser;
  ModifyFirstName = FIBServices.ModifyFirstName;
  ModifyMiddleName = FIBServices.ModifyMiddleName;
  ModifyLastName = FIBServices.ModifyLastName;
  ModifyUserId = FIBServices.ModifyUserId;
  ModifyGroupId = FIBServices.ModifyGroupId;
  ModifyPassword = FIBServices.ModifyPassword;
  ModifySecAdmin = FIBServices.ModifySecAdmin;
{$ENDIF}

implementation

uses
  Classes;

{$IFDEF INC_SERVICE_SUPPORT}
initialization
  RegisterClassAlias(TFIBServerProperties, 'TpFIBServerProperties');
  RegisterClassAlias(TFIBConfigService, 'TpFIBConfigService');
  RegisterClassAlias(TFIBLicensingService, 'TpFIBLicensingService');
  RegisterClassAlias(TFIBLogService, 'TpFIBLogService');
  RegisterClassAlias(TFIBStatisticalService, 'TpFIBStatisticalService');
  RegisterClassAlias(TFIBBackupService, 'TpFIBBackupService');
  RegisterClassAlias(TFIBRestoreService, 'TpFIBRestoreService');
  RegisterClassAlias(TFIBNBackupService, 'TpFIBNBackupService');
  RegisterClassAlias(TFIBNRestoreService, 'TpFIBNRestoreService');
  RegisterClassAlias(TFIBValidationService, 'TpFIBValidationService');
  RegisterClassAlias(TFIBSecurityService, 'TpFIBSecurityService');
{$ENDIF}

end.
