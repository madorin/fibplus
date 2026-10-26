object Form1: TForm1
  Left = 158
  Top = 155
  Width = 580
  Height = 434
  Caption = 'Local sorting example'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = True
  Position = poDesktopCenter
  OnClose = FormClose
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 15
  object Label3: TLabel
    Left = 0
    Top = 65
    Width = 572
    Height = 19
    Align = alTop
    AutoSize = False
    Caption = 
      '  Employee Data - Click on title of a column to add it in order ' +
      'queue or to change order of sorting'
    Color = clBtnShadow
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentColor = False
    ParentFont = False
    Layout = tlCenter
  end
  object Button1: TButton
    Left = 320
    Top = 104
    Width = 177
    Height = 25
    Caption = 'Delete column from Sorting'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 572
    Height = 65
    Align = alTop
    BevelOuter = bvNone
    Color = clTeal
    TabOrder = 1
    object Label1: TLabel
      Left = 8
      Top = 8
      Width = 513
      Height = 49
      AutoSize = False
      Caption = 
        'This Example demonstrate using TFIBDataSet DoSortEx methods' +
        ' for local sorting'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      WordWrap = True
    end
    object RadioButton1: TRadioButton
      Left = 231
      Top = 36
      Width = 122
      Height = 17
      Caption = 'Standard Sorting'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
      OnClick = RadioButton1Click
    end
    object RadioButton2: TRadioButton
      Left = 376
      Top = 36
      Width = 97
      Height = 17
      Caption = 'Ansi Sorting'
      Checked = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
      TabStop = True
    end
  end
  object DBGrid1: TDBGrid
    Left = 0
    Top = 84
    Width = 572
    Height = 297
    Align = alClient
    Ctl3D = True
    DataSource = ds
    ParentCtl3D = False
    TabOrder = 2
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -12
    TitleFont.Name = 'Segoe UI'
    TitleFont.Style = []
    OnTitleClick = DBGrid1TitleClick
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 381
    Width = 572
    Height = 19
    Panels = <>
    SimplePanel = True
    SimpleText = ' Copyrigth (C) Devrace 2000-2005'
  end
  object Button2: TButton
    Left = 8
    Top = 32
    Width = 205
    Height = 25
    Caption = 'Clear Sorting for Selected Column'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
    OnClick = Button1Click
  end
  object db: TFIBDatabase
    DBName = 'localhost:fibplus_samples'
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
    Left = 328
    Top = 72
  end
  object tr: TFIBTransaction
    DefaultDatabase = db
    TimeoutAction = TARollback
    Left = 360
    Top = 72
  end
  object ds: TDataSource
    DataSet = dt
    Left = 360
    Top = 104
  end
  object dt: TFIBDataSet
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
    Left = 328
    Top = 104
  end
end
