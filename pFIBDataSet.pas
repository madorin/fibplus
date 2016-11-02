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

unit pFIBDataSet;

interface
{$I FIBPlus.inc}

uses
  SysUtils, Classes, StdFuncs, DB, Ibase, IB_Intf, IB_Externals,
  FIBPlatforms, Fib, FIBMiscellaneous, pFIBDatabase,  FIBDataBase, FIBDataSet, FIBQuery,
  pFIBLists,  pFIBQuery, DSContainer, pFIBProps, IB_ErrorCodes, pFIBInterfaces,
  pFIBDataInfo {, FIBSaveDataSetToXml }{$IFDEF D6+},FMTBcd, Variants {$ENDIF}  ;





type

  TLockStatus = (lsSuccess, lsDeadLock, lsNotExist, lsMultiply, lsUnknownError);
  TLockErrorEvent =
    procedure(DataSet: TDataSet; LockError: TLockStatus;
    var ErrorMessage: string; var Action: TDataAction) of object;

  TCachRefreshKind = (frkEdit, frkInsert);
  TOnGetSQLTextProc = procedure(DataSet: TFIBDataSet; var SQLText: string) of object;

(* For generate SQL text*)
  TIncludeFieldsToSQL=(ifsAllFields,ifsNoBlob,ifsOnlyBlob);
(* ********************)

  TpFIBDataSet = class(TFIBDataSet)
  private
    vQryRecordCount: TFIBQuery;
    vLockQry: TFIBQuery;
    FDataSet_ID: integer;
    FLoadedDataSet_ID: integer;
    FDefaultFormats: TFormatFields;
    FOnLockError: TLockErrorEvent;
    vUserOnPostError: TDataSetErrorEvent;
    vUserOnDeleteError: TDataSetErrorEvent;
    FOnLockSQLText    :TOnGetSQLTextProc;
    // lists of UpdateObjects
    vUpdates: TList;
    vDeletes: TList;
    vInserts: TList;


    FReceiveEvents: TStrings;
{$IFDEF USE_DEPRECATE_METHODS2}
    FOnUserEvent: TUserEvent;
{$ENDIF }

    FHaveUncommitedChanges: boolean;
    FHaveRollbackedChanges: boolean;

    FDescription: string;
    FOnAskRecordCount: TOnGetSQLTextProc;
    FOnApplyDefaultValue:TOnApplyDefaultValue;
    FSQLTextChanges: integer;
    FBlobsUpdate: TpFIBUpdateObject;
    FOnApplyFieldRepository:TOnApplyFieldRepository;
    FContainer: TDataSetsContainer;
    FDefaultsInited:boolean;
    FParamsForFields: array of TFIBXSQLVAR;
    FGeneratorBeUsed:boolean;

    FMidasCommandText:Widestring;
    FMidasOutParams: TParams;
    procedure SetContainer(Value: TDataSetsContainer);
{$IFDEF USE_DEPRECATE_METHODS2}
    procedure SetReceiveEvents(Value: TStrings);
{$ENDIF}
    //Property access procedures
    function  GetSelectSQL: TStrings;
    procedure SetSelectSQL(Value: TStrings);

    // UpdateObjects support
    function ListForUO(KindUpdate: TUpdateKind): TList;
    procedure SynchroOrdersUO(List: TList);

    //

    procedure SetDataSet_ID(Value: Integer);
    function GetFieldForTable(const Relation: string): TField;
    function WillGenerateSQLs: boolean;
    function  GetFIBVersion: string;
    procedure SetFIBVersion(const vs: string);

  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation);  override;
    function  GetVisibleRecno: Integer;
    procedure SetVisibleRecno(Value: Integer);
    function  GetRecNo: Integer; override;
    procedure SetRecNo(Value: Integer); override;
    procedure InternalPost; override;
    procedure InternalOpen ;override;
    procedure SetPrepareOptions(Value: TpPrepareOptions); override;
    procedure DoOnPostError(DataSet: TDataSet; E: DB.EDatabaseError; var Action:
      TDataAction); override;
    procedure DoOnDeleteError(DataSet: TDataSet; E: DB.EDatabaseError; var
      Action: TDataAction);

    function  CompareFieldValues(Field:TField;const S1,S2:variant):integer; override;
    //     IProviderSupport
  protected
//    FParams: TParams;



{$IFNDEF TWideDataSet}
    function PSGetTableName: string; override;
    function PSGetKeyFields: string; override;
    function PSGetQuoteChar: string; override;
    procedure PSSetCommandText(const CommandText: string); override;
{$ELSE}
    procedure PSSetCommandText(const CommandText: Widestring); override;
    function PSGetTableNameW: WideString; override;
    function PSGetKeyFieldsW: WideString; override;
    function PSGetQuoteCharW: Widestring; override;
    function PSGetCommandTextW: WideString;override;
{$ENDIF}
    function PSGetUpdateException(E: Exception; Prev: EUpdateError):
      EUpdateError; override;
    function PSInTransaction: Boolean; override;
    function PSIsSQLBased: Boolean; override;
    function PSIsSQLSupported: Boolean; override;
    procedure PSStartTransaction; override;
    procedure PSEndTransaction(Commit: Boolean); override;

    procedure PSReset; override;
    function PSUpdateRecord(UpdateKind: TUpdateKind; Delta: TDataSet): Boolean;
      override;
    function PSExecuteStatement(const ASQL: {$IFNDEF TWideDataSet} string{$ELSE} Widestring{$ENDIF}; AParams: TParams;
      ResultSet: Pointer = nil): Integer; override;
    procedure PSExecute; override;
    function PSGetParams: TParams; override;
    procedure PSSetParams(AParams: TParams); override;




    function IsVisible(Buffer: TRecordBuffer): Boolean; override;

    procedure InternalPostRecord(Qry: TFIBQuery; Buff: Pointer); override;
    procedure InternalDeleteRecord(Qry: TFIBQuery; Buff: Pointer); override;
    procedure AddedFilterRecord(DataSet: TDataSet; var Accept: Boolean);
      virtual;

    procedure InternalDoBeforeOpen; override;
    procedure DoBeforeOpen; override;
    procedure DoAfterOpen; override;
    procedure DoAfterClose; override;
    procedure DoBeforeInsert; override;
    procedure DoAfterInsert; override;
    procedure DoBeforeEdit; override;
    procedure DoBeforePost; override;
    procedure DoAfterPost; override;
    procedure DoBeforeCancel; override;
    procedure DoAfterCancel; override;
    procedure DoBeforeDelete; override;
    procedure DoOnNewRecord; override;
    procedure DoAfterDelete; override;
    procedure DoAfterEdit; override;
    procedure DoAfterScroll; override;
    procedure DoBeforeClose; override;
    procedure DoBeforeScroll; override;
    procedure DoOnCalcFields; override;

    procedure DoBeforeRefresh; override;
    procedure DoAfterRefresh; override;

    procedure DoOnApplyDefaultValue(Field:TField; var Applied:boolean); dynamic;

    function  GetRecordCount: Integer; override;
    procedure UpdateFieldsProps; virtual;

    procedure DoAfterEndUpdateTransaction(EndingTR:TFIBTransaction;Action: TTransactionAction;
      Force: Boolean); override;

    procedure ClearModifFlags(Kind: byte; NeedRefreshFields:boolean=True);
    procedure CloseProtect;
    function RaiseLockError(LockError: TLockStatus; ExceptMessage: string):
      TDataAction;
  private
//
    FBlockContextCount:integer;
    FBlockSize:Integer;
    FExecBlockStatement:TStrings;
    function  AddStatementToExecuteBlock(SK:TpSQLKind):boolean;
    //=Succes add to execblock
  protected
    procedure LoadRepositoryInfo; override;
    procedure SQLChanging(Sender: TObject); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function RecordCountFromSrv: integer; dynamic;
    function VisibleRecordCount: Integer;
    function VisibleRecnoToRecno(VisRN: integer): Integer;

    procedure ParseParamToFieldsLinks(Dest: TStrings); override;
    procedure Prepare; override;
    function CanEdit: Boolean; override;
    function CanInsert: Boolean; override;
    function CanDelete: Boolean; override;
    function IsSequenced: Boolean; override; // Scroll bar

    function ExistActiveUO(KindUpdate: TUpdateKind): boolean;
    // Exist active Update objects

    function AddUpdateObject(Value: TpFIBUpdateObject): integer;
    procedure RemoveUpdateObject(Value: TpFIBUpdateObject);

    function ParamByName(const ParamName: string): TFIBXSQLVAR;
    function FindParam(const ParamName: string): TFIBXSQLVAR;

    function RecordStatus(RecNumber: integer): TUpdateStatus;
    procedure CloneRecord(SrcRecord: integer; IgnoreFields: array of const);
    procedure CloneCurRecord(IgnoreFields: array of const);
    // Cached Routine
    procedure CommitUpdToCach; // Clear CU buffers
    procedure ApplyUpdToBase(DontChangeCacheFlags:boolean=True); // Send Updates to Base
    procedure ApplyUpdates;

    // SaveLoad Buffer functions

    procedure SaveToStream(Stream: TStream; SeekBegin: boolean; AddInfo:Ansistring='');
    procedure LoadFromStream(Stream: TStream; SeekBegin: boolean ); overload;
    procedure LoadFromStream(Stream: TStream; SeekBegin: boolean; var AddInfo:Ansistring);overload;

//    procedure SaveToXmlFile(const FileName:string; Format:TXmlDataSetFormat); overload;
//    procedure SaveToXmlFile(const FileName:string; const FormatName:string);  overload;

    procedure SaveToFile(const FileName: string; AddInfo:Ansistring='');
    procedure LoadFromFile(const FileName: string); overload;
    procedure LoadFromFile(const FileName: string;var AddInfo:Ansistring); overload;


    // End SaveLoad

    function LockRecord(RaiseErr: boolean= True): TLockStatus;
    function FieldByFieldNo(FieldNo: Integer): TField;
    function ParamNameCount(const aParamName: string): integer;
    function ParamCount: integer;
    procedure ExecUpdateObjects(KindUpdate: TUpdateKind; Buff: TRecordBuffer;
      aExecuteOrder: TFIBOrderExecUO);
{$IFDEF USE_DEPRECATE_METHODS2}
    procedure DoUserEvent(Sender: TObject; const UDE: string; var Info: string);
      dynamic; deprecated;
{$ENDIF}
    procedure OpenWP(const ParamValues: array of Variant); overload;
    procedure OpenWP(const ParamNames : string;const ParamValues: array of Variant); overload;
    procedure OpenWPS(const ParamSources: array of ISQLObject);

    procedure ReOpenWP(const ParamValues: array of Variant); overload;
    procedure ReOpenWP(const ParamNames : string;const ParamValues: array of Variant); overload;
    procedure ReOpenWPS(const ParamSources: array of ISQLObject);


    procedure BatchRecordToQuery(ToQuery:TFIBQuery);
    procedure BatchAllRecordsToQuery(ToQuery:TFIBQuery);
    procedure AutoGenerateSQLText(ForState: TDataSetState);


    function GenerateSQLText
      (const TableName, KeyFieldNames: string; SK: TpSQLKind; IncludeFields:TIncludeFieldsToSQL=ifsAllFields;
     ReturningFields: TSetReturningFields=[]
    ): string;

    function GenerateSQLTextNoParams
      (const TableName, KeyFieldNames: string; SK: TpSQLKind): string;

    function GenerateSQLTextWA
      (const TableName: string; SK: TpSQLKind; IncludeFields:TIncludeFieldsToSQL=ifsAllFields): string;
      // Where All
    procedure GenerateUpdateBlobsSQL;
    procedure GenerateSQLs;
    function CanGenerateSQLs: boolean;

    //AutoUpdate operations
    function KeyField: TField;
    function SqlTextGenID: string;
    procedure IncGenerator; virtual;


    function AllKeyFields(const TableName: string): string;

    procedure CacheModify(
      aFields: array of integer; Values: array of Variant;  KindModify: byte
    );

    procedure CacheEdit(aFields: array of integer; Values: array of Variant);
    procedure CacheAppend(aFields: array of integer; Values: array of Variant);
      overload;
    procedure CacheAppend(Value: Variant; DoRefresh: boolean = False); overload;

    procedure CacheInsert(aFields: array of integer; Values: array of Variant);
      overload;
    procedure CacheInsert(Value: Variant; DoRefresh: boolean = False); overload;

    procedure CacheRefresh(FromDataSet: TDataSet; Kind: TCachRefreshKind
      ; FieldMap: TStrings
      );
    procedure CacheRefreshByArrMap(
      FromDataSet: TDataSet; Kind: TCachRefreshKind;
      const SourceFields, DestFields: array of string
      );
    procedure RefreshFromQuery(RefreshQuery:TFIBQuery;const KeyFields:string; IsDeletedRecords:boolean=False;
     DoAdditionalRefreshRec:boolean=False
    );

    procedure RefreshFromDataSet(RefreshDataSet:TDataSet;const KeyFields:string;
     IsDeletedRecords:boolean=False;
     DoAdditionalRefreshRec:boolean=False
    );

    function RecordFieldAsFloat(Field: TField; RecNumber: integer;
      IsVisibleRecordNum: boolean = True): Double;

  public
    property HasUncommitedChanges: boolean read FHaveUncommitedChanges;
    property HaveRollbackedChanges: boolean read FHaveRollbackedChanges;
    property AllRecordCount: integer read FAllRecordCount;
    property VisibleRecno: integer read GetVisibleRecno write SetVisibleRecno;
  published

    //Added properties
    property Filtered;
    property OnFilterRecord;

    property DeleteSQL: TStrings read GetDeleteSQL write SetDeleteSQL;
    property UpdateSQL: TStrings read GetUpdateSQL write SetUpdateSQL;
    property InsertSQL: TStrings read GetInsertSQL write SetInsertSQL;
    property RefreshSQL: TStrings read GetRefreshSQL write SetRefreshSQL;
    property SelectSQL: TStrings read GetSelectSQL write SetSelectSQL;

    property DefaultFormats: TFormatFields read FDefaultFormats write
      FDefaultFormats;
    property OnPostError: TDataSetErrorEvent read vUserOnPostError write
      vUserOnPostError;
    property OnDeleteError: TDataSetErrorEvent read vUserOnDeleteError write
      vUserOnDeleteError;
    property OnLockError: TLockErrorEvent read FOnLockError write FOnLockError;
{$IFDEF USE_DEPRECATE_METHODS2}

    property OnUserEvent: TUserEvent read FOnUserEvent write FOnUserEvent;

    property ReceiveEvents: TStrings read FReceiveEvents write SetReceiveEvents;
{$ENDIF}    
    property DataSet_ID: integer read FDataSet_ID write SetDataSet_ID default 0;
    property Description: string read FDescription write FDescription;
    property Container:TDataSetsContainer read FContainer write SetContainer;
    property OnAskRecordCount: TOnGetSQLTextProc read FOnAskRecordCount write
      FOnAskRecordCount;
    property About: string read GetFIBVersion write SetFIBVersion stored False;
    property OnApplyDefaultValue:TOnApplyDefaultValue read FOnApplyDefaultValue write FOnApplyDefaultValue;
    property OnApplyFieldRepository:TOnApplyFieldRepository read FOnApplyFieldRepository write FOnApplyFieldRepository;
    property OnLockSQLText  :TOnGetSQLTextProc    read FOnLockSQLText write FOnLockSQLText;
  end;

function FieldInArray(Field: TField; Arr: array of const): boolean;


implementation

uses
{$IFNDEF NO_MONITOR}
  FIBSQLMonitor,
{$ENDIF}
{$IFDEF D_XE3}
  System.Types, // for inline funcs
{$ENDIF}

  StrUtil, DBConsts, SqlTxtRtns, FIBConsts, 
  pFIBFieldsDescr, pFIBCacheQueries,FIBCacheManage;


const
  SQLKindNames: array[TpSQLKind] of string = (
    'UpdateSQL',
    'InsertSQL',
    'DeleteSQL',
    'RefreshSQL',
    'UpdateOrInsert'
    );

  StreamSignature:AnsiString = 'FIB$DATASET';

function UseFormat(const sFormat: string; Scale: integer): string;
var
  L, pD: integer;
begin
  L := Length(sFormat);
  if (L = 0) then
    Result := sFormat
  else
  if (sFormat[L] = '.') then
    Result := sFormat + MakeStr('0', Scale)
  else
  begin
    pD := PosCh('.', sFormat);
    if pD = 0 then
      Result := sFormat
    else
    if (pD = L - 1) then
      Result := FastCopy(sFormat, 1, Pred(pd)) + '.' + MakeStr(sFormat[L], Scale)
    else
      Result := sFormat
  end;
end;

//

constructor TpFIBDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDefaultFormats := TFormatFields.Create(Self);
  inherited OnPostError := DoOnPostError;
  inherited OnDeleteError := DoOnDeleteError;

  vUpdates := TList.Create;
  vDeletes := TList.Create;
  vInserts := TList.Create;

  FReceiveEvents := TStringList.Create;

  vQryRecordCount := TFIBQuery.Create(Self);
  vQryRecordCount.ParamCheck := True;
  vLockQry := TFIBQuery.Create(Self);
  vLockQry.ParamCheck := True;

end;

destructor TpFIBDataSet.Destroy;
begin
  FDefaultFormats.Free;
  vUpdates.Free;
  vDeletes.Free;
  vInserts.Free;
  FReceiveEvents.Free;

   if Assigned(FExecBlockStatement) then
    FExecBlockStatement.Free;
   if Assigned(FParams) then
    FParams.Free;
  if FGeneratorBeUsed then
   FreeHandleCachedQuery(Database,
    'select gen_id(' + FAutoUpdateOptions.GeneratorName + ', '
    + IntToStr(FAutoUpdateOptions.GeneratorStep) +') from RDB$DATABASE'
   );
  inherited Destroy;
end;


function TpFIBDataSet.GetVisibleRecno: Integer;
var
  R: integer;
begin
  R := inherited GetRecno;
  FFilteredCacheInfo.NonVisibleRecords.Find(R, Result);
  Result := R - Result;
end;

procedure TpFIBDataSet.SetVisibleRecno(Value: Integer);
var
  R, R1: integer;
  Diff, i: integer;
begin
  if (FFilteredCacheInfo.NonVisibleRecords.Count = 0) or
    (FFilteredCacheInfo.NonVisibleRecords[0] > Value)
  then
    inherited SetRecno(Value)
  else
  begin
    R := FFilteredCacheInfo.NonVisibleRecords[0];
    R1 := R - 1;
    for i := 1 to Pred(FFilteredCacheInfo.NonVisibleRecords.Count) do
    begin
      Diff := FFilteredCacheInfo.NonVisibleRecords[i] - R - 1;
      if Diff <> 0 then
      begin
        if R1 + Diff > Value then
          Diff := Value - R1;
        Inc(R1, Diff);
        if R1 = Value then
        begin
          R := FFilteredCacheInfo.NonVisibleRecords[i - 1] + Diff;
          Break
        end
      end;
      R := FFilteredCacheInfo.NonVisibleRecords[i];
    end;
    if R1 < Value then
    begin
      R := FFilteredCacheInfo.NonVisibleRecords.LastItem + Value - R1
    end;
    inherited SetRecno(R)
  end;
end;

function TpFIBDataSet.GetRecNo: Integer;
begin
  if poVisibleRecno in Options then
    Result := VisibleRecNo
  else
    Result := inherited GetRecNo
end;

procedure TpFIBDataSet.SetRecNo(Value: Integer);
begin
  if poVisibleRecno in Options then
    SetVisibleRecno(Value)
  else
    SetRealRecNo(Value);
end;


function TpFIBDataSet.VisibleRecordCount: Integer;
var
  Buff: TRecordBuffer;
  i: integer;
  OldCurrentRec: integer;
begin
  if not Filtered then
    Result := RecordCount
  else
  begin
    Result := 0;
    Buff := AllocRecordBuffer;
    OldCurrentRec := FCurrentRecord;
    try
      if FFilteredCacheInfo.AllRecords <> FRecordCount then
      begin
        for i := 0 to Pred(FRecordCount) do
        begin
          FCurrentRecord := i;
          ReadRecordCache(FCurrentRecord, Buff, False);
          if IsVisible(Buff) then
            Inc(Result)
        end;
        FFilteredCacheInfo.AllRecords := FRecordCount;
        FFilteredCacheInfo.FilteredRecords := Result
      end
      else
      begin
        Result := FFilteredCacheInfo.FilteredRecords
      end
    finally
      FCurrentRecord := OldCurrentRec;
      FreeRecordBuffer(Buff);
    end;
  end;
end;

function TpFIBDataSet.VisibleRecnoToRecno(VisRN: integer): Integer;
var
  i: Integer;
  VisCount: integer;
  PredRN: integer;
begin
  with FFilteredCacheInfo do
    if NonVisibleRecords.Count = 0 then
      Result := VisRN
    else
    begin
      VisCount := 0;
      PredRN := 0;
      for i := 0 to NonVisibleRecords.Count - 1 do
      begin
        Inc(VisCount, NonVisibleRecords[i] - PredRN - 1);
        if VisCount > VisRN then
        begin
          Result := VisRN + i;
          Exit;
        end
        else
          PredRN := NonVisibleRecords[i];
      end;
      Result := VisRN + NonVisibleRecords.Count;
    end;
end;


procedure TpFIBDataSet.DoAfterEndUpdateTransaction(
 EndingTR:TFIBTransaction;Action: TTransactionAction;  Force: Boolean);
begin
  if (Action in [TACommit, TACommitRetaining]) then
  begin
    if (poProtectedEdit in Options) and not CachedUpdates  then
        CloseProtect;
    FHaveUncommitedChanges :=False
  end
  else
  begin
   FHaveRollbackedChanges :=FHaveUncommitedChanges or FHaveRollbackedChanges;
   FHaveUncommitedChanges :=False
  end;
  inherited DoAfterEndUpdateTransaction(EndingTR,Action,Force);
end;


function TpFIBDataSet.CanEdit: Boolean; //override;
begin
  Result := ((inherited CanEdit or ExistActiveUO(ukModify)
    or WillGenerateSQLs
    or (CachedUpdates and Assigned(OnUpdateRecord))

    )
    and (ukModify in FAllowedUpdateKinds)
    )
    or (drsInCacheRefresh in FRunState)
end;

function TpFIBDataSet.CanInsert: Boolean; //override;
begin
  Result := ((inherited CanInsert or ExistActiveUO(ukInsert)
    or WillGenerateSQLs
    or (CachedUpdates and Assigned(OnUpdateRecord))
    )
    and (ukInsert in FAllowedUpdateKinds)
    )
    or (drsInCacheRefresh in FRunState)
end;

function TpFIBDataSet.CanDelete: Boolean;
begin
  Result := (inherited CanDelete or ExistActiveUO(ukDelete)
    or WillGenerateSQLs
    or (CachedUpdates and Assigned(OnUpdateRecord))
    )
    and (ukDelete in FAllowedUpdateKinds)
end;

function TpFIBDataSet.IsSequenced: Boolean;         // Scroll bar
begin
  if (CacheModelOptions.CacheModelKind<>cmkStandard) then
    Result := False
  else
  begin
    Result := inherited IsSequenced;
    if not Result then
      if not Filtered or not (poVisibleRecno in Options) then
        Result := FAllRecordCount <> 0
      else
        Result := AllFetched
  end;
end;

// UpdateObjects support

function TpFIBDataSet.ListForUO(KindUpdate: TUpdateKind): TList;
begin
  Result := nil;
  case KindUpdate of
    ukModify: Result := vUpdates;
    ukInsert: Result := vInserts;
    ukDelete: Result := vDeletes;
  end;
end;

function TpFIBDataSet.ExistActiveUO(KindUpdate: TUpdateKind): boolean;
var
  List: TList;
  i, lc: integer;

begin
  List := ListForUO(KindUpdate);
  Result := False;
  if List = nil then
    Exit;
  lc := Pred(List.Count);
  for i := 0 to lc do
  begin
    Result := TpFIBUpdateObject(List[i]).Active;
    if Result then
      Exit;
  end;
end;

procedure TpFIBDataSet.SynchroOrdersUO(List: TList);
var
  i, lc: integer;
begin
  lc := Pred(List.Count);
  with List do
    for i := 0 to lc do
    begin
      TpFIBUpdateObject(List[i]).ChangeOrderInList(i);
    end;
end;

function TpFIBDataSet.AddUpdateObject(Value: TpFIBUpdateObject): integer;
var
  List: TList;
  OldPos: integer;
begin
  Result := -1;
  if Value = nil then
    Exit;
  List := ListForUO(Value.KindUpdate);
  if List = nil then
    Exit;
  with List do
  begin
    OldPos := IndexOf(Value);
    if OldPos = -1 then
    begin
      if Value.OrderInList < Count then
        Insert(Value.OrderInList, Value)
      else
        Add(Value);
    end
    else
    begin
      if Value.OrderInList < Count then
        Move(OldPos, Value.OrderInList)
      else
        Move(OldPos, Pred(Count))
    end;
  end;
  SynchroOrdersUO(List);
  Result := List.IndexOf(Value)
end;

procedure TpFIBDataSet.RemoveUpdateObject(Value: TpFIBUpdateObject);
var
  List: TList;
begin
  if Value = nil then
    Exit;
  List := ListForUO(Value.KindUpdate);
  if List <> nil then
  begin
    List.Remove(Value);
    SynchroOrdersUO(List);
  end;
end;

/// Execute UpdateObjects

procedure TpFIBDataSet.ExecUpdateObjects(KindUpdate: TUpdateKind; Buff: TRecordBuffer;
  aExecuteOrder: TFIBOrderExecUO
  );
var
  List: TList;
  i: integer;
begin
  List := ListForUO(KindUpdate);
  if List.Count > 0 then
  begin
    for i := 0 to Pred(List.Count) do
     with TpFIBUpdateObject(List[i]) do
      if
       Active and (ExecuteOrder = aExecuteOrder) and (not EmptyStrings(SQL))
       and (SQL[0]<>SNoAction)
      then
      begin
          AutoStartUpdateTransaction;
          SetQueryParams(TpFIBUpdateObject(List[i]), Buff);
          ExecQuery;

          if SQLType in [SQLSelect, SQLExecProcedure, SQLSelectForUpdate] then
          begin
            WriteRecordCache(PRecordData(Buff)^.rdRecordNumber, Buff);
            InternalRefreshRow(TpFIBUpdateObject(List[i]), Buff);
          end;

          FHaveUncommitedChanges:=True;
      end;
  end;
end;

procedure TpFIBDataSet.SetDataSet_ID(Value: Integer);
begin
  if FDataSet_Id = Value then
    Exit;
  CheckDataSetClosed(' change DataSetID ');
  FDataSet_Id := Value;
  FPrepared := False;
  if Value <> 0 then
    PrepareOptions := PrepareOptions + [psApplyRepositary]
end;

procedure TpFIBDataSet.LoadRepositoryInfo;
begin
   ListDataSetInfo.LoadDataSetInfo(Self);
end;


procedure TpFIBDataSet.SQLChanging(Sender: TObject);
begin
  inherited;
  FHaveRollbackedChanges := False;
  FHaveUncommitedChanges := False;
end;


{$WARNINGS OFF}

procedure TpFIBDataSet.Prepare; //override;
var
  iCurScreenState: Integer;
  condApplied: boolean;
begin
  ChangeScreenCursor(iCurScreenState);
  try
    FBase.CheckDatabase;
    StartTransaction;
    FBase.CheckTransaction;
    if (psApplyRepositary in PrepareOptions)
      and (DataSet_ID <> 0)  and (FLoadedDataSet_ID <> FDataSet_Id)
    then
    begin
      condApplied := Conditions.Applied;
      ListDataSetInfo.LoadDataSetInfo(Self);
      FLoadedDataSet_ID := FDataSet_Id;
      if condApplied then
        Conditions.Apply;
    end
{    else
     FLoadedDataSet_ID:=0;}
;
    if not EmptyStrings(FQSelect.SQL) then
    begin
      if not FQSelect.Open then
        FQSelect.Prepare;
      if (csDesigning in ComponentState) then
      begin
        PrepareQuery(skModify);
        PrepareQuery(FIBDataSet.skInsert);
        PrepareQuery(FIBDataSet.skDelete);
      end;
      FPrepared := True;
      InternalInitFieldDefs;
    end
    else
      FIBError(feEmptyQuery, ['Prepare ' + CmpFullName(Self)]);
  finally
   RestoreScreenCursor(iCurScreenState);
  end;
end;
//{$WARNINGS ON}

function TpFIBDataSet.GetRecordCount: Integer;
begin
  Result := inherited GetRecordCount;
  if Filtered and (poVisibleRecno in Options) then
    Result := VisibleRecordCount
  else
  if Result < FAllRecordCount - FDeletedRecords then
    Result := FAllRecordCount - FDeletedRecords
end;


procedure  TpFIBDataSet.InternalPostRecord(Qry: TFIBQuery; Buff: Pointer);
begin
  if Qry = QInsert then
    ExecUpdateObjects(ukInsert, Buff, oeBeforeDefault)
  else
    ExecUpdateObjects(ukModify, Buff, oeBeforeDefault);
  CheckDataSetOpen(' continue post ');
  if not EmptyStrings(Qry.SQL) and (Qry.SQL[0]<>SNoAction) then
  begin
    AutoStartUpdateTransaction;
    SetQueryParams(Qry, Buff);
    if Qry.Open then
      Qry.Close;
    if not Qry.Prepared then
      Qry.Prepare;
    Qry.ExecQuery;
    FHaveUncommitedChanges:=True;
    if Qry.SQLType in [SQLSelect, SQLExecProcedure, SQLSelectForUpdate] then
    begin
      WriteRecordCache(PRecordData(Buff)^.rdRecordNumber, Buff);
      InternalRefreshRow(Qry, Buff);
    end;
  end;
  if Qry = QInsert then
  begin
    if Assigned(FBlobsUpdate) and (FBlobsUpdate.Active) then
     FBlobsUpdate.KindUpdate  :=ukInsert;
    ExecUpdateObjects(ukInsert, Buff, oeAfterDefault)
  end
  else
  begin
    if Assigned(FBlobsUpdate) and (FBlobsUpdate.Active) then
     FBlobsUpdate.KindUpdate  :=ukModify;
    ExecUpdateObjects(ukModify, Buff, oeAfterDefault);
  end;
  PRecordData(Buff)^.rdFlags := Byte(cusUnmodified);
  SetModified(False);
  WriteRecordCache(PRecordData(Buff)^.rdRecordNumber, Buff);
//  if not CachedUpdates then
   AutoCommitUpdateTransaction;

  if not EmptyStrings(FQRefresh.SQL) and (poRefreshAfterPost in Options)
     and (CacheModelOptions.CacheModelKind=cmkStandard)
  then
  begin
    DoBeforeRefresh;

    if InternalRefreshRow(FQRefresh, Buff) and (BlobFieldCount>0) then
    begin
     UpdateBlobInfo(Buff,ubiClearOldValue,False,False);
     if  CachedUpdates then
        UpdateBlobInfo(Buff,ubiCheckIsNull,True,False)
     else
        UpdateBlobInfo(Buff,ubiPost,True,False);
     WriteRecordCache(PRecordData(Buff).rdRecordNumber,Buff);
    end;


    DoAfterRefresh;
  end;
  UpdateBlobInfo(Buff,ubiClearOldValue,False,False);
end;

procedure TpFIBDataSet.InternalDeleteRecord(Qry: TFIBQuery; Buff: Pointer);
var
   vNeedDeleteFromCache:boolean;

begin
  if Qry.SQL.Count > 0 then
    if Qry.SQL[0] = SNoAction then
      Exit;
  AutoStartUpdateTransaction;
  ExecUpdateObjects(ukDelete, Buff, oeBeforeDefault);
  if not EmptyStrings(Qry.SQL) then
  begin
    SetQueryParams(Qry, Buff);
    if not Qry.Prepared then
      Qry.Prepare;
    Qry.ExecQuery;
    if Qry.Open  then
     Qry.Next;
    FHaveUncommitedChanges:=True;
  end;
  ExecUpdateObjects(ukDelete, Buff, oeAfterDefault);
  if poRefreshAfterDelete in Options then
  begin
   vNeedDeleteFromCache:=not InternalRefreshRow(QRefresh,Buff);
  end
  else
   vNeedDeleteFromCache:=True;
   
  if vNeedDeleteFromCache then
   PRecordData(Buff)^.rdFlags := Byte(cusDeletedApplied);

  WriteRecordCache(PRecordData(Buff)^.rdRecordNumber, Buff);
  if not FCachedUpdates then
    AutoCommitUpdateTransaction;
end;

procedure TpFIBDataSet.DoOnDeleteError
  (DataSet: TDataSet; E: DB.EDatabaseError; var Action: TDataAction);
begin
  if (GlobalContainer<>nil) and (FContainer<>GlobalContainer) then
   GlobalContainer.DataSetError(DataSet, deOnDeleteError, E, Action);
  if FContainer <> nil then
    FContainer.DataSetError(DataSet, deOnDeleteError, E, Action);
  if Assigned(vUserOnDeleteError) then
    vUserOnDeleteError(DataSet, E, Action);
end;

function  TpFIBDataSet.CompareFieldValues(Field:TField;const S1,S2:variant):integer;
var
  Compared:boolean;
begin
  Compared:=False;
  if (GlobalContainer<>nil) and (FContainer<>GlobalContainer) then
   Compared:=GlobalContainer.DataSetCompareFieldValues(Self, Field,S1,S2,Result);

  if FContainer <> nil then
   Compared:=FContainer.DataSetCompareFieldValues(Self, Field,S1,S2,Result);

  if not Compared then
   Result:= inherited CompareFieldValues(Field,S1,S2);
end;

procedure TpFIBDataSet.DoOnPostError
  (DataSet: TDataSet; E: DB.EDatabaseError; var Action: TDataAction);
begin
  inherited;
  if (GlobalContainer<>nil) and (FContainer<>GlobalContainer) then
   GlobalContainer.DataSetError(DataSet, deOnPostError, E, Action);
  if FContainer <> nil then
    FContainer.DataSetError(DataSet, deOnPostError, E, Action);
  if Assigned(vUserOnPostError) then
    vUserOnPostError(DataSet, E, Action);
end;

procedure TpFIBDataSet.DoBeforePost;
begin
  if (State = dsInsert) and
    (FAutoUpdateOptions.WhenGetGenID = wgBeforePost) then
    IncGenerator;
  if (GlobalContainer<>nil) and (FContainer<>GlobalContainer) then
   GlobalContainer.DataSetEvent(Self, deBeforePost);

  if FContainer <> nil then
    FContainer.DataSetEvent(Self, deBeforePost);
  inherited;
  if not CachedUpdates then
    AutoGenerateSQLText(State);
end;

procedure TpFIBDataSet.InternalOpen ;
begin
  inherited InternalOpen;
  UpdateFieldsProps
end;

procedure TpFIBDataSet.InternalPost;
var
  IsInsert: Boolean;
begin
  IsInsert:= State = dsInsert ;
  inherited InternalPost;
  if IsInsert then
    FFilteredCacheInfo.NonVisibleRecords.IncValues(GetRealRecno, 1);
end;

procedure TpFIBDataSet.DoAfterPost;
var
  ActBuff: TRecordBuffer;
begin
  if (GlobalContainer<>nil) and (FContainer<>GlobalContainer) then
   GlobalContainer.DataSetEvent(Self, deAfterPost);

  if FContainer <> nil then
    FContainer.DataSetEvent(Self, deAfterPost);
  if (poProtectedEdit in Options) and not CachedUpdates and not (AutoCommit) then
  begin
    ActBuff := GetActiveBuf;
    if PRecordData(ActBuff) <> nil then
    begin
      with PRecordData(ActBuff)^ do
        rdFlags       := Byte(cusModified);
      WriteRecordCache(PRecordData(ActBuff)^.rdRecordNumber, ActBuff);
    end
  end;

  inherited;

  if AutoCommit and CachedUpdates then
  begin
    ApplyUpdToBase;
    AutoCommitUpdateTransaction;
    CommitUpdToCach
  end;
  if
   (dcForceMasterRefresh in FDetailConditions)  and not CachedUpdates
  then
    RefreshMasterDS;
end;

procedure TpFIBDataSet.DoBeforeCancel;
begin
  inherited;
  if (GlobalContainer<>nil) and (FContainer<>GlobalContainer) then
   GlobalContainer.DataSetEvent(Self, deBeforeCancel);
  if FContainer <> nil then
    FContainer.DataSetEvent(Self, deBeforeCancel);
end;

procedure TpFIBDataSet.DoAfterCancel;
begin
  if (GlobalContainer<>nil) and (FContainer<>GlobalContainer) then
   GlobalContainer.DataSetEvent(Self, deAfterCancel);
  if FContainer <> nil then
    FContainer.DataSetEvent(Self, deAfterCancel);
  inherited;
end;

procedure TpFIBDataSet.DoBeforeDelete;
begin
  if not CanDelete then
    Abort;
{  if not CachedUpdates
    and not (FAutoUpdateOptions.UpdateOnlyModifiedFields)
    and not (drsInCacheRefresh in FRunState)
  then
  begin
    PrepareQuery(FIBDataSet.skDelete);
    if not CanDelete then
      Abort;
  end;}
  if (GlobalContainer<>nil) and (FContainer<>GlobalContainer) then
   GlobalContainer.DataSetEvent(Self, deBeforeDelete);
  if FContainer <> nil then
    FContainer.DataSetEvent(Self, deBeforeDelete);
  inherited;
end;

procedure TpFIBDataSet.DoBeforeInsert;
begin
  ForceEndWaitMaster;
  if not CanInsert then
    Abort;
{  if not CachedUpdates and not (FAutoUpdateOptions.UpdateOnlyModifiedFields)
    and not (drsInCacheRefresh in FRunState) then
    PrepareQuery(FIBDataSet.skInsert);
  if not CanInsert then
    Abort;                           }
  if (GlobalContainer<>nil) and (FContainer<>GlobalContainer) then
   GlobalContainer.DataSetEvent(Self, deBeforeInsert);
  if FContainer <> nil then
    FContainer.DataSetEvent(Self, deBeforeInsert);
  if Assigned(BeforeInsert) then
    BeforeInsert(Self);
end;

procedure TpFIBDataSet.DoAfterInsert;
begin

  if (GlobalContainer<>nil) and (FContainer<>GlobalContainer) then
   GlobalContainer.DataSetEvent(Self, deAfterInsert);
  if FContainer <> nil then
    FContainer.DataSetEvent(Self, deAfterInsert);
  inherited;
end;

procedure TpFIBDataSet.DoAfterEdit; 
begin
  if (GlobalContainer<>nil) and (FContainer<>GlobalContainer) then
   GlobalContainer.DataSetEvent(Self, deAfterEdit);

  if FContainer <> nil then
    FContainer.DataSetEvent(Self, deAfterEdit);
  inherited
end;

procedure TpFIBDataSet.DoAfterDelete; 
begin
  if (GlobalContainer<>nil) and (FContainer<>GlobalContainer) then
   GlobalContainer.DataSetEvent(Self, deAfterDelete);
  if FContainer <> nil then
    FContainer.DataSetEvent(Self, deAfterDelete);
  if AutoCommit and CachedUpdates then
  begin
    ApplyUpdToBase;
    AutoCommitUpdateTransaction;
    CommitUpdToCach
  end;
  inherited
end;

procedure TpFIBDataSet.DoAfterScroll;
begin
  if (GlobalContainer<>nil) and (FContainer<>GlobalContainer) then
   GlobalContainer.DataSetEvent(Self, deAfterScroll);
  if FContainer <> nil then
    FContainer.DataSetEvent(Self, deAfterScroll);
  inherited    
end;

procedure TpFIBDataSet.DoBeforeClose;
begin

  if DefaultFields and Assigned(FFilterParser) then
    FFilterParser.ResetFields;


  if DisableCOCount > 0 then
    Exit;
  if (GlobalContainer<>nil) and (FContainer<>GlobalContainer) then
   GlobalContainer.DataSetEvent(Self, deBeforeClose);
  if FContainer <> nil then
    FContainer.DataSetEvent(Self, deBeforeClose);
  inherited
end;



procedure TpFIBDataSet.DoBeforeRefresh;
begin
  if (GlobalContainer<>nil) and (FContainer<>GlobalContainer) then
   GlobalContainer.DataSetEvent(Self, deBeforeRefresh);
  if FContainer <> nil then
    FContainer.DataSetEvent(Self, deBeforeRefresh);
  inherited;
end;

procedure TpFIBDataSet.DoAfterRefresh;
begin
  if (GlobalContainer<>nil) and (FContainer<>GlobalContainer) then
   GlobalContainer.DataSetEvent(Self, deAfterRefresh);
  if FContainer <> nil then
    FContainer.DataSetEvent(Self, deAfterRefresh);
  inherited;
end;


procedure TpFIBDataSet.DoOnApplyDefaultValue(Field:TField; var Applied:boolean);
begin
  Applied:=False;
  if (GlobalContainer<>nil) and (FContainer<>GlobalContainer) then
   GlobalContainer.DoOnApplyDefaultValue(Self,Field, Applied);
  if FContainer <> nil then
    FContainer.DoOnApplyDefaultValue(Self,Field, Applied);
  if Assigned(FOnApplyDefaultValue) then
   FOnApplyDefaultValue(Self,Field,Applied);
end;

procedure TpFIBDataSet.DoOnCalcFields;
begin
  if (GlobalContainer<>nil) and (FContainer<>GlobalContainer) then
   GlobalContainer.DataSetEvent(Self, deOnCalcFields);
  if FContainer <> nil then
    FContainer.DataSetEvent(Self, deOnCalcFields);
  inherited
end;

procedure TpFIBDataSet.DoBeforeScroll;
begin
  if (GlobalContainer<>nil) and (FContainer<>GlobalContainer) then
   GlobalContainer.DataSetEvent(Self, deBeforeScroll);
  if FContainer <> nil then
    FContainer.DataSetEvent(Self, deBeforeScroll);
  inherited

end;

procedure TpFIBDataSet.DoOnNewRecord;
var
  i: integer;
  de: string;
  vDifferenceTime: double;
  PAR: TFIBXSQLVAR;
  DefValueApplied:boolean;
  GuidValue:TGUID;
begin
  if (FAutoUpdateOptions.WhenGetGenID = wgOnNewRecord) then
    IncGenerator
  else
  if (FAutoUpdateOptions.WhenGetGenID = wgBeforePost) and (KeyField <> nil) then
    KeyField.Required := False;
  if DataBase is TpFIBDataBase then
    vDifferenceTime := TpFIBDataBase(DataBase).DifferenceTime
  else
    vDifferenceTime := 0;
  for i := 0 to Pred(FieldCount) do
    with Fields[i] do
    begin
      if AutoUpdateOptions.SelectGenId and (Fields[i] = KeyField)
      then
        Continue;
      begin
        if not FDefaultsInited  then
        begin
         if FAutoUpdateOptions.ParamsToFieldsLinks.Count>0 then
          PAR :=
           Params.FindParam(FAutoUpdateOptions.ParamsToFieldsLinks.Values[Fields[i].FieldName])
         else
          PAR :=nil;
         FParamsForFields[i]:=PAR ;
        end
        else
         PAR := FParamsForFields[i];

        if PAR <> nil then
          Fields[i].Value := PAR.Value
        else
        if (Fields[i] is TFIBStringField) and
          TFIBStringField(Fields[i]).DefaultValueEmptyString then
          asString := ''
        else
        if (Fields[i] is TFIBGuidField) then
        begin
           CreateGuid(GuidValue);
           TFIBGuidField(Fields[i]).asGuid:=GuidValue;
        end
        else
        begin

          de := FastUpperCase(FastTrim(DefaultExpression));
         if (DefaultExpression<>'') then
          if (de='')  then
             asString := DefaultExpression
          else
          begin
            de:=CutQuote(de);
            DefValueApplied:=False;
            DoOnApplyDefaultValue(Fields[i],DefValueApplied);
            if not DefValueApplied then
            begin
             if de <> 'NULL' then
              if Fields[i] is TDateTimeField then
              begin
                if StringInArray(de, ['NOW','CURRENT_TIME','CURRENT_TIMESTAMP']) then
                  asDateTime := Now - vDifferenceTime
                else
                if StringInArray(de, ['TODAY', 'CURRENT_DATE']) then
                  asDateTime := Trunc(Now - vDifferenceTime)
                else
                if (de = 'TOMORROW') then
                  asDateTime := Trunc(Now - vDifferenceTime) + 1
                else
                if (de = 'YESTERDAY') then
                  asDateTime := Trunc(Now - vDifferenceTime) - 1
                else
                  asString := DefaultExpression;
              end
              else
              if  (Fields[i] is TFIBStringField) then
              begin
                if StringInArray(de, ['USER', 'CURRENT_USER']) then
                begin
                    asString := DataBase.DBParamByDPB[isc_dpb_user_name]
                end
                else
                if StringInArray(de, ['ROLE', 'CURRENT_ROLE']) then
                begin
                    asString := DataBase.DBParamByDPB[isc_dpb_sql_role_name]
                end
                else
                if(Length(DefaultExpression)>0) and (DefaultExpression[1]='''') then
                  asString := FastCopy(DefaultExpression,2,Length(DefaultExpression)-2)
                else
                  asString := DefaultExpression;
              end
              else
                asString := DefaultExpression;
            end;
          end;
        end;
      end;
    end;
  if (GlobalContainer<>nil) and (FContainer<>GlobalContainer) then
   GlobalContainer.DataSetEvent(Self, deOnNewRecord);
  if FContainer <> nil then
    FContainer.DataSetEvent(Self, deOnNewRecord);
  FDefaultsInited:=True;
  inherited DoOnNewRecord
end;

function TpFIBDataSet.WillGenerateSQLs: boolean;
begin
  with FAutoUpdateOptions do
    Result := UpdateOnlyModifiedFields and
      AutoReWriteSqls and CanChangeSQLs and
      (KeyFields <> '') and (UpdateTableName <> '');
end;

procedure TpFIBDataSet.SaveToStream(Stream: TStream; SeekBegin: boolean;AddInfo:Ansistring='');
var
  i, fc, fs: integer;
  Version: integer;
  ast:AnsiString;
begin
  FetchAll;
  with Stream do
  begin
    if SeekBegin then
      Seek(0, soFromBeginning);
    //

    WriteBuffer(StreamSignature[1], Length(StreamSignature));

    Version := 7;
    WriteBuffer(Version, SizeOf(Integer));
//
    fc:=Length(AddInfo);
    WriteBuffer(fc, SizeOf(Integer));
    if fc>0 then
     WriteBuffer(AddInfo[1], fc);

    fc:=CacheModelOptions.BufferChunks;
    WriteBuffer(fc, SizeOf(Integer));
    WriteBuffer(FRecordBufferSize, SizeOf(Integer));
    WriteBuffer(FCalcFieldsOffset, SizeOf(Integer));
    WriteBuffer(FBlockReadSize, SizeOf(Integer));
    WriteBuffer(FStringFieldCount, SizeOf(Integer));
    WriteBuffer(vrdFieldCount, SizeOf(Integer));


    fc := FieldDefs.Count;
    WriteBuffer(fc, SizeOf(Integer));
    for i := 0 to Pred(fc) do
    with FieldDefs[i] do
    begin
      fs := Size;
      WriteBuffer(fs, SizeOf(Integer));
      WriteBuffer(DataType, SizeOf(TFieldType));

      fs:=FieldNo;
      WriteBuffer(fs, SizeOf(Integer));
      ast:=Name;
      fs:=Length(ast);
      WriteBuffer(fs, SizeOf(Integer));
      WriteBuffer(ast[1], fs);
    end;

//

    vFieldDescrList.SaveToStream(Stream);

    fc := FieldCount;
    WriteBuffer(fc, SizeOf(Integer));
    for i := 0 to Pred(fc) do
    begin
      fs := Fields[i].DataSize;
      WriteBuffer(fs, SizeOf(Integer));
      WriteBuffer(Fields[i].DataType, SizeOf(TFieldType));
    end;


    WriteBuffer(FRecordCount, SizeOf(Integer));
    WriteBuffer(FDeletedRecords, SizeOf(Integer));
    FRecordsCache.SaveToStream(Stream, False);
  end;
end;

procedure TpFIBDataSet.LoadFromStream(Stream: TStream; SeekBegin: boolean);
var AddInfo:Ansistring;
begin
 LoadFromStream(Stream,SeekBegin,AddInfo)
end;

procedure TpFIBDataSet.LoadFromStream(Stream: TStream; SeekBegin: boolean;var AddInfo:Ansistring);
var
  fc: integer;
  i, fs: integer;
  FieldNo,Version: integer;
  ft: TFieldType;
  s: Ansistring;
  vSize:integer;
  Name:Ansistring;
  vDefaultFields:boolean;
  procedure RaizeErrStream;
  begin
    raise Exception.Create(
      Format(SFIBErrorUnableStreamLoad, [CmpFullName(Self)])
      );
  end;

begin
  DisableControls;
  if not (csDesigning in ComponentState) then
  try
    Include(FRunState,drsInLoadFromStream);
    with Stream do
    begin
      if SeekBegin then
        Seek(0, soFromBeginning);
      SetString(s, nil, Length(StreamSignature));
      ReadBuffer(s[1], Length(StreamSignature));
      if s <> StreamSignature then
        raise Exception.Create('Can''t load dataset cache from Stream.');

      ReadBuffer(Version, SizeOf(Integer));
      if Version < 7 then
       raise
          Exception.Create('Can''t load dataset cache from Stream.Incorrect version.');

      if Version>=7 then
      begin
        ReadBuffer(fc, SizeOf(Integer));
        SetLength(AddInfo,fc);
        if fc>0 then
         ReadBuffer(AddInfo[1], fc);

       if Active then Close;

       ReadBuffer(fc, SizeOf(Integer));
       CacheModelOptions.BufferChunks:=fc;
       ReadBuffer(FRecordBufferSize, SizeOf(Integer));
       ReadBuffer(FCalcFieldsOffset, SizeOf(Integer));
       ReadBuffer(FBlockReadSize, SizeOf(Integer));
       ReadBuffer(FStringFieldCount, SizeOf(Integer));
       ReadBuffer(vrdFieldCount, SizeOf(Integer));

       FieldDefs.BeginUpdate;
       FieldDefs.Clear;
       ReadBuffer(fc, SizeOf(Integer));
       for i := 0 to Pred(fc) do
       begin
        ReadBuffer(vSize, SizeOf(Integer));
        ReadBuffer(ft, SizeOf(TFieldType));
        ReadBuffer(FieldNo, SizeOf(Integer));
        ReadBuffer(fs, SizeOf(Integer));
        SetLength(Name,fs);
        if fs>0 then
         ReadBuffer(Name[1], fs);
         with TFieldDef.Create(FieldDefs,Name,
                     ft, vSize, False, FieldNo) do
            InternalCalcField := False;
       end;

       FieldDefs.EndUpdate;
      end;

      vFieldDescrList.LoadFromStream(Stream,Version);
      ReadBuffer(fc, SizeOf(Integer));
      vDefaultFields:=False;
      if fc <> FieldCount then
      begin
        if (FieldCount=0) and not Active then
        begin
         CreateFields;
         vDefaultFields:=True
        end;
       if fc <> FieldCount then
        RaizeErrStream;
      end;

      BindFields(True);
      for i := 0 to Pred(fc) do
      begin
        ReadBuffer(fs, SizeOf(Integer));
        if fs <> Fields[i].DataSize then
          RaizeErrStream;
        ReadBuffer(ft, SizeOf(TFieldType));
        if ft <> Fields[i].DataType then
          RaizeErrStream;
      end;
      try

        ReadBuffer(FRecordCount, SizeOf(Integer));
        ReadBuffer(FDeletedRecords, SizeOf(Integer));
        if not Assigned(FRecordsCache) then
         FRecordsCache:=
         TRecordsCache.Create(CacheModelOptions.BufferChunks,FRecordBufferSize,FBlockReadSize,FStringFieldCount);

        FRecordsCache.LoadFromStream(Stream, False);
      except
        Close;
        raise;
      end;
      if not Active then
      begin
        Include(FRunState,drsInClone);
        try
         Open;
         if vDefaultFields then
          SetDefaultFields(True);
         RefreshClientFields(False);
        finally
         Exclude(FRunState,drsInClone);
        end;
      end
    end;
  //  RefreshClientFields;
    First;
 finally
  Exclude(FRunState,drsInLoadFromStream);
  EnableControls
 end
end;



procedure TpFIBDataSet.SaveToFile(const FileName: string; AddInfo:Ansistring='');
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(FileName,fmCreate);
  try
    SaveToStream(Stream, True,AddInfo);
  finally
    Stream.Free;
  end;
end;
{
procedure TpFIBDataSet.SaveToXmlFile(const FileName:string; const FormatName:string);
begin
 DataSetSaveToXML(Self,FileName,FormatName)
end;

procedure TpFIBDataSet.SaveToXmlFile(const FileName:string; Format:TXmlDataSetFormat);
begin
 case Format of
  xmlAdo :   DataSetSaveToXML(Self,FileName,TAdoXmlWriter.Name);
  xmlClientDataset: DataSetSaveToXML(Self,FileName,TClientDataSetXmlWriter.Name);
 else
 end
end;
}
procedure TpFIBDataSet.LoadFromFile(const FileName: string);
var
  AddInfo:Ansistring;
begin
 LoadFromFile(FileName,AddInfo);
end;

procedure TpFIBDataSet.LoadFromFile(const FileName: string;var AddInfo:Ansistring);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(FileName, fmOpenRead);
  try
    LoadFromStream(Stream, True,AddInfo);
    PrepareAdditionalInfo;
  finally
    Stream.Free;
  end;
end;

function
  TpFIBDataSet.RaiseLockError(LockError: TLockStatus; ExceptMessage: string):
  TDataAction;
begin
  Result := daFail;
  if Assigned(FOnLockError) then
    FOnLockError(Self, LockError, ExceptMessage, Result);
  case Result of
    daFail: raise Exception.Create(ExceptMessage);
    daAbort: Abort
  end
end;

procedure TpFIBDataSet.DoBeforeEdit;
var
  oldUM: boolean;
begin
  if not CanEdit then
    Abort;
  if (poProtectedEdit in Options) then
    with AutoUpdateOptions do
      if UpdateStatus = usUnModified then
      begin
        LockRecord(True);
        if EmptyStrings(RefreshSQL) and
          (AutoReWriteSqls or UpdateOnlyModifiedFields)
        then
        begin
         QRefresh.SQL.Text := GenerateSQLText(UpdateTableName, KeyFields, skRefresh);
        end;
        InternalRefresh;
        if EmptyStrings(UpdateSQL) and
          (AutoReWriteSqls or UpdateOnlyModifiedFields)
        then
        begin
          oldUM := UpdateOnlyModifiedFields;
          UpdateOnlyModifiedFields := False;
          QUpdate.SQL.Text         := GenerateSQLText(UpdateTableName, KeyFields,skModify);
          UpdateOnlyModifiedFields := oldUM;
        end;
      end;
  if (GlobalContainer<>nil) and (FContainer<>GlobalContainer) then
   GlobalContainer.DataSetEvent(Self, deBeforeEdit);
  if FContainer <> nil then
    FContainer.DataSetEvent(Self, deBeforeEdit); 
  inherited;
end;

procedure TpFIBDataSet.InternalDoBeforeOpen;
begin
  if psAskRecordCount in PrepareOptions then
    FAllRecordCount := RecordCountFromSrv
  else
    FAllRecordCount := 0;
end;

procedure TpFIBDataSet.DoBeforeOpen;
begin
  StartTransaction;
  FFilteredCacheInfo.NonVisibleRecords.Clear;
  if DisableCOCount > 0 then
    Exit;
  if (GlobalContainer<>nil) and (FContainer<>GlobalContainer) then
   GlobalContainer.DataSetEvent(Self, deBeforeOpen);
  if FContainer <> nil then
    FContainer.DataSetEvent(Self, deBeforeOpen);
  inherited DoBeforeOpen;
end;

procedure TpFIBDataSet.DoAfterClose; // override;
begin
  SetLength(FParamsForFields,0);
  if DisableCOCount > 0 then
    Exit;
  if (GlobalContainer<>nil) and (FContainer<>GlobalContainer) then
   GlobalContainer.DataSetEvent(Self, deAfterClose);
  if FContainer <> nil then
    FContainer.DataSetEvent(Self, deAfterClose);
  inherited DoAfterClose;
  FSQLTextChanges := QSelect.SQLTextChangeCount;
  FHaveRollbackedChanges := False;
end;

function TpFIBDataSet.GetSelectSQL: TStrings;
begin
  Result := inherited SelectSQL
end;

procedure TpFIBDataSet.SetSelectSQL(Value: TStrings);
begin
  if Active and (csDesigning in ComponentState) then
    Close;
  inherited SelectSQL := Value
end;

procedure TpFIBDataSet.SetPrepareOptions(Value: TpPrepareOptions);
var
  NeedUpdateFieldsProps: boolean;
begin
  NeedUpdateFieldsProps := (psApplyRepositary in Value - FPrepareOptions);
  inherited;
  if NeedUpdateFieldsProps then
    UpdateFieldsProps
end;

function TpFIBDataSet.ParamNameCount(const aParamName: string): integer;
var
  i: integer;
begin
  Result := 0;
  with Params do
  begin
    for i := Pred(Count) downto 0 do
      if Params[i].Name = aParamName then
        Inc(Result)
  end;
end;

function TpFIBDataSet.ParamCount: integer;
begin
  Result := Params.Count
end;

function TpFIBDataSet.FindParam(const ParamName: string): TFIBXSQLVAR;
begin
  StartTransaction;
  Result := Params.ByName[ParamName];
end;

function TpFIBDataSet.ParamByName(const ParamName: string): TFIBXSQLVAR;
begin
  Result := Params.ByName[ParamName];
  if Result = nil then
    raise Exception.Create(
      Format(SFIBErrorParamNotExist, [ParamName, CmpFullName(Self)])
      );
end;

//{$WARNINGS OFF}
procedure TpFIBDataSet.ApplyUpdates;
begin
 ApplyUpdToBase(False);
end;
//{$WARNINGS ON}

procedure TpFIBDataSet.ClearModifFlags(Kind: byte; NeedRefreshFields:boolean=True);
var
  i: integer;
  Buff: TRecordBuffer;
begin
  // Commit Updates
  Buff := AllocRecordBuffer;
  try
    for i := 0 to Pred(FRecordCount) do
    begin
      ReadRecordCache(i, Buff, False);
      with PRecordData(Buff)^ do
      begin
        case Kind of
          0:
          case TCachedUpdateStatus(rdFlags and 7) of
            cusDeleted:
               rdFlags  := Byte(cusDeletedApplied);
            cusInserted, cusModified:
               rdFlags  := Byte(cusUnmodified);
          else
              Continue
          end;
          1:
          if (TCachedUpdateStatus(rdFlags and 7) in [cusUnModified, cusDeletedApplied]) then
            Continue
          else
             rdFlags := Byte(cusUnmodified);
        end;
        WriteRecordCache(i, Buff);
      end;
    end;
    FUpdatesPending := False;
    FCountUpdatesPending := 0;
  finally
    FreeRecordBuffer(Buff);
  end;
 if (State=dsBrowse) and CachedUpdates then
  RefreshClientFields(NeedRefreshFields);
// ^^^For refresh Grid buffer
   SaveOldBuffer(GetActiveBuf);
end;

procedure TpFIBDataSet.CloseProtect;
begin
  if Active then
    ClearModifFlags(1,False)
end;

procedure TpFIBDataSet.CommitUpdToCach;
begin
  ClearModifFlags(0);
end;

{$WARNINGS OFF}
procedure TpFIBDataSet.ApplyUpdToBase(DontChangeCacheFlags:boolean=True);
var
  i: integer;
  Buff: TRecordBuffer;
  UpdateKind: TUpdateKind;
  UpdateAction: TFIBUpdateAction;
  cus: TCachedUpdateStatus;
  vResume:Boolean;
  bRecordsSkipped:boolean;
  RecordsInExecBlock:array of Integer;
  SQL:WideString;
procedure SaveFlagsForRecordsInExecBlock;
var
 j:integer;
begin
  if not DontChangeCacheFlags then
  begin
   for j:=0 to Pred(Length(RecordsInExecBlock)) do
   begin
    ReadRecordCache(RecordsInExecBlock[j], Buff, False);
    PRecordData(Buff)^.rdFlags:=Byte(cusUnmodified);
    WriteRecordCache(RecordsInExecBlock[j], Buff);
   end;
   SetLength(RecordsInExecBlock,1);
   RecordsInExecBlock[0]:=i;
  end
end;

procedure AddRecordToListInExecBlock;
begin
  if not DontChangeCacheFlags then
  begin
   SetLength(RecordsInExecBlock,Length(RecordsInExecBlock)+1);
   RecordsInExecBlock[Length(RecordsInExecBlock)-1]:=i;
  end;
end;

procedure AddRecordToExecuteBlock(Kind:TpSQLKind);
begin
  if not AddStatementToExecuteBlock(Kind) then
  begin
//    FQUpdate.SQL.Assign(FExecBlockStatement);
    UpdateAction:=uaApply;
      while (UpdateAction in [uaApply, uaRetry]) do
      try
       if Database.IsUnicodeConnect then
         SQL:=UTF8Decode(FExecBlockStatement.Text)
       else
         SQL:=FExecBlockStatement.Text;

       UpdateTransaction.ExecSQLImmediate(SQL);

       UpdateAction:=uaApplied;
      except
            on E: EFIBError do
            begin
              UpdateAction := uaFail;
              if Assigned(FOnUpdateError) then
                FOnUpdateError(Self, E, UpdateKind, UpdateAction);
              case UpdateAction of
                uaFail: raise;
                uaAbort: raise EAbort.Create(E.Message);
                uaSkip:  bRecordsSkipped := True;
              end;
            end;
      end;
    FExecBlockStatement.Clear;
    SaveFlagsForRecordsInExecBlock;
    AddStatementToExecuteBlock(Kind);
    AddRecordToListInExecBlock;
  end
  else
   AddRecordToListInExecBlock;
end;

begin
  if State in [dsEdit, dsInsert] then
    Post;
  if FRecordCount = 0 then
    Exit;
  AutoStartUpdateTransaction;
  Buff := AllocRecordBuffer;
  try
    bRecordsSkipped:=False;
    for i := 0 to Pred(FRecordCount) do
    begin
      ReadRecordCache(i, Buff, False);
      with PRecordData(Buff)^ do
      begin
        if TCachedUpdateStatus(rdFlags) in [cusUnmodified, cusUnInserted,cusDeletedApplied]
        then
          Continue;
        cus := TCachedUpdateStatus(rdFlags and 7);
        FUpdatesPending := True;
        case TCachedUpdateStatus(rdFlags and 7) of
          cusModified:
            UpdateKind := ukModify;
          cusInserted:
            UpdateKind := ukInsert;
          cusDeleted :
            UpdateKind :=ukDelete;
        else
          Continue
        end;
        try
          vTypeDispositionField := dfRRecNumber;
          vInspectRecno := i;
          if (Assigned(FOnUpdateRecord)) then
          begin
            UpdateAction := uaRetry;
            while UpdateAction = uaRetry do
            begin
             UpdateAction := uaFail;
             FOnUpdateRecord(Self, UpdateKind, UpdateAction);
            end
          end
          else
            UpdateAction := uaApply;
          vTypeDispositionField := dfNormal;
        except
          on E: EFIBError do
          begin
            UpdateAction := uaFail;
            if Assigned(FOnUpdateError) then
              FOnUpdateError(Self, E, UpdateKind, UpdateAction);
            vTypeDispositionField := dfNormal;
            case UpdateAction of
              uaFail: raise;
              uaAbort: raise EAbort.Create(E.Message);
            end;
            case UpdateAction of
              uaFail:
                FIBError(feUserAbort, [nil]);
              uaAbort:
                raise EAbort.Create(
                  Format(SFIBErrorAbortUpdates, [iifStr(Self.Owner <> nil,
                    Self.Owner.Name + '.', ''), Self.Name])
                  );
              uaSkip: bRecordsSkipped:=True
            end;
          end;
        end;

        while (UpdateAction in [uaApply, uaRetry]) do
        begin
          try
            vTypeDispositionField := dfRRecNumber;
            vInspectRecno := i;
            case TCachedUpdateStatus(rdFlags and 7) of
              cusModified:
                if CanEdit then
                begin
                 if  FAutoUpdateOptions.UseExecuteBlock then
                 begin
                  AddRecordToExecuteBlock(skModify);
                 end
                 else
                 begin
                  AutoGenerateSQLText(dsEdit);
                  InternalPostRecord(FQUpdate, Buff);
                 end;
                end;
              cusInserted:
                if CanInsert then
                begin
                 if  FAutoUpdateOptions.UseExecuteBlock then
                 begin
                  AddRecordToExecuteBlock(FIBDataSet.skInsert)
                 end
                 else
                 begin
                  AutoGenerateSQLText(dsInsert);
                  InternalPostRecord(FQInsert, Buff);
                 end
                end;
              cusDeleted:
                if CanDelete then
                 if  FAutoUpdateOptions.UseExecuteBlock then
                 begin
                  if not AddStatementToExecuteBlock(FIBDataSet.skDelete) then
                  begin
                    AddRecordToExecuteBlock(FIBDataSet.skDelete)
                  end;
                 end
                 else
                 begin
                  InternalDeleteRecord(FQDelete, Buff);
                 end
            end;
            if DontChangeCacheFlags and not FAutoUpdateOptions.UseExecuteBlock  then
            begin
             //        Restore CU status
             rdFlags:=Byte(cus);
             WriteRecordCache(i, Buff);
            end;
            UpdateAction := uaApplied;

            if Assigned(FAfterUpdateRecord) then
            begin
              vResume := True;
              FAfterUpdateRecord(Self, UpdateKind, vResume);
              if not vResume then
               Abort;
            end;

          except
            (*
             * If there is an exception, then allow the user
             * to intervene (decide what to do about it).
             *)
            on E: EFIBError do
            begin
              UpdateAction := uaFail;
              if Assigned(FOnUpdateError) then
                FOnUpdateError(Self, E, UpdateKind, UpdateAction);
              case UpdateAction of
                uaFail: raise;
                uaAbort: raise EAbort.Create(E.Message);
                uaSkip:  bRecordsSkipped := True;
              end;
            end;
          end;
        end;
      end;
    end;

    if  FAutoUpdateOptions.UseExecuteBlock and (FExecBlockStatement<>nil) and (FExecBlockStatement.Count>0)
    then
    begin
      FExecBlockStatement.Add('END');
//      FQUpdate.SQL.Assign(FExecBlockStatement);
      UpdateAction:=uaApply;
      while (UpdateAction in [uaApply, uaRetry]) do
      try
//       FQUpdate.ExecQuery;
       if Database.IsUnicodeConnect then
         SQL:=UTF8Decode(FExecBlockStatement.Text)
       else
         SQL:=FExecBlockStatement.Text;

       UpdateTransaction.ExecSQLImmediate(SQL);

       UpdateAction:=uaApplied;
      except
            on E: EFIBError do
            begin
              UpdateAction := uaFail;
              if Assigned(FOnUpdateError) then
                FOnUpdateError(Self, E, UpdateKind, UpdateAction);
              case UpdateAction of
                uaFail: raise;
                uaAbort: raise EAbort.Create(E.Message);
                uaSkip:  bRecordsSkipped := True;
              end;
            end;
      end;

      FExecBlockStatement.Clear;
      SaveFlagsForRecordsInExecBlock
    end;

    FUpdatesPending := bRecordsSkipped;
    if not FUpdatesPending then
      AutoCommitUpdateTransaction;

  finally
    if Assigned(FExecBlockStatement) then
     FExecBlockStatement.Clear;
    FreeRecordBuffer(Buff);
    vTypeDispositionField := dfNormal;
    RefreshClientFields
  end;
end;



function TpFIBDataSet.RecordStatus(RecNumber: integer): TUpdateStatus;
var
  Buff: TRecordBuffer;
begin
  Buff := AllocRecordBuffer;
  try
    ReadRecordCache(RecNumber, Buff, False);
    with PRecordData(Buff)^ do
      if not (TCachedUpdateStatus(rdFlags and 7) in [cusUninserted, cusDeletedApplied]) then
        Result := TUpdateStatus(rdFlags and 7)
      else
        Result := usDeleted;
  finally
    FreeRecordBuffer(Buff);
  end
end;

procedure TpFIBDataSet.UpdateFieldsProps;
var
  i: integer;
  scale: Short;
  vFiAlias, vFi: TpFIBFieldInfo;
  RelTable, RelField: string;
  vModifyTable: string;
  vModifyTableAlias:string;
begin
  if  drsInClone in FRunState then
    Exit;

  if AutoUpdateOptions.AutoReWriteSqls then
  begin
   vModifyTable:=FAutoUpdateOptions.ModifiedTableName;
   vModifyTableAlias:=FAutoUpdateOptions.AliasModifiedTable
  end
  else
  begin
   if EmptyStrings(QUpdate.SQL) then
    vModifyTable:=QInsert.ModifyTable
   else
    vModifyTable:=QUpdate.ModifyTable;
   vModifyTableAlias:='';
  end;
  for i := 0 to Pred(FieldCount) do
  begin
    if poAutoFormatFields in FOptions then
    begin
  // Format Fields routine
      case Fields[i].DataType of
        ftDate:
          with TDateField(Fields[i]) do
          begin
            if DisplayFormat = '' then
              DisplayFormat := FDefaultFormats.DisplayFormatDate;
          end;
        ftTime:
          with TTimeField(Fields[i]) do
          begin
            if DisplayFormat = '' then
              DisplayFormat := FDefaultFormats.DisplayFormatTime;
          end;
        ftDateTime:
          with TDateTimeField(Fields[i]) do
          begin
            if DisplayFormat = '' then
              DisplayFormat := FDefaultFormats.DateTimeDisplayFormat;
          end;
        ftSmallint, ftInteger, ftFloat:
          with TNumericField(Fields[i]) do
          begin
            scale := GetFieldScale(TNumericField(Fields[i]));

            if scale < 0 then
            begin
              if DisplayFormat = '' then
                DisplayFormat :=
                  UseFormat(FDefaultFormats.NumericDisplayFormat, -scale);
              if EditFormat = '' then
                EditFormat :=
                  UseFormat(FDefaultFormats.NumericEditFormat, -scale)
            end;
          end;
        ftBCD:
          with TBCDField(Fields[i]) do
            if (Size > 0) and not currency then
            begin
              if DisplayFormat = '' then
                DisplayFormat :=
                  UseFormat(FDefaultFormats.NumericDisplayFormat, Size);
              if EditFormat = '' then
                EditFormat :=
                  UseFormat(FDefaultFormats.NumericEditFormat, Size); 
            end;
      end;
    end; //end Format

    if
      (PrepareOptions *
       [pfSetRequiredFields, pfSetReadOnlyFields, pfImportDefaultValues,
        psUseBooleanField] <> []
      )
      or ((psApplyRepositary in PrepareOptions) and (urFieldsInfo in DataBase.UseRepositories))
      or (Fields[i] is TFIBMemoField) and (psSupportUnicodeBlobs in PrepareOptions)
    then
    begin
      RelTable := 'ALIAS';
      RelField := Fields[i].FieldName;
      vFiAlias :=
        ListTableInfo.GetFieldInfo(DataBase, RelTable, RelField,
        (psApplyRepositary in PrepareOptions) and (urFieldsInfo in DataBase.UseRepositories)
        );

      RelTable := GetRelationTableName(Fields[i]);
      RelField := GetRelationFieldName(Fields[i]);

      if not Fields[i].ReadOnly and (pfSetReadOnlyFields in PrepareOptions)
        and (Fields[i].FieldKind = fkData) then
      begin
        if AutoUpdateOptions.AutoReWriteSqls then
        begin
          RelTable := FormatIdentifier(Database.SQLDialect,RelTable);        
          Fields[i].ReadOnly := not EquelStrings(RelTable,vModifyTable, False);
          if not Fields[i].ReadOnly  and AutoUpdateOptions.ModifiedTableHaveAlias then
          begin
           Fields[i].ReadOnly :=
            not IsEquelSQLNames(TableAliasForField(Fields[i].FieldName),vModifyTableAlias);
          end;
        end
        else
        if not CachedUpdates or not Assigned(OnUpdateRecord) then
          Fields[i].ReadOnly :=(RelTable <> vModifyTable);
      end;
      if ((RelField = '') or (RelTable = '')) and (vFiAlias = nil) then
        Continue;
      vFi :=
        ListTableInfo.GetFieldInfo(DataBase, RelTable, RelField,
        (psApplyRepositary in PrepareOptions) and (urFieldsInfo in DataBase.UseRepositories)
        );
      if (vFi = nil) then
        vFi := vFiAlias;
      if (vFi = nil) then
        Continue;
      if (Fields[i] is TFIBMemoField) and
       ((psSupportUnicodeBlobs in PrepareOptions) or Database.NeedUTFEncodeDDL)
      then
       TFIBMemoField(Fields[i]).InternalSetCharSet(vFi.CharSetID);

      {$IFDEF D_XE3}with FormatSettings do{$ENDIF}
      if pfImportDefaultValues in PrepareOptions then
        if (Fields[i] is TNumericField) then
        begin
          // Be sure to handle '1.0' with different DecSep!
          if (DecimalSeparator <> '.') then
            Fields[i].DefaultExpression := ReplaceStr(vFi.DefaultValue, '.',
              DecimalSeparator)
          else
          if IsNumericStr(vFi.DefaultValue) then
            Fields[i].DefaultExpression := vFi.DefaultValue;
        end
        else
        if (Fields[i] is TDateTimeField) and
         not StringIsDateTimeDefValue(FastUpperCase(FastTrim(vFi.DefaultValue)))
        then
        begin
          with Fields[i] do
            case DataType of
              ftDate: DefaultExpression := ToClientDateFmt(vFi.DefaultValue, 1);
              ftTime: DefaultExpression := ToClientDateFmt(vFi.DefaultValue, 2);
            else
              DefaultExpression := ToClientDateFmt(vFi.DefaultValue, 0)
            end
        end
        else
        begin
         if (Fields[i] is TFIBBooleanField) then
         begin
          if vFi.DefaultValue='1' then
           Fields[i].DefaultExpression:=TFIBBooleanField(Fields[i]).StringTrue
          else
          if vFi.DefaultValue='0' then
           Fields[i].DefaultExpression:=TFIBBooleanField(Fields[i]).StringFalse;
         end
         else
         if (Fields[i] is TDateTimeField) then
           Fields[i].DefaultExpression := FastTrim(vFi.DefaultValue)
         else
         if Fields[i] is TFIBStringField then
         begin
          TFIBStringField(Fields[i]).DefaultValueEmptyString := vFi.DefaultValueEmptyString;
          if Length(vFi.DefaultValue)>0 then
           Fields[i].DefaultExpression := ''''+vFi.DefaultValue+'''';
         end
         else
           Fields[i].DefaultExpression := vFi.DefaultValue;
        end;

      if (vFiAlias <> nil) then
       vFi := vFiAlias;

      if (Fields[i].FieldKind = fkData) then
      begin
        if not Fields[i].ReadOnly and not (psCanEditComputedFields in
          PrepareOptions) and (pfSetReadOnlyFields in PrepareOptions)
        then
        begin
          Fields[i].ReadOnly := vFi.IsComputed;
        end;

        if (pfSetRequiredFields in PrepareOptions) then
          Fields[i].Required :=
            not QSelect[Fields[i].FieldName].IsNullable and
            IsBlank(vFi.DefaultValue) and not vFi.IsTriggered;
      end;

      if psApplyRepositary in PrepareOptions then
      begin
        // Info from FIB$FIELDS_INFO
        if vFi.WithAdditionalInfo then
        begin
          if vFi.DisplayWidth <> 0 then
            Fields[i].DisplayWidth := vFi.DisplayWidth;
          if vFi.DisplayLabel <> '' then
            Fields[i].DisplayLabel := vFi.DisplayLabel;
          Fields[i].Visible := vFi.Visible;
          if (vFi.DisplayFormat <> '') then
            if (Fields[i] is TNumericField) then
              TNumericField(Fields[i]).DisplayFormat := vFi.DisplayFormat
            else
            if (Fields[i] is TDateTimeField) then
              TDateTimeField(Fields[i]).DisplayFormat := vFi.DisplayFormat;
          if (vFi.EditFormat <> '') then
            if (Fields[i] is TNumericField) then
              TNumericField(Fields[i]).EditFormat := vFi.EditFormat;
        end;

        if (GlobalContainer<>nil) and (FContainer<>GlobalContainer) then
         GlobalContainer.DoOnApplyFieldRepository(Self,Fields[i],vFI);
        if Assigned(FContainer) then
         FContainer.DoOnApplyFieldRepository(Self,Fields[i],vFI);

        if Assigned(FOnApplyFieldRepository) then
         FOnApplyFieldRepository(Self,Fields[i],vFI);
      end;
    end;
  end;
end;

procedure TpFIBDataSet.DoAfterOpen;
begin
  FDefaultsInited         := False;
  SetLength(FParamsForFields,FieldCount);
  FillChar(FParamsForFields[0],SizeOf(TFIBXSQLVAR)*FieldCount,0);
{  FHaveRollbackedChanges := False;
  FHaveUncommitedChanges := False;}
//  UpdateFieldsProps;
  if not (csDesigning in ComponentState) then
    if (vSelectSQLTextChanged or FAutoUpdateOptions.Modified) and FAutoUpdateOptions.AutoReWriteSqls then
    begin
      if not FAutoUpdateOptions.UpdateOnlyModifiedFields then
        GenerateSQLs
      else
        with FAutoUpdateOptions do
        if Length(UpdateTableName)>0 then
        begin
          if IsBlank(KeyFields) then
            KeyFields := PrimaryKeyFields(FAutoUpdateOptions.ModifiedTableName);
          if IsBlank(KeyFields) then
            KeyFields := AllKeyFields(FAutoUpdateOptions.ModifiedTableName);

          RefreshSQL.Text :=
            GenerateSQLText(UpdateTableName, KeyFields, skRefresh);
          DeleteSQL.Text :=
            GenerateSQLText(UpdateTableName, KeyFields, FIBDataSet.skDelete);
        end;
        FAutoUpdateOptions.Modified:=False
      end;

  FUpdatesPending := False;

  //
  if (GlobalContainer<>nil) and (FContainer<>GlobalContainer) then
   GlobalContainer.DataSetEvent(Self, deAfterOpen);
  if FContainer <> nil then
    FContainer.DataSetEvent(Self, deAfterOpen);

  if not (csDesigning in ComponentState) then
    if (AutoUpdateOptions.AutoParamsToFields) and
      (FSQLTextChanges < QSelect.SQLTextChangeCount) then
    begin
      FSQLTextChanges := QSelect.SQLTextChangeCount;
      ParseParamToFieldsLinks(AutoUpdateOptions.ParamsToFieldsLinks);
    end;
  inherited;
end;

// Filter works

procedure TpFIBDataSet.AddedFilterRecord(DataSet: TDataSet; var Accept:
  Boolean);
begin
  // abstract method
end;

function TpFIBDataSet.IsVisible(Buffer: TRecordBuffer): Boolean;
var
  OldState: TDataSetState;
  FR: integer;
begin
  if drsInMoveRecord in FRunState then
  begin
    result := True;
    exit;
  end;
    
  Result := inherited IsVisible(Buffer);
  FR := PRecordData(Buffer)^.rdRecordNumber + 1;
  if not Result then
    FFilteredCacheInfo.NonVisibleRecords.Add(FR);
  if drsInApplyUpdates in FRunState then
    Exit;
  OldState := State;
  if Filtered and Result then
  try
    SetTempState(dsFilter);
    FCurrentRecord :=PRecordData(Buffer)^.rdRecordNumber;
    if Result and Filtered then
    begin
      Include(FRunState,drsInFilterProc);
      if Assigned(FFilterParser) then
        Result := FFilterParser.BooleanResult;
      if Result then
        if Assigned(OnFilterRecord) then
          OnFilterRecord(Self, Result);
    end;
    if Result then
      AddedFilterRecord(Self, Result);
    if not Result then
      FFilteredCacheInfo.NonVisibleRecords.Add(FR)
    else
      FFilteredCacheInfo.NonVisibleRecords.Remove(FR)
  finally
    RestoreState(OldState);
    Exclude(FRunState,drsInFilterProc);
  end;
end;

function TpFIBDataSet.RecordCountFromSrv: integer;
var
  i: integer;
  s: string;
begin
  Result := 0;
  if (QSelect.Transaction = nil) or (not QSelect.Transaction.Active) then
    Exit;
  with vQryRecordCount do
  try
    Close;
    if QSelect.Database <> Database then
      Database := QSelect.Database;
    if QSelect.Transaction <> Transaction then
      Transaction := QSelect.Transaction;
    s := '';
    if Assigned(FOnAskRecordCount) then
      FOnAskRecordCount(Self, s);
    if s = '' then
     if Database.IsFirebirdConnect and (Database.ServerMajorVersion>=2) then
       s := 'Select Count(*) from ('+QSelect.ReadySQLText(False)+')'
     else
       s := CountSelect(QSelect.ReadySQLText(False));
    if (s + #13#10) <> SQL.Text then
      SQL.Text := s;
    if SQL.Text = '' then
      Exit;
    for i := 0 to Pred(Params.Count) do
      Params[i].Value := QSelect.Params.ByName[Params[i].Name].Value;
    Prepare;
    for i := 0 to Pred(OnlySrvParams.Count) do
      Params.ByName[OnlySrvParams[i]].Value :=
        QSelect.Params.ByName[OnlySrvParams[i]].Value;
    try
      ExecQuery;
      if Eof then
       Result := 0
      else 
       Result := Fields[0].asInteger ;
     vQryRecordCount.FreeHandle;  
    except
     on E:Exception do
      raise Exception.Create(
        Format(SFIBErrorUnableGetRecordCount, [CmpFullName(Self)])+#13#10+
         E.Message
        );
    end;
  finally
  end
end;


function TpFIBDataSet.GetFieldForTable(const Relation: string): TField;
var
  i: integer;
  q: string;
begin
  Result := nil;
  if Length(Relation) = 0 then Exit;
  if Relation[1]='"' then q:='"' else q:='';
  for i := 0 to Pred(FieldCount) do
    if (q+GetRelationTableName(Fields[i])+q = Relation)  then
    begin
      Result := Fields[i];
      Exit;
    end;
end;

function TpFIBDataSet.LockRecord(RaiseErr: boolean = True): TLockStatus;
var
  ExceptMessage: string;
  Retry: boolean;
  tf: TField;
  i: integer;
  UnknownErrorMsg, LockTxt: string;
  TableName: string;
  Where    : string;
begin
  LockTxt:='';
  if Assigned(FOnLockSQLText) then
  begin
    FOnLockSQLText(Self,LockTxt)
  end;

  if LockTxt='' then
  begin
    if (EmptyStrings(QUpdate.SQL) or
     (AutoUpdateOptions.AutoReWriteSqls and (AutoUpdateOptions.UpdateOnlyModifiedFields)))
    then
     with AutoUpdateOptions do
     if AutoReWriteSqls  then
     begin
      LockTxt :=UpdateTableName;
      if KeyFieldList.Count>0 then
      begin
       Where   :=KeyFieldList[0]+'=?'+KeyFieldList[0];
       for i:=1 to KeyFieldList.Count-1 do
        Where   :=Where+' and '+KeyFieldList[i]+'=?'+KeyFieldList[i];
      end
      else
       raise Exception.Create(SFIBErrorUnableLock)
     end
     else
      raise Exception.Create(SFIBErrorUnableLock)
    else
    begin
     LockTxt :=GetModifyTable(QUpdate.ReadySQLText(False),True);
     Where   :=QUpdate.WhereClause[1]
    end;
    if (LockTxt <> '') then
    begin
      TableName:=ExtractWord(1,LockTxt,CharsAfterClause);
      if poUseSelectForLock in Options then
      begin
          LockTxt :='SELECT 0 FROM ' + LockTxt + ' WHERE '+
          Where+ ' FOR UPDATE WITH LOCK';
      end
      else
      begin
        tf := GetFieldForTable(TableName);
        if tf <> nil then
        begin
          LockTxt :='UPDATE ' + LockTxt + ' SET '
            +FormatIdentifier(Database.SQLDialect, GetRelationFieldName(tf)) + '= ?'
            +FormatIdentifier(Database.SQLDialect, tf.FieldName) + ' WHERE '
            +Where;
        end
        else
          LockTxt := ''
      end;
    end;
  end;
  if LockTxt <> '' then
  begin
    if (vLockQry.SQL.Count=0) or (vLockQry.SQL.Text <> LockTxt + #13#10) then
      vLockQry.SQL.Text := LockTxt
  end
  else
    vLockQry.SQL.Assign(QUpdate.SQL);
  if vLockQry.Database <> Database then
    vLockQry.Database := Database;
  if vLockQry.Transaction <> UpdateTransaction then
    vLockQry.Transaction := UpdateTransaction;

  if not CachedUpdates and not (State in [dsEdit, dsInsert]) then
    SaveOldBuffer(GetActiveBuf);
  {$IFDEF D_XE4}
   SetQueryParams(vLockQry, Pointer(GetActiveBuf));
  {$ELSE}
   SetQueryParams(vLockQry, GetActiveBuf);
  {$ENDIF}
  if CachedUpdates then
    for i := 0 to Pred(vLockQry.Params.Count) do
    begin
      tf := FindField(vLockQry.Params[i].Name);
      if (tf <> nil) and not tf.IsBlob then
        if tf.isNull then
          vLockQry.Params[i].IsNull := True
        else
        if tf is TDateTimeField then
          vLockQry.Params[i].AsDateTime := tf.OldValue
        else
          vLockQry.Params[i].Value := tf.OldValue
    end;
  Result := lsUnknownError;
  Retry  := True;
  while Retry do
  begin
    try
      if (not UpdateTransaction.InTransaction) and (poStartTransaction in Options)
      then
        UpdateTransaction.StartTransaction;
      vLockQry.ExecQuery;
      if vLockQry.RowsAffected = 1 then
        Result := lsSuccess
      else
      if vLockQry.RowsAffected = 0 then
        Result := lsNotExist
      else
        Result := lsMultiply;
    except
      on E: EFIBError do
        case E.SQLCode of
         sqlcode_deadlock:
           Result := lsDeadLock;
         sqlcode_901 :
           if E.IBErrorCode= isc_lock_conflict then
            Result := lsDeadLock
           else
           begin
            UnknownErrorMsg := E.Message;
            Result := lsUnknownError
           end;
        else
          UnknownErrorMsg := E.Message;
          Result := lsUnknownError
        end;
    end;
    if (Result <> lsSuccess) and RaiseErr then
    begin
      case Result of
        lsDeadLock: ExceptMessage := SEdDeadLockMess;
        lsNotExist: ExceptMessage := SEdNotExistRecord;
        lsMultiply: ExceptMessage := SEdMultiplyRecord;
        lsUnknownError: ExceptMessage := UnknownErrorMsg;
      end;
      ExceptMessage := SEdErrorPrefix + ExceptMessage;
      Retry := RaiseLockError(Result, ExceptMessage) = daRetry
    end
    else
      Retry := False
  end;
end;
//


//  other routine stuff

procedure TpFIBDataSet.OpenWP(const ParamValues: array of Variant);
begin
  if High(ParamValues) > -1 then
    FQSelect.SetParamValues(ParamValues);
  Open
end;


procedure TpFIBDataSet.OpenWP(const ParamNames:string;const ParamValues: array of Variant);
begin
  FQSelect.SetParamValues(ParamNames,ParamValues);
  Open
end;

procedure TpFIBDataSet.OpenWPS(const ParamSources: array of ISQLObject);
begin
  AssignSQLObjectParams(Self,ParamSources);
  Open;
end;

procedure TpFIBDataSet.ReOpenWP(const ParamValues: array of Variant);
begin
  Close;
  OpenWP(ParamValues)
end;

procedure TpFIBDataSet.ReOpenWP(const ParamNames:string; const ParamValues: array of Variant);
begin
  Close;
  OpenWP(ParamNames,ParamValues)
end;

procedure TpFIBDataSet.ReOpenWPS(const ParamSources: array of ISQLObject);
begin
  Close;
  OpenWPS(ParamSources)
end;

procedure TpFIBDataSet.BatchRecordToQuery(ToQuery:TFIBQuery);
begin
  AssignSQLObjectParams(ToQuery,[Self]);
  ToQuery.ExecQuery;
end;

procedure TpFIBDataSet.BatchAllRecordsToQuery(ToQuery:TFIBQuery);
var
 {$IFDEF D2009+}
  OldBookMark:TBookmark;
 {$ELSE}
   OldBookMark:TBookmarkStr;
 {$ENDIF}
begin
  OldBookMark:=BookMark;
  DisableControls;
  DisableScrollEvents;
  try
   First;
   while not eof do
   begin
     BatchRecordToQuery(ToQuery);
     Next;
   end;
  finally
   BookMark:=OldBookMark;
   EnableControls;
   EnableScrollEvents;
  end;
end;

// Clone Records routine

function FieldInArray(Field: TField; Arr: array of const): boolean;
var
  i: integer;
  CI: boolean;
begin
  CI := True;
  if Field.DataSet is TFIBDataSet then
    if (TFIBDataSet(Field.DataSet).Database <> nil) then
      with TFIBDataSet(Field.DataSet).Database do
      begin
        CI := (SQLDialect < 3) or (UpperOldNames)
      end;
  Result := False;
  for i := Low(Arr) to High(Arr) do
    with Arr[i] do
    begin
      case VType of
        vtInteger: Result := Field.Index = VInteger;
        vtPChar:
          Result :=
            EquelNames(CI, Field.FieldName, vPChar);
        vtAnsiString:
          Result :=
            EquelNames(CI, Field.FieldName, string(VAnsiString));
        vtPointer:
          if TObject(VPointer) is TStrings then
            if CI then
              Result :=
                TStrings(VPointer).IndexOf(AnsiUpperCase(Field.FieldName)) <> -1
            else
              Result := TStrings(VPointer).IndexOf(Field.FieldName) <> -1
          else
          if TObject(VPointer) is TField then
            Result := VPointer = Field;
        vtObject:
          if VObject is TStrings then
            if CI then
              Result := TStrings(VObject).IndexOf(AnsiUpperCase(Field.FieldName))
                <> -1
            else
              Result := TStrings(VObject).IndexOf(Field.FieldName) <> -1
          else
          if VObject is TField then
            Result := VObject = Field;
        {$IFDEF D2009+}
        vtUnicodeString:
          Result :=
            EquelNames(CI, Field.FieldName, string(VString));
        {$ENDIF}
      end;
      if Result then
        Exit
    end;
end;

procedure TpFIBDataSet.CloneRecord(SrcRecord: integer; IgnoreFields: array of
  const);
var
  i, r: integer;
  ForceInsert: boolean;
begin
  if State = dsInsert then
    r := FRecordCount + 1
  else
    r := FRecordCount;
  if (SrcRecord > r) or (SrcRecord < 1) then
    Exit;
  ForceInsert := State <> dsInsert;
  if ForceInsert then
    Insert;
  for i := 0 to Pred(FieldCount) do
    if (Fields[i].FieldKind in [fkData])
      and not FieldInArray(Fields[i], IgnoreFields) then
    begin
      Fields[i].Value := RecordFieldValue(Fields[i], SrcRecord);
    end;
end;

procedure TpFIBDataSet.CloneCurRecord(IgnoreFields: array of const);
begin
  CloneRecord(GetRealRecno , IgnoreFields)
end;

// Wrappers


function TpFIBDataSet.FieldByFieldNo(FieldNo: Integer): TField;
begin
  Result:=FieldByNumber(FieldNo);
end;

// Containers stuff

{$IFDEF USE_DEPRECATE_METHODS2}
procedure TpFIBDataSet.SetReceiveEvents(Value: TStrings);
begin
  FReceiveEvents.Assign(Value)
end;
{$ENDIF}

procedure TpFIBDataSet.SetContainer(Value: TDataSetsContainer);
begin
  if FContainer <> Value then
  begin
    if FContainer <> nil then
      FContainer.RemoveDataSet(Self);
    FContainer := Value;
    if FContainer <> nil then
    begin
      FContainer.FreeNotification(Self);
      FContainer.AddDataSet(Self);
    end;
  end;
end;

procedure TpFIBDataSet.Notification(AComponent: TComponent; Operation: TOperation);
var
  i: integer;
begin
  inherited Notification(AComponent, Operation);
  case Operation of
    opRemove:
      if (AComponent = FContainer) then
        FContainer := nil
      else
      if (AComponent is TField) and not (csDestroying in ComponentState) then
      begin
        i := FFNFields.IndexOfObject(AComponent);
        if i <> -1 then
          FFNFields.Delete(i);
      end;
  end;
end;
{$IFDEF USE_DEPRECATE_METHODS2}
procedure TpFIBDataSet.DoUserEvent(Sender: TObject; const UDE: string; var Info:
  string);
begin
  if FastUpperCase(UDE) = 'CLOSE' then
    Close
  else
  if FastUpperCase(UDE) = 'OPEN' then
    Open
  else
  begin
   if (GlobalContainer<>nil) and (FContainer<>GlobalContainer) then
    GlobalContainer.UserEvent(Sender, Self, UDE, Info);
   if FContainer <> nil then
    FContainer.UserEvent(Sender, Self, UDE, Info);
  end;

  if Assigned(FOnUserEvent) then
    FOnUserEvent(Sender, Self, UDE, Info)

end;
{$ENDIF}

function  TpFIBDataSet.AddStatementToExecuteBlock(SK:TpSQLKind):boolean;
var
    s:string;
begin
 Result:=FBlockContextCount<255;
 if not Result then
 begin
  FExecBlockStatement.Add('END');
  Exit;
 end;
 if not Assigned(FExecBlockStatement) then
   FExecBlockStatement:=TStringList.Create;
 if FExecBlockStatement.Count=0 then
 begin
    FBlockContextCount:=0;
    FExecBlockStatement.Add('EXECUTE BLOCK AS BEGIN');
    FBlockSize:=Length(FExecBlockStatement[0])+2;
 end;
 with FAutoUpdateOptions do
   s := GenerateSQLTextNoParams(UpdateTableName, KeyFields, SK)+';';

 Result:=(FBlockSize+Length(s)+2)<High(Word)-3; // 3 for 'END'
 if Result then
 begin
  FExecBlockStatement.Add(s);
  Inc(FBlockSize,Length(s)+2);
  Inc(FBlockContextCount);
 end
 else
  FExecBlockStatement.Add('END');
end;

procedure TpFIBDataSet.AutoGenerateSQLText(ForState: TDataSetState);
var
  s: string;
  tmp:TIncludeFieldsToSQL;
begin
  with FAutoUpdateOptions do
   if UpdateOnlyModifiedFields and (KeyFields <> '')  and (UpdateTableName <> '')
   then
   begin
      if SeparateBlobUpdate then
       tmp:=ifsNoBlob
      else
       tmp:=ifsAllFields;
      case ForState of
        dsEdit:
          begin
            s := GenerateSQLText(UpdateTableName, KeyFields, skModify,tmp);
            if s <> UpdateSQL.Text then
              UpdateSQL.Text := s;
          end;
        dsInsert:
          begin
            s := GenerateSQLText(UpdateTableName, KeyFields, FIBDataSet.skInsert,tmp);
            if s <> InsertSQL.Text then
              InsertSQL.Text := s;
          end;
      end;
   end;
   GenerateUpdateBlobsSQL;   
end;
{$IFDEF D2006+}
function ExtractFieldName(const Fields: string; var Pos: Integer): string;
var
  I: Integer;
begin
  I := Pos;
  while (I <= Length(Fields)) and (Fields[I] <> ';') do Inc(I);
  Result := Trim(Copy(Fields, Pos, I - Pos));
  if (I <= Length(Fields)) and (Fields[I] = ';') then Inc(I);
  Pos := I;
end;
{$ENDIF}

function TpFIBDataSet.GenerateSQLTextNoParams
      (const TableName, KeyFieldNames: string; SK: TpSQLKind): string;
const
  Indent = ' ';
var
  i: integer;
  pWhereClause, InsValuesStr: string;
  AcceptCount: integer;
  RealKeyFieldName, RealFieldName: string;
  FieldTableName: string;
  FieldTableAlias: string;  
  KeyFieldList: TList;
  FormatTableName: string;
  RelTableName: string;
  vpFIBTableInfo: TpFIBTableInfo;
  vFi: TpFIBFieldInfo;
  vFieldName:string;
  vAliasTableName:string;
  fc:integer;
  OldForceIsNull  :boolean;
  vCanNtIncToWhere:boolean;
  vSQLTxt:string;

  procedure GetFieldList(List: TList; const FieldNames: string);
  var
    Pos: Integer;
    Field: TField;
  begin
    Pos := 1;
      while Pos <= Length(FieldNames) do
      begin
        Field := FN(ExtractFieldName(FieldNames, Pos));
        if Field <> nil then
          List.Add(Field);
      end;
  end;

  function ChangeToSQLDecimalSeparator(const Source:string):string;
  begin
    {$IFDEF D_XE3}with FormatSettings do{$ENDIF}
    if DecimalSeparator='.' then
      Result:=Source
    else
    begin
      Result:=ReplaceStr(Source,DecimalSeparator,'.')
    end;
  end;

  function FieldValueToStr(Field:TField;Old:boolean):string;
  var
     v:variant;
     sqlsubtype:integer;
  begin
   if Old then
    v:=Field.OldValue
   else
    v:=Field.Value;


   if VarIsNull(v) or VarIsEmpty(v) then
     Result:='NULL'
   else
   begin
     case Field.DataType of
      ftBCD,ftFloat:
       Result:=ChangeToSQLDecimalSeparator(VarToStr(v));
      ftDate,ftDateTime,ftTime:
         Result:=''''+VarToStr(v)+'''';
      ftString,ftWideString:
      begin
        if  Field is TFIBStringField then
          sqlsubtype:=TFIBStringField(Field).SqlSubType
        else
        if  Field is TFIBWideStringField then
          sqlsubtype:=TFIBWideStringField(Field).SqlSubType
        else
         sqlsubtype:=0;
        if DataBase.NeedUnicodeFieldTranslation(Byte(sqlsubtype))
          and   (Byte(sqlsubtype) in DataBase.UnicodeCharSets)
        then
         Result:=''''+UTF8Encode(v)+''''
        else
         Result:=''''+VarToStr(v)+'''';
      end
     else
      Result:=VarToStr(v)
     end
   end;
  end;


begin
  Result := '';
  if Length(TableName) = 0 then
    Exit;

  if FAutoUpdateOptions.UpdateTableName=TableName then
  begin
   FormatTableName :=FAutoUpdateOptions.ModifiedTableName;
   vAliasTableName :=FAutoUpdateOptions.AliasModifiedTable;
  end
  else
  begin
   with Database do
     if PosAlias(TableName)=0 then
     begin
      FormatTableName :=EasyFormatIdentifier(SQLDialect, TableName,EasyFormatsStr);
      vAliasTableName :=FormatTableName;
     end
     else
     begin
      FormatTableName :=EasyFormatIdentifier(SQLDialect, CutTableName(TableName),EasyFormatsStr);
      vAliasTableName :=EasyFormatIdentifier(SQLDialect, CutAlias(TableName),EasyFormatsStr);
     end;
  end;


  if not FieldCount>0 then
    raise Exception.Create(
     Format(SFIBErrorGenerationError, [CmpFullName(Self), SQLKindNames[SK],
        TableName]));

  vpFIBTableInfo := ListTableInfo.GetTableInfo(Database, FormatTableName,False);
  if vpFIBTableInfo = nil then
      Exit;


 begin // begin create added where condition
  KeyFieldList  := TList.Create;
  try
    GetFieldList(KeyFieldList, KeyFieldNames);
    if KeyFieldList.Count = 0 then
      Exit;


    // Validate KeyFields
    pWhereClause := '';
    for I := Pred(KeyFieldList.Count) downto 0 do
    begin
      RelTableName :=
       EasyFormatIdentifier(Database.SQLDialect,
        GetRelationTableName(TObject(KeyFieldList[i])),
         False
       );

//      if RelTableName <> FormatTableName then
      if not IsEquelSQLNames(RelTableName,FormatTableName) then
      begin
        KeyFieldList.Delete(i);
        Continue;
      end;

      RealKeyFieldName :=
       EasyFormatIdentifier(Database.SQLDialect,
        GetRelationFieldName(TObject(KeyFieldList[i])),
        False
       );
      vFi := vpFIBTableInfo.FieldInfo(RealKeyFieldName);
      if (vFi = nil) then
       vCanNtIncToWhere:=not IsDBKeyField(KeyFieldList[i])
      else
       vCanNtIncToWhere:=not vFi.CanIncToWhereClause;
      if vCanNtIncToWhere then
        KeyFieldList.Delete(i)
      else
      begin
        vFieldName:=TField(KeyFieldList[i]).FieldName;
        pWhereClause := pWhereClause + iifStr(pWhereClause = '', '', ' and ') +
          vAliasTableName + '.' + RealKeyFieldName + '=' +FieldValueToStr(TField(KeyFieldList[i]),True)
      end;
    end;
    if KeyFieldList.Count = 0 then
    begin
      raise Exception.Create(
        Format(SFIBErrorGenerationError, [CmpFullName(Self), SQLKindNames[SK],
        TableName])
          )
    end;
  finally
    KeyFieldList.Free
  end;
  OldForceIsNull:=not (qoNoForceIsNull in FQSelect.Options);
  try
    if OldForceIsNull then
     FQSelect.Options:=FQSelect.Options+[qoNoForceIsNull];
    vSQLTxt:=FQSelect.ReadySQLText(False); // SetMacro
  finally
    if OldForceIsNull then
     FQSelect.Options:=FQSelect.Options-[qoNoForceIsNull]
  end;
  with FAutoUpdateOptions do
  begin
    ReadySelectSQL:=vSQLTxt
  end;
 end;

  // end create added where condition


    case SK of
      skModify: Result := 'Update ' + FormatTableName+' '+vAliasTableName + ' Set';
      FIBDataSet.skInsert:
        begin
          Result := 'Insert into ' + FormatTableName + '(';
          InsValuesStr := 'values (';
        end;
      FIBDataSet.skDelete:
        begin
          Result := 'Delete from ' + FormatTableName +' '+vAliasTableName+ CLRF +
            'where ' + pWhereClause;
          Exit;
        end;
      skRefresh:
      begin
        Result :=
          AddToWhereClause(vSQLTxt, pWhereClause, True);
        Result :=SetOrderClause( Result,'' );
        Exit;
      end;
    end;


    AcceptCount := 0;


    fc:=FieldCount-1;
    for i := 0 to fc do
    begin
      begin
       if (Fields[i].FieldKind <> fkData) then
        Continue;

       if SK <> FIBDataSet.skDelete then
        if FAutoUpdateOptions.UpdateOnlyModifiedFields then
        begin
            case SK of
              skModify:
                begin
                  if not Fields[i].IsBlob then
                  begin
                    case Fields[i].DataType of
                     ftLargeint:
                      if TLargeintField(Fields[i]).Value = TFIBLargeintField(Fields[i]).OldValue then
                       Continue;
                     ftBCD     :
                      if not  TFIBBCDField(Fields[i]).FieldModified  then
                       Continue;
                     ftBytes   :;
                    else
                     if Fields[i].OldValue = Fields[i].Value then
                      Continue
                    end
                  end
                  else
                  if not BlobModified(Fields[i]) then
                    Continue;
                end;
              FIBDataSet.skInsert:
               if Fields[i].IsNull then    Continue;
            end;
        end;

       FieldTableName :=
        EasyFormatIdentifier(Database.SQLDialect,
         GetRelationTableName(Fields[i]),    False
        );
       FieldTableAlias:=TableAliasForField(Fields[i].FieldName)
      end;

      if (FieldTableName <> FormatTableName) or (FieldTableAlias<>vAliasTableName) then
        Continue
      else
      if FAutoUpdateOptions.ModifiedTableHaveAlias then
       begin
        if not IsEquelSQLNames(TableAliasForField(Fields[i].FieldName),vAliasTableName) then
          Continue
       end;

      RealFieldName :=
        EasyFormatIdentifier(Database.SQLDialect,GetRelationFieldName(Fields[i]), False);
      vFieldName:=Fields[i].FieldName ;

      vFi := vpFIBTableInfo.FieldInfo(RealFieldName);
      if
       (vFi = nil) or (vFi.IsComputed and not (psCanEditComputedFields in PrepareOptions))
      then
        Continue;
      Inc(AcceptCount);
      Result := Result + iifStr(AcceptCount = 1, '', ',') ;
      InsValuesStr := InsValuesStr + iifStr(AcceptCount = 1, '', ',') ;
      case SK of
        skModify: Result := Result + Indent + RealFieldName + '='+FieldValueToStr(FBN(vFieldName),False);
        FIBDataSet.skInsert:
          begin
            Result := Result + Indent + RealFieldName;
            InsValuesStr := InsValuesStr + Indent +FieldValueToStr(FBN(vFieldName),False);
          end;
      end;
    end; // end for
    if AcceptCount = 0 then
    begin
      Result := '';
    end
    else
    case SK of
      skModify:
       Result := Result +  ' where ' + pWhereClause;
      FIBDataSet.skInsert:
       Result := Result + CLRF + ')' + InsValuesStr + ')';
    end;
end;

{$WARNINGS OFF}

function TpFIBDataSet.GenerateSQLText
  (const TableName, KeyFieldNames: string; SK: TpSQLKind; IncludeFields:TIncludeFieldsToSQL=ifsAllFields;
     ReturningFields: TSetReturningFields=[]
  ): string;
const
  Indent = '     ';
var
  i: integer;
  pWhereClause, InsValuesStr: string;
  AcceptCount: integer;
  RealKeyFieldName, RealFieldName: string;
  FieldTableName: string;
  FieldTableAlias: string;  
  KeyFieldList: TList;
  FormatTableName: string;
  RelTableName: string;
  vpFIBTableInfo: TpFIBTableInfo;
  vFi: TpFIBFieldInfo;
  vFieldName:string;
  vAliasTableName:string;
  fc:integer;
  vFieldsCreated  :boolean;
  OldForceIsNull  :boolean;
  vCanNtIncToWhere:boolean;
  vSQLTxt:string;
  sReturningFields:string;

  procedure GetFieldList(List: TList; const FieldNames: string);
  var
    Pos: Integer;
    Field: TField;
    FieldDef:TFieldDef;
  begin
    Pos := 1;
    if vFieldsCreated then
      while Pos <= Length(FieldNames) do
      begin
        Field := FN(ExtractFieldName(FieldNames, Pos));
        if Field <> nil then
          List.Add(Field);
      end
    else
      while Pos <= Length(FieldNames) do
      begin
        FieldDef := FieldDefs.Find(ExtractFieldName(FieldNames, Pos));
        if FieldDef <> nil then
          List.Add(FieldDef);
      end
  end; 
begin
  Result := '';
  if Length(TableName) = 0 then
    Exit;
  sReturningFields:='';
  if FAutoUpdateOptions.UpdateTableName=TableName then
  begin
   FormatTableName :=FAutoUpdateOptions.ModifiedTableName;
   vAliasTableName :=FAutoUpdateOptions.AliasModifiedTable;
  end
  else
  begin
   with Database do
     if PosAlias(TableName)=0 then
     begin
      FormatTableName :=EasyFormatIdentifier(SQLDialect, TableName,EasyFormatsStr);
      vAliasTableName :=FormatTableName;
     end
     else
     begin
      FormatTableName :=EasyFormatIdentifier(SQLDialect, CutTableName(TableName),EasyFormatsStr);
      vAliasTableName :=EasyFormatIdentifier(SQLDialect, CutAlias(TableName),EasyFormatsStr);
     end;
  end;

  vFieldsCreated:=FieldCount>0;
  if FAutoUpdateOptions.UpdateOnlyModifiedFields and  not vFieldsCreated then
    Exit;
  if not vFieldsCreated then
    FieldDefs.Update;
  vpFIBTableInfo := ListTableInfo.GetTableInfo(Database, FormatTableName,False);
  if vpFIBTableInfo = nil then
      Exit;

 if (Length(FAutoUpdateOptions.WhereCondition)=0) or
  ((rfKeyFields in ReturningFields) and not (rfAll in ReturningFields))
 then
 begin // begin create added where condition
  KeyFieldList  := TList.Create;
  try
    GetFieldList(KeyFieldList, KeyFieldNames);
    if KeyFieldList.Count = 0 then
      Exit;


    // Validate KeyFields
    pWhereClause := '';
    for I := Pred(KeyFieldList.Count) downto 0 do
    begin
      RelTableName :=
       EasyFormatIdentifier(Database.SQLDialect,
        GetRelationTableName(TObject(KeyFieldList[i])),
         False
       );

//      if RelTableName <> FormatTableName then
      if not IsEquelSQLNames(RelTableName,FormatTableName) then
      begin
        KeyFieldList.Delete(i);
        Continue;
      end;
      RealKeyFieldName :=
       EasyFormatIdentifier(Database.SQLDialect,
        GetRelationFieldName(TObject(KeyFieldList[i])),
        False
       );
      vFi := vpFIBTableInfo.FieldInfo(RealKeyFieldName);
      if (vFi = nil) then
       vCanNtIncToWhere:=not IsDBKeyField(KeyFieldList[i])
      else
       vCanNtIncToWhere:=not vFi.CanIncToWhereClause;
      if vCanNtIncToWhere then
        KeyFieldList.Delete(i)
      else
      begin
        if vFieldsCreated then
          vFieldName:=TField(KeyFieldList[i]).FieldName
        else
         vFieldName:=TFieldDef(KeyFieldList[i]).Name;

        pWhereClause := pWhereClause + iifStr(pWhereClause = '', '', ' and ') +
          vAliasTableName + '.' + RealKeyFieldName + '=?' +
          EasyFormatIdentifier(
           Database.SQLDialect, 'OLD_' + vFieldName,
           False
          );
        if (rfKeyFields in ReturningFields) and not(rfAll in ReturningFields) then
         sReturningFields:=sReturningFields+RealKeyFieldName+','
      end;
    end;
    if KeyFieldList.Count = 0 then
    begin
      raise Exception.Create(
        Format(SFIBErrorGenerationError, [CmpFullName(Self), SQLKindNames[SK],
        TableName])
          )
    end;
  finally
    KeyFieldList.Free
  end;
  OldForceIsNull:=not (qoNoForceIsNull in FQSelect.Options);
  try
    if OldForceIsNull then
     FQSelect.Options:=FQSelect.Options+[qoNoForceIsNull];
    vSQLTxt:=FQSelect.ReadySQLText(False); // SetMacro
  finally
    if OldForceIsNull then
     FQSelect.Options:=FQSelect.Options-[qoNoForceIsNull]
  end;
  with FAutoUpdateOptions do
  begin
    WhereCondition:=pWhereClause;
    ReadySelectSQL:=vSQLTxt
  end;
 end
 else
 begin
   pWhereClause:=FAutoUpdateOptions.WhereCondition;
   vSQLTxt     :=FAutoUpdateOptions.ReadySelectSQL
 end;

  // end create added where condition


    case SK of
      skModify: Result := 'Update ' + FormatTableName+' '+vAliasTableName + ' Set';
      FIBDataSet.skInsert:
        begin
          Result := 'Insert into ' + FormatTableName + '(';
          InsValuesStr := 'values (';
        end;
      FIBDataSet.skDelete:
        begin
          Result := 'Delete from ' + FormatTableName +' '+vAliasTableName+ CLRF +
            'where ' + pWhereClause;
          Exit;
        end;
      skRefresh:
      begin
        Result :=
          AddToWhereClause(vSQLTxt, pWhereClause, True);
        Result :=SetOrderClause( Result,'' );
        Exit;
      end;
    end;


    AcceptCount := 0;

    if vFieldsCreated then
     fc:=FieldCount-1
    else
     fc:=FieldDefs.Count-1;
    for i := 0 to fc do
    begin
      if vFieldsCreated then
      begin
       if (Fields[i].FieldKind <> fkData) then
        Continue;
       case IncludeFields of
        ifsNoBlob:
          if Fields[i].IsBlob then
            Continue;
        ifsOnlyBlob:
          if not Fields[i].IsBlob then
            Continue;
       end;

       if SK <> FIBDataSet.skDelete then
        if FAutoUpdateOptions.UpdateOnlyModifiedFields then
        begin
            case SK of
              skModify:
                begin
                  if not Fields[i].IsBlob then
                  begin
                    case Fields[i].DataType of
                     ftLargeint:
                      if TLargeintField(Fields[i]).Value = TFIBLargeintField(Fields[i]).OldValue then
                       Continue;
                     ftBCD     :
                      if not  TFIBBCDField(Fields[i]).FieldModified  then
                       Continue;
                     ftBytes   :;
                    else
                     if Fields[i].OldValue = Fields[i].Value then
                      Continue
                    end
                  end
                  else
                  if not BlobModified(Fields[i]) then
                    Continue;
                end;
              FIBDataSet.skInsert: if Fields[i].IsNull then
                  Continue;
            end;
        end;

       FieldTableName :=
        EasyFormatIdentifier(Database.SQLDialect,
         GetRelationTableName(Fields[i]),    False
        );
       FieldTableAlias:=TableAliasForField(Fields[i].FieldName)
      end
      else
      begin
       FieldTableName :=
        EasyFormatIdentifier(Database.SQLDialect,
         GetRelationTableName(FieldDefs[i]),
         False
        );
       FieldTableAlias:=TableAliasForField(FieldDefs[i].Name)
      end;

      if (FieldTableName <> FormatTableName) or (FieldTableAlias<>vAliasTableName) then
        Continue
      else
      if vFieldsCreated and FAutoUpdateOptions.ModifiedTableHaveAlias then
       begin
        if not IsEquelSQLNames(TableAliasForField(Fields[i].FieldName),vAliasTableName) then
          Continue
       end;

      if vFieldsCreated then
      begin
       RealFieldName :=
        EasyFormatIdentifier(Database.SQLDialect,GetRelationFieldName(Fields[i]), False);
       vFieldName:=Fields[i].FieldName ;
      end
      else
      begin
       RealFieldName :=
        EasyFormatIdentifier(Database.SQLDialect,
          GetRelationFieldName(FieldDefs[i]), False
        );
       vFieldName:=FieldDefs[i].Name;
      end;
      vFi := vpFIBTableInfo.FieldInfo(RealFieldName);
      if
       (vFi = nil) or (vFi.IsComputed and not (psCanEditComputedFields in PrepareOptions))
      then
        Continue;
      Inc(AcceptCount);
      Result := Result + iifStr(AcceptCount = 1, '', ',') + CLRF;
      InsValuesStr := InsValuesStr + iifStr(AcceptCount = 1, '', ',') + CLRF;
      case SK of
        skModify:
        begin
         Result := Result + Indent + RealFieldName + '=?' +
          EasyFormatIdentifier(Database.SQLDialect, 'NEW_' +
            vFieldName, False
          );
         if (rfAll in ReturningFields) then
          sReturningFields:=sReturningFields+RealFieldName+','
         else
         if (rfBlobFields in ReturningFields) and  Fields[i].IsBlob then
          sReturningFields:=sReturningFields+RealFieldName+','
        end;
        FIBDataSet.skInsert:
          begin
            Result := Result + Indent + RealFieldName;
            InsValuesStr := InsValuesStr + Indent + '?' +
              EasyFormatIdentifier(Database.SQLDialect,
              'NEW_' + vFieldName, False
              );
           if (rfAll in ReturningFields) then
            sReturningFields:=sReturningFields+RealFieldName+','
           else
           if (rfBlobFields in ReturningFields) and  Fields[i].IsBlob then
            sReturningFields:=sReturningFields+RealFieldName+','
          end;
      end;
    end; // end for
    if AcceptCount = 0 then
    begin
      Result := SNoAction;
    end
    else
    case SK of
      skModify:
       Result := Result + CLRF + 'where ' + pWhereClause;
      FIBDataSet.skInsert:
       Result := Result + CLRF + ')' + CLRF + InsValuesStr + CLRF + ')';
    end;
    if Length(sReturningFields)>0 then
    begin
     SetLength(sReturningFields,Length(sReturningFields)-1);
     Result := Result + CLRF +'RETURNING '+sReturningFields
    end;
    if FAutoUpdateOptions.UseRowsClause then
     Result:=Result + CLRF +' ROWS 1'
end;


function TpFIBDataSet.GenerateSQLTextWA
  (const TableName: string; SK: TpSQLKind;  IncludeFields:TIncludeFieldsToSQL=ifsAllFields): string; // Where All
begin
  Result := GenerateSQLText(TableName, AllKeyFields(TableName), SK, IncludeFields)
end;

//AutoUpdate operations

function TpFIBDataSet.KeyField: TField;
begin
  with FAutoUpdateOptions do
    Result := FindField(KeyFields)
end;

function TpFIBDataSet.SqlTextGenID: string;
begin
  with FAutoUpdateOptions do
    Result := 'SELECT GEN_ID(' +
      FormatIdentifier(Database.SQLDialect, GeneratorName) +
      ',1) FROM  RDB$DATABASE';
end;

procedure TpFIBDataSet.IncGenerator;
var
  kf: TField;
  //    GenName:string;
begin
  with FAutoUpdateOptions do
    if WhenGetGenID = wgNever then
      Exit;
  if (drsInCacheRefresh in FRunState) then
    Exit;
  if not Assigned(DataBase) then
    FIBError(feDatabaseNotAssigned, [CmpFullName(Self)]);
  kf := KeyField;
  if (kf = nil) or not (kf is TNumericField) then
    Exit;
  if kf.IsNull then
  begin
    if (kf is TFIBBCDField) and (TFIBBCDField(kf).Size = 0) then
      TFIBBCDField(kf).asInt64 :=
        DataBase.Gen_Id(
         FAutoUpdateOptions.GeneratorName,
         FAutoUpdateOptions.GeneratorStep, Transaction
        )
    else
    if kf is TLargeintField then
      TLargeintField(kf).AsLargeInt :=
        DataBase.Gen_Id(FAutoUpdateOptions.GeneratorName,
         FAutoUpdateOptions.GeneratorStep, Transaction
        )
    else
      kf.AsInteger :=
        DataBase.Gen_Id(FAutoUpdateOptions.GeneratorName,
         FAutoUpdateOptions.GeneratorStep, Transaction
        );
   FGeneratorBeUsed:=True        
  end;
end;

function TpFIBDataSet.AllKeyFields(const TableName: string): string;
var
  i: integer;
begin
  Result := '';
  if TableName='' then 
    Exit;
  for i := 0 to Pred(FieldCount) do
   if not Fields[i].IsBlob then
    if GetRelationTableName(Fields[i])=TableName then
     Result := Result + iifStr(Length(Result) > 0, ';', '') + Fields[i].FieldName;
end;

procedure TpFIBDataSet.GenerateUpdateBlobsSQL;
begin
    with FAutoUpdateOptions do
    if SeparateBlobUpdate and (BlobFieldCount>0) then
    begin
      if FBlobsUpdate=nil then
       FBlobsUpdate:=TpFIBUpdateObject.Create(Self);
      with FBlobsUpdate do
      begin
        Database    :=Self.Database;
        Transaction :=UpdateTransaction;
        ExecuteOrder:=oeAfterDefault;
        KindUpdate  :=ukModify;
        DataSet     :=Self;
        FBlobsUpdate.SQL.Text:=
         GenerateSQLText(UpdateTableName, KeyFields, skModify,ifsOnlyBlob);
        if (SQL.Count>0) and (SQL[0]<>SNoAction) then
          Active:=True;
      end;
    end;
end;

procedure TpFIBDataSet.GenerateSQLs;
var
  tmp:TIncludeFieldsToSQL;
begin
  QDelete.OnSQLChanging := nil;
  QInsert.OnSQLChanging := nil;
  QUpdate.OnSQLChanging := nil;
  QRefresh.OnSQLChanging := nil;
  if FieldDefs.Count=0 then
   FieldDefs.Update;
  with FAutoUpdateOptions do
  try
    if IsBlank(KeyFields) then
      KeyFields := PrimaryKeyFields(FAutoUpdateOptions.ModifiedTableName);
    if IsBlank(KeyFields) then
      KeyFields := AllKeyFields(FAutoUpdateOptions.ModifiedTableName);
    if IsBlank(KeyFields) then
      Exit;
    if CanChangeSQLs or (EmptyStrings(DeleteSQL)) then
      DeleteSQL.Text := GenerateSQLText(UpdateTableName, KeyFields, FIBDataSet.skDelete);


    if SeparateBlobUpdate then
     tmp:=ifsNoBlob
    else
     tmp:=ifsAllFields;
    if CanChangeSQLs or (EmptyStrings(UpdateSQL)) then
      UpdateSQL.Text := GenerateSQLText(UpdateTableName, KeyFields, skModify,tmp,UseReturningFields);
    if CanChangeSQLs or (EmptyStrings(InsertSQL)) then
      InsertSQL.Text := GenerateSQLText(UpdateTableName, KeyFields, FIBDataSet.skInsert,tmp,UseReturningFields);
    GenerateUpdateBlobsSQL;
    if CanChangeSQLs or (EmptyStrings(RefreshSQL)) then
      RefreshSQL.Text := GenerateSQLText(UpdateTableName, KeyFields, skRefresh);
  finally
    QDelete.OnSQLChanging := SQLChanging;
    QInsert.OnSQLChanging := SQLChanging;
    QUpdate.OnSQLChanging := SQLChanging;
    QRefresh.OnSQLChanging := SQLChanging;
  end;
end;

function TpFIBDataSet.CanGenerateSQLs: boolean;
begin
  Result := Length(AutoUpdateOptions.UpdateTableName) > 0;
end;

procedure TpFIBDataSet.CacheInsert(Value: Variant; DoRefresh: boolean = False);
begin
  CacheInsert([0], [Value]);
  if DoRefresh then
    Refresh
end;

procedure TpFIBDataSet.CacheAppend(Value: Variant; DoRefresh: boolean = False);
begin
  CacheAppend([0], [Value]);
  if DoRefresh then
    Refresh
end;

procedure TpFIBDataSet.CacheModify(
  aFields: array of integer; Values: array of Variant;  KindModify: byte 
);
var
  i: integer;
begin
  CheckBrowseMode;
  Include(FRunState,drsInCacheRefresh);
  try
    case KindModify of
      0: Edit;
      1: Insert;
      2: Append;
    end;
    for i := 0 to High(Values) do
      if i > High(aFields) then
        Break
      else
        Fields[aFields[i]].Value := Values[i]
          ;
    Post;
  finally
   Exclude(FRunState,drsInCacheRefresh);
  end;
end;

procedure TpFIBDataSet.CacheEdit(
  aFields: array of integer; Values: array of Variant
  );
begin
  CacheModify(aFields, Values, 0);
end;

procedure TpFIBDataSet.CacheAppend(
  aFields: array of integer; Values: array of Variant
  );
begin
  CacheModify(aFields, Values, 2);
end;

procedure TpFIBDataSet.CacheInsert(
  aFields: array of integer; Values: array of Variant
  );
begin
  CacheModify(aFields, Values, 1);
end;

procedure TpFIBDataSet.CacheRefresh(FromDataSet: TDataSet; Kind: TCachRefreshKind
  ; FieldMap: TStrings
  );
var
  i: integer;
  fn1: Tfield;
  Buff: TRecordBuffer;
  sfn: string;
  ForcedEdit: boolean;
  IsReadOnlyField: boolean;
begin
  if not (State in [dsInsert, dsEdit]) then
    Include(FRunState,drsInCacheRefresh);
  try
    ForcedEdit := not (State in [dsInsert, dsEdit]);
    if ForcedEdit then
      if Kind = frkInsert then
        Insert
      else
        Edit;
    for i := 0 to Pred(FromDataSet.FieldCount) do
    begin
      if (FieldMap <> nil) then
      begin
        sfn := FieldMap.Values[FromDataSet.Fields[i].FieldName];
        if sfn = '' then
          sfn := FromDataSet.Fields[i].FieldName;
      end
      else
        sfn := FromDataSet.Fields[i].FieldName;
      fn1 := FN(sfn);
      if fn1 <> nil then
      begin
        IsReadOnlyField := fn1.ReadOnly;
        fn1.ReadOnly := False;
        try
          fn1.Value := FromDataSet.Fields[i].Value;
        finally
          fn1.ReadOnly := IsReadOnlyField;
        end;
      end;
    end;
    if ForcedEdit then
      Post;
    Buff := GetActiveBuf;
    with PRecordData(Buff)^ do
    begin
      rdFlags:=Byte(cusUnmodified);
      WriteRecordCache(rdRecordNumber, Buff);
      SaveOldBuffer(Buff)
    end;
  finally
   Exclude(FRunState,drsInCacheRefresh);
  end
end;

procedure TpFIBDataSet.CacheRefreshByArrMap(
  FromDataSet: TDataSet; Kind: TCachRefreshKind;
  const SourceFields, DestFields: array of string
  );
var
  ts: TStrings;
  i, m: integer;

begin
  ts := TStringList.Create;
  m := High(SourceFields);
  if High(DestFields) > m then
    m := High(DestFields);
  with ts do
  try
    for i := 0 to m do
      Values[SourceFields[i]] := DestFields[i];
    CacheRefresh(FromDataSet, Kind, ts);
  finally
    Free
  end;
end;

procedure TpFIBDataSet.RefreshFromQuery(RefreshQuery:TFIBQuery;const KeyFields:string;
 IsDeletedRecords:boolean=False;
 DoAdditionalRefreshRec:boolean=False
);
var
    fl: TFIBList;
    p : TFIBXSQLVAR;
    KeyValues : array of Variant;
    SrcKeys   : array of TFIBXSQLVAR;
    SrcValues : array of TFIBXSQLVAR;
    EditFields: array of integer;
    Values    : array of Variant;
    i,j:integer;
    CurRec    : integer;
    OldActiveRecord:integer;
begin
 fl:= TFIBList.Create;
 CurRec    :=GetRecno;
 DisableControls;
 DisableScrollEvents;
 OldActiveRecord:=ActiveRecord;
 try
   GetFieldList(fl, KeyFields);
   if fl.Count>0 then
   with RefreshQuery do
   begin

    for i:= 0 to Pred(Self.ParamCount) do
    begin
     p:=FindParam(Self.Params[i].Name);
     if p<>nil then
      p.Value:=Self.Params[i].Value
    end;

    ExecQuery;
    if Eof then
     Exit;


    SetLength(SrcKeys,fl.Count);
    for i:=0 to fl.Count-1 do
     SrcKeys[i]:=RefreshQuery.FieldByName(TField(fl.List^[i]).FieldName);

    SetLength(KeyValues,fl.Count);

    if not DoAdditionalRefreshRec then
    begin

      SetLength(SrcValues,Self.FieldCount);
      SetLength(EditFields,Self.FieldCount);
      j:=0;
      for i:=0 to Self.FieldCount-1 do
      begin
       SrcValues[i]:=RefreshQuery.FindField(Self.Fields[i].FieldName);
       if  SrcValues[i]<>nil then
       begin
        EditFields[j]:=i;
        Inc(j)
       end;
      end;
      SetLength(EditFields,j);
      SetLength(Values,j);
    end
    else
    begin
      SetLength(SrcValues,fl.Count);
      SetLength(EditFields,fl.Count);
      SetLength(Values,fl.Count);
      for i:=0 to fl.Count-1 do
      begin
        EditFields[i]:=TField(fl.List^[i]).Index;
        SrcValues[i]:=RefreshQuery.FindField(TField(fl.List^[i]).FieldName);
      end
    end;

    if not GoToFirstRecordOnExecute then
      Next;
    while not Eof do
    begin
     for i:=0 to fl.Count-1 do
       KeyValues[i]:=SrcKeys[i].Value;

     if Locate(KeyFields, KeyValues,[]) then
     begin
      if IsDeletedRecords then
       CacheDelete
      else
      if not DoAdditionalRefreshRec then
      begin
       for i:=0 to Length(EditFields)-1 do
        Values[i]:=SrcValues[EditFields[i]].Value;
       CacheEdit(EditFields,Values)
      end
    end  // Locate
    else
    begin
       for i:=0 to Length(EditFields)-1 do
        Values[i]:=SrcValues[EditFields[i]].Value;
       CacheAppend(EditFields,Values);
       if Sorted then
        MoveRecordToOrderPos;
    end;
    if DoAdditionalRefreshRec then
     Refresh; // For Record which anymore approach conditions

    Next;
   end
  end
 finally
  Recno:=CurRec;
  SetRecordPosInBuffer(OldActiveRecord);
  EnableControls;
  EnableScrollEvents;
  fl.Free
 end
end;


procedure TpFIBDataSet.RefreshFromDataSet(RefreshDataSet:TDataSet;const KeyFields:string;
     IsDeletedRecords:boolean=False;     DoAdditionalRefreshRec:boolean=False
);
var
    fl: TFIBList;
    p : TFIBXSQLVAR;
    KeyValues : array of Variant;
    SrcKeys   : array of TField;
    i:integer;
    CurRec    : integer;
    OldActiveRecord:integer;
    OldFiltered:boolean;
begin
 fl:= TFIBList.Create;
 CurRec    :=GetRecno;
 DisableControls;
 DisableScrollEvents;
 OldActiveRecord:=ActiveRecord;
 OldFiltered:=Filtered;
 try
   Filtered:=False;
   GetFieldList(fl, KeyFields);

    if not RefreshDataSet.Active then
    begin
     if RefreshDataSet is TFIBDataSet then
      for i:= 0 to Pred(Self.ParamCount) do
      begin
       p:=TFIBDataSet(RefreshDataSet).Params.ByName[Self.Params[i].Name];
       if p<>nil then
        p.Value:=Self.Params[i].Value
      end;
      RefreshDataSet.Open
    end;

   SetLength(SrcKeys,fl.Count);
   for i:=0 to fl.Count-1 do
     SrcKeys[i]:=RefreshDataSet.FieldByName(TField(fl.List^[i]).FieldName);
   SetLength(KeyValues,fl.Count);

   RefreshDataSet.First;
   while not RefreshDataSet.Eof do
   begin
     for i:=0 to fl.Count-1 do
       KeyValues[i]:=SrcKeys[i].Value;

    if Locate(KeyFields, KeyValues,[]) then
    begin
     if IsDeletedRecords then
      CacheDelete
     else
      CacheRefresh(RefreshDataSet, frkEdit, nil);
    end
    else
    if not IsDeletedRecords then
    begin
      CacheRefresh(RefreshDataSet, frkInsert, nil);
//      SaveToFile('c:\Logs\Err.dataset', IntToStr(KeyValues[0]));
    end;

    if DoAdditionalRefreshRec then
     Refresh; // For Record which anymore approach conditions

    RefreshDataSet.Next
   end;

 finally
  Recno:=CurRec;
  Filtered:=OldFiltered;
  SetRecordPosInBuffer(OldActiveRecord);
  EnableControls;
  EnableScrollEvents;
  fl.Free
 end;

end;

function TpFIBDataSet.RecordFieldAsFloat(Field: TField; RecNumber: integer;
  IsVisibleRecordNum: boolean = True): Double;
begin
  Result := 0;
  if (RecNumber > FRecordCount) then
    Exit;
  if IsVisibleRecordNum then
    vInspectRecno := VisibleRecnoToRecno(RecNumber)
  else
    vInspectRecno := RecNumber;
  try
    vTypeDispositionField := dfRRecNumber;
    Result := Field.AsFloat;
  finally
    vTypeDispositionField := dfNormal
  end;
end;


//     IProviderSupport
{$IFNDEF TWideDataSet}
function TpFIBDataSet.PSGetQuoteChar: string;
{$ELSE}
function TpFIBDataSet.PSGetQuoteCharW: WideString;
{$ENDIF}
begin
  Result := '';
  if Assigned(Database) and (Database.SQLDialect = 3) then
    Result := '"'
end;

{$IFNDEF TWideDataSet}
function TpFIBDataSet.PSGetTableName: string;
{$ELSE}
function TpFIBDataSet.PSGetTableNameW: WideString;
{$ENDIF}
var
  ts: TStrings;
begin
  Result := '';
  ts := TStringList.Create;
  try
    AllSQLTables(QSelect.ReadySQLText(False), ts);
    if ts.Count = 0 then
      Exit;
    if ts.IndexOf(AutoUpdateOptions.UpdateTableName) <> -1 then
      Result := AutoUpdateOptions.UpdateTableName
    else
      Result := ts[0]
  finally
    ts.Free;
  end;
end;

{$IFNDEF TWideDataSet}
function TpFIBDataSet.PSGetKeyFields: string;
{$ELSE}
function TpFIBDataSet.PSGetKeyFieldsW: WideString;
{$ENDIF}
begin
{$IFNDEF TWideDataSet}
  Result := inherited PSGetKeyFields;
{$ELSE}
  Result := inherited PSGetKeyFieldsW;
{$ENDIF}
  if Result = '' then
    Result := FAutoUpdateOptions.KeyFields;
end;

{$IFDEF TWideDataSet}
procedure TpFIBDataSet.PSSetCommandText(const CommandText: Widestring);
{$ELSE}
procedure TpFIBDataSet.PSSetCommandText(const CommandText: string);
{$ENDIF}
begin
 FMidasCommandText:='';
 if CommandText <> '' then
 begin
  if CommandText='FIB$COMMIT' then
   FMidasCommandText:=CommandText
  else
  if CommandText='FIB$ROLLBACK' then
   FMidasCommandText:=CommandText
  else
  if CommandText='FIB$GET_INTRANSACTION' then
   FMidasCommandText:=CommandText
  else
    SelectSQL.Text := CommandText;
 end
end;


{$IFDEF TWideDataSet}
function TpFIBDataSet.PSGetCommandTextW: WideString;
begin
 if FMidasCommandText='' then
  Result := SelectSQL.Text
 else
  Result :=FMidasCommandText
end;
{$ENDIF}


function TpFIBDataSet.PSGetUpdateException(E: Exception;
  Prev: EUpdateError): EUpdateError;
var
  ErrC: integer;
begin
  if E is EFIBError then
  begin
    if Prev <> nil then
      ErrC := Prev.ErrorCode
    else
      ErrC := 0;
    with EFIBError(E) do
      Result := EUpdateError.Create(Message, '', IBErrorCode, ErrC, E)
  end
  else
    Result := inherited PSGetUpdateException(E, Prev);
end;

function TpFIBDataSet.PSInTransaction: Boolean;
begin
  Result := UpdateTransaction.InTransaction;
end;

function TpFIBDataSet.PSIsSQLBased: Boolean;
begin
  Result := True;
end;

function TpFIBDataSet.PSIsSQLSupported: Boolean;
begin
  Result := True;
end;

procedure TpFIBDataSet.PSStartTransaction;
begin
  if not Assigned(Database) then
    FIBError(feDatabaseNotAssigned, [CmpFullName(Self)]);
  if not Assigned(UpdateTransaction) then
    FIBError(feTransactionNotAssigned, [CmpFullName(Self)]);
  if not Database.Connected then
    Database.Open;
  if not UpdateTransaction.InTransaction then
    UpdateTransaction.StartTransaction;
end;

procedure TpFIBDataSet.PSEndTransaction(Commit: Boolean);
begin
  if Assigned(UpdateTransaction) and UpdateTransaction.InTransaction then
    if Commit then
      UpdateTransaction.Commit
    else
      UpdateTransaction.RollBack
end;

type
  THackDS = class(TDataSet);

function TpFIBDataSet.PSUpdateRecord(UpdateKind: TUpdateKind;
  Delta: TDataSet): Boolean;

var
  UpdateAction: TFIBUpdateAction;
  j: integer;
  UpdQry: TFIBQuery;
  CurParam: TFIBXSQLVAR;
  ListUO: TList;
  NewBcd, OldBcd: TBcd;

  procedure ExecUpdate;
  var
    i: integer;
    OldVal, NewVal: variant;

    procedure SetParam;
    var
      lValue: Int64;
      lScale: byte;
      pValue: PBcd;
    begin
      if CurParam <> nil then
        case Delta.Fields[i].DataType of
        ftGuid:
          if VarIsEmpty(NewVal) then
            CurParam.AsGuid :=StringAsGuid(OldVal)
          else
          if VarToStr(NewVal)<>'' then
            CurParam.AsGuid :=StringAsGuid(NewVal)
          else
            CurParam.Clear;
        ftBcd :
         begin
          // Avoid variants
          if VarIsEmpty(NewVal) then
          begin
            if VarIsNull(OldVal) then
            begin
              CurParam.IsNull := True;
              Exit;
            end;
            pValue := @OldBcd;
          end
          else
          begin
            if VarIsNull(NewVal) then
            begin
              CurParam.IsNull := True;
              Exit;
            end;
            pValue := @NewBcd;
          end;
          BCDToInt64WithScale(pValue^, lValue, lScale);
          CurParam.AsInt64 := lValue;
          CurParam.Data.sqlscale := -lScale;
        end;
        else
          if VarIsEmpty(NewVal) then
            CurParam.Value := OldVal
          else
            CurParam.Value := NewVal;
        end 
    end;

  begin
    UpdQry.Prepare;
    for i := 0 to Pred(Delta.FieldCount) do
      with Delta.Fields[i] do
      begin
        if (UpdateKind=ukInsert) and
         (pfInKey in ProviderFlags)
        and (FieldName=AutoUpdateOptions.KeyFields)
        and (AutoUpdateOptions.GeneratorName<>'')
        and (AutoUpdateOptions.WhenGetGenID<>wgNever)
        then
        begin
            OldVal := unAssigned;
            {$IFDEF D6+}
             NewVal :=
              DataBase.Gen_Id(FAutoUpdateOptions.GeneratorName,
               FAutoUpdateOptions.GeneratorStep, Transaction
             )
            {$ELSE}
             NewVal :=
              Int(DataBase.Gen_Id(FAutoUpdateOptions.GeneratorName,
               FAutoUpdateOptions.GeneratorStep, Transaction
             ))

            {$ENDIF}
        end
        else
        if (DataType <> ftBcd) then
        begin
          OldVal := OldValue;
          NewVal := NewValue;
        end
        else
        begin
          try
            OldVal := OldValue;
          except
            on E: EOverFlow do
              OldVal := unAssigned
         // For read OldIsNull

          end;
          try
            NewVal := NewValue;
          except
             // For read NewIsNull
            on E: EOverFlow do
              NewVal := unAssigned
          end;

          if not VarIsNull(OldVal) then
            if GetBCDFieldData(Delta.Fields[i], True, OldBcd) then
              OldVal := '';
          if not VarIsNull(NewVal) then
            if GetBCDFieldData(Delta.Fields[i], False, NewBcd) then
              NewVal := '';
        end;

        CurParam := UpdQry.FindParam(FieldName);
        SetParam;
        CurParam := UpdQry.FindParam('NEW_' + FieldName);
        SetParam;
        CurParam := UpdQry.FindParam('OLD_' + FieldName);
        NewVal := unAssigned;
        SetParam;
      end;
    UpdQry.ExecQuery;
  end;

begin
  Result := False;
  if Assigned(OnUpdateRecord) then
  begin
    UpdateAction := uaFail;
    if Assigned(FOnUpdateRecord) then
    begin
      FOnUpdateRecord(Delta, UpdateKind, UpdateAction);
      Result := UpdateAction = uaApplied;
    end;
  end
  else
  begin
    Result := False;
    ListUO := ListForUO(UpdateKind);
    for j := 0 to Pred(ListUO.Count) do
      with TpFIBUpdateObject(ListUO[j]) do
        if Active and (ExecuteOrder = oeBeforeDefault) and (not
          EmptyStrings(SQL)) then
        begin
          UpdQry := TpFIBUpdateObject(ListUO[j]);
          ExecUpdate;
          Result := True;
        end;
    case UpdateKind of
      ukModify: UpdQry := QUpdate;
      ukInsert: UpdQry := QInsert;
    else
      UpdQry := QDelete;
    end;
    Result := Result or (UpdQry.SQL.Count > 0);
    if (not EmptyStrings(UpdQry.SQL)) then
      ExecUpdate;
    for j := 0 to Pred(ListUO.Count) do
      with TpFIBUpdateObject(ListUO[j]) do
        if Active and (ExecuteOrder = oeAfterDefault) and (not EmptyStrings(SQL))
          then
        begin
          UpdQry := TpFIBUpdateObject(ListUO[j]);
          ExecUpdate;
          Result := True;
        end;
  end;
  if Result and AutoCommit then
    AutoCommitUpdateTransaction
end;


function TpFIBDataSet.PSExecuteStatement(const ASQL: {$IFNDEF TWideDataSet} string{$ELSE} Widestring{$ENDIF}; AParams: TParams;
  ResultSet: Pointer = nil): Integer;
var
  vDataset: TpFIBDataSet;
  vQuery: TFIBQuery;
  i, j: Integer;
  sqlStr: string;

  procedure AssignParams(qry: TFIBQuery);
  var
    i: integer;
  begin
    for i := 0 to AParams.Count - 1 do
      qry.Params[i].Value := AParams[i].Value;
  end;

begin
  // Create SQLText
  sqlStr := ASQL;
  j := 0;
  repeat
    i := PosCh('?', sqlStr);
    if i > 0 then
    begin
      sqlStr := FastCopy(sqlStr, 1, i - 1) + ':Param' + IntToStr(j) + FastCopy(sqlStr, i
        + 1, MaxInt);
      Inc(j);
    end;
  until i = 0;

  if ResultSet = nil then
  begin
    vQuery := GetQueryForUse(UpdateTransaction, sqlStr);
    try
      AssignParams(vQuery);
      vQuery.ExecQuery;
      if vQuery.SQLType = SQLSelect then
      begin
        while not vQuery.Eof do
          vQuery.Next;
        Result := vQuery.RecordCount;
      end
      else
        Result := vQuery.RowsAffected;
    finally
      FreeQueryForUse(vQuery);
    end;
  end
  else
  begin
    vDataset := TpFIBDataSet.Create(nil);
    try
      vDataset.Database := Database;
      vDataset.Transaction := Transaction;
      if not Transaction.InTransaction then
        Transaction.StartTransaction;

      vDataset.SelectSQL.Text := sqlStr;

      AssignParams(vDataset.QSelect);
      vDataset.Open;
      if vDataset.QSelect.SQLType = SQLSelect then
      begin
        vDataset.FetchAll;
        Result := vDataset.RecordCount;
      end
      else
        Result := vDataset.QSelect.RowsAffected;
    finally
      if Assigned(ResultSet) then
        TDataSet(ResultSet^) := vDataset
      else
        vDataset.Free;
    end;
  end;

end;

procedure TpFIBDataSet.PSReset;
begin
  inherited PSReset;
  if Active then
  begin
    CloseOpen(False)
  end;
end;

procedure TpFIBDataSet.PSExecute;
begin
  if FMidasCommandText='FIB$COMMIT' then
    UpdateTransaction.Commit
  else
  if FMidasCommandText='FIB$ROLLBACK' then
    UpdateTransaction.RollBack
  else
  if FMidasCommandText='FIB$GET_INTRANSACTION' then
     //
  else
   QSelect.ExecQuery
end;

function TpFIBDataSet.PSGetParams: TParams;
var
  i: integer;
  CurParam: TParam;
  FldType: TFieldType;
begin
  if FMidasCommandText<>'' then
  begin
   if  (FMidasOutParams = nil) then
    FMidasOutParams := TParams.Create
   else
    FMidasOutParams.Clear;

   Result :=FMidasOutParams;

   if FMidasCommandText='GET_INTRANSACTION' then
   begin
      CurParam := FMidasOutParams.CreateParam(
       ftBoolean, 'Active', ptOutput
      );
      CurParam.AsBoolean :=UpdateTransaction.InTransaction
   end;

   FMidasCommandText:='';
   Exit;
  end;

  if  (FParams = nil) then
    FParams := TParams.Create
  else
    FParams.Clear;
  Result := FParams;
  for i := 0 to Pred(Params.Count) do
   begin
      case Params[i].SQLType of
        SQL_TEXT, SQL_VARYING: FldType := ftString;
        SQL_DOUBLE, SQL_FLOAT: FldType := ftFloat;
        SQL_SHORT: FldType := ftSmallint;
        SQL_LONG: FldType := ftInteger;
        SQL_INT64: if Params[i].Scale=0 then
                    FldType := ftLargeint
                   else
                   if Params[i].Scale<=-4 then
                    FldType := ftBCD
                   else
                    FldType := ftFloat; 
        SQL_TIMESTAMP: FldType := ftDateTime;
        SQL_TYPE_TIME: FldType := ftTime;
        SQL_TYPE_DATE: FldType := ftDate;
        SQL_BLOB, SQL_ARRAY: FldType := ftBlob;
      else
        FldType := ftString;
      end;
      CurParam := FParams.CreateParam(
       FldType, Params[i].Name, ptInput
      );
     CurParam.Value := Params[i].Value
   end;
end;

procedure TpFIBDataSet.PSSetParams(AParams: TParams);
var
  i: integer;
  CurParam: TFIBXSQLVAR;
begin
  if not QSelect.Prepared then
   QSelect.Prepare;
  if Assigned(AParams) then
    for i := 0 to Pred(AParams.Count) do
    begin
      CurParam := FindParam(AParams[i].Name);
      if CurParam <> nil then
        CurParam.Value := AParams[i].Value;
    end;
end;



function TpFIBDataSet.GetFIBVersion: string;
begin
  Result := IntToStr(FIBPlusVersion) + '.' + IntToStr(FIBPlusBuild) + '.' +
    IntToStr(FIBCustomBuild) + ' ' + FIBVersionNote
end;

procedure TpFIBDataSet.SetFIBVersion(const vs: string);
begin

end;

procedure TpFIBDataSet.ParseParamToFieldsLinks(Dest: TStrings);
var
  i, p: Integer;
  s, s1: string;
  TableAlias: string;
  tf: TField;
begin
  s := SelectSQL.Text;
  for i := 0 to Params.Count - 1 do
  begin
    s1 := FastTrim(GetLinkFieldName(s, Params[i].Name));
    if s1 <> '' then
    begin
      p := PosCh('.', s1);
      if p > 0 then
      begin
        TableAlias:=Copy(s1,  1, p - 1);
        s1:=FastCopy(s1,p+1,MaxInt);
//        System.Delete(s1, 1, p);
        DoTrim(TableAlias);
        DoTrim(s1);
        TableAlias := TableByAlias(s, TableAlias);
        if (s1 <> '') and (s1[1] <> '"') then
          s1 := FastUpperCase(s1);
        tf := FieldByOrigin(TableAlias,s1);
        if Assigned(tf) then
          s1 := tf.FieldName
      end
      else
      begin
        TableAlias := '';
        DoTrim(s1);
      end;
      if s1 <> '' then
        Dest.Values[s1] := Params[i].Name;
     end;
  end;
end;
end.

