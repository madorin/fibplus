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

unit IB_ErrorCodes;

interface

const
  isc_arith_except               =  335544321;
  isc_bad_dbkey                  =  335544322;
  isc_bad_db_format              =  335544323;
  isc_bad_db_handle              =  335544324;
  isc_bad_dpb_content            =  335544325;
  isc_bad_dpb_form               =  335544326;
  isc_bad_req_handle             =  335544327;
  isc_bad_segstr_handle          =  335544328;
  isc_bad_segstr_id              =  335544329;
  isc_bad_tpb_content            =  335544330;
  isc_bad_tpb_form               =  335544331;
  isc_bad_trans_handle           =  335544332;
  isc_bug_check                  =  335544333;
  isc_convert_error              =  335544334;
  isc_db_corrupt                 =  335544335;
  isc_deadlock                   =  335544336;
  isc_excess_trans               =  335544337;
  isc_from_no_match              =  335544338;
  isc_infinap                    =  335544339;
  isc_infona                     =  335544340;
  isc_infunk                     =  335544341;
  isc_integ_fail                 =  335544342;
  isc_invalid_blr                =  335544343;
  isc_io_error                   =  335544344;
  isc_lock_conflict              =  335544345;
  isc_metadata_corrupt           =  335544346;
  isc_not_valid                  =  335544347;
  isc_no_cur_rec                 =  335544348;
  isc_no_dup                     =  335544349;
  isc_no_finish                  =  335544350;
  isc_no_meta_update             =  335544351;
  isc_no_priv                    =  335544352;
  isc_no_recon                   =  335544353;
  isc_no_record                  =  335544354;
  isc_no_segstr_close            =  335544355;
  isc_obsolete_metadata          =  335544356;
  isc_open_trans                 =  335544357;
  isc_port_len                   =  335544358;
  isc_read_only_field            =  335544359;
  isc_read_only_rel              =  335544360;
  isc_read_only_trans            =  335544361;
  isc_read_only_view             =  335544362;
  isc_req_no_trans               =  335544363;
  isc_req_sync                   =  335544364;
  isc_req_wrong_db               =  335544365;
  isc_segment                    =  335544366;
  isc_segstr_eof                 =  335544367;
  isc_segstr_no_op               =  335544368;
  isc_segstr_no_read             =  335544369;
  isc_segstr_no_trans            =  335544370;
  isc_segstr_no_write            =  335544371;
  isc_segstr_wrong_db            =  335544372;
  isc_sys_request                =  335544373;
  isc_stream_eof                 =  335544374;
  isc_unavailable                =  335544375;
  isc_unres_rel                  =  335544376;
  isc_uns_ext                    =  335544377;
  isc_wish_list                  =  335544378;
  isc_wrong_ods                  =  335544379;
  isc_wronumarg                  =  335544380;
  isc_imp_exc                    =  335544381;
  isc_random                     =  335544382;
  isc_fatal_conflict             =  335544383;
  isc_badblk                     =  335544384;
  isc_invpoolcl                  =  335544385;
  isc_nopoolids                  =  335544386;
  isc_relbadblk                  =  335544387;
  isc_blktoobig                  =  335544388;
  isc_bufexh                     =  335544389;
  isc_syntaxerr                  =  335544390;
  isc_bufinuse                   =  335544391;
  isc_bdbincon                   =  335544392;
  isc_reqinuse                   =  335544393;
  isc_badodsver                  =  335544394;
  isc_relnotdef                  =  335544395;
  isc_fldnotdef                  =  335544396;
  isc_dirtypage                  =  335544397;
  isc_waifortra                  =  335544398;
  isc_doubleloc                  =  335544399;
  isc_nodnotfnd                  =  335544400;
  isc_dupnodfnd                  =  335544401;
  isc_locnotmar                  =  335544402;
  isc_badpagtyp                  =  335544403;
  isc_corrupt                    =  335544404;
  isc_badpage                    =  335544405;
  isc_badindex                   =  335544406;
  isc_dbbnotzer                  =  335544407;
  isc_tranotzer                  =  335544408;
  isc_trareqmis                  =  335544409;
  isc_badhndcnt                  =  335544410;
  isc_wrotpbver                  =  335544411;
  isc_wroblrver                  =  335544412;
  isc_wrodpbver                  =  335544413;
  isc_blobnotsup                 =  335544414;
  isc_badrelation                =  335544415;
  isc_nodetach                   =  335544416;
  isc_notremote                  =  335544417;
  isc_trainlim                   =  335544418;
  isc_notinlim                   =  335544419;
  isc_traoutsta                  =  335544420;
  isc_connect_reject             =  335544421;
  isc_dbfile                     =  335544422;
  isc_orphan                     =  335544423;
  isc_no_lock_mgr                =  335544424;
  isc_ctxinuse                   =  335544425;
  isc_ctxnotdef                  =  335544426;
  isc_datnotsup                  =  335544427;
  isc_badmsgnum                  =  335544428;
  isc_badparnum                  =  335544429;
  isc_virmemexh                  =  335544430;
  isc_blocking_signal            =  335544431;
  isc_lockmanerr                 =  335544432;
  isc_journerr                   =  335544433;
  isc_keytoobig                  =  335544434;
  isc_nullsegkey                 =  335544435;
  isc_sqlerr                     =  335544436;
  isc_wrodynver                  =  335544437;
  isc_funnotdef                  =  335544438;
  isc_funmismat                  =  335544439;
  isc_bad_msg_vec                =  335544440;
  isc_bad_detach                 =  335544441;
  isc_noargacc_read              =  335544442;
  isc_noargacc_write             =  335544443;
  isc_read_only                  =  335544444;
  isc_ext_err                    =  335544445;
  isc_non_updatable              =  335544446;
  isc_no_rollback                =  335544447;
  isc_bad_sec_info               =  335544448;
  isc_invalid_sec_info           =  335544449;
  isc_misc_interpreted           =  335544450;
  isc_update_conflict            =  335544451;
  isc_unlicensed                 =  335544452;
  isc_obj_in_use                 =  335544453;
  isc_nofilter                   =  335544454;
  isc_shadow_accessed            =  335544455;
  isc_invalid_sdl                =  335544456;
  isc_out_of_bounds              =  335544457;
  isc_invalid_dimension          =  335544458;
  isc_rec_in_limbo               =  335544459;
  isc_shadow_missing             =  335544460;
  isc_cant_validate              =  335544461;
  isc_cant_start_journal         =  335544462;
  isc_gennotdef                  =  335544463;
  isc_cant_start_logging         =  335544464;
  isc_bad_segstr_type            =  335544465;
  isc_foreign_key                =  335544466;
  isc_high_minor                 =  335544467;
  isc_tra_state                  =  335544468;
  isc_trans_invalid              =  335544469;
  isc_buf_invalid                =  335544470;
  isc_indexnotdefined            =  335544471;
  isc_login                      =  335544472;
  isc_invalid_bookmark           =  335544473;
  isc_bad_lock_level             =  335544474;
  isc_relation_lock              =  335544475;
  isc_record_lock                =  335544476;
  isc_max_idx                    =  335544477;
  isc_jrn_enable                 =  335544478;
  isc_old_failure                =  335544479;
  isc_old_in_progress            =  335544480;
  isc_old_no_space               =  335544481;
  isc_no_wal_no_jrn              =  335544482;
  isc_num_old_files              =  335544483;
  isc_wal_file_open              =  335544484;
  isc_bad_stmt_handle            =  335544485;
  isc_wal_failure                =  335544486;
  isc_walw_err                   =  335544487;
  isc_logh_small                 =  335544488;
  isc_logh_inv_version           =  335544489;
  isc_logh_open_flag             =  335544490;
  isc_logh_open_flag2            =  335544491;
  isc_logh_diff_dbname           =  335544492;
  isc_logf_unexpected_eof        =  335544493;
  isc_logr_incomplete            =  335544494;
  isc_logr_header_small          =  335544495;
  isc_logb_small                 =  335544496;
  isc_wal_illegal_attach         =  335544497;
  isc_wal_invalid_wpb            =  335544498;
  isc_wal_err_rollover           =  335544499;
  isc_no_wal                     =  335544500;
  isc_drop_wal                   =  335544501;
  isc_stream_not_defined         =  335544502;
  isc_wal_subsys_error           =  335544503;
  isc_wal_subsys_corrupt         =  335544504;
  isc_no_archive                 =  335544505;
  isc_shutinprog                 =  335544506;
  isc_range_in_use               =  335544507;
  isc_range_not_found            =  335544508;
  isc_charset_not_found          =  335544509;
  isc_lock_timeout               =  335544510;
  isc_prcnotdef                  =  335544511;
  isc_prcmismat                  =  335544512;
  isc_wal_bugcheck               =  335544513;
  isc_wal_cant_expand            =  335544514;
  isc_codnotdef                  =  335544515;
  isc_xcpnotdef                  =  335544516;
  isc_except                     =  335544517;
  isc_cache_restart              =  335544518;
  isc_bad_lock_handle            =  335544519;
  isc_jrn_present                =  335544520;
  isc_wal_err_rollover2          =  335544521;
  isc_wal_err_logwrite           =  335544522;
  isc_wal_err_jrn_comm           =  335544523;
  isc_wal_err_expansion          =  335544524;
  isc_wal_err_setup              =  335544525;
  isc_wal_err_ww_sync            =  335544526;
  isc_wal_err_ww_start           =  335544527;
  isc_shutdown                   =  335544528;
  isc_existing_priv_mod          =  335544529;
  isc_primary_key_ref            =  335544530;
  isc_primary_key_notnull        =  335544531;
  isc_ref_cnstrnt_notfound       =  335544532;
  isc_foreign_key_notfound       =  335544533;
  isc_ref_cnstrnt_update         =  335544534;
  isc_check_cnstrnt_update       =  335544535;
  isc_check_cnstrnt_del          =  335544536;
  isc_integ_index_seg_del        =  335544537;
  isc_integ_index_seg_mod        =  335544538;
  isc_integ_index_del            =  335544539;
  isc_integ_index_mod            =  335544540;
  isc_check_trig_del             =  335544541;
  isc_check_trig_update          =  335544542;
  isc_cnstrnt_fld_del            =  335544543;
  isc_cnstrnt_fld_rename         =  335544544;
  isc_rel_cnstrnt_update         =  335544545;
  isc_constaint_on_view          =  335544546;
  isc_invld_cnstrnt_type         =  335544547;
  isc_primary_key_exists         =  335544548;
  isc_systrig_update             =  335544549;
  isc_not_rel_owner              =  335544550;
  isc_grant_obj_notfound         =  335544551;
  isc_grant_fld_notfound         =  335544552;
  isc_grant_nopriv               =  335544553;
  isc_nonsql_security_rel        =  335544554;
  isc_nonsql_security_fld        =  335544555;
  isc_wal_cache_err              =  335544556;
  isc_shutfail                   =  335544557;
  isc_check_constraint           =  335544558;
  isc_bad_svc_handle             =  335544559;
  isc_shutwarn                   =  335544560;
  isc_wrospbver                  =  335544561;
  isc_bad_spb_form               =  335544562;
  isc_svcnotdef                  =  335544563;
  isc_no_jrn                     =  335544564;
  isc_transliteration_failed     =  335544565;
  isc_start_cm_for_wal           =  335544566;
  isc_wal_ovflow_log_required    =  335544567;
  isc_text_subtype               =  335544568;
  isc_dsql_error                 =  335544569;
  isc_dsql_command_err           =  335544570;
  isc_dsql_constant_err          =  335544571;
  isc_dsql_cursor_err            =  335544572;
  isc_dsql_datatype_err          =  335544573;
  isc_dsql_decl_err              =  335544574;
  isc_dsql_cursor_update_err     =  335544575;
  isc_dsql_cursor_open_err       =  335544576;
  isc_dsql_cursor_close_err      =  335544577;
  isc_dsql_field_err             =  335544578;
  isc_dsql_internal_err          =  335544579;
  isc_dsql_relation_err          =  335544580;
  isc_dsql_procedure_err         =  335544581;
  isc_dsql_request_err           =  335544582;
  isc_dsql_sqlda_err             =  335544583;
  isc_dsql_var_count_err         =  335544584;
  isc_dsql_stmt_handle           =  335544585;
  isc_dsql_function_err          =  335544586;
  isc_dsql_blob_err              =  335544587;
  isc_collation_not_found        =  335544588;
  isc_collation_not_for_charset  =  335544589;
  isc_dsql_dup_option            =  335544590;
  isc_dsql_tran_err              =  335544591;
  isc_dsql_invalid_array         =  335544592;
  isc_dsql_max_arr_dim_exceeded  =  335544593;
  isc_dsql_arr_range_error       =  335544594;
  isc_dsql_trigger_err           =  335544595;
  isc_dsql_subselect_err         =  335544596;
  isc_dsql_crdb_prepare_err      =  335544597;
  isc_specify_field_err          =  335544598;
  isc_num_field_err              =  335544599;
  isc_col_name_err               =  335544600;
  isc_where_err                  =  335544601;
  isc_table_view_err             =  335544602;
  isc_distinct_err               =  335544603;
  isc_key_field_count_err        =  335544604;
  isc_subquery_err               =  335544605;
  isc_expression_eval_err        =  335544606;
  isc_node_err                   =  335544607;
  isc_command_end_err            =  335544608;
  isc_index_name                 =  335544609;
  isc_exception_name             =  335544610;
  isc_field_name                 =  335544611;
  isc_token_err                  =  335544612;
  isc_union_err                  =  335544613;
  isc_dsql_construct_err         =  335544614;
  isc_field_aggregate_err        =  335544615;
  isc_field_ref_err              =  335544616;
  isc_order_by_err               =  335544617;
  isc_return_mode_err            =  335544618;
  isc_extern_func_err            =  335544619;
  isc_alias_conflict_err         =  335544620;
  isc_procedure_conflict_error   =  335544621;
  isc_relation_conflict_err      =  335544622;
  isc_dsql_domain_err            =  335544623;
  isc_idx_seg_err                =  335544624;
  isc_node_name_err              =  335544625;
  isc_table_name                 =  335544626;
  isc_proc_name                  =  335544627;
  isc_idx_create_err             =  335544628;
  isc_wal_shadow_err             =  335544629;
  isc_dependency                 =  335544630;
  isc_idx_key_err                =  335544631;
  isc_dsql_file_length_err       =  335544632;
  isc_dsql_shadow_number_err     =  335544633;
  isc_dsql_token_unk_err         =  335544634;
  isc_dsql_no_relation_alias     =  335544635;
  isc_indexname                  =  335544636;
  isc_no_stream_plan             =  335544637;
  isc_stream_twice               =  335544638;
  isc_stream_not_found           =  335544639;
  isc_collation_requires_text    =  335544640;
  isc_dsql_domain_not_found      =  335544641;
  isc_index_unused               =  335544642;
  isc_dsql_self_join             =  335544643;
  isc_stream_bof                 =  335544644;
  isc_stream_crack               =  335544645;
  isc_db_or_file_exists          =  335544646;
  isc_invalid_operator           =  335544647;
  isc_conn_lost                  =  335544648;
  isc_bad_checksum               =  335544649;
  isc_page_type_err              =  335544650;
  isc_ext_readonly_err           =  335544651;
  isc_sing_select_err            =  335544652;
  isc_psw_attach                 =  335544653;
  isc_psw_start_trans            =  335544654;
  isc_invalid_direction          =  335544655;
  isc_dsql_var_conflict          =  335544656;
  isc_dsql_no_blob_array         =  335544657;
  isc_dsql_base_table            =  335544658;
  isc_duplicate_base_table       =  335544659;
  isc_view_alias                 =  335544660;
  isc_index_root_page_full       =  335544661;
  isc_dsql_blob_type_unknown     =  335544662;
  isc_req_max_clones_exceeded    =  335544663;
  isc_dsql_duplicate_spec        =  335544664;
  isc_unique_key_violation       =  335544665;
  isc_srvr_version_too_old       =  335544666;
  isc_drdb_completed_with_errs   =  335544667;
  isc_dsql_procedure_use_err     =  335544668;
  isc_dsql_count_mismatch        =  335544669;
  isc_blob_idx_err               =  335544670;
  isc_array_idx_err              =  335544671;
  isc_key_field_err              =  335544672;
  isc_no_delete                  =  335544673;
  isc_del_last_field             =  335544674;
  isc_sort_err                   =  335544675;
  isc_sort_mem_err               =  335544676;
  isc_version_err                =  335544677;
  isc_inval_key_posn             =  335544678;
  isc_no_segments_err            =  335544679;
  isc_crrp_data_err              =  335544680;
  isc_rec_size_err               =  335544681;
  isc_dsql_field_ref             =  335544682;
  isc_req_depth_exceeded         =  335544683;
  isc_no_field_access            =  335544684;
  isc_no_dbkey                   =  335544685;
  isc_jrn_format_err             =  335544686;
  isc_jrn_file_full              =  335544687;
  isc_dsql_open_cursor_request   =  335544688;
  isc_ib_error                   =  335544689;
  isc_cache_redef                =  335544690;
  isc_cache_too_small            =  335544691;
  isc_log_redef                  =  335544692;
  isc_log_too_small              =  335544693;
  isc_partition_too_small        =  335544694;
  isc_partition_not_supp         =  335544695;
  isc_log_length_spec            =  335544696;
  isc_precision_err              =  335544697;
  isc_scale_nogt                 =  335544698;
  isc_expec_short                =  335544699;
  isc_expec_long                 =  335544700;
  isc_expec_ushort               =  335544701;
  isc_like_escape_invalid        =  335544702;
  isc_svcnoexe                   =  335544703;
  isc_net_lookup_err             =  335544704;
  isc_service_unknown            =  335544705;
  isc_host_unknown               =  335544706;
  isc_grant_nopriv_on_base       =  335544707;
  isc_dyn_fld_ambiguous          =  335544708;
  isc_dsql_agg_ref_err           =  335544709;
  isc_complex_view               =  335544710;
  isc_unprepared_stmt            =  335544711;
  isc_expec_positive             =  335544712;
  isc_dsql_sqlda_value_err       =  335544713;
  isc_invalid_array_id           =  335544714;
  isc_extfile_uns_op             =  335544715;
  isc_svc_in_use                 =  335544716;
  isc_err_stack_limit            =  335544717;
  isc_invalid_key                =  335544718;
  isc_net_init_error             =  335544719;
  isc_loadlib_failure            =  335544720;
  isc_network_error              =  335544721;
  isc_net_connect_err            =  335544722;
  isc_net_connect_listen_err     =  335544723;
  isc_net_event_connect_err      =  335544724;
  isc_net_event_listen_err       =  335544725;
  isc_net_read_err               =  335544726;
  isc_net_write_err              =  335544727;
  isc_integ_index_deactivate     =  335544728;
  isc_integ_deactivate_primary   =  335544729;
  isc_cse_not_supported          =  335544730;
  isc_tra_must_sweep             =  335544731;
  isc_unsupported_network_drive  =  335544732;
  isc_io_create_err              =  335544733;
  isc_io_open_err                =  335544734;
  isc_io_close_err               =  335544735;
  isc_io_read_err                =  335544736;
  isc_io_write_err               =  335544737;
  isc_io_delete_err              =  335544738;
  isc_io_access_err              =  335544739;
  isc_udf_exception              =  335544740;
  isc_lost_db_connection         =  335544741;
  isc_no_write_user_priv         =  335544742;
  isc_token_too_long             =  335544743;
  isc_max_att_exceeded           =  335544744;
  isc_login_same_as_role_name    =  335544745;
  isc_usrname_too_long           =  335544747;
  isc_password_too_long          =  335544748;
  isc_usrname_required           =  335544749;
  isc_password_required          =  335544750;
  isc_bad_protocol               =  335544751;
  isc_dup_usrname_found          =  335544752;
  isc_usrname_not_found          =  335544753;
  isc_error_adding_sec_record    =  335544754;
  isc_error_modifying_sec_record =  335544755;
  isc_error_deleting_sec_record  =  335544756;
  isc_error_updating_sec_db      =  335544757;
  isc_sort_rec_size_err                = 335544758;
  isc_bad_default_value                = 335544759;
  isc_invalid_clause                   = 335544760;
  isc_too_many_handles                 = 335544761;
  isc_optimizer_blk_exc                = 335544762;
  isc_invalid_string_constant          = 335544763;
  isc_transitional_date                = 335544764;
  isc_read_only_database               = 335544765;
  isc_must_be_dialect_2_and_up         = 335544766;
  isc_blob_filter_exception            = 335544767;
  isc_exception_access_violation       = 335544768;
  isc_exception_datatype_missalignment = 335544769;
  isc_exception_array_bounds_exceeded  = 335544770;
  isc_exception_float_denormal_operand = 335544771;
  isc_exception_float_divide_by_zero   = 335544772;
  isc_exception_float_inexact_result   = 335544773;
  isc_exception_float_invalid_operand  = 335544774;
  isc_exception_float_overflow         = 335544775;
  isc_exception_float_stack_check      = 335544776;
  isc_exception_float_underflow        = 335544777;
  isc_exception_integer_divide_by_zero = 335544778;
  isc_exception_integer_overflow       = 335544779;
  isc_exception_unknown                = 335544780;
  isc_exception_stack_overflow         = 335544781;
  isc_exception_sigsegv                = 335544782;
  isc_exception_sigill                 = 335544783;
  isc_exception_sigbus                 = 335544784;
  isc_exception_sigfpe                 = 335544785;
  isc_ext_file_delete                  = 335544786;
  isc_ext_file_modify                  = 335544787;
  isc_adm_task_denied                  = 335544788;
  isc_extract_input_mismatch           = 335544789;
  isc_insufficient_svc_privileges      = 335544790;
  isc_file_in_use                      = 335544791;
  isc_service_att_err                  = 335544792;
  isc_ddl_not_allowed_by_db_sql_dial   = 335544793;
  isc_cancelled                        = 335544794;
  isc_unexp_spb_form                   = 335544795;
  isc_gfix_db_name                     = 335740929;
  isc_gfix_invalid_sw                  = 335740930;
  isc_gfix_incmp_sw                    = 335740932;
  isc_gfix_replay_req                  = 335740933;
  isc_gfix_pgbuf_req                   = 335740934;
  isc_gfix_val_req                     = 335740935;
  isc_gfix_pval_req                    = 335740936;
  isc_gfix_trn_req                     = 335740937;
  isc_gfix_full_req                    = 335740940;
  isc_gfix_usrname_req                 = 335740941;
  isc_gfix_pass_req                    = 335740942;
  isc_gfix_subs_name                   = 335740943;
  isc_gfix_wal_req                     = 335740944;
  isc_gfix_sec_req                     = 335740945;
  isc_gfix_nval_req                    = 335740946;
  isc_gfix_type_shut                   = 335740947;
  isc_gfix_retry                       = 335740948;
  isc_gfix_retry_db                    = 335740951;
  isc_gfix_exceed_max                  = 335740991;
  isc_gfix_corrupt_pool                = 335740992;
  isc_gfix_mem_exhausted               = 335740993;
  isc_gfix_bad_pool                    = 335740994;
  isc_gfix_trn_not_valid               = 335740995;
  isc_gfix_unexp_eoi                   = 335741012;
  isc_gfix_recon_fail                  = 335741018;
  isc_gfix_trn_unknown                 = 335741036;
  isc_gfix_mode_req                    = 335741038;
  isc_gfix_opt_SQL_dialect             = 335741039;
  isc_dsql_dbkey_from_non_table        = 336003074;
  isc_dsql_transitional_numeric        = 336003075;
  isc_dsql_dialect_warning_expr        = 336003076;
  isc_dyn_role_does_not_exist          = 336068796;
  isc_dyn_no_grant_admin_opt           = 336068797;
  isc_dyn_user_not_role_member         = 336068798;
  isc_dyn_delete_role_failed           = 336068799;
  isc_dyn_grant_role_to_user           = 336068800;
  isc_dyn_inv_sql_role_name            = 336068801;
  isc_dyn_dup_sql_role                 = 336068802;
  isc_dyn_kywd_spec_for_role           = 336068803;
  isc_dyn_roles_not_supported          = 336068804;
  isc_dyn_domain_name_exists           = 336068812;
  isc_dyn_field_name_exists            = 336068813;
  isc_dyn_dependency_exists            = 336068814;
  isc_dyn_dtype_invalid                = 336068815;
  isc_dyn_char_fld_too_small           = 336068816;
  isc_dyn_invalid_dtype_conversion     = 336068817;
  isc_dyn_dtype_conv_invalid           = 336068818;
  isc_gbak_unknown_switch              = 336330753;
  isc_gbak_page_size_missing           = 336330754;
  isc_gbak_page_size_toobig            = 336330755;
  isc_gbak_redir_ouput_missing         = 336330756;
  isc_gbak_switches_conflict           = 336330757;
  isc_gbak_unknown_device              = 336330758;
  isc_gbak_no_protection               = 336330759;
  isc_gbak_page_size_not_allowed       = 336330760;
  isc_gbak_multi_source_dest           = 336330761;
  isc_gbak_filename_missing            = 336330762;
  isc_gbak_dup_inout_names             = 336330763;
  isc_gbak_inv_page_size               = 336330764;
  isc_gbak_db_specified                = 336330765;
  isc_gbak_db_exists                   = 336330766;
  isc_gbak_unk_device                  = 336330767;
  isc_gbak_blob_info_failed            = 336330772;
  isc_gbak_unk_blob_item               = 336330773;
  isc_gbak_get_seg_failed              = 336330774;
  isc_gbak_close_blob_failed           = 336330775;
  isc_gbak_open_blob_failed            = 336330776;
  isc_gbak_put_blr_gen_id_failed       = 336330777;
  isc_gbak_unk_type                    = 336330778;
  isc_gbak_comp_req_failed             = 336330779;
  isc_gbak_start_req_failed            = 336330780;
  isc_gbak_rec_failed                  = 336330781;
  isc_gbak_rel_req_failed              = 336330782;
  isc_gbak_db_info_failed              = 336330783;
  isc_gbak_no_db_desc                  = 336330784;
  isc_gbak_db_create_failed            = 336330785;
  isc_gbak_decomp_len_error            = 336330786;
  isc_gbak_tbl_missing                 = 336330787;
  isc_gbak_blob_col_missing            = 336330788;
  isc_gbak_create_blob_failed          = 336330789;
  isc_gbak_put_seg_failed              = 336330790;
  isc_gbak_rec_len_exp                 = 336330791;
  isc_gbak_inv_rec_len                 = 336330792;
  isc_gbak_exp_data_type               = 336330793;
  isc_gbak_gen_id_failed               = 336330794;
  isc_gbak_unk_rec_type                = 336330795;
  isc_gbak_inv_bkup_ver                = 336330796;
  isc_gbak_missing_bkup_desc           = 336330797;
  isc_gbak_string_trunc                = 336330798;
  isc_gbak_cant_rest_record            = 336330799;
  isc_gbak_send_failed                 = 336330800;
  isc_gbak_no_tbl_name                 = 336330801;
  isc_gbak_unexp_eof                   = 336330802;
  isc_gbak_db_format_too_old           = 336330803;
  isc_gbak_inv_array_dim               = 336330804;
  isc_gbak_xdr_len_expected            = 336330807;
  isc_gbak_open_bkup_error             = 336330817;
  isc_gbak_open_error                  = 336330818;
  isc_gbak_missing_block_fac           = 336330934;
  isc_gbak_inv_block_fac               = 336330935;
  isc_gbak_block_fac_specified         = 336330936;
  isc_gbak_missing_username            = 336330940;
  isc_gbak_missing_password            = 336330941;
  isc_gbak_missing_skipped_bytes       = 336330952;
  isc_gbak_inv_skipped_bytes           = 336330953;
  isc_gbak_err_restore_charset         = 336330965;
  isc_gbak_err_restore_collation       = 336330967;
  isc_gbak_read_error                  = 336330972;
  isc_gbak_write_error                 = 336330973;
  isc_gbak_db_in_use                   = 336330985;
  isc_gbak_sysmemex                    = 336330990;
  isc_gbak_restore_role_failed         = 336331002;
  isc_gbak_role_op_missing             = 336331005;
  isc_gbak_page_buffers_missing        = 336331010;
  isc_gbak_page_buffers_wrong_param    = 336331011;
  isc_gbak_page_buffers_restore        = 336331012;
  isc_gbak_inv_size                    = 336331014;
  isc_gbak_file_outof_sequence         = 336331015;
  isc_gbak_join_file_missing           = 336331016;
  isc_gbak_stdin_not_supptd            = 336331017;
  isc_gbak_stdout_not_supptd           = 336331018;
  isc_gbak_bkup_corrupt                = 336331019;
  isc_gbak_unk_db_file_spec            = 336331020;
  isc_gbak_hdr_write_failed            = 336331021;
  isc_gbak_disk_space_ex               = 336331022;
  isc_gbak_size_lt_min                 = 336331023;
  isc_gbak_svc_name_missing            = 336331025;
  isc_gbak_not_ownr                    = 336331026;
  isc_gbak_mode_req                    = 336331031;
  isc_gsec_cant_open_db                = 336723983;
  isc_gsec_switches_error              = 336723984;
  isc_gsec_no_op_spec                  = 336723985;
  isc_gsec_no_usr_name                 = 336723986;
  isc_gsec_err_add                     = 336723987;
  isc_gsec_err_modify                  = 336723988;
  isc_gsec_err_find_mod                = 336723989;
  isc_gsec_err_rec_not_found           = 336723990;
  isc_gsec_err_delete                  = 336723991;
  isc_gsec_err_find_del                = 336723992;
  isc_gsec_err_find_disp               = 336723996;
  isc_gsec_inv_param                   = 336723997;
  isc_gsec_op_specified                = 336723998;
  isc_gsec_pw_specified                = 336723999;
  isc_gsec_uid_specified               = 336724000;
  isc_gsec_gid_specified               = 336724001;
  isc_gsec_proj_specified              = 336724002;
  isc_gsec_org_specified               = 336724003;
  isc_gsec_fname_specified             = 336724004;
  isc_gsec_mname_specified             = 336724005;
  isc_gsec_lname_specified             = 336724006;
  isc_gsec_inv_switch                  = 336724008;
  isc_gsec_amb_switch                  = 336724009;
  isc_gsec_no_op_specified             = 336724010;
  isc_gsec_params_not_allowed          = 336724011;
  isc_gsec_incompat_switch             = 336724012;
  isc_gsec_inv_username                = 336724044;
  isc_gsec_inv_pw_length               = 336724045;
  isc_gsec_db_specified                = 336724046;
  isc_gsec_db_admin_specified          = 336724047;
  isc_gsec_db_admin_pw_specified       = 336724048;
  isc_gsec_sql_role_specified          = 336724049;
  isc_license_no_file                  = 336789504;
  isc_license_op_specified             = 336789523;
  isc_license_op_missing               = 336789524;
  isc_license_inv_switch               = 336789525;
  isc_license_inv_switch_combo         = 336789526;
  isc_license_inv_op_combo             = 336789527;
  isc_license_amb_switch               = 336789528;
  isc_license_inv_parameter            = 336789529;
  isc_license_param_specified          = 336789530;
  isc_license_param_req                = 336789531;
  isc_license_syntx_error              = 336789532;
  isc_license_dup_id                   = 336789534;
  isc_license_inv_id_key               = 336789535;
  isc_license_err_remove               = 336789536;
  isc_license_err_update               = 336789537;
  isc_license_err_convert              = 336789538;
  isc_license_err_unk                  = 336789539;
  isc_gstat_unknown_switch             = 336920577;
  isc_gstat_retry                      = 336920578;
  isc_gstat_wrong_ods                  = 336920579;
  isc_gstat_unexpected_eof             = 336920580;
  isc_gstat_open_err                   = 336920605;
  isc_gstat_read_err                   = 336920606;
  isc_gstat_sysmemex                   = 336920607;
  isc_err_max                          = 660;

 //FB
  isc_att_shutdown                    = 335544856;
//Error SQLCodes
// See Language reference.pdf  Chapter 6. Page186
  sqlcode_checkconstraint              =-297;
  sqlcode_foreign_or_create_schema     =-530;
  sqlcode_notpermission                =-551;
  sqlcode_unique_violation             =-803;
  sqlcode_exception                    =-836;
  sqlcode_deadlock                     =-913;
  sqlcode_902                          =-902;
  sqlcode_901                          =-901;


implementation
  {
101 Segment buffer length shorter than expected 335544366L
100 No match for first value expression 335544338L
100 Invalid database key 335544354L
100 Attempted retrieval of more segments than exist 335544367L
100 Attempt to fetch past the last record in a record stream 335544374L
-84 Table/procedure has non-SQL security class defined 335544554L
-84 Column has non-SQL security class defined 335544555L
-84 Procedure <string> does not return any values 335544668L
-103 Datatype for constant unknown 335544571L
-104 Invalid request BLR at offset <long> 335544343L
-104 BLR syntax error: expected <string> at offset <long>,encountered <long>335544390L
-104 Context already in use (BLR error) 335544425L
-104 Context not defined (BLR error) 335544426L
-104 Bad parameter number 335544429L
-104 335544440L
-104 Invalid slice description language at offset <long> 335544456L
-104 Invalid command 335544570L
-104 Internal error 335544579L
-104 Option specified more than once 335544590L

-104 Unknown transaction option 335544591L
-104 Invalid array reference 335544592L
-104 Token unknown-line <long>, char <long> 335544634L
-104 Unexpected end of command 335544608L
-104 Token unknown 335544612L
-150 Attempted update of read-only table 335544360L
-150 Cannot update read-only view <string> 335544362L
-150 Not updatable 335544446L
-150 Cannot define constraints on views 335544546L
-151 Attempted update of read-only column 335544359L
-155 <string> is not a valid base table of the specified view 335544658L
-157 Must specify column name for view select expression 335544598L
-158 Number of columns does not match select list 335544599L
-162 Dbkey not available for multi-table views 335544685L
-170 Parameter mismatch for procedure <string> 335544512L
-170 External functions cannot have more than10 parameters 335544619L
-171 Function <string> could not be matched 335544439L
-171 Column notarray or invalid dimensions(expected<long>,encountered
<long>)
335544458L
-171 Return mode by value not allowed for this datatype 335544618L
-172 Function <string> is not defined 335544438L
-204 Generator <string> is not defined 335544463L
-204 Reference to invalid stream number 335544502L

-204 CHARACTER SET <string> is not defined 335544509L
-204 Procedure <string> is not defined 335544511L
-204 Status code <string> unknown 335544515L
-204 Exception <string> not defined 335544516L
-204 Name of Referential Constraint not defined in constraints table. 335544532L
-204 Could not find table/procedure for GRANT 335544551L
-204 Implementation of text subtype <digit> not located. 335544568L
-204 Datatype unknown 335544573L
-204 Table unknown 335544580L
-204 Procedure unknown 335544581L
-204 COLLATION <string> is not defined 335544588L
-204 COLLATION <string> is not valid for specified CHARACTER SET 335544589L
-204 Trigger unknown 335544595L
-204 Alias <string> conflicts with an alias in the same statement 335544620L
-204 Alias <string> conflicts with a procedure in the same statement 335544621L
-204 Alias <string> conflicts with a table in the same statement 335544622L
-204 There is no alias or table named <string> at this scope level 335544635L
-204 There is no index <string> for table <string> 335544636L
-204 Invalid use of CHARACTER SET or COLLATE 335544640L
-204 BLOB SUB_TYPE <string> is not defined 335544662L
-205 Column <string> is not defined in table <string> 335544396L
-205 Could not find column for GRANT 335544552L

-206 Column is not a Blob 335544587L
-206 Subselect illegal in this context 335544596L
-208 Invalid ORDER BY clause 335544617L
-219 Table <string> is not defined 335544395L
-239 Cache length too small 335544691L
-260 Cache redefined 335544690L
-281 Table <string> is not referenced in plan 335544637L
-282 Table <string> is referenced more than once in plan; use aliases to
distinguish
335544638L
-282 The table <string> is referenced twice; use aliases to differentiate 335544643L
-282 Table <string> is referenced twice in view; use an alias to distinguish 335544659L
-282 View <string> has more than one base table; use aliases to distinguish 335544660L
-283 Table <string> is referenced in the plan but not the from list 335544639L
-284 Index <string> cannot be used in the specified plan 335544642L
-291 Column used in a PRIMARY/UNIQUE constraint must be NOT NULL. 335544531L
-292 Cannot update constraints (RDB$REF_CONSTRAINTS). 335544534L
-293 Cannot update constraints (RDB$CHECK_CONSTRAINTS). 335544535L
-294 Cannot delete CHECK constraint entry (RDB$CHECK_CONSTRAINTS) 335544536L
-295 Cannot update constraints (RDB$RELATION_CONSTRAINTS). 335544545L
-296 Internal isc software consistency check (invalid RDB$CONSTRAINT_TYPE) 335544547L
-297 Operation violates CHECK constraint <string> on view or table 335544558L
-313 Count of column list and variable list do not match 335544669L
-314 Cannot transliterate character between character sets 335544565L


-401 Invalid comparison operator for find operation 335544647L
-402 Attempted invalid operation on a Blob 335544368L
-402 Blob and array datatypes are not supported for <string> operation 335544414L
-402 Data operation not supported 335544427L
-406 Subscript out of bounds 335544457L
-407 Null segment of UNIQUE KEY 335544435L
-413 Conversion error from string "<string>" 335544334L
-413 Filter not found to convert type <long> to type <long> 335544454L
-501 Invalid request handle 335544327L
-501 Attempt to reclose a closed cursor 335544577L
-502 Declared cursor already exists 335544574L
-502 Attempt to reopen an open cursor 335544576L
-504 Cursor unknown 335544572L
-508 No current record for fetch operation 335544348L
-510 Cursor not updatable 335544575L
-518 Request unknown 335544582L
-519 The PREPARE statement identifies a prepare statement with an open
cursor
335544688L
-530 Violation of FOREIGN KEY constraint: "<string>" 335544466L
-530 Cannot prepare a CREATE DATABASE/SCHEMA statement 335544597L
-532 Transaction marked invalid by I/O error 335544469L
-551 No permission for <string> access to <string> <string> 335544352L
-552 Only the owner of a table can reassign ownership 335544550L

-552 User does not have GRANT privileges for operation 335544553L
-553 Cannot modify an existing user privilege 335544529L
-595 The current position is on a crack 335544645L
-596 Illegal operation when at beginning of stream 335544644L
-597 Preceding file did not specify length, so <string> must include starting
page number
335544632L
-598 Shadow number must be a positive integer 335544633L
-599 Gen.c: node not supported 335544607L
-600 A node name is not permitted in a secondary, shadow, cache or log file
name
335544625L
-600 Sort error: corruption in data structure 335544680L
-601 Database or file exists 335544646L
-604 Array declared with too many dimensions 335544593L
-604 Illegal array dimension range 335544594L
-605 Inappropriate self-reference of column 335544682L
-607 Unsuccessful metadata update 335544351L
-607 Cannot modify or erase a system trigger 335544549L
-607 Array/Blob/DATE/TIME/TIMESTAMP datatypes not allowed in arithmetic 335544657L
-615 Lock on table <string> conflicts with existing lock 335544475L
-615 Requested record lock conflicts with existing lock 335544476L
-615 Refresh range number <long> already in use 335544507L
-616 Cannot delete PRIMARY KEY being used in FOREIGN KEY definition. 335544530L
-616 Cannot delete index used by an integrity constraint 335544539L
-616 Cannot modify index used by an integrity constraint 335544540L

-616 Cannot delete trigger used by a CHECK Constraint 335544541L
-616 Cannot delete column being used in an integrity constraint. 335544543L
-616 There are <long> dependencies 335544630L
-616 Last column in a table cannot be deleted 335544674L
-617 Cannot update trigger used by a CHECK Constraint 335544542L
-617 Cannot rename column being used in an integrity constraint. 335544544L
-618 Cannot delete index segment used by an integrity constraint 335544537L
-618 Cannot update index segment used by an integrity constraint 335544538L
-625 Validation error for column <string>, value "<string>" 335544347L
-637 Duplicate specification of <string> not supported 335544664L
-660 Non-existent PRIMARY or UNIQUE KEY specified for FOREIGN KEY 335544533L
-660 Cannot create index <string> 335544628L
-663 Segment count of 0 defined for index <string> 335544624L
-663 Too many keys defined for index <string> 335544631L
-663 Too few key columns found for index <string> (incorrect column
name?)
335544672L
-664 key size exceeds implementation restriction for index "<string>" 335544434L
-677 <string> extension error 335544445L
-685 Invalid Blob type for operation 335544465L
-685 Attempt to index Blob column in index <string> 335544670L
-685 Attempt to index array column in index <string> 335544671L
-689 Page <long> is of wrong type (expected <long>, found <long>) 335544403L
-689 Wrong page type 335544650L

-690 Segments not allowed in expression index <string> 335544679L
-691 New record size of <long> bytes is too big 335544681L
-692 Maximum indexes per table (<digit>) exceeded 335544477L
-693 Too many concurrent executions of the same request 335544663L
-694 Cannot access column <string> in view <string> 335544684L
-802 Arithmetic exception, numeric overflow, or string truncation 335544321L
-803 Attempt to store duplicate value (visible to active transactions) in
unique index "<string>"
335544349L
-803 Violation of PRIMARY or UNIQUE KEY constraint: "<string>" 335544665L
-804 Wrong number of arguments on call 335544380L
-804 SQLDA missingor incorrectversion, or incorrectnumber/typeof variables 335544583L
-804 Count of columns not equal count of values 335544584L
-804 Function unknown 335544586L
-806 Only simple column names permitted for VIEW WITH CHECK OPTION 335544600L
-807 No where clause for VIEW WITH CHECK OPTION 335544601L
-808 Only one table allowed for VIEW WITH CHECK OPTION 335544602L
-809 DISTINCT, GROUP or HAVING not permitted for VIEW WITH CHECK OPTION 335544603L
-810 No subqueries permitted for VIEW WITH CHECK OPTION 335544605L
-811 Multiple rows in singleton select 335544652L
-816 External file could not be opened for output 335544651L
-817 Attempted update during read-only transaction 335544361L
-817 Attempted write to read-only Blob 335544371L
-817 Operation not supported 335544444L

-820 Metadata is obsolete 335544356L
-820 Unsupportedon-diskstructure for file<string>;found <long>, support
<long>
335544379L
-820 Wrong DYN version 335544437L
-820 Minor version too high found <long> expected <long> 335544467L
-823 Invalid bookmark handle 335544473L
-824 Invalid lock level <digit> 335544474L
-825 Invalid lock handle 335544519L
-826 Invalid statement handle 335544585L
-827 Invalid direction for find operation 335544655L
-828 Invalid key position 335544678L
-829 Invalid column reference 335544616L
-830 Column used with aggregate 335544615L
-831 Attempt to define a second PRIMARY KEY for the same table 335544548L
-832 FOREIGN KEY column count does not match PRIMARY KEY 335544604L
-833 Expression evaluation not supported 335544606L
-834 Refresh range number <long> not found 335544508L
-835 Bad checksum 335544649L
-836 Exception <digit> 335544517L
-837 Restart shared cache manager 335544518L
-838 Database <string> shutdown in <digit> seconds 335544560L
-839 journal file wrong format 335544686L
-840 Intermediate journal file full 335544687L

-841 Too many versions 335544677L
-842 Precision should be greater than 0 335544697L
-842 Scale cannot be greater than precision 335544698L
-842 Short integer expected 335544699L
-842 Long integer expected 335544700L
-842 Unsigned short integer expected 335544701L
-901 Invalid database key 335544322L
-901 Unrecognized database parameter block 335544326L
-901 Invalid Blob handle 335544328L
-901 Invalid Blob ID 335544329L
-901 Invalid parameter in transaction parameter block 335544330L
-901 Invalid format for transaction parameter block 335544331L
-901 Invalid transaction handle (expecting explicit transaction start) 335544332L
-901 Attempt to start more than <long> transactions 335544337L
-901 Information type inappropriate for object specified 335544339L
-901 No information of this type available for object specified 335544340L
-901 Unknown information item 335544341L
-901 Action cancelled by trigger (<long>) to preserve data integrity 335544342L
-901 Lock conflict on no wait transaction 335544345L
-901 Program attempted to exit without finishing database 335544350L
-901 Transaction is not in limbo 335544353L
-901 Blob was not closed 335544355L
-901 Cannot disconnect database with open transactions (<long> active) 335544357L

-901 Message length error (encountered <long>, expected <long>) 335544358L
-901 No transaction for request 335544363L
-901 Request synchronization error 335544364L
-901 Request referenced an unavailable database 335544365L
-901 Attempted read of a new, open Blob 335544369L
-901 Attempted action on blob outside transaction 335544370L
-901 Attempted reference to Blob in unavailable database 335544372L
-901 Table <string> was omitted from the transaction reserving list 335544376L
-901 Request includes a DSRI extension not supported in this
implementation
335544377L
-901 Feature is not supported 335544378L
-901 <string> 335544382L
-901 Unrecoverable conflict with limbo transaction <long> 335544383L
-901 Internal error 335544392L
-901 Database handle not zero 335544407L
-901 Transaction handle not zero 335544408L
-901 Transaction in limbo 335544418L
-901 Transaction not in limbo 335544419L
-901 Transaction outstanding 335544420L
-901 Undefined message number 335544428L
-901 Blocking signal has been received 335544431L
-901 Database system cannot read argument <long> 335544442L
-901 Database system cannot write argument <long> 335544443L

-901 <string> 335544450L
-901 Transaction <long> is <string> 335544468L
-901 Invalid statement handle 335544485L
-901 Lock time-out on wait transaction 335544510L
-901 Invalid service handle 335544559L
-901 Wrong version of service parameter block 335544561L
-901 Unrecognized service parameter block 335544562L
-901 Service <string> is not defined 335544563L
-901 INDEX <string> 335544609L
-901 EXCEPTION <string> 335544610L
-901 Column <string> 335544611L
-901 Union not supported 335544613L
-901 Unsupported DSQL construct 335544614L
-901 Illegal use of keyword VALUE 335544623L
-901 Table <string> 335544626L
-901 Procedure <string> 335544627L
-901 Specified domain or source column does not exist 335544641L
-901 Variable <string> conflicts with parameter in same procedure 335544656L
-901 Server version too old to support all CREATE DATABASE options 335544666L
-901 Cannot delete 335544673L
-901 Sort error 335544675L
-902 Internal isc software consistency check (<string>) 335544333L
-902 Database file appears corrupt (<string>) 335544335L

-902 I/O error during "<string>" operation for file "<string>" 335544344L
-902 Corrupt system table 335544346L
-902 Operating system directive <string> failed 335544373L
-902 Internal error 335544384L
-902 Internal error 335544385L
-902 Internal error 335544387L
-902 Block size exceeds implementation restriction 335544388L
-902 Incompatible version of on-disk structure 335544394L
-902 Internal error 335544397L
-902 Internal error 335544398L
-902 Internal error 335544399L
-902 Internal error 335544400L
-902 Internal error 335544401L
-902 Internal error 335544402L
-902 Database corrupted 335544404L
-902 Checksum error on database page <long> 335544405L
-902 Index is broken 335544406L
-902 Transaction--request mismatch (synchronization error) 335544409L
-902 Bad handle count 335544410L
-902 Wrong version of transaction parameter block 335544411L
-902 Unsupported BLR version (expected <long>, encountered <long>) 335544412L
-902 Wrong version of database parameter block 335544413L
-902 Database corrupted 335544415L

-902 Internal error 335544416L
-902 Internal error 335544417L
-902 Internal error 335544422L
-902 Internal error 335544423L
-902 Lock manager error 335544432L
-902 SQL error code = <long> 335544436L
-902 335544448L
-902 335544449L
-902 Cache buffer for page <long> invalid 335544470L
-902 There is no index in table <string> with id <digit> 335544471L
-902 Your user name and password are not defined. Ask your database
administrator to set up an InterBase login.
335544472L
-902 Enable journal for database before starting online dump 335544478L
-902 Online dump failure. Retry dump 335544479L
-902 An online dump is already in progress 335544480L
-902 No more disk/tape space. Cannot continue online dump 335544481L
-902 Maximum number of online dump files that can be specified is 16 335544483L
-902 Database <string> shutdown in progress 335544506L
-902 Long-term journaling already enabled 335544520L
-902 Database <string> shutdown 335544528L
-902 Database shutdown unsuccessful 335544557L
-902 Cannot attach to password database 335544653L
-902 Cannot start transaction for password database 335544654L

-902 Long-term journaling not enabled 335544564L
-902 Dynamic SQL Error 335544569L
-904 Invalid database handle (no active connection) 335544324L
-904 Unavailable database 335544375L
-904 Implementation limit exceeded 335544381L
-904 Too many requests 335544386L
-904 Buffer exhausted 335544389L
-904 Buffer in use 335544391L
-904 Request in use 335544393L
-904 No lock manager available 335544424L
-904 Unable to allocate memory from operating system 335544430L
-904 Update conflicts with concurrent update 335544451L
-904 Object <string> is in use 335544453L
-904 Cannot attach active shadow file 335544455L
-904 A file in manual shadow <long> is unavailable 335544460L
-904 Cannot add index, index root page is full. 335544661L
-904 Sort error: not enough memory 335544676L
-904 Request depth exceeded. (Recursive definition?) 335544683L
-906 Product <string> is not licensed 335544452L
-909 Drop database completed with errors 335544667L
-911 Record from transaction <long> is stuck in limbo 335544459L
-913 Deadlock 335544336L
-922 File <string> is not a valid database 335544323L

-923 Connection rejected by remote interface 335544421L
-923 Secondary server attachments cannot validate databases 335544461L
-923 Secondary server attachments cannot start journaling 335544462L
-924 Bad parameters on attach or create database 335544325L
-924 Database detach completed with errors 335544441L
-924 Connection lost to pipe server 335544648L
-926 No rollback performed 335544447L
-999 InterBase error 335544689L
  }
end.

