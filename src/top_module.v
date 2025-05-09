module top_module (
    input wire clk,
    input wire button,
    input wire miso, // Data จาก SD
    input wire reset,
    output wire mosi, sck, cs, // SPI Signals
    output wire hsync, vsync,
    output wire [3:0] red, green, blue
);

    wire [7:0] sd_data;
    wire [15:0] pixel_data;
    wire [15:0] pixel_addr;
    wire [1:0] image_index;

    SPI_Master spi (
        .clk(clk),
        .reset(reset), 
        .miso(miso), //master in slave out
        .mosi(mosi), //master out slave in
        .sck(sck), //slave clk
        .cs(cs), //chip select
        .data_out(sd_data)
    );

    wire [16:0] read_addr; //vga to buffer
    wire [15:0] pixel_data; //buffer to vga

    frame_buffer buffer (
        .clk(clk), 
        .we(write_en), //from sd controller
        .write_pixel(write_data),
        .write_addr(write_addr),
        .read_addr(read_addr), //finish
        .vga_pixel(pixel_data) //finish
    );

    VGA_Controller vga (
        .clk(clk), 
        .hsync(hsync), //finish
        .vsync(vsync), //finish
        .red(red), //finish
        .green(green), //finish
        .blue(blue), //finish
        .pixel_data(pixel_data), //finish
        .active_video(),
        .read_addr(read_addr) //finish
    );

    button_switch btn (
        .clk(clk), 
        .button(button), 
        .image_index(image_index)
    );

endmodule
