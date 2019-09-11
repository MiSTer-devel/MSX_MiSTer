--
--  VDP_NTSC.vhd
--   VDP_NTSC sync signal generator.
--
--  Copyright (C) 2006 Kunihiko Ohnaka
--  All rights reserved.
--                                     http://www.ohnaka.jp/ese-vdp/
--
--  {\tgEFA¨æÑ{\tgEFAÉîÃ¢Äì¬³ê½h¶¨ÍAÈºÌðð
--  ½·êÉÀèAÄÐz¨æÑgpªÂ³êÜ·B
--
--  1.\[XR[h`®ÅÄÐz·éêAãLÌì \¦A{ðêA¨æÑºL
--    ÆÓðð»ÌÜÜÌ`ÅÛ·é±ÆB
--  2.oCi`®ÅÄÐz·éêAÐz¨Ét®ÌhLgÌ¿ÉAãLÌ
--    ì \¦A{ðêA¨æÑºLÆÓððÜßé±ÆB
--  3.ÊÉæéOÌÂÈµÉA{\tgEFAðÌA¨æÑ¤ÆIÈ»iâ®
--    ÉgpµÈ¢±ÆB
--
--  {\tgEFAÍAì ÒÉæÁÄu»óÌÜÜvñ³êÄ¢Ü·Bì ÒÍA
--  ÁèÚIÖÌK«ÌÛØA¤i«ÌÛØAÜ½»êÉÀè³êÈ¢A¢©Èé¾¦
--  Iàµ­ÍÃÙÈÛØÓCà¢Ü¹ñBì ÒÍARÌ¢©ñðâí¸A¹Q
--  ­¶Ì´ö¢©ñðâí¸A©ÂÓCÌªª_ñÅ é©µiÓCÅ é©iß¸
--  »Ì¼Ìjs@s×Å é©ðâí¸A¼É»Ìæ¤È¹Qª­¶·éÂ\«ðmç
--  ³êÄ¢½ÆµÄàA{\tgEFAÌgpÉæÁÄ­¶µ½iãÖiÜ½ÍãpT
--  [rXÌ²BAgpÌr¸Af[^Ìr¸AvÌr¸AÆ±ÌfàÜßAÜ½»
--  êÉÀè³êÈ¢j¼Ú¹QAÔÚ¹QAô­IÈ¹QAÁÊ¹QA¦±I¹QAÜ
--  ½ÍÊ¹QÉÂ¢ÄAêØÓCðíÈ¢àÌÆµÜ·B
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
--   JP: ú{êÌRgsÍ JP:ðªÉt¯éÉ·é
--
-------------------------------------------------------------------------------
-- Revision History
--
-- 13th,October,2003 created by Kunihiko Ohnaka
-- JP: VDPÌRAÌÀÆ\¦foCXÖÌoÍðÊ\[XÉµ½D
--
-- ?th,August,2006 modified by Kunihiko Ohnaka
--   - Move the equalization pulse generator from
--     vdp.vhd.
--
-- 29th,October,2006 modified by Kunihiko Ohnaka
--   - Insert the license text.
--   - Add the document part below.
--
-- 23th,March,2008 modified by t.hara
-- JP: t@N^O, NTSC Æ PAL Ì^C~O¶¬ñHð
--
-------------------------------------------------------------------------------
-- Document
--
-- JP: ESE-VDPRA(vdp.vhd)ª¶¬µ½rfIMðANTSC/PALÌ
-- JP: ^C~OÉÁ½¯úM¨æÑfMÉÏ·µÜ·B
-- JP: ESE-VDPRAÍNTSC[hÍ NTSC/PALÌ^C~OÅf
-- JP: Mâ¼¯úMð¶¬·é½ßA{W[ÅÍ
-- JP: ½¯úMÉ¿pXð}ü·é¾¯ðsÁÄ
-- JP: ¢Ü·B
--

LIBRARY IEEE;
    USE IEEE.STD_LOGIC_1164.ALL;
    USE IEEE.STD_LOGIC_UNSIGNED.ALL;
    USE WORK.VDP_PACKAGE.ALL;

ENTITY VDP_NTSC_PAL IS
    PORT(
        CLK21M              : IN    STD_LOGIC;
        RESET               : IN    STD_LOGIC;
        -- MODE
        PALMODE             : IN    STD_LOGIC;
        INTERLACEMODE       : IN    STD_LOGIC;
        -- VIDEO INPUT
        VIDEORIN            : IN    STD_LOGIC_VECTOR(  5 DOWNTO 0 );
        VIDEOGIN            : IN    STD_LOGIC_VECTOR(  5 DOWNTO 0 );
        VIDEOBIN            : IN    STD_LOGIC_VECTOR(  5 DOWNTO 0 );
        VIDEOVSIN_N         : IN    STD_LOGIC;
        HCOUNTERIN          : IN    STD_LOGIC_VECTOR( 10 DOWNTO 0 );
        VCOUNTERIN          : IN    STD_LOGIC_VECTOR( 10 DOWNTO 0 );
        -- VIDEO OUTPUT
        VIDEOROUT           : OUT   STD_LOGIC_VECTOR(  5 DOWNTO 0 );
        VIDEOGOUT           : OUT   STD_LOGIC_VECTOR(  5 DOWNTO 0 );
        VIDEOBOUT           : OUT   STD_LOGIC_VECTOR(  5 DOWNTO 0 );
        VIDEOHSOUT_N        : OUT   STD_LOGIC;
        VIDEOVSOUT_N        : OUT   STD_LOGIC
    );
END VDP_NTSC_PAL;

ARCHITECTURE RTL OF VDP_NTSC_PAL IS
    TYPE TYPSSTATE IS (SSTATE_A, SSTATE_B, SSTATE_C, SSTATE_D);
    SIGNAL FF_SSTATE        : TYPSSTATE;
    SIGNAL FF_HSYNC_N       : STD_LOGIC;

    SIGNAL W_MODE           : STD_LOGIC_VECTOR(  1 DOWNTO 0 );
    SIGNAL W_STATE_A1_FULL  : STD_LOGIC_VECTOR( 10 DOWNTO 0 );
    SIGNAL W_STATE_A2_FULL  : STD_LOGIC_VECTOR( 10 DOWNTO 0 );
    SIGNAL W_STATE_B_FULL   : STD_LOGIC_VECTOR( 10 DOWNTO 0 );
    SIGNAL W_STATE_C_FULL   : STD_LOGIC_VECTOR( 10 DOWNTO 0 );
BEGIN

    -- MODE
    W_MODE  <= PALMODE & INTERLACEMODE;
    WITH( W_MODE )SELECT W_STATE_A1_FULL <=
        "01000001100"   WHEN "00",  -- 524
        "01000001101"   WHEN "01",  -- 525
        "01001110010"   WHEN "10",  -- 626
        "01001110001"   WHEN "11",  -- 625
        (OTHERS => 'X') WHEN OTHERS;

    WITH( W_MODE )SELECT W_STATE_A2_FULL <=
        "01000011000"   WHEN "00",  -- 524+12
        "01000011001"   WHEN "01",  -- 525+12
        "01001111110"   WHEN "10",  -- 626+12
        "01001111101"   WHEN "11",  -- 625+12
        (OTHERS => 'X') WHEN OTHERS;

    WITH( W_MODE )SELECT W_STATE_B_FULL <=
        "01000010010"   WHEN "00",  -- 524+6
        "01000010011"   WHEN "01",  -- 525+6
        "01001111000"   WHEN "10",  -- 626+6
        "01001110111"   WHEN "11",  -- 625+6
        (OTHERS => 'X') WHEN OTHERS;

    WITH( W_MODE )SELECT W_STATE_C_FULL <=
        "01000011110"   WHEN "00",  -- 524+18
        "01000011111"   WHEN "01",  -- 525+18
        "01010000100"   WHEN "10",  -- 626+18
        "01010000011"   WHEN "11",  -- 625+18
        (OTHERS => 'X') WHEN OTHERS;

    -- STATE
    PROCESS( RESET, CLK21M )
    BEGIN
        IF (CLK21M'EVENT AND CLK21M = '1') THEN
            IF (RESET = '1') THEN
                FF_SSTATE <= SSTATE_A;
            ELSE
                IF(     (VCOUNTERIN = 0) OR
                        (VCOUNTERIN = 12) OR
                        (VCOUNTERIN = W_STATE_A1_FULL) OR
                        (VCOUNTERIN = W_STATE_A2_FULL) )THEN
                    FF_SSTATE <= SSTATE_A;
                ELSIF(  (VCOUNTERIN = 6) OR
                        (VCOUNTERIN = W_STATE_B_FULL) )THEN
                    FF_SSTATE <= SSTATE_B;
                ELSIF(  (VCOUNTERIN = 18) OR
                        (VCOUNTERIN = W_STATE_C_FULL) )THEN
                    FF_SSTATE <= SSTATE_C;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- GENERATE H SYNC PULSE
    PROCESS( RESET, CLK21M )
    BEGIN
        IF( CLK21M'EVENT AND CLK21M = '1' )THEN
            IF( RESET = '1' )THEN
                FF_HSYNC_N <= '0';
            ELSE
--                IF( FF_SSTATE = SSTATE_A )THEN
--                    IF( (HCOUNTERIN = 1) OR (HCOUNTERIN = CLOCKS_PER_LINE/2+1) ) THEN
--                        FF_HSYNC_N <= '0';                       -- PULSE ON
--                        VIDEOVSOUT_N <= VIDEOVSIN_N;
--                    ELSIF( (HCOUNTERIN = 51) OR (HCOUNTERIN = CLOCKS_PER_LINE/2+51) ) THEN
--                        FF_HSYNC_N <= '1';                       -- PULSE OFF
--                    END IF;
--                ELSIF( FF_SSTATE = SSTATE_B )THEN
--                    IF( (HCOUNTERIN = CLOCKS_PER_LINE-100+1 ) OR (HCOUNTERIN = CLOCKS_PER_LINE/2-100+1) ) THEN
--                        FF_HSYNC_N <= '0';                       -- PULSE ON
--                        VIDEOVSOUT_N <= VIDEOVSIN_N;
--                    ELSIF( (HCOUNTERIN = 1) OR (HCOUNTERIN = CLOCKS_PER_LINE/2+1) ) THEN
--                        FF_HSYNC_N <= '1';                       -- PULSE OFF
--                    END IF;
--                ELSIF( FF_SSTATE = SSTATE_C )THEN
                    IF( HCOUNTERIN = 1 )THEN
                        FF_HSYNC_N <= '0';                       -- PULSE ON
--                        VIDEOVSOUT_N <= VIDEOVSIN_N;
                    ELSIF( HCOUNTERIN = 101 )THEN
                        FF_HSYNC_N <= '1';                       -- PULSE OFF
                    END IF;
--                END IF;
            END IF;
        END IF;
    END PROCESS;

    VIDEOHSOUT_N    <= FF_HSYNC_N;
    VIDEOVSOUT_N    <= VIDEOVSIN_N;
    VIDEOROUT       <= VIDEORIN;
    VIDEOGOUT       <= VIDEOGIN;
    VIDEOBOUT       <= VIDEOBIN;
END RTL;
