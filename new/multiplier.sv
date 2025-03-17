`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/08/2025 08:18:42 PM
// Design Name: 
// Module Name: multiplier
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


module multiplier #(
    parameter DATA_WIDTH = 32
) (
    input  logic                  clk,
    input  logic                  reset,
    input  logic [DATA_WIDTH-1:0] input_data,
    input  logic [DATA_WIDTH-1:0] weight,
    output logic [DATA_WIDTH-1:0] result,
    input  logic                  input_weight_valid,
    output logic                  result_valid_delay
);

    always_ff @(posedge clk, posedge reset) begin : blockName
        if (reset) begin
            result <= 0;
        end else begin
            result <= input_data * weight;
        end

    end

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            result_valid_delay <= 0;
        end else begin
            result_valid_delay <= input_weight_valid;
        end
    end
endmodule
