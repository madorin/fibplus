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
{    Written by Serge Buzadzhy                                  }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

unit FIBClientDataSet;

interface

{$I FIB.inc}

uses
  FIBInterfaces, SysUtils, Classes,
  Db, DbConsts, DBClient, Provider, DSIntf, MidConst, FMTBcd, Variants;

{$T-,H+,X+}

type

  TOnApplyUpdateKind = (aukBefore, aukAfter);

  TFIBClientDataSet = class(TClientDataSet, ISQLObject)
  protected
    function ExecuteServerCommand(const Command: string): OleVariant;
    function GetFieldClass(FieldType: TFieldType): TFieldClass; override;
{$IFNDEF C24}
    procedure DataConvert(Field: TField; Source, Dest: Pointer; ToNative: Boolean); override;
{$ENDIF}
    // ISQLObject
    function ParamCount: integer;
    function ParamName(ParamIndex: integer): string;
    function FieldsCount: integer;
    function FieldExist(const FieldName: string; var FieldIndex: integer): Boolean;
    function ParamExist(const ParamName: string; var ParamIndex: integer): Boolean;
    function FieldValue(const FieldName: string; Old: Boolean): variant; overload;
    function FieldValue(const FieldIndex: integer; Old: Boolean): variant; overload;
    function ParamValue(const ParamName: string): variant; overload;
    function ParamValue(const ParamIndex: integer): variant; overload;
    procedure SetParamValue(const ParamIndex: integer; aValue: variant);
    function FieldName(FieldIndex: integer): string;
    function IEof: Boolean;
    procedure INext;
    //
  public
    procedure OpenWP(ParamValues: array of variant);
    procedure Commit;
    procedure RollBack;
    function TransactionIsActive: Boolean;
  end;

  TFIBClientBCDField = class(TBCDField)
  private
    function GetScaledValue(var Value: Int64): Boolean;
    procedure SetScaledValue(Value: Int64);
  protected
{$IFDEF C24}
    procedure CopyData(Source, Dest: TValueBuffer); overload; override;
    function GetAsBCD: TBcd; override;
{$ENDIF}
    function GetAsCurrency: Currency; override;
    function GetAsFloat: Double; override;

    function GetAsExtended: Extended; override;
    function GetAsString: string; override;
    function GetAsInt64: Int64; virtual;
    function GetAsVariant: variant; override;
    procedure SetAsFloat(Value: Double); override;

    procedure SetAsExtended(Value: Extended); override;
    procedure SetAsString(const Value: string); override;
    procedure SetAsCurrency(Value: Currency); override;
    procedure SetAsInt64(Value: Int64); virtual;
    procedure SetVarValue(const Value: variant); override;
    procedure GetText(var Text: string; DisplayText: Boolean); override;
  public
    procedure Assign(Source: TPersistent); override;
    property AsExtended: Extended read GetAsExtended write SetAsExtended;
    property AsInt64: Int64 read GetAsInt64 write SetAsInt64;
    property Value: Extended read GetAsExtended write SetAsExtended;
  end;

  TFIBDataSetProvider = class(TDataSetProvider)
  protected
    function FindRecord(Source, Delta: TDataSet; UpdateMode: TUpdateMode): Boolean; override;
    procedure UpdateRecord(Source, Delta: TDataSet; BlobsOnly, KeyOnly: Boolean); override;
    function CreateResolver: TCustomResolver; override;
  end;

implementation

uses
  StdFuncs;

type
  TFIBDataSetResolver = class(TDataSetResolver)
  private
    procedure PutRecord(Tree: TUpdateTree);
  protected
    procedure InternalBeforeResolve(Tree: TUpdateTree); override;
    procedure DoUpdate(Tree: TUpdateTree); override;
    procedure DoDelete(Tree: TUpdateTree); override;
    procedure DoInsert(Tree: TUpdateTree); override;

  end;

  TFIBSQLResolver = class(TSQLResolver)
  protected
  end;

  { TFIBClientDataSet }

function TFIBClientDataSet.ExecuteServerCommand(const Command: string): OleVariant;
var
  DummyOwnerData: OleVariant;
begin
  Result := Unassigned;
  if Assigned(AppServer) then
    AppServer.AS_Execute(ProviderName, Command, Result, DummyOwnerData);
end;

procedure TFIBClientDataSet.Commit;
begin
  ExecuteServerCommand(FIBCommitCommand);
end;

procedure TFIBClientDataSet.RollBack;
begin
  ExecuteServerCommand(FIBRollbackCommand);
end;

function TFIBClientDataSet.TransactionIsActive: Boolean;
var
  OutParams: TParams;
begin
  Result := False;
  if not Assigned(AppServer) then
    Exit;
  OutParams := TParams.Create;
  try
    UnpackParams(ExecuteServerCommand(FIBInTransactionCommand), OutParams);
    Result := OutParams.ParamByName(FIBInTransactionParam).AsBoolean;
  finally
    OutParams.Free;
  end;
end;

{$IFNDEF C24}
// Before XE3 TFIBClientBCDField gets and sets its value scaled by Size through this conversion;
// XE3+ converts through the TValueBuffer overload and the field converts the native value itself
procedure TFIBClientDataSet.DataConvert(Field: TField; Source, Dest: Pointer; ToNative: Boolean);
var
  Scale: byte;
begin
  if (Field.DataType <> ftBCD) or (Field.Size = 4) then
    inherited DataConvert(Field, Source, Dest, ToNative)
  else if ToNative then
    Int64ToBCD(Int64(Source^), Field.Size, TBcd(Dest^))
  else if not BCDToInt64WithScale(TBcd(Source^), Int64(Dest^), Scale) then
    raise EOverFlow.CreateFmt(SFieldOutOfRange, [Field.DisplayName]);

end;
{$ENDIF}

function TFIBClientDataSet.FieldExist(const FieldName: string; var FieldIndex: integer): Boolean;
var
  tf: TField;
begin
  tf := FindField(FieldName);
  Result := Assigned(tf);
  if Result then
    FieldIndex := tf.Index;
end;

function TFIBClientDataSet.FieldName(FieldIndex: integer): string;
begin
  Result := Fields[FieldIndex].FieldName;
end;

function TFIBClientDataSet.FieldsCount: integer;
begin
  Result := FieldCount
end;

function TFIBClientDataSet.FieldValue(const FieldName: string; Old: Boolean): variant;
var
  tf: TField;
begin
  tf := FieldByName(FieldName);
  if Old then
    Result := tf.OldValue
  else
    Result := tf.Value
end;

function TFIBClientDataSet.FieldValue(const FieldIndex: integer; Old: Boolean): variant;
var
  tf: TField;
begin
  tf := Fields[FieldIndex];
  if Old and (State <> dsInsert) then
    Result := tf.OldValue
  else
    Result := tf.Value
end;

function TFIBClientDataSet.GetFieldClass(FieldType: TFieldType): TFieldClass;
begin
  case FieldType of
    ftBCD: Result := TFIBClientBCDField;
  else
    Result := inherited GetFieldClass(FieldType)
  end
end;

function TFIBClientDataSet.IEof: Boolean;
begin
  Result := Eof;
end;

procedure TFIBClientDataSet.INext;
begin
  Next
end;

procedure TFIBClientDataSet.OpenWP(ParamValues: array of variant);
var
  i: integer;
  pc: integer;
begin
  // Exec Query with ParamValues
  if High(ParamValues) < Pred(Params.Count) then
    pc := High(ParamValues)
  else
    pc := Pred(Params.Count);
  for i := Low(ParamValues) to pc do
    Params[i].Value := ParamValues[i];
  Open
end;

function TFIBClientDataSet.ParamCount: integer;
begin
  Result := Params.Count
end;

function TFIBClientDataSet.ParamExist(const ParamName: string; var ParamIndex: integer): Boolean;
var
  par: TParam;
begin
  par := Params.FindParam(ParamName);
  Result := par <> nil;
  if Result then
    ParamIndex := par.Index
end;

function TFIBClientDataSet.ParamName(ParamIndex: integer): string;
begin
  Result := Params[ParamIndex].Name;
end;

function TFIBClientDataSet.ParamValue(const ParamIndex: integer): variant;
begin
  Result := Params[ParamIndex].Value
end;

function TFIBClientDataSet.ParamValue(const ParamName: string): variant;
begin
  Result := Params.ParamByName(ParamName).Value
end;

procedure TFIBClientDataSet.SetParamValue(const ParamIndex: integer; aValue: variant);
begin
  Params[ParamIndex].Value := aValue;
end;

{ TFIBClientBCDField }

{$IFDEF C24}
// The native value of a BCD field; TField.GetData/SetData(Pointer) are deprecated (XE3+)
function GetBcdData(Field: TField; var Value: TBcd): Boolean;
var
  Data: TValueBuffer;
begin
  SetLength(Data, SizeOf(TBcd));
  Result := Field.GetData(Data);
  if Result then
    Move(Data[0], Value, SizeOf(TBcd));
end;

procedure SetBcdData(Field: TField; const Value: TBcd);
var
  Data: TValueBuffer;
begin
  SetLength(Data, SizeOf(TBcd));
  Move(Value, Data[0], SizeOf(TBcd));
  Field.SetData(Data);
end;

// While the field is validated GetData copies the value given to SetData, here the native TBcd
// (TBCDField copies a Currency)
procedure TFIBClientBCDField.CopyData(Source, Dest: TValueBuffer);
begin
  Move(Source[0], Dest[0], Min(SizeOf(TBcd), Min(Length(Source), Length(Dest))));
end;

// TBCDField.GetAsBCD (through Currency) from the native value, also while the field is validated
function TFIBClientBCDField.GetAsBCD: TBcd;
var
  Bcd: TBcd;
begin
  if GetBcdData(Self, Bcd) then
    CurrToBCD(BCDToCurrency(Bcd), Result)
  else
    Result := NullBcd;
end;
{$ENDIF}

// The value scaled by Size, for Size 4 the Currency bits (as TDataSet.DataConvert converts it)
function TFIBClientBCDField.GetScaledValue(var Value: Int64): Boolean;
{$IFDEF C24}
var
  Bcd: TBcd;
  Scale: Byte;
begin
  Result := GetBcdData(Self, Bcd);
  if not Result then
    Exit;
  if Size = 4 then
    begin
      if not BCDToCurr(Bcd, PCurrency(@Value)^) then
        raise EOverFlow.CreateFmt(SFieldOutOfRange, [DisplayName]);
    end
  else if not BCDToInt64WithScale(Bcd, Value, Scale) then
    raise EOverFlow.CreateFmt(SFieldOutOfRange, [DisplayName]);
end;
{$ELSE}
begin
  Result := GetData(@Value, False);
end;
{$ENDIF}

procedure TFIBClientBCDField.SetScaledValue(Value: Int64);
{$IFDEF C24}
var
  Bcd: TBcd;
begin
  FillChar(Bcd, SizeOf(Bcd), 0);
  if Size = 4 then
    CurrToBCD(PCurrency(@Value)^, Bcd, 32, Size)
  else
    Int64ToBCD(Value, Size, Bcd);
  SetBcdData(Self, Bcd);
end;
{$ELSE}
begin
  SetData(@Value, False);
end;
{$ENDIF}

procedure TFIBClientBCDField.Assign(Source: TPersistent);
begin
  if Source = nil then
    Clear
  else if Source is TField then
    Value := TField(Source).Value
  else
    inherited Assign(Source);
end;

function TFIBClientBCDField.GetAsCurrency: Currency;
begin
  Result := GetAsExtended
end;

function TFIBClientBCDField.GetAsExtended: Extended;
var
  C: Int64;
begin
  if GetScaledValue(C) then
    Result := C * E10[-Size]
  else
    Result := 0
end;

function TFIBClientBCDField.GetAsFloat: Double;
var
  C: Int64;
begin
  if GetScaledValue(C) then
    Result := C * E10[-Size]
  else
    Result := 0
end;

function TFIBClientBCDField.GetAsInt64: Int64;
begin
  if GetScaledValue(Result) then
    if Size <> 0 then
      Result := Round(Result * E10[-Size])
    else
  else
    Result := 0
end;

function TFIBClientBCDField.GetAsString: string;
var
  C: Int64;
begin
{$IFDEF C24}with FormatSettings do {$ENDIF}
    if GetScaledValue(C) then
      Result := Int64WithScaleToStr(C, Size, DecimalSeparator)
    else
      Result := '';
end;

function TFIBClientBCDField.GetAsVariant: variant;
begin
  if IsNull then
    Result := Null
  else
    case Size of
      0: Result := AsInt64;
      4: Result := asCurrency
    else
      Result := AsExtended
    end
end;

procedure TFIBClientBCDField.GetText(var Text: string; DisplayText: Boolean);
var
  Format: TFloatFormat;
  Digits: integer;
  FmtStr: string;
  C: Int64;
begin
{$IFDEF C24}with FormatSettings do {$ENDIF}
    try
      if GetScaledValue(C) then
      begin
        if DisplayText or (EditFormat = '') then
          FmtStr := DisplayFormat
        else
          FmtStr := EditFormat;
        if FmtStr = '' then
        begin
          if Currency then
          begin
            Digits := CurrencyDecimals;
            if DisplayText then
              Format := ffCurrency
            else
              Format := ffFixed;
            Text := CurrToStrF(C * E10[-Size], Format, Digits);
          end
          else
          begin
            Digits := Size;
            Text := Int64WithScaleToStr(C, Digits, DecimalSeparator)
          end;
        end
        else if Size = 4 then
          Text := FormatCurr(FmtStr, C * E10[-Size])
        else
        begin
          Text := FormatNumericString(FmtStr, Int64WithScaleToStr(C, Size, DecimalSeparator));
        end;
      end
      else
        Text := '';
    except
      on E: Exception do
        Text := SBCDOverflow;
    end;
end;

procedure TFIBClientBCDField.SetAsCurrency(Value: Currency);
begin
  SetAsExtended(Value)
end;

procedure TFIBClientBCDField.SetAsExtended(Value: Extended);
var
  RndComp: Comp;
begin
  try
    RndComp := Value * E10[Size];
    SetScaledValue(PInt64(@RndComp)^);
  except
    raise
  end;
end;

procedure TFIBClientBCDField.SetAsFloat(Value: Double);
begin
  SetAsExtended(Value);
end;

procedure TFIBClientBCDField.SetAsInt64(Value: Int64);
begin
  SetScaledValue(Value)
end;

procedure TFIBClientBCDField.SetAsString(const Value: string);
begin
  if Value = '' then
    Clear
  else if (Size = 0) then
    SetAsInt64(StrToInt64(Value))
  else
    SetAsExtended(StrToFloat(Value))
end;

procedure TFIBClientBCDField.SetVarValue(const Value: variant);
begin
  case VarType(Value) of
    varEmpty, varNull: Clear;
    varString, varOleStr, varUString:
      AsString := Value;
    varSmallint, varInteger, varWord, varLongWord: AsInteger := Value;
    varInt64: AsInt64 := Value
  else
    AsExtended := Value;
  end
end;

{ TFIBDataSetProvider }

function TFIBDataSetProvider.CreateResolver: TCustomResolver;
begin
  if ResolveToDataSet then
    Result := TFIBDataSetResolver.Create(Self)
  else
    Result := TFIBSQLResolver.Create(Self);
end;

type
  TUnprotectedPacketDataSet = class(TPacketDataSet);

function TFIBDataSetProvider.FindRecord(Source, Delta: TDataSet; UpdateMode: TUpdateMode): Boolean;

  procedure GetFieldList(DataSet: TDataSet; UpdateMode: TUpdateMode; List: TList);
  var
    i: integer;
  begin
    for i := 0 to DataSet.FieldCount - 1 do
      with DataSet.Fields[i] do
      begin
        if (DataType in [ftBytes, ftVarBytes]) or IsBlob or (DataSet.Fields[i] is TObjectField) then
          continue;
        case UpdateMode of
          upWhereKeyOnly:
            if pfInKey in ProviderFlags then
              List.Add(DataSet.Fields[i]);
          upWhereAll:
            if pfInWhere in ProviderFlags then
              List.Add(DataSet.Fields[i]);
          upWhereChanged:
            if (pfInKey in ProviderFlags) or (not VarIsEmpty(NewValue)) then
              List.Add(DataSet.Fields[i]);
        end;
      end;
  end;

var
  i: integer;
  KeyValues: variant;
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
          if (TField(FieldList[i]) is TBCDField) and (TBCDField(FieldList[i]).Size <> 4) then
            KeyValues[i] := BCDFieldAsString(TField(FieldList[i]), IsDelta)
          else if IsDelta then
            KeyValues[i] := OldValue
          else
            KeyValues[i] := Value;
          if Fields <> '' then
            Fields := Fields + ';';
          Fields := Fields + FieldName;
        end;
      Result := Source.Locate(Fields, KeyValues, []);
    end
    else if FieldList.Count = 1 then
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

procedure TFIBDataSetProvider.UpdateRecord(Source, Delta: TDataSet; BlobsOnly, KeyOnly: Boolean);
var
  Field: TField;
  i: integer;
  UseUpMode: TUpdateMode;
  BcdValue: TBcd;
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
        if (Field <> nil) and (not BlobsOnly or (Field.IsBlob and VarIsNull(Fields[i].NewValue))) then
          if Fields[i].DataType <> ftBCD then
            Fields[i].Assign(Field)
          else
          begin
            // main changes:
            GetBCDFieldData(Field, False, BcdValue);
{$IFDEF C24}
            SetBcdData(Fields[i], BcdValue)
{$ELSE}
            Fields[i].SetData(@BcdValue)
{$ENDIF}
          end;
      end;
      Post;
    end;
  end;
end;

{ TFIBDataSetResolver }

type
  TUnprotectedUpdateTree = class(TUpdateTree);

procedure TFIBDataSetResolver.DoDelete(Tree: TUpdateTree);
begin
  with TUnprotectedUpdateTree(Tree) do
  begin
    if TFIBDataSetProvider(Provider).FindRecord(Source, Delta, Provider.UpdateMode) then
      Source.Delete
    else
      DatabaseError(SRecordChanged);
  end;

end;

procedure TFIBDataSetResolver.DoInsert(Tree: TUpdateTree);
begin
  TUnprotectedUpdateTree(Tree).Source.Append;
  PutRecord(Tree);
end;

procedure TFIBDataSetResolver.DoUpdate(Tree: TUpdateTree);
begin
  with TUnprotectedUpdateTree(Tree) do
  begin
    if not TFIBDataSetProvider(Provider).FindRecord(Source, Delta, Provider.UpdateMode) then
      DatabaseError(SRecordChanged);
    Source.Edit;
    PutRecord(Tree);
  end;
end;

procedure TFIBDataSetResolver.InternalBeforeResolve(Tree: TUpdateTree);
begin
  with TUnprotectedUpdateTree(Tree) do
    TFIBDataSetProvider(Provider).FindRecord(Source, Delta, Provider.UpdateMode);
end;

procedure TFIBDataSetResolver.PutRecord(Tree: TUpdateTree);

procedure PutField(Src, Dest: TField); forward;

  procedure PutObjectField(Src, Dest: TObjectField);
  var
    i: integer;
  begin
    if VarIsNull(Src.NewValue) then
      Dest.Clear
    else
      for i := 0 to Src.FieldCount - 1 do
        if (not VarIsEmpty(Src.Fields[i].NewValue)) and (pfInUpdate in Src.Fields[i].ProviderFlags) then
          PutField(Src.Fields[i], Dest.Fields[i]);
  end;

  procedure PutField(Src, Dest: TField);
  begin
    if (Src.DataType in [ftArray, ftADT]) then
      PutObjectField(TObjectField(Src), TObjectField(Dest))
    else if (Src.DataType in [ftDataSet, ftReference]) then
      raise Exception.CreateRes(@SNoDataSets)
    else if (not VarIsEmpty(Src.NewValue)) and (pfInUpdate in Src.ProviderFlags) then
      Dest.Assign(Src);
  end;

var
  i: integer;
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

end.
