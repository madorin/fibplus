object Form1: TForm1
  Left = 257
  Top = 169
  Width = 634
  Height = 461
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
    Top = 41
    Width = 626
    Height = 27
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
  object Label3: TLabel
    Left = 172
    Top = 48
    Width = 48
    Height = 13
    Caption = 'Country:'
    Color = clBtnShadow
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentColor = False
    ParentFont = False
  end
  object Label4: TLabel
    Left = 406
    Top = 48
    Width = 70
    Height = 13
    Caption = 'Department:'
    Color = clBtnShadow
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentColor = False
    ParentFont = False
  end
  object Splitter1: TSplitter
    Left = 0
    Top = 313
    Width = 626
    Height = 6
    Cursor = crVSplit
    Align = alBottom
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 408
    Width = 626
    Height = 19
    Panels = <>
    SimplePanel = True
    SimpleText = ' Copyrigth (C) Devrace 2000-2009'
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 626
    Height = 41
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
        'This Example demonstrate simple using TpFIBPlusDataSet Server-si' +
        'de filtering. For this purpose used TpFIBDataSet property '#39'Condi' +
        'tions'#39
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
    Top = 68
    Width = 626
    Height = 245
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
  object DBLookupComboBox1: TDBLookupComboBox
    Left = 224
    Top = 44
    Width = 161
    Height = 21
    DropDownRows = 12
    KeyField = 'F_1'
    ListField = 'F_1'
    ListSource = dsCountry
    TabOrder = 3
    OnCloseUp = DBLookupComboBox1CloseUp
  end
  object DBLookupComboBox2: TDBLookupComboBox
    Left = 480
    Top = 44
    Width = 145
    Height = 21
    DropDownRows = 12
    KeyField = 'F_1'
    ListField = 'F_2'
    ListSource = dsDept
    TabOrder = 4
    OnCloseUp = DBLookupComboBox1CloseUp
  end
  object Memo1: TMemo
    Left = 0
    Top = 319
    Width = 626
    Height = 89
    Align = alBottom
    Lines.Strings = (
      'Memo1')
    ScrollBars = ssBoth
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
      '    EMP.EMP_NO,'
      '    EMP.FIRST_NAME,'
      '    EMP.LAST_NAME,'
      '    EMP.PHONE_EXT,'
      '    EMP.HIRE_DATE,'
      '    EMP.DEPT_NO,'
      '    EMP.JOB_CODE,'
      '    EMP.JOB_GRADE,'
      '    EMP.JOB_COUNTRY,'
      '    EMP.SALARY,'
      '    EMP.FULL_NAME,'
      '    DEP.DEPARTMENT'
      'FROM'
      '    EMPLOYEE EMP'
      '    JOIN DEPARTMENT DEP ON EMP.DEPT_NO = DEP.DEPT_NO'
      ''
      ' WHERE '
      '        EMP.EMP_NO = :OLD_EMP_NO'
      '    ')
    SelectSQL.Strings = (
      'SELECT'
      '    EMP.EMP_NO,'
      '    EMP.FIRST_NAME,'
      '    EMP.LAST_NAME,'
      '    EMP.PHONE_EXT,'
      '    EMP.HIRE_DATE,'
      '    EMP.DEPT_NO,'
      '    EMP.JOB_CODE,'
      '    EMP.JOB_GRADE,'
      '    EMP.JOB_COUNTRY,'
      '    EMP.SALARY,'
      '    EMP.FULL_NAME,'
      '    DEP.DEPARTMENT'
      'FROM'
      '    EMPLOYEE EMP'
      '    JOIN DEPARTMENT DEP ON EMP.DEPT_NO = DEP.DEPT_NO '
      '      @@DEPT% AND DEP.DEPT_NO = :DEPT_NO@'
      'WHERE'
      '    @@COUNTRY% 1 = 1 @')
    AutoUpdateOptions.UpdateTableName = 'EMPLOYEE'
    AutoUpdateOptions.KeyFields = 'EMP_NO'
    AutoUpdateOptions.GeneratorName = 'EMP_NO_GEN'
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
  object dtCountry: TpFIBDataSet
    SelectSQL.Strings = (
      'SELECT CAST('#39' --- ALL ---'#39' AS VARCHAR(15))'
      'FROM RDB$DATABASE'
      ''
      'UNION'
      ''
      'SELECT COUNTRY'
      'FROM COUNTRY '
      ''
      'ORDER BY 1')
    Transaction = tr
    Database = db
    Left = 504
    Top = 88
    oFetchAll = True
  end
  object dtDept: TpFIBDataSet
    SelectSQL.Strings = (
      'SELECT '
      '  CAST('#39'---'#39' AS CHAR(3)), '
      '  CAST('#39' --- ALL ---'#39' AS VARCHAR(25))'
      'FROM RDB$DATABASE'
      ''
      'UNION'
      ''
      'SELECT DEPT_NO, DEPARTMENT'
      'FROM DEPARTMENT '
      ''
      'ORDER BY'
      '  2')
    Transaction = tr
    Database = db
    Left = 504
    Top = 120
    oFetchAll = True
  end
  object dsCountry: TDataSource
    DataSet = dtCountry
    Left = 536
    Top = 88
  end
  object dsDept: TDataSource
    DataSet = dtDept
    Left = 536
    Top = 120
  end
end
