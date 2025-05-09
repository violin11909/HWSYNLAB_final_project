`timescale 1ns / 1ps
module VGA_Controller (
    input wire clk,              // 25MHz Clock for VGA
    input wire [15:0] pixel_data, //pixel from frame buffer
    output reg hsync, vsync,     // VGA Sync signals
    output reg [3:0] red, green, blue, // VGA Color signals
    output reg active_video,      // Active pixel flag
    output reg [16:0] read_addr //address to fetch from frame_buffer
);

    reg [9:0] h_count = 0;
    reg [9:0] v_count = 0;
    
    always @(posedge clk) begin
        if (h_count < 799) h_count <= h_count + 1;
        else begin
            h_count <= 0;
            if (v_count < 524) v_count <= v_count + 1;
            else v_count <= 0;
        end
    end
    
    always @(*) begin
        hsync = (h_count >= 656 && h_count < 752) ? 0 : 1;
        vsync = (v_count >= 490 && v_count < 492) ? 0 : 1;
        active_video = (h_count < 320 && v_count < 240); //fixed from 640 480

        /*
        x = h_count;   // กำหนดค่าพิกเซลแนวนอน
        y = v_count;   // กำหนดค่าพิกเซลแนวตั้ง
        */

        if (active_video) begin
            read_addr = v_count * 320 + h_count; //320 = width
            //RGB 5-6-5 bits
            red = pixel_data[15:12];  // แสดงสีแดง
            green = pixel_data[10:7];
            blue = pixel_data[4:1];
        end else begin //if not active_video
            //set to its default
            red = 0; green = 0; blue = 0;
            read_addr = 0;
        end
    end
endmodule
