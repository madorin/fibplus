object Form1: TForm1
  Left = 179
  Top = 151
  Width = 639
  Height = 505
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
  object StatusBar1: TStatusBar
    Left = 0
    Top = 452
    Width = 631
    Height = 19
    Panels = <>
    SimplePanel = True
    SimpleText = ' Copyrigth (C) Devrace 2000-2005'
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 631
    Height = 49
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
        'This Example demonstrate using TpFIBPlusDataSet.Options and TpFI' +
        'BDataSet.PrepareOptions  for tuning work of pFIBDataSet. '
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      WordWrap = True
    end
  end
  object Panel3: TPanel
    Left = 0
    Top = 49
    Width = 631
    Height = 403
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object Label2: TLabel
      Left = 0
      Top = 0
      Width = 631
      Height = 19
      Align = alTop
      AutoSize = False
      Caption = '  Employee Dataset'
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
    object DBGrid1: TDBGrid
      Left = 0
      Top = 19
      Width = 631
      Height = 384
      Align = alClient
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
    object Button1: TButton
      Left = 448
      Top = 0
      Width = 183
      Height = 21
      Caption = 'Set Options and Reopen DataSet'
      TabOrder = 1
      OnClick = Button1Click
    end
  end
  object db: TpFIBDatabase
    DBName = 'localhost:D:\home\devrace\FIBPlusExamples\db\EMPLOYEE.FDB'
    DBParams.Strings = (
      'lc_ctype=NONE'
      'user_name=SYSDBA'
      'password=masterkey'
      'sql_role_name=')
    DefaultTransaction = tr
    DefaultUpdateTransaction = tr
    SQLDialect = 3
    Timeout = 0
    UpperOldNames = True
    DesignDBOptions = []
    WaitForRestoreConnect = 0
    Left = 336
    Top = 16
  end
  object tr: TpFIBTransaction
    DefaultDatabase = db
    TimeoutAction = TARollback
    Left = 368
    Top = 16
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
    AutoCommit = True
    Left = 336
    Top = 48
  end
  object ds: TDataSource
    DataSet = dt
    Left = 368
    Top = 48
  end
end
