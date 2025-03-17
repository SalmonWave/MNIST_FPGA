/*******************************************************************************
* Channel Accumulator Module
* Purpose: Accumulates convolution results across multiple input channels
* Description: Instantiates multiple conv_multiplier modules (formerly cnn_kernel)
*              and sums their outputs
*******************************************************************************/

`timescale 1ns / 1ps
`include "cnn_layer_1_define.vh"

module channel_accumulator (
    // Clock & Reset
    input clk,
    input reset_n,
    // Data Inputs
    input     [`WEIGHT_BITWIDTH*(`INPUT_CHANNELS*`KERNEL_WIDTH*`KERNEL_HEIGHT)-1:0]       weights,
    input data_valid,
    input     [`FEATURE_BITWIDTH*(`INPUT_CHANNELS*`IMAGE_WIDTH*`IMAGE_HEIGHT)-1:0]     feature_map,
    // Outputs
    output result_valid,
    output [`CHANNEL_ACCUM_BITWIDTH-1:0] channel_sum
);


    localparam PIPELINE_STAGES = 1;

    //==============================================================================
    // Pipeline Control Logic
    //==============================================================================
    integer                       i;
    reg     [PIPELINE_STAGES-1:0] pipeline_valid;
    wire    [`INPUT_CHANNELS-1:0] MAC_valid;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            pipeline_valid <= {PIPELINE_STAGES{1'b0}};
        end else begin
            pipeline_valid[PIPELINE_STAGES-1] <= &MAC_valid;
            // Shift through the pipeline stages if more than 1
            if (PIPELINE_STAGES > 1) begin
                for (i = 1; i < PIPELINE_STAGES; i = i + 1) begin
                    pipeline_valid[i] <= pipeline_valid[i-1];
                end
            end
        end
    end

    //==============================================================================
    // Generate Padded Feature Map (Zero Padding + Input Feature Map) (28 x 28 -> 30 x 30) (4CH Input Feature Map)
    //==============================================================================
    wire [`FEATURE_BITWIDTH*(`PADDED_WIDTH)*(`PADDED_HEIGHT)-1:0] padded_feature_0;
    wire [`FEATURE_BITWIDTH*(`PADDED_WIDTH)*(`PADDED_HEIGHT)-1:0] padded_feature_1;
    wire [`FEATURE_BITWIDTH*(`PADDED_WIDTH)*(`PADDED_HEIGHT)-1:0] padded_feature_2;
    wire [`FEATURE_BITWIDTH*(`PADDED_WIDTH)*(`PADDED_HEIGHT)-1:0] padded_feature_3;

    localparam OUTPUT_WIDTH = (`IMAGE_WIDTH);  //  Same Padding
    localparam OUTPUT_HEIGHT = (`IMAGE_HEIGHT);  //  Same Padding

    padding U_PADDING_CHANNEL_0 (
        .feature_map(feature_map[0*`FEATURE_BITWIDTH*(`IMAGE_WIDTH*`IMAGE_HEIGHT) +: `FEATURE_BITWIDTH*(`IMAGE_WIDTH*`IMAGE_HEIGHT)]),
        .padded_feature(padded_feature_0)
    );
    //==============================================================================
    // Instantiate Conv Multipliers for Each Input Channel
    //==============================================================================
    wire [`KERNEL_ACCUM_BITWIDTH*(`IMAGE_WIDTH*`IMAGE_HEIGHT)-1:0] output_feature_map;
    reg [`KERNEL_ACCUM_BITWIDTH*(`IMAGE_WIDTH*`IMAGE_HEIGHT)-1:0] reg_output_feature_map;

    MAC U_MAC_CHANNEL_0 (
        .clk(clk),
        .reset_n(reset_n),
        .weight(weights[0*`WEIGHT_BITWIDTH*(`KERNEL_WIDTH*`KERNEL_HEIGHT) +: `WEIGHT_BITWIDTH*(`KERNEL_WIDTH*`KERNEL_HEIGHT)]),
        .padded_feature(padded_feature_0),
        .result_valid(MAC_valid[0*`INPUT_CHANNELS+:`INPUT_CHANNELS]),
        .output_feature_map(output_feature_map[0*`KERNEL_ACCUM_BITWIDTH*(OUTPUT_WIDTH*OUTPUT_HEIGHT) +: `KERNEL_ACCUM_BITWIDTH*(OUTPUT_WIDTH*OUTPUT_HEIGHT)])
    );
    
    //==============================================================================
    // Sum Results from All Input Channels
    //==============================================================================
    reg [`CHANNEL_ACCUM_BITWIDTH*(OUTPUT_WIDTH)*(OUTPUT_HEIGHT)-1:0] accumulated_output_feature;

    integer acc_idx;
    always @(*) begin
        accumulated_output_feature = 0;  // Initialize the accumulated result to 0.

        // Loop over all input channels and sum their corresponding feature maps
        for (
            acc_idx = 0; acc_idx < `INPUT_CHANNELS; acc_idx = acc_idx + 1
        ) begin
            // For each channel, correctly select the corresponding part of the feature map to add
            accumulated_output_feature = accumulated_output_feature + 
            output_feature_map[acc_idx*`KERNEL_ACCUM_BITWIDTH*(OUTPUT_WIDTH*OUTPUT_HEIGHT) +: `KERNEL_ACCUM_BITWIDTH*(OUTPUT_WIDTH*OUTPUT_HEIGHT)];
        end
    end



    //==============================================================================
    // Register the Final Sum
    //==============================================================================
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            reg_output_feature_map <= 0;
        end else if (&MAC_valid) begin
            reg_output_feature_map <= output_feature_map;
        end
    end

    //==============================================================================
    // Output Assignments
    //==============================================================================
    assign result_valid = pipeline_valid[PIPELINE_STAGES-1];
    assign channel_sum  = reg_output_feature_map;

endmodule
