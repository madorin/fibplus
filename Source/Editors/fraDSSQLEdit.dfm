object fDSSQLEdit: TfDSSQLEdit
  Left = 0
  Top = 0
  Width = 698
  Height = 439
  TabOrder = 0
  TabStop = True
  object pgCtrl: TPageControl
    Left = 0
    Top = 0
    Width = 698
    Height = 439
    ActivePage = shModifySQLs
    Align = alClient
    TabOrder = 0
    OnChange = pgCtrlChange
    object shSelect: TTabSheet
      Caption = 'SelectSQL'
      inline SelectSQLEdit: TfSQLEdit
        Left = 0
        Top = 0
        Width = 690
        Height = 411
        Align = alClient
        ParentShowHint = False
        ShowHint = True
        TabOrder = 0
        TabStop = True
        inherited Splitter2: TSplitter
          Left = 440
          Height = 411
        end
        inherited Panel1: TPanel
          Width = 440
          Height = 411
          inherited splPlan: TSplitter
            Top = 388
            Width = 438
          end
          inherited Panel10: TPanel
            Width = 438
            inherited SpeedButton1: TSpeedButton
              OnClick = SelectSQLEditSpeedButton1Click
            end
            inherited btnGenSQL: TSpeedButton
              Left = 365
              OnClick = SelectSQLEditbtnGenSQLClick
            end
          end
          inherited StatusBar1: TStatusBar
            Top = 391
            Width = 438
          end
        end
        inherited Panel6: TPanel
          Left = 443
          Height = 411
          inherited GroupBox1: TGroupBox
            Height = 343
            inherited Panel2: TPanel
              Height = 279
              Caption = ''
              inherited DBGrid2: TDBGrid
                Height = 94
              end
              inherited Panel4: TPanel
                Top = 187
              end
            end
          end
        end
        inherited ds: TDataSource
          Left = 84
        end
        inherited FindDialog1: TFindDialog
          Left = 76
          Top = 72
        end
        inherited dsFields: TDataSource
          Left = 168
          Top = 112
        end
        inherited menuPlan: TPopupMenu
          Left = 88
          Top = 176
        end
      end
    end
    object shGenOptions: TTabSheet
      Caption = 'Generate Modify SQLs'
      ImageIndex = 1
      object Splitter1: TSplitter
        Left = 353
        Top = 0
        Width = 5
        Height = 411
      end
      object Panel2: TPanel
        Left = 0
        Top = 0
        Width = 145
        Height = 411
        Align = alLeft
        BevelOuter = bvNone
        BorderWidth = 1
        TabOrder = 0
        OnMouseMove = Panel2MouseMove
        object Label3: TLabel
          Left = 4
          Top = 5
          Width = 101
          Height = 13
          Caption = 'Select modified table:'
        end
        object cmbTables: TComboBox
          Left = 3
          Top = 24
          Width = 139
          Height = 21
          ItemHeight = 0
          ParentShowHint = False
          ShowHint = True
          TabOrder = 0
          OnChange = cmbTablesChange
        end
        object btnGetFields: TButton
          Left = 3
          Top = 48
          Width = 140
          Height = 25
          Caption = 'Get &Table Fields'
          TabOrder = 1
          OnClick = btnGetFieldsClick
        end
        object btnGenSql: TButton
          Left = 3
          Top = 75
          Width = 140
          Height = 25
          Caption = '&Generate SQLs'
          TabOrder = 2
          OnClick = btnGenSqlClick
        end
        object btnClearSQLs: TButton
          Left = 3
          Top = 137
          Width = 140
          Height = 25
          Caption = '&Clear SQLs'
          TabOrder = 4
          OnClick = btnClearSQLsClick
        end
        object GroupBox1: TGroupBox
          Left = 1
          Top = 363
          Width = 143
          Height = 47
          Align = alBottom
          Caption = 'On Save SQLs'
          TabOrder = 6
          object chFieldOrigin: TCheckBox
            Left = 6
            Top = 16
            Width = 127
            Height = 17
            Hint = 'Save Fields origin'
            Caption = 'Field Origins'
            ParentShowHint = False
            ShowHint = True
            TabOrder = 0
          end
        end
        object GroupBox2: TGroupBox
          Left = 1
          Top = 279
          Width = 143
          Height = 84
          Align = alBottom
          Caption = 'Options'
          TabOrder = 5
          object Label2: TLabel
            Left = 5
            Top = 59
            Width = 67
            Height = 13
            Caption = 'ParamSymbol:'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = []
            ParentFont = False
          end
          object chByPrimary: TCheckBox
            Left = 3
            Top = 17
            Width = 136
            Height = 24
            Hint = 'Use only primary key in where clause'
            Caption = 'Where by primary key'
            Checked = True
            ParentShowHint = False
            ShowHint = True
            State = cbChecked
            TabOrder = 0
          end
          object chNonUpdPrKey: TCheckBox
            Left = 3
            Top = 38
            Width = 137
            Height = 17
            Hint = 'To not change a primary key in update SQL'
            Caption = 'Non update primary key'
            Checked = True
            ParentShowHint = False
            ShowHint = True
            State = cbChecked
            TabOrder = 1
          end
          object cmbParamSymbol: TComboBox
            Left = 96
            Top = 56
            Width = 36
            Height = 21
            Style = csDropDownList
            Color = clBtnFace
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = [fsBold]
            ItemHeight = 13
            ParentFont = False
            TabOrder = 2
            Items.Strings = (
              ':'
              '?')
          end
        end
        object cmbGenerateKind: TComboBox
          Left = 3
          Top = 107
          Width = 141
          Height = 21
          Style = csDropDownList
          ItemHeight = 13
          TabOrder = 3
          Items.Strings = (
            'Generate All SQLs'
            'Generate Insert '
            'Generate Update'
            'Generate Delete'
            'Generate Refresh')
        end
      end
      object Panel3: TPanel
        Left = 145
        Top = 0
        Width = 208
        Height = 411
        Align = alLeft
        BevelOuter = bvNone
        Caption = 'Panel2'
        TabOrder = 1
        object Label1: TLabel
          Left = 0
          Top = 0
          Width = 48
          Height = 13
          Align = alTop
          Caption = 'Key Fields'
        end
        object LstKeyFields: TListBox
          Left = 0
          Top = 13
          Width = 208
          Height = 398
          Align = alClient
          ItemHeight = 13
          MultiSelect = True
          TabOrder = 0
        end
      end
      object Panel5: TPanel
        Left = 358
        Top = 0
        Width = 332
        Height = 411
        Align = alClient
        BevelOuter = bvNone
        Caption = 'Panel2'
        TabOrder = 2
        object Label4: TLabel
          Left = 0
          Top = 0
          Width = 65
          Height = 13
          Align = alTop
          Caption = 'Update Fields'
        end
        object LstUpdFields: TListBox
          Left = 0
          Top = 13
          Width = 332
          Height = 398
          Align = alClient
          ItemHeight = 13
          MultiSelect = True
          TabOrder = 0
        end
      end
    end
    object shModifySQLs: TTabSheet
      Caption = 'Modify SQLs'
      ImageIndex = 2
      object grSQLKind: TRadioGroup
        Left = 0
        Top = 0
        Width = 690
        Height = 36
        Align = alTop
        Caption = 'Statement &Type'
        Columns = 5
        ItemIndex = 0
        Items.Strings = (
          '&Insert'
          '&Update'
          '&Delete '
          '&Refresh')
        TabOrder = 0
        OnClick = grSQLKindClick
      end
      inline ModifySQLEdit: TfSQLEdit
        Left = 0
        Top = 36
        Width = 690
        Height = 375
        Align = alClient
        ParentShowHint = False
        ShowHint = True
        TabOrder = 1
        TabStop = True
        inherited Splitter2: TSplitter
          Left = 440
          Height = 375
        end
        inherited Panel1: TPanel
          Width = 440
          Height = 375
          inherited splPlan: TSplitter
            Top = 352
            Width = 438
          end
          inherited Panel10: TPanel
            Width = 438
          end
          inherited StatusBar1: TStatusBar
            Top = 355
            Width = 438
          end
        end
        inherited Panel6: TPanel
          Left = 443
          Height = 375
          inherited GroupBox1: TGroupBox
            Height = 307
            inherited Panel2: TPanel
              Height = 243
              inherited DBGrid2: TDBGrid
                Height = 58
              end
              inherited Panel4: TPanel
                Top = 151
              end
            end
          end
        end
      end
    end
  end
end
