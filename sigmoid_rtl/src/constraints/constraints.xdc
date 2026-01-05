
create_clock -period 5.2 -name clk -waveform {0.000 2.6} [get_ports clk]

if 0 {
    set_input_delay -clock [get_clocks clk] -min -add_delay 0.100 [get_ports {data_in[*]}]
    set_input_delay -clock [get_clocks clk] -max -add_delay 0.150 [get_ports {data_in[*]}]
    set_input_delay -clock [get_clocks clk] -min -add_delay 0.100 [get_ports rst]
    set_input_delay -clock [get_clocks clk] -max -add_delay 0.150 [get_ports rst]
    set_input_delay -clock [get_clocks clk] -min -add_delay 0.100 [get_ports valid_in]
    set_input_delay -clock [get_clocks clk] -max -add_delay 0.150 [get_ports valid_in]
    set_output_delay -clock [get_clocks clk] -min -add_delay 0.100 [get_ports {data_out[*]}]
    set_output_delay -clock [get_clocks clk] -max -add_delay 0.150 [get_ports {data_out[*]}]
    set_output_delay -clock [get_clocks clk] -min -add_delay 0.100 [get_ports valid_out]
    set_output_delay -clock [get_clocks clk] -max -add_delay 0.150 [get_ports valid_out]
}