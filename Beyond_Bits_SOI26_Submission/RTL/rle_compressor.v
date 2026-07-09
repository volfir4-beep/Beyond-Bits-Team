// rle_compressor.v
// Simple RLE: reads serial bit input, outputs (bit, count) pairs
module rle_compressor (
    input clk, rst, data_in, data_valid,
    output reg [3:0] run_count,
    output reg run_bit,
    output reg out_valid
);
    reg [3:0] count;
    reg current_bit;
    reg started;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count       <= 1; 
            current_bit <= 0;
            started     <= 0; 
            out_valid   <= 0;
            run_count   <= 0;
            run_bit     <= 0;
        end else if (data_valid) begin
            out_valid <= 0;
            if (!started) begin
                current_bit <= data_in;
                count       <= 1; 
                started     <= 1;
            end else if (data_in == current_bit && count < 15) begin
                count <= count + 1;
            end else begin
                // Output the completed run
                run_bit   <= current_bit;
                run_count <= count;
                out_valid <= 1;
                
                // Start new run
                current_bit <= data_in;
                count       <= 1;
            end
        end else if (started) begin
            // FLUSH LOGIC: If data is no longer valid but we have a trapped run, flush it!
            run_bit   <= current_bit;
            run_count <= count;
            out_valid <= 1;
            started   <= 0; // Clear started flag so we don't double-flush
            count     <= 1;
        end else begin
            out_valid <= 0;
        end
    end
endmodule
