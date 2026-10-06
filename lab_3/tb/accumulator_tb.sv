`timescale 1ns/1ps

module accumulator_tb;

    logic clk;
    logic reset;
    logic enable;
    logic [7:0] data_in;
    logic [7:0] sum;

    accumulator #(
        .WIDTH(8)
    ) dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .data_in(data_in),
        .sum(sum)
    );

    task check_sum(input logic [7:0] expected);
        begin
            if (sum !== expected)
                $fatal(1, "Expected sum=%0d, got sum=%0d",
                       expected, sum);
        end
    endtask

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        // Reset clears sum
        reset = 1;
        enable = 0;
        data_in = 0;

        @(posedge clk);
        #1;
        check_sum(8'd0);

        // One addition works
        @(negedge clk);
        reset = 0;
        enable = 1;
        data_in = 5;

        @(posedge clk);
        #1;
        check_sum(8'd5);

        // Several additions 
        @(negedge clk);
        data_in = 3;

        @(posedge clk);
        #1;
        check_sum(8'd8);

        @(negedge clk);
        data_in = 2;

        @(posedge clk);
        #1;
        check_sum(8'd10);

        // enable = 0 holds the value
        @(negedge clk);
        enable = 0;
        data_in = 1;

        @(posedge clk);
        #1;
        check_sum(8'd10);

        // Addition resumes
        @(negedge clk);
        enable = 1;
        data_in = 7;

        @(posedge clk);
        #1;
        check_sum(8'd17);

        // 8-bit overflow wraps correctly
        @(negedge clk);
        data_in = 250;

        @(posedge clk);
        #1;
        check_sum(8'd11);

        @(negedge clk);
        data_in = 10;

        @(posedge clk);
        #1;
        check_sum(8'd21);

        //using reference model 
        @(negedge clk);
        reset = 1;
        enable = 0;
        data_in = 0;

        @(posedge clk);
        expected_sum = 0;
        #1;
        check_sum(expected_sum);

        // Test 100 randomized cycles
        repeat (100) begin
            @(negedge clk);
            reset = 0;
            enable = $urandom_range(0, 1);
            data_in = $urandom_range(0, 255);

            @(posedge clk);
            if (enable)
                expected_sum = expected_sum + data_in;

            #1;
            check_sum(expected_sum);
        end
            $display("All accumulator tests passed!");
            $finish;
        end

    initial begin
        #100us;
        $fatal(1, "Simulation timed out");
    end

endmodule