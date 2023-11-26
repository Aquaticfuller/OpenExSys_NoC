+incdir+$PROJ_ROOT/rtl/include
+incdir+$PROJ_ROOT/tb

$PROJ_ROOT/rtl/include/rvh_noc_pkg.sv

$PROJ_ROOT/rtl/model/cells/std_dffe.sv
$PROJ_ROOT/rtl/model/cells/std_dffr.sv
$PROJ_ROOT/rtl/model/cells/std_dffre.sv
$PROJ_ROOT/rtl/model/cells/std_dffrve.sv

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
$PROJ_ROOT/rtl/rtl/model/simple_dual_one_clock.v

$PROJ_ROOT/rtl/input_port.sv
$PROJ_ROOT/rtl/look_adead_routing.sv
$PROJ_ROOT/rtl/output_port_vc_selection.sv
$PROJ_ROOT/rtl/input_port_vc.sv
$PROJ_ROOT/rtl/output_port_vc_assignment.sv
$PROJ_ROOT/rtl/priority_req_select.sv
$PROJ_ROOT/rtl/sa_global.sv
$PROJ_ROOT/rtl/switch.sv
$PROJ_ROOT/rtl/input_port_flit_decoder.sv
$PROJ_ROOT/rtl/input_to_output.sv
$PROJ_ROOT/rtl/output_port_vc_credit_counter.sv
$PROJ_ROOT/rtl/sa_local.sv
$PROJ_ROOT/rtl/performance_monitor.sv
$PROJ_ROOT/rtl/vnet_router.sv

$PROJ_ROOT/tb/top_mesh_syn.sv  
// $PROJ_ROOT/tb/testbench.sv
