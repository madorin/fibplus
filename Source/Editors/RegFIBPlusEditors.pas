unit RegFIBPlusEditors;

interface

{$I ..\FIBPlus.inc}

uses
  Windows, Classes,
{$IFDEF D_XE2}
  Vcl.StdCtrls, Vcl.Forms, Vcl.ExtCtrls, Vcl.Dialogs,
{$ELSE}
  StdCtrls, Forms, ExtCtrls, Dialogs,
{$ENDIF}
  SysUtils, pFIBInterfaces, TypInfo, FIBDatabase,
  DesignEditors, DesignIntf, Variants // ,Types

  ;

type

  TiBeforeProposalCall = procedure(const ProposalName: string) of object;

  IFIBSQLTextEditor = interface
    ['{59B98703-4324-43AA-A656-5842806E35B2}']
    function GetReadOnly: boolean;
    procedure SetReadOnly(Value: boolean);
    function GetLines: TStrings;
    procedure SetLines(Value: TStrings);
    function GetSelStart: Integer;
    procedure SetSelStart(Value: Integer);
    function GetSelLength: Integer;
    procedure SetSelLength(Value: Integer);
    function GetCaretX: Integer;
    function GetCaretY: Integer;
    procedure iSetCaretPos(X, Y: Integer);
    procedure ScreenPosToTextPos(const ScrX, ScrY: Integer; var DestX, DestY: Integer); // for drag and drop

    procedure ISetProposalItems(ts1, ts2: TStrings);
    procedure SaveProposals(const aName: string);
    procedure ApplyProposal(const aName: string);
    procedure AddToCurrentProposal(ts, ts1: TStrings);
    procedure AddProposal(const aName: string);
    procedure ClearProposal;
    function GetBeforePropCall: TiBeforeProposalCall;
    procedure SetBeforePropCall(Event: TiBeforeProposalCall);
    function GetPosInText: Integer;
    procedure SelectAll;
    function GetModified: boolean;
    procedure SetModified(Value: boolean);
    procedure SetFocus;
    property SelLength: Integer read GetSelLength write SetSelLength;
    property SelStart: Integer read GetSelStart write SetSelStart;
    property ReadOnly: boolean read GetReadOnly write SetReadOnly;
    property Lines: TStrings read GetLines write SetLines;
    property CaretX: Integer read GetCaretX;
    property CaretY: Integer read GetCaretY;
    property DoBeforeProposalCall: TiBeforeProposalCall read GetBeforePropCall write SetBeforePropCall;
    property PosInText: Integer read GetPosInText;
  end;

  { TODO 1 : Plug in the tools. Check that it compiles under D6, port to D2009 }

procedure RegisterFIBSQLTextEditor(Editor: TClass);
function GetSQLTextEditor: TClass;

procedure Register;

implementation

uses
  pFIBComponentEditors, ToolsAPI, RegSynEditAlt {, FIBSplash};

var
  vSQLTextEditorClass: TClass;

type
  TFIBSQLMemo = class(TMemo, IFIBSQLTextEditor)
  private
    function GetReadOnly: boolean;
    procedure SetReadOnly(Value: boolean);
    function GetLines: TStrings;
    function GetCaretX: Integer;
    function GetCaretY: Integer;
    function GetModified: boolean;
    procedure SetModified(Value: boolean);
    procedure iSetCaretPos(X, Y: Integer);
    procedure ISetProposalItems(ts1, ts2: TStrings);
    procedure SaveProposals(const aName: string);
    procedure ApplyProposal(const aName: string);
    procedure AddToCurrentProposal(ts, ts1: TStrings);
    procedure AddProposal(const aName: string);
    procedure ClearProposal;
    function GetBeforePropCall: TiBeforeProposalCall;
    procedure SetBeforePropCall(Event: TiBeforeProposalCall);
    function GetPosInText: Integer;
    procedure ScreenPosToTextPos(const ScrX, ScrY: Integer; var DestX, DestY: Integer); // for drag and drop
  public
    constructor Create(AOwner: TComponent); override;
  end;

procedure RegisterFIBSQLTextEditor(Editor: TClass);
begin
  if Assigned(Editor) then
    vSQLTextEditorClass := Editor
  else
    vSQLTextEditorClass := TFIBSQLMemo
end;

function GetSQLTextEditor: TClass;
begin
  if Assigned(vSQLTextEditorClass) then
    Result := vSQLTextEditorClass
  else
    Result := TFIBSQLMemo
end;

procedure Register;
  procedure RegisterEditors;
  var
    DatabaseClass: TClass;
    QueryClass: TClass;
    DatasetClass: TClass;
    DeltaReceiver: TClass;
    TransactionClass: TClass;
    pi: PPropInfo;
    auClass: TClass;
  begin
    try
      // database  Properties
      DatabaseClass := expDatabaseClass;
      TransactionClass := expTransactionClass;
      QueryClass := expQueryClass;
      DatasetClass := expDatasetClass;
      DeltaReceiver := expDeltaReceiverClass;
      RegisterPropertyEditor(TypeInfo(string), DatabaseClass, 'AliasName', TFIBAliasEdit);
      RegisterPropertyEditor(TypeInfo(string), DatabaseClass, 'DBName', TFileNameProperty);
      RegisterPropertyEditor(TypeInfo(string), DatabaseClass, 'LibraryName', TFileNameProperty);
      RegisterPropertyEditor(TypeInfo(TNotifyEvent), DatabaseClass, 'OnConnect', nil);
      pi := GetPropInfo(DatabaseClass, 'OnLogin');
      if pi <> nil then
        RegisterPropertyEditor(pi.PropType^, DatabaseClass, 'OnLogin', nil);

      RegisterComponentEditor(TComponentClass(DatabaseClass), TpFIBDatabaseEditor);
      RegisterComponentEditor(TComponentClass(TransactionClass), TpFIBTransactionEditor);
      RegisterComponentEditor(TComponentClass(QueryClass), TpFIBQueryEditor);
      RegisterComponentEditor(TComponentClass(DatasetClass), TFIBGenSQlEd);

      pi := GetPropInfo(QueryClass, 'Conditions');
      RegisterPropertyEditor(pi.PropType^, nil, 'Conditions', TFIBConditionsEditor);

      pi := GetPropInfo(DatasetClass, 'Options');
      RegisterPropertyEditor(pi.PropType^, nil, 'Options', TpFIBDataSetOptionsEditor);
      pi := GetPropInfo(DatasetClass, 'PrepareOptions');
      RegisterPropertyEditor(pi.PropType^, nil, 'PrepareOptions', TpFIBDataSetOptionsEditor);
      pi := GetPropInfo(DatasetClass, 'AutoUpdateOptions');
      RegisterPropertyEditor(pi.PropType^, DatasetClass, 'AutoUpdateOptions', TpFIBAutoUpdateOptionsEditor);

      auClass := GetTypeData(pi^.PropType^).ClassType;
      RegisterPropertyEditor(TypeInfo(TStrings), auClass, 'ParamsToFieldsLinks', TEdParamToFields);
      RegisterPropertyEditor(TypeInfo(string), auClass, 'GeneratorName', TGeneratorNameEdit);

      RegisterPropertyEditor(TypeInfo(string), auClass, 'KeyFields', TKeyFieldNameEdit);

      RegisterPropertyEditor(TypeInfo(string), auClass, 'UpdateTableName', TTableNameEdit);

      RegisterPropertyEditor(TypeInfo(Integer), DatasetClass, 'DataSet_ID', TDataSet_ID_Edit);

      RegisterPropertyEditor(TypeInfo(TStrings), DatasetClass, 'SelectSQL', nil);
      RegisterPropertyEditor(TypeInfo(TStrings), DatasetClass, 'InsertSQL', nil);
      RegisterPropertyEditor(TypeInfo(TStrings), DatasetClass, 'UpdateSQL', nil);
      RegisterPropertyEditor(TypeInfo(TStrings), DatasetClass, 'DeleteSQL', nil);
      RegisterPropertyEditor(TypeInfo(TStrings), DatasetClass, 'RefreshSQL', nil);
      RegisterPropertyEditor(TypeInfo(boolean), DatasetClass, 'WaitEndMasterScroll', nil);

      pi := GetPropInfo(DatasetClass, 'SQLs');
      RegisterPropertyEditor(TypeInfo(TStrings), GetTypeData(pi^.PropType^).ClassType, '', TFIBSQLsProperty);

      RegisterPropertyEditor(pi.PropType^, DatasetClass, '', TFIBSQLsProperties);

      RegisterPropertyEditor(TypeInfo(string), QueryClass, 'StoredProcName', TpFIBStoredProcProperty);

      RegisterPropertyEditor(TypeInfo(TStrings), QueryClass, 'SQL', TpFIBSQLPropEdit);

      RegisterPropertyEditor(TypeInfo(string), TransactionClass, 'UserKindTransaction', TFIBTrKindEdit);

      pi := GetPropInfo(DatabaseClass, 'GeneratorsCache');
      auClass := GetTypeData(pi^.PropType^).ClassType;
      RegisterPropertyEditor(TypeInfo(TOwnedCollection), auClass, 'GeneratorList', TpFIBGeneratorsProperty);

      RegisterPropertyEditor(TypeInfo(string), auClass, 'CacheFileName', TFileNameProperty);

      { RegisterPropertyEditor(TypeInfo(TOwnedCollection),TGeneratorsCache,
        'Generators',   TpFIBGeneratorsProperty
        );
        {  RegisterPropertyEditor(TypeInfo(TCollection), TCustomDBGridEh, 'Columns', TDBGridEhColumnsProperty);
      }
      RegisterPropertyEditor(TypeInfo(TStrings), TransactionClass, 'TRParams', TpFIBTRParamsEditor);

      if Assigned(expServicesClass) then
        RegisterPropertyEditor(TypeInfo(string), expServicesClass, 'LibraryName', TFileNameProperty);

      RegisterPropertyEditor(TypeInfo(string), DeltaReceiver, 'TableName', TTableNameEditDR);

      RegisterComponentEditor(TComponentClass(DeltaReceiver), TpFIBDeltaReceiverEditor);

      RegisterPropertiesInCategory('Transactions', ['*Transaction*']);
    except
    end;
  end;

begin
  // RegisterSplashScreen;
  RegisterEditors;
end;

{ TFIBSQLMemo }

constructor TFIBSQLMemo.Create(AOwner: TComponent);
begin
  inherited;
  ScrollBars := ssBoth;
end;

function TFIBSQLMemo.GetCaretX: Integer;
begin
  Result := CaretPos.X
end;

function TFIBSQLMemo.GetCaretY: Integer;
begin
  Result := CaretPos.Y
end;

function TFIBSQLMemo.GetLines: TStrings;
begin
  Result := Lines
end;

function TFIBSQLMemo.GetModified: boolean;
begin
  Result := Modified
end;

function TFIBSQLMemo.GetReadOnly: boolean;
begin
  Result := ReadOnly
end;

procedure TFIBSQLMemo.ScreenPosToTextPos(const ScrX, ScrY: Integer; var DestX, DestY: Integer); // for drag and drop
begin
  DestX := -1
end;

procedure TFIBSQLMemo.iSetCaretPos(X, Y: Integer);
begin

end;

procedure TFIBSQLMemo.SetModified(Value: boolean);
begin
  Modified := Value
end;

procedure TFIBSQLMemo.SetReadOnly(Value: boolean);
begin
  inherited ReadOnly := Value
end;

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
  Result := nil
end;

procedure TFIBSQLMemo.SetBeforePropCall(Event: TiBeforeProposalCall);
begin

end;

function TFIBSQLMemo.GetPosInText: Integer;
begin
  Result := SelStart;
end;

// RegisterFIBSQLTextEditor(TFIBSQLMemo)
// AppHandleException:=Application.HandleException;

end.
