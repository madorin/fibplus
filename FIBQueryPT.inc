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
{$IFDEF FIB_INTERFACE}
 FLoadingPrepared:boolean;
 procedure ReadQueryStartTransaction (Reader: TReader);
 procedure WriteQueryStartTransaction(Writer: TWriter);

 procedure ReadQueryAutoCommit (Reader: TReader);
 procedure WriteQueryAutoCommit(Writer: TWriter);


 procedure ReadQueryTrimChar (Reader: TReader);
 procedure WriteQueryTrimChar(Writer: TWriter);

 procedure ReadAutoFreeHandle (Reader: TReader);
 procedure WriteAutoFreeHandle(Writer: TWriter);

 procedure ReadQueryNoForceIsNull (Reader: TReader);
 procedure WriteQueryNoForceIsNull(Writer: TWriter);



 procedure DefineProperties(Filer: TFiler); override;

{$ENDIF}

{$IFDEF FIB_IMPLEMENT}
procedure TFIBQuery.ReadQueryTrimChar (Reader: TReader);
begin
 if Reader.ReadBoolean then
   Include(FOptions,qoTrimCharFields)
 else
   Exclude(FOptions,qoTrimCharFields)
end;

procedure TFIBQuery.WriteQueryTrimChar(Writer: TWriter);
begin
 Writer.WriteBoolean(qoTrimCharFields in Options);
end;

procedure TFIBQuery.ReadQueryStartTransaction (Reader: TReader);
begin
 if Reader.ReadBoolean then
   Include(FOptions,qoStartTransaction)
 else
   Exclude(FOptions,qoStartTransaction);
end;

procedure TFIBQuery.WriteQueryStartTransaction(Writer: TWriter);
begin
 Writer.WriteBoolean(qoStartTransaction in Options)
end;


procedure TFIBQuery.ReadQueryAutoCommit (Reader: TReader);
begin
  if Reader.ReadBoolean then
   Include(FOptions,qoAutoCommit)
  else
   Exclude(FOptions,qoAutoCommit)
end;

procedure TFIBQuery.WriteQueryAutoCommit(Writer: TWriter);
begin
 Writer.WriteBoolean(qoAutoCommit in Options)
end;

procedure TFIBQuery.ReadAutoFreeHandle (Reader: TReader);
begin
 if Reader.ReadBoolean then
  Include(FOptions,qoFreeHandleAfterExecute)
 else
  Exclude(FOptions,qoFreeHandleAfterExecute);
end;


procedure TFIBQuery.WriteAutoFreeHandle(Writer: TWriter);
begin
 Writer.WriteBoolean(qoFreeHandleAfterExecute in Options)
end;

procedure TFIBQuery.ReadQueryNoForceIsNull (Reader: TReader);
begin
 if Reader.ReadBoolean then
  Include(FOptions,qoNoForceIsNull)
 else
  Exclude(FOptions,qoNoForceIsNull);
end;

procedure TFIBQuery.WriteQueryNoForceIsNull(Writer: TWriter);
begin
 Writer.WriteBoolean(qoNoForceIsNull in Options)
end;


procedure TFIBQuery.DefineProperties(Filer: TFiler);
var
  IsWriteProcess:boolean;

function DoSave(Option:TpFIBQueryOption):boolean;
begin
 if Filer.Ancestor <> nil then
 begin
    Result:=([Option]*TFIBQuery(Filer.Ancestor).Options)<>([Option]*Options)
 end
 else
  Result:= Option in Options
end;

begin
  inherited;
  IsWriteProcess:=not (Filer is TReader);
          
  if (csDesigning in ComponentState) and not IsWriteProcess and not FLoadingPrepared then
  begin
  // Paste component in DesignTime
  // Clear Values from tools
   FOptions:=[];
   FLoadingPrepared:=True;
  end;


  Filer.DefineProperty('qoAutoCommit',
   ReadQueryAutoCommit, WriteQueryAutoCommit,
    IsWriteProcess and DoSave(qoAutoCommit)
  );

  Filer.DefineProperty('qoStartTransaction',
   ReadQueryStartTransaction, WriteQueryStartTransaction,
    IsWriteProcess and DoSave(qoStartTransaction)
  );

  Filer.DefineProperty('qoTrimCharFields',
   ReadQueryTrimChar , WriteQueryTrimChar,
    IsWriteProcess and DoSave(qoTrimCharFields)
  );

  Filer.DefineProperty('qoNoForceIsNull',
   ReadQueryNoForceIsNull, WriteQueryNoForceIsNull,
    IsWriteProcess and DoSave(qoNoForceIsNull)
  );

  Filer.DefineProperty('qoFreeHandleAfterExecute',
   ReadAutoFreeHandle , WriteAutoFreeHandle,
    IsWriteProcess and DoSave(qoFreeHandleAfterExecute)
  );


end;

{$ENDIF}
