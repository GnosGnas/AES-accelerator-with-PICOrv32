// Project title   : AES Accelerator integrated with PicoRV32I via AXI4-Lite master
// Filename        : AES_decrypt.v
// Description     : Hardware modules to perform AES decryption
// Author          : Ruban Vishnu Pandian V (EE19B138)
// Date			   : 10th December, 2021

module AES_decrypt(
    input clk,
    input reset,
    input start,
    input [1:0] key_len,
    output ready,
    input [127:0] ciphertext,
    output [127:0] plaintext,
    input [127:0] subkey,
    input subkey_valid,
    output [3:0] subkey_addr
);

    //Registers used in the module are declared
    reg ready;
    reg [1:0] status;
    reg [127:0] plaintext;
    reg [3:0] skey_addr;
    assign subkey_addr = skey_addr;

    //Intermediate wires used in the module are declared
    wire [127:0] output_1, invshiftrows_out;
    wire [127:0] invsubbytes_out, addkey_out, invmixcols_out;

    AddRoundKey ark1 (output_1, ciphertext, subkey);

    wire [31:0] rowin1, rowin2, rowin3, rowin4;
    
    //Rows corresponding to the 128-bit register "Plaintext" are assigned
    assign rowin1 = {plaintext[127:120], plaintext[95:88], plaintext[63:56], plaintext[31:24]};
    assign rowin2 = {plaintext[119:112], plaintext[87:80], plaintext[55:48], plaintext[23:16]};
    assign rowin3 = {plaintext[111:104], plaintext[79:72], plaintext[47:40], plaintext[15:8]};
    assign rowin4 = {plaintext[103:96], plaintext[71:64], plaintext[39:32], plaintext[7:0]};

    //InvShiftrows, InvSubBytes and AddRoundKey operations are executed
    InvShiftrows isr1 (rowin1, rowin2, rowin3, rowin4, invshiftrows_out);
    InvSubBytes isb1 (invshiftrows_out, invsubbytes_out);
    AddRoundKey ark2 (addkey_out, invsubbytes_out, subkey);

    wire [31:0] colin1, colin2, colin3, colin4;

    //The output of AddroundKey module is taken and split into columns
    assign colin1 = {addkey_out[127:120],addkey_out[119:112], addkey_out[111:104], addkey_out[103:96]};
    assign colin2 = {addkey_out[95:88], addkey_out[87:80], addkey_out[79:72], addkey_out[71:64]};
    assign colin3 = {addkey_out[63:56], addkey_out[55:48], addkey_out[47:40], addkey_out[39:32]};
    assign colin4 = {addkey_out[31:24], addkey_out[23:16], addkey_out[15:8], addkey_out[7:0]};

    //The columns declared above are passed into the InvMixCols operation module
    InvMixCols imc1 (colin1, colin2, colin3, colin4, invmixcols_out);

    always @(posedge clk) begin
        if(reset) begin
            ready <= 1;
            plaintext <= 0;
            skey_addr <= 0;
            status <= 0;        //When reset is HIGH, the module is reset to it's default state
        end
        else if((|key_len) && (start) && (~status)) begin
            ready <= 0;
            status <= 1;
            case(key_len)
            2'b00: ;
            2'b01: begin
                skey_addr <= 10;
            end
            2'b10: begin
                skey_addr <= 12;
            end
            2'b11: begin
                skey_addr <= 14;
            end
            endcase
            //If new key is given and if the module is free, the module is started and status is made 1
        end
        else if (status==1) begin
            if (subkey_valid) begin
                plaintext <= output_1;
                skey_addr <= skey_addr-1;
                status <= 2;
                //If status==1, the module is in it's pre-first-round stage. Register "plaintext"
                //is initialised with the output of the first addkey module. Also, 2 is assigned to start
            end
        end
        else if (status == 2) begin
            if (subkey_valid) begin
                skey_addr <= skey_addr-1;
                if (skey_addr==0) begin
                    status <= 0;               //In the last round, InvMixCols is not needed. Hence,
                    ready <= 1;                //register "plaintext" is assigned to addkey_out 
                    plaintext <= addkey_out;   //(Output of Addkey module). Also, status is made zero
                end
                else plaintext <= invmixcols_out;
                //In all the other rounds, it's assigned to invmixcols_out 
                //(Output of InvMixCols module)
            end
        end
    end
endmodule

