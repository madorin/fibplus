{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ InterBase databases                                           }
{                                                               }
{    FIBPlus is based in part on the product                    }
{    Free IB Components, written by Gregory H. Deatz for        }
{    Hoagland, Longo, Moran, Dunst & Doukas Company.            }
{    mailto:gdeatz@hlmdd.com                                    }
{                                                               }
{    Copyright (c) 1998-2012 Devrace Ltd.                       }
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
   procedure  GetFieldDataPointer(Field:TField;RecNumber:integer; var IsString:boolean;var OutRes:Pointer);

{$ENDIF}

{$IFDEF FIB_IMPLEMENT}



procedure TFIBCustomDataSet.GetFieldDataPointer(Field:TField;RecNumber:integer; var  IsString:boolean;var OutRes:Pointer);
var
   P1:Pointer;
   fi:PFIBFieldDescr;
   fn:Integer;
   c:Currency;
   OutRes1:Pointer;   
begin

 case  FCacheModelOptions.CacheModelKind of
   cmkStandard:
   begin
    if FRecordCount<=RecNumber then
     FetchNext(RecNumber-FRecordCount+1);
    if  Unidirectional then
     RecNumber:=RecNumber mod FCacheModelOptions.FBufferChunks
   end;
   cmkLimitedBufferSize:
   begin
     RecNumber:=RecNumber mod FCacheModelOptions.FBufferChunks
   end;
  end;
  fn:=Field.FieldNo;

  if
  (fn<=0) and (not vCalcFieldsSavedCache
    or    not GetBit(PSavedRecordData(FRecordsCache.PRecBuffer(RecNumber+1,False))^.rdFlags,7))
  then
  begin
// NeedRecalcFields
    vInspectRecno:=RecNumber;
    try
      vTypeDispositionField:=dfRRecNumber;
      IsString:=False;
      if not GetFieldData(Field,PAnsiChar(OutRes)) then // ForceCalculate
       OutRes:=nil
      else
      case Field.DataType of
       ftBCD:
       begin
        BCDToCurr(TBcd(OutRes^), c);
       {$IFDEF D6+}
        if TBCDField(Field).Size<=4 then
          PInt64(OutRes)^:=(PInt64(@c)^ div IE10[4-TBCDField(Field).Size])
        else
          PInt64(OutRes)^:=PInt64(@c)^ *IE10[TBCDField(Field).Size-4];
       {$ELSE} // D5
        PCurrency(OutRes)^:=c
       {$ENDIF}  
       end;
      end;
     finally
      vTypeDispositionField:=dfNormal
     end;
  end;


    if fn>0 then
    begin
      fi:=vFieldDescrList.List.List[fn-1];
      IsString:=fi^.fdStrIndex>-1;

      if  IsString then
      begin

       OutRes:=FRecordsCache.GetStringFieldData(RecNumber,fi^.fdStrIndex);
       if PAnsiString(OutRes)^='' then
       begin
       // May be null, may be empty str
        P1:=FRecordsCache.PRecBuffer(RecNumber+1,False);
        if PSavedRecordData(P1).rdFields[fn].fdIsNull then
         OutRes:=nil;
       end;
      end
      else
      begin
        OutRes:=FRecordsCache.GetNonStringFieldData(RecNumber,fi^.fdDataOfs-DiffSizesRecData,P1);
        if PSavedRecordData(P1).rdFields[fn].fdIsNull then
         OutRes:=nil;
      end;
    end
    else
    if vCalcFieldsSavedCache then
    begin // Calc
     OutRes1:=FRecordsCache.GetNonStringFieldData(RecNumber, FBlockReadSize+Field.Offset,P1);
     if OutRes1<>nil then
      if not PBoolean(OutRes1)^ then
       OutRes:=nil
      else
      begin
        Inc(PAnsiChar(OutRes1),SizeOf(Boolean));
        IsString:=False;

        case Field.DataType of
         ftBCD:
         begin
          BCDToCurr(TBcd(OutRes1^), c);
         {$IFDEF D6+}
          if TBCDField(Field).Size<=4 then
            PInt64(OutRes)^:=(PInt64(@c)^ div IE10[4-TBCDField(Field).Size])
          else
            PInt64(OutRes)^:=PInt64(@c)^ *IE10[TBCDField(Field).Size-4];
         {$ELSE} // D5
          PCurrency(OutRes)^:=c
         {$ENDIF}
         end;
        else
         OutRes:=OutRes1
        end;
      end
    end;
end;


function TFIBCustomDataSet.InternalLocate(const KeyFields: string;
  KeyValues:array of Variant; Options: TExtLocateOptions;FromBegin:boolean = False;
  LocateKind:TLocateKind = lkStandard; ResyncToCenter:boolean =False
  ): Boolean;

type
  TArrow=(arForward,arBackward);
var
  fl: TFIBList;
  fld_cnt: Integer;
  rc,rc1 :Integer;
  Arrow:TArrow;
  vIgnoreRecChecked:boolean;
  RecI: Integer;
  vSortInfos     : array of TSortFieldInfo;
  FinishSearch:boolean;
  NowInFetched:boolean;
  vDateAdjusted:boolean;

  WideValue:WideString;
  WideKey:WideString;
  vCalcBuffer:PAnsiChar;
  
function IsVisibleRecord:boolean;
var
 vBuff:TRecordBuffer;
begin

  if drsInMoveRecord in FRunState then
  begin
   Result := True;
   Exit;
  end;

  if Filtered then
  begin
   vBuff:=AllocRecordBuffer;
   try
    FCurrentRecord:=RecI;
    ReadRecordCache(RecI, vBuff, False);
    Result:=IsVisible(vBuff);
   finally
    FreeMem(vBuff);
   end;
  end
  else
  if FCacheModelOptions.FCacheModelKind=cmkStandard then
  begin
    if UniDirectional then
     vBuff :=FRecordsCache.PRecBuffer((RecI mod BufferChunks) +1,False)-DiffSizesRecData
    else
     vBuff :=FRecordsCache.PRecBuffer(RecI+1,False)-DiffSizesRecData;
    Result:=IsVisibleStat(vBuff);
  end
  else
    Result:=True;  
end;


procedure AdjustOrders(L, R: Integer);
var
  I, J: Integer;
  P: Integer;
  T: TSortFieldInfo;
  P1:Pointer;
  v :Variant;
begin
  repeat
    I := L;
    J := R;
    P := vSortInfos[(L + R) shr 1].InOrderIndex;
    repeat
      while vSortInfos[I].InOrderIndex< P do
        Inc(I);
      while vSortInfos[J].InOrderIndex> P do
        Dec(J);
      if I <= J then
      begin
        if I<>J then
        begin
          T := vSortInfos[I];
          vSortInfos[I] := vSortInfos[J];
          vSortInfos[J] := T;
          P1:=fl.List^[I];
          fl.List^[I]:=fl.List^[J];
          fl.List^[J]:=P1;
          v :=KeyValues[I];
          KeyValues[I]:=KeyValues[J];
          KeyValues[J]:=v;
        end;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if L < J then
      AdjustOrders( L, J);
    L := I;
  until I >= R;
end;

function  InitSortInfos:boolean;
var
   i:integer;
   NeedAdjustOrder:boolean;
   vCallAsSorted:boolean;
begin
  vCallAsSorted:=eloInSortedDS in Options;
  if not vCallAsSorted then
  begin
    Result := False;
    Exit;
  end;
    
  NeedAdjustOrder:=False;
  SetLength(vSortInfos,fld_cnt);
  for i:=0 to fld_cnt-1 do
  begin
   if IsSortedField(TField(fl.List^[i]),vSortInfos[i]) then
   begin
    if vSortInfos[i].InOrderIndex<>Succ(i) then
       NeedAdjustOrder:=True;
   end
   else
   begin
     Result := False;
     Exit;
   end;
  end;

  if NeedAdjustOrder then
   AdjustOrders(0,fld_cnt-1);


  for i:=0 to fld_cnt-1 do
   if (vSortInfos[i].InOrderIndex<>Succ(i)) or
    ((TField(fl.List^[i]).DataType in [ftString,ftWideString,ftGuid]) and
      not (vCallAsSorted and not (eloCaseInsensitive in Options))
    )
   then
   begin
     Result := False;
     Exit;
   end;
  Result:=True;
end;


procedure  AdjustKeys;
var
      i:integer;
      CalcSize:integer;
      fdt  :TFieldType ;
begin
  CalcSize:=0;
  for i:=Pred(fl.Count) downto 0 do
  begin

     if TField(fl.List^[i]).FieldKind in [fkCalculated, fkLookup] then
     begin
        Inc(CalcSize,TField(fl.List^[i]).DataSize)
     end;
     if VarIsNull(KeyValues[i]) or VarIsEmpty(KeyValues[i]) then
     begin
       KeyValues[i]:=null;
       Continue
     end
     else
     if VarType(KeyValues[i])= varBoolean then
      if KeyValues[i] then
       KeyValues[i]:=1
      else
       KeyValues[i]:=0;

     fdt  :=TField(fl.List^[i]).DataType ;
     {$IFDEF UNICODE_TO_STRING_FIELDS}
      if fdt=ftString then
       fdt:=ftWideString;
     {$ENDIF}
     case fdt  of
      ftString  :
      begin
       if eloCaseInsensitive in Options then
       begin
         KeyValues[i]:=AnsiUpperCase(KeyValues[i]);
        {$IFDEF D2009+}
         KeyValues[i]:=VarAsType(KeyValues[i],varString);
        {$ENDIF}
       end
       else
        KeyValues[i]:=VarAsType(KeyValues[i],varString);
      end;
      ftSmallint: KeyValues[i]:=VarAsType(KeyValues[i],varSmallInt);
      ftInteger : KeyValues[i]:=VarAsType(KeyValues[i],varInteger);
      ftBoolean : KeyValues[i]:=VarAsType(KeyValues[i],varByte);
      ftFloat   : KeyValues[i]:=VarAsType(KeyValues[i],varDouble);
      ftCurrency: KeyValues[i]:=VarAsType(KeyValues[i],varCurrency);
      ftWideString :
      begin
       if Database.NeedUnicodeFieldsTranslation then
       begin
         if eloCaseInsensitive in Options then
         begin
          KeyValues[i]:=WideUpperCase(KeyValues[i]);
         end
         else
         begin
          KeyValues[i]:=VarAsType(KeyValues[i],varOleStr);
         end
       end
       else
       begin
         if eloCaseInsensitive in Options then
           KeyValues[i]:=AnsiUpperCase(KeyValues[i])
         else
          KeyValues[i]:=VarAsType(KeyValues[i],varString);
       end
      end;
      {$IFDEF D6+}
      ftLargeint   : KeyValues[i]:=VarAsType(KeyValues[i],varInt64);
      {$ELSE}
      ftLargeint   : KeyValues[i]:=VarAsType(KeyValues[i],varInteger);
      {$ENDIF}
      ftBCD        :
       {$IFDEF D6+}
        if TField(fl.List^[i]).Size=0 then
         KeyValues[i]:=VarAsType(KeyValues[i],varInt64)
        else
         KeyValues[i]:=VarAsType(KeyValues[i]*E10[TField(fl.List^[i]).Size],varInt64);
       {$ELSE}
        ;
       {$ENDIF}
      ftTime:
      begin
       KeyValues[i]:= VarAsType(KeyValues[i],varDate);
       KeyValues[i]:= DateTimeToTimeStamp(KeyValues[i]).Time
      end   ;
      ftDate:
      begin
       KeyValues[i]:= VarAsType(KeyValues[i],varDate);
       KeyValues[i]:= DateTimeToTimeStamp(KeyValues[i]).Date
      end;
      ftDateTime:
      begin
       if VarType(KeyValues[i])<>varDate then
       begin
        vDateAdjusted:=True;
        KeyValues[i]:=VarAsType(KeyValues[i],varDate);
       end 
      end;
      ftGuid:
        KeyValues[i]:=VarAsType(KeyValues[i],varString);
     end;
  end;
  if CalcSize>0 then
   GetMem(vCalcBuffer,CalcSize)
  else
   vCalcBuffer:=nil
end;


procedure IsFinishSearch;
begin
  case LocateKind of
   lkStandard,lkNext:
   begin
     if FCacheModelOptions.FCacheModelKind=cmkStandard then
     begin
      FinishSearch:=RecI>=FRecordCount;
      if FinishSearch and not (eloInFetchedRecords in Options) then
        FinishSearch:=FetchNext(1)=0;
     end
     else
     begin
      FinishSearch:=RecI>vPartition.EndPartRecordNo
     end;
   end;
   lkPrior:
   begin
    if FCacheModelOptions.FCacheModelKind=cmkStandard then
     FinishSearch:=RecI<0
    else
     FinishSearch:=RecI<vPartition.BeginPartRecordNo
   end;
  end;
end;

var
 StrValue,sKey:Ansistring; // used in CompareValues



function CompareValues:boolean;
var
  i:integer;
  p:Pointer;
  vIsString:boolean;
  L:integer;
  dt:TDateTime;
  cResult:shortInt;
  InitStrValue:boolean;
  inWS:boolean;
  ts:TTimeStamp;
  fi:PFIBFieldDescr;
  dv:Double;
  fn:Integer;
 {$IFNDEF D6+}
  tempCurrency:Currency;
 {$ENDIF}
  function UDFCompStr(const s:Ansistring):integer;
  begin
   Result:=CompareFieldValues(TField(fl.List^[i]),KeyValues[i],s )
  end;

  function UDFCompWideStr(const s:Widestring):integer;
  begin
   Result:=CompareFieldValues(TField(fl.List^[i]),WideKey,s )
  end;

  procedure UDFUtf8DecodeA(var s:Ansistring);
  begin
  {$IFDEF   D2009+}
   s:=UTF8ToString(S)
  {$ELSE}
   s:=UTF8Decode(s)
  {$ENDIF}
  end;

  procedure ChangeArrowInSorted;
  begin
          case TField(fl.List^[i]).DataType of
           ftString    :
           begin
            if not InitStrValue then
             StrValue:=PAnsiString(p)^;
             if eloCaseInsensitive in Options then
              StrValue:=AnsiUppercase(StrValue);
             Arrow:=TArrow(vSortInfos[i].Asc xor  (UDFCompStr(StrValue)>0))
           end;
           ftWideString:
           begin
            if not InWs then
            begin
             DoUtf8Decode(KeyValues[i],WideKey);
             if InitStrValue then
              DoUtf8Decode(StrValue,WideValue)
             else
              DoUtf8Decode(PAnsiString(p)^,WideValue);
            end;
             if eloCaseInsensitive in Options then
              DoWideUppercase(WideValue);
              Arrow:=TArrow(vSortInfos[i].Asc xor  (UDFCompWideStr(WideValue)>0))
           end;
          else
           Arrow:=TArrow(vSortInfos[i].Asc xor (cResult< 0));
          end  ;
  end;


  function NonStrFieldCompare:boolean;
  begin
          // Non string fields compare
              case TField(fl.List^[i]).DataType of
               ftSmallInt:
                begin
                   if PSmallInt(P)^=TVarData(KeyValues[i]).VSmallInt then
                    cResult:=0
                   else
                   if PSmallInt(P)^>TVarData(KeyValues[i]).VSmallInt then
                    cResult:=1
                   else
                    cResult:=-1;
                end;
               ftInteger,ftDate,ftTime:
               begin
                 if (fi=nil) or (fi.fdDataSize=4) then
                 begin
                   if PInteger(P)^=TVarData(KeyValues[i]).VInteger then
                    cResult:=0
                   else
                   if PInteger(P)^>TVarData(KeyValues[i]).VInteger then
                    cResult:=1
                   else
                    cResult:=-1;
                 end
                 else
                 begin
                   if PSmallInt(P)^=TVarData(KeyValues[i]).VInteger then
                    cResult:=0
                   else
                   if PSmallInt(P)^>TVarData(KeyValues[i]).VInteger then
                    cResult:=1
                   else
                    cResult:=-1;
                 end
               end;
               ftFloat  :
               begin
                 if fi=nil then
                 begin
                   if Abs(PDouble(P)^-TVarData(KeyValues[i]).VDouble)<1E-11  then
                    cResult:=0
                   else
                   if PDouble(P)^>TVarData(KeyValues[i]).VDouble then
                    cResult:=1
                   else
                    cResult:=-1;
                 end
                 else
                 begin
                  case fi^.fdDataType of
                   SQL_FLOAT:
                     dv:=PSingle(P)^;
                   SQL_LONG :
                     dv:=PLong(P)^*E10[fi^.fdDataScale];
                   SQL_SHORT:
                     dv:=PShort(P)^*E10[fi^.fdDataScale]
                  else
                   dv:=PDouble(P)^
                  end;

                   if Abs(dv-TVarData(KeyValues[i]).VDouble)<1E-11  then
                    cResult:=0
                   else
                   if dv>TVarData(KeyValues[i]).VDouble then
                    cResult:=1
                   else
                    cResult:=-1;
                 end
               end;

               ftBCD    :
               begin
               {$IFNDEF D6+}
               // Keys don't adjust
                cResult :=ComparePCurrencyAndVariant(p,KeyValues[i]);
               {$ELSE}
                if Int64(P^)=TVarData(KeyValues[i]).VInt64 then
                 cResult:=0
                else
                if Int64(P^)>TVarData(KeyValues[i]).VInt64 then
                 cResult:=1
                else
                 cResult:=-1;
               {$ENDIF}
               end;
               ftBoolean:
               begin
                if Byte(P^)=TVarData(KeyValues[i]).VByte then
                 cResult:=0
                else
                if Byte(P^)>TVarData(KeyValues[i]).VByte then
                 cResult:=1
                else
                 cResult:=-1;
               end;
               ftDateTime :
               begin
                ts:=MSecsToTimeStamp(PDouble(P)^);
                if vDateAdjusted then
                   ts.Time:= ts.Time - (ts.Time mod 1000);
//                 ts.Time:=(ts.Time div 1000)*1000; // TDateTime can't contain Msecs
                dt:=TimeStampToDateTime(ts);
{                if (vDateAdjusted and  (Abs(dt-TVarData(KeyValues[i]).VDate)<1E-5))
                 or (dt=TVarData(KeyValues[i]).VDate)}
                if dt=TVarData(KeyValues[i]).VDate  then
                 cResult:=0
                else
                if dt>TVarData(KeyValues[i]).VDate then
                 cResult:=1
                else
                 cResult:=-1
               end   ;
               ftLargeint:
               {$IFDEF D6+}
                if Int64(P^)=TVarData(KeyValues[i]).VInt64 then
                 cResult:=0
                else
                if Int64(P^)>TVarData(KeyValues[i]).VInt64 then
                 cResult:=1
                else
                 cResult:=-1;
               {$ELSE}
                if Int64(P^)=TVarData(KeyValues[i]).VInteger then
                 cResult:=0
                else
                if Int64(P^)>TVarData(KeyValues[i]).VInteger then
                 cResult:=1
                else
                 cResult:=-1;
               {$ENDIF}
               ftGuid:
               begin
                cResult :=CompareStrAndGuid(PGuid(P),AnsiString(TVarData(KeyValues[i]).VString));
               end;
              end;
              Result:=cResult=0
      end;

var
    fdt  :TFieldType ;

begin
      i := 0; cResult:=0;
      Result := True;
      Arrow :=arForward;
      while (Result  and (i < fld_cnt)) do
      begin
        InitStrValue:=False;
        inWS:=False;
        p:=vCalcBuffer;
        GetFieldDataPointer(TField(fl.List^[i]),RecI,vIsString,p);
        fn:=TField(fl.List^[i]).FieldNo;
        if fn>=1 then
         fi:=vFieldDescrList[fn-1]
        else
         fi:=nil;
       {$IFNDEF D6+}
         if (TField(fl.List^[i]).DataType=ftBCD) and (fn>=1) then
         if p<>nil then
         begin
          tempCurrency:=PComp(p)^*E10[-TBCDField(fl.List^[i]).Size];
          p:=@tempCurrency;
         end;
       {$ENDIF}


        if TVarData(KeyValues[i]).VType = varNull then // After cast. varByRef or varVariant can't be
        begin
          if p=nil then
          begin
            Inc(i);
            Continue;
          end
          else
          begin
            Result := False;
            if (eloInSortedDS in Options) then
             if FIsClientSorting then
              Arrow:=TArrow(vSortInfos[i].Asc)
             else
              Arrow:=TArrow(vSortInfos[i].NullsFirst);
            Exit;
          end;
        end
        else
        begin
          if p=nil then
          begin
            Result := False;
            if (eloInSortedDS in Options) then
             if FIsClientSorting then
              Arrow:=TArrow(not vSortInfos[i].Asc)
             else
              Arrow:=TArrow(not vSortInfos[i].NullsFirst);
            Exit;
          end;
        end;
        fdt  :=TField(fl.List^[i]).DataType;
        {$IFDEF UNICODE_TO_STRING_FIELDS}
         if fdt=ftString then
          fdt:= ftWideString;
        {$ENDIF}
        if Result then
        begin
          if  (Options-[eloInFetchedRecords]=[])
           and ((fdt = ftString)   or ((fdt =ftWideString)  and not Database.NeedUnicodeFieldsTranslation))
          then
          begin
            sKey:=AnsiString(TVarData(KeyValues[i]).VString);

            if Options-[eloInFetchedRecords]=[] then
            begin
             if vIsString then
             begin
              if poTrimCharFields in Self.Options then
              begin
                 L:=Length(PAnsiString(p)^);
                 if (L>0) and (PAnsiString(p)^[L]=' ')  then
                 begin
                  while (L>0) and (PAnsiString(p)^[L]=' ') do
                   Dec(L);
                  Result :=(L=Length(sKey)) and CompareMem(@PAnsiString(p)^[1],@sKey[1],L);
                 end
                 else
                 begin
                  Result :=(L=Length(sKey)) and (sKey=PAnsiString(p)^)
                 end
              end
              else
              begin
               Result :=sKey=PAnsiString(p)^;
              end
             end
             else
             begin
              L:=StrScan(PAnsiChar(p),#0)-PAnsiChar(p);
              if L>TField(fl.List^[i]).Size then
               L:=TField(fl.List^[i]).Size;
              if poTrimCharFields in Self.Options then
               while (L>0) and (PAnsiChar(p)[L-1]=' ') do
                Dec(L);
              Result :=(L=Length(sKey)) and CompareMem(PAnsiChar(p),@sKey[1],L);
             end;
            end
          end
          else
//          case TField(fl.List^[i]).DataType  of
           case fdt  of

            ftString:
            begin
             sKey:=AnsiString(TVarData(KeyValues[i]).VString);
             InitStrValue:=True;
             if vIsString then
             begin
              StrValue:=PAnsiString(p)^;
              UniqueString (StrValue);
              if poTrimCharFields in Self.Options then
              begin
               L:=Length(StrValue) ;
               while (L>0) and (PAnsiChar(p)[L-1]=' ') do
                Dec(L);
               SetLength(StrValue,L)
              end;
          //      DoTrimRight(StrValue)
             end
             else
             begin
              L:=StrScan(PAnsiChar(p),#0)-PAnsiChar(p);
              if L>TField(fl.List^[i]).Size then
               L:=TField(fl.List^[i]).Size;

              if poTrimCharFields in Self.Options then
              while (L>0) and (PAnsiChar(p)[L-1]=' ') do
               Dec(L);
              SetString(StrValue,PAnsiChar(p),L);
             end;

             if (TField(fl.List^[i]) is TFIBStringField) and
               Database.NeedUnicodeFieldTranslation(Byte(TFIBStringField(fl.List^[i]).SqlSubType))
             then
              UDFUtf8DecodeA(StrValue);

             if (eloPartialKey in Options) then
             begin
              if (eloCaseInsensitive in Options) then
               {$IFDEF D2009+}
                DoAnsiUpperCase(StrValue)   ;
               {$ELSE}
                StrValue:=AnsiUpperCase(StrValue);
               {$ENDIF}
              Result :=IsBeginPartStr(sKey,StrValue)
             end
             else
             if  (eloWildCards in Options) then
             begin
              if (eloCaseInsensitive in Options) then
               {$IFDEF D2009+}
                DoAnsiUpperCase(StrValue)    ;
               {$ELSE}
                StrValue:=AnsiUpperCase(StrValue);
               {$ENDIF}
              Result:= SQLMaskCompareAA(StrValue,sKey)
             end
             else
             if (eloCaseInsensitive in Options) then
             begin //eloCaseInsensitive in Options
              {$IFDEF D2009+}
               Result:=AnsiCompareTextAA(sKey, StrValue)=0;
              {$ELSE}
               Result:=AnsiCompareText(sKey, StrValue)=0;
              {$ENDIF}
             end
             else
             // eloSorted
               Result:=sKey = StrValue
            end;
            ftWideString:
            begin
            // Options<>[]
              inWS:=True;
              WideKey:=TVarData(KeyValues[i]).VOleStr;
              begin
               if vIsString then
               begin
                DoUtf8Decode(PAnsiString(p)^,WideValue);
                if poTrimCharFields in Self.Options then
                   DoTrimRight(WideValue)
               end
               else
               begin
                if TField(fl.List^[i]).FieldNo<0 then
                begin
                  {$IFDEF D2009+}
                   {$IFDEF D_XE}
                    WideValue:=PWideChar(p)
                   {$ELSE}
                    WideValue:=UTF8ToString(PAnsiChar(P))
                   {$ENDIF}
          			 {$ELSE}
                    WideValue:=UTF8Decode(PChar(P))
			           {$ENDIF}
                    ;
//                  WideValue:=PWideChar(p);
                  if poTrimCharFields in Self.Options then
                   DoTrimRight(WideValue)
                end
                else
                begin
                  L:=StrScan(PAnsiChar(p),#0)-PAnsiChar(p);
                  if L>TField(fl.List^[i]).DataSize-1 then
                   L:=TField(fl.List^[i]).DataSize-1;

                  if poTrimCharFields in Self.Options then
                  while (L>0) and (PAnsiChar(p)[L-1]= ' ') do
                   Dec(L);
                  SetString(StrValue,PAnsiChar(p),L);
                  DoUtf8Decode(StrValue,WideValue);
                end
               end;

               if (eloPartialKey in Options) then
               begin
                if (eloCaseInsensitive in Options) then
                 DoWideUpperCase(WideValue);
                Result :=IsBeginPartStr(WideKey,WideValue)
               end
               else
               if  (eloWildCards in Options) then
               begin
                if (eloCaseInsensitive in Options) then
                 DoWideUpperCase(WideValue);
                Result:= SQLMaskCompare(WideValue,WideKey)
               end
               else
                if (eloCaseInsensitive in Options) then
                {$IFDEF D6+}
                 Result:=WideCompareText(WideValue,WideKey)=0 //eloCaseInsensitive in Options
                {$ELSE}
                begin
                 DoWideUpperCase(WideValue);
                 Result:=WideValue=WideKey
                end 
                {$ENDIF}
                else
                 Result:=WideKey=WideValue

              end
            end       // ftWideString *)
            else
             Result:=NonStrFieldCompare
            end
          end;


         if not Result and (eloInSortedDS in Options) then
         begin
         // for sorted
          ChangeArrowInSorted;
          Exit;
        end;
        Inc(i);
      end;

end;

procedure FindFirst;
var
   GoodRec:Integer;
   sRecI  :Integer;
begin
  // Already find  record in sorted dataset
  // Goto first suitable record
  if (LocateKind<>lkStandard) or not (eloInSortedDS in Options) then
    Exit;
  sRecI:=RecI;
  if IsVisibleRecord and (RecI+1<>vIgnoreLocRecno) then
   GoodRec:=RecI
  else
   GoodRec:=-1;
  while Result and (RecI>0)  do
  begin
   Dec(RecI);
   if IsVisibleRecord and (RecI+1<>vIgnoreLocRecno)  then
   begin
    Result:=CompareValues;
    if Result then
     GoodRec:=RecI;
   end;
  end;
  if GoodRec>-1 then
  begin
    RecI:=GoodRec;
    Result := True;
    Exit;
  end
  else
  begin
   RecI:=sRecI;
   Result := True;
   while Result and(RecI<FRecordCount-1) do
   begin
    Inc(RecI);     
    if IsVisibleRecord and (RecI+1<>vIgnoreLocRecno) then
    begin
      Result:=CompareValues;
      if Result then
      begin
       GoodRec:=RecI;
       Break
      end;
    end;
   end;
   if GoodRec>-1 then
   begin
    RecI:=GoodRec;
    Result := True;
   end
   else
    Result :=False
  end;
end;

begin
  CheckActive;
  Result := False;
  vCalcBuffer:=nil;  
  if IsEmpty then
   Exit;
  rc:=-1;
  rc1:=-1;
  if State in [dsEdit,dsInsert] then
   Post;
  NowInFetched:=True;
  vIgnoreRecChecked  :=False;
  fl := TFIBList.Create;
  try
    GetFieldList(fl, KeyFields);
    fld_cnt     := fl.Count;
//    SetLength(wsA,fl.Count);
    if fl.Count=0 then
     Exit;


    vDateAdjusted:=False;     
    Result      := False;

    AdjustKeys;
    if InitSortInfos then
      Include(Options,eloInSortedDS)   // Force use SortInfo
    else
      Exclude(Options,eloInSortedDS); // SortInfo not Valid

    if FromBegin then
    begin
     if FCacheModelOptions.FCacheModelKind=cmkStandard then
      RecI := 0
     else
      RecI :=vPartition.BeginPartRecordNo;
     if RecI+1=vIgnoreLocRecno then
     begin
       Inc(RecI);
       if RecI >= FRecordCount then
         Exit;
     end;
    end
    else
    case LocateKind of
     lkNext :
     begin
      RecI :=GetRealRecNo;
      if RecI+1=vIgnoreLocRecno then
       Inc(RecI);

      case FCacheModelOptions.CacheModelKind  of
       cmkStandard :
         if RecI >= FRecordCount then
          begin
           if FetchNext(RecI-FRecordCount+1)<RecI-FRecordCount+1 then
            Exit;
          end;
      else
       IsFinishSearch;
       if FinishSearch then
        Exit;
      end;
     end;
     lkPrior:
     begin
      RecI :=GetRealRecNo-2;
      if RecI+1=vIgnoreLocRecno then
       Dec(RecI);
     end;
     lkStandard:RecI :=0;
    end;
    if FCacheModelOptions.CacheModelKind=cmkStandard then
    begin
     if RecI >= FRecordCount then
      RecI := FRecordCount-1;
    end;
    if (eloInSortedDS in Options) then
    begin
      Result:= CompareValues;

      if  not Result then
      begin
        case LocateKind of
         lkStandard,lkNext :
            if Arrow=arBackward then
                   Exit;
         lkPrior: if Arrow=arForward then
                    Exit;
        end;
        RecI:=FRecordCount-1;
        if (RecI+1=vIgnoreLocRecno) then
        if RecI=0 then
         Exit 
        else
        begin
          Dec(RecI); 
          vIgnoreRecChecked:=True
        end;
        Result:=CompareValues;
      end;
      if Result then
      begin
        FindFirst;
        Exit;
      end;

      if Arrow=arForward then
      begin
//     Data no fetched yet
       NowInFetched:=False;
       RecI:=FRecordCount;
       if (eloInFetchedRecords in Options) or (FetchNext(1)= 0) then
        Exit;
      end
      else
      begin
       rc1:=RecI;
       RecI:=0;
       if (vIgnoreLocRecno=1) then
        if  not vIgnoreRecChecked  then
        begin
         Inc(RecI);
         vIgnoreRecChecked:=True
        end;
        rc:=RecI
      end;
    end;

    IsFinishSearch;

    while (not Result) and not FinishSearch do
    begin
      if (eloInSortedDS in Options) and NowInFetched then
      begin
       if rc=vIgnoreLocRecno then
        Inc(rc);
       if rc1=vIgnoreLocRecno then
        Dec(rc1);
       if  (rc>rc1) then
        Break;

       RecI:=((rc1+rc) div 2);
       if (RecI+1=vIgnoreLocRecno) then
       begin
         if  vIgnoreRecChecked then
          Exit
         else
         begin
          Inc(RecI);
          vIgnoreRecChecked:=True
         end;
       end;
      end;
      Result:=CompareValues;

      if Result then
      begin
       if (eloInSortedDS in Options) then
       begin
        FindFirst;
        Exit;
       end
       else
        Result:=IsVisibleRecord;
      end;

      if not Result then
       if (eloInFetchedRecords in Options) then
       begin
         case LocateKind of
          lkStandard,lkNext:
          begin
           Inc(RecI);
           IsFinishSearch;
          end;
          lkPrior:
          begin
           Dec(RecI);
           IsFinishSearch;
          end;
         end;
       end
       else
       if not (eloInSortedDS in Options) then
       begin
        if LocateKind=lkPrior then
        begin
           Dec(RecI);
           IsFinishSearch;
        end
        else
        begin
          Inc(RecI);
          IsFinishSearch;
        end;
       end
       else
// eloInSortedDS in Options
       if NowInFetched then
       begin
         case Arrow of
         arForward :
             begin
              if rc=RecI+1 then
                Break
              else
               rc:=RecI+1;
             end;
         else
          if rc1=RecI-1 then
           Break
          else
           rc1:=RecI-1;
         end
       end
       else
       begin
        case Arrow of
         arForward :
         begin
          Inc(RecI);
          IsFinishSearch;
         end;
         arBackward:
          Break
        end
       end
    end;

  finally
    fl.Free;
    FreeMem(vCalcBuffer);
    if Result then
    begin
       SetRealRecno(RecI+1,ResyncToCenter);
       CursorPosChanged;
       DataEvent(deDataSetChange,0)
    end
    else
    if (eloNearest in Options) and (eloInSortedDS in Options)
    then
    begin
       if  (Arrow=arForward) then
        SetRealRecno(RecI+2,ResyncToCenter)
       else
        SetRealRecno(RecI+1,ResyncToCenter);
       DataEvent(deDataSetChange,0);        
       CursorPosChanged;
    end;
  end;
end;
{$ENDIF}
