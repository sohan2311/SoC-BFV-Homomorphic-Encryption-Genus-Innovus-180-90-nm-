# ==============================================================================
# Cadence Genus Synthesis Script - Pipelined BFV Core (180nm)
# ==============================================================================

# Setup 180nm Library Paths
set_db init_lib_search_path /home/install/FOUNDRY/digital/180nm/dig/lib/
set_db library slow.lib

# Read the Verilog files in bottom-up dependency order
read_hdl {
    bfv_mod_adder.v
    bfv_mod_mult.v
    bfv_keygen.v
    bfv_encrypt_core.v
    bfv_top.v
}

# Elaborate your top-level module
elaborate bfv_top

# Apply the optimized constraints
read_sdc ./bfv_pipelined_180nm.sdc

# Power optimization goals
set_max_leakage_power 0.0
set_max_dynamic_power 0.0

# Synthesis effort levels
set_db syn_generic_effort high
set_db syn_map_effort high
set_db syn_opt_effort high

# Run Synthesis
syn_generic
syn_map
syn_opt

# Export 180nm Netlist and physical constraints for Innovus
write_hdl > bfv_180nm_pipelined_netlist.v
write_sdc > bfv_180nm_pipelined_output.sdc

# Generate 180nm Reports
report timing > bfv_180nm_pipelined_timing.rpt
report power  > bfv_180nm_pipelined_power.rpt
report area   > bfv_180nm_pipelined_area.rpt
report gates  > bfv_180nm_pipelined_gates.rpt

# Open the GUI to inspect the schematic
gui_show