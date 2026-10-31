`timescale 1ns / 1ps

module tb_top;
    localparam int CLK_PERIOD = 10;
    localparam int CLKS_PER_BIT = 868;

    logic clk = 0;
    logic rst = 1;
    logic uart_rx_pin = 1;
    wire uart_tx_pin;
    wire led0;
    integer passed = 0;
    integer failed = 0;

    always #(CLK_PERIOD / 2) clk = ~clk;

    top dut (
        .CLK100MHZ(clk),
        .btn0(rst),
        .uart_rx_pin(uart_rx_pin),
        .uart_tx_pin(uart_tx_pin),
        .led0(led0)
    );

    task automatic uart_send(input logic [7:0] data);
        @(negedge clk);
        uart_rx_pin = 0;
        repeat (CLKS_PER_BIT) @(negedge clk);
        for (int i = 0; i < 8; i++) begin
            uart_rx_pin = data[i];
            repeat (CLKS_PER_BIT) @(negedge clk);
        end
        uart_rx_pin = 1;
        repeat (CLKS_PER_BIT) @(negedge clk);
    endtask

    task automatic uart_receive(output logic [7:0] data);
        integer timeout_count;
        data = 0;
        timeout_count = 0;
        while (uart_tx_pin !== 1'b0) begin
            @(negedge clk);
            timeout_count++;
            if (timeout_count > 100000)
                $fatal(1, "UART RX timeout");
        end
        repeat (CLKS_PER_BIT + CLKS_PER_BIT/2) @(negedge clk);
        for (int i = 0; i < 8; i++) begin
            data[i] = uart_tx_pin;
            repeat (CLKS_PER_BIT) @(negedge clk);
        end
        if (uart_tx_pin !== 1'b1)
            $fatal(1, "Invalid UART stop bit");
    endtask

    task automatic run_test(
        input logic [7:0] op,
        input logic [7:0] a,
        input logic [7:0] b
    );
        logic [7:0] rx_low;
        logic [7:0] rx_high;
        logic [15:0] actual;
        logic [15:0] expected;

        if (op == 8'h01)
            expected = {8'b0, a} + {8'b0, b};
        else
            expected = a * b;

        fork
            begin
                uart_send(op);
                uart_send(a);
                uart_send(b);
            end
            begin
                uart_receive(rx_low);
                uart_receive(rx_high);
            end
        join

        actual = {rx_high, rx_low};
        if (actual === expected) begin
            passed++;
            $display("PASS: A=%0d B=%0d OP=%h RESULT=%0d", a, b, op, actual);
        end else begin
            failed++;
            $display("FAIL: A=%0d B=%0d OP=%h EXPECTED=%0d GOT=%0d", a, b, op, expected, actual);
        end
        repeat (2000) @(posedge clk);
    endtask

    initial begin
        $display("=================================");
        $display(" UART Arithmetic Accelerator TB");
        $display("=================================");
        rst = 1;
        uart_rx_pin = 1;
        repeat (20) @(posedge clk);
        @(negedge clk);
        rst = 0;
        repeat (20) @(posedge clk);

        run_test(8'h02, 12, 7);
        run_test(8'h01, 12, 7);
        run_test(8'h02, 255, 255);
        run_test(8'h01, 255, 255);
        run_test(8'h02, 0, 100);
        run_test(8'h01, 23, 42);

        for (int i = 0; i < 100; i++) begin
            logic [7:0] a;
            logic [7:0] b;
            logic [7:0] op;
            a = $urandom_range(0, 255);
            b = $urandom_range(0, 255);
            op = $urandom_range(0, 1) ? 8'h01 : 8'h02;
            run_test(op, a, b);
        end

        $display("=================================");
        $display(" TEST RESULTS");
        $display(" Passed: %0d", passed);
        $display(" Failed: %0d", failed);
        $display(" Total:  %0d", passed + failed);
        $display("=================================");
        if (failed == 0)
            $display("ALL TESTS PASSED");
        else
            $fatal(1, "TESTBENCH FAILED");
        $finish;
    end
endmodule
