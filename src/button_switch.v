`timescale 1ns / 1ps
module button_switch (
    input wire clk,
    input wire reset,
    input wire left_button,
    input wire right_button,
    input wire delete_button,
    output reg [1:0] image_index,
    output reg delete_flag
);

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

    reg del_sync_0 = 0, del_sync_1 = 0, del_last = 0;
    reg [15:0] del_debounce_cnt = 0;
    wire delete_rising;

    always @(posedge clk) begin
        del_sync_0 <= delete_button;
        del_sync_1 <= del_sync_0;
    end

    always @(posedge clk) begin
        if (del_sync_1 != del_last) begin
            del_debounce_cnt <= del_debounce_cnt + 1;
            if (del_debounce_cnt == 16'hFFFF)
                del_last <= del_sync_1;
        end else begin
            del_debounce_cnt <= 0;
        end
    end

    assign delete_rising = (del_last == 0) && (del_sync_1 == 1);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            image_index <= 0;
            delete_flag <= 0;
        end else begin
            delete_flag <= delete_rising;
            if (right_rising)
                image_index <= image_index + 1;
            else if (left_rising)
                image_index <= image_index - 1;
        end
    end
endmodule