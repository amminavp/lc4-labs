`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

/* 8-register, n-bit register file with
 * four read ports and two write ports
 * to support two pipes.
 * 
 * If both pipes try to write to the
 * same register, pipe B wins.
 * 
 * Inputs should be bypassed to the outputs
 * as needed so the register file returns
 * data that is written immediately
 * rather than only on the next cycle.
 */
module lc4_regfile_ss #(parameter n = 16)
   (input  wire         clk,
    input  wire         gwe,
    input  wire         rst,

    input  wire [  2:0] i_rs_A,      // pipe A: rs selector
    output wire [n-1:0] o_rs_data_A, // pipe A: rs contents
    input  wire [  2:0] i_rt_A,      // pipe A: rt selector
    output wire [n-1:0] o_rt_data_A, // pipe A: rt contents

    input  wire [  2:0] i_rs_B,      // pipe B: rs selector
    output wire [n-1:0] o_rs_data_B, // pipe B: rs contents
    input  wire [  2:0] i_rt_B,      // pipe B: rt selector
    output wire [n-1:0] o_rt_data_B, // pipe B: rt contents

    input  wire [  2:0]  i_rd_A,     // pipe A: rd selector
    input  wire [n-1:0]  i_wdata_A,  // pipe A: data to write
    input  wire          i_rd_we_A,  // pipe A: write enable

    input  wire [  2:0]  i_rd_B,     // pipe B: rd selector
    input  wire [n-1:0]  i_wdata_B,  // pipe B: data to write
    input  wire          i_rd_we_B   // pipe B: write enable
    );

   /*** TODO: Your Code Here ***/
    wire [7:0] write_reg_A, write_reg_B;
    genvar i;

    generate
    for (i = 0; i <= 7; i = i + 1) begin 
    
    assign write_reg_A[i] = (i_rd_A == i) & i_rd_we_A;
    assign write_reg_B[i] = (i_rd_B == i) & i_rd_we_B;

    end
    endgenerate

    wire[15:0] C[n-1:0];

    //If both write ports specify the same destination, only pipe B's write should succeed (since the instruction in pipe B follows the instruction in pipe A in program order).

//Any values being written to the register file should be bypassed to the outputs (read ports) so that values being written are immediately available. This eliminates the need to bypass from Writeback to Decode in the pipeline, outside of the register file.

    
    Nbit_reg #(n, 0) reg0(.in(write_reg_B[0] ? i_wdata_B : i_wdata_A),.out(C[0]),.clk(clk),.we(write_reg_A[0] | write_reg_B[0]),.gwe(gwe),.rst(rst));
    Nbit_reg #(n, 0) reg1(.in(write_reg_B[1] ? i_wdata_B : i_wdata_A),.out(C[1]),.clk(clk),.we(write_reg_A[1] | write_reg_B[1]),.gwe(gwe),.rst(rst));
    Nbit_reg #(n, 0) reg2(.in(write_reg_B[2] ? i_wdata_B : i_wdata_A),.out(C[2]),.clk(clk),.we(write_reg_A[2] | write_reg_B[2]),.gwe(gwe),.rst(rst));
    Nbit_reg #(n, 0) reg3(.in(write_reg_B[3] ? i_wdata_B : i_wdata_A),.out(C[3]),.clk(clk),.we(write_reg_A[3] | write_reg_B[3]),.gwe(gwe),.rst(rst));
    Nbit_reg #(n, 0) reg4(.in(write_reg_B[4] ? i_wdata_B : i_wdata_A),.out(C[4]),.clk(clk),.we(write_reg_A[4] | write_reg_B[4]),.gwe(gwe),.rst(rst));
    Nbit_reg #(n, 0) reg5(.in(write_reg_B[5] ? i_wdata_B : i_wdata_A),.out(C[5]),.clk(clk),.we(write_reg_A[5] | write_reg_B[5]),.gwe(gwe),.rst(rst));
    Nbit_reg #(n, 0) reg6(.in(write_reg_B[6] ? i_wdata_B : i_wdata_A),.out(C[6]),.clk(clk),.we(write_reg_A[6] | write_reg_B[6]),.gwe(gwe),.rst(rst));
    Nbit_reg #(n, 0) reg7(.in(write_reg_B[7] ? i_wdata_B : i_wdata_A),.out(C[7]),.clk(clk),.we(write_reg_A[7] | write_reg_B[7]),.gwe(gwe),.rst(rst));


   assign o_rs_data_A = (i_rs_A == i_rd_B && i_rd_we_B) ? i_wdata_B:
                        (i_rs_A == i_rd_A && i_rd_we_A) ? i_wdata_A:
                                  (& (3'b000 == i_rs_A)) ? C[0]: 
                                  (& (3'b001 == i_rs_A)) ? C[1]:
                                  (& (3'b010 == i_rs_A)) ? C[2]:
                                  (& (3'b011 == i_rs_A)) ? C[3]:
                                  (& (3'b100 == i_rs_A)) ? C[4]:
                                  (& (3'b101 == i_rs_A)) ? C[5]:
                                  (& (3'b110 == i_rs_A)) ? C[6]: C[7];

   assign o_rs_data_B = (i_rs_B == i_rd_B && i_rd_we_B) ? i_wdata_B:
                        (i_rs_B == i_rd_A && i_rd_we_A) ? i_wdata_A:
                                  (& (3'b000 == i_rs_B)) ? C[0]: 
                                  (& (3'b001 == i_rs_B)) ? C[1]:
                                  (& (3'b010 == i_rs_B)) ? C[2]:
                                  (& (3'b011 == i_rs_B)) ? C[3]:
                                  (& (3'b100 == i_rs_B)) ? C[4]:
                                  (& (3'b101 == i_rs_B)) ? C[5]:
                                  (& (3'b110 == i_rs_B)) ? C[6]: C[7];

   assign o_rt_data_A = (i_rt_A == i_rd_B && i_rd_we_B) ? i_wdata_B:
                        (i_rt_A == i_rd_A && i_rd_we_A) ? i_wdata_A:
                                  (& (3'b000 == i_rt_A)) ? C[0]: 
                                  (& (3'b001 == i_rt_A)) ? C[1]:
                                  (& (3'b010 == i_rt_A)) ? C[2]:
                                  (& (3'b011 == i_rt_A)) ? C[3]:
                                  (& (3'b100 == i_rt_A)) ? C[4]:
                                  (& (3'b101 == i_rt_A)) ? C[5]:
                                  (& (3'b110 == i_rt_A)) ? C[6]: C[7];

   assign o_rt_data_B = (i_rt_B == i_rd_B && i_rd_we_B) ? i_wdata_B:
                        (i_rt_B == i_rd_A && i_rd_we_A) ? i_wdata_A:
                                  (& (3'b000 == i_rt_B)) ? C[0]: 
                                  (& (3'b001 == i_rt_B)) ? C[1]:
                                  (& (3'b010 == i_rt_B)) ? C[2]:
                                  (& (3'b011 == i_rt_B)) ? C[3]:
                                  (& (3'b100 == i_rt_B)) ? C[4]:
                                  (& (3'b101 == i_rt_B)) ? C[5]:
                                  (& (3'b110 == i_rt_B)) ? C[6]: C[7];
   



endmodule
