// Project title   : AES Accelerator integrated with PicoRV32I via AXI4-Lite master
// Filename        : AddRoundKey.v
// Description     : Hardware modules to perform AES decryption
// Author          : Ruban Vishnu Pandian V (EE19B138)
// Date			   : 10th December, 2021

module AddRoundKey (res, inp, subkey);
	input [127:0] inp, subkey;
	output [127:0] res;

	assign res = inp ^ subkey;        //XORs the inputs since addition in GF(2^8) is XOR
endmodule
