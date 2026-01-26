# IKAOPLL
YM2413 Verilog core for FPGA implementation. It was reverse-engineered with only Yamaha's datasheet and die shots from Madov and Travis Goodspeed. The 9-bit digital output design and the VRC7 patch was copied from [nukeykt](https://github.com/nukeykt)'s [source](https://github.com/nukeykt/Nuked-SMS-FPGA/blob/main/ym2413.v). © 2024 Sehyeon Kim(Raki) 

<p align=center><img alt="header image" src="./docs/ikamusume_dx7.jpg" height="auto" width="640"></p>

Copyrighted work. Permitted to be used as the header image. Painted by [SEONGSU](https://twitter.com/seongsu_twit).

日本語版READMEは[こちら](README_ja.md)

## Features
* A **cycle-accurate, die shot based, BSD2 licensed** core.
* Accurately emulates most signals of the actual chip.
* Three digital outputs available.
* All LSI test bits are implemented.
* Easy-to-use, **built-in 16-bit accumulated output and mixer**, eliminating the need of external LPF.

## Module instantiation
The steps below show how to instantiate the IKAOPLL module in Verilog:

1. Download this repository or add it as a submodule to your project.
2. You can use the Verilog snippet below to instantiate the module.

```verilog
//Verilog module instantiation example
IKAOPLL #(
    .FULLY_SYNCHRONOUS          (1                          ),
    .FAST_RESET                 (1                          ),
    .ALTPATCH_CONFIG_MODE       (0                          ),
    .USE_PIPELINED_MULTIPLIER   (1                          )
) main (
    .i_XIN_EMUCLK               (                           ),
    .o_XOUT                     (                           ),

    .i_phiM_PCEN_n              (                           ),

    .i_IC_n                     (                           ),

    .i_ALTPATCH_EN              (                           ),

    .i_CS_n                     (                           ),
    .i_WR_n                     (                           ),
    .i_A0                       (                           ),

    .i_D                        (                           ),
    .o_D                        (                           ),
    .o_D_OE                     (                           ),

    .o_DAC_EN_MO                (                           ),
    .o_DAC_EN_RO                (                           ),
    .o_IMP_NOFLUC_SIGN          (                           ),
    .o_IMP_NOFLUC_MAG           (                           ),
    .o_IMP_FLUC_SIGNED_MO       (                           ),
    .o_IMP_FLUC_SIGNED_RO       (                           ),
    .i_ACC_SIGNED_MOVOL         (5'sd2                      ),
    .i_ACC_SIGNED_ROVOL         (5'sd3                      ),
    .o_ACC_SIGNED_STRB          (                           ),
    .o_ACC_SIGNED               (                           )
);
```
3. Attach your signals to the port. The direction and the polarity of the signals are described in the port names. The section below explains what the signals mean.


**PARAMETERS**
* `FULLY_SYNCHRONOUS` **1** makes the entire module synchronized(default, recommended). A 2-stage synchronizer is added to all asynchronous control signal inputs. Hence, all write operations are delayed by 2 clocks. If **0**, 10 latches are used. There are two unsafe D-latches to emulate an SR-latch for a write request, and an 8-bit D-latch to temporarily store a data bus write value. When using the latches, you must ensure that the enable signals are given the appropriate clock or global attribute. Quartus displays several warnings and treats these signals as GCLK. Because the latch enable signals are considered clocks, the timing analyzer will complain that additional constraints should be added to the bus control signals.
* `FAST_RESET` When set to **0**, assertion of the `i_IC_n` for at least 72 cycles of phiM **should be guaranteed during the operation of `i_EMUCLK` and `i_phiM_PCEN_n`** to ensure reset of all pipelines in the IKAOPLL. If it is **1**, then if `i_IC_n` is logic low, it forces phi1_cen, the internal divided clock enable, to be enabled so that the pipelines reset at the same rate as the `i_EMUCLK`. It takes 18 cycles of phiM to reset the entire chip.
* `ALTPATCH_CONFIG_MODE` When set to **1**, you can use D[4] of test register to swap patches. If the bit is **0** you should provide alternative patch(VRC7) enable signal externally.
* `USE_PIPELINED_MULTIPLIER` Allows the compiler to utilize resources efficiently. The original chip handles addition and multiplication in 1 phi1 cycle.


**PORTS**
* `i_EMUCLK` is your system clock.
* `i_phiM_PCEN_n` is the clock enable(negative logic) for positive edge of the phiM.
* `i_IC_n` is the synchronous reset. To flush every pipelines in the module, IC_n must be kept at zero for at least 72 phiM cycles. Note that while the `i_IC_n` is asserted, the `i_phiM_PCEN_n` must be operating.
* `o_D_OE` is the output enable for FPGA's tri-state I/O driver.
* `o_DAC_EN_MO` and `o_DAC_EN_RO` are used to enable the DAC output on the original chip. 
* `IMP_NOFLUC_SIGN` used to toggle the Vref source select switch of the string DAC on the original chip.
* `o_IMP_NOFLUC_MAG` used to enable a tap switch of string DAC on the original chip, which have a total of 256 taps.
* `o_IMP_FLUC_SIGNED_MO` and `o_IMP_FLUC_SIGNED_RO` are the 9-bit digital outputs of the final sound. Emulates zero-level fluctuation caused by flaws in the original DAC design.
* `o_ACC_SIGNED_STRB` is the strobe signal for the 16-bit accumulated digital output. You can sample data using an external DFFs on the positive edge of this strobe. The duty cycle is 50% fixed.
* `o_ACC_SIGNED` provides 16-bit accumulated digital output. The original DAC outputs the percussion impulses twice, so you can adjust the volume of each channel by providing an signed 5-bit scaling factor. The default values are +2 for the synth, and +3 for the percussion.
