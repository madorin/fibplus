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

unit FIBUpdateObject;

interface

{$I FIBPlus.inc}

uses
  SysUtils, Classes, DB, FIBQuery, FIBDataSet;

type
  TFIBOrderExecUO = (oeBeforeDefault, oeAfterDefault);

  TFIBUpdateObject = class(TFIBQuery)
  private
    FActive: Boolean;
    FOrderInList: Integer;
    FDataSet: TFIBDataSet;
    FKindUpdate: TUpdateKind;
    FExecuteOrder: TFIBOrderExecUO;
    procedure SetDataSet(Value: TFIBDataSet);
    procedure SetOrderInList(Value: Integer);
    procedure SetKindUpdate(Value: TUpdateKind);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure ChangeOrderInList(NewOrder: Integer);
    procedure Apply;

  published
    property DataSet: TFIBDataSet read FDataSet write SetDataSet;
    property OrderInList: Integer read FOrderInList write SetOrderInList;
    property KindUpdate: TUpdateKind read FKindUpdate write SetKindUpdate default ukModify;
    property Active: Boolean read FActive write FActive default True;
    property ExecuteOrder: TFIBOrderExecUO read FExecuteOrder write FExecuteOrder default oeBeforeDefault;
    property ParamCheck default True;
  end;

implementation

uses
  pFIBDataSet, StrUtil, FIBConsts;

constructor TFIBUpdateObject.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ParamCheck := True;
  FActive := True;
end;

destructor TFIBUpdateObject.Destroy;
begin
  if FDataSet <> nil then
    TpFIBDataSet(FDataSet).RemoveUpdateObject(Self);
  inherited Destroy;
end;

procedure TFIBUpdateObject.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if Operation = opRemove then
  begin
    if AComponent = FDataSet then
      FDataSet := nil;
  end;
  inherited Notification(AComponent, Operation)
end;

procedure TFIBUpdateObject.SetDataSet(Value: TFIBDataSet);
begin
  if (Value <> nil) and not(Value is TpFIBDataSet) then
    raise Exception.Create(Format(SFIBErrorNotDataSet, [Value.Name]));
  if Value = FDataSet then
    Exit;
  if FDataSet <> nil then
    TpFIBDataSet(FDataSet).RemoveUpdateObject(Self);
  if Value <> nil then
    TpFIBDataSet(Value).AddUpdateObject(Self);
  FDataSet := Value;
  if FDataSet <> nil then
  begin
    FDataSet.FreeNotification(Self);
    if Database = nil then
      Database := FDataSet.Database;
    if Transaction = nil then
      Transaction := FDataSet.Transaction;
  end;
end;

procedure TFIBUpdateObject.SetOrderInList(Value: Integer);
begin
  FOrderInList := Value;
  if FDataSet <> nil then
    TpFIBDataSet(FDataSet).AddUpdateObject(Self)
end;

procedure TFIBUpdateObject.SetKindUpdate(Value: TUpdateKind);
begin
  if Value = FKindUpdate then
    Exit;
  if FDataSet <> nil then
  begin
    TpFIBDataSet(FDataSet).RemoveUpdateObject(Self);
    FKindUpdate := Value;
    TpFIBDataSet(FDataSet).AddUpdateObject(Self);
  end
  else
    FKindUpdate := Value;
end;

procedure TFIBUpdateObject.ChangeOrderInList(NewOrder: Integer);
begin
  FOrderInList := NewOrder;
end;

procedure TFIBUpdateObject.Apply;
begin
  if not Active or (FDataSet = nil) or EmptyStrings(SQL) then
    Exit;
  if not(FDataSet is TpFIBDataSet) then
    raise Exception.Create(Format(SFIBErrorNotDataSetDetail, [Self.Name, FDataSet.Name]));
  with TpFIBDataSet(FDataSet) do
  begin
{$IFDEF D_XE4}
    ExecUpdateObjects(FKindUpdate, Pointer(ActiveBuffer), FExecuteOrder);
{$ELSE}
    ExecUpdateObjects(FKindUpdate, ActiveBuffer, FExecuteOrder);
{$ENDIF}
  end;
end;

end.
