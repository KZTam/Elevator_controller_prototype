`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.11.2024 00:12:27
// Design Name: 
// Module Name: up_down
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


module up_down(
    input clk, i_rst_n, i_stop,
    input pulse,    //2 sec/pulse, which update the handler
    input [2:0] floor_next, //target floor
    output [2:0] o_current_floor,
    output reg floor_reached,
    output reg o_up, o_down, o_door
    );
    
    //STATES
    localparam   IDLE = 2'b00,  //no request
                 MOVE = 2'b01,  //operation (up or down)
                 OPEN = 2'b10;  //open door
    
    reg [2:0] state_reg, state_next;
    reg [2:0] last_floor_next;  //store the previous target floor
    reg [2:0] current_floor_reg;
    reg halt;   //ZA WARUDOOOOO!!!! if HIGH (async.)
    
    initial begin
        state_next = IDLE;
        current_floor_reg = 1;  //1st floor (or ground floor)
        halt = 1'b0;
        o_up = 0;
        o_down = 0;
        o_door = 0;   
    end
    
    always @(posedge i_stop)
    begin
        halt <= ~halt;  //invert logic when push button (i_stop) is pressed
    end
                 
    always @(posedge clk, negedge i_rst_n)
    begin
        if(~i_rst_n)    //elevator need some rest
        begin
            state_reg <= IDLE;
            current_floor_reg <= 1;
            o_up <= 0;
            o_down <= 0;
            o_door <= 0;
        end
        else    //sync the state updater (should be run after up down handler is updated completely)
        begin
            state_reg <= state_next;
        end
    end
    
    //2 sec environment (for MOVE and OPEN state)
    always @(posedge pulse) 
    begin
        if(~halt)   //stop update if halt is 1
        begin
            state_next = state_reg;
            case(state_reg)
                IDLE:    
                begin
                    //nothing as IDLE state does not need 2 sec environment
                end
                MOVE:   //note: "floor_next" can be changed due to priority changes
                begin
                    if(current_floor_reg > floor_next)  //elevator floor is higher 
                    begin
                        current_floor_reg = current_floor_reg - 1;
                    end
                    else if(current_floor_reg < floor_next) //elevator floor is lower
                    begin
                        current_floor_reg = current_floor_reg + 1;
                    end
                    else    //target floor reached
                    begin
                        last_floor_next = current_floor_reg;   //store current floor as previous target floor
                        state_next = OPEN;
                    end
                end
                OPEN:   //the time when lift closed
                begin
                    if(floor_next)
                    begin
                        if(current_floor_reg > floor_next)  //elevator floor is higher 
                        begin
                            state_next = MOVE;
                        end
                        else if(current_floor_reg < floor_next) //elevator floor is lower
                        begin
                            state_next = MOVE;
                        end
                        else    //user still pressing the same floor request (like holding the button)
                        begin
                            state_next = OPEN;
                        end                      
                    end
                    else    //floor_next = 0 (the dir function above also not run)
                    begin
                        o_up = 0;
                        o_down = 0;
                        state_next = IDLE;
                    end                 
                end
                default:
                begin
                    state_next = IDLE;
                end
            endcase
        end
    end
    
    //output handler
    always @(negedge clk)   //after state updated at above, time to update next state output (for IDLE state) and update outputs 
    begin
        case (state_reg)    
            IDLE:
            begin
                floor_reached <= 0;
                    if(floor_next)  //requests received (the status will be updated instantly)
                    begin
                        if(current_floor_reg > floor_next)  //elevator floor is higher 
                        begin
                            o_down = 1;
                            state_next = MOVE;
                        end
                        else if(current_floor_reg < floor_next) //elevator floor is lower
                        begin
                            o_up = 1;
                            state_next = MOVE;
                        end
                        else    //request floor = elevator floor
                        begin
                            state_next = OPEN;
                        end  
                    end                
                o_door <= 0;           
            end
            MOVE:
            begin
                floor_reached <= 0;
                o_door <= 0;
            end
            OPEN:
            begin
                floor_reached <= 1; //to be send to priority controller to clear current floor request
                if(current_floor_reg != floor_next && floor_next) //determine elevator dir (this wont be run if there is no floor request)
                begin
                        if(current_floor_reg > floor_next)  //elevator floor is higher 
                        begin
                            o_down <= 1;
                        end
                        else if(current_floor_reg < floor_next) //elevator floor is lower
                        begin
                            o_up <= 1;
                        end                
                end
                o_door <= 1;    //open the door
            end
        endcase
    end
    
assign o_current_floor = current_floor_reg;

endmodule
