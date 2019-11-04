object Form1: TForm1
  Left = 210
  Top = 170
  Width = 624
  Height = 479
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
    Width = 616
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
    Top = 426
    Width = 616
    Height = 19
    Panels = <>
    SimplePanel = True
    SimpleText = ' Copyrigth (C) Devrace 2000-2005'
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 616
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
        'This Example demonstrate using TpFIBDataSet LocalFiltering using' +
        ' Property '#39'Filter'#39' and Event '#39'OnFilterRecord'#39
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
    Top = 76
    Width = 431
    Height = 350
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
    Left = 431
    Top = 76
    Width = 185
    Height = 350
    Align = alRight
    BevelOuter = bvNone
    TabOrder = 3
    object Label3: TLabel
      Left = 12
      Top = 40
      Width = 76
      Height = 13
      Caption = 'Field for Filtering'
    end
    object Label4: TLabel
      Left = 12
      Top = 96
      Width = 52
      Height = 13
      Caption = 'Field Value'
    end
    object RadioButton1: TRadioButton
      Left = 8
      Top = 11
      Width = 73
      Height = 17
      Caption = 'FilterText'
      Checked = True
      Color = clBtnFace
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      TabOrder = 0
      TabStop = True
    end
    object RadioButton2: TRadioButton
      Left = 88
      Top = 11
      Width = 113
      Height = 17
      Caption = 'OnFilterRecord'
      Color = clBtnFace
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      TabOrder = 1
    end
    object ComboBox1: TComboBox
      Left = 12
      Top = 56
      Width = 162
      Height = 21
      Style = csDropDownList
      ItemHeight = 13
      TabOrder = 2
    end
    object Edit1: TEdit
      Left = 12
      Top = 112
      Width = 161
      Height = 21
      TabOrder = 3
      Text = 'Edit1'
    end
    object chkIgnoreCase: TCheckBox
      Left = 11
      Top = 137
      Width = 97
      Height = 17
      Caption = 'Ignore Case'
      TabOrder = 4
    end
    object Button1: TButton
      Left = 12
      Top = 160
      Width = 161
      Height = 25
      Caption = 'Apply Filter'
      TabOrder = 5
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 12
      Top = 192
      Width = 161
      Height = 25
      Caption = 'Cancel Filter'
      TabOrder = 6
      OnClick = Button2Click
    end
  end
  object db: TpFIBDatabase
    DBName = 'localhost:D:\home\devrace\FIBPlusExamples\db\EMPLOYEE.FDB'
    DBParams.Strings = (
      'lc_ctype=NONE'
      'user_name=SYSDBA'
      'password=masterkey')
    DefaultTransaction = tr
    DefaultUpdateTransaction = trwrite
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
      'UPDATE CUSTOMER'
      'SET '
      '    CUSTOMER = :CUSTOMER,'
      '    CONTACT_FIRST = :CONTACT_FIRST,'
      '    CONTACT_LAST = :CONTACT_LAST,'
      '    PHONE_NO = :PHONE_NO,'
      '    ADDRESS_LINE1 = :ADDRESS_LINE1,'
      '    ADDRESS_LINE2 = :ADDRESS_LINE2,'
      '    CITY = :CITY,'
      '    STATE_PROVINCE = :STATE_PROVINCE,'
      '    COUNTRY = :COUNTRY,'
      '    POSTAL_CODE = :POSTAL_CODE,'
      '    ON_HOLD = :ON_HOLD'
      'WHERE'
      '    CUST_NO = :OLD_CUST_NO'
      '    ')
    DeleteSQL.Strings = (
      'DELETE FROM'
      '    CUSTOMER'
      'WHERE'
      '        CUST_NO = :OLD_CUST_NO'
      '    ')
    InsertSQL.Strings = (
      'INSERT INTO CUSTOMER('
      '    CUST_NO,'
      '    CUSTOMER,'
      '    CONTACT_FIRST,'
      '    CONTACT_LAST,'
      '    PHONE_NO,'
      '    ADDRESS_LINE1,'
      '    ADDRESS_LINE2,'
      '    CITY,'
      '    STATE_PROVINCE,'
      '    COUNTRY,'
      '    POSTAL_CODE,'
      '    ON_HOLD'
      ')'
      'VALUES('
      '    :CUST_NO,'
      '    :CUSTOMER,'
      '    :CONTACT_FIRST,'
      '    :CONTACT_LAST,'
      '    :PHONE_NO,'
      '    :ADDRESS_LINE1,'
      '    :ADDRESS_LINE2,'
      '    :CITY,'
      '    :STATE_PROVINCE,'
      '    :COUNTRY,'
      '    :POSTAL_CODE,'
      '    :ON_HOLD'
      ')')
    RefreshSQL.Strings = (
      'SELECT'
      '    C.CUST_NO,'
      '    C.CUSTOMER,'
      '    C.CONTACT_FIRST,'
      '    C.CONTACT_LAST,'
      '    C.PHONE_NO,'
      '    C.ADDRESS_LINE1,'
      '    C.ADDRESS_LINE2,'
      '    C.CITY,'
      '    C.STATE_PROVINCE,'
      '    C.COUNTRY,'
      '    C.POSTAL_CODE,'
      '    C.ON_HOLD,'
      
        '    (SELECT COUNT(*) FROM SALES WHERE CUST_NO = C.CUST_NO) QUANT' +
        'ITY_ORDERS'
      'FROM'
      '    CUSTOMER C'
      ''
      ' WHERE '
      '        C.CUST_NO = :OLD_CUST_NO'
      '    '
      'ORDER BY'
      '    CUSTOMER')
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
    UpdateTransaction = trwrite
    AutoCommit = True
    OnFilterRecord = dtFilterRecord
    Left = 504
    Top = 40
  end
  object ds: TDataSource
    DataSet = dt
    Left = 536
    Top = 40
  end
  object trwrite: TpFIBTransaction
    DefaultDatabase = db
    TimeoutAction = TARollback
    Left = 568
    Top = 8
  end
end
