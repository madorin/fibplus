object Form1: TForm1
  Left = 105
  Top = 123
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
    Top = 57
    Width = 626
    Height = 23
    Align = alTop
    AutoSize = False
    Caption = '  Sales Data'
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
    SimpleText = ' Copyrigth (C) Devrace 2000-2009'
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
      Caption = 'This Example demonstrate using EventAlerter'
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
    Width = 626
    Height = 328
    Align = alClient
    Ctl3D = True
    DataSource = ds
    Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection, dgConfirmDelete, dgCancelOnExit]
    ParentCtl3D = False
    TabOrder = 2
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
  end
  object Button1: TButton
    Left = 350
    Top = 56
    Width = 275
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Insert Sale with pFIBQuery'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 3
    OnClick = Button1Click
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
    SaveAliasParamsAfterConnect = False
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
      ' Update  SALES Set '
      '   PO_NUMBER=:PO_NUMBER,'
      '   CUST_NO=:CUST_NO,'
      '   SALES_REP=:SALES_REP,'
      '   ORDER_STATUS=:ORDER_STATUS,'
      '   ORDER_DATE=:ORDER_DATE,'
      '   SHIP_DATE=:SHIP_DATE,'
      '   DATE_NEEDED=:DATE_NEEDED,'
      '   PAID=:PAID,'
      '   QTY_ORDERED=:QTY_ORDERED,'
      '   TOTAL_VALUE=:TOTAL_VALUE,'
      '   DISCOUNT=:DISCOUNT,'
      '   ITEM_TYPE=:ITEM_TYPE,'
      '   AGED=:AGED'
      ' where '
      '   PO_NUMBER=:OLD_PO_NUMBER')
    DeleteSQL.Strings = (
      'DELETE FROM'
      '    SALES'
      'WHERE'
      '     PO_NUMBER =:OLD_PO_NUMBER'
      '    ')
    InsertSQL.Strings = (
      
        ' Insert into SALES(PO_NUMBER,CUST_NO,SALES_REP,ORDER_STATUS,ORDE' +
        'R_DATE,SHIP_DATE,DATE_NEEDED,PAID,QTY_ORDERED,TOTAL_VALUE,DISCOU' +
        'NT,ITEM_TYPE,AGED)'
      
        ' values (:PO_NUMBER,:CUST_NO,:SALES_REP,:ORDER_STATUS,:ORDER_DAT' +
        'E,:SHIP_DATE,:DATE_NEEDED,:PAID,:QTY_ORDERED,:TOTAL_VALUE,:DISCO' +
        'UNT,:ITEM_TYPE,:AGED)'
      ' ')
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
      ' where '
      '   PO_NUMBER=:OLD_PO_NUMBER')
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
      'ORDER BY'
      '   ORDER_DATE DESC')
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
  object qryInsertSale: TpFIBQuery
    Transaction = trInsertSale
    Database = db
    SQL.Strings = (
      'INSERT INTO SALES ('
      '    PO_NUMBER,'
      '    CUST_NO,'
      '    SALES_REP,'
      '    QTY_ORDERED,'
      '    TOTAL_VALUE'
      ') VALUES ('
      '    :PO_NUMBER,'
      '    :CUST_NO,'
      '    :SALES_REP,'
      '    :QTY_ORDERED,'
      '    :TOTAL_VALUE'
      ')')
    Left = 504
    Top = 72
    qoAutoCommit = True
    qoStartTransaction = True
  end
  object trInsertSale: TpFIBTransaction
    DefaultDatabase = db
    TimeoutAction = TARollback
    Left = 536
    Top = 72
  end
  object SIBfibEventAlerter1: TSIBfibEventAlerter
    Events.Strings = (
      'new_order')
    OnEventAlert = SIBfibEventAlerter1EventAlert
    Database = db
    AutoRegister = True
    Left = 568
    Top = 40
  end
end
