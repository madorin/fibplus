object fraEdConditions: TfraEdConditions
  Left = 0
  Top = 0
  Width = 474
  Height = 365
  TabOrder = 0
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 384
    Height = 365
    Align = alClient
    BevelOuter = bvNone
    BorderWidth = 4
    TabOrder = 0
    OnResize = ListView1Resize
    object Splitter1: TSplitter
      Left = 4
      Top = 231
      Width = 376
      Height = 4
      Cursor = crVSplit
      Align = alBottom
    end
    object GroupBox2: TGroupBox
      Left = 4
      Top = 4
      Width = 376
      Height = 227
      Align = alClient
      Caption = 'Condition text'
      TabOrder = 0
      object Panel3: TPanel
        Left = 2
        Top = 15
        Width = 372
        Height = 210
        Align = alClient
        BevelOuter = bvNone
        BorderWidth = 4
        TabOrder = 0
        object Memo1: TMemo
          Left = 4
          Top = 4
          Width = 364
          Height = 202
          Align = alClient
          TabOrder = 0
          OnExit = Memo1Exit
        end
      end
    end
    object GroupBox1: TGroupBox
      Left = 4
      Top = 235
      Width = 376
      Height = 126
      Align = alBottom
      Caption = 'Condition Names'
      TabOrder = 1
      object Panel4: TPanel
        Left = 2
        Top = 15
        Width = 372
        Height = 109
        Align = alClient
        BevelOuter = bvNone
        BorderWidth = 4
        TabOrder = 0
        object ListView1: TListView
          Left = 4
          Top = 4
          Width = 364
          Height = 101
          Align = alClient
          Checkboxes = True
          Columns = <
            item
              Caption = 'Conditions'
              Width = 320
            end>
          Ctl3D = False
          GridLines = True
          HideSelection = False
          RowSelect = True
          ShowColumnHeaders = False
          TabOrder = 0
          ViewStyle = vsReport
          OnChange = ListView1Change
          OnClick = ListView1Click
          OnKeyUp = ListView1KeyUp
        end
      end
    end
  end
  object Panel2: TPanel
    Left = 384
    Top = 0
    Width = 90
    Height = 365
    Align = alRight
    BevelOuter = bvNone
    TabOrder = 1
    object Button1: TButton
      Left = 8
      Top = 156
      Width = 75
      Height = 25
      Caption = '&OK'
      ModalResult = 1
      TabOrder = 2
    end
    object Button2: TButton
      Left = 8
      Top = 188
      Width = 75
      Height = 25
      Cancel = True
      Caption = '&Cancel'
      ModalResult = 2
      TabOrder = 3
    end
    object Button3: TButton
      Left = 7
      Top = 77
      Width = 75
      Height = 25
      Caption = '&Delete'
      TabOrder = 1
      OnClick = Button3Click
    end
    object Button4: TButton
      Left = 7
      Top = 11
      Width = 75
      Height = 25
      Caption = '&Add'
      TabOrder = 0
      OnClick = Button4Click
    end
    object Button5: TButton
      Left = 7
      Top = 109
      Width = 75
      Height = 25
      Caption = 'C&lear '
      TabOrder = 4
      OnClick = Button5Click
    end
    object btnEdit: TButton
      Left = 7
      Top = 43
      Width = 75
      Height = 25
      Caption = '&Edit'
      TabOrder = 5
      OnClick = btnEditClick
    end
  end
end
