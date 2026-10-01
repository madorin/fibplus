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
  FIBErrorMessages: array[TFIBClientError] of String = (
    'Unknown error.',
    'Unsupported feature.',
    'Not permitted.',
    'Temporary file access error.',
    'Database connection timed out.',
    'Cannot set database.',
    'Cannot set transaction.',
    'Operation cancelled at user''s request.',
    'DPB Constant (isc_dpb_%s) is unsupported.',
    'DPB Constant (%s) is unknown.',
    'TPB Constant (isc_tpb_%s) is unsupported.',
    'TPB Constant (%s) is unknown.',
    '%s: Cannot perform operation -- DB is not open.',
    'Cannot perform operation -- DB is currently open.',
    'Database name is missing.',
    '%s :Transaction is not active.',
    '%s :Transaction is active.',
    'Timeout values cannot be negative.',
    '%s :No databases are listed in transaction component.', // Changed
    '%s :Updating wrong database.',  // Changed
    '%s :Updating wrong transaction.',// Changed
    'Database not assigned for %s.',
    'Transaction not assigned for %s.',
    'XSQLDA index out of range.',
    'XSQLDA name does not exist (%s).',
    'End of file.',
    'Beginning of file.',
    '%s:Invalid statement handle.', // Changed
    'Can''t %s because %s dataset open.',
    'Can''t %s because %s dataset closed.',
    'Unknown SQL Data type (%d).',
    'Invalid column index (index exceeds permitted range).',
    'Invalid parameter index (index exceeds permitted range).',
    'Invalid data conversion.',
    'Column cannot be set to null (%s)',
    'Blob stream cannot be read.',
    'Blob stream cannot be written.',
    'Can''t %s , because  query is empty',
    'Can''t "open" a non-select statement. Use ExecQuery.',
    'No access to field "%s".',
    'Field "%s" is read-only.',
    'Field "%s" not found.',
    'DataSet not in Edit or Insert mode.(%s)',
    'Not editing.',
    'Can''t insert into dataset. (%s)',
    'Can''t post. (%s) ',
    'Can''t update. (%s)',
    'Can''t delete from dataset. (%s)',
    'Can''t refresh row. (%s)',
    'Buffer not set.',
    'Circular references not permitted.(%s)',
    'SQL Parse Error in '+':%s ' + CRLF + CRLF + '%s',
    'User abort.',
    'Data set is uni-directional.',
    'Cannot create shared resource. (Windows error %d)',
    'Windows API error. (Windows error %d [$%.8x])',
    'Column lists do not match.',
    'Column types don''t match. (From index: %d, To index: %d)',
    'Can''t end a shared transaction unless it is forced and equal to the transaction''s TimeoutAction.',
    'Column types "%s" is not array field',//feNotIsArrayField
    'Dimension %d don''t exist in "%s" ',//feWrongDimension
    'SQL Dialect invalid',//feSQLDialectInvalid
   {$IFDEF WINDOWS}
    'InterBase library gds32.dll not found in the path. Please install InterBase to use this functionality',//feIBMissing,
   {$ENDIF}
   {$IFDEF LINUX}
    'InterBase library libgds.so.0 not found in the path. Please install InterBase to use this functionality',//feIBMissing,
   {$ENDIF}
   {$IFDEF MACOS}
    'InterBase library  not found in the path. Please install InterBase to use this functionality',//feIBMissing,
   {$ENDIF}

    '%s is an InterBase6 function. Please upgrade to InterBase6 to use this functonality',
    // Added by Serg Vostrikov
    'InterBase Install DLL ibinstall.dll not found in the path. Please install InterBase 6 to use this functionality',
    'Cannot perform operation -- service is not attached',
    'Cannot perform operation -- service is attached',
    'Server Name Missing',
    'Query Parameters missing or incorrect',
    'Start Parameters missing or incorrect',
    'Unexpected Output buffer value',
    'Generic ServiceStart not applicable: Use Specific Procedures to set configuration params',
    'SPB Constant Not supported',
    'SPB Constant Unknown',
    'Field Size too small. Field %s.%s',

    '%s. Can''t use limited cache. '#13#10+
    'CachedUpdates must be False,'#13#10+
    'Select must have "Order by" clause ,'#13#10+
    'All order fields must exist in fields section'#13#10+
    'Select can''t use params with prefix "NEW_"'#13#10+
    'UpdateTransaction must be equel Transaction or AutoCommit=True '
    ,

    'Error in %s. FieldList is empty.',
    '%s can''t use field "%s"',
    '%s is an Firebird 2 function. Please upgrade to Firebird 2 to use this functonality'
    
  );
