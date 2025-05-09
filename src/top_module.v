`timescale 1ns / 1ps
module top_module (
    input wire clk,
    input wire reset,
    input wire left_button,
    input wire right_button,
    input wire delete_button,
    input wire miso,        // SD card data input
    output wire mosi, sck,  // SPI signals
    output wire cs,
    output wire hsync, vsync,
    output wire [3:0] red, green, blue,
       
    output wire [7:0]  Segments,
    output wire [3:0]  AN
);

    wire [7:0] sd_data;
    wire [7:0] write_data;
    wire [16:0] write_addr;
    wire write_en;

    wire [1:0] image_index;
    wire delete_flag;

    //declare wire
    wire spi_mosi, spi_sck, spi_cs;
    
    wire [1:0] seg_display; //add

    // SPI master
    SPI_Master spi (
        .clk(clk),
        .reset(reset),
        .miso(miso),
        .mosi(spi_mosi),
        .sck(spi_sck),
        .cs(spi_cs),
        .data_out(sd_data)
    );

    //assign outputs
    assign mosi = spi_mosi;
    assign sck = spi_sck;
    assign cs = spi_cs;

    // SD Controller
    SD_controller sd_ctrl (
        .clk(clk),
        .reset(reset),
        .image_index(image_index),
        .miso(miso),
        .mosi(mosi),
        .sck(sck),
        .cs(cs),
        .pixel_data(write_data),
        .pixel_addr(write_addr),
        .write_enable(write_en),
        .spi_start(),         // คุณสามารถเชื่อมต่อกับ SPI master เพิ่มเติมได้ถ้าจำเป็น
        .spi_done(),          // เช่นจาก SPI master
        .spi_data_out(sd_data),
        .spi_data_in(),     // อาจต้องเชื่อมใน design จริง
        .seg_display(seg_display)
    );
     SevenSegmentDisplay5bit seven_seg_inst (
        .Clk(clk),
        .Reset(reset),
        .DataIn(seg_display),
        .Segments(Segments),
        .AN(AN)      
    );

    wire [16:0] read_addr;
    wire [15:0] pixel_data;

    // Frame buffer
    frame_buffer buffer (
        .clk(clk),
        .we(write_en),
        .write_pixel(write_data),
        .write_addr(write_addr),
        .read_addr(read_addr),
        .vga_pixel(pixel_data)
    );

    // VGA output
    VGA_Controller vga (
        .clk(clk),
        .hsync(hsync),
        .vsync(vsync),
        .red(red),
        .green(green),
        .blue(blue),
        .pixel_data(pixel_data),
        .active_video(),
        .read_addr(read_addr)
    );

    // Updated button logic
    button_switch btn (
        .clk(clk),
        .reset(reset),
        .left_button(left_button),
        .right_button(right_button),
        .delete_button(delete_button),
        .image_index(image_index),
        .delete_flag(delete_flag)
    );

endmodule