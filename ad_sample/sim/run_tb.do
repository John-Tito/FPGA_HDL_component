do compile.do


#退出仿真，清空命令行
quit -sim
.main clear

#开始仿真
vsim -L axi4stream_vip_v1_1_4 -L axi_vip_v1_1_4 -L xilinx_vip -t ps -novopt work.sc_hdlc_v1_0_tb

set NoQuitOnFinish 1
onbreak {resume}
log /* -r

#添加波形
add wave -position insertpoint -radix hex -group S_AXI sim:/sc_hdlc_v1_0_tb/sc_hdlc_0/sc_hdlc_v1_0_S_AXI_inst/*
add wave -position insertpoint -radix hex -group M_AXIS sim:/sc_hdlc_v1_0_tb/sc_hdlc_0/sc_hdlc_v1_0_M_AXIS_inst/*
add wave -position insertpoint -radix hex -group S_AXIS sim:/sc_hdlc_v1_0_tb/sc_hdlc_0/sc_hdlc_v1_0_S_AXIS_inst/*
add wave -position insertpoint -radix hex -group TX sim:/sc_hdlc_v1_0_tb/sc_hdlc_0/HDLC_TOP_dut/HDLC_TRANSMIT_dut/*
add wave -position insertpoint -radix hex -group RX sim:/sc_hdlc_v1_0_tb/sc_hdlc_0/HDLC_TOP_dut/HDLC_RECEIVE_dut/*
add wave -position insertpoint -radix hex -group RX_FIFO sim:/sc_hdlc_v1_0_tb/sc_hdlc_0/g_user_fifo/fifo_single_clock_reg_v2_dut/*
add wave -position insertpoint -radix hex -group TX_FIFO sim:/sc_hdlc_v1_0_tb/sc_hdlc_0/g_user_fifo/fifo_single_clock_reg_v2_dut1/*

run 100 us
