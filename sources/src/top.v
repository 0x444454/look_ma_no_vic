// "Look Ma No VIC" - An example prototypal FPGA demo for the C64 Ultimate.
//
// https://github.com/0x444454/look_ma_no_vic
//
// Use Xilinx Vivado 2025.2 to build.
//
// Revision history [authors in square brackets]:
//   2026-02-29: First version. [DDT]
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
  wire mmcm_locked;
  clock_gen_rmii_to_13m5 u_clk (
    .clk_in(clk_rmii),
    .clk_pix(clk_pix),
    .locked(mmcm_locked)
  );

  assign AVID_CLK = clk_pix;

  wire        csync_n;
  wire        hsync_unused;
  wire        vsync_unused;
  wire        active;
  wire        in_sync;
  wire        in_blank_unused;
  wire [9:0]  x;
  wire [8:0]  y;
  wire        frame_start;

  video_timing u_timing (
    .clk(clk_pix),
    .csync_n(csync_n),
    .hsync(hsync_unused),
    .vsync(vsync_unused),
    .in_sync(in_sync),
    .in_blank(in_blank_unused),
    .active(active),
    .x(x),
    .y(y),
    .frame_start(frame_start)
  );

  wire [7:0] video_r;
  wire [7:0] video_g;
  wire [7:0] video_b;
  wire       image_active;

  video_pattern u_pattern (
    .clk(clk_pix),
    .frame_start(frame_start),
    .active(active),
    .in_sync(in_sync),
    .x(x),
    .y(y),
    .r(video_r),
    .g(video_g),
    .b(video_b),
    .image_active(image_active)
  );

  reg sync_q = 1'b1;
  always @(posedge clk_pix) begin
    sync_q <= csync_n;
  end

  assign AVID_SYNCn = sync_q;
  assign AVID_FB    = image_active;
  assign AVID_R     = video_r;
  assign AVID_G     = video_g;
  assign AVID_B     = video_b;

  // Simple board-alive indication from the known-good RMII clock.
  reg [25:0] led_div = 26'd0;
  always @(posedge clk_rmii) begin
    led_div <= led_div + 26'd1;
  end
  assign LED_BOARDn = led_div[24];

endmodule
