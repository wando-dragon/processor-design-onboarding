module counter #(
    parameter WIDTH = 8
) (
    input  logic             clk,
    input  logic             reset,
    input  logic             enable,
    output logic [WIDTH-1:0] count
);

    // Your logic here
    always_ff @(posedge clk) begin
        if (reset)
            count <= '0;
        else if (enable)
            count <= count + 1;
    end


endmodule