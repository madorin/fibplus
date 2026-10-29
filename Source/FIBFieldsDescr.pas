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

uses
  FIBPlatforms, FIBProps;

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
  Result := Integer(vFieldInfoList.Add(p))
end;

procedure TFIBFieldDescrList.Assign(Source: TFIBFieldDescrList);
var
  i: TFIBListIndex;
  Dest: PFIBFieldDescr;
begin
  if Source = Self then
    exit;
  Clear;
  vFieldInfoList.Capacity := Source.vFieldInfoList.Capacity;
  for i := 0 to Source.vFieldInfoList.Count - 1 do
    with PFIBFieldDescr(Source.vFieldInfoList[i])^ do
    begin
      Add(fdDataType, fdDataScale, fdDataSize, fdNullable, fdIsDBKey, fdIsSeparateString, fdAddedFields);
      Dest := vFieldInfoList[i];
      Dest^.fdDataOfs := fdDataOfs;
      Dest^.fdStrIndex := fdStrIndex;
      Dest^.fdSubType := fdSubType;
      Dest^.fdRelationTable := fdRelationTable;
      Dest^.fdRelationField := fdRelationField;
      Dest^.fdTableAlias := fdTableAlias;
    end;
end;

procedure TFIBFieldDescrList.Clear;
var
  i: TFIBListIndex;
begin
  for i := 0 to vFieldInfoList.Count - 1 do
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
  Result := Integer(vFieldInfoList.Capacity)
end;

function TFIBFieldDescrList.GetFieldInfo(Index: Integer): PFIBFieldDescr;
begin
  Result := PFIBFieldDescr(vFieldInfoList.List[Index])
end;

procedure TFIBFieldDescrList.LoadFromStream(Stream: TStream; StreamVersion: Integer);
var
  i, c: Integer;
  p: PFIBFieldDescr;
  UTF8: Boolean;
begin
  Clear;
  // version 7 has the names in the system code page
  UTF8 := StreamVersion >= 8;
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
        fdRelationTable := ReadUTF8StrFromStream(Stream, UTF8);
        fdRelationField := ReadUTF8StrFromStream(Stream, UTF8);
        fdTableAlias := ReadUTF8StrFromStream(Stream, UTF8);
      end
    end;
  finally
    FreeMem(p, SizeOf(TFIBFieldDescr))
  end;
end;

procedure TFIBFieldDescrList.SaveToStream(Stream: TStream);
var
  i, FieldCount: Integer;
begin
  FieldCount := Integer(vFieldInfoList.Count); // field descriptors, 4 bytes in the stream
  Stream.WriteBuffer(FieldCount, SizeOf(FieldCount));
  for i := 0 to FieldCount - 1 do
  begin
    Stream.WriteBuffer(PFIBFieldDescr(vFieldInfoList[i])^, SizeOf(TFIBFieldDescr) - SizeOf(Pstring) * 3);
    WriteUTF8StrToStream(PFIBFieldDescr(vFieldInfoList[i])^.fdRelationTable, Stream);
    WriteUTF8StrToStream(PFIBFieldDescr(vFieldInfoList[i])^.fdRelationField, Stream);
    WriteUTF8StrToStream(PFIBFieldDescr(vFieldInfoList[i])^.fdTableAlias, Stream);
  end;
end;

procedure TFIBFieldDescrList.SetCapacity(aCapacity: Integer);
begin
  vFieldInfoList.Capacity := aCapacity
end;

end.
