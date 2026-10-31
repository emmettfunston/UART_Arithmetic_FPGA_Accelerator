module command_fsm (
    input  logic clk,
    input  logic rst,
    input  logic [7:0] rx_data,
    input  logic rx_valid,
    input  logic tx_busy,
    output logic tx_start,
    output logic [7:0] tx_data,
    output logic [7:0] operand_a,
    output logic [7:0] operand_b,
    output logic [7:0] opcode,
    input  logic [15:0] result
);
    typedef enum logic [3:0] {
        WAIT_OPCODE,
        WAIT_A,
        WAIT_B,
        CAPTURE_RESULT,
        SEND_LOW,
        WAIT_LOW_BUSY,
        WAIT_LOW_DONE,
        SEND_HIGH,
        WAIT_HIGH_BUSY,
        WAIT_HIGH_DONE
    } state_t;

    state_t state;
    logic [15:0] result_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= WAIT_OPCODE;
            operand_a <= 0;
            operand_b <= 0;
            opcode <= 0;
            result_reg <= 0;
            tx_data <= 0;
            tx_start <= 0;
        end else begin
            tx_start <= 0;
            case (state)
                WAIT_OPCODE: begin
                    if (rx_valid && (rx_data == 8'h01 || rx_data == 8'h02)) begin
                        opcode <= rx_data;
                        state <= WAIT_A;
                    end
                end
                WAIT_A: begin
                    if (rx_valid) begin
                        operand_a <= rx_data;
                        state <= WAIT_B;
                    end
                end
                WAIT_B: begin
                    if (rx_valid) begin
                        operand_b <= rx_data;
                        state <= CAPTURE_RESULT;
                    end
                end
                CAPTURE_RESULT: begin
                    result_reg <= result;
                    state <= SEND_LOW;
                end
                SEND_LOW: begin
                    if (!tx_busy) begin
                        tx_data <= result_reg[7:0];
                        tx_start <= 1;
                        state <= WAIT_LOW_BUSY;
                    end
                end
                WAIT_LOW_BUSY: begin
                    if (tx_busy)
                        state <= WAIT_LOW_DONE;
                end
                WAIT_LOW_DONE: begin
                    if (!tx_busy)
                        state <= SEND_HIGH;
                end
                SEND_HIGH: begin
                    if (!tx_busy) begin
                        tx_data <= result_reg[15:8];
                        tx_start <= 1;
                        state <= WAIT_HIGH_BUSY;
                    end
                end
                WAIT_HIGH_BUSY: begin
                    if (tx_busy)
                        state <= WAIT_HIGH_DONE;
                end
                WAIT_HIGH_DONE: begin
                    if (!tx_busy)
                        state <= WAIT_OPCODE;
                end
                default: state <= WAIT_OPCODE;
            endcase
        end
    end
endmodule
