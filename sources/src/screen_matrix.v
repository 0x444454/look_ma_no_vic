// screen_matrix.v
// 45x25 character screen matrix (C64 screen codes).
// This covers our 360x200 lo-res pixels screen.
//
// Default contents:
//   - Filled with SPACE (screen code 32)
//   - Row 1 (second from top): centered "**** COMMODORE 64 ULTIMATE ****"
//   - Row 3 (fourth from top): centered "50T FPGA SYSTEM 52160 LOGIC CELLS FREE"
//
// IMPORTANT:
//   This file stores C64 screen codes (not PETSCII, not ASCII).
//   - Alphabetics: 'A' = 1, 'B' = 2, ... 'Z' = 26.
//   - Space is code 32.

module screen_matrix (
  input  wire [5:0] cx,   // 0..44
  input  wire [4:0] cy,   // 0..24
  output wire [7:0] code
);

  localparam integer W = 45;
  localparam integer H = 25;
  localparam integer N = W*H; // 1125

  reg [7:0] mem [0:N-1];

  integer i;
  integer idx;

  initial begin
    // Fill with spaces (code 32)
    for (i = 0; i < N; i = i + 1) begin
      mem[i] = 8'd32;
    end

    // Row 1 message
    idx = (1*W) + 7;
    mem[idx +  0] = 8'd42;
    mem[idx +  1] = 8'd42;
    mem[idx +  2] = 8'd42;
    mem[idx +  3] = 8'd42;
    mem[idx +  4] = 8'd32;
    mem[idx +  5] = 8'd3;
    mem[idx +  6] = 8'd15;
    mem[idx +  7] = 8'd13;
    mem[idx +  8] = 8'd13;
    mem[idx +  9] = 8'd15;
    mem[idx + 10] = 8'd4;
    mem[idx + 11] = 8'd15;
    mem[idx + 12] = 8'd18;
    mem[idx + 13] = 8'd5;
    mem[idx + 14] = 8'd32;
    mem[idx + 15] = 8'd54;
    mem[idx + 16] = 8'd52;
    mem[idx + 17] = 8'd32;
    mem[idx + 18] = 8'd21;
    mem[idx + 19] = 8'd12;
    mem[idx + 20] = 8'd20;
    mem[idx + 21] = 8'd9;
    mem[idx + 22] = 8'd13;
    mem[idx + 23] = 8'd1;
    mem[idx + 24] = 8'd20;
    mem[idx + 25] = 8'd5;
    mem[idx + 26] = 8'd32;
    mem[idx + 27] = 8'd42;
    mem[idx + 28] = 8'd42;
    mem[idx + 29] = 8'd42;
    mem[idx + 30] = 8'd42;

    // Row 3 message
    idx = (3*W) + 3;
    mem[idx +  0] = 8'd53;
    mem[idx +  1] = 8'd48;
    mem[idx +  2] = 8'd20;
    mem[idx +  3] = 8'd32;
    mem[idx +  4] = 8'd6;
    mem[idx +  5] = 8'd16;
    mem[idx +  6] = 8'd7;
    mem[idx +  7] = 8'd1;
    mem[idx +  8] = 8'd32;
    mem[idx +  9] = 8'd19;
    mem[idx + 10] = 8'd25;
    mem[idx + 11] = 8'd19;
    mem[idx + 12] = 8'd20;
    mem[idx + 13] = 8'd5;
    mem[idx + 14] = 8'd13;
    mem[idx + 15] = 8'd32;
    mem[idx + 16] = 8'd53;
    mem[idx + 17] = 8'd50;
    mem[idx + 18] = 8'd49;
    mem[idx + 19] = 8'd54;
    mem[idx + 20] = 8'd48;
    mem[idx + 21] = 8'd32;
    mem[idx + 22] = 8'd12;
    mem[idx + 23] = 8'd15;
    mem[idx + 24] = 8'd7;
    mem[idx + 25] = 8'd9;
    mem[idx + 26] = 8'd3;
    mem[idx + 27] = 8'd32;
    mem[idx + 28] = 8'd3;
    mem[idx + 29] = 8'd5;
    mem[idx + 30] = 8'd12;
    mem[idx + 31] = 8'd12;
    mem[idx + 32] = 8'd19;
    mem[idx + 33] = 8'd32;
    mem[idx + 34] = 8'd6;
    mem[idx + 35] = 8'd18;
    mem[idx + 36] = 8'd5;
    mem[idx + 37] = 8'd5;

  end

  // idx = cy*45 + cx = (cy<<5) + (cy<<3) + (cy<<2) + cy + cx
  wire [10:0] idx_rd = ( {6'd0, cy} << 5 ) +
                       ( {6'd0, cy} << 3 ) +
                       ( {6'd0, cy} << 2 ) +
                       ( {6'd0, cy} ) +
                       {5'd0, cx};

  assign code = mem[idx_rd];

endmodule
