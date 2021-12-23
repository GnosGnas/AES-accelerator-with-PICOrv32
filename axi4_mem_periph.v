module axi4_mem_periph #(
	parameter AXI_TEST = 0,
	parameter VERBOSE = 0
) (
	/* verilator lint_off MULTIDRIVEN */

	input             clk,
	input             mem_axi_awvalid,
	output reg        mem_axi_awready,
	input      [31:0] mem_axi_awaddr,
	input      [ 2:0] mem_axi_awprot,

	input             mem_axi_wvalid,
	output reg        mem_axi_wready,
	input      [31:0] mem_axi_wdata,
	input      [ 3:0] mem_axi_wstrb,

	output reg        mem_axi_bvalid,
	input             mem_axi_bready,

	input             mem_axi_arvalid,
	output reg        mem_axi_arready,
	input      [31:0] mem_axi_araddr,
	input      [ 2:0] mem_axi_arprot,

	output reg        mem_axi_rvalid,
	input             mem_axi_rready,
	output reg [31:0] mem_axi_rdata,

	output reg        tests_passed
);
	reg [31:0]   memory [0:128*1024/4-1] /* verilator public */;
	reg verbose;
	initial verbose = $test$plusargs("verbose") || VERBOSE;

	initial begin
		mem_axi_awready = 0;
		mem_axi_wready = 0;
		mem_axi_bvalid = 0;
		mem_axi_arready = 0;
		mem_axi_rvalid = 0;
		tests_passed = 0;
	end

	reg latched_raddr_en = 0;
	reg latched_waddr_en = 0;
	reg latched_wdata_en = 0;

	reg fast_raddr = 0;
	reg fast_waddr = 0;
	reg fast_wdata = 0;

	reg [31:0] latched_raddr;
	reg [31:0] latched_waddr;
	reg [31:0] latched_wdata;
	reg [ 3:0] latched_wstrb;
	reg        latched_rinsn;
	
	//// Our modifications for AES accelerator
    reg reset;
	reg pt_valid, ct_valid;
	reg [127:0] pt_encr, ct_decr;
	wire ct_rdy, pt_rdy;
	wire [127:0] ct_encr, pt_decr;
	reg [1:0] key_len;
	wire key_mem_status, key_inp_ready;
	reg [255:0] short_key;
	wire error;
	reg key_status;
	wire pt_in_en, ct_in_en;
	
	parameter BASE_Addr = 32'h2500_0000;
	
	AES A (.clk(clk), .reset(reset), 
	       .pt_valid(pt_valid), .pt_encr(pt_encr), .pt_in_en(pt_in_en),
	       .ct_rdy(ct_rdy), .ct_encr(ct_encr), .ct_in_en(ct_in_en),
	       .ct_valid(ct_valid), .ct_decr(ct_decr),
	       .pt_rdy(pt_rdy), .pt_decr(pt_decr),
	       .key_len(key_len), .key_mem_status(key_mem_status),
           .short_key(short_key), .error(error), .key_inp_ready(key_inp_ready));
	////contd later
	
	task handle_axi_arvalid; begin
		mem_axi_arready <= 1;
		latched_raddr = mem_axi_araddr;
		latched_rinsn = mem_axi_arprot[2];
		latched_raddr_en = 1;
		fast_raddr <= 1;
	end endtask

	task handle_axi_awvalid; begin
		mem_axi_awready <= 1;
		latched_waddr = mem_axi_awaddr;
		latched_waddr_en = 1;
		fast_waddr <= 1;
	end endtask

	task handle_axi_wvalid; begin
		mem_axi_wready <= 1;
		latched_wdata = mem_axi_wdata;
		latched_wstrb = mem_axi_wstrb;
		latched_wdata_en = 1;
		fast_wdata <= 1;
	end endtask

	task handle_axi_rvalid; begin
		if (verbose)
			$display("RD: ADDR=%08x DATA=%08x%s", latched_raddr, memory[latched_raddr >> 2], latched_rinsn ? " INSN" : "");
		if (latched_raddr < 128*1024) begin
			mem_axi_rdata <= memory[latched_raddr >> 2];
			mem_axi_rvalid <= 1;
			latched_raddr_en = 0;
		end else
		//// MODS for AES
		//AES outputs
		if (latched_raddr == BASE_Addr) begin
			// ct_rdy
			mem_axi_rdata <= {31'd0,ct_rdy};
			mem_axi_rvalid <= 1;
			latched_raddr_en = 0; 
		end else
		if (latched_raddr == BASE_Addr+4) begin
			// ct_encr-1
			mem_axi_rdata <= ct_encr[127:96];
			mem_axi_rvalid <= 1;
			latched_raddr_en = 0; 
		end else
		if (latched_raddr == BASE_Addr+8) begin
			// ct_encr-2
			mem_axi_rdata <= ct_encr[95:64];
			mem_axi_rvalid <= 1;
			latched_raddr_en = 0; 
		end else
		if (latched_raddr == BASE_Addr+12) begin
			// ct_encr-3
			mem_axi_rdata <= ct_encr[63:32];
			mem_axi_rvalid <= 1;
			latched_raddr_en = 0; 
		end else
		if (latched_raddr == BASE_Addr+16) begin
			// ct_encr-4
			mem_axi_rdata <= ct_encr[31:0];
			mem_axi_rvalid <= 1;
			latched_raddr_en = 0; 
		end else
		if (latched_raddr == BASE_Addr+20) begin
			// pt_rdy
			mem_axi_rdata <= {31'd0,pt_rdy};
			mem_axi_rvalid <= 1;
			latched_raddr_en = 0; 
		end else
		if (latched_raddr == BASE_Addr+24) begin
			// pt_decr-1
			mem_axi_rdata <= pt_decr[127:96];
			mem_axi_rvalid <= 1;
			latched_raddr_en = 0; 
		end else
		if (latched_raddr == BASE_Addr+28) begin
			// pt_decr-2
			mem_axi_rdata <= pt_decr[95:64];
			mem_axi_rvalid <= 1;
			latched_raddr_en = 0; 
		end else
		if (latched_raddr == BASE_Addr+32) begin
			// pt_decr-3
			mem_axi_rdata <= pt_decr[63:32];
			mem_axi_rvalid <= 1;
			latched_raddr_en = 0; 
		end else
		if (latched_raddr == BASE_Addr+36) begin
			// pt_decr-4
			mem_axi_rdata <= pt_decr[31:0];
			mem_axi_rvalid <= 1;
			latched_raddr_en = 0; 
		end else
		if (latched_raddr == BASE_Addr+40) begin
			// key_inp_rdy
			mem_axi_rdata <= {31'd0,key_inp_ready};
			mem_axi_rvalid <= 1;
			latched_raddr_en = 0; 
		end else
		if (latched_raddr == BASE_Addr+44) begin
			// error bit
			mem_axi_rdata <= {31'd0,error};
			mem_axi_rvalid <= 1;
			latched_raddr_en = 0; 
		end else
		if (latched_raddr == BASE_Addr+48) begin
			// key_exp_status
			mem_axi_rdata <= {31'd0,key_mem_status};
			mem_axi_rvalid <= 1;
			latched_raddr_en = 0; 
		end else
		if (latched_raddr == BASE_Addr+52) begin
			// pt_in_en
			mem_axi_rdata <= {31'd0, pt_in_en};
			mem_axi_rvalid <= 1;
			latched_raddr_en = 0;
		end else
		if (latched_raddr == BASE_Addr+56) begin
			// ct_in_en
			mem_axi_rdata <= {31'd0, ct_in_en};
			mem_axi_rvalid <= 1;
			latched_raddr_en = 0;
		end		
		////contd later
		else begin
		$display($time, "Bad");
			$display("OUT-OF-BOUNDS MEMORY READ FROM %08x", latched_raddr);
			$finish;
		end
	end endtask

	task handle_axi_bvalid; begin
		if (verbose)
			$display("WR: ADDR=%08x DATA=%08x STRB=%04b", latched_waddr, latched_wdata, latched_wstrb);
		if (latched_waddr < 128*1024) begin
			if (latched_wstrb[0]) memory[latched_waddr >> 2][ 7: 0] <= latched_wdata[ 7: 0];
			if (latched_wstrb[1]) memory[latched_waddr >> 2][15: 8] <= latched_wdata[15: 8];
			if (latched_wstrb[2]) memory[latched_waddr >> 2][23:16] <= latched_wdata[23:16];
			if (latched_wstrb[3]) memory[latched_waddr >> 2][31:24] <= latched_wdata[31:24];
		end else
		if (latched_waddr == 32'h1000_0000) begin
			if (verbose) begin
				if (32 <= latched_wdata && latched_wdata < 128)
					$display("OUT: '%c'", latched_wdata[7:0]);
				else
					$display("OUT: %3d", latched_wdata);
			end else begin
				$write("%c", latched_wdata[7:0]);
`ifndef VERILATOR
				$fflush();
`endif
			end
		end else
		// address below used by assembly in start.S - we are not using this
		if (latched_waddr == 32'h2000_0000) begin
			if (latched_wdata == 1)
				tests_passed = 1;
		end else 
		// Changed the target address for the 'all pass' so that it can be written from C
		if (latched_waddr == 32'h2100_0000) begin
			if (latched_wdata == 1)
				tests_passed = 1;
		end else 
		//// MODS for AES
		//AES inputs
		if (latched_waddr == BASE_Addr) begin 
			// Keylen
            key_len <= latched_wdata[1:0];
		end else
		if (latched_waddr == BASE_Addr+4) begin 
			// Key-1
			short_key[255:224] <= latched_wdata;
		end else	
		if (latched_waddr == BASE_Addr+8) begin 
			// Key-2
			short_key[223:192] <= latched_wdata;
		end else
		if (latched_waddr == BASE_Addr+12) begin 
			// Key-3
			short_key[191:160] <= latched_wdata;
		end else
		if (latched_waddr == BASE_Addr+16) begin 
			// Key-4
			short_key[159:128] <= latched_wdata;
		end else	
		if (latched_waddr == BASE_Addr+20) begin 
			// Key-5
			short_key[127:96] <= latched_wdata;
		end else
		if (latched_waddr == BASE_Addr+24) begin 
			// Key-6
			short_key[95:64] <= latched_wdata;
		end else
		if (latched_waddr == BASE_Addr+28) begin 
			// Key-7
			short_key[63:32] <= latched_wdata;
		end else
		if (latched_waddr == BASE_Addr+32) begin 
			// Key-8
			short_key[31:0] <= latched_wdata;
		end else
		if (latched_waddr == BASE_Addr+36) begin 
			// pt_encr-1
			pt_encr[127:96] <= latched_wdata;
		end else
		if (latched_waddr == BASE_Addr+40) begin 
			// pt_encr-2
			pt_encr[95:64] <= latched_wdata;
		end else
		if (latched_waddr == BASE_Addr+44) begin 
			// pt_encr-3
			pt_encr[63:32] <= latched_wdata;
		end else
		if (latched_waddr == BASE_Addr+48) begin 
			// pt_encr-4
			pt_encr[31:0] <= latched_wdata;
		end else
		if (latched_waddr == BASE_Addr+52) begin 
			// pt valid
			pt_valid <= latched_wdata[0];
		end else 
		if (latched_waddr == BASE_Addr+56) begin 
			// ct_decr-1
			ct_decr[127:96] <= latched_wdata;
		end else 
		if (latched_waddr == BASE_Addr+60) begin 
			// ct_decr-2
			ct_decr[95:64] <= latched_wdata;
		end else 
		if (latched_waddr == BASE_Addr+64) begin 
			// ct_decr-3
			ct_decr[63:32] <= latched_wdata;
		end else 
		if (latched_waddr == BASE_Addr+68) begin 
			// ct_decr-4
			ct_decr[31:0] <= latched_wdata;
		end else 
		if (latched_waddr == BASE_Addr+72) begin 
			// ct valid
			ct_valid <= latched_wdata[0];
		end else
        if (latched_waddr == BASE_Addr+76) begin
            // reset
            reset <= latched_wdata[0];
			if (latched_wdata[0]) begin
				key_len <= 0; // Necessary for proper working
			end
			//// end of mods
        end
		else begin
			$display("OUT-OF-BOUNDS MEMORY WRITE TO %08x", latched_waddr);
			$finish;
		end
		mem_axi_bvalid <= 1;
		latched_waddr_en = 0;
		latched_wdata_en = 0;
	end endtask

	always @(negedge clk) begin
		if (mem_axi_arvalid && !(latched_raddr_en || fast_raddr)) handle_axi_arvalid;
		if (mem_axi_awvalid && !(latched_waddr_en || fast_waddr)) handle_axi_awvalid;
		if (mem_axi_wvalid  && !(latched_wdata_en || fast_wdata)) handle_axi_wvalid;
		if (!mem_axi_rvalid && latched_raddr_en) handle_axi_rvalid;
		if (!mem_axi_bvalid && latched_waddr_en && latched_wdata_en) handle_axi_bvalid;
	end

	always @(posedge clk) begin
		mem_axi_arready <= 0;
		mem_axi_awready <= 0;
		mem_axi_wready <= 0;

		fast_raddr <= 0;
		fast_waddr <= 0;
		fast_wdata <= 0;

		if (mem_axi_rvalid && mem_axi_rready) begin
			mem_axi_rvalid <= 0;
		end

		if (mem_axi_bvalid && mem_axi_bready) begin
			mem_axi_bvalid <= 0;
		end

		if (mem_axi_arvalid && mem_axi_arready && !fast_raddr) begin
			latched_raddr = mem_axi_araddr;
			latched_rinsn = mem_axi_arprot[2];
			latched_raddr_en = 1;
		end

		if (mem_axi_awvalid && mem_axi_awready && !fast_waddr) begin
			latched_waddr = mem_axi_awaddr;
			latched_waddr_en = 1;
		end

		if (mem_axi_wvalid && mem_axi_wready && !fast_wdata) begin
			latched_wdata = mem_axi_wdata;
			latched_wstrb = mem_axi_wstrb;
			latched_wdata_en = 1;
		end

		if (mem_axi_arvalid && !(latched_raddr_en || fast_raddr)) handle_axi_arvalid;
		if (mem_axi_awvalid && !(latched_waddr_en || fast_waddr)) handle_axi_awvalid;
		if (mem_axi_wvalid  && !(latched_wdata_en || fast_wdata)) handle_axi_wvalid;

		if (!mem_axi_rvalid && latched_raddr_en) handle_axi_rvalid;
		if (!mem_axi_bvalid && latched_waddr_en && latched_wdata_en) handle_axi_bvalid;
	end
endmodule

