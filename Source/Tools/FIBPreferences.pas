unit FIBPreferences;

interface

{$I ..\FIBPlus.inc}

uses
  System.SysUtils, System.Classes, System.Variants, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls,
  Vcl.StdCtrls, FIBProps;

type
  TFIBPreferencesForm = class(TForm)
    PageControl: TPageControl;
    DatabasePage: TTabSheet;
    DataSetPage: TTabSheet;
    PrepareOptionsGroup: TGroupBox;
    chRequiredFields: TCheckBox;
    chSetReadOnlyFields: TCheckBox;
    chImportDefaultValues: TCheckBox;
    chUseBooleanField: TCheckBox;
    chApplyRepositary: TCheckBox;
    chGetOrderInfo: TCheckBox;
    chAskRecordCount: TCheckBox;
    DataSetOptionsGroup: TGroupBox;
    chTrimCharFields: TCheckBox;
    chRefreshAfterPost: TCheckBox;
    chRefreshDeletedRecord: TCheckBox;
    chStartTransaction: TCheckBox;
    chAutoFormatFields: TCheckBox;
    chProtectedEdit: TCheckBox;
    chKeepSorting: TCheckBox;
    chPersistentSorting: TCheckBox;
    DetailConditionsGroup: TGroupBox;
    chForceOpen: TCheckBox;
    chForceMasterRefresh: TCheckBox;
    chWaitEndMasterScroll: TCheckBox;
    edGeneratorPrefix: TEdit;
    edGeneratorSuffix: TEdit;
    GeneratorPrefixLabel: TLabel;
    GeneratorSuffixLabel: TLabel;
    OKButton: TButton;
    CancelButton: TButton;
    TransactionPage: TTabSheet;
    QueryPage: TTabSheet;
    chStoreConnected: TCheckBox;
    chSynchronizeTime: TCheckBox;
    chUpperOldNames: TCheckBox;
    chUseLoginPrompt: TCheckBox;
    CharSetLabel: TLabel;
    cmbCharSet: TComboBox;
    SQLDialectLabel: TLabel;
    cmbSQLDialect: TComboBox;
    TimeoutActionLabel: TLabel;
    TimeoutLabel: TLabel;
    TPBModeLabel: TLabel;
    cmbTimeOutAction: TComboBox;
    edTimeout: TEdit;
    cmbTPBMode: TComboBox;
    chGoToFirstRecord: TCheckBox;
    chParamCheck: TCheckBox;
    chAutoStartTransaction: TCheckBox;
    chAutoCommitTransaction: TCheckBox;
    chUseSQLINT64ToBCD: TCheckBox;
    chVisibleRecno: TCheckBox;
    DefaultFormatsGroup: TGroupBox;
    DateFormatLabel: TLabel;
    TimeFormatLabel: TLabel;
    DisplayNumFormatLabel: TLabel;
    EditNumFormatLabel: TLabel;
    edDateFormat: TEdit;
    edTimeFormat: TEdit;
    edDisplayNumFormat: TEdit;
    edEditNumFormat: TEdit;
    chIgnoreMasterClose: TCheckBox;
    chUseGuidField: TCheckBox;
    chFetchAll: TCheckBox;
    chEmptyStrToNull: TCheckBox;
    chCloseDesignConnections: TCheckBox;
    chCacheCalcFields: TCheckBox;
    edDateTimeDisplay: TEdit;
    DateTimeFormatLabel: TLabel;
    chUseLargeIntField: TCheckBox;
    chUseSelectForLock: TCheckBox;
    chNoForceIsNull: TCheckBox;
    chFreeHandlesAfterClose: TCheckBox;
    chRefreshAfterDelete: TCheckBox;
    chDontCloseAfterEndTransaction: TCheckBox;
    chCanEditComputedFields: TCheckBox;
    chSupportUnicodeBlobs: TCheckBox;
    chQueryTrimCharFields: TCheckBox;
    chQueryNoForceIsNull: TCheckBox;
    chFreeHandleAfterExecute: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    FDataSetOptionBoxes: array[TFIBDataSetOption] of TCheckBox;
    FPrepareOptionBoxes: array[TFIBPrepareOption] of TCheckBox;
    FDetailConditionBoxes: array[TDetailCondition] of TCheckBox;
    FQueryOptionBoxes: array[TFIBQueryOption] of TCheckBox;
    procedure LoadPreferences;
    procedure SavePreferences;
  end;

var
  CloseDesignConnections: Boolean;

procedure ShowFIBPreferences;

implementation

{$R *.dfm}

uses
  RegUtils, FIBToolsConsts;

const
  // Some registry names differ from the option names; they are kept for the values saved by older versions
  DataSetOptionNames: array[TFIBDataSetOption] of string = ('TrimCharFields', 'RefreshAfterPost',
    'RefreshDeletedRecord', 'StartTransaction', 'AutoFormatFields', 'ProtectedEdit', 'UseSelectForLock',
    'KeepSorting',
{$IFDEF OBSOLETE_PROPS}
    'AllowChangeSqls',
{$ENDIF}
    'PersistentSorting', 'VisibleRecno', 'NoForceIsNull', 'FetchAll', 'FreeHandlesAfterClose', 'CacheCalcFields',
    'RefreshAfterDelete', 'DontCloseAfterEndTransaction');

  PrepareOptionNames: array[TFIBPrepareOption] of string = ('RequiredFields', 'SetReadOnlyFields',
    'ImportDefaultValues', 'UseBooleanField', 'UseGuidField', 'SQLINT64ToBCD', 'ApplyRepositary', 'GetOrderInfo',
    'AskRecordCount', 'CanEditComputedFields', 'SetEmptyStrToNull', 'SupportUnicodeBlobs', 'UseLargeIntField');

  DetailConditionNames: array[TDetailCondition] of string = ('ForceOpen', 'IgnoreMasterClose',
    'ForceMasterRefresh', 'WaitEndMasterScroll');

  QueryOptionNames: array[TFIBQueryOption] of string = ('AutoStartTransaction', 'AutoCommitTransaction',
    'TrimCharFields', 'NoForceIsNull', 'FreeHandleAfterExecute');

procedure SetOption(var Options: TFIBDataSetOptions; Option: TFIBDataSetOption; Value: Boolean); overload;
begin
  if Value then
    Include(Options, Option)
  else
    Exclude(Options, Option);
end;

procedure SetOption(var Options: TFIBPrepareOptions; Option: TFIBPrepareOption; Value: Boolean); overload;
begin
  if Value then
    Include(Options, Option)
  else
    Exclude(Options, Option);
end;

procedure SetOption(var Options: TDetailConditions; Option: TDetailCondition; Value: Boolean); overload;
begin
  if Value then
    Include(Options, Option)
  else
    Exclude(Options, Option);
end;

procedure SetOption(var Options: TFIBQueryOptions; Option: TFIBQueryOption; Value: Boolean); overload;
begin
  if Value then
    Include(Options, Option)
  else
    Exclude(Options, Option);
end;

// Values is the result of DefReadFromRegistry: False when the key is missing, else [value, exists] pairs
function ReadString(const Values: Variant; Index: Integer; var Value: string): Boolean;
begin
  Result := VarIsArray(Values) and (VarType(Values[1, Index]) = varBoolean) and Boolean(Values[1, Index]);
  if Result then
    Value := VarToStr(Values[0, Index]);
end;

function ReadInteger(const Values: Variant; Index: Integer; var Value: Integer): Boolean;
var
  Text: string;
begin
  Result := ReadString(Values, Index, Text) and TryStrToInt(Text, Value);
end;

function ReadBoolean(const Values: Variant; Index: Integer; var Value: Boolean): Boolean;
var
  Text: string;
begin
  Result := ReadString(Values, Index, Text) and TryStrToBool(Text, Value);
end;

procedure LoadFromReg;
var
  Values: Variant;
  Flag: Boolean;
  Number: Integer;
  Text: string;
  DataSetOption: TFIBDataSetOption;
  PrepareOption: TFIBPrepareOption;
  DetailCondition: TDetailCondition;
  QueryOption: TFIBQueryOption;
begin
  Values := DefReadFromRegistry(['Software', RegFIBRoot, RegPreferences, 'FIBDataSet', 'Options'],
    DataSetOptionNames);
  for DataSetOption := Low(TFIBDataSetOption) to High(TFIBDataSetOption) do
    if ReadBoolean(Values, Ord(DataSetOption), Flag) then
      SetOption(DefaultOptions, DataSetOption, Flag);

  Values := DefReadFromRegistry(['Software', RegFIBRoot, RegPreferences, 'FIBDataSet', 'PrepareOptions'],
    PrepareOptionNames);
  for PrepareOption := Low(TFIBPrepareOption) to High(TFIBPrepareOption) do
    if ReadBoolean(Values, Ord(PrepareOption), Flag) then
      SetOption(DefaultPrepareOptions, PrepareOption, Flag);

  Values := DefReadFromRegistry(['Software', RegFIBRoot, RegPreferences, 'FIBDataSet', 'DetailConditions'],
    DetailConditionNames);
  for DetailCondition := Low(TDetailCondition) to High(TDetailCondition) do
    if ReadBoolean(Values, Ord(DetailCondition), Flag) then
      SetOption(DefaultDetailConditions, DetailCondition, Flag);

  Values := DefReadFromRegistry(['Software', RegFIBRoot, RegPreferences, 'FIBDataSet', 'DefFormatFields'],
    ['DateFormat', 'TimeFormat', 'NumericDisplayFormat', 'NumericEditFormat', 'DateTimeFormat']);
  if ReadString(Values, 0, Text) then
    dDefDateFormat := Text;
  if ReadString(Values, 1, Text) then
    dDefTimeFormat := Text;
  if ReadString(Values, 2, Text) then
    dDefDisplayFormatNum := Text;
  if ReadString(Values, 3, Text) then
    dDefEditFormatNum := Text;
  if ReadString(Values, 4, Text) then
    dDefDateTimeFormat := Text;

  Values := DefReadFromRegistry(['Software', RegFIBRoot, RegPreferences, 'FIBDataSet', 'Other'],
    ['DefPrefixGenName', 'DefSufixGenName']);
  if ReadString(Values, 0, Text) then
    DefPrefixGenName := Text;
  if ReadString(Values, 1, Text) then
    DefSufixGenName := Text;

  Values := DefReadFromRegistry(['Software', RegFIBRoot, RegPreferences, 'FIBDatabase'],
    ['DialectC', 'CharSetC', 'UseLoginPrompt', 'UpperOldNames', 'SynchronizeTime', 'StoreConnected',
    'CloseDesignConnectAfterRun']);
  if ReadInteger(Values, 0, Number) and (Number >= 1) and (Number <= 3) then
    DefSQLDialect := Number;
  if ReadString(Values, 1, Text) then
    DefCharSet := Text;
  if ReadBoolean(Values, 2, Flag) then
    DefUseLoginPrompt := Flag;
  if ReadBoolean(Values, 3, Flag) then
    DefUpperOldNames := Flag;
  if ReadBoolean(Values, 4, Flag) then
    DefSynchronizeTime := Flag;
  if ReadBoolean(Values, 5, Flag) then
    DefStoreConnected := Flag;
  if ReadBoolean(Values, 6, Flag) then
    CloseDesignConnections := Flag;

  Values := DefReadFromRegistry(['Software', RegFIBRoot, RegPreferences, 'FIBQuery'],
    ['GoToFirstRecordOnExecute', 'ParamCheck']);
  if ReadBoolean(Values, 0, Flag) then
    DefGoToFirstRecordOnExecute := Flag;
  if ReadBoolean(Values, 1, Flag) then
    DefParamCheck := Flag;

  Values := DefReadFromRegistry(['Software', RegFIBRoot, RegPreferences, 'FIBQuery'], QueryOptionNames);
  for QueryOption := Low(TFIBQueryOption) to High(TFIBQueryOption) do
    if ReadBoolean(Values, Ord(QueryOption), Flag) then
      SetOption(DefQueryOptions, QueryOption, Flag);

  Values := DefReadFromRegistry(['Software', RegFIBRoot, RegPreferences, 'FIBTransaction'],
    ['TimeOutAction', 'TimeOut', 'TPBMode']);
  if ReadInteger(Values, 0, Number) and (Number >= Ord(Low(TTransactionAction1))) and
    (Number <= Ord(High(TTransactionAction1))) then
    DefTimeOutAction := TTransactionAction1(Number);
  if ReadInteger(Values, 1, Number) and (Number >= 0) then
    DefTimeOut := Number;
  if ReadInteger(Values, 2, Number) and (Number >= Ord(Low(TTPBMode))) and (Number <= Ord(High(TTPBMode))) then
    DefTPBMode := TTPBMode(Number);
end;

procedure SaveToReg;
var
  Values: TArray<Variant>;
  DataSetOption: TFIBDataSetOption;
  PrepareOption: TFIBPrepareOption;
  DetailCondition: TDetailCondition;
  QueryOption: TFIBQueryOption;
begin
  SetLength(Values, Length(DataSetOptionNames));
  for DataSetOption := Low(TFIBDataSetOption) to High(TFIBDataSetOption) do
    Values[Ord(DataSetOption)] := DataSetOption in DefaultOptions;
  DefWriteToRegistry(['Software', RegFIBRoot, RegPreferences, 'FIBDataSet', 'Options'], DataSetOptionNames, Values);

  SetLength(Values, Length(PrepareOptionNames));
  for PrepareOption := Low(TFIBPrepareOption) to High(TFIBPrepareOption) do
    Values[Ord(PrepareOption)] := PrepareOption in DefaultPrepareOptions;
  DefWriteToRegistry(['Software', RegFIBRoot, RegPreferences, 'FIBDataSet', 'PrepareOptions'], PrepareOptionNames,
    Values);

  SetLength(Values, Length(DetailConditionNames));
  for DetailCondition := Low(TDetailCondition) to High(TDetailCondition) do
    Values[Ord(DetailCondition)] := DetailCondition in DefaultDetailConditions;
  DefWriteToRegistry(['Software', RegFIBRoot, RegPreferences, 'FIBDataSet', 'DetailConditions'],
    DetailConditionNames, Values);

  DefWriteToRegistry(['Software', RegFIBRoot, RegPreferences, 'FIBDataSet', 'DefFormatFields'],
    ['DateFormat', 'TimeFormat', 'NumericDisplayFormat', 'NumericEditFormat', 'DateTimeFormat'],
    [dDefDateFormat, dDefTimeFormat, dDefDisplayFormatNum, dDefEditFormatNum, dDefDateTimeFormat]);

  DefWriteToRegistry(['Software', RegFIBRoot, RegPreferences, 'FIBDataSet', 'Other'],
    ['DefPrefixGenName', 'DefSufixGenName'], [DefPrefixGenName, DefSufixGenName]);

  DefWriteToRegistry(['Software', RegFIBRoot, RegPreferences, 'FIBDatabase'],
    ['DialectC', 'CharSetC', 'UseLoginPrompt', 'UpperOldNames', 'SynchronizeTime', 'StoreConnected',
    'CloseDesignConnectAfterRun'],
    [DefSQLDialect, DefCharSet, DefUseLoginPrompt, DefUpperOldNames, DefSynchronizeTime, DefStoreConnected,
    CloseDesignConnections]);

  DefWriteToRegistry(['Software', RegFIBRoot, RegPreferences, 'FIBQuery'],
    ['GoToFirstRecordOnExecute', 'ParamCheck'], [DefGoToFirstRecordOnExecute, DefParamCheck]);

  SetLength(Values, Length(QueryOptionNames));
  for QueryOption := Low(TFIBQueryOption) to High(TFIBQueryOption) do
    Values[Ord(QueryOption)] := QueryOption in DefQueryOptions;
  DefWriteToRegistry(['Software', RegFIBRoot, RegPreferences, 'FIBQuery'], QueryOptionNames, Values);

  DefWriteToRegistry(['Software', RegFIBRoot, RegPreferences, 'FIBTransaction'],
    ['TimeOutAction', 'TimeOut', 'TPBMode'], [Integer(DefTimeOutAction), DefTimeOut, Integer(DefTPBMode)]);
end;

procedure ShowFIBPreferences;
var
  Form: TFIBPreferencesForm;
begin
  Form := TFIBPreferencesForm.Create(nil);
  try
    Form.LoadPreferences;
    if Form.ShowModal = mrOk then
    begin
      Form.SavePreferences;
      SaveToReg;
    end;
  finally
    Form.Free;
  end;
end;

procedure TFIBPreferencesForm.FormCreate(Sender: TObject);
begin
  FDataSetOptionBoxes[poTrimCharFields] := chTrimCharFields;
  FDataSetOptionBoxes[poRefreshAfterPost] := chRefreshAfterPost;
  FDataSetOptionBoxes[poRefreshDeletedRecord] := chRefreshDeletedRecord;
  FDataSetOptionBoxes[poStartTransaction] := chStartTransaction;
  FDataSetOptionBoxes[poAutoFormatFields] := chAutoFormatFields;
  FDataSetOptionBoxes[poProtectedEdit] := chProtectedEdit;
  FDataSetOptionBoxes[poUseSelectForLock] := chUseSelectForLock;
  FDataSetOptionBoxes[poKeepSorting] := chKeepSorting;
  FDataSetOptionBoxes[poPersistentSorting] := chPersistentSorting;
  FDataSetOptionBoxes[poVisibleRecno] := chVisibleRecno;
  FDataSetOptionBoxes[poNoForceIsNull] := chNoForceIsNull;
  FDataSetOptionBoxes[poFetchAll] := chFetchAll;
  FDataSetOptionBoxes[poFreeHandlesAfterClose] := chFreeHandlesAfterClose;
  FDataSetOptionBoxes[poCacheCalcFields] := chCacheCalcFields;
  FDataSetOptionBoxes[poRefreshAfterDelete] := chRefreshAfterDelete;
  FDataSetOptionBoxes[poDontCloseAfterEndTransaction] := chDontCloseAfterEndTransaction;

  FPrepareOptionBoxes[pfSetRequiredFields] := chRequiredFields;
  FPrepareOptionBoxes[pfSetReadOnlyFields] := chSetReadOnlyFields;
  FPrepareOptionBoxes[pfImportDefaultValues] := chImportDefaultValues;
  FPrepareOptionBoxes[psUseBooleanField] := chUseBooleanField;
  FPrepareOptionBoxes[psUseGuidField] := chUseGuidField;
  FPrepareOptionBoxes[psSQLINT64ToBCD] := chUseSQLINT64ToBCD;
  FPrepareOptionBoxes[psApplyRepositary] := chApplyRepositary;
  FPrepareOptionBoxes[psGetOrderInfo] := chGetOrderInfo;
  FPrepareOptionBoxes[psAskRecordCount] := chAskRecordCount;
  FPrepareOptionBoxes[psCanEditComputedFields] := chCanEditComputedFields;
  FPrepareOptionBoxes[psSetEmptyStrToNull] := chEmptyStrToNull;
  FPrepareOptionBoxes[psSupportUnicodeBlobs] := chSupportUnicodeBlobs;
  FPrepareOptionBoxes[psUseLargeIntField] := chUseLargeIntField;

  FDetailConditionBoxes[dcForceOpen] := chForceOpen;
  FDetailConditionBoxes[dcIgnoreMasterClose] := chIgnoreMasterClose;
  FDetailConditionBoxes[dcForceMasterRefresh] := chForceMasterRefresh;
  FDetailConditionBoxes[dcWaitEndMasterScroll] := chWaitEndMasterScroll;

  FQueryOptionBoxes[qoStartTransaction] := chAutoStartTransaction;
  FQueryOptionBoxes[qoAutoCommit] := chAutoCommitTransaction;
  FQueryOptionBoxes[qoTrimCharFields] := chQueryTrimCharFields;
  FQueryOptionBoxes[qoNoForceIsNull] := chQueryNoForceIsNull;
  FQueryOptionBoxes[qoFreeHandleAfterExecute] := chFreeHandleAfterExecute;

  Caption := FPTPrefCaption;
  GeneratorPrefixLabel.Caption := FPTGeneratorPref;
  GeneratorSuffixLabel.Caption := FPTGeneratorSuf;

  CharSetLabel.Caption := FPTCharSet;
  SQLDialectLabel.Caption := FPTSQLDialect;
  chStoreConnected.Caption := FPTStoreConnected;
  chSynchronizeTime.Caption := FPTSyncTime;
  chUpperOldNames.Caption := FPTUpperOldNames;
  chUseLoginPrompt.Caption := FPTUseLoginPrompt;
  chCloseDesignConnections.Caption := FPTCloseDesignConnections;
  TimeoutActionLabel.Caption := FPTTimeoutAction;
  TimeoutLabel.Caption := FPTTimeout;
  chGoToFirstRecord.Caption := FPTGotoFirstRecord;
  chParamCheck.Caption := FPTCheckParam;
  chAutoStartTransaction.Caption := FPTAutoStartTrans;
  chAutoCommitTransaction.Caption := FPTAutoCommitTrans;

  OKButton.Caption := SOKButton;
  CancelButton.Caption := SCancelButton;
end;

procedure TFIBPreferencesForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  Timeout: Integer;
begin
  if (ModalResult = mrOk) and not (TryStrToInt(Trim(edTimeout.Text), Timeout) and (Timeout >= 0)) then
  begin
    CanClose := False;
    PageControl.ActivePage := TransactionPage;
    edTimeout.SetFocus;
    MessageDlg(FPTInvalidTimeout, mtError, [mbOK], 0);
  end;
end;

procedure TFIBPreferencesForm.LoadPreferences;
var
  DataSetOption: TFIBDataSetOption;
  PrepareOption: TFIBPrepareOption;
  DetailCondition: TDetailCondition;
  QueryOption: TFIBQueryOption;
begin
  for DataSetOption := Low(TFIBDataSetOption) to High(TFIBDataSetOption) do
    if Assigned(FDataSetOptionBoxes[DataSetOption]) then
      FDataSetOptionBoxes[DataSetOption].Checked := DataSetOption in DefaultOptions;
  for PrepareOption := Low(TFIBPrepareOption) to High(TFIBPrepareOption) do
    FPrepareOptionBoxes[PrepareOption].Checked := PrepareOption in DefaultPrepareOptions;
  for DetailCondition := Low(TDetailCondition) to High(TDetailCondition) do
    FDetailConditionBoxes[DetailCondition].Checked := DetailCondition in DefaultDetailConditions;
  for QueryOption := Low(TFIBQueryOption) to High(TFIBQueryOption) do
    FQueryOptionBoxes[QueryOption].Checked := QueryOption in DefQueryOptions;

  cmbSQLDialect.ItemIndex := DefSQLDialect - 1;
  cmbCharSet.Text := DefCharSet;
  chUseLoginPrompt.Checked := DefUseLoginPrompt;
  chUpperOldNames.Checked := DefUpperOldNames;
  chSynchronizeTime.Checked := DefSynchronizeTime;
  chStoreConnected.Checked := DefStoreConnected;
  chCloseDesignConnections.Checked := CloseDesignConnections;

  cmbTimeOutAction.ItemIndex := Ord(DefTimeOutAction);
  edTimeout.Text := IntToStr(DefTimeOut);
  cmbTPBMode.ItemIndex := Ord(DefTPBMode);

  chGoToFirstRecord.Checked := DefGoToFirstRecordOnExecute;
  chParamCheck.Checked := DefParamCheck;

  edGeneratorPrefix.Text := DefPrefixGenName;
  edGeneratorSuffix.Text := DefSufixGenName;
  edDateFormat.Text := dDefDateFormat;
  edTimeFormat.Text := dDefTimeFormat;
  edDisplayNumFormat.Text := dDefDisplayFormatNum;
  edDateTimeDisplay.Text := dDefDateTimeFormat;
  edEditNumFormat.Text := dDefEditFormatNum;
end;

procedure TFIBPreferencesForm.SavePreferences;
var
  DataSetOption: TFIBDataSetOption;
  PrepareOption: TFIBPrepareOption;
  DetailCondition: TDetailCondition;
  QueryOption: TFIBQueryOption;
begin
  for DataSetOption := Low(TFIBDataSetOption) to High(TFIBDataSetOption) do
    if Assigned(FDataSetOptionBoxes[DataSetOption]) then
      SetOption(DefaultOptions, DataSetOption, FDataSetOptionBoxes[DataSetOption].Checked);
  for PrepareOption := Low(TFIBPrepareOption) to High(TFIBPrepareOption) do
    SetOption(DefaultPrepareOptions, PrepareOption, FPrepareOptionBoxes[PrepareOption].Checked);
  for DetailCondition := Low(TDetailCondition) to High(TDetailCondition) do
    SetOption(DefaultDetailConditions, DetailCondition, FDetailConditionBoxes[DetailCondition].Checked);
  for QueryOption := Low(TFIBQueryOption) to High(TFIBQueryOption) do
    SetOption(DefQueryOptions, QueryOption, FQueryOptionBoxes[QueryOption].Checked);

  DefStoreConnected := chStoreConnected.Checked;
  DefSynchronizeTime := chSynchronizeTime.Checked;
  DefUpperOldNames := chUpperOldNames.Checked;
  DefUseLoginPrompt := chUseLoginPrompt.Checked;
  DefCharSet := cmbCharSet.Text;
  DefSQLDialect := cmbSQLDialect.ItemIndex + 1;
  CloseDesignConnections := chCloseDesignConnections.Checked;

  DefTimeOutAction := TTransactionAction1(cmbTimeOutAction.ItemIndex);
  DefTimeOut := StrToInt(Trim(edTimeout.Text));
  DefTPBMode := TTPBMode(cmbTPBMode.ItemIndex);

  DefGoToFirstRecordOnExecute := chGoToFirstRecord.Checked;
  DefParamCheck := chParamCheck.Checked;
  DefPrefixGenName := edGeneratorPrefix.Text;
  DefSufixGenName := edGeneratorSuffix.Text;

  dDefDateFormat := edDateFormat.Text;
  dDefTimeFormat := edTimeFormat.Text;
  dDefDisplayFormatNum := edDisplayNumFormat.Text;
  dDefEditFormatNum := edEditNumFormat.Text;
  dDefDateTimeFormat := edDateTimeDisplay.Text;
end;

initialization
  LoadFromReg;

end.
