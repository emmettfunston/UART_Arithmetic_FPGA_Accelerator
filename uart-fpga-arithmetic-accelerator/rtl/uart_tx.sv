module uart_tx #(
    parameter integer CLKS_PER_BIT = 868
)(
    input logic clk,
    input logic rst,
    input logic start,
    input logic [7:0] data_in,
    output logic tx,
    output logic busy
);
    typedef enum logic [1:0] {
        IDLE, START_BIT, DATA, STOP
    } state_t;

    state_t state;
    logic [9:0] clk_count;
    logic [2:0] bit_index;
    logic [7:0] data_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
            data_reg <= 0;
            tx <= 1;
            busy <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1;
                    busy <= 0;
                    clk_count <= 0;
                    if (start) begin
                        data_reg <= data_in;
                        bit_index <= 0;
                        busy <= 1;
                        state <= START_BIT;
                    end
                end
                START_BIT: begin
                    tx <= 0;
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 0;
                        state <= DATA;
                    end else
                        clk_count <= clk_count + 1'b1;
                end
                DATA: begin
                    tx <= data_reg[bit_index];
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 0;
                        if (bit_index == 7)
                            state <= STOP;
                        else
                            bit_index <= bit_index + 1'b1;
                    end else
                        clk_count <= clk_count + 1'b1;
                end
                STOP: begin
                    tx <= 1;
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 0;
                        state <= IDLE;
                    end else
                        clk_count <= clk_count + 1'b1;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
