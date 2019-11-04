object Form1: TForm1
  Left = 245
  Top = 155
  Width = 607
  Height = 404
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
    Width = 599
    Height = 19
    Align = alTop
    AutoSize = False
    Caption = '  BlobFlt Data'
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
    Top = 351
    Width = 599
    Height = 19
    Panels = <>
    SimplePanel = True
    SimpleText = ' Copyrigth (C) Devrace 2000-2005'
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 599
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
        'This Example demonstrate using IB/FB BlobFilers. Using DIPUCL li' +
        'brary for compresing data with UCL algoritm from "http://www.yun' +
        'qa.de/delphi/". Also demonstrated using TpFIBGUIDField'
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
    Width = 599
    Height = 124
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
    Columns = <
      item
        Expanded = False
        FieldName = 'GUID'
        Width = 209
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'NAME'
        Width = 350
        Visible = True
      end>
  end
  object Panel2: TPanel
    Left = 0
    Top = 200
    Width = 599
    Height = 151
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    object DBMemo1: TDBMemo
      Left = 0
      Top = 3
      Width = 473
      Height = 147
      Anchors = [akLeft, akTop, akRight, akBottom]
      DataField = 'BLOBDATA'
      DataSource = ds
      TabOrder = 0
    end
    object Button1: TButton
      Left = 480
      Top = 8
      Width = 113
      Height = 25
      Caption = 'Load Text Data'
      TabOrder = 1
      OnClick = Button1Click
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
  object dt: TpFIBDataSet
    UpdateSQL.Strings = (
      'UPDATE BLOBFLT'
      'SET '
      '    NAME = :NAME,'
      '    BLOBDATA = :BLOBDATA'
      'WHERE'
      '    GUID = :OLD_GUID'
      '    ')
    DeleteSQL.Strings = (
      'DELETE FROM'
      '    BLOBFLT'
      'WHERE'
      '        GUID = :OLD_GUID'
      '    ')
    InsertSQL.Strings = (
      'INSERT INTO BLOBFLT('
      '    GUID,'
      '    NAME,'
      '    BLOBDATA'
      ')'
      'VALUES('
      '    :GUID,'
      '    :NAME,'
      '    :BLOBDATA'
      ')')
    RefreshSQL.Strings = (
      'SELECT'
      '    GUID,'
      '    NAME,'
      '    BLOBDATA'
      'FROM'
      '    BLOBFLT '
      ''
      ' WHERE '
      '        BLOBFLT.GUID = :OLD_GUID'
      '    ')
    SelectSQL.Strings = (
      'SELECT'
      '    GUID,'
      '    NAME,'
      '    BLOBDATA'
      'FROM'
      '    BLOBFLT ')
    AutoUpdateOptions.UpdateTableName = 'EMPLOYEE'
    AutoUpdateOptions.KeyFields = 'EMP_NO'
    AutoUpdateOptions.GeneratorName = 'EMP_NO_GEN'
    AutoUpdateOptions.WhenGetGenID = wgBeforePost
    Transaction = tr
    Database = db
    AutoCommit = True
    Left = 504
    Top = 40
    poUseGuidField = True
  end
  object ds: TDataSource
    DataSet = dt
    Left = 536
    Top = 40
  end
  object OpenDialog1: TOpenDialog
    Left = 488
    Top = 192
  end
end
