// Project title   : AES Accelerator integrated with PicoRV32I via AXI4-Lite Master
// Filename        : AESKeyexpansion_192.v
// Description     : Hardware modules to perform AES Key expansion
// Author          : Saurav Sachin Kale (EE19B141), Ruban Vishnu Pandian (EE19B138)
// Date			   : 10th December, 2021

module AESKeyexpansion_192(
    input clk,
    input reset,
    input start,
    input [191:0] short_key,
    output [127:0] subkey,
	output [3:0] cnt192,
    output valid_skey
);

	reg [4:0] i;  //last bit always 0 so can be removed!
	reg [191:0] prev_period_key_1; //This register keeps track of the previous 6 words
                                   //since it's used in current key generation     
	reg status;

	wire [31:0] key1, key2, key3, key4;
    assign cnt192 = i[4:1];
 
    //The current_word_gen_192 module is instantiated 4 times to process 4 words in a clock cycle
    //since each round key is comprised of 4 words. In this way, one round key is processed per cycle
	current_word_gen_192 word1(.i({i,1'd0}),.prev_word(prev_period_key_1[31:0]),.prev_period_word(prev_period_key_1[191:160]),.current_word(key1));
	current_word_gen_192 word2(.i({i,1'd1}),.prev_word(key1),.prev_period_word(prev_period_key_1[159:128]),.current_word(key2));
	current_word_gen_192 word3(.i({i[4:1],2'd2}),.prev_word(key2),.prev_period_word(prev_period_key_1[127:96]),.current_word(key3));
	current_word_gen_192 word4(.i({i[4:1],2'd3}),.prev_word(key3),.prev_period_word(prev_period_key_1[95:64]),.current_word(key4));
	
	//The full round key is obtained by concatenating 4 keywords. Only in the second round, we 
	//instead concatenate prev_period_key_1[63:0], key1, key2 since in that round, the first 2 
	//keywords are obtained from the input 192-bit key itself
	assign subkey = (i==3)? ({prev_period_key_1[63:0], key1, key2}): ({key1, key2, key3, key4}); //6
	assign valid_skey = status;

    //Note: Register 'i' denotes the first 5 bits of the control variable. Since it's a multiple of 2,
    //the first 5 bits are enough to determine the control variable completely 
	always @(posedge clk)
	begin
		if(reset) begin
		i <= 0;
		prev_period_key_1 <= 0;
		status <= 0;            //Reset signal resets the module to its default state
		end
		else begin
			if (start) begin
				i <= 3; //6
				prev_period_key_1 <= short_key;
				status <= 1;
				//If the module is started, the input key is sampled and stored in "prev_period_key_1".
                //Also, the status bit is set to 1.
			end
			else if (i==3) begin //6
				i <= 4; //8
				prev_period_key_1 = {prev_period_key_1[127:0],key1,key2};
				status <= 1;
				//Only in the second round,"prev_period_key_1" is updated this way
			end
			else if((i>=4) && (i<24)) begin //48
				i <= i+2; //+4
				prev_period_key_1 = {prev_period_key_1[63:0],key1,key2,key3,key4};
				status <= 1;
				//In intermediate rounds, "prev_period_key_1" is assigned to 
				//{last two words of prev_period_key_1 + current round key} so that it 
				//holds it for the next round
			end
			else if(i==24) begin //48
				i <= 0;
				status <= 0;
				prev_period_key_1 <= 0;
				//In the final round, all the registers are made zero since key expansion is done
			end
		end
	end
endmodule
