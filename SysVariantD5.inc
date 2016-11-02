const
  oleaut = 'oleaut32.dll';
  MaxDimCount=16;


function SafeArrayGetElement(VarArray: PVarArray; Indices,
  Data: Pointer): Integer; stdcall;
  external oleaut name 'SafeArrayGetElement';

function SafeArrayPutElement(VarArray: PVarArray; Indices,
  Data: Pointer): Integer; stdcall;
  external oleaut name 'SafeArrayPutElement';

function SafeArrayPtrOfIndex(VarArray: PVarArray; Indices: Pointer;
  var pvData: Pointer): HResult; stdcall;
  external oleaut name 'SafeArrayPtrOfIndex';

type
  TVarArrayBoundArray = array[0..MaxDimCount-1] of TVarArrayBound;




function GetVarArray(const A: Variant): PVarArray;
begin
  if TVarData(A).VType and varByRef <> 0 then
    Result := PVarArray(TVarData(A).VPointer^) else
    Result := TVarData(A).VArray;
end;


function _VarArrayGet(var A: Variant; IndexCount: Integer;
  Indices: Integer): Variant; cdecl;
var
  VarArrayPtr: PVarArray;
  VarType: Integer;
  P: Pointer;
begin
  if TVarData(A).VType and varArray = 0 then
   raise Exception.Create(reVarNotArray);
  VarArrayPtr := GetVarArray(A);
  if VarArrayPtr^.DimCount <> IndexCount then
     raise Exception.Create(reVarArrayBounds);
  VarType := TVarData(A).VType and varTypeMask;
  VarClear(Result);
  if VarType = varVariant then
  begin

    {$IFDEF WINDOWS}
    if SafeArrayPtrOfIndex(VarArrayPtr, @Indices, P) <> 0 then
    {$ELSE}
    if SafeArrayPtrOfIndex(VarArrayPtr, PVarArrayCoorArray(@Indices), P) <> 0 then
    {$ENDIF}
     raise Exception.Create(reVarArrayBounds);
    Result := PVariant(P)^;
  end
  else
  begin
  {$IFDEF WINDOWS}
  if SafeArrayGetElement(VarArrayPtr, @Indices,
      @TVarData(Result).VPointer) <> 0 then
  {$ELSE}
  if SafeArrayGetElement(VarArrayPtr, PVarArrayCoorArray(@Indices),
      @TVarData(Result).VPointer) <> 0 then
  {$ENDIF}
     raise Exception.Create(reVarArrayBounds);
    TVarData(Result).VType := VarType;
  end;
end;


procedure VarStringToOleStr(var Dest: Variant; const Source: Variant);
var
  OleStrPtr: PWideChar;
begin
  OleStrPtr := StringToOleStr(string(TVarData(Source).VString));
  VarClear(Dest);
  TVarData(Dest).VType := varOleStr;
  TVarData(Dest).VOleStr := OleStrPtr;
end;                    



procedure _VarArrayPut(var A: Variant; const Value: Variant;
  IndexCount: Integer; Indices: Integer); cdecl;
var
  VarArrayPtr: PVarArray;
  VarType: Integer;
  P: Pointer;
  Temp: TVarData;
begin
  if TVarData(A).VType and varArray = 0 then
       raise Exception.Create(reVarNotArray);
  VarArrayPtr := GetVarArray(A);
  if VarArrayPtr^.DimCount <> IndexCount then
       raise Exception.Create(reVarArrayBounds);
  VarType := TVarData(A).VType and varTypeMask;
  if (VarType = varVariant) and (TVarData(Value).VType <> varString) then
  begin
    {$IFDEF WINDOWS}
    if SafeArrayPtrOfIndex(VarArrayPtr, @Indices, P) <> 0 then
    {$ELSE}
    if SafeArrayPtrOfIndex(VarArrayPtr, PVarArrayCoorArray(@Indices), P) <> 0 then
    {$ENDIF}

     raise Exception.Create(reVarArrayBounds);
    PVariant(P)^ := Value;
  end
  else
  begin
    Temp.VType := varEmpty;
    try
      if VarType = varVariant then
      begin
        VarStringToOleStr(Variant(Temp), Value);
        P := @Temp;
      end
      else
      begin
        VarCast(Variant(Temp), Value, VarType);
        case VarType of
          varOleStr, varDispatch, varUnknown:
            P := Temp.VPointer;
        else
          P := @Temp.VPointer;
        end;
      end;
      {$IFDEF WINDOWS}
      if SafeArrayPutElement(VarArrayPtr, @Indices, P) <> 0 then
      {$ELSE}
      if SafeArrayPutElement(VarArrayPtr, PVarArrayCoorArray(@Indices), P) <> 0 then
      {$ENDIF}
     raise Exception.Create(reVarArrayBounds);
    finally
      VarClear(Variant(Temp));
    end;
  end;
end;

function VarArrayGet(const A: Variant; const Indices: array of Integer): Variant;
asm
        {     ->EAX     Pointer to A            }
        {       EDX     Pointer to Indices      }
        {       ECX     High bound of Indices   }
        {       [EBP+8] Pointer to result       }

        PUSH    EBX

        MOV     EBX,ECX
        INC     EBX
        JLE     @@endLoop
@@loop:
        PUSH    [EDX+ECX*4].Integer
        DEC     ECX
        JNS     @@loop
@@endLoop:
        PUSH    EBX
        PUSH    EAX
        MOV     EAX,[EBP+8]
        PUSH    EAX
        CALL    _VarArrayGet
        LEA     ESP,[ESP+EBX*4+3*4]

        POP     EBX
end;

procedure VarArrayPut(var A: Variant; const Value: Variant; const Indices: array of Integer);
asm
        {     ->EAX     Pointer to A            }
        {       EDX     Pointer to Value        }
        {       ECX     Pointer to Indices      }
        {       [EBP+8] High bound of Indices   }

        PUSH    EBX

        MOV     EBX,[EBP+8]

        TEST    EBX,EBX
        JS      @@endLoop
@@loop:
        PUSH    [ECX+EBX*4].Integer
        DEC     EBX
        JNS     @@loop
@@endLoop:
        MOV     EBX,[EBP+8]
        INC     EBX
        PUSH    EBX
        PUSH    EDX
        PUSH    EAX
        CALL    _VarArrayPut
        LEA     ESP,[ESP+EBX*4+3*4]

        POP     EBX
end;



function VarTypeIsNumeric(const AVarType: Word): Boolean;
begin
  Result := AVarType in [varSmallInt, varInteger, varBoolean,
                         varByte, varSingle,varDouble,varCurrency];

end;

function VarIsNumeric(const V: Variant): Boolean;
begin
  Result := VarTypeIsNumeric(TVarData(V).VType);
end;

{$HINTS ON}

