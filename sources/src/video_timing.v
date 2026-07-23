module video_timing (
  input  wire       clk,
  output wire       csync_n,
  output wire       hsync,
  output wire       vsync,
  output wire       in_sync,
  output wire       in_blank,
  output wire       active,
  output wire [9:0] x,
  output wire [8:0] y,
  output wire       frame_start
);

  // PAL-like 288p50 timing using a 13.5 MHz pixel clock.
  localparam integer H_TOTAL  = 864;
  localparam integer H_SYNC   = 64;
  localparam integer H_BP     = 68;
  localparam integer H_ACTIVE = 720;

  localparam integer V_TOTAL  = 312;
  localparam integer V_VSYNC  = 3;
  localparam integer V_BP     = 19;
  localparam integer V_ACTIVE = 288;

  localparam integer H_ACT_START = H_SYNC + H_BP;
  localparam integer H_ACT_END   = H_ACT_START + H_ACTIVE;
  localparam integer V_ACT_START = V_VSYNC + V_BP;
  localparam integer V_ACT_END   = V_ACT_START + V_ACTIVE;

  // Broad composite-sync pulse during the vertical-sync interval.
  localparam integer PULSE_BROAD = 366;

  reg [9:0] hc = 10'd0;
  reg [8:0] vc = 9'd0;

  always @(posedge clk) begin
    if (hc == H_TOTAL-1) begin
      hc <= 10'd0;
      if (vc == V_TOTAL-1) begin
        vc <= 9'd0;
      end else begin
        vc <= vc + 9'd1;
      end
    end else begin
      hc <= hc + 10'd1;
    end
  end

  assign frame_start = (hc == 10'd0) && (vc == 9'd0);

  wire in_vsync_lines = (vc < V_VSYNC);
  wire [9:0] sync_width = in_vsync_lines ? PULSE_BROAD[9:0] : H_SYNC[9:0];

  assign in_sync = (hc < sync_width);
  assign csync_n = ~in_sync;
  assign hsync   = ~(hc < H_SYNC);
  assign vsync   = ~(vc < V_VSYNC);

  wire h_active = (hc >= H_ACT_START) && (hc < H_ACT_END);
  wire v_active = (vc >= V_ACT_START) && (vc < V_ACT_END);

  assign active   = h_active & v_active;
  assign in_blank = ~active;
  assign x = hc - H_ACT_START;
  assign y = vc - V_ACT_START;

endmodule
