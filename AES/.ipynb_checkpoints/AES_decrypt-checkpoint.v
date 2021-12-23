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

    reg ready;
    reg [1:0] status;
    reg [127:0] plaintext;
    reg [3:0] skey_addr;

    wire [127:0] output_1, invshiftrows_out;
    wire [127:0] invsubbytes_out, addkey_out, invmixcols_out;

    AddRoundKey ark1 (output_1, ciphertext, subkey);

    wire [31:0] rowin1, rowin2, rowin3, rowin4;
    assign subkey_addr = skey_addr;
    assign rowin1 = {plaintext[127:120], plaintext[95:88], plaintext[63:56], plaintext[31:24]};
    assign rowin2 = {plaintext[119:112], plaintext[87:80], plaintext[55:48], plaintext[23:16]};
    assign rowin3 = {plaintext[111:104], plaintext[79:72], plaintext[47:40], plaintext[15:8]};
    assign rowin4 = {plaintext[103:96], plaintext[71:64], plaintext[39:32], plaintext[7:0]};

    InvShiftrows isr1 (rowin1, rowin2, rowin3, rowin4, invshiftrows_out);
    InvSubBytes isb1 (invshiftrows_out, invsubbytes_out);
    AddRoundKey ark2 (addkey_out, invsubbytes_out, subkey);

    wire [31:0] colin1, colin2, colin3, colin4;

    assign colin1 = {addkey_out[127:120],addkey_out[119:112], addkey_out[111:104], addkey_out[103:96]};
    assign colin2 = {addkey_out[95:88], addkey_out[87:80], addkey_out[79:72], addkey_out[71:64]};
    assign colin3 = {addkey_out[63:56], addkey_out[55:48], addkey_out[47:40], addkey_out[39:32]};
    assign colin4 = {addkey_out[31:24], addkey_out[23:16], addkey_out[15:8], addkey_out[7:0]};

    InvMixCols imc1 (colin1, colin2, colin3, colin4, invmixcols_out);

    always @(posedge clk) begin
        if(reset) begin
            ready <= 1;
            plaintext <= 0;
            skey_addr <= 0;
            status <= 0;
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
        end
        else if (status==1) begin
            if (subkey_valid) begin
                plaintext <= output_1;
                skey_addr <= skey_addr-1;
                status <= 2;
            end
        end
        else if (status == 2) begin
            if (subkey_valid) begin
                skey_addr <= skey_addr-1;
                
                if (skey_addr==0) begin
                    status <= 0;
                    ready <= 1;
                    plaintext <= addkey_out;
                end
                else plaintext <= invmixcols_out;
            end
        end
    end
endmodule

module InvMixCols(
    input [31:0] colin1,
    input [31:0] colin2,
    input [31:0] colin3,
    input [31:0] colin4,
    output [127:0] out
);

reg [31:0] colout1, colout2, colout3, colout4;

function automatic [7:0] mul2 (input [7:0] a);
    begin
        mul2 = (a[7]) ? (({a[6:0],1'b0})^(8'b00011011)) : ({a[6:0],1'b0});
    end
endfunction

function automatic [7:0] mul (input [7:0] a, input [1:0] sel);   
    begin
        case(sel)
        2'b00: mul = mul2(mul2(mul2(a)))^a;          //x09
        2'b01: mul = mul2(mul2(mul2(a))^a)^a;        //x0B
        2'b10: mul = mul2(mul2(mul2(a)^a))^a;        //x0D
        2'b11: mul = mul2(mul2(mul2(a)^a)^a);        //x0E
        endcase
    end
endfunction

always @(*)
begin
    colout1[31:24] = mul(colin1[31:24],2'b11)^mul(colin1[23:16],2'b01)^mul(colin1[15:8],2'b10)^mul(colin1[7:0],2'b00);
    colout2[31:24] = mul(colin2[31:24],2'b11)^mul(colin2[23:16],2'b01)^mul(colin2[15:8],2'b10)^mul(colin2[7:0],2'b00);
    colout3[31:24] = mul(colin3[31:24],2'b11)^mul(colin3[23:16],2'b01)^mul(colin3[15:8],2'b10)^mul(colin3[7:0],2'b00);
    colout4[31:24] = mul(colin4[31:24],2'b11)^mul(colin4[23:16],2'b01)^mul(colin4[15:8],2'b10)^mul(colin4[7:0],2'b00);

    colout1[23:16] = mul(colin1[31:24],2'b00)^mul(colin1[23:16],2'b11)^mul(colin1[15:8],2'b01)^mul(colin1[7:0],2'b10);
    colout2[23:16] = mul(colin2[31:24],2'b00)^mul(colin2[23:16],2'b11)^mul(colin2[15:8],2'b01)^mul(colin2[7:0],2'b10);
    colout3[23:16] = mul(colin3[31:24],2'b00)^mul(colin3[23:16],2'b11)^mul(colin3[15:8],2'b01)^mul(colin3[7:0],2'b10);
    colout4[23:16] = mul(colin4[31:24],2'b00)^mul(colin4[23:16],2'b11)^mul(colin4[15:8],2'b01)^mul(colin4[7:0],2'b10);

    colout1[15:8] = mul(colin1[31:24],2'b10)^mul(colin1[23:16],2'b00)^mul(colin1[15:8],2'b11)^mul(colin1[7:0],2'b01);
    colout2[15:8] = mul(colin2[31:24],2'b10)^mul(colin2[23:16],2'b00)^mul(colin2[15:8],2'b11)^mul(colin2[7:0],2'b01);
    colout3[15:8] = mul(colin3[31:24],2'b10)^mul(colin3[23:16],2'b00)^mul(colin3[15:8],2'b11)^mul(colin3[7:0],2'b01);
    colout4[15:8] = mul(colin4[31:24],2'b10)^mul(colin4[23:16],2'b00)^mul(colin4[15:8],2'b11)^mul(colin4[7:0],2'b01);

    colout1[7:0] = mul(colin1[31:24],2'b01)^mul(colin1[23:16],2'b10)^mul(colin1[15:8],2'b00)^mul(colin1[7:0],2'b11);
    colout2[7:0] = mul(colin2[31:24],2'b01)^mul(colin2[23:16],2'b10)^mul(colin2[15:8],2'b00)^mul(colin2[7:0],2'b11);
    colout3[7:0] = mul(colin3[31:24],2'b01)^mul(colin3[23:16],2'b10)^mul(colin3[15:8],2'b00)^mul(colin3[7:0],2'b11);
    colout4[7:0] = mul(colin4[31:24],2'b01)^mul(colin4[23:16],2'b10)^mul(colin4[15:8],2'b00)^mul(colin4[7:0],2'b11);
end

assign out = {colout1, colout2, colout3, colout4};

endmodule

module InvShiftrows(
    input [31:0] rowin1,
    input [31:0] rowin2,
    input [31:0] rowin3,
    input [31:0] rowin4,
    output [127:0] out
);

wire [31:0] rowout1, rowout2, rowout3, rowout4;

assign rowout1 = rowin1;
assign rowout2 = {rowin2[7:0],rowin2[31:8]};
assign rowout3 = {rowin3[15:0],rowin3[31:16]};
assign rowout4 = {rowin4[23:0],rowin4[31:24]};

assign out = {rowout1[31:24], rowout2[31:24], rowout3[31:24], rowout4[31:24],
              rowout1[23:16], rowout2[23:16], rowout3[23:16], rowout4[23:16],
              rowout1[15:8], rowout2[15:8], rowout3[15:8], rowout4[15:8],
              rowout1[7:0], rowout2[7:0], rowout3[7:0], rowout4[7:0]};

endmodule

module InvSubBytes(
    input [127:0] in,
    output [127:0] out
);

function automatic [7:0] inv_sbox;
    input [7:0] in_byte;
    reg [7:0] out_iso;
    reg [3:0] g0;
    reg [3:0] g1;
    reg [3:0] g1_g0_t;
    reg [3:0] g0_sq;
    reg [3:0] g1_sq_mult_v;
    reg [3:0] inverse;
    reg [3:0] d0;
    reg [3:0] d1;
    
    begin
    out_iso = iso(in_byte);

    g1 = out_iso[7:4];
    g0 = out_iso[3:0];

    g1_g0_t = gf4_mul(g1, g0);
    g0_sq = gf4_sq(g0);
    g1_sq_mult_v = gf4_sq_mul_v(g1);

    inverse = gf4_inv((g1_g0_t ^ g0_sq ^ g1_sq_mult_v));

    d1 = gf4_mul(g1, inverse);
    d0 = gf4_mul((g0 ^ g1), inverse);

    inv_sbox = inv_iso({d1, d0});
    end
endfunction

function automatic [7:0] iso;
    input [7:0] a;
    begin
    iso[0]= a[3];
    iso[1]= a[1] ^ a[3] ^ a[5];
    iso[2]= ~(a[2] ^ a[3] ^ a[6] ^a[7]);
    iso[3]= ~(a[5] ^ a[7]);
    iso[4]= ~(a[1] ^ a[2] ^ a[7]);
    iso[5]= ~(a[0] ^ a[4] ^ a[5] ^ a[6]);
    iso[6]= a[1] ^ a[2] ^ a[3] ^ a[4] ^ a[5] ^ a[7];
    iso[7]= a[1] ^ a[2] ^ a[6] ^ a[7];
    end
endfunction

function automatic [7:0] inv_iso;
    input [7:0] a;
    begin
    inv_iso[0]= a[0] ^ a[1] ^ a[4];
    inv_iso[1]= a[4] ^ a[5] ^ a[6];
    inv_iso[2]= a[2] ^ a[3] ^ a[4] ^ a[6] ^ a[7];
    inv_iso[3]= a[2] ^ a[3] ^ a[4] ^ a[5] ^ a[6];
    inv_iso[4]= a[2] ^ a[4];
    inv_iso[5]= a[1] ^ a[6];
    inv_iso[6]= a[1] ^ a[2] ^ a[5] ^ a[6];
    inv_iso[7]= a[1] ^ a[6] ^ a[7];
    end
endfunction

function automatic [3:0] gf4_sq;
    input [3:0] a;
    begin
    gf4_sq[3] = a[3];
    gf4_sq[2] = a[1] ^ a[3];
    gf4_sq[1] = a[2];
    gf4_sq[0] = a[0] ^ a[2];
    end
endfunction

function automatic [3:0] gf4_sq_mul_v;
    input [3:0] a;

    reg [3:0] a_sq;

    reg [3:0] a_1;
    reg [3:0] a_2;
    reg [3:0] a_3;

    reg [3:0] p_0;
    reg [3:0] p_1;
    reg [3:0] p_2;

    begin
    a_sq[3] = a[3];
    a_sq[2] = a[1] ^ a[3];
    a_sq[1] = a[2];
    a_sq[0] = a[0] ^ a[2];

    p_0 = a_sq;
    a_1 = {a_sq[2:0], 1'b0} ^ ((a_sq[3])? 4'b0011 : 4'b0);

    p_1 = p_0;
    a_2 = {a_1[2:0], 1'b0} ^ ((a_1[3])? 4'b0011 : 4'b0);

    p_2 = p_1 ^ a_2;
    a_3 = {a_2[2:0], 1'b0} ^ ((a_2[3])? 4'b0011 : 4'b0);

    gf4_sq_mul_v = p_2 ^ a_3;
    end
endfunction

function automatic [3:0] gf4_mul;
    input [3:0] a;
    input [3:0] b;
    reg [3:0] a_1;
    reg [3:0] a_2;
    reg [3:0] a_3;

    reg [3:0] p_0;
    reg [3:0] p_1;
    reg [3:0] p_2;
    begin
    p_0 = (b[0])? a : 4'b0;
    a_1 = {a[2:0], 1'b0} ^ ((a[3])? 4'b0011 : 4'b0);

    p_1 = p_0 ^ ((b[1])? a_1 : 4'b0);
    a_2 = {a_1[2:0], 1'b0} ^ ((a_1[3])? 4'b0011 : 4'b0);

    p_2 = p_1 ^ ((b[2])? a_2 : 4'b0);
    a_3 = {a_2[2:0], 1'b0} ^ ((a_2[3])? 4'b0011 : 4'b0);

    gf4_mul = p_2 ^ ((b[3])? a_3 : 4'b0);
    end
endfunction

function automatic [3:0] gf4_inv;
    input [3:0] a;
    begin
    gf4_inv[3] = (a[3] & a[2] & a[1] & a[0]) | (~a[3] & ~a[2] & a[1]) | (~a[3] & a[2] & ~a[1]) | (a[3] & ~a[2] & ~a[0]) | (a[2] & ~a[1] & ~a[0]);
    gf4_inv[2] = (a[3] & a[2] & ~a[1] & a[0]) | (~a[3] & a[2] & ~a[0]) | (a[3] & ~a[2] & ~a[0]) | (~a[2] & a[1] & a[0]) | (~a[3] & a[1] & a[0]);
    gf4_inv[1] =  (a[3] & ~a[2] & ~a[1]) | (~a[3] & a[1] & a[0]) | (~a[3] & a[2] & a[0]) | (a[3] & a[2] & ~a[0]) | (~a[3] & a[2] & a[1]);
    gf4_inv[0] = (a[3] & ~a[2] & ~a[1] & ~a[0]) | (a[3] & ~a[2] & a[1] & a[0]) | (~a[3] & ~a[1] & a[0]) | (~a[3] & a[1] & ~a[0]) | (a[2] & a[1] & ~a[0]) | (~a[3] & a[2] & ~a[1]);
    end
endfunction

genvar i;
for(i=0; i<=120; i=i+8)
begin
    assign out[i+7:i] = inv_sbox(in[i+7:i]);
end

endmodule

