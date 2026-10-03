{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ InterBase databases                                           }
{                                                               }
{    FIBPlus is based in part on the product                    }
{    Free IB Components, written by Gregory H. Deatz for        }
{    Hoagland, Longo, Moran, Dunst & Doukas Company.            }
{    mailto:gdeatz@hlmdd.com                                    }
{                                                               }
{    Copyright (c) 1998-2012 Devrace Ltd.                       }
{    Written by Serge Buzadzhy                                  }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit FIBDataSet;

interface

{$I FIBPlus.inc}

uses
  SysUtils, ibase, IB_Intf, ib_externals, fib,
  FIBPlatforms,
  pFIBProps, pFIBFieldsDescr, DB, FIBCacheManage,
  DBCommon, DbConsts, DBParsers,
  FIBDatabase, FIBQuery, FIBMiscellaneous, SqlTxtRtns, pFIBLists,
  FIBCloneComponents,
{$IFDEF SUPPORT_ARRAY_FIELD}pFIBArray, {$ENDIF}
  pFIBInterfaces, pFIBEventLists,
  Classes, StdFuncs
{$IFNDEF NO_GUI}
{$IFDEF D_XE2}
  , System.UITypes
{$ELSE}
  , Forms, Controls // IS GUI units
{$ENDIF}
{$ENDIF}
  , FMTBcd, Variants

  ;

const
  vBufferCacheSize            = 32; // Allocate cache in this many record chunks
  vMinBufferChunksForLimCache = 100;

type

{$IFNDEF D_XE4}
{$IFDEF D2009+}
  TRecordBuffer = PByte;
{$ELSE}
  TRecordBuffer = PChar;
{$ENDIF}
{$ENDIF}
  TFIBCustomDataSet = class;
  TFIBDataSet = class;

  TFIBFieldStreamArray = array [0 .. 0] of TFIBFieldStream;
  PFIBFieldStreamArray = ^TFIBFieldStreamArray;

  TFieldData = record
    fdIsNull: Boolean;
  end;

  PFieldData = ^TFieldData;

  TCachedUpdateStatus = (cusUnmodified, cusModified, cusInserted, cusDeleted, cusUninserted, cusDeletedApplied);

  TRecordData = packed record
    rdRecordNumber: Long;
    rdBookmarkFlag: TBookmarkFlag;
    rdFlags: Byte; // 3 bit - TCachedUpdateStatus
    // rdCachedUpdateStatus: TCachedUpdateStatus;// Bit 7 is Calcs
    rdFields: array [1 .. 1] of TFieldData;
  end;

  PRecordData = ^TRecordData;

  TSavedRecordData = packed record
    rdFlags: Byte;
    rdFields: array [1 .. 1] of TFieldData;
  end;

  PSavedRecordData = ^TSavedRecordData;

  TFIBStringField = class(TStringField)
  private
    FPrepared: Boolean;
    vInSetAsString: Boolean;
    FEmptyStrToNull: Boolean;
    FDefaultValueEmptyString: Boolean;
    FValueLength: Integer;
    FCollateNumber: Byte;
    FCharacterSetName: string;
    FIsDBKey: Boolean;
    FReservedBuffer: TDataBuffer;
    // FStringBuffer     :FIBByteString;
    FDataSet: TDataSet;
    function GetAsDB_KEY: string;
    procedure Prepare;
    procedure UnPrepare(Sender: TObject);
    function GetDataToReserveBuffer: Boolean;
    function InternalGetAsString(var IsNull: Boolean): string;
    function CodePage: Word;
  protected
    class procedure CheckTypeSize(Value: Integer); override;
    procedure SetDataSet(ADataSet: TDataSet); override;
    function GetAsString: string; override;
    function GetAsNativeData: FIBByteString;
    procedure SetAsNativeData(const Value: FIBByteString);
    function GetAsVariant: Variant; override;
    procedure SetAsString(const Value: string); override;
{$IFDEF D2009+}
    function GetAsAnsiString: AnsiString; override;
    procedure SetAsAnsiString(const Value: AnsiString); override;
{$ENDIF}
    procedure SetSize(Value: Integer); override;
{$IFDEF UNICODE_TO_STRING_FIELDS}
    function GetDataSize: Integer; override;
{$ENDIF}
  public
    destructor Destroy; override;
    function IsDBKey: Boolean;
    function SqlSubType: Integer;
    function CharacterSet: string;
    procedure Clear; override;
    property DefaultValueEmptyString: Boolean read FDefaultValueEmptyString write FDefaultValueEmptyString;
    property AsNativeData: FIBByteString read GetAsNativeData;
    property AsOctetsData: FIBByteString read GetAsNativeData write SetAsNativeData;
  published
    property EmptyStrToNull: Boolean read FEmptyStrToNull write FEmptyStrToNull default false;
  end;

  TFIBWideStringField = class(TWideStringField)
  protected
    FPrepared: Boolean;
    FSqlSubType: Integer;
    FDataSize: Integer;
    FCollateNumber: Byte;
    FCharacterSetName: string;
    FDataSet: TDataSet;
    FEmptyStrToNull: Boolean;
    FCreated: Boolean;
    function GetDataSize: Integer; override;
    procedure SetSize(Value: Integer); override;
    procedure Prepare;
    procedure UnPrepare(Sender: TObject);
    procedure SetDataSet(ADataSet: TDataSet); override;
{$IFDEF D2006+}
    procedure CopyData(Source, Dest: Pointer); override;
{$ENDIF}
  protected

    FReservedBuffer: TDataBuffer;
    FStringBuffer: FIBByteString;

    FNeedUnicodeConvert: Boolean;
    FValueLength: Integer;
    function GetBytesValue(var Value: FIBByteString): Boolean;
    function GetDataToReserveBuffer: Boolean;
    function GetAsNativeData: FIBByteString;
    procedure SetAsNativeData(const Value: FIBByteString);
    function GetAsString: string; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Clear; override;
    function CharacterSet: string;
    function SqlSubType: Integer;
    function CollateNumber: Byte;

    property AsNativeData: FIBByteString read GetAsNativeData write SetAsNativeData;

  published
    property EmptyStrToNull: Boolean read FEmptyStrToNull write FEmptyStrToNull default false;

  end;

  TFIBLargeIntField = class(TLargeIntField)
  private
    function GetOldAsInt64: Int64;
  protected
    procedure SetVarValue(const Value: Variant); override;
  public
    property OldValue: Int64 read GetOldAsInt64;
  end;

  // INT128, NUMERIC(19..38) and DECFLOAT fields. DECFLOAT values which TBcd can not
  // hold (NaN, Infinity, more than 64 digits) are read as text by AsString and
  // DisplayText and as Double by AsFloat and Value; AsBCD, AsCurrency, AsInteger
  // and AsLargeInt raise a conversion error for them.
  // DECFLOAT has a floating scale, which TFieldDef can not express: its field defs have
  // Precision 16/34 and Size (scale) 8/17. FIBPlus itself does not normalize values to
  // Size and AsFloat is not rounded to it, but consumers of fixed point values
  // (TClientDataSet: at most 32 digits and a fixed scale) lose the digits out of this
  // range. Set Size of a persistent field for another range, or cast to VARCHAR
  // for exact values.
  TFIBFMTBCDField = class(TFMTBCDField)
  protected
    function GetAsFloat: Double; override;
    function GetAsString: string; override;
    function GetAsVariant: Variant; override;
    procedure GetText(var Text: string; DisplayText: Boolean); override;
    procedure SetAsFloat(Value: Double); override;
  end;

  TFIBIntegerField = class(TIntegerField)
  protected
    function GetAsBoolean: Boolean; override;
    procedure SetAsBoolean(Value: Boolean); override;
  public
    procedure Clear; override;
    constructor Create(AOwner: TComponent); override;
  end;

  TFIBDateField = class(TDateField)
  protected
{$IFDEF D_XE3}
    procedure SetAsDateTime(Value: TDateTime); override;
{$ENDIF}
  public

  end;

  TFIBTimeField = class(TTimeField)
  private
    FShowMsec: Boolean;
  protected
    procedure GetText(var Text: string; DisplayText: Boolean); override;
{$IFDEF D_XE3}
    procedure SetAsDateTime(Value: TDateTime); override;
{$ENDIF}
  public
  published
    property ShowMsec: Boolean read FShowMsec write FShowMsec default false;
  end;

  TFIBDateTimeField = class(TDateTimeField)
  private
    FShowMsec: Boolean;
    function GetAsTimeStamp: TTimeStamp;
    procedure SetAsTimeStamp(const Value: TTimeStamp);

  protected
    procedure GetText(var Text: string; DisplayText: Boolean); override;
{$IFDEF D_XE3}
    procedure SetAsDateTime(Value: TDateTime); override;
{$ENDIF}
  public
    property AsTimeStamp: TTimeStamp read GetAsTimeStamp write SetAsTimeStamp;
  published
    property ShowMsec: Boolean read FShowMsec write FShowMsec default false;
  end;

  TFIBBlobField = class(TBlobField)
  private
    FSubType: SmallInt;
    FIsClientCalcField: Boolean;
  protected
    function GetAsVariant: Variant; override;
    function GetBlobId: TISC_QUAD;
    function GetIsNull: Boolean; override;
  public
    function GetBlobInfo: TBlobInfo;
    property SubType: SmallInt read FSubType;
    property Blob_ID: TISC_QUAD read GetBlobId;
  published
    property IsClientField: Boolean read FIsClientCalcField write FIsClientCalcField default false;
  end;

  // TNT Controls Interface

  IWideStringField = interface
    ['{679C5F1A-4356-4696-A8F3-9C7C6970A9F6}']
    function GetAsWideString: {$IFDEF D2009+}UnicodeString; {$ELSE} WideString;
    {$ENDIF}
    procedure SetAsWideString(const Value: {$IFDEF D2009+}UnicodeString
      {$ELSE} WideString {$ENDIF});
    function GetWideDisplayText: WideString;
    function GetWideEditText: WideString;
    procedure SetWideEditText(const Value: WideString);
    // --
    property AsWideString: {$IFDEF D2009+}UnicodeString {$ELSE} WideString
    {$ENDIF} read GetAsWideString write SetAsWideString { inherited } ;
    property WideDisplayText: WideString read GetWideDisplayText;
    property WideText: WideString read GetWideEditText write SetWideEditText;
  end;

  TFIBMemoField = class(TMemoField, IWideStringField)
  private
    FCharSetID: Integer;
    FSubType: SmallInt;
    // UTF-8 also for a Unicode column known from the metadata (psSupportUnicodeBlobs)
    function BlobCodePage: Word;
    function GetWideDisplayText: WideString;
    function GetWideEditText: WideString;
    procedure SetWideEditText(const Value: WideString);
  protected
    procedure SetAsVariant(const Value: Variant); override;
{$IFDEF D2009+}
    function GetAsAnsiString: AnsiString; override;
{$ENDIF}
{$IFDEF D_XE3+}
    procedure SetAsAnsiString(const Value: AnsiString); override;
{$ENDIF}
  public
    function GetAsWideString: {$IFDEF D2009+}UnicodeString; {$ELSE} WideString;
    {$ENDIF} {$IFDEF D2006+} override; {$ENDIF}
    procedure SetAsWideString(const aValue:
      {$IFDEF D2009+} UnicodeString{$ELSE} WideString {$ENDIF});
    {$IFDEF D2006+} override; {$ENDIF}
    function GetAsVariant: Variant; override;
    function GetAsString: string; override;
    procedure SetAsString(const Value: string); override;
    function GetBlobId: TISC_QUAD;
  public
    function GetBlobInfo: TBlobInfo;
    property SubType: SmallInt read FSubType;
    procedure InternalSetCharSet(aValue: Integer); // Internal use
    property Blob_ID: TISC_QUAD read GetBlobId;
  end;

  TFIBSmallIntField = class(TSmallintField)
  protected
    function GetAsBoolean: Boolean; override;
    procedure SetAsBoolean(Value: Boolean); override;
  end;

  TFIBFloatField = class(TFloatField)
  private
    FRoundByScale: Boolean;
    function GetScale: Integer;
  protected
    procedure SetAsFloat(Value: Double); override;
    procedure GetText(var Text: string; DisplayText: Boolean); override;
  public
    constructor Create(AOwner: TComponent); override;
    property Scale: Integer read GetScale;
  published
    property RoundByScale: Boolean read FRoundByScale write FRoundByScale default True;
  end;

  TFIBBCDField = class(TBCDField)
  private
    FDataAsComp: Boolean;
    FDataSet: TDataSet;
    function ServerType: Integer;
  protected
    procedure LoadRoundByScale(Reader: TReader);
    procedure DefineProperties(Filer: TFiler); override;
    procedure SetDataSet(ADataSet: TDataSet); override;
    class procedure CheckTypeSize(Value: Integer); override;
    function GetAsCurrency: Currency; override;
    function GetAsString: string; override;
    function GetAsVariant: Variant; override;
    function GetDataSize: Integer; override;
    procedure GetText(var Text: string; DisplayText: Boolean); override;
    function GetValue(var Value: Currency): Boolean;
    procedure SetAsString(const Value: string); override;
    procedure SetAsCurrency(Value: Currency); override;
{$IFNDEF NO_USE_COMP}
    function GetAsComp: Comp;
    procedure SetAsComp(Value: Comp);
{$ENDIF}
    function GetAsExtended: Extended; {$IFDEF D2009+} override; {$ENDIF}
    procedure SetAsExtended(Value: Extended); {$IFDEF D2009+} override; {$ENDIF}
    function GetAsInt64: Int64;
    procedure SetAsInt64(const Value: Int64);
    function GetAsBCD: TBcd; override;
    procedure SetAsBCD(const Value: TBcd); override;
    procedure SetVarValue(const Value: Variant); override;
    function GetInternalData(var ValueIsNull: Boolean): Int64;
    function GetInternalOldData(var OldIsNull: Boolean): Int64;
    function GetData(Buffer: Pointer): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    procedure AddExtended(const Value: Extended);
    procedure SubtractExtended(const Value: Extended);
    procedure MultiplyExtended(const Value: Extended);
    procedure DivideExtended(const Value: Extended);

    procedure AddBCD(const Value: TBcd);
    procedure SubtractBCD(const Value: TBcd);
    procedure MultiplyBCD(const Value: TBcd);
    procedure DivideBCD(const Value: TBcd);
    property AsInt64: Int64 read GetAsInt64 write SetAsInt64;
    procedure Assign(Source: TPersistent); override;
    function FieldModified: Boolean;
    property AsBcd: TBcd read GetAsBCD write SetAsBCD;
{$IFNDEF NO_USE_COMP}
    property AsComp: Comp read GetAsComp write SetAsComp;
{$ENDIF}
    property AsExtended: Extended read GetAsExtended write SetAsExtended;
    property Value: Variant read GetAsVariant write SetVarValue;
  published
    property Size default 8;

  end;

  TFIBGuidField = class(TGuidField)
  private
    FBuffer: FIBByteString;
    pBuffer: Pointer;
  protected
    class procedure CheckTypeSize(Value: Integer); override;
    procedure SetAsString(const Value: string); override;
{$IFDEF D_25}
    function GetAsGuid: TGUID; override;
    procedure SetAsGuid(const Value: TGUID); override;
{$ELSE}
    function GetAsGuid: TGUID;
    procedure SetAsGuid(const Value: TGUID);
{$ENDIF}
    function GetAsVariant: Variant; override;
    procedure SetAsVariant(const Value: Variant); override;

  public
    constructor Create(AOwner: TComponent); override;
    property AsGuid: TGUID read GetAsGuid write SetAsGuid;
  end;

  TFIBBooleanField = class(TBooleanField)
  private
    FStringFalse: string;
    FStringTrue: string;
  protected
    function StoreStrFalse: Boolean;
    function StoreStrTrue: Boolean;

    function GetAsInteger: LongInt; override;
    procedure SetAsString(const Value: string); override;
    procedure SetVarValue(const Value: Variant); override;
    procedure SetAsInteger(Value: LongInt); override;
    procedure SetAsBoolean(Value: Boolean); override;
    function GetDataSize: Integer; override;
    function GetAsString: string; override;
    function GetAsBoolean: Boolean; override;
    function GetAsVariant: Variant; override;

  public
    constructor Create(AOwner: TComponent); override;
  published
    property StringFalse: string read FStringFalse write FStringFalse stored StoreStrFalse;
    property StringTrue: string read FStringTrue write FStringTrue stored StoreStrTrue;

  end;

{$IFDEF SUPPORT_ARRAY_FIELD}

  TFIBArrayField = class(TBytesField)
  private
    FStreamIndex: Integer;
    function GetFIBXSQLVAR: TFIBXSQLVAR;
  protected
    procedure GetText(var Text: string; DisplayText: Boolean); override;
    function GetDimCount: Integer;
    function GetElementType: TFieldType;
    function GetDimension(Index: Integer): TISC_ARRAY_BOUND;
    function GetArraySize: Integer;
    function GetArrayId: TISC_QUAD;
    function GetAsVariant: Variant; override;
    procedure SetAsVariant(const Value: Variant); override;

  public
    constructor Create(AOwner: TComponent); override;
    property DimensionCount: Integer read GetDimCount;
    property ElementType: TFieldType read GetElementType;
    property Dimension[Index: Integer]: TISC_ARRAY_BOUND read GetDimension;
    property ArraySize: Integer read GetArraySize;
    property ArrayID: TISC_QUAD read GetArrayId;
  end;
{$ENDIF}

  TUpdateKinds = set of TUpdateKind;
  TFIBUpdateAction = (uaFail, uaAbort, uaSkip, uaRetry, uaApply, uaApplied);

  TFIBUpdateErrorEvent = procedure(DataSet: TDataSet; E: EFIBError; UpdateKind: TUpdateKind; var UpdateAction: TFIBUpdateAction) of object;
  TFIBUpdateRecordEvent = procedure(DataSet: TDataSet; UpdateKind: TUpdateKind; var UpdateAction: TFIBUpdateAction) of object;

  TFIBAfterUpdateRecordEvent = procedure(DataSet: TDataSet; UpdateKind: TUpdateKind; var Resume: Boolean) of object;

  TFIBUpdateRecordTypes = set of TCachedUpdateStatus;
  TOnFetchRecord = procedure(FromQuery: TFIBQuery; RecordNumber: Integer; var StopFetching: Boolean) of object;

  TpSQLKind = (skModify, skInsert, skDelete, skRefresh, skMerge);
  TDispositionFieldType = (dfNormal, dfRRecNumber);
  TExtLocateOption = (eloCaseInsensitive, eloPartialKey, eloWildCards, eloInSortedDS, eloNearest, eloInFetchedRecords);

  TExtLocateOptions = set of TExtLocateOption;
  TLocateKind = (lkStandard, lkNext, lkPrior);

  TSortFieldInfo = record
    FieldName: string;
    InDataSetIndex: Integer;
    InOrderIndex: Integer;
    Asc: Boolean;
    NullsFirst: Boolean;
  end;

  TFIBDataLink = class(TDetailDataLink)
  private
    FMasterChangedInPost: Boolean;
    function DetailPosting: Boolean;
    procedure ApplyMasterChangedInPost;
  protected
    FDataSet: TFIBCustomDataSet;
  protected
    procedure ActiveChanged; override;
    procedure RecordChanged(Field: TField); override;
    procedure CheckBrowseMode; override;
    procedure DataSetChanged; override;
    function GetDetailDataSet: TDataSet; override;
  public
    constructor Create(ADataSet: TFIBCustomDataSet);
    destructor Destroy; override;
  end;

  TFIBBookmark = packed record
    bRecordNumber: Integer;
    bActiveRecord: Integer;
  end;

  PFIBBookMark = ^TFIBBookmark;
  (*
    * TFIBCustomDataSet - declaration
  *)
  TTransactionKind = (tkReadTransaction, tkUpdateTransaction);
  TCompareFieldValues = function(Field: TField; const S1, S2: Variant): Integer of object;

  TRecordsPartition = record
    BeginPartRecordNo: Integer;
    EndPartRecordNo: Integer;
    IncludeBof: Boolean;
    IncludeEof: Boolean;
  end;

  PRecordsPartition = ^TRecordsPartition;

  TCacheModelKind = (cmkStandard, cmkLimitedBufferSize);

  TCacheModelOptions = class(TPersistent)
  private
    vOwner: TFIBCustomDataSet;
    FCacheModelKind: TCacheModelKind;
    FBufferChunks: Integer;
    FPlanForDescSQLs: string;
    FBlobCacheLimit: Integer;
    procedure SetBufferChunks(Value: Integer);
    procedure SetCacheModelKind(Value: TCacheModelKind);
  public
    constructor Create(Owner: TFIBCustomDataSet);
  published
    property CacheModelKind: TCacheModelKind read FCacheModelKind write SetCacheModelKind default cmkStandard;
    property BufferChunks: Integer read FBufferChunks write SetBufferChunks default vBufferCacheSize;
    property PlanForDescSQLs: string read FPlanForDescSQLs write FPlanForDescSQLs;
    property BlobCacheLimit: Integer read FBlobCacheLimit write FBlobCacheLimit default 0;
  end;

  TUpdateFieldStreams = (ufsCheckIsNull, ufsPost, ufsCancel, ufsClearOldValue, ufsRefresh);
  TOnFillClientBlob = procedure(DataSet: TFIBCustomDataSet; Field: TFIBBlobField; Stream: TFIBBlobStream) of object;
  TOnBlobFieldProcessing = procedure(Field: TBlobField; BlobSize: Integer; Progress: Integer; var Stop: Boolean) of object;

  TDataSetRunStateValue = (
    drsInCacheRefresh,
    drsInSort,
    drsInOpenByTimer,
    drsInFilterProc,
    drsInGetRecordProc,
    drsInGotoBookMark,
    drsInClone,
    drsInApplyUpdates,
    drsInRefreshClientFields,
    drsDontCheckInactive,
    drsForceCreateCalcFields,
    drsInRefreshRow,
    drsInMoveRecord,
    drsInCacheDelete,
    drsInFetchingAll,
    drsInLoaded,
    drsGetBlobStream,
    drsInLoadFromStream,
    drsInFieldValidate,
    drsInFieldAsData,
    drsInPost
  );
  TDataSetRunState = set of TDataSetRunStateValue; // InternalUse

  TFilteredCacheInfo = record
    AllRecords: Integer;
    FilteredRecords: Integer;
    NonVisibleRecords: TSortedList;
  end;

{$IFDEF D_XE2}

  EventInfo = NativeInt;
{$ELSE}
  EventInfo = LongInt;
{$ENDIF}

  TFIBCustomDataSet = class({$IFDEF TWideDataSet}TWideDataset{$ELSE}TDataSet{$ENDIF}, ISQLObject, IFIBDataSet)
  protected
    (*
      * Fields, and internal objects
    *)
    FBase: TFIBBase; // Manages database and transaction
    FStreamsBufferOffset: Integer;
    FStreamsCacheOffset: Integer;
    // array fields have stream slots after the BLOB fields, see FieldStreamIndex
    FArrayFieldCount: Integer;
    FFieldStreamList: TList;
    FOpenedFieldStreams: TList;
    FRecordsCache: TRecordsCache;
    FBufferChunkSize, FBPos, FOBPos, FBEnd, FOBEnd: DWORD;
    FCachedUpdates: Boolean;
    FCalcFieldsOffset: Integer;
    FCurrentRecord: Long;
    FDeletedRecords: Long; // How many records have been deleted?
    FSourceLink: TFIBDataLink;
    FOpen: Boolean; // Is the dataset open?
    FPrepared: Boolean;
    FQDelete, FQInsert, FQRefresh, FQSelect, FQUpdate: TFIBQuery;
    // Dataset management queries
    FRecordBufferSize: Integer;
    FBlockReadSize: Integer;

    FRecordCount: Integer;
    FAllRecordCount: Integer;
    FRecordSize: Integer;
    vDisableScrollCount: Integer;

    FDatabaseDisconnecting, FDatabaseDisconnected, FDatabaseFree: TNotifyEvent;
    FOnUpdateError: TFIBUpdateErrorEvent;
    FOnUpdateRecord: TFIBUpdateRecordEvent;
    FAfterUpdateRecord: TFIBAfterUpdateRecordEvent;
    FTransactionEnding: TNotifyEvent;
    FTransactionEnded: TNotifyEvent;
    FTransactionFree: TNotifyEvent;

    FBeforeStartTr: TNotifyEvent;
    FAfterStartTr: TNotifyEvent;
    FBeforeEndTr: TEndTrEvent;
    FAfterEndTr: TEndTrEvent;

    FBeforeStartUpdTr: TNotifyEvent;
    FAfterStartUpdTr: TNotifyEvent;
    FBeforeEndUpdTr: TEndTrEvent;
    FAfterEndUpdTr: TEndTrEvent;

    FUpdatesPending: Boolean;
    FUpdateRecordTypes: TFIBUpdateRecordTypes;
    FUniDirectional: Boolean;
    FOnGetRecordError: TDataSetErrorEvent;
    FOptions: TpFIBDsOptions;
    FDetailConditions: TDetailConditions;
    vInspectRecno: Integer;
    vTypeDispositionField: TDispositionFieldType;
    // A DECFLOAT value of this field which TBcd can not hold is copied to
    // vRawDecimalData and GetFieldData returns False, see TFIBFMTBCDField
    vRawDecimalField: TField;
    vRawDecimalReturned: Boolean;
    vRawDecimalData: TFB_DEC34;
    vTimerForDetail: TFIBTimer;
    vScrollTimer: TFIBTimer;
    FDisableCOCount: Integer;
    FDisableCalcFieldsCount: Integer;
    FPrepareOptions: TpPrepareOptions;
    vSelectSQLTextChanged: Boolean;
    FRefreshTransactionKind: TTransactionKind;
    FAutoCommit: Boolean;
    FWaitEndMasterInterval: Integer;
    FOnFieldChange: TFieldNotifyEvent;
    FOnFillClientBlob: TOnFillClientBlob;
    FOnBlobFieldRead: TOnBlobFieldProcessing;
    FOnBlobFieldWrite: TOnBlobFieldProcessing;
    FWritingBlob: TField;
    vPredState: TDataSetState;
    vrdFieldCount: Integer;
    FStringFieldCount: Integer;
    FFilterParser: TExpressionParser;
    FAllowedUpdateKinds: TUpdateKinds;
    FRunState: TDataSetRunState;
    vSimpleBookMark: Integer;
    vCalcFieldsSavedCache: Boolean;
    FFieldOriginRule: TFieldOriginRule;
    FFilteredCacheInfo: TFilteredCacheInfo;

  protected
    FAutoUpdateOptions: TAutoUpdateOptions;
{$IFDEF CSMonitor}
    FCSMonitorSupport: TCSMonitorSupport;
    procedure SetCSMonitorSupport(Value: TCSMonitorSupport);
{$ENDIF}
    function IsDBKeyField(Field: TObject): Boolean;

    // GB
    procedure CheckDataFields(FieldList: TList; const CallerProc: string);
    procedure PrepareAdditionalSelects;
    function CompareBookMarkAndRecno(BookMark: TBookMark; Rno: Integer; OnlyFields: Boolean = false): Boolean;
    function RefreshAround(BaseQuery: TFIBQuery; var BaseRecNum: Integer;
      IgnoreEmptyBaseQuery: Boolean = True;
      ReopenBaseQuery: Boolean = True): Boolean;
    // End GB
  private
    // GB
    FCacheModelOptions: TCacheModelOptions;

    vPartition: PRecordsPartition;
    FQCurrentSelect: TFIBQuery;
    FQSelectPart: TFIBQuery;
    FQSelectDescPart: TFIBQuery;
    FQSelectDesc: TFIBQuery;
    FQBookMark: TFIBQuery;
    FKeyFieldsForBookMark: TStrings;
    FSortFields: Variant;
    function CanHaveLimitedCache: Boolean;

    procedure SetCacheModelOptions(aCacheModelOptions: TCacheModelOptions);
    function GetBufferChunks: Integer;
    procedure SetBufferChunks(Value: Integer);
    procedure ShiftCurRec;
    // End GB

    function StoreUpdTransaction: Boolean;
    procedure SetOnEndScroll(Event: TDataSetNotifyEvent);
    function GetDefaultFields: Boolean;
    procedure ClearFieldStreamList;

    function CreateInternalQuery(const QName: string): TFIBQuery;
    function GetGroupByString: string;
    function GetMainWhereClause: string;
    procedure SetGroupByString(const Value: string);
    procedure SetMainWhereClause(const Value: string);
    function GetPlanClause: string;
    procedure SetPlanClause(const Value: string);
  protected
    FOnCompareFieldValues: TCompareFieldValues;
    function CompareFieldValues(Field: TField; const S1, S2: Variant): Integer; virtual;
  public
    function AnsiCompareString(Field: TField; const val1, val2: Variant): Integer;
    function StdAnsiCompareString(Field: TField; const S1, S2: Variant): Integer;
    function StdCompareValues(Field: TField; const S1, S2: Variant): Integer;
  published
    property OnCompareFieldValues: TCompareFieldValues read FOnCompareFieldValues write FOnCompareFieldValues;
  protected
{$DEFINE FIB_INTERFACE}
{$I FIBDataSetPT.inc}
{$UNDEF FIB_INTERFACE}
  protected
    function GetXSQLVAR(Fld: TField): TXSQLVAR;
    function GetFieldScale(Fld: TNumericField): Short;
    function GetUpdateTransaction: TFIBTransaction;
    (*
      * Routines for managing access to the database, etc... They have
      * nothing to do with TDataset.
    *)
    function AdjustCurrentRecord(Buffer: Pointer; GetMode: TGetMode): TGetResult;
    function CanEdit: Boolean; virtual;
    function CanInsert: Boolean; virtual;
    function CanDelete: Boolean; virtual;
    procedure CheckFieldCompatibility(Field: TField; FieldDef: TFieldDef); override;
    procedure CheckInactive; override;
    procedure CheckEditState;
    procedure UpdateFieldStreams(Buff: Pointer; Operation: TUpdateFieldStreams; ClearModified, ForceWrite: Boolean; Field: TField = nil);
    procedure CallBackBlobWrite(BlobSize: Integer; BytesProcessing: Integer; var Stop: Boolean);
    function StreamFieldCount: Integer;
    function FieldStreamIndex(Field: TField): Integer;
{$IFDEF SUPPORT_ARRAY_FIELD}
    procedure PrepareStreamFields;
    function GetFieldArray(Field: TField): TpFIBArray;
    function ReadArrayBuffer(Field: TField; Buffer: PAnsiChar): Boolean;
    procedure WriteArrayBuffer(Field: TField; Buffer: PAnsiChar);
{$ENDIF}
    (*
      * When copying a given record buffer, should we overwrite
      * the pointers to "memory" or should we just copy the
      * contents?
    *)
    procedure CopyRecordBuffer(Source, Dest: Pointer);
    procedure DoDatabaseDisconnecting(Sender: TObject);
    procedure DoDatabaseDisconnected(Sender: TObject);
    procedure DoDatabaseFree(Sender: TObject);
    procedure DoTransactionEnding(Sender: TObject); virtual;
    procedure DoTransactionEnded(Sender: TObject); virtual;
    procedure DoTransactionFree(Sender: TObject);

    procedure DoBeforeStartTransaction(Sender: TObject);
    procedure DoAfterStartTransaction(Sender: TObject);
    procedure DoBeforeEndTransaction(EndingTR: TFIBTransaction; Action: TTransactionAction; Force: Boolean);
    procedure DoAfterEndTransaction(EndingTR: TFIBTransaction; Action: TTransactionAction; Force: Boolean);

    procedure DoBeforeStartUpdateTransaction(Sender: TObject);
    procedure DoAfterStartUpdateTransaction(Sender: TObject);
    procedure DoBeforeEndUpdateTransaction(EndingTR: TFIBTransaction; Action: TTransactionAction; Force: Boolean);
    procedure DoAfterEndUpdateTransaction(EndingTR: TFIBTransaction; Action: TTransactionAction; Force: Boolean); virtual;

    procedure FetchCurrentRecordToBuffer(Qry: TFIBQuery; RecordNumber: Integer; Buffer: TRecordBuffer);
    procedure FetchRecordToCache(Qry: TFIBQuery; RecordNumber: Integer);
    procedure InitDataSetSchema;
    function GetActiveBuf: TRecordBuffer;
    function GetDatabase: TFIBDatabase;
    function GetDBHandle: PISC_DB_HANDLE;
    function GetDeleteSQL: TStrings;
    function GetInsertSQL: TStrings;
    function GetParams: TFIBXSQLDA;
    function GetRefreshSQL: TStrings;
    function GetSelectSQL: TStrings;
    function GetStatementType: TFIBSQLTypes;
    function GetUpdateSQL: TStrings;
    function GetTransaction: TFIBTransaction;
    function GetTRHandle: PISC_TR_HANDLE;

    procedure InternalDeleteRecord(Qry: TFIBQuery; Buff: Pointer); virtual;
{$DEFINE FIB_INTERFACE}
{$I FIBDataSetLocate.inc}
{$UNDEF FIB_INTERFACE}
    function InternalLocate(const KeyFields: string;
      KeyValues: array of Variant; Options: TExtLocateOptions;
      FromBegin: Boolean = false; LocateKind: TLocateKind = lkStandard;
      ResyncToCenter: Boolean = false): Boolean; virtual;

    function InternalLocateForLimCache(const KeyFields: string;
      const KeyValues: array of Variant; Options: TExtLocateOptions;
      LocateKind: TLocateKind = lkStandard; aQLocate: TFIBQuery = nil): Boolean;

    function InternalExtLocate(const KeyFields: string;
      const KeyValues: Variant; Options: TExtLocateOptions;
      LocateKind: TLocateKind): Boolean;

    procedure InternalPostRecord(Qry: TFIBQuery; Buff: Pointer); virtual;
    function InternalRefreshRow(Qry: TFIBQuery; Buff: TRecordBuffer): Boolean;
    procedure InternalRevertRecord(RecordNumber: Integer; WithUnInserted: Boolean);
    function IsVisibleStat(Buffer: TRecordBuffer): Boolean;
    function IsVisible(Buffer: TRecordBuffer): Boolean; virtual;
    procedure SaveOldBuffer(Buffer: TRecordBuffer);
    procedure SetDatabase(Value: TFIBDatabase);
    procedure LiveChangeDatabase(Value: TFIBDatabase); // internal use
    procedure SetDeleteSQL(Value: TStrings);
    procedure SetInsertSQL(Value: TStrings);
    procedure SetQueryParams(Qry: TFIBQuery; Buffer: Pointer);
    procedure SetRefreshSQL(Value: TStrings);
    procedure SetSelectSQL(Value: TStrings);
    procedure SetUpdateSQL(Value: TStrings);
    procedure SetTransaction(Value: TFIBTransaction);
    procedure LiveChangeTransaction(Value: TFIBTransaction); // internal use
    procedure SetUpdateTransaction(Value: TFIBTransaction); virtual;

    procedure SetUpdateRecordTypes(Value: TFIBUpdateRecordTypes);
    procedure SetUniDirectional(Value: Boolean);
    procedure SetPrepareOptions(Value: TpPrepareOptions); virtual;
    procedure SetRefreshTransactionKind(const Value: TTransactionKind);
    procedure SourceChanged;
    procedure SourceDisabled;
  protected
    FParams: TParams;
    procedure SQLChanging(Sender: TObject); virtual;
    procedure ReadRecordCache(RecordNumber: Integer; Buffer: TRecordBuffer; ReadOldBuffer: Boolean; Shift: Integer = 0);
    procedure WriteRecordCache(RecordNumber: Integer; Buffer: TRecordBuffer);
    function GetNewBuffer: TRecordBuffer;
    function GetOldBuffer(aRecordNo: Integer = -1): TRecordBuffer;
    procedure CheckUpdateTransaction;
  protected
    FValidatingFieldBuffer: TDataBuffer;
    FValidatedField: TField;
    FValidatedRec: Integer;

    vFieldDescrList: TFIBFieldDescrList;
    FFNFields: TStringList;
    (*
      * Routines from TDataset that need to be overridden to use the IB API
      * directly.
    *)

    vIgnoreLocRecno: Integer;
    vControlsEnabled: Boolean;
    FOnEnableControls: TDataSetNotifyEvent;
    FOnDisableControls: TDataSetNotifyEvent;
    FOnEndScroll: TDataSetNotifyEvent;
    FCachedActive: Boolean;
    vNeedReloadClientBlobs: Boolean;

    vBeforeCloseEvents: TNotifyEventList;
    vAfterOpenEvents: TNotifyEventList;
    vBeforeOpenEvents: TNotifyEventList;
    procedure SetActive(Value: Boolean); override;
    procedure DataEvent(Event: TDataEvent; Info: EventInfo); override;

    procedure SetStateFieldValue(State: TDataSetState; Field: TField; const Value: Variant); override;
    procedure DoOnDisableControls(DataSet: TDataSet);
    procedure DoOnEnableControls(DataSet: TDataSet);
    function AllocRecordBuffer: TRecordBuffer; override; // abstract
    procedure InternalDoBeforeOpen; virtual;
    procedure DoBeforeOpen; override;
    procedure DoAfterOpen; override;
    procedure DoBeforeClose; override;
    procedure DoAfterClose; override;
    procedure DoBeforeCancel; override;
    procedure DoAfterCancel; override;
    procedure DoBeforeDelete; override;
    procedure DoBeforeEdit; override;
    procedure DoBeforeInsert; override;
    procedure DoBeforeScroll; override;
    procedure DoAfterScroll; override;
    procedure DoBeforePost; override;
    procedure DoAfterPost; override;
    procedure DoAfterDelete; override;
    procedure DoOnEndScroll(Sender: TObject);
    procedure DoOnPostError(DataSet: TDataSet; E: EDatabaseError; var Action: TDataAction); virtual;
    procedure FreeRecordBuffer(var Buffer: TRecordBuffer); override; // abstract
    procedure GetBookmarkData(Buffer: TRecordBuffer; Data: Pointer); override; // abstract
    function GetBookmarkFlag(Buffer: TRecordBuffer): TBookmarkFlag; override; // abstract
    function GetCanModify: Boolean; override;
    function GetDataSource: TDataSource; override;
    function GetFieldClass(FieldType: TFieldType): TFieldClass; override;
    function GetRecNo: Integer; override;
    function GetRealRecNo: Integer;
    procedure TryDesignPrepare;

{$IFDEF D_XE4}
    procedure GetBookmarkData(Buffer: TRecordBuffer; Data: TBookMark); override;
    procedure DataConvert(Field: TField; Source: TValueBuffer; var Dest: TValueBuffer; ToNative: Boolean); override;
{$ELSE}
{$IFDEF D_XE3}
    procedure GetBookmarkData(Buffer: TRecordBuffer; Data: TBookMark); override;
    procedure DataConvert(Field: TField; Source, Dest: TValueBuffer; ToNative: Boolean); override;
{$ENDIF}
{$ENDIF}
  protected

    procedure PrepareQuery(KindQuery: TpSQLKind);
    procedure PrepareBookMarkSize;
    procedure ClearCalcFields(Buffer: TRecordBuffer); override;
    procedure GetCalcFields(Buffer: TRecordBuffer); override;
    function GetRecord(Buffer: TRecordBuffer; GetMode: TGetMode; DoCheck: Boolean): TGetResult; override; // abstract
    function GetRecordCount: Integer; override;
    function GetRecordSize: Word; override; // abstract

{$IFDEF D_23}
    procedure InternalAddRecord(Buffer: TRecBuf; Append: Boolean); override;
{$ELSE}
    procedure InternalAddRecord(Buffer: Pointer; Append: Boolean); override; // abstract
{$ENDIF}
    procedure InternalCancel; override;
    procedure InternalClose; override; // abstract
    procedure CloseCursor; override;
    procedure InternalDelete; override; // abstract
    procedure InternalFirst; override; // abstract
    procedure InternalHandleException; override; // abstract
    procedure InternalInitFieldDefs; override; // abstract
    procedure InternalInitRecord(Buffer: TRecordBuffer); override; // abstract
    procedure InternalLast; override; // abstract
    procedure InternalOpen; override; // abstract
    procedure InternalPost; override; // abstract
    procedure DoInternalRefresh(Qry: TFIBQuery; Buff: Pointer; ForceFullRefresh: Boolean); virtual;
    procedure InternalRefresh; override;
    procedure InternalSetToRecord(Buffer: TRecordBuffer); override; // abstract
    function IsCursorOpen: Boolean; override; // abstract

    procedure SetBookmarkFlag(Buffer: TRecordBuffer; Value: TBookmarkFlag); override;
{$IFDEF D_23}
    procedure InternalGotoBookmark(BookMark: TBookMark); override;
    procedure SetBookmarkData(Buffer: TRecBuf; Data: TBookMark); override;
{$ELSE}
    procedure InternalGotoBookmark(BookMark: Pointer); override;
    procedure SetBookmarkData(Buffer: TRecordBuffer; Data: Pointer); override;
{$ENDIF}
    procedure SetCachedUpdates(Value: Boolean);
    procedure SetDataSource(Value: TDataSource);
    procedure SetOptions(Value: TpFIBDsOptions);
    procedure SetFieldData(Field: TField; Buffer: Pointer); override; // abstract

    procedure SetRealRecNo(Value: Integer; ToCenter: Boolean = false);
    procedure SetRecNo(Value: Integer); override;
    function MasterFieldsChanged: Boolean; virtual;
    procedure SetParamsFromMaster;
    procedure ForceEndWaitMaster;

    // Filter works
    procedure SetFiltered(Value: Boolean); override;
    procedure ExprParserCreate(const Text: string; Options: TFilterOptions);
    procedure SetFilterData(const Text: string; Options: TFilterOptions);
    procedure SetFilterOptions(Value: TFilterOptions); override;
    procedure SetFilterText(const Value: string); override;
    //

  protected
    FIsClientSorting: Boolean;

    FBeforeFetchRecord: TOnFetchRecord;
    FAfterFetchRecord: TOnFetchRecord;
    FRelationTables: TStringList;
    FCountUpdatesPending: Integer;
{$IFNDEF NO_GUI}
    FSQLScreenCursor: TCursor;
{$ENDIF}
    FSQLs: TSQLs;
    procedure SetBeforeFetchRecord(Value: TOnFetchRecord);
    function IsValidBuffer(FCache: PAnsiChar): Boolean;
    function GetAllFetched: Boolean;
    procedure OpenByTimer(Sender: TObject);
    procedure DoCloseOpen(Sender: TObject);
    function GetWaitEndMasterScroll: Boolean;
    procedure SetWaitEndMasterScroll(Value: Boolean);
    function GetDetailConditions: TDetailConditions;
    procedure SetDetailConditions(Value: TDetailConditions);

    function IsSorted: Boolean;
    procedure DoOnSelectFetch(RecordNumber: Integer; var StopFetching: Boolean);
    procedure PrepareAdditionalInfo;
    procedure RefreshMasterDS;
    procedure AutoStartUpdateTransaction;
    procedure AutoCommitUpdateTransaction;
    (*
      * Properties that are protected in TFIBCustomDataSet, but should be,
      * at some level, made visible. These are good candidates for
      * being made *public*.

    *)

    property Params: TFIBXSQLDA read GetParams;
    property Prepared: Boolean read FPrepared;
    property QDelete: TFIBQuery read FQDelete;
    property QInsert: TFIBQuery read FQInsert;
    property QRefresh: TFIBQuery read FQRefresh;
    property QSelect: TFIBQuery read FQSelect;
    property QUpdate: TFIBQuery read FQUpdate;
    property StatementType: TFIBSQLTypes read GetStatementType;
    property UpdatesPending: Boolean read FUpdatesPending;

    property BufferChunks: Integer read GetBufferChunks write SetBufferChunks;

    property CachedUpdates: Boolean read FCachedUpdates write SetCachedUpdates default false;
    property DeleteSQL: TStrings read GetDeleteSQL write SetDeleteSQL;
    property InsertSQL: TStrings read GetInsertSQL write SetInsertSQL;
    property RefreshSQL: TStrings read GetRefreshSQL write SetRefreshSQL;
    property SelectSQL: TStrings read GetSelectSQL write SetSelectSQL;
    property UniDirectional: Boolean read FUniDirectional write SetUniDirectional default false;
    property UpdateRecordTypes: TFIBUpdateRecordTypes read FUpdateRecordTypes
    write SetUpdateRecordTypes default [cusUnmodified, cusModified,
      cusInserted];
    property UpdateSQL: TStrings read GetUpdateSQL write SetUpdateSQL;
    // -- Events
    property DatabaseDisconnecting: TNotifyEvent read FDatabaseDisconnecting write FDatabaseDisconnecting;
    property DatabaseDisconnected: TNotifyEvent read FDatabaseDisconnected write FDatabaseDisconnected;
    property DatabaseFree: TNotifyEvent read FDatabaseFree write FDatabaseFree;
    property OnUpdateError: TFIBUpdateErrorEvent read FOnUpdateError write FOnUpdateError;
    property OnUpdateRecord: TFIBUpdateRecordEvent read FOnUpdateRecord write FOnUpdateRecord;
    property AfterUpdateRecord: TFIBAfterUpdateRecordEvent read FAfterUpdateRecord write FAfterUpdateRecord;
    property TransactionEnding: TNotifyEvent read FTransactionEnding write FTransactionEnding;
    property TransactionEnded: TNotifyEvent read FTransactionEnded write FTransactionEnded;
    property TransactionFree: TNotifyEvent read FTransactionFree write FTransactionFree;
    property DisableCOCount: Integer read FDisableCOCount;
    property CacheModelOptions: TCacheModelOptions read FCacheModelOptions write SetCacheModelOptions;
  private

    function GetConditions: TConditions;
    procedure SetConditions(Value: TConditions);
    function GetOrderString: string;
    procedure SetOrderString(const OrderTxt: string);
    function GetFieldsString: string;
    procedure SetFieldsString(const Value: string);

  public
    function FN(const FieldName: string): TField; // FindField
    function FBN(const FieldName: string): TField; // FieldByName
    procedure SwapRecords(Recno1, Recno2: Integer);
    function GetCacheSize: Integer;
    procedure ApplyConditions(Reopen: Boolean = false);
    procedure CancelConditions;

    property OrderClause: string read GetOrderString write SetOrderString;
    property FieldsClause: string read GetFieldsString write SetFieldsString;
    property GroupByClause: string read GetGroupByString write SetGroupByString;
    property MainWhereClause: string read GetMainWhereClause write SetMainWhereClause;
    property PlanClause: string read GetPlanClause write SetPlanClause;

    property Conditions: TConditions read GetConditions write SetConditions;

  public
    // public declarations

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Loaded; override;

    property AutoUpdateOptions: TAutoUpdateOptions read FAutoUpdateOptions write FAutoUpdateOptions;

  protected
    vLockResync: Integer;
    function NeedMoveRecordToOrderPos: Boolean;
    procedure MoveRecordToOrderPos;
    procedure CreateDetailTimer;
    procedure CreateScrollTimer;
  protected
    procedure ChangeScreenCursor(var OldCursor: Integer);
    procedure RestoreScreenCursor(const OldCursor: Integer);
  public
    property RunState: TDataSetRunState read FRunState;
    procedure Resync(Mode: TResyncMode); override;
    function BookmarkValid(BookMark: TBookMark): Boolean; override;
{$IFDEF D_XE4}
    function GetFieldData(Field: TField; var Buffer: TValueBuffer): Boolean; override;
    procedure SetFieldData(Field: TField; Buffer: TValueBuffer); override;
{$ELSE}
{$IFDEF D_XE3}
    function GetFieldData(Field: TField; Buffer: TValueBuffer): Boolean; override;
    procedure SetFieldData(Field: TField; Buffer: TValueBuffer); override;
{$ENDIF}
{$ENDIF}
    procedure Post; override;
    function SetRecordPosInBuffer(NewPos: Integer): Integer;

    procedure CloseOpen(const DoFetchAll: Boolean);
    procedure StartTransaction;
    procedure BatchInput(InputObject: TFIBBatchInputStream; SQLKind: TpSQLKind = skInsert);
    procedure BatchOutput(OutputObject: TFIBBatchOutputStream);
    function CachedUpdateStatus: TCachedUpdateStatus;
    procedure CancelUpdates; virtual;
    procedure CheckDatasetClosed(const Reason: string);
    procedure CheckDatasetOpen(const Reason: string);
    procedure CheckNotUniDirectional;
    procedure FetchAll;
    procedure Prepare; virtual;
    procedure UnPrepare;
    procedure RecordModified(Value: Boolean);

    procedure RevertRecord;
    procedure Undelete;
    procedure DisableScrollEvents;
    procedure EnableScrollEvents;
    procedure DisableCloseOpenEvents;
    procedure EnableCloseOpenEvents;

    procedure DisableCalcFields;
    procedure EnableCalcFields;

{$IFDEF SUPPORT_ARRAY_FIELD}
    function ArrayFieldValue(Field: TField): Variant;
    procedure SetArrayValue(Field: TField; Value: Variant);
    function GetElementFromValue(Field: TField; Indexes: array of Integer): Variant;
    procedure SetArrayElementValue(Field: TField; Value: Variant; Indexes: array of Integer);
{$ENDIF}
    function GetRelationTableName(Field: TObject): string;
    function GetRelationFieldName(Field: TObject): string;

    procedure MoveRecord(OldRecno, NewRecno: Integer; NeedResync: Boolean = True); virtual;

    procedure DoSortEx(Fields: array of Integer; Ordering: array of Boolean); overload;
    procedure DoSortEx(Fields: TStrings; Ordering: array of Boolean); overload;

    procedure DoSort(Fields: array of const; Ordering: array of Boolean); virtual;

    function CreateCalcField(FieldClass: TFieldClass; const aName, aFieldName: string; aSize: Integer): TField;
    function CreateLookUpField(FieldClass: TFieldClass;
      const aName, aFieldName: string; aSize: Integer; aLookupDataSet: TDataSet;
      const aKeyFields, aLookupKeyFields, aLookupResultField: string): TField;
    function GetFieldOrigin(Fld: TField): string;
    function FieldByOrigin(const aOrigin: string): TField; overload;
    function FieldByOrigin(const TableName, FieldName: string): TField; overload;
    function FieldByRelName(const FName: string): TField;
    function ReadySelectText: string;
    function TableAliasForField(const aFieldName: string): string;
    function SQLFieldName(const aFieldName: string): string;
    procedure RestoreMacroDefaultValues;

    function IsComputedField(Fld: Variant): Boolean;
    function DomainForField(Fld: Variant): string;
    // Sort Info
    function SortInfoIsValid: Boolean;
    function IsSortedField(Field: TField; var FieldSortOrder: TSortFieldInfo): Boolean;
    function SortFieldsCount: Integer;
    function SortFieldInfo(OrderIndex: Integer): TSortFieldInfo;
    function SortedFields: string;
    property SortFields: Variant read FSortFields;
    property Sorted: Boolean read IsSorted;
    property RelationTables: TStringList read FRelationTables;
    property CachedActive: Boolean read FCachedActive;
  public
    // public routines overridden from TDataSet
    function CompareBookmarks(Bookmark1, Bookmark2: TBookMark): Integer; override;
    function BlobModified(Field: TField): Boolean;
    function CreateBlobStream(Field: TField; Mode: TBlobStreamMode): TStream; override;
    function GetRecordFieldInfo(Field: TField; var TableName, FieldName: string; var RecordKeyValues: TDynArray): Boolean;

    function GetCurrentRecord(Buffer: TRecordBuffer): Boolean; override;
{$IFDEF D2009+}
    function GetBlobFieldData(FieldNo: Integer; var Buffer: TBlobByteData): Integer; override; // MIDAS
{$ENDIF}
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override; // abstract
    procedure DataConvert(Field: TField; Source, Dest: Pointer; ToNative: Boolean); override;
    function GetStateFieldValue(State: TDataSetState; Field: TField): Variant; override;
    procedure DoFieldValidate(Field: TField; Buffer: Pointer);

    function RecordFieldValue(Field: TField; RecNumber: Integer): Variant; overload;
    function RecordFieldValue(Field: TField; aBookmark: TBookMark): Variant; overload;
    // -1 for calculated and lookup fields
    function StringFieldCharSetID(Field: TField): Integer;
    function StringFieldCodePage(Field: TField): Word;
    function BlobFieldCodePage(Field: TField): Word;

    function ExtLocate(const KeyFields: string; const KeyValues: Variant; Options: TExtLocateOptions): Boolean;

    function Locate(const KeyFields: string; const KeyValues: Variant; Options: TLocateOptions): Boolean; override;

    function LocatePrior(const KeyFields: string; const KeyValues: Variant; Options: TLocateOptions): Boolean; // Sister function to Locate

    function LocateNext(const KeyFields: string; const KeyValues: Variant; Options: TLocateOptions): Boolean; // Sister function to Locate
    function ExtLocateNext(const KeyFields: string; const KeyValues: Variant;
      Options: TExtLocateOptions): Boolean; // Sister function to ExtLocate

    function ExtLocatePrior(const KeyFields: string; const KeyValues: Variant;
      Options: TExtLocateOptions): Boolean; // Sister function to ExtLocate

    procedure RefreshFilters;

    function Lookup(const KeyFields: string; const KeyValues: Variant; const ResultFields: string): Variant; override;
    function Translate(Src, Dest: PAnsiChar; ToOem: Boolean): Integer; override;
    function UpdateStatus: TUpdateStatus; override;
    function IsSequenced: Boolean; override; // Scroll bar
    // Before XE6 TDataSet.DefaultFields is a flag that is stale while the dataset is inactive
{$IFDEF D_20}{$WARN HIDING_MEMBER OFF}{$ENDIF}
    property DefaultFields: Boolean read GetDefaultFields;
{$IFDEF D_20}{$WARN HIDING_MEMBER DEFAULT}{$ENDIF}
  public
{$IFDEF CSMonitor}
    procedure SetCSMonitorSupportToQ;
{$ENDIF}
    procedure CacheDelete;
    procedure CacheOpen;
    procedure RefreshClientFields(ForceCalc: Boolean = True);
    function CreateCalcFieldAs(Field: TField): TField;
    procedure CopyFieldsStructure(Source: TFIBCustomDataSet; RecreateFields: Boolean);
    procedure CopyFieldsProperties(Source, Destination: TFIBCustomDataSet);
    procedure AssignProperties(Source: TFIBCustomDataSet);

    procedure OpenAsClone(DataSet: TFIBCustomDataSet);
    procedure Clone(DataSet: TFIBCustomDataSet; RecreateFields: Boolean; FullCopyProperties: Boolean = false);
    function CanCloneFromDataSet(DataSet: TFIBCustomDataSet): Boolean;

    function PrimaryKeyFields(const TableName: string; RelFieldName: Boolean = false): string;
    function FetchNext(FetchCount: DWORD): Integer;
    procedure ReopenLocate(const LocateFieldNames: string);
    function AllFieldValues: Variant;
    procedure ExportDataToScript(OutPut: TStrings; TableName: string = ''; AllFields: Boolean = false);
    procedure ExportDataToScriptFile(const FileName: string; TableName: string = ''; AllFields: Boolean = false);
  protected
    procedure InternalFullRefresh(NeedResync: Boolean = True; ReopenRefreshSQL: Boolean = True);
  public
    procedure FullRefresh;
  private
    FMasSourceDisableCount: Integer;
  public
    procedure DisableMasterSource;
    procedure EnableMasterSource;
    function MasterSourceDisabled: Boolean;

    property CacheSize: Integer read GetCacheSize;
    // Public properties
    property DBHandle: PISC_DB_HANDLE read GetDBHandle;
    property TRHandle: PISC_TR_HANDLE read GetTRHandle;
    property AllFetched: Boolean read GetAllFetched;
    property WaitEndMasterInterval: Integer read FWaitEndMasterInterval write FWaitEndMasterInterval;
    property WaitEndMasterScroll: Boolean read GetWaitEndMasterScroll write SetWaitEndMasterScroll;
    property CountUpdatesPending: Integer read FCountUpdatesPending;
  public
    { ISQLObject }
    function ParamCount: Integer;
    function ParamName(ParamIndex: Integer): string;
    function FieldsCount: Integer;
    function FieldName(FieldIndex: Integer): string;
    function FieldExist(const FieldName: string; var FieldIndex: Integer): Boolean;
    function ParamExist(const ParamName: string; var ParamIndex: Integer): Boolean;
    function FieldValue(const FieldName: string; Old: Boolean): Variant; overload;
    function FieldValue(const FieldIndex: Integer; Old: Boolean): Variant; overload;
    function ParamValue(const ParamName: string): Variant; overload;
    function DefMacroValue(const MacroName: string): string;
    function ParamValue(const ParamIndex: Integer): Variant; overload;
    procedure SetParamValue(const ParamIndex: Integer; aValue: Variant);
    procedure SetParamValues(const ParamValues: array of Variant); overload;
    procedure SetParamValues(const ParamNames: string; ParamValues: array of Variant); overload;

    function IEof: Boolean;
    procedure INext;
    procedure ParseParamToFieldsLinks(Dest: TStrings); virtual; abstract;
  protected
    procedure LoadRepositoryInfo; virtual; abstract;

    { END  ISQLObject }

  public
    (*
      * Published properties implemented in TFIBCustomDataSet
    *)
    // -- Properties

    property Transaction: TFIBTransaction read GetTransaction write SetTransaction;
    property Database: TFIBDatabase read GetDatabase write SetDatabase;
    property BeforeFetchRecord: TOnFetchRecord read FBeforeFetchRecord write SetBeforeFetchRecord;
    property AfterFetchRecord: TOnFetchRecord read FAfterFetchRecord write FAfterFetchRecord;
    property OnGetRecordError: TDataSetErrorEvent read FOnGetRecordError write FOnGetRecordError;
    property Options: TpFIBDsOptions read FOptions write SetOptions
{$IFDEF DFM_VERSION1}
    default [poTrimCharFields, poStartTransaction, poAutoFormatFields,
      poRefreshAfterPost];
{$ELSE}
    stored false;
{$ENDIF}
    property FieldOriginRule: TFieldOriginRule read FFieldOriginRule write FFieldOriginRule default forTableAndFieldName;

    property DetailConditions: TDetailConditions read GetDetailConditions write SetDetailConditions stored false;

    property UpdateTransaction: TFIBTransaction read GetUpdateTransaction write SetUpdateTransaction stored StoreUpdTransaction;
    property PrepareOptions: TpPrepareOptions read FPrepareOptions write SetPrepareOptions stored false;
    property AutoCommit: Boolean read FAutoCommit write FAutoCommit default false;
    property OnFieldChange: TFieldNotifyEvent read FOnFieldChange write FOnFieldChange;
    property OnEnableControls: TDataSetNotifyEvent read FOnEnableControls write FOnEnableControls;
    property OnDisableControls: TDataSetNotifyEvent read FOnDisableControls write FOnDisableControls;
    property OnEndScroll: TDataSetNotifyEvent read FOnEndScroll write SetOnEndScroll;
    property OnFillClientBlob: TOnFillClientBlob read FOnFillClientBlob write FOnFillClientBlob;
    property OnReadBlobField: TOnBlobFieldProcessing read FOnBlobFieldRead write FOnBlobFieldRead;
    property OnWriteBlobField: TOnBlobFieldProcessing read FOnBlobFieldWrite write FOnBlobFieldWrite;

{$IFNDEF NO_GUI}
    property SQLScreenCursor: TCursor read FSQLScreenCursor write FSQLScreenCursor default crDefault;
{$ENDIF}
    property SQLs: TSQLs read FSQLs write FSQLs stored false;
    property RefreshTransactionKind: TTransactionKind
    read FRefreshTransactionKind write SetRefreshTransactionKind
    default tkReadTransaction;

    property BeforeStartTransaction: TNotifyEvent read FBeforeStartTr write FBeforeStartTr;
    property AfterStartTransaction: TNotifyEvent read FAfterStartTr write FAfterStartTr;
    property BeforeEndTransaction: TEndTrEvent read FBeforeEndTr write FBeforeEndTr;
    property AfterEndTransaction: TEndTrEvent read FAfterEndTr write FAfterEndTr;

    property BeforeStartUpdateTransaction: TNotifyEvent read FBeforeStartUpdTr write FBeforeStartUpdTr;
    property AfterStartUpdateTransaction: TNotifyEvent read FAfterStartUpdTr write FAfterStartUpdTr;
    property BeforeEndUpdateTransaction: TEndTrEvent read FBeforeEndUpdTr write FBeforeEndUpdTr;
    property AfterEndUpdateTransaction: TEndTrEvent read FAfterEndUpdTr write FAfterEndUpdTr;

    property AllowedUpdateKinds: TUpdateKinds read FAllowedUpdateKinds write FAllowedUpdateKinds default [ukModify, ukInsert, ukDelete];
{$IFDEF CSMonitor}
    property CSMonitorSupport: TCSMonitorSupport read FCSMonitorSupport write SetCSMonitorSupport;
{$ENDIF}
  end;

  TFIBDataSet = class(TFIBCustomDataSet)
  private
    function DoStoreActive: Boolean;
  public
    property Params;
    property Prepared;
    property QDelete;
    property QInsert;
    property QRefresh;
    property QSelect;
    property QUpdate;
    property StatementType;
    property UpdatesPending;
  public
    property Bof;
    property BookMark;
    property Designer;
    property Eof;
    property FieldCount;
    property FieldDefs;
    property Fields;
    property FieldValues;
    property Modified;
    property RecordCount;
    property State;
    property BufferChunks;
  published
    property CachedUpdates;
    property UniDirectional;
    property UpdateRecordTypes;

    property UpdateSQL;
    property DeleteSQL;
    property InsertSQL;
    property RefreshSQL;
    property SelectSQL;
    property Filter;
    property FilterOptions;
    property CacheModelOptions;
    property DatabaseDisconnecting;
    property DatabaseDisconnected;
    property DatabaseFree;
    property OnUpdateError;
    property OnUpdateRecord;
    property AfterUpdateRecord;
    property TransactionEnding;
    property TransactionEnded;
    property TransactionFree;
    property AutoUpdateOptions;

    property Conditions;
  published
    (*
      * Published out of TDataset
    *)

    property Active stored DoStoreActive;
    property AutoCalcFields;
    // property DataSource read GetDataSource write SetDataSource;
    property AfterCancel;
    property AfterClose;
    property AfterDelete;
    property AfterEdit;
    property AfterInsert;
    property AfterOpen;
    property AfterPost;
    property AfterScroll;
    property BeforeCancel;
    property BeforeClose;
    property BeforeDelete;
    property BeforeEdit;
    property BeforeInsert;
    property BeforeOpen;
    property BeforePost;
    property BeforeScroll;
    property OnCalcFields;
    property OnDeleteError;
    property OnEditError;
    property OnNewRecord;
    property OnPostError;

    property BeforeRefresh;
    property AfterRefresh;
    { TFIBCustomDataSet }
    property AllowedUpdateKinds;
    property Transaction;
    property Database;
    property BeforeFetchRecord;
    property AfterFetchRecord;
    property OnGetRecordError;
    property Options;
    property DetailConditions;

    property UpdateTransaction;
    property PrepareOptions;
    property FieldOriginRule;
    property AutoCommit;
    property OnFieldChange;
    property OnEnableControls;
    property OnDisableControls;
    property OnEndScroll;
    property OnFillClientBlob;
    property OnReadBlobField;
    property OnWriteBlobField;

{$IFNDEF NO_GUI}
    property SQLScreenCursor;
{$ENDIF}
    property SQLs;
    property RefreshTransactionKind;

    property BeforeStartTransaction;
    property AfterStartTransaction;
    property BeforeEndTransaction;
    property AfterEndTransaction;

    property BeforeStartUpdateTransaction;
    property AfterStartUpdateTransaction;
    property BeforeEndUpdateTransaction;
    property AfterEndUpdateTransaction;
    property DataSource read GetDataSource write SetDataSource;
{$IFDEF CSMonitor}
    property CSMonitorSupport;
{$ENDIF}
  end;

  // The stream returned by CreateBlobStream for the value of a BLOB or ARRAY field
  TFIBDSFieldStream = class(TStream)
  protected
    FModified: Boolean;
    FField: TField;
    FFieldStream: TFIBFieldStream;
    FOnBlobFieldRead: TOnBlobFieldProcessing;
    procedure DoCallBack(BlobSize: Integer; BytesProcessing: Integer; var Stop: Boolean);
  public
    constructor Create(AField: TField; AFieldStream: TFIBFieldStream; Mode: TBlobStreamMode);
    destructor Destroy; override;
    function Read(var Buffer; Count: LongInt): LongInt; override;
    function Seek(Offset: LongInt; Origin: Word): LongInt; override;
    procedure SetSize(NewSize: LongInt); override;
    function Write(const Buffer; Count: LongInt): LongInt; override;
  end;

  (*
    * Support routines
  *)
function RecordDataLength(n: Integer): Long;
function IsDBKeyField(Field: TObject): Boolean;
function LocateOptionsToExtLocateOptions(LocateOptions: TLocateOptions): TExtLocateOptions;

type
  TFIBFilterType = (ftByField, ftCopy);

procedure FilterOut(FromDS: TFIBCustomDataSet);
(* Clear the entire record cache, and do everything short of
  closing the data set--but don't delete anything, etc.. *)

procedure Sort(DataSet: TFIBCustomDataSet; aFields: array of const; Ordering: array of Boolean);

(*
  * More constants
*)
const
  DefaultFieldClasses: array [ftUnknown .. ftTypedBinary] of TFieldClass = (
    nil,                // ftUnknown
    TFIBStringField,    // ftString
    TFIBSmallIntField,  // ftSmallint
    TFIBIntegerField,   // ftInteger
    TWordField,         // ftWord
    TFIBBooleanField,   // ftBoolean
    TFIBFloatField,     // ftFloat
    TCurrencyField,     // ftCurrency
    TFIBBCDField,       // ftBCD
    TFIBDateField,      // ftDate
    TFIBTimeField,      // ftTime
    TFIBDateTimeField,  // ftDateTime
{$IFDEF SUPPORT_ARRAY_FIELD}
    TFIBArrayField,     // ftBytes
{$ELSE}
    TBytesField,        // ftBytes
{$ENDIF}
    TVarBytesField,     // ftVarBytes
    TAutoIncField,      // ftAutoInc
    TFIBBlobField,      // ftBlob
    TFIBMemoField,      // ftMemo
    TGraphicField,      // ftGraphic
    TFIBBlobField,      // ftFmtMemo
    TFIBBlobField,      // ftParadoxOle
    TFIBBlobField,      // ftDBaseOle
    TFIBBlobField       // ftTypedBinary
  );

const
  SNoAction = 'No Action';

implementation

uses
  StrUtil, FIBConsts, pFIBDataInfo, VariantRtn, IB_ErrorCodes,
  pFIBCacheQueries, DSContainer, FIBTypes, FIBCharSets;

const
  DiffSizesRecData = SizeOf(TRecordData) - SizeOf(TSavedRecordData);
  LocateParamPrefix = 'LOCATE_';

  // INT128, DECFLOAT(16) and DECFLOAT(34) values are cached in the server format
function CacheToDecimal(fi: PFIBFieldDescr; Data: Pointer): TFBDecimal;
begin
  Result := FBDecimalFromRaw(fi^.fdDataType, fi^.fdDataScale, Data);
end;

function CacheToBcd(fi: PFIBFieldDescr; Data: Pointer; out Value: TBcd): Boolean;
begin
  Result := FBRawToBcd(fi^.fdDataType, fi^.fdDataScale, Data, Value);
end;

function IsTimeZoneField(fi: PFIBFieldDescr): Boolean;
begin
  Result := (fi^.fdDataType = SQL_TIME_TZ_EX) or (fi^.fdDataType = SQL_TIMESTAMP_TZ_EX);
end;

// Descriptor of a data field of the dataset, nil for calculated, lookup and unknown fields
function DataFieldDescr(DS: TFIBCustomDataSet; Field: TField): PFIBFieldDescr;
begin
  if (Field <> nil) and (Field.FieldKind = fkData) and (Field.FieldNo > 0) and (Field.FieldNo <= DS.vrdFieldCount) then
    Result := DS.vFieldDescrList[Field.FieldNo - 1]
  else
    Result := nil;
end;

// Descriptor of a TIME/TIMESTAMP WITH TIME ZONE field, nil for other fields
function TimeZoneFieldDescr(DS: TFIBCustomDataSet; Field: TField): PFIBFieldDescr;
begin
  Result := DataFieldDescr(DS, Field);
  if (Result <> nil) and not IsTimeZoneField(Result) then
    Result := nil;
end;

// Local time of a TIME/TIMESTAMP WITH TIME ZONE cache value
function TimeZoneCacheToDateTime(fi: PFIBFieldDescr; Data: Pointer): TDateTime;
begin
  if fi^.fdDataType = SQL_TIME_TZ_EX then
    Result := TimeStampToDateTime(TimeStamp(DateDelta, FBTimeTZToMSecs(PISC_TIME_TZ_EX(Data)^)))
  else
    Result := TimeStampToDateTime
      (MSecsToTimeStamp(FBTimeStampTZToMSecs(PISC_TIMESTAMP_TZ_EX(Data)^)));
end;

// TIME/TIMESTAMP WITH TIME ZONE from the record cache to a parameter
procedure CacheToTimeZoneParam(Param: TFIBXSQLVAR; fi: PFIBFieldDescr; Data: Pointer);
var
  vTimeTZ: TISC_TIME_TZ;
  vTimeStampTZ: TISC_TIMESTAMP_TZ;
begin
  if fi^.fdDataType = SQL_TIME_TZ_EX then
    with PISC_TIME_TZ_EX(Data)^ do
      // assigned local time, the server resolves it in the time zone
      if ext_offset = FBUnresolvedOffset then
        Param.SetAsDateTimeTZ(FBTimeTZToMSecs(PISC_TIME_TZ_EX(Data)^) / MSecsPerDay, time_zone)
      else
        begin
          vTimeTZ.utc_time := utc_time;
          vTimeTZ.time_zone := time_zone;
          Param.SetAsTimeTZ(vTimeTZ);
        end
  else
    with PISC_TIMESTAMP_TZ_EX(Data)^ do
      if ext_offset = FBUnresolvedOffset then
        Param.SetAsDateTimeTZ
        (TimeStampToDateTime(MSecsToTimeStamp(FBTimeStampTZToMSecs(PISC_TIMESTAMP_TZ_EX(Data)^))), time_zone)
      else
        begin
          vTimeStampTZ.utc_timestamp := utc_timestamp;
          vTimeStampTZ.time_zone := time_zone;
          Param.SetAsTimeStampTZ(vTimeStampTZ);
        end;
end;

// Cache data of a TIME/TIMESTAMP WITH TIME ZONE field in the active record
function ActiveTimeZoneData(Field: TField; out fi: PFIBFieldDescr; out Data: Pointer): Boolean;
var
  DS: TFIBCustomDataSet;
  Buff: TRecordBuffer;
begin
  Result := false;
  if (Field = nil) or not(Field.DataSet is TFIBCustomDataSet) then
    Exit;
  DS := TFIBCustomDataSet(Field.DataSet);
  fi := TimeZoneFieldDescr(DS, Field);
  if fi = nil then
    Exit;
  Buff := DS.GetActiveBuf;
  if Buff = nil then
    Exit;
  Data := Buff + fi^.fdDataOfs;
  Result := True;
end;

// True if Param does not hold the time zone value of the cache,
// a value not resolved by the server yet is always reported as changed
function TimeZoneParamChanged(Param: TFIBXSQLVAR; fi: PFIBFieldDescr; Data: Pointer): Boolean;
begin
  Result := True;
  if fi^.fdDataType = SQL_TIME_TZ_EX then
    begin
      if (Param.SQLType = SQL_TIME_TZ) and (PISC_TIME_TZ_EX(Data)^.ext_offset <> FBUnresolvedOffset) then
        with PISC_TIME_TZ(Param.Data^.sqldata)^ do
          Result := (utc_time <> PISC_TIME_TZ_EX(Data)^.utc_time) or (time_zone <> PISC_TIME_TZ_EX(Data)^.time_zone);
    end
  else if (Param.SQLType = SQL_TIMESTAMP_TZ) and (PISC_TIMESTAMP_TZ_EX(Data)^.ext_offset <> FBUnresolvedOffset) then
    with PISC_TIMESTAMP_TZ(Param.Data^.sqldata)^ do
      Result := (utc_timestamp.timestamp_date <> PISC_TIMESTAMP_TZ_EX(Data)^.utc_timestamp.timestamp_date) or
        (utc_timestamp.timestamp_time <> PISC_TIMESTAMP_TZ_EX(Data)^.utc_timestamp.timestamp_time) or
        (time_zone <> PISC_TIMESTAMP_TZ_EX(Data)^.time_zone);
end;

function IsSysField(const FieldName: string): Boolean;
begin
  Result := false;
  if (Length(FieldName) > 4) then
    if (FieldName[1] = 'R') and (FieldName[2] = 'D') and (FieldName[3] = 'B') and (FieldName[4] = '$') then
      Result := True;
end;

function IsDBKeyField(Field: TObject): Boolean;
begin
  Result := ((Field is TFIBStringField) and (TFIBStringField(Field).IsDBKey)) or
    ((Field is TFieldDef) and (TFieldDef(Field).DataType = ftString) and (TFieldDef(Field).Name = 'DB_KEY'))
end;

(*
  * TFIBStringField - implementation
*)

destructor TFIBStringField.Destroy;
begin
  if Assigned(FReservedBuffer) then
    FreeMem(FReservedBuffer);
  if FDataSet is TFIBCustomDataSet then
    TFIBCustomDataSet(FDataSet).vBeforeCloseEvents.Remove(UnPrepare);

  inherited;
end;

class procedure TFIBStringField.CheckTypeSize(Value: Integer);
begin
  (*
    * Just don't check. Any string size is valid.
  *)
end;

procedure TFIBStringField.Prepare;
var
  F: TFIBXSQLVAR;
  st: Short;
  p: PSmallint;
begin
  if DataSet is TFIBCustomDataSet then
    with TFIBCustomDataSet(DataSet) do
      if QSelect.SQL.Count > 0 then
        begin
          if not QSelect.Prepared then
            QSelect.Prepare;
          F := QSelect.FindField(Self.FieldName);
          if F <> nil then
            begin
              st := F.SqlSubType;
              p := @st;
              Inc(p, 1);
              FCollateNumber := PByte(p)^;
              FCharacterSetName := F.CharacterSet;
            end
          else
            begin
              FCollateNumber := 0;
              FCharacterSetName := UnknownStr;
            end
        end;
  FIsDBKey := IsDBKey;
  FPrepared := True;
end;

function TFIBStringField.CodePage: Word;
begin
  // calculated and lookup: system code page, as TStringField
  if (FieldKind = fkData) and (DataSet is TFIBCustomDataSet) then
    Result := TFIBCustomDataSet(DataSet).StringFieldCodePage(Self)
  else
    Result := FIBCodePageSystem;
end;

procedure TFIBStringField.UnPrepare(Sender: TObject);
begin
  FPrepared := false;
end;

procedure TFIBStringField.SetDataSet(ADataSet: TDataSet);
begin
  inherited SetDataSet(ADataSet);
  if DataSet is TFIBCustomDataSet then
    TFIBCustomDataSet(DataSet).vBeforeCloseEvents.Remove(UnPrepare);

  if Assigned(ADataSet) and (ADataSet is TFIBCustomDataSet) then
    begin
      FEmptyStrToNull := psSetEmptyStrToNull in TFIBCustomDataSet(ADataSet).FPrepareOptions;
      TFIBCustomDataSet(ADataSet).vBeforeCloseEvents.Add(UnPrepare);
      FDataSet := ADataSet;
    end;
end;

function TFIBStringField.GetAsDB_KEY: string;
var
  i: Integer;
  p: TDataBuffer;
begin
  if not GetDataToReserveBuffer then
    begin
      Result := '';
    end
  else
    for i := 0 to (Size div 4) - 1 do
      begin
        p := FReservedBuffer;
        Inc(p, i * 4);
        Result := Result + Format('%-8.8x', [PInteger(p)^]);
      end;
end;

function TFIBStringField.IsDBKey: Boolean;
begin
  with TFIBDataSet(DataSet) do
    if (FieldKind = fkData) and Assigned(vFieldDescrList) and (vFieldDescrList.Capacity > 0) then
      begin
        Result := vFieldDescrList[FieldNo - 1]^.fdIsDBKey;
      end
    else
      Result := false;
end;

function TFIBStringField.SqlSubType: Integer;
var
  fi: PFIBFieldDescr;
begin
  if (FieldKind <> fkData) or not(DataSet is TFIBDataSet) then
    Result := -1
  else
    begin
      fi := TFIBDataSet(DataSet).vFieldDescrList[FieldNo - 1];
      Result := fi.fdSubType;
    end;
end;

function TFIBStringField.CharacterSet: string;
begin
  if FieldKind <> fkData then
    Result := UnknownStr
  else
    begin
      if not FPrepared then
        Prepare;
      Result := FCharacterSetName;
    end;
end;

function TFIBStringField.GetDataToReserveBuffer: Boolean;
begin
  if DataSet.Active then
    begin
      if not FPrepared then
        Prepare;
      if not Assigned(FReservedBuffer) then
        begin
          GetMem(FReservedBuffer, DataSize);
          FReservedBuffer[Size] := ZeroData;
        end;
      Result := GetData(FReservedBuffer)
    end
  else
    Result := false
end;

function TFIBStringField.InternalGetAsString(var IsNull: Boolean): string;
begin
  IsNull := false;
  if FIsDBKey then
    begin
      Result := GetAsDB_KEY;
      Exit;
    end
  else if GetDataToReserveBuffer then
    begin
      if (FReservedBuffer^ = ZeroData) then
        Result := ''
      else
        Result := DecodeString(PAnsiChar(FReservedBuffer), Length(PAnsiChar(FReservedBuffer)), CodePage);
    end
  else
    begin
      IsNull := True;
      Result := '';
    end;
end;

function TFIBStringField.GetAsString: string;
var
  IsNull: Boolean;
begin
  Result := InternalGetAsString(IsNull);
end;

function TFIBStringField.GetAsVariant: Variant;
var
  IsNull: Boolean;
begin
  Result := InternalGetAsString(IsNull);
  if IsNull then
    Result := Null
end;

function TFIBStringField.GetAsNativeData: FIBByteString;
begin
  Include(TFIBCustomDataSet(DataSet).FRunState, drsInFieldAsData);
  try
    if not GetDataToReserveBuffer then
      Result := ''
    else
      begin
        SetLength(Result, FValueLength);
        Move(FReservedBuffer^, Result[1], FValueLength)
      end;
  finally
    Exclude(TFIBCustomDataSet(DataSet).FRunState, drsInFieldAsData);
  end
end;

const
  vEmptyStrBuffer: PAnsiChar = #0;

procedure TFIBStringField.SetAsNativeData(const Value: FIBByteString);
begin
  if FieldKind <> fkData then
    raise Exception.Create('Method TFIBStringField.SetAsNativeData:' + CLRF +
      'DataSet ' + CmpFullName(Self) + ' field "' + FieldName +
      '" is not data field');
  Include(TFIBCustomDataSet(DataSet).FRunState, drsInFieldAsData);
  try
    FValueLength := Length(Value);
    if FValueLength > 0 then
      begin
        SetData(@Value[1])
      end
    else
      TFIBDataSet(DataSet).SetFieldData(Self, vEmptyStrBuffer);
  finally
    Exclude(TFIBCustomDataSet(DataSet).FRunState, drsInFieldAsData);
  end
end;

procedure TFIBStringField.SetSize(Value: Integer);
begin
  inherited SetSize(Value);
  FreeMem(FReservedBuffer);
  FReservedBuffer := nil;
end;

{$IFDEF UNICODE_TO_STRING_FIELDS}

function TFIBStringField.GetDataSize: Integer;
begin
  Result := inherited GetDataSize;
  if (FieldKind = fkData) and TFIBDataSet(DataSet).Database.NeedUnicodeFieldTranslation(Byte(SqlSubType)) then
    Result := (Result - 1) * TFIBDataSet(DataSet).Database.BytesInUnicodeChar
      (Byte(SqlSubType)) + 1

end;
{$ENDIF}

procedure TFIBStringField.Clear;
begin
  SetData(nil);
end;

procedure TFIBStringField.SetAsString(const Value: string);

  procedure InternalSetAsString(const vValue: AnsiString);
  begin
    FValueLength := Length(vValue);
    if FValueLength > 0 then
      begin
        SetData(@vValue[1])
      end
    else
      TFIBDataSet(DataSet).SetFieldData(Self, vEmptyStrBuffer);
  end;

var
  TempStr: string;
  Count, Excess: Integer;
  Bytes: FIBByteString;
begin
  vInSetAsString := True;
  try
    if FieldKind = fkData then
      begin
        // Size is in characters, the buffer in bytes: cut at a character boundary
        Count := Length(Value);
        if Count > Size then
          Count := Size;
        repeat
{$IFDEF D2009+}
          if (Count > 0) and (Count < Length(Value)) and (Value[Count] >= #$D800) and (Value[Count] <= #$DBFF) then
            Dec(Count);
{$ENDIF}
          Bytes := EncodeString(Copy(Value, 1, Count), CodePage);
          Excess := Length(Bytes) - (DataSize - 1);
          if Excess <= 0 then
            Break;
          Dec(Count, (Excess + 1) div 2);
        until False;
        InternalSetAsString(Bytes);
      end
    else
      begin
        TempStr := Value;
        if Length(Value) > Size then
          SetLength(TempStr, Size);
        InternalSetAsString(AnsiString(TempStr));
      end;
  finally
    vInSetAsString := false;
  end;
end;

{$IFDEF D2009+}

function TFIBStringField.GetAsAnsiString: AnsiString;
begin
  Result := inherited GetAsAnsiString;
  if FieldKind = fkData then
    SetStringCodePage(RawByteString(Result), CodePage);
end;

procedure TFIBStringField.SetAsAnsiString(const Value: AnsiString);
var
  CP: Word;
begin
  CP := CodePage;
  // another code page is converted; NONE and OCTETS are stored raw
  if (CP <> FIBCodePageSystem) and (StringCodePage(Value) <> CP) then
    SetAsString(string(Value))
  else
    inherited SetAsAnsiString(Value);
end;
{$ENDIF}

procedure TFIBWideStringField.SetSize(Value: Integer);
begin
  inherited SetSize(Value);
  if FCreated then
    begin
    end;
end;

function TFIBWideStringField.GetDataSize: Integer;
begin
  if FieldKind in [fkCalculated, fkLookup] then
    Result := (Size * 3) + 1
  else
    begin
      if not FPrepared then
        Prepare;
      Result := FDataSize
    end;
end;

function TFIBWideStringField.GetBytesValue(var Value: FIBByteString): Boolean;
begin
  if not Assigned(FReservedBuffer) then
    begin
      GetMem(FReservedBuffer, DataSize);
      FReservedBuffer[Size] := ZeroData;
    end;
  Include(TFIBDataSet(DataSet).FRunState, drsInFieldAsData);
  try
    Result := GetData(FReservedBuffer);
  finally
    Exclude(TFIBDataSet(DataSet).FRunState, drsInFieldAsData)
  end;
  if Result then
    if FReservedBuffer^ = ZeroData then
      Value := ''
    else
      begin
        SetLength(Value, FValueLength);
        if FValueLength > 0 then
          Move(FReservedBuffer^, Value[1], FValueLength);
      end;
end;

function TFIBWideStringField.GetDataToReserveBuffer: Boolean;
begin
  if DataSet.Active then
    begin
      if not FPrepared then
        Prepare;
      if not Assigned(FReservedBuffer) then
        begin
          GetMem(FReservedBuffer, DataSize);
          FReservedBuffer[Size] := ZeroData;
        end;
      Result := GetData(FReservedBuffer)
    end
  else
    Result := false
end;

function TFIBWideStringField.GetAsString: string;
begin
  if FieldKind <> fkData then
    begin
      Result := inherited;
      Exit;
    end;
  if GetDataToReserveBuffer then
    Result := PWideChar(FReservedBuffer)
  else
    Result := '';
end;

function TFIBWideStringField.GetAsNativeData: FIBByteString;
begin

  Include(TFIBCustomDataSet(DataSet).FRunState, drsInFieldAsData);
  try
    if not GetDataToReserveBuffer then
      Result := ''
    else
      begin
        SetLength(Result, FValueLength);
        Move(FReservedBuffer^, Result[1], FValueLength)
      end;
  finally
    Exclude(TFIBCustomDataSet(DataSet).FRunState, drsInFieldAsData);
  end
end;

procedure TFIBWideStringField.SetAsNativeData(const Value: FIBByteString);
begin
  if FieldKind <> fkData then
    raise Exception.Create('Method TFIBWideStringField.SetAsNativeData:' + CLRF +
      'DataSet ' + CmpFullName(Self) + ' field "' + FieldName +
      '" is not data field');
  Include(TFIBCustomDataSet(DataSet).FRunState, drsInFieldAsData);
  try
    FValueLength := Length(Value);
    if FValueLength > 0 then
      SetData(@Value[1])
    else
      TFIBDataSet(DataSet).SetFieldData(Self, vEmptyStrBuffer);
  finally
    Exclude(TFIBCustomDataSet(DataSet).FRunState, drsInFieldAsData);
  end
end;

constructor TFIBWideStringField.Create(AOwner: TComponent);
begin
  try
    inherited Create(AOwner);
    FSqlSubType := -1;
  finally
    FCreated := True
  end;
end;

destructor TFIBWideStringField.Destroy;
begin
  if FDataSet is TFIBCustomDataSet then
    TFIBCustomDataSet(FDataSet).vBeforeCloseEvents.Remove(UnPrepare);

  if Assigned(FReservedBuffer) then
    FreeMem(FReservedBuffer);

  inherited;
end;

procedure TFIBWideStringField.SetDataSet(ADataSet: TDataSet);
begin
  inherited SetDataSet(ADataSet);
  if DataSet is TFIBCustomDataSet then
    TFIBCustomDataSet(DataSet).vBeforeCloseEvents.Remove(UnPrepare);

  if Assigned(ADataSet) and (ADataSet is TFIBCustomDataSet) then
    begin
      FEmptyStrToNull := psSetEmptyStrToNull in TFIBCustomDataSet(ADataSet).FPrepareOptions;
      TFIBCustomDataSet(ADataSet).vBeforeCloseEvents.Add(UnPrepare);
      // FDataSet:=ADataSet;
    end;
  FDataSet := ADataSet;
end;

{$IFDEF D2006+}

procedure TFIBWideStringField.CopyData(Source, Dest: Pointer);
var
  s: string;
  L: Integer;
begin
  // Call when Field Validate
  if DataSet is TFIBCustomDataSet then
    s := DecodeString(PAnsiChar(Source), Length(PAnsiChar(Source)),
      TFIBCustomDataSet(DataSet).StringFieldCodePage(Self))
  else
    s := UTF8Decode(PAnsiChar(Source));
  // Dest has DataSize bytes, the UTF8 source can hold more characters
  L := Length(s);
  if L > DataSize div SizeOf(Char) - 1 then
    L := DataSize div SizeOf(Char) - 1;
  if L > 0 then
    Move(PChar(s)^, Dest^, L * SizeOf(Char))
  else
    L := 0;
  PChar(Dest)[L] := #0;
end;
{$ENDIF}

procedure TFIBWideStringField.Prepare;
var
  F: TFIBXSQLVAR;
  st: Short;
  p: PSmallint;
begin
  if DataSet is TFIBCustomDataSet then
    with TFIBCustomDataSet(DataSet) do
      begin
        if not QSelect.Prepared then
          QSelect.Prepare;
        F := QSelect[Self.FieldName];
        if F <> nil then
          begin
            FSqlSubType := F.SqlSubType;
            st := F.SqlSubType;
            p := @st;
            Inc(p, 1);
            FCollateNumber := PByte(p)^;

            // FCollateNumber:=PByte(TPtrAsInteger(@st)+1)^;
            FCharacterSetName := F.CharacterSet;
            FDataSize := F.Size;

            if (DataSet is TFIBDataSet) then
              begin
                with TFIBDataSet(DataSet).Database do
                  FNeedUnicodeConvert := NeedUnicodeFieldTranslation
                    (Byte(F.SqlSubType)) and (Byte(F.SqlSubType) in UnicodeCharSets)
              end
            else
              FNeedUnicodeConvert := false;

          end
        else
          begin
            FSqlSubType := -1;
            FDataSize := (Size * 3) + 1;
            FCollateNumber := 0;
            FCharacterSetName := UnknownStr;
          end;

      end;

  FPrepared := True;
end;

procedure TFIBWideStringField.UnPrepare(Sender: TObject);
begin
  FPrepared := false;
end;

procedure TFIBWideStringField.Clear;
begin
  SetData(nil);
end;

function TFIBWideStringField.CharacterSet: string;
begin
  if FieldKind <> fkData then
    Result := UnknownStr
  else
    begin
      if not FPrepared then
        Prepare;
      Result := FCharacterSetName;
    end;
end;

function TFIBWideStringField.SqlSubType: Integer;
var
  fi: PFIBFieldDescr;
begin
  if (FieldKind <> fkData) or not(DataSet is TFIBDataSet) then
    Result := -1
  else
    begin
      fi := TFIBDataSet(DataSet).vFieldDescrList[FieldNo - 1];
      Result := fi.fdSubType;
    end;
end;

function TFIBWideStringField.CollateNumber: Byte;
begin
  if FieldKind <> fkData then
    Result := 0
  else
    begin
      if not FPrepared then
        Prepare;
      Result := FCollateNumber;
    end;
end;

(*
  * TFIBLargeIntField - implementation
*)

function TFIBLargeIntField.GetOldAsInt64: Int64;
var
  SaveState: TDataSetState;
begin
  if FieldKind in [fkData, fkInternalCalc] then
    begin
      SaveState := DataSet.State;
      TFIBCustomDataSet(DataSet).SetTempState(dsOldValue);
      try
        Result := AsLargeInt;
      finally
        TFIBCustomDataSet(DataSet).RestoreState(SaveState);
      end;
    end
  else
    Result := 0;
end;

procedure TFIBLargeIntField.SetVarValue(const Value: Variant);
begin
  if VarIsNull(Value) or VarIsEmpty(Value) then
    Clear
  else
    SetAsLargeInt(Value);
end;

(*
  * TFIBFMTBCDField - implementation
*)

// The field descriptor of a DECFLOAT data field of a FIBPlus dataset, nil for other fields
function DecFloatFieldDescr(Field: TField): PFIBFieldDescr;
begin
  Result := nil;
  if not(Field.DataSet is TFIBCustomDataSet) then
    Exit;
  Result := DataFieldDescr(TFIBCustomDataSet(Field.DataSet), Field);
  if (Result <> nil) and (Result^.fdDataType <> SQL_DEC16) and (Result^.fdDataType <> SQL_DEC34) then
    Result := nil;
end;

type
  // State of the dataset while a DECFLOAT field reads its value, see BeginDecFloatRead
  TDecFloatRead = record
    DS: TFIBCustomDataSet;
    fi: PFIBFieldDescr;
    SaveField: TField;
    SaveReturned: Boolean;
  end;

  TDecFloatReadResult = (drNotDecFloat, drNull, drBcd, drSpecial);

  // Until EndDecFloatRead GetFieldData does not raise a conversion error for a DECFLOAT
  // value of Field which TBcd can not hold (NaN, Infinity, more than 64 digits):
  // it keeps the value in the server format and reports no data.
  // Returns False for fields which are not DECFLOAT fields of a FIBPlus dataset
  // (INT128 always fits TBcd).
function BeginDecFloatRead(Field: TField; out R: TDecFloatRead): Boolean;
begin
  R.fi := DecFloatFieldDescr(Field);
  Result := R.fi <> nil;
  if not Result then
    Exit;
  R.DS := TFIBCustomDataSet(Field.DataSet);
  R.SaveField := R.DS.vRawDecimalField;
  R.SaveReturned := R.DS.vRawDecimalReturned;
  R.DS.vRawDecimalField := Field;
  R.DS.vRawDecimalReturned := false;
end;

// True if GetFieldData met a value which TBcd can not hold, returned in Value
function EndDecFloatRead(var R: TDecFloatRead; out Value: TFBDecimal): Boolean;
begin
  Result := R.DS.vRawDecimalReturned;
  R.DS.vRawDecimalField := R.SaveField;
  R.DS.vRawDecimalReturned := R.SaveReturned;
  if Result then
    Value := CacheToDecimal(R.fi, @R.DS.vRawDecimalData);
end;

// Reads the value of a DECFLOAT field once, as TBcd or as a special value
function ReadDecFloat(Field: TField; out Bcd: TBcd; out Special: TFBDecimal): TDecFloatReadResult;
var
  R: TDecFloatRead;
  HasData: Boolean;
begin
  Result := drNotDecFloat;
  if not BeginDecFloatRead(Field, R) then
    Exit;
  try
    // a value being validated is returned as TBcd
    HasData := R.DS.GetFieldData(Field, Pointer(@Bcd));
  finally
    if EndDecFloatRead(R, Special) then
      Result := drSpecial;
  end;
  if Result <> drSpecial then
    if HasData then
      Result := drBcd
    else
      Result := drNull;
end;

// The results of the inherited methods, without a second read of the value

function TFIBFMTBCDField.GetAsFloat: Double;
var
  vBcd: TBcd;
  vDecimal: TFBDecimal;
begin
  case ReadDecFloat(Self, vBcd, vDecimal) of
    drBcd: Result := BcdToDouble(vBcd);
    drSpecial: Result := FBDecimalToDouble(vDecimal);
    drNull: Result := 0;
    else
      Result := inherited GetAsFloat;
  end;
end;

function TFIBFMTBCDField.GetAsString: string;
var
  vBcd: TBcd;
  vDecimal: TFBDecimal;
begin
  case ReadDecFloat(Self, vBcd, vDecimal) of
    drBcd: Result := BcdToStr(vBcd);
    drSpecial: Result := FBDecimalToStr(vDecimal, LocalDecimalSeparator);
    drNull: Result := '';
    else
      Result := inherited GetAsString;
  end;
end;

function TFIBFMTBCDField.GetAsVariant: Variant;
var
  vBcd: TBcd;
  vDecimal: TFBDecimal;
begin
  // like TFIBXSQLVAR.AsVariant and TFIBCustomDataSet.RecordFieldValue
  case ReadDecFloat(Self, vBcd, vDecimal) of
    drBcd: VarFMTBcdCreate(Result, vBcd);
    drSpecial: Result := FBDecimalToDouble(vDecimal);
    drNull: Result := Null;
    else
      Result := inherited GetAsVariant;
  end;
end;

procedure TFIBFMTBCDField.GetText(var Text: string; DisplayText: Boolean);
var
  R: TDecFloatRead;
  vDecimal: TFBDecimal;
  Special: Boolean;
begin
  if not BeginDecFloatRead(Self, R) then
    begin
      inherited GetText(Text, DisplayText);
      Exit;
    end;
  // the formatting of the inherited method, a special value is read as no data
  try
    inherited GetText(Text, DisplayText);
  finally
    Special := EndDecFloatRead(R, vDecimal);
  end;
  if Special then
    Text := FBDecimalToStr(vDecimal, LocalDecimalSeparator);
end;

procedure TFIBFMTBCDField.SetAsFloat(Value: Double);
var
  vBcd: TBcd;
begin
  // DECFLOAT has a floating scale, so the value is not rounded to Size.
  // Like TFIBXSQLVAR.AsDouble, the shortest decimal representation keeps
  // all digits of the Double (DoubleToBcd keeps 15 digits only).
  if DecFloatFieldDescr(Self) <> nil then
    begin
      // NaN, Infinity and values out of TBcd range
      if not FBDecimalToBcd(DoubleToFBDecimal(Value), vBcd) then
        FIBError(feInvalidDataConversion, [nil]);
      SetAsBCD(vBcd);
    end
  else
    inherited SetAsFloat(Value);
end;

(*
  * TFIBIntegerField - implementation
*)

constructor TFIBIntegerField.Create(AOwner: TComponent); // override;
begin
  inherited Create(AOwner);
end;

function TFIBIntegerField.GetAsBoolean: Boolean;
begin
  Result := AsInteger > 0
end;

procedure TFIBIntegerField.SetAsBoolean(Value: Boolean);
begin
  if Value then
    AsInteger := 1
  else
    AsInteger := 0
end;

procedure TFIBIntegerField.Clear;
begin
  SetData(nil);
end;

(*
  * TFIBDateField - implementation
*)

{$IFDEF D_XE3}

procedure TFIBDateField.SetAsDateTime(Value: TDateTime);
begin
{$IFDEF WIN64}
  inherited SetAsDateTime(Value)
{$ELSE}
  SetData(@Value, false);
{$ENDIF}
end;

{$ENDIF}
(*
  * TFIBTimeField - implementation
*)
{$IFDEF D_XE3}

procedure TFIBTimeField.SetAsDateTime(Value: TDateTime);
begin
{$IFDEF WIN64}
  inherited SetAsDateTime(Value)
{$ELSE}
  SetData(@Value, false);
{$ENDIF}
end;
{$ENDIF}

procedure TFIBTimeField.GetText(var Text: string; DisplayText: Boolean);
var
  Data: Integer;
begin
  inherited GetText(Text, DisplayText);
  if FShowMsec then
    begin
      if DataSet.GetFieldData(Self, @Data) then
        begin
          Data := Data mod 1000;
          if Data > 0 then
            Text := Text + '.' + IntToStr(Data)
        end
    end;
end;

(*
  * TFIBDateTimeField - implementation
*)

{$IFDEF D_XE3}

procedure TFIBDateTimeField.SetAsDateTime(Value: TDateTime);
begin
  inherited SetAsDateTime(Value)
  // SetData(@Value, False);
end;
{$ENDIF}

procedure TFIBDateTimeField.GetText(var Text: string; DisplayText: Boolean);
var
  Data: Double;
  ts: TTimeStamp;

begin
  inherited GetText(Text, DisplayText);
  if FShowMsec then
    begin
      if DataSet.GetFieldData(Self, @Data) then
        begin
          ts := MSecsToTimeStamp(Data);
          ts.Time := ts.Time mod 1000;
          if ts.Time > 0 then
            Text := Text + '.' + IntToStr(ts.Time)
        end
    end;
end;

function TFIBDateTimeField.GetAsTimeStamp: TTimeStamp;
var
  Data: Double;
begin
  if DataSet.GetFieldData(Self, @Data) then
    Result := MSecsToTimeStamp(Data)
  else
    begin
      Result.Time := 0;
      Result.Date := 0;
    end;
end;

procedure TFIBDateTimeField.SetAsTimeStamp(const Value: TTimeStamp);
var
  Data: Double;
begin
  Data := TimeStampToMSecs(Value);
  SetData(@Data)
end;

(*
  * TFIBBlobField - implementation
*)

function TFIBBlobField.GetAsVariant: Variant;
begin
  if IsNull then
    Result := Null
  else
    Result := inherited GetAsVariant;
end;

function TFIBBlobField.GetBlobInfo: TBlobInfo;
var
  DB: TFIBDatabase;
  TR: TFIBTransaction;
  ForceTR: Boolean;
  BlobID: TISC_QUAD;
  Success: Boolean;
  fs: TStream;
begin
  if IsNull then
    begin
      FillChar(Result, SizeOf(Result), 0);
      Exit;
    end;
  Include(TFIBDataSet(DataSet).FRunState, drsGetBlobStream);
  try
    fs := TFIBDataSet(DataSet).CreateBlobStream(Self, bmRead)
  finally
    Exclude(TFIBDataSet(DataSet).FRunState, drsGetBlobStream);
  end;

  if fs = nil then
    begin
      DB := TFIBDataSet(DataSet).Database;
      TR := TFIBDataSet(DataSet).UpdateTransaction;
      if not TR.Active then
        TR := TFIBDataSet(DataSet).Transaction;
      if not TR.Active then
        begin
          ForceTR := True;
          TR := TFIBTransaction.Create(Self);
          TR.DefaultDatabase := DB;
          TR.StartTransaction
        end
      else
        ForceTR := false;
      BlobID := GetBlobId;
      Result := GetBlobInfoRec(DB, TR, BlobID, Success);
      if ForceTR then
        TR.Free;
    end
  else
    begin
      Result.NumSegments := TFIBBlobStream(fs).BlobNumSegments;
      Result.BlobType := TFIBBlobStream(fs).BlobType;
      Result.MaxSegmentSize := TFIBBlobStream(fs).BlobMaxSegmentSize;
      Result.TotalSize := TFIBBlobStream(fs).BlobSize;
    end
end;

function TFIBBlobField.GetBlobId: TISC_QUAD;
var
  ValueBuffer: PAnsiChar;
begin
  GetMem(ValueBuffer, SizeOf(TISC_QUAD));
  try
    GetData(ValueBuffer);
    Result := PISC_QUAD(ValueBuffer)^;
  finally
    FreeMem(ValueBuffer)
  end;
end;

function TFIBBlobField.GetIsNull: Boolean;
begin
  if FIsClientCalcField then
    Result := BlobSize = 0
  else
    Result := inherited GetIsNull;
end;

{$IFDEF D_XE3}

procedure TFIBMemoField.SetAsAnsiString(const Value: AnsiString);
begin
{$IFDEF D_25}
  SetData(TValueBuffer(Value), Length(Value));
{$ELSE}
  SetData(Pointer(Value), Length(Value));
{$ENDIF}
end;
{$ENDIF}

function TFIBMemoField.BlobCodePage: Word;
begin
  if DataSet is TFIBCustomDataSet then
    Result := TFIBCustomDataSet(DataSet).BlobFieldCodePage(Self)
  else
    Result := FIBCodePageSystem;
  // psSupportUnicodeBlobs, for servers that send the column bytes
  if (Result = FIBCodePageSystem) and (FCharSetID > 0) and (FCharSetID < 256) and (DataSet is TFIBDataSet) and
    Assigned(TFIBDataSet(DataSet).Database) and (FCharSetID in TFIBDataSet(DataSet).Database.UnicodeCharSets) then
    Result := FIBCodePageUTF8;
end;

function TFIBMemoField.GetAsString: string;
begin
{$IFDEF D2009+}
  Result := DecodeString(inherited GetAsAnsiString, BlobCodePage);
{$ELSE}
  Result := DecodeString(inherited GetAsString, BlobCodePage);
{$ENDIF}
end;

function TFIBMemoField.GetAsVariant: Variant;
begin
  if IsNull then
    Result := Null
  else if BlobCodePage <> FIBCodePageSystem then
    Result := GetAsWideString
  else
    Result := inherited GetAsVariant;
end;

procedure TFIBMemoField.SetAsVariant(const Value: Variant);
begin
  if BlobCodePage <> FIBCodePageSystem then
  begin
    if VarIsNull(Value) then
      Clear
    else
      SetAsWideString(Value)
  end
  else
    inherited SetAsVariant(Value)
end;

procedure TFIBMemoField.SetAsString(const Value: string);
var
  CodePage: Word;
begin
  CodePage := BlobCodePage;
  if CodePage <> FIBCodePageSystem then
{$IFDEF D2009+}
    SetAsAnsiString(EncodeString(Value, CodePage))
{$ELSE}
    inherited SetAsString(EncodeString(Value, CodePage))
{$ENDIF}
  else
    inherited SetAsString(Value)
end;

function TFIBMemoField.GetBlobId: TISC_QUAD;
var
  ValueBuffer: PAnsiChar;
begin
  GetMem(ValueBuffer, SizeOf(TISC_QUAD));
  try
    GetData(ValueBuffer);
    Result := PISC_QUAD(ValueBuffer)^;
  finally
    FreeMem(ValueBuffer)
  end;
end;

procedure TFIBMemoField.InternalSetCharSet(aValue: Integer); // Internal use
begin
  FCharSetID := aValue
end;

function TFIBMemoField.GetBlobInfo: TBlobInfo;
var
  DB: TFIBDatabase;
  TR: TFIBTransaction;
  ForceTR: Boolean;
  BlobID: TISC_QUAD;
  Success: Boolean;
  fs: TStream;
begin
  if IsNull then
    begin
      FillChar(Result, SizeOf(Result), 0);
      Exit;
    end;
  Include(TFIBDataSet(DataSet).FRunState, drsGetBlobStream);
  try
    fs := TFIBDataSet(DataSet).CreateBlobStream(Self, bmRead)
  finally
    Exclude(TFIBDataSet(DataSet).FRunState, drsGetBlobStream);
  end;

  if fs = nil then
    begin
      DB := TFIBDataSet(DataSet).Database;
      TR := TFIBDataSet(DataSet).UpdateTransaction;
      if not TR.Active then
        TR := TFIBDataSet(DataSet).Transaction;
      if not TR.Active then
        begin
          ForceTR := True;
          TR := TFIBTransaction.Create(Self);
          TR.DefaultDatabase := DB;
          TR.StartTransaction
        end
      else
        ForceTR := false;
      BlobID := GetBlobId;
      Result := GetBlobInfoRec(DB, TR, BlobID, Success);
      if ForceTR then
        TR.Free;
    end
  else
    begin
      Result.NumSegments := TFIBBlobStream(fs).BlobNumSegments;
      Result.BlobType := TFIBBlobStream(fs).BlobType;
      Result.MaxSegmentSize := TFIBBlobStream(fs).BlobMaxSegmentSize;
      Result.TotalSize := TFIBBlobStream(fs).BlobSize;
    end
end;
{$IFDEF D2009+}

function TFIBMemoField.GetAsAnsiString: AnsiString;
begin
  Result := inherited GetAsAnsiString;
  SetStringCodePage(RawByteString(Result), BlobCodePage);
end;
{$ENDIF}

function TFIBMemoField.GetAsWideString: {$IFDEF D2009+}UnicodeString; {$ELSE} WideString; {$ENDIF}
begin
{$IFDEF D2009+}
  Result := DecodeString(inherited GetAsAnsiString, BlobCodePage);
{$ELSE}
  Result := DecodeWideString(inherited GetAsString, BlobCodePage);
{$ENDIF}
end;

procedure TFIBMemoField.SetAsWideString(const aValue:
  {$IFDEF D2009+}UnicodeString{$ELSE} WideString{$ENDIF});
begin
{$IFDEF D2009+}
  SetAsString(aValue);
{$ELSE}
  if BlobCodePage = FIBCodePageUTF8 then
    inherited SetAsString(UTF8Encode(aValue))
  else
    inherited SetAsString(aValue)
{$ENDIF}
end;

function TFIBMemoField.GetWideDisplayText: WideString;
begin
  Result := GetAsWideString
end;

function TFIBMemoField.GetWideEditText: WideString;
begin
  Result := GetAsWideString
end;

procedure TFIBMemoField.SetWideEditText(const Value: WideString);
begin
  SetAsWideString(Value)
end;

(*
  * TFIBSmallIntField - implementation
*)

function TFIBSmallIntField.GetAsBoolean: Boolean;
begin
  Result := AsInteger > 0
end;

procedure TFIBSmallIntField.SetAsBoolean(Value: Boolean);
begin
  if Value then
    AsInteger := 1
  else
    AsInteger := 0
end;

constructor TFIBFloatField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRoundByScale := True;
end;

function TFIBFloatField.GetScale: Integer;
begin
  if (FieldKind = fkData) then
    Result := TFIBCustomDataSet(DataSet).GetFieldScale(Self)
  else
    Result := -15;
end;

procedure TFIBFloatField.GetText(var Text: string; DisplayText: Boolean);
begin
  inherited GetText(Text, DisplayText);
  Text := Trim(Text)
end;

const
  MAXSHORT = 32767;
{$EXTERNALSYM MAXSHORT}

procedure TFIBFloatField.SetAsFloat(Value: Double);
var
  fi: PFIBFieldDescr;
begin
  if (FieldKind = fkData) then
    begin
      fi := TFIBDataSet(DataSet).vFieldDescrList[FieldNo - 1];
      if Assigned(fi) then
        case fi^.fdDataType of
          SQL_SHORT:
            if (Value > MAXSHORT * E10[fi^.fdDataScale]) or (Value < -MAXSHORT * E10[fi^.fdDataScale]) then
              RangeError(Value, -MAXSHORT * E10[fi^.fdDataScale], MAXSHORT * E10[fi^.fdDataScale]);

          SQL_LONG:
            if (Value > MaxInt * E10[fi^.fdDataScale]) or (Value < -MaxInt * E10[fi^.fdDataScale]) then
              RangeError(Value, -MaxInt * E10[fi^.fdDataScale], MaxInt * E10[fi^.fdDataScale]);
        end;
    end;
  if FRoundByScale and (Scale <> 0) then
    inherited SetAsFloat(RoundExtend(Value, -Scale))
  else
    inherited SetAsFloat(Value)
end;

{ TFIBBooleanField }

constructor TFIBBooleanField.Create(AOwner: TComponent);
begin
  inherited;
  FStringTrue := TrueStr;
  FStringFalse := FalseStr;
end;

function TFIBBooleanField.GetAsInteger: LongInt;
begin
  if Value then
    Result := 1
  else
    Result := 0
end;

function TFIBBooleanField.GetDataSize: Integer;
var
  D: TFIBDataSet;
  fi: PFIBFieldDescr;
begin
  if (FieldKind <> fkData) or not(DataSet is TFIBDataSet) then
    begin
      Result := inherited GetDataSize; // SizeOf( WordBool )
      Exit;
    end;
  D := TFIBDataSet(DataSet);
  if D.vFieldDescrList.Capacity = 0 then
    begin
      Result := inherited GetDataSize; // SizeOf( WordBool )
      Exit;
    end;
  fi := D.vFieldDescrList[FieldNo - 1];
  Result := fi.fdDataSize;
end;

function TFIBBooleanField.StoreStrFalse: Boolean;
begin
  Result := FStringFalse <> 'False';
end;

function TFIBBooleanField.StoreStrTrue: Boolean;
begin
  Result := FStringTrue <> 'True';
end;

function TFIBBooleanField.GetAsString: string;
var
  B: LongBool;
begin
  B := false; // clear
  if GetData(@B) then
    if B then
      Result := FStringTrue
    else
      Result := FStringFalse
  else
    Result := '';
end;

procedure TFIBBooleanField.SetAsInteger(Value: LongInt); // override;
begin
  SetAsBoolean(Value <> 0)
end;

procedure TFIBBooleanField.SetAsString(const Value: string);
var
  StrValue: string;
begin
  if (Value = '1') or (Value = 'T') or (AnsiCompareText(Value, FStringTrue) = 0) then
    SetAsBoolean(True)
  else if (Value = '0') or (Value = 'F') or (AnsiCompareText(Value, FStringFalse) = 0) then
    SetAsBoolean(false)
  else
    begin
      StrValue := Value;
      inherited SetAsString(StrValue);
    end;
end;

procedure TFIBBooleanField.SetVarValue(const Value: Variant);
begin
  if VarType(Value) = vtString then
    SetAsString(Value)
  else
    inherited;
end;

function TFIBBooleanField.GetAsBoolean: Boolean;
var
  B: LongBool;
begin
  B := false; // clear
  if GetData(@B) then
    Result := B
  else
    Result := false;
end;

function TFIBBooleanField.GetAsVariant: Variant;
var
  B: LongBool;
begin
  B := false; // clear
  if GetData(@B) then
    Result := B
  else
    Result := Null;
end;

procedure TFIBBooleanField.SetAsBoolean(Value: Boolean);
var
  B: LongBool;
begin
  if Value then
    Long(B) := 1
  else
    Long(B) := 0;
  SetData(@B);
end;

// Array support
{$IFDEF SUPPORT_ARRAY_FIELD}

constructor TFIBArrayField.Create(AOwner: TComponent); // override;
begin
  inherited Create(AOwner);
  FStreamIndex := -1;
end;

procedure TFIBArrayField.GetText(var Text: string; DisplayText: Boolean);
begin
  if IsNull then
    Text := '(Array)'
  else
    Text := '(ARRAY)'
end;

function TFIBArrayField.GetFIBXSQLVAR: TFIBXSQLVAR;
begin
  if DataSet = nil then
    Result := nil
  else
    with TFIBDataSet(DataSet).QSelect, TFIBDataSet(DataSet) do
      begin
        if not Prepared then
          Prepare;
        Result := QSelect[Self.FieldName]
      end;
end;

function TFIBArrayField.GetDimCount: Integer;
begin
  if GetFIBXSQLVAR = nil then
    Result := 0
  else
    Result := GetFIBXSQLVAR.DimensionCount
end;

function TFIBArrayField.GetElementType: TFieldType;
begin
  if GetFIBXSQLVAR = nil then
    Result := ftUnknown
  else
    Result := GetFIBXSQLVAR.ElementType
end;

function TFIBArrayField.GetDimension(Index: Integer): TISC_ARRAY_BOUND;
begin
  if GetFIBXSQLVAR = nil then
    FIBError(feInvalidColumnIndex, [nil])
  else
    Result := GetFIBXSQLVAR.Dimension[Index]
end;

function TFIBArrayField.GetArraySize: Integer;
begin
  if GetFIBXSQLVAR = nil then
    Result := 0
  else
    Result := GetFIBXSQLVAR.ArraySize
end;

function TFIBArrayField.GetArrayId: TISC_QUAD;
var
  ValueBuffer: PAnsiChar;
begin
  GetMem(ValueBuffer, SizeOf(TISC_QUAD));
  try
    GetData(ValueBuffer);
    Result := PISC_QUAD(ValueBuffer)^;
  finally
    FreeMem(ValueBuffer)
  end;
end;

function TFIBArrayField.GetAsVariant: Variant;
begin
  Result := 0;
  if DataSet <> nil then
    Result := TFIBDataSet(DataSet).ArrayFieldValue(Self)
end;

procedure TFIBArrayField.SetAsVariant(const Value: Variant); // override;
begin
  if DataSet <> nil then
    TFIBDataSet(DataSet).SetArrayValue(Self, Value)
end;

{$ENDIF}
{ TFIBBCDField }

constructor TFIBBCDField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetDataType(ftBCD);
  Size := 8;
end;

procedure TFIBBCDField.AddExtended(const Value: Extended);
var
  oBCD: TBcd;
begin
  oBCD := ExtendedToBCD(Value, Size);
  BcdAdd(AsBcd, oBCD, oBCD);
  AsBcd := oBCD
end;

procedure TFIBBCDField.SubtractExtended(const Value: Extended);
var
  oBCD: TBcd;
begin
  oBCD := ExtendedToBCD(Value, Size);
  BcdSubtract(AsBcd, oBCD, oBCD);
  AsBcd := oBCD
end;

procedure TFIBBCDField.MultiplyExtended(const Value: Extended);
var
  oBCD: TBcd;
begin
  oBCD := ExtendedToBCD(Value, Size);
  BcdMultiply(AsBcd, oBCD, oBCD);
  AsBcd := oBCD
end;

procedure TFIBBCDField.DivideExtended(const Value: Extended);
var
  oBCD: TBcd;
begin
  oBCD := ExtendedToBCD(Value, Size);
  BcdDivide(AsBcd, oBCD, oBCD);
  AsBcd := oBCD
end;

procedure TFIBBCDField.AddBCD(const Value: TBcd);
var
  oBCD: TBcd;
begin
  BcdAdd(AsBcd, Value, oBCD);
  AsBcd := oBCD
end;

procedure TFIBBCDField.SubtractBCD(const Value: TBcd);
var
  oBCD: TBcd;
begin
  BcdSubtract(AsBcd, Value, oBCD);
  AsBcd := oBCD
end;

procedure TFIBBCDField.MultiplyBCD(const Value: TBcd);
var
  oBCD: TBcd;
begin
  BcdMultiply(AsBcd, Value, oBCD);
  AsBcd := oBCD
end;

procedure TFIBBCDField.DivideBCD(const Value: TBcd);
var
  oBCD: TBcd;
begin
  BcdDivide(AsBcd, Value, oBCD);
  AsBcd := oBCD
end;

procedure TFIBBCDField.LoadRoundByScale(Reader: TReader);
begin
  Reader.ReadBoolean
end;

procedure TFIBBCDField.DefineProperties(Filer: TFiler);
begin
  inherited;
  Filer.DefineProperty('RoundByScale', LoadRoundByScale, nil, false);
end;

class procedure TFIBBCDField.CheckTypeSize(Value: Integer);
begin
  { No need to check as the base type is currency, not BCD }
end;

procedure TFIBBCDField.SetDataSet(ADataSet: TDataSet);
begin
  FDataSet := ADataSet;
  inherited SetDataSet(ADataSet);
end;

function TFIBBCDField.GetAsCurrency: Currency;
begin
  if (FieldKind = fkCalculated) { or (Scale=-4) } then
    Result := inherited GetAsCurrency
  else if not GetValue(Result) then
    Result := 0;
end;

function TFIBBCDField.GetAsString: string;
var
  C: Int64;
  Success: Boolean;
begin
  if FieldKind = fkCalculated then
    Result := inherited GetAsString
  else
    begin
      Success := GetData(@C);
      if Success then
        if Size = 0 then
          Result := IntToStr(C)
        else
          Result := BcdToStr(GetAsBCD)
      else
        Result := '';
    end;
end;

function TFIBBCDField.GetAsVariant: Variant;
begin
  if FieldKind = fkCalculated then
    Result := inherited GetAsVariant
  else if IsNull then
    Result := Null
  else
    begin
      if Size = 0 then
        Result := AsInt64
      else if Size <= 4 then
        Result := AsCurrency
      else
        begin
          VarFMTBcdCreate(Result, AsBcd);
    {$IFDEF D_XE}
    {$IFNDEF D_XE2}
          Result := Result + 0; // Avoid bug BCD in XE
    {$ENDIF}
    {$ENDIF}
        end;
    end;
end;

function TFIBBCDField.GetDataSize: Integer;
var
  lTF: TField;
begin
  case FieldKind of
    fkCalculated: Result := inherited GetDataSize;
    fkLookup:
      if Assigned(LookupDataSet) then
        begin
          lTF := LookupDataSet.FindField(LookupResultField);
          if Assigned(lTF) then
            Result := lTF.DataSize
          else
            Result := SizeOf(Int64);
        end
      else
        Result := SizeOf(Int64);
    else
      Result := 8;
      {
      if (ServerType=SQL_DOUBLE) then
      Result := 8
      else
      Result := SizeOf(Int64);
    }
  end
end;

function TFIBBCDField.ServerType: Integer;
var
  fi: PFIBFieldDescr;
begin

  if (FieldKind <> fkData) or not(DataSet is TFIBDataSet) then
    Result := -1
  else
    begin
      fi := TFIBDataSet(DataSet).vFieldDescrList[FieldNo - 1];
      Result := fi.fdDataType;
    end;
end;

procedure TFIBBCDField.GetText(var Text: string; DisplayText: Boolean);
var
  FmtStr: string;
  Digits: Integer;
  TC: Int64;
  Format: TFloatFormat;
  bcdValue: TBcd;
begin
  if FieldKind in [fkCalculated] then
    inherited GetText(Text, DisplayText)
  else
    begin
      if not GetData(@TC) then
        Text := ''
      else
        begin
          if DisplayText or (EditFormat = '') then
            FmtStr := DisplayFormat
          else
            FmtStr := EditFormat;
          if Size = 0 then
            begin
              if FmtStr = '' then
                begin
                  Text := IntToStr(TC)
                end
              else
                begin
                  Int64ToBCD(TC, Size, bcdValue);
                  Text := FormatBcd(FmtStr, bcdValue)
                end;
            end
          else
    {$IFDEF D_XE3}with FormatSettings do {$ENDIF}
              begin
                if FmtStr = '' then
                  begin
                    if Currency then
                      begin
                        Digits := CurrencyDecimals;
                        if DisplayText then
                          Format := ffCurrency
                        else
                          Format := ffFixed;
                        Text := CurrToStrF(TC * E10[-Size], Format, Digits);
                      end
                    else
                      begin
                        Digits := Size;
                        Text := Int64WithScaleToStr(TC, Digits, DecimalSeparator)
                      end;
                  end
                else if Size = 4 then
                  Text := FormatCurr(FmtStr, TC * E10[-Size])
                else
                  begin
                    Text := FormatNumericString(FmtStr, Int64WithScaleToStr(TC, Size, DecimalSeparator));
                  end;
              end;
        end;
    end;
end;

function TFIBBCDField.GetValue(var Value: Currency): Boolean;
var
  C: Int64;
begin
  if FieldKind = fkCalculated then
    Result := inherited GetValue(Value)
  else if Size = 4 then
    Result := GetData(@Value)
  else
    begin
      C := 0;
      if Size = 0 then // patchInt64B start
        begin
          Result := GetData(@C);
          Value := C;
        end
      else
        begin // patchInt64B end
          Result := GetData(@C);
          if Result then
            begin
              if Size < 4 then
                begin
                  Value := E10[-Size];
                  Value := C * Value;
                end
              else
                Value := C * E10[-Size];
            end
        end
    end;
end;

procedure TFIBBCDField.SetAsString(const Value: string); // override;
begin
  if FieldKind = fkCalculated then
    inherited SetAsString(Value)
  else
    begin
      if Value = '' then
        Clear
      else if (ServerType = SQL_INT64) then
        begin
          if (Size = 0) then
            SetAsInt64(StrToInt64(Value))
          else
            SetAsBCD(StrToBCD(Trim(Value)));
        end
      else
        inherited SetAsString(Value)
    end;
end;

procedure TFIBBCDField.SetAsCurrency(Value: Currency);
var
  C: Comp;
begin
  if FieldKind = fkCalculated then
    inherited SetAsCurrency(Value)
  else
    try
      if Size = 0 then
        begin
          C := Value;
  {$IFDEF D_XE3}
          TFIBDataSet(DataSet).SetFieldData(Self, @C);
  {$ELSE}
          SetData(@C);
  {$ENDIF}
        end
      else
        begin
          if (MinValue <> 0) or (MaxValue <> 0) then
            begin
              Value := RoundExtend(Value, Size);
              if (Value < MinValue) or (Value > MaxValue) then
                RangeError(Value, MinValue, MaxValue);
            end;
          C := Value * E10[Size];
  {$IFDEF D_XE3}
          TFIBDataSet(DataSet).SetFieldData(Self, @C);
  {$ELSE}
          SetData(@C);
  {$ENDIF}
        end;
    except
      on E: Exception do
        if Assigned(OnValidate) then
          raise
        else if Self.Name = '' then
          raise Exception.Create(CmpFullName(Self) + '.' + FieldName + CLRF + E.Message)
        else
          raise Exception.Create(CmpFullName(Self) + CLRF + E.Message)
    end
end;

function TFIBBCDField.GetAsExtended: Extended;
var
  C: Int64;
  Success: Boolean;
begin
  Success := GetData(@C);
  if not Success then
    Result := 0
  else
    Result := C * E10[-Size]
end;

{$IFNDEF NO_USE_COMP}

function TFIBBCDField.GetAsComp: Comp;
begin
  if Size = 0 then
    begin
      if not GetData(@Result) then
        Result := 0;
    end
  else
    Result := GetAsExtended;
end;

procedure TFIBBCDField.SetAsComp(Value: Comp);
begin
  if FieldKind = fkCalculated then
    inherited SetVarValue(Value)
  else if Size = 0 then
    SetData(@Value)
  else
    AsExtended := Value;
end;
{$ENDIF}

function TFIBBCDField.GetAsBCD: TBcd;
var
  C: Int64;
begin
  if FieldKind = fkCalculated then
    Result := inherited GetAsBCD
  else
    begin
      if not GetData(@C) then
        C := 0;
      Int64ToBCD(C, Size, Result)
    end;
end;

procedure TFIBBCDField.SetAsBCD(const Value: TBcd);
var
  C: Int64;
  lScale: Byte;
begin
  if FieldKind = fkCalculated then
    inherited SetAsBCD(Value)
  else
    begin
      BCDToInt64WithScale(Value, C, lScale);
      if lScale <> Size then
        C := Round(C * E10[Size - lScale]);
  {$IFDEF D_XE3}
      TFIBDataSet(DataSet).SetFieldData(Self, @C);
  {$ELSE}
      SetData(@C);
  {$ENDIF}
    end
end;

procedure TFIBBCDField.SetVarValue(const Value: Variant);
var
  C: Comp;
begin
  if VarIsNull(Value) then
    Clear
  else
    try
      if FieldKind = fkCalculated then
        inherited SetVarValue(Value)

      else
        case VarType(Value) of
          varInt64: SetAsInt64(Value);
          else
            if VarIsFMTBcd(Value) then
              AsBcd := VarToBcd(Value)
            else
              begin
                C := Value * E10[Size];
    {$IFDEF D_XE3}
                TFIBDataSet(DataSet).SetFieldData(Self, @C);
    {$ELSE}
                SetData(@C);
    {$ENDIF}
              end
        end;
    except
      on EVariantError do
        DatabaseErrorFmt(SFieldValueError, [DisplayName]);
    end
end;

function TFIBBCDField.FieldModified: Boolean;
var
  OldIsNull: Boolean;
  vIsNull: Boolean;
begin
  Result := (GetInternalData(vIsNull) <> GetInternalOldData(OldIsNull)) or (vIsNull xor OldIsNull);
end;

function TFIBBCDField.GetInternalData(var ValueIsNull: Boolean): Int64;
begin
  ValueIsNull := not GetData(@Result);
  if ValueIsNull then
    Result := 0;
end;

function TFIBBCDField.GetInternalOldData(var OldIsNull: Boolean): Int64;
var
  SaveState: TDataSetState;
begin
  if FieldKind in [fkData, fkInternalCalc] then
    begin
      SaveState := DataSet.State;
      TFIBCustomDataSet(DataSet).SetTempState(dsOldValue);
      try
        Result := GetInternalData(OldIsNull);
      finally
        TFIBCustomDataSet(DataSet).RestoreState(SaveState);
      end;
    end
  else
    Result := 0;
end;

function TFIBBCDField.GetAsInt64: Int64;
begin
  if not GetData(@Result) then
    Result := 0
  else if Size > 0 then
    Result := Result div IE10[Size];
end;

procedure TFIBBCDField.SetAsInt64(const Value: Int64);
begin
  if FieldKind = fkCalculated then
    inherited SetVarValue(Value)
  else if Size = 0 then
    SetData(@Value)
  else
    AsExtended := Value;
end;

procedure TFIBBCDField.SetAsExtended(Value: Extended);
var
  RndComp: Comp;
begin
  try
    RndComp := Value * E10[Size];
  except
    on E: Exception do
      begin
        if Self.Name = '' then
          raise Exception.Create(CmpFullName(Self) + '.' + FieldName + CLRF + E.Message)
        else
          raise Exception.Create(CmpFullName(Self) + CLRF + E.Message)
      end;
  end;
{$IFDEF D_XE3}
  TFIBDataSet(DataSet).SetFieldData(Self, @RndComp);
{$ELSE}
  SetData(@RndComp);
{$ENDIF}
end;

function TFIBBCDField.GetData(Buffer: Pointer): Boolean;
begin
  if FieldKind = fkCalculated then
    Result := inherited GetData(Buffer)
  else
    try
      FDataAsComp := True;
      Result := inherited GetData(Buffer);
    finally
      FDataAsComp := false
    end;
end;

procedure TFIBBCDField.Assign(Source: TPersistent);
begin
  if FieldKind = fkCalculated then
    inherited Assign(Source)
  else if Source is TBCDField then
    begin
      AsString := BCDFieldAsString(TBCDField(Source), false)
    end
  else
    inherited Assign(Source);
end;

(*
  * TFIBDataLink - implementation
*)
constructor TFIBDataLink.Create(ADataSet: TFIBCustomDataSet);
begin
  inherited Create;
  FDataSet := ADataSet;
end;

destructor TFIBDataLink.Destroy;
begin
  FDataSet.FSourceLink := nil;
  inherited;
end;

procedure TFIBDataLink.DataSetChanged;
begin
  inherited DataSetChanged;
end;

function TFIBDataLink.GetDetailDataSet: TDataSet;
begin
  Result := FDataSet;
end;

procedure TFIBDataLink.ActiveChanged;
begin
  if Active then
    begin
      FDataSet.SourceChanged;
    end
  else if not Active then
    begin
      FDataSet.SourceDisabled;
    end;
end;

// Master posted from the detail Post (e.g. BeforePost)
function TFIBDataLink.DetailPosting: Boolean;
begin
  Result := (drsInPost in FDataSet.FRunState) and (FDataSet.State in dsEditModes);
end;

procedure TFIBDataLink.CheckBrowseMode;
begin
  if FDataSet.Active and not DetailPosting then
    FDataSet.CheckBrowseMode;
end;

// The posted record belongs to the new master key, a reopen would drop cached updates
procedure TFIBDataLink.ApplyMasterChangedInPost;
begin
  if FMasterChangedInPost then
    begin
      FMasterChangedInPost := false;
      FDataSet.SetParamsFromMaster;
    end;
end;

procedure TFIBDataLink.RecordChanged(Field: TField);
begin
  if (Field = nil) and (FDataSet.Active) then
    begin
      if DetailPosting then
        begin
          FMasterChangedInPost := True;
          Exit;
        end;
      if (not FDataSet.MasterFieldsChanged) then
        Exit;
      FDataSet.SourceChanged;
    end;
end;

(*
  * TFIBCustomDataSet - implementation
*)

function TFIBCustomDataSet.CreateInternalQuery(const QName: string): TFIBQuery;
begin
  Result := TFIBQuery.Create(Self);
{$IFDEF CSMonitor}
  Result.CSMonitorSupport.Enabled := FCSMonitorSupport.Enabled;
  Result.CSMonitorSupport.IncludeDatasetDescription := FCSMonitorSupport.IncludeDatasetDescription;
{$ENDIF}
  with Result do
    begin

      OnSQLChanging := SQLChanging;
      GoToFirstRecordOnExecute := false;
      ParamCheck := True;
      Options := [];
      Name := QName;
    end;
end;

constructor TFIBCustomDataSet.Create(AOwner: TComponent);
begin
  inherited;
  FBase := TFIBBase.Create(Self);
  FCurrentRecord := -1;
{$IFDEF CSMonitor}
  FCSMonitorSupport := TCSMonitorSupport.Create(Self);
{$ENDIF}
  FFieldStreamList := TList.Create;
  FOpenedFieldStreams := TList.Create;
  FSourceLink := TFIBDataLink.Create(Self);
  FQDelete := CreateInternalQuery('DeleteQuery');
  FQInsert := CreateInternalQuery('InsertQuery');
  FQRefresh := CreateInternalQuery('RefreshQuery');
  FQUpdate := CreateInternalQuery('UpdateQuery');
  FQSelect := CreateInternalQuery('SelectQuery');
  FQCurrentSelect := FQSelect;
  // FQSelect.OnSQLFetch    :=DoOnSelectFetch;
  FUpdateRecordTypes := [cusUnmodified, cusModified, cusInserted];
  BookmarkSize := SizeOf(TFIBBookmark);
  FFieldOriginRule := forTableAndFieldName;
  // Events...
  with FBase do
    begin
      OnDatabaseDisconnecting := DoDatabaseDisconnecting;
      OnDatabaseDisconnected := DoDatabaseDisconnected;
      OnDatabaseFree := DoDatabaseFree;
      OnTransactionEnding := DoTransactionEnding;
      OnTransactionEnded := DoTransactionEnded;
      OnTransactionFree := DoTransactionFree;
    end;

  if (csDesigning in ComponentState) and not(CmpInLoadedState(Self)) then
    begin
      FOptions := DefaultOptions;
      FDetailConditions := DefaultDetailConditions;
      FPrepareOptions := DefaultPrepareOptions;
    end
  else
    begin
      FOptions := StatDefDataSetOptions;
      FPrepareOptions := StatDefPrepareOptions;
      // [pfImportDefaultValues,psGetOrderInfo,psUseBooleanField,psSetEmptyStrToNull];
    end;
  FSortFields := Null;
  vIgnoreLocRecno := -1;
  FRelationTables := TStringList.Create;
  with FRelationTables do
    begin
      Sorted := True;
      Duplicates := dupIgnore;
    end;

  if (csDesigning in ComponentState) and not CmpInLoadedState(Self) then
    Database := DefDataBase;
  FWaitEndMasterInterval := 300;
  vControlsEnabled := True;
  vFieldDescrList := TFIBFieldDescrList.Create;
{$IFNDEF NO_GUI}
  FSQLScreenCursor := crDefault;
{$ENDIF}
  FSQLs := TSQLs.Create(Self);

  if AOwner is TFIBDatabase then
    Database := TFIBDatabase(AOwner)
  else if AOwner is TFIBTransaction then
    Transaction := TFIBTransaction(AOwner);
  FAutoUpdateOptions := TAutoUpdateOptions.Create(Self);
  FFNFields := TStringList.Create;
  with FFNFields do
    begin
      Sorted := True;
      Duplicates := dupIgnore;
    end;
  FCacheModelOptions := TCacheModelOptions.Create(Self);
  FAllowedUpdateKinds := [ukModify, ukInsert, ukDelete];

  FFilteredCacheInfo.NonVisibleRecords := TSortedList.Create;
  FFilteredCacheInfo.AllRecords := -1;
  vBeforeCloseEvents := TNotifyEventList.Create(Self);
  vAfterOpenEvents := TNotifyEventList.Create(Self);
  vBeforeOpenEvents := TNotifyEventList.Create(Self);
end;

destructor TFIBCustomDataSet.Destroy;
begin
  inherited Destroy;
{$IFDEF CSMonitor}
  FCSMonitorSupport.Free;
{$ENDIF}
  FSourceLink.Free;
  FBase.Free;
  ClearFieldStreamList;
  FFieldStreamList.Free;
  FOpenedFieldStreams.Free;
  FRelationTables.Free;
  vFieldDescrList.Free;
  FSQLs.Free;
  FreeAndNil(FFilterParser);
  FreeAndNil(FRecordsCache);
  FAutoUpdateOptions.Free;
  FreeAndNil(FFNFields);
  FKeyFieldsForBookMark.Free;
  FCacheModelOptions.Free;
  FreeMem(vPartition);
  FFilteredCacheInfo.NonVisibleRecords.Free;
end;

procedure TFIBCustomDataSet.Loaded;
begin
  if not(drsInClone in FRunState) then
    begin
      if csDesigning in ComponentState then
        Include(FRunState, drsInLoaded);
      try
        inherited
      finally
        Exclude(FRunState, drsInLoaded);
      end
    end;
end;

procedure TFIBCustomDataSet.CreateDetailTimer;
begin
  if not Assigned(vTimerForDetail) then
    begin
      vTimerForDetail := TFIBTimer.Create(Self);
      with vTimerForDetail do
        begin
          Interval := 0;
          Enabled := false;
          OnTimer := OpenByTimer;
        end;
    end;
end;

procedure TFIBCustomDataSet.CreateScrollTimer;
begin
  if not Assigned(vScrollTimer) then
    begin
      vScrollTimer := TFIBTimer.Create(Self);
      with vScrollTimer do
        begin
          Interval := 0;
          Enabled := false;
          OnTimer := DoOnEndScroll;
        end;
    end;
end;

procedure TFIBCustomDataSet.CheckUpdateTransaction;
begin
  if UpdateTransaction = nil then
    FIBError(feTransactionNotAssigned, [CmpFullName(TComponent(Self.Owner))]);
  UpdateTransaction.CheckInTransaction;
end;

function TFIBCustomDataSet.FN(const FieldName: string): TField; // FindField
var
  i: Integer;
  FName: string;
begin
  if FFNFields.Find(FieldName, i) then
    Result := TField(FFNFields.Objects[i])
  else
    begin
      if (Length(FieldName) > 0) and (FieldName[1] = '"') then
        FName := FastCopy(FieldName, 2, Length(FieldName) - 2)
      else
        FName := FieldName;
      Result := FindField(FName);
      if Assigned(Result) then
        FFNFields.AddObject(FieldName, Result)
    end;
end;

function TFIBCustomDataSet.FBN(const FieldName: string): TField; // FieldByName
begin
  Result := FN(FieldName);
  if Result = nil then
    DatabaseErrorFmt(SFieldNotFound, [FieldName], Self);
end;

function TFIBCustomDataSet.GetCacheSize: Integer;
begin
  Result := FRecordsCache.Size
end;

function TFIBCustomDataSet.GetConditions: TConditions;
begin
  Result := QSelect.Conditions
end;

procedure TFIBCustomDataSet.SetConditions(Value: TConditions);
begin
  QSelect.Conditions := Value
end;

procedure TFIBCustomDataSet.ApplyConditions(Reopen: Boolean = false);
begin
  Close;
  QSelect.Conditions.Apply;
  if Reopen then
    Open
end;

procedure TFIBCustomDataSet.CancelConditions;
begin
  Close;
  QSelect.Conditions.CancelApply;
end;

function TFIBCustomDataSet.GetOrderString: string;
begin
  Result := FQSelect.OrderClause
end;

procedure TFIBCustomDataSet.SetOrderString(const OrderTxt: string);
begin
  FQSelect.OrderClause := OrderTxt
end;

function TFIBCustomDataSet.GetFieldsString: string;
begin
  Result := FQSelect.FieldsClause
end;

procedure TFIBCustomDataSet.SetFieldsString(const Value: string);
begin
  FQSelect.FieldsClause := Value
end;

procedure TFIBCustomDataSet.Resync(Mode: TResyncMode);
begin
  if not Active then
    Exit;
  if drsInGotoBookMark in FRunState then
    try
      Exclude(FRunState, drsInGotoBookMark);
      if vLockResync > 0 then
        Dec(vLockResync)
      else
        inherited Resync([])
    finally
      EnableControls;
      EnableScrollEvents;
    end
  else if vLockResync = 0 then
    inherited Resync(Mode)
end;

function TFIBCustomDataSet.BookmarkValid(BookMark: TBookMark): Boolean;
begin
  // Result :=Assigned(Bookmark)
  if Assigned(BookMark) then
    case FCacheModelOptions.FCacheModelKind of
      cmkStandard:
        if BookmarkSize = SizeOf(TFIBBookmark) then
          Result := FRecordsCache.BookmarkValid(PFIBBookMark(BookMark)^.bRecordNumber)
        else
          Result := True;
      else
        Result := True;
    end
  else
    Result := false;
end;

procedure TFIBCustomDataSet.Post;
begin
  Include(FRunState, drsInPost);
  try
    inherited Post;
  finally
    vLockResync := 0;
    Exclude(FRunState, drsInPost);
  end;
  FSourceLink.ApplyMasterChangedInPost;
end;

procedure TFIBCustomDataSet.PrepareAdditionalSelects;
const
  sign: array [Boolean] of Char = ('<', '>');
  sign1: array [Boolean] of Char = ('=', ' ');
var
  i: Integer;
  vInvertedOrder: string;
  vPartWhere: string;
  vPartWhereDesc: string;
  sc: Integer;
  tf: TField;
  FN, fn1: string;
  vLocateWhere: string;
  vSQL: string;
  EquelCondition: string;
  ParName: string;
  ParName1: string;
  useCoalesce: Boolean;
begin
  vPartWhere := '';
  vPartWhereDesc := '';

  sc := SortFieldsCount;
  if sc = 0 then
    FIBErrorEx('%s:Can''t find or parse ORDER BY statement.', [CmpFullName(Self)]);

  EquelCondition := '';

  vSQL := ReadySelectText;
  for i := sc downto 1 do
    with SortFieldInfo(i) do
      begin
        tf := FindField(FieldName);
        if Assigned(tf) then
          begin
            FN := FieldNameForSQL(TableAliasForField(FieldName), GetRelationFieldName(tf));
            ParName := '?' + FormatIdentifier(3, 'NEW_' + FieldName);

            useCoalesce := Database.IsFB21OrMore and vFieldDescrList[tf.FieldNo - 1]
              ^.fdNullable;
            // useCoalesce:=false;
            if useCoalesce then
              begin
                case tf.DataType of
                  ftString, ftWideString:
                    begin
                      // ParName1:='COALESCE('+ParName+','+' '''' )';

                      ParName1 := 'COALESCE(' + ParName + ',' + '''''' + ',' + FN + ' )';
                      // ^^^^^^^Third arg is for setting param length
                      fn1 := 'COALESCE(' + FN + ','''' )';

                    end;
                  ftSmallint, ftLargeint, ftInteger, ftBoolean, ftFloat, ftCurrency, ftBCD, ftFMTBcd:
                    begin
                      ParName1 := 'COALESCE(' + ParName + ',' + IntToStr(Low(Int64)) + ')';
                      fn1 := 'COALESCE(' + FN + ',' + IntToStr(Low(Int64)) + ')';
                    end;
                  ftTime:
                    begin
                      ParName1 := 'COALESCE(' + ParName + ',Cast(''00:00'' AS TIME))';
                      fn1 := 'COALESCE(' + FN + ',Cast(''00:00'' AS TIME))';
                    end;
                  ftDate:
                    begin
                      ParName1 := 'COALESCE(' + ParName + ',Cast(''01.01.1753'' AS DATE))';
                      fn1 := 'COALESCE(' + FN + ',Cast(''01.01.1753'' AS DATE))';
                    end;
                  ftDateTime:
                    begin
                      ParName1 := 'COALESCE(' + ParName + ',Cast(''01.01.1753'' AS TIMESTAMP))';
                      fn1 := 'COALESCE(' + FN + ',Cast(''01.01.1753'' AS TIMESTAMP))';
                    end;

                  else // case
                    begin
                      ParName1 := ParName;
                      fn1 := FN;
                    end;
                end;
              end
            else
              ParName1 := ParName;
            if i < sc then
              begin
                EquelCondition := ' and (' + FN + '=' + ParName + ')';

                if useCoalesce then
                  begin
                    vPartWhere := '((' + vPartWhere + EquelCondition + ') or (' + fn1 + sign[Asc] + ParName1 + '))';
                    vPartWhereDesc := '((' + vPartWhereDesc + EquelCondition + ') or ('
                      + fn1 + sign[not Asc] + ParName1 + '))';
                  end
                else
                  begin
                    vPartWhere := '((' + vPartWhere + EquelCondition + ') or (' + FN + sign[Asc] + ParName + '))';
                    vPartWhereDesc := '((' + vPartWhereDesc + EquelCondition + ') or ('
                      + FN + sign[not Asc] + ParName + '))';
                  end;
              end
            else
              begin
                vPartWhere := '(' + FN + sign[Asc] + ParName1 + ')';
                vPartWhereDesc := '(' + FN + sign[not Asc] + ParName1 + ')';
              end;
          end;
      end;
  // vInvertedOrder:=InvertOrderClause(OrderClause);
  vInvertedOrder := OrderStringTxt(vSQL, i, i); // for macro changed order
  vInvertedOrder := InvertOrderClause(vInvertedOrder);
  vSQL := FQSelect.SQL.Text;
  if not Assigned(FQSelectDesc) then
    FQSelectDesc := CreateInternalQuery('SelectDescQuery');
  with FQSelectDesc do
    begin
      Close;
      BeginModifySQLText;
      SQL.Text := vSQL;
      OrderClause := vInvertedOrder;
      Database := Self.Database;
      Transaction := Self.Transaction;
      PlanClause := FCacheModelOptions.FPlanForDescSQLs;
      EndModifySQLText;
    end;

  if not Assigned(FQSelectPart) then
    FQSelectPart := CreateInternalQuery('SelectPartQuery');
  with FQSelectPart do
    begin
      Close;
      Database := Self.Database;
      Transaction := Self.Transaction;
      SQL.Text := AddToWhereClause(vSQL, vPartWhere);
    end;

  if not Assigned(FQSelectDescPart) then
    FQSelectDescPart := CreateInternalQuery('SelectPartDescQuery');
  with FQSelectDescPart do
    begin
      Close;
      Database := Self.Database;
      Transaction := Self.Transaction;
      BeginModifySQLText;
      SQL.Text := AddToWhereClause(vSQL, vPartWhereDesc);
      PlanClause := FCacheModelOptions.FPlanForDescSQLs;
      OrderClause := vInvertedOrder;
      EndModifySQLText;
    end;

  vLocateWhere := '';
  for i := 0 to Pred(FKeyFieldsForBookMark.Count) do
    begin
      tf := FindField(FKeyFieldsForBookMark.Strings[i]);
      if Assigned(tf) then
        begin
          FN := FieldNameForSQL(TableAliasForField(tf.FieldName), GetRelationFieldName(tf));
          if i > 0 then
            vLocateWhere := vLocateWhere + ' and ';
          vLocateWhere := vLocateWhere + '(' + FN + '=?' + FormatIdentifier(3, LocateParamPrefix + tf.FieldName) + ')';
        end;
    end;

  if not Assigned(FQBookMark) then
    FQBookMark := CreateInternalQuery('SelectLocate');
  with FQBookMark do
    begin
      Close;
      Database := Self.Database;
      Transaction := Self.Transaction;
      SQL.Text := AddToWhereClause(vSQL, vLocateWhere);
    end;
end;

function TFIBCustomDataSet.CanHaveLimitedCache: Boolean;
var
  i: Integer;
  pc: Integer;
begin
  Result := not CachedUpdates and (OrderClause <> '') and (AutoCommit or (UpdateTransaction = Transaction));

  if Result then
    begin
      pc := Pred(ParamCount);
      for i := 0 to pc do
        if IsNewParamName(Params[i].Name) then
          begin
            Result := false;
            Exit;
          end;
    end;
end;

procedure TFIBCustomDataSet.SetCacheModelOptions(aCacheModelOptions: TCacheModelOptions);
begin
  FCacheModelOptions.Assign(aCacheModelOptions);
end;

function TFIBCustomDataSet.GetBufferChunks: Integer;
begin
  Result := FCacheModelOptions.FBufferChunks
end;

procedure TFIBCustomDataSet.SetBufferChunks(Value: Integer);
begin
  FCacheModelOptions.BufferChunks := Value
end;

function TFIBCustomDataSet.StoreUpdTransaction: Boolean;
begin
  Result := (FQDelete.Transaction <> FQSelect.Transaction) or (csAncestor in ComponentState)
end;

procedure TFIBCustomDataSet.SetUpdateTransaction(Value: TFIBTransaction);
begin
  if FRefreshTransactionKind = tkUpdateTransaction then
    FQRefresh.Transaction := Value;
  if Assigned(FQDelete.Transaction) then
    with FQDelete.Transaction do
      begin
        RemoveEvent(DoBeforeStartUpdateTransaction, tetBeforeStartTransaction);
        RemoveEvent(DoAfterStartUpdateTransaction, tetAfterStartTransaction);
        RemoveEndEvent(DoBeforeEndUpdateTransaction, tetBeforeEndTransaction);
        RemoveEndEvent(DoAfterEndUpdateTransaction, tetAfterEndTransaction);
      end;
  FQDelete.Transaction := Value;
  FQInsert.Transaction := Value;
  FQUpdate.Transaction := Value;
  if Assigned(Value) then
    begin
      Value.AddEvent(DoBeforeStartUpdateTransaction, tetBeforeStartTransaction);
      Value.AddEvent(DoAfterStartUpdateTransaction, tetAfterStartTransaction);
      Value.AddEndEvent(DoBeforeEndUpdateTransaction, tetBeforeEndTransaction);
      Value.AddEndEvent(DoAfterEndUpdateTransaction, tetAfterEndTransaction);
    end;
end;

function TFIBCustomDataSet.GetUpdateTransaction: TFIBTransaction;
begin
  Result := FQUpdate.Transaction
end;

procedure TFIBCustomDataSet.ReopenLocate(const LocateFieldNames: string);
var
  NeedKeepCurrent: Boolean;
  LocateFields: string;
  NewValues: array of Variant;
  i, j, R: Integer;
  OldActiveRecord: Integer;
begin
  CheckNotUniDirectional;
  if FRecordCount > 0 then
    NeedKeepCurrent := (LocateFieldNames <> '') or (not EmptyStrings(QRefresh.SQL) and InternalRefreshRow(QRefresh,
      GetActiveBuf))
  else
    NeedKeepCurrent := false;
  R := GetRecNo;
  OldActiveRecord := ActiveRecord;
  if NeedKeepCurrent then
    begin
      LocateFields := LocateFieldNames;
      SetLength(NewValues, 0);
      j := 0;
      if LocateFields = '' then
        begin
          for i := 0 to Pred(FieldCount) do
            if (Fields[i].FieldKind = fkData) and not(Fields[i].IsBlob)
    {$IFDEF SUPPORT_ARRAY_FIELD}
              and not(Fields[i] is TFIBArrayField)
    {$ENDIF}
            then
              begin
                if j > 0 then
                  LocateFields := LocateFields + ';';
                LocateFields := LocateFields + Fields[i].FieldName;
                SetLength(NewValues, j + 1);
                NewValues[j] := Fields[i].Value;
                Inc(j);
              end;
          NeedKeepCurrent := LocateFields <> '';
        end
      else
        begin
          repeat
            i := PosCh(';', LocateFields);
            SetLength(NewValues, j + 1);
            if i = 0 then
              NewValues[j] := FBN(LocateFields).Value
            else
              begin
                NewValues[j] := FBN(FastCopy(LocateFields, 1, i - 1)).Value;
                LocateFields := FastCopy(LocateFields, i + 1, MaxInt);
                // System.Delete(LocateFields, 1, i);
              end;
            Inc(j);
          until i = 0;
          LocateFields := LocateFieldNames;
        end;
    end;
  DisableControls;
  DisableScrollEvents;
  try
    CloseOpen(false);
    if NeedKeepCurrent then
      begin
        if FRecordCount < R then
          FetchNext(R - FRecordCount);
        if InternalLocate(LocateFields, NewValues, [], True) then
          begin
            SetRecordPosInBuffer(OldActiveRecord);
          end;
      end;
  finally
    EnableControls;
    EnableScrollEvents;
  end;
end;

procedure TFIBCustomDataSet.FullRefresh;
begin
  InternalFullRefresh
end;

procedure TFIBCustomDataSet.InternalFullRefresh(NeedResync: Boolean = True; ReopenRefreshSQL: Boolean = True);
var
  R, R1: Integer;
begin
  case FCacheModelOptions.CacheModelKind of
    cmkStandard: ReopenLocate('');
    cmkLimitedBufferSize:
      if Active then
        begin
          DoBeforeRefresh;
          R := GetRealRecNo;
          R1 := R mod FCacheModelOptions.FBufferChunks;
          if R1 = 0 then
            R1 := FCacheModelOptions.FBufferChunks;
          FRecordsCache.SaveOldBuffer(R1);
          AssignSQLObjectParams(QRefresh, [Self]);
          RefreshAround(QRefresh, R, false, ReopenRefreshSQL);
          ClearFieldStreamList;
          if NeedResync then
            Resync([]);
          DoAfterRefresh;
        end
      else
        Open;
  end;
end;

{$WARNINGS OFF}

function TFIBCustomDataSet.FetchNext(FetchCount: DWORD): Integer;
var
  Buffer: TRecordBuffer;
  iCurScreenState: Integer;
begin
  Result := 0;
  if AllFetched then
    Exit;
  Buffer := AllocRecordBuffer;
  ChangeScreenCursor(iCurScreenState);
  try
    while (Result < FetchCount) and (FQSelect.Next <> nil) do
      begin
        FetchRecordToCache(FQSelect, FRecordCount);
        Inc(FRecordCount);
        Inc(Result)
      end;
  { except
      end; }
  finally
    RestoreScreenCursor(iCurScreenState);
    FreeRecordBuffer(Buffer);
  end
end;
// {$WARNINGS ON}

/// / PrepareOptions Stream

{$DEFINE FIB_IMPLEMENT}
{$I FIBDataSetPT.inc}
{$UNDEF FIB_IMPLEMENT}

function TFIBCustomDataSet.GetXSQLVAR(Fld: TField): TXSQLVAR;
begin
  if (Fld = nil) or (Fld.FieldKind <> fkData) then
    begin
      FillChar(Result, SizeOf(Result), 0);
      Result.SQLType := -1;
      Exit;
    end;
  if FieldDefs.Count = 0 then
    FieldDefs.Update;
  if Assigned(QSelect.Database) and Assigned(QSelect.Transaction) and (QSelect.SQL.Count > 0) then
    begin
      if not QSelect.Prepared then
        QSelect.Prepare;
      if QSelect.Current.Count > 0 then
        begin
          if not Active and (Fld.FieldNo = 0) then
            BindFields(True);
          Result := QSelect.Current[Fld.FieldNo - 1].Data^
        end
      else
        Result.SQLType := -1;
    end
  else
    Result.SQLType := -1;
end;

function TFIBCustomDataSet.GetFieldScale(Fld: TNumericField): Short;
begin
  Result := 100;
  if (Fld = nil) or (Fld.FieldKind <> fkData) then
    Exit;
  with GetXSQLVAR(Fld) do
    if SQLType <> -1 then
      Result := sqlscale
end;

function TFIBCustomDataSet.GetRelationTableName(Field: TObject): string;
var
  fi: PFIBFieldDescr;
begin
  Result := '';
  if (Field = nil) then
    Exit;
  if Field is TField then
    begin
      case TField(Field).FieldKind of
        fkData:
          begin
            if QSelect.Prepared then
              with GetXSQLVAR(TField(Field)) do
                begin
                  if SQLType <> -1 then
                    Result := QSelect.Current[TField(Field).FieldNo - 1].RelationName
                end
            else
              begin
                fi := vFieldDescrList[TField(Field).FieldNo - 1];
                Result := fi^.fdRelationTable
              end
          end;
        fkCalculated: Result := 'CALCULATED';
        fkLookup:
          if TField(Field).LookupDataSet is TFIBCustomDataSet then
            with TFIBCustomDataSet(TField(Field).LookupDataSet) do
              Result := GetRelationTableName
                (FindField(TField(Field).LookupResultField))
      end;
    end
  else if Field is TFieldDef then
    begin
      if QSelect.Prepared then
        with QSelect.Current[TFieldDef(Field).FieldNo - 1] do
          begin
            if Data^.SQLType <> -1 then
              Result := RelationName;
          end
      else
        begin
          fi := vFieldDescrList[TFieldDef(Field).FieldNo - 1];
          Result := fi^.fdRelationTable
        end
    end;
end;

function TFIBCustomDataSet.GetRelationFieldName(Field: TObject): string;
var
  fi: PFIBFieldDescr;
begin
  Result := '';
  if (Field = nil) then
    Exit;
  if Field is TField then
    begin
      case TField(Field).FieldKind of
        fkData:
          begin
            if QSelect.Prepared then
              with GetXSQLVAR(TField(Field)) do
                begin
                  if SQLType <> -1 then
                    Result := QSelect.Current[TField(Field).FieldNo - 1].SqlName;
                end
            else
              begin
                fi := vFieldDescrList[TField(Field).FieldNo - 1];
                Result := fi^.fdRelationField
              end
          end;
        fkCalculated: Result := TField(Field).FieldName;
        fkLookup:
          if TField(Field).LookupDataSet is TFIBCustomDataSet then
            with TFIBCustomDataSet(TField(Field).LookupDataSet) do
              Result := GetRelationFieldName
                (FindField(TField(Field).LookupResultField))
      end;
    end
  else if Field is TFieldDef then
    begin
      if QSelect.Prepared then
        with QSelect.Current[TFieldDef(Field).FieldNo - 1] do
          begin
            if Data^.SQLType <> -1 then
              Result := SqlName;
          end
      else
        begin
          fi := vFieldDescrList[TFieldDef(Field).FieldNo - 1];
          Result := fi^.fdRelationField
        end
    end;
  if Result = 'DB_KEY' then
    Result := 'RDB$DB_KEY'
end;

function TFIBCustomDataSet.AdjustCurrentRecord(Buffer: Pointer; GetMode: TGetMode): TGetResult;
begin
  (*
    * Skip over all invisible records.
  *)
  if FCacheModelOptions.CacheModelKind = cmkLimitedBufferSize then
    begin
      Result := grOk;
      Exit;
    end;

  if Assigned(Buffer) then
    while not IsVisible(Buffer) do
      begin
        if GetMode = gmPrior then
          begin
            if FCurrentRecord >= 0 then
              Dec(FCurrentRecord);
            if FCurrentRecord = -1 then
              begin
                Result := grBOF;
                Exit;
              end;
            ReadRecordCache(FCurrentRecord, Buffer, false);
          end
        else
          begin
            Inc(FCurrentRecord);
            if (FCurrentRecord = FRecordCount) then
              begin
                if (not FQSelect.Eof) and (FQSelect.Next <> nil) then
                  begin
                    FetchCurrentRecordToBuffer(FQSelect, FCurrentRecord, Buffer);
                    Inc(FRecordCount);
                  end
                else
                  begin
                    Result := grEOF;
                    Exit;
                  end;
              end
            else
              ReadRecordCache(FCurrentRecord, Buffer, false);
          end;
      end;
  Result := grOk;
end;

function TFIBCustomDataSet.GetAllFetched: Boolean;
begin
  Result := QSelect.Eof
end;

procedure TFIBCustomDataSet.BatchInput(InputObject: TFIBBatchInputStream; SQLKind: TpSQLKind);
begin
  case SQLKind of
    skInsert: FQInsert.BatchInput(InputObject);
    skModify: FQUpdate.BatchInput(InputObject);
    FIBDataSet.skDelete: FQDelete.BatchInput(InputObject);
    skRefresh: FQRefresh.BatchInput(InputObject);
    else
      FQInsert.BatchInput(InputObject);
  end;
end;

procedure TFIBCustomDataSet.BatchOutput(OutputObject: TFIBBatchOutputStream);
var
  Qry: TFIBQuery;
  i: Integer;
begin
  Qry := TFIBQuery.Create(Self);
{$IFDEF CSMonitor}
  Qry.CSMonitorSupport.Enabled := FCSMonitorSupport.Enabled;
  Qry.CSMonitorSupport.IncludeDatasetDescription := FCSMonitorSupport.IncludeDatasetDescription;
{$ENDIF}
  with Qry do
    try
      Database := FBase.Database;
      Transaction := FBase.Transaction;
      SQL.Assign(FQSelect.SQL);
      Prepare;
      for i := 0 to Pred(Params.Count) do
        Params[i].Assign(Self.Params[i]);
      BatchOutput(OutputObject);
    finally
      Free;
    end;
end;

procedure TFIBCustomDataSet.CancelUpdates;
var
  i: Integer;
begin
  DisableControls;
  try
    if State in [dsEdit, dsInsert] then
      Cancel;
    if not FUpdatesPending or not FCachedUpdates then
      Exit;
    for i := 0 to Pred(FRecordCount) do
      InternalRevertRecord(i, false);
    FCountUpdatesPending := 0;
    FUpdatesPending := false;
    RefreshFilters;
    if Assigned(FRecordsCache) then
      FRecordsCache.ClearLog;
  finally
    EnableControls;
  end;
end;

procedure TFIBCustomDataSet.CheckDatasetClosed(const Reason: string);
begin
  if FOpen then
    FIBError(feDataSetOpen, [Reason, CmpFullName(Self)]);
end;

procedure TFIBCustomDataSet.CheckDatasetOpen(const Reason: string);
begin
  if State = dsInactive then
    FIBError(feDataSetClosed, [Reason, CmpFullName(Self)]);
end;

procedure TFIBCustomDataSet.CheckNotUniDirectional;
begin
  if UniDirectional then
    FIBError(feDataSetUniDirectional, [CmpFullName(Self)]);
end;

function TFIBCustomDataSet.CanEdit: Boolean;
var
  Buff: PRecordData;
begin
  Buff := PRecordData(GetActiveBuf);
  Result := (not EmptyStrings(FQUpdate.SQL)) or
    ((Buff <> nil) and (TCachedUpdateStatus(Buff^.rdFlags) = cusInserted) and FCachedUpdates);
end;

function TFIBCustomDataSet.CanInsert: Boolean;
begin
  Result := not EmptyStrings(FQInsert.SQL);
end;

function TFIBCustomDataSet.CanDelete: Boolean;
begin
  Result := not EmptyStrings(FQDelete.SQL)
end;

procedure TFIBCustomDataSet.CheckFieldCompatibility(Field: TField; FieldDef: TFieldDef);
begin
  with Field do
    case DataType of
      ftDate, ftTime, ftDateTime:
        if DataType <> FieldDef.DataType then
          DatabaseErrorFmt(SFieldTypeMismatch, [DisplayName, FieldTypeNames[DataType],
            FieldTypeNames[FieldDef.DataType]], Self);
      else
        inherited CheckFieldCompatibility(Field, FieldDef);
    end;
end;

procedure TFIBCustomDataSet.CheckInactive;
begin
  if not(drsDontCheckInactive in FRunState) then
    inherited CheckInactive;
end;

procedure TFIBCustomDataSet.CheckEditState;
var
  RState: TDataSetState;
begin
  CheckActive;
  if State in [dsNewValue, dsOldValue] then
    RState := vPredState
  else
    RState := State;
  case RState of
    dsEdit:
      if not CanEdit then
        FIBError(feCannotUpdate, [CmpFullName(Self)]);
    dsInsert:
      if not CanInsert then
        FIBError(feCannotInsert, [CmpFullName(Self)]);
    else
      FIBError(feNotInEditState, [CmpFullName(Self)])
  end;
end;

procedure TFIBCustomDataSet.ClearFieldStreamList;
var
  i: Integer;
begin
  if Assigned(FFieldStreamList) then
    for i := FFieldStreamList.Count - 1 downto 0 do
      TFIBFieldStream(FFieldStreamList[i]).Free;
end;

function TFIBCustomDataSet.CompareFieldValues(Field: TField; const S1, S2: Variant): Integer;
begin
  // For Sort String fields
  if Assigned(FOnCompareFieldValues) then
    Result := FOnCompareFieldValues(Field, S1, S2)
  else
    Result := StdCompareValues(Field, S1, S2);
end;

function TFIBCustomDataSet.StdCompareValues(Field: TField; const S1, S2: Variant): Integer;
begin
  if VarIsNull(S1) then
    begin
      if VarIsNull(S2) then
        Result := 0
      else
        Result := -1;
    end
  else
    begin
      if VarIsNull(S2) then
        Result := 1
      else
        case Field.DataType of
          ftString:
  {$IFDEF UNICODE_TO_STRING_FIELDS}
            if (Field is TFIBStringField) and (TFIBStringField(Field).CodePage = FIBCodePageUTF8) then
              Result := WideCompareStr(S1, S2)
            else
              Result := AnsiCompareStr(S1, S2);
  {$ELSE}
            Result := AnsiCompareStr(S1, S2);
  {$ENDIF}
          ftWideString: Result := WideCompareStr(S1, S2);
          else
            Result := CompareVariants(S1, S2);
        end;
    end;
end;

function TFIBCustomDataSet.StdAnsiCompareString(Field: TField; const S1, S2: Variant): Integer;
begin
  if VarIsNull(S1) or VarIsNull(S2) then
    Result := StdCompareValues(Field, S1, S2)
  else if Field.DataType in [ftString, ftFixedChar] then
    Result := AnsiCompareStr(S1, S2)
  else
    Result := StdCompareValues(Field, S1, S2);
end;

function TFIBCustomDataSet.AnsiCompareString(Field: TField; const val1, val2: Variant): Integer;
var
  i, L1, L2: Integer;
  up1, up2: Boolean;
  S1, S2: string;
begin
  if Field.DataType in [ftString, ftFixedChar] then
    begin
      S1 := val1;
      S2 := val2;
      L1 := Length(S1);
      L2 := Length(S2);
      if L1 > L2 then
        begin
          L1 := L2;
          Result := 1
        end
      else if L1 < L2 then
        Result := -1
      else
        Result := 0;
      for i := 1 to L1 do
        if (S1[i] <> S2[i]) then
          begin
            up1 := S1[i] = AnsiUpperCase(S1[i]);
            up2 := S2[i] = AnsiUpperCase(S2[i]);
            if up1 then
              begin
                if up2 then
                  Result := AnsiCompareStr(S1[i], S2[i])
                else
                  Result := -1
              end
            else
              begin
                if up2 then
                  Result := 1
                else
                  Result := AnsiCompareStr(S1[i], S2[i])
              end;
            Exit;
          end;
    end
  else
    Result := StdCompareValues(Field, S1, S2);
end;

procedure TFIBCustomDataSet.CopyRecordBuffer(Source, Dest: Pointer);
begin
  if Assigned(Source) and Assigned(Dest) then
    Move(Source^, Dest^, FRecordBufferSize);
end;

procedure TFIBCustomDataSet.DoDatabaseDisconnecting(Sender: TObject);
begin
  if Active then
    begin
      if ((poDontCloseAfterEndTransaction in Options) or FCachedUpdates) and
        not(csDestroying in ComponentState) and not(csDesigning in ComponentState) then

        // if FCachedUpdates or  then
        FetchAll
      else
        Active := false;
    end;
  FPrepared := false;
  if Assigned(FDatabaseDisconnecting) then
    FDatabaseDisconnecting(Sender);
end;

procedure TFIBCustomDataSet.DoDatabaseDisconnected(Sender: TObject);
begin
  if Assigned(FDatabaseDisconnected) then
    FDatabaseDisconnected(Sender);
end;

procedure TFIBCustomDataSet.DoDatabaseFree(Sender: TObject);
begin
  if Assigned(FDatabaseFree) then
    FDatabaseFree(Sender);
end;

procedure TFIBCustomDataSet.DoTransactionEnding(Sender: TObject);
begin
  if Assigned(FTransactionEnding) then
    FTransactionEnding(Sender);
  if Transaction.State in [tsDoRollback, tsDoCommit] then
    if Active then
      begin
        if ((poDontCloseAfterEndTransaction in Options) or FCachedUpdates) and not(csDestroying in ComponentState) and
          not(csDesigning in ComponentState) then
          begin
            FetchAll;
            if QSelect.Open then
              QSelect.Close;
          end
        else
          Active := false;
      end;
end;

procedure TFIBCustomDataSet.DoTransactionEnded(Sender: TObject);
begin
  if Assigned(FTransactionEnded) then
    FTransactionEnded(Sender);
end;

procedure TFIBCustomDataSet.DoTransactionFree(Sender: TObject);
begin
  if Assigned(FTransactionFree) then
    FTransactionFree(Sender);
end;

// Read the record from FQSelect.Current into cache (temporary file)

const
  IBBuffDateDelta = 678576;
  FMSecsPerDay: Single = MSecsPerDay;

type
  TFriendFieldStream = class(TFIBFieldStream);
  PTimeStamp = ^TTimeStamp;

procedure TFIBCustomDataSet.FetchRecordToCache(Qry: TFIBQuery; RecordNumber: Integer);
var
  p: PSavedRecordData;
  pbd: PFIBFieldStreamArray;
  i, j, C: Integer;
  LocalData: TDataBuffer;
  StopFetching: Boolean;
  qda: TFIBXSQLDA;
  vvFieldLength: Integer;
  fi: PFIBFieldDescr;
  Buffer: TRecordBuffer;
  curVar: TFIBXSQLVAR;
begin
  StopFetching := false;
  if FUniDirectional or (FCacheModelOptions.CacheModelKind = cmkLimitedBufferSize) then
    RecordNumber := RecordNumber mod FCacheModelOptions.FBufferChunks;
  Buffer := FRecordsCache.PrepareMemory(RecordNumber + 1);
  p := PSavedRecordData(Buffer);
  qda := Qry.Current;
  // Make sure blob cache is empty
  pbd := PFIBFieldStreamArray(Buffer + FStreamsCacheOffset);
  if not(drsInRefreshRow in FRunState) then
    for i := 0 to StreamFieldCount - 1 do
      begin
        if pbd^[i] <> nil then
          begin
            if (pbd^[i].IndexInList >= 0) and (pbd^[i].IndexInList < FFieldStreamList.Count) then
              if (pbd^[i] = FFieldStreamList[pbd^[i].IndexInList]) then
                pbd^[i].Free;
            pbd^[i] := nil
          end
      end;

  // Get record information
  p^.rdFlags := Byte(cusUnmodified);
  // Load up the fields
  C := qda.Count - 1;

  for i := 0 to C do
    begin
      curVar := qda[i];
      if (Qry = FQSelect) then
        j := i + 1
      else
        j := FQSelect.FieldIndex[curVar.Name] + 1;
      if j > 0 then
        with p^, p^.rdFields[j] do
          begin
            fi := vFieldDescrList.List.List[j - 1];
            with curVar.Data^ do
              fdIsNull := (fi^.fdNullable and (sqlind <> nil) and (sqlind^ = -1));

            if fdIsNull then
              begin
                case fi^.fdDataType of
                  SQL_VARYING, SQL_TEXT:
                    begin
                      if fi^.fdIsSeparateString then
                        begin
                          FRecordsCache.SetStringValue(fi^.fdStrIndex, RecordNumber, '');
                        end;
                      Continue;
                    end;
                  SQL_BLOB, SQL_ARRAY: ;
                  else // case
                    Continue;
                end;
              end;

            LocalData := curVar.Data^.sqldata;
            case fi^.fdDataType of
              SQL_TIMESTAMP:
                with PISC_QUAD(LocalData)^ do
                  begin
                    PDouble(@Buffer[fi^.fdDataOfs - DiffSizesRecData])^ :=
                      (gds_quad_high + IBBuffDateDelta) * FMSecsPerDay + (gds_quad_low div 10);
                  end;
              SQL_TYPE_DATE:
                begin
                  PInteger(@Buffer[fi^.fdDataOfs - DiffSizesRecData])^ := PISC_DATE(LocalData)^ + IBBuffDateDelta;
                end;
              SQL_TYPE_TIME:
                begin
                  PInteger(@Buffer[fi^.fdDataOfs - DiffSizesRecData])^ := PISC_TIME(LocalData)^ div 10;
                end;
              SQL_INT64:
                if (fi^.fdDataScale < -4) and not(psSQLINT64ToBCD in PrepareOptions) then
                  begin
                    PDouble(@Buffer[fi^.fdDataOfs - DiffSizesRecData])^ := curVar.AsDouble;
                  end
                else
                  begin
                    PInt64(@Buffer[fi^.fdDataOfs - DiffSizesRecData])^ := PInt64(LocalData)^
                  end;
              SQL_VARYING:
                begin
                  // vvFieldLength :=DataBase.ClientLibrary.isc_vax_integer(LocalData, 2);
                  vvFieldLength := PWord(LocalData)^;
                  // It is isc_vax_integer(LocalData, 2);
                  if vvFieldLength = 0 then
                    begin
                      if fi^.fdIsSeparateString then
                        FRecordsCache.SetStringValue(fi^.fdStrIndex, RecordNumber, '')
                      else
                        FillChar(Buffer[fi^.fdDataOfs - DiffSizesRecData], fi^.fdDataSize, 0)
                    end
                  else
                    begin
                      Inc(PByte(LocalData), 2);
                      if vvFieldLength < fi^.fdDataSize then
                        { FillChar(PAnsiChar(LocalData)[vvFieldLength],fi^.fdDataSize-vvFieldLength-1,0); }

                        PAnsiChar(LocalData)[vvFieldLength] := #0;

                      // FillChar(Buffer[fi^.fdDataOfs-DiffSizesRecData],fi^.fdDataSize,0);

                      if fi^.fdIsSeparateString then
                        FRecordsCache.SetStringFromPChar(fi^.fdStrIndex, RecordNumber,
                          PAnsiChar(LocalData), vvFieldLength, false)
                      else
                        Move(LocalData^, Buffer[fi^.fdDataOfs - DiffSizesRecData], fi^.fdDataSize);
                    end;
                end;
              SQL_TEXT:
                if fi^.fdIsSeparateString then
                  begin
                    FRecordsCache.SetStringFromPChar(fi^.fdStrIndex, RecordNumber, PAnsiChar(LocalData), -1, True);
                  end
                else
                  begin
                    if not fdIsNull then
                      Move(LocalData^, Buffer[fi^.fdDataOfs - DiffSizesRecData], fi^.fdDataSize)
                    else
                      FillChar(Buffer[fi^.fdDataOfs - DiffSizesRecData], fi^.fdDataSize, 0)
                  end;

              else
                // BLOBS and BOOLEAN BLOB_ID
                if fdIsNull then
                  FillChar(LocalData^, fi^.fdDataSize, 0) // for Blob only
                else
                  Move(LocalData^, Buffer[fi^.fdDataOfs - DiffSizesRecData], fi^.fdDataSize);
            end;
          end;
    end;
  // if (Qry=FQRefresh) then
  if (drsInRefreshRow in FRunState) then
    begin
      for i := 0 to StreamFieldCount - 1 do
        if pbd^[i] <> nil then
          begin
            j := Qry.FieldIndex[FQSelect.Fields[pbd^[i].FieldNo - 1].Name];
            if (j > -1) then
              if (State in [dsEdit, dsInsert]) and (pbd^[i].BlobID.gds_quad_high = 0) and
                (pbd^[i].UpdateTransaction = Qry.Transaction) then
                begin
                  TFriendFieldStream(pbd^[i]).ReplaceBlobID(Qry.Fields[j].AsQuad);
                end
              else if not EquelQUADs(Qry.Fields[j].AsQuad, pbd^[i].BlobID) then
                begin
                  if (RefreshTransactionKind = tkUpdateTransaction) and (Qry.Fields[j].ServerSQLSubType = 1) and
                    Database.IsFirebirdConnect and (Database.ServerMajorVersion >= 2)
                    and (pbd^[i].BlobID.gds_quad_high = 0) and (Qry.Fields[j].AsQuad.gds_quad_high = 0) then
                    begin
                      // Is decoded blob
                      TFIBBlobStream(pbd^[i]).CloseBlob;
                      pbd^[i].DeInitialize;
                      pbd^[i].Transaction := UpdateTransaction;
                      pbd^[i].BlobID := Qry.Fields[j].AsQuad;
                      pbd^[i].DoSeek(0, soFromBeginning, nil);
                    end
                  else
                    begin
                      pbd^[i].Free;
                      pbd^[i] := nil;
                    end
                end
          end;
    end;

  if Assigned(FAfterFetchRecord) then
    FAfterFetchRecord(Qry, RecordNumber, StopFetching);
  if StopFetching then
    begin
      Inc(FRecordCount);
      Abort;
    end;
end;

procedure TFIBCustomDataSet.InitDataSetSchema;
var
  i, C: Integer;
  rdl: Integer;
  qda: TFIBXSQLDA;

  vvFieldBufSize: Integer;
  vvSeparateString: Boolean;
  fi: PFIBFieldDescr;
  vvSqlType: Integer;
  vvSqlSubType: Short;
  StrIndex: Integer;
  atf: TAddedTypeFields;

begin
  rdl := RecordDataLength(FQSelect.Current.Count);
  FRecordSize := rdl; // (1)
  FBlockReadSize := rdl - DiffSizesRecData;
  FStringFieldCount := 0;

  qda := QSelect.Current;
  // Load up the fields
  C := qda.Count - 1;
  vFieldDescrList.Capacity := C + 1;
  vrdFieldCount := vFieldDescrList.Capacity;

  for i := 0 to C do
    begin
      with qda[i].Data^ do
        begin
          vvSqlType := SQLType and (not 1);
          vvSqlSubType := SqlSubType;
          vvSeparateString := false;
          StrIndex := -1;
          case vvSqlType of
            SQL_FLOAT: vvFieldBufSize := SizeOf(Single);
            SQL_DOUBLE, SQL_D_FLOAT: vvFieldBufSize := SizeOf(Double);
            SQL_SHORT:
              begin
                vvFieldBufSize := SizeOf(Short)
              end;
            SQL_LONG:
              begin
                vvFieldBufSize := SizeOf(Integer)
              end;
            SQL_TIMESTAMP: vvFieldBufSize := SizeOf(TTimeStamp);
            SQL_TYPE_DATE, SQL_TYPE_TIME: vvFieldBufSize := SizeOf(Integer);
            SQL_INT64:
              begin
                if (sqlscale = 0) then
                  vvFieldBufSize := SizeOf(Int64)
                else if (sqlscale >= -4) or (psSQLINT64ToBCD in PrepareOptions) then
                  vvFieldBufSize := SizeOf(Int64)
                else
                  vvFieldBufSize := SizeOf(Int64);
              end;
            SQL_VARYING, SQL_TEXT:
              begin
                vvFieldBufSize := sqllen;
                if not Database.NeedUnicodeFieldTranslation(Byte(vvSqlSubType)) and
                  (Byte(vvSqlSubType) in Database.UnicodeCharSets) then
                  if not IsSysField(qda[i].SqlName) or not Database.ReturnDeclaredFieldSize then
                    vvFieldBufSize := vvFieldBufSize div Database.BytesInUnicodeChar
                      (vvSqlSubType);

                if (FieldDefs[i].DataType in [ftGuid]) or StringInArray(qda[i].SqlName, ['DB_KEY', 'RDB$DB_KEY']) then
                  vvSeparateString := false
                else
                  vvSeparateString := (vvFieldBufSize > 20) or (Byte(vvSqlSubType) = OCTETS_CHARSET_ID);
                // ^^^ Nod separate

                if vvSeparateString then
                  begin
                    StrIndex := FStringFieldCount;
                    Inc(FStringFieldCount);
                  end;
              end;
            else
              vvFieldBufSize := sqllen;
          end;
          case FieldDefs[i].DataType of
            ftGuid: atf := atfGuidField;
            ftWideString: atf := atfWideStringField;
            else
              atf := atfStandard
          end;
          vFieldDescrList.Add(vvSqlType and (not 1), sqlscale, vvFieldBufSize,
            SQLType and 1 = 1, StringInArray(qda[i].SqlName, ['DB_KEY', 'RDB$DB_KEY']), vvSeparateString, atf);
        end;
      fi := vFieldDescrList[i];
      fi^.fdSubType := vvSqlSubType;
      fi^.fdRelationTable := qda[i].RelationName;
      fi^.fdRelationField := qda[i].SqlName;
      fi^.fdTableAlias := QSelect.TableAliasForField(i);

      if fi^.fdIsSeparateString then
        fi^.fdStrIndex := StrIndex
      else
        begin
          fi^.fdStrIndex := -1;
          fi^.fdDataOfs := FRecordSize;
          Inc(FRecordSize, vvFieldBufSize);
          Inc(FBlockReadSize, vvFieldBufSize);
        end;
    end;

  FStreamsCacheOffset := FBlockReadSize;
  for i := 0 to C do
    begin
      fi := vFieldDescrList[i];
      if fi^.fdIsSeparateString then
        begin
          fi^.fdDataOfs := FRecordSize;
          // Inc(FRecordSize,fi^.fdDataSize);
          Inc(FRecordSize, fi^.fdDataSize + SizeOf(Integer)); // LengthExp
        end;
    end;
end;

(*
  * Read the record from FQSelect.Current into the cache (temporary file)
  * Then write it to the record buffer.
*)

procedure TFIBCustomDataSet.FetchCurrentRecordToBuffer(Qry: TFIBQuery; RecordNumber: Integer; Buffer: TRecordBuffer);
begin
  if RecordNumber > -1 then
    begin
      FetchRecordToCache(Qry, RecordNumber);
      ReadRecordCache(RecordNumber, Buffer, false);
    end
  else
    InitDataSetSchema;
end;

function TFIBCustomDataSet.GetActiveBuf: TRecordBuffer;
begin
  case State of
    dsCalcFields: Result := TRecordBuffer(CalcBuffer)
    else
      if not FOpen then
        Result := nil
      else if IsEmpty and (State <> dsInsert) then
        Result := nil
      else
        Result := TRecordBuffer(ActiveBuffer);
  end;
end;

function TFIBCustomDataSet.CachedUpdateStatus: TCachedUpdateStatus;
begin
  if Active then
    if GetActiveBuf <> nil then
      Result := TCachedUpdateStatus(PRecordData(GetActiveBuf)^.rdFlags)
    else
      Result := cusUnmodified
  else
    Result := cusUnmodified;
end;

function TFIBCustomDataSet.GetDatabase: TFIBDatabase;
begin
  Result := FBase.Database;
end;

function TFIBCustomDataSet.GetDBHandle: PISC_DB_HANDLE;
begin
  Result := FBase.DBHandle;
end;

function TFIBCustomDataSet.GetDeleteSQL: TStrings;
begin
  Result := FQDelete.SQL;
end;

function TFIBCustomDataSet.GetInsertSQL: TStrings;
begin
  Result := FQInsert.SQL;
end;

function TFIBCustomDataSet.GetParams: TFIBXSQLDA;
begin
  Result := FQSelect.Params;
end;

function TFIBCustomDataSet.GetRefreshSQL: TStrings;
begin
  Result := FQRefresh.SQL;
end;

function TFIBCustomDataSet.GetSelectSQL: TStrings;
begin
  Result := FQSelect.SQL;
end;

function TFIBCustomDataSet.GetStatementType: TFIBSQLTypes;
begin
  Result := FQSelect.SQLType;
end;

function TFIBCustomDataSet.GetUpdateSQL: TStrings;
begin
  Result := FQUpdate.SQL;
end;

function TFIBCustomDataSet.GetTransaction: TFIBTransaction;
begin
  Result := FBase.Transaction;
end;

function TFIBCustomDataSet.GetTRHandle: PISC_TR_HANDLE;
begin
  Result := FBase.TRHandle;
end;

procedure TFIBCustomDataSet.InternalDeleteRecord(Qry: TFIBQuery; Buff: Pointer);
var
  vNeedDeleteFromCache: Boolean;
begin
  AutoStartUpdateTransaction;
  SetQueryParams(Qry, Buff);
  Qry.ExecQuery;
  if Qry.Open then
    Qry.Next;
  if poRefreshAfterDelete in Options then
    begin
      vNeedDeleteFromCache := not InternalRefreshRow(QRefresh, Buff);
    end
  else
    vNeedDeleteFromCache := True;

  with PRecordData(Buff)^ do
    begin
      if vNeedDeleteFromCache then
        rdFlags := Byte(cusDeletedApplied);
      WriteRecordCache(rdRecordNumber, Buff);
    end;
  if not FCachedUpdates then
    AutoCommitUpdateTransaction;
end;

{$DEFINE FIB_IMPLEMENT}
{$I FIBDataSetLocate.inc}
// ^^^^InternalLocate implement
{$UNDEF FIB_IMPLEMENT}

procedure TFIBCustomDataSet.CheckDataFields(FieldList: TList; const CallerProc: string);
var
  i: Integer;
begin
  if FieldList.Count = 0 then
    FIBError(feFieldListEmpty, [CmpFullName(Self) + '.' + CallerProc])
  else
    for i := 0 to FieldList.Count - 1 do
      begin
        if TField(FieldList[i]).FieldKind <> fkData then
          FIBError(feCantUseField, [CmpFullName(Self) + '.' + CallerProc, TField(FieldList[i]).FieldName])
      end;
end;

function TFIBCustomDataSet.InternalLocateForLimCache(const KeyFields: string;
  const KeyValues: array of Variant; Options: TExtLocateOptions;
  LocateKind: TLocateKind = lkStandard; aQLocate: TFIBQuery = nil): Boolean;
var
  fl: TFIBList;
  vQLocate: TFIBQuery;
  vLocateWhere: string;
  FN, ParName: string;
  i: Integer;
  R: Integer;
begin
  fl := TFIBList.Create;
  DisableControls;
  DisableScrollEvents;
  if aQLocate = nil then
    vQLocate := CreateInternalQuery('QLocate')
  else
    vQLocate := aQLocate;
  try
    GetFieldList(fl, KeyFields);
    CheckDataFields(fl, 'LocateForPartialCache');
    vQLocate.Database := Database;
    vQLocate.Transaction := Transaction;
    vLocateWhere := '';
    for i := 0 to Pred(fl.Count) do
      begin
        FN := FieldNameForSQL(TableAliasForField(TField(fl.List^[i]).FieldName),
          GetRelationFieldName(TField(fl.List^[i])));

        if i > 0 then
          vLocateWhere := vLocateWhere + ' and ';
        (* case VarType(KeyValues[i]) of
        varString,varOleStr {$IFDEF D2009+},varUString{$ENDIF}: *)
        case TField(fl.List^[i]).DataType of
          ftString, ftFixedChar, ftWideString:
            begin
              if eloCaseInsensitive in Options then
                begin
                  // ParName:='UPPER(?'+FormatIdentifier(3,LocateParamPrefix+TField(fl.List^[i]).FieldName)+')';
                  // ParName:='UPPER( @'+FormatIdentifier(3,LocateParamPrefix+TField(fl.List^[i]).FieldName)+'%# )';
                  if VarIsNull(KeyValues[i]) then
                    begin
                      ParName := '?' + FormatIdentifier(3, LocateParamPrefix + TField(fl.List^[i]).FieldName)
                    end
                  else
                    begin
                      ParName := 'UPPER( @' + LocateParamPrefix + TField(fl.List^[i]).FieldName + '%# )';
                      FN := 'UPPER(' + FN + ')'
                    end;
                end
              else
                // ParName:='?'+FormatIdentifier(3,LocateParamPrefix+TField(fl.List^[i]).FieldName);
                // ParName:='@'+FormatIdentifier(3,LocateParamPrefix+TField(fl.List^[i]).FieldName)+'%# ';

                if VarIsNull(KeyValues[i]) then
                  ParName := '?' + FormatIdentifier(3, LocateParamPrefix + TField(fl.List^[i]).FieldName)
                else
                  ParName := '@' + LocateParamPrefix + TField(fl.List^[i]).FieldName + '%# ';
              if eloPartialKey in Options then
                vLocateWhere := vLocateWhere + '(' + FN + ' starting with ' + ParName + ')'
              else if eloWildCards in Options then
                vLocateWhere := vLocateWhere + '(' + FN + ' like ' + ParName + ')'
              else
                vLocateWhere := vLocateWhere + '(' + FN + '=' + ParName + ')'
            end;
          else
            vLocateWhere := vLocateWhere + '(' + FN + '=?' + FormatIdentifier(3, LocateParamPrefix + TField(fl.List^[i])
              .FieldName) + ')';
        end
      end;

    case LocateKind of
      lkStandard: vQLocate.SQL.Text := AddToWhereClause(QSelect.SQL.Text, vLocateWhere);
      lkNext:
        begin
          vQLocate.SQL.Text := AddToWhereClause(FQSelectPart.SQL.Text, vLocateWhere);
          // AssignSQLObjectParams(vQLocate,[Self]);
        end;
      lkPrior:
        begin
          vQLocate.SQL.Text := AddToWhereClause(FQSelectDescPart.SQL.Text, vLocateWhere);
          // AssignSQLObjectParams(vQLocate,[Self]);
        end;
    end;

    if Assigned(Database) and Database.IsFirebirdConnect then
      begin
        vQLocate.SQL.Text := SetFirstClause(vQLocate.SQL.Text, 1);
        {
        Test speed only
        FQSelectDescPart.SQL.Text:=SetFirstClause(FQSelectDescPart.SQL.Text,1);
        FQSelectPart.SQL.Text:=SetFirstClause(FQSelectPart.SQL.Text,1); }
      end;
    AssignSQLObjectParams(vQLocate, [Self]);
    for i := 0 to Pred(fl.Count) do
      begin
        if Length(KeyValues) > i then
          vQLocate.Params.ByName[LocateParamPrefix + TField(fl.List^[i]).FieldName].Value := KeyValues[i]
      end;
    R := (FCacheModelOptions.FBufferChunks div 2) + 1;
    // R:=(FCacheModelOptions.FBufferChunks div 2);
    // ^^^^^^^^^^^^^^^08.2012
    // vQLocate.OrderClause:='';
    if aQLocate = nil then
      begin
        Result := RefreshAround(vQLocate, R);
        if Result then
          Resync([rmCenter]);
      end
    else
      with aQLocate do
        begin
          // From Lookup
          Close;
          Params.AssignValues(FQSelect.Params);
          ExecQuery;
          Next;
          Result := not Eof;
        end;
  finally
    fl.Free;
    EnableScrollEvents;
    EnableControls;
    if aQLocate = nil then
      vQLocate.Free
  end;
end;

procedure TFIBCustomDataSet.CallBackBlobWrite(BlobSize: Integer; BytesProcessing: Integer; var Stop: Boolean);
begin
  if (GlobalContainer <> nil) then
    GlobalContainer.DoOnWriteBlobField(TBlobField(FWritingBlob), BlobSize, BytesProcessing, Stop);
  if Assigned(FOnBlobFieldWrite) then
    begin
      FOnBlobFieldWrite(TBlobField(FWritingBlob), BlobSize, BytesProcessing, Stop);
    end
end;

function TFIBCustomDataSet.StreamFieldCount: Integer;
begin
  Result := BlobFieldCount + FArrayFieldCount;
end;

// Index of the stream slot of Field in a record buffer, -1 when it has none
function TFIBCustomDataSet.FieldStreamIndex(Field: TField): Integer;
begin
  if Field.IsBlob then
    Result := Field.Offset
{$IFDEF SUPPORT_ARRAY_FIELD}
  else if Field is TFIBArrayField then
    Result := TFIBArrayField(Field).FStreamIndex
{$ENDIF}
  else
    Result := -1;
end;

procedure TFIBCustomDataSet.UpdateFieldStreams(Buff: Pointer;
  Operation: TUpdateFieldStreams; ClearModified, ForceWrite: Boolean;
  Field: TField = nil);
var
  i: Integer;
  Streams: PFIBFieldStreamArray;
  SwapTableName, SwapFieldName: string;
  SwapKeyValues: TDynArray;

  function FillSwapInfo(Field: TField): Boolean;
  begin
    with Database.BlobSwapSupport do
      if not Active or (Length(SwapDirectory) = 0) then
        begin
          Result := false;
          Exit;
        end;
    Result := GetRecordFieldInfo(Field, SwapTableName, SwapFieldName, SwapKeyValues);
  end;

  procedure UpdateFieldStream(Field: TField);
  var
    Index: Integer;
    Stream: TFIBFieldStream;
  begin
    Index := FieldStreamIndex(Field);
    if Index < 0 then
      Exit;
    Stream := Streams^[Index];
    if Stream = nil then
      Exit;
    case Operation of
      ufsPost:
        begin
          if (Stream is TFIBBlobStream) and FillSwapInfo(Field) then
            with TFIBBlobStream(Stream) do
              begin
                TableName := AnsiString(SwapTableName);
                FieldName := AnsiString(SwapFieldName);
                RecordKeyValues := SwapKeyValues;
              end;
          FWritingBlob := Field;
          try
            Stream.DoFinalize(ClearModified and (Stream.BlobID.gds_quad_high <> 0), ForceWrite, CallBackBlobWrite);
          finally
            FWritingBlob := nil;
          end;
        end;
      ufsCancel: Stream.Cancel;
      ufsClearOldValue: Stream.FreeOldBuffer;
    end;
    with PRecordData(Buff)^.rdFields[Field.FieldNo] do
      begin
        fdIsNull := Stream.Size = 0;
        if fdIsNull and (Stream.BlobID.gds_quad_high = 0) then
          Stream.BlobID := NullQUID;
      end;
    PISC_QUAD(PAnsiChar(Buff) + vFieldDescrList[Field.FieldNo - 1].fdDataOfs)^:= Stream.BlobID;
  end;

begin
  if not Assigned(Buff) or (StreamFieldCount = 0) then
    Exit;
  Streams := PFIBFieldStreamArray(PAnsiChar(Buff) + FStreamsBufferOffset);
  if Field = nil then
    for i := 0 to FieldCount - 1 do
      UpdateFieldStream(Fields[i])
  else
    UpdateFieldStream(Field);
end;

procedure TFIBCustomDataSet.InternalPostRecord(Qry: TFIBQuery; Buff: Pointer);
begin
  // abstract
end;

{$WARNINGS OFF}

function TFIBCustomDataSet.InternalRefreshRow(Qry: TFIBQuery; Buff: TRecordBuffer): Boolean;
var
  iCurScreenState: Integer;
begin
  Include(FRunState, drsInRefreshRow);
  ChangeScreenCursor(iCurScreenState);
  Result := false;
  try
    if Buff = nil then
      Exit;
    if not EmptyStrings(Qry.SQL) and (Active) then
      begin
        if not FCachedUpdates and (CacheModelOptions.CacheModelKind = cmkStandard) then
          SaveOldBuffer(Buff);
        if not(Qry.Open or Qry.ProcExecuted) then
          begin
            SetQueryParams(Qry, Buff);
            PrepareQuery(skRefresh);
            if Qry.OnlySrvParams.Count > 0 then
              SetQueryParams(Qry, Buff); // for params in macro
            if (poStartTransaction in Options) and not Qry.Transaction.InTransaction then
              Qry.Transaction.StartTransaction;
            Qry.ExecQuery;
            // raise Exception.Create('Error Message');
          end;
        if Qry.Open or Qry.ProcExecuted then
          with PRecordData(Buff)^ do
            try
              if (Qry.SQLType = SQLExecProcedure) or (Qry.Next <> nil) then
                begin
                  FetchCurrentRecordToBuffer(Qry, PRecordData(Buff)^.rdRecordNumber, Buff);
                  Result := True;
                end
              else if poRefreshDeletedRecord in Options then
                begin
                  if (CacheModelOptions.CacheModelKind = cmkStandard) then
                    begin
                      Inc(vLockResync);
                      try
                        CacheDelete;
                      finally
                        Dec(vLockResync);
                      end;
                      DoAfterRefresh;
                    end;
                end;
            finally
              Qry.Close;
            end;
        UpdateFieldStreams(Buff, ufsCheckIsNull, false, false);
        // UpdateFieldStreams(Buff,ufsRefresh,False,False);
      end
    else if RecordCount > 0 then
      FIBError(feCannotRefresh, [CmpFullName(Self)]);
  finally
    Exclude(FRunState, drsInRefreshRow);
    RestoreScreenCursor(iCurScreenState);
  end;
end;

// {$WARNINGS ON}

procedure TFIBCustomDataSet.InternalRevertRecord(RecordNumber: Integer; WithUnInserted: Boolean);
var
  pRecBuff: TRecordBuffer;
begin
  pRecBuff := FRecordsCache.pRecBuff(RecordNumber + 1);
  case TCachedUpdateStatus(PSavedRecordData(pRecBuff)^.rdFlags and 7) of
    cusInserted:
      begin
        TCachedUpdateStatus(PSavedRecordData(pRecBuff)^.rdFlags) := cusUninserted;
        Inc(FDeletedRecords);
      end;
    cusDeleted:
      begin
        TCachedUpdateStatus(PSavedRecordData(pRecBuff)^.rdFlags) := cusUnmodified;
        Dec(FDeletedRecords);
      end;
    cusUninserted:
      if WithUnInserted then
        begin
          TCachedUpdateStatus(PSavedRecordData(pRecBuff)^.rdFlags) := cusInserted;
          Dec(FDeletedRecords);
          Inc(FCountUpdatesPending, 2);
        end;
    cusModified: FRecordsCache.RevertRecord(RecordNumber + 1);
  end;
end;

(*
  A visible record is one that is not truly deleted, and it is also
  listed in the FUpdateRecordTypes set.
*)

function TFIBCustomDataSet.IsVisibleStat(Buffer: TRecordBuffer): Boolean;
begin
  Result := (TCachedUpdateStatus(PRecordData(Buffer)^.rdFlags and 7) in FUpdateRecordTypes) or
    (FCacheModelOptions.CacheModelKind = cmkLimitedBufferSize) or
    (drsInApplyUpdates in FRunState) or (drsInSort in FRunState);
end;

function TFIBCustomDataSet.IsVisible(Buffer: TRecordBuffer): Boolean;
begin
  Result := IsVisibleStat(Buffer)
end;

function LocateOptionsToExtLocateOptions(LocateOptions: TLocateOptions): TExtLocateOptions;
begin
  Result := [];
  if loCaseInsensitive in LocateOptions then
    Include(Result, eloCaseInsensitive);
  if loPartialKey in LocateOptions then
    Include(Result, eloPartialKey);
end;

procedure CastVariantToArray(const KeyValues: Variant; var VarArray: TDynArray);
begin
  if VarIsArray(KeyValues) then
    VarArray := KeyValues
  else
    begin
      SetLength(VarArray, 1);
      VarArray[0] := KeyValues;
    end;
end;

function TFIBCustomDataSet.Locate(const KeyFields: string; const KeyValues: Variant; Options: TLocateOptions): Boolean;
var
  eOptions: TExtLocateOptions;
  VarArray: TDynArray;
begin
  CheckActive;
  eOptions := LocateOptionsToExtLocateOptions(Options);
  CastVariantToArray(KeyValues, VarArray);
  case FCacheModelOptions.CacheModelKind of
    cmkStandard: Result := InternalLocate(KeyFields, VarArray, eOptions, True, lkStandard, True);
    else
      Result := InternalLocateForLimCache(KeyFields, VarArray, eOptions);
  end;
end;

function TFIBCustomDataSet.LocateNext(const KeyFields: string; const KeyValues: Variant; Options: TLocateOptions): Boolean;
var
  eOptions: TExtLocateOptions;
begin
  eOptions := LocateOptionsToExtLocateOptions(Options);
  Result := InternalExtLocate(KeyFields, KeyValues, eOptions, lkNext);
end;

function TFIBCustomDataSet.LocatePrior(const KeyFields: string; const KeyValues: Variant; Options: TLocateOptions): Boolean;
// Sister function to Locate
var
  eOptions: TExtLocateOptions;
begin
  eOptions := LocateOptionsToExtLocateOptions(Options);
  Result := InternalExtLocate(KeyFields, KeyValues, eOptions, lkPrior);
end;

function TFIBCustomDataSet.InternalExtLocate(const KeyFields: string;
  const KeyValues: Variant; Options: TExtLocateOptions;
  LocateKind: TLocateKind): Boolean;
var
  VarArray: TDynArray;
  ForceInFetchedFlag: Boolean;

  function EndOfCache: Boolean;
  begin
    case LocateKind of
      lkNext: Result := Eof;
      lkPrior: Result := Bof;
      else
        Result := True;
    end;
  end;

begin
  Result := EndOfCache;
  if Result then
    begin
      Result := false;
      Exit;
    end;

  CastVariantToArray(KeyValues, VarArray);
  ForceInFetchedFlag := (FCacheModelOptions.CacheModelKind = cmkLimitedBufferSize) and
    not(eloInFetchedRecords in Options);
  if ForceInFetchedFlag then
    Include(Options, eloInFetchedRecords);
  Result := InternalLocate(KeyFields, VarArray, Options, false, LocateKind);
  if not Result and (FCacheModelOptions.FCacheModelKind = cmkLimitedBufferSize) and ForceInFetchedFlag then
    Result := InternalLocateForLimCache(KeyFields, VarArray, Options, LocateKind);
end;

function TFIBCustomDataSet.ExtLocateNext(const KeyFields: string; const KeyValues: Variant; Options: TExtLocateOptions): Boolean;
begin
  Result := InternalExtLocate(KeyFields, KeyValues, Options, lkNext);
end;

function TFIBCustomDataSet.ExtLocatePrior(const KeyFields: string; const KeyValues: Variant; Options: TExtLocateOptions): Boolean;
// Sister function to ExtLocate
begin
  Result := InternalExtLocate(KeyFields, KeyValues, Options, lkPrior);
end;

procedure TFIBCustomDataSet.RefreshFilters;
var
  OldRecno: Integer;
begin
  if csDestroying in ComponentState then
    Exit;
  if Active then
    begin
      CheckBrowseMode;
      if IsEmpty then
        OldRecno := -1
      else
        OldRecno := GetRealRecNo;
      RefreshClientFields(false);
      if GetRealRecNo <> OldRecno then
        First
    end
end;

procedure TFIBCustomDataSet.ChangeScreenCursor(var OldCursor: Integer);
begin
{$IFNDEF NO_GUI}
{$IFDEF D_XE2}
  if Assigned(Database) and Assigned(Database.DoChangeScreenCursor) then
    Database.DoChangeScreenCursor(FSQLScreenCursor, OldCursor)
{$ELSE}
  OldCursor := Screen.Cursor;
  if (FSQLScreenCursor <> crDefault) and (FSQLScreenCursor <> OldCursor) then
    Screen.Cursor := FSQLScreenCursor;
{$ENDIF}
{$ENDIF}
end;

procedure TFIBCustomDataSet.RestoreScreenCursor(const OldCursor: Integer);
{$IFDEF D_XE2}
var
  Dummy: Integer;
{$ENDIF}
begin
{$IFNDEF NO_GUI}
{$IFDEF D_XE2}
  if Assigned(Database) and Assigned(Database.DoChangeScreenCursor) then
    Database.DoChangeScreenCursor(OldCursor, Dummy)
{$ELSE}
  if (FSQLScreenCursor <> crDefault) and (FSQLScreenCursor <> OldCursor) then
    Screen.Cursor := OldCursor;
{$ENDIF}
{$ENDIF}
end;

procedure TFIBCustomDataSet.Prepare;
var
  iCurScreenState: Integer;
begin
  ChangeScreenCursor(iCurScreenState);
  try
    FBase.CheckDatabase;
    StartTransaction;
    FBase.CheckTransaction;
    if not EmptyStrings(FQSelect.SQL) then
      begin
        if not FQSelect.Open then
          FQSelect.Prepare;
        if (csDesigning in ComponentState) or FIBHideGrantError then
          begin
            PrepareQuery(FIBDataSet.skModify);
            PrepareQuery(FIBDataSet.skInsert);
            PrepareQuery(FIBDataSet.skDelete);
            PrepareQuery(skRefresh);
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

procedure TFIBCustomDataSet.UnPrepare;
begin
  QSelect.FreeHandle;
  QDelete.FreeHandle;
  QInsert.FreeHandle;
  QUpdate.FreeHandle;
  QRefresh.FreeHandle;
  FPrepared := false
end;

procedure TFIBCustomDataSet.RecordModified(Value: Boolean);
begin
  SetModified(Value);
end;

procedure TFIBCustomDataSet.RevertRecord;
var
  Buff: TRecordBuffer;
begin
  CheckDatasetOpen(' revert record ');
  if FCachedUpdates then
    begin
      Buff := GetActiveBuf;
      InternalRevertRecord(PRecordData(Buff)^.rdRecordNumber, True);
      ReadRecordCache(PRecordData(Buff)^.rdRecordNumber, Buff, false);
      if IsVisible(Buff) then
        DataEvent(deRecordChange, 0)
      else
        begin
          SetCurrentRecord(ActiveRecord);
          Resync([]);
        end;
      Dec(FCountUpdatesPending);
      FUpdatesPending := FCountUpdatesPending > 0
    end;
end;

procedure TFIBCustomDataSet.SaveOldBuffer(Buffer: TRecordBuffer);
var
  R: Integer;
begin
  if Assigned(Buffer) then
    begin
      case FCacheModelOptions.CacheModelKind of
        cmkStandard:
          begin
            FRecordsCache.SaveOldBuffer(PRecordData(Buffer)^.rdRecordNumber + 1);
            if FCachedUpdates then
              FRecordsCache.SaveToChangeLog(PRecordData(Buffer)^.rdRecordNumber + 1);
          end;
        cmkLimitedBufferSize:
          begin
            R := (PRecordData(Buffer)^.rdRecordNumber + 1) mod FCacheModelOptions.FBufferChunks;
            if R = 0 then
              R := FCacheModelOptions.FBufferChunks;
            FRecordsCache.SaveOldBuffer(R);
          end;

      end;
    end;
end;

procedure TFIBCustomDataSet.SetDatabase(Value: TFIBDatabase);
begin
  // Check that the dataset is closed
  CheckDatasetClosed(' change database ');
  // Unset the database property of all owned components
  LiveChangeDatabase(Value)
end;

procedure TFIBCustomDataSet.LiveChangeDatabase(Value: TFIBDatabase);
// internal use
begin
  FQDelete.Database := Value;
  FQInsert.Database := Value;
  FQRefresh.Database := Value;
  FQSelect.Database := Value;
  FQUpdate.Database := Value;

  if FBase.Database <> Value then
    begin
      FBase.Database := Value;
      if Assigned(Value) and Assigned(Value.DefaultUpdateTransaction) then
        begin
          if not(Assigned(UpdateTransaction) and (UpdateTransaction <> Transaction))
            and not CmpInLoadedState(Self) and not CmpInLoadedState(Value) then
            UpdateTransaction := Value.DefaultUpdateTransaction
        end;
    end;
end;

procedure TFIBCustomDataSet.SetDeleteSQL(Value: TStrings);
begin
  FQDelete.SQL.Assign(Value);
end;

procedure TFIBCustomDataSet.SetInsertSQL(Value: TStrings);
begin
  FQInsert.SQL.Assign(Value);
end;

{$WARNINGS OFF}

type
  TFriendSQLVAR = class(TFIBXSQLVAR);

procedure TFIBCustomDataSet.SetQueryParams(Qry: TFIBQuery; Buffer: Pointer);
var
  L, i, j, pc, pc1: Integer;
  cr, Data: PAnsiChar;
  FN: string;
  st: AnsiString;
  OldBuffer: Pointer;
  fi: PFIBFieldDescr;
  tf: TField;
  cur_param: TFIBXSQLVAR;
  Source_Param: TFIBXSQLVAR;
begin
  if (Buffer = nil) then
    FIBError(feBufferNotSet, [CmpFullName(Self)]);
  with PRecordData(Buffer)^ do
    begin
      if rdRecordNumber < 0 then
        Exit;
      if (State = dsInsert) then
        OldBuffer := Buffer
      else
        case FCacheModelOptions.FCacheModelKind of
          cmkStandard:
            begin
              if UniDirectional then
                OldBuffer := FRecordsCache.OldBuffer
                  ((rdRecordNumber mod FCacheModelOptions.FBufferChunks) + 1) - DiffSizesRecData
              else
                OldBuffer := FRecordsCache.OldBuffer(rdRecordNumber + 1) - DiffSizesRecData
            end
          else
            OldBuffer := FRecordsCache.OldBuffer
              ((rdRecordNumber mod FCacheModelOptions.FBufferChunks) + 1) - DiffSizesRecData;
        end;

      pc := Qry.Params.Count;
      pc1 := pc + Qry.OnlySrvParams.Count;
      i := 0;
      while i < pc1 do
        begin
          if i < pc then
            cur_param := Qry.Params[i]
          else
            cur_param := Qry.FindParam(Qry.OnlySrvParams[i - pc]);
          Inc(i);
          if cur_param = nil then
            Continue;
          FN := cur_param.Name;
          if IsOldParamName(FN) then
            begin
              FN := FastCopy(FN, 5, MaxInt);
              cr := OldBuffer;
            end
          else if IsNewParamName(FN) then
            begin
              FN := FastCopy(FN, 5, MaxInt);
              cr := Buffer;
            end
          else if IsMasParamName(FN) and (DataSource <> nil) and (DataSource.DataSet <> nil) then
            begin
              FN := FastCopy(FN, 5, MaxInt);
              tf := DataSource.DataSet.FindField(FN);
              if tf <> nil then
                begin
                  cur_param.Value := tf.Value;
                end;
              Continue;
            end
          else
            cr := Buffer;

          tf := Self.FN(FN);
          if Assigned(tf) and (tf.FieldKind = fkData) then
            j := tf.FieldNo
          else
            j := FQSelect.FieldIndex[FN] + 1;

          if (Qry <> FQSelect) then
            begin
              if j = 0 then
                begin
                  // if field 'fn' don't exist
                  Source_Param := Params.ByName[FN];
                  if Source_Param <> nil then
                    cur_param.Assign(Source_Param)
                end
              else if (Qry = FQRefresh) and (DataSource <> nil) then
                begin
                  Source_Param := Params.ByName[cur_param.Name];
                  if (Source_Param <> nil) then
                    begin
                      cur_param.Assign(Source_Param);
                      Continue
                    end;
                end;
            end;

          if (j > 0) then
            with PRecordData(cr)^ do
              if rdFields[j].fdIsNull then
                cur_param.IsNull := True
              else
                begin
                  fi := vFieldDescrList[j - 1];

                  if cur_param.IsNull then
                    cur_param.IsNull := false;

                  Data := cr + fi^.fdDataOfs;
                  case fi^.fdDataType of
                    SQL_TEXT, SQL_VARYING:
                      begin
                        if fi^.fdIsDBKey then
                          begin
                            SetString(st, Data, fi^.fdDataSize);
                            cur_param.Data^.SQLType := SQL_TEXT or (cur_param.Data^.SQLType and 1);
                            cur_param.Data^.sqllen := fi^.fdDataSize;
                            FIBAlloc(cur_param.Data^.sqldata, 0, fi^.fdDataSize + 1);
                            Move(st[1], cur_param.Data^.sqldata^, fi^.fdDataSize);
                          end
                        else
                          case fi^.fdAddedFields of
                            atfGuidField: cur_param.AsGuid := PGuid(Data)^;
                            else
                              if fi^.fdIsSeparateString then
                                begin
                                  L := PInteger(Data)^;
                                  Inc(Data, SizeOf(Integer));
                                end
                              else
                                L := Q_StrLen(Data);

                              if L > fi^.fdDataSize then
                                L := fi^.fdDataSize;
                              SetString(st, Data, L);
                              { if L=0 then
                        TFriendSQLVAR(cur_param).SetValue(SQL_TEXT,L, tspValue,'')
                        else
                        TFriendSQLVAR(cur_param).SetValue(SQL_TEXT,L, tspValue,st[1]); }

                              if L = 0 then
                                TFriendSQLVAR(cur_param).SetAsStrData(L, '')
                              else
                                TFriendSQLVAR(cur_param).SetAsStrData(L, st[1]);
                          end;
                      end;
                    SQL_FLOAT: cur_param.AsDouble := PSingle(Data)^;
                    SQL_DOUBLE, SQL_D_FLOAT: cur_param.AsDouble := PDouble(Data)^;
                    SQL_SHORT:
                      if fi^.fdDataScale < 0 then
                        cur_param.AsDouble := PShort(Data)^ * E10[fi^.fdDataScale]
                      else
                        cur_param.AsLong := PShort(Data)^;
                    SQL_LONG:
                      if fi^.fdDataScale < 0 then
                        cur_param.AsDouble := PLong(Data)^ * E10[fi^.fdDataScale]
                      else
                        cur_param.AsLong := PLong(Data)^;
                    SQL_INT64:
                      begin
                        if (fi^.fdDataScale >= -4) or (psSQLINT64ToBCD in PrepareOptions) then
                          begin
                            cur_param.AsInt64 := PInt64(Data)^;
                            cur_param.Scale := fi^.fdDataScale;
                          end
                        else
                          cur_param.AsDouble := PDouble(Data)^;
                      end;
                    SQL_BLOB, SQL_ARRAY, SQL_QUAD:
                      begin
                        if tf <> nil then
                          UpdateFieldStreams(Buffer, ufsPost, false, false, tf);
                        cur_param.AsQuad := PISC_QUAD(Data)^;
                      end;
                    SQL_TYPE_DATE:
                      begin
                        cur_param.AsTimeStamp := StdFuncs.TimeStamp(PInt(Data)^, 0);
                      end;
                    SQL_TYPE_TIME:
                      begin
                        cur_param.AsTimeStamp := StdFuncs.TimeStamp(0, PInt(Data)^);
                      end;
                    SQL_TIMESTAMP: cur_param.AsTimeStamp := MSecsToTimeStamp(PDouble(Data)^);
                    IB_SQL_BOOLEAN, SQL_BOOLEAN: cur_param.AsBoolean := (PByte(Data)^ <> ISC_FALSE);
                    SQL_INT128: cur_param.SetAsInt128(PFB_I128(Data)^, fi^.fdDataScale);
                    SQL_DEC16: cur_param.SetAsDec16(PFB_DEC16(Data)^);
                    SQL_DEC34: cur_param.SetAsDec34(PFB_DEC34(Data)^);
                    SQL_TIME_TZ_EX, SQL_TIMESTAMP_TZ_EX: CacheToTimeZoneParam(cur_param, fi, Data);
                  end;
                end;
        end;
    end;
end;

// {$WARNINGS ON}

procedure TFIBCustomDataSet.SetRefreshSQL(Value: TStrings);
begin
  FQRefresh.SQL.Assign(Value);
end;

procedure TFIBCustomDataSet.SetSelectSQL(Value: TStrings);
begin
  if not(csDesigning in ComponentState) then
    CheckDatasetClosed(' change SelectSQL ')
  else
    Close;
  FQSelect.SQL.Assign(Value);
end;

procedure TFIBCustomDataSet.SetUpdateSQL(Value: TStrings);
begin
  FQUpdate.SQL.Assign(Value);
end;

procedure TFIBCustomDataSet.SetTransaction(Value: TFIBTransaction);
begin
  CheckDatasetClosed(' change transaction ');
  LiveChangeTransaction(Value)
end;

procedure TFIBCustomDataSet.LiveChangeTransaction(Value: TFIBTransaction);
// internal use
var
  vOnlyRead: Boolean;
begin
  FBase.Transaction := Value;
  vOnlyRead := FQSelect.Transaction <> FQDelete.Transaction;
  if Assigned(FQSelect.Transaction) then
    with FQSelect.Transaction do
      begin
        RemoveEvent(DoBeforeStartTransaction, tetBeforeStartTransaction);
        RemoveEvent(DoAfterStartTransaction, tetAfterStartTransaction);
        RemoveEndEvent(DoBeforeEndTransaction, tetBeforeEndTransaction);
        RemoveEndEvent(DoAfterEndTransaction, tetAfterEndTransaction);

        RemoveEvent(DoBeforeStartUpdateTransaction, tetBeforeStartTransaction);
        RemoveEvent(DoAfterStartUpdateTransaction, tetAfterStartTransaction);
        RemoveEndEvent(DoBeforeEndUpdateTransaction, tetBeforeEndTransaction);
        RemoveEndEvent(DoAfterEndUpdateTransaction, tetAfterEndTransaction);
      end;

  FQSelect.Transaction := Value;
  if Assigned(Value) then
    begin
      Value.AddEvent(DoBeforeStartTransaction, tetBeforeStartTransaction);
      Value.AddEvent(DoAfterStartTransaction, tetAfterStartTransaction);

      Value.AddEndEvent(DoBeforeEndTransaction, tetBeforeEndTransaction);
      Value.AddEndEvent(DoAfterEndTransaction, tetAfterEndTransaction);
    end;
  if not vOnlyRead then
    begin
      FQRefresh.Transaction := Value;
      FQDelete.Transaction := Value;
      FQInsert.Transaction := Value;
      FQUpdate.Transaction := Value;
      if Assigned(Value) then
        begin
          Value.AddEvent(DoBeforeStartUpdateTransaction, tetBeforeStartTransaction);
          Value.AddEvent(DoAfterStartUpdateTransaction, tetAfterStartTransaction);
          Value.AddEndEvent(DoBeforeEndUpdateTransaction, tetBeforeEndTransaction);
          Value.AddEndEvent(DoAfterEndUpdateTransaction, tetAfterEndTransaction);
        end
    end
  else if FRefreshTransactionKind = tkReadTransaction then
    FQRefresh.Transaction := Value;

end;

procedure TFIBCustomDataSet.SetUpdateRecordTypes(Value: TFIBUpdateRecordTypes);
begin
  FUpdateRecordTypes := Value;
  if Active then
    First;
end;

procedure TFIBCustomDataSet.SetUniDirectional(Value: Boolean);
begin
  CheckDatasetClosed(' change Unidirectional property ');
  // inherited SetUniDirectional(Value);
  FUniDirectional := Value;
end;

function TFIBCustomDataSet.GetWaitEndMasterScroll: Boolean;
begin
  if Assigned(vTimerForDetail) then
    Result := vTimerForDetail.Interval > 0
  else
    Result := false;
end;

procedure TFIBCustomDataSet.SetWaitEndMasterScroll(Value: Boolean);
begin
  if Value then
    begin
      CreateDetailTimer;
      vTimerForDetail.Interval := WaitEndMasterInterval;
      Include(FDetailConditions, dcWaitEndMasterScroll);
    end
  else
    begin
      ForceEndWaitMaster;
      if Assigned(vTimerForDetail) then
        begin
          vTimerForDetail.Free;
          vTimerForDetail := nil;
        end;
      Exclude(FDetailConditions, dcWaitEndMasterScroll);
    end;
end;

function TFIBCustomDataSet.GetDetailConditions: TDetailConditions;
begin
  if Assigned(vTimerForDetail) and (vTimerForDetail.Interval > 0) then
    Include(FDetailConditions, dcWaitEndMasterScroll)
  else
    Exclude(FDetailConditions, dcWaitEndMasterScroll);
  Result := FDetailConditions;
end;

procedure TFIBCustomDataSet.SetDetailConditions(Value: TDetailConditions);
begin
  FDetailConditions := Value;
  if dcWaitEndMasterScroll in FDetailConditions then
    begin
      CreateDetailTimer;
      vTimerForDetail.Interval := WaitEndMasterInterval
    end
  else if Assigned(vTimerForDetail) then
    begin
      vTimerForDetail.Free;
      vTimerForDetail := nil;
    end;
end;

procedure TFIBCustomDataSet.StartTransaction;
begin
  if Database = nil then
    if Transaction <> nil then
      Database := Transaction.DefaultDatabase;
  if Transaction = nil then
    if Database <> nil then
      Transaction := Database.DefaultTransaction;
  if (Transaction <> nil) and not Transaction.Active then
    begin
      if Transaction.DatabaseCount = 0 then
        Transaction.DefaultDatabase := Database;
      if poStartTransaction in Options then
        Transaction.StartTransaction;
    end;
end;

procedure TFIBCustomDataSet.CloseOpen(const DoFetchAll: Boolean);
var
  iCurScreenState: Integer;
  OldDefaultFields: Boolean;
begin
  ChangeScreenCursor(iCurScreenState);
  try
    if Active then
      begin
        // Keep automatic fields alive across the reopen
        OldDefaultFields := DefaultFields;
        if OldDefaultFields then
          SetDefaultFields(false);
        try
          Close;
          Open;
        finally
          if OldDefaultFields then
            begin
              SetDefaultFields(True);
              // Reopen failed: drop the automatic fields left over from the previous cursor
              if not Active then
                DestroyFields;
            end;
        end;
      end
    else
      Open;
    if DoFetchAll then
      FetchAll;
  finally
    RestoreScreenCursor(iCurScreenState);
  end;
end;

procedure TFIBCustomDataSet.OpenByTimer(Sender: TObject);
begin
  Include(FRunState, drsInOpenByTimer);
  try
    DoCloseOpen(Sender);
  finally
    Exclude(FRunState, drsInOpenByTimer);
  end
end;

procedure TFIBCustomDataSet.DoCloseOpen(Sender: TObject);
begin
  if Assigned(vTimerForDetail) then
    vTimerForDetail.Enabled := false;
  DisableControls;
  try
    if not EmptyStrings(SelectSQL) then
      begin
        if (Active or (dcForceOpen in FDetailConditions)) then
          CloseOpen(false)
      end;
  finally
    EnableControls;
    DataEvent(deDataSetScroll, 0);
  end;
end;

procedure TFIBCustomDataSet.SetPrepareOptions(Value: TpPrepareOptions);
begin
  if not(csReading in ComponentState) and (((psUseBooleanField in Value - FPrepareOptions) or (psUseBooleanField
    in FPrepareOptions - Value)) or ((psSQLINT64ToBCD in Value - FPrepareOptions) or (psSQLINT64ToBCD
    in FPrepareOptions - Value))) or ((psUseLargeIntField in Value - FPrepareOptions) or
    (psUseLargeIntField in FPrepareOptions - Value)) then
    begin
      CheckDatasetClosed
      ('change psUseBooleanField or psSQLINT64ToBCD or psUseLargeIntField' + CLRF);
      if Prepared then
        begin
          FPrepareOptions := Value;
          FieldDefs.Clear;
          FieldDefs.Update;
          Exit;
        end;
    end;
  FPrepareOptions := Value;
end;

procedure TFIBCustomDataSet.SetRefreshTransactionKind(const Value: TTransactionKind);
begin
  case Value of
    tkReadTransaction: QRefresh.Transaction := Transaction;
    tkUpdateTransaction: QRefresh.Transaction := UpdateTransaction;
  end;
  FRefreshTransactionKind := Value;
end;

procedure TFIBCustomDataSet.SourceChanged;
var
  IsFirstEndWait: Boolean;
begin
  if FMasSourceDisableCount > 0 then
    Exit;
  IsFirstEndWait := (DataSource = nil) or (DataSource.DataSet = nil) or not(DataSource.DataSet is TFIBCustomDataSet) or
    not(drsInOpenByTimer in TFIBCustomDataSet(DataSource.DataSet).FRunState);
  if Assigned(vTimerForDetail) and (vTimerForDetail.Interval > 0) then
    begin
      if IsFirstEndWait then
        begin
          vTimerForDetail.Enabled := false;
          vTimerForDetail.Interval := WaitEndMasterInterval;
          vTimerForDetail.Enabled := True;
        end
      else
        try
          Include(FRunState, drsInOpenByTimer);
          DoCloseOpen(nil);
        finally
          Exclude(FRunState, drsInOpenByTimer);
        end;
    end
  else
    DoCloseOpen(nil)
end;

procedure TFIBCustomDataSet.SourceDisabled;
begin
  if not(dcIgnoreMasterClose in DetailConditions) and Active then
    try
      Close;
    except
      if DataSource.DataSet is TFIBCustomDataSet then
        TFIBCustomDataSet(DataSource.DataSet).CloseCursor;
      raise;
    end;
end;

{ MasterDetails Routines }
procedure TFIBCustomDataSet.DisableMasterSource;
begin
  Inc(FMasSourceDisableCount)
end;

procedure TFIBCustomDataSet.EnableMasterSource;
begin
  Dec(FMasSourceDisableCount)
end;

function TFIBCustomDataSet.MasterSourceDisabled: Boolean;
begin
  Result := FMasSourceDisableCount > 0
end;

procedure TFIBCustomDataSet.SQLChanging(Sender: TObject);
begin
  FAutoUpdateOptions.WhereCondition := '';
  FAutoUpdateOptions.ReadySelectSQL := '';
  if (Sender = QSelect) then
    begin
      FAutoUpdateOptions.UpdateTableName := FAutoUpdateOptions.UpdateTableName;
      if Assigned(FParams) then
        begin
          FreeAndNil(FParams);
        end;

      vSelectSQLTextChanged := True;
      if not(csDesigning in ComponentState) then
        CheckDatasetClosed(' change SelectSQL ')
      else
        Close;
      FieldDefs.Clear;
      FPrepared := false;
    end;
end;

(*
  * I can "undelete" uninserted records (make them "inserted" again).
  * I can "undelete" cached deleted (the deletion hasn't yet occurred).
*)
procedure TFIBCustomDataSet.Undelete;
var
  Buff: PRecordData;
begin
  CheckDatasetOpen(' undelete ');
  Buff := PRecordData(GetActiveBuf);
  with Buff^ do
    begin
      if TCachedUpdateStatus(rdFlags) = cusUninserted then
        begin
          TCachedUpdateStatus(rdFlags) := cusInserted;
          Inc(FCountUpdatesPending);
        end
      else if TCachedUpdateStatus(rdFlags) = cusDeleted then
        begin
          TCachedUpdateStatus(rdFlags) := cusUnmodified;
          Dec(FCountUpdatesPending);
        end;
      Dec(FDeletedRecords);

      WriteRecordCache(rdRecordNumber, TRecordBuffer(Buff));
    end;
end;

function TFIBCustomDataSet.UpdateStatus: TUpdateStatus;
var
  CurBuff: PRecordData;
begin
  Result := usUnmodified;
  if not Active then
    Exit;
  CurBuff := PRecordData(GetActiveBuf);
  if CurBuff <> nil then
    with CurBuff^ do
      if (rdFlags and 7) <> Byte(cusUninserted) then
        Result := TUpdateStatus(rdFlags and 7)
      else
        Result := usDeleted;
end;

function TFIBCustomDataSet.IsSequenced: Boolean;
begin
  Result := Assigned(FQSelect) and FQSelect.Eof and (not Filtered or (FRecordCount = 0)) and not UniDirectional;
end;

function TFIBCustomDataSet.IsValidBuffer(FCache: PAnsiChar): Boolean;
begin
  Result := (PRecordData(FCache)^.rdRecordNumber < FRecordCount) and (PRecordData(FCache)^.rdRecordNumber > -1)
end;

procedure TFIBCustomDataSet.ReadRecordCache(RecordNumber: Integer; Buffer: TRecordBuffer; ReadOldBuffer: Boolean; Shift: Integer = 0);
var
  OldBuf: TRecordBuffer;
  PrRecordNumber: Integer;
begin
  PrRecordNumber := RecordNumber + Shift;
  if FUniDirectional or (FCacheModelOptions.CacheModelKind = cmkLimitedBufferSize) then
    RecordNumber := RecordNumber mod FCacheModelOptions.FBufferChunks;
  if RecordNumber >= 0 then
    begin
      PInteger(Buffer)^ := PrRecordNumber;
      // FillChar(Buffer[SizeOf(Integer)],FRecordBufferSize-SizeOf(Integer),0);
      if FCalcFieldsOffset <> FRecordBufferSize then
        FillChar(Buffer[FCalcFieldsOffset], FRecordBufferSize - FCalcFieldsOffset, 0);
      if ReadOldBuffer then
        begin
          OldBuf := FRecordsCache.OldBuffer(RecordNumber + 1);
          Move(OldBuf[0], Buffer[DiffSizesRecData], FRecordBufferSize - DiffSizesRecData);
        end
      else
        begin
          Inc(Buffer, DiffSizesRecData);
          FRecordsCache.ReadRecordBuffer(RecordNumber + 1, Buffer, false);
        end;
    end;
end;

procedure TFIBCustomDataSet.WriteRecordCache(RecordNumber: Integer; Buffer: TRecordBuffer);
begin
  if RecordNumber >= 0 then
    begin
      if FUniDirectional or (FCacheModelOptions.CacheModelKind = cmkLimitedBufferSize) then
        RecordNumber := RecordNumber mod FCacheModelOptions.FBufferChunks;
      Buffer := Buffer + DiffSizesRecData;
      FRecordsCache.WriteRecord(RecordNumber + 1, Buffer, True);
    end;
end;

//
function TFIBCustomDataSet.GetNewBuffer: TRecordBuffer;
begin
  Result := GetActiveBuf;
end;

function TFIBCustomDataSet.GetOldBuffer(aRecordNo: Integer = -1): TRecordBuffer;
var
  buf: TRecordBuffer;
  RecordNo: Integer;
begin
  if aRecordNo = -1 then
    begin
      Result := GetActiveBuf;
      if Result = nil then
        Exit;
      RecordNo := PRecordData(Result)^.rdRecordNumber;
    end
  else
    RecordNo := aRecordNo;
  Result := AllocRecordBuffer;
  PInteger(Result)^ := RecordNo;
  // Move(RecordNo,Result[0],SizeOf(Integer));
  case FCacheModelOptions.FCacheModelKind of
    cmkStandard: buf := FRecordsCache.OldBuffer(RecordNo + 1);
    cmkLimitedBufferSize:
      buf := FRecordsCache.OldBuffer
        ((RecordNo mod FCacheModelOptions.FBufferChunks) + 1);
    else
      Exit;
  end;
  Move(buf[0], Result[DiffSizesRecData], FRecordBufferSize - DiffSizesRecData);
end;

//

function TFIBCustomDataSet.SortInfoIsValid: Boolean;
var
  i, sfc: Integer;
begin
  if VarIsNull(FSortFields) then
    Result := false
  else
    begin
      sfc := SortFieldsCount - 1;
      for i := 0 to sfc do
        if FN(FSortFields[i, 0]) = nil then
          begin
            Result := false;
            Exit;
          end;
      Result := True;
    end;
end;

function TFIBCustomDataSet.IsSortedField(Field: TField; var FieldSortOrder: TSortFieldInfo): Boolean;
var
  FN, tmpStr: string;
  L, i: Integer;
begin
  Result := not VarIsNull(FSortFields);
  if not Result then
    Exit;
  Result := false;
  FN := Field.FieldName;
  L := VarArrayHighBound(FSortFields, 1);
  for i := 0 to L do
    begin
      tmpStr := FSortFields[i, 0];
      Result := tmpStr = FN;
      if Result then
        begin
          FieldSortOrder.FieldName := tmpStr;
          FieldSortOrder.InDataSetIndex := Field.Index;
          FieldSortOrder.InOrderIndex := i + 1;
          FieldSortOrder.Asc := FSortFields[i, 1];
          FieldSortOrder.NullsFirst := FSortFields[i, 2];
          Exit;
        end;
    end;
end;

function TFIBCustomDataSet.SortFieldsCount: Integer;
begin
  Result := 0;
  if VarIsNull(FSortFields) then
    Exit;
  Result := VarArrayHighBound(FSortFields, 1) + 1;
end;

function TFIBCustomDataSet.IsSorted: Boolean;
begin
  Result := SortFieldsCount > 0
end;

function TFIBCustomDataSet.SortFieldInfo(OrderIndex: Integer): TSortFieldInfo;
begin
  if (OrderIndex < 1) or (OrderIndex > SortFieldsCount) then
    begin
      Result.FieldName := 'Unknown';
      Result.InOrderIndex := -1;
      Result.InDataSetIndex := -1;
      Result.Asc := True;
    end
  else
    begin
      Result.FieldName := FSortFields[OrderIndex - 1, 0];
      Result.InDataSetIndex := FBN(Result.FieldName).Index;
      Result.InOrderIndex := OrderIndex;
      Result.Asc := FSortFields[OrderIndex - 1, 1];
      Result.NullsFirst := FSortFields[OrderIndex - 1, 2];
    end;
end;

function TFIBCustomDataSet.SortedFields: string;
var
  i, L: Integer;
begin
  Result := '';
  if VarIsNull(FSortFields) then
    Exit;
  L := VarArrayHighBound(FSortFields, 1);
  for i := 0 to L do
    Result := Result + iifStr(i > 0, ';', '') + FSortFields[i, 0];
end;

function TFIBCustomDataSet.GetFieldOrigin(Fld: TField): string;
var
  TName: string;
  FName: string;
begin
  Result := '';
  if (Fld = nil) then
    Exit;
  if FFieldOriginRule = forNoRule then
    Exit;

  if not Active and (Fld.FieldNo = 0) then
    begin
      if not Prepared then
        Prepare;
      BindFields(True);
    end;
  case FFieldOriginRule of
    forTableAndFieldName:
      begin
        TName := GetRelationTableName(Fld);
        FName := GetRelationFieldName(Fld);
      end;
    forClientFieldName:
      begin
        TName := '';
        FName := Fld.FieldName
      end;
    forTableAliasAndFieldName:
      begin
        TName := TableAliasForField(Fld.FieldName);
        FName := GetRelationFieldName(Fld);
      end;
  end;

  if Length(TName) > 0 then
    Result := TName + '.' + FName
  else if Length(FName) > 0 then
    Result := FName
  else
    Result := ''
end;

function TFIBCustomDataSet.CreateCalcField(FieldClass: TFieldClass; const aName, aFieldName: string; aSize: Integer): TField;
begin
  Result := FieldClass.Create(Self);
  with Result do
    begin
      FieldKind := fkCalculated;
      Size := aSize;
      FieldName := aFieldName;
      Name := aName;
      if DefaultFields then
        Include(FRunState, drsForceCreateCalcFields);
      try
        DataSet := Self;
      except
        Exclude(FRunState, drsForceCreateCalcFields);
        raise
      end;
    end;
end;

function TFIBCustomDataSet.CreateLookUpField(FieldClass: TFieldClass;
  const aName, aFieldName: string; aSize: Integer; aLookupDataSet: TDataSet;
  const aKeyFields, aLookupKeyFields, aLookupResultField: string): TField;
begin
  Result := CreateCalcField(FieldClass, aName, aFieldName, aSize);
  with Result do
    begin
      FieldKind := fkLookup;
      LookupDataSet := aLookupDataSet;
      KeyFields := aKeyFields;
      LookupKeyFields := aLookupKeyFields;
      LookupResultField := aLookupResultField
    end;
end;

function TFIBCustomDataSet.IsComputedField(Fld: Variant): Boolean;
var
  Field: TObject;
  t: Integer;
  fi: TpFIBFieldInfo;
begin
  Result := false;
  Field := nil;
  t := VarType(Fld);
  case t of
    varInteger, varWord, varLongWord, varInt64: Field := Fields[Fld];
    varOleStr, varString{$IFDEF D2009+}, varUString{$ENDIF}:
      begin
        Field := FN(Fld);
        if Field = nil then
          Field := FieldDefs.Find(Fld);
      end;
  end;
  if (Field = nil) or ((Field is TField) and (TField(Field).FieldKind <> fkData)) then
    Exit;

  fi := ListTableInfo.GetFieldInfo(Database, GetRelationTableName(Field), GetRelationFieldName(Field), false);
  if fi = nil then
    Exit;
  Result := fi.IsComputed;
end;

function TFIBCustomDataSet.DomainForField(Fld: Variant): string;
var
  Field: TObject;
  t: Integer;
  fi: TpFIBFieldInfo;
begin
  Result := '';
  Field := nil;
  t := VarType(Fld);
  case t of
    varInteger, varWord, varLongWord, varInt64: Field := Fields[Fld];
    varOleStr, varString {$IFDEF D2009+}, varUString{$ENDIF}:
      begin
        Field := FN(Fld);
        if Field = nil then
          Field := FieldDefs.Find(Fld);
      end;

  end;
  if (Field = nil) or ((Field is TField) and (TField(Field).FieldKind <> fkData)) then
    Exit;

  fi := ListTableInfo.GetFieldInfo(Database, GetRelationTableName(Field), GetRelationFieldName(Field), false);
  if fi = nil then
    Exit;
  Result := fi.DomainName;
end;

function TFIBCustomDataSet.FieldByOrigin(const aOrigin: string): TField;
begin
  // First field only
  Result := FieldByOrigin(ExtractWord(1, aOrigin, ['.']), ExtractWord(2, aOrigin, ['.']));
end;

function TFIBCustomDataSet.FieldByOrigin(const TableName, FieldName: string): TField;
var
  i: Integer;
  vTableName: string;
  vFieldName: string;
begin
  if Assigned(Database) and ((Database.SQLDialect < 3) or Database.UpperOldNames) then
    begin
      if (Length(TableName) > 0) and (TableName[1] <> '"') then
        vTableName := FastUpperCase(TableName)
      else
        vTableName := TableName;
      if (Length(FieldName) > 0) and (FieldName[1] <> '"') then
        vFieldName := FastUpperCase(FieldName)
      else
        vFieldName := FieldName
    end
  else
    begin
      vTableName := TableName;
      vFieldName := FieldName;
    end;
  vTableName := CutQuote(vTableName);
  vFieldName := CutQuote(vFieldName);
  for i := 0 to Pred(FieldCount) do
    begin
      if (GetRelationTableName(Fields[i]) = vTableName) and (GetRelationFieldName(Fields[i]) = vFieldName) then
        begin
          Result := Fields[i];
          Exit
        end;
    end;
  Result := nil;
end;

function TFIBCustomDataSet.ReadySelectText: string;
begin
  if Length(FAutoUpdateOptions.ReadySelectSQL) = 0 then
    begin
      Result := FQSelect.ReadySQLText(false); // SetMacro
      FAutoUpdateOptions.ReadySelectSQL := Result;
    end
  else
    Result := FAutoUpdateOptions.ReadySelectSQL;
end;

function TFIBCustomDataSet.TableAliasForField(const aFieldName: string): string;
var
  fi: PFIBFieldDescr;
  tf: TField;
begin
  if QSelect.Prepared then
    Result := QSelect.TableAliasForFieldByName(aFieldName)
  else
    begin
      tf := FBN(aFieldName);
      if Assigned(tf) and (tf.FieldKind = fkData) and (vFieldDescrList.Capacity > tf.FieldNo) then
        begin
          fi := vFieldDescrList[tf.FieldNo - 1];
          Result := fi^.fdTableAlias
        end
      else
        Result := ''
    end
end;

function TFIBCustomDataSet.SQLFieldName(const aFieldName: string): string;
begin
  Result := QSelect.SQLFieldName(aFieldName);
end;

(*
  * TDataset overrides
*)

procedure TFIBCustomDataSet.DoOnDisableControls(DataSet: TDataSet);
begin
  if Assigned(FOnDisableControls) then
    FOnDisableControls(Self)
end;

procedure TFIBCustomDataSet.DoOnEnableControls(DataSet: TDataSet);
begin
  if Assigned(FOnEnableControls) then
    FOnEnableControls(Self)
end;

type
  THack = class(TFIBDatabase);

procedure TFIBCustomDataSet.SetActive(Value: Boolean);
begin
  if Value then
    if (csDesigning in ComponentState) and (CmpInLoadedState(Self) or (drsInLoaded in FRunState)) then
      if Assigned(Database) then
        try
          if not Database.Connected then
            begin
              if THack(Database).StreammedConnectFail then
                Exit;
              Database.Open(false);
              if not Database.Connected then
                Exit;
            end;
        except
          Exit;
        end;
  inherited SetActive(Value);

end;

procedure TFIBCustomDataSet.DataEvent(Event: TDataEvent; Info: EventInfo);
begin
  if Event = deFieldChange then
    if Assigned(FOnFieldChange) then
      FOnFieldChange(TField(Info));
  vNeedReloadClientBlobs := Event = deDatasetChange;
  try
    inherited DataEvent(Event, Info);
    if ControlsDisabled then
      begin
        if vControlsEnabled then
          begin
            vControlsEnabled := false;
            DoOnDisableControls(Self);
          end
      end
    else if not vControlsEnabled then
      begin
        vControlsEnabled := True;
        DoOnEnableControls(Self);
      end;
  finally
    vNeedReloadClientBlobs := false;
  end
end;

procedure TFIBCustomDataSet.SetStateFieldValue(State: TDataSetState; Field: TField; const Value: Variant);
begin
  vPredState := Self.State;
  inherited SetStateFieldValue(State, Field, Value)
end;

function TFIBCustomDataSet.AllocRecordBuffer: TRecordBuffer;
begin
  Result := AllocMem(FRecordBufferSize);
end;

function TFIBCustomDataSet.BlobModified(Field: TField): Boolean;
var
  fs: TStream;
begin
  if not Field.IsBlob then
    begin
      Result := false;
      Exit;
    end;
  if not CachedUpdates then
    Result := TBlobField(Field).Modified
  else
    begin
      fs := CreateBlobStream(Field, bmRead);
      if Assigned(fs) then
        begin
          if Assigned(TFIBDSFieldStream(fs).FFieldStream) then
            Result := TFIBDSFieldStream(fs).FModified or TFIBDSFieldStream(fs).FFieldStream.Modified
          else
            Result := TFIBDSFieldStream(fs).FModified;
          fs.Free;
        end
      else
        Result := false
    end;
end;

function TFIBCustomDataSet.GetRecordFieldInfo(Field: TField; var TableName, FieldName: string; var RecordKeyValues: TDynArray): Boolean;
var
  vPKNames: string;
  vPos: Integer;
  vPKField: TField;
begin
  TableName := GetRelationTableName(Field);
  FieldName := GetRelationFieldName(Field);
  vPKNames := PrimaryKeyFields(TableName, True);
  if vPKNames = '' then
    begin
      Result := false;
      Exit;
    end
  else
    begin
      SetLength(RecordKeyValues, 0);
      vPos := 1;
      while vPos <= Length(vPKNames) do
        begin
          vPKField := FieldByOrigin(TableName, ExtractFieldName(vPKNames, vPos));
          if vPKField = nil then
            begin
              Result := false;
              Exit;
            end;
          SetLength(RecordKeyValues, Length(RecordKeyValues) + 1);
          RecordKeyValues[Length(RecordKeyValues) - 1] := vPKField.Value;
        end;
    end;
  Result := True;
end;

function TFIBCustomDataSet.CreateBlobStream(Field: TField; Mode: TBlobStreamMode): TStream;
var
  pb: PFIBFieldStreamArray;
  vIndex: Integer;
  fs, fs1: TFIBFieldStream;
  bs: TFIBBlobStream;
  Buff: TRecordBuffer;

  fOfs: Integer;
  BlobID: TISC_QUAD;
  vTableName: string;
  vFieldName: string;
  vKeyValues: TDynArray;

  function FillFieldInfo: Boolean;
  begin
    with Database.BlobSwapSupport do
      if not Active or (Length(SwapDirectory) = 0) then
        begin
          Result := false;
          Exit;
        end;
    Result := GetRecordFieldInfo(Field, vTableName, vFieldName, vKeyValues);
  end;

begin
  if not((Field is TFIBBlobField) and TFIBBlobField(Field).IsClientField) then
    if (Mode <> bmRead) and (not Field.ReadOnly) then
      CheckEditState;

  case vTypeDispositionField of
    dfNormal:
      case State of
        dsFilter:
          begin
            Buff := AllocRecordBuffer;
            if FCurrentRecord < FRecordCount then
              ReadRecordCache(FCurrentRecord, Buff, false)
            else
              ReadRecordCache(FRecordCount - 1, Buff, false);
          end;
        else
          Buff := GetActiveBuf;
      end;
    dfRRecNumber:
      begin
        Buff := AllocRecordBuffer;
        if State <> dsOldValue then
          ReadRecordCache(vInspectRecno, Buff, false)
        else
          ReadRecordCache(vInspectRecno, Buff, True);
      end;
  end;

  if (Buff = nil) then
    begin
      fs := nil;
      Result := TFIBDSFieldStream.Create(Field, fs, Mode);
      Exit;
    end;

  try
    pb := PFIBFieldStreamArray(Buff + FStreamsBufferOffset);
    vIndex := FieldStreamIndex(Field);
    if drsGetBlobStream in FRunState then
      begin
        Result := pb^[vIndex];
        Exit;
      end;
    if (pb^[vIndex] = nil) or (vNeedReloadClientBlobs and pb^[vIndex].IsClientField) then
      begin
        fOfs := vFieldDescrList[Field.FieldNo - 1].fdDataOfs;
        BlobID := PISC_QUAD(@Buff[fOfs])^;
        if (Field is TFIBBlobField) and (TFIBBlobField(Field).FIsClientCalcField) and (Mode = bmRead) then
          begin
            Field.ReadOnly := True;
            bs := TFIBBlobStream.CreateNew(Field.FieldNo, FFieldStreamList);
            fs := bs;
            pb^[vIndex] := fs;
            fs.IsClientField := True;
            if Assigned(FOnFillClientBlob) then
              FOnFillClientBlob(Self, TFIBBlobField(Field), bs);
          end
        else
          begin
            if PRecordData(Buff)^.rdFields[Field.FieldNo].fdIsNull then
              begin
                BlobID.gds_quad_high := 0;
                BlobID.gds_quad_low := 0;
              end;
            if ((PRecordData(Buff)^.rdFields[Field.FieldNo].fdIsNull and (Mode = bmRead))) then
              begin
                fs := nil;
              end
            else
              begin
      {$IFDEF SUPPORT_ARRAY_FIELD}
                if Field is TFIBArrayField then
                  fs := TFIBArrayStream.CreateNew(Field.FieldNo, FFieldStreamList, FQSelect[Field.FieldName].FIBArray)
                else
      {$ENDIF}
                  begin
                    if FillFieldInfo then
                      bs := TFIBBlobStream.CreateNew(Field.FieldNo, FFieldStreamList,
                        vTableName, vFieldName, @vKeyValues)
                    else
                      bs := TFIBBlobStream.CreateNew(Field.FieldNo, FFieldStreamList);
                    if Field is TFIBBlobField then
                      bs.BlobSubType := TFIBBlobField(Field).FSubType
                    else if Field is TFIBMemoField then
                      bs.BlobSubType := TFIBMemoField(Field).FSubType
                    else
                      bs.BlobSubType := FQSelect[Field.FieldName].AsXSQLVAR^.SqlSubType;
                    fs := bs;
                  end;
                pb^[vIndex] := fs;
                fs.Mode := bmReadWrite;
                fs.Database := Database;
                fs.Transaction := Transaction;
                fs.UpdateTransaction := UpdateTransaction;
                fs.BlobID := BlobID;
              end;
          end;

        if (State = dsBrowse) and (fs <> nil) then
          WriteRecordCache(PRecordData(Buff)^.rdRecordNumber, Buff);
      end
    else
      fs := pb^[vIndex];
    if Assigned(fs) then
      begin
        fs.UpdateTransaction := UpdateTransaction;

        if (FCacheModelOptions.FBlobCacheLimit > 0) then
          begin
            fOfs := FOpenedFieldStreams.IndexOf(fs);
            if fOfs >= 0 then
              begin
                FOpenedFieldStreams.Delete(fOfs);
              end;
            FOpenedFieldStreams.Add(fs); // Last to Last

            if (FOpenedFieldStreams.Count > FCacheModelOptions.FBlobCacheLimit) then
              begin
                //
                fs1 := TFIBFieldStream(FOpenedFieldStreams[0]);
                // a modified value (CachedUpdates) exists only in the stream until it is stored
                if not fs1.Modified then
                  fs1.DeInitialize;
                FOpenedFieldStreams.Delete(0);
              end;
          end
      end;
    //
    Result := TFIBDSFieldStream.Create(Field, fs, Mode);
  finally
    if (State in [dsFilter]) or (vTypeDispositionField <> dfNormal) then
      FreeRecordBuffer(Buff);
  end;
end;

function TFIBCustomDataSet.CompareBookmarks(Bookmark1, Bookmark2: TBookMark): Integer;
const
  RetCodes: array [Boolean, Boolean] of ShortInt = ((2, -1), (1, 0));
var
  R1, R2: Integer;
begin
  Result := RetCodes[Bookmark1 = nil, Bookmark2 = nil];
  if Result = 2 then // Both bookmarks are initialized
    begin
      with FRecordsCache do
        begin
          R1 := RecordByBookMark(PFIBBookMark(Bookmark1)^.bRecordNumber);
          R2 := RecordByBookMark(PFIBBookMark(Bookmark2)^.bRecordNumber);
        end;
      if R1 < R2 then
        Result := -1
      else if R1 > R2 then
        Result := 1
      else
        Result := 0;
    end;
end;

procedure TFIBCustomDataSet.CacheDelete;
begin
  try
    Include(FRunState, drsInCacheDelete);
    FilterOut(Self);
  finally
    Exclude(FRunState, drsInCacheDelete);
  end
end;

procedure TFIBCustomDataSet.CacheOpen;
begin
  if Active then
    Close;
  FCachedActive := True;
  Open;
end;

procedure TFIBCustomDataSet.RefreshClientFields(ForceCalc: Boolean = True);
var
{$IFDEF D2009+}
  B: TBookMark;
{$ELSE}
  B: TBookMarkStr;
{$ENDIF}
  CurEof: Boolean;
begin

  if IsEmpty then
    begin
      First;
      Exit;
    end;

  CurEof := Eof;
  DisableControls;
  DisableScrollEvents;
  if ForceCalc then
    Include(FRunState, drsInRefreshClientFields);
  Inc(vSimpleBookMark);
  B := BookMark;
  try
    BookMark := B;
    if CurEof then
      Next; // Restore Eof Flag only
  finally
    Dec(vSimpleBookMark);
    if ForceCalc then
      Exclude(FRunState, drsInRefreshClientFields);
    EnableScrollEvents;
    EnableControls
  end;
end;

function TFIBCustomDataSet.CanCloneFromDataSet(DataSet: TFIBCustomDataSet): Boolean;
var
  i: Integer;
begin
  Result := FieldCount = DataSet.FieldCount;
  if not Result then
    Exit;
  for i := FieldCount - 1 downto 0 do
    with DataSet.Fields[i] do
      begin
        Result := (Fields[i].DataType = DataType) and (Fields[i].Size = Size) and (Fields[i].FieldKind = FieldKind) and
          not(DataType in [ftBlob, ftBytes]);
        if not Result then
          Exit;
      end;
end;

function TFIBCustomDataSet.CreateCalcFieldAs(Field: TField): TField;
begin
  Result := TFieldClass(Field.ClassType).Create(Owner);
  with Result do
    begin
      Size := Field.Size;
      FieldKind := Field.FieldKind;
      FieldName := Field.FieldName;
      Lookup := Field.Lookup;
      KeyFields := Field.KeyFields;
      LookupDataSet := Field.LookupDataSet;
      LookupResultField := Field.LookupResultField;
      LookupKeyFields := Field.LookupKeyFields;
      DataSet := Self;
    end;
end;

function TFIBCustomDataSet.IsDBKeyField(Field: TObject): Boolean;
var
  FN: Integer;
begin
  if Field is TField then
    FN := TField(Field).FieldNo - 1
  else if Field is TFieldDef then
    FN := TFieldDef(Field).FieldNo - 1
  else
    begin
      Result := false;
      Exit;
    end;
  Result := FQSelect.Prepared and (FQSelect.FieldCount > FN) and (FQSelect.Fields[FN].SqlName = 'DB_KEY')
end;

procedure TFIBCustomDataSet.AssignProperties(Source: TFIBCustomDataSet);
begin
  CheckDatasetClosed('Can''t assign properties');
  CopyProps(Source, Self);
end;

procedure TFIBCustomDataSet.CopyFieldsProperties(Source, Destination: TFIBCustomDataSet);
var
  i: Integer;
  fc: Integer;
  F, f1: TField;
begin
  if (Source = nil) or (Destination = nil) or (Source = Destination) then
    Exit;
  fc := Source.FieldCount - 1;
  for i := 0 to fc do
    begin
      F := Source.Fields[i];
      f1 := Destination.FindField(F.FieldName);
      if f1 = nil then
        Continue;
      with f1 do
        begin
          AutoGenerateValue := F.AutoGenerateValue;
          ConstraintErrorMessage := F.ConstraintErrorMessage;
          CustomConstraint := F.CustomConstraint;
          Tag := F.Tag;
          Index := F.Index;
          EditMask := F.EditMask;
          DisplayWidth := F.DisplayWidth;
          DisplayLabel := F.DisplayLabel;
          Required := F.Required;
          ReadOnly := F.ReadOnly;
          Visible := F.Visible;
          DefaultExpression := F.DefaultExpression;
          Alignment := F.Alignment;

        end;
      if (F is TNumericField) and (f1 is TNumericField) then
        with TNumericField(f1) do
          begin
            DisplayFormat := TNumericField(F).DisplayFormat;
            EditFormat := TNumericField(F).EditFormat;
          end;

      if (F is TIntegerField) and (f1 is TIntegerField) then
        with TIntegerField(f1) do
          begin
            MaxValue := TIntegerField(F).MaxValue;
            MinValue := TIntegerField(F).MinValue;
          end;

      if (F is TDateTimeField) and (f1 is TDateTimeField) then
        TDateTimeField(f1).DisplayFormat := TDateTimeField(F).DisplayFormat;
      if (F is TBooleanField) and (f1 is TBooleanField) then
        TBooleanField(f1).DisplayValues := TBooleanField(F).DisplayValues;
      if (F is TFloatField) and (f1 is TFloatField) then
        with TFloatField(f1) do
          begin
            MaxValue := TFloatField(F).MaxValue;
            MinValue := TFloatField(F).MinValue;
            Precision := TFloatField(F).Precision;
            Currency := TFloatField(F).Currency;
          end;

      if (F is TBCDField) and (f1 is TBCDField) then
        with TBCDField(f1) do
          begin
            MaxValue := TBCDField(F).MaxValue;
            MinValue := TBCDField(F).MinValue;
            Precision := TBCDField(F).Precision;
            Currency := TBCDField(F).Currency;
          end;
    end;
end;

procedure TFIBCustomDataSet.CopyFieldsStructure(Source: TFIBCustomDataSet; RecreateFields: Boolean);
var
  i: Integer;
begin
  if Source = nil then
    Exit;
  CheckInactive;
  if RecreateFields then
    begin
      Source.FieldDefs.Update;
      FieldDefs.Assign(Source.FieldDefs);
      DestroyFields;
      CreateFields;
      if not Source.DefaultFields then
        begin
          for i := FieldCount - 1 downto 0 do
            if Source.FindField(Fields[i].FieldName) = nil then
              Fields[i].Free;

          for i := 0 to Source.FieldCount - 1 do
            if (Source.Fields[i].FieldKind in [fkLookup, fkCalculated]) then
              CreateCalcFieldAs(Source.Fields[i]);
        end;
      BindFields(True);
    end
  else
    begin
      FieldDefs.Update;
      BindFields(True);
    end;
  CopyFieldsProperties(Source, Self);
end;

procedure TFIBCustomDataSet.Clone(DataSet: TFIBCustomDataSet; RecreateFields: Boolean; FullCopyProperties: Boolean = false);
begin
  Close;
  // DataSet.CheckActive;
  Include(FRunState, drsInClone);
  DisableControls;
  try
    if FullCopyProperties then
      begin
        CopyProps(DataSet, Self);
        Close;
      end;
    if DataSet.Active then
      begin
        CopyFieldsStructure(DataSet, RecreateFields);
  {$IFDEF SUPPORT_ARRAY_FIELD}
        PrepareStreamFields;
  {$ENDIF}
        vFieldDescrList.Assign(DataSet.vFieldDescrList);
        vrdFieldCount := DataSet.vrdFieldCount;
        FBufferChunkSize := DataSet.FBufferChunkSize;
        FRecordSize := DataSet.FRecordSize;
        FCalcFieldsOffset := DataSet.FCalcFieldsOffset;
        FStreamsBufferOffset := DataSet.FStreamsBufferOffset;
        FRecordBufferSize := DataSet.FRecordBufferSize;
        FRecordCount := DataSet.FRecordCount;
        FStringFieldCount := DataSet.FStringFieldCount;
        FBlockReadSize := DataSet.FBlockReadSize;
        if not Assigned(FRecordsCache) then
          FRecordsCache := TRecordsCache.Create(FCacheModelOptions.FBufferChunks,
            FRecordBufferSize, FBlockReadSize, FStringFieldCount);
        FRecordsCache.Assign(DataSet.FRecordsCache);

        if (Filter <> '') and not Assigned(FFilterParser) then
          ExprParserCreate(FastTrim(Filter), FilterOptions);

        Open;
        if not DataSet.IsEmpty then
          Recno := DataSet.Recno;
        RefreshClientFields(false);
      end;
  finally
    EnableControls;
    Exclude(FRunState, drsInClone);
  end;
end;

procedure TFIBCustomDataSet.OpenAsClone(DataSet: TFIBCustomDataSet);
begin
  if DefaultFields then
    Clone(DataSet, True)
  else
    begin
      if not CanCloneFromDataSet(DataSet) then
        begin
          Close;
          raise Exception.Create(Format(SFIBErrorCloneCursor, [CmpFullName(Self), CmpFullName(DataSet)]));
        end;
      Clone(DataSet, false)
    end;
end;

procedure TFIBCustomDataSet.DoSortEx(Fields: TStrings; Ordering: array of Boolean);
var
  vFields: array of TVarRec;
  i: Integer;
begin
  SetLength(vFields, Fields.Count);
  for i := 0 to Fields.Count - 1 do
    vFields[i].VInteger := FBN(Fields[i]).Index;
  DoSort(vFields, Ordering);
end;

procedure TFIBCustomDataSet.DoSortEx(Fields: array of Integer; Ordering: array of Boolean);
var
  vFields: array of TVarRec;
  i: Integer;
begin
  SetLength(vFields, High(Fields) + 1);
  for i := 0 to High(Fields) do
    vFields[i].VInteger := Fields[i];
  DoSort(vFields, Ordering);
end;

procedure TFIBCustomDataSet.DoSort(Fields: array of const; Ordering: array of Boolean);
begin
  if State in [dsEdit, dsInsert] then
    Post;
  try
    Include(FRunState, drsInSort);
    Sort(Self, Fields, Ordering);
  finally
    Exclude(FRunState, drsInSort);
    RefreshFilters
  end;
end;

function TFIBCustomDataSet.FieldByRelName(const FName: string): TField;
var
  j: Integer;

begin
  Result := nil;
  if Length(FName) = 0 then
    Exit;
  for j := 0 to Pred(FieldCount) do
    if IsEquelSQLNames(GetRelationFieldName(Fields[j]), FName) then
      begin
        Result := Fields[j];
        Exit
      end;
end;

procedure TFIBCustomDataSet.RestoreMacroDefaultValues;
begin
  FQSelect.RestoreMacroDefaultValues
end;

function TFIBCustomDataSet.PrimaryKeyFields(const TableName: string; RelFieldName: Boolean = false): string;
var
  PrimKeyFields: string;
  i, wc: Integer;
  vField: TFIBXSQLVAR;
  tf: TField;
  FN: string;
begin
  Result := '';
  PrimKeyFields := FastTrim(ListTableInfo.GetTableInfo(Database, TableName, false).PrimaryKeyFields[Database]);
  if PrimKeyFields = '' then
    Exit;
  wc := WordCount(PrimKeyFields, [';']);
  if FieldCount > 0 then
    for i := 1 to wc do
      begin
        FN := ExtractWord(i, PrimKeyFields, [';']);
        tf := FieldByOrigin(TableName, FN);
        if tf = nil then
          begin
            Result := '';
            Exit;
          end;
        if RelFieldName then
          Result := Result + iifStr(i > 1, ';', '') + FN
        else
          Result := Result + iifStr(i > 1, ';', '') + tf.FieldName;
      end
  else
    for i := 1 to wc do
      begin
        FN := ExtractWord(i, PrimKeyFields, [';']);
        vField := FQSelect.FieldByOrigin(TableName, FN);
        if vField = nil then
          begin
            Result := '';
            Exit;
          end;
        if RelFieldName then
          Result := Result + iifStr(i > 1, ';', '') + FN
        else
          Result := Result + iifStr(i > 1, ';', '') + vField.Name;
      end;
end;

procedure TFIBCustomDataSet.PrepareAdditionalInfo;
var
  i, oc, fi: Integer;
  tf: TField;
  SQLText: string;
  tmpStr: string;
begin
  if drsInClone in FRunState then
    Exit;

  if (poPersistentSorting in Options) and not VarIsNull(FSortFields) and FIsClientSorting then
    Exit;
  if VarIsNull(FSortFields) or not FIsClientSorting then
    begin
      SQLText := ReadySelectText;
      FSortFields := GetOrderInfo(SQLText, Database.IsFB21OrMore);

      if VarIsNull(FSortFields) then
        Exit;
      oc := VarArrayHighBound(FSortFields, 1);
      for i := 0 to oc do
        begin
          fi := StrToIntDef(FSortFields[i, 0], 0);
          if fi > 0 then
            begin
              tf := FieldByNumber(fi);
              if tf <> nil then
                begin
                  FSortFields[i, 0] := tf.FieldName
                end
              else
                FSortFields[i, 0] := 'NotPresented'
            end
          else
            begin
              tmpStr := FSortFields[i, 0];

              fi := PosCh('.', tmpStr);
              if fi <> 0 then
                begin
                  tf := FieldByOrigin(tmpStr);
                  if tf = nil then
                    tf := FieldByOrigin(FullFieldName(SQLText, tmpStr));
                end
              else
                begin
                  tf := FindField(tmpStr);
                  if tf = nil then
                    tf := FieldByRelName(tmpStr);
                end;
              if tf = nil then
                begin
                  if FCacheModelOptions.FCacheModelKind = cmkLimitedBufferSize then
                    FIBErrorEx('%s.' + CLRF + 'Field %s use in order, but not presented in fields section of SelectSQL',
                      [CmpFullName(Self), tmpStr]);
                  FIsClientSorting := false;
                  FSortFields := Null;
                  Exit
                end
              else
                begin
                  FSortFields[i, 0] := tf.FieldName;

                  { FSortFields[i,1]:=True;
            FSortFields[i,2]:=True; // NULLS FIRST OR LAST }

                end;
            end;
        end;
    end;
  FIsClientSorting := false;
end;

procedure TFIBCustomDataSet.DoBeforeOpen; // override;
var
  i: Integer;
begin
  if DisableCOCount > 0 then
    Exit;
  inherited DoBeforeOpen;

  if vBeforeOpenEvents.Count > 0 then
    for i := 0 to Pred(vBeforeOpenEvents.Count) do
      vBeforeOpenEvents.Event[i](Self)

end;

procedure TFIBCustomDataSet.DoBeforeClose; // override;
var
  i: Integer;
begin
  if DefaultFields then
    begin
      FFNFields.Clear;
      if Assigned(FFilterParser) then
        FFilterParser.ResetFields;
    end;

  if DisableCOCount > 0 then
    Exit;
  inherited DoBeforeClose;
  for i := 0 to Pred(vBeforeCloseEvents.Count) do
    begin
      vBeforeCloseEvents.Event[i](Self)
    end;
end;

procedure TFIBCustomDataSet.DoAfterClose; // override;
begin
  if DisableCOCount > 0 then
    Exit;
  inherited DoAfterClose;
  if poFreeHandlesAfterClose in Options then
    UnPrepare;
end;

procedure TFIBCustomDataSet.DoAfterOpen;

var
  i, L: Integer;
  arr1: array of TVarRec;
  arr2: array of Boolean;

begin
  if not(csDesigning in ComponentState) and (FFieldOriginRule <> forNoRule) and
    not(drsInLoadFromStream in FRunState) then
    for i := 0 to Pred(FieldCount) do
      Fields[i].Origin := GetFieldOrigin(Fields[i]);

  FRelationTables.Clear;
  if not(csDesigning in ComponentState) and not(drsInLoadFromStream in FRunState) then
    for i := 0 to Pred(FieldCount) do
      if Fields[i].FieldKind = fkData then
        FRelationTables.Add(GetRelationTableName(Fields[i]));

  if FIsClientSorting and vSelectSQLTextChanged then
    begin
      if not(poPersistentSorting in Options) or not SortInfoIsValid then
        begin
          FSortFields := Null;
          FIsClientSorting := false;
        end;
    end;
  inherited;
  if poFetchAll in Options then
    FetchAll;
  if Filtered and Assigned(FFilterParser) and (FFilterParser.ExpressionText <> Filter) then
    Filter := Filter;
  vSelectSQLTextChanged := false;
  if Assigned(vTimerForDetail) then
    vTimerForDetail.Enabled := false;
  if (poPersistentSorting in Options) then
    begin
      if not FIsClientSorting then
        Exit;
      L := SortFieldsCount;
      SetLength(arr1, L);
      SetLength(arr2, L);
      Dec(L);
      for i := 0 to L do
        begin
          arr1[i].VInteger := FindField(FSortFields[i, 0]).Index;
          arr2[i] := FSortFields[i, 1]
        end;
      DoSort(arr1, arr2);
      First;
    end
  else if not(psGetOrderInfo in PrepareOptions) then
    FSortFields := Null;

  if vAfterOpenEvents.Count > 0 then
    for i := 0 to Pred(vAfterOpenEvents.Count) do
      vAfterOpenEvents.Event[i](Self)
end;

procedure TFIBCustomDataSet.DoBeforeCancel;
begin
  inherited;
  if not Active then
    FIBError(feDataSetClosed, ['continue after BeforeCancel', CmpFullName(Self)])
end;

procedure TFIBCustomDataSet.DoAfterCancel;
begin
  inherited;
end;

procedure TFIBCustomDataSet.DoBeforeDelete;
begin
  ForceEndWaitMaster;
  if not CanDelete then
    Abort;
  if not CachedUpdates then
    SaveOldBuffer(GetActiveBuf)
  else if TCachedUpdateStatus(PRecordData(GetActiveBuf)^.rdFlags and 7) = cusUnmodified then
    SaveOldBuffer(GetActiveBuf);
  inherited;
  if not Active then
    FIBError(feDataSetClosed, ['continue after BeforeDelete', CmpFullName(Self)])
end;

procedure TFIBCustomDataSet.ForceEndWaitMaster;
begin
  if (DataSource = nil) or (DataSource.DataSet = nil) then
    Exit;
  if WaitEndMasterScroll then
    begin
      if (DataSource.DataSet is TFIBCustomDataSet) then
        TFIBCustomDataSet(DataSource.DataSet).ForceEndWaitMaster;
      if MasterFieldsChanged then
        DoCloseOpen(nil);
      if Assigned(vTimerForDetail) then
        vTimerForDetail.Enabled := false;
    end
end;

procedure TFIBCustomDataSet.DoBeforeEdit;
var
  Buff: PRecordData;
begin
  ForceEndWaitMaster;
  if not CanEdit then
    Abort;
  Buff := PRecordData(GetActiveBuf);
  if not CachedUpdates or (TCachedUpdateStatus(Buff^.rdFlags and 7) = cusUnmodified) then
    SaveOldBuffer(TRecordBuffer(Buff));
  inherited;
  if not Active then
    FIBError(feDataSetClosed, ['continue after BeforeEdit', CmpFullName(Self)]);
end;

procedure TFIBCustomDataSet.DoBeforePost; // override;
begin
  if State in [dsEdit, dsInsert] then
    inherited DoBeforePost;
  if not Active then
    FIBError(feDataSetClosed, ['continue after BeforePost', CmpFullName(Self)]);
end;

procedure TFIBCustomDataSet.DoBeforeInsert;
begin
  if not CanInsert then
    Abort;
  inherited;
end;

procedure TFIBCustomDataSet.DoAfterScroll;
begin
  if vDisableScrollCount = 0 then
    begin
      inherited;
      if Assigned(vScrollTimer) then
        with vScrollTimer do
          begin
            Enabled := false;
            Enabled := True;
          end;
    end;
end;

procedure TFIBCustomDataSet.DoBeforeScroll;
begin
  if vDisableScrollCount = 0 then
    inherited;
end;

procedure TFIBCustomDataSet.DoOnEndScroll(Sender: TObject);
begin
  if Assigned(vScrollTimer) then
    vScrollTimer.Enabled := false;
  if Assigned(FOnEndScroll) then
    FOnEndScroll(Self);
end;

procedure TFIBCustomDataSet.DisableScrollEvents;
begin
  Inc(vDisableScrollCount)
end;

procedure TFIBCustomDataSet.EnableScrollEvents;
begin
  if vDisableScrollCount > 0 then
    Dec(vDisableScrollCount)
end;

procedure TFIBCustomDataSet.DisableCloseOpenEvents;
begin
  Inc(FDisableCOCount)
end;

procedure TFIBCustomDataSet.EnableCloseOpenEvents;
begin
  if FDisableCOCount > 0 then
    Dec(FDisableCOCount)
end;

procedure TFIBCustomDataSet.DisableCalcFields;
begin
  Inc(FDisableCalcFieldsCount)
end;

procedure TFIBCustomDataSet.EnableCalcFields;
begin
  if FDisableCalcFieldsCount > 0 then
    begin
      Dec(FDisableCalcFieldsCount);
      if FDisableCalcFieldsCount = 0 then
        RefreshClientFields(false);
    end;
end;

procedure TFIBCustomDataSet.DoOnPostError(DataSet: TDataSet; E: EDatabaseError; var Action: TDataAction);
begin
end;

procedure TFIBCustomDataSet.DoAfterDelete; // override;
begin
  inherited;
  if (dcForceMasterRefresh in FDetailConditions) and not CachedUpdates then
    RefreshMasterDS;
end;

procedure TFIBCustomDataSet.DoAfterPost;
begin
  if drsInMoveRecord in FRunState then
    try
      MoveRecordToOrderPos;
    finally
      Exclude(FRunState, drsInMoveRecord);
    end;
  inherited;
end;

procedure TFIBCustomDataSet.MoveRecord(OldRecno, NewRecno: Integer; NeedResync: Boolean = True);
begin
  if NewRecno < 1 then
    NewRecno := 1;
  if NewRecno > FRecordCount then
    begin
      FetchAll;
      if NewRecno > FRecordCount then
        NewRecno := FRecordCount;
    end;
  FRecordsCache.MoveRecord(OldRecno - 1, NewRecno - 1);
  if NeedResync then
    Resync([]);
end;

function TFIBCustomDataSet.SetRecordPosInBuffer(NewPos: Integer): Integer;
var
  Distance: Integer;
  MoveDistance: Integer;
begin
  Distance := NewPos - ActiveRecord;
  Result := ActiveRecord;
  if Distance = 0 then
    Exit
  else if Distance > 0 then
    MoveDistance := -Distance - ActiveRecord
  else
    MoveDistance := BufferCount - NewPos - 1;
  DisableScrollEvents;
  DisableControls;
  try
    MoveDistance := MoveBy(MoveDistance);
    MoveBy(-MoveDistance);
    Result := ActiveRecord
  finally
    EnableScrollEvents;
    EnableControls;
  end;
end;

function TFIBCustomDataSet.NeedMoveRecordToOrderPos: Boolean;
var
  i: Integer;
  OrderFieldsCount: Integer;
  FN: string;
  CalculateFieldsForced: Boolean;
begin
  if not Sorted then
    Result := false
  else if not(poKeepSorting in FOptions) and (FCacheModelOptions.CacheModelKind <> cmkLimitedBufferSize) then
    Result := false
  else
    begin
      OrderFieldsCount := VarArrayHighBound(FSortFields, 1) + 1;
      FN := FSortFields[0, 0];
      if OrderFieldsCount = 1 then
        with FBN(FN) do
          begin
            if FieldKind in [fkCalculated, fkLookup] then
              begin
                GetCalcFields(ActiveBuffer);
              end;
            if CachedUpdates then
              Result := True
            else
              Result := Value <> OldValue // CachedUpdates???
          end
      else
        begin
          Result := false;
          CalculateFieldsForced := false;
          for i := 0 to OrderFieldsCount - 1 do
            begin
              FN := FSortFields[i, 0];
              with FBN(FN) do
                begin
                  if (FieldKind in [fkCalculated, fkLookup]) and not CalculateFieldsForced then
                    begin
                      GetCalcFields(ActiveBuffer);
                      CalculateFieldsForced := True;
                    end;
                  Result := Value <> OldValue;
                end;
              if Result then
                Exit;
            end;
        end;
    end;
end;

function TFIBCustomDataSet.AllFieldValues: Variant;
var
  i: Integer;
begin
  Result := VarArrayCreate([0, Fields.Count - 1], varVariant);
  for i := 0 to Fields.Count - 1 do
    Result[i] := Fields[i].Value;
end;

procedure TFIBCustomDataSet.ExportDataToScript(OutPut: TStrings; TableName: string = ''; AllFields: Boolean = false);
var
  FieldList: string;
  i: Integer;
  vTableName: string;
begin
  if TableName = '' then
    TableName := AutoUpdateOptions.UpdateTableName;
  if (Length(TableName) > 0) and (TableName[1] = '"') then
    vTableName := Copy(TableName, 2, Length(TableName) - 2)
  else
    vTableName := TableName;
  FieldList := '';
  if not AllFields then
    for i := 0 to Pred(FieldCount) do
      begin
        if GetRelationTableName(Fields[i]) = vTableName then
          FieldList := FieldList + Fields[i].FieldName + ';';
      end;
  GetExportDataScript(Self, TableName, OutPut, True, FieldList)
end;

procedure TFIBCustomDataSet.ExportDataToScriptFile(const FileName: string; TableName: string = ''; AllFields: Boolean = false);
var
  FieldList: string;
  i: Integer;
  vTableName: string;
begin
  if TableName = '' then
    TableName := AutoUpdateOptions.UpdateTableName;
  if (Length(TableName) > 0) and (TableName[1] = '"') then
    vTableName := Copy(TableName, 2, Length(TableName) - 2)
  else
    vTableName := TableName;
  FieldList := '';
  if not AllFields then
    for i := 0 to Pred(FieldCount) do
      begin
        if GetRelationTableName(Fields[i]) = vTableName then
          FieldList := FieldList + Fields[i].FieldName + ';';
      end;
  GetExportDataScriptToFile(Self, TableName, FileName, True, FieldList)
end;

procedure TFIBCustomDataSet.MoveRecordToOrderPos;
var
  i, NewPlace: Integer;
  KeyValues: Variant;
  OldVisibleRecno: Boolean;
  OldFiltered: Boolean;
  OrderFieldsCount: Integer;
  ForcedCalculateFields: Boolean;
  OldFValues: Variant;
  oldLockResync: Integer;
  // OldActiveRecord:Integer;
{$IFDEF D2009+}
  B: TBookMark;
{$ELSE}
  B: TBookMarkStr;
{$ENDIF}
begin
  if IsEmpty then
    Exit;
  OldVisibleRecno := poVisibleRecno in Options;
  OldFiltered := Filtered;
  B := BookMark;
  if Sorted then
    if not(poKeepSorting in Options) then
      FSortFields := Null
    else
      try
        Include(FRunState, drsInMoveRecord);
        // OldActiveRecord:=ActiveRecord;
        DisableControls;
        DisableScrollEvents;
        Options := Options - [poVisibleRecno];
        vIgnoreLocRecno := Recno;
        if OldFiltered then
          begin
            Filtered := false;
            First;
            Recno := vIgnoreLocRecno
          end;
        OrderFieldsCount := VarArrayHighBound(FSortFields, 1) + 1;
        if OrderFieldsCount = 1 then
          begin
            with FBN(FSortFields[0, 0]) do
              begin
                if FieldKind in [fkCalculated, fkLookup] then
                  GetCalcFields(ActiveBuffer);
                KeyValues := Value
              end;
          end
        else
          begin
            KeyValues := VarArrayCreate([0, OrderFieldsCount - 1], varVariant);
            ForcedCalculateFields := false;
            for i := 0 to OrderFieldsCount - 1 do
              with FBN(FSortFields[i, 0]) do
                begin
                  if (FieldKind in [fkCalculated, fkLookup]) and not ForcedCalculateFields then
                    begin
                      GetCalcFields(ActiveBuffer);
                      ForcedCalculateFields := True
                    end;
                  KeyValues[i] := Value;
                end;
          end;
        OldFValues := AllFieldValues;
        ExtLocate(SortedFields, KeyValues, [eloInSortedDS, eloNearest]);
        // ^^^^^^^^^^^^ Search place for record

        if (Recno > vIgnoreLocRecno) and (not Eof) then
          NewPlace := Recno - 1
        else
          NewPlace := Recno;

        if NewPlace <> vIgnoreLocRecno then
          begin
            MoveRecord(vIgnoreLocRecno, NewPlace, false);
            if FFilteredCacheInfo.NonVisibleRecords.Count > 0 then
              begin
                with FFilteredCacheInfo.NonVisibleRecords do
                  if vIgnoreLocRecno > NewPlace then
                    IncValuesDiapazon(NewPlace, MaxInt, 1)
                  else
                    IncValuesDiapazon(vIgnoreLocRecno, NewPlace, -1)
              end;

            { if NewPlace>=RecordCount then
            begin
            Recno:=RecordCount-1;
            //       vNeedLast:=True
            end
            else
            Recno:=NewPlace;
          }
          end
        else
          begin
            Recno := vIgnoreLocRecno;
            // SetRecordPosInBuffer(OldActiveRecord);
          end;
      // Inc(vLockResync);
      finally
        Exclude(FRunState, drsInMoveRecord);
        vIgnoreLocRecno := -1;
        if OldFiltered then
          begin
            oldLockResync := vLockResync;
            Filtered := OldFiltered;
            vLockResync := oldLockResync;
          end;
        if OldVisibleRecno then
          Options := Options + [poVisibleRecno];

        BookMark := B;
        EnableScrollEvents;
        EnableControls;
      end;
end;

procedure TFIBCustomDataSet.FetchAll;
var
{$IFDEF D2009+}
  CurBookmark: TBookMark;
{$ELSE}
  CurBookmark: string;
{$ENDIF}
  iCurScreenState: Integer;
begin
  ChangeScreenCursor(iCurScreenState);
  try
    if FQSelect.Eof or not FQSelect.Open then
      Exit;
    DisableControls;
    DisableScrollEvents;
    Inc(vSimpleBookMark);
    try
      CurBookmark := BookMark;
      Last;
      BookMark := CurBookmark;
    finally
      Dec(vSimpleBookMark);
      EnableControls;
      EnableScrollEvents;
    end;
  finally
    RestoreScreenCursor(iCurScreenState);
  end;
end;

(*
  * Free up the record buffer allocated by TDataset
*)
procedure TFIBCustomDataSet.FreeRecordBuffer(var Buffer: TRecordBuffer);
begin
  FreeMem(Buffer);
  Buffer := nil;
end;

procedure TFIBCustomDataSet.PrepareQuery(KindQuery: TpSQLKind);
var
  Qry: TFIBQuery;
  OldUpdateTransaction: TFIBTransaction;
  ForceStartTransaction: Boolean;
begin
  case KindQuery of
    skModify: Qry := QUpdate;
    skInsert: Qry := QInsert;
    skDelete: Qry := QDelete;
    else
      Qry := QRefresh;
  end;
  try
    if not EmptyStrings(Qry.SQL) and (not Qry.Prepared) and (Qry.SQL[0] <> SNoAction) then
      begin
        if not Assigned(Qry.Transaction) then
          FIBError(feTransactionNotAssigned, [CmpFullName(Qry)]);
        if not Assigned(Transaction) then
          FIBError(feTransactionNotAssigned, [CmpFullName(Self)]);

        if Qry.Transaction.MainDatabase = Database then
          begin
            OldUpdateTransaction := Qry.Transaction;
            try
              Qry.Transaction := Transaction;
              StartTransaction;
              Qry.Prepare;
            finally
              Qry.Transaction := OldUpdateTransaction
            end;
          end
        else
          begin
            ForceStartTransaction := not Qry.Transaction.InTransaction;
            if ForceStartTransaction then
              Qry.Transaction.StartTransaction;
            Qry.Prepare;
            if ForceStartTransaction then
              Qry.Transaction.Commit;
          end;
      end;
  except
    on E: Exception do
      if (E is EFIBInterbaseError) and (EFIBInterbaseError(E).sqlcode = sqlcode_notpermission) and
        FIBHideGrantError and not(csDesigning in ComponentState) then
        begin
          if KindQuery <> skRefresh then
            FAllowedUpdateKinds := FAllowedUpdateKinds - [TUpdateKind(KindQuery)];
          Abort;
        end
      else
        raise;
  end;
end;

procedure TFIBCustomDataSet.PrepareBookMarkSize;
var
  i, oc: Integer;
  tf: TField;
  Pos: Integer;

  // TIME/TIMESTAMP WITH TIME ZONE keys keep the cache value with its time zone
  function KeySize(tf: TField; DefSize: Integer): Integer;
  var
    fi: PFIBFieldDescr;
  begin
    fi := TimeZoneFieldDescr(Self, tf);
    if fi <> nil then
      Result := fi^.fdDataSize
    else
      Result := DefSize;
  end;

begin
  if not Assigned(FKeyFieldsForBookMark) then
    FKeyFieldsForBookMark := TStringList.Create
  else
    FKeyFieldsForBookMark.Clear;

  BookmarkSize := 2 * SizeOf(Integer);
  if Length(FAutoUpdateOptions.KeyFields) = 0 then
    begin
      case CacheModelOptions.CacheModelKind of
        cmkStandard: BookmarkSize := SizeOf(TFIBBookmark);
        cmkLimitedBufferSize:
          begin
            if VarIsNull(FSortFields) then
              FIBErrorEx
              ('%s.PrepareBookMarkSize:Can''t find or parse ORDER BY statement.', [CmpFullName(Self)]);
            oc := VarArrayHighBound(FSortFields, 1);
            for i := 0 to oc do
              begin
                tf := FN(FSortFields[i, 0]);
                if Assigned(tf) then
                  begin
                    FKeyFieldsForBookMark.AddObject(tf.FieldName, TObject(BookmarkSize));
                    if tf is TFIBStringField then
                      BookmarkSize := BookmarkSize + SizeOf(Boolean) + tf.DataSize - 1
                    else
                      BookmarkSize := BookmarkSize + SizeOf(Boolean) + KeySize(tf, tf.DataSize);
                  end;
              end;
          end;
      end; // case
    end
  else if CacheModelOptions.CacheModelKind = cmkLimitedBufferSize then
    begin
      Pos := 1;
      while Pos <= Length(FAutoUpdateOptions.KeyFields) do
        begin
          tf := FN(ExtractFieldName(FAutoUpdateOptions.KeyFields, Pos));
          if Assigned(tf) then
            begin
              FKeyFieldsForBookMark.AddObject(tf.FieldName, TObject(BookmarkSize));
              BookmarkSize := BookmarkSize + SizeOf(Boolean) + KeySize(tf, tf.DataSize)
            end;
        end;
    end;
end;

{$IFDEF D_XE3}

procedure TFIBCustomDataSet.GetBookmarkData(Buffer: TRecordBuffer; Data: TBookMark);
begin
  GetBookmarkData(TRecordBuffer(Buffer), Pointer(Data));
end;
{$ENDIF}

procedure TFIBCustomDataSet.GetBookmarkData(Buffer: TRecordBuffer; Data: Pointer);
var
  i, L: Integer;
  fi: PFIBFieldDescr;
  tf: TField;
  PIsNull: PAnsiChar;
  FieldSize: Integer;
begin
  if not IsEmpty then
    begin
      FillChar(Data^, BookmarkSize, 0);
      with PFIBBookMark(Data)^ do
        begin
          bRecordNumber := FRecordsCache.BookMarkByRecord
            (PRecordData(Buffer)^.rdRecordNumber);
          bActiveRecord := ActiveRecord;
        end;
      // if  (FCacheModelOptions.CacheModelKind=cmkLimitedBufferSize) then
      if vSimpleBookMark = 0 then
        begin
          for i := 0 to Pred(FKeyFieldsForBookMark.Count) do
            begin
              tf := FN(FKeyFieldsForBookMark[i]);
              if Assigned(tf) then
                begin
                  if (tf is TFIBStringField) then
                    FieldSize := tf.DataSize - 1
                  else
                    FieldSize := tf.DataSize;

                  PIsNull := PAnsiChar(Data) + Integer(FKeyFieldsForBookMark.Objects[i]);
                  if PRecordData(Buffer)^.rdFields[tf.FieldNo].fdIsNull then
                    PBoolean(PIsNull)^ := True
                  else
                    begin
                      PBoolean(PIsNull)^ := false;
                      fi := vFieldDescrList[tf.FieldNo - 1];
                      if (tf.DataType in [ftWideString, ftString]) then
                        begin
                          if fi^.fdIsSeparateString then
                            begin
                              L := PInteger(PAnsiChar(Buffer + fi^.fdDataOfs))^;
                              if L < FieldSize then
                                FieldSize := L;
                              if poTrimCharFields in Options then
                                while PAnsiChar(Buffer + fi^.fdDataOfs + SizeOf(Integer))
                                  [FieldSize - 1] = ' ' do
                                  Dec(FieldSize);
                              Move(PAnsiChar(Buffer + fi^.fdDataOfs + SizeOf(Integer))^,
                                PAnsiChar(PIsNull + SizeOf(Boolean))^, FieldSize);
                            end
                          else
                            begin
                              L := Length(PAnsiChar(Buffer + fi^.fdDataOfs));
                              if L < FieldSize then
                                FieldSize := L;
                              if poTrimCharFields in Options then
                                while PAnsiChar(Buffer + fi^.fdDataOfs)
                                  [FieldSize - 1] = ' ' do
                                  Dec(FieldSize);
                              Move(PAnsiChar(Buffer + fi^.fdDataOfs)^,
                                PAnsiChar(PIsNull + SizeOf(Boolean))^, FieldSize);
                            end
                        end
                      else
                        case fi^.fdDataType of
                          // Firebird 4 types are stored in the format of the field buffer
                          SQL_INT128, SQL_DEC16, SQL_DEC34:
                            if not CacheToBcd(fi, Buffer + fi^.fdDataOfs, PBcd(PIsNull + SizeOf(Boolean))^) then
                              PBoolean(PIsNull)^ := True;
                          // the value with its time zone, see PrepareBookMarkSize
                          SQL_TIME_TZ_EX, SQL_TIMESTAMP_TZ_EX:
                            Move(PAnsiChar(Buffer + fi^.fdDataOfs)^,
                              PAnsiChar(PIsNull + SizeOf(Boolean))^, fi^.fdDataSize);
                          else
                            Move(PAnsiChar(Buffer + fi^.fdDataOfs)^, PAnsiChar(PIsNull + SizeOf(Boolean))^, FieldSize);
                        end;
                    end;
                end;
            end;
        end;
    end;
end;

function TFIBCustomDataSet.GetBookmarkFlag(Buffer: TRecordBuffer): TBookmarkFlag;
begin
  if (State = dsBrowse) and not IsEmpty then
    Result := bfCurrent
  else
    Result := PRecordData(Buffer)^.rdBookmarkFlag;
end;

function TFIBCustomDataSet.GetCanModify: Boolean;
begin
  Result := CanEdit or CanInsert or CanDelete
end;

function TFIBCustomDataSet.GetCurrentRecord(Buffer: TRecordBuffer): Boolean;
begin
  if not IsEmpty and (GetBookmarkFlag(ActiveBuffer) = bfCurrent) then
    begin
      UpdateCursorPos;
      ReadRecordCache(PRecordData(ActiveBuffer)^.rdRecordNumber, Buffer, false);
      Result := True;
    end
  else
    Result := false;
end;

function TFIBCustomDataSet.GetDataSource: TDataSource;
begin
  if FSourceLink = nil then
    Result := nil
  else
    Result := FSourceLink.DataSource;
end;

function TFIBCustomDataSet.GetFieldClass(FieldType: TFieldType): TFieldClass;
begin
  Result := nil;
  if (FieldType <= ftTypedBinary) then
    Result := DefaultFieldClasses[FieldType]
  else
    case FieldType of
      ftGuid: Result := TFIBGuidField;
      ftWideString: Result := TFIBWideStringField;
      ftLargeint: Result := TFIBLargeIntField;
      ftFMTBcd: Result := TFIBFMTBCDField;
{$IFDEF SUPPORT_ARRAY_FIELD}
      ftBytes: Result := TFIBArrayField;
{$ENDIF}
{$IFDEF D2007+}
      ftWideMemo: Result := TFIBMemoField;
{$ENDIF}
    end;
end;

function TFIBCustomDataSet.RecordFieldValue(Field: TField; RecNumber: Integer): Variant;
var
  p, P1: Pointer;
  fi: PFIBFieldDescr;
  NeedRecalcField: Boolean;
  tmpCurrency: Currency;
  tmpDateTime: TDateTime;
  vBcd: TBcd;

begin
  CheckActive;
  case FCacheModelOptions.FCacheModelKind of
    cmkStandard:
      begin
        if FRecordCount < RecNumber then
          FetchNext(RecNumber - FRecordCount + 1);
        if FRecordCount < RecNumber then
          raise Exception.Create(CmpFullName(Self) + '.' + 'Can''t read record ' + IntToStr(RecNumber));
        if UniDirectional then
          RecNumber := RecNumber mod FCacheModelOptions.FBufferChunks
      end;
    cmkLimitedBufferSize:
      begin
        if (RecNumber - 1 <= vPartition.EndPartRecordNo) and (RecNumber - 1 >= vPartition.BeginPartRecordNo) then
          RecNumber := RecNumber mod FCacheModelOptions.FBufferChunks
        else
          raise Exception.Create(CmpFullName(Self) + '.' + 'Can''t read record ' + IntToStr(RecNumber));
      end;
  end;
  NeedRecalcField := Field.FieldKind in [fkCalculated, fkLookup];
  if NeedRecalcField then
    NeedRecalcField := not vCalcFieldsSavedCache or
      not GetBit(PSavedRecordData(FRecordsCache.PRecBuffer(RecNumber, false))^.rdFlags, 7);
  // if NeedRecalcField then
  if NeedRecalcField or Field.IsBlob then
    begin
      vInspectRecno := RecNumber - 1;
      try
        vTypeDispositionField := dfRRecNumber;
        Result := Field.Value;
      finally
        vTypeDispositionField := dfNormal
      end;
    end
  else
    begin
      if Field.FieldNo > 0 then
        begin
          fi := vFieldDescrList[Field.FieldNo - 1];
          p := FRecordsCache.GetFieldData(RecNumber, fi^.fdDataOfs - DiffSizesRecData, fi^.fdStrIndex, P1);
          if PSavedRecordData(P1).rdFields[Field.FieldNo].fdIsNull then
            begin
              Result := Null;
              Exit;
            end;

          if p = nil then
            Result := Null
          else
            case fi^.fdDataType of
              SQL_VARYING, SQL_TEXT:
                begin
                  if fi^.fdIsSeparateString then
                    begin
                      case Field.DataType of
                        ftString: Result := DecodeString(PFIBByteString(p)^, StringFieldCodePage(Field));
                        ftWideString: Result := DecodeWideString(PFIBByteString(p)^, StringFieldCodePage(Field));
                      end;

                      if poTrimCharFields in FOptions then
                        Result := VarTrimRight(Result);
                    end
                  else
                    case Field.DataType of
                      ftString:
                        begin
                          Result := DecodeString(FastCopy(AnsiString(PAnsiChar(p)), 1, fi^.fdDataSize),
                            StringFieldCodePage(Field));
                          if poTrimCharFields in FOptions then
                            Result := VarTrimRight(Result);
                        end;
                      ftWideString:
                        begin
                          // fdDataSize: bytes, Size: characters
                          Result := DecodeWideString(FastCopy(AnsiString(PAnsiChar(p)), 1, fi^.fdDataSize),
                            StringFieldCodePage(Field));
                          if poTrimCharFields in FOptions then
                            Result := VarTrimRight(Result);
                        end;
                      ftGuid: Result := GUIDAsString(PGuid(p)^);

                    end;
                end;

              SQL_DOUBLE: Result := PDouble(p)^;
              SQL_FLOAT: Result := PSingle(p)^;
              SQL_LONG:
                if fi^.fdDataScale <> 0 then
                  Result := PLong(p)^ * E10[fi^.fdDataScale]
                else
                  Result := PLong(p)^;
              SQL_SHORT:
                if fi^.fdDataScale <> 0 then
                  Result := PShort(p)^ * E10[fi^.fdDataScale]
                else
                  Result := PShort(p)^;
              SQL_TIMESTAMP: Result := TimeStampToDateTime(MSecsToTimeStamp(PDateTime(p)^));
              SQL_BLOB: ;

              SQL_TYPE_DATE:
                begin
                  Result := TimeStampToDateTime(TimeStamp(PInteger(p)^, 0));
                end;
              SQL_TYPE_TIME: Result := TimeStampToDateTime(TimeStamp(DateDelta, PInteger(p)^));
              SQL_INT64:
                case Field.DataType of
                  ftFloat: Result := PDouble(p)^;
                  ftBCD:
                    begin
                      if fi^.fdDataScale = 0 then
                        Result := PInt64(p)^
                      else
                        begin
                          // Result:=PInt64(P)^*E10[fi^.fdDataScale];
                          Int64ToBCD(PInt64(p)^, -fi^.fdDataScale, vBcd);
                          VarFMTBcdCreate(Result, vBcd);

                          ;
                          if Field.Size = 4 then
                            Result := VarAsType(Result, varCurrency);
                        end;

                    end;
                  ftLargeint: Result := PInt64(p)^;
                end;
              SQL_INT128, SQL_DEC16, SQL_DEC34:
                if CacheToBcd(fi, p, vBcd) then
                  VarFMTBcdCreate(Result, vBcd)
                else
                  Result := FBRawToDouble(fi^.fdDataType, fi^.fdDataScale, p);
              SQL_TIME_TZ_EX, SQL_TIMESTAMP_TZ_EX: Result := TimeZoneCacheToDateTime(fi, p);
              IB_SQL_BOOLEAN, SQL_BOOLEAN: Result := PBoolean(p)^;
            end;
        end
      else
        begin
          // Calc
          p := FRecordsCache.GetFieldData(RecNumber, FBlockReadSize + Field.Offset, -1, P1);
          if p = nil then
            Result := Null
          else
            begin
              if not PBoolean(p)^ then
                begin
                  Result := Null;
                  Exit;
                end;
              Inc(PAnsiChar(p), SizeOf(Boolean));
              case Field.DataType of
                ftString: Result := FastCopy(AnsiString(PAnsiChar(p)), 1, Field.Size);
                ftSmallint: Result := PSmallint(p)^;
                ftInteger: Result := PInteger(p)^;
                ftBoolean: Result := PBoolean(p)^;
                ftCurrency: Result := PCurrency(p)^;
                ftBCD:
                  begin
                    if BCDToCurr(TBcd(p^), tmpCurrency) then
                      Result := tmpCurrency
                    else
                      Result := Null;
                  end;
                ftDate, ftTime, ftDateTime:
                  begin
                    DataConvert(Field, p, @tmpDateTime, false);
                    if tmpDateTime = 0 then
                      Result := Null
                    else
                      Result := tmpDateTime;
                  end;
                ftFloat: Result := PDouble(p)^;
                ftWideString:
                  if Database.NeedUnicodeFieldsTranslation then
      {$IFDEF D2009+}
      {$IFDEF D_XE}
                    Result := WideString(PWideChar(p))
      {$ELSE}
                    Result := UTF8ToString(PAnsiChar(p))
      {$ENDIF}
      {$ELSE}
                    Result := UTF8Decode(PChar(p))
      {$ENDIF}
                  else
                    Result := AnsiString(PAnsiChar(p));
                ftGuid: Result := GUIDAsString(PGuid(p)^);
                ftLargeint: Result := PInt64(p)^;
              end;
            end;
        end;
    end;
end;

function TFIBCustomDataSet.RecordFieldValue(Field: TField; aBookmark: TBookMark): Variant;
begin
  if BookmarkValid(aBookmark) then
    Result := RecordFieldValue(Field, FRecordsCache.RecordByBookMark(PFIBBookMark(aBookmark)^.bRecordNumber) + 1)
  else
    Result := Null
end;

function TFIBCustomDataSet.StringFieldCharSetID(Field: TField): Integer;
var
  fi: PFIBFieldDescr;
begin
  fi := DataFieldDescr(Self, Field);
  if fi <> nil then
    Result := Byte(fi^.fdSubType)
  else
    Result := -1;
end;

function TFIBCustomDataSet.StringFieldCodePage(Field: TField): Word;
var
  CharSetID: Integer;
begin
  CharSetID := StringFieldCharSetID(Field);
  if (CharSetID >= 0) and Assigned(Database) then
    Result := Database.Capabilities.TextCodePage(CharSetID)
  else
    Result := FIBCodePageSystem;
end;

function TFIBCustomDataSet.BlobFieldCodePage(Field: TField): Word;
var
  fi: PFIBFieldDescr;
begin
  fi := DataFieldDescr(Self, Field);
  // text BLOB: the charset is in sqlscale
  if (fi <> nil) and (fi^.fdSubType = 1) and Assigned(Database) then
    Result := Database.Capabilities.BlobCodePage(Byte(fi^.fdDataScale))
  else
    Result := FIBCodePageSystem;
end;

{$IFDEF D_XE4}

procedure TFIBCustomDataSet.DataConvert(Field: TField; Source: TValueBuffer; var Dest: TValueBuffer; ToNative: Boolean);
begin
  DataConvert(Field, Pointer(Source), Pointer(Dest), ToNative);
end;
{$ELSE}
{$IFDEF D_XE3}

procedure TFIBCustomDataSet.DataConvert(Field: TField; Source, Dest: TValueBuffer; ToNative: Boolean);
begin
  DataConvert(Field, Pointer(Source), Pointer(Dest), ToNative);
end;
{$ENDIF}
{$ENDIF}
{$IFDEF D2006+}

procedure TFIBCustomDataSet.DataConvert(Field: TField; Source, Dest: Pointer; ToNative: Boolean);
var
  ws: WideString;
  s: AnsiString;
  L: Integer;
begin
  if not(Field is TWideStringField) or (Field.FieldKind <> fkData) then
    inherited
  else
    begin
      if StringFieldCodePage(Field) = FIBCodePageUTF8 then
        begin
          if ToNative then
            begin
              FillChar(Dest^, Field.DataSize, 0);
              s := UTF8Encode(PWideChar(Source));
              L := Length(s);
              if L > 0 then
                Move(s[1], Dest^, (L + 1) * SizeOf(AnsiChar));
            end
          else
            inherited
        end
      else
        begin
          FillChar(Dest^, Field.DataSize, 0);
          if ToNative then
            begin
              s := PWideChar(Source);
              L := Length(s);
              if L > 0 then
                Move(s[1], Dest^, L);
            end
          else
            begin
              ws := PAnsiChar(Source);
              L := Length(ws);
              if L > 0 then
                Move(ws[1], Dest^, (L + 1) * SizeOf(WideChar));
            end;
        end;
    end;
end;
{$ELSE}

procedure TFIBCustomDataSet.DataConvert(Field: TField; Source, Dest: Pointer; ToNative: Boolean);
var
  s: string;
begin
  if (Field is TWideStringField) then
    begin
      begin
        if StringFieldCodePage(Field) = FIBCodePageUTF8 then
          begin
            if ToNative then
              begin
                FillChar(PChar(Dest)[0], Field.DataSize, 0);
                s := UTF8Encode(PWideString(Source)^);
                if Length(s) > 0 then
                  Move(s[1], PChar(Dest)[0], Length(s))
              end
            else if (Field.FieldKind = fkData) then
              begin
                if (drsInFieldValidate in FRunState) and (Field = FValidatedField) and
                  (FValidatedRec = ActiveRecord) then
                  PWideString(Dest)^ := UTF8Decode(PChar(Source))
                else
                  PWideString(Dest)^ := PWideChar(Source);
              end
            else
              PWideString(Dest)^ := UTF8Decode(PChar(Source));
          end
        else
          begin
            if ToNative then
              begin
                FillChar(PChar(Dest)[0], Field.DataSize, 0);
                s := PWideString(Source)^;
                if Length(s) > 0 then
                  Move(s[1], PChar(Dest)[0], Length(s))
              end
            else
              PWideString(Dest)^ := PChar(Source)
          end;
      end
    end
  else
    inherited

end;
{$ENDIF}
{$IFDEF D2009+}

function TFIBCustomDataSet.GetBlobFieldData(FieldNo: Integer; var Buffer: TBlobByteData): Integer; // MIDAS
var
  Stream: TStream;
  blField: TBlobField;
  s: AnsiString;
  ws: string;
begin
  blField := FieldByNumber(FieldNo) as TBlobField;
  Stream := CreateBlobStream(blField, bmRead);
  Result := Stream.Size;
  if Result = 0 then
    Stream.Free
  else if blField.DataType = ftWideMemo then
    try
      blField.Transliterate := false;
      SetLength(s, Result);
      Stream.Read(s[1], Result);
      ws := UTF8ToString(s);
      if Length(Buffer) <= Length(ws) * SizeOf(WideChar) then
        SetLength(Buffer, Length(ws) * SizeOf(WideChar) + 3);
      Move(ws[1], Buffer[0], Length(ws) * SizeOf(WideChar));
      Result := Length(ws) * SizeOf(WideChar)
    finally
      Stream.Free;
    end
  else
    try
      if Length(Buffer) <= Result then
        SetLength(Buffer, Result + Result div 4);
      Stream.Read(Buffer[0], Result);
    finally
      Stream.Free;
    end;
end;
{$ENDIF}
{$IFDEF D_XE4}

function TFIBCustomDataSet.GetFieldData(Field: TField; var Buffer: TValueBuffer): Boolean;
begin
  Result := GetFieldData(Field, Pointer(Buffer))
end;
{$ELSE}
{$IFDEF D_XE3}

function TFIBCustomDataSet.GetFieldData(Field: TField; Buffer: TValueBuffer): Boolean;
begin
  Result := GetFieldData(Field, Pointer(Buffer))
end;
{$ENDIF}
{$ENDIF}

type
  THackField = class(TField);

function TFIBCustomDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
var
  Buff, Data: TRecordBuffer;
  CurrentRecord: PRecordData;
  fi: PFIBFieldDescr;
  L: Integer;
  Allocated: Boolean;

  function IsValidRecord: Boolean;
  begin
    case FCacheModelOptions.CacheModelKind of
      cmkLimitedBufferSize:
        begin
          Result := (CurrentRecord^.rdRecordNumber >= vPartition^.BeginPartRecordNo) and
            (CurrentRecord^.rdRecordNumber <= vPartition^.EndPartRecordNo) or (State = dsInsert)
        end;
      else
        Result := (State <> dsBrowse) or (CurrentRecord^.rdRecordNumber < FRecordCount)
    end;
  end;

  procedure GetInspectRecBuffer;
  var
    dsState: TDataSetState;
    OldDisableCalcFields: Integer;
  begin
    dsState := State;
    Allocated := (dsState <> dsCalcFields) and (Field.FieldKind in [fkLookup, fkCalculated]);
    if Allocated and vCalcFieldsSavedCache then
      begin
        Allocated := (drsInRefreshClientFields in FRunState) or
          not GetBit(PSavedRecordData(FRecordsCache.PRecBuffer(vInspectRecno + 1, false))^.rdFlags, 7)
      end;
    if Allocated then
      begin
        Buff := AllocRecordBuffer;
        ReadRecordCache(vInspectRecno, Buff, State = dsOldValue);
        if (Field.FieldKind in [fkLookup, fkCalculated]) then
          begin
            OldDisableCalcFields := FDisableCalcFieldsCount;
            FDisableCalcFieldsCount := 0;
            try
              SetTempState(dsCalcFields);
              GetCalcFields(Buff);
            finally
              FDisableCalcFieldsCount := OldDisableCalcFields;
              RestoreState(dsState);
            end
          end;
      end
    else
      begin
        Allocated := (dsState in [dsOldValue, dsFilter]) or
          ((vTypeDispositionField = dfRRecNumber) and (dsState <> dsCalcFields));
        if Allocated then
          begin
            Buff := AllocRecordBuffer;
            ReadRecordCache(vInspectRecno, Buff, State = dsOldValue)
          end
        else
          Buff := GetActiveBuf;
      end;
  end;
{
  procedure DoUTFStringValue;
  begin
  TFIBStringField(Field).FStringBuffer:=UTF8Decode(PAnsiChar(Data));
  L:=Length(TFIBStringField(Field).FStringBuffer);
  Move(TFIBStringField(Field).FStringBuffer[1], Buffer^, L);
  PAnsiChar(Buffer)[L]:=#0
  end; }

begin
  Result := false;
  if (drsInFieldValidate in FRunState) and not(State = dsOldValue) then
    if (Field = FValidatedField) and (FValidatedRec = ActiveRecord) then
      begin
        Result := FValidatingFieldBuffer <> nil;
        if Result and (Buffer <> nil) then
          // TField.CopyData moves GetIOSize bytes, for string fields at least
          // dsMaxStringSize, while field buffers have DataSize bytes
          if Field is TFIBWideStringField then
            THackField(Field).CopyData(FValidatingFieldBuffer, Buffer)
          else
            Move(FValidatingFieldBuffer^, Buffer^, Field.DataSize);
        Exit;
      end;

  Allocated := false;
  case vTypeDispositionField of
    dfNormal:
      begin
        if (FCurrentRecord < 0) and (drsInCacheDelete in FRunState) then
          Exit;
        vInspectRecno := FCurrentRecord;
        if (drsInFilterProc in FRunState) or (drsInGetRecordProc in FRunState) then
          begin
            case FCacheModelOptions.FCacheModelKind of
              cmkStandard:
                if (vInspectRecno < 0) or (vInspectRecno >= FRecordCount) then
                  Exit;
              cmkLimitedBufferSize:
                if (vInspectRecno < vPartition^.BeginPartRecordNo) or (vInspectRecno > vPartition^.EndPartRecordNo) then
                  Exit;
            end;
            GetInspectRecBuffer;
          end
        else
          case State of
            dsNewValue: Buff := GetNewBuffer;
            dsOldValue:
              begin
                Buff := GetOldBuffer;
                if Field.FieldKind in [fkCalculated, fkLookup] then
                  GetCalcFields(Buff);
                Allocated := True;
              end;
            else
              Buff := GetActiveBuf;
          end
      end;
    dfRRecNumber:
      begin
        if (vInspectRecno < 0) or (vInspectRecno > FRecordCount) then
          Exit;
        GetInspectRecBuffer
      end;
  end;

  try
    if (Buff = nil) then
      Exit;

    if (State <> dsOldValue) and (not IsVisibleStat(Buff)) then
      Exit;

    CurrentRecord := PRecordData(Buff);

    if (Field.FieldNo > 0) and (Field.FieldNo <= vrdFieldCount) and IsValidRecord then
      begin
        Result := not CurrentRecord^.rdFields[Field.FieldNo].fdIsNull;
        if (Buffer = nil) then
          Exit;
        if Result then
          begin
            fi := vFieldDescrList[Field.FieldNo - 1];
            Data := Buff + fi^.fdDataOfs;
            case fi^.fdDataType of
              SQL_VARYING, SQL_TEXT:
                begin
                  { if fi^.fdDataSize > Field.DataSize then
                FIBError(feFieldSizeMismatch,[Name,Field.FieldName]); }
                  // LengthExp
                  if fi^.fdIsSeparateString then
                    begin
                      L := PInteger(Data)^;
                      Inc(Data, SizeOf(Integer));
                      if not(drsInFieldAsData in FRunState) then
                        if (poTrimCharFields in FOptions) then
                          begin
                            while (L > 0) and (PAnsiChar(Data)[L - 1] = ' ') do
                              Dec(L);
                          end;
                    end
                  else if (Field.DataType = ftGuid) or fi^.fdIsDBKey or (drsInFieldAsData in FRunState) then
                    L := fi^.fdDataSize - 1
                  else if TDataBuffer(Data)[0] <> ZeroData then
                    begin
                      L := 0;
                      while (L < fi^.fdDataSize) and (PAnsiChar(Data)[L] <> #0) do
                        Inc(L);
                      if (poTrimCharFields in FOptions) then
                        begin
                          while (L > 0) and (PAnsiChar(Data)[L - 1] = ' ') do
                            Dec(L);
                        end;
                    end
                  else
                    L := 0;
                  if Field is TFIBStringField then
                    TFIBStringField(Field).FValueLength := L
                  else if Field is TFIBWideStringField then
                    TFIBWideStringField(Field).FValueLength := L;
                  if L = 0 then
                    begin
                      case Field.DataType of
                        ftWideString: PWideChar(Buffer)[0] := #0
                        else
                          TDataBuffer(Buffer)[0] := ZeroData;
                      end
                    end
                  else
                    begin
                      case Field.DataType of
                        ftString:
                          (* {$IFNDEF UNICODE_TO_STRING_FIELDS}
                      // For old version IB
                      // Unicode connect + non unicode field

                      if  (Field is TFIBStringField) and TFIBStringField(Field).FNeedUnicodeConvert
                      and not (drsInFieldAsData in FRunState)
                      then
                      begin
                      DoUTFStringValue
                      end
                      else
                      {$ENDIF} *)
                          begin
                            Move(Data^, Buffer^, L);
                            TFIBStringField(Field).FValueLength := L;
                            TDataBuffer(Buffer)[L] := ZeroData
                          end;
                        ftWideString:
                          begin
                            if (StringFieldCodePage(Field) = FIBCodePageUTF8) and not(drsInFieldAsData in FRunState) then
                              begin
                                L := Utf8ToUnicode(PWideChar(Buffer), L + 1, PAnsiChar(Data), L);
                                if L > Field.Size then
                                  L := Field.Size;
                                PWideChar(Buffer)[L] := #0
                              end
                            else
                              begin
                                Move(Data^, Buffer^, L);
                                TDataBuffer(Buffer)[L] := ZeroData;
                              end;
                          end;
                        ftGuid:
                          begin
                            GUIDAsStringToPChar(PGuid(Data), Buffer);
                            TDataBuffer(Buffer)[38] := ZeroData
                          end
                      end;
                    end;
                end;
              SQL_FLOAT: PDouble(Buffer)^ := PSingle(Data)^;
              SQL_LONG:
                if fi^.fdDataScale <> 0 then
                  PDouble(Buffer)^ := PLong(Data)^ * E10[fi^.fdDataScale]
                else
                  PLong(Buffer)^ := PLong(Data)^;
              SQL_SHORT:
                if fi^.fdDataScale <> 0 then
                  PDouble(Buffer)^ := PShort(Data)^ * E10[fi^.fdDataScale]
                else
                  PShort(Buffer)^ := PShort(Data)^;
              SQL_TIMESTAMP: PDouble(Buffer)^ := PDouble(Data)^;
              SQL_TYPE_TIME, SQL_TYPE_DATE: PLong(Buffer)^ := PLong(Data)^;
              SQL_INT128, SQL_DEC16, SQL_DEC34:
                if not CacheToBcd(fi, Data, TBcd(Buffer^)) then
                  if Field = vRawDecimalField then
                    begin
                      Move(Data^, vRawDecimalData, fi^.fdDataSize);
                      vRawDecimalReturned := True;
                      Result := false;
                    end
                  else
                    FIBError(feInvalidDataConversion, [nil]);
              SQL_TIME_TZ_EX: PInteger(Buffer)^ := FBTimeTZToMSecs(PISC_TIME_TZ_EX(Data)^);
              SQL_TIMESTAMP_TZ_EX:
                PDouble(Buffer)^ := FBTimeStampTZToMSecs
                  (PISC_TIMESTAMP_TZ_EX(Data)^);
              else
                begin
                  // Avoid BCD Overflow
                  if (Field.DataType = ftBCD) and (not(Field is TFIBBCDField) or not TFIBBCDField(Field).FDataAsComp)
                    then
                    begin
                      // from TDataPacketWriter
                      Result := Int64ToBCD(PInt64(Data)^, -fi^.fdDataScale, TBcd(Buffer^))
                    end
                  else
                    Move(Data^, Buffer^, fi^.fdDataSize);
                end;
            end;
          end
      end
    else if (Field.FieldNo < 0) then
      begin
        // Calculated Fields
        Result := Boolean(Buff[FCalcFieldsOffset + Field.Offset]);
        if (Buffer = nil) then
          Exit;
        if Result then
          begin
            Move(Buff[FCalcFieldsOffset + Field.Offset + SizeOf(Boolean)], Buffer^, Field.DataSize);
          end;
      end;

  finally
    if Allocated then
      FreeRecordBuffer(Buff);
  end;
end;

function TFIBCustomDataSet.GetStateFieldValue(State: TDataSetState; Field: TField): Variant;
var
  SaveState: TDataSetState;
begin
  if (Self.State = dsInsert) and (State = dsOldValue) then
    Result := Null
  else
    begin
      case Field.FieldKind of
        fkData, fkInternalCalc: Result := inherited GetStateFieldValue(State, Field);
        // fkData, fkInternalCalc,
        fkCalculated, fkLookup:
          case State of
            dsNewValue, dsCurValue: Result := Field.Value;
            dsOldValue:
              begin
                SaveState := Self.State;
                try
                  SetTempState(State);
                  Result := Field.AsVariant
                finally
                  RestoreState(SaveState);
                end;
              end;
            else
              Result := Null
          end;
      end;
    end;
end;

(*
  * GetRecNo and SetRecNo both operate off of 1-based indexes as
  * opposed to 0-based indexes.
  * This is because we want LastRecordNumber/RecordCount = 1
*)
function TFIBCustomDataSet.GetRealRecNo: Integer;
var
  ActBuff: TRecordBuffer;
begin
  ActBuff := GetActiveBuf;
  if ActBuff = nil then
    Result := 0
  else
    Result := PRecordData(ActBuff)^.rdRecordNumber + 1;
end;

function TFIBCustomDataSet.GetRecNo: Integer;
begin
  if State = dsFilter then
    Result := FCurrentRecord
  else
    Result := GetRealRecNo
end;

procedure TFIBCustomDataSet.ClearCalcFields(Buffer: TRecordBuffer);
begin
  // For Set LookUp null value (D7 and more)
  if (FDisableCalcFieldsCount = 0) and (CalcFieldsSize > 0) then
    begin
      if State in [dsEdit, dsInsert] then
        begin
          FillChar(Buffer[FCalcFieldsOffset], FRecordBufferSize - FCalcFieldsOffset, 0);
        end
    end;
end;

procedure TFIBCustomDataSet.GetCalcFields(Buffer: TRecordBuffer);
begin
  if (FDisableCalcFieldsCount = 0) and (CalcFieldsSize > 0) then
    begin
      if not vCalcFieldsSavedCache then
        inherited GetCalcFields(Buffer)
      else if not GetBit(PRecordData(Buffer)^.rdFlags, 7) or (drsInRefreshClientFields in FRunState) then
        begin
          inherited GetCalcFields(Buffer);
          PRecordData(Buffer)^.rdFlags := SetBit(PRecordData(Buffer)^.rdFlags, 7, True);
          WriteRecordCache(PRecordData(Buffer)^.rdRecordNumber, Buffer);
        end
    end;
end;

procedure TFIBCustomDataSet.ShiftCurRec;
var
  i: Integer;
begin
  Inc(FCurrentRecord, FCacheModelOptions.FBufferChunks);
  Inc(vPartition^.EndPartRecordNo, FCacheModelOptions.FBufferChunks);
  Inc(vPartition^.BeginPartRecordNo, FCacheModelOptions.FBufferChunks);

  for i := 0 to BufferCount - 1 do
    begin
      Inc(PRecordData(Buffers[i]).rdRecordNumber, BufferChunks);
      // VCL Cache
      // Refresh cache of dataset
    end;
end;

function TFIBCustomDataSet.GetRecord(Buffer: TRecordBuffer; GetMode: TGetMode; DoCheck: Boolean): TGetResult;
var
  Action: TDataAction;

  procedure ChangeCurSelect(NewSelect: TFIBQuery);
  begin
    FQCurrentSelect.Close;
    FQCurrentSelect := NewSelect;
    AssignSQLObjectParams(FQCurrentSelect, [Self]);
    FQCurrentSelect.Params.AssignValues(FQSelect.Params);
    if FQCurrentSelect.Open then
      FQCurrentSelect.Close;
    FQCurrentSelect.ExecQuery;
  end;

begin
  Action := daAbort;
  Result := grError;
  Include(FRunState, drsInGetRecordProc);
  try
    case GetMode of
      gmCurrent:
        case FCacheModelOptions.CacheModelKind of
          cmkStandard:
            begin

              if (FCurrentRecord >= 0) then
                begin
                  if FCurrentRecord < FRecordCount then
                    ReadRecordCache(FCurrentRecord, Buffer, false)
                  else
                    begin
                      while (not FQSelect.Eof) and (FCurrentRecord >= FRecordCount) and (FQSelect.Next <> nil) do
                        begin
                          FetchCurrentRecordToBuffer(FQSelect, FRecordCount, Buffer);
                          Inc(FRecordCount);
                        end;
                      Dec(FCurrentRecord);
                      if (FCurrentRecord >= 0) then
                        ReadRecordCache(FCurrentRecord, Buffer, false)
                    end;
                  Result := grOk;
                end
              else
                Result := grBOF;
            end;
          cmkLimitedBufferSize:
            begin
              if (FCurrentRecord >= vPartition^.BeginPartRecordNo) then
                begin
                  if (FCurrentRecord <= vPartition^.EndPartRecordNo) and (FCurrentRecord >= 0) then
                    begin
                      ReadRecordCache(FCurrentRecord, Buffer, false);
                      Result := grOk;
                    end
                  else if vPartition^.IncludeEof then
                    Result := grEOF
                  else
                    Result := grError;
                end
              else if vPartition^.IncludeBof then
                Result := grBOF
              else
                Result := grError;
            end;
        end;
      gmNext:
        begin
          Result := grOk;
          case FCacheModelOptions.CacheModelKind of
            cmkStandard:
              begin
                if (FCurrentRecord < FRecordCount - 1) then
                  begin
                    Inc(FCurrentRecord);
                    ReadRecordCache(FCurrentRecord, Buffer, false)
                  end
                else
                  begin
                    if FCurrentRecord = FRecordCount then
                      Result := grEOF
                    else if FCurrentRecord = FRecordCount - 1 then
                      begin
                        if (FQSelect.Eof) then
                          Result := grEOF
                        else
                          begin
                            if FQSelect.Next <> nil then
                              begin
                                Inc(FCurrentRecord);
                                if (FQSelect.Eof) then
                                  Result := grEOF
                              end
                            else
                              Result := grEOF;
                          end;

                        if (Result <> grEOF) then
                          begin
                            FetchCurrentRecordToBuffer(FQSelect, FCurrentRecord, Buffer);
                            Inc(FRecordCount);
                          end;
                      end
                  end;
              end;
            cmkLimitedBufferSize:
              if (FCurrentRecord + 1 >= vPartition^.BeginPartRecordNo) and
                (FCurrentRecord + 1 <= vPartition^.EndPartRecordNo) then
                begin
                  Inc(FCurrentRecord);
                  ReadRecordCache(FCurrentRecord, Buffer, false)
                end
              else if (FQCurrentSelect = FQSelect) or (FQCurrentSelect = FQSelectPart) then
                begin
                  if (FQCurrentSelect.Eof) then
                    begin
                      vPartition^.IncludeEof := True;
                      Result := grEOF;
                    end
                  else
                    begin
                      FQCurrentSelect.Next;
                      if (FCurrentRecord > -1) or (not FQCurrentSelect.Eof) then
                        Inc(FCurrentRecord);
                      if FQCurrentSelect.Eof then
                        begin
                          vPartition^.IncludeEof := True;
                          Result := grEOF;
                        end
                      else
                        begin
                          FetchCurrentRecordToBuffer(FQCurrentSelect, FCurrentRecord, Buffer);
                          Inc(vPartition^.EndPartRecordNo);
                          if vPartition^.BeginPartRecordNo < 0 then
                            vPartition^.BeginPartRecordNo := FCurrentRecord
                          else if (vPartition^.EndPartRecordNo -
                            vPartition^.BeginPartRecordNo) >= FCacheModelOptions.FBufferChunks then
                            begin
                              Inc(vPartition^.BeginPartRecordNo);
                              vPartition^.IncludeBof := false;
                            end;
                          FRecordCount := vPartition^.EndPartRecordNo - vPartition^.BeginPartRecordNo + 1;
                        end;
                    end;
                end
              else
                begin
                  // change the direction
                  if vPartition^.IncludeEof then
                    Result := grEOF
                  else
                    begin
                      ChangeCurSelect(FQSelectPart);
                      if FQCurrentSelect.Next = nil then
                        begin
                          vPartition^.IncludeEof := True;
                          Result := grEOF
                        end
                      else
                        begin
                          Inc(FCurrentRecord);
                          if (vPartition^.EndPartRecordNo - vPartition^.BeginPartRecordNo) >=
                            FCacheModelOptions.FBufferChunks - 1 then
                            begin
                              FRecordsCache.MoveRecord
                              (vPartition^.BeginPartRecordNo mod FCacheModelOptions. FBufferChunks,
                                FCurrentRecord mod FCacheModelOptions.FBufferChunks);
                              Inc(vPartition^.BeginPartRecordNo);
                              vPartition^.IncludeBof := false;
                            end;
                          Inc(vPartition^.EndPartRecordNo);
                          FetchCurrentRecordToBuffer(FQCurrentSelect, FCurrentRecord, Buffer);
                          Result := grOk;
                        end;
                    end;
                end;
          end;
        end;
      gmPrior:
        begin
          case FCacheModelOptions.CacheModelKind of
            cmkStandard:
              begin
                if (FCurrentRecord > 0) and (FCurrentRecord <= FRecordCount) then
                  begin
                    Dec(FCurrentRecord);
                    ReadRecordCache(FCurrentRecord, Buffer, false);
                    Result := grOk;
                  end
                else if (FCurrentRecord = -1) then
                  Result := grBOF
                else if (FCurrentRecord = 0) then
                  begin
                    Dec(FCurrentRecord);
                    Result := grBOF;
                  end
              end;
            cmkLimitedBufferSize:
              begin
                if (FCurrentRecord - 1 >= vPartition^.BeginPartRecordNo) and
                  (FCurrentRecord - 1 <= vPartition^.EndPartRecordNo) then
                  begin
                    Dec(FCurrentRecord);
                    if (FCurrentRecord = -1) then
                      begin
                        vPartition^.IncludeBof := True;
                        Result := grBOF
                      end
                    else
                      begin
                        ReadRecordCache(FCurrentRecord, Buffer, false);
                        Result := grOk;
                      end
                  end
                else if (FCurrentRecord = -1) then
                  begin
                    vPartition^.IncludeBof := True;
                    Result := grBOF
                  end
                else if (vPartition^.BeginPartRecordNo = FCurrentRecord) then
                  begin
                    if (FQCurrentSelect = FQSelectDesc) or (FQCurrentSelect = FQSelectDescPart) then
                      begin
                        if FQCurrentSelect.Next = nil then
                          begin
                            Dec(FCurrentRecord);
                            vPartition^.IncludeBof := True;
                            Result := grBOF
                          end
                        else
                          begin
                            Dec(FCurrentRecord);
                            if FCurrentRecord = -1 then
                              begin
                                ShiftCurRec;
                              end
                            else
                              begin
                                FRecordsCache.MoveRecord
                                (vPartition^.EndPartRecordNo mod BufferChunks,
                                  FCurrentRecord mod FCacheModelOptions.FBufferChunks);
                                vPartition^.IncludeEof := false;
                              end;

                            Dec(vPartition^.BeginPartRecordNo);
                            // 08.2012
                            with vPartition^ do
                              if EndPartRecordNo - BeginPartRecordNo >= FCacheModelOptions.FBufferChunks then
                                Dec(vPartition^.EndPartRecordNo);
                            // ^^^^^08.2012

                            FetchCurrentRecordToBuffer(FQCurrentSelect, FCurrentRecord, Buffer);
                            Result := grOk;
                          end;
                      end
                    else
                      begin
                        if vPartition^.IncludeBof then
                          Result := grBOF
                        else
                          begin
                            // U-turn

                            ChangeCurSelect(FQSelectDescPart);
                            if FQCurrentSelect.Next = nil then
                              begin
                                vPartition^.IncludeBof := True;
                                Result := grBOF
                              end
                            else
                              begin
                                Dec(FCurrentRecord);

                                if FCurrentRecord = -1 then
                                  ShiftCurRec;

                                if (vPartition^.EndPartRecordNo -
                                  vPartition^.BeginPartRecordNo) > FCacheModelOptions.FBufferChunks then
                                  begin
                                    FRecordsCache.MoveRecord
                                    (vPartition^.EndPartRecordNo mod FCacheModelOptions. FBufferChunks,
                                      FCurrentRecord mod FCacheModelOptions. FBufferChunks);
                                    vPartition^.IncludeEof := false;
                                  end;
                                Dec(vPartition^.BeginPartRecordNo);
                                // 08.2012
                                with vPartition^ do
                                  if EndPartRecordNo - BeginPartRecordNo >= FCacheModelOptions.FBufferChunks then
                                    Dec(vPartition^.EndPartRecordNo);
                                // ^^^^^08.2012

                                FetchCurrentRecordToBuffer(FQCurrentSelect, FCurrentRecord, Buffer);
                                Result := grOk;
                              end;
                          end;
                      end;
                  end;
              end;
          end;
        end;
    end;
    if Result = grOk then
      Result := AdjustCurrentRecord(Buffer, GetMode);
    if Result = grOk then
      with PRecordData(Buffer)^ do
        begin
          rdBookmarkFlag := bfCurrent;
          GetCalcFields(Buffer);
        end
    else if (Result = grEOF) and Assigned(Buffer) then
      begin
        PRecordData(Buffer)^.rdBookmarkFlag := bfEOF;
      end
    else if (Result = grBOF) and Assigned(Buffer) then
      begin
        PRecordData(Buffer)^.rdBookmarkFlag := bfBOF;
      end
    else if (Result = grError) and Assigned(Buffer) then
      begin
        PRecordData(Buffer)^.rdBookmarkFlag := bfEOF;
      end;
  except
    On E: EDatabaseError do
      begin
        Exclude(FRunState, drsInGetRecordProc);
        Action := daFail;
        if Assigned(FOnGetRecordError) then
          FOnGetRecordError(Self, E, Action);
        case Action of
          daFail: raise;
          daAbort: Abort;
        end;
      end;
  end;
  Exclude(FRunState, drsInGetRecordProc);
end;

function TFIBCustomDataSet.GetRecordCount: Integer;
begin

  if not UniDirectional then
    Result := FRecordCount - FDeletedRecords
  else if FRecordCount < FCacheModelOptions.FBufferChunks then
    Result := FRecordCount - FDeletedRecords
  else
    Result := FCacheModelOptions.FBufferChunks;

end;

function TFIBCustomDataSet.GetRecordSize: Word;
begin
  Result := FRecordBufferSize;
end;

procedure TFIBCustomDataSet.RefreshMasterDS;
var
  mdVisRecno: Boolean;
begin
  mdVisRecno := false;
  if (DataSource <> nil) and (DataSource.DataSet <> nil) then
    try
      if DataSource.DataSet is TFIBCustomDataSet then
        begin
          mdVisRecno := poVisibleRecno in TFIBCustomDataSet(DataSource.DataSet).Options;
          if mdVisRecno then
            TFIBCustomDataSet(DataSource.DataSet).Options :=
              TFIBCustomDataSet(DataSource.DataSet).Options - [poVisibleRecno]
        end;
      DataSource.DataSet.Refresh;
    finally
      if mdVisRecno then
        TFIBCustomDataSet(DataSource.DataSet).Options :=
          TFIBCustomDataSet(DataSource.DataSet).Options + [poVisibleRecno]
    end;
end;

procedure TFIBCustomDataSet.AutoStartUpdateTransaction;
begin
  if (UpdateTransaction <> nil) then
    if not UpdateTransaction.InTransaction and (poStartTransaction in Options) then
      UpdateTransaction.StartTransaction;
end;

procedure TFIBCustomDataSet.AutoCommitUpdateTransaction;
begin
  if FAutoCommit and (UpdateTransaction <> nil) then
    with UpdateTransaction do
      if UpdateTransaction.InTransaction then
        begin
          if (UpdateTransaction <> Transaction) and (TimeoutAction <> TACommitRetaining) then
            UpdateTransaction.Commit
          else
            CommitRetaining;
        end;
end;

procedure TFIBCustomDataSet.SwapRecords(Recno1, Recno2: Integer);
var
  R1, R2: TRecordBuffer;
begin
  if Recno1 = Recno2 then
    Exit;
  if (Recno1 < 0) or (Recno2 < 0) then
    Exit;
  if (Recno1 > FRecordCount) or (Recno2 > FRecordCount) then
    Exit;
  R1 := AllocRecordBuffer;
  R2 := AllocRecordBuffer;
  try
    ReadRecordCache(Recno1 - 1, R1, false);
    ReadRecordCache(Recno2 - 1, R2, false);
    PRecordData(R1)^.rdRecordNumber := Recno2 - 1;
    PRecordData(R2)^.rdRecordNumber := Recno1 - 1;
    WriteRecordCache(Recno1 - 1, R2);
    WriteRecordCache(Recno2 - 1, R1);
    RefreshClientFields(True);
  finally
    FreeRecordBuffer(R1);
    FreeRecordBuffer(R2);
  end;
end;

// InsertRecord, AppendRecord: the new record is positioned as by Insert, Append.
// AddRecord calls the TRecBuf overload, TDataSet does not forward it to Pointer.
{$IFDEF D_23}

procedure TFIBCustomDataSet.InternalAddRecord(Buffer: TRecBuf; Append: Boolean);
{$ELSE}

procedure TFIBCustomDataSet.InternalAddRecord(Buffer: Pointer; Append: Boolean);
{$ENDIF}
begin
  if Append then
    begin
      // also when UniDirectional, as Append + Post does
      InternalLast;
      SetBookmarkFlag(TRecordBuffer(Buffer), bfEOF);
    end
  else if not IsEmpty then
    PRecordData(Buffer)^.rdRecordNumber := FCurrentRecord;
  InternalPost;
end;

procedure TFIBCustomDataSet.InternalCancel;
var
  Buff: TRecordBuffer;
begin
  inherited InternalCancel;
  Buff := GetActiveBuf;
  if Buff <> nil then
    begin
      if (State = dsInsert) then
        begin
          if FRecordCount = 0 then
            FCurrentRecord := -1
          else
            begin
              case GetBookmarkFlag(Buff) of
                bfEOF:
                  case CacheModelOptions.CacheModelKind of
                    cmkStandard: FCurrentRecord := RecordCount - 1;
                    cmkLimitedBufferSize: FCurrentRecord := vPartition^.EndPartRecordNo
                  end;
                else
                  Inc(FCurrentRecord);
              end;
            end;
        end;
    end;
  UpdateFieldStreams(Buff, ufsCancel, false, false);
end;

procedure TFIBCustomDataSet.CloseCursor;
begin
  inherited CloseCursor;
  FQSelect.Close;
  if csDesigning in ComponentState then
    UnPrepare;
end;

procedure TFIBCustomDataSet.InternalClose;
begin
  ClearFieldStreamList;
  FCurrentRecord := -1;
  FOpen := false;
  FRecordCount := 0;
  FDeletedRecords := 0;
  FRecordSize := 0;

  FBPos := 0;
  FOBPos := 0;
  FBEnd := 0;
  FOBEnd := 0;
  FRecordsCache.Free;
  FRecordsCache := nil;
  BindFields(false); // Unbind the fields
  if DefaultFields then
    DestroyFields;
  vFieldDescrList.Clear;
  FCachedActive := false;
end;

procedure TFIBCustomDataSet.InternalDelete;
var
  Buff: TRecordBuffer;
  iCurScreenState: Integer;
begin
  ChangeScreenCursor(iCurScreenState);
  try
    Buff := GetActiveBuf;
    // Cannot delete a record without a FQDelete query existing.
    if CanDelete then
      begin
        if not CachedUpdates then
          begin
            InternalDeleteRecord(FQDelete, Buff);
            if FCacheModelOptions.CacheModelKind = cmkLimitedBufferSize then
              InternalFullRefresh(false);

          end
        else
          begin
            with PRecordData(Buff)^ do
              begin
                if TCachedUpdateStatus(rdFlags and 7) = cusInserted then
                  begin
                    TCachedUpdateStatus(rdFlags) := cusUninserted;
                    Dec(FCountUpdatesPending)
                  end
                else
                  begin
                    if not(drsInCacheRefresh in FRunState) then
                      begin
                        TCachedUpdateStatus(rdFlags) := cusDeleted;
                        Inc(FCountUpdatesPending);
                      end;
                  end;
              end;
            WriteRecordCache(PRecordData(Buff)^.rdRecordNumber, Buff);
          end;
        Inc(FDeletedRecords);
        FUpdatesPending := FCountUpdatesPending > 0;
      end
    else
      FIBError(feCannotDelete, [CmpFullName(Self)]);
    FFilteredCacheInfo.AllRecords := -1;
  finally
    RestoreScreenCursor(iCurScreenState);
  end;
end;

procedure TFIBCustomDataSet.InternalFirst;
begin
  case FCacheModelOptions.CacheModelKind of
    cmkStandard: FCurrentRecord := -1;
    cmkLimitedBufferSize:
      if (FQCurrentSelect <> FQSelect) or (vPartition^.BeginPartRecordNo > 0) then
        begin
          FQCurrentSelect.Close;
          if FQSelect.Open then
            FQSelect.Close;
          FQSelect.ExecQuery;
          FQCurrentSelect := FQSelect;
          with vPartition^ do
            begin
              BeginPartRecordNo := -1;
              EndPartRecordNo := -1;
              IncludeEof := false;
              IncludeBof := True;
            end;
        end;
  end;
  FCurrentRecord := -1;
end;

type
  PBookMark = ^TBookMark;

  // {$DEFINE DEBUG_COMPARE_BOOKMARK}
function TFIBCustomDataSet.CompareBookMarkAndRecno(BookMark: TBookMark; Rno: Integer; OnlyFields: Boolean = false): Boolean;
var
  TempBuf: TRecordBuffer;
  TempBookMark: PBookMark;
{$IFDEF DEBUG_COMPARE_BOOKMARK}
  s, S1: string;
{$ENDIF}
begin
  TempBuf := AllocRecordBuffer;
  GetMem(TempBookMark, BookmarkSize);
  try
    ReadRecordCache(Rno, TempBuf, false);
    GetBookmarkData(TempBuf, TempBookMark);
    PFIBBookMark(TempBookMark)^.bActiveRecord := PFIBBookMark(BookMark)
      ^.bActiveRecord;
    if OnlyFields then
      PFIBBookMark(TempBookMark)^.bRecordNumber := PFIBBookMark(BookMark)
        ^.bRecordNumber;
{$IFDEF DEBUG_COMPARE_BOOKMARK}
    SetLength(s, BookmarkSize);
    SetLength(S1, BookmarkSize);
    Move(BookMark^, s[1], BookmarkSize);
    Move(TempBookMark^, S1[1], BookmarkSize);
{$ENDIF}
    Result := CompareMem(TempBookMark, BookMark, BookmarkSize - 1);
  finally
    FreeMem(TempBuf);
    FreeMem(TempBookMark);
  end;
end;

function TFIBCustomDataSet.RefreshAround(BaseQuery: TFIBQuery;
  var BaseRecNum: Integer; IgnoreEmptyBaseQuery: Boolean = True;
  ReopenBaseQuery: Boolean = True): Boolean;

var
  RecShifted: Boolean;

  procedure ExecCurSelect(aCurSelect: TFIBQuery; SourceObject: ISQLObject);
  begin
    aCurSelect.Close;
    AssignSQLObjectParams(aCurSelect, [SourceObject]);
    aCurSelect.Params.AssignValues(FQSelect.Params);
    aCurSelect.ExecQuery;
  end;

  function FetchAround(aCurSelect: TFIBQuery; RecordsLimit: Integer; Arrow: SmallInt; FromRecNum: Integer = -1): Boolean;
  var
    i: Integer;
  begin
    if FromRecNum = -1 then
      FCurrentRecord := BaseRecNum
    else
      FCurrentRecord := FromRecNum;
    i := RecordsLimit;
    Result := false;
    while (i > 0) and (aCurSelect.Next <> nil) do
      begin
        Result := True;
        Inc(FCurrentRecord, Arrow);
        if FCurrentRecord = -1 then
          begin
            ShiftCurRec;
            RecShifted := True;
          end;

        FetchRecordToCache(aCurSelect, FCurrentRecord);
        if Arrow < 0 then
          begin
            vPartition^.BeginPartRecordNo := FCurrentRecord;
            if vPartition^.EndPartRecordNo = -1 then
              vPartition^.EndPartRecordNo := vPartition^.BeginPartRecordNo
          end
        else
          begin
            vPartition^.EndPartRecordNo := FCurrentRecord;

            if vPartition^.BeginPartRecordNo = -1 then
              vPartition^.BeginPartRecordNo := vPartition^.EndPartRecordNo;
          end;
        Dec(i);
      end;
    if aCurSelect.Eof then
      if Arrow < 0 then
        vPartition^.IncludeBof := True
      else
        vPartition^.IncludeEof := True;
  end;

var
  RecordSource: ISQLObject;
  EmptyDataSet: Boolean;
  NotFetchedCount: Integer;
begin
  with BaseQuery do
    begin
      if ReopenBaseQuery then
        begin
          Close;
          Params.AssignValues(FQSelect.Params);
          ExecQuery;
          Next;
          Result := not Eof;
        end
      else
        Result := RecordCount > 0;

    end;
  EmptyDataSet := True;
  if Result or (not IgnoreEmptyBaseQuery) then
    begin
      if BaseRecNum < (FCacheModelOptions.FBufferChunks div 2) then
        BaseRecNum := FCacheModelOptions.FBufferChunks div 2;

      if Result then
        begin
          EmptyDataSet := false;
          FetchRecordToCache(BaseQuery, BaseRecNum);
          vPartition^.BeginPartRecordNo := BaseRecNum;
          vPartition^.EndPartRecordNo := BaseRecNum;
          RecordSource := BaseQuery
        end
      else
        begin
          RecordSource := Self;
        end;

      vPartition^.IncludeBof := false;
      vPartition^.IncludeEof := false;

      ExecCurSelect(FQSelectDescPart, RecordSource);
      ExecCurSelect(FQSelectPart, RecordSource);
      if not Result then
        begin
          vPartition^.BeginPartRecordNo := -1;
          vPartition^.EndPartRecordNo := -1;
        end;

      RecShifted := false;

      if FetchAround(FQSelectDescPart, FCacheModelOptions.FBufferChunks div 2, -1) then
        EmptyDataSet := false;

      if not Result then
        Dec(BaseRecNum);

      NotFetchedCount :=
      // FCacheModelOptions.FBufferChunks-(vPartition^.EndPartRecordNo-vPartition^.BeginPartRecordNo+2);
        FCacheModelOptions.FBufferChunks - (vPartition^.EndPartRecordNo - vPartition^.BeginPartRecordNo + 1);
      // 08.2012
      if FetchAround(FQSelectPart, NotFetchedCount, 1) then
        EmptyDataSet := false;

      NotFetchedCount :=
      // FCacheModelOptions.FBufferChunks-(vPartition^.EndPartRecordNo-vPartition^.BeginPartRecordNo+2);
        FCacheModelOptions.FBufferChunks - (vPartition^.EndPartRecordNo - vPartition^.BeginPartRecordNo + 1);
      // 08.2012
      if NotFetchedCount > 0 then
        FetchAround(FQSelectDescPart, NotFetchedCount, -1, vPartition^.BeginPartRecordNo);

      FQSelectDescPart.Close;
      if RecShifted then
        Inc(BaseRecNum, FCacheModelOptions.FBufferChunks);
      if Result then
        FCurrentRecord := BaseRecNum
      else if EmptyDataSet then
        FCurrentRecord := -1
      else
        FCurrentRecord := BaseRecNum + 1;
      FQCurrentSelect := FQSelectPart;

      BaseQuery.Close;
    end;
end;

{$IFDEF D_23}

procedure TFIBCustomDataSet.InternalGotoBookmark(BookMark: TBookMark);
{$ELSE}

procedure TFIBCustomDataSet.InternalGotoBookmark(BookMark: Pointer);
{$ENDIF}
var
  Rno: Integer;
  i: Integer;
  tf: TField;
  AddrValue: Pointer;
  KeyValues: array of Variant;
  vBcd: TBcd;
  fi: PFIBFieldDescr;

  procedure StdGotoBookMark;
  begin
    if Rno > -1 then
      begin
        MoveBy(PFIBBookMark(BookMark)^.bActiveRecord - ActiveRecord);
        FCurrentRecord := Rno;
      end;
  end;

  function InWorkArea: Boolean;
  begin
    Result := (Rno > -1) and (Rno >= vPartition^.BeginPartRecordNo) and (Rno <= (vPartition^.EndPartRecordNo));
  end;

begin
  if State <> dsBrowse then
    raise Exception.Create('Can''t use bookmark. DataSet not in browse mode');
  Include(FRunState, drsInGotoBookMark);
  // Resync enables them again, also for an invalid bookmark
  DisableControls;
  DisableScrollEvents;
  try
    if not BookmarkValid(TBookMark(BookMark)) then
      begin
        Inc(vLockResync);
        Exit;
      end;

    Rno := FRecordsCache.RecordByBookMark(PFIBBookMark(BookMark)^.bRecordNumber);
    case FCacheModelOptions.CacheModelKind of
      cmkStandard:
        if (FKeyFieldsForBookMark.Count = 0) or (vSimpleBookMark > 0) then
          StdGotoBookMark
        else
          begin
            SetLength(KeyValues, FKeyFieldsForBookMark.Count);
            for i := 0 to Pred(FKeyFieldsForBookMark.Count) do
              begin
                if Boolean(PAnsiChar(BookMark) [Integer(FKeyFieldsForBookMark.Objects[i])]) then
                  KeyValues[i] := Null
                else
                  begin

                    tf := Self.FN(FKeyFieldsForBookMark[i]);
                    AddrValue := @PAnsiChar(BookMark)
                      [Integer(FKeyFieldsForBookMark.Objects[i]) + SizeOf(Boolean)];
                    fi := TimeZoneFieldDescr(Self, tf);
                    if fi <> nil then
                      KeyValues[i] := VarFromDateTime(TimeZoneCacheToDateTime(fi, AddrValue))
                    else if Assigned(tf) then
                      case tf.DataType of
                        ftSmallint: KeyValues[i] := PSmallint(AddrValue)^;
                        ftInteger: KeyValues[i] := PInteger(AddrValue)^;
                        ftFloat: KeyValues[i] := PDouble(AddrValue)^;
                        ftBCD:
                          begin
                            if (tf.Size = 0) then
                              begin
                                KeyValues[i] := PInt64(AddrValue)^
                              end
                            else
                              begin
                                Int64ToBCD(PInt64(AddrValue)^, -tf.Size, vBcd);
                                VarFMTBcdCreate(KeyValues[i], vBcd); ;
                                if tf.Size = 4 then
                                  KeyValues[i] := VarAsType(KeyValues[i], varCurrency);
                              end;
                          end;

                        ftString: KeyValues[i] := DecodeString(PAnsiChar(AddrValue), Length(PAnsiChar(AddrValue)),
                            StringFieldCodePage(tf));
                        ftWideString: KeyValues[i] := DecodeWideString(FIBByteString(PAnsiChar(AddrValue)),
                            StringFieldCodePage(tf));
                        ftDate: KeyValues[i] := IntDateToDateTime(PInteger(AddrValue)^);
                        // the bookmark keeps the field buffer format (msecs)
                        ftTime: KeyValues[i] := VarFromDateTime(PInteger(AddrValue)^ / MSecsPerDay);
                        ftDateTime:
                          KeyValues[i] := VarFromDateTime
                            (TimeStampToDateTime(MSecsToTimeStamp(PDouble(AddrValue)^)));
                        ftGuid: KeyValues[i] := GUIDAsString(PGuid(AddrValue)^);
                        ftLargeint: KeyValues[i] := PInt64(AddrValue)^;
                        ftFMTBcd: VarFMTBcdCreate(KeyValues[i], PBcd(AddrValue)^);
                      end;
                  end;
              end; // for
            if InternalLocate(FAutoUpdateOptions.KeyFields, KeyValues, []) then
              begin
                if not ControlsDisabled then
                  DisableControls; // Restore after Resync
                Include(FRunState, drsInGotoBookMark); // Restore after Resync
                MoveBy(PFIBBookMark(BookMark)^.bActiveRecord - ActiveRecord);
                FCurrentRecord := Rno
              end
          end;
      cmkLimitedBufferSize:
        begin
          if InWorkArea and CompareBookMarkAndRecno(BookMark, Rno) then
            begin
              StdGotoBookMark;
              Exit;
            end
          else
            begin
              for i := vPartition^.BeginPartRecordNo to vPartition^.
                EndPartRecordNo do
                begin
                  if CompareBookMarkAndRecno(BookMark, i, True) then
                    begin
                      MoveBy(PFIBBookMark(BookMark)^.bActiveRecord - ActiveRecord);
                      FCurrentRecord := FRecordsCache.BookMarkByRecord(i - 1);
                      Exit;
                    end;
                end;
              with FQBookMark do
                begin
                  if Open then
                    Close;

                  for i := 0 to Pred(FKeyFieldsForBookMark.Count) do
                    begin
                      if Boolean(PAnsiChar(BookMark) [Integer(FKeyFieldsForBookMark.Objects[i])]) then
                        ParamByName(LocateParamPrefix + FKeyFieldsForBookMark [i]).Clear
                      else
                        begin
                          tf := Self.FN(FKeyFieldsForBookMark[i]);
                          AddrValue := @PAnsiChar(BookMark)
                            [Integer(FKeyFieldsForBookMark.Objects[i]) + SizeOf(Boolean)];
                          fi := TimeZoneFieldDescr(Self, tf);
                          if fi <> nil then
                            // exact value with its time zone
                            CacheToTimeZoneParam
                            (ParamByName(LocateParamPrefix + FKeyFieldsForBookMark[i]), fi, AddrValue)
                          else if Assigned(tf) then
                            with ParamByName(LocateParamPrefix + FKeyFieldsForBookMark[i]) do
                              case tf.DataType of
                                ftSmallint: AsInteger := PSmallint(AddrValue)^;
                                ftInteger: AsInteger := PInteger(AddrValue)^;
                                ftFloat: AsDouble := PDouble(AddrValue)^;
                                ftString:
                                  AsString := DecodeString(PAnsiChar(AddrValue), Length(PAnsiChar(AddrValue)),
                                    StringFieldCodePage(tf));
                                ftWideString:
                                  AsWideString := DecodeWideString(FIBByteString(PAnsiChar(AddrValue)),
                                    StringFieldCodePage(tf));
                                ftDate: asDateTime := IntDateToDateTime(PInteger(AddrValue)^);
                                // the bookmark keeps the field buffer format (msecs)
                                ftTime: AsTime := PInteger(AddrValue)^ / MSecsPerDay;
                                ftDateTime:
                                  asDateTime := TimeStampToDateTime
                                    (MSecsToTimeStamp(PDouble(AddrValue)^));
                                ftLargeint: AsInt64 := PInt64(AddrValue)^;
                                ftFMTBcd: AsBcd := PBcd(AddrValue)^;
                              end;
                        end;
                    end; // for

                  if RefreshAround(FQBookMark, PFIBBookMark(BookMark)^.bRecordNumber) then
                    begin
                      MoveBy(PFIBBookMark(BookMark)^.bActiveRecord - ActiveRecord);
                      FCurrentRecord := PFIBBookMark(BookMark)^.bRecordNumber;
                    end
                  else
                    Inc(vLockResync);
                end;
            end;

        end
    end;
  except
    EnableControls;
    EnableScrollEvents;
    Exclude(FRunState, drsInGotoBookMark);
    raise
  end;
end;

procedure TFIBCustomDataSet.InternalHandleException;
begin
  if Assigned(Classes.ApplicationHandleException) then
    Classes.ApplicationHandleException(Self);
end;

procedure TFIBCustomDataSet.TryDesignPrepare;
var
  ForceConnect: Boolean;
  vLoginPrompt: Boolean;
begin
  if Assigned(Database) then
    begin
      ForceConnect := not Database.Connected;
      vLoginPrompt := Database.UseLoginPrompt;
      try
        if not Database.Connected then
          try
            Database.UseLoginPrompt := false;
            Database.Connected := True;
          except
            Database.UseLoginPrompt := vLoginPrompt;
            Exit
          end;
        if Assigned(Transaction) and Transaction.InTransaction then
          Prepare
        else if Assigned(Transaction) then
          if Transaction.InTransaction then
            begin
              Prepare;
            end
          else
            begin
              Transaction.StartTransaction;
              Prepare
            end;
      finally
        Database.UseLoginPrompt := vLoginPrompt;
        if ForceConnect and Database.Connected then
          Database.Connected := false
      end;
    end;

end;

procedure TFIBCustomDataSet.InternalInitFieldDefs;
var
  DataType: TFieldType;
  Size: Word;
  i, FieldNo: Integer;
  Name: string;
  isSmallInt: Boolean;
  vPrecision: Integer;

  RelFieldName, RelTabName: string;
  fi: TpFIBFieldInfo;
  tf: TField;
begin
  if drsInClone in FRunState then
    Exit;
  if not Prepared then
    begin
      if not(csDesigning in ComponentState) then
        Prepare
      else
        begin
          TryDesignPrepare;
        end;
      Exit;
    end;
  FieldDefs.BeginUpdate;
  try
    // Destroy any previously existing information...
    FieldDefs.Clear;
    for i := 0 to FQSelect.Current.Count - 1 do
      with FQSelect.Current[i].Data^ do
        begin
          // Get the field name
          Name := FQSelect.Current[i].AliasName;
          Size := 0;
          vPrecision := 0;
          case SQLType and not 1 of
            // All VARCHAR's must be converted to strings before recording
            // their values
            SQL_VARYING, SQL_TEXT:
              begin
                Size := sqllen;
                DataType := ftString;
                if Byte(SqlSubType) in Database.UnicodeCharSets then
                  begin
    {$IFNDEF UNICODE_TO_STRING_FIELDS}
                    DataType := ftWideString;
    {$ELSE}
                    DataType := ftString;
    {$ENDIF}
                    if not IsSysField(FQSelect.Current[i].SqlName) or not Database.ReturnDeclaredFieldSize then
                      Size := Size div Database.BytesInUnicodeChar
                        (Byte(SqlSubType));
                  end;
                tf := FindField(Name);
                if (tf <> nil) and (tf.Size <> Size) then
                  tf.Size := Size;

                if (psUseGuidField in PrepareOptions) and (Size = 16) then
                  begin
                    RelTabName := FQSelect.Current[i].RelationName;
                    RelFieldName := FQSelect.Current[i].SqlName;
                    fi := ListTableInfo.GetFieldInfo(Database, RelTabName, RelFieldName, false);
                    if Assigned(fi) and fi.CanBeGUID then
                      begin
                        DataType := ftGuid;
                        if (tf <> nil) then
                          tf.Size := 38;
                      end
                  end;

              end;
            // All Doubles/Floats should be cast to doubles.
            //
            SQL_DOUBLE, SQL_FLOAT:
              begin
                DataType := ftFloat;
              end;

            // SQL_LONG = 4 bytes
            SQL_SHORT, SQL_LONG:
              if (sqlscale < 0) then
                DataType := ftFloat
              else
                begin
                  isSmallInt := (sqllen <> 4) and ((FindField(Name) = nil) or (FindField(Name) is TSmallintField));
                  if psUseBooleanField in PrepareOptions then
                    begin
                      RelTabName := FQSelect.Current[i].RelationName;
                      RelFieldName := FQSelect.Current[i].SqlName;
                      if RelTabName = 'FIB$FIELDS_INFO' then
                        fi := nil
                      else
                        fi := ListTableInfo.GetFieldInfo(Database, RelTabName, RelFieldName, false);
                    end
                  else
                    begin
                      fi := nil;
                    end;
                  if ((fi <> nil) and fi.CanBeBoolean) then
                    DataType := ftBoolean
                  else
                    begin
                      tf := FindField(Name);
                      if Assigned(tf) and (tf.DataType = ftBoolean) then
                        DataType := ftBoolean
                      else if isSmallInt then
                        DataType := ftSmallint
                      else
                        DataType := ftInteger;
                    end;
                end;
            SQL_INT64:
              begin
                if (sqlscale = 0) then
                  begin
                    if psUseLargeIntField in PrepareOptions then
                      DataType := ftLargeint
                    else
                      DataType := ftBCD
                  end
                else if (sqlscale >= -4) or (psSQLINT64ToBCD in PrepareOptions) then
                  begin
                    DataType := ftBCD;
                    Size := -sqlscale;
                    tf := FindField(Name);
                    if tf <> nil then
                      if tf.Size <> Size then
                        tf.Size := Size;
                  end
                else
                  DataType := ftFloat;
              end;

            // SQL_DATE = 8 bytes
            SQL_TIMESTAMP: DataType := ftDateTime;
            SQL_TYPE_TIME: DataType := ftTime;
            SQL_TYPE_DATE: DataType := ftDate;
            // SQL_BLOB = variable
            SQL_BLOB:
              with Database do
                begin
                  Size := SizeOf(TISC_QUAD);
                  // if (sqlsubtype = 1) or true then
                  if (SqlSubType = 1) or (MemoSubTypesActive and IsMemoSubtype(SqlSubType)) then
                    begin
      {$IFDEF D2007+}
                      if (NeedUTFEncodeDDL and IsUnicodeConnect) and (Byte(sqlscale) in UnicodeCharSets) then
                        DataType := ftWideMemo
                      else
      {$ENDIF}
                        DataType := ftMemo
                    end
                  else
                    DataType := ftBlob;
                end;
            // SQL_ARRAY = variable

            SQL_ARRAY:
              begin
                Size := SizeOf(TISC_QUAD);
                DataType := ftBytes;
              end;
            SQL_INT128:
              begin
                DataType := ftFMTBcd;
                Size := -sqlscale;
                // NUMERIC/DECIMAL(38) or INT128 (sub type 0), which has up to 39 digits
                if SqlSubType = 0 then
                  vPrecision := 39
                else
                  vPrecision := 38;
              end;
            // DECFLOAT has a floating scale; half of the digits are fractional, see TFIBFMTBCDField
            SQL_DEC16:
              begin
                DataType := ftFMTBcd;
                Size := 8;
                vPrecision := 16;
              end;
            SQL_DEC34:
              begin
                DataType := ftFMTBcd;
                Size := 17;
                vPrecision := 34;
              end;
            SQL_TIME_TZ, SQL_TIME_TZ_EX: DataType := ftTime;
            SQL_TIMESTAMP_TZ, SQL_TIMESTAMP_TZ_EX: DataType := ftDateTime;
            IB_SQL_BOOLEAN, SQL_BOOLEAN: DataType := ftBoolean;
            else
              DataType := ftUnknown;
          end;
          FieldNo := i + 1;
          if DataType <> ftUnknown then
            begin
              if DataType = ftGuid then
                begin
                  with TFieldDef.Create(FieldDefs, Name, DataType, 38, false, FieldNo) do
                    InternalCalcField := false
                end
              else
                with TFieldDef.Create(FieldDefs, Name, DataType, Size, false, FieldNo) do
                  begin
                    InternalCalcField := false;
                    if vPrecision > 0 then
                      Precision := vPrecision;
                  end;
            end;
        end;
  finally
    FieldDefs.EndUpdate;
  end
end;

procedure TFIBCustomDataSet.InternalInitRecord(Buffer: TRecordBuffer);
var
  i: Integer;
begin
  FillChar(Buffer[0], FRecordBufferSize, #0);
  for i := 1 to vFieldDescrList.Capacity do
    PRecordData(Buffer)^.rdFields[i].fdIsNull := True;
end;

procedure TFIBCustomDataSet.SetBeforeFetchRecord(Value: TOnFetchRecord);
begin
  FBeforeFetchRecord := Value;
  if Assigned(FBeforeFetchRecord) then
    FQSelect.OnSQLFetch := DoOnSelectFetch
  else
    FQSelect.OnSQLFetch := nil
end;

procedure TFIBCustomDataSet.DoOnSelectFetch(RecordNumber: Integer; var StopFetching: Boolean);
begin
  if Assigned(FBeforeFetchRecord) then
    FBeforeFetchRecord(QSelect, RecordNumber, StopFetching);
end;

procedure TFIBCustomDataSet.InternalLast;
var
  iCurScreenState: Integer;
begin
  case FCacheModelOptions.CacheModelKind of
    cmkStandard:
      if (FQSelect.Eof) then
        begin
          if FRecordCount > 0 then
            FCurrentRecord := FRecordCount
          else
            FCurrentRecord := -1 // For Append
        end
      else
        begin
          ChangeScreenCursor(iCurScreenState);
          Include(FRunState, drsInFetchingAll);
          try
            try
              while (FQSelect.Next <> nil) do
                begin
                  FetchRecordToCache(FQSelect, FRecordCount);
                  Inc(FRecordCount);
                end;
            except
              try
                GetPriorRecord;
                GetPriorRecords;
              except
              end;
              raise;
            end;
          finally
            Exclude(FRunState, drsInFetchingAll);
            FCurrentRecord := FRecordCount;
            RestoreScreenCursor(iCurScreenState);
          end;
        end;
    cmkLimitedBufferSize:
      begin
        if State = dsInsert then
          begin
            FCurrentRecord := vPartition^.EndPartRecordNo + 1;
            Exit;
          end
        else if vPartition^.IncludeEof then
          begin
            FCurrentRecord := vPartition^.EndPartRecordNo + 1;
            Exit;
          end;

        ClearFieldStreamList;
        FQCurrentSelect.Close;
        if FQSelectDesc.Open then
          FQSelectDesc.Close;
        FQCurrentSelect := FQSelectDesc;

        FQCurrentSelect.Params.AssignValues(FQSelect.Params);
        FQCurrentSelect.ExecQuery;

        vPartition^.BeginPartRecordNo := MaxInt div 2;
        // vPartition^.BeginPartRecordNo :=200 div 2;
        vPartition^.EndPartRecordNo := vPartition^.BeginPartRecordNo - 1;

        FCurrentRecord := vPartition^.EndPartRecordNo;
        ChangeScreenCursor(iCurScreenState);
        try
          FRecordCount := 0;
          try
            while FQCurrentSelect.Next <> nil do
              begin
                FetchRecordToCache(FQCurrentSelect, FCurrentRecord);
                Dec(FCurrentRecord);
                Dec(vPartition^.BeginPartRecordNo);
                if (vPartition^.EndPartRecordNo - vPartition^.BeginPartRecordNo +
                  1 >= FCacheModelOptions.FBufferChunks) then
                  Break;
              end;
          except
          end;
          FCurrentRecord := vPartition^.EndPartRecordNo + 1;
          FRecordCount := vPartition^.EndPartRecordNo - vPartition^.BeginPartRecordNo + 1;
          vPartition^.IncludeBof := false;
          vPartition^.IncludeEof := True;

        finally
          RestoreScreenCursor(iCurScreenState);
        end;
      end;
  end;
end;

function TFIBCustomDataSet.MasterFieldsChanged: Boolean;
var
  pc, i: Integer;
  cur_param: TFIBXSQLVAR;
  cur_field: TField;
  vfi: PFIBFieldDescr;
  vData: Pointer;

  function MasParamChanged: Boolean;
  begin
    Result := false;
    if (cur_field <> nil) then
      begin
        Result := cur_field.IsNull xor cur_param.IsNull;
        if not Result then
          if ActiveTimeZoneData(cur_field, vfi, vData) then
            Result := TimeZoneParamChanged(cur_param, vfi, vData)
          else
            case cur_field.DataType of
              ftString, ftWideString: Result := (cur_param.AsString <> cur_field.AsString);
              ftSmallint, ftInteger, ftWord, ftBoolean: Result := (cur_param.AsLong <> cur_field.AsInteger);
              ftFloat, ftCurrency: Result := (cur_param.AsDouble <> cur_field.AsFloat);
              ftBCD:
                if (cur_field is TFIBBCDField) and (TFIBBCDField(cur_field).Size = 0) then
                  Result := (cur_param.AsInt64 <> TFIBBCDField(cur_field).AsInt64)
                else
                  Result := CompareBCD(cur_param.AsBcd, TFIBBCDField(cur_field).AsBcd) <> 0;

              ftDate: Result := (cur_param.AsDate <> cur_field.asDateTime);
              ftDateTime: Result := (cur_param.asDateTime <> cur_field.asDateTime);
              ftTime: Result := (cur_param.AsTime <> cur_field.asDateTime);
              ftGuid: Result := not IsEqualGUIDs(cur_param.AsGuid, TFIBGuidField(cur_field).AsGuid);
              ftLargeint: Result := cur_param.AsInt64 <> TFIBLargeIntField(cur_field).AsLargeInt;
              ftFMTBcd: Result := BcdCompare(cur_param.AsBcd, cur_field.AsBcd) <> 0;
            end;
      end;
  end;

begin
  Result := QSelect.MacroChanged;
  if Result then
    begin
      QSelect.ApplyMacro;
      Exit;
    end;
  pc := Params.Count - 1;
  if (DataSource <> nil) and (DataSource.DataSet <> nil) and (pc >= 0) then
    begin
      for i := 0 to pc do
        begin
          cur_param := Params[i];
          if IsMasParamName(cur_param.Name) then
            cur_field := DataSource.DataSet.FindField
              (FastCopy(cur_param.Name, 5, MaxInt))
          else
            cur_field := DataSource.DataSet.FindField(cur_param.Name);
          Result := MasParamChanged;
          if Result then
            Exit;
        end;
      pc := QSelect.OnlySrvParams.Count - 1;
      for i := 0 to pc do
        begin
          cur_param := QSelect.FindParam(QSelect.OnlySrvParams[i]);
          if cur_param = nil then
            Continue;
          if IsMasParamName(cur_param.Name) then
            cur_field := DataSource.DataSet.FindField
              (FastCopy(cur_param.Name, 5, MaxInt))
          else
            cur_field := DataSource.DataSet.FindField(cur_param.Name);

          Result := MasParamChanged;
          if Result then
            Exit;
        end
    end;
end;

procedure TFIBCustomDataSet.SetParamsFromMaster;
var
  pc, i: Integer;
  cur_param: TFIBXSQLVAR;
  cur_field: TField;
  s: TStream;
  vfi: PFIBFieldDescr;
  vData: Pointer;

  procedure SetFieldValue;
  begin
    if (cur_field <> nil) then
      begin
        if (cur_field.IsNull) then
          cur_param.IsNull := True
        else if ActiveTimeZoneData(cur_field, vfi, vData) then
          CacheToTimeZoneParam(cur_param, vfi, vData)
        else
          case cur_field.DataType of
            ftWideString: cur_param.Value := cur_field.Value;
            ftString: cur_param.AsString := cur_field.AsString;
            ftSmallint, ftInteger, ftWord, ftBoolean: cur_param.AsLong := cur_field.AsInteger;
            ftFloat, ftCurrency: cur_param.AsDouble := cur_field.AsFloat;
            ftBCD:
              if (cur_field is TFIBBCDField) and (TFIBBCDField(cur_field).Size = 0) then
                cur_param.AsInt64 := TFIBBCDField(cur_field).AsInt64
              else
                cur_param.AsBcd := TFIBBCDField(cur_field).AsBcd;
            ftDate: cur_param.AsDate := cur_field.asDateTime;
            ftDateTime: cur_param.asDateTime := cur_field.asDateTime;
            ftTime: cur_param.AsTime := cur_field.asDateTime;
            ftGuid: cur_param.AsGuid := TFIBGuidField(cur_field).AsGuid;
            ftLargeint: cur_param.AsInt64 := TFIBLargeIntField(cur_field).AsLargeInt;
            ftFMTBcd: cur_param.AsBcd := cur_field.AsBcd;
            ftBlob:
              begin
                s := nil;
                try
                  s := cur_field.DataSet.CreateBlobStream(cur_field, bmRead);
                  cur_param.LoadFromStream(s);
                finally
                  s.Free;
                end;
              end;
            else
              FIBError(feNotSupported, [CmpFullName(Self)]);
          end;
      end;
  end;

begin
  pc := Params.Count - 1;
  if (DataSource <> nil) and (DataSource.DataSet <> nil) and (pc >= 0) then
    begin
      for i := 0 to pc do
        begin
          cur_param := Params[i];
          if IsMasParamName(cur_param.Name) then
            cur_field := DataSource.DataSet.FindField
              (FastCopy(cur_param.Name, 5, MaxInt))
          else
            cur_field := DataSource.DataSet.FindField(cur_param.Name);
          SetFieldValue
        end;
      pc := QSelect.OnlySrvParams.Count - 1;
      for i := 0 to pc do
        begin
          cur_param := QSelect.FindParam(QSelect.OnlySrvParams[i]);
          if cur_param = nil then
            Continue;
          if IsMasParamName(cur_param.Name) then
            cur_field := DataSource.DataSet.FindField
              (FastCopy(cur_param.Name, 5, MaxInt))
          else
            cur_field := DataSource.DataSet.FindField(cur_param.Name);
          SetFieldValue
        end
    end;
end;

procedure TFIBCustomDataSet.InternalDoBeforeOpen;
begin

end;

procedure TFIBCustomDataSet.InternalOpen;
var
  iCurScreenState: Integer;
  i, j: Integer;
  vForceCreateFields: Boolean;
  vCalcFields: array of TField;
begin
  if drsInClone in FRunState then
    begin
      PrepareBookMarkSize;
      FOpen := True;
      Exit;
    end;
  ChangeScreenCursor(iCurScreenState);
  try
    FUpdatesPending := false;
    if FQSelect.MacroChanged then
      SQLChanging(QSelect);
    if not FPrepared or not FQSelect.Prepared then
      Prepare;
    if FieldDefs.Count = 0 then
      InternalInitFieldDefs;
    SetParamsFromMaster;
    if (FQSelect.SQLType = SQLSelect) or (FQSelect.SQLType = SQLSelectForUpdate) then
      begin
        vForceCreateFields := drsForceCreateCalcFields in FRunState;
        Exclude(FRunState, drsForceCreateCalcFields);
        if DefaultFields then
          CreateFields
        else if vForceCreateFields then
          begin
            // Only fields made by CreateCalcField count as automatic ones
            for i := 0 to FieldCount - 1 do
              if not(Fields[i].FieldKind in [fkCalculated, fkLookup]) then
                begin
                  vForceCreateFields := false;
                  Break;
                end;
            if vForceCreateFields then
              begin
                // TDataSet.CreateFields does nothing while any field exists (XE6+),
                // so detach the calculated fields and append them after the data fields
                SetLength(vCalcFields, FieldCount);
                for i := FieldCount - 1 downto 0 do
                  begin
                    vCalcFields[i] := Fields[i];
                    vCalcFields[i].DataSet := nil;
                  end;
                try
                  try
                    CreateFields;
                  except
                    // Back to the state before Open, so that the next Open retries
                    DestroyFields;
                    Include(FRunState, drsForceCreateCalcFields);
                    raise;
                  end;
                finally
                  for i := 0 to High(vCalcFields) do
                    vCalcFields[i].DataSet := Self;
                end;
                // Before XE6 the flag was computed while the calculated fields were attached
                SetDefaultFields(True);
              end;
          end;

        InitDataSetSchema;
        BindFields(True);
  {$IFDEF SUPPORT_ARRAY_FIELD}
        PrepareStreamFields;
  {$ENDIF}
        if BlobFieldCount > 0 then
          for i := 0 to Pred(FieldCount) do
            if Fields[i] is TFIBBlobField then
              TFIBBlobField(Fields[i]).FSubType := FQSelect[Fields[i].FieldName].AsXSQLVAR^.SqlSubType
            else if Fields[i] is TFIBMemoField then
              TFIBMemoField(Fields[i]).FSubType := FQSelect[Fields[i].FieldName].AsXSQLVAR^.SqlSubType;

        FQCurrentSelect := FQSelect;
        FCurrentRecord := -1;
        if FCacheModelOptions.FCacheModelKind = cmkLimitedBufferSize then
          begin
            if not Assigned(vPartition) then
              GetMem(vPartition, SizeOf(TRecordsPartition));
            vPartition^.BeginPartRecordNo := -1;
            vPartition^.EndPartRecordNo := -1;
            vPartition^.IncludeBof := True;
            vPartition^.IncludeEof := false;
          end;

        InternalDoBeforeOpen;
        if not FCachedActive then
          begin
            FQSelect.ExecQuery;
            FOpen := FQSelect.Open;
          end
        else
          FOpen := True;

        (*
        * Initialize offsets, buffer sizes, etc...
        * 1. Initially FRecordSize is just the "RecordDataLength".
        * 2. Allocate a "model" buffer and do a dummy fetch
        * 3. After the dummy fetch, FRecordSize will be appropriately
        *    adjusted to reflect the additional "weight" of the field
        *    data.
        * 4. Set up the FCalcFieldsOffset, FStreamsBufferOffset and FRecordBufferSize.
        * 5. Re-allocate the model buffer, accounting for the new
        *    FRecordBufferSize.
        * 6. Finally, calls to AllocRecordBuffer will work!.
      *)
        FStreamsBufferOffset := FRecordSize;
        FCalcFieldsOffset := FStreamsBufferOffset + (StreamFieldCount * SizeOf(TFIBFieldStream));
        FRecordBufferSize := FCalcFieldsOffset + CalcFieldsSize;
        FBlockReadSize := FBlockReadSize + (StreamFieldCount * SizeOf(TFIBFieldStream));

        FBufferChunkSize := FRecordBufferSize * FCacheModelOptions.FBufferChunks;
        vCalcFieldsSavedCache := poCacheCalcFields in Options;
        if vCalcFieldsSavedCache then
          FRecordsCache := TRecordsCache.Create(FCacheModelOptions.FBufferChunks,
            FRecordBufferSize, FBlockReadSize + CalcFieldsSize, FStringFieldCount)
        else
          FRecordsCache := TRecordsCache.Create(FCacheModelOptions.FBufferChunks,
            FRecordBufferSize, FBlockReadSize, FStringFieldCount);
        FRecordsCache.CreateNewBlock;
        FRecordsCache.SaveChangeLog := FCachedUpdates;
        j := 1;
        for i := 0 to Pred(vFieldDescrList.Capacity) do
          if vFieldDescrList[i].fdIsSeparateString then
            begin
              FRecordsCache.SetStrOffset(j, vFieldDescrList[i].fdDataOfs -
                DiffSizesRecData, vFieldDescrList[i].fdDataSize);
              Inc(j);
            end;
        FBPos := 0;
        FOBPos := 0;
        FBEnd := 0;
        FOBEnd := 0;
      end
    else
      begin
        FQSelect.ExecQuery;
        Exit;
      end;

    if (Filter <> '') and not Assigned(FFilterParser) then
      ExprParserCreate(FastTrim(Filter), FilterOptions);

    if (psGetOrderInfo in PrepareOptions) or (CacheModelOptions.CacheModelKind = cmkLimitedBufferSize) then
      PrepareAdditionalInfo;
    PrepareBookMarkSize;
    if CacheModelOptions.CacheModelKind = cmkLimitedBufferSize then
      PrepareAdditionalSelects;
  finally
    RestoreScreenCursor(iCurScreenState);
  end;
end;

procedure TFIBCustomDataSet.InternalPost;
var
  Qry: TFIBQuery;
  Buff: TRecordBuffer;
  iCurScreenState: Integer;
  bInserting: Boolean;
  R: Integer;
  vNeedMoveRec: Boolean;
begin
  CheckEditState;

  if not(drsInCacheRefresh in FRunState) then
    inherited InternalPost;
  ChangeScreenCursor(iCurScreenState);

  if (State = dsInsert) then
    begin
      bInserting := True;
      Qry := FQInsert;
    end
  else
    begin
      bInserting := false;
      Qry := FQUpdate;
    end;

  if State = dsEdit then
    vNeedMoveRec := NeedMoveRecordToOrderPos
  else
    begin
      // dsInsert
      vNeedMoveRec := Sorted and ((poKeepSorting in Options) or
        (FCacheModelOptions.CacheModelKind = cmkLimitedBufferSize));
    end;

  Buff := GetActiveBuf;
  UpdateFieldStreams(Buff, ufsCheckIsNull, false, false);
  try
    with PRecordData(Buff)^ do
      begin
        if bInserting then
          begin
            if not(drsInCacheRefresh in FRunState) then
              begin
                TCachedUpdateStatus(rdFlags) := cusInserted;
              end;
            with PRecordData(Buff)^ do
              begin
                R := GetRealRecNo;
                if (R > 0) and (GetBookmarkFlag(Buff) <> bfEOF) then
                  begin
                    rdRecordNumber := R - 1;
                  end
                else
                  begin
                    case FCacheModelOptions.CacheModelKind of
                      cmkStandard: rdRecordNumber := FRecordCount;
                      cmkLimitedBufferSize: rdRecordNumber := vPartition^.EndPartRecordNo + 1;
                    end;
                  end;
              end;
            FCurrentRecord := rdRecordNumber;
          end
        else
          begin
            if not(drsInCacheRefresh in FRunState) then
              begin
                case TCachedUpdateStatus(rdFlags and 7) of
                  cusUnmodified:
                    begin
                      TCachedUpdateStatus(rdFlags) := cusModified;
                    end;
                  cusUninserted:
                    begin
                      TCachedUpdateStatus(rdFlags) := cusInserted;
                      Dec(FDeletedRecords);
                    end;
                end
              end
          end;
      end;
    if (not CachedUpdates) and not(drsInCacheRefresh in FRunState) then
      begin
        case FCacheModelOptions.CacheModelKind of
          cmkStandard:
            try
              if bInserting then
                begin
                  if UniDirectional then
                    FRecordsCache.Insert(FCurrentRecord mod BufferChunks)
                  else
                    FRecordsCache.Insert(FCurrentRecord);
                end;
              InternalPostRecord(Qry, Buff);
            except
              if bInserting and (FCurrentRecord <= FRecordCount) then
                FRecordsCache.CancelInsert(FCurrentRecord + 1);
              raise;
            end;
          cmkLimitedBufferSize:
            begin
              if not(drsInCacheRefresh in FRunState) then
                InternalPostRecord(Qry, Buff);
              if vNeedMoveRec or (not(drsInCacheRefresh in FRunState) and (poRefreshAfterPost in FOptions)) then
                DoInternalRefresh(FQRefresh, Buff, vNeedMoveRec);
              Exit;
            end;
        end;
      end
    else
      begin
        if bInserting then
          begin
            FRecordsCache.Insert(FCurrentRecord);
          end;
        WriteRecordCache(PRecordData(Buff)^.rdRecordNumber, Buff);
        FUpdatesPending := not(drsInCacheRefresh in FRunState);
      end;
    if bInserting then
      begin
        Inc(FRecordCount);
        Inc(FAllRecordCount);
      end;

    if vNeedMoveRec then
      begin
        { SetState(dsBrowse);
        if IsVisible(Buff) then
        MoveRecordToOrderPos; }
        if IsVisible(Buff) then
          Include(FRunState, drsInMoveRecord);
        // Wait dsBrowse
      end
    else if not(poKeepSorting in Options) then
      FSortFields := Null;
  finally
    RestoreScreenCursor(iCurScreenState);
  end;
end;

procedure TFIBCustomDataSet.DoInternalRefresh(Qry: TFIBQuery; Buff: Pointer; ForceFullRefresh: Boolean);
var
  i: Integer;
begin
  if FCacheModelOptions.FCacheModelKind = cmkLimitedBufferSize then
    begin
      if not ForceFullRefresh or (State = dsInsert) then
        SaveOldBuffer(Buff);
      if InternalRefreshRow(Qry, Buff) then
        begin
          if ForceFullRefresh or NeedMoveRecordToOrderPos then
            InternalFullRefresh(false, false);
        end
      else
        begin
          if State in [dsEdit, dsInsert] then
            begin
              for i := 0 to Pred(FieldCount) do
                if not Fields[i].IsBlob then
                  begin
                    Fields[i].Value := Fields[i].OldValue;
                  end;
              // For FullRefresh^^^^
            end;
          InternalFullRefresh(false, false);
        end;
    end
  else
    begin
      InternalRefreshRow(Qry, Buff);
      if Sorted and (poKeepSorting in Options) then
        begin
          if NeedMoveRecordToOrderPos then
            begin
              MoveRecordToOrderPos;
              if vLockResync > 0 then
                Dec(vLockResync);
            end;
          FCurrentRecord := Recno - 1
        end;
      if not(State in [dsEdit, dsInsert]) then
        if dcForceMasterRefresh in DetailConditions then
          RefreshMasterDS;
    end;
end;

procedure TFIBCustomDataSet.InternalRefresh;
begin
  inherited;
  DoInternalRefresh(FQRefresh, Pointer(ActiveBuffer), false);
end;

procedure TFIBCustomDataSet.InternalSetToRecord(Buffer: TRecordBuffer);
begin
  case GetBookmarkFlag(Buffer) of
    bfCurrent: FCurrentRecord := PRecordData(Buffer)^.rdRecordNumber;
    bfInserted: FCurrentRecord := PRecordData(Buffer)^.rdRecordNumber - 1;
  end;
end;

function TFIBCustomDataSet.IsCursorOpen: Boolean;
begin
  Result := FOpen;
end;

function TFIBCustomDataSet.ExtLocate(const KeyFields: string; const KeyValues: Variant; Options: TExtLocateOptions): Boolean;
var
  VarArray: TDynArray;
begin
  CastVariantToArray(KeyValues, VarArray);
  case FCacheModelOptions.FCacheModelKind of
    cmkLimitedBufferSize: Result := InternalLocateForLimCache(KeyFields, VarArray, Options);
    else
      Result := InternalLocate(KeyFields, VarArray, Options, True, lkStandard, True);
  end;
end;

function TFIBCustomDataSet.Lookup(const KeyFields: string; const KeyValues: Variant; const ResultFields: string): Variant;
var
{$IFDEF D2009+}
  CurBookmark: TBookMark;
{$ELSE}
  CurBookmark: string;
{$ENDIF}
  rl: Boolean;
  VarArray: array of Variant;
  vQLookUp: TFIBQuery;
  OldRecno: Integer;
begin
  if IsEmptyStr(ResultFields) then
    begin
      Result := Null;
      Exit;
    end;
  Inc(vSimpleBookMark);
  CurBookmark := BookMark;
  DisableControls;
  try
    if VarIsArray(KeyValues) then
      VarArray := KeyValues
    else
      begin
        SetLength(VarArray, 1);
        VarArray[0] := KeyValues;
      end;
    case FCacheModelOptions.FCacheModelKind of
      cmkStandard:
        begin
          // rl:=InternalLocate(KeyFields, VarArray, [eloInSortedDS],True,lkStandard,True);
          rl := InternalLocate(KeyFields, VarArray, [], True, lkStandard, True);
          if rl then
            begin
              if PosCh(';', ResultFields) <> 0 then
                Result := FieldValues[ResultFields]
              else
                Result := FBN(ResultFields).Value
            end
          else
            Result := Null;
        end;
      cmkLimitedBufferSize:
        begin
          OldRecno := GetRealRecNo;
          rl := InternalLocate(KeyFields, VarArray, [eloInFetchedRecords], True);
          if rl then
            Result := FieldValues[ResultFields]
          else
            begin
              vQLookUp := CreateInternalQuery('QLookUp');
              vQLookUp.OrderClause := '';
              try
                begin
                  rl := InternalLocateForLimCache(KeyFields, VarArray, [], lkStandard, vQLookUp);
                  if rl then
                    Result := vQLookUp[ResultFields].Value
                  else
                    Result := Null;
                end
              finally
                vQLookUp.Free;
              end;
            end;
          if GetRealRecNo <> OldRecno then
            begin
              MoveBy(OldRecno - GetRealRecNo);
            end;
        end;
      else
        Result := Null;
    end;
  finally
    if FCacheModelOptions.FCacheModelKind = cmkStandard then
      BookMark := CurBookmark;
    Dec(vSimpleBookMark);
    EnableControls;
  end;

end;

{$IFDEF D_23}

procedure TFIBCustomDataSet.SetBookmarkData(Buffer: TRecBuf; Data: TBookMark);
{$ELSE}

procedure TFIBCustomDataSet.SetBookmarkData(Buffer: TRecordBuffer; Data: Pointer);
{$ENDIF}
var
  Rno: Integer;
begin
  if Data <> nil then
    begin
      Rno := FRecordsCache.RecordByBookMark(PFIBBookMark(Data).bRecordNumber);
      PRecordData(Buffer)^.rdRecordNumber := Rno
    end;
end;

procedure TFIBCustomDataSet.SetBookmarkFlag(Buffer: TRecordBuffer; Value: TBookmarkFlag);
begin
  if (PRecordData(Buffer)^.rdBookmarkFlag = bfInserted) and (Value = bfEOF) then
    case FCacheModelOptions.CacheModelKind of
      cmkStandard: PRecordData(Buffer)^.rdRecordNumber := FRecordCount;
      cmkLimitedBufferSize: PRecordData(Buffer)^.rdRecordNumber := vPartition^.EndPartRecordNo + 1
    end;

  PRecordData(Buffer)^.rdBookmarkFlag := Value;
end;

type
  THackQuery = class(TFIBQuery);

procedure TFIBCustomDataSet.SetCachedUpdates(Value: Boolean);
begin
  if Value <> FCachedUpdates then
    begin
      if not Value and FCachedUpdates and Active then
        CancelUpdates;
      if (not(csReading in ComponentState)) and Value then
        begin
          CheckDatasetClosed(' change CachedUpdates mode ');
          if FCacheModelOptions.FCacheModelKind = cmkLimitedBufferSize then
            FIBError(feCantUseLimitedCache, [CmpFullName(Self)]);
        end;
      FCachedUpdates := Value;
      THackQuery(FQSelect).FAutoCloseOnTransactionEnd := not FCachedUpdates and
        not(poDontCloseAfterEndTransaction in Options);
    end;
end;

procedure TFIBCustomDataSet.SetOnEndScroll(Event: TDataSetNotifyEvent);
begin
  if Assigned(Event) then
    begin
      CreateScrollTimer;
      vScrollTimer.Interval := WaitEndMasterInterval;
    end
  else
    begin
      vScrollTimer.Free;
      vScrollTimer := nil;
    end;
  FOnEndScroll := Event
end;

procedure TFIBCustomDataSet.SetDataSource(Value: TDataSource);
begin
  if IsLinkedTo(Value) then
    FIBError(feCircularReference, [CmpFullName(Self)]);
  if FSourceLink <> nil then
    FSourceLink.DataSource := Value;
end;

procedure TFIBCustomDataSet.SetOptions(Value: TpFIBDsOptions);
begin
  FOptions := Value;
{$IFDEF OBSOLETE_PROPS}
  Exclude(FOptions, poAllowChangeSqls);
{$ENDIF}
  if poStartTransaction in FOptions then
    begin
      QSelect.Options := QSelect.Options + [qoStartTransaction];
      QUpdate.Options := QUpdate.Options + [qoStartTransaction];
      QDelete.Options := QDelete.Options + [qoStartTransaction];
      QInsert.Options := QInsert.Options + [qoStartTransaction];
    end
  else
    begin
      QSelect.Options := QSelect.Options - [qoStartTransaction];
      QUpdate.Options := QUpdate.Options - [qoStartTransaction];
      QDelete.Options := QDelete.Options - [qoStartTransaction];
      QInsert.Options := QInsert.Options - [qoStartTransaction];
    end;

  if poNoForceIsNull in FOptions then
    begin
      QSelect.Options := QSelect.Options + [qoNoForceIsNull];
      QUpdate.Options := QUpdate.Options + [qoNoForceIsNull];
      QDelete.Options := QDelete.Options + [qoNoForceIsNull];
      QInsert.Options := QInsert.Options + [qoNoForceIsNull];
    end
  else
    begin
      QSelect.Options := QSelect.Options - [qoNoForceIsNull];
      QUpdate.Options := QUpdate.Options - [qoNoForceIsNull];
      QDelete.Options := QDelete.Options - [qoNoForceIsNull];
      QInsert.Options := QInsert.Options - [qoNoForceIsNull];
    end;

  THackQuery(FQSelect).FAutoCloseOnTransactionEnd := not FCachedUpdates and
    not(poDontCloseAfterEndTransaction in Options);

end;

function TFIBCustomDataSet.GetDefaultFields: Boolean;
begin
  Result := not Active and (FieldCount = 0);
  if not Result then
    Result := inherited DefaultFields;
end;

// Filter works

procedure TFIBCustomDataSet.SetFiltered(Value: Boolean);
begin
  FFilteredCacheInfo.NonVisibleRecords.Clear;
  FFilteredCacheInfo.AllRecords := -1;
  if Assigned(FFilterParser) and (FFilterParser.ExpressionText <> Filter) then
    Filter := Filter;
  inherited SetFiltered(Value);
  RefreshFilters
end;

procedure TFIBCustomDataSet.ExprParserCreate(const Text: string; Options: TFilterOptions);
const
  FldTypeMap: TFieldMap = (ord(ftUnknown), ord(ftString), ord(ftSmallint),
    ord(ftInteger), ord(ftWord), ord(ftBoolean), ord(ftFloat), ord(ftFloat),
    ord(ftBCD), ord(ftDate), ord(ftTime), ord(ftDateTime), ord(ftBytes),
    ord(ftVarBytes), ord(ftInteger), ord(ftBlob), ord(ftBlob), ord(ftBlob),
    ord(ftBlob), ord(ftBlob), ord(ftBlob), ord(ftBlob), ord(ftUnknown),
    ord(ftString), ord(ftWideString), ord(ftLargeint), ord(ftADT), ord(ftArray),
    ord(ftUnknown), ord(ftUnknown), ord(ftUnknown), ord(ftUnknown),
    ord(ftUnknown), ord(ftUnknown), ord(ftUnknown), ord(ftGuid), ord(ftUnknown),
    ord(ftUnknown)
{$IFDEF D2006+}
    , ord(ftUnknown), ord(ftUnknown), ord(ftUnknown), ord(ftUnknown)
{$ENDIF}
{$IFDEF D2009+}
    , ord(ftUnknown), ord(ftUnknown), ord(ftUnknown), ord(ftUnknown),
    ord(ftUnknown), ord(ftUnknown), ord(ftUnknown)
{$ENDIF}
{$IFDEF D2010+}
    , ord(ftUnknown), ord(ftUnknown), ord(ftUnknown)
{$ENDIF}
{$IFDEF D_30}
    , ord(ftUnknown)
{$ENDIF}
  );

var
  CalcFieldsList: TList;
  WideFieldsList: TList;
  i: Integer;
  OldParser: TExpressionParser;
begin
  OldParser := FFilterParser;
  CalcFieldsList := TList.Create;
  WideFieldsList := TList.Create;
  Include(FRunState, drsDontCheckInactive);
  try
    for i := 0 to Pred(FieldCount) do
      if Fields[i].FieldKind = fkCalculated then
        begin
          CalcFieldsList.Add(Fields[i]);
          Fields[i].FieldKind := fkInternalCalc;
        end;
{$IFDEF D2009+}
    // VCL converts literals compared with ftString fields to the system code page: keep them Unicode
    for i := 0 to Pred(FieldCount) do
      if (Fields[i].DataType = ftString) and not IsSystemCodePage(StringFieldCodePage(Fields[i])) then
        begin
          WideFieldsList.Add(Fields[i]);
          THackField(Fields[i]).SetDataType(ftWideString);
        end;
{$ENDIF}
    if IsBlank(Text) then
      FFilterParser := nil
    else
      FFilterParser := TExpressionParser.Create(Self, FastTrim(Text), Options,
        [poExtSyntax], '', nil, FldTypeMap, StrToDateFmt, SQLMaskCompare);
    OldParser.Free;
  finally
    for i := 0 to Pred(CalcFieldsList.Count) do
      TField(CalcFieldsList[i]).FieldKind := fkCalculated;
    for i := 0 to Pred(WideFieldsList.Count) do
      THackField(WideFieldsList[i]).SetDataType(ftString);
    Exclude(FRunState, drsDontCheckInactive);
    CalcFieldsList.Free;
    WideFieldsList.Free;
  end;
end;

procedure TFIBCustomDataSet.SetFilterData(const Text: string; Options: TFilterOptions);
begin
  if Active then
    begin
      CheckBrowseMode;
      if not Assigned(FFilterParser) or (FFilterParser.ExpressionText <> Text) or (FilterOptions <> Options) then
        ExprParserCreate(Text, Options)
    end
  else
    FreeAndNil(FFilterParser);
  FFilteredCacheInfo.NonVisibleRecords.Clear;
  FFilteredCacheInfo.AllRecords := -1;
  inherited SetFilterText(Text);
  inherited SetFilterOptions(Options);
  if Active and Filtered then
    First;
end;

procedure TFIBCustomDataSet.SetFilterOptions(Value: TFilterOptions);
begin
  SetFilterData(Filter, Value);
end;

procedure TFIBCustomDataSet.SetFilterText(const Value: string);
begin
  SetFilterData(Value, FilterOptions);
end;

// While OnValidate runs, GetFieldData returns the new value from Buffer.
// TField.Validate is not used: its Pointer overload keeps Buffer after the call
// and the next validation of the field reads that stale pointer.
procedure TFIBCustomDataSet.DoFieldValidate(Field: TField; Buffer: Pointer);
var
  OldBuffer: TDataBuffer;
  OldField: TField;
  OldRec, OldLength: Integer;
  WasValidating: Boolean;
begin
  if Assigned(Field.OnValidate) then
    begin
      // save the state of an outer validation: OnValidate may set other fields
      WasValidating := drsInFieldValidate in FRunState;
      OldBuffer := FValidatingFieldBuffer;
      OldField := FValidatedField;
      OldRec := FValidatedRec;
      // SetFieldData uses the value length after OnValidate, reading the field
      // from the record (OldValue for instance) changes it
      if Field is TFIBStringField then
        OldLength := TFIBStringField(Field).FValueLength
      else if Field is TFIBWideStringField then
        OldLength := TFIBWideStringField(Field).FValueLength
      else
        OldLength := 0;
      Include(FRunState, drsInFieldValidate);
      try
        FValidatingFieldBuffer := Buffer;
        FValidatedField := Field;
        FValidatedRec := ActiveRecord;
        Field.OnValidate(Field);
      finally
        if not WasValidating then
          Exclude(FRunState, drsInFieldValidate);
        FValidatingFieldBuffer := OldBuffer;
        FValidatedField := OldField;
        FValidatedRec := OldRec;
        if Field is TFIBStringField then
          TFIBStringField(Field).FValueLength := OldLength
        else if Field is TFIBWideStringField then
          TFIBWideStringField(Field).FValueLength := OldLength;
      end;
    end;
end;

{$IFDEF D_XE3}

procedure TFIBCustomDataSet.SetFieldData(Field: TField; Buffer: TValueBuffer);
begin
  SetFieldData(Field, Pointer(Buffer))
end;
{$ENDIF}

procedure TFIBCustomDataSet.SetFieldData(Field: TField; Buffer: Pointer);
var
  Buff, TmpBuff: TRecordBuffer;
  BoolValue, L: Integer;
  vfi: TpFIBFieldInfo;
  sp: Boolean;
  fi: PFIBFieldDescr;
  ValueCopy: TDataBuffer;
  ValueStack: array [0 .. 255] of Byte;

  // OnValidate gets a private copy of the new value, which is then stored:
  // Buffer can be the I/O buffer shared by all the fields of the dataset and
  // OnValidate overwrites it when it reads or sets another field
  function CopyValue: TDataBuffer;
  var
    Size, L: Integer;
    fi: PFIBFieldDescr;
  begin
    fi := vFieldDescrList[Field.FieldNo - 1];
    // the copy is read as field data (DataSize) and as record data (fdDataSize)
    Size := Field.DataSize;
    if Size < fi^.fdDataSize then
      Size := fi^.fdDataSize;
    // L is the number of bytes of Buffer which SetFieldData uses
    if Field is TFIBBooleanField then
      L := Field.DataSize
    else if (fi^.fdDataType = SQL_VARYING) or (fi^.fdDataType = SQL_TEXT) then
      begin
        if (Field.DataType = ftGuid) or fi^.fdIsDBKey then
          L := fi^.fdDataSize
        else if (drsInFieldAsData in FRunState) and (Field is TFIBWideStringField) then
          L := TFIBWideStringField(Field).FValueLength
        else if (Field is TFIBStringField) and ((drsInFieldAsData in FRunState) or TFIBStringField(Field)
          .vInSetAsString) then
            L := TFIBStringField(Field).FValueLength
          else
            begin
              L := 0;
              while (L < Size) and (PAnsiChar(Buffer)[L] <> #0) do
                Inc(L);
            end;
      end
    else
      case fi^.fdDataType of
        // converted from the field data type
        SQL_FLOAT, SQL_LONG, SQL_SHORT, SQL_INT64, SQL_INT128, SQL_DEC16,
          SQL_DEC34, SQL_TIME_TZ_EX, SQL_TIMESTAMP_TZ_EX:
          L := Field.DataSize;
        else
          L := fi^.fdDataSize;
      end;
    if L > Size then
      L := Size;
    if Size < SizeOf(ValueStack) then
      Result := TDataBuffer(@ValueStack)
    else
      GetMem(Result, Size + 1);
    Move(Buffer^, Result^, L);
    FillChar(PAnsiChar(Result)[L], Size + 1 - L, 0);
  end;

begin
  CheckActive;
  Buff := GetActiveBuf;
  if Buff = nil then
    Buff := Pointer(ActiveBuffer);
  if Field.FieldNo < 0 then
    begin
      TmpBuff := Buff + FCalcFieldsOffset + Field.Offset;
      Boolean(TmpBuff[0]) := LongBool(Buffer);
      if Boolean(TmpBuff[0]) then
        if (Field is TFIBStringField) then
          begin
            if TFIBStringField(Field).vInSetAsString then
              L := TFIBStringField(Field).FValueLength
            else
              L := Q_StrLen(Buffer);
            if L > Field.DataSize - 1 then
              L := Field.DataSize - 1;

            Move(Buffer^, TmpBuff[1], L);
            FillChar(TmpBuff[L + 1], Field.DataSize - L, 0);
          end
        else
          begin
            Move(Buffer^, TmpBuff[1], Field.DataSize);
          end;
    end
  else
    begin
      CheckEditState;
      ValueCopy := nil;
      try
        if Assigned(Field.OnValidate) and (Field.FieldNo > 0) and (Field.FieldNo <= vrdFieldCount) then
          begin
            if Buffer <> nil then
              begin
                ValueCopy := CopyValue;
                Buffer := ValueCopy;
              end;
            DoFieldValidate(Field, Buffer);
            // OnValidate could change the record buffers
            Buff := GetActiveBuf;
            if Buff = nil then
              Buff := Pointer(ActiveBuffer);
          end;
        with PRecordData(Buff)^ do
          begin
            if (Field.FieldNo > 0) and (Field.FieldNo <= vrdFieldCount) then
              begin
                sp := false;

                if (Buffer <> nil) and (PAnsiChar(Buffer)[0] = #0) and not(drsInCacheRefresh in FRunState) and
                  ((Field is TFIBStringField) and TFIBStringField(Field)
                  .FEmptyStrToNull or (Field is TFIBWideStringField) and
                  TFIBWideStringField(Field).FEmptyStrToNull) then
                  begin
                    vfi := ListTableInfo.GetFieldInfo(Database,
                      GetRelationTableName(Field), GetRelationFieldName(Field), false);
                    sp := not((vfi <> nil) and (vfi.DefaultValue = '') and vfi.DefaultValueEmptyString and
                      (not QSelect[Field.FieldName].IsNullable))
                  end;
                if (Buffer = nil) or sp then
                  begin
                    rdFields[Field.FieldNo].fdIsNull := True;
                    fi := vFieldDescrList[Field.FieldNo - 1];
                    if fi^.fdIsSeparateString then
                      PInteger(@Buff[fi^.fdDataOfs])^ := 0;
                  end
                else
                  begin
                    fi := vFieldDescrList[Field.FieldNo - 1];
                    if Field is TFIBBooleanField then
                      begin
                        BoolValue := PWord(Buffer)^;
                        Move(BoolValue, Buff[fi.fdDataOfs], fi.fdDataSize)
                      end
                    else
                      begin
                        if (fi^.fdDataType = SQL_VARYING) or (fi^.fdDataType = SQL_TEXT) then
                          begin
                            if (Field.DataType = ftGuid) or fi^.fdIsDBKey then
                              L := fi^.fdDataSize
                            else if (drsInFieldAsData in FRunState) then
                              begin
                                if Field is TFIBStringField then
                                  L := TFIBStringField(Field).FValueLength
                                else
                                  L := TFIBWideStringField(Field).FValueLength;
                                if L > fi.fdDataSize then
                                  L := fi.fdDataSize;
                              end
                            else
                              begin
                                if (Field is TFIBStringField) and TFIBStringField(Field).vInSetAsString then
                                  L := TFIBStringField(Field).FValueLength
                                else
                                  L := Q_StrLen(Buffer);
                                if L > fi.fdDataSize then
                                  L := fi.fdDataSize;

                                if (Field.DataType = ftGuid) or fi^.fdIsDBKey then
                                  L := fi^.fdDataSize
                                else if (poTrimCharFields in FOptions) then
                                  begin
                                    while (L > 0) and (PAnsiChar(Buffer)[L - 1] = ' ') do
                                      Dec(L);
                                  end;
                              end;

                            if fi^.fdIsSeparateString then
                              begin
                                PInteger(@Buff[fi^.fdDataOfs])^ := L;
                                Move(Buffer^, Buff[fi^.fdDataOfs + SizeOf(Integer)], L);
                                if (L < fi.fdDataSize) then
                                  PAnsiChar(Buff)[fi^.fdDataOfs + SizeOf(Integer) + L] := #0
                              end
                            else
                              begin
                                Move(Buffer^, Buff[fi^.fdDataOfs], L);
                                if (drsInFieldAsData in FRunState) then
                                  begin
                                    if (L < fi.fdDataSize) then
                                      FillChar(PAnsiChar(Buff)[fi^.fdDataOfs + L], fi.fdDataSize - L, 0)
                                  end
                                else if (L < fi.fdDataSize) then
                                  PAnsiChar(Buff)[fi^.fdDataOfs + L] := #0;
                              end;
                          end
                        else
                          case fi^.fdDataType of
                            SQL_FLOAT: PSingle(@Buff[fi^.fdDataOfs])^ := PDouble(Buffer)^;
                            SQL_LONG:
                              if fi^.fdDataScale <> 0 then
                                PLong(@Buff[fi^.fdDataOfs])^ := Round(PDouble(Buffer)^ * E10[-fi^.fdDataScale])
                              else
                                PLong(@Buff[fi^.fdDataOfs])^ := PLong(Buffer)^;
                            SQL_SHORT:
                              if fi^.fdDataScale <> 0 then
                                PShort(@Buff[fi^.fdDataOfs])^ := Round(PDouble(Buffer)^ * E10[-fi^.fdDataScale])
                              else
                                PShort(@Buff[fi^.fdDataOfs])^ := PShort(Buffer)^;
                            SQL_INT64:
                              if (fi^.fdDataScale < -4) and not(psSQLINT64ToBCD in PrepareOptions) then
                                PDouble(@Buff[fi^.fdDataOfs])^ := PDouble(Buffer)^
                              else
                                PInt64(@Buff[fi^.fdDataOfs])^ := PInt64(Buffer)^;
                            SQL_INT128, SQL_DEC16, SQL_DEC34:
                              if not FBBcdToRaw(TBcd(Buffer^), fi^.fdDataType,
                                fi^.fdDataScale, @Buff[fi^.fdDataOfs]) then
                                FIBError(feInvalidDataConversion, [nil]);
                            SQL_TIME_TZ_EX:
                              begin
                                // a value without time zone is stored in the session time zone
                                if rdFields[Field.FieldNo].fdIsNull then
                                  PISC_TIME_TZ_EX(@Buff[fi^.fdDataOfs])^.time_zone := FBSessionZoneID;
                                FBMSecsToTimeTZ(PInteger(Buffer)^, PISC_TIME_TZ_EX(@Buff[fi^.fdDataOfs])^);
                              end;
                            SQL_TIMESTAMP_TZ_EX:
                              begin
                                if rdFields[Field.FieldNo].fdIsNull then
                                  PISC_TIMESTAMP_TZ_EX(@Buff[fi^.fdDataOfs])^.time_zone := FBSessionZoneID;
                                FBMSecsToTimeStampTZ(PDouble(Buffer)^, PISC_TIMESTAMP_TZ_EX(@Buff[fi^.fdDataOfs])^);
                              end;
                            else
                              Move(Buffer^, Buff[fi^.fdDataOfs], fi.fdDataSize);
                          end;
                      end;
                    rdFields[Field.FieldNo].fdIsNull := false;
                    if (TCachedUpdateStatus(rdFlags and 7) = cusUnmodified) and not(drsInCacheRefresh in FRunState) then
                      begin
                        if State = dsInsert then
                          TCachedUpdateStatus(rdFlags) := cusInserted
                        else
                          TCachedUpdateStatus(rdFlags) := cusModified;

                        Inc(FCountUpdatesPending);
                      end;
                    SetModified(True);
                  end;
              end;
          end;
      finally
        if Pointer(ValueCopy) <> @ValueStack then
          FreeMem(ValueCopy);
      end;
    end;
  if not(State in [dsCalcFields, dsFilter, dsNewValue]) then
    DataEvent(deFieldChange, EventInfo(Field));
end;

procedure TFIBCustomDataSet.SetRealRecNo(Value: Integer; ToCenter: Boolean = false);
var
  RValue: Integer;
  OldRecno: Integer;
begin
  CheckBrowseMode;
  if (Value < 1) then
    RValue := 0
  else
    begin
      if FCacheModelOptions.FCacheModelKind = cmkStandard then
        begin
          if Value > FRecordCount then
            begin
              InternalLast;
              RValue := Min(FRecordCount, Value);
            end
          else
            RValue := Value - 1;
        end
      else
        begin
          // only for internal use
          RValue := Value - 1;
          if (RValue > vPartition.EndPartRecordNo) or (RValue < vPartition.BeginPartRecordNo) then
            Exit;
        end;
    end;
  OldRecno := GetRealRecNo;
  if Eof or Bof or (Value <> OldRecno) then
    begin
      DoBeforeScroll;
      FCurrentRecord := RValue;
      if ToCenter then
        Resync([rmCenter])
      else
        Resync([]);
      if FCacheModelOptions.FCacheModelKind = cmkStandard then
        begin
          if Value < 1 then
            begin
              MoveBy(-1); // BOF
              DoAfterScroll;
              Exit;
            end
          else if Value > FRecordCount then
            begin
              MoveBy(1); // EOF
              DoAfterScroll;
              Exit;
            end;
        end;
      if not ToCenter and (RValue - OldRecno <= BufferCount - ActiveRecord) then
        SetRecordPosInBuffer(ActiveRecord + RValue - OldRecno + 1);
      DoAfterScroll;
    end;
end;

procedure TFIBCustomDataSet.SetRecNo(Value: Integer);
begin
  SetRealRecNo(Value);
end;

function TFIBCustomDataSet.Translate(Src, Dest: PAnsiChar; ToOem: Boolean): Integer;
begin
  if Src <> nil then
    begin
      StrCopy(PAnsiChar(Dest), PAnsiChar(Src));
      Result := Q_StrLen(PAnsiChar(Dest));
    end
  else
    Result := 0;
end;

// Array support

{$IFDEF SUPPORT_ARRAY_FIELD}
// Array fields keep their value in a TFIBArrayStream until Post, like BLOB fields

procedure TFIBCustomDataSet.PrepareStreamFields;
var
  i: Integer;
begin
  FArrayFieldCount := 0;
  for i := 0 to FieldCount - 1 do
    if Fields[i] is TFIBArrayField then
      begin
        TFIBArrayField(Fields[i]).FStreamIndex := BlobFieldCount + FArrayFieldCount;
        Inc(FArrayFieldCount);
      end;
end;

function TFIBCustomDataSet.GetFieldArray(Field: TField): TpFIBArray;
begin
  Result := QSelect[Field.FieldName].FIBArray;
  if Result = nil then
    FIBError(feNotIsArrayField, [Field.FieldName]);
end;

// Whole array of Field in Buffer (ArraySize bytes), False for NULL
function TFIBCustomDataSet.ReadArrayBuffer(Field: TField; Buffer: PAnsiChar): Boolean;
var
  Stream: TStream;
begin
  Result := not Field.IsNull;
  if not Result then
    Exit;
  Stream := CreateBlobStream(Field, bmRead);
  try
    Result := Stream.Size > 0;
    if Result then
      begin
        Stream.Position := 0;
        Stream.ReadBuffer(Buffer^, GetFieldArray(Field).ArraySize);
      end;
  finally
    Stream.Free;
  end;
end;

procedure TFIBCustomDataSet.WriteArrayBuffer(Field: TField; Buffer: PAnsiChar);
var
  Stream: TStream;
begin
  Stream := CreateBlobStream(Field, bmWrite);
  try
    if Buffer <> nil then
      Stream.WriteBuffer(Buffer^, GetFieldArray(Field).ArraySize);
  finally
    Stream.Free;
  end;
end;

function TFIBCustomDataSet.ArrayFieldValue(Field: TField): Variant;
var
  Arr: TpFIBArray;
  Buffer: TDataBuffer;
begin
  Result := Null;
  if not Assigned(Field) then
    Exit;
  Arr := GetFieldArray(Field);
  Buffer := nil;
  FIBAlloc(Buffer, 0, Arr.ArraySize);
  try
    if ReadArrayBuffer(Field, PAnsiChar(Buffer)) then
      Result := Arr.BufferToVariant(PAnsiChar(Buffer));
  finally
    FIBAlloc(Buffer, 0, 0);
  end;
end;

procedure TFIBCustomDataSet.SetArrayValue(Field: TField; Value: Variant);
var
  Buffer: TDataBuffer;
begin
  CheckEditState;
  if not Assigned(Field) then
    Exit;
  // an empty stream is NULL
  if VarIsEmpty(Value) or VarIsNull(Value) then
    begin
      WriteArrayBuffer(Field, nil);
      Exit;
    end;
  Buffer := nil;
  FIBAlloc(Buffer, 0, GetFieldArray(Field).ArraySize);
  try
    GetFieldArray(Field).VariantToBuffer(Value, PAnsiChar(Buffer));
    WriteArrayBuffer(Field, PAnsiChar(Buffer));
  finally
    FIBAlloc(Buffer, 0, 0);
  end;
end;

function TFIBCustomDataSet.GetElementFromValue(Field: TField; Indexes: array of Integer): Variant;
var
  Arr: TpFIBArray;
  Buffer: TDataBuffer;
begin
  Result := Null;
  if not Assigned(Field) then
    Exit;
  Arr := GetFieldArray(Field);
  Buffer := nil;
  FIBAlloc(Buffer, 0, Arr.ArraySize);
  try
    if ReadArrayBuffer(Field, PAnsiChar(Buffer)) then
      Result := Arr.GetBufferElement(PAnsiChar(Buffer), Indexes)
    else
      Arr.CheckIndexes(Indexes);
  finally
    FIBAlloc(Buffer, 0, 0);
  end;
end;

procedure TFIBCustomDataSet.SetArrayElementValue(Field: TField; Value: Variant; Indexes: array of Integer);
var
  Arr: TpFIBArray;
  Buffer: TDataBuffer;
begin
  CheckEditState;
  if not Assigned(Field) then
    Exit;
  Arr := GetFieldArray(Field);
  Buffer := nil;
  FIBAlloc(Buffer, 0, Arr.ArraySize);
  try
    if not ReadArrayBuffer(Field, PAnsiChar(Buffer)) then
      Arr.InitBuffer(PAnsiChar(Buffer));
    Arr.SetBufferElement(PAnsiChar(Buffer), Indexes, Value);
    WriteArrayBuffer(Field, PAnsiChar(Buffer));
  finally
    FIBAlloc(Buffer, 0, 0);
  end;
end;
{$ENDIF}

function TFIBDataSet.DoStoreActive: Boolean;
begin
  Result := Active and (Database.StoreConnected or not(csDesigning in ComponentState))
end;

(*
  * Support routines
*)

function RecordDataLength(n: Integer): Long;
begin
  Result := SizeOf(TRecordData) + ((n - 1) * SizeOf(TFieldData));
end;

(*
  * It allows you to remove a record from a
  * DataSet without deleting it.
  *
  * "Remove" the current record from FromDS. (It marks the record deleted
  * without causing a post.
*)
procedure FilterOut(FromDS: TFIBCustomDataSet);
var
  BufferFrom: TRecordBuffer;
begin
  with FromDS do
    begin
      CheckDatasetOpen(' do delete from cache ');
      DisableControls;
      try
        BufferFrom := GetActiveBuf;
        if Assigned(BufferFrom) then
          begin
            TCachedUpdateStatus(PRecordData(BufferFrom)^.rdFlags) := cusDeletedApplied;
            Inc(FDeletedRecords);
            WriteRecordCache(PRecordData(BufferFrom)^.rdRecordNumber, BufferFrom);
            SetCurrentRecord(ActiveRecord);
            Resync([]);
          end;
      finally
        EnableControls;
      end;
    end;
end;

(*
  * Do a quick sort on the current Result set in the data set.
  * If bFetchAll, then ensure that all records are fetched before doing
  * the sort.
  * Fields is a list of the fields to sort on.
  * Ordering is a list of booleans specifying DESC or ASC (False, True)
  *
  * Based on randomized quick sort from
*)

procedure FastSort(DataSet: TFIBCustomDataSet; aFields: array of TField; Ordering: array of Boolean);

  function Compare1(Num: Integer; F: TField; aOrdering: Boolean; y: Variant; var x: Variant): Integer;
  var
    SortOrder: Integer;
  begin
    try
      x := DataSet.RecordFieldValue(F, Num + 1);
      if aOrdering then
        SortOrder := 1
      else
        SortOrder := -1;
      Result := DataSet.CompareFieldValues(F, x, y) * SortOrder;
    except
      Result := 0;
    end
  end;

  function Compare(Num, FCount: Integer; y: array of Variant; var x1: array of Variant): Integer;
  var
    SortOrder: Integer;
    FCur: Integer;
  begin
    Result := 0;
    for FCur := 0 to FCount do
      try
        x1[FCur] := DataSet.RecordFieldValue(aFields[FCur], Num + 1);
        if Ordering[FCur] then
          SortOrder := 1
        else
          SortOrder := -1;

        Result := DataSet.CompareFieldValues(aFields[FCur], x1[FCur], y[FCur]) * SortOrder;
        if Result <> 0 then
          Exit;
      except
        Result := 0;
        Exit
      end
  end;

  procedure QuickSort1(L, R: Integer; F: TField; aOrdering: Boolean);
  var
    i, j: Integer;
    p, V, V1: Variant;
  begin
    repeat
      i := L;
      j := R;
      p := DataSet.RecordFieldValue(F, ((L + R) shr 1) + 1);
      repeat
        while (i < DataSet.FRecordCount) and (Compare1(i, F, aOrdering, p, V) < 0) do
          Inc(i);
        while (j >= 0) and (Compare1(j, F, aOrdering, p, V1) > 0) do
          Dec(j);
        if i <= j then
          begin
            if (i <> j) and (V <> V1) then
              DataSet.FRecordsCache.SwapRecords(i, j);
            Inc(i);
            Dec(j);
          end;
      until i > j;
      if L < j then
        QuickSort1(L, j, F, aOrdering);
      L := i;
    until i >= R;
  end;

  procedure QuickSort(L, R: Integer);
  var
    i, j: Integer;
    p: array of Variant;
    V: array of Variant;
    V1: array of Variant;
    FCur, FCount: Integer;
  begin
    FCount := High(aFields);
    SetLength(p, FCount + 1);
    SetLength(V, FCount + 1);
    SetLength(V1, FCount + 1);
    repeat
      i := L;
      j := R;
      for FCur := 0 to FCount do
        p[FCur] := DataSet.RecordFieldValue(aFields[FCur], ((L + R) shr 1) + 1);
      repeat
        while (i < DataSet.FRecordCount) and (Compare(i, FCount, p, V) < 0) do
          Inc(i);
        while (j >= 0) and (Compare(j, FCount, p, V1) > 0) do
          Dec(j);
        if i <= j then
          begin
            if (i <> j) and not EasyCompareVarArray1(V, V1, FCount) then
              DataSet.FRecordsCache.SwapRecords(i, j);
            Inc(i);
            Dec(j);
          end;
      until (i > j);
      if L < j then
        QuickSort(L, j);
      L := i;
    until i >= R;
  end;

begin
  if DataSet.FRecordCount < 2 then
    Exit;
  if High(aFields) = 0 then
    QuickSort1(0, DataSet.FRecordCount - 1, aFields[0], Ordering[0])
  else
    QuickSort(0, DataSet.FRecordCount - 1);
end;

procedure Sort(DataSet: TFIBCustomDataSet; aFields: array of const; Ordering: array of Boolean);
var
  vFieldCount, i: Integer;
  vOptions: TFIBUpdateRecordTypes;
  // ^^^ save current options
{$IFDEF D2009+}
  B: TBookMark;
{$ELSE}
  B: TBookMarkStr;
{$ENDIF}
  tf: TField;
  iCurScreenState: Integer;

  function GetField(IndexF: Integer): TField;
  begin
    with DataSet do
      case aFields[IndexF].VType of
        vtChar:
          begin
            Result := DataSet.FindField(aFields[IndexF].vChar);
            if Result = nil then
              raise Exception.Create(SCantSort + IntToStr(IndexF) + ']');
          end;
        vtInteger: Result := Fields[aFields[IndexF].VInteger];
        vtObject:
          begin
            if not(aFields[IndexF].vObject is TField) or (TField(aFields[IndexF].vObject).DataSet <> DataSet) then
              raise Exception.Create(SCantSort + IntToStr(IndexF) + ']');
            Result := TField(aFields[IndexF].vObject);
          end;
        vtAnsiString:
          begin
            Result := DataSet.FindField
              (string(AnsiString(aFields[IndexF].vString)));
            if Result = nil then
              raise Exception.Create(SCantSort + IntToStr(IndexF) + ']');
          end;
        vtVariant:
          case VarType(aFields[IndexF].VVariant^) of
            varInteger, varWord, varLongWord, varInt64: Result := Fields[aFields[IndexF].VVariant^];
            varString, varOleStr{$IFDEF D2009+}, varUString{$ENDIF}:
              begin
                Result := DataSet.FindField(aFields[IndexF].VVariant^);
                if Result = nil then
                  raise Exception.Create(SCantSort + IntToStr(IndexF) + ']');
              end
            else
              raise Exception.Create(SCantSort + IntToStr(IndexF) + ']');
          end;
        vtWideString:
          begin
            Result := DataSet.FindField
              (WideString(aFields[IndexF].VWideString));
            if Result = nil then
              raise Exception.Create(SCantSort + IntToStr(IndexF) + ']');
          end;
{$IFDEF D2009+}
        vtUnicodeString:
          begin
            Result := DataSet.FindField(string(aFields[IndexF].vString));
            if Result = nil then
              raise Exception.Create(SCantSort + IntToStr(IndexF) + ']');
          end
{$ENDIF}
        else
          raise Exception.Create(SCantSort + IntToStr(IndexF) + ']');
      end;
  end;

var
  vSortedFields: array of TField;

begin
  if Length(aFields) = 0 then
    begin
      DataSet.FSortFields := Null;
      Exit;
    end;

  DataSet.CheckDatasetOpen(' do local sorting ');
  TFIBCustomDataSet(DataSet).ChangeScreenCursor(iCurScreenState);
  Inc(DataSet.vSimpleBookMark);
  B := DataSet.BookMark;
  DataSet.DisableControls;
  DataSet.DisableScrollEvents;
  DataSet.FetchAll;
  with DataSet do
    begin
      FFilteredCacheInfo.NonVisibleRecords.Clear;
      FFilteredCacheInfo.AllRecords := -1;

      vFieldCount := High(aFields) - Low(aFields) + 1;
      SetLength(vSortedFields, vFieldCount);

      FSortFields := VarArrayCreate([0, vFieldCount - 1, 0, 2], varVariant);
      for i := Low(aFields) to High(aFields) do
        begin
          tf := GetField(i);
          FSortFields[i, 1] := Ordering[i];
          FSortFields[i, 2] := false; // NULLS FIRST OR LAST
          FSortFields[i, 0] := tf.FieldName;
          vSortedFields[i] := tf;
        end;
      FIsClientSorting := True;
    end;

  if DataSet.FRecordCount < 2 then
    begin
      DataSet.EnableScrollEvents;
      DataSet.EnableControls;
      TFIBCustomDataSet(DataSet).RestoreScreenCursor(iCurScreenState);
      Exit;
    end;
  vOptions := DataSet.UpdateRecordTypes;
  DataSet.UpdateRecordTypes := [cusUnmodified, cusModified, cusInserted, cusUninserted, cusDeleted];

  try
    try
      FastSort(DataSet, vSortedFields, Ordering);
    except
      DataSet.FSortFields := Null;
      raise
    end;
  finally
    DataSet.UpdateRecordTypes := vOptions;
    DataSet.BookMark := B;
    Dec(DataSet.vSimpleBookMark);
    TFIBCustomDataSet(DataSet).RestoreScreenCursor(iCurScreenState);
    DataSet.EnableScrollEvents;
    DataSet.EnableControls;
  end;
end;

// TFIBDSFieldStream
constructor TFIBDSFieldStream.Create(AField: TField; AFieldStream: TFIBFieldStream; Mode: TBlobStreamMode);
var
  DataSet: TFIBCustomDataSet;
  NeedTransaction, NeedConnection: Boolean;
begin
  FModified := Mode = bmWrite;
  FField := AField;
  FFieldStream := AFieldStream;
  if not Assigned(FFieldStream) then
    Exit;
  if AField.DataSet is TFIBCustomDataSet then
    DataSet := TFIBCustomDataSet(AField.DataSet)
  else
    DataSet := nil;
  if Assigned(DataSet) and (Mode = bmRead) then
    FOnBlobFieldRead := DataSet.FOnBlobFieldRead;
  NeedTransaction := false;
  NeedConnection := false;
  if Assigned(DataSet) then
    with DataSet do
      begin
        if CachedUpdates or (poDontCloseAfterEndTransaction in Options) then
          begin
            NeedTransaction := not Transaction.InTransaction;
            NeedConnection := not Database.Connected;
          end;
        if NeedConnection then
          Database.Open;
        if NeedTransaction then
          Transaction.StartTransaction;
      end;
  FFieldStream.DoSeek(0, soFromBeginning, DoCallBack);
  if Mode = bmWrite then
    FFieldStream.Truncate;
  if NeedTransaction then
    DataSet.Transaction.Commit;
  if NeedConnection and (DataSet.Database.TimeOut = 0) then
    DataSet.Database.Close;
end;

destructor TFIBDSFieldStream.Destroy;
begin
  if FModified then
    begin
      FModified := false;
      if FField is TBlobField then
        begin
          if not TBlobField(FField).Modified then
            TBlobField(FField).Modified := True;
        end
      else
        // TBlobField.IsNull checks the stream when Modified, other fields keep the NULL flag
        with TFIBCustomDataSet(FField.DataSet) do
          UpdateFieldStreams(GetActiveBuf, ufsCheckIsNull, false, false, FField);
      TFIBCustomDataSet(FField.DataSet).DataEvent(deFieldChange, EventInfo(FField));
    end;
  inherited Destroy;
end;

procedure TFIBDSFieldStream.DoCallBack(BlobSize: Integer; BytesProcessing: Integer; var Stop: Boolean);
begin
  if not(FField is TBlobField) then
    Exit;
  if GlobalContainer <> nil then
    GlobalContainer.DoOnReadBlobField(TBlobField(FField), BlobSize, BytesProcessing, Stop);
  if Assigned(FOnBlobFieldRead) then
    FOnBlobFieldRead(TBlobField(FField), BlobSize, BytesProcessing, Stop);
end;

function TFIBDSFieldStream.Read(var Buffer; Count: LongInt): LongInt;
begin
  if not Assigned(FFieldStream) then
    Result := 0
  else if FField.DataSet.State = dsOldValue then
    Result := FFieldStream.ReadOldBuffer(Buffer, Count)
  else
    Result := FFieldStream.Read(Buffer, Count);
end;

function TFIBDSFieldStream.Seek(Offset: LongInt; Origin: Word): LongInt;
begin
  if not Assigned(FFieldStream) then
    Result := 0
  else if FField.DataSet.State = dsOldValue then
    Result := FFieldStream.SeekInOldBuffer(Offset, Origin)
  else
    Result := FFieldStream.Seek(Offset, Origin);
end;

procedure TFIBDSFieldStream.SetSize(NewSize: LongInt);
begin
  if Assigned(FFieldStream) then
    FFieldStream.SetSize(NewSize);
end;

function TFIBDSFieldStream.Write(const Buffer; Count: LongInt): LongInt;
begin
  // client calculated BLOB fields are written outside of the edit state
  if not((FField is TFIBBlobField) and TFIBBlobField(FField).FIsClientCalcField)
    and not(FField.DataSet.State in [dsEdit, dsInsert]) then
    FIBError(feNotEditing, [CmpFullName(FField.DataSet)]);
  FModified := True;
  TFIBDataSet(FField.DataSet).RecordModified(True);
  if FField is TBlobField then
    TBlobField(FField).Modified := True;
  if Assigned(FFieldStream) then
    Result := FFieldStream.Write(Buffer, Count)
  else
    Result := 0;
end;

function TFIBCustomDataSet.FieldExist(const FieldName: string; var FieldIndex: Integer): Boolean;
var
  tf: TField;
begin
  tf := FindField(FieldName);
  Result := Assigned(tf);
  if Result then
    FieldIndex := tf.Index;
end;

function TFIBCustomDataSet.FieldValue(const FieldIndex: Integer; Old: Boolean): Variant;
var
  tf: TField;
begin
  tf := Fields[FieldIndex];
  if Old and (State <> dsInsert) then
    Result := tf.OldValue
  else
    Result := tf.Value
end;

function TFIBCustomDataSet.FieldValue(const FieldName: string; Old: Boolean): Variant;
var
  tf: TField;
begin
  tf := FBN(FieldName);
  if Old then
    Result := tf.OldValue
  else
    Result := tf.Value
end;

function TFIBCustomDataSet.ParamExist(const ParamName: string; var ParamIndex: Integer): Boolean;
begin
  Result := QSelect.ParamExist(ParamName, ParamIndex);
end;

function TFIBCustomDataSet.ParamValue(const ParamIndex: Integer): Variant;
begin
  Result := QSelect.ParamValue(ParamIndex)
end;

function TFIBCustomDataSet.ParamValue(const ParamName: string): Variant;
begin
  Result := QSelect.ParamValue(ParamName)
end;

function TFIBCustomDataSet.DefMacroValue(const MacroName: string): string;
begin
  Result := QSelect.DefMacroValue(MacroName)
end;

function TFIBCustomDataSet.ParamCount: Integer;
begin
  Result := Params.Count
end;

function TFIBCustomDataSet.ParamName(ParamIndex: Integer): string;
begin
  Result := Params[ParamIndex].Name;
end;

function TFIBCustomDataSet.FieldsCount: Integer;
begin
  Result := FieldCount
end;

function TFIBCustomDataSet.FieldName(FieldIndex: Integer): string;
begin
  Result := Fields[FieldIndex].FieldName;
end;

procedure TFIBCustomDataSet.SetParamValue(const ParamIndex: Integer; aValue: Variant);
begin
  Params[ParamIndex].Value := aValue;
end;

procedure TFIBCustomDataSet.SetParamValues(const ParamValues: array of Variant);
begin
  QSelect.SetParamValues(ParamValues)
end;

procedure TFIBCustomDataSet.SetParamValues(const ParamNames: string; ParamValues: array of Variant);
begin
  QSelect.SetParamValues(ParamNames, ParamValues)
end;

function TFIBCustomDataSet.IEof: Boolean;
begin
  Result := Eof
end;

procedure TFIBCustomDataSet.INext;
begin
  Next
end;

//

procedure TFIBCustomDataSet.DoAfterEndTransaction(EndingTR: TFIBTransaction; Action: TTransactionAction; Force: Boolean);
begin
  if Assigned(FAfterEndTr) then
    FAfterEndTr(EndingTR, Action, Force);
end;

procedure TFIBCustomDataSet.DoAfterEndUpdateTransaction(EndingTR: TFIBTransaction; Action: TTransactionAction; Force: Boolean);
begin
  if Assigned(FAfterEndUpdTr) then
    FAfterEndUpdTr(EndingTR, Action, Force);
end;

procedure TFIBCustomDataSet.DoAfterStartTransaction(Sender: TObject);
begin
  if Assigned(FAfterStartTr) then
    FAfterStartTr(Sender);
end;

procedure TFIBCustomDataSet.DoAfterStartUpdateTransaction(Sender: TObject);
begin
  if Assigned(FAfterStartUpdTr) then
    FAfterStartUpdTr(Sender);
end;

procedure TFIBCustomDataSet.DoBeforeEndTransaction(EndingTR: TFIBTransaction; Action: TTransactionAction; Force: Boolean);
begin
  if Assigned(FBeforeEndTr) then
    FBeforeEndTr(EndingTR, Action, Force);
end;

procedure TFIBCustomDataSet.DoBeforeEndUpdateTransaction(EndingTR: TFIBTransaction; Action: TTransactionAction; Force: Boolean);
begin
  if Assigned(FBeforeEndUpdTr) then
    FBeforeEndUpdTr(EndingTR, Action, Force);
end;

procedure TFIBCustomDataSet.DoBeforeStartTransaction(Sender: TObject);
begin
  if Assigned(FBeforeStartTr) then
    FBeforeStartTr(Sender);
end;

procedure TFIBCustomDataSet.DoBeforeStartUpdateTransaction(Sender: TObject);
begin
  if Assigned(FBeforeStartUpdTr) then
    FBeforeStartUpdTr(Sender);
end;

{ TFIBGuidField }

class procedure TFIBGuidField.CheckTypeSize(Value: Integer);
begin
  if not Value in [38, 16] { Length(GuidString) } then
    DatabaseError(SInvalidFieldSize);
end;

constructor TFIBGuidField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetLength(FBuffer, 38);
  pBuffer := @FBuffer[1]
end;

function TFIBGuidField.GetAsVariant: Variant;
begin
  Result := GetAsString
end;

procedure TFIBGuidField.SetAsVariant(const Value: Variant);
var
  GuidValue: TGUID;
  sValue: string;
begin
  sValue := VarToStr(Value);
  if Length(sValue) = 0 then
    Clear
  else
    begin
      GuidValue := StringAsGuid(AnsiString(sValue));
      SetData(@GuidValue)
    end;
end;

function TFIBGuidField.GetAsGuid: TGUID;
begin
  if not GetData(pBuffer) then
    Result := fibGUID_NULL
  else
    Result := StringAsGuid(FBuffer)
end;

procedure TFIBGuidField.SetAsGuid(const Value: TGUID);
begin
  if IsEqualGUIDs(Value, fibGUID_NULL) then
    Clear
  else
{$IFDEF D_XE3}
    TFIBDataSet(DataSet).SetFieldData(Self, @Value);
{$ELSE}
    SetData(@Value);
{$ENDIF}
end;

procedure TFIBGuidField.SetAsString(const Value: string);
var
  GuidValue: TGUID;
begin
  if Length(Value) = 0 then
    Clear
  else
    begin
      GuidValue := StringAsGuid(AnsiString(Value));
      SetAsGuid(GuidValue)
    end;
end;

constructor TCacheModelOptions.Create(Owner: TFIBCustomDataSet);
begin
  inherited Create;
  vOwner := Owner;
  FBufferChunks := vBufferCacheSize
end;

procedure TCacheModelOptions.SetBufferChunks(Value: Integer);
begin
  vOwner.CheckInactive;
  if (Value <= 0) then
    FBufferChunks := vBufferCacheSize
  else
    FBufferChunks := Value;

  if FCacheModelKind = cmkLimitedBufferSize then
    if FBufferChunks < vMinBufferChunksForLimCache then
      FBufferChunks := vMinBufferChunksForLimCache

end;

procedure TCacheModelOptions.SetCacheModelKind(Value: TCacheModelKind);
begin
  if Value <> FCacheModelKind then
    begin
      vOwner.CheckInactive;
      case Value of
        cmkStandard:
          begin
            FreeMem(vOwner.vPartition);
            vOwner.vPartition := nil
          end;
        cmkLimitedBufferSize:
          begin
            if not(csLoading in vOwner.ComponentState) then
              if not vOwner.CanHaveLimitedCache then
                FIBError(feCantUseLimitedCache, [CmpFullName(vOwner)]);
            if FBufferChunks < vMinBufferChunksForLimCache then
              FBufferChunks := vMinBufferChunksForLimCache;
            if not Assigned(vOwner.vPartition) then
              begin
                GetMem(vOwner.vPartition, SizeOf(TRecordsPartition));
                vOwner.vPartition^.BeginPartRecordNo := -1;
                vOwner.vPartition^.EndPartRecordNo := -1;
                vOwner.vPartition^.IncludeBof := false;
                vOwner.vPartition^.IncludeEof := false;
              end;
          end;
      end;
      FCacheModelKind := Value;
    end;
end;

function TFIBCustomDataSet.GetGroupByString: string;
begin
  Result := FQSelect.GroupByClause
end;

function TFIBCustomDataSet.GetMainWhereClause: string;
begin
  Result := FQSelect.MainWhereClause
end;

procedure TFIBCustomDataSet.SetGroupByString(const Value: string);
begin
  FQSelect.GroupByClause := Value
end;

procedure TFIBCustomDataSet.SetMainWhereClause(const Value: string);
begin
  FQSelect.MainWhereClause := Value
end;

function TFIBCustomDataSet.GetPlanClause: string;
begin
  Result := FQSelect.PlanClause
end;

procedure TFIBCustomDataSet.SetPlanClause(const Value: string);
begin
  FQSelect.PlanClause := Value
end;

{$IFDEF CSMonitor}

procedure TFIBCustomDataSet.SetCSMonitorSupport(Value: TCSMonitorSupport);
begin
  FCSMonitorSupport.Assign(Value)
end;

procedure TFIBCustomDataSet.SetCSMonitorSupportToQ;
var
  i: Integer;
  ls: TList;
begin
  ls := TList.Create;
  if Assigned(FQDelete) then
    ls.Add(FQDelete);
  if Assigned(FQInsert) then
    ls.Add(FQInsert);
  if Assigned(FQRefresh) then
    ls.Add(FQRefresh);
  if Assigned(FQUpdate) then
    ls.Add(FQUpdate);
  if Assigned(FQSelect) then
    ls.Add(FQSelect);
  if Assigned(FQSelectDesc) then
    ls.Add(FQSelectDesc);
  if Assigned(FQSelectPart) then
    ls.Add(FQSelectPart);
  if Assigned(FQBookMark) then
    ls.Add(FQBookMark);
  for i := 0 to ls.Count - 1 do
    begin
      TFIBQuery(ls[i]).CSMonitorSupport.Enabled := FCSMonitorSupport.Enabled;
      TFIBQuery(ls[i]).CSMonitorSupport.IncludeDatasetDescription := FCSMonitorSupport.IncludeDatasetDescription;
    end;
  ls.Free;
end;
{$ENDIF}

end.
