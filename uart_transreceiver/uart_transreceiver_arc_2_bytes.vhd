
architecture rtl of uart_transreceiver is

    use work.uart_transreceiver_data_type_pkg.all;
    alias clock is uart_transreceiver_clocks.clock;

    signal uart_rx_clocks   : uart_rx_clock_group;
    signal uart_rx_data_in  : uart_rx_data_input_group;
    signal uart_rx_data_out  : uart_rx_data_output_group;
    
    signal uart_tx_clocks   : uart_tx_clock_group;
    signal uart_tx_data_in  : uart_tx_data_input_group;
    signal uart_tx_data_out : uart_tx_data_output_group;

    signal delay_between_data_packet_transmissions : natural range 0 to 2**8-1 := 0;
    signal packet_counter : natural range 0 to 7;
    signal uart_data_packet_transmission_is_ready : boolean;

    signal transmission_is_requested : boolean := false;
    signal uart_tx_data_packet : uart_data_packet_type := (others => '0');
    signal uart_rx_data_packet : uart_data_packet_type := (others => '0');
    signal uart_rx_word_counter : natural range 0 to 1 := 1;
    signal uart_data_packet_is_received : boolean;
    signal uart_rx_watchdog_timer : natural range 0 to 2**16-1 := 0;

    type list_of_uart_transmitter_states is (wait_for_transmit_request, uart_transmission_is_in_progress);
    signal uart_transmitter_state : list_of_uart_transmitter_states := wait_for_transmit_request;

begin

------------------------------------------------------------------------
    uart_transreceiver_data_out <= ( 
                                       received_data_packet => uart_rx_data_packet,
                                       uart_data_packet_transmission_is_ready => uart_data_packet_transmission_is_ready ,
                                       uart_tx_data_out                       => uart_tx_data_out                       ,
                                       uart_rx_data_out                       => uart_rx_data_out                       ,
                                       uart_data_packet_is_received           => uart_data_packet_is_received
                                   );
    
------------------------------------------------------------------------
    uart_transmit_package_manager : process(clock)


        type list_of_uart_receiver_states is (wait_for_first_packet_ready, wait_for_second_packet_ready);
        variable uart_receiver_state : list_of_uart_receiver_states;
        
    begin
        if rising_edge(clock) then
            init_uart(uart_tx_data_in);

            if delay_between_data_packet_transmissions > 0 then
                delay_between_data_packet_transmissions <= delay_between_data_packet_transmissions - 1;
            end if;

            if transmission_is_requested then
                transmit_8bit_data_package(uart_tx_data_in, uart_tx_data_packet(uart_tx_data_packet'left downto uart_tx_data_packet'left-7));
                uart_tx_data_packet <= uart_tx_data_packet(uart_tx_data_packet'left-8 downto 0) & x"00";
            end if;

            uart_data_packet_transmission_is_ready <= false;
            transmission_is_requested <= false;
            CASE uart_transmitter_state is
                WHEN wait_for_transmit_request =>
                    uart_transmitter_state <= wait_for_transmit_request;
                    packet_counter <= packet_max_index;

                    if uart_transreceiver_data_in.uart_data_packet_transmission_is_requested then
                        packet_counter <= packet_max_index;
                        uart_tx_data_packet <= uart_transreceiver_data_in.uart_data_packet;
                        transmission_is_requested <= true;
                        uart_transmitter_state <= uart_transmission_is_in_progress;
                    end if;

                WHEN uart_transmission_is_in_progress =>

                    uart_transmitter_state <= uart_transmission_is_in_progress;

                    if uart_tx_is_ready(uart_tx_data_out) then
                        delay_between_data_packet_transmissions <= 40;
                    end if;

                    if delay_between_data_packet_transmissions = 1 then
                        transmission_is_requested <= true;
                        packet_counter <= packet_counter - 1;
                    end if;

                    if uart_tx_is_ready(uart_tx_data_out) and packet_counter = 0 then
                        uart_transmitter_state <= wait_for_transmit_request;
                        uart_data_packet_transmission_is_ready <= true;
                        packet_counter <= packet_max_index;
                        delay_between_data_packet_transmissions <= 0;
                    end if; 

            end CASE;

        --------------------------------------------------
            if uart_rx_watchdog_timer > 0 then 
                uart_rx_watchdog_timer <= uart_rx_watchdog_timer - 1;
            end if;

            if uart_rx_watchdog_timer = 1 then
                uart_rx_word_counter <= 1;
            end if;

            uart_data_packet_is_received <= false;
            if uart_rx_data_is_ready(uart_rx_data_out) then
                uart_rx_watchdog_timer <= 500;
                uart_rx_data_packet    <= uart_rx_data_packet(uart_rx_data_packet'left-8 downto 0) & get_uart_rx_data(uart_rx_data_out);
                if uart_rx_word_counter > 0 then
                    uart_rx_word_counter <= uart_rx_word_counter - 1;
                else
                    uart_data_packet_is_received <= true; 
                    uart_rx_word_counter <= 1;
                    uart_rx_watchdog_timer <= 0;
                end if;
            end if;


        end if; --rising_edge
    end process uart_transmit_package_manager;	

------------------------------------------------------------------------
    uart_rx_clocks <= (clock => uart_transreceiver_clocks.clock);
    u_uart_rx : uart_rx
    port map( uart_rx_clocks,
    	  uart_transreceiver_FPGA_in.uart_rx_FPGA_in,
    	  uart_rx_data_in,
    	  uart_rx_data_out); 

------------------------------------------------------------------------
    uart_tx_clocks <= (clock => uart_transreceiver_clocks.clock);
    u_uart_tx : uart_tx
    port map( uart_tx_clocks,
    	  uart_transreceiver_FPGA_out.uart_tx_FPGA_out,
    	  uart_tx_data_in,
    	  uart_tx_data_out);

------------------------------------------------------------------------
end rtl; 
