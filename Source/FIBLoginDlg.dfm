object FIBLoginForm: TFIBLoginForm
  Left = 328
  Top = 272
  Width = 331
  Height = 222
  HorzScrollBar.Range = 318
  VertScrollBar.Range = 185
  ActiveControl = EdPassword
  BorderStyle = bsDialog
  Caption = 'Database login'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Pitch = fpVariable
  Font.Style = []
  OldCreateOrder = True
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 15
  object Bevel1: TBevel
    Left = 8
    Top = 8
    Width = 309
    Height = 40
    Shape = bsFrame
  end
  object Bevel2: TBevel
    Left = 8
    Top = 53
    Width = 309
    Height = 87
    Shape = bsFrame
  end
  object Label1: TLabel
    Left = 13
    Top = 3
    Width = 63
    Height = 13
    Caption = 'Database :'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Pitch = fpVariable
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lbDBName: TLabel
    Left = 11
    Top = 21
    Width = 301
    Height = 15
    AutoSize = False
    Caption = 'lbDBName'
  end
  object Label2: TLabel
    Left = 16
    Top = 65
    Width = 59
    Height = 13
    Caption = 'User Name :'
    FocusControl = EdUserName
  end
  object Label3: TLabel
    Left = 16
    Top = 89
    Width = 52
    Height = 13
    Caption = 'Password :'
    FocusControl = EdPassword
  end
  object Label4: TLabel
    Left = 16
    Top = 112
    Width = 28
    Height = 13
    Caption = 'Role :'
    FocusControl = EdRole
  end
  object Button1: TButton
    Left = 164
    Top = 150
    Width = 75
    Height = 25
    Caption = '&OK'
    Default = True
    ModalResult = 1
    TabOrder = 0
  end
  object Button2: TButton
    Left = 244
    Top = 150
    Width = 75
    Height = 25
    Cancel = True
    Caption = '&Cancel'
    ModalResult = 2
    TabOrder = 1
  end
  object EdUserName: TEdit
    Left = 130
    Top = 62
    Width = 179
    Height = 21
    TabOrder = 2
  end
  object EdPassword: TEdit
    Left = 130
    Top = 86
    Width = 179
    Height = 21
    PasswordChar = '*'
    TabOrder = 3
  end
  object EdRole: TEdit
    Left = 130
    Top = 110
    Width = 179
    Height = 21
    TabOrder = 4
  end
end
