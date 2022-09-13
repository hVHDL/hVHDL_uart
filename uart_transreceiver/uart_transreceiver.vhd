library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

    use work.uart_transreceiver_pkg.all;
    use work.uart_rx_pkg.all;
    use work.uart_tx_pkg.all;

entity uart_transreceiver is
    port (
        uart_transreceiver_clocks   : in uart_transreceiver_clock_group;
        uart_transreceiver_FPGA_in  : in uart_transreceiver_FPGA_input_group;
        uart_transreceiver_FPGA_out : out uart_transreceiver_FPGA_output_group;
        uart_transreceiver_data_in  : in uart_transreceiver_data_input_group;
        uart_transreceiver_data_out : out uart_transreceiver_data_output_group
    );
end entity;
