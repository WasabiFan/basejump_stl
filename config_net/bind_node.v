`include "config_s.v"

module bind_node
  #(parameter             // node specific parameters 
    id_p = -1,            // unique ID of this node
    data_bits_p = -1,     // number of bits of configurable register associated with this node
    data_ref_len_p = -1,  // default/reset value of configurable register associated with this node
    logic [data_bits_p - 1 : 0] data_ref_p[data_ref_len_p] = 0  // data_o change reference array
   )
   (input clk_dst_i,
    input config_s config_i,
    
    input [data_bits_p - 1 : 0] data_o
   );

   logic [data_bits_p - 1 : 0] data_o_r, data_o_n;

   assign data_o_n = data_o;
   always @ (posedge clk_dst_i) begin
     data_o_r <= data_o_n;
   end

   // Since the design is synchronized to posedge of clk, using negedge clk
   // here is to allow all flip-flops become stable in the register connected
   // to data_o. This might guarantee simulation correct even at gate level,
   // when all flip-flops don't necessarily change at the same time.
   int data_ref_idx = 0;
   int errors = 0;
   always @ (negedge clk_dst_i) begin
     if(data_ref_idx == 0) begin
       if (data_o === data_ref_p[0]) begin
         $display("  @time %0d: \t output data_o_%0d\t reset   to %b", $time, id_p, data_o);
         data_ref_idx += 1;
       end
     end else begin
       if (data_o !== data_o_r) begin
         $display("  @time %0d: \t output data_o_%0d\t changed to %b", $time, id_p, data_o);
         if (data_o !== data_ref_p[data_ref_idx]) begin
           $display("  @time %0d: \t ERROR output data_o_%0d = %b <-> expected = %b", $time, id_p, data_o, data_ref_p[data_ref_idx]);
           errors += 1;
         end
         data_ref_idx += 1;
       end
     end
   end

   final begin
     if(data_ref_idx == 0) begin
       $display(" !FAIL: Config node %5d has not reset properly!", id_p);
     end else begin
       if (errors != 0) begin
         $display(" !FAIL: Config node %5d has received at least %0d wrong packet(s)!", id_p, errors);
       end else if (data_ref_idx < data_ref_len_p) begin
         $display(" !FAIL: Config node %5d has missed at least %0d packet(s)!", id_p, data_ref_len_p - data_ref_idx);
       end else if (data_ref_idx > data_ref_len_p) begin
         $display(" !FAIL: Config node %5d has received at least %0d more packet(s)!", id_p, data_ref_idx - data_ref_len_p);
       end else begin
         $display("  PASS: Config node %5d is probably working properly.", id_p);
       end
     end
   end

endmodule