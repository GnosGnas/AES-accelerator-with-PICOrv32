

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

	// Registers and Wires added for arbiter
	reg r_table_valid_in [(log2_cpu_burst - 1):0], r_table_valid_out [(log2_cpu_burst - 1):0];

	//my parameters
	localparam log2_cpu_burst = 8;
	localparam cpu_burst = 256;

	//AES control regs
	reg [31:0] latched_custom_inp;
	reg [log2_cpu_burst - 1:0] aes_input_size;
	reg [31:0] aes_pt_data;
	reg aes_pt_valid;
	reg in_enable;
	reg out_ready;
	reg [31:0] aes_out [3:0];
    reg pt_valid;
    wire ct_rdy;
    reg [127:0] pt_encr;
    wire [127:0] ct_encr;
    reg ct_valid;
    wire pt_rdy;
    reg [127:0] ct_decr;
    wire [127:0] pt_decr;
    reg [1:0] key_len;
    wire key_mem_status;
	wire key_inp_ready;
    reg [255:0] short_key;
    wire error;
	
	reg [2:0] status;

	AES myAES(clk, reset, pt_valid, ct_rdy, pt_encr, ct_encr, ct_valid, pt_rdy, ct_decr, pt_decr, key_len, key_mem_status, key_inp_ready, short_key, error);
	//////
	
	
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

	task handle_axi_arvalid; begin
		mem_axi_arready <= 1;
		latched_raddr = mem_axi_araddr;
		latched_rinsn = mem_axi_arprot[2];
		latched_raddr_en = 1;
		fast_raddr <= 1;
	end endtask

	task handle_axi_rvalid; begin
		if (verbose)
			$display("RD: ADDR=%08x DATA=%08x%s", latched_raddr, memory[latched_raddr >> 2], latched_rinsn ? " INSN" : "");

		// Arbitration not enabled
		if (!arb_en) begin
			if (latched_raddr < 128*1024) begin
				mem_axi_rdata <= memory[latched_raddr >> 2];
				mem_axi_rvalid <= 1;
				latched_raddr_en = 0;
			end
		end else

		// Arbitration enabled
		if (arb_en) begin
			// Read Conflicts
			if ((latched_raddr >= aes_dest_addr) && (latched_raddr < aes_dest_addr+16)) begin //start with dest_end
				if (out_ready) begin
					mem_axi_rdata <= aes_out[latched_raddr-aes_dest_addr];
					mem_axi_rvalid <= 1;
					latched_raddr_en = 0;
				end else begin
					mem_axi_rvalid <= 0;
					latched_raddr_en = 1;
				end
			end else
			if ((latched_raddr >= aes_dest_addr + 16) && (latched_raddr < aes_dest_addr_end)) begin
				temp = (aes_addr_start+{(latched_raddr-aes_dest_addr)[31:4],4'b0}); //will be treated as a wire

				if (r_table_valid_out[aes_dest_addr[8:4]]) begin
					mem_axi_rdata <= memory[latched_raddr >> 2];
					mem_axi_rvalid <= 1;
					latched_raddr_en = 0;
				end else if (in_enable) begin 
					latched_custom_inp = temp;
					input_switch <= 1;
					r_table_valid_in[temp[8:4]] <= 1;  //here i took index as 5 bits!!
					mem_axi_rvalid <= 0;
					latched_raddr_en = 1;	
				end else begin
					mem_axi_rvalid <= 0;
					latched_raddr_en = 1;
				end
			end else if (latched_raddr < 128*1024) begin
				// We have two cases so that we don't send the wrong information to the CPU
				if (latched_rarb_send) begin
					aes_pt_data <= memory[latched_raddr >> 2];
					aes_pt_valid <= 1;
					latched_rarb_send = 0;
					mem_axi_rvalid <= 0;
				end
				else begin
					mem_axi_rvalid <= 1;
					mem_axi_rdata <= memory[latched_raddr >> 2];
				end
				latched_raddr_en = 0;
			end
		end
		//if (latched_raddr == DONE) /// done /// status/// corresponding to key and decryption
			// Yet to add memory-mapped registers 
		////
		//AES outputs
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
		if (latched_raddr == BASE_Addr+56) begin
			// ct_in_en
			mem_axi_rdata <= {31'd0, ct_in_en};
			mem_axi_rvalid <= 1;
			latched_raddr_en = 0;
		end		
		else begin
			$display("OUT-OF-BOUNDS MEMORY READ FROM %08x", latched_raddr);
			$finish;
		end
	end endtask

	task handle_axi_bvalid; begin
		if (verbose)
			$display("WR: ADDR=%08x DATA=%08x STRB=%04b", latched_waddr, latched_wdata, latched_wstrb);
		
		// Arbitration not enabled
		if (!arb_en) begin
			if (latched_waddr < 128*1024) begin
				if (latched_wstrb[0]) memory[latched_waddr >> 2][ 7: 0] <= latched_wdata[ 7: 0];
				if (latched_wstrb[1]) memory[latched_waddr >> 2][15: 8] <= latched_wdata[15: 8];
				if (latched_wstrb[2]) memory[latched_waddr >> 2][23:16] <= latched_wdata[23:16];
				if (latched_wstrb[3]) memory[latched_waddr >> 2][31:24] <= latched_wdata[31:24];
			end else
		end else
		
		// Arbitration enabled
		if (arb_en) begin
			if (!latched_warb_send) begin
				if ((latched_waddr >= aes_addr_start+16) && (latched_waddr < aes_addr_end)) begin
					if (in_enable) begin
						temp = aes_addr_start+{(latched_waddr-aes_addr_start)[31:4],4'b0}; //will become a wire
						latched_custom_inp = temp;
						input_switch = 1;
						r_table_valid_in[temp[8:4]] <= 1;
						latched_waddr_en = 0;
						latched_wdata_en = 0;
						mem_axi_bvalid <= 1;

						if (latched_waddr < 128*1024) begin
							if (latched_wstrb[0]) memory[latched_waddr >> 2][ 7: 0] <= latched_wdata[ 7: 0];
							if (latched_wstrb[1]) memory[latched_waddr >> 2][15: 8] <= latched_wdata[15: 8];
							if (latched_wstrb[2]) memory[latched_waddr >> 2][23:16] <= latched_wdata[23:16];
							if (latched_wstrb[3]) memory[latched_waddr >> 2][31:24] <= latched_wdata[31:24];
						end
					end
					else begin
						mem_axi_bvalid <= 0;
						latched_waddr_en = 1;
						latched_wdata_en = 1;
					end
				end else
				if (latched_waddr < 128*1024) begin
					if (latched_wstrb[0]) memory[latched_waddr >> 2][ 7: 0] <= latched_wdata[ 7: 0];
					if (latched_wstrb[1]) memory[latched_waddr >> 2][15: 8] <= latched_wdata[15: 8];
					if (latched_wstrb[2]) memory[latched_waddr >> 2][23:16] <= latched_wdata[23:16];
					if (latched_wstrb[3]) memory[latched_waddr >> 2][31:24] <= latched_wdata[31:24];
				end

				if ((latched_waddr >= aes_dest_addr) && (latched_waddr < aes_dest_addr_end)) begin//check signs
				//w_table needs to store only 10bits of addr if burst = 255 and one bit for validity
					w_table_addr[latched_waddr[8:4]] <= latched_waddr[13:9];
					w_table_strb[latched_waddr[8:4]] <=  latched_wstrb;
				end else

			end else begin
				if ((w_table_addr[latched_waddr[8:4]] == latched_waddr[13:9]) && (|w_table_strb[latched_waddr[8:4]])) begin
					if (~w_table_strb[0]) memory[latched_waddr >> 2][ 7: 0] <= latched_wdata[ 7: 0];
					if (~w_table_strb[1]) memory[latched_waddr >> 2][15: 8] <= latched_wdata[15: 8];
					if (~w_table_strb[2]) memory[latched_waddr >> 2][23:16] <= latched_wdata[23:16];
					if (~w_table_strb[3]) memory[latched_waddr >> 2][31:24] <= latched_wdata[31:24];
				end
				else begin
					if (latched_wstrb[0]) memory[latched_waddr >> 2][ 7: 0] <= latched_wdata[ 7: 0];
					if (latched_wstrb[1]) memory[latched_waddr >> 2][15: 8] <= latched_wdata[15: 8];
					if (latched_wstrb[2]) memory[latched_waddr >> 2][23:16] <= latched_wdata[23:16];
					if (latched_wstrb[3]) memory[latched_waddr >> 2][31:24] <= latched_wdata[31:24];
				end
				
				latched_warb_send = 0;
				latched_waddr_en = 0;
				latched_wdata_en = 0;
			end
		end

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
				latched_waddr_en = 0;
				latched_wdata_en = 0;
				mem_axi_bvalid <= 1;
		end else
		// address below used by assembly in start.S - we are not using this
		if (latched_waddr == 32'h2000_0000) begin
			if (latched_wdata == 1)
				tests_passed = 1;

			latched_waddr_en = 0;
			latched_wdata_en = 0;
			mem_axi_bvalid <= 1;
		end else 
		// Changed the target address for the 'all pass' so that it can be written from C
		if (latched_waddr == 32'h2100_0000) begin
			if (latched_wdata == 1)
				tests_passed = 1;

				latched_waddr_en = 0;
				latched_wdata_en = 0;
				mem_axi_bvalid <= 1;
		end else 
		//give the starting input addr
		if (latched_waddr == BASE_Encrypt) begin
			$display("Writing %d to starting address",  latched_wdata);
			aes_addr_start <= latched_wdata;
			status <= 3'b001;
		end else
		//give the size of the chunk to work on
		if (latched_waddr == BASE_Encrypt+4) begin
			if (latched_wdata <= cpu_burst) begin
				aes_addr_end <= aes_addr_start + (latched_wdata<<2) - 1; //Check if addr more?? If order fixed then use status reg?	
				aes_input_size <= latched_wdata[log2_cpu_burst - 1 :0];
				status <= 3'b011;
			end
		end else
	
		if (latched_waddr == BASE_Encrypt+8) begin
			if (((latched_wdata - aes_addr_start < 0) && (latched_wdata + {22'b0, aes_input_size, 2'b0} - aes_addr_start < 0)) || (latched_wdata - aes_addr_start > {22'b0, aes_input_size, 2'b0})) begin
				aes_dest_addr <= latched_wdata;
				status <= 3'b111;
				arb_en <= 1'b1;
				in_enable <= 1'b1;
			end
		end else begin
			///// NEED TO ADD for key and decrytion
		
		////AES key_exp inputs
		if (latched_waddr == BASE_Addr) begin 
			//Keylen
			key_len <= latched_wdata[1:0];
		end else
		if (latched_waddr == BASE_Addr+4) begin 
			//Key-1
			short_key[255:224] <= latched_wdata;
		end else	
		if (latched_waddr == BASE_Addr+8) begin 
			//Key-2
			short_key[223:192] <= latched_wdata;
		end else
		if (latched_waddr == BASE_Addr+12) begin 
			//Key-3
			short_key[191:160] <= latched_wdata;
		end else
		if (latched_waddr == BASE_Addr+16) begin 
			//Key-4
			short_key[159:128] <= latched_wdata;
		end else	
		if (latched_waddr == BASE_Addr+20) begin 
			//Key-5
			short_key[127:96] <= latched_wdata;
		end else
		if (latched_waddr == BASE_Addr+24) begin 
			//Key-6
			short_key[95:64] <= latched_wdata;
		end else
		if (latched_waddr == BASE_Addr+28) begin 
			//Key-7
			short_key[63:32] <= latched_wdata;
		end else
		if (latched_waddr == BASE_Addr+32) begin 
			//Key-8
			short_key[31:0] <= latched_wdata;
		end else
		if (latched_waddr == BASE_Addr+56) begin 
			//ct_decr-1
			ct_decr[127:96] <= latched_wdata;
		end else 
		if (latched_waddr == BASE_Addr+60) begin 
			//ct_decr-2
			ct_decr[95:64] <= latched_wdata;
		end else 
		if (latched_waddr == BASE_Addr+64) begin 
			//ct_decr-3
			ct_decr[63:32] <= latched_wdata;
		end else
		if (latched_waddr == BASE_Addr+68) begin 
			//ct_decr-4
			ct_decr[31:0] <= latched_wdata;
		end

		latched_waddr_en = 0;
		latched_wdata_en = 0;
		mem_axi_bvalid <= 1; 
		end
		else begin
			$display("OUT-OF-BOUNDS MEMORY WRITE TO %08x", latched_waddr);
			$finish;
		end
	end endtask

	//one memory addr -> 32 bits so this is a state machine which puts 128 output bits to each of the 4 consecutive 32 bit memlocs
	task my_w_arb; begin
		latched_wdata = aes_out[counter];
		latched_wstrb = 4'b1111;
		latched_waddr = aes_dest_addr+(counter<<2); //move to next aligned word addr
		latched_waddr_en = 1;
		latched_wdata_en = 1;
		latched_warb_send = 1;
		r_table_valid_out[aes_dest_addr[8:4]] <= 1;
		if (counter == 3) begin
			latched_warb_en = 0;
			out_ready <= 0;
			in_enable <= 1;
			aes_addr_start <= aes_addr_start+16;
			if (aes_addr_start+16 == aes_addr_end)
				status <= 0;
		end
		counter <= counter + 1;
	end endtask

	//state machine which reads 4 consecutive 32 bit mem locs for a 128 bit aes input
	task my_r_arb; begin
		//if the current address has been read already out of order
		if ((counter==0) && r_table_valid_in[aes_addr_start[8:4]]) begin
				latched_rarb_en = 0; //see where aes_addr_start is changing
		end else begin
			if (input_switch) latched_raddr = latched_custom_inp;
			else latched_raddr = aes_addr_start + (rcounter<<2);
			//latched_raddr = aes_addr_start;
			latched_raddr_en = 1;
			//latched_rinsn = mem_axi_arprot[2]; //maybe/////////////////////
			rcounter <= rcounter + 1;
			latched_rarb_send = 1;
			r_table_valid_in[aes_addr_start[8:4]] <= 1;
			latched_rarb_en = 0;
			
			if (rcounter == 3) begin
				latched_rarb_en = 0;
			end
		end
	end endtask

	task my_arb_en; begin
		if (!latched_warb_en) begin
			if (out_ready) begin
				if (!(mem_axi_awvalid || mem_axi_wvalid)) //here basically checking if other masters related to cpu are active
					latched_warb_en = 1;
			end
		end
		if (!latched_rarb_en) begin
			if((in_enable) && (status==3'b111)) begin //status tells if given inputs r ok or not
				if(!mem_axi_arvalid)
					latched_rarb_en = 1;
			end
		end
	end endtask

	task aes_wrapper; begin
		if (status == 3'b111) begin
			if (aes_pt_valid) begin
				case (aes_cnt)
					2'd0: pt_encr[31:0] <= aes_pt_data;
					2'd1: pt_encr[63:32] <= aes_pt_data;
					2'd2: pt_encr[95:64] <= aes_pt_data;
					2'd3: pt_encr[127:96] <= aes_pt_data;
				endcase
				aes_cnt <= aes_cnt + 1;
				if (aes_cnt == 2'd3) begin
					pt_valid <= 1;
				end
				aes_pt_valid <= 0;
			end
			else if (pt_valid) pt_valid <= 0; ////see module behaviour\

			if ((!out_ready) && ct_rdy) begin
				out_ready <= 1;
				aes_out[3] <= ct_encr[127:96]; //
				aes_out[2] <= ct_encr[95:64];
				aes_out[1] <= ct_encr[63:32];
				aes_out[0] <= ct_encr[31:0];
			end

			if ((in_enable) && (!input_switch)) aes_dest_addr_start <= aes_dest_addr_start+16;
		end
		else begin
			arb_en <= 0;
			pt_valid <= 0;
			for (i=0; i<CPUBURST/4; i=i+1) begin
				r_table_valid_in[i] <= 0;
				r_table_valid_out[i] <= 0;
				w_table_addr[i] <= 0;
				w_table_strb[i] <= 0;
			end
		end
	end	endtask

	always @(negedge clk) begin
		if ((!latched_rar_en) && mem_axi_arvalid && !(latched_raddr_en || fast_raddr)) handle_axi_arvalid;
		if ((!latched_warb_en) && mem_axi_awvalid && !(latched_waddr_en || fast_waddr)) handle_axi_awvalid;
		if ((!latched_warb_en) && mem_axi_wvalid  && !(latched_wdata_en || fast_wdata)) handle_axi_wvalid;
		if (!mem_axi_rvalid && latched_raddr_en) handle_axi_rvalid;
		if (!mem_axi_bvalid && latched_waddr_en && latched_wdata_en) handle_axi_bvalid;
		if (arb_en && (out_ready)) my_arb_en;
		if ((latched_warb_en) && (!latched_warb_send)) my_w_arb;
		if ((latched_rar_en) && (!latched_rarb_send)) my_r_arb;
		aes_wrapper;
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

		if ((!latched_rarb_en) && mem_axi_arvalid && !(latched_raddr_en || fast_raddr)) handle_axi_arvalid;
		if ((!latched_warb_en) && mem_axi_awvalid && !(latched_waddr_en || fast_waddr)) handle_axi_awvalid;
		if ((!latched_warb_en) && mem_axi_wvalid  && !(latched_wdata_en || fast_wdata)) handle_axi_wvalid;
		if (!mem_axi_rvalid && latched_raddr_en) handle_axi_rvalid;
		if (!mem_axi_bvalid && latched_waddr_en && latched_wdata_en) handle_axi_bvalid;
		if (arb_en && (out_ready)) my_arb_en;
		aes_wrapper;
		if ((latched_warb_en) && (!latched_warb_send)) my_w_arb;
		if ((latched_rarb_en) && (!latched_rarb_send)) my_r_arb;
	end
endmodule
