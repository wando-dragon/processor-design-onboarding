module alu_tb;

    logic [7:0] a;
    logic [7:0] b;
    logic [2:0] op;
    logic [7:0] result;

    alu dut (
        .a(a),
        .b(b),
        .op(op),
        .result(result)
    );

    initial begin

        a = 8'd10;
        b = 8'd3;

        op = 3'd0;
        #1;
        if (result !== 8'd13)
            $fatal(1, "ADD failed");

        op = 3'd1;
        #1;
        if (result !== 8'd7)
            $fatal(1, "SUB failed");

        // Add tests for AND, OR, XOR, and an unsupported opcode.

        $display("All ALU tests passed!");
        $finish;

    end

endmodule
