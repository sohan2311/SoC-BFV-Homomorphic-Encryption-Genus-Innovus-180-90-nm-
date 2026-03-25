# ==============================================================================
# Cadence Genus Synthesis Script - Pipelined BFV Core (90nm)
# ==============================================================================

# Setup 90nm Library Paths
set_db init_lib_search_path /home/install/FOUNDRY/digital/90nm/dig/lib/
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

# Apply the 90nm optimized constraints
read_sdc ./bfv_pipelined_90nm.sdc

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

# Export 90nm Netlist and physical constraints for Innovus
write_hdl > bfv_90nm_pipelined_netlist.v
write_sdc > bfv_90nm_pipelined_output.sdc

# Generate 90nm Reports
report timing > bfv_90nm_pipelined_timing.rpt
report power  > bfv_90nm_pipelined_power.rpt
report area   > bfv_90nm_pipelined_area.rpt
report gates  > bfv_90nm_pipelined_gates.rpt

# Open the GUI to inspect the schematic
gui_show
