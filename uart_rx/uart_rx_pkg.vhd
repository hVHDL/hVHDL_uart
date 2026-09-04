library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package uart_rx_pkg is

    subtype uint12 is integer range 0 to 2**12-1;

    type uart_rx_FPGA_input_group is record
        uart_rx : std_logic;
    end record;
    
    type uart_rx_data_input_group is record
        number_of_clocks_per_bit : uint12;
    end record;

    constant init_uart_rx : uart_rx_data_input_group := (number_of_clocks_per_bit => 24);
    
    type uart_rx_data_output_group is record
        uart_rx_data : std_logic_vector(7 downto 0);
        uart_rx_data_transmission_is_ready : boolean;
    end record;
    
------------------------------------------------------------------------
    procedure set_number_of_clocks_per_bit (
        signal uart_rx_data_input : out uart_rx_data_input_group;
        set_number_of_clocks_per_bit_to : integer range 0 to 2**12-1);
------------------------------------------------------------------------
    function uart_rx_data_is_ready ( uart_rx_out : uart_rx_data_output_group)
        return boolean;
------------------------------------------------------------------------
    function get_uart_rx_data ( uart_rx_out : uart_rx_data_output_group)
        return std_logic_vector;
------------------------------------------------------------------------
    function get_uart_rx_data ( uart_rx_out : uart_rx_data_output_group)
        return natural;
------------------------------------------------------------------------
    
------------------------------------------------------------------------
end package uart_rx_pkg;

package body uart_rx_pkg is

------------------------------------------------------------------------
    procedure set_number_of_clocks_per_bit
    (
        signal uart_rx_data_input : out uart_rx_data_input_group;
        set_number_of_clocks_per_bit_to : integer range 0 to 2**12-1
    ) is
    begin
        uart_rx_data_input.number_of_clocks_per_bit <= set_number_of_clocks_per_bit_to;
    end set_number_of_clocks_per_bit;
------------------------------------------------------------------------
    function uart_rx_data_is_ready
    (
        uart_rx_out : uart_rx_data_output_group
    )
    return boolean
    is
    begin
        return uart_rx_out.uart_rx_data_transmission_is_ready;
    end uart_rx_data_is_ready;

------------------------------------------------------------------------
    function get_uart_rx_data
    (
        uart_rx_out : uart_rx_data_output_group
    )
    return std_logic_vector 
    is
    begin
        return uart_rx_out.uart_rx_data; 
    end get_uart_rx_data;

------------------------------------------------------------------------
    function get_uart_rx_data
    (
        uart_rx_out : uart_rx_data_output_group
    )
    return natural
    is
    begin
        return to_integer(unsigned(uart_rx_out.uart_rx_data));
    end get_uart_rx_data;
------------------------------------------------------------------------
end package body uart_rx_pkg;

------------------------------------------------------------------------
------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.uart_rx_pkg.all;

entity uart_rx is
    port (
        clock : in std_logic;
        uart_rx_FPGA_in  : in uart_rx_FPGA_input_group;
        uart_rx_data_in  : in uart_rx_data_input_group;
        uart_rx_data_out : out uart_rx_data_output_group
    );
end entity;

architecture rtl of uart_rx is

    alias clocks_per_bit is uart_rx_data_in.number_of_clocks_per_bit;

    type rx_state_t is (idle, start_bit, data_bits, stop_bit);
    signal rx_state : rx_state_t := idle;

    -- two-flop synchroniser plus one extra flop for high->low edge detection
    signal rx_meta : std_logic := '1';
    signal rx_sync : std_logic := '1';
    signal rx_prev : std_logic := '1';

    signal clk_count    : natural range 0 to 4095 := 0;   -- core clocks into the current bit
    signal bit_index    : natural range 0 to 7    := 0;
    signal shift_reg    : std_logic_vector(7 downto 0) := (others => '0');
    signal bit_votes    : natural range 0 to 3    := 0;   -- '1' samples across the bit

    signal received_data : std_logic_vector(7 downto 0) := (others => '0');
    signal data_ready    : boolean := false;

begin

    uart_rx_data_out <= (uart_rx_data                      => received_data,
                         uart_rx_data_transmission_is_ready => data_ready);

    ------------------------------------------------------------------
    -- Oversampling receiver: clocks_per_bit core clocks per UART bit
    -- (set via set_number_of_clocks_per_bit).  Each data bit is decided by
    -- a majority vote of three samples taken over the middle quarter of the
    -- bit, and the bit grid is aligned to the start-bit edge, so the
    -- decision stays correct with a few percent of baud mismatch.  A start
    -- bit is only accepted on a genuine high->low edge, and the receiver
    -- re-arms half a bit into the stop bit, so back-to-back frames from a
    -- slightly faster transmitter do not slip.
    ------------------------------------------------------------------
    uart_rx_receiver : process(clock)
        variable half_bit  : natural;
        variable bit_end   : natural;
        variable start_end : natural;
        variable s1, s2, s3 : natural;
    begin
        if rising_edge(clock) then

            rx_meta <= uart_rx_FPGA_in.uart_rx;
            rx_sync <= rx_meta;
            rx_prev <= rx_sync;

            half_bit := clocks_per_bit / 2;
            bit_end  := clocks_per_bit - 1;
            -- the start-bit edge is seen ~2 clocks late through the
            -- synchroniser; shorten the start bit by that much so the data
            -- bit grid lands centred on the real bits
            if clocks_per_bit > 4 then
                start_end := clocks_per_bit - 3;
            else
                start_end := clocks_per_bit - 1;
            end if;
            s1 := clocks_per_bit * 3 / 8;             -- three sample points over the
            s2 := clocks_per_bit / 2;                 -- middle quarter of the bit, so
            s3 := clocks_per_bit * 5 / 8;             -- the vote survives baud skew

            data_ready <= false;

            CASE rx_state is

                WHEN idle =>
                    clk_count <= 0;
                    bit_index <= 0;
                    bit_votes <= 0;
                    if rx_prev = '1' and rx_sync = '0' then      -- start-bit edge
                        rx_state <= start_bit;
                    end if;

                WHEN start_bit =>
                    if clk_count = half_bit and rx_sync = '1' then
                        rx_state  <= idle;                       -- glitch, not a start bit
                    elsif clk_count >= start_end then
                        clk_count <= 0;
                        rx_state  <= data_bits;
                    else
                        clk_count <= clk_count + 1;
                    end if;

                WHEN data_bits =>
                    if rx_sync = '1'
                       and (clk_count = s1 or clk_count = s2 or clk_count = s3) then
                        bit_votes <= bit_votes + 1;
                    end if;

                    if clk_count >= bit_end then
                        clk_count <= 0;
                        bit_votes <= 0;
                        if bit_votes >= 2 then                   -- LSB first
                            shift_reg <= '1' & shift_reg(7 downto 1);
                        else
                            shift_reg <= '0' & shift_reg(7 downto 1);
                        end if;
                        if bit_index >= 7 then
                            rx_state <= stop_bit;
                        else
                            bit_index <= bit_index + 1;
                        end if;
                    else
                        clk_count <= clk_count + 1;
                    end if;

                WHEN stop_bit =>
                    if clk_count >= half_bit then
                        received_data <= shift_reg;
                        data_ready    <= true;
                        clk_count     <= 0;
                        bit_index     <= 0;
                        rx_state      <= idle;
                    else
                        clk_count <= clk_count + 1;
                    end if;

            end CASE;

        end if; --rising_edge
    end process uart_rx_receiver;

end rtl;
