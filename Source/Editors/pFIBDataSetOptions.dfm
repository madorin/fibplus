object FPDataSetOptionsForm: TFPDataSetOptionsForm
  Left = 278
  Top = 109
  BorderStyle = bsDialog
  Caption = '%s - Options, PrepareOptions'
  ClientHeight = 321
  ClientWidth = 449
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = True
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Pages: TPageControl
    Left = 8
    Top = 8
    Width = 433
    Height = 273
    ActivePage = OptionsPage
    TabOrder = 0
    object OptionsPage: TTabSheet
      Caption = 'Options'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object ch_poTrimCharFields: TCheckBox
        Left = 16
        Top = 16
        Width = 390
        Height = 17
        Caption = 'Trim char fields'
        TabOrder = 0
        OnClick = ch_poTrimCharFieldsClick
      end
      object ch_poRefreshAfterPost: TCheckBox
        Tag = 1
        Left = 16
        Top = 32
        Width = 390
        Height = 17
        Caption = 'Refresh current record after posting'
        TabOrder = 1
        OnClick = ch_poTrimCharFieldsClick
      end
      object Ch_poRefreshDeletedRecord: TCheckBox
        Tag = 2
        Left = 16
        Top = 48
        Width = 390
        Height = 17
        Caption = 'Delete non existing records from local buffer'
        TabOrder = 2
        OnClick = ch_poTrimCharFieldsClick
      end
      object ch_poStartTransaction: TCheckBox
        Tag = 3
        Left = 16
        Top = 64
        Width = 390
        Height = 17
        Caption = 'Auto start transaction before opening'
        TabOrder = 3
        OnClick = ch_poTrimCharFieldsClick
      end
      object ch_poAutoFormatFields: TCheckBox
        Tag = 4
        Left = 16
        Top = 80
        Width = 390
        Height = 17
        Caption = 'Apply DefaultFormats to DisplayFormat and EditFormat'
        TabOrder = 4
        OnClick = ch_poTrimCharFieldsClick
      end
      object ch_poProtectedEdit: TCheckBox
        Tag = 5
        Left = 16
        Top = 96
        Width = 390
        Height = 17
        Caption = 'Execute idle update before record editing'
        TabOrder = 5
        OnClick = ch_poTrimCharFieldsClick
      end
      object ch_poKeepSorting: TCheckBox
        Tag = 6
        Left = 16
        Top = 112
        Width = 390
        Height = 17
        Caption = 'Place modified record according to sorting order'
        TabOrder = 6
        OnClick = ch_poTrimCharFieldsClick
      end
      object ch_poPersistentSorting: TCheckBox
        Tag = 7
        Left = 16
        Top = 128
        Width = 390
        Height = 17
        Caption = 'Restore local sorting after re-opening'
        TabOrder = 7
        OnClick = ch_poTrimCharFieldsClick
      end
      object ch_poVisibleRecno: TCheckBox
        Tag = 7
        Left = 16
        Top = 144
        Width = 390
        Height = 17
        Caption = 'Recno for visible records only'
        TabOrder = 8
        OnClick = ch_poTrimCharFieldsClick
      end
      object ch_poNoForceIsNull: TCheckBox
        Tag = 7
        Left = 16
        Top = 160
        Width = 390
        Height = 17
        Caption = 'No change SQL to "IS NULL" for NULL parameters'
        TabOrder = 9
        OnClick = ch_poTrimCharFieldsClick
      end
      object ch_poFetchAll: TCheckBox
        Tag = 7
        Left = 16
        Top = 176
        Width = 390
        Height = 17
        Caption = 'Fetch all records after dataset open'
        TabOrder = 10
        OnClick = ch_poTrimCharFieldsClick
      end
      object ch_poFreeHandlesAfterClose: TCheckBox
        Tag = 7
        Left = 16
        Top = 192
        Width = 390
        Height = 17
        Caption = 'Free SQL handle after dataset close'
        TabOrder = 11
        OnClick = ch_poTrimCharFieldsClick
      end
      object ch_poCacheCalcFields: TCheckBox
        Tag = 7
        Left = 16
        Top = 208
        Width = 390
        Height = 17
        Caption = 'Save Calc fields values to cache'
        TabOrder = 12
        OnClick = ch_poTrimCharFieldsClick
      end
    end
    object PreparePage: TTabSheet
      Caption = 'PrepareOptions'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object ch_pfSetRequiredFields: TCheckBox
        Left = 16
        Top = 16
        Width = 390
        Height = 17
        Caption = 
          'Set Required property in TField components according to NOT NULL' +
          ' state'
        TabOrder = 0
        OnClick = ch_poTrimCharFieldsClick
      end
      object ch_pfSetReadOnlyFields: TCheckBox
        Tag = 1
        Left = 16
        Top = 32
        Width = 390
        Height = 17
        Caption = 'Set ReadOnly property in TField components for calculated fields'
        TabOrder = 1
        OnClick = ch_poTrimCharFieldsClick
      end
      object ch_pfImportDefaultValues: TCheckBox
        Tag = 2
        Left = 16
        Top = 48
        Width = 390
        Height = 17
        Caption = 
          'Set Default property of TField components according to table des' +
          'cription'
        TabOrder = 2
        OnClick = ch_poTrimCharFieldsClick
      end
      object ch_psUseBooleanField: TCheckBox
        Tag = 3
        Left = 16
        Top = 64
        Width = 390
        Height = 17
        Caption = 'Emulate boolean fields'
        TabOrder = 3
        OnClick = ch_poTrimCharFieldsClick
      end
      object ch_psSQLINT64ToBCD: TCheckBox
        Tag = 4
        Left = 16
        Top = 80
        Width = 390
        Height = 17
        Caption = 
          'Create TBCDField instances for INT64 fields with any scale (SQLD' +
          'ialect 3)'
        TabOrder = 4
        OnClick = ch_poTrimCharFieldsClick
      end
      object ch_psApplyRepositary: TCheckBox
        Tag = 5
        Left = 16
        Top = 96
        Width = 390
        Height = 17
        Caption = 
          'Apply FIBPlus Repository options to field propetries, queries, e' +
          'tc'
        TabOrder = 5
        OnClick = ch_poTrimCharFieldsClick
      end
      object ch_psGetOrderInfo: TCheckBox
        Tag = 6
        Left = 16
        Top = 112
        Width = 390
        Height = 17
        Caption = 'Fill SortFields property using ORDER BY clause'
        TabOrder = 6
        OnClick = ch_poTrimCharFieldsClick
      end
      object ch_psAskRecordCount: TCheckBox
        Tag = 7
        Left = 16
        Top = 128
        Width = 390
        Height = 17
        Caption = 'Get record count without fetching all records'
        TabOrder = 7
        OnClick = ch_poTrimCharFieldsClick
      end
      object ch_psCanEditComputedFields: TCheckBox
        Tag = 7
        Left = 16
        Top = 144
        Width = 390
        Height = 17
        Caption = 'Can edit server calculated fields'
        TabOrder = 8
        OnClick = ch_poTrimCharFieldsClick
      end
      object ch_psSetEmptyStrToNull: TCheckBox
        Tag = 7
        Left = 16
        Top = 160
        Width = 390
        Height = 17
        Caption = 'Empty string interpretate as null value'
        TabOrder = 9
        OnClick = ch_poTrimCharFieldsClick
      end
      object ch_psSupportUnicodeBlobs: TCheckBox
        Tag = 7
        Left = 16
        Top = 176
        Width = 390
        Height = 17
        Caption = 
          'FORCE Unicode translate for BLOB fields with UNICODE_FSS charset' +
          ' '
        TabOrder = 10
        OnClick = ch_poTrimCharFieldsClick
      end
      object ch_psUseLargeIntField: TCheckBox
        Tag = 7
        Left = 16
        Top = 192
        Width = 390
        Height = 17
        Caption = 'Create TLargeIntField for BIGINT fields'
        TabOrder = 11
        OnClick = ch_poTrimCharFieldsClick
      end
    end
  end
  object OkB: TButton
    Left = 280
    Top = 290
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object CancelB: TButton
    Left = 365
    Top = 290
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
end
