--
--  vdp_hvcounter.vhd
--   horizontal and vertical counter of ESE-VDP.
--
--  Copyright (C) 2000-2006 Kunihiko Ohnaka
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

LIBRARY IEEE;
    USE IEEE.STD_LOGIC_1164.ALL;
    USE IEEE.STD_LOGIC_UNSIGNED.ALL;
    USE IEEE.STD_LOGIC_ARITH.ALL;
    USE WORK.VDP_PACKAGE.ALL;

ENTITY VDP_HVCOUNTER IS
    PORT(
        RESET                   : IN    STD_LOGIC;
        CLK21M                  : IN    STD_LOGIC;

        H_CNT                   : OUT   STD_LOGIC_VECTOR( 10 DOWNTO 0 );
        V_CNT_IN_FIELD          : OUT   STD_LOGIC_VECTOR(  9 DOWNTO 0 );
        V_CNT_IN_FRAME          : OUT   STD_LOGIC_VECTOR( 10 DOWNTO 0 );
        FIELD                   : OUT   STD_LOGIC;
        H_BLANK                 : OUT   STD_LOGIC;
        V_BLANK                 : OUT   STD_LOGIC;

        PAL_MODE                : IN    STD_LOGIC;
        INTERLACE_MODE          : IN    STD_LOGIC;
        Y212_MODE               : IN    STD_LOGIC
    );
END VDP_HVCOUNTER;

ARCHITECTURE RTL OF VDP_HVCOUNTER IS

    -- FLIP FLOP
    SIGNAL FF_H_CNT                 : STD_LOGIC_VECTOR( 10 DOWNTO 0 );
    SIGNAL FF_V_CNT_IN_FIELD        : STD_LOGIC_VECTOR(  9 DOWNTO 0 );
    SIGNAL FF_FIELD                 : STD_LOGIC;
    SIGNAL FF_V_CNT_IN_FRAME        : STD_LOGIC_VECTOR( 10 DOWNTO 0 );
    SIGNAL FF_H_BLANK               : STD_LOGIC;
    SIGNAL FF_V_BLANK               : STD_LOGIC;
    SIGNAL FF_PAL_MODE              : STD_LOGIC;
    SIGNAL FF_INTERLACE_MODE        : STD_LOGIC;

    -- WIRE
    SIGNAL W_H_CNT_HALF             : STD_LOGIC;
    SIGNAL W_H_CNT_END              : STD_LOGIC;
    SIGNAL W_FIELD_END_CNT          : STD_LOGIC_VECTOR(  9 DOWNTO 0 );
    SIGNAL W_FIELD_END              : STD_LOGIC;
    SIGNAL W_DISPLAY_MODE           : STD_LOGIC_VECTOR(  1 DOWNTO 0 );
    SIGNAL W_LINE_MODE              : STD_LOGIC_VECTOR(  1 DOWNTO 0 );
    SIGNAL W_H_BLANK_START          : STD_LOGIC;
    SIGNAL W_H_BLANK_END            : STD_LOGIC;
    SIGNAL W_V_BLANKING_START       : STD_LOGIC;
    SIGNAL W_V_BLANKING_END         : STD_LOGIC;
    SIGNAL W_V_SYNC_INTR_START_LINE : STD_LOGIC_VECTOR(  8 DOWNTO 0 );
BEGIN

    H_CNT               <= FF_H_CNT;
    V_CNT_IN_FIELD      <= FF_V_CNT_IN_FIELD;
    FIELD               <= FF_FIELD;
    V_CNT_IN_FRAME      <= FF_V_CNT_IN_FRAME;
    H_BLANK             <= FF_H_BLANK;
    V_BLANK             <= FF_V_BLANK;

    --------------------------------------------------------------------------
    --  V SYNCHRONIZE MODE CHANGE
    --------------------------------------------------------------------------
    PROCESS( RESET, CLK21M )
    BEGIN
        IF( RISING_EDGE(CLK21M) )THEN
            IF( RESET = '1' )THEN
                FF_PAL_MODE         <= '0';
                FF_INTERLACE_MODE   <= '0';
            ELSE
                IF( ((W_H_CNT_HALF OR W_H_CNT_END) AND W_FIELD_END AND FF_FIELD) = '1' )THEN
                    FF_PAL_MODE         <= PAL_MODE;
                    FF_INTERLACE_MODE   <= INTERLACE_MODE;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    --------------------------------------------------------------------------
    --  HORIZONTAL COUNTER
    --------------------------------------------------------------------------
    W_H_CNT_HALF    <=  '1' WHEN( FF_H_CNT = (CLOCKS_PER_LINE/2)-1 )ELSE
                        '0';
    W_H_CNT_END     <=  '1' WHEN( FF_H_CNT = CLOCKS_PER_LINE-1 )ELSE
                        '0';

    PROCESS( RESET, CLK21M )
    BEGIN
        IF( RISING_EDGE(CLK21M) )THEN
            IF( RESET = '1' )THEN
                FF_H_CNT <= (OTHERS => '0');
            ELSE
                IF( W_H_CNT_END = '1' )THEN
                    FF_H_CNT <= (OTHERS => '0' );
                ELSE
                    FF_H_CNT <= FF_H_CNT + 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    --------------------------------------------------------------------------
    --  VERTICAL COUNTER
    --------------------------------------------------------------------------
    W_DISPLAY_MODE  <=  FF_INTERLACE_MODE & FF_PAL_MODE;

    WITH( W_DISPLAY_MODE )SELECT W_FIELD_END_CNT <=
        CONV_STD_LOGIC_VECTOR( 523, 10 )    WHEN "00",
        CONV_STD_LOGIC_VECTOR( 524, 10 )    WHEN "10",
        CONV_STD_LOGIC_VECTOR( 625, 10 )    WHEN "01",
        CONV_STD_LOGIC_VECTOR( 624, 10 )    WHEN "11",
        (OTHERS=>'X')                       WHEN OTHERS;

    W_FIELD_END <=  '1' WHEN( FF_V_CNT_IN_FIELD = W_FIELD_END_CNT )ELSE
                    '0';

    PROCESS( RESET, CLK21M )
    BEGIN
        IF( RISING_EDGE(CLK21M) )THEN
            IF( RESET = '1' )THEN
                FF_V_CNT_IN_FIELD   <= (OTHERS => '0');
            ELSE
                IF( (W_H_CNT_HALF OR W_H_CNT_END) = '1' )THEN
                    IF( W_FIELD_END = '1' )THEN
                        FF_V_CNT_IN_FIELD <= (OTHERS => '0');
                    ELSE
                        FF_V_CNT_IN_FIELD <= FF_V_CNT_IN_FIELD + 1;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    --------------------------------------------------------------------------
    --  FIELD ID
    --------------------------------------------------------------------------
    PROCESS( RESET, CLK21M )
    BEGIN
        IF( RISING_EDGE(CLK21M) )THEN
            IF( RESET = '1' )THEN
                FF_FIELD <= '0';
            ELSE
                -- GENERATE FF_FIELD SIGNAL
                IF( (W_H_CNT_HALF OR W_H_CNT_END) = '1' )THEN
                    IF( W_FIELD_END = '1' )THEN
                        FF_FIELD <= NOT FF_FIELD;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    --------------------------------------------------------------------------
    --  VERTICAL COUNTER IN FRAME
    --------------------------------------------------------------------------
    PROCESS( RESET, CLK21M )
    BEGIN
        IF( RISING_EDGE(CLK21M) )THEN
            IF( RESET = '1' )THEN
                FF_V_CNT_IN_FRAME   <= (OTHERS => '0');
            ELSE
                IF( (W_H_CNT_HALF OR W_H_CNT_END) = '1' )THEN
                    IF( W_FIELD_END = '1' AND FF_FIELD = '1' )THEN
                        FF_V_CNT_IN_FRAME   <= (OTHERS => '0');
                    ELSE
                        FF_V_CNT_IN_FRAME   <= FF_V_CNT_IN_FRAME + 1;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -----------------------------------------------------------------------------
    -- H BLANKING
    -----------------------------------------------------------------------------
    W_H_BLANK_START     <=  W_H_CNT_END;
    W_H_BLANK_END       <=  '1' WHEN( FF_H_CNT = LEFT_BORDER )ELSE
                            '0';

    PROCESS( RESET, CLK21M )
    BEGIN
        IF( RISING_EDGE(CLK21M) )THEN
            IF( RESET = '1' )THEN
                FF_H_BLANK <= '0';
            ELSE
                IF( W_H_BLANK_START = '1' )THEN
                    FF_H_BLANK <= '1';
                ELSIF( W_H_BLANK_END = '1' )THEN
                    FF_H_BLANK <= '0';
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -----------------------------------------------------------------------------
    -- V BLANKING
    -----------------------------------------------------------------------------
    W_LINE_MODE <= Y212_MODE & FF_PAL_MODE;

    WITH W_LINE_MODE SELECT W_V_SYNC_INTR_START_LINE <=
        CONV_STD_LOGIC_VECTOR( V_BLANKING_START_192_NTSC, 9 )   WHEN "00",
        CONV_STD_LOGIC_VECTOR( V_BLANKING_START_212_NTSC, 9 )   WHEN "10",
        CONV_STD_LOGIC_VECTOR( V_BLANKING_START_192_PAL, 9 )    WHEN "01",
        CONV_STD_LOGIC_VECTOR( V_BLANKING_START_212_PAL, 9 )    WHEN "11",
        (OTHERS => 'X')                         WHEN OTHERS;

    W_V_BLANKING_END    <=  '1' WHEN( (FF_V_CNT_IN_FIELD = ("00" & (OFFSET_Y + LED_TV_Y_NTSC) & (FF_FIELD AND FF_INTERLACE_MODE)) AND FF_PAL_MODE = '0') OR
                                      (FF_V_CNT_IN_FIELD = ("00" & (OFFSET_Y + LED_TV_Y_PAL) & (FF_FIELD AND FF_INTERLACE_MODE)) AND FF_PAL_MODE = '1') )ELSE
                            '0';
    W_V_BLANKING_START  <=  '1' WHEN( (FF_V_CNT_IN_FIELD = ((W_V_SYNC_INTR_START_LINE + LED_TV_Y_NTSC) & (FF_FIELD AND FF_INTERLACE_MODE)) AND FF_PAL_MODE = '0') OR
                                      (FF_V_CNT_IN_FIELD = ((W_V_SYNC_INTR_START_LINE + LED_TV_Y_PAL) & (FF_FIELD AND FF_INTERLACE_MODE)) AND FF_PAL_MODE = '1') )ELSE
                            '0';

    PROCESS( RESET, CLK21M )
    BEGIN
        IF( RISING_EDGE(CLK21M) )THEN
            IF( RESET = '1' )THEN
                FF_V_BLANK <= '0';
            ELSE
                IF( W_H_BLANK_END = '1' )THEN
                    IF( W_V_BLANKING_END = '1' )THEN
                        FF_V_BLANK <= '0';
                    ELSIF( W_V_BLANKING_START = '1' )THEN
                        FF_V_BLANK <= '1';
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

END RTL;
