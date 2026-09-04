#!/usr/bin/env python3
from pathlib import Path
from vunit import VUnit

# ROOT
ROOT = Path(__file__).resolve().parent
VU = VUnit.from_argv()

lib = VU.add_library("lib");
lib.add_source_files(ROOT / "uart_rx/uart_rx_pkg.vhd")
lib.add_source_files(ROOT / "uart_tx/uart_tx_pkg.vhd")

lib.add_source_files(ROOT / "testbenches/tb_uart_test.vhd")
lib.add_source_files(ROOT / "testbenches/tb_uart_baud_skew.vhd")

skew_tb = lib.test_bench("uart_baud_skew_tb")
for tx_cpb in (24, 23, 25):
    skew_tb.add_config(name=f"tx_cpb_{tx_cpb}", generics=dict(g_tx_clocks_per_bit=tx_cpb))

VU.main()
