library GUID_UDF;

{ DECLARE EXTERNAL FUNCTION CreateGUID
  integer,
  Char(16)
  RETURNS PARAMETER 2
  ENTRY_POINT 'CreateGUID' MODULE_NAME 'GUID_UDF';

  // the first parameter is a dummy.
  // call as "CreateGUID(1)"
  }

 function CoCreateGuid(out guid: TGUID): HResult; stdcall; external 'ole32.dll' name 'CoCreateGuid';

 procedure CreateGUID(var i: integer; p: pchar); cdecl; export;
 begin
   CoCreateGuid(PGUID(p)^);
 end;

exports
 CreateGUID;
begin
 isMultiThread:=True;
end.
