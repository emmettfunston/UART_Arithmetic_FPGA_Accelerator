module uart_rx #(
    parameter integer CLKS_PER_BIT = 868
)(
    input  logic clk,
    input  logic rst,
    input  logic rx,
    output logic [7:0] data_out,
    output logic data_valid
);
    typedef enum logic [1:0] {
        IDLE, START, DATA, STOP
    } state_t;

    state_t state;
    logic [9:0] clk_count;
    logic [2:0] bit_index;
    logic [7:0] data_reg;
    (* ASYNC_REG = "TRUE" *) logic rx_meta;
    (* ASYNC_REG = "TRUE" *) logic rx_sync;

    always_ff @(posedge clk) begin
        if (rst) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
        end else begin
            rx_meta <= rx;
            rx_sync <= rx_meta;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
            data_reg <= 0;
            data_out <= 0;
            data_valid <= 0;
        end else begin
            data_valid <= 0;
            case (state)
                IDLE: begin
                    clk_count <= 0;
                    bit_index <= 0;
                    if (!rx_sync)
                        state <= START;
                end
                START: begin
                    if (clk_count == CLKS_PER_BIT/2 - 1) begin
                        clk_count <= 0;
                        if (!rx_sync)
                            state <= DATA;
                        else
                            state <= IDLE;
                    end else
                        clk_count <= clk_count + 1'b1;
                end
                DATA: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 0;
                        data_reg[bit_index] <= rx_sync;
                        if (bit_index == 7)
                            state <= STOP;
                        else
                            bit_index <= bit_index + 1'b1;
                    end else
                        clk_count <= clk_count + 1'b1;
                end
                STOP: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 0;
                        if (rx_sync) begin
                            data_out <= data_reg;
                            data_valid <= 1;
                        end
                        state <= IDLE;
                    end else
                        clk_count <= clk_count + 1'b1;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
