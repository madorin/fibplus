object Form1: TForm1
  Left = 158
  Top = 147
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
  OnClose = FormClose
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label2: TLabel
    Left = 0
    Top = 57
    Width = 626
    Height = 19
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
    Top = 408
    Width = 626
    Height = 19
    Panels = <>
    SimplePanel = True
    SimpleText = ' Copyrigth (C) Devrace 2000-2005'
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 626
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
      Caption = 'This Example demonstrate using FIBPlus connection from DLL'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      WordWrap = True
    end
    object Button1: TButton
      Left = 8
      Top = 24
      Width = 161
      Height = 25
      Caption = 'Show DDL Form'
      TabOrder = 0
      OnClick = Button1Click
    end
  end
  object DBGrid1: TDBGrid
    Left = 0
    Top = 76
    Width = 626
    Height = 332
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
  object db: TpFIBDatabase
    DBName = 
      'localhost:G:\Program Files\Firebird\examples\empbuild\EMPLOYEE.F' +
      'DB'
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
    Left = 504
    Top = 40
  end
  object ds: TDataSource
    DataSet = dt
    Left = 536
    Top = 40
  end
end
