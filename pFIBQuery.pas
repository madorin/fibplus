{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ InterBase databases                                           }
{                                                               }
{    FIBPlus is based in part on the product                    }
{    Free IB Components, written by Gregory H. Deatz for        }
{    Hoagland, Longo, Moran, Dunst & Doukas Company.            }
{    mailto:gdeatz@hlmdd.com                                    }
{                                                               }
{    Copyright (c) 1998-2007 Devrace Ltd.                       }
{    Written by Serge Buzadzhy (buzz@devrace.com)               }
{                                                               }
{ ------------------------------------------------------------- }
{    FIBPlus home page: http://www.fibplus.com/                 }
{    FIBPlus support  : http://www.devrace.com/support/         }
{ ------------------------------------------------------------- }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit pFIBQuery;

interface

{$I FIBPlus.inc}
uses
   FIBPlatforms,SysUtils, Classes,
   DB,ibase,IB_Intf, ib_externals,FIBQuery,fib,FIBDataSet;

type
  TpFIBQuery = class;

  TFIBQueryErrorEvent =
   procedure(pFIBQuery:TpFIBQuery; E: EFIBError; var Action: TDataAction) of object;

  TpFIBQuery = class(TFIBQuery)
  private
    FDescription:string;
    FOnExecuteError:TFIBQueryErrorEvent;
    function GetFIBVersion: string;
    procedure SetFIBVersion(const vs: string);
  protected
  public
    constructor Create(AOwner: TComponent); override;
    procedure ExecProc;
    procedure ExecQuery; override;
    procedure ExecProcedure(const ProcName:string;const InputParams:array of variant); overload;
    procedure ExecProcedure(const ProcName:string);overload;
    function  BlobToStrings(const BlobFieldName:string;Destination:Tstrings):boolean;
    function  BlobAsString(const BlobFieldName:string):string;
    function  FieldIsNull(Field:TFIBXSQLVAR):boolean;
    function  FN(const FieldName:string) : TFIBXSQLVAR;
  published
    property Description:string  read FDescription write FDescription;
    property OnExecuteError:TFIBQueryErrorEvent read FOnExecuteError write FOnExecuteError;
    property About   :string read GetFIBVersion write SetFIBVersion stored false;
    property BeforeExecute;
    property AfterExecute ;
  end;

  TFIBOrderExecUO = (oeBeforeDefault,oeAfterDefault);

  TpFIBUpdateObject = class(TpFIBQuery)
  private
   FActive:boolean;
   FOrderInList:integer;
   FDataSet      :TFIBDataSet;
   FKindUpdate   :TUpdateKind;
   FExecuteOrder :TFIBOrderExecUO;
   procedure SetDataSet     (Value:TFIBDataSet);
   procedure SetOrderInList(Value:Integer);
   procedure SetKindUpdate(Value:TUpdateKind);
  protected
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure   Notification(AComponent: TComponent; Operation: TOperation);override;
    procedure   ChangeOrderInList(NewOrder:integer);
    procedure   Apply;

  published
   property DataSet:TFIBDataSet  read FDataSet write SetDataSet;
   property OrderInList :integer  read FOrderInList write SetOrderInList;
   property KindUpdate  :TUpdateKind read FKindUpdate  write SetKindUpdate default ukModify;
   property Active:boolean read FActive write FActive default true;
   property ExecuteOrder:TFIBOrderExecUO  read FExecuteOrder write FExecuteOrder default oeBeforeDefault;
   property ParamCheck default true ;
  end;

implementation

uses FIBMiscellaneous,pFIBDataSet,StrUtil, FIBConsts;

const ExecProcPrefix1=' PROCEDURE ';

constructor TpFIBQuery.Create(AOwner: TComponent);// override;
begin
 inherited Create(AOwner);
end;


function TpFIBQuery.FieldIsNull(Field:TFIBXSQLVAR):boolean;
begin
  Result:=Field.IsNull
end;


procedure TpFIBQuery.ExecProc;
begin
 if IsProc then ExecQuery;
end;


procedure TpFIBQuery.ExecProcedure(const ProcName:string);
begin
 if SQL.Text<>ExecProcPrefix+ExecProcPrefix1+ProcName+CLRF then
  SQL.Text:=ExecProcPrefix+ExecProcPrefix1+ProcName;
 ExecProc
end;


procedure TpFIBQuery.ExecProcedure(const ProcName:string;const InputParams:array of variant);
var i:integer;
    SQLText:string;
begin
  SQLText:=ExecProcPrefix+ExecProcPrefix1+ProcName;
  if High(InputParams)>=0   then SQLText:=SQLText+'(?P0';
  for i:=Low(InputParams)+1 to High(InputParams) do
  begin
   SQLText:=SQLText+',?P'+IntToStr(i);
  end;

  if High(InputParams)>=0   then SQLText:=SQLText+')';
  if SQL.Text<> SQLText+CLRF then
     SQL.Text:= SQLText;
  if not Prepared then   Prepare;
  for i:=0 to Pred(Params.Count)  do
   Params[i].asVariant:=InputParams[i];
  ExecProc
end;


procedure TpFIBQuery.ExecQuery;
var
 Action: TDataAction;
begin

 Action:=daRetry;
 while Action=daRetry do
 try
  Action:=daFail;
  inherited ExecQuery;
 except
  On E:EFIBError do
  if Assigned(FOnExecuteError) then
   begin
    FOnExecuteError(Self,E,Action);
    case Action of
     daFail: raise ;
     daAbort: Abort;
    end;
   end
  else
   raise
 end;

end;


function TpFIBQuery.GetFIBVersion: string;
begin
 Result:=IntToStr(FIBPlusVersion)+'.'+ IntToStr(FIBPlusBuild)+'.'+
  IntToStr(FIBCustomBuild)+' '+FIBVersionNote
end;

procedure TpFIBQuery.SetFIBVersion(const vs:string);
begin

end;

function  TpFIBQuery.BlobToStrings(const BlobFieldName:string;Destination:Tstrings):boolean;
var bs:TFIBBlobStream;
    fi:integer;
    fld:TFIBXSQLVAR;
begin
  Result:=false;
  if not Open or (Destination=nil)then
   Exit;
  fi:=GetFieldIndex(BlobFieldName);
  if fi<0 then Exit;
  fld:=FieldByName(BlobFieldName);
  if (fld.data.sqltype and (not 1) <> SQL_BLOB) then Exit;
  if (fld.data.sqlsubtype  <> isc_blob_text) then Exit;

  bs := TFIBBlobStream.Create;
  with bs do
  try
   try
    Mode := bmRead;
    Database := Self.Database;
    Transaction := Self.Transaction;
    BlobID := fld.AsQuad;
    Seek(0,soFromBeginning);
    Destination.LoadFromStream(bs);
    Result:=true;
   except
    Result:=false
   end
  finally
    bs.Free
  end;
end;

function  TpFIBQuery.BlobAsString(const BlobFieldName:string):string;
var
 ts:Tstrings;
begin
  Result:='';
  ts:=TStringList.Create;
  try
   if BlobToStrings(BlobFieldName,ts) then Result:=ts.Text
  finally
   ts.Free
  end;
end;

function  TpFIBQuery.FN(const FieldName:string) : TFIBXSQLVAR;
begin
 // Wrapper for FieldByName;
 Result:=FieldByName(FieldName)
end;

/// TpFIBUpdateObject.

constructor TpFIBUpdateObject.Create(AOwner: TComponent); 
begin
 inherited Create(AOwner);
 ParamCheck:=true;
 FKindUpdate:=ukModify;
 FActive:=true;
 FExecuteOrder:=oeBeforeDefault;
end;


destructor TpFIBUpdateObject.Destroy; 
begin
 if FDataSet<>nil then
  TpFIBDataSet(FDataSet).RemoveUpdateObject(Self);
 inherited Destroy;
end;

procedure TpFIBUpdateObject.Notification(AComponent: TComponent; Operation: TOperation);//override;
begin
 if Operation=opRemove then
 begin
  if AComponent=FDataSet then FDataSet:=nil;
 end;
 inherited Notification(AComponent,Operation)
end;

procedure TpFIBUpdateObject.SetDataSet(Value:TFIBDataSet);
begin
 if (Value <> nil) and  not (Value is TpFIBDataSet) then
  raise Exception.Create(Format(SFIBErrorNotDataSet, [Value.Name]));
 if  Value = FDataSet then Exit;
 if  FDataSet<>nil then TpFIBDataSet(FDataSet).RemoveUpdateObject(Self);
 if  Value <>nil   then TpFIBDataSet(Value).AddUpdateObject(Self);
 FDataSet:=Value;
 if FDataSet<>nil then
 begin
  FDataSet.FreeNotification(Self);
  if DataBase=nil    then DataBase   :=FDataSet.DataBase;
  if Transaction=nil then Transaction:=FDataSet.Transaction;
 end;
end;

procedure TpFIBUpdateObject.SetOrderInList(Value:Integer);
begin
 FOrderInList:=Value;
 if  FDataSet<>nil then TpFIBDataSet(FDataSet).AddUpdateObject(Self)
end;

procedure TpFIBUpdateObject.SetKindUpdate(Value:TUpdateKind);
begin
 if Value=FKindUpdate then Exit;
 if  FDataSet<>nil then
 begin
  TpFIBDataSet(FDataSet).RemoveUpdateObject(Self);
  FKindUpdate:=Value;
  TpFIBDataSet(FDataSet).AddUpdateObject(Self);
 end
 else FKindUpdate:=Value;
end;

procedure    TpFIBUpdateObject.ChangeOrderInList(NewOrder:integer);
begin
// run only from FdataSet.SynhroOrdersUO
  FOrderInList:=NewOrder  ;
end;

procedure   TpFIBUpdateObject.Apply;
begin
 if not Active or (FDataSet=nil) or EmptyStrings(SQL) then Exit;
 if not (FDataSet is TpFibDataSet) then
  raise Exception.Create(
   Format(SFIBErrorNotDataSetDetail, [Self.Name, FDataSet.Name])
  );
 with TpFibDataSet(FDataSet) do
 begin
 {$IFDEF D_XE4}
  ExecUpdateObjects(FKindUpdate,Pointer(ActiveBuffer),FExecuteOrder);
 {$ELSE}
  ExecUpdateObjects(FKindUpdate,ActiveBuffer,FExecuteOrder);
 {$ENDIF}
 end;
end;


end.
