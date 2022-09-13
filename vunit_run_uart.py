#!/usr/bin/env python3
from pathlib import Path
from vunit import VUnit

# ROOT
ROOT = Path(__file__).resolve().parent
VU = VUnit.from_argv()
# VU = VUnit.from_argv(vhdl_standard="93")

def add_sources(lib, filename):
    with open(filename, "r") as f:
        for line in f.readlines():
            lib.add_source_files(ROOT / line.strip())

lib = VU.add_library("lib");
add_sources(lib,"sources.txt")
lib.add_source_files(ROOT / "uart_transreceiver/uart_transreceiver_arc_2_bytes.vhd")
lib.add_source_files(ROOT / "uart_transreceiver/uart_transreceiver_data_type_16_bit_pkg.vhd")

lib2 = VU.add_library("lib2");
add_sources(lib2,"sources.txt")
lib2.add_source_files(ROOT / "uart_transreceiver/uart_transreceiver_arc_5_bytes.vhd")
lib2.add_source_files(ROOT / "uart_transreceiver/uart_transreceiver_data_type_40_bit_pkg.vhd")

VU.main()
