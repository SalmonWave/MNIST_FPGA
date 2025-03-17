/*******************************************************************************
* CNN MAC Module
* Purpose: Verilog implementation of CNN MAC operation
* Description: Performs multiplication and accumulation for a single CNN kernel
*******************************************************************************/

`timescale 1ns/1ps
`include "cnn_layer_1_define.vh"

module conv_multiplier (
    // Clock & Reset
    input                           clk,
    input                           reset_n,
    // Data Inputs
    input  [`WEIGHT_BITWIDTH*`KERNEL_WIDTH*`KERNEL_HEIGHT-1:0]         weight,
    input                           data_valid,
    input  [`FEATURE_BITWIDTH*`IMAGE_WIDTH*`IMAGE_HEIGHT-1:0]       feature_map,
    // Outputs
    output                          result_valid,
    output [`KERNEL_ACCUM_BITWIDTH-1:0]              kernel_sum
);


localparam PIPELINE_STAGES = 2;

//==============================================================================
// Pipeline Control Logic
//==============================================================================
integer                    i;
reg  [PIPELINE_STAGES-1:0] pipeline_valid;

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        pipeline_valid <= 0;
        end else begin
        pipeline_valid[PIPELINE_STAGES-1] <= data_valid;

        // Shift through the pipeline stages if more than 1
        if (PIPELINE_STAGES > 1) begin
            for (i = 1; i < PIPELINE_STAGES; i = i + 1) begin
                pipeline_valid[i] <= pipeline_valid[i-1];
            end
        end
    end
end
//==============================================================================
// Input Feature Map with Padding Logic
//==============================================================================
wire [`FEATURE_BITWIDTH-1:0] padded_feature[0:I_HEIGHT+2*PADDING-1][0:I_WIDTH+2*PADDING-1];
wire [`FEATURE_BITWIDTH-1:0] kernel_input[0:K_HEIGHT-1][0:K_WIDTH-1];

// Generate padded feature map
genvar p_row, p_col;
generate
    for(p_row = 0; p_row < I_HEIGHT+2*PADDING; p_row = p_row + 1) begin: pad_row
        for(p_col = 0; p_col < I_WIDTH+2*PADDING; p_col = p_col + 1) begin: pad_col
            // If within original image boundaries, use the image data
            // Otherwise, use zero padding
            if (p_row >= PADDING && p_row < I_HEIGHT+PADDING && 
                p_col >= PADDING && p_col < I_WIDTH+PADDING) begin
                assign padded_feature[p_row][p_col] = feature_map[((p_row-PADDING)*I_WIDTH + (p_col-PADDING))*I_F_BW +: I_F_BW];
            end else begin
                assign padded_feature[p_row][p_col] = {I_F_BW{1'b0}}; // Zero padding
            end
        end
    end
endgenerate

// Extract kernel window based on current position
genvar k_row, k_col;
generate
    for(k_row = 0; k_row < K_HEIGHT; k_row = k_row + 1) begin: kernel_row
        for(k_col = 0; k_col < K_WIDTH; k_col = k_col + 1) begin: kernel_col
            assign kernel_input[k_row][k_col] = padded_feature[y_idx + k_row][x_idx + k_col];
        end
    end
endgenerate



//==============================================================================
// Multiply Operation: feature_map * weight
//==============================================================================
wire [`KERNEL_HEIGHT*`KERNEL_WIDTH*FEATURE_BITWIDTH-1:0] products;
reg  [`KERNEL_HEIGHT*`KERNEL_WIDTH*FEATURE_BITWIDTH-1:0] products_reg;

genvar i;
generate
    for(i = 0; i < KERNEL_WIDTH*KERNEL_HEIGHT; i = i + 1) begin : multiply_loop
        // Multiply each feature map element by corresponding weight
        assign products[i*M_BW +: M_BW] = feature_map[i*I_F_BW +: I_F_BW] * weight[i*WEIGHT_WIDTH +: W_BW];
        
        // Register the products
        always @(posedge clk or negedge reset_n) begin
            if(!reset_n) begin
                products_reg[i*M_BW +: M_BW] <= {M_BW{1'b0}};
            end 
            else if(soft_reset) begin
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
    for(j = 0; j < KERNEL_WIDTH*KERNEL_HEIGHT; j = j + 1) begin
        sum_result = sum_result + products_reg[j*M_BW +: M_BW];
    end
end    

// Register the accumulated result
always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        sum_result_reg <= {AK_BW{1'b0}};
    end 
    else if(soft_reset) begin
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