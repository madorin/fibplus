object frmFIBPreferences: TfrmFIBPreferences
  Left = 310
  Top = 137
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'FIBPlus Preferences'
  ClientHeight = 424
  ClientWidth = 422
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = True
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object z: TPageControl
    Left = 8
    Top = 8
    Width = 409
    Height = 376
    ActivePage = TabSheet4
    TabOrder = 0
    object TabSheet4: TTabSheet
      Caption = 'TpFIBDataSet'
      object Label4: TLabel
        Left = 8
        Top = 328
        Width = 105
        Height = 13
        Caption = 'Prefix Generator name'
      end
      object Label5: TLabel
        Left = 200
        Top = 328
        Width = 102
        Height = 13
        Caption = 'Sufix Generator name'
      end
      object GroupBox1: TGroupBox
        Left = 197
        Top = 4
        Width = 200
        Height = 202
        Caption = 'PrepareOptions'
        TabOrder = 1
        object chRequiredFields: TCheckBox
          Left = 16
          Top = 15
          Width = 143
          Height = 12
          Caption = 'SetRequiredFields'
          TabOrder = 0
        end
        object chSetReadOnlyFields: TCheckBox
          Left = 16
          Top = 30
          Width = 143
          Height = 12
          Caption = 'SetReadOnlyFields'
          TabOrder = 1
        end
        object chImportDefaultValues: TCheckBox
          Left = 16
          Top = 45
          Width = 143
          Height = 12
          Caption = 'ImportDefaultValues'
          TabOrder = 2
        end
        object chUseBooleanField: TCheckBox
          Left = 16
          Top = 60
          Width = 143
          Height = 12
          Caption = 'UseBooleanField'
          TabOrder = 3
        end
        object chApplyRepositary: TCheckBox
          Left = 16
          Top = 135
          Width = 143
          Height = 12
          Caption = 'ApplyRepositary'
          TabOrder = 8
        end
        object chGetOrderInfo: TCheckBox
          Left = 16
          Top = 120
          Width = 143
          Height = 12
          Caption = 'GetOrderInfo'
          TabOrder = 7
        end
        object chAskRecordCount: TCheckBox
          Left = 16
          Top = 150
          Width = 143
          Height = 12
          Caption = 'AskRecordCount'
          TabOrder = 9
        end
        object chUseSQLINT64ToBCD: TCheckBox
          Left = 16
          Top = 105
          Width = 143
          Height = 12
          Caption = 'SQLINT64 To BCD Field'
          TabOrder = 6
        end
        object chUseGuidField: TCheckBox
          Left = 16
          Top = 75
          Width = 143
          Height = 12
          Caption = 'UseGuidField'
          TabOrder = 4
        end
        object chEmptyStrToNull: TCheckBox
          Left = 16
          Top = 165
          Width = 143
          Height = 12
          Caption = 'SetEmptyStrToNull'
          TabOrder = 10
        end
        object chUseLargeIntField: TCheckBox
          Left = 16
          Top = 90
          Width = 143
          Height = 12
          Caption = 'UseLargeIntField'
          TabOrder = 5
        end
      end
      object GroupBox2: TGroupBox
        Left = 3
        Top = 4
        Width = 190
        Height = 202
        Caption = 'Options'
        TabOrder = 0
        object chTrimCharFields: TCheckBox
          Left = 10
          Top = 12
          Width = 134
          Height = 17
          Caption = 'TrimCharFields'
          TabOrder = 0
        end
        object chRefreshAfterPost: TCheckBox
          Left = 10
          Top = 26
          Width = 134
          Height = 17
          Caption = 'RefreshAfterPost'
          TabOrder = 1
        end
        object chRefreshDeletedRecord: TCheckBox
          Left = 10
          Top = 40
          Width = 134
          Height = 17
          Caption = 'RefreshDeletedRecord'
          TabOrder = 2
        end
        object chStartTransaction: TCheckBox
          Left = 10
          Top = 55
          Width = 134
          Height = 17
          Caption = 'StartTransaction'
          TabOrder = 3
        end
        object chAutoFormatFields: TCheckBox
          Left = 10
          Top = 70
          Width = 134
          Height = 17
          Caption = 'AutoFormatFields'
          TabOrder = 4
        end
        object chProtectedEdit: TCheckBox
          Left = 10
          Top = 85
          Width = 134
          Height = 17
          Caption = 'ProtectedEdit'
          TabOrder = 5
        end
        object chKeepSorting: TCheckBox
          Left = 10
          Top = 100
          Width = 134
          Height = 17
          Caption = 'KeepSorting'
          TabOrder = 6
        end
        object chPersistentSorting: TCheckBox
          Left = 10
          Top = 115
          Width = 134
          Height = 17
          Caption = 'PersistentSorting'
          TabOrder = 7
        end
        object chVisibleRecno: TCheckBox
          Left = 10
          Top = 130
          Width = 134
          Height = 17
          Caption = 'VisibleRecno'
          TabOrder = 8
        end
        object chFetchAll: TCheckBox
          Left = 10
          Top = 145
          Width = 134
          Height = 17
          Caption = 'FetchAll'
          TabOrder = 9
        end
        object chCacheCalcFields: TCheckBox
          Left = 10
          Top = 160
          Width = 134
          Height = 17
          Caption = 'CacheCalcFields'
          TabOrder = 10
        end
        object chUseSelectForLock: TCheckBox
          Left = 10
          Top = 176
          Width = 134
          Height = 17
          Caption = 'UseSelectForLock'
          TabOrder = 11
        end
      end
      object GroupBox3: TGroupBox
        Left = 2
        Top = 206
        Width = 152
        Height = 115
        Caption = 'DetailConditions'
        TabOrder = 2
        object chForceOpen: TCheckBox
          Left = 9
          Top = 14
          Width = 137
          Height = 14
          Caption = 'ForceOpen'
          TabOrder = 0
        end
        object chForceMasterRefresh: TCheckBox
          Left = 9
          Top = 33
          Width = 137
          Height = 17
          Caption = 'ForceMasterRefresh'
          TabOrder = 1
        end
        object chWaitEndMasterScroll: TCheckBox
          Left = 9
          Top = 55
          Width = 137
          Height = 17
          Caption = 'WaitEndMasterScroll'
          TabOrder = 2
        end
        object chIgnoreMasterClose: TCheckBox
          Left = 10
          Top = 76
          Width = 137
          Height = 17
          Caption = 'Ignore MasterClose'
          TabOrder = 3
        end
      end
      object EdPrefixGen: TEdit
        Left = 122
        Top = 326
        Width = 63
        Height = 21
        TabOrder = 4
      end
      object EdSufixGen: TEdit
        Left = 312
        Top = 326
        Width = 82
        Height = 21
        TabOrder = 5
      end
      object GroupBox4: TGroupBox
        Left = 157
        Top = 206
        Width = 240
        Height = 115
        Caption = 'DefaultFormats'
        TabOrder = 3
        object Label9: TLabel
          Left = 5
          Top = 13
          Width = 86
          Height = 13
          Caption = 'Date                    :'
        end
        object Label10: TLabel
          Left = 5
          Top = 33
          Width = 86
          Height = 13
          Caption = 'Time                    :'
        end
        object Label11: TLabel
          Left = 5
          Top = 73
          Width = 85
          Height = 13
          Caption = 'Display Numeric  :'
        end
        object Label12: TLabel
          Left = 5
          Top = 93
          Width = 84
          Height = 13
          Caption = 'Edit Numeric       :'
        end
        object Label7: TLabel
          Left = 5
          Top = 53
          Width = 86
          Height = 13
          Caption = 'DateTimeDisplay :'
        end
        object edDateFormat: TEdit
          Left = 92
          Top = 9
          Width = 140
          Height = 21
          TabOrder = 0
        end
        object edTimeFormat: TEdit
          Left = 92
          Top = 29
          Width = 140
          Height = 21
          TabOrder = 1
        end
        object edDisplayNumFormat: TEdit
          Left = 92
          Top = 69
          Width = 140
          Height = 21
          TabOrder = 3
        end
        object edEditNumFormat: TEdit
          Left = 92
          Top = 89
          Width = 140
          Height = 21
          TabOrder = 4
        end
        object edDateTimeDisplay: TEdit
          Left = 92
          Top = 49
          Width = 140
          Height = 21
          TabOrder = 2
        end
      end
    end
    object TabSheet1: TTabSheet
      Caption = 'TpFIBDatabase'
      object Label6: TLabel
        Left = 12
        Top = 116
        Width = 38
        Height = 13
        Caption = 'C&harSet'
        FocusControl = CharSetC
      end
      object Label8: TLabel
        Left = 12
        Top = 142
        Width = 57
        Height = 13
        Caption = 'S&QL Dialect'
        FocusControl = DialectC
      end
      object chStoreConnected: TCheckBox
        Left = 13
        Top = 17
        Width = 308
        Height = 17
        Caption = 'Store Connected'
        TabOrder = 0
      end
      object chSynchronizeTime: TCheckBox
        Left = 13
        Top = 39
        Width = 308
        Height = 17
        Caption = 'Synchronize Time '
        TabOrder = 1
      end
      object chUpperOldNames: TCheckBox
        Left = 13
        Top = 61
        Width = 340
        Height = 17
        Caption = 'Upper Old Names'
        TabOrder = 2
      end
      object chUseLoginPrompt: TCheckBox
        Left = 13
        Top = 83
        Width = 348
        Height = 17
        Caption = 'Use Login Prompt'
        TabOrder = 3
      end
      object CharSetC: TComboBox
        Left = 90
        Top = 113
        Width = 97
        Height = 21
        ItemHeight = 13
        TabOrder = 4
        Items.Strings = (
          'ASCII'
          'CYRL'
          'DOS437'
          'DOS850'
          'DOS852'
          'DOS857'
          'DOS860'
          'DOS861'
          'DOS863'
          'DOS865'
          'DOS866'
          'EUCJ_0208'
          'ISO8859_1'
          'NEXT'
          'NONE'
          'OCTETS'
          'SJIS_0208'
          'UNICODE_FSS'
          'WIN1250'
          'WIN1251'
          'WIN1252'
          'WIN1253'
          'WIN1254')
      end
      object DialectC: TComboBox
        Left = 90
        Top = 139
        Width = 97
        Height = 21
        Style = csDropDownList
        ItemHeight = 13
        TabOrder = 5
        Items.Strings = (
          '1'
          '2'
          '3')
      end
      object chCloseDsgnConnect: TCheckBox
        Left = 13
        Top = 171
        Width = 348
        Height = 17
        Caption = 'Close design connect after run application'
        TabOrder = 6
        OnClick = chCloseDsgnConnectClick
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'TpFIBTransaction'
      object Label1: TLabel
        Left = 7
        Top = 20
        Width = 70
        Height = 13
        Caption = 'Timeout action'
        FocusControl = cmbTimeOutAction
      end
      object Label2: TLabel
        Left = 7
        Top = 44
        Width = 38
        Height = 13
        Caption = 'Timeout'
        FocusControl = edTimeout
      end
      object Label3: TLabel
        Left = 7
        Top = 68
        Width = 48
        Height = 13
        Caption = 'TPBMode'
        FocusControl = cmbTPBMode
      end
      object cmbTimeOutAction: TComboBox
        Left = 155
        Top = 17
        Width = 142
        Height = 21
        Style = csDropDownList
        ItemHeight = 13
        TabOrder = 0
        Items.Strings = (
          'TARollback'
          'TARollbackRetaining'
          'TACommit'
          'TACommitRetaining')
      end
      object edTimeout: TEdit
        Left = 155
        Top = 40
        Width = 142
        Height = 21
        AutoSize = False
        TabOrder = 1
      end
      object cmbTPBMode: TComboBox
        Left = 155
        Top = 65
        Width = 142
        Height = 21
        Style = csDropDownList
        ItemHeight = 13
        TabOrder = 2
        Items.Strings = (
          'tpbDefault'
          'tpbReadCommitted'
          'tpbRepeatableRead')
      end
    end
    object TabSheet3: TTabSheet
      Caption = 'TpFIBQuery'
      object ChGo1: TCheckBox
        Left = 14
        Top = 23
        Width = 347
        Height = 17
        Caption = 'Go to First Record'
        TabOrder = 0
      end
      object ChParamCheck: TCheckBox
        Left = 14
        Top = 45
        Width = 355
        Height = 17
        Caption = 'ParamCheck'
        TabOrder = 1
      end
      object chAutoStartTransaction: TCheckBox
        Left = 14
        Top = 68
        Width = 355
        Height = 17
        Caption = 'Autostart transaction'
        TabOrder = 2
      end
      object chAutoCommitTransaction: TCheckBox
        Left = 14
        Top = 90
        Width = 355
        Height = 17
        Caption = 'Autocommit transaction'
        TabOrder = 3
      end
    end
  end
  object Button1: TButton
    Left = 256
    Top = 392
    Width = 75
    Height = 25
    Caption = '&OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object Button2: TButton
    Left = 342
    Top = 392
    Width = 75
    Height = 25
    Cancel = True
    Caption = '&Cancel'
    ModalResult = 2
    TabOrder = 2
  end
end
