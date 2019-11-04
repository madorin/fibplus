object Form1: TForm1
  Left = 269
  Top = 164
  Width = 669
  Height = 414
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
    Width = 661
    Height = 19
    Align = alTop
    AutoSize = False
    Caption = '  Job Dataset'
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
    Top = 361
    Width = 661
    Height = 19
    Panels = <>
    SimplePanel = True
    SimpleText = ' Copyrigth (C) Devrace 2000-2005'
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 661
    Height = 57
    Align = alTop
    BevelOuter = bvNone
    Color = clTeal
    TabOrder = 1
    object Label1: TLabel
      Left = 8
      Top = 8
      Width = 577
      Height = 41
      AutoSize = False
      Caption = 
        'This Example demonstrate using Interbase/Firebird Array-Fields .' +
        '..'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      WordWrap = True
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 76
    Width = 661
    Height = 285
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object DBGrid1: TDBGrid
      Left = 0
      Top = 0
      Width = 439
      Height = 285
      Align = alClient
      BorderStyle = bsNone
      Ctl3D = True
      DataSource = ds
      ParentCtl3D = False
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
    end
    object Panel3: TPanel
      Left = 439
      Top = 0
      Width = 222
      Height = 285
      Align = alRight
      BevelOuter = bvNone
      TabOrder = 1
      DesignSize = (
        222
        285)
      object GroupBox3: TGroupBox
        Left = 6
        Top = 161
        Width = 213
        Height = 123
        Anchors = [akLeft, akTop, akBottom]
        Caption = 'JOB_REQUIREMENT'
        TabOrder = 0
        DesignSize = (
          213
          123)
        object DBMemo1: TDBMemo
          Left = 6
          Top = 15
          Width = 201
          Height = 99
          Anchors = [akLeft, akTop, akRight, akBottom]
          DataField = 'JOB_REQUIREMENT'
          DataSource = ds
          TabOrder = 0
        end
      end
      object GroupBox2: TGroupBox
        Left = 5
        Top = 3
        Width = 214
        Height = 154
        Caption = 'LANGUAGE_REQ :VARCHAR(15) [1:5]'
        TabOrder = 1
        object Edit1: TEdit
          Left = 7
          Top = 22
          Width = 200
          Height = 21
          TabOrder = 0
          Text = 'Edit1'
          OnChange = Edit1Change
        end
        object Edit2: TEdit
          Left = 7
          Top = 48
          Width = 200
          Height = 21
          TabOrder = 1
          Text = 'Edit2'
          OnChange = Edit1Change
        end
        object Edit3: TEdit
          Left = 7
          Top = 74
          Width = 200
          Height = 21
          TabOrder = 2
          Text = 'Edit3'
          OnChange = Edit1Change
        end
        object Edit4: TEdit
          Left = 7
          Top = 100
          Width = 200
          Height = 21
          TabOrder = 3
          Text = 'Edit4'
          OnChange = Edit1Change
        end
        object Edit5: TEdit
          Left = 7
          Top = 126
          Width = 200
          Height = 21
          TabOrder = 4
          Text = 'Edit5'
          OnChange = Edit1Change
        end
      end
    end
  end
  object db: TpFIBDatabase
    DBName = 'localhost:D:\home\devrace\FIBPlusExamples\db\EMPLOYEE.FDB'
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
    SelectSQL.Strings = (
      'SELECT'
      '    JOB.JOB_CODE,'
      '    JOB.JOB_GRADE,'
      '    JOB.JOB_COUNTRY,'
      '    JOB.JOB_TITLE,'
      '    JOB.MIN_SALARY,'
      '    JOB.MAX_SALARY,'
      '    JOB.JOB_REQUIREMENT,'
      '    JOB.LANGUAGE_REQ'
      'FROM'
      '    JOB JOB'
      'ORDER BY'
      '    1, 2, 3')
    AutoUpdateOptions.UpdateTableName = 'JOB'
    AutoUpdateOptions.KeyFields = 'JOB_CODE;JOB_GRADE;JOB_COUNTRY'
    AutoUpdateOptions.AutoReWriteSqls = True
    AutoUpdateOptions.CanChangeSQLs = True
    AutoUpdateOptions.GeneratorName = 'GEN_JOB_ID'
    AutoUpdateOptions.UpdateOnlyModifiedFields = True
    AfterScroll = dtAfterScroll
    BeforePost = dtBeforePost
    OnPostError = dtPostError
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
