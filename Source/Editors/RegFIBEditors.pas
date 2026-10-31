unit RegFIBEditors;

interface

{$I ..\FIB.inc}

uses
  Windows, Classes,
{$IFDEF C23}
  Vcl.StdCtrls, Vcl.Forms, Vcl.ExtCtrls, Vcl.Dialogs,
{$ELSE}
  StdCtrls, Forms, ExtCtrls, Dialogs,
{$ENDIF}
  SysUtils, FIBInterfaces, TypInfo, FIBDatabase,
  DesignEditors, DesignIntf, Variants

  ;

type

  TFIBBeforeProposalEvent = procedure(const ProposalName: string) of object;

  IFIBSQLTextEditor = interface
    ['{59B98703-4324-43AA-A656-5842806E35B2}']
    function GetReadOnly: Boolean;
    procedure SetReadOnly(Value: Boolean);
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
    function GetBeforePropCall: TFIBBeforeProposalEvent;
    procedure SetBeforePropCall(Event: TFIBBeforeProposalEvent);
    function GetPosInText: Integer;
    procedure SelectAll;
    function GetModified: Boolean;
    procedure SetModified(Value: Boolean);
    procedure SetFocus;
    property SelLength: Integer read GetSelLength write SetSelLength;
    property SelStart: Integer read GetSelStart write SetSelStart;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly;
    property Lines: TStrings read GetLines write SetLines;
    property CaretX: Integer read GetCaretX;
    property CaretY: Integer read GetCaretY;
    property DoBeforeProposalCall: TFIBBeforeProposalEvent read GetBeforePropCall write SetBeforePropCall;
    property PosInText: Integer read GetPosInText;
  end;

procedure RegisterFIBSQLTextEditor(Editor: TClass);
function GetSQLTextEditor: TClass;

procedure Register;

implementation

uses
  FIBComponentEditors, ToolsAPI, RegSynEditAlt;

var
  SQLTextEditorClass: TClass;

type
  TFIBSQLMemo = class(TMemo, IFIBSQLTextEditor)
  private
    function GetReadOnly: Boolean;
    procedure SetReadOnly(Value: Boolean);
    function GetLines: TStrings;
    function GetCaretX: Integer;
    function GetCaretY: Integer;
    function GetModified: Boolean;
    procedure SetModified(Value: Boolean);
    procedure iSetCaretPos(X, Y: Integer);
    procedure ISetProposalItems(ts1, ts2: TStrings);
    procedure SaveProposals(const aName: string);
    procedure ApplyProposal(const aName: string);
    procedure AddToCurrentProposal(ts, ts1: TStrings);
    procedure AddProposal(const aName: string);
    procedure ClearProposal;
    function GetBeforePropCall: TFIBBeforeProposalEvent;
    procedure SetBeforePropCall(Event: TFIBBeforeProposalEvent);
    function GetPosInText: Integer;
    procedure ScreenPosToTextPos(const ScrX, ScrY: Integer; var DestX, DestY: Integer); // for drag and drop
  public
    constructor Create(AOwner: TComponent); override;
  end;

procedure RegisterFIBSQLTextEditor(Editor: TClass);
begin
  if Assigned(Editor) then
    SQLTextEditorClass := Editor
  else
    SQLTextEditorClass := TFIBSQLMemo
end;

function GetSQLTextEditor: TClass;
begin
  if Assigned(SQLTextEditorClass) then
    Result := SQLTextEditorClass
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
    // database  Properties
    DatabaseClass := expDatabaseClass;
    TransactionClass := expTransactionClass;
    QueryClass := expQueryClass;
    DatasetClass := expDatasetClass;
    DeltaReceiver := expDeltaReceiverClass;
    RegisterPropertyEditor(TypeInfo(string), DatabaseClass, 'AliasName', TFIBAliasEdit);
    RegisterPropertyEditor(TypeInfo(string), DatabaseClass, 'DBName', TFIBFileNameProperty);
    RegisterPropertyEditor(TypeInfo(string), DatabaseClass, 'LibraryName', TFIBFileNameProperty);
    RegisterPropertyEditor(TypeInfo(TNotifyEvent), DatabaseClass, 'OnConnect', nil);
    pi := GetPropInfo(DatabaseClass, 'OnLogin');
    if pi <> nil then
      RegisterPropertyEditor(pi.PropType^, DatabaseClass, 'OnLogin', nil);

    RegisterComponentEditor(TComponentClass(DatabaseClass), TFIBDatabaseEditor);
    RegisterComponentEditor(TComponentClass(TransactionClass), TFIBTransactionEditor);
    RegisterComponentEditor(TComponentClass(QueryClass), TFIBQueryEditor);
    RegisterComponentEditor(TComponentClass(DatasetClass), TFIBDataSetEditor);

    pi := GetPropInfo(QueryClass, 'Conditions');
    RegisterPropertyEditor(pi.PropType^, nil, 'Conditions', TFIBConditionsEditor);

    pi := GetPropInfo(DatasetClass, 'Options');
    RegisterPropertyEditor(pi.PropType^, nil, 'Options', TFIBDataSetOptionsEditor);
    pi := GetPropInfo(DatasetClass, 'PrepareOptions');
    RegisterPropertyEditor(pi.PropType^, nil, 'PrepareOptions', TFIBDataSetOptionsEditor);
    pi := GetPropInfo(DatasetClass, 'AutoUpdateOptions');
    RegisterPropertyEditor(pi.PropType^, DatasetClass, 'AutoUpdateOptions', TFIBAutoUpdateOptionsEditor);

    auClass := GetTypeData(pi^.PropType^).ClassType;
    RegisterPropertyEditor(TypeInfo(TStrings), auClass, 'ParamsToFieldsLinks', TFIBParamsToFieldsProperty);
    RegisterPropertyEditor(TypeInfo(string), auClass, 'GeneratorName', TFIBGeneratorNameProperty);

    RegisterPropertyEditor(TypeInfo(string), auClass, 'KeyFields', TFIBKeyFieldsProperty);

    RegisterPropertyEditor(TypeInfo(string), auClass, 'UpdateTableName', TFIBUpdateTableNameProperty);

    RegisterPropertyEditor(TypeInfo(Integer), DatasetClass, 'DataSet_ID', TFIBDataSetIDProperty);

    RegisterPropertyEditor(TypeInfo(TStrings), DatasetClass, 'SelectSQL', nil);
    RegisterPropertyEditor(TypeInfo(TStrings), DatasetClass, 'InsertSQL', nil);
    RegisterPropertyEditor(TypeInfo(TStrings), DatasetClass, 'UpdateSQL', nil);
    RegisterPropertyEditor(TypeInfo(TStrings), DatasetClass, 'DeleteSQL', nil);
    RegisterPropertyEditor(TypeInfo(TStrings), DatasetClass, 'RefreshSQL', nil);
    RegisterPropertyEditor(TypeInfo(Boolean), DatasetClass, 'WaitEndMasterScroll', nil);

    pi := GetPropInfo(DatasetClass, 'SQLs');
    RegisterPropertyEditor(TypeInfo(TStrings), GetTypeData(pi^.PropType^).ClassType, '', TFIBSQLsProperty);

    RegisterPropertyEditor(pi.PropType^, DatasetClass, '', TFIBSQLsProperties);

    RegisterPropertyEditor(TypeInfo(string), QueryClass, 'StoredProcName', TFIBStoredProcProperty);

    RegisterPropertyEditor(TypeInfo(TStrings), QueryClass, 'SQL', TFIBSQLPropEdit);

    RegisterPropertyEditor(TypeInfo(string), TransactionClass, 'UserKindTransaction', TFIBTrKindEdit);

    pi := GetPropInfo(DatabaseClass, 'GeneratorsCache');
    auClass := GetTypeData(pi^.PropType^).ClassType;
    RegisterPropertyEditor(TypeInfo(TOwnedCollection), auClass, 'GeneratorList', TFIBGeneratorsProperty);

    RegisterPropertyEditor(TypeInfo(string), auClass, 'CacheFileName', TFIBFileNameProperty);

    RegisterPropertyEditor(TypeInfo(TStrings), TransactionClass, 'TRParams', TFIBTransactionParamsEditor);

    if Assigned(expServicesClass) then
      RegisterPropertyEditor(TypeInfo(string), expServicesClass, 'LibraryName', TFIBFileNameProperty);

    RegisterPropertyEditor(TypeInfo(string), DeltaReceiver, 'TableName', TFIBDeltaReceiverTableNameProperty);

    RegisterComponentEditor(TComponentClass(DeltaReceiver), TFIBDeltaReceiverEditor);

    RegisterPropertiesInCategory('Transactions', ['*Transaction*']);
  end;

begin
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

function TFIBSQLMemo.GetModified: Boolean;
begin
  Result := Modified
end;

function TFIBSQLMemo.GetReadOnly: Boolean;
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

procedure TFIBSQLMemo.SetModified(Value: Boolean);
begin
  Modified := Value
end;

procedure TFIBSQLMemo.SetReadOnly(Value: Boolean);
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

function TFIBSQLMemo.GetBeforePropCall: TFIBBeforeProposalEvent;
begin
  Result := nil
end;

procedure TFIBSQLMemo.SetBeforePropCall(Event: TFIBBeforeProposalEvent);
begin

end;

function TFIBSQLMemo.GetPosInText: Integer;
begin
  Result := SelStart;
end;

end.
