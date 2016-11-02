object fAutoUpdateOptionForm: TfAutoUpdateOptionForm
  Left = 0
  Top = 0
  Width = 334
  Height = 262
  TabOrder = 0
  object PrimaryKeyL: TLabel
    Left = 8
    Top = 37
    Width = 90
    Height = 13
    Caption = 'Primary key field(s):'
  end
  object ModTableL: TLabel
    Left = 8
    Top = 11
    Width = 71
    Height = 13
    Caption = 'Modifying table'
  end
  object GroupBox1: TGroupBox
    Left = 8
    Top = 62
    Width = 318
    Height = 105
    Caption = ' SQL generation '
    TabOrder = 0
    object AllowChangeC: TCheckBox
      Left = 8
      Top = 24
      Width = 308
      Height = 17
      Caption = 'Allow changing SQL properties without closing DataSet'
      TabOrder = 0
    end
    object AutoGenC: TCheckBox
      Left = 8
      Top = 48
      Width = 308
      Height = 17
      Caption = 'Auto generation of modifying queries after DataSet opening'
      TabOrder = 1
      OnClick = AutoGenCClick
    end
    object ModFieldsC: TCheckBox
      Left = 8
      Top = 72
      Width = 308
      Height = 17
      Caption = 'Include in UpdateSQL only modified fields'
      Enabled = False
      TabOrder = 2
    end
  end
  object KeyC: TComboBox
    Left = 128
    Top = 34
    Width = 199
    Height = 21
    ItemHeight = 13
    TabOrder = 1
  end
  object GroupBox2: TGroupBox
    Left = 8
    Top = 168
    Width = 318
    Height = 85
    Caption = ' Auto increment options '
    TabOrder = 2
    object GenNameL: TLabel
      Left = 8
      Top = 17
      Width = 78
      Height = 13
      Caption = 'Generator Name'
    end
    object Label1: TLabel
      Left = 209
      Top = 14
      Width = 72
      Height = 13
      Caption = 'Generator Step'
    end
    object GenC: TComboBox
      Left = 9
      Top = 34
      Width = 193
      Height = 21
      ItemHeight = 13
      TabOrder = 0
    end
    object WhenGetC: TComboBox
      Left = 8
      Top = 58
      Width = 279
      Height = 21
      Style = csDropDownList
      ItemHeight = 13
      TabOrder = 1
    end
    object edGenStep: TEdit
      Left = 218
      Top = 33
      Width = 67
      Height = 21
      TabOrder = 2
      OnKeyPress = edGenStepKeyPress
    end
  end
  object TableC: TComboBox
    Left = 128
    Top = 8
    Width = 199
    Height = 21
    ItemHeight = 13
    TabOrder = 3
  end
end
