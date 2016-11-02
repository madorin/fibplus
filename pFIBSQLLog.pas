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
unit pFIBSQLLog;

interface

uses
   SysUtils, Classes,
   pTestInfo,pFIBInterfaces,FIBDatabase,pFIBProps,fib,StdFuncs,pFIBQuery,
   FIBQuery, pFIBCacheQueries,FIBPlatforms
  ;

type
  TFIBStatisticsParam = (
    fspExecuteCount,
    fspPrepareCount,
    fspSumTimeExecute,
    fspAvgTimeExecute,
    fspMaxTimeExecute,
    fspLastTimeExecute
  );

  TFIBStatisticsParams= set of TFIBStatisticsParam;

  TFIBSQLLogger =class;
  TpFIBStatistics=TFIBSQLLogger;


  TSQLLogEvent = procedure(const ObjectName,Operation,EventText: String;
   DataType: TLogFlag; cApplication :String;
   EventTime : TDateTime; var WriteToLog: Boolean) of object;



  TFIBSQLLogger = class(TComponent,ISQLLogger,ISQLStatMaker)
  private
    tr:TFIBTransaction;
    FAppStatInfo:TTestInfo;
    FApplicationID :string;
    FDatabase   :TFIBDatabase;
    FStatisticsParams  :TFIBStatisticsParams;
    FExistStatTable :TpFIBExistObject;
    FOnLogEvent: TSQLLogEvent;
    FLogFlags:TLogFlags;
    FLogList: TStrings;
    FLogFileName:string;
    FForceSaveToFile:boolean;
    FActiveLogging:boolean;
    FStream : TFileStream;
    procedure SetActiveStatistics(Value:boolean);
    function  GetActiveStatistics:boolean;
    procedure SetActiveLogging(const Value:boolean);
    function  GetActiveLogging:boolean;

    procedure SetLogFileName(FileName:string);
    procedure SetStatParams (Value:TFIBStatisticsParams);
    procedure SetDatabase(DB:TObject);
    procedure CheckDatabase;
    procedure OnDisconnect(Sender:TObject);
    function GetFS: boolean;
    procedure SetFS(const Value: boolean);
    function    GetLogFlags :TLogFlags;
    procedure   SetLogFlags(Value:TLogFlags);
    function GetLogFileName: string;
    function GetStatMaker: ISQLStatMaker;
    function GetLogger :ISQLLogger;
  protected
    procedure   Notification(AComponent: TComponent; Operation: TOperation); override;
// ISQLLogger
   procedure   WriteData(const ObjectName,OperationName,EventText: String;
    DataType: TLogFlag
   );


  public
    constructor Create(AOwner:TComponent); override;
    destructor  Destroy; override;
    function    GetInstance:TObject;    
    procedure   Clear;
    procedure   SaveStatisticsToFile(const FileName:string);
    procedure   SortStatisticsForPrint(const VarName:string;Ascending:boolean);
    function    ExistStatisticsTable:boolean;
    procedure   CreateStatisticsTable;
    procedure   SaveStatisticsToDB(ForMaxExecTime:integer=0);
    procedure   SaveLog;
    property    Database   :TFIBDatabase read FDatabase  ;
    property    StatisticsMaker:ISQLStatMaker read GetStatMaker implements ISQLStatMaker;
    property    Logger:ISQLLogger read GetLogger;
  published
    property    ActiveStatistics:boolean read GetActiveStatistics write SetActiveStatistics default False;
    property    LogFileName:string read GetLogFileName write SetLogFileName;
    property    ApplicationID :string read FApplicationID write FApplicationID;
    property    StatisticsParams  :TFIBStatisticsParams read FStatisticsParams write SetStatParams
     default
      [fspExecuteCount,fspSumTimeExecute,fspAvgTimeExecute, fspMaxTimeExecute,
        fspLastTimeExecute,fspPrepareCount
      ];
    property    LogFlags: TLogFlags read  GetLogFlags write SetLogFlags  default
     [lfQPrepare, lfQExecute,   lfConnect, lfTransact];
    property    ForceSaveLog:boolean read GetFS write SetFS;
    property    ActiveLogging:boolean read GetActiveLogging write SetActiveLogging default False;
    property    OnLogEvent: TSQLLogEvent read FOnLogEvent write FOnLogEvent;
  end;



implementation

uses StrUtil, FIBConsts;

{ TFIBSQLLogger }

procedure TFIBSQLLogger.CheckDatabase;
begin
 if not Assigned(FDatabase) then
  FIBError(feDatabaseNotAssigned,[CmpFullName(Self)]);
 if not FDatabase.Connected then
  FIBError(feDatabaseClosed,[CmpFullName(Self)]);
end;

procedure TFIBSQLLogger.Clear;
begin
 FAppStatInfo.Clear;
end;

constructor TFIBSQLLogger.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAppStatInfo:=TTestInfo.Create;
  FStatisticsParams  :=[
    fspExecuteCount,
    fspPrepareCount,
    fspSumTimeExecute,
    fspAvgTimeExecute,
    fspMaxTimeExecute,
    fspLastTimeExecute
  ];
  FLogList:=TStringList.Create;
  FLogFlags:=[lfQPrepare, lfQExecute,   lfConnect, lfTransact];
  FExistStatTable:=eoUnknown;
  tr:=TFIBTransaction.Create(Self);
end;

destructor TFIBSQLLogger.Destroy;
begin
  if Assigned(FDatabase) then
  begin
    SetDatabase(nil);
  end;
  FAppStatInfo.Free;
  FLogList.Free;
  inherited;  
end;

procedure   TFIBSQLLogger.CreateStatisticsTable;
var q:TpFIBQuery;
begin
 if not ExistStatisticsTable then
 begin
  tr.DefaultDatabase:=FDatabase;
  q:=TpFIBQuery.Create(Self);
  q.Database:=FDatabase;
  q.Transaction:=tr;
  q.ParamCheck :=false;
  try
   tr.StartTransaction;
   q.SQL.Text :='CREATE GENERATOR FIB$APP_STATISTICS_GEN_ID';
   q.ExecQuery;

   q.SQL.Text :=
    'CREATE TABLE FIB$APP_STATISTICS ( ID INTEGER NOT NULL, '+
    'APP_ID VARCHAR(12), SQL_TEXT BLOB SUB_TYPE -2 SEGMENT SIZE 1,'+
    'EXECUTECOUNT INTEGER, PREPARECOUNT INTEGER, SUMTIMEEXECUTE INTEGER, AVGTIMEEXECUTE INTEGER,'+
    'MAXTIMEEXECUTE INTEGER, MAXTIME_PARAMS BLOB SUB_TYPE -2 SEGMENT SIZE 1,'+
    'LASTTIMEEXECUTE INTEGER, LOG_DATE '+
     iifStr(FDatabase.SQLDialect<2,'DATE','TIMESTAMP')+
    ' ,CMP_NAME VARCHAR(256), ATTACHMENT_ID INTEGER)';
   q.ExecQuery;
   q.SQL.Text :=
    'ALTER TABLE FIB$APP_STATISTICS ADD CONSTRAINT PK_FIB$APP_STATISTICS PRIMARY KEY (ID)';
   q.ExecQuery;
   q.SQL.Text :=
    'CREATE TRIGGER FIB$APP_STATISTICS_BI FOR FIB$APP_STATISTICS '+
    'ACTIVE BEFORE INSERT POSITION 0 '+
    'AS BEGIN '+#13#10+
    'IF (NEW.ID IS NULL) THEN '+#13#10+
    'NEW.ID = GEN_ID(FIB$APP_STATISTICS_GEN_ID,1);'+#13#10+
    'NEW.log_date =''NOW'';'+#13#10+'END';
   q.ExecQuery;
   tr.Commit;
   FExistStatTable:=eoYes;
  finally
   q.Free;
  end;
 end;
end;

function TFIBSQLLogger.ExistStatisticsTable: boolean;
begin
 CheckDatabase;
 case FExistStatTable of
  eoYes: Result:=True;
  eoNo : Result:=False;
 else
  Result:=
   FDatabase.QueryValue(
    'Select Count(*) from RDB$RELATIONS Where RDB$RELATION_NAME=''FIB$APP_STATISTICS''',0
   )>0;
  if Result then
   FExistStatTable:=eoYes
  else
   FExistStatTable:=eoNo;
 end;
end;

procedure TFIBSQLLogger.SaveStatisticsToDB(ForMaxExecTime:integer=0);
var i:integer;
    q:TFIBQuery;
    s:string;
begin
 if not ExistStatisticsTable then
  raise Exception.Create(SFIBStatNoSave);
 if IsBlank(FApplicationID) then
  raise Exception.Create(SFIBStatNoSaveAppID);
 tr.DefaultDatabase:=FDatabase;
 q:=  GetQueryForUse(tr,
   'Insert into FIB$APP_STATISTICS '+
   '( APP_ID, SQL_TEXT, EXECUTECOUNT,PREPARECOUNT, SUMTIMEEXECUTE , AVGTIMEEXECUTE ,  MAXTIMEEXECUTE ,'+
   'LASTTIMEEXECUTE, MAXTIME_PARAMS, CMP_NAME,ATTACHMENT_ID) '+
   'Values (?AP,?S,?E,?PC,?SU,?A,?M,?L,?MP,?C,?AT)'
 );
 with FAppStatInfo do
 try
  tr.StartTransaction;
  for i :=0  to Pred(ObjCount) do
  if (ForMaxExecTime=0) or (GetVarInt(ObjName(i),scMaxTimeExecute)>=ForMaxExecTime) then
  begin
   q.ParamByName('S' ).asString :=ObjName(i);
   q.ParamByName('AP').asString :=FApplicationID;
   q.ParamByName('E').asInteger:=GetVarInt(ObjName(i),scExecuteCount);
   q.ParamByName('PC').asInteger :=GetVarInt(ObjName(i),scPrepareCount);   
   q.ParamByName('SU').asInteger:=GetVarInt(ObjName(i),scSumTimeExecute);
   q.ParamByName('A').asInteger:=GetVarInt(ObjName(i),scAvgTimeExecute);
   q.ParamByName('M').asInteger:=GetVarInt(ObjName(i),scMaxTimeExecute);
   q.ParamByName('L').asInteger:=GetVarInt(ObjName(i),scLastTimeExecute);
   q.ParamByName('C').asString :=GetVarStr(ObjName(i),scLastQuery);
   q.ParamByName('AT').asInteger:=FDatabase.AttachmentID;
   s:= GetVarStrings(ObjName(i),scMaxTimeExecute).Text;
   if s<>'' then
    q.ParamByName('MP').asString:=s
   else
    q.ParamByName('MP').IsNull:=true;
   q.ExecQuery;
  end;
 finally
   FreeQueryForUse(q);
   tr.Commit;
 end
end;

function  TFIBSQLLogger.GetActiveStatistics: boolean;
begin
 Result:= FAppStatInfo.ActiveStatistics
end;

procedure TFIBSQLLogger.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  if (Operation=opRemove) then
   if AComponent=FDatabase then FDatabase:=nil;
  inherited Notification(AComponent,Operation);
end;

procedure TFIBSQLLogger.SaveStatisticsToFile(const FileName:string);
begin
 FAppStatInfo.SaveStatisticsToFile(FileName);
end;

procedure TFIBSQLLogger.SetActiveStatistics(Value: boolean);
begin
 FAppStatInfo.ActiveStatistics:=Value
end;

procedure TFIBSQLLogger.SetLogFileName(FileName: string);
begin
  FLogFileName:=FileName;
end;

procedure TFIBSQLLogger.SetDatabase(DB:TObject);
begin
 if Assigned(FDatabase) then
 begin
  FDatabase.RemoveEvent(OnDisconnect,detBeforeDisconnect);
  FDatabase.SQLLogger    :=nil;
  FDatabase.SQLStatisticsMaker :=nil
 end;
 if (DB=nil) or (DB is TFIBDatabase) then
  FDatabase:=TFIBDatabase(DB);
 if Assigned(FDatabase) then
 begin
  FDatabase.SQLStatisticsMaker:=FAppStatInfo;
//  FDatabase.SQLLogger:=FSQLLogger;
  FDatabase.AddEvent(OnDisconnect,detBeforeDisconnect);
 end;
 FExistStatTable:=eoUnknown;
end;

procedure TFIBSQLLogger.OnDisconnect(Sender:TObject);
begin
 FExistStatTable:=eoUnknown;
end;

procedure TFIBSQLLogger.SetStatParams (Value:TFIBStatisticsParams);
begin  
 with FAppStatInfo do
 begin
   SetLogParamsInc(scPrepareCount  ,  fspPrepareCount    in FStatisticsParams );
   SetLogParamsInc(scExecuteCount  ,  fspExecuteCount    in FStatisticsParams );
   SetLogParamsInc(scSumTimeExecute,  fspSumTimeExecute  in FStatisticsParams );
   SetLogParamsInc(scAvgTimeExecute,  fspAvgTimeExecute  in FStatisticsParams );
   SetLogParamsInc(scMaxTimeExecute,  fspMaxTimeExecute  in FStatisticsParams );
   SetLogParamsInc(scLastTimeExecute, fspLastTimeExecute in FStatisticsParams );
 end;
end;

procedure TFIBSQLLogger.SortStatisticsForPrint(const VarName: string;
  Ascending: boolean);
begin
 FAppStatInfo.SortStatisticsForPrint(VarName,Ascending)
end;

function TFIBSQLLogger.GetFS: boolean;
begin
  Result:=FForceSaveToFile
end;

procedure TFIBSQLLogger.SetFS(const Value: boolean);
begin
  FForceSaveToFile:=Value
end;

function TFIBSQLLogger.GetLogFlags: TLogFlags;
begin
 Result:= FLogFlags
end;

procedure TFIBSQLLogger.SetLogFlags(Value: TLogFlags);
begin
 FLogFlags:=Value
end;

function TFIBSQLLogger.GetActiveLogging: boolean;
begin
 Result:= FActiveLogging
end;

procedure TFIBSQLLogger.SetActiveLogging(const Value: boolean);
begin
 FActiveLogging:=Value
end;

function TFIBSQLLogger.GetLogFileName: string;
begin
 Result:=FLogFileName
end;

procedure TFIBSQLLogger.SaveLog;
begin
  if (csDesigning in ComponentState) then
    Exit;
  if (FStream = nil) then
  begin
    if not FileExists(FLogFileName) then
      FStream := TFileStream.Create(FLogFileName, fmCreate or fmShareDenyNone)
    else
      FStream := TFileStream.Create(FLogFileName, fmOpenWrite or fmShareDenyNone);
  end;
  try
   FStream.Seek(0, soFromEnd);
   FLogList.SaveToStream(FStream);
   FLogList.Clear;
  finally
   FStream.Free;
   FStream := nil;
  end
end;


function TFIBSQLLogger.GetStatMaker: ISQLStatMaker;
begin
 result:=FAppStatInfo
end;

procedure TFIBSQLLogger.WriteData(const ObjectName, OperationName,
  EventText: String; DataType: TLogFlag);
var
   Rows:string;
   EventDateTime: TDateTime;
   WriteToLog: Boolean;
begin
 if (csDesigning in ComponentState) then
    Exit;

 if ActiveLogging and (DataType in FLogFlags) then
 begin
   EventDateTime:=Now;
   Rows:=  'Application:'+FApplicationID+CLRF+
   ' Object: "'+ObjectName+'"'+CLRF+
   ' Operation:'+OperationName+'>> Time '+FormatDateTime('C.zzz',EventDateTime)+CLRF+EventText+CLRF;
   WriteToLog:=True;
   if Assigned(FOnLogEvent) then
    FOnLogEvent(ObjectName,OperationName,EventText,DataType,FApplicationID,EventDateTime,WriteToLog);
  if WriteToLog then
  begin
   FLogList.Add(Rows);
   if FForceSaveToFile then
    SaveLog;
  end;
 end;
end;

function TFIBSQLLogger.GetInstance: TObject;
begin
  Result:=Self
end;

function TFIBSQLLogger.GetLogger: ISQLLogger;
begin
  Result:=Self
end;

end.
