/*******************************************************************************
* CNN MAC Module
* Purpose: Verilog implementation of CNN MAC operation
* Description: Performs multiplication and accumulation for a single CNN kernel
*******************************************************************************/

`timescale 1ns / 1ps
`include "cnn_layer_1_define.vh"

module cnn_layer_top (
    // Clock & Reset
    input clk,
    input reset_n,
    // CNN Parameters
    input  [`WEIGHT_BITWIDTH*(`OUTPUT_CHANNELS*`INPUT_CHANNELS*`KERNEL_WIDTH*`KERNEL_HEIGHT)-1:0] weights,
    input  [`BIAS_BITWIDTH*`OUTPUT_CHANNELS-1:0] biases,
    // Data Input
    input data_valid,
    input  [`FEATURE_BITWIDTH*(`INPUT_CHANNELS*`IMAGE_WIDTH*`IMAGE_HEIGHT)-1:0] feature_map,
    // Output
    output result_valid,
    output [`CHANNEL_ACCUM_BITWIDTH*`OUTPUT_CHANNELS-1:0] output_feature
);

padding U_PADDING_CH0(
    .feature_map(feature_map[0*`FEATURE_BITWIDTH*(`IMAGE_WIDTH*`IMAGE_HEIGHT) +: `FEATURE_BITWIDTH*(`IMAGE_WIDTH*`IMAGE_HEIGHT)]),
    .padded_feature()
);


endmodule