//---------------------------------------------------------------------------

#include <basepch.h>
#pragma hdrstop





USEFORMNS("pFIBDBEdit.pas", Pfibdbedit, DBEditForm);
USEFORMNS("pFIBTrEdit.pas", Pfibtredit, frmTransEdit);
USEFORMNS("fraDSSQLEdit.pas", Fradssqledit, fDSSQLEdit); /* TFrame: File Type */
USEFORMNS("fraConditionsEdit.pas", Fraconditionsedit, fraEdConditions); /* TFrame: File Type */
USEFORMNS("fraSQLEdit.pas", Frasqledit, fSQLEdit); /* TFrame: File Type */
USEFORMNS("pFIBConditionsEdit.pas", Pfibconditionsedit, frmEditCheckStrings);
USEFORMNS("pFIBAutoUpdEditor.pas", Pfibautoupdeditor, pFIBAutoUpdateOptionForm);
USEFORMNS("uFIBScriptForm.pas", Ufibscriptform, frmScript);
USEFORMNS("EdDataSetInfo.pas", Eddatasetinfo, frmEdDataSetInfo);
USEFORMNS("fraAutoUpdEditor.pas", Fraautoupdeditor, fAutoUpdateOptionForm); /* TFrame: File Type */
USEFORMNS("FIBSQLEditor.pas", Fibsqleditor, frmSQLEdit);
USEFORMNS("EdFieldInfo.pas", Edfieldinfo, frmFields);
USEFORMNS("EdErrorInfo.pas", Ederrorinfo, frmErrors);
USEFORMNS("EdParamToFields.pas", Edparamtofields, frmEdParamToFields);
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
