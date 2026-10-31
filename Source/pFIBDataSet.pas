unit pFIBDataSet deprecated 'Use FIBDataSet (TFIBDataSet)';

interface

uses
  DB, FIBDataSet;

type
  TpFIBDataSet = TFIBDataSet deprecated 'Use TFIBDataSet';
  TpSQLKind = FIBDataSet.TFIBSQLKind deprecated 'Use TFIBSQLKind';
  TLockStatus = FIBDataSet.TFIBLockStatus;
  TLockErrorEvent = FIBDataSet.TFIBLockErrorEvent;
  TCachRefreshKind = FIBDataSet.TFIBCacheRefreshKind;
  TOnGetSQLTextProc = FIBDataSet.TFIBGetSQLTextEvent;
  TIncludeFieldsToSQL = FIBDataSet.TFIBIncludeFieldsToSQL;

const
  lsSuccess = FIBDataSet.lsSuccess;
  lsDeadLock = FIBDataSet.lsDeadLock;
  lsNotExist = FIBDataSet.lsNotExist;
  lsMultiply = FIBDataSet.lsMultiply;
  lsUnknownError = FIBDataSet.lsUnknownError;
  frkEdit = FIBDataSet.frkEdit;
  frkInsert = FIBDataSet.frkInsert;
  ifsAllFields = FIBDataSet.ifsAllFields;
  ifsNoBlob = FIBDataSet.ifsNoBlob;
  ifsOnlyBlob = FIBDataSet.ifsOnlyBlob;

function FieldInArray(Field: TField; Arr: array of const): Boolean; deprecated 'Use FIBDataSet.FieldInArray';

implementation

uses
  Classes;

function FieldInArray(Field: TField; Arr: array of const): Boolean;
begin
  Result := FIBDataSet.FieldInArray(Field, Arr);
end;

initialization
  RegisterClassAlias(TFIBDataSet, 'TpFIBDataSet');

end.
