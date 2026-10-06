`timescale 1ns/1ps

module fifo_tb;

    logic clk;
    logic reset;
    logic wr_en;
    logic rd_en;
    logic [7:0] wr_data;
    logic [7:0] rd_data;
    logic full;
    logic empty;

    //Random Testing
    logic [7:0] expected_queue[$];
    logic [7:0] expected_data;
    logic do_write;
    logic do_read;
    fifo #(
        .WIDTH(8),
        .DEPTH(4)
    ) dut (
        .clk(clk),
        .reset(reset),
        .wr_en(wr_en),
        .wr_data(wr_data),
        .rd_en(rd_en),
        .rd_data(rd_data),
        .full(full),
        .empty(empty)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Apply requests before the rising edge, then wait for results
    task cycle(
        input logic write_request,
        input logic read_request,
        input logic [7:0] data
    );
        begin
            @(negedge clk);
            wr_en = write_request;
            rd_en = read_request;
            wr_data = data;

            @(posedge clk);
            #1;
        end
    endtask

    task check_data(input logic [7:0] expected);
        begin
            if (rd_data !== expected)
                $fatal(1, "Expected data=%0d, got %0d",
                       expected, rd_data);
        end
    endtask

    task check_flags(
        input logic expected_full,
        input logic expected_empty
    );
        begin
            if (full !== expected_full || empty !== expected_empty)
                $fatal(1, "Expected full=%0b empty=%0b, got full=%0b empty=%0b", expected_full, expected_empty, full, empty);
        end
    endtask

    initial begin
        reset = 1;
        wr_en = 0;
        rd_en = 0;
        wr_data = 0;

        // 1. reset produces empty = 1
        @(posedge clk);
        #1;
        check_flags(0, 1);
        check_data(0);

        @(negedge clk);
        reset = 0;

        // 2. one write makes the FIFO non-empty
        cycle(1, 0, 8'd42);
        check_flags(0, 0);

        // 3. write then read returns the correct data
        cycle(0, 1, 0);
        check_data(8'd42);
        check_flags(0, 1);

        // 4 and 5. multiple values preserve order + filling the FIFO asserts full
        cycle(1, 0, 8'd10);
        check_flags(0, 0);
        cycle(1, 0, 8'd20);
        check_flags(0, 0);
        cycle(1, 0, 8'd30);
        check_flags(0, 0);
        cycle(1, 0, 8'd40);
        check_flags(1, 0);

        // 6. a write while full is rejected
        cycle(1, 0, 8'd99);
        check_flags(1, 0);

        // 7. draining the FIFO asserts empty
        cycle(0, 1, 0);
        check_data(8'd10);
        check_flags(0, 0);
        cycle(0, 1, 0);
        check_data(8'd20);
        check_flags(0, 0);
        cycle(0, 1, 0);
        check_data(8'd30);
        check_flags(0, 0);
        cycle(0, 1, 0);
        check_data(8'd40);
        check_flags(0, 1);

        // 8. a read while empty is rejected
        cycle(0, 1, 0);
        check_data(8'd40);
        check_flags(0, 1);

        // 9. pointer wraparound
        cycle(1, 0, 8'd50);
        cycle(1, 0, 8'd60);
        cycle(1, 0, 8'd70);

        cycle(0, 1, 0);
        check_data(8'd50);
        cycle(0, 1, 0);
        check_data(8'd60);

        cycle(1, 0, 8'd80);
        cycle(1, 0, 8'd90);
        cycle(1, 0, 8'd100);
        check_flags(1, 0);

        cycle(0, 1, 0);
        check_data(8'd70);
        cycle(0, 1, 0);
        check_data(8'd80);
        cycle(0, 1, 0);
        check_data(8'd90);
        cycle(0, 1, 0);
        check_data(8'd100);
        check_flags(0, 1);

        // 10. simultaneous read/write
        cycle(1, 0, 8'd11);
        cycle(1, 0, 8'd22);

        cycle(1, 1, 8'd33);
        check_data(8'd11);
        check_flags(0, 0);

        cycle(0, 1, 0);
        check_data(8'd22);
        check_flags(0, 0);

        cycle(0, 1, 0);
        check_data(8'd33);
        check_flags(0, 1);

        // Empty: accept write, reject simultaneous read.
        cycle(1, 1, 8'd55);
        check_data(8'd33);
        check_flags(0, 0);

        cycle(0, 1, 0);
        check_data(8'd55);
        check_flags(0, 1);

        // Full: accept read, reject simultaneous write.
        cycle(1, 0, 8'd1);
        cycle(1, 0, 8'd2);
        cycle(1, 0, 8'd3);
        cycle(1, 0, 8'd4);
        check_flags(1, 0);

        cycle(1, 1, 8'd99);
        check_data(8'd1);
        check_flags(0, 0);

        cycle(0, 1, 0);
        check_data(8'd2);
        cycle(0, 1, 0);
        check_data(8'd3);
        cycle(0, 1, 0);
        check_data(8'd4);
        check_flags(0, 1);

        // Randomized Testing
        @(negedge clk);
        reset = 1;
        wr_en = 0;
        rd_en = 0;
        wr_data = 0;
        

        @(posedge clk);
        #1;
        check_flags(0, 1);
        check_data(0);

        repeat (200) begin
            @(negedge clk);
            reset = 0;

            
            wr_en   = 1'($urandom_range(1, 0));
            rd_en   = 1'($urandom_range(1, 0));
            wr_data = 8'($urandom_range(255, 0));

            
            do_write = wr_en && !full;
            do_read  = rd_en && !empty;

          
            if (do_read)
                expected_data = expected_queue.pop_front();

            if (do_write)
                expected_queue.push_back(wr_data);

            @(posedge clk);
            #1;

            if (do_read)
                check_data(expected_data);

            check_flags(
                expected_queue.size() == 4,
                expected_queue.size() == 0
            );
        end

    $display("All FIFO tests passed!");
$finish;
    end

    initial begin
        #100us;
        $fatal(1, "Simulation timed out");
    end

endmodule