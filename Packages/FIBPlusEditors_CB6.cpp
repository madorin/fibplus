//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop
USEFORMNS("pFIBDBEdit.pas", Pfibdbedit, DBEditForm);
USEFORMNS("pFIBTrEdit.pas", Pfibtredit, frmTransEdit);
USEFORMNS("fraSQLEdit.pas", Frasqledit, fSQLEdit); /* TFrame: File Type */
USEFORMNS("fraAutoUpdEditor.pas", Fraautoupdeditor, fAutoUpdateOptionForm); /* TFrame: File Type */
USEFORMNS("fraConditionsEdit.pas", Fraconditionsedit, fraEdConditions); /* TFrame: File Type */
USEFORMNS("fraDSSQLEdit.pas", Fradssqledit, fDSSQLEdit); /* TFrame: File Type */
USEFORMNS("FIBDataSQLEditor.pas", Fibdatasqleditor, frmDstSQLedit);
USEFORMNS("FIBSQLEditor.pas", Fibsqleditor, frmSQLEdit);
USEFORMNS("pFIBDataSetOptions.pas", Pfibdatasetoptions, FPDataSetOptionsForm);
USEFORMNS("EdErrorInfo.pas", Ederrorinfo, frmErrors);
USEFORMNS("EdFieldInfo.pas", Edfieldinfo, frmFields);
USEFORMNS("EdParamToFields.pas", Edparamtofields, frmEdParamToFields);
USEFORMNS("pFIBAutoUpdEditor.pas", Pfibautoupdeditor, pFIBAutoUpdateOptionForm);
USEFORMNS("pFIBConditionsEdit.pas", Pfibconditionsedit, frmEditCheckStrings);
USEFORMNS("EdDataSetInfo.pas", Eddatasetinfo, frmEdDataSetInfo);
USEFORMNS("uFIBScriptForm.pas", Ufibscriptform, frmScript);
USEFORMNS("pfibdsgnviewsqls.pas", Pfibdsgnviewsqls, frmSaveSQLs);
USEFORMNS("pFIBPreferences.pas", Pfibpreferences, frmFIBPreferences);
USEFORMNS("uFrmSearchResult.pas", Ufrmsearchresult, frmCompSearchResult);
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
