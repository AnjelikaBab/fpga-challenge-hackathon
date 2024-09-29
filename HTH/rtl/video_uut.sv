/****************************************************************************
FILENAME     :  video_uut.sv
PROJECT      :  Hack the Hill 2024
****************************************************************************/

/*  INSTANTIATION TEMPLATE  -------------------------------------------------

video_uut video_uut (       
    .clk_i          ( ),//               
    .cen_i          ( ),//
    .vid_sel_i      ( ),//
    .vdat_bars_i    ( ),//[19:0]
    .vdat_colour_i  ( ),//[19:0]
    .fvht_i         ( ),//[ 3:0]
    .fvht_o         ( ),//[ 3:0]
    .video_o        ( ) //[19:0]
);

-------------------------------------------------------------------------- */


module video_uut (
    input  wire         clk_i           ,// clock
    input  wire         cen_i           ,// clock enable
    input  wire         vid_sel_i       ,// select source video
    input  wire [19:0]  vdat_bars_i     ,// input video {luma, chroma}
    input  wire [19:0]  vdat_colour_i   ,// input video {luma, chroma}
    input  wire [3:0]   fvht_i          ,// input video timing signals
    output wire [3:0]   fvht_o          ,// 1 clk pulse after falling edge on input signal
    output wire [19:0]  video_o          // 1 clk pulse after any edge on input signal
); 

reg [19:0]  vid_d1;
reg [3:0]   fvht_d1;
reg h_dly; //h delay
reg v_dly; //v delay
reg [11:0] line_cnt;
reg [11:0] pixel_cnt;

//colour change
reg [4:0] colour_change1 = 0;
reg [4:0] colour_change2 = 3;

reg [7:0] colour_count = 0;
reg [7:0] colour_debounce = 20;


reg [9:0] y_arr[8] = '{940, 646, 525, 450, 335, 260, 139, 64}; 
reg [9:0] cb_arr[8] = '{512, 176, 625, 289, 735, 399, 848, 512}; 
reg [9:0] cr_arr[8] = '{512, 567, 176, 231, 793, 848, 457, 512};


//frame thingy
reg[7:0] target_wait = 1;
//reg[11:0] f_cnt = 0;


//box initial coordinates
reg [11:0] x1[2] = '{1, 1600}; 
reg [11:0] x2[2] = '{300, 1900};
reg [11:0] y1[2] = '{1, 600};
reg [11:0] y2[2] = '{300 + 43, 900+43};

reg[11:0] w[2] = '{300 - 1, 1900 - 1600}; 
reg[11:0] h[2] = '{343 - 1, 943 - 600}; 



//background
reg [9:0] y = 64;
reg [9:0] cb = 512;
reg [9:0] cr = 512;

//box
reg [9:0] by = 450;
reg [9:0] bcb = 289;
reg [9:0] bcr = 231;

//step
reg [5:0]step_x = 1;
reg [5:0]step_y = 1;

reg forward_x[2] = '{1,0};
//reg forward_x2
reg forward_y[2] = '{1,0};

reg collide = 0;
//reg forward_y2

reg toggle = 0; //changes between cb and cr
reg [7:0] frame_count = 0; //count for number of frames

wire h_in = fvht_i[1];
wire v_in = fvht_i[2];
wire no_mans_land = h_in||v_in;

wire h_rising = h_in & ~h_dly;
wire h_falling = ~h_in & h_dly;

wire v_rising = v_in & ~v_dly;
wire v_falling = ~v_in & v_dly;

reg box_signal1 = 0;
reg box_signal2 = 0;
reg[19:0] box_color1;
reg[19:0] box_color2;

always @(posedge clk_i) begin
    if(cen_i) begin
		h_dly <= h_in;
		v_dly <= v_in;
		
		// check boundaries of boxes
		if((pixel_cnt >= x1[0]) && (pixel_cnt <= x2[0]) && (line_cnt >= y1[0]) && (line_cnt <= y2[0])) begin
			box_signal1 <= 1;
			box_signal2 <= 0;		
		end else if((pixel_cnt >= x1[1]) && (pixel_cnt <= x2[1]) && (line_cnt >= y1[1]) && (line_cnt <= y2[1])) begin	
			box_signal1 <= 0;
			box_signal2 <= 1;
		end else begin
			box_signal1 <= 0;
			box_signal2 <= 0;
		end
		
		if (toggle) begin
				toggle <= 0;
		end else begin
				toggle <= 1;
		end
		
		//setting up box colors
		box_color1[19:10] <= y_arr[colour_change1];
		box_color2[19:10] <= y_arr[colour_change2];
		
		if (toggle) begin
			box_color1[9:0] <= cb_arr[colour_change1];
			box_color2[9:0] <= cb_arr[colour_change2];
		end else begin
			box_color1[9:0] <= cr_arr[colour_change1];
			box_color2[9:0] <= cr_arr[colour_change2];
		end
		
		if (box_signal1) begin
			vid_d1 <= box_color1;
		end else if (box_signal2) begin
			vid_d1 <= box_color2;
		end else begin
			vid_d1 <= vdat_bars_i;
		end
		
		if(frame_count == target_wait) begin
				// x axis bouncing 
				
            if(x2[0] < 1919 && forward_x[0]) begin
                x1[0] <= step_x + x1[0];
                x2[0] <= step_x + x2[0];
            end else if ((x2[0] >= 1919 && forward_x[0]) || forward_x[0] && collide) begin
					 forward_x[0] <= 0;
					 collide <= 0;
					 colour_change1++;
				end else if(x1[0] > 0 && (!forward_x[0])) begin
                x1[0] <= x1[0] - step_x;
                x2[0] <= x2[0] - step_x;
            end else if ((x1[0] == 0 && (!forward_x[0]))|| !forward_x[0] && collide) begin
                forward_x[0] <= 1;
					 collide <= 0;
					 colour_change1++;
            end
				
				// y axis bouncing
				if(y2[0] < 1125 && forward_y[0]) begin
                y1[0] <= step_y + y1[0];
                y2[0] <= step_y + y2[0];
            end else if ((y2[0] >= 1125 && forward_y[0])|| forward_y[0] && collide) begin
					 forward_y[0] <= 0;
					 collide <= 0;
					 colour_change1++;
				end else if(y1[0] > 42 && (!forward_y[0])) begin
                y1[0] <= y1[0] - step_y;
                y2[0] <= y2[0] - step_y;
            end else if ((y1[0] == 42 && (!forward_y[0])) || !forward_y[0] && collide) begin
                forward_y[0] <= 1;
					 collide <= 0;
					 colour_change1++;
            end
				
				if(x2[1] < 1919 && forward_x[1]) begin
                x1[1] <= step_x + x1[1];
                x2[1] <= step_x + x2[1];
            end else if ((x2[1] >= 1919 && forward_x[1]) || forward_x[1] && collide) begin
					 forward_x[1] <= 0;
					 colour_change2++;
				end else if(x1[1] > 0 && (!forward_x[1])) begin
                x1[1] <= x1[1] - step_x;
                x2[1] <= x2[1] - step_x;
            end else if ((x1[1] == 0 && (!forward_x[1]))|| !forward_x[1] && collide) begin
                forward_x[1] <= 1;
					 colour_change2++;
            end
				
				// y axis bouncing
				if(y2[1] < 1125 && forward_y[1]) begin
                y1[1] <= step_y + y1[1];
                y2[1] <= step_y + y2[1];
            end else if ((y2[1] >= 1125 && forward_y[1])|| forward_y[1] && collide) begin
					 forward_y[1] <= 0;
					 colour_change2++;
				end else if(y1[1] > 42 && (!forward_y[1])) begin
                y1[1] <= y1[1] - step_y;
                y2[1] <= y2[1] - step_y;
            end else if ((y1[1] == 42 && (!forward_y[1])) || !forward_y[1] && collide) begin
                forward_y[1] <= 1;
					 colour_change2++;
            end
				
				// color change
            if(colour_change1 == 7) begin
                colour_change1 <= 0;
            end 
				
				if(colour_change2 == 7) begin
                colour_change2 <= 0;
            end 

            frame_count <= 0;
				
				if((x1[0] < x1[1] + w[1]) && (x1[0] + w[0] > x1[1]) && (y1[0] < y1[1] + h[1]) && (y1[0] + h[0] > y[1])) begin //Collision Function, checks if any of the edges are touching
					collide <=1;	
				end
      end
				
		pixel_cnt <= pixel_cnt + 1;
		fvht_d1 <= fvht_i;

	   if(h_falling == 1) begin
			pixel_cnt <= 0;
			line_cnt <= line_cnt + 1;
			//h_falling <= 0;
		end
		
		if(v_rising == 1) begin
			line_cnt <= 1;
			frame_count <= frame_count + 1;
			//v_rising <= 0;
		end
		
    end
end


// OUTPUT
assign fvht_o  = fvht_d1;
assign video_o = vid_d1;


endmodule

