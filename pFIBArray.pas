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



unit pFIBArray;
{$I FIBPlus.inc}

interface

uses
  SysUtils, Classes, ibase,IB_Intf, ib_externals,
  DB, fib, FIBDatabase, StdFuncs,FIBPlatforms
  {$IFDEF D6+}, Variants{$ENDIF}
  ;

 {$IFDEF SUPPORT_ARRAY_FIELD}
 type

   TpFIBArray=class
      private
       FClientLibrary:IIBClientLibrary;
       FXSQLVAR:PXSQLVAR;
       FArrayType:TFieldType;
       FTableName:Ansistring;
       FFieldName:Ansistring;
       vISC_ARRAY_DESC:TISC_ARRAY_DESC;
       function GetDimensionCount:Integer;
       function GetDimension(Index: Integer): TISC_ARRAY_BOUND;
       function GetSliceSize(aISC_ARRAY_DESC:TISC_ARRAY_DESC):integer;
       function GetArraySize:integer;
       procedure VariantToBuffer(Value:Variant;var ToBuffer:TDataBuffer);
       procedure PutArrayBuf(var Buffer,ToBuffer:TDataBuffer;
        DBHandle:PISC_DB_HANDLE;TRHandle: PISC_TR_HANDLE
       );
       function GetElementBuf(Buffer:TDataBuffer;
         aISC_ARRAY_DESC:TISC_ARRAY_DESC;
         DBHandle:PISC_DB_HANDLE;TRHandle: PISC_TR_HANDLE
       ):Variant;
       procedure PutElementBuf(Value:Variant;var ToBuffer:TDataBuffer;
        aISC_ARRAY_DESC:TISC_ARRAY_DESC;
        DBHandle:PISC_DB_HANDLE;TRHandle: PISC_TR_HANDLE
       );

       function GetFieldData(Field:TField;var ToBuffer:TDataBuffer):boolean;
       function GetScale: Byte;

      public
       constructor Create(ClientLibrary:IIBClientLibrary;aFXSQLVAR:PXSQLVAR;
        DBHandle: PISC_DB_HANDLE;
        TRHandle: PISC_TR_HANDLE;
        const ATableName,AFieldName:string
       ); overload;

       destructor Destroy; override;
       function GetArrayValues(bufData:TDataBuffer;
         DBHandle:PISC_DB_HANDLE;TRHandle: PISC_TR_HANDLE
       ):Variant;                         // for Internal use from FibQuery
       procedure SetArrayValue(Value:Variant;var ToBuffer:TDataBuffer;
         DBHandle:PISC_DB_HANDLE;TRHandle: PISC_TR_HANDLE
       );                                // for Internal use from FibQuery
       function GetFieldArrayValues(Field:TField;
         DBHandle:PISC_DB_HANDLE;TRHandle: PISC_TR_HANDLE
       ):Variant;  // for Internal use from DataSet
       procedure SetFieldArrayValue(Value:Variant;Field:TField;
         DBHandle:PISC_DB_HANDLE;TRHandle: PISC_TR_HANDLE
       );        // for Internal use  from DataSet

       function GetElementFromField(
        Field:TField;Indexes:array of integer;
        DBHandle:PISC_DB_HANDLE;TRHandle: PISC_TR_HANDLE
       ):Variant;        // for Internal use  from DataSet

       procedure PutElementToField(Field:TField;Value:Variant;
        Indexes:array of integer;
        DBHandle:PISC_DB_HANDLE;TRHandle: PISC_TR_HANDLE
       );        // for Internal use  from DataSet


      public
       property ArrayType:TFieldType read FArrayType;

       property TableName:Ansistring read FTableName;
       property FieldName:Ansistring read FFieldName;

       property DimensionCount:Integer read GetDimensionCount;
       property Dimension[Index: Integer]: TISC_ARRAY_BOUND read GetDimension;
       property ArraySize:Integer read GetArraySize;
       property Scale:Byte read GetScale;
      end;
    {$ENDIF}
implementation

{$IFDEF SUPPORT_ARRAY_FIELD}
uses FIBDataSet,VariantRtn,StrUtil;
{
type

 TTraceArr=array [0..1] of  INT64;
 PTraceArr=^TTraceArr;


var
 TraceArr:TTraceArr;
}

{$IFNDEF D6+}
 type
  PComp=^Comp;
{$ENDIF}

const MaxDimCount=64;


 threadvar
 // vars for Callback functions from VariantRtn
   glBufArField:TDataBuffer;
   glArrayType :TFieldType;
   glScale     :integer;
   glErrInt    :byte;
   glISC_ARRAY_DESC:TISC_ARRAY_DESC;
   glCount     :Integer;
   glBufIsNull :boolean;
   TracePChar  :TDataBuffer;
   CurIBLib    :IIBClientLibrary;

constructor TpFIBArray.Create(ClientLibrary:IIBClientLibrary;aFXSQLVAR:PXSQLVAR;
        DBHandle: PISC_DB_HANDLE;
        TRHandle: PISC_TR_HANDLE;

        const ATableName,AFieldName:string

);
begin
 inherited Create;
 FClientLibrary :=ClientLibrary;
 with FClientLibrary do
 try
   FXSQLVAR       :=aFXSQLVAR;
   FTableName     :=ATableName;
   FFieldName     :=AFieldName;

   isc_array_lookup_bounds(StatusVector, DBHandle, TRHandle,
      PAnsiChar(FTableName), PAnsiChar(FFieldName), @vISC_ARRAY_DESC
   );
    with vISC_ARRAY_DESC do
    begin

      case array_desc_dtype of
        Blr_int64 :            FArrayType := ftBCD;
        Blr_text, Blr_Varying: FArrayType := ftString;
        Blr_Short:             FArrayType := ftSmallint;
        Blr_Long:              FArrayType := ftInteger;
        Blr_Float, Blr_Double,
        Blr_D_Float:           FArrayType := ftFloat;
        Blr_Date:              FArrayType := ftDateTime;
        Blr_sql_date:          FArrayType := ftDate;
        Blr_sql_time:          FArrayType := ftTime;
      end;
    end;

 except
   IbError(ClientLibrary,Self)
 end;
end;

destructor TpFIBArray.Destroy;
begin
  FClientLibrary:=nil;
  inherited;
end;

function TpFIBArray.GetScale: Byte;
begin
 Result:=
  256-Byte(vISC_ARRAY_DESC.array_desc_scale)
end;

function TpFIBArray.GetDimensionCount:Integer;
begin
 Result:=vISC_ARRAY_DESC.array_desc_dimensions
end;


function TpFIBArray.GetDimension(Index: Integer): TISC_ARRAY_BOUND;
begin
 if Index in [0..DimensionCount] then
   Result := vISC_ARRAY_DESC.array_desc_bounds[Index]
 else
  FIBError(feWrongDimension,[Index,FTableName+'.'+FFieldName])
end;

function TpFIBArray.GetSliceSize(aISC_ARRAY_DESC:TISC_ARRAY_DESC):integer;
var i:integer;
    DataSize:integer;
begin
{  Result := 0;
  with aISC_ARRAY_DESC do
  begin
   DataSize:=array_desc_length;
   if array_desc_dtype=Blr_Varying then   Inc(DataSize, 2);
   for i := 0 to Pred(DimensionCount)  do
    Inc(Result,
     DataSize *
     (array_desc_bounds[i].array_bound_upper -
      array_desc_bounds[i].array_bound_lower+ 1
     )
    );
   if array_desc_dtype=Blr_Varying then   Inc(Result, 2);
  end;}
  Result := 1;
  with aISC_ARRAY_DESC do
  begin
   DataSize:=array_desc_length;
   if array_desc_dtype=Blr_Varying then   Inc(DataSize, 2);
   //HONCHAROV 3A
   for i := 0 to Pred(DimensionCount)  do
   begin
    Result := Result *  (array_desc_bounds[i].array_bound_upper -
      array_desc_bounds[i].array_bound_lower+ 1);
   end;
   Result := Result * DataSize;
  end;

end;

function TpFIBArray.GetArraySize:integer;
begin
 Result:=GetSliceSize(vISC_ARRAY_DESC)
end;


procedure ReadElementFromBuffer(
 OldValue:Variant; IndexValue:array of integer;
 Var NewValue:Variant;  Var Continue:boolean
);
type
    PSmall=^Smallint;
var s:Ansistring;
    tm_date: TCTimeStructure;
    p:Pointer;
begin
   p:=glBufArField+glISC_ARRAY_DESC.array_desc_length*(glCount);

   with CurIBLib   ,glISC_ARRAY_DESC do
     if   glBufIsNull then
      NewValue:=null
     else
     case glArrayType  of //
      ftString   :
       begin
         S := PAnsiChar(glBufArField + (array_desc_length + glErrInt) * glCount);
         if glErrInt > 0 then S := FastCopy(S, 1, Length(S) - 1);
         NewValue := S;
       end;
      ftSmallint :   NewValue:=PSmall(p)^;
      ftInteger  :   NewValue:=PInteger(p)^;
      ftFloat    :   NewValue:=PDouble(p)^;
      ftDate :
      begin
        isc_decode_sql_date(PISC_DATE(p), @tm_date);
        try
          NewValue:=EncodeDate(Word(tm_date.tm_year + 1900), Word(tm_date.tm_mon + 1),
                               Word(tm_date.tm_mday)) ;
        except
        end;
      end;
      ftTime :
      begin
        isc_decode_sql_time(PISC_TIME(p), @tm_date);
        try
          NewValue:=
          EncodeTime(Word(tm_date.tm_hour), Word(tm_date.tm_min),
                 Word(tm_date.tm_sec), (PISC_TIME(p)^ mod 10000) div 10);
        except
        end;
      end;
      ftDateTime :
      begin
        isc_decode_date(PISC_QUAD(p), @tm_date);
        try
        NewValue:=EncodeDate(Word(tm_date.tm_year + 1900), Word(tm_date.tm_mon + 1),
                               Word(tm_date.tm_mday)) ;

        if NewValue>=0 then
          NewValue:=NewValue +
           EncodeTime(Word(tm_date.tm_hour), Word(tm_date.tm_min),
            Word(tm_date.tm_sec),(PISC_QUAD(p)^.gds_quad_low mod 10000) div 10
           )
        else
         NewValue:=NewValue -
          EncodeTime(Word(tm_date.tm_hour), Word(tm_date.tm_min),
           Word(tm_date.tm_sec),(PISC_QUAD(p)^.gds_quad_low mod 10000) div 10
          )
        except
        end;
      end;
      ftBCD:
       NewValue:=PInt64(p)^*E10[-glScale];
     else
     // under construction

     end; // end Case
   Inc(glCount)
end;




function TpFIBArray.GetArrayValues(
  bufData:TDataBuffer; DBHandle:PISC_DB_HANDLE;TRHandle: PISC_TR_HANDLE
):Variant;
var i,j:integer;
    ArrSize:integer;
    Buffer: TDataBuffer;
    a:array of   Integer;
begin
 j:=0;
 SetLength(a,DimensionCount*2);
 for i:=0 to Pred(DimensionCount) do
 begin
   a[j]:=Dimension[i].array_bound_lower ;
   a[j+1]:=Dimension[i].array_bound_upper ;
   Inc(j,2);
 end;

 Result :=VarArrayCreate(a,  varVariant);
 ArrSize:=GetArraySize;
 Buffer := nil;
 FIBAlloc(Buffer, 0, ArrSize + 1);
 with FClientLibrary do
 try
  isc_array_get_slice (
   StatusVector, DBHandle, TRHandle,
   PISC_QUAD(bufData), @vISC_ARRAY_DESC, Pointer(Buffer) ,LongInt(@ArrSize)
  );
 with vISC_ARRAY_DESC do
  if array_desc_dtype=Blr_Varying then
   glErrInt:=2
  else
   glErrInt:=0;
  glBufIsNull :=ArrSize=0;
  glBufArField:=Buffer;
  glArrayType :=FArrayType;
  glScale     :=Scale;
  glISC_ARRAY_DESC:=vISC_ARRAY_DESC;
  glCount     :=0;
  CurIBLib    := FClientLibrary;
  CycleWriteArray(Result,ReadElementFromBuffer);
 finally
  FIBAlloc(Buffer, 0, 0);
 end;
end;

function TpFIBArray.GetFieldData(Field:TField;var ToBuffer:TDataBuffer):boolean;
begin
  ToBuffer:=nil;
  FIBAlloc(ToBuffer,0,ArraySize);
  Result:=Field.GetData(ToBuffer);
  if not Result then
  begin
    PISC_QUAD(ToBuffer)^.gds_quad_low:=0;
    PISC_QUAD(ToBuffer)^.gds_quad_high:=0;
  end;
end;

function TpFIBArray.GetFieldArrayValues(Field:TField;
         DBHandle:PISC_DB_HANDLE;TRHandle: PISC_TR_HANDLE
       ):Variant;
var
  Buffer:TDataBuffer;
begin
  GetFieldData(Field,Buffer);
  try
    Result:=GetArrayValues(Buffer, DBHandle,TRHandle);
  finally
    FreeMem(Buffer);
  end;
end;


procedure WriteElementToBuffer(Value:Variant; IndexValue:array of integer;
       const HighBoundInd:integer;
       Var Continue:boolean
      );

var
  bufInt:integer;
  bufSmInt:SmallInt;
  bufStr:Ansistring;
  bufDouble:Double;
  p:Pointer;
  tm_date: TCTimeStructure;
  Yr, Mn, Dy, Hr, Mt, S, Ms: Word;
  bufInt64:Int64;
begin
   with CurIBLib   do
   case glArrayType of //glArrayType
     ftString: if not VarIsEmpty(Value) then
              begin
                if VarIsNull(Value) then
                 bufStr:=#0
                else
                 bufStr:=VarToStr(Value);
               if glErrInt>0 then bufStr:=bufStr+#10#0;
               p:=TDataBuffer(bufStr);
               Move(p^,glBufArField^,Length(bufStr));
              end;
    ftSmallint:if not VarIsEmpty(Value) then
               begin
                if VarIsNull(Value) then
                 bufSmInt:=0
                else
                 bufSmInt:=VarAsType(Value,varSmallint);
                 Move(bufSmInt,glBufArField^,SizeOf(bufSmInt));
               end;
     ftInteger: if not VarIsEmpty(Value) then
                begin
                if VarIsNull(Value) then
                 bufInt:=0
                else
                 bufInt:=VarAsType(Value,varInteger);
                 Move(bufInt,glBufArField^,SizeOf(bufInt));
                end;
     ftFloat : if not VarIsEmpty(Value) then
               begin
                if VarIsNull(Value) then
                 bufDouble:=0
                else
                 bufDouble:=VarAsType(Value,varDouble);
                Move(bufDouble,glBufArField^,SizeOf(bufDouble));
               end;
     ftDate : if not VarIsEmpty(Value) then
                 begin
                  if VarIsNull(Value) then
                   Value:=EncodeDate(1858,11,17)
                  else
                   Value:=VarToDateTime(Value);
                   DecodeDate(Value, Yr, Mn, Dy);
                   DecodeTime(Value, Hr, Mt, S, Ms);
                   with tm_date do
                   begin
                     tm_sec :=  S;
                     tm_min :=  Mt;
                     tm_hour := Hr;
                     tm_mday := Dy;
                     tm_mon :=  Mn - 1;
                     tm_year := Yr - 1900;
                   end;
                  isc_encode_sql_date(@tm_date, PISC_DATE(glBufArField));
                 end;
     ftTime : if not VarIsEmpty(Value) then
                 begin
                  if VarIsNull(Value) then
                   Value:=EncodeDate(1858,11,17)
                  else
                   Value:=VarToDateTime(Value);
                   DecodeDate(Value, Yr, Mn, Dy);
                   DecodeTime(Value, Hr, Mt, S, Ms);
                   with tm_date do
                   begin
                     tm_sec :=  S;
                     tm_min :=  Mt;
                     tm_hour := Hr;
                     tm_mday := Dy;
                     tm_mon :=  Mn - 1;
                     tm_year := Yr - 1900;
                   end;
                   isc_encode_sql_time(@tm_date, PISC_TIME(glBufArField));
                 end;
     ftDateTime:
                if not VarIsEmpty(Value) then
                 begin
                  if VarIsNull(Value) then
                   Value:=EncodeDate(1858,11,17)
                  else
                   Value:=VarToDateTime(Value);
                   DecodeDate(Value, Yr, Mn, Dy);
                   DecodeTime(Value, Hr, Mt, S, Ms);
                   with tm_date do
                   begin
                     tm_sec :=  S;
                     tm_min :=  Mt;
                     tm_hour := Hr;
                     tm_mday := Dy;
                     tm_mon :=  Mn - 1;
                     tm_year := Yr - 1900;
                   end;
                   isc_encode_date(@tm_date, PISC_QUAD(glBufArField));
                 end;
     ftBCD:
      if not VarIsEmpty(Value) then
      begin
        if VarIsNull(Value) then
         FillChar(glBufArField^,SizeOf(bufInt64),0)
        else
        begin
          {$IFDEF D6+}
           bufInt64:=Value*E10[glScale];
          {$ELSE}
           PComp(@bufInt64)^:=Value*E10[glScale];
          {$ENDIF}
           Move(bufInt64,glBufArField^,SizeOf(bufInt64));

        end;
      end;
   end;
   glBufArField:=glBufArField+glISC_ARRAY_DESC.array_desc_length+glErrInt;
end;


procedure TpFIBArray.VariantToBuffer(Value:Variant;var ToBuffer:TDataBuffer);
var
  ArrSize:integer;
begin
// procedure for Write to Buffer of Array Field
 if not VarIsArray(Value) then
  Exit;
 if VarArrayDimCount(Value) >DimensionCount then
  FIBError(feWrongDimension,[integer(Value),
    FTableName+'.'+FFieldName
  ]);
 ArrSize:=GetArraySize;
 FIBAlloc(ToBuffer, 0, ArrSize + 1);
 with vISC_ARRAY_DESC do
 if array_desc_dtype=Blr_Varying then
  glErrInt:=2
 else
  glErrInt:=0;

 glBufArField:=ToBuffer;
 TracePChar  :=ToBuffer;
 glArrayType :=FArrayType;
 glScale     :=Scale;
 glISC_ARRAY_DESC:=vISC_ARRAY_DESC;
 CurIBLib    := FClientLibrary;
 CycleReadArray(Value,WriteElementToBuffer);
end;

function TpFIBArray.GetElementBuf(Buffer:TDataBuffer;
         aISC_ARRAY_DESC:TISC_ARRAY_DESC;
         DBHandle:PISC_DB_HANDLE;TRHandle: PISC_TR_HANDLE
       ):Variant;
var
  SliceSize:integer;
  Fake:boolean;
  FakeVar:Variant;
  BufElement:TDataBuffer;
begin
  SliceSize:=GetSliceSize(aISC_ARRAY_DESC);
  BufElement:=nil;
  FIBAlloc(BufElement, 0, SliceSize+1);
  with FClientLibrary do
  try
   isc_array_get_slice    (
    StatusVector, DBHandle, TRHandle,
    PISC_QUAD(Buffer) ,
    @aISC_ARRAY_DESC, Pointer(BufElement) ,LongInt(@SliceSize)
   );
   glBufIsNull :=SliceSize=0;
   glBufArField:=BufElement;
   glArrayType :=FArrayType;
   glScale:=Scale;   
   glCount     :=0;
   ReadElementFromBuffer(FakeVar, [1], Result, Fake);
  finally
   FreeMem(BufElement);
  end;
end;

procedure TpFIBArray.PutElementBuf(Value:Variant;var ToBuffer:TDataBuffer;
        aISC_ARRAY_DESC:TISC_ARRAY_DESC;
        DBHandle:PISC_DB_HANDLE;TRHandle: PISC_TR_HANDLE
);
var
  SliceSize:integer;
  Buffer :TDataBuffer;
  Fake   :boolean;
  ArrayId:TISC_QUAD;
begin
  SliceSize:=GetSliceSize(aISC_ARRAY_DESC);
  Buffer:=nil;
  FIBAlloc(Buffer, 0, SliceSize + 1);
  with FClientLibrary do
  try
   glBufArField:=Buffer;
   glArrayType :=FArrayType;
   glScale:=Scale;
   WriteElementToBuffer(Value,[1],0,Fake);
   ArrayId:=PISC_QUAD(ToBuffer)^;
   isc_array_put_slice    (
    StatusVector, DBHandle, TRHandle,
    PISC_QUAD(ToBuffer) ,
    @aISC_ARRAY_DESC, Pointer(Buffer) ,@SliceSize
   );
  finally
   FIBAlloc(Buffer, 0, 0);
  end;
end;


procedure TpFIBArray.PutArrayBuf(var Buffer,ToBuffer:TDataBuffer;
        DBHandle:PISC_DB_HANDLE;TRHandle: PISC_TR_HANDLE
);
var
  ArrSize:integer;
begin
  ArrSize:=GetArraySize;

  FClientLibrary.isc_array_put_slice    (
   StatusVector, DBHandle, TRHandle,
    PISC_QUAD(ToBuffer) ,
    @vISC_ARRAY_DESC, Pointer(Buffer) ,@ArrSize
  );

end;


procedure TpFIBArray.SetArrayValue(Value:Variant;
         var ToBuffer:TDataBuffer;
         DBHandle:PISC_DB_HANDLE;TRHandle: PISC_TR_HANDLE
);
var
  Buffer: TDataBuffer;
begin
 Buffer := nil;
 FIBAlloc(Buffer, 0, GetArraySize + 1);
 try
  VariantToBuffer(Value,Buffer);
  PutArrayBuf(Buffer,ToBuffer, DBHandle,TRHandle);
 finally
  FIBAlloc(Buffer, 0, 0);
 end;
end;

type THDataSet=class(TFIBDataSet);

procedure TpFIBArray.SetFieldArrayValue(Value:Variant;Field:TField;
         DBHandle:PISC_DB_HANDLE;TRHandle: PISC_TR_HANDLE
);
var ValueBuffer:TDataBuffer;
    EditBuffer :TDataBuffer;
begin
  ValueBuffer:=nil;
  GetFieldData(Field,EditBuffer);
  try
    VariantToBuffer(Value,ValueBuffer);
    PutArrayBuf(ValueBuffer,EditBuffer,DBHandle,TRHandle);
    {$IFDEF D_XE3}
      THDataSet(Field.DataSet).SetFieldData(Field, EditBuffer);
    {$ELSE}
     Field.SetData(EditBuffer);
    {$ENDIF}
  finally
    FIBAlloc(ValueBuffer,0,0);
  end;
end;

function TpFIBArray.GetElementFromField(
        Field:TField;Indexes:array of integer;
        DBHandle:PISC_DB_HANDLE;TRHandle: PISC_TR_HANDLE
       ):Variant;        // for Internal use  from DataSet
var
   i:integer;
   loc_ISC_ARRAY_DESC:TISC_ARRAY_DESC;
   EditBuffer:TDataBuffer;
begin
  loc_ISC_ARRAY_DESC:=vISC_ARRAY_DESC;
  with loc_ISC_ARRAY_DESC do
   for i:=Low(Indexes) to High(Indexes) do
   begin
    array_desc_bounds[i].array_bound_upper:=Indexes[i];
    array_desc_bounds[i].array_bound_lower:=Indexes[i];
   end;
   GetFieldData(Field,EditBuffer);
   Result:=GetElementBuf(EditBuffer,
            loc_ISC_ARRAY_DESC, DBHandle,TRHandle
           );
   FreeMem(EditBuffer);           
end;

procedure TpFIBArray.PutElementToField(Field:TField;Value:Variant;
        Indexes:array of integer;
        DBHandle:PISC_DB_HANDLE;TRHandle: PISC_TR_HANDLE
       );        // for Internal use  from DataSet

var
   i:integer;
   loc_ISC_ARRAY_DESC:TISC_ARRAY_DESC;
   EditBuffer:TDataBuffer;
begin
  loc_ISC_ARRAY_DESC:=vISC_ARRAY_DESC;
  with loc_ISC_ARRAY_DESC do
   for i:=Low(Indexes) to High(Indexes) do
   begin
    array_desc_bounds[i].array_bound_upper:=Indexes[i];
    array_desc_bounds[i].array_bound_lower:=Indexes[i];
   end;
   GetFieldData(Field,EditBuffer);
   PutElementBuf(Value,EditBuffer,
         loc_ISC_ARRAY_DESC, DBHandle,TRHandle
   );
   Field.SetData(EditBuffer);
   FreeMem(EditBuffer);
end;


{$ENDIF}


end.


