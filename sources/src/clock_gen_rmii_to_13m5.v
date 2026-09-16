module clock_gen_rmii_to_13m5 (
  input  wire clk_in,
  output wire clk_pix
);

  // Generate the single 13.5 MHz clock used by video timing, chroma and the DAC interface.
  wire clkfb_pix;
  wire clk_pix_mmcm;

  MMCME2_BASE #(
    .BANDWIDTH("OPTIMIZED"),
    .CLKIN1_PERIOD(20.000),
    .DIVCLK_DIVIDE(2),
    .CLKFBOUT_MULT_F(27.000),
    .CLKFBOUT_PHASE(0.000),

    // 50 MHz input -> 675 MHz VCO -> 13.5 MHz video clock.
    .CLKOUT0_DIVIDE_F(50.000),
    .CLKOUT0_PHASE(0.000),
    .CLKOUT0_DUTY_CYCLE(0.500),

    .STARTUP_WAIT("FALSE")
  ) u_mmcm_pix (
    .CLKIN1(clk_in),
    .CLKFBIN(clkfb_pix),
    .CLKFBOUT(clkfb_pix),
    .CLKOUT0(clk_pix_mmcm),
    .PWRDWN(1'b0),
    .RST(1'b0)
  );

  BUFG u_bufg_pix (.I(clk_pix_mmcm), .O(clk_pix));
endmodule
