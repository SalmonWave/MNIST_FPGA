/*******************************************************************************
* CNN Processor Module
* Purpose: Top-level CNN processing engine 
* Description: Manages multiple output channels, applies biases and activation function
*******************************************************************************/

`timescale 1ns / 1ps
`include "cnn_layer_1_define.vh"

module cnn_processor (
    // Clock & Reset
    input clk,
    input reset_n,
    // CNN Parameters
    input  [`WEIGHT_BITWIDTH*`INPUT_CHANNELS*`OUTPUT_CHANNELS*`KERNEL_WIDTH*`KERNEL_HEIGHT-1:0] weights,
    input [`BIAS_BITWIDTH*`OUTPUT_CHANNELS-1:0] biases,
    // Data Input
    input data_valid,
    input  [`FEATURE_BITWIDTH*`INPUT_CHANNELS*`IMAGE_WIDTH*`IMAGE_HEIGHT-1:0] feature_map,
    // Output
    output result_valid,
    output [`CHANNEL_ACCUM_BITWIDTH*`OUTPUT_CHANNELS-1:0] output_feature
);



    localparam PIPELINE_STAGES = 1;

    //==============================================================================
    // Pipeline Control Logic
    //==============================================================================
    integer                        i;
    reg     [ PIPELINE_STAGES-1:0] pipeline_valid;
    wire    [`OUTPUT_CHANNELS-1:0] channel_valid;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            pipeline_valid <= 0;
        end else begin
            pipeline_valid[PIPELINE_STAGES-1] <= &channel_valid;    //  After all Channel finish calculating 


            // Shift through the pipeline stages if more than 1
            if (PIPELINE_STAGES > 1) begin
                for (i = 1; i < PIPELINE_STAGES; i = i + 1) begin
                    pipeline_valid[i] <= pipeline_valid[i-1];
                end
            end
        end
    end

    //==============================================================================
    // Instantiate Channel Accumulators for Each Output Channel
    //==============================================================================
    wire [                        `OUTPUT_CHANNELS-1:0] ch_data_valid;
    wire [`OUTPUT_CHANNELS*`CHANNEL_ACCUM_BITWIDTH-1:0] channel_sums;

    // Instantiate channel_accumulator for each output channel
    genvar ch_idx;
    generate
        for (
            ch_idx = 0; ch_idx < `OUTPUT_CHANNELS; ch_idx = ch_idx + 1
        ) begin : output_channel_inst
            // Each output channel gets the same valid signal
            assign ch_data_valid[ch_idx] = data_valid;

            // Instantiate channel_accumulator for this output channel
            channel_accumulator ch_acc (
                .clk            (clk),
                .reset_n        (reset_n),
                .weights        (weights[ch_idx*`INPUT_CHANNELS*`KERNEL_WIDTH*`KERNEL_HEIGHT*`WEIGHT_BITWIDTH +: `INPUT_CHANNELS*`KERNEL_WIDTH*`KERNEL_HEIGHT*`WEIGHT_BITWIDTH]),
                .data_valid     (ch_data_valid[ch_idx]),
                .feature_map    (feature_map),
                .result_valid   (channel_valid[ch_idx]),
                .channel_sum    (channel_sums[ch_idx*`CHANNEL_ACCUM_BITWIDTH +: `CHANNEL_ACCUM_BITWIDTH])
            );
        end
    endgenerate

    //==============================================================================
    // Add Bias to Each Channel's Output
    //==============================================================================
    wire [`OUTPUT_CHANNELS*`CHANNEL_ACCUM_BITWIDTH-1:0] biased_outputs;
    reg  [`OUTPUT_CHANNELS*`CHANNEL_ACCUM_BITWIDTH-1:0] biased_outputs_reg;

    // Add bias to each channel's accumulated sum
    genvar bias_idx;
    generate
        for (
            bias_idx = 0; bias_idx < `OUTPUT_CHANNELS; bias_idx = bias_idx + 1
        ) begin : add_bias
            assign biased_outputs[bias_idx*`CHANNEL_ACCUM_BITWIDTH +: `CHANNEL_ACCUM_BITWIDTH] = 
        channel_sums[bias_idx*`CHANNEL_ACCUM_BITWIDTH +: `CHANNEL_ACCUM_BITWIDTH] + 
         {{(`CHANNEL_ACCUM_BITWIDTH-`BIAS_BITWIDTH){biases[bias_idx*`BIAS_BITWIDTH + `BIAS_BITWIDTH -1]}}, biases[bias_idx*`BIAS_BITWIDTH +: `BIAS_BITWIDTH]};
        end
    endgenerate

    // Register the biased outputs
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            biased_outputs_reg <= 0;
        end else if(&channel_valid) begin         //  After all Channel finish calculating 
            biased_outputs_reg <= biased_outputs;
        end
    end

    //==============================================================================
    // Optional: ReLU Activation Function (commented out to match original function)
    //==============================================================================
    wire [`OUTPUT_CHANNELS*`CHANNEL_ACCUM_BITWIDTH-1:0] activated_outputs;

    genvar act_idx;
    generate
        for (
            act_idx = 0; act_idx < `OUTPUT_CHANNELS; act_idx = act_idx + 1
        ) begin : relu_activation
            // ReLU function: max(0, x)
            assign activated_outputs[act_idx*`CHANNEL_ACCUM_BITWIDTH +: `CHANNEL_ACCUM_BITWIDTH] = 
             (biased_outputs_reg[act_idx*`CHANNEL_ACCUM_BITWIDTH +: `CHANNEL_ACCUM_BITWIDTH] > 0) ? 
             biased_outputs_reg[act_idx*`CHANNEL_ACCUM_BITWIDTH +: `CHANNEL_ACCUM_BITWIDTH] : 0;
        end
    endgenerate

    //==============================================================================
    // Output Assignments
    //==============================================================================
    assign result_valid = pipeline_valid[PIPELINE_STAGES-1];
    assign output_feature = activated_outputs; // Change to activated_outputs if using ReLU

endmodule
