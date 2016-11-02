unit RegFIBPlusEditors;

interface

{$I ..\FIBPlus.inc}
uses Windows,Classes,
{$IFDEF D_XE2}
Vcl.StdCtrls,Vcl.Forms,Vcl.ExtCtrls,Vcl.Dialogs,
{$ELSE}
StdCtrls,Forms,ExtCtrls,Dialogs,
{$ENDIF}
SysUtils,pFIBInterfaces,  TypInfo, FIBDatabase,
     {$IFDEF D6+}
       DesignEditors,DesignIntf, Variants//,Types
     {$else}
       DsgnIntf
     {$ENDIF}

;

type


      TiBeforeProposalCall=procedure(const ProposalName:string) of object;


      IFIBSQLTextEditor= interface
       ['{59B98703-4324-43AA-A656-5842806E35B2}']
       function GetReadOnly:boolean;
       procedure SetReadOnly(Value:boolean);
       function  GetLines:TStrings;
       procedure SetLines(Value: TStrings);
       function GetSelStart: Integer;
       procedure SetSelStart(Value: Integer);
       function GetSelLength: Integer;
       procedure SetSelLength(Value: Integer);
       function  GetCaretX:integer;
       function  GetCaretY:integer;
       procedure iSetCaretPos(X,Y:integer);
       procedure  ScreenPosToTextPos(const ScrX,ScrY:Integer; var DestX,DestY:Integer ); // для драг дропа

       procedure  ISetProposalItems(ts1,ts2:TStrings);
       procedure       SaveProposals(const aName:string);
       procedure       ApplyProposal(const aName:string);
       procedure       AddToCurrentProposal(ts,ts1:TStrings);
       procedure       AddProposal(const aName:string);
       procedure       ClearProposal;
       function        GetBeforePropCall:TiBeforeProposalCall;
       procedure       SetBeforePropCall(Event:TiBeforeProposalCall);
       function        GetPosInText:Integer;
       procedure SelectAll;
       function GetModified: Boolean;
       procedure SetModified(Value: Boolean);
       procedure SetFocus;
       property SelLength: Integer read GetSelLength write SetSelLength;
       property SelStart: Integer read GetSelStart write SetSelStart;
       property  ReadOnly:boolean read GetReadOnly write SetReadOnly;
       property Lines: TStrings read GetLines write SetLines;
       property CaretX:integer read GetCaretX;
       property CaretY:integer read GetCaretY;
       property DoBeforeProposalCall: TiBeforeProposalCall read GetBeforePropCall write SetBeforePropCall;
       property PosInText:integer read GetPosInText;
      end;


{ TODO 1 : Тулзы подключить. Проверить на компиляцию под Д6 перенести под Д2009 }



procedure RegisterFIBSQLTextEditor(Editor:TClass);
function  GetSQLTextEditor:TClass;

procedure Register;

implementation

uses pFIBComponentEditors, {$ifndef internal} fib_aspr_api, Fibmodule5, Fibmodule6, FibHash2, Fibhash3,
  fibAthlInstanceCounter, fibCheckSingleLicenseClass, fib_hard,
 {$endif}
  ToolsAPI, { RegFIBPlusUtils, } RegSynEditAlt {, FIBSplash};


var    vSQLTextEditorClass:TClass;
var
  LicensedTo: string;
  k: AnsiString;

type   TFIBSQLMemo=class(TMemo,IFIBSQLTextEditor)
       private
        function GetReadOnly:boolean;
        procedure SetReadOnly(Value:boolean);
        function  GetLines:TStrings;
        function  GetCaretX:integer;
        function  GetCaretY:integer;
        function  GetModified: Boolean;
        procedure SetModified(Value: Boolean);
        procedure iSetCaretPos(X,Y:integer);
        procedure  ISetProposalItems(ts1,ts2:TStrings);
        procedure       SaveProposals(const aName:string);
        procedure       ApplyProposal(const aName:string);
        procedure       AddToCurrentProposal(ts,ts1:TStrings);
        procedure       AddProposal(const aName:string);
        procedure       ClearProposal;
        function        GetBeforePropCall:TiBeforeProposalCall;
        procedure       SetBeforePropCall(Event:TiBeforeProposalCall);
        function        GetPosInText:Integer;
        procedure ScreenPosToTextPos(const ScrX,ScrY:Integer; var DestX,DestY:Integer ); // для драг дропа
       public
         constructor Create(AOwner:TComponent);override;
       end;

procedure RegisterFIBSQLTextEditor(Editor:TClass);
begin
 if Assigned(Editor) then
  vSQLTextEditorClass:=Editor
 else
  vSQLTextEditorClass:=TFIBSQLMemo
end;

function  GetSQLTextEditor:TClass;
begin
 if Assigned(vSQLTextEditorClass) then
  Result:=vSQLTextEditorClass
 else
  Result:=TFIBSQLMemo
end;

{$ifndef internal}
type

  TMenuIOTAFibPlus = class(TNotifierObject, IOTAWIzard, IOTAMenuWizard)
  public
    function GetMenuText: string;
    function GetIDString: string;
    function GetName: string;
    function GetState: TWizardState;
    procedure Execute;
  end;

  TIDEIOTAFibPlus = class(TNotifierObject, IOTANotifier, IOTAIDENotifier, IOTAIDENotifier50)
  public
    // IOTAIDENotifier
    procedure FileNotification(NotifyCode: TOTAFileNotification;
      const FileName: string; var Cancel: Boolean);
    procedure BeforeCompile(const Project: IOTAProject; var Cancel: Boolean); overload;
    procedure AfterCompile(Succeeded: Boolean); overload;

    // IOTAIDENotifier50
    procedure BeforeCompile(const Project: IOTAProject; IsCodeInsight: Boolean;
      var Cancel: Boolean); overload;
    procedure AfterCompile(Succeeded: Boolean; IsCodeInsight: Boolean); overload;
  end;

type
  TDemoTimer = class
  end;

var
  DemoTimer: TDemoTimer;


var
  CheckLicense: TCheckLicense;
  NotifierIndex: Integer;
{$endif}



type
  IFIBClassesExporter = interface
   ['{AFC7CF1A-EAA5-4584-B47D-BDAD337B4EEC}']  
   function iGetStringer:IFIBStringer;
   function iGetMetaExtractor:IFIBMetaDataExtractor;
  end;


procedure Register;
  procedure RegisterEditors;
  var
     DatabaseClass:TClass;
     QueryClass:TClass;
     DatasetClass:TClass;
     DeltaReceiver:TClass;
     TransactionClass:TClass;
     pi:PPropInfo;
     auClass:TClass;
     expCl:IFIBClassesExporter;
  begin

   Supports(FIBClassesExporter,IFIBClassesExporter,expCl);
   try
    expCl.iGetStringer;    // AV  если триал пытаются использовать с не триалом
  //database  Properties
    DatabaseClass:=expDatabaseClass;
    TransactionClass:=expTransactionClass;
    QueryClass:=expQueryClass;
    DatasetClass:=expDatasetClass;
    DeltaReceiver:=expDeltaReceiverClass;
    RegisterPropertyEditor(TypeInfo(string), DatabaseClass, 'AliasName', TFIBAliasEdit);
    RegisterPropertyEditor(TypeInfo(string), DatabaseClass, 'DBName', TFileNameProperty);
    RegisterPropertyEditor(TypeInfo(string), DatabaseClass, 'LibraryName', TFileNameProperty);
    RegisterPropertyEditor(TypeInfo(TNotifyEvent),DatabaseClass,  'OnConnect',   nil  );
    pi:=GetPropInfo(DatabaseClass,'OnLogin');
    if pi<>nil then
     RegisterPropertyEditor(pi.PropType^,DatabaseClass,  'OnLogin',   nil  );

    RegisterComponentEditor(TComponentClass(DatabaseClass), TpFIBDatabaseEditor);
    RegisterComponentEditor(TComponentClass(TransactionClass), TpFIBTransactionEditor);
    RegisterComponentEditor(TComponentClass(QueryClass), TpFIBQueryEditor);
    RegisterComponentEditor(TComponentClass(DataSetClass), TFIBGenSQlEd);


    pi:=GetPropInfo(QueryClass,'Conditions');
    RegisterPropertyEditor(pi.PropType^,nil,'Conditions',TFIBConditionsEditor);


    pi:=GetPropInfo(DatasetClass,'Options');
    RegisterPropertyEditor(pi.PropType^, nil, 'Options', TpFIBDataSetOptionsEditor);
    pi:=GetPropInfo(DatasetClass,'PrepareOptions');
    RegisterPropertyEditor(pi.PropType^, nil, 'PrepareOptions', TpFIBDataSetOptionsEditor);
    pi:=GetPropInfo(DatasetClass,'AutoUpdateOptions');
    RegisterPropertyEditor(pi.PropType^, DatasetClass, 'AutoUpdateOptions', TpFIBAutoUpdateOptionsEditor);

    auClass:=GetTypeData(Pi^.PropType^).ClassType;
    RegisterPropertyEditor(TypeInfo(TStrings), auClass,
      'ParamsToFieldsLinks', TEdParamToFields
    );
    RegisterPropertyEditor(TypeInfo(string), auClass,
      'GeneratorName', TGeneratorNameEdit
    );

    RegisterPropertyEditor(TypeInfo(string), auClass,
      'KeyFields', TKeyFieldNameEdit
      );

    RegisterPropertyEditor(TypeInfo(string), auClass,
      'UpdateTableName', TTableNameEdit
      );


    RegisterPropertyEditor(TypeInfo(integer), DatasetClass,
      'DataSet_ID', TDataSet_ID_Edit
      );



    RegisterPropertyEditor(TypeInfo(TStrings),DatasetClass,'SelectSQL',nil);
    RegisterPropertyEditor(TypeInfo(TStrings),DatasetClass,'InsertSQL',nil);
    RegisterPropertyEditor(TypeInfo(TStrings),DatasetClass,'UpdateSQL',nil);
    RegisterPropertyEditor(TypeInfo(TStrings),DatasetClass,'DeleteSQL',nil);
    RegisterPropertyEditor(TypeInfo(TStrings),DatasetClass,'RefreshSQL',nil);
    RegisterPropertyEditor(TypeInfo(boolean),DatasetClass,'WaitEndMasterScroll',nil);

    pi:=GetPropInfo(DatasetClass,'SQLs');
    RegisterPropertyEditor(TypeInfo(TStrings),GetTypeData(Pi^.PropType^).ClassType,'',TFIBSQLsProperty);

    RegisterPropertyEditor(pi.PropType^,DatasetClass,'',TFIBSQLsProperties);

    RegisterPropertyEditor(TypeInfo(string), QueryClass, 'StoredProcName',
     TpFIBStoredProcProperty
    );

    RegisterPropertyEditor(TypeInfo(TStrings), QueryClass, 'SQL',
     TpFIBSQLPropEdit
    );


    RegisterPropertyEditor(TypeInfo(string),TransactionClass,
     'UserKindTransaction',   TFIBTrKindEdit
    );

  pi:=GetPropInfo(DatabaseClass,'GeneratorsCache');
  auClass:=GetTypeData(Pi^.PropType^).ClassType;
  RegisterPropertyEditor(TypeInfo(TOwnedCollection),auClass,
   'GeneratorList',   TpFIBGeneratorsProperty
  );

  RegisterPropertyEditor(TypeInfo(string),auClass,
   'CacheFileName',   TFileNameProperty
  );


{  RegisterPropertyEditor(TypeInfo(TOwnedCollection),TGeneratorsCache,
   'Generators',   TpFIBGeneratorsProperty
  );
{  RegisterPropertyEditor(TypeInfo(TCollection), TCustomDBGridEh, 'Columns', TDBGridEhColumnsProperty);
}
  RegisterPropertyEditor(TypeInfo(TStrings), TransactionClass, 'TRParams',
   TpFIBTRParamsEditor
  );

    if Assigned(expServicesClass) then
     RegisterPropertyEditor(TypeInfo(string), expServicesClass, 'LibraryName', TFileNameProperty);

     RegisterPropertyEditor(TypeInfo(string), DeltaReceiver,
      'TableName', TTableNameEditDR
      );

    RegisterComponentEditor(TComponentClass(DeltaReceiver), TpFIBDeltaReceiverEditor);

    {$IFDEF D6+}
     RegisterPropertiesInCategory('Transactions',['*Transaction*'] );
    {$ENDIF}
   except
   end;
  end;
begin
  // RegisterSplashScreen;
  {$ifdef internal}
  // RegisterFIBUtils;
  RegisterEditors;
  {$else}
  {$I include\aspr_crypt_begin1.inc}  // trial
//  MessageBox(0, 'trial', '', mb_ok);
  RegisterEditors;
  DemoTimer := TDemoTimer.Create;
  {$I include\aspr_crypt_end1.inc}
  {$I include\aspr_crypt_begin2.inc}  // single user
//  MessageBox(0, 'single', '', mb_ok);
  RegisterFIBUtils;
  RegisterEditors;
  CheckLicense := TCheckLicense.Create(k);
  NotifierIndex := (BorlandIDEServices as IOTAServices).AddNotifier(TIDEIOTAFibPlus.Create);
  {$I include\aspr_crypt_end2.inc}
  {$I include\aspr_crypt_begin3.inc}  // multi user
//  MessageBox(0, 'multi', '', mb_ok);
  RegisterFIBUtils;
  RegisterEditors;
  {$I include\aspr_crypt_end3.inc}
  RegisterPackageWizard(TMenuIOTAFibPlus.create as IOTAWizard);
  {$endif}
end;




{ TFIBSQLMemo }

constructor TFIBSQLMemo.Create(AOwner: TComponent);
begin
  inherited;
  ScrollBars:=ssBoth;
end;

function TFIBSQLMemo.GetCaretX: integer;
begin
 Result:=CaretPos.X
end;

function TFIBSQLMemo.GetCaretY: integer;
begin
 Result:=CaretPos.Y
end;

function TFIBSQLMemo.GetLines: TStrings;
begin
  Result:=Lines
end;

function TFIBSQLMemo.GetModified: Boolean;
begin
  Result:=Modified
end;


function TFIBSQLMemo.GetReadOnly: boolean;
begin
 Result:=ReadOnly
end;


procedure TFIBSQLMemo.ScreenPosToTextPos(const ScrX,ScrY:Integer; var DestX,DestY:Integer ); // для драг дропа
begin
 DestX:=-1
end;

procedure TFIBSQLMemo.iSetCaretPos(X,Y:integer);
begin

end;

procedure TFIBSQLMemo.SetModified(Value: Boolean);
begin
 Modified:=Value
end;


procedure TFIBSQLMemo.SetReadOnly(Value: boolean);
begin
  inherited ReadOnly:=Value
end;


{$ifndef internal}
procedure RegisterModule;
const
  RegKey = 'Devrace\FibPlus\7.2';
var
  Crypt: TDev_class8;   //Tea
  Crypt2: TDev_class10;  //Ice
  tempkey: HKey;
  keyClass: array[0..256] of AnsiChar;
  KeySize: DWord;
  work, Hardware: AnsiString;
  I: Integer;
  info, username, key: Ansistring;
  t: AnsiChar;
begin
  DemoTimer := nil;
  CheckLicense := nil;
  NotifierIndex := -MAXWORD;

  LicensedTo := 'Craked version';
  Crypt := TDev_class8.Create(nil);
  Crypt2 := TDev_class10.Create(nil);
  try
    if RegOpenKeyEx(HKEY_CURRENT_USER, 'Software\' + RegKey, 0, KEY_QUERY_VALUE, tempkey) = ERROR_SUCCESS then
    begin
      KeySize := 256;
      RegQueryInfoKeyA(tempkey, keyClass, @KeySize, nil, nil, nil, nil, nil, nil, nil, nil, nil);
      RegCloseKey(TempKey);
      Hardware := GetHardID;
      Hardware := Hardware + StringOfChar('\', Length(RegKey) - Length(Hardware));
      work := '';
      for I := 1 to Length(RegKey) do
        work := work + AnsiChar(Byte(Ord(Hardware[i]) + Ord(RegKey[i])));

      crypt.InitStr(work, TDev_hash2); //MD5
      info := crypt.WorkDSt(keyclass);
      username := Copy(info, 1, Pos(#1, Info) - 1);
      LicensedTo := username;
      key := copy(info, Pos(#1, Info) + 1, Length(info));
      k := key;
      crypt2.InitStr(username, TDev_hash3);  //RipeMD-128
      key := key + '==';
      key := Crypt2.WorkDSt(key);

      t := key[1]; key[1] := key[30]; key[30] := t;
      t := key[3]; key[3] := key[32]; key[32] := t;
      t := key[6]; key[6] := key[35]; key[35] := t;
      t := key[8]; key[8] := key[37]; key[37] := t;
      t := key[10]; key[10] := key[39]; key[39] := t;
      t := key[12]; key[12] := key[41]; key[41] := t;
      t := key[14]; key[14] := key[43]; key[43] := t;

//      MessageBoxa(0, PAnsiChar(key), PAnsiChar(username), mb_ok) ;
      CheckKeyAndDecrypt(PAnsiChar(key), PAnsiChar(username), False);
;
//      k := key;
    end;
  finally
    Crypt.Burn;
    Crypt.Free;
    Crypt2.Burn;
    Crypt2.Free;
  end;
end;
{$endif}

{$ifndef internal}
{ TMenuIOTACleverFilter }

procedure TMenuIOTAFibPlus.Execute;
var
  Msg: string;
begin
  {$I include\userpolybuffer.inc}
  Msg := 'FibPlus version 7.2.'#13#10'Copyright (c) Devrace Ltd, S.A.'#13#10;
  if Assigned(DemoTimer)
    then Msg := Msg + 'Trial version'
    else Msg := Msg + 'Registered on ' + LicensedTo;
  if Assigned(CheckLicense) then
    Msg := Msg + #13#10'Running instance: ' + IntToStr(CheckLicense.InstanceCount);

  if BorlandIDEServices <> nil then
    MessageDlg(Msg, mtInformation, [mbOk], 0{$IFDEF D10+}, mbOK{$ENDIF});
end;

function TMenuIOTAFibPlus.GetIDString: string;
begin
  Result := 'Devrace.FibPlus';
end;

function TMenuIOTAFibPlus.GetMenuText: string;
begin
  Result := 'About Devrace FibPlus';
end;

function TMenuIOTAFibPlus.GetName: string;
begin
  Result := 'AboutDevraceFibPlus';
end;

function TMenuIOTAFibPlus.GetState: TWizardState;
begin
  Result := [wsEnabled];
end;

{ TIDEIOTACleverFilter }

procedure TIDEIOTAFibPlus.AfterCompile(Succeeded: Boolean);
begin

end;

procedure TIDEIOTAFibPlus.AfterCompile(Succeeded, IsCodeInsight: Boolean);
begin

end;

procedure TIDEIOTAFibPlus.BeforeCompile(const Project: IOTAProject;
  IsCodeInsight: Boolean; var Cancel: Boolean);
begin
  {$I include\userpolybuffer.inc}
  Cancel := not (Assigned(CheckLicense) and CheckLicense.IsValid);
  if Cancel then
    (BorlandIDEServices as IOTAMessageServices).AddTitleMessage('The compilation of the project has been stopped because of the violation of the license agreement: the current registration key is being used on multiple computers simultaneously.');
end;

procedure TIDEIOTAFibPlus.BeforeCompile(const Project: IOTAProject;
  var Cancel: Boolean);
begin
  {$I include\userpolybuffer.inc}
  Cancel := not (Assigned(CheckLicense) and CheckLicense.IsValid);
  if Cancel then
    (BorlandIDEServices as IOTAMessageServices).AddTitleMessage('The compilation of the project has been stopped because of the violation of the license agreement: the current registration key is being used on multiple computers simultaneously.');
end;

procedure TIDEIOTAFibPlus.FileNotification(
  NotifyCode: TOTAFileNotification; const FileName: string;
  var Cancel: Boolean);
begin
  {$I include\userpolybuffer.inc}
  Cancel := not (Assigned(CheckLicense) and CheckLicense.IsValid);
  if Cancel then
    (BorlandIDEServices as IOTAMessageServices).AddTitleMessage('The compilation of the project has been stopped because of the violation of the license agreement: the current registration key is being used on multiple computers simultaneously.');
end;

procedure CleanupModule;
begin
  {$I include\userpolybuffer.inc}
  if Assigned(DemoTimer) then FreeAndNil(DemoTimer);
  if Assigned(CheckLicense) then FreeAndNil(CheckLicense);
  if NotifierIndex <> -MAXWORD then
    (BorlandIDEServices as IOTAServices).RemoveNotifier(NotifierIndex);
end;

{$endif}
procedure TFIBSQLMemo.ISetProposalItems(ts1, ts2: TStrings);
begin

end;

procedure TFIBSQLMemo.AddProposal(const aName: string);
begin

end;

procedure TFIBSQLMemo.AddToCurrentProposal(ts, ts1: TStrings);
begin

end;

procedure TFIBSQLMemo.ApplyProposal(const aName: string);
begin

end;

procedure TFIBSQLMemo.ClearProposal;
begin

end;

procedure TFIBSQLMemo.SaveProposals(const aName: string);
begin

end;

function TFIBSQLMemo.GetBeforePropCall: TiBeforeProposalCall;
begin
 Result:=nil
end;

procedure TFIBSQLMemo.SetBeforePropCall(Event: TiBeforeProposalCall);
begin

end;

function TFIBSQLMemo.GetPosInText: Integer;
begin

end;

initialization
{$ifndef internal}
  RegisterModule;
{$endif}
// RegisterFIBSQLTextEditor(TFIBSQLMemo)
//  AppHandleException:=Application.HandleException;
finalization
{$ifndef internal}
  CleanupModule;
{$endif}
end.


