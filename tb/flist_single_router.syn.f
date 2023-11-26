+incdir+$PROJ_ROOT/rtl/rvh_noc/rtl/include
+incdir+$PROJ_ROOT/rtl/rvh_noc/tb

$PROJ_ROOT/rtl/rvh_noc/rtl/include/rvh_noc_pkg.sv

$PROJ_ROOT/$L1D_ROOT/models/cells/std_dffe.sv
$PROJ_ROOT/$L1D_ROOT/models/cells/std_dffr.sv
$PROJ_ROOT/$L1D_ROOT/models/cells/std_dffre.sv
$PROJ_ROOT/$L1D_ROOT/models/cells/std_dffrve.sv

$PROJ_ROOT/rtl/util/usage_manager.sv
$PROJ_ROOT/rtl/util/mp_fifo.sv
$PROJ_ROOT/rtl/util/mp_fifo_ptr_output.sv
$PROJ_ROOT/rtl/util/sp_fifo_dat_vld_output.sv
$PROJ_ROOT/rtl/util/one_counter.sv
$PROJ_ROOT/rtl/util/priority_encoder.sv
$PROJ_ROOT/rtl/util/onehot_mux.sv
$PROJ_ROOT/rtl/util/one_hot_priority_encoder.sv
$PROJ_ROOT/rtl/util/left_circular_rotate.sv
$PROJ_ROOT/rtl/util/oh2idx.sv
$PROJ_ROOT/rtl/util/one_hot_rr_arb.sv
$PROJ_ROOT/rtl/util/select_two_from_n_valid.sv
$PROJ_ROOT/rtl/util/freelist.sv

$PROJ_ROOT/rtl/util/commoncell/src/Basic/hw/MuxOH.v
$PROJ_ROOT/rtl/util/commoncell/src/Queue/hw/AgeMatrixSelector.v

// TODO: need to change to compiled dpsram
$PROJ_ROOT/rtl/rvh_noc/rtl/model/simple_dual_one_clock.v

$PROJ_ROOT/rtl/rvh_noc/rtl/input_port.sv
$PROJ_ROOT/rtl/rvh_noc/rtl/look_adead_routing.sv
$PROJ_ROOT/rtl/rvh_noc/rtl/output_port_vc_selection.sv
$PROJ_ROOT/rtl/rvh_noc/rtl/input_port_vc.sv
$PROJ_ROOT/rtl/rvh_noc/rtl/output_port_vc_assignment.sv
$PROJ_ROOT/rtl/rvh_noc/rtl/priority_req_select.sv
$PROJ_ROOT/rtl/rvh_noc/rtl/sa_global.sv
$PROJ_ROOT/rtl/rvh_noc/rtl/switch.sv
$PROJ_ROOT/rtl/rvh_noc/rtl/input_port_flit_decoder.sv
$PROJ_ROOT/rtl/rvh_noc/rtl/input_to_output.sv
$PROJ_ROOT/rtl/rvh_noc/rtl/output_port_vc_credit_counter.sv
$PROJ_ROOT/rtl/rvh_noc/rtl/sa_local.sv
$PROJ_ROOT/rtl/rvh_noc/rtl/performance_monitor.sv
$PROJ_ROOT/rtl/rvh_noc/rtl/vnet_router.sv

$PROJ_ROOT/rtl/rvh_noc/tb/top_single_router_syn.sv  
// $PROJ_ROOT/rtl/rvh_noc/tb/testbench.sv
