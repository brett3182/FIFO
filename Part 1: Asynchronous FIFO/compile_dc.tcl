#/**************************************************/
#/* Compile Script for Synopsys                    */
#/*                                                */
#/* dc_shell-t -f compile_dc.tcl                   */
#/*                                                */
#/* OSU FreePDK 45nm                               */
#/**************************************************/

# All verilog files, separated by spaces         
set my_verilog_files [list ../fifo_memory.sv ../fifo_read.sv ../fifo_sync_r2w.sv ../fifo_sync_w2r.sv ../fifo_write.sv ../fifo_top.sv]

# Top-level Module                              
set my_toplevel   fifo_top

# Clock pins and their frequencies (MHz)
# Added two clock: write and read
# Max. frequency with 0 or positive slack is 1600MHz and 800MHz for write and read clock respectively.         
set my_clock_pins [list wclk rclk]
set my_clk_freq_MHz [list 1600 800]

# Delay of input signals (Clock-to-Q, Package etc.)
set my_input_delay_ns 0.1

# Reserved time for output signals (Holdtime etc.)
set my_output_delay_ns 0.1

#/**************************************************/
#/* No modifications needed below                  */
#/**************************************************/
set OSU_FREEPDK [format "%s%s"  [getenv "PDK_DIR"] "/osu_soc/lib/files"]
set search_path [concat  $search_path $OSU_FREEPDK]
set alib_library_analysis_path $OSU_FREEPDK

set link_library [set target_library [concat  [list gscl45nm.db] [list dw_foundation.sldb]]]
set target_library "gscl45nm.db"
define_design_lib WORK -path ./WORK
set verilogout_show_unconnected_pins "true"
set_ultra_optimization true
set_ultra_optimization -force

analyze -f sverilog $my_verilog_files

elaborate $my_toplevel

current_design $my_toplevel

link
uniquify

# Create both clocks (FIXED)
foreach {clk_pin freq} [list wclk 1600 rclk 800] {
    set clk_period [expr 1000.0 / $freq]
    if {[llength [find port $clk_pin]] > 0} {
        create_clock -period $clk_period -name $clk_pin [get_ports $clk_pin]
    } else {
        create_clock -period $clk_period -name $clk_pin
    }
}

# Mark clocks as asynchronous (FIXED NAME)
set_clock_groups -asynchronous -group [get_clocks wclk] -group [get_clocks rclk]

set_driving_cell -lib_cell INVX1 [all_inputs]

# Constrain non-clock inputs/outputs (FIXED)
set non_clock_inputs [remove_from_collection [all_inputs] [get_ports "$my_clock_pins"]]
foreach clk $my_clock_pins {
    set_input_delay $my_input_delay_ns -clock $clk $non_clock_inputs
    set_output_delay $my_output_delay_ns -clock $clk [all_outputs]
}

compile -ungroup_all -map_effort medium
compile -incremental_mapping -map_effort medium

check_design
report_constraint -all_violators

# Uncomment to write outputs
# write -f verilog -output $my_toplevel.vh
# write_sdc $my_toplevel.sdc
# write -f db -hier -output $my_toplevel.db

redirect timing.rep { report_timing }
redirect cell.rep { report_cell }
redirect power.rep { report_power }
redirect area.rep { report_area }

quit
