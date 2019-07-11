unit fraSQLEdit;

interface

{$I ..\FIBPlus.inc}
{$I pFIBPropEd.inc}
uses

  Windows, Messages, SysUtils, Classes,
  {$IFDEF D_XE2}
  Vcl.Graphics, Vcl.Dialogs, Vcl.Menus,Vcl.Forms,
  Data.DB, Vcl.DBCtrls, Vcl.StdCtrls, Vcl.Mask, Vcl.Grids, Vcl.DBGrids,
  Vcl.Controls, Vcl.ComCtrls, Vcl.Buttons, Vcl.ExtCtrls,
  {$ELSE}
  Graphics, Controls, Menus, Forms, Dialogs,
  Buttons, ExtCtrls, StdCtrls, Grids, DBGrids, DB, DBCtrls, Mask, ComCtrls,
  {$ENDIF}
  pFIBInterfaces  ,  RegFIBPlusEditors,uFIBEditorForm
  {$IFDEF D6+},Variants{$ENDIF}

  ;




type
  TFrame=TFIBEditorCustomFrame;// Fake for D5 

  TfSQLEdit = class(TFrame)
    Panel1: TPanel;
    Panel10: TPanel;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    Panel6: TPanel;
    Panel7: TGroupBox;
    LbTableSyn: TCheckBox;
    chReplaceSQL: TCheckBox;
    Splitter2: TSplitter;
    ds: TDataSource;
    FontDialog1: TFontDialog;
    FindDialog1: TFindDialog;
    dsFields: TDataSource;
    chOnlySelFields: TCheckBox;
    btnCheck: TSpeedButton;
    GroupBox1: TGroupBox;
    Panel2: TPanel;
    Splitter1: TSplitter;
    DBGrid1: TDBGrid;
    DBGrid2: TDBGrid;
    Panel3: TPanel;
    Label4: TLabel;
    Edit1: TEdit;
    cmbTabsNameViews: TComboBox;
    btnGenSQL: TSpeedButton;
    cmbKindSQL: TComboBox;
    Label1: TLabel;
    splPlan: TSplitter;
    menuPlan: TPopupMenu;
    miHidePlan: TMenuItem;
    Label2: TLabel;
    cmbParamSymbol: TComboBox;
    btnReplaceZv: TSpeedButton;
    StatusBar1: TStatusBar;
    btnShowInCodeEditor: TSpeedButton;
    Panel4: TPanel;
    edDomain: TDBEdit;
    Label3: TLabel;
    Label5: TLabel;
    edFieldType: TEdit;
    btnColorBack: TSpeedButton;
    ColorDialog1: TColorDialog;
    btnShowDDL: TSpeedButton;
    btnSQLHelp: TSpeedButton;
    btnSQLScript: TSpeedButton;
    lbNotNull: TLabel;
    procedure Panel7Resize(Sender: TObject);
    procedure cmbTabsNameViewsChange(Sender: TObject);
    procedure qrySPsFilterRecord(DataSet: TDataSet; var Accept: Boolean);
    procedure Edit1Change(Sender: TObject);
    procedure DBGrid1DblClick(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure FindDialog1Find(Sender: TObject);
    procedure DBGrid1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure btnGenSQLClick(Sender: TObject);
    procedure Panel10Resize(Sender: TObject);
    procedure btnCheckClick(Sender: TObject);
    procedure miHidePlanClick(Sender: TObject);
    procedure cmbParamSymbolChange(Sender: TObject);
    procedure DBGrid1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure btnReplaceZvClick(Sender: TObject);
    procedure qryTabFieldsBeforeOpen(DataSet: TDataSet);
    procedure btnShowInCodeEditorClick(Sender: TObject);
    procedure qryAllTablesAfterScroll(DataSet: TDataSet);
    procedure qryTabFieldsAfterScroll(DataSet: TDataSet);
    procedure qrySPFieldsAfterOpen(DataSet: TDataSet);
    procedure btnColorBackClick(Sender: TObject);
    procedure btnShowDDLClick(Sender: TObject);
    procedure btnSQLHelpClick(Sender: TObject);
    procedure btnSQLScriptClick(Sender: TObject);
  private
//FIBPlus Components
    FDataSetClass:TClass;

    qryAllTables :TDataSet;
    qrySPs:TDataSet;
    qrySPparams:TDataSet;
    qryTabFields:TDataSet;
    qrySPFields:TDataSet  ;
    qryTabFields1:TDataSet;
    qryAllTables1:TDataSet;
    //~ qryAllGenerators:TDataSet;

  private
    OutPutTxt:TStrings;
    Dialect  :integer;
    vParamSymb:Char;
    FCanConnect:boolean;
    FConnectForced:boolean;
    FExistField_ForPrecision:integer;
    procedure GenTemplate(IsSP,OnlySelFields:boolean);
    procedure viewSQLKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure viewSQLKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure viewSQLMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);


    procedure ShowHideTemplateSupport;
    procedure CheckSQL;
    function GetSQLText: string;
    procedure SetSQLText(const Value: string);
    procedure EditorDragOver(Sender, Source: TObject; X, Y: Integer;
     State: TDragState; var Accept: Boolean);
    procedure EditorDragDrop(Sender, Source: TObject; X, Y: Integer);
    function GetModified: boolean;
  protected
    FProposalPrepared:boolean;
    procedure PrepareProposals;
    procedure CallBackProposal(const ProposalName:string);    
  public
// Interface variables
    FStringer:IFIBStringer;
    FMetaExtractor:IFIBMetaDataExtractor;

    vEditedQuery:TComponent;
    FDatabase  :TComponent;
    trTransaction: TComponent;
    viewSQL: TWinControl;
    viewPlan:TWinControl;
    iViewSQL:IFIBSQLTextEditor;
    iViewPlan:IFIBSQLTextEditor;

    procedure Search(Again:boolean);

  public
    destructor Destroy; override;
    procedure ShowEditorStatus;
    procedure ReadOptions;
    procedure SaveOptions;

    procedure PrepareFrame(Database:TComponent);
    property  SQLText:string read GetSQLText write SetSQLText;
    property  CanConnect: boolean read FCanConnect;
    property  Modified:boolean read GetModified;
  end;

const
   SpaceStr='    ';
   ForceNewStr=#13#10+SpaceStr;
   QuotMarks=#39;

implementation

{$R *.dfm}

uses
 TypInfo,RegistryUtils,ToCodeEditorIntfs,  pFIBEditorsConsts
  , RTTIRoutines, uFIBScriptForm{$IFDEF HTML_DOCS}, uFIBSQLHelper{$ENDIF},
  IBSQLSyn, pFIBSyntaxMemo, uFontEditor;

const
   RegFIBSQLEdOptions='SQLEditorFrame';

type THackWinControl=class(TCustomControl);

  TDBObjectType = (otDomain, otTable, otView, otProcedure, otGenerator,
    otException, otUDF, otRole,otDBTrigger);
// must be equal TDBObjectType from pFIBMetaData.pas


procedure TfSQLEdit.Panel7Resize(Sender: TObject);
begin
 DBGrid1.Columns[0].Width:=Panel7.Width-30;
 Edit1.Width:=Panel7.Width-104;
 cmbTabsNameViews.Width:=Panel7.Width-7;
 DBGrid2.Columns[0].Width:=DBGrid1.Columns[0].Width;
end;

procedure TfSQLEdit.PrepareFrame(Database:TComponent);

//var Splitter1:TSplitter;


procedure PrepareDataSet(var DS:TDataSet);
begin
   DS:=TDataSet(TComponentClass(FDataSetClass).Create(Self));
   SetObjectProp(DS,'Database',DataBase);
   SetObjectProp(DS,'Transaction',trTransaction);
end;

begin
//   StatusBar1.Visible:=False;
   FDatabase:=Database;
   if Assigned(Database) then
   begin
     Dialect:= GetPropValue(Database,'SQLDialect');
     if GetPropValue(Database,'Connected') then
      FCanConnect:=True
     else
     try
      SetPropValue(Database,'Connected','True');
      FCanConnect   :=GetPropValue(Database,'Connected');
      FConnectForced:=FCanConnect;
//      Database.Connected:=False
     except
     end;
   end
   else
   begin
    Dialect:=1;
    Panel6.Visible:=False;
    Splitter2.Visible:=False;
    btnCheck.Enabled :=False;
    btnGenSQL.Visible:=False;
   end;
   vParamSymb:=':';

   {$IFNDEF HTML_DOCS}
    btnSQLHelp.Visible:=False;
   {$ENDIF}
   FStringer:=FIBClassesExporter.iGetStringer;
   FMetaExtractor:=FIBClassesExporter.iGetMetaExtractor;
   FDataSetClass :=expDatasetClass;

    viewSQL:=TWinControl(TComponentClass(GetSQLTextEditor).Create(Self));
    viewSQL.Tag:=1;
    viewPlan:=TWinControl(TComponentClass(GetSQLTextEditor).Create(Self));
    
    ObjSupports(viewSQL, IFIBSQLTextEditor,   iViewSQL);
    ObjSupports(viewPlan, IFIBSQLTextEditor,   iViewPlan);
//Bug
//    PrepareProposals;

   OutPutTxt :=iViewSQL .Lines;
   iViewSQL.DoBeforeProposalCall:=CallBackProposal;   
   with THackWinControl(viewPlan) do
   begin
     Parent:=Panel1;
     Font.Name:='Courier New';
     Font.Size:=10;
     Align:=alBottom;
     SendToBack;
     Visible:=False;
     Height:=80;
     PopupMenu:= menuPlan;
     iViewPlan .ReadOnly:=True
   end;
   with THackWinControl(viewSQL) do
   begin
     Parent:=Panel1;
     Font.Name:='Courier New';
     Font.Size:=10;
     Align:=alClient;
     SendToBack;

     OnKeyDown:=viewSQLKeyDown;
     OnKeyUp:=viewSQLKeyUp;
     OnMouseUp:=viewSQLMouseUp;
     OnDragOver:=EditorDragOver;
     OnDragDrop:=EditorDragDrop;
   end;


   if FCanConnect then
   begin
     trTransaction:=expTransactionClass.Create(Self);
     SetObjectProp(trTransaction,'DefaultDatabase',DataBase);
     PrepareDataSet(qryAllTables);
     PrepareDataSet(qrySPs);
     PrepareDataSet(qrySPparams);
     PrepareDataSet(qryTabFields);
     PrepareDataSet(qrySPFields);
     PrepareDataSet(qryTabFields1);
     PrepareDataSet(qryAllTables1);
//     PrepareDataSet(qryAllGenerators);

     AssignStringsToProp(qryAllTables,'SelectSQL',
      'select RDB$RELATION_NAME AS NAME'+
      ' from RDB$RELATIONS'+
      ' where RDB$FLAGS = 1 '+
      'order by 1'
     );
     qryAllTables.OnFilterRecord:=qrySPsFilterRecord;
     qryAllTables.Filtered:=True;
     qryAllTables.AfterScroll:=qryAllTablesAfterScroll;

     AssignStringsToProp(qrySPs,'SelectSQL',
           'select RDB$PROCEDURE_NAME AS NAME '+
           ' from RDB$PROCEDURES order by 1'
     );
     qrySPs.Filtered := True;
     qrySPs.OnFilterRecord := qrySPsFilterRecord;
     qrySPs.AfterScroll:=qryAllTablesAfterScroll;

     AssignStringsToProp(qryTabFields,'SelectSQL',
      ' Select RF.rdb$field_name NAME, F.rdb$field_name DOMAIN_NAME,'+
      ' F.rdb$field_type,F.rdb$field_length,F.rdb$null_flag '+
      ' ,F.rdb$field_scale,F.rdb$field_sub_type, '+
      ' RF.RDB$NULL_FLAG NOT_NULL'+
      '  ,@@PREC%0 rdb$field_precision@ '+
      ' from  RDB$RELATION_FIELDS RF '+
      ' join rdb$fields F on RF.rdb$field_source=F.rdb$field_name '+
      ' where  RDB$RELATION_NAME=?NAME '+
      'order by RDB$FIELD_POSITION');

     qryTabFields.AfterScroll := qryTabFieldsAfterScroll;
     qryTabFields.BeforeOpen := qryTabFieldsBeforeOpen;
     SetObjectProp(qryTabFields,'DataSource',ds);

     SetPropValue(qryTabFields,'DetailConditions','[dcForceMasterRefresh,dcForceOpen]');



     AssignStringsToProp(qrySPparams,'SelectSQL',
      'select RDB$PARAMETER_NAME,'+
      'RDB$PARAMETER_NUMBER,'+
      'RDB$PARAMETER_TYPE '+
      ' from RDB$PROCEDURE_PARAMETERS '+
      'WHERE RDB$PROCEDURE_NAME=?NAME '+
      'order by 3 DESC ,2 ');

     SetPropValue(qrySPparams,'DetailConditions','[dcForceMasterRefresh,dcForceOpen]');

     AssignStringsToProp(qrySPFields,'SelectSQL',
      'select  RDB$PARAMETER_NAME NAME,'+
      '  F.rdb$field_name DOMAIN_NAME,F.rdb$null_flag NOT_NULL,F.rdb$field_type,' +
      'F.rdb$field_length,'+
      '  F.rdb$field_scale,  F.rdb$field_sub_type, 0 rdb$field_precision '+
      'from   RDB$PROCEDURE_PARAMETERS RF '+
      ' join rdb$fields F on RF.rdb$field_source=F.rdb$field_name '+
      'WHERE RDB$PROCEDURE_NAME=?NAME and '+
      ' RDB$PARAMETER_TYPE=1 '+
      'order BY RDB$PARAMETER_NUMBER '
     );

     qrySPFields.AfterOpen := qrySPFieldsAfterOpen;
     qrySPFields.AfterScroll := qryTabFieldsAfterScroll;
     SetObjectProp(qrySPFields,'DataSource',ds);
     SetPropValue(qrySPFields,'DetailConditions','[dcForceMasterRefresh,dcForceOpen]');

     AssignStringsToProp(qryTabFields1,'SelectSQL',
      'Select  RDB$FIELD_NAME NAME from  RDB$RELATION_FIELDS '+
      'where   RDB$RELATION_NAME=?NAME '+
      'union select '+
      '  RDB$PARAMETER_NAME NAME '+
      'from '+
      '  RDB$PROCEDURE_PARAMETERS '+
      'WHERE '+
      ' RDB$PROCEDURE_NAME=?NAME and RDB$PARAMETER_TYPE=1 '+
      'order BY 1');
     qryTabFields1.BeforeOpen := qryTabFieldsBeforeOpen;


     AssignStringsToProp(qryAllTables1,'SelectSQL',
      'select RDB$RELATION_NAME AS NAME, 0 T '+
      ' from RDB$RELATIONS R '+
      ' where RDB$FLAGS = 1 and RDB$VIEW_BLR IS NULL '+
      'union '+
      'select RDB$RELATION_NAME AS NAME, 1 T '+
      ' from RDB$RELATIONS R '+
      ' where RDB$FLAGS = 1 and NOT RDB$VIEW_BLR IS NULL '+
      'union '+
      'select RDB$PROCEDURE_NAME AS NAME,2 T '+
      ' from RDB$PROCEDURES '+

      ' order by 2,1');

     qryAllTables1.Filtered := True;
     qryAllTables1.OnFilterRecord := qrySPsFilterRecord;


{     AssignStringsToProp(qryAllGenerators,'SelectSQL',
      ' SELECT RDB$GENERATOR_NAME '+
      ' FROM RDB$GENERATORS '+
      ' WHERE  RDB$SYSTEM_FLAG IS NULL '+
      ' ORDER BY 1');

    qryAllGenerators.Filtered := True;
    qryAllGenerators.OnFilterRecord := qrySPsFilterRecord;
 }
   end;

  cmbTabsNameViews.Items.Add(SGenSQLView1);
  cmbTabsNameViews.Items.Add(SGenSQLView2);
  cmbTabsNameViews.Items.Add(SGenSQLView3);

  if FCanConnect then
  begin
    cmbTabsNameViews.ItemIndex:=1;
    cmbTabsNameViewsChange(cmbTabsNameViews);
  end
  else
  begin
   cmbTabsNameViews.ItemIndex:=0;
  end;
  cmbKindSQL.ItemIndex:=0;
  DBGrid1.Align:=alTop;
  Splitter1.Height:=3;
  cmbParamSymbol.ItemIndex:=0;
  if not FCanConnect then
     ShowHideTemplateSupport;
end;

const
  CMPFORMAT = '\color{clBlue}%s \style{+B}\color{clBlack}%s\style{-B} ';

  { TODO : Добить пропозал }

procedure TfSQLEdit.cmbTabsNameViewsChange(Sender: TObject);
begin
 case cmbTabsNameViews.ItemIndex of
   0:
   begin
    qryAllTables.Close;
    qrySPs.Close;
   end;
   1:
   begin
      SetObjectProp(qrySPFields,'DataSource',nil);
      SetObjectProp(qryTabFields,'DataSource',ds);
      ds.DataSet:=qryAllTables;
      ds.DataSet.Open;
      dsFields.DataSet:=qryTabFields;
   end;
   2:
   begin
      SetObjectProp(qrySPFields,'DataSource',ds);
      SetObjectProp(qryTabFields,'DataSource',nil);


      ds.DataSet:=qrySPs;
      ds.DataSet.Open;
      dsFields.DataSet:=qrySPFields;      
   end;
 end;
end;

procedure TfSQLEdit.qrySPsFilterRecord(DataSet: TDataSet;
  var Accept: Boolean);
begin
 Accept :=true;
 with DataSet do       
  if Trim(Edit1.Text)<>'' then
   Accept :=Pos(UpperCase(Trim(Edit1.Text)),UpperCase(Fields[0].AsString))<>0;
end;

procedure TfSQLEdit.Edit1Change(Sender: TObject);
begin
 qryAllTables.Filtered:=False;
 qryAllTables.Filtered:=True;
 qrySPs.Filtered:=False;
 qrySPs.Filtered:=True;
 qryAllTables1.Filtered:=False;
 qryAllTables1.Filtered:=True;
end;

procedure TfSQLEdit.DBGrid1DblClick(Sender: TObject);
begin
 GenTemplate(cmbTabsNameViews.ItemIndex=2,chOnlySelFields.Checked);
end;



function GetLinePosition(SQL:TStrings;Position:integer):integer;
var L:integer;
begin
 Result:=0; L:=0;
 while (L<Position) and (Result<SQL.Count) do
 begin
   L:=L+Length(SQL[Result])+2;
   Inc(Result);
 end;
end;

procedure TfSQLEdit.GenTemplate(IsSP,OnlySelFields: boolean);
var DefSyn:string;
    DefSyn1:string;
    Dest:TStrings;
    DFrom:TPoint;
    LineFrom:integer;
    fn,pars:string;
    IsExecSP:boolean;
    CurMetaObj:string;
    i,c:integer;
    s:string;
    p,p1:integer;
    SysTab:TDataSet;
    iSysTab:IFIBDataSet;
procedure AddField(const FName:string);
begin
  with Dest do
  begin
      fn:=FStringer.FormatIdentifier(Dialect,FName);
      if chReplaceSQL.Checked then
       Add(SpaceStr+DefSyn1+fn+',')
      else
      begin
       Dest[LineFrom-1]:=Dest[LineFrom-1]+',';
       Insert(LineFrom,SpaceStr+DefSyn1+fn);
       Inc(LineFrom)
      end;
  end;
end;

procedure AddUpdateField(const FName:string);
begin
  with Dest do
  begin
      fn:=FStringer.FormatIdentifier(Dialect,FName);
      Add(SpaceStr+fn+'='+vParamSymb+fn+',')
  end;
end;

begin
 LineFrom:=0;
 if DBGrid1.DataSource.DataSet.FieldCount=0 then Exit;
 CurMetaObj:=DBGrid1.DataSource.DataSet.Fields[0].asString;
 if LbTableSyn.Checked and (cmbKindSQL.ItemIndex=0)  then
 begin
   DefSyn:=FStringer.FormatIdentifier(GetPropValue(FDatabase,'SQLDialect',False), Copy(CurMetaObj,1,3));
   if not InputQuery('Enter alias for table :'+CurMetaObj,'',DefSyn) then
    DefSyn:=''
 end
 else
  DefSyn:='';
 if DefSyn<>'' then
  DefSyn1:=DefSyn+'.'
 else
  DefSyn1:='';
 Dest:=OutPutTxt;
 if chReplaceSQL.Checked then Dest.Clear;
 if isSP then SysTab:=qrySPparams else SysTab:=qryTabFields;
 ObjSupports(SysTab,IFIBDataSet,iSysTab);
 with SysTab,Dest do
 begin
{   if Params[0].AsString<>CurMetaObj then
   begin
    Params[0].AsString :=CurMetaObj;
    Close;    Open;
   end;
 }

   if iSysTab.ParamValue('NAME')<>CurMetaObj then
   begin
    iSysTab.SetParamValues('NAME',[CurMetaObj]);
    Close;    Open;
   end;

   if RecordCount=0 then
   begin
    if isSP then
    begin
     Add('EXECUTE PROCEDURE '+ FStringer.FormatIdentifier(Dialect,CurMetaObj));
    end;
    Exit;
   end;

   IsExecSP:=IsSP and ((Fields[2].asInteger=0) or (cmbKindSQL.ItemIndex=4));
   if IsExecSP then
   begin
     Add('EXECUTE PROCEDURE '+ FStringer.FormatIdentifier(Dialect,CurMetaObj));
     DefSyn:=' ';
   end;
   if (chReplaceSQL.Checked) or (cmbKindSQL.ItemIndex<>0) then
   begin
    if not IsExecSP then
    case cmbKindSQL.ItemIndex of
     0:Add('SELECT');
     1:
     begin
       DefSyn:='';
       Add('INSERT INTO '+FStringer.FormatIdentifier(Dialect,CurMetaObj)+' (');
     end;

     2:Add('UPDATE '+FStringer.FormatIdentifier(Dialect,CurMetaObj)+' SET ');
     3:Add('DELETE FROM '+FStringer.FormatIdentifier(Dialect,CurMetaObj));
    end;
   end
   else
   begin
    FStringer.DispositionFromClause(Dest.Text,DFrom.X,DFrom.Y);
    if DFrom.X=0 then raise Exception.Create('Clause "FROM" not found')
    else
    begin
     s:=Dest.Text;
     if Copy(s,DFrom.Y-DFrom.X-1,2)<>ForceNewStr then
      Dest.Text:=Copy(s,1,DFrom.X-1)+#13#10+
                Copy(s,DFrom.X,DFrom.Y-DFrom.X)+ForceNewStr+
                Copy(s,DFrom.Y+1,MaxInt)
     else
      Dest.Text:=Copy(s,1,DFrom.X-1)+#13#10+
                Copy(s,DFrom.X,DFrom.Y-DFrom.X)+
                Copy(s,DFrom.Y+1,MaxInt);
     LineFrom:=GetLinePosition(Dest,DFrom.X+2)-1;
    end;
   end;

   if not OnlySelFields then
   begin
     First;
     while not eof and not IsExecSP and (not IsSP or (Fields[2].asInteger<>0)) do
     begin
       case cmbKindSQL.ItemIndex of
        0,1,4: AddField(Fields[0].asString);
        2: AddUpdateField(Fields[0].asString);
       end;
      Next
     end;
   end
   else
   with DBGrid2,DBGrid2.DataSource.DataSet do
   begin
    if SelectedRows.Count>0 then
      for i:=0 to Pred(SelectedRows.Count) do
      begin
        Bookmark:=SelectedRows[i];
       case cmbKindSQL.ItemIndex of
        0,1,4: AddField(Fields[0].asString);
        2: AddUpdateField(Fields[0].asString);
       end;
      end
     else
     begin
       case cmbKindSQL.ItemIndex of
        0,1,4: AddField(Fields[0].asString);
        2: AddUpdateField(Fields[0].asString);
       end;
     end;
   end;
   pars:='';
   if IsSP then
   begin
     //Input SP params
       while not eof  do
       begin
        if Fields[2].asInteger=0 then
        begin
         if pars<>'' then
          pars:=pars+','+ForceNewStr;
          pars:=pars+vParamSymb+Trim(Fields[0].asString);
        end;
        Next
       end;
       if pars<>'' then         
        pars:='('+pars+')';
   end;

   if chReplaceSQL.Checked then
   case cmbKindSQL.ItemIndex of
   0:begin
      Strings[Pred(Count)]:=Copy(Strings[Pred(Count)],1,Length(Strings[Pred(Count)])-1);
      if not IsExecSP then
       Add('FROM');
      Add(SpaceStr+FStringer.FormatIdentifier(Dialect,CurMetaObj)+pars+' '+DefSyn)
     end;
   1:begin
      Strings[Pred(Count)]:=Copy(Strings[Pred(Count)],1,Length(Strings[Pred(Count)])-1);
      Add(') VALUES (');
      c:=Count-2;
      for i:=1 to c do
      begin
        Add(SpaceStr+vParamSymb+Trim(Strings[i]));
      end;
      Add(')');
     end;
    2:begin
       Strings[Pred(Count)]:=Copy(Strings[Pred(Count)],1,Length(Strings[Pred(Count)])-1);
       Add('WHERE');

       s:=FMetaExtractor.DBPrimaryKeys(CurMetaObj,trTransaction);
       if s<>'' then
       begin
        p1:=1;
        p:=FStringer.PosCh(';',s);
        while p>0 do
        begin
         pars:=FStringer.FormatIdentifier(Dialect,Copy(s,p1,p-p1));
         Add(SpaceStr+pars+'='+vParamSymb+pars + ' AND ') ;
         p1:=p+1;
         p:=FStringer.PosCh1(';',s,p1);
        end;
        pars:=FStringer.FormatIdentifier(Dialect,Copy(s,p1,Length(s)-p1+1));
        Add(SpaceStr+pars+'='+vParamSymb+pars) ;
       end
       else
       begin
         c:=Count-3;
         for i:=1 to c do
         begin
            Add(Copy(Strings[i],1,Length(Strings[i])-1)+' AND ') ;
         end;
         Add(Strings[c+1]) ;
       end;
      end;
    3:
     begin
       Add('WHERE');
       s:=FMetaExtractor.DBPrimaryKeys(CurMetaObj,trTransaction);
       if s<>'' then
       begin
        p1:=1;
        p:=FStringer.PosCh(';',s);
        while p>0 do
        begin
         pars:=FStringer.FormatIdentifier(Dialect,Copy(s,p1,p-p1));
         Add(SpaceStr+pars+'='+vParamSymb+pars + ' AND ') ;
         p1:=p+1;
         p:=FStringer.PosCh1(';',s,p1);
        end;
        pars:=FStringer.FormatIdentifier(Dialect,Copy(s,p1,Length(s)-p1+1));
        Add(SpaceStr+pars+'='+vParamSymb+pars) ;
       end
     end;
    4:  Add(pars) ;
   end
   else
   begin
    FStringer.DispositionFromClause(Dest.Text,DFrom.X,DFrom.Y);
    LineFrom :=GetLinePosition(Dest,DFrom.Y)-1;
    if (Trim(Dest[LineFrom-1])='') and (Length(Dest[LineFrom-1])>0) then
     Dest[LineFrom-1]:=SpaceStr+ 'JOIN '+
      Trim(FStringer.FormatIdentifier(Dialect,CurMetaObj))+pars+' '+DefSyn+ ' ON ( )'
    else
    Insert(LineFrom,SpaceStr+ 'JOIN '+
      Trim(FStringer.FormatIdentifier(Dialect,CurMetaObj))+pars+' '+DefSyn+ ' ON ( )')
   end;
   FStringer.DeleteEmptyStr(Dest);
 end;
end;

procedure TfSQLEdit.SpeedButton1Click(Sender: TObject);
begin
 if ViewSQL is TMPSyntaxMemo then
  ChangeEditorProps(TMPSyntaxMemo(ViewSQL))
 else
 with FontDialog1.Font do
 begin
   Name :=THackWinControl(viewSQL).Font.Name;
   Size :=THackWinControl(viewSQL).Font.Size;
   Color:=THackWinControl(viewSQL).Font.Color;
   Style:=THackWinControl(viewSQL).Font.Style;
   CharSet:=THackWinControl(viewSQL).Font.CharSet;
   if FontDialog1.Execute then
    THackWinControl(viewSQL).Font:=FontDialog1.Font

 end;
end;

procedure TfSQLEdit.SpeedButton2Click(Sender: TObject);
begin
 FindDialog1.Execute
end;

procedure TfSQLEdit.FindDialog1Find(Sender: TObject);
begin
  Search(False);
end;

procedure TfSQLEdit.Search(Again:boolean);
var L,p,j:integer;
    curL:integer;
    lv:string;
    sStart:integer;
    CurMemo:TControl;
    iCurMemo:IFIBSQLTextEditor;
(*  {$IFDEF USE_SYN_EDIT}
    CurMemo:TSynMemo;
  {$ELSE}
    CurMemo:TMemo;
  {$ENDIF}*)
begin
  //Некое подобие поиска.
  L:=0;
  CurMemo:=viewSQL;
  ObjSupports(CurMemo,IFIBSQLTextEditor,iCurMemo);
  if Again then
   sStart:=iCurMemo.SelStart
  else
   sStart:=1;
  with iCurMemo,CurMemo,FStringer do
  for j:=0 to Pred(Lines.Count) do
  begin
    curL:=Length(Lines[j]);
    if (L+curL)<sStart then L:=L+curL+2
    else
    begin
       if (L-1)< sStart then
       begin
     {$IFDEF USE_SYN_EDIT}
        lv:=Copy(Lines[j],sStart+SelEnd   -L,MaxInt);
     {$ELSE}
        lv:=Copy(Lines[j],sStart+SelLength-L,MaxInt);
     {$ENDIF}
        p:=PosCI(FindDialog1.FindText,lv);
     {$IFDEF USE_SYN_EDIT}
        if p>0 then p:=p+sStart+SelEnd-L-1;
     {$ELSE}
        if p>0 then p:=p+sStart+SelLength-L-1;
     {$ENDIF}
       end
       else
       begin
        lv:=Lines[j];
        p:=PosCI(FindDialog1.FindText,lv);
       end;
       if (p=0)  then L:=L+curL+2
       else
       begin
         if L=0 then SelStart :=p-1 else SelStart :=L+p-1;
     {$IFDEF USE_SYN_EDIT}
         SelEnd   :=SelStart+Length(FindDialog1.FindText);
     {$ELSE}
         SelLength:=Length(FindDialog1.FindText);
     {$ENDIF}
         SetFocus;
      {$IFNDEF LINUX}
         FindDialog1.CloseDialog;
      {$ENDIF}
         Exit;
       end;
    end;
  end;
 {$IFNDEF LINUX}
  FindDialog1.CloseDialog;
 {$ENDIF}
end;

procedure TfSQLEdit.DBGrid1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 {$IFDEF MSWINDOWS}
  if Key=VK_RETURN then
 {$ENDIF}
 {$IFDEF LINUX}
   if Key=Key_Return then
 {$ENDIF}
 DBGrid1DblClick(Sender)
end;

procedure TfSQLEdit.ShowEditorStatus;
begin
 if Modified then
  StatusBar1.Panels[0].Text:='Modified';
{$IFDEF USE_SYN_EDIT}
   with viewSQL do
   begin
     StatusBar1.Panels[1].Text:=IntToStr(CaretY)+':'+IntToStr(CaretX);
   end;
{$ELSE}
   with iViewSQL do
   begin
     StatusBar1.Panels[1].Text:=IntToStr(GetCaretY+1)+':'+IntToStr(GetCaretX+1);
   end;
{$ENDIF}
end;


procedure TfSQLEdit.viewSQLKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
begin
 ShowEditorStatus
end;

procedure TfSQLEdit.viewSQLMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
var
   s:string;
   p:TPoint;
   objName:string;
   ts:TStrings;
begin
 ShowEditorStatus;

 if Sender is TMPCustomSyntaxMemo then
 if (ssCtrl in Shift) and TMPCustomSyntaxMemo(Sender).Hinting then
 begin
   TMPCustomSyntaxMemo(Sender).ScreenPosToTextPos(X,Y,p.x,p.y);

   objName:=TMPCustomSyntaxMemo(Sender).WordByPos(p);

   s:= FIBClassesExporter.iGetMetaExtractor.ObjectDDLTxt(trTransaction,Ord(otTable),objName);
   if s='' then
      s:= FIBClassesExporter.iGetMetaExtractor.ObjectDDLTxt(trTransaction,Ord(otView),objName);
   if s='' then
    s:=FIBClassesExporter.iGetMetaExtractor.ObjectDDLTxt(trTransaction,Ord(otProcedure),objName);
   if s='' then
    s:=FIBClassesExporter.iGetMetaExtractor.ObjectDDLTxt(trTransaction,Ord(otGenerator),objName);
   if s<>'' then
   begin
     ts:=TStringList.Create;
     try
      ts.Text:=s;
      if frmScript<>nil then
      begin
       frmScript.ChangeScript('DDL for "'+objName+'"',ts.Text) ;
       frmScript.SetFocus;
      end
      else
       ShowScript('DDL for "'+objName+'"',FDatabase, ts,True,True );
     finally
      ts.Free
     end;
   end
 end

end;

procedure TfSQLEdit.viewSQLKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 with viewSQL, iViewSQL do    
 if ssCtrl in Shift then
  case Chr(Key) of
  'F','f': FindDialog1.Execute;
  'A','a': SelectAll;
  end
 else
 case Key of
  {$IFDEF WINDOWS}
   VK_F3:
  {$ELSE}
   Key_F3:
  {$ENDIF}
//   FindDialog1Find(FindDialog1);
    Search(True);
   VK_F11:
   begin
    if FCanConnect then
     ShowHideTemplateSupport;
   end;
 end;
end;


procedure TfSQLEdit.ShowHideTemplateSupport;
begin
  if (ds.DataSet<>nil) and ds.DataSet.Active then
  begin
    Splitter2.Visible:=not Splitter2.Visible;
    Panel6.Visible:=not Panel6.Visible;
    Splitter2.Left:=Panel6.Left-100;
  end
  else
  begin
    Splitter2.Visible:=False;
    Panel6.Visible:=False;
  end;
  btnGenSQL.Visible:=Panel6.Visible;
  btnShowDDL.Visible:=Panel6.Visible;
  btnCheck.Visible:=Panel6.Visible;
  btnReplaceZv.Visible:=Panel6.Visible;
end;

procedure TfSQLEdit.btnGenSQLClick(Sender: TObject);
begin
 DBGrid1DblClick(DBGrid1);
end;

procedure TfSQLEdit.Panel10Resize(Sender: TObject);
begin
 btnGenSQL.Left:=Panel10.Width-btnGenSQL.Width-1
end;

procedure TfSQLEdit.CheckSQL;
var
 qryCheck:TComponent;
 iCheck:IFIBQuery;
begin
  if (FStringer.EmptyStrings(OutPutTxt)) or (not FCanConnect) then Exit;
  qryCheck:=
   expQueryClass.Create(Self);
  ObjSupports(qryCheck,IFIBQuery,iCheck);
  with qryCheck,iCheck do
  begin
    SetObjectProp(qryCheck,'Database',FDatabase);
    SetObjectProp(qryCheck,'Transaction',trTransaction);
    SetPropValue(qryCheck,'Options','[qoStartTransaction,qoNoForceIsNull]');

    SetObjectProp(qryCheck,'SQL',OutPutTxt);
    try
     try
       Prepare;
       iViewPlan .Lines.Text:=Plan;
     except
      ON E:Exception do
      begin
        iViewPlan.Lines.Text:=E.Message;
        iViewPlan.Lines.Delete(0);
      end;
     end;
    finally
      viewPlan.Visible:=True;
      splPlan.Top:=1;
      splPlan.Visible:=True;
      Free;
    end;
  end;
end;

procedure TfSQLEdit.btnCheckClick(Sender: TObject);
begin
 CheckSQL
end;

procedure TfSQLEdit.miHidePlanClick(Sender: TObject);
begin
   viewPlan.Visible:=False;
   splPlan.Visible:=False;
end;

procedure TfSQLEdit.cmbParamSymbolChange(Sender: TObject);
begin
 if Length(cmbParamSymbol.Text)>0 then
  vParamSymb:=cmbParamSymbol.Text[1];
end;

function TfSQLEdit.GetSQLText: string;
begin
  Result:=iViewSQL.Lines.Text
end;

procedure TfSQLEdit.SetSQLText(const Value: string);
begin
 iViewSQL.Lines.Text:=Value;
 iViewSQL.SetModified(False);
end;

procedure TfSQLEdit.EditorDragOver(Sender, Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
begin
 Accept:=(Source=DBGrid1) or (Source=DBGrid2)
end;




{$IFDEF USE_SYN_EDIT}
function GetPositionOfMouse(Mem:TSynMemo;out Point: TPoint): Boolean;
begin
  { Get XY caret position of mouse. Returns False if point is outside the
    region of the SynEdit control. }
  with Mem do
  begin
    Result := False;
    GetCursorPos(Point);                    // mouse position (on screen)
    Point := ScreenToClient(Point);    // convert to SynEdit coordinates
    { Make sure it fits within the SynEdit bounds }
    if (Point.X < 0) or (Point.Y < 0) or (Point.X > Width) or (Point.Y> Height) then
      EXIT;

    { inside the eidtor, get the word under the mouse pointer }
{$IFNDEF SYNEDIT_1.3}    
    Point := PixelsToRowColumn(Point); // convert coordinate to LineCol coordinates
{$ELSE}
   with PixelsToRowColumn(Point.X, Point.Y) do
   begin
     Point.X:=Column;
     Point.Y:=Row
   end;
{$ENDIF}    
    Result := True;                         // return that the point was valid
  end;
end;
{$ENDIF}

procedure TfSQLEdit.EditorDragDrop(Sender, Source: TObject; X, Y: Integer);
var
  s,s1:string;
  i:integer;

  p:TPoint;
  diffY:integer;

begin
   diffY:=0;
   if not (Source is TDBGrid) then
    Exit;
   with TDBGrid(Source) do
   begin
    if SelectedRows.Count=0 then
    begin
     s :=' '+FStringer.FormatIdentifier(3,DataSource.DataSet.Fields[0].asString)+' ';
    end
    else
    begin
      if SelectedRows.Count>1 then
      begin
       s1:=' '+FStringer.FormatIdentifier(3,DataSource.DataSet.Fields[0].asString)+','#13#10;
       Inc(diffY);
      end
      else
       s1:='';
      s:=' ';
      DataSource.DataSet.DisableControls;
      try
        for i:=0 to Pred(SelectedRows.Count) do
        begin
          TDBGrid(Source).DataSource.DataSet.Bookmark:=SelectedRows[i];
          s:=s+' '+FStringer.FormatIdentifier(3,DataSource.DataSet.Fields[0].asString)+','#13#10;
          Inc(diffY);
        end;
        s:=s+s1;
      finally
       DataSource.DataSet.EnableControls;
      end;
    end;
   end;



    iViewSQL.ScreenPosToTextPos(X,Y,P.X,P.Y);
    if P.X<0 then
     Exit;

    if iViewSQL.Lines.Count=0 then
     iViewSQL.Lines.Add('');

    if (p.Y<0) then
     p.Y:=0
    else
    if (p.Y>=iViewSQL.Lines.Count) then
     p.Y:=iViewSQL.Lines.Count-1;
    iViewSQL.Lines[p.Y]:=
     Copy(iViewSQL.Lines[p.Y],1,p.X)+s+Copy(iViewSQL.Lines[p.Y],p.X+1,MaxInt);
    iViewSQL.Lines.Text:=iViewSQL.Lines.Text;
    if diffY>0 then
    begin
     iViewSQL.iSetCaretPos(
       Length(iViewSQL.Lines[p.Y]),p.Y+diffY-1);
    end
    else
    begin
      P.X:=P.X+ Length(s)-1;
      with iViewSQL do
       iSetCaretPos(p.X,p.Y)
    end;

    iViewSQL .SetFocus
end;

procedure TfSQLEdit.DBGrid1MouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
//{$IFDEF USE_SYN_EDIT}
 if ssLeft  in Shift then
  TDBGrid(Sender).BeginDrag(False)
//{$ENDIF}
end;


procedure TfSQLEdit.btnReplaceZvClick(Sender: TObject);
var i,j,p:integer;
    s,s1:string;
    curAlias,Alias,RelTable:string;
    dsShablon:TDataSet;
    iShablon:IFIBDataSet;

function GetTableAliasForField(const FieldOrig:string):string;
var
   p1:integer;
begin
   if FieldOrig[1]<>'"' then
   begin
     p1:=Pos('.',FieldOrig);
     if p1>0 then
      Result:=Copy(FieldOrig,1,p1-1)
     else
      Result:=''
   end
   else
   begin
    p1:=2;
    while FieldOrig[p1]<>'"' do
     Inc(p1);
    Result:=Copy(FieldOrig,1,p1)
   end;
end;

begin
 if FCanConnect then
 with FStringer do
 begin
   dsShablon:=TDataSet(expDatasetClass.Create(Self));
   ObjSupports(dsShablon,IFIBDataSet,iShablon);
   try
     SetObjectProp(dsShablon,'Database',FDatabase);
     SetObjectProp(dsShablon,'Transaction',trTransaction);
     SetPropValue(dsShablon,'PrepareOptions','[]');
//     dsShablon.PrepareOptions:=[];
     s1:=iViewSQL.Lines.Text;
     s:='';
     p:=FStringer.PosCh('*',s1);
     if p=0 then Exit;
     while p<>0 do
     begin
      if (p>1) and (s1[p-1]='/') then
      begin
       p:=FStringer.PosInRight('*',s1,p+1);
       Continue
      end;
      if (p<Length(s1)) and (s1[p+1]='/') then
      begin
       p:=FStringer.PosInRight('*',s1,p+1);
       Continue
      end;

      j:=p-1;
      while (j>0) and (s1[j] in [' ',#9,#13,#10]) do Dec(j);
      RelTable:='';Alias:='';
      if (j>0) and (s1[j]='.') then
      begin
       while (j>0) and (s1[j] in [' ',#9,#13,#10,'.']) do
        Dec(j);
       if s1[j]<>'"' then
       begin
         while (j>0) and not (s1[j] in [' ',#9,#13,#10,'.']) do
         begin
          Alias:=s1[j]+Alias;
          Dec(j);
         end;

       end
       else
       begin
        Alias:=s1[j];
        Dec(j);
        while (j>0) and (s1[j]<>'"') do
        begin
         Alias:=s1[j]+Alias;        
         Dec(j);
        end;
        Alias:='"'+Alias  ;
        Dec(j)
       end;

       RelTable:=TableByAlias(iViewSQL.Lines.Text,Alias);
      end;
      s:=s+Copy(s1,1,j);
      if LastChar(s)<>#10 then s:=s+#13#10#9;
      with  dsShablon,iShablon do
      begin
       Close;
       SetObjectProp(dsShablon,'SelectSQL',iViewSQL.Lines);
       SetOrdProp(dsShablon,'FieldOriginRule',3);
//       SelectSQL.Text:=viewSQL.Text;

       Open;
       for i :=0  to Pred(FieldCount) do
       begin
         if (RelTable='') or
          (GetRelationTableName(Fields[i])=UpperCase(RelTable))
         then
         begin

           curAlias:=GetFieldOrigin(Fields[i]);
           curAlias:=GetTableAliasForField(curAlias);
           if curAlias='' then
           begin
             curAlias:=GetRelationTableName(Fields[i]);
             curAlias:=AliasForTable(s1,curAlias);
           end;

          if (Alias='') or (Alias=curAlias) then
          begin
           s:=s+curAlias+'.'+ FStringer.FormatIdentifier(3,GetRelationFieldName(Fields[i]));
          end
          else
           Continue;
//          s:=s+curAlias+'.'+ FStringer.FormatIdentifier(3,GetRelationFieldName(Fields[i]));
(*          if Alias<>'' then
          begin
           s:=s+Alias+'.'+ FStringer.FormatIdentifier(3,GetRelationFieldName(Fields[i]))
          end
          else
          begin

           s:=s+
            FormatIdentifier(3,GetRelationTableName(Fields[i]))+'.'+
            FormatIdentifier(3,GetRelationFieldName(Fields[i]));
          end;*)
          if i<FieldCount-1 then s:=s+','+#13#10#9;
         end;
       end;
      end;
      s1:=Copy(s1,p+1,MaxInt);
      p:=Pos('*',s1);
     end;
     j:=1; p:=Length(s1);
     while (j<=p) and  (s1[j]in [' ',#13,#9,#10]) do Inc(j);
     s1:=Copy(s1,j,100000);
     if (LastChar(s)<>#10) then s:=s+#13#10;
     s:=s+s1;
     iViewSQL.Lines.Text:=s;
   finally
     dsShablon.Free;
   end;
 end;
end;

destructor TfSQLEdit.Destroy;
begin
  iViewSQL:=nil;
  iViewPlan:=nil;
  FStringer:=nil;
  FMetaExtractor:=nil;
  if FConnectForced  then
   SetPropValue(FDatabase,'Connected','False');
  if frmScript<>nil then
    frmScript.Free;
{$IFDEF HTML_DOCS}
  if frmSQLHelper<>nil then
   frmSQLHelper.Free;
{$ENDIF}   
  inherited;
end;


function StrToFontStyle(const Str:String):TFontStyles;
begin
  Result:=[];
  if Pos('fsBold',Str)>0 then Include( Result, fsBold  );
  if Pos('fsItalic',Str)>0 then Include( Result, fsItalic  );
  if Pos('fsUnderline',Str)>0 then Include( Result, fsUnderline  );
  if Pos('fsStrikeOut',Str)>0 then Include( Result, fsStrikeOut  );
end;



procedure TfSQLEdit.ReadOptions;

var v:Variant;
    i:integer;

begin


 v:=
  DefReadFromRegistry(['Software',RegFIBRoot,RegFIBSQLEdOptions],
   [
    'FontName',
    'FontSize',
    'FontColor',
    'FontStyle',
    'FontCharSet',
    'DoReplaceSQL',
    'UseOnlySelectedFields',
    'UseTableAlias',
    'ParamSymbol',
    'AssistantWidth',
    'TableListHeigth',
    'BackgroundColor',
    'DontUseMetadataInProposal'
   ]
 );

 if (VarType(v)<>varBoolean) then
  for i:=0 to  12 do
   if V[1,i] then
   case i of
    0:THackWinControl(viewSQL).Font.Name   :=V[0,i];
    1:THackWinControl(viewSQL).Font.Size   :=V[0,i];
    2:THackWinControl(viewSQL).Font.Color  :=V[0,i];
    3:THackWinControl(viewSQL).Font.Style  :=StrToFontStyle(V[0,i]);
    4:THackWinControl(viewSQL).Font.CharSet:=V[0,i];
    5:chReplaceSQL.Checked:=V[0,i];
    6:chOnlySelFields.Checked:=V[0,i];
    7:LbTableSyn.Checked :=V[0,i];
    8:cmbParamSymbol.Text:=V[0,i];
    9:Panel6.Width       :=V[0,i];
    10:DBGrid1.Height    :=v[0,i];
    11: begin
        THackWinControl(viewSQL).Color  :=V[0,i];
        THackWinControl(viewPlan).Color  :=V[0,i];
    end;
    12: viewSQL.Tag:=V[0,i]
   end;


  if ViewSQL is TMPSyntaxMemo then
  begin
   v:=
    DefReadFromRegistry(['Software',RegFIBRoot,RegFIBSQLEdOptions],
      ['KeyWordsFontColor',
       'KeyWordsFontStyle',
       'FunctionsFontColor',
       'FunctionsFontStyle',
       'ParametersFontColor',
       'ParametersFontStyle',
       'TypesFontColor',
       'TypesFontStyle',
       'CommentsFontColor',
       'CommentsFontStyle',
       'StringsFontColor',
       'StringsFontStyle',
       'NumbersFontColor',
       'NumbersFontStyle',
       'SelectedColor'

      ]
    );
   if (VarType(v)<>varBoolean) then
    for i:=0 to  14 do
     if V[1,i] then
     case i of
      0: TMPSyntaxMemo(ViewSQL).SyntaxAttributes.FontColor[tokKeyWord]:=V[0,i];
      1: TMPSyntaxMemo(ViewSQL).SyntaxAttributes.FontStyle[tokKeyWord]:=StrToFontStyle(V[0,i]);
      2: TMPSyntaxMemo(ViewSQL).SyntaxAttributes.FontColor[tokFunction]:=V[0,i];
      3: TMPSyntaxMemo(ViewSQL).SyntaxAttributes.FontStyle[tokFunction]:=StrToFontStyle(V[0,i]);
      4: TMPSyntaxMemo(ViewSQL).SyntaxAttributes.FontColor[tokParam]:=V[0,i];
      5: TMPSyntaxMemo(ViewSQL).SyntaxAttributes.FontStyle[tokParam]:=StrToFontStyle(V[0,i]);

      6: TMPSyntaxMemo(ViewSQL).SyntaxAttributes.FontColor[tokTypes]:=V[0,i];
      7: TMPSyntaxMemo(ViewSQL).SyntaxAttributes.FontStyle[tokTypes]:=StrToFontStyle(V[0,i]);

      8: TMPSyntaxMemo(ViewSQL).SyntaxAttributes.FontColor[tokILComment]:=V[0,i];
      9: TMPSyntaxMemo(ViewSQL).SyntaxAttributes.FontStyle[tokILComment]:=StrToFontStyle(V[0,i]);

      10: TMPSyntaxMemo(ViewSQL).SyntaxAttributes.FontColor[tokString]:=V[0,i];
      11: TMPSyntaxMemo(ViewSQL).SyntaxAttributes.FontStyle[tokString]:=StrToFontStyle(V[0,i]);

      12: TMPSyntaxMemo(ViewSQL).SyntaxAttributes.FontColor[tokInteger]:=V[0,i];
      13: TMPSyntaxMemo(ViewSQL).SyntaxAttributes.FontStyle[tokInteger]:=StrToFontStyle(V[0,i]);
      14: TMPSyntaxMemo(ViewSQL).SelColor:=V[0,i];
     end
  end   ;

    with TMPSyntaxMemo(ViewSQL).SyntaxAttributes do
    begin
      FontColor[tokStringEnd]:=FontColor[tokString];
      FontStyle[tokStringEnd]:=FontStyle[tokString];

      FontColor[tokFloat]:=FontColor[tokInteger];
      FontStyle[tokFloat]:=FontStyle[tokInteger] ;

      FontColor[tokMLCommentBeg]:=FontColor[tokILComment];
      FontStyle[tokMLCommentBeg]:=FontStyle[tokILComment];

      FontColor[tokMLCommentEnd]:=FontColor[tokILComment];
      FontStyle[tokMLCommentEnd]:=FontStyle[tokILComment];

      FontColor[tokELCommentBeg]:=FontColor[tokILComment];
      FontStyle[tokELCommentBeg]:=FontStyle[tokILComment];

      FontColor[tokELCommentEnd]:=FontColor[tokILComment];
      FontStyle[tokELCommentEnd]:=FontStyle[tokILComment];

   end
end;

function FontStyleToStr(Font:TFont):string;
begin
  Result:='[';
  if fsBold in Font.Style then Result:= Result+'fsBold,';
  if fsItalic in Font.Style then Result:= Result+'fsItalic,';
  if fsUnderline in Font.Style then Result:= Result+'fsUnderline,';
  if fsStrikeOut in Font.Style then Result:= Result+'fsStrikeOut';
  if Result[Length( Result )]=',' then
   Result[Length( Result )]:=']'
  else
   Result:= Result+']'
end;

function FontStyleToStr1(fs:TFontStyles):string;
begin
  Result:='[';
  if fsBold in fs then Result:= Result+'fsBold,';
  if fsItalic in fs then Result:= Result+'fsItalic,';
  if fsUnderline in fs then Result:= Result+'fsUnderline,';
  if fsStrikeOut in fs then Result:= Result+'fsStrikeOut';
  if Result[Length( Result )]=',' then
   Result[Length( Result )]:=']'
  else
   Result:= Result+']'
end;



procedure TfSQLEdit.SaveOptions;
begin
 with THackWinControl(viewSQL) do
 begin
   DefWriteToRegistry(['Software',RegFIBRoot,RegFIBSQLEdOptions],
     [
      'FontName',
      'FontSize',
      'FontColor',
      'FontStyle',
      'FontCharSet',
      'DoReplaceSQL',
      'UseOnlySelectedFields',
      'UseTableAlias',
      'ParamSymbol',
      'AssistantWidth',
      'TableListHeigth',
      'BackgroundColor',
      'DontUseMetadataInProposal'
     ],
     [Font.Name,
      Font.Size,
      Font.Color,
      FontStyleToStr(Font),
      Font.CharSet,
      chReplaceSQL.Checked,
      chOnlySelFields.Checked,
      LbTableSyn.Checked,
      cmbParamSymbol.Text,
      Panel6.Width,
      DBGrid1.Height,
      THackWinControl(viewSQL).Color,
      viewSQL.Tag
     ]
   );


    if ViewSQL is TMPSyntaxMemo then
    begin
     DefWriteToRegistry(['Software',RegFIBRoot,RegFIBSQLEdOptions],
      ['KeyWordsFontColor',
       'KeyWordsFontStyle' ,
       'FunctionsFontColor',
       'FunctionsFontStyle',
       'ParametersFontColor',
       'ParametersFontStyle',
       'TypesFontColor',
       'TypesFontStyle',
       'CommentsFontColor',
       'CommentsFontStyle',
       'StringsFontColor',
       'StringsFontStyle',
       'NumbersFontColor',
       'NumbersFontStyle',
       'SelectedColor'
      ],
      [
       TMPSyntaxMemo(ViewSQL).SyntaxAttributes.FontColor[tokKeyWord],
       FontStyleToStr1(TMPSyntaxMemo(ViewSQL).SyntaxAttributes.FontStyle[tokKeyWord]),
       TMPSyntaxMemo(ViewSQL).SyntaxAttributes.FontColor[tokFunction],
       FontStyleToStr1(TMPSyntaxMemo(ViewSQL).SyntaxAttributes.FontStyle[tokFunction]),
       TMPSyntaxMemo(ViewSQL).SyntaxAttributes.FontColor[tokParam],
       FontStyleToStr1(TMPSyntaxMemo(ViewSQL).SyntaxAttributes.FontStyle[tokParam]),
       TMPSyntaxMemo(ViewSQL).SyntaxAttributes.FontColor[tokTypes],
       FontStyleToStr1(TMPSyntaxMemo(ViewSQL).SyntaxAttributes.FontStyle[tokTypes]),
       TMPSyntaxMemo(ViewSQL).SyntaxAttributes.FontColor[tokILComment],
       FontStyleToStr1(TMPSyntaxMemo(ViewSQL).SyntaxAttributes.FontStyle[tokILComment]),
       TMPSyntaxMemo(ViewSQL).SyntaxAttributes.FontColor[tokString],
       FontStyleToStr1(TMPSyntaxMemo(ViewSQL).SyntaxAttributes.FontStyle[tokString]),
       TMPSyntaxMemo(ViewSQL).SyntaxAttributes.FontColor[tokInteger],
       FontStyleToStr1(TMPSyntaxMemo(ViewSQL).SyntaxAttributes.FontStyle[tokInteger]),
       TMPSyntaxMemo(ViewSQL).SelColor
      ]
     )
    end
  end;
end;

procedure TfSQLEdit.qryTabFieldsBeforeOpen(DataSet: TDataSet);
var
   iTabFields: IFIBDataSet;
   iDb:IFIBConnect;
begin
  DBGrid2.SelectedRows.Clear;
  ObjSupports(FDatabase,IFIBConnect,idb);
  ObjSupports(qryTabFields,IFIBDataSet,iTabFields);

  if idb.IsFirebirdConnect then
  begin
   case FExistField_ForPrecision of
    0: begin
         if idb.QueryValueAsStr(
           'SELECT Count(*)   FROM RDB$RELATION_FIELDS WHERE  RDB$FIELD_NAME='+
           '''RDB$FIELD_PRECISION''   and RDB$RELATION_NAME=''RDB$FIELDS''',0,['']
         )='0'
         then
          FExistField_ForPrecision:=2
         else
          FExistField_ForPrecision:=1;
         if FExistField_ForPrecision=1 then
          iTabFields.SetParamValue(0,'F.rdb$field_precision')
         else
          iTabFields.SetParamValues('PREC',[iTabFields.DefMacroValue('PREC')])
       end;
    1: iTabFields.SetParamValues('PREC',['F.rdb$field_precision']);
   else
    iTabFields.SetParamValues('PREC',[iTabFields.DefMacroValue('PREC')])
   end
  end
  else
   iTabFields.SetParamValues('PREC',[iTabFields.DefMacroValue('PREC')])
end;


procedure TfSQLEdit.btnShowInCodeEditorClick(Sender: TObject);
var
  Form:TComponent;
begin
 if not Assigned(StringsToCodeEditor) then
  Exit;
 with StringsToCodeEditor do
 begin
   Form:=Owner;
   while (Form<>nil) and not (Form is TForm) do
    Form:=Form.Owner;
   if (Form<>nil) and (Form is TForm) then
    TForm(Form).ModalResult:=mrYes;

   if not(vEditedQuery.Owner is FDataSetClass) then
    ICreatePropInCode(vEditedQuery,'SQL',iViewSQL .Lines,GetModified)
   else
   begin
     ICreatePropInCode(vEditedQuery.Owner,vEditedQuery.Name,iViewSQL .Lines,GetModified)

{     if vEditedQuery= TFIBDataSet(vEditedQuery.Owner).QSelect then
     if vEditedQuery= TFIBDataSet(vEditedQuery.Owner).QSelect then
      ICreatePropInCode(vEditedQuery.Owner,'SelectSQL',viewSQL.Lines,GetModified)
     else
     if vEditedQuery= TFIBDataSet(vEditedQuery.Owner).QInsert then
      ICreatePropInCode(vEditedQuery.Owner,'InsertSQL',viewSQL.Lines,GetModified)
     else
     if vEditedQuery= TFIBDataSet(vEditedQuery.Owner).QUpdate then
      ICreatePropInCode(vEditedQuery.Owner,'UpdateSQL',viewSQL.Lines,GetModified)
     else
     if vEditedQuery= TFIBDataSet(vEditedQuery.Owner).QDelete then
      ICreatePropInCode(vEditedQuery.Owner,'DeleteSQL',viewSQL.Lines,GetModified)
     else
     if vEditedQuery= TFIBDataSet(vEditedQuery.Owner).QRefresh then
      ICreatePropInCode(vEditedQuery.Owner,'RefreshSQL',viewSQL.Lines,GetModified);}
   end;
 end;
end;

function TfSQLEdit.GetModified: boolean;
var
   Strings:TStrings;
begin
 Strings:=TStrings(GetObjectProp(vEditedQuery,'SQL'));
 Result:=Strings.Text<>iViewSQL .Lines.Text
end;

procedure TfSQLEdit.qryAllTablesAfterScroll(DataSet: TDataSet);
var
    ObjName:string;
    s:String;
begin
 if frmScript<>nil then
 begin
   ObjName:=DataSet.Fields[0].AsString;
   if DataSet=qryAllTables then
   begin
      s:= FIBClassesExporter.iGetMetaExtractor.ObjectDDLTxt(trTransaction,Ord(otTable),objName);
      if s='' then
       s:= FIBClassesExporter.iGetMetaExtractor.ObjectDDLTxt(trTransaction,Ord(otView),objName);
   end
   else
     s:=FIBClassesExporter.iGetMetaExtractor.ObjectDDLTxt(trTransaction,Ord(otProcedure),objName);
   frmScript.ChangeScript('DDL for "'+objName+'"',s);
 end;
end;

procedure TfSQLEdit.qryTabFieldsAfterScroll(DataSet: TDataSet);
var
   s:string;
   prec:string;
begin
 with Dataset do
 case FieldByName('RDB$FIELD_TYPE').asInteger of
  7 : s:='SMALL';
  8 : if FieldByName('RDB$FIELD_SCALE').asInteger=0 then
       s:='INTEGER'
      else
      begin
       s:='NUMERIC';
       if FieldByName('rdb$field_precision').asInteger=0 then
        prec:='9'
       else
        prec:=FieldByName('rdb$field_precision').asString;
       s:=s+'('+prec+','+IntToStr(-FieldByName('RDB$FIELD_SCALE').asInteger)+')';
      end;
  12: s:='DATE';
  13: s:='TIME';
  14: s:='CHAR('+FieldByName('RDB$FIELD_LENGTH').asString+')';
  16:
  begin
   if (FieldByName('RDB$FIELD_SUB_TYPE').asInteger=0) and
      (FieldByName('RDB$FIELD_SCALE').asInteger=0)
   then
      s:='BIGINT'
   else
   begin
     s:='NUMERIC';
     if FieldByName('rdb$field_precision').asInteger=0 then
      prec:='18'
     else
      prec:=FieldByName('rdb$field_precision').asString;

     if (FieldByName('RDB$FIELD_SCALE').asInteger=0) then
      s:=s+'('+prec+',0)'
     else
      s:=s+'('+prec+','+IntToStr(-FieldByName('RDB$FIELD_SCALE').asInteger)+')';
   end;
  end;
  23: // FBBoolean
      s:='BOOLEAN';
  27: if FieldByName('RDB$FIELD_SCALE').asInteger=0 then
       s:='DOUBLE PRECISION'
      else
      begin
       s:='NUMERIC';
       if FieldByName('rdb$field_precision').asInteger=0 then
        prec:='15'
       else
        prec:=FieldByName('rdb$field_precision').asString;
       s:=s+'('+prec+','+IntToStr(-FieldByName('RDB$FIELD_SCALE').asInteger)+')';
      end;
  35: s:='TIMESTAMP';
  37: s:='VARCHAR('+FieldByName('RDB$FIELD_LENGTH').asString+')';
  261: if FieldByName('RDB$FIELD_SUB_TYPE').asInteger=2 then
        s:='Text'
       else
        s:='BLOB';
 else
  s:=''
 end;
 lbNotNull.Visible:= DataSet.FieldByName('NOT_NULL').asInteger=1;

 edFieldType.Text:=s;
end;

procedure TfSQLEdit.qrySPFieldsAfterOpen(DataSet: TDataSet);
begin
 edFieldType.Text:=''
end;

procedure TfSQLEdit.btnColorBackClick(Sender: TObject);
begin
 ColorDialog1.Color:=THackWinControl(viewSQL).Color;
 if  ColorDialog1.Execute then
  THackWinControl(viewSQL).Color:=ColorDialog1.Color
end;


procedure TfSQLEdit.btnShowDDLClick(Sender: TObject);
var ts:TStrings;
    s:String;
    objName:string;

begin
//
 if frmScript<>nil then
 begin
  frmScript.SetFocus;
  Exit;
 end;
 ts:=TStringList.Create;
 try
  if not DBGrid1.DataSource.DataSet.Active then Exit;
  objName:=DBGrid1.DataSource.DataSet.Fields[0].asString;
  case cmbTabsNameViews.ItemIndex of
    1:
     begin
      s:= FIBClassesExporter.iGetMetaExtractor.ObjectDDLTxt(trTransaction,Ord(otTable),objName);
      if s='' then
       s:= FIBClassesExporter.iGetMetaExtractor.ObjectDDLTxt(trTransaction,Ord(otView),objName);
       ts.Text:=s
    end;
    2:  ts.Text:=FIBClassesExporter.iGetMetaExtractor.ObjectDDLTxt(trTransaction,Ord(otProcedure),objName);
  end;
  if frmScript<>nil then
       frmScript.ChangeScript('DDL for "'+objName+'"',ts.Text)
  else
   ShowScript('DDL for "'+objName+'"',FDatabase, ts,True,True );
 finally
  ts.Free
 end
end;

procedure TfSQLEdit.btnSQLHelpClick(Sender: TObject);
begin
{$IFDEF HTML_DOCS}
 ShowSQLHelp
{$ENDIF}
end;

procedure TfSQLEdit.PrepareProposals;
var
 ts,ts1:TStrings;
 i:integer;
begin
  if Assigned(FMetaExtractor) then
  begin
    FMetaExtractor.SetDatabase(FDatabase);
    if (viewSQL.Tag=0) and not FMetaExtractor.NamesLoaded and  FCanConnect     then
      FMetaExtractor.LoadObjectNames;

    ts:=TStringList.Create;
    ts1:=TStringList.Create;
    try
      ts.Assign(DefProposalShadow[0]);
      ts1.Assign(DefProposalShadow[1]);
      iViewSQL.ISetProposalItems(ts,ts1);
      iViewSQL.SaveProposals('DEFAULT');
      if FCanConnect and (viewSQL.Tag=0) and FMetaExtractor.NamesLoaded then
      with FMetaExtractor,FStringer do
      begin
        for i:=0 to  Pred(TablesCount) do
        begin
         ts.Add('table '+ProposalDelimiterShadow+'M '+FormatIdentifier(3, TableName[i]));
         ts1.Add(FormatIdentifier(3, TableName[i]));
        end;

        for i:=0 to  Pred(ViewsCount) do
        begin
         ts.Add('view '+ProposalDelimiterShadow+'O '+FormatIdentifier(3, ViewName[i]));
         ts1.Add(FormatIdentifier(3, ViewName[i]));
        end;

        for i:=0 to  Pred(ProceduresCount) do
        begin
         ts.Add('procedure '+ProposalDelimiterShadow+'N '+FormatIdentifier(3, ProcedureName[i]));
         ts1.Add(FormatIdentifier(3, ProcedureName[i]));
        end;


        for i:=0 to  Pred(UDFSCount) do
        begin
         ts.Add('udf '+ProposalDelimiterShadow+'T '+FormatIdentifier(3, UDFName[i]));
         ts1.Add(FormatIdentifier(3, UDFName[i])+'@@( | )@');
        end;


        for i:=0 to  Pred(GeneratorsCount) do
        begin
         ts.Add('generator '+ProposalDelimiterShadow+'G '+FormatIdentifier(3, GeneratorsName[i]));
         ts1.Add(FormatIdentifier(3, GeneratorsName[i]));
        end;

        iViewSQL.ISetProposalItems(ts,ts1);
        iViewSQL.SaveProposals('MAIN');
        iViewSQL.ClearProposal;

        ts.Clear;
        ts1.Clear;

        ProposalInternalFunctionsItems(ts,ts1);
        for i:=0 to  Pred(UDFSCount) do
        begin
         ts.Add('udf '+ProposalDelimiterShadow+'T '+FormatIdentifier(3, UDFName[i]));
         ts1.Add(FormatIdentifier(3, UDFName[i])+'@@( | )@');
        end;


        for i:=0 to  Pred(GeneratorsCount) do
        begin
         ts.Add('generator '+ProposalDelimiterShadow+'G '+FormatIdentifier(3, GeneratorsName[i]));
         ts1.Add(FormatIdentifier(3, GeneratorsName[i]));
        end;

        iViewSQL.ISetProposalItems(ts,ts1);
        iViewSQL.SaveProposals('FUNCTIONS');



      end;
    finally
     FProposalPrepared:=True;
     ts.Free;
     ts1.Free;
    end
  end;

end;

procedure TfSQLEdit.CallBackProposal(const ProposalName: string);
var
   AliasName:string;
   Parser:ISQLParser;


   Position:integer;
   CurSections:TiSQLSections;
   c:integer;

   objName,DBObjName:string;
   s,s1:String;
   s1a,s2a:string;
   ts,ts1:TStrings;
   i:integer;

type
    TProposalType=(ptFields);

        procedure DoApplyProposal(pt:TProposalType);
        var c:integer;
        begin
           with iViewSQL do
           case pt of
            ptFields:
            begin
                   ClearProposal;
                   SaveProposals('TEMP1');
                   s:=Trim(s);
                   s1:=Trim(s1);
                   ts:=TstringList.Create;
                   ts1:=TstringList.Create;
                   try
                    ts.Text:=s1;
                    ts1.Text:=s;
                    for c:=0 to Pred(ts.Count) do
                     ts[c]:='Field '+ProposalDelimiterShadow+'R'+' '+ts[c];


                    AddToCurrentProposal(ts,ts1);
                    AddProposal('FUNCTIONS')
                   finally
                    ts.Free;
                    ts1.Free;
                   end;

            end;
           end
        end;


begin
 if not FProposalPrepared then
  PrepareProposals;
 if not CanConnect or (viewSQL.Tag<>0) then
 begin
      iViewSQL .    ApplyProposal('DEFAULT');
  Exit;
 end;
 Parser:=FIBClassesExporter.iGetSQLParser;
 with iViewSQL do
 begin
    Parser.SetSQLText(Lines.Text);
    Position:=PosInText;
    CurSections:=Parser.iPosInSections(Position);
    if not FMetaExtractor.NamesLoaded then
      FMetaExtractor.LoadObjectNames;
    if Length(CurSections)=0 then
        ApplyProposal('MAIN')
    else

     if not (CurSections[Length(CurSections)-1] in [pFIBInterfaces.stComment,pFIBInterfaces.stUnknown] )then
     begin
       if (Parser.GetPrevWord(Position,c)='.') or (Parser.GetWord(Position,c)='.') then
       begin
         objName:=Parser.GetPrevWord(c,c);

         DBObjName:=Parser.TableByAlias(Lines.Text,ObjName);
         s:=FMetaExtractor.ObjectListFields(DBObjName,s1);
         if s<>'' then
         begin
          DoApplyProposal(ptFields)

         end
      end
      else
     case CurSections[Length(CurSections)-1] of
      pFIBInterfaces.stFrom:
//       if ProposalName<>'MAIN' then
        ApplyProposal('MAIN');
      pFIBInterfaces.stFields,pFIBInterfaces.stWhere,pFIBInterfaces.stGroupBy,pFIBInterfaces.stHaving,pFIBInterfaces.stOrderBy:
      begin
         ts:=Parser.GetAllTables(True);
         if ts.Count=0 then
          ApplyProposal('MAIN')
         else
         begin
          s:='';
          s1:='';
          for i:=0 to ts.Count-1 do
          begin
           DBObjName:=Parser.CutTableName(ts[i]);
           AliasName:=Parser.CutAlias(ts[i]);
           s1a:=FMetaExtractor.ObjectListFields(DBObjName,s2a,False,True);
           if AliasName<>DBObjName then
           begin
             s1a:=StringReplace(s1a,DBObjName+'.',AliasName+'.',[rfReplaceAll]);
             s2a:=StringReplace(s2a,DBObjName+'.',AliasName+'.',[rfReplaceAll]);
           end;

           s:=s+s1a;
           s1:=s1+s2a
          end;
          if s='' then
            ApplyProposal('MAIN')
          else
          begin
           DoApplyProposal(ptFields)
          end     ;

         end

//         ShowMessage(s+#13+'______'+#13+s1)
       end;
      end
     end

 end

end;

procedure TfSQLEdit.btnSQLScriptClick(Sender: TObject);
begin
 if frmScript1<>nil then
 begin
  frmScript1.SetFocus;
  Exit;
 end; 
   ShowScriptEx('Script execute form',FDatabase, nil,False,True ,1);
end;

end.


