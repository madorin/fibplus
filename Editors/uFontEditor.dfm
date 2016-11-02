object frmFontEditor: TfrmFontEditor
  Left = 398
  Top = 249
  BorderStyle = bsDialog
  Caption = 'Editor Properties'
  ClientHeight = 255
  ClientWidth = 503
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 503
    Height = 255
    ActivePage = TabSheet1
    Align = alClient
    TabOrder = 0
    object TabSheet1: TTabSheet
      Caption = 'Font and colors'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object Label1: TLabel
        Left = 232
        Top = 52
        Width = 30
        Height = 13
        Caption = 'Color'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label2: TLabel
        Left = 232
        Top = 4
        Width = 26
        Height = 13
        Caption = 'Font'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lstTokens: TListBox
        Left = 0
        Top = 0
        Width = 209
        Height = 227
        Align = alLeft
        ItemHeight = 13
        Items.Strings = (
          'Background'
          'KeyWords'
          'Functions'
          'Parameters'
          'Types'
          'Comments'
          'Strings'
          'Numbers'
          'Selected Text')
        TabOrder = 0
        OnKeyUp = lstTokensKeyUp
        OnMouseUp = lstTokensMouseUp
      end
      object edColor: TEdit
        Left = 232
        Top = 68
        Width = 241
        Height = 21
        ReadOnly = True
        TabOrder = 1
      end
      object GroupBox1: TGroupBox
        Left = 232
        Top = 108
        Width = 241
        Height = 97
        Caption = 'FontStyle'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 2
        object chBold: TCheckBox
          Left = 21
          Top = 19
          Width = 97
          Height = 17
          Caption = '&Bold'
          Enabled = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
          TabOrder = 0
          OnClick = chBoldClick
        end
        object chItalic: TCheckBox
          Left = 21
          Top = 42
          Width = 97
          Height = 17
          Caption = '&Italic'
          Enabled = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
          TabOrder = 1
          OnClick = chBoldClick
        end
        object chUnderLine: TCheckBox
          Left = 21
          Top = 66
          Width = 97
          Height = 17
          Caption = '&Underline'
          Enabled = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
          TabOrder = 2
          OnClick = chBoldClick
        end
      end
      object edFont: TEdit
        Left = 233
        Top = 22
        Width = 238
        Height = 21
        ReadOnly = True
        TabOrder = 3
      end
      object btnChangeFont: TButton
        Left = 471
        Top = 23
        Width = 20
        Height = 20
        Caption = '...'
        TabOrder = 4
        OnClick = btnChangeFontClick
      end
      object btnChangeColor: TButton
        Left = 472
        Top = 69
        Width = 20
        Height = 20
        Caption = '...'
        TabOrder = 5
        OnClick = btnChangeColorClick
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'Other'
      ImageIndex = 1
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object chUseMetaInProposal: TCheckBox
        Left = 12
        Top = 10
        Width = 429
        Height = 17
        Caption = 'Use metadata in code proposal'
        TabOrder = 0
        OnClick = chUseMetaInProposalClick
      end
    end
  end
  object FontDialog1: TFontDialog
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    Left = 360
    Top = 160
  end
  object ColorDialog1: TColorDialog
    Left = 400
    Top = 160
  end
end
