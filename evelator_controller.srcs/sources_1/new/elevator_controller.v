`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.11.2024 19:49:38
// Design Name: 
// Module Name: elevator_controller
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


module elevator_controller(
    input i_clk, i_rst_n, i_stop,
    input [4:0] i_req_ext, i_req_inter,
    output o_up, o_down, o_door,
    output [2:0] o_current_floor
    );

    wire pulse_2s;
    prescaler_2sec #(.PSC(100000)) clock_converter( //here set 100000 for 2ms simulation, if want real time, use 100000000.
        .clk_50MHz(i_clk),
        .i_rst_n(i_rst_n),
        .i_stop(i_stop),
        .out(pulse_2s)
    );

    wire feedback_up, feedback_down, floor_reached;
    wire [2:0] current_floor_reg;
    wire [2:0] target_floor;       
    priority_controller PCU(
        .clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_stop(i_stop),
        .o_up(feedback_up),
        .o_down(feedback_down),
        .floor_reached(floor_reached),
        .current_floor_reg(current_floor_reg),
        .i_req_ext(i_req_ext),
        .i_req_inter(i_req_inter),
        .floor_next(target_floor)
    );
        
    up_down EMU(
        .clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_stop(i_stop),
        .pulse(pulse_2s),
        .floor_next(target_floor),
        .o_current_floor(current_floor_reg),
        .floor_reached(floor_reached),
        .o_up(feedback_up),
        .o_down(feedback_down),
        .o_door(o_door)        
    );
    
    assign o_up = feedback_up;
    assign o_down = feedback_down;
    assign o_current_floor = current_floor_reg;
    
endmodule
