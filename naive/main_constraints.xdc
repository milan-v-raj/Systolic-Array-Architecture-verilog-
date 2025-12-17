# main_constraints.xdc for a Digilent Basys 3 Board

# --- Clock Signal ---
# This connects your 'clk' port to the main 100MHz clock on the board (pin W5)
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
# This line is CRITICAL: It tells the timing analyzer that 'clk' is a 100MHz clock
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} [get_ports clk]

# --- Input Signals (Switches) ---
# This connects your 'start' port to switch 0 (SW0)
set_property PACKAGE_PIN V17 [get_ports start]
set_property IOSTANDARD LVCMOS33 [get_ports start]

# This connects your 'rst' port to switch 1 (SW1)
set_property PACKAGE_PIN V16 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]

# --- Output Signal (LED) ---
# This connects your 'done' port to LED 0 (LD0)
set_property PACKAGE_PIN U16 [get_ports done]
set_property IOSTANDARD LVCMOS33 [get_ports done]