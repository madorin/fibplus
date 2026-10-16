object FIBPreferencesForm: TFIBPreferencesForm
  Left = 310
  Top = 137
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'FIBPlus Preferences'
  ClientHeight = 589
  ClientWidth = 480
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnCloseQuery = FormCloseQuery
  TextHeight = 15
  object z: TPageControl
    Left = 8
    Top = 8
    Width = 464
    Height = 540
    ActivePage = TabSheet4
    TabOrder = 0
    object TabSheet4: TTabSheet
      Caption = 'TFIBDataSet'
      object Label4: TLabel
        Left = 6
        Top = 485
        Width = 121
        Height = 15
        Caption = 'Prefix Generator name'
      end
      object Label5: TLabel
        Left = 234
        Top = 485
        Width = 117
        Height = 15
        Caption = 'Sufix Generator name'
      end
      object GroupBox2: TGroupBox
        Left = 6
        Top = 6
        Width = 222
        Height = 314
        Caption = 'Options'
        TabOrder = 0
        object chTrimCharFields: TCheckBox
          Left = 10
          Top = 22
          Width = 205
          Height = 17
          Caption = 'TrimCharFields'
          TabOrder = 0
        end
        object chRefreshAfterPost: TCheckBox
          Left = 10
          Top = 40
          Width = 205
          Height = 17
          Caption = 'RefreshAfterPost'
          TabOrder = 1
        end
        object chRefreshDeletedRecord: TCheckBox
          Left = 10
          Top = 58
          Width = 205
          Height = 17
          Caption = 'RefreshDeletedRecord'
          TabOrder = 2
        end
        object chStartTransaction: TCheckBox
          Left = 10
          Top = 76
          Width = 205
          Height = 17
          Caption = 'StartTransaction'
          TabOrder = 3
        end
        object chAutoFormatFields: TCheckBox
          Left = 10
          Top = 94
          Width = 205
          Height = 17
          Caption = 'AutoFormatFields'
          TabOrder = 4
        end
        object chProtectedEdit: TCheckBox
          Left = 10
          Top = 112
          Width = 205
          Height = 17
          Caption = 'ProtectedEdit'
          TabOrder = 5
        end
        object chKeepSorting: TCheckBox
          Left = 10
          Top = 130
          Width = 205
          Height = 17
          Caption = 'KeepSorting'
          TabOrder = 6
        end
        object chPersistentSorting: TCheckBox
          Left = 10
          Top = 148
          Width = 205
          Height = 17
          Caption = 'PersistentSorting'
          TabOrder = 7
        end
        object chVisibleRecno: TCheckBox
          Left = 10
          Top = 166
          Width = 205
          Height = 17
          Caption = 'VisibleRecno'
          TabOrder = 8
        end
        object chFetchAll: TCheckBox
          Left = 10
          Top = 184
          Width = 205
          Height = 17
          Caption = 'FetchAll'
          TabOrder = 9
        end
        object chCacheCalcFields: TCheckBox
          Left = 10
          Top = 202
          Width = 205
          Height = 17
          Caption = 'CacheCalcFields'
          TabOrder = 10
        end
        object chUseSelectForLock: TCheckBox
          Left = 10
          Top = 220
          Width = 205
          Height = 17
          Caption = 'UseSelectForLock'
          TabOrder = 11
        end
        object chNoForceIsNull: TCheckBox
          Left = 10
          Top = 238
          Width = 205
          Height = 17
          Caption = 'NoForceIsNull'
          TabOrder = 12
        end
        object chFreeHandlesAfterClose: TCheckBox
          Left = 10
          Top = 256
          Width = 205
          Height = 17
          Caption = 'FreeHandlesAfterClose'
          TabOrder = 13
        end
        object chRefreshAfterDelete: TCheckBox
          Left = 10
          Top = 274
          Width = 205
          Height = 17
          Caption = 'RefreshAfterDelete'
          TabOrder = 14
        end
        object chDontCloseAfterEndTransaction: TCheckBox
          Left = 10
          Top = 292
          Width = 205
          Height = 17
          Caption = 'DontCloseAfterEndTransaction'
          TabOrder = 15
        end
      end
      object GroupBox1: TGroupBox
        Left = 234
        Top = 6
        Width = 216
        Height = 314
        Caption = 'PrepareOptions'
        TabOrder = 1
        object chRequiredFields: TCheckBox
          Left = 10
          Top = 22
          Width = 198
          Height = 17
          Caption = 'SetRequiredFields'
          TabOrder = 0
        end
        object chSetReadOnlyFields: TCheckBox
          Left = 10
          Top = 40
          Width = 198
          Height = 17
          Caption = 'SetReadOnlyFields'
          TabOrder = 1
        end
        object chImportDefaultValues: TCheckBox
          Left = 10
          Top = 58
          Width = 198
          Height = 17
          Caption = 'ImportDefaultValues'
          TabOrder = 2
        end
        object chUseBooleanField: TCheckBox
          Left = 10
          Top = 76
          Width = 198
          Height = 17
          Caption = 'UseBooleanField'
          TabOrder = 3
        end
        object chUseGuidField: TCheckBox
          Left = 10
          Top = 94
          Width = 198
          Height = 17
          Caption = 'UseGuidField'
          TabOrder = 4
        end
        object chUseLargeIntField: TCheckBox
          Left = 10
          Top = 112
          Width = 198
          Height = 17
          Caption = 'UseLargeIntField'
          TabOrder = 5
        end
        object chUseSQLINT64ToBCD: TCheckBox
          Left = 10
          Top = 130
          Width = 198
          Height = 17
          Caption = 'SQLINT64 To BCD Field'
          TabOrder = 6
        end
        object chGetOrderInfo: TCheckBox
          Left = 10
          Top = 148
          Width = 198
          Height = 17
          Caption = 'GetOrderInfo'
          TabOrder = 7
        end
        object chApplyRepositary: TCheckBox
          Left = 10
          Top = 166
          Width = 198
          Height = 17
          Caption = 'ApplyRepositary'
          TabOrder = 8
        end
        object chAskRecordCount: TCheckBox
          Left = 10
          Top = 184
          Width = 198
          Height = 17
          Caption = 'AskRecordCount'
          TabOrder = 9
        end
        object chEmptyStrToNull: TCheckBox
          Left = 10
          Top = 202
          Width = 198
          Height = 17
          Caption = 'SetEmptyStrToNull'
          TabOrder = 10
        end
        object chCanEditComputedFields: TCheckBox
          Left = 10
          Top = 220
          Width = 198
          Height = 17
          Caption = 'CanEditComputedFields'
          TabOrder = 11
        end
        object chSupportUnicodeBlobs: TCheckBox
          Left = 10
          Top = 238
          Width = 198
          Height = 17
          Caption = 'SupportUnicodeBlobs'
          TabOrder = 12
        end
      end
      object GroupBox3: TGroupBox
        Left = 6
        Top = 328
        Width = 176
        Height = 146
        Caption = 'DetailConditions'
        TabOrder = 2
        object chForceOpen: TCheckBox
          Left = 10
          Top = 22
          Width = 158
          Height = 17
          Caption = 'ForceOpen'
          TabOrder = 0
        end
        object chForceMasterRefresh: TCheckBox
          Left = 10
          Top = 46
          Width = 158
          Height = 17
          Caption = 'ForceMasterRefresh'
          TabOrder = 1
        end
        object chWaitEndMasterScroll: TCheckBox
          Left = 10
          Top = 70
          Width = 158
          Height = 17
          Caption = 'WaitEndMasterScroll'
          TabOrder = 2
        end
        object chIgnoreMasterClose: TCheckBox
          Left = 10
          Top = 94
          Width = 158
          Height = 17
          Caption = 'Ignore MasterClose'
          TabOrder = 3
        end
      end
      object EdPrefixGen: TEdit
        Left = 136
        Top = 482
        Width = 86
        Height = 23
        TabOrder = 4
      end
      object EdSufixGen: TEdit
        Left = 360
        Top = 482
        Width = 90
        Height = 23
        TabOrder = 5
      end
      object GroupBox4: TGroupBox
        Left = 188
        Top = 328
        Width = 262
        Height = 146
        Caption = 'DefaultFormats'
        TabOrder = 3
        object Label9: TLabel
          Left = 10
          Top = 26
          Width = 90
          Height = 15
          Caption = 'Date'
          FocusControl = edDateFormat
        end
        object Label10: TLabel
          Left = 10
          Top = 50
          Width = 90
          Height = 15
          Caption = 'Time'
          FocusControl = edTimeFormat
        end
        object Label7: TLabel
          Left = 10
          Top = 74
          Width = 90
          Height = 15
          Caption = 'DateTimeDisplay'
          FocusControl = edDateTimeDisplay
        end
        object Label11: TLabel
          Left = 10
          Top = 98
          Width = 90
          Height = 15
          Caption = 'Display Numeric'
          FocusControl = edDisplayNumFormat
        end
        object Label12: TLabel
          Left = 10
          Top = 122
          Width = 90
          Height = 15
          Caption = 'Edit Numeric'
          FocusControl = edEditNumFormat
        end
        object edDateFormat: TEdit
          Left = 116
          Top = 22
          Width = 136
          Height = 23
          TabOrder = 0
        end
        object edTimeFormat: TEdit
          Left = 116
          Top = 46
          Width = 136
          Height = 23
          TabOrder = 1
        end
        object edDateTimeDisplay: TEdit
          Left = 116
          Top = 70
          Width = 136
          Height = 23
          TabOrder = 2
        end
        object edDisplayNumFormat: TEdit
          Left = 116
          Top = 94
          Width = 136
          Height = 23
          TabOrder = 3
        end
        object edEditNumFormat: TEdit
          Left = 116
          Top = 118
          Width = 136
          Height = 23
          TabOrder = 4
        end
      end
    end
    object TabSheet1: TTabSheet
      Caption = 'TFIBDatabase'
      object Label6: TLabel
        Left = 12
        Top = 123
        Width = 42
        Height = 15
        Caption = 'C&harSet'
        FocusControl = CharSetC
      end
      object Label8: TLabel
        Left = 12
        Top = 152
        Width = 64
        Height = 15
        Caption = 'S&QL Dialect'
        FocusControl = DialectC
      end
      object chStoreConnected: TCheckBox
        Left = 12
        Top = 12
        Width = 430
        Height = 17
        Caption = 'Store Connected'
        TabOrder = 0
      end
      object chSynchronizeTime: TCheckBox
        Left = 12
        Top = 36
        Width = 430
        Height = 17
        Caption = 'Synchronize Time'
        TabOrder = 1
      end
      object chUpperOldNames: TCheckBox
        Left = 12
        Top = 60
        Width = 430
        Height = 17
        Caption = 'Upper Old Names'
        TabOrder = 2
      end
      object chUseLoginPrompt: TCheckBox
        Left = 12
        Top = 84
        Width = 430
        Height = 17
        Caption = 'Use Login Prompt'
        TabOrder = 3
      end
      object CharSetC: TComboBox
        Left = 110
        Top = 120
        Width = 140
        Height = 23
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
        Left = 110
        Top = 149
        Width = 140
        Height = 23
        Style = csDropDownList
        TabOrder = 5
        Items.Strings = (
          '1'
          '2'
          '3')
      end
      object chCloseDsgnConnect: TCheckBox
        Left = 12
        Top = 188
        Width = 430
        Height = 17
        Caption = 'Close design-time connections before the program runs'
        TabOrder = 6
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'TFIBTransaction'
      object Label1: TLabel
        Left = 12
        Top = 15
        Width = 81
        Height = 15
        Caption = 'Timeout action'
        FocusControl = cmbTimeOutAction
      end
      object Label2: TLabel
        Left = 12
        Top = 44
        Width = 45
        Height = 15
        Caption = 'Timeout'
        FocusControl = edTimeout
      end
      object Label3: TLabel
        Left = 12
        Top = 73
        Width = 54
        Height = 15
        Caption = 'TPBMode'
        FocusControl = cmbTPBMode
      end
      object cmbTimeOutAction: TComboBox
        Left = 140
        Top = 12
        Width = 170
        Height = 23
        Style = csDropDownList
        TabOrder = 0
        Items.Strings = (
          'TARollback'
          'TARollbackRetaining'
          'TACommit'
          'TACommitRetaining')
      end
      object edTimeout: TEdit
        Left = 140
        Top = 41
        Width = 170
        Height = 23
        TabOrder = 1
      end
      object cmbTPBMode: TComboBox
        Left = 140
        Top = 70
        Width = 170
        Height = 23
        Style = csDropDownList
        TabOrder = 2
        Items.Strings = (
          'tpbDefault'
          'tpbReadCommitted'
          'tpbRepeatableRead'
          'tpbReadConsistency')
      end
    end
    object TabSheet3: TTabSheet
      Caption = 'TFIBQuery'
      object ChGo1: TCheckBox
        Left = 12
        Top = 12
        Width = 430
        Height = 17
        Caption = 'Go to First Record'
        TabOrder = 0
      end
      object ChParamCheck: TCheckBox
        Left = 12
        Top = 36
        Width = 430
        Height = 17
        Caption = 'ParamCheck'
        TabOrder = 1
      end
      object chAutoStartTransaction: TCheckBox
        Left = 12
        Top = 60
        Width = 430
        Height = 17
        Caption = 'Autostart transaction'
        TabOrder = 2
      end
      object chAutoCommitTransaction: TCheckBox
        Left = 12
        Top = 84
        Width = 430
        Height = 17
        Caption = 'Autocommit transaction'
        TabOrder = 3
      end
      object chQueryTrimCharFields: TCheckBox
        Left = 12
        Top = 108
        Width = 430
        Height = 17
        Caption = 'TrimCharFields'
        TabOrder = 4
      end
      object chQueryNoForceIsNull: TCheckBox
        Left = 12
        Top = 132
        Width = 430
        Height = 17
        Caption = 'NoForceIsNull'
        TabOrder = 5
      end
      object chFreeHandleAfterExecute: TCheckBox
        Left = 12
        Top = 156
        Width = 430
        Height = 17
        Caption = 'FreeHandleAfterExecute'
        TabOrder = 6
      end
    end
  end
  object Button1: TButton
    Left = 314
    Top = 556
    Width = 75
    Height = 25
    Caption = '&OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object Button2: TButton
    Left = 397
    Top = 556
    Width = 75
    Height = 25
    Cancel = True
    Caption = '&Cancel'
    ModalResult = 2
    TabOrder = 2
  end
end
