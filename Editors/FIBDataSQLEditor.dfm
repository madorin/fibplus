object frmDstSQLedit: TfrmDstSQLedit
  Left = 200
  Top = 299
  Width = 742
  Height = 462
  Caption = 'frmDstSQLedit'
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
  object Panel1: TPanel
    Left = 0
    Top = 398
    Width = 734
    Height = 37
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 0
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
  inline fSQLsEdit: TfDSSQLEdit
    Left = 0
    Top = 0
    Width = 734
    Height = 398
    Align = alClient
    TabOrder = 1
    TabStop = True
    inherited pgCtrl: TPageControl
      Width = 734
      Height = 398
      ActivePage = fSQLsEdit.shSelect
      inherited shSelect: TTabSheet
        inherited SelectSQLEdit: TfSQLEdit
          Width = 726
          Height = 370
          inherited Splitter2: TSplitter
            Left = 476
            Height = 370
          end
          inherited Panel1: TPanel
            Width = 476
            Height = 370
            inherited splPlan: TSplitter
              Top = 347
              Width = 474
            end
            inherited Panel10: TPanel
              Width = 474
              inherited btnGenSQL: TSpeedButton
                Left = 349
              end
            end
            inherited StatusBar1: TStatusBar
              Top = 350
              Width = 474
            end
          end
          inherited Panel6: TPanel
            Left = 479
            Height = 370
            inherited GroupBox1: TGroupBox
              Height = 302
              inherited Panel2: TPanel
                Height = 238
                inherited DBGrid2: TDBGrid
                  Height = 53
                end
                inherited Panel4: TPanel
                  Top = 146
                end
              end
            end
          end
          inherited dsFields: TDataSource
            Left = 200
            Top = 168
          end
        end
      end
      inherited shModifySQLs: TTabSheet
        inherited grSQLKind: TRadioGroup
          Width = 726
        end
        inherited ModifySQLEdit: TfSQLEdit
          Width = 726
          Height = 334
          inherited Splitter2: TSplitter
            Left = 476
            Height = 334
          end
          inherited Panel1: TPanel
            Width = 476
            Height = 334
            inherited splPlan: TSplitter
              Top = 304
              Width = 458
            end
            inherited Panel10: TPanel
              Width = 458
              inherited btnGenSQL: TSpeedButton
                Left = 365
              end
              inherited btnReplaceZv: TSpeedButton
                Visible = False
              end
            end
            inherited StatusBar1: TStatusBar
              Top = 307
              Width = 458
            end
          end
          inherited Panel6: TPanel
            Left = 479
            Height = 334
            inherited GroupBox1: TGroupBox
              Height = 266
              inherited Panel2: TPanel
                Height = 202
                inherited DBGrid2: TDBGrid
                  Height = 10
                end
                inherited Panel4: TPanel
                  Top = 103
                  inherited edDomain: TDBEdit
                    Width = 149
                  end
                  inherited edFieldType: TEdit
                    Width = 141
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
