// Project title   : AES Accelerator integrated with PicoRV32I via AXI4-Lite master
// Filename        : Key_mem.v
// Description     : Hardware module to save subkeys
// Author          : Surya Prasad S (EE19B121)
// Date			   : 10th December 2021

// This module stores the subkey and a valid bit corresponding to each address. The valid bits need to be set to zero whenever a new key has been received by the Key expansion modules.

module keymem(
    input clk,
    input reset,
    input w_en,
    input reset_valid_bits,
    input [3:0] raddr_encr,
    input [3:0] raddr_decr,
    input [3:0] waddr,
    input [127:0] wkey,
    output [127:0] rkey_encr,
    output [127:0] rkey_decr,
    output [14:0] valid_bits 
);

	reg [14:0] valid_bits;
	reg [127:0] mem [0:14];

	integer i;
	
	assign rkey_encr = (valid_bits[raddr_encr]) ? mem[raddr_encr] : 128'bZ;		// Setting read value to high impedance if the valid bit is invalid
	assign rkey_decr = (valid_bits[raddr_decr]) ? mem[raddr_decr] : 128'bZ;

	always @(posedge clk) begin
	    if(reset) begin
	        for(i=0; i<15; i=i+1) begin
	            valid_bits[i] <= 0;
	            mem[i] <= 0;
	        end
	    end
	    else if(reset_valid_bits) begin
	        for(i=1; i<15; i=i+1) begin
	            valid_bits[i] <= 0;
	            mem[i] <= 0;
	        end
	    end
	    else begin
	        if(w_en) begin
	            mem[waddr] <= wkey;
	            valid_bits[waddr] <= 1; 
	        end
	    end
	end
endmodule
