object frmEdDataSetInfo: TfrmEdDataSetInfo
  Left = 898
  Top = 488
  BorderIcons = [biSystemMenu, biMaximize]
  Caption = 'Choose DataSet information '
  ClientHeight = 335
  ClientWidth = 584
  Color = clBtnFace
  Constraints.MinHeight = 216
  Constraints.MinWidth = 358
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = True
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 219
    Top = 0
    Height = 302
    ExplicitHeight = 295
  end
  object PageControl1: TPageControl
    Left = 222
    Top = 0
    Width = 362
    Height = 302
    ActivePage = TabSheet2
    Align = alClient
    MultiLine = True
    TabOrder = 0
    ExplicitHeight = 295
    object TabSheet2: TTabSheet
      Caption = 'Select'
      ImageIndex = 1
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
    end
    object TabSheet4: TTabSheet
      Caption = 'Insert'
      ImageIndex = 3
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
    end
    object TabSheet3: TTabSheet
      Caption = 'Update'
      ImageIndex = 2
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
    end
    object TabSheet7: TTabSheet
      Caption = 'Delete'
      ImageIndex = 6
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
    end
    object TabSheet5: TTabSheet
      Caption = 'Refresh'
      ImageIndex = 4
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
    end
    object TabSheet6: TTabSheet
      Caption = 'AutoUpdate Options'
      ImageIndex = 5
      DesignSize = (
        354
        256)
      object Label1: TLabel
        Left = 6
        Top = 7
        Width = 49
        Height = 13
        Caption = 'Key Field :'
      end
      object Label2: TLabel
        Left = 6
        Top = 29
        Width = 50
        Height = 13
        Caption = 'Generator:'
      end
      object Label3: TLabel
        Left = 7
        Top = 52
        Width = 65
        Height = 13
        Caption = 'UpdateTable:'
      end
      object DBEdit1: TDBEdit
        Left = 97
        Top = 5
        Width = 258
        Height = 21
        Anchors = [akLeft, akTop, akRight]
        DataField = 'KEY_FIELD'
        DataSource = DataSource1
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
      end
      object DBEdit2: TDBComboBox
        Left = 97
        Top = 25
        Width = 258
        Height = 21
        Anchors = [akLeft, akTop, akRight]
        DataField = 'NAME_GENERATOR'
        DataSource = DataSource1
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
      end
      object DBEdit3: TDBEdit
        Left = 97
        Top = 45
        Width = 258
        Height = 21
        Anchors = [akLeft, akTop, akRight]
        DataField = 'UPDATE_TABLE_NAME'
        DataSource = DataSource1
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 2
      end
      object DBCheckBox1: TDBCheckBox
        Left = 7
        Top = 76
        Width = 195
        Height = 17
        Caption = 'UpdateOnlyModifiedFields'
        DataField = 'UPDATE_ONLY_MODIFIED_FIELDS'
        DataSource = DataSource1
        TabOrder = 3
        ValueChecked = '1'
        ValueUnchecked = '0'
      end
    end
    object TabSheet8: TTabSheet
      Caption = 'Conditions'
      ImageIndex = 7
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      inline fraEdConditions1: TfraEdConditions
        Left = 0
        Top = 0
        Width = 354
        Height = 249
        Align = alClient
        TabOrder = 0
        TabStop = True
        ExplicitWidth = 354
        ExplicitHeight = 249
        inherited Panel1: TPanel
          Width = 264
          Height = 249
          ExplicitWidth = 264
          ExplicitHeight = 249
          inherited Splitter1: TSplitter
            Top = 115
            Width = 256
            ExplicitTop = 115
            ExplicitWidth = 256
          end
          inherited GroupBox2: TGroupBox
            Width = 256
            Height = 111
            ExplicitWidth = 256
            ExplicitHeight = 111
            inherited Panel3: TPanel
              Width = 260
              Height = 105
              ExplicitWidth = 260
              ExplicitHeight = 105
              inherited Memo1: TMemo
                Width = 252
                Height = 97
                ExplicitWidth = 252
                ExplicitHeight = 97
              end
            end
          end
          inherited GroupBox1: TGroupBox
            Top = 119
            Width = 256
            ExplicitTop = 119
            ExplicitWidth = 256
            inherited Panel4: TPanel
              Width = 252
              ExplicitWidth = 252
              inherited ListView1: TListView
                Width = 244
                ExplicitWidth = 244
              end
            end
          end
        end
        inherited Panel2: TPanel
          Left = 264
          Height = 249
          ExplicitLeft = 264
          ExplicitHeight = 249
          inherited Button1: TButton
            Visible = False
          end
          inherited Button2: TButton
            Visible = False
          end
        end
      end
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 302
    Width = 584
    Height = 33
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitTop = 295
    DesignSize = (
      584
      33)
    object Button1: TButton
      Left = 434
      Top = 3
      Width = 75
      Height = 27
      Anchors = [akRight]
      Caption = '&OK'
      Default = True
      ModalResult = 1
      TabOrder = 0
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 514
      Top = 3
      Width = 75
      Height = 27
      Anchors = [akRight]
      Cancel = True
      Caption = '&Cancel'
      ModalResult = 2
      TabOrder = 1
      OnClick = Button2Click
    end
    object btnSave: TButton
      Left = 6
      Top = 3
      Width = 75
      Height = 27
      Caption = '&Save'
      Enabled = False
      TabOrder = 2
      OnClick = btnSaveClick
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 0
    Width = 219
    Height = 302
    Align = alLeft
    Caption = 'Panel2'
    TabOrder = 2
    OnResize = Panel2Resize
    ExplicitHeight = 295
    object GroupBox2: TGroupBox
      Left = 1
      Top = 1
      Width = 217
      Height = 38
      Align = alTop
      Caption = 'Filter'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      DesignSize = (
        217
        38)
      object Edit1: TEdit
        Left = 4
        Top = 12
        Width = 205
        Height = 21
        Anchors = [akLeft, akRight]
        AutoSize = False
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        OnChange = Edit1Change
      end
    end
    object DBGrid1: TDBGrid
      Left = 1
      Top = 39
      Width = 217
      Height = 262
      Align = alClient
      DataSource = DataSource1
      Options = [dgEditing, dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgConfirmDelete, dgCancelOnExit]
      TabOrder = 1
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      Columns = <
        item
          Expanded = False
          FieldName = 'DS_ID'
          Width = 55
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'DESCRIPTION'
          Width = 131
          Visible = True
        end>
    end
  end
  object DataSource1: TDataSource
    Left = 176
    Top = 168
  end
end
