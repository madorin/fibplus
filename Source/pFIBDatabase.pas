unit pFIBDatabase deprecated 'Use FIBDatabase (TFIBDatabase, TFIBTransaction)';

interface

uses
  FIBDatabase;

type
  TpFIBDatabase = FIBDatabase.TFIBDatabase deprecated 'Use TFIBDatabase';
  TpFIBTransaction = FIBDatabase.TFIBTransaction deprecated 'Use TFIBTransaction';
  TFIBLoginEvent = FIBDatabase.TFIBLoginEvent;
  TpFIBAcceptCacheSchema = FIBDatabase.TFIBAcceptCacheSchemaEvent deprecated 'Use TFIBAcceptCacheSchemaEvent';
  TpFIBDBEventType = FIBDatabase.TFIBDatabaseEventType deprecated 'Use TFIBDatabaseEventType';
  TpFIBTrEventType = FIBDatabase.TFIBTransactionEventType deprecated 'Use TFIBTransactionEventType';
  TOnLostConnectActions = FIBDatabase.TOnLostConnectActions;
  TFIBLostConnectEvent = FIBDatabase.TFIBLostConnectEvent;
  TFIBRestoreConnectEvent = FIBDatabase.TFIBRestoreConnectEvent;
  TOnSQLExecute = FIBDatabase.TOnSQLExecute;

const
  laTerminateApp = FIBDatabase.laTerminateApp;
  laCloseConnect = FIBDatabase.laCloseConnect;
  laIgnore = FIBDatabase.laIgnore;
  laWaitRestore = FIBDatabase.laWaitRestore;

procedure WriteDBParamsToAlias(Database: TFIBDatabase); deprecated 'Use FIBDatabase.WriteDBParamsToAlias';

implementation

uses
  Classes;

procedure WriteDBParamsToAlias(Database: TFIBDatabase);
begin
  FIBDatabase.WriteDBParamsToAlias(Database);
end;

initialization
  RegisterClassAlias(TFIBDatabase, 'TpFIBDatabase');
  RegisterClassAlias(TFIBTransaction, 'TpFIBTransaction');

end.
