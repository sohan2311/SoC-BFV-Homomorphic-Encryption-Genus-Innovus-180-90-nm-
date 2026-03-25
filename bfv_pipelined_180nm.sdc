# ==============================================================================
# BFV SoC - Pipelined Logical & Physical Constraints (SDC)
# Target Frequency: 100 MHz (10.0 ns period)
# ==============================================================================

# 1. Clock Definition
create_clock -name clk -period 10.0 [get_ports clk]

# 2. Clock Imperfections (Aggressive for 180nm setup optimization)
set_clock_uncertainty -setup 0.2 [get_clocks clk]
set_clock_uncertainty -hold 0.1 [get_clocks clk]
set_clock_transition 0.2 [get_clocks clk]

# 3. I/O Delays (Tightened to give internal logic more time)
set_input_delay 0.5 -max -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
set_input_delay 0.1 -min -clock clk [remove_from_collection [all_inputs] [get_ports clk]]

set_output_delay 0.5 -max -clock clk [all_outputs]
set_output_delay 0.1 -min -clock clk [all_outputs]

# 4. Electrical Design Rules (DRVs)
set_input_transition 0.5 [all_inputs]
set_load 2.0 [all_outputs]