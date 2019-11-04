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
  object StatusBar1: TStatusBar
    Left = 0
    Top = 432
    Width = 757
    Height = 19
    Panels = <
      item
        Width = 50
      end>
    SimplePanel = False
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
        'This Example demonstrate offline work. '#13#10'Start editing in a grid' +
        '. Do attempt apply updates.  '#13#10'Application will restore connect ' +
        'and apply updates to base. '
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
    Top = 86
    Width = 757
    Height = 346
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
    Top = 57
    Width = 757
    Height = 29
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 3
    object Button1: TButton
      Left = 140
      Top = 2
      Width = 120
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Apply Updates'
      TabOrder = 0
      OnClick = Button1Click
    end
    object cmbKindWork: TComboBox
      Left = 2
      Top = 3
      Width = 127
      Height = 21
      Style = csDropDownList
      ItemHeight = 13
      TabOrder = 1
      OnChange = cmbKindWorkChange
      Items.Strings = (
        'Offline work'
        'Online work')
    end
    object Button2: TButton
      Left = 265
      Top = 2
      Width = 120
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Reopen Dataset'
      TabOrder = 2
      OnClick = Button2Click
    end
  end
  object db: TpFIBDatabase
    AutoReconnect = True
    DBName = 
      'localhost:D:\serge\Plus_demos\Voinov\FIBPlusExamples\db\EMPLOYEE' +
      '21.FDB'
    DBParams.Strings = (
      'lc_ctype=UTF8'
      'user_name=SYSDBA'
      'password=masterkey'
      'sql_role_name=')
    DefaultTransaction = tr
    DefaultUpdateTransaction = tr
    SQLDialect = 3
    Timeout = 300
    UpperOldNames = True
    AfterDisconnect = dbAfterDisconnect
    DesignDBOptions = []
    WaitForRestoreConnect = 10
    AfterConnect = dbAfterConnect
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
  end
  object ds: TDataSource
    DataSet = dt
    Left = 536
    Top = 40
  end
end
