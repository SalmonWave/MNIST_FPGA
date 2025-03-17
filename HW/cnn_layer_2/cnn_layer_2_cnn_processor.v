/*******************************************************************************
* CNN Processor Module
* Purpose: Top-level CNN processing engine 
* Description: Manages multiple output channels, applies biases and activation function
*******************************************************************************/

`timescale 1ns/1ps

module cnn_processor (
    // Clock & Reset
    input                               clk,
    input                               rst_n,
    input                               soft_rst,
    // CNN Parameters
    input     [CO*CI*KX*KY*W_BW-1:0]    weights,
    input     [CO*B_BW-1:0]             biases,
    // Data Input
    input                               data_valid,
    input     [CI*KX*KY*I_F_BW-1:0]     feature_map,
    // Output
    output                              result_valid,
    output    [CO*O_F_BW-1:0]           output_feature
);

`include "cnn_layer_1_define.vh"

localparam PIPELINE_STAGES = 1;

//==============================================================================
// Pipeline Control Logic
//==============================================================================
wire    [PIPELINE_STAGES-1:0]    pipeline_enables;
reg     [PIPELINE_STAGES-1:0]    pipeline_valid;
wire    [CO-1:0]                 channel_valid;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        pipeline_valid <= {PIPELINE_STAGES{1'b0}};
    end else if(soft_rst) begin
        pipeline_valid <= {PIPELINE_STAGES{1'b0}};
    end else begin
        pipeline_valid[PIPELINE_STAGES-1] <= &channel_valid;
    end
end

assign pipeline_enables = pipeline_valid;

//==============================================================================
// Instantiate Channel Accumulators for Each Output Channel
//==============================================================================
wire    [CO-1:0]                 ch_data_valid;
wire    [CO*ACI_BW-1:0]          channel_sums;

// Instantiate channel_accumulator for each output channel
genvar co_idx;
generate
    for(co_idx = 0; co_idx < CO; co_idx = co_idx + 1) begin : output_channel_inst
        // Each output channel gets the same valid signal
        assign ch_data_valid[co_idx] = data_valid;

        // Instantiate channel_accumulator for this output channel
        channel_accumulator ch_acc (
            .clk            (clk),
            .rst_n          (rst_n),
            .soft_rst       (soft_rst),
            .weights        (weights[co_idx*CI*KX*KY*W_BW +: CI*KX*KY*W_BW]),
            .data_valid     (ch_data_valid[co_idx]),
            .feature_map    (feature_map),
            .result_valid   (channel_valid[co_idx]),
            .channel_sum    (channel_sums[co_idx*ACI_BW +: ACI_BW])
        );
    end
endgenerate

//==============================================================================
// Add Bias to Each Channel's Output
//==============================================================================
wire    [CO*AB_BW-1:0]       biased_outputs;
reg     [CO*AB_BW-1:0]       biased_outputs_reg;

// Add bias to each channel's accumulated sum
genvar bias_idx;
generate
    for(bias_idx = 0; bias_idx < CO; bias_idx = bias_idx + 1) begin : add_bias
        assign biased_outputs[bias_idx*AB_BW +: AB_BW] = 
               channel_sums[bias_idx*ACI_BW +: ACI_BW] + 
               biases[bias_idx*B_BW +: B_BW];
    end
endgenerate

// Register the biased outputs
always @(posedge clk or negedge rst_n) begin
   if(!rst_n) begin
        biased_outputs_reg <= {CO*AB_BW{1'b0}};
   end else if(soft_rst) begin
        biased_outputs_reg <= {CO*AB_BW{1'b0}};
   end else if(&channel_valid) begin
        biased_outputs_reg <= biased_outputs;
   end
end

//==============================================================================
// Optional: ReLU Activation Function (commented out to match original function)
//==============================================================================
// wire [CO*O_F_BW-1:0] activated_outputs;
// 
// genvar act_idx;
// generate
//     for(act_idx = 0; act_idx < CO; act_idx = act_idx + 1) begin : relu_activation
//         // ReLU function: max(0, x)
//         assign activated_outputs[act_idx*O_F_BW +: O_F_BW] = 
//             (biased_outputs_reg[act_idx*AB_BW +: AB_BW] > 0) ? 
//             biased_outputs_reg[act_idx*AB_BW +: AB_BW] : {O_F_BW{1'b0}};
//     end
// endgenerate

//==============================================================================
// Output Assignments
//==============================================================================
assign result_valid = pipeline_valid[PIPELINE_STAGES-1];
assign output_feature = biased_outputs_reg; // Change to activated_outputs if using ReLU

endmodule