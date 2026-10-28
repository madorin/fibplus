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

unit FIBFieldsDescr;

interface

{$I FIB.inc}

uses
  Classes, IB_Externals;

type

  TAddedTypeFields = (atfStandard, atfGuidField, atfWideStringField);

  TFIBFieldDescr = packed record
    fdDataType: Short;
    fdDataScale: Short;
    fdNullable: Boolean;
    fdDataSize: Short;
    fdDataOfs: Integer;
    fdIsDBKey: Boolean;
    fdIsSeparateString: Boolean;
    fdStrIndex: Integer;
    fdAddedFields: TAddedTypeFields;
    fdSubType: Short;
    fdRelationTable: string;
    fdRelationField: string;
    fdTableAlias: string;

  end;

  PFIBFieldDescr = ^TFIBFieldDescr;

  TFIBFieldDescrList = class
  private
    vFieldInfoList: TList;
    function GetFieldInfo(Index: Integer): PFIBFieldDescr;
    function GetCapacity: Integer;
    procedure SetCapacity(aCapacity: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TFIBFieldDescrList);
    procedure Clear;
    function Add(afdDataType, afdDataScale, afdDataSize: Short;
      afdNullable, afdIsDBKey: Boolean; IsSeparateString: Boolean;
      aAddedType: TAddedTypeFields): Integer;
    procedure SaveToStream(Stream: TStream);
    procedure LoadFromStream(Stream: TStream; StreamVersion: Integer);

    property FieldInfo[Index: Integer]: PFIBFieldDescr read GetFieldInfo; default;
    property Capacity: Integer read GetCapacity write SetCapacity;
    property List: TList read vFieldInfoList;
  end;

implementation

// The names are in the system code page in the stream
procedure WriteName(Stream: TStream; const Name: string);
var
  Bytes: Ansistring;
  k: Integer;
begin
  Bytes := Ansistring(Name);
  k := Length(Bytes);
  Stream.WriteBuffer(k, SizeOf(Integer));
  if k > 0 then
    Stream.WriteBuffer(Bytes[1], k);
end;

function ReadName(Stream: TStream): string;
var
  Bytes: Ansistring;
  c: Integer;
begin
  Stream.ReadBuffer(c, SizeOf(Integer));
  SetLength(Bytes, c);
  if c > 0 then
    Stream.ReadBuffer(Bytes[1], c);
  Result := string(Bytes);
end;

{ TFIBFieldDescrList }

function TFIBFieldDescrList.Add(afdDataType, afdDataScale, afdDataSize: Short;
  afdNullable, afdIsDBKey: Boolean; IsSeparateString: Boolean;
  aAddedType: TAddedTypeFields): Integer;
var
  p: PFIBFieldDescr;
begin
  New(p);
  with p^ do
  begin
    fdDataType := afdDataType;
    fdDataScale := afdDataScale;
    fdNullable := afdNullable;
    fdDataSize := afdDataSize;
    fdIsDBKey := afdIsDBKey;
    fdIsSeparateString := IsSeparateString;
    fdAddedFields := aAddedType;
  end;
  Result := vFieldInfoList.Add(p)
end;

procedure TFIBFieldDescrList.Assign(Source: TFIBFieldDescrList);
var
  i: Integer;
begin
  if Source = Self then
    exit;
  Clear;
  vFieldInfoList.Capacity := Source.vFieldInfoList.Capacity;
  for i := 0 to Pred(Source.vFieldInfoList.Count) do
    with Source.FieldInfo[i]^ do
    begin
      Add(fdDataType, fdDataScale, fdDataSize, fdNullable, fdIsDBKey, fdIsSeparateString, fdAddedFields);
      PFIBFieldDescr(vFieldInfoList[i])^.fdDataOfs := fdDataOfs;
      PFIBFieldDescr(vFieldInfoList[i])^.fdStrIndex := fdStrIndex;

      PFIBFieldDescr(vFieldInfoList[i])^.fdSubType := fdSubType;
      PFIBFieldDescr(vFieldInfoList[i])^.fdRelationTable := fdRelationTable;
      PFIBFieldDescr(vFieldInfoList[i])^.fdRelationField := fdRelationField;
      PFIBFieldDescr(vFieldInfoList[i])^.fdTableAlias := fdTableAlias;

    end;
end;

procedure TFIBFieldDescrList.Clear;
var
  i: Integer;
begin
  with vFieldInfoList do
    for i := 0 to Pred(Count) do
    begin
      Finalize(PFIBFieldDescr(vFieldInfoList[i])^);
      FreeMem(vFieldInfoList[i], SizeOf(TFIBFieldDescr));
    end;
  vFieldInfoList.Clear;
end;

constructor TFIBFieldDescrList.Create;
begin
  inherited Create;
  vFieldInfoList := TList.Create;
end;

destructor TFIBFieldDescrList.Destroy;
begin
  Clear;
  vFieldInfoList.Free;
  inherited;
end;

function TFIBFieldDescrList.GetCapacity: Integer;
begin
  Result := vFieldInfoList.Capacity
end;

function TFIBFieldDescrList.GetFieldInfo(Index: Integer): PFIBFieldDescr;
begin
  Result := PFIBFieldDescr(vFieldInfoList.List[Index])
end;

procedure TFIBFieldDescrList.LoadFromStream(Stream: TStream; StreamVersion: Integer);
var
  i, c: Integer;
  p: PFIBFieldDescr;
begin
  Clear;
  Stream.ReadBuffer(c, SizeOf(Integer));
  Capacity := c;
  New(p);
  try
    for i := 0 to Pred(c) do
    begin
      if StreamVersion < 6 then
        Stream.ReadBuffer(p^, SizeOf(TFIBFieldDescr) - SizeOf(Boolean))
      else
        Stream.ReadBuffer(p^, SizeOf(TFIBFieldDescr) - SizeOf(Pstring) * 3);
      Add(p^.fdDataType, p^.fdDataScale, p^.fdDataSize, p^.fdNullable,
        p^.fdIsDBKey, p^.fdIsSeparateString, p^.fdAddedFields);
      FieldInfo[i]^.fdStrIndex := p^.fdStrIndex;
      FieldInfo[i]^.fdDataOfs := p^.fdDataOfs;
      FieldInfo[i]^.fdSubType := p^.fdSubType;
      with FieldInfo[i]^ do
      begin
        fdRelationTable := ReadName(Stream);
        fdRelationField := ReadName(Stream);
        fdTableAlias := ReadName(Stream);
      end
    end;
  finally
    FreeMem(p, SizeOf(TFIBFieldDescr))
  end;
end;

procedure TFIBFieldDescrList.SaveToStream(Stream: TStream);
var
  i: Integer;
begin
  Stream.WriteBuffer(vFieldInfoList.Count, SizeOf(Integer));
  for i := 0 to Pred(vFieldInfoList.Count) do
  begin
    Stream.WriteBuffer(PFIBFieldDescr(vFieldInfoList[i])^, SizeOf(TFIBFieldDescr) - SizeOf(Pstring) * 3);
    WriteName(Stream, PFIBFieldDescr(vFieldInfoList[i])^.fdRelationTable);
    WriteName(Stream, PFIBFieldDescr(vFieldInfoList[i])^.fdRelationField);
    WriteName(Stream, PFIBFieldDescr(vFieldInfoList[i])^.fdTableAlias);
  end;
end;

procedure TFIBFieldDescrList.SetCapacity(aCapacity: Integer);
begin
  vFieldInfoList.Capacity := aCapacity
end;

end.
