# look ma no vic
## A C64 Ultimate FPGA demo

This is an experimental FPGA demo for the C64 Ultimate.  
Hopefully we'll see better demos than this in the future ;-)

![screenshots](media/look_ma_no_vic-small.jpg)

## Demo video:  

[![Demo video](media/look_ma_no_vic-thumbnail.jpg)](media/look_ma_no_vic.mov)

# REQUIREMENTS

- A Commodore 64 Ultimate.
- Some way to upload the FPGA bitstream (I use Vivado 2025.2 via JTAG).

# IS THIS SAFE ?

My C64 Ultimate is still working after two days of experiments.  
However, low level hardware access may cause the machine or peripherals to work in untested or unsupported conditions, especially during "trial and error" experiments.
Use this __at your own risk__.  

Note that [at the moment] there is no official way to upload third-party FPGA bitstreams, so I use Vivado 2025.2.  

__IMPORTANT NOTE:__ Upload your bitstream directly to the FPGA, so Power-cycling the C64U should be enough to restore normal operation. Do __not__ upload to flash or other persistent storage.
How to recover the C64U in case you have issues:  
- Upload the [C64U firmware](https://github.com/GideonZ/1541ultimate/blob/master/recovery/u64ii/u64_mk2_artix.bit) via JTAG. This will give you a working C64U environment until power-off.
- Run the C64U updater.
- Your machine should be restored, and now survive power off.

Anyway, the golden rule is: If unsure, __DO NOT__ run this !!!

# HOW TO UPLOAD VIA JTAG

[TBD]


# LICENSE

Creative Commons, CC BY

https://creativecommons.org/licenses/by/4.0/deed.en

Please add a link to this github project.




