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
      Caption = 'This Example demonstrate work with refresh dataset'
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
    object Button2: TButton
      Left = 257
      Top = 2
      Width = 120
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Refresh'
      TabOrder = 0
      OnClick = Button2Click
    end
    object cmbKindRefresh: TComboBox
      Left = 2
      Top = 3
      Width = 215
      Height = 21
      Style = csDropDownList
      ItemHeight = 13
      TabOrder = 1
      Items.Strings = (
        'Refresh 1 record'
        'FullRefresh'
        'Refresh only changed records')
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
    WaitForRestoreConnect = 10
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
      '*'
      'FROM'
      '    BIGTABLE'
      'WHERE ID=:OLD_ID')
    SelectSQL.Strings = (
      'SELECT'
      '*'
      'FROM'
      '    BIGTABLE')
    AutoUpdateOptions.UpdateTableName = 'BIGTABLE'
    AutoUpdateOptions.KeyFields = 'ID'
    AutoUpdateOptions.GeneratorName = 'GEN_BIGTABLE_ID'
    AutoUpdateOptions.WhenGetGenID = wgBeforePost
    BeforeOpen = dtBeforeOpen
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
  object qryExactRefresh: TpFIBQuery
    Transaction = tr
    Database = db
    SQL.Strings = (
      'Select * from BIGTABLE'
      'Where LAST_UPDATE>:FETCHED'
      'ORDER BY LAST_UPDATE')
    Left = 608
    Top = 40
  end
end
