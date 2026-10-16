object FIBAboutForm: TFIBAboutForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'About FIBPlus'
  ClientHeight = 193
  ClientWidth = 456
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 15
  object IconCollection: TImageCollection
    Left = 8
    Top = 152
  end
  object IconImage: TVirtualImage
    Left = 20
    Top = 20
    Width = 128
    Height = 128
    ImageCollection = IconCollection
  end
  object ProductLabel: TLabel
    Left = 168
    Top = 20
    Width = 268
    Height = 25
    AutoSize = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object DescriptionLabel: TLabel
    Left = 168
    Top = 56
    Width = 268
    Height = 36
    AutoSize = False
    WordWrap = True
  end
  object ProjectLink: TLinkLabel
    Left = 168
    Top = 104
    Width = 268
    Height = 19
    TabOrder = 0
    UseVisualStyle = True
    OnLinkClick = LinkClick
  end
  object SupportLink: TLinkLabel
    Left = 168
    Top = 129
    Width = 268
    Height = 19
    TabOrder = 1
    UseVisualStyle = True
    OnLinkClick = LinkClick
  end
  object OKButton: TButton
    Left = 361
    Top = 148
    Width = 75
    Height = 25
    Default = True
    Cancel = True
    ModalResult = 1
    TabOrder = 2
  end
end
