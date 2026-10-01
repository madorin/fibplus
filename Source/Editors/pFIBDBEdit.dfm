object DBEditForm: TDBEditForm
  Left = 279
  Top = 199
  BorderStyle = bsDialog
  Caption = 'Connection Properties'
  ClientHeight = 315
  ClientWidth = 537
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
  object GroupBox1: TGroupBox
    Left = 8
    Top = 5
    Width = 433
    Height = 134
    Caption = ' Server '
    TabOrder = 0
    object Label1: TLabel
      Left = 14
      Top = 37
      Width = 31
      Height = 13
      Caption = '&Server'
      FocusControl = ServerE
    end
    object Label2: TLabel
      Left = 310
      Top = 37
      Width = 81
      Height = 13
      Caption = '&Network protocol'
      FocusControl = ProtocolC
    end
    object Label7: TLabel
      Left = 16
      Top = 108
      Width = 46
      Height = 13
      Caption = '&Database'
      FocusControl = DBNameE
    end
    object Label9: TLabel
      Left = 16
      Top = 81
      Width = 53
      Height = 13
      Caption = '&Alias Name'
      FocusControl = cmbAliases
    end
    object Label11: TLabel
      Left = 178
      Top = 37
      Width = 99
      Height = 13
      Caption = 'Port (only for Firebird)'
      FocusControl = edPort
    end
    object LocalC: TRadioButton
      Left = 12
      Top = 17
      Width = 105
      Height = 17
      Caption = '&Local engine'
      Checked = True
      TabOrder = 0
      TabStop = True
      OnClick = LocalCClick
    end
    object RemoteC: TRadioButton
      Left = 148
      Top = 17
      Width = 105
      Height = 17
      Caption = '&Remote server'
      TabOrder = 1
      OnClick = RemoteCClick
    end
    object ServerE: TEdit
      Left = 14
      Top = 53
      Width = 157
      Height = 21
      Enabled = False
      TabOrder = 2
    end
    object ProtocolC: TComboBox
      Left = 310
      Top = 53
      Width = 105
      Height = 21
      Style = csDropDownList
      Enabled = False
      ItemHeight = 13
      TabOrder = 4
      Items.Strings = (
        'NetBEUI'
        'Novell SPX'
        'TCP/IP')
    end
    object DBNameE: TEdit
      Left = 78
      Top = 105
      Width = 322
      Height = 21
      TabOrder = 6
    end
    object BrowseB: TButton
      Left = 401
      Top = 105
      Width = 20
      Height = 21
      Caption = '...'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 7
      OnClick = BrowseBClick
    end
    object cmbAliases: TComboBox
      Left = 78
      Top = 78
      Width = 272
      Height = 21
      ItemHeight = 13
      TabOrder = 5
      OnChange = cmbAliasesChange
    end
    object chSaveAlias: TCheckBox
      Left = 352
      Top = 81
      Width = 73
      Height = 17
      Caption = 'Save Alias'
      Checked = True
      State = cbChecked
      TabOrder = 8
    end
    object edPort: TEdit
      Left = 178
      Top = 53
      Width = 121
      Height = 21
      TabOrder = 3
    end
  end
  object GroupBox2: TGroupBox
    Left = 8
    Top = 139
    Width = 433
    Height = 170
    Caption = ' Connection Parameters '
    TabOrder = 1
    object Label3: TLabel
      Left = 8
      Top = 24
      Width = 51
      Height = 13
      Caption = '&User name'
      FocusControl = UserE
    end
    object Label4: TLabel
      Left = 8
      Top = 48
      Width = 46
      Height = 13
      Caption = '&Password'
      FocusControl = PasswordE
    end
    object Label5: TLabel
      Left = 8
      Top = 72
      Width = 22
      Height = 13
      Caption = 'Rol&e'
      FocusControl = RoleE
    end
    object Label6: TLabel
      Left = 8
      Top = 96
      Width = 38
      Height = 13
      Caption = 'C&harSet'
      FocusControl = CharSetC
    end
    object Label8: TLabel
      Left = 8
      Top = 120
      Width = 57
      Height = 13
      Caption = 'S&QL Dialect'
      FocusControl = DialectC
    end
    object Label10: TLabel
      Left = 8
      Top = 144
      Width = 60
      Height = 13
      Caption = 'Client Library'
    end
    object UserE: TEdit
      Left = 78
      Top = 21
      Width = 123
      Height = 21
      CharCase = ecUpperCase
      TabOrder = 0
      OnChange = UserEChange
    end
    object PasswordE: TEdit
      Left = 78
      Top = 45
      Width = 124
      Height = 21
      TabOrder = 1
      OnChange = PasswordEChange
    end
    object RoleE: TEdit
      Left = 78
      Top = 69
      Width = 124
      Height = 21
      CharCase = ecUpperCase
      TabOrder = 2
      OnChange = RoleEChange
    end
    object CharSetC: TComboBox
      Left = 78
      Top = 93
      Width = 124
      Height = 21
      ItemHeight = 13
      TabOrder = 3
      OnChange = CharSetCChange
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
        'UTF8'
        'WIN1250'
        'WIN1251'
        'WIN1252'
        'WIN1253'
        'WIN1254')
    end
    object UseLoginC: TCheckBox
      Left = 216
      Top = 120
      Width = 113
      Height = 17
      Caption = 'Use lo&gin prompt'
      TabOrder = 5
    end
    object ParamsM: TMemo
      Left = 216
      Top = 21
      Width = 201
      Height = 93
      TabOrder = 6
    end
    object DialectC: TComboBox
      Left = 78
      Top = 117
      Width = 124
      Height = 21
      Style = csDropDownList
      ItemHeight = 13
      TabOrder = 4
      Items.Strings = (
        '1'
        '2'
        '3')
    end
    object edLibrary: TEdit
      Left = 78
      Top = 141
      Width = 323
      Height = 21
      TabOrder = 7
      OnChange = UserEChange
    end
    object btnLibBrowse: TButton
      Left = 403
      Top = 141
      Width = 20
      Height = 21
      Caption = '...'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 8
      OnClick = btnLibBrowseClick
    end
  end
  object OkB: TButton
    Left = 456
    Top = 13
    Width = 75
    Height = 25
    Caption = '&OK'
    ModalResult = 1
    TabOrder = 2
  end
  object CancelB: TButton
    Left = 456
    Top = 42
    Width = 75
    Height = 25
    Cancel = True
    Caption = '&Cancel'
    ModalResult = 2
    TabOrder = 3
  end
  object TestB: TButton
    Left = 456
    Top = 71
    Width = 75
    Height = 25
    Caption = '&Test'
    TabOrder = 4
    OnClick = TestBClick
  end
  object OpenD: TOpenDialog
    DefaultExt = 'GDB'
    Filter = 
      'Interbase Database Files (*.gdb)|*.gdb|Interbase7 Database Files' +
      ' (*.ib)|*.ib|All files (*.*)|*.*'
    Left = 272
    Top = 192
  end
  object browseLib: TOpenDialog
    DefaultExt = 'DLL'
    Filter = 'Dynamic link library (*.dll)|*.dll|All files (*.*)|*.*'
    Left = 344
    Top = 192
  end
end
