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


unit IB_Intf;

interface

uses
{$I FIBPlus.inc}
{$T-}
{$IFDEF WINDOWS} Windows , {$ENDIF}
 SyncObjs, Classes,Sysutils, ibase, IB_InstallHeader, IB_Externals,FIBPlatforms;

type

{$M-}
   IIBClientLibrary = interface
    ['{BB362CBF-2BD0-41A8-8982-F5E3327354A6}']
    function  GetLibName:string;
    function  GetIBClientVersion: Integer;
    function  GetIBClientMinorVersion: Integer;
    function  GetBusy:boolean;
    function  isc_attach_database(status_vector : PISC_STATUS; db_name_length : Short;
                                 db_name : PAnsiChar; db_handle : PISC_DB_HANDLE;
			                           parm_buffer_length	: Short; parm_buffer : PAnsiChar): ISC_STATUS;
    function  isc_array_get_slice(status_vector : PISC_STATUS; db_handle : PISC_DB_HANDLE;
                                 trans_handle : PISC_TR_HANDLE; array_id : PISC_QUAD;
                                 descriptor : PISC_ARRAY_DESC; dest_array : PVoid;
				                         slice_length : ISC_LONG): ISC_STATUS;
    function  isc_array_lookup_bounds(status_vector : PISC_STATUS; db_handle : PISC_DB_HANDLE;
                                     trans_handle : PISC_TR_HANDLE; table_name, column_name : PAnsiChar;
				                             descriptor : PISC_ARRAY_DESC): ISC_STATUS;
    function  isc_array_lookup_desc(status_vector : PISC_STATUS; db_handle : PISC_DB_HANDLE;
                                   trans_handle : PISC_TR_HANDLE; table_name, column_name : PAnsiChar;
				                           descriptor : PISC_ARRAY_DESC): ISC_STATUS;
    function isc_array_set_desc(status_vector : PISC_STATUS; table_name : PAnsiChar;
                                column_name : PAnsiChar; sql_dtype, sql_length, sql_dimensions           : PShort;
                                 descriptor : PISC_ARRAY_DESC): ISC_STATUS;
    function isc_array_put_slice(status_vector : PISC_STATUS; db_handle  : PISC_DB_HANDLE;
                                 trans_handle : PISC_TR_HANDLE; array_id : PISC_QUAD;
                                 descriptor : PISC_ARRAY_DESC; source_array : PVoid;
                                 slice_length : PISC_LONG): ISC_STATUS;
    function isc_blob_info(status_vector : PISC_STATUS; blob_handle : PISC_BLOB_HANDLE;
				                   item_list_buffer_length : Short; item_list_buffer : PAnsiChar;
				                   result_buffer_length : Short; result_buffer : PAnsiChar): ISC_STATUS;
    function isc_blob_lookup_desc(status_vector : PISC_STATUS; db_handle : PISC_DB_HANDLE;
                                  trans_handle : PISC_TR_HANDLE; table_name, column_name : PAnsiChar;
                                  descriptor : PISC_BLOB_DESC; global : PUChar): ISC_STATUS;
    function isc_blob_set_desc(status_vector : PISC_STATUS; table_name, column_name : PAnsiChar;
                               subtype, charset, segment_size : Short; descriptor : PISC_BLOB_DESC): ISC_STATUS;
    function isc_cancel_blob(status_vector  : PISC_STATUS; blob_handle : PISC_BLOB_HANDLE): ISC_STATUS;


    function isc_cancel_events(status_vector : PISC_STATUS; db_handle : PISC_DB_HANDLE;
				                       event_id : PISC_LONG): ISC_STATUS;
    function isc_que_events(status_vector : PISC_STATUS; db_handle : PISC_DB_HANDLE;
      event_id : PISC_LONG; length : Short; event_buffer : PAnsiChar;
      event_function : TISC_CALLBACK; event_function_arg        : PVoid): ISC_STATUS;
    function isc_wait_for_event  (status_vector             : PISC_STATUS;
     db_handle                 : PISC_DB_HANDLE;
     length                    : Short;
     event_buffer,result_buffer             : PAnsiChar): ISC_STATUS;


    function isc_close_blob(status_vector : PISC_STATUS; blob_handle : PISC_BLOB_HANDLE): ISC_STATUS;
    function isc_create_blob2(status_vector : PISC_STATUS; db_handle : PISC_DB_HANDLE;
                              tran_handle : PISC_TR_HANDLE; blob_handle : PISC_BLOB_HANDLE;
                              blob_id : PISC_QUAD; bpb_length : Short; bpb_address : PAnsiChar): ISC_STATUS;


    function isc_commit_retaining(status_vector : PISC_STATUS; tran_handle : PISC_TR_HANDLE): ISC_STATUS;
    function isc_commit_transaction(status_vector : PISC_STATUS; tran_handle : PISC_TR_HANDLE): ISC_STATUS;
    function isc_transaction_info(status_vector            : PISC_STATUS;
                                 tran_handle               : PISC_TR_HANDLE;
                                 item_list_buffer_length   : Short;
                                 item_list_buffer          : PAnsiChar;
                                 result_buffer_length      : Short;
                                 result_buffer             : PAnsiChar): ISC_STATUS;


    function isc_database_info(status_vector : PISC_STATUS; db_handle : PISC_DB_HANDLE;
                               item_list_buffer_length : Short; item_list_buffer : PAnsiChar;
                                 result_buffer_length : Short; result_buffer : PAnsiChar): ISC_STATUS;
    procedure isc_decode_date(ib_date: PISC_QUAD; tm_date: PCTimeStructure);
    procedure isc_decode_sql_date(ib_date: PISC_DATE; tm_date: PCTimeStructure);
    procedure isc_decode_sql_time(ib_time: PISC_TIME; tm_date: PCTimeStructure);
    procedure isc_decode_timestamp(ib_timestamp: PISC_TIMESTAMP; tm_date: PCTimeStructure);
    function isc_detach_database(status_vector : PISC_STATUS; db_handle : PISC_DB_HANDLE): ISC_STATUS;
    function isc_drop_database(status_vector : PISC_STATUS; db_handle : PISC_DB_HANDLE): ISC_STATUS;
    function isc_dsql_alloc_statement2(const status_vector : PISC_STATUS; db_handle : PISC_DB_HANDLE;
				                               stmt_handle : PISC_STMT_HANDLE): ISC_STATUS;
    function isc_dsql_describe(status_vector : PISC_STATUS; stmt_handle : PISC_STMT_HANDLE;
                               dialect : UShort; xsqlda : PXSQLDA): ISC_STATUS;
    function isc_dsql_describe_bind(status_vector : PISC_STATUS; stmt_handle : PISC_STMT_HANDLE;
                                 dialect : UShort; xsqlda : PXSQLDA): ISC_STATUS;
    function isc_dsql_execute(status_vector : PISC_STATUS; tran_handle : PISC_TR_HANDLE;
                              stmt_handle : PISC_STMT_HANDLE; dialect : UShort;
                              xsqlda : PXSQLDA): ISC_STATUS;
    function isc_dsql_execute2(status_vector : PISC_STATUS; tran_handle : PISC_TR_HANDLE;
                               stmt_handle : PISC_STMT_HANDLE; dialect : UShort;
                               in_xsqlda, out_xsqlda : PXSQLDA): ISC_STATUS;
    function isc_dsql_execute_immediate(status_vector : PISC_STATUS; db_handle : PISC_DB_HANDLE;
				                                tran_handle : PISC_TR_HANDLE; length : UShort;
				                                statement : PAnsiChar; dialect : UShort;
                                        xsqlda : PXSQLDA): ISC_STATUS;

    function isc_dsql_exec_immed2(status_vector           : PISC_STATUS;
				 db_handle                : PISC_DB_HANDLE;
				 tran_handle              : PISC_TR_HANDLE;
				 length                   : UShort;
				 statement                : PAnsiChar;
				 dialect                  : UShort;
                                 in_xsqlda,
				 out_xsqlda               : PXSQLDA): ISC_STATUS;
                                 
    function isc_dsql_fetch(status_vector : PISC_STATUS; stmt_handle : PISC_STMT_HANDLE;
				                    dialect : UShort; xsqlda : PXSQLDA): ISC_STATUS;
    function isc_dsql_free_statement(status_vector : PISC_STATUS; stmt_handle : PISC_STMT_HANDLE;
                                     options : UShort): ISC_STATUS;
    function isc_dsql_prepare(status_vector : PISC_STATUS; tran_handle : PISC_TR_HANDLE;
                              stmt_handle : PISC_STMT_HANDLE; length : UShort;
                              statement : PAnsiChar; dialect : UShort;
                              xsqlda : PXSQLDA): ISC_STATUS;
    function isc_dsql_set_cursor_name(status_vector : PISC_STATUS; stmt_handle : PISC_STMT_HANDLE;
                                      cursor_name : PAnsiChar; _type : UShort): ISC_STATUS;
    function isc_dsql_sql_info(status_vector : PISC_STATUS; stmt_handle : PISC_STMT_HANDLE;
				                       item_length : Short; items : PAnsiChar; buffer_length : Short;
                               buffer : PAnsiChar): ISC_STATUS;
    procedure isc_encode_date(tm_date : PCTimeStructure; ib_date : PISC_QUAD);
    procedure isc_encode_sql_date(tm_date: PCTimeStructure; ib_date : PISC_DATE);
    procedure isc_encode_sql_time(tm_date : PCTimeStructure; ib_time : PISC_TIME);
    procedure isc_encode_timestamp(tm_date : PCTimeStructure; ib_timestamp : PISC_TIMESTAMP);
    function isc_event_block(event_buffer : PPAnsiChar; result_buffer : PPAnsiChar;
				                     id_count : UShort; event_list : array of PAnsiChar): ISC_LONG;
    procedure isc_event_counts(status_vector : PISC_STATUS; buffer_length  : Short;
				                       event_buffer : PAnsiChar; result_buffer : PAnsiChar);
    function isc_free(isc_arg1 : PAnsiChar): ISC_LONG;
    function isc_get_segment(status_vector : PISC_STATUS; blob_handle : PISC_BLOB_HANDLE;
                             actual_seg_length : PUShort; seg_buffer_length : UShort;
				                     seg_buffer : PAnsiChar): ISC_STATUS;
    function isc_put_segment(status_vector : PISC_STATUS; blob_handle : PISC_BLOB_HANDLE;
				                     seg_buffer_len : UShort; seg_buffer : PAnsiChar): ISC_STATUS;

    function isc_interprete(buffer : PAnsiChar; status_vector : PPISC_STATUS): ISC_STATUS;
    function  fb_Interpret(buffer: PAnsiChar; BufLen: ULong;
				 status_vector             : PPISC_STATUS):ISC_STATUS;

    function isc_open_blob2(status_vector : PISC_STATUS; db_handle : PISC_DB_HANDLE;
                            tran_handle : PISC_TR_HANDLE; blob_handle : PISC_BLOB_HANDLE;
				                    blob_id : PISC_QUAD; bpb_length : Short; bpb_buffer : PAnsiChar): ISC_STATUS;
    function isc_prepare_transaction2(status_vector : PISC_STATUS; tran_handle : PISC_TR_HANDLE;
                                      msg_length : Short; msg : PAnsiChar): ISC_STATUS;

    function isc_rollback_retaining(status_vector : PISC_STATUS; tran_handle : PISC_TR_HANDLE): ISC_STATUS;
    function isc_rollback_transaction(status_vector : PISC_STATUS; tran_handle : PISC_TR_HANDLE): ISC_STATUS;
    function isc_start_multiple(status_vector : PISC_STATUS; tran_handle : PISC_TR_HANDLE;
                                db_handle_count : Short; teb_vector_address : PISC_TEB): ISC_STATUS;
    function  isc_sqlcode(status_vector : PISC_STATUS): ISC_LONG;
    procedure isc_sql_interprete(sqlcode : Short; buffer : PAnsiChar;
                                 buffer_length : Short);
    function  isc_vax_integer(buffer : PAnsiChar; length : Short): ISC_LONG;

    function  isc_add_user(status_vector : PISC_STATUS; user_sec_data : PUserSecData): ISC_STATUS;
    function  isc_delete_user(status_vector : PISC_STATUS; user_sec_data : PUserSecData): ISC_STATUS;
    function  isc_modify_user(status_vector : PISC_STATUS; user_sec_data : PUserSecData): ISC_STATUS;


    function isc_prepare_transaction(status_vector         : PISC_STATUS;
                                 tran_handle               : PISC_TR_HANDLE): ISC_STATUS;

    function BLOB_put(isc_arg1                  : Ansichar;  isc_arg2                  : PBSTREAM): Int;
    function BLOB_get(isc_arg1                  : PBSTREAM): Int;

//IB2007
    function isc_dsql_batch_execute_immed(status_vector : PISC_STATUS; db_handle : PISC_DB_HANDLE;
						   tran_handle : PISC_TR_HANDLE; Dialect : UShort; no_of_sql : ulong;
						   statement : PPAnsiChar; rows_affected : PULong) : ISC_STATUS;
    function isc_dsql_batch_execute(status_vector : PISC_STATUS; tran_handle : PISC_TR_HANDLE;
						   stmt_handle : PISC_STMT_HANDLE; Dialect : UShort;
						   insqlda : PXSQLDA; no_of_rows : UShort;
						   batch_vars : PPXSQLVAR; rows_affected : PULong) : ISC_STATUS;
//FB2.5
    function fb_cancel_operation(status_vector : PISC_STATUS; db_handle : PISC_DB_HANDLE;
              option : UShort
    ) : ISC_STATUS;

    function fb_sqlstate(user_status: PISC_STATUS):FIBByteString;
   // Service manager functions
   function isc_service_attach (status_vector             : PISC_STATUS;
                                 isc_arg2                  : UShort;
                                 isc_arg3                  : PAnsiChar;
                                 service_handle            : PISC_SVC_HANDLE;
                                 isc_arg5                  : UShort;
                                 isc_arg6                  : PAnsiChar): ISC_STATUS;
    function isc_service_detach(status_vector             : PISC_STATUS;
                                service_handle            : PISC_SVC_HANDLE): ISC_STATUS;
    function isc_service_query  (status_vector             : PISC_STATUS;
                                 service_handle            : PISC_SVC_HANDLE;
                                 recv_handle               : PISC_SVC_HANDLE;
                                 isc_arg4                  : UShort;
                                 isc_arg5                  : PAnsiChar;
                                 isc_arg6                  : UShort;
                                 isc_arg7                  : PAnsiChar;
                                 isc_arg8                  : UShort;
                                 isc_arg9                  : PAnsiChar): ISC_STATUS;
    function isc_service_start (status_vector             : PISC_STATUS;
                                service_handle            : PISC_SVC_HANDLE;
                                recv_handle               : PISC_SVC_HANDLE;
                                isc_arg4                  : UShort;
                                isc_arg5                  : PAnsiChar): ISC_STATUS;
    // Client information functions
    procedure isc_get_client_version(buffer : PAnsiChar);
    function  isc_get_client_major_version: Integer;
    function  isc_get_client_minor_version: Integer;


    function isc_portable_integer(buffer: PAnsiChar;length: Short): ISC_INT64;

    procedure FreeIBLibrary;
    procedure LoadIBLibrary;
    function  LibraryLoaded:boolean;
    function  LibraryFilePath:string;
    property  LibraryName:string read GetLibName;
    property  ClientMinorVersion:integer read GetIBClientMinorVersion;
    property  ClientVersion     :integer read GetIBClientVersion;
    property  Busy:boolean read GetBusy;
  end;
{$M+}
  EAPICallException =Exception;

  TIBClientLibrary = class(TInterfacedObject, IIbClientLibrary)
  private
    FLibraryHandle:THandle;
    FLibraryName:string;
    FIBClientVersion     :integer;
    FIBClientMinorVersion:integer;
  private
    FBLOB_get            : TBLOB_get;
    FBLOB_put            : TBLOB_put;
    Fisc_sqlcode         : Tisc_sqlcode;
    Ffb_sqlstate         : Tfb_sqlstate;
    Fisc_sql_interprete  : Tisc_sql_interprete;
    Fisc_interprete      : Tisc_interprete;
    Ffb_interpret        : Tfb_interpret;
    Fisc_vax_integer     : Tisc_vax_integer;
    Fisc_blob_info       : Tisc_blob_info;
    Fisc_open_blob2      : Tisc_open_blob2;
    Fisc_close_blob      : Tisc_close_blob;
    Fisc_get_segment     :Tisc_get_segment;
    Fisc_put_segment     :Tisc_put_segment;
    Fisc_create_blob2    :Tisc_create_blob2;
    Fisc_blob_lookup_desc:Tisc_blob_lookup_desc;
    Fisc_blob_set_desc   :Tisc_blob_set_desc;
    Fisc_cancel_blob     :Tisc_cancel_blob ;

    Fisc_service_attach  : Tisc_service_attach;
    Fisc_service_detach  : Tisc_service_detach;
    Fisc_service_query   : Tisc_service_query;
    Fisc_service_start   : Tisc_service_start;
    Fisc_decode_date     : Tisc_decode_date;
    Fisc_decode_sql_date : Tisc_decode_sql_date;
    Fisc_decode_sql_time : Tisc_decode_sql_time;
    Fisc_decode_timestamp: Tisc_decode_timestamp;
    Fisc_encode_date     : Tisc_encode_date;
    Fisc_encode_sql_date : Tisc_encode_sql_date;
    Fisc_encode_sql_time : Tisc_encode_sql_time;
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
    Fisc_wait_for_event:Tisc_wait_for_event;
    Fisc_transaction_info:Tisc_transaction_info;
    Fisc_prepare_transaction:Tisc_prepare_transaction;
    Fisc_prepare_transaction2:Tisc_prepare_transaction2;
    //Array functions
    Fisc_array_lookup_bounds :Tisc_array_lookup_bounds;
    Fisc_array_get_slice     :Tisc_array_get_slice;
    Fisc_array_put_slice     :Tisc_array_put_slice;
    Fisc_array_set_desc      :Tisc_array_set_desc;
    Fisc_array_lookup_desc   :Tisc_array_lookup_desc;


    Fisc_portable_integer    :Tisc_portable_integer;

    Fisc_add_user   :Tisc_add_user;
    Fisc_delete_user:Tisc_delete_user;
    Fisc_modify_user:Tisc_modify_user;
   { IB 7.0 functions only}
    Fisc_get_client_version : Tisc_get_client_version;
    Fisc_get_client_major_version : Tisc_get_client_major_version;
    Fisc_get_client_minor_version : Tisc_get_client_minor_version;
//IB2007
    Fisc_dsql_batch_execute_immed : Tisc_dsql_batch_execute_immed;
    Fisc_dsql_batch_execute       : Tisc_dsql_batch_execute;
//FB2.5
    Ffb_cancel_operation: Tfb_cancel_operation;
  private
    FBusy:boolean;

    function  GetLibName:string;
    function  GetIBClientVersion: Integer;
    function  GetIBClientMinorVersion: Integer;
    function  GetBusy:boolean;
    function  isc_attach_database(status_vector : PISC_STATUS; db_name_length : Short;
                                 db_name : PAnsiChar; db_handle : PISC_DB_HANDLE;
			                           parm_buffer_length	: Short; parm_buffer : PAnsiChar): ISC_STATUS;
    function  isc_array_get_slice(status_vector : PISC_STATUS; db_handle : PISC_DB_HANDLE;
                                 trans_handle : PISC_TR_HANDLE; array_id : PISC_QUAD;
                                 descriptor : PISC_ARRAY_DESC; dest_array : PVoid;
				                         slice_length : ISC_LONG): ISC_STATUS;
    function  isc_array_lookup_bounds(status_vector : PISC_STATUS; db_handle : PISC_DB_HANDLE;
                                     trans_handle : PISC_TR_HANDLE; table_name, column_name : PAnsiChar;
				                             descriptor : PISC_ARRAY_DESC): ISC_STATUS;
    function  isc_array_lookup_desc(status_vector : PISC_STATUS; db_handle : PISC_DB_HANDLE;
                                   trans_handle : PISC_TR_HANDLE; table_name, column_name : PAnsiChar;
				                           descriptor : PISC_ARRAY_DESC): ISC_STATUS;
    function isc_array_set_desc(status_vector : PISC_STATUS; table_name : PAnsiChar;
                                column_name : PAnsiChar; sql_dtype, sql_length, sql_dimensions           : PShort;
                                 descriptor : PISC_ARRAY_DESC): ISC_STATUS;
    function isc_array_put_slice(status_vector : PISC_STATUS; db_handle  : PISC_DB_HANDLE;
                                 trans_handle : PISC_TR_HANDLE; array_id : PISC_QUAD;
                                 descriptor : PISC_ARRAY_DESC; source_array : PVoid;
                                 slice_length : PISC_LONG): ISC_STATUS;
    function isc_blob_info(status_vector : PISC_STATUS; blob_handle : PISC_BLOB_HANDLE;
				                   item_list_buffer_length : Short; item_list_buffer : PAnsiChar;
				                   result_buffer_length : Short; result_buffer : PAnsiChar): ISC_STATUS;
    function isc_blob_lookup_desc(status_vector : PISC_STATUS; db_handle : PISC_DB_HANDLE;
                                  trans_handle : PISC_TR_HANDLE; table_name, column_name : PAnsiChar;
                                  descriptor : PISC_BLOB_DESC; global : PUChar): ISC_STATUS;
    function isc_blob_set_desc(status_vector : PISC_STATUS; table_name, column_name : PAnsiChar;
                               subtype, charset, segment_size : Short; descriptor : PISC_BLOB_DESC): ISC_STATUS;
    function isc_cancel_blob(status_vector  : PISC_STATUS; blob_handle : PISC_BLOB_HANDLE): ISC_STATUS;
    function isc_cancel_events(status_vector : PISC_STATUS; db_handle : PISC_DB_HANDLE;
				                       event_id : PISC_LONG): ISC_STATUS;
    function isc_que_events(status_vector : PISC_STATUS; db_handle : PISC_DB_HANDLE;
				                    event_id : PISC_LONG; length : Short; event_buffer : PAnsiChar;
                            event_function : TISC_CALLBACK; event_function_arg        : PVoid): ISC_STATUS;

    function isc_wait_for_event  (status_vector: PISC_STATUS;
     db_handle: PISC_DB_HANDLE;length: Short; event_buffer,result_buffer: PAnsiChar): ISC_STATUS;

    function isc_close_blob(status_vector : PISC_STATUS; blob_handle : PISC_BLOB_HANDLE): ISC_STATUS;
    function isc_commit_retaining(status_vector : PISC_STATUS; tran_handle : PISC_TR_HANDLE): ISC_STATUS;
    function isc_commit_transaction(status_vector : PISC_STATUS; tran_handle : PISC_TR_HANDLE): ISC_STATUS;

    function isc_transaction_info(status_vector            : PISC_STATUS;
                                 tran_handle               : PISC_TR_HANDLE;
                                 item_list_buffer_length   : Short;
                                 item_list_buffer          : PAnsiChar;
                                 result_buffer_length      : Short;
                                 result_buffer             : PAnsiChar): ISC_STATUS;

    function isc_create_blob2(status_vector : PISC_STATUS; db_handle : PISC_DB_HANDLE;
                              tran_handle : PISC_TR_HANDLE; blob_handle : PISC_BLOB_HANDLE;
                              blob_id : PISC_QUAD; bpb_length : Short; bpb_address : PAnsiChar): ISC_STATUS;
    function isc_database_info(status_vector : PISC_STATUS; db_handle : PISC_DB_HANDLE;
                               item_list_buffer_length : Short; item_list_buffer : PAnsiChar;
                                 result_buffer_length : Short; result_buffer : PAnsiChar): ISC_STATUS;
    procedure isc_decode_date(ib_date: PISC_QUAD; tm_date: PCTimeStructure);
    procedure isc_decode_sql_date(ib_date: PISC_DATE; tm_date: PCTimeStructure);
    procedure isc_decode_sql_time(ib_time: PISC_TIME; tm_date: PCTimeStructure);
    procedure isc_decode_timestamp(ib_timestamp: PISC_TIMESTAMP; tm_date: PCTimeStructure);
    function isc_detach_database(status_vector : PISC_STATUS; db_handle : PISC_DB_HANDLE): ISC_STATUS;
    function isc_drop_database(status_vector : PISC_STATUS; db_handle : PISC_DB_HANDLE): ISC_STATUS;
    function isc_dsql_alloc_statement2(const status_vector : PISC_STATUS; db_handle : PISC_DB_HANDLE;
				                               stmt_handle : PISC_STMT_HANDLE): ISC_STATUS;
    function isc_dsql_describe(status_vector : PISC_STATUS; stmt_handle : PISC_STMT_HANDLE;
                               dialect : UShort; xsqlda : PXSQLDA): ISC_STATUS;
    function isc_dsql_describe_bind(status_vector : PISC_STATUS; stmt_handle : PISC_STMT_HANDLE;
                                 dialect : UShort; xsqlda : PXSQLDA): ISC_STATUS;
    function isc_dsql_execute(status_vector : PISC_STATUS; tran_handle : PISC_TR_HANDLE;
                              stmt_handle : PISC_STMT_HANDLE; dialect : UShort;
                              xsqlda : PXSQLDA): ISC_STATUS;
    function isc_dsql_execute2(status_vector : PISC_STATUS; tran_handle : PISC_TR_HANDLE;
                               stmt_handle : PISC_STMT_HANDLE; dialect : UShort;
                               in_xsqlda, out_xsqlda : PXSQLDA): ISC_STATUS;
    function isc_dsql_execute_immediate(status_vector : PISC_STATUS; db_handle : PISC_DB_HANDLE;
				                                tran_handle : PISC_TR_HANDLE; length : UShort;
				                                statement : PAnsiChar; dialect : UShort;
                                        xsqlda : PXSQLDA): ISC_STATUS;

    function isc_dsql_exec_immed2(status_vector           : PISC_STATUS;
				 db_handle                : PISC_DB_HANDLE;
				 tran_handle              : PISC_TR_HANDLE;
				 length                   : UShort;
				 statement                : PAnsiChar;
				 dialect                  : UShort;
                                 in_xsqlda,
				 out_xsqlda               : PXSQLDA): ISC_STATUS;


    function isc_dsql_fetch(status_vector : PISC_STATUS; stmt_handle : PISC_STMT_HANDLE;
				                    dialect : UShort; xsqlda : PXSQLDA): ISC_STATUS;
    function isc_dsql_free_statement(status_vector : PISC_STATUS; stmt_handle : PISC_STMT_HANDLE;
                                     options : UShort): ISC_STATUS;
    function isc_dsql_prepare(status_vector : PISC_STATUS; tran_handle : PISC_TR_HANDLE;
                              stmt_handle : PISC_STMT_HANDLE; length : UShort;
                              statement : PAnsiChar; dialect : UShort;
                              xsqlda : PXSQLDA): ISC_STATUS;
    function isc_dsql_set_cursor_name(status_vector : PISC_STATUS; stmt_handle : PISC_STMT_HANDLE;
                                      cursor_name : PAnsiChar; _type : UShort): ISC_STATUS;
    function isc_dsql_sql_info(status_vector : PISC_STATUS; stmt_handle : PISC_STMT_HANDLE;
				                       item_length : Short; items : PAnsiChar; buffer_length : Short;
                               buffer : PAnsiChar): ISC_STATUS;
    procedure isc_encode_date(tm_date : PCTimeStructure; ib_date : PISC_QUAD);
    procedure isc_encode_sql_date(tm_date: PCTimeStructure; ib_date : PISC_DATE);
    procedure isc_encode_sql_time(tm_date : PCTimeStructure; ib_time : PISC_TIME);
    procedure isc_encode_timestamp(tm_date : PCTimeStructure; ib_timestamp : PISC_TIMESTAMP);
    function isc_event_block(event_buffer : PPAnsiChar; result_buffer : PPAnsiChar;
				                     id_count : UShort; event_list : array of PAnsiChar): ISC_LONG;
    procedure isc_event_counts(status_vector : PISC_STATUS; buffer_length  : Short;
				                       event_buffer : PAnsiChar; result_buffer : PAnsiChar);
    function isc_free(isc_arg1 : PAnsiChar): ISC_LONG;
    function isc_get_segment(status_vector : PISC_STATUS; blob_handle : PISC_BLOB_HANDLE;
                             actual_seg_length : PUShort; seg_buffer_length : UShort;
				                     seg_buffer : PAnsiChar): ISC_STATUS;
    function isc_put_segment(status_vector : PISC_STATUS; blob_handle : PISC_BLOB_HANDLE;
				                     seg_buffer_len : UShort; seg_buffer : PAnsiChar): ISC_STATUS;

    function isc_interprete(buffer : PAnsiChar; status_vector : PPISC_STATUS): ISC_STATUS;
    function fb_Interpret(buffer: PAnsiChar; BufLen: ULong;
				 status_vector             : PPISC_STATUS): ISC_STATUS; //FB

    function isc_open_blob2(status_vector : PISC_STATUS; db_handle : PISC_DB_HANDLE;
                            tran_handle : PISC_TR_HANDLE; blob_handle : PISC_BLOB_HANDLE;
				                    blob_id : PISC_QUAD; bpb_length : Short; bpb_buffer : PAnsiChar): ISC_STATUS;
    function isc_prepare_transaction2(status_vector : PISC_STATUS; tran_handle : PISC_TR_HANDLE;
                                      msg_length : Short; msg : PAnsiChar): ISC_STATUS;
    function isc_rollback_retaining(status_vector : PISC_STATUS; tran_handle : PISC_TR_HANDLE): ISC_STATUS;
    function isc_rollback_transaction(status_vector : PISC_STATUS; tran_handle : PISC_TR_HANDLE): ISC_STATUS;
    function isc_start_multiple(status_vector : PISC_STATUS; tran_handle : PISC_TR_HANDLE;
                                db_handle_count : Short; teb_vector_address : PISC_TEB): ISC_STATUS;
    function  isc_sqlcode(status_vector : PISC_STATUS): ISC_LONG;
    procedure isc_sql_interprete(sqlcode : Short; buffer : PAnsiChar;
                                 buffer_length : Short);
    function  isc_vax_integer(buffer : PAnsiChar; length : Short): ISC_LONG;

    function  isc_add_user(status_vector : PISC_STATUS; user_sec_data : PUserSecData): ISC_STATUS;
    function  isc_delete_user(status_vector : PISC_STATUS; user_sec_data : PUserSecData): ISC_STATUS;
    function  isc_modify_user(status_vector : PISC_STATUS; user_sec_data : PUserSecData): ISC_STATUS;


    function isc_prepare_transaction(status_vector         : PISC_STATUS;
                                 tran_handle               : PISC_TR_HANDLE): ISC_STATUS;

    function BLOB_put(isc_arg1                  : Ansichar;  isc_arg2                  : PBSTREAM): Int;
    function BLOB_get(isc_arg1                  : PBSTREAM): Int;

   // Service manager functions
   function isc_service_attach (status_vector             : PISC_STATUS;
                                 isc_arg2                  : UShort;
                                 isc_arg3                  : PAnsiChar;
                                 service_handle            : PISC_SVC_HANDLE;
                                 isc_arg5                  : UShort;
                                 isc_arg6                  : PAnsiChar): ISC_STATUS;
    function isc_service_detach(status_vector             : PISC_STATUS;
                                service_handle            : PISC_SVC_HANDLE): ISC_STATUS;
    function isc_service_query  (status_vector             : PISC_STATUS;
                                 service_handle            : PISC_SVC_HANDLE;
                                 recv_handle               : PISC_SVC_HANDLE;
                                 isc_arg4                  : UShort;
                                 isc_arg5                  : PAnsiChar;
                                 isc_arg6                  : UShort;
                                 isc_arg7                  : PAnsiChar;
                                 isc_arg8                  : UShort;
                                 isc_arg9                  : PAnsiChar): ISC_STATUS;
    function isc_service_start (status_vector             : PISC_STATUS;
                                service_handle            : PISC_SVC_HANDLE;
                                recv_handle               : PISC_SVC_HANDLE;
                                isc_arg4                  : UShort;
                                isc_arg5                  : PAnsiChar): ISC_STATUS;
    // Client information functions
    procedure isc_get_client_version(buffer : PAnsiChar);
    function  isc_get_client_major_version: Integer;
    function  isc_get_client_minor_version: Integer;
    function  isc_portable_integer(buffer: PAnsiChar;length: Short): ISC_INT64;

//IB2007
    function isc_dsql_batch_execute_immed(status_vector : PISC_STATUS; db_handle : PISC_DB_HANDLE;
						   tran_handle : PISC_TR_HANDLE; Dialect : UShort; no_of_sql : ulong;
						   statement : PPAnsiChar; rows_affected : PULong) : ISC_STATUS;
    function isc_dsql_batch_execute(status_vector : PISC_STATUS; tran_handle : PISC_TR_HANDLE;
						   stmt_handle : PISC_STMT_HANDLE; Dialect : UShort;
						   insqlda : PXSQLDA; no_of_rows : UShort;
						   batch_vars : PPXSQLVAR; rows_affected : PULong) : ISC_STATUS;

//FB2.5
    function fb_cancel_operation(status_vector : PISC_STATUS; db_handle : PISC_DB_HANDLE;
              option : UShort
    ) : ISC_STATUS;

    function fb_sqlstate(user_status: PISC_STATUS):FIBByteString;

  public
    constructor Create(const aLibName:string);
    destructor  Destroy;override;
    procedure   LoadIBLibrary;
    procedure   FreeIBLibrary;
    function    LibraryLoaded:boolean;
    function    LibraryFilePath:string;
  end;


{ Library Initialization }
procedure LoadIBInstallLibrary;
procedure FreeIBInstallLibrary;
procedure CheckIBInstallLoaded;


function GetClientLibrary(const aLibName:string):IIbClientLibrary;



const
  IBDateDelta = 15018;
{$IFDEF MACOS}
  HINSTANCE_ERROR=0;
{$ENDIF}
const
  describe_bind_info:array[0..11] of Ansichar =(
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

 describe_select_info:array[0..12] of AnsiChar =(
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
  
var
    isc_install_clear_options: Tisc_install_clear_options;
    isc_install_execute: Tisc_install_execute;
    isc_install_get_info: Tisc_install_get_info;
    isc_install_get_message: Tisc_install_get_message;
    isc_install_load_external_text: Tisc_install_load_external_text;
    isc_install_precheck: Tisc_install_precheck;
    isc_install_set_option: Tisc_install_set_option;
    isc_uninstall_execute: Tisc_uninstall_execute;
    isc_uninstall_precheck: Tisc_uninstall_precheck;
    isc_install_unset_option: Tisc_install_unset_option;

implementation
uses FIBConsts;

{$IFDEF LINUX}
const
 HINSTANCE_ERROR=$20;
{$ENDIF}

var
{$IFDEF WINDOWS}
  IBInstallLibrary: THandle;
{$ENDIF}
{$IFDEF MACOS}
  IBInstallLibrary: THandle;
{$ENDIF}

{$IFDEF LINUX}
  IBInstallLibrary : Pointer;
{$ENDIF}

  vClientLibs:TInterfaceList;


var
    vLibAccess: TCriticalSection;


function GetClientLibrary(const aLibName:string):IIbClientLibrary;
var
  I: Integer;
begin
  vLibAccess.Acquire;
  try
    for I := 0 to vClientLibs.Count - 1 do
    if IIbClientLibrary(vClientLibs[i]).LibraryName=aLibName then
    begin
     Result:=IIbClientLibrary(vClientLibs[i])  ;
     if not Result.LibraryLoaded then
       Result.LoadIBLibrary;
     Exit;
    end;
    Result:=TIBClientLibrary.Create(aLibName);
    vClientLibs.Add(Result)
  finally
   vLibAccess.Release
  end;
end;

{$IFDEF WINDOWS}
 {$IFNDEF D_XE2}
procedure InitFPU;
var
  Default8087CW: Word;
begin
  asm
    FSTCW Default8087CW
    OR Default8087CW, 0300h
    FLDCW Default8087CW
  end;
end;
{$ELSE}
procedure InitFPU;
var
  Default8087CW: Word;
  asm
    FSTCW Default8087CW
    OR Default8087CW, 0300h
    FLDCW Default8087CW
  end;


{$ENDIF}
{$ENDIF}


{$DEFINE FP_STDCALL}
function isc_install_clear_options_stub(hOption: POPTIONS_HANDLE):MSG_NO;
{$I pFIBMacroComp.inc}
begin
  raise
    EAPICallException.Create(Format(SCantFindApiProc,['isc_install_clear_options',IB_INSTALL_DLL]));
end;

function isc_install_execute_stub(hOption: OPTIONS_HANDLE;
                             src_dir: TEXT;
                             dest_dir: TEXT;
                             status_func: FP_STATUS;
                             status_data: pointer;
                             error_func: FP_ERROR;
                             error_data: pointer;
                             uninstal_file_name: TEXT):MSG_NO;
{$I pFIBMacroComp.inc}
begin
  raise
    EAPICallException.Create(Format(SCantFindApiProc,['isc_install_execute_stub',IB_INSTALL_DLL]));
end;

function isc_install_get_info_stub(info_type :integer;
                              option :OPT;
                              info_buffer : Pointer;
                              buf_len : Cardinal): MSG_NO;
{$I pFIBMacroComp.inc}
begin
  raise
    EAPICallException.Create(Format(SCantFindApiProc,['isc_install_get',IB_INSTALL_DLL]));
end;

function isc_install_get_message_stub(hOption: OPTIONS_HANDLE;
                                 message_no: MSG_NO;
                                 message_txt: Pointer;
                                 message_len: Cardinal):MSG_NO;
{$I pFIBMacroComp.inc}
begin
  raise
    EAPICallException.Create(Format(SCantFindApiProc,['isc_install_get_message',IB_INSTALL_DLL]));
end;

function isc_install_load_external_text_stub(msg_file_name: TEXT):MSG_NO;
{$I pFIBMacroComp.inc}
begin
  raise
    EAPICallException.Create(Format(SCantFindApiProc,['isc_install_load_external_text',IB_INSTALL_DLL]));
end;

function isc_install_precheck_stub(hOption: OPTIONS_HANDLE;
                              src_dir: TEXT;
                              dest_dir: TEXT):MSG_NO;
{$I pFIBMacroComp.inc}
begin
  raise
    EAPICallException.Create(Format(SCantFindApiProc,['isc_install_precheck',IB_INSTALL_DLL]));
end;

function isc_install_set_option_stub(hOption: POPTIONS_HANDLE;
                                option: OPT):MSG_NO;
{$I pFIBMacroComp.inc}
begin
  raise
    EAPICallException.Create(Format(SCantFindApiProc,['isc_install_set_option',IB_INSTALL_DLL]));
end;

function isc_uninstall_execute_stub(uninstall_file_name: TEXT;
                               status_func: FP_STATUS;
                               status_data: pointer;
                               error_func: FP_ERROR;
                               error_data: pointer):MSG_NO;
{$I pFIBMacroComp.inc}
begin
  raise
    EAPICallException.Create(Format(SCantFindApiProc,['isc_uninstall_execute',IB_INSTALL_DLL]));
end;

function isc_uninstall_precheck_stub(uninstall_file_name: TEXT):MSG_NO;
{$I pFIBMacroComp.inc}
begin
  raise
    EAPICallException.Create(Format(SCantFindApiProc,['isc_uninstall_precheck',IB_INSTALL_DLL]));
end;

function isc_install_unset_option_stub(hOption: POPTIONS_HANDLE;
                                  option: OPT):MSG_NO;
{$I pFIBMacroComp.inc}
begin
  raise
    EAPICallException.Create(Format(SCantFindApiProc,['isc_install_unset_option',IB_INSTALL_DLL]));
end;

{$UNDEF FP_STDCALL}

procedure LoadIBInstallLibrary;
{$IFDEF WINDOWS}
  function GetProcAddr(ProcName: PAnsiChar): Pointer;
  begin
    Result := GetProcAddress(IBInstallLibrary, ProcName);
    if not Assigned(Result) then
     {$IFNDEF D6+}
      RaiseLastWin32Error;
     {$ELSE}
      RaiseLastOSError
     {$ENDIF}
  end;
{$ENDIF}
{$IFDEF LINUX}
  function GetProcAddr(ProcName : PAnsiChar) : Pointer;
  begin
    Result := dlsym(IBInstallLibrary, ProcName);
  end;
{$ENDIF}
{$IFDEF MACOS}
  function GetProcAddr(ProcName: PWideChar): Pointer;
  begin
    Result := GetProcAddress(IBInstallLibrary, ProcName);
    if not Assigned(Result) then
     {$IFNDEF D6+}
      RaiseLastWin32Error;
     {$ELSE}
      RaiseLastOSError
     {$ENDIF}
  end;
{$ENDIF}

begin
{$IFDEF WINDOWS}
  IBInstallLibrary := LoadLibrary(PChar(IB_INSTALL_DLL));
  if (IBInstallLibrary > HINSTANCE_ERROR) then
{$ENDIF}
{$IFDEF MACOS}
  IBInstallLibrary := LoadLibrary(PChar(IB_INSTALL_DLL));
  if (IBInstallLibrary <> 0) then
{$ENDIF}

{$IFDEF LINUX}
  IBInstallLibrary := dlopen(PAnsiChar(IB_INSTALL_DLL), 0);
  if (IBInstallLibrary <> nil) then
{$ENDIF}
  begin
    isc_install_clear_options := GetProcAddr('isc_install_clear_options');
    isc_install_execute := GetProcAddr('isc_install_execute');
    isc_install_get_info := GetProcAddr('isc_install_get_info');
    isc_install_get_message := GetProcAddr('isc_install_get_message');
    isc_install_load_external_text := GetProcAddr('isc_install_load_external_text');
    isc_install_precheck := GetProcAddr('isc_install_precheck');
    isc_install_set_option := GetProcAddr('isc_install_set_option');
    isc_uninstall_execute := GetProcAddr('isc_uninstall_execute');
    isc_uninstall_precheck := GetProcAddr('isc_uninstall_precheck');
    isc_install_unset_option := GetProcAddr('isc_install_unset_option');
  end
  else
  begin
    isc_install_clear_options := isc_install_clear_options_stub;
    isc_install_execute := isc_install_execute_stub;
    isc_install_get_info := isc_install_get_info_stub;
    isc_install_get_message := isc_install_get_message_stub;
    isc_install_load_external_text := isc_install_load_external_text_stub;
    isc_install_precheck := isc_install_precheck_stub;
    isc_install_set_option := isc_install_set_option_stub;
    isc_uninstall_execute := isc_uninstall_execute_stub;
    isc_uninstall_precheck := isc_uninstall_precheck_stub;
    isc_install_unset_option := isc_install_unset_option_stub;
  end;
{$IFDEF WINDOWS}
  InitFPU
{$ENDIF}  
end;

procedure FreeIBInstallLibrary;
begin
{$IFDEF WINDOWS}
  if IBInstallLibrary > HINSTANCE_ERROR then
  begin
    FreeLibrary(IBInstallLibrary);
    IBInstallLibrary := 0;
  end;
{$ENDIF}
{$IFDEF LINUX}
  if IBInstallLibrary <> nil then
  begin
    dlclose(IBInstallLibrary);
    IBInstallLibrary := nil;
  end;
{$ENDIF}
end;


procedure CheckIBInstallLoaded;
begin
{$IFDEF WINDOWS}
  if (IBInstallLibrary <= HINSTANCE_ERROR) then
    LoadIBInstallLibrary;
  if (IBInstallLibrary <= HINSTANCE_ERROR) then
{$ENDIF}
{$IFDEF LINUX}
  if (IBInstallLibrary = nil) then
    LoadIBInstallLibrary;
  if (IBInstallLibrary = nil) then
{$ENDIF}
  raise
    EAPICallException.Create(Format(SCantLoadLibrary,[IB_INSTALL_DLL]));
end;


{ TIBClientLibrary }

function TIBClientLibrary.BLOB_get(isc_arg1: PBSTREAM): Int;
begin
  if Assigned(FBLOB_get) then
   Result:= FBLOB_get(isc_arg1)
  else
   raise
    EAPICallException.Create(Format(SCantFindApiProc,['BLOB_get',FLibraryName]));
end;

function TIBClientLibrary.BLOB_put(isc_arg1: AnsiChar;
  isc_arg2: PBSTREAM): Int;
begin
  if Assigned(FBLOB_put) then
   Result:= FBLOB_put(isc_arg1,isc_arg2)
  else
   raise
    EAPICallException.Create(Format(SCantFindApiProc,['BLOB_put',FLibraryName]));
end;


function TIBClientLibrary.GetIBClientVersion: Integer;
begin
  Result := FIBClientVersion
end;

function  TIBClientLibrary.GetIBClientMinorVersion: Integer;
begin
 Result := FIBClientMinorVersion
end;

function TIBClientLibrary.GetLibName: string;
begin
  Result:=FLibraryName
end;


function TIBClientLibrary.isc_array_get_slice(status_vector: PISC_STATUS;
  db_handle: PISC_DB_HANDLE; trans_handle: PISC_TR_HANDLE;
  array_id: PISC_QUAD; descriptor: PISC_ARRAY_DESC; dest_array: PVoid;
  slice_length: ISC_LONG): ISC_STATUS;
begin
  if Assigned(Fisc_array_get_slice) then
   Result:=
    Fisc_array_get_slice(
     status_vector,  db_handle,trans_handle,array_id,descriptor,dest_array,slice_length
    )
  else
   raise
    EAPICallException.Create(Format(SCantFindApiProc,['isc_array_get_slice',FLibraryName]));
end;

function TIBClientLibrary.isc_array_lookup_bounds(
  status_vector: PISC_STATUS; db_handle: PISC_DB_HANDLE;
  trans_handle: PISC_TR_HANDLE; table_name, column_name: PAnsiChar;
  descriptor: PISC_ARRAY_DESC): ISC_STATUS;
begin
  if Assigned(Fisc_array_lookup_bounds) then
   Result:=
    Fisc_array_lookup_bounds(
     status_vector,  db_handle,trans_handle,  table_name, column_name,descriptor
    )
  else
   raise
    EAPICallException.Create(Format(SCantFindApiProc,['isc_array_lookup_bounds',FLibraryName]));
end;

function TIBClientLibrary.isc_array_lookup_desc(status_vector: PISC_STATUS;
  db_handle: PISC_DB_HANDLE; trans_handle: PISC_TR_HANDLE; table_name,
  column_name: PAnsiChar; descriptor: PISC_ARRAY_DESC): ISC_STATUS;
begin
  if Assigned(Fisc_array_lookup_desc) then
   Result:=
    Fisc_array_lookup_desc(
     status_vector,  db_handle,trans_handle,  table_name, column_name,descriptor
    )
  else
   raise
    EAPICallException.Create(Format(SCantFindApiProc,['isc_array_lookup_desc',FLibraryName]));
end;

function TIBClientLibrary.isc_array_put_slice(status_vector: PISC_STATUS;
  db_handle: PISC_DB_HANDLE; trans_handle: PISC_TR_HANDLE;
  array_id: PISC_QUAD; descriptor: PISC_ARRAY_DESC; source_array: PVoid;
  slice_length: PISC_LONG): ISC_STATUS;
begin
  if Assigned(Fisc_array_put_slice) then
   Result:=
    Fisc_array_put_slice(
     status_vector,  db_handle,trans_handle,  array_id,descriptor,source_array,  slice_length
    )
  else
   raise
    EAPICallException.Create(Format(SCantFindApiProc,['isc_array_put_slice',FLibraryName]));
end;

function TIBClientLibrary.isc_array_set_desc(status_vector: PISC_STATUS;
  table_name, column_name: PAnsiChar; sql_dtype, sql_length,
  sql_dimensions: PShort; descriptor: PISC_ARRAY_DESC): ISC_STATUS;
begin
  if Assigned(Fisc_array_set_desc) then
   Result:=
    Fisc_array_set_desc(
     status_vector, table_name, column_name,sql_dtype, sql_length, sql_dimensions,descriptor
    )
  else
   raise
    EAPICallException.Create(Format(SCantFindApiProc,['isc_array_set_desc',FLibraryName]));
end;

function TIBClientLibrary.isc_attach_database(status_vector: PISC_STATUS;
  db_name_length: Short; db_name: PAnsiChar; db_handle: PISC_DB_HANDLE;
  parm_buffer_length: Short; parm_buffer: PAnsiChar): ISC_STATUS;
begin
  FBusy:=True;
  try
   Result:=
      Fisc_attach_database(status_vector,  db_name_length,db_name,db_handle, parm_buffer_length, parm_buffer)
  finally
   FBusy:=False;
  end
end;


function TIBClientLibrary.isc_blob_info(status_vector: PISC_STATUS;
  blob_handle: PISC_BLOB_HANDLE; item_list_buffer_length: Short;
  item_list_buffer: PAnsiChar; result_buffer_length: Short;
  result_buffer: PAnsiChar): ISC_STATUS;
begin
  FBusy:=True;
  try
     Result:=
      Fisc_blob_info(status_vector,  blob_handle,item_list_buffer_length,
       item_list_buffer,result_buffer_length,
        result_buffer
      )
  finally
   FBusy:=False;
  end
end;

function TIBClientLibrary.isc_blob_lookup_desc(status_vector: PISC_STATUS;
  db_handle: PISC_DB_HANDLE; trans_handle: PISC_TR_HANDLE; table_name,
  column_name: PAnsiChar; descriptor: PISC_BLOB_DESC;
  global: PUChar): ISC_STATUS;
begin
  FBusy:=True;
  try
     Result:=
      Fisc_blob_lookup_desc(status_vector, db_handle,trans_handle,table_name,
       column_name,descriptor,  global
      )
  finally
   FBusy:=False;
  end
end;

function TIBClientLibrary.isc_blob_set_desc(status_vector: PISC_STATUS;
  table_name, column_name: PAnsiChar; subtype, charset, segment_size: Short;
  descriptor: PISC_BLOB_DESC): ISC_STATUS;
begin
  FBusy:=True;
  try
     Result:=
      Fisc_blob_set_desc(
       status_vector, table_name, column_name,subtype, charset, segment_size, descriptor
      )
  finally
   FBusy:=False;
  end
end;

function TIBClientLibrary.isc_cancel_blob(status_vector: PISC_STATUS;
  blob_handle: PISC_BLOB_HANDLE): ISC_STATUS;
begin
  FBusy:=True;
  try
     Result:= Fisc_cancel_blob(status_vector, blob_handle)
  finally
   FBusy:=False;
  end
end;

function TIBClientLibrary.isc_cancel_events(status_vector: PISC_STATUS;
  db_handle: PISC_DB_HANDLE; event_id: PISC_LONG): ISC_STATUS;
begin
  FBusy:=True;
  try
     Result:= Fisc_cancel_events(status_vector, db_handle,event_id)
  finally
   FBusy:=False;
  end
end;


function TIBClientLibrary.isc_que_events(status_vector: PISC_STATUS;
  db_handle: PISC_DB_HANDLE; event_id: PISC_LONG; length: Short;
  event_buffer: PAnsiChar; event_function: TISC_CALLBACK;
  event_function_arg: PVoid): ISC_STATUS;
begin
  FBusy:=True;
  try
     Result:= Fisc_que_events(status_vector, db_handle,event_id,
       length, event_buffer, event_function,  event_function_arg
     )
  finally
   FBusy:=False;
  end
end;

function TIBClientLibrary.isc_wait_for_event  (status_vector: PISC_STATUS;
     db_handle: PISC_DB_HANDLE;length: Short; event_buffer,result_buffer: PAnsiChar): ISC_STATUS;
begin
  FBusy:=True;
  try
     Result:= Fisc_wait_for_event(status_vector, db_handle,
       length, event_buffer, result_buffer
     )
  finally
   FBusy:=False;
  end
end;

function TIBClientLibrary.isc_close_blob(status_vector: PISC_STATUS;
  blob_handle: PISC_BLOB_HANDLE): ISC_STATUS;
begin
  FBusy:=True;
  try
     Result:= Fisc_close_blob(status_vector, blob_handle)
  finally
   FBusy:=False;
  end
end;

function TIBClientLibrary.isc_commit_retaining(status_vector: PISC_STATUS;
  tran_handle: PISC_TR_HANDLE): ISC_STATUS;
begin
    if Assigned(Fisc_commit_retaining) then
    try
     FBusy:=True;
     Result:= Fisc_commit_retaining(status_vector, tran_handle)
    finally
     FBusy:=False;
    end
    else
     raise
      EAPICallException.Create(Format(SCantFindApiProc,['isc_commit_retaining',FLibraryName]));
end;

function TIBClientLibrary.isc_commit_transaction(
  status_vector: PISC_STATUS; tran_handle: PISC_TR_HANDLE): ISC_STATUS;
begin
  FBusy:=True;
  try
     Result:= Fisc_commit_transaction(status_vector, tran_handle)
  finally
   FBusy:=False;
  end

end;



function TIBClientLibrary.isc_transaction_info(status_vector            : PISC_STATUS;
                                 tran_handle               : PISC_TR_HANDLE;
                                 item_list_buffer_length   : Short;
                                 item_list_buffer          : PAnsiChar;
                                 result_buffer_length      : Short;
                                 result_buffer             : PAnsiChar): ISC_STATUS;
begin
  FBusy:=True;
  try
     Result:= Fisc_transaction_info(status_vector, tran_handle,
                                   item_list_buffer_length   ,
                                   item_list_buffer          ,
                                   result_buffer_length      ,
                                   result_buffer
               )
  finally
   FBusy:=False;
  end
end;


function TIBClientLibrary.isc_create_blob2(status_vector: PISC_STATUS;
  db_handle: PISC_DB_HANDLE; tran_handle: PISC_TR_HANDLE;
  blob_handle: PISC_BLOB_HANDLE; blob_id: PISC_QUAD; bpb_length: Short;
  bpb_address: PAnsiChar): ISC_STATUS;
begin
  FBusy:=True;
  try

     Result:= Fisc_create_blob2(
      status_vector,db_handle,tran_handle,  blob_handle,blob_id,bpb_length,  bpb_address
     )
  finally
   FBusy:=False;
  end
end;

function TIBClientLibrary.isc_database_info(status_vector: PISC_STATUS;
  db_handle: PISC_DB_HANDLE; item_list_buffer_length: Short;
  item_list_buffer: PAnsiChar; result_buffer_length: Short;
  result_buffer: PAnsiChar): ISC_STATUS;
begin
  FBusy:=True;
  try
     Result:= Fisc_database_info(
      status_vector,db_handle,item_list_buffer_length,
      item_list_buffer,result_buffer_length, result_buffer
     )
  finally
   FBusy:=False;
  end
end;

procedure TIBClientLibrary.isc_decode_date(ib_date: PISC_QUAD;
  tm_date: PCTimeStructure);
begin
  FBusy:=True;
  try
    if Assigned(Fisc_decode_date) then
     Fisc_decode_date( ib_date,  tm_date)
    else
     raise
      EAPICallException.Create(Format(SCantFindApiProc,['isc_decode_date',FLibraryName]));
  finally
   FBusy:=False;
  end
end;

procedure TIBClientLibrary.isc_encode_date(tm_date: PCTimeStructure;
  ib_date: PISC_QUAD);
begin
  FBusy:=True;
  try
    if Assigned(Fisc_encode_date) then
     Fisc_encode_date(tm_date,ib_date)
    else
     raise
      EAPICallException.Create(Format(SCantFindApiProc,['isc_encode_date',FLibraryName]));
  finally
   FBusy:=False;
  end
end;

procedure TIBClientLibrary.isc_encode_sql_date(tm_date: PCTimeStructure;
  ib_date: PISC_DATE);
begin
  FBusy:=True;
  try
    if Assigned(Fisc_encode_sql_date) then
     Fisc_encode_sql_date(tm_date,ib_date)
    else
     raise
      EAPICallException.Create(Format(SCantFindApiProc,['isc_encode_sql_date',FLibraryName]));
  finally
   FBusy:=False;
  end
end;

procedure TIBClientLibrary.isc_encode_sql_time(tm_date: PCTimeStructure;
  ib_time: PISC_TIME);
begin
  FBusy:=True;
  try
    if Assigned(Fisc_encode_sql_time) then
     Fisc_encode_sql_time(tm_date,ib_time)
    else
     raise
      EAPICallException.Create(Format(SCantFindApiProc,['isc_encode_sql_time',FLibraryName]));
  finally
   FBusy:=False;
  end
end;

procedure TIBClientLibrary.isc_encode_timestamp(tm_date: PCTimeStructure;
  ib_timestamp: PISC_TIMESTAMP);
begin
  FBusy:=True;
  try
    if Assigned(Fisc_encode_timestamp) then
     Fisc_encode_timestamp(tm_date,ib_timestamp)
    else
     raise
      EAPICallException.Create(Format(SCantFindApiProc,['isc_encode_timestamp',FLibraryName]));
  finally
   FBusy:=False;
  end

end;


procedure TIBClientLibrary.isc_decode_sql_date(ib_date: PISC_DATE;
  tm_date: PCTimeStructure);
begin
  FBusy:=True;
  try
    if Assigned(Fisc_decode_sql_date) then
     Fisc_decode_sql_date( ib_date,  tm_date)
    else
     raise
      EAPICallException.Create(Format(SCantFindApiProc,['isc_decode_sql_date',FLibraryName]));
  finally
   FBusy:=False;
  end
end;

procedure TIBClientLibrary.isc_decode_sql_time(ib_time: PISC_TIME;
  tm_date: PCTimeStructure);
begin
  FBusy:=True;
  try
    if Assigned(Fisc_decode_sql_time) then
     Fisc_decode_sql_time( ib_time,  tm_date)
    else
     raise
      EAPICallException.Create(Format(SCantFindApiProc,['isc_decode_sql_time',FLibraryName]));
  finally
   FBusy:=False;
  end
end;

procedure TIBClientLibrary.isc_decode_timestamp(
  ib_timestamp: PISC_TIMESTAMP; tm_date: PCTimeStructure);
begin
  FBusy:=True;
  try
    if Assigned(Fisc_decode_timestamp) then
     Fisc_decode_timestamp( ib_timestamp,  tm_date)
    else
     raise
      EAPICallException.Create(Format(SCantFindApiProc,['isc_decode_timestamp',FLibraryName]));
  finally
   FBusy:=False;
  end

end;


function TIBClientLibrary.isc_add_user(status_vector: PISC_STATUS;
  user_sec_data: PUserSecData): ISC_STATUS;
begin
  FBusy:=True;
  try
     Result:= Fisc_add_user(status_vector,  user_sec_data)
  finally
   FBusy:=False;
  end
end;


function TIBClientLibrary.isc_delete_user(status_vector: PISC_STATUS;
  user_sec_data: PUserSecData): ISC_STATUS;
begin
  FBusy:=True;
  try
     Result:= Fisc_delete_user(status_vector,  user_sec_data)
  finally
   FBusy:=False;
  end
end;

function TIBClientLibrary.isc_modify_user(status_vector: PISC_STATUS;
  user_sec_data: PUserSecData): ISC_STATUS;
begin
  FBusy:=True;
  try
     Result:= Fisc_modify_user(status_vector,  user_sec_data)
  finally
   FBusy:=False;
  end
end;

function TIBClientLibrary.isc_detach_database(status_vector: PISC_STATUS;
  db_handle: PISC_DB_HANDLE): ISC_STATUS;
begin
  FBusy:=True;
  try
     Result:= Fisc_detach_database(status_vector,  db_handle)
  finally
   FBusy:=False;
  end
end;

function TIBClientLibrary.isc_drop_database(status_vector: PISC_STATUS;
  db_handle: PISC_DB_HANDLE): ISC_STATUS;
begin
  FBusy:=True;
  try
     Result:= Fisc_drop_database(status_vector,  db_handle)
  finally
   FBusy:=False;
  end
end;

function TIBClientLibrary.isc_dsql_alloc_statement2(
const  status_vector: PISC_STATUS; db_handle: PISC_DB_HANDLE;
  stmt_handle: PISC_STMT_HANDLE): ISC_STATUS;
begin
  FBusy:=True;
  try
   Result:= Fisc_dsql_alloc_statement2(status_vector,  db_handle,stmt_handle)
  finally
   FBusy:=False;
  end
end;

//IB2007
function TIBClientLibrary.isc_dsql_batch_execute(status_vector: PISC_STATUS;
  tran_handle: PISC_TR_HANDLE; stmt_handle: PISC_STMT_HANDLE; Dialect: UShort;
  insqlda: PXSQLDA; no_of_rows: UShort; batch_vars: PPXSQLVAR;
  rows_affected: PULong): ISC_STATUS;
begin
   if Assigned(Fisc_dsql_batch_execute) then
   try
    FBusy:=True;
    Result := Fisc_dsql_batch_execute(status_vector, tran_handle, stmt_handle, Dialect,
      insqlda, no_of_rows, batch_vars, rows_affected)
   finally
    FBusy:=False;
   end
   else
     raise
      EAPICallException.Create(Format(SCantFindApiProc,['isc_dsql_batch_execute',FLibraryName]));
end;

function TIBClientLibrary.isc_dsql_batch_execute_immed(
  status_vector: PISC_STATUS; db_handle: PISC_DB_HANDLE;
  tran_handle: PISC_TR_HANDLE; Dialect: UShort; no_of_sql: ulong;
  statement: PPAnsiChar; rows_affected: PULong): ISC_STATUS;
begin
   if Assigned(Fisc_dsql_batch_execute_immed) then
   try
     FBusy:=True;
     Result := Fisc_dsql_batch_execute_immed(status_vector, db_handle,
        tran_handle, Dialect, no_of_sql, statement, rows_affected)
    finally
     FBusy:=False;
    end
    else
     raise
      EAPICallException.Create(Format(SCantFindApiProc,['isc_dsql_batch_execute_immed',FLibraryName]));
end;
//End //IB2007

function TIBClientLibrary.isc_dsql_describe(status_vector: PISC_STATUS;
  stmt_handle: PISC_STMT_HANDLE; dialect: UShort;
  xsqlda: PXSQLDA): ISC_STATUS;
begin
  FBusy:=True;
  try
    Result:= Fisc_dsql_describe(status_vector,  stmt_handle,dialect,xsqlda)
  finally
    FBusy:=False;
  end
end;

function TIBClientLibrary.isc_dsql_describe_bind(
  status_vector: PISC_STATUS; stmt_handle: PISC_STMT_HANDLE;
  dialect: UShort; xsqlda: PXSQLDA): ISC_STATUS;
begin
  FBusy:=True;
  try
    Result:= Fisc_dsql_describe_bind(status_vector,  stmt_handle,dialect,xsqlda)
  finally
    FBusy:=False;
  end
end;

function TIBClientLibrary.isc_dsql_execute(status_vector: PISC_STATUS;
  tran_handle: PISC_TR_HANDLE; stmt_handle: PISC_STMT_HANDLE;
  dialect: UShort; xsqlda: PXSQLDA): ISC_STATUS;
begin
  FBusy:=True;
  try
    Result:= Fisc_dsql_execute(status_vector, tran_handle, stmt_handle,dialect,xsqlda)
  finally
    FBusy:=False;
  end
end;

function TIBClientLibrary.isc_dsql_execute_immediate(
  status_vector: PISC_STATUS; db_handle: PISC_DB_HANDLE;
  tran_handle: PISC_TR_HANDLE; length: UShort; statement: PAnsiChar;
  dialect: UShort; xsqlda: PXSQLDA): ISC_STATUS;
begin
  FBusy:=True;
  try
    Result:=
     Fisc_dsql_execute_immediate(status_vector, db_handle,tran_handle, length,statement,dialect,xsqlda)
  finally
    FBusy:=False;
  end
end;


function TIBClientLibrary.isc_dsql_exec_immed2(status_vector: PISC_STATUS;
 db_handle: PISC_DB_HANDLE; tran_handle: PISC_TR_HANDLE;
 length: UShort;statement: PAnsiChar;dialect: UShort;
 in_xsqlda,out_xsqlda: PXSQLDA): ISC_STATUS;
begin
  FBusy:=True;
  try
    Result:=
     Fisc_dsql_exec_immed2(status_vector, db_handle,tran_handle, length,statement,dialect,in_xsqlda,out_xsqlda)
  finally
    FBusy:=False;
  end
end;


function TIBClientLibrary.isc_dsql_execute2(status_vector: PISC_STATUS;
  tran_handle: PISC_TR_HANDLE; stmt_handle: PISC_STMT_HANDLE;
  dialect: UShort; in_xsqlda, out_xsqlda: PXSQLDA): ISC_STATUS;
begin
  FBusy:=True;
  try
    Result:=
     Fisc_dsql_execute2(status_vector, tran_handle, stmt_handle,dialect,in_xsqlda, out_xsqlda)
  finally
    FBusy:=False;
  end
end;

function TIBClientLibrary.isc_dsql_fetch(status_vector: PISC_STATUS;
  stmt_handle: PISC_STMT_HANDLE; dialect: UShort;
  xsqlda: PXSQLDA): ISC_STATUS;
begin
  FBusy:=True;
  try
   Result:=
    Fisc_dsql_fetch(status_vector, stmt_handle,dialect,xsqlda);
  finally
    FBusy:=False;
  end
end;

function TIBClientLibrary.isc_dsql_free_statement(
  status_vector: PISC_STATUS; stmt_handle: PISC_STMT_HANDLE;
  options: UShort): ISC_STATUS;
begin
  FBusy:=True;
  try
   Result:=
    Fisc_dsql_free_statement(status_vector, stmt_handle,options)
  finally
    FBusy:=False;
  end
end;

function TIBClientLibrary.isc_dsql_prepare(status_vector: PISC_STATUS;
  tran_handle: PISC_TR_HANDLE; stmt_handle: PISC_STMT_HANDLE;
  length: UShort; statement: PAnsiChar; dialect: UShort;
  xsqlda: PXSQLDA): ISC_STATUS;
begin
  FBusy:=True;
  try
   Result:=
    Fisc_dsql_prepare(status_vector, tran_handle,stmt_handle,
     length,statement,dialect, xsqlda
    )
  finally
    FBusy:=False;
  end
end;

function TIBClientLibrary.isc_dsql_set_cursor_name(
  status_vector: PISC_STATUS; stmt_handle: PISC_STMT_HANDLE;
  cursor_name: PAnsiChar; _type: UShort): ISC_STATUS;
begin
  FBusy:=True;
  try
   Result:=
    Fisc_dsql_set_cursor_name(status_vector, stmt_handle, cursor_name,_type)
  finally
    FBusy:=False;
  end
end;

function TIBClientLibrary.isc_dsql_sql_info(status_vector: PISC_STATUS;
  stmt_handle: PISC_STMT_HANDLE; item_length: Short; items: PAnsiChar;
  buffer_length: Short; buffer: PAnsiChar): ISC_STATUS;
begin
  FBusy:=True;
  try
   Result:=
    Fisc_dsql_sql_info(status_vector, stmt_handle,item_length,items,
     buffer_length,buffer)
  finally
    FBusy:=False;
  end
end;


type
  Tsib_event_block = function (EventBuffer, ResultBuffer: PPAnsiChar; IDCount: UShort;
    Event1, Event2, Event3, Event4, Event5, Event6, Event7, Event8, Event9,
    Event10, Event11, Event12, Event13, Event14, Event15: PAnsiChar): ISC_LONG; cdecl;

function TIBClientLibrary.isc_event_block(event_buffer,
  result_buffer: PPAnsiChar; id_count: UShort;
  event_list: array of PAnsiChar): ISC_LONG;
begin
  FBusy:=True;
  try
   Result:=
    Tsib_event_block(Fisc_event_block)(event_buffer, result_buffer,id_count,
     event_list[0], event_list[1], event_list[2], event_list[3],
     event_list[4], event_list[5], event_list[6], event_list[7], event_list[8],
     event_list[9], event_list[10], event_list[11], event_list[12],
     event_list[13], event_list[14]
    )
  finally
    FBusy:=False;
  end

end;

procedure TIBClientLibrary.isc_event_counts(status_vector: PISC_STATUS;
  buffer_length: Short; event_buffer, result_buffer: PAnsiChar);
begin
  FBusy:=True;
  try
    Fisc_event_counts(status_vector, buffer_length,event_buffer, result_buffer)
  finally
    FBusy:=False;
  end
end;

function TIBClientLibrary.isc_free(isc_arg1: PAnsiChar): ISC_LONG;
begin
  FBusy:=True;
  try
    Result:=Fisc_free(isc_arg1)
  finally
    FBusy:=False;
  end
end;

function TIBClientLibrary.isc_get_client_major_version: Integer;
begin
  if Assigned(Fisc_get_client_major_version) then
  try
    FBusy:=True;
    Result:=Fisc_get_client_major_version
  finally
    FBusy:=False;
  end
  else
   raise
    EAPICallException.Create(Format(SCantFindApiProc,['isc_get_client_major_version',FLibraryName]));
end;

function TIBClientLibrary.isc_get_client_minor_version: Integer;
begin
  if Assigned(Fisc_get_client_minor_version) then
  try
    FBusy:=True;
    Result:=Fisc_get_client_minor_version
  finally
    FBusy:=False;
  end
  else
   raise
    EAPICallException.Create(Format(SCantFindApiProc,['isc_get_client_minor_version',FLibraryName]));
end;

procedure TIBClientLibrary.isc_get_client_version(buffer: PAnsiChar);
begin

  if Assigned(Fisc_get_client_version) then
  try
    FBusy:=True;
    Fisc_get_client_version(buffer)
  finally
    FBusy:=False;
  end
  else
   raise
    EAPICallException.Create(Format(SCantFindApiProc,['isc_get_client_version',FLibraryName]));
end;

function TIBClientLibrary.isc_get_segment(status_vector: PISC_STATUS;
  blob_handle: PISC_BLOB_HANDLE; actual_seg_length: PUShort;
  seg_buffer_length: UShort; seg_buffer: PAnsiChar): ISC_STATUS;
begin
  FBusy:=True;
  try
   Result:=
    Fisc_get_segment(
     status_vector,  blob_handle,actual_seg_length,  seg_buffer_length,seg_buffer
    )
  finally
    FBusy:=False;
  end
end;


function TIBClientLibrary.isc_put_segment(status_vector: PISC_STATUS;
  blob_handle: PISC_BLOB_HANDLE; seg_buffer_len: UShort;
  seg_buffer: PAnsiChar): ISC_STATUS;
begin
  FBusy:=True;
  try
   Result:=
    Fisc_put_segment(
     status_vector,  blob_handle, seg_buffer_len,seg_buffer
    )
  finally
    FBusy:=False;
  end
end;

function TIBClientLibrary.isc_interprete(buffer: PAnsiChar;
  status_vector: PPISC_STATUS): ISC_STATUS;
begin
  FBusy:=True;
  try
   Result:= Fisc_interprete(buffer,  status_vector)
  finally
    FBusy:=False;
  end
end;


function TIBClientLibrary.fb_Interpret(buffer: PAnsiChar; BufLen: ULong;
				 status_vector             : PPISC_STATUS): ISC_STATUS;
begin
  if not Assigned(Ffb_interpret) then
   Result:=isc_interprete(buffer,status_vector)
  else
  begin
    FBusy:=True;
    try
     Result:= Ffb_interpret(buffer, BufLen ,status_vector)
    finally
      FBusy:=False;
    end
  end
end;


function TIBClientLibrary.isc_open_blob2(status_vector: PISC_STATUS;
  db_handle: PISC_DB_HANDLE; tran_handle: PISC_TR_HANDLE;
  blob_handle: PISC_BLOB_HANDLE; blob_id: PISC_QUAD; bpb_length: Short;
  bpb_buffer: PAnsiChar): ISC_STATUS;
begin
  FBusy:=True;
  try
   Result:=
    Fisc_open_blob2(
     status_vector, db_handle,tran_handle,  blob_handle,blob_id,bpb_length, bpb_buffer
    )
  finally
    FBusy:=False;
  end
end;

function TIBClientLibrary.isc_prepare_transaction(
  status_vector: PISC_STATUS; tran_handle: PISC_TR_HANDLE): ISC_STATUS;
begin
  FBusy:=True;
  try
   Result:= Fisc_prepare_transaction(status_vector, tran_handle)
  finally
    FBusy:=False;
  end
end;

function TIBClientLibrary.isc_prepare_transaction2(
  status_vector: PISC_STATUS; tran_handle: PISC_TR_HANDLE;
  msg_length: Short; msg: PAnsiChar): ISC_STATUS;
begin
  FBusy:=True;
  try
   Result:= Fisc_prepare_transaction2(status_vector, tran_handle,msg_length,msg)
  finally
    FBusy:=False;
  end
end;



function TIBClientLibrary.isc_rollback_retaining(
  status_vector: PISC_STATUS; tran_handle: PISC_TR_HANDLE): ISC_STATUS;
begin
  if Assigned(Fisc_rollback_retaining) then
  try
   FBusy:=True;
   Result:= Fisc_rollback_retaining(status_vector, tran_handle)
  finally
    FBusy:=False;
  end
  else
   raise
    EAPICallException.Create(Format(SCantFindApiProc,['isc_rollback_retaining',FLibraryName]));
end;

function TIBClientLibrary.isc_rollback_transaction(
  status_vector: PISC_STATUS; tran_handle: PISC_TR_HANDLE): ISC_STATUS;
begin
  FBusy:=True;
  try
    Result:= Fisc_rollback_transaction(status_vector, tran_handle)
  finally
    FBusy:=False;
  end
end;


// Services

function TIBClientLibrary.isc_service_attach(status_vector: PISC_STATUS;
  isc_arg2: UShort; isc_arg3: PAnsiChar; service_handle: PISC_SVC_HANDLE;
  isc_arg5: UShort; isc_arg6: PAnsiChar): ISC_STATUS;
begin
  if Assigned(Fisc_service_attach) then
  try
   FBusy:=True;
   Result:= Fisc_service_attach(status_vector,
     isc_arg2,isc_arg3,service_handle, isc_arg5,isc_arg6
   )
  finally
    FBusy:=False;
  end
  else
   raise
    EAPICallException.Create(Format(SCantFindApiProc,['isc_service_attach',FLibraryName]));
end;

function TIBClientLibrary.isc_service_detach(status_vector: PISC_STATUS;
  service_handle: PISC_SVC_HANDLE): ISC_STATUS;
begin
  if Assigned(Fisc_service_detach) then
  try
   FBusy:=True;
   Result:= Fisc_service_detach(status_vector, service_handle )
  finally
    FBusy:=False;
  end
  else
   raise
    EAPICallException.Create(Format(SCantFindApiProc,['isc_service_detach',FLibraryName]));
end;

function TIBClientLibrary.isc_service_query(status_vector: PISC_STATUS;
  service_handle, recv_handle: PISC_SVC_HANDLE; isc_arg4: UShort;
  isc_arg5: PAnsiChar; isc_arg6: UShort; isc_arg7: PAnsiChar; isc_arg8: UShort;
  isc_arg9: PAnsiChar): ISC_STATUS;
begin
  if Assigned(Fisc_service_query) then
  try
   FBusy:=True;
   Result:= Fisc_service_query(status_vector, service_handle ,
    recv_handle,isc_arg4, isc_arg5,isc_arg6,isc_arg7,isc_arg8,  isc_arg9
   )
  finally
    FBusy:=False;
  end
  else
   raise
    EAPICallException.Create(Format(SCantFindApiProc,['isc_service_query',FLibraryName]));
end;

function TIBClientLibrary.isc_service_start(status_vector: PISC_STATUS;
  service_handle, recv_handle: PISC_SVC_HANDLE; isc_arg4: UShort;
  isc_arg5: PAnsiChar): ISC_STATUS;
begin
  if Assigned(Fisc_service_start) then
  try
   FBusy:=True;
   Result:= Fisc_service_start(status_vector, service_handle ,
    recv_handle,isc_arg4, isc_arg5
   )
  finally
    FBusy:=False;
  end
  else
   raise
    EAPICallException.Create(Format(SCantFindApiProc,['isc_service_start',FLibraryName]));
end;

procedure TIBClientLibrary.isc_sql_interprete(sqlcode: Short;
  buffer: PAnsiChar; buffer_length: Short);
begin
  FBusy:=True;
  try
   Fisc_sql_interprete(sqlcode, buffer,buffer_length)
  finally
    FBusy:=False;
  end
end;

function TIBClientLibrary.isc_sqlcode(
  status_vector: PISC_STATUS): ISC_LONG;
begin
  FBusy:=True;
  try
   Result:= Fisc_sqlcode(status_vector)
  finally
    FBusy:=False;
  end
end;

//procedure TIBClientLibrary.fb_sqlstate(buffer: PAnsiChar; const user_status: PISC_STATUS);

function TIBClientLibrary.fb_sqlstate(user_status: PISC_STATUS):FIBByteString;
var
  buffer: array[0..FB_sqlstate_bufSize-1] of AnsiChar;
begin
  if Assigned(Ffb_sqlstate) then
  try
   FBusy:=True;
   FillChar(buffer,FB_sqlstate_bufSize,0);
   Ffb_sqlstate(@buffer, user_status);
   Result:=buffer
  finally
   FBusy:=False;
  end;
end;

function TIBClientLibrary.isc_start_multiple(status_vector: PISC_STATUS;
  tran_handle: PISC_TR_HANDLE; db_handle_count: Short;
  teb_vector_address: PISC_TEB): ISC_STATUS;
begin
  FBusy:=True;
  try
   Result:= Fisc_start_multiple(status_vector,
    tran_handle,db_handle_count, teb_vector_address
   )
  finally
    FBusy:=False;
  end
end;

function TIBClientLibrary.isc_vax_integer(buffer: PAnsiChar;
  length: Short): ISC_LONG;
begin
  FBusy:=True;
  try
   Result:= Fisc_vax_integer(buffer, length)
  finally
    FBusy:=False;
  end
end;

function TIBClientLibrary.isc_portable_integer(buffer: PAnsiChar;
  length: Short): ISC_INT64;
begin
  if Assigned(Fisc_portable_integer) then
  try
   FBusy:=True;
   Result:= Fisc_portable_integer(buffer, length);
  finally
    FBusy:=False;
  end
  else
   raise
    EAPICallException.Create(Format(SCantFindApiProc,['isc_portable_integer',FLibraryName]));
end;

constructor TIBClientLibrary.Create(const aLibName: string);
begin
 inherited Create;
 FLibraryName:=aLibName;
 LoadIBLibrary;
end;

destructor TIBClientLibrary.Destroy;
begin
 FreeIBLibrary
end;

procedure TIBClientLibrary.LoadIBLibrary;

  function TryGetProcAddr(ProcName: String): Pointer;
  begin
    Result := GetProcAddress(FLibraryHandle, PChar(ProcName));
  end;


  function GetProcAddr(ProcName: String): Pointer;
  begin
    Result := GetProcAddress(FLibraryHandle, PChar(ProcName));
    if not Assigned(Result) then
     {$IFNDEF D6+}
      RaiseLastWin32Error;
     {$ELSE}
      RaiseLastOSError
     {$ENDIF}

  end;


begin
  FLibraryHandle := LoadLibrary(PChar(FLibraryName));
  if (FLibraryHandle > HINSTANCE_ERROR) then
  begin
    FBLOB_get    := GetProcAddr('BLOB_get');
    FBLOB_put    := GetProcAddr('BLOB_put');
    Fisc_sqlcode := GetProcAddr('isc_sqlcode');
    Fisc_sql_interprete := GetProcAddr('isc_sql_interprete');
    Fisc_interprete := GetProcAddr('isc_interprete');
    Ffb_interpret   := TryGetProcAddr('fb_interpret');    
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
    Fisc_dsql_exec_immed2:= GetProcAddr('isc_dsql_exec_immed2');
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

    Fisc_array_lookup_bounds :=GetProcAddr('isc_array_lookup_bounds');

    Fisc_array_get_slice     :=GetProcAddr('isc_array_get_slice');
    Fisc_array_put_slice     :=GetProcAddr('isc_array_put_slice');
    Fisc_wait_for_event      :=GetProcAddr('isc_wait_for_event');
    Fisc_transaction_info    :=GetProcAddr('isc_transaction_info');
    Fisc_prepare_transaction:=GetProcAddr('isc_prepare_transaction');
    Fisc_prepare_transaction2:=GetProcAddr('isc_prepare_transaction2');


    Fisc_rollback_retaining := TryGetProcAddr('isc_rollback_retaining');
    if Assigned(Fisc_rollback_retaining) then
    begin
      FIBClientVersion := 6;
      FIBClientMinorVersion:=0;
      Fisc_service_attach      := GetProcAddr('isc_service_attach');
      Fisc_service_detach      := GetProcAddr('isc_service_detach');
      Fisc_service_query       := GetProcAddr('isc_service_query');
      Fisc_service_start       := GetProcAddr('isc_service_start');
      Fisc_decode_sql_date     := GetProcAddr('isc_decode_sql_date');
      Fisc_decode_sql_time     := GetProcAddr('isc_decode_sql_time');
      Fisc_decode_timestamp    := GetProcAddr('isc_decode_timestamp');
      Fisc_encode_sql_date     := GetProcAddr('isc_encode_sql_date');
      Fisc_encode_sql_time     := GetProcAddr('isc_encode_sql_time');
      Fisc_encode_timestamp    := GetProcAddr('isc_encode_timestamp');
      Fisc_portable_integer    := GetProcAddr('isc_portable_integer');
    end
    else
    begin
      FIBClientVersion := 5;
      FIBClientMinorVersion:=0;
    end;

    Ffb_sqlstate:=TryGetProcAddr('fb_sqlstate');
  end
  else
  begin
    // Can't load Library
   {$IFDEF D7+}
    RaiseLastOSError
   {$ELSE}
    raise
     EAPICallException.Create(Format(SCantLoadLibrary,[FLibraryName]));
   {$ENDIF} 
  end;

  Fisc_get_client_version := TryGetProcAddr('isc_get_client_version'); {do not localize}
  if Assigned(Fisc_get_client_version) then
  begin
    Fisc_get_client_major_version := GetProcAddr('isc_get_client_major_version'); {do not localize}
    Fisc_get_client_minor_version := GetProcAddr('isc_get_client_minor_version'); {do not localize}
    FIBClientVersion := Fisc_get_client_major_version;
    FIBClientMinorVersion:=Fisc_get_client_minor_version;
//IB2007
    Fisc_dsql_batch_execute_immed := TryGetProcAddr('isc_dsql_batch_execute_immed');
    Fisc_dsql_batch_execute := TryGetProcAddr('isc_dsql_batch_execute');
//FB2.5
    Ffb_cancel_operation    :=TryGetProcAddr('fb_cancel_operation')
  end
  else
  begin
    FIBClientMinorVersion:=0;
  end;

{$IFDEF WINDOWS}
  InitFPU
{$ENDIF}

end;

procedure   TIBClientLibrary.FreeIBLibrary;
begin
 {$IFDEF WINDOWS}
  if (FLibraryHandle > HINSTANCE_ERROR) then
  begin
    FreeLibrary(FLibraryHandle);
    FLibraryHandle:=HINSTANCE_ERROR
  end;
 {$ENDIF}
 {$IFDEF LINUX}
  if (FLibraryHandle <> nil) then
  begin
     dlclose(FLibraryHandle);
     FLibraryHandle:=nil
  end;
 {$ENDIF}
end;

function    TIBClientLibrary.LibraryLoaded:boolean;
begin
 {$IFDEF WINDOWS}
     Result:= FLibraryHandle>HINSTANCE_ERROR
 {$ENDIF}
 {$IFDEF MACOS}
     Result:= FLibraryHandle>HINSTANCE_ERROR
 {$ENDIF}
 {$IFDEF LINUX}
     Result:= FLibraryHandle <> nil
 {$ENDIF}

end;

function TIBClientLibrary.fb_cancel_operation(status_vector: PISC_STATUS;
  db_handle: PISC_DB_HANDLE; option: UShort): ISC_STATUS;
begin
  if Assigned(Ffb_cancel_operation) then
   Result:=
    Ffb_cancel_operation(
     status_vector,  db_handle,option
    )
  else
   raise
    EAPICallException.Create(Format(SCantFindApiProc,['fb_cancel_operation',FLibraryName]));
end;

function TIBClientLibrary.GetBusy: boolean;
begin
  Result:=FBusy
end;

function  TIBClientLibrary.LibraryFilePath:string;
var
 Buffer: array[0..1024] of Char;
begin
   GetModuleFileName(FLibraryHandle,Buffer,SizeOf(Buffer));
   Result:=Buffer
end;

initialization
 vClientLibs:=TInterfaceList.Create;
 vLibAccess:=TCriticalSection.Create;
finalization
 vClientLibs.Free;
 FreeAndNil(vLibAccess);
end.
