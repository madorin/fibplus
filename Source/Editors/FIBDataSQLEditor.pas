{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ Interbase databases                                           }
{                                                               }
{    FIBPlus is based in part on the product                    }
{    Free IB Components, written by Gregory H. Deatz for        }
{    Hoagland, Longo, Moran, Dunst & Doukas Company.            }
{    mailto:gdeatz@hlmdd.com                                    }
{                                                               }
{    Copyright (c) 1998-2004 Serge Buzadzhy                     }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit FIBDataSQLEditor;

interface

{$I ..\FIB.inc}

uses
  Windows, Messages, SysUtils, Variants, Classes,
{$IFDEF C23}
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls,
  Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.Buttons,
{$ELSE}
  Graphics, Controls, Forms, Dialogs, ComCtrls, ExtCtrls, StdCtrls, Buttons,
{$ENDIF}
  fraSQLEdit, DB,
  fraDSSQLEdit, uFIBEditorForm;

type
  TFIBDataSetSQLEditForm = class(TFIBEditorCustomForm)
    Panel1: TPanel;
    btnOK: TBitBtn;
    btnCancel: TBitBtn;
    fSQLsEdit: TFIBDataSetSQLFrame;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    procedure ReadOptions;
    procedure SaveOptions;
    procedure SaveFieldsOrigins(aDataSet: TDataSet);
  public
    { Public declarations }
  end;

var
  frmDstSQLedit: TFIBDataSetSQLEditForm;

function ShowDSSQLEdit(aDataSet: TDataSet; KindSQL: Integer; var ExitToCodeEditor: Integer): Boolean;

implementation

{$R *.dfm}

uses
  TypInfo, RegUtils, FIBProps, RTTIRoutines, FIBInterfaces;

const
  RegFIBSQLEdOptions = 'SQLEditor';

function ShowDSSQLEdit(aDataSet: TDataSet; KindSQL: Integer; var ExitToCodeEditor: Integer): Boolean;
var
  ForceClose: Boolean;
  Modified: Boolean;
begin
  frmDstSQLedit := TFIBDataSetSQLEditForm.Create(Application);
  with frmDstSQLedit do
  begin
    with fSQLsEdit do
    begin
      FDataSet := aDataSet;
      PrepareFrame(TComponent(GetObjectProp(aDataSet, 'Database')), TStrings(GetObjectProp(aDataSet, 'SelectSQL')).Text,
        TStrings(GetObjectProp(aDataSet, 'InsertSQL')).Text, TStrings(GetObjectProp(aDataSet, 'UpdateSQL')).Text,
        TStrings(GetObjectProp(aDataSet, 'DeleteSQL')).Text, TStrings(GetObjectProp(aDataSet, 'RefreshSQL')).Text);
    end;
    ReadOptions;
    Caption := 'SQL edit :' + aDataSet.Name;
    case KindSQL of
      0: fSQLsEdit.pgCtrl.ActivePage := fSQLsEdit.shSelect;
    else
      fSQLsEdit.pgCtrl.ActivePage := fSQLsEdit.shModifySQLs;
      fSQLsEdit.grSQLKind.ItemIndex := KindSQL - 1
    end;
    fSQLsEdit.SetProposal;
    Result := ShowModal in [mrOk, mrYes];

    ExitToCodeEditor := -1;
    if Result then
    begin
      if ModalResult = mrYes then
      begin
        if fSQLsEdit.pgCtrl.ActivePageIndex = 0 then
          ExitToCodeEditor := 0
        else
          ExitToCodeEditor := fSQLsEdit.grSQLKind.ItemIndex + 1;
      end
      else
        ExitToCodeEditor := -1;
      ForceClose := aDataSet.Active;
      if ForceClose then
        aDataSet.Close;
      Modified := TStrings(GetObjectProp(aDataSet, 'SelectSQL')).Text <> fSQLsEdit.SelectSQLEdit.SQLText;
      if Modified then
        AssignStringsToProp(aDataSet, 'SelectSQL', fSQLsEdit.SelectSQLEdit.SQLText);
      if TStrings(GetObjectProp(aDataSet, 'InsertSQL')).Text <> fSQLsEdit.FInsertSQL then
      begin
        AssignStringsToProp(aDataSet, 'InsertSQL', fSQLsEdit.FInsertSQL);
        Modified := True;
      end;
      if TStrings(GetObjectProp(aDataSet, 'UpdateSQL')).Text <> fSQLsEdit.FUpdateSQL then
      begin
        AssignStringsToProp(aDataSet, 'UpdateSQL', fSQLsEdit.FUpdateSQL);
        Modified := True;
      end;
      if TStrings(GetObjectProp(aDataSet, 'DeleteSQL')).Text <> fSQLsEdit.FDeleteSQL then
      begin
        AssignStringsToProp(aDataSet, 'DeleteSQL', fSQLsEdit.FDeleteSQL);
        Modified := True;
      end;
      if TStrings(GetObjectProp(aDataSet, 'RefreshSQL')).Text <> fSQLsEdit.FRefreshSQL then
      begin
        AssignStringsToProp(aDataSet, 'RefreshSQL', fSQLsEdit.FRefreshSQL);
        Modified := True;
      end;
      Result := Modified;
      if fSQLsEdit.chFieldOrigin.Checked then
        SaveFieldsOrigins(aDataSet);
      if ForceClose then
        aDataSet.Open;
    end;
    Free
  end;
end;

procedure TFIBDataSetSQLEditForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveOptions;
end;

procedure TFIBDataSetSQLEditForm.ReadOptions;

{$IFNDEF NO_REGISTRY}
var
  OriginsValue: Variant;
{$ENDIF}
begin
{$IFNDEF NO_REGISTRY}
  OriginsValue := DefReadFromRegistry(['Software', RegFIBRoot, RegFIBSQLEdOptions], ['Origins']);
  if VarIsArray(OriginsValue) and Boolean(OriginsValue[1, 0]) then
    fSQLsEdit.chFieldOrigin.Checked := OriginsValue[0, 0];
  fSQLsEdit.ReadOptions;

{$ENDIF}
end;

procedure TFIBDataSetSQLEditForm.SaveOptions;
begin
{$IFNDEF NO_REGISTRY}
  DefWriteToRegistry(['Software', RegFIBRoot, RegFIBSQLEdOptions], ['Origins'], [fSQLsEdit.chFieldOrigin.Checked]);
  fSQLsEdit.SaveOptions;
{$ENDIF}
end;

{$IFDEF C27}
type
  THackDataSet = class(TDataSet);
{$ENDIF}

// TDataSet.DefaultFields is deprecated (XE6+)
function HasDefaultFields(DataSet: TDataSet): Boolean;
begin
{$IFDEF C27}
  Result := (THackDataSet(DataSet).FieldOptions.AutoCreateMode <> acExclusive) or not (lcPersistent in DataSet.Fields.LifeCycles);
{$ELSE}
  Result := DataSet.DefaultFields;
{$ENDIF}
end;

procedure TFIBDataSetSQLEditForm.SaveFieldsOrigins(aDataSet: TDataSet);
var
  i: Integer;
  DatabaseConnected: Boolean;
  ids: IFIBDataSet;
begin
  with aDataSet do
  begin
    if HasDefaultFields(aDataSet) or (not Active and (FieldCount = 0)) then
      Exit;
    DatabaseConnected := Assigned(GetObjectProp(aDataSet, 'Database')) and
      GetPropValue(GetObjectProp(aDataSet, 'Database'), 'Connected');
    if not DatabaseConnected then
      Exit;
    if ObjSupports(aDataSet, IFIBDataSet, ids) then
      for i := 0 to Pred(FieldCount) do
        Fields[i].Origin := ids.GetFieldOrigin(Fields[i]);
  end;
end;

end.
