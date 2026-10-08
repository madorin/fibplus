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

unit FIBQuery;

interface

{$I FIBPlus.inc}

uses
  SysUtils, Classes, ibase, IB_Intf, IB_Externals, FIBPlatforms,
  DB, fib, FIBDatabase, StdFuncs, IB_ErrorCodes, SqlTxtRtns, pFIBProps,
  pFIBInterfaces
{$IFDEF SUPPORT_ARRAY_FIELD}, pFIBArray {$ENDIF}
  , FMTBcd, Variants, FIBTypes;

type
  // Stream Events
  TCallBackBlobReadWrite = procedure(BlobSize: integer; BytesProcessing: integer; var Stop: boolean) of object;

  TFIBQuery = class;
  TFIBXSQLDA = class;
  TFIBXSQLVAR = class;

  TTypeSetToParam = (tspNull, tspIsNullable, tspScale, tspValue, tspSqlVar);

  // TFIBXSQLVAR
  TFIBXSQLVAR = class(TObject)
  private
    function GetAsBoolean: boolean;
    procedure SetAsBoolean(const Value: boolean);
  protected
    FIndex: integer;
    FModified: boolean;
    FName: string;
    FSqlName: string;
    FRelationName: string;
    FOwnerName: string;
    FAliasName: string;
    FRelationAlias: string;
    FQuery: TFIBQuery;
    FVariantFalse, FVariantTrue: Variant;
    FXSQLVAR: PXSQLVAR; // Point to the PXSQLVAR in the owner object
    FParent: TFIBXSQLDA;
    // Added variables
    FIsMacro: boolean;
    FQuoted: boolean;
    FOldValue: Variant; // Value Param from last ExecQuery
    FDefMacroValue: string;
    FSrvSQLType: integer;
    FSrvSQLSubType: integer;
    FSrvSQLLen: Smallint;
    FSrvSQLScale: Smallint;
    FInWhereClause: boolean;
    FCanForceIsNull: boolean;
    FInitialized: boolean;
    FBeginPosInText: integer;
    FEndPosInText: integer;
    FIsDefferedSetting: boolean;
    FStreamValue: TMemoryStream;
    FWideTempValue: WideString;
    FParDataIsPrepared: boolean;
{$IFDEF SUPPORT_ARRAY_FIELD}
    vFIBArray: TpFIBArray;
    // value of an array parameter, written before the execution (TFIBQuery.PutArrayParams)
    FArrayValue: Variant;
{$ENDIF}
    function GetAsInt64: Int64;
    function GetRelationAlias: string;
    function IsDefferedLongString: boolean;
    // Firebird 4 data types
    function IsDecimalType: boolean;
    function IsTimeZoneType: boolean;
    function GetDecimalValue: TFBDecimal;
    procedure GetTimeZoneValue(out LocalValue: TTimeStamp; out ZoneID: Word; out OffsetMinutes: integer);
    function GetAsTimeZoneID: Word;
    function GetAsTimeZoneOffset: integer;
    function GetAsTimeZoneName: string;
    function GetAsUTCDateTime: TDateTime;

    function GetAsCurrency: Currency;
{$IFNDEF NO_USE_COMP}
    function GetAsComp: Comp;
{$ENDIF}
    function GetAsDateTime: TDateTime;
    function GetAsTimeStamp: TTimeStamp;
    function GetAsDouble: Double;
    function GetAsFloat: Double;
    function GetAsSingle: Float;
    function GetAsLong: Long;
    function GetAsPointer: Pointer;
    function GetAsQuad: TISC_QUAD;
    function GetAsShort: Short;
    function GetAsString: string;
    function GetAsAnsiString: Ansistring;
    function TextCodePage: Word;
    function BlobCodePage: Word;
    function GetAsVariant: Variant;
    function GetAsExtended: Extended;
    function GetAsXSQLVAR: PXSQLVAR;
    function GetIsNull: boolean;
    function GetIsNullable: boolean;
    function GetSize: integer;
    function GetSQLType: integer;
    function GetServerSQLType: integer;
    function GetSQLSubtype: Short;
    function GetServerSQLSubType: integer;
    function GetServerSQLSize: integer;
    function GetServerSQLScale: integer;
    // Array Support
{$IFDEF SUPPORT_ARRAY_FIELD}
    procedure CheckArrayType;
    function GetDimensionCount: integer;
    function GetDimension(Index: integer): TISC_ARRAY_BOUND;
    function GetSliceSize: integer;
    function GetElementType: TFieldType;
    function GetArraySize: integer;
{$ENDIF}
    //
    procedure SetValue(aSQLType, aSize: integer; ValueType: TTypeSetToParam; const aValue; ws: PWideString = nil);

    procedure SetAsCurrency(aValue: Currency);
{$IFNDEF NO_USE_COMP}
    procedure SetAsComp(aValue: Comp); // patchInt64A
{$ENDIF}
    procedure SetAsInt64(aValue: Int64);
    procedure SetAsDateTime(aValue: TDateTime);
    procedure SetAsTime(aValue: TDateTime);
    procedure SetAsDate(aValue: TDateTime);
    procedure SetAsTimeStamp(aValue: TTimeStamp);
    procedure SetAsDouble(aValue: Double);
    procedure SetAsFloat(aValue: Double);
    procedure SetAsSingle(aValue: Float);
    procedure SetAsExtended(aValue: Extended);

    procedure SetAsLong(aValue: Long);
    procedure SetAsQuad(aValue: TISC_QUAD);
    // keeps the long value which the BLOB ID was written from
    procedure SetQuadValue(const aValue: TISC_QUAD);
    procedure SetAsShort(aValue: Short);
    procedure InternalSetAsString(aValue: Pointer; IsWide: boolean; AdjustDeffered: boolean = False);
    procedure SetAsString(const aValue: string);
    procedure SetAsWideString(const aValue: WideString);
    procedure SetAsAnsiString(const aValue: Ansistring);
    procedure SetAsStrData(Len: integer; const aValue);
    function GetAsWideString: WideString;

    procedure SetAsVariant(Value: Variant);

    procedure SetAsXSQLVAR(aValue: PXSQLVAR);
    procedure SetIsNull(aValue: boolean);
    procedure SetIsNullable(aValue: boolean);
    function GetScale: integer;

    procedure SetScale(Value: integer);
    function GetAsBcd: TBcd;
    procedure SetAsBcd(Value: TBcd);

    function GetAsGUID: TGUID;
    procedure SetAsGuid(aValue: TGUID);
    procedure SetSQLLen(A: Smallint);
  public
    constructor Create(AParent: TFIBXSQLDA);
    destructor Destroy; override;
    procedure Assign(Source: TFIBXSQLVAR);

    // procedure SetSQLLen(A:SmallInt);

    function IsNumericType(SQLType: integer): boolean;
    function IsRealType(SQLType: integer): boolean;
    function IsDateTimeType(SQLType: integer): boolean;

    procedure LoadFromFile(const FileName: string); overload;
    procedure LoadFromFile(const FileName: string; cb: TCallBackBlobReadWrite); overload;
    procedure LoadFromStream(Stream: TStream);
    procedure SaveToFile(const FileName: string; cb: TCallBackBlobReadWrite = nil);
    procedure SaveToFileStream(const FileName: string);
    procedure SaveToStream(Stream: TStream);

    procedure Clear;
    function IsParam: boolean;
    function IsBlob: boolean;
    function CharacterSet: string;
    // Array Support
{$IFDEF SUPPORT_ARRAY_FIELD}
    function IsArray: boolean;
    function GetArrayElement(Indexes: array of integer): Variant;
    function GetArrayValues: Variant;
    procedure SetArrayValue(Value: Variant);
    function IsArrayParamValue(const Value: Variant; ServerType: integer): boolean;
{$ENDIF}
    function IsDefMacroValue: boolean;
    procedure SetDefMacroValue;
    //

    property AsCurrency: Currency read GetAsCurrency write SetAsCurrency;
{$IFNDEF NO_USE_COMP}
    property AsComp: Comp read GetAsComp write SetAsComp;
{$ENDIF}
    property AsExtended: Extended read GetAsExtended write SetAsExtended;
    property AsInt64: Int64 read GetAsInt64 write SetAsInt64;
    property AsBcd: TBcd read GetAsBcd write SetAsBcd;
    property AsGuid: TGUID read GetAsGUID write SetAsGuid;
    property AsDateTime: TDateTime read GetAsDateTime write SetAsDateTime;
    property AsDate: TDateTime read GetAsDateTime write SetAsDate;
    property AsTime: TDateTime read GetAsDateTime write SetAsTime;
    property AsTimeStamp: TTimeStamp read GetAsTimeStamp write SetAsTimeStamp;
    property AsDouble: Double read GetAsDouble write SetAsDouble;
    property AsFloat: Double read GetAsFloat write SetAsFloat;
    property AsSingle: Float read GetAsSingle write SetAsSingle;
    property AsInteger: integer read GetAsLong write SetAsLong;
    property AsLong: Long read GetAsLong write SetAsLong;
    property AsPointer: Pointer read GetAsPointer;
    property AsQuad: TISC_QUAD read GetAsQuad write SetAsQuad;
    property AsShort: Short read GetAsShort write SetAsShort;
    property AsString: string read GetAsString write SetAsString;
    property AsWideString: WideString read GetAsWideString write SetAsWideString;
    property AsAnsiString: Ansistring read GetAsAnsiString write SetAsAnsiString;

    property AsVariant: Variant read GetAsVariant write SetAsVariant;
    property AsXSQLVAR: PXSQLVAR read GetAsXSQLVAR write SetAsXSQLVAR;
    property AsBoolean: boolean read GetAsBoolean write SetAsBoolean;
    // TIME/TIMESTAMP WITH TIME ZONE.
    // AsDateTime returns the local time in the value's own time zone.
    procedure SetAsDateTimeTZ(const aValue: TDateTime; aZoneID: Word); overload;
    procedure SetAsDateTimeTZ(const aValue: TDateTime; const aTimeZone: string); overload;
    // Raw Firebird 4 values
    procedure SetAsTimeTZ(const aValue: TISC_TIME_TZ);
    procedure SetAsTimeStampTZ(const aValue: TISC_TIMESTAMP_TZ);
    procedure SetAsInt128(const aValue: TFB_I128; aScale: integer = 0);
    procedure SetAsDec16(const aValue: TFB_DEC16);
    procedure SetAsDec34(const aValue: TFB_DEC34);
    property AsTimeZoneID: Word read GetAsTimeZoneID;
    property AsTimeZoneOffset: integer read GetAsTimeZoneOffset;
    property AsTimeZoneName: string read GetAsTimeZoneName;
    property AsUTCDateTime: TDateTime read GetAsUTCDateTime;
    property Data: PXSQLVAR read FXSQLVAR write FXSQLVAR;
    property IsNull: boolean read GetIsNull write SetIsNull;
    property IsNullable: boolean read GetIsNullable write SetIsNullable;
    property Scale: integer read GetScale write SetScale;
    property Index: integer read FIndex;
    property Modified: boolean read FModified write FModified;
    property Name: string read FName;
    // Parameters get SqlName and RelationName only from ReadParamNames
    property SqlName: string read FSqlName;
    property RelationName: string read FRelationName;
    property OwnerName: string read FOwnerName;
    property AliasName: string read FAliasName;
    property RelationAlias: string read GetRelationAlias;
    property Size: integer read GetSize;
    property ServerSize: integer read GetServerSQLSize;
    property SQLType: integer read GetSQLType;
    property ServerSQLType: integer read GetServerSQLType;
    property SQLSubtype: Short read GetSQLSubtype;
    property ServerSQLSubType: integer read GetServerSQLSubType;
    property Value: Variant read GetAsVariant write SetAsVariant;
    property OldValue: Variant read FOldValue;
    property VariantFalse: Variant read FVariantFalse write FVariantFalse;
    property VariantTrue: Variant read FVariantTrue write FVariantTrue;
    // Added properties
    property IsMacro: boolean read FIsMacro write FIsMacro;
    property Quoted: boolean read FQuoted write FQuoted;
    property DefMacroValue: string read FDefMacroValue write FDefMacroValue;
    property InWhereClause: boolean read FInWhereClause;
    property BeginPosInText: integer read FBeginPosInText;
    property EndPosInText: integer read FEndPosInText;

    // Array Support
{$IFDEF SUPPORT_ARRAY_FIELD}
    property FIBArray: TpFIBArray read vFIBArray;
    property DimensionCount: integer read GetDimensionCount;
    property Dimension[Index: integer]: TISC_ARRAY_BOUND read GetDimension;
    property ElementType: TFieldType read GetElementType;
    property ArraySize: integer read GetArraySize;
{$ENDIF}
  end;

  TFIBXSQLVARArray = array [0 .. 0] of TFIBXSQLVAR;
  PFIBXSQLVARArray = ^TFIBXSQLVARArray;

  // TFIBXSQLVAR
  TFIBXSQLDA = class(TObject)
  private
    FEquelNames: TStringList;
    FCachedNames: TStringList;
    FCount: integer;
    FHasDefferedSettings: boolean;
    procedure AdjustDefferedSettings;
  protected
    FNames: TStringList;
    FQuery: TFIBQuery;
    FSize: integer;
    FXSQLDA: PXSQLDA;
    FXSQLVARs: PFIBXSQLVARArray; // array of FIBXQLVARs
    FIsParams: boolean;
    function GetModified: boolean;
    function GetNames: string;
    function GetRecordSize: integer;
    function GetXSQLDA: PXSQLDA;
    function GetXSQLVAR(Idx: integer): TFIBXSQLVAR;
    function GetXSQLVARByName(const Idx: string): TFIBXSQLVAR;
    procedure Initialize;
    procedure SetCount(Value: integer);
    procedure AddName(const FieldName: string; Idx: integer; aQuoted: boolean);
    procedure SetUnModifiedToVars;
  public
    constructor Create(aIsParams: boolean);
    destructor Destroy; override;
    procedure ClearValues;
    function FindParam(const aParamName: string): TFIBXSQLVAR;
    function ParamByName(const aParamName: string): TFIBXSQLVAR;
    procedure AssignValues(SourceSQLDA: TFIBXSQLDA);
    property Query: TFIBQuery read FQuery;
    property AsXSQLDA: PXSQLDA read GetXSQLDA;
    property ByName[const Idx: string]: TFIBXSQLVAR read GetXSQLVARByName;
    property Count: integer read FCount write SetCount;
    property Modified: boolean read GetModified;
    property Names: string read GetNames;
    property RecordSize: integer read GetRecordSize;
    property Vars[Idx: integer]: TFIBXSQLVAR read GetXSQLVAR; default;
  end;

  // TFIBBatch - basis for batch input and batch output objects.
  TBatchState = (bsNotPrepared, bsFileReady, bsInProcess, bsInError);

  TFIBBatch = class(TObject)
  protected
    FFilename: string;
    FColumns: TFIBXSQLDA;
    FParams: TFIBXSQLDA;
    FState: TBatchState;
    FVersion: integer;
    FCharset: Ansistring;
  public
    procedure ReadyStream; virtual; abstract;
    property Columns: TFIBXSQLDA read FColumns;
    property FileName: string read FFilename write FFilename;
    property Params: TFIBXSQLDA read FParams;
    property State: TBatchState read FState;
  end;

  // TFIBBatchInputStream - see FIBMiscellaneous for good examples.
  TFIBBatchInputStream = class(TFIBBatch)
  public
    function ReadParameters: boolean; virtual; abstract;
  end;

  TFIBBatchInputStreamClass = class of TFIBBatchInputStream;

  // TFIBBatchOutputStream - see FIBMiscellaneous for good examples.
  TFIBBatchOutputStream = class(TFIBBatch)
  protected
  public
    function WriteColumns: boolean; virtual; abstract;
  end;

  TFIBBatchOutputStreamClass = class of TFIBBatchOutputStream;

  // TFIBQuery
  TFIBSQLTypes = (
    SQLUnknown,
    SQLSelect,
    SQLInsert,
    SQLUpdate,
    SQLDelete,
    SQLDDL,
    SQLGetSegment,
    SQLPutSegment,
    SQLExecProcedure,
    SQLStartTransaction,
    SQLCommit,
    SQLRollback,
    SQLSelectForUpdate,
    SQLSetGenerator,
    SQLSavePointOperation
  );

  TOnSQLFetch = procedure(RecordNumber: integer; var StopFetching: boolean) of object;

  TBatchOperation = (boInput, boOutput, boOutputToQuery);
  TBatchAction = (baContinue, baStop, baSkip);
  TBatchErrorAction = (beFail, beAbort, beRetry, beIgnore);

  TOnBatching = procedure(BatchOperation: TBatchOperation; RecNumber: integer; var BatchAction: TBatchAction) of object;
  TOnBatchError = procedure(E: EFIBError; var BatchErrorAction: TBatchErrorAction) of object;

  TAllRowsAffected = record
    Updates: integer;
    Deletes: integer;
    Selects: integer;
    Inserts: integer;
  end;

  TQueryRunStateValues = (qrsInPrepare, qrsInExecute, qrsInClose);
  TQueryRunState = set of TQueryRunStateValues;

  TFIBQuery = class(TComponent, ISQLObject, IFIBQuery)
  private
    FOnBatching: TOnBatching;
    FDoParamCheck: boolean;
    FParser: TSQLParser;
    FTransactionEnding: TNotifyEvent;
    FTransactionEnded: TNotifyEvent;
    FBeforeExecute: TNotifyEvent;
    FAfterExecute: TNotifyEvent;
    FAfterFirstFetch: TNotifyEvent;
{$IFDEF CSMonitor}
    FCSMonitorSupport: TCSMonitorSupport;
    procedure SetMonitorSupport(Value: TCSMonitorSupport);
    function GetCSMonText: string;
{$ENDIF}
    function GetSQLKind: TSQLKind;
  protected
    FBase: TFIBBase;
    FBOF, // At BOF?
    FEof, // At EOF
    FGoToFirstRecordOnExecute,
    // Automatically position record on first record after executing
    FOpen, // Is a cursor open?
    FPrepared: boolean; // Has the query been prepared?
    FRecordCount: integer; // How many records have been read so far?
    FHandle: TISC_STMT_HANDLE; // Once prepared, this accesses the SQL Query

    FOnSQLChanging: TNotifyEvent; // Call this when the SQL is changing.
    FSQL: TStrings; // SQL Query (by user)
    FParamCheck: boolean; // Check for parameters? (just like TQuery)
    FProcessedSQL: string; // SQL Query (pre-processed for param labels)
    FPreparedSQL: Ansistring;
    FSQLParams, // Any parameters to the query.
    FSQLRecord: TFIBXSQLDA; // The current record
    FSQLType: TFIBSQLTypes;
    // Select, update, delete, insert, create, alter, etc...

    FUserSQLParams: TFIBXSQLDA;
    FProcExecuted: boolean;
    FOnSQLFetch: TOnSQLFetch;
    FMacroChar: Char;
    vUserParamsCreated: boolean;
    FCountLockSQL: integer;
    FModifyTable: string;
    FOptions: TpFIBQueryOptions;
    vDiffParams: boolean;
    FOnlySrvParams: TStringList;
    FCallTime: Cardinal;
    FHaveMacros: boolean;
    FNeedForceIsNull: boolean;
    FMacroChanged: boolean;
    FSQLTextChangeCount: integer;
    FHaveStreamParams: boolean;
    FQueryRunState: TQueryRunState;
    FCodePageApplied: boolean;
    FAutoCloseOnTransactionEnd: boolean;
    vFetched: boolean;
    FStatementTimeout: Cardinal;
{$DEFINE FIB_INTERFACE}
{$I FIBQueryPT.inc}
{$UNDEF FIB_INTERFACE}
    procedure SaveStreamedParams(toParams: TFIBXSQLDA);
    procedure ClearStreamedParams;
    procedure SetParamCheck(Value: boolean);
    procedure SetStatementTimeout(Value: Cardinal);
    function TimeoutApplies: boolean;
    procedure ApplyStatementTimeout(Value: Cardinal);
    function GetModifyTable: string;
    procedure DatabaseDisconnecting(Sender: TObject);
    procedure DatabaseConnectionLost(Sender: TObject);
    function GetDatabase: TFIBDatabase;
    function GetDBHandle: PISC_DB_HANDLE;
    function GetEOF: boolean;
    function GetFields(const Idx: integer): TFIBXSQLVAR;
    function GetFieldIndex(const FieldName: string): integer;
    function GetPlan: string;
    function GetRecordCount: integer;
    function GetRowsAffected: integer;
    function GetAllRowsAffected: TAllRowsAffected;

    function GetSQLParams: TFIBXSQLDA;
    function GetTransaction: TFIBTransaction;
    function GetTRHandle: PISC_TR_HANDLE;
    procedure SetDatabase(Value: TFIBDatabase); virtual;
    // Descendants that defer their SQL build it here, before Params or Prepare
    procedure BuildDeferredSQL; virtual;
    procedure SetSQL(Value: TStrings);
    procedure SetMacroChar(Value: Char);
    procedure SetTransaction(Value: TFIBTransaction);
    procedure SQLChanging(Sender: TObject);
    procedure SQLChange(Sender: TObject);
    procedure DoTransactionEnding(Sender: TObject);
    // Added procedures
    procedure SaveRestoreValues(SQLDA: TFIBXSQLDA; IsSave: boolean);

    function GetWhereClause(Index: integer): string;
    procedure SetWhereClause(Index: integer; const WhereClauseTxt: string);
    function GetOrderString: string;
    procedure SetOrderString(const OrderTxt: string);

    function GetGroupByString: string;
    procedure SetGroupByString(const GroupByTxt: string);

    function GetFieldsClause: string;
    procedure SetFieldsClause(const NewFields: string);

    procedure PrepareUserParamsTypes;
    procedure StartStatisticExec(const stText: string);
    procedure EndStatisticExec(const stText: string);
    procedure DoStatisticPrepare(const stText: string);

    function ParamsNotExist(const SQLText: string): boolean;
    procedure PreprocessSQL(const sSQL: String; IsUserSQL: boolean);
    procedure DoBeforeExecute;
    procedure DoAfterExecute;
    procedure DoAfterFirstFetch;
    procedure CloseCursor(Complete: boolean);
    procedure CompleteStatement;
    function CloseOnEof: boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Loaded; override;
    property Handle: TISC_STMT_HANDLE read FHandle;
    property QueryRunState: TQueryRunState read FQueryRunState;
  private
    FRelationAliasesRead: boolean;
    FParamNamesRead: boolean;
    procedure ReadRelationAliases;
    function FullNamesNeeded(NamesCut: boolean): boolean;
    procedure ReadDescribeInfo(SQLDA: TFIBXSQLDA; ReadNames: boolean);
    procedure ReadParamNames;
    function DecodeName(const Name: Ansistring): string;
    procedure ConvertSQLTextToCodePage;
  public
    function TableAliasForField(FieldIndex: integer): string; overload;
    function TableAliasForFieldByName(const aFieldName: string): string;
    // {$IFNDEF BCB}
    function TableAliasForField(const aFieldName: string): string; overload;
    // {$ENDIF}
  private
    FOnBatchError: TOnBatchError;
    FCursorName: string;
  public
    function BatchInput(InputObject: TFIBBatchInputStream): boolean;
    function BatchOutput(OutputObject: TFIBBatchOutputStream): Boolean;

    procedure BatchInputRawFile(const FileName: Ansistring);
    procedure BatchOutputRawFile(const FileName: Ansistring; Version: integer = 3);

    procedure BatchToQuery(ToQuery: TFIBQuery; Mappings: TStrings);
  public
    function Call(ErrCode: ISC_STATUS; RaiseError: boolean): ISC_STATUS;
    procedure CheckClosed(const OpName: Ansistring);
    // raise error if query is not closed.
    procedure CheckOpen(const OpName: Ansistring);
    // raise error if query is not open.
    procedure CheckValidStatement; // raise error if statement is invalid.
    procedure Close; // close the query.
    function Current: TFIBXSQLDA;
    procedure ExecQuery; virtual; // ExecQuery the query.
    procedure ExecuteImmediate;
    // procedure CancelQuery;  // Only For IB
{$IFDEF SUPPORT_IB2007}
    procedure ExecuteAsBatch; overload;
    procedure ExecuteAsBatch(const SQLs: array of Ansistring); overload;
{$ENDIF}
    procedure FreeHandle;
    function Next: TFIBXSQLDA;
    procedure Prepare; // Prepare the query.

    function FieldByName(const FieldName: string): TFIBXSQLVAR;
    function FindField(const FieldName: string): TFIBXSQLVAR;
    function FN(const FieldName: string): TFIBXSQLVAR;

    function FieldByOrigin(const TableName, FieldName: string): TFIBXSQLVAR; overload;
    function SQLFieldName(const aFieldName: string): string;
{$IFDEF SUPPORT_ARRAY_FIELD}
    procedure PrepareArrayFields;
    procedure PutArrayParams;
    procedure PrepareArraySqlVar(SqlVar: TFIBXSQLVAR; const RelName, SqlName: string);
{$ENDIF}
    procedure SetParamValues(const ParamValues: array of Variant); overload;
    procedure SetParamValues(const ParamNames: string; ParamValues: array of Variant); overload;
    procedure ExecWP(const ParamValues: array of Variant); overload;
    procedure ExecWP(const ParamNames: string; ParamValues: array of Variant); overload;
    // Exec Query with ParamValues
    procedure ExecWPS(const ParamSources: array of ISQLObject); overload;
    procedure ExecWPS(ParamSource: ISQLObject; AllRecords: boolean = True); overload;

    procedure BeginModifySQLText;
    procedure EndModifySQLText;
    function CountModifySQLText: integer;
    function GetMainWhereIndex: integer;
    function GetMainWhereClause: string;
    procedure SetMainWhereClause(const Value: string);
    function IsProc: boolean; virtual;
    function ParamByName(const ParamName: string): TFIBXSQLVAR;
    function FindParam(const aParamName: string): TFIBXSQLVAR;
    procedure ApplyMacro;
    procedure RestoreMacroDefaultValues;
    function FieldCount: integer;
    function SQLDescribeInfo(InfoRequest: array of AnsiChar): PXSQLDA; deprecated;
    property Bof: boolean read FBOF;
    property DBHandle: PISC_DB_HANDLE read GetDBHandle;
    property Eof: boolean read GetEOF;
    property FldByName[const FieldName: string]: TFIBXSQLVAR read FieldByName; default;
    property Fields[const Idx: integer]: TFIBXSQLVAR read GetFields;
    property FieldIndex[const FieldName: string]: integer read GetFieldIndex;
    property Open: boolean read FOpen;
    property Params: TFIBXSQLDA read GetSQLParams;
    property Plan: string read GetPlan;
    property Prepared: boolean read FPrepared;
    property RecordCount: integer read GetRecordCount;
    property RowsAffected: integer read GetRowsAffected;
    property AllRowsAffected: TAllRowsAffected read GetAllRowsAffected;
    property SQLType: TFIBSQLTypes read FSQLType;
    property TRHandle: PISC_TR_HANDLE read GetTRHandle;
    property ProcExecuted: boolean read FProcExecuted write FProcExecuted;
    property OnSQLFetch: TOnSQLFetch read FOnSQLFetch write FOnSQLFetch;
    // for internal use
    property OnlySrvParams: TStringList read FOnlySrvParams;
  protected
    FConditions: TConditions;
    procedure AddCondition(const Name, Condition: string; Enabled: boolean);
    procedure SetConditions(Value: TConditions);
  published
    property Conditions: TConditions read FConditions write SetConditions;
  public
    { ISQLObject }
    function ParamCount: integer;
    function ParamName(ParamIndex: integer): string;
    function FieldName(FieldIndex: integer): string;
    function FieldsCount: integer;
    function FieldExist(const FieldName: string; var FieldIndex: integer): boolean;
    function ParamExist(const ParamName: string; var ParamIndex: integer): boolean;
    function FieldValue(const FieldName: string; Old: boolean): Variant; overload;
    function FieldValue(const FieldIndex: integer; Old: boolean): Variant; overload;
    function ParamValue(const ParamName: string): Variant; overload;
    function ParamValue(const ParamIndex: integer): Variant; overload;
    function DefMacroValue(const MacroName: string): string;
    procedure SetParamValue(const ParamIndex: integer; aValue: Variant);
    function IEof: boolean;
    procedure INext;

    { End ISQLObject }

    function ReadySQLText(ForChangeExecSQL: boolean = True): string;
    property SQLTextChangeCount: integer read FSQLTextChangeCount;
  private
    procedure SetPlanClause(const Value: string);
    function GetPlanClause: string;
  public

    procedure AssignProperties(Source: TFIBQuery);
    function WhereClausesCount: integer;
    property WhereClause[Index: integer]: string read GetWhereClause write SetWhereClause;
    property MainWhereClause: string read GetMainWhereClause write SetMainWhereClause;
    property IndexMainWhere: integer read GetMainWhereIndex;
    property CursorName: string read FCursorName write FCursorName;
    property OrderClause: string read GetOrderString write SetOrderString;
    property GroupByClause: string read GetGroupByString write SetGroupByString;
    property FieldsClause: string read GetFieldsClause write SetFieldsClause;
    property PlanClause: string read GetPlanClause write SetPlanClause;
    property ModifyTable: string read GetModifyTable;
    property CallTime: Cardinal read FCallTime;
    property MacroChanged: boolean read FMacroChanged;
    property SQLKind: TSQLKind read GetSQLKind;
    property BeforeExecute: TNotifyEvent read FBeforeExecute write FBeforeExecute;
    property AfterExecute: TNotifyEvent read FAfterExecute write FAfterExecute;

  published
    property Transaction: TFIBTransaction read GetTransaction write SetTransaction;
    property Database: TFIBDatabase read GetDatabase write SetDatabase;

    property GoToFirstRecordOnExecute: boolean read FGoToFirstRecordOnExecute write FGoToFirstRecordOnExecute default True;
    property ParamCheck: boolean read FParamCheck write SetParamCheck default True;
    // ms; 0: the attachment value applies (Session.StatementTimeout). For a SELECT the timer runs until EOF
    // FIBNoStatementTimeout: no timeout for this statement, even with a Session value
    property StatementTimeout: Cardinal read FStatementTimeout write SetStatementTimeout default 0;
    property SQL: TStrings read FSQL write SetSQL;

    property OnSQLChanging: TNotifyEvent read FOnSQLChanging write FOnSQLChanging;
    property Options: TpFIBQueryOptions read FOptions write FOptions stored False;
    property OnBatching: TOnBatching read FOnBatching write FOnBatching;
    property OnBatchError: TOnBatchError read FOnBatchError write FOnBatchError;
    property TransactionEnding: TNotifyEvent read FTransactionEnding write FTransactionEnding;
    property TransactionEnded: TNotifyEvent read FTransactionEnded write FTransactionEnded;
    property AfterFirstFetch: TNotifyEvent read FAfterFirstFetch write FAfterFirstFetch;
{$IFDEF CSMonitor}
    property CSMonitorSupport: TCSMonitorSupport read FCSMonitorSupport write SetMonitorSupport;
{$ENDIF}
  end;

procedure BlobToStream(ModelVar: TFIBXSQLVAR; BlobID: TISC_QUAD; Stream: TStream);

const
  // StatementTimeout value: this statement ignores Session.StatementTimeout (firebird.conf still applies)
  FIBNoStatementTimeout = High(Cardinal);

  ExecProcPrefix = 'EXECUTE ';
  // Statistic consts
  scPrepareCount    = 'PrepareCount';
  scExecuteCount    = 'ExecuteCount';
  scSumTimeExecute  = 'SumTimeExecute';
  scAvgTimeExecute  = 'AvgTimeExecute';
  scMaxTimeExecute  = 'MaxTimeExecute';
  scLastTimeExecute = 'LastTimeExecute';
  scLastQuery       = 'LastQueryName';

  fibGUID_NULL: TGUID = '{00000000-0000-0000-0000-000000000000}';

var
  DisableEncodingSQLText: boolean;
  TraceString: string;

implementation

uses
  FIBMiscellaneous, StrUtil,
  IBBlobFilter, FIBConsts, FIBCloneComponents, FIBCharSets
  // Added uses
{$IFNDEF NO_MONITOR}
  , FIBSQLMonitor
{$ENDIF}
{$IFDEF CSMonitor}
  , FIBDataSet, pFIBDataSet
{$ENDIF}
  ;

const
  cPlanMaxLength = 16384;

  // Clients before Firebird 4 return names over 31 bytes empty, later ones cut them
function ClientTruncatesNames(const ClientLibrary: IIbClientLibrary): boolean;
begin
  Result := (ClientLibrary.Version.Product = fpFirebird) and (ClientLibrary.Version.Major >= 4);
end;

function XSQLVARName(const Name: array of AnsiChar; NameLength: Short): Ansistring;
var
  L: integer;
begin
  L := NameLength;
  if L > Length(Name) then
    L := Length(Name)
  else if L < 0 then
    L := 0;
  SetString(Result, PAnsiChar(@Name[0]), L);
end;

// A name filling the XSQLVAR array may have been cut by the client
function XSQLVARNameCut(NameLength: Short): boolean;
begin
  Result := NameLength >= LENGTH_METANAMES - 1;
end;

// TFIBXSQLVAR
constructor TFIBXSQLVAR.Create(AParent: TFIBXSQLDA);
begin
  FParent := AParent;
  FVariantFalse := 0;
  FVariantTrue := 1;
end;

destructor TFIBXSQLVAR.Destroy; // override;
begin
{$IFDEF SUPPORT_ARRAY_FIELD}
  if Assigned(vFIBArray) then
    vFIBArray.Free;
{$ENDIF}
  inherited Destroy;
  FreeAndNil(FStreamValue);
end;

{$WARNINGS OFF}

procedure TFIBXSQLVAR.Assign(Source: TFIBXSQLVAR);
var
  szBuff: PAnsiChar;
  s_bhandle, d_bhandle: TISC_BLOB_HANDLE;
  bSourceBlob, bDestBlob: boolean;
  iSegs, iMaxSeg, iSize: Long;
  iBlobType: Short;
  SP: TFIBXSQLVAR;
  DestSQLType, SrcSQLType: integer;
begin
  if IsMacro then
  begin
    AsString := Source.AsString;
    Exit;
  end;

  szBuff := nil;
  SrcSQLType := Source.FXSQLVAR^.SQLType and (not 1);
  DestSQLType := FXSQLVAR^.SQLType and (not 1);
  bSourceBlob := SrcSQLType = SQL_BLOB;
  bDestBlob := True;
  s_bhandle := nil;
  d_bhandle := nil;
  try
    if (Source.IsNull) then
    begin
      IsNull := True;
      Exit;
    end
    else if SrcSQLType = SQL_ARRAY then
    begin
      // array ID written by TFIBQuery.PutArrayParams
      AsQuad := Source.AsQuad;
      Exit;
    end
    else if DestSQLType = SQL_ARRAY then
      Exit;

    if (DestSQLType <> SQL_BLOB) and not bSourceBlob then
    begin
      AsXSQLVAR := Source.AsXSQLVAR;
      Exit;
    end
    else if (SrcSQLType <> SQL_BLOB) then
    begin
      szBuff := nil;
      FIBAlloc(szBuff, 0, Source.FXSQLVAR^.sqllen);
      Move(Source.FXSQLVAR^.sqldata[0], szBuff[0], Source.FXSQLVAR^.sqllen);
      iSize := Source.FXSQLVAR^.sqllen;
    end
    else if (DestSQLType <> SQL_BLOB) then
    begin
      if FParent = FQuery.FUserSQLParams then
      begin
        if not FQuery.Prepared then
          FQuery.Prepare;
        SP := FQuery.FSQLParams.FindParam(Name);
        bDestBlob := not((SP = nil) or (SP.FXSQLVAR^.SQLType and (not 1) <> SQL_BLOB));
        if bDestBlob then
          AsQuad := SP.AsQuad;
      end
      else
        bDestBlob := False;
    end;
    if bSourceBlob then
    begin
      // read the blob
      Source.FQuery.Call(Source.FQuery.Database.ClientLibrary.isc_open_blob2
        (StatusVector, Source.FQuery.DBHandle, Source.FQuery.TRHandle,
        @s_bhandle, PISC_QUAD(Source.FXSQLVAR.sqldata), 0, nil), True);
      with Source.FQuery, Source.FQuery.Database do
        try
          GetBlobInfo(ClientLibrary, @s_bhandle, iSegs, iMaxSeg, iSize, iBlobType);
          szBuff := nil;
          FIBAlloc(szBuff, 0, iSize);
          ReadBlob(ClientLibrary, @s_bhandle, szBuff, iSize);
          if (not bDestBlob) // avoid
            or (FXSQLVAR^.SQLSubtype <> Source.FXSQLVAR^.SQLSubtype) then
            IBFilterBuffer(Database, szBuff, iSize, Source.FXSQLVAR^.SQLSubtype, False); // ivan_ra

        finally
          Source.FQuery.Call(ClientLibrary.isc_close_blob(StatusVector, @s_bhandle), True);
        end;
    end;

    if bDestBlob then
    begin
      // write the blob
      FQuery.Call(FQuery.Database.ClientLibrary.isc_create_blob2(StatusVector,
        FQuery.DBHandle, FQuery.TRHandle, @d_bhandle, PISC_QUAD(FXSQLVAR.sqldata), 0, nil), True);
      try
        if (not bSourceBlob) // avoid conversation
          or (FXSQLVAR^.SQLSubtype <> Source.FXSQLVAR^.SQLSubtype) then
          IBFilterBuffer(FQuery.Database, szBuff, iSize, Source.FXSQLVAR^.SQLSubtype, True); // ivan_ra
        WriteBlob(FQuery.Database.ClientLibrary, @d_bhandle, szBuff, iSize);
        IsNull := False;
      finally
        FQuery.Call(FQuery.Database.ClientLibrary.isc_close_blob(StatusVector, @d_bhandle), True);
      end;
    end
    else
    begin
      // just copy the buffer
      FXSQLVAR.SQLType := SQL_TEXT;
      FXSQLVAR.sqllen := iSize;
      FIBAlloc(FXSQLVAR.sqldata, iSize, iSize);
      Move(szBuff[0], FXSQLVAR^.sqldata[0], iSize);
    end;
  finally
    FIBAlloc(szBuff, 0, 0);
  end;
end;

procedure TFIBXSQLVAR.SetSQLLen(A: Smallint);
begin
  FXSQLVAR^.sqllen := A
end;

function TFIBXSQLVAR.GetAsInt64: Int64;
begin
  Result := 0;
  if not IsNull then
    case FXSQLVAR^.SQLType and (not 1) of
      SQL_TEXT, SQL_VARYING:
        begin
          try
            Result := StrToInt64(AsWideString);
          except
            on E: Exception do
              FIBError(feInvalidDataConversion, [nil]);
          end;
        end;
      SQL_SHORT:
        Result := PShort(FXSQLVAR^.sqldata)
          ^ div Trunc(E10[-FXSQLVAR^.sqlscale]);
      SQL_LONG: Result := PLong(FXSQLVAR^.sqldata)^ div Trunc(E10[-FXSQLVAR^.sqlscale]);
      SQL_INT64:
        Result := PInt64(FXSQLVAR^.sqldata)
          ^ div Trunc(E10[-FXSQLVAR^.sqlscale]);
      SQL_INT128, SQL_DEC16, SQL_DEC34:
        if not FBRawToInt64(FXSQLVAR^.SQLType and (not 1), FXSQLVAR^.sqlscale, FXSQLVAR^.sqldata, Result) then
          FIBError(feInvalidDataConversion, [nil]);

      SQL_DOUBLE, SQL_FLOAT, SQL_D_FLOAT: Result := Trunc(AsDouble);
      IB_SQL_BOOLEAN: Result := PShort(FXSQLVAR^.sqldata)^;
      SQL_BOOLEAN: Result := PByte(FXSQLVAR^.sqldata)^;
      SQL_NULL: Result := 0;
    else
      FIBError(feInvalidDataConversion, [nil]);
    end;
end;

function TFIBXSQLVAR.IsDecimalType: boolean;
begin
  case FXSQLVAR^.SQLType and (not 1) of
    SQL_INT128, SQL_DEC16, SQL_DEC34: Result := True;
  else
    Result := False;
  end;
end;

function TFIBXSQLVAR.IsTimeZoneType: boolean;
begin
  case FXSQLVAR^.SQLType and (not 1) of
    SQL_TIME_TZ, SQL_TIME_TZ_EX, SQL_TIMESTAMP_TZ, SQL_TIMESTAMP_TZ_EX: Result := True;
  else
    Result := False;
  end;
end;

function TFIBXSQLVAR.GetDecimalValue: TFBDecimal;
begin
  if not IsDecimalType then
    FIBError(feInvalidDataConversion, [nil]);
  Result := FBDecimalFromRaw(FXSQLVAR^.SQLType and (not 1), FXSQLVAR^.sqlscale, FXSQLVAR^.sqldata);
end;

function TFIBXSQLVAR.GetAsCurrency: Currency;
var
  C: Int64;
begin
  if IsNull then
    Result := 0
  else if IsDecimalType then
  begin
    // Currency is Int64 scaled by 10000
    if not FBRawToScaledInt64(FXSQLVAR^.SQLType and (not 1), FXSQLVAR^.sqlscale, FXSQLVAR^.sqldata, -4, C) then
      FIBError(feInvalidDataConversion, [nil]);
    Result := PCurrency(@C)^;
  end
  else if (FQuery.Database.SQLDialect < 3) or (FXSQLVAR^.SQLType and (not 1) <> SQL_INT64) then
    Result := GetAsDouble
  else
    Result := PInt64(FXSQLVAR^.sqldata)^ * E10[FXSQLVAR^.sqlscale];
end;

{$IFNDEF NO_USE_COMP}

function TFIBXSQLVAR.GetAsComp: Comp;
begin
  InitFPU;
  Result := 0;
  if not IsNull then
    if (FXSQLVAR^.SQLType and (not 1)) <> SQL_INT64 then
      Result := AsDouble
    else
      Result := PInt64(FXSQLVAR^.sqldata)^ * E10[FXSQLVAR^.sqlscale];
end;
{$ENDIF}

const
  IBBuffDateDelta = 678576;

function TFIBXSQLVAR.GetAsTimeStamp: TTimeStamp;
var
  ZoneID: Word;
  Offset: integer;
begin
  if IsNull then
  begin
    Result.Time := 0;
    Result.Date := 0;
  end
  else
    case FXSQLVAR^.SQLType and (not 1) of
      SQL_TEXT, SQL_VARYING:
        try
          Result := DateTimeToTimeStamp(StrToDate(AsWideString));
        except
          on E: EConvertError do
            FIBError(feInvalidDataConversion, [nil]);
        end;
      SQL_TYPE_TIME:
        begin
          Result.Date := 0;
          Result.Time := PISC_TIME(FXSQLVAR^.sqldata)^ div 10
        end;
      SQL_TYPE_DATE:
        begin
          Result.Date := PISC_DATE(FXSQLVAR^.sqldata)^ + IBBuffDateDelta;
          Result.Time := 0
        end;
      SQL_TIMESTAMP:
        with PISC_QUAD(FXSQLVAR^.sqldata)^ do
        begin
          Result.Date := gds_quad_high + IBBuffDateDelta;
          Result.Time := gds_quad_low div 10
        end;
      SQL_TIME_TZ, SQL_TIME_TZ_EX, SQL_TIMESTAMP_TZ, SQL_TIMESTAMP_TZ_EX:
        begin
          GetTimeZoneValue(Result, ZoneID, Offset);
        end;
    else
      FIBError(feInvalidDataConversion, [nil]);
    end;
end;

(*
  * Returns the local time of the value in its own time zone.
  * For TIME WITH TIME ZONE LocalValue.Date is 0.
*)
procedure TFIBXSQLVAR.GetTimeZoneValue(out LocalValue: TTimeStamp; out ZoneID: Word; out OffsetMinutes: integer);
var
  vSQLType: integer;
  vTime: TISC_TIME_TZ_EX;
  vTimeStamp: TISC_TIMESTAMP_TZ_EX;
begin
  vSQLType := FXSQLVAR^.SQLType and (not 1);
  // The extended forms only append ext_offset to the basic ones
  case vSQLType of
    SQL_TIME_TZ, SQL_TIME_TZ_EX:
      begin
        if vSQLType = SQL_TIME_TZ_EX then
          vTime := PISC_TIME_TZ_EX(FXSQLVAR^.sqldata)^
        else
        begin
          vTime.utc_time := PISC_TIME_TZ(FXSQLVAR^.sqldata)^.utc_time;
          vTime.time_zone := PISC_TIME_TZ(FXSQLVAR^.sqldata)^.time_zone;
          vTime.ext_offset := FBKnownZoneOffset(vTime.time_zone);
        end;
        ZoneID := vTime.time_zone;
        OffsetMinutes := vTime.ext_offset;
        LocalValue.Date := 0;
        LocalValue.Time := FBTimeTZToMSecs(vTime);
      end;
    SQL_TIMESTAMP_TZ, SQL_TIMESTAMP_TZ_EX:
      begin
        if vSQLType = SQL_TIMESTAMP_TZ_EX then
          vTimeStamp := PISC_TIMESTAMP_TZ_EX(FXSQLVAR^.sqldata)^
        else
        begin
          vTimeStamp.utc_timestamp := PISC_TIMESTAMP_TZ(FXSQLVAR^.sqldata)
            ^.utc_timestamp;
          vTimeStamp.time_zone := PISC_TIMESTAMP_TZ(FXSQLVAR^.sqldata)
            ^.time_zone;
          vTimeStamp.ext_offset := FBKnownZoneOffset(vTimeStamp.time_zone);
        end;
        ZoneID := vTimeStamp.time_zone;
        OffsetMinutes := vTimeStamp.ext_offset;
        LocalValue := MSecsToTimeStamp(FBTimeStampTZToMSecs(vTimeStamp));
      end;
  else
    FIBError(feInvalidDataConversion, [nil]);
  end;
end;

function TFIBXSQLVAR.GetAsTimeZoneID: Word;
var
  ts: TTimeStamp;
  Offset: integer;
begin
  if IsNull or not IsTimeZoneType then
    Result := FBGmtZoneID
  else
    GetTimeZoneValue(ts, Result, Offset);
end;

function TFIBXSQLVAR.GetAsTimeZoneOffset: integer;
var
  ts: TTimeStamp;
  ZoneID: Word;
begin
  if IsNull or not IsTimeZoneType then
    Result := 0
  else
    GetTimeZoneValue(ts, ZoneID, Result);
end;

function TFIBXSQLVAR.GetAsTimeZoneName: string;
begin
  if IsNull or not IsTimeZoneType then
    Result := ''
  else
    Result := FBTimeZoneName(AsTimeZoneID);
end;

function TFIBXSQLVAR.GetAsUTCDateTime: TDateTime;
begin
  Result := 0;
  if not IsNull then
    case FXSQLVAR^.SQLType and (not 1) of
      SQL_TIME_TZ, SQL_TIME_TZ_EX: Result := (PISC_TIME(FXSQLVAR^.sqldata)^ div 10) / MSecsPerDay;
      SQL_TIMESTAMP_TZ, SQL_TIMESTAMP_TZ_EX: Result := FBTimeStampToDateTime(PISC_TIMESTAMP(FXSQLVAR^.sqldata)^);
    else
      Result := AsDateTime;
    end;
end;

procedure TFIBXSQLVAR.SetAsDateTimeTZ(const aValue: TDateTime; const aTimeZone: string);
var
  sSQLType: integer;
  S: string;
begin
  sSQLType := ServerSQLType;
  if (sSQLType = SQL_TIME_TZ) or (sSQLType = SQL_TIME_TZ_EX) or ((sSQLType = 0) and (Trunc(aValue) = 0)) then
    S := FormatDateTime('hh":"nn":"ss"."zzz', aValue)
  else
    S := FormatDateTime('yyyy"-"mm"-"dd" "hh":"nn":"ss"."zzz', aValue);
  // The server resolves the local time in the given time zone
  AsString := S + ' ' + aTimeZone;
end;

procedure TFIBXSQLVAR.SetAsTimeTZ(const aValue: TISC_TIME_TZ);
begin
  SetValue(SQL_TIME_TZ, SizeOf(TISC_TIME_TZ), tspValue, aValue);
end;

procedure TFIBXSQLVAR.SetAsTimeStampTZ(const aValue: TISC_TIMESTAMP_TZ);
begin
  SetValue(SQL_TIMESTAMP_TZ, SizeOf(TISC_TIMESTAMP_TZ), tspValue, aValue);
end;

procedure TFIBXSQLVAR.SetAsInt128(const aValue: TFB_I128; aScale: integer = 0);
begin
  SetValue(SQL_INT128, SizeOf(TFB_I128), tspValue, aValue);
  if aScale <> 0 then
    Scale := aScale;
end;

procedure TFIBXSQLVAR.SetAsDec16(const aValue: TFB_DEC16);
begin
  SetValue(SQL_DEC16, SizeOf(TFB_DEC16), tspValue, aValue);
end;

procedure TFIBXSQLVAR.SetAsDec34(const aValue: TFB_DEC34);
begin
  SetValue(SQL_DEC34, SizeOf(TFB_DEC34), tspValue, aValue);
end;

procedure TFIBXSQLVAR.SetAsDateTimeTZ(const aValue: TDateTime; aZoneID: Word);
var
  sSQLType: integer;
  ZoneName: string;
begin
  if aZoneID = FBSessionZoneID then
  begin
    sSQLType := ServerSQLType;
    if (sSQLType = SQL_TIME_TZ) or (sSQLType = SQL_TIME_TZ_EX) then
      AsTime := aValue
    else
      AsDateTime := aValue;
    Exit;
  end;
  ZoneName := FBTimeZoneName(aZoneID);
  if ZoneName = '' then
    FIBError(feInvalidDataConversion, [nil]);
  SetAsDateTimeTZ(aValue, ZoneName);
end;

function TFIBXSQLVAR.GetAsDateTime: TDateTime;
const
  MSecsPerDay10 = MSecsPerDay * 10;
begin
  Result := 0;
  if not IsNull then
    case FXSQLVAR^.SQLType and (not 1) of
      SQL_TEXT, SQL_VARYING:
        try
          Result := StrToDate(AsWideString);
        except
          on E: EConvertError do
            FIBError(feInvalidDataConversion, [nil]);
        end;
      SQL_TYPE_TIME:
        begin
          Result := PISC_TIME(FXSQLVAR^.sqldata)^ / MSecsPerDay10;
        end;
      SQL_TYPE_DATE:
        begin
          Result := PISC_DATE(FXSQLVAR^.sqldata)^ - IBDateDelta;
        end;
      SQL_TIMESTAMP:
        begin
          { Result:=
            PISC_QUAD(FXSQLVAR^.sqldata)^.gds_quad_high-IBDateDelta+
            PISC_QUAD(FXSQLVAR^.sqldata)^.gds_quad_low/MSecsPerDay10; }

          Result := HookTimeStampToDateTime(AsTimeStamp);
        end;
      SQL_TIME_TZ, SQL_TIME_TZ_EX: Result := AsTimeStamp.Time / MSecsPerDay;
      SQL_TIMESTAMP_TZ, SQL_TIMESTAMP_TZ_EX: Result := HookTimeStampToDateTime(AsTimeStamp);
    else
      FIBError(feInvalidDataConversion, [nil]);
    end;
end;

function TFIBXSQLVAR.GetAsDouble: Double;
begin
  Result := 0;
  if not IsNull then
    case FXSQLVAR^.SQLType and (not 1) of
      SQL_TEXT, SQL_VARYING:
        begin
          try
            Result := StrToFloat(AsWideString);
          except
            on E: Exception do
              FIBError(feInvalidDataConversion, [nil]);
          end;
        end;
      SQL_SHORT: Result := PShort(FXSQLVAR^.sqldata)^ * E10[FXSQLVAR^.sqlscale];
      SQL_LONG: Result := PLong(FXSQLVAR^.sqldata)^ * E10[FXSQLVAR^.sqlscale];
      SQL_FLOAT: Result := PFloat(FXSQLVAR^.sqldata)^;
      SQL_INT64: Result := PInt64(FXSQLVAR^.sqldata)^ * E10[FXSQLVAR^.sqlscale];
      SQL_DOUBLE, SQL_D_FLOAT: Result := PDouble(FXSQLVAR^.sqldata)^;
      SQL_INT128, SQL_DEC16, SQL_DEC34:
        Result := FBRawToDouble(FXSQLVAR^.SQLType and (not 1), FXSQLVAR^.sqlscale, FXSQLVAR^.sqldata);
      IB_SQL_BOOLEAN, SQL_BOOLEAN:
        if AsBoolean then
          Result := 1
        else
          Result := 0;
      SQL_NULL: Result := 0;
    else
      FIBError(feInvalidDataConversion, [nil]);
    end;
end;

function TFIBXSQLVAR.GetAsSingle: Float;
begin
  Result := 0;
  try
    Result := AsDouble;
  except
    on E: EOverflow do
      FIBError(feInvalidDataConversion, [nil]);
  end;
end;

function TFIBXSQLVAR.GetAsFloat: Double;
begin
  Result := GetAsDouble;
end;

function TFIBXSQLVAR.GetAsLong: Long;
var
  vInt64: Int64;
begin
  Result := 0;
  if not IsNull then
    case FXSQLVAR^.SQLType and (not 1) of
      SQL_TEXT, SQL_VARYING:
        begin
          try
            Result := StrToInt(AsWideString);
          except
            on E: Exception do
              FIBError(feInvalidDataConversion, [nil]);
          end;
        end;
      SQL_SHORT: Result := Trunc(PShort(FXSQLVAR^.sqldata)^ * E10[FXSQLVAR^.sqlscale]);
      SQL_LONG:
        begin
          Result := Trunc(PLong(FXSQLVAR^.sqldata)^ * E10[FXSQLVAR^.sqlscale]);
        end;
      SQL_INT64: Result := Trunc(PInt64(FXSQLVAR^.sqldata)^ * E10[FXSQLVAR^.sqlscale]);
      SQL_INT128, SQL_DEC16, SQL_DEC34:
        begin
          vInt64 := AsInt64;
          if (vInt64 > MaxInt) or (vInt64 < -MaxInt - 1) then
            FIBError(feInvalidDataConversion, [nil]);
          Result := vInt64;
        end;

      SQL_DOUBLE, SQL_FLOAT, SQL_D_FLOAT: Result := Trunc(AsDouble);
      IB_SQL_BOOLEAN, SQL_BOOLEAN: Result := Ord(AsBoolean);
      SQL_NULL: Result := 0;

    else
      FIBError(feInvalidDataConversion, [nil]);
    end;
end;

function TFIBXSQLVAR.GetAsPointer: Pointer;
begin
  if not IsNull then
    Result := FXSQLVAR^.sqldata
  else
    Result := nil;
end;

function TFIBXSQLVAR.GetAsQuad: TISC_QUAD;
begin
  if IsNull then
  begin
    Result.gds_quad_high := 0;
    Result.gds_quad_low := 0;
  end
  else
    case FXSQLVAR^.SQLType and (not 1) of
      SQL_BLOB, SQL_ARRAY, SQL_QUAD: Result := PISC_QUAD(FXSQLVAR^.sqldata)^;
    else
      FIBError(feInvalidDataConversion, [nil]);
    end;
end;

function TFIBXSQLVAR.GetAsShort: Short;
begin
  Result := 0;
  try
    Result := AsLong;
  except
    on E: Exception do
      FIBError(feInvalidDataConversion, [nil]);
  end;
end;

function TFIBXSQLVAR.GetAsString: string;
begin
  Result := GetAsWideString
end;

function TFIBXSQLVAR.TextCodePage: Word;
begin
  Result := FQuery.Database.Capabilities.TextCodePage(Byte(FXSQLVAR^.SQLSubtype));
end;

function TFIBXSQLVAR.BlobCodePage: Word;
begin
  if FXSQLVAR^.SQLSubtype = 1 then
    Result := FQuery.Database.Capabilities.BlobCodePage(Byte(FXSQLVAR^.sqlscale))
  else
    Result := FIBCodePageSystem;
end;

function TFIBXSQLVAR.GetAsAnsiString: Ansistring;
var
  sz: TDataBuffer;
  str_len: integer;
  bs: TFIBBlobStream;
  byteStr: FIBByteString;
begin
  Result := '';
  // Check null, if so return a default string
  if not IsNull then
    case FXSQLVAR^.SQLType and (not 1) of
      // 0: Result:='';
      SQL_ARRAY: Result := '(ARRAY)';
      SQL_BLOB:
        try
          Result := '(BLOB)'; { return on error }
          if IsParam and (FStreamValue = nil) then
            Exit; // BlobHandle may be invalid
          if FStreamValue <> nil then
          begin
            if FStreamValue.Size = 0 then
              Result := ''
            else
            begin
              SetLength(Result, FStreamValue.Size);
              FStreamValue.Position := 0;
              FStreamValue.Read(Result[1], FStreamValue.Size);
{$IFDEF D2009+}
              if Assigned(FQuery.Database) then
                SetStringCodePage(RawByteString(Result), BlobCodePage);
{$ENDIF}
            end;
          end
          else
          begin
            bs := TFIBBlobStream.Create;
            try
              bs.Mode := bmRead;
              with FQuery do
              begin
                bs.InternalSetCharSet(Byte(FXSQLVAR^.sqlscale));
                bs.Database := Database;
                bs.Transaction := Transaction;
                if qoStartTransaction in Options then
                  if (Transaction <> nil) and not Transaction.InTransaction then
                    Transaction.StartTransaction;
              end;
              bs.BlobID := AsQuad;
              bs.blobSubType := FXSQLVAR^.SQLSubtype;
              Result := bs.AsString;

            finally
              bs.Free;
            end;
          end;
        except
          // BlobHandle is invalid!
        end;

      SQL_TEXT, SQL_VARYING:
        begin
          sz := FXSQLVAR^.sqldata;
          if (FXSQLVAR^.SQLType and (not 1) = SQL_TEXT) then
            str_len := FXSQLVAR^.sqllen
          else
          begin
            str_len := PWord(sz)^; // It is isc_vax_integer(LocalData, 2);
            Inc(sz, 2);
          end;
{$IFDEF D2009+}
          // before tagging: SetLength of a shared string drops the code page; spaces are never in
          // multi-byte characters
          if qoTrimCharFields in FQuery.Options then
            while (str_len > 0) and (PAnsiChar(sz)[str_len - 1] = ' ') do
              Dec(str_len);
{$ENDIF}
          SetLength(byteStr, str_len);
          if str_len > 0 then
            Move(sz^, byteStr[1], str_len);

{$IFDEF D2009+}
          if Assigned(FQuery.Database) and (str_len > 0) then
            SetStringCodePage(byteStr, TextCodePage);
          Result := byteStr;
{$ELSE}
          if Assigned(FQuery.Database) and (Byte(FXSQLVAR^.SQLSubtype) in FQuery.Database.UnicodeCharsets) then
          begin
            if FQuery.Database.NeedUnicodeFieldsTranslation then
              Result := Ansistring(UTF8Decode(byteStr))
            else
              Result := byteStr
          end
          else
            Result := byteStr;

          if qoTrimCharFields in FQuery.Options then
            DoTrimRight(Result);
{$ENDIF}
        end;
      SQL_TYPE_DATE: Result := DateToStr(AsDateTime);
      SQL_TIMESTAMP: Result := DateTimeToStr(AsDateTime);
      SQL_TYPE_TIME: Result := TimeToStr(AsTime);
      SQL_SHORT, SQL_LONG:
        if FXSQLVAR^.sqlscale <> 0 then
          Result := FloatToStr(AsDouble)
        else
          Result := IntToStr(AsLong);
      SQL_INT64:
        if FXSQLVAR^.sqlscale = 0 then
          Result := IntToStr(AsInt64)
        else
          with FXSQLVAR^ do
{$IFDEF D_XE3}with FormatSettings do {$ENDIF}
            begin
              Result := Int64WithScaleToStr(PInt64(sqldata)^, -sqlscale, DecimalSeparator)
            end;
      SQL_DOUBLE, SQL_FLOAT, SQL_D_FLOAT: Result := FloatToStr(AsDouble);
      SQL_INT128: Result := Ansistring(FBDecimalToPlainStr(GetDecimalValue, LocalDecimalSeparator));
      SQL_DEC16, SQL_DEC34: Result := Ansistring(FBDecimalToStr(GetDecimalValue, LocalDecimalSeparator));
      SQL_TIME_TZ, SQL_TIME_TZ_EX: Result := Ansistring(TimeToStr(AsDateTime) + ' ' + AsTimeZoneName);
      SQL_TIMESTAMP_TZ, SQL_TIMESTAMP_TZ_EX: Result := Ansistring(DateTimeToStr(AsDateTime) + ' ' + AsTimeZoneName);
      IB_SQL_BOOLEAN, SQL_BOOLEAN:
        if AsBoolean then
          Result := TrueStr
        else
          Result := FalseStr;
      SQL_NULL: Result := '';
    else
      FIBError(feInvalidDataConversion, [nil]);
    end;
end;

function TFIBXSQLVAR.GetAsExtended: Extended;
begin
  Result := 0;
  if not IsNull then
    case FXSQLVAR^.SQLType and (not 1) of
      SQL_TEXT, SQL_VARYING:
        try
          Result := StrToFloat(AsWideString);
        except
          on E: Exception do
            FIBError(feInvalidDataConversion, [nil]);
        end;
      SQL_SHORT: Result := Long(PShort(FXSQLVAR^.sqldata)^) * E10[FXSQLVAR^.sqlscale];
      SQL_LONG: Result := PLong(FXSQLVAR^.sqldata)^ * E10[FXSQLVAR^.sqlscale];
      SQL_FLOAT: Result := PFloat(FXSQLVAR^.sqldata)^;
      SQL_INT64: Result := PInt64(FXSQLVAR^.sqldata)^ * E10[FXSQLVAR^.sqlscale];
      SQL_DOUBLE, SQL_D_FLOAT: Result := PDouble(FXSQLVAR^.sqldata)^;
      SQL_INT128, SQL_DEC16, SQL_DEC34:
        Result := FBRawToDouble(FXSQLVAR^.SQLType and (not 1), FXSQLVAR^.sqlscale, FXSQLVAR^.sqldata);
      IB_SQL_BOOLEAN, SQL_BOOLEAN: Result := Ord(AsBoolean);
      SQL_NULL: Result := 0;
    else
      FIBError(feInvalidDataConversion, [nil]);
    end;
end;

function TFIBXSQLVAR.GetAsVariant: Variant;
var
  vBcd: TBcd;
begin
  if IsMacro then
    Result := AsWideString
  else if IsNull then
    Result := NULL
  // Check null, if so return a default string
  else
    case FXSQLVAR^.SQLType and (not 1) of
      SQL_ARRAY:
{$IFDEF SUPPORT_ARRAY_FIELD}
        if FParent.FIsParams then
          // the value set by the user, written at ExecQuery
          if VarIsEmpty(FArrayValue) then
            Result := '(Array)'
          else
            Result := FArrayValue
        else
          Result := GetArrayValues;
{$ELSE}
        Result := '(Array)';
{$ENDIF}
      SQL_BLOB:
        // Result := '(BLOB)';
        Result := AsString;
      SQL_TEXT, SQL_VARYING:
        // a variant keeps no code page
        if Assigned(FQuery.Database) and ((Byte(FXSQLVAR^.SQLSubtype) in FQuery.Database.UnicodeCharsets)
          {$IFDEF D2009+} or not IsSystemCodePage(TextCodePage){$ENDIF}) then
          Result := GetAsWideString
        else
          Result := AsAnsiString;
      SQL_TYPE_DATE, SQL_TYPE_TIME, SQL_TIMESTAMP: Result := AsDateTime;
      SQL_SHORT, SQL_LONG:
        if FXSQLVAR^.sqlscale <> 0 then
          Result := AsDouble
        else
          Result := AsLong;
      SQL_INT64:
        if FXSQLVAR^.sqlscale = 0 then
          Result := AsInt64
        else if FXSQLVAR^.sqlscale >= (-4) then
          Result := AsExtended
        else
          Result := AsDouble;
      SQL_DOUBLE, SQL_FLOAT, SQL_D_FLOAT: Result := AsDouble;
      SQL_INT128, SQL_DEC16, SQL_DEC34:
        // NaN, Infinity and values out of TBcd range are returned as Double
        if FBRawToBcd(FXSQLVAR^.SQLType and (not 1), FXSQLVAR^.sqlscale, FXSQLVAR^.sqldata, vBcd) then
          VarFMTBcdCreate(Result, vBcd)
        else
          Result := FBRawToDouble(FXSQLVAR^.SQLType and (not 1), FXSQLVAR^.sqlscale, FXSQLVAR^.sqldata);
      SQL_TIME_TZ, SQL_TIME_TZ_EX, SQL_TIMESTAMP_TZ, SQL_TIMESTAMP_TZ_EX: Result := AsDateTime;
      IB_SQL_BOOLEAN, SQL_BOOLEAN: Result := AsBoolean;
      SQL_NULL: Result := NULL;
    else
      FIBError(feInvalidDataConversion, [nil]);
    end;
end;

function TFIBXSQLVAR.GetAsXSQLVAR: PXSQLVAR;
begin
  Result := FXSQLVAR;
end;

function TFIBXSQLVAR.GetIsNull: boolean;
begin
  Result := (FStreamValue = nil) and not IsMacro;
  if Result then
    Result := ((not FParent.FIsParams) and (FQuery.RecordCount = 0) and (FQuery.SQLType <> SQLExecProcedure)) or
      (IsNullable and (FXSQLVAR^.sqlind^ = -1) or (FXSQLVAR^.SQLType in [0, 1]));
end;

function TFIBXSQLVAR.GetIsNullable: boolean;
begin
  Result := not IsMacro and (FXSQLVAR^.SQLType and 1 = 1);
  // Result := (FXSQLVAR^.sqltype and 1 = 1);
  if Result and not Assigned(FXSQLVAR^.sqlind) then
    FIBAlloc(FXSQLVAR^.sqlind, 0, SizeOf(Short));
end;

procedure TFIBXSQLVAR.LoadFromFile(const FileName: string);
var
  fs: TFileStream;
begin
  fs := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(fs);
  finally
    fs.Free;
  end;
end;

procedure TFIBXSQLVAR.LoadFromFile(const FileName: string; cb: TCallBackBlobReadWrite);
var
  q: TISC_QUAD;
begin
  q := FileToBlob(FileName, FQuery.Database, FQuery.Transaction, cb);
  AsQuad := q;
  if Assigned(FStreamValue) then
  begin
    FStreamValue.Free;
    FStreamValue := nil;
  end;
end;

procedure TFIBXSQLVAR.LoadFromStream(Stream: TStream);
begin
  if FStreamValue = nil then
    FStreamValue := TMemoryStream.Create;
  FStreamValue.LoadFromStream(Stream);
  FWideTempValue := '';
  FQuery.FHaveStreamParams := True;
  FXSQLVAR^.SQLType := SQL_BLOB
end;

procedure TFIBXSQLVAR.SaveToFileStream(const FileName: string);
var
  fs: TFileStream;
begin
  fs := TFileStream.Create(FileName, fmCreate or fmShareExclusive);
  try
    SaveToStream(fs);
  finally
    fs.Free;
  end;
end;

procedure TFIBXSQLVAR.SaveToFile(const FileName: string; cb: TCallBackBlobReadWrite = nil);
begin
  if not ExistBlobFilter(FQuery.Database, FXSQLVAR^.SQLSubtype) then
    BlobToFile(AsQuad, FileName, FQuery.Database, FQuery.Transaction, cb)
  else
    SaveToFileStream(FileName)
end;

procedure BlobToStream(ModelVar: TFIBXSQLVAR; BlobID: TISC_QUAD; Stream: TStream);
var
  bs: TFIBBlobStream;
begin
  bs := TFIBBlobStream.Create;
  try
    bs.blobSubType := ModelVar.AsXSQLVAR^.SQLSubtype; // ivan_ra
    bs.Mode := bmRead;
    with ModelVar.FQuery do
    begin
      bs.Database := Database;
      bs.Transaction := Transaction;
      if qoStartTransaction in Options then
        if (Transaction <> nil) and not Transaction.InTransaction then
          Transaction.StartTransaction;
    end;
    bs.BlobID := BlobID;
    bs.SaveToStream(Stream);
  finally
    bs.Free;
  end;
end;

procedure TFIBXSQLVAR.SaveToStream(Stream: TStream);
begin
  BlobToStream(Self, AsQuad, Stream);
end;

function TFIBXSQLVAR.GetSize: integer;
begin
  Result := FXSQLVAR^.sqllen;
end;

procedure TFIBXSQLVAR.Clear;
begin
  IsNull := True;
end;
// Array Support

{$IFDEF SUPPORT_ARRAY_FIELD}

function TFIBXSQLVAR.IsArray: boolean;
begin
  Result := (FXSQLVAR^.SQLType and (not 1) = SQL_ARRAY)
end;

procedure TFIBXSQLVAR.CheckArrayType;
begin
  if not IsArray or not Assigned(vFIBArray) then
    if FParent.FIsParams then
      FIBError(feNotIsArrayField, [Name])
    else
      FIBError(feNotIsArrayField, [RelationName + '.' + SqlName]);
end;

function TFIBXSQLVAR.GetDimensionCount: integer;
begin
  CheckArrayType;
  Result := vFIBArray.DimensionCount
end;

function TFIBXSQLVAR.GetElementType: TFieldType;
begin
  CheckArrayType;
  Result := vFIBArray.ArrayType
end;

function TFIBXSQLVAR.GetDimension(Index: integer): TISC_ARRAY_BOUND;
begin
  CheckArrayType;
  Result := vFIBArray.Dimension[Index]
end;

function TFIBXSQLVAR.GetSliceSize: integer;
begin
  CheckArrayType;
  Result := vFIBArray.ArraySize
end;

procedure TFIBXSQLVAR.SetArrayValue(Value: Variant);
const
  NullID: TISC_QUAD = (gds_quad_high: 0; gds_quad_low: 0);
begin
  if FParent.FIsParams then
  begin
    // the column of the parameter is known only after Prepare
    SetValue(SQL_ARRAY, SizeOf(TISC_QUAD), tspValue, NullID);
    FArrayValue := Value;
    Exit;
  end;
  CheckArrayType;
  vFIBArray.SetArrayValue(Value, FXSQLVAR^.sqldata, FQuery.DBHandle, FQuery.TRHandle);
  AsQuad := PISC_QUAD(FXSQLVAR^.sqldata)^;
end;

// Byte arrays set to a parameter of an unknown type are BLOB data (VariantToStream)
function TFIBXSQLVAR.IsArrayParamValue(const Value: Variant; ServerType: integer): boolean;
begin
  Result := IsArray or (ServerType = SQL_ARRAY) or (FParent.FIsParams and (ServerType = 0) and
    (VarType(Value) and varTypeMask <> varByte));
end;

function TFIBXSQLVAR.GetArrayValues: Variant;
begin
  CheckArrayType;
  // sqldata of a NULL column may keep the array ID of the previous row
  if IsNull then
    Result := NULL
  else
    Result := vFIBArray.GetArrayValues(FXSQLVAR^.sqldata, FQuery.DBHandle, FQuery.TRHandle);
end;

function TFIBXSQLVAR.GetArrayElement(Indexes: array of integer): Variant;
begin
  CheckArrayType;
  if IsNull then
    Result := NULL
  else
    Result := vFIBArray.GetElement(FXSQLVAR^.sqldata, Indexes, FQuery.DBHandle, FQuery.TRHandle);
end;

function TFIBXSQLVAR.GetArraySize: integer;
begin
  CheckArrayType;
  Result := vFIBArray.ArraySize
end;
{$ENDIF}
// End Array Support

procedure TFIBXSQLVAR.SetDefMacroValue;
begin
  AsWideString := FDefMacroValue
end;

function TFIBXSQLVAR.IsDefMacroValue: boolean;
begin
  Result := IsMacro and (FDefMacroValue = AsWideString)
end;

function TFIBXSQLVAR.GetSQLType: integer;
begin
  Result := FXSQLVAR^.SQLType and (not 1);
end;

function TFIBXSQLVAR.GetSQLSubtype: Short;
begin
  Result := FXSQLVAR^.SQLSubtype;
end;

function TFIBXSQLVAR.IsRealType(SQLType: integer): boolean;
begin
  Result := (((SQLType = SQL_INT64) or (SQLType = SQL_LONG) or
    (SQLType = SQL_SHORT) or (SQLType = SQL_INT128)) and (Scale <> 0)) or
    (SQLType = SQL_DOUBLE) or (SQLType = SQL_FLOAT) or (SQLType = SQL_D_FLOAT)
    or (SQLType = SQL_DEC16) or (SQLType = SQL_DEC34)
end;

function TFIBXSQLVAR.IsNumericType(SQLType: integer): boolean;
begin
  Result := (SQLType = SQL_INT64) or (SQLType = SQL_LONG) or
    (SQLType = SQL_SHORT) or (SQLType = SQL_DOUBLE) or (SQLType = SQL_FLOAT) or
    (SQLType = SQL_D_FLOAT) or (SQLType = SQL_INT128) or (SQLType = SQL_DEC16) or (SQLType = SQL_DEC34)
end;

// A string over 32767 bytes set before Prepare: already a blob, but encoded
// only when the server parameter is known
function TFIBXSQLVAR.IsDefferedLongString: boolean;
begin
  Result := FIsDefferedSetting and (FStreamValue <> nil) and (Length(FWideTempValue) > 0);
end;

function TFIBXSQLVAR.IsDateTimeType(SQLType: integer): boolean;
begin
  Result := (SQLType = SQL_TIMESTAMP) or (SQLType = SQL_TYPE_DATE) or
    (SQLType = SQL_TYPE_TIME) or (SQLType = SQL_TIMESTAMP_TZ) or
    (SQLType = SQL_TIME_TZ) or (SQLType = SQL_TIMESTAMP_TZ_EX) or (SQLType = SQL_TIME_TZ_EX)
end;

function TFIBXSQLVAR.GetServerSQLType: integer;
var
  SrvSqlVar: TFIBXSQLVAR;
begin
  if not FQuery.Prepared then
    Result := 0 // Unknown
  else
    with FParent do
      if not FIsParams or (FParent.FQuery.FSQLParams = FParent) then
        if FInitialized then
          Result := FSrvSQLType
        else
          Result := GetSQLType
      else
      begin
        if FSrvSQLType <> 0 then
          Result := FSrvSQLType
        else
        begin
          SrvSqlVar := FQuery.FSQLParams.FindParam(FName);
          if SrvSqlVar = nil then
            Result := GetSQLType
          else if SrvSqlVar.FSrvSQLType = 0 then
            Result := SrvSqlVar.SQLType
          else
            Result := SrvSqlVar.FSrvSQLType;
          FSrvSQLType := Result
        end;
      end;
end;

function TFIBXSQLVAR.GetServerSQLScale: integer;
var
  SrvSqlVar: TFIBXSQLVAR;
begin
  with FParent do
    if not FIsParams or (FParent.FQuery.FSQLParams = FParent) then
      if FInitialized then
        Result := GetScale
      else
        Result := FSrvSQLScale
    else
    begin
      if FSrvSQLScale <> 0 then
        Result := FSrvSQLScale
      else
      begin
        SrvSqlVar := FQuery.FSQLParams.FindParam(FName);
        if SrvSqlVar = nil then
          Result := GetScale
        else if SrvSqlVar.FSrvSQLScale = 0 then
          Result := SrvSqlVar.Scale
        else
          Result := SrvSqlVar.FSrvSQLScale;
        FSrvSQLScale := Result;
      end;
    end;
end;

function TFIBXSQLVAR.GetServerSQLSize: integer;
var
  SrvSqlVar: TFIBXSQLVAR;
begin
  if not FQuery.Prepared then
    Result := 0 // Unknown
  else
    with FParent do
      if not FIsParams or (FParent.FQuery.FSQLParams = FParent) then
        if FInitialized then
          Result := GetSize
        else
          Result := FSrvSQLLen
      else
      begin
        if FSrvSQLLen <> 0 then
          Result := FSrvSQLLen
        else
        begin
          SrvSqlVar := FQuery.FSQLParams.FindParam(FName);
          if SrvSqlVar = nil then
            Result := GetSize
          else if SrvSqlVar.FSrvSQLLen = 0 then
            Result := SrvSqlVar.Size
          else
            Result := SrvSqlVar.FSrvSQLLen;
          FSrvSQLLen := Result;
        end;
      end;
end;

function TFIBXSQLVAR.GetServerSQLSubType: integer;
var
  SrvSqlVar: TFIBXSQLVAR;
begin
  if not FQuery.Prepared then
    Result := 0 // Unknown
  else
    with FParent do
      if not FIsParams or (FParent.FQuery.FSQLParams = FParent) then
        if FInitialized then
          Result := GetSQLSubtype
        else
          Result := FSrvSQLSubType
      else
      begin
        if FSrvSQLSubType <> 0 then
          Result := FSrvSQLSubType
        else
        begin
          SrvSqlVar := FQuery.FSQLParams.FindParam(FName);
          if SrvSqlVar = nil then
            Result := GetSQLSubtype
          // not initialized yet: as described (see GetServerSQLType)
          else if SrvSqlVar.FSrvSQLType = 0 then
            Result := SrvSqlVar.SQLSubtype
          else
            Result := SrvSqlVar.FSrvSQLSubType;
          FSrvSQLSubType := Result;
        end;
      end;
end;

procedure InternalSetNull(xvar: TFIBXSQLVAR; const aValue: boolean);
begin
  with xvar, xvar.FXSQLVAR^ do
  begin
    if aValue then
    begin
      if (xvar.FXSQLVAR^.SQLType in [0, 1]) then
      begin
        SQLType := SQL_TEXT;
        sqllen := 0;
        FreeMem(sqldata);
        sqldata := nil;
      end;
      if (not IsNullable) then
        IsNullable := True;
      sqlind^ := -1;
      { if xvar.IsParam then
        sqllen  :=0; }
    end
    else if IsNullable then
      sqlind^ := 0;
    FModified := True;
  end;
end;

procedure InternalSetNullable(xvar: TFIBXSQLVAR; const aValue: boolean);
begin
  if (aValue <> xvar.IsNullable) then
    with xvar.FXSQLVAR^ do
      if aValue then
      begin
        SQLType := SQLType or 1;
        FIBAlloc(sqlind, 0, SizeOf(Short));
      end
      else
      begin
        SQLType := SQLType and (not 1);
        FIBAlloc(sqlind, 0, 0);
      end;
end;

procedure InternalSetValue(xvar: TFIBXSQLVAR; aSQLType, aSize: integer; const aValue);
begin
  with xvar, xvar.FXSQLVAR^ do
  begin
    if IsNull then
      IsNull := False;
    sqlscale := 0;
    if (aSize = 0) then
    begin
      sqllen := aSize;
      ReallocMem(sqldata, 1);
    end
    else if (sqllen <> aSize) then
    begin
      sqllen := aSize;
      ReallocMem(sqldata, aSize);
    end;
    SQLType := aSQLType or (SQLType and 1);
    Move(aValue, sqldata^, sqllen);
    FModified := True;
  end;
end;

procedure InternalSetAsXSQLVAR(xvar: TFIBXSQLVAR; aValue: PXSQLVAR);
var
  local_sqlind: PShort;
  local_sqldata: TDataBuffer;
  local_sqllen: integer;
begin
  with xvar, xvar.FXSQLVAR^ do
  begin
    local_sqlind := sqlind;
    local_sqldata := sqldata;
    Move(aValue^, FXSQLVAR^, SizeOf(TXSQLVAR));
    sqlind := local_sqlind;
    sqldata := local_sqldata;

    if (sqlind = nil) then
    begin
      if (aValue^.sqlind <> nil) then
      begin
        FIBAlloc(sqlind, 0, SizeOf(Short));
        sqlind^ := aValue^.sqlind^;
      end;
    end
    else if (aValue^.sqlind = nil) then
    begin
      FIBAlloc(sqlind, 0, 0);
      sqlind := nil;
    end
    else
      sqlind^ := aValue^.sqlind^;

    if (SQLType and (not 1)) = SQL_VARYING then
      local_sqllen := sqllen + 2
    else
      local_sqllen := sqllen;
    if local_sqllen <> 0 then
    begin
      FIBAlloc(sqldata, 0, local_sqllen);
      Move(aValue^.sqldata[0], FXSQLVAR^.sqldata[0], local_sqllen);
    end
    else
    begin
      ReallocMem(sqldata, 1);
    end;
    FModified := True;
  end;
end;

procedure TFIBXSQLVAR.SetValue(aSQLType, aSize: integer; ValueType: TTypeSetToParam; const aValue; ws: PWideString = nil);
var
  i: integer;
  xvar: TFIBXSQLVAR;
  OldIsNull: boolean;
begin
{$IFDEF SUPPORT_ARRAY_FIELD}
  // any other value replaces a pending array value
  if ((ValueType = tspValue) and (aSQLType <> SQL_ARRAY)) or
    (ValueType = tspSqlVar) or ((ValueType = tspNull) and boolean(aValue)) then
    VarClear(FArrayValue);
{$ENDIF}
  // a non-string value replaces the kept string, not the BLOB ID written from it
  if (ws = nil) and ((ValueType = tspValue) and (aSQLType <> SQL_BLOB) and (aSQLType <> SQL_ARRAY) or
    (ValueType = tspSqlVar) or (ValueType = tspNull) and boolean(aValue)) then
    FWideTempValue := '';
  OldIsNull := IsNull;
  i := NonAnsiIndexOf(FParent.FEquelNames, FName);
  // if (FParent.FEquelNames.Count=0) or not FParent.FEquelNames.Find(FName,i) then
  if i < 0 then
    case ValueType of
      tspNull: InternalSetNull(Self, boolean(aValue));
      tspIsNullable: InternalSetNullable(Self, boolean(aValue));
      tspScale: FXSQLVAR^.sqlscale := integer(aValue);
      tspValue: InternalSetValue(Self, aSQLType, aSize, aValue);
      tspSqlVar: InternalSetAsXSQLVAR(Self, PXSQLVAR(aValue));
    end
  else
    while (i < FParent.FEquelNames.Count) and (FParent.FEquelNames[i] = FName) do
    begin
      xvar := FParent[integer(FParent.FEquelNames.Objects[i])];
      case ValueType of
        tspNull: InternalSetNull(xvar, boolean(aValue));
        tspIsNullable: InternalSetNullable(xvar, boolean(aValue));
        tspScale: xvar.FXSQLVAR^.sqlscale := integer(aValue);
        tspValue:
          begin
            InternalSetValue(xvar, aSQLType, aSize, aValue);
            if ws <> nil then
              xvar.FWideTempValue := ws^
            else if (aSQLType <> SQL_BLOB) and (aSQLType <> SQL_ARRAY) then
              xvar.FWideTempValue := '';
          end;
        tspSqlVar: InternalSetAsXSQLVAR(xvar, PXSQLVAR(aValue))
      end;
      Inc(i)
    end;
  FInitialized := True;
  if FCanForceIsNull and not(qoNoForceIsNull in FQuery.Options) then
  begin
    if OldIsNull <> IsNull then
      FQuery.FNeedForceIsNull := True;
  end;
  if IsMacro and not FQuery.FMacroChanged then
    if VarToStr(Value) <> VarToStr(OldValue) then
      FQuery.FMacroChanged := True;
end;

procedure TFIBXSQLVAR.SetAsInt64(aValue: Int64);
begin
  if FQuery.Database.SQLDialect < 3 then
    SetAsLong(aValue) // For avoid IB4 bug
  else
    SetValue(SQL_INT64, SizeOf(Int64), tspValue, aValue)
end;

procedure TFIBXSQLVAR.SetAsCurrency(aValue: Currency);
begin
  if FQuery.Database.SQLDialect < 3 then
    SetAsDouble(aValue)
  else
  begin
    SetValue(SQL_INT64, SizeOf(Currency), tspValue, aValue);
    SetScale(-4);
  end;
end;

{$IFNDEF NO_USE_COMP}

procedure TFIBXSQLVAR.SetAsComp(aValue: Comp);
begin
  SetValue(SQL_INT64, SizeOf(Comp), tspValue, aValue)
end;
{$ENDIF}

procedure TFIBXSQLVAR.SetAsTimeStamp(aValue: TTimeStamp);
var
  tq: TISC_QUAD;
begin
  with tq do
  begin
    gds_quad_high := aValue.Date - IBBuffDateDelta;
    gds_quad_low := aValue.Time * 10;
  end;
  SetValue(SQL_TIMESTAMP, SizeOf(TISC_QUAD), tspValue, tq);
end;

procedure TFIBXSQLVAR.SetAsTime(aValue: TDateTime);
var
  sSQLType: integer;
  vTime: ISC_TIME;
begin
  sSQLType := ServerSQLType;
  if sSQLType = 0 then
  begin
    // the server type is not known yet, AdjustDefferedSettings completes it
    FIsDefferedSetting := True;
    FParent.FHasDefferedSettings := True;
  end;
  if (sSQLType = SQL_TIME_TZ) or (sSQLType = SQL_TIME_TZ_EX) then
  begin
    // TIME in the session time zone, a TIMESTAMP would be resolved at 1899-12-30
    vTime := DateTimeToTimeStamp(aValue).Time * 10;
    SetValue(SQL_TYPE_TIME, SizeOf(ISC_TIME), tspValue, vTime);
  end
  else
    AsTimeStamp := DateTimeToTimeStamp(aValue);
end;

procedure TFIBXSQLVAR.SetAsDate(aValue: TDateTime);
begin
  AsTimeStamp := DateTimeToTimeStamp(Trunc(aValue));
end;

procedure TFIBXSQLVAR.SetAsDateTime(aValue: TDateTime);
begin
  AsTimeStamp := DateTimeToTimeStamp(aValue);
end;

procedure TFIBXSQLVAR.SetAsDouble(aValue: Double);
var
  sSQLType: integer;
  vDec: TFB_DEC34;
begin
  sSQLType := ServerSQLType;
  if sSQLType = 0 then
  begin
    // the server type is not known yet, AdjustDefferedSettings completes it
    FIsDefferedSetting := True;
    FParent.FHasDefferedSettings := True;
  end;
  // DECFLOAT gets the shortest decimal representation (0.1 and not 0.1000000000000000055...)
  if ((sSQLType = SQL_DEC16) or (sSQLType = SQL_DEC34)) and FBDecimalToDec34(DoubleToFBDecimal(aValue), vDec) then
    SetValue(SQL_DEC34, SizeOf(TFB_DEC34), tspValue, vDec)
  else
    SetValue(SQL_DOUBLE, SizeOf(Double), tspValue, aValue)
end;

procedure TFIBXSQLVAR.SetAsSingle(aValue: Float);
begin
  SetValue(SQL_FLOAT, SizeOf(Float), tspValue, aValue)
end;

procedure TFIBXSQLVAR.SetAsFloat(aValue: Double);
begin
  SetAsDouble(aValue)
end;

procedure TFIBXSQLVAR.SetAsExtended(aValue: Extended);
var
  vScale: integer;
begin
  if (FQuery.Database.SQLDialect < 3) then
    SetAsDouble(aValue)
  else
  begin
    vScale := ExtPrecision(aValue) - 18;
    AsInt64 := Round(aValue * E10[-vScale]);
    SetScale(vScale);
  end;
end;

procedure TFIBXSQLVAR.SetAsLong(aValue: Long);
begin
  SetValue(SQL_LONG, SizeOf(Long), tspValue, aValue);
end;

procedure TFIBXSQLVAR.SetAsQuad(aValue: TISC_QUAD);
begin
  // the last assignment wins, a kept long value would replace the BLOB ID at the execute
  if FStreamValue <> nil then
  begin
    FreeAndNil(FStreamValue);
    FWideTempValue := '';
  end;
  SetQuadValue(aValue);
end;

procedure TFIBXSQLVAR.SetQuadValue(const aValue: TISC_QUAD);
var
  vSQLType: integer;
begin
  if SQLType and (not 1) <> SQL_ARRAY then
    vSQLType := SQL_BLOB
  else
    vSQLType := SQL_ARRAY;
  SetValue(vSQLType, SizeOf(TISC_QUAD), tspValue, aValue)
end;

procedure TFIBXSQLVAR.SetAsShort(aValue: Short);
begin
  SetValue(SQL_SHORT, SizeOf(Short), tspValue, aValue)
end;

procedure TFIBXSQLVAR.InternalSetAsString(aValue: Pointer; IsWide: boolean; AdjustDeffered: boolean = False);
// Value may be Ansistring or widestring
var
  CodePage: Word;
  // encoded again from FWideTempValue once the server type is known
  Provisional: Boolean;
  sSubType, sSQLScale: Short;
  sSQLType, vSQLType, vSize: integer;
  vValue: Ansistring;
  B: boolean;

  function ServerBlobCodePage(SubType, CharSetID: Short): Word;
  begin
    if SubType = 1 then
      Result := FQuery.Database.Capabilities.BlobCodePage(Byte(CharSetID))
    else
      Result := FIBCodePageSystem;
  end;

  // SqlName of a parameter is filled only by ReadParamNames
  function IsDBKey: Boolean;
  var
    RawName: AnsiString;
  begin
    RawName := XSQLVARName(FXSQLVAR^.SqlName, FXSQLVAR^.sqlname_length);
    Result := (RawName = 'DB_KEY') or (RawName = 'RDB$DB_KEY');
  end;

begin
  sSQLType := ServerSQLType;
  sSubType := ServerSQLSubType;
  sSQLScale := GetServerSQLScale;
  CodePage := FIBCodePageSystem;
  Provisional := False;
  if AdjustDeffered then
  begin
    case sSQLType of
      SQL_TEXT, SQL_VARYING:
        begin
          CodePage := FQuery.Database.Capabilities.TextCodePage(Byte(sSubType));
          FIsDefferedSetting := False;
        end;
      SQL_BLOB:
        begin
          CodePage := ServerBlobCodePage(sSubType, sSQLScale);
          FIsDefferedSetting := False;
        end;
    end;
  end
  // Unicode Delphi: kept until the server type is known
  else if not IsMacro and ({$IFDEF D2009+}True{$ELSE}FQuery.Database.NeedUnicodeFieldsTranslation{$ENDIF}) then
  begin
    if IsWide then
      FWideTempValue := PWideString(aValue)^
    else
{$IFDEF D2009+}
      // with its own code page, lost in the buffer
      FWideTempValue := string(PAnsiString(aValue)^);
{$ELSE}
      FWideTempValue := '';
{$ENDIF}

    case sSQLType of
      0:
        begin
          FIsDefferedSetting := True;
          Provisional := True;
          FParent.FHasDefferedSettings := True;
          case FXSQLVAR^.SQLType of
            SQL_TEXT, SQL_VARYING:
              if not FParDataIsPrepared then
                CodePage := FQuery.Database.Capabilities.TextCodePage(Byte(FXSQLVAR^.SQLSubtype));
            SQL_BLOB:
              CodePage := ServerBlobCodePage(FXSQLVAR^.SQLSubtype, FXSQLVAR^.sqlscale);
          end; // case
        end;
      SQL_TEXT, SQL_VARYING:
        begin
          if not FParDataIsPrepared then
            CodePage := FQuery.Database.Capabilities.TextCodePage(Byte(sSubType));
          FIsDefferedSetting := False;
        end;
      SQL_BLOB:
        begin
          CodePage := ServerBlobCodePage(sSubType, sSQLScale);
          FIsDefferedSetting := False;
        end;
    end; // case

  end
  else
    FIsDefferedSetting := False;

  if IsWide then
  begin
    if CodePage = FIBCodePageUTF8 then
      vValue := UTF8Encode(PWideString(aValue)^)
    else
    begin
      FWideTempValue := PWideString(aValue)^;
      // not sent: macros go into the SQL text, provisional bytes are encoded again
      if IsMacro or Provisional then
        vValue := Ansistring(PWideString(aValue)^)
      else
        vValue := EncodeString(PWideString(aValue)^, CodePage);
    end;
  end
  else if CodePage = FIBCodePageUTF8 then
  begin
    if Length(FWideTempValue) = 0 then
      vValue := UTF8Encode(PAnsiString(aValue)^)
    else
    begin
      vValue := UTF8Encode(FWideTempValue);
      FWideTempValue := '';
    end;
  end
  else if (CodePage <> FIBCodePageSystem) and not Provisional then
  begin
{$IFDEF D2009+}
    // already in the code page (not deferred values: tagged by the described type)
    if not AdjustDeffered and (StringCodePage(PAnsiString(aValue)^) = CodePage) then
      vValue := PAnsiString(aValue)^
    else
{$ENDIF}
    if Length(FWideTempValue) = 0 then
      vValue := EncodeString(string(PAnsiString(aValue)^), CodePage)
    else
      vValue := EncodeString(FWideTempValue, CodePage);
  end
  else
    vValue := PAnsiString(aValue)^;
  if CodePage = FIBCodePageUTF8 then
    FXSQLVAR^.SQLSubtype := FQuery.Database.UTF8CharSetID
  else if (CodePage <> FIBCodePageSystem) and ((sSQLType = SQL_TEXT) or (sSQLType = SQL_VARYING)) then
    FXSQLVAR^.SQLSubtype := sSubType;
  if Length(vValue) > 32767 then
    sSQLType := SQL_BLOB;
  if (sSQLType = SQL_BLOB) then
  begin
    if FStreamValue = nil then
      FStreamValue := TMemoryStream.Create
    else
      FStreamValue.Clear;
    if Length(vValue) > 0 then
      FStreamValue.Write(vValue[1], Length(vValue));
    FQuery.FHaveStreamParams := True;
    FXSQLVAR^.SQLType := sSQLType;
    FXSQLVAR^.SQLSubtype := sSubType;
    FXSQLVAR^.sqlscale := sSQLScale;
    Exit;
  end
  else if IsDBKey then
  begin
    vSQLType := FXSQLVAR^.SQLType;
    vSize := FXSQLVAR^.sqllen
  end
  else
  begin
    vSQLType := SQL_TEXT;
    vSize := Length(vValue);
  end;
  FreeAndNil(FStreamValue); // a previous long value

{$IFDEF D_XE3}with FormatSettings do {$ENDIF}
    if vSize > 0 then
    begin
      if not IsMacro and IsNumericType(sSQLType) then
      begin
        // Avoid  bug in  CAST
        vValue := ReplaceStr(vValue, ',', SQLDecimalSeparator);
        if not CharInSet(DecimalSeparator, [SQLDecimalSeparator, ',']) then
          vValue := ReplaceStr(vValue, DecimalSeparator, SQLDecimalSeparator);
      end;
      SetValue(vSQLType, vSize, tspValue, vValue[1], @FWideTempValue)
    end
    else if IsNumericType(sSQLType) or (IsDateTimeType(sSQLType)) then
    begin
      B := True;
      SetValue(vSQLType, vSize, tspNull, B)
    end
    else
      SetValue(vSQLType, vSize, tspValue, '')
end;

procedure TFIBXSQLVAR.SetAsString(const aValue: string);
begin
{$IFDEF D2009+}
  SetAsWideString(aValue)
{$ELSE}
  SetAsAnsiString(aValue)
{$ENDIF}
end;

procedure TFIBXSQLVAR.SetAsAnsiString(const aValue: Ansistring);
begin
  FWideTempValue := '';
  InternalSetAsString(@aValue, False);
end;

procedure TFIBXSQLVAR.SetAsStrData(Len: integer; const aValue);
begin
  FWideTempValue := '';
  SetValue(SQL_TEXT, Len, tspValue, aValue);
  FParDataIsPrepared := True
end;

procedure TFIBXSQLVAR.SetAsWideString(const aValue: WideString);
begin
  InternalSetAsString(@aValue, True);
end;

function TFIBXSQLVAR.GetAsWideString: WideString;
var
  sz: TDataBuffer;
  str_len: integer;
  // s:Ansistring;
  bs: TFIBBlobStream;
  byteStr: FIBByteString;
begin

  if Length(FWideTempValue) > 0 then
    Result := FWideTempValue
{$IFDEF D2009+}
  else if Assigned(FQuery.Database) and ((FXSQLVAR^.SQLType and (not 1) = SQL_TEXT) or
    (FXSQLVAR^.SQLType and (not 1) = SQL_VARYING)) then
    Result := DecodeString(GetAsAnsiString, TextCodePage)
{$ENDIF}
  else if Assigned(FQuery.Database) and FQuery.Database.NeedUnicodeFieldsTranslation then
    with FXSQLVAR^ do
      case SQLType and (not 1) of
        SQL_TEXT, SQL_VARYING:
          if Byte(SQLSubtype) in FQuery.Database.UnicodeCharsets then
          begin
            if IsNull then
              Result := ''
            else
            begin
              sz := FXSQLVAR^.sqldata;
              if (FXSQLVAR^.SQLType and (not 1) = SQL_TEXT) then
                str_len := FXSQLVAR^.sqllen
              else
              begin
                // str_len := FQuery.Database.ClientLibrary.isc_vax_integer(FXSQLVar^.sqldata, 2);
                str_len := PWord(sz)^; // It is isc_vax_integer(sz, 2);
                Inc(sz, 2);
              end;
              // SetString(s, sz, str_len);

              SetLength(byteStr, str_len);
              if str_len > 0 then
                Move(sz^, byteStr[1], str_len);

{$IFDEF D2009+}
              Result := UTF8ToString(byteStr);
{$ELSE}
              Result := UTF8Decode(byteStr);
{$ENDIF}
              if qoTrimCharFields in FQuery.Options then
                DoTrimRight(Result);
              // Result:=DoTrimRight(Result);
            end
          end
          else
            Result := GetAsAnsiString;

        SQL_BLOB:
          try
            Result := '(BLOB)'; { return on error }
            if IsParam and (FStreamValue = nil) then
              Exit; // BlobHandle may be invalid
            if FStreamValue <> nil then
            begin
              if FStreamValue.Size = 0 then
                Result := ''
              else
              begin

                SetLength(byteStr, FStreamValue.Size);
                FStreamValue.Position := 0;
                FStreamValue.Read(byteStr[1], FStreamValue.Size);
                Result := DecodeWideString(byteStr, BlobCodePage);
              end;
            end
            else
            begin
              bs := TFIBBlobStream.Create;
              try
                bs.Mode := bmRead;
                with FQuery do
                begin
                  bs.InternalSetCharSet(Byte(FXSQLVAR^.sqlscale));
                  bs.Database := Database;
                  bs.Transaction := Transaction;
                  if qoStartTransaction in Options then
                    if (Transaction <> nil) and not Transaction.InTransaction then
                      Transaction.StartTransaction;
                end;
                bs.BlobID := AsQuad;
                bs.blobSubType := FXSQLVAR^.SQLSubtype;
                Result := bs.AsWideString;

              finally
                bs.Free;
              end;
            end
          except
            // BlobHandle is invalid!
          end;

      else
        Result := GetAsAnsiString;
      end
  else
    Result := GetAsAnsiString;
end;

procedure TFIBXSQLVAR.SetAsVariant(Value: Variant);
var
  vt: integer;
  sSQLType: integer;
  v: TVarData;
  ws: WideString;
  BlobValue: TMemoryStream;
begin
  vt := VarType(Value);
  sSQLType := ServerSQLType;
  // if not FParent.FQuery.Prepared then
  if sSQLType = 0 then
  begin
    FParent.FHasDefferedSettings := True;
    FIsDefferedSetting := True;
  end;

  if (sSQLType = SQL_TIMESTAMP) or (sSQLType = SQL_TYPE_DATE) then
    if vt in [varDouble, varCurrency, varInteger, varSingle, varSmallint, varWord, varShortInt, varLongWord, varInt64

      ] then
    begin
      vt := varDate;
      Value := TDateTime(Value);
    end;

  if IsMacro then
  begin
    Value := VarToStr(Value);
    vt := VarType(Value);
  end;
  if VarIsNull(Value) then
    IsNull := True
  else if VarIsFMTBcd(Value) then
    AsBcd := VarToBcd(Value)
  else
    case vt of
      varEmpty, varNull: IsNull := True;
      varSmallint, varInteger, varByte, varWord, varShortInt, varLongWord: AsLong := Value;
      varInt64: AsInt64 := Value;
      varSingle, varDouble: AsDouble := Value;
      varCurrency: AsCurrency := Value;
      varBoolean:
        case sSQLType of
          SQL_BOOLEAN: AsBoolean := Value;
        else
          if Value then
            AsVariant := VariantTrue
          else
            AsVariant := VariantFalse;
        end;
      varDate:
        case sSQLType of
          SQL_TYPE_TIME, SQL_TIME_TZ, SQL_TIME_TZ_EX: AsTime := Value;
          SQL_TYPE_DATE: AsDate := Value;
        else
          AsDateTime := Value;
        end;
      varOleStr{$IFDEF D2009+}, varUString{$ENDIF} :
        AsWideString := Value;
      varString: AsAnsiString := Value;
      varArray:
{$IFDEF SUPPORT_ARRAY_FIELD}
        if IsArrayParamValue(Value, sSQLType) then
          SetArrayValue(Value)
        else
{$ENDIF}
          if IsBlob or (sSQLType = 0) then
          begin
            BlobValue := TMemoryStream.Create;
            try
              VariantToStream(Value, BlobValue);
              LoadFromStream(BlobValue);
            finally
              BlobValue.Free
            end;
          end

            ;
      varVariant: AsVariant := Variant(PVarData(TVarData(Value).VPointer)^);
      varByRef, varDispatch, varError, varUnknown: FIBError(feNotPermitted, [nil]);
    else
      if VarIsArray(Value) then
      begin
{$IFDEF SUPPORT_ARRAY_FIELD}
        if IsArrayParamValue(Value, sSQLType) then
          SetArrayValue(Value)
        else
{$ENDIF}
          if IsBlob or (sSQLType = 0) then
          begin
            BlobValue := TMemoryStream.Create;
            try
              VariantToStream(Value, BlobValue);
              LoadFromStream(BlobValue);
            finally
              BlobValue.Free
            end;
          end

      end
      else if vt and varByRef <> 0 then
      begin
        v := TVarData(Value);
        case vt and not varByRef of
          varSmallint: AsLong := PSmallInt(v.VPointer)^;
          varInteger: AsLong := PInteger(v.VPointer)^;
          varSingle: AsDouble := PSingle(v.VPointer)^;
          varDouble: AsDouble := PDouble(v.VPointer)^;
          varCurrency: AsCurrency := PCurrency(v.VPointer)^;
          varDate:
            case sSQLType of
              SQL_TYPE_TIME, SQL_TIME_TZ, SQL_TIME_TZ_EX: AsTime := PDate(v.VPointer)^;
              SQL_TYPE_DATE: AsDate := PDate(v.VPointer)^;
            else
              AsDateTime := PDate(v.VPointer)^;
            end;
          varOleStr:
            begin
              ws := VarToWideStr(Value);
              AsVariant := ws;
            end;

          varBoolean: AsBoolean := PWordBool(v.VPointer)^;
          varShortInt: AsLong := PShortInt(v.VPointer)^;
          varByte: AsLong := PByte(v.VPointer)^;
          varWord: AsLong := PWord(v.VPointer)^;
          varLongWord: AsLong := PLongWord(v.VPointer)^;
          varInt64: AsInt64 := PInt64(v.VPointer)^;
          varVariant: AsVariant := Variant(PVarData(v.VPointer)^);
        else
          FIBError(feNotPermitted, [nil]);
        end
      end
      else
        FIBError(feNotPermitted, [nil]);

    end;
end;

procedure TFIBXSQLVAR.SetAsXSQLVAR(aValue: PXSQLVAR);
begin
  SetValue(0, 0, tspSqlVar, aValue)
end;

procedure TFIBXSQLVAR.SetIsNull(aValue: boolean);
begin
  if aValue then
  begin
    FWideTempValue := '';
    if FStreamValue <> nil then
    begin
      FStreamValue.Free;
      FStreamValue := nil;
    end;
  end;
  SetValue(0, 0, tspNull, aValue)
end;

procedure TFIBXSQLVAR.SetIsNullable(aValue: boolean);
begin
  SetValue(0, 0, tspIsNullable, aValue)
end;

function TFIBXSQLVAR.GetScale: integer;
begin
  Result := FXSQLVAR^.sqlscale
end;

procedure TFIBXSQLVAR.SetScale(Value: integer);
begin
  SetValue(0, 0, tspScale, Value)
end;

function TFIBXSQLVAR.IsBlob: boolean;
begin
  case SQLType of
    SQL_BLOB, SQL_ARRAY: Result := True;
  else
    Result := False;
  end;
end;

function TFIBXSQLVAR.IsParam: boolean;
begin
  Result := Assigned(FParent) and FParent.FIsParams
end;

function TFIBXSQLVAR.GetRelationAlias: string;
begin
  if Assigned(FParent) and not FParent.FIsParams and Assigned(FQuery) and not FQuery.FRelationAliasesRead then
    FQuery.ReadRelationAliases;
  Result := FRelationAlias;
end;

function TFIBXSQLVAR.CharacterSet: string;
var
  SqlVar: PXSQLVAR;
begin
  Result := '';
  if Assigned(FParent) then
  begin
    SqlVar := FParent.FXSQLVARs[FIndex].Data;
    case SqlVar^.SQLType and (not 1) of
      SQL_TEXT, SQL_VARYING:
        Result := FirebirdCharSetName(Byte(SqlVar^.SQLSubtype));
      // a text BLOB keeps the charset in sqlscale, SQLSubtype is the BLOB subtype
      SQL_BLOB:
        if SqlVar^.SQLSubtype = 1 then
          Result := FirebirdCharSetName(Byte(SqlVar^.sqlscale));
    end;
  end;
  if Result = '' then
    Result := UnknownStr;
end;

function TFIBXSQLVAR.GetAsBcd: TBcd;
begin
  if IsDecimalType and not IsNull then
  begin
    if not FBRawToBcd(FXSQLVAR^.SQLType and (not 1), FXSQLVAR^.sqlscale, FXSQLVAR^.sqldata, Result) then
      FIBError(feInvalidDataConversion, [nil])
  end
  else if (FQuery.Database.SQLDialect < 3) or (FXSQLVAR^.SQLType and (not 1) <> SQL_INT64) then
  begin
    if not CurrToBCD(GetAsCurrency, Result) then
      FIBError(feInvalidDataConversion, [nil])
  end
  else
  begin
    if not Int64ToBCD(PInt64(FXSQLVAR^.sqldata)^, -FXSQLVAR^.sqlscale, Result) then
      FIBError(feInvalidDataConversion, [nil])
  end;
end;

procedure TFIBXSQLVAR.SetAsBcd(Value: TBcd);
var
  E: Extended;
  C: Int64;
  vScale: integer;
  vInt128: TFB_I128;
begin
  if (FQuery.Database.SQLDialect < 3) then
  begin
    if not BCDToExtended(Value, E) then
      FIBError(feInvalidDataConversion, [nil]);
    SetAsExtended(E);
  end
  else
  begin
    if BcdToInt64Scaled(Value, C, vScale) then
      SetValue(SQL_INT64, SizeOf(Int64), tspValue, C)
    else
    begin
      // Does not fit BIGINT, send as INT128 (Firebird 4+)
      if not FBBcdToRaw(Value, SQL_INT128, vScale, @vInt128) then
        FIBError(feInvalidDataConversion, [nil]);
      SetValue(SQL_INT128, SizeOf(TFB_I128), tspValue, vInt128);
    end;
    Scale := vScale;
  end;
end;

function TFIBXSQLVAR.GetAsGUID: TGUID;
begin
  if not IsNull then
    case FXSQLVAR^.SQLType and (not 1) of
      SQL_VARYING: Result := PGUID(FXSQLVAR^.sqldata + 2)^;
      SQL_TEXT: Result := PGUID(FXSQLVAR^.sqldata)^;
    end
  else
    Result := fibGUID_NULL
end;

procedure TFIBXSQLVAR.SetAsGuid(aValue: TGUID);
begin
  SetValue(SQL_TEXT, SizeOf(aValue), tspValue, aValue);
end;

function TFIBXSQLVAR.GetAsBoolean: boolean;
begin
  Result := False;
  if not IsNull then
    case FXSQLVAR^.SQLType and (not 1) of
      SQL_BOOLEAN: Result := PByte(FXSQLVAR^.sqldata)^ = ISC_TRUE;
      // numbers: any value other than zero is True, whatever the scale
      IB_SQL_BOOLEAN, SQL_SHORT: Result := PShort(FXSQLVAR^.sqldata)^ <> 0;
      SQL_LONG: Result := PLong(FXSQLVAR^.sqldata)^ <> 0;
      SQL_INT64: Result := PInt64(FXSQLVAR^.sqldata)^ <> 0;
      SQL_FLOAT: Result := PSingle(FXSQLVAR^.sqldata)^ <> 0;
      SQL_DOUBLE, SQL_D_FLOAT: Result := PDouble(FXSQLVAR^.sqldata)^ <> 0;
    else
      FIBError(feInvalidDataConversion, [nil])
    end;
end;

procedure TFIBXSQLVAR.SetAsBoolean(const Value: boolean);
begin
  case FSrvSQLType of
    0:
      begin
        FIsDefferedSetting := True;
        FParent.FHasDefferedSettings := True;
        SetAsShort(Ord(Value));
      end;
    SQL_BOOLEAN: SetValue(SQL_BOOLEAN, SizeOf(boolean), tspValue, Value);
  else
    SetAsShort(Ord(Value));
  end;
end;

// TFIBXSQLDA
constructor TFIBXSQLDA.Create(aIsParams: boolean);
begin
  FNames := TStringList.Create;
  with FNames do
  begin
    Sorted := True;
    Duplicates := dupAccept;
  end;

  FEquelNames := TStringList.Create;
  with FEquelNames do
  begin
    Sorted := True;
    Duplicates := dupAccept;
  end;

  FCachedNames := TStringList.Create;
  { with FCachedNames do
    begin
    Sorted     := True;
    Duplicates := dupIgnore;
    end; }
  FIsParams := aIsParams;
end;

destructor TFIBXSQLDA.Destroy;
var
  i: integer;
begin
  FNames.Free;
  FEquelNames.Free;
  FCachedNames.Free;
  if FXSQLDA <> nil then
  begin
    for i := 0 to FSize - 1 do
      with FXSQLDA^.SqlVar[i] do
      begin
        FIBAlloc(sqldata, 0, 0);
        FIBAlloc(sqlind, 0, 0);
        FXSQLVARs^[i].Free;
      end;
    FIBAlloc(FXSQLDA, 0, 0);
    FIBAlloc(FXSQLVARs, 0, 0);
    FXSQLDA := nil;
  end;
  inherited;
end;

function TFIBXSQLDA.FindParam(const aParamName: string): TFIBXSQLVAR;
begin
  Result := ByName[aParamName];
end;

function TFIBXSQLDA.ParamByName(const aParamName: string): TFIBXSQLVAR;
begin
  Result := ByName[aParamName];
  if Result = nil then
    raise Exception.Create(Format(SFIBErrorParamNotExist, [aParamName, CmpFullName(FQuery)]));
end;

procedure TFIBXSQLDA.AssignValues(SourceSQLDA: TFIBXSQLDA);
var
  i: integer;
  pc: integer;
  uSType, sSType: integer; // parameterType
  UsrPar, Srvpar: TFIBXSQLVAR;
begin
  // uSType - user Params[i].SQLType
  // sSType - real Params[i].SQLType
  pc := Pred(SourceSQLDA.Count);
  for i := 0 to pc do
  begin
    UsrPar := SourceSQLDA[i];
    Srvpar := ByName[UsrPar.Name];
    if (Srvpar <> nil) and (UsrPar <> nil) then
      with Srvpar do
      begin
        if (not UsrPar.IsMacro) and UsrPar.IsNull then
        begin
          AsVariant := NULL;
          Continue;
        end;
        sSType := FXSQLVAR^.SQLType and (not 1);
        uSType := UsrPar.FXSQLVAR^.SQLType and (not 1);

        if ((uSType = SQL_BLOB) or (uSType = SQL_ARRAY)) and
          ((sSType = SQL_BLOB) or (sSType = SQL_ARRAY)) and not UsrPar.IsDefferedLongString then
        begin
          FreeAndNil(FStreamValue);
          AsQuad := UsrPar.AsQuad
        end
        else
        begin
          if (uSType = SQL_INT64) or (uSType = SQL_INT128) then
          begin
            if (sSType = SQL_BLOB) or (sSType = SQL_ARRAY) then
              AsInt64 := 0;
            Assign(UsrPar);
          end
          else
          begin
            FParDataIsPrepared := UsrPar.FParDataIsPrepared;
            if not UsrPar.FIsDefferedSetting or (Length(UsrPar.FWideTempValue) = 0) then
              AsVariant := UsrPar.AsVariant
            else
            begin
              InternalSetAsString(@UsrPar.FWideTempValue, True, True);
              UsrPar.FXSQLVAR^.SQLType := FXSQLVAR^.SQLType;
              UsrPar.FXSQLVAR^.sqlind^ := 0;
              UsrPar.FXSQLVAR^.SQLSubtype := FXSQLVAR^.SQLSubtype;
              UsrPar.FXSQLVAR^.sqlscale := FXSQLVAR^.sqlscale;
            end;
          end
        end
      end;
  end;
  FQuery.SaveStreamedParams(Self)
end;

procedure TFIBXSQLDA.ClearValues;
var
  j: integer;
  // b:boolean;
begin
  for j := 0 to Pred(Count) do
    with FXSQLVARs^[j] do
    begin
      if IsMacro then
        Value := FXSQLVARs^[j].DefMacroValue
      else
      begin
        // b:=IsNullable;
        IsNull := True;
        // IsNullable:=b;
      end;
    end;
end;

procedure TFIBXSQLDA.AddName(const FieldName: string; Idx: integer; aQuoted: boolean);
var
  FN: string;
  i: integer;
begin
  if not aQuoted then
    FN := FastUpperCase(FieldName)
  else
    FN := FieldName;
  if FIsParams then
    with FEquelNames do
    begin
      // if Find(fn,i) then
      i := NonAnsiIndexOf(FEquelNames, FN);
      if i > -1 then
        AddObject(FN, TObject(Idx))
      else
      begin
        // if FNames.Find(fn,i) then
        i := NonAnsiIndexOf(FNames, FN);
        if i > -1 then
        begin
          AddObject(FN, TObject(Idx));
          AddObject(FN, FNames.Objects[i]);
        end;

      end;

    end;

  FNames.AddObject(FN, TObject(Idx));
  with FXSQLVARs^[Idx] do
  begin
    FName := FN;
    FIndex := Idx;
    FQuoted := aQuoted
  end;
end;

procedure TFIBXSQLDA.AdjustDefferedSettings;
var
  i: integer;
  S: Ansistring;
  sSQLType: integer;
  uSQLType: integer;
  B: boolean;
  // sSQLLen:integer;
begin
  // For values which sets before preparing
  for i := 0 to FCount - 1 do
    if FXSQLVARs^[i].FIsDefferedSetting then
    begin
      sSQLType := FXSQLVARs^[i].ServerSQLType;
      uSQLType := FXSQLVARs^[i].SQLType;
      // sSQLLen:=FXSQLVARs^[i].ServerSize;

      case sSQLType of
        SQL_BOOLEAN:
          // text is converted by the server, as after Prepare
          if (uSQLType <> SQL_TEXT) and (uSQLType <> SQL_VARYING) then
          begin
            B := FXSQLVARs^[i].AsBoolean;
            FXSQLVARs^[i].SetValue(SQL_BOOLEAN, SizeOf(boolean), tspValue, B);
          end;
        SQL_DEC16, SQL_DEC34:
          if (uSQLType = SQL_DOUBLE) and not FXSQLVARs^[i].IsNull then
            FXSQLVARs^[i].SetAsDouble
              (PDouble(FXSQLVARs^[i].FXSQLVAR^.sqldata)^);
        SQL_TIME_TZ, SQL_TIME_TZ_EX:
          if (uSQLType = SQL_TIMESTAMP) and not FXSQLVARs^[i].IsNull then
            FXSQLVARs^[i].SetAsTime(FXSQLVARs^[i].AsDateTime);
      else
        case uSQLType of
          SQL_TEXT, SQL_VARYING:
            begin
              // UNICODE;
              if not FXSQLVARs^[i].IsNull then
              begin
                S := FXSQLVARs^[i].GetAsAnsiString;
                FXSQLVARs^[i].InternalSetAsString(@S, False, True);
              end;
            end;
          SQL_DOUBLE, SQL_INT64, SQL_LONG, SQL_FLOAT, SQL_SHORT:
            if ((sSQLType = SQL_TIMESTAMP) or (sSQLType = SQL_TYPE_DATE) or (sSQLType = SQL_TYPE_TIME)) then
            begin
              FXSQLVARs^[i].SetAsDateTime(FXSQLVARs^[i].Value)
            end;
          SQL_BLOB:
            // text set as a string, not bytes loaded from a stream
            if (FXSQLVARs^[i].ServerSQLSubType = 1) and not FXSQLVARs^[i].IsNull and
              (Length(FXSQLVARs^[i].FWideTempValue) > 0) then
              FXSQLVARs^[i].InternalSetAsString(@FXSQLVARs^[i].FWideTempValue, True, True);
        end;
      end;
    end;
  FHasDefferedSettings := False
end;

function TFIBXSQLDA.GetModified: boolean;
var
  i: integer;
begin
  Result := False;
  for i := 0 to FCount - 1 do
    if FXSQLVARs^[i].Modified then
    begin
      Result := True;
      Exit;
    end;
end;

procedure TFIBXSQLDA.SetUnModifiedToVars;
var
  i: integer;
begin
  for i := 0 to FCount - 1 do
    FXSQLVARs^[i].Modified := False;
end;

function TFIBXSQLDA.GetNames: string;
begin
  Result := FNames.Text;
end;

function TFIBXSQLDA.GetRecordSize: integer;
begin
  Result := SizeOf(TFIBXSQLDA) + XSQLDA_LENGTH(FSize);
end;

function TFIBXSQLDA.GetXSQLDA: PXSQLDA;
begin
  Result := FXSQLDA;
end;

function TFIBXSQLDA.GetXSQLVAR(Idx: integer): TFIBXSQLVAR;
begin
  if (Idx < 0) or (Idx >= FCount) then
    FIBError(feXSQLDAIndexOutOfRange, [nil]);
  Result := FXSQLVARs^[Idx]
end;

function TFIBXSQLDA.GetXSQLVARByName(const Idx: string): TFIBXSQLVAR;
var
  i: integer;

  procedure InternalGetXSQLVARByName;
  var
    S: string;
    Quoted: boolean;
  begin
    Quoted := (Length(Idx) > 0) and (Idx[1] = '"');
    if Quoted then
      S := FastCopy(Idx, 2, Length(Idx) - 2)
    else
      S := Idx;
    i := NonAnsiIndexOf(FNames, S);
    if i > -1 then
      Result := GetXSQLVAR(integer(FNames.Objects[i]))
    else if not Quoted then
    begin
      S := FastUpperCase(Idx);
      i := NonAnsiIndexOf(FNames, S);
      if i > -1 then
        Result := GetXSQLVAR(integer(FNames.Objects[i]))
      else
        Result := nil;
    end;
  end;

begin
  i := NonAnsiIndexOf(FCachedNames, Idx);
  // if FCachedNames.Find(Idx,i) then
  if i > -1 then
  begin
    Result := TFIBXSQLVAR(FCachedNames.Objects[i]);
    Exit;
  end;
  InternalGetXSQLVARByName;
  // For params from macros
  if (Result = nil) and (FQuery <> nil) and (Self = FQuery.FUserSQLParams) then
  begin
    if FQuery.MacroChanged then
      FQuery.ApplyMacro;
    Result := FQuery.FSQLParams.GetXSQLVARByName(Idx)
  end
  else if Assigned(Result) then
  begin
    FCachedNames.AddObject(Idx, Result);
  end
end;

procedure TFIBXSQLDA.Initialize;
var
  i, j, C: integer;
  NamesWereEmpty: boolean;
  NamesCut: boolean;
  st, st1: string;
begin
  if FXSQLDA = nil then
    Exit;
  NamesWereEmpty := (FNames.Count = 0);
  NamesCut := False;
  for i := 0 to FCount - 1 do
  begin
    with FXSQLVARs^[i].Data^ do
    begin
      FXSQLVARs^[i].FSrvSQLType := SQLType and (not 1);
      FXSQLVARs^[i].FSrvSQLLen := sqllen;
      FXSQLVARs^[i].FSrvSQLScale := sqlscale;
      FXSQLVARs^[i].FSrvSQLSubType := SQLSubtype;
      FXSQLVARs^[i].FInitialized := True;
      if not FIsParams then
      begin
        FXSQLVARs^[i].FSqlName := FQuery.DecodeName(XSQLVARName(SqlName, sqlname_length));
        FXSQLVARs^[i].FRelationName := FQuery.DecodeName(XSQLVARName(RelName, relname_length));
        FXSQLVARs^[i].FOwnerName := FQuery.DecodeName(XSQLVARName(ownname, ownname_length));
        FXSQLVARs^[i].FAliasName := FQuery.DecodeName(XSQLVARName(AliasName, aliasname_length));
        NamesCut := NamesCut or XSQLVARNameCut(sqlname_length) or
          XSQLVARNameCut(relname_length) or XSQLVARNameCut(ownname_length) or XSQLVARNameCut(aliasname_length);
      end
      else
      begin
        FXSQLVARs^[i].FSqlName := '';
        FXSQLVARs^[i].FRelationName := '';
        FXSQLVARs^[i].FOwnerName := '';
        FXSQLVARs^[i].FAliasName := '';
      end;
      FXSQLVARs^[i].FRelationAlias := '';
      case SQLType and (not 1) of
        0:
          if Self <> FQuery.FUserSQLParams then
          begin
            FIBError(feUnknownSQLDataType, [SQLType and (not 1)])
          end;
        SQL_TEXT:
          if (sqllen = 0) then
            FIBAlloc(sqldata, 0, 1)
          else
            FIBAlloc(sqldata, 0, sqllen);
        SQL_TYPE_DATE, SQL_TYPE_TIME, SQL_TIMESTAMP, SQL_BLOB, SQL_ARRAY,
          SQL_QUAD, SQL_SHORT, SQL_LONG, SQL_INT64, SQL_DOUBLE, SQL_FLOAT,
          SQL_D_FLOAT, IB_SQL_BOOLEAN, SQL_BOOLEAN, SQL_INT128, SQL_DEC16,
          SQL_DEC34, SQL_TIME_TZ_EX, SQL_TIMESTAMP_TZ_EX:
          begin
            FIBAlloc(sqldata, 0, sqllen);
          end;
        SQL_TIME_TZ, SQL_TIMESTAMP_TZ:
          begin
            if not FIsParams then
            begin
              // Fetch the extended form, the server fills the time zone offset
              if SQLType and (not 1) = SQL_TIME_TZ then
              begin
                SQLType := SQL_TIME_TZ_EX or (SQLType and 1);
                sqllen := SizeOf(TISC_TIME_TZ_EX);
              end
              else
              begin
                SQLType := SQL_TIMESTAMP_TZ_EX or (SQLType and 1);
                sqllen := SizeOf(TISC_TIMESTAMP_TZ_EX);
              end;
            end;
            FIBAlloc(sqldata, 0, sqllen);
          end;
        SQL_VARYING:
          begin
            FIBAlloc(sqldata, 0, sqllen + 2);
          end;
        SQL_NULL: ;
      else
        FIBError(feUnknownSQLDataType, [SQLType and (not 1)])
      end;
      if (SQLType and 1 = 1) then
        FIBAlloc(sqlind, 0, SizeOf(Short))
      else if (sqlind <> nil) then
        FIBAlloc(sqlind, 0, 0);
    end;
  end;
  if (Self = FQuery.FSQLRecord) and (FCount > 0) and FQuery.FullNamesNeeded(NamesCut) then
    FQuery.ReadDescribeInfo(Self, True);
  if NamesWereEmpty then
  begin
    j := 0;
    for i := 0 to FCount - 1 do
    begin
      if FIsParams then
        with FXSQLVARs^[i].Data^ do
          st := FQuery.DecodeName(XSQLVARName(AliasName, aliasname_length))
      else
        st := FXSQLVARs^[i].FAliasName;
      if st = '' then
      begin
        Inc(j);
        st := 'F_' + IntToStr(j);
      end
      else if NonAnsiIndexOf(FNames, st) > -1 then
      begin
        // repeated field names
        C := 0;
        repeat
          Inc(C);
          st1 := st + IntToStr(C);
        until GetXSQLVARByName(st1) = nil;
        st := st1;
      end;
      if not FIsParams then
        FXSQLVARs^[i].FAliasName := st;
      AddName(st, i, True);
    end;
  end;
end;

procedure TFIBXSQLDA.SetCount(Value: integer);
var
  i, OldSize: integer;
begin
  FNames.Clear;
  FEquelNames.Clear;
  FCachedNames.Clear;
  FCount := Value;
  if FSize > 0 then
    OldSize := XSQLDA_LENGTH(FSize)
  else
    OldSize := 0;

  if FCount > FSize then
  begin
    FIBAlloc(FXSQLDA, OldSize, XSQLDA_LENGTH(FCount));
    FIBAlloc(FXSQLVARs, FSize * SizeOf(TFIBXSQLVAR), FCount * SizeOf(TFIBXSQLVAR));
    FXSQLDA^.Version := SQLDA_VERSION_CURRENT;
    for i := 0 to FCount - 1 do
    begin
      if i >= FSize then
      begin
        FXSQLVARs^[i] := TFIBXSQLVAR.Create(Self);
        FXSQLVARs^[i].FQuery := FQuery;
      end;
      FXSQLVARs^[i].FXSQLVAR := @FXSQLDA^.SqlVar[i];
    end;
    FSize := FCount;
  end;
  if (FSize > 0) then
  begin
    FXSQLDA^.sqln := Value;
    FXSQLDA^.sqld := Value;
  end;
end;

// TFIBQuery
constructor TFIBQuery.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAutoCloseOnTransactionEnd := True;

{$IFDEF CSMonitor}
  FCSMonitorSupport := TCSMonitorSupport.Create(Self);
{$ENDIF}
  FBase := TFIBBase.Create(Self);
  with FBase do
  begin
    OnDatabaseDisconnecting := DatabaseDisconnecting;
    OnDatabaseConnectionLost := DatabaseConnectionLost;
    OnTransactionEnding := DoTransactionEnding;
  end;
  FSQL := TStringList.Create;
  TStringList(FSQL).OnChanging := SQLChanging;
  FSQLParams := TFIBXSQLDA.Create(True);
  FSQLParams.FQuery := Self;
  FSQLRecord := TFIBXSQLDA.Create(False);
  FSQLRecord.FQuery := Self;
  FUserSQLParams := TFIBXSQLDA.Create(True);
  FUserSQLParams.FQuery := Self;
  FMacroChar := '@';
  FConditions := TConditions.Create(Self);
  FParser := TSQLParser.Create;
  TStringList(FSQL).OnChange := SQLChange;

  if (csDesigning in ComponentState) and not CmpInLoadedState(Self) then
  begin
    // Default values from tools
    ParamCheck := DefParamCheck;
    GoToFirstRecordOnExecute := DefGoToFirstRecordOnExecute;
    FOptions := DefQueryOptions;
    Database := DefDataBase;
  end
  else
  begin
    FParamCheck := True;
    FGoToFirstRecordOnExecute := True;
  end;

  FModifyTable := '-1';

  if AOwner is TFIBDatabase then
    Database := TFIBDatabase(AOwner)
  else if AOwner is TFIBTransaction then
    Transaction := TFIBTransaction(AOwner);
  FOnlySrvParams := TStringList.Create;
  with FOnlySrvParams do
  begin
    Sorted := True;
    Duplicates := dupIgnore;
  end;
end;

destructor TFIBQuery.Destroy;
begin
  // Close may commit; free the query even if that raises
  try
    if (FOpen) then
      Close;
    if (FHandle <> nil) then
      FreeHandle;
  finally
{$IFDEF CSMonitor}
    FCSMonitorSupport.Free;
{$ENDIF}
    FBase.Free;
    FSQLParams.Free;
    FSQLRecord.Free;
    FUserSQLParams.Free;
    FOnlySrvParams.Free;
    FConditions.Free;
    FParser.Free;
    inherited;
    FSQL.Free;
  end;
end;

procedure TFIBQuery.Loaded;
begin
  inherited;
end;

{$DEFINE FIB_IMPLEMENT}
{$I FIBQueryPT.inc}
{$UNDEF FIB_IMPLEMENT}

function TFIBQuery.BatchInput(InputObject: TFIBBatchInputStream): boolean;
var
  RecNum: integer;
  BatchAction: TBatchAction;
  ErrorAction: TBatchErrorAction;

begin
  if not Prepared then
    Prepare;
  Result := FSQLType in [SQLInsert, SQLUpdate, SQLDelete, SQLExecProcedure];
  if not Result then
    Exit;
  InputObject.FParams := Self.FUserSQLParams;
  // Self.FUserSQLParams.Initialize;
  InputObject.ReadyStream;
  Result := InputObject.State = bsFileReady;
  if Result and (InputObject.FVersion > 2) and (InputObject.FCharset <> Database.ConnectParams.Charset) then
    raise Exception.Create(Format(SErrorInProc, [CmpFullName(Self),
      'BatchInput']) + Format(SEInvalidCharsetData, [InputObject.FCharset, Database.ConnectParams.Charset]));

  RecNum := 1;
  BatchAction := baContinue;
  while InputObject.ReadParameters do
  begin
    if Assigned(FOnBatching) then
    begin
      FOnBatching(boInput, RecNum, BatchAction);
      Inc(RecNum);
    end;

    case BatchAction of
      baContinue:
        begin
          ErrorAction := beRetry;
          while ErrorAction = beRetry do
            try
              ExecQuery;
              ErrorAction := beIgnore;
            except
              on E: EFIBError do
                if Assigned(FOnBatchError) then
                begin
                  ErrorAction := beFail;
                  FOnBatchError(E, ErrorAction);
                  case ErrorAction of //
                    beFail: raise;
                    beAbort: Abort;
                  end; // case
                end
                else
                  raise
            end;
        end;
      baStop: Exit;
    else
      BatchAction := baContinue;
    end;
  end;
  InputObject.FParams := nil
end;

function TFIBQuery.BatchOutput(OutputObject: TFIBBatchOutputStream): Boolean;
var
  RecNum: integer;
  BatchAction: TBatchAction;
begin
  CheckClosed('batch output');
  if not Prepared then
    Prepare;
  Result := FSQLType = SQLSelect;
  if not Result then
    Exit;
  try
    ExecQuery;
    OutputObject.FColumns := Self.FSQLRecord;
    OutputObject.ReadyStream;
    Result := OutputObject.State = bsFileReady;
    RecNum := 1;
    BatchAction := baContinue;
    if not FGoToFirstRecordOnExecute then
      Next;
    while (not Eof) do
    begin
      if Assigned(FOnBatching) then
      begin
        FOnBatching(boOutput, RecNum, BatchAction);
        Inc(RecNum);
      end;
      case BatchAction of
        baContinue:
          if not(OutputObject.WriteColumns) then
            Break;
        baStop: Break;
      else
        BatchAction := baContinue;
      end;
      Next;
    end;
    Close;
  except
    Close;
    Result := False
  end;
end;

procedure TFIBQuery.BatchInputRawFile(const FileName: Ansistring);
var
  RawInput: TFIBInputRawFile;
begin
  RawInput := TFIBInputRawFile.Create;
  try
    RawInput.FileName := FileName;
    BatchInput(RawInput);
  finally
    RawInput.Free;
  end;
end;

procedure TFIBQuery.BatchOutputRawFile(const FileName: Ansistring; Version: integer = 3);
var
  RawOutput: TFIBOutputRawFile;
begin
  RawOutput := TFIBOutputRawFile.CreateEx(Version, Database.ConnectParams.Charset);
  try
    RawOutput.FileName := FileName;
    BatchOutput(RawOutput);
  finally
    RawOutput.Free;
  end;
end;

procedure TFIBQuery.BatchToQuery(ToQuery: TFIBQuery; Mappings: TStrings);
var
  Map: TList;
  i, RecNum: integer;
  BatchAction: TBatchAction;
  ErrorAction: TBatchErrorAction;

  function GetParam(const FieldName: string): TFIBXSQLVAR;
  var
    j, p: integer;
    S: string;
  begin
    S := '';
    if Mappings = nil then
      S := FieldName
    else
      for j := 0 to Pred(Mappings.Count) do
      begin
        p := PosCI('=' + FieldName, Mappings[j]);
        if (p > 0) and (p + Length(FieldName) = Length(Mappings[j])) then
        begin
          S := FastCopy(Mappings[j], 1, p - 1);
          Break;
        end;
      end;
    if S = '' then
      S := FieldName;
    Result := ToQuery.FindParam(S)
  end;

begin
  if ToQuery = nil then
    Exit;
  Close;
  if not Prepared then
    Prepare;
  if not ToQuery.Prepared then
    ToQuery.Prepare;
  Map := TList.Create;
  try
    Map.Count := FieldCount;
    for i := 0 to Pred(FieldCount) do
      Map[i] := GetParam(Fields[i].Name);
    ExecQuery;
    RecNum := 1;
    while not Eof do
    begin
      BatchAction := baContinue;
      if Assigned(FOnBatching) then
      begin
        FOnBatching(boOutputToQuery, RecNum, BatchAction);
        Inc(RecNum);
      end;
      case BatchAction of
        baContinue:
          begin
            for i := 0 to Pred(FieldCount) do
              if Map[i] <> nil then
                TFIBXSQLVAR(Map[i]).Assign(Fields[i]);
            ErrorAction := beRetry;
            while ErrorAction = beRetry do
              try
                ToQuery.ExecQuery;
                ErrorAction := beIgnore;
              except
                on E: EFIBError do
                  if Assigned(FOnBatchError) then
                  begin
                    ErrorAction := beFail;
                    FOnBatchError(E, ErrorAction);
                    case ErrorAction of //
                      beFail: raise;
                      beAbort: Abort;
                    end; // case
                  end
                  else
                    raise
              end;
          end;
        baStop: Exit;
      else
        BatchAction := baContinue;
      end;
      Next;
    end;
  finally
    Map.Free;
  end;
end;

procedure TFIBQuery.CheckClosed(const OpName: Ansistring);
begin
  if FOpen then
    FIBError(feDatasetOpen, [OpName, CmpFullName(Self)]);
end;

procedure TFIBQuery.CheckOpen(const OpName: Ansistring);
begin
  if not FOpen then
    FIBError(feDatasetClosed, [OpName, CmpFullName(Self)]);
end;

procedure TFIBQuery.CheckValidStatement;
var
  ForceConnect: boolean;
  ForceTransaction: boolean;
begin
  if not Assigned(Database) then
    FIBError(feDatabaseNotAssigned, [CmpFullName(Self)]);
  if not Assigned(Transaction) then
    FIBError(feTransactionNotAssigned, [CmpFullName(Self)]);

  ForceConnect := not Database.Connected;
  if ForceConnect then
    Database.Connected := True;
  ForceTransaction := not Transaction.InTransaction;
  if ForceTransaction then
    Transaction.StartTransaction;
  try
    try
      Prepare;
    except
      FIBError(feInvalidStatementHandle, [CmpFullName(Self)]);
    end;
  finally
    if ForceTransaction then
      Transaction.Commit;
    if ForceConnect then
      Database.Connected := False;
  end;
end;

procedure TFIBQuery.Close;
begin
  CloseCursor(True);
end;

procedure TFIBQuery.CloseCursor(Complete: boolean);
var
  isc_res: ISC_STATUS;
  WasOpen: boolean;
begin
  WasOpen := FOpen;
  try
    Include(FQueryRunState, qrsInClose);
    if (FHandle <> nil) and FOpen then
      case SQLType of
        SQLSelect, SQLSelectForUpdate:
          begin
            if Assigned(Transaction) then
              Transaction.DoOnSQLExec(Self, koOther);
            isc_res := Call(Database.ClientLibrary.isc_dsql_free_statement(StatusVector, @FHandle, DSQL_close), False);
            if (StatusVector^ = 1) and (isc_res > 0) and not CheckStatusVector([isc_bad_stmt_handle,
              isc_dsql_cursor_close_err]) then
              IBError(Database.ClientLibrary, Self);
          end;
      end;
  finally
    Exclude(FQueryRunState, qrsInClose);
    FEof := False;
    FBOF := False;
    FOpen := False;
    FProcExecuted := False;
  end;
  if Complete and WasOpen then
    CompleteStatement;
end;

// qoAutoCommit, qoFreeHandleAfterExecute: after ExecQuery without cursor, on Close of a cursor
procedure TFIBQuery.CompleteStatement;
begin
  // Not from DoTransactionEnding
  if (qoAutoCommit in Options) and Assigned(Transaction) and
    Transaction.InTransaction and (Transaction.State = tsActive) then
    if Transaction.TimeoutAction = TACommitRetaining then
      Transaction.CommitRetaining
    else
      Transaction.Commit;
  if qoFreeHandleAfterExecute in Options then
    FreeHandle;
end;

function TFIBQuery.CloseOnEof: boolean;
begin
  Result := Options * [qoAutoCommit, qoFreeHandleAfterExecute] <> [];
end;

function TFIBQuery.Call(ErrCode: ISC_STATUS; RaiseError: boolean): ISC_STATUS;
begin
  Set8087CW(Default8087CW);
  Result := 0;
  if Transaction <> nil then
    Result := Transaction.Call(ErrCode, False);
  if (ErrCode > 0) and RaiseError then
    IBError(Database.ClientLibrary, Self);
end;

function TFIBQuery.Current: TFIBXSQLDA;
begin
  Result := FSQLRecord;
end;

procedure TFIBQuery.DatabaseDisconnecting(Sender: TObject);
begin
  if (FHandle <> nil) then
  begin
    CloseCursor(False);
    FreeHandle;
  end;
end;

procedure TFIBQuery.DatabaseConnectionLost(Sender: TObject);
begin
  // Close must not call the server
  FHandle := nil;
  CloseCursor(False);
  FPrepared := False;
end;

procedure TFIBQuery.BeginModifySQLText;
begin
  Inc(FCountLockSQL)
end;

procedure TFIBQuery.EndModifySQLText;
begin
  if FCountLockSQL > 0 then
    Dec(FCountLockSQL)
  else
    FCountLockSQL := 0;
  if FCountLockSQL = 0 then
    SQLChange(nil);
end;

function TFIBQuery.CountModifySQLText: integer;
begin
  Result := FCountLockSQL;
end;

function TFIBQuery.GetMainWhereIndex: integer;
begin
  Result := MainWhereIndex(SQL.Text);
end;

function TFIBQuery.GetMainWhereClause: string;
var
  ind: integer;
begin
  ind := GetMainWhereIndex;
  if ind = -1 then
    Result := ''
  else
    Result := WhereClause[ind]
end;

procedure TFIBQuery.SetMainWhereClause(const Value: string);
begin
  SQL.Text := FParser.SetMainWhereClause(Value);
end;

function TFIBQuery.ParamsNotExist(const SQLText: string): boolean;
var
  i: integer;
  State: TParserState;
  QuoteChar: Char;
begin
  State := sNormal;
  QuoteChar := '''';
  for i := 2 to Length(SQLText) do
  begin
    case State of
      sNormal:
        case SQLText[i] of
          '?', ':':
            begin
              Result := False;
              Exit;
            end;
          '*':
            if (SQLText[i - 1] = '/') then
              State := sComment;
          '''', '"':
            begin
              QuoteChar := SQLText[i];
              State := sQuote
            end;
          '-':
            if (SQLText[i - 1] = '-') then
              State := sFBComment;
        else
          if SQLText[i] = FMacroChar then
          begin
            Result := False;
            Exit;
          end;

        end;
      sQuote:
        if SQLText[i] = QuoteChar then
          State := sNormal;
      sComment:
        if (SQLText[i] = '/') and (SQLText[i - 1] = '*') then
          State := sNormal;
      sFBComment:
        if (SQLText[i] = #13) then
          State := sNormal;
    end;
  end;
  Result := True;
end;

procedure TFIBQuery.SaveRestoreValues(SQLDA: TFIBXSQLDA; IsSave: boolean);
var
  j, pc: integer;
begin
  pc := Pred(SQLDA.Count);
  if IsSave then
    for j := 0 to pc do
    begin
      if SQLDA.FXSQLVARs^[j].FInitialized then
        SQLDA.FXSQLVARs^[j].FOldValue := SQLDA.FXSQLVARs^[j].Value
    end
  else
    for j := 0 to pc do
      case SQLDA[j].SQLType of
        SQL_BLOB, SQL_ARRAY: ;
      else
        if not VarIsEmpty(SQLDA[j].FOldValue) then
          SQLDA.FXSQLVARs^[j].Value := SQLDA.FXSQLVARs^[j].FOldValue
        else
        begin
          if SQLDA.FXSQLVARs^[j].SQLType = SQL_VARYING then
            SQLDA.FXSQLVARs^[j].FXSQLVAR^.SQLType := SQL_TEXT;
          SQLDA.FXSQLVARs^[j].Value := NULL;
        end
      end
end;

{$IFNDEF NO_MONITOR}

type
  THackMonitorHook = class(TFIBSQLMonitorHook);
{$ENDIF}

function TFIBQuery.ReadySQLText(ForChangeExecSQL: boolean = True): string;
type
  TCompareNull = (cNone, cIsNull, cIsNotNull);
var
  i, j: integer;
  pv: string;
  vLenMacro: integer;
  vDelta: integer;
  pv1: string;
  C: TCompareNull;
  CurParam: TFIBXSQLVAR;
const
  StrIsNull    = ' IS NULL ';
  StrIsNotNull = ' IS NOT NULL ';

begin
  if ForChangeExecSQL then
    vDiffParams := False;
  Result := FParser.SQLText;
  if not FHaveMacros and (qoNoForceIsNull in Options) then
    Exit;

  vDelta := 0;
  for i := 0 to Pred(Params.Count) do
  begin
    CurParam := Params.FXSQLVARs^[i];
    if CurParam.IsMacro then
    begin
      vLenMacro := CurParam.FEndPosInText - CurParam.FBeginPosInText + 1;
      pv := CurParam.AsWideString;
      if CurParam.Quoted then
      begin
        if pv = '' then
          pv1 := '''' + pv + ''''
        else if pv[1] = '''' then
          pv1 := pv
        else
          pv1 := '''' + pv + ''''

          (* if pv='' then
            pv1:=''''+''''
            else
            if pv[1]='''' then
            pv1:=pv
            else
            begin
            pv1:=pv+'''';
            if pv1[1]='#' then // ??????
            pv1[1]:=''''
            else
            pv1:=''''+pv1

            end; *)
      end
      else
        pv1 := pv;
      Result := Copy(Result, 1, CurParam.FBeginPosInText - vDelta - 1) + pv1 +
        Copy(Result, CurParam.FEndPosInText - vDelta + 1, MaxInt);
      Inc(vDelta, vLenMacro - Length(pv1));
      CurParam.FOldValue := pv;
      if ForChangeExecSQL then
        vDiffParams := True;
    end
    else if not(qoNoForceIsNull in Options) and
      ((qrsInExecute in FQueryRunState) or not(qrsInPrepare in FQueryRunState))
    // ^^^  Lock replacing for prepare. Replace must be call for execute query only
    then
      if CurParam.IsNull and CurParam.InWhereClause and CurParam.FCanForceIsNull then
      begin
        j := CurParam.FBeginPosInText - 1;
        while CharInSet(FParser.SQLText[j], CharsAfterClause) do
          Dec(j);
        C := cNone;
        case FParser.SQLText[j] of
          '>':
            if FParser.SQLText[j - 1] = '<' then
            begin
              C := cIsNotNull;
              Dec(j);
            end;

          '=':
            if CharInSet(FParser.SQLText[j - 1], ['!', '^', '~']) then
            begin
              C := cIsNotNull;
              Dec(j);
            end
            else if not CharInSet(FParser.SQLText[j - 1], ['<', '>']) then
              C := cIsNull
        end;

        if C <> cNone then
        begin
          vLenMacro := CurParam.FEndPosInText - j + 1;

          case C of
            cIsNull: pv1 := StrIsNull;
            cIsNotNull: pv1 := StrIsNotNull
          end;
          Result := Copy(Result, 1, j - vDelta - 1) + pv1 + Copy(Result, CurParam.FEndPosInText - vDelta + 1, MaxInt);
          Inc(vDelta, vLenMacro - Length(pv1));
          if ForChangeExecSQL then
          begin
            CurParam.FOldValue := NULL;
            vDiffParams := True
          end;
        end;
      end;
  end;
end;

procedure TFIBQuery.StartStatisticExec(const stText: string);
begin
  if Assigned(Database.SQLStatisticsMaker) and Database.SQLStatisticsMaker.ActiveStatistics then
    with Database.SQLStatisticsMaker do
    begin
      SetStringValue(stText, scLastQuery, CmpFullName(Self));
      FixStartTime(stText, scLastTimeExecute);
      IncCounter(stText, scExecuteCount);
    end;
end;

procedure TFIBQuery.DoStatisticPrepare(const stText: string);
begin
  if Assigned(Database.SQLStatisticsMaker) and Database.SQLStatisticsMaker.ActiveStatistics then
    with Database.SQLStatisticsMaker do
    begin
      SetStringValue(stText, scLastQuery, CmpFullName(Self));
      IncCounter(stText, scPrepareCount);
    end;
end;

procedure TFIBQuery.EndStatisticExec(const stText: string);
var
  lt, S, j: integer;
  ts: TStrings;
begin
  if Assigned(Database.SQLStatisticsMaker) and Database.SQLStatisticsMaker.ActiveStatistics then
    with Database.SQLStatisticsMaker do
    begin
      lt := FixEndTime(stText, scLastTimeExecute);
      S := AddIntValue(stText, scSumTimeExecute, lt);
      SetIntValue(stText, scAvgTimeExecute, Round(S / GetVarInt(stText, scExecuteCount)));
      if GetVarInt(stText, scMaxTimeExecute) < lt then
      begin
        SetIntValue(stText, scMaxTimeExecute, lt);
        ts := GetVarStrings(stText, scMaxTimeExecute);
        ts.Clear;
        for j := 0 to Params.Count - 1 do
          with Params[j] do
          begin
            if (FXSQLVAR^.SQLType and (not 1) <> SQL_ARRAY) and (FXSQLVAR^.SQLType and (not 1) <> SQL_BLOB) then
              ts.Add('Params[' + IntToStr(j) + ']=''' + AsWideString + '''')
            else
              ts.Add('Params[' + IntToStr(j) + ']=(' + IntToStr(Params[j].AsQuad.gds_quad_high) + ',' +
                IntToStr(Params[j].AsQuad.gds_quad_low) + ')')
          end;
      end;
    end;
end;

procedure TFIBQuery.DoBeforeExecute;
begin
  if Assigned(FBeforeExecute) then
    FBeforeExecute(Self);
  if not Assigned(Transaction) then
    FIBError(feTransactionNotAssigned, [CmpFullName(Self)]);
  FSQLRecord.ClearValues;

  if qoStartTransaction in Options then
    if (Transaction <> nil) and not Transaction.InTransaction then
      Transaction.StartTransaction;
  Transaction.DoOnSQLExec(Self, koBefore);
end;

procedure TFIBQuery.DoAfterFirstFetch;
begin
  if Assigned(FAfterFirstFetch) then
    FAfterFirstFetch(Self);
  Transaction.DoOnSQLExec(Self, koAfterFirstFetch);
end;

procedure TFIBQuery.DoAfterExecute;
begin
  if Assigned(FAfterExecute) then
    FAfterExecute(Self);
  Transaction.DoOnSQLExec(Self, koAfter);
  FUserSQLParams.SetUnModifiedToVars;
  FMacroChanged := False;
  FNeedForceIsNull := False;
  ClearStreamedParams;

{$IFNDEF NO_MONITOR}
  if MonitoringEnabled then
    if MonitorHook <> nil then
      MonitorHook.SQLExecute(Self, '');
{$ENDIF}
end;

procedure TFIBQuery.ConvertSQLTextToCodePage;
begin
  if not FCodePageApplied then
    if DisableEncodingSQLText then
      FPreparedSQL := Ansistring(FProcessedSQL)
    else if SQLKind = skDDL then
      FPreparedSQL := EncodeString(FProcessedSQL, Database.Capabilities.MetadataCodePage)
    else
      FPreparedSQL := EncodeString(FProcessedSQL, Database.Capabilities.CodePage);
  FCodePageApplied := True;
end;

procedure TFIBQuery.ExecuteImmediate;
var
  xSQLDA: PXSQLDA;
  pc: integer;
begin
  BuildDeferredSQL;
  DoBeforeExecute;
{$IFDEF CSMonitor}
  if Pos('/* CSMON$', FParser.SQLText) <= 0 then
    FParser.SQLText := FParser.SQLText + GetCSMonText;
{$ENDIF}
  if (Length(FProcessedSQL) = 0) or FMacroChanged then
  begin
    PreprocessSQL(ReadySQLText, False);
    ConvertSQLTextToCodePage;
  end
  else if not FCodePageApplied then
    ConvertSQLTextToCodePage;
  SaveStreamedParams(Params);
  pc := Params.Count;
  if (vDiffParams and FDoParamCheck and (pc > 0)) then
  begin
    FSQLParams.AssignValues(FUserSQLParams);
    xSQLDA := FSQLParams.FXSQLDA;
  end
  else
  begin
    xSQLDA := FUserSQLParams.FXSQLDA;
    if FUserSQLParams.FHasDefferedSettings then
      FUserSQLParams.AdjustDefferedSettings;
  end;

  FreeHandle;
  Call(Database.ClientLibrary.isc_dsql_execute_immediate(StatusVector,
    @Database.Handle, @Transaction.Handle, 0, PAnsiChar(Ansistring(FPreparedSQL)), Database.SQLDialect, xSQLDA), True);
  DoAfterExecute;
  CompleteStatement;
end;

{$IFDEF SUPPORT_IB2007}

procedure TFIBQuery.ExecuteAsBatch(const SQLs: array of Ansistring);
var
  vBatchBuffer, vb: PPAnsiChar;
  vBatchCount: integer;
  i: integer;
  pCurCommand: PAnsiChar;
  Results: PULong;
begin
  if Database.IsIB2007Connect and (Length(SQLs) > 0) then
  begin
    vBatchCount := Length(SQLs);
    vBatchBuffer := nil;
    for i := 0 to Pred(vBatchCount) do
    begin
      FIBAlloc(vBatchBuffer, vBatchCount * SizeOf(PAnsiChar), (vBatchCount + 1) * SizeOf(PAnsiChar));
      GetMem(pCurCommand, Length(SQLs[i]) + 1);
      Move(SQLs[i][1], pCurCommand^, Length(SQLs[i]));
      pCurCommand[Length(SQLs[i])] := #0;
      vb := vBatchBuffer;
      Inc(vb, i);
      vb^ := pCurCommand;
    end;
    Results := nil;
    try
      if vBatchCount > 0 then
      begin
        if qoStartTransaction in Options then
          if (Transaction <> nil) and not Transaction.InTransaction then
            Transaction.StartTransaction;

        GetMem(Results, vBatchCount * SizeOf(ULong));
        Call(Database.ClientLibrary.isc_dsql_batch_execute_immed(StatusVector,
          @Database.Handle, @Transaction.Handle, Database.SQLDialect, vBatchCount, vBatchBuffer, Results), True);
      end
    finally
      vb := vBatchBuffer;
      for i := 0 to vBatchCount - 1 do
      begin
        FreeMem(vb^);
        Inc(vb);
      end;
      FreeMem(vBatchBuffer);
      FreeMem(Results);
    end;
  end;
end;

procedure TFIBQuery.ExecuteAsBatch;
var
  vBatchBuffer, vb: PPAnsiChar;
  vBatchCount: integer;
  // curCommand   : Ansistring;
  curPos, LastPos: integer;
  SQLText: Ansistring;
  pCurCommand: PAnsiChar;
  Results: PULong;
  i: integer;
  ExistSQL: boolean;
  function GetCurCommand: boolean;
  var
    State: integer; // 0 - norma,1- comment ,2 single quote,3 double quote
  begin
    Result := False;
    State := 0;
    LastPos := curPos;
    ExistSQL := False;
    while LastPos <= Length(SQLText) do
    begin
      case State of
        0:
          case SQLText[LastPos] of
            '''':
              begin
                State := 2;
                Inc(LastPos);
              end;
            '"':
              begin
                State := 3;
                Inc(LastPos);
              end;

            '/':
              begin
                if (LastPos < Length(SQLText)) and (SQLText[LastPos + 1] = '*') then
                begin
                  State := 1;
                  Inc(LastPos);
                end;
              end;
            ';':
              begin
                Inc(LastPos);
                Result := True;
                Exit;
              end;
          else
            if SQLText[LastPos] >= 'A' then
              ExistSQL := True;
          end;
        1: // State=1
          case SQLText[LastPos] of
            '*':
              begin
                if (LastPos < Length(SQLText)) and (SQLText[LastPos + 1] = '/') then
                begin
                  State := 0;
                  Inc(LastPos);
                end
              end;
          end;
        2:
          case SQLText[LastPos] of
            '''': State := 0;
          end;
        3:
          case SQLText[LastPos] of
            '"': State := 0;
          end;

      end;
      Inc(LastPos);
    end;
  end;

begin
  if Database.IsIB2007Connect then
  begin
    if not(qoStartTransaction in Options) then
      Transaction.CheckInTransaction
    else
      Database.CheckActive;

    vBatchCount := 0;
    vBatchBuffer := nil;
    curPos := 1;
    SQLText := SQL.Text;

    while GetCurCommand do
    begin
      if ExistSQL then
      begin
        FIBAlloc(vBatchBuffer, vBatchCount * SizeOf(PAnsiChar), (vBatchCount + 1) * SizeOf(PAnsiChar));
        GetMem(pCurCommand, LastPos - curPos + 1);
        Move(SQLText[curPos], pCurCommand^, LastPos - curPos);
        pCurCommand[LastPos - curPos] := #0;
        vb := vBatchBuffer;
        Inc(vb, vBatchCount);
        vb^ := pCurCommand;
        Inc(vBatchCount);
      end;
      curPos := LastPos
    end; // while
    Results := nil;
    try
      if vBatchCount > 0 then
      begin
        if qoStartTransaction in Options then
          if (Transaction <> nil) and not Transaction.InTransaction then
            Transaction.StartTransaction;

        GetMem(Results, vBatchCount * SizeOf(ULong));
        Call(Database.ClientLibrary.isc_dsql_batch_execute_immed(StatusVector,
          @Database.Handle, @Transaction.Handle, Database.SQLDialect, vBatchCount, vBatchBuffer, Results), True);
      end
    finally
      vb := vBatchBuffer;
      for i := 0 to vBatchCount - 1 do
      begin
        FreeMem(vb^);
        Inc(vb);
      end;
      FreeMem(vBatchBuffer);
      FreeMem(Results);
    end;
  end
end;
{$ENDIF}

procedure TFIBQuery.ExecQuery;
var
  fetch_res: ISC_STATUS;
  pc: integer;
  SV: PISC_STATUS;
  xSQLDA: PXSQLDA;
  vParams: TFIBXSQLDA;

  procedure DoLog(E: Exception = nil);
  var
    j: integer;
    st: string;
    Mess: String;
  begin
    if E = nil then
      Mess := 'Execute query:'
    else
      Mess := 'Error on execute query. Error message: "' + E.Message + '"';
    // if Assigned(Database.SQLLogger)  and (lfQExecute in Database.SQLLogger.LogFlags) then
    begin
      st := '';
      for j := 0 to vParams.Count - 1 do
        with vParams[j] do
        begin
          if (FXSQLVAR^.SQLType and (not 1) <> SQL_ARRAY) and (FXSQLVAR^.SQLType and (not 1) <> SQL_BLOB) then
            st := st + CLRF + 'Params[' + IntToStr(j) + ']=''' + AsString + ''''
          else
            st := st + CLRF + 'Params[' + IntToStr(j) + ']=(' + IntToStr(vParams[j].AsQuad.gds_quad_high) + ',' +
              IntToStr(vParams[j].AsQuad.gds_quad_low) + ')'
        end;

      Database.SQLLogger.WriteData(CmpFullName(Self), 'TrID=' + IntToStr(Transaction.TransactionID) + ' ' + Mess,
        FProcessedSQL + st, lfQExecute);
    end;
  end;

{$IFNDEF NO_MONITOR}
  procedure DoMonitoring(E: Exception);
  begin
    with THackMonitorHook(MonitorHook) do // Added Source
    begin
      SQLExecute(Self, '');
      WriteSQLData(CmpFullName(Self) + ': [Execute] ' + E.Message, tfQExecute);
    end;
  end;
{$ENDIF}

begin
  Include(FQueryRunState, qrsInExecute);
  vFetched := False;
  try
    // Before DoBeforeExecute, as closing may commit
    if FOpen then
      Close;
    BuildDeferredSQL;
    if GetSQLKind = skDDL then
    begin
      ExecuteImmediate;
      Exit;
    end;

    DoBeforeExecute;
    pc := Params.Count;
    if FDoParamCheck and (pc > 0) then
      Prepare
    else if not Prepared then
      Prepare;
    SaveStreamedParams(FUserSQLParams);
{$IFDEF SUPPORT_ARRAY_FIELD}
    PutArrayParams;
{$ENDIF}
    if (vDiffParams and FDoParamCheck and (pc > 0)) then
    begin
      FSQLParams.AssignValues(FUserSQLParams);
      xSQLDA := FSQLParams.FXSQLDA;
      vParams := FSQLParams
    end
    else
    begin
      xSQLDA := FUserSQLParams.FXSQLDA;
      vParams := FUserSQLParams;
      if FUserSQLParams.FHasDefferedSettings then
        FUserSQLParams.AdjustDefferedSettings;
    end;

    FCallTime := FIBGetTickCount;

    try
      SV := StatusVector;
      case FSQLType of
        SQLSelect, SQLSelectForUpdate:
          begin
            StartStatisticExec(FProcessedSQL);
            Call(Database.ClientLibrary.isc_dsql_execute(SV, TRHandle, @FHandle, Database.SQLDialect, xSQLDA), True);
            EndStatisticExec(FProcessedSQL);
            FOpen := True;
            FBOF := True;
            FEof := False;
            FRecordCount := 0;
            FSQLRecord.ClearValues;
            if Assigned(Database.SQLLogger) and (lfQExecute in Database.SQLLogger.LogFlags) then
              DoLog;
          end;
        SQLExecProcedure:
          begin
            StartStatisticExec(FProcessedSQL);
            fetch_res := Call(Database.ClientLibrary.isc_dsql_execute2(SV,
              TRHandle, @FHandle, Database.SQLDialect, xSQLDA, FSQLRecord.FXSQLDA), False);
            EndStatisticExec(FProcessedSQL);
            if Assigned(Database.SQLLogger) and (lfQExecute in Database.SQLLogger.LogFlags) then
              DoLog;
            if (fetch_res <> 0) then
              IBError(Database.ClientLibrary, Self);
            FProcExecuted := True;
          end;
        SQLCommit:
          begin
            StartStatisticExec(FProcessedSQL);
            Transaction.Commit;
            EndStatisticExec(FProcessedSQL);
            if Assigned(Database.SQLLogger) and (lfQExecute in Database.SQLLogger.LogFlags) then
              DoLog;
          end;
        SQLRollback:
          begin
            StartStatisticExec(FProcessedSQL);
            Transaction.RollBack;
            EndStatisticExec(FProcessedSQL);
            if Assigned(Database.SQLLogger) and (lfQExecute in Database.SQLLogger.LogFlags) then
              DoLog;
          end;
      else
        begin
          StartStatisticExec(FProcessedSQL);
          Call(Database.ClientLibrary.isc_dsql_execute(StatusVector, TRHandle,
            @FHandle, Database.SQLDialect, xSQLDA), True);
          EndStatisticExec(FProcessedSQL);
          if Assigned(Database.SQLLogger) and (lfQExecute in Database.SQLLogger.LogFlags) then
            DoLog;
        end;
      end;

      FCallTime := FIBGetTickCount - FCallTime;

      if FDoParamCheck and (pc > 0) and FHaveMacros then
        SaveRestoreValues(FUserSQLParams, True);
      // AfterExecute sees the first record
      if FGoToFirstRecordOnExecute and FOpen then
        Next;
      DoAfterExecute;
      if not(FSQLType in [SQLSelect, SQLSelectForUpdate]) then
        CompleteStatement
      else if FOpen and FEof and CloseOnEof then
        Close;
    except
      On E: Exception do
      begin
        FCallTime := FIBGetTickCount - FCallTime;
{$IFNDEF NO_MONITOR}
        if MonitoringEnabled then
          if MonitorHook <> nil then
            DoMonitoring(E);
        { with THackMonitorHook(MonitorHook) do    //Added Source
          begin
          SQLExecute( Self );
          WriteSQLData(CmpFullName(Self) + ': [Execute] ' + E.Message,tfQExecute);
          end; }
{$ENDIF}
        if Assigned(Database.SQLLogger) and (lfQExecute in Database.SQLLogger.LogFlags) then
          DoLog(E);
        raise;
      end
    end;
  finally
    Exclude(FQueryRunState, qrsInExecute);
  end
end;

procedure TFIBQuery.ExecWPS(const ParamSources: array of ISQLObject);
begin
  AssignSQLObjectParams(Self, ParamSources);
  ExecQuery;
end;

procedure TFIBQuery.ExecWPS(ParamSource: ISQLObject; AllRecords: boolean = True);
var
  ErrorAction: TBatchErrorAction;
begin
  if AllRecords then
    while not ParamSource.IEof do
    begin
      AssignSQLObjectParams(Self, [ParamSource]);
      try
        ExecQuery;
      except
        on E: EFIBError do
          if Assigned(FOnBatchError) then
          begin
            ErrorAction := beFail;
            FOnBatchError(E, ErrorAction);
            case ErrorAction of //
              beFail: raise;
              beAbort: Abort;
            end; // case
          end
          else
            raise
      end;
      ParamSource.INext
    end
  else
    ExecWPS([ParamSource]);
end;

function TFIBQuery.GetEOF: boolean;
begin
  Result := FEof or not FOpen;
end;

function TFIBQuery.FieldByName(const FieldName: string): TFIBXSQLVAR;
begin
  Result := FSQLRecord.ByName[FieldName];
  if not Assigned(Result) then
    FIBError(feFieldNotFound, [FieldName]);
end;

function TFIBQuery.FindField(const FieldName: string): TFIBXSQLVAR;
begin
  Result := FSQLRecord.ByName[FieldName];
end;

function TFIBQuery.FN(const FieldName: string): TFIBXSQLVAR;
begin
  Result := FSQLRecord.ByName[FieldName];
end;

function TFIBQuery.FieldByOrigin(const TableName, FieldName: string): TFIBXSQLVAR;
var
  i: integer;
  vTableName: string;
  vFieldName: string;
begin
  if Assigned(Database) and ((Database.SQLDialect < 3) or Database.UpperOldNames) then
  begin
    vTableName := FastUpperCase(TableName);
    vFieldName := FastUpperCase(FieldName);
  end
  else
  begin
    vTableName := TableName;
    vFieldName := FieldName;
  end;
  with FSQLRecord do
    for i := 0 to Pred(FCount) do
    begin
      if (FXSQLVARs[i].RelationName = vTableName) and (FXSQLVARs[i].SqlName = vFieldName) then
      begin
        Result := FXSQLVARs[i];
        Exit;
      end;
    end;
  Result := nil;
end;

function TFIBQuery.SQLFieldName(const aFieldName: string): string;
var
  tf: TFIBXSQLVAR;
  vSQL: string;
  rn: string;
begin
  if not Prepared then
    Prepare;
  tf := FN(aFieldName);
  if not Assigned(tf) then
    Result := ''
  else
  begin
    vSQL := ReadySQLText(False);
    rn := tf.RelationName;
    if Length(rn) > 0 then
      Result := FormatIdentifier(3, TableAliasForFieldByName(aFieldName)) + '.' + FormatIdentifier(3, tf.SqlName)
    else
      Result := ''
  end;
end;

function TFIBQuery.GetFields(const Idx: integer): TFIBXSQLVAR;
begin
  if (Idx < 0) or (Idx >= FSQLRecord.Count) then
    FIBError(feFieldNotFound, ['Field No: ' + IntToStr(Idx)]);
  Result := FSQLRecord[Idx];
end;

function TFIBQuery.GetFieldIndex(const FieldName: string): integer;
var
  xsv: TFIBXSQLVAR;
begin
  xsv := FSQLRecord.ByName[FieldName];
  if (xsv = nil) then
    Result := -1
  else
    Result := xsv.Index;
end;

function TFIBQuery.Next: TFIBXSQLDA;
var
  fetch_res: ISC_STATUS;
  StopFetching: boolean;

  procedure DoLog;
  var
    i: integer;
    st: String;
  begin
    // if Assigned(FBase.Database.SQLLogger) and (lfQFetch in FBase.Database.SQLLogger.LogFlags) then
    begin
      for i := 0 to Pred(Current.Count) do
      begin
        st := st + Fields[i].Name + ' = ';
        if Fields[i].IsNull then
          st := st + 'NULL'
        else
          st := st + Fields[i].AsString;
        st := st + CRLF;
      end;
      st := CRLF + st;

      if (Eof) then
        st := st + CRLF + '  End of file reached';
      FBase.Database.SQLLogger.WriteData(CmpFullName(Self), 'Fetch:', st, lfQFetch);
    end
  end;

begin
  Result := nil;
  if not FEof then
  begin
    CheckOpen('fetch next record');
    if Assigned(FOnSQLFetch) then
    begin
      StopFetching := False;
      FOnSQLFetch(FRecordCount, StopFetching);
      if StopFetching and not(csLoading in ComponentState) then
        // Abort;
        Exit;
    end;
    // Go to the next record...
    Set8087CW(Default8087CW);
    // vLib:=FBase.Database.ClientLibrary;
    fetch_res := Call(FBase.Database.ClientLibrary.isc_dsql_fetch(StatusVector,
      @FHandle, FBase.Database.SQLDialect, FSQLRecord.FXSQLDA), False);

    if (fetch_res > 0) then
    begin
      if (fetch_res = 100) then
        FEof := True
      else if (CheckStatusVector([isc_dsql_cursor_err])) then
        FEof := True
      else
        try
          IBError(FBase.Database.ClientLibrary, Self);
        except
          CloseCursor(False);
          raise;
        end
    end
    else
    begin
      Inc(FRecordCount);
      FBOF := False;
      Result := FSQLRecord;
    end;
{$IFNDEF NO_MONITOR}
    if MonitoringEnabled then
      if MonitorHook <> nil then
        MonitorHook.SQLFetch(Self);
{$ENDIF}
    if Assigned(FBase.Database.SQLLogger) and (lfQFetch in FBase.Database.SQLLogger.LogFlags) then
      DoLog;
  end;
  if not vFetched then
  begin
    vFetched := True;
    DoAfterFirstFetch;
  end;
  // ExecQuery closes it after AfterExecute
  if FEof and FOpen and not(qrsInExecute in FQueryRunState) and CloseOnEof then
    Close;
end;

procedure TFIBQuery.FreeHandle;
var
  isc_res: ISC_STATUS;
begin
  try
    FSQLRecord.Count := 0;
    if FHandle <> nil then
    begin
      isc_res := Call(Database.ClientLibrary.isc_dsql_free_statement(StatusVector, @FHandle, DSQL_drop), False);
      if (StatusVector^ = 1) and (isc_res > 0) and (isc_res <> isc_bad_stmt_handle) then
        IBError(Database.ClientLibrary, Self);
      FEof := True;
    end;
  finally
    FPrepared := False;
    FHandle := nil;
  end;
end;

function TFIBQuery.GetDatabase: TFIBDatabase;
begin
  Result := FBase.Database;
end;

function TFIBQuery.GetDBHandle: PISC_DB_HANDLE;
begin
  Result := FBase.DBHandle;
end;

function Get_Numeric_Info(ClientLibrary: IIbClientLibrary; var buffer: PAnsiChar): integer;
var
  L: Short;
begin
  if not Assigned(ClientLibrary) then
    Result := -1
  else
  begin
    L := ClientLibrary.isc_vax_integer(buffer, 2);
    Inc(buffer, 2);
    Result := ClientLibrary.isc_vax_integer(buffer, L);
    Inc(buffer, L);
  end;
end;

function Get_String_Info(ClientLibrary: IIbClientLibrary;
  var SourceBuffer: PAnsiChar; DestBuffer: PAnsiChar; Dest_len: integer)
  : integer; overload;
var
  L: integer;
begin
  if not Assigned(ClientLibrary) then
    Result := -1
  else
  begin
    FillChar(DestBuffer[0], Dest_len, 0);
    L := ClientLibrary.isc_vax_integer(SourceBuffer, 2);
    Result := L;
    if Result >= Dest_len then
      Result := Dest_len - 1;
    Move(SourceBuffer[2], DestBuffer[0], Result);
    Inc(SourceBuffer, L + 2);
  end
end;

function Get_String_Info(ClientLibrary: IIbClientLibrary; var SourceBuffer: PAnsiChar): Ansistring; overload;
var
  L: integer;
begin
  L := ClientLibrary.isc_vax_integer(SourceBuffer, 2);
  SetString(Result, SourceBuffer + 2, L);
  Inc(SourceBuffer, L + 2);
end;

function TFIBQuery.DecodeName(const Name: Ansistring): string;
begin
  Result := DecodeString(Name, Database.Capabilities.MetadataCodePage);
end;

// The XSQLVAR names may be cut or, with clients before Firebird 4, empty
function TFIBQuery.FullNamesNeeded(NamesCut: boolean): boolean;
begin
  Result := (Database.Capabilities.MaxIdentifierLength > LENGTH_METANAMES - 1)
    and (NamesCut or not ClientTruncatesNames(Database.ClientLibrary));
end;

procedure TFIBQuery.ReadRelationAliases;
var
  i: integer;
  vSQL: string;
  rn: string;
begin
  if not Prepared then
    Exit;
  if Database.IsFirebirdConnect and (Database.ServerMajorVersion >= 2) and (FHandle <> nil { for MDT } ) then
  begin
    ReadDescribeInfo(FSQLRecord, False);
    if FRelationAliasesRead then
      Exit;
  end;
  // old servers or an unreadable info answer
  FRelationAliasesRead := True;
  vSQL := ReadySQLText(False);
  for i := 0 to Pred(FSQLRecord.Count) do
  begin
    rn := FSQLRecord.FXSQLVARs^[i].RelationName;
    if Length(rn) > 0 then
      rn := AliasForTable(vSQL, FormatIdentifier(3, rn));
    FSQLRecord.FXSQLVARs^[i].FRelationAlias := rn;
  end;
end;

// Relation aliases and, with ReadNames, full names; a failed call keeps the XSQLVAR names
procedure TFIBQuery.ReadDescribeInfo(SQLDA: TFIBXSQLDA; ReadNames: boolean);
var
  IsSelect: boolean;
  Status: ISC_STATUS;
  DescribeItem: Byte;
  Request: array [0 .. 12] of AnsiChar;
  RequestLength: integer;
  buffer: array [0 .. 32766] of AnsiChar;
  p: PAnsiChar;
  Lib: IIbClientLibrary;
  Item: Byte;
  Index, StartIndex: integer;
  Truncated: boolean;
  S: string;

  procedure AddItem(Value: Byte);
  begin
    Request[RequestLength] := AnsiChar(Value);
    Inc(RequestLength);
  end;

begin
  if FHandle = nil then
    Exit;
  IsSelect := SQLDA = FSQLRecord;
  if IsSelect then
  begin
    DescribeItem := isc_info_sql_select;
    // only after a complete answer, else ReadRelationAliases falls back
    FRelationAliasesRead := False;
    for Index := 0 to Pred(SQLDA.Count) do
      SQLDA.FXSQLVARs^[Index].FRelationAlias := '';
  end
  else
    DescribeItem := isc_info_sql_bind;
  Lib := Database.ClientLibrary;
  StartIndex := 1;
  repeat
    RequestLength := 0;
    if StartIndex > 1 then
    begin
      AddItem(isc_info_sql_sqlda_start);
      AddItem(2);
      AddItem(StartIndex and $FF);
      AddItem(StartIndex shr 8);
    end;
    AddItem(DescribeItem);
    AddItem(isc_info_sql_describe_vars);
    AddItem(isc_info_sql_sqlda_seq);
    if ReadNames then
    begin
      AddItem(isc_info_sql_field);
      AddItem(isc_info_sql_relation);
      if IsSelect then
      begin
        AddItem(isc_info_sql_owner);
        AddItem(isc_info_sql_alias);
      end;
    end;
    if IsSelect then
      AddItem(frb_info_sql_relation_alias);
    AddItem(isc_info_sql_describe_end);
    Status := Lib.isc_dsql_sql_info(StatusVector, @FHandle, RequestLength, @Request[0], SizeOf(buffer), buffer);
    Call(Status, False);
    if Status > 0 then
      Exit;
    if (buffer[0] <> AnsiChar(DescribeItem)) or (buffer[1] <> AnsiChar(isc_info_sql_describe_vars)) then
      Exit;
    p := @buffer[2];
    Get_Numeric_Info(Lib, p);
    Index := -1;
    Truncated := False;
    while not Truncated and (p^ <> AnsiChar(isc_info_end)) do
    begin
      Item := Byte(p^);
      Inc(p);
      case Item of
        isc_info_sql_describe_end: ;
        isc_info_truncated: Truncated := True;
        isc_info_sql_sqlda_seq: Index := Get_Numeric_Info(Lib, p) - 1;
        isc_info_sql_field, isc_info_sql_relation, isc_info_sql_owner, isc_info_sql_alias, frb_info_sql_relation_alias:
          begin
            S := DecodeName(Get_String_Info(Lib, p));
            if (Index >= 0) and (Index < SQLDA.Count) then
              with SQLDA.FXSQLVARs^[Index] do
                case Item of
                  isc_info_sql_field: FSqlName := S;
                  isc_info_sql_relation: FRelationName := S;
                  isc_info_sql_owner: FOwnerName := S;
                  isc_info_sql_alias: FAliasName := S;
                else
                  if S = '' then
                    FRelationAlias := FRelationName
                  else
                    FRelationAlias := S;
                end;
          end;
      else
        Exit;
      end;
    end;
    // Continue from the column that did not fit
    if Truncated then
      if Index + 1 > StartIndex then
        StartIndex := Index + 1
      else
        Exit;
  until not Truncated;
  if IsSelect then
    FRelationAliasesRead := True;
end;

function TFIBQuery.TableAliasForField(FieldIndex: integer): string;
begin
  if not Prepared then
    Prepare;
  if (FieldIndex < 0) or (FieldIndex >= FSQLRecord.Count) then
    Result := ''
  else
    Result := FormatIdentifier(3, FSQLRecord[FieldIndex].RelationAlias);
end;

function TFIBQuery.TableAliasForFieldByName(const aFieldName: string): string;
var
  tf: TFIBXSQLVAR;
begin
  tf := FN(aFieldName);
  if not Assigned(tf) then
    Result := ''
  else
    Result := TableAliasForField(tf.FIndex);
end;

// {$IFNDEF BCB}
function TFIBQuery.TableAliasForField(const aFieldName: string): string;
begin
  Result := TableAliasForFieldByName(aFieldName)
end;
// {$ENDIF}

function TFIBQuery.SQLDescribeInfo(InfoRequest: array of AnsiChar): PXSQLDA;
var
  Result_buffer: array [0 .. 32766] of AnsiChar;
  PResult: PAnsiChar;
  N: integer;
  Item: PAnsiChar;
  Index: Short;
  SqlVar: PXSQLVAR;
  Lib: IIbClientLibrary;
begin
  if (not Prepared) then
    Result := nil
  else
  begin
    Lib := Database.ClientLibrary;
    Call(Lib.isc_dsql_sql_info(StatusVector, @FHandle, SizeOf(InfoRequest), @InfoRequest[0],
      // SizeOf(Result_buffer)
      32766, Result_buffer), True);
    if not(Result_buffer[0] in [AnsiChar(isc_info_sql_select), AnsiChar(isc_info_sql_bind)]) or
      (Result_buffer[1] <> AnsiChar(isc_info_sql_describe_vars)) then
    begin
      Result := nil;
      Exit;
    end;
    PResult := @Result_buffer[2];
    N := Get_Numeric_Info(Lib, PResult);
    Result := AllocMem(XSQLDA_LENGTH(N));
    Result^.Version := SQLDA_VERSION1;
    Result^.sqld := N;
    while PResult[0] <> AnsiChar(isc_info_end) do
    begin
      Item := PResult;
      SqlVar := nil;
      if Item[0] = AnsiChar(isc_info_sql_describe_end) then
        Inc(PResult, 1)
      else
        while Item[0] <> AnsiChar(isc_info_sql_describe_end) do
        begin
          Inc(PResult, 1);
          case Byte(Item[0]) of
            isc_info_sql_sqlda_seq:
              begin
                index := Get_Numeric_Info(Lib, PResult);
                SqlVar := @Result^.SqlVar[index - 1];
                Inc(Result^.sqln)
              end;
            isc_info_sql_type: SqlVar.SQLType := Get_Numeric_Info(Lib, PResult);
            isc_info_sql_sub_type: SqlVar.SQLSubtype := Get_Numeric_Info(Lib, PResult);
            isc_info_sql_scale: SqlVar.sqlscale := Get_Numeric_Info(Lib, PResult);
            isc_info_sql_length: SqlVar.sqllen := Get_Numeric_Info(Lib, PResult);
            isc_info_sql_field:
              SqlVar.sqlname_length := Get_String_Info(Lib, PResult, @SqlVar.SqlName[0], SizeOf(SqlVar.SqlName));
            isc_info_sql_relation:
              SqlVar.relname_length := Get_String_Info(Lib, PResult, @SqlVar.RelName[0], SizeOf(SqlVar.RelName));
            isc_info_sql_owner:
              SqlVar.ownname_length := Get_String_Info(Lib, PResult, @SqlVar.ownname[0], SizeOf(SqlVar.ownname));
            isc_info_sql_alias:
              SqlVar.aliasname_length := Get_String_Info(Lib, PResult, @SqlVar.AliasName[0], SizeOf(SqlVar.AliasName));
            { frb_info_sql_relation_alias:
              get_string_info(Lib,PResult,@SQLVar.ownname[0],SizeOf(SQLVar.aliasname)); }
            isc_info_truncated:
              begin

              end;
          end;
          Item := PResult;
        end;
    end;
  end;
end;

{$R-}

function TFIBQuery.GetPlan: string;
var
  Result_buffer: array [0 .. cPlanMaxLength] of AnsiChar;
  Result_length: integer;
  info_request: AnsiChar;
  Position: integer;
begin
  if (not Prepared) or (not(FSQLType in [SQLSelect, SQLSelectForUpdate,
    SQLExecProcedure, SQLUpdate, SQLDelete, SQLInsert])) then
    Result := ''
  else
  begin
    info_request := AnsiChar(isc_info_sql_get_plan);
    Call(Database.ClientLibrary.isc_dsql_sql_info(StatusVector, @FHandle, 1,
      @info_request, SizeOf(Result_buffer), Result_buffer), True);
    if (Result_buffer[0] <> AnsiChar(isc_info_sql_get_plan)) then
    begin
      Result := '';
      Exit;
    end;
    Result_length := Database.ClientLibrary.isc_vax_integer
      (@Result_buffer[1], 2);

    Position := 3;
    while (Result_length > 0) and (Result_buffer[Position] in [#0, #10, #13, #9, ' ']) do
    begin
      Inc(Position);
      Dec(Result_length);
    end;
    if Result_length > 0 then
      Result := DecodeString(PAnsiChar(@Result_buffer[Position]), Result_length, Database.Capabilities.MetadataCodePage)
    else
      Result := '';
  end;
end;

function TFIBQuery.GetRecordCount: integer;
begin
  Result := FRecordCount;
end;

function TFIBQuery.GetAllRowsAffected: TAllRowsAffected;
var
  InfoBuffer: PAnsiChar;
  AllocAddr: PAnsiChar;

  info_request: AnsiChar;
  InfoLen: integer;

  function ReadRequest: integer;
  begin
    with Database.ClientLibrary do
    begin
      Inc(InfoBuffer);
      InfoLen := isc_vax_integer(InfoBuffer, 2);
      Inc(InfoBuffer, 2);
      Result := isc_vax_integer(InfoBuffer, InfoLen);
      Inc(InfoBuffer, InfoLen);
    end;
  end;

begin
  if not Prepared then
    Prepare;
  InfoBuffer := AllocMem(255);
  AllocAddr := InfoBuffer;
  try
    with Database.ClientLibrary do
    begin
      info_request := AnsiChar(isc_info_sql_records);
      FillChar(Result, SizeOf(Result), 0);

      if isc_dsql_sql_info(StatusVector, @FHandle, 1, @info_request, 255, InfoBuffer) > 0 then
        IBError(Database.ClientLibrary, Self);
      if (InfoBuffer[0] = AnsiChar(isc_info_end)) then
        Exit;
      if (InfoBuffer[0] <> AnsiChar(isc_info_sql_records)) then
        FIBError(feUnknownError, [nil]);
      Inc(InfoBuffer);
      InfoLen := isc_vax_integer(InfoBuffer, 2);
      if InfoLen > 255 then
      begin
        InfoBuffer := AllocAddr;
        ReallocMem(InfoBuffer, InfoLen);
        AllocAddr := InfoBuffer;
        if isc_dsql_sql_info(StatusVector, @FHandle, 1, @info_request, InfoLen, InfoBuffer) > 0 then
          IBError(Database.ClientLibrary, Self);
        Inc(InfoBuffer);
      end;
      Inc(InfoBuffer, 2);

      while Byte(InfoBuffer[0]) <> isc_info_end do
        case Byte(InfoBuffer[0]) of
          isc_info_req_insert_count: Result.Inserts := ReadRequest;
          isc_info_req_update_count: Result.Updates := ReadRequest;
          isc_info_req_select_count: Result.Selects := ReadRequest;
          isc_info_req_delete_count: Result.Deletes := ReadRequest;
        else
          FIBError(feUnknownError, [nil]);
        end;
    end;
  finally
    FreeMem(AllocAddr);
  end;
end;

function TFIBQuery.GetRowsAffected: integer;
var
  ar: TAllRowsAffected;
begin
  ar := GetAllRowsAffected;
  case SQLType of
    SQLUpdate: Result := ar.Updates;
    SQLDelete: Result := ar.Deletes;
    SQLInsert: Result := ar.Inserts;
    SQLSelect: Result := ar.Selects;
  else
    Result := ar.Updates + ar.Deletes + ar.Selects + ar.Inserts
  end;
end;

procedure TFIBQuery.BuildDeferredSQL;
begin
end;

function TFIBQuery.GetSQLParams: TFIBXSQLDA;
begin
  BuildDeferredSQL;
  if (FUserSQLParams.FXSQLDA = nil) and not vUserParamsCreated then
    SQLChange(nil);
  Result := FUserSQLParams;
end;

function TFIBQuery.GetTransaction: TFIBTransaction;
begin
  Result := FBase.Transaction;
end;

function TFIBQuery.GetTRHandle: PISC_TR_HANDLE;
begin
  Result := FBase.TRHandle;
end;

(*
  * Preprocess SQL
  *  Using FSQL, process the typed SQL and put the process SQL
  *  in FProcessedSQL and parameter names in FSQLParams
*)
const
  ParamNameChars = ['A' .. 'Z', 'a' .. 'z', '0' .. '9', '_', '$', '%',
    '#', '.'];

procedure TFIBQuery.PreprocessSQL(const sSQL: String; IsUserSQL: boolean);
const
  DefParCount = 10;
var
  cCurChar, cNextChar, cQuoteChar: Char;
  sParamName: string;
  sMacroName: string;
  i, iLenSQL, iCurState, iSQLPos: integer;
  iCurParamState: Byte;
  slNames: TStrings;
  BracketOpenedInWhere: integer;

  vParams: TFIBXSQLDA;
  NewParams: TFIBXSQLDA;
  tempVar, tempVar1: TXSQLVAR;
  ParVar, NParVar: TFIBXSQLVAR;

  PCount, ind: integer;

  CurMDef: string;
  OldStyleMacro: boolean;
  // EndMacro :boolean;
  InWhereClause: boolean;
  CanForceIsNull: boolean;
  OldMacroChanged: boolean;

  vBeginParamPos: integer;
  vBeginParamsPos: array of integer;
  vEndParamsPos: array of integer;
  vInDeclarationSection: boolean;

  procedure AddToProcessedSQL(cChar: Char);
  begin
    if not IsUserSQL then
    begin
      if iSQLPos > Length(FProcessedSQL) then
        SetLength(FProcessedSQL, Length(FProcessedSQL) + 512);
      FProcessedSQL[iSQLPos] := cChar;
      Inc(iSQLPos);
    end;
  end;

  function ParamCanForceIsNull(EndPos: integer): boolean;
  begin
    if not InWhereClause then
      Result := False
    else
    begin
      while (EndPos <= iLenSQL) and CharInSet(sSQL[EndPos], [' ', #9, #13, #10]) do
        Inc(EndPos);
      if EndPos <= iLenSQL then
      begin
        case sSQL[EndPos] of
          '+', '|', '*': Result := False;
          '-': Result := (EndPos < iLenSQL) and (sSQL[EndPos + 1] = '-');
          '/':
            Result := (EndPos < iLenSQL) and (sSQL[EndPos + 1] = '*');
        else
          Result := True;
        end;
      end
      else
        Result := True;
    end;
  end;

const
  DefaultState      = 0;
  CommentState      = 1;
  QuoteState        = 2;
  ParamState        = 3;
  MacroState        = 4;
  FBCommentState    = 5;
  ParamDefaultState = 0;
  ParamQuoteState   = 1;

  procedure RegParamName(AddQuote: boolean);
  var
    B: Byte;
  begin
    iCurParamState := ParamDefaultState;
    // iCurState := DefaultState;
    if (cNextChar = '-') and (i + 2 < iLenSQL) and (sSQL[i + 2] = '-') then
      iCurState := FBCommentState
    else if (cNextChar = '/') and (i + 2 < iLenSQL) and (sSQL[i + 2] = '*') then
      iCurState := CommentState
    else
      iCurState := DefaultState;
    Inc(PCount);
    B := 0;
    if InWhereClause then
      B := SetBit(B, 0, True);
    if CanForceIsNull then
      B := SetBit(B, 1, True);
    if AddQuote then
      B := SetBit(B, 2, True);

    slNames.AddObject(sParamName, TObject(B));
    SetLength(vBeginParamsPos, PCount);
    SetLength(vEndParamsPos, PCount);
    vBeginParamsPos[PCount - 1] := vBeginParamPos;
    if AddQuote then
      vEndParamsPos[PCount - 1] := i + 1
    else
      vEndParamsPos[PCount - 1] := i;
    sParamName := '';
    { if iCurState in [CommentState,FBCommentState] then
      begin
      Inc(i)
      end; }
  end;

begin
  slNames := TStringList.Create;
  try
    // Do some initializations of variables
    cQuoteChar := '''';
    PCount := 0;
    InWhereClause := False;
    CanForceIsNull := False;
    BracketOpenedInWhere := 0;
    iLenSQL := Length(sSQL); // +MaxParams
    if not IsUserSQL then
    begin
      FCodePageApplied := False;
      SetString(FProcessedSQL, nil, iLenSQL);
      FillChar(FProcessedSQL[1], iLenSQL, 0);
    end;

    i := 1;
    iSQLPos := 1;
    iCurState := DefaultState;
    iCurParamState := ParamDefaultState;
    OldStyleMacro := False;
    vInDeclarationSection := True;
    (*
      * Now, traverse through the SQL string, character by character,
      * picking out the parameters and formatting correctly for InterBase.
    *)
    while (i <= iLenSQL) do
    begin
      // Get the current token and a look-ahead.
      cCurChar := sSQL[i];
      if i = iLenSQL then
        cNextChar := #0
      else
        cNextChar := sSQL[i + 1];

      if (iCurState = DefaultState) and not(SQLKind in [skExecuteProc, skExecuteBlock]) then
      begin
        if not InWhereClause then
        begin
          InWhereClause := IsWhereBeginPos(sSQL, i);
          if InWhereClause and IsUserSQL then
          begin
            Inc(i, 5);
            BracketOpenedInWhere := 0;
            Continue;
          end
        end
        else
        begin
          case cCurChar of
            '(': Inc(BracketOpenedInWhere);
            ')': Dec(BracketOpenedInWhere);
          end;
          InWhereClause := (BracketOpenedInWhere >= 0) and not IsWhereEndPos(sSQL, i)
        end;
      end;

      // Now act based on the current state.
      case iCurState of
        DefaultState:
          begin
            case cCurChar of
              'A', 'a':
                begin
                  if SQLKind = skExecuteBlock then
                  begin
                    if vInDeclarationSection and (iLenSQL - i >= 2) then
                      vInDeclarationSection := not(CharInSet(sSQL[i + 1], ['S', 's']) and
                        CharInSet(sSQL[i + 2], CharsAfterClause));
                    if vInDeclarationSection and (iLenSQL - i >= 2) then
                      vInDeclarationSection := not(CharInSet(sSQL[i + 1], ['S', 's']) and
                        CharInSet(sSQL[i + 2], CharsAfterClause));
                  end;
                end;

              '''', '"':
                begin
                  cQuoteChar := cCurChar;
                  iCurState := QuoteState;
                end;
              '?', ':':
                if FParser.CanParamsCheck and vInDeclarationSection then
                begin
                  iCurState := ParamState;
                  AddToProcessedSQL('?');
                  vBeginParamPos := i;
                end;
              '/':
                if (cNextChar = '*') then
                begin
                  AddToProcessedSQL(cCurChar);
                  Inc(i);
                  iCurState := CommentState;
                end;
              '-':
                begin
                  if cCurChar = cNextChar then
                  begin
                    iCurState := FBCommentState;
                    AddToProcessedSQL(cCurChar);
                    Inc(i);
                  end;
                end;
            else
              if cCurChar = FMacroChar then
              begin
                iCurState := MacroState;
                OldStyleMacro := cNextChar <> FMacroChar;
                if OldStyleMacro then
                  sParamName := FMacroChar;
                vBeginParamPos := i;
              end;
            end;
          end;
        FBCommentState:
          begin
            if CharInSet(cCurChar, [#0, #13, #10]) then
              iCurState := DefaultState;
          end;
        CommentState:
          begin
            if (cNextChar = #0) then
              FIBError(feSQLParseError, [CmpFullName(Self), SFIBErrorEOFInComments])
            else if (cCurChar = '*') then
            begin
              if (cNextChar = '/') then
                iCurState := DefaultState;
            end;
          end;
        QuoteState:
          begin
            if (cNextChar = #0) then
              FIBError(feSQLParseError, [CmpFullName(Self), SFIBErrorEOFInString])
            else if (cCurChar = cQuoteChar) then
            begin
              if (cNextChar = cQuoteChar) then
              begin
                AddToProcessedSQL(cCurChar);
                Inc(i);
              end
              else
                iCurState := DefaultState;
            end;
          end;
        ParamState, MacroState:
          begin
            if iCurParamState = ParamDefaultState then
              if cCurChar = '"' then
              begin
                iCurParamState := ParamQuoteState;
                Inc(i);
                AddToProcessedSQL(' ');
                Continue;
              end;
            // Step 1, collect the name of the parameter
            if (iCurParamState = ParamQuoteState) or CharInSet(cCurChar, ParamNameChars) then
              sParamName := sParamName + cCurChar
            else if ((iCurState = MacroState) and (not OldStyleMacro or not CharInSet(cCurChar, [' ', #13, #10]))) then
              sParamName := sParamName + cCurChar
            else if not CmpInLoadedState(Self) then
              FIBError(feSQLParseError, [CmpFullName(Self), SFIBErrorParamNameExpected])
            else
              Exit;
            // Step 2, determine if the parameter name is finished.
            if (cNextChar = '"') and (iCurParamState = ParamQuoteState) then
            begin
              CanForceIsNull := ParamCanForceIsNull(i + 2);
              RegParamName(True);
              Inc(i, 2);
              CanForceIsNull := False;
              AddToProcessedSQL(' ');
              Continue;
            end;

            if iCurState <> MacroState then
            begin
              if not CharInSet(cNextChar, ParamNameChars) and (iCurParamState <> ParamQuoteState) then
              begin
                CanForceIsNull := ParamCanForceIsNull(i + 1);
                RegParamName(False);
                if InWhereClause and (cNextChar = ')') then
                  Dec(BracketOpenedInWhere);
                Inc(i);
                CanForceIsNull := False;
              end;
            end
            else
            begin
              if OldStyleMacro then
              begin
                if not(iCurParamState = ParamQuoteState) and CharInSet(cNextChar, [' ', #13, #10]) then
                begin
                  RegParamName(False);
                  Inc(i);
                end;
              end
              else
              begin
                if not(iCurParamState = ParamQuoteState) and (cNextChar = FMacroChar) then
                begin
                  Inc(i);
                  RegParamName(False);
                end;
              end;
            end;
          end;
      end;
      if (iCurState in [ParamState, MacroState]) then
        AddToProcessedSQL(' ')
      else
        AddToProcessedSQL(sSQL[i]);
      Inc(i);
    end;

    if not IsUserSQL then
    begin
      SetLength(FProcessedSQL, iSQLPos - 1);
    end;

    // Create Params List
    NewParams := TFIBXSQLDA.Create(True);

    NewParams.FQuery := Self;
    NewParams.FXSQLDA := nil;

    if IsUserSQL then
      vParams := FUserSQLParams
    else
      vParams := FSQLParams;
    NewParams.FHasDefferedSettings := vParams.FHasDefferedSettings;
    NewParams.Count := slNames.Count;
    for i := 0 to slNames.Count - 1 do
    begin
      sParamName := slNames[i];
      if sParamName[1] <> FMacroChar then
      begin
        NewParams.AddName(sParamName, i, GetBit(Byte(slNames.Objects[i]), 2));
        NParVar := NewParams.FXSQLVARs^[i];
        NParVar.IsMacro := False;
        InternalSetNull(NParVar, True);
        if IsUserSQL then
          NParVar.FXSQLVAR^.SQLType := 0;
        NParVar.FInitialized := False;
        NParVar.FInWhereClause := GetBit(Byte(slNames.Objects[i]), 0);
        NParVar.FCanForceIsNull := GetBit(Byte(slNames.Objects[i]), 1);
        NParVar.FBeginPosInText := vBeginParamsPos[i];
        NParVar.FEndPosInText := vEndParamsPos[i];
      end
      else // macroses
        if not IsUserSQL then
          NewParams.Count := NewParams.Count - 1
        else
        begin
          CurMDef := '';
          sMacroName := ParseMacroString(sParamName, FMacroChar, CurMDef);
          NewParams.AddName(FastCopy(sMacroName, 2, 255), i, False);
          NParVar := NewParams.FXSQLVARs^[i];
          NParVar.IsMacro := True;
          FHaveMacros := True;
          NParVar.Quoted := (CurMDef <> '') and (CurMDef[1] = '#');
          if NParVar.Quoted then
            DoCopy(CurMDef, NewParams[i].FDefMacroValue, 2, Length(CurMDef) - 1)
          else
            NParVar.FDefMacroValue := CurMDef;
          if Length(CurMDef) > 0 then
            NParVar.FWideTempValue := CurMDef
          else
            InternalSetValue(NParVar, SQL_TEXT, 0, '');
          NParVar.FBeginPosInText := vBeginParamsPos[i];
          NParVar.FEndPosInText := vEndParamsPos[i];
        end;

      vParams.FCachedNames.Clear;
      if (vParams.Count > 0) and (NewParams.Count > i) then
      begin
        OldMacroChanged := MacroChanged;
        try
          FMacroChanged := False;
          ParVar := vParams.ByName[NewParams.FXSQLVARs^[i].Name];
        finally
          FMacroChanged := OldMacroChanged
        end;
        if Assigned(ParVar) and (ParVar.FParent <> vParams) then
          ParVar := nil
      end
      else
        ParVar := nil;
      if (ParVar <> nil) and (ParVar.FXSQLVAR^.SQLType and (not 1) <> 520) then
      // if (ParVar<>nil) then
      begin
        // Restore Old ParamValues
        NParVar := NewParams.FXSQLVARs^[i];
        ParVar.FInWhereClause := NParVar.FInWhereClause;
        ParVar.IsMacro := NParVar.IsMacro;
        ParVar.FDefMacroValue := NParVar.FDefMacroValue;
        ParVar.FBeginPosInText := NParVar.FBeginPosInText;
        ParVar.FEndPosInText := NParVar.FEndPosInText;
        tempVar := NParVar.FXSQLVAR^;
        tempVar1 := ParVar.FXSQLVAR^;
        NParVar.FParent := vParams;
        NParVar.FXSQLVAR^.SQLType := ParVar.FXSQLVAR^.SQLType;
        vParams.FXSQLVARs^[ParVar.FIndex] := NParVar;
        vParams.FXSQLDA^.SqlVar[ParVar.FIndex] := tempVar;

        NewParams.FXSQLVARs^[i] := ParVar;
        NewParams.FXSQLDA^.SqlVar[i] := tempVar1;
        ParVar.FXSQLVAR := @NewParams.FXSQLDA^.SqlVar[i];
        vParams[ParVar.FIndex].FXSQLVAR := @vParams.FXSQLDA^.SqlVar
          [ParVar.FIndex];
        ind := vParams.FNames.IndexOfObject(TObject(ParVar.FIndex));
        if ind > -1 then
          vParams.FNames.Delete(ind);
        ParVar.FParent := NewParams;
        ParVar.FIndex := i;
        ParVar.FSrvSQLType := 0;
        ParVar.FSrvSQLSubType := 0;
        ParVar.FSrvSQLLen := 0;
      end;
    end;
    if IsUserSQL then
      FUserSQLParams := NewParams
    else
      FSQLParams := NewParams;
    vParams.Free;
  finally
    slNames.Free;
  end;
end;

procedure TFIBQuery.SetDatabase(Value: TFIBDatabase);
begin
  if (Value <> FBase.Database) and FPrepared then
    FreeHandle;
  FBase.Database := Value;
end;

// Array Support
{$IFDEF SUPPORT_ARRAY_FIELD}

procedure TFIBQuery.PrepareArraySqlVar(SqlVar: TFIBXSQLVAR; const RelName, SqlName: string);
begin
  // the variables of the query are reused by the next Prepare, also for another statement
  if (SqlVar.vFIBArray = nil) or not SqlVar.vFIBArray.Matches(Database, RelName, SqlName) then
  begin
    FreeAndNil(SqlVar.vFIBArray);
    SqlVar.vFIBArray := TpFIBArray.Create(Database, Transaction, RelName, SqlName);
  end;
end;

procedure TFIBQuery.ReadParamNames;
var
  i: integer;
  NamesCut: boolean;
begin
  NamesCut := False;
  for i := 0 to FSQLParams.Count - 1 do
    with FSQLParams.FXSQLVARs^[i], FXSQLVAR^ do
    begin
      FRelationName := DecodeName(XSQLVARName(RelName, relname_length));
      FSqlName := DecodeName(XSQLVARName(SqlName, sqlname_length));
      NamesCut := NamesCut or XSQLVARNameCut(relname_length) or XSQLVARNameCut(sqlname_length);
    end;
  if (FSQLParams.Count > 0) and FullNamesNeeded(NamesCut) then
    ReadDescribeInfo(FSQLParams, True);
  FParamNamesRead := True;
end;

// Writes the array values of the parameters as new arrays
procedure TFIBQuery.PutArrayParams;
var
  i: integer;
  Par, Srvpar: TFIBXSQLVAR;
  ColumnRelation, ColumnName: string;
  buffer: TDataBuffer;
  ID: TISC_QUAD;
begin
  for i := 0 to FUserSQLParams.Count - 1 do
  begin
    Par := FUserSQLParams[i];
    if VarIsEmpty(Par.FArrayValue) then
      Continue;
    if vDiffParams then
      Srvpar := FSQLParams.FindParam(Par.Name)
    else
      Srvpar := FSQLParams[i];
    if (Srvpar = nil) or (Srvpar.SQLType <> SQL_ARRAY) then
      FIBErrorEx('Parameter %s is not an array', [Par.Name]);
    // the column the parameter is assigned to
    if not FParamNamesRead then
      ReadParamNames;
    ColumnRelation := Srvpar.FRelationName;
    ColumnName := Srvpar.FSqlName;
    if (Par.vFIBArray = nil) or not Par.vFIBArray.Matches(Database, ColumnRelation, ColumnName) then
    begin
      FreeAndNil(Par.vFIBArray);
      Par.vFIBArray := TpFIBArray.Create(Database, Transaction, ColumnRelation, ColumnName);
    end;
    buffer := nil;
    FIBAlloc(buffer, 0, Par.vFIBArray.ArraySize);
    try
      Par.vFIBArray.VariantToBuffer(Par.FArrayValue, PAnsiChar(buffer));
      Par.vFIBArray.PutSlice(PAnsiChar(buffer), ID, DBHandle, TRHandle);
    finally
      FIBAlloc(buffer, 0, 0);
    end;
    Par.AsQuad := ID;
  end;
end;

procedure TFIBQuery.PrepareArrayFields;
var
  i: integer;
  v: TFIBXSQLVAR;
  da: TFIBXSQLDA;
begin
  da := Current;
  for i := 0 to Pred(da.Count) do
  begin
    v := da.FXSQLVARs^[i];
    if v.FXSQLVAR^.SQLType and (not 1) = SQL_ARRAY then
      PrepareArraySqlVar(v, v.RelationName, v.SqlName);
  end;
end;
{$ENDIF}

procedure TFIBQuery.PrepareUserParamsTypes;
var
  i: integer;
  vSQLType: integer;
  SQLPar: TFIBXSQLVAR;
begin
  FOnlySrvParams.Clear;
  if not vDiffParams then
    Exit;
  for i := 0 to Pred(FUserSQLParams.Count) do
  begin
    SQLPar := FSQLParams.FindParam(FUserSQLParams[i].Name);
    if SQLPar = nil then
      Continue;
    vSQLType := SQLPar.FXSQLVAR^.SQLType and (not 1);
    if (vSQLType = SQL_TIMESTAMP) or (vSQLType = SQL_TYPE_DATE) then
      with FUserSQLParams[i] do
        case SQLType of
          SQL_DOUBLE, SQL_FLOAT, SQL_D_FLOAT, SQL_INT64: AsDateTime := AsFloat
        end;
  end;
  SLDifference(FSQLParams.FNames, FUserSQLParams.FNames, FOnlySrvParams)
end;

procedure TFIBQuery.Prepare;
var
  stmt_len: integer;
  res_buffer: array [0 .. 7] of AnsiChar;
  type_item: AnsiChar;
  i: integer;
  SV: PISC_STATUS;
  ParamsSQLDA: PXSQLDA;
  BlobValue: Ansistring;
  tmpVar: TFIBXSQLVAR;
  function NeedTransformUserSQL: boolean;
  var
    j, pc: integer;
    p: TFIBXSQLVAR;
  begin
    Result := not FPrepared or FMacroChanged or FNeedForceIsNull;
    if Result then
      Exit;
    if not FHaveMacros and (qoNoForceIsNull in Options) then
      Exit;
    pc := Pred(FUserSQLParams.Count);
    for j := 0 to pc do
    begin
      p := FUserSQLParams[j];

      if p.IsMacro then
        Result := p.Value <> p.FOldValue;
      // Macro value changed. Must change SQL text.
      if Result then
        Exit;
      Result := (p.FCanForceIsNull and (p.IsNull <> VarIsNull(p.FOldValue)));
      // May be change IS NULL
      if Result then
        Exit;
    end;
  end;

begin
  Include(FQueryRunState, qrsInPrepare);
  try
    if Open then
      Close;
    FBase.CheckDatabase;
{$IFDEF CSMonitor}
    if Pos('/* CSMON$', FParser.SQLText) <= 0 then
      FParser.SQLText := FParser.SQLText + GetCSMonText;
{$ENDIF}
    if qoStartTransaction in Options then
      if (Transaction <> nil) and not Transaction.InTransaction then
        Transaction.StartTransaction;
    FBase.CheckTransaction;
    BuildDeferredSQL;
    if (FDoParamCheck) and (Params.Count > 0) then
    begin
      if not vUserParamsCreated then
        SQLChange(nil);
      if NeedTransformUserSQL then
      begin
        PreprocessSQL(ReadySQLText, False);
        ConvertSQLTextToCodePage;
        FMacroChanged := False;
        // FNeedForceIsNull:=False;
        FNeedForceIsNull := not(qoNoForceIsNull in Options) and not(qrsInExecute in FQueryRunState);
        FreeHandle;
      end;
    end
    else
    begin

{$IFDEF CSMonitor}
      if Pos('/* CSMON$', FProcessedSQL) <= 0 then
        FProcessedSQL := FProcessedSQL + GetCSMonText;
{$ENDIF}
      ConvertSQLTextToCodePage;
    end;
    if FPrepared then
      Exit;
    FRelationAliasesRead := False;
    FParamNamesRead := False;
    if IsBlank(FProcessedSQL) then
      FIBError(feEmptyQuery, ['Prepare']);
    try
      SV := StatusVector;
      with Database.ClientLibrary do
      begin
        if (not Transaction.InTransaction) then
          Transaction.StartTransaction;
        Call(isc_dsql_alloc_statement2(SV, DBHandle, @FHandle), True);
        FSQLRecord.Count := 1;
        Call(isc_dsql_prepare(SV, TRHandle, @FHandle, 0, PAnsiChar(FPreparedSQL), Database.SQLDialect,
          FSQLRecord.FXSQLDA), True);

        (* After preparing the statement, query the stmt type and possibly
          create a FSQLRecord "holder" *)
        // Get the type of the statement
        type_item := AnsiChar(isc_info_sql_stmt_type);
        Call(isc_dsql_sql_info(SV, @FHandle, 1, @type_item, SizeOf(res_buffer), res_buffer), True);
        if (res_buffer[0] <> AnsiChar(isc_info_sql_stmt_type)) then
          FIBError(feUnknownError, [nil]);
        stmt_len := isc_vax_integer(@res_buffer[1], 2);
        FSQLType := TFIBSQLTypes(isc_vax_integer(@res_buffer[3], stmt_len));
        if FSQLType = SQLSelectForUpdate then
        begin
          if FCursorName = '' then
            FCursorName := RandomString(10);
          Call(isc_dsql_set_cursor_name(StatusVector, @FHandle, PAnsiChar(Ansistring(FCursorName)), 0), True);
        end;

        // Done getting the type
        case FSQLType of
          SQLGetSegment, SQLPutSegment, SQLStartTransaction:
            begin
              FreeHandle;
              FIBError(feNotPermitted, [nil]);
            end;
          SQLInsert, SQLUpdate, SQLDelete, SQLSelect, SQLSelectForUpdate, SQLExecProcedure:
            begin
              // We already know how many inputs there are, so...
              if vDiffParams then
                ParamsSQLDA := FSQLParams.FXSQLDA
              else
                ParamsSQLDA := FUserSQLParams.FXSQLDA;
              if (ParamsSQLDA <> nil) then
              begin
                if vDiffParams and FHaveMacros then // !!!
                  SaveRestoreValues(FSQLParams, True);
                if Call(isc_dsql_describe_bind(SV, @FHandle, Database.SQLDialect, FSQLParams.FXSQLDA), False) > 0 then
                  IBError(Database.ClientLibrary, Self)
                else
                begin
                  if (ParamsSQLDA = FUserSQLParams.FXSQLDA) then
                    for i := 0 to Pred(FUserSQLParams.Count) do
                    begin
                      tmpVar := FSQLParams.FXSQLVARs^[i];
                      with FUserSQLParams.FXSQLVARs^[i] do
                        if IsNull then
                        begin
                          FXSQLVAR^.SQLType := tmpVar.FXSQLVAR^.SQLType;
                          FXSQLVAR^.sqlscale := tmpVar.FXSQLVAR^.sqlscale;
                          FXSQLVAR^.sqllen := tmpVar.FXSQLVAR^.sqllen;
                          FXSQLVAR^.SQLSubtype := tmpVar.FXSQLVAR^.SQLSubtype;
                          FIBAlloc(FXSQLVAR^.sqldata, 0, FSQLParams[i].FXSQLVAR^.sqllen);
                          IsNull := True
                        end
                        else if (tmpVar.SQLType = SQL_ARRAY) and (SQLType = SQL_BLOB) then
                          // array ID set by AsQuad before the server type was known
                          FXSQLVAR^.SQLType := SQL_ARRAY or (FXSQLVAR^.SQLType and 1)
                        else if tmpVar.IsBlob and (not IsBlob or IsDefferedLongString) then
                        begin
                          FPrepared := True;

                          if (SQLType = SQL_TEXT) or IsBlob then
                          begin
                            if Length(FWideTempValue) > 0 then
                            begin
                              InternalSetAsString(@FWideTempValue, True, True)
                            end;
                            BlobValue := AsAnsiString
                          end
                          else
                            BlobValue := AsAnsiString;

                          FXSQLVAR^.SQLType := tmpVar.FXSQLVAR^.SQLType;
                          FXSQLVAR^.sqllen := tmpVar.FXSQLVAR^.sqllen;
                          ReallocMem(FXSQLVAR^.sqldata, tmpVar.FXSQLVAR^.sqllen);
                          FXSQLVAR^.SQLSubtype := tmpVar.FXSQLVAR^.SQLSubtype;
                          FSrvSQLType := tmpVar.SQLType;
                          tmpVar.FSrvSQLType := tmpVar.SQLType;
                          FSrvSQLSubType := tmpVar.SQLSubtype;
                          InternalSetAsString(@BlobValue, False, True)
                        end;
                    end;
                end;
              end;

              FSQLParams.Initialize;
              if vDiffParams and FHaveMacros then // !!!
              begin
                FPrepared := True;
                SaveRestoreValues(FSQLParams, False);
              end;
              if FSQLType in [SQLSelect, SQLSelectForUpdate, SQLExecProcedure] then
              begin
                if FSQLRecord.FXSQLDA^.sqld > FSQLRecord.FXSQLDA^.sqln then
                begin
                  FSQLRecord.Count := FSQLRecord.FXSQLDA^.sqld;
                  Call(isc_dsql_describe(SV, @FHandle, Database.SQLDialect, FSQLRecord.FXSQLDA), True);
                end
                else if FSQLRecord.FXSQLDA^.sqld = 0 then
                  FSQLRecord.Count := 0;
                FSQLRecord.Initialize;
              end
              else
                FSQLRecord.Count := 0;
              PrepareUserParamsTypes;
{$IFDEF SUPPORT_ARRAY_FIELD}
              PrepareArrayFields;
{$ENDIF}
            end;
        end;
        if FStatementTimeout <> 0 then
          ApplyStatementTimeout(FStatementTimeout);
        FPrepared := True;
{$IFNDEF NO_MONITOR}
        if MonitoringEnabled then
          if MonitorHook <> nil then
            MonitorHook.SQLPrepare(Self);
{$ENDIF}
        DoStatisticPrepare(FProcessedSQL);
        if Assigned(Database.SQLLogger) then
        begin
          Database.SQLLogger.WriteData(CmpFullName(Self), 'Prepare:', FProcessedSQL, lfQPrepare);
        end;
      end;
    except
      on E: Exception do
      begin
{$IFNDEF NO_MONITOR}
        if MonitoringEnabled then
          if MonitorHook <> nil then
            THackMonitorHook(MonitorHook).WriteSQLData(CmpFullName(Self) + ': [Prepare] ' + E.Message, tfQPrepare);
{$ENDIF}
        if Assigned(Database.SQLLogger) then
        begin
          Database.SQLLogger.WriteData(CmpFullName(Self), 'Error on Prepare:', FProcessedSQL, lfQPrepare);
        end;
        if (FHandle <> nil) then
          FreeHandle;
        raise;
      end;
    end;
  finally
    Exclude(FQueryRunState, qrsInPrepare);
  end;
end;

procedure TFIBQuery.SetSQL(Value: TStrings);
begin
  FSQL.Assign(Value);
end;

procedure TFIBQuery.SetMacroChar(Value: Char);
begin
  if Value = ' ' then
    FMacroChar := #0
  else
    FMacroChar := Value
end;

procedure TFIBQuery.SetTransaction(Value: TFIBTransaction);
begin
  FBase.Transaction := Value;
end;

function TFIBQuery.GetModifyTable: string;
begin
  if FModifyTable = '-1' then
  begin
    SQLChange(nil);
    FModifyTable := SqlTxtRtns.GetModifyTable(FParser.SQLText);
  end;
  Result := FModifyTable
end;

procedure TFIBQuery.SaveStreamedParams(toParams: TFIBXSQLDA);
var
  bs: TFIBBlobStream;
  i: integer;
begin
  if not FHaveStreamParams then
    Exit;

  bs := TFIBBlobStream.Create;
  try
    bs.Mode := bmWrite;
    for i := 0 to Pred(toParams.Count) do
      with toParams[i] do
        if FStreamValue <> nil then
        begin
          IsNull := False;
          bs.blobSubType := ServerSQLSubType;
          with FQuery do
          begin
            bs.Database := Database;
            bs.Transaction := Transaction;
            FStreamValue.Seek(0, soFromBeginning);
            bs.LoadFromStream(FStreamValue);
            if qoStartTransaction in Options then
              if (Transaction <> nil) and not Transaction.InTransaction then
                Transaction.StartTransaction;
          end;
          bs.Finalize;
          SetQuadValue(bs.BlobID);
          if toParams <> FUserSQLParams then
            FUserSQLParams.ByName[toParams[i].Name].SetQuadValue(AsQuad)
        end
  finally
    bs.Free;
  end;
end;

procedure TFIBQuery.ClearStreamedParams;
var
  i: integer;
begin
  if not FHaveStreamParams then
    Exit;

  for i := 0 to Pred(Params.Count) do
    with Params[i] do
      if FStreamValue <> nil then
      begin
        FreeAndNil(FStreamValue);
      end;

  for i := 0 to Pred(FUserSQLParams.Count) do
    with FUserSQLParams[i] do
      if FStreamValue <> nil then
      begin
        FreeAndNil(FStreamValue);
      end;

  FHaveStreamParams := False
end;

// the server only times DML
function TFIBQuery.TimeoutApplies: boolean;
begin
  Result := FSQLType in [SQLSelect, SQLSelectForUpdate, SQLInsert, SQLUpdate, SQLDelete, SQLExecProcedure];
end;

procedure TFIBQuery.ApplyStatementTimeout(Value: Cardinal);
begin
  if (FHandle = nil) or not TimeoutApplies then
    Exit;
  Database.RequireStatementTimeout(CmpPropPath(Self, 'StatementTimeout'), Value);
  if Database.Capabilities.StatementTimeout then
    Call(Database.ClientLibrary.fb_dsql_set_timeout(StatusVector, @FHandle, Value), True);
end;

procedure TFIBQuery.SetStatementTimeout(Value: Cardinal);
begin
  if FStatementTimeout = Value then
    Exit;
  if FPrepared then
    ApplyStatementTimeout(Value);
  FStatementTimeout := Value;
end;

procedure TFIBQuery.SetParamCheck(Value: boolean);
begin
  FDoParamCheck := Value;
  FParamCheck := Value;
  if not Value then
  begin
    FUserSQLParams.Count := 0;
    FSQLParams.Count := 0;
    FProcessedSQL := FSQL.Text;
    FreeHandle;
  end

end;

procedure TFIBQuery.SQLChange(Sender: TObject);
begin
  FHaveMacros := False;
  FParser.SQLText := FSQL.Text;
  if FCountLockSQL > 0 then
    Exit;
  Inc(FSQLTextChangeCount); // Internal Use
  FModifyTable := '-1';
  FDoParamCheck := ParamCheck;
  if not FDoParamCheck or (FSQL.Count = 0) or ParamsNotExist(FParser.SQLText) then
  begin
    FUserSQLParams.Count := 0;
    FSQLParams.Count := 0;
    FProcessedSQL := FParser.SQLText;
  end
  else
  begin
    // For register Params
    PreprocessSQL(FParser.SQLText, True);
    if FUserSQLParams.Count = 0 then
      FProcessedSQL := FParser.SQLText
    else
      FProcessedSQL := '';
  end;
  // set by ConvertSQLTextToCodePage
  FPreparedSQL := '';
  FreeHandle;
  vUserParamsCreated := True;
  FCodePageApplied := False;
end;

procedure TFIBQuery.SQLChanging(Sender: TObject);
begin
  Close;
  with Conditions do
    if State = [] then
    begin
      RestorePrimarySQL;
      PrimarySQL := ''
    end;
  if Assigned(OnSQLChanging) then
    OnSQLChanging(Self);
  if FHandle <> nil then
    FreeHandle;
  FMacroChanged := False;
end;

procedure TFIBQuery.DoTransactionEnding(Sender: TObject);
begin
  if Transaction.State in [tsDoRollback, tsDoCommit] then
    if FAutoCloseOnTransactionEnd then
      if (FOpen) then
        Close;
end;

/// / Routine work
procedure TFIBQuery.SetParamValues(const ParamValues: array of Variant);
var
  i: integer;
  pc: integer;
begin
  // Exec Query with ParamValues
  if High(ParamValues) < Pred(Params.Count) then
    pc := High(ParamValues)
  else
    pc := Pred(Params.Count);
  for i := Low(ParamValues) to pc do
    Params[i].AsVariant := ParamValues[i];
end;

procedure TFIBQuery.SetParamValues(const ParamNames: string; ParamValues: array of Variant);
var
  i: integer;
  pc: integer;
  curPar: TFIBXSQLVAR;

begin
  pc := WordCount(ParamNames, [';']) - 1;
  if pc <> High(ParamValues) then
    raise Exception.Create(Format(SFIBParamsCountNotEquelValuesCount,
      ['procedure ' + CmpFullName(Self) + '.SetParamValues']));
  for i := 0 to pc do
  begin
    curPar := ParamByName(ExtractWord(i + 1, ParamNames, [';']));
    curPar.AsVariant := ParamValues[i];
  end;
end;

function TFIBQuery.DefMacroValue(const MacroName: string): string;
begin
  Result := ParamByName(MacroName).DefMacroValue
end;

procedure TFIBQuery.ExecWP(const ParamValues: array of Variant);
begin
  // Exec Query with ParamValues
  SetParamValues(ParamValues);
  ExecQuery
end;

procedure TFIBQuery.ExecWP(const ParamNames: string; ParamValues: array of Variant);
begin
  SetParamValues(ParamNames, ParamValues);
  ExecQuery
end;

function TFIBQuery.FieldCount: integer;
begin
  if FSQLRecord <> nil then
    Result := FSQLRecord.Count
  else
    Result := 0;
end;

function TFIBQuery.FindParam(const aParamName: string): TFIBXSQLVAR;
begin
  Result := Params.ByName[aParamName];
end;

function TFIBQuery.ParamByName(const ParamName: string): TFIBXSQLVAR;
begin
  Result := Params.ByName[ParamName];
  if (Result = nil) and IsProc then
    Result := FieldByName(ParamName);
  if (Result = nil) then
    raise Exception.Create(Format(SFIBErrorParamNotExist, [ParamName, CmpFullName(Self)]));
end;

procedure TFIBQuery.ApplyMacro;
begin
  if csDesigning in ComponentState then
    Exit;
  Close;
  FreeHandle;
  PreprocessSQL(ReadySQLText, False);
  FMacroChanged := False;
  FNeedForceIsNull := False;
end;

procedure TFIBQuery.RestoreMacroDefaultValues;
var
  i: integer;
begin
  for i := 0 to Pred(Params.Count) do
    if Params[i].IsMacro then
    begin
      Params[i].AsWideString := Params[i].DefMacroValue
    end;
end;

function TFIBQuery.IsProc: boolean;
begin
  Result := FastUpperCase(FastCopy(TrimLeft(SQL.Text), 1, 8)) = ExecProcPrefix
end;

// Conditions;
procedure TFIBQuery.SetConditions(Value: TConditions);
begin
  FConditions.Assign(Value)
end;

procedure TFIBQuery.AddCondition(const Name, Condition: string; Enabled: boolean);
begin
  FConditions.AddCondition(Name, Condition, Enabled)
end;

function TFIBQuery.ParamCount: integer;
begin
  Result := Params.Count
end;

function TFIBQuery.ParamName(ParamIndex: integer): string;
begin
  Result := Params[ParamIndex].Name;
end;

function TFIBQuery.FieldName(FieldIndex: integer): string;
begin
  Result := FSQLRecord[FieldIndex].Name;
end;

function TFIBQuery.FieldsCount: integer;
begin
  Result := FieldCount
end;

function TFIBQuery.FieldExist(const FieldName: string; var FieldIndex: integer): boolean;
begin
  FieldIndex := GetFieldIndex(FieldName);
  Result := FieldIndex > -1
end;

function TFIBQuery.ParamExist(const ParamName: string; var ParamIndex: integer): boolean;
var
  Par: TFIBXSQLVAR;
begin
  Par := FindParam(ParamName);
  Result := Assigned(Par);
  if Result then
    ParamIndex := Par.FIndex
end;

function TFIBQuery.FieldValue(const FieldName: string; Old: boolean): Variant;
begin
  Result := FieldByName(FieldName).Value;
end;

function TFIBQuery.FieldValue(const FieldIndex: integer; Old: boolean): Variant;
begin
  Result := GetFields(FieldIndex).Value;
end;

function TFIBQuery.ParamValue(const ParamName: string): Variant;
begin
  Result := ParamByName(ParamName).Value;
end;

function TFIBQuery.ParamValue(const ParamIndex: integer): Variant;
begin
  Result := Params[ParamIndex].Value;
end;

function TFIBQuery.WhereClausesCount: integer;
begin
  Result := WhereCount(SQL.Text)
end;

procedure TFIBQuery.SetPlanClause(const Value: string);
begin
  SQL.Text := FParser.SetMainPlan(Value);
end;

function TFIBQuery.GetPlanClause: string;
begin
  Result := FParser.MainPlanClause;
end;

function TFIBQuery.GetWhereClause(Index: integer): string;
var
  StartPos, EndPos: integer;
begin
  Result := FParser.WhereClause(Index, StartPos, EndPos);
end;

procedure TFIBQuery.SetWhereClause(Index: integer; const WhereClauseTxt: string);
begin
  SQL.Text := FParser.SetWhereClause(Index, WhereClauseTxt);
end;

function TFIBQuery.GetOrderString: string;
begin
  Result := FParser.OrderClause;
end;

function TFIBQuery.GetGroupByString: string;
begin
  Result := FParser.GroupByClause
end;

procedure TFIBQuery.SetGroupByString(const GroupByTxt: string);
var
  CondApplied: boolean;
begin
  CondApplied := Conditions.Applied;
  Conditions.CancelApply;
  SQL.Text := FParser.SetGroupClause(GroupByTxt);
  if CondApplied then
    Conditions.Apply;
end;

function TFIBQuery.GetFieldsClause: string;
begin
  Result := FParser.GetFieldsClause
end;

procedure TFIBQuery.SetFieldsClause(const NewFields: string);
var
  CondApplied: boolean;
begin
  CondApplied := Conditions.Applied;
  Conditions.CancelApply;
  SQL.Text := FParser.SetFieldsClause(NewFields);
  if CondApplied then
    Conditions.Apply;
end;

procedure TFIBQuery.SetOrderString(const OrderTxt: string);
var
  CondApplied: boolean;
begin
  CondApplied := Conditions.Applied;
  Conditions.CancelApply;
  SQL.Text := FParser.SetOrderClause(OrderTxt);
  if CondApplied then
    Conditions.Apply;
end;

procedure TFIBQuery.SetParamValue(const ParamIndex: integer; aValue: Variant);
begin
  Params[ParamIndex].Value := aValue;
end;

function TFIBQuery.IEof: boolean;
begin
  Result := Eof
end;

procedure TFIBQuery.INext;
begin
  Next
end;

//
function TFIBQuery.GetSQLKind: TSQLKind;
begin
  Result := FParser.SQLKind
end;

procedure TFIBQuery.AssignProperties(Source: TFIBQuery);
begin
  CopyProps(Source, Self);
end;

{$IFDEF CSMonitor}

procedure TFIBQuery.SetMonitorSupport(Value: TCSMonitorSupport);
begin
  FCSMonitorSupport.Assign(Value)
end;

function TFIBQuery.GetCSMonText: string;
var
  bWasComment, bEnabled, bIncludeDSDesc: boolean;
  // db
  DB_pl: TFIBDatabase;
  sDB_pl_name: string;
  // tr
  Tr_pl: TFIBTransaction;
  sTr_pl_name: string;
  // tr
  sDs_pl_name: string;
begin
  Result := '';
  bWasComment := False;
  bIncludeDSDesc := FCSMonitorSupport.IncludeDatasetDescription;
  bEnabled := FCSMonitorSupport.Enabled = csmeEnabled;
  if FCSMonitorSupport.Enabled = csmeDisabled then
    Exit;
  DB_pl := GetDatabase;
  if (not Assigned(DB_pl)) then
    Exit;
  Tr_pl := GetTransaction;
  if (not Assigned(Tr_pl)) then
    Exit;
  if not bEnabled then
    bEnabled := (FCSMonitorSupport.Enabled = csmeTransactionDriven) and (Tr_pl.CSMonitorSupport.Enabled = csmeEnabled);
  if not bEnabled then
    bEnabled := (FCSMonitorSupport.Enabled = csmeDatabaseDriven) and (DB_pl.CSMonitorSupport.Enabled = csmeEnabled);
  if not bEnabled then
    bEnabled := (FCSMonitorSupport.Enabled = csmeTransactionDriven) and
      (Tr_pl.CSMonitorSupport.Enabled = csmeDatabaseDriven) and (DB_pl.CSMonitorSupport.Enabled = csmeEnabled);
  if not bEnabled then
    Exit;
  // db
  sDB_pl_name := '';
  if Assigned(DB_pl) then
  begin
    sDB_pl_name := DB_pl.Name;
    if IsEmptyStr(sDB_pl_name) then
      sDB_pl_name := 'DB_0x' + IntToHex(integer(DB_pl), 8);
    if Assigned(DB_pl.Owner) then
      sDB_pl_name := DB_pl.Owner.Name + '.' + sDB_pl_name;
  end;
  if sDB_pl_name <> '' then
  begin
    Result := '/* CSMON$CON_NAME=' + sDB_pl_name + '; ';
    bWasComment := True;
  end;
  // tr
  sTr_pl_name := '';
  if Assigned(Tr_pl) then
  begin
    sTr_pl_name := Tr_pl.Name;
    if IsEmptyStr(sTr_pl_name) then
      sTr_pl_name := 'Trans_0x' + IntToHex(integer(Tr_pl), 8);
    if Assigned(Tr_pl.Owner) then
      sTr_pl_name := Tr_pl.Owner.Name + '.' + sTr_pl_name;
  end;
  if sTr_pl_name <> '' then
  begin
    if not bWasComment then
      Result := Result + '/* ';
    Result := Result + 'CSMON$TR_NAME=' + sTr_pl_name + '; ';
    bWasComment := True;
  end;
  sDs_pl_name := Name;
  if IsEmptyStr(sDs_pl_name) then
    sDs_pl_name := 'Query_0x' + IntToHex(integer(Self), 8);
  if Assigned(Owner) then
    if Owner is TFIBDataSet then
    begin
      if Owner is TpFIBDataSet then
      begin
        if (not IsEmptyStr((Owner as TpFIBDataSet).Description)) and bIncludeDSDesc then
          sDs_pl_name := Owner.Name + ':[' + trim((Owner as TpFIBDataSet).Description) + '].' + sDs_pl_name
        else
          sDs_pl_name := Owner.Name + '.' + sDs_pl_name;
      end
      else
        sDs_pl_name := Owner.Name + '.' + sDs_pl_name;
      if Assigned(Owner.Owner) then
        sDs_pl_name := Owner.Owner.Name + '.' + sDs_pl_name;
    end
    else
      sDs_pl_name := Owner.Name + '.' + sDs_pl_name;
  if sDs_pl_name <> '' then
  begin
    if not bWasComment then
      Result := Result + '/* ';
    Result := Result + 'CSMON$ST_NAME=' + sDs_pl_name + '; ';
    bWasComment := True;
  end;
  if bWasComment then
    Result := Result + ' */';
  Result := ' ' + Result;
end;
{$ENDIF}

initialization

DisableEncodingSQLText := False;

finalization

//
end.
