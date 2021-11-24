echo off
echo %project_root%
FOR /F "tokens=* USEBACKQ" %%F IN (`git rev-parse --show-toplevel`) DO (
SET project_root=%%F
)
SET source=%project_root%/../

            ghdl -a --ieee=synopsys %source%/uart/uart_transreceiver/uart_tx/uart_tx_pkg.vhd
            ghdl -a --ieee=synopsys %source%/uart/uart_transreceiver/uart_rx/uart_rx_pkg.vhd
        ghdl -a --ieee=synopsys %source%/uart/uart_transreceiver/uart_transreceiver_pkg.vhd
    ghdl -a --ieee=synopsys %source%/uart/uart_pkg.vhd

