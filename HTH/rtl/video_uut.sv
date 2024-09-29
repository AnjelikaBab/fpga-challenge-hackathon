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
    output wire [19:0]  video_o      ,    // 1 clk pulse after any edge on input signal
    output wire [10:0]  pix_count_o,
    output wire [10:0]  line_count_o
); 

reg [19:0]  vid_d1;
reg [3:0]   fvht_d1;
reg h_dly; //h delay
reg v_dly; //v delay
reg [2:0] v_s;
reg [10:0] line_cnt;
reg [10:0] pixel_cnt;

wire h_in = fvht_i[1];
wire v_in = fvht_i[2];
wire no_mans_land = h_in||v_in;

wire h_rising = h_in && ~h_dly;
wire h_falling = ~h_in && h_dly;

wire v_rising = v_in && ~v_dly;
wire v_falling = ~v_in && v_dly;

always @(posedge clk_i) begin
    if(cen_i) begin
        vid_d1 <= vdat_bars_i;
        h_dly <= h_in;
        v_dly <= v_in;
        //vid_d1  <= (vid_sel_i)? vdat_colour_i : vdat_bars_i;

        pixel_cnt <= pixel_cnt + 1;
        fvht_d1 <= fvht_i;

       if(h_falling == 1) begin
            pixel_cnt <= 0;
            line_cnt <= line_cnt + 1;
        end
if(v_rising == 1) begin
            line_cnt <= 1;
            v_rising <= 0;
        end

    end
end





//always @(posedge h_rising) begin
//end


//
//always @(posedge h_falling) begin
//    pixel_cnt <= 0;
//    line_cnt <= line_cnt + 1;
//end
//
//always @(posedge v_rising) begin
//      line_cnt <= 1;
//end


//always @(posedge v_falling) begin
//end


//falling edge => when h goes from 1 to 0 or when v goes from 1 to 0 (line counter, and pixel counter needed)
//toggle between cb and cr

//Vertical edge detection
//v_s <= {v_s[1:0],  v_in}; //shifting
//falling_v_s = v_s[1:0] == 2'b10 ? 1 : 0; //falling edge trigger (vertical goes from 1 to 0)
//
////Horizontal edge detection
//h_s <= {h_s[1:0], h_in};
//falling_h_s = h_s[1:0] == 2'b10 ? 1 : 0; 




//Mask





// OUTPUT
assign fvht_o  = fvht_d1;
assign video_o = vid_d1;
//assign pix_count_o = pixel_cnt;

endmodule