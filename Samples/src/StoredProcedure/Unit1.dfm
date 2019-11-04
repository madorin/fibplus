object Form1: TForm1
  Left = 245
  Top = 155
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
      Caption = 'This Example demonstrate simple using TpFIBStoredProcedure. '
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      WordWrap = True
    end
  end
  object PageControl1: TPageControl
    Left = 0
    Top = 57
    Width = 626
    Height = 351
    ActivePage = TabSheet1
    Align = alClient
    TabOrder = 2
    object TabSheet1: TTabSheet
      Caption = 'Org Chart'
      object DBGrid1: TDBGrid
        Left = 0
        Top = 0
        Width = 618
        Height = 323
        Align = alClient
        Ctl3D = True
        DataSource = dsOrgChart
        Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection, dgConfirmDelete, dgCancelOnExit]
        ParentCtl3D = False
        ReadOnly = True
        TabOrder = 0
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'MS Sans Serif'
        TitleFont.Style = []
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'Department'
      ImageIndex = 1
      object DBGrid2: TDBGrid
        Left = 0
        Top = 0
        Width = 618
        Height = 323
        Align = alClient
        DataSource = dsDept
        Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection, dgConfirmDelete, dgCancelOnExit]
        ReadOnly = True
        TabOrder = 0
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'MS Sans Serif'
        TitleFont.Style = []
      end
      object Button1: TButton
        Left = 422
        Top = 286
        Width = 179
        Height = 25
        Anchors = [akRight, akBottom]
        Caption = 'Show Department Budget'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clNavy
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 1
        OnClick = Button1Click
      end
    end
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
  object dtOrgChart: TpFIBDataSet
    SelectSQL.Strings = (
      'SELECT'
      '    HEAD_DEPT,'
      '    DEPARTMENT,'
      '    MNGR_NAME,'
      '    TITLE,'
      '    EMP_CNT'
      'FROM'
      '    ORG_CHART ')
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
  object dsOrgChart: TDataSource
    DataSet = dtOrgChart
    Left = 536
    Top = 40
  end
  object dtDept: TpFIBDataSet
    SelectSQL.Strings = (
      'SELECT'
      '    DEPT_NO,'
      '    DEPARTMENT,'
      '    HEAD_DEPT,'
      '    MNGR_NO,'
      '    BUDGET,'
      '    LOCATION,'
      '    PHONE_NO'
      'FROM'
      '    DEPARTMENT ')
    Transaction = tr
    Database = db
    Left = 504
    Top = 72
  end
  object spSubTotalBudget: TpFIBStoredProc
    Transaction = pFIBTransaction1
    Database = db
    SQL.Strings = (
      'EXECUTE PROCEDURE SUB_TOT_BUDGET (?HEAD_DEPT)')
    StoredProcName = 'SUB_TOT_BUDGET'
    Left = 505
    Top = 105
    qoAutoCommit = True
    qoStartTransaction = True
  end
  object dsDept: TDataSource
    DataSet = dtDept
    Left = 536
    Top = 72
  end
  object pFIBTransaction1: TpFIBTransaction
    DefaultDatabase = db
    TimeoutAction = TARollback
    Left = 536
    Top = 105
  end
end
