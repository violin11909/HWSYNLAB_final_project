`timescale 1ns / 1ps


module SD_controller (
    input wire clk,
    input wire reset,
    input wire miso,
    input wire mosi,
    input wire sck, //fix output -> input
    input wire cs, //fix output -> input
    output reg [15:0] pixel_data,
    output reg [16:0] pixel_addr,
    output reg write_enable,
    output reg spi_start,
    input wire spi_done,
    input wire [7:0] spi_data_out,
    output reg [7:0] spi_data_in,
    input wire [1:0] image_index,
    input wire delete_flag,
    
    
     output reg [1:0] seg_display
);

parameter IDLE         = 4'd0;
parameter INIT_START   = 4'd1;
parameter SEND_CMD0    = 4'd2;
parameter WAIT_CMD0    = 4'd3;
parameter SEND_CMD8    = 4'd4;
parameter WAIT_CMD8    = 4'd5;
parameter SEND_CMD55   = 4'd6;
parameter SEND_ACMD41  = 4'd7;
parameter WAIT_ACMD41  = 4'd8;
parameter SEND_CMD16   = 4'd9;
parameter SEND_CMD17   = 4'd10;
parameter WAIT_TOKEN   = 4'd11;
parameter READ_BLOCK   = 4'd12;
parameter NEXT_BLOCK   = 4'd13;
parameter DONE         = 4'd14;

    // ใช้ reg เก็บสถานะปัจจุบัน
    reg [3:0] state = IDLE;
    reg [9:0] byte_cnt = 0;
    reg [7:0] block_buffer;
    reg even_byte = 0;
    reg [31:0] block_index = 0;

    localparam BLOCKS_PER_IMAGE = 300;

    wire [31:0] base_block_addr = image_index * BLOCKS_PER_IMAGE;
    wire [31:0] block_addr = base_block_addr + block_index;

    /*
    assign mosi = 1'b0;
    assign sck = clk;
    */
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            spi_start <= 0;
            pixel_addr <= 0;
            write_enable <= 0;
            byte_cnt <= 0;
            block_index <= 0;
            even_byte <= 0;
            
            seg_display <= 2'b11;
        end else begin
            spi_start <= 0;
            write_enable <= 0;

            if (delete_flag) begin
                pixel_addr <= 0;
                pixel_data <= 16'h0000;
                write_enable <= 1;
                if (pixel_addr < BLOCKS_PER_IMAGE * 256)
                    pixel_addr <= pixel_addr + 1;
                else
                    state <= DONE;
            end else begin
                case (state)
                    IDLE: begin
                    seg_display <= 2'b10;
                        state <= INIT_START;
                    end
                    INIT_START: begin
                    seg_display <= 2'b01;
                        spi_data_in <= 8'h40;
                        spi_start <= 1;
                        state <= SEND_CMD0;
                    end
                    SEND_CMD0: begin
                    seg_display <= 2'b01;
                        if (spi_done) begin
                            spi_data_in <= 8'h00;
                            spi_start <= 1;
                            state <= WAIT_CMD0;
                        end
                    end
                    WAIT_CMD0: begin
                    seg_display <= 2'b01;
                        if (spi_done) begin
                            state <= (spi_data_out == 8'h01) ? SEND_CMD8 : INIT_START;
                        end
                    end
                    SEND_CMD8: begin
                    seg_display <= 2'b10;
                        spi_data_in <= 8'h48;
                        spi_start <= 1;
                        state <= WAIT_CMD8;
                    end
                    WAIT_CMD8: begin
                    seg_display <= 2'b11;
                        if (spi_done) state <= SEND_CMD55;
                    end
                    SEND_CMD55: begin
                    seg_display <= 2'b00;
                        spi_data_in <= 8'h77;
                        spi_start <= 1;
                        state <= SEND_ACMD41;
                    end
                    SEND_ACMD41: begin
                    seg_display <= 2'b01;
                        if (spi_done) begin
                            spi_data_in <= 8'h69;
                            spi_start <= 1;
                            state <= WAIT_ACMD41;
                        end
                    end
                    WAIT_ACMD41: begin
                    seg_display <= 2'b10;
                        if (spi_done) begin
                            state <= (spi_data_out == 8'h00) ? SEND_CMD16 : SEND_CMD55;
                        end
                    end
                    SEND_CMD16: begin
                    seg_display <= 2'b11;
                        spi_data_in <= 8'h50;
                        spi_start <= 1;
                        state <= SEND_CMD17;
                    end
                    SEND_CMD17: begin
                    seg_display <= 2'b00;
                        if (spi_done) begin
                            spi_data_in <= 8'h11;
                            spi_start <= 1;
                            state <= WAIT_TOKEN;
                        end
                    end
                    WAIT_TOKEN: begin
                    seg_display <= 2'b01;
                        if (spi_done && spi_data_out == 8'hFE)
                            state <= READ_BLOCK;
                    end
                    READ_BLOCK: begin
                    seg_display <= 2'b10;
                        if (spi_done) begin
                            block_buffer <= spi_data_out;

                            // PRINT DEBUG
                            

                            if (even_byte) begin
                                pixel_data <= {block_buffer, spi_data_out};
                                pixel_addr <= pixel_addr + 1;
                                write_enable <= 1;
                            end
                            even_byte <= ~even_byte;
                            byte_cnt <= byte_cnt + 1;

                            if (byte_cnt == 511) begin
                                byte_cnt <= 0;
                                block_index <= block_index + 1;
                                even_byte <= 0;
                                if (block_index == BLOCKS_PER_IMAGE - 1)
                                    state <= DONE;
                                else
                                    state <= NEXT_BLOCK;
                            end else begin
                                spi_data_in <= 8'hFF;
                                spi_start <= 1;
                            end
                        end
                    end
                    NEXT_BLOCK: begin
                        spi_data_in <= 8'h11;
                        spi_start <= 1;
                        state <= WAIT_TOKEN;
                    end
                    DONE: begin
                        state <= DONE;
                    end
                endcase
            end
        end
    end
endmodule