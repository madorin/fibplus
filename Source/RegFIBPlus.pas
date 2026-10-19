{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ InterBase databases                                           }
{                                                               }
{    FIBPlus is based in part on the product                    }
{    Free IB Components, written by Gregory H. Deatz for        }
{    Hoagland, Longo, Moran, Dunst & Doukas Company.            }
{    mailto:gdeatz@hlmdd.com                                    }
{                                                               }
{    Copyright (c) 1998-2007 Devrace Ltd.                       }
{    Written by Serge Buzadzhy                                  }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit RegFIBPlus;

interface

{$I FIBPlus.inc}

uses
  Classes, Sysutils, DB, DSContainer,
  FIBSQLLog, FIBEventAlerter, FIBMetadata, FIBDataRefresh, FIBExports,
{$IFNDEF NO_MONITOR} FIBSQLMonitor, {$ENDIF} FIBErrorHandler,
  FIBStoredProc, FIBProps, FIBClientDataSet {$IFDEF INC_SERVICE_SUPPORT},
  FIBServices {$ENDIF};

procedure Register;

implementation

uses
{$IFNDEF NO_REGISTRY} RegUtils, {$ENDIF} FIBDataSet, FIBQuery, FIBDatabase,
  SqlTxtRtns, StrUtil, FIBDataInfo, FIBScripter;

const
  pnFIBPlus         = 'FIBPlus';
  pnFIBPlusServices = 'FIBPlusServices';

{$R RegFIBPlus.dcr}

procedure Register;
begin

  RegisterClasses([TFIBIntegerField, TFIBSmallIntField, TFIBLargeIntField,
    TFIBBCDField, TFIBFMTBCDField, TFIBFloatField, TFIBBooleanField,
    TFIBDateTimeField, TFIBDateField, TFIBTimeField, TFIBGuidField,
    TFIBStringField, TFIBWideStringField, TFIBBlobField, TFIBMemoField
{$IFDEF SUPPORT_ARRAY_FIELD}, TFIBArrayField{$ENDIF}, TFIBClientBCDField]);

  RegisterFields([TFIBStringField, TFIBIntegerField, TFIBSmallIntField,
    TFIBFloatField, TFIBBCDField, TFIBFMTBCDField, TFIBBooleanField,
    TFIBDateField, TFIBTimeField, TFIBDateTimeField, TFIBWideStringField]);

  RegisterComponents(pnFIBPlus, [TFIBDatabase, TFIBDataSet, TFIBTransaction,
    TFIBQuery, TFIBStoredProc, TFIBUpdateObject, TDataSetsContainer,
    TFIBErrorHandler, TFIBScripter, TFIBDBSchemaExtract, TFIBTableChangesReader, TFIBSQLLogger, TFIBEventAlerter,
    TFIBClientDataSet, TFIBDataSetProvider
{$IFNDEF NO_MONITOR}, TFIBSQLMonitor{$ENDIF}]);

{$IFDEF INC_SERVICE_SUPPORT}
  RegisterComponents(pnFIBPlusServices, [TFIBServerProperties,
    TFIBConfigService, TFIBLogService,
    TFIBStatisticalService, TFIBBackupService, TFIBRestoreService,
    TFIBValidationService, TFIBSecurityService, TFIBNBackupService, TFIBNRestoreService]);
{$ENDIF}
end;

end.
