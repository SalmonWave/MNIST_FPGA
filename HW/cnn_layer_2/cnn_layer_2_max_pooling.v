/*******************************************************************************
* Max Pooling Layer 2 Module
* Purpose: Performs 2x2 max pooling with stride 2 on feature maps from CNN Layer 2
* Description: Reduces spatial dimensions while preserving depth/channels
*              Input: 12x12x8 → Output: 6x6x8
*******************************************************************************/

`timescale 1ns/1ps

module max_pooling_layer2 (
    // Clock & Reset
    input                                   clk,
    input                                   rst_n,
    input                                   soft_rst,
    // Control Signals
    input                                   data_valid,
    output                                  result_valid,
    // Data Ports
    input      [INPUT_CHANNELS*FEATURE_BITWIDTH*INPUT_WIDTH*INPUT_HEIGHT-1:0] feature_map_in,
    output reg [INPUT_CHANNELS*FEATURE_BITWIDTH*OUTPUT_WIDTH*OUTPUT_HEIGHT-1:0] feature_map_out
);

// Pooling layer parameters
parameter INPUT_CHANNELS  = 8;    // Number of input/output channels
parameter FEATURE_BITWIDTH = 8;   // Feature map bit width
parameter INPUT_WIDTH     = 12;   // Input width
parameter INPUT_HEIGHT    = 12;   // Input height
parameter POOL_SIZE       = 2;    // Pooling window size
parameter STRIDE_SIZE     = 2;    // Stride size
parameter OUTPUT_WIDTH    = 6;    // Output width after pooling
parameter OUTPUT_HEIGHT   = 6;    // Output height after pooling

// Internal signals
reg [2:0] pipeline_valid;  // Valid signal pipeline
reg processing_done;       // Processing completion flag

// Valid signal propagation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pipeline_valid <= 3'b000;
        processing_done <= 1'b0;
    end else if (soft_rst) begin
        pipeline_valid <= 3'b000;
        processing_done <= 1'b0;
    end else begin
        pipeline_valid <= {pipeline_valid[1:0], data_valid};
        processing_done <= pipeline_valid[2];
    end
end

// Output valid signal
assign result_valid = processing_done;

// Max pooling process
genvar ch;
generate
    for (ch = 0; ch < INPUT_CHANNELS; ch = ch + 1) begin: channel_pooling
        // Process each channel separately
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                feature_map_out[ch*FEATURE_BITWIDTH*OUTPUT_WIDTH*OUTPUT_HEIGHT +: FEATURE_BITWIDTH*OUTPUT_WIDTH*OUTPUT_HEIGHT] <= 0;
            end else if (soft_rst) begin
                feature_map_out[ch*FEATURE_BITWIDTH*OUTPUT_WIDTH*OUTPUT_HEIGHT +: FEATURE_BITWIDTH*OUTPUT_WIDTH*OUTPUT_HEIGHT] <= 0;
            end else if (data_valid) begin
                // Perform max pooling on this channel
                pool_channel(
                    feature_map_in[ch*FEATURE_BITWIDTH*INPUT_WIDTH*INPUT_HEIGHT +: FEATURE_BITWIDTH*INPUT_WIDTH*INPUT_HEIGHT],
                    feature_map_out[ch*FEATURE_BITWIDTH*OUTPUT_WIDTH*OUTPUT_HEIGHT +: FEATURE_BITWIDTH*OUTPUT_WIDTH*OUTPUT_HEIGHT],
                    ch
                );
            end
        end
    end
endgenerate

// Max pooling for a single channel
task pool_channel;
    input  [FEATURE_BITWIDTH*INPUT_WIDTH*INPUT_HEIGHT-1:0] in_feature;
    output [FEATURE_BITWIDTH*OUTPUT_WIDTH*OUTPUT_HEIGHT-1:0] out_feature;
    input  integer channel_idx;
    
    integer i, j, x, y;
    reg [FEATURE_BITWIDTH-1:0] max_val;
    reg [FEATURE_BITWIDTH-1:0] current_val;
    begin
        // Process each 2x2 region with stride 2
        for (i = 0; i < OUTPUT_HEIGHT; i = i + 1) begin
            for (j = 0; j < OUTPUT_WIDTH; j = j + 1) begin
                // Initialize max value
                max_val = 0;
                
                // Find maximum in 2x2 window
                for (y = 0; y < POOL_SIZE; y = y + 1) begin
                    for (x = 0; x < POOL_SIZE; x = x + 1) begin
                        // Get current pixel value from input feature map
                        current_val = get_pixel_value(
                            in_feature, 
                            j*STRIDE_SIZE + x, 
                            i*STRIDE_SIZE + y
                        );
                        
                        // Update max value if current is larger
                        if (current_val > max_val || (x == 0 && y == 0)) begin
                            max_val = current_val;
                        end
                    end
                end
                
                // Store max value to output feature map
                set_pixel_value(
                    out_feature,
                    j,
                    i,
                    max_val
                );
            end
        end
    end
endtask

// Helper function to get pixel value from feature map
function [FEATURE_BITWIDTH-1:0] get_pixel_value;
    input [FEATURE_BITWIDTH*INPUT_WIDTH*INPUT_HEIGHT-1:0] feature;
    input integer x;
    input integer y;
    begin
        get_pixel_value = feature[(y*INPUT_WIDTH + x)*FEATURE_BITWIDTH +: FEATURE_BITWIDTH];
    end
endfunction

// Helper function to set pixel value in feature map
task set_pixel_value;
    inout [FEATURE_BITWIDTH*OUTPUT_WIDTH*OUTPUT_HEIGHT-1:0] feature;
    input integer x;
    input integer y;
    input [FEATURE_BITWIDTH-1:0] value;
    begin
        feature[(y*OUTPUT_WIDTH + x)*FEATURE_BITWIDTH +: FEATURE_BITWIDTH] = value;
    end
endtask

endmodule