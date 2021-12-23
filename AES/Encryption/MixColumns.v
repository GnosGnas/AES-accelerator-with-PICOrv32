// Project title   : AES Accelerator integrated with PicoRV32I via AXI4-Lite master
// Filename        : MixColumns.v
// Description     : Hardware module to perform MixColumns operation for AES
// Author          : Surya Prasad S (EE19B121)
// Date			   : 10th December, 2021


module MixColumns (res, inp);
	input [127:0] inp;
	output [127:0] res;

	// Matrix for mixcolumns
	// | 2 3 1 1 |
	// | 1 2 3 1 |
	// | 3 1 1 2 |
	// Here the matrix operation is being done column-wise
	genvar i;
	for(i=0; i<4; i=i+1)
	begin
		assign res[31+32*i:24+32*i]  = mixer(2, inp[31+32*i:24+32*i]) ^ mixer(3, inp[23+32*i:16+32*i]) ^ mixer(1, inp[15+32*i:8+32*i]) ^ mixer(1, inp[7+32*i:32*i]);
		assign res[23+32*i:16+32*i]  = mixer(1, inp[31+32*i:24+32*i]) ^ mixer(2, inp[23+32*i:16+32*i]) ^ mixer(3, inp[15+32*i:8+32*i]) ^ mixer(1, inp[7+32*i:32*i]);
		assign res[15+32*i:8+32*i]   = mixer(1, inp[31+32*i:24+32*i]) ^ mixer(1, inp[23+32*i:16+32*i]) ^ mixer(2, inp[15+32*i:8+32*i]) ^ mixer(3, inp[7+32*i:32*i]);
		assign res[7+32*i:32*i]      = mixer(3, inp[31+32*i:24+32*i]) ^ mixer(1, inp[23+32*i:16+32*i]) ^ mixer(1, inp[15+32*i:8+32*i]) ^ mixer(2, inp[7+32*i:32*i]);
	end

    // The function below is used for the mixcolumns operation. This function defines multiplication by 1, 2 and 3 in GF(2^8)
	function automatic [7:0] mixer (input [1:0] i, input [7:0] inp);
	begin:a1
		reg [7:0] temp;
	
		// Integer i for MixColumns can be three values 1, 2 and 3 and they have been handled in this function
		if(i == 1) mixer = inp;
		else if(i == 2) begin
			if(inp[7]) temp = 8'h1b; 
			else temp = 0;
			mixer = (inp<<1)^temp;	                                    
		end
		else begin
			if(inp[7]) temp = 8'h1b;
			else temp = 0;
			mixer = inp^(inp<<1)^temp;
		end
	end
	endfunction
endmodule
