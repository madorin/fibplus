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


unit IB_InstallHeader;


interface

{$I FIBPlus.inc}
uses

SysUtils, Classes;

{$DEFINE FP_STDCALL}
{ InterBase Install API interface }
type
  OPTIONS_HANDLE = integer;
  POPTIONS_HANDLE = ^OPTIONS_HANDLE;
  MSG_NO = longint;
  OPT = longint;
  TEXT = PChar;
  FP_ERROR = function(IscCode: MSG_NO; UserContext: Pointer;
                             const ActionDescription : TEXT): Integer;
  {$I pFIBMacroComp.inc}
  FP_STATUS = function(Status: Integer; UserContext: Pointer;
                              const ActionDescription: TEXT): Integer;
                                {$I pFIBMacroComp.inc}

const

   IB_INSTALL_DLL = 'ibinstall.dll';

  { These are the values the FP_ERROR routine can return. }
  isc_install_fp_retry    = -1;
  isc_install_fp_continue =  0;
  isc_install_fp_abort    =  1;

   { isc_install_get_info info_types }
   isc_install_info_destination  =  1;
   isc_install_info_opspace  = 2     ;
   isc_install_info_opname =  3      ;
   isc_install_info_opdescription  = 4;


  ISC_INSTALL_MAX_MESSAGE_LEN   = 300;
  ISC_INSTALL_MAX_MESSAGES      = 200;
  ISC_INSTALL_MAX_PATH          = 256;

  { Basic Components used to install InterBase }
  INTERBASE                     = 1000;
  IB_SERVER                     = 1001;
  IB_CLIENT                     = 1002;

  IB_CMD_TOOLS                  = 1003;
  IB_CMD_TOOLS_DB_MGMT          = 1004;
  IB_CMD_TOOLS_USR_MGMT         = 1005;
  IB_CMD_TOOLS_DB_QUERY         = 1006;

  IB_GUI_TOOLS                  = 1007;

  IB_DOC                        = 1011;
  IB_EXAMPLES                   = 1012;
  IB_EXAMPLE_API                = 1013;
  IB_EXAMPLE_DB                 = 1014;
  IB_DEV                        = 1015;

  IB_CONNECTIVITY_SERVER        = 1100;
  IB_CONNECTIVITY               = 1101;
  IB_ODBC_CLIENT                = 1102;
  IB_JDBC_CLIENT                = 1103;
  IB_OLEDB_CLIENT               = 1104;

  { Error and warning codes }
  isc_install_optlist_empty           = -1;
  isc_install_actlist_empty           = -2;
  isc_install_fp_copy_delayed         = -3;
  isc_install_fp_delete_delayed       = -4;
  isc_install_option_not_found        = -5;
  isc_install_msg_version             = -6;
  isc_install_cant_load_msg           = -7;
  isc_install_invalid_msg             = -8;
  isc_install_invalid_tbl             = -9;
  isc_install_cant_create_msg         = -10;
  isc_install_handle_not_allocated    = -11;
  isc_install_odbc_comp_notfound      = -12;
  isc_install_cant_delete             = -13;
  isc_install_cant_rmdir              = -14;
  isc_install_key_nonempty            = -15;

  isc_install_success                 = 0;

  { File and directory related errors }
  isc_install_file_error              = isc_install_success;
  isc_install_path_not_valid          = isc_install_file_error+1;
  isc_install_path_not_exists         = isc_install_file_error+2;
  isc_install_cant_write              = isc_install_file_error+3;
  isc_install_type_unknown            = isc_install_file_error+4;
  isc_install_cant_move_file          = isc_install_file_error+5;
  isc_install_device_not_valid        = isc_install_file_error+6;
  isc_install_data_truncated          = isc_install_file_error+7;
  isc_install_cant_get_temp           = isc_install_file_error+8;
  isc_install_no_file                 = isc_install_file_error+9;
  isc_install_cant_load_lib           = isc_install_file_error+10;
  isc_install_cant_lookup_lib         = isc_install_file_error+11;
  isc_install_file_exists             = isc_install_file_error+12;
  isc_install_cant_open_log           = isc_install_file_error+13;
  isc_install_write_error             = isc_install_file_error+14;
  isc_install_read_error              = isc_install_file_error+15;
  isc_install_invalid_log             = isc_install_file_error+16;
  isc_install_cant_read               = isc_install_file_error+17;
  isc_install_no_diskspace            = isc_install_file_error+18;
  isc_install_cant_create_dir         = isc_install_file_error+19;
  isc_install_msg_syntax              = isc_install_file_error+20;
  isc_install_fp_delete_error         = isc_install_file_error+21;
  isc_install_fp_rename_error         = isc_install_file_error+22;
  isc_install_fp_copy_error           = isc_install_file_error+23;

  { Precheck related errors }
  isc_install_precheck_error          = isc_install_file_error+24;
  isc_install_system_not_supported    = isc_install_precheck_error;
  isc_install_server_running          = isc_install_precheck_error+1;
  isc_install_classic_found           = isc_install_precheck_error+2;
  isc_install_no_privileges           = isc_install_precheck_error+3;
  isc_install_cant_get_free_space     = isc_install_precheck_error+4;
  isc_install_guardian_running        = isc_install_precheck_error+5;
  isc_install_invalid_option          = isc_install_precheck_error+6;
  isc_install_invalid_handle          = isc_install_precheck_error+7;
  isc_install_message_not_found       = isc_install_precheck_error+8;

  { TCP/IP services related }
  isc_install_ip_error                = isc_install_precheck_error+9;
  isc_install_no_stack                = isc_install_ip_error;
  isc_install_cant_add_service        = isc_install_ip_error+1;
  isc_install_invalid_port            = isc_install_ip_error+2;
  isc_install_invalid_service         = isc_install_ip_error+3;
  isc_install_no_proto                = isc_install_ip_error+4;
  isc_install_no_services_entry       = isc_install_ip_error+5;
  isc_install_sock_error              = isc_install_ip_error+6;
  isc_install_conversion_error        = isc_install_ip_error+7;


  { Operations errors }
  isc_install_op_error                = isc_install_ip_error+8;
  isc_install_cant_copy               = isc_install_op_error;
  isc_install_no_mem                  = isc_install_op_error+1;
  isc_install_queue_failed            = isc_install_op_error+2;
  isc_install_invalid_param           = isc_install_op_error+3;
  isc_install_fp_error_exception      = isc_install_op_error+4;
  isc_install_fp_status_exception     = isc_install_op_error+5;
  isc_install_user_aborted            = isc_install_op_error+6;

  { Registry related errors }
  isc_install_reg_error               = isc_install_op_error+7;
  isc_install_key_exists              = isc_install_reg_error;
  isc_install_cant_create_key         = isc_install_reg_error+1;
  isc_install_cant_set_value          = isc_install_reg_error+2;
  isc_install_cant_open_key           = isc_install_reg_error+3;
  isc_install_cant_delete_key         = isc_install_reg_error+4;
  isc_install_cant_query_key          = isc_install_reg_error+5;
  isc_install_cant_delete_value       = isc_install_reg_error+6;

  { OS services related errors }
  isc_install_serv_error              = isc_install_reg_error+7;
  isc_install_service_existed         = isc_install_serv_error;
  isc_install_cant_create_service     = isc_install_serv_error+1;
  isc_install_cant_open_service       = isc_install_serv_error+2;
  isc_install_cant_query_service      = isc_install_serv_error+3;
  isc_install_service_running         = isc_install_serv_error+4;
  isc_install_cant_delete_service     = isc_install_serv_error+5;
  isc_install_cant_open_manager       = isc_install_serv_error+6;
  isc_install_system_error            = isc_install_serv_error+7;
  isc_install_com_regfail             = isc_install_serv_error+8;
  isc_install_dcom_required           = isc_install_serv_error+9;

  { ODBC installation errors }
  isc_install_odbc_error              = isc_install_serv_error+10;
  isc_install_odbc_general            = isc_install_odbc_error;
  isc_install_core_version            = isc_install_odbc_error+1;
  isc_install_drv_version             = isc_install_odbc_error+2;
  isc_install_tran_version            = isc_install_odbc_error+3;

type
Tisc_install_clear_options = function(hOption: POPTIONS_HANDLE):MSG_NO;
  {$I pFIBMacroComp.inc}

Tisc_install_execute = function (hOption: OPTIONS_HANDLE;
                                 src_dir: TEXT;
                                 dest_dir: TEXT;
                                 status_func: FP_STATUS;
                                 status_data: pointer;
                                 error_func: FP_ERROR;
                                 error_data: pointer;
                                 uninstal_file_name: TEXT):MSG_NO;
  {$I pFIBMacroComp.inc}

Tisc_install_get_info = function (info_type :integer;
                                  option :OPT;
                                  info_buffer : Pointer;
                                  buf_len : Cardinal): MSG_NO;
  {$I pFIBMacroComp.inc}



Tisc_install_get_message = function (hOption: OPTIONS_HANDLE;
                                     message_no: MSG_NO;
                                     message_txt: Pointer;
                                     message_len: Cardinal):MSG_NO;
  {$I pFIBMacroComp.inc}

Tisc_install_load_external_text = function (msg_file_name: TEXT):MSG_NO;
  {$I pFIBMacroComp.inc}

Tisc_install_precheck = function (hOption: OPTIONS_HANDLE;
                                  src_dir: TEXT;
                                  dest_dir: TEXT):MSG_NO;
  {$I pFIBMacroComp.inc}

Tisc_install_set_option = function (hOption: POPTIONS_HANDLE;
                                    option: OPT):MSG_NO;
  {$I pFIBMacroComp.inc}

Tisc_uninstall_execute = function (uninstall_file_name: TEXT;
                                   status_func: FP_STATUS;
                                   status_data: pointer;
                                   error_func: FP_ERROR;
                                   error_data: pointer):MSG_NO;
  {$I pFIBMacroComp.inc}

Tisc_uninstall_precheck = function (uninstall_file_name: TEXT):MSG_NO;
  {$I pFIBMacroComp.inc}

Tisc_install_unset_option = function (hOption: POPTIONS_HANDLE;
                                      option: OPT):MSG_NO;
  {$I pFIBMacroComp.inc}
implementation


  { EXECute ....check of Install mode and call Install_execute or unistall_execute }
  { raise an exception on error from the dll }
  { call the onWarning handler on warning from DLL }
  { GetSpaceAvailable -- call isc_install_get_info function }
end.
