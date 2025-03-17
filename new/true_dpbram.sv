`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/23/2025 01:19:37 PM
// Design Name: 
// Module Name: true_dpbram
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


module true_dual_port_bram#
(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 12,
    parameter MEM_SIZE = 4096
) 
(
    input  logic clk,              
    input  logic ce_a, ce_b,       // Clock Enable 
    input  logic we_a, we_b,       // Write Enable (0: Read, 1:Write)
    input  logic [ADDR_WIDTH - 1:0] addr_a, addr_b, 
    input  logic [DATA_WIDTH - 1:0] din_a, din_b,  
    output logic [DATA_WIDTH - 1:0] qout_a, qout_b 
);


    (* ram_style = "block" *) // BRAM으로 강제 지정
    reg [DATA_WIDTH - 1:0] mem [0:MEM_SIZE - 1]; 

    //  Port A 
    always @(posedge clk) begin
        if (ce_a) begin         
            if (we_a) begin
                mem[addr_a] <= din_a; 
            end else begin
                qout_a <= mem[addr_a];    
            end
        end
    end

    //  Port B
    always @(posedge clk) begin
        if (ce_b) begin         
            if (we_b) begin
                mem[addr_b] <= din_b;
            end else begin
                qout_b <= mem[addr_b];    
            end
        end
    end
endmodule