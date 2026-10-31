module top (
    input  logic CLK100MHZ,
    input  logic btn0,
    input  logic uart_rx_pin,
    output logic uart_tx_pin,
    output logic led0
);
    logic rst;
    assign rst = btn0;

    logic [7:0] rx_data;
    logic rx_valid;
    logic tx_busy;
    logic tx_start;
    logic [7:0] tx_data;
    logic [7:0] operand_a;
    logic [7:0] operand_b;
    logic [7:0] opcode;
    logic [15:0] result;

    uart_rx #(.CLKS_PER_BIT(868)) receiver (
        .clk(CLK100MHZ),
        .rst(rst),
        .rx(uart_rx_pin),
        .data_out(rx_data),
        .data_valid(rx_valid)
    );

    uart_tx #(.CLKS_PER_BIT(868)) transmitter (
        .clk(CLK100MHZ),
        .rst(rst),
        .start(tx_start),
        .data_in(tx_data),
        .tx(uart_tx_pin),
        .busy(tx_busy)
    );

    arithmetic_unit alu (
        .a(operand_a),
        .b(operand_b),
        .opcode(opcode),
        .result(result)
    );

    command_fsm controller (
        .clk(CLK100MHZ),
        .rst(rst),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .tx_busy(tx_busy),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .operand_a(operand_a),
        .operand_b(operand_b),
        .opcode(opcode),
        .result(result)
    );

    always_ff @(posedge CLK100MHZ) begin
        if (rst)
            led0 <= 1'b0;
        else if (rx_valid)
            led0 <= ~led0;
    end
endmodule
