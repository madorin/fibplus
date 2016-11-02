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
 FCurOption:TpFIBDsOption;
 FCurPrepareOption:TpPrepareOption;
 FCurDetailCondition :TDetailCondition;
 FLoadingPrepared    :boolean;



procedure ReadOption (Reader: TReader);
procedure WriteOption(Writer: TWriter);

procedure ReadPrepareOption (Reader: TReader);
procedure WritePrepareOption(Writer: TWriter);

procedure ReadDetailCondition (Reader: TReader);
procedure WriteDetailCondition(Writer: TWriter);


procedure ReadOV(Reader: TReader);

procedure ReadBufferChunks(Reader: TReader);




procedure DefineProperties(Filer: TFiler); override;
{$ENDIF}

{$IFDEF FIB_IMPLEMENT}
procedure TFIBCustomDataSet.ReadOV(Reader: TReader);
begin
 Reader.ReadBoolean
end;


procedure TFIBCustomDataSet.ReadOption(Reader: TReader);
begin
 if Reader.ReadBoolean then
  Options:=Options+[FCurOption]
 else
  Options:=Options-[FCurOption];
end;

procedure TFIBCustomDataSet.WriteOption(Writer: TWriter);
begin
   Writer.WriteBoolean(FCurOption in Options)
end;


procedure TFIBCustomDataSet.ReadPrepareOption (Reader: TReader);
begin
 if Reader.ReadBoolean then
  PrepareOptions:=PrepareOptions+[FCurPrepareOption]
 else
  PrepareOptions:=PrepareOptions-[FCurPrepareOption];
end;

procedure TFIBCustomDataSet.WritePrepareOption(Writer: TWriter);
begin
   Writer.WriteBoolean(FCurPrepareOption in PrepareOptions)
end;

procedure TFIBCustomDataSet.ReadDetailCondition (Reader: TReader);
begin
 if Reader.ReadBoolean then
  DetailConditions:=DetailConditions+[FCurDetailCondition ]
 else
  DetailConditions:=DetailConditions-[FCurDetailCondition];
end;

procedure TFIBCustomDataSet.WriteDetailCondition(Writer: TWriter);
begin
   Writer.WriteBoolean(FCurDetailCondition  in DetailConditions)
end;



procedure TFIBCustomDataSet.ReadBufferChunks(Reader: TReader);
begin
 BufferChunks:=Reader.ReadInteger
end;



procedure TFIBCustomDataSet.DefineProperties(Filer: TFiler);

var
   IsWriteProcess:boolean;

function DoSaveDetailCond:boolean;
begin
   if IsWriteProcess then
     if Filer.Ancestor <> nil then
     begin
      Result:= ([FCurDetailCondition]*TFIBDataSet(Filer.Ancestor).DetailConditions)<>
               ([FCurDetailCondition]*DetailConditions)
     end
     else
      Result:=FCurDetailCondition in DetailConditions
   else
    Result := False;
end;

function DoSavePrepareOption(WriteTrueValue:boolean):boolean;
begin
  if IsWriteProcess then
   if Filer.Ancestor <> nil then
   begin
    Result:= ([FCurPrepareOption]*TFIBDataSet(Filer.Ancestor).PrepareOptions)<>
             ([FCurPrepareOption]*PrepareOptions)
   end
   else
   begin
    if WriteTrueValue then
     Result:=FCurPrepareOption in PrepareOptions
    else
     Result:=not (FCurPrepareOption in PrepareOptions)
   end
  else
    Result := False;
end;

function DoSaveOption(WhenInclude:boolean):boolean;
begin
   if IsWriteProcess then
     if Filer.Ancestor <> nil then
     begin
      Result:= ([FCurOption]*TFIBDataSet(Filer.Ancestor).Options)<>
               ([FCurOption]*Options)
     end
     else
     begin
      if WhenInclude then
       Result:=FCurOption in Options
      else
       Result:=not (FCurOption in Options)
     end
   else
     Result := False;  
end;

begin
  inherited;
  IsWriteProcess:=not (Filer is TReader);
  if (csDesigning in ComponentState) and not IsWriteProcess and not FLoadingPrepared then
  begin
  // Paste component in DesignTime
  // Clear Values from tools
   FOptions:=StatDefDataSetOptions;
//   [poTrimCharFields,poStartTransaction,poAutoFormatFields,poRefreshAfterPost];
   FDetailConditions:=[];
   FPrepareOptions  :=StatDefPrepareOptions;
   FLoadingPrepared :=True;
  end;

  with Filer do
   begin
     DefineProperty('BufferChunks',  ReadBufferChunks , nil,False);
     FCurPrepareOption:=psUseBooleanField;
     DefineProperty('poUseBooleanField',  ReadPrepareOption , WritePrepareOption,
       DoSavePrepareOption(False)
     );

     FCurPrepareOption:=psUseGuidField;
     DefineProperty('poUseGuidField',  ReadPrepareOption , WritePrepareOption,
       DoSavePrepareOption(True)
     );

     FCurPrepareOption:=psUseLargeIntField;
     DefineProperty('poUseLargeIntField',  ReadPrepareOption , WritePrepareOption,
       DoSavePrepareOption(True)
     );

     FCurPrepareOption:=pfImportDefaultValues;
     DefineProperty('poImportDefaultValues', ReadPrepareOption, WritePrepareOption,
       DoSavePrepareOption(False)
     );
     FCurPrepareOption:=psGetOrderInfo;
     DefineProperty('poGetOrderInfo', ReadPrepareOption, WritePrepareOption,
       DoSavePrepareOption(False)
     );

     FCurPrepareOption:=psSupportUnicodeBlobs;
     DefineProperty('poSupportUnicodeBlobs', ReadPrepareOption, WritePrepareOption,
       DoSavePrepareOption(True)
     );

     FCurPrepareOption:=pfSetRequiredFields;
     DefineProperty('poSetRequiredFields', ReadPrepareOption, WritePrepareOption,
      DoSavePrepareOption(True)
     );
     FCurPrepareOption:=pfSetReadOnlyFields;
     DefineProperty('poSetReadOnlyFields', ReadPrepareOption, WritePrepareOption,
       DoSavePrepareOption(True)
     );
     FCurPrepareOption:=psSQLINT64ToBCD;
     DefineProperty('poSQLINT64ToBCD', ReadPrepareOption, WritePrepareOption,
       DoSavePrepareOption(True)
     );
     FCurPrepareOption:=psApplyRepositary;
     DefineProperty('poApplyRepositary', ReadPrepareOption, WritePrepareOption,
       DoSavePrepareOption(True)
     );
     FCurPrepareOption:=psAskRecordCount;
     DefineProperty('poAskRecordCount', ReadPrepareOption, WritePrepareOption,
       DoSavePrepareOption(True)
     );
     FCurPrepareOption:=psCanEditComputedFields;
     DefineProperty('poCanEditComputedFields', ReadPrepareOption, WritePrepareOption,
       DoSavePrepareOption(True)
     );

     FCurPrepareOption:=psSetEmptyStrToNull;
     DefineProperty('poEmptyStrToNull', ReadPrepareOption, WritePrepareOption,
       DoSavePrepareOption(False)
     );


//
     FCurDetailCondition:=dcWaitEndMasterScroll;
     DefineProperty('WaitEndMasterScroll', ReadDetailCondition, WriteDetailCondition,
       DoSaveDetailCond
     );
     FCurDetailCondition:=dcForceMasterRefresh;
     DefineProperty('dcForceMasterRefresh', ReadDetailCondition,  WriteDetailCondition,
        DoSaveDetailCond
     );
     FCurDetailCondition:=dcForceOpen;
     DefineProperty('dcForceOpen',  ReadDetailCondition,  WriteDetailCondition,
       DoSaveDetailCond
     );
     FCurDetailCondition:=dcIgnoreMasterClose;
     DefineProperty('dcIgnoreMasterClose', ReadDetailCondition,  WriteDetailCondition,
       DoSaveDetailCond
     );

// Options

     FCurOption:=poTrimCharFields;
     DefineProperty('oTrimCharFields', ReadOption, WriteOption,
       DoSaveOption(False)
     );

     FCurOption:=poDontCloseAfterEndTransaction;
     DefineProperty('oDontAutoClose', ReadOption, WriteOption,
       DoSaveOption(True)
     );


     FCurOption:=poFreeHandlesAfterClose;
     DefineProperty('oFreeHandlesAfterClose', ReadOption, WriteOption,
       DoSaveOption(True)
     );

     FCurOption:=poUseSelectForLock;
     DefineProperty('oUseSelectForLock', ReadOption, WriteOption,
       DoSaveOption(True)
     );

     FCurOption:=poCacheCalcFields;
     DefineProperty('oCacheCalcFields', ReadOption, WriteOption,
       DoSaveOption(True)
     );

     FCurOption:=poRefreshAfterPost;
     DefineProperty('oRefreshAfterPost', ReadOption, WriteOption,
       DoSaveOption(False)
     );



     FCurOption:=poRefreshAfterDelete;

     DefineProperty('oRefreshAfterDelete', ReadOption, WriteOption,
       DoSaveOption(True)
     );


     FCurOption:=poRefreshDeletedRecord;
     DefineProperty('oRefreshDeletedRecord', ReadOption, WriteOption,
       DoSaveOption(True)
     );

     FCurOption:=poStartTransaction;
     DefineProperty('oStartTransaction', ReadOption, WriteOption,
       DoSaveOption(False)
     );

     FCurOption:=poAutoFormatFields;
     DefineProperty('oAutoFormatFields', ReadOption, WriteOption,
       DoSaveOption(False)
     );

     FCurOption:=poProtectedEdit;
     DefineProperty('oProtectedEdit', ReadOption, WriteOption,
       DoSaveOption(True)
     );

     FCurOption:=poKeepSorting;
     DefineProperty('oKeepSorting', ReadOption, WriteOption,
       DoSaveOption(True)
     );

     FCurOption:=poPersistentSorting;
     DefineProperty('oPersistentSorting', ReadOption, WriteOption,
       DoSaveOption(True)
     );


     FCurOption:=poVisibleRecno;
     DefineProperty('oVisibleRecno', ReadOption, WriteOption,
       DoSaveOption(True)
     );

     FCurOption:=poNoForceIsNull;
     DefineProperty('oNoForceIsNull', ReadOption, WriteOption,
       DoSaveOption(True)
     );

     FCurOption:=poFetchAll;
     DefineProperty('oFetchAll', ReadOption, WriteOption,
       DoSaveOption(True)
     );


   end ;

  Filer.DefineProperty('ObjectView',  ReadOV, nil,   False );
end;

////End  PrepareOptions Stream
{$ENDIF}
