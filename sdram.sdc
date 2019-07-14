derive_pll_clocks

create_generated_clock -name SDRAM_CLK -source [get_pins -compatibility_mode {*|pll|pll_inst|altera_pll_i|*[1].*|divclk}] [get_ports {SDRAM_CLK}]

derive_clock_uncertainty

# Set acceptable delays for SDRAM chip (See correspondent chip datasheet) 
set_input_delay -max -clock SDRAM_CLK 6.4ns [get_ports SDRAM_DQ[*]]
set_input_delay -min -clock SDRAM_CLK 3.7ns [get_ports SDRAM_DQ[*]]
set_output_delay -max -clock SDRAM_CLK 1.6ns [get_ports {SDRAM_D* SDRAM_A* SDRAM_BA* SDRAM_n* SDRAM_CKE}]
set_output_delay -min -clock SDRAM_CLK -0.9ns [get_ports {SDRAM_D* SDRAM_A* SDRAM_BA* SDRAM_n* SDRAM_CKE}]
