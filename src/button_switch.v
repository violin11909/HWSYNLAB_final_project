module button_switch (
    input wire clk,
    input wire button,
    output reg [1:0] image_index // Index ของภาพ
);

    always @(posedge clk) begin
        if (button)
            image_index <= image_index + 1; // กดปุ่มแล้วเปลี่ยนรูป
    end
endmodule
