object Form1: TForm1
  Left = 27
  Top = 181
  Width = 765
  Height = 485
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
    Width = 757
    Height = 23
    Align = alTop
    AutoSize = False
    Caption = '  Employee Data'
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
    Top = 432
    Width = 757
    Height = 19
    Panels = <>
    SimplePanel = True
    SimpleText = ' Copyrigth (C) Devrace 2000-2009'
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 757
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
        'This Example demonstrate using LostConnection handing. Start edi' +
        'ting in a grid and shutdown Interbase. Do attempt apply updates.' +
        '  Application will handle a connection losing and close TpFIBDat' +
        'abase. '
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
    Top = 109
    Width = 757
    Height = 323
    Align = alClient
    Ctl3D = True
    DataSource = ds
    ParentCtl3D = False
    TabOrder = 2
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
  end
  object Panel2: TPanel
    Left = 0
    Top = 80
    Width = 757
    Height = 29
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 3
    object Label5: TLabel
      Left = 6
      Top = 7
      Width = 119
      Height = 13
      Caption = 'Reaction for lost connect'
      Color = clBtnFace
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentColor = False
      ParentFont = False
    end
    object Label3: TLabel
      Left = 264
      Top = 8
      Width = 119
      Height = 13
      Caption = 'Attempt restore connect  '
      Color = clBtnFace
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Visible = False
    end
    object Label4: TLabel
      Left = 381
      Top = 9
      Width = 8
      Height = 13
      Caption = '0'
      Color = clBtnFace
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
      Visible = False
    end
    object cmbKindOnLost: TComboBox
      Left = 130
      Top = 3
      Width = 127
      Height = 21
      Style = csDropDownList
      ItemHeight = 13
      TabOrder = 0
      Items.Strings = (
        'Close pFIBDataBase '
        'Terminate application'
        'Restore connect')
    end
    object Button1: TButton
      Left = 556
      Top = 2
      Width = 120
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Apply Updates'
      TabOrder = 1
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 683
      Top = 2
      Width = 74
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Close'
      TabOrder = 2
      OnClick = Button2Click
    end
  end
  object db: TpFIBDatabase
    DBName = 
      'localhost:D:\serge\Plus_demos\Voinov\FIBPlusExamples\db\EMPLOYEE' +
      '21.FDB'
    DBParams.Strings = (
      'lc_ctype=UTF8'
      'user_name=SYSDBA'
      'password=masterkey')
    DefaultTransaction = tr
    DefaultUpdateTransaction = tr
    SQLDialect = 3
    Timeout = 0
    UpperOldNames = True
    DesignDBOptions = []
    LibraryName = 'fbclient.dll'
    WaitForRestoreConnect = 10
    OnLostConnect = dbLostConnect
    OnErrorRestoreConnect = dbErrorRestoreConnect
    AfterRestoreConnect = dbAfterRestoreConnect
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
      '    EMPLOYEE ')
    AutoUpdateOptions.UpdateTableName = 'EMPLOYEE'
    AutoUpdateOptions.KeyFields = 'EMP_NO'
    AutoUpdateOptions.GeneratorName = 'EMP_NO_GEN'
    AutoUpdateOptions.WhenGetGenID = wgBeforePost
    Transaction = tr
    Database = db
    Left = 504
    Top = 40
    object dtEMP_NO: TFIBSmallIntField
      FieldName = 'EMP_NO'
    end
    object dtFIRST_NAME: TFIBStringField
      FieldName = 'FIRST_NAME'
      Size = 15
      EmptyStrToNull = True
    end
    object dtLAST_NAME: TFIBStringField
      FieldName = 'LAST_NAME'
      EmptyStrToNull = True
    end
    object dtPHONE_EXT: TFIBStringField
      FieldName = 'PHONE_EXT'
      Size = 4
      EmptyStrToNull = True
    end
    object dtHIRE_DATE: TFIBDateTimeField
      FieldName = 'HIRE_DATE'
    end
    object dtDEPT_NO: TFIBStringField
      FieldName = 'DEPT_NO'
      Size = 3
      EmptyStrToNull = True
    end
    object dtJOB_CODE: TFIBStringField
      FieldName = 'JOB_CODE'
      Size = 5
      EmptyStrToNull = True
    end
    object dtJOB_GRADE: TFIBSmallIntField
      FieldName = 'JOB_GRADE'
    end
    object dtJOB_COUNTRY: TFIBStringField
      FieldName = 'JOB_COUNTRY'
      Size = 15
      EmptyStrToNull = True
    end
    object dtSALARY: TFIBBCDField
      FieldName = 'SALARY'
      Size = 2
      RoundByScale = True
    end
    object dtFULL_NAME: TFIBStringField
      FieldName = 'FULL_NAME'
      Size = 37
      EmptyStrToNull = True
    end
  end
  object ds: TDataSource
    DataSet = dt
    Left = 536
    Top = 40
  end
  object pFibErrorHandler1: TpFibErrorHandler
    OnFIBErrorEvent = pFibErrorHandler1FIBErrorEvent
    Left = 568
    Top = 40
  end
end
