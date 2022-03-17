/* TODO: Vishnu Priya Ammina (amminavp) and Jackson Meyer - Lee (jmeye) */

`timescale 1ns / 1ps

// disable implicit wire declaration
`default_nettype none

module lc4_processor
   (input  wire        clk,                // main clock
    input wire         rst, // global reset
    input wire         gwe, // global we for single-step clock
                                    
    output wire [15:0] o_cur_pc, // Address to read from instruction memory
    input wire [15:0]  i_cur_insn, // Output of instruction memory
    output wire [15:0] o_dmem_addr, // Address to read/write from/to data memory
    input wire [15:0]  i_cur_dmem_data, // Output of data memory
    output wire        o_dmem_we, // Data memory write enable
    output wire [15:0] o_dmem_towrite, // Value to write to data memory
   
    output wire [1:0]  test_stall, // Testbench: is this is stall cycle? (don't compare the test values)
    output wire [15:0] test_cur_pc, // Testbench: program counter
    output wire [15:0] test_cur_insn, // Testbench: instruction bits
    output wire        test_regfile_we, // Testbench: register file write enable
    output wire [2:0]  test_regfile_wsel, // Testbench: which register to write in the register file 
    output wire [15:0] test_regfile_data, // Testbench: value to write into the register file
    output wire        test_nzp_we, // Testbench: NZP condition codes write enable
    output wire [2:0]  test_nzp_new_bits, // Testbench: value to write to NZP bits
    output wire        test_dmem_we, // Testbench: data memory write enable
    output wire [15:0] test_dmem_addr, // Testbench: address to read/write memory
    output wire [15:0] test_dmem_data, // Testbench: value read/writen from/to memory

    input wire [7:0]   switch_data, // Current settings of the Zedboard switches
    output wire [7:0]  led_data // Which Zedboard LEDs should be turned on?
    );
   
   /*** YOUR CODE HERE ***/

   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    * 
    * You may also use if statements inside the always block
    * to conditionally print out information.
    *
    * You do not need to resynthesize and re-implement if this is all you change;
    * just restart the simulation.
    */


wire [15:0] F_pc, D_pc, X_pc, M_pc, W_pc;
wire [2:0] D_stall, X_stall, M_stall, W_stall;


//PC
wire [15:0] pc_inc, next_pc;

cla16 inc_pc (.a(F_pc), .b(0), .cin(1), .sum(pc_inc));
assign next_pc = pc_inc;



//Fetch
Nbit_reg #(16, 16'h8200) REG_in_F_pc (.in(next_pc), .out(F_pc), .clk(clk), .we(reg_we), .gwe(gwe), .rst(rst));

Nbit_reg #(16) REG_F_D_pc (.in(F_pc), .out(D_pc), .clk(clk), .we(reg_we), .gwe(gwe), .rst(rst));
Nbit_reg #(2, 2'd2) REG_F_D_stall (.in(2'h0), .out(D_stall), .clk(clk), .we(1), .gwe(gwe), .rst(rst));


//Decode
 
wire [2:0] decode_r1sel, decode_r2sel, decode_wsel;
wire decode_r1re, decode_r2re, decode_regfile_we, decode_nzp_we, decode_select_pc_plus_one, decode_is_load, decode_is_store, decode_is_branch, decode_is_control_insn;

lc4_decoder decoder (.insn(i_cur_insn), 
      .r1sel(decode_r1sel), 
      .r1re(decode_r1re), 
      .r2sel(decode_r2sel),
      .r2re(decode_r2re),
      .wsel(decode_wsel),
      .regfile_we(decode_regfile_we),
      .nzp_we(decode_nzp_we),
      .select_pc_plus_one(decode_select_pc_plus_one),
      .is_load(decode_is_load),
      .is_store(decode_is_store),
      .is_branch(decode_is_branch),
      .is_control_insn(decode_is_control_insn));

wire [15:0] reg_rs_data, reg_rt_data, to_rd_data;

lc4_regfile D_regfile (.clk(clk), .gwe(gwe), .rst(rst),
      .i_rs(decode_r1sel),
      .o_rs_data(reg_rs_data),
      .i_rt(decode_r2sel),
      .o_rt_data(reg_rt_data),
      .i_rd(decode_wsel),
      .i_wdata(to_rd_data),
      .i_rd_we(decode_regfile_we));

Nbit_reg #(16, 16'h8200) REG_D_X_pc (.in(D_pc), .out(X_pc), .clk(clk), .we(reg_we), .gwe(gwe), .rst(rst));
Nbit_reg #(2, 2'd2) REG_D_X_stall (.in(D_stall), .out(X_stall), .clk(clk), .we(1), .gwe(gwe), .rst(rst));


//Execute 
 wire [15:0] alu_out;
   
lc4_alu alu (.i_insn(i_cur_insn),
      .i_pc(X_pc),
      .i_r1data(reg_rs_data),
      .i_r2data(reg_rt_data),
      .o_result(alu_out));


assign to_rd_data = decode_is_load ? i_cur_dmem_data : decode_select_pc_plus_one ? next_pc : alu_out;

Nbit_reg #(16, 16'h8200) REG_XM_pc (.in(X_pc), .out(M_pc), .clk(clk), .we(1), .gwe(gwe), .rst(rst));
Nbit_reg #(2, 2'd2) REG_XM_stall (.in(X_stall), .out(M_stall), .clk(clk), .we(1), .gwe(gwe), .rst(rst));



//Memory

Nbit_reg #(16, 16'h8200) REG_MW_pc (.in(M_pc), .out(W_pc), .clk(clk), .we(1), .gwe(gwe), .rst(rst));
Nbit_reg #(2, 2'd2) REG_MW_stall (.in(M_stall), .out(W_stall), .clk(clk), .we(1), .gwe(gwe), .rst(rst));


//Write
assign o_cur_pc = W_pc;
assign o_dmem_addr = (decode_is_load || decode_is_store) ? alu_out : 0;
assign o_dmem_we = decode_is_store;



// TEST ASSIGNMENTS
  assign test_stall = W_stall; 
  assign test_cur_pc = W_pc;
  assign test_cur_insn = i_cur_insn;
  assign test_regfile_we = decode_regfile_we;
  assign test_regfile_wsel = decode_wsel;
  assign test_regfile_data = to_rd_data;
  assign test_nzp_we = 1;
  assign test_nzp_new_bits = !test_regfile_data ? 2 : test_regfile_data[15] ? 4 : 1;
  assign test_dmem_we = o_dmem_we;
  assign test_dmem_addr = o_dmem_addr;
  assign test_dmem_data = i_cur_dmem_data;



`ifndef NDEBUG
   always @(posedge gwe) begin
      // $display("%d %h %h %h %h %h", $time, f_pc, d_pc, e_pc, m_pc, test_cur_pc);
      // if (o_dmem_we)
      //   $display("%d STORE %h <= %h", $time, o_dmem_addr, o_dmem_towrite);

      // Start each $display() format string with a %d argument for time
      // it will make the output easier to read.  Use %b, %h, and %d
      // for binary, hex, and decimal output of additional variables.
      // You do not need to add a \n at the end of your format string.
      // $display("%d ...", $time);

      // Try adding a $display() call that prints out the PCs of
      // each pipeline stage in hex.  Then you can easily look up the
      // instructions in the .asm files in test_data.

      // basic if syntax:
      // if (cond) begin
      //    ...;
      //    ...;
      // end

      // Set a breakpoint on the empty $display() below
      // to step through your pipeline cycle-by-cycle.
      // You'll need to rewind the simulation to start
      // stepping from the beginning.

      // You can also simulate for XXX ns, then set the
      // breakpoint to start stepping midway through the
      // testbench.  Use the $time printouts you added above (!)
      // to figure out when your problem instruction first
      // enters the fetch stage.  Rewind your simulation,
      // run it for that many nano-seconds, then set
      // the breakpoint.

      // In the objects view, you can change the values to
      // hexadecimal by selecting all signals (Ctrl-A),
      // then right-click, and select Radix->Hexadecimal.

      // To see the values of wires within a module, select
      // the module in the hierarchy in the "Scopes" pane.
      // The Objects pane will update to display the wires
      // in that module.

      //$display(); 
   end
`endif
endmodule
