module c64_font_rom(
    input  logic [10:0] addr,  // 0..2047 = 256 chars * 8 rows
    output logic [7:0]  data
);
    // 2KB (256*8) uppercase/graphics charset from C64 chargen ROM (first half of 4KB ROM).
    logic [7:0] mem [0:2047];

    initial begin
        // Keep this hex file in the Vivado project "src" directory.
        $readmemh("c64_chargen_ucg.hex", mem);
    end

    assign data = mem[addr];
endmodule
