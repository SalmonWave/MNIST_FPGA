`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/11/2025 10:29:56 AM
// Design Name: 
// Module Name: FCN_TOP
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module FCN_TOP#(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 12,
    parameter MEM_SIZE   = 4096
) (

);




    data_mover_bram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MEM_SIZE(MEM_SIZE)   
    ) 
        U_DATA_MOVER
    (
        input logic clk,
        input logic reset,
        input logic i_run,
        input logic [ADDR_WIDTH - 1:0] i_num_cnt,
        output logic o_idle,
        output logic o_read,
        output logic o_write,
        output logic o_done,


        // BRAM0 READ INPUT_DATA
        output logic ce_input,  // Clock Enable 
        output logic we_input,  // Write Enable (0: Read, 1:Write)
        output logic [ADDR_WIDTH - 1:0] addr_input,
        output logic [DATA_WIDTH - 1:0] din_input,
        input logic [DATA_WIDTH - 1:0] qout_input,

        // BRAM0 READ INPUT_DATA
        output logic ce_weight,  // Clock Enable 
        output logic we_weight,  // Write Enable (0: Read, 1:Write)
        output logic [ADDR_WIDTH - 1:0] addr_weight,
        output logic [DATA_WIDTH - 1:0] din_weight,
        input logic [DATA_WIDTH - 1:0] qout_weight,

        // BRAM2 WRITE
        output logic                    ce_c,    // Clock Enable 
        output logic                    we_c,    // Write Enable (0: Read, 1:Write)
        output logic [ADDR_WIDTH - 1:0] addr_c,
        output logic [DATA_WIDTH - 1:0] din_c,
        input  logic [DATA_WIDTH - 1:0] qout_c
    );


    true_dual_port_bram#
    (
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MEM_SIZE(MEM_SIZE)   
    ) 
    (
        input  logic clk,              
        input  logic ce_a, ce_b,       // Clock Enable 
        input  logic we_a, we_b,       // Write Enable (0: Read, 1:Write)
        input  logic [ADDR_WIDTH - 1:0] addr_a, addr_b, 
        input  logic [DATA_WIDTH - 1:0] din_a, din_b,  
        output logic [DATA_WIDTH - 1:0] qout_a, qout_b 
    );


endmodule
