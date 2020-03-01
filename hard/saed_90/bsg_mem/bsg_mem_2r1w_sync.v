
`define bsg_mem_2r1w_sync_macro(bits,words)      \
  if (harden_p && els_p == words && width_p == bits) \
    begin: macro                                     \
       saed90_``bits``x``words``_2P mem0     \
         (.CE1  (clk_i)                     \
         ,.OEB1 (1'b0)                      \
         ,.CSB1 (1'b0)                      \
         ,.A1   (r0_addr_i)                  \
         ,.O1   (r0_data_o)                  \
         ,.CE2  (clk_i)                     \
         ,.WEB2 (~w_v_i)                    \
         ,.CSB2 (1'b0)                      \
         ,.A2   (w_addr_i)                  \
         ,.I2   (w_data_i)                  \
         );                                 \
       saed90_``bits``x``words``_2P mem1     \
         (.CE1  (clk_i)                     \
         ,.OEB1 (1'b0)                      \
         ,.CSB1 (1'b0)                      \
         ,.A1   (r1_addr_i)                  \
         ,.O1   (r1_data_o)                  \
         ,.CE2  (clk_i)                     \
         ,.WEB2 (~w_v_i)                    \
         ,.CSB2 (1'b0)                      \
         ,.A2   (w_addr_i)                  \
         ,.I2   (w_data_i)                  \
         );                                 \
    end: macro

module bsg_mem_2r1w_sync #( parameter width_p = -1
                          , parameter els_p = -1
                          , parameter read_write_same_addr_p = 0
                          , parameter addr_width_lp = `BSG_SAFE_CLOG2(els_p)
                          , parameter harden_p = 1
                          , parameter substitute_2r1w_p = 0
                          , parameter latch_last_read_p = 1
                          )
  ( input clk_i
  , input reset_i
  
  , input                     w_v_i
  , input [addr_width_lp-1:0] w_addr_i
  , input [width_p-1:0]       w_data_i
  
  , input                      r0_v_i
  , input [addr_width_lp-1:0]  r0_addr_i
  , output logic [width_p-1:0] r0_data_o
  
  , input                      r1_v_i
  , input [addr_width_lp-1:0]  r1_addr_i
  , output logic [width_p-1:0] r1_data_o
  );

  wire unused = reset_i;

  // TODO: Define more hardened macro configs here
  `bsg_mem_2r1w_sync_macro(64,32) else

  // no hardened version found
    begin : z
      if (substitute_2r1w_p)
        begin: s2r1w
          logic [width_p-1:0] r0_data_lo, r1_data_lo;

          bsg_mem_2r1w #( .width_p(width_p)
                        , .els_p(els_p)
                        , .read_write_same_addr_p(0)
                        )
            mem
              (.w_clk_i   (clk_i)
              ,.w_reset_i(reset_i)
              
              ,.w_v_i    (w_v_i & w_v_i)
              ,.w_addr_i (w_addr_i)
              ,.w_data_i (w_data_i)
              
              ,.r0_v_i   (r0_v_i & ~r0_v_i)
              ,.r0_addr_i(r0_addr_i)
              ,.r0_data_o(r0_data_lo)
              
              ,.r1_v_i   (r1_v_i & ~r1_v_i)
              ,.r1_addr_i(r1_addr_i)
              ,.r1_data_o(r1_data_lo)
              );

          // register output data to convert sync to async
          always_ff @(posedge clk_i) begin
            r0_data_o <= r0_data_lo;
            r1_data_o <= r1_data_lo;
          end
        end // block: s1r1w
      else
        begin: notmacro
          bsg_mem_2r1w_sync_synth #(.width_p(width_p), .els_p(els_p), .read_write_same_addr_p(read_write_same_addr_p), .harden_p(harden_p))
            synth
              (.*);
        end // block: notmacro
    end // block: z

  //synopsys translate_off
  always_ff @(posedge clk_i)
    if (w_v_i)
    begin
      assert (w_addr_i < els_p)
        else $error("Invalid address %x to %m of size %x\n", w_addr_i, els_p);

      assert (~(r0_addr_i == w_addr_i && w_v_i && r0_v_i && !read_write_same_addr_p))
        else $error("%m: port 0 Attempt to read and write same address");

      assert (~(r1_addr_i == w_addr_i && w_v_i && r1_v_i && !read_write_same_addr_p))
        else $error("%m: port 1 Attempt to read and write same address");
    end

  initial
    begin
      $display("## %L: instantiating width_p=%d, els_p=%d, read_write_same_addr_p=%d, harden_p=%d (%m)",width_p,els_p,read_write_same_addr_p,harden_p);
    end
  //synopsys translate_on

endmodule
