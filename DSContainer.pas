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
{    Written by Serge Buzadzhy (buzz@devrace.com)               }
{                                                               }
{ ------------------------------------------------------------- }
{    FIBPlus home page: http://www.fibplus.com/                 }
{    FIBPlus support  : http://www.devrace.com/support/         }
{ ------------------------------------------------------------- }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit DSContainer;

interface

{$I FIBPlus.inc}
uses
  SysUtils, Classes, DB,pFIBDataInfo,FIBDataSet;

type

  TKindDataSetEvent = (   deBeforeOpen ,   deAfterOpen,deBeforeClose     ,
      deAfterClose,deBeforeInsert,deAfterInsert,deBeforeEdit,deAfterEdit,
      deBeforePost,deAfterPost,deBeforeCancel,deAfterCancel,deBeforeDelete,
      deAfterDelete,deBeforeScroll,deAfterScroll,deOnNewRecord,deOnCalcFields,
      deBeforeRefresh,deAfterRefresh
     );

  TKindDataSetError=(
   deOnEditError,deOnPostError,deOnDeleteError
  );

  TOnApplyDefaultValue = procedure(DataSet:TDataSet; Field:TField; var Applied:boolean) of  object;
  TOnApplyFieldRepository=procedure(DataSet:TDataSet;Field:TField;FieldInfo:TpFIBFieldInfo) of object;

  TOnDataSetEvent     =procedure (DataSet:TDataSet;Event:TKindDataSetEvent) of object;
  TOnDataSetError     =procedure (DataSet:TDataSet;Event:TKindDataSetError;
      E: EDatabaseError; var Action: TDataAction
  ) of object;

  TOnCompareFieldValues=
   function  (Field:TField;const S1,S2:variant;var Compared:boolean ):integer of object;
{$IFDEF USE_DEPRECATE_METHODS2}
  TUserEvent      =procedure (Sender:TObject;Receiver:TDataSet;const EventName:string;
     var Info :string
  ) of object;
{$ENDIF}

  TDataSetsContainer = class;

  TDataSetsContainer = class(TComponent)
  private
   FActive       :boolean;
   FMasterContainer:TDataSetsContainer;
   FOnDataSetEvent:TOnDataSetEvent;
   FOnApplyDefaultValue:TOnApplyDefaultValue;
   FOnApplyFieldRepository:TOnApplyFieldRepository;
   FOnDataSetError:TOnDataSetError;
   FOnCompareFieldValues:TOnCompareFieldValues;
   FOnReadBlobField:TOnBlobFieldProcessing;
   FOnWriteBlobField:TOnBlobFieldProcessing;

{$IFDEF USE_DEPRECATE_METHODS2}
   FOnUserEvent  :TUserEvent;
{$ENDIF}
   vDataSetsList :TList;
   FIsGlobalContainer:boolean;
   procedure     SetMasterContainer(Value:TDataSetsContainer);
   procedure     CheckCircularMaster(Value:TDataSetsContainer);
   procedure     SetIsGlobalContainer(const Value: boolean);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
   constructor Create(AOwner:Tcomponent);override;
   destructor  Destroy;override;

   procedure AddDataSet(Value:TDataSet);
   procedure RemoveDataSet(Value:TDataSet);
{$IFDEF USE_DEPRECATE_METHODS2}
   procedure NotifyDataSets(Sender:TObject;const UDA,UDE:string;var Info :string);  dynamic; deprecated;
                                                                   //  (UDA - user defined address)
                                                                  //  (UDE - user defined Event)
{$ENDIF}
   procedure DataSetEvent(DataSet:TDataSet;Event:TKindDataSetEvent);
   procedure DoOnApplyDefaultValue(DataSet:TDataSet;Field:TField; var Applied:boolean);
   procedure DoOnApplyFieldRepository(DataSet:TDataSet;Field:TField;FieldInfo:TpFIBFieldInfo);
   procedure DataSetError(DataSet:TDataSet;Event:TKindDataSetError;
    E: EDatabaseError; var Action: TDataAction
   );
   function DataSetCompareFieldValues(DataSet:TDataSet;
      Field:TField;const S1,S2:variant;var Res:integer
   ):boolean;

   procedure DoOnReadBlobField(Field:TBlobField;BlobSize:integer;Progress:integer;var Stop:boolean);
   procedure DoOnWriteBlobField(Field:TBlobField;BlobSize:integer;Progress:integer;var Stop:boolean);

{$IFDEF USE_DEPRECATE_METHODS2}
   procedure UserEvent(Sender:TObject;Receiver:TDataSet;const EventName:string; var Info :string); deprecated;
{$ENDIF}
   function  DataSetCount:integer;
   function  DataSet(Index:integer):TDataSet;
  published
   property Active:boolean  read FActive write FActive default true;
   property OnDataSetEvent  :TOnDataSetEvent read FOnDataSetEvent  write FOnDataSetEvent;
   property OnDataSetError  :TOnDataSetError read FOnDataSetError  write FOnDataSetError;
{$IFDEF USE_DEPRECATE_METHODS2}
   property OnUserEvent     :TUserEvent  read FOnUserEvent write FOnUserEvent;
{$ENDIF}   
   property OnApplyDefaultValue:TOnApplyDefaultValue read FOnApplyDefaultValue write FOnApplyDefaultValue;
   property OnApplyFieldRepository:TOnApplyFieldRepository read FOnApplyFieldRepository write FOnApplyFieldRepository;
   property MasterContainer:TDataSetsContainer read FMasterContainer write SetMasterContainer;
   property OnCompareFieldValues:TOnCompareFieldValues read  FOnCompareFieldValues write FOnCompareFieldValues;
   property IsGlobalContainer:boolean read FIsGlobalContainer write SetIsGlobalContainer default false;
   property OnReadBlobField :TOnBlobFieldProcessing read FOnReadBlobField write FOnReadBlobField;
   property OnWriteBlobField :TOnBlobFieldProcessing read FOnWriteBlobField write FOnWriteBlobField;
  end;

 function GlobalContainer:TDataSetsContainer;

implementation

uses
{$IFDEF D_XE3}
  System.Types, // for inline funcs
{$ENDIF}
 StrUtil,FIBConsts;

threadvar
 vGlobalContainer:TDataSetsContainer;

function GlobalContainer:TDataSetsContainer;
begin
  Result:=vGlobalContainer
end;


constructor TDataSetsContainer.Create(AOwner:Tcomponent);//override;
begin
 inherited Create(AOwner);
 FActive         :=true;
 FMasterContainer :=nil;
 vDataSetsList    :=TList.Create;
end;

destructor  TDataSetsContainer.Destroy;//override;
begin
 inherited Destroy;
 vDataSetsList.Free;
end;

procedure TDataSetsContainer.Notification(AComponent: TComponent; Operation: TOperation); //override;
begin
 if (Operation=opRemove) then
 begin
  if AComponent<>FMasterContainer then vDataSetsList.Remove(AComponent);
  if AComponent=FMasterContainer then FMasterContainer:=nil;
 end;
 inherited Notification(AComponent,Operation)
end;

procedure TDataSetsContainer.DataSetEvent(DataSet:TDataSet;Event:TKindDataSetEvent);
begin
 if Assigned(FMasterContainer) then FMasterContainer.DataSetEvent(DataSet,Event);
 if Active then
 begin
  if Assigned(FOnDataSetEvent) then FOnDataSetEvent(DataSet,Event)
 end;
end;

procedure TDataSetsContainer.DoOnApplyDefaultValue(DataSet:TDataSet;Field:TField; var Applied:boolean);
begin
 if Assigned(FMasterContainer) then FMasterContainer.DoOnApplyDefaultValue(DataSet,Field,Applied);
 if Active then
 begin
  if Assigned(FOnApplyDefaultValue) then FOnApplyDefaultValue(DataSet,Field,Applied)
 end;
end;

procedure TDataSetsContainer.DataSetError(DataSet:TDataSet;Event:TKindDataSetError;
 E: EDatabaseError; var Action: TDataAction);
begin
 if Assigned(FMasterContainer) then FMasterContainer.DataSetError(DataSet,Event,E,Action);
 if Active then
 begin
   if Assigned(FOnDataSetError) then FOnDataSetError(DataSet,Event,E,Action)
 end;
end;

{$IFDEF USE_DEPRECATE_METHODS2}
procedure TDataSetsContainer.UserEvent(Sender:TObject;Receiver:TDataSet;const EventName:string;var Info:string);
begin
 if Assigned(FMasterContainer) then FMasterContainer.UserEvent(Sender,Receiver,EventName,Info);
 if Active then
 begin
   if Assigned(FOnUserEvent) then FOnUserEvent(Sender,Receiver,EventName,Info)
 end;
end;
{$ENDIF}

procedure TDataSetsContainer.SetMasterContainer(Value:TDataSetsContainer);
var i:integer;
begin
  CheckCircularMaster(Value);
  if FMasterContainer<>nil then
    for i:=0 to Pred(vDataSetsList.Count) do
     FMasterContainer.RemoveDataSet(TDataSet(vDataSetsList[i]));
  FMasterContainer:=Value;
  if Value<>nil then
  begin
    Value.FreeNotification(Self);
    for i:=0 to Pred(vDataSetsList.Count) do
     Value.AddDataSet(TDataSet(vDataSetsList[i]))
  end;
end;

procedure TDataSetsContainer.CheckCircularMaster(Value:TDataSetsContainer);
var CurContainer:TDataSetsContainer;
begin
  if Value = Self then raise Exception.Create(SFIBErrorCircularLinks);
  CurContainer:=Value;
  while CurContainer<>nil do
   if   CurContainer.MasterContainer=Self then raise Exception.Create(SFIBErrorCircularLinks)
   else CurContainer:=CurContainer.MasterContainer;
end;


procedure TDataSetsContainer.AddDataSet(Value:TDataSet);
begin
 if Value<>nil then
 begin
  if vDataSetsList.IndexOf(Value)=-1 then vDataSetsList.Add(Value);
  if MasterContainer<>nil then MasterContainer.AddDataSet(Value);
  Value.FreeNotification(Self)
 end;
end;

procedure TDataSetsContainer.RemoveDataSet(Value:TDataSet);
begin
 if vDataSetsList.IndexOf(Value)<>-1 then vDataSetsList.Remove(Value);
 if MasterContainer<>nil then MasterContainer.RemoveDataSet(Value);
end;
{$IFDEF USE_DEPRECATE_METHODS2}
procedure TDataSetsContainer.NotifyDataSets(Sender:TObject;const UDA,UDE:string;var Info :string);
var i:integer;
begin
 for i:=0 to Pred(vDataSetsList.Count) do
 begin
   if (UDA='') or
    WildStringCompare(
     FastUpperCase(TDataSet(vDataSetsList[i]).Owner.Name+'.'+TDataSet(vDataSetsList[i]).Name),
     FastUpperCase(UDA)
    )
   then
   if (TDataSet(vDataSetsList[i]) is TpFibDataSet) then
    with TpFibDataSet(vDataSetsList[i]) do
     if (ReceiveEvents.Count=0) or (WldIndexOf(ReceiveEvents,UDE,false)<>-1 )then
      DoUserEvent(Sender,UDE,Info)
 end;
end;
{$ENDIF}

function  TDataSetsContainer.DataSetCount:integer;
begin
 Result   :=vDataSetsList.Count
end;

function  TDataSetsContainer.DataSet(Index:integer):TDataSet;
begin
  if (Index<vDataSetsList.Count) and (Index>-1) then
   Result :=TDataSet(vDataSetsList[Index])
  else
   Result :=nil
end;


function TDataSetsContainer.DataSetCompareFieldValues(DataSet: TDataSet;
  Field: TField; const S1, S2: variant; var Res:integer): boolean;
begin
 if Assigned(FOnCompareFieldValues) then
  Res:=FOnCompareFieldValues(Field,S1, S2,Result)
 else
  Result := False;
end;

procedure TDataSetsContainer.SetIsGlobalContainer(const Value: boolean);
begin
  FIsGlobalContainer := Value;
  if not (csDesigning in ComponentState)then
  begin
   if Value then
   begin
    if Assigned(vGlobalContainer) and (vGlobalContainer<>Self) then
     vGlobalContainer.FIsGlobalContainer:=False;
    vGlobalContainer:=Self
   end
   else
   if not Value and (vGlobalContainer=Self) then
    vGlobalContainer:=nil
  end;
end;

procedure TDataSetsContainer.DoOnApplyFieldRepository(DataSet: TDataSet;
  Field: TField; FieldInfo: TpFIBFieldInfo);
begin
 if Assigned(FMasterContainer) then FMasterContainer.DoOnApplyFieldRepository(DataSet,Field,FieldInfo);
 if Active then
 begin
  if Assigned(FOnApplyFieldRepository) then FOnApplyFieldRepository(DataSet,Field,FieldInfo)
 end;
end;

procedure TDataSetsContainer.DoOnReadBlobField(Field: TBlobField; BlobSize,
  Progress: integer; var Stop: boolean);
begin
 if Assigned(FOnReadBlobField) then
  FOnReadBlobField(Field,BlobSize,Progress,Stop)
end;

procedure TDataSetsContainer.DoOnWriteBlobField(Field: TBlobField;
  BlobSize, Progress: integer; var Stop: boolean);
begin
 if Assigned(FOnWriteBlobField) then
  FOnWriteBlobField(Field,BlobSize,Progress,Stop)
end;

initialization
 vGlobalContainer:=nil;
end.

