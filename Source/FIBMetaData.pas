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

unit FIBMetaData;

interface

{$I FIB.inc}

uses
  Classes, SysUtils, ibase, DB,
  FIBDatabase, FIBQuery, FIBDataSet, FIBProps, StrUtil,
  FIBInterfaces, FIB, Variants;

const

  DefTerminator  = ';';
  ProcTerminator = '^';

type

  // Metadata Object Identifiers
  TDBObjectType = (
    otDomain,
    otTable,
    otView,
    otProcedure,
    otGenerator,
    otException,
    otUDF,
    otRole,
    otDBTrigger,
    otStoredFunctions,
    otPackage,
    otDatabase
  );
  TDBObjectTypes = set of TDBObjectType;

  // SubObjects
  TTableChildType = (
    soTableFields,
    soPrimaryKey,
    soForeignKey,
    soTableTriggers,
    soUniqueConstr,
    soIndex,
    soCheckConstr,
    soTableGrants
  );
  TTableChildTypes = set of TTableChildType;

  TViewChildType = (soViewFields, soViewTriggers, soViewGrants);
  TViewChildTypes = set of TViewChildType;

  TProcedureChild = (soProcFieldIn, soProcFieldOut, soProcGrants);
  TProcedureChilds = set of TProcedureChild;

  TUDFChild = (soUDFField);
  TUDFChilds = set of TUDFChild;

  TPackageChild = (soPackageProcedures, soPackageFunctions);

  TRoleChild = (soRoleGrants);

  TTriggerType = (ttBefore, ttAfter, ttON);
  TTriggerAction = (
    taInsert,
    taUpdate,
    taDelete,
    taConnect,
    taDisconnect,
    taTransactionStart,
    taTransactionCommit,
    taTransactionRollback
  );
  TTriggerActions = set of TTriggerAction;

  TIndexOrder = (IoDescending, IoAscending);
  TForeignKeyRule = (fkrRestrict, fkrCascade, fkrSetNull, fkrSetDefault);

  TFIBFieldType = (
    fftUnKnown,
    fftNumeric,
    fftChar,
    fftVarchar,
    fftCstring,
    fftSmallint,
    fftInteger,
    fftQuad,
    fftFloat,
    fftDoublePrecision,
    fftTimestamp,
    fftBlob,
    fftBlobId,
    fftDate,
    fftTime,
    fftInt64,
    fftBoolean,
    fftInt128,
    fftDecFloat,
    fftTimeTZ,
    fftTimestampTZ
  );

  TPrivilege = (
    goSelect,
    goInsert,
    goUpdate,
    goDelete,
    goReferences,
    goExecuteProc,
    goRole
  );
  TPrivileges = set of TPrivilege;

  TNotifyLoadMetaData = procedure(Sender: TObject; const Message: string; var Stop: boolean) of object;

  TDDLTextOption = (dtoUseCreateDB, dtoUseSetClientLib, dtoUseSetTerm, dtoDecodeDomains, dtoIncludeGrants,
    dtoIncludeComments);
  TDDLTextOptions = set of TDDLTextOption;

const
  DefObjects = [otDomain, otTable, otView, otProcedure, otGenerator,
    otException, otUDF, otRole, otDBTrigger];
  DefTableChilds = [soTableFields, soPrimaryKey, soForeignKey, soTableTriggers,
    soUniqueConstr, soIndex, soCheckConstr];
  DefViewChilds = [soViewFields, soViewTriggers];
  DefDDLTextOptions = [dtoUseCreateDB, dtoUseSetTerm, dtoIncludeComments];
  DefSchemaExtractDDLTextOptions = [dtoIncludeComments];

type
  TCustomMetaObject = class;
  TMetaObjectClass = class of TCustomMetaObject;

  TMetaDomain = class;
  TMetaTable = class;
  TMetaDataBase = class;

  TMetaDataItem = record
    Childs: TList;
    ClassID: TMetaObjectClass;
  end;

  TCustomMetaObject = class(TObject)
  private
    FName: string;
    FFormatName: string;
    FDescription: string;
    FOwner: TCustomMetaObject;
    FItems: array of TMetaDataItem;
    FItemsCount: Integer;
    FLoaded: boolean;
    function GetChildObject(const ClassIndex, Index: Integer): TCustomMetaObject;
    function GetChildObjectByName(const ClassIndex: Integer; const ObjectName: string): TCustomMetaObject;
    function GetChildsCount(const ClassIndex: Integer): Integer;
    procedure ClearChilds(const ClassIndex: Integer);
    function GetAsDDL: string;
    procedure AddClass(ClassID: TMetaObjectClass);

    function GenerateChildDDL(Stream: TStringStream; ChildType: Integer): Integer;
    procedure GenerateChildCommentDDL(Stream: TStringStream; ChildType: Integer);
    function GetAsObjectDDL: string;
    procedure SetName(const Value: string);
    function GetItems(const Index: Integer): TMetaDataItem;
    function GetMetaDataBase: TMetaDataBase;
  protected
    procedure LoadDescription(Query: TFIBQuery);
    procedure WriteCommentDDL(Stream: TStringStream; const Target, Text: string);
    procedure GenerateObjectDDL(Stream: TStringStream); virtual;
    // Keyword of COMMENT ON for the object; empty when it cannot have a comment
    function CommentKeyword: string; virtual;
    function CommentTarget: string; virtual;
    // COMMENT ON for the object and its sub-objects
    procedure GenerateCommentDDL(Stream: TStringStream); virtual;
    property MetaDataBase: TMetaDataBase read GetMetaDataBase;
  public
    constructor Create(AOwner: TCustomMetaObject; aName: string = ''); virtual;
    destructor Destroy; override;
    procedure Clear;
    class function ClassIndex: Integer; virtual;
    class function IsSubObject: boolean; virtual;

    procedure GenerateDDLText(Stream: TStringStream); virtual;
    property Name: string read FName write SetName;
    property Description: string read FDescription;
    property AsDDL: string read GetAsDDL;
    property AsObjectDDL: string read GetAsObjectDDL;
    property ItemsCount: Integer read FItemsCount;
    property Items[const Index: Integer]: TMetaDataItem read GetItems;
    property Parent: TCustomMetaObject read FOwner;
    property FormatName: string read FFormatName;
    property Loaded: boolean read FLoaded;
  end;

  (* GRANT{
    <privileges> ON [TABLE] {tablename | viewname}
    TO {<object> | <userlist> | GROUP UNIX_group}
    | EXECUTE ON PROCEDURE procname TO {<object> | <userlist>}
    | <role_granted> TO {PUBLIC | <role_grantee_list>}};
    <privileges> = {ALL [PRIVILEGES] | <privilege_list>}
    <privilege_list> = {
    SELECT
    | DELETE
    | INSERT
    | UPDATE [(col [, col ...])]
    | REFERENCES [(col [, col ...])]
    [, <privilege_list> ...]}}
    <object> = {
    PROCEDURE procname
    | TRIGGER trigname
    | VIEW viewname
    | PUBLIC
    [, <object> ...]}
    <userlist> = {
    [USER] username
    | rolename
    | Unix_user}
    [, <userlist> ...]
    [WITH GRANT OPTION]
    <role_granted> = rolename [, rolename ...]
  *)
  TCustomMetaGrant = class(TCustomMetaObject)
  private
    FObjectName: string;
    FPrivileges: array of TPrivileges;
    FFields: array of string;
    FWithGrantOption: array of boolean;
    FUserList: array of string;
    procedure SetSize(Size: Integer);
    function GetSize: Integer;
    procedure LoadFromDataBase(QGrants: TFIBQuery; const Name: string; Pack: boolean = True);
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
    property Count: Integer read GetSize;
  end;

  TMetaViewGrant = class(TCustomMetaGrant)
  public
    class function ClassIndex: Integer; override;
  end;

  TMetaTableGrant = class(TCustomMetaGrant)
  public
    class function ClassIndex: Integer; override;
  end;

  TMetaProcGrant = class(TCustomMetaGrant)
  public
    class function ClassIndex: Integer; override;
  end;

  TMetaRoleGrant = class(TCustomMetaGrant)
  public
    class function ClassIndex: Integer; override;
  end;

  TMetaGenerator = class(TCustomMetaObject)
  private
    FValue: Int64;
    procedure LoadFromDataBase(QName: TFIBQuery);
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
    function CommentKeyword: string; override;
  public
    class function ClassIndex: Integer; override;
    property Value: Int64 read FValue;
  end;

  TArrBounds = record
    LOWER_BOUND: Integer;
    UPPER_BOUND: Integer end;
    TFieldDimensions = array of TArrBounds;

    TCustomMetaField = class(TCustomMetaObject)private FScale: Word;
    FLength: Smallint;
    FPrecision: Smallint;
    FFieldType: TFIBFieldType;
    FCharSet: string;
    FSegmentLength: Smallint;
    FSubType: Smallint;
    FBytesPerCharacter: Smallint;
    FIsArray: boolean;
    FDimensions: TFieldDimensions;
    FIdentity: Integer;
    procedure LoadFromDataBase(QField, QCharset: TFIBQuery); virtual;
    property SegmentLength: Smallint read FSegmentLength;
    function GetShortFieldType: string;
    function GetDimensionStr: string;
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
  public
    class function IsSubObject: boolean; override;
    property Scale: Word read FScale;
    property Length: Smallint read FLength;
    property Precision: Smallint read FPrecision;
    property FieldType: TFIBFieldType read FFieldType;
    property CharSet: string read FCharSet;
    property SubType: Smallint read FSubType;
    property BytesPerCharacter: Smallint read FBytesPerCharacter;
    property ShortFieldType: string read GetShortFieldType;
  end;

  TMetaField = class(TCustomMetaField)
  private
    procedure LoadFromDataBase(QField, QCharset: TFIBQuery); override;
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
    function CommentKeyword: string; override;
    function CommentTarget: string; override;
  public
    class function ClassIndex: Integer; override;
    property SegmentLength;
  end;

  TMetaProcField = class(TMetaField)
  private
    FDomain: string;
    FMechanizm: Smallint;
    FUseDomain: boolean;
    FUseRelation: boolean;
    FRelationObject: string;
    FRelationField: string;
    FDefaultValue: string;
    procedure DoLoadFromQuery(QField, QCharset: TFIBQuery; CanUseParamDomain, CanUseProcParamRelation: boolean);
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
    function CommentKeyword: string; override;
  end;

  TMetaProcInField = class(TMetaProcField)
  public
    class function ClassIndex: Integer; override;
  end;

  TMetaProcOutField = class(TMetaProcField)
  public
    class function ClassIndex: Integer; override;
  end;

  TMetaTableField = class(TMetaField)
  private
    FDefaultValue: string;
    FNotNull: boolean;
    FDomain: Integer;
    FDomainName: string;
    FComputedSource: string;
    FValidationSource: string;
    procedure LoadFromDataBase(Q: TFIBQuery; C: TFIBQuery); override;
    function GetDomain: TMetaDomain;
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
  public
    class function ClassIndex: Integer; override;
    property DefaultValue: string read FDefaultValue;
    property NotNull: boolean read FNotNull;
    property Domain: TMetaDomain read GetDomain;
    property ComputedSource: string read FComputedSource;
  end;

  TMetaDomain = class(TMetaTableField)
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
    function CommentKeyword: string; override;
    function CommentTarget: string; override;
  public
    class function ClassIndex: Integer; override;
    class function IsSubObject: boolean; override;
  end;

  TMetaConstraint = class(TCustomMetaObject)
  private
    FFields: array of Integer;
    function GetFields(const Index: Integer): TMetaTableField;
    function GetFieldsCount: Integer;
  public
    class function IsSubObject: boolean; override;
    property Fields[const Index: Integer]: TMetaTableField read GetFields;
    property FieldsCount: Integer read GetFieldsCount;
  end;

  TMetaPrimaryKey = class(TMetaConstraint)
  private
    procedure LoadFromDataBase(Q: TFIBQuery);
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
  public
    class function ClassIndex: Integer; override;
  end;

  TMetaUniqueConstraint = class(TMetaConstraint)
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
  public
    class function ClassIndex: Integer; override;
  end;

  TMetaForeignKey = class(TMetaConstraint)
  private
    FForTable: Integer;
    FForFields: array of Integer;
    FOnDelete: TForeignKeyRule;
    FOnUpdate: TForeignKeyRule;
    function GetForFields(const Index: Integer): TMetaTableField;
    function GetForFieldsCount: Integer;
    function GetForTable: TMetaTable;
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
  public
    class function ClassIndex: Integer; override;
    property ForTable: TMetaTable read GetForTable;
    property ForFields[const Index: Integer]: TMetaTableField read GetForFields;
    property ForFieldsCount: Integer read GetForFieldsCount;
    property OnDelete: TForeignKeyRule read FOnDelete;
    property OnUpdate: TForeignKeyRule read FOnUpdate;
  end;

  TMetaCheckConstraint = class(TCustomMetaObject)
  private
    FConstraint: string;
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
  public
    class function ClassIndex: Integer; override;
    property Constraint: string read FConstraint;
  end;

  TMetaIndex = class(TMetaConstraint)
  private
    FUnique: boolean;
    FActive: boolean;
    FOrder: TIndexOrder;
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
    function CommentKeyword: string; override;
  public
    class function ClassIndex: Integer; override;
    property Unique: boolean read FUnique;
    property Active: boolean read FActive;
    property Order: TIndexOrder read FOrder;
  end;

  TCustomMetaTrigger = class(TCustomMetaObject)
  private
    FPrefix: TTriggerType;
    FSuffix: TTriggerActions;
    FPosition: Smallint;
    FActive: boolean;
    FSource: string;
    class function DecodePrefix(Value: Integer): TTriggerType;
    class function DecodeSuffixes(Value: Integer): TTriggerActions;
    procedure LoadFromDataBase(Q: TFIBQuery);
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
    procedure SaveFakeDDL(Stream: TStringStream); // For Views
    procedure SaveAlterDDL(Stream: TStringStream);
    function CommentKeyword: string; override;
  public
    class function IsSubObject: boolean; override;
    property Prefix: TTriggerType read FPrefix;
    property Suffix: TTriggerActions read FSuffix;
    property Position: Smallint read FPosition;
    property Active: boolean read FActive;
    property Source: string read FSource;
  end;

  TMetaTableTrigger = class(TCustomMetaTrigger)
  public
    class function ClassIndex: Integer; override;
  end;

  TMetaViewTrigger = class(TCustomMetaTrigger)
  public
    class function ClassIndex: Integer; override;
  end;

  TMetaDBTrigger = class(TCustomMetaTrigger)
  public
    class function ClassIndex: Integer; override;
    class function IsSubObject: boolean; override;
  end;

  TMetaTable = class(TCustomMetaObject)
  private
    FRelationType: Integer;
    function GetFields(const Index: Integer): TMetaTableField;
    function GetFieldsCount: Integer;
    procedure LoadFromDataBase(QNames, QFields: TFIBQuery; QCharset: TFIBQuery;
      QPrimary, QIndex, QForeign, QCheck, QTrigger: TFIBQuery;
      ChildTypes: TTableChildTypes);

    function FindFieldIndex(const Name: string): Integer;
    function GetUniques(const Index: Integer): TMetaUniqueConstraint;
    function GetUniquesCount: Integer;
    function GetPrimaryKey: TMetaPrimaryKey;
    function GetPrimaryKeyExist: boolean;
    function GetIndices(const Index: Integer): TMetaIndex;
    function GetIndicesCount: Integer;
    function GetForeign(const Index: Integer): TMetaForeignKey;
    function GetForeignCount: Integer;
    function GetChecks(const Index: Integer): TMetaCheckConstraint;
    function GetChecksCount: Integer;
    function GetTriggers(const Index: Integer): TCustomMetaTrigger;
    function GetTriggersCount: Integer;
    function GetGrants(const Index: Integer): TCustomMetaGrant;
    function GetGrantsCount: Integer;

  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
    function CommentKeyword: string; override;
    procedure GenerateCommentDDL(Stream: TStringStream); override;
  public
    constructor Create(AOwner: TCustomMetaObject; aName: string = ''); override;
    class function ClassIndex: Integer; override;

    function FindFieldName(const Name: string): TMetaTableField;
    procedure GenerateDDLText(Stream: TStringStream); override;

    property Fields[const Index: Integer]: TMetaTableField read GetFields;
    property FieldsCount: Integer read GetFieldsCount;

    property PrimaryKey: TMetaPrimaryKey read GetPrimaryKey;
    property PrimaryKeyExist: boolean read GetPrimaryKeyExist;

    property Uniques[const Index: Integer]: TMetaUniqueConstraint read GetUniques;
    property UniquesCount: Integer read GetUniquesCount;

    property Indices[const Index: Integer]: TMetaIndex read GetIndices;
    property IndicesCount: Integer read GetIndicesCount;

    property Foreign[const Index: Integer]: TMetaForeignKey read GetForeign;
    property ForeignCount: Integer read GetForeignCount;

    property Checks[const Index: Integer]: TMetaCheckConstraint read GetChecks;
    property ChecksCount: Integer read GetChecksCount;

    property Triggers[const Index: Integer]: TCustomMetaTrigger read GetTriggers;
    property TriggersCount: Integer read GetTriggersCount;
  end;

  TMetaView = class(TCustomMetaObject)
  private
    FSource: string;
    function GetFields(const Index: Integer): TMetaField;
    function GetFieldsCount: Integer;
    function GetTriggers(const Index: Integer): TCustomMetaTrigger;
    function GetTriggersCount: Integer;
    function GetGrants(const Index: Integer): TCustomMetaGrant;
    function GetGrantsCount: Integer;

    procedure LoadFromDataBase(QName, QFields, QTriggers: TFIBQuery; QCharset: TFIBQuery; ChildTypes: TViewChildTypes);

  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
    function CommentKeyword: string; override;
    procedure GenerateCommentDDL(Stream: TStringStream); override;
  public
    constructor Create(AOwner: TCustomMetaObject; aName: string = ''); override;
    class function ClassIndex: Integer; override;
    procedure GenerateDDLText(Stream: TStringStream); override;
    property Source: string read FSource;
    property Fields[const Index: Integer]: TMetaField read GetFields;
    property FieldsCount: Integer read GetFieldsCount;
    property Triggers[const Index: Integer]: TCustomMetaTrigger read GetTriggers;
    property TriggersCount: Integer read GetTriggersCount;
  end;

  TMetaProcedure = class(TCustomMetaObject)
  private
    FSource: string;
    FPackageName: string;
    procedure LoadFromDataBase(QNames, QFields: TFIBQuery; QCharset: TFIBQuery; CanUseParamDomain, CanUseProcParamRelation: boolean);
    function GetInputFields(const Index: Integer): TMetaProcInField;
    function GetInputFieldsCount: Integer;
    function GetOutputFields(const Index: Integer): TMetaProcOutField;
    function GetOutputFieldsCount: Integer;
    function GetGrants(const Index: Integer): TCustomMetaGrant;
    function GetGrantsCount: Integer;

    procedure InternalSaveToDDL(Stream: TStringStream; Operation: string);
    procedure SaveToPostDDL(Stream: TStringStream);
    procedure SaveToAlterDDL(Stream: TStringStream);
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
    function CommentKeyword: string; override;
    function CommentTarget: string; override;
    procedure GenerateCommentDDL(Stream: TStringStream); override;

  public
    constructor Create(AOwner: TCustomMetaObject; aName: string = ''); override;
    class function ClassIndex: Integer; override;
    property Source: string read FSource;
    property InputFields[const Index: Integer]: TMetaProcInField read GetInputFields;
    property InputFieldsCount: Integer read GetInputFieldsCount;

    property OutputFields[const Index: Integer]: TMetaProcOutField read GetOutputFields;
    property OutputFieldsCount: Integer read GetOutputFieldsCount;
    property PackageName: string read FPackageName;
  end;

  TMetaStoredFunc = class(TCustomMetaObject)
  private
    FPackageName: string;
    FSource: string;
    function GetInputFields(const Index: Integer): TMetaProcInField;
    function GetInputFieldsCount: Integer;

    procedure LoadFromDataBase(QNames, QReturn, QInputs, QCharset: TFIBQuery);
    procedure InternalSaveToDDL(Stream: TStringStream; Operation: string);
    function GetReturn: TMetaProcOutField;
  protected
    procedure SaveEmptyDDL(Stream: TStringStream);
    procedure SaveAlterDDL(Stream: TStringStream);
    procedure GenerateObjectDDL(Stream: TStringStream); override;
    function CommentKeyword: string; override;
    function CommentTarget: string; override;
    procedure GenerateCommentDDL(Stream: TStringStream); override;
  public
    constructor Create(AOwner: TCustomMetaObject; aName: string = ''); override;
    class function ClassIndex: Integer; override;
    property Source: string read FSource;
    property InputFields[const Index: Integer]: TMetaProcInField read GetInputFields;
    property InputFieldsCount: Integer read GetInputFieldsCount;
    property PackageName: string read FPackageName;
    property Return: TMetaProcOutField read GetReturn;
  end;

  // Routines of a package: their DDL is the package source, AsDDL has only their comments
  TMetaPackageProcedure = class(TMetaProcedure)
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
  public
    class function ClassIndex: Integer; override;
    class function IsSubObject: boolean; override;
    procedure GenerateDDLText(Stream: TStringStream); override;
  end;

  TMetaPackageFunction = class(TMetaStoredFunc)
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
  public
    class function ClassIndex: Integer; override;
    class function IsSubObject: boolean; override;
    procedure GenerateDDLText(Stream: TStringStream); override;
  end;

  TMetaPackage = class(TCustomMetaObject)
  private
    FSpec: string;
    FBody: string;
    procedure LoadFromDataBase(QNames, QCharset: TFIBQuery);
    procedure SaveSpecDDL(Stream: TStringStream);
    procedure SaveBodyDDL(Stream: TStringStream);
    function GetProcedures(const Index: Integer): TMetaPackageProcedure;
    function GetProceduresCount: Integer;
    function GetFunctions(const Index: Integer): TMetaPackageFunction;
    function GetFunctionsCount: Integer;
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
    function CommentKeyword: string; override;
    procedure GenerateCommentDDL(Stream: TStringStream); override;
  public
    constructor Create(AOwner: TCustomMetaObject; aName: string = ''); override;
    class function ClassIndex: Integer; override;
    property SpecSource: string read FSpec;
    property BodySource: string read FBody;
    property Procedures[const Index: Integer]: TMetaPackageProcedure read GetProcedures;
    property ProceduresCount: Integer read GetProceduresCount;
    property Functions[const Index: Integer]: TMetaPackageFunction read GetFunctions;
    property FunctionsCount: Integer read GetFunctionsCount;
  end;

  TMetaException = class(TCustomMetaObject)
  private
    FMessage: string;
    FNumber: Integer;
    procedure LoadFromDataBase(QName: TFIBQuery);
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
    function CommentKeyword: string; override;
  public
    class function ClassIndex: Integer; override;
    property Message: string read FMessage;
    property Number: Integer read FNumber;
  end;

  TMetaUDFField = class(TCustomMetaField)
  private
    FPosition: Smallint;
    FMechanism: Smallint;
    procedure LoadFromDataBase(QField, QCharset: TFIBQuery); override;
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
  public
    class function ClassIndex: Integer; override;
    property Position: Smallint read FPosition;
    property Mechanism: Smallint read FMechanism;
  end;

  TMetaUDF = class(TCustomMetaObject)
  private
    FModule: string;
    FEntry: string;
    FReturn: Smallint;
    procedure LoadFromDataBase(QNames, QFields: TFIBQuery; QCharset: TFIBQuery);
    function GetFields(const Index: Integer): TMetaUDFField;
    function GetFieldsCount: Integer;
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
    function CommentKeyword: string; override;
  public
    constructor Create(AOwner: TCustomMetaObject; aName: string = ''); override;
    class function ClassIndex: Integer; override;
    property Module: string read FModule;
    property Entry: string read FEntry;
    property Return: Smallint read FReturn;
    property Fields[const Index: Integer]: TMetaUDFField read GetFields;
    property FieldsCount: Integer read GetFieldsCount;
  end;

  TMetaRole = class(TCustomMetaObject)
  private
    FOwner: string;
  protected
    procedure LoadFromDataBase(QName: TFIBQuery);
    procedure GenerateObjectDDL(Stream: TStringStream); override;
    function CommentKeyword: string; override;
    function GetGrants(const Index: Integer): TCustomMetaGrant;
    function GetGrantsCount: Integer;

  public
    constructor Create(AOwner: TCustomMetaObject; aName: string = ''); override;
    class function ClassIndex: Integer; override;
    property Owner: string read FOwner;
  end;

  TMetaDataBase = class(TCustomMetaObject)
  private
    FInternalTransaction: TFIBTransaction;
  private
    // DBInfo

    FPageSize: Integer;
    FDefaultCharset: string;
    FConnectCharset: string;
    FClientLib: string;

    FProcParamDomainSupports: boolean;
    FProcParamRelationSupports: boolean;
    FIdentityFieldsSupports: boolean;
    FStoredFunctionsSupports: boolean;
    FPackagesSupports: boolean;
    FTabRelTypeSupports: boolean;
    FCommentsSupports: boolean;
    // Of the SQL text, for the byte length of a COMMENT ON
    FCodePage: Word;

    FSQLDialect: Integer;
    //
    FLoadObjects: TDBObjectTypes;
    FLoadTableChilds: TTableChildTypes;
    FLoadViewChilds: TViewChildTypes;
    FSysInfos: boolean;

    // Flags
    FNamesLoaded: boolean;
    FDDLTextOptions: TDDLTextOptions;
    FOnLoadMetaData: TNotifyLoadMetaData;

    function GetGenerators(const Index: Integer): TMetaGenerator;
    function GetGeneratorsCount: Integer;
    function GetTables(const Index: Integer): TMetaTable;
    function GetTablesCount: Integer;
    function FindTableIndex(const TableName: string): Integer;
    function FindDomainIndex(const DomainName: string): Integer;
    function GetViews(const Index: Integer): TMetaView;
    function GetViewsCount: Integer;
    function GetDomains(const Index: Integer): TMetaDomain;
    function GetDomainsCount: Integer;
    function GetProcedures(const Index: Integer): TMetaProcedure;
    function GetProceduresCount: Integer;
    function GetFunctionsCount: Integer;
    function GetFunctions(const Index: Integer): TMetaStoredFunc;

    function GetExceptions(const Index: Integer): TMetaException;
    function GetExceptionsCount: Integer;
    function GetUDFS(const Index: Integer): TMetaUDF;
    function GetUDFSCount: Integer;
    function GetRoles(const Index: Integer): TMetaRole;
    function GetRolesCount: Integer;
    function GetPackageCount: Integer;
    function GetPackages(const Index: Integer): TMetaPackage;
    procedure DetectServerFeatures;
    procedure SetOptionalColumns(Query: TFIBQuery; ObjectType: TDBObjectType);
    function ProcFieldsSQL: string;
    function UDFFieldsSQL: string;
    function CommentsIncluded(Options: TDDLTextOptions): boolean;
    function CommentFits(const Statement, Text: string): boolean;
  public
    constructor Create(AOwner: TCustomMetaObject; aName: string = ''); override;
    destructor Destroy; override;
    class function ClassIndex: Integer; override;

    procedure Clear;
    procedure LoadFromDataBase(DB: TFIBDatabase; OnlyNames: boolean = False);

    procedure GenerateDDLText(Stream: TStringStream); override;
    procedure ExtGenerateDDLText(Stream: TStringStream; Options: TDDLTextOptions = DefDDLTextOptions);

    function GetDBObject(DB: TFIBDatabase; ObjectType: TDBObjectType;
      const ObjectName: string; ForceLoad: boolean = True): TCustomMetaObject;

    property Generators[const Index: Integer]: TMetaGenerator read GetGenerators;
    property GeneratorsCount: Integer read GetGeneratorsCount;

    property Tables[const Index: Integer]: TMetaTable read GetTables;
    property TablesCount: Integer read GetTablesCount;

    property Packages[const Index: Integer]: TMetaPackage read GetPackages;
    property PackageCount: Integer read GetPackageCount;

    property Views[const Index: Integer]: TMetaView read GetViews;
    property ViewsCount: Integer read GetViewsCount;

    property Domains[const Index: Integer]: TMetaDomain read GetDomains;
    property DomainsCount: Integer read GetDomainsCount;

    property Procedures[const Index: Integer]: TMetaProcedure read GetProcedures;
    property ProceduresCount: Integer read GetProceduresCount;

    property Exceptions[const Index: Integer]: TMetaException read GetExceptions;
    property ExceptionsCount: Integer read GetExceptionsCount;

    property UDFS[const Index: Integer]: TMetaUDF read GetUDFS;
    property UDFSCount: Integer read GetUDFSCount;

    property Roles[const Index: Integer]: TMetaRole read GetRoles;
    property RolesCount: Integer read GetRolesCount;

    property SysInfo: boolean read FSysInfos write FSysInfos;
    property ViewInfo: TViewChildTypes read FLoadViewChilds write FLoadViewChilds default DefViewChilds;
    property DBObjects: TDBObjectTypes read FLoadObjects write FLoadObjects default DefObjects;
    property TableInfo: TTableChildTypes read FLoadTableChilds write FLoadTableChilds default DefTableChilds;

    property DDLTextOptions: TDDLTextOptions read FDDLTextOptions write FDDLTextOptions;
    property OnLoadMetaData: TNotifyLoadMetaData read FOnLoadMetaData write FOnLoadMetaData;
  end;

  TFIBDBSchemaExtract = class;

  TLoadOptions = class(TPersistent)
  private
    FLoadObjects: TDBObjectTypes;
    FLoadTableChilds: TTableChildTypes;
    FLoadViewChilds: TViewChildTypes;
    FIncSysInfo: boolean;
  public
    constructor Create;
  published
    property SysInfo: boolean read FIncSysInfo write FIncSysInfo default False;
    property ViewInfo: TViewChildTypes read FLoadViewChilds write FLoadViewChilds default DefViewChilds;
    property DBObjects: TDBObjectTypes read FLoadObjects write FLoadObjects default DefObjects;
    property TableInfo: TTableChildTypes read FLoadTableChilds write FLoadTableChilds default DefTableChilds;
  end;

  TFIBDBSchemaExtract = class(TComponent)

  protected
    FDatabase: TFIBDatabase;
    FOnLoadMetaData: TNotifyLoadMetaData;
    FLoadOptions: TLoadOptions;
    FMetaDatabase: TMetaDataBase;
    FFullLoaded: boolean;
  protected
    function GetDomains(const Index: Integer): TMetaDomain;
    function GetDomainsCount: Integer;
    function GetExceptions(const Index: Integer): TMetaException;
    function GetExceptionsCount: Integer;
    function GetGenerators(const Index: Integer): TMetaGenerator;
    function GetGeneratorsCount: Integer;
    function GetProcedures(const Index: Integer): TMetaProcedure;
    function GetProceduresCount: Integer;
    function GetFunctions(const Index: Integer): TMetaStoredFunc;
    function GetFunctionsCount: Integer;

    function GetTables(const Index: Integer): TMetaTable;
    function GetTablesCount: Integer;
    function GetUDFS(const Index: Integer): TMetaUDF;
    function GetUDFSCount: Integer;
    function GetViews(const Index: Integer): TMetaView;
    function GetViewsCount: Integer;
    procedure SetDatabase(const Value: TFIBDatabase);
    procedure SetLoadOptions(const Value: TLoadOptions);
    function GetNamesLoaded: boolean;
  private
    function GetPackageCount: Integer;
    function GetPackages(const Index: Integer): TMetaPackage;
    function GetDDLTextOptions: TDDLTextOptions;
    procedure SetDDLTextOptions(const Value: TDDLTextOptions);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure DoOnLoadMetaData(Sender: TObject; const Message: string; var Stop: boolean);
  published
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure LoadMetaData(OnlyNames: boolean = False);
    procedure LoadObjectNames;
    function GetDDLText: string;
    function GetMetaDataBase: TMetaDataBase;

    procedure Clear;

    function ObjectByName(ObjectType: TDBObjectType; const ObjectName: string; ForceLoad: boolean = True): TCustomMetaObject;
    function GetObjectDDL(ObjectType: TDBObjectType; const ObjectName: string; ForceLoad: boolean = True): string;

    property Generators[const Index: Integer]: TMetaGenerator read GetGenerators;
    property GeneratorsCount: Integer read GetGeneratorsCount;

    property Tables[const Index: Integer]: TMetaTable read GetTables;
    property TablesCount: Integer read GetTablesCount;

    property Packages[const Index: Integer]: TMetaPackage read GetPackages;
    property PackagesCount: Integer read GetPackageCount;

    property Views[const Index: Integer]: TMetaView read GetViews;
    property ViewsCount: Integer read GetViewsCount;

    property Domains[const Index: Integer]: TMetaDomain read GetDomains;
    property DomainsCount: Integer read GetDomainsCount;

    property Procedures[const Index: Integer]: TMetaProcedure read GetProcedures;
    property ProceduresCount: Integer read GetProceduresCount;

    property Functions[const Index: Integer]: TMetaStoredFunc read GetFunctions;
    property FunctionsCount: Integer read GetFunctionsCount;

    property Exceptions[const Index: Integer]: TMetaException read GetExceptions;
    property ExceptionsCount: Integer read GetExceptionsCount;

    property UDFS[const Index: Integer]: TMetaUDF read GetUDFS;
    property UDFSCount: Integer read GetUDFSCount;
    property MetaDataLoaded: boolean read FFullLoaded;
    property NamesLoaded: boolean read GetNamesLoaded;
  published
    property Database: TFIBDatabase read FDatabase write SetDatabase;
    property DDLTextOptions: TDDLTextOptions read GetDDLTextOptions write SetDDLTextOptions
      default DefSchemaExtractDDLTextOptions;
    property LoadOptions: TLoadOptions read FLoadOptions write SetLoadOptions;
    property OnLoadMetaData: TNotifyLoadMetaData read FOnLoadMetaData write FOnLoadMetaData;
  end;

procedure FullExtractDDL(DB: TFIBDatabase; Dest: TStrings);

implementation

uses
  StdFuncs, FIBCharSets, FIBPlatforms;

procedure FullExtractDDL(DB: TFIBDatabase; Dest: TStrings);
var
  Extractor: TMetaDataBase;
begin
  Extractor := TMetaDataBase.Create(nil, '');
  try
    Extractor.LoadFromDataBase(DB);
    Dest.Text := Extractor.AsDDL
  finally
    Extractor.Free;
  end;
end;

function CutDefaultValue(const Source: string): string;
begin
  Result := Trim(Source);
  if Result <> '' then
    Result := Copy(Result, 9, System.Length(Result) - 8);
end;

// Name of a routine, with its package if any
function RoutineName(const PackageName, FormatName: string): string;
begin
  if PackageName = '' then
    Result := FormatName
  else
    Result := FormatIdentifier(3, PackageName) + '.' + FormatName;
end;

function CreateQuery(const SQLText: string; Transaction: TFIBTransaction): TFIBQuery;
begin
  Result := TFIBQuery.Create(nil);
  try
    Result.Database := Transaction.MainDatabase;
    Result.Transaction := Transaction;
    Result.Options := [qoTrimCharFields, qoNoForceIsNull, qoStartTransaction];
    Result.SQL.Text := SQLText;
  except
    Result.Free;
    raise;
  end;
end;

function SavedMetaObjectName(const MetaObjectName: string): string;
begin
  if (Length(MetaObjectName) > 0) and (MetaObjectName[1] = '"') then
    Result := FastCopy(MetaObjectName, 2, Length(MetaObjectName) - 2)
  else
    Result := MetaObjectName
end;

const
  TriggerPrefixes: array [TTriggerType] of string = ('BEFORE', 'AFTER', 'ON');

  TriggerSuffixes: array [TTriggerAction] of string = (
    'INSERT',
    'UPDATE',
    'DELETE',
    'CONNECT',
    'DISCONNECT',
    'TRANSACTION START',
    'TRANSACTION COMMIT',
    'TRANSACTION ROLLBACK'
  );

  FieldTypes: array [TFIBFieldType] of string = (
    '',
    'NUMERIC',
    'CHAR',
    'VARCHAR',
    'CSTRING',
    'SMALLINT',
    'INTEGER',
    'QUAD',
    'FLOAT',
    'DOUBLE PRECISION',
    'TIMESTAMP',
    'BLOB',
    'BLOBID',
    'DATE',
    'TIME',
    'BIGINT',
    'BOOLEAN',
    'INT128',
    'DECFLOAT',
    'TIME WITH TIME ZONE',
    'TIMESTAMP WITH TIME ZONE'
  );

  QRYDB_INFO = 'SELECT RDB$CHARACTER_SET_NAME, RDB$DESCRIPTION FROM RDB$DATABASE';

  // One row: 1 when the system column of a feature exists, else 0
  QRY_SERVER_FEATURES = 'SELECT ' +
    '(SELECT COUNT(*) FROM RDB$RELATION_FIELDS WHERE RDB$RELATION_NAME = ''RDB$FUNCTIONS'' AND ' +
    'RDB$FIELD_NAME = ''RDB$FUNCTION_SOURCE'') AS STORED_FUNCTIONS, ' +
    '(SELECT COUNT(*) FROM RDB$RELATION_FIELDS WHERE RDB$RELATION_NAME = ''RDB$PACKAGES'' AND ' +
    'RDB$FIELD_NAME = ''RDB$PACKAGE_NAME'') AS PACKAGES, ' +
    '(SELECT COUNT(*) FROM RDB$RELATION_FIELDS WHERE RDB$RELATION_NAME = ''RDB$RELATION_FIELDS'' AND ' +
    'RDB$FIELD_NAME = ''RDB$IDENTITY_TYPE'') AS IDENTITY_FIELDS, ' +
    '(SELECT COUNT(*) FROM RDB$RELATION_FIELDS WHERE RDB$RELATION_NAME = ''RDB$RELATIONS'' AND ' +
    'RDB$FIELD_NAME = ''RDB$RELATION_TYPE'') AS RELATION_TYPE, ' +
    '(SELECT COUNT(*) FROM RDB$RELATION_FIELDS WHERE RDB$RELATION_NAME = ''RDB$PROCEDURE_PARAMETERS'' AND ' +
    'RDB$FIELD_NAME = ''RDB$PARAMETER_MECHANISM'') AS PARAM_DOMAINS, ' +
    '(SELECT COUNT(*) FROM RDB$RELATION_FIELDS WHERE RDB$RELATION_NAME = ''RDB$PROCEDURE_PARAMETERS'' AND ' +
    'RDB$FIELD_NAME = ''RDB$RELATION_NAME'') AS PARAM_RELATIONS, ' +
    // COMMENT ON came with Firebird 2.0, as the descriptions of generators and roles
    '(SELECT COUNT(*) FROM RDB$RELATION_FIELDS WHERE RDB$RELATION_NAME = ''RDB$GENERATORS'' AND ' +
    'RDB$FIELD_NAME = ''RDB$DESCRIPTION'') AS COMMENTS ' +
    'FROM RDB$DATABASE';

  // Optional columns, filled by the server features
  DescriptionMacro = '@@DESCRIPTION@';
  DescriptionColumn = ', RDB$DESCRIPTION';
  PackageNameMacro = '@@PACK_NAME@';
  PackageNameColumn = ', RDB$PACKAGE_NAME';

  // FB3^^^^
  QRYGenerators = 'SELECT RDB$GENERATOR_NAME ' + DescriptionMacro + ' FROM RDB$GENERATORS GEN WHERE ' +
    '(NOT GEN.RDB$GENERATOR_NAME STARTING WITH ''RDB$'') AND ' +
    '(NOT GEN.RDB$GENERATOR_NAME STARTING WITH ''SQL$'') AND ' +
    '((GEN.RDB$SYSTEM_FLAG IS NULL) OR (GEN.RDB$SYSTEM_FLAG <> 1)) ' +
    'ORDER BY GEN.RDB$GENERATOR_NAME';

  QRYTables = 'SELECT REL.RDB$RELATION_NAME, REL.RDB$DESCRIPTION FROM RDB$RELATIONS REL WHERE ' +
    '(REL.RDB$SYSTEM_FLAG <> 1 OR REL.RDB$SYSTEM_FLAG IS NULL) AND ' +
    '(NOT REL.RDB$FLAGS IS NULL) AND ' + '(REL.RDB$VIEW_BLR IS NULL) AND ' +
    '(REL.RDB$SECURITY_CLASS STARTING WITH ''SQL$'') ' +
    'ORDER BY REL.RDB$RELATION_NAME';

  QRYTablesRel = 'SELECT REL.RDB$RELATION_NAME, REL.RDB$RELATION_TYPE, REL.RDB$DESCRIPTION FROM RDB$RELATIONS REL WHERE ' +
    '(REL.RDB$SYSTEM_FLAG <> 1 OR REL.RDB$SYSTEM_FLAG IS NULL) AND ' +
    '(NOT REL.RDB$FLAGS IS NULL) AND ' +
    '(REL.RDB$VIEW_BLR IS NULL) AND ' +
    '(REL.RDB$SECURITY_CLASS STARTING WITH ''SQL$'') ' +
    'ORDER BY REL.RDB$RELATION_NAME';

  QRYSysTables = 'SELECT REL.RDB$RELATION_NAME, REL.RDB$DESCRIPTION FROM RDB$RELATIONS REL ' +
    'WHERE REL.RDB$VIEW_BLR IS NULL ORDER BY REL.RDB$RELATION_NAME';

  QRYSysTablesRel = 'SELECT REL.RDB$RELATION_NAME, REL.RDB$RELATION_TYPE, REL.RDB$DESCRIPTION FROM RDB$RELATIONS REL ' +
    'WHERE REL.RDB$VIEW_BLR IS NULL ORDER BY REL.RDB$RELATION_NAME';

  QRYTableFields = 'SELECT FLD.RDB$FIELD_TYPE, FLD.RDB$FIELD_SCALE, ' +
    'FLD.RDB$FIELD_LENGTH, FLD.RDB$FIELD_PRECISION, ' +
    'FLD.RDB$CHARACTER_SET_ID, FLD.RDB$FIELD_SUB_TYPE, RFR.RDB$FIELD_NAME, ' +
    'FLD.RDB$SEGMENT_LENGTH, RFR.RDB$NULL_FLAG, RFR.RDB$DEFAULT_SOURCE, ' +
    'RFR.RDB$FIELD_SOURCE , FLD.RDB$COMPUTED_SOURCE, ' +
    '(Select Count(*) from  RDB$FIELD_DIMENSIONS  DIM where   DIM.rdb$field_name= RFR.RDB$FIELD_SOURCE)    is_Array, RFR.RDB$DESCRIPTION ' +
    'FROM RDB$RELATIONS REL, RDB$RELATION_FIELDS RFR, RDB$FIELDS FLD ' +
    'WHERE (RFR.RDB$FIELD_SOURCE = FLD.RDB$FIELD_NAME) AND ' +
    '(RFR.RDB$RELATION_NAME = REL.RDB$RELATION_NAME) AND ' +
    '(REL.RDB$RELATION_NAME = ?RN) ' +
    'ORDER BY RFR.RDB$FIELD_POSITION, RFR.RDB$FIELD_NAME';

  QRYTableFieldsFB3 = 'SELECT FLD.RDB$FIELD_TYPE, FLD.RDB$FIELD_SCALE, ' +
    'FLD.RDB$FIELD_LENGTH, FLD.RDB$FIELD_PRECISION, ' +
    'FLD.RDB$CHARACTER_SET_ID, FLD.RDB$FIELD_SUB_TYPE, RFR.RDB$FIELD_NAME, ' +
    'FLD.RDB$SEGMENT_LENGTH, RFR.RDB$NULL_FLAG, RFR.RDB$DEFAULT_SOURCE, ' +
    'RFR.RDB$FIELD_SOURCE , FLD.RDB$COMPUTED_SOURCE, ' +
    '(Select Count(*) from  RDB$FIELD_DIMENSIONS  DIM where   DIM.rdb$field_name= RFR.RDB$FIELD_SOURCE)    is_Array, ' +
    'RFR.RDB$IDENTITY_TYPE, RFR.RDB$DESCRIPTION ' +
    'FROM RDB$RELATIONS REL, RDB$RELATION_FIELDS RFR, RDB$FIELDS FLD ' +
    'WHERE (RFR.RDB$FIELD_SOURCE = FLD.RDB$FIELD_NAME) AND ' +
    '(RFR.RDB$RELATION_NAME = REL.RDB$RELATION_NAME) AND ' +
    '(REL.RDB$RELATION_NAME = ?RN) ' +
    'ORDER BY RFR.RDB$FIELD_POSITION, RFR.RDB$FIELD_NAME';

  QRYFieldDimensions = 'SELECT  RDB$DIMENSION, RDB$LOWER_BOUND, RDB$UPPER_BOUND ' +
    'FROM RDB$FIELD_DIMENSIONS ' +
    'WHERE      RDB$FIELD_NAME=:FN   ' +
    'ORDER BY 1 ';

  QRYCharset = 'SELECT RDB$CHARACTER_SET_ID, RDB$CHARACTER_SET_NAME, RDB$BYTES_PER_CHARACTER, ' +
    '(SELECT CH.RDB$CHARACTER_SET_ID FROM RDB$DATABASE DB ' +
    'JOIN RDB$CHARACTER_SETS CH ON CH.RDB$CHARACTER_SET_NAME=DB.RDB$CHARACTER_SET_NAME) DBCharSet ' +
    'FROM RDB$CHARACTER_SETS ' +
    'WHERE RDB$CHARACTER_SET_ID=?CH_ID';
  QRYUnique = 'SELECT RC.RDB$CONSTRAINT_NAME, IDX.RDB$FIELD_NAME ' +
    'FROM RDB$RELATION_CONSTRAINTS RC, RDB$INDEX_SEGMENTS IDX ' +
    'WHERE (IDX.RDB$INDEX_NAME = RC.RDB$INDEX_NAME||'''') AND ' +
    '(RC.RDB$CONSTRAINT_TYPE = ?CT) ' + 'AND (RC.RDB$RELATION_NAME = ?RN) ' +
    'ORDER BY IDX.RDB$FIELD_POSITION';

  QRYIndex = 'SELECT IDX.RDB$INDEX_NAME, ISG.RDB$FIELD_NAME, IDX.RDB$UNIQUE_FLAG, ' +
    'IDX.RDB$INDEX_INACTIVE, IDX.RDB$INDEX_TYPE, IDX.RDB$DESCRIPTION FROM RDB$INDICES IDX ' +
    'LEFT JOIN RDB$INDEX_SEGMENTS ISG ON ISG.RDB$INDEX_NAME = IDX.RDB$INDEX_NAME ' +
    'WHERE  NOT  EXISTS(SELECT * FROM RDB$RELATION_CONSTRAINTS C WHERE IDX.RDB$INDEX_NAME = C.RDB$INDEX_NAME) ' +
    ' AND (IDX.RDB$RELATION_NAME = ?RN) ' +
    'ORDER BY IDX.RDB$INDEX_NAME, ISG.RDB$FIELD_POSITION';

  QRYForeign = 'SELECT A.RDB$CONSTRAINT_NAME, B.RDB$UPDATE_RULE, B.RDB$DELETE_RULE, ' +
    'C.RDB$RELATION_NAME AS FK_TABLE, D.RDB$FIELD_NAME AS FK_FIELD, ' +
    'E.RDB$FIELD_NAME AS ONFIELD ' +
    'FROM RDB$REF_CONSTRAINTS B, RDB$RELATION_CONSTRAINTS A, RDB$RELATION_CONSTRAINTS C, ' +
    'RDB$INDEX_SEGMENTS D, RDB$INDEX_SEGMENTS E ' +
    'WHERE (A.RDB$CONSTRAINT_TYPE = ''FOREIGN KEY'') AND ' +
    '(A.RDB$CONSTRAINT_NAME = B.RDB$CONSTRAINT_NAME) AND ' +
    '(B.RDB$CONST_NAME_UQ=C.RDB$CONSTRAINT_NAME) AND (C.RDB$INDEX_NAME=D.RDB$INDEX_NAME) AND ' +
    '(A.RDB$INDEX_NAME||''''=E.RDB$INDEX_NAME) AND ' +
    '(D.RDB$FIELD_POSITION = E.RDB$FIELD_POSITION) ' +
    'AND (A.RDB$RELATION_NAME = ?RN) ' +
    'ORDER BY A.RDB$CONSTRAINT_NAME, D.RDB$FIELD_POSITION';

  QRYCheck = 'SELECT A.RDB$CONSTRAINT_NAME, C.RDB$TRIGGER_SOURCE ' +
    'FROM RDB$RELATION_CONSTRAINTS A, RDB$CHECK_CONSTRAINTS B, RDB$TRIGGERS C ' +
    'WHERE (A.RDB$CONSTRAINT_TYPE = ''CHECK'') AND ' +
    '(A.RDB$CONSTRAINT_NAME = B.RDB$CONSTRAINT_NAME) AND ' +
    '(B.RDB$TRIGGER_NAME = C.RDB$TRIGGER_NAME) AND ' +
    '(C.RDB$TRIGGER_TYPE = 1) ' + 'AND (A.RDB$RELATION_NAME = ?RN)';

  QRYTrigger = 'SELECT T.RDB$TRIGGER_NAME, T.RDB$TRIGGER_SOURCE, T.RDB$TRIGGER_SEQUENCE, ' +
    'T.RDB$TRIGGER_TYPE, T.RDB$TRIGGER_INACTIVE, T.RDB$SYSTEM_FLAG, T.RDB$DESCRIPTION ' +
    'from RDB$TRIGGERS T left join RDB$CHECK_CONSTRAINTS C ON C.RDB$TRIGGER_NAME = ' +
    'T.RDB$TRIGGER_NAME where ((T.RDB$SYSTEM_FLAG = 0) or (T.RDB$SYSTEM_FLAG is null)) ' +
    'and (c.rdb$trigger_name is null) and (T.RDB$RELATION_NAME = ?RN) ' +
    'order by T.RDB$TRIGGER_NAME';

  QRYDBTriggers = 'SELECT T.RDB$TRIGGER_NAME, T.RDB$TRIGGER_SOURCE, T.RDB$TRIGGER_SEQUENCE, ' +
    'T.RDB$TRIGGER_TYPE, T.RDB$TRIGGER_INACTIVE, T.RDB$SYSTEM_FLAG, T.RDB$DESCRIPTION ' +
    'from RDB$TRIGGERS T left join RDB$CHECK_CONSTRAINTS C ON C.RDB$TRIGGER_NAME = ' +
    'T.RDB$TRIGGER_NAME where ((T.RDB$SYSTEM_FLAG = 0) or (T.RDB$SYSTEM_FLAG is null)) ' +
    'and (c.rdb$trigger_name is null) and (T.RDB$RELATION_NAME  IS NULL) ' +
    'order by T.RDB$TRIGGER_NAME';

  QRYSysTrigger = 'SELECT T.RDB$TRIGGER_NAME, T.RDB$TRIGGER_SOURCE, T.RDB$TRIGGER_SEQUENCE, ' +
    'T.RDB$TRIGGER_TYPE, T.RDB$TRIGGER_INACTIVE, T.RDB$SYSTEM_FLAG, T.RDB$DESCRIPTION ' +
    'FROM RDB$TRIGGERS T LEFT JOIN RDB$CHECK_CONSTRAINTS C ON C.RDB$TRIGGER_NAME = ' +
    'T.RDB$TRIGGER_NAME WHERE (T.RDB$RELATION_NAME = ?RN) ORDER BY T.RDB$TRIGGER_NAME';

  QRYViews = 'SELECT REL.RDB$RELATION_NAME, REL.RDB$VIEW_SOURCE, REL.RDB$DESCRIPTION FROM RDB$RELATIONS REL WHERE ' +
    '(REL.RDB$SYSTEM_FLAG <> 1 OR REL.RDB$SYSTEM_FLAG IS NULL) AND ' +
    '(NOT REL.RDB$FLAGS IS NULL) AND ' +
    '(NOT REL.RDB$VIEW_BLR IS NULL) AND ' +
    '(REL.RDB$SECURITY_CLASS STARTING WITH ''SQL$'') ' +
    'ORDER BY REL.RDB$RELATION_ID';

  // The column order is read by TMetaTableField.LoadFromDataBase
  QRYSysDomains = 'select RDB$FIELD_TYPE, RDB$FIELD_SCALE, RDB$FIELD_LENGTH, ' +
    'RDB$FIELD_PRECISION, RDB$CHARACTER_SET_ID, RDB$FIELD_SUB_TYPE, ' +
    'RDB$FIELD_NAME, RDB$SEGMENT_LENGTH, RDB$NULL_FLAG, RDB$DEFAULT_SOURCE, RDB$COMPUTED_SOURCE, ' +
    'RDB$VALIDATION_SOURCE AS CHECK_CONSTRAINT, ' +
    ' (Select Count(*) from  RDB$FIELD_DIMENSIONS  DIM where   DIM.rdb$field_name= RDB$FIELDS.rdb$field_name)    is_Array, ' +
    'RDB$DESCRIPTION ' +
    'FROM RDB$FIELDS';

  // The system flag also excludes the MON$ domains of Firebird 4 and later
  QRYDomains = QRYSysDomains + ' WHERE NOT (RDB$FIELD_NAME STARTING WITH ''RDB$'') AND ' +
    'NOT (RDB$FIELD_NAME STARTING WITH ''SEC$'') AND ' +
    '(RDB$SYSTEM_FLAG IS NULL OR RDB$SYSTEM_FLAG = 0)';

  QRYProcedures = 'SELECT RDB$PROCEDURE_NAME, RDB$PROCEDURE_SOURCE, RDB$DESCRIPTION ' + PackageNameMacro +
    ' FROM RDB$PROCEDURES ORDER BY RDB$PROCEDURE_NAME';

  QRYPackageProcedures = 'SELECT RDB$PROCEDURE_NAME, RDB$PROCEDURE_SOURCE, RDB$DESCRIPTION, RDB$PACKAGE_NAME ' +
    'FROM RDB$PROCEDURES WHERE RDB$PACKAGE_NAME = ?PN ORDER BY RDB$PROCEDURE_NAME';

  QRYProcFields = 'SELECT FS.RDB$FIELD_TYPE, FS.RDB$FIELD_SCALE, FS.RDB$FIELD_LENGTH, FS.RDB$FIELD_PRECISION, ' +
    'FS.RDB$CHARACTER_SET_ID, FS.RDB$FIELD_SUB_TYPE, PP.RDB$PARAMETER_NAME, FS.RDB$SEGMENT_LENGTH, PP.RDB$DESCRIPTION ' +
    'FROM RDB$PROCEDURES PR LEFT JOIN RDB$PROCEDURE_PARAMETERS PP ' +
    'ON PP.RDB$PROCEDURE_NAME = PR.RDB$PROCEDURE_NAME LEFT JOIN RDB$FIELDS FS ON ' +
    'FS.RDB$FIELD_NAME = PP.RDB$FIELD_SOURCE LEFT JOIN RDB$CHARACTER_SETS CR ON ' +
    'FS.RDB$CHARACTER_SET_ID = CR.RDB$CHARACTER_SET_ID LEFT JOIN RDB$COLLATIONS CO ' +
    'ON ((FS.RDB$COLLATION_ID = CO.RDB$COLLATION_ID) AND (FS.RDB$CHARACTER_SET_ID = ' +
    'CO.RDB$CHARACTER_SET_ID)) WHERE (PR.RDB$PROCEDURE_NAME = ?RN) AND ' +
    '(PP.RDB$PARAMETER_TYPE = ?RT)';

  QRYProcFieldsDomain = 'SELECT ' + 'F.RDB$FIELD_TYPE AS FIELD_TYPE_ID,' +
    'F.RDB$FIELD_SCALE AS SCALE,' + 'F.RDB$FIELD_LENGTH AS FIELD_LENGTH_,' +
    'F.RDB$FIELD_PRECISION AS PRECISION_,' +
    'F.RDB$CHARACTER_SET_ID AS CHARSET_ID,' +
    'F.RDB$FIELD_SUB_TYPE AS SUB_TYPE_ID,' +
    'PP.RDB$PARAMETER_NAME AS PARAMETER_NAME,' +
    'F.RDB$SEGMENT_LENGTH AS SEGMENT_SIZE,' +

    'PP.rdb$parameter_mechanism AS MECHANIZM,' +
    'PP.rdb$field_source AS F_BASED_ON_DOMAIN, ' + 'F.RDB$DEFAULT_SOURCE, ' +
    'PP.RDB$DESCRIPTION ' +

    'FROM RDB$PROCEDURE_PARAMETERS PP ' +
    'JOIN RDB$FIELDS F ON F.RDB$FIELD_NAME = PP.RDB$FIELD_SOURCE ' +
    'WHERE PP.RDB$PROCEDURE_NAME = ?RN ' +
    'AND PP.RDB$PARAMETER_TYPE = :RT';

  QRYProcFieldsRelation = 'SELECT ' + 'F.RDB$FIELD_TYPE AS FIELD_TYPE_ID,' +
    'F.RDB$FIELD_SCALE AS SCALE,' + 'F.RDB$FIELD_LENGTH AS FIELD_LENGTH_,' +
    'F.RDB$FIELD_PRECISION AS PRECISION_,' +
    'F.RDB$CHARACTER_SET_ID AS CHARSET_ID,' +
    'F.RDB$FIELD_SUB_TYPE AS SUB_TYPE_ID,' +
    'PP.RDB$PARAMETER_NAME AS PARAMETER_NAME,' +
    'F.RDB$SEGMENT_LENGTH AS SEGMENT_SIZE,' +

    'PP.rdb$parameter_mechanism AS MECHANIZM,' +
    'PP.rdb$field_source AS F_BASED_ON_DOMAIN, ' + 'F.RDB$DEFAULT_SOURCE,' +
    'PP.RDB$RELATION_NAME, ' + 'PP.RDB$FIELD_NAME, ' +
    'PP.RDB$DESCRIPTION ' +

    'FROM RDB$PROCEDURE_PARAMETERS PP ' +
    'JOIN RDB$FIELDS F ON F.RDB$FIELD_NAME = PP.RDB$FIELD_SOURCE ' +
    'WHERE PP.RDB$PROCEDURE_NAME = ?RN ' +
    'AND PP.RDB$PARAMETER_TYPE = :RT';

  // Firebird 3 and later: a packaged procedure can have the name of another one
  ProcFieldsPackageFilter = ' AND COALESCE(PP.RDB$PACKAGE_NAME, '''') = ?PN';
  ProcFieldsOrder = ' ORDER BY PP.RDB$PARAMETER_NUMBER';

  QRYExceptions = 'SELECT RDB$EXCEPTION_NAME, RDB$MESSAGE, RDB$EXCEPTION_NUMBER, RDB$DESCRIPTION FROM RDB$EXCEPTIONS ORDER BY RDB$EXCEPTION_NAME';

  QRYExceptionNames = 'SELECT RDB$EXCEPTION_NAME FROM RDB$EXCEPTIONS ORDER BY RDB$EXCEPTION_NAME';

  QRYUDFs = 'SELECT RDB$FUNCTION_NAME, RDB$MODULE_NAME, RDB$ENTRYPOINT, RDB$RETURN_ARGUMENT, RDB$DESCRIPTION ' +
    'FROM RDB$FUNCTIONS WHERE (RDB$SYSTEM_FLAG IS NULL OR RDB$SYSTEM_FLAG = 0) ORDER BY RDB$FUNCTION_NAME';

  QRYUDFFields = 'SELECT RDB$FIELD_TYPE, RDB$FIELD_SCALE, RDB$FIELD_LENGTH, RDB$FIELD_PRECISION, ' +
    'RDB$CHARACTER_SET_ID, RDB$FIELD_SUB_TYPE, RDB$ARGUMENT_POSITION, RDB$MECHANISM ' +
    'FROM RDB$FUNCTION_ARGUMENTS WHERE RDB$FUNCTION_NAME = ?FN';

  // Firebird 3 and later: a packaged function can have the name of an external one
  UDFFieldsPackageFilter = ' AND RDB$PACKAGE_NAME IS NULL';
  UDFFieldsOrder = ' ORDER BY RDB$ARGUMENT_POSITION';

  // Firebird 3 and later
  QRYUDFsFB3 = 'SELECT RDB$FUNCTION_NAME, RDB$MODULE_NAME, RDB$ENTRYPOINT, RDB$RETURN_ARGUMENT, RDB$DESCRIPTION ' +
    'FROM RDB$FUNCTIONS WHERE (RDB$SYSTEM_FLAG IS NULL OR RDB$SYSTEM_FLAG = 0) AND RDB$FUNCTION_SOURCE IS NULL ' +
    'AND RDB$PACKAGE_NAME IS NULL ORDER BY RDB$FUNCTION_NAME';

  // The packaged functions have no source either, they are loaded with their package
  QRYStoredFuncsFB3 = 'SELECT RDB$FUNCTION_NAME, RDB$FUNCTION_SOURCE, RDB$RETURN_ARGUMENT, RDB$PACKAGE_NAME, ' +
    'RDB$DESCRIPTION FROM RDB$FUNCTIONS WHERE (RDB$SYSTEM_FLAG IS NULL OR RDB$SYSTEM_FLAG = 0) AND ' +
    'RDB$FUNCTION_SOURCE IS NOT NULL AND RDB$PACKAGE_NAME IS NULL ORDER BY RDB$FUNCTION_NAME';

  QRYPackageFunctions = 'SELECT RDB$FUNCTION_NAME, RDB$FUNCTION_SOURCE, RDB$RETURN_ARGUMENT, RDB$PACKAGE_NAME, ' +
    'RDB$DESCRIPTION FROM RDB$FUNCTIONS WHERE RDB$PACKAGE_NAME = ?PN ORDER BY RDB$FUNCTION_NAME';

  // The column order is read by TMetaProcField.DoLoadFromQuery; PN is '' outside a package
  QRYStoredFuncFieldsFB3Base = 'SELECT F.RDB$FIELD_TYPE, F.RDB$FIELD_SCALE, F.RDB$FIELD_LENGTH, ' +
    'F.RDB$FIELD_PRECISION, F.RDB$CHARACTER_SET_ID, F.RDB$FIELD_SUB_TYPE, PP.RDB$ARGUMENT_NAME, ' +
    'F.RDB$SEGMENT_LENGTH, PP.RDB$ARGUMENT_MECHANISM, PP.RDB$FIELD_SOURCE, F.RDB$DEFAULT_SOURCE, ' +
    'PP.RDB$RELATION_NAME, PP.RDB$FIELD_NAME, PP.RDB$DESCRIPTION ' +
    'FROM RDB$FUNCTION_ARGUMENTS PP ' +
    'JOIN RDB$FUNCTIONS F1 ON F1.RDB$FUNCTION_NAME = PP.RDB$FUNCTION_NAME AND ' +
    'F1.RDB$PACKAGE_NAME IS NOT DISTINCT FROM PP.RDB$PACKAGE_NAME ' +
    'JOIN RDB$FIELDS F ON F.RDB$FIELD_NAME = PP.RDB$FIELD_SOURCE ' +
    'WHERE PP.RDB$FUNCTION_NAME = ?FN AND COALESCE(PP.RDB$PACKAGE_NAME, '''') = ?PN AND ';

  QRYStoredFuncFieldsFB3Out = QRYStoredFuncFieldsFB3Base + 'PP.RDB$ARGUMENT_POSITION = F1.RDB$RETURN_ARGUMENT';

  QRYStoredFuncFieldsFB3In = QRYStoredFuncFieldsFB3Base + 'PP.RDB$ARGUMENT_POSITION <> F1.RDB$RETURN_ARGUMENT ' +
    'ORDER BY PP.RDB$ARGUMENT_POSITION';

  QRYPackages = 'SELECT RDB$PACKAGE_NAME, RDB$PACKAGE_HEADER_SOURCE, RDB$PACKAGE_BODY_SOURCE, RDB$DESCRIPTION ' +
    'FROM RDB$PACKAGES WHERE (RDB$SYSTEM_FLAG IS NULL OR RDB$SYSTEM_FLAG = 0)';

  // ^^^^^FB3

  QRYRoles = 'SELECT RDB$ROLE_NAME, RDB$OWNER_NAME ' + DescriptionMacro + ' FROM RDB$ROLES';

  QRYGrant = 'Select ' + 'P.RDB$USER,' + 'P.RDB$PRIVILEGE,' +
    'P.RDB$GRANT_OPTION,' + 'P.RDB$FIELD_NAME,' + 'P.RDB$USER_TYPE,' +
    'P.RDB$OBJECT_TYPE, ' + 'T1.RDB$TYPE_NAME USERTYPE ' +
    'from RDB$USER_PRIVILEGES P ' +
    'JOIN RDB$TYPES T1 ON (P.RDB$USER_TYPE= T1.RDB$TYPE and T1.RDB$FIELD_NAME=''RDB$OBJECT_TYPE'' )' +
    'WHERE RDB$RELATION_NAME=?RN ' + 'AND RDB$USER<>''SYSDBA'' ORDER BY 1';
  { TCustomMetaObject }

constructor TCustomMetaObject.Create(AOwner: TCustomMetaObject; aName: string = '');
begin
  inherited Create;
  Name := aName;
  FOwner := AOwner;
  if (FOwner <> nil) and (ClassIndex >= 0) then
    FOwner.FItems[ClassIndex].Childs.Add(Self)
end;

destructor TCustomMetaObject.Destroy;
var
  I: Integer;
begin
  for I := 0 to FItemsCount - 1 do
  begin
    ClearChilds(I);
    FItems[I].Childs.Free;
    FItems[I].Childs := nil;
  end;
  inherited Destroy;
end;

procedure TCustomMetaObject.Clear;
var
  I: Integer;
begin
  for I := 0 to FItemsCount - 1 do
    ClearChilds(I);
  FLoaded := False
end;

procedure TCustomMetaObject.ClearChilds(const ClassIndex: Integer);
var
  Childs: TList;
  I: TFIBListIndex;
begin
  Childs := FItems[ClassIndex].Childs;
  for I := 0 to Childs.Count - 1 do
    TObject(Childs[I]).Free;
  Childs.Clear;
end;

function TCustomMetaObject.GetAsDDL: string;
var
  Stream: TStringStream;
  DataBase: TMetaDataBase;
begin
  DataBase := MetaDataBase;
  Stream := TStringStream.Create('', TEncoding.Unicode);
  try
    GenerateDDLText(Stream);
    if (DataBase = nil) or DataBase.CommentsIncluded(DataBase.DDLTextOptions) then
      GenerateCommentDDL(Stream);
    Result := Stream.DataString;
  finally
    Stream.Free;
  end;
end;

function TCustomMetaObject.GetMetaDataBase: TMetaDataBase;
var
  Root: TCustomMetaObject;
begin
  Root := Self;
  while Root.FOwner <> nil do
    Root := Root.FOwner;
  if Root is TMetaDataBase then
    Result := TMetaDataBase(Root)
  else
    Result := nil;
end;

procedure TCustomMetaObject.LoadDescription(Query: TFIBQuery);
var
  Field: TFIBXSQLVAR;
begin
  Field := Query.FindField('RDB$DESCRIPTION');
  if (Field <> nil) and not Field.IsNull then
    FDescription := Field.AsString
  else
    FDescription := '';
end;

function TCustomMetaObject.CommentKeyword: string;
begin
  Result := '';
end;

function TCustomMetaObject.CommentTarget: string;
begin
  Result := FormatName;
end;

procedure TCustomMetaObject.WriteCommentDDL(Stream: TStringStream; const Target, Text: string);
var
  Statement: string;
  DataBase: TMetaDataBase;
begin
  Statement := 'COMMENT ON ' + Target + ' IS ' + QuotedStr(Text);
  DataBase := MetaDataBase;
  if (DataBase = nil) or DataBase.CommentFits(Statement, Text) then
    Stream.WriteString(Statement + DefTerminator + sLineBreak)
  else
    // COMMENT ON takes only a literal: such a description cannot be written
    Stream.WriteString('/* The description of ' + StringReplace(Target, '*/', '* /', [rfReplaceAll]) +
      ' is longer than a string literal */' + sLineBreak);
end;

procedure TCustomMetaObject.GenerateCommentDDL(Stream: TStringStream);
begin
  if (FDescription <> '') and (CommentKeyword <> '') then
    WriteCommentDDL(Stream, CommentKeyword + ' ' + CommentTarget, FDescription);
end;

procedure TCustomMetaObject.GenerateChildCommentDDL(Stream: TStringStream; ChildType: Integer);
var
  I: Integer;
begin
  for I := 0 to GetChildsCount(ChildType) - 1 do
    GetChildObject(ChildType, I).GenerateCommentDDL(Stream);
end;

function TCustomMetaObject.GetChildObject(const ClassIndex, Index: Integer): TCustomMetaObject;
var
  FChilds: TList;
begin
  Result := nil;
  FChilds := FItems[ClassIndex].Childs;
  if (FChilds.Count > 0) and (Index >= 0) and (Index < FChilds.Count) then
    Result := TCustomMetaObject(FChilds.Items[Index]);

end;

procedure TCustomMetaObject.AddClass(ClassID: TMetaObjectClass);
begin
  SetLength(FItems, FItemsCount + 1);
  FItems[FItemsCount].Childs := TList.Create;
  FItems[FItemsCount].ClassID := ClassID;
  Inc(FItemsCount);
end;

function TCustomMetaObject.GenerateChildDDL(Stream: TStringStream; ChildType: Integer): Integer;
var
  I: Integer;
begin
  Result := GetChildsCount(ChildType);
  for I := 0 to Result - 1 do
  begin
    Stream.WriteString(sLineBreak);
    GetChildObject(ChildType, I).GenerateObjectDDL(Stream);
    Stream.WriteString(DefTerminator);
  end;
end;

procedure TCustomMetaObject.GenerateObjectDDL(Stream: TStringStream);
begin
end;

function TCustomMetaObject.GetItems(const Index: Integer): TMetaDataItem;
begin
  Assert((Index >= 0) and (FItemsCount > 0) and (Index < FItemsCount));
  Result := FItems[Index];
end;

procedure TCustomMetaObject.GenerateDDLText(Stream: TStringStream);
begin
  GenerateObjectDDL(Stream);
  Stream.WriteString(DefTerminator + sLineBreak)
end;

function TCustomMetaObject.GetAsObjectDDL: string;
var
  Stream: TStringStream;
begin
  Stream := TStringStream.Create('', TEncoding.Unicode);
  try
    GenerateObjectDDL(Stream);
    Result := Stream.DataString;
  finally
    Stream.Free;
  end;
end;

function TCustomMetaObject.GetChildsCount(const ClassIndex: Integer): Integer;
begin
  if FItems[ClassIndex].Childs = nil then
    Result := 0
  else
    Result := Integer(FItems[ClassIndex].Childs.Count); // the objects of one class in the database
end;

procedure TCustomMetaObject.SetName(const Value: string);
begin
  FName := Value;
  FFormatName := FormatIdentifier(3, FName);
end;

function TCustomMetaObject.GetChildObjectByName(const ClassIndex: Integer; const ObjectName: string): TCustomMetaObject;
var
  FChilds: TList;
  I: TFIBListIndex;
begin
  Result := nil;
  if ClassIndex = Ord(otDatabase) then
    Exit;

  FChilds := FItems[ClassIndex].Childs;
  for I := FChilds.Count - 1 downto 0 do
  begin
    if TCustomMetaObject(FChilds.Items[I]).FName = ObjectName then
    begin
      Result := TCustomMetaObject(FChilds.Items[I]);
      Exit;
    end;
  end;
end;

class function TCustomMetaObject.ClassIndex: Integer;
begin
  Result := -1
end;

class function TCustomMetaObject.IsSubObject: boolean;
begin
  Result := False
end;

{ TMetaGenerator }

procedure TMetaGenerator.LoadFromDataBase(QName: TFIBQuery);
var
  Query: TFIBQuery;
begin
  Name := Trim(QName.Fields[0].AsString);
  LoadDescription(QName);
  Query := CreateQuery(Format('select gen_id(%s, 0) from rdb$database', [FormatName]), QName.Transaction);
  try
    Query.ExecQuery;
    if not Query.Eof then
      FValue := Query.Fields[0].AsInt64
  finally
    Query.Free;
  end;
  FLoaded := True
end;

procedure TMetaGenerator.GenerateObjectDDL(Stream: TStringStream);
begin
  Stream.WriteString(Format('CREATE GENERATOR %s;%sSET GENERATOR %0:s TO %2:d', [FormatName, sLineBreak, FValue]));
end;

function TMetaGenerator.CommentKeyword: string;
begin
  Result := 'GENERATOR';
end;

class function TMetaGenerator.ClassIndex: Integer;
begin
  Result := Ord(otGenerator)
end;

{ TMetaTable }

constructor TMetaTable.Create(AOwner: TCustomMetaObject; aName: string = '');
begin
  inherited Create(AOwner, aName);
  AddClass(TMetaTableField);
  AddClass(TMetaPrimaryKey);
  AddClass(TMetaForeignKey);
  AddClass(TCustomMetaTrigger);
  AddClass(TMetaUniqueConstraint);
  AddClass(TMetaIndex);
  AddClass(TMetaCheckConstraint);
  AddClass(TCustomMetaGrant)
end;

function TMetaTable.FindFieldName(const Name: string): TMetaTableField;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to FieldsCount - 1 do
    if Fields[I].FName = Name then
    begin
      Result := Fields[I];
      Exit;
    end;
end;

function TMetaTable.GetFields(const Index: Integer): TMetaTableField;
begin
  Result := TMetaTableField(GetChildObject(Ord(soTableFields), Index))
end;

function TMetaTable.GetFieldsCount: Integer;
begin
  Result := GetChildsCount(Ord(soTableFields));
end;

function TMetaTable.GetPrimaryKey: TMetaPrimaryKey;
begin
  if FItems[Ord(soPrimaryKey)].Childs.Count > 0 then
    Result := TMetaPrimaryKey(GetChildObject(Ord(soPrimaryKey), 0))
  else
    Result := nil
end;

function TMetaTable.GetPrimaryKeyExist: boolean;
begin
  Result := FItems[Ord(soPrimaryKey)].Childs.Count > 0;
end;

function TMetaTable.GetUniques(const Index: Integer): TMetaUniqueConstraint;
begin
  Result := TMetaUniqueConstraint(GetChildObject(Ord(soUniqueConstr), Index))
end;

function TMetaTable.GetUniquesCount: Integer;
begin
  Result := GetChildsCount(Ord(soUniqueConstr));
end;

procedure TMetaTable.LoadFromDataBase(QNames, QFields: TFIBQuery;
  QCharset: TFIBQuery; QPrimary, QIndex, QForeign, QCheck, QTrigger: TFIBQuery;
  ChildTypes: TTableChildTypes);
var
  CurName: string;
  RelationType: TFIBXSQLVAR;
begin
  // Fields
  Name := QNames.Fields[0].AsString;
  LoadDescription(QNames);
  RelationType := QNames.FindField('RDB$RELATION_TYPE');
  if RelationType <> nil then
    FRelationType := RelationType.AsInteger;

  if soTableFields in ChildTypes then
  begin
    QFields.Params[0].AsString := FName;
    QFields.ExecQuery;
    while not QFields.Eof do
    begin
      with TMetaTableField.Create(Self) do
        LoadFromDataBase(QFields, QCharset);
      QFields.Next;
    end;
    QFields.Close;

    // PRIMARY
    if soPrimaryKey in ChildTypes then
    begin
      QPrimary.Params[1].AsString := FName;
      QPrimary.Params[0].AsString := 'PRIMARY KEY';
      QPrimary.ExecQuery;
      if not QPrimary.Eof then
        TMetaPrimaryKey.Create(Self).LoadFromDataBase(QPrimary);
    end;

    // INDICES
    if soIndex in ChildTypes then
    begin
      CurName := '';
      QIndex.Params[0].AsString := FName;
      QIndex.ExecQuery;
      while not QIndex.Eof do
      begin
        if CurName <> QIndex.Fields[0].AsString then
          with TMetaIndex.Create(Self) do
          begin
            SetLength(FFields, 1);
            Name := QIndex.Fields[0].AsString;
            FFields[0] := FindFieldIndex(QIndex.Fields[1].AsString);
            FUnique := QIndex.Fields[2].AsInteger = 1;
            FActive := QIndex.Fields[3].AsInteger = 0;
            if QIndex.Fields[4].AsInteger = 0 then
              FOrder := IoAscending
            else
              FOrder := IoDescending;
            LoadDescription(QIndex);
            CurName := QIndex.Fields[0].AsString;
            FLoaded := True
          end
        else
          with Indices[IndicesCount - 1] do
          begin
            SetLength(FFields, FieldsCount + 1);
            FFields[FieldsCount - 1] := FindFieldIndex(QIndex.Fields[1].AsString);
          end;
        QIndex.Next;
      end;
    end;

    // UNIQUE
    if soUniqueConstr in ChildTypes then
    begin
      QPrimary.Params[0].AsString := 'UNIQUE';
      if not(soPrimaryKey in ChildTypes) then
        QPrimary.Params[1].AsString := FName;
      QPrimary.ExecQuery;
      while not QPrimary.Eof do
      begin
        if CurName <> QPrimary.Fields[0].AsString then
          with TMetaUniqueConstraint.Create(Self) do
          begin
            SetLength(FFields, 1);
            Name := QPrimary.Fields[0].AsString;
            FFields[0] := FindFieldIndex(Trim(QPrimary.Fields[1].AsString));
            CurName := QPrimary.Fields[0].AsString;
            FLoaded := True
          end
        else
          with Uniques[UniquesCount - 1] do
          begin
            SetLength(FFields, FieldsCount + 1);
            FFields[FieldsCount - 1] := FindFieldIndex(Trim(QPrimary.Fields[1].AsString));
          end;
        QPrimary.Next;
      end;
    end;

  end;

  // Check
  if soCheckConstr in ChildTypes then
  begin
    QCheck.Params[0].AsString := FName;
    QCheck.ExecQuery;
    while not QCheck.Eof do
      with TMetaCheckConstraint.Create(Self) do
      begin
        Name := QCheck.Fields[0].AsString;
        FConstraint := QCheck.Fields[1].AsString;
        QCheck.Next;
        FLoaded := True
      end;
  end;

  // TRIGGER
  if soTableTriggers in ChildTypes then
  begin
    QTrigger.Params[0].AsString := FName;
    QTrigger.ExecQuery;
    while not QTrigger.Eof do
    begin
      TMetaTableTrigger.Create(Self).LoadFromDataBase(QTrigger);
      QTrigger.Next;
    end;
  end;
  FLoaded := True
end;

procedure TMetaTable.GenerateDDLText(Stream: TStringStream);
begin
  inherited GenerateDDLText(Stream);
  GenerateChildDDL(Stream, Ord(soPrimaryKey));
  Stream.WriteString(sLineBreak);
  if GenerateChildDDL(Stream, Ord(soUniqueConstr)) > 0 then
    Stream.WriteString(sLineBreak);
  if GenerateChildDDL(Stream, Ord(soIndex)) > 0 then
    Stream.WriteString(sLineBreak);
  if GenerateChildDDL(Stream, Ord(soForeignKey)) > 0 then
    Stream.WriteString(sLineBreak);
  if GenerateChildDDL(Stream, Ord(soCheckConstr)) > 0 then
    Stream.WriteString(sLineBreak);
  if GenerateChildDDL(Stream, Ord(soTableTriggers)) > 0 then
    Stream.WriteString(sLineBreak);
end;

function TMetaTable.CommentKeyword: string;
begin
  Result := 'TABLE';
end;

procedure TMetaTable.GenerateCommentDDL(Stream: TStringStream);
begin
  inherited GenerateCommentDDL(Stream);
  GenerateChildCommentDDL(Stream, Ord(soTableFields));
  GenerateChildCommentDDL(Stream, Ord(soIndex));
  GenerateChildCommentDDL(Stream, Ord(soTableTriggers));
end;

function TMetaTable.GetIndices(const Index: Integer): TMetaIndex;
begin
  Result := TMetaIndex(GetChildObject(Ord(soIndex), Index))
end;

function TMetaTable.GetIndicesCount: Integer;
begin
  Result := GetChildsCount(Ord(soIndex));
end;

function TMetaTable.GetForeign(const Index: Integer): TMetaForeignKey;
begin
  Result := TMetaForeignKey(GetChildObject(Ord(soForeignKey), Index))
end;

function TMetaTable.GetForeignCount: Integer;
begin
  Result := GetChildsCount(Ord(soForeignKey));
end;

function TMetaTable.FindFieldIndex(const Name: string): Integer;
begin
  for Result := 0 to FieldsCount - 1 do
  begin
    if Fields[Result].FName = Name then
      Exit;
  end;
  raise Exception.CreateFmt('Field %s not found', [Name]);
end;

function TMetaTable.GetChecks(const Index: Integer): TMetaCheckConstraint;
begin
  Result := TMetaCheckConstraint(GetChildObject(Ord(soCheckConstr), Index));
end;

function TMetaTable.GetChecksCount: Integer;
begin
  Result := GetChildsCount(Ord(soCheckConstr));
end;

function TMetaTable.GetTriggers(const Index: Integer): TCustomMetaTrigger;
begin
  Result := TCustomMetaTrigger(GetChildObject(Ord(soTableTriggers), Index));
end;

function TMetaTable.GetTriggersCount: Integer;
begin
  Result := GetChildsCount(Ord(soTableTriggers));
end;

procedure TMetaTable.GenerateObjectDDL(Stream: TStringStream);
var
  I: Integer;
begin
  case FRelationType of
    2: Stream.WriteString(Format('CREATE EXTERNAL TABLE %s (', [FormatName]));
    4, 5: Stream.WriteString(Format('CREATE GLOBAL TEMPORARY TABLE %s (', [FormatName]));

  else
    Stream.WriteString(Format('CREATE TABLE %s (', [FormatName]));
  end;
  for I := 0 to FieldsCount - 1 do
  begin
    Stream.WriteString(sLineBreak + '   ');
    Fields[I].GenerateObjectDDL(Stream);
    if I <> FieldsCount - 1 then
      Stream.WriteString(',');
  end;
  Stream.WriteString(sLineBreak + ')');
  case FRelationType of
    4: Stream.WriteString(sLineBreak + 'ON COMMIT PRESERVE ROWS ');
    5: Stream.WriteString(sLineBreak + 'ON COMMIT DELETE ROWS ');
  end;
end;

function TMetaTable.GetGrants(const Index: Integer): TCustomMetaGrant;
begin
  Result := TCustomMetaGrant(GetChildObject(Ord(soTableGrants), Index));
end;

function TMetaTable.GetGrantsCount: Integer;
begin
  Result := GetChildsCount(Ord(soTableGrants));
end;

class function TMetaTable.ClassIndex: Integer;
begin
  Result := Ord(otTable)
end;

{ TCustomMetaField }

procedure TCustomMetaField.LoadFromDataBase(QField, QCharset: TFIBQuery);
var
  Identity: TFIBXSQLVAR;

  procedure GetCharsetInfo(const Id: Integer; var CharSet: string; var Count: Smallint);
  begin
    if not QCharset.Open or (QCharset.Params[0].AsInteger <> Id) then
    begin
      QCharset.Close;
      QCharset.Params[0].AsInteger := Id;
      QCharset.ExecQuery;
    end;
    if QCharset.Fields[0].AsInteger <> QCharset.Fields[3].AsInteger then
      CharSet := QCharset.Fields[1].AsString
    else
      CharSet := '';

    Count := QCharset.Fields[2].AsShort;
  end;

begin
  FScale := Word(Abs(QField.Fields[1].AsShort));
  FLength := QField.Fields[2].AsShort;
  FPrecision := QField.Fields[3].AsShort;
  if (FScale > 0) or
  // NUMERIC(19..38, 0) is stored as INT128 with sub type 1 or 2
    ((QField.Fields[0].AsInteger = blr_int128) and (QField.Fields[5].AsInteger in [1, 2])) then
  begin
    FFieldType := fftNumeric;
    if FPrecision = 0 then
      case QField.Fields[0].AsInteger of
        blr_short: FPrecision := 4;
        blr_long: FPrecision := 7;
        blr_int64, blr_quad, blr_double: FPrecision := 15;
        blr_int128: FPrecision := 38;
      else
        raise Exception.Create('Unknown error');
      end;
  end
  else
    case QField.Fields[0].AsInteger of
      blr_text, blr_text2: FFieldType := fftChar;
      blr_varying, blr_varying2: FFieldType := fftVarchar;
      blr_cstring, blr_cstring2: FFieldType := fftCstring;
      blr_short: FFieldType := fftSmallint;
      blr_long: FFieldType := fftInteger;
      blr_quad: FFieldType := fftQuad;
      blr_float, blr_d_float: FFieldType := fftFloat;
      blr_double: FFieldType := fftDoublePrecision;
      blr_timestamp: FFieldType := fftTimestamp;
      blr_blob: FFieldType := fftBlob;
      blr_blob_id: FFieldType := fftBlobId;
      blr_sql_date: FFieldType := fftDate;
      blr_sql_time: FFieldType := fftTime;
      blr_int64: FFieldType := fftInt64;

      blr_boolean_dtype, blr_bool: FFieldType := fftBoolean;
      blr_int128: FFieldType := fftInt128;
      blr_dec64, blr_dec128: FFieldType := fftDecFloat;
      blr_sql_time_tz, blr_ex_time_tz: FFieldType := fftTimeTZ;
      blr_timestamp_tz, blr_ex_timestamp_tz: FFieldType := fftTimestampTZ;
    end;
  if (FFieldType in [fftChar, fftVarchar, fftCstring]) and not QField.Fields[4].IsNull then
    GetCharsetInfo(QField.Fields[4].AsInteger, FCharSet, FBytesPerCharacter)
  else
    FBytesPerCharacter := 1;

  FSubType := QField.Fields[5].AsShort;
  Identity := QField.FindField('RDB$IDENTITY_TYPE');
  if (Identity = nil) or Identity.IsNull then
    FIdentity := -1
  else
    FIdentity := Identity.AsInteger;
  LoadDescription(QField);
  FLoaded := True
end;

class function TCustomMetaField.IsSubObject: boolean;
begin
  Result := True
end;

function TCustomMetaField.GetDimensionStr: string;
var
  J: NativeInt;
begin
  Result := '[';
  for J := 0 to High(FDimensions) do
    Result := Result + IntToStr(FDimensions[J].LOWER_BOUND) + ':' + IntToStr(FDimensions[J].UPPER_BOUND) + ',';
  Result[System.Length(Result)] := ']'
end;

procedure TCustomMetaField.GenerateObjectDDL(Stream: TStringStream);
begin
  case FFieldType of
    fftNumeric:
      begin
        Stream.WriteString(Format('%s(%d,%d)', [FieldTypes[FFieldType], FPrecision, FScale]));
        if FIsArray then
          Stream.WriteString(' ' + GetDimensionStr);

      end;
    fftChar .. fftCstring:
      begin
        if FBytesPerCharacter < 0 then
          FBytesPerCharacter := 1;
        Stream.WriteString(Format('%s(%d)', [FieldTypes[FFieldType], FLength div FBytesPerCharacter]));
        if FIsArray then
          Stream.WriteString(' ' + GetDimensionStr);
        if FCharSet <> '' then
          Stream.WriteString(' CHARACTER SET ' + FCharSet);
      end;
    fftBlob:
      Stream.WriteString(Format('%s SUB_TYPE %d SEGMENT SIZE %d', [FieldTypes[FFieldType], FSubType, FSegmentLength]));
    fftDecFloat:
      begin
        Stream.WriteString(GetShortFieldType);
        if FIsArray then
          Stream.WriteString(' ' + GetDimensionStr);
      end;
  else
    Stream.WriteString(Format('%s', [FieldTypes[FFieldType]]));
    if FIsArray then
      Stream.WriteString(' ' + GetDimensionStr);

  end;
end;

function TCustomMetaField.GetShortFieldType: string;
begin
  case FFieldType of
    fftChar .. fftCstring: Result := Format('%s(%d)', [FieldTypes[FFieldType], FLength div FBytesPerCharacter]);
    fftNumeric: Result := Format('%s(%d,%d)', [FieldTypes[FFieldType], FPrecision, FScale]);
    fftDecFloat:
      if FLength = 8 then
        Result := FieldTypes[FFieldType] + '(16)'
      else
        Result := FieldTypes[FFieldType] + '(34)';
  else
    Result := Format('%s', [FieldTypes[FFieldType]]);
  end;
end;

{ TMetaDataBase }

constructor TMetaDataBase.Create(AOwner: TCustomMetaObject; aName: string = '');
begin
  inherited Create(nil);
  FInternalTransaction := TFIBTransaction.Create(nil);
  FInternalTransaction.Internal := True;
  FInternalTransaction.TPBMode := tpbDefault;
  FInternalTransaction.TRParams.Add('read');
  FInternalTransaction.TRParams.Add('nowait');
  FInternalTransaction.TRParams.Add('concurrency');

  AddClass(TMetaDomain);
  AddClass(TMetaTable);
  AddClass(TMetaView);
  AddClass(TMetaProcedure);
  AddClass(TMetaGenerator);
  AddClass(TMetaException);
  AddClass(TMetaUDF);
  AddClass(TMetaRole);
  AddClass(TCustomMetaTrigger);
  AddClass(TMetaStoredFunc);
  AddClass(TMetaPackage);

  FLoadObjects := DefObjects;
  FLoadTableChilds := DefTableChilds;
  FLoadViewChilds := DefViewChilds;
  FDDLTextOptions := DefDDLTextOptions;
end;

destructor TMetaDataBase.Destroy;
begin
  FInternalTransaction.Free;
  inherited Destroy;
end;

procedure TMetaDataBase.LoadFromDataBase(DB: TFIBDatabase; OnlyNames: boolean = False);
var
  I: Integer;
  ConStr, Str: string;
  QCharset: TFIBQuery;
  QNames, QFields, QFuncReturn, QFuncInputs, QPrimary: TFIBQuery;
  QIndex, QForeign, QCheck, QTrigger: TFIBQuery;
  QGrants: TFIBQuery;
  Stop: boolean;
  Transaction: TFIBTransaction;
  CurObject: TCustomMetaObject;
begin
  // Also the objects of the types not loaded now, left by GetDBObject
  Clear;
  FName := DB.DatabaseName;
  Transaction := FInternalTransaction;
  if Transaction.Active then
    Transaction.Commit;
  Transaction.DefaultDatabase := DB;
  Transaction.StartTransaction;
  try

    Stop := False;
    QNames := nil;
    QTrigger := nil;
    QCharset := nil;
    QFields := nil;
    QFuncReturn := nil;
    QFuncInputs := nil;
    QPrimary := nil;
    QIndex := nil;
    QForeign := nil;
    QCheck := nil;
    QGrants := nil;
    try
      QNames := CreateQuery('', Transaction);
      if FSysInfos then
        QTrigger := CreateQuery(QRYSysTrigger, Transaction)
      else
        QTrigger := CreateQuery(QRYTrigger, Transaction);
      QCharset := CreateQuery(QRYCharset, Transaction);
      // Each object type sets its SQL, after DetectServerFeatures
      QFields := CreateQuery('', Transaction);
      QFuncReturn := CreateQuery(QRYStoredFuncFieldsFB3Out, Transaction);
      QFuncInputs := CreateQuery(QRYStoredFuncFieldsFB3In, Transaction);
      QPrimary := CreateQuery(QRYUnique, Transaction);
      QIndex := CreateQuery(QRYIndex, Transaction);
      QForeign := CreateQuery(QRYForeign, Transaction);
      QCheck := CreateQuery(QRYCheck, Transaction);
      QGrants := CreateQuery(QRYGrant, Transaction);

      FPageSize := Transaction.DefaultDatabase.PageSize;
      QNames.SQL.Text := QRYDB_INFO;
      QNames.ExecQuery;
      FDefaultCharset := Trim(QNames.Fields[0].AsString);
      LoadDescription(QNames);
      QNames.Close;
      FSQLDialect := Transaction.DefaultDatabase.SQLDialect;
      FConnectCharset := Transaction.DefaultDatabase.ConnectParams.CharSet;
      FClientLib := Transaction.DefaultDatabase.LibraryName;

      DetectServerFeatures;

      // DOMAINS
      if otDomain in FLoadObjects then
      begin
        if FSysInfos then
          QNames.SQL.Text := QRYSysDomains
        else
          QNames.SQL.Text := QRYDomains;
        QNames.ExecQuery;
        while not QNames.Eof do
        begin
          if Assigned(FOnLoadMetaData) then
          begin
            FOnLoadMetaData(Self, 'Load Domains: ' + QNames.FieldByName('RDB$FIELD_NAME').AsString, Stop);
            if Stop then
              Exit
          end;
          with TMetaDomain.Create(Self, QNames.FieldByName('RDB$FIELD_NAME').AsString) do
            if not OnlyNames then
              LoadFromDataBase(QNames, QCharset);
          QNames.Next;
        end;
        QNames.Close;
      end;

      // GENERATORS
      if otGenerator in FLoadObjects then
      begin
        QNames.SQL.Text := QRYGenerators;
        SetOptionalColumns(QNames, otGenerator);
        QNames.ExecQuery;
        while not QNames.Eof do
        begin
          if Assigned(FOnLoadMetaData) then
          begin
            FOnLoadMetaData(Self, 'Load Generators: ' + QNames.Fields[0].AsString, Stop);
            if Stop then
              Exit
          end;
          with TMetaGenerator.Create(Self, QNames.Fields[0].AsString) do
            if not OnlyNames then
              LoadFromDataBase(QNames);
          QNames.Next;
        end;
        QNames.Close;
      end;

      if (otStoredFunctions in FLoadObjects) and FStoredFunctionsSupports then
      begin
        QNames.SQL.Text := QRYStoredFuncsFB3;
        QNames.ExecQuery;

        while not QNames.Eof do
        begin
          if Assigned(FOnLoadMetaData) then
          begin
            FOnLoadMetaData(Self, 'Load Functions: ' + QNames.Fields[0].AsString, Stop);
            if Stop then
              Exit
          end;

          with TMetaStoredFunc.Create(Self, QNames.Fields[0].AsString) do
            if not OnlyNames then
              LoadFromDataBase(QNames, QFuncReturn, QFuncInputs, QCharset);
          QNames.Next;
        end;
        QNames.Close;

      end;

      // UDF
      if otUDF in FLoadObjects then
      begin
        if not FStoredFunctionsSupports then
          QNames.SQL.Text := QRYUDFs
        else
          QNames.SQL.Text := QRYUDFsFB3;
        QFields.SQL.Text := UDFFieldsSQL;
        QNames.ExecQuery;
        while not QNames.Eof do
        begin
          if Assigned(FOnLoadMetaData) then
          begin
            FOnLoadMetaData(Self, 'Load Functions: ' + QNames.Fields[0].AsString, Stop);
            if Stop then
              Exit
          end;

          with TMetaUDF.Create(Self, QNames.Fields[0].AsString) do
            if not OnlyNames then
              LoadFromDataBase(QNames, QFields, QCharset);
          QNames.Next;
        end;
        QNames.Close;
      end;

      // TABLES
      if otTable in FLoadObjects then
      begin

        if FTabRelTypeSupports then
        begin
          if FSysInfos then
            QNames.SQL.Text := QRYSysTablesRel
          else
            QNames.SQL.Text := QRYTablesRel;
        end
        else
        begin
          if FSysInfos then
            QNames.SQL.Text := QRYSysTables
          else
            QNames.SQL.Text := QRYTables;
        end;
        QNames.ExecQuery;
        if FIdentityFieldsSupports then
          QFields.SQL.Text := QRYTableFieldsFB3
        else
          QFields.SQL.Text := QRYTableFields;

        while not QNames.Eof do
        begin
          if Assigned(FOnLoadMetaData) then
          begin
            FOnLoadMetaData(Self, 'Load Tables: ' + QNames.Fields[0].AsString, Stop);
            if Stop then
              Exit
          end;
          CurObject := TMetaTable.Create(Self, QNames.Fields[0].AsString);
          with TMetaTable(CurObject) do
            if not OnlyNames then
              LoadFromDataBase(QNames, QFields, QCharset, QPrimary, QIndex,
                QForeign, QCheck, QTrigger, FLoadTableChilds);

          QGrants.Params[0].AsString := QNames.Fields[0].AsString;
          QGrants.ExecQuery;
          if not QGrants.Eof then
            TMetaTableGrant.Create(CurObject).LoadFromDataBase(QGrants, QNames.Fields[0].AsString);
          QNames.Next;
        end;
        QNames.Close;
        // FOREIGN
        // if not  OnlyNames then
        if [soForeignKey, soTableFields] <= FLoadTableChilds then
        begin
          for I := 0 to TablesCount - 1 do
          begin
            if Assigned(FOnLoadMetaData) then
            begin
              FOnLoadMetaData(Self, 'Load Foreign keys for table: ' + Tables[I].Name, Stop);
              if Stop then
                Exit
            end;
            QForeign.Params[0].AsString := Tables[I].Name;
            QForeign.ExecQuery;
            ConStr := '';
            while not QForeign.Eof do
            begin
              if ConStr <> Trim(QForeign.Fields[0].AsString) then // new
              begin
                with TMetaForeignKey.Create(Tables[I]) do
                begin
                  Name := QForeign.Fields[0].AsString;
                  if not OnlyNames then
                  begin
                    FLoaded := True;
                    ConStr := FName;
                    FForTable := FindTableIndex(Trim(QForeign.Fields[3].AsString));
                    SetLength(FFields, 1);
                    FFields[0] := Tables[I].FindFieldIndex
                      (Trim(QForeign.Fields[5].AsString));
                    SetLength(FForFields, 1);
                    FForFields[0] := ForTable.FindFieldIndex
                      (Trim(QForeign.Fields[4].AsString));

                    Str := QForeign.Fields[1].AsString;
                    if Str = 'RESTRICT' then
                      FOnUpdate := fkrRestrict
                    else if Str = 'CASCADE' then
                      FOnUpdate := fkrCascade
                    else if Str = 'SET NULL' then
                      FOnUpdate := fkrSetNull
                    else
                      FOnUpdate := fkrSetDefault;

                    Str := Trim(QForeign.Fields[2].AsString);
                    if Str = 'RESTRICT' then
                      FOnDelete := fkrRestrict
                    else if Str = 'CASCADE' then
                      FOnDelete := fkrCascade
                    else if Str = 'SET NULL' then
                      FOnDelete := fkrSetNull
                    else
                      FOnDelete := fkrSetDefault;
                  end;
                end;
              end
              else
                with Tables[I].Foreign[Tables[I].ForeignCount - 1] do
                begin
                  SetLength(FFields, Length(FFields) + 1);
                  FFields[FieldsCount - 1] := Tables[I].FindFieldIndex(Trim(QForeign.Fields[5].AsString));
                  SetLength(FForFields, Length(FForFields) + 1);
                  FForFields[ForFieldsCount - 1] := ForTable.FindFieldIndex(Trim(QForeign.Fields[4].AsString));
                end;
              QForeign.Next;
            end;
          end;
        end;
      end;

      // VIEWS
      if otView in FLoadObjects then
      begin
        QNames.SQL.Text := QRYViews;
        QFields.SQL.Text := QRYTableFields;
        QNames.ExecQuery;
        while not QNames.Eof do
        begin
          if Assigned(FOnLoadMetaData) then
          begin
            FOnLoadMetaData(Self, 'Load Views: ' + QNames.Fields[0].AsString, Stop);
            if Stop then
              Exit
          end;

          CurObject := TMetaView.Create(Self, QNames.Fields[0].AsString);
          // if not  OnlyNames then
          begin
            with TMetaView(CurObject) do
              LoadFromDataBase(QNames, QFields, QTrigger, QCharset, FLoadViewChilds);

            QGrants.Params[0].AsString := QNames.Fields[0].AsString;
            QGrants.ExecQuery;
            if not QGrants.Eof then
              TMetaViewGrant.Create(CurObject).LoadFromDataBase(QGrants, QNames.Fields[0].AsString);
          end;
          QNames.Next;
        end;
        QNames.Close;
      end;

      // PROCEDURE
      if otProcedure in FLoadObjects then
      begin

        QNames.SQL.Text := QRYProcedures;
        if FPackagesSupports then
          QNames.MainWhereClause := 'RDB$PACKAGE_NAME IS NULL';
        SetOptionalColumns(QNames, otProcedure);
        QFields.SQL.Text := ProcFieldsSQL;

        QNames.ExecQuery;
        while not QNames.Eof do
        begin
          if Assigned(FOnLoadMetaData) then
          begin
            FOnLoadMetaData(Self, 'Load Procedures: ' + QNames.Fields[0].AsString, Stop);
            if Stop then
              Exit
          end;

          CurObject := TMetaProcedure.Create(Self, QNames.Fields[0].AsString);
          if not OnlyNames then
          begin
            with TMetaProcedure(CurObject) do
              LoadFromDataBase(QNames, QFields, QCharset, FProcParamDomainSupports, FProcParamRelationSupports);

            QGrants.Params[0].AsString := QNames.Fields[0].AsString;
            QGrants.ExecQuery;
            if not QGrants.Eof then
              TMetaProcGrant.Create(CurObject).LoadFromDataBase(QGrants, QNames.Fields[0].AsString);
          end;
          QNames.Next;
        end;
        QNames.Close;
      end;

      // EXCEPTION
      if otException in FLoadObjects then
      begin
        if OnlyNames then
          QNames.SQL.Text := QRYExceptionNames
        else
          QNames.SQL.Text := QRYExceptions;

        QNames.ExecQuery;
        while not QNames.Eof do
        begin
          if Assigned(FOnLoadMetaData) then
          begin
            FOnLoadMetaData(Self, 'Load Exceptions: ' + QNames.Fields[0].AsString, Stop);
            if Stop then
              Exit
          end;
          with TMetaException.Create(Self, QNames.Fields[0].AsString) do
            if not OnlyNames then
              LoadFromDataBase(QNames);
          QNames.Next;
        end;
        QNames.Close;
      end;

      // DBTriggers
      if otDBTrigger in FLoadObjects then
      begin
        QNames.SQL.Text := QRYDBTriggers;
        QNames.ExecQuery;
        while not QNames.Eof do
        begin
          if Assigned(FOnLoadMetaData) then
          begin
            FOnLoadMetaData(Self, 'Load DB Triggers: ' + QNames.Fields[0].AsString, Stop);
            if Stop then
              Exit
          end;

          with TMetaDBTrigger.Create(Self, QNames.Fields[0].AsString) do
            if not OnlyNames then
              LoadFromDataBase(QNames);
          QNames.Next;
        end;
        QNames.Close;
      end;

      if FPackagesSupports and (otPackage in FLoadObjects) then
      begin
        QNames.SQL.Text := QRYPackages;
        QNames.ExecQuery;
        while not QNames.Eof do
        begin
          if Assigned(FOnLoadMetaData) then
          begin
            FOnLoadMetaData(Self, 'Load DB Packages: ' + QNames.Fields[0].AsString, Stop);
            if Stop then
              Exit
          end;

          with TMetaPackage.Create(Self, QNames.Fields[0].AsString) do
            if not OnlyNames then
              LoadFromDataBase(QNames, QCharset);
          QNames.Next;
        end;
        QNames.Close;
      end;

      // ROLES
      if otRole in FLoadObjects then
      begin
        QNames.SQL.Text := QRYRoles;
        SetOptionalColumns(QNames, otRole);
        QNames.ExecQuery;
        while not QNames.Eof do
        begin
          if Assigned(FOnLoadMetaData) then
          begin
            FOnLoadMetaData(Self, 'Load DB ROLES: ' + QNames.Fields[0].AsString, Stop);
            if Stop then
              Exit
          end;
          if FSysInfos or (Copy(QNames.Fields[0].AsString, 1, 4) <> 'RDB$') then
          begin

            CurObject := TMetaRole.Create(Self);
            TMetaRole(CurObject).LoadFromDataBase(QNames);

            QGrants.Params[0].AsString := QNames.Fields[0].AsString;
            QGrants.ExecQuery;
            if not QGrants.Eof then
              TMetaRoleGrant.Create(CurObject).LoadFromDataBase(QGrants, QNames.Fields[0].AsString);
          end;
          QNames.Next;
        end;
        QNames.Close;
      end;
    finally
      QFuncReturn.Free;
      QFuncInputs.Free;
      QNames.Free;
      QCharset.Free;

      QFields.Free;
      QPrimary.Free;
      QIndex.Free;
      QForeign.Free;
      QCheck.Free;
      QTrigger.Free;
      QGrants.Free;
    end;
  finally
    Transaction.Commit;
    FLoaded := not OnlyNames;
    FNamesLoaded := True
  end
end;

procedure TMetaDataBase.ExtGenerateDDLText(Stream: TStringStream; Options: TDDLTextOptions = DefDDLTextOptions);
var
  I: Integer;

  procedure SaveChilds(const Comment: string; ParentType, ChildType: Integer; Separator: string = DefTerminator; Kind: Integer = 0);
  // Kind= 0 - standard, =1 -FakeViewTrigger,=2 Alter - View Trigger
  var
    I, J: Integer;
    Parent: TCustomMetaObject;
    HeaderWritten: boolean;
  begin
    HeaderWritten := False;
    for I := 0 to GetChildsCount(ParentType) - 1 do
    begin
      Parent := GetChildObject(ParentType, I);
      for J := 0 to Parent.GetChildsCount(ChildType) - 1 do
      begin
        if not HeaderWritten then
        begin
          Stream.WriteString(sLineBreak + Format('/* %s */', [Comment]) + sLineBreak);
          HeaderWritten := True;
        end;
        Stream.WriteString(sLineBreak);
        case Kind of
          0: Parent.GetChildObject(ChildType, J).GenerateObjectDDL(Stream);
          1: TCustomMetaTrigger(Parent.GetChildObject(ChildType, J)).SaveFakeDDL(Stream);
          2: TCustomMetaTrigger(Parent.GetChildObject(ChildType, J)).SaveAlterDDL(Stream);
        end;
        Stream.WriteString(Separator + sLineBreak);
      end;
    end;
  end;

  procedure SaveMainObjects(Comment: string; ObjType: Integer; Separator: Char = DefTerminator);
  var
    I: Integer;
    CurObj: TCustomMetaObject;
  begin
    if FItems[ObjType].Childs.Count > 0 then
    begin
      Stream.WriteString(sLineBreak + sLineBreak + Format('/* %s */', [Comment]));
      if Separator <> DefTerminator then
      begin
        Stream.WriteString(sLineBreak);
        Stream.WriteString('SET TERM ^;');
        Stream.WriteString(sLineBreak);
      end;

      for I := 0 to GetChildsCount(ObjType) - 1 do
      begin
        CurObj := GetChildObject(ObjType, I);
        if not CurObj.Loaded then
          CurObj := GetDBObject(FInternalTransaction.DefaultDatabase, TDBObjectType(ObjType), CurObj.FName);
        if I = 0 then
          Stream.WriteString(sLineBreak)
        else
        begin
          Stream.WriteString(sLineBreak + sLineBreak);
        end;
        // Only the object; its constraints, triggers and bodies follow in their own sections
        if CurObj is TMetaProcedure then
          TMetaProcedure(CurObj).SaveToPostDDL(Stream)
        else if CurObj is TMetaPackage then
          TMetaPackage(CurObj).SaveSpecDDL(Stream)
        else if CurObj is TMetaStoredFunc then
          TMetaStoredFunc(CurObj).SaveEmptyDDL(Stream)
        else
          CurObj.GenerateObjectDDL(Stream);
        Stream.WriteString(Separator);
      end;
      Stream.WriteString(sLineBreak + sLineBreak);

      if Separator <> DefTerminator then
      begin
        Stream.WriteString(sLineBreak);
        Stream.WriteString('SET TERM ;^');
        Stream.WriteString(sLineBreak);
      end;

    end;
  end;

  procedure SaveComments;
  const
    // The order of the script
    CommentedObjects: array [0 .. 10] of TDBObjectType = (otRole, otUDF, otDomain, otGenerator, otException,
      otProcedure, otStoredFunctions, otPackage, otTable, otView, otDBTrigger);
  var
    Comments: TStringStream;
    ObjType: TDBObjectType;
    I: Integer;
  begin
    Comments := TStringStream.Create('', TEncoding.Unicode);
    try
      if FDescription <> '' then
        WriteCommentDDL(Comments, 'DATABASE', FDescription);
      for ObjType in CommentedObjects do
        for I := 0 to GetChildsCount(Ord(ObjType)) - 1 do
          GetChildObject(Ord(ObjType), I).GenerateCommentDDL(Comments);
      if Comments.Size > 0 then
        Stream.WriteString(sLineBreak + '/* COMMENTS */' + sLineBreak + sLineBreak + Comments.DataString +
          sLineBreak);
    finally
      Comments.Free;
    end;
  end;

  procedure SaveGrants;
  var
    I: Integer;
    TabNode: TMetaTable;
    ViewNode: TMetaView;
    ProcNode: TMetaProcedure;
    RoleNode: TMetaRole;
  begin
    Stream.WriteString(sLineBreak + sLineBreak);

    Stream.WriteString('/*GRANTS*/');
    Stream.WriteString(sLineBreak);
    Stream.WriteString('/*GRANTS ON TABLES*/');
    Stream.WriteString(sLineBreak);
    Stream.WriteString(sLineBreak);
    for I := 0 to TablesCount - 1 do
    begin
      TabNode := Tables[I];
      if TabNode.GetGrantsCount > 0 then
        TabNode.GetGrants(0).GenerateObjectDDL(Stream)
    end;
    Stream.WriteString('COMMIT WORK;');

    Stream.WriteString(sLineBreak + sLineBreak);
    Stream.WriteString('/*GRANTS ON VIEWS*/');
    Stream.WriteString(sLineBreak + sLineBreak);
    for I := 0 to ViewsCount - 1 do
    begin
      ViewNode := Views[I];
      if ViewNode.GetGrantsCount > 0 then
        ViewNode.GetGrants(0).GenerateObjectDDL(Stream)
    end;
    Stream.WriteString('COMMIT WORK;');

    Stream.WriteString(sLineBreak + sLineBreak);
    Stream.WriteString('/*GRANTS ON PROCEDURES*/');
    Stream.WriteString(sLineBreak + sLineBreak);
    for I := 0 to ProceduresCount - 1 do
    begin
      ProcNode := Procedures[I];
      if ProcNode.GetGrantsCount > 0 then
        ProcNode.GetGrants(0).GenerateObjectDDL(Stream)
    end;
    Stream.WriteString('COMMIT WORK;');

    Stream.WriteString(sLineBreak + sLineBreak);
    Stream.WriteString('/*GRANTS ROLES*/');
    Stream.WriteString(sLineBreak + sLineBreak);
    for I := 0 to RolesCount - 1 do
    begin
      RoleNode := Roles[I];
      if RoleNode.GetGrantsCount > 0 then
        RoleNode.GetGrants(0).GenerateObjectDDL(Stream)
    end;
    Stream.WriteString('COMMIT WORK;');

  end;

var
  vProcTerminator: Char;
begin

  Stream.WriteString('SET SQL DIALECT ' + IntToStr(FSQLDialect) + ';' + sLineBreak);
  Stream.WriteString('SET NAMES  ' + FConnectCharset + ';' + sLineBreak);
  if dtoUseSetClientLib in Options then
    Stream.WriteString('SET CLIENTLIB  ''' + FClientLib + ''';' + sLineBreak + sLineBreak);

  if dtoUseCreateDB in Options then
  begin
    Stream.WriteString('CREATE DATABASE ''' + FName + '''' + sLineBreak +
      'USER ''SYSDBA'' PASSWORD ''masterkey''' + sLineBreak + 'PAGE_SIZE ' + IntToStr(FPageSize) + sLineBreak);
    if Length(FDefaultCharset) > 0 then
      Stream.WriteString('DEFAULT CHARACTER SET ' + FDefaultCharset + DefTerminator + sLineBreak);
  end
  else
    Stream.WriteString('CONNECT ''' + FName + ''' USER ''SYSDBA'' PASSWORD ''masterkey'';' + sLineBreak);

  if dtoUseSetTerm in Options then
    vProcTerminator := ProcTerminator
  else
    vProcTerminator := DefTerminator;
  SaveMainObjects('ROLES', Ord(otRole));
  SaveMainObjects('FUNCTIONS', Ord(otUDF));
  SaveMainObjects('DOMAINS', Ord(otDomain));
  SaveMainObjects('GENERATORS', Ord(otGenerator));
  SaveMainObjects('EXEPTIONS', Ord(otException));
  SaveMainObjects('PROCEDURES', Ord(otProcedure), vProcTerminator);
  SaveMainObjects('FUNCTIONS', Ord(otStoredFunctions), vProcTerminator);
  SaveMainObjects('PACKAGES', Ord(otPackage), vProcTerminator);
  SaveMainObjects('TABLES', Ord(otTable));
  SaveMainObjects('VIEWS', Ord(otView));
  SaveMainObjects('DB TRIGGERS', Ord(otDBTrigger), vProcTerminator);
  SaveChilds('UNIQUE', Ord(otTable), Ord(soUniqueConstr));
  SaveChilds('PRIMARY', Ord(otTable), Ord(soPrimaryKey));
  SaveChilds('FOREIGN', Ord(otTable), Ord(soForeignKey));
  SaveChilds('INDICES', Ord(otTable), Ord(soIndex));
  SaveChilds('CHECKS', Ord(otTable), Ord(soCheckConstr));
  if dtoUseSetTerm in Options then
    Stream.WriteString(sLineBreak + 'SET TERM ^;' + sLineBreak);
  SaveChilds('TRIGGERS (Views)', Ord(otView), Ord(soViewTriggers), vProcTerminator, 1);
  SaveChilds('TRIGGERS', Ord(otTable), Ord(soTableTriggers), vProcTerminator);
  SaveChilds('TRIGGERS (Views)', Ord(otView), Ord(soViewTriggers), vProcTerminator, 2);

  if ProceduresCount > 0 then
  begin
    Stream.WriteString(sLineBreak + '/* PROCEDURES */');
    for I := 0 to ProceduresCount - 1 do
    begin
      Stream.WriteString(sLineBreak + sLineBreak);
      Procedures[I].SaveToAlterDDL(Stream);
      Stream.WriteString(vProcTerminator + sLineBreak);
    end;
  end;

  if PackageCount > 0 then
  begin
    Stream.WriteString(sLineBreak + '/* PACKAGES */');
    for I := 0 to PackageCount - 1 do
    begin
      Stream.WriteString(sLineBreak + sLineBreak);
      Packages[I].SaveBodyDDL(Stream);
      Stream.WriteString(vProcTerminator + sLineBreak);
    end;
  end;

  if GetFunctionsCount > 0 then
  begin
    Stream.WriteString(sLineBreak + '/* FUNCTIONS */');
    for I := 0 to GetFunctionsCount - 1 do
    begin
      Stream.WriteString(sLineBreak + sLineBreak);
      GetFunctions(I).SaveAlterDDL(Stream);
      Stream.WriteString(vProcTerminator + sLineBreak);
    end;
  end;

  if dtoUseSetTerm in Options then
    Stream.WriteString('SET TERM ;^' + sLineBreak + sLineBreak);
  if CommentsIncluded(Options) then
    SaveComments;
  Stream.WriteString('COMMIT WORK;');

  if dtoIncludeGrants in Options then
    SaveGrants
end;

function TMetaDataBase.GetGenerators(const Index: Integer): TMetaGenerator;
begin
  Result := TMetaGenerator(GetChildObject(Ord(otGenerator), Index));
end;

function TMetaDataBase.GetGeneratorsCount: Integer;
begin
  Result := GetChildsCount(Ord(otGenerator))
end;

function TMetaDataBase.GetTables(const Index: Integer): TMetaTable;
begin
  Result := TMetaTable(GetChildObject(Ord(otTable), Index));
end;

function TMetaDataBase.GetTablesCount: Integer;
begin
  Result := GetChildsCount(Ord(otTable))
end;

function TMetaDataBase.FindTableIndex(const TableName: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to TablesCount - 1 do
    if Tables[I].Name = TableName then
    begin
      Result := I;
      Exit;
    end
end;

function TMetaDataBase.FindDomainIndex(const DomainName: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to DomainsCount - 1 do
    if Domains[I].Name = DomainName then
    begin
      Result := I;
      Exit;
    end
end;

function TMetaDataBase.GetViews(const Index: Integer): TMetaView;
begin
  Result := TMetaView(GetChildObject(Ord(otView), Index));
end;

function TMetaDataBase.GetViewsCount: Integer;
begin
  Result := GetChildsCount(Ord(otView))
end;

function TMetaDataBase.GetDomains(const Index: Integer): TMetaDomain;
begin

  Result := TMetaDomain(GetChildObject(Ord(otDomain), Index));
end;

function TMetaDataBase.GetDomainsCount: Integer;
begin
  Result := GetChildsCount(Ord(otDomain))
end;

function TMetaDataBase.GetPackageCount: Integer;
begin
  Result := GetChildsCount(Ord(otPackage))
end;

function TMetaDataBase.GetPackages(const Index: Integer): TMetaPackage;
begin
  Result := TMetaPackage(GetChildObject(Ord(otPackage), Index));
end;

function TMetaDataBase.GetProcedures(const Index: Integer): TMetaProcedure;
begin
  Result := TMetaProcedure(GetChildObject(Ord(otProcedure), Index));
end;

function TMetaDataBase.GetProceduresCount: Integer;
begin
  Result := GetChildsCount(Ord(otProcedure))
end;

function TMetaDataBase.GetFunctionsCount: Integer;
begin
  Result := GetChildsCount(Ord(otStoredFunctions))
end;

function TMetaDataBase.GetFunctions(const Index: Integer): TMetaStoredFunc;
begin
  Result := TMetaStoredFunc(GetChildObject(Ord(otStoredFunctions), Index));
end;

function TMetaDataBase.GetExceptions(const Index: Integer): TMetaException;
begin
  Result := TMetaException(GetChildObject(Ord(otException), Index));
end;

function TMetaDataBase.GetExceptionsCount: Integer;
begin
  Result := GetChildsCount(Ord(otException))
end;

function TMetaDataBase.GetUDFS(const Index: Integer): TMetaUDF;
begin
  Result := TMetaUDF(GetChildObject(Ord(otUDF), Index));
end;

function TMetaDataBase.GetUDFSCount: Integer;
begin
  Result := GetChildsCount(Ord(otUDF))
end;

function TMetaDataBase.GetRoles(const Index: Integer): TMetaRole;
begin
  Result := TMetaRole(GetChildObject(Ord(otRole), Index));
end;

function TMetaDataBase.GetRolesCount: Integer;
begin
  Result := GetChildsCount(Ord(otRole))
end;

procedure TMetaDataBase.Clear;
begin
  inherited Clear;
  FNamesLoaded := False;
end;

procedure TMetaDataBase.DetectServerFeatures;
var
  Query: TFIBQuery;
begin
  Query := CreateQuery(QRY_SERVER_FEATURES, FInternalTransaction);
  try
    Query.ExecQuery;
    FStoredFunctionsSupports := Query.FieldByName('STORED_FUNCTIONS').AsInteger > 0;
    FPackagesSupports := Query.FieldByName('PACKAGES').AsInteger > 0;
    FIdentityFieldsSupports := Query.FieldByName('IDENTITY_FIELDS').AsInteger > 0;
    FTabRelTypeSupports := Query.FieldByName('RELATION_TYPE').AsInteger > 0;
    FProcParamDomainSupports := Query.FieldByName('PARAM_DOMAINS').AsInteger > 0;
    FProcParamRelationSupports := Query.FieldByName('PARAM_RELATIONS').AsInteger > 0;
    FCommentsSupports := Query.FieldByName('COMMENTS').AsInteger > 0;
  finally
    Query.Free;
  end;
  FCodePage := FInternalTransaction.DefaultDatabase.Capabilities.CodePage;
end;

procedure TMetaDataBase.SetOptionalColumns(Query: TFIBQuery; ObjectType: TDBObjectType);
begin
  case ObjectType of
    otGenerator, otRole:
      if FCommentsSupports then
        Query.ParamByName('DESCRIPTION').AsString := DescriptionColumn;
    otProcedure:
      if FPackagesSupports then
        Query.ParamByName('PACK_NAME').AsString := PackageNameColumn;
  end;
end;

function TMetaDataBase.ProcFieldsSQL: string;
begin
  if not FProcParamDomainSupports then
    Result := QRYProcFields
  else if not FProcParamRelationSupports then
    Result := QRYProcFieldsDomain
  else if not FPackagesSupports then
    Result := QRYProcFieldsRelation
  else
    Result := QRYProcFieldsRelation + ProcFieldsPackageFilter;
  Result := Result + ProcFieldsOrder;
end;

function TMetaDataBase.UDFFieldsSQL: string;
begin
  Result := QRYUDFFields;
  if FPackagesSupports then
    Result := Result + UDFFieldsPackageFilter;
  Result := Result + UDFFieldsOrder;
end;

function TMetaDataBase.CommentsIncluded(Options: TDDLTextOptions): boolean;
begin
  Result := (dtoIncludeComments in Options) and FCommentsSupports;
end;

function TMetaDataBase.CommentFits(const Statement, Text: string): boolean;
const
  // Bytes in the charset of the connection
  MaxLiteralLength = 65535;
  MaxStatementLength = 65533;
begin
  // Firebird 3 and later limit the literal, older servers the statement
  if FStoredFunctionsSupports then
    Result := EncodedLength(Text, FCodePage) <= MaxLiteralLength
  else
    Result := EncodedLength(Statement, FCodePage) <= MaxStatementLength;
end;

procedure TMetaDataBase.GenerateDDLText(Stream: TStringStream);
begin
  { if not FLoaded then
    begin
    Clear;
    LoadFromDatabase(FInternalTransaction.DefaultDatabase);
    end; }
  ExtGenerateDDLText(Stream, FDDLTextOptions)
end;

{ (otDomain, otTable, otView, otProcedure, otGenerator,
  otException, otUDF, otRole,otDBTrigger,motGrants) }

const
  QRY_NAMES: array [TDBObjectType] of string = (
    QRYDomains,
    QRYTables,
    QRYViews,
    QRYProcedures,
    QRYGenerators,
    QRYExceptions,
    QRYUDFs,
    QRYRoles,
    QRYDBTriggers,
    QRYStoredFuncsFB3,
    QRYPackages,
    'DB_DUMM'
  );

  QRY_NAMES_Where: array [TDBObjectType] of string = (
    'RDB$FIELD_NAME=:N',
    'REL.RDB$RELATION_NAME=:N',
    'REL.RDB$RELATION_NAME=:N',
    'RDB$PROCEDURE_NAME=:N',
    'RDB$GENERATOR_NAME=:N',
    'RDB$EXCEPTION_NAME=:N',
    'RDB$FUNCTION_NAME=:N',
    'RDB$ROLE_NAME=:N',
    'T.RDB$TRIGGER_NAME=:N',
    'RDB$FUNCTION_NAME=:N',
    'RDB$PACKAGE_NAME=:N',
    'DB_DUMM'
  );

  MetaNodeClasses: array [TDBObjectType] of TMetaObjectClass = (
    TMetaDomain,
    TMetaTable,
    TMetaView,
    TMetaProcedure,
    TMetaGenerator,
    TMetaException,
    TMetaUDF,
    TMetaRole,
    TMetaDBTrigger,
    TMetaStoredFunc,
    TMetaPackage,
    TMetaDataBase
  );

function TMetaDataBase.GetDBObject(DB: TFIBDatabase; ObjectType: TDBObjectType;
  const ObjectName: string; ForceLoad: boolean): TCustomMetaObject;
var
  SavedName: string;
  QNames, QFields, QFuncInputs, QCharset: TFIBQuery;
  QPrimary: TFIBQuery;
  QIndex, QForeign, QCheck, QTrigger: TFIBQuery;
  ClassOfNode: TMetaObjectClass;
begin
  if ObjectType = otDatabase then
  begin
    Result := nil;
    Exit;
  end;
  SavedName := SavedMetaObjectName(ObjectName);
  Result := GetChildObjectByName(Ord(ObjectType), SavedName);
  // if (Result=nil) and ForceLoad then
  if ForceLoad or (Result <> nil) and (not Result.Loaded) then
  begin
    if (Result <> nil) and Result.Loaded then
      Result.Clear;
    QNames := nil;
    QCharset := nil;
    QFields := nil;
    QFuncInputs := nil;
    QPrimary := nil;
    QIndex := nil;
    QForeign := nil;
    QCheck := nil;
    QTrigger := nil;
    if FInternalTransaction.Active then
      FInternalTransaction.Commit;
    FInternalTransaction.DefaultDatabase := DB;
    try
      DetectServerFeatures;
      if (ObjectType = otTable) and FTabRelTypeSupports then
        QNames := CreateQuery(QRYSysTablesRel, FInternalTransaction)
      else
        QNames := CreateQuery(QRY_NAMES[ObjectType], FInternalTransaction);
      QNames.MainWhereClause := QRY_NAMES_Where[ObjectType];
      if FPackagesSupports and (ObjectType in [otProcedure, otStoredFunctions, otUDF]) then
        QNames.MainWhereClause := QNames.MainWhereClause + ' and RDB$PACKAGE_NAME IS NULL';
      // A PSQL function of Firebird 3 and later is not an external one
      if FStoredFunctionsSupports and (ObjectType = otUDF) then
        QNames.MainWhereClause := QNames.MainWhereClause + ' and RDB$FUNCTION_SOURCE IS NULL';
      SetOptionalColumns(QNames, ObjectType);
      QNames.ParamByName('N').AsString := SavedName;

      QNames.ExecQuery;
      if not QNames.Eof then
      begin
        if ObjectType in [otDomain, otUDF, otTable, otView, otProcedure, otStoredFunctions, otPackage] then
          QCharset := CreateQuery(QRYCharset, FInternalTransaction);

        ClassOfNode := MetaNodeClasses[ObjectType];
        if not Assigned(Result) then
          Result := ClassOfNode.Create(Self);

        case ObjectType of
          otDomain: TMetaDomain(Result).LoadFromDataBase(QNames, QCharset);
          otTable:
            begin
              if FIdentityFieldsSupports then
                QFields := CreateQuery(QRYTableFieldsFB3, FInternalTransaction)
              else
                QFields := CreateQuery(QRYTableFields, FInternalTransaction);
              QPrimary := CreateQuery(QRYUnique, FInternalTransaction);
              QIndex := CreateQuery(QRYIndex, FInternalTransaction);
              QForeign := CreateQuery(QRYForeign, FInternalTransaction);
              QCheck := CreateQuery(QRYCheck, FInternalTransaction);
              QTrigger := CreateQuery(QRYTrigger, FInternalTransaction);
              TMetaTable(Result).LoadFromDataBase(QNames, QFields, QCharset,
                QPrimary, QIndex, QForeign, QCheck, QTrigger, [soTableFields, soTableFields, soPrimaryKey, soForeignKey,
                soTableTriggers, soUniqueConstr, soIndex, soCheckConstr])
            end;

          otGenerator: TMetaGenerator(Result).LoadFromDataBase(QNames);
          otUDF:
            begin
              QFields := CreateQuery(UDFFieldsSQL, FInternalTransaction);
              TMetaUDF(Result).LoadFromDataBase(QNames, QFields, QCharset);
            end;
          otView:
            begin
              QFields := CreateQuery(QRYTableFields, FInternalTransaction);
              QTrigger := CreateQuery(QRYTrigger, FInternalTransaction);
              TMetaView(Result).LoadFromDataBase(QNames, QFields, QTrigger, QCharset, [soViewFields, soViewTriggers])
            end;
          otProcedure:
            begin
              QFields := CreateQuery(ProcFieldsSQL, FInternalTransaction);
              TMetaProcedure(Result).LoadFromDataBase(QNames, QFields, QCharset,
                FProcParamDomainSupports, FProcParamRelationSupports)
            end;
          otException: TMetaException(Result).LoadFromDataBase(QNames);
          otRole: TMetaRole(Result).LoadFromDataBase(QNames);
          otDBTrigger: TCustomMetaTrigger(Result).LoadFromDataBase(QNames);
          otStoredFunctions:
            begin
              QFields := CreateQuery(QRYStoredFuncFieldsFB3Out, FInternalTransaction);
              QFuncInputs := CreateQuery(QRYStoredFuncFieldsFB3In, FInternalTransaction);
              TMetaStoredFunc(Result).LoadFromDataBase(QNames, QFields, QFuncInputs, QCharset);
            end;
          otPackage: TMetaPackage(Result).LoadFromDataBase(QNames, QCharset);
        end;
      end
    finally
      if FInternalTransaction.Active then
        FInternalTransaction.Commit;
      QCharset.Free;
      QFields.Free;
      QFuncInputs.Free;
      QNames.Free;
      QPrimary.Free;
      QIndex.Free;
      QForeign.Free;
      QCheck.Free;
      QTrigger.Free;
    end;
  end;
end;

class function TMetaDataBase.ClassIndex: Integer;
begin
  Result := Ord(otDatabase);
end;

{ TMetaConstraint }

function TMetaConstraint.GetFields(const Index: Integer): TMetaTableField;
begin
  Assert((Index >= 0) and (Index < FieldsCount), IntToStr(Index) + ' ' + ClassName);
  Result := TMetaTable(FOwner).Fields[FFields[Index]];
end;

function TMetaConstraint.GetFieldsCount: Integer;
begin
  Result := Integer(Length(FFields));
end;

class function TMetaConstraint.IsSubObject: boolean;
begin
  Result := True
end;

{ TMetaUniqueConstraint }

class function TMetaUniqueConstraint.ClassIndex: Integer;
begin
  Result := Ord(soUniqueConstr)
end;

procedure TMetaUniqueConstraint.GenerateObjectDDL(Stream: TStringStream);
var
  I: Integer;
begin
  Stream.WriteString(Format('ALTER TABLE %s ADD UNIQUE (', [TMetaTable(FOwner).FormatName]));
  for I := 0 to FieldsCount - 1 do
  begin
    Stream.WriteString(Fields[I].FormatName);
    if I <> FieldsCount - 1 then
      Stream.WriteString(', ');
  end;
  Stream.WriteString(')');
end;

{ TMetaPrimaryKey }

procedure TMetaPrimaryKey.LoadFromDataBase(Q: TFIBQuery);
var
  I: Integer;
begin
  Name := Q.Fields[0].AsString;
  I := 0;
  SetLength(FFields, 10000);
  while not Q.Eof do
  begin
    FFields[I] := TMetaTable(FOwner).FindFieldIndex(Trim(Q.Fields[1].AsString));
    Inc(I);
    Q.Next
  end;
  SetLength(FFields, I);
  FLoaded := True
end;

procedure TMetaPrimaryKey.GenerateObjectDDL(Stream: TStringStream);
var
  I: Integer;
begin
  if Copy(FName, 0, 6) = 'INTEG_' then
    Stream.WriteString(Format('ALTER TABLE %s ADD PRIMARY KEY (', [TMetaTable(FOwner).FormatName]))
  else
    Stream.WriteString(Format('ALTER TABLE %s ADD CONSTRAINT %s PRIMARY KEY (',
      [TMetaTable(FOwner).FormatName, FormatName]));
  for I := 0 to FieldsCount - 1 do
  begin
    Stream.WriteString(Fields[I].FormatName);
    if I <> FieldsCount - 1 then
      Stream.WriteString(', ');
  end;
  Stream.WriteString(')');
end;

class function TMetaPrimaryKey.ClassIndex: Integer;
begin
  Result := Ord(soPrimaryKey)
end;

{ TMetaIndex }

class function TMetaIndex.ClassIndex: Integer;
begin
  Result := Ord(soIndex)
end;

function TMetaIndex.CommentKeyword: string;
begin
  Result := 'INDEX';
end;

procedure TMetaIndex.GenerateObjectDDL(Stream: TStringStream);
var
  I: Integer;
  Unique, Order: string;
begin
  if FUnique then
    Unique := ' UNIQUE';
  if FOrder = IoDescending then
    Order := ' DESCENDING';

  Stream.WriteString(Format('CREATE%s%s INDEX %s ON %s (', [Order, Unique, FormatName, TMetaTable(FOwner).FormatName]));

  for I := 0 to FieldsCount - 1 do
  begin
    Stream.WriteString(Fields[I].FormatName);
    if I <> FieldsCount - 1 then
      Stream.WriteString(', ');
  end;
  Stream.WriteString(')');
  if not FActive then
    Stream.WriteString(Format('%sALTER INDEX %s INACTIVE', [sLineBreak, FormatName]));
end;

{ TMetaForeignKey }

function TMetaForeignKey.GetForFields(const Index: Integer): TMetaTableField;
begin
  Assert((Index >= 0) and (Index < ForFieldsCount));
  Result := ForTable.Fields[FForFields[Index]];
end;

function TMetaForeignKey.GetForFieldsCount: Integer;
begin
  Result := Integer(Length(FForFields));
end;

function TMetaForeignKey.GetForTable: TMetaTable;
begin
  Result := MetaDataBase.Tables[FForTable];
end;

procedure TMetaForeignKey.GenerateObjectDDL(Stream: TStringStream);
var
  I: Integer;
begin
  if Copy(FName, 0, 6) = 'INTEG_' then
    Stream.WriteString(Format('ALTER TABLE %s ADD FOREIGN KEY (', [TMetaTable(FOwner).FormatName]))
  else
    Stream.WriteString(Format('ALTER TABLE %s ADD CONSTRAINT %s ' + sLineBreak +
      ' FOREIGN KEY (', [TMetaTable(FOwner).FormatName, FormatName]));

  for I := 0 to FieldsCount - 1 do
  begin
    Stream.WriteString(Fields[I].FormatName);
    if I <> FieldsCount - 1 then
      Stream.WriteString(', ');
  end;
  Stream.WriteString(Format(') REFERENCES %s (', [ForTable.FormatName]));
  for I := 0 to ForFieldsCount - 1 do
  begin
    Stream.WriteString(ForFields[I].FormatName);
    if I <> ForFieldsCount - 1 then
      Stream.WriteString(', ');
  end;
  Stream.WriteString(')');

  case OnDelete of
    fkrCascade: Stream.WriteString(' ON DELETE CASCADE');
    fkrSetNull: Stream.WriteString(' ON DELETE SET NULL');
    fkrSetDefault: Stream.WriteString(' ON DELETE SET DEFAULT');
  end;

  case OnUpdate of
    fkrCascade: Stream.WriteString(' ON UPDATE CASCADE');
    fkrSetNull: Stream.WriteString(' ON UPDATE SET NULL');
    fkrSetDefault: Stream.WriteString(' ON UPDATE SET DEFAULT');
  end;

  // Stream.WriteString(NewLine);
end;

class function TMetaForeignKey.ClassIndex: Integer;
begin
  Result := Ord(soForeignKey)
end;

{ TMetaCheckConstraint }

class function TMetaCheckConstraint.ClassIndex: Integer;
begin
  Result := Ord(soCheckConstr)
end;

procedure TMetaCheckConstraint.GenerateObjectDDL(Stream: TStringStream);
begin
  Stream.WriteString(Format('ALTER TABLE %s ADD %s', [TMetaTable(FOwner).FormatName, FConstraint]));
end;

{ TCustomMetaTrigger }

class function TCustomMetaTrigger.DecodePrefix(Value: Integer): TTriggerType;
begin
  if Value < 1000 then
    Result := TTriggerType((Value + 1) and 1)
  else
    Result := TTriggerType(2)
end;

class function TCustomMetaTrigger.DecodeSuffixes(Value: Integer): TTriggerActions;
var
  V, Slot: Integer;
begin
  Result := [];
  if Value < 1000 then
  begin
    for Slot := 1 to 3 do
    begin
      V := ((Value + 1) shr (Slot * 2 - 1)) and 3;
      if V > 0 then
        Include(Result, TTriggerAction(V - 1));
    end
  end
  else
    Include(Result, TTriggerAction(3 + Byte(Value)));
end;

procedure TCustomMetaTrigger.LoadFromDataBase(Q: TFIBQuery);
begin
  Name := Q.Fields[0].AsString;
  FSource := Q.Fields[1].AsString;
  FPosition := Q.Fields[2].AsShort;
  FPrefix := DecodePrefix(Q.Fields[3].AsInteger);
  FSuffix := DecodeSuffixes(Q.Fields[3].AsInteger);
  FActive := Q.Fields[4].AsInteger = 0;
  LoadDescription(Q);
  FLoaded := True
end;

function TCustomMetaTrigger.CommentKeyword: string;
begin
  Result := 'TRIGGER';
end;

procedure TCustomMetaTrigger.SaveFakeDDL(Stream: TStringStream);
var
  Count: Smallint;
  Suf: TTriggerAction;
begin
  // For Updateble View
  if FPrefix <> ttON then
  begin
    Stream.WriteString(Format('CREATE TRIGGER %s FOR %s%s', [FormatName, FOwner.FormatName, sLineBreak]));
  end
  else
  begin
    Stream.WriteString(Format('CREATE TRIGGER %s%s', [FormatName, sLineBreak]));
  end;

  if FActive then
    Stream.WriteString('ACTIVE ');

  Stream.WriteString(TriggerPrefixes[FPrefix] + ' ');
  Count := 0;
  for Suf := taInsert to taTransactionRollback do
    if Suf in FSuffix then
    begin
      Inc(Count);
      if Count > 1 then
        Stream.WriteString(' OR ');
      Stream.WriteString(TriggerSuffixes[Suf]);
    end;
  Stream.WriteString(Format(' POSITION %d%s%s', [FPosition, sLineBreak, 'AS BEGIN  POST_EVENT ''FAKE''; END']));
end;

procedure TCustomMetaTrigger.SaveAlterDDL(Stream: TStringStream);
begin
  Stream.WriteString(Format('ALTER TRIGGER %s%s', [FormatName, sLineBreak]));
  if FActive then
    Stream.WriteString('ACTIVE ');
  Stream.WriteString(Format(' %s%s', [sLineBreak, FSource]));
end;

class function TCustomMetaTrigger.IsSubObject: boolean;
begin
  Result := True
end;

procedure TCustomMetaTrigger.GenerateObjectDDL(Stream: TStringStream);
var
  Count: Smallint;
  Suf: TTriggerAction;
begin
  if FPrefix <> ttON then
  begin
    Stream.WriteString(Format('CREATE TRIGGER %s FOR %s%s', [FormatName, FOwner.FormatName, sLineBreak]));
  end
  else
  begin
    Stream.WriteString(Format('CREATE TRIGGER %s%s', [FormatName, sLineBreak]));
  end;

  if FActive then
    Stream.WriteString('ACTIVE ');

  Stream.WriteString(TriggerPrefixes[FPrefix] + ' ');
  Count := 0;
  for Suf := taInsert to taTransactionRollback do
    if Suf in FSuffix then
    begin
      Inc(Count);
      if Count > 1 then
        Stream.WriteString(' OR ');
      Stream.WriteString(TriggerSuffixes[Suf]);
    end;
  // Stream.WriteString(Format(' POSITION %d%s', [FPosition, NewLine,FSource]));
  Stream.WriteString(' POSITION ' + IntToStr(FPosition) + sLineBreak + FSource);
end;

{ TMetaTableGrant }

class function TMetaTableGrant.ClassIndex: Integer;
begin
  Result := Ord(soTableGrants)
end;

{ TMetaProcGrant }

class function TMetaProcGrant.ClassIndex: Integer;
begin
  Result := Ord(soProcGrants)
end;

{ TMetaViewGrant }

class function TMetaViewGrant.ClassIndex: Integer;
begin
  Result := Ord(soViewGrants)
end;

{ TMetaTableTrigger }

class function TMetaTableTrigger.ClassIndex: Integer;
begin
  Result := Ord(soTableTriggers)
end;

{ TMetaViewTrigger }

class function TMetaViewTrigger.ClassIndex: Integer;
begin
  Result := Ord(soViewTriggers)
end;

{ TMetaDBTrigger }

class function TMetaDBTrigger.ClassIndex: Integer;
begin
  Result := Ord(otDBTrigger)
end;

class function TMetaDBTrigger.IsSubObject: boolean;
begin
  Result := False
end;
{ TMetaRoleGrant }

class function TMetaRoleGrant.ClassIndex: Integer;
begin
  Result := Ord(soRoleGrants)
end;

{ TMetaView }

constructor TMetaView.Create(AOwner: TCustomMetaObject; aName: string = '');
begin
  inherited Create(AOwner, aName);
  AddClass(TMetaField);
  AddClass(TCustomMetaTrigger);
  AddClass(TCustomMetaGrant);
end;

function TMetaView.GetFields(const Index: Integer): TMetaField;
begin
  Result := TMetaField(GetChildObject(Ord(soViewFields), Index))
end;

function TMetaView.GetFieldsCount: Integer;
begin
  Result := GetChildsCount(Ord(soViewFields));
end;

function TMetaView.GetTriggers(const Index: Integer): TCustomMetaTrigger;
begin
  Result := TCustomMetaTrigger(GetChildObject(Ord(soViewTriggers), Index))
end;

function TMetaView.GetTriggersCount: Integer;
begin
  Result := GetChildsCount(Ord(soViewTriggers));
end;

procedure TMetaView.LoadFromDataBase(QName, QFields, QTriggers: TFIBQuery; QCharset: TFIBQuery; ChildTypes: TViewChildTypes);
begin
  Name := QName.Fields[0].AsString;
  FSource := Trim(QName.Fields[1].AsString);
  LoadDescription(QName);

  // FIELD
  if soViewFields in ChildTypes then
  begin
    QFields.Params[0].AsString := FName;
    QFields.ExecQuery;
    while not QFields.Eof do
    begin
      TMetaField.Create(Self).LoadFromDataBase(QFields, QCharset);
      QFields.Next;
    end;
    QFields.Close
  end;

  // TRIGGER
  if soViewTriggers in ChildTypes then
  begin
    QTriggers.Params[0].AsString := FName;
    QTriggers.ExecQuery;
    while not QTriggers.Eof do
    begin
      TMetaViewTrigger.Create(Self).LoadFromDataBase(QTriggers);
      QTriggers.Next;
    end;
  end;
  FLoaded := True
end;

procedure TMetaView.GenerateDDLText(Stream: TStringStream);
begin
  inherited GenerateDDLText(Stream);
  GenerateChildDDL(Stream, Ord(soViewTriggers));
end;

procedure TMetaView.GenerateObjectDDL(Stream: TStringStream);
var
  I: Integer;
begin
  Stream.WriteString(Format('CREATE VIEW %s (', [FormatName]));
  for I := 0 to FieldsCount - 1 do
  begin
    Stream.WriteString(sLineBreak + '   ' + Fields[I].FormatName);
    if I <> FieldsCount - 1 then
      Stream.WriteString(',');
  end;
  Stream.WriteString(sLineBreak + ')' + sLineBreak + 'AS' + sLineBreak);
  Stream.WriteString(Source);
end;

function TMetaView.GetGrants(const Index: Integer): TCustomMetaGrant;
begin
  Result := TCustomMetaGrant(GetChildObject(Ord(soViewGrants), Index));
end;

function TMetaView.GetGrantsCount: Integer;
begin
  Result := GetChildsCount(Ord(soViewGrants));
end;

class function TMetaView.ClassIndex: Integer;
begin
  Result := Ord(otView)
end;

function TMetaView.CommentKeyword: string;
begin
  Result := 'VIEW';
end;

procedure TMetaView.GenerateCommentDDL(Stream: TStringStream);
begin
  inherited GenerateCommentDDL(Stream);
  GenerateChildCommentDDL(Stream, Ord(soViewFields));
  GenerateChildCommentDDL(Stream, Ord(soViewTriggers));
end;

{ TMetaDomain }

procedure TMetaDomain.GenerateObjectDDL(Stream: TStringStream);
begin
  // Stream.WriteString(Format('CREATE DOMAIN %s AS ', [FormatName]));
  Stream.WriteString('CREATE DOMAIN ');
  inherited GenerateObjectDDL(Stream);

end;

class function TMetaDomain.ClassIndex: Integer;
begin
  Result := Ord(otDomain)
end;

class function TMetaDomain.IsSubObject: boolean;
begin
  Result := False
end;

function TMetaDomain.CommentKeyword: string;
begin
  Result := 'DOMAIN';
end;

function TMetaDomain.CommentTarget: string;
begin
  Result := FormatName;
end;
{ TMetaProcedure }

constructor TMetaProcedure.Create(AOwner: TCustomMetaObject; aName: string = '');
begin
  inherited Create(AOwner, aName);
  AddClass(TMetaProcInField); // in
  AddClass(TMetaProcOutField); // out
  AddClass(TCustomMetaGrant); // grant
end;

function TMetaProcedure.GetInputFields(const Index: Integer): TMetaProcInField;
begin
  Result := TMetaProcInField(GetChildObject(Ord(soProcFieldIn), Index))
end;

function TMetaProcedure.GetInputFieldsCount: Integer;
begin
  Result := GetChildsCount(Ord(soProcFieldIn));
end;

function TMetaProcedure.GetOutputFields(const Index: Integer): TMetaProcOutField;
begin
  Result := TMetaProcOutField(GetChildObject(Ord(soProcFieldOut), Index))
end;

function TMetaProcedure.GetOutputFieldsCount: Integer;
begin
  Result := GetChildsCount(Ord(soProcFieldOut));
end;

procedure TMetaProcedure.InternalSaveToDDL(Stream: TStringStream; Operation: string);
var
  I: Integer;
begin
  Stream.WriteString(Format('%s PROCEDURE %s', [Operation, FormatName]));
  if InputFieldsCount > 0 then
  begin
    Stream.WriteString(' (');
    for I := 0 to InputFieldsCount - 1 do
    begin
      Stream.WriteString(sLineBreak + '   ');
      InputFields[I].GenerateObjectDDL(Stream);
      if I <> InputFieldsCount - 1 then
        Stream.WriteString(',');
    end;
    Stream.WriteString(')');
  end;

  if OutputFieldsCount > 0 then
  begin
    Stream.WriteString(Format('%sRETURNS (', [sLineBreak]));
    for I := 0 to OutputFieldsCount - 1 do
    begin
      Stream.WriteString(sLineBreak + '   ');
      OutputFields[I].GenerateObjectDDL(Stream);
      if I <> OutputFieldsCount - 1 then
        Stream.WriteString(',');
    end;
    Stream.WriteString(')');
  end;
end;

procedure TMetaProcedure.LoadFromDataBase(QNames, QFields: TFIBQuery;
  QCharset: TFIBQuery; CanUseParamDomain, CanUseProcParamRelation: boolean);
var
  Field, PackageParam: TFIBXSQLVAR;
begin
  Name := QNames.Fields[0].AsString;
  FSource := QNames.Fields[1].AsString;
  Field := QNames.FindField('RDB$PACKAGE_NAME');
  if Field <> nil then
    FPackageName := Field.AsString;
  LoadDescription(QNames);

  QFields.Params[0].AsString := FName;
  PackageParam := QFields.FindParam('PN');
  if PackageParam <> nil then
    PackageParam.AsString := FPackageName;

  // Extract In params
  QFields.Params[1].AsInteger := 0; // in
  QFields.ExecQuery;
  while not QFields.Eof do
  begin
    TMetaProcInField.Create(Self).DoLoadFromQuery(QFields, QCharset, CanUseParamDomain, CanUseProcParamRelation);
    QFields.Next;
  end;
  QFields.Close;

  // Extract Out params
  QFields.Params[1].AsInteger := 1; // out
  QFields.ExecQuery;
  while not QFields.Eof do
  begin
    TMetaProcOutField.Create(Self).DoLoadFromQuery(QFields, QCharset, CanUseParamDomain, CanUseProcParamRelation);
    QFields.Next;
  end;
  QFields.Close;
  FLoaded := True

end;

procedure TMetaProcedure.SaveToAlterDDL(Stream: TStringStream);
begin
  InternalSaveToDDL(Stream, 'ALTER');
  Stream.WriteString(sLineBreak + 'AS ');
  Stream.WriteString(FSource);
end;

procedure TMetaProcedure.SaveToPostDDL(Stream: TStringStream);
begin
  InternalSaveToDDL(Stream, 'CREATE');
  Stream.WriteString(sLineBreak + 'AS' + sLineBreak + 'BEGIN' + sLineBreak + '  SUSPEND;' + sLineBreak + 'END');
end;

procedure TMetaProcedure.GenerateObjectDDL(Stream: TStringStream);
begin
  InternalSaveToDDL(Stream, 'CREATE');
  Stream.WriteString(sLineBreak + 'AS' + sLineBreak);
  Stream.WriteString(FSource);
end;

function TMetaProcedure.GetGrants(const Index: Integer): TCustomMetaGrant;
begin
  Result := TCustomMetaGrant(GetChildObject(Ord(soProcGrants), Index));
end;

function TMetaProcedure.GetGrantsCount: Integer;
begin
  Result := GetChildsCount(Ord(soProcGrants));
end;

class function TMetaProcedure.ClassIndex: Integer;
begin
  Result := Ord(otProcedure)
end;

function TMetaProcedure.CommentKeyword: string;
begin
  Result := 'PROCEDURE';
end;

function TMetaProcedure.CommentTarget: string;
begin
  Result := RoutineName(FPackageName, FormatName);
end;

procedure TMetaProcedure.GenerateCommentDDL(Stream: TStringStream);
begin
  inherited GenerateCommentDDL(Stream);
  GenerateChildCommentDDL(Stream, Ord(soProcFieldIn));
  GenerateChildCommentDDL(Stream, Ord(soProcFieldOut));
end;

{ TMetaException }

procedure TMetaException.LoadFromDataBase(QName: TFIBQuery);
begin
  Name := QName.Fields[0].AsString;
  FMessage := QName.Fields[1].AsString;
  FNumber := QName.Fields[2].AsInteger;
  LoadDescription(QName);
  FLoaded := True
end;

procedure TMetaException.GenerateObjectDDL(Stream: TStringStream);
begin
  Stream.WriteString(' CREATE EXCEPTION ' + FormatName + ' ' + QuotedStr(FMessage) + ' ');
end;

function TMetaException.CommentKeyword: string;
begin
  Result := 'EXCEPTION';
end;

class function TMetaException.ClassIndex: Integer;
begin
  Result := Ord(otException)
end;

{ TMetaUDF }

constructor TMetaUDF.Create(AOwner: TCustomMetaObject; aName: string = '');
begin
  inherited Create(AOwner, aName);
  AddClass(TMetaUDFField);
end;

procedure TMetaUDF.GenerateObjectDDL(Stream: TStringStream);
var
  I, C: Integer;
begin
  Stream.WriteString(Format('DECLARE EXTERNAL FUNCTION %s', [FormatName]));
  C := 0;

  if FReturn = 0 then
  begin // return position
    for I := 0 to FieldsCount - 1 do
      if Fields[I].Position <> Return then
      begin
        if C > 0 then
          Stream.WriteString(',');
        Stream.WriteString(sLineBreak + '  ');
        Fields[I].GenerateObjectDDL(Stream);
        Inc(C);
      end;
    for I := 0 to FieldsCount - 1 do
      if Fields[I].Position = Return then
      begin
        Stream.WriteString(sLineBreak + '  RETURNS ');
        Fields[I].GenerateObjectDDL(Stream);
        Break;
      end;
  end
  else
  begin
    for I := 0 to FieldsCount - 1 do
    begin
      if C > 0 then
        Stream.WriteString(',');
      Stream.WriteString(sLineBreak + '  ');
      Fields[I].GenerateObjectDDL(Stream);
      Inc(C);
    end;
    Stream.WriteString(Format('%s  RETURNS PARAMETER %d', [sLineBreak, FReturn]));
  end;

  Stream.WriteString(Format('%s  ENTRY_POINT ''%s'' MODULE_NAME ''%s''', [sLineBreak, FEntry, FModule]));
end;

procedure TMetaUDF.LoadFromDataBase(QNames, QFields: TFIBQuery; QCharset: TFIBQuery);
begin
  Name := QNames.Fields[0].AsString;
  FModule := QNames.Fields[1].AsString;
  FEntry := Trim(QNames.Fields[2].AsString);
  FReturn := QNames.Fields[3].AsShort;
  LoadDescription(QNames);

  QFields.Params[0].AsString := QNames.Fields[0].AsString;
  QFields.ExecQuery;
  while not QFields.Eof do
  begin
    TMetaUDFField.Create(Self).LoadFromDataBase(QFields, QCharset);
    QFields.Next;
  end;
  QFields.Close;
  FLoaded := True
end;

function TMetaUDF.GetFields(const Index: Integer): TMetaUDFField;
begin
  Result := TMetaUDFField(GetChildObject(Ord(soUDFField), Index))
end;

function TMetaUDF.GetFieldsCount: Integer;
begin
  Result := GetChildsCount(Ord(soUDFField));
end;

class function TMetaUDF.ClassIndex: Integer;
begin
  Result := Ord(otUDF)
end;

function TMetaUDF.CommentKeyword: string;
begin
  Result := 'EXTERNAL FUNCTION';
end;

{ TMetaTableField }

function TMetaTableField.GetDomain: TMetaDomain;
begin
  if FDomain >= 0 then
    Result := MetaDataBase.Domains[FDomain]
  else
    Result := nil;
end;

procedure TMetaTableField.LoadFromDataBase(Q: TFIBQuery; C: TFIBQuery);
var
  QDims: TFIBQuery;
  J: Integer;
begin
  inherited LoadFromDataBase(Q, C);
  FNotNull := (Q.Fields[8].AsInteger = 1);
  if not Q.Fields[9].IsNull then
    FDefaultValue := CutDefaultValue(Q.Fields[9].AsString)
  else
    FDefaultValue := '';

  FDomain := -1;
  if not(Self is TMetaDomain) then
  begin
    if not(Q.Fields[10].IsNull or (Copy(Q.Fields[10].AsString, 1, 4) = 'RDB$')) then
    begin
      FDomainName := Q.Fields[10].AsString;
      FDomain := MetaDataBase.FindDomainIndex(FDomainName);
    end;
    FComputedSource := Q.Fields[11].AsString;

  end
  else if not Q.Fields[11].IsNull then
    FValidationSource := Q.Fields[11].AsString
  else
    FValidationSource := '';

  FIsArray := Q.Fields[12].AsInteger <> 0;
  SetLength(FDimensions, Q.Fields[12].AsInteger);

  if FIsArray then
  begin
    QDims := CreateQuery(QRYFieldDimensions, Q.Transaction);
    try
      if not(Self is TMetaDomain) then
        QDims.Params[0].AsString := Q.Fields[10].AsString
      else
        QDims.Params[0].AsString := FName;
      QDims.ExecQuery;
      J := 0;
      while not QDims.Eof do
      begin
        FDimensions[J].LOWER_BOUND := QDims.Fields[1].AsInteger;
        FDimensions[J].UPPER_BOUND := QDims.Fields[2].AsInteger;
        QDims.Next;
        Inc(J)
      end;
      QDims.Close;
    finally
      QDims.Free
    end
  end;

  FLoaded := True
end;

procedure TMetaTableField.GenerateObjectDDL(Stream: TStringStream);
begin
  if (FDomainName <> '') and not(dtoDecodeDomains in MetaDataBase.DDLTextOptions) then
  begin
    Stream.WriteString(FormatName + ' ');
    Stream.WriteString(FormatIdentifier(3, FDomainName))
  end
  else if FComputedSource <> '' then
  begin
    Stream.WriteString(FormatName + ' ');
    Stream.WriteString(' COMPUTED BY ' + FComputedSource)
  end
  else
    inherited GenerateObjectDDL(Stream);
  case FIdentity of
    0: Stream.WriteString(' GENERATED ALWAYS AS IDENTITY');
    1: Stream.WriteString(' GENERATED BY DEFAULT AS IDENTITY');
  else
    if FDefaultValue <> '' then
      Stream.WriteString(' DEFAULT ' + FDefaultValue);
    if FNotNull then
      Stream.WriteString(' NOT NULL');
    if FValidationSource <> '' then
      Stream.WriteString(sLineBreak + FValidationSource);
  end;
end;

class function TMetaTableField.ClassIndex: Integer;
begin
  Result := Ord(soTableFields)
end;

{ TMetaField }

procedure TMetaField.LoadFromDataBase(QField, QCharset: TFIBQuery);
begin
  inherited LoadFromDataBase(QField, QCharset);
  Name := QField.Fields[6].AsString;
  FSegmentLength := QField.Fields[7].AsShort;
end;

procedure TMetaField.GenerateObjectDDL(Stream: TStringStream);
begin
  if Self is TMetaDomain then
    Stream.WriteString(FormatName + ' AS ')
  else
    Stream.WriteString(FormatName + ' ');
  inherited GenerateObjectDDL(Stream);
end;

class function TMetaField.ClassIndex: Integer;
begin
  Result := Ord(soViewFields)
end;

function TMetaField.CommentKeyword: string;
begin
  Result := 'COLUMN';
end;

function TMetaField.CommentTarget: string;
begin
  // The owner gives its package, if any
  Result := FOwner.CommentTarget + '.' + FormatName;
end;

{ TMetaUDFField }

procedure TMetaUDFField.LoadFromDataBase(QField, QCharset: TFIBQuery);
begin
  inherited LoadFromDataBase(QField, QCharset);
  FPosition := QField.Fields[6].AsShort;
  FMechanism := QField.Fields[7].AsShort;
  Name := 'Field ' + IntToStr(FPosition);
  FLoaded := True
end;

procedure TMetaUDFField.GenerateObjectDDL(Stream: TStringStream);
begin
  if FFieldType = fftBlob then
    Stream.WriteString('BLOB')
  else
    inherited GenerateObjectDDL(Stream);
  case FMechanism of
    - 1: Stream.WriteString(' FREE_IT');
    0: Stream.WriteString(' BY VALUE');
    1: ; // BY REFERENCE = default
    2: Stream.WriteString(' BY DESCRIPTOR');
  end;
end;

class function TMetaUDFField.ClassIndex: Integer;
begin
  Result := Ord(soUDFField)
end;

{ TMetaRole }

procedure TMetaRole.LoadFromDataBase(QName: TFIBQuery);
begin
  Name := QName.Fields[0].AsString;
  FOwner := QName.Fields[1].AsString;
  LoadDescription(QName);
  FLoaded := True
end;

function TMetaRole.CommentKeyword: string;
begin
  Result := 'ROLE';
end;

procedure TMetaRole.GenerateObjectDDL(Stream: TStringStream);
begin
  Stream.WriteString(Format('CREATE ROLE %s /* By user %s */', [FormatName, Trim(FOwner)]));
end;

function TMetaRole.GetGrants(const Index: Integer): TCustomMetaGrant;
begin
  Result := TCustomMetaGrant(GetChildObject(Ord(soRoleGrants), Index));
end;

function TMetaRole.GetGrantsCount: Integer;
begin
  Result := GetChildsCount(Ord(soRoleGrants));
end;

constructor TMetaRole.Create(AOwner: TCustomMetaObject; aName: string = '');
begin
  inherited Create(AOwner, aName);
  AddClass(TCustomMetaGrant)

end;

class function TMetaRole.ClassIndex: Integer;
begin
  Result := Ord(otRole)
end;

{ TMetaProcField }

procedure TMetaProcField.DoLoadFromQuery(QField: TFIBQuery; QCharset: TFIBQuery; CanUseParamDomain, CanUseProcParamRelation: boolean);
var
  Check_PREFIX: string;
begin
  inherited LoadFromDataBase(QField, QCharset);
  FUseRelation := False;
  FDefaultValue := '';
  if CanUseParamDomain then
  begin
    FMechanizm := QField.Fields[8].AsShort;
    FDomain := QField.Fields[9].AsString;
    Check_PREFIX := Copy(FDomain, 1, 4);
    FUseDomain := (Check_PREFIX <> 'RDB$') and (Check_PREFIX <> 'SEC$');
    if CanUseProcParamRelation then
    begin
      FRelationObject := QField.Fields[11].AsString;
      FRelationField := QField.Fields[12].AsString;
      FUseRelation := System.Length(FRelationField) > 0;
      if not FUseDomain and not FUseRelation then
        FDefaultValue := QField.Fields[10].AsString
    end
    else if not FUseDomain then
      FDefaultValue := QField.Fields[10].AsString
  end
  else
    FUseDomain := False;

  FLoaded := True
end;

procedure TMetaProcField.GenerateObjectDDL(Stream: TStringStream);
begin
  if FUseDomain then
  begin
    Stream.WriteString(FormatName + ' ');
    case FMechanizm of
      0: Stream.WriteString(FormatIdentifier(3, FDomain));
      1: Stream.WriteString('TYPE OF ' + FDomain)
    end
  end
  else if FUseRelation then
  begin
    Stream.WriteString(FormatName + ' ');
    Stream.WriteString('TYPE OF COLUMN ' + FormatIdentifier(3, FRelationObject) +
      '.' + FormatIdentifier(3, FRelationField))
  end
  else
  begin
    inherited GenerateObjectDDL(Stream);
    if FDefaultValue <> '' then
      Stream.WriteString(' ' + FDefaultValue);

  end
end;

function TMetaProcField.CommentKeyword: string;
begin
  // Firebird 3 needs the routine kind when a procedure and a function have the same name
  if FOwner is TMetaStoredFunc then
    Result := 'FUNCTION PARAMETER'
  else if (MetaDataBase <> nil) and MetaDataBase.FStoredFunctionsSupports then
    Result := 'PROCEDURE PARAMETER'
  else
    Result := 'PARAMETER';
end;

{ TMetaProcInField }

class function TMetaProcInField.ClassIndex: Integer;
begin
  Result := Ord(soProcFieldIn)
end;
{ TMetaProcOutField }

class function TMetaProcOutField.ClassIndex: Integer;
begin
  Result := Ord(soProcFieldOut)
end;

{ TCustomMetaGrant }

type
  TDynStrArray = array of string;

procedure DeleteIndex(Index: Integer; var StringArray: TDynStrArray);
var
  I, L: NativeInt;
begin
  L := Length(StringArray) - 1;
  for I := Index to L - 1 do
    StringArray[I] := StringArray[I + 1];
  SetLength(StringArray, L)
end;

type
  TDynArray1 = array of boolean;

procedure DeleteIndexArr1(Index: Integer; var BooleanArray: TDynArray1);
var
  L: NativeInt;
begin
  L := Length(BooleanArray) - 1;
  if Index = L then
    SetLength(BooleanArray, L)
  else
  begin
    Move(BooleanArray[Index + 1], BooleanArray[Index], L - Index);
    SetLength(BooleanArray, L)
  end;
end;

procedure TCustomMetaGrant.GenerateObjectDDL(Stream: TStringStream);
var
  I: Integer;
  L: Integer;
  s: string;
begin
  L := Count - 1;
  for I := 0 to L do
  begin
    if FPrivileges[I] = [goRole] then
    begin
      Stream.WriteString('GRANT  ' + FormatIdentifier(3, FObjectName) + ' TO ');
      Stream.WriteString(sLineBreak + '  ' + FUserList[I]);
    end
    else if FPrivileges[I] = [goExecuteProc] then
    begin
      Stream.WriteString('GRANT EXECUTE ON PROCEDURE ' + FormatIdentifier(3, FObjectName) + ' TO');
      Stream.WriteString(sLineBreak + '  ' + FUserList[I]);
    end
    else
    begin
      if FPrivileges[I] = [] then
        Continue;
      Stream.WriteString('GRANT ');
      if FPrivileges[I] = [goSelect, goInsert, goUpdate, goDelete, goReferences] then
        Stream.WriteString('ALL ON ')
      else
      begin
        s := '';
        if goSelect in FPrivileges[I] then
          s := 'SELECT,';
        if goInsert in FPrivileges[I] then
          s := s + 'INSERT,';
        if goUpdate in FPrivileges[I] then
        begin
          s := s + 'UPDATE';
          if Length(FFields[I]) > 0 then
            s := s + '(' + FFields[I] + ')';
          s := s + ','
        end;
        if goDelete in FPrivileges[I] then
          s := s + 'DELETE,';
        if goReferences in FPrivileges[I] then
        begin
          s := s + 'REFERENCES';
          if Length(FFields[I]) > 0 then
            s := s + '(' + FFields[I] + ')';
          s := s + ','
        end;
        if Length(s) > 0 then
          SetLength(s, Length(s) - 1);
        Stream.WriteString(s + ' ON ')
      end;

      Stream.WriteString(FormatIdentifier(3, FObjectName));
      Stream.WriteString(' TO ' + sLineBreak + '  ');
      Stream.WriteString(FUserList[I]);
      if FWithGrantOption[I] then
        Stream.WriteString(' WITH GRANT OPTION');
    end;
    Stream.WriteString(DefTerminator + sLineBreak + sLineBreak)
  end;
end;

function TCustomMetaGrant.GetSize: Integer;
begin
  Result := Integer(Length(FUserList)) // grants of one object
end;

procedure TCustomMetaGrant.LoadFromDataBase(QGrants: TFIBQuery; const Name: string; Pack: boolean = True);
var
  I, L, J: Integer;
  s: string;
  CurUser: string;

begin
  FObjectName := Name;
  I := 0;
  L := 0;
  CurUser := '';
  while not QGrants.Eof do
  begin

    if L = 0 then
    begin
      L := 1000;
      SetSize(L);
    end;
    if I > L then
    begin
      Inc(L, 200);
      SetSize(L);
    end;

    CurUser := QGrants.Fields[0].AsString;
    s := QGrants.Fields[6].AsString;
    if (s <> 'USER') and (s <> 'ROLE') then
      CurUser := QGrants.Fields[6].AsString + ' ' + FormatIdentifier(3, CurUser);
    FUserList[I] := CurUser;
    // goSelect,goInsert,goUpdate,goDelete,goReference,goExecuteProc,goRole
    case QGrants.Fields[1].AsString[1] of
      'D': FPrivileges[I] := FPrivileges[I] + [goDelete];
      'I': FPrivileges[I] := FPrivileges[I] + [goInsert];
      'M': FPrivileges[I] := FPrivileges[I] + [goRole];
      'R': FPrivileges[I] := FPrivileges[I] + [goReferences];
      'S': FPrivileges[I] := FPrivileges[I] + [goSelect];
      'U': FPrivileges[I] := FPrivileges[I] + [goUpdate];
      'X': FPrivileges[I] := FPrivileges[I] + [goExecuteProc];
    else
      // FPrivileges[i]:=FPrivileges[i]+[goRole];
    end;
    FWithGrantOption[I] := QGrants.Fields[2].asBoolean;
    FFields[I] := FormatIdentifier(3, QGrants.Fields[3].AsString);
    if Pack and (I > 0) then
    begin
      if FUserList[I - 1] = FUserList[I] then
      begin
        if (FWithGrantOption[I - 1] = FWithGrantOption[I]) and (FFields[I - 1] = FFields[I]) then
        begin
          FPrivileges[I - 1] := FPrivileges[I - 1] + FPrivileges[I];
          FPrivileges[I] := [];
          Dec(I)
        end;
      end;
    end;
    Inc(I);
    QGrants.Next
  end;
  SetSize(I);
  if Pack then
  begin
    for I := Count - 1 downto 1 do
    begin
      for J := I - 1 downto 0 do
        if Length(FUserList[I]) < 1024 then
          if (FPrivileges[I] = FPrivileges[J]) and (FWithGrantOption[I] = FWithGrantOption[J])
          // and (FFields[i]=FFields[j])
            and (FUserList[J] = FUserList[I]) and (Length(FFields[J]) > 0) and (Length(FFields[I]) > 0) then
          begin
            // Pack  by Fields
            FFields[J] := FFields[J] + ',' + FFields[I];
            DeleteIndex(I, TDynStrArray(FUserList));
            DeleteIndex(I, TDynStrArray(FFields));
            DeleteIndexArr1(I, TDynArray1(FWithGrantOption));
            DeleteIndexArr1(I, TDynArray1(FPrivileges));
            Break
          end;
    end;

    for I := Count - 1 downto 1 do
    begin
      for J := I - 1 downto 0 do
        if Length(FUserList[I]) < 1024 then
          if (FPrivileges[I] = FPrivileges[J]) and (FWithGrantOption[I] = FWithGrantOption[J]) and
            (FFields[I] = FFields[J]) then
          begin
            if Length(FUserList[J]) + Length(FUserList[I]) < 100 then
              FUserList[J] := FUserList[J] + ',' + FUserList[I]
            else if (Length(FUserList[J]) mod 100 + Length(FUserList[I]) mod 100) > 100 then
              FUserList[J] := FUserList[J] + ',' + sLineBreak + '  ' + FUserList[I]
            else
              FUserList[J] := FUserList[J] + ',' + FUserList[I];
            DeleteIndex(I, TDynStrArray(FUserList));
            DeleteIndex(I, TDynStrArray(FFields));
            DeleteIndexArr1(I, TDynArray1(FWithGrantOption));
            DeleteIndexArr1(I, TDynArray1(FPrivileges));
            Break
          end;
    end;

  end;
  FLoaded := True
end;

procedure TCustomMetaGrant.SetSize(Size: Integer);
begin
  SetLength(FPrivileges, Size);
  SetLength(FWithGrantOption, Size);
  SetLength(FFields, Size);
  SetLength(FUserList, Size);
end;

{ TFIBDBSchemaExtract }

procedure TFIBDBSchemaExtract.Clear;
begin
  FMetaDatabase.Clear;
end;

constructor TFIBDBSchemaExtract.Create(AOwner: TComponent);
begin
  inherited;
  FMetaDatabase := TMetaDataBase.Create(nil);
  FMetaDatabase.OnLoadMetaData := DoOnLoadMetaData;
  FMetaDatabase.DDLTextOptions := DefSchemaExtractDDLTextOptions;
  FLoadOptions := TLoadOptions.Create;
end;

function TFIBDBSchemaExtract.GetDDLTextOptions: TDDLTextOptions;
begin
  Result := FMetaDatabase.DDLTextOptions;
end;

procedure TFIBDBSchemaExtract.SetDDLTextOptions(const Value: TDDLTextOptions);
begin
  FMetaDatabase.DDLTextOptions := Value;
end;

destructor TFIBDBSchemaExtract.Destroy;
begin
  FLoadOptions.Free;
  FMetaDatabase.Free;
  inherited;
end;

procedure TFIBDBSchemaExtract.SetLoadOptions(const Value: TLoadOptions);
begin
  FLoadOptions.Assign(Value);
end;

function TFIBDBSchemaExtract.ObjectByName(ObjectType: TDBObjectType; const ObjectName: string; ForceLoad: boolean): TCustomMetaObject;
begin
  Result := FMetaDatabase.GetDBObject(Database, ObjectType, ObjectName, ForceLoad)
end;

function TFIBDBSchemaExtract.GetObjectDDL(ObjectType: TDBObjectType; const ObjectName: string; ForceLoad: boolean = True): string;
var
  N: TCustomMetaObject;
begin
  N := FMetaDatabase.GetDBObject(Database, ObjectType, ObjectName, ForceLoad);
  if Assigned(N) then
    Result := N.AsDDL
  else
    Result := ''
end;

procedure TFIBDBSchemaExtract.DoOnLoadMetaData(Sender: TObject; const Message: string; var Stop: boolean);
begin
  if Assigned(FOnLoadMetaData) then
    FOnLoadMetaData(Sender, Message, Stop)
end;

function TFIBDBSchemaExtract.GetDDLText: string;
begin
  if not FFullLoaded then
  begin
    FMetaDatabase.Clear;
    LoadMetaData;
  end;
  Result := FMetaDatabase.AsDDL;
end;

function TFIBDBSchemaExtract.GetDomains(const Index: Integer): TMetaDomain;
begin
  Result := FMetaDatabase.GetDomains(Index)
end;

function TFIBDBSchemaExtract.GetDomainsCount: Integer;
begin
  Result := FMetaDatabase.GetDomainsCount
end;

function TFIBDBSchemaExtract.GetExceptions(const Index: Integer): TMetaException;
begin
  Result := FMetaDatabase.GetExceptions(Index)
end;

function TFIBDBSchemaExtract.GetExceptionsCount: Integer;
begin
  Result := FMetaDatabase.GetExceptionsCount
end;

function TFIBDBSchemaExtract.GetGenerators(const Index: Integer): TMetaGenerator;
begin
  Result := FMetaDatabase.GetGenerators(Index)
end;

function TFIBDBSchemaExtract.GetGeneratorsCount: Integer;
begin
  Result := FMetaDatabase.GetGeneratorsCount
end;

function TFIBDBSchemaExtract.GetPackageCount: Integer;
begin
  Result := FMetaDatabase.GetPackageCount
end;

function TFIBDBSchemaExtract.GetPackages(const Index: Integer): TMetaPackage;
begin
  Result := FMetaDatabase.GetPackages(Index)
end;

function TFIBDBSchemaExtract.GetProcedures(const Index: Integer): TMetaProcedure;
begin
  Result := FMetaDatabase.GetProcedures(Index)
end;

function TFIBDBSchemaExtract.GetProceduresCount: Integer;
begin
  Result := FMetaDatabase.GetProceduresCount
end;

function TFIBDBSchemaExtract.GetFunctions(const Index: Integer): TMetaStoredFunc;
begin
  Result := FMetaDatabase.GetFunctions(Index)
end;

function TFIBDBSchemaExtract.GetFunctionsCount: Integer;
begin
  Result := FMetaDatabase.GetFunctionsCount
end;

function TFIBDBSchemaExtract.GetTables(const Index: Integer): TMetaTable;
begin
  Result := FMetaDatabase.GetTables(Index)
end;

function TFIBDBSchemaExtract.GetTablesCount: Integer;
begin
  Result := FMetaDatabase.GetTablesCount
end;

function TFIBDBSchemaExtract.GetUDFS(const Index: Integer): TMetaUDF;
begin
  Result := FMetaDatabase.GetUDFS(Index)
end;

function TFIBDBSchemaExtract.GetUDFSCount: Integer;
begin
  Result := FMetaDatabase.GetUDFSCount
end;

function TFIBDBSchemaExtract.GetViews(const Index: Integer): TMetaView;
begin
  Result := FMetaDatabase.GetViews(Index)
end;

function TFIBDBSchemaExtract.GetViewsCount: Integer;
begin
  Result := FMetaDatabase.GetViewsCount
end;

procedure TFIBDBSchemaExtract.LoadObjectNames;
begin
  LoadMetaData(True)
end;

procedure TFIBDBSchemaExtract.LoadMetaData(OnlyNames: boolean = False);
begin
  if Assigned(FDatabase) then
  begin
    FMetaDatabase.FSysInfos := FLoadOptions.FIncSysInfo;
    FMetaDatabase.FLoadViewChilds := FLoadOptions.FLoadViewChilds;
    FMetaDatabase.FLoadTableChilds := FLoadOptions.FLoadTableChilds;
    FMetaDatabase.FLoadObjects := FLoadOptions.FLoadObjects;

    FMetaDatabase.LoadFromDataBase(FDatabase, OnlyNames);
    FFullLoaded := not OnlyNames
  end
  else
    FIBError(feCantLoadMetadata, [CmpFullName(Self)]);
end;

function TFIBDBSchemaExtract.GetMetaDataBase: TMetaDataBase;
begin
  Result := FMetaDatabase
end;

procedure TFIBDBSchemaExtract.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if (Operation = opRemove) and (AComponent = FDatabase) then
  begin
    FDatabase := nil;
    FMetaDatabase.Clear;
  end;
  inherited;

end;

procedure TFIBDBSchemaExtract.SetDatabase(const Value: TFIBDatabase);
begin
  if FDatabase <> Value then
  begin
    FMetaDatabase.Clear;
    FDatabase := Value;
    FFullLoaded := False;
  end
end;

{ TMDLoadOptions }

constructor TLoadOptions.Create;
begin
  inherited Create;

  FLoadObjects := DefObjects;
  FLoadTableChilds := DefTableChilds;
  FLoadViewChilds := DefViewChilds;

end;

function TFIBDBSchemaExtract.GetNamesLoaded: boolean;
begin
  Result := FMetaDatabase.FNamesLoaded
end;

{ TMetaStoredFunc }

class function TMetaStoredFunc.ClassIndex: Integer;
begin
  Result := Ord(otStoredFunctions)
end;

constructor TMetaStoredFunc.Create(AOwner: TCustomMetaObject; aName: string);
begin
  inherited Create(AOwner, aName);
  AddClass(TMetaProcInField); // in
  AddClass(TMetaProcOutField); // out
  AddClass(TCustomMetaGrant); // grant
end;

procedure TMetaStoredFunc.GenerateObjectDDL(Stream: TStringStream);
begin
  InternalSaveToDDL(Stream, 'CREATE');
  Stream.WriteString(sLineBreak + 'AS' + sLineBreak);
  Stream.WriteString(FSource);
end;

function TMetaStoredFunc.GetInputFields(const Index: Integer): TMetaProcInField;
begin
  Result := TMetaProcInField(GetChildObject(Ord(soProcFieldIn), Index))
end;

function TMetaStoredFunc.GetInputFieldsCount: Integer;
begin
  Result := GetChildsCount(Ord(soProcFieldIn));
end;

function TMetaStoredFunc.GetReturn: TMetaProcOutField;
begin
  if FItems[Ord(soProcFieldOut)].Childs.Count > 0 then
    Result := TMetaProcOutField(GetChildObject(Ord(soProcFieldOut), 0))
  else
    Result := nil
end;

procedure TMetaStoredFunc.InternalSaveToDDL(Stream: TStringStream; Operation: string);
var
  I: Integer;
  // Return:TMetaProcOutField;
begin
  Stream.WriteString(Format('%s FUNCTION %s', [Operation, FormatName]));

  if InputFieldsCount > 0 then
  begin
    if InputFieldsCount > 1 then
    begin
      Stream.WriteString(' (');
      for I := 0 to InputFieldsCount - 1 do
      begin
        Stream.WriteString(sLineBreak + '   ');
        InputFields[I].GenerateObjectDDL(Stream);
        if I <> InputFieldsCount - 1 then
          Stream.WriteString(',');
      end;
      Stream.WriteString(')');
    end
    else
    begin
      Stream.WriteString(' (');
      InputFields[0].GenerateObjectDDL(Stream);
      Stream.WriteString(')');
    end;
  end;

  Stream.WriteString(Format('%sRETURNS ', [sLineBreak]));
  // Return:=TMetaProcOutField(GetChildObject(Ord(soProcFieldOut), 0));
  if Return <> nil then
    Return.GenerateObjectDDL(Stream);

end;

type
  TMetaProcFieldClass = class of TMetaProcField;

procedure TMetaStoredFunc.LoadFromDataBase(QNames, QReturn, QInputs, QCharset: TFIBQuery);

  procedure LoadFields(Query: TFIBQuery; FieldClass: TMetaProcFieldClass);
  begin
    Query.ParamByName('FN').AsString := FName;
    Query.ParamByName('PN').AsString := FPackageName;
    Query.ExecQuery;
    while not Query.Eof do
    begin
      TMetaProcField(FieldClass.Create(Self)).DoLoadFromQuery(Query, QCharset, True, True);
      Query.Next;
    end;
    Query.Close;
  end;

begin
  Name := QNames.Fields[0].AsString;
  FSource := QNames.Fields[1].AsString;
  FPackageName := QNames.Fields[3].AsString;
  LoadDescription(QNames);
  LoadFields(QReturn, TMetaProcOutField);
  LoadFields(QInputs, TMetaProcInField);
  FLoaded := True
end;

function TMetaStoredFunc.CommentKeyword: string;
begin
  Result := 'FUNCTION';
end;

function TMetaStoredFunc.CommentTarget: string;
begin
  Result := RoutineName(FPackageName, FormatName);
end;

procedure TMetaStoredFunc.GenerateCommentDDL(Stream: TStringStream);
begin
  inherited GenerateCommentDDL(Stream);
  // The return value has no name and no COMMENT ON
  GenerateChildCommentDDL(Stream, Ord(soProcFieldIn));
end;

procedure TMetaStoredFunc.SaveEmptyDDL(Stream: TStringStream);
begin
  InternalSaveToDDL(Stream, 'CREATE');
  Stream.WriteString(sLineBreak + 'AS' + sLineBreak + 'BEGIN' + sLineBreak + 'END');
end;

procedure TMetaStoredFunc.SaveAlterDDL(Stream: TStringStream);
begin
  InternalSaveToDDL(Stream, 'ALTER');
  Stream.WriteString(sLineBreak + 'AS' + sLineBreak);
  Stream.WriteString(FSource);

end;

{ TMetaPackageProcedure }

class function TMetaPackageProcedure.ClassIndex: Integer;
begin
  Result := Ord(soPackageProcedures)
end;

class function TMetaPackageProcedure.IsSubObject: boolean;
begin
  Result := True
end;

procedure TMetaPackageProcedure.GenerateObjectDDL(Stream: TStringStream);
begin
end;

procedure TMetaPackageProcedure.GenerateDDLText(Stream: TStringStream);
begin
end;

{ TMetaPackageFunction }

class function TMetaPackageFunction.ClassIndex: Integer;
begin
  Result := Ord(soPackageFunctions)
end;

class function TMetaPackageFunction.IsSubObject: boolean;
begin
  Result := True
end;

procedure TMetaPackageFunction.GenerateObjectDDL(Stream: TStringStream);
begin
end;

procedure TMetaPackageFunction.GenerateDDLText(Stream: TStringStream);
begin
end;

{ TMetaPackage }

constructor TMetaPackage.Create(AOwner: TCustomMetaObject; aName: string = '');
begin
  inherited Create(AOwner, aName);
  AddClass(TMetaPackageProcedure);
  AddClass(TMetaPackageFunction);
end;

class function TMetaPackage.ClassIndex: Integer;
begin
  Result := Ord(otPackage)
end;

function TMetaPackage.GetProcedures(const Index: Integer): TMetaPackageProcedure;
begin
  Result := TMetaPackageProcedure(GetChildObject(Ord(soPackageProcedures), Index));
end;

function TMetaPackage.GetProceduresCount: Integer;
begin
  Result := GetChildsCount(Ord(soPackageProcedures));
end;

function TMetaPackage.GetFunctions(const Index: Integer): TMetaPackageFunction;
begin
  Result := TMetaPackageFunction(GetChildObject(Ord(soPackageFunctions), Index));
end;

function TMetaPackage.GetFunctionsCount: Integer;
begin
  Result := GetChildsCount(Ord(soPackageFunctions));
end;

procedure TMetaPackage.GenerateCommentDDL(Stream: TStringStream);
begin
  inherited GenerateCommentDDL(Stream);
  GenerateChildCommentDDL(Stream, Ord(soPackageProcedures));
  GenerateChildCommentDDL(Stream, Ord(soPackageFunctions));
end;

procedure TMetaPackage.GenerateObjectDDL(Stream: TStringStream);
begin
  Stream.WriteString(Format('CREATE PACKAGE %s AS ' + sLineBreak, [FormatName]));
  Stream.WriteString(FSpec);
  Stream.WriteString(DefTerminator);
  Stream.WriteString(sLineBreak + sLineBreak);
  Stream.WriteString(Format('RECREATE PACKAGE BODY %s AS ' + sLineBreak, [FormatName]));
  Stream.WriteString(FBody);
end;

procedure TMetaPackage.LoadFromDataBase(QNames, QCharset: TFIBQuery);
var
  DataBase: TMetaDataBase;
  QRoutines, QProcFields, QFuncReturn, QFuncInputs: TFIBQuery;
begin
  Name := QNames.Fields[0].AsString;
  FSpec := QNames.Fields[1].AsString;
  FBody := QNames.Fields[2].AsString;
  LoadDescription(QNames);

  DataBase := MetaDataBase;
  QRoutines := nil;
  QProcFields := nil;
  QFuncReturn := nil;
  QFuncInputs := nil;
  try
    QRoutines := CreateQuery(QRYPackageProcedures, QNames.Transaction);
    QProcFields := CreateQuery(DataBase.ProcFieldsSQL, QNames.Transaction);
    QRoutines.Params[0].AsString := FName;
    QRoutines.ExecQuery;
    while not QRoutines.Eof do
    begin
      TMetaPackageProcedure.Create(Self).LoadFromDataBase(QRoutines, QProcFields, QCharset,
        DataBase.FProcParamDomainSupports, DataBase.FProcParamRelationSupports);
      QRoutines.Next;
    end;
    QRoutines.Close;

    QRoutines.SQL.Text := QRYPackageFunctions;
    QFuncReturn := CreateQuery(QRYStoredFuncFieldsFB3Out, QNames.Transaction);
    QFuncInputs := CreateQuery(QRYStoredFuncFieldsFB3In, QNames.Transaction);
    QRoutines.Params[0].AsString := FName;
    QRoutines.ExecQuery;
    while not QRoutines.Eof do
    begin
      TMetaPackageFunction.Create(Self).LoadFromDataBase(QRoutines, QFuncReturn, QFuncInputs, QCharset);
      QRoutines.Next;
    end;
    QRoutines.Close;
  finally
    QFuncInputs.Free;
    QFuncReturn.Free;
    QProcFields.Free;
    QRoutines.Free;
  end;
  FLoaded := True;
end;

function TMetaPackage.CommentKeyword: string;
begin
  Result := 'PACKAGE';
end;

procedure TMetaPackage.SaveBodyDDL(Stream: TStringStream);
begin
  Stream.WriteString(Format('RECREATE PACKAGE BODY %s AS ' + sLineBreak, [FormatName]));
  Stream.WriteString(FBody);
end;

procedure TMetaPackage.SaveSpecDDL(Stream: TStringStream);
begin
  Stream.WriteString(Format('CREATE PACKAGE %s AS ' + sLineBreak, [FormatName]));
  Stream.WriteString(FSpec);
end;

end.
