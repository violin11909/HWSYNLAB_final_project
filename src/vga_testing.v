module vga_testing 
	(
		input wire clk, reset,
		input wire [11:0] sw,
		output wire hsync, vsync,
		output wire [11:0] rgb
	);
	
	// register for RGB color
	reg [11:0] rgb_reg;
	
	// video status output from VGA_Controller
	wire video_on;
	wire [9:0] x, y;  // เพิ่มตัวแปร x, y
	
    // Instantiate VGA_Controller
    VGA_Controller vga_controller (
        .clk(clk), 
        .hsync(hsync), .vsync(vsync),
        .active_video(video_on), 
        .x(x), .y(y)
    );

    // RGB buffer
    always @(posedge clk or posedge reset)
        if (reset)
            rgb_reg <= 0;
        else
            rgb_reg <= sw;
        
    // Output RGB (ส่งค่าออกไปที่ VGA)
    assign rgb = (video_on) ? rgb_reg : 12'b0;
endmodule
