unit pFIBSQLLog deprecated 'Use FIBSQLLog (TFIBSQLLogger)';

interface

uses
  FIBSQLLog;

type
  TpFIBStatistics = FIBSQLLog.TFIBSQLLogger deprecated 'Use TFIBSQLLogger';
  TFIBStatisticsParam = FIBSQLLog.TFIBStatisticsParam;
  TFIBStatisticsParams = FIBSQLLog.TFIBStatisticsParams;
  TFIBSQLLogger = FIBSQLLog.TFIBSQLLogger;
  TSQLLogEvent = FIBSQLLog.TFIBSQLLogEvent;

const
  fspExecuteCount = FIBSQLLog.fspExecuteCount;
  fspPrepareCount = FIBSQLLog.fspPrepareCount;
  fspSumTimeExecute = FIBSQLLog.fspSumTimeExecute;
  fspAvgTimeExecute = FIBSQLLog.fspAvgTimeExecute;
  fspMaxTimeExecute = FIBSQLLog.fspMaxTimeExecute;
  fspLastTimeExecute = FIBSQLLog.fspLastTimeExecute;

implementation

end.
