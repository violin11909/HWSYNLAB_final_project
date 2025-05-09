module SD_controller (
    input wire clk,
    input wire reset,
    input wire miso,
    input wire mosi,
    output wire sck,
    output reg cs,
    output reg [15:0] pixel_data,
    output reg [16:0] pixel_addr,
    output reg write_enable,
    output reg spi_start,
    input wire spi_done,
    input wire [7:0] spi_data_out,
    output reg [7:0] spi_data_in,
    input wire [1:0] image_index
);

    //FSM
    typedef enum logic [3:0] {
        IDLE = 0,
        INIT_START = 1,
        SEND_CMD0 = 2,
        WAIT_CMD0 = 3,
        SEND_CMD8 = 4,
        WAIT_CMD8 = 5,
        SEND_CMD55 = 6,
        SEND_ACMD41 = 7,
        WAIT_ACMD41 = 8,
        SEND_CMD16 = 9,
        SEND_CMD17 = 10,
        WAIT_TOKEN = 11,
        READ_BLOCK = 12,
        NEXT_BLOCK = 13,
        DONE = 14
    } state_t;

    state_t state = IDLE;

    reg [9:0] byte_cnt = 0;
    reg [7:0] block_buffer;
    reg even_byte = 0;
    reg [31:0] block_index = 0;

    localparam BLOCKS_PER_IMAGE = 300;

    wire [31:0] base_block_addr = image_index * BLOCKS_PER_IMAGE;
    wire [31:0] block_addr = base_block_addr + block_index;

    //dummy spi output
    assign mosi = 1'b0;
    assign sck = clk;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            cs <= 1;
            spi_start <= 0;
            pixel_addr <= 0;
            write_enable <= 0;
            byte_cnt <= 0;
            block_index <= 0;
            even_byte <= 0;
        end else begin //not reset
            spi_start <= 0;
            write_enable <= 0;

            case (state)
                IDLE: begin
                    cs <= 1;
                    state <= INIT_START;
                end
                INIT_START: begin
                    cs <= 0;
                    spi_data_in <= 8'h40; //cmd0
                    spi_start <= 1;
                    state <= SEND_CMD0;
                end
                SEND_CMD0: begin
                    if (spi_done) begin
                        spi_data_in <= 8'h00; //dummy argument
                        spi_start <= 1;
                        state <= WAIT_CMD0;
                    end
                end
                WAIT_CMD0: begin
                    if (spi_done) begin
                        if (spi_data_out == 8'h01) //idle state
                            state <= SEND_CMD8;
                        else
                            state <= INIT_START; //retry
                    end
                end
                SEND_CMD8: begin
                    spi_data_in <= 8'h48; //CMD8
                    spi_start <= 1;
                    state <= WAIT_CMD8;
                end
                WAIT_CMD8: begin
                    if (spi_done) begin
                        state <= SEND_CMD55;
                    end
                end
                SEND_CMD55: begin
                    spi_data_in <= 8'h77; //cmd55
                    spi_state <= 1;
                    state <= SEND_ACMD41;
                end
                SEND_ACMD41: begin
                    if (spi_done) begin
                        spi_data_in <= 8'h69; //acmd41
                        spi_start <= 1;
                        state <= WAIT_ACMD41;
                    end
                end
                WAIT_ACMD41: begin
                    if (spi_done) begin
                        if (spi_data_out == 8'h00)
                            state <= SEND_CMD16;
                        else
                            state <= SEND_CMD55; //retry ACMD41
                    end
                end
                SEND_CMD16: begin
                    spi_data_in <= 8'h50; //cmd16
                    spi_start <= 1;
                    state <= SEND_CMD17;
                end
                SEND_CMD17: begin
                    if (spi_done) begin
                        spi_data_in <= 8'h11 //cmd17 dummy (read block)
                        spi_start <= 1;
                        state <= WAIT_TOKEN;
                    end
                end
                WAIT_TOKEN: begin
                    if (spi_done && spi_data_out == 8'hFE)
                        state <= READ_BLOCK;
                end
                READ_BLOCK: begin
                    if (spi_done) begin
                        block_buffer <= spi_data_out;
                        if (even_byte) begin
                            pixel_data <= {block_buffer, spi_data_out};
                            pixel_addr <= pixel_addr + 1;
                            write_enable <= 1;
                        end
                        even_byte <= ~even_byte; //toggle
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
                    spi_data_in <= 8'h11; //next cmd17
                    spi_start <= 1;
                    state <= WAIT_TOKEN;
                end 
                DONE: begin
                    //idle or ready to next block
                    state <= DONE;
                end
            endcase
        end
    end

endmodule