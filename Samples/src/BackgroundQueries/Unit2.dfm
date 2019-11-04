object ThreadSQLForm: TThreadSQLForm
  Left = 383
  Top = 285
  Width = 505
  Height = 292
  Caption = 'Custom Backgound Query ...'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCloseQuery = FormCloseQuery
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 65
    Width = 497
    Height = 158
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object DBGrid1: TDBGrid
      Left = 0
      Top = 0
      Width = 497
      Height = 158
      Align = alClient
      DataSource = ds
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 0
    Width = 497
    Height = 65
    Align = alTop
    BevelInner = bvRaised
    BevelOuter = bvLowered
    TabOrder = 1
    object memSQL: TMemo
      Left = 2
      Top = 2
      Width = 493
      Height = 61
      Align = alClient
      BorderStyle = bsNone
      Color = clGrayText
      Ctl3D = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentCtl3D = False
      ParentFont = False
      ScrollBars = ssBoth
      TabOrder = 0
    end
  end
  object Panel3: TPanel
    Left = 0
    Top = 223
    Width = 497
    Height = 35
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object Label1: TLabel
      Left = 8
      Top = 10
      Width = 32
      Height = 13
      Caption = 'Label1'
    end
    object Label2: TLabel
      Left = 138
      Top = 10
      Width = 8
      Height = 13
      Alignment = taRightJustify
      Caption = '0'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label3: TLabel
      Left = 152
      Top = 10
      Width = 17
      Height = 13
      Caption = 'sec'
    end
    object BitBtn1: TBitBtn
      Left = 405
      Top = 8
      Width = 75
      Height = 25
      Anchors = [akRight, akBottom]
      TabOrder = 0
      Kind = bkClose
    end
  end
  object ds: TDataSource
    Left = 328
    Top = 16
  end
  object dba: TpFIBDatabase
    DBParams.Strings = (
      '')
    DefaultTransaction = tra
    DefaultUpdateTransaction = tra
    SQLDialect = 3
    Timeout = 0
    WaitForRestoreConnect = 0
    Left = 232
    Top = 16
  end
  object dt: TpFIBDataSet
    Transaction = tra
    Database = dba
    DefaultFormats.DateTimeDisplayFormat = 'dd.mm.yyyy'
    Left = 264
    Top = 16
    poApplyRepositary = True
    dcForceMasterRefresh = True
    dcForceOpen = True
  end
  object tra: TpFIBTransaction
    DefaultDatabase = dba
    TimeoutAction = TARollback
    Left = 296
    Top = 16
  end
  object Timer1: TTimer
    OnTimer = Timer1Timer
    Left = 136
    Top = 105
  end
end
