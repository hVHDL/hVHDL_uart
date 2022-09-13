library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package uart_transreceiver_data_type_pkg is

    subtype uart_packet_has_16_bits is std_logic_vector(15 downto 0);
    subtype uart_data_packet_type is uart_packet_has_16_bits;

end package uart_transreceiver_data_type_pkg;
