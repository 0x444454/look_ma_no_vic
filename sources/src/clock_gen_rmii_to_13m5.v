module clock_gen_rmii_to_13m5 (
  input  wire clk_in,
  output wire clk_pix,
  output wire locked
);

  wire clkfb;
  wire clk_pix_mmcm;

  MMCME2_BASE #(
    .BANDWIDTH("OPTIMIZED"),
    .CLKIN1_PERIOD(20.000),
    .DIVCLK_DIVIDE(2),
    .CLKFBOUT_MULT_F(27.000),
    .CLKFBOUT_PHASE(0.000),

    // 50 MHz input -> 675 MHz VCO -> 13.5 MHz pixel clock.
    .CLKOUT0_DIVIDE_F(50.000),
    .CLKOUT0_PHASE(0.000),
    .CLKOUT0_DUTY_CYCLE(0.500),

    .STARTUP_WAIT("FALSE")
  ) u_mmcm (
    .CLKIN1(clk_in),
    .CLKFBIN(clkfb),
    .CLKFBOUT(clkfb),
    .CLKOUT0(clk_pix_mmcm),
    .LOCKED(locked),
    .PWRDWN(1'b0),
    .RST(1'b0)
  );

  BUFG u_bufg_pix (.I(clk_pix_mmcm), .O(clk_pix));
endmodule
