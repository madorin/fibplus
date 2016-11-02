{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ InterBase databases                                           }
{                                                               }
{    FIBPlus is based in part on the product                    }
{    Free IB Components, written by Gregory H. Deatz for        }
{    Hoagland, Longo, Moran, Dunst & Doukas Company.            }
{    mailto:gdeatz@hlmdd.com                                    }
{                                                               }
{    Copyright (c) 1998-2010 Devrace Ltd.                       }
{    Written by Serge Buzadzhy (buzz@devrace.com)               }
{                                                               }
{ ------------------------------------------------------------- }
{    FIBPlus home page: http://www.fibplus.com/                 }
{    FIBPlus support  : http://www.devrace.com/support/         }
{ ------------------------------------------------------------- }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit pFIBDataRefresh;

interface
{$I FIBPlus.inc}

uses SysUtils,Classes, pFIBDataSet,FIBDataSet,DB,FIBQuery,FIBDatabase;


type
     TChangesCount= packed record
      cChangesCount:integer; // Commited Changes Count
      cDeletesCount:integer; // Commited Deletes Count
      ncChangesCount:integer;// NonCommited Changes Count
      ncDeletesCount:integer;// NonCommited Deletes Count
     end;

  // For one Table only
     TpFIBTableChangesReader=class(TComponent)
     private
//        Flags
      FCommitOrder:Int64; // last commit number
      FCurTransaction:Int64;                // For current transaction changes and  RollBack
      FLastTimeReaded:TDateTime;
      FSQLTextsPrepared:boolean;
      FExistNonCommitedChanges:boolean;
      function GetCurTransaction: Int64;
     private
// properties

      FReceivedChanges:TChangesCount;
      FTableName:string;

      FQryNonCommitedDelta:TpFIBDataSet;
      FQryNonCommitedDeletes:TpFIBDataSet;

      FQryCommitedDelta:TpFIBDataSet;
      FQryCommitedDeletes:TpFIBDataSet;
      FBeforeEndTransaction:TEndTrEvent;
      FAfterEndTransaction:TEndTrEvent;
     private
      FTransaction: TFIBTransaction;

      procedure ClearFlags;
      procedure SetCurTransactionID;
      function  GetAllChangesCount: Integer;

      procedure SetTransaction(const Value: TFIBTransaction);
      procedure AdjustDataSetProperties(ADataSet:TpFIBDataSet);
      procedure SetTableName(const Value: string);
      procedure CheckTransaction;
      procedure DoBeforeEndTransaction(EndingTR:TFIBTransaction;
          Action: TTransactionAction; Force: Boolean);
      procedure DoAfterEndTransaction(EndingTR:TFIBTransaction;
          Action: TTransactionAction; Force: Boolean);

     protected
      procedure Notification(AComponent: TComponent;Operation: TOperation); override;
      procedure PrepareSQLTexts;
      procedure Loaded; override;
     public
      constructor Create(AOwner:TComponent); override;
      destructor Destroy ; override;
      function  IsTransactionCommited(TransID:Int64):boolean;
      procedure ResetStartParams;
      function  GetActualCommitNo:Int64;
      procedure ReceiveDelta(OnlyCurTransactionChanges:boolean = False);
      procedure ApplyDelta(ToDataSet:TpFIBDataSet;const KeyFields:string);
      property  ReceivedChanges:TChangesCount read FReceivedChanges;
      property  ChangesCount:Integer read GetAllChangesCount;
      property  CommitedDelta       :TpFIBDataSet read FQryCommitedDelta;
      property  CommitedDeltaDel:TpFIBDataSet read FQryCommitedDeletes;
      property  NonCommitedDelta       :TpFIBDataSet read FQryNonCommitedDelta;
      property  NonCommitedDeltaDel:TpFIBDataSet read FQryNonCommitedDeletes;
      property  ExistNonCommitedChanges:boolean read FExistNonCommitedChanges;
// Start Params
      property  StartCommitNo:Int64 read FCommitOrder write FCommitOrder;
      property  CurTransactionID:Int64 read GetCurTransaction;
      property  LastTimeReaded:TDateTime read FLastTimeReaded write FLastTimeReaded;
     published
      property TableName:string read FTableName write SetTableName;
      property Transaction :TFIBTransaction read FTransaction write SetTransaction;
      property BeforeEndTransaction:TEndTrEvent read FBeforeEndTransaction write FBeforeEndTransaction;
      property AfterEndTransaction:TEndTrEvent read FAfterEndTransaction write FAfterEndTransaction;
     end;

implementation

uses {$IFDEF D6+} Variants,{$ENDIF}pFIBProps;
{ TpFIBRefresher }

(* DBSchema

CREATE DOMAIN FIB$BIGINT AS BIGINT;
CREATE DOMAIN FIB$TIMESTAMP AS TIMESTAMP;

CREATE GENERATOR FIB$GEN_COMMIT_NO;
CREATE GENERATOR FIB$GEN_TRANSACTION_ID;


CREATE TABLE FIB$TRANSACTIONS(
  TRANSACTION_ID FIB$BIGINT,
  COMMIT_NO   FIB$BIGINT ,
  COMMIT_TIME    FIB$TIMESTAMP
);

CREATE  DESCENDING INDEX IDX_FIB$COMMIT_NO
ON FIB$TRANSACTIONS (COMMIT_NO);


CREATE TABLE FIB$CHANGED_TABLES(
  TABLE_NAME     VARCHAR(32),
  TRANSACTION_ID FIB$BIGINT
);


CREATE UNIQUE INDEX IDX_CHANGED_TABLES
ON FIB$CHANGED_TABLES (TRANSACTION_ID, TABLE_NAME);

CREATE PROCEDURE FIB$CLEAR_TRANSACTION_ID
AS
BEGIN
  rdb$set_context('USER_TRANSACTION','FIB$TRANSACTION_ID',NULL);
END
;

CREATE PROCEDURE FIB$GET_TRANSACTION_ID (
  FORCE   SMALLINT
)
RETURNS (
  TRANS_ID   INTEGER
)
AS
BEGIN
  TRANS_ID=rdb$get_context('USER_TRANSACTION','FIB$TRANSACTION_ID');
  if ((TRANS_ID is NULL) AND (FORCE=1)) then
  begin
   TRANS_ID=GEN_ID(FIB$GEN_TRANSACTION_ID,1);
   rdb$set_context('USER_TRANSACTION','FIB$TRANSACTION_ID',:TRANS_ID);
  end
  suspend;
END
;

CREATE TRIGGER FIB$ON_TRANSACTION_ROLLBACK
ACTIVE ON  TRANSACTION ROLLBACK  POSITION 0
as
BEGIN
 EXECUTE PROCEDURE FIB$CLEAR_TRANSACTION_ID;
END
;

CREATE TRIGGER FIB$ON_TRANSACTION_COMMIT
ACTIVE ON  TRANSACTION COMMIT  POSITION 0
AS
   DECLARE TRANS_ID BIGINT;
   DECLARE COMMIT_NO BIGINT;
BEGIN
  Select TRANS_ID From FIB$GET_TRANSACTION_ID(0) INTO :TRANS_ID;
  if  (NOT TRANS_ID is NULL) then
  begin
    COMMIT_NO=GEN_ID(FIB$GEN_COMMIT_NO,1);
    insert into FIB$TRANSACTIONS (TRANSACTION_ID,COMMIT_NO,COMMIT_TIME)
    values(:TRANS_ID,:COMMIT_NO,'NOW');

      Update  FIB$CHANGED_TABLES Set
        COMMIT_NO=:COMMIT_NO
      where
        TRANSACTION_ID=:TRANS_ID
    ;
    EXECUTE PROCEDURE FIB$CLEAR_TRANSACTION_ID;
  end
END
;


// For Each table


ALTER TABLE BIGTABLE ADD FIB$TRANSACTION_ID FIB$BIGINT;
ALTER TABLE BIGTABLE ADD FIB$UPDATE_TIME FIB$TIMESTAMP;

CREATE TABLE BIGTABLE_DELETED(
  ID                 INTEGER NOT NULL,
  FIB$TRANSACTION_ID FIB$BIGINT,
  FIB$DELETED_TIME   FIB$TIMESTAMP
);

CREATE TRIGGER FIB$TRANSLOG_BIGTABLE FOR BIGTABLE
ACTIVE BEFORE INSERT OR UPDATE OR DELETE POSITION 0
AS
 DECLARE VARIABLE TRANS_ID INTEGER;
BEGIN
  Select TRANS_ID From FIB$GET_TRANSACTION_ID(1) INTO
    :TRANS_ID;

 if (DELETING) then
  Insert into BIGTABLE_DELETED(ID,FIB$TRANSACTION_ID,FIB$DELETED_TIME)
   values (Old.ID,:TRANS_ID,'NOW');
 else
 begin
   new.FIB$TRANSACTION_ID=:TRANS_ID;
   new.FIB$UPDATE_TIME   ='NOW';
 end
END
;
*)

type
   TFriendDataSet=class(TFIBDataSet);

procedure TpFIBTableChangesReader.AdjustDataSetProperties(ADataSet: TpFIBDataSet);
begin
  with ADataSet do
  begin
    if Active then Close;
    Transaction:=FTransaction;
    if Assigned(FTransaction) then
     Database:=FTransaction.DefaultDatabase;
    CachedUpdates:=True;
    PrepareOptions:=[];
    Options:=[poTrimCharFields,poFetchAll,poFreeHandlesAfterClose]
  end;
end;

procedure TpFIBTableChangesReader.ApplyDelta(ToDataSet: TpFIBDataSet;const KeyFields:string);
begin
    if ReceivedChanges.cChangesCount>0 then
     ToDataSet.RefreshFromDataSet(CommitedDelta,KeyFields);
    if ReceivedChanges.cDeletesCount>0 then
     ToDataSet.RefreshFromDataSet(CommitedDeltaDel,KeyFields,True);

    if ReceivedChanges.ncChangesCount>0 then
     ToDataSet.RefreshFromDataSet(NonCommitedDelta,KeyFields);

    if ReceivedChanges.ncDeletesCount>0 then
     ToDataSet.RefreshFromDataSet(NonCommitedDeltaDel,KeyFields,True);
end;

procedure TpFIBTableChangesReader.CheckTransaction;
begin
 if not Assigned(FTransaction) or not Assigned(FTransaction.DefaultDatabase) or
  not FTransaction.Active
 then
  raise Exception.Create('Can''t use ChangesReader. Transaction is not active')
end;

procedure TpFIBTableChangesReader.ClearFlags;
begin
 FCommitOrder:=0;
 FCurTransaction:=0;     // For current transaction changes and  RollBack
 FLastTimeReaded:=0;
end;


constructor TpFIBTableChangesReader.Create(AOwner: TComponent);
begin
  inherited;


  FQryNonCommitedDelta:=TpFIBDataSet.Create(Self);
  FQryNonCommitedDeletes:=TpFIBDataSet.Create(Self);

  FQryCommitedDelta:=TpFIBDataSet.Create(Self);
  FQryCommitedDeletes:=TpFIBDataSet.Create(Self);

end;

destructor TpFIBTableChangesReader.Destroy;
begin
  inherited;
end;

procedure TpFIBTableChangesReader.DoAfterEndTransaction(EndingTR: TFIBTransaction;
  Action: TTransactionAction; Force: Boolean);
begin
 FLastTimeReaded:=0;
 FCurTransaction:=0;
 FExistNonCommitedChanges:=False;
 if Assigned(FAfterEndTransaction) then
  FAfterEndTransaction(EndingTR,Action, Force);
end;

procedure TpFIBTableChangesReader.DoBeforeEndTransaction(EndingTR: TFIBTransaction;
  Action: TTransactionAction; Force: Boolean);
begin
 if Action in [TARollback, TARollbackRetaining] then
 begin
  FLastTimeReaded:=0;
  ReceiveDelta(True)
 end;
 if Assigned(FBeforeEndTransaction) then
  FBeforeEndTransaction(EndingTR,Action, Force);
end;

procedure TpFIBTableChangesReader.ReceiveDelta(OnlyCurTransactionChanges:boolean = False);
var
   tmpCommitOrder:Int64;
   tmpTime:TDateTime;
begin
   SetCurTransactionID; 
   PrepareSQLTexts;
   FillChar(FReceivedChanges,SizeOf(FReceivedChanges),0);
   with Transaction do
   begin
     if not OnlyCurTransactionChanges then
     begin
       tmpCommitOrder:=GetActualCommitNo;
       if tmpCommitOrder<>FCommitOrder then
       begin
         with FQryCommitedDelta do
         begin
           ParamByName('FIB$COMMIT_NO').asInt64:=FCommitOrder;
           CloseOpen(True);
         end;
         FReceivedChanges.cChangesCount:=FQryCommitedDelta.RecordCount;

         with FQryCommitedDeletes do
         begin
           ParamByName('FIB$COMMIT_NO').asInt64:=FCommitOrder;
           CloseOpen(True);
         end;
         FReceivedChanges.cDeletesCount:=FQryCommitedDeletes.RecordCount;
         FCommitOrder:=tmpCommitOrder;
       end;
     end;
// UnCommited Changes
     if FCurTransaction>0 then
     begin
       tmpTime:=DefaultDatabase.GetServerTime;
       with FQryNonCommitedDelta do
       begin
         ParamByName('TRANS_ID').asInt64:=FCurTransaction;
         ParamByName('DT').asDateTime:=FLastTimeReaded;
         CloseOpen(True);
         FReceivedChanges.ncChangesCount:=RecordCount;
       end;

       with FQryNonCommitedDeletes do
       begin
         ParamByName('TRANS_ID').asInt64:=FCurTransaction;
         ParamByName('DT').asDateTime:=FLastTimeReaded;
         CloseOpen(True);
         FReceivedChanges.ncDeletesCount:=RecordCount;
       end;
       FExistNonCommitedChanges:=FExistNonCommitedChanges or
        (FReceivedChanges.ncDeletesCount>0) or (FReceivedChanges.ncChangesCount>0);
       FLastTimeReaded:=tmpTime;
     end;
   end;

end;

procedure TpFIBTableChangesReader.SetCurTransactionID;
var
  v:  Variant;{$IFNDEF D6+}   I:integer;{$ENDIF}

begin
// Set Flags
  CheckTransaction;
  if Transaction.IsReadOnly then
   FCurTransaction:=0
  else 
  if FCurTransaction=0 then
    with Transaction.DefaultDatabase do
    begin
     v:=QueryValue('Select TRANS_ID From FIB$GET_TRANSACTION_ID(0)',0,Transaction);
     if not VarIsNull(v)  then
     begin
      {$IFNDEF D6+}
         i:=v;
         FCurTransaction:=i
      {$ELSE}
        FCurTransaction:=v;
      {$ENDIF}

     end
    end;
end;

procedure TpFIBTableChangesReader.SetTableName(const Value: string);
begin
 if FTableName<>Value then
 begin
  FTableName := Value;
  FSQLTextsPrepared:=False;
  FLastTimeReaded:=0;
 end 
end;

procedure TpFIBTableChangesReader.SetTransaction(const Value: TFIBTransaction);
begin
 if   Value<> FTransaction then
 begin
  if not (csDesigning in ComponentState) then
  if Assigned(FTransaction) then
  begin
   FTransaction.RemoveEndEvent(DoBeforeEndTransaction,tetBeforeEndTransaction);
   FTransaction.RemoveEndEvent(DoAfterEndTransaction,tetAfterEndTransaction);
  end;

  FTransaction := Value;
  if not (csDesigning in ComponentState) then
  begin
    if Assigned(FTransaction) then
    begin
     FTransaction.AddEndEvent(DoBeforeEndTransaction,tetBeforeEndTransaction);
     FTransaction.AddEndEvent(DoAfterEndTransaction,tetAfterEndTransaction);
    end;

    AdjustDataSetProperties(FQryNonCommitedDelta);
    AdjustDataSetProperties(FQryNonCommitedDeletes);
    AdjustDataSetProperties(FQryCommitedDelta);
    AdjustDataSetProperties(FQryCommitedDeletes);
    FLastTimeReaded:=0
  end;
 end
end;

procedure TpFIBTableChangesReader.ResetStartParams;
begin
 FCommitOrder:=GetActualCommitNo;
 FLastTimeReaded:=Transaction.DefaultDatabase.GetServerTime  ;
 AdjustDataSetProperties(FQryNonCommitedDelta);
 AdjustDataSetProperties(FQryNonCommitedDeletes);
 AdjustDataSetProperties(FQryCommitedDelta);
 AdjustDataSetProperties(FQryCommitedDeletes);
end;

function  TpFIBTableChangesReader.IsTransactionCommited(TransID:Int64):boolean;
var
  v1:variant;
begin
// Test LimboTransaction
 if TransID=FCurTransaction then
  Result:=False
 else
 begin
   CheckTransaction;
   with Transaction.DefaultDatabase do
    begin
      v1:=QueryValue('Select COUNT(COMMIT_NO) from FIB$TRANSACTIONS WHERE '+
       'TRANSACTION_ID = '+IntToStr(TransID),0,nil,False
      );
      Result:=v1<>0;
    end
 end
end;

procedure TpFIBTableChangesReader.Loaded;
begin
  inherited;
   AdjustDataSetProperties(FQryNonCommitedDelta);
    AdjustDataSetProperties(FQryNonCommitedDeletes);
    AdjustDataSetProperties(FQryCommitedDelta);
    AdjustDataSetProperties(FQryCommitedDeletes);

end;

function TpFIBTableChangesReader.GetActualCommitNo: Int64;
var
//{$IFDEF D6+}  v:  Variant;{$ELSE} v:integer;{$ENDIF}
  v:Variant;
{$IFNDEF D6+}
  j:integer;
{$ENDIF}
begin
 CheckTransaction;
 with Transaction.DefaultDatabase do
  begin
    v:=QueryValue('Select MAX(COMMIT_NO) from FIB$TRANSACTIONS',0,Transaction);
    if VarIsNull(v) then
     Result:=0
    else
    begin
    {$IFDEF D6+}
       Result:=v;
    {$ELSE}
       j:=v;
       Result:=j
    {$ENDIF}

    end
  end
end;

function TpFIBTableChangesReader.GetAllChangesCount: Integer;
begin
  Result:=FReceivedChanges.cChangesCount+
    FReceivedChanges.cDeletesCount+
    FReceivedChanges.ncChangesCount+
    FReceivedChanges.ncDeletesCount
end;


procedure TpFIBTableChangesReader.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) then
  if  (AComponent = FTransaction) then
  begin
   FTransaction:=nil;
   ClearFlags  ;
  end
end;

function GetDeletedTableName(const TableName:string):string;
begin
  if Length(TableName)=0 then
  begin
    Result:=''; Exit;
  end;
  if TableName[1]<>'"' then
   Result:=TableName+'_DELETED'
  else
   Result:=Copy(TableName,1,Length(TableName)-1)+'_DELETED"';
end;

procedure TpFIBTableChangesReader.PrepareSQLTexts;
var
   BegSQLChanges,TabNameDeleted:string;
begin
  if not FSQLTextsPrepared then
  begin
    BegSQLChanges:='SELECT * FROM '+FTableName+' T'+
        #13#10'join FIB$TRANSACTIONS TR ON (TR.TRANSACTION_ID='+
       'T.FIB$TRANSACTION_ID)';
       ;
    FQryCommitedDelta.SelectSQL.Text:=
     BegSQLChanges+#13#10'WHERE TR.COMMIT_NO>:FIB$COMMIT_NO';

    FQryNonCommitedDelta.SelectSQL.Text:=
      'SELECT * FROM '+FTableName+' T WHERE T.FIB$TRANSACTION_ID=:TRANS_ID AND T.FIB$UPDATE_TIME>=:DT';

    TabNameDeleted:=GetDeletedTableName(FTableName);
    FQryCommitedDeletes.SelectSQL.Text:='SELECT * FROM '+TabNameDeleted+' D'#13#10+
     'join FIB$TRANSACTIONS TR ON (TR.TRANSACTION_ID=D.FIB$TRANSACTION_ID )'#13#10+
     'WHERE TR.COMMIT_NO>:FIB$COMMIT_NO';

    FQryNonCommitedDeletes.SelectSQL.Text:='SELECT * FROM '+TabNameDeleted+' D'#13#10+
     'WHERE D.FIB$TRANSACTION_ID=:TRANS_ID AND D.FIB$DELETED_TIME>=:DT';
    FSQLTextsPrepared:=True
  end;
end;






function TpFIBTableChangesReader.GetCurTransaction: Int64;
begin
   SetCurTransactionID;
   Result:=FCurTransaction
end;

end.
