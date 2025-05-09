module button_switch (
    input wire clk,
    input wire reset,
    input wire button,
    output reg [1:0] image_index // Index ของภาพ
);

    reg [15:0] debounce_cnt = 0;
    reg button_sync_0 = 0, button_sync_1 = 0;
    reg button_last = 0;

    wire button_rising;

    // 1. synchronize ปุ่มกับ clock domain
    always @(posedge clk) begin
        button_sync_0 <= button;
        button_sync_1 <= button_sync_0;
    end

    // 2. debouncer using counter
    always @(posedge clk) begin
        if (button_sync_1 != button_last) begin
            debounce_cnt <= debounce_cnt + 1;
            if (debounce_cnt == 16'hFFFF)
                button_last <= button_sync_1;
        end else begin
            debounce_cnt <= 0;
        end
    end

    // 3. detect rising edge
    assign button_rising = (button_last == 0) && (button_sync_1 == 1);

    // 4. เปลี่ยน image index เมื่อกดปุ่ม
    always @(posedge clk or posedge reset) begin
        if (reset)
            image_index <= 0;
        else if (button_rising)
            image_index <= image_index + 1;
    end
    
    /*
    always @(posedge clk) begin
        if (button)
            image_index <= image_index + 1; // กดปุ่มแล้วเปลี่ยนรูป
    end
    */
endmodule
