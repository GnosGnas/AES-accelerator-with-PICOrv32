// Project title   : AES Accelerator integrated with PicoRV32I via AXI4-Lite master
// Filename        : AES_encrypt.v
// Description     : Hardware modules to perform AES encryption
// Author          : Surya Prasad S (EE19B121)
// Date			   : 10th December 2021

// Encryption is being done based on AES encryption standard (EBC cipher mode)
// Based on the length of key the least number of cycles it takes to encrypt a plaintext is 12 (in case of 128-bit key), 14 (in case of 192-bit key) or 16 (in case of 256-bit key).
// The actual number of cycles it takes is based on whether the Key Memory contains all the subkeys. This also means that there is no restriction on the other module which generates the subkeys required for encryption. So the Key-Expansion module may take just one cycle to fill all the subkeys in the Key Memory or may take 100s of cycles too.
// NOTE: This also means there is a possibility of infinite stall when there is no key being expanded and stored in memory


module AES_encrypt (clk,
	     reset,
		 start,
	     plaintext,
		 ciphertext,
		 ciphertext_valid,
		 key_len,
		 subkey,
		 subkey_addr,
		 subkey_valid
		 );
	// Port declarations
	input clk, reset, start;
	input [127:0] plaintext;

	output [127:0] ciphertext;
	output reg ciphertext_valid;

	input [1:0] key_len;
	input [127:0] subkey;
	input subkey_valid;
	output reg [3:0] subkey_addr;

	reg [1:0] stage;
	reg [127:0] result;
	reg [3:0] max_rounds;

	wire [127:0] pre_addkey_out, subbytes_out, shiftrows_out, mixcols_out, addkey_in, addkey_out;
	wire addkey_switch;

    // In the final round, output of the shiftrows operation must be passed on to addkey operation.
	// Hence, a bit is used to choose between the inputs to be given
	assign addkey_switch = (max_rounds==1);                          
	assign addkey_in = addkey_switch ? shiftrows_out : mixcols_out;

	assign ciphertext = result;
	
	// A1 module is needed for passing the first subkey and the other modules are used for the remaining rounds
	AddRoundKey A1 (pre_addkey_out, plaintext, subkey);   
	
	SubBytes    SB (subbytes_out, result);
	ShiftRows   SR (shiftrows_out, subbytes_out);
	MixColumns  M  (mixcols_out, shiftrows_out);
	AddRoundKey A2 (addkey_out, addkey_in, subkey);

	always@(posedge clk) begin
		if (reset) begin    		 // The encryption module is set to default state when reset is HIGH
			stage <= 0;				 //	For moving across stages
			ciphertext_valid <= 0;	 // Output ciphertext is initially invalid
			result <= 0;			 // Output of each stage is stored in result
			max_rounds <= 0;		 // Number of rounds taken after pre_addkey stage
		end
        else if ((|key_len) && (start) && (stage==0))	begin
			//$display("DEBUG-AES_encrypt.v: Start encryption with plaintext - %h", plaintext);
			stage <= 1;				 						// 1-cycle delay introduced in getting the plaintext to fetch subkey[0]
			ciphertext_valid <= 0;
			if (key_len == 2'd3) max_rounds <= 15;			// Max rounds is determined according to the mode of AES (128,192 or 256) 
			else if (key_len == 2'd2) max_rounds <= 13;
			else max_rounds <= 11;
			subkey_addr <= 0;    
		end
		else if (stage == 1) begin
			if (subkey_valid) begin
				//$display("DEBUG-AES_encrypt.v: Subkey[%d]-%h, round1 result-%h", subkey_addr, subkey, pre_addkey_out);
				stage <= 2;
				result <= pre_addkey_out;           
				max_rounds <= max_rounds-1;
				subkey_addr <= subkey_addr+1;
				// If stage=1, we are in the pre-first-round stage of encryption. result stores the output of the first add_key operation
			end
		end
		else if (stage == 2) begin
			if (subkey_valid) begin
				//$display("DEBUG-AES_encrypt.v: Subkey[%d]-%h, round%d", subkey_addr, subkey, subkey_addr+1, addkey_out);
				max_rounds <= max_rounds-1;
				result <= addkey_out;
				subkey_addr <= subkey_addr+1;
                // In the other rounds, all operations are be done. 
				if (max_rounds == 1) begin
					stage <= 0;
					ciphertext_valid <= 1'b1;
					// Once the final round is done, stage is again made zero and ciphervalid is made HIGH
					// Indicating that the module has the ciphertext processed and available
				end
			end
		end
	end
endmodule

