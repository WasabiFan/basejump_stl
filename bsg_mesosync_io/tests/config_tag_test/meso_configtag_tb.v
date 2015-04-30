//`include "definitions.v"
`define half_period 16
parameter bit_num_p = 5;

module meso_configtag_tb();

logic clk, clk2, reset, reset_r;
logic loop_back, fifo_en, channel_reset, out, toggle_bit; 

config_s conf;

assign conf = '{cfg_clk: clk2, cfg_bit: out};

clk_divider_s clk_divider;
mode_cfg_s mode_cfg;
logic [$clog2(2*bit_num_p)-1:0] la_input_bit_selector;
logic [$clog2(2*bit_num_p)-1:0] la_output_bit_selector;
logic [$clog2(2*bit_num_p)-1:0] v_output_bit_selector;
bit_cfg_s [bit_num_p*2-1:0] bit_cfg;

bsg_mesosync_config_tag_extractor
           #(  .ch1_width_p(bit_num_p)
             , .ch2_width_p(bit_num_p) 
             , .cfg_tag_base_id_p(11) 
            ) DUT
            (  .clk(clk)
             , .reset(reset_r)
             
             , .config_i(conf)

             // Configuration output
             , .clk_divider_o(clk_divider)
             , .bit_cfg_o(bit_cfg)
             , .mode_cfg_o(mode_cfg)
             , .la_input_bit_selector_o(la_input_bit_selector)
             , .la_output_bit_selector_o(la_output_bit_selector)
             , .v_output_bit_selector_o(v_output_bit_selector)
             , .fifo_en_o(fifo_en)
             , .loop_back_o(loop_back)
             , .channel_reset_o(channel_reset)
             );
int i;

initial begin

  $display({"clk\t reset\t out\t clk_div\t ch_reset lpbk\t fifo\t"
            ,"la_inp la_out v_out mode_cfg bit_cfg"});

  $monitor("%b\t %b\t %b\t %h\t %b\t %b\t %b\t %d\t %d\t %d\t %b\t %b",
           clk,reset,out, clk_divider,channel_reset,loop_back,fifo_en, 
           la_input_bit_selector, la_output_bit_selector, 
           v_output_bit_selector, mode_cfg, bit_cfg);

  out = 0;

  reset = 1'b1;
  @ (negedge clk)
  @ (negedge clk)
  reset = 1'b0;
  @ (posedge clk)
  $display("module has been reset");
 
  send_config_tag(clk2,1'b1,out);

  send_config_tag(clk2,1'b0,out,{2'b11,4'd5,4'd10},8'd11,11);
  send_config_tag(clk2,1'b0,out,{2'b01,4'd5,4'd10},8'd11,11);
  send_config_tag(clk2,1'b0,out,{2'b10,4'd5,4'd10},8'd11,11);

  send_config_tag(clk2,1'b0,out,{1'b0,5'b00000,4'd4,4'd5,4'd9,4'd7},8'd12,21);
  send_config_tag(clk2,1'b0,out,{5'h0a,5'h1b,5'h03,5'h09,5'h18},8'd13,25);
  send_config_tag(clk2,1'b0,out,{5'h05,5'h1b,5'h13,5'h19,5'h08},8'd14,25);
  send_config_tag(clk2,1'b0,out,{2'b10,4'd5,4'd10},8'd11,11);
  send_config_tag(clk2,1'b0,out,{1'b0,5'b10101,4'd4,4'd5,4'd9,4'd7},8'd12,21);
 
  #1000

  $stop;
end

always begin
  #`half_period clk = 1'b0;
  #`half_period clk = 1'b1;
end

always begin
  #`half_period clk2 = 1'b0;
  #`half_period clk2 = 1'b0;
  #`half_period clk2 = 1'b0;
  #`half_period clk2 = 1'b0;
  #`half_period clk2 = 1'b0;
  #`half_period clk2 = 1'b1;
  #`half_period clk2 = 1'b1;
  #`half_period clk2 = 1'b1;
  #`half_period clk2 = 1'b1;
  #`half_period clk2 = 1'b1;
end
    
always begin
  #(`half_period/2) toggle_bit = 1'b1;
  #(`half_period/2) toggle_bit = 1'b1;
  #(`half_period/2) toggle_bit = 1'b1;
  #(`half_period/2) toggle_bit = 1'b1;
  #(`half_period/2) toggle_bit = 1'b1;
  #(`half_period/2) toggle_bit = 1'b1;
  #(`half_period/2) toggle_bit = 1'b0;
  #(`half_period/2) toggle_bit = 1'b0;
end

endmodule