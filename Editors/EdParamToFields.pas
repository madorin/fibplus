unit EdParamToFields;

interface
         {$i ..\FIBPlus.inc}
uses
  Windows, Messages, SysUtils,
  Classes,
   {$IFDEF D_XE2}
  Vcl.Graphics, Vcl.Controls, Vcl.Forms,  Vcl.Dialogs, Vcl.ComCtrls, Vcl.ExtCtrls,
  Vcl.StdCtrls,
  {$ELSE}
  Graphics, Controls, Forms,  Dialogs, ComCtrls, ExtCtrls, StdCtrls,
  {$ENDIF}
  DB,  uFIBEditorForm
  {$IFDEF D6+}
  ,Variants
  {$ENDIF}

  ;

type
  TfrmEdParamToFields = class(TFIBEditorCustomForm)
    Memo1: TMemo;
    Panel1: TPanel;
    Button1: TButton;
    Button2: TButton;
    Panel2: TPanel;
    lstFields: TListBox;
    Splitter1: TSplitter;
    lstParams: TListBox;
    Splitter2: TSplitter;
    Button3: TButton;
    Button4: TButton;
    Panel3: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Splitter1Moved(Sender: TObject);
  private
    FDataSet  :TDataSet;
  public
    { Public declarations }
  end;

var
  frmEdParamToFields: TfrmEdParamToFields;

 function ShowEdParamToFields(DataSet:TDataSet;CurValues:TStrings):boolean;

implementation

uses pFIBInterfaces, RTTIRoutines;



{$R *.dfm}
 function ShowEdParamToFields(DataSet:TDataSet;CurValues:TStrings):boolean;
 var i:integer;
     ids:IFIBDataSet;
 begin
   if not ObjSupports(DataSet,IFIBDataSet,ids) then
   begin
     Result:=False;
     Exit;
   end;

   frmEdParamToFields:= TfrmEdParamToFields.Create(Application);
   with frmEdParamToFields do
   try
    Caption:=DataSet.Name+':Params to Fields Links (Values for NewRecord)';
    FDataSet:=DataSet;

    Memo1.Lines.Assign(CurValues);
    for i:=0 to DataSet.FieldCount-1 do
     lstFields.Items.Add(DataSet.Fields[i].FieldName);
    for i:=0 to ids.ParamCount-1 do
//     lstParams.Items.Add(DataSet.Params[i].Name);
     lstParams.Items.Add(ids.ParamName(i));

    if lstFields.Items.Count>0 then
     lstFields.ItemIndex:=0;

    if lstParams.Items.Count>0 then
     lstParams.ItemIndex:=0;
    Result:=ShowModal=mrOK;
    if Result then
     CurValues.Assign(Memo1.Lines)
   finally
     Free
   end;
 end;

procedure TfrmEdParamToFields.Button3Click(Sender: TObject);
begin
 if (lstFields.Items.Count>0) and (lstParams.Items.Count>0) then
  Memo1.Lines.Values[lstFields.Items[lstFields.ItemIndex]]:=
   lstParams.Items[lstParams.ItemIndex]
  ;
end;


procedure TfrmEdParamToFields.Button4Click(Sender: TObject);
 var
     ids:IFIBDataSet;
begin
 ObjSupports(FDataSet,IFIBDataSet,ids);
 ids.ParseParamToFieldsLinks(Memo1.Lines);
end;

procedure TfrmEdParamToFields.Splitter1Moved(Sender: TObject);
begin
  Label2.Left:=lstFields.Width+1
end;

end.
