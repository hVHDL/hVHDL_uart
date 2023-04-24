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

VU.main()
