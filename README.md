
# EE2003 Final Project: AES-Accelerator
This project was in collaboration with [Saurav Kale](https://github.com/siriusBl4ck) and [Ruban VP](https://github.com/Ruban-VP).

## How to use the peripheral:
* The C code for testing the accelerator named **AES_mem_mapped.c** is present inside the folder **firmware**.
* The pure C code for AES can be found in the file **aes.h**
* Tests have been performed and the relevant files named **test1.c**, **test2.c** are also provided in **tests_with_aes** folder. These test files are provided to demonstrate the speedup the peripheral achieves over AES implementation using C.
* After understanding the test files, modify the **AES_mem_mapped.c** file according to your needs.
* In this folder, run the command **"make"**.

## Interfacing with PICOrv32:
There are two codes: arb_mem_periph.v and axi4_mem_periph.v. 
To change the bus change it in the rule testbench.vpp in the Makefile.
We have tested our accelerator only with AXI4lite and the Makefile also uses its verilog file.


## Required compliers:
* iverilog
* riscv-unknown-elf
* verilator
