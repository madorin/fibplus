//---------------------------------------------------------------------------

#include <basepch.h>
#pragma hdrstop
USEFORMNS("fraAutoUpdEditor.pas", Fraautoupdeditor, fAutoUpdateOptionForm); /* TFrame: File Type */
USEFORMNS("fraDSSQLEdit.pas", Fradssqledit, fDSSQLEdit); /* TFrame: File Type */
USEFORMNS("pFIBAutoUpdEditor.pas", Pfibautoupdeditor, pFIBAutoUpdateOptionForm);
USEFORMNS("fraConditionsEdit.pas", Fraconditionsedit, fraEdConditions); /* TFrame: File Type */
USEFORMNS("pFIBDBEdit.pas", Pfibdbedit, DBEditForm);
USEFORMNS("FIBSQLEditor.pas", Fibsqleditor, frmSQLEdit);
USEFORMNS("fraSQLEdit.pas", Frasqledit, fSQLEdit); /* TFrame: File Type */
USEFORMNS("EdFieldInfo.pas", Edfieldinfo, frmFields);
USEFORMNS("pFIBTrEdit.pas", Pfibtredit, frmTransEdit);
USEFORMNS("EdParamToFields.pas", Edparamtofields, frmEdParamToFields);
USEFORMNS("EdErrorInfo.pas", Ederrorinfo, frmErrors);
USEFORMNS("EdDataSetInfo.pas", Eddatasetinfo, frmEdDataSetInfo);
USEFORMNS("pFIBConditionsEdit.pas", Pfibconditionsedit, frmEditCheckStrings);
USEFORMNS("uFIBScriptForm.pas", Ufibscriptform, frmScript);
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
