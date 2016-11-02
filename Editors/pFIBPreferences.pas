unit pFIBPreferences;

interface

{$I ..\FIBPlUS.INC}
uses
  Windows, Messages, SysUtils, Classes,

   {$IFDEF D_XE2}
  Vcl.Graphics, Vcl.Controls, Vcl.Forms,  Vcl.Dialogs, Vcl.ComCtrls, Vcl.ExtCtrls,
  Vcl.StdCtrls,
  {$ELSE}
  Graphics, Controls, Forms,  Dialogs, ComCtrls, ExtCtrls, StdCtrls,
  {$ENDIF}
  pFIBProps,uFIBEditorForm
  {$IFDEF D6+}
   ,Variants
  {$ENDIF}
  ;

type
  TfrmFIBPreferences = class(TFIBEditorCustomForm)
    z: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet4: TTabSheet;
    GroupBox1: TGroupBox;
    chRequiredFields: TCheckBox;
    chSetReadOnlyFields: TCheckBox;
    chImportDefaultValues: TCheckBox;
    chUseBooleanField: TCheckBox;
    chApplyRepositary: TCheckBox;
    chGetOrderInfo: TCheckBox;
    chAskRecordCount: TCheckBox;
    GroupBox2: TGroupBox;
    chTrimCharFields: TCheckBox;
    chRefreshAfterPost: TCheckBox;
    chRefreshDeletedRecord: TCheckBox;
    chStartTransaction: TCheckBox;
    chAutoFormatFields: TCheckBox;
    chProtectedEdit: TCheckBox;
    chKeepSorting: TCheckBox;
    chPersistentSorting: TCheckBox;
    GroupBox3: TGroupBox;
    chForceOpen: TCheckBox;
    chForceMasterRefresh: TCheckBox;
    chWaitEndMasterScroll: TCheckBox;
    EdPrefixGen: TEdit;
    EdSufixGen: TEdit;
    Label4: TLabel;
    Label5: TLabel;
    Button1: TButton;
    Button2: TButton;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    chStoreConnected: TCheckBox;
    chSynchronizeTime: TCheckBox;
    chUpperOldNames: TCheckBox;
    chUseLoginPrompt: TCheckBox;
    Label6: TLabel;
    CharSetC: TComboBox;
    Label8: TLabel;
    DialectC: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    cmbTimeOutAction: TComboBox;
    edTimeout: TEdit;
    cmbTPBMode: TComboBox;
    ChGo1: TCheckBox;
    ChParamCheck: TCheckBox;
    chAutoStartTransaction: TCheckBox;
    chAutoCommitTransaction: TCheckBox;
    chUseSQLINT64ToBCD: TCheckBox;
    chVisibleRecno: TCheckBox;
    GroupBox4: TGroupBox;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    edDateFormat: TEdit;
    edTimeFormat: TEdit;
    edDisplayNumFormat: TEdit;
    edEditNumFormat: TEdit;
    chIgnoreMasterClose: TCheckBox;
    chUseGuidField: TCheckBox;
    chFetchAll: TCheckBox;
    chEmptyStrToNull: TCheckBox;
    chCloseDsgnConnect: TCheckBox;
    chCacheCalcFields: TCheckBox;
    edDateTimeDisplay: TEdit;
    Label7: TLabel;
    chUseLargeIntField: TCheckBox;
    chUseSelectForLock: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure chCloseDsgnConnectClick(Sender: TObject);
  private
   procedure LoadPreferences;
   procedure SavePreferences;
   procedure SaveToReg;
  public
    { Public declarations }
  end;

var
  frmFIBPreferences: TfrmFIBPreferences;
  bCloseDesignConnect:boolean;

procedure ShowFIBPreferences;


implementation

{$R *.DFM}
uses RegUtils, FIBToolsConsts;

procedure ShowFIBPreferences;
begin
if frmFIBPreferences =nil then
 frmFIBPreferences:=TfrmFIBPreferences.Create(Application);
with frmFIBPreferences do begin
 try
  LoadPreferences;
  if ShowModal=mrOk then begin
   SavePreferences   ;
   SaveToReg
  end;
 finally
  Free;
  frmFIBPreferences:=nil
 end;
end;

end;

{ TfrmFIBPreferences }

procedure TfrmFIBPreferences.LoadPreferences;
begin
 chAskRecordCount.Checked:=
  psAskRecordCount in DefaultPrepareOptions;
 chGetOrderInfo.Checked:=
  psGetOrderInfo in DefaultPrepareOptions;
 chApplyRepositary.Checked:=
  psApplyRepositary in DefaultPrepareOptions;
 chUseBooleanField.Checked:=
  psUseBooleanField in DefaultPrepareOptions;
 chUseGuidField.Checked:=
  psUseGuidField in DefaultPrepareOptions;
 chUseLargeIntField.Checked:=
  psUseLargeIntField in DefaultPrepareOptions;

 chUseSQLINT64ToBCD.Checked:=
  psSQLINT64ToBCD in DefaultPrepareOptions;
 chImportDefaultValues.Checked:=
  pfImportDefaultValues in DefaultPrepareOptions;
 chSetReadOnlyFields.Checked:=
  pfSetReadOnlyFields in DefaultPrepareOptions;
 chRequiredFields.Checked:=
  pfSetRequiredFields in DefaultPrepareOptions;
 chEmptyStrToNull.Checked:=
  psSetEmptyStrToNull in DefaultPrepareOptions;

  chPersistentSorting   .Checked:=
   poPersistentSorting    in DefaultOptions;
  chKeepSorting         .Checked:=
   poKeepSorting          in DefaultOptions;
  chProtectedEdit       .Checked:=
   poProtectedEdit        in DefaultOptions;
  chAutoFormatFields    .Checked:=
   poAutoFormatFields     in DefaultOptions;
  chStartTransaction    .Checked:=
   poStartTransaction     in DefaultOptions;
  chRefreshDeletedRecord.Checked:=
   poRefreshDeletedRecord in DefaultOptions;
  chRefreshAfterPost    .Checked:=
   poRefreshAfterPost     in DefaultOptions;
  chTrimCharFields      .Checked:=
   poTrimCharFields       in DefaultOptions;
  chVisibleRecno        .Checked:=
   poVisibleRecno in DefaultOptions;
  chFetchAll            .Checked:=
   poFetchAll in DefaultOptions;
  chCacheCalcFields     .Checked:=
   poCacheCalcFields in DefaultOptions;
  chUseSelectForLock    .Checked:=
   poUseSelectForLock in DefaultOptions;

  chWaitEndMasterScroll.Checked:=
   dcWaitEndMasterScroll in DefaultDetailConditions;
  chForceMasterRefresh.Checked:=
   dcForceMasterRefresh in DefaultDetailConditions;
  chForceOpen.Checked:=
   dcForceOpen in DefaultDetailConditions;
  chIgnoreMasterClose.Checked:=
   dcIgnoreMasterClose in DefaultDetailConditions;

   DialectC.ItemIndex :=DefSQLDialect-1;
   CharSetC.Text      :=DefCharSet;
   chUseLoginPrompt.Checked  :=DefUseLoginPrompt;
   chUpperOldNames.Checked   :=DefUpperOldNames;
   chSynchronizeTime.Checked :=DefSynchronizeTime;
   chStoreConnected.Checked  :=DefStoreConnected;

   cmbTimeOutAction.ItemIndex:=Ord(DefTimeOutAction);
   edTimeout.Text            :=IntToStr(DefTimeOut);
   cmbTPBMode.ItemIndex      :=Ord(DefTPBMode);
   ChGo1.Checked             :=DefGoToFirstRecordOnExecute;
   ChParamCheck.Checked      :=DefParamCheck;


   chAutoCommitTransaction.Checked:=qoAutoCommit       in DefQueryOptions;
   chAutoStartTransaction .Checked:=qoStartTransaction in DefQueryOptions;
   EdPrefixGen.Text   := DefPrefixGenName;
   EdSufixGen .Text   := DefSufixGenName;
   edDateFormat.Text  := dDefDateFormat;
   edTimeFormat.Text  := dDefTimeFormat;
   edDisplayNumFormat.Text := dDefDisplayFormatNum;
   edDateTimeDisplay.Text := dDefDateTimeFormat;
   edEditNumFormat.Text    := dDefEditFormatNum   ;
   chCloseDsgnConnect.Checked:=bCloseDesignConnect
end;

procedure TfrmFIBPreferences.SavePreferences;
begin
 if chAskRecordCount.Checked then
  Include (DefaultPrepareOptions,psAskRecordCount)
 else
  Exclude (DefaultPrepareOptions,psAskRecordCount);

 if chGetOrderInfo.Checked then
  Include (DefaultPrepareOptions,psGetOrderInfo)
 else
  Exclude (DefaultPrepareOptions,psGetOrderInfo);

 if chApplyRepositary.Checked then
  Include (DefaultPrepareOptions,psApplyRepositary)
 else
  Exclude (DefaultPrepareOptions,psApplyRepositary);

 if chUseBooleanField.Checked then
  Include (DefaultPrepareOptions,psUseBooleanField)
 else
  Exclude (DefaultPrepareOptions,psUseBooleanField);

 if chUseGuidField.Checked then
  Include (DefaultPrepareOptions,psUseGuidField)
 else
  Exclude (DefaultPrepareOptions,psUseGuidField);

 if chUseLargeIntField.Checked then
  Include (DefaultPrepareOptions,psUseLargeIntField)
 else
  Exclude (DefaultPrepareOptions,psUseLargeIntField);



 if chUseSQLINT64ToBCD.Checked then
  Include (DefaultPrepareOptions,psSQLINT64ToBCD)
 else
  Exclude (DefaultPrepareOptions,psSQLINT64ToBCD);

 if chImportDefaultValues.Checked then
  Include (DefaultPrepareOptions,pfImportDefaultValues)
 else
  Exclude (DefaultPrepareOptions,pfImportDefaultValues);
 if chSetReadOnlyFields.Checked then
  Include (DefaultPrepareOptions,pfSetReadOnlyFields)
 else
  Exclude (DefaultPrepareOptions,pfSetReadOnlyFields);
 if chRequiredFields.Checked then
  Include (DefaultPrepareOptions,pfSetRequiredFields)
 else
  Exclude (DefaultPrepareOptions,pfSetRequiredFields);

 if chEmptyStrToNull.Checked then
  Include (DefaultPrepareOptions,psSetEmptyStrToNull)
 else
  Exclude (DefaultPrepareOptions,psSetEmptyStrToNull);

  if chPersistentSorting   .Checked  then
   Include (DefaultOptions, poPersistentSorting)
  else
   Exclude (DefaultOptions, poPersistentSorting)     ;
  if chKeepSorting         .Checked  then
   Include (DefaultOptions , poKeepSorting)
  else
   Exclude (DefaultOptions, poKeepSorting)           ;
  if chProtectedEdit       .Checked  then
   Include (DefaultOptions, poProtectedEdit)
  else
   Exclude (DefaultOptions, poProtectedEdit);
  if chStartTransaction    .Checked  then
   Include (DefaultOptions , poStartTransaction)
  else
   Exclude (DefaultOptions , poStartTransaction)     ;

  if chAutoFormatFields    .Checked  then
   Include (DefaultOptions, poAutoFormatFields)
  else
   Exclude (DefaultOptions, poAutoFormatFields)      ;
  if chRefreshDeletedRecord.Checked  then
   Include (DefaultOptions , poRefreshDeletedRecord)
  else
   Exclude (DefaultOptions, poRefreshDeletedRecord);
  if chRefreshAfterPost    .Checked  then
   Include (DefaultOptions,poRefreshAfterPost)
  else
   Exclude (DefaultOptions , poRefreshAfterPost)     ;
  if chTrimCharFields      .Checked  then
   Include (DefaultOptions,poTrimCharFields)
  else
   Exclude (DefaultOptions,poTrimCharFields);

  if chVisibleRecno        .Checked  then
   Include (DefaultOptions,poVisibleRecno)
  else
   Exclude (DefaultOptions,poVisibleRecno);

  if chFetchAll        .Checked  then
   Include (DefaultOptions,poFetchAll)
  else
   Exclude (DefaultOptions,poFetchAll);

  if chCacheCalcFields .Checked  then
   Include (DefaultOptions,poCacheCalcFields)
  else
   Exclude (DefaultOptions,poCacheCalcFields);

  if chUseSelectForLock  .Checked  then
   Include (DefaultOptions,poUseSelectForLock)
  else
   Exclude (DefaultOptions,poUseSelectForLock);


  if chWaitEndMasterScroll.Checked then
   Include (DefaultDetailConditions,dcWaitEndMasterScroll)
  else
   Exclude (DefaultDetailConditions,dcWaitEndMasterScroll);
  if chForceMasterRefresh.Checked then
   Include (DefaultDetailConditions,dcForceMasterRefresh)
  else
   Exclude (DefaultDetailConditions,dcForceMasterRefresh);
  if chForceOpen.Checked then
   Include (DefaultDetailConditions,dcForceOpen)
  else
   Exclude (DefaultDetailConditions,dcForceOpen);

  if chIgnoreMasterClose.Checked then
   Include (DefaultDetailConditions,dcIgnoreMasterClose)
  else
   Exclude (DefaultDetailConditions,dcIgnoreMasterClose);

  if chAutoCommitTransaction.Checked then
   Include (DefQueryOptions,qoAutoCommit)
  else
   Exclude (DefQueryOptions,qoAutoCommit);

  if chAutoStartTransaction .Checked then
   Include (DefQueryOptions,qoStartTransaction )
  else
   Exclude (DefQueryOptions,qoStartTransaction );

  DefStoreConnected  := chStoreConnected.Checked;
  DefSynchronizeTime := chSynchronizeTime.Checked;
  DefUpperOldNames   := chUpperOldNames.Checked;
  DefUseLoginPrompt  := chUseLoginPrompt.Checked;
  DefCharSet         := CharSetC.Text;
  DefSQLDialect      := DialectC.ItemIndex+1   ;

  DefTimeOutAction   :=TTransactionAction1(cmbTimeOutAction.ItemIndex);
  DefTimeOut := StrToInt(edTimeout.Text);
  DefTPBMode := TTPBMode(cmbTPBMode.ItemIndex);

  DefGoToFirstRecordOnExecute:= ChGo1.Checked;
  DefParamCheck              := ChParamCheck.Checked;
  DefPrefixGenName    := EdPrefixGen.Text;
  DefSufixGenName     := EdSufixGen .Text;

  dDefDateFormat:=edDateFormat.Text;
  dDefTimeFormat:=edTimeFormat.Text;
  dDefDisplayFormatNum:= edDisplayNumFormat.Text;
  dDefEditFormatNum   := edEditNumFormat.Text    ;
  dDefDateTimeFormat  := edDateTimeDisplay.Text;
end;


procedure TfrmFIBPreferences.SaveToReg;
begin
   DefWriteToRegistry(
    ['Software',RegFIBRoot,RegPreferences,'pFIBDataSet','Options'],
    ['PersistentSorting',
     'KeepSorting',
     'ProtectedEdit',
     'AutoFormatFields',
     'StartTransaction',
     'RefreshDeletedRecord',
     'RefreshAfterPost',
     'TrimCharFields',
     'VisibleRecno',
     'FetchAll',
     'CacheCalcFields'
    ],
    [
     chPersistentSorting.Checked,
     chKeepSorting.Checked,
     chProtectedEdit.Checked,
     chAutoFormatFields.Checked,
     chStartTransaction.Checked,
     chRefreshDeletedRecord.Checked,
     chRefreshAfterPost.Checked,
     chTrimCharFields.Checked,
     chVisibleRecno  .Checked,
     chFetchAll      .Checked,
     chCacheCalcFields.Checked
    ]
   );

   DefWriteToRegistry(
    ['Software',RegFIBRoot,RegPreferences,'pFIBDataSet','PrepareOptions'],
    ['AskRecordCount',
     'GetOrderInfo',
     'ApplyRepositary',
     'UseBooleanField',
     'ImportDefaultValues',
     'SetReadOnlyFields',
     'RequiredFields',
     'SQLINT64ToBCD',
     'UseGuidField',
     'SetEmptyStrToNull',
     'UseLargeIntField'
    ],
    [  chAskRecordCount.Checked,
       chGetOrderInfo.Checked,
       chApplyRepositary.Checked,
       chUseBooleanField.Checked,
       chImportDefaultValues.Checked,
       chSetReadOnlyFields.Checked,
       chRequiredFields.Checked,
       chUseSQLINT64ToBCD.Checked,
       chUseGuidField.Checked,
       chEmptyStrToNull.Checked,
       chUseLargeIntField.Checked
    ]
   );

   DefWriteToRegistry(
    ['Software',RegFIBRoot,RegPreferences,'pFIBDataSet','DetailConditions'],
    [
     'WaitEndMasterScroll',
     'ForceMasterRefresh',
     'ForceOpen',
     'IgnoreMasterClose'
    ],
    [
     chWaitEndMasterScroll.Checked,
     chForceMasterRefresh.Checked,
     chForceOpen.Checked,
     chIgnoreMasterClose.Checked
    ]
   );

   DefWriteToRegistry(
    ['Software',RegFIBRoot,RegPreferences,'pFIBDataSet','DefFormatFields'],
    ['DateFormat',
     'TimeFormat',
     'NumericDisplayFormat',
     'NumericEditFormat',
     'DateTimeFormat'
    ],
    [
     edDateFormat.Text,
     edTimeFormat.Text,
     edDisplayNumFormat.Text,
     edEditNumFormat.Text,
     edDateTimeDisplay.Text
    ]
   );

   DefWriteToRegistry(
    ['Software',RegFIBRoot,RegPreferences,'pFIBDataSet','Other'],
    [
     'DefPrefixGenName',
     'DefSufixGenName'
    ],
    [
     EdPrefixGen.Text,
     EdSufixGen .Text
    ]
   );

   DefWriteToRegistry(
    ['Software',RegFIBRoot,RegPreferences,'pFIBDataBase'],
    [
     'DialectC',
     'CharSetC',
     'UseLoginPrompt',
     'UpperOldNames',
     'SynchronizeTime',
     'StoreConnected',
     'CloseDesignConnectAfterRun'
    ],
    [
     DialectC.ItemIndex+1,
     CharSetC.Text,
     chUseLoginPrompt.Checked,
     chUpperOldNames.Checked,
     chSynchronizeTime.Checked,
     chStoreConnected.Checked,
     chCloseDsgnConnect.Checked
    ]
   );

   DefWriteToRegistry(
    ['Software',RegFIBRoot,RegPreferences,'pFIBQuery'],
    [
     'GoToFirstRecordOnExecute',
     'ParamCheck',
     'AutoStartTransaction',
     'AutoCommitTransaction'
    ],
    [
     ChGo1.Checked,
     ChParamCheck.Checked,
     chAutoStartTransaction .Checked,
     chAutoCommitTransaction.Checked
    ]
   );

   DefWriteToRegistry(
    ['Software',RegFIBRoot,RegPreferences,'pFIBTransaction'],
    [
     'TimeOutAction',
     'TimeOut',
     'TPBMode'
    ],
    [
     cmbTimeOutAction.ItemIndex,
     edTimeout.Text,
     cmbTPBMode.ItemIndex
    ]
   );



end;

procedure LoadFromReg;
var Values:Variant;
begin
   Values:=
   DefReadFromRegistry(['Software',RegFIBRoot,RegPreferences,'pFIBDataSet','Options'],
    [
     'PersistentSorting',
     'KeepSorting',
     'ProtectedEdit',
     'AutoFormatFields',
     'StartTransaction',
     'RefreshDeletedRecord',
     'RefreshAfterPost',
     'TrimCharFields',
     'VisibleRecno',
     'FetchAll',
     'CacheCalcFields'
    ]
   );

   if VarType(Values)<>varBoolean then
   begin
    if Values[1,0] then
     if Values[0,0] then
      Include (DefaultOptions, poPersistentSorting)
     else
      Exclude (DefaultOptions, poPersistentSorting);

    if Values[1,1] then
     if Values[0,1] then
      Include (DefaultOptions , poKeepSorting)
     else
      Exclude (DefaultOptions , poKeepSorting);

    if Values[1,2] then
     if Values[0,2] then
      Include (DefaultOptions, poProtectedEdit)
     else
      Exclude (DefaultOptions, poProtectedEdit);

    if Values[1,3] then
     if Values[0,3] then
      Include (DefaultOptions, poAutoFormatFields)
     else
      Exclude (DefaultOptions, poAutoFormatFields);

    if Values[1,4] then
     if Values[0,4] then
      Include (DefaultOptions , poStartTransaction)
     else
      Exclude (DefaultOptions , poStartTransaction);

    if Values[1,5] then
     if Values[0,5] then
      Include (DefaultOptions, poRefreshDeletedRecord)
     else
      Exclude (DefaultOptions, poRefreshDeletedRecord);

    if Values[1,6] then
     if Values[0,6] then
      Include (DefaultOptions,poRefreshAfterPost)
     else
      Exclude (DefaultOptions,poRefreshAfterPost);  

    if Values[1,7] then
     if Values[0,7] then
      Include (DefaultOptions,poTrimCharFields )
     else
      Exclude (DefaultOptions,poTrimCharFields );

    if Values[1,8] then
     if Values[0,8] then
      Include (DefaultOptions,poVisibleRecno )
     else
      Exclude (DefaultOptions,poVisibleRecno );

    if Values[1,9] then
     if Values[0,9] then
      Include (DefaultOptions,poFetchAll )
     else
      Exclude (DefaultOptions,poFetchAll );

    if Values[1,10] then
     if Values[0,10] then
      Include (DefaultOptions,poCacheCalcFields )
     else
      Exclude (DefaultOptions,poCacheCalcFields );
   end;

   Values:=
    DefReadFromRegistry(['Software',RegFIBRoot,
     RegPreferences,'pFIBDataSet','DefFormatFields'],
    ['DateFormat',
     'TimeFormat',
     'NumericDisplayFormat',
     'NumericEditFormat',
     'DateTimeFormat'
     ]
    );

   if VarType(Values)<>varBoolean then
   begin
    if Values[1,0] then
     dDefDateFormat:=VarToStr(Values[0,0]);

    if Values[1,1] then
     dDefTimeFormat:=VarToStr(Values[0,1]);

    if Values[1,2] then
     dDefDisplayFormatNum:= VarToStr(Values[0,2]);
    if Values[1,3] then
     dDefEditFormatNum  := VarToStr(Values[0,3]);
    if Values[1,4] then
     dDefDateTimeFormat  := VarToStr(Values[0,4]);
   end;


   Values:=
   DefReadFromRegistry(['Software',RegFIBRoot,
    RegPreferences,'pFIBDataSet','DetailConditions'],
    ['WaitEndMasterScroll',  'ForceMasterRefresh','ForceOpen','IgnoreMasterClose']
   );

   if VarType(Values)<>varBoolean then
   begin
    if Values[1,0] then
     if Values[0,0] then
      Include (DefaultDetailConditions,dcWaitEndMasterScroll)
     else
      Exclude (DefaultDetailConditions,dcWaitEndMasterScroll);

    if Values[1,1] then
     if Values[0,1] then
       Include (DefaultDetailConditions,dcForceMasterRefresh)
     else
       Exclude (DefaultDetailConditions,dcForceMasterRefresh);

    if Values[1,2] then
     if Values[0,2] then
      Include (DefaultDetailConditions,dcForceOpen)
     else
      Exclude (DefaultDetailConditions,dcForceOpen);

    if Values[1,3] then
     if Values[0,3] then
      Include (DefaultDetailConditions,dcIgnoreMasterClose)
     else
      Exclude (DefaultDetailConditions,dcIgnoreMasterClose);
   end;

   Values:=
   DefReadFromRegistry(
    ['Software',RegFIBRoot,RegPreferences,'pFIBDataSet','PrepareOptions'],
    ['AskRecordCount',
     'GetOrderInfo',
     'ApplyRepositary',
     'UseBooleanField',
     'ImportDefaultValues',
     'SetReadOnlyFields',
     'RequiredFields',
     'SQLINT64ToBCD',
     'UseGuidField',
     'SetEmptyStrToNull',
     'UseLargeIntField'
    ]
   );

  if VarType(Values)<>varBoolean then
  begin
    if Values[1,0] then
     if Values[0,0] then
      Include (DefaultPrepareOptions,psAskRecordCount)
     else
      Exclude (DefaultPrepareOptions,psAskRecordCount);

    if Values[1,1] then
     if Values[0,1] then
      Include (DefaultPrepareOptions,psGetOrderInfo)
     else
      Exclude (DefaultPrepareOptions,psGetOrderInfo);

    if Values[1,2] then
     if Values[0,2] then
      Include (DefaultPrepareOptions,psApplyRepositary)
     else
      Exclude (DefaultPrepareOptions,psApplyRepositary);

    if Values[1,3] then
     if Values[0,3] then
      Include (DefaultPrepareOptions,psUseBooleanField)
     else
      Exclude (DefaultPrepareOptions,psUseBooleanField);

    if Values[1,4] then
     if Values[0,4] then
      Include (DefaultPrepareOptions,pfImportDefaultValues)
     else
      Exclude (DefaultPrepareOptions,pfImportDefaultValues);

    if Values[1,5] then
     if Values[0,5] then
      Include (DefaultPrepareOptions,pfSetReadOnlyFields)
     else
      Exclude (DefaultPrepareOptions,pfSetReadOnlyFields);

    if Values[1,6] then
     if Values[0,6] then
      Include (DefaultPrepareOptions,pfSetRequiredFields)
     else
      Exclude (DefaultPrepareOptions,pfSetRequiredFields);


    if Values[1,7] then
     if Values[0,7] then
      Include (DefaultPrepareOptions,psSQLINT64ToBCD )
     else
      Exclude (DefaultPrepareOptions,psSQLINT64ToBCD );

    if Values[1,8] then
     if Values[0,8] then
      Include (DefaultPrepareOptions,psUseGuidField)
     else
      Exclude (DefaultPrepareOptions,psUseGuidField);

    if Values[1,9] then
     if Values[0,9] then
      Include (DefaultPrepareOptions,psSetEmptyStrToNull)
     else
      Exclude (DefaultPrepareOptions,psSetEmptyStrToNull);
    if Values[1,10] then
     if Values[0,10] then
      Include (DefaultPrepareOptions,psUseLargeIntField)
     else
      Exclude (DefaultPrepareOptions,psUseLargeIntField);

  end;

   Values:=
   DefReadFromRegistry(
    ['Software',RegFIBRoot,RegPreferences,'pFIBDataSet','Other'],
    [
     'DefPrefixGenName',
     'DefSufixGenName'
    ]
   );

    if VarType(Values)<>varBoolean then
    begin
     if Values[1,0] then
      DefPrefixGenName:=Values[0,0];
     if Values[1,1] then
      DefSufixGenName:=Values[0,1];
    end;

    Values:=DefReadFromRegistry(
    ['Software',RegFIBRoot,RegPreferences,'pFIBDataBase'],
    [
     'DialectC',
     'CharSetC',
     'UseLoginPrompt',
     'UpperOldNames',
     'SynchronizeTime',
     'StoreConnected',
     'CloseDesignConnectAfterRun'
    ]
   );

  if VarType(Values)<>varBoolean then
  begin
    if Values[1,0] then
     DefSQLDialect:=Values[0,0];
    if Values[1,1] then
     DefCharSet:=Values[0,1];
    if Values[1,2] then
     DefUseLoginPrompt:=Values[0,2];
    if Values[1,3] then
     DefUpperOldNames:=Values[0,3];
    if Values[1,4] then
     DefSynchronizeTime:=Values[0,4];
    if Values[1,5] then
     DefStoreConnected :=Values[0,5];
    if Values[1,6] then
     bCloseDesignConnect:=Values[0,6];

  end;

   Values:=DefReadFromRegistry(
    ['Software',RegFIBRoot,RegPreferences,'pFIBQuery'],
    [
     'GoToFirstRecordOnExecute',
     'ParamCheck',
     'AutoStartTransaction',
     'AutoCommitTransaction'     
    ]
   );
  if VarType(Values)<>varBoolean then
  begin
   if Values[1,0] then
    DefGoToFirstRecordOnExecute:=Values[0,0];
   if Values[1,1] then
    DefParamCheck:=Values[0,1];
   if Values[1,2] then
    if Values[0,2] then
     Include(DefQueryOptions,qoStartTransaction);
   if Values[1,3] then
    if Values[0,3] then
     Include(DefQueryOptions,qoAutoCommit);
  end;

   Values:=DefReadFromRegistry(
    ['Software',RegFIBRoot,RegPreferences,'pFIBTransaction'],
    [
     'TimeOutAction',
     'TimeOut',
     'TPBMode'
    ]
   );
  if VarType(Values)<>varBoolean then
  begin
   if Values[1,0] then
    DefTimeOutAction   :=TTransactionAction1(Values[0,0]);
   if Values[1,1] then
    DefTimeOut := Values[0,1];
   if Values[1,2] then
    DefTPBMode := TTPBMode(Values[0,2]);
  end;

end;

procedure TfrmFIBPreferences.FormCreate(Sender: TObject);
begin
  Caption := FPTPrefCaption;
  Label4.Caption :=  FPTGeneratorPref;
  Label5.Caption := FPTGeneratorSuf;

  Label6.Caption :=  FPTCharSet;
  Label8.Caption := FPTSQLDialect;
  chStoreConnected.Caption := FPTStoreConnected;
  chSynchronizeTime.Caption := FPTSyncTime;
  chUpperOldNames.Caption := FPTUpperOldNames;
  chUseLoginPrompt.Caption := FPTUseLoginPromt;
  Label1.Caption := FPTTimeoutAction;
  Label2.Caption := FPTTimeout;
  ChGo1.Caption := FPTGotoFirstRecord;
  ChParamCheck.Caption := FPTCheckParam;
  chAutoStartTransaction.Caption := FPTAutoStartTrans;
  chAutoCommitTransaction.Caption := FPTAutoCommitTrans;

  Button1.Caption := SOKButton;
  Button2.Caption := SCancelButton;
end;

procedure TfrmFIBPreferences.chCloseDsgnConnectClick(Sender: TObject);
begin
  bCloseDesignConnect:=chCloseDsgnConnect.Checked
end;

initialization
 {$IFNDEF FIBPLUS_TRIAL}
  LoadFromReg;
 {$ENDIF} 
end.


