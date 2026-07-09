// decompressor.v
// Re-inflates (run_bit, run_count) blocks back into a continuous serial stream
module rle_decompressor (
    input wire clk,
    input wire rst,
    input wire [3:0] run_count,
    input wire run_bit,
    input wire in_valid,
    output reg data_out,
    output reg out_valid,
    output reg ready          // Tells upstream hardware it can accept the next token
);

    reg [3:0] internal_counter;
    reg active_bit;
    reg state;

    localparam IDLE = 1'b0;
    localparam DECOMPRESS = 1'b1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out         <= 1'b0;
            out_valid        <= 1'b0;
            ready            <= 1'b1;
            internal_counter <= 4'd0;
            active_bit       <= 1'b0;
            state            <= IDLE;
        end else begin
            out_valid <= 1'b0; // Default clock-cycle pulse state

            case (state)
                IDLE: begin
                    ready <= 1'b1;
                    if (in_valid && run_count > 0) begin
                        active_bit       <= run_bit;
                        internal_counter <= run_count;
                        ready            <= 1'b0;
                        state            <= DECOMPRESS;
                    end
                end

                DECOMPRESS: begin
                    if (internal_counter > 0) begin
                        data_out         <= active_bit;
                        out_valid        <= 1'b1;
                        internal_counter <= internal_counter - 1'b1;
                    end
                    
                    if (internal_counter == 4'd1) begin
                        ready <= 1'b1; // Ready for next token on the next cycle
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule
