--
--  vdp_vga.vhd
--   VGA up-scan converter.
--
--  Copyright (C) 2006 Kunihiko Ohnaka
--  All rights reserved.
--                                     http://www.ohnaka.jp/ese-vdp/
--
--  �{�\�t�g�E�F�A�����і{�\�t�g�E�F�A�Ɋ��Â��č쐬���ꂽ�h�����́A�ȉ��̏��
--  �������ꍇ�Ɍ���A�ĔЕz�����юg�p���������܂��B
--
--  1.�\�[�X�R�[�h�`���ōĔЕz�����ꍇ�A���L�̒��쌠�\���A�{��ꗗ�A�����щ��L
--    �Ɛӏ��̂܂܂̌`�ŕێ����邱�ƁB
--  2.�o�C�i���`���ōĔЕz�����ꍇ�A�Еz���ɕt���̃h�L�������g���̎����ɁA���L��
--    ���쌠�\���A�{��ꗗ�A�����щ��L�Ɛӏ���܂߂邱�ƁB
--  3.���ʂɂ��鎖�O�̋��Ȃ��ɁA�{�\�t�g�E�F�A���̔��A�����я��ƓI�Ȑ��i�⊈��
--    �Ɏg�p���Ȃ����ƁB
--
--  �{�\�t�g�E�F�A�́A���쌠�҂ɂ���āu�����̂܂܁v�񋟂����Ă��܂��B���쌠�҂́A
--  ����ړI�ւ̓K�����̕ۏ؁A���i���̕ۏ؁A�܂������Ɍ�肳���Ȃ��A�����Ȃ閾��
--  �I�����͈ÖقȕۏؐӔC�����܂����B���쌠�҂́A���R�̂����������킸�A���Q
--  �����̌�����������킸�A���ӔC�̍������_���ł��邩���i�ӔC�ł��邩�i�ߎ�
--  ���̑��́j�s�@�s�ׂł��邩�����킸�A���ɂ��̂悤�ȑ��Q�����������\�����m��
--  �����Ă����Ƃ��Ă��A�{�\�t�g�E�F�A�̎g�p�ɂ���Ĕ��������i���֕i�܂��͑��p�T
--  �[�r�X�̒��B�A�g�p�̑r���A�f�[�^�̑r���A���v�̑r���A�Ɩ��̒��f���܂߁A�܂���
--  ���Ɍ�肳���Ȃ��j���ڑ��Q�A�Ԑڑ��Q�A��I�ȑ��Q�A��ʑ��Q�A�����I���Q�A��
--  ���͌��ʑ��Q�ɂ��āA���ؐӔC�𕉂��Ȃ����̂Ƃ��܂��B
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
--   JP: ���{���̃R�����g�s�� JP:�𓪂ɕt���鎖�ɂ���
--
-------------------------------------------------------------------------------
-- Revision History
--
-- 29th,October,2006 modified by Kunihiko Ohnaka
--   - Insert the license text.
--   - Add the document part below.
--
-- ?th,August,2006 modified by Kunihiko Ohnaka
--   - Move the equalization pulse generator from
--     vdp.vhd.
--
-- 20th,August,2006 modified by Kunihiko Ohnaka
--  - Change field mapping algorithm when interlace
--    mode is enabled.
--        even field  -> even line (odd  line is blacK)
--        odd  field  -> odd line  (even line is blacK)
--
-- 13th,October,2003 created by Kunihiko Ohnaka
-- JP: VDP�̃R�A�̎���ƕ\���f�o�C�X�ւ̏o�͂��ʃ\�[�X�ɂ����D
--
-------------------------------------------------------------------------------
-- Document
--
-- JP: ESE-VDP�R�A(vdp.vhd)�����������r�f�I�M�����AVGA�^�C�~���O��
-- JP: �ϊ������A�b�v�X�L�����R���o�[�^�ł��B
-- JP: NTSC�͐����������g����15.7KHz�A�����������g����60Hz�ł����A
-- JP: VGA�̐����������g����31.5KHz�A�����������g����60Hz�ł����A
-- JP: ���C�����������قڔ{�ɂȂ���悤�ȃ^�C�~���O�ɂȂ��܂��B
-- JP: �����ŁAvdp�� ntsc���[�h�œ������A�e���C�����{�̑��x��
-- JP: ���x�`�悷�邱�ƂŃX�L�����R���o�[�g��������Ă��܂��B
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
        -- VIDEO OUTPUT
        VIDEOROUT       : OUT   STD_LOGIC_VECTOR( 5 DOWNTO 0);
        VIDEOGOUT       : OUT   STD_LOGIC_VECTOR( 5 DOWNTO 0);
        VIDEOBOUT       : OUT   STD_LOGIC_VECTOR( 5 DOWNTO 0);
        VIDEODEOUT      : OUT   STD_LOGIC;
        VIDEOHSOUT_N    : OUT   STD_LOGIC;
        VIDEOVSOUT_N    : OUT   STD_LOGIC
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
    CONSTANT DISP_WIDTH     : INTEGER := 562;    -- 30 + 512 + 20
    CONSTANT DISP_START_X   : INTEGER := 120;
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

    -- GENERATE H-SYNC SIGNAL
    PROCESS( RESET, CLK21M )
    BEGIN
        IF( RESET = '1' )THEN
            FF_HSYNC_N <= '1';
        ELSIF( CLK21M'EVENT AND CLK21M = '1' )THEN
            IF( (HCOUNTERIN = 0) OR (HCOUNTERIN = (CLOCKS_PER_LINE/2)) ) THEN
                FF_HSYNC_N <= '0';
            ELSIF( (HCOUNTERIN = 40) OR (HCOUNTERIN = (CLOCKS_PER_LINE/2) + 40) ) THEN
                FF_HSYNC_N <= '1';
            END IF;
        END IF;
    END PROCESS;

    -- GENERATE V-SYNC SIGNAL
    -- THE VIDEOVSIN_N SIGNAL IS NOT USED
    PROCESS( RESET, CLK21M )
    BEGIN
        IF( RESET = '1' )THEN
            VIDEOVSOUT_N <= '1';
        ELSIF( CLK21M'EVENT AND CLK21M = '1' )THEN
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
    END PROCESS;

    -- GENERATE DATA READ TIMING
    PROCESS( RESET, CLK21M )
    BEGIN
        IF( RESET = '1' )THEN
            XPOSITIONR <= (OTHERS => '0');
        ELSIF( CLK21M'EVENT AND CLK21M = '1' )THEN
            IF( (HCOUNTERIN = DISP_START_X) OR
                    (HCOUNTERIN = DISP_START_X + (CLOCKS_PER_LINE/2)) ) THEN
                XPOSITIONR <= (OTHERS => '0');
            ELSE
                XPOSITIONR <= XPOSITIONR + 1;
            END IF;
        END IF;
    END PROCESS;

    -- GENERATE VIDEO OUTPUT TIMING
    PROCESS( RESET, CLK21M )
    BEGIN
        IF( RESET = '1' )THEN
            VIDEOOUTX <= '0';
            VIDEOOUTY <= '0';
        ELSIF( CLK21M'EVENT AND CLK21M = '1' )THEN
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
    END PROCESS;

	 VIDEODEOUT <= VIDEOOUTX;
    VIDEOHSOUT_N <= FF_HSYNC_N;
END RTL;
