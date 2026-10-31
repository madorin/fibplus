unit IB_Services deprecated 'Use FIBServices';

interface

{$I FIB.inc}

uses
  ibase, FIBServices;

{$IFDEF INC_SERVICE_SUPPORT}
type
  TpFIBCustomService = FIBServices.TFIBCustomService deprecated 'Use TFIBCustomService';
  TpFIBServerProperties = FIBServices.TFIBServerProperties deprecated 'Use TFIBServerProperties';
  TpFIBControlService = FIBServices.TFIBControlService deprecated 'Use TFIBControlService';
  TpFIBControlAndQueryService = FIBServices.TFIBControlAndQueryService deprecated 'Use TFIBControlAndQueryService';
  TpFIBConfigService = FIBServices.TFIBConfigService deprecated 'Use TFIBConfigService';
  TpFIBLogService = FIBServices.TFIBLogService deprecated 'Use TFIBLogService';
  TpFIBStatisticalService = FIBServices.TFIBStatisticalService deprecated 'Use TFIBStatisticalService';
  TpFIBBackupRestoreService = FIBServices.TFIBBackupRestoreService deprecated 'Use TFIBBackupRestoreService';
  TpFIBBackupService = FIBServices.TFIBBackupService deprecated 'Use TFIBBackupService';
  TpFIBRestoreService = FIBServices.TFIBRestoreService deprecated 'Use TFIBRestoreService';
  TpFIBNBackupService = FIBServices.TFIBNBackupService deprecated 'Use TFIBNBackupService';
  TpFIBNRestoreService = FIBServices.TFIBNRestoreService deprecated 'Use TFIBNRestoreService';
  TpFIBValidationService = FIBServices.TFIBValidationService deprecated 'Use TFIBValidationService';
  TpFIBSecurityService = FIBServices.TFIBSecurityService deprecated 'Use TFIBSecurityService';
  TProtocol = FIBServices.TFIBProtocol;
  TOutputBufferOption = FIBServices.TFIBOutputBufferOption;
  TFIBCustomService = FIBServices.TFIBCustomService;
  TLoginEvent = FIBServices.TFIBServiceLoginEvent;
  TDatabaseInfo = FIBServices.TFIBServerDatabaseInfo;
  TLicenseInfo = FIBServices.TFIBLicenseInfo;
  TLicenseMaskInfo = FIBServices.TFIBLicenseMaskInfo;
  TConfigFileData = FIBServices.TFIBConfigFileData;
  TConfigParams = FIBServices.TFIBConfigParams;
  TVersionInfo = FIBServices.TFIBServerVersionInfo;
  TPropertyOption = FIBServices.TFIBServerPropertyOption;
  TPropertyOptions = FIBServices.TFIBServerPropertyOptions;
  TFIBServerProperties = FIBServices.TFIBServerProperties;
  TFIBControlService = FIBServices.TFIBControlService;
  TServiceGetTextNotify = FIBServices.TFIBServiceGetTextEvent;
  TFIBControlAndQueryService = FIBServices.TFIBControlAndQueryService;
  TShutdownMode = FIBServices.TFIBShutdownMode;
  TFIBConfigService = FIBServices.TFIBConfigService;
  TFIBLogService = FIBServices.TFIBLogService;
  TStatOption = FIBServices.TFIBStatisticsOption;
  TStatOptions = FIBServices.TFIBStatisticsOptions;
  TFIBStatisticalService = FIBServices.TFIBStatisticalService;
  TFIBBackupRestoreService = FIBServices.TFIBBackupRestoreService;
  TBackupOption = FIBServices.TFIBBackupOption;
  TBackupOptions = FIBServices.TFIBBackupOptions;
  TFIBBackupService = FIBServices.TFIBBackupService;
  TRestoreOption = FIBServices.TFIBRestoreOption;
  TRestoreOptions = FIBServices.TFIBRestoreOptions;
  TFIBRestoreService = FIBServices.TFIBRestoreService;
  TFIBNBackupService = FIBServices.TFIBNBackupService;
  TFIBNRestoreService = FIBServices.TFIBNRestoreService;
  TValidateOption = FIBServices.TFIBValidateOption;
  TValidateOptions = FIBServices.TFIBValidateOptions;
  TTransactionGlobalAction = FIBServices.TFIBLimboGlobalAction;
  TTransactionState = FIBServices.TFIBLimboTransactionState;
  TTransactionAdvise = FIBServices.TFIBLimboTransactionAdvise;
  TServiceTransactionAction = FIBServices.TFIBLimboTransactionAction;
  TLimboTransactionInfo = FIBServices.TFIBLimboTransactionInfo;
  TFIBValidationService = FIBServices.TFIBValidationService;
  TUserInfo = FIBServices.TFIBUserInfo;
  TSecurityAction = FIBServices.TFIBSecurityAction;
  TSecurityModifyParam = FIBServices.TFIBSecurityModifyParam;
  TSecurityModifyParams = FIBServices.TFIBSecurityModifyParams;
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

var
  SPBConstantNames: array [1 .. isc_spb_last_spb_constant] of string absolute FIBServices.SPBConstantNames;
  SPBConstantValues: array [1 .. isc_spb_last_spb_constant] of Integer absolute FIBServices.SPBConstantValues;

implementation

uses
  Classes;

{$IFDEF INC_SERVICE_SUPPORT}
initialization
  RegisterClassAlias(TFIBServerProperties, 'TpFIBServerProperties');
  RegisterClassAlias(TFIBConfigService, 'TpFIBConfigService');
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
