# Set the reference directory for source file relative paths (by default the value is script directory path)
set origin_dir "."

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}
# Set 'sources_1' fileset object
set obj [get_filesets sources_1]

set files [glob ${origin_dir}/../src/*.v]
add_files -norecurse -fileset $obj $files
set_property source_mgmt_mode All [current_project]

if { [get_ips ad574_ila] == "" } {
  create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name ad574_ila
  set_property -dict [list CONFIG.C_PROBE4_WIDTH {12} CONFIG.C_PROBE0_WIDTH {2} CONFIG.C_NUM_OF_PROBES {5} CONFIG.Component_Name {ad574_ila}] [get_ips ad574_ila]
}