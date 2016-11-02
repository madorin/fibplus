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


unit pFIBFieldsDescr;

interface
{$I FIBPlus.inc}
uses
  Classes,IB_Externals;

type


  TAddedTypeFields=(atfStandard,atfGuidField,atfWideStringField);

  TFIBFieldDescr=packed record
    fdDataType        : Short;
    fdDataScale       : Short;
    fdNullable        : Boolean;
    fdDataSize        : Short;
    fdDataOfs         : Integer;
    fdIsDBKey         : boolean;
    fdIsSeparateString:boolean;
    fdStrIndex    : integer;
    fdAddedFields : TAddedTypeFields;
    fdSubType     : Short;
    fdRelationTable:Ansistring;
    fdRelationField:Ansistring;
    fdTableAlias   :Ansistring;

  end;

  PFIBFieldDescr= ^TFIBFieldDescr;

  TFIBFieldDescrList=class
   private
    vFieldInfoList:TList;
    function GetFieldInfo(Index:integer):PFIBFieldDescr;
    function GetCapacity:integer;
    procedure SetCapacity(aCapacity: Integer);
   public
    constructor Create;
    destructor  Destroy; override;
    procedure   Assign(Source:TFIBFieldDescrList);
    procedure   Clear;
    function Add( afdDataType,afdDataScale,afdDataSize: Short;
     afdNullable,afdIsDBKey : Boolean;     IsSeparateString:boolean;
     aAddedType:TAddedTypeFields
    ):integer;
    procedure SaveToStream(Stream:TStream);
    procedure LoadFromStream(Stream:TStream; StreamVersion:byte);

    property FieldInfo[Index:integer]:PFIBFieldDescr read GetFieldInfo ;default;
    property Capacity:integer read GetCapacity write SetCapacity;
    property List:TList read vFieldInfoList;
   end;

implementation

{ TFIBFieldDescrList }

function TFIBFieldDescrList.Add(
 afdDataType, afdDataScale, afdDataSize: Short; afdNullable,afdIsDBKey : Boolean;
 IsSeparateString:boolean ;  aAddedType:TAddedTypeFields
):integer;
var p:PFIBFieldDescr;
begin
 New(p);
 with p^ do
 begin
    fdDataType :=afdDataType;
    fdDataScale:=afdDataScale;
    fdNullable :=afdNullable;
    fdDataSize :=afdDataSize;
    fdIsDBKey  :=afdIsDBKey ;
    fdIsSeparateString:=IsSeparateString;
    fdAddedFields:=aAddedType ;
 end;
 Result:=vFieldInfoList.Add(p)
end;

procedure TFIBFieldDescrList.Assign(Source:TFIBFieldDescrList);
var i:integer;
begin
 if Source=Self then exit;
 Clear;
 vFieldInfoList.Capacity:=Source.vFieldInfoList.Capacity;
 for i:=0 to Pred(Source.vFieldInfoList.Count) do
 with Source.FieldInfo[i]^ do
 begin
  Add( fdDataType,fdDataScale,fdDataSize,  fdNullable,fdIsDBKey,fdIsSeparateString,fdAddedFields );
  PFIBFieldDescr(vFieldInfoList[i])^.fdDataOfs :=fdDataOfs;
  PFIBFieldDescr(vFieldInfoList[i])^.fdStrIndex :=fdStrIndex;

  PFIBFieldDescr(vFieldInfoList[i])^.fdSubType  :=fdSubType;
  PFIBFieldDescr(vFieldInfoList[i])^.fdRelationTable  :=fdRelationTable;
  PFIBFieldDescr(vFieldInfoList[i])^.fdRelationField :=fdRelationField;
  PFIBFieldDescr(vFieldInfoList[i])^.fdTableAlias :=fdTableAlias;

 end;
end;

procedure TFIBFieldDescrList.Clear;
var
  i:integer;
begin
 with vFieldInfoList do
  for i:=0 to Pred(Count) do
  begin
    Finalize(PFIBFieldDescr(vFieldInfoList[i])^);
    FreeMem(vFieldInfoList[i],SizeOf(TFIBFieldDescr));
  end    ;
 vFieldInfoList.Clear;
end;

constructor TFIBFieldDescrList.Create;
begin
 inherited Create;
 vFieldInfoList:=TList.Create;
end;

destructor TFIBFieldDescrList.Destroy;
begin
  Clear;
  vFieldInfoList.Free;
  inherited;
end;

function TFIBFieldDescrList.GetCapacity: integer;
begin
 Result:=vFieldInfoList.Capacity
end;

function TFIBFieldDescrList.GetFieldInfo(Index: integer): PFIBFieldDescr;
begin
 Result:=PFIBFieldDescr(vFieldInfoList.List[Index])
end;

procedure TFIBFieldDescrList.LoadFromStream(Stream: TStream; StreamVersion:byte);
var i,c:integer;
    p:PFIBFieldDescr;
begin
 Clear;
 Stream.ReadBuffer(c,SizeOf(integer));
 Capacity := c;
 New(p);
 try
  for i:=0 to Pred(c) do
  begin
   if StreamVersion <6 then
    Stream.ReadBuffer(p^,SizeOf(TFIBFieldDescr)-SizeOf(boolean))
   else
    Stream.ReadBuffer(p^,SizeOf(TFIBFieldDescr)-SizeOf(Pstring)*3);
   Add( p^.fdDataType, p^.fdDataScale, p^.fdDataSize, p^.fdNullable,p^.fdIsDBKey,p^.fdIsSeparateString,p^.fdAddedFields);
   FieldInfo[i]^.fdStrIndex:=p^.fdStrIndex;
   FieldInfo[i]^.fdDataOfs:=p^.fdDataOfs;
   FieldInfo[i]^.fdSubType:=p^.fdSubType;
   with  FieldInfo[i]^ do
   begin
     Stream.ReadBuffer(c,SizeOf(integer));
     SetLength(fdRelationTable,c);
     if c>0 then
      Stream.ReadBuffer(fdRelationTable[1],c);

     Stream.ReadBuffer(c,SizeOf(integer));
     SetLength(fdRelationField,c);
     if c>0 then
      Stream.ReadBuffer(fdRelationField[1],c);

     Stream.ReadBuffer(c,SizeOf(integer));
     SetLength(fdTableAlias,c);
     if c>0 then
      Stream.ReadBuffer(fdTableAlias[1],c);

   end
  end;
 finally
  FreeMem(p,SizeOf(TFIBFieldDescr))
 end;
end;

procedure TFIBFieldDescrList.SaveToStream(Stream: TStream);
var
   i:integer;
   k:integer;
begin
 Stream.WriteBuffer(vFieldInfoList.Count,SizeOf(integer));
 for i:=0 to Pred(vFieldInfoList.Count) do
 begin
  Stream.WriteBuffer(PFIBFieldDescr(vFieldInfoList[i])^,SizeOf(TFIBFieldDescr)-SizeOf(Pstring)*3);
  k:=Length(PFIBFieldDescr(vFieldInfoList[i])^.fdRelationTable);
  Stream.WriteBuffer(k,SizeOf(integer));
  if k>0 then
   Stream.WriteBuffer(PFIBFieldDescr(vFieldInfoList[i])^.fdRelationTable[1],k);

  k:=Length(PFIBFieldDescr(vFieldInfoList[i])^.fdRelationField);
  Stream.WriteBuffer(k,SizeOf(integer));
  if k>0 then
   Stream.WriteBuffer(PFIBFieldDescr(vFieldInfoList[i])^.fdRelationField[1],k);

  k:=Length(PFIBFieldDescr(vFieldInfoList[i])^.fdTableAlias);
  Stream.WriteBuffer(k,SizeOf(integer));
  if k>0 then
   Stream.WriteBuffer(PFIBFieldDescr(vFieldInfoList[i])^.fdTableAlias[1],k);

 end;
end;

procedure TFIBFieldDescrList.SetCapacity(aCapacity: Integer);
begin
 vFieldInfoList.Capacity:=aCapacity
end;

end.
