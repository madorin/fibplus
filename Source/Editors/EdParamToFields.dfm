object frmEdParamToFields: TfrmEdParamToFields
  Left = 414
  Top = 158
  BorderStyle = bsToolWindow
  Caption = 'Edit Params to Fields Links '
  ClientHeight = 351
  ClientWidth = 420
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = True
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter2: TSplitter
    Left = 0
    Top = 198
    Width = 420
    Height = 2
    Cursor = crVSplit
    Align = alBottom
  end
  object Memo1: TMemo
    Left = 0
    Top = 200
    Width = 420
    Height = 110
    Align = alBottom
    TabOrder = 0
  end
  object Panel1: TPanel
    Left = 0
    Top = 310
    Width = 420
    Height = 41
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object Button1: TButton
      Left = 256
      Top = 10
      Width = 75
      Height = 25
      Caption = '&OK'
      ModalResult = 1
      TabOrder = 0
    end
    object Button2: TButton
      Left = 336
      Top = 10
      Width = 75
      Height = 25
      Caption = '&Cancel'
      ModalResult = 2
      TabOrder = 1
    end
    object Button3: TButton
      Left = 7
      Top = 10
      Width = 75
      Height = 25
      Caption = '&Add'
      TabOrder = 2
      OnClick = Button3Click
    end
    object Button4: TButton
      Left = 87
      Top = 10
      Width = 75
      Height = 25
      Caption = '&Scan'
      TabOrder = 3
      OnClick = Button4Click
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 0
    Width = 420
    Height = 198
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object Splitter1: TSplitter
      Left = 202
      Top = 16
      Width = 2
      Height = 182
      OnMoved = Splitter1Moved
    end
    object lstFields: TListBox
      Left = 0
      Top = 16
      Width = 202
      Height = 182
      Align = alLeft
      ItemHeight = 13
      TabOrder = 0
    end
    object lstParams: TListBox
      Left = 204
      Top = 16
      Width = 216
      Height = 182
      Align = alClient
      ItemHeight = 13
      TabOrder = 1
    end
    object Panel3: TPanel
      Left = 0
      Top = 0
      Width = 420
      Height = 16
      Align = alTop
      BevelOuter = bvLowered
      TabOrder = 2
      object Label1: TLabel
        Left = 5
        Top = 2
        Width = 27
        Height = 13
        Caption = 'Fields'
      end
      object Label2: TLabel
        Left = 201
        Top = 1
        Width = 35
        Height = 13
        Caption = 'Params'
      end
    end
  end
end
