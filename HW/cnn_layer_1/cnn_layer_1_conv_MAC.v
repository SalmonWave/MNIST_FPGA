`timescale 1ns/1ps
`include "cnn_layer_1_define.vh"

module MAC (
    // Clock & Reset
    input                           clk,
    input                           reset_n,
    // Data Inputs
    input  [`WEIGHT_BITWIDTH*(`KERNEL_WIDTH*`KERNEL_HEIGHT)-1:0] weight,
    input  [`FEATURE_BITWIDTH*(`PADDED_WIDTH)*(`PADDED_HEIGHT)-1:0] padded_feature,
    // Outputs
    output                          result_valid,
    output [`KERNEL_ACCUM_BITWIDTH*(`IMAGE_WIDTH*`IMAGE_HEIGHT)-1:0] output_feature_map
);

// Local parameter definitions
localparam OUTPUT_WIDTH = (`IMAGE_WIDTH);   //  Same Padding
localparam OUTPUT_HEIGHT = (`IMAGE_HEIGHT); //  Same Padding

//==============================================================================
// Pipeline Control Logic
//==============================================================================


localparam PIPELINE_STAGES = 1; 

integer i;
reg [PIPELINE_STAGES-1:0] pipeline_valid;

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        pipeline_valid <= {PIPELINE_STAGES{1'b0}};
    end else begin
        pipeline_valid[PIPELINE_STAGES-1] <= 1'b1;
        // Shift through the pipeline stages if more than 1
        if (PIPELINE_STAGES > 1) begin
            for (i = 1; i < PIPELINE_STAGES; i = i + 1) begin
                pipeline_valid[i] <= pipeline_valid[i-1];
            end
        end
    end
end    


//==============================================================================
// Kernel Calculation (Parallel Stride)
//==============================================================================

wire [`KERNEL_ACCUM_BITWIDTH*(OUTPUT_WIDTH*OUTPUT_HEIGHT)-1:0] conv_results;
reg  [`KERNEL_ACCUM_BITWIDTH*(OUTPUT_WIDTH*OUTPUT_HEIGHT)-1:0] output_results_reg;

genvar out_row, out_col;
generate
    for(out_row = 0; out_row < OUTPUT_HEIGHT; out_row = out_row + 1) begin: output_row
        for(out_col = 0; out_col < OUTPUT_WIDTH; out_col = out_col + 1) begin: output_col
            
            //  Create Kernel Window(3x3)   
            wire [`FEATURE_BITWIDTH*(`KERNEL_WIDTH*`KERNEL_HEIGHT)-1:0] kernel_window;
            
            genvar k_row, k_col;
            for(k_row = 0; k_row < `KERNEL_HEIGHT; k_row = k_row + 1) begin: kernel_row_loop
                for(k_col = 0; k_col < `KERNEL_WIDTH; k_col = k_col + 1) begin: kernel_col_loop

                    localparam padded_row = out_row * `STRIDE_SIZE + k_row;
                    localparam padded_col = out_col * `STRIDE_SIZE + k_col;
                    
                    assign kernel_window[`FEATURE_BITWIDTH*((k_row*`KERNEL_WIDTH) + k_col) +: `FEATURE_BITWIDTH] = 
                        padded_feature[`FEATURE_BITWIDTH*((padded_row*`PADDED_WIDTH) + padded_col) +: `FEATURE_BITWIDTH];
                end
            end
            
            // Convolution (Kernel Window, Filter)
            wire [`KERNEL_MUL_BITWIDTH*(`KERNEL_WIDTH*`KERNEL_HEIGHT)-1:0] mult_results;      //  9 result (8 Bit * 8 Bit)
                

            genvar k_idx;
            for(k_idx = 0; k_idx < `KERNEL_WIDTH*`KERNEL_HEIGHT; k_idx = k_idx + 1) begin: multiply_loop
                // Multiply 
                assign mult_results[k_idx*`KERNEL_MUL_BITWIDTH +: `KERNEL_MUL_BITWIDTH] = 
                    $signed(kernel_window[`FEATURE_BITWIDTH*k_idx +: `FEATURE_BITWIDTH]) * 
                    $signed(weight[`WEIGHT_BITWIDTH*k_idx +: `WEIGHT_BITWIDTH]);
            end
            
            /*
             *      IF REGISTERED OUTPUT NEED
             */
            // reg [`KERNEL_MUL_BITWIDTH*(`KERNEL_WIDTH*`KERNEL_HEIGHT)-1:0] r_mult_results;
            //
            //     always @(posedge clk or negedge reset_n) begin
            //         if(!reset_n) begin
            //             r_mult_results[k_idx*`KERNEL_MUL_BITWIDTH +: `KERNEL_MUL_BITWIDTH] <= {`KERNEL_MUL_BITWIDTH{1'b0}};
            //         end else begin
            //             r_mult_results[k_idx*`KERNEL_MUL_BITWIDTH +: `KERNEL_MUL_BITWIDTH] <= 
            //                 mult_results[k_idx*`KERNEL_MUL_BITWIDTH +: `KERNEL_MUL_BITWIDTH];
            //         end
            //     end
            // 
            
            // Accumulate
            wire [`KERNEL_ACCUM_BITWIDTH-1:0] sum_result;
            
            assign sum_result = 
              $signed(mult_results[0*`KERNEL_MUL_BITWIDTH +: `KERNEL_MUL_BITWIDTH]) 
            + $signed(mult_results[1*`KERNEL_MUL_BITWIDTH +: `KERNEL_MUL_BITWIDTH])
            + $signed(mult_results[2*`KERNEL_MUL_BITWIDTH +: `KERNEL_MUL_BITWIDTH])
            + $signed(mult_results[3*`KERNEL_MUL_BITWIDTH +: `KERNEL_MUL_BITWIDTH])
            + $signed(mult_results[4*`KERNEL_MUL_BITWIDTH +: `KERNEL_MUL_BITWIDTH])
            + $signed(mult_results[5*`KERNEL_MUL_BITWIDTH +: `KERNEL_MUL_BITWIDTH])
            + $signed(mult_results[6*`KERNEL_MUL_BITWIDTH +: `KERNEL_MUL_BITWIDTH])
            + $signed(mult_results[7*`KERNEL_MUL_BITWIDTH +: `KERNEL_MUL_BITWIDTH])
            + $signed(mult_results[8*`KERNEL_MUL_BITWIDTH +: `KERNEL_MUL_BITWIDTH]);

            assign conv_results[`KERNEL_ACCUM_BITWIDTH*((out_row*OUTPUT_WIDTH) + out_col) +: `KERNEL_ACCUM_BITWIDTH] = sum_result;

        end
    end
endgenerate

//==============================================================================
// Register the Final Sum
//==============================================================================
always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        output_results_reg <= 0;
    end else begin
        output_results_reg <= conv_results;
    end
end

//==============================================================================
// Output Assignments
//==============================================================================
assign result_valid = pipeline_valid[PIPELINE_STAGES-1];
assign output_feature_map = output_results_reg;

endmodule