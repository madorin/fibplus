//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop
USERES("FIBPlus_CB5.res");
USEPACKAGE("vcl50.bpi");
USEUNIT("RegFIBPlus.pas");
USEPACKAGE("vcldb50.bpi");
USERES("FIBPlus.dcr");
USEUNIT("VariantRtn.pas");
USEUNIT("DSContainer.pas");
USEUNIT("FIB.pas");
USEUNIT("FIBConsts.pas");
USEUNIT("FIBDataBase.pas");
USEUNIT("FIBDataSet.pas");
USEUNIT("FIBMiscellaneous.pas");
USEUNIT("FIBQuery.pas");
USEUNIT("FIBSQLMonitor.pas");
USEUNIT("ib_errorcodes.pas");
USEUNIT("ib_externals.pas");
USEUNIT("IB_Install.pas");
USEUNIT("IB_InstallHeader.pas");
USEUNIT("IB_Intf.pas");
USEUNIT("IB_Services.pas");
USEUNIT("ibase.pas");
USEUNIT("pFIBArray.pas");
USEUNIT("pFIBCacheQueries.pas");
USEUNIT("pFIBDatabase.pas");
USEUNIT("pFIBDataInfo.pas");
USEUNIT("pFIBDataSet.pas");
USEUNIT("pFIBErrorHandler.pas");
USEUNIT("pFIBEventLists.pas");
USEUNIT("pFIBFieldsDescr.pas");
USEUNIT("pFIBProps.pas");
USEUNIT("pFIBQuery.pas");
USEUNIT("pFIBStoredProc.pas");
USEUNIT("RegUtils.pas");
USEUNIT("SQLTxtRtns.pas");
USEUNIT("StdFuncs.pas");
USEUNIT("StrUtil.pas");
USEUNIT("pFIBScripter.pas");
USEUNIT("pFIBExports.pas");
USEUNIT("pFIBDataRefresh.pas");
USEUNIT("pFIBMetaData.pas");
USEUNIT("SIBFIBEA.PAS");
USEUNIT("pFIBSQLLog.pas");
USEUNIT("FIBSafeTimer.pas");
USEFORMNS("FIBDBLoginDlg.pas", Fibdblogindlg, frmFIBDBLoginDlg);
USEUNIT("FIBMDTInterface.pas");
USEUNIT("pFIBInterfaces.pas");
USEUNIT("IBBlobFilter.pas");
USEUNIT("FIBCloneComponents.pas");
USEUNIT("pFIBLists.pas");
USEUNIT("DBParsers.pas");
USEUNIT("FIBCacheManage.pas");
USEUNIT("SIBGlobals.pas");
USEUNIT("SIBAPI.pas");
USEUNIT("SIBEABase.pas");
USEUNIT("pTestInfo.pas");
USEUNIT("pFIBClientDataSet.pas");
USEPACKAGE("Vclmid50.bpi");
//---------------------------------------------------------------------------
#pragma package(smart_init)
//---------------------------------------------------------------------------

//   Package source.
//---------------------------------------------------------------------------

#pragma argsused
int WINAPI DllEntryPoint(HINSTANCE hinst, unsigned long reason, void*)
{
   return 1;
}
//---------------------------------------------------------------------------


