module button_switch (
input wire clk,
input wire reset,
input wire left_button,
input wire right_button,
output reg [1:0] image_index // Index ของภาพ 0–3 (ถ้า 2 บิต)
);

// ซิงโครไนซ์และ debounce สำหรับ left_button
reg left_sync_0 = 0, left_sync_1 = 0, left_last = 0;
reg [15:0] left_debounce_cnt = 0;
wire left_rising;

always @(posedge clk) begin
    left_sync_0 <= left_button;
    left_sync_1 <= left_sync_0;
end

always @(posedge clk) begin
    if (left_sync_1 != left_last) begin
        left_debounce_cnt <= left_debounce_cnt + 1;
        if (left_debounce_cnt == 16'hFFFF)
            left_last <= left_sync_1;
    end else begin
        left_debounce_cnt <= 0;
    end
end

assign left_rising = (left_last == 0) && (left_sync_1 == 1);

// ซิงโครไนซ์และ debounce สำหรับ right_button
reg right_sync_0 = 0, right_sync_1 = 0, right_last = 0;
reg [15:0] right_debounce_cnt = 0;
wire right_rising;

always @(posedge clk) begin
    right_sync_0 <= right_button;
    right_sync_1 <= right_sync_0;
end

always @(posedge clk) begin
    if (right_sync_1 != right_last) begin
        right_debounce_cnt <= right_debounce_cnt + 1;
        if (right_debounce_cnt == 16'hFFFF)
            right_last <= right_sync_1;
    end else begin
        right_debounce_cnt <= 0;
    end
end

assign right_rising = (right_last == 0) && (right_sync_1 == 1);

// เปลี่ยน image_index
always @(posedge clk or posedge reset) begin
    if (reset)
        image_index <= 0;
    else if (right_rising)
        image_index <= image_index + 1;
    else if (left_rising)
        image_index <= image_index - 1;
end
endmodule