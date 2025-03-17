/*******************************************************************************
* CNN MAC Module
* Purpose: Verilog implementation of CNN MAC operation
* Description: Performs multiplication and accumulation for a single CNN kernel
*******************************************************************************/

`timescale 1ns / 1ps
`include "cnn_layer_1_define.vh"

module padding (
    // Data Inputs
    input  [`FEATURE_BITWIDTH*(`IMAGE_WIDTH*`IMAGE_HEIGHT)-1:0]       feature_map,
    // Outputs
    output [`FEATURE_BITWIDTH*(`PADDED_WIDTH)*(`PADDED_HEIGHT)-1:0]   padded_feature
);


//==============================================================================
// Generate Padded Feature Map (Zero Padding + Input Feature Map) (28 x 28 -> 30 x 30)
//==============================================================================

    genvar p_row, p_col;
    generate
        for (
            p_row = 0; p_row < `PADDED_HEIGHT; p_row = p_row + 1
        ) begin : pad_row
            for (
                p_col = 0; p_col < `PADDED_WIDTH; p_col = p_col + 1
            ) begin : pad_col
                if (p_row < `PADDING_SIZE || p_row >= `IMAGE_HEIGHT + `PADDING_SIZE ||
                p_col < `PADDING_SIZE || p_col >= `IMAGE_WIDTH + `PADDING_SIZE) begin
                    // Padding → Zero
                    assign padded_feature[`FEATURE_BITWIDTH*((p_row*(`PADDED_WIDTH)) + p_col) +: `FEATURE_BITWIDTH] = 0;
                end else begin
                    assign padded_feature[`FEATURE_BITWIDTH*((p_row*(`PADDED_WIDTH)) + p_col) +: `FEATURE_BITWIDTH] =
                    feature_map[`FEATURE_BITWIDTH*(((p_row-`PADDING_SIZE)*`IMAGE_WIDTH) + (p_col-`PADDING_SIZE)) +: `FEATURE_BITWIDTH];
                end
            end
        end
    endgenerate



endmodule
