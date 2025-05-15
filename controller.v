`timescale 1ns / 1ps

module controller(input wire CCLK, SW0, SW1, SW2, BTN0, BTN1, BTN2, BTN3, output reg JA1, JA2, JA3, JA4, JB1);
	
	//Define SW0 as reset
	wire reset;
	assign reset = SW0;
	
	wire[1:0] flow;
	assign flow = {SW2, SW1};
	
	//clock divider wires
	wire slowclk;
	wire CLK0_OUT;
	
	//either btn 1 or btn 3 will cross with the N/S straight
	wire NS_CROSS;
	assign NS_CROSS = (BTN1 || BTN3);
	
	//similarly, 0 and 2
	wire EW_CROSS;
	assign EW_CROSS = (BTN0 || BTN2);
	
	reg EW_FLAG;
	reg NS_FLAG;
	
	reg CLEAR_EW;
	reg CLEAR_NS;
	
	
	
	//clock divider instantiation
	divclk divclk (
    .CLKIN_IN(CCLK), 
    .CLKDV_OUT(slowclk), 
    .CLKIN_IBUFG_OUT(), 
    .CLK0_OUT(CLK0_OUT)
    );
	
	//counter regs
	reg[20:0] flash_count;
	reg[25:0] green_count; 
	reg[23:0] yellow_count;
	reg[23:0] red_count;
	
	//counter enable reg
	reg flash_count_en;
	reg green_count_en;
	reg yellow_count_en;
	reg red_count_en;
	
	//define states with parameters
	//22 states = 5 bit parameters
	//No Idle state - start at N/S Turn
	
	//N/S Left Arrow states
	parameter[5:0] NS_TURN_GREEN = 5'h00;
	parameter[5:0] NS_TURN_YELLOW = 5'h01;
	parameter[5:0] NS_TURN_RED = 5'h02;
	
	//NS straight no crossing signal
	parameter[5:0] NS_STRAIGHT_GREEN = 5'h03;
	parameter[5:0] NS_STRAIGHT_YELLOW = 5'h04;
	parameter[5:0] NS_STRAIGHT_YELLOW_OFF = 5'h05;
	parameter[5:0] NS_STRAIGHT_RED = 5'h06;
	
	//NS straight w crossing signal
	parameter[5:0] NS_STRAIGHT_GREEN_CROSS = 5'h07;
	parameter[5:0] NS_STRAIGHT_YELLOW_CROSS = 5'h08;
	parameter[5:0] NS_STRAIGHT_RED_CROSS = 5'h09;
	
	//EW left arrow sequence
	parameter[5:0] EW_TURN_GREEN = 5'h0a;
	parameter[5:0] EW_TURN_YELLOW= 5'h0b;
	parameter[5:0] EW_TURN_RED = 5'h0c;
	
	//EW straight no crossing
	parameter[5:0] EW_STRAIGHT_GREEN = 5'h0d;
	parameter[5:0] EW_STRAIGHT_YELLOW = 5'h0e;
	parameter[5:0] EW_STRAIGHT_YELLOW_OFF = 5'h0f;
	parameter[5:0] EW_STRAIGHT_RED = 5'h10;
	
	//EW straight w crossing signal
	parameter[5:0] EW_STRAIGHT_GREEN_CROSS = 5'h11;
	parameter[5:0] EW_STRAIGHT_YELLOW_CROSS = 5'h12;
	parameter[5:0] EW_STRAIGHT_RED_CROSS = 5'h13;
	
	//current and next state regs
	reg[5:0] current, next;
	
	//combinational logic to determine next state
	always@(*) begin
		//defaults
		flash_count_en = 0;
		green_count_en = 0;
		yellow_count_en = 0;
		red_count_en = 0;
		CLEAR_EW = 0;  
		CLEAR_NS = 0;
	 
		case(current)
			NS_TURN_GREEN: begin
				green_count_en = 1;
				{JB1, JA4, JA3, JA2, JA1} = 0;
				
				if(green_count == 0) next = NS_TURN_YELLOW;
				else next = NS_TURN_GREEN;
			end			
			NS_TURN_YELLOW: begin
				green_count_en = 0;
				yellow_count_en = 1;
				{JB1, JA4, JA3, JA2, JA1} = 1;
				
				if(yellow_count == 0) next = NS_TURN_RED;
				else next = NS_TURN_YELLOW;
			end
			NS_TURN_RED: begin
				yellow_count_en = 0;
				red_count_en = 1;
				{JB1, JA4, JA3, JA2, JA1} = 2;
				
				if(red_count == 0)begin
					if(NS_FLAG) next = NS_STRAIGHT_GREEN_CROSS;
					else next = NS_STRAIGHT_GREEN;
				end
				else next = NS_TURN_RED;
			end
			
			NS_STRAIGHT_GREEN: begin
				red_count_en = 0;
				green_count_en = 1;
				flash_count_en = 1;
				
				{JB1, JA4, JA3, JA2, JA1} = 3;
				
				if(green_count == 0) next = NS_STRAIGHT_YELLOW;
				else if(flash_count == 0) next = NS_STRAIGHT_YELLOW_OFF;
				else next = NS_STRAIGHT_GREEN;
			end			
			NS_STRAIGHT_YELLOW_OFF: begin
				green_count_en = 1;
				flash_count_en = 1;
				
				{JB1, JA4, JA3, JA2, JA1} = 4;
				
				if(green_count == 0) next = NS_STRAIGHT_YELLOW;
				else if(flash_count == 0) next = NS_STRAIGHT_GREEN;
				else next = NS_STRAIGHT_YELLOW_OFF;
			end			
			NS_STRAIGHT_YELLOW: begin
				green_count_en = 0;
				yellow_count_en = 1;
				flash_count_en = 0;
				{JB1, JA4, JA3, JA2, JA1} = 5;
				
				if(yellow_count == 0) next = NS_STRAIGHT_RED;
				else next = NS_STRAIGHT_YELLOW;
			end			
			NS_STRAIGHT_RED: begin
				yellow_count_en = 0;
				red_count_en = 1;
				
				{JB1, JA4, JA3, JA2, JA1} = 6;
				
				if(red_count == 0) next = EW_TURN_GREEN;
				else next = NS_STRAIGHT_RED;
			end
			
			NS_STRAIGHT_GREEN_CROSS: begin
				red_count_en = 0;
				green_count_en = 1;
				
				{JB1, JA4, JA3, JA2, JA1} = 7;
				
				CLEAR_NS = 1;
				
				if(green_count == 0) begin
					next = NS_STRAIGHT_YELLOW_CROSS;
					CLEAR_NS = 0;
				end
				else next = NS_STRAIGHT_GREEN_CROSS;
			end
			NS_STRAIGHT_YELLOW_CROSS: begin
				green_count_en = 0;
				yellow_count_en = 1;
				{JB1, JA4, JA3, JA2, JA1} = 8;
				
				if(yellow_count == 0) next = NS_STRAIGHT_RED;
				else next = NS_STRAIGHT_YELLOW_CROSS;
			end
			//actually no need for a separate red crossing state here as both states do exactly the same thing
			
			EW_TURN_GREEN: begin
				red_count_en = 0;
				green_count_en = 1;
				{JB1, JA4, JA3, JA2, JA1} = 10; //to keep consistent with state conventions
				
				if(green_count == 0) next = EW_TURN_YELLOW;
				else next = EW_TURN_GREEN;
			end
			EW_TURN_YELLOW: begin
				green_count_en = 0;
				yellow_count_en = 1;
				{JB1, JA4, JA3, JA2, JA1} = 11;
				
				if(yellow_count == 0) next = EW_TURN_RED;
				else next = EW_TURN_YELLOW;
			end
			EW_TURN_RED: begin
				yellow_count_en = 0;
				red_count_en = 1;
				{JB1, JA4, JA3, JA2, JA1} = 12;
				
				if(red_count == 0)begin
					if(EW_FLAG) next = EW_STRAIGHT_GREEN_CROSS;
					else next = EW_STRAIGHT_GREEN;
				end
				else next = EW_TURN_RED;
			end
			
			
			
			EW_STRAIGHT_GREEN: begin
				red_count_en = 0;
				green_count_en = 1;
				flash_count_en = 1;
				{JB1, JA4, JA3, JA2, JA1} = 13;
				
				if(green_count == 0) next = EW_STRAIGHT_YELLOW;
				else if(flash_count == 0) next = EW_STRAIGHT_YELLOW_OFF;
				else next = EW_STRAIGHT_GREEN;
			end			
			EW_STRAIGHT_YELLOW_OFF: begin
				green_count_en = 1;
				flash_count_en = 1;
				{JB1, JA4, JA3, JA2, JA1} = 14;
				
				if(green_count == 0) next = EW_STRAIGHT_YELLOW;
				else if(flash_count == 0) next = EW_STRAIGHT_GREEN;
				else next = EW_STRAIGHT_YELLOW_OFF;
			end			
			EW_STRAIGHT_YELLOW: begin
				green_count_en = 0;
				flash_count_en = 0;
				yellow_count_en = 1;
				{JB1, JA4, JA3, JA2, JA1} = 15;
				
				if(yellow_count == 0) next = EW_STRAIGHT_RED;
				else next = EW_STRAIGHT_YELLOW;
			end			
			EW_STRAIGHT_RED: begin
				yellow_count_en = 0;
				red_count_en = 1;
				{JB1, JA4, JA3, JA2, JA1} = 16;
				
				if(red_count == 0) next = NS_TURN_GREEN;
				else next = EW_STRAIGHT_RED;
			end
			
			EW_STRAIGHT_GREEN_CROSS: begin
				red_count_en =0 ;
				green_count_en = 1;
				{JB1, JA4, JA3, JA2, JA1} = 17;
				
				CLEAR_EW = 1;
				
				if(green_count == 0) begin
					next = EW_STRAIGHT_YELLOW_CROSS;
					CLEAR_EW = 0;
					
				end
				else next = EW_STRAIGHT_GREEN_CROSS;
			end
			EW_STRAIGHT_YELLOW_CROSS: begin
				green_count_en = 0;
				yellow_count_en=1;
				{JB1, JA4, JA3, JA2, JA1} = 18;
				if(yellow_count == 0) next = EW_STRAIGHT_RED;
				else next = EW_STRAIGHT_YELLOW_CROSS;
			end
				
			
		endcase
	end
	
	always@(posedge slowclk or posedge reset) begin
		if(reset) begin
			current <= NS_TURN_GREEN;
			flash_count <= 3125000;
			yellow_count <= 9375000;
			red_count <= 6250000;
			
			NS_FLAG <= 0;
			EW_FLAG <= 0;
			
			case(flow)
				2'b00: green_count <= 23437500;
				2'b01: green_count <= 31250000;
				2'b10: green_count <= 39062500;
				2'b11: green_count <= 46875000;
			endcase
		end
		
		else begin 
			if(flash_count == 0) flash_count <= 21'b111111111111111111111;		
			else if(flash_count_en) flash_count <= flash_count- 1;
			
			if(red_count == 0) red_count <= 6250000;
			else if(red_count_en) red_count <= red_count - 1;
			
			if(yellow_count == 0) yellow_count <= 9375000;
			else if(yellow_count_en) yellow_count <= yellow_count - 1;
			
			if(green_count == 0) begin
				case(flow)
					2'b00: green_count <= 23437500;
					2'b01: green_count <= 31250000;
					2'b10: green_count <= 39062500;
					2'b11: green_count <= 46875000;
				endcase
			end
			else if(green_count_en) green_count <= green_count - 1;
			
			if(EW_CROSS) EW_FLAG <= 1;
			else if(CLEAR_EW) EW_FLAG <= 0;
			
			if(NS_CROSS) NS_FLAG <= 1;
			else if (CLEAR_NS) NS_FLAG <= 0;
			
				current <= next;
			end
		
		
	end
	
endmodule
