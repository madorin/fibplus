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
{ TFIBBlobFilter                                                      }
{     Copyright (c)  2002 by                                         }
{     Ivan Ravin email:      <ivan_ra@chat.ru>                       }
{                                                                    }
{ Adapted for FIBPlus  by Serge Buzadzhy                             }
{                                                                    }
{********************************************************************}

unit IBBlobFilter;

interface

{$I FIB.inc}

uses
  Classes;

type
  PFIBBlobFilterProc = ^TFIBBlobFilterProc;
  TFIBBlobFilterProc = procedure(var BlobBuffer; var BlobSize: LongInt);

  TFIBBlobFilters = class(TObject)
  private
    FIBBlobFilterList: TList;
    FSorted: Boolean;
    function GetFilterProc(BlobSubType: Integer; ForEncode: Boolean): PFIBBlobFilterProc;
    procedure Sort;
  public
    destructor Destroy; override;
    function Find(BlobSubType: Integer; var anIndex: Integer): Boolean;
    procedure RegisterBlobFilter(BlobSubType: Integer; EncodeProc, DecodeProc: PFIBBlobFilterProc);
    procedure RemoveBlobFilter(BlobSubType: Integer);
    procedure IBFilterBuffer(var BlobBuffer: PAnsiChar; var BlobSize: LongInt; BlobSubType: Integer; ForEncode: Boolean);
  end;

type
  // Deprecated names of the types renamed in 8.0.0
  PIBBlobFilterProc = PFIBBlobFilterProc deprecated 'Use PFIBBlobFilterProc';
  TIBBlobFilterProc = TFIBBlobFilterProc deprecated 'Use TFIBBlobFilterProc';
  TIBBlobFilters = TFIBBlobFilters deprecated 'Use TFIBBlobFilters';

implementation

type
  PFIBBlobFilter = ^TFIBBlobFilter;

  TFIBBlobFilter = record
    SubType: Integer;
    EncodeProc: PFIBBlobFilterProc;
    DecodeProc: PFIBBlobFilterProc;
  end;

{ TFIBBlobFilters }

destructor TFIBBlobFilters.Destroy;
var
  IBBlobFilter: Pointer;
begin
  if assigned(FIBBlobFilterList) then
  begin
    for IBBlobFilter in FIBBlobFilterList do
      Dispose(PFIBBlobFilter(IBBlobFilter));
    FIBBlobFilterList.Free;
    FIBBlobFilterList := nil;
  end;
  inherited;
end;

function TFIBBlobFilters.Find(BlobSubType: Integer; var anIndex: Integer): Boolean;
var
  L, H, i, C: Integer;
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
  H := Integer(FIBBlobFilterList.Count) - 1; // one entry per registered blob subtype
  while L <= H do
  begin
    i := (L + H) shr 1;
    C := PFIBBlobFilter(FIBBlobFilterList.Items[i])^.SubType - BlobSubType;
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

function TFIBBlobFilters.GetFilterProc(BlobSubType: Integer; ForEncode: Boolean): PFIBBlobFilterProc;
var
  i: Integer;
  IBBlobFilter: PFIBBlobFilter;
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

procedure TFIBBlobFilters.IBFilterBuffer(var BlobBuffer: PAnsiChar; var BlobSize: Integer; BlobSubType: Integer; ForEncode: Boolean);
var
  pProc: PFIBBlobFilterProc;
  IBBlobFilterProc: TFIBBlobFilterProc;
begin
  pProc := nil;
  if (BlobSubType < 0) and (BlobSize > 0) and (BlobBuffer <> nil) then
    pProc := GetFilterProc(BlobSubType, ForEncode);
  if assigned(pProc) then
  begin
    IBBlobFilterProc := TFIBBlobFilterProc(pProc);
    IBBlobFilterProc(BlobBuffer, BlobSize)
  end;
end;

procedure TFIBBlobFilters.RegisterBlobFilter(BlobSubType: Integer; EncodeProc, DecodeProc: PFIBBlobFilterProc);
var
  IBBlobFilter: PFIBBlobFilter;
  i: Integer;
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

procedure TFIBBlobFilters.RemoveBlobFilter(BlobSubType: Integer);
var
  i: Integer;
  IBBlobFilter: PFIBBlobFilter;
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

function CompareFilters(p1, p2: Pointer): Integer;
begin
  Result := PFIBBlobFilter(p1)^.SubType - PFIBBlobFilter(p2)^.SubType;
end;

procedure TFIBBlobFilters.Sort;
begin
  if assigned(FIBBlobFilterList) then
  begin
    FIBBlobFilterList.Sort(CompareFilters);
    FSorted := True;
  end;
end;

end.
