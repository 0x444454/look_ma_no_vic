# look ma no vic
## A C64 Ultimate FPGA demo

This is an experimental FPGA demo for the C64 Ultimate.
Hopefully we'll see better demos than this in the future ;-)

![screenshots](media/look_ma_no_vic-small.jpg)

# REQUIREMENTS

- A Commodore 64 Ultimate.
- Some way to upload the FPGA bitstream (I use Vivado via JTAG).

# IS THIS SAFE ?

Ahem... Relatively :-)  
My C64 Ultimate is still working after two days of experiments.  
Use this at your own risk.  
Note that you will have to reinstall the C64U firmware after uploading a third-party bitstream.  

At the moment, there is no official way to upload third-parties FPGA bitstreams, so I use Vivado 2025.2.  

__IMPORTANT NOTE:__ Power-cycling the C64U after uploading this bitstream will lead to a seemingly bricked machine.  
How to recover:  
- Upload the ![C64U firmware](https://github.com/GideonZ/1541ultimate/blob/master/recovery/u64ii/u64_mk2_artix.bit) via JTAG. This will give you a working C64U environment.
- Run the C64U updater.
- Your machine should be "as new again".

# HOW TO UPLOAD VIA JTAG

[TBD]







