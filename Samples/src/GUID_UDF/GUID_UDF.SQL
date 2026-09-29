DECLARE EXTERNAL FUNCTION CreateGUID
  integer,
  Char(16)
  RETURNS PARAMETER 2
  ENTRY_POINT 'CreateGUID' MODULE_NAME 'GUID_UDF';

  // the first parameter is a dummy.
  // call as "CreateGUID(1)"