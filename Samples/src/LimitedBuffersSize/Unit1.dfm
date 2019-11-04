object Form1: TForm1
  Left = 68
  Top = 136
  Width = 801
  Height = 467
  Caption = 'FIBPlus Example - Xyz'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label2: TLabel
    Left = 0
    Top = 57
    Width = 793
    Height = 19
    Align = alTop
    AutoSize = False
    Caption = '  Bigtable Data'
    Color = clBtnShadow
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentColor = False
    ParentFont = False
    Layout = tlCenter
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 414
    Width = 793
    Height = 19
    Panels = <>
    SimplePanel = True
    SimpleText = ' Copyright (C) Devrace 2000-2009'
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 793
    Height = 57
    Align = alTop
    BevelOuter = bvNone
    Color = clTeal
    TabOrder = 1
    object Label1: TLabel
      Left = 8
      Top = 8
      Width = 777
      Height = 41
      AutoSize = False
      Caption = 
        'This Example demonstrate simple using TpFIBDataSet LimitedBuffer' +
        'sSize. Press button "Prepare large table" '
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      WordWrap = True
    end
  end
  object PageControl1: TPageControl
    Left = 0
    Top = 76
    Width = 793
    Height = 338
    ActivePage = TabSheet2
    Align = alClient
    TabOrder = 2
    OnChange = PageControl1Change
    object TabSheet1: TTabSheet
      Caption = 'Standard Mode'
      object DBGrid1: TDBGrid
        Left = 0
        Top = 0
        Width = 785
        Height = 317
        Align = alClient
        Ctl3D = True
        DataSource = ds
        Options = [dgEditing, dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit]
        ParentCtl3D = False
        TabOrder = 0
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'MS Sans Serif'
        TitleFont.Style = []
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'LimitedBuffersSize Mode'
      ImageIndex = 1
      object DBGrid2: TDBGrid
        Left = 0
        Top = 0
        Width = 785
        Height = 310
        Align = alClient
        Ctl3D = True
        DataSource = dsLim
        Options = [dgEditing, dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit]
        ParentCtl3D = False
        TabOrder = 0
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'MS Sans Serif'
        TitleFont.Style = []
      end
    end
  end
  object Button1: TButton
    Left = 668
    Top = 76
    Width = 124
    Height = 20
    Anchors = [akTop, akRight]
    Caption = 'Prepare large table'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 3
    OnClick = Button1Click
  end
  object db: TpFIBDatabase
    DBName = 
      'localhost:E:\nv\documents\0000\devrace\FIBPlusExamples\db\EMPLOY' +
      'EE.FDB'
    DBParams.Strings = (
      'lc_ctype=NONE'
      'user_name=SYSDBA'
      'password=masterkey')
    DefaultTransaction = tr
    DefaultUpdateTransaction = tr
    SQLDialect = 3
    Timeout = 0
    UpperOldNames = True
    DesignDBOptions = []
    WaitForRestoreConnect = 0
    Left = 456
    Top = 8
  end
  object tr: TpFIBTransaction
    DefaultDatabase = db
    TimeoutAction = TARollback
    Left = 488
    Top = 8
  end
  object dt: TpFIBDataSet
    SelectSQL.Strings = (
      'SELECT'
      '    M.ID,'
      '    M.NAME'
      '/*,    D.INT_VALUE*/'
      'FROM'
      '    BIGTABLE M'
      '/*    JOIN BIGTABLE_DETAIL D ON M.ID = D.BIGTABLE_ID */'
      'ORDER BY'
      '    M.NAME')
    AutoUpdateOptions.UpdateTableName = 'EMPLOYEE'
    AutoUpdateOptions.KeyFields = 'EMP_NO'
    AutoUpdateOptions.GeneratorName = 'EMP_NO_GEN'
    AutoUpdateOptions.WhenGetGenID = wgBeforePost
    Transaction = tr
    Database = db
    AutoCommit = True
    Left = 456
    Top = 40
  end
  object ds: TDataSource
    DataSet = dt
    Left = 488
    Top = 40
  end
  object dtLim: TpFIBDataSet
    SelectSQL.Strings = (
      'SELECT'
      '    M.ID,'
      '    M.NAME'
      '/*,    D.INT_VALUE*/'
      'FROM'
      '    BIGTABLE M'
      '/*    JOIN BIGTABLE_DETAIL D ON M.ID = D.BIGTABLE_ID */'
      'ORDER BY'
      '    M.NAME')
    CacheModelOptions.CacheModelKind = cmkLimitedBufferSize
    CacheModelOptions.BufferChunks = 100
    CacheModelOptions.PlanForDescSQLs = '(M ORDER IDX_BIGTABLE_NAME_DESC)'
    Transaction = tr
    Database = db
    AutoCommit = True
    Left = 456
    Top = 80
  end
  object dsLim: TDataSource
    DataSet = dtLim
    Left = 488
    Top = 80
  end
end
