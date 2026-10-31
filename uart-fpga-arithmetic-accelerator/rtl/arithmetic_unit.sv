module arithmetic_unit (
    input  logic [7:0] a,
    input  logic [7:0] b,
    input  logic [7:0] opcode,
    output logic [15:0] result
);
    always_comb begin
        case (opcode)
            8'h01: result = {8'b0, a} + {8'b0, b};
            8'h02: result = a * b;
            default: result = 16'h0000;
        endcase
    end
endmodule
