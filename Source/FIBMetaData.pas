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
  TFIBDBObjectType = (
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
  TFIBDBObjectTypes = set of TFIBDBObjectType;

  // SubObjects
  TFIBTableChildType = (
    soTableFields,
    soPrimaryKey,
    soForeignKey,
    soTableTriggers,
    soUniqueConstr,
    soIndex,
    soCheckConstr,
    soTableGrants
  );
  TFIBTableChildTypes = set of TFIBTableChildType;

  TFIBViewChildType = (soViewFields, soViewTriggers, soViewGrants);
  TFIBViewChildTypes = set of TFIBViewChildType;

  TFIBProcedureChild = (soProcFieldIn, soProcFieldOut, soProcGrants);
  TFIBProcedureChildren = set of TFIBProcedureChild;

  TFIBUDFChild = (soUDFField);
  TFIBUDFChildren = set of TFIBUDFChild;

  TFIBPackageChild = (soPackageProcedures, soPackageFunctions);

  TFIBRoleChild = (soRoleGrants);

  TFIBTriggerType = (ttBefore, ttAfter, ttON);
  TFIBTriggerAction = (
    taInsert,
    taUpdate,
    taDelete,
    taConnect,
    taDisconnect,
    taTransactionStart,
    taTransactionCommit,
    taTransactionRollback
  );
  TFIBTriggerActions = set of TFIBTriggerAction;

  TFIBIndexOrder = (IoDescending, IoAscending);
  TFIBForeignKeyRule = (fkrRestrict, fkrCascade, fkrSetNull, fkrSetDefault);

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

  TFIBPrivilege = (
    goSelect,
    goInsert,
    goUpdate,
    goDelete,
    goReferences,
    goExecuteProc,
    goRole,
    goUsage
  );
  TFIBPrivileges = set of TFIBPrivilege;

  TFIBLoadMetaDataEvent = procedure(Sender: TObject; const Message: string; var Stop: Boolean) of object;

  TFIBDDLTextOption = (dtoUseCreateDB, dtoUseSetClientLib, dtoUseSetTerm, dtoDecodeDomains, dtoIncludeGrants,
    dtoIncludeComments);
  TFIBDDLTextOptions = set of TFIBDDLTextOption;

const
  DefObjects = [otDomain, otTable, otView, otProcedure, otGenerator,
    otException, otUDF, otRole, otDBTrigger, otStoredFunctions, otPackage];
  DefTableChildTypes = [soTableFields, soPrimaryKey, soForeignKey, soTableTriggers,
    soUniqueConstr, soIndex, soCheckConstr];
  DefViewChildTypes = [soViewFields, soViewTriggers];
  DefDDLTextOptions = [dtoUseCreateDB, dtoUseSetTerm, dtoIncludeComments];
  DefSchemaExtractDDLTextOptions = [dtoIncludeComments];

type
  TFIBCustomMetaObject = class;
  TFIBMetaObjectClass = class of TFIBCustomMetaObject;

  TFIBMetaDomain = class;
  TFIBMetaTable = class;
  TFIBMetaDatabase = class;

  TFIBMetaDataItem = record
    Childs: TList;
    ClassID: TFIBMetaObjectClass;
  end;

  TFIBCustomMetaObject = class(TObject)
  private
    FName: string;
    FFormatName: string;
    FDescription: string;
    FOwner: TFIBCustomMetaObject;
    FItems: array of TFIBMetaDataItem;
    FItemsCount: Integer;
    FLoaded: Boolean;
    function GetChildObject(const ClassIndex, Index: Integer): TFIBCustomMetaObject;
    function GetChildObjectByName(const ClassIndex: Integer; const ObjectName: string): TFIBCustomMetaObject;
    function GetChildsCount(const ClassIndex: Integer): Integer;
    procedure ClearChilds(const ClassIndex: Integer);
    function GetAsDDL: string;
    procedure AddClass(ClassID: TFIBMetaObjectClass);

    function GenerateChildDDL(Stream: TStringStream; ChildType: Integer): Integer;
    procedure GenerateChildCommentDDL(Stream: TStringStream; ChildType: Integer);
    function GetAsObjectDDL: string;
    procedure SetName(const Value: string);
    function GetItems(const Index: Integer): TFIBMetaDataItem;
    function GetMetaDataBase: TFIBMetaDatabase;
  protected
    procedure LoadDescription(Query: TFIBQuery);
    procedure WriteCommentDDL(Stream: TStringStream; const Target, Text: string);
    procedure GenerateObjectDDL(Stream: TStringStream); virtual;
    // Keyword of COMMENT ON for the object; empty when it cannot have a comment
    function CommentKeyword: string; virtual;
    function CommentTarget: string; virtual;
    // COMMENT ON for the object and its sub-objects
    procedure GenerateCommentDDL(Stream: TStringStream); virtual;
    property MetaDataBase: TFIBMetaDatabase read GetMetaDataBase;
  public
    constructor Create(AOwner: TFIBCustomMetaObject; aName: string = ''); virtual;
    destructor Destroy; override;
    procedure Clear;
    class function ClassIndex: Integer; virtual;
    class function IsSubObject: Boolean; virtual;

    procedure GenerateDDLText(Stream: TStringStream); virtual;
    property Name: string read FName write SetName;
    property Description: string read FDescription;
    property AsDDL: string read GetAsDDL;
    property AsObjectDDL: string read GetAsObjectDDL;
    property ItemsCount: Integer read FItemsCount;
    property Items[const Index: Integer]: TFIBMetaDataItem read GetItems;
    property Parent: TFIBCustomMetaObject read FOwner;
    property FormatName: string read FFormatName;
    property Loaded: Boolean read FLoaded;
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
  TFIBCustomMetaGrant = class(TFIBCustomMetaObject)
  private
    FObjectName: string;
    // RDB$OBJECT_TYPE of the object
    FObjectType: Integer;
    FPrivileges: array of TFIBPrivileges;
    FFields: array of string;
    FWithGrantOption: array of Boolean;
    FUserList: array of string;
    procedure SetSize(Size: Integer);
    function GetSize: Integer;
    procedure LoadFromDataBase(QGrants: TFIBQuery; const Name: string; Pack: Boolean = True);
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
    property Count: Integer read GetSize;
  end;

  TFIBMetaViewGrant = class(TFIBCustomMetaGrant)
  public
    class function ClassIndex: Integer; override;
  end;

  TFIBMetaTableGrant = class(TFIBCustomMetaGrant)
  public
    class function ClassIndex: Integer; override;
  end;

  TFIBMetaProcedureGrant = class(TFIBCustomMetaGrant)
  public
    class function ClassIndex: Integer; override;
  end;

  TFIBMetaRoleGrant = class(TFIBCustomMetaGrant)
  public
    class function ClassIndex: Integer; override;
  end;

  // Grants of a generator or an exception, their only children
  TFIBObjectGrant = class(TFIBCustomMetaGrant)
  public
    class function ClassIndex: Integer; override;
  end;

  TFIBMetaGenerator = class(TFIBCustomMetaObject)
  private
    FValue: Int64;
    FOptionsLoaded: Boolean;
    FInitialValue: Int64;
    FIncrement: Integer;
    procedure LoadFromDataBase(QName: TFIBQuery);
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
    function CommentKeyword: string; override;
  public
    constructor Create(AOwner: TFIBCustomMetaObject; aName: string = ''); override;
    class function ClassIndex: Integer; override;
    property Value: Int64 read FValue;
    property InitialValue: Int64 read FInitialValue;
    property Increment: Integer read FIncrement;
  end;

  TFIBMetaArrayBounds = record
    LOWER_BOUND: Integer;
    UPPER_BOUND: Integer;
  end;

  TFIBFieldDimensions = array of TFIBMetaArrayBounds;

  TFIBCustomMetaField = class(TFIBCustomMetaObject)
  private
    FScale: Word;
    FLength: SmallInt;
    FPrecision: SmallInt;
    FFieldType: TFIBFieldType;
    FCharSet: string;
    FSegmentLength: SmallInt;
    FSubType: SmallInt;
    FBytesPerCharacter: SmallInt;
    FIsArray: Boolean;
    FDimensions: TFIBFieldDimensions;
    FIdentity: Integer;
    procedure LoadFromDataBase(QField, QCharset: TFIBQuery); virtual;
    property SegmentLength: SmallInt read FSegmentLength;
    function GetShortFieldType: string;
    function GetDimensionStr: string;
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
  public
    class function IsSubObject: Boolean; override;
    property Scale: Word read FScale;
    property Length: SmallInt read FLength;
    property Precision: SmallInt read FPrecision;
    property FieldType: TFIBFieldType read FFieldType;
    property CharSet: string read FCharSet;
    property SubType: SmallInt read FSubType;
    property BytesPerCharacter: SmallInt read FBytesPerCharacter;
    property ShortFieldType: string read GetShortFieldType;
  end;

  TFIBMetaField = class(TFIBCustomMetaField)
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

  TFIBMetaProcedureField = class(TFIBMetaField)
  private
    FDomain: string;
    FMechanizm: SmallInt;
    FUseDomain: Boolean;
    FUseRelation: Boolean;
    FRelationObject: string;
    FRelationField: string;
    FDefaultValue: string;
    procedure DoLoadFromQuery(QField, QCharset: TFIBQuery; CanUseParamDomain, CanUseProcParamRelation: Boolean);
    // BaseType: a TYPE OF COLUMN parameter as its type, for a routine made before the tables
    procedure WriteDeclaration(Stream: TStringStream; BaseType: Boolean);
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
    function CommentKeyword: string; override;
  end;

  TFIBMetaProcedureInField = class(TFIBMetaProcedureField)
  public
    class function ClassIndex: Integer; override;
  end;

  TFIBMetaProcedureOutField = class(TFIBMetaProcedureField)
  public
    class function ClassIndex: Integer; override;
  end;

  TFIBMetaTableField = class(TFIBMetaField)
  private
    FDefaultValue: string;
    FNotNull: Boolean;
    FDomain: Integer;
    FDomainName: string;
    FComputedSource: string;
    FValidationSource: string;
    FCollation: string;
    FIdentityStart: Int64;
    FIdentityIncrement: Integer;
    procedure LoadFromDataBase(Q: TFIBQuery; C: TFIBQuery); override;
    function GetDomain: TFIBMetaDomain;
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
  public
    class function ClassIndex: Integer; override;
    property DefaultValue: string read FDefaultValue;
    property NotNull: Boolean read FNotNull;
    property Domain: TFIBMetaDomain read GetDomain;
    property ComputedSource: string read FComputedSource;
    property Collation: string read FCollation;
  end;

  TFIBMetaDomain = class(TFIBMetaTableField)
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
    function CommentKeyword: string; override;
    function CommentTarget: string; override;
  public
    class function ClassIndex: Integer; override;
    class function IsSubObject: Boolean; override;
  end;

  TFIBMetaConstraint = class(TFIBCustomMetaObject)
  private
    FFields: array of Integer;
    function GetFields(const Index: Integer): TFIBMetaTableField;
    function GetFieldsCount: Integer;
  public
    class function IsSubObject: Boolean; override;
    property Fields[const Index: Integer]: TFIBMetaTableField read GetFields;
    property FieldsCount: Integer read GetFieldsCount;
  end;

  TFIBMetaPrimaryKey = class(TFIBMetaConstraint)
  private
    procedure LoadFromDataBase(Q: TFIBQuery);
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
  public
    class function ClassIndex: Integer; override;
  end;

  TFIBMetaUniqueConstraint = class(TFIBMetaConstraint)
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
  public
    class function ClassIndex: Integer; override;
  end;

  TFIBMetaForeignKey = class(TFIBMetaConstraint)
  private
    FForTable: Integer;
    FForFields: array of Integer;
    FOnDelete: TFIBForeignKeyRule;
    FOnUpdate: TFIBForeignKeyRule;
    function GetForFields(const Index: Integer): TFIBMetaTableField;
    function GetForFieldsCount: Integer;
    function GetForTable: TFIBMetaTable;
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
  public
    class function ClassIndex: Integer; override;
    property ForTable: TFIBMetaTable read GetForTable;
    property ForFields[const Index: Integer]: TFIBMetaTableField read GetForFields;
    property ForFieldsCount: Integer read GetForFieldsCount;
    property OnDelete: TFIBForeignKeyRule read FOnDelete;
    property OnUpdate: TFIBForeignKeyRule read FOnUpdate;
  end;

  TFIBMetaCheckConstraint = class(TFIBCustomMetaObject)
  private
    FConstraint: string;
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
  public
    class function ClassIndex: Integer; override;
    property Constraint: string read FConstraint;
  end;

  TFIBMetaIndex = class(TFIBMetaConstraint)
  private
    FUnique: Boolean;
    FActive: Boolean;
    FOrder: TFIBIndexOrder;
    FExpression: string;
    FCondition: string;
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
    function CommentKeyword: string; override;
  public
    class function ClassIndex: Integer; override;
    property Unique: Boolean read FUnique;
    property Active: Boolean read FActive;
    property Order: TFIBIndexOrder read FOrder;
    // COMPUTED BY expression, in parentheses
    property Expression: string read FExpression;
    // WHERE clause of a partial index
    property Condition: string read FCondition;
  end;

  TFIBCustomMetaTrigger = class(TFIBCustomMetaObject)
  private
    FPrefix: TFIBTriggerType;
    FSuffix: TFIBTriggerActions;
    FPosition: SmallInt;
    FActive: Boolean;
    FSource: string;
    FTriggerType: Int64;
    FEngine: string;
    FEntryPoint: string;
    FSQLSecurity: Integer;
    procedure WriteBody(Stream: TStringStream);
    class function DecodePrefix(Value: Int64): TFIBTriggerType;
    class function DecodeSuffixes(Value: Int64): TFIBTriggerActions;
    function IsDDLTrigger: Boolean;
    function DDLEventsText: string;
    procedure WriteHeaderDDL(Stream: TStringStream);
    procedure LoadFromDataBase(Q: TFIBQuery);
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
    procedure SaveFakeDDL(Stream: TStringStream); // For Views
    procedure SaveAlterDDL(Stream: TStringStream);
    function CommentKeyword: string; override;
  public
    class function IsSubObject: Boolean; override;
    property Prefix: TFIBTriggerType read FPrefix;
    property Suffix: TFIBTriggerActions read FSuffix;
    property Position: SmallInt read FPosition;
    property Active: Boolean read FActive;
    property Source: string read FSource;
    // RDB$TRIGGER_TYPE, also of the DDL triggers
    property TriggerType: Int64 read FTriggerType;
    // ENGINE of a UDR trigger, empty for a PSQL one
    property Engine: string read FEngine;
    property EntryPoint: string read FEntryPoint;
    // -1 not set, 0 INVOKER, 1 DEFINER
    property SQLSecurity: Integer read FSQLSecurity;
  end;

  TFIBMetaTableTrigger = class(TFIBCustomMetaTrigger)
  public
    class function ClassIndex: Integer; override;
  end;

  TFIBMetaViewTrigger = class(TFIBCustomMetaTrigger)
  public
    class function ClassIndex: Integer; override;
  end;

  TFIBMetaDBTrigger = class(TFIBCustomMetaTrigger)
  public
    class function ClassIndex: Integer; override;
    class function IsSubObject: Boolean; override;
  end;

  TFIBMetaTable = class(TFIBCustomMetaObject)
  private
    FRelationType: Integer;
    FSQLSecurity: Integer;
    function GetFields(const Index: Integer): TFIBMetaTableField;
    function GetFieldsCount: Integer;
    procedure LoadFromDataBase(QNames, QFields: TFIBQuery; QCharset: TFIBQuery;
      QPrimary, QIndex, QForeign, QCheck, QTrigger: TFIBQuery;
      ChildTypes: TFIBTableChildTypes);

    function FindFieldIndex(const Name: string): Integer;
    function GetUniques(const Index: Integer): TFIBMetaUniqueConstraint;
    function GetUniquesCount: Integer;
    function GetPrimaryKey: TFIBMetaPrimaryKey;
    function GetPrimaryKeyExist: Boolean;
    function GetIndices(const Index: Integer): TFIBMetaIndex;
    function GetIndicesCount: Integer;
    function GetForeign(const Index: Integer): TFIBMetaForeignKey;
    function GetForeignCount: Integer;
    function GetChecks(const Index: Integer): TFIBMetaCheckConstraint;
    function GetChecksCount: Integer;
    function GetTriggers(const Index: Integer): TFIBCustomMetaTrigger;
    function GetTriggersCount: Integer;

  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
    function CommentKeyword: string; override;
    procedure GenerateCommentDDL(Stream: TStringStream); override;
  public
    constructor Create(AOwner: TFIBCustomMetaObject; aName: string = ''); override;
    class function ClassIndex: Integer; override;

    function FindFieldName(const Name: string): TFIBMetaTableField;
    procedure GenerateDDLText(Stream: TStringStream); override;

    property Fields[const Index: Integer]: TFIBMetaTableField read GetFields;
    property FieldsCount: Integer read GetFieldsCount;

    property PrimaryKey: TFIBMetaPrimaryKey read GetPrimaryKey;
    property PrimaryKeyExist: Boolean read GetPrimaryKeyExist;

    property Uniques[const Index: Integer]: TFIBMetaUniqueConstraint read GetUniques;
    property UniquesCount: Integer read GetUniquesCount;

    property Indices[const Index: Integer]: TFIBMetaIndex read GetIndices;
    property IndicesCount: Integer read GetIndicesCount;

    property Foreign[const Index: Integer]: TFIBMetaForeignKey read GetForeign;
    property ForeignCount: Integer read GetForeignCount;

    property Checks[const Index: Integer]: TFIBMetaCheckConstraint read GetChecks;
    property ChecksCount: Integer read GetChecksCount;

    property Triggers[const Index: Integer]: TFIBCustomMetaTrigger read GetTriggers;
    property TriggersCount: Integer read GetTriggersCount;
    // -1 not set, 0 INVOKER, 1 DEFINER
    property SQLSecurity: Integer read FSQLSecurity;
  end;

  TFIBMetaView = class(TFIBCustomMetaObject)
  private
    FSource: string;
    function GetFields(const Index: Integer): TFIBMetaField;
    function GetFieldsCount: Integer;
    function GetTriggers(const Index: Integer): TFIBCustomMetaTrigger;
    function GetTriggersCount: Integer;

    procedure LoadFromDataBase(QName, QFields, QTriggers: TFIBQuery; QCharset: TFIBQuery; ChildTypes: TFIBViewChildTypes);

  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
    function CommentKeyword: string; override;
    procedure GenerateCommentDDL(Stream: TStringStream); override;
  public
    constructor Create(AOwner: TFIBCustomMetaObject; aName: string = ''); override;
    class function ClassIndex: Integer; override;
    procedure GenerateDDLText(Stream: TStringStream); override;
    property Source: string read FSource;
    property Fields[const Index: Integer]: TFIBMetaField read GetFields;
    property FieldsCount: Integer read GetFieldsCount;
    property Triggers[const Index: Integer]: TFIBCustomMetaTrigger read GetTriggers;
    property TriggersCount: Integer read GetTriggersCount;
  end;

  TFIBMetaProcedure = class(TFIBCustomMetaObject)
  private
    FSource: string;
    FPackageName: string;
    FEngine: string;
    FEntryPoint: string;
    FSQLSecurity: Integer;
    // AS and the source, or EXTERNAL NAME and ENGINE
    procedure WriteBody(Stream: TStringStream);
    procedure LoadFromDataBase(QNames, QFields: TFIBQuery; QCharset: TFIBQuery; CanUseParamDomain, CanUseProcParamRelation: Boolean);
    function GetInputFields(const Index: Integer): TFIBMetaProcedureInField;
    function GetInputFieldsCount: Integer;
    function GetOutputFields(const Index: Integer): TFIBMetaProcedureOutField;
    function GetOutputFieldsCount: Integer;

    procedure InternalSaveToDDL(Stream: TStringStream; Operation: string; BaseTypes: Boolean = False);
    procedure SaveToPostDDL(Stream: TStringStream);
    procedure SaveToAlterDDL(Stream: TStringStream);
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
    function CommentKeyword: string; override;
    function CommentTarget: string; override;
    procedure GenerateCommentDDL(Stream: TStringStream); override;

  public
    constructor Create(AOwner: TFIBCustomMetaObject; aName: string = ''); override;
    class function ClassIndex: Integer; override;
    property Source: string read FSource;
    property InputFields[const Index: Integer]: TFIBMetaProcedureInField read GetInputFields;
    property InputFieldsCount: Integer read GetInputFieldsCount;

    property OutputFields[const Index: Integer]: TFIBMetaProcedureOutField read GetOutputFields;
    property OutputFieldsCount: Integer read GetOutputFieldsCount;
    property PackageName: string read FPackageName;
    // ENGINE of a UDR procedure, empty for a PSQL one
    property Engine: string read FEngine;
    property EntryPoint: string read FEntryPoint;
    // -1 not set, 0 INVOKER, 1 DEFINER
    property SQLSecurity: Integer read FSQLSecurity;
  end;

  TFIBMetaStoredFunction = class(TFIBCustomMetaObject)
  private
    FPackageName: string;
    FSource: string;
    FEngine: string;
    FEntryPoint: string;
    FDeterministic: Boolean;
    FSQLSecurity: Integer;
    procedure WriteBody(Stream: TStringStream);
    function GetInputFields(const Index: Integer): TFIBMetaProcedureInField;
    function GetInputFieldsCount: Integer;

    procedure LoadFromDataBase(QNames, QReturn, QInputs, QCharset: TFIBQuery);
    procedure InternalSaveToDDL(Stream: TStringStream; Operation: string; BaseTypes: Boolean = False);
    function GetReturn: TFIBMetaProcedureOutField;
  protected
    procedure SaveEmptyDDL(Stream: TStringStream);
    procedure SaveAlterDDL(Stream: TStringStream);
    procedure GenerateObjectDDL(Stream: TStringStream); override;
    function CommentKeyword: string; override;
    function CommentTarget: string; override;
    procedure GenerateCommentDDL(Stream: TStringStream); override;
  public
    constructor Create(AOwner: TFIBCustomMetaObject; aName: string = ''); override;
    class function ClassIndex: Integer; override;
    property Source: string read FSource;
    property InputFields[const Index: Integer]: TFIBMetaProcedureInField read GetInputFields;
    property InputFieldsCount: Integer read GetInputFieldsCount;
    property PackageName: string read FPackageName;
    property Return: TFIBMetaProcedureOutField read GetReturn;
    // ENGINE of a UDR function, empty for a PSQL one
    property Engine: string read FEngine;
    property EntryPoint: string read FEntryPoint;
    property Deterministic: Boolean read FDeterministic;
    // -1 not set, 0 INVOKER, 1 DEFINER
    property SQLSecurity: Integer read FSQLSecurity;
  end;

  // Routines of a package: their DDL is the package source, AsDDL has only their comments
  TFIBMetaPackageProcedure = class(TFIBMetaProcedure)
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
  public
    class function ClassIndex: Integer; override;
    class function IsSubObject: Boolean; override;
    procedure GenerateDDLText(Stream: TStringStream); override;
  end;

  TFIBMetaPackageFunction = class(TFIBMetaStoredFunction)
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
  public
    class function ClassIndex: Integer; override;
    class function IsSubObject: Boolean; override;
    procedure GenerateDDLText(Stream: TStringStream); override;
  end;

  TFIBMetaPackage = class(TFIBCustomMetaObject)
  private
    FSpec: string;
    FBody: string;
    FSQLSecurity: Integer;
    procedure LoadFromDataBase(QNames, QCharset: TFIBQuery);
    // A TYPE OF COLUMN parameter: the header is made before the tables with the base types
    function UsesColumnTypes: Boolean;
    // SQL SECURITY before AS
    function HeaderOptions: string;
    procedure SaveSpecDDL(Stream: TStringStream);
    procedure SaveHeaderAlterDDL(Stream: TStringStream);
    procedure SaveBodyDDL(Stream: TStringStream);
    function GetProcedures(const Index: Integer): TFIBMetaPackageProcedure;
    function GetProceduresCount: Integer;
    function GetFunctions(const Index: Integer): TFIBMetaPackageFunction;
    function GetFunctionsCount: Integer;
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
    function CommentKeyword: string; override;
    procedure GenerateCommentDDL(Stream: TStringStream); override;
  public
    constructor Create(AOwner: TFIBCustomMetaObject; aName: string = ''); override;
    class function ClassIndex: Integer; override;
    property SpecSource: string read FSpec;
    property BodySource: string read FBody;
    property Procedures[const Index: Integer]: TFIBMetaPackageProcedure read GetProcedures;
    property ProceduresCount: Integer read GetProceduresCount;
    property Functions[const Index: Integer]: TFIBMetaPackageFunction read GetFunctions;
    property FunctionsCount: Integer read GetFunctionsCount;
    // -1 not set, 0 INVOKER, 1 DEFINER
    property SQLSecurity: Integer read FSQLSecurity;
  end;

  TFIBMetaException = class(TFIBCustomMetaObject)
  private
    FMessage: string;
    FNumber: Integer;
    procedure LoadFromDataBase(QName: TFIBQuery);
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
    function CommentKeyword: string; override;
  public
    constructor Create(AOwner: TFIBCustomMetaObject; aName: string = ''); override;
    class function ClassIndex: Integer; override;
    property Message: string read FMessage;
    property Number: Integer read FNumber;
  end;

  TFIBMetaUDFField = class(TFIBCustomMetaField)
  private
    FPosition: SmallInt;
    FMechanism: SmallInt;
    procedure LoadFromDataBase(QField, QCharset: TFIBQuery); override;
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
  public
    class function ClassIndex: Integer; override;
    property Position: SmallInt read FPosition;
    property Mechanism: SmallInt read FMechanism;
  end;

  TFIBMetaUDF = class(TFIBCustomMetaObject)
  private
    FModule: string;
    FEntry: string;
    FReturn: SmallInt;
    procedure LoadFromDataBase(QNames, QFields: TFIBQuery; QCharset: TFIBQuery);
    function GetFields(const Index: Integer): TFIBMetaUDFField;
    function GetFieldsCount: Integer;
  protected
    procedure GenerateObjectDDL(Stream: TStringStream); override;
    function CommentKeyword: string; override;
  public
    constructor Create(AOwner: TFIBCustomMetaObject; aName: string = ''); override;
    class function ClassIndex: Integer; override;
    property Module: string read FModule;
    property Entry: string read FEntry;
    property Return: SmallInt read FReturn;
    property Fields[const Index: Integer]: TFIBMetaUDFField read GetFields;
    property FieldsCount: Integer read GetFieldsCount;
  end;

  TFIBMetaRole = class(TFIBCustomMetaObject)
  private
    FOwner: string;
  protected
    procedure LoadFromDataBase(QName: TFIBQuery);
    procedure GenerateObjectDDL(Stream: TStringStream); override;
    function CommentKeyword: string; override;

  public
    constructor Create(AOwner: TFIBCustomMetaObject; aName: string = ''); override;
    class function ClassIndex: Integer; override;
    property Owner: string read FOwner;
  end;

  TFIBMetaDatabase = class(TFIBCustomMetaObject)
  private
    FInternalTransaction: TFIBTransaction;
  private
    // DBInfo

    FPageSize: Integer;
    FDefaultCharset: string;
    FConnectCharset: string;
    FUserName: string;
    FClientLib: string;

    FProcParamDomainSupports: Boolean;
    FProcParamRelationSupports: Boolean;
    FIdentityFieldsSupports: Boolean;
    FStoredFunctionsSupports: Boolean;
    FPackagesSupports: Boolean;
    FTabRelTypeSupports: Boolean;
    FCommentsSupports: Boolean;
    // START WITH and INCREMENT BY of a sequence or an identity column
    FSequenceOptionsSupports: Boolean;
    FPartialIndicesSupports: Boolean;
    // ENGINE and EXTERNAL NAME of the routines and triggers
    FExternalRoutinesSupports: Boolean;
    FSQLSecuritySupports: Boolean;
    // DEFAULT SQL SECURITY of the database: -1 not set, 0 INVOKER, 1 DEFINER
    FDefaultSQLSecurity: Integer;
    // Firebird 3 and later limit a string literal to 64 KB, not the statement
    FLongStatementsSupports: Boolean;
    // Of the SQL text, for the byte length of a COMMENT ON
    FCodePage: Word;

    FSQLDialect: Integer;
    //
    FLoadObjects: TFIBDBObjectTypes;
    FLoadTableChilds: TFIBTableChildTypes;
    FLoadViewChilds: TFIBViewChildTypes;
    FSysInfos: Boolean;

    // Flags
    FNamesLoaded: Boolean;
    FDDLTextOptions: TFIBDDLTextOptions;
    FOnLoadMetaData: TFIBLoadMetaDataEvent;

    function GetGenerators(const Index: Integer): TFIBMetaGenerator;
    function GetGeneratorsCount: Integer;
    function GetTables(const Index: Integer): TFIBMetaTable;
    function GetTablesCount: Integer;
    function FindTableIndex(const TableName: string): Integer;
    function FindDomainIndex(const DomainName: string): Integer;
    function GetViews(const Index: Integer): TFIBMetaView;
    function GetViewsCount: Integer;
    function GetDomains(const Index: Integer): TFIBMetaDomain;
    function GetDomainsCount: Integer;
    function GetProcedures(const Index: Integer): TFIBMetaProcedure;
    function GetProceduresCount: Integer;
    function GetFunctionsCount: Integer;
    function GetFunctions(const Index: Integer): TFIBMetaStoredFunction;

    function GetExceptions(const Index: Integer): TFIBMetaException;
    function GetExceptionsCount: Integer;
    function GetUDFS(const Index: Integer): TFIBMetaUDF;
    function GetUDFSCount: Integer;
    function GetRoles(const Index: Integer): TFIBMetaRole;
    function GetRolesCount: Integer;
    function GetPackageCount: Integer;
    function GetPackages(const Index: Integer): TFIBMetaPackage;
    procedure DetectServerFeatures;
    procedure SetOptionalColumns(Query: TFIBQuery; ObjectType: TFIBDBObjectType);
    function ProcFieldsSQL: string;
    function UDFFieldsSQL: string;
    function CommentsIncluded(Options: TFIBDDLTextOptions): Boolean;
    function CommentFits(const Statement, Text: string): Boolean;
  public
    constructor Create(AOwner: TFIBCustomMetaObject; aName: string = ''); override;
    destructor Destroy; override;
    class function ClassIndex: Integer; override;

    procedure Clear;
    procedure LoadFromDataBase(DB: TFIBDatabase; OnlyNames: Boolean = False);

    procedure GenerateDDLText(Stream: TStringStream); override;
    procedure ExtGenerateDDLText(Stream: TStringStream; Options: TFIBDDLTextOptions = DefDDLTextOptions);

    function GetDBObject(DB: TFIBDatabase; ObjectType: TFIBDBObjectType;
      const ObjectName: string; ForceLoad: Boolean = True): TFIBCustomMetaObject;

    property Generators[const Index: Integer]: TFIBMetaGenerator read GetGenerators;
    property GeneratorsCount: Integer read GetGeneratorsCount;

    property Tables[const Index: Integer]: TFIBMetaTable read GetTables;
    property TablesCount: Integer read GetTablesCount;

    property Packages[const Index: Integer]: TFIBMetaPackage read GetPackages;
    property PackageCount: Integer read GetPackageCount;

    property Views[const Index: Integer]: TFIBMetaView read GetViews;
    property ViewsCount: Integer read GetViewsCount;

    property Domains[const Index: Integer]: TFIBMetaDomain read GetDomains;
    property DomainsCount: Integer read GetDomainsCount;

    property Procedures[const Index: Integer]: TFIBMetaProcedure read GetProcedures;
    property ProceduresCount: Integer read GetProceduresCount;

    property Exceptions[const Index: Integer]: TFIBMetaException read GetExceptions;
    property ExceptionsCount: Integer read GetExceptionsCount;

    property UDFS[const Index: Integer]: TFIBMetaUDF read GetUDFS;
    property UDFSCount: Integer read GetUDFSCount;

    property Roles[const Index: Integer]: TFIBMetaRole read GetRoles;
    property RolesCount: Integer read GetRolesCount;

    property SysInfo: Boolean read FSysInfos write FSysInfos;
    property ViewInfo: TFIBViewChildTypes read FLoadViewChilds write FLoadViewChilds default DefViewChildTypes;
    property DBObjects: TFIBDBObjectTypes read FLoadObjects write FLoadObjects default DefObjects;
    property TableInfo: TFIBTableChildTypes read FLoadTableChilds write FLoadTableChilds default DefTableChildTypes;

    property DDLTextOptions: TFIBDDLTextOptions read FDDLTextOptions write FDDLTextOptions;
    property OnLoadMetaData: TFIBLoadMetaDataEvent read FOnLoadMetaData write FOnLoadMetaData;
  end;

  TFIBDBSchemaExtract = class;

  TFIBMetaLoadOptions = class(TPersistent)
  private
    FLoadObjects: TFIBDBObjectTypes;
    FLoadTableChilds: TFIBTableChildTypes;
    FLoadViewChilds: TFIBViewChildTypes;
    FIncSysInfo: Boolean;
  public
    constructor Create;
  published
    property SysInfo: Boolean read FIncSysInfo write FIncSysInfo default False;
    property ViewInfo: TFIBViewChildTypes read FLoadViewChilds write FLoadViewChilds default DefViewChildTypes;
    property DBObjects: TFIBDBObjectTypes read FLoadObjects write FLoadObjects default DefObjects;
    property TableInfo: TFIBTableChildTypes read FLoadTableChilds write FLoadTableChilds default DefTableChildTypes;
  end;

  TFIBDBSchemaExtract = class(TComponent)

  protected
    FDatabase: TFIBDatabase;
    FOnLoadMetaData: TFIBLoadMetaDataEvent;
    FLoadOptions: TFIBMetaLoadOptions;
    FMetaDatabase: TFIBMetaDatabase;
    FFullLoaded: Boolean;
  protected
    function GetDomains(const Index: Integer): TFIBMetaDomain;
    function GetDomainsCount: Integer;
    function GetExceptions(const Index: Integer): TFIBMetaException;
    function GetExceptionsCount: Integer;
    function GetGenerators(const Index: Integer): TFIBMetaGenerator;
    function GetGeneratorsCount: Integer;
    function GetProcedures(const Index: Integer): TFIBMetaProcedure;
    function GetProceduresCount: Integer;
    function GetFunctions(const Index: Integer): TFIBMetaStoredFunction;
    function GetFunctionsCount: Integer;

    function GetTables(const Index: Integer): TFIBMetaTable;
    function GetTablesCount: Integer;
    function GetUDFS(const Index: Integer): TFIBMetaUDF;
    function GetUDFSCount: Integer;
    function GetViews(const Index: Integer): TFIBMetaView;
    function GetViewsCount: Integer;
    procedure SetDatabase(const Value: TFIBDatabase);
    procedure SetLoadOptions(const Value: TFIBMetaLoadOptions);
    function GetNamesLoaded: Boolean;
  private
    function GetPackageCount: Integer;
    function GetPackages(const Index: Integer): TFIBMetaPackage;
    function GetDDLTextOptions: TFIBDDLTextOptions;
    procedure SetDDLTextOptions(const Value: TFIBDDLTextOptions);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure DoOnLoadMetaData(Sender: TObject; const Message: string; var Stop: Boolean);
  published
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure LoadMetaData(OnlyNames: Boolean = False);
    procedure LoadObjectNames;
    function GetDDLText: string;
    function GetMetaDataBase: TFIBMetaDatabase;

    procedure Clear;

    function ObjectByName(ObjectType: TFIBDBObjectType; const ObjectName: string; ForceLoad: Boolean = True): TFIBCustomMetaObject;
    function GetObjectDDL(ObjectType: TFIBDBObjectType; const ObjectName: string; ForceLoad: Boolean = True): string;

    property Generators[const Index: Integer]: TFIBMetaGenerator read GetGenerators;
    property GeneratorsCount: Integer read GetGeneratorsCount;

    property Tables[const Index: Integer]: TFIBMetaTable read GetTables;
    property TablesCount: Integer read GetTablesCount;

    property Packages[const Index: Integer]: TFIBMetaPackage read GetPackages;
    property PackagesCount: Integer read GetPackageCount;

    property Views[const Index: Integer]: TFIBMetaView read GetViews;
    property ViewsCount: Integer read GetViewsCount;

    property Domains[const Index: Integer]: TFIBMetaDomain read GetDomains;
    property DomainsCount: Integer read GetDomainsCount;

    property Procedures[const Index: Integer]: TFIBMetaProcedure read GetProcedures;
    property ProceduresCount: Integer read GetProceduresCount;

    property Functions[const Index: Integer]: TFIBMetaStoredFunction read GetFunctions;
    property FunctionsCount: Integer read GetFunctionsCount;

    property Exceptions[const Index: Integer]: TFIBMetaException read GetExceptions;
    property ExceptionsCount: Integer read GetExceptionsCount;

    property UDFS[const Index: Integer]: TFIBMetaUDF read GetUDFS;
    property UDFSCount: Integer read GetUDFSCount;
    property MetaDataLoaded: Boolean read FFullLoaded;
    property NamesLoaded: Boolean read GetNamesLoaded;
  published
    property Database: TFIBDatabase read FDatabase write SetDatabase;
    property DDLTextOptions: TFIBDDLTextOptions read GetDDLTextOptions write SetDDLTextOptions
      default DefSchemaExtractDDLTextOptions;
    property LoadOptions: TFIBMetaLoadOptions read FLoadOptions write SetLoadOptions;
    property OnLoadMetaData: TFIBLoadMetaDataEvent read FOnLoadMetaData write FOnLoadMetaData;
  end;

procedure FullExtractDDL(DB: TFIBDatabase; Dest: TStrings);

type
  // Deprecated names of the types renamed in 8.0.0
  TDBObjectType = TFIBDBObjectType deprecated 'Use TFIBDBObjectType';
  TDBObjectTypes = TFIBDBObjectTypes deprecated 'Use TFIBDBObjectTypes';
  TTableChildType = TFIBTableChildType deprecated 'Use TFIBTableChildType';
  TTableChildTypes = TFIBTableChildTypes deprecated 'Use TFIBTableChildTypes';
  TViewChildType = TFIBViewChildType deprecated 'Use TFIBViewChildType';
  TViewChildTypes = TFIBViewChildTypes deprecated 'Use TFIBViewChildTypes';
  TProcedureChild = TFIBProcedureChild deprecated 'Use TFIBProcedureChild';
  TProcedureChilds = TFIBProcedureChildren deprecated 'Use TFIBProcedureChildren';
  TUDFChild = TFIBUDFChild deprecated 'Use TFIBUDFChild';
  TUDFChilds = TFIBUDFChildren deprecated 'Use TFIBUDFChildren';
  TPackageChild = TFIBPackageChild deprecated 'Use TFIBPackageChild';
  TRoleChild = TFIBRoleChild deprecated 'Use TFIBRoleChild';
  TTriggerType = TFIBTriggerType deprecated 'Use TFIBTriggerType';
  TTriggerAction = TFIBTriggerAction deprecated 'Use TFIBTriggerAction';
  TTriggerActions = TFIBTriggerActions deprecated 'Use TFIBTriggerActions';
  TIndexOrder = TFIBIndexOrder deprecated 'Use TFIBIndexOrder';
  TForeignKeyRule = TFIBForeignKeyRule deprecated 'Use TFIBForeignKeyRule';
  TPrivilege = TFIBPrivilege deprecated 'Use TFIBPrivilege';
  TPrivileges = TFIBPrivileges deprecated 'Use TFIBPrivileges';
  TNotifyLoadMetaData = TFIBLoadMetaDataEvent deprecated 'Use TFIBLoadMetaDataEvent';
  TDDLTextOption = TFIBDDLTextOption deprecated 'Use TFIBDDLTextOption';
  TDDLTextOptions = TFIBDDLTextOptions deprecated 'Use TFIBDDLTextOptions';
  TCustomMetaObject = TFIBCustomMetaObject deprecated 'Use TFIBCustomMetaObject';
  TMetaObjectClass = TFIBMetaObjectClass deprecated 'Use TFIBMetaObjectClass';
  TMetaDataItem = TFIBMetaDataItem deprecated 'Use TFIBMetaDataItem';
  TCustomMetaGrant = TFIBCustomMetaGrant deprecated 'Use TFIBCustomMetaGrant';
  TMetaViewGrant = TFIBMetaViewGrant deprecated 'Use TFIBMetaViewGrant';
  TMetaTableGrant = TFIBMetaTableGrant deprecated 'Use TFIBMetaTableGrant';
  TMetaProcGrant = TFIBMetaProcedureGrant deprecated 'Use TFIBMetaProcedureGrant';
  TMetaRoleGrant = TFIBMetaRoleGrant deprecated 'Use TFIBMetaRoleGrant';
  TMetaGenerator = TFIBMetaGenerator deprecated 'Use TFIBMetaGenerator';
  TArrBounds = TFIBMetaArrayBounds deprecated 'Use TFIBMetaArrayBounds';
  TFieldDimensions = TFIBFieldDimensions deprecated 'Use TFIBFieldDimensions';
  TCustomMetaField = TFIBCustomMetaField deprecated 'Use TFIBCustomMetaField';
  TMetaField = TFIBMetaField deprecated 'Use TFIBMetaField';
  TMetaProcField = TFIBMetaProcedureField deprecated 'Use TFIBMetaProcedureField';
  TMetaProcInField = TFIBMetaProcedureInField deprecated 'Use TFIBMetaProcedureInField';
  TMetaProcOutField = TFIBMetaProcedureOutField deprecated 'Use TFIBMetaProcedureOutField';
  TMetaTableField = TFIBMetaTableField deprecated 'Use TFIBMetaTableField';
  TMetaDomain = TFIBMetaDomain deprecated 'Use TFIBMetaDomain';
  TMetaConstraint = TFIBMetaConstraint deprecated 'Use TFIBMetaConstraint';
  TMetaPrimaryKey = TFIBMetaPrimaryKey deprecated 'Use TFIBMetaPrimaryKey';
  TMetaUniqueConstraint = TFIBMetaUniqueConstraint deprecated 'Use TFIBMetaUniqueConstraint';
  TMetaForeignKey = TFIBMetaForeignKey deprecated 'Use TFIBMetaForeignKey';
  TMetaCheckConstraint = TFIBMetaCheckConstraint deprecated 'Use TFIBMetaCheckConstraint';
  TMetaIndex = TFIBMetaIndex deprecated 'Use TFIBMetaIndex';
  TCustomMetaTrigger = TFIBCustomMetaTrigger deprecated 'Use TFIBCustomMetaTrigger';
  TMetaTableTrigger = TFIBMetaTableTrigger deprecated 'Use TFIBMetaTableTrigger';
  TMetaViewTrigger = TFIBMetaViewTrigger deprecated 'Use TFIBMetaViewTrigger';
  TMetaDBTrigger = TFIBMetaDBTrigger deprecated 'Use TFIBMetaDBTrigger';
  TMetaTable = TFIBMetaTable deprecated 'Use TFIBMetaTable';
  TMetaView = TFIBMetaView deprecated 'Use TFIBMetaView';
  TMetaProcedure = TFIBMetaProcedure deprecated 'Use TFIBMetaProcedure';
  TMetaStoredFunc = TFIBMetaStoredFunction deprecated 'Use TFIBMetaStoredFunction';
  TMetaPackageProcedure = TFIBMetaPackageProcedure deprecated 'Use TFIBMetaPackageProcedure';
  TMetaPackageFunction = TFIBMetaPackageFunction deprecated 'Use TFIBMetaPackageFunction';
  TMetaPackage = TFIBMetaPackage deprecated 'Use TFIBMetaPackage';
  TMetaException = TFIBMetaException deprecated 'Use TFIBMetaException';
  TMetaUDFField = TFIBMetaUDFField deprecated 'Use TFIBMetaUDFField';
  TMetaUDF = TFIBMetaUDF deprecated 'Use TFIBMetaUDF';
  TMetaRole = TFIBMetaRole deprecated 'Use TFIBMetaRole';
  TMetaDataBase = TFIBMetaDatabase deprecated 'Use TFIBMetaDatabase';
  TLoadOptions = TFIBMetaLoadOptions deprecated 'Use TFIBMetaLoadOptions';

implementation

uses
  StdFuncs, FIBCharSets, FIBPlatforms;

procedure FullExtractDDL(DB: TFIBDatabase; Dest: TStrings);
var
  Extractor: TFIBMetaDatabase;
begin
  Extractor := TFIBMetaDatabase.Create(nil, '');
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
  // An unquoted name is taken as it is, in its case
  if (Length(MetaObjectName) > 0) and (MetaObjectName[1] = '"') then
    Result := UnquoteIdentifier(MetaObjectName)
  else
    Result := MetaObjectName
end;

function ReadOptionalString(Query: TFIBQuery; const FieldName: string): string;
var
  Field: TFIBXSQLVAR;
begin
  Field := Query.FindField(FieldName);
  if Field = nil then
    Result := ''
  else
    Result := Trim(Field.AsString);
end;

// RDB$SQL_SECURITY: -1 not set, 0 INVOKER, 1 DEFINER
function ReadSQLSecurity(Query: TFIBQuery): Integer;
var
  Field: TFIBXSQLVAR;
begin
  Field := Query.FindField('RDB$SQL_SECURITY');
  if (Field = nil) or Field.IsNull then
    Result := -1
  else if Field.AsBoolean then
    Result := 1
  else
    Result := 0;
end;

function SQLSecurityClause(Value: Integer): string;
begin
  case Value of
    0: Result := 'SQL SECURITY INVOKER';
    1: Result := 'SQL SECURITY DEFINER';
  else
    Result := '';
  end;
end;

// Of a UDR routine or trigger; Body is the AS text of an engine that has one
function ExternalClause(const Engine, EntryPoint, Body: string): string;
begin
  Result := 'EXTERNAL NAME ' + QuotedStr(EntryPoint) + sLineBreak + 'ENGINE ' + FormatIdentifier(3, Engine);
  if Body <> '' then
    Result := Result + sLineBreak + 'AS ' + QuotedStr(Body);
end;

const
  TriggerPrefixes: array [TFIBTriggerType] of string = ('BEFORE', 'AFTER', 'ON');

  TriggerSuffixes: array [TFIBTriggerAction] of string = (
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
  QRYDBSQLSecurity = 'SELECT RDB$SQL_SECURITY FROM RDB$DATABASE';

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
    'RDB$FIELD_NAME = ''RDB$DESCRIPTION'') AS COMMENTS, ' +
    '(SELECT COUNT(*) FROM RDB$RELATION_FIELDS WHERE RDB$RELATION_NAME = ''RDB$GENERATORS'' AND ' +
    'RDB$FIELD_NAME = ''RDB$GENERATOR_INCREMENT'') AS SEQUENCE_OPTIONS, ' +
    '(SELECT COUNT(*) FROM RDB$RELATION_FIELDS WHERE RDB$RELATION_NAME = ''RDB$INDICES'' AND ' +
    'RDB$FIELD_NAME = ''RDB$CONDITION_SOURCE'') AS PARTIAL_INDICES, ' +
    '(SELECT COUNT(*) FROM RDB$RELATION_FIELDS WHERE RDB$RELATION_NAME = ''RDB$PROCEDURES'' AND ' +
    'RDB$FIELD_NAME = ''RDB$ENGINE_NAME'') AS EXTERNAL_ROUTINES, ' +
    '(SELECT COUNT(*) FROM RDB$RELATION_FIELDS WHERE RDB$RELATION_NAME = ''RDB$PROCEDURES'' AND ' +
    'RDB$FIELD_NAME = ''RDB$SQL_SECURITY'') AS SQL_SECURITY ' +
    'FROM RDB$DATABASE';

  // Optional columns, filled by the server features
  DescriptionMacro = '@@DESCRIPTION@';
  DescriptionColumn = ', RDB$DESCRIPTION';
  PackageNameMacro = '@@PACK_NAME@';
  PackageNameColumn = ', RDB$PACKAGE_NAME';
  SequenceOptionsMacro = '@@SEQUENCE_OPTIONS@';
  SequenceOptionsColumns = ', RDB$INITIAL_VALUE, RDB$GENERATOR_INCREMENT';
  IndexConditionMacro = '@@CONDITION@';
  IndexConditionColumn = ', IDX.RDB$CONDITION_SOURCE';
  // Firebird 3 and later: UDR routines and triggers; Firebird 4 and later: SQL SECURITY
  RoutineOptionsMacro = '@@ROUTINE_OPTIONS@';
  ExternalColumns = ', RDB$ENGINE_NAME, RDB$ENTRYPOINT';
  SQLSecurityColumn = ', RDB$SQL_SECURITY';

  // The collation of a column: its own, else the one of its implicit domain
  CollationColumns = ', RFR.RDB$COLLATION_ID AS COLUMN_COLLATION_ID, FLD.RDB$COLLATION_ID AS DOMAIN_COLLATION_ID, ' +
    '(SELECT CO.RDB$COLLATION_NAME FROM RDB$COLLATIONS CO WHERE CO.RDB$CHARACTER_SET_ID = FLD.RDB$CHARACTER_SET_ID ' +
    'AND CO.RDB$COLLATION_ID = RFR.RDB$COLLATION_ID) AS COLUMN_COLLATION, ' +
    '(SELECT CO.RDB$COLLATION_NAME FROM RDB$COLLATIONS CO WHERE CO.RDB$CHARACTER_SET_ID = FLD.RDB$CHARACTER_SET_ID ' +
    'AND CO.RDB$COLLATION_ID = FLD.RDB$COLLATION_ID) AS DOMAIN_COLLATION ';

  QRYGenerators = 'SELECT RDB$GENERATOR_NAME ' + DescriptionMacro + ' ' + SequenceOptionsMacro +
    ' FROM RDB$GENERATORS GEN WHERE ' +
    '(NOT GEN.RDB$GENERATOR_NAME STARTING WITH ''RDB$'') AND ' +
    '(NOT GEN.RDB$GENERATOR_NAME STARTING WITH ''SQL$'') AND ' +
    '((GEN.RDB$SYSTEM_FLAG IS NULL) OR (GEN.RDB$SYSTEM_FLAG <> 1)) ' +
    'ORDER BY GEN.RDB$GENERATOR_NAME';

  QRYTables = 'SELECT REL.RDB$RELATION_NAME, REL.RDB$DESCRIPTION FROM RDB$RELATIONS REL WHERE ' +
    '(REL.RDB$SYSTEM_FLAG <> 1 OR REL.RDB$SYSTEM_FLAG IS NULL) AND ' +
    '(NOT REL.RDB$FLAGS IS NULL) AND ' + '(REL.RDB$VIEW_BLR IS NULL) AND ' +
    '(REL.RDB$SECURITY_CLASS STARTING WITH ''SQL$'') ' +
    'ORDER BY REL.RDB$RELATION_NAME';

  QRYTablesRel = 'SELECT REL.RDB$RELATION_NAME, REL.RDB$RELATION_TYPE, REL.RDB$DESCRIPTION ' + RoutineOptionsMacro +
    ' FROM RDB$RELATIONS REL WHERE ' +
    '(REL.RDB$SYSTEM_FLAG <> 1 OR REL.RDB$SYSTEM_FLAG IS NULL) AND ' +
    '(NOT REL.RDB$FLAGS IS NULL) AND ' +
    '(REL.RDB$VIEW_BLR IS NULL) AND ' +
    '(REL.RDB$SECURITY_CLASS STARTING WITH ''SQL$'') ' +
    'ORDER BY REL.RDB$RELATION_NAME';

  QRYSysTables = 'SELECT REL.RDB$RELATION_NAME, REL.RDB$DESCRIPTION FROM RDB$RELATIONS REL ' +
    'WHERE REL.RDB$VIEW_BLR IS NULL ORDER BY REL.RDB$RELATION_NAME';

  QRYSysTablesRel = 'SELECT REL.RDB$RELATION_NAME, REL.RDB$RELATION_TYPE, REL.RDB$DESCRIPTION ' + RoutineOptionsMacro +
    ' FROM RDB$RELATIONS REL ' +
    'WHERE REL.RDB$VIEW_BLR IS NULL ORDER BY REL.RDB$RELATION_NAME';

  QRYTableFields = 'SELECT FLD.RDB$FIELD_TYPE, FLD.RDB$FIELD_SCALE, ' +
    'FLD.RDB$FIELD_LENGTH, FLD.RDB$FIELD_PRECISION, ' +
    'FLD.RDB$CHARACTER_SET_ID, FLD.RDB$FIELD_SUB_TYPE, RFR.RDB$FIELD_NAME, ' +
    'FLD.RDB$SEGMENT_LENGTH, RFR.RDB$NULL_FLAG, RFR.RDB$DEFAULT_SOURCE, ' +
    'RFR.RDB$FIELD_SOURCE , FLD.RDB$COMPUTED_SOURCE, ' +
    '(Select Count(*) from  RDB$FIELD_DIMENSIONS  DIM where   DIM.rdb$field_name= RFR.RDB$FIELD_SOURCE)    is_Array, RFR.RDB$DESCRIPTION ' +
    CollationColumns +
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
    'RFR.RDB$IDENTITY_TYPE, RFR.RDB$DESCRIPTION ' + CollationColumns +
    ', (SELECT GEN.RDB$INITIAL_VALUE FROM RDB$GENERATORS GEN WHERE GEN.RDB$GENERATOR_NAME = RFR.RDB$GENERATOR_NAME) ' +
    'AS IDENTITY_START, ' +
    '(SELECT GEN.RDB$GENERATOR_INCREMENT FROM RDB$GENERATORS GEN WHERE GEN.RDB$GENERATOR_NAME = RFR.RDB$GENERATOR_NAME) ' +
    'AS IDENTITY_INCREMENT ' +
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
    'ORDER BY RC.RDB$CONSTRAINT_NAME, IDX.RDB$FIELD_POSITION';

  // An expression index has no segments
  QRYIndex = 'SELECT IDX.RDB$INDEX_NAME, ISG.RDB$FIELD_NAME, IDX.RDB$UNIQUE_FLAG, ' +
    'IDX.RDB$INDEX_INACTIVE, IDX.RDB$INDEX_TYPE, IDX.RDB$DESCRIPTION, IDX.RDB$EXPRESSION_SOURCE ' +
    IndexConditionMacro + ' FROM RDB$INDICES IDX ' +
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
    'T.RDB$TRIGGER_TYPE, T.RDB$TRIGGER_INACTIVE, T.RDB$SYSTEM_FLAG, T.RDB$DESCRIPTION ' + RoutineOptionsMacro + ' ' +
    'from RDB$TRIGGERS T left join RDB$CHECK_CONSTRAINTS C ON C.RDB$TRIGGER_NAME = ' +
    'T.RDB$TRIGGER_NAME where ((T.RDB$SYSTEM_FLAG = 0) or (T.RDB$SYSTEM_FLAG is null)) ' +
    'and (c.rdb$trigger_name is null) and (T.RDB$RELATION_NAME = ?RN) ' +
    'order by T.RDB$TRIGGER_NAME';

  QRYDBTriggers = 'SELECT T.RDB$TRIGGER_NAME, T.RDB$TRIGGER_SOURCE, T.RDB$TRIGGER_SEQUENCE, ' +
    'T.RDB$TRIGGER_TYPE, T.RDB$TRIGGER_INACTIVE, T.RDB$SYSTEM_FLAG, T.RDB$DESCRIPTION ' + RoutineOptionsMacro + ' ' +
    'from RDB$TRIGGERS T left join RDB$CHECK_CONSTRAINTS C ON C.RDB$TRIGGER_NAME = ' +
    'T.RDB$TRIGGER_NAME where ((T.RDB$SYSTEM_FLAG = 0) or (T.RDB$SYSTEM_FLAG is null)) ' +
    'and (c.rdb$trigger_name is null) and (T.RDB$RELATION_NAME  IS NULL) ' +
    'order by T.RDB$TRIGGER_NAME';

  QRYSysTrigger = 'SELECT T.RDB$TRIGGER_NAME, T.RDB$TRIGGER_SOURCE, T.RDB$TRIGGER_SEQUENCE, ' +
    'T.RDB$TRIGGER_TYPE, T.RDB$TRIGGER_INACTIVE, T.RDB$SYSTEM_FLAG, T.RDB$DESCRIPTION ' + RoutineOptionsMacro + ' ' +
    'FROM RDB$TRIGGERS T LEFT JOIN RDB$CHECK_CONSTRAINTS C ON C.RDB$TRIGGER_NAME = ' +
    'T.RDB$TRIGGER_NAME WHERE (T.RDB$RELATION_NAME = ?RN) ORDER BY T.RDB$TRIGGER_NAME';

  QRYViews = 'SELECT REL.RDB$RELATION_NAME, REL.RDB$VIEW_SOURCE, REL.RDB$DESCRIPTION FROM RDB$RELATIONS REL WHERE ' +
    '(REL.RDB$SYSTEM_FLAG <> 1 OR REL.RDB$SYSTEM_FLAG IS NULL) AND ' +
    '(NOT REL.RDB$FLAGS IS NULL) AND ' +
    '(NOT REL.RDB$VIEW_BLR IS NULL) AND ' +
    '(REL.RDB$SECURITY_CLASS STARTING WITH ''SQL$'') ' +
    'ORDER BY REL.RDB$RELATION_ID';

  // The column order is read by TFIBMetaTableField.LoadFromDataBase
  QRYSysDomains = 'select RDB$FIELD_TYPE, RDB$FIELD_SCALE, RDB$FIELD_LENGTH, ' +
    'RDB$FIELD_PRECISION, RDB$CHARACTER_SET_ID, RDB$FIELD_SUB_TYPE, ' +
    'RDB$FIELD_NAME, RDB$SEGMENT_LENGTH, RDB$NULL_FLAG, RDB$DEFAULT_SOURCE, RDB$COMPUTED_SOURCE, ' +
    'RDB$VALIDATION_SOURCE AS CHECK_CONSTRAINT, ' +
    ' (Select Count(*) from  RDB$FIELD_DIMENSIONS  DIM where   DIM.rdb$field_name= RDB$FIELDS.rdb$field_name)    is_Array, ' +
    'RDB$DESCRIPTION, RDB$COLLATION_ID AS DOMAIN_COLLATION_ID, ' +
    '(SELECT CO.RDB$COLLATION_NAME FROM RDB$COLLATIONS CO WHERE ' +
    'CO.RDB$CHARACTER_SET_ID = RDB$FIELDS.RDB$CHARACTER_SET_ID AND ' +
    'CO.RDB$COLLATION_ID = RDB$FIELDS.RDB$COLLATION_ID) AS DOMAIN_COLLATION ' +
    'FROM RDB$FIELDS';

  // The system flag also excludes the MON$ domains of Firebird 4 and later
  QRYDomains = QRYSysDomains + ' WHERE NOT (RDB$FIELD_NAME STARTING WITH ''RDB$'') AND ' +
    'NOT (RDB$FIELD_NAME STARTING WITH ''SEC$'') AND ' +
    '(RDB$SYSTEM_FLAG IS NULL OR RDB$SYSTEM_FLAG = 0)';

  QRYProcedures = 'SELECT RDB$PROCEDURE_NAME, RDB$PROCEDURE_SOURCE, RDB$DESCRIPTION ' + PackageNameMacro + ' ' +
    RoutineOptionsMacro +
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
    'PP.rdb$field_source AS F_BASED_ON_DOMAIN, ' + 'PP.RDB$DEFAULT_SOURCE, ' +
    'PP.RDB$DESCRIPTION, F.RDB$DEFAULT_SOURCE AS DOMAIN_DEFAULT_SOURCE ' +

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
    'PP.rdb$field_source AS F_BASED_ON_DOMAIN, ' + 'PP.RDB$DEFAULT_SOURCE, ' +
    'PP.RDB$RELATION_NAME, ' + 'PP.RDB$FIELD_NAME, ' +
    'PP.RDB$DESCRIPTION, F.RDB$DEFAULT_SOURCE AS DOMAIN_DEFAULT_SOURCE ' +

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
    'AND RDB$ENGINE_NAME IS NULL AND RDB$PACKAGE_NAME IS NULL ORDER BY RDB$FUNCTION_NAME';

  // PSQL and UDR functions; the packaged ones are loaded with their package
  QRYStoredFuncsFB3 = 'SELECT RDB$FUNCTION_NAME, RDB$FUNCTION_SOURCE, RDB$RETURN_ARGUMENT, RDB$PACKAGE_NAME, ' +
    'RDB$DESCRIPTION, RDB$DETERMINISTIC_FLAG ' + RoutineOptionsMacro + ' FROM RDB$FUNCTIONS ' +
    'WHERE (RDB$SYSTEM_FLAG IS NULL OR RDB$SYSTEM_FLAG = 0) AND ' +
    '(RDB$FUNCTION_SOURCE IS NOT NULL OR RDB$ENGINE_NAME IS NOT NULL) AND RDB$PACKAGE_NAME IS NULL ' +
    'ORDER BY RDB$FUNCTION_NAME';

  QRYPackageFunctions = 'SELECT RDB$FUNCTION_NAME, RDB$FUNCTION_SOURCE, RDB$RETURN_ARGUMENT, RDB$PACKAGE_NAME, ' +
    'RDB$DESCRIPTION FROM RDB$FUNCTIONS WHERE RDB$PACKAGE_NAME = ?PN ORDER BY RDB$FUNCTION_NAME';

  // The column order is read by TFIBMetaProcedureField.DoLoadFromQuery; PN is '' outside a package
  QRYStoredFuncFieldsFB3Base = 'SELECT F.RDB$FIELD_TYPE, F.RDB$FIELD_SCALE, F.RDB$FIELD_LENGTH, ' +
    'F.RDB$FIELD_PRECISION, F.RDB$CHARACTER_SET_ID, F.RDB$FIELD_SUB_TYPE, PP.RDB$ARGUMENT_NAME, ' +
    'F.RDB$SEGMENT_LENGTH, PP.RDB$ARGUMENT_MECHANISM, PP.RDB$FIELD_SOURCE, PP.RDB$DEFAULT_SOURCE, ' +
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
    RoutineOptionsMacro + ' FROM RDB$PACKAGES WHERE (RDB$SYSTEM_FLAG IS NULL OR RDB$SYSTEM_FLAG = 0)';

  QRYRoles = 'SELECT RDB$ROLE_NAME, RDB$OWNER_NAME ' + DescriptionMacro + ' FROM RDB$ROLES';

  QRYGrant = 'Select ' + 'P.RDB$USER,' + 'P.RDB$PRIVILEGE,' +
    'P.RDB$GRANT_OPTION,' + 'P.RDB$FIELD_NAME,' + 'P.RDB$USER_TYPE,' +
    'P.RDB$OBJECT_TYPE, ' + 'T1.RDB$TYPE_NAME USERTYPE ' +
    'from RDB$USER_PRIVILEGES P ' +
    'JOIN RDB$TYPES T1 ON (P.RDB$USER_TYPE= T1.RDB$TYPE and T1.RDB$FIELD_NAME=''RDB$OBJECT_TYPE'' )' +
    'WHERE P.RDB$RELATION_NAME = ?RN AND P.RDB$OBJECT_TYPE = ?OT ' + 'AND RDB$USER<>''SYSDBA'' ORDER BY 1';

  // RDB$OBJECT_TYPE of the objects with grants
  GrantOnRelation = 0;
  GrantOnProcedure = 5;
  GrantOnException = 7;
  GrantOnRole = 13;
  GrantOnGenerator = 14;
  GrantOnFunction = 15;
  GrantOnPackage = 18;
  { TFIBCustomMetaObject }

constructor TFIBCustomMetaObject.Create(AOwner: TFIBCustomMetaObject; aName: string = '');
begin
  inherited Create;
  Name := aName;
  FOwner := AOwner;
  if (FOwner <> nil) and (ClassIndex >= 0) then
    FOwner.FItems[ClassIndex].Childs.Add(Self)
end;

destructor TFIBCustomMetaObject.Destroy;
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

procedure TFIBCustomMetaObject.Clear;
var
  I: Integer;
begin
  for I := 0 to FItemsCount - 1 do
    ClearChilds(I);
  FLoaded := False
end;

procedure TFIBCustomMetaObject.ClearChilds(const ClassIndex: Integer);
var
  Childs: TList;
  I: TFIBListIndex;
begin
  Childs := FItems[ClassIndex].Childs;
  for I := 0 to Childs.Count - 1 do
    TObject(Childs[I]).Free;
  Childs.Clear;
end;

function TFIBCustomMetaObject.GetAsDDL: string;
var
  Stream: TStringStream;
  DataBase: TFIBMetaDatabase;
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

function TFIBCustomMetaObject.GetMetaDataBase: TFIBMetaDatabase;
var
  Root: TFIBCustomMetaObject;
begin
  Root := Self;
  while Root.FOwner <> nil do
    Root := Root.FOwner;
  if Root is TFIBMetaDatabase then
    Result := TFIBMetaDatabase(Root)
  else
    Result := nil;
end;

procedure TFIBCustomMetaObject.LoadDescription(Query: TFIBQuery);
var
  Field: TFIBXSQLVAR;
begin
  Field := Query.FindField('RDB$DESCRIPTION');
  if (Field <> nil) and not Field.IsNull then
    FDescription := Field.AsString
  else
    FDescription := '';
end;

function TFIBCustomMetaObject.CommentKeyword: string;
begin
  Result := '';
end;

function TFIBCustomMetaObject.CommentTarget: string;
begin
  Result := FormatName;
end;

procedure TFIBCustomMetaObject.WriteCommentDDL(Stream: TStringStream; const Target, Text: string);
var
  Statement: string;
  DataBase: TFIBMetaDatabase;
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

procedure TFIBCustomMetaObject.GenerateCommentDDL(Stream: TStringStream);
begin
  if (FDescription <> '') and (CommentKeyword <> '') then
    WriteCommentDDL(Stream, CommentKeyword + ' ' + CommentTarget, FDescription);
end;

procedure TFIBCustomMetaObject.GenerateChildCommentDDL(Stream: TStringStream; ChildType: Integer);
var
  I: Integer;
begin
  for I := 0 to GetChildsCount(ChildType) - 1 do
    GetChildObject(ChildType, I).GenerateCommentDDL(Stream);
end;

function TFIBCustomMetaObject.GetChildObject(const ClassIndex, Index: Integer): TFIBCustomMetaObject;
var
  FChilds: TList;
begin
  Result := nil;
  FChilds := FItems[ClassIndex].Childs;
  if (FChilds.Count > 0) and (Index >= 0) and (Index < FChilds.Count) then
    Result := TFIBCustomMetaObject(FChilds.Items[Index]);

end;

procedure TFIBCustomMetaObject.AddClass(ClassID: TFIBMetaObjectClass);
begin
  SetLength(FItems, FItemsCount + 1);
  FItems[FItemsCount].Childs := TList.Create;
  FItems[FItemsCount].ClassID := ClassID;
  Inc(FItemsCount);
end;

function TFIBCustomMetaObject.GenerateChildDDL(Stream: TStringStream; ChildType: Integer): Integer;
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

procedure TFIBCustomMetaObject.GenerateObjectDDL(Stream: TStringStream);
begin
end;

function TFIBCustomMetaObject.GetItems(const Index: Integer): TFIBMetaDataItem;
begin
  Assert((Index >= 0) and (FItemsCount > 0) and (Index < FItemsCount));
  Result := FItems[Index];
end;

procedure TFIBCustomMetaObject.GenerateDDLText(Stream: TStringStream);
begin
  GenerateObjectDDL(Stream);
  Stream.WriteString(DefTerminator + sLineBreak)
end;

function TFIBCustomMetaObject.GetAsObjectDDL: string;
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

function TFIBCustomMetaObject.GetChildsCount(const ClassIndex: Integer): Integer;
begin
  if FItems[ClassIndex].Childs = nil then
    Result := 0
  else
    Result := Integer(FItems[ClassIndex].Childs.Count); // the objects of one class in the database
end;

procedure TFIBCustomMetaObject.SetName(const Value: string);
begin
  FName := Value;
  FFormatName := FormatIdentifier(3, FName);
end;

function TFIBCustomMetaObject.GetChildObjectByName(const ClassIndex: Integer; const ObjectName: string): TFIBCustomMetaObject;
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
    if TFIBCustomMetaObject(FChilds.Items[I]).FName = ObjectName then
    begin
      Result := TFIBCustomMetaObject(FChilds.Items[I]);
      Exit;
    end;
  end;
end;

class function TFIBCustomMetaObject.ClassIndex: Integer;
begin
  Result := -1
end;

class function TFIBCustomMetaObject.IsSubObject: Boolean;
begin
  Result := False
end;

{ TFIBMetaGenerator }

constructor TFIBMetaGenerator.Create(AOwner: TFIBCustomMetaObject; aName: string = '');
begin
  inherited Create(AOwner, aName);
  AddClass(TFIBCustomMetaGrant);
end;

procedure TFIBMetaGenerator.LoadFromDataBase(QName: TFIBQuery);
var
  Query: TFIBQuery;
begin
  Name := Trim(QName.Fields[0].AsString);
  LoadDescription(QName);
  FOptionsLoaded := QName.FindField('RDB$GENERATOR_INCREMENT') <> nil;
  if FOptionsLoaded then
  begin
    FInitialValue := QName.FieldByName('RDB$INITIAL_VALUE').AsInt64;
    FIncrement := QName.FieldByName('RDB$GENERATOR_INCREMENT').AsInteger;
  end;
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

procedure TFIBMetaGenerator.GenerateObjectDDL(Stream: TStringStream);
begin
  Stream.WriteString('CREATE GENERATOR ' + FormatName);
  // Always START WITH: its default is 0 in Firebird 3, 1 in Firebird 4 and later
  if FOptionsLoaded then
  begin
    Stream.WriteString(' START WITH ' + IntToStr(FInitialValue));
    if FIncrement <> 1 then
      Stream.WriteString(' INCREMENT BY ' + IntToStr(FIncrement));
  end;
  Stream.WriteString(Format(';%sSET GENERATOR %s TO %d', [sLineBreak, FormatName, FValue]));
end;

function TFIBMetaGenerator.CommentKeyword: string;
begin
  Result := 'GENERATOR';
end;

class function TFIBMetaGenerator.ClassIndex: Integer;
begin
  Result := Ord(otGenerator)
end;

{ TFIBMetaTable }

constructor TFIBMetaTable.Create(AOwner: TFIBCustomMetaObject; aName: string = '');
begin
  inherited Create(AOwner, aName);
  AddClass(TFIBMetaTableField);
  AddClass(TFIBMetaPrimaryKey);
  AddClass(TFIBMetaForeignKey);
  AddClass(TFIBCustomMetaTrigger);
  AddClass(TFIBMetaUniqueConstraint);
  AddClass(TFIBMetaIndex);
  AddClass(TFIBMetaCheckConstraint);
  AddClass(TFIBCustomMetaGrant);
  FSQLSecurity := -1;
end;

function TFIBMetaTable.FindFieldName(const Name: string): TFIBMetaTableField;
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

function TFIBMetaTable.GetFields(const Index: Integer): TFIBMetaTableField;
begin
  Result := TFIBMetaTableField(GetChildObject(Ord(soTableFields), Index))
end;

function TFIBMetaTable.GetFieldsCount: Integer;
begin
  Result := GetChildsCount(Ord(soTableFields));
end;

function TFIBMetaTable.GetPrimaryKey: TFIBMetaPrimaryKey;
begin
  if FItems[Ord(soPrimaryKey)].Childs.Count > 0 then
    Result := TFIBMetaPrimaryKey(GetChildObject(Ord(soPrimaryKey), 0))
  else
    Result := nil
end;

function TFIBMetaTable.GetPrimaryKeyExist: Boolean;
begin
  Result := FItems[Ord(soPrimaryKey)].Childs.Count > 0;
end;

function TFIBMetaTable.GetUniques(const Index: Integer): TFIBMetaUniqueConstraint;
begin
  Result := TFIBMetaUniqueConstraint(GetChildObject(Ord(soUniqueConstr), Index))
end;

function TFIBMetaTable.GetUniquesCount: Integer;
begin
  Result := GetChildsCount(Ord(soUniqueConstr));
end;

procedure TFIBMetaTable.LoadFromDataBase(QNames, QFields: TFIBQuery;
  QCharset: TFIBQuery; QPrimary, QIndex, QForeign, QCheck, QTrigger: TFIBQuery;
  ChildTypes: TFIBTableChildTypes);
var
  CurName: string;
  RelationType, ConditionField: TFIBXSQLVAR;
begin
  // Fields
  Name := QNames.Fields[0].AsString;
  LoadDescription(QNames);
  RelationType := QNames.FindField('RDB$RELATION_TYPE');
  if RelationType <> nil then
    FRelationType := RelationType.AsInteger;
  FSQLSecurity := ReadSQLSecurity(QNames);

  if soTableFields in ChildTypes then
  begin
    QFields.Params[0].AsString := FName;
    QFields.ExecQuery;
    while not QFields.Eof do
    begin
      with TFIBMetaTableField.Create(Self) do
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
        TFIBMetaPrimaryKey.Create(Self).LoadFromDataBase(QPrimary);
    end;

    // INDICES
    if soIndex in ChildTypes then
    begin
      CurName := '';
      QIndex.ParamByName('RN').AsString := FName;
      QIndex.ExecQuery;
      while not QIndex.Eof do
      begin
        if CurName <> QIndex.Fields[0].AsString then
          with TFIBMetaIndex.Create(Self) do
          begin
            Name := QIndex.Fields[0].AsString;
            FExpression := Trim(QIndex.FieldByName('RDB$EXPRESSION_SOURCE').AsString);
            if FExpression = '' then
            begin
              SetLength(FFields, 1);
              FFields[0] := FindFieldIndex(QIndex.Fields[1].AsString);
            end;
            ConditionField := QIndex.FindField('RDB$CONDITION_SOURCE');
            if ConditionField <> nil then
              FCondition := Trim(ConditionField.AsString);
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
      CurName := '';
      QPrimary.Params[0].AsString := 'UNIQUE';
      if not(soPrimaryKey in ChildTypes) then
        QPrimary.Params[1].AsString := FName;
      QPrimary.ExecQuery;
      while not QPrimary.Eof do
      begin
        if CurName <> QPrimary.Fields[0].AsString then
          with TFIBMetaUniqueConstraint.Create(Self) do
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
      with TFIBMetaCheckConstraint.Create(Self) do
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
    QTrigger.ParamByName('RN').AsString := FName;
    QTrigger.ExecQuery;
    while not QTrigger.Eof do
    begin
      TFIBMetaTableTrigger.Create(Self).LoadFromDataBase(QTrigger);
      QTrigger.Next;
    end;
  end;
  FLoaded := True
end;

procedure TFIBMetaTable.GenerateDDLText(Stream: TStringStream);
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

function TFIBMetaTable.CommentKeyword: string;
begin
  Result := 'TABLE';
end;

procedure TFIBMetaTable.GenerateCommentDDL(Stream: TStringStream);
begin
  inherited GenerateCommentDDL(Stream);
  GenerateChildCommentDDL(Stream, Ord(soTableFields));
  GenerateChildCommentDDL(Stream, Ord(soIndex));
  GenerateChildCommentDDL(Stream, Ord(soTableTriggers));
end;

function TFIBMetaTable.GetIndices(const Index: Integer): TFIBMetaIndex;
begin
  Result := TFIBMetaIndex(GetChildObject(Ord(soIndex), Index))
end;

function TFIBMetaTable.GetIndicesCount: Integer;
begin
  Result := GetChildsCount(Ord(soIndex));
end;

function TFIBMetaTable.GetForeign(const Index: Integer): TFIBMetaForeignKey;
begin
  Result := TFIBMetaForeignKey(GetChildObject(Ord(soForeignKey), Index))
end;

function TFIBMetaTable.GetForeignCount: Integer;
begin
  Result := GetChildsCount(Ord(soForeignKey));
end;

function TFIBMetaTable.FindFieldIndex(const Name: string): Integer;
begin
  for Result := 0 to FieldsCount - 1 do
  begin
    if Fields[Result].FName = Name then
      Exit;
  end;
  raise Exception.CreateFmt('Field %s not found', [Name]);
end;

function TFIBMetaTable.GetChecks(const Index: Integer): TFIBMetaCheckConstraint;
begin
  Result := TFIBMetaCheckConstraint(GetChildObject(Ord(soCheckConstr), Index));
end;

function TFIBMetaTable.GetChecksCount: Integer;
begin
  Result := GetChildsCount(Ord(soCheckConstr));
end;

function TFIBMetaTable.GetTriggers(const Index: Integer): TFIBCustomMetaTrigger;
begin
  Result := TFIBCustomMetaTrigger(GetChildObject(Ord(soTableTriggers), Index));
end;

function TFIBMetaTable.GetTriggersCount: Integer;
begin
  Result := GetChildsCount(Ord(soTableTriggers));
end;

procedure TFIBMetaTable.GenerateObjectDDL(Stream: TStringStream);
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
  if FSQLSecurity >= 0 then
    Stream.WriteString(sLineBreak + SQLSecurityClause(FSQLSecurity));
end;

class function TFIBMetaTable.ClassIndex: Integer;
begin
  Result := Ord(otTable)
end;

{ TFIBCustomMetaField }

procedure TFIBCustomMetaField.LoadFromDataBase(QField, QCharset: TFIBQuery);
var
  Identity: TFIBXSQLVAR;

  procedure GetCharsetInfo(const Id: Integer; var CharSet: string; var Count: SmallInt);
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
  FSubType := QField.Fields[5].AsShort;
  if ((FFieldType in [fftChar, fftVarchar, fftCstring]) or (FFieldType = fftBlob) and (FSubType = 1)) and
    not QField.Fields[4].IsNull then
    GetCharsetInfo(QField.Fields[4].AsInteger, FCharSet, FBytesPerCharacter)
  else
    FBytesPerCharacter := 1;

  Identity := QField.FindField('RDB$IDENTITY_TYPE');
  if (Identity = nil) or Identity.IsNull then
    FIdentity := -1
  else
    FIdentity := Identity.AsInteger;
  LoadDescription(QField);
  FLoaded := True
end;

class function TFIBCustomMetaField.IsSubObject: Boolean;
begin
  Result := True
end;

function TFIBCustomMetaField.GetDimensionStr: string;
var
  J: NativeInt;
begin
  Result := '[';
  for J := 0 to High(FDimensions) do
    Result := Result + IntToStr(FDimensions[J].LOWER_BOUND) + ':' + IntToStr(FDimensions[J].UPPER_BOUND) + ',';
  Result[System.Length(Result)] := ']'
end;

procedure TFIBCustomMetaField.GenerateObjectDDL(Stream: TStringStream);
begin
  case FFieldType of
    fftNumeric:
      begin
        Stream.WriteString(GetShortFieldType);
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
      begin
        Stream.WriteString(Format('%s SUB_TYPE %d SEGMENT SIZE %d', [FieldTypes[FFieldType], FSubType, FSegmentLength]));
        if FCharSet <> '' then
          Stream.WriteString(' CHARACTER SET ' + FCharSet);
      end;
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

function TFIBCustomMetaField.GetShortFieldType: string;
begin
  case FFieldType of
    fftChar .. fftCstring: Result := Format('%s(%d)', [FieldTypes[FFieldType], FLength div FBytesPerCharacter]);
    fftNumeric:
      // DECIMAL(1..4, s) is stored as INTEGER, NUMERIC(1..4, s) as SMALLINT
      if FSubType = 2 then
        Result := Format('DECIMAL(%d,%d)', [FPrecision, FScale])
      else
        Result := Format('%s(%d,%d)', [FieldTypes[FFieldType], FPrecision, FScale]);
    fftDecFloat:
      if FLength = 8 then
        Result := FieldTypes[FFieldType] + '(16)'
      else
        Result := FieldTypes[FFieldType] + '(34)';
  else
    Result := Format('%s', [FieldTypes[FFieldType]]);
  end;
end;

{ TFIBMetaDatabase }

constructor TFIBMetaDatabase.Create(AOwner: TFIBCustomMetaObject; aName: string = '');
begin
  inherited Create(nil);
  FInternalTransaction := TFIBTransaction.Create(nil);
  FInternalTransaction.Internal := True;
  FInternalTransaction.TPBMode := tpbDefault;
  FInternalTransaction.TRParams.Add('read');
  FInternalTransaction.TRParams.Add('nowait');
  FInternalTransaction.TRParams.Add('concurrency');

  AddClass(TFIBMetaDomain);
  AddClass(TFIBMetaTable);
  AddClass(TFIBMetaView);
  AddClass(TFIBMetaProcedure);
  AddClass(TFIBMetaGenerator);
  AddClass(TFIBMetaException);
  AddClass(TFIBMetaUDF);
  AddClass(TFIBMetaRole);
  AddClass(TFIBCustomMetaTrigger);
  AddClass(TFIBMetaStoredFunction);
  AddClass(TFIBMetaPackage);

  FLoadObjects := DefObjects;
  FLoadTableChilds := DefTableChildTypes;
  FLoadViewChilds := DefViewChildTypes;
  FDDLTextOptions := DefDDLTextOptions;
  FDefaultSQLSecurity := -1;
end;

destructor TFIBMetaDatabase.Destroy;
begin
  FInternalTransaction.Free;
  inherited Destroy;
end;

procedure TFIBMetaDatabase.LoadFromDataBase(DB: TFIBDatabase; OnlyNames: Boolean = False);
var
  I: Integer;
  ConStr, Str: string;
  QCharset: TFIBQuery;
  QNames, QFields, QFuncReturn, QFuncInputs, QPrimary: TFIBQuery;
  QIndex, QForeign, QCheck, QTrigger: TFIBQuery;
  QGrants: TFIBQuery;
  Stop: Boolean;
  Transaction: TFIBTransaction;
  CurObject: TFIBCustomMetaObject;

  procedure LoadGrants(Owner: TFIBCustomMetaObject; GrantClass: TFIBMetaObjectClass; ObjectType: Integer);
  begin
    QGrants.ParamByName('RN').AsString := Owner.Name;
    QGrants.ParamByName('OT').AsInteger := ObjectType;
    QGrants.ExecQuery;
    if not QGrants.Eof then
      TFIBCustomMetaGrant(GrantClass.Create(Owner)).LoadFromDataBase(QGrants, Owner.Name);
    QGrants.Close;
  end;

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
      FUserName := Transaction.DefaultDatabase.ConnectParams.UserName;
      FClientLib := Transaction.DefaultDatabase.LibraryName;

      DetectServerFeatures;
      if FPartialIndicesSupports then
        QIndex.ParamByName('CONDITION').AsString := IndexConditionColumn;
      SetOptionalColumns(QTrigger, otDBTrigger);
      FDefaultSQLSecurity := -1;
      if FSQLSecuritySupports then
      begin
        QNames.SQL.Text := QRYDBSQLSecurity;
        QNames.ExecQuery;
        FDefaultSQLSecurity := ReadSQLSecurity(QNames);
        QNames.Close;
      end;

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
          with TFIBMetaDomain.Create(Self, QNames.FieldByName('RDB$FIELD_NAME').AsString) do
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
          CurObject := TFIBMetaGenerator.Create(Self, QNames.Fields[0].AsString);
          if not OnlyNames then
          begin
            TFIBMetaGenerator(CurObject).LoadFromDataBase(QNames);
            LoadGrants(CurObject, TFIBObjectGrant, GrantOnGenerator);
          end;
          QNames.Next;
        end;
        QNames.Close;
      end;

      if (otStoredFunctions in FLoadObjects) and FStoredFunctionsSupports then
      begin
        QNames.SQL.Text := QRYStoredFuncsFB3;
        SetOptionalColumns(QNames, otStoredFunctions);
        QNames.ExecQuery;

        while not QNames.Eof do
        begin
          if Assigned(FOnLoadMetaData) then
          begin
            FOnLoadMetaData(Self, 'Load Functions: ' + QNames.Fields[0].AsString, Stop);
            if Stop then
              Exit
          end;

          CurObject := TFIBMetaStoredFunction.Create(Self, QNames.Fields[0].AsString);
          if not OnlyNames then
          begin
            TFIBMetaStoredFunction(CurObject).LoadFromDataBase(QNames, QFuncReturn, QFuncInputs, QCharset);
            LoadGrants(CurObject, TFIBMetaProcedureGrant, GrantOnFunction);
          end;
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

          with TFIBMetaUDF.Create(Self, QNames.Fields[0].AsString) do
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
        SetOptionalColumns(QNames, otTable);
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
          CurObject := TFIBMetaTable.Create(Self, QNames.Fields[0].AsString);
          with TFIBMetaTable(CurObject) do
            if not OnlyNames then
              LoadFromDataBase(QNames, QFields, QCharset, QPrimary, QIndex,
                QForeign, QCheck, QTrigger, FLoadTableChilds);

          LoadGrants(CurObject, TFIBMetaTableGrant, GrantOnRelation);
          QNames.Next;
        end;
        QNames.Close;
        // FOREIGN
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
                with TFIBMetaForeignKey.Create(Tables[I]) do
                begin
                  Name := QForeign.Fields[0].AsString;
                  ConStr := FName;
                  if not OnlyNames then
                  begin
                    FLoaded := True;
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
              else if not OnlyNames then
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

          CurObject := TFIBMetaView.Create(Self, QNames.Fields[0].AsString);
          begin
            with TFIBMetaView(CurObject) do
              LoadFromDataBase(QNames, QFields, QTrigger, QCharset, FLoadViewChilds);

            LoadGrants(CurObject, TFIBMetaViewGrant, GrantOnRelation);
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

          CurObject := TFIBMetaProcedure.Create(Self, QNames.Fields[0].AsString);
          if not OnlyNames then
          begin
            with TFIBMetaProcedure(CurObject) do
              LoadFromDataBase(QNames, QFields, QCharset, FProcParamDomainSupports, FProcParamRelationSupports);

            LoadGrants(CurObject, TFIBMetaProcedureGrant, GrantOnProcedure);
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
          CurObject := TFIBMetaException.Create(Self, QNames.Fields[0].AsString);
          if not OnlyNames then
          begin
            TFIBMetaException(CurObject).LoadFromDataBase(QNames);
            LoadGrants(CurObject, TFIBObjectGrant, GrantOnException);
          end;
          QNames.Next;
        end;
        QNames.Close;
      end;

      // DBTriggers
      if otDBTrigger in FLoadObjects then
      begin
        QNames.SQL.Text := QRYDBTriggers;
        SetOptionalColumns(QNames, otDBTrigger);
        QNames.ExecQuery;
        while not QNames.Eof do
        begin
          if Assigned(FOnLoadMetaData) then
          begin
            FOnLoadMetaData(Self, 'Load DB Triggers: ' + QNames.Fields[0].AsString, Stop);
            if Stop then
              Exit
          end;

          with TFIBMetaDBTrigger.Create(Self, QNames.Fields[0].AsString) do
            if not OnlyNames then
              LoadFromDataBase(QNames);
          QNames.Next;
        end;
        QNames.Close;
      end;

      if FPackagesSupports and (otPackage in FLoadObjects) then
      begin
        QNames.SQL.Text := QRYPackages;
        SetOptionalColumns(QNames, otPackage);
        QNames.ExecQuery;
        while not QNames.Eof do
        begin
          if Assigned(FOnLoadMetaData) then
          begin
            FOnLoadMetaData(Self, 'Load DB Packages: ' + QNames.Fields[0].AsString, Stop);
            if Stop then
              Exit
          end;

          CurObject := TFIBMetaPackage.Create(Self, QNames.Fields[0].AsString);
          if not OnlyNames then
          begin
            TFIBMetaPackage(CurObject).LoadFromDataBase(QNames, QCharset);
            LoadGrants(CurObject, TFIBMetaProcedureGrant, GrantOnPackage);
          end;
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

            CurObject := TFIBMetaRole.Create(Self);
            TFIBMetaRole(CurObject).LoadFromDataBase(QNames);
            LoadGrants(CurObject, TFIBMetaRoleGrant, GrantOnRole);
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

procedure TFIBMetaDatabase.ExtGenerateDDLText(Stream: TStringStream; Options: TFIBDDLTextOptions = DefDDLTextOptions);
var
  I: Integer;

  procedure SaveChilds(const Comment: string; ParentType, ChildType: Integer; Separator: string = DefTerminator; Kind: Integer = 0);
  // Kind= 0 - standard, =1 -FakeViewTrigger,=2 Alter - View Trigger
  var
    I, J: Integer;
    Parent: TFIBCustomMetaObject;
    HeaderWritten: Boolean;
  begin
    HeaderWritten := False;
    for I := 0 to GetChildsCount(ParentType) - 1 do
    begin
      Parent := GetChildObject(ParentType, I);
      for J := 0 to Parent.GetChildsCount(ChildType) - 1 do
      begin
        // A foreign key of a load of the names only
        if not Parent.GetChildObject(ChildType, J).Loaded then
          Continue;
        if not HeaderWritten then
        begin
          Stream.WriteString(sLineBreak + Format('/* %s */', [Comment]) + sLineBreak);
          HeaderWritten := True;
        end;
        Stream.WriteString(sLineBreak);
        case Kind of
          0: Parent.GetChildObject(ChildType, J).GenerateObjectDDL(Stream);
          1: TFIBCustomMetaTrigger(Parent.GetChildObject(ChildType, J)).SaveFakeDDL(Stream);
          2: TFIBCustomMetaTrigger(Parent.GetChildObject(ChildType, J)).SaveAlterDDL(Stream);
        end;
        Stream.WriteString(Separator + sLineBreak);
      end;
    end;
  end;

  procedure SaveMainObjects(Comment: string; ObjType: Integer; Separator: Char = DefTerminator);
  var
    I, Count: Integer;
    CurObj: TFIBCustomMetaObject;
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

      Count := 0;
      for I := 0 to GetChildsCount(ObjType) - 1 do
      begin
        CurObj := GetChildObject(ObjType, I);
        if not CurObj.Loaded then
          CurObj := GetDBObject(FInternalTransaction.DefaultDatabase, TFIBDBObjectType(ObjType), CurObj.FName);
        // Dropped since the names were loaded
        if (CurObj = nil) or not CurObj.Loaded then
          Continue;
        Inc(Count);
        if Count = 1 then
          Stream.WriteString(sLineBreak)
        else
        begin
          Stream.WriteString(sLineBreak + sLineBreak);
        end;
        // Only the object; its constraints, triggers and bodies follow in their own sections
        if CurObj is TFIBMetaProcedure then
          TFIBMetaProcedure(CurObj).SaveToPostDDL(Stream)
        else if CurObj is TFIBMetaPackage then
          TFIBMetaPackage(CurObj).SaveSpecDDL(Stream)
        else if CurObj is TFIBMetaStoredFunction then
          TFIBMetaStoredFunction(CurObj).SaveEmptyDDL(Stream)
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
    CommentedObjects: array [0 .. 10] of TFIBDBObjectType = (otRole, otUDF, otDomain, otGenerator, otException,
      otProcedure, otStoredFunctions, otPackage, otTable, otView, otDBTrigger);
  var
    Comments: TStringStream;
    ObjType: TFIBDBObjectType;
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

    // Optional: the section is written only when an object has grants
    procedure SaveObjectGrants(const Comment: string; ObjType: TFIBDBObjectType; GrantIndex: Integer;
      Optional: Boolean = False);
    var
      I: Integer;
      Node: TFIBCustomMetaObject;
      HeaderWritten: Boolean;
    begin
      HeaderWritten := False;
      for I := 0 to GetChildsCount(Ord(ObjType)) - 1 do
      begin
        Node := GetChildObject(Ord(ObjType), I);
        if (Node.ItemsCount <= GrantIndex) or (Node.GetChildsCount(GrantIndex) = 0) then
          Continue;
        if not HeaderWritten then
        begin
          Stream.WriteString(sLineBreak + sLineBreak + Format('/*%s*/', [Comment]) + sLineBreak + sLineBreak);
          HeaderWritten := True;
        end;
        Node.GetChildObject(GrantIndex, 0).GenerateObjectDDL(Stream);
      end;
      if not HeaderWritten and not Optional then
        Stream.WriteString(sLineBreak + sLineBreak + Format('/*%s*/', [Comment]) + sLineBreak + sLineBreak);
      if HeaderWritten or not Optional then
        Stream.WriteString('COMMIT WORK;');
    end;

  begin
    Stream.WriteString(sLineBreak + sLineBreak);
    Stream.WriteString('/*GRANTS*/');
    SaveObjectGrants('GRANTS ON TABLES', otTable, Ord(soTableGrants));
    SaveObjectGrants('GRANTS ON VIEWS', otView, Ord(soViewGrants));
    SaveObjectGrants('GRANTS ON PROCEDURES', otProcedure, Ord(soProcGrants));
    SaveObjectGrants('GRANTS ON FUNCTIONS', otStoredFunctions, Ord(soProcGrants), True);
    SaveObjectGrants('GRANTS ON PACKAGES', otPackage, Ord(soProcGrants), True);
    SaveObjectGrants('GRANTS ON SEQUENCES', otGenerator, TFIBObjectGrant.ClassIndex, True);
    SaveObjectGrants('GRANTS ON EXCEPTIONS', otException, TFIBObjectGrant.ClassIndex, True);
    SaveObjectGrants('GRANTS ROLES', otRole, Ord(soRoleGrants));
  end;

var
  CurrentTerminator: Char;
  UserClause: string;
begin

  Stream.WriteString('SET SQL DIALECT ' + IntToStr(FSQLDialect) + ';' + sLineBreak);
  if FConnectCharset <> '' then
    Stream.WriteString('SET NAMES ' + FConnectCharset + ';' + sLineBreak);
  if dtoUseSetClientLib in Options then
    Stream.WriteString('SET CLIENTLIB ''' + FClientLib + ''';' + sLineBreak + sLineBreak);

  // The user of the connection, never a password
  if FUserName <> '' then
    UserClause := ' USER ' + QuotedStr(FUserName)
  else
    UserClause := '';
  if dtoUseCreateDB in Options then
  begin
    Stream.WriteString('CREATE DATABASE ''' + FName + '''' + UserClause + sLineBreak +
      'PAGE_SIZE ' + IntToStr(FPageSize));
    if Length(FDefaultCharset) > 0 then
      Stream.WriteString(sLineBreak + 'DEFAULT CHARACTER SET ' + FDefaultCharset);
    Stream.WriteString(DefTerminator + sLineBreak);
  end
  else
    Stream.WriteString('CONNECT ''' + FName + '''' + UserClause + ';' + sLineBreak);
  if FDefaultSQLSecurity >= 0 then
    Stream.WriteString('ALTER DATABASE SET DEFAULT ' + SQLSecurityClause(FDefaultSQLSecurity) + ';' + sLineBreak);

  if dtoUseSetTerm in Options then
    CurrentTerminator := ProcTerminator
  else
    CurrentTerminator := DefTerminator;
  SaveMainObjects('ROLES', Ord(otRole));
  SaveMainObjects('FUNCTIONS', Ord(otUDF));
  SaveMainObjects('DOMAINS', Ord(otDomain));
  SaveMainObjects('GENERATORS', Ord(otGenerator));
  SaveMainObjects('EXCEPTIONS', Ord(otException));
  SaveMainObjects('PROCEDURES', Ord(otProcedure), CurrentTerminator);
  SaveMainObjects('FUNCTIONS', Ord(otStoredFunctions), CurrentTerminator);
  SaveMainObjects('PACKAGES', Ord(otPackage), CurrentTerminator);
  SaveMainObjects('TABLES', Ord(otTable));
  SaveMainObjects('VIEWS', Ord(otView));
  SaveChilds('UNIQUE', Ord(otTable), Ord(soUniqueConstr));
  SaveChilds('PRIMARY', Ord(otTable), Ord(soPrimaryKey));
  SaveChilds('FOREIGN', Ord(otTable), Ord(soForeignKey));
  SaveChilds('INDICES', Ord(otTable), Ord(soIndex));
  SaveChilds('CHECKS', Ord(otTable), Ord(soCheckConstr));
  if dtoUseSetTerm in Options then
    Stream.WriteString(sLineBreak + 'SET TERM ^;' + sLineBreak);
  SaveChilds('TRIGGERS (Views)', Ord(otView), Ord(soViewTriggers), CurrentTerminator, 1);
  SaveChilds('TRIGGERS', Ord(otTable), Ord(soTableTriggers), CurrentTerminator);
  SaveChilds('TRIGGERS (Views)', Ord(otView), Ord(soViewTriggers), CurrentTerminator, 2);

  if ProceduresCount > 0 then
  begin
    Stream.WriteString(sLineBreak + '/* PROCEDURES */');
    for I := 0 to ProceduresCount - 1 do
    begin
      if not Procedures[I].Loaded then
        Continue;
      Stream.WriteString(sLineBreak + sLineBreak);
      Procedures[I].SaveToAlterDDL(Stream);
      Stream.WriteString(CurrentTerminator + sLineBreak);
    end;
  end;

  if PackageCount > 0 then
  begin
    Stream.WriteString(sLineBreak + '/* PACKAGES */');
    for I := 0 to PackageCount - 1 do
    begin
      if not Packages[I].Loaded then
        Continue;
      Stream.WriteString(sLineBreak + sLineBreak);
      if Packages[I].UsesColumnTypes then
      begin
        Packages[I].SaveHeaderAlterDDL(Stream);
        Stream.WriteString(CurrentTerminator + sLineBreak + sLineBreak);
      end;
      Packages[I].SaveBodyDDL(Stream);
      Stream.WriteString(CurrentTerminator + sLineBreak);
    end;
  end;

  if GetFunctionsCount > 0 then
  begin
    Stream.WriteString(sLineBreak + '/* FUNCTIONS */');
    for I := 0 to GetFunctionsCount - 1 do
    begin
      if not GetFunctions(I).Loaded then
        Continue;
      Stream.WriteString(sLineBreak + sLineBreak);
      GetFunctions(I).SaveAlterDDL(Stream);
      Stream.WriteString(CurrentTerminator + sLineBreak);
    end;
  end;

  if dtoUseSetTerm in Options then
    Stream.WriteString('SET TERM ;^' + sLineBreak + sLineBreak);
  // Last: a DDL trigger fires on the statements after it
  SaveMainObjects('DB TRIGGERS', Ord(otDBTrigger), CurrentTerminator);
  if CommentsIncluded(Options) then
    SaveComments;
  Stream.WriteString('COMMIT WORK;');

  if dtoIncludeGrants in Options then
    SaveGrants
end;

function TFIBMetaDatabase.GetGenerators(const Index: Integer): TFIBMetaGenerator;
begin
  Result := TFIBMetaGenerator(GetChildObject(Ord(otGenerator), Index));
end;

function TFIBMetaDatabase.GetGeneratorsCount: Integer;
begin
  Result := GetChildsCount(Ord(otGenerator))
end;

function TFIBMetaDatabase.GetTables(const Index: Integer): TFIBMetaTable;
begin
  Result := TFIBMetaTable(GetChildObject(Ord(otTable), Index));
end;

function TFIBMetaDatabase.GetTablesCount: Integer;
begin
  Result := GetChildsCount(Ord(otTable))
end;

function TFIBMetaDatabase.FindTableIndex(const TableName: string): Integer;
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

function TFIBMetaDatabase.FindDomainIndex(const DomainName: string): Integer;
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

function TFIBMetaDatabase.GetViews(const Index: Integer): TFIBMetaView;
begin
  Result := TFIBMetaView(GetChildObject(Ord(otView), Index));
end;

function TFIBMetaDatabase.GetViewsCount: Integer;
begin
  Result := GetChildsCount(Ord(otView))
end;

function TFIBMetaDatabase.GetDomains(const Index: Integer): TFIBMetaDomain;
begin

  Result := TFIBMetaDomain(GetChildObject(Ord(otDomain), Index));
end;

function TFIBMetaDatabase.GetDomainsCount: Integer;
begin
  Result := GetChildsCount(Ord(otDomain))
end;

function TFIBMetaDatabase.GetPackageCount: Integer;
begin
  Result := GetChildsCount(Ord(otPackage))
end;

function TFIBMetaDatabase.GetPackages(const Index: Integer): TFIBMetaPackage;
begin
  Result := TFIBMetaPackage(GetChildObject(Ord(otPackage), Index));
end;

function TFIBMetaDatabase.GetProcedures(const Index: Integer): TFIBMetaProcedure;
begin
  Result := TFIBMetaProcedure(GetChildObject(Ord(otProcedure), Index));
end;

function TFIBMetaDatabase.GetProceduresCount: Integer;
begin
  Result := GetChildsCount(Ord(otProcedure))
end;

function TFIBMetaDatabase.GetFunctionsCount: Integer;
begin
  Result := GetChildsCount(Ord(otStoredFunctions))
end;

function TFIBMetaDatabase.GetFunctions(const Index: Integer): TFIBMetaStoredFunction;
begin
  Result := TFIBMetaStoredFunction(GetChildObject(Ord(otStoredFunctions), Index));
end;

function TFIBMetaDatabase.GetExceptions(const Index: Integer): TFIBMetaException;
begin
  Result := TFIBMetaException(GetChildObject(Ord(otException), Index));
end;

function TFIBMetaDatabase.GetExceptionsCount: Integer;
begin
  Result := GetChildsCount(Ord(otException))
end;

function TFIBMetaDatabase.GetUDFS(const Index: Integer): TFIBMetaUDF;
begin
  Result := TFIBMetaUDF(GetChildObject(Ord(otUDF), Index));
end;

function TFIBMetaDatabase.GetUDFSCount: Integer;
begin
  Result := GetChildsCount(Ord(otUDF))
end;

function TFIBMetaDatabase.GetRoles(const Index: Integer): TFIBMetaRole;
begin
  Result := TFIBMetaRole(GetChildObject(Ord(otRole), Index));
end;

function TFIBMetaDatabase.GetRolesCount: Integer;
begin
  Result := GetChildsCount(Ord(otRole))
end;

procedure TFIBMetaDatabase.Clear;
begin
  inherited Clear;
  FNamesLoaded := False;
end;

procedure TFIBMetaDatabase.DetectServerFeatures;
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
    FSequenceOptionsSupports := Query.FieldByName('SEQUENCE_OPTIONS').AsInteger > 0;
    FPartialIndicesSupports := Query.FieldByName('PARTIAL_INDICES').AsInteger > 0;
    FExternalRoutinesSupports := Query.FieldByName('EXTERNAL_ROUTINES').AsInteger > 0;
    FSQLSecuritySupports := Query.FieldByName('SQL_SECURITY').AsInteger > 0;
  finally
    Query.Free;
  end;
  FLongStatementsSupports := FInternalTransaction.DefaultDatabase.IsFirebirdConnect and
    (FInternalTransaction.DefaultDatabase.ServerMajorVersion >= 3);
  FCodePage := FInternalTransaction.DefaultDatabase.Capabilities.CodePage;
end;

procedure TFIBMetaDatabase.SetOptionalColumns(Query: TFIBQuery; ObjectType: TFIBDBObjectType);
var
  RoutineOptions: string;
  Macro: TFIBXSQLVAR;
begin
  case ObjectType of
    otGenerator, otRole:
      begin
        if FCommentsSupports then
          Query.ParamByName('DESCRIPTION').AsString := DescriptionColumn;
        if (ObjectType = otGenerator) and FSequenceOptionsSupports then
          Query.ParamByName('SEQUENCE_OPTIONS').AsString := SequenceOptionsColumns;
      end;
    otProcedure:
      if FPackagesSupports then
        Query.ParamByName('PACK_NAME').AsString := PackageNameColumn;
  end;
  RoutineOptions := '';
  case ObjectType of
    otProcedure, otStoredFunctions, otDBTrigger:
      if FExternalRoutinesSupports then
        RoutineOptions := ExternalColumns;
  end;
  if FSQLSecuritySupports and (ObjectType in [otTable, otProcedure, otStoredFunctions, otDBTrigger, otPackage]) then
    RoutineOptions := RoutineOptions + SQLSecurityColumn;
  // Also when empty: a reused query keeps the value of its previous SQL
  Macro := Query.FindParam('ROUTINE_OPTIONS');
  if Macro <> nil then
    Macro.AsString := RoutineOptions;
end;

function TFIBMetaDatabase.ProcFieldsSQL: string;
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

function TFIBMetaDatabase.UDFFieldsSQL: string;
begin
  Result := QRYUDFFields;
  if FPackagesSupports then
    Result := Result + UDFFieldsPackageFilter;
  Result := Result + UDFFieldsOrder;
end;

function TFIBMetaDatabase.CommentsIncluded(Options: TFIBDDLTextOptions): Boolean;
begin
  Result := (dtoIncludeComments in Options) and FCommentsSupports;
end;

function TFIBMetaDatabase.CommentFits(const Statement, Text: string): Boolean;
const
  // Bytes in the charset of the connection
  MaxLiteralLength = 65535;
  MaxStatementLength = 65533;
begin
  if FLongStatementsSupports then
    Result := EncodedLength(Text, FCodePage) <= MaxLiteralLength
  else
    Result := EncodedLength(Statement, FCodePage) <= MaxStatementLength;
end;

procedure TFIBMetaDatabase.GenerateDDLText(Stream: TStringStream);
begin
  ExtGenerateDDLText(Stream, FDDLTextOptions)
end;

{ (otDomain, otTable, otView, otProcedure, otGenerator,
  otException, otUDF, otRole,otDBTrigger,motGrants) }

const
  QRY_NAMES: array [TFIBDBObjectType] of string = (
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

  QRY_NAMES_Where: array [TFIBDBObjectType] of string = (
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

  MetaNodeClasses: array [TFIBDBObjectType] of TFIBMetaObjectClass = (
    TFIBMetaDomain,
    TFIBMetaTable,
    TFIBMetaView,
    TFIBMetaProcedure,
    TFIBMetaGenerator,
    TFIBMetaException,
    TFIBMetaUDF,
    TFIBMetaRole,
    TFIBMetaDBTrigger,
    TFIBMetaStoredFunction,
    TFIBMetaPackage,
    TFIBMetaDatabase
  );

function TFIBMetaDatabase.GetDBObject(DB: TFIBDatabase; ObjectType: TFIBDBObjectType;
  const ObjectName: string; ForceLoad: Boolean): TFIBCustomMetaObject;
var
  SavedName: string;
  QNames, QFields, QFuncInputs, QCharset: TFIBQuery;
  QPrimary: TFIBQuery;
  QIndex, QForeign, QCheck, QTrigger: TFIBQuery;
  ClassOfNode: TFIBMetaObjectClass;
begin
  if ObjectType = otDatabase then
  begin
    Result := nil;
    Exit;
  end;
  SavedName := SavedMetaObjectName(ObjectName);
  Result := GetChildObjectByName(Ord(ObjectType), SavedName);
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
      if (ObjectType = otPackage) and not FPackagesSupports or
        (ObjectType = otStoredFunctions) and not FStoredFunctionsSupports then
      begin
        Result := nil;
        Exit;
      end;
      if (ObjectType = otTable) and FTabRelTypeSupports then
        QNames := CreateQuery(QRYSysTablesRel, FInternalTransaction)
      else
        QNames := CreateQuery(QRY_NAMES[ObjectType], FInternalTransaction);
      QNames.MainWhereClause := QRY_NAMES_Where[ObjectType];
      if FPackagesSupports and (ObjectType in [otProcedure, otStoredFunctions, otUDF]) then
        QNames.MainWhereClause := QNames.MainWhereClause + ' and RDB$PACKAGE_NAME IS NULL';
      // A PSQL function of Firebird 3 and later is not an external one
      if FStoredFunctionsSupports and (ObjectType = otUDF) then
        QNames.MainWhereClause := QNames.MainWhereClause + ' and RDB$FUNCTION_SOURCE IS NULL and RDB$ENGINE_NAME IS NULL';
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
          otDomain: TFIBMetaDomain(Result).LoadFromDataBase(QNames, QCharset);
          otTable:
            begin
              if FIdentityFieldsSupports then
                QFields := CreateQuery(QRYTableFieldsFB3, FInternalTransaction)
              else
                QFields := CreateQuery(QRYTableFields, FInternalTransaction);
              QPrimary := CreateQuery(QRYUnique, FInternalTransaction);
              QIndex := CreateQuery(QRYIndex, FInternalTransaction);
              if FPartialIndicesSupports then
                QIndex.ParamByName('CONDITION').AsString := IndexConditionColumn;
              QForeign := CreateQuery(QRYForeign, FInternalTransaction);
              QCheck := CreateQuery(QRYCheck, FInternalTransaction);
              QTrigger := CreateQuery(QRYTrigger, FInternalTransaction);
              SetOptionalColumns(QTrigger, otDBTrigger);
              TFIBMetaTable(Result).LoadFromDataBase(QNames, QFields, QCharset,
                QPrimary, QIndex, QForeign, QCheck, QTrigger, [soTableFields, soTableFields, soPrimaryKey, soForeignKey,
                soTableTriggers, soUniqueConstr, soIndex, soCheckConstr])
            end;

          otGenerator: TFIBMetaGenerator(Result).LoadFromDataBase(QNames);
          otUDF:
            begin
              QFields := CreateQuery(UDFFieldsSQL, FInternalTransaction);
              TFIBMetaUDF(Result).LoadFromDataBase(QNames, QFields, QCharset);
            end;
          otView:
            begin
              QFields := CreateQuery(QRYTableFields, FInternalTransaction);
              QTrigger := CreateQuery(QRYTrigger, FInternalTransaction);
              SetOptionalColumns(QTrigger, otDBTrigger);
              TFIBMetaView(Result).LoadFromDataBase(QNames, QFields, QTrigger, QCharset, [soViewFields, soViewTriggers])
            end;
          otProcedure:
            begin
              QFields := CreateQuery(ProcFieldsSQL, FInternalTransaction);
              TFIBMetaProcedure(Result).LoadFromDataBase(QNames, QFields, QCharset,
                FProcParamDomainSupports, FProcParamRelationSupports)
            end;
          otException: TFIBMetaException(Result).LoadFromDataBase(QNames);
          otRole: TFIBMetaRole(Result).LoadFromDataBase(QNames);
          otDBTrigger: TFIBCustomMetaTrigger(Result).LoadFromDataBase(QNames);
          otStoredFunctions:
            begin
              QFields := CreateQuery(QRYStoredFuncFieldsFB3Out, FInternalTransaction);
              QFuncInputs := CreateQuery(QRYStoredFuncFieldsFB3In, FInternalTransaction);
              TFIBMetaStoredFunction(Result).LoadFromDataBase(QNames, QFields, QFuncInputs, QCharset);
            end;
          otPackage: TFIBMetaPackage(Result).LoadFromDataBase(QNames, QCharset);
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

class function TFIBMetaDatabase.ClassIndex: Integer;
begin
  Result := Ord(otDatabase);
end;

{ TFIBMetaConstraint }

function TFIBMetaConstraint.GetFields(const Index: Integer): TFIBMetaTableField;
begin
  Assert((Index >= 0) and (Index < FieldsCount), IntToStr(Index) + ' ' + ClassName);
  Result := TFIBMetaTable(FOwner).Fields[FFields[Index]];
end;

function TFIBMetaConstraint.GetFieldsCount: Integer;
begin
  Result := Integer(Length(FFields));
end;

class function TFIBMetaConstraint.IsSubObject: Boolean;
begin
  Result := True
end;

{ TFIBMetaUniqueConstraint }

class function TFIBMetaUniqueConstraint.ClassIndex: Integer;
begin
  Result := Ord(soUniqueConstr)
end;

procedure TFIBMetaUniqueConstraint.GenerateObjectDDL(Stream: TStringStream);
var
  I: Integer;
begin
  if Copy(FName, 1, 6) = 'INTEG_' then
    Stream.WriteString(Format('ALTER TABLE %s ADD UNIQUE (', [TFIBMetaTable(FOwner).FormatName]))
  else
    Stream.WriteString(Format('ALTER TABLE %s ADD CONSTRAINT %s UNIQUE (',
      [TFIBMetaTable(FOwner).FormatName, FormatName]));
  for I := 0 to FieldsCount - 1 do
  begin
    Stream.WriteString(Fields[I].FormatName);
    if I <> FieldsCount - 1 then
      Stream.WriteString(', ');
  end;
  Stream.WriteString(')');
end;

{ TFIBMetaPrimaryKey }

procedure TFIBMetaPrimaryKey.LoadFromDataBase(Q: TFIBQuery);
var
  I: Integer;
begin
  Name := Q.Fields[0].AsString;
  I := 0;
  SetLength(FFields, 10000);
  while not Q.Eof do
  begin
    FFields[I] := TFIBMetaTable(FOwner).FindFieldIndex(Trim(Q.Fields[1].AsString));
    Inc(I);
    Q.Next
  end;
  SetLength(FFields, I);
  FLoaded := True
end;

procedure TFIBMetaPrimaryKey.GenerateObjectDDL(Stream: TStringStream);
var
  I: Integer;
begin
  if Copy(FName, 0, 6) = 'INTEG_' then
    Stream.WriteString(Format('ALTER TABLE %s ADD PRIMARY KEY (', [TFIBMetaTable(FOwner).FormatName]))
  else
    Stream.WriteString(Format('ALTER TABLE %s ADD CONSTRAINT %s PRIMARY KEY (',
      [TFIBMetaTable(FOwner).FormatName, FormatName]));
  for I := 0 to FieldsCount - 1 do
  begin
    Stream.WriteString(Fields[I].FormatName);
    if I <> FieldsCount - 1 then
      Stream.WriteString(', ');
  end;
  Stream.WriteString(')');
end;

class function TFIBMetaPrimaryKey.ClassIndex: Integer;
begin
  Result := Ord(soPrimaryKey)
end;

{ TFIBMetaIndex }

class function TFIBMetaIndex.ClassIndex: Integer;
begin
  Result := Ord(soIndex)
end;

function TFIBMetaIndex.CommentKeyword: string;
begin
  Result := 'INDEX';
end;

procedure TFIBMetaIndex.GenerateObjectDDL(Stream: TStringStream);
var
  I: Integer;
  Unique, Order: string;
begin
  if FUnique then
    Unique := ' UNIQUE';
  if FOrder = IoDescending then
    Order := ' DESCENDING';

  Stream.WriteString(Format('CREATE%s%s INDEX %s ON %s ', [Unique, Order, FormatName, TFIBMetaTable(FOwner).FormatName]));

  if FExpression <> '' then
    Stream.WriteString('COMPUTED BY ' + FExpression)
  else
  begin
    Stream.WriteString('(');
    for I := 0 to FieldsCount - 1 do
    begin
      Stream.WriteString(Fields[I].FormatName);
      if I <> FieldsCount - 1 then
        Stream.WriteString(', ');
    end;
    Stream.WriteString(')');
  end;
  if FCondition <> '' then
    Stream.WriteString(' ' + FCondition);
  if not FActive then
    Stream.WriteString(Format('%s%sALTER INDEX %s INACTIVE', [DefTerminator, sLineBreak, FormatName]));
end;

{ TFIBMetaForeignKey }

function TFIBMetaForeignKey.GetForFields(const Index: Integer): TFIBMetaTableField;
begin
  Assert((Index >= 0) and (Index < ForFieldsCount));
  Result := ForTable.Fields[FForFields[Index]];
end;

function TFIBMetaForeignKey.GetForFieldsCount: Integer;
begin
  Result := Integer(Length(FForFields));
end;

function TFIBMetaForeignKey.GetForTable: TFIBMetaTable;
begin
  Result := MetaDataBase.Tables[FForTable];
end;

procedure TFIBMetaForeignKey.GenerateObjectDDL(Stream: TStringStream);
var
  I: Integer;
begin
  if Copy(FName, 0, 6) = 'INTEG_' then
    Stream.WriteString(Format('ALTER TABLE %s ADD FOREIGN KEY (', [TFIBMetaTable(FOwner).FormatName]))
  else
    Stream.WriteString(Format('ALTER TABLE %s ADD CONSTRAINT %s ' + sLineBreak +
      ' FOREIGN KEY (', [TFIBMetaTable(FOwner).FormatName, FormatName]));

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
end;

class function TFIBMetaForeignKey.ClassIndex: Integer;
begin
  Result := Ord(soForeignKey)
end;

{ TFIBMetaCheckConstraint }

class function TFIBMetaCheckConstraint.ClassIndex: Integer;
begin
  Result := Ord(soCheckConstr)
end;

procedure TFIBMetaCheckConstraint.GenerateObjectDDL(Stream: TStringStream);
begin
  if Copy(FName, 1, 6) = 'INTEG_' then
    Stream.WriteString(Format('ALTER TABLE %s ADD %s', [TFIBMetaTable(FOwner).FormatName, FConstraint]))
  else
    Stream.WriteString(Format('ALTER TABLE %s ADD CONSTRAINT %s %s', [TFIBMetaTable(FOwner).FormatName, FormatName,
      FConstraint]));
end;

{ TFIBCustomMetaTrigger }

const
  TriggerKindShift = 13;
  TriggerKindDB = 1;
  TriggerKindDDL = 2;
  // All the event bits of ANY DDL STATEMENT: not the kind bits nor BEFORE/AFTER
  DDLAnyStatement = Int64($7FFFFFFFFFFF9FFE);

  // By the bit of RDB$TRIGGER_TYPE; 13 to 15 hold the trigger kind
  DDLEvents: array [1 .. 47] of string = (
    'CREATE TABLE',
    'ALTER TABLE',
    'DROP TABLE',
    'CREATE PROCEDURE',
    'ALTER PROCEDURE',
    'DROP PROCEDURE',
    'CREATE FUNCTION',
    'ALTER FUNCTION',
    'DROP FUNCTION',
    'CREATE TRIGGER',
    'ALTER TRIGGER',
    'DROP TRIGGER',
    '',
    '',
    '',
    'CREATE EXCEPTION',
    'ALTER EXCEPTION',
    'DROP EXCEPTION',
    'CREATE VIEW',
    'ALTER VIEW',
    'DROP VIEW',
    'CREATE DOMAIN',
    'ALTER DOMAIN',
    'DROP DOMAIN',
    'CREATE ROLE',
    'ALTER ROLE',
    'DROP ROLE',
    'CREATE INDEX',
    'ALTER INDEX',
    'DROP INDEX',
    'CREATE SEQUENCE',
    'ALTER SEQUENCE',
    'DROP SEQUENCE',
    'CREATE USER',
    'ALTER USER',
    'DROP USER',
    'CREATE COLLATION',
    'DROP COLLATION',
    'ALTER CHARACTER SET',
    'CREATE PACKAGE',
    'ALTER PACKAGE',
    'DROP PACKAGE',
    'CREATE PACKAGE BODY',
    'DROP PACKAGE BODY',
    'CREATE MAPPING',
    'ALTER MAPPING',
    'DROP MAPPING'
  );

class function TFIBCustomMetaTrigger.DecodePrefix(Value: Int64): TFIBTriggerType;
begin
  case Integer((Value shr TriggerKindShift) and 3) of
    TriggerKindDB: Result := ttON;
    TriggerKindDDL: Result := TFIBTriggerType(Value and 1);
  else
    Result := TFIBTriggerType((Value + 1) and 1);
  end;
end;

class function TFIBCustomMetaTrigger.DecodeSuffixes(Value: Int64): TFIBTriggerActions;
var
  V, Slot: Integer;
begin
  Result := [];
  case Integer((Value shr TriggerKindShift) and 3) of
    TriggerKindDB: Include(Result, TFIBTriggerAction(Ord(taConnect) + (Value and $FF)));
    TriggerKindDDL: ;
  else
    for Slot := 1 to 3 do
    begin
      V := ((Value + 1) shr (Slot * 2 - 1)) and 3;
      if V > 0 then
        Include(Result, TFIBTriggerAction(V - 1));
    end;
  end;
end;

function TFIBCustomMetaTrigger.IsDDLTrigger: Boolean;
begin
  Result := (FTriggerType shr TriggerKindShift) and 3 = TriggerKindDDL;
end;

function TFIBCustomMetaTrigger.DDLEventsText: string;
var
  Bit: Integer;
begin
  if FTriggerType and DDLAnyStatement = DDLAnyStatement then
    Result := 'ANY DDL STATEMENT'
  else
  begin
    Result := '';
    for Bit := Low(DDLEvents) to High(DDLEvents) do
      if (DDLEvents[Bit] <> '') and (FTriggerType and (Int64(1) shl Bit) <> 0) then
      begin
        if Result <> '' then
          Result := Result + ' OR ';
        Result := Result + DDLEvents[Bit];
      end;
  end;
end;

procedure TFIBCustomMetaTrigger.LoadFromDataBase(Q: TFIBQuery);
begin
  Name := Q.Fields[0].AsString;
  FSource := Q.Fields[1].AsString;
  FPosition := Q.Fields[2].AsShort;
  // BIGINT in Firebird 3 and later, with the DDL events
  FTriggerType := Q.Fields[3].AsInt64;
  FPrefix := DecodePrefix(FTriggerType);
  FSuffix := DecodeSuffixes(FTriggerType);
  FActive := Q.Fields[4].AsInteger = 0;
  FEngine := ReadOptionalString(Q, 'RDB$ENGINE_NAME');
  FEntryPoint := ReadOptionalString(Q, 'RDB$ENTRYPOINT');
  FSQLSecurity := ReadSQLSecurity(Q);
  LoadDescription(Q);
  FLoaded := True
end;

procedure TFIBCustomMetaTrigger.WriteBody(Stream: TStringStream);
begin
  if FEngine <> '' then
    Stream.WriteString(sLineBreak + ExternalClause(FEngine, FEntryPoint, FSource))
  else
  begin
    if FSQLSecurity >= 0 then
      Stream.WriteString(sLineBreak + SQLSecurityClause(FSQLSecurity));
    Stream.WriteString(sLineBreak + FSource);
  end;
end;

function TFIBCustomMetaTrigger.CommentKeyword: string;
begin
  Result := 'TRIGGER';
end;

procedure TFIBCustomMetaTrigger.WriteHeaderDDL(Stream: TStringStream);
var
  Count: SmallInt;
  Suf: TFIBTriggerAction;
begin
  if (FPrefix = ttON) or IsDDLTrigger then
    Stream.WriteString(Format('CREATE TRIGGER %s%s', [FormatName, sLineBreak]))
  else
    Stream.WriteString(Format('CREATE TRIGGER %s FOR %s%s', [FormatName, FOwner.FormatName, sLineBreak]));

  if FActive then
    Stream.WriteString('ACTIVE ')
  else
    Stream.WriteString('INACTIVE ');

  Stream.WriteString(TriggerPrefixes[FPrefix] + ' ');
  if IsDDLTrigger then
    Stream.WriteString(DDLEventsText)
  else
  begin
    Count := 0;
    for Suf := taInsert to taTransactionRollback do
      if Suf in FSuffix then
      begin
        Inc(Count);
        if Count > 1 then
          Stream.WriteString(' OR ');
        Stream.WriteString(TriggerSuffixes[Suf]);
      end;
  end;
  Stream.WriteString(' POSITION ' + IntToStr(FPosition));
end;

procedure TFIBCustomMetaTrigger.SaveFakeDDL(Stream: TStringStream);
begin
  // For Updateble View
  WriteHeaderDDL(Stream);
  Stream.WriteString(sLineBreak + 'AS BEGIN POST_EVENT ''FAKE''; END');
end;

procedure TFIBCustomMetaTrigger.SaveAlterDDL(Stream: TStringStream);
begin
  Stream.WriteString(Format('ALTER TRIGGER %s%s', [FormatName, sLineBreak]));
  if FActive then
    Stream.WriteString('ACTIVE')
  else
    Stream.WriteString('INACTIVE');
  WriteBody(Stream);
end;

class function TFIBCustomMetaTrigger.IsSubObject: Boolean;
begin
  Result := True
end;

procedure TFIBCustomMetaTrigger.GenerateObjectDDL(Stream: TStringStream);
begin
  WriteHeaderDDL(Stream);
  WriteBody(Stream);
end;

{ TFIBMetaTableGrant }

class function TFIBMetaTableGrant.ClassIndex: Integer;
begin
  Result := Ord(soTableGrants)
end;

{ TFIBMetaProcedureGrant }

class function TFIBMetaProcedureGrant.ClassIndex: Integer;
begin
  Result := Ord(soProcGrants)
end;

{ TFIBMetaViewGrant }

class function TFIBMetaViewGrant.ClassIndex: Integer;
begin
  Result := Ord(soViewGrants)
end;

{ TFIBMetaTableTrigger }

class function TFIBMetaTableTrigger.ClassIndex: Integer;
begin
  Result := Ord(soTableTriggers)
end;

{ TFIBMetaViewTrigger }

class function TFIBMetaViewTrigger.ClassIndex: Integer;
begin
  Result := Ord(soViewTriggers)
end;

{ TFIBMetaDBTrigger }

class function TFIBMetaDBTrigger.ClassIndex: Integer;
begin
  Result := Ord(otDBTrigger)
end;

class function TFIBMetaDBTrigger.IsSubObject: Boolean;
begin
  Result := False
end;
{ TFIBMetaRoleGrant }

class function TFIBMetaRoleGrant.ClassIndex: Integer;
begin
  Result := Ord(soRoleGrants)
end;

{ TFIBObjectGrant }

class function TFIBObjectGrant.ClassIndex: Integer;
begin
  Result := 0;
end;

{ TFIBMetaView }

constructor TFIBMetaView.Create(AOwner: TFIBCustomMetaObject; aName: string = '');
begin
  inherited Create(AOwner, aName);
  AddClass(TFIBMetaField);
  AddClass(TFIBCustomMetaTrigger);
  AddClass(TFIBCustomMetaGrant);
end;

function TFIBMetaView.GetFields(const Index: Integer): TFIBMetaField;
begin
  Result := TFIBMetaField(GetChildObject(Ord(soViewFields), Index))
end;

function TFIBMetaView.GetFieldsCount: Integer;
begin
  Result := GetChildsCount(Ord(soViewFields));
end;

function TFIBMetaView.GetTriggers(const Index: Integer): TFIBCustomMetaTrigger;
begin
  Result := TFIBCustomMetaTrigger(GetChildObject(Ord(soViewTriggers), Index))
end;

function TFIBMetaView.GetTriggersCount: Integer;
begin
  Result := GetChildsCount(Ord(soViewTriggers));
end;

procedure TFIBMetaView.LoadFromDataBase(QName, QFields, QTriggers: TFIBQuery; QCharset: TFIBQuery; ChildTypes: TFIBViewChildTypes);
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
      TFIBMetaField.Create(Self).LoadFromDataBase(QFields, QCharset);
      QFields.Next;
    end;
    QFields.Close
  end;

  // TRIGGER
  if soViewTriggers in ChildTypes then
  begin
    QTriggers.ParamByName('RN').AsString := FName;
    QTriggers.ExecQuery;
    while not QTriggers.Eof do
    begin
      TFIBMetaViewTrigger.Create(Self).LoadFromDataBase(QTriggers);
      QTriggers.Next;
    end;
  end;
  FLoaded := True
end;

procedure TFIBMetaView.GenerateDDLText(Stream: TStringStream);
begin
  inherited GenerateDDLText(Stream);
  GenerateChildDDL(Stream, Ord(soViewTriggers));
end;

procedure TFIBMetaView.GenerateObjectDDL(Stream: TStringStream);
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

class function TFIBMetaView.ClassIndex: Integer;
begin
  Result := Ord(otView)
end;

function TFIBMetaView.CommentKeyword: string;
begin
  Result := 'VIEW';
end;

procedure TFIBMetaView.GenerateCommentDDL(Stream: TStringStream);
begin
  inherited GenerateCommentDDL(Stream);
  GenerateChildCommentDDL(Stream, Ord(soViewFields));
  GenerateChildCommentDDL(Stream, Ord(soViewTriggers));
end;

procedure TFIBMetaDomain.GenerateObjectDDL(Stream: TStringStream);
begin
  Stream.WriteString('CREATE DOMAIN ');
  inherited GenerateObjectDDL(Stream);

end;

class function TFIBMetaDomain.ClassIndex: Integer;
begin
  Result := Ord(otDomain)
end;

class function TFIBMetaDomain.IsSubObject: Boolean;
begin
  Result := False
end;

function TFIBMetaDomain.CommentKeyword: string;
begin
  Result := 'DOMAIN';
end;

function TFIBMetaDomain.CommentTarget: string;
begin
  Result := FormatName;
end;
{ TFIBMetaProcedure }

constructor TFIBMetaProcedure.Create(AOwner: TFIBCustomMetaObject; aName: string = '');
begin
  inherited Create(AOwner, aName);
  AddClass(TFIBMetaProcedureInField); // in
  AddClass(TFIBMetaProcedureOutField); // out
  AddClass(TFIBCustomMetaGrant); // grant
  FSQLSecurity := -1;
end;

function TFIBMetaProcedure.GetInputFields(const Index: Integer): TFIBMetaProcedureInField;
begin
  Result := TFIBMetaProcedureInField(GetChildObject(Ord(soProcFieldIn), Index))
end;

function TFIBMetaProcedure.GetInputFieldsCount: Integer;
begin
  Result := GetChildsCount(Ord(soProcFieldIn));
end;

function TFIBMetaProcedure.GetOutputFields(const Index: Integer): TFIBMetaProcedureOutField;
begin
  Result := TFIBMetaProcedureOutField(GetChildObject(Ord(soProcFieldOut), Index))
end;

function TFIBMetaProcedure.GetOutputFieldsCount: Integer;
begin
  Result := GetChildsCount(Ord(soProcFieldOut));
end;

procedure TFIBMetaProcedure.InternalSaveToDDL(Stream: TStringStream; Operation: string; BaseTypes: Boolean = False);
var
  I: Integer;
begin
  // No operation in a package header
  if Operation <> '' then
    Stream.WriteString(Operation + ' ');
  Stream.WriteString('PROCEDURE ' + FormatName);
  if InputFieldsCount > 0 then
  begin
    Stream.WriteString(' (');
    for I := 0 to InputFieldsCount - 1 do
    begin
      Stream.WriteString(sLineBreak + '   ');
      InputFields[I].WriteDeclaration(Stream, BaseTypes);
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
      OutputFields[I].WriteDeclaration(Stream, BaseTypes);
      if I <> OutputFieldsCount - 1 then
        Stream.WriteString(',');
    end;
    Stream.WriteString(')');
  end;
end;

procedure TFIBMetaProcedure.LoadFromDataBase(QNames, QFields: TFIBQuery;
  QCharset: TFIBQuery; CanUseParamDomain, CanUseProcParamRelation: Boolean);
var
  Field, PackageParam: TFIBXSQLVAR;
begin
  Name := QNames.Fields[0].AsString;
  FSource := QNames.Fields[1].AsString;
  Field := QNames.FindField('RDB$PACKAGE_NAME');
  if Field <> nil then
    FPackageName := Field.AsString;
  FEngine := ReadOptionalString(QNames, 'RDB$ENGINE_NAME');
  FEntryPoint := ReadOptionalString(QNames, 'RDB$ENTRYPOINT');
  FSQLSecurity := ReadSQLSecurity(QNames);
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
    TFIBMetaProcedureInField.Create(Self).DoLoadFromQuery(QFields, QCharset, CanUseParamDomain, CanUseProcParamRelation);
    QFields.Next;
  end;
  QFields.Close;

  // Extract Out params
  QFields.Params[1].AsInteger := 1; // out
  QFields.ExecQuery;
  while not QFields.Eof do
  begin
    TFIBMetaProcedureOutField.Create(Self).DoLoadFromQuery(QFields, QCharset, CanUseParamDomain, CanUseProcParamRelation);
    QFields.Next;
  end;
  QFields.Close;
  FLoaded := True

end;

procedure TFIBMetaProcedure.WriteBody(Stream: TStringStream);
begin
  if FEngine <> '' then
    Stream.WriteString(sLineBreak + ExternalClause(FEngine, FEntryPoint, FSource))
  else
  begin
    if FSQLSecurity >= 0 then
      Stream.WriteString(sLineBreak + SQLSecurityClause(FSQLSecurity));
    // Firebird 2.5 keeps the spaces after AS in the source, not a line break
    Stream.WriteString(sLineBreak + 'AS' + sLineBreak);
    Stream.WriteString(FSource);
  end;
end;

procedure TFIBMetaProcedure.SaveToAlterDDL(Stream: TStringStream);
begin
  InternalSaveToDDL(Stream, 'ALTER');
  WriteBody(Stream);
end;

procedure TFIBMetaProcedure.SaveToPostDDL(Stream: TStringStream);
begin
  // Before the tables: a TYPE OF COLUMN parameter is written as its type
  InternalSaveToDDL(Stream, 'CREATE', True);
  // A UDR procedure has no PSQL dependencies
  if FEngine <> '' then
  begin
    WriteBody(Stream);
    Exit;
  end;
  Stream.WriteString(sLineBreak + 'AS' + sLineBreak + 'BEGIN' + sLineBreak);
  // SUSPEND needs output parameters in Firebird 3 and later
  if OutputFieldsCount > 0 then
    Stream.WriteString('  SUSPEND;')
  else
    Stream.WriteString('  EXIT;');
  Stream.WriteString(sLineBreak + 'END');
end;

procedure TFIBMetaProcedure.GenerateObjectDDL(Stream: TStringStream);
begin
  InternalSaveToDDL(Stream, 'CREATE');
  WriteBody(Stream);
end;

class function TFIBMetaProcedure.ClassIndex: Integer;
begin
  Result := Ord(otProcedure)
end;

function TFIBMetaProcedure.CommentKeyword: string;
begin
  Result := 'PROCEDURE';
end;

function TFIBMetaProcedure.CommentTarget: string;
begin
  Result := RoutineName(FPackageName, FormatName);
end;

procedure TFIBMetaProcedure.GenerateCommentDDL(Stream: TStringStream);
begin
  inherited GenerateCommentDDL(Stream);
  GenerateChildCommentDDL(Stream, Ord(soProcFieldIn));
  GenerateChildCommentDDL(Stream, Ord(soProcFieldOut));
end;

{ TFIBMetaException }

constructor TFIBMetaException.Create(AOwner: TFIBCustomMetaObject; aName: string = '');
begin
  inherited Create(AOwner, aName);
  AddClass(TFIBCustomMetaGrant);
end;

procedure TFIBMetaException.LoadFromDataBase(QName: TFIBQuery);
var
  MessageField: TFIBXSQLVAR;
  Bytes: AnsiString;
  CodePage: Word;
begin
  Name := QName.Fields[0].AsString;
  MessageField := QName.Fields[1];
  // RDB$MESSAGE has the charset NONE: the bytes of the statement that made the exception
  if not MessageField.IsNull and (Byte(MessageField.Data.sqlsubtype) = 0) then
  begin
    Bytes := MessageField.AsAnsiString;
    CodePage := QName.Database.Capabilities.MetadataCodePage;
    if CodePage = FIBCodePageUTF8 then
      FMessage := DecodeServerText(PAnsiChar(Bytes), Length(Bytes))
    else
      FMessage := DecodeString(PAnsiChar(Bytes), Length(Bytes), CodePage);
  end
  else
    FMessage := MessageField.AsString;
  FNumber := QName.Fields[2].AsInteger;
  LoadDescription(QName);
  FLoaded := True
end;

procedure TFIBMetaException.GenerateObjectDDL(Stream: TStringStream);
begin
  Stream.WriteString('CREATE EXCEPTION ' + FormatName + ' ' + QuotedStr(FMessage));
end;

function TFIBMetaException.CommentKeyword: string;
begin
  Result := 'EXCEPTION';
end;

class function TFIBMetaException.ClassIndex: Integer;
begin
  Result := Ord(otException)
end;

{ TFIBMetaUDF }

constructor TFIBMetaUDF.Create(AOwner: TFIBCustomMetaObject; aName: string = '');
begin
  inherited Create(AOwner, aName);
  AddClass(TFIBMetaUDFField);
end;

procedure TFIBMetaUDF.GenerateObjectDDL(Stream: TStringStream);
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

procedure TFIBMetaUDF.LoadFromDataBase(QNames, QFields: TFIBQuery; QCharset: TFIBQuery);
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
    TFIBMetaUDFField.Create(Self).LoadFromDataBase(QFields, QCharset);
    QFields.Next;
  end;
  QFields.Close;
  FLoaded := True
end;

function TFIBMetaUDF.GetFields(const Index: Integer): TFIBMetaUDFField;
begin
  Result := TFIBMetaUDFField(GetChildObject(Ord(soUDFField), Index))
end;

function TFIBMetaUDF.GetFieldsCount: Integer;
begin
  Result := GetChildsCount(Ord(soUDFField));
end;

class function TFIBMetaUDF.ClassIndex: Integer;
begin
  Result := Ord(otUDF)
end;

function TFIBMetaUDF.CommentKeyword: string;
begin
  Result := 'EXTERNAL FUNCTION';
end;

{ TFIBMetaTableField }

function TFIBMetaTableField.GetDomain: TFIBMetaDomain;
begin
  if FDomain >= 0 then
    Result := MetaDataBase.Domains[FDomain]
  else
    Result := nil;
end;

procedure TFIBMetaTableField.LoadFromDataBase(Q: TFIBQuery; C: TFIBQuery);
var
  QDims: TFIBQuery;
  J: Integer;
  ColumnCollationID, DomainCollationID, IdentityStart, IdentityIncrement: TFIBXSQLVAR;
begin
  inherited LoadFromDataBase(Q, C);
  // A collation other than the default one of the charset, or other than the one of the domain
  FCollation := '';
  ColumnCollationID := Q.FindField('COLUMN_COLLATION_ID');
  DomainCollationID := Q.FindField('DOMAIN_COLLATION_ID');
  if (ColumnCollationID = nil) or ColumnCollationID.IsNull then
  begin
    if (DomainCollationID <> nil) and (DomainCollationID.AsInteger <> 0) and
      ((Self is TFIBMetaDomain) or (Copy(Q.Fields[10].AsString, 1, 4) = 'RDB$')) then
      FCollation := Trim(Q.FieldByName('DOMAIN_COLLATION').AsString);
  end
  else if Copy(Q.Fields[10].AsString, 1, 4) = 'RDB$' then
  begin
    if ColumnCollationID.AsInteger <> 0 then
      FCollation := Trim(Q.FieldByName('COLUMN_COLLATION').AsString);
  end
  else if ColumnCollationID.AsInteger <> DomainCollationID.AsInteger then
    FCollation := Trim(Q.FieldByName('COLUMN_COLLATION').AsString);
  IdentityStart := Q.FindField('IDENTITY_START');
  IdentityIncrement := Q.FindField('IDENTITY_INCREMENT');
  if (IdentityStart <> nil) and not IdentityStart.IsNull then
  begin
    FIdentityStart := IdentityStart.AsInt64;
    FIdentityIncrement := IdentityIncrement.AsInteger;
  end
  else
  begin
    FIdentityStart := 0;
    FIdentityIncrement := 1;
  end;
  FNotNull := (Q.Fields[8].AsInteger = 1);
  if not Q.Fields[9].IsNull then
    FDefaultValue := CutDefaultValue(Q.Fields[9].AsString)
  else
    FDefaultValue := '';

  FDomain := -1;
  if not(Self is TFIBMetaDomain) then
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
      if not(Self is TFIBMetaDomain) then
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

procedure TFIBMetaTableField.GenerateObjectDDL(Stream: TStringStream);
var
  Collation: string;
begin
  Collation := FCollation;
  if (FDomainName <> '') and (dtoDecodeDomains in MetaDataBase.DDLTextOptions) and (Collation = '') and
    (Domain <> nil) then
    Collation := Domain.FCollation;
  if (FDomainName <> '') and not(dtoDecodeDomains in MetaDataBase.DDLTextOptions) then
  begin
    Stream.WriteString(FormatName + ' ');
    Stream.WriteString(FormatIdentifier(3, FDomainName))
  end
  else if FComputedSource <> '' then
  begin
    Stream.WriteString(FormatName + ' ');
    Stream.WriteString('COMPUTED BY ' + FComputedSource)
  end
  else
    inherited GenerateObjectDDL(Stream);
  case FIdentity of
    0, 1:
      begin
        if FIdentity = 0 then
          Stream.WriteString(' GENERATED ALWAYS AS IDENTITY')
        else
          Stream.WriteString(' GENERATED BY DEFAULT AS IDENTITY');
        // Always START WITH: its default is 0 in Firebird 3, 1 in Firebird 4 and later
        Stream.WriteString(' (START WITH ' + IntToStr(FIdentityStart));
        if FIdentityIncrement <> 1 then
          Stream.WriteString(' INCREMENT BY ' + IntToStr(FIdentityIncrement));
        Stream.WriteString(')');
      end;
  else
    if FDefaultValue <> '' then
      Stream.WriteString(' DEFAULT ' + FDefaultValue);
    if FNotNull then
      Stream.WriteString(' NOT NULL');
    if FValidationSource <> '' then
      Stream.WriteString(sLineBreak + FValidationSource);
    if (Collation <> '') and (FComputedSource = '') then
      Stream.WriteString(' COLLATE ' + FormatIdentifier(3, Collation));
  end;
end;

class function TFIBMetaTableField.ClassIndex: Integer;
begin
  Result := Ord(soTableFields)
end;

{ TFIBMetaField }

procedure TFIBMetaField.LoadFromDataBase(QField, QCharset: TFIBQuery);
begin
  inherited LoadFromDataBase(QField, QCharset);
  Name := QField.Fields[6].AsString;
  FSegmentLength := QField.Fields[7].AsShort;
end;

procedure TFIBMetaField.GenerateObjectDDL(Stream: TStringStream);
begin
  if Self is TFIBMetaDomain then
    Stream.WriteString(FormatName + ' AS ')
  else if FormatName <> '' then
    Stream.WriteString(FormatName + ' ');
  inherited GenerateObjectDDL(Stream);
end;

class function TFIBMetaField.ClassIndex: Integer;
begin
  Result := Ord(soViewFields)
end;

function TFIBMetaField.CommentKeyword: string;
begin
  Result := 'COLUMN';
end;

function TFIBMetaField.CommentTarget: string;
begin
  // The owner gives its package, if any
  Result := FOwner.CommentTarget + '.' + FormatName;
end;

{ TFIBMetaUDFField }

procedure TFIBMetaUDFField.LoadFromDataBase(QField, QCharset: TFIBQuery);
begin
  inherited LoadFromDataBase(QField, QCharset);
  FPosition := QField.Fields[6].AsShort;
  FMechanism := QField.Fields[7].AsShort;
  Name := 'Field ' + IntToStr(FPosition);
  FLoaded := True
end;

procedure TFIBMetaUDFField.GenerateObjectDDL(Stream: TStringStream);
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

class function TFIBMetaUDFField.ClassIndex: Integer;
begin
  Result := Ord(soUDFField)
end;

{ TFIBMetaRole }

procedure TFIBMetaRole.LoadFromDataBase(QName: TFIBQuery);
begin
  Name := QName.Fields[0].AsString;
  FOwner := QName.Fields[1].AsString;
  LoadDescription(QName);
  FLoaded := True
end;

function TFIBMetaRole.CommentKeyword: string;
begin
  Result := 'ROLE';
end;

procedure TFIBMetaRole.GenerateObjectDDL(Stream: TStringStream);
begin
  Stream.WriteString(Format('CREATE ROLE %s /* By user %s */', [FormatName, Trim(FOwner)]));
end;

constructor TFIBMetaRole.Create(AOwner: TFIBCustomMetaObject; aName: string = '');
begin
  inherited Create(AOwner, aName);
  AddClass(TFIBCustomMetaGrant)

end;

class function TFIBMetaRole.ClassIndex: Integer;
begin
  Result := Ord(otRole)
end;

{ TFIBMetaProcedureField }

procedure TFIBMetaProcedureField.DoLoadFromQuery(QField: TFIBQuery; QCharset: TFIBQuery; CanUseParamDomain, CanUseProcParamRelation: Boolean);
var
  Check_PREFIX: string;
  DomainDefault: TFIBXSQLVAR;
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
    end;
    // "= value" or "DEFAULT value" of the parameter, whatever its type; Firebird 2.5 keeps the one
    // of a parameter without a domain in its implicit domain
    FDefaultValue := Trim(QField.Fields[10].AsString);
    DomainDefault := QField.FindField('DOMAIN_DEFAULT_SOURCE');
    if (FDefaultValue = '') and not FUseDomain and not FUseRelation and (DomainDefault <> nil) then
      FDefaultValue := Trim(DomainDefault.AsString);
  end
  else
    FUseDomain := False;

  FLoaded := True
end;

procedure TFIBMetaProcedureField.WriteDeclaration(Stream: TStringStream; BaseType: Boolean);
begin
  // TYPE OF COLUMN has the domain of the column as field source
  if FUseRelation and not BaseType then
  begin
    if FormatName <> '' then
      Stream.WriteString(FormatName + ' ');
    Stream.WriteString('TYPE OF COLUMN ' + FormatIdentifier(3, FRelationObject) +
      '.' + FormatIdentifier(3, FRelationField))
  end
  else if FUseDomain and not FUseRelation then
  begin
    if FormatName <> '' then
      Stream.WriteString(FormatName + ' ');
    case FMechanizm of
      0: Stream.WriteString(FormatIdentifier(3, FDomain));
      1: Stream.WriteString('TYPE OF ' + FormatIdentifier(3, FDomain))
    end
  end
  else
    inherited GenerateObjectDDL(Stream);
  if FDefaultValue <> '' then
    Stream.WriteString(' ' + FDefaultValue);
end;

procedure TFIBMetaProcedureField.GenerateObjectDDL(Stream: TStringStream);
begin
  WriteDeclaration(Stream, False);
end;

function TFIBMetaProcedureField.CommentKeyword: string;
begin
  // Firebird 3 needs the routine kind when a procedure and a function have the same name
  if FOwner is TFIBMetaStoredFunction then
    Result := 'FUNCTION PARAMETER'
  else if (MetaDataBase <> nil) and MetaDataBase.FStoredFunctionsSupports then
    Result := 'PROCEDURE PARAMETER'
  else
    Result := 'PARAMETER';
end;

{ TFIBMetaProcedureInField }

class function TFIBMetaProcedureInField.ClassIndex: Integer;
begin
  Result := Ord(soProcFieldIn)
end;
{ TFIBMetaProcedureOutField }

class function TFIBMetaProcedureOutField.ClassIndex: Integer;
begin
  Result := Ord(soProcFieldOut)
end;

{ TFIBCustomMetaGrant }

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
  TDynArray1 = array of Boolean;

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

procedure TFIBCustomMetaGrant.GenerateObjectDDL(Stream: TStringStream);
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
      Stream.WriteString('GRANT ' + FormatIdentifier(3, FObjectName) + ' TO ');
      Stream.WriteString(sLineBreak + '  ' + FUserList[I]);
      if FWithGrantOption[I] then
        Stream.WriteString(' WITH ADMIN OPTION');
    end
    else if (FPrivileges[I] = [goExecuteProc]) or (FPrivileges[I] = [goUsage]) then
    begin
      if goUsage in FPrivileges[I] then
        Stream.WriteString('GRANT USAGE ON ')
      else
        Stream.WriteString('GRANT EXECUTE ON ');
      case FObjectType of
        GrantOnFunction: Stream.WriteString('FUNCTION ');
        GrantOnPackage: Stream.WriteString('PACKAGE ');
        GrantOnGenerator: Stream.WriteString('SEQUENCE ');
        GrantOnException: Stream.WriteString('EXCEPTION ');
      else
        Stream.WriteString('PROCEDURE ');
      end;
      Stream.WriteString(FormatIdentifier(3, FObjectName) + ' TO');
      Stream.WriteString(sLineBreak + '  ' + FUserList[I]);
      if FWithGrantOption[I] then
        Stream.WriteString(' WITH GRANT OPTION');
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

function TFIBCustomMetaGrant.GetSize: Integer;
begin
  Result := Integer(Length(FUserList)) // grants of one object
end;

procedure TFIBCustomMetaGrant.LoadFromDataBase(QGrants: TFIBQuery; const Name: string; Pack: Boolean = True);
var
  I, L, J: Integer;
  s: string;
  CurUser: string;

begin
  FObjectName := Name;
  FObjectType := QGrants.Fields[5].AsInteger;
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
    if I >= L then
    begin
      Inc(L, 200);
      SetSize(L);
    end;

    CurUser := Trim(QGrants.Fields[0].AsString);
    // PUBLIC is a keyword, not a name
    if CurUser <> 'PUBLIC' then
      CurUser := FormatIdentifier(3, CurUser);
    s := QGrants.Fields[6].AsString;
    // A function grantee is of the type UDF
    if s = 'UDF' then
      s := 'FUNCTION';
    if (s <> 'USER') and (s <> 'ROLE') then
      CurUser := s + ' ' + CurUser;
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
      'G': FPrivileges[I] := FPrivileges[I] + [goUsage];
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

procedure TFIBCustomMetaGrant.SetSize(Size: Integer);
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
  FMetaDatabase := TFIBMetaDatabase.Create(nil);
  FMetaDatabase.OnLoadMetaData := DoOnLoadMetaData;
  FMetaDatabase.DDLTextOptions := DefSchemaExtractDDLTextOptions;
  FLoadOptions := TFIBMetaLoadOptions.Create;
end;

function TFIBDBSchemaExtract.GetDDLTextOptions: TFIBDDLTextOptions;
begin
  Result := FMetaDatabase.DDLTextOptions;
end;

procedure TFIBDBSchemaExtract.SetDDLTextOptions(const Value: TFIBDDLTextOptions);
begin
  FMetaDatabase.DDLTextOptions := Value;
end;

destructor TFIBDBSchemaExtract.Destroy;
begin
  FLoadOptions.Free;
  FMetaDatabase.Free;
  inherited;
end;

procedure TFIBDBSchemaExtract.SetLoadOptions(const Value: TFIBMetaLoadOptions);
begin
  FLoadOptions.Assign(Value);
end;

function TFIBDBSchemaExtract.ObjectByName(ObjectType: TFIBDBObjectType; const ObjectName: string; ForceLoad: Boolean): TFIBCustomMetaObject;
begin
  Result := FMetaDatabase.GetDBObject(Database, ObjectType, ObjectName, ForceLoad)
end;

function TFIBDBSchemaExtract.GetObjectDDL(ObjectType: TFIBDBObjectType; const ObjectName: string; ForceLoad: Boolean = True): string;
var
  N: TFIBCustomMetaObject;
begin
  N := FMetaDatabase.GetDBObject(Database, ObjectType, ObjectName, ForceLoad);
  if Assigned(N) then
    Result := N.AsDDL
  else
    Result := ''
end;

procedure TFIBDBSchemaExtract.DoOnLoadMetaData(Sender: TObject; const Message: string; var Stop: Boolean);
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

function TFIBDBSchemaExtract.GetDomains(const Index: Integer): TFIBMetaDomain;
begin
  Result := FMetaDatabase.GetDomains(Index)
end;

function TFIBDBSchemaExtract.GetDomainsCount: Integer;
begin
  Result := FMetaDatabase.GetDomainsCount
end;

function TFIBDBSchemaExtract.GetExceptions(const Index: Integer): TFIBMetaException;
begin
  Result := FMetaDatabase.GetExceptions(Index)
end;

function TFIBDBSchemaExtract.GetExceptionsCount: Integer;
begin
  Result := FMetaDatabase.GetExceptionsCount
end;

function TFIBDBSchemaExtract.GetGenerators(const Index: Integer): TFIBMetaGenerator;
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

function TFIBDBSchemaExtract.GetPackages(const Index: Integer): TFIBMetaPackage;
begin
  Result := FMetaDatabase.GetPackages(Index)
end;

function TFIBDBSchemaExtract.GetProcedures(const Index: Integer): TFIBMetaProcedure;
begin
  Result := FMetaDatabase.GetProcedures(Index)
end;

function TFIBDBSchemaExtract.GetProceduresCount: Integer;
begin
  Result := FMetaDatabase.GetProceduresCount
end;

function TFIBDBSchemaExtract.GetFunctions(const Index: Integer): TFIBMetaStoredFunction;
begin
  Result := FMetaDatabase.GetFunctions(Index)
end;

function TFIBDBSchemaExtract.GetFunctionsCount: Integer;
begin
  Result := FMetaDatabase.GetFunctionsCount
end;

function TFIBDBSchemaExtract.GetTables(const Index: Integer): TFIBMetaTable;
begin
  Result := FMetaDatabase.GetTables(Index)
end;

function TFIBDBSchemaExtract.GetTablesCount: Integer;
begin
  Result := FMetaDatabase.GetTablesCount
end;

function TFIBDBSchemaExtract.GetUDFS(const Index: Integer): TFIBMetaUDF;
begin
  Result := FMetaDatabase.GetUDFS(Index)
end;

function TFIBDBSchemaExtract.GetUDFSCount: Integer;
begin
  Result := FMetaDatabase.GetUDFSCount
end;

function TFIBDBSchemaExtract.GetViews(const Index: Integer): TFIBMetaView;
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

procedure TFIBDBSchemaExtract.LoadMetaData(OnlyNames: Boolean = False);
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

function TFIBDBSchemaExtract.GetMetaDataBase: TFIBMetaDatabase;
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

constructor TFIBMetaLoadOptions.Create;
begin
  inherited Create;

  FLoadObjects := DefObjects;
  FLoadTableChilds := DefTableChildTypes;
  FLoadViewChilds := DefViewChildTypes;

end;

function TFIBDBSchemaExtract.GetNamesLoaded: Boolean;
begin
  Result := FMetaDatabase.FNamesLoaded
end;

{ TFIBMetaStoredFunction }

class function TFIBMetaStoredFunction.ClassIndex: Integer;
begin
  Result := Ord(otStoredFunctions)
end;

constructor TFIBMetaStoredFunction.Create(AOwner: TFIBCustomMetaObject; aName: string);
begin
  inherited Create(AOwner, aName);
  AddClass(TFIBMetaProcedureInField); // in
  AddClass(TFIBMetaProcedureOutField); // out
  AddClass(TFIBCustomMetaGrant); // grant
  FSQLSecurity := -1;
end;

procedure TFIBMetaStoredFunction.GenerateObjectDDL(Stream: TStringStream);
begin
  InternalSaveToDDL(Stream, 'CREATE');
  WriteBody(Stream);
end;

function TFIBMetaStoredFunction.GetInputFields(const Index: Integer): TFIBMetaProcedureInField;
begin
  Result := TFIBMetaProcedureInField(GetChildObject(Ord(soProcFieldIn), Index))
end;

function TFIBMetaStoredFunction.GetInputFieldsCount: Integer;
begin
  Result := GetChildsCount(Ord(soProcFieldIn));
end;

function TFIBMetaStoredFunction.GetReturn: TFIBMetaProcedureOutField;
begin
  if FItems[Ord(soProcFieldOut)].Childs.Count > 0 then
    Result := TFIBMetaProcedureOutField(GetChildObject(Ord(soProcFieldOut), 0))
  else
    Result := nil
end;

procedure TFIBMetaStoredFunction.InternalSaveToDDL(Stream: TStringStream; Operation: string; BaseTypes: Boolean = False);
var
  I: Integer;
begin
  // No operation in a package header
  if Operation <> '' then
    Stream.WriteString(Operation + ' ');
  Stream.WriteString('FUNCTION ' + FormatName);

  if InputFieldsCount > 0 then
  begin
    if InputFieldsCount > 1 then
    begin
      Stream.WriteString(' (');
      for I := 0 to InputFieldsCount - 1 do
      begin
        Stream.WriteString(sLineBreak + '   ');
        InputFields[I].WriteDeclaration(Stream, BaseTypes);
        if I <> InputFieldsCount - 1 then
          Stream.WriteString(',');
      end;
      Stream.WriteString(')');
    end
    else
    begin
      Stream.WriteString(' (');
      InputFields[0].WriteDeclaration(Stream, BaseTypes);
      Stream.WriteString(')');
    end;
  end;

  Stream.WriteString(Format('%sRETURNS ', [sLineBreak]));
  if Return <> nil then
    Return.WriteDeclaration(Stream, BaseTypes);
  if FDeterministic then
    Stream.WriteString(' DETERMINISTIC');
end;

procedure TFIBMetaStoredFunction.WriteBody(Stream: TStringStream);
begin
  if FEngine <> '' then
    Stream.WriteString(sLineBreak + ExternalClause(FEngine, FEntryPoint, FSource))
  else
  begin
    if FSQLSecurity >= 0 then
      Stream.WriteString(sLineBreak + SQLSecurityClause(FSQLSecurity));
    Stream.WriteString(sLineBreak + 'AS' + sLineBreak);
    Stream.WriteString(FSource);
  end;
end;

type
  TMetaProcFieldClass = class of TFIBMetaProcedureField;

procedure TFIBMetaStoredFunction.LoadFromDataBase(QNames, QReturn, QInputs, QCharset: TFIBQuery);

  procedure LoadFields(Query: TFIBQuery; FieldClass: TMetaProcFieldClass);
  begin
    Query.ParamByName('FN').AsString := FName;
    Query.ParamByName('PN').AsString := FPackageName;
    Query.ExecQuery;
    while not Query.Eof do
    begin
      TFIBMetaProcedureField(FieldClass.Create(Self)).DoLoadFromQuery(Query, QCharset, True, True);
      Query.Next;
    end;
    Query.Close;
  end;

begin
  Name := QNames.Fields[0].AsString;
  FSource := QNames.Fields[1].AsString;
  FPackageName := QNames.Fields[3].AsString;
  FEngine := ReadOptionalString(QNames, 'RDB$ENGINE_NAME');
  FEntryPoint := ReadOptionalString(QNames, 'RDB$ENTRYPOINT');
  FDeterministic := ReadOptionalString(QNames, 'RDB$DETERMINISTIC_FLAG') = '1';
  FSQLSecurity := ReadSQLSecurity(QNames);
  LoadDescription(QNames);
  LoadFields(QReturn, TFIBMetaProcedureOutField);
  LoadFields(QInputs, TFIBMetaProcedureInField);
  FLoaded := True
end;

function TFIBMetaStoredFunction.CommentKeyword: string;
begin
  Result := 'FUNCTION';
end;

function TFIBMetaStoredFunction.CommentTarget: string;
begin
  Result := RoutineName(FPackageName, FormatName);
end;

procedure TFIBMetaStoredFunction.GenerateCommentDDL(Stream: TStringStream);
begin
  inherited GenerateCommentDDL(Stream);
  // The return value has no name and no COMMENT ON
  GenerateChildCommentDDL(Stream, Ord(soProcFieldIn));
end;

procedure TFIBMetaStoredFunction.SaveEmptyDDL(Stream: TStringStream);
begin
  InternalSaveToDDL(Stream, 'CREATE', True);
  // A UDR function has no PSQL dependencies
  if FEngine <> '' then
    WriteBody(Stream)
  else
    Stream.WriteString(sLineBreak + 'AS' + sLineBreak + 'BEGIN' + sLineBreak + 'END');
end;

procedure TFIBMetaStoredFunction.SaveAlterDDL(Stream: TStringStream);
begin
  InternalSaveToDDL(Stream, 'ALTER');
  WriteBody(Stream);
end;

class function TFIBMetaPackageProcedure.ClassIndex: Integer;
begin
  Result := Ord(soPackageProcedures)
end;

class function TFIBMetaPackageProcedure.IsSubObject: Boolean;
begin
  Result := True
end;

procedure TFIBMetaPackageProcedure.GenerateObjectDDL(Stream: TStringStream);
begin
end;

procedure TFIBMetaPackageProcedure.GenerateDDLText(Stream: TStringStream);
begin
end;

class function TFIBMetaPackageFunction.ClassIndex: Integer;
begin
  Result := Ord(soPackageFunctions)
end;

class function TFIBMetaPackageFunction.IsSubObject: Boolean;
begin
  Result := True
end;

procedure TFIBMetaPackageFunction.GenerateObjectDDL(Stream: TStringStream);
begin
end;

procedure TFIBMetaPackageFunction.GenerateDDLText(Stream: TStringStream);
begin
end;

{ TFIBMetaPackage }

constructor TFIBMetaPackage.Create(AOwner: TFIBCustomMetaObject; aName: string = '');
begin
  inherited Create(AOwner, aName);
  AddClass(TFIBMetaPackageProcedure);
  AddClass(TFIBMetaPackageFunction);
  AddClass(TFIBCustomMetaGrant);
  FSQLSecurity := -1;
end;

class function TFIBMetaPackage.ClassIndex: Integer;
begin
  Result := Ord(otPackage)
end;

function TFIBMetaPackage.GetProcedures(const Index: Integer): TFIBMetaPackageProcedure;
begin
  Result := TFIBMetaPackageProcedure(GetChildObject(Ord(soPackageProcedures), Index));
end;

function TFIBMetaPackage.GetProceduresCount: Integer;
begin
  Result := GetChildsCount(Ord(soPackageProcedures));
end;

function TFIBMetaPackage.GetFunctions(const Index: Integer): TFIBMetaPackageFunction;
begin
  Result := TFIBMetaPackageFunction(GetChildObject(Ord(soPackageFunctions), Index));
end;

function TFIBMetaPackage.GetFunctionsCount: Integer;
begin
  Result := GetChildsCount(Ord(soPackageFunctions));
end;

procedure TFIBMetaPackage.GenerateCommentDDL(Stream: TStringStream);
begin
  inherited GenerateCommentDDL(Stream);
  GenerateChildCommentDDL(Stream, Ord(soPackageProcedures));
  GenerateChildCommentDDL(Stream, Ord(soPackageFunctions));
end;

function TFIBMetaPackage.HeaderOptions: string;
begin
  if FSQLSecurity >= 0 then
    Result := ' ' + SQLSecurityClause(FSQLSecurity)
  else
    Result := '';
end;

procedure TFIBMetaPackage.GenerateObjectDDL(Stream: TStringStream);
begin
  Stream.WriteString(Format('CREATE PACKAGE %s%s AS ' + sLineBreak, [FormatName, HeaderOptions]));
  Stream.WriteString(FSpec);
  Stream.WriteString(DefTerminator);
  Stream.WriteString(sLineBreak + sLineBreak);
  Stream.WriteString(Format('RECREATE PACKAGE BODY %s AS ' + sLineBreak, [FormatName]));
  Stream.WriteString(FBody);
end;

procedure TFIBMetaPackage.LoadFromDataBase(QNames, QCharset: TFIBQuery);
var
  DataBase: TFIBMetaDatabase;
  QRoutines, QProcFields, QFuncReturn, QFuncInputs: TFIBQuery;
begin
  Name := QNames.Fields[0].AsString;
  FSpec := QNames.Fields[1].AsString;
  FBody := QNames.Fields[2].AsString;
  FSQLSecurity := ReadSQLSecurity(QNames);
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
      TFIBMetaPackageProcedure.Create(Self).LoadFromDataBase(QRoutines, QProcFields, QCharset,
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
      TFIBMetaPackageFunction.Create(Self).LoadFromDataBase(QRoutines, QFuncReturn, QFuncInputs, QCharset);
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

function TFIBMetaPackage.CommentKeyword: string;
begin
  Result := 'PACKAGE';
end;

procedure TFIBMetaPackage.SaveBodyDDL(Stream: TStringStream);
begin
  Stream.WriteString(Format('RECREATE PACKAGE BODY %s AS ' + sLineBreak, [FormatName]));
  Stream.WriteString(FBody);
end;

function TFIBMetaPackage.UsesColumnTypes: Boolean;
var
  I, J: Integer;
begin
  Result := True;
  for I := 0 to ProceduresCount - 1 do
  begin
    for J := 0 to Procedures[I].InputFieldsCount - 1 do
      if Procedures[I].InputFields[J].FUseRelation then
        Exit;
    for J := 0 to Procedures[I].OutputFieldsCount - 1 do
      if Procedures[I].OutputFields[J].FUseRelation then
        Exit;
  end;
  for I := 0 to FunctionsCount - 1 do
  begin
    for J := 0 to Functions[I].InputFieldsCount - 1 do
      if Functions[I].InputFields[J].FUseRelation then
        Exit;
    if (Functions[I].Return <> nil) and Functions[I].Return.FUseRelation then
      Exit;
  end;
  Result := False;
end;

procedure TFIBMetaPackage.SaveSpecDDL(Stream: TStringStream);
var
  I: Integer;
begin
  Stream.WriteString(Format('CREATE PACKAGE %s%s AS ' + sLineBreak, [FormatName, HeaderOptions]));
  if not UsesColumnTypes then
  begin
    Stream.WriteString(FSpec);
    Exit;
  end;
  // The tables do not exist yet; SaveHeaderAlterDDL writes the header later
  Stream.WriteString('BEGIN');
  for I := 0 to ProceduresCount - 1 do
  begin
    Stream.WriteString(sLineBreak + '  ');
    Procedures[I].InternalSaveToDDL(Stream, '', True);
    Stream.WriteString(DefTerminator);
  end;
  for I := 0 to FunctionsCount - 1 do
  begin
    Stream.WriteString(sLineBreak + '  ');
    Functions[I].InternalSaveToDDL(Stream, '', True);
    Stream.WriteString(DefTerminator);
  end;
  Stream.WriteString(sLineBreak + 'END');
end;

procedure TFIBMetaPackage.SaveHeaderAlterDDL(Stream: TStringStream);
begin
  Stream.WriteString(Format('ALTER PACKAGE %s%s AS ' + sLineBreak, [FormatName, HeaderOptions]));
  Stream.WriteString(FSpec);
end;

end.
