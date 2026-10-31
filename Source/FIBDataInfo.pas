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

unit FIBDataInfo;

interface

{$I FIB.inc}

uses
{$IFDEF WINDOWS}
  Windows, // for inline functions
{$ENDIF}
  SyncObjs, SysUtils, Classes, DB, FIBDataSet, FIBDataBase,
  FIBQuery, FIBProps;

type
  TFIBTableInfoCache = class;

  TFIBTableInfo = class
  private
    FOwner: TFIBTableInfoCache;
    FDBName: string;
    FTableName: string;
    FPrimaryKeyFields: string;
    FFieldList: TStringList;
    FFormatNumber: Integer;
    FFIVersion: Integer; // FIB$FIELDS_INFO
    FWithFieldRepositoryInfo: Boolean;
    FStreamVersion: Integer;
    FNonValidated: Boolean;
    FTableID: Integer;
    procedure GetInfoFields(DB: TFIBDataBase; const TableName: string; aTransaction: TFIBTransaction);
    procedure GetRepositoryFieldInfos(DB: TFIBDataBase; const TableName: string; aTransaction: TFIBTransaction);
    procedure ClearFieldList;
    procedure GetAdditionalInfo(FromQuery: TFIBCustomDataSet; const aFieldName: string; ToFieldInfo: TFIBFieldInfo);
    procedure FillInfo(DB: TFIBDataBase; Tr: TFIBTransaction; const ATableName: string);
    function IsActualInfo(DB: TFIBDataBase): Boolean;
    function GetPrimaryKeyFields(DB: TFIBDataBase): string;
    function GetTableId(DB: TFIBDataBase): Integer;
    procedure LoadFromStreamVersion(Stream: TStream; aStreamVersion: Integer);
  public
    constructor Create(AOwner: TFIBTableInfoCache);
    destructor Destroy; override;
    procedure SaveToStream(Stream: TStream);
    procedure LoadFromStream(Stream: TStream; FromBegin: Boolean);

    function FieldInfo(const FieldName: string): TFIBFieldInfo;
    property TableName: string read FTableName;
    property PrimaryKeyFields[DB: TFIBDataBase]: string read GetPrimaryKeyFields;
    property FieldList: TStringList read FFieldList;
    property TableID[DB: TFIBDataBase]: Integer read GetTableId;
  end;

  TFIBTableInfoCache = class(TComponent)
  private
    FListTabInfo: TStringList;
    FLock: TCriticalSection;
    FNeedValidate: Boolean;
    FLastTransactionId: Integer;
    procedure PrepareInternalTransaction(aDataBase: TFIBDataBase);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure SaveToStream(Stream: TStream);
    procedure LoadFromStream(Stream: TStream; DB: TFIBDataBase = nil);

    procedure SaveToFile(const FileName: string);
    function LoadFromFile(const FileName: string; DB: TFIBDataBase = nil): Boolean;
    procedure ValidateSchema(aDataBase: TFIBDataBase; Proc: TFIBAcceptCacheSchemaEvent);

    function FindTableInfo(const ADBName, ATableName: string): TFIBTableInfo;
    function GetTableInfo(aDataBase: TFIBDataBase; const ATableName: string; WithRepositoryInfo: Boolean): TFIBTableInfo;
    function GetFieldInfo(aDataBase: TFIBDataBase; const ATableName, aFieldName: string; RepositoryInfo: Boolean): TFIBFieldInfo;

    procedure Clear;
    procedure ClearForDataBase(aDataBase: TFIBDataBase);
    procedure ClearForTable(const TableName: string);
    property NeedValidate: Boolean read FNeedValidate write FNeedValidate;
  end;

  TFIBDataSetInfo = class
  private
    FDBName: string;
    FStreamVersion: Integer;
    FVersion: Integer;
    FSelectSQL: TStrings;
    FInsertSQL: TStrings;
    FUpdateSQL: TStrings;
    FDeleteSQL: TStrings;
    FRefreshSQL: TStrings;
    FKeyField: string;
    FGeneratorName: string;
    FDescription: string;
    FUpdateTableName: string;
    FUpdateOnlyModifiedFields: Boolean;
    FConditions: string;
    FNonValidated: Boolean;

  public
    constructor Create(DataSet: TFIBCustomDataSet); overload;
    constructor Create; overload;
    destructor Destroy; override;

    procedure SaveToStream(Stream: TStream);
    procedure LoadFromStream(Stream: TStream);

  end;

  TFIBDataSetInfoCache = class
  private
    FListDataSetInfo: TStringList;
    FLock: TCriticalSection;
    FNeedValidate: Boolean;
    function ActualVersionDSInfo(DataSet: TFIBCustomDataSet): Integer;
  public
    constructor Create;
    destructor Destroy; override;
    function FindDataSetInfo(DataSet: TFIBCustomDataSet; var Index: Integer): TFIBDataSetInfo; overload;
    function FindDataSetInfo(const DBName: string; DS_ID: Integer; var Index: Integer): TFIBDataSetInfo; overload;
    function GetDataSetInfo(DataSet: TFIBCustomDataSet): TFIBDataSetInfo;
    function LoadDataSetInfo(DataSet: TFIBCustomDataSet): Boolean;
    procedure Clear;
    procedure ClearDSInfo(DataSet: TFIBCustomDataSet); overload;
    procedure ClearDSInfo(DS_ID: Integer); overload;

    procedure SaveToStream(Stream: TStream);
    procedure LoadFromStream(Stream: TStream);

    procedure SaveToFile(const FileName: string);
    function LoadFromFile(const FileName: string): Boolean;
    property NeedValidate: Boolean read FNeedValidate write FNeedValidate;
  end;

  // Thread-safe, process-wide cache of stored procedure input parameters
  TFIBStoredProcMetadataCache = class
  private
    FItems: TStringList; // Objects are TFIBStoredProcMetadata
    FLock: TCriticalSection;
    function AcquireMetadata(DB: TFIBDataBase; const StoredProcName: string; ForceReQuery: Boolean): TObject;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function GetExecProcTxt(DB: TFIBDataBase; const StoredProcName: string; ForceReQuery: Boolean): string;
    function GetParamDefValue(DB: TFIBDataBase; const StoredProcName: string; ParamNo: Integer): string;
    procedure ClearSPInfo(DB: TFIBDataBase);
  end;

  TFIBErrorMessage = class
  private
    FErrorMsg: string;
    FVersion: Integer;
  public
    constructor Create(const aErrorMsg: string; aVersion: Integer);
  public
    property ErrorMsg: string read FErrorMsg;
    property Version: Integer read FVersion;
  end;

  // Thread-safe, process-wide cache of FIB$ERROR_MESSAGES, validated per database
  TFIBErrorMessageCache = class
  private
    FDatabases: TStringList; // Objects are TFIBDatabaseErrorMessages
    FLock: TMultiReadExclusiveWriteSynchronizer;
    function DatabaseMessages(const DBName: string; CanCreate: Boolean): TObject;
    function FindErrorMessage(const DBName, ErrorName: string; out ErrorMsg: string): Boolean;
    function IsValidated(const DBName: string): Boolean;
    procedure Validate(const DBName: string; MaxVersion: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
  public
    procedure SaveToStream(Stream: TStream);
    procedure LoadFromStream(Stream: TStream);
    procedure SaveToFile(const FileName: string);
    procedure LoadFromFile(const FileName: string);
  public
    procedure AddErrorMessage(const DBName, ErrorName, ErrorMsg: string; Version: Integer);
    function ErrorMessage(DB: TFIBDataBase; Tr: TFIBTransaction; const ErrorName: string): string;
  end;

var
  TableInfoCache: TFIBTableInfoCache;
  DataSetInfoCache: TFIBDataSetInfoCache;
  StoredProcInfoCache: TFIBStoredProcMetadataCache;
  ErrorMessageCache: TFIBErrorMessageCache;
  // Manage Developer Info tables

procedure CreateFieldsRepositoryTable(DB: TFIBDataBase);
procedure CreateDataSetsRepositoryTable(DB: TFIBDataBase);
procedure CreateErrorsRepositoryTable(DB: TFIBDataBase);

function ExistFieldsRepositoryTable(DB: TFIBDataBase): Boolean;
function ExistDataSetsRepositoryTable(DB: TFIBDataBase): Boolean;
function ExistErrorsRepositoryTable(DB: TFIBDataBase): Boolean;
function ExistBooleanDomain(DB: TFIBDataBase): Boolean;

function SaveFIBDataSetInfo(DataSet: TFIBCustomDataSet; const Name: string): Boolean;

// Routine function

function GetFieldInfos(Field: TField; RepositoryInfo: Boolean): TFIBFieldInfo;
// The upgrades of the repository tables run in an own transaction of the database
procedure UpgradeFieldsRepositoryTable(DB: TFIBDataBase); overload;
procedure UpgradeFieldsRepositoryTable(Tr: TFIBTransaction); overload;
procedure UpgradeDataSetsRepositoryTable(DB: TFIBDataBase); overload;
procedure UpgradeDataSetsRepositoryTable(Tr: TFIBTransaction); overload;

function DBPrimaryKeyFields(const TableName: string; aTransaction: TFIBTransaction;
  Database: TFIBDataBase = nil): string;

implementation

uses
  StrUtil, FIBConsts, FIBCacheQueries, ibase, SqlTxtRtns, FIB,
  StdFuncs, FIBCharSets
{$IFDEF C24}
{$IFDEF MACOS}
    , Posix.Unistd // for inline functions
{$ENDIF}
{$ENDIF}
    ;

const
  // 7: the text of the table info in UTF-8
  CurStreamVersion = 7;
  MinStreamVersion = 6;
  // 2: DBName of the dataset info in UTF-8; 3: all the texts in UTF-8
  DSCurStreamVersion = 3;
  // 2: the texts of the error messages in UTF-8, MaxVersion per database
  ErrCurStreamVersion = 2;

type
  TFriendDatabase = class(TFIBDataBase);
  TFriendFieldInfo = class(TFIBFieldInfo);
  TFriendDataSet = class(TFIBCustomDataSet);
  TFIBSaveToStreamProc = procedure(Stream: TStream) of object;

// The cache files are optional: a failed save must not make Close fail, nor leave a truncated file
procedure SaveCacheFile(const FileName: string; HasItems: Boolean; SaveToStream: TFIBSaveToStreamProc);
var
  Stream: TFileStream;
begin
  if not HasItems then
  begin
    if FileExists(FileName) then
      SysUtils.DeleteFile(FileName);
    Exit;
  end;
  try
    Stream := TFileStream.Create(FileName, fmCreate);
  except
    Exit;
  end;
  try
    try
      SaveToStream(Stream);
    finally
      Stream.Free;
    end;
  except
    SysUtils.DeleteFile(FileName);
  end;
end;

var
  DatabaseRepositories: TStringList;
  LockRepList: TCriticalSection;

  // One character per repository table: '1' exists, '0' doesn't, '2' unknown; under LockRepList
procedure SetRepositoryState(DB: TFIBDataBase; const State: string);
var
  Index: Integer;
begin
  Index := DatabaseRepositories.IndexOfObject(DB);
  if Index < 0 then
  begin
    DatabaseRepositories.AddObject(State, DB);
    // TFIBTableInfoCache.Notification removes the entry with the component
    DB.FreeNotification(TableInfoCache);
  end
  else
    DatabaseRepositories[Index] := State;
end;

const
  SDefer = '@FIB_DEFERRED';

  FormatNumbersSQL = 'select a1.rdb$relation_name,a1.RDB$RELATION_ID VER  from RDB$RELATIONS a1' + sLineBreak +
    'where a1.RDB$SYSTEM_FLAG = 0' + sLineBreak +
    'and not  a1.rdb$view_blr is null' + sLineBreak +
    'union' + sLineBreak +
    'select R.rdb$relation_name,RDB$FORMAT from RDB$RELATIONS R' + sLineBreak +
    'where R.RDB$SYSTEM_FLAG = 0' + sLineBreak +
    'and  R.rdb$view_blr is null   order by 1';

function ExistRepositoryTable(DB: TFIBDataBase; Kind: Byte): Boolean;
var
  aTransaction: TFIBTransaction;
  qry: TFIBQuery;
  Index: Integer;
  s: string;
  cr: TFIBExtendedBoolean;

  function RepositoryIsRegistered: TFIBExtendedBoolean;
  begin
    Index := DatabaseRepositories.IndexOfObject(DB);
    if Index > -1 then
    begin
      case DatabaseRepositories[Index][Kind] of
        '0': Result := eFalse;
        '1': Result := eTrue;
      else
        Result := eUnknown;
      end
    end
    else
      Result := eUnknown;
  end;

begin
  LockRepList.Acquire;
  try
    if csDesigning in DB.ComponentState then
    begin
      Index := -1;
      DatabaseRepositories.Clear;
      cr := eUnknown;
    end
    else
      cr := RepositoryIsRegistered;
    Result := cr = eTrue;
    if cr <> eUnknown then
      Exit;
    if not(TFIBUseRepository(Kind - 1) in DB.UseRepositories) then
      Exit;

    if Index < 0 then
      s := '222'
    else
      s := DatabaseRepositories[Index];

    aTransaction := CreateInternalTransaction(DB, True);
    aTransaction.TimeoutAction := TACommit;
    qry := TFIBQuery.Create(nil);
    with qry do
      try
        ParamCheck := True;
        Database := DB;
        Transaction := aTransaction;
        SQL.Text := 'select COUNT(RDB$RELATION_NAME)' + sLineBreak +
          'from RDB$RELATIONS where RDB$FLAGS = 1' + sLineBreak +
          'and RDB$RELATION_NAME=?RT';
        aTransaction.StartTransaction;
        case Kind of
          1: Params[0].asString := 'FIB$FIELDS_INFO';
          2: Params[0].asString := 'FIB$DATASETS_INFO';
          3: Params[0].asString := 'FIB$ERROR_MESSAGES';
        end;

        ExecQuery;
        if Fields[0].asInteger > 0 then
          s[Kind] := '1'
        else
          s[Kind] := '0';
        Close;

        SetRepositoryState(DB, s);

        Result := RepositoryIsRegistered = eTrue;
      finally
        aTransaction.Free;
        Free;
      end;
  finally
    LockRepList.Release;
  end;
end;

function ExistDataSetsRepositoryTable(DB: TFIBDataBase): Boolean;
begin
  Result := ExistRepositoryTable(DB, 2)
end;

function ExistErrorsRepositoryTable(DB: TFIBDataBase): Boolean;
begin
  Result := ExistRepositoryTable(DB, 3)
end;

function ExistBooleanDomain(DB: TFIBDataBase): Boolean;
var
  Transaction: TFIBTransaction;
  qry: TFIBQuery;
begin
  qry := TFIBQuery.Create(nil);
  Transaction := CreateInternalTransaction(DB, True);
  try
    qry.Transaction := Transaction;
    with qry, qry.SQL do
    begin
      ParamCheck := False;
      Database := DB;
      ParamCheck := False;
      Transaction.StartTransaction;
      Text := 'Select Count(*) FROM RDB$FIELDS FLD' + sLineBreak + 'WHERE FLD.RDB$FIELD_NAME = ''FIB$BOOLEAN''';
      ExecQuery;
      Result := qry.Fields[0].asInteger <> 0;
    end
  finally
    Transaction.Free;
    qry.Free;
  end;
end;

function ExistFieldsRepositoryTable(DB: TFIBDataBase): Boolean;
begin
  Result := ExistRepositoryTable(DB, 1)
end;

function TransactionDatabase(Transaction: TFIBTransaction): TFIBDataBase;
begin
  Result := Transaction.DefaultDatabase;
  if (Result = nil) and (Transaction.DatabaseCount > 0) then
    Result := Transaction.Databases[0];
end;

const
  FieldsInfoNamesUpgrade      = 'FIB$FIELDS_INFO names';
  DataSetsInfoKeyFieldUpgrade = 'FIB$DATASETS_INFO KEY_FIELD';

type
  // Repository upgrades that failed (no rights, table in use), not retried for the component
  TFailedUpgrades = class(TComponent)
  private
    FUpgrades: TStringList;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Contains(DB: TFIBDataBase; const Upgrade: string): Boolean;
    procedure Add(DB: TFIBDataBase; const Upgrade: string);
  end;

var
  FailedUpgrades: TFailedUpgrades;

constructor TFailedUpgrades.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FUpgrades := TStringList.Create;
end;

destructor TFailedUpgrades.Destroy;
begin
  FUpgrades.Free;
  inherited Destroy;
end;

procedure TFailedUpgrades.Notification(AComponent: TComponent; Operation: TOperation);
var
  i: Integer;
begin
  if Operation = opRemove then
  begin
    LockRepList.Acquire;
    try
      for i := FUpgrades.Count - 1 downto 0 do
        if FUpgrades.Objects[i] = AComponent then
          FUpgrades.Delete(i);
    finally
      LockRepList.Release;
    end;
  end;
  inherited Notification(AComponent, Operation);
end;

function TFailedUpgrades.Contains(DB: TFIBDataBase; const Upgrade: string): Boolean;
var
  i: Integer;
begin
  Result := False;
  LockRepList.Acquire;
  try
    for i := 0 to FUpgrades.Count - 1 do
      if (FUpgrades.Objects[i] = DB) and (FUpgrades[i] = Upgrade) then
      begin
        Result := True;
        Break;
      end;
  finally
    LockRepList.Release;
  end;
end;

// Not at design time: the developer can fix the cause and retry
procedure TFailedUpgrades.Add(DB: TFIBDataBase; const Upgrade: string);
begin
  if csDesigning in DB.ComponentState then
    Exit;
  LockRepList.Acquire;
  try
    FUpgrades.AddObject(Upgrade, DB);
    DB.FreeNotification(Self);
  finally
    LockRepList.Release;
  end;
end;

// Firebird can't change the type of a key column: the primary key is dropped and recreated
procedure WidenRepositoryColumns(DB: TFIBDataBase;
  const Upgrade, TableName: string; const ColumnNames: array of string;
  NewLength: Integer);
var
  Transaction: TFIBTransaction;
  qry: TFIBQuery;
  Narrow, KeyColumns: TStringList;
  KeyName, KeyList: string;
  DropKey: Boolean;
  ColumnLength, i: Integer;
  ColumnName: string;

  procedure ExecDDL(const SQL: string);
  begin
    qry.SQL.Text := SQL;
    qry.ExecQuery;
  end;

begin
  if FailedUpgrades.Contains(DB, Upgrade) then
    Exit;
  Transaction := CreateInternalTransaction(DB, False);
  qry := TFIBQuery.Create(nil);
  Narrow := TStringList.Create;
  KeyColumns := TStringList.Create;
  try
    try
      qry.Database := DB;
      qry.Transaction := Transaction;
      Transaction.StartTransaction;
      // no COALESCE: InterBase and Firebird 1.0
      qry.SQL.Text := 'select f.RDB$CHARACTER_LENGTH, f.RDB$FIELD_LENGTH ' +
        'from RDB$RELATION_FIELDS rf ' +
        'join RDB$FIELDS f on f.RDB$FIELD_NAME = rf.RDB$FIELD_SOURCE ' +
        'where rf.RDB$RELATION_NAME = :TABLE_NAME and rf.RDB$FIELD_NAME = :COLUMN_NAME';
      for ColumnName in ColumnNames do
      begin
        qry.Params[0].asString := TableName;
        qry.Params[1].asString := ColumnName;
        qry.ExecQuery;
        if not qry.Eof then
        begin
          if qry.Fields[0].IsNull then
            ColumnLength := qry.Fields[1].asInteger
          else
            ColumnLength := qry.Fields[0].asInteger;
          if ColumnLength < NewLength then
            Narrow.Add(ColumnName);
        end;
        qry.Close;
      end;
      if Narrow.Count > 0 then
      begin
        // cached prepared statements on the table keep its index in use
        DB.ClearQueryCacheList;
        qry.SQL.Text := 'select c.RDB$CONSTRAINT_NAME, s.RDB$FIELD_NAME ' +
          'from RDB$RELATION_CONSTRAINTS c ' +
          'join RDB$INDEX_SEGMENTS s on s.RDB$INDEX_NAME = c.RDB$INDEX_NAME ' +
          'where c.RDB$RELATION_NAME = :TABLE_NAME and c.RDB$CONSTRAINT_TYPE = ''PRIMARY KEY'' ' +
          'order by s.RDB$FIELD_POSITION';
        qry.Params[0].asString := TableName;
        qry.ExecQuery;
        while not qry.Eof do
        begin
          KeyName := Trim(qry.Fields[0].asString);
          KeyColumns.Add(Trim(qry.Fields[1].asString));
          qry.Next;
        end;
        qry.Close;
        DropKey := False;
        for i := 0 to Narrow.Count - 1 do
          DropKey := DropKey or (KeyColumns.IndexOf(Narrow[i]) >= 0);
        if DropKey then
          ExecDDL(Format('ALTER TABLE %s DROP CONSTRAINT %s', [TableName, KeyName]));
        for i := 0 to Narrow.Count - 1 do
          ExecDDL(Format('ALTER TABLE %s ALTER COLUMN %s TYPE VARCHAR(%d)', [TableName, Narrow[i], NewLength]));
        if DropKey then
        begin
          KeyList := KeyColumns[0];
          for i := 1 to KeyColumns.Count - 1 do
            KeyList := KeyList + ', ' + KeyColumns[i];
          ExecDDL(Format('ALTER TABLE %s ADD CONSTRAINT %s PRIMARY KEY (%s)', [TableName, KeyName, KeyList]));
        end;
      end;
      Transaction.Commit;
    except
      try
        if Transaction.InTransaction then
          Transaction.Rollback;
      except
      end;
      FailedUpgrades.Add(DB, Upgrade);
    end;
  finally
    KeyColumns.Free;
    Narrow.Free;
    qry.Free;
    Transaction.Free;
  end;
end;

// The repository upgrades run in an own transaction, never in a transaction of the application.
// A statement that fails (the column or the object exists already) is skipped.
function TryRepositoryDDL(qry: TFIBQuery; const SQLs: array of string): Boolean;
var
  i: Integer;
begin
  Result := True;
  try
    for i := Low(SQLs) to High(SQLs) do
    begin
      qry.SQL.Text := SQLs[i];
      qry.ExecQuery;
    end;
  except
    on EFIBError do
      Result := False;
  end;
end;

procedure CommitRepositoryUpgrade(Transaction: TFIBTransaction);
begin
  try
    Transaction.Commit;
  except
    if Transaction.InTransaction then
      Transaction.Rollback;
    raise;
  end;
end;

procedure UpgradeFieldsRepositoryTable(DB: TFIBDataBase);
var
  qry: TFIBQuery;
  Transaction: TFIBTransaction;
begin
  // without rights to widen the table the other changes fail too, don't retry on every read
  if (DB = nil) or FailedUpgrades.Contains(DB, FieldsInfoNamesUpgrade) then
    Exit;
  if DB.Capabilities.MaxIdentifierLength > 31 then
    WidenRepositoryColumns(DB, FieldsInfoNamesUpgrade, 'FIB$FIELDS_INFO',
      ['TABLE_NAME', 'FIELD_NAME'], DB.Capabilities.MaxIdentifierLength);
  Transaction := CreateInternalTransaction(DB, False);
  qry := TFIBQuery.Create(nil);
  try
    qry.Database := DB;
    qry.Transaction := Transaction;
    qry.ParamCheck := False;
    Transaction.StartTransaction;
    TryRepositoryDDL(qry, ['CREATE GENERATOR FIB$FIELD_INFO_VERSION']);
    TryRepositoryDDL(qry, ['ALTER TABLE FIB$FIELDS_INFO ADD DISPLAY_WIDTH INTEGER DEFAULT 0']);
    TryRepositoryDDL(qry, ['ALTER TABLE FIB$FIELDS_INFO ADD FIB$VERSION INTEGER']);
    TryRepositoryDDL(qry, ['CREATE TRIGGER FIB$FIELDS_INFO_BI FOR FIB$FIELDS_INFO ' +
      'ACTIVE BEFORE INSERT POSITION 0 as ' + sLineBreak + 'begin ' + sLineBreak +
      'new.fib$version=gen_id(fib$field_info_version,1);' + sLineBreak + 'end']);
    TryRepositoryDDL(qry, ['CREATE TRIGGER FIB$FIELDS_INFO_BU FOR FIB$FIELDS_INFO ' +
      'ACTIVE BEFORE UPDATE POSITION 0 as ' + sLineBreak + 'begin ' + sLineBreak +
      'new.fib$version=gen_id(fib$field_info_version,1);' + sLineBreak + 'end']);
    CommitRepositoryUpgrade(Transaction);
  finally
    qry.Free;
    Transaction.Free;
  end;
end;

procedure UpgradeDataSetsRepositoryTable(DB: TFIBDataBase);
var
  qry: TFIBQuery;
  Transaction: TFIBTransaction;
begin
  if DB = nil then
    Exit;
  Transaction := CreateInternalTransaction(DB, False);
  qry := TFIBQuery.Create(nil);
  try
    qry.Database := DB;
    qry.Transaction := Transaction;
    qry.ParamCheck := False;
    Transaction.StartTransaction;
    if not ExistBooleanDomain(DB) then
    begin
      qry.SQL.Text := 'CREATE DOMAIN FIB$BOOLEAN AS SMALLINT DEFAULT 1 NOT NULL CHECK (VALUE IN (0,1))';
      qry.ExecQuery;
    end;
    TryRepositoryDDL(qry, ['ALTER TABLE FIB$DATASETS_INFO ADD UPDATE_TABLE_NAME  VARCHAR(68)']);
    TryRepositoryDDL(qry, ['ALTER TABLE FIB$DATASETS_INFO ADD UPDATE_ONLY_MODIFIED_FIELDS  FIB$BOOLEAN NOT NULL']);
    TryRepositoryDDL(qry, ['ALTER TABLE FIB$DATASETS_INFO ADD CONDITIONS  BLOB sub_type 1 segment size 80']);
    TryRepositoryDDL(qry, ['CREATE GENERATOR FIB$FIELD_INFO_VERSION']);
    TryRepositoryDDL(qry, ['ALTER TABLE FIB$DATASETS_INFO ADD fib$version  INTEGER',
      'CREATE TRIGGER FIB$DATASETS_INFO_BI FOR FIB$DATASETS_INFO ' +
      'ACTIVE BEFORE INSERT POSITION 0 as ' + sLineBreak + 'begin' + sLineBreak +
      'new.fib$version=gen_id(fib$field_info_version,1);' + sLineBreak + 'end',
      'CREATE TRIGGER FIB$DATASETS_INFO_BU FOR FIB$DATASETS_INFO ' +
      'ACTIVE BEFORE UPDATE POSITION 0 as ' + sLineBreak + 'begin' + sLineBreak +
      'new.fib$version=gen_id(fib$field_info_version,1);' + sLineBreak + 'end']);
    CommitRepositoryUpgrade(Transaction);
  finally
    qry.Free;
    Transaction.Free;
  end;
end;

procedure UpgradeFieldsRepositoryTable(Tr: TFIBTransaction);
begin
  UpgradeFieldsRepositoryTable(TransactionDatabase(Tr));
end;

procedure UpgradeDataSetsRepositoryTable(Tr: TFIBTransaction);
begin
  UpgradeDataSetsRepositoryTable(TransactionDatabase(Tr));
end;

procedure DoCreateRepositoryTable(DB: TFIBDataBase; Kind: Byte);
var
  Index: Integer;
  State: string;
  Transaction: TFIBTransaction;
  qry: TFIBQuery;
begin
  qry := TFIBQuery.Create(nil);
  Transaction := CreateInternalTransaction(DB, False);
  try
    qry.Database := DB;
    qry.Transaction := Transaction;
    qry.ParamCheck := False;
    Transaction.StartTransaction;
    with qry, qry.SQL do
      case Kind of
        1:
          begin
            if not ExistBooleanDomain(DB) then
            begin
              Text := 'CREATE DOMAIN FIB$BOOLEAN AS SMALLINT DEFAULT 1 NOT NULL CHECK (VALUE IN (0,1))';
              ExecQuery;
            end;
            Text := Format
              ('CREATE TABLE FIB$FIELDS_INFO (TABLE_NAME VARCHAR(%0:d) NOT NULL,',
              [DB.Capabilities.MaxIdentifierLength]) + sLineBreak +
              Format('FIELD_NAME VARCHAR(%0:d) NOT NULL,',
              [DB.Capabilities.MaxIdentifierLength]) + sLineBreak +
              'DISPLAY_LABEL VARCHAR(25),' + sLineBreak +
              'VISIBLE FIB$BOOLEAN DEFAULT 1 NOT NULL,' + sLineBreak +
              'DISPLAY_FORMAT VARCHAR(15),' + sLineBreak + 'EDIT_FORMAT VARCHAR(15),'
              + sLineBreak + 'TRIGGERED FIB$BOOLEAN DEFAULT 0 NOT NULL,' + sLineBreak +
              'CONSTRAINT PK_FIB$FIELDS_INFO PRIMARY KEY (TABLE_NAME, FIELD_NAME))';
            ExecQuery;
            Text := 'GRANT SELECT ON TABLE FIB$FIELDS_INFO TO PUBLIC';
            ExecQuery;
          end;
        2:
          begin
            Text := 'CREATE TABLE FIB$DATASETS_INFO (DS_ID INTEGER NOT NULL,' +
              sLineBreak + 'DESCRIPTION VARCHAR(40),' +
              'SELECT_SQL BLOB sub_type 1 segment size 80,' + sLineBreak +
              'UPDATE_SQL BLOB sub_type 1 segment size 80,' + sLineBreak +
              'INSERT_SQL BLOB sub_type 1 segment size 80,' + sLineBreak +
              'DELETE_SQL BLOB sub_type 1 segment size 80,' + sLineBreak +
              'REFRESH_SQL BLOB sub_type 1 segment size 80,' + sLineBreak +
              'NAME_GENERATOR VARCHAR(68), ' + 'KEY_FIELD VARCHAR(1024),' +
              'CONSTRAINT PK_FIB$DATASETS_INFO PRIMARY KEY (DS_ID))';
            ExecQuery;
            Text := 'GRANT SELECT ON TABLE FIB$DATASETS_INFO TO PUBLIC';
            ExecQuery;
          end;
        3:
          begin
            Text := 'CREATE TABLE FIB$ERROR_MESSAGES (' +
              'CONSTRAINT_NAME  VARCHAR(67) NOT NULL,' +
              'MESSAGE_STRING   VARCHAR(100),' + 'FIB$VERSION      INTEGER,' +
              'CONSTR_TYPE      VARCHAR(11) DEFAULT ''UNIQUE'' NOT NULL,' +
              'CONSTRAINT PK_FIB$ERROR_MESSAGES PRIMARY KEY (CONSTRAINT_NAME))';

            ExecQuery;
            Text := 'GRANT SELECT ON TABLE FIB$ERROR_MESSAGES TO PUBLIC';
            ExecQuery;

            try
              Text := 'CREATE GENERATOR FIB$FIELD_INFO_VERSION';
              ExecQuery;
            except
            end;
            Text := 'CREATE TRIGGER BI_FIB$ERROR_MESSAGES FOR FIB$ERROR_MESSAGES ' +
              'ACTIVE BEFORE INSERT POSITION 0 AS ' + sLineBreak + 'begin ' + sLineBreak +
              'new.fib$version=gen_id(fib$field_info_version,1);' +
              sLineBreak + ' end';
            ExecQuery;

            Text := 'CREATE TRIGGER BU_FIB$ERROR_MESSAGES FOR FIB$ERROR_MESSAGES ' +
              'ACTIVE BEFORE UPDATE POSITION 0 AS ' + sLineBreak + 'begin ' + sLineBreak +
              'new.fib$version=gen_id(fib$field_info_version,1);' +
              sLineBreak + ' end';
            ExecQuery;
          end;
      end;
    Transaction.Commit;
  finally
    Transaction.Free;
    qry.Free;
  end;
  // the upgrades alter the tables created above, in their own transaction
  case Kind of
    1: UpgradeFieldsRepositoryTable(DB);
    2: UpgradeDataSetsRepositoryTable(DB);
  end;
  LockRepList.Acquire;
  try
    Index := DatabaseRepositories.IndexOfObject(DB);
    if Index < 0 then
      State := '222'
    else
      State := DatabaseRepositories[Index];
    State[Kind] := '1';
    SetRepositoryState(DB, State);
  finally
    LockRepList.Release;
  end;
end;

procedure CreateDataSetsRepositoryTable(DB: TFIBDataBase);
begin
  DoCreateRepositoryTable(DB, 2)
end;

procedure CreateFieldsRepositoryTable(DB: TFIBDataBase);
begin
  DoCreateRepositoryTable(DB, 1)
end;

procedure CreateErrorsRepositoryTable(DB: TFIBDataBase);
begin
  DoCreateRepositoryTable(DB, 3)
end;

function ExchangeDataSetInfo(DataSet: TFIBCustomDataSet; DS_Info: TFIBDataSetInfo; aDescription: string = ''): Boolean;
var
  InfoTransaction: TFIBTransaction;
  DI: TFIBDataSet;
  DataSetDescription: string;
  tf1: TFIBXSQLVAR;
  q: TFIBQuery;

begin
  Result := True;
  if DataSet <> nil then
    with TFriendDataSet(DataSet) do
    begin
      if DataSet_ID = 0 then
        raise Exception.Create(Name + SCompEditDataSet_ID);
      if Database = nil then
        raise Exception.Create(SDataBaseNotAssigned);
      if not(urDataSetInfo in DataSet.Database.UseRepositories) then
        raise Exception.Create(SCompEditDataSetInfoForbid);
      if not ExistDataSetsRepositoryTable(DataSet.Database) then
        raise Exception.Create(SCompEditDataSetInfoNotExists);

      // before the cached query below: its prepared statement would block the DDL
      if (DS_Info = nil) and (Length(AutoUpdateOptions.KeyFields) > 68) then
        WidenRepositoryColumns(DataSet.Database, DataSetsInfoKeyFieldUpgrade, 'FIB$DATASETS_INFO', ['KEY_FIELD'], 1024);
      DI := nil;
      q := nil;
      InfoTransaction := CreateInternalTransaction(DataSet.Database, False);
      try
        DI := TFIBDataSet.Create(nil);
        q := GetQueryForUse(InfoTransaction, 'SELECT * FROM FIB$DATASETS_INFO WHERE DS_ID=:DS_ID');
        InfoTransaction.StartTransaction;
        if DS_Info <> nil then
        begin
          q.Params[0].asInteger := DataSet_ID;
          q.ExecQuery;
          // no info stored for the dataset
          if q.RecordCount = 0 then
          begin
            Result := False;
            Exit;
          end;
          with DS_Info, q do
          begin
            FSelectSQL.Text := FieldByName('SELECT_SQL').asString;
            FUpdateSQL.Text := FieldByName('UPDATE_SQL').asString;
            FInsertSQL.Text := FieldByName('INSERT_SQL').asString;
            FDeleteSQL.Text := FieldByName('DELETE_SQL').asString;
            FRefreshSQL.Text := FieldByName('REFRESH_SQL').asString;
            FKeyField := FieldByName('KEY_FIELD').asString;
            FGeneratorName := FieldByName('NAME_GENERATOR').asString;
            FDescription := FieldByName('DESCRIPTION').asString;
            tf1 := FindField('FIB$VERSION');
            if Assigned(tf1) then
              FVersion := FieldByName('FIB$VERSION').asInteger;
            tf1 := FindField('UPDATE_TABLE_NAME');
            if Assigned(tf1) then
              FUpdateTableName := tf1.asString;
            tf1 := FindField('UPDATE_ONLY_MODIFIED_FIELDS');
            if Assigned(tf1) then
              FUpdateOnlyModifiedFields := tf1.asInteger = 1;
            tf1 := FindField('CONDITIONS');
            if Assigned(tf1) then
            begin
              FConditions := tf1.asString;
            end;
            q.Close;
          end;
        end
        else
        begin
          // For design only
          DI.Database := DataSet.Database;
          DI.Transaction := InfoTransaction;
          DI.UpdateTransaction := InfoTransaction;
          DI.SelectSQL.Text := 'SELECT * FROM FIB$DATASETS_INFO WHERE DS_ID=' + IntToStr(DataSet_ID);

          DI.InsertSQL.Text := 'INSERT INTO FIB$DATASETS_INFO (DS_ID,UPDATE_ONLY_MODIFIED_FIELDS) VALUES('
            + IntToStr(DataSet_ID) + ',1)';
          DI.UpdateSQL.Text := 'UPDATE FIB$DATASETS_INFO SET SELECT_SQL=?SELECT_SQL,' +
            'DESCRIPTION=?DESCRIPTION,' + 'UPDATE_SQL=?UPDATE_SQL,' +
            'INSERT_SQL=?INSERT_SQL,' + 'DELETE_SQL=?DELETE_SQL,' +
            'REFRESH_SQL=?REFRESH_SQL,' + 'NAME_GENERATOR=?NAME_GENERATOR,' +
            'KEY_FIELD=?KEY_FIELD, ' + 'UPDATE_TABLE_NAME=?UPDATE_TABLE_NAME, ' +
            'UPDATE_ONLY_MODIFIED_FIELDS=?UPDATE_ONLY_MODIFIED_FIELDS, ' +
            'CONDITIONS=?CONDITIONS ' + 'WHERE DS_ID=' + IntToStr(DataSet_ID);
          try
            DI.QUpdate.Prepare;
          except
            UpgradeDataSetsRepositoryTable(DataSet.Database);
            InfoTransaction.Commit;
            InfoTransaction.StartTransaction
          end;
          DI.Open;
          if DI.RecordCount = 0 then
          begin
            DI.QInsert.ExecQuery;
            DI.Close;
            DI.Open;
            if DI.RecordCount = 0 then
              raise Exception.Create(SCompEditUnableInsertInfoRecord);
          end;
          if Length(aDescription) = 0 then
            DataSetDescription := DI.FieldByName('DESCRIPTION').asString
          else
            DataSetDescription := aDescription;

          DI.Edit;
          DI.FieldByName('SELECT_SQL').asString := SelectSQL.Text;
          DI.FieldByName('INSERT_SQL').asString := InsertSQL.Text;
          DI.FieldByName('DELETE_SQL').asString := DeleteSQL.Text;
          DI.FieldByName('UPDATE_SQL').asString := UpdateSQL.Text;
          DI.FieldByName('REFRESH_SQL').asString := RefreshSQL.Text;
          DI.FieldByName('KEY_FIELD').asString := AutoUpdateOptions.KeyFields;
          DI.FieldByName('NAME_GENERATOR').asString := AutoUpdateOptions.GeneratorName;
          DI.FieldByName('DESCRIPTION').asString := DataSetDescription;
          DI.FieldByName('UPDATE_TABLE_NAME').asString := AutoUpdateOptions.UpdateTableName;
          DI.FieldByName('UPDATE_ONLY_MODIFIED_FIELDS').asInteger := Ord(AutoUpdateOptions.UpdateOnlyModifiedFields);
          DI.FieldByName('CONDITIONS').asString := Conditions.ExchangeString;
          DI.Post;
        end;
        InfoTransaction.Commit;
        Result := True;
      finally
        if q <> nil then
          FreeQueryForUse(q);
        InfoTransaction.Free;
        DI.Free;
      end;
    end;
end;

function SaveFIBDataSetInfo(DataSet: TFIBCustomDataSet; const Name: string): Boolean;
begin
  Result := ExchangeDataSetInfo(DataSet, nil, Name);
end;

function DoGetTableId(const TableName: string; Database: TFIBDataBase; aTransaction: TFIBTransaction): Integer;
var
  q: TFIBQuery;
const
  STabId = 'select RDB$RELATION_ID from RDB$RELATIONS ' +
    'where RDB$RELATION_NAME=?TN';

begin
  if (aTransaction = nil) or (Database = nil) then
  begin
    Result := -1;
    Exit;
  end;
  q := GetQueryForUse(Database, aTransaction, STabId);
  with q do
    try
      Params[0].asString := TableName;
      if not Transaction.InTransaction then
        Transaction.StartTransaction;
      ExecQuery;
      if Eof then
        Result := -1
      else
        Result := Fields[0].asInteger
    finally
      FreeQueryForUse(q);
    end
end;

function DBPrimaryKeyFields(const TableName: string; aTransaction: TFIBTransaction;
  Database: TFIBDataBase = nil): string;
var
  q: TFIBQuery;
const
  SGetPrimary = 'select i.rdb$field_name' + sLineBreak +
    'from    rdb$relation_constraints r, rdb$index_segments i' + sLineBreak +
    'where   r.rdb$relation_name=:TN and' + sLineBreak +
    'r.rdb$constraint_type=''PRIMARY KEY'' and' + sLineBreak +
    'r.rdb$index_name=i.rdb$index_name' + sLineBreak +
    'order by i.rdb$field_position';

begin
  if Length(TableName) = 0 then
  begin
    Result := '';
    Exit;
  end;
  if (Database = nil) and (aTransaction <> nil) then
    Database := aTransaction.DefaultDatabase;
  if (aTransaction = nil) or (Database = nil) then
  begin
    Result := SDefer;
    Exit;
  end;
  q := GetQueryForUse(Database, aTransaction, SGetPrimary);
  Result := '';
  with q do
    try
      q.Options := [qoStartTransaction];
      if TableName[1] = '"' then
        ParamByName('TN').asString := Copy(TableName, 2, Length(TableName) - 2)
      else
        ParamByName('TN').asString := TableName;
      ExecQuery;
      Result := FastTrim(Fields[0].asString);
      Next;
      while not Eof do
      begin
        Result := Result + ';' + FastTrim(Fields[0].asString);
        Next
      end;
    finally
      FreeQueryForUse(q);
    end
end;

// TFIBTableInfo
constructor TFIBTableInfo.Create(AOwner: TFIBTableInfoCache);
begin
  inherited Create;
  FOwner := AOwner;
  FFieldList := TStringList.Create;
  FTableID := -1;
  FStreamVersion := CurStreamVersion;
end;

procedure TFIBTableInfo.FillInfo(DB: TFIBDataBase; Tr: TFIBTransaction; const ATableName: string);

var
  InfoDatabase: TFIBDataBase;
  ForceTransaction: Boolean;
  WorkTransaction: TFIBTransaction;
begin
  FTableName := ATableName;
  FPrimaryKeyFields := SDefer;
  InfoDatabase := DB;
  FDBName := InfoDatabase.DBName;
  WorkTransaction := InfoDatabase.FirstActiveTransaction;
  ForceTransaction := WorkTransaction = nil;
  if ForceTransaction then
  begin
    if Length(FTableName) > 0 then
      GetInfoFields(DB, FTableName, Tr);
  end
  else
  begin
    if Length(FTableName) > 0 then
      GetInfoFields(DB, FTableName, WorkTransaction);
  end;

end;

destructor TFIBTableInfo.Destroy; // override;
begin
  ClearFieldList;
  FFieldList.Free;
  inherited Destroy;
end;

procedure TFIBTableInfo.SaveToStream(Stream: TStream);
var
  i, L: Integer;
begin
  with Stream do
  begin
    WriteUTF8StrToStream(FDBName, Stream);
    WriteUTF8StrToStream(FTableName, Stream);
    WriteBuffer(FWithFieldRepositoryInfo, SizeOf(Boolean));
    WriteBuffer(FFormatNumber, SizeOf(Integer)); // metadate counter
    WriteBuffer(FFIVersion, SizeOf(Integer)); // counter for FIB$FIELD_INFO
    WriteUTF8StrToStream(FPrimaryKeyFields, Stream);
    L := FFieldList.Count;
    WriteBuffer(L, SizeOf(Integer));
    for i := 0 to Pred(FFieldList.Count) do
    begin
      WriteUTF8StrToStream(FFieldList[i], Stream);
      TFIBFieldInfo(FFieldList.Objects[i]).SaveToStream(Stream)
    end;
  end;
end;

procedure TFIBTableInfo.LoadFromStreamVersion(Stream: TStream; aStreamVersion: Integer);
begin
  FStreamVersion := aStreamVersion;
  LoadFromStream(Stream, False)
end;

procedure TFIBTableInfo.LoadFromStream(Stream: TStream; FromBegin: Boolean);
var
  i, fc: Integer;
  UTF8: Boolean;
  fn: string;
  fi: TFIBFieldInfo;

  {
    procedure RaizeErrStream;
    begin
    raise Exception.Create(SCompEditFieldInfoLoadError);
    end;
  }
begin
  with Stream do
  begin
    if FromBegin then
      Seek(0, soFromBeginning);

    UTF8 := FStreamVersion >= 7;
    FDBName := ReadUTF8StrFromStream(Stream, UTF8);
    FTableName := ReadUTF8StrFromStream(Stream, UTF8);
    ReadBuffer(FWithFieldRepositoryInfo, SizeOf(Boolean));

    ReadBuffer(FFormatNumber, SizeOf(Integer));
    ReadBuffer(FFIVersion, SizeOf(Integer)); // Counter for FIB$FIELD_INFO

    FPrimaryKeyFields := ReadUTF8StrFromStream(Stream, UTF8);
    ReadBuffer(fc, SizeOf(Integer));

    ClearFieldList;
    for i := 0 to Pred(fc) do
    begin
      fn := ReadUTF8StrFromStream(Stream, UTF8);
      fi := TFIBFieldInfo.Create;
      fi.LoadFromStream(Stream, False, UTF8);
      FFieldList.AddObject(fn, fi);
    end;
  end;
  FNonValidated := True
end;

function TFIBTableInfo.GetPrimaryKeyFields(DB: TFIBDataBase): string;
var
  InfoTransaction: TFIBTransaction;
begin
  InfoTransaction := TFriendDatabase(DB).GetInternalTransaction;
  // read on first use, the info is shared by the threads
  if FOwner <> nil then
    FOwner.FLock.Acquire;
  try
    if FPrimaryKeyFields = SDefer then
      FPrimaryKeyFields := DBPrimaryKeyFields(FTableName, InfoTransaction, DB);
    Result := FPrimaryKeyFields;
  finally
    if FOwner <> nil then
      FOwner.FLock.Release;
  end;
end;

function TFIBTableInfo.GetTableId(DB: TFIBDataBase): Integer;
var
  InfoTransaction: TFIBTransaction;
begin
  InfoTransaction := TFriendDatabase(DB).GetInternalTransaction;
  if FOwner <> nil then
    FOwner.FLock.Acquire;
  try
    if FTableID = -1 then // defer
      FTableID := DoGetTableId(FTableName, DB, InfoTransaction);
    Result := FTableID;
  finally
    if FOwner <> nil then
      FOwner.FLock.Release;
  end;
end;

function TFIBTableInfo.FieldInfo(const FieldName: string): TFIBFieldInfo;
var
  Index: Integer;
  Name: string;
begin
  Result := nil;
  Name := FastTrim(ReplaceStr(FieldName, '"', ''));
  // "Name" and NAME are different fields, a name in another case finds the field too
  Index := FFieldList.Count - 1;
  while (Index >= 0) and (FFieldList[Index] <> Name) do
    Dec(Index);
  if Index < 0 then
    Index := FFieldList.IndexOf(Name);
  if Index > -1 then
    Result := TFIBFieldInfo(FFieldList.Objects[Index]);
end;

procedure TFIBTableInfo.ClearFieldList;
var
  i: Integer;
begin
  for i := Pred(FFieldList.Count) downto 0 do
    FFieldList.Objects[i].Free;
  FFieldList.Clear;
end;

procedure TFIBTableInfo.GetAdditionalInfo(FromQuery: TFIBCustomDataSet; const aFieldName: string; ToFieldInfo: TFIBFieldInfo);
var
  i: Integer;
begin
  try
    with FromQuery, TFriendFieldInfo(ToFieldInfo) do //
      if (fn('FIELD_NAME').asString = aFieldName) or Locate('FIELD_NAME', TrimRight(aFieldName), []) then
      begin
        FWithAdditionalInfo := True;
        for i := 0 to Pred(FieldCount) do
          with Fields[i] do
          begin
            if StringInArray(FieldName, ['TABLE_NAME', 'FIELD_NAME', 'FIB$VERSION']) then
              Continue
            else
              case FieldName[1] of
                'D':
                  case Length(FieldName) of
                    13:
                      if FieldName = 'DISPLAY_LABEL' then
                        FDisplayLabel := asString
                      else if FieldName = 'DISPLAY_WIDTH' then
                        FDisplayWidth := asInteger
                      else
                        FOtherInfo.Values[FieldName] := asString;
                    14:
                      if FieldName = 'DISPLAY_FORMAT' then
                        FDisplayFormat := asString
                      else
                        FOtherInfo.Values[FieldName] := asString;
                  else
                    FOtherInfo.Values[FieldName] := asString;
                  end;
                'E':
                  if FieldName = 'EDIT_FORMAT' then
                    FEditFormat := asString
                  else
                    FOtherInfo.Values[FieldName] := asString;
                'V':
                  if FieldName = 'VISIBLE' then
                    FVisible := asInteger = 1
                  else
                    FOtherInfo.Values[FieldName] := asString;
                'T':
                  if FieldName = 'TRIGGERED' then
                    FIsTriggered := asInteger = 1
                  else
                    FOtherInfo.Values[FieldName] := asString;
              else
                FOtherInfo.Values[FieldName] := asString;
              end
          end;
      end
  except
  end
end;

const
  FormatNumberSQL = 'select a1.RDB$RELATION_ID VER  from RDB$RELATIONS a1' +
    sLineBreak + 'where a1.RDB$SYSTEM_FLAG = 0  and a1.rdb$relation_name=?TN' + sLineBreak +
    'and not  a1.rdb$view_blr is null' + sLineBreak + 'union' + sLineBreak +
    'select RDB$FORMAT from RDB$RELATIONS R' + sLineBreak +
    'where R.RDB$SYSTEM_FLAG = 0    and R.rdb$relation_name=?TN' + sLineBreak +
    'and  R.rdb$view_blr is null';

  FI_VersionSQL  = 'Select Max(fib$version) From FIB$FIELDS_INFO Where table_name=?TN';
  FI_VersionsSQL = 'Select table_name,Max(fib$version) From FIB$FIELDS_INFO group by table_name order by 1';

function TFIBTableInfo.IsActualInfo(DB: TFIBDataBase): Boolean;
var
  q: TFIBQuery;
  InfoTransaction: TFIBTransaction;
  ForceTransaction: Boolean;
  UpdateRepository: Boolean;
begin
  UpdateRepository := False;
  InfoTransaction := TFriendDatabase(DB).GetInternalTransaction;
  if DB.DBName <> FDBName then
  begin
    Result := False;
    Exit;
  end
  else
    Result := True;
  ForceTransaction := DB.ActiveTransactionCount = 0;
  if not ForceTransaction then
    InfoTransaction := DB.FirstActiveTransaction;

  if (FTableName <> 'ALIAS') then
  begin
    q := GetQueryForUse(DB, InfoTransaction, FormatNumberSQL);
    with q do
      try
        Options := [qoStartTransaction];
        Params[0].asString := TableName;
        ExecQuery;
        Result := FFormatNumber = q.Fields[0].asInteger;
      finally
        Close;
        FreeQueryForUse(q);
      end;
  end;
  if Result and FWithFieldRepositoryInfo and ExistFieldsRepositoryTable(DB) then
  begin
    q := GetQueryForUse(DB, InfoTransaction, FI_VersionSQL);
    with q do
      try
        Options := [qoStartTransaction];
        Params[0].asString := TableName;
        try
          ExecQuery;
        except
          UpdateRepository := True;
        end;
        if not UpdateRepository then
          Result := FFIVersion = q.Fields[0].asInteger;
      finally
        Close;
        FreeQueryForUse(q);
      end;
    // after the query is released, its prepared statement would block the DDL
    if UpdateRepository then
    begin
      UpgradeFieldsRepositoryTable(DB);
      Exit;
    end;
  end;
  FNonValidated := not Result;
end;

procedure TFIBTableInfo.GetRepositoryFieldInfos(DB: TFIBDataBase; const TableName: string;
  aTransaction: TFIBTransaction);
var
  q: TFIBQuery;
  fi: TFIBFieldInfo;
  ExistAdInfo: Boolean;
  d: TFIBDataSet;
  i: Integer;
  UpdateRepository: Boolean;
begin
  d := nil;
  UpdateRepository := False;
  ExistAdInfo := ExistFieldsRepositoryTable(DB);
  if ExistAdInfo then
    try
      q := GetQueryForUse(DB, aTransaction, FI_VersionSQL);
      with q do
        try
          // GetVersion
          Options := [qoStartTransaction];
          Params[0].asString := TableName;
          try
            q.ExecQuery;
            FFIVersion := q.Fields[0].asInteger;
          except
            UpdateRepository := True;
            FFIVersion := 0;
          end;
        finally
          Close;
          FreeQueryForUse(q);
        end;
      if UpdateRepository then
        UpgradeFieldsRepositoryTable(DB);

      d := TFIBDataSet.Create(nil);
      d.PrepareOptions := [];
      d.Database := DB;
      d.Transaction := aTransaction;
      d.SelectSQL.Text := 'Select * from FIB$FIELDS_INFO where TABLE_NAME=:TN ORDER BY TABLE_NAME,FIELD_NAME';
      d.PrepareOptions := [];
      d.ParamByName('TN').asString := TableName;
      d.Open;
    except
      d.Free;
      d := nil;
      ExistAdInfo := False;
    end;
  if not ExistAdInfo then
    Exit;

  if TableName = 'ALIAS' then
  begin
    ClearFieldList;
    with d do
      try
        while not Eof do
        begin
          fi := TFIBFieldInfo.Create;
          GetAdditionalInfo(d, FastTrim(Fields[1].asString), fi);
          FFieldList.AddObject(FastTrim(Fields[1].asString), fi);
          Next
        end;
      finally
        Free;
      end
  end
  else
    try
      for i := 0 to Pred(FFieldList.Count) do
      begin
        fi := TFIBFieldInfo(FFieldList.Objects[i]);
        GetAdditionalInfo(d, FFieldList[i], fi);
      end;
    finally
      d.Free
    end;
end;

procedure TFIBTableInfo.GetInfoFields(DB: TFIBDataBase; const TableName: string;
  aTransaction: TFIBTransaction);
var
  q: TFIBQuery;
  fi: TFIBFieldInfo;
  ExistAdInfo: Boolean;
  d: TFIBDataSet;
  p: Integer;
  QuoteExist: Boolean;
  UpdateRepository: Boolean;
  ProcSQL: string;
begin
  if Length(TableName) = 0 then
    Exit;
  d := nil;
  UpdateRepository := False;
  ExistAdInfo := FWithFieldRepositoryInfo and ExistFieldsRepositoryTable(DB);
  if ExistAdInfo then
    try
      q := GetQueryForUse(DB, aTransaction, FI_VersionSQL);
      with q do
        try
          Options := [qoStartTransaction];
          Params[0].asString := TableName;
          try
            q.ExecQuery;
            FFIVersion := q.Fields[0].asInteger;
          except
            UpdateRepository := True;
            FFIVersion := 0;
          end;
        finally
          Close;
          FreeQueryForUse(q);
        end;
      if UpdateRepository then
        UpgradeFieldsRepositoryTable(DB);

      d := TFIBDataSet.Create(nil);
      d.PrepareOptions := [];
      d.Database := DB;
      d.Transaction := aTransaction;
      d.SelectSQL.Text := 'Select * from FIB$FIELDS_INFO where TABLE_NAME=:TN ORDER BY FIELD_NAME';
      d.PrepareOptions := [];
      d.ParamByName('TN').asString := TableName;
      d.Open;
    except
      d.Free;
      d := nil;
      ExistAdInfo := False;
    end;
  if TableName = 'ALIAS' then
  begin
    if not ExistAdInfo then
      Exit;
    with d do
      try
        while not Eof do
        begin
          fi := TFIBFieldInfo.Create;
          GetAdditionalInfo(d, FastTrim(Fields[1].asString), fi);
          FFieldList.AddObject(FastTrim(Fields[1].asString), fi);
          Next
        end;
      finally
        Free;
      end
  end
  else
  begin
    q := GetQueryForUse(DB, aTransaction,
      'Select R.RDB$FIELD_NAME,R.RDB$FIELD_SOURCE,F.RDB$COMPUTED_BLR, ' + sLineBreak +
      'R.RDB$DEFAULT_SOURCE DS,F.RDB$DEFAULT_SOURCE DS1, ' + sLineBreak +
      'F.RDB$FIELD_TYPE, ' + sLineBreak + 'F.RDB$CHARACTER_SET_ID, F.RDB$DIMENSIONS, '
      + sLineBreak + 'RL.RDB$FORMAT, RL.RDB$RELATION_ID, RL.RDB$VIEW_BLR ' + sLineBreak +
      'from  RDB$RELATION_FIELDS R ' + sLineBreak +
      'JOIN RDB$FIELDS F ON (R.RDB$FIELD_SOURCE = F.RDB$FIELD_NAME) ' + sLineBreak +
      'LEFT JOIN RDB$RELATIONS RL ON (RL.RDB$RELATION_NAME = R.RDB$RELATION_NAME '
      + sLineBreak + '  and RL.RDB$SYSTEM_FLAG = 0) ' + sLineBreak +
      'where  R.RDB$RELATION_NAME=:TN ' + sLineBreak +
      'order by R.RDB$FIELD_POSITION');

    try
      q.Options := [qoStartTransaction, qoTrimCharFields];
      q.Params[0].asString := TableName;
      q.ExecQuery;
      // Same value as FormatNumberSQL, which IsActualInfo compares with
      if q.Eof then
        FFormatNumber := 0
      else if q.Fields[10].IsNull then
        FFormatNumber := q.Fields[8].asInteger
      else
        FFormatNumber := q.Fields[9].asInteger;
      if q.Eof then
      begin
        // a selectable procedure: its output parameters, not those of a packaged one
        ProcSQL := 'Select P.RDB$PARAMETER_NAME,F.RDB$FIELD_NAME,0,0,0,' + sLineBreak +
          'P.RDB$PARAMETER_TYPE,' + sLineBreak + 'F.RDB$CHARACTER_SET_ID, NULL' +
          sLineBreak + 'from RDB$PROCEDURE_PARAMETERS P' + sLineBreak +
          'JOIN RDB$FIELDS F ON (P.RDB$FIELD_SOURCE = F.RDB$FIELD_NAME)' +
          'WHERE P.RDB$PROCEDURE_NAME=:PN' + sLineBreak +
          'AND P.RDB$PARAMETER_TYPE=1';
        if DB.IsFirebirdConnect and (DB.ODSMajorVersion >= 12) then
          ProcSQL := ProcSQL + sLineBreak + 'AND P.RDB$PACKAGE_NAME IS NULL';
        q.Close;
        FreeQueryForUse(q);
        q := nil;
        q := GetQueryForUse(DB, aTransaction, ProcSQL);
        q.Options := [qoStartTransaction, qoTrimCharFields];
        q.Params[0].asString := TableName;
        q.ExecQuery;
      end;
      ClearFieldList;

      with q do
        while not Eof do
        begin
          fi := TFIBFieldInfo.Create;
          with TFriendFieldInfo(fi) do
          begin
            FDomainName := Fields[1].asString;
            FIsComputed := (Fields[2].SQLType = SQL_BLOB) and not Fields[2].IsNull;
            FDefaultValue := '';
            if Fields[3].SQLType = SQL_BLOB then
            begin
              if not Fields[3].IsNull then
                FDefaultValue := FastTrim(Fields[3].asString);
              if FDefaultValue = '' then
                if not Fields[4].IsNull then
                  FDefaultValue := FastTrim(Fields[4].asString);
            end;
            if FDefaultValue <> '' then
            begin
              FDefaultValue := FastTrim(FastCopy(FDefaultValue, 8, MaxInt));
              // Cut "DEFAULT"
              QuoteExist := False;
              p := 1;
              while p <= Length(FDefaultValue) do
              begin
                if CharInSet(FDefaultValue[p], ['''', '"']) then
                begin
                  QuoteExist := True;
                  Break
                end
                else
                  Inc(p);
              end;
              if QuoteExist then
              begin
                FDefaultValue := CutQuote(FastTrim(FastCopy(FDefaultValue, p, MaxInt)));
              end;
              if FDefaultValue = '' then
                FDefaultValueEmptyString := True;
              // Cut Leading Quote
            end;
            case Fields[5].asInteger of
              9, 261: FCanIncToWhereClause := False
            else
              FCanIncToWhereClause := Fields[7].IsNull
            end;
            FCharSet := Fields[6].asInteger;
            if ExistAdInfo then
              GetAdditionalInfo(d, FastTrim(Fields[0].asString), fi);
          end;
          FFieldList.AddObject(FastTrim(Fields[0].asString), fi);
          Next
        end;
    finally
      if ExistAdInfo then
        d.Free;
      if q <> nil then
      begin
        q.Close;
        FreeQueryForUse(q);
      end;
    end
  end;
end;

// TFIBTableInfoCache
constructor TFIBTableInfoCache.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FListTabInfo := TStringList.Create;
  // "Name" and NAME are different tables
  FListTabInfo.CaseSensitive := True;
  FListTabInfo.Sorted := True;
  FListTabInfo.Duplicates := dupAccept;
  FLock := TCriticalSection.Create;
end;

destructor TFIBTableInfoCache.Destroy; // override;
begin
  FLock.Acquire;
  try
    Clear;
    FListTabInfo.Free;
    FListTabInfo := nil;
    inherited Destroy;
  finally
    FLock.Release;
    FLock.Free
  end;
end;

// Table infos are per database name, shared and validated on use: only the state goes
procedure TFIBTableInfoCache.Notification(AComponent: TComponent; Operation: TOperation);
var
  Index: Integer;
begin
  if (Operation = opRemove) and (AComponent is TFIBDataBase) then
  begin
    LockRepList.Acquire;
    try
      Index := DatabaseRepositories.IndexOfObject(AComponent);
      if Index <> -1 then
        DatabaseRepositories.Delete(Index);
    finally
      LockRepList.Release;
    end;
  end;
  inherited Notification(AComponent, Operation);
end;

const
  Signature        = 'FIB$MCF';
  DSSignature      = 'FIB$MCFDS';

procedure TFIBTableInfoCache.SaveToStream(Stream: TStream);
var
  i, tc: Integer;
  StreamVersion: Integer;
begin
  FLock.Acquire;
  try
    with Stream do
    begin
      Seek(0, soFromBeginning);
      WriteStrToStream(Signature, Stream);
      StreamVersion := CurStreamVersion;
      WriteBuffer(StreamVersion, SizeOf(Integer));
      WriteBuffer(FLastTransactionId, SizeOf(Integer));
      tc := FListTabInfo.Count;
      WriteBuffer(tc, SizeOf(Integer));
      for i := 0 to Pred(tc) do
      begin
        WriteUTF8StrToStream(FListTabInfo[i], Stream);
        TFIBTableInfo(FListTabInfo.Objects[i]).SaveToStream(Stream);
      end;
    end;
  finally
    FLock.Release;
  end;
end;

procedure TFIBTableInfoCache.LoadFromStream(Stream: TStream; DB: TFIBDataBase = nil);
var
  i, tc: Integer;
  StreamVersion: Integer;
  tn: AnsiString;
  TableName: string;
  ti: TFIBTableInfo;
begin
  FLock.Acquire;
  try
    Clear;
    with Stream do
    begin
      Seek(0, soFromBeginning);
      SetLength(tn, Length(Signature));
      ReadBuffer(tn[1], Length(Signature)); // Signature
      if tn <> Signature then
      begin
        Seek(0, soFromBeginning);
        ReadStrFromStream(Stream, tn);
      end;
      if tn <> Signature then
        Exit;
      ReadBuffer(StreamVersion, SizeOf(Integer));
      if (StreamVersion < MinStreamVersion) or (StreamVersion > CurStreamVersion) then
        Exit;

      ReadBuffer(tc, SizeOf(Integer));
      if (DB <> nil) then
        PrepareInternalTransaction(DB);
      if tc > FLastTransactionId then
      begin
        Exit; // Database is after backup
      end;

      ReadBuffer(tc, SizeOf(Integer));
      for i := 0 to Pred(tc) do
      begin
        TableName := ReadUTF8StrFromStream(Stream, StreamVersion >= 7);
        ti := TFIBTableInfo.Create(Self);
        try
          ti.LoadFromStreamVersion(Stream, StreamVersion);
        except
          ti.Free;
          raise;
        end;
        FListTabInfo.AddObject(TableName, ti)
      end;
    end;
  finally
    FLock.Release;
  end;
end;

procedure TFIBTableInfoCache.SaveToFile(const FileName: string);
begin
  SaveCacheFile(FileName, FListTabInfo.Count > 0, SaveToStream);
end;

function TFIBTableInfoCache.LoadFromFile(const FileName: string; DB: TFIBDataBase = nil): Boolean;
var
  Stream: TFileStream;
begin
  Clear;
  Result := FileExists(FileName);
  if not Result then
    Exit;
  Stream := TFileStream.Create(FileName, fmOpenRead);
  try
    try
      LoadFromStream(Stream, DB);
    except
      on E: Exception do
      begin
        if E is EFIBError then
          raise;
        // a damaged cache file is ignored, the infos are read from the database
        Clear;
        Result := False;
      end;
    end;
  finally
    Stream.Free;
  end;
end;

procedure TFIBTableInfoCache.ValidateSchema(aDataBase: TFIBDataBase; Proc: TFIBAcceptCacheSchemaEvent);
const
  MaxCountSeparate = 10;
var
  i: Integer;
  DelCache, rt: Boolean;
  FiDs, TfDs: TFIBDataSet;
  WorkTransaction: TFIBTransaction;
  DBCount: Integer;
  BulkCheck: Boolean;
  // FiDs - Versions from FIB$FIELDS_INFO
  // TfDs - metadata counters
begin
  PrepareInternalTransaction(aDataBase);
  WorkTransaction := TFriendDatabase(aDataBase).GetInternalTransaction;
  TfDs := nil;
  FiDs := nil;
  // the infos are freed under the lock, as in the other methods of the cache
  FLock.Acquire;
  try
    with FListTabInfo do
    begin
      // The cache is shared by all databases, only the entries of aDataBase are validated
      DBCount := 0;
      for i := 0 to Count - 1 do
        if TFIBTableInfo(Objects[i]).FDBName = aDataBase.DBName then
          Inc(DBCount);
      BulkCheck := (DBCount > MaxCountSeparate) and not Assigned(Proc);
      if not BulkCheck then
        rt := False
      else
      begin
        TfDs := TFIBDataSet.Create(nil);
        with TfDs do
        begin
          Database := aDataBase;
          Options := [poStartTransaction, poTrimCharFields];
          Transaction := WorkTransaction;
          SelectSQL.Add(FormatNumbersSQL);
          PrepareOptions := [];
          Open;
        end;
        rt := TfDs.ExtLocate('RDB$RELATION_NAME', 'FIB$FIELDS_INFO', [eloInSortedDS]);
        if rt then
        begin
          FiDs := TFIBDataSet.Create(nil);
          with FiDs do
          begin
            Database := aDataBase;
            Options := [poStartTransaction, poTrimCharFields];
            Transaction := WorkTransaction;
            SelectSQL.Add(FI_VersionsSQL);
            PrepareOptions := [];
            Open;
          end;
        end;
      end;
      for i := Count - 1 downto 0 do
      begin
        if TFIBTableInfo(Objects[i]).FDBName <> aDataBase.DBName then
          Continue;
        if Assigned(Proc) then
        begin
          DelCache := False;
          Proc(FListTabInfo[i], DelCache);
          DelCache := not DelCache
        end
        else if BulkCheck then
        begin
          DelCache := (TfDs = nil) or (FListTabInfo[i] <> 'ALIAS') and
            not(TfDs.ExtLocate('RDB$RELATION_NAME', FListTabInfo[i], [eloInSortedDS]) and
            (TfDs.Fields[1].asInteger = TFIBTableInfo(Objects[i]).FFormatNumber));
          if rt and not DelCache then
            DelCache := (FiDs = nil) or not(FiDs.ExtLocate('TABLE_NAME', FListTabInfo[i], [eloInSortedDS])
              and (FiDs.Fields[1].asInteger = TFIBTableInfo(Objects[i]).FFIVersion));
        end
        else
          with TFIBTableInfo(Objects[i]) do
            DelCache := (Length(FTableName) > 0) and not IsActualInfo(aDataBase);
        if DelCache then
        begin
          Objects[i].Free;
          Delete(i)
        end
        else
          TFIBTableInfo(Objects[i]).FNonValidated := False;
      end;
    end;
  finally
    TfDs.Free;
    FiDs.Free;
    FLock.Release;
  end;
end;

function TFIBTableInfoCache.FindTableInfo(const ADBName, ATableName: string): TFIBTableInfo;
var
  Index: Integer;
  i: Integer;
begin
  Result := nil;
  with FListTabInfo do
    if Find(ATableName, Index) then
      if ADBName = TFIBTableInfo(Objects[Index]).FDBName then
        Result := TFIBTableInfo(Objects[Index])
      else // other Database
        for i := Index + 1 to Pred(Count) do
          if (ATableName = Strings[i]) and (ADBName = TFIBTableInfo(Objects[i]).FDBName) then
          begin
            Result := TFIBTableInfo(Objects[i]);
            Break;
          end
          else if (ATableName <> Strings[i]) then
            Exit;
end;

procedure TFIBTableInfoCache.PrepareInternalTransaction (aDataBase: TFIBDataBase);
var
  WorkTransaction: TFIBTransaction;
begin
  WorkTransaction := TFriendDatabase(aDataBase).GetInternalTransaction;
  if not WorkTransaction.Active then
    WorkTransaction.StartTransaction;
  FLastTransactionId := WorkTransaction.TransactionID;
  // ^^^^ For this only
end;

function TFIBTableInfoCache.GetTableInfo(aDataBase: TFIBDataBase; const ATableName: string; WithRepositoryInfo: Boolean): TFIBTableInfo;
var
  TmpTableName: string;
  WorkTransaction: TFIBTransaction;
begin
  WorkTransaction := TFriendDatabase(aDataBase).GetInternalTransaction;
  TmpTableName := FastTrim(ReplaceStr(ATableName, '"', ''));
  FLock.Acquire;
  try
    if not(csDesigning in aDataBase.ComponentState) then
      Result := FindTableInfo(aDataBase.DBName, TmpTableName)
    else
    begin
      Result := nil;
      ClearForTable(ATableName);
    end;
    if (Result <> nil) and Result.FNonValidated and FNeedValidate and
      not Result.IsActualInfo(aDataBase) then
    begin
      // the outdated info is read again
      FListTabInfo.Delete(FListTabInfo.IndexOfObject(Result));
      Result.Free;
      Result := nil;
    end;
    if Result = nil then
    begin
      Result := TFIBTableInfo.Create(Self);
      try
        Result.FWithFieldRepositoryInfo := WithRepositoryInfo;
        Result.FillInfo(aDataBase, WorkTransaction, TmpTableName);
      except
        Result.Free;
        raise;
      end;
      FListTabInfo.AddObject(TmpTableName, Result);
    end
    else if WithRepositoryInfo and not Result.FWithFieldRepositoryInfo then
    begin
      Result.GetRepositoryFieldInfos(aDataBase, TmpTableName, WorkTransaction);
      Result.FWithFieldRepositoryInfo := WithRepositoryInfo;
    end;
  finally
    FLock.Release;
  end;
end;

function TFIBTableInfoCache.GetFieldInfo(aDataBase: TFIBDataBase;
  const ATableName, aFieldName: string; RepositoryInfo: Boolean)
  : TFIBFieldInfo;
var
  ti: TFIBTableInfo;
begin
  Result := nil;
  ti := GetTableInfo(aDataBase, ATableName, RepositoryInfo);
  if ti = nil then
    Exit;
  Result := ti.FieldInfo(aFieldName);
end;

procedure TFIBTableInfoCache.Clear;
var
  i: Integer;
begin
  FLock.Acquire;
  try
    for i := 0 to Pred(FListTabInfo.Count) do
      FListTabInfo.Objects[i].Free;
    FListTabInfo.Clear;
  finally
    FLock.Release;
  end;
end;

procedure TFIBTableInfoCache.ClearForDataBase(aDataBase: TFIBDataBase);
var
  i: Integer;
begin
  FLock.Acquire;
  try
    if aDataBase = nil then
      Exit;
    with FListTabInfo do
      for i := Pred(Count) downto 0 do
        if (TFIBTableInfo(Objects[i]).FDBName = aDataBase.DBName) then
        begin
          Objects[i].Free;
          Delete(i)
        end;
  finally
    FLock.Release;
  end;

end;

procedure TFIBTableInfoCache.ClearForTable(const TableName: string);
var
  Index: Integer;
  TmpTableName: string;
begin
  TmpTableName := FastTrim(ReplaceStr(TableName, '"', ''));
  FLock.Acquire;
  try
    with FListTabInfo do
      if Find(TmpTableName, Index) then
      begin
        while (Index < Count) and (TFIBTableInfo(Objects[Index]).FTableName = TmpTableName) do
        begin
          Objects[Index].Free;
          Delete(Index)
        end;
      end;
  finally
    FLock.Release;
  end;
end;

// DataSets info
constructor TFIBDataSetInfo.Create;
begin
  FStreamVersion := DSCurStreamVersion;
  FSelectSQL := TStringList.Create;
  FInsertSQL := TStringList.Create;
  FUpdateSQL := TStringList.Create;
  FDeleteSQL := TStringList.Create;
  FRefreshSQL := TStringList.Create;
end;

constructor TFIBDataSetInfo.Create(DataSet: TFIBCustomDataSet);
begin
  if DataSet = nil then
    raise Exception.Create(SCantGetInfo + 'nil');
  if (DataSet.Database = nil) or (DataSet.Database.DBName = '') then
    raise Exception.Create(SCantGetInfo + IntToStr(DataSet.DataSet_ID) + sLineBreak + SDataBaseNotAssigned);
  Create;
  FDBName := DataSet.Database.DBName;
end;

destructor TFIBDataSetInfo.Destroy;
begin
  FSelectSQL.Free;
  FInsertSQL.Free;
  FUpdateSQL.Free;
  FDeleteSQL.Free;
  FRefreshSQL.Free;
  inherited Destroy;
end;

constructor TFIBDataSetInfoCache.Create; // (AOwner:TComponent);
begin
  inherited Create;
  FListDataSetInfo := TStringList.Create;
  FListDataSetInfo.Sorted := True;
  FListDataSetInfo.Duplicates := dupAccept;
  FLock := TCriticalSection.Create;
end;

destructor TFIBDataSetInfoCache.Destroy;
begin
  Clear;
  FListDataSetInfo.Free;
  FLock.Free;
  inherited;
end;

procedure TFIBDataSetInfoCache.Clear;
var
  i: Integer;
begin
  FLock.Acquire;
  try
    with FListDataSetInfo do
    begin
      for i := 0 to Pred(Count) do
        Objects[i].Free;
      Clear;
    end;
  finally
    FLock.Release;
  end;
end;

function TFIBDataSetInfoCache.ActualVersionDSInfo(DataSet: TFIBCustomDataSet): Integer;
var
  q: TFIBQuery;
begin
  Result := 0;
  if DataSet = nil then
    Exit;
  q := GetQueryForUse(DataSet.Database, DataSet.Transaction, 'SELECT FIB$VERSION FROM FIB$DATASETS_INFO WHERE DS_ID=:DS_ID');
  try
    q.Params[0].asInteger := DataSet.DataSet_ID;
    q.ExecQuery;
    if not q.Eof then
      Result := q.Fields[0].asInteger
  finally
    q.Close;
    FreeQueryForUse(q);
  end;
end;

function TFIBDataSetInfoCache.FindDataSetInfo(DataSet: TFIBCustomDataSet; var Index: Integer): TFIBDataSetInfo;
begin
  Result := nil;
  if (DataSet = nil) or (DataSet.Database = nil) or (DataSet.DataSet_ID = 0) then
    Exit;
  Result := FindDataSetInfo(DataSet.Database.DBName, DataSet.DataSet_ID, Index)
end;

function TFIBDataSetInfoCache.FindDataSetInfo(const DBName: string; DS_ID: Integer; var Index: Integer): TFIBDataSetInfo;
var
  ID_Str: string;
  i: Integer;
begin
  ID_Str := IntToStr(DS_ID);
  Result := nil;
  with FListDataSetInfo do
    if Find(ID_Str, Index) then
      if DBName = TFIBDataSetInfo(Objects[Index]).FDBName then
        Result := TFIBDataSetInfo(Objects[Index])
      else
      begin
        for i := Index + 1 to Pred(Count) do
          if (ID_Str = Strings[i]) and (DBName = TFIBDataSetInfo(Objects[i]).FDBName) then
          begin
            Result := TFIBDataSetInfo(Objects[i]);
            Index := i;
            Break;
          end
          else if (ID_Str <> Strings[i]) then
            Exit;
      end;
end;

function TFIBDataSetInfoCache.GetDataSetInfo(DataSet: TFIBCustomDataSet): TFIBDataSetInfo;
var
  Index: Integer;
begin
  Result := nil;

  if (DataSet = nil) or (DataSet.Database = nil) or (DataSet.DataSet_ID = 0) then
    Exit;
  Result := FindDataSetInfo(DataSet, Index);
  if Result <> nil then
    if Result.FNonValidated and FNeedValidate then
    begin
      if ActualVersionDSInfo(DataSet) <> Result.FVersion then
      begin
        FListDataSetInfo.Delete(Index);
        Result.Free;
        Result := nil
      end
      else
        Result.FNonValidated := False
    end;

  if Result = nil then
  begin
    Result := TFIBDataSetInfo.Create(DataSet);
    try
      // without a stored row there is no info: the settings of the dataset stay
      if not ExchangeDataSetInfo(DataSet, Result) then
        FreeAndNil(Result);
    except
      Result.Free;
      raise;
    end;
    if Result <> nil then
      FListDataSetInfo.AddObject(IntToStr(DataSet.DataSet_ID), Result);
  end;
end;

function TFIBDataSetInfoCache.LoadDataSetInfo(DataSet: TFIBCustomDataSet): Boolean;
var
  DSI: TFIBDataSetInfo;
begin
  Result := False;
  if DataSet = nil then
    Exit;
  FLock.Acquire;
  try
    if csDesigning in DataSet.ComponentState then
      ClearDSInfo(DataSet);
    DSI := GetDataSetInfo(DataSet);
    if DSI = nil then
      Exit;
    with TFriendDataSet(DataSet) do
    begin
      if (DSI.FSelectSQL.Count > 0) and (not SelectSQL.Equals(DSI.FSelectSQL)) then
      begin
        if not Conditions.Applied or (Conditions.PrimarySQL <> DSI.FSelectSQL.Text) then
          SelectSQL.Assign(DSI.FSelectSQL);
      end;
      if (DSI.FInsertSQL.Count > 0) and (not InsertSQL.Equals(DSI.FInsertSQL)) then
        InsertSQL.Assign(DSI.FInsertSQL);
      if (DSI.FUpdateSQL.Count > 0) and (not UpdateSQL.Equals(DSI.FUpdateSQL)) then
        UpdateSQL.Assign(DSI.FUpdateSQL);
      if (DSI.FDeleteSQL.Count > 0) and (not DeleteSQL.Equals(DSI.FDeleteSQL)) then
        DeleteSQL.Assign(DSI.FDeleteSQL);
      if (DSI.FRefreshSQL.Count > 0) and (not RefreshSQL.Equals(DSI.FRefreshSQL)) then
        RefreshSQL.Assign(DSI.FRefreshSQL);
      with AutoUpdateOptions do
      begin
        SelectGenID := (DSI.FKeyField <> '') and (DSI.FGeneratorName <> '');
        KeyFields := DSI.FKeyField;
        GeneratorName := DSI.FGeneratorName;
        UpdateOnlyModifiedFields := DSI.FUpdateOnlyModifiedFields;
        UpdateTableName := DSI.FUpdateTableName;
      end;
      Conditions.ReadFromExchangeString(DSI.FConditions);
      Description := DSI.FDescription
    end;
  finally
    FLock.Release;
  end;
end;

procedure TFIBDataSetInfoCache.ClearDSInfo(DataSet: TFIBCustomDataSet);
var
  ID_Str: string;
  Index: Integer;
begin
  if DataSet = nil then
    Exit;
  FLock.Acquire;
  try
    if DataSet.DataSet_ID = 0 then
      Exit;
    ID_Str := IntToStr(DataSet.DataSet_ID);
    with FListDataSetInfo do
      if Find(ID_Str, Index) then
        // the same DS_ID of other databases follows in the sorted list
        while (Index < Count) and (Strings[Index] = ID_Str) do
          if (DataSet.Database <> nil) and (DataSet.Database.DBName = TFIBDataSetInfo(Objects[Index]).FDBName) then
          begin
            Objects[Index].Free;
            Delete(Index);
          end
          else
            Inc(Index);
  finally
    FLock.Release;
  end;
end;

procedure TFIBDataSetInfoCache.ClearDSInfo(DS_ID: Integer);
var
  ID_Str: string;
  Index: Integer;
begin
  FLock.Acquire;
  try
    if (DS_ID = 0) then
      Exit;
    ID_Str := IntToStr(DS_ID);
    with FListDataSetInfo do
      while Find(ID_Str, Index) do
      begin
        Objects[Index].Free;
        Delete(Index);
      end;
  finally
    FLock.Release;
  end;
end;

//

type
  TFIBStoredProcMetadata = class
  private
    FParamsText: string; // '(?A, ?B)' or ''
    FDefaultValues: array of string;
  end;

  // Exact and locale independent: quoted names are case sensitive, and keys
  // with a common prefix stay adjacent
  TOrdinalStringList = class(TStringList)
  protected
    function CompareStrings(const S1, S2: string): Integer; override;
  end;

function TOrdinalStringList.CompareStrings(const S1, S2: string): Integer;
begin
  Result := CompareStr(S1, S2);
end;

const
  qInputParams = 'SELECT PP.RDB$PARAMETER_NAME, %s' + sLineBreak +
    'FROM RDB$PROCEDURE_PARAMETERS PP' + sLineBreak + '%s' +
    'WHERE PP.RDB$PROCEDURE_NAME = :PN AND PP.RDB$PARAMETER_TYPE = 0' + sLineBreak +
    '%s' + 'ORDER BY PP.RDB$PARAMETER_NUMBER';

  // ODS 11 (Firebird 2.0) has parameter defaults, ODS 12 (Firebird 3.0) packages
function InputParamsSQL(DB: TFIBDataBase): string;
var
  ODS: Integer;
begin
  if DB.IsFirebirdConnect then
    ODS := DB.ODSMajorVersion
  else
    ODS := 0;
  if ODS >= 12 then
    Result := Format(qInputParams, ['PP.RDB$DEFAULT_SOURCE', '', 'AND PP.RDB$PACKAGE_NAME IS NULL' + sLineBreak])
  else if ODS >= 11 then
    Result := Format(qInputParams, ['PP.RDB$DEFAULT_SOURCE', '', ''])
  else
    Result := Format(qInputParams, ['F.RDB$DEFAULT_SOURCE',
      'JOIN RDB$FIELDS F ON F.RDB$FIELD_NAME = PP.RDB$FIELD_SOURCE' + sLineBreak, '']);
end;

// '= 5' or 'DEFAULT 5' -> '5'
function DefaultSourceValue(const Source: string): string;
begin
  Result := FastTrim(Source);
  if (Result <> '') and (Result[1] = '=') then
    Result := FastTrim(FastCopy(Result, 2, Length(Result)))
  else if FastUpperCase(FastCopy(Result, 1, 7)) = 'DEFAULT' then
    Result := FastTrim(FastCopy(Result, 8, Length(Result)));
end;

function LoadStoredProcMetadata(DB: TFIBDataBase; const StoredProcName: string): TFIBStoredProcMetadata;
var
  Query: TFIBQuery;
  Transaction: TFIBTransaction;
  ParamsText: string;
  Count: Integer;
begin
  if not DB.Connected then
    FIBError(feDatabaseClosed, [CmpFullName(DB)]);

  Result := TFIBStoredProcMetadata.Create;
  Transaction := CreateInternalTransaction(DB, True);
  Query := TFIBQuery.Create(nil);
  try
    try
      Query.Database := DB;
      Query.Transaction := Transaction;
      Query.ParamCheck := True;
      Query.SQL.Text := InputParamsSQL(DB);
      // On failure Transaction.Free ends the transaction without masking the error
      Transaction.StartTransaction;
      Query.Params[0].asString := FormatIdentifierValue(DB.SQLDialect, StoredProcName);
      Query.ExecQuery;
      ParamsText := '';
      Count := 0;
      while not Query.Eof do
      begin
        if ParamsText <> '' then
          ParamsText := ParamsText + ', ';
        ParamsText := ParamsText + '?' + FormatIdentifier(DB.SQLDialect, FastTrim(Query.Fields[0].asString));
        SetLength(Result.FDefaultValues, Count + 1);
        Result.FDefaultValues[Count] := DefaultSourceValue(Query.Fields[1].asString);
        Inc(Count);
        Query.Next;
      end;
      Query.Close;
      Transaction.Commit;
      if ParamsText <> '' then
        Result.FParamsText := '(' + ParamsText + ')';
    except
      Result.Free;
      raise;
    end;
  finally
    Query.Free;
    Transaction.Free;
  end;
end;

function CacheKey(DB: TFIBDataBase; const StoredProcName: string): string;
begin
  Result := DB.DBName + #0 + StoredProcName;
end;

// '"My ""Proc"""' -> 'My "Proc"'
function StripQuote(const Value: string): string;
var
  Quote: Char;
begin
  if (Value <> '') and ((Value[1] = '"') or (Value[1] = '''')) then
  begin
    Quote := Value[1];
    Result := StringReplace(FastCopy(Value, 2, Length(Value) - 2), Quote + Quote, Quote, [rfReplaceAll]);
  end
  else
    Result := Value;
end;

{ TFIBStoredProcMetadataCache }

constructor TFIBStoredProcMetadataCache.Create;
begin
  inherited Create;
  FItems := TOrdinalStringList.Create;
  FItems.Sorted := True;
  FLock := TCriticalSection.Create;
end;

destructor TFIBStoredProcMetadataCache.Destroy;
begin
  Clear;
  FItems.Free;
  FLock.Free;
  inherited Destroy;
end;

procedure TFIBStoredProcMetadataCache.Clear;
var
  i: Integer;
begin
  FLock.Acquire;
  try
    for i := 0 to FItems.Count - 1 do
      FItems.Objects[i].Free;
    FItems.Clear;
  finally
    FLock.Release;
  end;
end;

procedure TFIBStoredProcMetadataCache.ClearSPInfo(DB: TFIBDataBase);
var
  Prefix: string;
  i: Integer;
begin
  Prefix := CacheKey(DB, '');
  FLock.Acquire;
  try
    // Keys of the same database are adjacent in the sorted list
    FItems.Find(Prefix, i);
    while (i < FItems.Count) and (CompareStr(FastCopy(FItems[i], 1, Length(Prefix)), Prefix) = 0) do
    begin
      FItems.Objects[i].Free;
      FItems.Delete(i);
    end;
  finally
    FLock.Release;
  end;
end;

// Returns with FLock acquired, the caller must release it
function TFIBStoredProcMetadataCache.AcquireMetadata(DB: TFIBDataBase; const StoredProcName: string; ForceReQuery: Boolean): TObject;
var
  Name, Key: string;
  i: Integer;
  Metadata: TFIBStoredProcMetadata;
begin
  Name := StripQuote(StoredProcName);
  Key := CacheKey(DB, Name);
  if not ForceReQuery then
  begin
    FLock.Acquire;
    if FItems.Find(Key, i) then
    begin
      Result := FItems.Objects[i];
      Exit;
    end;
    FLock.Release;
  end;

  // Loaded outside the lock; nothing is cached on failure
  Metadata := LoadStoredProcMetadata(DB, Name);
  FLock.Acquire;
  try
    if FItems.Find(Key, i) then
    begin
      FItems.Objects[i].Free;
      FItems.Objects[i] := Metadata;
    end
    else
      FItems.AddObject(Key, Metadata);
  except
    FLock.Release;
    Metadata.Free;
    raise;
  end;
  Result := Metadata;
end;

function TFIBStoredProcMetadataCache.GetExecProcTxt(DB: TFIBDataBase; const StoredProcName: string; ForceReQuery: Boolean): string;
var
  Metadata: TFIBStoredProcMetadata;
begin
  Metadata := TFIBStoredProcMetadata(AcquireMetadata(DB, StoredProcName, ForceReQuery));
  try
    Result := 'EXECUTE PROCEDURE ' + StoredProcName;
    if Metadata.FParamsText <> '' then
      Result := Result + ' ' + Metadata.FParamsText;
  finally
    FLock.Release;
  end;
end;

function TFIBStoredProcMetadataCache.GetParamDefValue(DB: TFIBDataBase; const StoredProcName: string; ParamNo: Integer): string;
var
  Metadata: TFIBStoredProcMetadata;
begin
  Metadata := TFIBStoredProcMetadata(AcquireMetadata(DB, StoredProcName, False));
  try
    if (ParamNo >= 0) and (ParamNo < Length(Metadata.FDefaultValues)) then
      Result := Metadata.FDefaultValues[ParamNo]
    else
      Result := '';
  finally
    FLock.Release;
  end;
end;

// Routine function

function GetFieldInfos(Field: TField; RepositoryInfo: Boolean): TFIBFieldInfo;
var
  d: TFIBCustomDataSet;
  RelTable, RelField: string;
begin
  Result := nil;
  if not(Field.DataSet is TFIBCustomDataSet) then
    Exit;
  d := TFIBCustomDataSet(Field.DataSet);
  with d do
  begin
    RelTable := GetRelationTableName(Field);
    RelField := GetRelationFieldName(Field);
    Result := TableInfoCache.GetFieldInfo(Database, RelTable, RelField, RepositoryInfo);
  end;
  if Result <> nil then
    Exit;

  RelTable := 'ALIAS';
  RelField := Field.FieldName;
  with d do
    Result := TableInfoCache.GetFieldInfo(Database, RelTable, RelField, RepositoryInfo);
end;

{ TFIBErrorMessage }

constructor TFIBErrorMessage.Create(const aErrorMsg: string; aVersion: Integer);
begin
  FErrorMsg := aErrorMsg;
  FVersion := aVersion;
end;

type
  // The messages of one database, by the exact constraint name as FIB$ERROR_MESSAGES compares it
  TFIBDatabaseErrorMessages = class(TStringList)
  private
    FMaxVersion: Integer;
    FValidated: Boolean;
  public
    constructor Create;
    procedure AddMessage(const ErrorName, ErrorMsg: string; Version: Integer);
  end;

constructor TFIBDatabaseErrorMessages.Create;
begin
  inherited Create;
  CaseSensitive := True;
  Sorted := True;
  Duplicates := dupIgnore;
  OwnsObjects := True;
end;

procedure TFIBDatabaseErrorMessages.AddMessage(const ErrorName, ErrorMsg: string; Version: Integer);
var
  Index: Integer;
  Msg: TFIBErrorMessage;
begin
  if Find(ErrorName, Index) then
  begin
    Msg := TFIBErrorMessage(Objects[Index]);
    if Version > Msg.FVersion then
    begin
      Msg.FErrorMsg := ErrorMsg;
      Msg.FVersion := Version;
    end;
  end
  else
    AddObject(ErrorName, TFIBErrorMessage.Create(ErrorMsg, Version));
end;

{ TFIBErrorMessageCache }

const
  ErrSignature = 'FIB$Error_messages';

constructor TFIBErrorMessageCache.Create;
begin
  inherited Create;
  FDatabases := TStringList.Create;
  FDatabases.Sorted := True;
  FDatabases.Duplicates := dupIgnore;
  FDatabases.OwnsObjects := True;
  FLock := TMultiReadExclusiveWriteSynchronizer.Create;
end;

destructor TFIBErrorMessageCache.Destroy;
begin
  FDatabases.Free;
  FLock.Free;
  inherited Destroy;
end;

// The caller holds the lock, the write lock when CanCreate is True
function TFIBErrorMessageCache.DatabaseMessages(const DBName: string; CanCreate: Boolean): TObject;
var
  Index: Integer;
begin
  if FDatabases.Find(DBName, Index) then
    Result := FDatabases.Objects[Index]
  else if CanCreate then
  begin
    Result := TFIBDatabaseErrorMessages.Create;
    FDatabases.AddObject(DBName, Result);
  end
  else
    Result := nil;
end;

procedure TFIBErrorMessageCache.Clear;
begin
  FLock.BeginWrite;
  try
    FDatabases.Clear;
  finally
    FLock.EndWrite;
  end;
end;

procedure TFIBErrorMessageCache.AddErrorMessage(const DBName, ErrorName, ErrorMsg: string; Version: Integer);
begin
  FLock.BeginWrite;
  try
    TFIBDatabaseErrorMessages(DatabaseMessages(DBName, True)).AddMessage(ErrorName, ErrorMsg, Version);
  finally
    FLock.EndWrite;
  end;
end;

function TFIBErrorMessageCache.FindErrorMessage(const DBName, ErrorName: string; out ErrorMsg: string): Boolean;
var
  Messages: TFIBDatabaseErrorMessages;
  Index: Integer;
begin
  Result := False;
  FLock.BeginRead;
  try
    Messages := TFIBDatabaseErrorMessages(DatabaseMessages(DBName, False));
    if (Messages <> nil) and Messages.Find(ErrorName, Index) then
    begin
      ErrorMsg := TFIBErrorMessage(Messages.Objects[Index]).FErrorMsg;
      Result := True;
    end;
  finally
    FLock.EndRead;
  end;
end;

function TFIBErrorMessageCache.IsValidated(const DBName: string): Boolean;
var
  Messages: TObject;
begin
  FLock.BeginRead;
  try
    Messages := DatabaseMessages(DBName, False);
    Result := (Messages <> nil) and TFIBDatabaseErrorMessages(Messages).FValidated;
  finally
    FLock.EndRead;
  end;
end;

// No messages, or another max version (a changed message, a restored database): drop the cached ones
procedure TFIBErrorMessageCache.Validate(const DBName: string; MaxVersion: Integer);
var
  Messages: TFIBDatabaseErrorMessages;
begin
  FLock.BeginWrite;
  try
    Messages := TFIBDatabaseErrorMessages(DatabaseMessages(DBName, True));
    if (MaxVersion = 0) or (MaxVersion <> Messages.FMaxVersion) then
      Messages.Clear;
    Messages.FMaxVersion := MaxVersion;
    Messages.FValidated := True;
  finally
    FLock.EndWrite;
  end;
end;

// The message of ErrorName in FIB$ERROR_MESSAGES of DB, read in Tr
function TFIBErrorMessageCache.ErrorMessage(DB: TFIBDataBase; Tr: TFIBTransaction; const ErrorName: string): string;
var
  Version: Integer;
  q: TFIBQuery;
begin
  Result := '';
  if not (urErrorMessagesInfo in DB.UseRepositories) or not ExistErrorsRepositoryTable(DB) then
    Exit;
  if not IsValidated(DB.DBName) then
  begin
    q := GetQueryForUse(DB, Tr, 'SELECT MAX(FIB$VERSION) FROM FIB$ERROR_MESSAGES');
    try
      q.ExecQuery;
      Validate(DB.DBName, q.Fields[0].AsInteger);
    finally
      FreeQueryForUse(q);
    end;
  end;
  if FindErrorMessage(DB.DBName, ErrorName, Result) then
    Exit;
  q := GetQueryForUse(DB, Tr, 'SELECT MESSAGE_STRING, FIB$VERSION FROM FIB$ERROR_MESSAGES WHERE CONSTRAINT_NAME=?CN');
  try
    q.Options := q.Options + [qoTrimCharFields];
    q.Params[0].AsString := ErrorName;
    q.ExecQuery;
    Version := 0;
    if not q.Eof then
    begin
      Result := q.Fields[0].AsString;
      Version := q.Fields[1].AsInteger;
    end;
  finally
    FreeQueryForUse(q);
  end;
  // a constraint without a message is cached too, with an empty one
  AddErrorMessage(DB.DBName, ErrorName, Result, Version);
end;

procedure TFIBErrorMessageCache.LoadFromFile(const FileName: string);
var
  Stream: TFileStream;
begin
  if not FileExists(FileName) then
    Exit;
  Stream := TFileStream.Create(FileName, fmOpenRead);
  try
    try
      LoadFromStream(Stream);
    except
      // a damaged cache file is ignored, the messages are read from the database
      Clear;
    end;
  finally
    Stream.Free;
  end;
end;

// Version 1: texts in the system code page, one MaxVersion for all databases;
// 2: texts in UTF-8, MaxVersion per database. The loaded databases are validated again.
procedure TFIBErrorMessageCache.LoadFromStream(Stream: TStream);
var
  StreamVersion, MaxVersion, Version, DBCount, MsgCount, i, j: Integer;
  Signature: AnsiString;
  UTF8: Boolean;
  Messages: TFIBDatabaseErrorMessages;
  ErrorName: string;
begin
  Stream.Position := 0;
  Stream.ReadBuffer(StreamVersion, SizeOf(Integer));
  if (StreamVersion < 1) or (StreamVersion > ErrCurStreamVersion) then
    Exit;
  ReadStrFromStream(Stream, Signature);
  if Signature <> ErrSignature then
    Exit;
  UTF8 := StreamVersion >= 2;
  MaxVersion := 0;
  if StreamVersion = 1 then
    Stream.ReadBuffer(MaxVersion, SizeOf(Integer));
  FLock.BeginWrite;
  try
    FDatabases.Clear;
    Stream.ReadBuffer(DBCount, SizeOf(Integer));
    for i := 0 to DBCount - 1 do
    begin
      Messages := TFIBDatabaseErrorMessages(DatabaseMessages(ReadUTF8StrFromStream(Stream, UTF8), True));
      if StreamVersion >= 2 then
        Stream.ReadBuffer(MaxVersion, SizeOf(Integer));
      Messages.FMaxVersion := MaxVersion;
      Stream.ReadBuffer(MsgCount, SizeOf(Integer));
      for j := 0 to MsgCount - 1 do
      begin
        Stream.ReadBuffer(Version, SizeOf(Integer));
        ErrorName := ReadUTF8StrFromStream(Stream, UTF8);
        Messages.AddMessage(ErrorName, ReadUTF8StrFromStream(Stream, UTF8), Version);
      end;
    end;
  finally
    FLock.EndWrite;
  end;
end;

procedure TFIBErrorMessageCache.SaveToFile(const FileName: string);
begin
  SaveCacheFile(FileName, FDatabases.Count > 0, SaveToStream);
end;

procedure TFIBErrorMessageCache.SaveToStream(Stream: TStream);
var
  Value, i, j: Integer;
  Messages: TFIBDatabaseErrorMessages;
  Msg: TFIBErrorMessage;
begin
  FLock.BeginRead;
  try
    Value := ErrCurStreamVersion;
    Stream.WriteBuffer(Value, SizeOf(Integer));
    WriteStrToStream(ErrSignature, Stream);
    Value := FDatabases.Count;
    Stream.WriteBuffer(Value, SizeOf(Integer));
    for i := 0 to FDatabases.Count - 1 do
    begin
      Messages := TFIBDatabaseErrorMessages(FDatabases.Objects[i]);
      WriteUTF8StrToStream(FDatabases[i], Stream);
      Stream.WriteBuffer(Messages.FMaxVersion, SizeOf(Integer));
      Value := Messages.Count;
      Stream.WriteBuffer(Value, SizeOf(Integer));
      for j := 0 to Messages.Count - 1 do
      begin
        Msg := TFIBErrorMessage(Messages.Objects[j]);
        Stream.WriteBuffer(Msg.FVersion, SizeOf(Integer));
        WriteUTF8StrToStream(Messages[j], Stream);
        WriteUTF8StrToStream(Msg.FErrorMsg, Stream);
      end;
    end;
  finally
    FLock.EndRead;
  end;
end;

procedure TFIBDataSetInfo.LoadFromStream(Stream: TStream);
var
  UTF8: Boolean;
begin
  FDBName := ReadUTF8StrFromStream(Stream, FStreamVersion >= 2);
  Stream.ReadBuffer(FVersion, SizeOf(Integer));
  UTF8 := FStreamVersion >= 3;
  FSelectSQL.Text := ReadUTF8StrFromStream(Stream, UTF8);
  FInsertSQL.Text := ReadUTF8StrFromStream(Stream, UTF8);
  FUpdateSQL.Text := ReadUTF8StrFromStream(Stream, UTF8);
  FDeleteSQL.Text := ReadUTF8StrFromStream(Stream, UTF8);
  FRefreshSQL.Text := ReadUTF8StrFromStream(Stream, UTF8);
  FKeyField := ReadUTF8StrFromStream(Stream, UTF8);
  FGeneratorName := ReadUTF8StrFromStream(Stream, UTF8);
  FDescription := ReadUTF8StrFromStream(Stream, UTF8);
  FUpdateTableName := ReadUTF8StrFromStream(Stream, UTF8);
  FConditions := ReadUTF8StrFromStream(Stream, UTF8);
  Stream.ReadBuffer(FUpdateOnlyModifiedFields, SizeOf(Boolean));
  FNonValidated := True;
end;

procedure TFIBDataSetInfo.SaveToStream(Stream: TStream);
begin
  WriteUTF8StrToStream(FDBName, Stream);
  Stream.WriteBuffer(FVersion, SizeOf(Integer));
  WriteUTF8StrToStream(FSelectSQL.Text, Stream);
  WriteUTF8StrToStream(FInsertSQL.Text, Stream);
  WriteUTF8StrToStream(FUpdateSQL.Text, Stream);
  WriteUTF8StrToStream(FDeleteSQL.Text, Stream);
  WriteUTF8StrToStream(FRefreshSQL.Text, Stream);
  WriteUTF8StrToStream(FKeyField, Stream);
  WriteUTF8StrToStream(FGeneratorName, Stream);
  WriteUTF8StrToStream(FDescription, Stream);
  WriteUTF8StrToStream(FUpdateTableName, Stream);
  WriteUTF8StrToStream(FConditions, Stream);
  Stream.WriteBuffer(FUpdateOnlyModifiedFields, SizeOf(Boolean));
end;

procedure TFIBDataSetInfoCache.LoadFromStream(Stream: TStream);
var
  i, c: Integer;
  StreamVersion: Integer;
  tn: AnsiString;
  DI: TFIBDataSetInfo;
begin
  Clear;
  with Stream do
  begin
    Seek(0, soFromBeginning);
    SetLength(tn, Length(DSSignature));
    ReadBuffer(tn[1], Length(DSSignature)); // Signature
    if tn <> DSSignature then
    begin
      Seek(0, soFromBeginning);
      ReadStrFromStream(Stream, tn);
    end;
    if tn <> DSSignature then
      Exit;
    ReadBuffer(StreamVersion, SizeOf(Integer));
    if (StreamVersion < 1) or (StreamVersion > DSCurStreamVersion) then
      Exit;
    ReadBuffer(c, SizeOf(Integer));
    for i := 0 to Pred(c) do
    begin
      ReadStrFromStream(Stream, tn);
      DI := TFIBDataSetInfo.Create;
      try
        DI.FStreamVersion := StreamVersion;
        DI.LoadFromStream(Stream);
      except
        DI.Free;
        raise;
      end;
      FListDataSetInfo.AddObject(string(tn), DI)
    end;
  end;
end;

procedure TFIBDataSetInfoCache.SaveToStream(Stream: TStream);
var
  i, c: Integer;
begin
  FLock.Acquire;
  with Stream do
    try
      Seek(0, soFromBeginning);
      WriteStrToStream(DSSignature, Stream);
      c := DSCurStreamVersion;
      WriteBuffer(c, SizeOf(Integer));
      c := FListDataSetInfo.Count;
      WriteBuffer(c, SizeOf(Integer));
      for i := 0 to Pred(c) do
      begin
        // the key is the DataSet_ID
        WriteStrToStream(AnsiString(FListDataSetInfo[i]), Stream);
        TFIBDataSetInfo(FListDataSetInfo.Objects[i]).SaveToStream(Stream);
      end;
    finally
      FLock.Release;
    end;
end;

function TFIBDataSetInfoCache.LoadFromFile(const FileName: string): Boolean;
var
  Stream: TFileStream;
begin
  FLock.Acquire;
  try
    Clear;
    Result := FileExists(FileName);
    if not Result then
      Exit;
    Stream := TFileStream.Create(FileName, fmOpenRead);
    try
      try
        LoadFromStream(Stream);
      except
        // a damaged cache file is ignored, the infos are read from the database
        Clear;
        Result := False;
      end;
    finally
      Stream.Free;
    end;
  finally
    FLock.Release;
  end;
end;

procedure TFIBDataSetInfoCache.SaveToFile(const FileName: string);
begin
  SaveCacheFile(FileName, FListDataSetInfo.Count > 0, SaveToStream);
end;

initialization

LockRepList := TCriticalSection.Create;
TableInfoCache := TFIBTableInfoCache.Create(nil);
DataSetInfoCache := TFIBDataSetInfoCache.Create;
DatabaseRepositories := TStringList.Create;
FailedUpgrades := TFailedUpgrades.Create(nil);
StoredProcInfoCache := TFIBStoredProcMetadataCache.Create;
ErrorMessageCache := TFIBErrorMessageCache.Create;

finalization

ErrorMessageCache.Free;
// before the lists they update on the notification of a database
TableInfoCache.Free;
FailedUpgrades.Free;
DatabaseRepositories.Free;
DataSetInfoCache.Free;
StoredProcInfoCache.Free;
LockRepList.Free;

end.
