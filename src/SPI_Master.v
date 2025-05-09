`timescale 1ns / 1ps
module SPI_Master (
    input wire clk,           // System clock
    input wire reset,         // Reset signal
    input wire start,         // Trigger transfer เริ่มส่งข้อมูล
    input wire [7:0] data_in, // byte to send
    output reg [7:0] data_out, // Read data
    output reg done,          // 1 when transfer is done
    output reg busy,

    output reg sck,           // slave's clock
    output reg mosi,
    input wire miso,
    output reg cs             // chip selector
);

    //parameters
    //เนื่องจากว่า clk ของ fpga เร็วกว่าของ sdc มาก จึงใช้ตัวหารเพื่อให้ทำงานในความเร็วที่เหมาะสม
    //ต้องรอ clk ของ fpga กี่ครั้ง จึงจะ toggle sck ครั้งหนึ่ง
    parameter CLK_DIV = 10; //adjust this for sck speed

    //internal registers
    reg [7:0] shift_reg; //data register for sending/receiving
    reg [2:0] bit_cnt; //count from 0 to 7 (8 bits)

    //นับจำนวน clk ของ fpga มาเช็คกับ CLK_DIV ว่าครบรอบ 1 clk ของ slave หรือยัง
    reg [7:0] clk_div_cnt; //clock divider counter
    
    reg sck_int; //internal clock phase (o or 1)
    reg state; // 0 = idle, 1 = transfering

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            shift_reg <= 8'h00;
            data_out <= 8'h00;
            bit_cnt <= 3'd0;
            clk_div_cnt <= 8'd0;
            sck <= 1'b0; //slave's clock
            mosi <= 1'b1;
            cs <= 1'b1; //not selected anything
            busy <= 1'b0; //not busy
            done <= 1'b0; //not done
            state <= 1'b0; //state 0 idle
        end else begin
            done <= 1'b0;

            //FSM
            if (state == 0) begin //idle
                if (start) begin
                    cs <= 1'b0; //start using this slave
                    busy <= 1'b1;
                    state <= 1; //next state
                    bit_cnt <= 3'd7;
                    shift_reg <= data_in;
                    mosi <= data_in[7];
                    sck <= 1'b0;
                    sck_int <= 1'b0;
                    clk_div_cnt <= 0;
                end
            end else begin //transferring
                if (clk_div_cnt == CLK_DIV) begin //ถ้าครบแล้ว รันครั้งนึง
                    clk_div_cnt <= 0; //รีเซ็ต เริ่มใหม่
                    sck_int <= ~sck_int; //toggle
                    sck <= sck_int; //อัพเดตให้ทำงานแค่ที่ rising edge

                    if (sck_int == 1'b1) begin
                        shift_reg <= {shift_reg[6:0], miso};
                        if (bit_cnt == 0) begin
                            state <= 0;
                            busy <= 0;
                            done <= 1;
                            cs <= 1'b1;
                            data_out <= {shift_reg[6:0], miso}; //final result
                        end else begin
                            bit_cnt <= bit_cnt - 1;
                            mosi <= shift_reg[6]; //actually, it's just dummy
                        end
                    end
                end else begin
                    clk_div_cnt <= clk_div_cnt + 1; //นับเสมอ
                end
            end
        end
    end

endmodule
