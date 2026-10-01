unit pFIBRepositoryOperations;

interface
{$i ..\FIBPlus.inc}
 uses pFIBInterfaces;

 procedure   AdjustFRepositaryTable(DB:IFIBConnect);
 procedure   CreateErrorRepositoryTable(DB:IFIBConnect);
 procedure   CreateDataSetRepositoryTable(DB:IFIBConnect);
 // Length in characters of a column, 0 when it doesn't exist
 function    ColumnLength(DB: IFIBConnect; const TableName, ColumnName: string): Integer;
 // TABLE_NAME and FIELD_NAME of FIB$FIELDS_INFO: 63 on Firebird 4+, else 31
 function    RepositoryNameLength(DB:IFIBConnect): Integer;
 procedure   WidenDataSetKeyField(DB: IFIBConnect);

implementation

uses SysUtils, pFIBEditorsConsts;

const
  KeyFieldLength = 1024;

function ColumnLength(DB: IFIBConnect; const TableName, ColumnName: string): Integer;
begin
  // RDB$CHARACTER_LENGTH is NULL on old servers, no COALESCE on InterBase and Firebird 1.0
  Result := StrToIntDef(DB.QueryValueAsStr(qryColumnLength, 0, [TableName, ColumnName]), 0);
  if Result = 0 then
    Result := StrToIntDef(DB.QueryValueAsStr(qryColumnLength, 1, [TableName, ColumnName]), 0);
end;

function RepositoryNameLength(DB: IFIBConnect): Integer;
begin
  if DB.IsFirebirdConnect and (ColumnLength(DB, 'RDB$RELATIONS', 'RDB$RELATION_NAME') > 31) then
    Result := 63
  else
    Result := 31;
end;

procedure WidenDataSetKeyField(DB: IFIBConnect);
begin
  if ColumnLength(DB, 'FIB$DATASETS_INFO', 'KEY_FIELD') < KeyFieldLength then
    DB.Execute(Format('ALTER TABLE FIB$DATASETS_INFO ALTER COLUMN KEY_FIELD TYPE VARCHAR(%d)',
      [KeyFieldLength]));
end;

// Firebird can't retype key columns: one statement, as Execute commits each one
procedure WidenFieldsRepositoryNames(DB: IFIBConnect; NewLength: Integer);
var
  KeyName, SQL: string;
begin
  if (ColumnLength(DB, 'FIB$FIELDS_INFO', 'TABLE_NAME') >= NewLength) and
    (ColumnLength(DB, 'FIB$FIELDS_INFO', 'FIELD_NAME') >= NewLength) then
    Exit;
  KeyName := Trim(DB.QueryValueAsStr(qryPrimaryKeyName, 0, ['FIB$FIELDS_INFO']));
  SQL := 'EXECUTE BLOCK AS BEGIN'#13#10;
  if KeyName <> '' then
    SQL := SQL + '  EXECUTE STATEMENT ''ALTER TABLE FIB$FIELDS_INFO DROP CONSTRAINT ' +
      KeyName + ''';'#13#10;
  SQL := SQL +
    Format('  EXECUTE STATEMENT ''ALTER TABLE FIB$FIELDS_INFO ALTER COLUMN TABLE_NAME TYPE VARCHAR(%d)'';'#13#10,
      [NewLength]) +
    Format('  EXECUTE STATEMENT ''ALTER TABLE FIB$FIELDS_INFO ALTER COLUMN FIELD_NAME TYPE VARCHAR(%d)'';'#13#10,
      [NewLength]);
  if KeyName <> '' then
    SQL := SQL + '  EXECUTE STATEMENT ''ALTER TABLE FIB$FIELDS_INFO ADD CONSTRAINT ' + KeyName +
      ' PRIMARY KEY (TABLE_NAME, FIELD_NAME)'';'#13#10;
  DB.Execute(SQL + 'END');
end;

 procedure   AdjustFRepositaryTable(DB:IFIBConnect);
 var
   NameLength: Integer;
 begin
    NameLength := RepositoryNameLength(DB);
    if db.QueryValueAsStr(qryExistTable,0,['FIB$FIELDS_INFO'])='0' then
    begin
     if db.QueryValueAsStr(qryExistDomain,0,['FIB$BOOLEAN'])='0' then
       db.Execute(qryCreateBooleanDomain);
     db.Execute(Format(qryCreateTabFieldsRepository, [NameLength]));
     db.Execute('GRANT SELECT ON TABLE FIB$FIELDS_INFO TO PUBLIC');
    end
    else
     WidenFieldsRepositoryNames(DB, NameLength);
//Adjust1
    if db.QueryValueAsStr(qryExistField,0,['FIB$FIELDS_INFO','DISPLAY_WIDTH'])='0' then
    begin
      try
       db.Execute(qryCreateFieldInfoVersionGen);
      except
      end;
      try
       db.Execute('ALTER TABLE FIB$FIELDS_INFO ADD DISPLAY_WIDTH INTEGER DEFAULT 0');
      except
      end;
      try
       db.Execute('ALTER TABLE FIB$FIELDS_INFO ADD FIB$VERSION INTEGER');
      except
      end;
      try
       db.Execute(
       'CREATE TRIGGER FIB$FIELDS_INFO_BI FOR FIB$FIELDS_INFO '+
       'ACTIVE BEFORE INSERT POSITION 0 as '+#13#10+
       'begin '+#13#10+
         'new.fib$version=gen_id(fib$field_info_version,1);'+#13#10+
       'end');
      except
      end;
      try
       db.Execute(
       'CREATE TRIGGER FIB$FIELDS_INFO_BU FOR FIB$FIELDS_INFO '+
       'ACTIVE BEFORE UPDATE POSITION 0 as '+#13#10+
       'begin '+#13#10+
         'new.fib$version=gen_id(fib$field_info_version,1);'+#13#10+
       'end');
      except
      end;
    end;
    if db.QueryValueAsStr(qryExistField,0,['FIB$FIELDS_INFO','DISPLAY_WIDTH'])='0' then
    begin
    //Adjust2
      try
       db.Execute('ALTER TABLE FIB$DATASETS_INFO ADD UPDATE_TABLE_NAME  VARCHAR(68)');
      except
      end;
      try
       db.Execute('ALTER TABLE FIB$DATASETS_INFO ADD UPDATE_ONLY_MODIFIED_FIELDS  FIB$BOOLEAN NOT NULL');
      except
      end;
      try
       db.Execute('ALTER TABLE FIB$DATASETS_INFO ADD CONDITIONS  BLOB sub_type 1 segment size 80');
      except
      end;
   end;
 end;

  procedure   CreateErrorRepositoryTable(DB:IFIBConnect);
  begin
    if db.QueryValueAsStr(qryExistTable,0,['FIB$ERROR_MESSAGES'])='0' then
    begin
      db.Execute('CREATE TABLE FIB$ERROR_MESSAGES ('+
      'CONSTRAINT_NAME  VARCHAR(67) NOT NULL,'+
      'MESSAGE_STRING   VARCHAR(100),'+
      'FIB$VERSION      INTEGER,'+
      'CONSTR_TYPE      VARCHAR(11) DEFAULT ''UNIQUE'' NOT NULL,'+
      'CONSTRAINT PK_FIB$ERROR_MESSAGES PRIMARY KEY (CONSTRAINT_NAME))');

      db.Execute('GRANT SELECT ON TABLE FIB$ERROR_MESSAGES TO PUBLIC');

      if db.QueryValueAsStr(qryGeneratorExist,0,['FIB$FIELD_INFO_VERSION'])='0' then
       db.Execute(qryCreateFieldInfoVersionGen);


       db.Execute('CREATE TRIGGER BI_FIB$ERROR_MESSAGES FOR FIB$ERROR_MESSAGES '+
       'ACTIVE BEFORE INSERT POSITION 0 AS '#13#10+
       'begin '#13#10'new.fib$version=gen_id(fib$field_info_version,1);'#13#10' end');

       db.Execute(       'CREATE TRIGGER BU_FIB$ERROR_MESSAGES FOR FIB$ERROR_MESSAGES '+
       'ACTIVE BEFORE UPDATE POSITION 0 AS '#13#10+
       'begin '#13#10'new.fib$version=gen_id(fib$field_info_version,1);'#13#10' end');


    end;
  end;

 procedure   CreateDataSetRepositoryTable(DB:IFIBConnect);
 begin
    if db.QueryValueAsStr(qryExistTable,0,['FIB$DATASETS_INFO'])='0' then
    begin
       db.Execute('CREATE TABLE FIB$DATASETS_INFO (DS_ID INTEGER NOT NULL,'#13#10+
       'DESCRIPTION VARCHAR(40),'+
       'SELECT_SQL BLOB sub_type 1 segment size 80,'#13#10+
       'UPDATE_SQL BLOB sub_type 1 segment size 80,'#13#10+
       'INSERT_SQL BLOB sub_type 1 segment size 80,'#13#10+
       'DELETE_SQL BLOB sub_type 1 segment size 80,'#13#10+
       'REFRESH_SQL BLOB sub_type 1 segment size 80,'#13#10+
       'NAME_GENERATOR VARCHAR(68), '+
       'KEY_FIELD VARCHAR(1024),'+
       'CONSTRAINT PK_FIB$DATASETS_INFO PRIMARY KEY (DS_ID))');

       db.Execute('GRANT SELECT ON TABLE FIB$DATASETS_INFO TO PUBLIC');
    end;
    //Adjust
       if db.QueryValueAsStr(qryExistDomain,0,['FIB$BOOLEAN'])='0' then
        db.Execute(qryCreateBooleanDomain);
       if db.QueryValueAsStr(qryGeneratorExist,0,['FIB$FIELD_INFO_VERSION'])='0' then
        db.Execute(qryCreateFieldInfoVersionGen);

      if db.QueryValueAsStr(qryExistField,0,['FIB$DATASETS_INFO','UPDATE_TABLE_NAME'])='0' then
        db.Execute('ALTER TABLE FIB$DATASETS_INFO ADD UPDATE_TABLE_NAME  VARCHAR(68)');

      if db.QueryValueAsStr(qryExistField,0,['FIB$DATASETS_INFO','UPDATE_ONLY_MODIFIED_FIELDS'])='0' then
        db.Execute('ALTER TABLE FIB$DATASETS_INFO ADD UPDATE_ONLY_MODIFIED_FIELDS  FIB$BOOLEAN NOT NULL');

      if db.QueryValueAsStr(qryExistField,0,['FIB$DATASETS_INFO','CONDITIONS'])='0' then
        db.Execute('ALTER TABLE FIB$DATASETS_INFO ADD CONDITIONS  BLOB sub_type 1 segment size 80');

      if db.QueryValueAsStr(qryExistField,0,['FIB$DATASETS_INFO','FIB$VERSION'])='0' then
        db.Execute('ALTER TABLE FIB$DATASETS_INFO ADD FIB$VERSION  INTEGER');

   try
     db.Execute('CREATE TRIGGER FIB$DATASETS_INFO_BI FOR FIB$DATASETS_INFO '+
     'ACTIVE BEFORE INSERT POSITION 0 as '+#13#10+
     'begin'#13#10+
       'new.fib$version=gen_id(fib$field_info_version,1);'#13#10+
     'end');
   except
   end;

   try
     db.Execute('CREATE TRIGGER FIB$DATASETS_INFO_BU FOR FIB$DATASETS_INFO '+
   'ACTIVE BEFORE UPDATE POSITION 0 as '+#13#10+
   'begin'#13#10+
     'new.fib$version=gen_id(fib$field_info_version,1);'#13#10+
   'end');
   except
   end;
 end;
end.
