// Project title   : AES Accelerator integrated with PicoRV32I via AXI4-Lite Master
// Filename        : Key_Expansion_Outer.v
// Description     : Hardware modules to perform AES Key expansion
// Author          : Surya Prasad S (EE19B121), Ruban Vishnu Pandian (EE19B138)
// Date			   : 10th December, 2021
 
 // The main function of this module is to start the appropriate submodule for key expansion based on the key length. This module takes in the key as and when they have been passed. Hence, the outer module needs to be careful to set valid_key bit to zero after passing the key.
 
 module key_exp_outer(
    input clk,
    input reset,
    input start,
    input [255:0] short_key,
    input [1:0] key_len,
    output valid,                                 
    output reset_valid_bits,
    output [3:0] waddr,
    output [127:0] subkey,
    output [1:0] prev_key_len
 );
    
    wire [127:0] subkey128;
    wire [127:0] subkey192;
    wire [127:0] subkey256;
    wire valid_skey128, valid_skey192, valid_skey256;
    wire[3:0] cnt128, cnt192, cnt256;

    reg start128, start192, start256; 
    reg [255:0] prev_key;
    reg [1:0] prev_key_len;
    reg [127:0] subkey;
    reg reset_valid_bits;
    reg [3:0] waddr;

    assign valid = (valid_skey128 | valid_skey192 | valid_skey256);		// Valid bit for the subkey is being given here by one of the three modules

	// Similary, here too we are connecting the subkey and the corresponding address of it based on the module
    always @(*) begin
        case(prev_key_len)
            2'b01: begin
                subkey = subkey128;
                waddr = cnt128;
            end
            2'b10: begin
                subkey = subkey192;
                waddr = cnt192;
            end
            2'b11: begin 
                subkey = subkey256;
                waddr = cnt256;
            end
            2'b00: subkey = 0; 
        endcase
    end
    
    AESKeyexpansion_128 s1(clk, reset, start128, short_key[255:128], subkey128, cnt128, valid_skey128);
    AESKeyexpansion_192 s2(clk, reset, start192, short_key[255:64], subkey192, cnt192, valid_skey192);
    AESKeyexpansion_256 s3(clk, reset, start256, short_key, subkey256, cnt256, valid_skey256);

    always @(posedge clk) begin
        if(reset) begin
            prev_key <= 0;
            prev_key_len <= 0;
            start128 <= 0;
            start192 <= 0;
            start256 <= 0;
            reset_valid_bits <= 0;
        end
        else begin
            if(start) begin
                if((prev_key == short_key) && (prev_key_len == key_len)) begin
                    //$display("DEBUG-Key_Expansion_Outer.v: Same key received-%h", short_key);
                    start128 <= 0;
                    start192 <= 0;
                    start256 <= 0;
                    reset_valid_bits <= 0;
                end
                else begin
                    //$display("DEBUG-Key_Expansion_Outer.v: New key being passed-%h, %d", short_key, key_len);
                    prev_key_len <= key_len;
                    prev_key <= short_key;
                    reset_valid_bits <= 1;			// Here we are reseting all the valid_bits in the Key memory if a new key has been received.
                    case(key_len)
                    2'b01: start128 <= 1;
                    2'b10: start192 <= 1;
                    2'b11: start256 <= 1;
                    2'b00: begin
                        start128 <= 0;
                        start192 <= 0;
                        start256 <= 0;
                    end
                    endcase
                end
            end
            else begin
                start128 <= 0;
                start192 <= 0;
                start256 <= 0;
                reset_valid_bits <= 0;
            end
        end
    end
endmodule
