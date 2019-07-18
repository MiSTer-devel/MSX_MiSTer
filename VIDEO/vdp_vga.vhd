--
--  vdp_vga.vhd
--   VGA up-scan converter.
--
--  Copyright (C) 2006 Kunihiko Ohnaka
--  All rights reserved.
--                                     http://www.ohnaka.jp/ese-vdp/
--
--  ÔøΩ{ÔøΩ\ÔøΩtÔøΩgÔøΩEÔøΩFÔøΩAÔøΩÔøΩÔøΩÔøΩÔøΩ—ñ{ÔøΩ\ÔøΩtÔøΩgÔøΩEÔøΩFÔøΩAÔøΩ…äÔøΩÔøΩ√ÇÔøΩÔøΩƒçÏê¨ÔøΩÔøΩÔøΩÍÇΩÔøΩhÔøΩÔøΩÔøΩÔøΩÔøΩÕÅAÔøΩ»âÔøΩÔøΩÃèÔøΩÔøΩ
--  ÔøΩÔøΩÔøΩÔøΩÔøΩÔøΩÔøΩÍçáÔøΩ…åÔøΩÔøΩÔøΩAÔøΩƒî–ïzÔøΩÔøΩÔøΩÔøΩÔøΩ—égÔøΩpÔøΩÔøΩÔøΩÔøΩÔøΩ¬ÇÔøΩÔøΩÔøΩÔøΩ‹ÇÔøΩÔøΩB
--
--  1.ÔøΩ\ÔøΩ[ÔøΩXÔøΩRÔøΩ[ÔøΩhÔøΩ`ÔøΩÔøΩÔøΩ≈çƒî–ïzÔøΩÔøΩÔøΩÔøΩÔøΩÍçáÔøΩAÔøΩÔøΩÔøΩLÔøΩÃíÔøΩÔøΩÏå†ÔøΩ\ÔøΩÔøΩÔøΩAÔøΩ{ÔøΩÔøΩÍóóÔøΩAÔøΩÔøΩÔøΩÔøΩÔøΩ—âÔøΩÔøΩL
--    ÔøΩ∆ê”èÔøΩÔøΩÃÇ‹Ç‹ÇÃå`ÔøΩ≈ï€éÔøΩÔøΩÔøΩÔøΩÈÇ±ÔøΩ∆ÅB
--  2.ÔøΩoÔøΩCÔøΩiÔøΩÔøΩÔøΩ`ÔøΩÔøΩÔøΩ≈çƒî–ïzÔøΩÔøΩÔøΩÔøΩÔøΩÍçáÔøΩAÔøΩ–ïzÔøΩÔøΩÔøΩ…ïtÔøΩÔøΩÔøΩÃÉhÔøΩLÔøΩÔøΩÔøΩÔøΩÔøΩÔøΩÔøΩgÔøΩÔøΩÔøΩÃéÔøΩÔøΩÔøΩÔøΩ…ÅAÔøΩÔøΩÔøΩLÔøΩÔøΩ
--    ÔøΩÔøΩÔøΩÏå†ÔøΩ\ÔøΩÔøΩÔøΩAÔøΩ{ÔøΩÔøΩÍóóÔøΩAÔøΩÔøΩÔøΩÔøΩÔøΩ—âÔøΩÔøΩLÔøΩ∆ê”èÔøΩÔøΩÔøΩ‹ÇﬂÇÈÇ±ÔøΩ∆ÅB
--  3.ÔøΩÔøΩÔøΩ Ç…ÇÔøΩÔøΩÈéñÔøΩOÔøΩÃãÔøΩÔøΩ¬Ç»ÇÔøΩÔøΩ…ÅAÔøΩ{ÔøΩ\ÔøΩtÔøΩgÔøΩEÔøΩFÔøΩAÔøΩÔøΩÔøΩÃîÔøΩÔøΩAÔøΩÔøΩÔøΩÔøΩÔøΩ—èÔøΩÔøΩ∆ìIÔøΩ»êÔøΩÔøΩiÔøΩ‚äàÔøΩÔøΩ
--    ÔøΩ…égÔøΩpÔøΩÔøΩÔøΩ»ÇÔøΩÔøΩÔøΩÔøΩ∆ÅB
--
--  ÔøΩ{ÔøΩ\ÔøΩtÔøΩgÔøΩEÔøΩFÔøΩAÔøΩÕÅAÔøΩÔøΩÔøΩÏå†ÔøΩ“Ç…ÇÔøΩÔøΩÔøΩƒÅuÔøΩÔøΩÔøΩÔøΩÔøΩÃÇ‹Ç‹ÅvÔøΩÒãüÇÔøΩÔøΩÔøΩÔøΩƒÇÔøΩÔøΩ‹ÇÔøΩÔøΩBÔøΩÔøΩÔøΩÏå†ÔøΩ“ÇÕÅA
--  ÔøΩÔøΩÔøΩÔøΩ⁄ìIÔøΩ÷ÇÃìKÔøΩÔøΩÔøΩÔøΩÔøΩÃï€èÿÅAÔøΩÔøΩÔøΩiÔøΩÔøΩÔøΩÃï€èÿÅAÔøΩ‹ÇÔøΩÔøΩÔøΩÔøΩÔøΩÔøΩ…åÔøΩËÇ≥ÔøΩÔøΩÔøΩ»ÇÔøΩÔøΩAÔøΩÔøΩÔøΩÔøΩÔøΩ»ÇÈñæÔøΩÔøΩ
--  ÔøΩIÔøΩÔøΩÔøΩÔøΩÔøΩÕà√ñŸÇ»ï€èÿê”îCÔøΩÔøΩÔøΩÔøΩÔøΩ‹ÇÔøΩÔøΩÔøΩÔøΩBÔøΩÔøΩÔøΩÏå†ÔøΩ“ÇÕÅAÔøΩÔøΩÔøΩRÔøΩÃÇÔøΩÔøΩÔøΩÔøΩÔøΩÔøΩÔøΩÔøΩÔøΩÔøΩÌÇ∏ÔøΩAÔøΩÔøΩÔøΩQ
--  ÔøΩÔøΩÔøΩÔøΩÔøΩÃåÔøΩÔøΩÔøΩÔøΩÔøΩÔøΩÔøΩÔøΩÔøΩÔøΩÔøΩÌÇ∏ÔøΩAÔøΩÔøΩÔøΩ¬ê”îCÔøΩÃçÔøΩÔøΩÔøΩÔøΩÔøΩÔøΩ_ÔøΩÔøΩÔøΩ≈ÇÔøΩÔøΩÈÇ©ÔøΩÔøΩÔøΩiÔøΩ”îCÔøΩ≈ÇÔøΩÔøΩÈÇ©ÔøΩiÔøΩﬂéÔøΩ
--  ÔøΩÔøΩÔøΩÃëÔøΩÔøΩÃÅjÔøΩsÔøΩ@ÔøΩsÔøΩ◊Ç≈ÇÔøΩÔøΩÈÇ©ÔøΩÔøΩÔøΩÔøΩÔøΩÌÇ∏ÔøΩAÔøΩÔøΩÔøΩ…ÇÔøΩÔøΩÃÇÊÇ§ÔøΩ»ëÔøΩÔøΩQÔøΩÔøΩÔøΩÔøΩÔøΩÔøΩÔøΩÔøΩÔøΩÔøΩÔøΩ¬î\ÔøΩÔøΩÔøΩÔøΩÔøΩmÔøΩÔøΩ
--  ÔøΩÔøΩÔøΩÔøΩÔøΩƒÇÔøΩÔøΩÔøΩÔøΩ∆ÇÔøΩÔøΩƒÇÔøΩÔøΩAÔøΩ{ÔøΩ\ÔøΩtÔøΩgÔøΩEÔøΩFÔøΩAÔøΩÃégÔøΩpÔøΩ…ÇÔøΩÔøΩÔøΩƒîÔøΩÔøΩÔøΩÔøΩÔøΩÔøΩÔøΩÔøΩiÔøΩÔøΩÔøΩ÷ïiÔøΩ‹ÇÔøΩÔøΩÕëÔøΩÔøΩpÔøΩT
--  ÔøΩ[ÔøΩrÔøΩXÔøΩÃíÔøΩÔøΩBÔøΩAÔøΩgÔøΩpÔøΩÃërÔøΩÔøΩÔøΩAÔøΩfÔøΩ[ÔøΩ^ÔøΩÃërÔøΩÔøΩÔøΩAÔøΩÔøΩÔøΩvÔøΩÃërÔøΩÔøΩÔøΩAÔøΩ∆ñÔøΩÔøΩÃíÔøΩÔøΩfÔøΩÔøΩÔøΩ‹ÇﬂÅAÔøΩ‹ÇÔøΩÔøΩÔøΩ
--  ÔøΩÔøΩÔøΩ…åÔøΩËÇ≥ÔøΩÔøΩÔøΩ»ÇÔøΩÔøΩjÔøΩÔøΩÔøΩ⁄ëÔøΩÔøΩQÔøΩAÔøΩ‘ê⁄ëÔøΩÔøΩQÔøΩAÔøΩÔøΩIÔøΩ»ëÔøΩÔøΩQÔøΩAÔøΩÔøΩ ëÔøΩÔøΩQÔøΩAÔøΩÔøΩÔøΩÔøΩÔøΩIÔøΩÔøΩÔøΩQÔøΩAÔøΩÔøΩ
--  ÔøΩÔøΩÔøΩÕåÔøΩÔøΩ ëÔøΩÔøΩQÔøΩ…Ç¬ÇÔøΩÔøΩƒÅAÔøΩÔøΩÔøΩÿê”îCÔøΩïâÇÔøΩÔøΩ»ÇÔøΩÔøΩÔøΩÔøΩÃÇ∆ÇÔøΩÔøΩ‹ÇÔøΩÔøΩB
--
--  Note that above Japanese version license is the formal document.
--  The following translation is only for reference.
--
--  Redistribution and use of this software or any derivative works,
--  are permitted provided that the following conditions are met:
--
--  1. Redistributions of source code must retain the above copyright
--     notice, this list of conditions and the following disclaimer.
--  2. Redistributions in binary form must reproduce the above
--     copyright notice, this list of conditions and the following
--     disclaimer in the documentation and/or other materials
--     provided with the distribution.
--  3. Redistributions may not be sold, nor may they be used in a
--     commercial product or activity without specific prior written
--     permission.
--
--  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
--  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
--  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
--  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
--  COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
--  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
--  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
--  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
--  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
--  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
--  POSSIBILITY OF SUCH DAMAGE.
--
-------------------------------------------------------------------------------
-- Memo
--   Japanese comment lines are starts with "JP:".
--   JP: ì˙ñ{åÍÇÃÉRÉÅÉìÉgçsÇÕ JP:Çì™Ç…ïtÇØÇÈéñÇ…Ç∑ÇÈ
--
-------------------------------------------------------------------------------
-- Revision History
--
-- 3rd,June,2018 modified by KdL
--  - Added a trick to help set a pixel ratio 1:1
--    on an LED display at 60Hz (not guaranteed on all displays)
--
-- 29th,October,2006 modified by Kunihiko Ohnaka
--  - Inserted the license text
--  - Added the document part below
--
-- ??th,August,2006 modified by Kunihiko Ohnaka
--  - Moved the equalization pulse generator from vdp.vhd
--
-- 20th,August,2006 modified by Kunihiko Ohnaka
--  - Changed field mapping algorithm when interlace mode is enabled
--        even field  -> even line (odd  line is black)
--        odd  field  -> odd line  (even line is black)
--
-- 13th,October,2003 created by Kunihiko Ohnaka
-- JP: VDPÇÃÉRÉAÇÃé¿ëïÇ∆ï\é¶ÉfÉoÉCÉXÇ÷ÇÃèoóÕÇï É\Å[ÉXÇ…ÇµÇΩÅD
--
-------------------------------------------------------------------------------
-- Document
--
-- JP: ESE-VDPÉRÉA(vdp.vhd)Ç™ê∂ê¨ÇµÇΩÉrÉfÉIêMçÜÇÅAVGAÉ^ÉCÉ~ÉìÉOÇ…
-- JP: ïœä∑Ç∑ÇÈÉAÉbÉvÉXÉLÉÉÉìÉRÉìÉoÅ[É^Ç≈Ç∑ÅB
-- JP: NTSCÇÕêÖïΩìØä˙é¸îgêîÇ™15.7KHzÅAêÇíºìØä˙é¸îgêîÇ™60HzÇ≈Ç∑Ç™ÅA
-- JP: VGAÇÃêÖïΩìØä˙é¸îgêîÇÕ31.5KHzÅAêÇíºìØä˙é¸îgêîÇÕ60HzÇ≈Ç†ÇËÅA
-- JP: ÉâÉCÉìêîÇæÇØÇ™ÇŸÇ⁄î{Ç…Ç»Ç¡ÇΩÇÊÇ§Ç»É^ÉCÉ~ÉìÉOÇ…Ç»ÇËÇ‹Ç∑ÅB
-- JP: ÇªÇ±Ç≈ÅAvdpÇ ntscÉÇÅ[ÉhÇ≈ìÆÇ©ÇµÅAäeÉâÉCÉìÇî{ÇÃë¨ìxÇ≈
-- JP: ìÒìxï`âÊÇ∑ÇÈÇ±Ç∆Ç≈ÉXÉLÉÉÉìÉRÉìÉoÅ[ÉgÇé¿åªÇµÇƒÇ¢Ç‹Ç∑ÅB
--

LIBRARY IEEE;
    USE IEEE.STD_LOGIC_1164.ALL;
    USE IEEE.STD_LOGIC_UNSIGNED.ALL;
    USE WORK.VDP_PACKAGE.ALL;

ENTITY VDP_VGA IS
    PORT(
        -- VDP CLOCK ... 21.477MHZ
        CLK21M          : IN    STD_LOGIC;
        RESET           : IN    STD_LOGIC;
        -- VIDEO INPUT
        VIDEORIN        : IN    STD_LOGIC_VECTOR( 5 DOWNTO 0);
        VIDEOGIN        : IN    STD_LOGIC_VECTOR( 5 DOWNTO 0);
        VIDEOBIN        : IN    STD_LOGIC_VECTOR( 5 DOWNTO 0);
        VIDEOVSIN_N     : IN    STD_LOGIC;
        HCOUNTERIN      : IN    STD_LOGIC_VECTOR(10 DOWNTO 0);
        VCOUNTERIN      : IN    STD_LOGIC_VECTOR(10 DOWNTO 0);
        -- MODE
        PALMODE         : IN    STD_LOGIC;  -- caro
        INTERLACEMODE   : IN    STD_LOGIC;
        LEGACY_VGA      : IN    STD_LOGIC;
        -- VIDEO OUTPUT
        VIDEOROUT       : OUT   STD_LOGIC_VECTOR( 5 DOWNTO 0);
        VIDEOGOUT       : OUT   STD_LOGIC_VECTOR( 5 DOWNTO 0);
        VIDEOBOUT       : OUT   STD_LOGIC_VECTOR( 5 DOWNTO 0);
        VIDEODEOUT      : OUT   STD_LOGIC;
        VIDEOHSOUT_N    : OUT   STD_LOGIC;
        VIDEOVSOUT_N    : OUT   STD_LOGIC;
        -- SWITCHED I/O SIGNALS
        RATIOMODE       : IN    STD_LOGIC_VECTOR( 2 DOWNTO 0)
    );
END VDP_VGA;

ARCHITECTURE RTL OF VDP_VGA IS
    COMPONENT VDP_DOUBLEBUF
        PORT (
            CLK         : IN    STD_LOGIC;
            XPOSITIONW  : IN    STD_LOGIC_VECTOR(  9 DOWNTO 0 );
            XPOSITIONR  : IN    STD_LOGIC_VECTOR(  9 DOWNTO 0 );
            EVENODD     : IN    STD_LOGIC;
            WE          : IN    STD_LOGIC;
            DATARIN     : IN    STD_LOGIC_VECTOR(  5 DOWNTO 0 );
            DATAGIN     : IN    STD_LOGIC_VECTOR(  5 DOWNTO 0 );
            DATABIN     : IN    STD_LOGIC_VECTOR(  5 DOWNTO 0 );
            DATAROUT    : OUT   STD_LOGIC_VECTOR(  5 DOWNTO 0 );
            DATAGOUT    : OUT   STD_LOGIC_VECTOR(  5 DOWNTO 0 );
            DATABOUT    : OUT   STD_LOGIC_VECTOR(  5 DOWNTO 0 )
        );
    END COMPONENT;

    SIGNAL FF_HSYNC_N       : STD_LOGIC;

    -- VIDEO OUTPUT ENABLE
    SIGNAL VIDEOOUTX        : STD_LOGIC;
    SIGNAL VIDEOOUTY        : STD_LOGIC;

    -- DOUBLE BUFFER SIGNAL
    SIGNAL XPOSITIONW       : STD_LOGIC_VECTOR(  9 DOWNTO 0 );
    SIGNAL XPOSITIONR       : STD_LOGIC_VECTOR(  9 DOWNTO 0 );
    SIGNAL EVENODD          : STD_LOGIC;
    SIGNAL WE_BUF           : STD_LOGIC;
    SIGNAL DATAROUT         : STD_LOGIC_VECTOR(  5 DOWNTO 0 );
    SIGNAL DATAGOUT         : STD_LOGIC_VECTOR(  5 DOWNTO 0 );
    SIGNAL DATABOUT         : STD_LOGIC_VECTOR(  5 DOWNTO 0 );
    SIGNAL DATADEOUT        : STD_LOGIC;

    -- DISP_START_X + DISP_WIDTH < CLOCKS_PER_LINE/2 = 684
    CONSTANT DISP_WIDTH             : INTEGER := 576;
    SHARED VARIABLE DISP_START_X    : INTEGER := 684 - DISP_WIDTH - 2;          -- 106
BEGIN

    VIDEOROUT <= DATAROUT  WHEN VIDEOOUTX = '1' ELSE (OTHERS => '0');
    VIDEOGOUT <= DATAGOUT  WHEN VIDEOOUTX = '1' ELSE (OTHERS => '0');
    VIDEOBOUT <= DATABOUT  WHEN VIDEOOUTX = '1' ELSE (OTHERS => '0');

    DBUF : VDP_DOUBLEBUF
    PORT MAP(
        CLK         => CLK21M,
        XPOSITIONW  => XPOSITIONW,
        XPOSITIONR  => XPOSITIONR,
        EVENODD     => EVENODD,
        WE          => WE_BUF,
        DATARIN     => VIDEORIN,
        DATAGIN     => VIDEOGIN,
        DATABIN     => VIDEOBIN,
        DATAROUT    => DATAROUT,
        DATAGOUT    => DATAGOUT,
        DATABOUT    => DATABOUT
    );

    XPOSITIONW  <=  HCOUNTERIN(10 DOWNTO 1) - (CLOCKS_PER_LINE/2 - DISP_WIDTH - 10);
    EVENODD     <=  VCOUNTERIN(1);
    WE_BUF      <=  '1';

    -- PIXEL RATIO 1:1 FOR LED DISPLAY
    PROCESS( CLK21M )
        CONSTANT DISP_START_Y   : INTEGER := 3;
        CONSTANT PRB_HEIGHT     : INTEGER := 25;
        CONSTANT RIGHT_X        : INTEGER := 684 - DISP_WIDTH - 2;              -- 106
        CONSTANT PAL_RIGHT_X    : INTEGER := 87;                                -- 87
        CONSTANT CENTER_X       : INTEGER := RIGHT_X - 32 - 2;                  -- 72
        CONSTANT BASE_LEFT_X    : INTEGER := CENTER_X - 32 - 2 - 3;             -- 35
    BEGIN
        IF( CLK21M'EVENT AND CLK21M = '1' )THEN
            IF( (RATIOMODE = "000" OR INTERLACEMODE = '1' OR PALMODE = '1') AND LEGACY_VGA = '1' )THEN
                -- LEGACY OUTPUT
                DISP_START_X := RIGHT_X;                                        -- 106
            ELSIF( PALMODE = '1' )THEN
                -- 50HZ
                DISP_START_X := PAL_RIGHT_X;                                    -- 87
            ELSIF( RATIOMODE = "000" OR INTERLACEMODE = '1' )THEN
                -- 60HZ
                DISP_START_X := CENTER_X;                                       -- 72
            ELSIF( (VCOUNTERIN < 38 + DISP_START_Y + PRB_HEIGHT) OR
                   (VCOUNTERIN > 526 - PRB_HEIGHT AND VCOUNTERIN < 526 ) OR
                   (VCOUNTERIN > 524 + 38 + DISP_START_Y AND VCOUNTERIN < 524 + 38 + DISP_START_Y + PRB_HEIGHT) OR
                   (VCOUNTERIN > 524 + 526 - PRB_HEIGHT) )THEN
                -- PIXEL RATIO 1:1 (VGA MODE, 60HZ, NOT INTERLACED)
--              IF( EVENODD = '0' )THEN                                         -- PLOT FROM TOP-RIGHT
                IF( EVENODD = '1' )THEN                                         -- PLOT FROM TOP-LEFT
                    DISP_START_X := BASE_LEFT_X + CONV_INTEGER(NOT RATIOMODE);  -- 35 TO 41
                ELSE
                    DISP_START_X := RIGHT_X;                                    -- 106
                END IF;
            ELSE
                DISP_START_X := CENTER_X;                                       -- 72
            END IF;
        END IF;
    END PROCESS;

    -- GENERATE H-SYNC SIGNAL
    PROCESS( RESET, CLK21M )
    BEGIN
        IF( RISING_EDGE(CLK21M) )THEN
            IF( RESET = '1' )THEN
                FF_HSYNC_N <= '1';
	    ELSE
                IF( (HCOUNTERIN = 0) OR (HCOUNTERIN = (CLOCKS_PER_LINE/2)) ) THEN
                    FF_HSYNC_N <= '0';
                ELSIF( (HCOUNTERIN = 40) OR (HCOUNTERIN = (CLOCKS_PER_LINE/2) + 40) ) THEN
                    FF_HSYNC_N <= '1';
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- GENERATE V-SYNC SIGNAL
    -- THE VIDEOVSIN_N SIGNAL IS NOT USED
    PROCESS( RESET, CLK21M )
    BEGIN
        IF( RISING_EDGE(CLK21M) )THEN
            IF( RESET = '1' )THEN
                VIDEOVSOUT_N <= '1';
	    ELSE
                IF ( PALMODE = '0' ) THEN -- caro
                    IF( INTERLACEMODE = '0' ) THEN
                        IF( (VCOUNTERIN = 3*2) OR (VCOUNTERIN = 524+3*2) )THEN
                            VIDEOVSOUT_N <= '0';
                        ELSIF( (VCOUNTERIN = 6*2) OR (VCOUNTERIN = 524+6*2) ) THEN
                            VIDEOVSOUT_N <= '1';
                        END IF;
                    ELSE
                        IF( (VCOUNTERIN = 3*2) OR (VCOUNTERIN = 525+3*2) )THEN
                            VIDEOVSOUT_N <= '0';
                        ELSIF( (VCOUNTERIN = 6*2) OR (VCOUNTERIN = 525+6*2) ) THEN
                            VIDEOVSOUT_N <= '1';
                        END IF;
                    END IF;
                ELSE
                    IF( INTERLACEMODE = '0' ) THEN
                        IF( (VCOUNTERIN = 3*2) OR (VCOUNTERIN = 626+3*2) )THEN
                            VIDEOVSOUT_N <= '0';
                        ELSIF( (VCOUNTERIN = 6*2) OR (VCOUNTERIN = 626+6*2) ) THEN
                            VIDEOVSOUT_N <= '1';
                        END IF;
                    ELSE
                        IF( (VCOUNTERIN = 3*2) OR (VCOUNTERIN = 625+3*2) )THEN
                            VIDEOVSOUT_N <= '0';
                        ELSIF( (VCOUNTERIN = 6*2) OR (VCOUNTERIN = 625+6*2) ) THEN
                            VIDEOVSOUT_N <= '1';
                        END IF;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- GENERATE DATA READ TIMING
    PROCESS( RESET, CLK21M )
    BEGIN
        IF( RISING_EDGE(CLK21M) )THEN
            IF( RESET = '1' )THEN
                XPOSITIONR <= (OTHERS => '0');
	    ELSE
                IF( (HCOUNTERIN = DISP_START_X) OR
                        (HCOUNTERIN = DISP_START_X + (CLOCKS_PER_LINE/2)) ) THEN
                    XPOSITIONR <= (OTHERS => '0');
                ELSE
                    XPOSITIONR <= XPOSITIONR + 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- GENERATE VIDEO OUTPUT TIMING
    PROCESS( RESET, CLK21M )
    BEGIN
        IF( CLK21M'EVENT AND CLK21M = '1' )THEN
            IF( RESET = '1' )THEN
                VIDEOOUTX <= '0';
                VIDEOOUTY <= '0';
	    ELSE
                IF( (HCOUNTERIN = DISP_START_X) OR
                        ((HCOUNTERIN = DISP_START_X + (CLOCKS_PER_LINE/2)) AND INTERLACEMODE = '0') ) THEN
                    VIDEOOUTX <= VIDEOOUTY;
                ELSIF( (HCOUNTERIN = DISP_START_X + DISP_WIDTH) OR
                           (HCOUNTERIN = DISP_START_X + DISP_WIDTH + (CLOCKS_PER_LINE/2)) ) THEN
                    VIDEOOUTX <= '0';
                END IF;

                IF( INTERLACEMODE='0' ) THEN
                    -- NON-INTERLACE
                    -- 3+3+16 = 19
                    IF( (VCOUNTERIN = 20*2) OR
                            ((VCOUNTERIN = 524+20*2) AND (PALMODE = '0')) OR
                            ((VCOUNTERIN = 626+20*2) AND (PALMODE = '1')) ) THEN
                        VIDEOOUTY <= '1';
                    ELSIF(  ((VCOUNTERIN = 524) AND (PALMODE = '0')) OR
                            ((VCOUNTERIN = 626) AND (PALMODE = '1')) OR
                             (VCOUNTERIN = 0) ) THEN
                        VIDEOOUTY <= '0';
                    END IF;
                ELSE
                    -- INTERLACE
                    IF( (VCOUNTERIN = 20*2) OR
                            -- +1 SHOULD BE NEEDED.
                            -- BECAUSE ODD FIELD'S START IS DELAYED HALF LINE.
                            -- SO THE START POSITION OF DISPLAY TIME SHOULD BE
                            -- DELAYED MORE HALF LINE.
                            ((VCOUNTERIN = 525+20*2 + 1) AND (PALMODE = '0')) OR
                            ((VCOUNTERIN = 625+20*2 + 1) AND (PALMODE = '1')) ) THEN
                        VIDEOOUTY <= '1';
                    ELSIF(  ((VCOUNTERIN = 525) AND (PALMODE = '0')) OR
                            ((VCOUNTERIN = 625) AND (PALMODE = '1')) OR
                             (VCOUNTERIN = 0) ) THEN
                        VIDEOOUTY <= '0';
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    VIDEODEOUT <= VIDEOOUTX;
    VIDEOHSOUT_N <= FF_HSYNC_N;
END RTL;
