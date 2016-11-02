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
{********************************************************************}
{ TIBBlobFilter                                                      }
{     Copyright (c)  2002 by                                         }
{     Ivan Ravin email:      <ivan_ra@chat.ru>                       }
{                                                                    }
{ Adapted for FIBPlus  by Serge Buzadzhy                             }
{                                                                    }
{********************************************************************}

unit IBBlobFilter;



interface
{$I FIBPlus.inc}

uses
  Classes;

type
  PIBBlobFilterProc = ^TIBBlobFilterProc;
  TIBBlobFilterProc = procedure (var BlobBuffer; var BlobSize:longint);

  TIBBlobFilters = class(TObject)
  private
    FIBBlobFilterList : TList;
    FSorted : boolean;
    function GetFilterProc(BlobSubType:integer;ForEncode:boolean):PIBBlobFilterProc;
    procedure Sort;
  public
    destructor Destroy; override;
    function Find(BlobSubType:integer;var anIndex:integer):boolean;    
    procedure RegisterBlobFilter(BlobSubType:integer;
                                 EncodeProc,DecodeProc:PIBBlobFilterProc);
    procedure RemoveBlobFilter(BlobSubType:integer);
    procedure IBFilterBuffer(var BlobBuffer:PAnsiChar;var BlobSize:longint;
                        BlobSubType:integer;ForEncode: boolean);
  end;


implementation


type
  PIBBlobFilter = ^TIBBlobFilter;
  TIBBlobFilter = record
    SubType    : integer;
    EncodeProc : PIBBlobFilterProc;
    DecodeProc : PIBBlobFilterProc;
  end;


var IBBlobFilters : TIBBlobFilters;


procedure UnLoadFilterList;
begin
  if  not assigned(IBBlobFilters) then
    Exit;
  IBBlobFilters.Free;
  IBBlobFilters:=nil;
end;

{ TIBBlobFilters }

destructor TIBBlobFilters.Destroy;
var i:integer;
    IBBlobFilter:PIBBlobFilter;
begin
  if assigned(FIBBlobFilterList) then
  begin
    for i:=0 to FIBBlobFilterList.Count-1 do
    begin
      IBBlobFilter:=FIBBlobFilterList.Items[i];
      Dispose(IBBlobFilter);
    end;
    FIBBlobFilterList.Free;
    FIBBlobFilterList:=nil;
  end;
  inherited;
end;

function TIBBlobFilters.Find(BlobSubType: integer;
  var anIndex: integer): boolean;
var
  L, H, I, C: Integer;
begin
  if not Assigned(FIBBlobFilterList) then
  begin
   Result:=False;
   anIndex:=0;
   Exit;
  end;
  if not FSorted then
    Sort;
  Result := False;
  L := 0;
  H := FIBBlobFilterList.Count - 1;
  while L <= H do
  begin
    I := (L + H) shr 1;
    C := PIBBlobFilter(FIBBlobFilterList.Items[i])^.SubType - BlobSubType;
    if C < 0 then
      L := I + 1
    else
    begin
      H := I - 1;
      if C = 0 then
      begin
        Result := True;
        L := I;
      end;
    end;
  end;
  anIndex := L;
end;

function TIBBlobFilters.GetFilterProc(BlobSubType: integer;
  ForEncode: boolean): PIBBlobFilterProc;
var i:integer;
    IBBlobFilter:PIBBlobFilter;
begin
  result:=nil;
  if not assigned(FIBBlobFilterList) then
    Exit;
  if Find(BlobSubType,i) then
  begin
    IBBlobFilter:=FIBBlobFilterList.Items[i];
    if ForEncode then
      result:=IBBlobFilter^.EncodeProc
    else
      result:=IBBlobFilter^.DecodeProc;
  end;
end;

procedure TIBBlobFilters.IBFilterBuffer(var BlobBuffer: PAnsiChar;
  var BlobSize: Integer; BlobSubType: integer; ForEncode: boolean);
var
  pProc:PIBBlobFilterProc;
  IBBlobFilterProc:TIBBlobFilterProc;
begin
  pProc := nil;
  if (BlobSubType<0) and (BlobSize>0) and (BlobBuffer<>nil) then
    pProc:=GetFilterProc(BlobSubType,ForEncode);
  if assigned(pProc) then
  begin
    IBBlobFilterProc:=TIBBlobFilterProc(pProc);
    IBBlobFilterProc(BlobBuffer,BlobSize)
  end;
end;

procedure TIBBlobFilters.RegisterBlobFilter(BlobSubType: integer;
  EncodeProc, DecodeProc: PIBBlobFilterProc);
var
    IBBlobFilter:PIBBlobFilter;
    i:integer;
begin
  i:=0;
  if not Assigned(FIBBlobFilterList) then
    FIBBlobFilterList := TList.Create;
  if Find(BlobSubType,i) then
    IBBlobFilter:=FIBBlobFilterList.Items[i]
  else
  begin
    new(IBBlobFilter);
    IBBlobFilter^.SubType:=BlobSubType;
    FIBBlobFilterList.Add(IBBlobFilter);
    FSorted:=false;
  end;
  IBBlobFilter^.EncodeProc:=EncodeProc;
  IBBlobFilter^.DecodeProc:=DecodeProc;
end;

procedure TIBBlobFilters.RemoveBlobFilter(BlobSubType: integer);
var i:integer;
    IBBlobFilter:PIBBlobFilter;
begin
  if not assigned(FIBBlobFilterList) then
    Exit;
  if Find(BlobSubType,i) then
  begin
    IBBlobFilter:=FIBBlobFilterList.Items[i];
    Dispose(IBBlobFilter);
    FIBBlobFilterList.Delete(I);
  end;
end;


function CompareFilters(p1,p2:Pointer):integer;
begin
  result:=PIBBlobFilter(p1)^.SubType-PIBBlobFilter(p2)^.SubType;
end;

procedure TIBBlobFilters.Sort;
begin
  if Assigned(FIBBlobFilterList) then
  begin
   FIBBlobFilterList.Sort(CompareFilters);
   FSorted:=true;
  end;
end;

initialization

finalization
  UnLoadFilterList;

end.


