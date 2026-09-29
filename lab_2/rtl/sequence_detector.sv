module sequence_detector (
    input  logic clk,
    input  logic reset,
    input  logic x,
    output logic detect
);

    // Your FSM here
    typedef enum logic [2:0]{
        IDLE,
        GOT1,
        GOT10,
        GOT101,
        DONE
    } state_t;

    state_t state;
    state_t next_state;

    always_ff @(posedge clk) begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    always_comb begin
        next_state = state;
        detect = 1'b0;

        case (state)

            IDLE: begin
                if (x) 
                    next_state = GOT1; 
            end

            GOT1: begin
                if (x == 1'b0)
                    next_state = GOT10; 
            end

            GOT10: begin
                if (x)
                  next_state = GOT101;
                else
                  next_state = IDLE;
            end

            GOT101: begin
                if (x)
                    next_state = DONE;
                else
                    next_state = GOT10;
            end
            DONE: begin
                detect = 1'b1; 
                if (x)
                    next_state = GOT1;
                else 
                    next_state = GOT10;

            end 

            default: begin
                next_state = IDLE;
            end

        endcase
    end
endmodule
