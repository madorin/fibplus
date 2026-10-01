object frmSQLEdit: TfrmSQLEdit
  Left = 474
  Top = 344
  Width = 798
  Height = 463
  Caption = 'frmSQLEdit'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  PixelsPerInch = 96
  TextHeight = 13
  inline fSQLEdit1: TfSQLEdit
    Left = 0
    Top = 0
    Width = 790
    Height = 399
    Align = alClient
    ParentShowHint = False
    ShowHint = True
    TabOrder = 0
    TabStop = True
    inherited Splitter2: TSplitter
      Left = 540
      Height = 399
    end
    inherited Panel1: TPanel
      Width = 540
      Height = 399
      inherited splPlan: TSplitter
        Top = 376
        Width = 538
      end
      inherited Panel10: TPanel
        Width = 538
        inherited SpeedButton1: TSpeedButton
          OnClick = fSQLEdit1SpeedButton1Click
        end
        inherited btnShowDDL: TSpeedButton
          OnClick = fSQLEdit1btnShowDDLClick
        end
      end
      inherited StatusBar1: TStatusBar
        Top = 379
        Width = 538
      end
    end
    inherited Panel6: TPanel
      Left = 543
      Height = 399
      inherited GroupBox1: TGroupBox
        Height = 331
        inherited Panel2: TPanel
          Height = 267
          inherited Splitter1: TSplitter
            Height = 3
          end
          inherited DBGrid2: TDBGrid
            Top = 92
            Height = 83
          end
          inherited Panel4: TPanel
            Top = 175
            inherited edDomain: TDBEdit
              Width = 145
            end
            inherited edFieldType: TEdit
              Width = 137
            end
          end
        end
      end
    end
    inherited ds: TDataSource
      Left = 284
      Top = 160
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 399
    Width = 790
    Height = 37
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    OnResize = Panel1Resize
    object btnOK: TBitBtn
      Left = 546
      Top = 8
      Width = 73
      Height = 25
      Caption = '&OK'
      ModalResult = 1
      TabOrder = 0
      NumGlyphs = 2
    end
    object btnCancel: TBitBtn
      Left = 626
      Top = 8
      Width = 75
      Height = 25
      Cancel = True
      Caption = '&Cancel'
      ModalResult = 2
      TabOrder = 1
      NumGlyphs = 2
    end
  end
end
