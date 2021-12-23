// Project title   : AES Accelerator integrated with PicoRV32I via AXI4-Lite Master
// Filename        : AESKeyexpansion_128.v
// Description     : Hardware modules to perform AES Key expansion
// Author          : Saurav Sachin Kale (EE19B141), Ruban Vishnu Pandian (EE19B138)
// Date			   : 10th December, 2021

module AESKeyexpansion_128(
    input clk,
    input reset,
    input start,
    input [127:0] short_key,
    output [127:0] subkey,
    output [3:0] cnt128,
    output valid_skey
);

    reg [3:0] i;
    reg [127:0] prev_period_key_1;  //This register keeps track of the previous round key
                                    //since it's used in current key generation            
    reg status;

    wire [31:0] key1, key2, key3, key4;
    assign cnt128 = i;

    //The current_word_gen_128 module is instantiated 4 times to process 4 words in a clock cycle
    //since each round key is comprised of 4 words. In this way, one round key is processed per cycle
    current_word_gen_128 word1(.i({i,2'd0}),.prev_word(prev_period_key_1[31:0]),.prev_period_word(prev_period_key_1[127:96]),.current_word(key1));
    current_word_gen_128 word2(.i({i,2'd1}),.prev_word(key1),.prev_period_word(prev_period_key_1[95:64]),.current_word(key2));
    current_word_gen_128 word3(.i({i,2'd2}),.prev_word(key2),.prev_period_word(prev_period_key_1[63:32]),.current_word(key3));
    current_word_gen_128 word4(.i({i,2'd3}),.prev_word(key3),.prev_period_word(prev_period_key_1[31:0]),.current_word(key4));

    //The full round key is formed by concatenating 4 individual key words in the right sequence
    assign subkey = {key1, key2, key3, key4};     
    assign valid_skey = status;

    //Note: Register 'i' denotes the first 4 bits of the control variable. Since it's a multiple of 4,
    //the first 4 bits are enough to determine the control variable completely 
    always @(posedge clk)
    begin
        if(reset) begin
        i <= 0;
        prev_period_key_1 <= 0;
        status <= 0;              //Reset signal resets the module to its default state
        end
        else begin
            if (start) begin
                // $display("1. Short key: %h, %d",short_key, i);
                i <= 1; //4
                prev_period_key_1 <= short_key;
                status <= 1;
                //If the module is started, the input key is sampled and stored in "prev_period_key_1".
                //Also, the status bit is set to 1.
            end
            else if((i>=1) && (i<10)) begin //40
                //$display("2. Short key: %h, %d",subkey, i);
                prev_period_key_1 <= {key1,key2,key3,key4};
                i <= i+1; //+4
                //In intermediate rounds, "prev_period_key_1" is assigned to current round key so that
                //it holds it for the next round
            end
            else if(i==10) begin //40
                //$display("3. Short key: %h, %d", subkey, i);
                i <= 0;
                status <= 0;
                prev_period_key_1 <= 0;
                //In the final round, all the registers are made zero since key expansion is done
            end
        end
    end
endmodule
