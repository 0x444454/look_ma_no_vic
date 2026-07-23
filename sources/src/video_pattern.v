/// This module handles video output values.
/// This includes our demo image, plus sync and blanking levels.
module video_pattern (
  input  wire       clk,
  input  wire       frame_start,
  input  wire       active,
  input  wire       in_sync,
  input  wire [9:0] x,
  input  wire [8:0] y,
  output reg  [7:0] r,
  output reg  [7:0] g,
  output reg  [7:0] b,
  output reg        image_active
);


  localparam integer IMG_LINES  = 200;
  localparam integer BORDER_TOP = 20;

  wire in_img_y = (y >= BORDER_TOP) && (y < (BORDER_TOP + IMG_LINES));
  wire img_active_now = active && in_img_y;
  wire [8:0] y_img = y - BORDER_TOP;

  localparam integer BG_ZCX = 360;
  localparam integer BG_ZCY = 100;
  reg [31:0] inv_bzx_16p16 = 32'h00008000;
  reg [31:0] inv_bzy_16p16 = 32'h00010000;
  reg [8:0]  zoom_phase = 9'd0;
  reg [7:0]  zoom_t;
  reg [31:0] zoom_dx;
  reg [31:0] zoom_dy;
  reg [15:0] zoom_x_new;
  reg [15:0] zoom_y_new;
  reg [31:0] inv_x_new;
  reg [31:0] inv_y_new;

  always @(posedge clk) begin
    if (frame_start) begin
      zoom_phase <= zoom_phase + 9'd1;
      if (zoom_phase[8] == 1'b0) zoom_t = zoom_phase[7:0];
      else                       zoom_t = 8'hFF - zoom_phase[7:0];
      zoom_dx    = (32'h00000600 * zoom_t) / 8'd255;
      zoom_dy    = (32'h00000300 * zoom_t) / 8'd255;
      zoom_x_new = 16'h0200 + zoom_dx[15:0];
      zoom_y_new = 16'h0100 + zoom_dy[15:0];
      inv_x_new  = 32'd16777216 / zoom_x_new;
      inv_y_new  = 32'd16777216 / zoom_y_new;
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

  wire [31:0] x_char_fp = {x[9:4], x[3:0], 12'd0};
  wire [15:0] y_char_fp = {y_img[8:3], y_img[2:0], 5'd0};
  wire [5:0] cx = x_char_fp[31:16];
  wire [4:0] cy = y_char_fp[15:8];
  wire [2:0] font_x = x_char_fp[15:13];
  wire [2:0] font_y = y_img[2:0];

  wire [7:0] char_code_raw;
  screen_matrix u_scr (.cx(cx), .cy(cy), .code(char_code_raw));
  wire [7:0] char_code = (char_code_raw >= 8'd65 && char_code_raw <= 8'd90) ?
                         (char_code_raw + 8'd32) : char_code_raw;
  wire [10:0] font_addr = {char_code, 3'b000} + {8'd0, font_y};
  wire [7:0] font_row;
  c64_font_rom u_font (.addr(font_addr), .data(font_row));
  wire font_bit = font_row[7 - font_x];
  wire [7:0] base_pix = font_bit ? 8'hFF : luma_bg;

  wire scroll_on;
  scroller u_scroll (
    .clk(clk), .frame_start(frame_start), .en(img_active_now && !in_sync),
    .x(x), .y(y_img), .pix_on(scroll_on)
  );

  localparam [7:0] BLANK_CODE = 8'd96;

  always @(posedge clk) begin
    image_active <= img_active_now;

    if (in_sync) begin
      // H-sync pulse.
      r <= 8'd0;
      g <= 8'd0;
      b <= 8'd0;
    end else if (img_active_now) begin
      if (scroll_on) begin
        // Text (scroller and messages) is white.
        r <= 8'hFF;
        g <= 8'hFF;
        b <= 8'hFF;
      end else begin
        // Background zooming gfx pattern.
        // This is a grayscale demo, so set RGB all to the same value.
        r <= base_pix;
        g <= base_pix;
        b <= base_pix;
      end
    end else begin
      // Blanking.
      r <= BLANK_CODE;
      g <= BLANK_CODE;
      b <= BLANK_CODE;
    end
  end
endmodule
