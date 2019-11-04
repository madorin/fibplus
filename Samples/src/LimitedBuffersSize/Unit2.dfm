object Form2: TForm2
  Left = 169
  Top = 165
  Width = 406
  Height = 150
  BorderIcons = [biHelp]
  Caption = 'Please wait ...'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poMainFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 24
    Height = 13
    Caption = 'lblOp'
  end
  object lbProgress: TLabel
    Left = 8
    Top = 27
    Width = 8
    Height = 13
    Caption = 'N'
    Visible = False
  end
  object btnStop: TButton
    Left = 8
    Top = 72
    Width = 75
    Height = 25
    Caption = 'Stop'
    TabOrder = 0
    OnClick = btnStopClick
  end
  object ProgressBar1: TProgressBar
    Left = 8
    Top = 40
    Width = 385
    Height = 17
    Min = 0
    Max = 100
    Step = 1
    TabOrder = 1
  end
  object dtGenData: TpFIBDataSet
    UniDirectional = True
    SelectSQL.Strings = (
      'Select * from GEN_BIGTABLE_CONTENT(:CNT) ')
    BeforeOpen = dtGenDataBeforeOpen
    Transaction = Form1.tr
    Database = Form1.db
    AfterFetchRecord = dtGenDataAfterFetchRecord
    Left = 8
    Top = 48
  end
end
