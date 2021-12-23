// Project title   : AES Accelerator integrated with PicoRV32I via AXI4-Lite master
// Filename        : InvSubBytes.v
// Description     : Hardware modules to perform AES decryption
// Author          : Ruban Vishnu Pandian V (EE19B138)
// Date			   : 10th December, 2021

module InvSubBytes(
    input [127:0] in,
    output [127:0] out
);

//The inverse SBOX is applied on all bytes of the 128-bit input using a "For loop"
genvar i;
for(i=0; i<=120; i=i+8)
begin
    assign out[i+7:i] = inv_sbox(in[i+7:i]);
end

//Master "inv_sbox" function is defined below
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

//The helper functions used to define the master "inv_sbox" function are defined below
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
endmodule

