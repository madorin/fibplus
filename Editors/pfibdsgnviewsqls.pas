{************************************************************************}
{ FIBPlus - component library  for direct access  to Interbase  databases}
{    FIBPlus is based in part on the product                             }
{    Free IB Components, written by Gregory H. Deatz for                 }
{    Hoagland, Longo, Moran, Dunst & Doukas Company.                     }
{                                         Contact:       gdeatz@hlmdd.com}
{    Copyright (c) 1998-2001 Serge Buzadzhy                              }
{                                         Contact: buzz@ukr.net          }
{  Please see the file FIBLicense.txt for full license information.      }
{************************************************************************}

unit pFIBDsgnViewSQLs;

interface
{$I ..\FIBPlus.inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, CheckLst, Db, FIBDataSet, pFIBDataSet, FIBQuery, pFIBQuery,
  ExtCtrls, ComCtrls, Menus, Buttons,clipbrd, FIBDatabase,pFIBDatabase,
  ImgList,  ToolWin,ToolsAPI,uFIBEditorForm
  {$IFDEF SQL_NAVIGATOR_SUPPORT_BDE}
    ,dbTables
  {$ENDIF}
  {$IFDEF USE_SYN_EDIT}
   ,SynEditHighlighter, SynHighlighterSQL, SynEdit, SynMemo
  {$ENDIF}

  ;

type
  TFIBSQLOwner=class
  private
    vFIBSQLOwner:TComponent;
    vChecked:boolean;
    procedure SetProp(const PropName:string; Value:TStrings);
    function GetCustomForm:TCustomForm;
  public
   constructor Create(aFIBSQLOwner:TComponent);
  end;

  TOperationOnSQLText=(oSaveSQL,oCheckSQL,oAnalyzeSQL,oClearDescr);

  TfrmSaveSQLs = class(TFIBEditorCustomForm)
    PopupMenu1: TPopupMenu;
    SelectAll1: TMenuItem;
    Unselectall1: TMenuItem;
    SaveDialog1: TSaveDialog;
    FindDialog1: TFindDialog;
    Panel2: TPanel;
    PopupMenu2: TPopupMenu;
    HideSearchResult1: TMenuItem;
    ShowSearchResult1: TMenuItem;
    CopytoClipboard1: TMenuItem;
    GotocurrentComponent1: TMenuItem;
    pFIBDatabase1: TpFIBDatabase;
    pFIBTransaction1: TpFIBTransaction;
    qryCheck: TpFIBQuery;
    StatusBar1: TStatusBar;
    Panel1: TPanel;
    GrSearch: TGroupBox;
    PageControl1: TPageControl;
    TabSQL: TTabSheet;
    TabInsertSQL: TTabSheet;
    TabUpdateSQL: TTabSheet;
    TabDeleteSQL: TTabSheet;
    TabRefreshSQL: TTabSheet;
    Splitter3: TSplitter;
    Splitter1: TSplitter;
    ImageList1: TImageList;
    PopupMenu3: TPopupMenu;
    miSaveallSQLs1: TMenuItem;
    SaveonlySelectSQL1: TMenuItem;
    qryBuf: TpFIBQuery;
    qryObjects: TpFIBQuery;
    qryInsObj: TpFIBQuery;
    qryUpdObj: TpFIBQuery;
    qryDescr: TpFIBDataSet;
    qryAllDescr: TpFIBDataSet;
    ToolBar1: TToolBar;
    btnGetForms: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton1: TToolButton;
    ToolButton3: TToolButton;
    ToolButton2: TToolButton;
    ToolButton8: TToolButton;
    ToolButton4: TToolButton;
    ToolButton9: TToolButton;
    ToolButton7: TToolButton;
    Panel3: TPanel;
    ListBox1: TListBox;
    Splitter4: TSplitter;
    MemErrMess: TMemo;
    Panel4: TPanel;
    lstForms: TCheckListBox;
    Splitter2: TSplitter;
    lstQueries: TCheckListBox;
    ToolButton10: TToolButton;
    procedure lstFormsEnter(Sender: TObject);
    procedure lstQueriesClickCheck(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure lstFormsClickCheck(Sender: TObject);
    procedure lstQueriesEnter(Sender: TObject);
    procedure SelectAll1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure FindDialog1Find(Sender: TObject);
    procedure ListBox1DblClick(Sender: TObject);
    procedure HideSearchResult1Click(Sender: TObject);
    procedure ShowSearchResult1Click(Sender: TObject);
    procedure CopytoClipboard1Click(Sender: TObject);
    procedure GotocurrentComponent1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure btnGetFormsClick(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
    procedure miSaveallSQLs1Click(Sender: TObject);
    procedure PopupMenu1Popup(Sender: TObject);
    procedure ToolButton7Click(Sender: TObject);
    procedure ToolButton5Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ToolButton8Click(Sender: TObject);
    procedure lstQueriesDblClick(Sender: TObject);
    procedure ToolButton10Click(Sender: TObject);
  private
    OI:TForm;
    OldSQLTxt:string;
    function CloseUnFile(const UnName:string) :boolean;
    function GetOI:TForm;
    function GetUnitName(aCmp:TComponent):string;
    {$IFDEF SQL_NAVIGATOR_SUPPORT_BDE}
    procedure DBParamsFromBDEAlias(
     const AliasName:string;var DPB: TStrings
    );
    procedure DBParamsFromBDEDatabase(
         const BDE_DataBase:TDatabase;var DPB: TStrings
    );

    {$ENDIF}
    procedure GetDBParams(cmp:TComponent; DPB:TStrings );
    function  Connect(DPB:TStrings):integer;


  private
    vFullSave:boolean;
    vProjectName:string;
    WindowList: Pointer;
    FSearchResult:TStrings;
    FListOfOpenedForms:TStringList;
    FUnits   :array of string;
    procedure MemoExit(Sender: TObject);
    procedure MemoEnter(Sender: TObject);
    procedure FillQueryList;
    function  PrepareForms(OnlyLoaded:boolean):boolean;
    procedure GetForms;
    procedure SetQueryCheck(Index:integer);
    procedure SetModuleCheck(Index:integer);
    procedure ClearForms;
    procedure ClearSQLs;
    procedure RegisterModule(Module:TComponent; const UnName:string);
    function  SearchContext(const Value:string):boolean;
    function  FindInCmp(cmp:TComponent;const Value:string):boolean;
    function  GetCurrentSQLOwner:TFIBSQLOwner;
    procedure ScanSelObjects(Operation:TOperationOnSQLText);
    procedure SetSearchResVisible(Value:boolean);
    procedure ClearSearch;
    procedure FocusToComponent(cmp:TComponent);

    procedure SaveFIBSQLOwner(var F:Text;aFIBSQLOwner:TComponent);
    function  Analyze(aFIBSQLOwner:TComponent;ResultStrings:TStrings;
     var F:TextFile
    ) :integer;
    function  CheckSQL(aFIBSQLOwner:TComponent):integer;
    function  UnitInProject(const UnitName:string):boolean;
  public
    destructor Destroy; override;
  end;


 procedure  ShowAllSQLs;

var
  frmSaveSQLs: TfrmSaveSQLs;

implementation

{$R *.DFM}
uses StrUtil,SQLTxtRtns,
  {$IFNDEF  D6+}
   DsgnIntf,
  {$ELSE}
   DesignIntf,
  {$ENDIF}
 EditIntf, FIBToolsConsts,
 FIBDataSQLEditor,FIBSQLEditor
, FindCmp;


{$IFDEF VER130}
 type TFormDesigner=IFormDesigner;
      TComponentList=TDesignerSelectionList;
{$ELSE}
 {$IFDEF D6+}
  type TFormDesigner=IDesigner;
 {$ELSE}
 {$IFDEF VER120}
  type TFormDesigner=IFormDesigner;
 {$ENDIF}
 {$ENDIF}
{$ENDIF}




var
 {$IFDEF USE_SYN_EDIT}
  SynSQLSyn1: TSynSQLSyn;
  memSQL      :TSynMemo;
  memInsertSQL:TSynMemo;
  memUpdateSQL:TSynMemo;
  memDeleteSQL:TSynMemo;
  memRefreshSQL:TSynMemo;
 {$ELSE}
  memSQL      :TMemo;
  memInsertSQL:TMemo;
  memUpdateSQL:TMemo;
  memDeleteSQL:TMemo;
  memRefreshSQL:TMemo;
 {$ENDIF}

  CurrentComponent:TComponent;

{$IFDEF D9+}
{$REGION 'Notificator code'}
{$ENDIF}
type
     TNotificator=class (TComponent,IOTAIDENotifier)
     private
      procedure FileNotification(NotifyCode: TOTAFileNotification;
        const FileName: string; var Cancel: Boolean);
      procedure AfterSave;
      procedure BeforeSave;
      procedure Destroyed;
      procedure Modified;
      procedure BeforeCompile(const Project: IOTAProject; var Cancel: Boolean);overload;
      procedure AfterCompile(Succeeded: Boolean); overload;
     public
      destructor Destroy; override;
     end;

      destructor TNotificator.Destroy;
      begin
       inherited Destroy;
      end;

      procedure TNotificator.BeforeCompile(const Project: IOTAProject; var Cancel: Boolean);
      begin
      end;

      procedure TNotificator.AfterCompile(Succeeded: Boolean);
      begin
      end;

      procedure TNotificator.AfterSave;
      begin
      end;
      procedure TNotificator.BeforeSave;
      begin
      end;

      procedure TNotificator.Destroyed;
      begin
      end;

      procedure TNotificator.Modified;
      begin
      end;

      procedure TNotificator.FileNotification(NotifyCode: TOTAFileNotification;
        const FileName: string; var Cancel: Boolean);
      var
         i:integer;
         j:integer;
      begin
        if NotifyCode=ofnFileClosing then
        if Assigned(frmSaveSQLs) then
        with frmSaveSQLs do
        begin
          i:=0;
          while i<Length(FUnits) do
          begin
            if FUnits[i]=FileName then
            begin
              if lstForms.ItemIndex=i then
              begin
                lstQueries.Items.Clear;
                ClearSQLs
              end;
              lstForms.Items.Objects[i].Free;
              lstForms.Items.Delete(i);
              if lstForms.ItemIndex=i then
              begin
                ClearSQLs;
                lstFormsEnter(lstForms);
              end;
              for j:=i+1 to Length(FUnits)-1 do
               FUnits[j-1]:=FUnits[j];
              SetLength(FUnits,Length(FUnits)-1);
              Exit;
            end;
            Inc(i);
          end;
        end;
      end;


var  Notificator:TNotificator;
{$IFDEF D9+}
{$ENDREGION }
{$ENDIF}
procedure  ShowAllSQLs;
begin
 if not Assigned(frmSaveSQLs) then
  frmSaveSQLs:= TfrmSaveSQLs.Create(nil);
 with frmSaveSQLs do
 begin
    vProjectName:=GetActiveProjectShortName;
    Caption:=Caption+' :'+vProjectName;
    OI :=GetOI;
    FormStyle:=fsStayOnTop;
    if WindowState=wsMinimized then
     WindowState:=wsNormal;
    Show;
 end;
end;

function ExistCheckedItems(CheckListBox:TCheckListBox):boolean;
var i:integer;
begin
 Result:=false;
 with CheckListBox do
  for i:=0 to Pred(Items.Count) do begin
   Result:= Checked[i];
   if Result then Exit;
  end;
end;

constructor TFIBSQLOwner.Create(aFIBSQLOwner:TComponent);
begin
 vFIBSQLOwner:=aFIBSQLOwner;
 vChecked    :=false;
end;


function TFIBSQLOwner.GetCustomForm:TCustomForm;
var tmpCmp:TComponent;
begin
 Result:=nil;
 tmpCmp:=vFIBSQLOwner;
 while (tmpCmp.Owner<>nil) and not (tmpCmp is TCustomForm) do
  tmpCmp:=tmpCmp.Owner;
 if tmpCmp is TCustomForm then
  Result:=TCustomForm(tmpCmp);
end;


procedure TFIBSQLOwner.SetProp(const PropName: string; Value: TStrings);
var
 Form:TCustomForm;
begin
 if vFIBSQLOwner is TFIBDataSet then
 with TFIBDataSet(vFIBSQLOwner) do
 begin
  if (PropName='SQL') or (PropName='SelectSQL') then
   SelectSQL.Assign(Value)
  else
  if (PropName='InsertSQL') then
   InsertSQL.Assign(Value)
  else
  if (PropName='UpdateSQL') then
   UpdateSQL.Assign(Value)
  else
  if (PropName='DeleteSQL') then
   DeleteSQL.Assign(Value)
  else
  if (PropName='RefreshSQL') then
   RefreshSQL.Assign(Value);
 end
 else
 if vFIBSQLOwner is TFIBQuery then
 with TFIBQuery(vFIBSQLOwner) do
 begin
  if (PropName='SQL') or (PropName='SelectSQL') then
   SQL.Assign(Value)
 end
{$IFDEF SQL_NAVIGATOR_SUPPORT_BDE}
 else
 if vFIBSQLOwner is TQuery then
 with  TQuery(vFIBSQLOwner) do
 begin
  if (PropName='SQL') or (PropName='SelectSQL') then
   SQL.Assign(Value)
 end
 else
 if vFIBSQLOwner is TUpdateSql then
 with TUpdateSql(vFIBSQLOwner) do
 begin
  if (PropName='InsertSQL') then
   InsertSQL.Assign(Value)
  else
  if (PropName='UpdateSQL') then
   ModifySQL.Assign(Value)
  else
  if (PropName='DeleteSQL') then
   DeleteSQL.Assign(Value);
 end
{$ENDIF}
;
  Form:=GetCustomForm;
  if Form<>nil then
    Form.Designer.Modified;
end;

type
     TFakeCmp =class(TComponent)
     protected
      procedure Notification(AComponent: TComponent; Operation: TOperation);override;
     end;


procedure TFakeCmp.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if Operation =opRemove then
   if AComponent=CurrentComponent then CurrentComponent:=nil;
  inherited Notification(AComponent,Operation)
end;

var FakeCmp:TFakeCmp;

{ TfrmSaveSQLs }

destructor TfrmSaveSQLs.Destroy;
begin
  ClearForms;
  FListOfOpenedForms.Free;
  FListOfOpenedForms:=nil;
  FSearchResult.Free;
  FSearchResult:=nil;  
  inherited Destroy;
end;

procedure TfrmSaveSQLs.GetForms;
var i,j,k:integer;
    UnName:string;
    Found :boolean;
{$IFDEF D6+}
    tmpCmp:TComponent;
{$ENDIF}

function IsValidFrame(Frame:TFrame) :boolean;
var k:integer;
begin
  Result := False;
  with Frame do
   for k:=0 to Pred(ComponentCount) do
   begin
      if (Components[k] is TFIBQuery) or
        (Components[k] is TFIBCustomDataSet)
{$IFDEF SQL_NAVIGATOR_SUPPORT_BDE}
     or (Components[k] is TQuery)
     or (Components[k] is TUpdateSQL)
{$ENDIF}

      then
      begin
        Result := True;
        Break;
      end
      else
      if Components[k] is TFrame then
      begin
        Result:=IsValidFrame(TFrame(Components[k]));
        if Result then
          Break
      end;
   end;
end;

begin
 ClearForms;
 with Screen do
 for i:=Pred(CustomFormCount) downto 0 do
 begin

  if not (csDesigning in CustomForms[i].ComponentState) then
   Continue;
  with CustomForms[i] do
   begin
    UnName:=GetUnitName(CustomForms[i]);
    Found :=false;
    if UnitInProject(UnName) then
    for j:=0 to Pred(ComponentCount) do
{$IFNDEF D6+}
     if Pos('TDataModule',Components[j].ClassName)=1 then
     begin
       Found :=True; Break;
     end
     else
{$ENDIF}
     if (Components[j] is TFIBQuery) or
      (Components[j] is TFIBCustomDataSet)
{$IFDEF SQL_NAVIGATOR_SUPPORT_BDE}
     or (Components[j] is TQuery)
     or (Components[j] is TUpdateSQL)
{$ENDIF}
     then
     begin
       RegisterModule(CustomForms[i],UnName);
       Found :=True;
       Break;
     end
{$IFDEF D5+}
     else
     if Components[j] is TFrame then
     begin
      if IsValidFrame(TFrame(Components[j])) then
      begin
        RegisterModule(Components[j],UnName);
        Found :=True;
      end;
(*      tmpCmp:=Components[j];
      with tmpCmp do
      for k:=0 to Pred(ComponentCount) do
      if (Components[k] is TFIBQuery) or
        (Components[k] is TFIBCustomDataSet)
{$IFDEF SQL_NAVIGATOR_SUPPORT_BDE}
     or (Components[k] is TQuery)
     or (Components[k] is TUpdateSQL)
{$ENDIF}

      then
      begin
        RegisterModule(tmpCmp,UnName);
        Found :=True;
        Break;
      end *)
     end
{$IFDEF D6+}
     else
      if (ClassName='TDataModuleForm')  then
      begin
       tmpCmp:=Components[1];
       if (Components[j] is TDataModule) then
       with Components[j] do
        for k:=0 to Pred(ComponentCount) do
        if (Components[k] is TFIBQuery) or
        (Components[k] is TFIBCustomDataSet)
{$IFDEF SQL_NAVIGATOR_SUPPORT_BDE}
        or (Components[k] is TQuery)
        or (Components[k] is TUpdateSQL)
{$ENDIF}
        then
        begin
          RegisterModule(tmpCmp,UnName);
          Found :=True;
          Break;
        end
      end;
{$ENDIF}

{$ENDIF}
;
     if not Found then
     begin
      if FListOfOpenedForms.Find(UnName,k) then
      begin
       CloseUnFile(UnName);
       FListOfOpenedForms.Delete(k)
      end;
     end;
   end
 end;
 with Screen do
 for i:=Pred(DataModuleCount)  downto 0 do
 begin
  if not (csDesigning in DataModules[i].ComponentState) then Continue;
  UnName:=GetUnitName(DataModules[i]);
  Found :=false;
  if UnitInProject(UnName) then
  with DataModules[i] do
  for j:=0 to Pred(ComponentCount) do
   if (Components[j] is TFIBQuery) or
    (Components[j] is TFIBCustomDataSet)
{$IFDEF SQL_NAVIGATOR_SUPPORT_BDE}
     or (Components[j] is TQuery)
     or (Components[j] is TUpdateSQL)
{$ENDIF}

   then
   begin
     RegisterModule(DataModules[i],UnName);
     Found :=True;
     Break;
   end;// end if for


  if not Found then
  if FListOfOpenedForms.Find(UnName,k) then
  begin
     CloseUnFile(UnName);
     FListOfOpenedForms.Delete(k)
  end;
 end;

end;


procedure TfrmSaveSQLs.RegisterModule(Module: TComponent; const UnName:string);
var i:integer;
    ts:TStringList;

procedure DoRegister(Owner:TComponent);
var k:integer;
begin
  with Owner do
  for k:=0 to Pred(ComponentCount) do
   if (Components[k] is TFIBQuery) or
    (Components[k] is TFIBCustomDataSet)
{$IFDEF SQL_NAVIGATOR_SUPPORT_BDE}
     or (Components[k] is TQuery)
     or (Components[k] is TUpdateSQL)
{$ENDIF}

   then
   begin
    ts.AddObject(Components[k].Name+'  '+
    '('+Components[k].ClassName+')',
     TFIBSQLOwner.Create(Components[k])
    )
   end
   else
   if Components[k] is TFrame then
   begin
    DoRegister(TFrame(Components[k]));
   end;
end;

begin
 ts:=TStringList.Create;
 ts.Sorted:=True;
 ts.Duplicates:=dupIgnore;
 DoRegister(Module);
 i:= lstForms.Items.AddObject(Module.Name+'  '+
   '('+Module.ClassName+')',ts);
 if i>=Length(FUnits) then
  SetLength(FUnits,i+1);
 FUnits[i]:=UnName;
end;

function TfrmSaveSQLs.GetCurrentSQLOwner:TFIBSQLOwner;
begin
 Result:=nil;
 if (lstQueries.ItemIndex=-1) or (lstQueries.Items.Count<=0) then
  Exit;
 if lstForms.Items.Count>0 then
  Result:=TFIBSQLOwner(
         TStrings(lstForms.Items.Objects[lstForms.ItemIndex]).
          Objects[lstQueries.ItemIndex]
         );

end;

function GetFormDesigner(cmp:TComponent):
{$IFNDEF D6+}
TFormDesigner;
{$ELSE}
 IDesignerHook;
{$ENDIF}
var     DsgnForm   :TForm;
begin

  if cmp is TForm then
    DsgnForm:=TForm(cmp)
  else
  if cmp.Owner is TForm then
    DsgnForm:=TForm(cmp.Owner)
  else
   if cmp.Owner.Owner is TForm then
    DsgnForm:=TForm(cmp.Owner.Owner)
   else
   if cmp.Owner.Owner.Owner is TForm then
    DsgnForm:=TForm(cmp.Owner.Owner.Owner)
   else
    raise Exception.Create('Can''t... Sorry');
  {$IFNDEF D6+}
    Result:=TFormDesigner(DsgnForm.Designer)
  {$ELSE}
    Result:=DsgnForm.Designer
  {$ENDIF}

end;

var InEnter:boolean;

procedure TfrmSaveSQLs.FillQueryList;
var i:integer;
begin
 if InEnter then begin
  InEnter:=false;
  Exit;
 end;

 lstQueries.Clear;
 if lstForms.ItemIndex>-1 then
  lstQueries.Items.AddStrings(
   TStrings(lstForms.Items.Objects[lstForms.ItemIndex])
  );
 for i:=0 to Pred(lstQueries.Items.Count) do
 begin
  lstQueries.Checked[i]:=
  TFIBSQLOwner(
   TStrings(lstForms.Items.Objects[lstForms.ItemIndex]).
   Objects[i]
  ).vChecked;
 end;
end;


procedure TfrmSaveSQLs.lstFormsEnter(Sender: TObject);
begin
 FillQueryList;
 lstQueries.ItemIndex:=0;
 lstQueriesEnter(lstForms);
end;

procedure TfrmSaveSQLs.lstQueriesClickCheck(Sender: TObject);
begin
 SetQueryCheck(lstQueries.ItemIndex);
 if lstQueries.Checked[lstQueries.ItemIndex] then
  lstForms.Checked[lstForms.ItemIndex]:=True
 else
 if not ExistCheckedItems(lstQueries) then
  lstForms.Checked[lstForms.ItemIndex]:=false
end;


procedure TfrmSaveSQLs.ClearForms;
var
 i,j:integer;
begin
 with lstForms.Items do
 for i:=0 to Pred(Count) do
 begin
  for j:=0 to Pred(TStrings(Objects[i]).Count) do
   TStrings(Objects[i]).Objects[j].Free;
  Objects[i].Free;
 end;
 lstForms.Items.Clear;
 lstQueries.Items.Clear;
 ClearSQLs;
 SetLength(FUnits,0);
end;

procedure TfrmSaveSQLs.ClearSQLs;
begin
 memSQL.Lines.Clear;
 memInsertSQL.Lines.Clear;
 memUpdateSQL.Lines.Clear;
 memDeleteSQL.Lines.Clear;
 memRefreshSQL.Lines.Clear;
end;

procedure TfrmSaveSQLs.FormClose(Sender: TObject;
  var Action: TCloseAction);
var
  FIBSQLOwner:TFIBSQLOwner;
begin
 {$IFNDEF USE_SYN_EDIT}
  if ActiveControl is TMemo then
 {$ELSE}
   if ActiveControl is TSynMemo then
 {$ENDIF}
    MemoExit(ActiveControl);

 FIBSQLOwner:=GetCurrentSQLOwner;
 if FIBSQLOwner<>nil then
 begin
  CurrentComponent:=FIBSQLOwner.vFIBSQLOwner;
  FakeCmp.FreeNotification(CurrentComponent);
 end;
 ClearSearch;
 ClearForms;
end;

procedure TfrmSaveSQLs.lstFormsClickCheck(Sender: TObject);
begin
  SetModuleCheck(lstForms.ItemIndex);
  lstFormsEnter(lstForms)
end;



procedure TfrmSaveSQLs.lstQueriesEnter(Sender: TObject);
var FIBSQLOwner:TFIBSQLOwner;
begin
{
if InEnter then begin
 InEnter:=false;
 Exit;
end;
}
FIBSQLOwner:=GetCurrentSQLOwner;
if FIBSQLOwner=nil then
 Exit;
with FIBSQLOwner do
begin
 TabSQL.TabVisible:=True;
 TabInsertSQL.TabVisible:=vFIBSQLOwner is TFIBCustomDataSet;
 TabDeleteSQL.TabVisible:=vFIBSQLOwner is TFIBCustomDataSet;
 TabUpdateSQL.TabVisible:=vFIBSQLOwner is TFIBCustomDataSet;
 TabRefreshSQL.TabVisible:=vFIBSQLOwner is TFIBCustomDataSet;
// TabSheet5.TabVisible:=vFIBSQLOwner is TFIBCustomDataSet;
 if vFIBSQLOwner is TFIBQuery then
 begin
  TabSQL.Caption:='SQL';
  MemSQL.Text:=TFIBQuery(vFIBSQLOwner).SQL.Text;
 end
 else
 if vFIBSQLOwner is TFIBCustomDataSet then
 begin
  TabSQL.Caption:='SelectSQL';
  MemSQL.Text:=TFIBDataSet(vFIBSQLOwner).SelectSQL.Text;
  MemInsertSQL.Text :=TFIBDataSet(vFIBSQLOwner).InsertSQL.Text;
  MemUpdateSQL.Text :=TFIBDataSet(vFIBSQLOwner).UpdateSQL.Text;
  MemDeleteSQL.Text :=TFIBDataSet(vFIBSQLOwner).DeleteSQL.Text;
  MemRefreshSQL.Text:=TFIBDataSet(vFIBSQLOwner).RefreshSQL.Text;

    memSQL       .Modified:=false;
    memInsertSQL .Modified:=false;
    memUpdateSQL .Modified:=false;
    memDeleteSQL .Modified:=false;
    memRefreshSQL.Modified:=false;

 end
{$IFDEF SQL_NAVIGATOR_SUPPORT_BDE}
 else
  if vFIBSQLOwner is TQuery then
  begin
   TabSQL.Caption:='SQL';
   MemSQL.Text:=TQuery(vFIBSQLOwner).SQL.Text;

   memSQL       .Modified:=false;

  end
  else
  if vFIBSQLOwner is TUpdateSQL then
  begin
   TabSQL.Caption:='SQL';
//   MemSQL.Clear;
   TabSQL.TabVisible:=false;
   TabInsertSQL.TabVisible:=True;
   TabDeleteSQL.TabVisible:=True;
   TabUpdateSQL.TabVisible:=True;


   MemInsertSQL.Text :=TUpdateSQL(vFIBSQLOwner).InsertSQL.Text;
   MemUpdateSQL.Text :=TUpdateSQL(vFIBSQLOwner).ModifySQL.Text;
   MemDeleteSQL.Text :=TUpdateSQL(vFIBSQLOwner).DeleteSQL.Text;

   memInsertSQL .Modified:=false;
   memUpdateSQL .Modified:=false;
   memDeleteSQL .Modified:=false;
   memRefreshSQL.Modified:=false;
  end

{$ENDIF}

end;
if (OI<>nil)  and OI.Enabled and OI.Visible
then
begin
 InEnter:=lstQueries=ActiveControl;
 GotocurrentComponent1Click(nil);
 TWinControl(Sender).SetFocus
end;

end;

procedure TfrmSaveSQLs.SelectAll1Click(Sender: TObject);
var i:integer;
begin
 with TCheckListBox(PopupMenu1.PopupComponent) do begin
  for i:=0 to Pred(Items.Count) do begin
   Checked[i]:=Sender=SelectAll1;
   if PopupMenu1.PopupComponent=lstQueries then
    SetQueryCheck(i)
   else
    SetModuleCheck(i)
  end;
  if PopupMenu1.PopupComponent=lstQueries then
   lstForms.Checked[lstForms.ItemIndex]:=Sender=SelectAll1
  else
   lstFormsEnter(lstForms)
 end;
end;

procedure TfrmSaveSQLs.SetQueryCheck(Index: integer);
begin
 TFIBSQLOwner(
  TStrings(lstForms.Items.Objects[lstForms.ItemIndex]).
   Objects[Index]).vChecked:=
    lstQueries.Checked[Index];
end;

procedure TfrmSaveSQLs.SetModuleCheck(Index: integer);
var i:integer;
   ch:boolean;
begin
  with lstForms do
  begin
   ch:= Checked[Index];
   with TStrings(Items.Objects[Index])
   do
    for i:= 0 to Pred(Count) do
      TFIBSQLOwner(Objects[i]).vChecked:=ch;
  end;
end;

procedure TfrmSaveSQLs.ScanSelObjects(Operation:TOperationOnSQLText);
var F:TextFile;
    i,j:integer;
    ErrMsg:TStrings;
    AnalyzeResult:TStrings;
//    im:TIModuleInterface;
begin
 if Operation in [oSaveSQL,oAnalyzeSQL] then
 begin
  if SaveDialog1.Execute then
  begin
   AssignFile(F,SaveDialog1.FileName);
   Rewrite(F);
   Writeln(F,'Project  - "'+ GetActiveProjectName+'"');
  end
  else
   Exit;
 end;

   Screen.Cursor:=crHourGlass;
   AnalyzeResult:=TStringList.Create;
   try
    with lstForms do
    for i:=0 to Pred(Items.Count) do
     if Checked[i] then
     begin
     with TStrings(Items.Objects[i]) do
     for j:= 0 to Pred(Count) do
      with  TFIBSQLOwner(Objects[j]) do
      if vChecked then
      case Operation of
      oSaveSQL:
       begin
         Writeln(F,'Unit - "'+ GetUnitName(vFIBSQLOwner)+'"');
         StatusBar1.Panels[0].Text:='Saving SQL for '+
          vFIBSQLOwner.Owner.Name+'.'+vFIBSQLOwner.Name;
         Writeln(F,'Component - '+ vFIBSQLOwner.Owner.Name+'.'+
          vFIBSQLOwner.Name+':'+vFIBSQLOwner.Owner.ClassName);
         SaveFIBSQLOwner(F,vFIBSQLOwner);
       end;
      oCheckSQL:
       begin
         StatusBar1.Panels[0].Text:='Check SQL for '+
          vFIBSQLOwner.Owner.Name+'.'+vFIBSQLOwner.Name;
         if CheckSQL(vFIBSQLOwner) in [1,2] then
         begin
          ErrMsg:=TStringList.Create;
          ErrMsg.Text:='Can''t connect to base';
          ListBox1.Items.AddObject(
            'Error in:'+  vFIBSQLOwner.Owner.Name+'.'+vFIBSQLOwner.Name,
           ErrMsg
          );
         end;
       end;
       oAnalyzeSQL:
       begin
         StatusBar1.Panels[0].Text:='Analyze SQL for '+
          vFIBSQLOwner.Owner.Name+'.'+vFIBSQLOwner.Name;

         Writeln(F,'Unit     - "'+ GetUnitName(vFIBSQLOwner)+'"');
         Writeln(F,'Component- ' + vFIBSQLOwner.Owner.Name+'.'+
          vFIBSQLOwner.Name+':'  + vFIBSQLOwner.Owner.ClassName);

         Analyze(vFIBSQLOwner,AnalyzeResult,F);
         Writeln(F,'');         
       end;
      end;
      Application.ProcessMessages;
     end;
   finally
    AnalyzeResult.Free;
    Screen.Cursor:=crDefault;
    if Operation in [oSaveSQL,oAnalyzeSQL] then
     CloseFile(F);
    StatusBar1.Panels[0].Text:=''
   end;
end;

function  TfrmSaveSQLs.CheckSQL(aFIBSQLOwner:TComponent):integer;
var
    DPB:TStrings;
    
procedure CheckSQLText(SQLText:TStrings;const SQLName: string);
var ErrMsg:TStrings;
begin
      if SQLText.Count=0 then Exit;
       qryCheck.SQL.Assign(SQLText);
       try
        qryCheck.Prepare;
       except
         On E: Exception do
         begin
          ErrMsg:=TStringList.Create;
          ErrMsg.Text:=E.Message;
          ListBox1.Items.AddObject(
           'Error in:'+
            aFIBSQLOwner.Owner.Name+'.'+aFIBSQLOwner.Name+'.'+
             SQLName
            ,
           ErrMsg
          );
          Result:=3;
         end;
       end;
end;

begin
  Result:=1; //Не ассигнован ДбНаме

  DPB :=TStringList.Create;
  try
    GetDBParams(aFIBSQLOwner,DPB);
    Connect(DPB);
    with pFIBDatabase1 do
    begin
        if aFIBSQLOwner is TFIBQuery then
         CheckSQLText(TFIBQuery(aFIBSQLOwner).SQL,'SQL')
        else
        if aFIBSQLOwner is TFIBDataSet then
        begin
         CheckSQLText(TFIBDataSet(aFIBSQLOwner).SelectSQL, 'SelectSQL');
         CheckSQLText(TFIBDataSet(aFIBSQLOwner).InsertSQL, 'InsertSQL');
         CheckSQLText(TFIBDataSet(aFIBSQLOwner).RefreshSQL,'RefreshSQL');
         CheckSQLText(TFIBDataSet(aFIBSQLOwner).DeleteSQL, 'DeleteSQL');
         CheckSQLText(TFIBDataSet(aFIBSQLOwner).UpdateSQL, 'UpdateSQL');
        end
       {$IFDEF SQL_NAVIGATOR_SUPPORT_BDE}
        else
        if aFIBSQLOwner is TQuery then
        begin
         CheckSQLText(TQuery(aFIBSQLOwner).SQL,'SQL');
        end
        else
        if aFIBSQLOwner is TUpdateSQL then
        begin
         CheckSQLText(TUpdateSQL(aFIBSQLOwner).InsertSQL , 'InsertSQL');
         CheckSQLText(TUpdateSQL(aFIBSQLOwner).DeleteSQL , 'DeleteSQL');
         CheckSQLText(TUpdateSQL(aFIBSQLOwner).ModifySQL , 'UpdateSQL');
        end

       {$ENDIF}
        ;Result:=0
    end;
  finally
   DPB.Free
  end
end;

procedure TfrmSaveSQLs.SaveFIBSQLOwner(var F: Text;
  aFIBSQLOwner: TComponent);
var i:integer;
begin
  Writeln(f);
  if aFIBSQLOwner is TFIBQuery then
  begin
   with TFIBQuery(aFIBSQLOwner),TFIBQuery(aFIBSQLOwner).SQL do
   if Trim(SQL.Text)<>'' then
   begin
    Writeln(f,'/*SQL*/');
    for i:=0 to Pred(Count) do
     Writeln(f,Strings[i]);
    Writeln(f,';');
   end
  end
  else
   if aFIBSQLOwner is TFIBDataSet then
   with TFIBDataSet(aFIBSQLOwner) do
   begin
    if Trim(SelectSQL.Text)<>'' then
    begin
     Writeln(f,'/*SelectSQL*/');
     with SelectSQL do
      for i:=0 to Pred(Count) do
       Writeln(f,Strings[i]);
     Writeln(f,';');
    end;
    if not vFullSave then
    begin
     Writeln(f);     Exit;
    end;
    if Trim(InsertSQL.Text)<>'' then
    begin
     Writeln(f,'/*InsertSQL*/');
     with InsertSQL do
      for i:=0 to Pred(Count) do
       Writeln(f,Strings[i]);
     Writeln(f,';');
    end;
    if Trim(UpdateSQL.Text)<>'' then
    begin
     Writeln(f,'/*UpdateSQL*/');
     with UpdateSQL do
      for i:=0 to Pred(Count) do
       Writeln(f,Strings[i]);
     Writeln(f,';');
    end;
    if Trim(DeleteSQL.Text)<>'' then
    begin
     Writeln(f,'/*DeleteSQL*/');
     with DeleteSQL do
      for i:=0 to Pred(Count) do
      Writeln(f,Strings[i]);
     Writeln(f,';');
    end;
    if Trim(RefreshSQL.Text)<>'' then
    begin
     Writeln(f,'/*RefreshSQL*/');
     with RefreshSQL do
      for i:=0 to Pred(Count) do
       Writeln(f,Strings[i]);
     Writeln(f,';');
    end;
   end
  {$IFDEF SQL_NAVIGATOR_SUPPORT_BDE}
   else
   if aFIBSQLOwner is TQuery then
   begin
    with TQuery(aFIBSQLOwner),TQuery(aFIBSQLOwner).SQL do
    if Trim(SQL.Text)<>'' then
    begin
    Writeln(f,'/*SQL*/');
    for i:=0 to Pred(Count) do
     Writeln(f,Strings[i]);
     Writeln(f,';');
    end
   end
   else
   if aFIBSQLOwner is TUpdateSQL then
   with TUpdateSQL(aFIBSQLOwner) do
   begin
    if not vFullSave then
    begin
     Writeln(f);     Exit;
    end;
    if Trim(InsertSQL.Text)<>'' then
    begin
     Writeln(f,'/*InsertSQL*/');
     with InsertSQL do
      for i:=0 to Pred(Count) do
       Writeln(f,Strings[i]);
     Writeln(f,';');
    end;
    if Trim(ModifySQL.Text)<>'' then
    begin
     Writeln(f,'/*ModifySQL*/');
     with ModifySQL do
      for i:=0 to Pred(Count) do
       Writeln(f,Strings[i]);
     Writeln(f,';');
    end;
    if Trim(DeleteSQL.Text)<>'' then
    begin
     Writeln(f,'/*DeleteSQL*/');
     with DeleteSQL do
      for i:=0 to Pred(Count) do
      Writeln(f,Strings[i]);
     Writeln(f,';');
    end;
   end
  {$ENDIF}
   ;
   Writeln(f);
end;

procedure TfrmSaveSQLs.FormCreate(Sender: TObject);
begin

  Caption := FPTNavCaption;
  btnGetForms.Hint := FPTNavGetFormsButtonHint;
  ToolButton5.Hint := FPTNavCloseFormsButtonHint;
  ToolButton1.Hint := FPTNavSaveSQLButtonHint;
  ToolButton3.Hint := FPTNavFindButtonHint;
  ToolButton2.Hint := FPTNavCheckButtonHint;
  ToolButton8.Hint := FPTNavSaveCallsHint;
  ToolButton4.Hint := FPTNavHideSearchButtonHint;
  ToolButton7.Hint := FPTNavShowOIButtonHint;
  GrSearch.Caption := FPTNavSearchResults;
  SelectAll1.Caption := FPTNavSelectAllItem;
  Unselectall1.Caption := FPTNavUnselectAllItem;
  GotocurrentComponent1.Caption :=  FPTNavGotoCurrentItem;
  ShowSearchResult1.Caption := FPTNavShowResultsItem;
  HideSearchResult1.Caption := FPTNavHideResultsItem;
  CopytoClipboard1.Caption := FPTNavCopyToClipboardItem;
  miSaveallSQLs1.Caption := FPTNavSaveAllItem;
  SaveonlySelectSQL1.Caption := FPTNavSaveSelectSQlItem;



 FListOfOpenedForms:=TStringList.Create;


 with FListOfOpenedForms do
 begin
      Sorted:=True;
      Duplicates:=dupIgnore;
 end;  // with

   visible:=false;
   WindowList:=nil;
   {$IFDEF USE_SYN_EDIT}
    SynSQLSyn1 :=TSynSQLSyn.Create(Self);
    with SynSQLSyn1 do begin
      DefaultFilter:= FPTNavSQLFilter;
      CommentAttri.Foreground := clBlue;
      NumberAttri.Foreground  := clRed ;
      StringAttri.Background  := clInactiveBorder;
      SQLDialect              := sqlInterbase6;
    end;
    memSQL       :=TSynMemo.Create(Self);
    memInsertSQL :=TSynMemo.Create(Self);
    memUpdateSQL :=TSynMemo.Create(Self);
    memDeleteSQL :=TSynMemo.Create(Self);
    memRefreshSQL:=TSynMemo.Create(Self);
    memSQL.      Highlighter:=SynSQLSyn1;
    memInsertSQL.Highlighter:=SynSQLSyn1;
    memUpdateSQL.Highlighter:=SynSQLSyn1;
    memDeleteSQL.Highlighter:=SynSQLSyn1;
    memRefreshSQL.Highlighter:=SynSQLSyn1;
   {$ELSE}
    memSQL       :=TMemo.Create (Self);
    memInsertSQL :=TMemo.Create (Self);
    memUpdateSQL :=TMemo.Create(Self);
    memDeleteSQL :=TMemo.Create(Self);
    memRefreshSQL:=TMemo.Create(Self);
    memSQL       .ScrollBars:=ssBoth;
    memInsertSQL .ScrollBars:=ssBoth;
    memUpdateSQL .ScrollBars:=ssBoth;
    memDeleteSQL .ScrollBars:=ssBoth;
    memRefreshSQL.ScrollBars:=ssBoth;

   {$ENDIF}
    memSQL.Parent:=TabSQL;
    memSQL.Align :=alClient;
    memInsertSQL.Parent:=TabInsertSQL;
    memInsertSQL.Align :=alClient;
    memUpdateSQL.Parent:=TabUpdateSQL;
    memUpdateSQL.Align :=alClient;
    memDeleteSQL.Parent:=TabDeleteSQL;
    memDeleteSQL.Align :=alClient;
    memRefreshSQL.Parent:=TabRefreshSQL;
    memRefreshSQL.Align :=alClient;

    memSQL       .Modified:=false;
    memInsertSQL .Modified:=false;
    memUpdateSQL .Modified:=false;
    memDeleteSQL .Modified:=false;
    memRefreshSQL.Modified:=false;

    memSQL       .OnExit:=MemoExit;
    memInsertSQL .OnExit:=MemoExit;
    memUpdateSQL .OnExit:=MemoExit;
    memDeleteSQL .OnExit:=MemoExit;
    memRefreshSQL.OnExit:=MemoExit;

    memSQL       .OnEnter:=MemoEnter;
    memInsertSQL .OnEnter:=MemoEnter;
    memUpdateSQL .OnEnter:=MemoEnter;
    memDeleteSQL .OnEnter:=MemoEnter;
    memRefreshSQL.OnEnter:=MemoEnter;
 
 FSearchResult:=TStringList.Create;

end;

procedure TfrmSaveSQLs.SpeedButton1Click(Sender: TObject);
begin
 FindDialog1.Execute
end;

function TfrmSaveSQLs.SearchContext(const Value: string): boolean;
var
    i,j:integer;
begin
   Result:=false;
   Screen.Cursor:=crHourGlass;
   try
    with lstForms do
    for i:=0 to Pred(Items.Count) do
     with TStrings(Items.Objects[i]) do
     for j:= 0 to Pred(Count) do
      with  TFIBSQLOwner(Objects[j]) do
       Result:=FindInCmp(vFIBSQLOwner,Value) or Result
   finally
    Screen.Cursor:=crDefault;
   end;
   SetSearchResVisible(Result);
   ClearSearch;
   if Result then begin
    ListBox1.Items.AddStrings(FSearchResult);
    FSearchResult.Clear
   end;
   FindDialog1.CloseDialog;
end;

procedure TfrmSaveSQLs.FocusToComponent(cmp:TComponent);
var
 i,j:integer;
begin
 with lstForms.Items do
  for i:=0 to Pred(Count) do
  with TStrings(lstForms.Items.Objects[i]) do
   for j:=0 to Pred(Count) do begin
    if cmp=TFIBSQLOwner(Objects[j]).vFIBSQLOwner
    then begin
     lstForms.ItemIndex  :=i;
     FillQueryList;
     lstQueries.ItemIndex:=j;
     lstQueriesEnter(lstQueries);
     Exit;
    end;
   end;
end;

procedure TfrmSaveSQLs.ClearSearch;
var i:integer;
begin
   with ListBox1.Items do begin
    for i:=0 to Pred(Count) do
     if Objects[i]<>nil then Objects[i].Free;
    Clear;
   end;
end;

function TfrmSaveSQLs.FindInCmp(cmp: TComponent;
  const Value: string): boolean;
var F:boolean;
 function PosX(Substr: string; S: string):integer;
 begin
  if frMatchCase in FindDialog1.Options then
   if frWholeWord in FindDialog1.Options then
    Result:=PosExt(Substr,S,[' ',#13,#10,')','(',',','.'],
     [' ',#13,#10,')','(',',','.']
    )
   else
    Result:=Pos(Substr,S)
  else
   if frWholeWord in FindDialog1.Options then
    Result:=PosExtCI(Substr,S,[' ',#13,#10,')','(',',','.'],
     [' ',#13,#10,')','(',',','.']
    )
   else
    Result:=PosCI(Substr,S)
 end;
begin
 Result:=false;
 if cmp is TFIBQuery then
 begin
  Result:=PosX(Value,TFIBQuery(cmp).SQL.Text)>0;
  if Result then FSearchResult.Add(cmp.Owner.Name+'.'+cmp.Name+'.SQL');
  Exit;
 end;
{$IFDEF SQL_NAVIGATOR_SUPPORT_BDE}
 if cmp is TQuery then
 begin
  Result:=PosX(Value,TQuery(cmp).SQL.Text)>0;
  if Result then FSearchResult.Add(cmp.Owner.Name+'.'+cmp.Name+'.SQL');
  Exit;
 end;
 if cmp is TUpdateSQL then
 begin
  Result:=PosX(Value,TUpdateSQL(cmp).InsertSQL.Text)>0;
  if Result then FSearchResult.Add(cmp.Owner.Name+'.'+cmp.Name+'.InsertSQL');
  F:=PosX(Value,TUpdateSQL(cmp).ModifySQL.Text)>0;
  Result:=Result or F;
  if F then FSearchResult.Add(cmp.Owner.Name+'.'+cmp.Name+'.ModifySQL');
  F:=PosX(Value,TUpdateSQL(cmp).DeleteSQL.Text)>0;
  Result:=Result or F;
  if F then FSearchResult.Add(cmp.Owner.Name+'.'+cmp.Name+'.DeleteSQL');
 end;

{$ENDIF}
 if cmp is TFIBDataSet then
 begin
  Result:=PosX(Value,TFIBDataSet(cmp).SelectSQL.Text)>0;
  if Result then FSearchResult.Add(cmp.Owner.Name+'.'+cmp.Name+'.SelectSQL');
  F:=PosX(Value,TFIBDataSet(cmp).InsertSQL.Text)>0;
  Result:=Result or F;
  if F then FSearchResult.Add(cmp.Owner.Name+'.'+cmp.Name+'.InsertSQL');
  F:=PosX(Value,TFIBDataSet(cmp).UpdateSQL.Text)>0;
  Result:=Result or F;
  if F then FSearchResult.Add(cmp.Owner.Name+'.'+cmp.Name+'.UpdateSQL');
  F:=PosX(Value,TFIBDataSet(cmp).DeleteSQL.Text)>0;
  Result:=Result or F;
  if F then FSearchResult.Add(cmp.Owner.Name+'.'+cmp.Name+'.DeleteSQL');
  F:=PosX(Value,TFIBDataSet(cmp).RefreshSQL.Text)>0;
  Result:=Result or F;
  if F then FSearchResult.Add(cmp.Owner.Name+'.'+cmp.Name+'.RefreshSQL');
 end;
end;

procedure TfrmSaveSQLs.FindDialog1Find(Sender: TObject);
begin
  GrSearch.Caption := Format(FPTNavSearchResultCaption, [FindDialog1.FindText]);
  FSearchResult.Clear;
  if not SearchContext(FindDialog1.FindText) then
  {$IFNDEF D9+}
  // Почему-то окно с мессаджем не показывается, дельфа становится недоступной
   ShowMessage(
     Format(FPTNavNotFound, [FindDialog1.FindText])
   );
  {$ENDIF} 
end;

procedure TfrmSaveSQLs.ListBox1DblClick(Sender: TObject);
var s:string;
   bs:string;
   r:integer;

function S1(chLst:TCheckListBox;const SValue:string):integer;
var i,l:integer;
begin
 Result:=-1; l:=Length(SValue);
 with chLst do
 for i:=0 to Pred(Items.Count) do
  if (Items[i][l+1]in [' ',#13]) and (Copy(Items[i],1,l)=SValue) then
  begin
   Result:=i; Exit;
  end;
end;

begin
 if ListBox1.ItemIndex<0 then Exit;
 s:=ListBox1.Items[ListBox1.ItemIndex];
 r:=Pos(':',s) ;
 if r>0 then s:=Trim(Copy(s,r+1,100000));
 bs:=ExtractWord(1,s,['.']);
 r :=S1(lstForms,bs);
 if r<0 then Exit;
 lstForms.ItemIndex:=r;
 lstFormsEnter(lstForms);
 bs:=ExtractWord(2,s,['.']);
 r :=S1(lstQueries,bs);
 if r<0 then Exit;
 lstQueries.ItemIndex:=r;
 lstQueriesEnter(lstQueries);
 bs:=ExtractWord(3,s,['.']);
 if (bs='SelectSQL') or (bs='') then bs:='SQL';
 if (bs='ModifySQL') or (bs='') then bs:='UpdateSQL';
   
 PageControl1.ActivePage:=TTabSheet(FindComponent('Tab'+bs));
 TWinControl(PageControl1.ActivePage.Controls[0]).SetFocus
end;

procedure TfrmSaveSQLs.HideSearchResult1Click(Sender: TObject);
begin
SetSearchResVisible(false)
end;

procedure TfrmSaveSQLs.ShowSearchResult1Click(Sender: TObject);
begin
 SetSearchResVisible(True)
end;

procedure TfrmSaveSQLs.CopytoClipboard1Click(Sender: TObject);
var s:string;
begin
 s:=GrSearch.Caption+#13#10+ListBox1.Items.Text;
 ClipBoard.SetTextBuf(PChar(s))
end;


function GetIOTAModule(const FileName:string):IOTAModule;
var
  Services: IOTAModuleServices;
  I: Integer;
begin
  Result := nil;
  Services := BorlandIDEServices as IOTAModuleServices;
  for I := 0 to Services.ModuleCount - 1 do
  begin
    if Services.Modules[I].FileName=FileName then
    begin
        Result:=Services.Modules[I];
        Break;
    end;
  end;
end;

function GetFormEditor(Module: IOTAModule): IOTAFormEditor;
var
 i: integer;
begin
  Result := nil;
  if not Assigned(Module) then
   Exit;
  for i := 0 to Module.GetModuleFileCount - 1 do
   if Supports(Module.GetModuleFileEditor(i), IOTAFormEditor, Result) then
    break;
end;

function FindIOTAComponent(Root:IOTAComponent; const CmpName:string):IOTAComponent;
var
    i:integer;
    CurName:string;
    CurCmpIntf:IOTAComponent;
begin
   Result := nil;
   for i:=0 to Pred(Root.GetComponentCount) do
   begin
    CurCmpIntf:=Root.GetComponent(i);
    if Assigned(CurCmpIntf) then
    begin
       CurName:='';
       CurCmpIntf.GetPropValueByName('Name',CurName);
       if CurName=CmpName then
       begin
         Result:=CurCmpIntf;
         Break;
       end
       else
       begin
         Result:=FindIOTAComponent(CurCmpIntf,CmpName);
         if Assigned( Result ) then
          Break
       end;
    end;
    CurCmpIntf:=nil
   end;
end;

procedure TfrmSaveSQLs.GotocurrentComponent1Click(Sender: TObject);
var FIBSQLOwner:TFIBSQLOwner;
    cmp        : TComponent;
    DsgnForm   :TForm;
    vUnitName:string;
    io:IOTAModule;
    FormIntf:IOTAFormEditor;
    CmpIntf   :IOTAComponent;
begin
 FIBSQLOwner:=GetCurrentSQLOwner;
 if FIBSQLOwner=nil then
  Exit;
 with FIBSQLOwner do
 begin
  cmp:=vFIBSQLOwner.Owner;
  while assigned(cmp) and not(cmp is TForm) do
    cmp:=cmp.Owner;
  if not assigned(cmp) then
    raise Exception.Create(FPTNavUnableToGoto)
  else
   DsgnForm:=TForm(cmp);

   if Sender =GotocurrentComponent1 then
   begin
    vUnitName:=GetUnitName(DsgnForm);
    io:=nil;
    if vUnitName<>'' then
    begin
      io:=GetIOTAModule(vUnitName);
      try
        if Assigned(io) then
        begin
          FormIntf:=GetFormEditor(io);
          if Assigned(FormIntf) then
          try
           FormIntf.Show;
           CmpIntf:=FormIntf.FindComponent(vFIBSQLOwner.Name);
           if Assigned(CmpIntf) then
           try
             CmpIntf.Select(False);
           finally
             CmpIntf:=nil;
           end
           else
           begin
             CmpIntf:=FindIOTAComponent(FormIntf.GetRootComponent,vFIBSQLOwner.Name);
             if Assigned(CmpIntf) then
             begin
              CmpIntf.Select(False);
              CmpIntf:=nil;
             end;
           end;
          finally
           FormIntf:=nil
          end;
        end;
      finally
       io:=nil
      end;
    end;
   end;


 end;
end;

procedure TfrmSaveSQLs.SpeedButton2Click(Sender: TObject);
begin
 ClearSearch;
 ScanSelObjects(oCheckSQL);
 SetSearchResVisible(ListBox1.Items.Count>0);
end;

function TfrmSaveSQLs.PrepareForms(OnlyLoaded: boolean):boolean;
var
    i,j:integer;
    UNName:string;

    ap:IOTAProject;
    mi:IOTAModuleInfo;
begin
  Result:=false;
(* {$IFNDEF D9+}
  with ToolServices do
  begin
    for i:=Pred(GetUnitCount) downto 0 do
    begin
     UNName:=GetUnitName(i);
     im:=GetModuleInterface(UNName);
     DFMFile:=ChangeFileExt(UNName,'.dfm');
     if (im=nil) and not OnlyLoaded then
     begin
      if FileExists(DFMFile) then
      begin
        Result:=OpenFile(UNName);
        if not Result then
         Continue;
        with FListOfOpenedForms do
        begin
         if not Find(UNName,j) then
          Add(UNName)
        end;  // with
        im:=GetModuleInterface(UNName);
        if im<>nil then
        begin
         if not im.ShowForm then
          CloseFile(UNName)
         else
          im.ShowSource;
         im.Release;
        end;
      end;
     end
     else
     if (im<>nil)  and FileExists(DFMFile)     then
     begin
      if im.GetFormInterface<>nil then
       with im.GetFormInterface do
       begin
        if (GetFormComponent.GetComponentHandle=nil) and not OnlyLoaded  then
        begin
         Result:=True;
         im.ShowForm;
         im.ShowSource;
        end
       end
      else
      if not OnlyLoaded then
      begin
       Result:=True;
       im.ShowForm;
       im.ShowSource;
      end;
      im.Release;
     end;
    end;    // with
  end;
 {$ELSE}*)
     ap:=GetActiveProject;
     if Assigned(ap) then
     begin
      for I := 0 to ap.GetModuleCount - 1 do
      begin
        mi:=aP.GetModule(I);
        UNName:=MI.FormName;
        if  Length(UNName)<>0 then
        begin
          if (GetIOTAModule(MI.FileName)<>nil) or not OnlyLoaded  then
          begin
            if GetIOTAModule(MI.FileName)=nil then
            with FListOfOpenedForms do
            begin
             if not Find(MI.FileName,j) then
              Add(MI.FileName)
            end;
            MI.OpenModule;
          end;
        end;
      end;
     end;
end;


procedure TfrmSaveSQLs.SetSearchResVisible(Value: boolean);
begin
   GrSearch .Visible:=Value;
   Splitter1.Visible:=Value;
   ToolButton4.Enabled:=Value;
   MemErrMess.Visible:= false;
   Splitter4.Visible:=MemErrMess.Visible;
end;

procedure TfrmSaveSQLs.ListBox1Click(Sender: TObject);
begin
   with ListBox1,ListBox1.Items do begin
     if Objects[ItemIndex]<>nil then begin
      MemErrMess.Lines.Assign(TStrings(Objects[ItemIndex]));
      Splitter4 .Visible:=True;
      MemErrMess.Visible:=True;
     end
     else begin
      Splitter4 .Visible:=false;
      MemErrMess.Visible:=false;
     end;
   end;
end;

procedure TfrmSaveSQLs.miSaveallSQLs1Click(Sender: TObject);
begin
 vFullSave:= (Sender=miSaveallSQLs1) or  (Sender=ToolButton1);
 ScanSelObjects(oSaveSQL)
end;


procedure TfrmSaveSQLs.PopupMenu1Popup(Sender: TObject);
begin
 GotocurrentComponent1.Visible:=
  PopupMenu1.PopupComponent= lstQueries
end;

function TfrmSaveSQLs.GetOI:TForm;
var j               : integer;
begin
    Result := nil;
    with Screen do
    for J := 0 to Pred(FormCount) do
     if Forms[j].ClassName = 'TPropertyInspector' then
     begin
      Result := Forms[j];
      Break
     end;
end;

procedure TfrmSaveSQLs.ToolButton7Click(Sender: TObject);
begin
   if OI <>nil then
   begin
     OI.Enabled:=True;
     if OI.Enabled then
     begin
      OI.Show;
     end;
   end;
end;

function TfrmSaveSQLs.GetUnitName(aCmp: TComponent): string;
begin
   Result:=UnitForFormA(GetFormDesigner(aCmp).GetRoot.Name);
end;


function TfrmSaveSQLs.CloseUnFile(const UnName: string):boolean;
var
 m:IOTAModule;
begin
  Result := False;
  m:= GetIOTAModule(UnName);
  if Assigned(m) then
  begin
    m.CloseModule(True);
    Result := True;
  end;
end;

{$IFDEF SQL_NAVIGATOR_SUPPORT_BDE}
procedure TfrmSaveSQLs.DBParamsFromBDEDatabase(
     const BDE_DataBase:TDatabase;var DPB: TStrings
);
var DPB1:TStrings;
begin
  DPB1:=TStringList.Create;
  try
   Session.GetAliasParams(BDE_DataBase.AliasName,DPB1);
   DPB.Values['DBName']  :=DPB1.Values['SERVER NAME'] ;
   DPB.Values['UserName']:=DPB1.Values['USER NAME'];
   DPB.Values['Password']:=BDE_DataBase.Params.Values['PASSWORD'];
   DPB.Values['RoleName']:='';
   DPB.Values['CharSet' ]:='';
  except
  end;
  DPB1.Free;
end;

procedure TfrmSaveSQLs.DBParamsFromBDEAlias(
     const AliasName:string;var DPB: TStrings
);
var DPB1:TStrings;
begin
  DPB1:=TStringList.Create;
  try
   Session.GetAliasParams(AliasName,DPB1);
   DPB.Values['DBName']  :=DPB1.Values['SERVER NAME'] ;
   DPB.Values['UserName']:=DPB1.Values['USER NAME'];
   DPB.Values['Password']:='';
   DPB.Values['RoleName']:='';
   DPB.Values['CharSet' ]:='';
  except
  end;
  DPB1.Free;
end;

{$ENDIF}

procedure TfrmSaveSQLs.GetDBParams(cmp: TComponent; DPB: TStrings);
var DB:TFIBDataBase;
 {$IFDEF SQL_NAVIGATOR_SUPPORT_BDE}
    DBBDE:TDataBase;
 {$ENDIF}
begin
  DPB.Clear;
  DB:=nil;

  if cmp is TFIBQuery then begin
   DB:=TFIBQuery(cmp).Database;
  end
  else
  if cmp is TFIBDataSet then begin
   DB:=TFIBDataSet(cmp).Database;
  end;
  if DB<>nil  then begin
   DPB.Values['DBName']  :=DB.DBName;
   DPB.Values['UserName']:=DB.ConnectParams.UserName;
   DPB.Values['Password']:=DB.ConnectParams.Password;
   DPB.Values['RoleName']:=DB.ConnectParams.RoleName;
   DPB.Values['CharSet' ]:=DB.ConnectParams.CharSet;
   DPB.Values['SQLDialect' ]:=IntToStr(DB.SQLDialect)   
  end
 {$IFDEF SQL_NAVIGATOR_SUPPORT_BDE}
  else
  if cmp is TQuery then
  begin
    DBBDE:=Session.FindDatabase(TQuery(cmp).DatabaseName);
    if DBBDE<>nil then
     with TQuery(cmp) do     DBParamsFromBDEDatabase(DBBDE,DPB)
    else
     with TQuery(cmp) do     DBParamsFromBDEAlias( TQuery(cmp).DatabaseName,DPB)
  end
  else
  if cmp is TUpdateSQL then
  begin
    if TUpdateSQL(cmp).DataSet=nil then Exit;
    with TDBDataSet(TUpdateSQL(cmp).DataSet) do
    begin
     DBBDE:=Session.FindDatabase(DatabaseName);
     if DBBDE<>nil then
      DBParamsFromBDEDatabase( DBBDE,DPB)
     else
      DBParamsFromBDEAlias( DatabaseName,DPB)
    end;    // with
  end
 {$ENDIF}
end;

function TfrmSaveSQLs.Connect(DPB: TStrings): integer;
begin
     Result:=0; // не смогли подконнектиться
     with pFIBDatabase1 do
     begin
      if (DBName<>DPB.Values['DBName']) and
      (DPB.Values['DBName']<>'')
      then
      begin
       Connected      :=false;
       DBName   :=DPB.Values['DBName'];
       ConnectParams.UserName:=DPB.Values['UserName'];
       ConnectParams.Password:=DPB.Values['Password'];
       ConnectParams.RoleName:=DPB.Values['RoleName'];
       ConnectParams.CharSet :=DPB.Values['CharSet' ];
       UseLoginPrompt :=false;
       SQLDialect:=StrToInt(DPB.Values['SQLDialect']);
      end;
      if not Connected then
       try
        Connected:=True;
       except
        if not Connected then
        begin
         UseLoginPrompt :=True;
         try
          Connected:=True;
         except
           Exit;
         end
        end;
       end;
      if not pFIBTransaction1.InTransaction then
       pFIBTransaction1.StartTransaction;
      Result:=1;
     end
end;

function TfrmSaveSQLs.Analyze(aFIBSQLOwner: TComponent;ResultStrings:TStrings ;
 var F:TextFile
):integer;
procedure AnalyzeSQLText(SQLText:TStrings;const aSQLName: string);
var
    ErrMsg:TStrings;
    Deps:TStrings;

    i :integer;
begin
   Deps :=TStringList.Create;
   try
    AllSQLTables(SQLText.Text,Deps);
    for i:=0 to Pred(Deps.Count) do
    begin
      Writeln(F,'    "'+Deps[i]+'"');
    end;
   except
     On E: Exception do
     begin
      ErrMsg:=TStringList.Create;
      ErrMsg.Text:=E.Message;
      ResultStrings.Add(
       'Error in:'+
        aFIBSQLOwner.Owner.Name+'.'+aFIBSQLOwner.Name+'.'+
         aSQLName
      );
      ListBox1.Items.AddObject(
       'Error in:'+
        aFIBSQLOwner.Owner.Name+'.'+aFIBSQLOwner.Name+'.'+
         aSQLName
        ,
       ErrMsg
      );
      Result:=3;
     end;
   end;
   Deps .Free;
end;

begin
  Result:=1; //Не ассигнован ДбНаме
  ResultStrings.Clear;

 try
    Writeln(F,'Used objects:');
    begin
        if aFIBSQLOwner is TFIBQuery then
         AnalyzeSQLText(TFIBQuery(aFIBSQLOwner).SQL,'SQL')
        else
        if aFIBSQLOwner is TFIBDataSet then
        begin
         AnalyzeSQLText(TFIBDataSet(aFIBSQLOwner).SelectSQL, 'SelectSQL');
         AnalyzeSQLText(TFIBDataSet(aFIBSQLOwner).InsertSQL, 'InsertSQL');
         AnalyzeSQLText(TFIBDataSet(aFIBSQLOwner).RefreshSQL,'RefreshSQL');
         AnalyzeSQLText(TFIBDataSet(aFIBSQLOwner).DeleteSQL, 'DeleteSQL');
         AnalyzeSQLText(TFIBDataSet(aFIBSQLOwner).UpdateSQL, 'UpdateSQL');
        end
       {$IFDEF SQL_NAVIGATOR_SUPPORT_BDE}
        else
        if aFIBSQLOwner is TQuery then
        begin
         AnalyzeSQLText(TQuery(aFIBSQLOwner).SQL,'SQL');
        end
        else
        if aFIBSQLOwner is TUpdateSQL then
        begin
         AnalyzeSQLText(TUpdateSQL(aFIBSQLOwner).InsertSQL , 'InsertSQL');
         AnalyzeSQLText(TUpdateSQL(aFIBSQLOwner).DeleteSQL , 'DeleteSQL');
         AnalyzeSQLText(TUpdateSQL(aFIBSQLOwner).ModifySQL , 'UpdateSQL');
        end
       {$ENDIF}
        ;Result:=0
    end;
 finally

 end;
end;
//
procedure TfrmSaveSQLs.btnGetFormsClick(Sender: TObject);
begin
 PrepareForms(false);
 ClearForms;
 lstQueries.Clear;
 GetForms;
end;


function  TfrmSaveSQLs.UnitInProject(const UnitName:string):boolean;
begin
 Result:=UnitInActiveProject(UnitName);
end;


procedure TfrmSaveSQLs.ToolButton5Click(Sender: TObject);
var i:integer;
begin
 with FListOfOpenedForms do
  for i:=Pred(Count) downto 0 do
  begin
   if CloseUnFile(FListOfOpenedForms[i]) then
    FListOfOpenedForms.Delete(i);
  end;
// FListOfOpenedForms.Clear;
 ClearForms;
 PrepareForms(True);
 GetForms;
 FillQueryList;
 if CurrentComponent<>nil then
 begin
   FocusToComponent(CurrentComponent);
 end;
end;


procedure TfrmSaveSQLs.MemoExit(Sender: TObject);
var
   {$IFDEF USE_SYN_EDIT}
     Mem:TSynEdit;
   {$ELSE}
     Mem:TMemo;
   {$ENDIF}
    vvFIBSQLOwner:TFIBSQLOwner;
begin
   {$IFDEF USE_SYN_EDIT}
     Mem:=TSynEdit(Sender);
   {$ELSE}
     Mem:=TMemo(Sender);
   {$ENDIF}

 Mem.Modified:=OldSQLTxt<>Mem.Lines.Text;
 if Mem.Modified then
 begin
   vvFIBSQLOwner:=GetCurrentSQLOwner;
   if vvFIBSQLOwner <>nil then
   with vvFIBSQLOwner,Mem do
   begin
    if memSQL=Sender then
     SetProp('SQL',Lines)
    else
    if memInsertSQL=Sender then
     SetProp('InsertSQL',Lines)
    else
    if memUpdateSQL=Sender then
     SetProp('UpdateSQL',Lines)
    else
    if memDeleteSQL=Sender then
     SetProp('DeleteSQL',Lines)
    else
    if memRefreshSQL=Sender then
     SetProp('RefreshSQL',Lines)
     
   end;
 end;
end;


procedure TfrmSaveSQLs.MemoEnter(Sender: TObject);
var
   {$IFDEF USE_SYN_EDIT}
     Mem:TSynEdit;
   {$ELSE}
     Mem:TMemo;
   {$ENDIF}
begin
   {$IFDEF USE_SYN_EDIT}
     Mem:=TSynEdit(Sender);
   {$ELSE}
     Mem:=TMemo(Sender);
   {$ENDIF}
   OldSQLTxt:=Mem.Lines.Text;
end;

procedure TfrmSaveSQLs.FormShow(Sender: TObject);
begin
 PrepareForms(True);
 GetForms;
 if CurrentComponent<>nil then
 begin
   FocusToComponent(CurrentComponent);
 end;
end;

procedure TfrmSaveSQLs.ToolButton8Click(Sender: TObject);
begin
 ScanSelObjects(oAnalyzeSQL);
end;

procedure TfrmSaveSQLs.lstQueriesDblClick(Sender: TObject);
begin
 GotocurrentComponent1Click(GotocurrentComponent1);
end;

procedure TfrmSaveSQLs.ToolButton10Click(Sender: TObject);
var
 FIBSQLOwner:TFIBSQLOwner;
 ExitToCodeEditor:integer;
begin
 FIBSQLOwner:=GetCurrentSQLOwner;
 if FIBSQLOwner=nil then
  Exit;
 if FIBSQLOwner.vFIBSQLOwner is TpFIBDataSet then
  ShowDSSQLsEdit(TpFIBDataSet(FIBSQLOwner.vFIBSQLOwner),ExitToCodeEditor)
 else
 if FIBSQLOwner.vFIBSQLOwner is TpFIBQuery then
  ShowSQLEdit(TpFIBQuery(FIBSQLOwner.vFIBSQLOwner));
end;

var
 idn:integer;

initialization
 CurrentComponent:=nil;
 InEnter:=false;
 FakeCmp:=TFakeCmp.Create(nil);
 frmSaveSQLs:=nil;
 Notificator:=TNotificator.Create(nil);
 {$IFNDEF FIBPLUS_TRIAL}
 idn:= (BorlandIDEServices as IOTAServices).AddNotifier(Notificator);
 {$ENDIF}
finalization
 if Assigned(frmSaveSQLs) then
  frmSaveSQLs.Free;
 FakeCmp.Free;
 {$IFNDEF FIBPLUS_TRIAL}
 (BorlandIDEServices as IOTAServices).RemoveNotifier(idn);
 {$ENDIF} 
 Notificator.Free
end.



