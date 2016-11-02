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

unit pFIBClientDataSet;

interface

{$I FIBPlus.inc}

uses
  pFIBInterfaces, SysUtils, Classes,
  Db, DbConsts, DBClient, Provider, DSIntf, MidConst
  {$IFDEF D6+},FMTBcd, Variants{$ENDIF};

{$T-,H+,X+}

type

  TOnApplyUpdateKind =(aukBefore,aukAfter);

  TpFIBClientDataSet = class(TClientDataSet,ISQLObject)
  protected
    function  GetFieldClass(FieldType: TFieldType): TFieldClass; override;
    procedure DataConvert(Field: TField; Source, Dest: Pointer; ToNative: Boolean); override;
//ISQLObject
   function  ParamCount:integer;
   function  ParamName(ParamIndex:integer):string;
   function  FieldsCount:integer;
   function  FieldExist(const FieldName:string; var FieldIndex:integer):boolean;
   function  ParamExist(const ParamName:string; var ParamIndex:integer):boolean;
   function  FieldValue(const FieldName:string; Old:boolean):variant;   overload;
   function  FieldValue(const FieldIndex:integer;Old:boolean):variant; overload;
   function  ParamValue(const ParamName:string):variant;   overload;
   function  ParamValue(const ParamIndex:integer):variant; overload;
   procedure SetParamValue(const ParamIndex:integer; aValue:Variant);
   function  FieldName(FieldIndex:integer):string;
   function  IEof:boolean;
   procedure INext;
//
  public
    procedure   OpenWP(ParamValues: array of Variant);
    procedure   Commit;
    procedure   RollBack;
    function    TransactionIsActive:boolean;
  end;

  TpFIBClientBCDField=class (TBCDField)
  private
  protected
     function  GetAsCurrency: Currency; override;
     function  GetAsFloat: Double; override;

{$IFNDEF NO_USE_COMP}
     function  GetAsComp : Comp  ;  virtual;
     procedure SetAsComp(Value: comp); virtual;
{$ENDIF}
     function  GetAsExtended: Extended;  {$IFNDEF D2009+} virtual{$ELSE} override {$ENDIF};
     function  GetAsString: string; override;
     function  GetAsInt64: Int64; virtual;
     function  GetAsVariant: Variant; override;
     procedure SetAsFloat(Value: Double); override;

     procedure SetAsExtended(Value: Extended); {$IFNDEF D2009+} virtual{$ELSE} override {$ENDIF};
     procedure SetAsString(const Value: string); override;
     procedure SetAsCurrency(Value: Currency); override;
     procedure SetAsInt64(Value: Int64); virtual;
     procedure SetVarValue(const Value: Variant); override;
     procedure GetText(var Text: string; DisplayText: Boolean); override;
  public
     procedure Assign(Source: TPersistent); override;
     property AsExtended :Extended read GetAsExtended write SetAsExtended;
     property AsInt64    :Int64    read GetAsInt64    write SetAsInt64;
{$IFNDEF NO_USE_COMP}
     property AsComp     :Comp     read GetAsComp     write SetAsComp;
{$ENDIF}     
     property Value      :Extended read GetAsExtended write SetAsExtended;
  end;

  TpFIBDataSetProvider = class(TDataSetProvider)
  protected
    function FindRecord(Source, Delta: TDataSet; UpdateMode: TUpdateMode): Boolean; {$IFDEF D2005+}override;{$ENDIF}
    procedure UpdateRecord(Source, Delta: TDataSet; BlobsOnly, KeyOnly: Boolean); override;
    function CreateResolver: TCustomResolver; override;
  end;


procedure Register;

implementation

{$R fibplus_midas.dcr}

uses StdFuncs;

type
  TpFIBDataSetResolver = class(TDataSetResolver)
  private
    procedure PutRecord(Tree: TUpdateTree);
  protected
    procedure InternalBeforeResolve(Tree: TUpdateTree); override;
    procedure DoUpdate(Tree: TUpdateTree); override;
    procedure DoDelete(Tree: TUpdateTree); override;
    procedure DoInsert(Tree: TUpdateTree); override;

  end;


  TpFIBSQLResolver = class(TSQLResolver)
  protected
  end;

{ TpFIBClientDataSet }

procedure TpFIBClientDataSet.Commit;
var
  DummyOwnerData: OleVariant;
  DummyParams   : OleVariant;
begin
   if Assigned(AppServer) then
    AppServer.AS_Execute(ProviderName, 'FIB$COMMIT', DummyParams, DummyOwnerData);
end;

procedure   TpFIBClientDataSet.RollBack;
var
  DummyOwnerData: OleVariant;
  DummyParams   : OleVariant;
begin
   if Assigned(AppServer) then
    AppServer.AS_Execute(ProviderName, 'FIB$ROLLBACK', DummyParams, DummyOwnerData);
end;

function TpFIBClientDataSet.TransactionIsActive: boolean;
var
  DummyOwnerData: OleVariant;
  Params   : OleVariant;
  v:Variant;
begin
  if Assigned(AppServer) then
  begin
   AppServer.AS_Execute(ProviderName, 'FIB$GET_INTRANSACTION', Params, DummyOwnerData);
   v:=Params[0];
   Result:=v[1];
  end
  else
   Result:=False
end;


procedure TpFIBClientDataSet.DataConvert(Field: TField; Source,
  Dest: Pointer; ToNative: Boolean);
var
 Scale :byte;
begin
 if  (Field.DataType<>ftBCD) or (Field.Size=4)
 then
   inherited DataConvert(Field,Source,  Dest,ToNative)
 else
   if ToNative then
        Int64ToBCD(Int64(Source^), Field.Size, TBcd(Dest^))
   else
    if not BCDToInt64WithScale(TBcd(Source^), Int64(Dest^),Scale ) then
        raise EOverFlow.CreateFmt(SFieldOutOfRange, [Field.DisplayName]);

end;



function TpFIBClientDataSet.FieldExist(const FieldName: string;
  var FieldIndex: integer): boolean;
var
  tf:TField;
begin
 tf:=FindField(FieldName);
 Result:= Assigned(tf);
 if Result then
  FieldIndex:=tf.Index;
end;

function TpFIBClientDataSet.FieldName(FieldIndex: integer): string;
begin
  Result:=Fields[FieldIndex].FieldName;
end;

function TpFIBClientDataSet.FieldsCount: integer;
begin
  Result:=FieldCount
end;

function TpFIBClientDataSet.FieldValue(const FieldName: string;
  Old: boolean): variant;
var
  tf:TField;
begin
 tf:=FieldByName(FieldName);
 if Old then
  Result:= tf.OldValue
 else
  Result:= tf.Value
end;

function TpFIBClientDataSet.FieldValue(const FieldIndex: integer;
  Old: boolean): variant;
var
  tf:TField;
begin
 tf:=Fields[FieldIndex];
 if Old and (State<>dsInsert) then
  Result:= tf.OldValue
 else
  Result:= tf.Value
end;

function TpFIBClientDataSet.GetFieldClass(
  FieldType: TFieldType): TFieldClass;
begin
 case FieldType of
  ftBCD :  Result:=TpFIBClientBCDField;
 else
  Result:=inherited GetFieldClass( FieldType)
 end
end;

function TpFIBClientDataSet.IEof: boolean;
begin
 Result:=Eof;
end;

procedure TpFIBClientDataSet.INext;
begin
  Next
end;

procedure TpFIBClientDataSet.OpenWP(ParamValues: array of Variant);
var i :integer;
    pc:integer;
begin
// Exec Query with ParamValues
 if High(ParamValues)<Pred(Params.Count) then
  pc:=High(ParamValues)
 else
  pc:=Pred(Params.Count);
 for i:=Low(ParamValues)  to pc do
  Params[i].Value:=ParamValues[i];
 Open
end;

function TpFIBClientDataSet.ParamCount: integer;
begin
 Result:=Params.Count
end;

function TpFIBClientDataSet.ParamExist(const ParamName: string;
  var ParamIndex: integer): boolean;
var
   par:TParam;
begin
 par:=Params.FindParam(ParamName);
 Result :=par<>nil;
 if Result then
  ParamIndex:=par.Index
end;

function TpFIBClientDataSet.ParamName(ParamIndex: integer): string;
begin
 Result:=Params[ParamIndex].Name;
end;

function TpFIBClientDataSet.ParamValue(const ParamIndex: integer): variant;
begin
 Result:=Params[ParamIndex].Value
end;

function TpFIBClientDataSet.ParamValue(const ParamName: string): variant;
begin
 Result:=Params.ParamByName(ParamName).Value
end;

procedure TpFIBClientDataSet.SetParamValue(const ParamIndex: integer;
  aValue: Variant);
begin
  Params[ParamIndex].Value:=aValue;
end;


{ TpFIBClientBCDField }

procedure TpFIBClientBCDField.Assign(Source: TPersistent);
begin
  if Source = nil then
    Clear
  else
  if Source is TField then
    Value := TField(Source).Value
  else
    inherited Assign(Source);
end;

{$IFNDEF NO_USE_COMP}
function TpFIBClientBCDField.GetAsComp: Comp;
begin
 Result:=GetAsExtended
end;

procedure TpFIBClientBCDField.SetAsComp(Value: comp);
begin
 SetData(@Value,False)
end;

{$ENDIF}

function TpFIBClientBCDField.GetAsCurrency: Currency;
begin
 Result:=GetAsExtended
end;

function TpFIBClientBCDField.GetAsExtended: Extended;
var C:Int64;
begin
 if GetData(@C, False) then
  Result:=C*E10[-Size]
 else
  Result:=0
end;

function TpFIBClientBCDField.GetAsFloat: Double;
var C:Comp;
begin
 if GetData(@C, False) then
  Result:=C*E10[-Size]
 else
  Result:=0
end;

function TpFIBClientBCDField.GetAsInt64: Int64;
begin
 if GetData(@Result, False) then
  if Size<>0 then
     Result:=Round(Result*E10[-Size])
  else   
 else
  Result:=0
end;

function TpFIBClientBCDField.GetAsString: string;
var C:Int64;
begin
 {$IFDEF D_XE3}with FormatSettings do{$ENDIF}
 if GetData(@C, False) then
  Result := Int64WithScaleToStr(C,Size,DecimalSeparator) else Result := '';
end;

function TpFIBClientBCDField.GetAsVariant: Variant;
begin
 case Size of
 0:
  {$IFDEF D6+}
   Result:= asInt64;
  {$ELSE}
   {$IFDEF NO_USE_COMP}
    Result:= asInteger ;
   {$ELSE}
    Result:= asComp ;
   {$ENDIF}

  {$ENDIF}
 4:
  Result:= asCurrency
 else
  Result:= asExtended
 end 
end;

procedure TpFIBClientBCDField.GetText(var Text: string;
  DisplayText: Boolean);
var
  Format: TFloatFormat;
  Digits: Integer;
  FmtStr: string;
  C: Int64;
begin
 {$IFDEF D_XE3}with FormatSettings do{$ENDIF}
  try
    if GetData(@C, False) then
    begin
      if DisplayText or (EditFormat = '') then
        FmtStr := DisplayFormat else
        FmtStr := EditFormat;
      if FmtStr = '' then
      begin
        if currency then
        begin
         Digits := CurrencyDecimals;
         if DisplayText then Format := ffCurrency else Format := ffFixed;
         Text := CurrToStrF(C*E10[-Size], Format, Digits);
        end
        else
        begin
          Digits := Size;
          Text := Int64WithScaleToStr(C,Digits,DecimalSeparator)
        end;
      end
      else
      if Size=4 then
       Text := FormatCurr(FmtStr, C*E10[-Size])
      else
      begin
        {$IFNDEF D6+}
          Text := FormatFloat(FmtStr, RoundExtend(C*E10[-Size],Size));
        {$ELSE}
          Text := FormatNumericString(FmtStr,Int64WithScaleToStr(C,Size,DecimalSeparator));
        {$ENDIF}
      end;
    end
    else
      Text := '';
  except
    on E: Exception do
      Text := SBCDOverflow;
  end;
end;


procedure TpFIBClientBCDField.SetAsCurrency(Value: Currency);
begin
  SetAsExtended(Value)
end;

procedure TpFIBClientBCDField.SetAsExtended(Value: Extended);
var
 RndComp :Comp;
begin
  try
   RndComp :=Value*E10[Size];
   SetData(@RndComp,False);   
  except
   raise 
  end;
end;

procedure TpFIBClientBCDField.SetAsFloat(Value: Double);
begin
  SetAsExtended(Value);
end;

procedure TpFIBClientBCDField.SetAsInt64(Value: Int64);
begin
  SetData(@Value,False)
end;

procedure TpFIBClientBCDField.SetAsString(const Value: string);
begin
 if Value = '' then Clear else
  if (Size=0) then
   SetAsInt64(StrToInt64(Value))
  else
   SetAsExtended(StrToFloat(Value))
end;

procedure TpFIBClientBCDField.SetVarValue(const Value: Variant);
begin
 case VarType(Value) of
  varEmpty,varNull      : Clear;
  varString,varOleStr{$IFDEF D2009+},varUString{$ENDIF}    : AsString :=Value;
  varSmallint,varInteger{$IFDEF D6+},varWord, varLongWord{$ENDIF}: AsInteger:=Value;
  {$IFDEF D6+}
    varInt64            : AsInt64  :=Value
  {$ENDIF}
 else
  AsExtended :=Value;
 end
end;

{ TpFIBDataSetProvider }


function TpFIBDataSetProvider.CreateResolver: TCustomResolver;
begin
  if ResolveToDataSet then
    Result := TpFIBDataSetResolver.Create(Self) else
    Result := TpFIBSQLResolver.Create(Self);
end;

type TUnprotectedPacketDataSet =class(TPacketDataSet);

function TpFIBDataSetProvider.FindRecord(Source, Delta: TDataSet;
  UpdateMode: TUpdateMode): Boolean;

  procedure GetFieldList(DataSet: TDataSet; UpdateMode: TUpdateMode; List: TList);
  var
    i: Integer;
  begin
    for i := 0 to DataSet.FieldCount - 1 do
      with DataSet.Fields[i] do
      begin
        if (DataType in [ftBytes, ftVarBytes]) or IsBlob or
           (DataSet.Fields[i] is TObjectField) then continue;
        case UpdateMode of
          upWhereKeyOnly:
            if pfInKey in ProviderFlags then List.Add(DataSet.Fields[i]);
          upWhereAll:
            if pfInWhere in ProviderFlags then List.Add(DataSet.Fields[i]);
          upWhereChanged:
            if (pfInKey in ProviderFlags) or (not VarIsEmpty(NewValue)) then
              List.Add(DataSet.Fields[i]);
        end;
      end;
  end;

var
  i: Integer;
  KeyValues: Variant;
  Fields: string;
  FieldList: TList;
  IsDelta: LongBool;
begin
  Result := False;
  TUnprotectedPacketDataSet(Delta).DSBase.GetProp(DSPROPISDELTA, @IsDelta);
  FieldList := TList.Create;
  try
    GetFieldList(Delta, UpdateMode, FieldList);
    if FieldList.Count > 1 then
    begin
      KeyValues := VarArrayCreate([0, FieldList.Count - 1], varVariant);
      Fields := '';
      for i := 0 to FieldList.Count - 1 do
        with TField(FieldList[i]) do
        begin
         if (TField(FieldList[i]) is TBCDField) and
           (TBCDField(FieldList[i]).Size<>4)
         then
            KeyValues[i] := BCDFieldAsString(TField(FieldList[i]),IsDelta)
         else
          if IsDelta then
            KeyValues[i] := OldValue else
            KeyValues[i] := Value;
          if Fields <> '' then Fields := Fields + ';';
          Fields := Fields + FieldName;
        end;
      Result := Source.Locate(Fields, KeyValues, []);
    end
    else
    if FieldList.Count = 1 then
    begin
      with TField(FieldList[0]) do
        if IsDelta then
          Result := Source.Locate(FieldName, OldValue, [])
        else
          Result := Source.Locate(FieldName, Value, []);
    end
    else
      DatabaseError(SNoKeySpecified);
  finally
    FieldList.Free;
  end;
end;

procedure TpFIBDataSetProvider.UpdateRecord(Source, Delta: TDataSet;
  BlobsOnly, KeyOnly: Boolean);
var
  Field: TField;
  i: Integer;
  UseUpMode: TUpdateMode;
  BcdValue:TBcd;
begin
  if KeyOnly then
    UseUpMode := upWhereKeyOnly
  else
    UseUpMode := UpdateMode;
  if not FindRecord(Source, Delta, UseUpMode) then
    DatabaseError(SRecordChanged);
  begin
    if not FindRecord(Source, Delta, upWhereKeyOnly) then
      DatabaseError(SRecordChanged);
    with Delta do
    begin
      Edit;
      for i := 0 to FieldCount - 1 do
      begin
        Field := Source.FindField(Fields[i].FieldName);
        if (Field <> nil) and (not BlobsOnly or (Field.IsBlob and VarIsNull(Fields[i].NewValue)))
        then
         if Fields[i].DataType<>ftBcd then
          Fields[i].Assign(Field)
         else
         begin
//  main changes:        
          GetBCDFieldData(Field,False,BcdValue);
          Fields[i].SetData(@BcdValue)
         end;
      end;
      Post;
    end;
  end;
end;

{ TpFIBDataSetResolver }

type  TUnprotectedUpdateTree= class(TUpdateTree);

procedure TpFIBDataSetResolver.DoDelete(Tree: TUpdateTree);
begin
  with TUnprotectedUpdateTree(Tree) do
  begin
    if TpFIBDataSetProvider(Provider).FindRecord(Source, Delta, Provider.UpdateMode) then
      Source.Delete
    else
      DatabaseError(SRecordChanged);
  end;

end;

procedure TpFIBDataSetResolver.DoInsert(Tree: TUpdateTree);
begin
  TUnprotectedUpdateTree(Tree).Source.Append;
  PutRecord(Tree);
end;



procedure TpFIBDataSetResolver.DoUpdate(Tree: TUpdateTree);
begin
  with TUnprotectedUpdateTree(Tree) do
  begin
    if not TpFIBDataSetProvider(Provider).FindRecord(Source, Delta, Provider.UpdateMode) then
      DatabaseError(SRecordChanged);
    Source.Edit;
    PutRecord(Tree);
  end;
end;


procedure TpFIBDataSetResolver.InternalBeforeResolve(Tree: TUpdateTree);
begin
  with TUnprotectedUpdateTree(Tree) do
   TpFIBDataSetProvider(Provider).FindRecord(Source, Delta, Provider.UpdateMode);
end;


procedure TpFIBDataSetResolver.PutRecord(Tree: TUpdateTree);

  procedure PutField(Src, Dest: TField); forward;

  procedure PutObjectField(Src, Dest: TObjectField);
  var
    i: Integer;
  begin
    if VarIsNull(Src.NewValue) then
      Dest.Clear else
      for i := 0 to Src.FieldCount - 1 do
        if (not VarIsEmpty(Src.Fields[i].NewValue)) and
           (pfInUpdate in Src.Fields[i].ProviderFlags) then
          PutField(Src.Fields[i], Dest.Fields[i]);
  end;

  procedure PutField(Src, Dest: TField);
  begin
    if (Src.DataType in [ftArray, ftADT]) then
      PutObjectField(TObjectField(Src), TObjectField(Dest)) else
    if (Src.DataType in [ftDataSet, ftReference]) then
      raise Exception.CreateRes(Integer(@SNoDataSets)) else
    if (not VarIsEmpty(Src.NewValue)) and
       (pfInUpdate in Src.ProviderFlags) then
      Dest.Assign(Src);
  end;

var
  i: Integer;
  Field: TField;
begin
  with TUnprotectedUpdateTree(Tree) do
  try
    for i := 0 to Delta.FieldCount - 1 do
    begin
      Field := Source.FindField(Delta.Fields[i].FieldName);
      if (Field <> nil) then
        PutField(Delta.Fields[i], Field);
    end;
    Source.Post;
  except
    Source.Cancel;
    raise;
  end;
end;


// Register;
procedure Register;
begin
   RegisterClasses([TpFIBClientBCDField]);
   RegisterComponents('FIBPlus', [TpFIBClientDataSet,TpFIBDataSetProvider]);
end;




end.

