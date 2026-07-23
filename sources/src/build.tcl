# rebuild.tcl
# Usage (Vivado Tcl console):
#   source rebuild.tcl
#
# This resets synth/impl/bitstream runs and rebuilds from scratch.

proc rebuild_bitstream {} {
    # Use the active project
    if {[llength [get_projects -quiet]] == 0} {
        error "No project is open. Open the .xpr first, then 'source rebuild.tcl'."
    }

    # Try to locate the standard runs (Vivado default names)
    set synth_run "synth_1"
    set impl_run  "impl_1"

    if {[llength [get_runs -quiet $synth_run]] == 0} {
        error "Run '$synth_run' not found. Check your run names (get_runs)."
    }
    if {[llength [get_runs -quiet $impl_run]] == 0} {
        error "Run '$impl_run' not found. Check your run names (get_runs)."
    }

    # Disable incremental flows (if enabled)
    catch { set_property INCREMENTAL_SYNTHESIS false [get_runs $synth_run] }
    catch { set_property INCREMENTAL_ROUTING false   [get_runs $impl_run] }
    catch { set_property INCREMENTAL_IMPLEMENTATION false [get_runs $impl_run] }

    puts "Resetting runs..."
    reset_run $impl_run
    reset_run $synth_run

    # Synthesis
    puts "Running synthesis..."
    launch_runs $synth_run -jobs 8
    wait_on_run $synth_run

    # Implementation (this also generates the bitstream if the impl run is configured to do so,
    # but we explicitly launch to write_bitstream below for clarity)
    puts "Running implementation..."
    launch_runs $impl_run -jobs 8
    wait_on_run $impl_run

    # Bitstream
    puts "Generating bitstream..."
    launch_runs $impl_run -to_step write_bitstream -jobs 8
    wait_on_run $impl_run

    # Report bit file path
    set bitfile [get_property BITSTREAM.FILE [get_runs $impl_run]]
    puts "DONE. Bitstream: $bitfile"
}

rebuild_bitstream
