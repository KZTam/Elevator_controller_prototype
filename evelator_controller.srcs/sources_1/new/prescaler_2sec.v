`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.11.2024 22:57:00
// Design Name: 
// Module Name: prescaler_2sec
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module prescaler_2sec #(parameter PSC = 100000000)(
    input clk_50MHz,
    input i_rst_n,
    input i_stop,
    output reg out
    );
    
    //50MHz to 2 second interval pulse (count until 1x10^8)
    reg [31:0] cnt;
    reg halt;   //世界！！！！！
    
    initial begin
        cnt = 0;
        halt = 0;
    end
    
    always @(posedge i_stop)
    begin
        halt <= ~halt;  //invert logic when push button (i_stop) is pressed
    end
    
    always @(posedge clk_50MHz, negedge i_rst_n)
    begin
        if (~i_rst_n)
        begin
            cnt <= 0;
            out <= 0;
        end
        else if(~halt) //generate pulse if i_stop = 0
        begin
            if(cnt >= PSC)    //if want to speed up the simulation, use 100000 to change it to 2ms pulse
            begin
                out <= 1'b1;
                cnt <= 0;
            end
            else
            begin
                out <= 1'b0;
                cnt <= cnt + 1'b1;
            end
        end
    end
    
endmodule
