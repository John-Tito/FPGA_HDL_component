#add_to_project
namespace eval adc_sample {

  ##################################################################
  # CHECK VIVADO VERSION
  ##################################################################
  set scripts_vivado_version 2018.3
  set current_vivado_version [version -short]

  if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
    catch {common::send_msg_id "IPS_TCL-100" "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_ip_tcl to create an updated script."}
    return 1
  }

  ##################################################################
  # START
  ##################################################################
  set list_projs [get_projects -quiet]
  if { $list_projs eq "" } {
    return 1
  }

  ##################################################################
  # CHECK IPs
  ##################################################################

  set bCheckIPs 1
  set bCheckIPsPassed 1
  if { $bCheckIPs == 1 } {
    set list_check_ips {
      xilinx.com:ip:fifo_generator:13.2
      xilinx.com:ip:ila:6.2
      xilinx.com:ip:axis_data_fifo:2.0
      xilinx.com:ip:axis_dwidth_converter:1.1
    }

    set list_ips_missing ""
    common::send_msg_id "IPS_TCL-1001" "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

    foreach ip_vlnv $list_check_ips {
    set ip_obj [get_ipdefs -all $ip_vlnv]
    if { $ip_obj eq "" } {
      lappend list_ips_missing $ip_vlnv
      }
    }

    if { $list_ips_missing ne "" } {
      catch {common::send_msg_id "IPS_TCL-105" "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
    }
  }

  if { $bCheckIPsPassed != 1 } {
    common::send_msg_id "IPS_TCL-102" "WARNING" "Will not continue with creation of design due to the error(s) above."
    return 1
  }

  ##################################################################
  # CREATE IP sample_axis_data_fifo
  ##################################################################

  set axis_data_fifo sample_data_fifo
  create_ip -name axis_data_fifo -vendor xilinx.com -library ip -version 2.0 -module_name $axis_data_fifo

  set_property -dict {
    CONFIG.TDATA_NUM_BYTES {16}
    CONFIG.FIFO_DEPTH {512}
    CONFIG.HAS_TSTRB {0}
    CONFIG.HAS_TKEEP {1}
    CONFIG.HAS_TLAST {1}
    CONFIG.HAS_AEMPTY {1}
    CONFIG.HAS_AFULL {1}
  } [get_ips $axis_data_fifo]

  ##################################################################

  ##################################################################
  # CREATE IP sample_axis_dwidth_converter
  ##################################################################

  set axis_dwidth_converter sample_dw_conv
  create_ip -name axis_dwidth_converter -vendor xilinx.com -library ip -version 1.1 -module_name $axis_dwidth_converter

  set_property -dict {
    CONFIG.S_TDATA_NUM_BYTES {16}
    CONFIG.M_TDATA_NUM_BYTES {64}
    CONFIG.HAS_TLAST {1}
    CONFIG.HAS_TKEEP {1}
    CONFIG.HAS_MI_TKEEP {1}
  } [get_ips $axis_dwidth_converter]

  ##################################################################

  ##################################################################
  # CREATE IP sample_ila_0
  ##################################################################

  set ila sample_ila_0
  create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name $ila

  set_property -dict {
    CONFIG.C_PROBE32_WIDTH {1}
    CONFIG.C_PROBE30_WIDTH {1}
    CONFIG.C_PROBE29_WIDTH {1}
    CONFIG.C_PROBE28_WIDTH {1}
    CONFIG.C_PROBE27_WIDTH {1}
    CONFIG.C_PROBE26_WIDTH {1}
    CONFIG.C_PROBE25_WIDTH {1}
    CONFIG.C_PROBE23_WIDTH {16}
    CONFIG.C_PROBE22_WIDTH {1}
    CONFIG.C_PROBE21_WIDTH {16}
    CONFIG.C_PROBE20_WIDTH {1}
    CONFIG.C_PROBE19_WIDTH {1}
    CONFIG.C_PROBE18_WIDTH {1}
    CONFIG.C_PROBE17_WIDTH {1}
    CONFIG.C_PROBE15_WIDTH {1}
    CONFIG.C_PROBE14_WIDTH {1}
    CONFIG.C_PROBE13_WIDTH {32}
    CONFIG.C_PROBE12_WIDTH {1}
    CONFIG.C_PROBE11_WIDTH {1}
    CONFIG.C_PROBE10_WIDTH {8}
    CONFIG.C_PROBE9_WIDTH {8}
    CONFIG.C_PROBE8_WIDTH {32}
    CONFIG.C_PROBE7_WIDTH {32}
    CONFIG.C_NUM_OF_PROBES {24}
  } [get_ips $ila]

  ##################################################################

  ##################################################################
  # CREATE IP sample_pkt_info_fifo
  ##################################################################

  set fifo_generator sample_pkt_info_fifo
  create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name $fifo_generator

  set_property -dict {
    CONFIG.Input_Data_Width {64}
    CONFIG.Input_Depth {64}
    CONFIG.Output_Data_Width {64}
    CONFIG.Output_Depth {64}
    CONFIG.Reset_Pin {true}
    CONFIG.Reset_Type {Synchronous_Reset}
    CONFIG.Full_Flags_Reset_Value {0}
    CONFIG.Use_Dout_Reset {true}
    CONFIG.Almost_Full_Flag {true}
    CONFIG.Almost_Empty_Flag {true}
    CONFIG.Data_Count_Width {6}
    CONFIG.Write_Data_Count_Width {6}
    CONFIG.Read_Data_Count_Width {6}
    CONFIG.Full_Threshold_Assert_Value {62}
    CONFIG.Full_Threshold_Negate_Value {61}
    CONFIG.Enable_Safety_Circuit {false}
  } [get_ips $fifo_generator]

  ##################################################################
  add_files [ glob ../src/*.v]
}