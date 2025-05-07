module VGA_Controller (
    input wire clk,              // 25MHz Clock for VGA
    output reg hsync, vsync,     // VGA Sync signals
    output reg [3:0] red, green, blue, // VGA Color signals
    output reg active_video,      // Active pixel flag
    output reg [9:0] x, y         // Current pixel coordinates
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
        active_video = (h_count < 640 && v_count < 480);

        x = h_count;   // กำหนดค่าพิกเซลแนวนอน
        y = v_count;   // กำหนดค่าพิกเซลแนวตั้ง
        
        if (active_video) begin
            red = 4'b1111;  // แสดงสีแดง
            green = 4'b0000;
            blue = 4'b0000;
        end else begin
            red = 0; green = 0; blue = 0;
        end
    end
endmodule
