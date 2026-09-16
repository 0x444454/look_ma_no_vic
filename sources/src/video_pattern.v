/// This module handles S-Video output values.
///
module video_pattern (
  input  wire       clk,       // 13.5 MHz timing, luma, chroma and DAC clock
  input  wire       frame_start,
  input  wire       active,
  input  wire       in_sync,
  input  wire       burst_active,
  input  wire       line_odd,
  input  wire [9:0] x,
  input  wire [8:0] y,
  output reg  [7:0] luma,
  output reg  [7:0] chroma,
  output reg        image_active
);

  localparam integer IMG_LINES  = 200;
  localparam integer BORDER_TOP = 20;

  wire in_img_y = (y >= BORDER_TOP) && (y < (BORDER_TOP + IMG_LINES));
  wire img_active_now = active && in_img_y;
  wire [8:0] y_img = y - BORDER_TOP;

  // -------------------------------------------------------------------------
  // Existing monochrome background zoom effect.
  // This continues to provide Luma exactly as in the previous demo version.
  // -------------------------------------------------------------------------
  localparam integer BG_ZCX = 352;
  localparam integer BG_ZCY = 100;
  reg [31:0] inv_bzx_16p16 = 32'h00008000;
  reg [31:0] inv_bzy_16p16 = 32'h00010000;
  reg [8:0]  zoom_phase = 9'd0;

  // These values are combinational calculations from the current zoom phase; only inverse zoom factors.
  wire [7:0] zoom_t = zoom_phase[8] ? (8'hFF - zoom_phase[7:0]) : zoom_phase[7:0];
  wire [31:0] zoom_dx = (32'h00000600 * zoom_t) / 8'd255;
  wire [31:0] zoom_dy = (32'h00000300 * zoom_t) / 8'd255;
  wire [15:0] zoom_x_new = 16'h0200 + zoom_dx[15:0];
  wire [15:0] zoom_y_new = 16'h0100 + zoom_dy[15:0];
  wire [31:0] inv_x_new = 32'd16777216 / zoom_x_new;
  wire [31:0] inv_y_new = 32'd16777216 / zoom_y_new;

  always @(posedge clk) begin
    if (frame_start) begin
      zoom_phase <= zoom_phase + 9'd1;
      inv_bzx_16p16 <= inv_x_new;
      inv_bzy_16p16 <= inv_y_new;
    end
  end

  wire signed [11:0] bg_dx = $signed({1'b0, x}) - $signed(BG_ZCX[11:0]);
  wire signed [11:0] bg_dy = $signed({1'b0, y_img}) - $signed(BG_ZCY[11:0]);
  wire signed [43:0] bg_dx_mul = bg_dx * $signed(inv_bzx_16p16);
  wire signed [43:0] bg_dy_mul = bg_dy * $signed(inv_bzy_16p16);
  wire signed [11:0] bg_dx_s = bg_dx_mul >>> 16;
  wire signed [11:0] bg_dy_s = bg_dy_mul >>> 16;
  wire signed [11:0] bg_xs = $signed(BG_ZCX[11:0]) + bg_dx_s;
  wire signed [11:0] bg_ys = $signed(BG_ZCY[11:0]) + bg_dy_s;
  wire signed [11:0] bg_u = bg_xs - $signed(BG_ZCX[11:0]);
  wire signed [11:0] bg_v = bg_ys - $signed(BG_ZCY[11:0]);
  wire [7:0] luma_bg = bg_u[7:0] ^ bg_v[7:0];

  // Chars are 16 output pixels wide and 8 lines high.
  wire [5:0] cx = x[9:4];
  wire [4:0] cy = y_img[7:3];
  wire [2:0] font_x = x[3:1];
  wire [2:0] font_y = y_img[2:0];

  wire [7:0] char_code_raw;
  screen_matrix u_scr (.cx(cx), .cy(cy), .code(char_code_raw));
  wire [7:0] char_code = (char_code_raw >= 8'd65 && char_code_raw <= 8'd90) ?
                         (char_code_raw + 8'd32) : char_code_raw;
  wire [10:0] font_addr = {char_code, font_y};
  wire [7:0] font_row;
  c64_font_rom u_font (.addr(font_addr), .data(font_row));
  wire font_bit = font_row[7 - font_x];
  
  // Clamp the animated background to the lowest Luma floor (i.e. BG_FLOOR).
  localparam [7:0] BG_FLOOR = 8'd16;
  wire [7:0] base_pix = font_bit ? 8'hFF :
                        ((luma_bg < BG_FLOOR) ? BG_FLOOR : luma_bg);

  wire scroll_on;
  scroller u_scroll (
    .clk(clk), .frame_start(frame_start), .en(img_active_now && !in_sync),
    .x(x), .y(y_img), .pix_on(scroll_on)
  );

  // -------------------------------------------------------------------------
  // PAL-like S-Video chroma signal generator.
  // -------------------------------------------------------------------------
  // PAL subcarrier = 4.43361875 MHz.
  // At 13.5 MHz this gives about 3.04 DAC samples per carrier cycle.
  // The 32-bit phase accumulator produces 4,433,618.7488 Hz.
  localparam [31:0] PAL_PHASE_INC = 32'd1410536854;

  reg [31:0] chroma_phase = 32'd0;
  reg [7:0]  hue_anim = 8'd0;

  always @(posedge clk) begin
    chroma_phase <= chroma_phase + PAL_PHASE_INC;
  end

  always @(posedge clk) begin
    if (frame_start)
      hue_anim <= hue_anim + 8'd1;
  end

  function signed [7:0] sine64;
    input [5:0] phase;
    begin
      case (phase)
      6'd 0: sine64 = 8'sd0;
      6'd 1: sine64 = 8'sd12;
      6'd 2: sine64 = 8'sd25;
      6'd 3: sine64 = 8'sd37;
      6'd 4: sine64 = 8'sd49;
      6'd 5: sine64 = 8'sd60;
      6'd 6: sine64 = 8'sd71;
      6'd 7: sine64 = 8'sd81;
      6'd 8: sine64 = 8'sd90;
      6'd 9: sine64 = 8'sd98;
      6'd10: sine64 = 8'sd106;
      6'd11: sine64 = 8'sd112;
      6'd12: sine64 = 8'sd117;
      6'd13: sine64 = 8'sd122;
      6'd14: sine64 = 8'sd125;
      6'd15: sine64 = 8'sd126;
      6'd16: sine64 = 8'sd127;
      6'd17: sine64 = 8'sd126;
      6'd18: sine64 = 8'sd125;
      6'd19: sine64 = 8'sd122;
      6'd20: sine64 = 8'sd117;
      6'd21: sine64 = 8'sd112;
      6'd22: sine64 = 8'sd106;
      6'd23: sine64 = 8'sd98;
      6'd24: sine64 = 8'sd90;
      6'd25: sine64 = 8'sd81;
      6'd26: sine64 = 8'sd71;
      6'd27: sine64 = 8'sd60;
      6'd28: sine64 = 8'sd49;
      6'd29: sine64 = 8'sd37;
      6'd30: sine64 = 8'sd25;
      6'd31: sine64 = 8'sd12;
      6'd32: sine64 = 8'sd0;
      6'd33: sine64 = -8'sd12;
      6'd34: sine64 = -8'sd25;
      6'd35: sine64 = -8'sd37;
      6'd36: sine64 = -8'sd49;
      6'd37: sine64 = -8'sd60;
      6'd38: sine64 = -8'sd71;
      6'd39: sine64 = -8'sd81;
      6'd40: sine64 = -8'sd90;
      6'd41: sine64 = -8'sd98;
      6'd42: sine64 = -8'sd106;
      6'd43: sine64 = -8'sd112;
      6'd44: sine64 = -8'sd117;
      6'd45: sine64 = -8'sd122;
      6'd46: sine64 = -8'sd125;
      6'd47: sine64 = -8'sd126;
      6'd48: sine64 = -8'sd127;
      6'd49: sine64 = -8'sd126;
      6'd50: sine64 = -8'sd125;
      6'd51: sine64 = -8'sd122;
      6'd52: sine64 = -8'sd117;
      6'd53: sine64 = -8'sd112;
      6'd54: sine64 = -8'sd106;
      6'd55: sine64 = -8'sd98;
      6'd56: sine64 = -8'sd90;
      6'd57: sine64 = -8'sd81;
      6'd58: sine64 = -8'sd71;
      6'd59: sine64 = -8'sd60;
      6'd60: sine64 = -8'sd49;
      6'd61: sine64 = -8'sd37;
      6'd62: sine64 = -8'sd25;
      6'd63: sine64 = -8'sd12;
        default: sine64 = 8'sd0;
      endcase
    end
  endfunction

  wire [7:0] carrier_phase = chroma_phase[31:24];

  // One full hue rotation across the 720 hor pixels: floor(x * 256 / 720).
  // Use 91/256 as an approximation of 256/720.
  wire [17:0] hue_mul = x * 18'd91;
  wire [7:0]  hue_x = hue_mul[15:8];
  wire [7:0]  hue_phase = hue_x + hue_anim;

  // PAL phase alternation: reverse the colour-vector phase on alternate lines.
  wire [7:0] active_phase = line_odd ?
                            (carrier_phase - hue_phase) :
                            (carrier_phase + hue_phase);

  wire signed [7:0] active_sine = sine64(active_phase[7:2]);

  localparam [7:0] SATURATION = 8'd44;
  wire signed [16:0] active_prod = $signed(active_sine) *
                                   $signed({1'b0, SATURATION});
  wire signed [16:0] active_scaled = active_prod >>> 7;
  wire signed [17:0] active_chroma_sum = 18'sd128 + active_scaled;
  wire [7:0] chroma_pattern = active_chroma_sum[7:0];

  // PAL swinging burst: alternate roughly +135 / -135 degrees by line.
  wire [7:0] burst_phase = line_odd ?
                           (carrier_phase + 8'd160) :
                           (carrier_phase + 8'd96);
  wire signed [7:0] burst_sine = sine64(burst_phase[7:2]);
  
  // PAL burst is nominally about 300 mV p-p.
  // On a 700-mV full-scale DAC, +/-55 8-bit counts is approximately +/-151 mV.
  wire signed [15:0] burst_prod = $signed(burst_sine) * 9'sd55;
  wire signed [15:0] burst_scaled = burst_prod >>> 7;
  wire signed [16:0] burst_chroma_sum = 17'sd128 + burst_scaled;
  wire [7:0] chroma_burst = burst_chroma_sum[7:0];

  localparam [7:0] BLANK_CODE   = 8'd96;
  localparam [7:0] CHROMA_ZERO  = 8'd128;

  // Luma path is working at 13.5 MHz.
  // AVID_FB is raised during the colour burst. 
  // BLANK controls all THS8136 DACs, so Luma is unblanked at the same time.
  // Luma must output 0 during the burst window.
  always @(posedge clk) begin
    image_active <= img_active_now;

    if (in_sync) begin
      luma <= 8'd0;
    end else if (burst_active) begin
      luma <= 8'd0;
    end else if (img_active_now) begin
      if (scroll_on)
        luma <= 8'hFF;
      else
        luma <= base_pix;
    end else begin
      luma <= BLANK_CODE;
    end
  end

  // Chroma is generated once per 13.5 MHz DAC sample in the same clock domain as the video timing.
  always @(posedge clk) begin
    if (burst_active) begin
      chroma <= chroma_burst;
    end else if (img_active_now && !(scroll_on || font_bit)) begin
      chroma <= chroma_pattern;
    end else begin
      chroma <= CHROMA_ZERO;
    end
  end
endmodule
