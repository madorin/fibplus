{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ InterBase databases                                           }
{                                                               }
{    FIBPlus is based in part on the product                    }
{    Free IB Components, written by Gregory H. Deatz for        }
{    Hoagland, Longo, Moran, Dunst & Doukas Company.            }
{    mailto:gdeatz@hlmdd.com                                    }
{                                                               }
{    Copyright (c) 1998-2007 Devrace Ltd.                       }
{    Written by Serge Buzadzhy                                  }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit DSContainer;

interface

{$I FIB.inc}

uses
  SysUtils, Classes, DB, FIBProps;

type

  TFIBDataSetEventKind = (
    deBeforeOpen,
    deAfterOpen,
    deBeforeClose,
    deAfterClose,
    deBeforeInsert,
    deAfterInsert,
    deBeforeEdit,
    deAfterEdit,
    deBeforePost,
    deAfterPost,
    deBeforeCancel,
    deAfterCancel,
    deBeforeDelete,
    deAfterDelete,
    deBeforeScroll,
    deAfterScroll,
    deOnNewRecord,
    deOnCalcFields,
    deBeforeRefresh,
    deAfterRefresh
  );

  TFIBDataSetErrorKind = (deOnEditError, deOnPostError, deOnDeleteError);

  TFIBApplyDefaultValueEvent = procedure(DataSet: TDataSet; Field: TField; var Applied: Boolean) of object;
  TFIBApplyFieldRepositoryEvent = procedure(DataSet: TDataSet; Field: TField; FieldInfo: TFIBFieldInfo) of object;

  TFIBDataSetEvent = procedure(DataSet: TDataSet; Event: TFIBDataSetEventKind) of object;
  TFIBDataSetErrorEvent = procedure(DataSet: TDataSet; Event: TFIBDataSetErrorKind; E: EDatabaseError; var Action: TDataAction) of object;

  TFIBCompareFieldValuesEvent = function(Field: TField; const S1, S2: Variant; var Compared: Boolean): Integer of object;
  TDataSetsContainer = class;

  TDataSetsContainer = class(TComponent)
  private
    FActive: Boolean;
    FMasterContainer: TDataSetsContainer;
    FOnDataSetEvent: TFIBDataSetEvent;
    FOnApplyDefaultValue: TFIBApplyDefaultValueEvent;
    FOnApplyFieldRepository: TFIBApplyFieldRepositoryEvent;
    FOnDataSetError: TFIBDataSetErrorEvent;
    FOnCompareFieldValues: TFIBCompareFieldValuesEvent;
    FOnReadBlobField: TFIBBlobFieldProcessingEvent;
    FOnWriteBlobField: TFIBBlobFieldProcessingEvent;
    FDataSetsList: TList;
    FIsGlobalContainer: Boolean;
    procedure SetMasterContainer(Value: TDataSetsContainer);
    procedure CheckCircularMaster(Value: TDataSetsContainer);
    procedure SetIsGlobalContainer(const Value: Boolean);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AddDataSet(Value: TDataSet);
    procedure RemoveDataSet(Value: TDataSet);
    procedure DataSetEvent(DataSet: TDataSet; Event: TFIBDataSetEventKind);
    procedure DoOnApplyDefaultValue(DataSet: TDataSet; Field: TField; var Applied: Boolean);
    procedure DoOnApplyFieldRepository(DataSet: TDataSet; Field: TField; FieldInfo: TFIBFieldInfo);
    procedure DataSetError(DataSet: TDataSet; Event: TFIBDataSetErrorKind; E: EDatabaseError; var Action: TDataAction);
    function DataSetCompareFieldValues(DataSet: TDataSet; Field: TField; const S1, S2: Variant; var Res: Integer): Boolean;
    procedure DoOnReadBlobField(Field: TBlobField; BlobSize: Integer; Progress: Integer; var Stop: Boolean);
    procedure DoOnWriteBlobField(Field: TBlobField; BlobSize: Integer; Progress: Integer; var Stop: Boolean);
    function DataSetCount: Integer;
    function DataSet(Index: Integer): TDataSet;
  published
    property Active: Boolean read FActive write FActive default true;
    property OnDataSetEvent: TFIBDataSetEvent read FOnDataSetEvent write FOnDataSetEvent;
    property OnDataSetError: TFIBDataSetErrorEvent read FOnDataSetError write FOnDataSetError;
    property OnApplyDefaultValue: TFIBApplyDefaultValueEvent read FOnApplyDefaultValue write FOnApplyDefaultValue;
    property OnApplyFieldRepository: TFIBApplyFieldRepositoryEvent read FOnApplyFieldRepository write FOnApplyFieldRepository;
    property MasterContainer: TDataSetsContainer read FMasterContainer write SetMasterContainer;
    property OnCompareFieldValues: TFIBCompareFieldValuesEvent read FOnCompareFieldValues write FOnCompareFieldValues;
    property IsGlobalContainer: Boolean read FIsGlobalContainer write SetIsGlobalContainer default false;
    property OnReadBlobField: TFIBBlobFieldProcessingEvent read FOnReadBlobField write FOnReadBlobField;
    property OnWriteBlobField: TFIBBlobFieldProcessingEvent read FOnWriteBlobField write FOnWriteBlobField;
  end;

function GlobalContainer: TDataSetsContainer;

type
  // Deprecated names of the types renamed in 8.0.0
  TKindDataSetEvent = TFIBDataSetEventKind deprecated 'Use TFIBDataSetEventKind';
  TKindDataSetError = TFIBDataSetErrorKind deprecated 'Use TFIBDataSetErrorKind';
  TOnApplyDefaultValue = TFIBApplyDefaultValueEvent deprecated 'Use TFIBApplyDefaultValueEvent';
  TOnApplyFieldRepository = TFIBApplyFieldRepositoryEvent deprecated 'Use TFIBApplyFieldRepositoryEvent';
  TOnDataSetEvent = TFIBDataSetEvent deprecated 'Use TFIBDataSetEvent';
  TOnDataSetError = TFIBDataSetErrorEvent deprecated 'Use TFIBDataSetErrorEvent';
  TOnCompareFieldValues = TFIBCompareFieldValuesEvent deprecated 'Use TFIBCompareFieldValuesEvent';

implementation

uses
{$IFDEF C24}
  System.Types, // for inline funcs
{$ENDIF}
  StrUtil, FIBConsts;

threadvar CurrentGlobalContainer: TDataSetsContainer;

function GlobalContainer: TDataSetsContainer;
begin
  Result := CurrentGlobalContainer
end;

constructor TDataSetsContainer.Create(AOwner: TComponent); // override;
begin
  inherited Create(AOwner);
  FActive := true;
  FDataSetsList := TList.Create;
end;

destructor TDataSetsContainer.Destroy; // override;
begin
  if CurrentGlobalContainer = Self then
    CurrentGlobalContainer := nil;
  inherited Destroy;
  FDataSetsList.Free;
end;

procedure TDataSetsContainer.Notification(AComponent: TComponent; Operation: TOperation); // override;
begin
  if (Operation = opRemove) then
    begin
      if AComponent <> FMasterContainer then
        FDataSetsList.Remove(AComponent);
      if AComponent = FMasterContainer then
        FMasterContainer := nil;
    end;
  inherited Notification(AComponent, Operation)
end;

procedure TDataSetsContainer.DataSetEvent(DataSet: TDataSet; Event: TFIBDataSetEventKind);
begin
  if Assigned(FMasterContainer) then
    FMasterContainer.DataSetEvent(DataSet, Event);
  if Active then
    begin
      if Assigned(FOnDataSetEvent) then
        FOnDataSetEvent(DataSet, Event)
    end;
end;

procedure TDataSetsContainer.DoOnApplyDefaultValue(DataSet: TDataSet; Field: TField; var Applied: Boolean);
begin
  if Assigned(FMasterContainer) then
    FMasterContainer.DoOnApplyDefaultValue(DataSet, Field, Applied);
  if Active then
    begin
      if Assigned(FOnApplyDefaultValue) then
        FOnApplyDefaultValue(DataSet, Field, Applied)
    end;
end;

procedure TDataSetsContainer.DataSetError(DataSet: TDataSet; Event: TFIBDataSetErrorKind; E: EDatabaseError; var Action: TDataAction);
begin
  if Assigned(FMasterContainer) then
    FMasterContainer.DataSetError(DataSet, Event, E, Action);
  if Active then
    begin
      if Assigned(FOnDataSetError) then
        FOnDataSetError(DataSet, Event, E, Action)
    end;
end;

procedure TDataSetsContainer.SetMasterContainer(Value: TDataSetsContainer);
var
  i: Integer;
begin
  CheckCircularMaster(Value);
  if FMasterContainer <> nil then
    for i := 0 to DataSetCount - 1 do
      FMasterContainer.RemoveDataSet(DataSet(i));
  FMasterContainer := Value;
  if Value <> nil then
    begin
      Value.FreeNotification(Self);
      for i := 0 to DataSetCount - 1 do
        Value.AddDataSet(DataSet(i))
    end;
end;

procedure TDataSetsContainer.CheckCircularMaster(Value: TDataSetsContainer);
var
  CurContainer: TDataSetsContainer;
begin
  if Value = Self then
    raise Exception.Create(SFIBErrorCircularLinks);
  CurContainer := Value;
  while CurContainer <> nil do
    if CurContainer.MasterContainer = Self then
      raise Exception.Create(SFIBErrorCircularLinks)
    else
      CurContainer := CurContainer.MasterContainer;
end;

procedure TDataSetsContainer.AddDataSet(Value: TDataSet);
begin
  if Value <> nil then
    begin
      if FDataSetsList.IndexOf(Value) = -1 then
        FDataSetsList.Add(Value);
      if MasterContainer <> nil then
        MasterContainer.AddDataSet(Value);
      Value.FreeNotification(Self)
    end;
end;

procedure TDataSetsContainer.RemoveDataSet(Value: TDataSet);
begin
  if FDataSetsList.IndexOf(Value) <> -1 then
    FDataSetsList.Remove(Value);
  if MasterContainer <> nil then
    MasterContainer.RemoveDataSet(Value);
end;

function TDataSetsContainer.DataSetCount: Integer;
begin
  Result := Integer(FDataSetsList.Count)
end;

function TDataSetsContainer.DataSet(Index: Integer): TDataSet;
begin
  if (Index < FDataSetsList.Count) and (Index > -1) then
    Result := TDataSet(FDataSetsList[Index])
  else
    Result := nil
end;

function TDataSetsContainer.DataSetCompareFieldValues(DataSet: TDataSet; Field: TField; const S1, S2: Variant; var Res: Integer): Boolean;
begin
  Result := False;
  if Assigned(FOnCompareFieldValues) then
    Res := FOnCompareFieldValues(Field, S1, S2, Result);
end;

procedure TDataSetsContainer.SetIsGlobalContainer(const Value: Boolean);
begin
  FIsGlobalContainer := Value;
  if not(csDesigning in ComponentState) then
    begin
      if Value then
        begin
          if Assigned(CurrentGlobalContainer) and (CurrentGlobalContainer <> Self) then
            CurrentGlobalContainer.FIsGlobalContainer := false;
          CurrentGlobalContainer := Self
        end
      else if not Value and (CurrentGlobalContainer = Self) then
        CurrentGlobalContainer := nil
    end;
end;

procedure TDataSetsContainer.DoOnApplyFieldRepository(DataSet: TDataSet; Field: TField; FieldInfo: TFIBFieldInfo);
begin
  if Assigned(FMasterContainer) then
    FMasterContainer.DoOnApplyFieldRepository(DataSet, Field, FieldInfo);
  if Active then
    begin
      if Assigned(FOnApplyFieldRepository) then
        FOnApplyFieldRepository(DataSet, Field, FieldInfo)
    end;
end;

procedure TDataSetsContainer.DoOnReadBlobField(Field: TBlobField; BlobSize, Progress: Integer; var Stop: Boolean);
begin
  if Assigned(FOnReadBlobField) then
    FOnReadBlobField(Field, BlobSize, Progress, Stop)
end;

procedure TDataSetsContainer.DoOnWriteBlobField(Field: TBlobField; BlobSize, Progress: Integer; var Stop: Boolean);
begin
  if Assigned(FOnWriteBlobField) then
    FOnWriteBlobField(Field, BlobSize, Progress, Stop)
end;

initialization

CurrentGlobalContainer := nil;

end.
