`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/08/2025 05:31:24 PM
// Design Name: 
// Module Name: data_mover_bram
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module data_mover_bram #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 12,
    parameter MEM_SIZE   = 4096
) (
    input logic clk,
    input logic reset,
    input logic i_run,
    input logic [ADDR_WIDTH - 1:0] i_num_cnt,
    output logic o_idle,
    output logic o_read,
    output logic o_write,
    output logic o_done,


    // BRAM0 READ INPUT_DATA
    output logic ce_input,  // Clock Enable 
    output logic we_input,  // Write Enable (0: Read, 1:Write)
    output logic [ADDR_WIDTH - 1:0] addr_input,
    output logic [DATA_WIDTH - 1:0] din_input,
    input logic [DATA_WIDTH - 1:0] qout_input,

    // BRAM1 READ WEIGHT_DATA
    output logic ce_weight,  // Clock Enable 
    output logic we_weight,  // Write Enable (0: Read, 1:Write)
    output logic [ADDR_WIDTH - 1:0] addr_weight,
    output logic [DATA_WIDTH - 1:0] din_weight,
    input logic [DATA_WIDTH - 1:0] qout_weight,

    // BRAM2 WRITE RESULT
    output logic                    ce_c,    // Clock Enable 
    output logic                    we_c,    // Write Enable (0: Read, 1:Write)
    output logic [ADDR_WIDTH - 1:0] addr_c,
    output logic [DATA_WIDTH - 1:0] din_c,
    input  logic [DATA_WIDTH - 1:0] qout_c
);


//-- State Transition

    typedef enum {
        IDLE,
        RUN,
        DONE
    } state_e;

    state_e read_state, read_state_next;
    state_e write_state, write_state_next;
    
    logic read_done, write_done;
    logic [ADDR_WIDTH-1:0] num_cnt;
    logic [ADDR_WIDTH-1:0] addr_cnt_read;
    logic [ADDR_WIDTH-1:0] addr_cnt_write;
    
    assign o_idle = (read_state == IDLE) && (write_state == IDLE);
    assign o_read = (read_state == RUN);
    assign o_write = (write_state == RUN);
    assign o_done = (write_state == DONE);
    assign read_done = o_read && (addr_cnt_read == num_cnt - 1);
    assign write_done = o_write && (addr_cnt_write == num_cnt - 1);

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            read_state  <= IDLE;
            write_state <= IDLE;
        end else begin
            read_state  <= read_state_next;
            write_state <= write_state_next;
        end
    end

    always_comb begin
        read_state_next  = read_state;
        write_state_next = write_state;

        case (read_state)
            IDLE:
            if (i_run) begin
                read_state_next = RUN;
            end

            RUN:
            if (read_done) begin
                read_state_next = DONE;
            end

            DONE: read_state_next = IDLE;
        endcase

        case (write_state)
            IDLE:
            if (i_run) begin
                write_state_next = RUN;
            end

            RUN:
            if (write_done) begin
                write_state_next = DONE;
            end

            DONE: write_state_next = IDLE;
        endcase
    end

//-- Address Counter


    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            num_cnt <= 0;
        end else if (i_run) begin
            num_cnt <= i_num_cnt;
        end
    end


    always @(posedge clk, posedge reset) begin
        if (reset) begin
            addr_cnt_read <= 0;
        end else if (read_done) begin
            addr_cnt_read <= 0;
        end else if (read_state == RUN) begin
            addr_cnt_read <= addr_cnt_read + 1;
        end
    end

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            addr_cnt_write <= 0;
        end else if (write_done) begin
            addr_cnt_write <= 0;
        end else if ((write_state == RUN) && we_c) begin
            addr_cnt_write <= addr_cnt_write + 1;
        end
    end


//-- READ FROM BRAM (INPUT, WEIGHT)

    assign addr_input = addr_cnt_read;
    assign ce_input = (read_state == RUN);
    assign we_input = 0;
    assign din_input = 0;

    assign addr_weight = addr_cnt_read;
    assign ce_weight = (read_state == RUN);
    assign we_weight = 0;
    assign din_weight = 0;

    logic [DATA_WIDTH-1:0] w_result;
    logic [DATA_WIDTH-1:0] result_reg;
    logic input_weight_valid;
    logic result_valid_delay;

// To ensure data validity when reading from Block RAM (BRAM), 
// the architecture typically requires a latency of one clock cycle
// after enabling the read operation. 

    always_ff @( posedge clk, posedge reset ) begin
        if(reset) begin
            input_weight_valid <= 0;
        end else begin
            input_weight_valid <= (read_state == RUN);
        end
    end

// Multiplier's 1-cycle delay ensures computed results
    
    multiplier #(
        .IN_DATA_WIDTH(DATA_WIDTH)
    ) mul_8bit_0 (
        .clk(clk),
        .reset(reset),
        .input_data(qout_input),
        .weight(qout_weight),
        .result(w_result),
        .input_weight_valid(input_weight_valid),
        .result_valid_delay(result_valid_delay)
    );


//-- WRITE TO BRAM 

// To ensure data validity when reading from Block RAM (BRAM), 
// the architecture typically requires a latency of one clock cycle
// after enabling the read operation. 

    assign addr_c = addr_cnt_write;
    assign ce_c   = result_valid_delay;
    assign we_c   = result_valid_delay;
    assign din_c  = w_result;

endmodule
