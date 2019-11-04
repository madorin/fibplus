object Form1: TForm1
  Left = 218
  Top = 170
  Width = 616
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
    Width = 608
    Height = 19
    Align = alTop
    AutoSize = False
    Caption = 
      '  Customer:                                                     ' +
      '             Quantity orders: '
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
    Left = 0
    Top = 240
    Width = 608
    Height = 19
    Align = alBottom
    AutoSize = False
    Caption = '  Orders Data'
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
  object DBText1: TDBText
    Left = 69
    Top = 60
    Width = 252
    Height = 13
    Color = clGray
    DataField = 'CUSTOMER'
    DataSource = ds
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clAqua
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentColor = False
    ParentFont = False
  end
  object DBText2: TDBText
    Left = 421
    Top = 61
    Width = 140
    Height = 13
    Color = clGray
    DataField = 'QUANTITY_ORDERS'
    DataSource = ds
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clAqua
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentColor = False
    ParentFont = False
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 426
    Width = 608
    Height = 19
    Panels = <>
    SimplePanel = True
    SimpleText = ' Copyrigth (C) Devrace 2000-2009'
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 608
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
        'This Example demonstrate using TpFIBDataSet Master-Detail. See D' +
        'etailConditions Properties for details'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      WordWrap = True
    end
    object DBNavigator1: TDBNavigator
      Left = 8
      Top = 32
      Width = 240
      Height = 25
      DataSource = ds
      TabOrder = 0
    end
  end
  object DBGrid1: TDBGrid
    Left = 0
    Top = 76
    Width = 608
    Height = 164
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
  object DBGrid2: TDBGrid
    Left = 0
    Top = 259
    Width = 608
    Height = 167
    Align = alBottom
    Ctl3D = True
    DataSource = dsDetail
    Options = [dgEditing, dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit, dgMultiSelect]
    ParentCtl3D = False
    TabOrder = 3
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
  end
  object db: TpFIBDatabase
    DBName = 'localhost:D:\home\devrace\FIBPlusExamples\db\EMPLOYEE.FDB'
    DBParams.Strings = (
      'lc_ctype=WIN1251'
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
      'ORDER BY'
      '    CUSTOMER')
    OnUpdateError = dtUpdateError
    AutoUpdateOptions.UpdateTableName = 'EMPLOYEE'
    AutoUpdateOptions.KeyFields = 'EMP_NO'
    AutoUpdateOptions.GeneratorName = 'EMP_NO_GEN'
    AutoUpdateOptions.WhenGetGenID = wgBeforePost
    BeforePost = dtBeforePost
    Transaction = tr
    Database = db
    AutoCommit = True
    Left = 440
    Top = 40
  end
  object ds: TDataSource
    DataSet = dt
    Left = 472
    Top = 40
  end
  object dtDetail: TpFIBDataSet
    UpdateSQL.Strings = (
      'UPDATE SALES'
      'SET '
      '    CUST_NO = :CUST_NO,'
      '    SALES_REP = :SALES_REP,'
      '    ORDER_STATUS = :ORDER_STATUS,'
      '    ORDER_DATE = :ORDER_DATE,'
      '    SHIP_DATE = :SHIP_DATE,'
      '    DATE_NEEDED = :DATE_NEEDED,'
      '    PAID = :PAID,'
      '    QTY_ORDERED = :QTY_ORDERED,'
      '    TOTAL_VALUE = :TOTAL_VALUE,'
      '    DISCOUNT = :DISCOUNT,'
      '    ITEM_TYPE = :ITEM_TYPE'
      'WHERE'
      '    PO_NUMBER = :OLD_PO_NUMBER'
      '    ')
    DeleteSQL.Strings = (
      'DELETE FROM'
      '    SALES'
      'WHERE'
      '        PO_NUMBER = :OLD_PO_NUMBER'
      '    ')
    InsertSQL.Strings = (
      'INSERT INTO SALES('
      '    PO_NUMBER,'
      '    CUST_NO,'
      '    SALES_REP,'
      '    ORDER_STATUS,'
      '    ORDER_DATE,'
      '    SHIP_DATE,'
      '    DATE_NEEDED,'
      '    PAID,'
      '    QTY_ORDERED,'
      '    TOTAL_VALUE,'
      '    DISCOUNT,'
      '    ITEM_TYPE'
      ')'
      'VALUES('
      '    :PO_NUMBER,'
      '    :CUST_NO,'
      '    :SALES_REP,'
      '    :ORDER_STATUS,'
      '    :ORDER_DATE,'
      '    :SHIP_DATE,'
      '    :DATE_NEEDED,'
      '    :PAID,'
      '    :QTY_ORDERED,'
      '    :TOTAL_VALUE,'
      '    :DISCOUNT,'
      '    :ITEM_TYPE'
      ')')
    RefreshSQL.Strings = (
      'SELECT'
      '    PO_NUMBER,'
      '    CUST_NO,'
      '    SALES_REP,'
      '    ORDER_STATUS,'
      '    ORDER_DATE,'
      '    SHIP_DATE,'
      '    DATE_NEEDED,'
      '    PAID,'
      '    QTY_ORDERED,'
      '    TOTAL_VALUE,'
      '    DISCOUNT,'
      '    ITEM_TYPE,'
      '    AGED'
      'FROM'
      '    SALES '
      'WHERE( '
      '    CUST_NO = ?MAS_CUST_NO'
      '     ) and (     SALES.PO_NUMBER = :OLD_PO_NUMBER'
      '     )'
      '    '
      'ORDER BY'
      '    ORDER_DATE DESC')
    SelectSQL.Strings = (
      'SELECT'
      '    PO_NUMBER,'
      '    CUST_NO,'
      '    SALES_REP,'
      '    ORDER_STATUS,'
      '    ORDER_DATE,'
      '    SHIP_DATE,'
      '    DATE_NEEDED,'
      '    PAID,'
      '    QTY_ORDERED,'
      '    TOTAL_VALUE,'
      '    DISCOUNT,'
      '    ITEM_TYPE,'
      '    AGED'
      'FROM'
      '    SALES '
      'WHERE'
      '    CUST_NO = ?CUST_NO'
      'ORDER BY'
      '    ORDER_DATE DESC')
    OnUpdateError = dtDetailUpdateError
    AutoUpdateOptions.AutoParamsToFields = True
    Transaction = tr
    Database = db
    AutoCommit = True
    DataSource = ds
    Left = 440
    Top = 104
  end
  object dsDetail: TDataSource
    DataSet = dtDetail
    Left = 480
    Top = 104
  end
end
