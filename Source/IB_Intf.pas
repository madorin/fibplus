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

unit IB_Intf;

interface

uses
{$I FIB.inc}
{$T-}
{$IFDEF WINDOWS} Windows, {$ENDIF}
  SyncObjs, Classes, Sysutils, ibase, IB_Externals,
  FIBPlatforms;

type
  TFIBProduct = (fpUnknown, fpInterBase, fpFirebird);

  // 3.0.13.33818 for a Firebird client "WI-V6.3.13.33818 Firebird 3.0"
  TFIBVersion = record
    Product: TFIBProduct;
    Major, Minor, Release, Build: Integer;
  end;

{$M-}

  IFIBClientLibrary = interface
    ['{8C184844-EB77-495F-81F5-AE3246958695}']
    function GetLibName: string;
    function GetIBClientVersion: Integer; deprecated;
    function GetIBClientMinorVersion: Integer; deprecated;
    function GetVersion: TFIBVersion;
    function GetBusy: Boolean;
    function isc_attach_database(status_vector: PISC_STATUS;
      db_name_length: Short; db_name: PAnsiChar; db_handle: PISC_DB_HANDLE;
      parm_buffer_length: Short; parm_buffer: PAnsiChar): ISC_STATUS;
    function isc_array_get_slice(status_vector: PISC_STATUS;
      db_handle: PISC_DB_HANDLE; trans_handle: PISC_TR_HANDLE;
      array_id: PISC_QUAD; descriptor: PISC_ARRAY_DESC; dest_array: PVoid;
      slice_length: PISC_LONG): ISC_STATUS;
    function isc_array_lookup_bounds(status_vector: PISC_STATUS;
      db_handle: PISC_DB_HANDLE; trans_handle: PISC_TR_HANDLE;
      table_name, column_name: PAnsiChar; descriptor: PISC_ARRAY_DESC)
      : ISC_STATUS;
    function isc_array_lookup_desc(status_vector: PISC_STATUS;
      db_handle: PISC_DB_HANDLE; trans_handle: PISC_TR_HANDLE;
      table_name, column_name: PAnsiChar; descriptor: PISC_ARRAY_DESC)
      : ISC_STATUS;
    function isc_array_set_desc(status_vector: PISC_STATUS;
      table_name: PAnsiChar; column_name: PAnsiChar;
      sql_dtype, sql_length, sql_dimensions: PShort;
      descriptor: PISC_ARRAY_DESC): ISC_STATUS;
    function isc_array_put_slice(status_vector: PISC_STATUS;
      db_handle: PISC_DB_HANDLE; trans_handle: PISC_TR_HANDLE;
      array_id: PISC_QUAD; descriptor: PISC_ARRAY_DESC; source_array: PVoid;
      slice_length: PISC_LONG): ISC_STATUS;
    function isc_get_slice(status_vector: PISC_STATUS;
      db_handle: PISC_DB_HANDLE; trans_handle: PISC_TR_HANDLE;
      array_id: PISC_QUAD; sdl_length: Short; sdl: PAnsiChar;
      param_length: Short; param: PISC_LONG; slice_length: ISC_LONG;
      slice: PVoid; return_length: PISC_LONG): ISC_STATUS;
    function isc_put_slice(status_vector: PISC_STATUS;
      db_handle: PISC_DB_HANDLE; trans_handle: PISC_TR_HANDLE;
      array_id: PISC_QUAD; sdl_length: Short; sdl: PAnsiChar;
      param_length: Short; param: PISC_LONG; slice_length: ISC_LONG;
      slice: PVoid): ISC_STATUS;
    function isc_blob_info(status_vector: PISC_STATUS;
      blob_handle: PISC_BLOB_HANDLE; item_list_buffer_length: Short;
      item_list_buffer: PAnsiChar; result_buffer_length: Short;
      result_buffer: PAnsiChar): ISC_STATUS;
    function isc_blob_lookup_desc(status_vector: PISC_STATUS;
      db_handle: PISC_DB_HANDLE; trans_handle: PISC_TR_HANDLE;
      table_name, column_name: PAnsiChar; descriptor: PISC_BLOB_DESC;
      global: PUChar): ISC_STATUS;
    function isc_blob_set_desc(status_vector: PISC_STATUS;
      table_name, column_name: PAnsiChar; subtype, charset, segment_size: Short;
      descriptor: PISC_BLOB_DESC): ISC_STATUS;
    function isc_cancel_blob(status_vector: PISC_STATUS; blob_handle: PISC_BLOB_HANDLE): ISC_STATUS;

    function isc_cancel_events(status_vector: PISC_STATUS; db_handle: PISC_DB_HANDLE; event_id: PISC_LONG): ISC_STATUS;
    function isc_que_events(status_vector: PISC_STATUS;
      db_handle: PISC_DB_HANDLE; event_id: PISC_LONG; length: Short;
      event_buffer: PAnsiChar; event_function: TISC_CALLBACK;
      event_function_arg: PVoid): ISC_STATUS;
    function isc_wait_for_event(status_vector: PISC_STATUS;
      db_handle: PISC_DB_HANDLE; length: Short;
      event_buffer, result_buffer: PAnsiChar): ISC_STATUS;

    function isc_close_blob(status_vector: PISC_STATUS; blob_handle: PISC_BLOB_HANDLE): ISC_STATUS;
    function isc_create_blob2(status_vector: PISC_STATUS;
      db_handle: PISC_DB_HANDLE; tran_handle: PISC_TR_HANDLE;
      blob_handle: PISC_BLOB_HANDLE; blob_id: PISC_QUAD; bpb_length: Short;
      bpb_address: PAnsiChar): ISC_STATUS;

    function isc_commit_retaining(status_vector: PISC_STATUS; tran_handle: PISC_TR_HANDLE): ISC_STATUS;
    function isc_commit_transaction(status_vector: PISC_STATUS; tran_handle: PISC_TR_HANDLE): ISC_STATUS;
    function isc_transaction_info(status_vector: PISC_STATUS;
      tran_handle: PISC_TR_HANDLE; item_list_buffer_length: Short;
      item_list_buffer: PAnsiChar; result_buffer_length: Short;
      result_buffer: PAnsiChar): ISC_STATUS;

    function isc_database_info(status_vector: PISC_STATUS;
      db_handle: PISC_DB_HANDLE; item_list_buffer_length: Short;
      item_list_buffer: PAnsiChar; result_buffer_length: Short;
      result_buffer: PAnsiChar): ISC_STATUS;
    procedure isc_decode_date(ib_date: PISC_QUAD; tm_date: PCTimeStructure);
    procedure isc_decode_sql_date(ib_date: PISC_DATE; tm_date: PCTimeStructure);
    procedure isc_decode_sql_time(ib_time: PISC_TIME; tm_date: PCTimeStructure);
    procedure isc_decode_timestamp(ib_timestamp: PISC_TIMESTAMP; tm_date: PCTimeStructure);
    function isc_detach_database(status_vector: PISC_STATUS; db_handle: PISC_DB_HANDLE): ISC_STATUS;
    function isc_drop_database(status_vector: PISC_STATUS; db_handle: PISC_DB_HANDLE): ISC_STATUS;
    function isc_dsql_alloc_statement2(const status_vector: PISC_STATUS;
      db_handle: PISC_DB_HANDLE; stmt_handle: PISC_STMT_HANDLE): ISC_STATUS;
    function isc_dsql_describe(status_vector: PISC_STATUS; stmt_handle: PISC_STMT_HANDLE; dialect: UShort; xsqlda: PXSQLDA): ISC_STATUS;
    function isc_dsql_describe_bind(status_vector: PISC_STATUS;
      stmt_handle: PISC_STMT_HANDLE; dialect: UShort; xsqlda: PXSQLDA)
      : ISC_STATUS;
    function isc_dsql_execute(status_vector: PISC_STATUS;
      tran_handle: PISC_TR_HANDLE; stmt_handle: PISC_STMT_HANDLE;
      dialect: UShort; xsqlda: PXSQLDA): ISC_STATUS;
    function isc_dsql_execute2(status_vector: PISC_STATUS;
      tran_handle: PISC_TR_HANDLE; stmt_handle: PISC_STMT_HANDLE;
      dialect: UShort; in_xsqlda, out_xsqlda: PXSQLDA): ISC_STATUS;
    function isc_dsql_execute_immediate(status_vector: PISC_STATUS;
      db_handle: PISC_DB_HANDLE; tran_handle: PISC_TR_HANDLE; length: UShort;
      statement: PAnsiChar; dialect: UShort; xsqlda: PXSQLDA): ISC_STATUS;

    function isc_dsql_exec_immed2(status_vector: PISC_STATUS;
      db_handle: PISC_DB_HANDLE; tran_handle: PISC_TR_HANDLE; length: UShort;
      statement: PAnsiChar; dialect: UShort; in_xsqlda, out_xsqlda: PXSQLDA)
      : ISC_STATUS;

    function isc_dsql_fetch(status_vector: PISC_STATUS; stmt_handle: PISC_STMT_HANDLE; dialect: UShort; xsqlda: PXSQLDA): ISC_STATUS;
    function isc_dsql_free_statement(status_vector: PISC_STATUS; stmt_handle: PISC_STMT_HANDLE; options: UShort): ISC_STATUS;
    function isc_dsql_prepare(status_vector: PISC_STATUS;
      tran_handle: PISC_TR_HANDLE; stmt_handle: PISC_STMT_HANDLE;
      length: UShort; statement: PAnsiChar; dialect: UShort; xsqlda: PXSQLDA)
      : ISC_STATUS;
    function isc_dsql_set_cursor_name(status_vector: PISC_STATUS;
      stmt_handle: PISC_STMT_HANDLE; cursor_name: PAnsiChar; _type: UShort)
      : ISC_STATUS;
    function isc_dsql_sql_info(status_vector: PISC_STATUS;
      stmt_handle: PISC_STMT_HANDLE; item_length: Short; items: PAnsiChar;
      buffer_length: Short; buffer: PAnsiChar): ISC_STATUS;
    procedure isc_encode_date(tm_date: PCTimeStructure; ib_date: PISC_QUAD);
    procedure isc_encode_sql_date(tm_date: PCTimeStructure; ib_date: PISC_DATE);
    procedure isc_encode_sql_time(tm_date: PCTimeStructure; ib_time: PISC_TIME);
    procedure isc_encode_timestamp(tm_date: PCTimeStructure; ib_timestamp: PISC_TIMESTAMP);
    function isc_event_block(event_buffer: PPAnsiChar;
      result_buffer: PPAnsiChar; id_count: UShort;
      event_list: array of PAnsiChar): ISC_LONG;
    procedure isc_event_counts(event_counts: PUISC_LONG; buffer_length: Short; event_buffer: PAnsiChar; result_buffer: PAnsiChar);
    function isc_free(isc_arg1: PAnsiChar): ISC_LONG;
    function isc_get_segment(status_vector: PISC_STATUS;
      blob_handle: PISC_BLOB_HANDLE; actual_seg_length: PUShort;
      seg_buffer_length: UShort; seg_buffer: PAnsiChar): ISC_STATUS;
    function isc_put_segment(status_vector: PISC_STATUS;
      blob_handle: PISC_BLOB_HANDLE; seg_buffer_len: UShort;
      seg_buffer: PAnsiChar): ISC_STATUS;

    function isc_interprete(buffer: PAnsiChar; status_vector: PPISC_STATUS): ISC_LONG;
    function fb_Interpret(buffer: PAnsiChar; BufLen: ULong; status_vector: PPISC_STATUS): ISC_LONG;

    function isc_open_blob2(status_vector: PISC_STATUS;
      db_handle: PISC_DB_HANDLE; tran_handle: PISC_TR_HANDLE;
      blob_handle: PISC_BLOB_HANDLE; blob_id: PISC_QUAD; bpb_length: Short;
      bpb_buffer: PAnsiChar): ISC_STATUS;
    function isc_prepare_transaction2(status_vector: PISC_STATUS;
      tran_handle: PISC_TR_HANDLE; msg_length: Short; msg: PAnsiChar)
      : ISC_STATUS;

    function isc_rollback_retaining(status_vector: PISC_STATUS; tran_handle: PISC_TR_HANDLE): ISC_STATUS;
    function isc_rollback_transaction(status_vector: PISC_STATUS; tran_handle: PISC_TR_HANDLE): ISC_STATUS;
    function isc_start_multiple(status_vector: PISC_STATUS;
      tran_handle: PISC_TR_HANDLE; db_handle_count: Short;
      teb_vector_address: PISC_TEB): ISC_STATUS;
    function isc_sqlcode(status_vector: PISC_STATUS): ISC_LONG;
    procedure isc_sql_interprete(sqlcode: Short; buffer: PAnsiChar; buffer_length: Short);
    function isc_vax_integer(buffer: PAnsiChar; length: Short): ISC_LONG;

    function isc_add_user(status_vector: PISC_STATUS; user_sec_data: PUserSecData): ISC_STATUS;
    function isc_delete_user(status_vector: PISC_STATUS; user_sec_data: PUserSecData): ISC_STATUS;
    function isc_modify_user(status_vector: PISC_STATUS; user_sec_data: PUserSecData): ISC_STATUS;

    function isc_prepare_transaction(status_vector: PISC_STATUS; tran_handle: PISC_TR_HANDLE): ISC_STATUS;

    function BLOB_put(isc_arg1: AnsiChar; isc_arg2: PBSTREAM): Int;
    function BLOB_get(isc_arg1: PBSTREAM): Int;

    // IB2007
    function isc_dsql_batch_execute_immed(status_vector: PISC_STATUS;
      db_handle: PISC_DB_HANDLE; tran_handle: PISC_TR_HANDLE; dialect: UShort;
      no_of_sql: ULong; statement: PPAnsiChar; rows_affected: PULong)
      : ISC_STATUS;
    function isc_dsql_batch_execute(status_vector: PISC_STATUS;
      tran_handle: PISC_TR_HANDLE; stmt_handle: PISC_STMT_HANDLE;
      dialect: UShort; insqlda: PXSQLDA; no_of_rows: UShort;
      batch_vars: PPXSQLVAR; rows_affected: PULong): ISC_STATUS;
    // FB2.5
    function fb_cancel_operation(status_vector: PISC_STATUS; db_handle: PISC_DB_HANDLE; option: UShort): ISC_STATUS;
    function fb_dsql_set_timeout(status_vector: PISC_STATUS; stmt_handle: PISC_STMT_HANDLE; timeout: Cardinal): ISC_STATUS;
    function HasStatementTimeout: Boolean;

    function fb_sqlstate(user_status: PISC_STATUS): FIBByteString;
    function fb_database_crypt_callback(StatusVector: PISC_STATUS; Callback: Pointer): ISC_STATUS;
    // Service manager functions
    function isc_service_attach(status_vector: PISC_STATUS; isc_arg2: UShort;
      isc_arg3: PAnsiChar; service_handle: PISC_SVC_HANDLE; isc_arg5: UShort;
      isc_arg6: PAnsiChar): ISC_STATUS;
    function isc_service_detach(status_vector: PISC_STATUS; service_handle: PISC_SVC_HANDLE): ISC_STATUS;
    function isc_service_query(status_vector: PISC_STATUS;
      service_handle: PISC_SVC_HANDLE; recv_handle: PISC_SVC_HANDLE;
      isc_arg4: UShort; isc_arg5: PAnsiChar; isc_arg6: UShort;
      isc_arg7: PAnsiChar; isc_arg8: UShort; isc_arg9: PAnsiChar): ISC_STATUS;
    function isc_service_start(status_vector: PISC_STATUS;
      service_handle: PISC_SVC_HANDLE; recv_handle: PISC_SVC_HANDLE;
      isc_arg4: UShort; isc_arg5: PAnsiChar): ISC_STATUS;
    // Client information functions
    procedure isc_get_client_version(buffer: PAnsiChar);
    function isc_get_client_major_version: Integer;
    function isc_get_client_minor_version: Integer;

    function isc_portable_integer(buffer: PAnsiChar; length: Short): ISC_INT64;

    procedure FreeIBLibrary;
    procedure LoadIBLibrary;
    function LibraryLoaded: Boolean;
    function LibraryFilePath: string;
    // 6.3 on every Firebird client, use Version; functions: properties can't be deprecated
    function ClientMinorVersion: Integer; deprecated;
    function ClientVersion: Integer; deprecated;
    property LibraryName: string read GetLibName;
    property Version: TFIBVersion read GetVersion;
    property Busy: Boolean read GetBusy;
  end;
{$M+}

  EFIBAPICallException = Exception;

  TFIBClientLibrary = class(TInterfacedObject, IFIBClientLibrary)
  private
    FLibraryHandle: THandle;
    FLibraryName: string;
    FIBClientVersion: Integer;
    FIBClientMinorVersion: Integer;
  private
    FBLOB_get: TBLOB_get;
    FBLOB_put: TBLOB_put;
    Fisc_sqlcode: Tisc_sqlcode;
    Ffb_sqlstate: Tfb_sqlstate;
    Fisc_sql_interprete: Tisc_sql_interprete;
    Fisc_interprete: Tisc_interprete;
    Ffb_interpret: Tfb_interpret;
    Fisc_vax_integer: Tisc_vax_integer;
    Fisc_blob_info: Tisc_blob_info;
    Fisc_open_blob2: Tisc_open_blob2;
    Fisc_close_blob: Tisc_close_blob;
    Fisc_get_segment: Tisc_get_segment;
    Fisc_put_segment: Tisc_put_segment;
    Fisc_create_blob2: Tisc_create_blob2;
    Fisc_blob_lookup_desc: Tisc_blob_lookup_desc;
    Fisc_blob_set_desc: Tisc_blob_set_desc;
    Fisc_cancel_blob: Tisc_cancel_blob;

    Fisc_service_attach: Tisc_service_attach;
    Fisc_service_detach: Tisc_service_detach;
    Fisc_service_query: Tisc_service_query;
    Fisc_service_start: Tisc_service_start;
    Fisc_decode_date: Tisc_decode_date;
    Fisc_decode_sql_date: Tisc_decode_sql_date;
    Fisc_decode_sql_time: Tisc_decode_sql_time;
    Fisc_decode_timestamp: Tisc_decode_timestamp;
    Fisc_encode_date: Tisc_encode_date;
    Fisc_encode_sql_date: Tisc_encode_sql_date;
    Fisc_encode_sql_time: Tisc_encode_sql_time;
    Fisc_encode_timestamp: Tisc_encode_timestamp;
    Fisc_dsql_free_statement: Tisc_dsql_free_statement;
    Fisc_dsql_execute2: Tisc_dsql_execute2;
    Fisc_dsql_execute: Tisc_dsql_execute;
    Fisc_dsql_set_cursor_name: Tisc_dsql_set_cursor_name;
    Fisc_dsql_fetch: Tisc_dsql_fetch;
    Fisc_dsql_sql_info: Tisc_dsql_sql_info;
    Fisc_dsql_alloc_statement2: Tisc_dsql_alloc_statement2;
    Fisc_dsql_prepare: Tisc_dsql_prepare;
    Fisc_dsql_describe_bind: Tisc_dsql_describe_bind;
    Fisc_dsql_describe: Tisc_dsql_describe;
    Fisc_dsql_execute_immediate: Tisc_dsql_execute_immediate;
    Fisc_dsql_exec_immed2: Tisc_dsql_exec_immed2;
    Fisc_drop_database: Tisc_drop_database;
    Fisc_detach_database: Tisc_detach_database;
    Fisc_attach_database: Tisc_attach_database;
    Fisc_database_info: Tisc_database_info;
    Fisc_start_multiple: Tisc_start_multiple;
    Fisc_commit_transaction: Tisc_commit_transaction;
    Fisc_commit_retaining: Tisc_commit_retaining;
    Fisc_rollback_transaction: Tisc_rollback_transaction;
    Fisc_rollback_retaining: Tisc_rollback_retaining;
    Fisc_cancel_events: Tisc_cancel_events;
    Fisc_que_events: Tisc_que_events;
    Fisc_event_counts: Tisc_event_counts;
    Fisc_event_block: Tisc_event_block;
    Fisc_free: Tisc_free;
    Fisc_wait_for_event: Tisc_wait_for_event;
    Fisc_transaction_info: Tisc_transaction_info;
    Fisc_prepare_transaction: Tisc_prepare_transaction;
    Fisc_prepare_transaction2: Tisc_prepare_transaction2;
    // Array functions
    Fisc_array_lookup_bounds: Tisc_array_lookup_bounds;
    Fisc_array_get_slice: Tisc_array_get_slice;
    Fisc_array_put_slice: Tisc_array_put_slice;
    Fisc_get_slice: Tisc_get_slice;
    Fisc_put_slice: Tisc_put_slice;
    Fisc_array_set_desc: Tisc_array_set_desc;
    Fisc_array_lookup_desc: Tisc_array_lookup_desc;

    Fisc_portable_integer: Tisc_portable_integer;

    Fisc_add_user: Tisc_add_user;
    Fisc_delete_user: Tisc_delete_user;
    Fisc_modify_user: Tisc_modify_user;
    { IB 7.0 functions only }
    Fisc_get_client_version: Tisc_get_client_version;
    Fisc_get_client_major_version: Tisc_get_client_major_version;
    Fisc_get_client_minor_version: Tisc_get_client_minor_version;
    // IB2007
    Fisc_dsql_batch_execute_immed: Tisc_dsql_batch_execute_immed;
    Fisc_dsql_batch_execute: Tisc_dsql_batch_execute;
    // FB2.5
    Ffb_cancel_operation: Tfb_cancel_operation;
    Ffb_dsql_set_timeout: Tfb_dsql_set_timeout;
    Ffb_shutdown: Tfb_shutdown;
    Ffb_database_crypt_callback: Tfb_database_crypt_callback;
    FVersion: TFIBVersion;
  private
    // calls in progress, of all threads
    FBusyCount: Integer;

    procedure BeginCall;
    procedure EndCall;
    function GetLibName: string;
    // the next four are deprecated in IFIBClientLibrary
    function GetIBClientVersion: Integer;
    function GetIBClientMinorVersion: Integer;
    function ClientMinorVersion: Integer;
    function ClientVersion: Integer;
    function GetVersion: TFIBVersion;
    function GetBusy: Boolean;
    function isc_attach_database(status_vector: PISC_STATUS;
      db_name_length: Short; db_name: PAnsiChar; db_handle: PISC_DB_HANDLE;
      parm_buffer_length: Short; parm_buffer: PAnsiChar): ISC_STATUS;
    function isc_array_get_slice(status_vector: PISC_STATUS;
      db_handle: PISC_DB_HANDLE; trans_handle: PISC_TR_HANDLE;
      array_id: PISC_QUAD; descriptor: PISC_ARRAY_DESC; dest_array: PVoid;
      slice_length: PISC_LONG): ISC_STATUS;
    function isc_array_lookup_bounds(status_vector: PISC_STATUS;
      db_handle: PISC_DB_HANDLE; trans_handle: PISC_TR_HANDLE;
      table_name, column_name: PAnsiChar; descriptor: PISC_ARRAY_DESC)
      : ISC_STATUS;
    function isc_array_lookup_desc(status_vector: PISC_STATUS;
      db_handle: PISC_DB_HANDLE; trans_handle: PISC_TR_HANDLE;
      table_name, column_name: PAnsiChar; descriptor: PISC_ARRAY_DESC)
      : ISC_STATUS;
    function isc_array_set_desc(status_vector: PISC_STATUS;
      table_name: PAnsiChar; column_name: PAnsiChar;
      sql_dtype, sql_length, sql_dimensions: PShort;
      descriptor: PISC_ARRAY_DESC): ISC_STATUS;
    function isc_array_put_slice(status_vector: PISC_STATUS;
      db_handle: PISC_DB_HANDLE; trans_handle: PISC_TR_HANDLE;
      array_id: PISC_QUAD; descriptor: PISC_ARRAY_DESC; source_array: PVoid;
      slice_length: PISC_LONG): ISC_STATUS;
    function isc_get_slice(status_vector: PISC_STATUS;
      db_handle: PISC_DB_HANDLE; trans_handle: PISC_TR_HANDLE;
      array_id: PISC_QUAD; sdl_length: Short; sdl: PAnsiChar;
      param_length: Short; param: PISC_LONG; slice_length: ISC_LONG;
      slice: PVoid; return_length: PISC_LONG): ISC_STATUS;
    function isc_put_slice(status_vector: PISC_STATUS;
      db_handle: PISC_DB_HANDLE; trans_handle: PISC_TR_HANDLE;
      array_id: PISC_QUAD; sdl_length: Short; sdl: PAnsiChar;
      param_length: Short; param: PISC_LONG; slice_length: ISC_LONG;
      slice: PVoid): ISC_STATUS;
    function isc_blob_info(status_vector: PISC_STATUS;
      blob_handle: PISC_BLOB_HANDLE; item_list_buffer_length: Short;
      item_list_buffer: PAnsiChar; result_buffer_length: Short;
      result_buffer: PAnsiChar): ISC_STATUS;
    function isc_blob_lookup_desc(status_vector: PISC_STATUS;
      db_handle: PISC_DB_HANDLE; trans_handle: PISC_TR_HANDLE;
      table_name, column_name: PAnsiChar; descriptor: PISC_BLOB_DESC;
      global: PUChar): ISC_STATUS;
    function isc_blob_set_desc(status_vector: PISC_STATUS;
      table_name, column_name: PAnsiChar; subtype, charset, segment_size: Short;
      descriptor: PISC_BLOB_DESC): ISC_STATUS;
    function isc_cancel_blob(status_vector: PISC_STATUS; blob_handle: PISC_BLOB_HANDLE): ISC_STATUS;
    function isc_cancel_events(status_vector: PISC_STATUS; db_handle: PISC_DB_HANDLE; event_id: PISC_LONG): ISC_STATUS;
    function isc_que_events(status_vector: PISC_STATUS;
      db_handle: PISC_DB_HANDLE; event_id: PISC_LONG; length: Short;
      event_buffer: PAnsiChar; event_function: TISC_CALLBACK;
      event_function_arg: PVoid): ISC_STATUS;

    function isc_wait_for_event(status_vector: PISC_STATUS;
      db_handle: PISC_DB_HANDLE; length: Short;
      event_buffer, result_buffer: PAnsiChar): ISC_STATUS;

    function isc_close_blob(status_vector: PISC_STATUS; blob_handle: PISC_BLOB_HANDLE): ISC_STATUS;
    function isc_commit_retaining(status_vector: PISC_STATUS; tran_handle: PISC_TR_HANDLE): ISC_STATUS;
    function isc_commit_transaction(status_vector: PISC_STATUS; tran_handle: PISC_TR_HANDLE): ISC_STATUS;

    function isc_transaction_info(status_vector: PISC_STATUS;
      tran_handle: PISC_TR_HANDLE; item_list_buffer_length: Short;
      item_list_buffer: PAnsiChar; result_buffer_length: Short;
      result_buffer: PAnsiChar): ISC_STATUS;

    function isc_create_blob2(status_vector: PISC_STATUS;
      db_handle: PISC_DB_HANDLE; tran_handle: PISC_TR_HANDLE;
      blob_handle: PISC_BLOB_HANDLE; blob_id: PISC_QUAD; bpb_length: Short;
      bpb_address: PAnsiChar): ISC_STATUS;
    function isc_database_info(status_vector: PISC_STATUS;
      db_handle: PISC_DB_HANDLE; item_list_buffer_length: Short;
      item_list_buffer: PAnsiChar; result_buffer_length: Short;
      result_buffer: PAnsiChar): ISC_STATUS;
    procedure isc_decode_date(ib_date: PISC_QUAD; tm_date: PCTimeStructure);
    procedure isc_decode_sql_date(ib_date: PISC_DATE; tm_date: PCTimeStructure);
    procedure isc_decode_sql_time(ib_time: PISC_TIME; tm_date: PCTimeStructure);
    procedure isc_decode_timestamp(ib_timestamp: PISC_TIMESTAMP; tm_date: PCTimeStructure);
    function isc_detach_database(status_vector: PISC_STATUS; db_handle: PISC_DB_HANDLE): ISC_STATUS;
    function isc_drop_database(status_vector: PISC_STATUS; db_handle: PISC_DB_HANDLE): ISC_STATUS;
    function isc_dsql_alloc_statement2(const status_vector: PISC_STATUS;
      db_handle: PISC_DB_HANDLE; stmt_handle: PISC_STMT_HANDLE): ISC_STATUS;
    function isc_dsql_describe(status_vector: PISC_STATUS; stmt_handle: PISC_STMT_HANDLE; dialect: UShort; xsqlda: PXSQLDA): ISC_STATUS;
    function isc_dsql_describe_bind(status_vector: PISC_STATUS;
      stmt_handle: PISC_STMT_HANDLE; dialect: UShort; xsqlda: PXSQLDA)
      : ISC_STATUS;
    function isc_dsql_execute(status_vector: PISC_STATUS;
      tran_handle: PISC_TR_HANDLE; stmt_handle: PISC_STMT_HANDLE;
      dialect: UShort; xsqlda: PXSQLDA): ISC_STATUS;
    function isc_dsql_execute2(status_vector: PISC_STATUS;
      tran_handle: PISC_TR_HANDLE; stmt_handle: PISC_STMT_HANDLE;
      dialect: UShort; in_xsqlda, out_xsqlda: PXSQLDA): ISC_STATUS;
    function isc_dsql_execute_immediate(status_vector: PISC_STATUS;
      db_handle: PISC_DB_HANDLE; tran_handle: PISC_TR_HANDLE; length: UShort;
      statement: PAnsiChar; dialect: UShort; xsqlda: PXSQLDA): ISC_STATUS;

    function isc_dsql_exec_immed2(status_vector: PISC_STATUS;
      db_handle: PISC_DB_HANDLE; tran_handle: PISC_TR_HANDLE; length: UShort;
      statement: PAnsiChar; dialect: UShort; in_xsqlda, out_xsqlda: PXSQLDA)
      : ISC_STATUS;

    function isc_dsql_fetch(status_vector: PISC_STATUS; stmt_handle: PISC_STMT_HANDLE; dialect: UShort; xsqlda: PXSQLDA): ISC_STATUS;
    function isc_dsql_free_statement(status_vector: PISC_STATUS; stmt_handle: PISC_STMT_HANDLE; options: UShort): ISC_STATUS;
    function isc_dsql_prepare(status_vector: PISC_STATUS;
      tran_handle: PISC_TR_HANDLE; stmt_handle: PISC_STMT_HANDLE;
      length: UShort; statement: PAnsiChar; dialect: UShort; xsqlda: PXSQLDA)
      : ISC_STATUS;
    function isc_dsql_set_cursor_name(status_vector: PISC_STATUS;
      stmt_handle: PISC_STMT_HANDLE; cursor_name: PAnsiChar; _type: UShort)
      : ISC_STATUS;
    function isc_dsql_sql_info(status_vector: PISC_STATUS;
      stmt_handle: PISC_STMT_HANDLE; item_length: Short; items: PAnsiChar;
      buffer_length: Short; buffer: PAnsiChar): ISC_STATUS;
    procedure isc_encode_date(tm_date: PCTimeStructure; ib_date: PISC_QUAD);
    procedure isc_encode_sql_date(tm_date: PCTimeStructure; ib_date: PISC_DATE);
    procedure isc_encode_sql_time(tm_date: PCTimeStructure; ib_time: PISC_TIME);
    procedure isc_encode_timestamp(tm_date: PCTimeStructure; ib_timestamp: PISC_TIMESTAMP);
    function isc_event_block(event_buffer: PPAnsiChar;
      result_buffer: PPAnsiChar; id_count: UShort;
      event_list: array of PAnsiChar): ISC_LONG;
    procedure isc_event_counts(event_counts: PUISC_LONG; buffer_length: Short; event_buffer: PAnsiChar; result_buffer: PAnsiChar);
    function isc_free(isc_arg1: PAnsiChar): ISC_LONG;
    function isc_get_segment(status_vector: PISC_STATUS;
      blob_handle: PISC_BLOB_HANDLE; actual_seg_length: PUShort;
      seg_buffer_length: UShort; seg_buffer: PAnsiChar): ISC_STATUS;
    function isc_put_segment(status_vector: PISC_STATUS;
      blob_handle: PISC_BLOB_HANDLE; seg_buffer_len: UShort;
      seg_buffer: PAnsiChar): ISC_STATUS;

    function isc_interprete(buffer: PAnsiChar; status_vector: PPISC_STATUS): ISC_LONG;
    function fb_Interpret(buffer: PAnsiChar; BufLen: ULong; status_vector: PPISC_STATUS): ISC_LONG; // FB

    function isc_open_blob2(status_vector: PISC_STATUS;
      db_handle: PISC_DB_HANDLE; tran_handle: PISC_TR_HANDLE;
      blob_handle: PISC_BLOB_HANDLE; blob_id: PISC_QUAD; bpb_length: Short;
      bpb_buffer: PAnsiChar): ISC_STATUS;
    function isc_prepare_transaction2(status_vector: PISC_STATUS;
      tran_handle: PISC_TR_HANDLE; msg_length: Short; msg: PAnsiChar)
      : ISC_STATUS;
    function isc_rollback_retaining(status_vector: PISC_STATUS; tran_handle: PISC_TR_HANDLE): ISC_STATUS;
    function isc_rollback_transaction(status_vector: PISC_STATUS; tran_handle: PISC_TR_HANDLE): ISC_STATUS;
    function isc_start_multiple(status_vector: PISC_STATUS;
      tran_handle: PISC_TR_HANDLE; db_handle_count: Short;
      teb_vector_address: PISC_TEB): ISC_STATUS;
    function isc_sqlcode(status_vector: PISC_STATUS): ISC_LONG;
    procedure isc_sql_interprete(sqlcode: Short; buffer: PAnsiChar; buffer_length: Short);
    function isc_vax_integer(buffer: PAnsiChar; length: Short): ISC_LONG;

    function isc_add_user(status_vector: PISC_STATUS; user_sec_data: PUserSecData): ISC_STATUS;
    function isc_delete_user(status_vector: PISC_STATUS; user_sec_data: PUserSecData): ISC_STATUS;
    function isc_modify_user(status_vector: PISC_STATUS; user_sec_data: PUserSecData): ISC_STATUS;

    function isc_prepare_transaction(status_vector: PISC_STATUS; tran_handle: PISC_TR_HANDLE): ISC_STATUS;

    function BLOB_put(isc_arg1: AnsiChar; isc_arg2: PBSTREAM): Int;
    function BLOB_get(isc_arg1: PBSTREAM): Int;

    // Service manager functions
    function isc_service_attach(status_vector: PISC_STATUS; isc_arg2: UShort;
      isc_arg3: PAnsiChar; service_handle: PISC_SVC_HANDLE; isc_arg5: UShort;
      isc_arg6: PAnsiChar): ISC_STATUS;
    function isc_service_detach(status_vector: PISC_STATUS; service_handle: PISC_SVC_HANDLE): ISC_STATUS;
    function isc_service_query(status_vector: PISC_STATUS;
      service_handle: PISC_SVC_HANDLE; recv_handle: PISC_SVC_HANDLE;
      isc_arg4: UShort; isc_arg5: PAnsiChar; isc_arg6: UShort;
      isc_arg7: PAnsiChar; isc_arg8: UShort; isc_arg9: PAnsiChar): ISC_STATUS;
    function isc_service_start(status_vector: PISC_STATUS;
      service_handle: PISC_SVC_HANDLE; recv_handle: PISC_SVC_HANDLE;
      isc_arg4: UShort; isc_arg5: PAnsiChar): ISC_STATUS;
    // Client information functions
    procedure isc_get_client_version(buffer: PAnsiChar);
    function isc_get_client_major_version: Integer;
    function isc_get_client_minor_version: Integer;
    function isc_portable_integer(buffer: PAnsiChar; length: Short): ISC_INT64;

    // IB2007
    function isc_dsql_batch_execute_immed(status_vector: PISC_STATUS;
      db_handle: PISC_DB_HANDLE; tran_handle: PISC_TR_HANDLE; dialect: UShort;
      no_of_sql: ULong; statement: PPAnsiChar; rows_affected: PULong)
      : ISC_STATUS;
    function isc_dsql_batch_execute(status_vector: PISC_STATUS;
      tran_handle: PISC_TR_HANDLE; stmt_handle: PISC_STMT_HANDLE;
      dialect: UShort; insqlda: PXSQLDA; no_of_rows: UShort;
      batch_vars: PPXSQLVAR; rows_affected: PULong): ISC_STATUS;

    // FB2.5
    function fb_cancel_operation(status_vector: PISC_STATUS; db_handle: PISC_DB_HANDLE; option: UShort): ISC_STATUS;
    function fb_dsql_set_timeout(status_vector: PISC_STATUS; stmt_handle: PISC_STMT_HANDLE; timeout: Cardinal): ISC_STATUS;
    function HasStatementTimeout: Boolean;

    function fb_sqlstate(user_status: PISC_STATUS): FIBByteString;
    function fb_database_crypt_callback(StatusVector: PISC_STATUS; Callback: Pointer): ISC_STATUS;

  public
    constructor Create(const aLibName: string);
    destructor Destroy; override;
    procedure LoadIBLibrary;
    procedure FreeIBLibrary;
    function LibraryLoaded: Boolean;
    function LibraryFilePath: string;
  end;

  // Data and Key are in the format of the server KeyHolder plugin
  TFIBCryptKeyRequestEvent = procedure(Sender: TObject; const Data: FIBByteString; var Key: FIBByteString) of object;

  // Firebird ICryptKeyCallback in the cloop layout: an unused slot (VMT), then the VTable
  TFIBCryptKeyCallback = class
  private
    FVTable: Pointer; // must stay the first field
    FSender: TObject;
    FOnRequest: TFIBCryptKeyRequestEvent;
    FRequestError: TObject;
    function Callback(DataLength: Cardinal; Data: Pointer; BufferLength: Cardinal; buffer: Pointer): Cardinal;
  public
    constructor Create(Sender: TObject; OnRequest: TFIBCryptKeyRequestEvent);
    destructor Destroy; override;
    function Activate(const ClientLibrary: IFIBClientLibrary; StatusVector: PISC_STATUS): ISC_STATUS;
    procedure Deactivate(const ClientLibrary: IFIBClientLibrary);
    procedure RaiseRequestError;
  end;

function GetClientLibrary(const aLibName: string): IFIBClientLibrary;

{$IFNDEF C22}
// System.Reset8087CW of Delphi XE and later
procedure Reset8087CW;
{$ENDIF}

const
  IBDateDelta = 15018;
{$IFDEF MACOS}
  HINSTANCE_ERROR = 0;
{$ENDIF}

const
  describe_bind_info: array [0 .. 11] of AnsiChar = (
    AnsiChar(isc_info_sql_bind),
    AnsiChar(isc_info_sql_describe_vars),
    AnsiChar(isc_info_sql_sqlda_seq),
    AnsiChar(isc_info_sql_type),
    AnsiChar(isc_info_sql_sub_type),
    AnsiChar(isc_info_sql_scale),
    AnsiChar(isc_info_sql_length),
    AnsiChar(isc_info_sql_field),
    AnsiChar(isc_info_sql_relation),
    AnsiChar(isc_info_sql_owner),
    AnsiChar(isc_info_sql_alias),
    AnsiChar(isc_info_sql_describe_end)
  );

  describe_select_info: array [0 .. 12] of AnsiChar = (
    AnsiChar(isc_info_sql_select),
    AnsiChar(isc_info_sql_describe_vars),
    AnsiChar(isc_info_sql_sqlda_seq),
    AnsiChar(isc_info_sql_type),
    AnsiChar(isc_info_sql_sub_type),
    AnsiChar(isc_info_sql_scale),
    AnsiChar(isc_info_sql_length),
    AnsiChar(isc_info_sql_field),
    AnsiChar(isc_info_sql_relation),
    AnsiChar(isc_info_sql_owner),
    AnsiChar(isc_info_sql_alias),
    AnsiChar(frb_info_sql_relation_alias),
    AnsiChar(isc_info_sql_describe_end)
  );

type
  // Deprecated names of the types renamed in 8.0.0
{$IFDEF WINDOWS}
  IIBClientLibrary = IFIBClientLibrary deprecated 'Use IFIBClientLibrary';
  TIBClientLibrary = TFIBClientLibrary deprecated 'Use TFIBClientLibrary';
  EAPICallException = EFIBAPICallException deprecated 'Use EFIBAPICallException';
{$ENDIF}

implementation

uses
  FIBConsts;

var
  ClientLibraries: TInterfaceList;

var
  ClientLibrariesLock: TCriticalSection;

function GetClientLibrary(const aLibName: string): IFIBClientLibrary;
var
  I: Integer;
begin
  ClientLibrariesLock.Acquire;
  try
    for I := 0 to ClientLibraries.Count - 1 do
{$IFDEF WINDOWS}
      // Windows file names ignore the case
      if SameText(IFIBClientLibrary(ClientLibraries[I]).LibraryName, aLibName) then
{$ELSE}
      if IFIBClientLibrary(ClientLibraries[I]).LibraryName = aLibName then
{$ENDIF}
      begin
        Result := IFIBClientLibrary(ClientLibraries[I]);
        if not Result.LibraryLoaded then
          Result.LoadIBLibrary;
        Exit;
      end;
    Result := TFIBClientLibrary.Create(aLibName);
    ClientLibraries.Add(Result)
  finally
    ClientLibrariesLock.Release
  end;
end;

{$IFNDEF C22}
procedure Reset8087CW;
begin
  Set8087CW(Default8087CW);
end;
{$ENDIF}

{ TFIBClientLibrary }

function TFIBClientLibrary.BLOB_get(isc_arg1: PBSTREAM): Int;
begin
  if Assigned(FBLOB_get) then
    Result := FBLOB_get(isc_arg1)
  else
    raise EFIBAPICallException.Create(Format(SCantFindApiProc, ['BLOB_get', FLibraryName]));
end;

function TFIBClientLibrary.BLOB_put(isc_arg1: AnsiChar; isc_arg2: PBSTREAM): Int;
begin
  if Assigned(FBLOB_put) then
    Result := FBLOB_put(isc_arg1, isc_arg2)
  else
    raise EFIBAPICallException.Create(Format(SCantFindApiProc, ['BLOB_put', FLibraryName]));
end;

function TFIBClientLibrary.GetIBClientVersion: Integer;
begin
  Result := FIBClientVersion
end;

function TFIBClientLibrary.GetIBClientMinorVersion: Integer;
begin
  Result := FIBClientMinorVersion
end;

function TFIBClientLibrary.ClientMinorVersion: Integer;
begin
  Result := FIBClientMinorVersion
end;

function TFIBClientLibrary.ClientVersion: Integer;
begin
  Result := FIBClientVersion
end;

function TFIBClientLibrary.GetVersion: TFIBVersion;
begin
  Result := FVersion;
end;

// The WI-V numbers are InterBase compatible (6.3 on Firebird), Firebird appends its version
function ParseClientVersion(const S: string): TFIBVersion;
var
  Api: array [0 .. 3] of Integer;
  Product: array [0 .. 1] of Integer;
  p: Integer;

  procedure ReadNumbers(I: Integer; var Numbers: array of Integer);
  var
    n: Integer;
  begin
    n := 0;
    while (I <= length(S)) and (n <= High(Numbers)) do
    begin
      if S[I] = '.' then
        Inc(n)
      else if CharInSet(S[I], ['0' .. '9']) then
        Numbers[n] := Numbers[n] * 10 + Ord(S[I]) - Ord('0')
      else
        Break;
      Inc(I);
    end;
  end;

begin
  FillChar(Result, SizeOf(Result), 0);
  FillChar(Api, SizeOf(Api), 0);
  FillChar(Product, SizeOf(Product), 0);
  p := Pos('-', S);
  if p = 0 then
    Exit;
  ReadNumbers(p + 2, Api);
  p := Pos('Firebird ', S);
  if p > 0 then
  begin
    ReadNumbers(p + length('Firebird '), Product);
    Result.Product := fpFirebird;
    Result.Major := Product[0];
    Result.Minor := Product[1];
  end
  else
  begin
    Result.Product := fpInterBase;
    Result.Major := Api[0];
    Result.Minor := Api[1];
  end;
  Result.Release := Api[2];
  Result.Build := Api[3];
end;

function TFIBClientLibrary.GetLibName: string;
begin
  Result := FLibraryName
end;

function TFIBClientLibrary.isc_array_get_slice(status_vector: PISC_STATUS;
  db_handle: PISC_DB_HANDLE; trans_handle: PISC_TR_HANDLE; array_id: PISC_QUAD;
  descriptor: PISC_ARRAY_DESC; dest_array: PVoid; slice_length: PISC_LONG)
  : ISC_STATUS;
begin
  if Assigned(Fisc_array_get_slice) then
    Result := Fisc_array_get_slice(status_vector, db_handle, trans_handle,
      array_id, descriptor, dest_array, slice_length)
  else
    raise EFIBAPICallException.Create(Format(SCantFindApiProc, ['isc_array_get_slice', FLibraryName]));
end;

function TFIBClientLibrary.isc_array_lookup_bounds(status_vector: PISC_STATUS;
  db_handle: PISC_DB_HANDLE; trans_handle: PISC_TR_HANDLE;
  table_name, column_name: PAnsiChar; descriptor: PISC_ARRAY_DESC): ISC_STATUS;
begin
  if Assigned(Fisc_array_lookup_bounds) then
    Result := Fisc_array_lookup_bounds(status_vector, db_handle, trans_handle, table_name, column_name, descriptor)
  else
    raise EFIBAPICallException.Create(Format(SCantFindApiProc, ['isc_array_lookup_bounds', FLibraryName]));
end;

function TFIBClientLibrary.isc_array_lookup_desc(status_vector: PISC_STATUS;
  db_handle: PISC_DB_HANDLE; trans_handle: PISC_TR_HANDLE;
  table_name, column_name: PAnsiChar; descriptor: PISC_ARRAY_DESC): ISC_STATUS;
begin
  if Assigned(Fisc_array_lookup_desc) then
    Result := Fisc_array_lookup_desc(status_vector, db_handle, trans_handle, table_name, column_name, descriptor)
  else
    raise EFIBAPICallException.Create(Format(SCantFindApiProc, ['isc_array_lookup_desc', FLibraryName]));
end;

function TFIBClientLibrary.isc_array_put_slice(status_vector: PISC_STATUS;
  db_handle: PISC_DB_HANDLE; trans_handle: PISC_TR_HANDLE; array_id: PISC_QUAD;
  descriptor: PISC_ARRAY_DESC; source_array: PVoid; slice_length: PISC_LONG)
  : ISC_STATUS;
begin
  if Assigned(Fisc_array_put_slice) then
    Result := Fisc_array_put_slice(status_vector, db_handle, trans_handle,
      array_id, descriptor, source_array, slice_length)
  else
    raise EFIBAPICallException.Create(Format(SCantFindApiProc, ['isc_array_put_slice', FLibraryName]));
end;

function TFIBClientLibrary.isc_get_slice(status_vector: PISC_STATUS;
  db_handle: PISC_DB_HANDLE; trans_handle: PISC_TR_HANDLE; array_id: PISC_QUAD;
  sdl_length: Short; sdl: PAnsiChar; param_length: Short; param: PISC_LONG;
  slice_length: ISC_LONG; slice: PVoid; return_length: PISC_LONG): ISC_STATUS;
begin
  if Assigned(Fisc_get_slice) then
    Result := Fisc_get_slice(status_vector, db_handle, trans_handle, array_id,
      sdl_length, sdl, param_length, param, slice_length, slice, return_length)
  else
    raise EFIBAPICallException.Create(Format(SCantFindApiProc, ['isc_get_slice', FLibraryName]));
end;

function TFIBClientLibrary.isc_put_slice(status_vector: PISC_STATUS;
  db_handle: PISC_DB_HANDLE; trans_handle: PISC_TR_HANDLE; array_id: PISC_QUAD;
  sdl_length: Short; sdl: PAnsiChar; param_length: Short; param: PISC_LONG;
  slice_length: ISC_LONG; slice: PVoid): ISC_STATUS;
begin
  if Assigned(Fisc_put_slice) then
    Result := Fisc_put_slice(status_vector, db_handle, trans_handle, array_id,
      sdl_length, sdl, param_length, param, slice_length, slice)
  else
    raise EFIBAPICallException.Create(Format(SCantFindApiProc, ['isc_put_slice', FLibraryName]));
end;

function TFIBClientLibrary.isc_array_set_desc(status_vector: PISC_STATUS;
  table_name, column_name: PAnsiChar; sql_dtype, sql_length, sql_dimensions
  : PShort; descriptor: PISC_ARRAY_DESC): ISC_STATUS;
begin
  if Assigned(Fisc_array_set_desc) then
    Result := Fisc_array_set_desc(status_vector, table_name, column_name,
      sql_dtype, sql_length, sql_dimensions, descriptor)
  else
    raise EFIBAPICallException.Create(Format(SCantFindApiProc, ['isc_array_set_desc', FLibraryName]));
end;

function TFIBClientLibrary.isc_attach_database(status_vector: PISC_STATUS;
  db_name_length: Short; db_name: PAnsiChar; db_handle: PISC_DB_HANDLE;
  parm_buffer_length: Short; parm_buffer: PAnsiChar): ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_attach_database(status_vector, db_name_length, db_name, db_handle, parm_buffer_length, parm_buffer)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_blob_info(status_vector: PISC_STATUS;
  blob_handle: PISC_BLOB_HANDLE; item_list_buffer_length: Short;
  item_list_buffer: PAnsiChar; result_buffer_length: Short;
  result_buffer: PAnsiChar): ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_blob_info(status_vector, blob_handle,
      item_list_buffer_length, item_list_buffer, result_buffer_length, result_buffer)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_blob_lookup_desc(status_vector: PISC_STATUS;
  db_handle: PISC_DB_HANDLE; trans_handle: PISC_TR_HANDLE;
  table_name, column_name: PAnsiChar; descriptor: PISC_BLOB_DESC;
  global: PUChar): ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_blob_lookup_desc(status_vector, db_handle, trans_handle, table_name, column_name, descriptor, global)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_blob_set_desc(status_vector: PISC_STATUS;
  table_name, column_name: PAnsiChar; subtype, charset, segment_size: Short;
  descriptor: PISC_BLOB_DESC): ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_blob_set_desc(status_vector, table_name, column_name, subtype, charset, segment_size, descriptor)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_cancel_blob(status_vector: PISC_STATUS; blob_handle: PISC_BLOB_HANDLE): ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_cancel_blob(status_vector, blob_handle)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_cancel_events(status_vector: PISC_STATUS; db_handle: PISC_DB_HANDLE; event_id: PISC_LONG): ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_cancel_events(status_vector, db_handle, event_id)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_que_events(status_vector: PISC_STATUS;
  db_handle: PISC_DB_HANDLE; event_id: PISC_LONG; length: Short;
  event_buffer: PAnsiChar; event_function: TISC_CALLBACK;
  event_function_arg: PVoid): ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_que_events(status_vector, db_handle, event_id, length,
      event_buffer, event_function, event_function_arg)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_wait_for_event(status_vector: PISC_STATUS;
  db_handle: PISC_DB_HANDLE; length: Short;
  event_buffer, result_buffer: PAnsiChar): ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_wait_for_event(status_vector, db_handle, length, event_buffer, result_buffer)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_close_blob(status_vector: PISC_STATUS; blob_handle: PISC_BLOB_HANDLE): ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_close_blob(status_vector, blob_handle)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_commit_retaining(status_vector: PISC_STATUS; tran_handle: PISC_TR_HANDLE): ISC_STATUS;
begin
  if Assigned(Fisc_commit_retaining) then
    try
      BeginCall;
      Result := Fisc_commit_retaining(status_vector, tran_handle)
    finally
      EndCall;
    end
  else
    raise EFIBAPICallException.Create(Format(SCantFindApiProc, ['isc_commit_retaining', FLibraryName]));
end;

function TFIBClientLibrary.isc_commit_transaction(status_vector: PISC_STATUS; tran_handle: PISC_TR_HANDLE): ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_commit_transaction(status_vector, tran_handle)
  finally
    EndCall;
  end

end;

function TFIBClientLibrary.isc_transaction_info(status_vector: PISC_STATUS;
  tran_handle: PISC_TR_HANDLE; item_list_buffer_length: Short;
  item_list_buffer: PAnsiChar; result_buffer_length: Short;
  result_buffer: PAnsiChar): ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_transaction_info(status_vector, tran_handle,
      item_list_buffer_length, item_list_buffer, result_buffer_length, result_buffer)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_create_blob2(status_vector: PISC_STATUS;
  db_handle: PISC_DB_HANDLE; tran_handle: PISC_TR_HANDLE;
  blob_handle: PISC_BLOB_HANDLE; blob_id: PISC_QUAD; bpb_length: Short;
  bpb_address: PAnsiChar): ISC_STATUS;
begin
  BeginCall;
  try

    Result := Fisc_create_blob2(status_vector, db_handle, tran_handle, blob_handle, blob_id, bpb_length, bpb_address)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_database_info(status_vector: PISC_STATUS;
  db_handle: PISC_DB_HANDLE; item_list_buffer_length: Short;
  item_list_buffer: PAnsiChar; result_buffer_length: Short;
  result_buffer: PAnsiChar): ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_database_info(status_vector, db_handle,
      item_list_buffer_length, item_list_buffer, result_buffer_length, result_buffer)
  finally
    EndCall;
  end
end;

procedure TFIBClientLibrary.isc_decode_date(ib_date: PISC_QUAD; tm_date: PCTimeStructure);
begin
  BeginCall;
  try
    if Assigned(Fisc_decode_date) then
      Fisc_decode_date(ib_date, tm_date)
    else
      raise EFIBAPICallException.Create(Format(SCantFindApiProc, ['isc_decode_date', FLibraryName]));
  finally
    EndCall;
  end
end;

procedure TFIBClientLibrary.isc_encode_date(tm_date: PCTimeStructure; ib_date: PISC_QUAD);
begin
  BeginCall;
  try
    if Assigned(Fisc_encode_date) then
      Fisc_encode_date(tm_date, ib_date)
    else
      raise EFIBAPICallException.Create(Format(SCantFindApiProc, ['isc_encode_date', FLibraryName]));
  finally
    EndCall;
  end
end;

procedure TFIBClientLibrary.isc_encode_sql_date(tm_date: PCTimeStructure; ib_date: PISC_DATE);
begin
  BeginCall;
  try
    if Assigned(Fisc_encode_sql_date) then
      Fisc_encode_sql_date(tm_date, ib_date)
    else
      raise EFIBAPICallException.Create(Format(SCantFindApiProc, ['isc_encode_sql_date', FLibraryName]));
  finally
    EndCall;
  end
end;

procedure TFIBClientLibrary.isc_encode_sql_time(tm_date: PCTimeStructure; ib_time: PISC_TIME);
begin
  BeginCall;
  try
    if Assigned(Fisc_encode_sql_time) then
      Fisc_encode_sql_time(tm_date, ib_time)
    else
      raise EFIBAPICallException.Create(Format(SCantFindApiProc, ['isc_encode_sql_time', FLibraryName]));
  finally
    EndCall;
  end
end;

procedure TFIBClientLibrary.isc_encode_timestamp(tm_date: PCTimeStructure; ib_timestamp: PISC_TIMESTAMP);
begin
  BeginCall;
  try
    if Assigned(Fisc_encode_timestamp) then
      Fisc_encode_timestamp(tm_date, ib_timestamp)
    else
      raise EFIBAPICallException.Create(Format(SCantFindApiProc, ['isc_encode_timestamp', FLibraryName]));
  finally
    EndCall;
  end

end;

procedure TFIBClientLibrary.isc_decode_sql_date(ib_date: PISC_DATE; tm_date: PCTimeStructure);
begin
  BeginCall;
  try
    if Assigned(Fisc_decode_sql_date) then
      Fisc_decode_sql_date(ib_date, tm_date)
    else
      raise EFIBAPICallException.Create(Format(SCantFindApiProc, ['isc_decode_sql_date', FLibraryName]));
  finally
    EndCall;
  end
end;

procedure TFIBClientLibrary.isc_decode_sql_time(ib_time: PISC_TIME; tm_date: PCTimeStructure);
begin
  BeginCall;
  try
    if Assigned(Fisc_decode_sql_time) then
      Fisc_decode_sql_time(ib_time, tm_date)
    else
      raise EFIBAPICallException.Create(Format(SCantFindApiProc, ['isc_decode_sql_time', FLibraryName]));
  finally
    EndCall;
  end
end;

procedure TFIBClientLibrary.isc_decode_timestamp(ib_timestamp: PISC_TIMESTAMP; tm_date: PCTimeStructure);
begin
  BeginCall;
  try
    if Assigned(Fisc_decode_timestamp) then
      Fisc_decode_timestamp(ib_timestamp, tm_date)
    else
      raise EFIBAPICallException.Create(Format(SCantFindApiProc, ['isc_decode_timestamp', FLibraryName]));
  finally
    EndCall;
  end

end;

function TFIBClientLibrary.isc_add_user(status_vector: PISC_STATUS; user_sec_data: PUserSecData): ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_add_user(status_vector, user_sec_data)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_delete_user(status_vector: PISC_STATUS; user_sec_data: PUserSecData): ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_delete_user(status_vector, user_sec_data)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_modify_user(status_vector: PISC_STATUS; user_sec_data: PUserSecData): ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_modify_user(status_vector, user_sec_data)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_detach_database(status_vector: PISC_STATUS; db_handle: PISC_DB_HANDLE): ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_detach_database(status_vector, db_handle)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_drop_database(status_vector: PISC_STATUS; db_handle: PISC_DB_HANDLE): ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_drop_database(status_vector, db_handle)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_dsql_alloc_statement2(const status_vector
  : PISC_STATUS; db_handle: PISC_DB_HANDLE; stmt_handle: PISC_STMT_HANDLE)
  : ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_dsql_alloc_statement2(status_vector, db_handle, stmt_handle)
  finally
    EndCall;
  end
end;

// IB2007
function TFIBClientLibrary.isc_dsql_batch_execute(status_vector: PISC_STATUS;
  tran_handle: PISC_TR_HANDLE; stmt_handle: PISC_STMT_HANDLE; dialect: UShort;
  insqlda: PXSQLDA; no_of_rows: UShort; batch_vars: PPXSQLVAR;
  rows_affected: PULong): ISC_STATUS;
begin
  if Assigned(Fisc_dsql_batch_execute) then
    try
      BeginCall;
      Result := Fisc_dsql_batch_execute(status_vector, tran_handle, stmt_handle,
        dialect, insqlda, no_of_rows, batch_vars, rows_affected)
    finally
      EndCall;
    end
  else
    raise EFIBAPICallException.Create(Format(SCantFindApiProc, ['isc_dsql_batch_execute', FLibraryName]));
end;

function TFIBClientLibrary.isc_dsql_batch_execute_immed(status_vector
  : PISC_STATUS; db_handle: PISC_DB_HANDLE; tran_handle: PISC_TR_HANDLE;
  dialect: UShort; no_of_sql: ULong; statement: PPAnsiChar;
  rows_affected: PULong): ISC_STATUS;
begin
  if Assigned(Fisc_dsql_batch_execute_immed) then
    try
      BeginCall;
      Result := Fisc_dsql_batch_execute_immed(status_vector, db_handle,
        tran_handle, dialect, no_of_sql, statement, rows_affected)
    finally
      EndCall;
    end
  else
    raise EFIBAPICallException.Create(Format(SCantFindApiProc, ['isc_dsql_batch_execute_immed', FLibraryName]));
end;
// End //IB2007

function TFIBClientLibrary.isc_dsql_describe(status_vector: PISC_STATUS;
  stmt_handle: PISC_STMT_HANDLE; dialect: UShort; xsqlda: PXSQLDA): ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_dsql_describe(status_vector, stmt_handle, dialect, xsqlda)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_dsql_describe_bind(status_vector: PISC_STATUS;
  stmt_handle: PISC_STMT_HANDLE; dialect: UShort; xsqlda: PXSQLDA): ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_dsql_describe_bind(status_vector, stmt_handle, dialect, xsqlda)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_dsql_execute(status_vector: PISC_STATUS;
  tran_handle: PISC_TR_HANDLE; stmt_handle: PISC_STMT_HANDLE; dialect: UShort;
  xsqlda: PXSQLDA): ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_dsql_execute(status_vector, tran_handle, stmt_handle, dialect, xsqlda)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_dsql_execute_immediate(status_vector: PISC_STATUS;
  db_handle: PISC_DB_HANDLE; tran_handle: PISC_TR_HANDLE; length: UShort;
  statement: PAnsiChar; dialect: UShort; xsqlda: PXSQLDA): ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_dsql_execute_immediate(status_vector, db_handle, tran_handle, length, statement, dialect, xsqlda)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_dsql_exec_immed2(status_vector: PISC_STATUS;
  db_handle: PISC_DB_HANDLE; tran_handle: PISC_TR_HANDLE; length: UShort;
  statement: PAnsiChar; dialect: UShort; in_xsqlda, out_xsqlda: PXSQLDA)
  : ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_dsql_exec_immed2(status_vector, db_handle, tran_handle,
      length, statement, dialect, in_xsqlda, out_xsqlda)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_dsql_execute2(status_vector: PISC_STATUS;
  tran_handle: PISC_TR_HANDLE; stmt_handle: PISC_STMT_HANDLE; dialect: UShort;
  in_xsqlda, out_xsqlda: PXSQLDA): ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_dsql_execute2(status_vector, tran_handle, stmt_handle, dialect, in_xsqlda, out_xsqlda)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_dsql_fetch(status_vector: PISC_STATUS;
  stmt_handle: PISC_STMT_HANDLE; dialect: UShort; xsqlda: PXSQLDA): ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_dsql_fetch(status_vector, stmt_handle, dialect, xsqlda);
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_dsql_free_statement(status_vector: PISC_STATUS; stmt_handle: PISC_STMT_HANDLE; options: UShort): ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_dsql_free_statement(status_vector, stmt_handle, options)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_dsql_prepare(status_vector: PISC_STATUS;
  tran_handle: PISC_TR_HANDLE; stmt_handle: PISC_STMT_HANDLE; length: UShort;
  statement: PAnsiChar; dialect: UShort; xsqlda: PXSQLDA): ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_dsql_prepare(status_vector, tran_handle, stmt_handle, length, statement, dialect, xsqlda)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_dsql_set_cursor_name(status_vector: PISC_STATUS;
  stmt_handle: PISC_STMT_HANDLE; cursor_name: PAnsiChar; _type: UShort)
  : ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_dsql_set_cursor_name(status_vector, stmt_handle, cursor_name, _type)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_dsql_sql_info(status_vector: PISC_STATUS;
  stmt_handle: PISC_STMT_HANDLE; item_length: Short; items: PAnsiChar;
  buffer_length: Short; buffer: PAnsiChar): ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_dsql_sql_info(status_vector, stmt_handle, item_length, items, buffer_length, buffer)
  finally
    EndCall;
  end
end;

type
  Tsib_event_block = function(EventBuffer, ResultBuffer: PPAnsiChar;
    IDCount: UShort; Event1, Event2, Event3, Event4, Event5, Event6, Event7,
    Event8, Event9, Event10, Event11, Event12, Event13, Event14,
    Event15: PAnsiChar): ISC_LONG; cdecl;

function TFIBClientLibrary.isc_event_block(event_buffer, result_buffer
  : PPAnsiChar; id_count: UShort; event_list: array of PAnsiChar): ISC_LONG;
begin
  BeginCall;
  try
    Result := Tsib_event_block(Fisc_event_block)(event_buffer, result_buffer,
      id_count, event_list[0], event_list[1], event_list[2], event_list[3],
      event_list[4], event_list[5], event_list[6], event_list[7], event_list[8],
      event_list[9], event_list[10], event_list[11], event_list[12], event_list[13], event_list[14])
  finally
    EndCall;
  end

end;

procedure TFIBClientLibrary.isc_event_counts(event_counts: PUISC_LONG; buffer_length: Short; event_buffer, result_buffer: PAnsiChar);
begin
  BeginCall;
  try
    Fisc_event_counts(event_counts, buffer_length, event_buffer, result_buffer)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_free(isc_arg1: PAnsiChar): ISC_LONG;
begin
  BeginCall;
  try
    Result := Fisc_free(isc_arg1)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_get_client_major_version: Integer;
begin
  if Assigned(Fisc_get_client_major_version) then
    try
      BeginCall;
      Result := Fisc_get_client_major_version
    finally
      EndCall;
    end
  else
    raise EFIBAPICallException.Create(Format(SCantFindApiProc, ['isc_get_client_major_version', FLibraryName]));
end;

function TFIBClientLibrary.isc_get_client_minor_version: Integer;
begin
  if Assigned(Fisc_get_client_minor_version) then
    try
      BeginCall;
      Result := Fisc_get_client_minor_version
    finally
      EndCall;
    end
  else
    raise EFIBAPICallException.Create(Format(SCantFindApiProc, ['isc_get_client_minor_version', FLibraryName]));
end;

procedure TFIBClientLibrary.isc_get_client_version(buffer: PAnsiChar);
begin

  if Assigned(Fisc_get_client_version) then
    try
      BeginCall;
      Fisc_get_client_version(buffer)
    finally
      EndCall;
    end
  else
    raise EFIBAPICallException.Create(Format(SCantFindApiProc, ['isc_get_client_version', FLibraryName]));
end;

function TFIBClientLibrary.isc_get_segment(status_vector: PISC_STATUS;
  blob_handle: PISC_BLOB_HANDLE; actual_seg_length: PUShort;
  seg_buffer_length: UShort; seg_buffer: PAnsiChar): ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_get_segment(status_vector, blob_handle, actual_seg_length, seg_buffer_length, seg_buffer)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_put_segment(status_vector: PISC_STATUS;
  blob_handle: PISC_BLOB_HANDLE; seg_buffer_len: UShort; seg_buffer: PAnsiChar)
  : ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_put_segment(status_vector, blob_handle, seg_buffer_len, seg_buffer)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_interprete(buffer: PAnsiChar; status_vector: PPISC_STATUS): ISC_LONG;
begin
  BeginCall;
  try
    Result := Fisc_interprete(buffer, status_vector)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.fb_Interpret(buffer: PAnsiChar; BufLen: ULong; status_vector: PPISC_STATUS): ISC_LONG;
begin
  if not Assigned(Ffb_interpret) then
    Result := isc_interprete(buffer, status_vector)
  else
  begin
    BeginCall;
    try
      Result := Ffb_interpret(buffer, BufLen, status_vector)
    finally
      EndCall;
    end
  end
end;

function TFIBClientLibrary.isc_open_blob2(status_vector: PISC_STATUS;
  db_handle: PISC_DB_HANDLE; tran_handle: PISC_TR_HANDLE;
  blob_handle: PISC_BLOB_HANDLE; blob_id: PISC_QUAD; bpb_length: Short;
  bpb_buffer: PAnsiChar): ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_open_blob2(status_vector, db_handle, tran_handle, blob_handle, blob_id, bpb_length, bpb_buffer)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_prepare_transaction(status_vector: PISC_STATUS; tran_handle: PISC_TR_HANDLE): ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_prepare_transaction(status_vector, tran_handle)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_prepare_transaction2(status_vector: PISC_STATUS;
  tran_handle: PISC_TR_HANDLE; msg_length: Short; msg: PAnsiChar): ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_prepare_transaction2(status_vector, tran_handle, msg_length, msg)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_rollback_retaining(status_vector: PISC_STATUS; tran_handle: PISC_TR_HANDLE): ISC_STATUS;
begin
  if Assigned(Fisc_rollback_retaining) then
    try
      BeginCall;
      Result := Fisc_rollback_retaining(status_vector, tran_handle)
    finally
      EndCall;
    end
  else
    raise EFIBAPICallException.Create(Format(SCantFindApiProc, ['isc_rollback_retaining', FLibraryName]));
end;

function TFIBClientLibrary.isc_rollback_transaction(status_vector: PISC_STATUS; tran_handle: PISC_TR_HANDLE): ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_rollback_transaction(status_vector, tran_handle)
  finally
    EndCall;
  end
end;


// Services

function TFIBClientLibrary.isc_service_attach(status_vector: PISC_STATUS;
  isc_arg2: UShort; isc_arg3: PAnsiChar; service_handle: PISC_SVC_HANDLE;
  isc_arg5: UShort; isc_arg6: PAnsiChar): ISC_STATUS;
begin
  if Assigned(Fisc_service_attach) then
    try
      BeginCall;
      Result := Fisc_service_attach(status_vector, isc_arg2, isc_arg3, service_handle, isc_arg5, isc_arg6)
    finally
      EndCall;
    end
  else
    raise EFIBAPICallException.Create(Format(SCantFindApiProc, ['isc_service_attach', FLibraryName]));
end;

function TFIBClientLibrary.isc_service_detach(status_vector: PISC_STATUS; service_handle: PISC_SVC_HANDLE): ISC_STATUS;
begin
  if Assigned(Fisc_service_detach) then
    try
      BeginCall;
      Result := Fisc_service_detach(status_vector, service_handle)
    finally
      EndCall;
    end
  else
    raise EFIBAPICallException.Create(Format(SCantFindApiProc, ['isc_service_detach', FLibraryName]));
end;

function TFIBClientLibrary.isc_service_query(status_vector: PISC_STATUS;
  service_handle, recv_handle: PISC_SVC_HANDLE; isc_arg4: UShort;
  isc_arg5: PAnsiChar; isc_arg6: UShort; isc_arg7: PAnsiChar; isc_arg8: UShort;
  isc_arg9: PAnsiChar): ISC_STATUS;
begin
  if Assigned(Fisc_service_query) then
    try
      BeginCall;
      Result := Fisc_service_query(status_vector, service_handle, recv_handle,
        isc_arg4, isc_arg5, isc_arg6, isc_arg7, isc_arg8, isc_arg9)
    finally
      EndCall;
    end
  else
    raise EFIBAPICallException.Create(Format(SCantFindApiProc, ['isc_service_query', FLibraryName]));
end;

function TFIBClientLibrary.isc_service_start(status_vector: PISC_STATUS;
  service_handle, recv_handle: PISC_SVC_HANDLE; isc_arg4: UShort;
  isc_arg5: PAnsiChar): ISC_STATUS;
begin
  if Assigned(Fisc_service_start) then
    try
      BeginCall;
      Result := Fisc_service_start(status_vector, service_handle, recv_handle, isc_arg4, isc_arg5)
    finally
      EndCall;
    end
  else
    raise EFIBAPICallException.Create(Format(SCantFindApiProc, ['isc_service_start', FLibraryName]));
end;

procedure TFIBClientLibrary.isc_sql_interprete(sqlcode: Short; buffer: PAnsiChar; buffer_length: Short);
begin
  BeginCall;
  try
    Fisc_sql_interprete(sqlcode, buffer, buffer_length)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_sqlcode(status_vector: PISC_STATUS): ISC_LONG;
begin
  BeginCall;
  try
    Result := Fisc_sqlcode(status_vector)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.fb_sqlstate(user_status: PISC_STATUS): FIBByteString;
var
  buffer: array [0 .. FB_sqlstate_bufSize - 1] of AnsiChar;
begin
  if Assigned(Ffb_sqlstate) then
    try
      BeginCall;
      FillChar(buffer, FB_sqlstate_bufSize, 0);
      Ffb_sqlstate(@buffer, user_status);
      Result := buffer
    finally
      EndCall;
    end;
end;

function TFIBClientLibrary.isc_start_multiple(status_vector: PISC_STATUS;
  tran_handle: PISC_TR_HANDLE; db_handle_count: Short;
  teb_vector_address: PISC_TEB): ISC_STATUS;
begin
  BeginCall;
  try
    Result := Fisc_start_multiple(status_vector, tran_handle, db_handle_count, teb_vector_address)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_vax_integer(buffer: PAnsiChar; length: Short): ISC_LONG;
begin
  BeginCall;
  try
    Result := Fisc_vax_integer(buffer, length)
  finally
    EndCall;
  end
end;

function TFIBClientLibrary.isc_portable_integer(buffer: PAnsiChar; length: Short): ISC_INT64;
begin
  if Assigned(Fisc_portable_integer) then
    try
      BeginCall;
      Result := Fisc_portable_integer(buffer, length);
    finally
      EndCall;
    end
  else
    raise EFIBAPICallException.Create(Format(SCantFindApiProc, ['isc_portable_integer', FLibraryName]));
end;

constructor TFIBClientLibrary.Create(const aLibName: string);
begin
  inherited Create;
  FLibraryName := aLibName;
  LoadIBLibrary;
end;

destructor TFIBClientLibrary.Destroy;
begin
  FreeIBLibrary;
  inherited Destroy
end;

procedure TFIBClientLibrary.LoadIBLibrary;

  function TryGetProcAddr(ProcName: String): Pointer;
  begin
    Result := GetProcAddress(FLibraryHandle, PChar(ProcName));
  end;

  function GetProcAddr(ProcName: String): Pointer;
  begin
    Result := GetProcAddress(FLibraryHandle, PChar(ProcName));
    if not Assigned(Result) then
      RaiseLastOSError

  end;

var
  VersionBuffer: array [0 .. 255] of AnsiChar;
begin
  FLibraryHandle := LoadLibrary(PChar(FLibraryName));
{$IFDEF WINDOWS}
  if (FLibraryHandle <= HINSTANCE_ERROR) and SameText(FLibraryName, FBCLIENT_DLL) then
    FLibraryHandle := LoadLibrary(GDS32_DLL);
{$ENDIF}
  if (FLibraryHandle > HINSTANCE_ERROR) then
  begin
    FBLOB_get := GetProcAddr('BLOB_get');
    FBLOB_put := GetProcAddr('BLOB_put');
    Fisc_sqlcode := GetProcAddr('isc_sqlcode');
    Fisc_sql_interprete := GetProcAddr('isc_sql_interprete');
    Fisc_interprete := GetProcAddr('isc_interprete');
    Ffb_interpret := TryGetProcAddr('fb_interpret');
    Fisc_vax_integer := GetProcAddr('isc_vax_integer');
    Fisc_blob_info := GetProcAddr('isc_blob_info');
    Fisc_open_blob2 := GetProcAddr('isc_open_blob2');
    Fisc_close_blob := GetProcAddr('isc_close_blob');
    Fisc_get_segment := GetProcAddr('isc_get_segment');
    Fisc_put_segment := GetProcAddr('isc_put_segment');
    Fisc_create_blob2 := GetProcAddr('isc_create_blob2');
    Fisc_decode_date := GetProcAddr('isc_decode_date');
    Fisc_encode_date := GetProcAddr('isc_encode_date');
    Fisc_dsql_free_statement := GetProcAddr('isc_dsql_free_statement');
    Fisc_dsql_execute2 := GetProcAddr('isc_dsql_execute2');
    Fisc_dsql_execute := GetProcAddr('isc_dsql_execute');
    Fisc_dsql_set_cursor_name := GetProcAddr('isc_dsql_set_cursor_name');
    Fisc_dsql_fetch := GetProcAddr('isc_dsql_fetch');
    Fisc_dsql_sql_info := GetProcAddr('isc_dsql_sql_info');
    Fisc_dsql_alloc_statement2 := GetProcAddr('isc_dsql_alloc_statement2');
    Fisc_dsql_prepare := GetProcAddr('isc_dsql_prepare');
    Fisc_dsql_describe_bind := GetProcAddr('isc_dsql_describe_bind');
    Fisc_dsql_describe := GetProcAddr('isc_dsql_describe');
    Fisc_dsql_execute_immediate := GetProcAddr('isc_dsql_execute_immediate');
    Fisc_dsql_exec_immed2 := GetProcAddr('isc_dsql_exec_immed2');
    Fisc_drop_database := GetProcAddr('isc_drop_database');
    Fisc_detach_database := GetProcAddr('isc_detach_database');
    Fisc_attach_database := GetProcAddr('isc_attach_database');
    Fisc_database_info := GetProcAddr('isc_database_info');
    Fisc_start_multiple := GetProcAddr('isc_start_multiple');
    Fisc_commit_transaction := GetProcAddr('isc_commit_transaction');
    Fisc_commit_retaining := GetProcAddr('isc_commit_retaining');
    Fisc_rollback_transaction := GetProcAddr('isc_rollback_transaction');
    Fisc_cancel_events := GetProcAddr('isc_cancel_events');
    Fisc_que_events := GetProcAddr('isc_que_events');
    Fisc_event_counts := GetProcAddr('isc_event_counts');
    Fisc_event_block := GetProcAddr('isc_event_block');
    Fisc_free := GetProcAddr('isc_free');

    Fisc_array_lookup_bounds := GetProcAddr('isc_array_lookup_bounds');

    Fisc_array_get_slice := GetProcAddr('isc_array_get_slice');
    Fisc_array_put_slice := GetProcAddr('isc_array_put_slice');
    Fisc_get_slice := GetProcAddr('isc_get_slice');
    Fisc_put_slice := GetProcAddr('isc_put_slice');
    Fisc_wait_for_event := GetProcAddr('isc_wait_for_event');
    Fisc_transaction_info := GetProcAddr('isc_transaction_info');
    Fisc_prepare_transaction := GetProcAddr('isc_prepare_transaction');
    Fisc_prepare_transaction2 := GetProcAddr('isc_prepare_transaction2');

    Fisc_rollback_retaining := TryGetProcAddr('isc_rollback_retaining');
    if Assigned(Fisc_rollback_retaining) then
    begin
      FIBClientVersion := 6;
      FIBClientMinorVersion := 0;
      Fisc_service_attach := GetProcAddr('isc_service_attach');
      Fisc_service_detach := GetProcAddr('isc_service_detach');
      Fisc_service_query := GetProcAddr('isc_service_query');
      Fisc_service_start := GetProcAddr('isc_service_start');
      Fisc_decode_sql_date := GetProcAddr('isc_decode_sql_date');
      Fisc_decode_sql_time := GetProcAddr('isc_decode_sql_time');
      Fisc_decode_timestamp := GetProcAddr('isc_decode_timestamp');
      Fisc_encode_sql_date := GetProcAddr('isc_encode_sql_date');
      Fisc_encode_sql_time := GetProcAddr('isc_encode_sql_time');
      Fisc_encode_timestamp := GetProcAddr('isc_encode_timestamp');
      Fisc_portable_integer := GetProcAddr('isc_portable_integer');
    end
    else
    begin
      FIBClientVersion := 5;
      FIBClientMinorVersion := 0;
    end;

    Ffb_sqlstate := TryGetProcAddr('fb_sqlstate');
    Ffb_shutdown := TryGetProcAddr('fb_shutdown');
    Ffb_database_crypt_callback := TryGetProcAddr('fb_database_crypt_callback');
  end
  else
  begin
    // Can't load Library
    RaiseLastOSError
  end;

  Fisc_get_client_version := TryGetProcAddr('isc_get_client_version');
  { do not localize }
  if Assigned(Fisc_get_client_version) then
  begin
    Fisc_get_client_major_version := GetProcAddr('isc_get_client_major_version'); { do not localize }
    Fisc_get_client_minor_version := GetProcAddr('isc_get_client_minor_version'); { do not localize }
    FIBClientVersion := Fisc_get_client_major_version;
    FIBClientMinorVersion := Fisc_get_client_minor_version;
    FillChar(VersionBuffer, SizeOf(VersionBuffer), 0);
    Fisc_get_client_version(@VersionBuffer[0]);
    // the version text is ASCII
    FVersion := ParseClientVersion(string(PAnsiChar(@VersionBuffer[0])));
    // IB2007
    Fisc_dsql_batch_execute_immed :=
      TryGetProcAddr('isc_dsql_batch_execute_immed');
    Fisc_dsql_batch_execute := TryGetProcAddr('isc_dsql_batch_execute');
    // FB2.5
    Ffb_cancel_operation := TryGetProcAddr('fb_cancel_operation');
    Ffb_dsql_set_timeout := TryGetProcAddr('fb_dsql_set_timeout')
  end
  else
  begin
    FIBClientMinorVersion := 0;
    FillChar(FVersion, SizeOf(FVersion), 0);
  end;

  // Loading the client library can change the FPU control word
  Reset8087CW;
end;

procedure TFIBClientLibrary.FreeIBLibrary;
begin
  // Firebird client must stop its own threads before being unloaded
  if Assigned(Ffb_shutdown) and LibraryLoaded then
    Ffb_shutdown(0, fb_shutrsn_app_stopped);
  Ffb_shutdown := nil;
  // FreeLibrary is dlclose on POSIX, as LoadLibrary is dlopen
  if LibraryLoaded then
  begin
    FreeLibrary(FLibraryHandle);
    FLibraryHandle := HINSTANCE_ERROR
  end;
end;

function TFIBClientLibrary.LibraryLoaded: Boolean;
begin
  Result := FLibraryHandle > HINSTANCE_ERROR;
end;

function TFIBClientLibrary.fb_cancel_operation(status_vector: PISC_STATUS; db_handle: PISC_DB_HANDLE; option: UShort): ISC_STATUS;
begin
  if Assigned(Ffb_cancel_operation) then
    Result := Ffb_cancel_operation(status_vector, db_handle, option)
  else
    raise EFIBAPICallException.Create(Format(SCantFindApiProc, ['fb_cancel_operation', FLibraryName]));
end;

function TFIBClientLibrary.fb_dsql_set_timeout(status_vector: PISC_STATUS; stmt_handle: PISC_STMT_HANDLE; timeout: Cardinal): ISC_STATUS;
begin
  if not Assigned(Ffb_dsql_set_timeout) then
    raise EFIBAPICallException.Create(Format(SCantFindApiProc, ['fb_dsql_set_timeout', FLibraryName]));
  Result := Ffb_dsql_set_timeout(status_vector, stmt_handle, timeout);
end;

function TFIBClientLibrary.HasStatementTimeout: Boolean;
begin
  Result := Assigned(Ffb_dsql_set_timeout);
end;

function TFIBClientLibrary.fb_database_crypt_callback(StatusVector: PISC_STATUS; Callback: Pointer): ISC_STATUS;
begin
  if not Assigned(Ffb_database_crypt_callback) then
    raise EFIBAPICallException.Create(Format(SCantFindApiProc, ['fb_database_crypt_callback', FLibraryName]));
  Result := Ffb_database_crypt_callback(StatusVector, Callback);
end;

function TFIBClientLibrary.GetBusy: Boolean;
begin
  Result := FBusyCount > 0
end;

procedure TFIBClientLibrary.BeginCall;
begin
{$IFDEF WINDOWS}
  InterlockedIncrement(FBusyCount);
{$ELSE}
  TInterlocked.Increment(FBusyCount);
{$ENDIF}
end;

procedure TFIBClientLibrary.EndCall;
begin
{$IFDEF WINDOWS}
  InterlockedDecrement(FBusyCount);
{$ELSE}
  TInterlocked.Decrement(FBusyCount);
{$ENDIF}
end;

function TFIBClientLibrary.LibraryFilePath: string;
var
  buffer: array [0 .. 1024] of Char;
begin
  GetModuleFileName(FLibraryHandle, buffer, SizeOf(buffer));
  Result := buffer
end;

type
  TCryptKeyCallbackVTable = record
    Dummy: Pointer;
    Version: NativeInt;
    Callback: function(This: TFIBCryptKeyCallback; DataLength: Cardinal;
      Data: Pointer; BufferLength: Cardinal; buffer: Pointer): Cardinal; cdecl;
  end;

function CryptKeyCallbackDispatcher(This: TFIBCryptKeyCallback;
  DataLength: Cardinal; Data: Pointer; BufferLength: Cardinal; buffer: Pointer)
  : Cardinal; cdecl;
begin
  Result := This.Callback(DataLength, Data, BufferLength, buffer);
end;

const
  // Version 2: IVersioned + callback()
  CryptKeyCallbackVTable: TCryptKeyCallbackVTable = (Dummy: nil; Version: 2;
    Callback: CryptKeyCallbackDispatcher);

constructor TFIBCryptKeyCallback.Create(Sender: TObject; OnRequest: TFIBCryptKeyRequestEvent);
begin
  inherited Create;
  FVTable := @CryptKeyCallbackVTable;
  FSender := Sender;
  FOnRequest := OnRequest;
end;

destructor TFIBCryptKeyCallback.Destroy;
begin
  FRequestError.Free;
  inherited Destroy;
end;

function TFIBCryptKeyCallback.Callback(DataLength: Cardinal; Data: Pointer; BufferLength: Cardinal; buffer: Pointer): Cardinal;
var
  RequestData, Key: FIBByteString;
begin
  Result := 0;
  try
    SetString(RequestData, PAnsiChar(Data), DataLength);
    Key := '';
    FOnRequest(FSender, RequestData, Key);
    // A truncated key would fail with a misleading error
    if Cardinal(length(Key)) > BufferLength then
      raise EFIBAPICallException.Create(Format(SCryptKeyTooLong, [length(Key), BufferLength]));
    if Key <> '' then
      Move(Pointer(Key)^, buffer^, length(Key));
    Result := Cardinal(length(Key));
  except
    // Must not cross the client library: raised by the caller after the attachment
    if FRequestError = nil then
      FRequestError := AcquireExceptionObject;
  end;
end;

function TFIBCryptKeyCallback.Activate(const ClientLibrary: IFIBClientLibrary; StatusVector: PISC_STATUS): ISC_STATUS;
begin
  FreeAndNil(FRequestError);
  Result := ClientLibrary.fb_database_crypt_callback(StatusVector, Self);
end;

procedure TFIBCryptKeyCallback.Deactivate(const ClientLibrary: IFIBClientLibrary);
var
  Status: array [0 .. 19] of ISC_STATUS;
begin
  // Own status vector, to keep the error of the attachment
  ClientLibrary.fb_database_crypt_callback(@Status, nil);
end;

procedure TFIBCryptKeyCallback.RaiseRequestError;
var
  E: TObject;
begin
  E := FRequestError;
  if E <> nil then
  begin
    FRequestError := nil;
    raise E;
  end;
end;

initialization

ClientLibraries := TInterfaceList.Create;
ClientLibrariesLock := TCriticalSection.Create;

finalization

ClientLibraries.Free;
FreeAndNil(ClientLibrariesLock);

end.
