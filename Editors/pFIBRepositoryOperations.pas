unit pFIBRepositoryOperations;

interface
{$i ..\FIBPlus.inc}
 uses pFIBInterfaces;

 procedure   AdjustFRepositaryTable(DB:IFIBConnect);
 procedure   CreateErrorRepositoryTable(DB:IFIBConnect);
 procedure   CreateDataSetRepositoryTable(DB:IFIBConnect); 

implementation

uses pFIBEditorsConsts;

{const
    qryCreateTabFieldsRepository=
       'CREATE TABLE FIB$FIELDS_INFO (TABLE_NAME VARCHAR(31) NOT NULL,'#13#10+
       'FIELD_NAME VARCHAR(31) NOT NULL,'#13#10+
       'DISPLAY_LABEL VARCHAR(25),'#13#10+
       'VISIBLE FIB$BOOLEAN DEFAULT 1 NOT NULL,'#13#10+
       'DISPLAY_FORMAT VARCHAR(15),'#13#10+
       'EDIT_FORMAT VARCHAR(15),'#13#10+
       'TRIGGERED FIB$BOOLEAN DEFAULT 0 NOT NULL,'#13#10+
       'CONSTRAINT PK_FIB$FIELDS_INFO PRIMARY KEY (TABLE_NAME, FIELD_NAME))';
}

 procedure   AdjustFRepositaryTable(DB:IFIBConnect);
 begin
    if db.QueryValueAsStr(qryExistTable,0,['FIB$FIELDS_INFO'])='0' then
    begin
     if db.QueryValueAsStr(qryExistDomain,0,['FIB$BOOLEAN'])='0' then
       db.Execute(qryCreateBooleanDomain);
     db.Execute(qryCreateTabFieldsRepository);
     db.Execute('GRANT SELECT ON TABLE FIB$FIELDS_INFO TO PUBLIC');
    end;
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
       'KEY_FIELD VARCHAR(68),'+
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
