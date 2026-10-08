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

unit pFIBDatabase;

interface

{$I FIBPlus.inc}

uses
  SysUtils, Classes, DB, ibase, IB_Intf, ib_externals, fib, FIBDatabase,
  FIBDataSet,
  FIBQuery, pFIBProps, StdFuncs, FIBPlatforms, Variants;

type

  TFIBLoginEvent = procedure(Database: TFIBDatabase; LoginParams: TStrings; var DoConnect: boolean) of object;

  TpFIBAcceptCacheSchema = procedure(const ObjName: string; var Accept: boolean) of object;

  TOnLostConnectActions = (laTerminateApp, laCloseConnect, laIgnore, laWaitRestore);
  TFIBLostConnectEvent = procedure(Database: TFIBDatabase; E: EFIBError;
    var Actions: TOnLostConnectActions; var DoRaise: boolean) of object;

  TFIBRestoreConnectEvent = procedure(Database: TFIBDatabase) of object;

  TpFIBDatabase = class(TFIBDatabase)
  private
    FRestoreConnectTimer: TFIBTimer;
    FWaitForRestoreConnect: Cardinal;
    FAliasName: Ansistring;
    FRewriteAlias: boolean;
    FBeforeConnect: TFIBLoginEvent;
    FOnLostConnect: TFIBLostConnectEvent;
    FOnErrorRestoreConnect: TFIBLostConnectEvent;
    FAfterRestoreConnect: TFIBRestoreConnectEvent;
    FBeforeStartTr: TNotifyEvent;
    FAfterStartTr: TNotifyEvent;
    FBeforeEndTr: TEndTrEvent;
    FAfterEndTr: TEndTrEvent;
    FCacheSchemaOptions: TCacheSchemaOptions;
    FOnAcceptCacheSchema: TpFIBAcceptCacheSchema;
    procedure SetAliasName(const Value: Ansistring);
    procedure SetWaitForRestoreConnect(Value: Cardinal);
    function GetFIBDataSet(Index: integer): TFIBCustomDataSet;
    function GetFIBQuery(Index: integer): TFIBQuery;
    function GetFIBVersion: string;
    procedure SetFIBVersion(const vs: string);
    function GetInRestoreConnect: boolean;
  protected
    procedure InternalClose(Force: boolean; DBinShutDown: boolean); override;
    procedure CloseLostConnect;
    procedure DoOnLostConnect(Database: TFIBDatabase; E: EFIBError; var Actions: TOnLostConnectActions; var DoRaise: boolean); dynamic;
    procedure DoOnErrorRestoreConnect(Database: TFIBDatabase; E: EFIBError; var Actions: TOnLostConnectActions); dynamic;
    procedure DoAfterRestoreConnect; dynamic;
    function GetAfterConnect: TNotifyEvent;
    procedure SetAfterConnect(Method: TNotifyEvent);
    procedure CreateRestoreConnectTimer;

    procedure ReadSaveDBParams(Reader: TReader);
    procedure DefineProperties(Filer: TFiler); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function ReadParamsFromAlias: boolean; dynamic;
    procedure SaveAlias; override;
    procedure Open(RaiseExcept: boolean = True); override;
    function ExTestConnected(Actions: TOnLostConnectActions): boolean;
    procedure WaitRestoreConnect;
    procedure StopWaitRestoreConnect;
    procedure RestoreConnect(Sender: TObject);
    procedure GetTableNames(TableNames: TStrings; WithSystem: boolean);
    procedure GetFieldNames(const TableName: string; FieldNames: TStrings; WithComputedFields: boolean = True);
    procedure ApplyUpdates(const DataSets: array of TDataSet);

    procedure ForceCloseTransactions;
    procedure CloseDataSets;
    function FIBQueryCount: integer;
    function FIBDataSetsCount: integer;
    property FIBDataSets[Index: integer]: TFIBCustomDataSet read GetFIBDataSet;
    property FIBQueries[Index: integer]: TFIBQuery read GetFIBQuery;
    property SaveDBParams: boolean read FRewriteAlias write FRewriteAlias default True;
    property InRestoreConnect: boolean read GetInRestoreConnect;

  published
    property CacheSchemaOptions: TCacheSchemaOptions read FCacheSchemaOptions write FCacheSchemaOptions;
    property AliasName: Ansistring read FAliasName write SetAliasName;
    property WaitForRestoreConnect: Cardinal read FWaitForRestoreConnect write SetWaitForRestoreConnect default 30000;
    property SaveAliasParamsAfterConnect: boolean read FRewriteAlias write FRewriteAlias default True;
    property BeforeConnect: TFIBLoginEvent read FBeforeConnect write FBeforeConnect;
    property AfterConnect: TNotifyEvent read GetAfterConnect write SetAfterConnect;
    property OnLostConnect: TFIBLostConnectEvent read FOnLostConnect write FOnLostConnect;
    property OnErrorRestoreConnect: TFIBLostConnectEvent read FOnErrorRestoreConnect write FOnErrorRestoreConnect;
    property AfterRestoreConnect: TFIBRestoreConnectEvent read FAfterRestoreConnect write FAfterRestoreConnect;
    property BeforeStartTransaction: TNotifyEvent read FBeforeStartTr write FBeforeStartTr;
    property AfterStartTransaction: TNotifyEvent read FAfterStartTr write FAfterStartTr;
    property BeforeEndTransaction: TEndTrEvent read FBeforeEndTr write FBeforeEndTr;
    property AfterEndTransaction: TEndTrEvent read FAfterEndTr write FAfterEndTr;
    property About: string read GetFIBVersion write SetFIBVersion stored False;
    property OnLogin: TFIBLoginEvent read FBeforeConnect write FBeforeConnect stored False; // obsolete    //
    property OnAcceptCacheSchema: TpFIBAcceptCacheSchema read FOnAcceptCacheSchema write FOnAcceptCacheSchema;
  end;

  TOnSQLExecute = procedure(Query: TFIBQuery; SQLType: TFIBSQLTypes) of object;

  TpFIBTransaction = class(TFIBTransaction)
  private
    FTPBMode: TTPBMode;
    FBeforeStart: TNotifyEvent;
    FAfterStart: TNotifyEvent;
    FBeforeEnd: TEndTrEvent;
    FAfterEnd: TEndTrEvent;
    FBeforeSQLExecute: TOnSQLExecute;
    FAfterSQLExecute: TOnSQLExecute;
    FAfterFirstFetch: TOnSQLExecute;
    FUserKindTransaction: string;
    function StoreTRParams: boolean;
    function StoreUKTR: boolean;
    procedure SetUserKindTransaction(const Value: string);
    function GetFIBDataSet(Index: integer): TFIBCustomDataSet;
    function GetFIBQuery(Index: integer): TFIBQuery;
    function GetFIBVersion: string;
    procedure SetFIBVersion(const Value: string);
  protected
    procedure EndTransaction(Action: TTransactionAction; Force: boolean); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure DoOnSQLExec(Query: TComponent; Kind: TKindOnOperation); override;
    procedure StartTransaction; override;
    function FIBQueryCount: integer;
    function FIBDataSetsCount: integer;
    property FIBDataSets[Index: integer]: TFIBCustomDataSet read GetFIBDataSet;
    property FIBQueries[Index: integer]: TFIBQuery read GetFIBQuery;
  published
    property BeforeStart: TNotifyEvent read FBeforeStart write FBeforeStart;
    property AfterStart: TNotifyEvent read FAfterStart write FAfterStart;
    property BeforeEnd: TEndTrEvent read FBeforeEnd write FBeforeEnd;
    property AfterEnd: TEndTrEvent read FAfterEnd write FAfterEnd;
    property TPBMode: TTPBMode read FTPBMode write FTPBMode default tpbReadCommitted;
    property TRParams stored StoreTRParams;
    property UserKindTransaction: string read FUserKindTransaction write SetUserKindTransaction stored StoreUKTR;
    property About: string read GetFIBVersion write SetFIBVersion stored False;
    property AfterSQLExecute: TOnSQLExecute read FAfterSQLExecute write FAfterSQLExecute;
    property BeforeSQLExecute: TOnSQLExecute read FBeforeSQLExecute write FBeforeSQLExecute;
    property AfterFirstFetch: TOnSQLExecute read FAfterFirstFetch write FAfterFirstFetch;
  end;

procedure WriteDBParamsToAlias(Database: TpFIBDatabase);

implementation

uses
{$IFNDEF NO_REGISTRY} RegUtils, {$ENDIF}
  StrUtil, pFIBCacheQueries, pFIBQuery, pFIBDataSet, pFIBDataInfo;

function GetQueriesCount(ForObj: TComponent): integer;
var
  i, bc: integer;
  CurB: TFIBBase;
  IncludedDS: TList;
begin
  Result := 0;
  if (ForObj is TFIBDatabase) then
    bc := TFIBDatabase(ForObj).FIBBaseCount - 1
  else
    bc := TFIBTransaction(ForObj).FIBBaseCount - 1;
  IncludedDS := TList.Create;
  with IncludedDS do
    try
      for i := 0 to bc do
      begin
        if (ForObj is TFIBDatabase) then
          CurB := TFIBDatabase(ForObj).FIBBases[i]
        else
          CurB := TFIBTransaction(ForObj).FIBBases[i];
        if (CurB.Owner = nil) or not(CurB.Owner is TFIBQuery) then
          Continue;
        if (TFIBQuery(CurB.Owner).Owner is TFIBCustomDataSet) then
          Continue;
        if IndexOf(TFIBQuery(CurB.Owner)) = -1 then
        begin
          Inc(Result);
          Add(TFIBQuery(CurB.Owner))
        end;
      end;
    finally
      Free
    end;
end;

function DoGetQuery(ForObj: TComponent; Index: integer): TFIBQuery;
var
  i, j, bc: integer;
  CurB: TFIBBase;
  IncludedDS: TList;
begin
  Result := nil;
  if Index < 0 then
    Exit;
  if (ForObj is TFIBDatabase) then
    bc := TFIBDatabase(ForObj).FIBBaseCount - 1
  else
    bc := TFIBTransaction(ForObj).FIBBaseCount - 1;

  IncludedDS := TList.Create;
  with IncludedDS do
    try
      j := 0;
      for i := 0 to bc do
      begin
        if (ForObj is TFIBDatabase) then
          CurB := TFIBDatabase(ForObj).FIBBases[i]
        else
          CurB := TFIBTransaction(ForObj).FIBBases[i];

        if (CurB.Owner = nil) or not(CurB.Owner is TFIBQuery) then
          Continue;
        if (TFIBQuery(CurB.Owner).Owner is TFIBCustomDataSet) then
          Continue;
        if IndexOf(TFIBQuery(CurB.Owner)) = -1 then
        begin
          if j = Index then
          begin
            Result := TFIBQuery(CurB.Owner);
            Exit;
          end;
          Inc(j);
          Add(TFIBQuery(CurB.Owner));
        end;
      end;
    finally
      Free;
    end;
end;

function GetDataSetsCount(ForObj: TComponent): integer;
var
  i, bc: integer;
  CurB: TFIBBase;
  IncludedDS: TList;
begin
  Result := 0;
  if (ForObj is TFIBDatabase) then
    bc := TFIBDatabase(ForObj).FIBBaseCount - 1
  else
    bc := TFIBTransaction(ForObj).FIBBaseCount - 1;
  IncludedDS := TList.Create;
  with IncludedDS do
    try
      for i := 0 to bc do
      begin
        if (ForObj is TFIBDatabase) then
          CurB := TFIBDatabase(ForObj).FIBBases[i]
        else
          CurB := TFIBTransaction(ForObj).FIBBases[i];
        if (CurB = nil) or (CurB.Owner = nil) or not(CurB.Owner is TFIBQuery) then
          Continue;
        if not(TFIBQuery(CurB.Owner).Owner is TFIBCustomDataSet) then
          Continue;
        if IndexOf(TFIBQuery(CurB.Owner).Owner) = -1 then
        begin
          Inc(Result);
          Add(TFIBQuery(CurB.Owner).Owner)
        end;
      end;
    finally
      Free
    end;
end;

function DoGetDataSet(ForObj: TComponent; Index: integer): TFIBCustomDataSet;
var
  i, j, bc: integer;
  CurB: TFIBBase;
  IncludedDS: TList;
begin
  Result := nil;
  if Index < 0 then
    Exit;
  if (ForObj is TFIBDatabase) then
    bc := TFIBDatabase(ForObj).FIBBaseCount - 1
  else
    bc := TFIBTransaction(ForObj).FIBBaseCount - 1;

  IncludedDS := TList.Create;
  with IncludedDS do
    try
      j := 0;
      for i := 0 to bc do
      begin
        if (ForObj is TFIBDatabase) then
          CurB := TFIBDatabase(ForObj).FIBBases[i]
        else
          CurB := TFIBTransaction(ForObj).FIBBases[i];

        if (CurB.Owner = nil) or not(CurB.Owner is TFIBQuery) then
          Continue;
        if not(TFIBQuery(CurB.Owner).Owner is TFIBCustomDataSet) then
          Continue;
        if IndexOf(TFIBQuery(CurB.Owner).Owner) = -1 then
        begin
          if j = Index then
          begin
            Result := TFIBCustomDataSet(TFIBQuery(CurB.Owner).Owner);
            Exit;
          end;
          Inc(j);
          Add(TFIBQuery(CurB.Owner).Owner)
        end;
      end;
    finally
      Free
    end;
end;

constructor TpFIBDatabase.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRewriteAlias := True;
  FWaitForRestoreConnect := 30000;
  FCacheSchemaOptions := TCacheSchemaOptions.Create;
end;

destructor TpFIBDatabase.Destroy;
begin
  inherited Destroy;
  FCacheSchemaOptions.Free;
end;

procedure TpFIBDatabase.CreateRestoreConnectTimer;
begin
  if not Assigned(FRestoreConnectTimer) then
  begin
    FRestoreConnectTimer := TFIBTimer.Create(Self);
    FRestoreConnectTimer.Enabled := False;
    FRestoreConnectTimer.Interval := FWaitForRestoreConnect;
    FRestoreConnectTimer.OnTimer := RestoreConnect;
  end;
end;

function TpFIBDatabase.GetAfterConnect: TNotifyEvent;
begin
  Result := OnConnect
end;

procedure TpFIBDatabase.SetAfterConnect(Method: TNotifyEvent);
begin
  OnConnect := Method
end;

procedure TpFIBDatabase.SetAliasName(const Value: Ansistring);
begin
  if not(csLoading in ComponentState) then
    CheckInactive;
  FAliasName := Value;
  if FAliasName <> '' then
    ReadParamsFromAlias
end;

procedure TpFIBDatabase.SetWaitForRestoreConnect(Value: Cardinal);
begin
  FWaitForRestoreConnect := Value;
  if not Assigned(FRestoreConnectTimer) then
    Exit;
  if Value = 0 then
    StopWaitRestoreConnect
  else
    FRestoreConnectTimer.Interval := Value;
end;

// Alias Works
{$IFNDEF NO_REGISTRY}

function TpFIBDatabase.ReadParamsFromAlias: boolean; // dynamic;
var
  Values: Variant;
  i: integer;
begin
  Values := DefReadFromRegistry(['Software', RegFIBRoot, 'Aliases', FAliasName],
    ['Database Name', DPBConstantNames[isc_dpb_user_name],
    DPBConstantNames[isc_dpb_lc_ctype], DPBConstantNames[isc_dpb_sql_role_name], 'SQL_DIALECT', 'CLIENT_LIB']);
  Result := VarType(Values) <> varBoolean;
  if not Result then
    Exit; // Don't exist
  for i := 0 to 5 do
  begin
    if Values[1, i] then
      case i of
        0: DBName := Values[0, i];
        1: DBParamByDPB[isc_dpb_user_name] := Values[0, i];
        2: DBParamByDPB[isc_dpb_lc_ctype] := Values[0, i];
        3: DBParamByDPB[isc_dpb_sql_role_name] := Values[0, i];
        4: SQLDialect := Values[0, i];
        5: LibraryName := Values[0, i]
      end
    else if i = 0 then
      Result := False
  end;
end;

procedure WriteDBParamsToAlias(Database: TpFIBDatabase);
begin
  with Database do
    DefWriteToRegistry(['Software', RegFIBRoot, 'Aliases', AliasName],
      ['Database Name', DPBConstantNames[isc_dpb_user_name], DPBConstantNames[isc_dpb_lc_ctype],
      DPBConstantNames[isc_dpb_sql_role_name], 'SQL_DIALECT', 'CLIENT_LIB'],
      [DBName, DBParamByDPB[isc_dpb_user_name], DBParamByDPB[isc_dpb_lc_ctype],
      DBParamByDPB[isc_dpb_sql_role_name], IntToStr(SQLDialect), LibraryName]);
end;

{$ELSE}

function TpFIBDatabase.ReadParamsFromAlias: boolean; // dynamic;
begin
  Result := False;
end;

procedure WriteDBParamsToAlias(Database: TpFIBDatabase);
begin

end;
{$ENDIF}

procedure TpFIBDatabase.SaveAlias;
begin
  WriteDBParamsToAlias(Self)
end;

procedure TpFIBDatabase.ForceCloseTransactions;
var
  i: integer;
begin
  for i := 0 to FTransactions.Count - 1 do
  begin
    try
      if FTransactions[i] <> nil then
        Transactions[i].OnDatabaseDisconnecting(Self);
    except
    end;
  end;
end;

procedure TpFIBDatabase.Open(RaiseExcept: boolean = True);
var
  DoConnect: boolean;
begin
  if Connected then
    Exit;
  DoConnect := True;
  if Assigned(FBeforeConnect) then
    FBeforeConnect(Self, DBParams, DoConnect);
  if not DoConnect then
    Exit;
  inherited Open(RaiseExcept);
  if Connected then
  begin
    StopWaitRestoreConnect;
    if FCacheSchemaOptions.AutoLoadFromFile and not(csDesigning in ComponentState) and
      FileExists(FCacheSchemaOptions.LocalCacheFile) then
      if Assigned(FOnAcceptCacheSchema) and FCacheSchemaOptions.ValidateAfterLoad then
      begin
        if LoadSchemaFromFile(FCacheSchemaOptions.LocalCacheFile, True, Self) then
        begin
          ListTableInfo.ValidateSchema(Self, FOnAcceptCacheSchema);
          SaveSchemaToFile(FCacheSchemaOptions.LocalCacheFile);
        end
      end
      else
      begin
        LoadSchemaFromFile(FCacheSchemaOptions.LocalCacheFile, FCacheSchemaOptions.ValidateAfterLoad, Self);
      end;
    if FRewriteAlias and (FAliasName <> '') then
      SaveAlias;
  end;
end;

// Lost Connection works

procedure TpFIBDatabase.InternalClose(Force: boolean; DBinShutDown: boolean);
begin
  if not Connected then
    Exit;
  if FCacheSchemaOptions.AutoSaveToFile and not(csDesigning in ComponentState) then
    SaveSchemaToFile(FCacheSchemaOptions.LocalCacheFile);
  inherited InternalClose(Force, DBinShutDown);
end;

function TpFIBDatabase.ExTestConnected(Actions: TOnLostConnectActions): boolean;
var
  b: boolean;
begin
  Result := Connected;
  if Result then
  begin
    try
      BaseLevel;
    except
      on E: EFIBError do
      begin
        Result := False;
        b := False;
        DoOnLostConnect(Self, E, Actions, b);
        if b then
          raise
      end
    end;
  end;
end;

procedure TpFIBDatabase.DoOnLostConnect(Database: TFIBDatabase; E: EFIBError; var Actions: TOnLostConnectActions; var DoRaise: boolean);
begin
  if Assigned(FOnLostConnect) then
    FOnLostConnect(Self, E, Actions, DoRaise);
  if Actions = laTerminateApp then
  begin
    CloseLostConnect;
    if CallTerminateProcs then
      TerminateApplication;
    // PostQuitMessage(0); //  Application.Terminate
  end;
  if Actions in [laCloseConnect, laWaitRestore] then
    CloseLostConnect;
  if Actions = laWaitRestore then
    WaitRestoreConnect;
end;

procedure TpFIBDatabase.DoOnErrorRestoreConnect(Database: TFIBDatabase; E: EFIBError; var Actions: TOnLostConnectActions); // dynamic;
var
  DoRaise: boolean;
begin
  DoRaise := False;
  if Assigned(FOnErrorRestoreConnect) then
    FOnErrorRestoreConnect(Self, E, Actions, DoRaise);
end;

procedure TpFIBDatabase.DoAfterRestoreConnect; // dynamic;
begin
  if Assigned(FAfterRestoreConnect) then
    FAfterRestoreConnect(Self);
end;

procedure TpFIBDatabase.CloseLostConnect;
begin
  // closed already or being closed
  if not Connected or (drsInCloseLostConnect in FDatabaseRunState) then
    Exit;
  Include(FDatabaseRunState, drsInCloseLostConnect);
  try
    // Let's avoid of calls IB Api
    FHandle := nil;
    AbandonServerHandles;
  finally
    Exclude(FDatabaseRunState, drsInCloseLostConnect);
  end;
end;

procedure TpFIBDatabase.RestoreConnect(Sender: TObject);
var
  Actions: TOnLostConnectActions;
  Restored: boolean;
begin
  if Connected then
  begin
    StopWaitRestoreConnect;
    Exit;
  end;
  if Assigned(FRestoreConnectTimer) and FRestoreConnectTimer.Enabled then
  begin
    FRestoreConnectTimer.Enabled := False;
    Actions := laWaitRestore
  end
  else
    Actions := laIgnore;
  Restored := False;
  Include(FDatabaseRunState, drsInRestoreLostConnect);
  try
    try
      Connected := True;
      // BeforeConnect can cancel the connect without an error
      Restored := Connected;
    except
      on E: EFIBError do
        DoOnErrorRestoreConnect(Self, E, Actions);
    end;
  finally
    Exclude(FDatabaseRunState, drsInRestoreLostConnect);
  end;
  if Restored then
    DoAfterRestoreConnect
  else
    case Actions of
      laWaitRestore:
        WaitRestoreConnect;
    else
      // OnLostConnect may have restarted the timer during the attempt
      StopWaitRestoreConnect;
      if (Actions = laTerminateApp) and CallTerminateProcs then
        TerminateApplication;
    end;
end;

procedure TpFIBDatabase.WaitRestoreConnect;
begin
  if FWaitForRestoreConnect = 0 then
    Exit;
  CreateRestoreConnectTimer;
  Include(FDatabaseRunState, drsInRestoreLostConnect);
  FRestoreConnectTimer.Enabled := True;
end;

procedure TpFIBDatabase.StopWaitRestoreConnect;
begin
  Exclude(FDatabaseRunState, drsInRestoreLostConnect);
  if Assigned(FRestoreConnectTimer) then
    FRestoreConnectTimer.Enabled := False;
end;

function TpFIBDatabase.GetFIBDataSet(Index: integer): TFIBCustomDataSet;
begin
  Result := DoGetDataSet(Self, Index)
end;

function TpFIBDatabase.FIBDataSetsCount: integer;
begin
  Result := GetDataSetsCount(Self)
end;

procedure TpFIBDatabase.GetTableNames(TableNames: TStrings; WithSystem: boolean);
const
  TablesSQL = 'Select RDB$RELATION_NAME from RDB$RELATIONS ' +
    'where RDB$VIEW_BLR is NULL @SYS ' + 'ORDER BY RDB$RELATION_NAME';
var
  qry: TFIBQuery;
begin
  CheckActive;
  qry := GetQueryForUse(FInternalTransaction, TablesSQL);
  TableNames.Clear;
  with qry do
    try
      Close;
      Options := [qoStartTransaction, qoTrimCharFields];
      TableNames.BeginUpdate;
      if not WithSystem then
        Params[0].asString := 'and RDB$SYSTEM_FLAG = 0'
      else
        Params[0].asString := '';
      ExecQuery;
      while not Eof do
      begin
        TableNames.Add(Fields[0].asString);
        Next;
      end;
    finally
      if FInternalTransaction.Active then
        FInternalTransaction.Commit;
      TableNames.EndUpdate;
      qry.FreeHandle;
      FreeQueryForUse(qry);
    end;
end;

procedure TpFIBDatabase.GetFieldNames(const TableName: string; FieldNames: TStrings; WithComputedFields: boolean = True);
const
  cFieldsSQL = 'Select RDB$FIELD_NAME  from RDB$RELATION_FIELDS R ' +
    'where R.RDB$RELATION_NAME = :TN ORDER BY R.RDB$FIELD_POSITION ';

  cFieldsSQL1 = 'Select R.RDB$FIELD_NAME  from  RDB$RELATION_FIELDS R ' +
    'join rdb$fields R2 on (R.RDB$FIELD_SOURCE = R2.RDB$FIELD_NAME) ' +
    'where R.RDB$RELATION_NAME = :TN AND R2.RDB$COMPUTED_SOURCE IS NULL ORDER BY R.RDB$FIELD_POSITION';

var
  qry: TFIBQuery;
  FieldsSQL: string;
begin
  CheckActive;
  if WithComputedFields then
    FieldsSQL := cFieldsSQL
  else
    FieldsSQL := cFieldsSQL1;

  qry := GetQueryForUse(FInternalTransaction, FieldsSQL);
  FieldNames.Clear;
  with qry do
    try
      Close;
      Options := [qoStartTransaction, qoTrimCharFields];
      FieldNames.BeginUpdate;
      if SQLDialect = 1 then
        Params[0].asString := UpperCase(TableName)
      else
        Params[0].asString := TableName;

      // Params[0].asString:=FormatIdentifier(SQLDialect, TableName);
      ExecQuery;
      while not Eof do
      begin
        FieldNames.Add(Fields[0].asString);
        Next;
      end;
    finally
      if FInternalTransaction.Active then
        FInternalTransaction.Commit;
      FieldNames.EndUpdate;
      qry.FreeHandle;
      FreeQueryForUse(qry);
    end;
end;

procedure TpFIBDatabase.CloseDataSets;
var
  Index: integer;
begin
  for Index := Pred(FFIBBases.Count) downto 0 do
    if FIBBases[Index] <> nil then
      if (FIBBases[Index].Owner is TFIBDataSet) then
        TFIBDataSet(FIBBases[Index].Owner).Close;
end;

function TpFIBDatabase.FIBQueryCount: integer;
begin
  Result := GetQueriesCount(Self);
end;

function TpFIBDatabase.GetFIBQuery(Index: integer): TFIBQuery;
begin
  Result := DoGetQuery(Self, Index);
end;

procedure TpFIBDatabase.ApplyUpdates(const DataSets: array of TDataSet);
var
  i: integer;
  DS: TFIBCustomDataSet;
  TR: TFIBTransaction;
begin
  if Length(DataSets) = 0 then
    Exit;
  TR := nil;
  for i := 0 to High(DataSets) do
  begin
    if not (DataSets[i] is TFIBCustomDataSet) then
      FIBError(feUpdateWrongDB, [CmpFullName(DataSets[i])]);
    DS := TFIBCustomDataSet(DataSets[i]);
    if DS.Database <> Self then
      FIBError(feUpdateWrongDB, [CmpFullName(DS)]);
    if i = 0 then
      TR := DS.UpdateTransaction;
    if (TR = nil) or (DS.UpdateTransaction <> TR) then
      FIBError(feUpdateWrongTR, [CmpFullName(DS)]);
  end;
  TR.CheckInTransaction;
  for i := 0 to High(DataSets) do
    if DataSets[i] is TpFIBDataSet then
      TpFIBDataSet(DataSets[i]).ApplyUpdToBase;
  if TR.TimeoutAction = TACommitRetaining then
    TR.CommitRetaining
  else
    TR.Commit;
  for i := 0 to High(DataSets) do
    if (DataSets[i] is TpFIBDataSet) and (DataSets[i].Active) then
      TpFIBDataSet(DataSets[i]).CommitUpdToCach;
end;

function TpFIBDatabase.GetFIBVersion: string;
begin
  Result := FIBVersionString;
end;

procedure TpFIBDatabase.SetFIBVersion(const vs: string);
begin

end;

procedure TpFIBDatabase.ReadSaveDBParams(Reader: TReader);
begin
  SaveAliasParamsAfterConnect := Reader.ReadBoolean;
end;

procedure TpFIBDatabase.DefineProperties(Filer: TFiler);
begin
  inherited;
  if Filer is TReader then
  begin
    // For oldest dfm
    Filer.DefineProperty('SaveDBParams', ReadSaveDBParams, nil, False);
  end;
end;

/// TpFIBTransaction

constructor TpFIBTransaction.Create(AOwner: TComponent); // override;
begin
  inherited Create(AOwner);
  if (csDesigning in ComponentState) and ((Owner <> nil) and not(csLoading in Owner.ComponentState)) then
    FTPBMode := DefTPBMode
  else
    FTPBMode := tpbReadCommitted;
  FUserKindTransaction := 'NoUserKind';
end;

procedure TpFIBTransaction.StartTransaction; // override;
var
  I: Integer;
begin
  if InTransaction then
    Exit;
  if FTPBMode = tpbReadConsistency then
    for I := 0 to DatabaseCount - 1 do
      if Databases[I].Connected then
        Databases[I].RequireReadConsistency('TPBMode tpbReadConsistency');
  with TRParams do
    if FTPBMode in [tpbReadCommitted, tpbRepeatableRead, tpbReadConsistency] then
    begin
      Clear;
      Add('write');
      Add('isc_tpb_nowait');
      case FTPBMode of
        tpbReadCommitted:
          begin
            Add('read_committed');
            Add('rec_version');
          end;
        tpbRepeatableRead: Add('concurrency');
        tpbReadConsistency:
          begin
            Add('read_committed');
            Add('read_consistency');
          end;
      end
    end;
  if (DefaultDataBase is TpFIBDatabase) and Assigned(TpFIBDatabase(DefaultDataBase).FBeforeStartTr) then
    TpFIBDatabase(DefaultDataBase).FBeforeStartTr(Self);
  if Assigned(FBeforeStart) then
    FBeforeStart(Self);

  inherited StartTransaction;

  if Assigned(FAfterStart) then
    FAfterStart(Self);
  if (DefaultDataBase is TpFIBDatabase) and Assigned(TpFIBDatabase(DefaultDataBase).FAfterStartTr) then
    TpFIBDatabase(DefaultDataBase).FAfterStartTr(Self);
end;

procedure TpFIBTransaction.EndTransaction(Action: TTransactionAction; Force: boolean); // override;
begin
  if (DefaultDataBase is TpFIBDatabase) and Assigned(TpFIBDatabase(DefaultDataBase).FBeforeEndTr) then
    TpFIBDatabase(DefaultDataBase).FBeforeEndTr(Self, Action, Force);
  if Assigned(FBeforeEnd) then
    FBeforeEnd(Self, Action, Force);
  inherited EndTransaction(Action, Force);
  if Assigned(FAfterEnd) then
    FAfterEnd(Self, Action, Force);
  if (DefaultDataBase is TpFIBDatabase) and Assigned(TpFIBDatabase(DefaultDataBase).FAfterEndTr) then
    TpFIBDatabase(DefaultDataBase).FAfterEndTr(Self, Action, Force);
end;

function TpFIBTransaction.StoreTRParams: boolean;
begin
  Result := FTPBMode = tpbDefault
end;

function TpFIBTransaction.FIBDataSetsCount: integer;
begin
  Result := GetDataSetsCount(Self)
end;

function TpFIBTransaction.FIBQueryCount: integer;
begin
  Result := GetQueriesCount(Self);
end;

function TpFIBTransaction.GetFIBDataSet(Index: integer): TFIBCustomDataSet;
begin
  Result := DoGetDataSet(Self, Index)
end;

function TpFIBTransaction.GetFIBQuery(Index: integer): TFIBQuery;
begin
  Result := DoGetQuery(Self, Index);
end;

procedure TpFIBTransaction.SetUserKindTransaction(const Value: string);
{$IFNDEF NO_REGISTRY}
var
  RegName: string;
  v: Variant;
{$ENDIF}
begin
{$IFNDEF NO_REGISTRY}
  FUserKindTransaction := Value;
  if (csLoading in ComponentState) or not(csDesigning in ComponentState) or (FUserKindTransaction = 'NoUserKind') then
    Exit;
  RegName := GetKeyForParValue('Software\' + RegFIBRoot + '\' + RegFIBTrKinds, 'Name', FUserKindTransaction);
  if RegName = '' then
    Exit;
  v := DefReadFromRegistry(['Software', RegFIBRoot, RegFIBTrKinds, RegName], ['Params']);
  if VarType(v) = varBoolean then
    Exit;
  FTPBMode := tpbDefault;
  TRParams.Text := v[0, 0]
{$ENDIF}
end;

function TpFIBTransaction.StoreUKTR: boolean;
begin
  Result := FUserKindTransaction <> 'NoUserKind'
end;

function TpFIBTransaction.GetFIBVersion: string;
begin
  Result := FIBVersionString;
end;

procedure TpFIBTransaction.SetFIBVersion(const Value: string);
begin

end;

procedure TpFIBTransaction.DoOnSQLExec(Query: TComponent; Kind: TKindOnOperation);
begin
  inherited DoOnSQLExec(Query, Kind);
  case Kind of
    koBefore:
      if Assigned(FBeforeSQLExecute) then
        FBeforeSQLExecute(TFIBQuery(Query), TFIBQuery(Query).SQLType);
    koAfter:
      if Assigned(FAfterSQLExecute) then
        FAfterSQLExecute(TFIBQuery(Query), TFIBQuery(Query).SQLType);
    koAfterFirstFetch:
      if Assigned(FAfterFirstFetch) then
        FAfterFirstFetch(TFIBQuery(Query), TFIBQuery(Query).SQLType);
  end;
end;

function TpFIBDatabase.GetInRestoreConnect: boolean;
begin
  Result := drsInRestoreLostConnect in FDatabaseRunState
end;

end.
