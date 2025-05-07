module frame_buffer (
    input wire clk, 
    input wire [15:0] pixel_data,  // ข้อมูลภาพจาก SD Card
    input wire [15:0] pixel_addr,  // Address ของ pixel
    output reg [15:0] vga_pixel    // ข้อมูลที่ใช้แสดงบน VGA
);

    reg [15:0] mem [0:76800]; // 320x240 = 76800 pixels

    always @(posedge clk) begin
        mem[pixel_addr] <= pixel_data; // เก็บข้อมูล pixel
        vga_pixel <= mem[pixel_addr];  // อ่านออกไปแสดงผล
    end
endmodule
