// "Look Ma No VIC" - An example prototypal FPGA demo for the C64 Ultimate.
//
// https://github.com/0x444454/look_ma_no_vic
//
// Use Xilinx Vivado 2025.2 to build.
//
// Revision history [authors in square brackets]:
//   2026-02-29: First version. [DDT]
//   2026-09-15: AVID changed from monochrome RGB to PAL-like S-Video Y/C.
//               Added:
//                 AVID_R = Composite
//                 AVID_G = Luma   (S-Video)
//                 AVID_B = Chroma (S-Video)
//               Chroma/DAC clock raised to 54 MHz; 13.5 MHz luma timing preserved.
//               PAL timing/porches/burst should be "more standard".
//
module top (
  input  wire        RMII_REFCLK,
  output wire        LED_BOARDn,
  output wire        CLOCK_C64_SYNTH,
  output wire        AVID_CLK,
  output wire        AVID_SYNCn,
  output wire        AVID_FB,
  output wire [9:2]  AVID_R,
  output wire [9:2]  AVID_G,
  output wire [9:2]  AVID_B
);

  assign CLOCK_C64_SYNTH = 1'b1;

  wire rmii_i;
  wire clk_rmii;
  IBUFG u_ibufg_rmii (.I(RMII_REFCLK), .O(rmii_i));
  BUFG  u_bufg_rmii  (.I(rmii_i), .O(clk_rmii));

  wire clk_pix;
  clock_gen_rmii_to_13m5 u_clk (
    .clk_in(clk_rmii),
    .clk_pix(clk_pix)
  );

  // One 13.5 MHz clock drives video timing, chroma generation and the THS8136 DAC interface.
  assign AVID_CLK = clk_pix;

  wire        csync_n;
  wire        active;
  wire        in_sync;
  wire        burst_active;
  wire        line_odd;
  wire [9:0]  x;
  wire [8:0]  y;
  wire        frame_start;

  video_timing u_timing (
    .clk(clk_pix),
    .csync_n(csync_n),
    .in_sync(in_sync),
    .active(active),
    .burst_active(burst_active),
    .line_odd(line_odd),
    .x(x),
    .y(y),
    .frame_start(frame_start)
  );

  wire [7:0] video_luma;
  wire [7:0] video_chroma;
  wire       image_active;

  video_pattern u_pattern (
    .clk(clk_pix),
    .frame_start(frame_start),
    .active(active),
    .in_sync(in_sync),
    .burst_active(burst_active),
    .line_odd(line_odd),
    .x(x),
    .y(y),
    .luma(video_luma),
    .chroma(video_chroma),
    .image_active(image_active)
  );

  reg sync_q = 1'b1;
  always @(posedge clk_pix) begin
    sync_q <= csync_n;
  end

  assign AVID_SYNCn = sync_q;

  // Keep the DAC enabled during active picture and during the chroma-burst window.
  assign AVID_FB = image_active | burst_active;

  // S-Video + composite mapping using the existing AVID DAC channels:
  //   G output -> Y (luma + sync)
  //   B output -> C (PAL-like chroma, centered on 128)
  //   R output -> composite Y+C, saturated to the 8-bit DAC range
  //
  // Chroma is represented as an unsigned 8-bit value centered on 128, so convert it back to a signed excursion before adding it to Luma.
  wire signed [10:0] composite_sum =
      $signed({3'b000, video_luma}) +
      ($signed({3'b000, video_chroma}) - 11'sd128);

  wire [7:0] video_composite =
      (composite_sum < 11'sd0)   ? 8'h00 :
      (composite_sum > 11'sd255) ? 8'hFF :
                                   composite_sum[7:0];

  reg [7:0] avid_r_q = 8'd0;
  reg [7:0] avid_g_q = 8'd0;
  reg [7:0] avid_b_q = 8'd128;

  always @(posedge clk_pix) begin
    avid_r_q <= video_composite;
    avid_g_q <= video_luma;
    avid_b_q <= video_chroma;
  end

  assign AVID_R = avid_r_q;
  assign AVID_G = avid_g_q;
  assign AVID_B = avid_b_q;

  // Simple board-alive indication from the known-good RMII clock.
  reg [25:0] led_div = 26'd0;
  always @(posedge clk_rmii) begin
    led_div <= led_div + 26'd1;
  end
  assign LED_BOARDn = led_div[24];

endmodule
