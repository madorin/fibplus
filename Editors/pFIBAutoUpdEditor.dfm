object pFIBAutoUpdateOptionForm: TpFIBAutoUpdateOptionForm
  Left = 291
  Top = 241
  BorderStyle = bsDialog
  Caption = '%s - AutoUpdateOptions Editor'
  ClientHeight = 295
  ClientWidth = 330
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
  object OkB: TButton
    Left = 158
    Top = 262
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 0
  end
  object CancelB: TButton
    Left = 245
    Top = 262
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 1
  end
  inline fAutoUpdateOptionForm1: TfAutoUpdateOptionForm
    Left = 0
    Top = 0
    Width = 330
    Height = 262
    Align = alTop
    TabOrder = 2
    ExplicitWidth = 330
    inherited PrimaryKeyL: TLabel
      Width = 90
      ExplicitWidth = 90
    end
    inherited ModTableL: TLabel
      Width = 71
      ExplicitWidth = 71
    end
    inherited GroupBox2: TGroupBox
      inherited GenNameL: TLabel
        Width = 78
        ExplicitWidth = 78
      end
      inherited Label1: TLabel
        Width = 72
        ExplicitWidth = 72
      end
    end
  end
end
