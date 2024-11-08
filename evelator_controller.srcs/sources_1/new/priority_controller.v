`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.11.2024 00:09:06
// Design Name: 
// Module Name: priority_controller
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


module priority_controller(
    input clk, i_rst_n, i_stop,
    input o_up, o_down, floor_reached,
    input [2:0] current_floor_reg,
    input [4:0] i_req_ext,
    input [4:0] i_req_inter,
    output reg [2:0] floor_next
    );
    
//    function integer log2;
//        input integer n;
//        integer i;
//        begin
//            log2 = 0;
//            for (i = n; i > 1; i = i >> 1) begin    //might have bug, infinity loop here
//                log2 = log2 + 1;
//            end
//        end
//    endfunction
    
    //STATES
    localparam   IDLE = 3'b000,  //no request
                 UP_PRIORITY = 3'b001,  //up priority algorithm
                 DOWN_PRIORITY = 3'b010,    //down priority algorithm
                 OUTPUT = 3'b011,  //output the request
                 ACKNOWLEDGED = 3'b100;  //clear current floor request (AND gate) 

    reg halt;   //THE WORLD!!!!
    reg [4:0] i_req_ext_prev, i_req_inter_prev;
    reg [2:0] state_reg, state_next;
    reg [2:0] priority_cnt;
    reg [4:0] request_reg;
    //reg [2:0] request_reg_value;
    reg [4:0] rotate_shift_flag, priority_bit;
    reg [4:0] current_floor_bit; 
    
    real current_floor_real;
    
    initial begin
        state_next = IDLE;
        i_req_ext_prev = 0;
        i_req_inter_prev = 0;
        rotate_shift_flag = 5'b00001;
        request_reg = 5'b00000;
        priority_bit = 5'b00001;
        halt = 1'b0;  
    end   
     
    always @(posedge i_stop)
    begin
        halt <= ~halt;  //invert logic when push button (i_stop) is pressed
    end
        
    always @(posedge clk, negedge i_rst_n)
    begin
        if(~i_rst_n)
        begin
            state_reg <= IDLE;
            rotate_shift_flag <= 5'b00001;
            request_reg <= 0;   //clear all request
            priority_cnt <= 0;
            floor_next <= 0;
        end
        else    //sync the state and request register
        begin
            state_reg <= state_next;
            //current_floor_real = $bitstoreal(current_floor_reg);
            request_reg <= (i_req_ext | i_req_inter);
            current_floor_bit <= (1'b1 << (current_floor_reg - 1));   //convert floor value to bit value
            //floor_next <= $log2(priority_bit) + 1; //floor_next: [1,5]
            case(priority_bit)  //log2 cannot used damnnnnnnnnn
                5'b00001: floor_next <= 1;
                5'b00010: floor_next <= 2;
                5'b00100: floor_next <= 3;
                5'b01000: floor_next <= 4;
                5'b10000: floor_next <= 5;
            endcase
        end
    end
    
    always @(posedge floor_reached)
    begin
        state_next = ACKNOWLEDGED;
    end
    
    //request_reg updater, update it when the floor button is pressed, thus solving the request keep sending problem.
//    always @(posedge i_req_ext[0], posedge i_req_inter[0])    
//    begin
//        request_reg = (request_reg | i_req_ext | i_req_inter);
//    end
    
    //state logic
    always @(negedge clk)
    begin
        //state_next = state_reg;
        if(~halt)        
        begin
//            if((i_req_ext_prev != i_req_ext) | (i_req_inter_prev != i_req_inter))   //update
//            begin
//                request_reg = (request_reg | i_req_ext | i_req_inter);
//            end
            
//            i_req_ext_prev = i_req_ext;
//            i_req_inter_prev = i_req_inter;
            
            case(state_reg)
               IDLE:
               begin
                    priority_bit = 0; //clear output
                    if(request_reg)
                    begin
                        priority_cnt = 0;
                        rotate_shift_flag = current_floor_bit;  
                        if(o_up)
                        begin
                            state_next = UP_PRIORITY;
                        end
                        else if(o_down)
                        begin
                            state_next = DOWN_PRIORITY;
                        end
                        else    
                        begin
                            state_next = UP_PRIORITY;
                        end
                    end
               end
               UP_PRIORITY: //default or when elevator is moving upwards
               begin
                    if(priority_cnt >= 5)   //1 cycle alr but no result
                    begin
                        state_next = IDLE;
                    end
                    else    //left rotate shift
                    begin
                        rotate_shift_flag = (rotate_shift_flag << 1) | (rotate_shift_flag >> 4);
                        priority_cnt = priority_cnt + 1;
                        if(rotate_shift_flag & request_reg)    //highest floor priority detected
                        begin
                            state_next = OUTPUT;
                        end
                    end
               end
               DOWN_PRIORITY:
               begin
                    if(priority_cnt >= 5)   //1 cycle alr but no result
                    begin
                        state_next = IDLE;
                    end
                    else    //right rotate shift
                    begin
                        rotate_shift_flag = (rotate_shift_flag >> 1) | (rotate_shift_flag << 4);
                        priority_cnt = priority_cnt + 1;
                        if(rotate_shift_flag & request_reg)    //highest floor priority detected
                        begin
                            state_next = OUTPUT;
                        end
                    end                    
               end
               OUTPUT:
               begin
                    //will not update next state unless floor edge posedge is detected
                    priority_bit = rotate_shift_flag;   //assign target floor (in bit form), later sync the value form at above code.
               end
               ACKNOWLEDGED:
               begin
                    request_reg = (request_reg & ~(current_floor_bit));  //might have bug
                    state_next = IDLE;  //go to idle state to detect next request
               end
            endcase
        end
    end
        
endmodule
