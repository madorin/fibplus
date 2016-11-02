object frmFields: TfrmFields
  Left = 41
  Top = 183
  Width = 676
  Height = 459
  Caption = 's'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = True
  Position = poScreenCenter
  ShowHint = True
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 438
    Top = 0
    Width = 226
    Height = 424
    Align = alRight
    BevelOuter = bvNone
    TabOrder = 0
    object Panel2: TPanel
      Left = 0
      Top = 332
      Width = 226
      Height = 92
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 0
      object btnCopyFields: TButton
        Left = 8
        Top = 57
        Width = 200
        Height = 25
        Hint = 'Copy fields from current metaobject'
        Caption = '&Copy Fields'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 2
        OnClick = btnCopyFieldsClick
      end
      object chFilt: TCheckBox
        Left = 8
        Top = 33
        Width = 192
        Height = 17
        Caption = '&Filter by current metaobject'
        TabOrder = 1
        OnClick = chFiltClick
      end
      object cmbKindObjs: TComboBox
        Left = 8
        Top = 5
        Width = 201
        Height = 21
        Style = csDropDownList
        ItemHeight = 13
        TabOrder = 0
        OnChange = cmbKindObjsChange
      end
    end
    object Panel3: TPanel
      Left = 0
      Top = 0
      Width = 226
      Height = 25
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 1
      OnResize = Panel3Resize
      object EdFilter: TEdit
        Left = 2
        Top = 3
        Width = 217
        Height = 21
        Hint = 'FilterText'
        TabOrder = 0
        OnChange = EdFilterChange
      end
    end
    object Panel4: TPanel
      Left = 0
      Top = 25
      Width = 226
      Height = 307
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 2
      object sbDBGrid2: TDBGrid
        Left = 0
        Top = 0
        Width = 226
        Height = 307
        Hint = 'List of Tables or Stored Procedures'
        Align = alClient
        DataSource = DataSource2
        Options = [dgColumnResize, dgRowSelect, dgCancelOnExit]
        PopupMenu = PopupMenu1
        TabOrder = 0
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'MS Sans Serif'
        TitleFont.Style = []
        OnDblClick = btnCopyFieldsClick
        Columns = <
          item
            Expanded = False
            FieldName = 'RDB$RELATION_NAME'
            Width = 185
            Visible = True
          end>
      end
    end
  end
  object Panel5: TPanel
    Left = 0
    Top = 0
    Width = 438
    Height = 424
    Align = alClient
    BevelOuter = bvNone
    BorderWidth = 1
    Caption = 'Panel5'
    TabOrder = 1
    object sbDBGrid1: TDBGrid
      Left = 1
      Top = 1
      Width = 436
      Height = 422
      Align = alClient
      DataSource = dsQryFL
      Options = [dgEditing, dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgCancelOnExit]
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
    end
  end
  object dsQryFL: TDataSource
    Left = 88
    Top = 296
  end
  object DataSource2: TDataSource
    OnDataChange = DataSource2DataChange
    Left = 312
    Top = 224
  end
  object PopupMenu1: TPopupMenu
    Left = 424
    Top = 136
    object miTables1: TMenuItem
      Caption = 'Tables'
      Checked = True
      OnClick = miProcedures1Click
    end
    object miProcedures1: TMenuItem
      Caption = 'Procedures'
      OnClick = miProcedures1Click
    end
    object miUserForms: TMenuItem
      Caption = 'User Forms'
      Visible = False
      OnClick = miProcedures1Click
    end
  end
end
