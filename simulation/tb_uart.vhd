LIBRARY ieee  ; 
LIBRARY std  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

    use work.uart_pkg.all;

library vunit_lib;
    context vunit_lib.vunit_context;

entity tb_uart is
  generic (runner_cfg : string);
end;

architecture sim of tb_uart is

    signal simulation_running : boolean := false;
    signal simulator_clock : std_logic := '0';
    signal clocked_reset : std_logic := '0';
    constant clock_per : time := 1 ns;
    constant simtime_in_clocks : integer := 8000;

    signal uart_data_in  : uart_data_input_group;
    signal uart_data_out : uart_data_output_group;

    signal simulation_counter : natural := 500;
    signal uart_tx : std_logic;

    signal data_from_uart : natural := 0;
    signal uart_was_run : boolean := false;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        simulation_running <= true;
        wait for simtime_in_clocks*clock_per;
        simulation_running <= false;
        check(uart_was_run, "uart did not run");

        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	
    simulator_clock <= not simulator_clock after clock_per/2.0;
------------------------------------------------------------------------

    clocked_reset_generator : process(simulator_clock)
    begin
    
        init_uart(uart_data_in);
        if simulation_counter > 0 then
            simulation_counter <= simulation_counter - 1;
        end if;

        CASE simulation_counter is
            when 0 => 
            when 3 => 
                transmit_16_bit_word_with_uart(uart_data_in, 44252);
            when others =>
        end CASE;

        receive_data_from_uart(uart_data_out, data_from_uart);
        if uart_is_ready(uart_data_out) then
            uart_was_run <= true;
        end if;
    
    end process clocked_reset_generator;	
------------------------------------------------------------------------

    u_uart : uart
    port map( uart_clocks.clock => simulator_clock,
    	  uart_FPGA_in.uart_transreceiver_FPGA_in.uart_rx_FPGA_in.uart_rx    => uart_tx,
    	  uart_FPGA_out.uart_transreceiver_FPGA_out.uart_tx_FPGA_out.uart_tx => uart_tx,
    	  uart_data_in  => uart_data_in,
    	  uart_data_out => uart_data_out);
end sim;
