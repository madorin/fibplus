object frmSQLEdit: TfrmSQLEdit
  Left = 474
  Top = 344
  Width = 798
  Height = 463
  Caption = 'frmSQLEdit'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  PixelsPerInch = 96
  TextHeight = 15
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
      Left = 497
      Height = 399
    end
    inherited Panel1: TPanel
      Width = 497
      Height = 399
      inherited splPlan: TSplitter
        Top = 376
        Width = 495
      end
      inherited Panel10: TPanel
        Width = 495
        inherited SpeedButton1: TSpeedButton
          OnClick = fSQLEdit1SpeedButton1Click
        end
        inherited btnShowDDL: TSpeedButton
          OnClick = fSQLEdit1btnShowDDLClick
        end
      end
      inherited StatusBar1: TStatusBar
        Top = 379
        Width = 495
      end
    end
    inherited Panel6: TPanel
      Left = 500
      Height = 399
      inherited GroupBox1: TGroupBox
        Height = 315
        inherited Panel2: TPanel
          Height = 251
          inherited Splitter1: TSplitter
            Height = 3
          end
          inherited DBGrid2: TDBGrid
            Top = 92
            Height = 66
          end
          inherited Panel4: TPanel
            Top = 159
            inherited edDomain: TDBEdit
              Width = 152
            end
            inherited edFieldType: TEdit
              Width = 144
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
    object btnOK: TBitBtn
      Left = 626
      Top = 8
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = '&OK'
      ModalResult = 1
      TabOrder = 0
      NumGlyphs = 2
    end
    object btnCancel: TBitBtn
      Left = 707
      Top = 8
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = '&Cancel'
      ModalResult = 2
      TabOrder = 1
      NumGlyphs = 2
    end
  end
end
