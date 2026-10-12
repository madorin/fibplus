object frmEditCheckStrings: TfrmEditCheckStrings
  Left = 197
  Top = 124
  Caption = 'Edit Conditions '
  ClientHeight = 334
  ClientWidth = 458
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
  inline fraEdConditions1: TfraEdConditions
    Left = 0
    Top = 0
    Width = 458
    Height = 334
    Align = alClient
    TabOrder = 0
    TabStop = True
    ExplicitWidth = 458
    ExplicitHeight = 327
    inherited Panel1: TPanel
      Width = 368
      Height = 327
      ExplicitWidth = 368
      ExplicitHeight = 327
      inherited Splitter1: TSplitter
        Top = 193
        Width = 360
        ExplicitTop = 193
        ExplicitWidth = 360
      end
      inherited GroupBox2: TGroupBox
        Width = 360
        Height = 189
        ExplicitWidth = 360
        ExplicitHeight = 189
        inherited Panel3: TPanel
          Width = 356
          Height = 172
          ExplicitWidth = 356
          ExplicitHeight = 172
          inherited Memo1: TMemo
            Width = 348
            Height = 164
            ExplicitWidth = 348
            ExplicitHeight = 164
          end
        end
      end
      inherited GroupBox1: TGroupBox
        Top = 197
        Width = 360
        ExplicitTop = 197
        ExplicitWidth = 360
        inherited Panel4: TPanel
          Width = 356
          ExplicitWidth = 356
          inherited ListView1: TListView
            Width = 348
            ExplicitWidth = 348
          end
        end
      end
    end
    inherited Panel2: TPanel
      Left = 368
      Height = 327
      ExplicitLeft = 368
      ExplicitHeight = 327
    end
  end
end
