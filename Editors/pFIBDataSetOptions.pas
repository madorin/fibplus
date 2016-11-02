{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ Interbase databases                                           }
{                                                               }
{    FIBPlus is based in part on the product                    }
{    Free IB Components, written by Gregory H. Deatz for        }
{    Hoagland, Longo, Moran, Dunst & Doukas Company.            }
{    mailto:gdeatz@hlmdd.com                                    }
{                                                               }
{    Copyright (c) 1998-2001 Serge Buzadzhy                     }
{    Contact: buzz@devrace.com                                  }
{                                                               }
{ ------------------------------------------------------------- }
{    FIBPlus home page      : http://www.fibplus.net/           }
{    FIBPlus support e-mail : fibplus@devrace.com               }
{ ------------------------------------------------------------- }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}
unit pFIBDataSetOptions;

interface
         {$I ..\FIBPlus.inc}
uses Classes,
 {$IFDEF D_XE2}
  Vcl.Graphics, Vcl.Controls, Vcl.Forms,  Vcl.Dialogs, Vcl.ComCtrls, Vcl.ExtCtrls,
  Vcl.StdCtrls,
  {$ELSE}
  Graphics, Controls, Forms,  Dialogs, ComCtrls, ExtCtrls, StdCtrls,
  {$ENDIF}

  Db, uFIBEditorForm;

type

  TFPDataSetOptionsForm = class(TFIBEditorCustomForm)
    Pages: TPageControl;
    OptionsPage: TTabSheet;
    PreparePage: TTabSheet;
    OkB: TButton;
    CancelB: TButton;
    ch_poTrimCharFields: TCheckBox;
    ch_poRefreshAfterPost: TCheckBox;
    Ch_poRefreshDeletedRecord: TCheckBox;
    ch_poStartTransaction: TCheckBox;
    ch_poAutoFormatFields: TCheckBox;
    ch_poProtectedEdit: TCheckBox;
    ch_poKeepSorting: TCheckBox;
    ch_poPersistentSorting: TCheckBox;
    ch_pfSetRequiredFields: TCheckBox;
    ch_pfSetReadOnlyFields: TCheckBox;
    ch_pfImportDefaultValues: TCheckBox;
    ch_psUseBooleanField: TCheckBox;
    ch_psSQLINT64ToBCD: TCheckBox;
    ch_psApplyRepositary: TCheckBox;
    ch_psGetOrderInfo: TCheckBox;
    ch_psAskRecordCount: TCheckBox;
    ch_poVisibleRecno: TCheckBox;
    ch_poNoForceIsNull: TCheckBox;
    ch_poFetchAll: TCheckBox;
    ch_poFreeHandlesAfterClose: TCheckBox;
    ch_poCacheCalcFields: TCheckBox;
    ch_psCanEditComputedFields: TCheckBox;
    ch_psSetEmptyStrToNull: TCheckBox;
    ch_psSupportUnicodeBlobs: TCheckBox;
    ch_psUseLargeIntField: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure ch_poTrimCharFieldsClick(Sender: TObject);
  private
    { Private declarations }
    FDataSet: TDataSet;
    procedure ShowChanges;
  public
    { Public declarations }
    function GetOptionBox(aIndex: Integer;const PropName:string): TCheckBox;
    function GetMaxOption(const PropName:string):integer;
  end;

function EditOptions(aDataSets: array of TDataSet; aPageIndex: Integer): boolean;

implementation

uses SysUtils,TypInfo, pFIBEditorsConsts;

{$R *.dfm}

function EditOptions(aDataSets: array of TDataSet; aPageIndex: Integer): boolean;
var aForm: TFPDataSetOptionsForm;
(*I*)    Option: Byte;
    chBox:TCheckBox;
    K:integer;
    Options:Integer;
    MaxOption:integer;
begin
  Result := False;
  if aDataSets[0] = nil then exit;
  aForm := TFPDataSetOptionsForm.Create(Application);
  try
    with aForm do
    begin
      FDataSet := aDataSets[0];
      Caption := Format(Caption, [FDataSet.Name]);
      Pages.ActivePage := Pages.Pages[aPageIndex];

      Options:=GetPropValue(FDataSet,'Options',False);

      MaxOption:=GetMaxOption('Options');
      for Option:=0 to MaxOption do
      begin
        chBox:=GetOptionBox(Option,'Options');
        if Assigned(chBox) then

        chBox.Checked :=Option in TIntegerSet(Options)
      end;


      Options:=GetPropValue(FDataSet,'PrepareOptions',False);
      MaxOption:=GetMaxOption('PrepareOptions');

      for Option:=0 to MaxOption do
      begin
        chBox:=GetOptionBox(Option,'PrepareOptions');
        if Assigned(chBox) then
         chBox.Checked :=Option in TIntegerSet(Options)

      end;

      Result := ShowModal = mrOk;
      if Result then
      begin
        MaxOption:=GetMaxOption('Options');
        for k:=Low(aDataSets) to High(aDataSets) do
        begin
          Options:=0;

          for Option:=0 to MaxOption do
          begin
             chBox:=GetOptionBox(Option,'Options');
             if Assigned(chBox) then
              if chBox.Checked then
                 Include(TIntegerSet(Options),Option);
          end;
          SetPropValue(aDataSets[k],'Options',Options)
        end;

        MaxOption:=GetMaxOption('PrepareOptions');
        for k:=Low(aDataSets) to High(aDataSets) do
        begin
          Options:=0;
          for Option:=0 to MaxOption do
          begin
             chBox:=GetOptionBox(Option,'PrepareOptions');
             if Assigned(chBox) then
              if chBox.Checked then
                 Include(TIntegerSet(Options),Option);
          end;
          SetPropValue(aDataSets[k],'PrepareOptions',Options)
        end;


      end;
    end;
  finally
    aForm.Free;
  end;
end;

procedure TFPDataSetOptionsForm.ShowChanges;
var
    Option: Byte;
    Options:Integer;
    MaxOption:integer;
    chBox:TCheckBox;

begin
  MaxOption:=GetMaxOption('Options');
  Options:=GetPropValue(FDataSet,'Options',False);
  for Option:=0 to MaxOption do
  begin
    chBox:=GetOptionBox(Option,'Options');
    if Assigned(chBox) then
    begin
     if (Ord(chBox.Checked)-Ord(Option in TIntegerSet(Options)))<>0 then
      chBox.Font.Style:=chBox.Font.Style+[fsBold]
     else
      chBox.Font.Style:=chBox.Font.Style-[fsBold]
    end;
  end;

  MaxOption:=GetMaxOption('PrepareOptions');
  Options:=GetPropValue(FDataSet,'PrepareOptions',False);
  for Option:=0 to MaxOption do
  begin
    chBox:=GetOptionBox(Option,'PrepareOptions');
    if Assigned(chBox) then
    begin
     if (Ord(chBox.Checked)-Ord(Option in TIntegerSet(Options)))<>0 then
      chBox.Font.Style:=chBox.Font.Style+[fsBold]
     else
      chBox.Font.Style:=chBox.Font.Style-[fsBold]
    end;
  end;

end;

function TFPDataSetOptionsForm.GetOptionBox(aIndex: Integer;const PropName:string): TCheckBox;
var
  EnumType: PTypeInfo;
  EnumName: string;
  PropType:PTypeInfo;
  PropInfo: PPropInfo;
begin
    PropInfo := GetPropInfo(FDataSet, PropName);
    PropType := PPropInfo(PropInfo)^.PropType^;
    EnumType := GetTypeData(PropType)^.CompType^;
    EnumName := GetEnumName(EnumType,aIndex);
    Result   := TCheckBox(FindComponent('Ch_'+EnumName))
end;

function TFPDataSetOptionsForm.GetMaxOption(const PropName:string):integer;
var
  EnumType: PTypeInfo;
  PropType:PTypeInfo;
  PropInfo: PPropInfo;
begin
    PropInfo := GetPropInfo(FDataSet, PropName);
    PropType := PPropInfo(PropInfo)^.PropType^;
    EnumType := GetTypeData(PropType)^.CompType^;
    Result   := GetTypeData(EnumType).MaxValue;
end;

procedure TFPDataSetOptionsForm.FormCreate(Sender: TObject);
begin
  //
  Caption := FPOptionsCaption;
  OptionsPage.Caption := FPOptionsPage;
  PreparePage.Caption := FPOptionsPreparePage;

  ch_poTrimCharFields.Caption := FPOptionsTrimChars;
  ch_poRefreshAfterPost.Caption := FPOptionsRefresh;
  Ch_poRefreshDeletedRecord.Caption := FPOptionsRefreshDelete;
  ch_poStartTransaction.Caption := FPOptionsAutoStart;
  ch_poAutoFormatFields.Caption := FPOptionsApplyFormats;
  ch_poProtectedEdit.Caption := FPOptionsIdleUpdate;
  ch_poKeepSorting.Caption := FPOptionsKeepSort;
  ch_poPersistentSorting.Caption := FPOptionsRestoreSort;
  ch_pfSetRequiredFields.Caption := FPOptionsSetRequired;
  ch_pfSetReadOnlyFields.Caption := FPOptionsSetReadOnly;
  ch_pfImportDefaultValues.Caption := FPOptionsSetDefault;
  ch_psUseBooleanField.Caption := FPOptionsEmulateBoolean;
  ch_psSQLINT64ToBCD.Caption := FPOptionsCreateBCD;
  ch_psApplyRepositary.Caption := FPOptionsApplyRepository;
  ch_psGetOrderInfo.Caption := FPOptionsSortFields;
  ch_psAskRecordCount.Caption := FPOptionsRecordCount;
  ch_poVisibleRecno.Caption := FPVisibleRecno;  
end;

procedure TFPDataSetOptionsForm.ch_poTrimCharFieldsClick(Sender: TObject);
begin
 ShowChanges
end;

end.
