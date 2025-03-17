/*******************************************************************************
* CNN MAC Module
* Purpose: Verilog implementation of CNN MAC operation
* Description: Performs multiplication and accumulation for a single CNN kernel
*******************************************************************************/

`timescale 1ns/1ps

module conv_multiplier (
    // Clock & Reset
    input                           clk,
    input                           rst_n,
    input                           soft_rst,
    // Data Inputs
    input  [KX*KY*W_BW-1:0]         weight,
    input                           data_valid,
    input  [KX*KY*I_F_BW-1:0]       feature_map,
    // Outputs
    output                          result_valid,
    output [AK_BW-1:0]              kernel_sum
);

`include "cnn_layer_1_define.vh"

localparam PIPELINE_STAGES = 2;

//==============================================================================
// Pipeline Control Logic
//==============================================================================
reg  [PIPELINE_STAGES-1:0] pipeline_valid;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        pipeline_valid <= {PIPELINE_STAGES{1'b0}};
    end 
    else if(soft_rst) begin
        pipeline_valid <= {PIPELINE_STAGES{1'b0}};
    end 
    else begin
        pipeline_valid[0] <= data_valid;
        pipeline_valid[1] <= pipeline_valid[0];
    end
end

//==============================================================================
// Multiply Operation: feature_map * weight
//==============================================================================
wire [KY*KX*M_BW-1:0] products;
reg  [KY*KX*M_BW-1:0] products_reg;

genvar i;
generate
    for(i = 0; i < KX*KY; i = i + 1) begin : multiply_loop
        // Multiply each feature map element by corresponding weight
        assign products[i*M_BW +: M_BW] = feature_map[i*I_F_BW +: I_F_BW] * weight[i*W_BW +: W_BW];
        
        // Register the products
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                products_reg[i*M_BW +: M_BW] <= {M_BW{1'b0}};
            end 
            else if(soft_rst) begin
                products_reg[i*M_BW +: M_BW] <= {M_BW{1'b0}};
            end 
            else if(data_valid) begin
                products_reg[i*M_BW +: M_BW] <= products[i*M_BW +: M_BW];
            end
        end
    end
endgenerate

//==============================================================================
// Accumulation Logic
//==============================================================================
reg [AK_BW-1:0] sum_result;
reg [AK_BW-1:0] sum_result_reg;

// Accumulate all products to generate one output point
integer j;
always @(*) begin
    sum_result = {AK_BW{1'b0}};
    for(j = 0; j < KX*KY; j = j + 1) begin
        sum_result = sum_result + products_reg[j*M_BW +: M_BW];
    end
end    

// Register the accumulated result
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        sum_result_reg <= {AK_BW{1'b0}};
    end 
    else if(soft_rst) begin
        sum_result_reg <= {AK_BW{1'b0}};
    end 
    else if(pipeline_valid[0]) begin
        sum_result_reg <= sum_result;
    end
end

//==============================================================================
// Output Assignments
//==============================================================================
assign result_valid = pipeline_valid[PIPELINE_STAGES-1];
assign kernel_sum = sum_result_reg;

endmodule