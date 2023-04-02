
#退出仿真，清空命令行
quit -sim
.main clear


set MODEL_TECH D:/ProgramFiles/EDA/modeltech_10.1a/win32
set UVM_HOME $MODEL_TECH/../verilog_src/uvm-1.1a
set UVM_DPI_HOME $MODEL_TECH/../uvm-1.1a/win32
set WORK_HOME .
set TB_HOME ./../testbench
set LIB_HOME ./lib/work

if { ![file isdirectory $LIB_HOME] } {
    vdel -all
    file mkdir $LIB_HOME
}

vlib $LIB_HOME
vmap work $LIB_HOME

#源文件列表
set list {
    ../src/hdlc_core/HDLC_RECEIVE.v
    ../src/hdlc_core/HDLC_RX_FLAG_CHECKER.v
    ../src/hdlc_core/HDLC_RX_SHIFT.v
    ../src/hdlc_core/HDLC_RX_ZREO_DELETE.v
    ../src/hdlc_core/HDLC_SERIAL_CRC.v
    ../src/hdlc_core/HDLC_TOP.v
    ../src/hdlc_core/HDLC_TRANSMIT.v
    ../src/hdlc_core/RX_OVS.v
    ../src/hdlc_core/TX_DIV.v
    ../src/sc_hdlc_v1_0_M_AXIS.v
    ../src/sc_hdlc_v1_0_S_AXI.v
    ../src/sc_hdlc_v1_0_S_AXIS.v
    ../src/sc_hdlc_v1_0.v
    ../src/fifo_sync_8to8_rx/sim/fifo_sync_8to8_rx.v
    ../src/fifo_sync_8to8_tx/sim/fifo_sync_8to8_tx.v
    ../sim/fifo_single_clock_reg_v2_init.svh
    ../sim/fifo_single_clock_reg_v2.sv
    ../sim/axi4stream_vip_1/sim/axi4stream_vip_1_pkg.sv
    ../sim/axi4stream_vip_1/sim/axi4stream_vip_1.sv
    ../sim/axi4stream_vip_0/sim/axi4stream_vip_0_pkg.sv
    ../sim/axi4stream_vip_0/sim/axi4stream_vip_0.sv
    ../sim/axi_vip_0/sim/axi_vip_0_pkg.sv
    ../sim/axi_vip_0/sim/axi_vip_0.sv
    ../sim/sc_hdlc_v1_0_tb.sv
}

proc compile_file { file_name file_type } {
    set MODEL_TECH D:/EDA/modeltech_10.1a/win32
    set UVM_HOME $MODEL_TECH/../verilog_src/uvm-1.1a
    set UVM_DPI_HOME $MODEL_TECH/../uvm-1.1a/win32
    set WORK_HOME .
    set TB_HOME ./../testbench
    set LIB_HOME ./lib/work

    puts $file_name
    if { [string equal $file_type ".vhd"] } {
        # 编译VHDL文件
        vcom -work work $file_name
    } elseif { [string equal $file_type ".v"]} {
        # 编译 verilog 文件
        #vlog -work work +incdir+$WORK_HOME +incdir+$UVM_HOME/src +incdir+$TB_HOME -L mtiAvm -L mtiOvm -L mtiUvm -L mtiUPF $file_name
        vlog -64 -incr -L axi4stream_vip_v1_1_4 -L axi_vip_v1_1_4 -L xilinx_vip -work work \
            +incdir+../src \
            +incdir+../src/hdlc_core \
            +incdir+../sim \
            +incdir+../sim/axi_vip_0/hdl \
            +incdir+../sim/axi4stream_vip_0/hdl \
            +incdir+../sim/axi4stream_vip_1/hdl \
            +incdir+D:/ProgramFiles/EDA/Xilinx/Vivado/2018.3/data/xilinx_vip/include \
            $file_name

    } elseif { [string equal $file_type ".sv"] } {

        vlog -64 -incr -sv -L axi4stream_vip_v1_1_4 -L axi_vip_v1_1_4 -L xilinx_vip -work work \
            +incdir+../src \
            +incdir+../src/hdlc_core \
            +incdir+../sim \
            +incdir+../sim/axi_vip_0/hdl \
            +incdir+../sim/axi4stream_vip_0/hdl \
            +incdir+../sim/axi4stream_vip_1/hdl \
            +incdir+D:/ProgramFiles/EDA/Xilinx/Vivado/2018.3/data/xilinx_vip/include \
            $file_name

    } elseif { [string equal $file_type ".c"] } {
        # 编译 verilog 文件
        vlog $file_name
    }
}
.main clear

# vcs -timescale=1ns/1ns +vcs+flush+all +warn=all -sverilog my_dpi.cc

foreach v $list {
    #补全文件路径，相对路径
    set file_path $WORK_HOME/$v
    #获取文件名，不含路径和后缀
    set file_name [file rootname [file tail $file_path]]
    #获取文件后缀并转换为小写,方便进行比较
    set file_ext_name [string tolower [file extension $file_path]]
    #获取编译后的库文件位置
    set file_lib_path $LIB_HOME/$file_name

    if { [file exists $file_path] } {

        if {![file isdirectory $file_lib_path]} {
            #若库文件不存在则直接编译
            compile_file $file_path $file_ext_name
        } else {

            #若库文件已存在则比较时间
            set new_time [file mtime $file_path]
            set old_time [file mtime $file_lib_path]

            # if { $new_time > $old_time } {
            #     #若文件被修改则执行编译
            compile_file $file_path $file_ext_name
            # } else {
            #     #否则跳过编译
            #     puts "skip $file_path"
            # }
        }

    } else {
        puts "*************** file $file_path not found ***************"
    }
}

vlog -64 -incr -work axis_infrastructure_v1_1_0 \
    +incdir+../src \
    +incdir+../src/hdlc_core \
    +incdir+../sim \
    +incdir+../sim/axi_vip_0/hdl \
    +incdir+../sim/axi4stream_vip_0/hdl \
    +incdir+D:/ProgramFiles/EDA/Xilinx/Vivado/2018.3/data/xilinx_vip/include \
    ../sim/axi4stream_vip_0/hdl/axis_infrastructure_v1_1_vl_rfs.v

vlog -64 -incr -sv -L axi4stream_vip_v1_1_4 -L axi_vip_v1_1_4 -L xilinx_vip -work axi4stream_vip_v1_1_4 \
    +incdir+../src \
    +incdir+../src/hdlc_core \
    +incdir+../sim \
    +incdir+../sim/axi_vip_0/hdl \
    +incdir+../sim/axi4stream_vip_0/hdl \
    +incdir+D:/ProgramFiles/EDA/Xilinx/Vivado/2018.3/data/xilinx_vip/include \
    ../sim/axi4stream_vip_0/hdl/axi4stream_vip_v1_1_vl_rfs.sv

vlog -64 -incr -work axi_infrastructure_v1_1_0 \
    +incdir+../src \
    +incdir+../src/hdlc_core \
    +incdir+../sim \
    +incdir+../sim/axi_vip_0/hdl \
    +incdir+../sim/axi4stream_vip_0/hdl \
    +incdir+D:/ProgramFiles/EDA/Xilinx/Vivado/2018.3/data/xilinx_vip/include \
    ../sim/axi_vip_0/hdl/axi_infrastructure_v1_1_vl_rfs.v


vlog -64 -incr -sv -L axi4stream_vip_v1_1_4 -L axi_vip_v1_1_4 -L xilinx_vip -work axi_vip_v1_1_4 \
    +incdir+../src \
    +incdir+../src/hdlc_core \
    +incdir+../sim \
    +incdir+../sim/axi_vip_0/hdl \
    +incdir+../sim/axi4stream_vip_0/hdl \
    +incdir+D:/ProgramFiles/EDA/Xilinx/Vivado/2018.3/data/xilinx_vip/include \
    ../sim/axi_vip_0/hdl/axi_vip_v1_1_vl_rfs.sv


# compile glbl module
vlog -work work "glbl.v"


puts "*************** compile finished ***************"
