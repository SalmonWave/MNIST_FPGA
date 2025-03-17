/*******************************************************************************
* Channel Accumulator Module
* Purpose: Accumulates convolution results across multiple input channels
* Description: Instantiates multiple conv_multiplier modules (formerly cnn_kernel)
*              and sums their outputs
*******************************************************************************/

`timescale 1ns/1ps

module channel_accumulator (
    // Clock & Reset
    input                               clk,
    input                               rst_n,
    input                               soft_rst,
    // Data Inputs
    input     [CI*KX*KY*W_BW-1:0]       weights,
    input                               data_valid,
    input     [CI*KX*KY*I_F_BW-1:0]     feature_map,
    // Outputs
    output                              result_valid,
    output    [ACI_BW-1:0]              channel_sum
);

`include "cnn_layer_1_define.vh"

localparam PIPELINE_STAGES = 1;

//==============================================================================
// Pipeline Control Logic
//==============================================================================
wire    [PIPELINE_STAGES-1:0]    pipeline_enables;
reg     [PIPELINE_STAGES-1:0]    pipeline_valid;
wire    [CI-1:0]                 multiplier_valid;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        pipeline_valid <= {PIPELINE_STAGES{1'b0}};
    end else if(soft_rst) begin
        pipeline_valid <= {PIPELINE_STAGES{1'b0}};
    end else begin
        pipeline_valid[PIPELINE_STAGES-1] <= &multiplier_valid;
    end
end

assign pipeline_enables = pipeline_valid;

//==============================================================================
// Instantiate Conv Multipliers for Each Input Channel
//==============================================================================
wire    [CI-1:0]                 channel_data_valid;
wire    [CI*AK_BW-1:0]           multiplier_results;
wire    [ACI_BW-1:0]             channel_sum_comb;
reg     [ACI_BW-1:0]             channel_sum_reg;
reg     [ACI_BW-1:0]             temp_sum;

// Instantiate conv_multiplier (formerly cnn_kernel) for each input channel
genvar ch_idx;
generate 
    for(ch_idx = 0; ch_idx < CI; ch_idx = ch_idx + 1) begin : channel_mult_inst
        // Each channel gets the same valid signal
        assign channel_data_valid[ch_idx] = data_valid;

        // Instantiate conv_multiplier for this channel
        conv_multiplier channel_mult (
            .clk            (clk),
            .rst_n          (rst_n),
            .soft_rst       (soft_rst),
            .weight         (weights[ch_idx*KX*KY*W_BW +: KX*KY*W_BW]),
            .data_valid     (channel_data_valid[ch_idx]),
            .feature_map    (feature_map[ch_idx*KX*KY*I_F_BW +: KX*KY*I_F_BW]),
            .result_valid   (multiplier_valid[ch_idx]),
            .kernel_sum     (multiplier_results[ch_idx*AK_BW +: AK_BW])
        );
    end
endgenerate

//==============================================================================
// Sum Results from All Input Channels
//==============================================================================
integer acc_idx;
always @(*) begin
    temp_sum = {ACI_BW{1'b0}};
    for(acc_idx = 0; acc_idx < CI; acc_idx = acc_idx + 1) begin
        temp_sum = temp_sum + multiplier_results[acc_idx*AK_BW +: AK_BW];
    end
end

assign channel_sum_comb = temp_sum;

//==============================================================================
// Register the Final Sum
//==============================================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        channel_sum_reg <= {ACI_BW{1'b0}};
    end else if(soft_rst) begin
        channel_sum_reg <= {ACI_BW{1'b0}};
    end else if(&multiplier_valid) begin
        channel_sum_reg <= channel_sum_comb;
    end
end

//==============================================================================
// Output Assignments
//==============================================================================
assign result_valid = pipeline_valid[PIPELINE_STAGES-1];
assign channel_sum = channel_sum_reg;

endmodule