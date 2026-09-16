module video_timing (
  input  wire       clk,
  output wire       csync_n,
  output wire       in_sync,
  output wire       active,
  output wire       burst_active,
  output wire       line_odd,
  output wire [9:0] x,
  output wire [8:0] y,
  output wire       frame_start
);

  // PAL-like progressive 288p timing at the standard 13.5 MHz sampling rate.
  //
  // STRICTLY NON-INTERLACED:
  //   - fixed 312 lines per frame
  //   - no half-line timing
  //   - no 312/313 line alternation
  //   - no interlace/equalizing pulse sequence
  //
  // 864 samples * (1 / 13.5 MHz) = 64.000 us
  // horizontal frequency         = 15.625 kHz exactly
  // frame rate                   = 15,625 / 312
  //                              = 50.080128 Hz
  //
  // Horizontal timing:
  //   sync       64 samples = 4.741 us
  //   back porch 76 samples = 5.630 us
  //   active    704 samples = 52.148 us
  //   front      20 samples = 1.481 us
  localparam integer H_TOTAL  = 864;
  localparam integer H_SYNC   = 64;
  localparam integer H_BP     = 76;
  localparam integer H_ACTIVE = 704;

  localparam integer V_TOTAL  = 312;
  localparam integer V_VSYNC  = 3;
  // Add four lines of vertical back porch before active video.  The image
  // therefore starts four lines lower without changing sync timing.
  localparam integer V_BP     = 20;
  localparam integer V_ACTIVE = 288;

  localparam integer H_ACT_START = H_SYNC + H_BP;
  localparam integer H_ACT_END   = H_ACT_START + H_ACTIVE;
  localparam integer V_ACT_START = V_VSYNC + V_BP;
  localparam integer V_ACT_END   = V_ACT_START + V_ACTIVE;

  // Progressive vertical sync uses three broad pulses, one per whole line.
  // This is intentionally simple and non-interlaced.
  localparam integer PULSE_BROAD = 369;  // 27.333 us at 13.5 MHz

  // PAL colour burst:
  // starts 12 samples (~0.889 us) after the trailing edge of H sync
  // lasts 30 samples = 2.222 us (~9.85 subcarrier cycles)
  localparam integer BURST_START = H_SYNC + 12;
  localparam integer BURST_END   = BURST_START + 30;

  reg [9:0] hc = 10'd0;
  reg [8:0] vc = 9'd0;

  always @(posedge clk) begin
    if (hc == H_TOTAL-1) begin
      hc <= 10'd0;
      if (vc == V_TOTAL-1)
        vc <= 9'd0;
      else
        vc <= vc + 9'd1;
    end else begin
      hc <= hc + 10'd1;
    end
  end

  assign frame_start = (hc == 10'd0) && (vc == 9'd0);

  // Used for PAL line-by-line phase alternation.
  assign line_odd = vc[0];

  wire in_vsync_lines = (vc < V_VSYNC);
  wire [9:0] sync_width =
      in_vsync_lines ? PULSE_BROAD[9:0] : H_SYNC[9:0];

  assign in_sync = (hc < sync_width);
  assign csync_n = ~in_sync;

  // No colour burst during the broad progressive vertical-sync lines.
  assign burst_active = !in_vsync_lines &&
                        (hc >= BURST_START) &&
                        (hc < BURST_END);

  wire h_active = (hc >= H_ACT_START) && (hc < H_ACT_END);
  wire v_active = (vc >= V_ACT_START) && (vc < V_ACT_END);

  assign active = h_active & v_active;

  wire [9:0] h_active_pos = hc - H_ACT_START;
  assign x = h_active ? h_active_pos : 10'd0;

  assign y = v_active ? (vc - V_ACT_START) : 9'd0;

endmodule
