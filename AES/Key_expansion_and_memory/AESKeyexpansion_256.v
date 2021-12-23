// Project title   : AES Accelerator integrated with PicoRV32I via AXI4-Lite Master
// Filename        : AESKeyexpansion_256.v
// Description     : Hardware modules to perform AES Key expansion
// Author          : Saurav Sachin Kale (EE19B141), Ruban Vishnu Pandian (EE19B138)
// Date			   : 10th December, 2021

module AESKeyexpansion_256(
    input clk,
    input reset,
    input start,
    input [255:0] short_key,
    output [127:0] subkey,
    output [3:0] cnt256,
    output valid_skey
);

    reg [3:0] i; //last 2 bit always 0 so can be removed!
    reg [127:0] prev_period_key_1, prev_period_key_2; 
    //These registers keep track of the previous two round keys since they are used in 
    //current key generation
    
    reg status;

    wire [31:0] key1, key2, key3, key4;
    assign cnt256 = i;

    //The current_word_gen_256 module is instantiated 4 times to process 4 words in a clock cycle
    //since each round key is comprised of 4 words. In this way, one round key is processed per cycle
    current_word_gen_256 word1(.i({i,2'd0}),.prev_word(prev_period_key_2[31:0]),.prev_period_word(prev_period_key_1[127:96]),.current_word(key1));
    current_word_gen_256 word2(.i({i,2'd1}),.prev_word(key1),.prev_period_word(prev_period_key_1[95:64]),.current_word(key2));
    current_word_gen_256 word3(.i({i,2'd2}),.prev_word(key2),.prev_period_word(prev_period_key_1[63:32]),.current_word(key3));
    current_word_gen_256 word4(.i({i,2'd3}),.prev_word(key3),.prev_period_word(prev_period_key_1[31:0]),.current_word(key4));
        
    //The full round key is formed by concatenating 4 individual key words in the right sequence.
    //Only in th second cycle, its directly obtained from the input 256-bit key    
    assign subkey = (i==1) ? prev_period_key_2 : {key1, key2, key3, key4};
    assign valid_skey = status;

    //Note: Register 'i' denotes the first 4 bits of the control variable. Since it's a multiple of 4,
    //the first 4 bits are enough to determine the control variable completely 
    always @(posedge clk)
    begin
        if(reset) begin
        i <= 0;
        prev_period_key_1 <= 0;
        prev_period_key_2 <= 0;
        status <= 0;              //Reset signal resets the module to its default state
        end
        else begin
            if (start) begin
                i <= 1; //4
                prev_period_key_1 <= short_key[255:128];
                prev_period_key_2 <= short_key[127:0];
                status <= 1;
                //If the module is started, the input key is sampled and stored in "prev_period_key_1"
                //and "prev_period_key_2". Also, the status bit is set to 1.
            end
            else if(i==1) begin
                i <= 2; //8
                prev_period_key_1 <= prev_period_key_1;
                prev_period_key_2 <= prev_period_key_2;
                status <= 1;
                //In the second round, round key is simply obtained from the input 256-bit key
            end
            else if ((i>=2) && (i<14)) begin //56
                prev_period_key_1 <= prev_period_key_2;
                prev_period_key_2 <= {key1,key2,key3,key4};
                i <= i+1; //+4
                //In intermediate rounds, "prev_period_key_1" and "prev_period_key_2" 
                //are updated with the  "prev_period_key_2" and current key respectively since 
                //they are used in the next key generation round
            end
            else if(i==14) begin //56
                i <= 0;
                status <= 0;
                prev_period_key_1 <= 0;
                prev_period_key_2 <= 0;
                //In the final round, all the registers are made zero since key expansion is done
            end
        end
    end
endmodule
