object Form1: TForm1
  Left = 38
  Top = 167
  Width = 783
  Height = 412
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
    Width = 775
    Height = 19
    Align = alTop
    AutoSize = False
    Caption = '  Unicode Data'
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
    Top = 359
    Width = 775
    Height = 19
    Panels = <>
    SimplePanel = True
    SimpleText = ' Copyrigth (C) Devrace 2000-2005'
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 775
    Height = 57
    Align = alTop
    BevelOuter = bvNone
    Color = clTeal
    TabOrder = 1
    object Label1: TLabel
      Left = 8
      Top = 8
      Width = 609
      Height = 41
      AutoSize = False
      Caption = 
        'This Example demonstrate using UNICODE_FSS Database. '#1042#1072#1084' '#1087#1086#1085#1072#1076#1086#1073 +
        #1103#1090#1089#1103' TntControls '#1082#1086#1085#1090#1088#1086#1083#1099' '#1089' '#1087#1086#1076#1076#1077#1088#1078#1082#1086#1081' Unicode (http://tnt.ccci.' +
        'org/delphi_unicode_controls/).'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      WordWrap = True
    end
  end
  object TntDBGrid1: TTntDBGrid
    Left = 0
    Top = 108
    Width = 775
    Height = 251
    Align = alClient
    DataSource = ds
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
  end
  object Panel2: TPanel
    Left = 0
    Top = 76
    Width = 775
    Height = 32
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 3
    object Label3: TLabel
      Left = 8
      Top = 8
      Width = 56
      Height = 13
      Caption = 'Field Name:'
    end
    object Label4: TLabel
      Left = 192
      Top = 8
      Width = 55
      Height = 13
      Caption = 'Field Value:'
    end
    object Label5: TLabel
      Left = 72
      Top = 8
      Width = 111
      Height = 13
      Caption = 'UNICODE_STRING'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object TntEdit1: TTntEdit
      Left = 256
      Top = 5
      Width = 135
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      Text = 'TntEdit1'
    end
    object Button1: TButton
      Left = 400
      Top = 3
      Width = 89
      Height = 25
      Caption = 'Locate by String'
      TabOrder = 1
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 496
      Top = 3
      Width = 129
      Height = 25
      Caption = 'Find ID and locate by ID'
      TabOrder = 2
      OnClick = Button2Click
    end
    object Button3: TButton
      Left = 631
      Top = 4
      Width = 138
      Height = 25
      Caption = 'Find ID and locate by ID 2'
      TabOrder = 3
      OnClick = Button3Click
    end
  end
  object db: TpFIBDatabase
    DBName = 'localhost:D:\home\devrace\FIBPlusExamples\db\EMPLOYEE.FDB'
    DBParams.Strings = (
      'lc_ctype=UNICODE_FSS'
      'user_name=SYSDBA'
      'password=masterkey')
    DefaultTransaction = tr
    DefaultUpdateTransaction = tr
    SQLDialect = 3
    Timeout = 0
    UpperOldNames = True
    DesignDBOptions = []
    WaitForRestoreConnect = 0
    Left = 504
    Top = 8
  end
  object tr: TpFIBTransaction
    DefaultDatabase = db
    TimeoutAction = TARollback
    Left = 536
    Top = 8
  end
  object dt: TpFIBDataSet
    CachedUpdates = True
    UpdateSQL.Strings = (
      'UPDATE UNICODE_TABLE'
      'SET '
      '    UNICODE_STRING = :UNICODE_STRING'
      'WHERE'
      '    ID = :OLD_ID'
      '    ')
    DeleteSQL.Strings = (
      'DELETE FROM'
      '    UNICODE_TABLE'
      'WHERE'
      '        ID = :OLD_ID'
      '    ')
    InsertSQL.Strings = (
      'INSERT INTO UNICODE_TABLE('
      '    ID,'
      '    UNICODE_STRING'
      ')'
      'VALUES('
      '    :ID,'
      '    :UNICODE_STRING'
      ')')
    RefreshSQL.Strings = (
      'SELECT'
      '    ID,'
      '    UNICODE_STRING'
      'FROM'
      '    UNICODE_TABLE '
      ''
      ' WHERE '
      '        UNICODE_TABLE.ID = :OLD_ID'
      '    ')
    SelectSQL.Strings = (
      'SELECT'
      '    ID,'
      '    UNICODE_STRING'
      'FROM'
      '    UNICODE_TABLE ')
    AutoUpdateOptions.UpdateTableName = 'UNICODE_TABLE'
    AutoUpdateOptions.KeyFields = 'ID'
    AutoUpdateOptions.GeneratorName = 'GEN_UNICODE_TABLE_ID'
    AutoUpdateOptions.WhenGetGenID = wgBeforePost
    Transaction = tr
    Database = db
    AutoCommit = True
    Left = 504
    Top = 40
  end
  object ds: TDataSource
    DataSet = dt
    Left = 536
    Top = 40
  end
end
