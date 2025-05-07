module top_module (
    input wire clk,
    input wire button,
    input wire miso, // Data จาก SD
    output wire mosi, sck, cs, // SPI Signals
    output wire hsync, vsync,
    output wire [3:0] red, green, blue
);

    wire [7:0] sd_data;
    wire [15:0] pixel_data;
    wire [15:0] pixel_addr;
    wire [1:0] image_index;

    SPI_Master spi (
        .clk(clk), .reset(0), .miso(miso), .mosi(mosi), .sck(sck), .cs(cs), .data_out(sd_data)
    );

    frame_buffer buffer (
        .clk(clk), .pixel_data(sd_data), .pixel_addr(pixel_addr), .vga_pixel(pixel_data)
    );

    VGA_Controller vga (
        .clk(clk), .hsync(hsync), .vsync(vsync), .red(red), .green(green), .blue(blue)
    );

    button_switch btn (
        .clk(clk), .button(button), .image_index(image_index)
    );

endmodule
