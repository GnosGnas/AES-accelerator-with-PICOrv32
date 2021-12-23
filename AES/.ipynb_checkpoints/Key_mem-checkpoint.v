module keymem(
    input clk,
    input reset,
    input w_en,
    input reset_valid_bits,
    input [3:0] raddr_encr,
    input [3:0] raddr_decr,
    input [3:0] waddr,
    input [127:0] wkey,
    output [127:0] rkey_encr,
    output [127:0] rkey_decr,
    output [14:0] valid_bits 
);

reg [14:0] valid_bits;
integer i;
reg [127:0] mem [0:14];

assign rkey_encr = (valid_bits[raddr_encr]) ? mem[raddr_encr] : 128'bZ;
assign rkey_decr = (valid_bits[raddr_decr]) ? mem[raddr_decr] : 128'bZ;

always @(posedge clk) begin
    if(reset) begin
        for(i=0; i<15; i=i+1) begin
            valid_bits[i] <= 0;
            mem[i] <= 0;
        end
    end
    else if(reset_valid_bits) begin
        for(i=1; i<15; i=i+1) begin
            valid_bits[i] <= 0;
            mem[i] <= 0;
        end
    end
    else begin
        if(w_en) begin
            mem[waddr] <= wkey;
            valid_bits[waddr] <= 1; 
            $display($time," Keymem key : %h, %d",wkey,waddr);
        end
    end
end
endmodule
