object Form1: TForm1
  Left = 216
  Top = 152
  Width = 747
  Height = 461
  ActiveControl = DBGrid1
  Caption = 'FIBPlus Example - Xyz'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnClose = FormClose
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  DesignSize = (
    739
    427)
  PixelsPerInch = 96
  TextHeight = 13
  object Label2: TLabel
    Left = 0
    Top = 57
    Width = 739
    Height = 23
    Align = alTop
    AutoSize = False
    Caption = '  SQL Statistic Data'
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
  object Splitter1: TSplitter
    Left = 0
    Top = 208
    Width = 739
    Height = 7
    Cursor = crVSplit
    Align = alBottom
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 408
    Width = 739
    Height = 19
    Panels = <>
    SimplePanel = True
    SimpleText = ' Copyrigth (C) Devrace 2000-2005'
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 739
    Height = 57
    Align = alTop
    BevelOuter = bvNone
    Color = clTeal
    TabOrder = 1
    object Label1: TLabel
      Left = 8
      Top = 2
      Width = 697
      Height = 55
      AutoSize = False
      Caption = 
        'This Example demonstrate simple using FIBSQLLogger for explore d' +
        'atabase operation time-params. '#1050#1080#1076#1072#1077#1084' '#1085#1072' '#1092#1086#1088#1084#1091' '#1082#1086#1084#1087#1086#1085#1077#1085#1090', '#1085#1072#1089#1090#1088#1072 +
        #1080#1074#1072#1077#1084' '#1089#1086#1077#1076#1080#1085#1077#1085#1080#1077', '#1080#1076#1077#1085#1090#1080#1092#1080#1082#1072#1094#1080#1102' '#1087#1088#1080#1083#1086#1078#1077#1085#1080#1103' '#1080' '#1082#1072#1082#1080#1077' '#1086#1087#1077#1088#1072#1094#1080#1080' '#1085#1091#1078#1085 +
        #1086' '#1082#1086#1085#1090#1088#1086#1083#1080#1088#1086#1074#1072#1090#1100'. '#1048#1079' '#1082#1086#1085#1090#1077#1082#1089#1090#1085#1086#1075#1086' '#1084#1077#1085#1102' '#1082#1086#1084#1087#1086#1085#1077#1085#1090#1072' '#1089#1086#1079#1076#1072#1077#1084' '#1090#1072#1073#1083#1080#1094 +
        #1091' '#1076#1083#1103' '#1093#1088#1072#1085#1077#1085#1080#1103' '#1089#1090#1072#1090#1080#1089#1090#1080#1082#1080'. '#1056#1072#1073#1086#1090#1072#1077#1084' '#1074' '#1086#1073#1099#1095#1085#1086#1084' '#1088#1077#1078#1080#1084#1077' '#1080' '#1087#1086#1089#1083#1077' '#1101#1090#1086 +
        #1075#1086' '#1089#1086#1093#1088#1072#1085#1103#1077#1084' '#1089#1090#1072#1090#1080#1089#1090#1080#1082#1091' '#1074' '#1073#1072#1079#1091' '#1076#1072#1085#1085#1099#1093' '#1083#1080#1073#1086' '#1092#1072#1081#1083'.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      WordWrap = True
    end
  end
  object DBGrid1: TDBGrid
    Left = 0
    Top = 80
    Width = 739
    Height = 128
    Align = alClient
    Ctl3D = True
    DataSource = ds
    Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection, dgConfirmDelete, dgCancelOnExit]
    ParentCtl3D = False
    ReadOnly = True
    TabOrder = 2
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
    Columns = <
      item
        Expanded = False
        FieldName = 'ATTACHMENT_ID'
        Title.Caption = 'AtachmentID'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'APP_ID'
        Title.Caption = 'ApplicationID'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'EXECUTECOUNT'
        Title.Caption = 'Execute Count'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'PREPARECOUNT'
        Title.Caption = 'Prepare Count'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'SUMTIMEEXECUTE'
        Title.Caption = 'SUM time'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'AVGTIMEEXECUTE'
        Title.Caption = 'AVG Time'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'MAXTIMEEXECUTE'
        Title.Caption = 'MAX time'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'LASTTIMEEXECUTE'
        Title.Caption = 'Last time'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'LOG_DATE'
        Title.Caption = 'Log Date'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CMP_NAME'
        Title.Caption = 'Component'
        Width = 150
        Visible = True
      end>
  end
  object PageControl1: TPageControl
    Left = 0
    Top = 215
    Width = 739
    Height = 193
    ActivePage = TabSheet1
    Align = alBottom
    TabOrder = 3
    object TabSheet1: TTabSheet
      Caption = 'SQL Text'
      object DBMemo1: TDBMemo
        Left = 0
        Top = 0
        Width = 731
        Height = 165
        Align = alClient
        DataField = 'SQL_TEXT'
        DataSource = ds
        TabOrder = 0
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'Max Time Params'
      ImageIndex = 1
      object DBMemo2: TDBMemo
        Left = 0
        Top = 0
        Width = 839
        Height = 165
        Align = alClient
        DataField = 'MAXTIME_PARAMS'
        DataSource = ds
        TabOrder = 0
      end
    end
  end
  object Button1: TButton
    Left = 488
    Top = 56
    Width = 121
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Run Test Queries'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 4
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 616
    Top = 56
    Width = 121
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Show Log'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 5
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
    SQLLogger = FIBSQLLogger1
    WaitForRestoreConnect = 0
    Left = 584
    Top = 8
  end
  object tr: TpFIBTransaction
    DefaultDatabase = db
    TimeoutAction = TARollback
    Left = 616
    Top = 8
  end
  object dt: TpFIBDataSet
    UpdateSQL.Strings = (
      'UPDATE EMPLOYEE'
      'SET '
      '    FIRST_NAME = :FIRST_NAME,'
      '    LAST_NAME = :LAST_NAME,'
      '    PHONE_EXT = :PHONE_EXT,'
      '    HIRE_DATE = :HIRE_DATE,'
      '    DEPT_NO = :DEPT_NO,'
      '    JOB_CODE = :JOB_CODE,'
      '    JOB_GRADE = :JOB_GRADE,'
      '    JOB_COUNTRY = :JOB_COUNTRY,'
      '    SALARY = :SALARY'
      'WHERE'
      '    EMP_NO = :OLD_EMP_NO'
      '    ')
    DeleteSQL.Strings = (
      'DELETE FROM'
      '    EMPLOYEE'
      'WHERE'
      '        EMP_NO = :OLD_EMP_NO'
      '    ')
    InsertSQL.Strings = (
      'INSERT INTO EMPLOYEE('
      '    EMP_NO,'
      '    FIRST_NAME,'
      '    LAST_NAME,'
      '    PHONE_EXT,'
      '    HIRE_DATE,'
      '    DEPT_NO,'
      '    JOB_CODE,'
      '    JOB_GRADE,'
      '    JOB_COUNTRY,'
      '    SALARY'
      ')'
      'VALUES('
      '    :EMP_NO,'
      '    :FIRST_NAME,'
      '    :LAST_NAME,'
      '    :PHONE_EXT,'
      '    :HIRE_DATE,'
      '    :DEPT_NO,'
      '    :JOB_CODE,'
      '    :JOB_GRADE,'
      '    :JOB_COUNTRY,'
      '    :SALARY'
      ')')
    RefreshSQL.Strings = (
      'SELECT'
      '    EMP_NO,'
      '    FIRST_NAME,'
      '    LAST_NAME,'
      '    PHONE_EXT,'
      '    HIRE_DATE,'
      '    DEPT_NO,'
      '    JOB_CODE,'
      '    JOB_GRADE,'
      '    JOB_COUNTRY,'
      '    SALARY,'
      '    FULL_NAME'
      'FROM'
      '    EMPLOYEE '
      ''
      ' WHERE '
      '        EMPLOYEE.EMP_NO = :OLD_EMP_NO'
      '    ')
    SelectSQL.Strings = (
      'SELECT'
      '    FIB.ID,'
      '    FIB.APP_ID,'
      '    FIB.SQL_TEXT,'
      '    FIB.EXECUTECOUNT,'
      '    FIB.PREPARECOUNT,'
      '    FIB.SUMTIMEEXECUTE,'
      '    FIB.AVGTIMEEXECUTE,'
      '    FIB.MAXTIMEEXECUTE,'
      '    FIB.MAXTIME_PARAMS,'
      '    FIB.LASTTIMEEXECUTE,'
      '    FIB.LOG_DATE,'
      '    FIB.CMP_NAME,'
      '    FIB.ATTACHMENT_ID'
      'FROM'
      '    FIB$APP_STATISTICS FIB')
    AutoUpdateOptions.UpdateTableName = 'EMPLOYEE'
    AutoUpdateOptions.KeyFields = 'EMP_NO'
    AutoUpdateOptions.GeneratorName = 'EMP_NO_GEN'
    AutoUpdateOptions.WhenGetGenID = wgBeforePost
    Transaction = tr
    Database = db
    AutoCommit = True
    Left = 584
    Top = 40
    object dtID: TFIBIntegerField
      FieldName = 'ID'
    end
    object dtAPP_ID: TFIBStringField
      DisplayLabel = 'Application'
      FieldName = 'APP_ID'
      Size = 12
      EmptyStrToNull = True
    end
    object dtSQL_TEXT: TFIBBlobField
      FieldName = 'SQL_TEXT'
      Size = 8
    end
    object dtEXECUTECOUNT: TFIBIntegerField
      FieldName = 'EXECUTECOUNT'
    end
    object dtPREPARECOUNT: TFIBIntegerField
      FieldName = 'PREPARECOUNT'
    end
    object dtSUMTIMEEXECUTE: TFIBIntegerField
      FieldName = 'SUMTIMEEXECUTE'
    end
    object dtAVGTIMEEXECUTE: TFIBIntegerField
      FieldName = 'AVGTIMEEXECUTE'
    end
    object dtMAXTIMEEXECUTE: TFIBIntegerField
      FieldName = 'MAXTIMEEXECUTE'
    end
    object dtMAXTIME_PARAMS: TFIBBlobField
      FieldName = 'MAXTIME_PARAMS'
      Size = 8
    end
    object dtLASTTIMEEXECUTE: TFIBIntegerField
      FieldName = 'LASTTIMEEXECUTE'
    end
    object dtLOG_DATE: TFIBDateTimeField
      FieldName = 'LOG_DATE'
    end
    object dtCMP_NAME: TFIBStringField
      FieldName = 'CMP_NAME'
      Size = 256
      EmptyStrToNull = True
    end
    object dtATTACHMENT_ID: TFIBIntegerField
      FieldName = 'ATTACHMENT_ID'
    end
  end
  object ds: TDataSource
    DataSet = dt
    Left = 616
    Top = 40
  end
  object pFIBQuery1: TpFIBQuery
    Transaction = tr
    Database = db
    Left = 648
    Top = 8
    qoAutoCommit = True
    qoStartTransaction = True
  end
  object pFIBDataSet1: TpFIBDataSet
    Transaction = tr
    Database = db
    Left = 680
    Top = 8
  end
  object FIBSQLLogger1: TFIBSQLLogger
    LogFileName = 'test.log'
    ApplicationID = 'testapp'
    LogFlags = [lfQPrepare, lfQExecute, lfConnect, lfTransact, lfService, lfMisc]
    ForceSaveLog = False
    Left = 648
    Top = 40
  end
end
