# Set the reference directory for source file relative paths (by default the value is script directory path)
set origin_dir "."

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}
# Set 'sources_1' fileset object
set obj [get_filesets sources_1]

set files [concat [glob ${origin_dir}/../src/hdlc_core/*.v] [glob ${origin_dir}/../src/*.v]]
add_files -norecurse -fileset $obj $files
set_property source_mgmt_mode All [current_project]

if { [get_ips hdlc_pkt_info_fifo] == "" } {
  create_ip -name axis_data_fifo -vendor xilinx.com -library ip -version 2.0 -module_name hdlc_pkt_info_fifo
  set_property -dict [list\
    CONFIG.TDATA_NUM_BYTES {4}\
    CONFIG.FIFO_DEPTH {64}\
    CONFIG.HAS_RD_DATA_COUNT {1}\
    CONFIG.HAS_AFULL {0}\
    CONFIG.HAS_PROG_FULL {1}\
    CONFIG.PROG_FULL_THRESH {59}\
  ] [get_ips hdlc_pkt_info_fifo]
}

if { [get_ips hdlc_axis_fifo] == "" } {
  create_ip -name axis_data_fifo -vendor xilinx.com -library ip -version 2.0 -module_name hdlc_axis_fifo
  set_property -dict [list\
    CONFIG.TID_WIDTH {5}\
    CONFIG.TDEST_WIDTH {5}\
    CONFIG.TUSER_WIDTH {1}\
    CONFIG.FIFO_DEPTH {4096}\
    CONFIG.FIFO_MODE {2}\
    CONFIG.HAS_TKEEP {1}\
    CONFIG.HAS_TLAST {1}\
    CONFIG.HAS_WR_DATA_COUNT {1}\
    CONFIG.HAS_RD_DATA_COUNT {1}\
    CONFIG.HAS_AFULL {0}\
    CONFIG.HAS_PROG_FULL {1}\
    CONFIG.PROG_FULL_THRESH {4091}\
  ] [get_ips hdlc_axis_fifo]
}

if { [get_ips axis_8_ila] == "" } {
  create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name axis_8_ila
  set_property -dict [list\
    CONFIG.C_NUM_OF_PROBES {9}\
    CONFIG.C_SLOT_0_AXI_PROTOCOL {AXI4S}\
    CONFIG.C_SLOT_0_AXIS_TDATA_WIDTH {8}\
    CONFIG.C_SLOT_0_AXIS_TID_WIDTH {5}\
    CONFIG.C_SLOT_0_AXIS_TUSER_WIDTH {1}\
    CONFIG.C_SLOT_0_AXIS_TDEST_WIDTH {5}\
    CONFIG.C_ENABLE_ILA_AXI_MON {true}\
    CONFIG.C_MONITOR_TYPE {AXI}\
  ] [get_ips axis_8_ila]
}

if { [get_ips ila_hdlc] == "" } {
  create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name ila_hdlc
  set_property -dict [list CONFIG.C_PROBE14_WIDTH {32}\
    CONFIG.C_PROBE13_WIDTH {32}\
    CONFIG.C_PROBE6_WIDTH {9}\
    CONFIG.C_PROBE3_WIDTH {8}\
    CONFIG.C_NUM_OF_PROBES {22}\
  ] [get_ips ila_hdlc]
}
