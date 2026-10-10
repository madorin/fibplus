unit pFIBDataSet;

{$MESSAGE WARN 'Unit pFIBDataSet is deprecated, use FIBDataSet (TFIBDataSet)'}

interface

uses
  DB, FIBDataSet;

type
  TpFIBDataSet = TFIBDataSet deprecated 'Use TFIBDataSet';
  TpSQLKind = FIBDataSet.TFIBSQLKind deprecated 'Use TFIBSQLKind';
  TLockStatus = FIBDataSet.TLockStatus;
  TLockErrorEvent = FIBDataSet.TLockErrorEvent;
  TCachRefreshKind = FIBDataSet.TCachRefreshKind;
  TOnGetSQLTextProc = FIBDataSet.TOnGetSQLTextProc;
  TIncludeFieldsToSQL = FIBDataSet.TIncludeFieldsToSQL;

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
