 module key_exp_outer(
    input clk,
    input reset,
    input start,
    input [255:0] short_key,
    input [1:0] key_len,
    output valid,                                 //Subkey valid or not
    output reset_valid_bits,
    output [3:0] waddr,
    output [127:0] subkey,
    output [1:0] key_len_reg
 );
    wire [127:0] subkey128;
    wire [127:0] subkey192;
    wire [127:0] subkey256;
    wire valid_skey128, valid_skey192, valid_skey256;
    wire[3:0] cnt128, cnt192, cnt256;

    reg start128, start192, start256; 
    reg [255:0] prev_key;
    reg [1:0] key_len_reg;
    reg [127:0] subkey;
    reg reset_valid_bits;
    reg [3:0] waddr;

    assign valid = (valid_skey128 | valid_skey192 | valid_skey256);

    always @(*) begin
        case(key_len_reg)
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
            key_len_reg <= 0;
            start128 <= 0;
            start192 <= 0;
            start256 <= 0;
            reset_valid_bits <= 0;
        end
        else begin
            if(start) begin
                if((prev_key == short_key) && (key_len_reg == key_len)) begin
                    start128 <= 0;
                    start192 <= 0;
                    start256 <= 0;
                    reset_valid_bits <= 0;
                end
                else begin
                    key_len_reg <= key_len;
                    prev_key <= short_key;
                    reset_valid_bits <= 1;
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
    reg [127:0] prev_period_key_1;
    reg status;

    wire [31:0] key1, key2, key3, key4;
    assign cnt128 = i;

    current_word_gen_128 word1(.i({i,2'd0}),.prev_word(prev_period_key_1[31:0]),.prev_period_word(prev_period_key_1[127:96]),.current_word(key1));
    current_word_gen_128 word2(.i({i,2'd1}),.prev_word(key1),.prev_period_word(prev_period_key_1[95:64]),.current_word(key2));
    current_word_gen_128 word3(.i({i,2'd2}),.prev_word(key2),.prev_period_word(prev_period_key_1[63:32]),.current_word(key3));
    current_word_gen_128 word4(.i({i,2'd3}),.prev_word(key3),.prev_period_word(prev_period_key_1[31:0]),.current_word(key4));

    assign subkey = {key1, key2, key3, key4};
    assign valid_skey = status;

    always @(posedge clk)
    begin
        if(reset) begin
        i <= 0;
        prev_period_key_1 <= 0;
        status <= 0;
        end
        else begin
            if (start) begin
                i <= 1; //4
                prev_period_key_1 <= short_key;
                $display("Short key: %h, %d",short_key, i);
                status <= 1;
            end
            else if((i>=1) && (i<10)) begin //40
                prev_period_key_1 <= {key1,key2,key3,key4};
                i <= i+1; //+4
                $display("Short key: %h, %d",{key1,key2,key3,key4}, i);
            end
            else if(i==10) begin //40
                i <= 0;
                status <= 0;
                prev_period_key_1 <= 0;
                $display("Short key: %h, %d",{key1,key2,key3,key4}, i);
            end
        end
    end
endmodule


module current_word_gen_128(
    input [5:0] i,
    input [31:0] prev_word,
    input [31:0] prev_period_word,
    output [31:0] current_word
);

reg [31:0] current_word;
reg [31:0] temp;

always @(*)  
begin
    case(i[1:0])
    2'd0: temp = {sbox(prev_word[23:16]),sbox(prev_word[15:8]),sbox(prev_word[7:0]),sbox(prev_word[31:24])}^{rcon(i[5:2]), 24'b0};
    default: temp = prev_word;
    endcase

    current_word = (prev_period_word)^(temp);
end

function automatic [7:0] rcon;
    input [3:0] val;
    begin
        case(val)
        4'd1: rcon = 8'h01;
        4'd2: rcon = 8'h02;
        4'd3: rcon = 8'h04;
        4'd4: rcon = 8'h08;
        4'd5: rcon = 8'h10;
        4'd6: rcon = 8'h20;
        4'd7: rcon = 8'h40;
        4'd8: rcon = 8'h80;
        4'd9: rcon = 8'h1B;
        4'd10: rcon = 8'h36;
        default: ; 
        endcase
    end
endfunction

function automatic [7:0] sbox;
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
    out_iso = isomorph(in_byte);

    g1 = out_iso[7:4];
    g0 = out_iso[3:0];

    g1_g0_t = gf4_mul(g1, g0);
    g0_sq = gf4_sq(g0);
    g1_sq_mult_v = gf4_sq_mul_v(g1);

    inverse = gf4_inv((g1_g0_t ^ g0_sq ^ g1_sq_mult_v));

    d1 = gf4_mul(g1, inverse);
    d0 = gf4_mul((g0 ^ g1), inverse);

    sbox = inv_isomorph_and_affine({d1, d0});
    end
endfunction

function automatic [7:0] isomorph;
    input [7:0] a;
    begin
        isomorph[7] =a[5] ^ a[7];
        isomorph[6] =a[1] ^ a[5] ^ a[4] ^ a[6];
        isomorph[5] =a[3] ^ a[2] ^ a[5] ^ a[7];
        isomorph[4] =a[3] ^ a[2] ^ a[4] ^ a[7] ^ a[6];
        isomorph[3] =a[1] ^ a[2] ^ a[7] ^ a[6];
        isomorph[2] =a[3] ^ a[2] ^ a[7] ^ a[6];
        isomorph[1] =a[1] ^ a[4] ^ a[6];
        isomorph[0] =a[1] ^ a[0] ^ a[3] ^ a[2] ^ a[7];
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

function automatic [7:0] inv_isomorph_and_affine;
    input [7:0] delta;
    begin
    inv_isomorph_and_affine[7] = delta[1] ^ delta[2] ^ delta[3] ^ delta[7];
    inv_isomorph_and_affine[6] = ~(delta[4] ^ delta[7]);
    inv_isomorph_and_affine[5] = ~(delta[1] ^ delta[2] ^ delta[7]);
    inv_isomorph_and_affine[4] = delta[0] ^ delta[1] ^ delta[2] ^ delta[4] ^ delta[6] ^ delta[7];
    inv_isomorph_and_affine[3] = delta[0];
    inv_isomorph_and_affine[2] = delta[0] ^ delta[1] ^ delta[3] ^ delta[4];
    inv_isomorph_and_affine[1] = ~(delta[0] ^ delta[2] ^ delta[7]);
    inv_isomorph_and_affine[0] = ~(delta[0] ^ delta[5] ^ delta[6] ^ delta[7]);
    end
endfunction

endmodule

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
	reg [191:0] prev_period_key_1; 
	reg status;

	wire [31:0] key1, key2, key3, key4;
    assign cnt192 = i[4:1];
 
	current_word_gen_192 word1(.i({i,1'd0}),.prev_word(prev_period_key_1[31:0]),.prev_period_word(prev_period_key_1[191:160]),.current_word(key1));
	current_word_gen_192 word2(.i({i,1'd1}),.prev_word(key1),.prev_period_word(prev_period_key_1[159:128]),.current_word(key2));
	current_word_gen_192 word3(.i({i[4:1],2'd2}),.prev_word(key2),.prev_period_word(prev_period_key_1[127:96]),.current_word(key3));
	current_word_gen_192 word4(.i({i[4:1],2'd3}),.prev_word(key3),.prev_period_word(prev_period_key_1[95:64]),.current_word(key4));
	assign subkey = (i==3)? ({prev_period_key_1[63:0], key1, key2}): ({key1, key2, key3, key4}); //6
	assign valid_skey = status;

	always @(posedge clk)
	begin
		if(reset) begin
		i <= 0;
		prev_period_key_1 <= 0;
		status <= 0;
		end
		else begin
			if (start) begin
				i <= 3; //6
				prev_period_key_1 <= short_key;
				status <= 1;
			end
			else if (i==3) begin //6
				i <= 4; //8
				prev_period_key_1 = {prev_period_key_1[127:0],key1,key2};
				status <= 1;
			end
			else if((i>=4) && (i<24)) begin //48
				i <= i+2; //+4
				prev_period_key_1 = {prev_period_key_1[63:0],key1,key2,key3,key4};
				status <= 1;
			end
			else if(i==24) begin //48
				i <= 0;
				status <= 0;
				prev_period_key_1 <= 0;
			end
		end
	end
endmodule



module current_word_gen_192(
    input [5:0] i,
    input [31:0] prev_word,
    input [31:0] prev_period_word,
    output [31:0] current_word
);

	reg [31:0] current_word;
	reg [31:0] temp;

	always @(*)  
	begin
		case(i)
		6'd6: temp = {sbox(prev_word[23:16]),sbox(prev_word[15:8]),sbox(prev_word[7:0]),sbox(prev_word[31:24])}^{rcon(quotient(i)),24'd0};
		6'd12: temp = {sbox(prev_word[23:16]),sbox(prev_word[15:8]),sbox(prev_word[7:0]),sbox(prev_word[31:24])}^{rcon(quotient(i)),24'd0};
		6'd18: temp = {sbox(prev_word[23:16]),sbox(prev_word[15:8]),sbox(prev_word[7:0]),sbox(prev_word[31:24])}^{rcon(quotient(i)),24'd0};
		6'd24: temp = {sbox(prev_word[23:16]),sbox(prev_word[15:8]),sbox(prev_word[7:0]),sbox(prev_word[31:24])}^{rcon(quotient(i)),24'd0};
		6'd30: temp = {sbox(prev_word[23:16]),sbox(prev_word[15:8]),sbox(prev_word[7:0]),sbox(prev_word[31:24])}^{rcon(quotient(i)),24'd0};
		6'd36: temp = {sbox(prev_word[23:16]),sbox(prev_word[15:8]),sbox(prev_word[7:0]),sbox(prev_word[31:24])}^{rcon(quotient(i)),24'd0};
		6'd42: temp = {sbox(prev_word[23:16]),sbox(prev_word[15:8]),sbox(prev_word[7:0]),sbox(prev_word[31:24])}^{rcon(quotient(i)),24'd0};
		6'd48: temp = {sbox(prev_word[23:16]),sbox(prev_word[15:8]),sbox(prev_word[7:0]),sbox(prev_word[31:24])}^{rcon(quotient(i)),24'd0};
		default: temp = prev_word;
		endcase
		current_word = (prev_period_word)^(temp);
	end

	function automatic [3:0] quotient;
		input [5:0] i;
		begin
			case(i)
			6'd0: quotient = 4'd0;
			6'd6: quotient = 4'd1;
			6'd12: quotient = 4'd2;
			6'd18: quotient = 4'd3;
			6'd24: quotient = 4'd4;
			6'd30: quotient = 4'd5;
			6'd36: quotient = 4'd6;
			6'd42: quotient = 4'd7;
			6'd48: quotient = 4'd8;
			default: ;
			endcase
		end
	endfunction

	function automatic [7:0] rcon;
		input [3:0] val;
		begin
			case(val)
			4'd1: rcon = 8'h01;
			4'd2: rcon = 8'h02;
			4'd3: rcon = 8'h04;
			4'd4: rcon = 8'h08;
			4'd5: rcon = 8'h10;
			4'd6: rcon = 8'h20;
			4'd7: rcon = 8'h40;
			4'd8: rcon = 8'h80;
			4'd9: rcon = 8'h1B;
			4'd10: rcon = 8'h36;
			default: ; 
			endcase
		end
	endfunction

	function automatic [7:0] sbox;
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
		out_iso = isomorph(in_byte);

		g1 = out_iso[7:4];
		g0 = out_iso[3:0];

		g1_g0_t = gf4_mul(g1, g0);
		g0_sq = gf4_sq(g0);
		g1_sq_mult_v = gf4_sq_mul_v(g1);

		inverse = gf4_inv((g1_g0_t ^ g0_sq ^ g1_sq_mult_v));

		d1 = gf4_mul(g1, inverse);
		d0 = gf4_mul((g0 ^ g1), inverse);

		sbox = inv_isomorph_and_affine({d1, d0});
		end
	endfunction

	function automatic [7:0] isomorph;
		input [7:0] a;
		begin
			isomorph[7] =a[5] ^ a[7];
			isomorph[6] =a[1] ^ a[5] ^ a[4] ^ a[6];
			isomorph[5] =a[3] ^ a[2] ^ a[5] ^ a[7];
			isomorph[4] =a[3] ^ a[2] ^ a[4] ^ a[7] ^ a[6];
			isomorph[3] =a[1] ^ a[2] ^ a[7] ^ a[6];
			isomorph[2] =a[3] ^ a[2] ^ a[7] ^ a[6];
			isomorph[1] =a[1] ^ a[4] ^ a[6];
			isomorph[0] =a[1] ^ a[0] ^ a[3] ^ a[2] ^ a[7];
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

	function automatic [7:0] inv_isomorph_and_affine;
		input [7:0] delta;
		begin
		inv_isomorph_and_affine[7] = delta[1] ^ delta[2] ^ delta[3] ^ delta[7];
		inv_isomorph_and_affine[6] = ~(delta[4] ^ delta[7]);
		inv_isomorph_and_affine[5] = ~(delta[1] ^ delta[2] ^ delta[7]);
		inv_isomorph_and_affine[4] = delta[0] ^ delta[1] ^ delta[2] ^ delta[4] ^ delta[6] ^ delta[7];
		inv_isomorph_and_affine[3] = delta[0];
		inv_isomorph_and_affine[2] = delta[0] ^ delta[1] ^ delta[3] ^ delta[4];
		inv_isomorph_and_affine[1] = ~(delta[0] ^ delta[2] ^ delta[7]);
		inv_isomorph_and_affine[0] = ~(delta[0] ^ delta[5] ^ delta[6] ^ delta[7]);
		end
	endfunction

endmodule

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
reg status;

wire [31:0] key1, key2, key3, key4;
assign cnt256 = i;

current_word_gen_256 word1(.i({i,2'd0}),.prev_word(prev_period_key_2[31:0]),.prev_period_word(prev_period_key_1[127:96]),.current_word(key1));
current_word_gen_256 word2(.i({i,2'd1}),.prev_word(key1),.prev_period_word(prev_period_key_1[95:64]),.current_word(key2));
current_word_gen_256 word3(.i({i,2'd2}),.prev_word(key2),.prev_period_word(prev_period_key_1[63:32]),.current_word(key3));
current_word_gen_256 word4(.i({i,2'd3}),.prev_word(key3),.prev_period_word(prev_period_key_1[31:0]),.current_word(key4));
	
assign subkey = (i==1) ? prev_period_key_2 : {key1, key2, key3, key4};
assign valid_skey = status;


always @(posedge clk)
begin
    if(reset) begin
       i <= 0;
       prev_period_key_1 <= 0;
       prev_period_key_2 <= 0;
       status <= 0;
    end
    else begin
        if (start) begin
            i <= 1; //4
            prev_period_key_1 <= short_key[255:128];
            prev_period_key_2 <= short_key[127:0];
            status <= 1;
        end
        else if(i==1) begin
            i <= 2; //8
            prev_period_key_1 <= prev_period_key_1;
            prev_period_key_2 <= prev_period_key_2;
            status <= 1;
        end
        else if ((i>=2) && (i<14)) begin //56
            prev_period_key_1 <= prev_period_key_2;
            prev_period_key_2 <= {key1,key2,key3,key4};
            i <= i+1; //+4
        end
        else if(i==14) begin //56
            i <= 0;
            status <= 0;
            prev_period_key_1 <= 0;
            prev_period_key_2 <= 0;
        end
    end
end

endmodule

module current_word_gen_256(
    input [5:0] i,
    input [31:0] prev_word,
    input [31:0] prev_period_word,
    output [31:0] current_word
);

reg [31:0] current_word;
reg [31:0] temp;

always @(*)  
begin
    case(i[2:0])
    3'd0: temp = {sbox(prev_word[23:16]),sbox(prev_word[15:8]),sbox(prev_word[7:0]),sbox(prev_word[31:24])}^{rcon({1'b0,i[5:3]}),24'd0};
    3'd4: temp = {sbox(prev_word[31:24]),sbox(prev_word[23:16]),sbox(prev_word[15:8]),sbox(prev_word[7:0])};
    default: temp = prev_word;
    endcase
    current_word = (prev_period_word)^(temp);
end

function automatic [7:0] rcon;
    input [3:0] val;
    begin
        case(val)
        4'd1: rcon = 8'h01;
        4'd2: rcon = 8'h02;
        4'd3: rcon = 8'h04;
        4'd4: rcon = 8'h08;
        4'd5: rcon = 8'h10;
        4'd6: rcon = 8'h20;
        4'd7: rcon = 8'h40;
        4'd8: rcon = 8'h80;
        4'd9: rcon = 8'h1B;
        4'd10: rcon = 8'h36;
        default: ; 
        endcase
    end
endfunction

function automatic [7:0] sbox;
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
    out_iso = isomorph(in_byte);

    g1 = out_iso[7:4];
    g0 = out_iso[3:0];

    g1_g0_t = gf4_mul(g1, g0);
    g0_sq = gf4_sq(g0);
    g1_sq_mult_v = gf4_sq_mul_v(g1);

    inverse = gf4_inv((g1_g0_t ^ g0_sq ^ g1_sq_mult_v));

    d1 = gf4_mul(g1, inverse);
    d0 = gf4_mul((g0 ^ g1), inverse);

    sbox = inv_isomorph_and_affine({d1, d0});
    end
endfunction

function automatic [7:0] isomorph;
    input [7:0] a;
    begin
        isomorph[7] =a[5] ^ a[7];
        isomorph[6] =a[1] ^ a[5] ^ a[4] ^ a[6];
        isomorph[5] =a[3] ^ a[2] ^ a[5] ^ a[7];
        isomorph[4] =a[3] ^ a[2] ^ a[4] ^ a[7] ^ a[6];
        isomorph[3] =a[1] ^ a[2] ^ a[7] ^ a[6];
        isomorph[2] =a[3] ^ a[2] ^ a[7] ^ a[6];
        isomorph[1] =a[1] ^ a[4] ^ a[6];
        isomorph[0] =a[1] ^ a[0] ^ a[3] ^ a[2] ^ a[7];
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

function automatic [7:0] inv_isomorph_and_affine;
    input [7:0] delta;
    begin
    inv_isomorph_and_affine[7] = delta[1] ^ delta[2] ^ delta[3] ^ delta[7];
    inv_isomorph_and_affine[6] = ~(delta[4] ^ delta[7]);
    inv_isomorph_and_affine[5] = ~(delta[1] ^ delta[2] ^ delta[7]);
    inv_isomorph_and_affine[4] = delta[0] ^ delta[1] ^ delta[2] ^ delta[4] ^ delta[6] ^ delta[7];
    inv_isomorph_and_affine[3] = delta[0];
    inv_isomorph_and_affine[2] = delta[0] ^ delta[1] ^ delta[3] ^ delta[4];
    inv_isomorph_and_affine[1] = ~(delta[0] ^ delta[2] ^ delta[7]);
    inv_isomorph_and_affine[0] = ~(delta[0] ^ delta[5] ^ delta[6] ^ delta[7]);
    end
endfunction

endmodule






