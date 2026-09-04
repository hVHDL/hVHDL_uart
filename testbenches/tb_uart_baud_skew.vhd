-- Regression for the uart_rx oversampling decoder: transmit a burst of
-- bytes back-to-back with the transmitter running at a different bit
-- period than the receiver (emulating a host UART whose baud rate the
-- FTDI / driver cannot generate exactly) and check every byte is received
-- unchanged.  g_tx_clocks_per_bit = 24 is matched; 23 / 25 are ~+4 / -4 %.

LIBRARY ieee;
    USE ieee.std_logic_1164.all;
    USE ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.uart_tx_pkg.all;
    use work.uart_rx_pkg.all;

entity uart_baud_skew_tb is
    generic (runner_cfg : string;
             g_tx_clocks_per_bit : integer := 23);
end entity;

architecture vunit_simulation of uart_baud_skew_tb is

    constant rx_clocks_per_bit : integer := 24;

    signal clk : std_logic := '0';

    signal rx_in  : uart_rx_FPGA_input_group;
    signal rx_cfg : uart_rx_data_input_group := (number_of_clocks_per_bit => rx_clocks_per_bit);
    signal rx_out : uart_rx_data_output_group;

    signal tx_out : uart_tx_FPGA_output_group;
    signal tx_cfg : uart_tx_data_input_group := init_uart_tx(number_of_clocks_per_bit => 24);
    signal tx_res : uart_tx_data_output_group;

    type byte_arr is array (natural range <>) of std_logic_vector(7 downto 0);
    constant pkt : byte_arr := (
        x"04", x"00", x"01", x"12", x"34", x"56", x"78",
        x"06", x"00", x"00", x"de", x"ad", x"be", x"ef",
        x"00", x"ff", x"a5", x"5a", x"0f", x"f0", x"01", x"80");

    signal n_tx : natural := 0;
    signal n_rx : natural := 0;

begin

    clk <= not clk after 5 ns;
    rx_in.uart_rx <= tx_out.uart_tx;

    main : process is
    begin
        test_runner_setup(runner, runner_cfg);
        wait until n_rx >= pkt'length for 200 us;
        check_equal(n_rx, pkt'length, "did not receive the whole burst");
        test_runner_cleanup(runner);
        wait;
    end process;

    tx : process (clk) is
        variable kick : boolean := true;
    begin
        if rising_edge(clk) then
            init_uart(tx_cfg, g_tx_clocks_per_bit);
            if (kick or uart_tx_is_ready(tx_res)) and n_tx < pkt'length then
                transmit_8bit_data_package(tx_cfg, pkt(n_tx));
                n_tx <= n_tx + 1;
                kick := false;
            end if;
        end if;
    end process;

    rx : process (clk) is
    begin
        if rising_edge(clk) then
            set_number_of_clocks_per_bit(rx_cfg, rx_clocks_per_bit);
            if uart_rx_data_is_ready(rx_out) then
                if n_rx < pkt'length then
                    check_equal(std_logic_vector'(get_uart_rx_data(rx_out)), pkt(n_rx),
                                "byte " & integer'image(n_rx));
                end if;
                n_rx <= n_rx + 1;
            end if;
        end if;
    end process;

    u_uart_tx : entity work.uart_tx
        port map (clk, tx_out, tx_cfg, tx_res);

    u_uart_rx : entity work.uart_rx
        port map (clk, rx_in, rx_cfg, rx_out);

end vunit_simulation;
