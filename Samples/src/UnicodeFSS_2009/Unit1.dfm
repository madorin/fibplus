object Form1: TForm1
  Left = 38
  Top = 167
  Caption = 'FIBPlus Example - Xyz'
  ClientHeight = 378
  ClientWidth = 775
  Color = clBtnFace
  Font.Charset = RUSSIAN_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
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
    SimpleText = '  Copyright (C) Devrace 2000-2008'
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 775
    Height = 57
    Align = alTop
    BevelOuter = bvNone
    Color = clTeal
    ParentBackground = False
    TabOrder = 1
    object Label1: TLabel
      Left = 8
      Top = 8
      Width = 609
      Height = 41
      AutoSize = False
      Caption = 'This Example demonstrate using UNICODE_FSS Database. '
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      WordWrap = True
    end
  end
  object TntDBGrid1: TDBGrid
    Left = 0
    Top = 108
    Width = 775
    Height = 251
    Align = alClient
    DataSource = ds
    TabOrder = 2
    TitleFont.Charset = RUSSIAN_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
    Columns = <
      item
        Color = clMoneyGreen
        Expanded = False
        FieldName = 'ID'
        ReadOnly = True
        Title.Color = clMoneyGreen
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'UNICODE_STRING'
        Width = 673
        Visible = True
      end>
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
    object TntEdit1: TEdit
      Left = 256
      Top = 5
      Width = 135
      Height = 21
      TabOrder = 0
    end
    object Button1: TButton
      Left = 401
      Top = 6
      Width = 89
      Height = 25
      Caption = 'Locate by String'
      TabOrder = 1
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 496
      Top = 6
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
    DBName = 'localhost:I:\Tiburon\FIBPlusExamples\db\EMPLOYEE.FDB'
    DBParams.Strings = (
      'lc_ctype=UNICODE_FSS'
      'user_name=SYSDBA'
      'password=masterkey'
      'sql_role_name=')
    DefaultTransaction = tr
    DefaultUpdateTransaction = tr
    SQLDialect = 3
    Timeout = 0
    UpperOldNames = True
    DesignDBOptions = []
    LibraryName = 'fbclient.dll'
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
