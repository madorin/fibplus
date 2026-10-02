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
  TIBBlobFilterProc = procedure(var BlobBuffer; var BlobSize: longint);

  TIBBlobFilters = class(TObject)
  private
    FIBBlobFilterList: TList;
    FSorted: boolean;
    function GetFilterProc(BlobSubType: integer; ForEncode: boolean): PIBBlobFilterProc;
    procedure Sort;
  public
    destructor Destroy; override;
    function Find(BlobSubType: integer; var anIndex: integer): boolean;
    procedure RegisterBlobFilter(BlobSubType: integer; EncodeProc, DecodeProc: PIBBlobFilterProc);
    procedure RemoveBlobFilter(BlobSubType: integer);
    procedure IBFilterBuffer(var BlobBuffer: PAnsiChar; var BlobSize: longint; BlobSubType: integer; ForEncode: boolean);
  end;

implementation

type
  PIBBlobFilter = ^TIBBlobFilter;

  TIBBlobFilter = record
    SubType: integer;
    EncodeProc: PIBBlobFilterProc;
    DecodeProc: PIBBlobFilterProc;
  end;

var
  IBBlobFilters: TIBBlobFilters;

procedure UnLoadFilterList;
begin
  if not assigned(IBBlobFilters) then
    Exit;
  IBBlobFilters.Free;
  IBBlobFilters := nil;
end;

{ TIBBlobFilters }

destructor TIBBlobFilters.Destroy;
var
  i: integer;
  IBBlobFilter: PIBBlobFilter;
begin
  if assigned(FIBBlobFilterList) then
  begin
    for i := 0 to FIBBlobFilterList.Count - 1 do
    begin
      IBBlobFilter := FIBBlobFilterList.Items[i];
      Dispose(IBBlobFilter);
    end;
    FIBBlobFilterList.Free;
    FIBBlobFilterList := nil;
  end;
  inherited;
end;

function TIBBlobFilters.Find(BlobSubType: integer; var anIndex: integer): boolean;
var
  L, H, i, C: integer;
begin
  if not assigned(FIBBlobFilterList) then
  begin
    Result := False;
    anIndex := 0;
    Exit;
  end;
  if not FSorted then
    Sort;
  Result := False;
  L := 0;
  H := FIBBlobFilterList.Count - 1;
  while L <= H do
  begin
    i := (L + H) shr 1;
    C := PIBBlobFilter(FIBBlobFilterList.Items[i])^.SubType - BlobSubType;
    if C < 0 then
      L := i + 1
    else
    begin
      H := i - 1;
      if C = 0 then
      begin
        Result := True;
        L := i;
      end;
    end;
  end;
  anIndex := L;
end;

function TIBBlobFilters.GetFilterProc(BlobSubType: integer; ForEncode: boolean): PIBBlobFilterProc;
var
  i: integer;
  IBBlobFilter: PIBBlobFilter;
begin
  Result := nil;
  if not assigned(FIBBlobFilterList) then
    Exit;
  if Find(BlobSubType, i) then
  begin
    IBBlobFilter := FIBBlobFilterList.Items[i];
    if ForEncode then
      Result := IBBlobFilter^.EncodeProc
    else
      Result := IBBlobFilter^.DecodeProc;
  end;
end;

procedure TIBBlobFilters.IBFilterBuffer(var BlobBuffer: PAnsiChar; var BlobSize: integer; BlobSubType: integer; ForEncode: boolean);
var
  pProc: PIBBlobFilterProc;
  IBBlobFilterProc: TIBBlobFilterProc;
begin
  pProc := nil;
  if (BlobSubType < 0) and (BlobSize > 0) and (BlobBuffer <> nil) then
    pProc := GetFilterProc(BlobSubType, ForEncode);
  if assigned(pProc) then
  begin
    IBBlobFilterProc := TIBBlobFilterProc(pProc);
    IBBlobFilterProc(BlobBuffer, BlobSize)
  end;
end;

procedure TIBBlobFilters.RegisterBlobFilter(BlobSubType: integer; EncodeProc, DecodeProc: PIBBlobFilterProc);
var
  IBBlobFilter: PIBBlobFilter;
  i: integer;
begin
  i := 0;
  if not assigned(FIBBlobFilterList) then
    FIBBlobFilterList := TList.Create;
  if Find(BlobSubType, i) then
    IBBlobFilter := FIBBlobFilterList.Items[i]
  else
  begin
    new(IBBlobFilter);
    IBBlobFilter^.SubType := BlobSubType;
    FIBBlobFilterList.Add(IBBlobFilter);
    FSorted := False;
  end;
  IBBlobFilter^.EncodeProc := EncodeProc;
  IBBlobFilter^.DecodeProc := DecodeProc;
end;

procedure TIBBlobFilters.RemoveBlobFilter(BlobSubType: integer);
var
  i: integer;
  IBBlobFilter: PIBBlobFilter;
begin
  if not assigned(FIBBlobFilterList) then
    Exit;
  if Find(BlobSubType, i) then
  begin
    IBBlobFilter := FIBBlobFilterList.Items[i];
    Dispose(IBBlobFilter);
    FIBBlobFilterList.Delete(i);
  end;
end;

function CompareFilters(p1, p2: Pointer): integer;
begin
  Result := PIBBlobFilter(p1)^.SubType - PIBBlobFilter(p2)^.SubType;
end;

procedure TIBBlobFilters.Sort;
begin
  if assigned(FIBBlobFilterList) then
  begin
    FIBBlobFilterList.Sort(CompareFilters);
    FSorted := True;
  end;
end;

initialization

finalization

UnLoadFilterList;

end.
