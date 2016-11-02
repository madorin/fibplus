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
unit FIBCloneComponents ;

interface
{$I FIBPlus.inc}

uses
  SysUtils, Classes;

function CreateClone(Src: TComponent): TComponent;
procedure SaveCmpToFile(Cmp: TComponent;FileName:string);
procedure SaveCmpToStream(Cmp: TComponent;ms:TStream);

function LoadCmpFromFile(FOwner,FParent: TComponent;FileName:string):TComponent;
function LoadCmpFromStream(FOwner,FParent: TComponent;ms:Tstream;
 FromBegin:boolean =True
):TComponent;

procedure CopyProps(Src: TComponent; Dst: TComponent);

implementation
uses TypInfo;

type
  PLongInt=^LongInt;
  TClassRegistrator = class (TObject)
    procedure RegisterClass(Instance: TComponent);
  end;

  TComponentHack = class (TComponent)
  end;

  TReaderEvents = class
  public
    OldName: String;
    procedure SetName(Reader: TReader; Component: TComponent; var Name: string);
    procedure OnFindMethodEvent(Reader: TReader; const MethodName: string;
       var Address: Pointer; var Error: Boolean) ;
  end;

function UniqueName(Instance: TComponent; Name: String; Owner: TComponent): String; forward;

procedure TClassRegistrator.RegisterClass(Instance: TComponent);
begin
  Classes.RegisterClass(TComponentClass(Instance.ClassType));
  TComponentHack(Instance).GetChildren(Self.RegisterClass , nil );
end;

procedure TReaderEvents.SetName(Reader: TReader; Component: TComponent; var Name: string);
begin
  if Component.Name='' then
   Name := UniqueName(Component, Name, Component.Owner)
  else
   Name:=Component.Name
end;


procedure TReaderEvents.OnFindMethodEvent(Reader: TReader; const MethodName: string;
       var Address: Pointer; var Error: Boolean);
begin
 Error:=false
end;


procedure RegisterComponent(Instance: TComponent);
begin
  with TClassRegistrator.Create do
  try
    RegisterClass(Instance);
  finally
    Free;
  end;
end;


procedure CopyProps(Src: TComponent; Dst: TComponent);
var
  F: TMemoryStream;
  Reader: TReader;
  Writer: TWriter;
  ReaderEvents: TReaderEvents;
  FOwner: TComponent;
begin
  F := TMemoryStream.Create;
  try
    Writer := TWriter.Create(F, 1024);
    try
      if Assigned(Src.Owner) then
        FOwner := Src.Owner else
        FOwner := Dst.Owner;
      Writer.Root := FOwner;
      Writer.WriteComponent(Src);
    finally
      Writer.Free;
    end;
    RegisterComponent(Src);
    F.Position := 0;
    Reader := TReader.Create(F, 1024);
    try
      ReaderEvents := TReaderEvents.Create;
      try
        ReaderEvents.OldName := Dst.Name;
        Reader.Root := FOwner;
        Reader.OnSetName := ReaderEvents.SetName;
        Reader.BeginReferences;
        try
          Reader.ReadComponent(Dst);
          Reader.FixupReferences;
        finally
          Reader.EndReferences;
        end;
      finally
        ReaderEvents.Free;
      end;
    finally
      Reader.Free;
    end;
  finally
    F.Free;
  end;
end;

procedure SaveCmpToStream(Cmp: TComponent;ms:TStream);
var
  Writer: TWriter;
  FOwner: TComponent;
begin
  try
    Writer := TWriter.Create(ms, 4096);
    try
      FOwner := Cmp.Owner;
      Writer.Root := FOwner;
      Writer.WriteSignature;
      Writer.WriteComponent(cmp);
    finally
      Writer.Free;
    end;
    ms.Position := 0;
  finally
  end
end;


procedure SaveCmpToFile(Cmp: TComponent;FileName:string);
var
  F: TMemoryStream;
begin
  F := TMemoryStream.Create;
 try
    SaveCmpToStream(Cmp,F);
    F.SaveToFile(FileName);
 finally
  F.Free
 end
end;

function LoadCmpFromStream(FOwner,FParent: TComponent;ms:Tstream;
 FromBegin:boolean =True
):TComponent;
var
  Reader: TReader;
  ReaderEvents: TReaderEvents;
  Signature: Longint;
const
  FilerSignature: array[1..4] of Char = 'TPF0';  
begin
  if FromBegin then
   ms.Seek(0,soFromBeginning);
  try
    Reader := TReader.Create(ms, 4096);
    Reader.Read(Signature, SizeOf(Signature));
    if Signature <> PLongInt(@FilerSignature)^ then
    begin
     Reader.Free;
     Reader := TReader.Create(ms, 4096);
     ms.Position:=0;
    end;
    try
      ReaderEvents := TReaderEvents.Create;
      try
        Reader.Root  := FOwner;
        Reader.Owner := FOwner;
        Reader.Parent:= FParent;
        Reader.OnSetName   := ReaderEvents.SetName;
        Reader.OnFindMethod:= ReaderEvents.OnFindMethodEvent;
        Reader.BeginReferences;
        try
          Result :=Reader.ReadComponent(nil); // nil
          try
           Reader.FixupReferences;
          except
          end; 
        finally
          Reader.EndReferences;
        end;
      finally
        ReaderEvents.Free;
      end;
    finally
      Reader.Free;
    end;
  except 
   Result :=nil
  end;
end;


function LoadCmpFromFile(FOwner,FParent: TComponent;FileName:string):TComponent;
var
  F: TMemoryStream;
begin
  F := TMemoryStream.Create;
  try
    F.LoadFromFile(FileName);
    Result:=LoadCmpFromStream(FOwner,FParent,F);
  finally
    F.Free;
  end;
end;


function CreateCloneOwner(Src: TComponent; AOwner: TComponent): TComponent;
begin
  Result := TComponentClass(Src.ClassType).Create(AOwner);
  try
    CopyProps(Src, Result);
  except
    Result.Free;
    raise;
  end;
end;

function CreateClone(Src: TComponent): TComponent;
begin
  Result := CreateCloneOwner(Src, Src.Owner)
end;

{
procedure CopyMethodProps(Src, Dst: TObject);
var
  I, Count: Integer;
  PropList: PPropList;
  PropInfo: PPropInfo;
  Method: TMethod;
begin
  if not Dst.InheritsFrom(Src.ClassType) then Exit;
  PropList := nil;
  Count := GetTypeData(Src.ClassInfo)^.PropCount;
  try
    ReAllocMem(PropList, Count * SizeOf(Pointer));
    GetPropInfos(Src.ClassInfo, PropList);
    for I := 0 to Count - 1 do
    begin
      PropInfo := PropList^[I];
      if PropInfo^.PropType^.Kind = tkMethod then
      begin
        Method := GetMethodProp(Src, PropInfo);
        SetMethodProp(Dst, PropInfo, Method);
      end;
    end;
  finally
    ReAllocMem(PropList, 0);
  end;
end;
 }
function UniqueName(Instance: TComponent; Name: String; Owner: TComponent): String;
var
  I: Integer;
  Tmp: TComponent;
begin
  I := 1;
  Result := Name;
  if Assigned(Owner) then
  begin
    Tmp := Owner.FindComponent(Result);
    if Assigned(Tmp) and (Tmp <> Instance) then
    while (Tmp <> nil) do
    begin
      Result :=Copy(Instance.ClassName,2,255)+IntToStr(i);
      Inc(I);
      Tmp := Owner.FindComponent(Result);
    end;
  end else
  begin
    Result := '';
    {$IFNDEF D6+}
    if Assigned(FindGlobalComponent) then
    {$ENDIF}
    begin
      Result := Name;
      while FindGlobalComponent(Result) <> nil do
      begin
        Result :=Copy(Instance.ClassName,2,255)+IntToStr(i);
        Inc(I);
      end;
    end;
  end;
end;



end.

