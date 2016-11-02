//---------------------------------------------------------------------------

#include <basepch.h>
#pragma hdrstop
USEFORMNS("pFIBConditionsEdit.pas", Pfibconditionsedit, frmEditCheckStrings);
USEFORMNS("EdErrorInfo.pas", Ederrorinfo, frmErrors);
USEFORMNS("EdDataSetInfo.pas", Eddatasetinfo, frmEdDataSetInfo);
USEFORMNS("uFIBScriptForm.pas", Ufibscriptform, frmScript);
USEFORMNS("EdParamToFields.pas", Edparamtofields, frmEdParamToFields);
USEFORMNS("fraDSSQLEdit.pas", Fradssqledit, fDSSQLEdit); /* TFrame: File Type */
USEFORMNS("pFIBAutoUpdEditor.pas", Pfibautoupdeditor, pFIBAutoUpdateOptionForm);
USEFORMNS("fraConditionsEdit.pas", Fraconditionsedit, fraEdConditions); /* TFrame: File Type */
USEFORMNS("fraAutoUpdEditor.pas", Fraautoupdeditor, fAutoUpdateOptionForm); /* TFrame: File Type */
USEFORMNS("fraSQLEdit.pas", Frasqledit, fSQLEdit); /* TFrame: File Type */
USEFORMNS("EdFieldInfo.pas", Edfieldinfo, frmFields);
USEFORMNS("pFIBTrEdit.pas", Pfibtredit, frmTransEdit);
USEFORMNS("pFIBDBEdit.pas", Pfibdbedit, DBEditForm);
USEFORMNS("FIBSQLEditor.pas", Fibsqleditor, frmSQLEdit);
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
