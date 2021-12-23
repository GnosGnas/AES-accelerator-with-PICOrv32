
# EE2003 Final Project: AES-Accelerator
This project was in collaboration with @siriusBl4ck and @Ruban-VP

## How to use the peripheral:
* The C code for testing the accelerator named **AES_mem_mapped.c** is present inside the folder **firmware**.
* The pure C code for AES can be found in the file **aes.h**
* Tests have been performed and the relevant files named **test1.c**, **test2.c** are also provided in **tests_with_aes** folder. These test files are provided to demonstrate the speedup the peripheral achieves over AES implementation using C.
* After understanding the test files, modify the **AES_mem_mapped.c** file according to your needs.
* In this folder, run the command **"make"**.

## Required compliers:
* iverilog
* riscv-unknown-elf
* verilator
