// Project title   : AES Accelerator integrated with PicoRV32I via AXI4-Lite master
// Filename        : AddRoundKey.v
// Description     : Hardware module to perform AddRoundKey operation for AES
// Author          : Surya Prasad S (EE19B121)
// Date			   : 10th December, 2021


module AddRoundKey (res, inp, subkey);
	input [127:0] inp, subkey;
	output [127:0] res;

	assign res = inp ^ subkey;        // XORing the inputs since addition in Field Theory is XOR
endmodule

