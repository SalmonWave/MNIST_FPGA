/*******************************************************************************
* Flatten Layer Module
* Purpose: Converts 3D feature maps to 1D vector for fully connected layers
* Description: Transforms 6x6x8 feature maps into a 288-element vector
*              Simply reorganizes data without mathematical operations
*******************************************************************************/

`timescale 1ns/1ps

module flatten_layer (
    // Clock & Reset
    input                                   clk,
    input                                   rst_n,
    input                                   soft_rst,
    // Control Signals
    input                                   data_valid,
    output reg                              result_valid,
    // Data Ports
    input      [INPUT_CHANNELS*FEATURE_BITWIDTH*INPUT_WIDTH*INPUT_HEIGHT-1:0] feature_map_in,
    output reg [FEATURE_BITWIDTH*FLATTENED_SIZE-1:0] flattened_out
);

// Flatten layer parameters
parameter INPUT_CHANNELS   = 8;    // Number of input channels
parameter FEATURE_BITWIDTH = 8;    // Feature map bit width
parameter INPUT_WIDTH      = 6;    // Input width
parameter INPUT_HEIGHT     = 6;    // Input height
parameter FLATTENED_SIZE   = 288;  // 6x6x8 = 288 flattened vector size

// Internal signals
integer i, j, k;
integer flat_index;
reg [FEATURE_BITWIDTH-1:0] pixel_value;

// Process valid signal
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        result_valid <= 1'b0;
    end else if (soft_rst) begin
        result_valid <= 1'b0;
    end else begin
        result_valid <= data_valid; // One cycle delay for valid signal
    end
end

// Flatten operation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        flattened_out <= {FEATURE_BITWIDTH*FLATTENED_SIZE{1'b0}};
    end else if (soft_rst) begin
        flattened_out <= {FEATURE_BITWIDTH*FLATTENED_SIZE{1'b0}};
    end else if (data_valid) begin
        // Convert 3D feature map to 1D array
        // Iterate through each element in the 3D feature map
        flat_index = 0;
        
        for (k = 0; k < INPUT_CHANNELS; k = k + 1) begin
            for (i = 0; i < INPUT_HEIGHT; i = i + 1) begin
                for (j = 0; j < INPUT_WIDTH; j = j + 1) begin
                    // Extract pixel value from input feature map
                    pixel_value = feature_map_in[(k*INPUT_HEIGHT*INPUT_WIDTH + i*INPUT_WIDTH + j)*FEATURE_BITWIDTH +: FEATURE_BITWIDTH];
                    
                    // Place value in flattened output array
                    flattened_out[flat_index*FEATURE_BITWIDTH +: FEATURE_BITWIDTH] <= pixel_value;
                    
                    flat_index = flat_index + 1;
                end
            end
        end
    end
end

endmodule