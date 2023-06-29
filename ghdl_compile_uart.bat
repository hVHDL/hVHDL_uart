echo off

ghdl -a --ieee=synopsys --std=08 %1/uart_tx/uart_tx_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %1/uart_rx/uart_rx_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %1/uart_protocol/uart_protocol_pkg.vhd
