object frmCompSearchResult: TfrmCompSearchResult
  Left = 684
  Top = 143
  BorderStyle = bsSizeToolWin
  Caption = 'Component Search Result'
  ClientHeight = 364
  ClientWidth = 263
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object ListBox1: TListBox
    Left = 0
    Top = 0
    Width = 263
    Height = 364
    Style = lbOwnerDrawFixed
    Align = alClient
    ItemHeight = 13
    TabOrder = 0
    OnClick = ListBox1Click
    OnDblClick = ListBox1DblClick
    OnDrawItem = ListBox1DrawItem
  end
end
