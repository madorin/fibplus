object frmTransEdit: TfrmTransEdit
  Left = 486
  Top = 315
  BorderStyle = bsDialog
  Caption = 'Transaction Editor'
  ClientHeight = 228
  ClientWidth = 342
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
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 88
    Height = 13
    Caption = 'Kind of transaction'
    FocusControl = cmbProps
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object Label2: TLabel
    Left = 8
    Top = 35
    Width = 41
    Height = 13
    Caption = '&Settings:'
    FocusControl = memParams
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object Bevel1: TBevel
    Left = 234
    Top = 52
    Width = 103
    Height = 133
    Shape = bsFrame
  end
  object cmbProps: TComboBox
    Left = 112
    Top = 5
    Width = 225
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 0
    OnChange = cmbPropsChange
    Items.Strings = (
      'Current parameters '
      'ReadCommitted'
      'RepeatableRead'
      'ReadOnly ReadCommitted')
  end
  object memParams: TMemo
    Left = 8
    Top = 52
    Width = 217
    Height = 133
    TabOrder = 1
  end
  object Button1: TButton
    Left = 179
    Top = 195
    Width = 75
    Height = 25
    Caption = '&OK'
    Default = True
    ModalResult = 1
    TabOrder = 2
  end
  object Button2: TButton
    Left = 261
    Top = 195
    Width = 75
    Height = 25
    Cancel = True
    Caption = '&Cancel'
    ModalResult = 2
    TabOrder = 3
  end
  object Button3: TButton
    Left = 242
    Top = 64
    Width = 85
    Height = 25
    Caption = '&New Kind'
    TabOrder = 4
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 242
    Top = 91
    Width = 85
    Height = 25
    Caption = '&Save kind'
    TabOrder = 5
    OnClick = Button4Click
  end
  object Button5: TButton
    Left = 242
    Top = 118
    Width = 85
    Height = 25
    Caption = '&Export to Ini'
    TabOrder = 6
    OnClick = Button5Click
  end
  object Button6: TButton
    Left = 242
    Top = 146
    Width = 85
    Height = 25
    Caption = '&Import from Ini'
    TabOrder = 7
    OnClick = Button6Click
  end
  object OpenDialog1: TOpenDialog
    DefaultExt = 'trk'
    Filter = 'Transaction Kinds *.trk|*.trk|*.ini |*.ini'
    Left = 88
    Top = 64
  end
  object SaveDialog1: TSaveDialog
    DefaultExt = 'trk'
    Filter = 'Transaction Kinds *.trk|*.trk'
    Title = 'Export transaction settings to file'
    Left = 88
    Top = 112
  end
end
