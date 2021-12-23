// Project title   : AES Accelerator integrated with PicoRV32I via AXI4-Lite master
// Filename        : InvShiftrows.v
// Description     : Hardware modules to perform AES decryption
// Author          : Ruban Vishnu Pandian V (EE19B138)
// Date			   : 10th December, 2021

module InvShiftrows(
    input [31:0] rowin1,
    input [31:0] rowin2,
    input [31:0] rowin3,
    input [31:0] rowin4,
    output [127:0] out
);

wire [31:0] rowout1, rowout2, rowout3, rowout4;

//Rows are obtained as inputs and inverse shift rows operation of AES decryption is performed
assign rowout1 = rowin1;
assign rowout2 = {rowin2[7:0],rowin2[31:8]};
assign rowout3 = {rowin3[15:0],rowin3[31:16]};
assign rowout4 = {rowin4[23:0],rowin4[31:24]};    

//The 128-bit output is hardcoded as concatenation of appropriate output rows' slices
assign out = {rowout1[31:24], rowout2[31:24], rowout3[31:24], rowout4[31:24],
              rowout1[23:16], rowout2[23:16], rowout3[23:16], rowout4[23:16],
              rowout1[15:8], rowout2[15:8], rowout3[15:8], rowout4[15:8],
              rowout1[7:0], rowout2[7:0], rowout3[7:0], rowout4[7:0]};

endmodule
