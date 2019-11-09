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
{    Written by Serge Buzadzhy (buzz@devrace.com)               }
{                                                               }
{ ------------------------------------------------------------- }
{    FIBPlus home page: http://www.fibplus.com/                 }
{    FIBPlus support  : http://www.devrace.com/support/         }
{ ------------------------------------------------------------- }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}


unit pFIBDataInfo;

interface

{$I FIBPlus.inc}
uses
  {$IFDEF WINDOWS}
   Windows, // For inline functions
  {$ENDIF}
  SyncObjs,SysUtils,Classes,DB,FIBPlatforms,FIBDataSet,FIBDataBase,FIBQuery,
  pFIBQuery,pFIBDataBase,pFIBProps
  ;


 type
        TExtBoolean= (eFalse,eTrue,eUnknown);

        TpFIBFieldInfo=class
        private
         FIsComputed  :boolean;
         FDefaultValue:Ansistring;
         FCanIncToWhereClause:boolean;
         FDomainName:Ansistring;
         FDefaultValueEmptyString: boolean;
// Info from FIB$FIELDS_INFO
         FWithAdditionalInfo:boolean;
         FDisplayLabel :Ansistring;
         FVisible      :boolean;
         FEditFormat   :Ansistring;
         FDisplayFormat:Ansistring;
         FIsTriggered  :boolean;
         FOtherInfo    :TStrings;
         FDisplayWidth :integer;
         FCanBeBoolean :TExtBoolean;
         FCanBeGUID    :TExtBoolean;
         FCharSet      :integer;
         function  GetCanBeBoolean:boolean;
         function  GetCanBeGUID:boolean;
         function  GetCharSet:string;
        public
         constructor Create;
         destructor  Destroy;override;
         procedure   SaveToStream(Stream:TStream);
         procedure   LoadFromStream(Stream:TStream;FromBegin:boolean);
         property    IsComputed  :boolean read FIsComputed;
         property    DefaultValue:Ansistring  read FDefaultValue;
         property    DomainName  :Ansistring  read FDomainName;
         property    CanIncToWhereClause:boolean read FCanIncToWhereClause;
// Info from FIB$FIELDS_INFO
         property WithAdditionalInfo:boolean read FWithAdditionalInfo;
         property DisplayLabel :Ansistring   read FDisplayLabel;
         property Visible      :boolean  read FVisible;
         property EditFormat   :Ansistring   read FEditFormat;
         property DisplayFormat:Ansistring   read FDisplayFormat;
         property IsTriggered  :boolean  read FIsTriggered;
         property OtherInfo    :TStrings read FOtherInfo;
         property DisplayWidth :integer  read FDisplayWidth;
         property DefaultValueEmptyString:boolean read FDefaultValueEmptyString;
         property CanBeBoolean :boolean  read GetCanBeBoolean;
         property CanBeGuid    :boolean  read GetCanBeGUID;
         property CharSetID    :integer  read FCharSet;
         property CharSet      :string   read GetCharSet;
        end;


        TpFIBTableInfoCollect= class;

        TpFIBTableInfo=class
        private
         FOwner:TpFIBTableInfoCollect;
         FDBName             :Ansistring;
         FTableName          :Ansistring;
         FPrimaryKeyFields   :Ansistring;
         FFieldList          :TStringList;
         FFormatNumber       :integer;
         FFIVersion          :integer;//FIB$FIELDS_INFO
         FWithFieldRepositaryInfo :boolean;
         FStreamVersion      :integer;
         FNonValidated       :boolean;
         FTableID            :integer;
         procedure GetInfoFields(const TableName:string;aTransaction:TFIBTransaction);
         procedure GetRepositaryFieldInfos(const TableName:string;aTransaction:TFIBTransaction);
         procedure ClearFieldList;
         procedure GetAdditionalInfo(FromQuery:TFIBDataset;
          const aFieldName:string;ToFieldInfo:TpFIBFieldInfo );
         procedure   FillInfo(DB:TFIBDataBase;Tr:TFIBTransaction; const ATableName:string);
         function    IsActualInfo(DB:TFIBDatabase) :boolean;
         function    GetPrimaryKeyFields(DB:TFIBDatabase): string;
         function    GetTableId(DB:TFIBDatabase):integer;
         procedure   LoadFromStreamVersion(Stream:TStream;aStreamVersion:integer);
        public
         constructor Create(AOwner:TpFIBTableInfoCollect);
         destructor  Destroy;override;
         procedure   SaveToStream(Stream:TStream);
         procedure   LoadFromStream(Stream:TStream;FromBegin:boolean);

         function    FieldInfo(const FieldName:string):TpFIBFieldInfo;
         property    TableName:Ansistring read FTableName ;
         property    PrimaryKeyFields[DB:TFIBDatabase]:string read GetPrimaryKeyFields;
         property    FieldList :TStringList read FFieldList;
         property    TableID[DB:TFIBDatabase]:integer read GetTableId;
        end;



       TpFIBTableInfoCollect= class(TComponent)
       private
        FDBNames    :TStringList;
        FListTabInfo:TStringList;
        FLock: TCriticalSection;
        FNeedValidate: boolean;
        FLastTransactionId:Integer;
        procedure PrepareInternalTransaction(aDataBase:TFIBDataBase);
       protected
         procedure Notification(AComponent: TComponent; Operation: TOperation); override;
       public
        constructor Create(AOwner:TComponent); override;
        destructor  Destroy;override;

        procedure   SaveToStream(Stream:TStream);
        procedure   LoadFromStream(Stream:TStream;DB:TFIBDatabase=nil);

        procedure   SaveToFile(const FileName:string);
        function    LoadFromFile(const FileName:string;DB:TFIBDatabase=nil):boolean;
        procedure   ValidateSchema(aDataBase:TFIBDataBase;Proc:TpFIBAcceptCacheSchema);

        function    FindTableInfo(const ADBName,ATableName:string):TpFIBTableInfo;
        function    GetTableInfo(aDataBase:TFIBDataBase;const ATableName:string;
              WithRepositaryInfo:boolean
        ):TpFIBTableInfo;
        function
         GetFieldInfo(aDataBase:TFIBDataBase; const ATableName,AFieldName:string;
                      RepositoryInfo:boolean
         ):TpFIBFieldInfo;

        procedure   Clear;
        procedure   ClearForDataBase(aDatabase:TFIBDataBase);
        procedure   ClearForTable(const TableName:string)   ;
        procedure   CommitInternalTransaction ;
        property    NeedValidate :boolean read FNeedValidate write FNeedValidate;
       end;


       TpDataSetInfo= class
       private
         FDBName:Ansistring;
         FVersion:integer;
         FSelectSQL:TStrings;
         FInsertSQL:TStrings;
         FUpdateSQL:TStrings;
         FDeleteSQL:TStrings;
         FRefreshSQL:TStrings;
         FKeyField:Ansistring;
         FGeneratorName:Ansistring;
         FDescription  :Ansistring;
         FUpdateTableName:Ansistring;
         FUpdateOnlyModifiedFields:boolean;
         FConditions   :Ansistring;
         FNonValidated :boolean;

       public
        constructor Create(DataSet:TFIBDataSet); overload;
        constructor Create; overload;
        destructor  Destroy;override;

        procedure   SaveToStream(Stream:TStream);
        procedure   LoadFromStream(Stream:TStream);

       end;

       TpDataSetInfoCollect= class
       private
        FListDataSetInfo:TStringList;
        FLock: TCriticalSection;
        FNeedValidate: boolean;
        function    ActualVersionDSInfo(DataSet:TFIBDataSet):integer;        
       public
        constructor Create;
        destructor  Destroy;override;
        function    FindDataSetInfo(DataSet:TFIBDataSet; var Index:integer):TpDataSetInfo; overload;
        function    FindDataSetInfo(const DBName:string;DS_ID:Integer ; var Index:integer):TpDataSetInfo; overload;
        function    GetDataSetInfo(DataSet:TFIBDataSet):TpDataSetInfo;
        function    LoadDataSetInfo(DataSet:TFIBDataSet):boolean;
        procedure   Clear;
        procedure   ClearDSInfo(DataSet:TFIBDataSet); overload;
        procedure   ClearDSInfo(DS_ID:integer); overload;

        procedure   SaveToStream(Stream:TStream);
        procedure   LoadFromStream(Stream:TStream);

        procedure   SaveToFile(const FileName:string);
        function    LoadFromFile(const FileName:string):boolean;
        property    NeedValidate :boolean read FNeedValidate write FNeedValidate;
       end;

       TpStoredProcCollect= class
       private
        FStoredProcNames:TStringList;
        FSPParamTxt:TStringList;
        FLock: TCriticalSection;
        function  IndexOfSP(DB:TFIBDatabase;const SPName:string;
         ForceReQuery:boolean):integer;
        function  GetParamsText(DB:TFIBDatabase;const SPName:string):string;
       public
        constructor Create;
        destructor  Destroy;override;
        procedure   Clear;
        function    GetExecProcTxt(DB:TFIBDatabase;
         const SPName:string;   ForceReQuery:boolean
        ):string;
        procedure   ClearSPInfo(DB:TFIBDatabase);
       end;

       TpErrorMessage=class
       private
        FErrorMsg :Ansistring;
        FVersion  :integer;
       public
        constructor Create(const aErrorMsg:string; aVersion:integer);
       public
        property ErrorMsg :Ansistring  read  FErrorMsg ;
        property Version  :integer read FVersion;
       end;

       TpErrorMessagesCollect=class
       private
        FDatabases :TStringList;
        FMaxVersion:integer;
        FValidated :boolean;
        FLock: TMultiReadExclusiveWriteSynchronizer;
        function  FindErrorMessage(const DBName,ErrorName:string;
         var BaseIndex,ErrorIndex:integer):boolean;
       public
        constructor Create;
        destructor  Destroy; override;
        procedure   Clear;
       public
        procedure   SaveToStream(Stream:TStream);
        procedure   LoadFromStream(Stream:TStream);
        procedure   SaveToFile(const FileName:string);
        procedure   LoadFromFile(const FileName:string);
       public
        procedure   AddErrorMessage(const DBName,ErrorName,ErrorMsg:string;
         Version:integer);
        function    ErrorMessage(Tr:TFIBTransaction; const ErrorName:string):string;
       end;

var
     ListTableInfo  :TpFIBTableInfoCollect;
     ListDataSetInfo:TpDataSetInfoCollect;
     ListSPInfo     :TpStoredProcCollect;
     ListErrorMessages:TpErrorMessagesCollect;
// Manage Developer Info tables

procedure   CreateFRepositaryTable(DB:TFIBDatabase);
procedure   CreateDRepositaryTable(DB:TFIBDatabase);
procedure   CreateERepositaryTable(DB:TFIBDatabase);

function    ExistFRepositaryTable(DB:TFIBDatabase):boolean;
function    ExistDRepositaryTable(DB:TFIBDatabase):boolean;
function    ExistERepositaryTable(DB:TFIBDatabase):boolean;
function    ExistBooleanDomain(DB:TFIBDatabase):boolean;

function    SaveFIBDataSetInfo(DataSet:TFibDataSet; const Name:string):boolean;

// Routine function

function    GetFieldInfos(Field:TField;RepositaryInfo:boolean):TpFIBFieldInfo;
function    GetOtherFieldInfo(Field:TField;const InfoName:string):string;
procedure   Update1RepositaryTable(Tr:TFIBTransaction);
procedure   Update2RepositaryTable(Tr:TFIBTransaction);


function DBPrimaryKeyFields(const TableName:string;
  aTransaction:TFIBTransaction
 ):string;

implementation

uses pFIBDataSet,StrUtil,FIBConsts,pFIBCacheQueries,ibase,SqlTxtRtns
 {$IFDEF D_XE3}
  {$IFDEF MACOS}
  ,Posix.Unistd // for inline functions
  {$ENDIF}
 {$ENDIF}
;

type
   TFriendDatabase= class(TFIBDatabase);

var
    DatabaseRepositories:TStringList;
    LockRepList: TCriticalSection;

const
  SDefer='@FIB_DEFERRED';

FormatNumbersSQL=
  'select a1.rdb$relation_name,a1.RDB$RELATION_ID VER  from RDB$RELATIONS a1'+CLRF+
  'where a1.RDB$SYSTEM_FLAG = 0'+CLRF+
  'and not  a1.rdb$view_blr is null'+CLRF+
  'union'+CLRF+
  'select R.rdb$relation_name,RDB$FORMAT from RDB$RELATIONS R'+CLRF+
  'where R.RDB$SYSTEM_FLAG = 0'+CLRF+
  'and  R.rdb$view_blr is null   order by 1';

function ExistRepositaryTable(DB:TFIBDatabase;Kind:byte):boolean;
var aTransaction:TFibTransaction;
    qry         :TFIBQuery;
    Index       :integer;
    s           :Ansistring;
    cr          :TExtBoolean;

function RepositaryIsRegistered:TExtBoolean;
begin
 Index:=DatabaseRepositories.IndexOfObject(DB);
 if Index>-1 then
 begin
  case DatabaseRepositories[Index][Kind] of
   '0': Result:=eFalse;
   '1': Result:=eTrue;
  else
    Result:=eUnknown;
  end
 end
 else
   Result:=eUnknown;
end;

begin
 LockRepList.Acquire;
 try
   if csDesigning in DB.ComponentState then
   begin
     Index:=-1;
     DatabaseRepositories.Clear;
     cr    :=eUnknown;
   end
   else
    cr    :=RepositaryIsRegistered;
   Result:=cr =eTrue;
   if cr<>eUnknown then Exit;
   if not (TFIBUseRepository(Kind-1) in DB.UseRepositories) then  Exit;

   if Index<0 then
     s:='222'
   else
     s:=DatabaseRepositories[Index];

   aTransaction:=TFIBTransaction.Create(nil);
   aTransaction.TimeoutAction  :=TACommit;
   aTransaction.DefaultDatabase:=DB;
   qry:=TFIBQuery.Create(nil);
   with qry do
   try
    ParamCheck:=True;
    Database:=DB;  Transaction:=aTransaction;
    SQL.Text:='select COUNT(RDB$RELATION_NAME)'+CLRF+
                      'from RDB$RELATIONS where RDB$FLAGS = 1'+CLRF+
                      'and RDB$RELATION_NAME=?RT';
    aTransaction.StartTransaction;
    case Kind of
      1: Params[0].asString:='FIB$FIELDS_INFO';
      2: Params[0].asString:='FIB$DATASETS_INFO';
      3: Params[0].asString:='FIB$ERROR_MESSAGES';
    end;

    ExecQuery;
    if Fields[0].asInteger>0 then
     s[Kind]:='1'
    else
     s[Kind]:='0';
    Close;

    if Index<0 then
     DatabaseRepositories.AddObject(s,DB)
    else
     DatabaseRepositories[Index]:=s;

    Result:=RepositaryIsRegistered=eTrue;
   finally
    aTransaction.Free;
    Free;
   end;
 finally
    LockRepList.Release;
 end;
end;

function ExistDRepositaryTable(DB:TFIBDatabase):boolean;
begin
 Result:=ExistRepositaryTable(DB,2)
end;

function ExistERepositaryTable(DB:TFIBDatabase):boolean;
begin
 Result:=ExistRepositaryTable(DB,3)
end;

function ExistBooleanDomain(DB:TFIBDatabase):boolean;
var
    Transaction:TFibTransaction;
    qry:TFIBQuery;
begin
 qry:=TFIBQuery.Create(nil);
 Transaction:=TFIBTransaction.Create(nil);
 try
  Transaction.DefaultDatabase:=DB;
  qry.Transaction:=Transaction;
  with qry,qry.SQL do
  begin
   ParamCheck:=False;
   Database:=DB;
   ParamCheck:=False;
   Transaction.StartTransaction;
   Text:=
       'Select Count(*) FROM RDB$FIELDS FLD'+CLRF +
       'WHERE FLD.RDB$FIELD_NAME = ''FIB$BOOLEAN''' ;
   ExecQuery;
   Result:=qry.Fields[0].asInteger<>0;
  end
 finally
  Transaction.Free;
  qry.Free;
 end;
end;

function ExistFRepositaryTable(DB:TFIBDatabase):boolean;
begin
 Result:=ExistRepositaryTable(DB,1)
end;

procedure   Update1RepositaryTable(Tr:TFIBTransaction);
var qry:TFIBQuery;
begin
 qry:=TFIBQuery.Create(nil);
 with qry,qry.SQL do
 try
  Database:=Tr.DefaultDatabase;  Transaction:=Tr;
  ParamCheck:=False;
  if not Tr.InTransaction then Tr.StartTransaction;
  try
   Text:='CREATE GENERATOR FIB$FIELD_INFO_VERSION';
   ExecQuery;
  except
  end;
  try
   Text:='ALTER TABLE FIB$FIELDS_INFO ADD DISPLAY_WIDTH INTEGER DEFAULT 0';
   ExecQuery;
  except
  end;
  try
   Text:='ALTER TABLE FIB$FIELDS_INFO ADD FIB$VERSION INTEGER';
   ExecQuery;
  except
  end;

  try
   Text:=
   'CREATE TRIGGER FIB$FIELDS_INFO_BI FOR FIB$FIELDS_INFO '+
   'ACTIVE BEFORE INSERT POSITION 0 as '+CLRF+
   'begin '+#13#10+
     'new.fib$version=gen_id(fib$field_info_version,1);'+CLRF+
   'end';
   ExecQuery;
  except
  end;
  try
   Text:=
   'CREATE TRIGGER FIB$FIELDS_INFO_BU FOR FIB$FIELDS_INFO '+
   'ACTIVE BEFORE UPDATE POSITION 0 as '+CLRF+
   'begin '+CLRF+
     'new.fib$version=gen_id(fib$field_info_version,1);'+CLRF+
   'end';
   ExecQuery;
  except
  end;
 finally
  Tr.CommitRetaining;
  Free
 end;
end;

procedure   Update2RepositaryTable(Tr:TFIBTransaction);
var qry:TFIBQuery;
begin
 qry:=TFIBQuery.Create(nil);
 with qry,qry.SQL do
 try
  Database:=Tr.DefaultDatabase;  Transaction:=Tr;
  ParamCheck:=False;
  if not ExistBooleanDomain(Transaction.DefaultDatabase) then
  begin
   Text:=
   'CREATE DOMAIN FIB$BOOLEAN AS SMALLINT DEFAULT 1 NOT NULL CHECK (VALUE IN (0,1))';
   ExecQuery;
  end;
  try
   Text:='ALTER TABLE FIB$DATASETS_INFO ADD UPDATE_TABLE_NAME  VARCHAR(68)';
   ExecQuery;
  except
  end;
  try
   Text:='ALTER TABLE FIB$DATASETS_INFO ADD UPDATE_ONLY_MODIFIED_FIELDS  FIB$BOOLEAN NOT NULL';
   ExecQuery;
  except
  end;
  try
   Text:='ALTER TABLE FIB$DATASETS_INFO ADD CONDITIONS  BLOB sub_type 1 segment size 80';
   ExecQuery;
  except
  end;

  if not Tr.InTransaction then Tr.StartTransaction;
  try
   Text:='CREATE GENERATOR FIB$FIELD_INFO_VERSION';
   ExecQuery;
  except
  end;

  try
   Text:='ALTER TABLE FIB$DATASETS_INFO ADD fib$version  INTEGER';
   ExecQuery;
   Text:=
   'CREATE TRIGGER FIB$DATASETS_INFO_BI FOR FIB$DATASETS_INFO '+
   'ACTIVE BEFORE INSERT POSITION 0 as '+CLRF +
   'begin'+CLRF+
     'new.fib$version=gen_id(fib$field_info_version,1);'+CLRF+
   'end';
   ExecQuery;

   Text:=
   'CREATE TRIGGER FIB$DATASETS_INFO_BU FOR FIB$DATASETS_INFO '+
   'ACTIVE BEFORE UPDATE POSITION 0 as '+CLRF+
   'begin'+CLRF+
     'new.fib$version=gen_id(fib$field_info_version,1);'+CLRF+
   'end';
   ExecQuery;
   
  except
  end;

 finally
   Tr.CommitRetaining;
   qry.Free
 end
end;

procedure   DoCreateRepositaryTable(DB:TFIBDatabase;Kind:byte);
var Index:integer;
    Transaction:TFibTransaction;
    qry:TFIBQuery;
begin
 qry:=TFIBQuery.Create(nil);
 Transaction:=TFibTransaction.Create(nil);
 try
  Transaction.DefaultDatabase:=DB;
  qry.Database:=DB;  qry.Transaction:=Transaction;
  qry.ParamCheck:=False;
  Transaction.StartTransaction;
  with qry,qry.SQL do
  case Kind of
  1: begin
      if not ExistBooleanDomain(DB) then
      begin
       Text:=
       'CREATE DOMAIN FIB$BOOLEAN AS SMALLINT DEFAULT 1 NOT NULL CHECK (VALUE IN (0,1))';
       ExecQuery;
      end;
      Text:=
       'CREATE TABLE FIB$FIELDS_INFO (TABLE_NAME VARCHAR(31) NOT NULL,'+CLRF+
       'FIELD_NAME VARCHAR(31) NOT NULL,'+CLRF+
       'DISPLAY_LABEL VARCHAR(25),'+CLRF+
       'VISIBLE FIB$BOOLEAN DEFAULT 1 NOT NULL,'+CLRF+
       'DISPLAY_FORMAT VARCHAR(15),'+CLRF+
       'EDIT_FORMAT VARCHAR(15),'+CLRF+
       'TRIGGERED FIB$BOOLEAN DEFAULT 0 NOT NULL,'+CLRF+
       'CONSTRAINT PK_FIB$FIELDS_INFO PRIMARY KEY (TABLE_NAME, FIELD_NAME))';
      ExecQuery;
      Text:='GRANT SELECT ON TABLE FIB$FIELDS_INFO TO PUBLIC';
      ExecQuery;
      Update1RepositaryTable(Transaction);      
     end;
   2:
    begin
      Text:=
       'CREATE TABLE FIB$DATASETS_INFO (DS_ID INTEGER NOT NULL,'+CLRF+
       'DESCRIPTION VARCHAR(40),'+
       'SELECT_SQL BLOB sub_type 1 segment size 80,'+CLRF+
       'UPDATE_SQL BLOB sub_type 1 segment size 80,'+CLRF+
       'INSERT_SQL BLOB sub_type 1 segment size 80,'+CLRF+
       'DELETE_SQL BLOB sub_type 1 segment size 80,'+CLRF+
       'REFRESH_SQL BLOB sub_type 1 segment size 80,'+CLRF+
       'NAME_GENERATOR VARCHAR(68), '+
       'KEY_FIELD VARCHAR(68),'+
       'CONSTRAINT PK_FIB$DATASETS_INFO PRIMARY KEY (DS_ID))';
      ExecQuery;
      Text:=
       'GRANT SELECT ON TABLE FIB$DATASETS_INFO TO PUBLIC';
      ExecQuery;
      Update2RepositaryTable(Transaction);
    end;
   3:
    begin
      Text:=
      'CREATE TABLE FIB$ERROR_MESSAGES ('+
      'CONSTRAINT_NAME  VARCHAR(67) NOT NULL,'+
      'MESSAGE_STRING   VARCHAR(100),'+
      'FIB$VERSION      INTEGER,'+
      'CONSTR_TYPE      VARCHAR(11) DEFAULT ''UNIQUE'' NOT NULL,'+
      'CONSTRAINT PK_FIB$ERROR_MESSAGES PRIMARY KEY (CONSTRAINT_NAME))'
      ;

      ExecQuery;
      Text:=
       'GRANT SELECT ON TABLE FIB$ERROR_MESSAGES TO PUBLIC';
      ExecQuery;

      try
       Text:='CREATE GENERATOR FIB$FIELD_INFO_VERSION';
       ExecQuery;
      except
      end;
      Text:=
       'CREATE TRIGGER BI_FIB$ERROR_MESSAGES FOR FIB$ERROR_MESSAGES '+
       'ACTIVE BEFORE INSERT POSITION 0 AS '+CLRF+
       'begin '+CLRF+'new.fib$version=gen_id(fib$field_info_version,1);'+CLRF+' end';
      ExecQuery;

      Text:=
       'CREATE TRIGGER BU_FIB$ERROR_MESSAGES FOR FIB$ERROR_MESSAGES '+
       'ACTIVE BEFORE UPDATE POSITION 0 AS '+CLRF+
       'begin '+CLRF+'new.fib$version=gen_id(fib$field_info_version,1);'+CLRF+' end';
      ExecQuery;
    end;
  end;
  Transaction.Commit;
 finally
  Transaction.Free;
  qry.Free;
 end;
 with DatabaseRepositories do
 begin
  Index:=IndexOfObject(DB);
  if Index=-1 then
   AddObject(FastCopy('222',1,Kind-1)+'1'+FastCopy('222',1,Kind+1),DB)
  else
   DatabaseRepositories[Index]:=
     FastCopy(DatabaseRepositories[Index],1,Kind-1)+'1'+FastCopy(DatabaseRepositories[Index],1,Kind+1);
 end;
end;

procedure   CreateDRepositaryTable(DB:TFIBDatabase);
begin
 DoCreateRepositaryTable(DB,2)
end;

procedure   CreateFRepositaryTable(DB:TFIBDatabase);
begin
 DoCreateRepositaryTable(DB,1)
end;

procedure   CreateERepositaryTable(DB:TFIBDatabase);
begin
 DoCreateRepositaryTable(DB,3)
end;

function   ExchangeDataSetInfo(DataSet:TFibDataSet;DS_Info:TpDataSetInfo;aDescription:string=''):boolean;
var
    vTransaction:TFibTransaction;
    DI:TpFIBDataset;
    vDescription:string;
    tf1:TFIBXSQLVAR;
    q:TFIBQuery;

begin
 Result:=True;
 if DataSet is TpFIBDataSet then
 with TpFIBDataSet (DataSet) do
 begin
   if DataSet_ID= 0 then
    raise Exception.Create(Name + SCompEditDataSet_ID);
   if DataBase=nil then  raise Exception.Create(SDataBaseNotAssigned);
   if not (urDataSetInfo in DataSet.Database.UseRepositories) then
     raise Exception.Create(SCompEditDataSetInfoForbid);
   if not ExistDRepositaryTable(DataSet.Database) then
     raise Exception.Create(SCompEditDataSetInfoNotExists);

   DI:=TpFIBDataset.Create(nil);
   vTransaction:=TFibTransaction.Create(nil);
   vTransaction.DefaultDatabase:=DataSet.DataBase;
   q:=GetQueryForUse(vTransaction,'SELECT * FROM FIB$DATASETS_INFO WHERE DS_ID=:DS_ID');
   try
    vTransaction.StartTransaction;
    if DS_Info<>nil then
    begin
     q.Params[0].asInteger:=DataSet_ID;
     q.ExecQuery;
     if q.RecordCount=0 then
      Exit;
     with DS_Info,q do
     begin
      FSelectSQL.Text :=FieldByName('SELECT_SQL').asString;
      FUpdateSQL.Text :=FieldByName('UPDATE_SQL').asString;
      FInsertSQL.Text :=FieldByName('INSERT_SQL').asString;
      FDeleteSQL.Text :=FieldByName('DELETE_SQL').asString;
      FRefreshSQL.Text:=FieldByName('REFRESH_SQL').asString;
      FKeyField       :=FieldByName('KEY_FIELD').asString;
      FGeneratorName  :=FieldByName('NAME_GENERATOR').asString;
      FDescription    :=FieldByName('DESCRIPTION')   .asString;
      tf1:=FindField('FIB$VERSION');
      if Assigned(tf1) then
       FVersion:=FieldByName('FIB$VERSION').asInteger;
      tf1:=FindField('UPDATE_TABLE_NAME');
      if Assigned(tf1) then
        FUpdateTableName:=tf1.AsString;
      tf1:=FindField('UPDATE_ONLY_MODIFIED_FIELDS');
      if Assigned(tf1) then
        FUpdateOnlyModifiedFields:=tf1.AsInteger=1;
      tf1:=FindField('CONDITIONS');
      if Assigned(tf1) then
      begin
        FConditions:=tf1.AsString;
      end;
      q.Close;
     end;
    end
    else
    begin
//For design only    
      DI.Database:=DataSet.DataBase;
      DI.Transaction:=vTransaction;
      DI.UpdateTransaction:=vTransaction;
      DI.SelectSQL.Text:=
       'SELECT * FROM FIB$DATASETS_INFO WHERE DS_ID='+IntToStr(DataSet_ID);

     DI.InsertSQL.Text:=
      'INSERT INTO FIB$DATASETS_INFO (DS_ID,UPDATE_ONLY_MODIFIED_FIELDS) VALUES('
      +IntToStr(DataSet_ID)+',1)';
     DI.UpdateSQL.Text:=
      'UPDATE FIB$DATASETS_INFO SET SELECT_SQL=?SELECT_SQL,'+
     'DESCRIPTION=?DESCRIPTION,'+
     'UPDATE_SQL=?UPDATE_SQL,'+
     'INSERT_SQL=?INSERT_SQL,'+
     'DELETE_SQL=?DELETE_SQL,'+
     'REFRESH_SQL=?REFRESH_SQL,'+
     'NAME_GENERATOR=?NAME_GENERATOR,'+
     'KEY_FIELD=?KEY_FIELD, '+
     'UPDATE_TABLE_NAME=?UPDATE_TABLE_NAME, '+
     'UPDATE_ONLY_MODIFIED_FIELDS=?UPDATE_ONLY_MODIFIED_FIELDS, '+
     'CONDITIONS=?CONDITIONS '+
     'WHERE DS_ID='+IntToStr(DataSet_ID)
     ;
     try
      DI.QUpdate.Prepare;
     except
      Update2RepositaryTable(vTransaction);
      vTransaction.Commit;
      vTransaction.StartTransaction
     end;
     DI.Open;
     if DI.RecordCount=0  then
     begin
       DI.QInsert.ExecQuery;
       DI.Close;DI.Open;
       if DI.RecordCount=0  then
        raise Exception.Create(SCompEditUnableInsertInfoRecord);
     end;
      if Length(aDescription)= 0 then
       vDescription:=DI.FieldByName('DESCRIPTION')   .asString
      else
       vDescription:=aDescription;
       

{      Result:=False;

      if not InputQuery(SCompEditSaveDataSetProperty, SCompEditDataSetDesc, vDescription
      ) then Exit;}
      DI.Edit;
      DI.FieldByName('SELECT_SQL') .asString :=DataSet.SelectSQL.Text;
      DI.FieldByName('INSERT_SQL') .asString :=DataSet.InsertSQL.Text;
      DI.FieldByName('DELETE_SQL') .asString :=DataSet.DeleteSQL.Text;
      DI.FieldByName('UPDATE_SQL') .asString :=DataSet.UpdateSQL.Text;
      DI.FieldByName('REFRESH_SQL').asString :=DataSet.RefreshSQL.Text;
      DI.FieldByName('KEY_FIELD')  .asString :=AutoUpdateOptions.KeyFields;
      DI.FieldByName('NAME_GENERATOR').asString  :=AutoUpdateOptions.GeneratorName;
      DI.FieldByName('DESCRIPTION')   .asString  :=vDescription;
      DI.FieldByName('UPDATE_TABLE_NAME').asString  :=AutoUpdateOptions.UpdateTableName;
      DI.FieldByName('UPDATE_ONLY_MODIFIED_FIELDS').asInteger:=
        Ord(AutoUpdateOptions.UpdateOnlyModifiedFields);
      DI.FieldByName('CONDITIONS').asString  :=Conditions.ExchangeString;
      DI.Post;
    end;
    vTransaction.Commit;
    Result:=True;
   finally
    FreeQueryForUse(q);
    vTransaction.Free;
    DI.Free;
   end;
 end;
end;

function   SaveFIBDataSetInfo(DataSet:TFibDataSet;const Name:string):boolean;
begin
 Result:=ExchangeDataSetInfo(DataSet,nil,Name);
end;



function DoGetTableId(const TableName:string;  aTransaction:TFIBTransaction):integer;
var
   q:TFIBQuery;
const
 STabId =   'select RDB$RELATION_ID from RDB$RELATIONS '+
 'where RDB$RELATION_NAME=?TN';

begin
  if (aTransaction=nil) or (aTransaction.DefaultDatabase=nil) then
  begin
   Result:=-1;
   Exit;
  end;
  q:=GetQueryForUse(aTransaction,STabId);
  with q do
  try
   Params[0].AsString:=TableName;
   if not Transaction.InTransaction then
    Transaction.StartTransaction;
   ExecQuery;
   if Eof then
     Result:=-1
   else
     Result:=Fields[0].asInteger
  finally
    FreeQueryForUse(q);
  end
end;

function DBPrimaryKeyFields(const TableName:string;
  aTransaction:TFIBTransaction
 ):string;
var
   q:TFIBQuery;
const
  SGetPrimary=   'select i.rdb$field_name'+CLRF+
   'from    rdb$relation_constraints r, rdb$index_segments i'+CLRF+
   'where   r.rdb$relation_name=:TN and'+CLRF+
   'r.rdb$constraint_type=''PRIMARY KEY'' and'+CLRF+
   'r.rdb$index_name=i.rdb$index_name'+CLRF +
   'order by i.rdb$field_position';

begin
  if Length(TableName) = 0 then
  begin
    result := '';
    exit;
  end;
  if (aTransaction=nil) or (aTransaction.DefaultDatabase=nil) then
  begin
   Result:=SDefer;
   Exit;
  end;
  q:=GetQueryForUse(aTransaction,SGetPrimary);
  Result:='';
  with q do
  try
   q.Options:=[qoStartTransaction];
   if TableName[1]='"' then
    ParamByName('TN').AsString:=Copy(TableName,2,Length(TableName)-2)
   else
    ParamByName('TN').AsString:=TableName;
   ExecQuery;
   Result:=FastTrim(Fields[0].asString); Next;
   while not Eof do
   begin
    Result:=Result+';'+FastTrim(Fields[0].asString);
    Next
   end;
  finally
    FreeQueryForUse(q);
  end
end;

//StreamRtn
procedure WriteStrToStream(const s:Ansistring;Stream: TStream);
var
  L:integer;
begin
   L:=Length(s);
   with Stream do
   begin
    WriteBuffer(L,SizeOf(Integer));
    if L>0 then
     WriteBuffer(s[1],L);
   end;
end;


procedure ReadStrFromStream(const Stream: TStream;var ResStr:Ansistring);
var
  L:integer;
begin
   with Stream do
   begin
    ReadBuffer(L,SizeOf(Integer));
    SetLength(ResStr,L);
    if L>0 then
     ReadBuffer(ResStr[1],L);
   end;
end;

constructor TpFIBFieldInfo.Create;
begin
  inherited Create;
  FWithAdditionalInfo:=False;
  FIsTriggered       :=False;
  FOtherInfo         :=TStringList.Create;
  FDefaultValueEmptyString := False;
  FDisplayWidth      :=0;
  FCanBeBoolean      :=eUnknown;
  FCanBeGUID         :=eUnknown;
end;

destructor  TpFIBFieldInfo.Destroy;
begin
 FOtherInfo.Free;
 inherited Destroy;
end;

function  TpFIBFieldInfo.GetCanBeBoolean:boolean;
begin
  case FCanBeBoolean  of
   eTrue    : Result:=True ;
   eFalse   : Result:=False;
  else
   Result:=PosCI('BOOLEAN',DomainName)>0;
   FCanBeBoolean :=TExtBoolean(Result);
  end;
end;

function  TpFIBFieldInfo.GetCanBeGUID:boolean;
begin
  case FCanBeGuid  of
   eTrue    : Result:=True ;
   eFalse   : Result:=False;
  else
   Result:=PosCI('GUID',DomainName)>0;
   FCanBeGuid :=TExtBoolean(Result);
  end;
end;

function  TpFIBFieldInfo.GetCharSet:string;
begin
 if (FCharSet<0) or (FCharSet>IBStdCharSetsCount-1) then
  Result:=UnknownStr
 else
  Result:=IBStdCharacterSets[FCharSet]
end;

procedure TpFIBFieldInfo.SaveToStream(Stream:TStream);
begin
  with Stream do
  begin
   WriteBuffer(FIsComputed,SizeOf(boolean));
   WriteBuffer(FCanIncToWhereClause,SizeOf(boolean));
   WriteBuffer(FDefaultValueEmptyString,SizeOf(boolean));
   WriteBuffer(FWithAdditionalInfo,SizeOf(boolean));
   WriteBuffer(FVisible,SizeOf(boolean));
   WriteBuffer(FIsTriggered,SizeOf(boolean));
   WriteBuffer(FDisplayWidth,SizeOf(integer));
   WriteBuffer(FCharSet,SizeOf(integer));
   WriteStrToStream(FDefaultValue,Stream);
   WriteStrToStream(FDomainName,Stream);
   WriteStrToStream(FDisplayLabel,Stream);
   WriteStrToStream(FEditFormat,Stream);
   WriteStrToStream(FDisplayFormat,Stream);
   WriteStrToStream(FOtherInfo.Text,Stream);
  end;
end;

procedure TpFIBFieldInfo.LoadFromStream(Stream:TStream;FromBegin:boolean);
var 
   st:Ansistring ;
procedure RaizeErrStream;
begin
 raise Exception.Create(SCompEditFieldInfoLoadError);
end;

begin
  with Stream do
  begin
   if FromBegin then Seek(0,soFromBeginning);
   ReadBuffer(FIsComputed,SizeOf(boolean));
   ReadBuffer(FCanIncToWhereClause,SizeOf(boolean));
   ReadBuffer(FDefaultValueEmptyString,SizeOf(boolean));
   ReadBuffer(FWithAdditionalInfo,SizeOf(boolean));
   ReadBuffer(FVisible,SizeOf(boolean));
   ReadBuffer(FIsTriggered,SizeOf(boolean));
   ReadBuffer(FDisplayWidth,SizeOf(integer));
   ReadBuffer(FCharSet,SizeOf(integer));

   ReadStrFromStream(Stream,FDefaultValue);
   ReadStrFromStream(Stream,FDomainName);
   ReadStrFromStream(Stream,FDisplayLabel);
   ReadStrFromStream(Stream,FEditFormat);
   ReadStrFromStream(Stream,FDisplayFormat);
   ReadStrFromStream(Stream,st);
   FOtherInfo.Text:=st;
  end
end;

// TpFIBTableInfo
constructor TpFIBTableInfo.Create(AOwner:TpFIBTableInfoCollect);
begin
 inherited Create;
 FOwner:=AOwner;
 FFieldList:=TStringList.Create;
 FTableID            :=-1;
end;

procedure   TpFIBTableInfo.FillInfo(DB:TFIBDataBase;Tr:TFIBTransaction; const ATableName:string);

var
   vDatabase:TFIBDatabase;
   vForceTransaction:boolean;
   vTr:TFIBTransaction;
begin
 inherited Create;
 FTableName:=ATableName;
 FPrimaryKeyFields:=SDefer;
 vDatabase:=DB;
 FDBName   :=vDatabase.DBName;
 vTr:=vDatabase.FirstActiveTransaction;
 vForceTransaction:=vTr=nil;
 if vForceTransaction then
 begin
   if Length(FTableName)>0 then
    GetInfoFields(FTableName,Tr);
 end
 else
 begin
   if Length(FTableName)>0 then
    GetInfoFields(FTableName,vTr);
 end;

end;



destructor TpFIBTableInfo.Destroy;//override;
begin
 ClearFieldList;
 FFieldList.Free;
 inherited Destroy;
end;

procedure   TpFIBTableInfo.SaveToStream(Stream:TStream);
var i,L:integer;
begin
  with Stream do
  begin
   WriteStrToStream(FDBName,Stream);
   WriteStrToStream(FTableName,Stream);
   WriteBuffer(FWithFieldRepositaryInfo,SizeOf(boolean));
   WriteBuffer(FFormatNumber,SizeOf(Integer)); // metadate counter
   WriteBuffer(FFIVersion   ,SizeOf(Integer)); // counter for FIB$FIELD_INFO
   WriteStrToStream(FPrimaryKeyFields,Stream);
   L:=FFieldList.Count;
   WriteBuffer(L,SizeOf(Integer));
   for i := 0  to Pred(FFieldList.Count) do
   begin
    WriteStrToStream(FFieldList[i],Stream);
    TpFIBFieldInfo(FFieldList.Objects[i]).SaveToStream(Stream)
   end;
  end;
end;

procedure   TpFIBTableInfo.LoadFromStreamVersion(Stream:TStream;aStreamVersion:integer);
begin
  FStreamVersion:=aStreamVersion;
  LoadFromStream(Stream,False)
end;

procedure   TpFIBTableInfo.LoadFromStream(Stream:TStream;FromBegin:boolean);
var i,fc,L:integer;
    fn:Ansistring;
    fi:TpFIBFieldInfo;

{
procedure RaizeErrStream;
begin
 raise Exception.Create(SCompEditFieldInfoLoadError);
end;
}
begin
  with Stream do
  begin
   if FromBegin then Seek(0,soFromBeginning);

   ReadBuffer(L,SizeOf(Integer));
   SetLength(FDBName,L);
   ReadBuffer(Pointer(FDBName)^,L);

   ReadBuffer(L,SizeOf(Integer));
   SetLength(FTableName,L);
   ReadBuffer(Pointer(FTableName)^,L);
   ReadBuffer(FWithFieldRepositaryInfo,SizeOf(boolean));

   ReadBuffer(FFormatNumber,SizeOf(Integer));
   ReadBuffer(FFIVersion   ,SizeOf(Integer)); // Counter for FIB$FIELD_INFO

   ReadBuffer(L,SizeOf(Integer));
   SetLength(FPrimaryKeyFields,L);
   ReadBuffer(FPrimaryKeyFields[1],L);
   ReadBuffer(fc,SizeOf(Integer));

   ClearFieldList;
   for i:=0 to Pred(fc) do
   begin
    ReadBuffer(L,SizeOf(Integer));
    SetLength(fn,L);
    ReadBuffer(fn[1],L);
    fi:=TpFIBFieldInfo.Create;
    fi.LoadFromStream(Stream,False);
    FFieldList.AddObject(fn,fi);
   end;
  end;
  FNonValidated:=True
end;

function TpFIBTableInfo.GetPrimaryKeyFields(DB:TFIBDatabase): string;
var
  vTransaction:TFIBTransaction;
begin
  vTransaction:=TFriendDatabase(DB).GetInternalTransaction;
  if FPrimaryKeyFields=SDefer then
  begin
   FPrimaryKeyFields:=DBPrimaryKeyFields(FTableName,vTransaction);
  end;
  Result:=FPrimaryKeyFields ;
end;

function TpFIBTableInfo.GetTableId(DB:TFIBDatabase):integer;
var
  vTransaction:TFIBTransaction;
begin
  vTransaction:=TFriendDatabase(DB).GetInternalTransaction;
  if FTableID=-1 then // deffer
  begin
   FTableID:=DoGetTableId(FTableName,vTransaction);
  end;
  Result:=FTableID;
end;

function TpFIBTableInfo.FieldInfo(const FieldName:string):TpFIBFieldInfo;
var Index:integer;
begin
 Result:=nil;
 Index:=FFieldList.IndexOf(FastTrim(ReplaceStr(FieldName,'"','')));
 if Index>-1 then Result:=TpFIBFieldInfo(FFieldList.Objects[Index]);
end;

procedure TpFIBTableInfo.ClearFieldList;
var i:integer;
begin
 for i:=Pred(FFieldList.Count) downto 0 do
  FFieldList.Objects[i].Free;
 FFieldList.Clear;
end;

procedure TpFIBTableInfo.GetAdditionalInfo(FromQuery:TFIBDataset;
          const aFieldName:string;ToFieldInfo:TpFIBFieldInfo);
var i:integer;
begin
 try
  with FromQuery,ToFieldInfo do       //
    if (FN('FIELD_NAME').asString=aFieldName) or
     Locate('FIELD_NAME',TrimRight(aFieldName),[]) then
    begin
     FWithAdditionalInfo:=True;
     for i:=0 to Pred(FieldCount) do
     with Fields[i] do
     begin
      if StringInArray(FieldName,['TABLE_NAME','FIELD_NAME','FIB$VERSION']) then
       Continue
      else
      case FieldName[1] of
       'D':
         case Length(FieldName) of
          13:if FieldName='DISPLAY_LABEL'then
              FDisplayLabel:=asString
             else
             if FieldName='DISPLAY_WIDTH' then
              FDisplayWidth:=asInteger
             else
              FOtherInfo.Values[FieldName]:=asString;
          14:if FieldName='DISPLAY_FORMAT' then
              FDisplayFormat:=asString
             else
              FOtherInfo.Values[FieldName]:=asString;
         else
           FOtherInfo.Values[FieldName]:=asString;
         end;
      'E':if FieldName='EDIT_FORMAT' then
           FEditFormat  :=asString
          else
           FOtherInfo.Values[FieldName]:=asString;
      'V':if FieldName='VISIBLE' then
           FVisible     :=asInteger=1
          else
           FOtherInfo.Values[FieldName]:=asString;
      'T':if FieldName='TRIGGERED' then
           FIsTriggered :=asInteger=1
          else
           FOtherInfo.Values[FieldName]:=asString;
      else
       FOtherInfo.Values[FieldName]:=asString;
      end
     end;
    end
 except
 end
end;

const FormatNumberSQL=
  'select a1.RDB$RELATION_ID VER  from RDB$RELATIONS a1'+CLRF+
  'where a1.RDB$SYSTEM_FLAG = 0  and a1.rdb$relation_name=?TN'+CLRF+
  'and not  a1.rdb$view_blr is null'+CLRF+
  'union'+CLRF+
  'select RDB$FORMAT from RDB$RELATIONS R'+CLRF+
  'where R.RDB$SYSTEM_FLAG = 0    and R.rdb$relation_name=?TN'+CLRF+
  'and  R.rdb$view_blr is null';

FI_VersionSQL =
 'Select Max(fib$version) From FIB$FIELDS_INFO Where table_name=?TN';
FI_VersionsSQL=
 'Select table_name,Max(fib$version) From FIB$FIELDS_INFO group by table_name order by 1';


function  TpFIBTableInfo.IsActualInfo(DB:TFIBDatabase) :boolean;
var
 q:TFIBQuery;
 vTransaction:TFIBTransaction;
 vForceTransaction:boolean;
begin
    vTransaction:=TFriendDatabase(DB).GetInternalTransaction;
    if DB.DBName<>FDBName then
    begin
     Result:=False;
     Exit; 
    end
    else
     Result:=True;
    vForceTransaction:=DB.ActiveTransactionCount=0;
    if not vForceTransaction then
     vTransaction:=DB.FirstActiveTransaction;

    if  (FTableName<>'ALIAS') then
    begin
      q:=GetQueryForUse(vTransaction,  FormatNumberSQL  );
      with q do
      try
       Options:=[qoStartTransaction];
       Params[0].asString:=TableName;
       ExecQuery;
       Result:=FFormatNumber=q.Fields[0].asInteger;
      finally
        Close;
        FreeQueryForUse(q);
      end;
    end;
    if Result  and FWithFieldRepositaryInfo and ExistFRepositaryTable(DB) then
    begin
      q:=GetQueryForUse(vTransaction,  FI_VersionSQL );
      with q do
      try
       Options:=[qoStartTransaction];
       Params[0].asString:=TableName;
       try
        ExecQuery;
       except
        Result:=True;
        Update1RepositaryTable(vTransaction);
        Exit;
       end;
       Result:=FFIVersion=q.Fields[0].asInteger;
      finally
        Close;
        FreeQueryForUse(q);
      end;
    end;
   FNonValidated:=not Result;
end;

procedure TpFIBTableInfo.GetRepositaryFieldInfos(const TableName:string;
 aTransaction:TFIBTransaction);
var q:TFIBQuery;
    fi:TpFIBFieldInfo;
    ExistAdInfo:boolean;
    d:TpFIBDataSet;
    i:integer;
begin
  d:=nil;
  ExistAdInfo:=ExistFRepositaryTable(aTransaction.DefaultDatabase);
  if ExistAdInfo then
  try
     q:=GetQueryForUse(aTransaction,  FI_VersionSQL );
     with q do
     try
     //GetVersion
      Options:=[qoStartTransaction];
      Params[0].asString:=TableName;
      try
       q.ExecQuery;
       FFIVersion:=q.Fields[0].asInteger;
      except
       Update1RepositaryTable(aTransaction);
       FFIVersion:=0;
      end;
     finally
       Close;
       FreeQueryForUse(q);
     end;

    d               :=TpFIBDataSet.Create(nil);
    d.PrepareOptions:=[];
    d.DataBase      :=aTransaction.DefaultDatabase;
    d.Transaction   :=aTransaction;
    d.SelectSQL.Text:='Select * from FIB$FIELDS_INFO where TABLE_NAME='''+
                    TableName+''' ORDER BY TABLE_NAME,FIELD_NAME';
    d.PrepareOptions:=[];
    d.Open;
  except
   d.Free;
   d:=nil;
   ExistAdInfo:=False;
  end;
  if not ExistAdInfo then
   Exit;


  if TableName='ALIAS' then
  begin
   ClearFieldList;
   with d do
   try
    while not eof do
    begin
     fi:=TpFIBFieldInfo.Create;
     GetAdditionalInfo(d,FastTrim(Fields[1].asString),fi);
     FFieldList.AddObject(FastTrim(Fields[1].asString),fi);
     Next
    end;
   finally
     Free;
   end
  end
  else
  try
   for i:=0 to Pred(FFieldList.Count) do
   begin
    fi:=TpFIBFieldInfo(FFieldList.Objects[i]);
    GetAdditionalInfo(d,FFieldList[i],fi);
   end;
  finally
   d.Free
  end;
end;


procedure TpFIBTableInfo.GetInfoFields(const TableName:string;
  aTransaction:TFIBTransaction
);
var
    q:TFIBQuery;
    fi:TpFIBFieldInfo;
    ExistAdInfo:boolean;
    d:TpFIBDataSet;
    p:integer;
    vQuoteExist:boolean;
begin
  if Length(TableName)=0 then Exit;
  d:=nil;
  ExistAdInfo:=FWithFieldRepositaryInfo and
   ExistFRepositaryTable(aTransaction.DefaultDatabase);
  if ExistAdInfo then
  try
     q:=GetQueryForUse(aTransaction,  FI_VersionSQL );
     with q do
     try
      Options:=[qoStartTransaction];
      Params[0].asString:=TableName;
      try
       q.ExecQuery;
       FFIVersion:=q.Fields[0].asInteger;
      except
       Update1RepositaryTable(aTransaction);
       FFIVersion:=0;
      end;
     finally
       Close;
       FreeQueryForUse(q);
     end;


    d            :=TpFIBDataSet.Create(nil);
    d.PrepareOptions:=[];
    d.DataBase   :=aTransaction.DefaultDatabase;
    d.Transaction:=aTransaction;
    d.SelectSQL.Text:='Select * from FIB$FIELDS_INFO where TABLE_NAME='''+
                    TableName+''' ORDER BY FIELD_NAME';
    d.PrepareOptions:=[];
    d.Open;
  except
   d.Free;
   d:=nil;
   ExistAdInfo:=False;
  end;
  if TableName='ALIAS' then
  begin
   if not ExistAdInfo then Exit;
   with d do
   try
    while not eof do
    begin
     fi:=TpFIBFieldInfo.Create;
     GetAdditionalInfo(d,FastTrim(Fields[1].asString),fi);
     FFieldList.AddObject(FastTrim(Fields[1].asString),fi);
     Next
    end;
   finally
     Free;
   end
  end
  else
  begin
    q:=GetQueryForUse(aTransaction,  FormatNumberSQL  );
    with q do
    try
     Options:=[qoStartTransaction];
     Prepare;
     Params[0].asString:=TableName;
     q.ExecQuery;
     FFormatNumber:=q.Fields[0].asInteger;
    finally
      Close;
      FreeQueryForUse(q);
    end;
    q:=GetQueryForUse(aTransaction,
         'Select R.RDB$FIELD_NAME,R.RDB$FIELD_SOURCE,F.RDB$COMPUTED_BLR, '+CLRF+
     'R.RDB$DEFAULT_SOURCE DS,F.RDB$DEFAULT_SOURCE DS1, '+CLRF+
     'F.RDB$FIELD_TYPE, '+CLRF+'F.RDB$CHARACTER_SET_ID, F. RDB$DIMENSIONS'+CLRF+
     'from  RDB$RELATION_FIELDS R '+CLRF+
     'JOIN RDB$FIELDS F ON (R.RDB$FIELD_SOURCE = F.RDB$FIELD_NAME) '+CLRF+
     'where  R.RDB$RELATION_NAME=:TN '+CLRF+
     'order by R.RDB$FIELD_POSITION'
    );

    with q do
    try
     Options:=[qoStartTransaction,qoTrimCharFields];
     Params[0].asString:=TableName;
     ExecQuery;
     if q.eof then
     begin
      Close;
      FreeQueryForUse(q);
      q:=GetQueryForUse(aTransaction,
       'Select P.RDB$PARAMETER_NAME,F.RDB$FIELD_NAME,0,0,0,'+CLRF+
       'P.RDB$PARAMETER_TYPE,'+CLRF+'F.RDB$CHARACTER_SET_ID, NULL'+CLRF+
       'from RDB$PROCEDURE_PARAMETERS P'+CLRF+
       'JOIN RDB$FIELDS F ON (P.RDB$FIELD_SOURCE = F.RDB$FIELD_NAME)'+
       'WHERE P.RDB$PROCEDURE_NAME=:PN'+CLRF+
       'AND P.RDB$PARAMETER_TYPE=1'
      );
      Options:=[qoStartTransaction,qoTrimCharFields];      
      Params[0].asString:=TableName;
      ExecQuery;
     end;
     ClearFieldList;

     while not eof do
     begin
      fi:=TpFIBFieldInfo.Create;
      with fi do
      begin
       FDomainName:=Fields[1].asString;
       FIsComputed:= (Fields[2].SQLType=SQL_BLOB) and  not Fields[2].IsNull;
       FDefaultValue:='';
       if Fields[3].SQLType=SQL_BLOB then
       begin
         if not Fields[3].IsNull then
          FDefaultValue:=FastTrim(Fields[3].AsString);
         if FDefaultValue='' then
          if not Fields[4].IsNull then
           FDefaultValue:=FastTrim(Fields[4].AsString);
       end;
       if FDefaultValue<>'' then
       begin
        FDefaultValue:=FastTrim(FastCopy(FDefaultValue,8,MaxInt)); //Cut "DEFAULT"
        vQuoteExist:=False;
        p:=1;
        while P<= Length(FDefaultValue) do
        begin
          if FDefaultValue[P] in ['''','"'] then
          begin
            vQuoteExist:=True;
            Break
          end
          else
           Inc(P);
        end;
        if vQuoteExist then
        begin
         FDefaultValue:=CutQuote(FastTrim(FastCopy(FDefaultValue,P,MaxInt)));
        end;
        if FDefaultValue='' then
            FDefaultValueEmptyString := True;
         //Cut Leading Quote
       end;
       case Fields[5].asInteger of
        9,261: FCanIncToWhereClause:=False
       else
         FCanIncToWhereClause:=Fields[7].IsNull
       end;
       FCharSet:=Fields[6].asInteger;
       if ExistAdInfo then
        GetAdditionalInfo(d,FastTrim(Fields[0].asString),fi);
      end;
      FFieldList.AddObject(FastTrim(Fields[0].asString),fi);
      Next
     end;
    finally
     if ExistAdInfo then d.Free;
     q.Close;
     FreeQueryForUse(q)
    end
  end;
end;

//TpFIBTableInfoCollect
constructor TpFIBTableInfoCollect.Create(AOwner:TComponent);
begin
 inherited Create(AOwner);
 FListTabInfo:=TStringList.Create;
 FListTabInfo.Sorted:=True;
 FListTabInfo.Duplicates:=dupAccept;
 FDBNames    :=TStringList.Create;
 FDBNames    .Sorted:=True;
 FDBNames    .Duplicates:=dupAccept;
// FLock:=TMultiReadExclusiveWriteSynchronizer.Create;
 FLock:= TCriticalSection.Create;
end;

destructor  TpFIBTableInfoCollect.Destroy;//override;
begin
 FLock.Acquire;
 try
   Clear;
   FListTabInfo.Free;
   FListTabInfo:=nil;
   FDBNames    .Free;
   FDBNames:= nil;
//   FInternalTransaction.Free;
   inherited Destroy;
 finally
  FLock.Release;
  FLock.Free
 end;
end;

procedure TpFIBTableInfoCollect.Notification(AComponent: TComponent; Operation: TOperation);
var Index:integer;
begin
 if Operation=opRemove then
  if AComponent is TFIBDataBase then
  begin
    ClearForDataBase(TFIBDataBase(AComponent));
    Index:=DatabaseRepositories.IndexOfObject(AComponent);
    if Index<>-1 then DatabaseRepositories.Delete(Index)
  end;
 inherited Notification(AComponent,Operation);
end;

const
 Signature='FIB$MCF';
 DSSignature='FIB$MCFDS';
 CurStreamVersion=6;

procedure   TpFIBTableInfoCollect.SaveToStream(Stream:TStream);
var i,tc:integer;
    StreamVersion:integer;
begin
  with Stream do
  begin
   Seek(0,soFromBeginning);
   WriteStrToStream(Signature,Stream);
   StreamVersion:=CurStreamVersion;
   WriteBuffer(StreamVersion,SizeOf(Integer));
   WriteBuffer(FLastTransactionId,SizeOf(Integer));
   tc:=FListTabInfo.Count;
   WriteBuffer(tc,SizeOf(Integer));
   for i :=0  to Pred(tc) do
   begin
    WriteStrToStream(FListTabInfo[i],Stream);
    TpFIBTableInfo(FListTabInfo.Objects[i]).SaveToStream(Stream);
   end;
  end;
end;

procedure   TpFIBTableInfoCollect.LoadFromStream(Stream:TStream;DB:TFIBDatabase=nil);
var i,tc:integer;
    StreamVersion:integer;
    tn:Ansistring;
    ti:TpFIBTableInfo;
begin
  Clear;
  with Stream do
  begin
   Seek(0,soFromBeginning);
   SetLength(tn,Length(Signature));
   ReadBuffer(tn[1],Length(Signature)); // Signature
   if tn<>Signature then
   begin
    Seek(0,soFromBeginning);
    ReadStrFromStream(Stream,tn);
   end;
   if tn<>Signature then
    Exit;
   ReadBuffer(StreamVersion,SizeOf(Integer));
   if StreamVersion<CurStreamVersion then
    Exit;  // old style cache

   ReadBuffer(tc,SizeOf(Integer));
   if (DB<>nil) then
    PrepareInternalTransaction(DB);
   if tc>FLastTransactionId then
   begin
      Exit;  // Database is after backup
   end;

   ReadBuffer(tc,SizeOf(Integer));
   for i:=0 to Pred(tc) do
   begin
    ReadStrFromStream(Stream,tn);
    ti:=TpFIBTableInfo.Create(Self);
    ti.LoadFromStreamVersion(Stream,StreamVersion);
    FListTabInfo.AddObject(tn,ti)
   end;
  end;
end;

procedure   TpFIBTableInfoCollect.SaveToFile(const FileName:string);
var
  Stream: TFileStream;
begin
 if FListTabInfo.Count>0 then
   try
    Stream := TFileStream.Create(FileName, fmCreate);
    try
     SaveToStream(Stream);
    finally
     Stream.Free;
    end;
   except
   end
 else
  if FileExists(FileName) then
   SysUtils.DeleteFile(FileName);
end;

function   TpFIBTableInfoCollect.LoadFromFile(const FileName:string;DB:TFIBDatabase=nil):boolean;
var
  Stream: TFileStream;
begin
  Clear;
  Result:=FileExists(FileName);
  if not Result then Exit;
  Stream := TFileStream.Create(FileName, fmOpenRead);
  try
   LoadFromStream(Stream,DB);
  finally
   Stream.Free;
  end;
end;

procedure   TpFIBTableInfoCollect.ValidateSchema(aDataBase:TFIBDataBase;Proc:TpFIBAcceptCacheSchema);
const MaxCountSeparate =10;
var i:integer;
    DelCache,rt:boolean;
    FiDs,TfDs: TpFIBDataSet;
    vTr:TFIBTransaction;
//  FiDs - Versions from FIB$FIELDS_INFO
//  TfDs - metadata counters
begin
 PrepareInternalTransaction(aDataBase);
 vTr:=TFriendDatabase(aDataBase).GetInternalTransaction;
 TfDs:=nil; FiDs:=nil;
 with FListTabInfo do
 begin
   if (Count<=MaxCountSeparate) or   Assigned(Proc) then
    rt:=False
   else
   begin
     TfDs:=TpFIBDataSet.Create(nil);
     with TfDs do
     begin
      Database:=aDataBase;
      Options :=[poStartTransaction,poTrimCharFields];
      Transaction:= vTr;
      SelectSQL.Add(FormatNumbersSQL);
      PrepareOptions:=[];
      Open;
     end;
     rt:=
      TfDs.ExtLocate('RDB$RELATION_NAME','FIB$FIELDS_INFO',[eloInSortedDS]) ;
    if rt then
    begin
     FiDs:=TpFIBDataSet.Create(nil);
     with FiDs do
     begin
      Database:=aDataBase;
      Options :=[poStartTransaction,poTrimCharFields];
      Transaction:= vTr;
      SelectSQL.Add(FI_VersionsSQL);
      PrepareOptions:=[];
      Open;
     end;
    end;
   end;
   try
     for i:=Count-1 downto 0 do
     begin
      if Assigned(Proc) then
      begin
       DelCache:=False;
       Proc(FListTabInfo[i],DelCache);
       DelCache:= not DelCache
      end
      else
      if Count>MaxCountSeparate then
      begin
        DelCache:=(TFDS=nil) or(FListTabInfo[i]<>'ALIAS') and not (
         TfDs.ExtLocate('RDB$RELATION_NAME',FListTabInfo[i],[eloInSortedDS]) and
         (TfDs.Fields[1].asInteger=TpFIBTableInfo(Objects[i]).FFormatNumber));
        if rt and not DelCache  then
         DelCache:= (FiDs=nil) or not (
          FiDs.ExtLocate('TABLE_NAME',FListTabInfo[i],[eloInSortedDS]) and
          (FiDs.Fields[1].asInteger=TpFIBTableInfo(Objects[i]).FFIVersion));
      end
      else
       with TpFIBTableInfo(Objects[i]) do
        DelCache:= (Length(FTableName)>0) and not IsActualInfo(aDatabase);
      if DelCache then
      begin
       Objects[i].Free;
       Delete(i)
      end;
     end;
   finally
{    if vTr.InTransaction then
     vTr.Commit;}
    TfDs.Free;
    if rt then
     FiDs.Free;
   end;
 end;
end;

//{$WARNINGS ON}


function    TpFIBTableInfoCollect.FindTableInfo
 (const ADBName,ATableName:string):TpFIBTableInfo;
var Index: Integer;
    i:integer;
begin
 Result:=nil;
 with FDBNames do
 if not Find(aDBName, Index) then
 begin
  Index:=Add(aDBName);
 end;
 with FListTabInfo do
  if Find(ATableName, Index) then
   if aDBName=TpFIBTableInfo(Objects[Index]).FDBName then
    Result:=TpFIBTableInfo(Objects[Index])
   else // other Database
    for i:=Index+1 to Pred(Count) do
     if (ATableName=Strings[i]) and
        (aDBName=TpFIBTableInfo(Objects[i]).FDBName)
     then
     begin
      Result:=TpFIBTableInfo(Objects[i]);
      Break;
     end
     else
     if (ATableName<>Strings[i]) then Exit;
end;


procedure TpFIBTableInfoCollect.PrepareInternalTransaction(aDataBase:TFIBDataBase);
var
   vTr:TFIBTransaction;
begin
 vTr:=TFriendDatabase(aDataBase).GetInternalTransaction;
 if not vTr.Active then
  vTr.StartTransaction;
 FLastTransactionId:=vTr.TransactionID;
//^^^^ For this only
// Commit on TimeOut;
end;

function TpFIBTableInfoCollect.GetTableInfo(aDataBase:TFIBDataBase;
 const ATableName:string; WithRepositaryInfo:boolean
):TpFIBTableInfo;
var
   TmpTableName: string;
   vTr:TFIBTransaction;
begin
 vTr:=TFriendDatabase(aDataBase).GetInternalTransaction;
 TmpTableName := FastTrim(ReplaceStr(ATableName,'"',''));
 FLock.Acquire;
 try
   if not (csDesigning in aDataBase.ComponentState) then
    Result       := FindTableInfo(aDataBase.DBName,TmpTableName)
   else
   begin
    Result:=nil;
//    ClearForDataBase(aDatabase);
     ClearForTable(aTableName);
   end;
   if Result=nil then
   begin
    Result:=TpFIBTableInfo.Create(Self);
    Result.FWithFieldRepositaryInfo:=WithRepositaryInfo;
    Result.FillInfo(aDataBase,vTr,TmpTableName);
    FListTabInfo.AddObject(TmpTableName,Result);
   end
   else
   begin
    if Result.FNonValidated and FNeedValidate then
     if not Result.IsActualInfo(aDatabase) then
     begin
        ClearForTable(TmpTableName);
        Result:=GetTableInfo(aDataBase, ATableName,WithRepositaryInfo);
        Exit;
     end;
     if WithRepositaryInfo and not Result.FWithFieldRepositaryInfo then
     begin
       Result.GetRepositaryFieldInfos(TmpTableName,vTr);
       Result.FWithFieldRepositaryInfo:=WithRepositaryInfo;
     end;
   end;
 finally
  FLock.Release;
 end;
end;

function  TpFIBTableInfoCollect.GetFieldInfo(aDataBase:TFIBDataBase;
 const ATableName,AFieldName:string ;RepositoryInfo:boolean):TpFIBFieldInfo;
var
  ti:TpFIBTableInfo;
begin
    Result:=nil;
    ti:=GetTableInfo(aDataBase,ATableName,RepositoryInfo);
    if ti=nil then
     Exit;
    Result:=ti.FieldInfo(AFieldName);
end;


procedure   TpFIBTableInfoCollect.Clear;
var
  i:integer;
begin
 FLock.Acquire;
 try
  for i:=0 to Pred(FListTabInfo.Count) do
   FListTabInfo.Objects[i].Free;
  FListTabInfo.Clear;
 finally
  FLock.Release;
 end;
end;

procedure   TpFIBTableInfoCollect.ClearForDataBase(aDatabase:TFIBDataBase);
var
  i:integer;
begin
 FLock.Acquire;
 try
   if aDatabase=nil then Exit;
   with FListTabInfo do
   for i:=Pred(Count) downto 0 do
    if (TpFIBTableInfo(Objects[i]).FDBName=aDatabase.DBName)  then
    begin
     Objects[i].Free;
     Delete(i)
    end;
 finally
  FLock.Release;
 end;

end;

procedure   TpFIBTableInfoCollect.ClearForTable(const TableName:string);
var
 Index: Integer;
 TmpTableName: string;
begin
 TmpTableName := FastTrim(ReplaceStr(TableName,'"',''));
 FLock.Acquire;
 try
  with FListTabInfo do
  if Find(TmpTableName, Index) then
  begin
   while (Index<Count) and
    (TpFIBTableInfo(Objects[Index]).FTableName=TmpTableName)
   do
   begin
    Objects[Index].Free;    Delete(Index)
   end;
  end;
 finally
  FLock.Release;
 end;
end;

// DataSets info
constructor TpDataSetInfo.Create;
begin
 FSelectSQL:=TStringList.Create;
 FInsertSQL:=TStringList.Create;
 FUpdateSQL:=TStringList.Create;
 FDeleteSQL:=TStringList.Create;
 FRefreshSQL:=TStringList.Create;
 FKeyField:='';
 FGeneratorName:='';
end;

constructor TpDataSetInfo.Create(DataSet:TFIBDataSet);
begin
 if not(DataSet is TpFIBDataSet) then
  Exit
 else
 if (DataSet=nil) or (DataSet.DataBase=nil)
 or (DataSet.DataBase.DBName='')
 then
  Raise Exception.Create(SCantGetInfo+IntToStr(TpFIBDataSet(DataSet).DataSet_ID)+CLRF+
   SDataBaseNotAssigned
  );
 inherited Create;
 FDBName:=DataSet.DataBase.DBName;
 FSelectSQL:=TStringList.Create;
 FInsertSQL:=TStringList.Create;
 FUpdateSQL:=TStringList.Create;
 FDeleteSQL:=TStringList.Create;
 FRefreshSQL:=TStringList.Create;
 FKeyField:='';
 FGeneratorName:='';
end;

destructor  TpDataSetInfo.Destroy;
begin
 FSelectSQL.Free;
 FInsertSQL.Free;
 FUpdateSQL.Free;
 FDeleteSQL.Free;
 FRefreshSQL.Free;
 inherited Destroy;
end;

constructor TpDataSetInfoCollect.Create;//(AOwner:TComponent);
begin
 inherited Create;
 FListDataSetInfo:=TStringList.Create;
 FListDataSetInfo.Sorted:=True;
 FListDataSetInfo.Duplicates:=dupAccept;
 FLock:=TCriticalSection.Create;
end;

destructor  TpDataSetInfoCollect.Destroy;
begin
 Clear;
 FListDataSetInfo.Free;
 FLock.Free;
 inherited;
end;

procedure   TpDataSetInfoCollect.Clear;
var
  i:integer;
begin
 FLock.Acquire;
 try
   with FListDataSetInfo do
   begin
    for i:=0 to Pred(Count) do Objects[i].Free;
    Clear;
   end;
 finally
    FLock.Release;
 end;
end;

function TpDataSetInfoCollect.ActualVersionDSInfo(DataSet:TFIBDataSet):integer;
var
   q:TFIBQuery;
begin
  Result:=0;
  if not (DataSet is TpFIBDataSet) then
   Exit;
  q:=GetQueryForUse(DataSet.Transaction,
   'SELECT FIB$VERSION FROM FIB$DATASETS_INFO WHERE DS_ID=:DS_ID'
  );
  try
   q.Params[0].AsInteger:=TpFIBDataSet(DataSet).DataSet_ID;
   q.ExecQuery;
   if not q.Eof then
    Result:=q.Fields[0].AsInteger
  finally
    q.Close;
    FreeQueryForUse(q);
  end;
end;

function    TpDataSetInfoCollect.FindDataSetInfo(DataSet:TFIBDataSet; var Index:integer):TpDataSetInfo;
begin
  Result:=nil;
  if not (DataSet is TpFIBDataSet) or not Assigned(DataSet.Database) then
   Exit;
  if (DataSet=nil) or (TpFIBDataSet(DataSet).DataSet_ID=0) then
   Exit;
  Result:=FindDataSetInfo(DataSet.Database.DBName,TpFIBDataSet(DataSet).DataSet_ID,Index)
end;

function    TpDataSetInfoCollect.FindDataSetInfo(const DBName:string;DS_ID:Integer ; var Index:integer):TpDataSetInfo;
var ID_Str:string;
    i:integer;
begin
 ID_Str:=IntToStr(DS_ID);
 Result:=nil;
 with FListDataSetInfo do
  if Find(ID_Str, Index) then
   if DBName=TpDataSetInfo(Objects[Index]).FDBName then
    Result:=TpDataSetInfo(Objects[Index])
   else
   begin
    for i:=Index+1 to Pred(Count) do
     if (ID_Str=Strings[i]) and
        (DBName=TpDataSetInfo(Objects[i]).FDBName)
     then
     begin
      Result:=TpDataSetInfo(Objects[i]);
      Index:=i;
      Break;
     end
     else
      if (ID_Str<>Strings[i]) then Exit;
   end;
end;

function TpDataSetInfoCollect.GetDataSetInfo(DataSet:TFIBDataSet):TpDataSetInfo;
var
 Index:integer;
begin
 Result:=nil;

 if not (DataSet is TpFIBDataSet) then
   Exit;

 if
  (DataSet=nil) or (DataSet.DataBase=nil) or (TpFIBDataSet(DataSet).DataSet_ID=0)
 then
  Exit;
 Result:=FindDataSetInfo(DataSet,Index);
 if Result<>nil then
  if Result.FNonValidated  and FNeedValidate  then
  begin
    if ActualVersionDSInfo(DataSet)<>Result.FVersion then
    begin
      FListDataSetInfo.Delete(Index);
      Result.Free;
      Result:=nil
    end
    else
     Result.FNonValidated:=False
  end;
   
 if Result=nil then
 begin
  Result:=TpDataSetInfo.Create(DataSet);
  ExchangeDataSetInfo(DataSet,Result);
  FListDataSetInfo.AddObject(IntToStr(TpFIBDataSet(DataSet).DataSet_ID),Result);
 end;
end;

function TpDataSetInfoCollect.LoadDataSetInfo(DataSet:TFIBDataSet):boolean;
var
 DSI:TpDataSetInfo;
begin
  Result:=False;
  if not (DataSet is TpFIBDataSet) then
   Exit;
  FLock.Acquire;
  try
    if csDesigning in  DataSet.ComponentState then
     ClearDSInfo(DataSet);
    DSI:=GetDataSetInfo(DataSet);
    if DSI=nil then Exit;
    with TpFIBDataSet(DataSet) do
    begin
     if (DSI.FSelectSQL.Count>0) and (not SelectSQL.Equals(DSI.FSelectSQL)) then
     begin
      if not Conditions.Applied or (Conditions.PrimarySQL<>DSI.FSelectSQL.Text) then
       SelectSQL.Assign(DSI.FSelectSQL);
     end;
     if (DSI.FInsertSQL.Count>0) and (not InsertSQL.Equals(DSI.FInsertSQL)) then
      InsertSQL.Assign(DSI.FInsertSQL);
     if (DSI.FUpdateSQL.Count>0) and (not UpdateSQL.Equals(DSI.FUpdateSQL)) then
      UpdateSQL.Assign(DSI.FUpdateSQL);
     if (DSI.FDeleteSQL.Count>0) and (not DeleteSQL.Equals(DSI.FDeleteSQL)) then
      DeleteSQL.Assign(DSI.FDeleteSQL);
     if (DSI.FRefreshSQL.Count>0)and(not RefreshSQL.Equals(DSI.FRefreshSQL))then
      RefreshSQL.Assign(DSI.FRefreshSQL);
     with AutoUpdateOptions do
     begin
      SelectGenID:=(DSI.FKeyField<>'') and (DSI.FGeneratorName<>'');
      KeyFields :=DSI.FKeyField;
      GeneratorName:=DSI.FGeneratorName;
      UpdateOnlyModifiedFields:=DSI.FUpdateOnlyModifiedFields;
      UpdateTableName         :=DSI.FUpdateTableName;
     end;
     Conditions.ReadFromExchangeString(DSI.FConditions);
     Description :=DSI.FDescription
    end;
  finally
    FLock.Release;
  end;
end;

procedure TpDataSetInfoCollect.ClearDSInfo(DataSet:TFIBDataSet);
var ID_Str:string;
    Index:integer;
begin
 if not (DataSet is TpFIBDataSet) then
   Exit;
 FLock.Acquire;
 try
   if (DataSet=nil) or (TpFIBDataSet(DataSet).DataSet_ID=0) then Exit;
   ID_Str:=IntToStr(TpFIBDataSet(DataSet).DataSet_ID);
   with FListDataSetInfo do
   if Find(ID_Str, Index) then
    if DataSet.Database.DBName=TpDataSetInfo(Objects[Index]).FDBName then
    begin
      Objects[Index].Free;
      Delete(Index);
    end;
 finally
    FLock.Release;
 end;
end;

procedure   TpDataSetInfoCollect.ClearDSInfo(DS_ID:integer);
var ID_Str:string;
    Index:integer;
begin
 FLock.Acquire;
 try
   if (DS_ID=0) then
    Exit;
   ID_Str:=IntToStr(DS_ID);
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

constructor TpStoredProcCollect.Create;
begin
 inherited Create;
 FStoredProcNames:=TStringList.Create;
 FStoredProcNames.Sorted:=True;
 FStoredProcNames.Duplicates:=dupIgnore;
 FSPParamTxt    :=TStringList.Create;
 FLock:= TCriticalSection.Create;
end;

destructor  TpStoredProcCollect.Destroy;//override;
begin
 FStoredProcNames.Free;
 FSPParamTxt  .Free;
 FLock.Free;
 inherited Destroy;
end;

procedure   TpStoredProcCollect.Clear;
begin
  FStoredProcNames.Clear;
  FSPParamTxt     .Clear;
end;

function  TpStoredProcCollect.GetParamsText(DB:TFIBDatabase;
   const SPName:string):string;
var
  Qry   : TpFIBQuery;
  Trans : TpFIBTransaction;
  lSQLDA: TFIBXSQLDA;
begin

    begin
      Result := '';
      Qry := TpFIBQuery.Create(nil);
      Trans := TpFIBTransaction.Create(nil);
      with Qry,Trans do
      try
        Database := DB;
        DefaultDatabase := Database;
        Transaction := Trans;
        SQL.Text :=
         'SELECT RDB$PARAMETER_NAME, RDB$PARAMETER_TYPE FROM'+CLRF+
         'RDB$PROCEDURE_PARAMETERS WHERE RDB$PROCEDURE_NAME='+CLRF +
         '''' + FormatIdentifierValue(Database.SQLDialect, SPName) + ''''+CLRF +
         'ORDER BY RDB$PARAMETER_NUMBER';
        StartTransaction;
        try
          ExecQuery;
          lSQLDA := Current;
          while not Qry.Eof do
          begin
            if (lSQLDA.ByName['RDB$PARAMETER_TYPE'].AsInteger = 0) then
            begin
              if (Result <> '') then
                Result := Result + ', ';
              Result := Result + '?' + FormatIdentifier(Database.SQLDialect,
              FastTrim(lSQLDA.ByName['RDB$PARAMETER_NAME'].AsString));
            end;
            lSQLDA := Next;
          end;
          Close;
        finally
          Commit;
        end;
      finally
        Qry.Free;
        Trans.Free;
      end;
    end;
    if Result<>'' then Result:='('+Result+')'
end;

function TpStoredProcCollect.IndexOfSP(DB:TFIBDatabase;const SPName:string;
 ForceReQuery:boolean
):integer;
var
 RegSPName:string;
begin
 FLock.Acquire;
 try
   RegSPName:=DB.DBName+'||'+SPName;
   with FStoredProcNames do
   begin
     if ForceReQuery or not Find(RegSPName,Result) then
     begin
      Result:=Add(RegSPName);
      FSPParamTxt.Insert(Result,GetParamsText(DB,SPName))
     end;
   end;
 finally
   FLock.Release
 end;
end;

function StripQuote(const Value: string): string;
begin
  if (Value <> EmptyStr) and  (Value[1] in ['"', '''']) then
   Result := FastCopy(Value, 2, length(Value) - 2)
  else
   Result := Value;
end;


function TpStoredProcCollect.GetExecProcTxt(DB:TFIBDatabase;
         const SPName:string;   ForceReQuery:boolean
        ):string;

begin
  Result:='EXECUTE PROCEDURE ' + SPName+' '+
   FSPParamTxt[IndexOfSP(DB,StripQuote(SPName),ForceReQuery)]
end;


procedure   TpStoredProcCollect.ClearSPInfo(DB:TFIBDatabase);
var i,c:integer;
begin
   c:=Pred(FStoredProcNames.Count);
   for i:=c downto 0 do
    if Pos(DB.DBName,FStoredProcNames[i])=1 then
    begin
      FStoredProcNames.Delete(i);
      FSPParamTxt.Delete(i);
    end;
end;

// Routine function

function GetFieldInfos(Field:TField;RepositaryInfo:boolean):TpFIBFieldInfo;
var d:TpFIBDataSet;
    RelTable,RelField:string;
begin
 Result:=nil;
 if not (Field.DataSet is TpFIBDataSet) then Exit;
 d:=TpFIBDataSet(Field.DataSet);
 with d do
 begin
  RelTable:=GetRelationTableName(Field);
  RelField:=GetRelationFieldName(Field);
  Result:=
   ListTableInfo.GetFieldInfo(DataBase,
       RelTable,RelField,RepositaryInfo
   );
 end;
 if Result<>nil then Exit;

 RelTable:='ALIAS';
 RelField:=Field.FieldName;
 with d do
 Result:=
   ListTableInfo.GetFieldInfo(DataBase,
       RelTable,RelField,RepositaryInfo
   );
end;

function  GetOtherFieldInfo(Field:TField;const InfoName:string):string;
var vFI:TpFIBFieldInfo;
begin
 Result:='';
 vFI   :=GetFieldInfos(Field,True);
 if vFI=nil then Exit;
 Result:=vFI.FOtherInfo.Values[InfoName]
end;


{ TpErrorMessage }

constructor TpErrorMessage.Create(const aErrorMsg: string;
  aVersion: integer);
begin
  FErrorMsg :=aErrorMsg ;
  FVersion  :=aVersion  ;
end;



{ TpErrorMessagesCollect }


procedure TpErrorMessagesCollect.
 AddErrorMessage(const DBName,ErrorName,ErrorMsg:string;  Version:integer);
 var BaseIndex,ErrorIndex:integer;
   e: TpErrorMessage;
   ts:TStringList;
begin
 BaseIndex:=-1;
 if FindErrorMessage(DBName,ErrorName,BaseIndex,ErrorIndex) then
 begin
   with FDatabases do
    e:=TpErrorMessage(TStringList(Objects[BaseIndex]).Objects[ErrorIndex]);
   if Version>e.FVersion then
   begin
      e.FErrorMsg:=ErrorMsg;
      e.FVersion:=Version;
   end;
 end
 else
 begin
  FLock.BeginWrite;
  try
   if BaseIndex<0 then
    BaseIndex:=FDatabases.AddObject(DBName,nil);
   if FDatabases.Objects[BaseIndex]=nil then
   begin
     ts:=TStringList.Create;
     ts.Sorted:=True;
     ts.Duplicates:=dupIgnore;
     FDatabases.Objects[BaseIndex]:=ts;
   end
   else
    ts:=TStringList(FDatabases.Objects[BaseIndex]);
   e:= TpErrorMessage.Create(ErrorMsg,Version);
   ts.AddObject(ErrorName,e);
  finally
   FLock.EndWrite;
  end
 end;
end;

procedure TpErrorMessagesCollect.Clear;
var i,j:integer;
begin
  with FDatabases do
   for i := 0 to Count - 1 do
   begin
     for j:=0 to TStringList(Objects[i]).Count-1 do
       (TStringList(Objects[i]).Objects[j]).Free;
     Objects[i].Free;
   end;
  FDatabases.Clear;
end;

constructor TpErrorMessagesCollect.Create;
begin
  FDatabases:=TStringList.Create;
  FDatabases.Sorted:=True;
  FDatabases.Duplicates:=dupIgnore;
  FValidated :=False;
  FLock:=TMultiReadExclusiveWriteSynchronizer.Create;
end;

destructor TpErrorMessagesCollect.Destroy;
begin
  FLock.BeginWrite;
  try
   Clear;
   FDatabases.Free;
   inherited;
  finally
   FLock.EndWrite;
   FLock.Free;
  end 
end;

function TpErrorMessagesCollect.ErrorMessage(Tr:TFIBTransaction; const
  ErrorName: string): string;
var
  BaseIndex, ErrorIndex,ver: integer;
  q:TFIBQuery;
begin
  if   not (urErrorMessagesInfo in Tr.DefaultDatabase.UseRepositories)
    or not ExistERepositaryTable(Tr.DefaultDatabase)
  then
  begin
   Result:=''; Exit;
  end;
  if not FValidated then
  begin
    q:=GetQueryForUse(Tr,
     'SELECT  Max(FIB$VERSION) FROM FIB$ERROR_MESSAGES'
    );
    q.ExecQuery;
    if q.Eof then
     ver:=0
    else
     ver:=q.Fields[0].asInteger;
    if (ver=0) or (ver>FMaxVersion) then Clear;
    FMaxVersion:=ver;
    FValidated:=True;
  end;
  Result := '';
  if
   FindErrorMessage(Tr.DefaultDatabase.DBName,ErrorName,  BaseIndex, ErrorIndex)
  then
   Result:=
    TpErrorMessage(TStringList(FDatabases.Objects[BaseIndex]).Objects[ErrorIndex]).ErrorMsg
  else
  begin
    if not ExistERepositaryTable(Tr.DefaultDatabase) then Exit;
    q:=GetQueryForUse(Tr,
     'SELECT  MESSAGE_STRING, FIB$VERSION FROM FIB$ERROR_MESSAGES WHERE CONSTRAINT_NAME=?CN'
    );
    q.Options:=q.Options+[qoTrimCharFields];
    try
     q.Params[0].AsString:=ErrorName;
     q.ExecQuery;
     if q.Eof then
     begin
       AddErrorMessage(Tr.DefaultDatabase.DBName,ErrorName,'',0)
     end
     else
     begin
       Result:=q.Fields[0].AsString;
       AddErrorMessage(Tr.DefaultDatabase.DBName,ErrorName, Result ,q.Fields[1].AsInteger)
     end;
    finally
     FreeQueryForUse(q);
    end;
  end;
end;

function TpErrorMessagesCollect.FindErrorMessage(const DBName,ErrorName: string;
  var BaseIndex, ErrorIndex: integer): boolean;
begin
  Result := False;
  with FDatabases do
   if Find(DBName,BaseIndex) then
   begin
     if Objects[BaseIndex]<>nil then
      Result:=TStringList(Objects[BaseIndex]).Find(ErrorName,ErrorIndex);
   end
   else
    BaseIndex:=-1;
end;

const ErrSignature='FIB$Error_messages';

procedure TpErrorMessagesCollect.LoadFromFile(const FileName: string);
var
  Stream: TFileStream;
begin
  if not FileExists(FileName) then Exit;
  Stream := TFileStream.Create(FileName, fmOpenRead);
  try
   LoadFromStream(Stream);
  finally
   Stream.Free;
  end;
end;

procedure TpErrorMessagesCollect.LoadFromStream(Stream: TStream);
var 
    ver,i,j,c,c1:integer;
    st:Ansistring;
    aDBName,aErrorName,aErrorMsg:Ansistring;
    aVersion:integer;
begin
  with Stream do
  begin
   Position:=0;
   ReadBuffer(ver,SizeOf(integer));
   if ver<>1 then
    Exit;
   ReadStrFromStream(Stream,st);
   if st<>ErrSignature then
    Exit;
   ReadBuffer(FMaxVersion,SizeOf(integer));
   Clear;
   ReadBuffer(C,SizeOf(Integer));
   for i:=0 to c-1 do
   begin
    ReadStrFromStream(Stream,aDBName);
    ReadBuffer(C1,SizeOf(Integer));
    for j:=0 to c1-1 do
    begin
     ReadBuffer(aVersion,SizeOf(integer));
     ReadStrFromStream(Stream,aErrorName);
     ReadStrFromStream(Stream,aErrorMsg);
     AddErrorMessage(aDBName,aErrorName,aErrorMsg,aVersion)
    end;
   end;
  end;
end;

procedure TpErrorMessagesCollect.SaveToFile(const FileName: string);
var
  Stream: TFileStream;
begin
 if FDatabases.Count>0 then 
 try
  Stream := TFileStream.Create(FileName, fmCreate);
  try
   SaveToStream(Stream);
  finally
   Stream.Free;
  end;
 except
 end
 else
  if FileExists(FileName) then   SysUtils.DeleteFile(FileName);
 
end;

procedure TpErrorMessagesCollect.SaveToStream(Stream: TStream);

var L:integer;
    ver,i,j:integer;

begin
  with Stream do
  begin
   ver:=1;
   WriteBuffer(ver,SizeOf(integer)); // Version of Stream format
   WriteStrToStream(ErrSignature,Stream);
   WriteBuffer(FMaxVersion,SizeOf(integer));
   L:=FDatabases.Count;
   WriteBuffer(L,SizeOf(integer));   
   for i:=0 to FDatabases.Count -1 do
   begin
     WriteStrToStream(FDatabases[i],Stream);
     L:=TStrings(FDatabases.Objects[i]).Count;
     WriteBuffer(L,SizeOf(integer));
     with TStrings(FDatabases.Objects[i]) do
     for j := 0 to Count - 1 do
     begin
      WriteBuffer(TpErrorMessage(Objects[j]).FVersion,SizeOf(integer));
      WriteStrToStream(Strings[j],Stream);
      WriteStrToStream(TpErrorMessage(Objects[j]).ErrorMsg,Stream);
     end;
   end;
  end;
end;


procedure TpDataSetInfo.LoadFromStream(Stream: TStream);
var
  s:Ansistring;
begin
  ReadStrFromStream(Stream,FDBName);
  Stream.ReadBuffer(FVersion,SizeOf(integer));  
  ReadStrFromStream(Stream,s);
  FSelectSQL.Text:=s;
  ReadStrFromStream(Stream,s);
  FInsertSQL.Text:=s;
  ReadStrFromStream(Stream,s);
  FUpdateSQL.Text:=s;
  ReadStrFromStream(Stream,s);
  FDeleteSQL.Text:=s;
  ReadStrFromStream(Stream,s);
  FRefreshSQL.Text:=s;
  ReadStrFromStream(Stream,FKeyField);
  ReadStrFromStream(Stream,FGeneratorName);
  ReadStrFromStream(Stream,FDescription);
  ReadStrFromStream(Stream,FUpdateTableName);
  ReadStrFromStream(Stream,FConditions);
  Stream.ReadBuffer(FUpdateOnlyModifiedFields,SizeOf(boolean));
  FNonValidated:=True;
end;


procedure TpDataSetInfo.SaveToStream(Stream: TStream);
begin
   WriteStrToStream(FDBName,Stream);
   Stream.WriteBuffer(FVersion,SizeOf(integer));
   WriteStrToStream(FSelectSQL.Text,Stream);
   WriteStrToStream(FInsertSQL.Text,Stream);
   WriteStrToStream(FUpdateSQL.Text,Stream);
   WriteStrToStream(FDeleteSQL.Text,Stream);
   WriteStrToStream(FRefreshSQL.Text,Stream);
   WriteStrToStream(FKeyField,Stream);
   WriteStrToStream(FGeneratorName,Stream);
   WriteStrToStream(FDescription,Stream);
   WriteStrToStream(FUpdateTableName,Stream);
   WriteStrToStream(FConditions,Stream);
   Stream.WriteBuffer(FUpdateOnlyModifiedFields,SizeOf(boolean));
end;

procedure TpDataSetInfoCollect.LoadFromStream(Stream: TStream);
var i,c:integer;
    StreamVersion:integer;
    tn:Ansistring;
    di:TpDataSetInfo;
begin
  Clear;
  with Stream do
  begin
   Seek(0,soFromBeginning);
   SetLength(tn,Length(DSSignature));
   ReadBuffer(tn[1],Length(DSSignature)); // Signature
   if tn<>DSSignature then
   begin
    Seek(0,soFromBeginning);
    ReadStrFromStream(Stream,tn);
   end;
   if tn<>DSSignature then
    Exit;
   ReadBuffer(StreamVersion,SizeOf(Integer));
   if StreamVersion<1 then
    Exit;  // old style cache
   ReadBuffer(c,SizeOf(Integer));
   for i:=0 to Pred(c) do
   begin
    ReadStrFromStream(Stream,tn);
    di:=TpDataSetInfo.Create;
    di.LoadFromStream(Stream);
    FListDataSetInfo.AddObject(tn,di)
   end;
  end;
end;

procedure TpDataSetInfoCollect.SaveToStream(Stream: TStream);
var
 i,c:integer;
begin
 FLock.Acquire;
 with Stream do
 try
    Seek(0,soFromBeginning);
    WriteStrToStream(DSSignature,Stream);
    c:=1; /// StreamVersion
    WriteBuffer(c,SizeOf(Integer));
    c:=FListDataSetInfo.Count;
    WriteBuffer(c,SizeOf(Integer));
    for i:=0 to Pred(c) do
    begin
     WriteStrToStream(FListDataSetInfo[i],Stream);
     TpDataSetInfo(FListDataSetInfo.Objects[i]).SaveToStream(Stream);
    end;
 finally
    FLock.Release;
 end;
end;

function TpDataSetInfoCollect.LoadFromFile(
  const FileName: string): boolean;
var
  Stream: TFileStream;
begin
  FLock.Acquire;
  try
    Clear;
    Result:=FileExists(FileName);
    if not Result then Exit;
    Stream := TFileStream.Create(FileName, fmOpenRead);
    try
     LoadFromStream(Stream);
    finally
     Stream.Free;
    end;
  finally
   FLock.Release;
  end;
end;

procedure TpDataSetInfoCollect.SaveToFile(const FileName: string);
var
  Stream: TFileStream;
begin
 if FListDataSetInfo.Count>0 then
   try
    Stream := TFileStream.Create(FileName, fmCreate);
    try
     SaveToStream(Stream);
    finally
     Stream.Free;
    end;
   except
   end
 else
  if FileExists(FileName) then
   SysUtils.DeleteFile(FileName);
end;

procedure TpFIBTableInfoCollect.CommitInternalTransaction;
begin
{  if FInternalTransaction.Active then
   FInternalTransaction.Commit;}
end;

initialization
 LockRepList:= TCriticalSection.Create;
 ListTableInfo    :=TpFIBTableInfoCollect.Create(nil);
 ListDataSetInfo  :=TpDataSetInfoCollect.Create;
 DatabaseRepositories  :=TStringList.Create;
 ListSPInfo       :=TpStoredProcCollect.Create;
 ListErrorMessages:=TpErrorMessagesCollect.Create;
finalization
 ListErrorMessages.Free;
 DatabaseRepositories.Free;
 ListDataSetInfo.Free;
 ListSPInfo.Free ;
 ListTableInfo.Free;
 LockRepList.Free;
end.

