module SPI_Master (
    input wire clk,           // System clock
    input wire reset,         // Reset signal
    input wire miso,          // Data from SD card
    output reg mosi,          // Data to SD card
    output reg sck,           // SPI clock
    output reg cs,            // Chip select
    output reg [7:0] data_out // Read data
);

    reg [7:0] command;
    reg [2:0] bit_counter;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cs <= 1; mosi <= 1; sck <= 0;
            bit_counter <= 0;
            command <= 8'hFF; // Dummy data for SPI
        end else begin
            sck <= ~sck; // Toggle SPI clock
            if (sck) begin
                mosi <= command[7]; // Send command bit-by-bit
                command <= {command[6:0], miso}; // Shift in data
                bit_counter <= bit_counter + 1;
                if (bit_counter == 7) begin
                    data_out <= command; // Store received byte
                end
            end
        end
    end
endmodule
