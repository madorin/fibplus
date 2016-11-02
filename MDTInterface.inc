(******************************************************************************)
(*          GrossBee LTD (www.grossbee.com)   Ukrain, Dnipropetrovsk          *)
(*                     Project "MIRROR DATABASE TOOLS"                        *)
(*============================================================================*)
(*                 Interface for link with other component libraries          *)
(*                               inc part                                     *)
(*                                                                            *)
(* Mishenkov A.G.                                                 12.06.2010. *)
(******************************************************************************)
uses Classes, SysUtils;


type
  TMDTVariableStructureType=byte;

const
  mdt_vstUnknown    = 0;
  mdt_vstInteger    = 1;
  mdt_vstDouble     = 2;
  mdt_vstString     = 3;
  mdt_vstSmallInt   = 4;
  mdt_vstTimeStamp  = 5;
  mdt_vstBoolean    = 6;
  mdt_vstInt64      = 7;
  mdt_vstGUID       = 8;
  mdt_vstExtended   = 9;

  mdt_vstUnitMaxCode=9;
  mdt_vstReserveBorderCode = 1000;

  mdt_AllVariableMaxDinamicLength=High(Longint) - SizeOf(Integer);
  mdt_OneVariableMaxDinamicLength=mdt_AllVariableMaxDinamicLength div 255;

type
  TMDTVariableStringCompareType=byte;

  TMDTTimeStampMode=(
    tsmFull,
    tsmOnlyDate,
    tsmOnlyTime);

  TMDTFloatType=(
    tftDouble,
    tftFloat);

type
  TMDTIsolationLevel=(
    ilReadCommited,
    ilSnapshot);

  TMDTEnableOper=(
    eoRead,
    eoReadWrite);

  PTimeStamp=^TTimeStamp;
  PBoolean=^boolean;

  TMDTSQLExecutor=(
    se_Server,
    se_Local,
    se_ServerAfterLocal);

  TMDTCursorState=(
    csUnknow,
    csAfterLast,
    csBeforeFirst,
    csInside);

const
  mdt_mopSQLText = 1;
  mdt_mopServerExecute = 2;
  mdt_mopTableName = 3;
  mdt_mopAliasName = 4;
  mdt_mopProcedureName = 5;
  mdt_mopComment = 6;
  mdt_mopIndexName = 7;
  mdt_mopDatabaseName = 8;

  mdt_mopMinPropertyNumber = 1;
  mdt_mopMaxPropertyNumber = 8;

const
  mdt_momCommon = 1;
  mdt_momOpen = 2;
  mdt_momFetch = 3;
  mdt_momClose = 4;
  mdt_momExecSQL = 5;
  mdt_momActualData = 7;
  mdt_momReadInsertUpdate = 8;
  mdt_momReadDelete = 9;
  mdt_momActivate = 10;
  mdt_momDeactivate = 11;
  mdt_momTableInsert_TMDTDatabase = 12;
  mdt_momTableUpdate_TMDTDatabase = 13;
  mdt_momTableDelete_TMDTDatabase = 14;
  mdt_momTableInsert = 15;
  mdt_momTableUpdate = 16;
  mdt_momTableDelete = 17;
  mdt_momReadInsertUpdateClient = 18;
  mdt_momReadDeleteClient = 19;
  mdt_momIndexComplete = 20;
  mdt_momFlush = 21;
  mdt_momTableSaveVersion = 22;
  mdt_momTableCheckVersion = 23;
  mdt_momTableDeleteVersion = 24;
  mdt_momActivateMetaData = 25;
  mdt_momDeactivateMetaData = 26;
  mdt_momOpenLocalDataControler = 27;
  mdt_momCloseLocalDataControler = 28;
  mdt_momMakeMirrorDatabase = 29;
  mdt_momActivateMirrorDatabase = 30;
  mdt_momTestConnect = 31;
  mdt_momReadSendedPackets = 32;
  mdt_momDirectReadEvents = 33;
  mdt_momReplicationFromDestMirror = 34;
  mdt_momReplicationToDestMirror = 35;
  mdt_momDeleteNotReplicateDataInDestMirror = 36;
  mdt_momReOpenLocalDataControler = 37;


const
  iid_MDTMasterObject: TGUID =
    '{1B075524-1204-4AB0-BF02-A75BC3D6A8B4}';
type
  IMDTMasterObject=interface(IUnknown)
  ['{1B075524-1204-4AB0-BF02-A75BC3D6A8B4}']
    procedure LinkedChieldDestroy(AIChield:IUnknown); stdcall;
    procedure LinkedChieldBeforeConnect(AIChield:IUnknown); stdcall;
    procedure LinkedChieldAfterConnect(AIChield:IUnknown); stdcall;
    procedure LinkedChieldBeforeDisconnect(AIChield:IUnknown); stdcall;
    procedure LinkedChieldAfterDisconnect(AIChield:IUnknown); stdcall;
    end;

const
  iid_MDTChieldObject: TGUID =
    '{89FD382E-B601-4855-A674-111CD54DB723}';
type
  IMDTChieldObject=interface(IUnknown)
  ['{89FD382E-B601-4855-A674-111CD54DB723}']
    procedure AddMasterLink(
      AIMaster:IMDTMasterObject); stdcall;
    procedure DeleteMasterLink(AMaster:IMDTMasterObject); stdcall;
    end;

const
  iid_MDTGarbageObject: TGUID =
    '{EF05F85D-8336-481E-8B81-0A36174816F3}';
type
  IMDTGarbageObjects=interface(IUnknown)
  ['{EF05F85D-8336-481E-8B81-0A36174816F3}']
    procedure AddObject(AObject:TObject);
    procedure StartBlock;
    procedure StopBlock;
    end;

const
  iid_MDTVariable: TGUID =
    '{CD40CA94-4FAB-4F9B-BA28-693797AF42CE}';
type
  IMDTVariable=interface(IUnknown)
  ['{CD40CA94-4FAB-4F9B-BA28-693797AF42CE}']
    function GetName: AnsiString;
    function GetStructureType: TMDTVariableStructureType;
    function GetMaxLength: integer;
    function GetAlwaysMaxLength: boolean;
    function GetPrecision: byte;
    function GetTimeStampMode: TMDTTimeStampMode;
    function GetNotNull: boolean;

    property Name: AnsiString read GetName;
    property StructureType: TMDTVariableStructureType read GetStructureType;
    property MaxLength: integer read GetMaxLength;
    property AlwaysMaxLength: boolean read GetAlwaysMaxLength;
    property Precision: byte read GetPrecision;
    property TimeStampMode: TMDTTimeStampMode read GetTimeStampMode;
    property NotNull: boolean read GetNotNull;
    end;

const
  iid_MDTVariables: TGUID =
    '{E34783F8-C18F-4025-9D6E-F53F9949CD64}';
type
  IMDTVariables=interface(IUnknown)
  ['{E34783F8-C18F-4025-9D6E-F53F9949CD64}']
    function GetOwnerObject: TObject;
    function GetVariableCount: integer;
    function GetIVariable(AIndex: integer): IMDTVariable;
    function VariableByOrderNumToIndex(ANum: integer):integer;


    property VariableCount: integer read GetVariableCount;
    property IVariable[AIndex: integer]: IMDTVariable read GetIVariable;
    end;

const
  iid_MDTDataRecord: TGUID =
    '{6A4903A6-D57B-4B87-A051-C0EE7196ABE9}';
type
  IMDTDataRecord=interface(IUnknown)
  ['{6A4903A6-D57B-4B87-A051-C0EE7196ABE9}']
    function GetOwnerObject: TObject;
    function GetIVariables: IMDTVariables;
    function GetIsNullMark(AIndex: integer): boolean;
    procedure GetDataBuffer(AIndex: integer; var RDataBuffer: pointer;
      var RSize: integer);
    procedure ClearValue(AIndex: integer);
    procedure WriteDataToBuffer(AIndex: integer; ADataBuffer: pointer;
      ASize: integer); overload;
    procedure WriteDataToBuffer(AIndex: integer; AStream: TStream;
      ASize: integer = -1); overload;
    function GetIntegerValue(AIndex: integer): integer;
    procedure SetIntegerValue(AIndex:integer; AValue:integer);
    function GetSmallIntValue(AIndex: integer): smallInt;
    procedure SetSmallIntValue(AIndex: integer; AValue: smallInt);
    function GetDoubleValue(AIndex: integer): Double;
    procedure SetDoubleValue(AIndex: integer; AValue: Double);
    function GetExtendedValue(AIndex: integer): Extended;
    procedure SetExtendedValue(AIndex: integer; AValue: Extended);
    function GetBooleanValue(AIndex: integer): Boolean;
    procedure SetBooleanValue(AIndex: integer; AValue: Boolean);
    function GetTimeStampValue(AIndex: integer): TTimeStamp;
    procedure SetTimeStampValue(AIndex: integer; AValue: TTimeStamp);
    function GetInt64Value(AIndex: integer): int64;
    procedure SetInt64Value(AIndex: integer; AValue: int64);
    function GetStringValue(AIndex: integer): AnsiString;
    procedure SetStringValue(AIndex: integer; AValue: AnsiString);

    property IVariables: IMDTVariables read GetIVariables;
    property IsNull[AIndex: integer]: boolean read GetIsNullMark;
    property IntegerValue[AIndex: integer]: integer
      read GetIntegerValue write SetIntegerValue;
    property SmallIntValue[AIndex: integer]: smallInt
      read GetSmallIntValue write SetSmallIntValue;
    property DoubleValue[AIndex: integer]: Double
      read GetDoubleValue write SetDoubleValue;
    property ExtendedValue[AIndex: integer]: Extended
      read GetExtendedValue write SetExtendedValue;
    property BooleanValue[AIndex: integer]: Boolean
      read GetBooleanValue write SetBooleanValue;
    property TimeStampValue[AIndex: integer]: TTimeStamp
      read GetTimeStampValue write SetTimeStampValue;
    property Int64Value[AIndex: integer]: int64
      read GetInt64Value write SetInt64Value;
    property StringValue[AIndex: integer]: AnsiString
      read GetStringValue write SetStringValue;
    end;

const
  iid_MDTSQLEvalution: TGUID =
    '{1B34210F-2F37-493C-BAA8-ED08ABE33997}';
type
  IMDTSQLEvalution=interface(IUnknown)
  ['{1B34210F-2F37-493C-BAA8-ED08ABE33997}']
    end;

const
  iid_MDTSQLParamEvalutions: TGUID =
    '{CE8BBCA2-6AD6-4C9C-83A9-AC1D0379363F}';
type
  IMDTSQLParamEvalutions=interface(IUnknown)
  ['{CE8BBCA2-6AD6-4C9C-83A9-AC1D0379363F}']
    function GetCount: integer;
    procedure FillVariables(AVariables:IMDTVariables);

    property Count: integer read GetCount;
    end;

const
  iid_MDTSQLSelect: TGUID =
    '{979A3C3C-D5E3-4FD0-B290-16663A1671B1}';
type
  IMDTSQLSelect=interface(IUnknown)
  ['{979A3C3C-D5E3-4FD0-B290-16663A1671B1}']
    function GetOwnerObject: TObject;
    end;

const
  iid_MDTLexicalAnalizer: TGUID =
    '{AC061E8B-62F7-42ED-8ADC-9FE8FF0A2591}';
type
  IMDTLexicalAnalizer=interface(IUnknown)
  ['{AC061E8B-62F7-42ED-8ADC-9FE8FF0A2591}']
    procedure SetSourceText(ASourceText: TStringList);
    end;

const
  iid_MDTSQLSelectParser: TGUID =
    '{0D8EA340-813F-4D88-B711-82651176DE57}';
type
  IMDTSQLSelectParser=interface(IUnknown)
  ['{0D8EA340-813F-4D88-B711-82651176DE57}']
    function GetOwnerObject: TObject;
    function ITranslate(AStartErrorKey: boolean): IMDTSQLSelect;
    procedure CheckEndOfText;
    end;

const
  iid_MDTFindTableByField: TGUID =
    '{6FDB97B7-7B7B-4B6E-9AB9-4BA382263FB0}';
type
  IMDTFindTableByField=interface(IUnknown)
  ['{6FDB97B7-7B7B-4B6E-9AB9-4BA382263FB0}']
    function GetTableNameByField(AFieldIndex: integer): AnsiString;
    function GetTableAliasByField(AFieldIndex: integer): AnsiString;
    end;

const
  iid_MDTSQLBuildDataOrderAddData: TGUID =
    '{9811EEF3-72A9-4032-91D1-DD827A1E8C1A}';
type
  IMDTSQLBuildDataOrderAddData=interface(IUnknown)
  ['{9811EEF3-72A9-4032-91D1-DD827A1E8C1A}']
    function GetOwnerObject: TObject;
    function GetFindTableByField: IMDTFindTableByField;
    function GetMonitorProcExist: boolean;

    property FindTableByField: IMDTFindTableByField read GetFindTableByField;
    property MonitorProcExist: boolean read GetMonitorProcExist;
    end;

const
  iid_MDTTreeString: TGUID =
    '{372BFAAC-E9CF-417C-AD1E-9B57FD434786}';
type
  IMDTTreeString=interface(IUnknown)
  ['{372BFAAC-E9CF-417C-AD1E-9B57FD434786}']
    function GetOwnerObjec: TObject;
    function GetText: AnsiString;
    procedure SetText(AValue: AnsiString);
    function GetIChildCount: integer;
    function GetIChild(AIndex: integer): IMDTTreeString;
    property Text: AnsiString read GetText write SetText;
    end;

const
  iid_MDTDataOrder: TGUID =
    '{19DF9633-7A11-4718-9D02-02204DFED96E}';
type
  IMDTDataOrder=interface(IUnknown)
  ['{19DF9633-7A11-4718-9D02-02204DFED96E}']
    function GetOpened: boolean;
    procedure Close;
    procedure FreeWithSourceOrders;
    procedure ActualTablesLocalStorage;
    procedure Open;
    procedure Next;
    function GetCursorState: TMDTCursorState;
    procedure SetParamsDataRecord(ADataRecord: IMDTDataRecord);
    function GetIZeroLeavingRecord: IMDTDataRecord;
    function GetOwnerObject: TObject;
    function CreateIDescription: IMDTTreeString;

    property Opened: boolean read GetOpened;
    property CursorState: TMDTCursorState read GetCursorState;
    property IZeroLeavingRecord: IMDTDataRecord read GetIZeroLeavingRecord;
    end;

const
  iid_MDTSQLProcessor: TGUID =
    '{A63104C6-93FB-42BA-84B1-59458F7315BD}';
type
  IMDTSQLProcessor=interface(IUnknown)
  ['{A63104C6-93FB-42BA-84B1-59458F7315BD}']
    procedure ClientPrepareSelectData(ASelect: IMDTSQLSelect);
    function CreateBuildDataOrderAddData: IMDTSQLBuildDataOrderAddData;
    function BuildSelectDataOrder(ASelect: IMDTSQLSelect;
      RAddData: IMDTSQLBuildDataOrderAddData): IMDTDataOrder;
    function GetIParamEvalutions: IMDTSQLParamEvalutions;

    property IParamEvalutions: IMDTSQLParamEvalutions read GetIParamEvalutions;
    end;

const
  iid_MDTDatabaseConnectParams: TGUID =
    '{BA1903CD-155E-4022-93C4-C057B5306C8E}';
type
  IMDTDatabaseConnectParams=interface(IUnknown)
  ['{BA1903CD-155E-4022-93C4-C057B5306C8E}']
   procedure SetUserName(AValue:AnsiString);
   function GetUserName:AnsiString;
   procedure SetPassword(AValue:AnsiString);
   function GetPassword:AnsiString;
   procedure SetRoleName(AValue:AnsiString);
   function GetRoleName:AnsiString;

   property UserName:AnsiString read GetUserName write SetUserName;
   property Password:AnsiString read GetPassword write SetPassword;
   property RoleName:AnsiString read GetRoleName write SetRoleName;
   end;

const
  iid_MDTRealDataBase: TGUID =
    '{C66F622B-B883-4C70-A620-13791DF61DF0}';
type
  IMDTRealDataBase=interface(IUnknown)
  ['{C66F622B-B883-4C70-A620-13791DF61DF0}']
    end;

const
  iid_MDTTransactionParams: TGUID =
    '{358A6CDA-8624-4553-BB26-28530D57192C}';
type
  IMDTTransactionParams=interface(IUnknown)
  ['{358A6CDA-8624-4553-BB26-28530D57192C}']
    function GetOwnerObject: TObject;
    function GetIsolationLevel: TMDTIsolationLevel;
    procedure SetIsolationLevel(AValue: TMDTIsolationLevel);
    function GetEnableOper: TMDTEnableOper;
    procedure SetEnableOper(AValue: TMDTEnableOper);

    property IsolationLevel: TMDTIsolationLevel
      read GetIsolationLevel write SetIsolationLevel;
    property EnableOper:TMDTEnableOper read GetEnableOper write SetEnableOper;
    end;

const
  iid_MDTRealDBTransaction: TGUID =
    '{27F2A58B-355E-4BBE-A245-4DD9671645C8}';
type
  IMDTRealDBTransaction=interface(IUnknown)
  ['{27F2A58B-355E-4BBE-A245-4DD9671645C8}']
    function GetOwnerObject: TObject;
    function GetActive: boolean;
    procedure Rollback;

    property Active: boolean read GetActive;
    end;

const
  iid_MDTRealDBCanal: TGUID =
    '{244A9528-959C-4B80-933F-9C2AA13A61CB}';
type
  IMDTRealDBCanal=interface(IUnknown)
  ['{244A9528-959C-4B80-933F-9C2AA13A61CB}']
    function GetOwnerObject: TObject;
    function GetIDatabaseConnectParams:IMDTDatabaseConnectParams;
    function GetIMDTRealDataBase:IMDTRealDataBase;
    function CreateIMDTTransactionParams:IMDTTransactionParams;
    function CreateIMDTRealDBTransaction:IMDTRealDBTransaction;

    property IDatabaseConnectParams:IMDTDatabaseConnectParams
      read GetIDatabaseConnectParams;
    property IMDTRealDataBase:IMDTRealDataBase
      read GetIMDTRealDataBase;
    end;

const
  iid_MDTProtectedBlock: TGUID =
    '{34DDF342-9EDD-4C14-9EB3-9DEC31EEE36E}';
type
  IMDTProtectedBlock=interface(IUnknown)
  ['{85D1F66F-71C2-49F6-B630-386F6C314CA3}']
    function GetOwnerObject: TObject;
    end;

const
  iid_MDTProtectedBlocks: TGUID =
    '{B288C36C-FD78-41A3-8D54-7F7D3CDB2C9F}';
type
  IMDTProtectedBlocks=interface(IUnknown)
  ['{B288C36C-FD78-41A3-8D54-7F7D3CDB2C9F}']
    function GetBlockCount: integer;
    function FindByName(AName: AnsiString): IMDTProtectedBlock;
    function ILast: IMDTProtectedBlock;

    property BlockCount: integer read GetBlockCount;
    end;

const
  iid_MDTMonitorObject: TGUID =
    '{045C1192-6661-47E4-A94C-A0E3D2D0B154}';
type
  IMDTMonitorObject=interface(IUnknown)
  ['{045C1192-6661-47E4-A94C-A0E3D2D0B154}']
    function GetOwnerObject: TObject;
    function GetID: integer;
    procedure SetID(AID: integer);

    property ID: integer read GetID write SetID;
    end;

const
  iid_MDTMonitorSelectObject: TGUID =
    '{DBD1F320-1A1E-4CC0-ABAB-27C1DD2BB124}';
type
  IMDTMonitorSelectObject=interface(IMDTMonitorObject)
  ['{DBD1F320-1A1E-4CC0-ABAB-27C1DD2BB124}']
    function GetSQLText: AnsiString;
    procedure SetSQLText(ASQLText: AnsiString);
    function GetServerExecute: boolean;
    procedure SetServerExecute(AValue: boolean);

    property SQLText: AnsiString read GetSQLText write SetSQLText;
    property ServerExecute: boolean read GetServerExecute write SetServerExecute;
    end;

const
  iid_MDTMonitor: TGUID =
    '{C7757D0E-1BA4-4B8F-AA45-626D18DD8966}';
type
  IMDTMonitor=interface(IUnknown)
  ['{C7757D0E-1BA4-4B8F-AA45-626D18DD8966}']
    function CreateSelectObject: IMDTMonitorSelectObject;
    procedure RegisterObject(AMonitorObject: IMDTMonitorObject);
    function StartAction(AObjectID: integer; AActionType: integer): integer;
    procedure StopAction(AObjectID: integer; AActionID: integer = -1);
    function ContinueAction(AObjectID: integer; AActionID: integer;
      AActionType: integer): integer;
    end;

const
  iid_MDTDatabase: TGUID =
    '{D2678073-531D-4EBB-972C-A6A5EC0BCBF0}';
type
  IMDTDatabase=interface(IUnknown)
  ['{D2678073-531D-4EBB-972C-A6A5EC0BCBF0}']
    procedure SetConnected(AConnect:boolean);
    function GetConnected:boolean;

    function GetChieldObject:IMDTChieldObject;
    function GetRealDBCanalCount:integer;
    function GetIRealDBCanal(AIndex:integer):IMDTRealDBCanal;
    function GetProtectedBlocks: IMDTProtectedBlocks;
    procedure NewProtectedBlock(var RTransactionParams:IMDTTransactionParams;
      AAtomic:boolean=false); overload;
    procedure NewProtectedBlock(AAtomic:boolean; AName: AnsiString = ''); overload;
    procedure PrepareRealDBCanalForDirrectSQL(ARealDBCanal:IMDTRealDBCanal);
    procedure CommitSepareteTransaction(
      ARealDBTransaction:IMDTRealDBTransaction; ARetain:boolean);
    procedure CommitProtectedBlock;
    procedure RollbackProtectedBlock;
    procedure CloseAllBlocksAndRetainTransaction(ACommit:boolean);

    function GetISQLLexicalAnalizer: IMDTLexicalAnalizer;
    function GetISQLProcessor: IMDTSQLProcessor;
    function CreateISQLClientSelectParser: IMDTSQLSelectParser;
    function CreateVariables: IMDTVariables;
    function CreateDataRecord(AVariables: IMDTVariables): IMDTDataRecord;
    function GetGarbageObjects:IMDTGarbageObjects;
    procedure RegisterWarningMessage(AMessageType,AObject,AMessage: AnsiString);
    procedure RegisterTranslatorError(E:Exception; ASQLText:AnsiString);
    function GetIOperationMonitor: IMDTMonitor;

    property Connected:boolean read GetConnected write SetConnected;
    property ChieldObject:IMDTChieldObject read GetChieldObject;
    property RealDBCanalCount:integer read GetRealDBCanalCount;
    property IRealDBCanals[AIndex:integer]:IMDTRealDBCanal read GetIRealDBCanal;
    property ProtectedBlocks: IMDTProtectedBlocks read GetProtectedBlocks;
    property ISQLLexicalAnalizer: IMDTLexicalAnalizer read GetISQLLexicalAnalizer;
    property ISQLProcessor: IMDTSQLProcessor read GetISQLProcessor;
    property IOperationMonitor: IMDTMonitor read GetIOperationMonitor;
    end;

type
  PMDTVoid                      = ^Pointer;
  TMDTISC_DB_HANDLE             = PMDTVoid;
  PMDTISC_DB_HANDLE             = ^TMDTISC_DB_HANDLE;
  TMDTISC_TR_HANDLE             = PMDTVoid;
  PMDTISC_TR_HANDLE             = ^TMDTISC_TR_HANDLE;

const
  iid_MDTIBRealDataBase: TGUID =
    '{1C8BED35-E362-45E1-8DF7-A5EAC2369D03}';
type
  IMDTIBRealDataBase=interface(IMDTRealDataBase)
  ['{1C8BED35-E362-45E1-8DF7-A5EAC2369D03}']
    procedure SetFileName(AValue:AnsiString);
    function GetFileName:AnsiString;
    function GetHandle: TMDTISC_DB_HANDLE;

    property FileName:AnsiString read GetFileName write SetFileName;
    property Handle:TMDTISC_DB_HANDLE read GetHandle;
   end;

const
  iid_MDTIBTransactionParams: TGUID =
    '{F0D24200-6631-4D3D-B5E2-040C2555FCD3}';
type
  IMDTIBTransactionParams=interface(IMDTTransactionParams)
  ['{F0D24200-6631-4D3D-B5E2-040C2555FCD3}']
    procedure ApplyByFullStrings(AParams: TStrings);
    end;

const
  iid_MDTIBRealDBTransaction: TGUID =
    '{EB753871-1D9C-4729-841D-A85377CE8106}';
type
  IMDTIBRealDBTransaction=interface(IMDTRealDBTransaction)
  ['{EB753871-1D9C-4729-841D-A85377CE8106}']
    function GetHandle: TMDTISC_TR_HANDLE;
    function GetITransactionParams: IMDTTransactionParams;
    procedure StartWithNativeParams(
      AIBTransactionParams: IMDTIBTransactionParams);
    procedure CommitRetaining;
    procedure RollbackRetaining;
    function GetDataChange: boolean;
    procedure SetDataChange(AValue: boolean);

    property Handle:TMDTISC_TR_HANDLE read GetHandle;
    property ITransactionParams: IMDTTransactionParams
      read GetITransactionParams;
    property DataChange: boolean read GetDataChange write SetDataChange;
    end;

const
  iid_MDTIBDatabaseConnectParams: TGUID =
    '{B31C7ED8-C863-4423-9F17-0CEC808A6E42}';
type
  IMDTIBDatabaseConnectParams=interface(IMDTDatabaseConnectParams)
  ['{B31C7ED8-C863-4423-9F17-0CEC808A6E42}']
   function GetLibraryName:AnsiString;

   property LibraryName:AnsiString read GetLibraryName;
   end;

const
  iid_MDTIBRealDBCanal: TGUID =
    '{E4EFCAA1-5632-4D91-8569-144FD567C1A4}';
type
  IMDTIBRealDBCanal=interface(IMDTRealDBCanal)
  ['{E4EFCAA1-5632-4D91-8569-144FD567C1A4}']

    function GetIMDTIBRealDataBase:IMDTIBRealDataBase;
    function GetIMDTIBRealCurrentTransaction: IMDTIBRealDBTransaction;
    function GetIMDTIBRealLongTransaction: IMDTIBRealDBTransaction;
    function GetIMDTIBDatabaseConnectParams: IMDTIBDatabaseConnectParams;

    property IMDTIBRealDataBase:IMDTIBRealDataBase
      read GetIMDTIBRealDataBase;
    property IMDTIBRealCurrentTransaction:IMDTIBRealDBTransaction
      read GetIMDTIBRealCurrentTransaction;
    property IMDTIBRealLongTransaction:IMDTIBRealDBTransaction
      read GetIMDTIBRealLongTransaction;
    property IMDTIBDatabaseConnectParams:IMDTIBDatabaseConnectParams
      read GetIMDTIBDatabaseConnectParams;
    end;


