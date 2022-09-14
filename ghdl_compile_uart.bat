echo off
echo %project_root%
FOR /F "tokens=* USEBACKQ" %%F IN (`git rev-parse --show-toplevel`) DO (
SET project_root=%%F
)
SET source=%project_root%/../

ghdl -a --ieee=synopsys --std=08 %source%/hVHDL_uart/uart_transreceiver/uart_tx/uart_tx_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/hVHDL_uart/uart_transreceiver/uart_rx/uart_rx_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/hVHDL_uart/uart_transreceiver/uart_transreceiver_data_type_16_bit_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/hVHDL_uart/uart_transreceiver/uart_transreceiver_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/hVHDL_uart/uart_transreceiver/uart_transreceiver.vhd
ghdl -a --ieee=synopsys --std=08 %source%/hVHDL_uart/uart_pkg.vhd
