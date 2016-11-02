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
{    Written by Serge Buzadzhy (buzz@devrace.com)               }
{                                                               }
{ ------------------------------------------------------------- }
{    FIBPlus home page: http://www.fibplus.com/                 }
{    FIBPlus support  : http://www.devrace.com/support/         }
{ ------------------------------------------------------------- }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}


unit RegFIBPlus;

interface
{$I FIBPlus.inc}
uses

  Classes,Sysutils,DB,
  pFIBDataSet,pFIBDatabase,
  pFIBQuery, DSContainer,pFIBSQLLog,SIBFIBEA,
  pFIBMetadata,pFIBDataRefresh,pFIBExports,
  {$IFNDEF NO_MONITOR}
   FIBSQLMonitor,
  {$ENDIF}
  pFIBErrorHandler, pFIBStoredProc,  pFIBProps
  {$IFDEF  INC_SERVICE_SUPPORT}
     ,IB_Services
  {$ENDIF}
  {$IFDEF IBINSTALL_SUPPORT}
  , IB_Install
  {$ENDIF}
;





procedure Register;

implementation

uses //DsgnIntf,
{$IFNDEF NO_REGISTRY}
 RegUtils,
{$ENDIF}
FIBDataSet,FIBQuery,FIBDatabase,SqlTxtRtns,StrUtil,
 pFIBDataInfo, pFIBScripter;

const FIBPalette='FIBPlus';

{$R fibplus.dcr}

procedure Register;
begin

//  RegisterComponents(FIBPalette, [TComponent1]);
  RegisterComponents(FIBPalette,
   [TpFIBDatabase,TpFIBDataSet,TpFIBTransaction,TpFIBQuery,TpFIBStoredProc,
    TpFIBUpdateObject,    TDataSetsContainer,
    TpFibErrorHandler,TpFIBScripter,TpFIBDBSchemaExtract, TpFIBTableChangesReader
   ]
  );

  RegisterComponents(FIBPalette, [TFIBSQLLogger  ,TSIBfibEventAlerter]);

 {$IFNDEF NO_MONITOR}
  RegisterComponents(FIBPalette, [TFIBSQLMonitor]);
 {$ENDIF}

   RegisterFields([TFIBStringField,TFIBIntegerField,TFIBSmallIntField,
     TFIBFloatField,TFIBBCDField,TFIBBooleanField,TFIBDateField,TFIBTimeField,TFIBDateTimeField,
     TFIBWideStringField]
   );

  {$IFDEF  INC_SERVICE_SUPPORT}
  RegisterComponents('FIBPlusServices', [
       TpFIBServerProperties,
       TpFIBConfigService,
       TpFIBLicensingService,
       TpFIBLogService,
       TpFIBStatisticalService,
       TpFIBBackupService,
       TpFIBRestoreService,
       TpFIBValidationService,
       TpFIBSecurityService,
       TpFIBNBackupService,
       TpFIBNRestoreService
    ]);
   {$ENDIF}
  {$IFDEF  IBINSTALL_SUPPORT}
    RegisterComponents('FIBPlusServices', [ TpFIBInstall,       TpFIBUnInstall ]);
  {$ENDIF}
end;

end.
