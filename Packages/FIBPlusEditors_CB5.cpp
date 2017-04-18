//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop
USERES("FIBPlusEditors_CB5.res");
USEPACKAGE("vcl50.bpi");
USEPACKAGE("Vcldb50.bpi");
USEPACKAGE("FIBPlus_CB5.bpi");
USEPACKAGE("dsnide50.bpi");
USEFORMNS("EdErrorInfo.pas", Ederrorinfo, frmErrors);
USEFORMNS("EdFieldInfo.pas", Edfieldinfo, frmFields);
USEUNIT("RegFIBPlusEditors.pas");
USEFORMNS("fraSQLEdit.pas", Frasqledit, fSQLEdit); /* TFrame: File Type */
USEFORMNS("fraConditionsEdit.pas", Fraconditionsedit, fraEdConditions); /* TFrame: File Type */
USEFORMNS("fraAutoUpdEditor.pas", Fraautoupdeditor, fAutoUpdateOptionForm); /* TFrame: File Type */
USEFORMNS("fraDSSQLEdit.pas", Fradssqledit, fDSSQLEdit); /* TFrame: File Type */
USEFORMNS("EdParamToFields.pas", Edparamtofields, frmEdParamToFields);
USEFORMNS("FIBSQLEditor.pas", Fibsqleditor, frmSQLEdit);
USEFORMNS("EdDataSetInfo.pas", Eddatasetinfo, frmEdDataSetInfo);
USEFORMNS("pFIBAutoUpdEditor.pas", Pfibautoupdeditor, pFIBAutoUpdateOptionForm);
USEFORMNS("pFIBConditionsEdit.pas", Pfibconditionsedit, frmEditCheckStrings);
USEFORMNS("pFIBDataSetOptions.pas", Pfibdatasetoptions, FPDataSetOptionsForm);
USEFORMNS("pFIBDBEdit.pas", Pfibdbedit, DBEditForm);
USEFORMNS("pFIBTrEdit.pas", Pfibtredit, frmTransEdit);
USEUNIT("ToCodeEditor.pas");
USEUNIT("ToCodeEditorIntfs.pas");
USEFORMNS("FIBDataSQLEditor.pas", Fibdatasqleditor, frmDstSQLedit);
USEUNIT("IBSQLSyn.pas");
USEUNIT("RegistryUtils.pas");
USEUNIT("RegSynEditAlt.pas");
USEUNIT("RTTIRoutines.pas");
USEUNIT("UnitSyntaxMemo.pas");
USERES("UnitSyntaxMemo.dcr");
USEUNIT("pFIBEditorsConsts.pas");
USEUNIT("pFIBComponentEditors.pas");
USEUNIT("pFIBRepositoryOperations.pas");
USEUNIT("fibCheckSingleLicenseClass.pas");
USEUNIT("fibAthlInstanceCounter.pas");
USEFORMNS("uFIBScriptForm.pas", Ufibscriptform, frmScript);
USEUNIT("FIBToolsConsts.pas");
USEUNIT("FindCmp.pas");
USEUNIT("pfibdsgnviewsqls.pas");
USEFORMNS("pFIBPreferences.pas", Pfibpreferences, frmFIBPreferences);
USEUNIT("RegFIBPlusUtils.pas");
USEFORMNS("uFrmSearchResult.pas", Ufrmsearchresult, frmCompSearchResult);
USEPACKAGE("Vclx50.bpi");
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
