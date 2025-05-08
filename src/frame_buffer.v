module frame_buffer (
    input wire clk, 
    input wire we, //write enable
    input wire [15:0] write_pixel, //pixel data to write
    input wire [16:0] write_addr,
    input wire [16:0] read_addr,
    output reg [15:0] vga_pixel    // ข้อมูลที่ใช้แสดงบน VGA
);

    reg [15:0] mem [0:76800]; // 320x240 = 76800 pixels

    /*
    //แบบนี้คือการอ่านและเขียนตำแหน่งหนึ่งในเมมพร้อม ๆ กัน ซึ่งทำไม่ได้ดีใน fpga
    always @(posedge clk) begin
        mem[pixel_addr] <= pixel_data; // เก็บข้อมูล pixel
        vga_pixel <= mem[pixel_addr];  // อ่านออกไปแสดงผล
    end
    */

    always @(posedge clk) begin
        if (we) begin
            mem[write_addr] <= write_pixel; //write when we == 1
        end
        vga_pixel <= mem[read_addr]; //read all the time
    end
endmodule
