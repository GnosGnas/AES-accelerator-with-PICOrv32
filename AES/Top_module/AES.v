// Project title   : AES Accelerator integrated with PicoRV32I via AXI4-Lite master
// Filename        : AES.v
// Description     : Top module for whole AES accelerator
// Authorc         : Surya Prasad S (EE19B121), Ruban Vishnu Pandian V (EE19B138)
// Date			   : 10th December 2021

// This is a wrapper module for AES encryption, AES decryption, Key expansion and Key memory modules. 
// The four modules are designed to interact with each other with minimum additional logic circuits.
// Key expansion module is expected to be executed first whenever a new key is to be used and it starts whenever the Key length becomes a valid number. This is irrespective of whether the previous key has been expanded. We additionally need a register key_valid to set the start off after which the module will continue generating the subkeys and sending them to Key memory module to be stored.
// The keymem module stores the subkey's address and the subkey in a set of registers. Also to reduce the latency, we have enabled the first subkey which is the slice of the short_key to be directly stored into the keymem module without the intervention of Key expansion module. The rest of the subkeys are given by the Key expansion modules.
// Both AES encryption and decryption modules operate independently. This parallelism allows us to encrypt and decrypt without having to wait for the other to complete.

// NOTE: New key cannot be given in the immediate next cycle. Since it is an impossible situation in our system we haven't provided support for that.


module AES(
    input clk,
    input reset,
    input pt_valid,
    output pt_in_en,
    output ct_rdy,
    input [127:0] pt_encr,
    output [127:0] ct_encr,
    input ct_valid,
    output ct_in_en,
    output pt_rdy,
    input [127:0] ct_decr,
    output [127:0] pt_decr,
    input [1:0] key_len,
    output key_mem_status,
    output key_inp_ready,
    input [255:0] short_key,
    output error
);

    reg [1:0] status;			// status[0] indicates if decryption is ongoing and status[1] indicates if encryption is ongoing
    reg key_valid;
    wire [1:0] prev_key_len;
    wire w_en;
    wire reset_valid_bits;
    wire [3:0] raddr_encr;
    wire [3:0] raddr_decr;
    wire [3:0] waddr;
    wire [127:0] wkey;
    wire [127:0] rkey_encr;
    wire [127:0] rkey_decr;
    wire [14:0] valid_bits; 
    wire [3:0] waddr_exp;
    wire [127:0] subkey_exp, subkey_encr, subkey_decr;
    wire [3:0] subkey_addr_encr, subkey_addr_decr;
    wire kv, subkey_valid;

    assign pt_in_en = ~status[1];		// The appropriate status bit is set high if encryption or decryption is going on
    assign ct_in_en = ~status[0];

    keymem a0(clk,
            reset,
            w_en,
            reset_valid_bits,
            raddr_encr,
            raddr_decr,
            waddr,
            wkey,
            rkey_encr,
            rkey_decr,
            valid_bits);

    assign w_en = (kv)|(subkey_valid);           // Write first key or valid key
    assign waddr = (kv) ? 4'd0 : waddr_exp;
    assign wkey = (kv) ? short_key[255:128] : subkey_exp; 
    assign raddr_encr = subkey_addr_encr;
    assign raddr_decr = subkey_addr_decr;

    assign kv = ((|key_len)) & (~key_valid);	// Special wire which is mainly used to switch the subkey input and to allow proper passing of new key to Key expansion module
                
    key_exp_outer a1(clk,
                    reset,
                    start_exp,
                    short_key,
                    key_len,
                    subkey_valid,                                 
                    reset_valid_bits,
                    waddr_exp,
                    subkey_exp,
                    prev_key_len);

    assign key_exp_status = (&valid_bits);		// Allows programmer to check if there is any key present in the Key memory
    assign start_exp = (kv) & (status == 0);	// Here key expansion is not allowed to start if encryption or decryption is going on
	assign key_inp_ready = (status == 0);		// Allows programmer to check if the module is ready to accept a new key
	
    AES_encrypt a2(.clk(clk),
                .reset(reset),
                .start(start_encr),
                .plaintext(pt_encr),
                .ciphertext(ct_encr),
                .ciphertext_valid(ready_encr),
                .key_len(prev_key_len),
                .subkey(subkey_encr),
                .subkey_addr(subkey_addr_encr),
                .subkey_valid(subkey_valid_encr));

    assign start_encr = pt_valid;
    assign subkey_encr = rkey_encr;
    assign subkey_valid_encr = valid_bits[raddr_encr];
    assign ct_rdy = ready_encr;

    AES_decrypt a3(clk,
                reset,
                start_decr,
                prev_key_len,
                ready_decr,
                ct_decr,
                pt_decr,
                subkey_decr,
                subkey_valid_decr,
                subkey_addr_decr);

    assign start_decr = ct_valid;
    assign subkey_decr = rkey_decr;
    assign subkey_valid_decr = valid_bits[raddr_decr];
    assign pt_rdy = ready_decr;
	
	assign error = (~(|valid_bits))&(|status);		// Allows programmer to check if inputs for either encryption or decryption has been given incorrectly, i.e., without the module having any key to process it

	always @(posedge clk) begin
    	if(reset) begin
    	    status <= 2'b0;
            key_valid <= 0;
    	end
    	else begin
            if (pt_valid) status[1] <= 1'b1;
            else if (pt_rdy) status[1] <= 1'b0;
            
            if (ct_valid) status[0] <= 1'b1;
            else if (ct_rdy) status[0] <= 1'b0;           

            key_valid <= (|key_len);
        end
	end
endmodule
