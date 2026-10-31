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

unit FIBCloneComponents;

interface

{$I FIB.inc}

uses
  SysUtils, Classes;

procedure CopyProps(Src: TComponent; Dst: TComponent);

implementation

type
  TClassRegistrator = class(TObject)
    procedure RegisterClass(Instance: TComponent);
  end;

  TComponentHack = class(TComponent)
  end;

  TReaderEvents = class
  public
    procedure SetName(Reader: TReader; Component: TComponent; var Name: string);
  end;

function UniqueName(Instance: TComponent; Name: String; Owner: TComponent): String; forward;

procedure TClassRegistrator.RegisterClass(Instance: TComponent);
begin
  Classes.RegisterClass(TComponentClass(Instance.ClassType));
  TComponentHack(Instance).GetChildren(Self.RegisterClass, nil);
end;

procedure TReaderEvents.SetName(Reader: TReader; Component: TComponent; var Name: string);
begin
  if Component.Name = '' then
    Name := UniqueName(Component, Name, Component.Owner)
  else
    Name := Component.Name
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
        FOwner := Src.Owner
      else
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
        Result := Copy(Instance.ClassName, 2, 255) + IntToStr(I);
        Inc(I);
        Tmp := Owner.FindComponent(Result);
      end;
  end
  else
  begin
    Result := '';
    begin
      Result := Name;
      while FindGlobalComponent(Result) <> nil do
      begin
        Result := Copy(Instance.ClassName, 2, 255) + IntToStr(I);
        Inc(I);
      end;
    end;
  end;
end;

end.
