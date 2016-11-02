unit uFrmSearchResult;

interface
{$I ..\FIBPlus.inc}
uses
  Windows, Messages, SysUtils, {$IFDEF D6+}Variants, {$ENDIF}Classes,
   {$IFDEF D_XE2}
  Vcl.Graphics, Vcl.Controls, Vcl.Forms,  Vcl.Dialogs, Vcl.ComCtrls, Vcl.ExtCtrls,
  Vcl.StdCtrls,Vcl.Menus,
  {$ELSE}
  Graphics, Controls, Forms,  Dialogs, ComCtrls, ExtCtrls, StdCtrls,Menus,
  {$ENDIF}

  uFIBEditorForm;

type
  TfrmCompSearchResult = class(TFIBEditorCustomForm)
    ListBox1: TListBox;
    procedure ListBox1DrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure FormResize(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
    procedure ListBox1DblClick(Sender: TObject);
  private
    FUnits:TStringList;
  public
    constructor Create(AOwner:TComponent);override;
    destructor Destroy; override;
  end;

var
  frmCompSearchResult: TfrmCompSearchResult;

  procedure ShowSearchResult(ComponentList:TStrings);

implementation

uses FindCmp;

{$R *.dfm}

procedure ShowSearchResult(ComponentList:TStrings);
var
 I: Integer;
 P: Integer;
begin
  if frmCompSearchResult=nil then
   frmCompSearchResult:=TfrmCompSearchResult.Create(Application)
  else
  begin
   frmCompSearchResult.ListBox1.Items.Clear;
   frmCompSearchResult.FUnits.Clear;
  end;
  for I := 0 to ComponentList.Count - 1 do
  begin
   P:=Pos('#UNIT#', ComponentList[I]);
   frmCompSearchResult.ListBox1.Items.Add(Copy(ComponentList[I],1,P-1));
   frmCompSearchResult.FUnits.Add(Copy(ComponentList[I],P+6,MaxInt));
  end;
  frmCompSearchResult.Show;
end;

{ TfrmCompSearchResult }

constructor TfrmCompSearchResult.Create(AOwner: TComponent);
begin
  inherited;
  FUnits:=TStringList.Create;
end;

destructor TfrmCompSearchResult.Destroy;
begin
  FUnits.Free;
  inherited;
end;

procedure TfrmCompSearchResult.ListBox1DrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
	Offset: Integer;      { text offset width }
        P : Integer;
begin
  with (Control as TListBox).Canvas do  { draw on control canvas, not on the form }
  begin
    FillRect(Rect);       { clear the rectangle }
    Offset := 2;          { provide default offset }
    P:=Pos(':', (Control as TListBox).Items[Index]);
    Font.Style :=[fsBold] ;
    if Index=(Control as TListBox).ItemIndex then
     Font.Color :=clWhite
    else
     Font.Color :=clBlack;
    TextOut(Rect.Left + Offset, Rect.Top,
     Copy((Control as TListBox).Items[Index],1,P-1)
    )  ;
//    Font.Color :=clGray;
    TextOut((Rect.Left + ((Rect.Right-Rect.Left) div 2)), Rect.Top,':');
    if Index=(Control as TListBox).ItemIndex then
     Font.Color :=clWhite
    else
     Font.Color :=clRed;
    TextOut((Rect.Left + ((Rect.Right-Rect.Left) div 2))+5, Rect.Top,
        Copy((Control as TListBox).Items[Index],P+1,MaxInt)
    );
  end;
end;

procedure TfrmCompSearchResult.FormResize(Sender: TObject);
begin
 ListBox1.Invalidate
end;

procedure TfrmCompSearchResult.ListBox1Click(Sender: TObject);
begin
 ListBox1.Invalidate
end;

procedure TfrmCompSearchResult.ListBox1DblClick(Sender: TObject);
begin
  FindComponentExpert.DoComponentFocus(nil,
   ListBox1.Items[ListBox1.ItemIndex]+'#UNIT#'+FUnits[ListBox1.ItemIndex]
  );
end;

initialization
 frmCompSearchResult:=nil;
end.
