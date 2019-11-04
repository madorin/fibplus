object Form2: TForm2
  Left = 240
  Top = 202
  Width = 633
  Height = 457
  Caption = 'FIBPlusExample - SQL Monitor'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object StatusBar1: TStatusBar
    Left = 0
    Top = 404
    Width = 625
    Height = 19
    Panels = <>
    SimplePanel = False
  end
  object Panel1: TPanel
    Left = 0
    Top = 57
    Width = 105
    Height = 347
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 1
    object Label2: TLabel
      Left = 0
      Top = 0
      Width = 105
      Height = 19
      Align = alTop
      AutoSize = False
      Caption = ' Trace Flags'
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
    object Label4: TLabel
      Left = 8
      Top = 264
      Width = 78
      Height = 13
      Caption = 'Events Quantity:'
    end
    object lblQty: TLabel
      Left = 8
      Top = 280
      Width = 33
      Height = 13
      Caption = 'lblQty'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object chkPrepare: TCheckBox
      Left = 8
      Top = 88
      Width = 89
      Height = 17
      Caption = 'Prepare'
      TabOrder = 0
      OnClick = chkPrepareClick
    end
    object chkExecute: TCheckBox
      Left = 8
      Top = 110
      Width = 89
      Height = 17
      Caption = 'Execute'
      TabOrder = 1
      OnClick = chkExecuteClick
    end
    object chkFetch: TCheckBox
      Left = 8
      Top = 133
      Width = 89
      Height = 17
      Caption = 'Fetch'
      TabOrder = 2
      OnClick = chkFetchClick
    end
    object chkConnect: TCheckBox
      Left = 8
      Top = 156
      Width = 89
      Height = 17
      Caption = 'Connect'
      TabOrder = 3
      OnClick = chkConnectClick
    end
    object chkTransact: TCheckBox
      Left = 8
      Top = 178
      Width = 89
      Height = 17
      Caption = 'Transact'
      TabOrder = 4
      OnClick = chkTransactClick
    end
    object chkService: TCheckBox
      Left = 8
      Top = 201
      Width = 89
      Height = 17
      Caption = 'Service'
      TabOrder = 5
      OnClick = chkServiceClick
    end
    object chkMisc: TCheckBox
      Left = 8
      Top = 224
      Width = 89
      Height = 17
      Caption = 'Misc'
      TabOrder = 6
      OnClick = chkMiscClick
    end
    object Button1: TButton
      Left = 5
      Top = 24
      Width = 92
      Height = 25
      Caption = 'Start'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 7
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 5
      Top = 52
      Width = 92
      Height = 25
      Caption = 'Clear Log'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 8
      OnClick = Button2Click
    end
  end
  object Panel2: TPanel
    Left = 105
    Top = 57
    Width = 520
    Height = 347
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object Label1: TLabel
      Left = 0
      Top = 0
      Width = 520
      Height = 19
      Align = alTop
      AutoSize = False
      Caption = ' Monitor Log'
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
    object Memo1: TMemo
      Left = 0
      Top = 19
      Width = 520
      Height = 328
      Align = alClient
      Lines.Strings = (
        'Memo1')
      ScrollBars = ssBoth
      TabOrder = 0
    end
  end
  object Panel3: TPanel
    Left = 0
    Top = 0
    Width = 625
    Height = 57
    Align = alTop
    BevelOuter = bvNone
    Color = clTeal
    TabOrder = 3
    object Label3: TLabel
      Left = 8
      Top = 8
      Width = 609
      Height = 41
      AutoSize = False
      Caption = 'This Example demonstrate simple using TpFIBSQLMonitor. '
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      WordWrap = True
    end
  end
  object FIBSQLMonitor1: TFIBSQLMonitor
    OnSQL = FIBSQLMonitor1SQL
    TraceFlags = []
    Left = 576
    Top = 40
  end
end
