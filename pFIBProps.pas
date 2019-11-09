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


unit pFIBProps;

interface

{$I FIBPlus.inc}
{$J+}
uses
   Classes,SysUtils,DB,IniFiles,FIBPlatforms;

type
  
  TKindOnOperation     =(koBefore,koAfter,koAfterFirstFetch,koOther);
  TpFIBExistObject     =(eoYes,eoNo,eoUnknown);

  TpPrepareOption=
   (pfSetRequiredFields,pfSetReadOnlyFields,pfImportDefaultValues,
    psUseBooleanField,psUseGuidField,psSQLINT64ToBCD,psApplyRepositary,psGetOrderInfo,
    psAskRecordCount,psCanEditComputedFields,psSetEmptyStrToNull,psSupportUnicodeBlobs,
    psUseLargeIntField
   );
  TpPrepareOptions=set of TpPrepareOption;

  TpFIBDsOption=
   (poTrimCharFields,poRefreshAfterPost,
     poRefreshDeletedRecord, poStartTransaction,poAutoFormatFields,poProtectedEdit,
     poUseSelectForLock,  poKeepSorting,
   {$IFDEF OBSOLETE_PROPS}
     poAllowChangeSqls,
   {$ENDIF}     
     poPersistentSorting,poVisibleRecno,poNoForceIsNull,poFetchAll,poFreeHandlesAfterClose
     ,poCacheCalcFields,poRefreshAfterDelete,poDontCloseAfterEndTransaction
   );
  TpFIBDsOptions= set of TpFIBDsOption;


  TpFIBQueryOption =(qoStartTransaction,qoAutoCommit,qoTrimCharFields,qoNoForceIsNull,
   qoFreeHandleAfterExecute);
  TpFIBQueryOptions=set of TpFIBQueryOption;

  TDetailCondition=(dcForceOpen,dcIgnoreMasterClose,dcForceMasterRefresh,
   dcWaitEndMasterScroll
  );

  TDetailConditions= set of TDetailCondition;
  TFieldOriginRule =(forNoRule,forTableAndFieldName,forClientFieldName,forTableAliasAndFieldName);

  TSQLs = class(TPersistent)
  private
   FOwner     :TComponent;
   function  GetSelectSQL:TStrings;
   procedure SetSelectSQL(Value:TStrings);
   function  GetInsertSQL:TStrings;
   procedure SetInsertSQL(Value:TStrings);
   function  GetUpdateSQL:TStrings;
   procedure SetUpdateSQL(Value:TStrings);
   function  GetDeleteSQL:TStrings;
   procedure SetDeleteSQL(Value:TStrings);
   function  GetRefreshSQL:TStrings;
   procedure SetRefreshSQL(Value:TStrings);
  public
   constructor Create(Owner:TComponent);
   property    Owner:TComponent read FOwner;
  published
   property SelectSQL:TStrings read  GetSelectSQL write SetSelectSQL;
   property UpdateSQL:TStrings read  GetUpdateSQL write SetUpdateSQL;
   property DeleteSQL:TStrings read  GetDeleteSQL write SetDeleteSQL;
   property InsertSQL:TStrings read  GetInsertSQL write SetInsertSQL;
   property RefreshSQL:TStrings read GetRefreshSQL write SetRefreshSQL;
  end;

  TFormatFields = class(TPersistent)
  private
    FOwner  :TComponent;
    FDisplayFormatDateTime:string;
    FDisplayFormatDate    :string;
    FDisplayFormatTime    :string;
    FDisplayFormatNumeric :string;
    FEditFormatNumeric    :string;
    function StoreDfDt:boolean;
    function StoreDfN:boolean;
    function StoreEfN:boolean;
    function StoreDfD:boolean;
    function StoreDfT:boolean;
  protected
    procedure   AssignTo(Dest: TPersistent);override;
  public
    constructor Create(aOwner  :TComponent);
  published
    property DateTimeDisplayFormat:string read FDisplayFormatDateTime
                                   write FDisplayFormatDateTime  stored  StoreDfDt ;
    property NumericDisplayFormat :string read FDisplayFormatNumeric
                                   write FDisplayFormatNumeric   stored  StoreDfN ;
    property NumericEditFormat    :string read FEditFormatNumeric
                                   write FEditFormatNumeric     stored  StoreEfN ;
    property DisplayFormatDate:string read FDisplayFormatDate
                               write FDisplayFormatDate  stored StoreDfD;
    property DisplayFormatTime:string read FDisplayFormatTime
                               write FDisplayFormatTime stored StoreDfT;
  end;

  TWhenGetGenID=(wgNever,wgOnNewRecord,wgBeforePost);
  TReturningFields =(rfAll,rfKeyFields,rfBlobFields);
  TSetReturningFields=set of TReturningFields;

  TAutoUpdateOptions= class (TPersistent)
  private
   FOwner     :TComponent;
   FUpdateTableName:string;
   FKeyFieldList   :TStrings;
   FKeyFields      :string;
   FAutoReWriteSqls:boolean;
   FCanChangeSQLs:boolean;
   FGeneratorName :string;
   FGeneratorStep:integer;
   FSelectGenID:boolean;
   FGenBeforePost:boolean;
   FUpdateOnlyModifiedFields:boolean;
   FWhenGetGenID:TWhenGetGenID;
   FParamFieldLinks :TStrings;
   FAutoParamsToFields:boolean;
   FSeparateBlobUpdate:boolean;
   FUseExecuteBlock   :boolean; // For CachedUpdates only
   FWhereCondition    :string; // Cache where
   FModifiedTable     :string;
   FAliasModifiedTable:string;
   FModifiedTableHaveAlias:boolean;
   FReadySelectSQL: string;
   FReturningFields: TSetReturningFields;
   FUseRowsClause  :boolean;
   FModified:boolean;
   procedure SetUpdateTableName(const Value:string);
   procedure SetSelectGenID(Value:boolean);
   function  GetSelectGenID:boolean;
   function  GetGenBeforePost:boolean;
   procedure SetGenBeforePost(Value:boolean);
   procedure SetParamFieldLinks(const Value: TStrings);
   procedure SetUpdateOnlyModifiedFields(const Value: boolean);
   procedure SetKeyFields(const Value:string);
   function  GetAliasModifiedTable: string;
   function  GetModifiedTable: string;
   procedure PrepareUpdateTableStrings;
    procedure SetReturningFields(const Value: TSetReturningFields);
  protected
  // for compatibility only
    procedure  ReadSelectGenID(Reader: TReader);
    procedure  ReadGenBeforePost(Reader: TReader);
    procedure  AssignTo(Dest: TPersistent);override;
    procedure  DefineProperties(Filer: TFiler); override;
  public
   constructor Create(Owner:TComponent);
   destructor  Destroy; override;
   property    Owner:TComponent  read    FOwner;
   property    SelectGenID:boolean read GetSelectGenID write SetSelectGenID ;
   property    GenBeforePost:boolean read GetGenBeforePost write SetGenBeforePost ;
   property    KeyFieldList:TStrings read FKeyFieldList;
// Cache Analize results
   property    WhereCondition :string read FWhereCondition write FWhereCondition;
   property    ModifiedTableName :string read GetModifiedTable;
   property    AliasModifiedTable:string read GetAliasModifiedTable;
   property    ModifiedTableHaveAlias:boolean read FModifiedTableHaveAlias;
   property    ReadySelectSQL:string read FReadySelectSQL write FReadySelectSQL;
   property    Modified:boolean read FModified write FModified;
  published
   property    UpdateTableName:string  read  FUpdateTableName write SetUpdateTableName;
   property    KeyFields  :string read  FKeyFields write SetKeyFields;
   property    AutoReWriteSqls:boolean read  FAutoReWriteSqls write FAutoReWriteSqls default False;
   property    CanChangeSQLs:boolean read  FCanChangeSQLs write FCanChangeSQLs default False;
   property    GeneratorName :string read FGeneratorName write FGeneratorName ;
   property    UpdateOnlyModifiedFields:boolean read FUpdateOnlyModifiedFields write SetUpdateOnlyModifiedFields
    default False;
   property    WhenGetGenID:TWhenGetGenID read FWhenGetGenID write FWhenGetGenID default wgNever;
   property    GeneratorStep:integer read FGeneratorStep write FGeneratorStep default 1;
   property    ParamsToFieldsLinks :TStrings read FParamFieldLinks  write SetParamFieldLinks;
   property    AutoParamsToFields:boolean read FAutoParamsToFields write FAutoParamsToFields default False;
   property    SeparateBlobUpdate:boolean read FSeparateBlobUpdate write FSeparateBlobUpdate default False;
   property    UseExecuteBlock   :boolean read FUseExecuteBlock write FUseExecuteBlock default False;
   //^^^ For CachedUpdates only
   property    UseReturningFields: TSetReturningFields read FReturningFields write SetReturningFields default [];
   property    UseRowsClause  :boolean read FUseRowsClause write FUseRowsClause default False;
  end;

{$IFDEF SUPPORT_IB2007}
  TIBConnectParams =class(TPersistent)
  private
    FOwner:TComponent;
    function  GetInstanceName:string;
    procedure SetInstanceName(const Value:string);
  public
     constructor Create(Owner:TComponent);
  published
    property InstanceName: string read GetInstanceName  write SetInstanceName stored False;
  end;
{$ENDIF}

  TUseGeneratorCache=(No,forAll,forGeneratorList);
  TGeneratorParams=class(TNamedItem)
  private
   FStepForCache:integer;
   FNextValue   :Int64;
   FLimit       :Int64;
   function StoreStep: Boolean;
  public
   constructor Create(Collection: TCollection); override;
   procedure SaveToFile;
   function  NextValue:Int64;
  published
   property StepForCache:integer read FStepForCache write FStepForCache  stored StoreStep;
  end;


  TGeneratorsCache=class(TPersistent)
  private
   FOwner:TComponent;
   FCacheFileName:string;
   FUseGeneratorCache:TUseGeneratorCache;
   FGenerators:TOwnedCollection;
   FDefaultStep:Integer;
   FLoaded:boolean;
   procedure SetGenerators(const Value: TOwnedCollection);
   function DoSaveGenList: Boolean;
  protected
   function  GetOwner: TPersistent; override;
  public
   constructor Create(Owner:TComponent);
   destructor Destroy; override;
// Internal use methods
   function  IndexOf(const AName: string): Integer;
   function  Find(const GenName: string): TGeneratorParams;
   function  CanWork(const GenName: string):boolean;
   function  GetStep(const GenName: string):integer;
   function  GetNextValue(const GenName: string):Int64;
   procedure InternalSetGenParams(const GenName: string; Limit:Int64);
   procedure SaveToFile;
   procedure LoadFromFile;
   property  Loaded:boolean read FLoaded;
  public
   procedure  AddGenerator(const GenName: string; Limit:Int64);
   procedure  RemoveGenerator(const GenName: string);   
  published
   property CacheFileName:string read FCacheFileName write FCacheFileName;
   property UseGeneratorCache:TUseGeneratorCache
    read FUseGeneratorCache write FUseGeneratorCache default No;
   property GeneratorList:TOwnedCollection read FGenerators write SetGenerators stored DoSaveGenList;
   property DefaultStep:Integer read FDefaultStep write FDefaultStep default 50;
  end;

  TConnectParams=class(TPersistent)
  private
    FOwner:TComponent;
    FIsFirebird:boolean;
{$IFDEF SUPPORT_IB2007}
    FIBParams:TIBConnectParams;
    procedure SetIBParams(const Value: TIBConnectParams);
{$ENDIF}
    function  GetUserNameA: string;
    procedure SetUserName(const Value:string);
    function  GetRoleName: string;
    procedure SetRoleName(const Value:string);
    function  GetPassword: string;
    procedure SetPassword(const Value:string);
    function  GetCharSet: string;
    procedure SetCharSet(const Value:string);

  public
   constructor Create(Owner:TComponent);
   destructor Destroy; override;
  published
    property UserName : string read GetUserNameA write SetUserName stored False;
    property RoleName : string read GetRoleName write SetRoleName stored False;
    property Password : string read GetPassword write SetPassword stored False;
    property CharSet  : string read GetCharSet  write SetCharSet  stored False;
    property IsFirebird:boolean read FIsFirebird write FIsFirebird default True ;
{$IFDEF SUPPORT_IB2007}
    property IB2007   : TIBConnectParams read FIBParams write SetIBParams;
{$ENDIF}
  end;
{$IFDEF CSMonitor}
  TCSMonitorEnabled = (csmeDisabled, csmeEnabled, csmeDatabaseDriven, csmeTransactionDriven);

  EFIBCSMonitorError = class(Exception);

  TCSMonitorSupport = class(TPersistent)
  private
    FOwner: TComponent;
    FEnabled: TCSMonitorEnabled;
    FIncludeDatasetDescription: boolean;
    procedure SetEnabled(const Value: TCSMonitorEnabled);
    procedure SetIncludeDatasetDescription(const Value: boolean);
    function  DoStoreEnabled:boolean;
  public
    constructor Create(AOwner: TComponent);
  published
    property Enabled: TCSMonitorEnabled read FEnabled write SetEnabled stored DoStoreEnabled;
    property IncludeDatasetDescription: boolean read FIncludeDatasetDescription
      write SetIncludeDatasetDescription default true;
  end;
{$ENDIF}

  TCacheSchemaOptions =class(TPersistent)
  private
   FLocalCacheFile  :string;
   FAutoSaveToFile  :boolean;
   FAutoLoadFromFile:boolean;
   FValidateAfterLoad:boolean;
  public
   constructor Create;
  published
   property LocalCacheFile:string read FLocalCacheFile write FLocalCacheFile;
   property AutoSaveToFile:boolean read FAutoSaveToFile write FAutoSaveToFile default False;
   property AutoLoadFromFile:boolean read FAutoLoadFromFile write FAutoLoadFromFile default False;
   property ValidateAfterLoad:boolean read FValidateAfterLoad write FValidateAfterLoad default True;
  end;

  TDBParams =class(TStringList)
  private
    FOwner : TComponent;
    procedure ReadData(Reader: TReader);
    procedure WriteData(Writer: TWriter);
  protected
   procedure DefineProperties(Filer: TFiler); override;
  public
   constructor Create(AOwner:TComponent);
  end;

  TTransactionAction1 =
   (TARollback1, TARollbackRetaining1,TACommit1, TACommitRetaining1);
  TTPBMode=(tpbDefault,tpbReadCommitted,tpbRepeatableRead);

  TBlobSwapSupport=class(TPersistent)
  private
   FActive:boolean;
   FAutoValidateSwap:boolean;
   FSwapDirectory:string;
   FMinBlobSizeToSwap:integer;
   FTables:TStrings;
   function GetSwapDirectory: string;
   function StoreSwapDir: Boolean;
   procedure SetTables(aTables:TStrings);
   function StoreTables:boolean;
  public
   constructor Create;
   destructor  Destroy; override;
   property    SwapDirectory:string read GetSwapDirectory;
  published
   property Active:boolean read FActive write FActive default False;
   property AutoValidateSwap:boolean read FAutoValidateSwap write FAutoValidateSwap default False;
   property SwapDir:string read FSwapDirectory write FSwapDirectory stored StoreSwapDir;
   property MinBlobSizeToSwap:integer read FMinBlobSizeToSwap write FMinBlobSizeToSwap default 0;
   property Tables:TStrings read FTables write SetTables stored StoreTables;
  end;

  TConditions =class;

  TCondition =class
  private
   FOwner:TConditions;
   FEnabled:boolean;
   FInDestroy:boolean;

   FEnabledFromStream:boolean;
   FValueFromStream:boolean;

   function  GetName: string;
   function  GetValue: string;
   procedure SetValue(const Value: string);
   procedure SetValueFromStream(const Value: string);

   procedure SetName(const Name: string);
   procedure SetEnabled(const Value: boolean);
   procedure SetEnabledFromStream(const Value: boolean);
  public
   constructor Create(AOwner:TConditions);
   destructor  Destroy; override;
   property Enabled:boolean read FEnabled write SetEnabled;
   property Name: string read GetName write SetName;
   property Value: string read GetValue write SetValue;
  end;

  TConditionsStateFlag = (csInApply,csInCancel,csInRestorePrimarySQL);
  TConditionsState = set of TConditionsStateFlag;

  TConditions= class (TStringList)
  private
    FFIBQuery  :TComponent;
    FApplied   :boolean;
    FPrimarySQL:string;
    FState     :TConditionsState;
    function  GetEnabledText: string;
    function  GetCondition(Index: integer): TCondition;
  protected
    procedure Put(Index: Integer; const S: string); override;
    procedure DefineProperties(Filer: TFiler); override;
    procedure ReadEnabled(Reader: TReader);
  {$IFDEF DFM_VERSION1}
    procedure WriteEnabled(Writer: TWriter);
  {$ENDIF}
    procedure   ReadStrings(Reader: TReader);
    procedure   ReadData(Reader: TReader);
    procedure   WriteData(Writer: TWriter);

  public
    procedure   WriteToExchangeStrings(Dest:TStrings);
    function    ExchangeString:string;
    procedure   ReadFromExchangeStrings(Source:TStrings);
    procedure   ReadFromExchangeString(const Source:string);
  public
    constructor Create(AOwner:TComponent);
    destructor  Destroy; override;
    function    Add(const S: string): Integer; override;
    function    AddObject(const S: string; AObject: TObject): Integer; override;
    procedure   Clear; override;
    procedure   Delete(Index: Integer); override;
    function    AddCondition(const Name,Condition:string;Enabled:boolean):TCondition;
    function    FindCondition(const Name:string):TCondition;
    function    ByName(const Name:string):TCondition;
    procedure   Remove(const Name:string);
    procedure   Apply;
    procedure   CancelApply;
    procedure   RestorePrimarySQL;
    property    EnabledText: string read GetEnabledText;
    property    Applied :boolean read FApplied;
    property    Condition[Index:integer] :TCondition read  GetCondition ;default;
    property    PrimarySQL:string read FPrimarySQL write FPrimarySQL;
    property    State :TConditionsState read FState;
  end;

  TMemoSubtypes = class
  private
    FActive:boolean;
    FSubTypes:array of ShortInt;
    FSubTypesStr:string;
    procedure SetSubTypes(const SubTypesStr:string);
  public
    function IsMemoSubtype(aSubtype:ShortInt):boolean;
    property Active:boolean read FActive ;
  published
    property Subtypes:string read FSubTypesStr write SetSubTypes ;
  end;

//DataSet defaults
const
  StatDefPrepareOptions=[pfImportDefaultValues,psGetOrderInfo,psUseBooleanField,psSetEmptyStrToNull];

  DefaultPrepareOptions:TpPrepareOptions =StatDefPrepareOptions;

  StatDefDataSetOptions=[poTrimCharFields,poStartTransaction,poAutoFormatFields,  poRefreshAfterPost];
  DefaultOptions:TpFIBDsOptions =StatDefDataSetOptions;
//  [poTrimCharFields,poStartTransaction,poAutoFormatFields,  poRefreshAfterPost];

  DefaultDetailConditions:TDetailConditions=[];


//DataBase Defaults
  DefStoreConnected :boolean = True;
  DefSynchronizeTime:boolean = True;
  DefUpperOldNames  :boolean = False;
  DefUseLoginPrompt :boolean = False;
  DefCharSet        :string  = '';
  DefSQLDialect     :integer = 1;

//Transaction Defaults
  DefTimeOutAction :TTransactionAction1=taRollBack1;
  DefTimeOut       :Integer =0;
  DefTPBMode:TTPBMode =tpbReadCommitted;

//FIBQuery Defaults
  DefParamCheck               :boolean = True;
  DefGoToFirstRecordOnExecute :boolean = True;
  DefQueryOptions             :TpFIBQueryOptions =[];
//Registry Keys
  RegFIBRoot    ='FIBC_Software';
  RegFIBTrKinds ='Transation Kinds';
  RegPreferences='Preferences';
  RegRepository ='Repository';
  DefPrefixGenName     :string  = 'GEN_';
  DefSufixGenName      :string  = '_ID';
  DefEmptyStrToNull    :boolean = True;
// FormatFields Defaults
  FF_UseRuntimeDefaults:boolean = False;
   RDefDateFormat      :string ='dd.mm.yyyy';
   RDefTimeFormat      :string ='hh:nn';
   RDefDisplayFormatNum:string ='#,##0.';
   RDefEditFormatNum   :string ='0.';


   dDefDateFormat      :string ='dd.mm.yyyy';
   dDefTimeFormat      :string ='hh:nn';
   dDefDateTimeFormat  :string ='dd.mm.yyyy hh:nn';
   dDefDisplayFormatNum:string ='#,##0.';
   dDefEditFormatNum   :string ='0.';


implementation

uses
 FIBDatabase,FIBDataSet,FIBQuery,fib,ibase,StrUtil,StdFuncs,SqlTxtRtns;


constructor TAutoUpdateOptions.Create;
begin
 inherited Create;
 FOwner:=Owner;
 FGeneratorName :='';
 FGenBeforePost:=True;
 FWhenGetGenID :=wgNever;
 FGeneratorStep:=1;
 FParamFieldLinks:=TStringList.Create;
 FKeyFieldList   :=TStringList.Create;
end;

destructor  TAutoUpdateOptions.Destroy;
begin
  FParamFieldLinks.Free;
  FKeyFieldList.Free;
  inherited Destroy;
end;

procedure   TAutoUpdateOptions.AssignTo(Dest: TPersistent);
begin
  if Dest  is TAutoUpdateOptions then
  with TAutoUpdateOptions(Dest) do
  begin
    FUpdateTableName:=Self.FUpdateTableName;
    FKeyFields      :=Self.FKeyFields      ;
    FAutoReWriteSqls:=Self.FAutoReWriteSqls;
    FCanChangeSQLs  :=Self.FCanChangeSQLs  ;
    FGeneratorName  :=Self.FGeneratorName  ;
    FGeneratorStep  :=Self.FGeneratorStep  ;
    FSelectGenID    :=Self.FSelectGenID    ;
    FGenBeforePost  :=Self.FGenBeforePost  ;
    FUpdateOnlyModifiedFields:=Self.FUpdateOnlyModifiedFields;
    FWhenGetGenID   :=Self.FWhenGetGenID   ;
    FParamFieldLinks.Assign(Self.FParamFieldLinks);
    FModifiedTableHaveAlias := Self.FModifiedTableHaveAlias;
    FSeparateBlobUpdate:=Self.FSeparateBlobUpdate;
    FAutoParamsToFields:=Self.FAutoParamsToFields;
  end
  else
   inherited AssignTo(Dest)
end;

procedure  TAutoUpdateOptions.DefineProperties(Filer: TFiler);
begin
 if Filer is TReader then
 begin
 // For oldest dfm
   Filer.DefineProperty('SelectGenID',  ReadSelectGenID, nil,   False );
   Filer.DefineProperty('GenBeforePost',  ReadGenBeforePost, nil,   False );
 end;
end;

procedure TAutoUpdateOptions.ReadSelectGenID(Reader: TReader);
begin
 FSelectGenID:=Reader.ReadBoolean;
 if FSelectGenID then
    FWhenGetGenID := wgBeforePost
 else
    FWhenGetGenID := wgNever;
end;


procedure  TAutoUpdateOptions.ReadGenBeforePost(Reader: TReader);
begin
 FGenBeforePost:=Reader.ReadBoolean;
 if not FSelectGenID then  exit;
 if FGenBeforePost then
   FWhenGetGenID:=wgBeforePost
 else
   FWhenGetGenID:=wgOnNewRecord
end;

procedure TAutoUpdateOptions.SetUpdateTableName(const Value:string);
var
   MT:string;
begin
 FWhereCondition:='';
 FUpdateTableName:=Value;
 FModifiedTable:='';
 FAliasModifiedTable:='';
 FModifiedTableHaveAlias:=PosAlias(Value)>0;

 if (FGeneratorName='') and (WhenGetGenID<>wgNever) then
 begin
   MT:=GetModifiedTable;
   if (Length(MT)>0) and (MT[1]='"') then
   begin
    MT:=FastCopy(MT,2,Length(MT)-2);
    FGeneratorName:='"'+DefPrefixGenName+MT+DefSufixGenName+'"'
   end
   else
    FGeneratorName:=DefPrefixGenName+MT+DefSufixGenName;
 end;
 FModified:=True;
end;


// for compatibility only
function  TAutoUpdateOptions.GetSelectGenID:boolean;
begin
  result:=FWhenGetGenID<>wgNever
end;

procedure TAutoUpdateOptions.SetSelectGenID(Value: boolean);
begin
 if not Value then
   FWhenGetGenID:=wgNever
 else
 if FWhenGetGenID=wgNever then
  FWhenGetGenID:=wgBeforePost;
end;

function TAutoUpdateOptions.GetGenBeforePost: boolean;
begin
 result:=FWhenGetGenID in [wgBeforePost,wgNever]
end;

procedure TAutoUpdateOptions.SetGenBeforePost(Value: boolean);
begin
 if FWhenGetGenID<>wgNever then
 if Value then
   FWhenGetGenID:=wgBeforePost
 else
  FWhenGetGenID :=wgOnNewRecord;
end;

procedure TAutoUpdateOptions.SetParamFieldLinks(const Value: TStrings);
begin
  FParamFieldLinks.Assign( Value);
  DeleteEmptyStr(FParamFieldLinks)
end;

procedure TAutoUpdateOptions.SetReturningFields(
  const Value: TSetReturningFields);
begin
  FReturningFields := Value;
  FModified:=True;
end;

const
  DefDateFormat='dd.mm.yyyy';
  DefTimeFormat='hh:nn';

// TFormatFields
constructor TFormatFields.Create(aOwner  :TComponent);
begin
 FOwner:=aOwner;
 if FF_UseRuntimeDefaults then
 begin
   FDisplayFormatDateTime:= RDefDateFormat + ' '+RDefTimeFormat;
   FDisplayFormatNumeric := RDefDisplayFormatNum ;
   FEditFormatNumeric    := RDefEditFormatNum;
   FDisplayFormatDate    := RDefDateFormat;
   FDisplayFormatTime    := RDefTimeFormat;
 end
 else
 if    Assigned(FOwner) and (csDesigning in FOwner.ComponentState)
   and not CmpInLoadedState(FOwner)
 then
 begin
//   FDisplayFormatDateTime:= dDefDateFormat + ' '+dDefTimeFormat;
   FDisplayFormatDateTime:= dDefDateTimeFormat;
   FDisplayFormatNumeric := dDefDisplayFormatNum ;
   FEditFormatNumeric    := dDefEditFormatNum;
   FDisplayFormatDate    := dDefDateFormat;
   FDisplayFormatTime    := dDefTimeFormat;
 end
 else
 begin
   FDisplayFormatDateTime:= DefDateFormat + ' '+DefTimeFormat;
   FDisplayFormatNumeric :='#,##0.' ;
   FEditFormatNumeric    :='0.';
   FDisplayFormatDate    := DefDateFormat;
   FDisplayFormatTime    := DefTimeFormat;
 end;   
end;

function TFormatFields.StoreDfT:boolean;
begin
 if FF_UseRuntimeDefaults then
  Result:=   FDisplayFormatTime<>RDefTimeFormat
 else
  Result:= FDisplayFormatTime<>DefTimeFormat
end;

function TFormatFields.StoreDfD:boolean;
begin
 if FF_UseRuntimeDefaults then
  Result:= FDisplayFormatDate<>RDefDateFormat
 else
  Result:= FDisplayFormatDate<>DefDateFormat;
end;

function TFormatFields.StoreDfDt:boolean;
begin
 if FF_UseRuntimeDefaults then
  Result:= FDisplayFormatDateTime<>RDefDateFormat + ' '+RDefTimeFormat
 else
  Result:= FDisplayFormatDateTime<>DefDateFormat + ' '+DefTimeFormat;
end;

function TFormatFields.StoreDfN:boolean;
begin
 if FF_UseRuntimeDefaults then
  Result:= FDisplayFormatNumeric<>RDefDisplayFormatNum
 else
  Result:= FDisplayFormatNumeric <>'#,##0.' ;
end;

function TFormatFields.StoreEfN:boolean;
begin
 if FF_UseRuntimeDefaults then
  Result:=FEditFormatNumeric<>RDefEditFormatNum
 else
  Result:=FEditFormatNumeric<>'0.';
end;

procedure   TFormatFields.AssignTo(Dest: TPersistent);
begin
  if Dest  is TFormatFields then
  with TFormatFields(Dest) do
  begin
    FDisplayFormatDateTime:=Self.FDisplayFormatDateTime;
    FDisplayFormatDate    :=Self.FDisplayFormatDate;
    FDisplayFormatTime    :=Self.FDisplayFormatTime;
    FDisplayFormatNumeric :=Self.FDisplayFormatNumeric;
    FEditFormatNumeric    :=Self.FEditFormatNumeric;
  end
  else
   inherited AssignTo(Dest)
end;

///TConnectParams

constructor TConnectParams.Create(Owner:TComponent);
begin
 inherited Create;
 FOwner:=Owner;
 FIsFirebird:=True;
{$IFDEF SUPPORT_IB2007}
 FIBParams:=TIBConnectParams.Create(Owner);
{$ENDIF}
end;

destructor TConnectParams.Destroy;
begin
{$IFDEF SUPPORT_IB2007}
 FIBParams.Free;
{$ENDIF} 
 inherited Destroy
end;

function  TConnectParams.GetUserNameA: string;
begin
 Result:='';
 if Assigned(FOwner) and (FOwner is TFIBDataBase) then
 with TFIBDataBase(FOwner) do
 begin
  Result:=DBParamByDPB[isc_dpb_user_name];
 end;
end;

procedure TConnectParams.SetUserName(const Value:string);
begin
 if Assigned(FOwner) and (FOwner is TFIBDataBase) then
  with TFIBDataBase(FOwner) do
   DBParamByDPB[isc_dpb_user_name]:= Value
end;

function  TConnectParams.GetRoleName: string;
begin
 Result:='';
 if Assigned(FOwner) and (FOwner is TFIBDataBase) then
 with TFIBDataBase(FOwner) do
 begin
  Result:=DBParamByDPB[isc_dpb_sql_role_name];
 end;
end;

procedure TConnectParams.SetRoleName(const Value:string);
begin
 if Assigned(FOwner) and (FOwner is TFIBDataBase) then
  with TFIBDataBase(FOwner) do
   DBParamByDPB[isc_dpb_sql_role_name]:= Value
end;

function  TConnectParams.GetPassword: string;
begin
 Result:='';
 if Assigned(FOwner) and (FOwner is TFIBDataBase) then
 with TFIBDataBase(FOwner) do
 begin
  Result:=DBParamByDPB[isc_dpb_password];
 end;
end;

procedure TConnectParams.SetPassword(const Value:string);
begin
 if Assigned(FOwner) and (FOwner is TFIBDataBase) then
  with TFIBDataBase(FOwner) do
   DBParamByDPB[isc_dpb_password]:= Value
end;

function  TConnectParams.GetCharSet: string;
begin
 Result:='';
 if Assigned(FOwner) and (FOwner is TFIBDataBase) then
 with TFIBDataBase(FOwner) do
 begin
  Result:=DBParamByDPB[isc_dpb_lc_ctype];
 end;
end;

procedure TConnectParams.SetCharSet(const Value:string);
begin
 if Assigned(FOwner) and (FOwner is TFIBDataBase) then
  with TFIBDataBase(FOwner) do
   DBParamByDPB[isc_dpb_lc_ctype]:= FastUpperCase(Value)
end;

{$IFDEF SUPPORT_IB2007}
procedure TConnectParams.SetIBParams(const Value: TIBConnectParams);
begin
  FIBParams.Assign(Value);
end;



{ TIBConnectParams }
constructor TIBConnectParams.Create(Owner: TComponent);
begin
 inherited Create;
 FOwner:=Owner
end;

function  TIBConnectParams.GetInstanceName:string;
begin
 Result:='';
 if Assigned(FOwner) and (FOwner is TFIBDataBase) then
 with TFIBDataBase(FOwner) do
 begin
  Result:=DBParamByDPB[isc_dpb_instance_name];
 end;
end;

procedure TIBConnectParams.SetInstanceName(const Value:string);
begin
 if Assigned(FOwner) and (FOwner is TFIBDataBase) then
  with TFIBDataBase(FOwner) do
   DBParamByDPB[isc_dpb_instance_name]:= Value
end;
{$ENDIF}
{ TSQLs }

constructor TSQLs.Create(Owner: TComponent);
begin
 inherited Create;
 FOwner:=Owner;
end;

function TSQLs.GetDeleteSQL: TStrings;
begin
 Result:=TFIBDataSet(FOwner).DeleteSQL
end;

function TSQLs.GetInsertSQL: TStrings;
begin
 Result:=TFIBDataSet(FOwner).InsertSQL
end;

function TSQLs.GetRefreshSQL: TStrings;
begin
 Result:=TFIBDataSet(FOwner).RefreshSQL
end;

function TSQLs.GetSelectSQL: TStrings;
begin
 Result:=TFIBDataSet(FOwner).SelectSQL
end;

function TSQLs.GetUpdateSQL: TStrings;
begin
 Result:=TFIBDataSet(FOwner).UpdateSQL
end;

procedure TSQLs.SetDeleteSQL(Value: TStrings);
begin
 TFIBDataSet(FOwner).DeleteSQL:=Value
end;

procedure TSQLs.SetInsertSQL(Value: TStrings);
begin
 TFIBDataSet(FOwner).InsertSQL:=Value
end;

procedure TSQLs.SetRefreshSQL(Value: TStrings);
begin
 TFIBDataSet(FOwner).RefreshSQL:=Value
end;

procedure TSQLs.SetSelectSQL(Value: TStrings);
begin
 TFIBDataSet(FOwner).SelectSQL:=Value
end;

procedure TSQLs.SetUpdateSQL(Value: TStrings);
begin
 TFIBDataSet(FOwner).UpdateSQL:=Value
end;




{ TCacheSchemaOptions }

constructor TCacheSchemaOptions.Create;
begin
 inherited Create;
 FLocalCacheFile   :='';
 FAutoSaveToFile   :=False;
 FAutoLoadFromFile :=False;
 FValidateAfterLoad:=True;
end;

{ TDBParams }

constructor TDBParams.Create(AOwner: TComponent);
begin
 inherited Create;
 FOwner := AOwner;
end;

procedure TDBParams.DefineProperties(Filer: TFiler);
  function DoWrite: Boolean;
  begin
    if Filer.Ancestor <> nil then
    begin
      Result := True;
      if Filer.Ancestor is TStrings then
        Result := not Equals(TStrings(Filer.Ancestor))
    end
    else Result := Count > 0;
  end;
begin
  Filer.DefineProperty('Strings', ReadData, WriteData, DoWrite); 
end;

procedure TDBParams.ReadData(Reader: TReader);
begin
  Reader.ReadListBegin;
  BeginUpdate;
  try
    Clear;
    while not Reader.EndOfList do Add(Reader.ReadString);
  finally
    EndUpdate;
  end;
  Reader.ReadListEnd;
end;

procedure TDBParams.WriteData(Writer: TWriter);
var
  I: Integer;
  OldPassword:string;
begin
 if (FOwner is TFIBDatabase) and
  (ddoNotSavePassword in  TFIBDatabase(FOwner).DesignDBOptions)
 then
 begin
  OldPassword:=TFIBDatabase(FOwner).ConnectParams.Password;
  TFIBDatabase(FOwner).ConnectParams.Password:='';
 end;
 try
  Writer.WriteListBegin;
  for I := 0 to Count - 1 do Writer.WriteString(Get(I));
  Writer.WriteListEnd;
 finally
  if (FOwner is TFIBDatabase) and
   (ddoNotSavePassword in  TFIBDatabase(FOwner).DesignDBOptions)
  then
  begin
   TFIBDatabase(FOwner).ConnectParams.Password:=OldPassword;
  end;
 end;
end;


{ TConditions }

constructor TConditions.Create(AOwner:TComponent);
begin
 inherited Create;
 FFIBQuery:=AOwner;
 FApplied :=False;
 FPrimarySQL:='';
 FState :=[]
end;

destructor  TConditions.Destroy; 
var i:integer;
begin
 for i := Count - 1 downto 0 do
 begin
  Objects[i].Free;
 end;
 inherited Destroy;
end;

procedure TConditions.Put(Index: Integer; const S: string);
begin
  if Index=Count then AddObject(S,TCondition.Create(Self))
  else
   inherited Put(Index,S)
end;

function TConditions.Add(const S: string): Integer;
begin
  Result:=inherited Add(S);
  Objects[Result]:=TCondition.Create(Self);
end;

function TConditions.AddCondition(const Name,Condition: string;
  Enabled: boolean): TCondition;
var i:integer;
begin
 i:=IndexOfName(Name);
 if i=-1 then
 begin
  i:=Add(Name+'='+Condition);
  Result:=TCondition(Objects[i]);
 end
 else
 begin
  Result:=TCondition(Objects[i]);
  Result.Value:=Condition;
 end;

 Result.FEnabled:=Enabled;
 if Enabled then FApplied:=False
end;



function  TConditions.FindCondition(const Name:string):TCondition;
var i:integer;
begin
 i:=IndexOfName(Name);
 if i<0 then
  Result:=nil
 else
  Result:=TCondition(Objects[i]);
end;

function  TConditions.ByName(const Name:string):TCondition;
begin
  Result:=FindCondition(Name);
  if Result=nil then
    raise Exception.Create ('Can''t find Condition '+Name);
end;


procedure TConditions.Remove(const Name: string);
var Ind:integer;
begin
 Ind:=IndexOfName(Name);
 if Ind<>-1 then
 begin
  Delete(Ind);
  FApplied:=False
 end;
end;

function TConditions.GetEnabledText: string;
var   i,c:integer;
begin
 Result:='';
 c:=Pred(Count);
 if c<0 then Exit;
 for i:=0 to c do
 if TCondition(Objects[i]).Enabled and not IsBlank(Strings[i]) then
 begin
   Result:=Result+'('+ValueFromStr(Strings[i])+')'+CLRF;
   Result:=Result+CLRF+ ' and ';
 end;
 if not IsBlank(Result) then
  SetLength(Result,Length(Result)-7);
end;

procedure TConditions.Apply;
var Wh,Wh1:string;
begin
 with TFIBQuery(FFIBQuery) do
 begin
   BeginModifySQLText;
   Include(FState,csInApply);   
   try
    Wh1:=Conditions.EnabledText;
    if IsBlank(FPrimarySQL) then
      FPrimarySQL:=SQL.Text
    else
     RestorePrimarySQL;
    if not IsBlank(Wh1) then
    begin
     Wh:=GetMainWhereClause;
     if Wh<>'' then
       Wh:=Wh+CLRF+ 'and '+Wh1
     else
       Wh:=Wh1;
     SetMainWhereClause(Wh);
    end;
    FApplied:=True;
   finally
    EndModifySQLText;
    Exclude(FState,csInApply);    
   end;
 end;
end;

procedure TConditions.CancelApply;
begin
  if (FApplied) and (FState=[]) then
  try
    Include(FState,csInCancel);
    RestorePrimarySQL
  finally
    Exclude(FState,csInCancel);
  end;
end;

procedure   TConditions.RestorePrimarySQL;
begin
  Include(FState,csInRestorePrimarySQL);
  try
    FApplied:=False;
    if not IsBlank(FPrimarySQL) then
     if TFIBQuery(FFIBQuery).SQL.Text<>FPrimarySQL then
      TFIBQuery(FFIBQuery).SQL.Text:=FPrimarySQL;
  finally
   Exclude(FState,csInRestorePrimarySQL);
  end
end;

function TConditions.GetCondition(Index: integer): TCondition;
begin
 if (Index<0) or (Index>=Count) then
  Result:=nil
 else
  Result:=TCondition(Objects[Index]);
end;

function TConditions.AddObject(const S: string; AObject: TObject): Integer;
begin
  if (AObject is TCondition) or (AObject=nil) then
   Result:=inherited AddObject(S,AObject)
  else
   Result:=-1
end;

procedure TConditions.Clear;
var i:integer;
begin
 for i := Count - 1 downto 0 do
 begin
  Objects[i].Free;
 end;
 inherited;
end;

procedure TConditions.Delete(Index: Integer);
begin
  if not Condition[Index].FInDestroy then
   Condition[Index].Free
  else
   inherited;
end;

procedure TConditions.DefineProperties(Filer: TFiler);

  function DoWriteConditions: Boolean;
  var
     i:integer;
  begin
   Result:=False;
   if (Filer is TReader) then Exit;
   if (Filer.Ancestor <> nil) then
   begin
     if not (Filer.Ancestor is TConditions) then
      Result := False
     else
     if not Equals(TStrings(Filer.Ancestor)) then
       Result:=True
     else
     begin
       for i:=0 to Pred(Count) do
       if
          (TConditions(Filer.Ancestor).Condition[i].Enabled<>Condition[i].Enabled)
        or (TConditions(Filer.Ancestor).Condition[i].Name<>Condition[i].Name)
       then
       begin
        Result:=True; Exit;
       end;
     end;
   end
   else
   begin
     Result := Count>0;
   end;
  end;

var
  HasData:boolean;
begin
{  Filer.DefineProperty('Strings', ReadData, WriteData, DoWriteConditions);
  Filer.DefineProperty('Enabled',  ReadEnabled, WriteEnabled,   DoWriteConditions);}
  {$IFDEF DFM_VERSION1}
   inherited;
   Filer.DefineProperty('Enabled',  ReadEnabled, WriteEnabled,   DoWriteCondEnabled);
   Filer.DefineProperty('Data',  ReadData,nil, False);   
  {$ELSE}
   Filer.DefineProperty('Strings', ReadStrings, nil, False);
   Filer.DefineProperty('Enabled',  ReadEnabled,nil,   False);
    if Assigned(FFIBQuery) and(csAncestor in FFIBQuery.ComponentState)
      and  not((Filer is TReader) or (Filer is TWriter))
    then
     HasData:=False
    else
     HasData:=DoWriteConditions;
    Filer.DefineProperty('Data',  ReadData,WriteData, HasData);
  {$ENDIF}
end;

{$IFDEF DFM_VERSION1}
procedure TConditions.WriteEnabled(Writer: TWriter);
var s:string;
    i:integer;
begin
 s:='[';
 for i:=0 to Pred(Count) do
  s:=s+IntToStr(Integer(Condition[i].Enabled))+',';
 s[Length(s)]:=']';
 Writer.WriteString(s)
end;
{$ENDIF}

procedure TConditions.ReadEnabled(Reader: TReader);
var s:string;
    i,j:integer;
begin
 s:=Reader.ReadString;
 i:=2;
 while i<Length(s) do
 begin
  j:=(i div 2) -1;
  if j<Count then
  begin
   Condition[j].Enabled:=s[i]='1';
   Inc(i,2)
  end
  else
   Exit;
 end
end;

const
   ExchangeDelimeter='#$#$';

procedure   TConditions.WriteToExchangeStrings(Dest:TStrings);
var
    i:integer;
begin
  for i:=0 to Pred(Count) do
  begin
   Dest.Add(Condition[i].Name+ExchangeDelimeter+Condition[i].Value+ExchangeDelimeter+
    IntToStr(Ord(Condition[i].Enabled))
   );
  end;
end;

function    TConditions.ExchangeString:string;
var ts:TStrings;
begin
  ts:=TStringList.Create;
  try
    WriteToExchangeStrings(ts);
    Result:=ts.Text
  finally
    ts.Free
  end;
end;

procedure   TConditions.ReadFromExchangeStrings(Source:TStrings);
var
    i:integer;
    p:integer;
    CondName,CondBody:string;
    s:string;
begin
  Clear;
  for i:=0 to Pred(Source.Count) do
  begin
    s:=Source[i];
    p:=Pos(ExchangeDelimeter,s);
    CondName:=FastCopy(s,1,p-1);
    s:=FastCopy(s,p+Length(ExchangeDelimeter),MaxInt);
    p:=Pos(ExchangeDelimeter,s);
    CondBody:=FastCopy(s,1,p-1);
    s:=FastCopy(s,p+Length(ExchangeDelimeter),MaxInt);
    AddCondition(CondName,CondBody,FastTrim(s)='1')
  end;
end;

procedure   TConditions.ReadFromExchangeString(const Source:string);
var ts:TStrings;
begin
  ts:=TStringList.Create;
  try
    ts.Text:=Source;
    ReadFromExchangeStrings(ts);
  finally
    ts.Free
  end;
end;

procedure TConditions.ReadStrings(Reader: TReader);
begin
  Reader.ReadListBegin;
  BeginUpdate;
  try
    Clear;
    while not Reader.EndOfList do
    begin
      Add(Reader.ReadString);
    end;
  finally
    EndUpdate;
  end;
  Reader.ReadListEnd;
end;


procedure TConditions.ReadData(Reader: TReader);
var
  N,V  : string;
  En   : boolean;
  Index:integer;
  Deleted:boolean;
  C:TCondition;
begin
  Reader.ReadListBegin;
  BeginUpdate;
  Deleted:=False;
  try
    while not Reader.EndOfList do
    begin
      if Deleted then
      begin
       Remove(Reader.ReadString);
      end
      else
      begin
        N:=Reader.ReadString;
        Deleted:=(N='#@DELETED');
        if not Deleted then
        begin
          V  :=Reader.ReadString;
          En :=Reader.ReadBoolean;
          Index:=IndexOfName(N);
          if (Index<0) then
          begin
            if (V<>'0')  then
            begin
              if V='''' then  V:='';
              C:=AddCondition(N,V,En);
              C.FEnabledFromStream:=True;
              C.FValueFromStream:=True;              
            end;
          end
          else
          begin
            if Index>=0 then
            begin
              if Condition[Index].FEnabledFromStream then
               Condition[Index].SetEnabledFromStream(En);
//              Condition[Index].Enabled:=En;
              if (V<>'0') and Condition[Index].FValueFromStream then
               Condition[Index].SetValueFromStream(V);
//               Condition[Index].Value:=V
            end;
          end;
        end;
      end;
    end;
  finally
    EndUpdate;
  end;
  Reader.ReadListEnd;
end;

procedure TConditions.WriteData(Writer: TWriter);
var
  I,J: Integer;
  Index:integer;
  N,V: string;

begin
  Writer.WriteListBegin;
  for I := 0 to Count - 1 do
  begin
    N:=Names[I];
    if Writer.Ancestor=nil then
    begin
     V:=Values[N];
     Writer.WriteString(N);
     if V='' then
        V:=''''; 
     Writer.WriteString(V);
     Writer.WriteBoolean(Condition[I].Enabled);
    end
    else
    begin
     Index:=TConditions(Writer.Ancestor).IndexOfName(N);
     if Index<0 then
     begin
       Writer.WriteString(N);
       V:=ValueFromStr(Get(I));
       if V='' then
        V:='''';
       Writer.WriteString(V);
       Writer.WriteBoolean(Condition[I].Enabled);
     end
     else
     begin
      V:=ValueFromStr(Get(I));
      if V=ValueFromStr(TConditions(Writer.Ancestor).Strings[Index]) then
       V:='0';
      if (V<>'0') or
       (Condition[I].Enabled<>TConditions(Writer.Ancestor).Condition[Index].Enabled)
      then
      begin
       Writer.WriteString(N);
       Writer.WriteString(V);
       Writer.WriteBoolean(Condition[I].Enabled);
      end;
     end;
    end;
  end;
  if (Writer.Ancestor<>nil) then
  begin
    J:=0;
    for I := 0 to TConditions(Writer.Ancestor).Count - 1 do
     if FindCondition(TConditions(Writer.Ancestor).Condition[I].Name)=nil then
     begin
      Inc(J);
      if J=1 then
       Writer.WriteString('#@DELETED');
      Writer.WriteString(TConditions(Writer.Ancestor).Condition[I].Name);
     end;
  end;
  Writer.WriteListEnd;
end;

{ TCondition }

constructor TCondition.Create(AOwner: TConditions);
begin
 inherited Create;
 FOwner:=AOwner;
 FInDestroy:=False;

 FEnabledFromStream:=False;
 FValueFromStream  :=False;
end;

destructor TCondition.Destroy;
var i: integer;
begin
  if FInDestroy then  Exit;
  FInDestroy:=True;
  i := FOwner.IndexOfObject(Self);
  if i>=0 then FOwner.Delete(i);
  inherited Destroy;
end;

function TCondition.GetName: string;
var i: integer;
begin
 i := FOwner.IndexOfObject(Self);
 Result := FOwner.Names[i];
end;

function TCondition.GetValue: string;
var
   i: integer;
begin
 i      := FOwner.IndexOfObject(Self);
 Result := ValueFromStr(FOwner.Strings[i]);
end;

procedure TCondition.SetEnabled(const Value: boolean);
begin
  if  FEnabled <> Value then
  begin
   FOwner.FApplied:=False;
   FEnabled := Value;
   FEnabledFromStream:=False;
  end;
end;

procedure TCondition.SetEnabledFromStream(const Value: boolean);
begin
  SetEnabled(Value);
  FEnabledFromStream:=True;
end;

procedure TCondition.SetName(const Name: string);
var i: integer;
begin
 i := FOwner.IndexOfObject(Self);
 FOwner.Strings[i]:=Name+'='+ValueFromStr(FOwner.Strings[i]);
end;

procedure TCondition.SetValue(const Value: string);
var
   i: integer;
begin
 i := FOwner.IndexOfObject(Self);
 if FOwner.Strings[i]<>FOwner.Names[i]+'='+Value then
 begin
  FOwner.Strings[i]:=FOwner.Names[i]+'='+Value;
  FValueFromStream:=False
 end;
end;

procedure TCondition.SetValueFromStream(const Value: string);
begin
  SetValue(Value);
  FValueFromStream:=True
end;

procedure TAutoUpdateOptions.SetUpdateOnlyModifiedFields(
  const Value: boolean);
begin
  FUpdateOnlyModifiedFields :=
    Value and FAutoReWriteSqls and FCanChangeSQLs;
end;


procedure TAutoUpdateOptions.SetKeyFields(const Value:string);
var
 Pos: Integer;
begin
   FWhereCondition:='';
   FKeyFieldList.Clear;
   Pos := 1;
   while Pos <= Length(Value) do
   begin
       FKeyFieldList.Add(ExtractFieldName(Value, Pos));
   end;
   FKeyFields:=Value;
   FModified:=True;
end;

{ TBlobSwapSupport }

constructor TBlobSwapSupport.Create;
begin
  inherited Create;
  FSwapDirectory:=AppPathTemplate;
  FTables:=TStringList.Create;
end;

destructor  TBlobSwapSupport.Destroy;
begin
 FTables.Free;
 inherited Destroy;
end;

function TBlobSwapSupport.GetSwapDirectory: string;
begin
 if not Active then
 begin
   Result := '';
   Exit;
 end;
 if
  FastUpperCase(Copy(FSwapDirectory,1, Length(AppPathTemplate)))=AppPathTemplate
 then
  Result:=ApplicationPath+
   Copy(FSwapDirectory, Length(AppPathTemplate)+1,MaxInt)
 else
  Result := FSwapDirectory;

 if (Length(Result) > 0) and (Result[Length(Result)]<>'\') then
   Result := Result+'\';
end;


function TBlobSwapSupport.StoreSwapDir: Boolean;
begin
 Result:=FSwapDirectory<>AppPathTemplate
end;

procedure TBlobSwapSupport.SetTables(aTables:TStrings);
begin
  FTables.Assign(aTables)
end;


function TBlobSwapSupport.StoreTables:boolean;
begin
 Result:=Trim(FTables.Text)<>''
end;

function TAutoUpdateOptions.GetAliasModifiedTable: string;
begin
  PrepareUpdateTableStrings;
  Result:=FAliasModifiedTable
end;

function TAutoUpdateOptions.GetModifiedTable: string;
begin
  PrepareUpdateTableStrings;
  Result:=FModifiedTable
end;

procedure TAutoUpdateOptions.PrepareUpdateTableStrings;
begin
  if Length(FModifiedTable) = 0 then
  begin
   if FModifiedTableHaveAlias then
     begin
       FModifiedTable     :=CutTableName(UpdateTableName);
       FAliasModifiedTable:=CutAlias(UpdateTableName);
     end
   else
   begin
      FModifiedTable     :=UpdateTableName;
      if FOwner<>nil then
       FAliasModifiedTable:=
        AliasForTable(TFIBDataSet(FOwner).QSelect.ReadySQLText(False),UpdateTableName)
      else
       FAliasModifiedTable:=UpdateTableName;
   end;
   if Assigned(FOwner) and Assigned(TFIBDataSet(FOwner).Database) then
   with TFIBDataSet(FOwner).Database do
   begin
      FModifiedTable := EasyFormatIdentifier(SQLDialect, FModifiedTable,
          EasyFormatsStr
      );
      FAliasModifiedTable := EasyFormatIdentifier(SQLDialect, FAliasModifiedTable,
          EasyFormatsStr
      );
   end;
  end;
end;



{$IFDEF CSMonitor}
{ TCSMonitorSupport }



constructor TCSMonitorSupport.Create(AOwner: TComponent);
begin
  inherited Create;
  FOwner := AOwner;
  FIncludeDatasetDescription := true;
  if (FOwner is TFIBQuery) or
    (FOwner is TFIBDataSet) then FEnabled := csmeTransactionDriven else
    if FOwner is TFIBTransaction then FEnabled := csmeDatabaseDriven else
      if FOwner is TFIBDatabase then FEnabled := csmeDisabled;

end;

function  TCSMonitorSupport.DoStoreEnabled:boolean;
begin
  if (FOwner is TFIBQuery) or (FOwner is TFIBDataSet) then
      Result := FEnabled <> csmeTransactionDriven
  else
  if FOwner is TFIBTransaction then
      Result := FEnabled <> csmeDatabaseDriven
  else
  if FOwner is TFIBDatabase then
   Result := FEnabled <> csmeDisabled
  else
   Result:=False
end;

procedure TCSMonitorSupport.SetEnabled(const Value: TCSMonitorEnabled);
begin
  if (FOwner is TFIBTransaction) and
    not (Value in [csmeDisabled, csmeEnabled, csmeDatabaseDriven]) then
    raise EFIBCSMonitorError.Create('This object cannot use this value');
  if (FOwner is TFIBDatabase) and
    not (Value in [csmeDisabled, csmeEnabled]) then
    raise EFIBCSMonitorError.Create('This object cannot use this value');
  FEnabled := Value;
  if (FOwner is TFIBDataSet) then (FOwner as TFIBDataSet).SetCSMonitorSupportToQ;
end;

procedure TCSMonitorSupport.SetIncludeDatasetDescription(const Value: boolean);
begin
  FIncludeDatasetDescription := Value;
  if (FOwner is TFIBDataSet) then (FOwner as TFIBDataSet).SetCSMonitorSupportToQ;
end;

{$ENDIF}

{ TGeneratorParams }
type
 THackOwnedCollection = class(TOwnedCollection);

constructor TGeneratorParams.Create(Collection: TCollection);
begin
  FStepForCache:=TGeneratorsCache(THackOwnedCollection(Collection).GetOwner).DefaultStep;
  FNextValue:=-1;
  inherited;
end;



function TGeneratorParams.NextValue: Int64;
begin
 Result:=FNextValue;
 if FNextValue>-1 then
 begin
  Inc(FNextValue);
  if FNextValue>FLimit then
   FNextValue:=-1;
   SaveToFile
 end;
end;

procedure TGeneratorParams.SaveToFile;
var
   Ini:TIniFile;
   CacheFileName:string;
begin
 CacheFileName:=
  TGeneratorsCache(THackOwnedCollection(Collection).GetOwner).FCacheFileName;
 if Length(CacheFileName)>0 then
 begin
  Ini:=TIniFile.Create(CacheFileName);
  try
    with Self do
    begin
     Ini.WriteInteger( Name,'StepForCache',FStepForCache );
     Ini.WriteString(Name,
      'NextValue', IntToStr(FNextValue)
     );
     Ini.WriteString(Name,'Limit', IntToStr(FLimit));
    end;
  finally
   Ini.Free;
  end;
 end
end;

function TGeneratorParams.StoreStep: Boolean;
begin
  Result:=FStepForCache<>TGeneratorsCache(THackOwnedCollection(Collection).GetOwner).DefaultStep;
end;

{ TGeneratorsCache }

function TGeneratorsCache.CanWork(const GenName: string): boolean;
begin
 if Length(FCacheFileName)=0 then
  Result:=False
 else
 case FUseGeneratorCache of
  No:  Result:=False;
  forAll:Result:=True;
 else
   Result:=Find(GenName)<>nil
 end
end;

constructor TGeneratorsCache.Create(Owner: TComponent);
begin
 inherited Create;
 FOwner:=Owner;
 FGenerators:=TOwnedCollection.Create(Self,TGeneratorParams);
 FDefaultStep:=50
end;

destructor TGeneratorsCache.Destroy;
begin
  FGenerators.Free;
  inherited;
end;

function TGeneratorsCache.Find(const GenName: string): TGeneratorParams;
var
  I: Integer;
begin
  I := IndexOf(GenName);
  if I < 0 then Result := nil else
   Result := TGeneratorParams(FGenerators.Items[I]);
end;

function TGeneratorsCache.GetNextValue(const GenName: string): Int64;
var
   GenParams:TGeneratorParams;
begin
 if not Loaded then
  LoadFromFile;
 GenParams:=Find(GenName);
 if GenParams<>nil then
  Result:=GenParams.NextValue
 else
  Result:=-1;
end;

function TGeneratorsCache.GetOwner: TPersistent;
begin
 Result:=FOwner;
end;

function TGeneratorsCache.IndexOf(const AName: string): Integer;
begin
  for Result := 0 to FGenerators.Count - 1 do
    if AnsiCompareText(TNamedItem(FGenerators.Items[Result]).Name, AName) = 0 then Exit;
  Result := -1;
end;

procedure TGeneratorsCache.LoadFromFile;
var
   Ini:TIniFile;
   i:integer;
   ts:TStrings;
   curGen:TGeneratorParams;
   s:string;
begin
 if Length(FCacheFileName)>0 then
 begin
  Ini:=TIniFile.Create(FCacheFileName);
  ts:=TStringList.Create;
  try
    Ini.ReadSections(ts);
    for i := 0 to ts.Count - 1 do
    begin
     curGen:=Find(ts[i]);
     if curGen=nil then
      curGen:=TGeneratorParams(FGenerators.Add);
     curGen.Name:=ts[i];
     curGen.FStepForCache:=Ini.ReadInteger(ts[i],'StepForCache',DefaultStep);
     s:=Ini.ReadString(ts[i],'NextValue','-1');
     curGen.FNextValue:=StrToIntDef(s, -1);
     s:=Ini.ReadString(ts[i],'Limit','-1');
     curGen.FLimit:=StrToIntDef(s, -1);
    end;
  finally
   ts.Free;
   Ini.Free;
  end;
 end;
 FLoaded:=True;
end;

procedure TGeneratorsCache.SaveToFile;
var
   Ini:TIniFile;
   i:integer;
begin
 if Length(FCacheFileName)>0 then
 begin
  Ini:=TIniFile.Create(FCacheFileName);
  try
    for i := 0 to FGenerators.Count - 1 do
    with TGeneratorParams(FGenerators.Items[i]) do
    begin
     Ini.WriteInteger( Name,'StepForCache',FStepForCache );
     Ini.WriteString(Name, 'NextValue', IntToStr(FNextValue));
     Ini.WriteString(Name, 'Limit', IntToStr(FLimit));
    end;
  finally
   Ini.Free;
  end;
 end
end;

procedure TGeneratorsCache.SetGenerators(const Value: TOwnedCollection);
begin
  FGenerators.Assign(Value);
end;

procedure TGeneratorsCache.InternalSetGenParams(const GenName: string;
  Limit: Int64);
var
   GenParams:TGeneratorParams;
begin
 GenParams:=Find(GenName);
 if GenParams=nil then
  if  FUseGeneratorCache=forAll then
  begin
    GenParams:=TGeneratorParams(FGenerators.Add);
    GenParams.Name:=GenName
  end;
 if GenParams<>nil then
 begin
   GenParams.FLimit:=Limit;
   GenParams.FNextValue:=Limit-GenParams.FStepForCache+1;
   GenParams.SaveToFile
 end;
end;


function TGeneratorsCache.GetStep(const GenName: string): integer;
var
   GenParams:TGeneratorParams;
begin
 GenParams:=Find(GenName);
 if GenParams<>nil then
  Result:=GenParams.FStepForCache
 else
  Result:=DefaultStep
end;

procedure TGeneratorsCache.AddGenerator(const GenName: string;
  Limit: Int64);
var
   GenParams:TGeneratorParams;
begin
 GenParams:=Find(GenName);
 if GenParams=nil then
 begin
    GenParams:=TGeneratorParams(FGenerators.Add);
    GenParams.Name:=GenName;
    GenParams.FLimit:=Limit;
 end;
end;

procedure TGeneratorsCache.RemoveGenerator(const GenName: string);
var i:integer;
begin
  I := IndexOf(GenName);
  if I>=0 then
   FGenerators.Delete(I)
end;

function TGeneratorsCache.DoSaveGenList: Boolean;
begin
 Result:=FGenerators.Count>0
end;

{ TMemoSubtypes }


function TMemoSubtypes.IsMemoSubtype(aSubtype: ShortInt): boolean;
var
 i,L:integer;
begin
{ Result:=(aSubtype=FSubType1) or (aSubtype=FSubType2) or (aSubtype=FSubType2)
    or  (aSubtype=FSubType3) or (aSubtype=FSubType4)}
 Result:=False;
 L:=Length(FSubTypes)-1;
 for I := 0 to L do
  if aSubType=FSubTypes[I] then
  begin
    Result:=True;
    Break
  end;

end;

procedure TMemoSubtypes.SetSubTypes(const SubTypesStr: string);
var
   wc,i:Integer;
   s:string;
begin
   FActive:=False;
   wc:=WordCount(SubTypesStr,[';']);
   SetLength(FSubTypes,wc);
   FSubTypesStr:='';
   for I := 1 to wc do
   begin
     s:=ExtractWord(I,SubTypesStr,[';']);
     FSubTypes[I-1]:=StrToIntDef(S, 1);
     if FSubTypes[I-1]<>1 then
     begin
       FActive:=True;
       FSubTypesStr:=FSubTypesStr+s+';'
     end;
   end;
   SetLength(FSubTypesStr,Length(FSubTypesStr)-1)
end;


end.


