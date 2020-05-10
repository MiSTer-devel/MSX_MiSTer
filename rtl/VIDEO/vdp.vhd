--
--  vdp.vhd
--   Top VHDL Source of ESE-VDP.
--
--  Copyright (C) 2000-2006 Kunihiko Ohnaka
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
-- Contributors
--
--   Kazuhiro Tsujikawa
--     - Bug fixes
--   Alex Wulms
--     - Bug fixes
--     - Expansion and improvement of the VDP-Command engine
--     - Improvement of the TEXT2 mode.
--
-------------------------------------------------------------------------------
-- Memo
--   Japanese comment lines are starts with "JP:".
--   JP: ���{���̃R�����g�s�� JP:�𓪂ɕt���鎖�ɂ���
--
-------------------------------------------------------------------------------
-- Todo
--   * support VdpCmdMXS, VdpCmdMXD bits in command engine
--
-------------------------------------------------------------------------------
-- Revision History
--
-- 3rd,June,2018 modified by KdL
--  - Improved the VGA up-scan converter
--
-- 15th,March,2017 modified by KdL
--  - Improved ENAHSYNC, thanks to Grauw
--
-- 27th,July,2014 modified by KdL
--  - Fixed H-SYNC interrupt reset control
--
-- 23rd,January,2013 modified by KdL
--  - Fixed V-SYNC and H-SYNC interrupt
--  - Added an extra signal to force NTSC/PAL modes
--
-- 29th,October,2006 modified by Kunihiko Ohnaka
--  - Added the license text
--  - Added the document part below
--
-- 3rd,Sep,2006 modified by Kunihiko Ohnaka
--  - Fix several UNKNOWN REALITY problems
--  - Horizontal Sprite problem
--  - Overscan problem
--  - [NOP] zoom demo problem
--  - 'Star Wars Scroll' demo problem
--
-- 20th,Aug,2006 modified by Kunihiko Ohnaka
--  - Separate SPRITE module.
--  - Fixed the palette rewriting timing problem.
--  - Added the interlace double resolution function. (Two page mode)
--
-- 15th,Aug,2006 modified by Kunihiko Ohnaka
--  - Separate VDP_NTSC sync generator module.
--  - Separate screen mode modules.
--  - Fixed the sprite posision problem on GRAPHIC6.
--
-- 15th,Jan,2006 modified by Alex Wulms
-- text 2 mode  : debug blink function
-- high-res modi: debug 'screen off'
-- text 1&2 mode: debug VdpR23 scroll and color "0000" handling
-- all modi     : precalculate adjustx, adjusty once per line

-- 1th,Jan,2006 modified by Alex Wulms
-- Added the blink support to text 2 mode
--
-- 16th,Aug,2005 modified by Kazuhiro Tsujikawa
-- JP: TMS9918���[�h��VRAM�C���N�������g���14�r�b�g�Ɍ��
--
-- 08th,May,2005 modified by Kunihiko Ohnaka
-- JP: VGA�R���|�[�l���g��InerlaceMode�M�����`�����悤�ɂ���
--
-- 26th,April,2005 modified by Kazuhiro Tsujikawa
-- JP: VRAM�Ƃ̃f�[�^�o�X(pRamDbi/pRamDbo)���P�����o�X��(SDRAM�Ή�)
--
-- 08th,November,2004 modified by Kazuhiro Tsujikawa
-- JP: Vsync/Hsync���荞�ݏC���~�X����
--
-- 03rd,November,2004 modified by Kazuhiro Tsujikawa
-- JP: SCREEN6���ʎ��ӐF�C����MSX2�^�C�g�����S�Ή�
--
-- 19th,September,2004 modified by Kazuhiro Tsujikawa
-- JP: �p�^�[���l�[���e�[�u���̃}�X�N�������ANMA�f���Ή�
-- JP: MultiColorMode(SCREEN3)������}�W���r�f���Ή�
--
-- 12th,September,2004 modified by Kazuhiro Tsujikawa
-- JP: VdpR0DispNum����C���P�ʂŔ��f���X�y�[�X�}���{�E�ł̃`���c�L�΍�
--
-- 11th,September,2004 modified by Kazuhiro Tsujikawa
-- JP: �����A�����荞�ݏC����MGSEL(�e���|������)�΍�
--
-- 22nd,August,2004 modified by Kazuhiro Tsujikawa
-- JP: �p���b�g��Read/Write�Փ˂��C�����K�[���ł̃`���c�L�΍�
--
-- 21st,August,2004 modified by Kazuhiro Tsujikawa
-- JP: R#1/IE0(�����A�����荞�݋���)�̓������C����GALAGA�΍�
--
-- 2nd,August,2004 modified by Kazuhiro Tsujikawa
-- JP: Screen7/8�ł̃X�v���C�g�ǂݍ��݃A�h���X���C����Snatcher�΍�
--
-- 31th,July,2004 modified by Kazuhiro Tsujikawa
-- JP: Screen7/8�ł�VRAM�ǂݍ��݃A�h���X���C����Snatcher�΍�
--
-- 24th,July,2004 modified by Kazuhiro Tsujikawa
-- JP: �X�v���C�g32�������\�����̗������C��(248=256-8->preDotCounter_x_end)
--
-- 18th,July,2004 modified by Kazuhiro Tsujikawa
-- JP: Screen6�̃����_�����O�����쐬
--
-- 17th,July,2004 modified by Kazuhiro Tsujikawa
-- JP: Screen7�̃����_�����O�����쐬
--
-- 29th,June,2004 modified by Kazuhiro Tsujikawa
-- JP: Screen8�̃����_�����O�����C��
--
-- 26th,June,2004 modified by Kazuhiro Tsujikawa
-- JP: WebPack�ŃR���p�C��������HMMC/LMMC/LMCM�����삵�Ȃ��s����C��
-- JP: onehot sequencer(VdpCmdState) must be initialized by asyncronus RESET
--
-- 22nd,June,2004 modified by Kazuhiro Tsujikawa
-- JP: R#1/IE0(�����A�����荞�݋���)�̓������C��
-- JP: Ys2�Ńo�m�A�̉Ƃɓ������l�ɂȂ��
--
-- 13th,June,2004 modified by Kazuhiro Tsujikawa
-- JP: �g���X�v���C�g���E��1�h�b�g�������s����C��
-- JP: SCREEN5�ŃX�v���C�g�E�[32�h�b�g���\�������Ȃ��s����C��
-- JP: SCREEN5��211���C��(�ŉ�)�̃X�v���C�g���\�������Ȃ��s����C��
-- JP: ���ʏ���t���O(VdpR1DispOn)��1���C���P�ʂŔ��f�����l�ɏC��
--
-- 21st,March,2004 modified by Alex Wulms
-- Several enhancements to command engine:
--   Added PSET,LINE,SRCH,POINT
--   Added the screen 6,7,8 support
--   Improved the existing commands
--
-- 15th,January,2004 modified by Kunihiko Ohnaka
-- JP: VDP�R�}���h�̎�����J�n
-- JP: HMMC,HMMM,YMMM,HMMV,LMMC,LMMM,LMMV�����.�܂��s�����.
--
-- 12th,January,2004 modified by Kunihiko Ohnaka
-- JP: �R�����g�̏C��
--
-- 30th,December,2003 modified by Kazuhiro Tsujikawa
-- JP: �N�����̉��ʃ��[�h��VDP_NTSC�� VGA�̂ǂ����ɂ��邩���C�O�����͂Őؑ�
-- JP: DHClk/DLClk���ꎞ�I�ɕ���������
--
-- 16th,December,2003 modified by Kunihiko Ohnaka
-- JP: �N�����̉��ʃ��[�h��VDP_NTSC�� VGA�̂ǂ����ɂ��邩���Cvdp_package.vhd
-- JP: ���Œ��`���ꂽ�萔�Őؑւ����悤�ɂ����D
--
-- 10th,December,2003 modified by Kunihiko Ohnaka
-- JP: TEXT MODE 2 (SCREEN0 WIDTH80)���T�|�[�g�D
-- JP: ���̉������{�𑜓x���[�h�ł����D�ꉞ�����Ή��ł����悤�ɍ����
-- JP: �������肾������C�������܂肪���������������C���܂肫�ꂢ��
-- JP: �Ή��ɂȂ�Ă��Ȃ����������܂��D
--
-- 13th,October,2003 modified by Kunihiko Ohnaka
-- JP: ESE-MSX���ł� 2S300E�𕡐��p���鎖���ł����悤�ɂ��CVDP�P�̂�
-- JP: 2S300E�� SRAM�����L���鎖���\�ƂȂ���D
-- JP: �����ɔ����ȉ��̂悤�ȕύX���s���D
-- JP: �EVGA�o�͑Ή�(�A�b�v�X�L�����R���o�[�g)
-- JP: �ESCREEN7,8�̃^�C�~���O����@�Ɠ�����
--
-- 15th,June,2003 modified by Kunihiko Ohnaka
-- JP:�����A�����Ԋ��荞�݂�������ăX�y�[�X�}���{�E���V�ׂ��悤�ɂ����D
-- JP:GraphicMode3(Screen4)��Y���C������ 212���C���ɂȂ��Ȃ�����̂�
-- JP:�C�������肵���D
-- JP:�������C�X�y�[�X�}���{�E�� set adjust�@�\�������Ă��Ȃ��悤��
-- JP:�����ŁC�\�����K�N�K�N���Ă��܂��D�������̓����\���X�v���C�g����
-- JP:�����Ă��Ȃ��悤�Ɍ������D�����s���D
--
-- 15th,June,2003 modified by Kunihiko Ohnaka
-- JP:�����u�����N���󂢂Ă��܂�����CSpartan-II E + IO���ŃX�v���C�g��
-- JP:�\���������悤�ɂȂ���D�����͂����炭�R���p�C���̃o�O�ŁCISE 5.2��
-- JP:�o�[�W�����A�b�v�������\���������悤�ɂȂ���D
-- JP:���łɁC�X�v���C�g���[�h2�ŉ� 8����Ԃ悤�ɂ���(����)�D
-- JP:���̑��ׂ��ȏC��������Ă��܂��D
--
-- 15th,July,2002 modified by Kazuhiro Tsujikawa
-- no comment;
--
-------------------------------------------------------------------------------
-- Document
--
-- JP: ESE-VDP�̃g�b�v�G���e�B�e�B�ł��BCPU�Ƃ̃C���^�[�t�F�[�X�A
-- JP: ���ʕ`���^�C�~���O�̐����AVDP���W�X�^�̎���Ȃǂ��܂܂���
-- JP: ���܂��B
--


LIBRARY IEEE;
    USE IEEE.STD_LOGIC_1164.ALL;
    USE IEEE.STD_LOGIC_UNSIGNED.ALL;
    USE IEEE.STD_LOGIC_ARITH.ALL;
    USE WORK.VDP_PACKAGE.ALL;

ENTITY VDP IS
    PORT(
        -- VDP CLOCK ... 21.477MHZ
        CLK21M              : IN    STD_LOGIC;
        RESET               : IN    STD_LOGIC;
        REQ                 : IN    STD_LOGIC;
        ACK                 : OUT   STD_LOGIC;
        WRT                 : IN    STD_LOGIC;
        ADR                 : IN    STD_LOGIC_VECTOR( 15 DOWNTO 0 );
        DBI                 : OUT   STD_LOGIC_VECTOR(  7 DOWNTO 0 );
        DBO                 : IN    STD_LOGIC_VECTOR(  7 DOWNTO 0 );

        INT_N               : OUT   STD_LOGIC;

        PRAMOE_N            : OUT   STD_LOGIC;
        PRAMWE_N            : OUT   STD_LOGIC;
        PRAMADR             : OUT   STD_LOGIC_VECTOR( 16 DOWNTO 0 );
        PRAMDBI             : IN    STD_LOGIC_VECTOR( 15 DOWNTO 0 );
        PRAMDBO             : OUT   STD_LOGIC_VECTOR(  7 DOWNTO 0 );

        VDPSPEEDMODE        : IN    STD_LOGIC;
        RATIOMODE           : IN    STD_LOGIC_VECTOR(  2 DOWNTO 0 );
        CENTERYJK_R25_N     : IN    STD_LOGIC;

        -- VIDEO OUTPUT
        PVIDEOR             : OUT   STD_LOGIC_VECTOR(  5 DOWNTO 0 );
        PVIDEOG             : OUT   STD_LOGIC_VECTOR(  5 DOWNTO 0 );
        PVIDEOB             : OUT   STD_LOGIC_VECTOR(  5 DOWNTO 0 );
        PVIDEODE            : OUT   STD_LOGIC;

        PVIDEOHS_N          : OUT   STD_LOGIC;
        PVIDEOVS_N          : OUT   STD_LOGIC;
        PVIDEOCS_N          : OUT   STD_LOGIC;

        PVIDEODHCLK         : OUT   STD_LOGIC;
        PVIDEODLCLK         : OUT   STD_LOGIC;

        -- DISPLAY RESOLUTION (0=15KHZ, 1=31KHZ)
        DISPRESO            : IN    STD_LOGIC;

        NTSC_PAL_TYPE       : IN    STD_LOGIC;
        FORCED_V_MODE       : IN    STD_LOGIC;
        LEGACY_VGA          : IN    STD_LOGIC

        -- DEBUG OUTPUT
    --  DEBUG_OUTPUT        : OUT   STD_LOGIC_VECTOR( 15 DOWNTO 0 ) -- ��
    );
END VDP;

ARCHITECTURE RTL OF VDP IS

    SIGNAL H_CNT                        : STD_LOGIC_VECTOR( 10 DOWNTO 0 );
    SIGNAL V_CNT                        : STD_LOGIC_VECTOR( 10 DOWNTO 0 );

    -- DISPLAY POSITIONS, ADAPTED FOR ADJUST(X,Y)
    SIGNAL ADJUST_X                     : STD_LOGIC_VECTOR(  6 DOWNTO 0 );

    -- DOT STATE REGISTER
    SIGNAL DOTSTATE                     : STD_LOGIC_VECTOR(  1 DOWNTO 0 );
    SIGNAL EIGHTDOTSTATE                : STD_LOGIC_VECTOR(  2 DOWNTO 0 );

    -- DISPLAY FIELD SIGNAL
    SIGNAL FIELD                        : STD_LOGIC;
    SIGNAL HD                           : STD_LOGIC;
    SIGNAL VD                           : STD_LOGIC;
    SIGNAL ACTIVE_LINE                  : STD_LOGIC;
    SIGNAL V_BLANKING_START             : STD_LOGIC;

    -- FOR VSYNC INTERRUPT
    SIGNAL VSYNCINT_N                   : STD_LOGIC;
    SIGNAL CLR_VSYNC_INT                : STD_LOGIC;
    SIGNAL REQ_VSYNC_INT_N              : STD_LOGIC;

    -- FOR HSYNC INTERRUPT
    SIGNAL HSYNCINT_N                   : STD_LOGIC;
    SIGNAL CLR_HSYNC_INT                : STD_LOGIC;
    SIGNAL REQ_HSYNC_INT_N              : STD_LOGIC;

    SIGNAL DVIDEOHS_N                   : STD_LOGIC;

    -- DISPLAY AREA FLAGS
    SIGNAL WINDOW                       : STD_LOGIC;
    SIGNAL WINDOW_X                     : STD_LOGIC;
    SIGNAL PREWINDOW_X                  : STD_LOGIC;
    SIGNAL PREWINDOW_Y                  : STD_LOGIC;
    SIGNAL PREWINDOW_Y_SP               : STD_LOGIC;
    SIGNAL PREWINDOW                    : STD_LOGIC;
    SIGNAL PREWINDOW_SP                 : STD_LOGIC;
    -- FOR FRAME ZONE
    SIGNAL BWINDOW_X                    : STD_LOGIC;
    SIGNAL BWINDOW_Y                    : STD_LOGIC;
    SIGNAL BWINDOW                      : STD_LOGIC;
    SIGNAL BWINDOW_VGA                  : STD_LOGIC;

    -- DOT COUNTER - 8 ( READING ADDR )
    SIGNAL PREDOTCOUNTER_X              : STD_LOGIC_VECTOR(  8 DOWNTO 0 );
    SIGNAL PREDOTCOUNTER_Y              : STD_LOGIC_VECTOR(  8 DOWNTO 0 );
    -- Y COUNTERS INDEPENDENT OF VERTICAL SCROLL REGISTER
    SIGNAL PREDOTCOUNTER_YP             : STD_LOGIC_VECTOR(  8 DOWNTO 0 );

    -- VDP REGISTER ACCESS
    SIGNAL VDPVRAMACCESSADDR            : STD_LOGIC_VECTOR( 16 DOWNTO 0 );
    SIGNAL DISPMODEVGA                  : STD_LOGIC;
    SIGNAL VDPVRAMREADINGR              : STD_LOGIC;
    SIGNAL VDPVRAMREADINGA              : STD_LOGIC;
    SIGNAL VDPR0DISPNUM                 : STD_LOGIC_VECTOR(  3 DOWNTO 1 );
    SIGNAL VDPVRAMACCESSDATA            : STD_LOGIC_VECTOR(  7 DOWNTO 0 );
    SIGNAL VDPVRAMACCESSADDRTMP         : STD_LOGIC_VECTOR( 16 DOWNTO 0 );
    SIGNAL VDPVRAMADDRSETREQ            : STD_LOGIC;
    SIGNAL VDPVRAMADDRSETACK            : STD_LOGIC;
    SIGNAL VDPVRAMWRREQ                 : STD_LOGIC;
    SIGNAL VDPVRAMWRACK                 : STD_LOGIC;
    SIGNAL VDPVRAMRDDATA                : STD_LOGIC_VECTOR(  7 DOWNTO 0 );
    SIGNAL VDPVRAMRDREQ                 : STD_LOGIC;
    SIGNAL VDPVRAMRDACK                 : STD_LOGIC;
    SIGNAL VDPR9PALMODE                 : STD_LOGIC;

    SIGNAL REG_R0_HSYNC_INT_EN          : STD_LOGIC;
    SIGNAL REG_R1_SP_SIZE               : STD_LOGIC;
    SIGNAL REG_R1_SP_ZOOM               : STD_LOGIC;
    SIGNAL REG_R1_VSYNC_INT_EN          : STD_LOGIC;
    SIGNAL REG_R1_DISP_ON               : STD_LOGIC;
    SIGNAL REG_R2_PT_NAM_ADDR           : STD_LOGIC_VECTOR(  6 DOWNTO 0 );
    SIGNAL REG_R4_PT_GEN_ADDR           : STD_LOGIC_VECTOR(  5 DOWNTO 0 );
    SIGNAL REG_R10R3_COL_ADDR           : STD_LOGIC_VECTOR( 10 DOWNTO 0 );
    SIGNAL REG_R11R5_SP_ATR_ADDR        : STD_LOGIC_VECTOR(  9 DOWNTO 0 );
    SIGNAL REG_R6_SP_GEN_ADDR           : STD_LOGIC_VECTOR(  5 DOWNTO 0 );
    SIGNAL REG_R7_FRAME_COL             : STD_LOGIC_VECTOR(  7 DOWNTO 0 );
    SIGNAL REG_R8_SP_OFF                : STD_LOGIC;
    SIGNAL REG_R8_COL0_ON               : STD_LOGIC;
    SIGNAL REG_R9_PAL_MODE              : STD_LOGIC;
    SIGNAL REG_R9_INTERLACE_MODE        : STD_LOGIC;
    SIGNAL REG_R9_Y_DOTS                : STD_LOGIC;
    SIGNAL REG_R12_BLINK_MODE           : STD_LOGIC_VECTOR(  7 DOWNTO 0 );
    SIGNAL REG_R13_BLINK_PERIOD         : STD_LOGIC_VECTOR(  7 DOWNTO 0 );
    SIGNAL REG_R18_ADJ                  : STD_LOGIC_VECTOR(  7 DOWNTO 0 );
    SIGNAL REG_R19_HSYNC_INT_LINE       : STD_LOGIC_VECTOR(  7 DOWNTO 0 );
    SIGNAL REG_R23_VSTART_LINE          : STD_LOGIC_VECTOR(  7 DOWNTO 0 );
    SIGNAL REG_R25_CMD                  : STD_LOGIC;
    SIGNAL REG_R25_YAE                  : STD_LOGIC;
    SIGNAL REG_R25_YJK                  : STD_LOGIC;
    SIGNAL REG_R25_MSK                  : STD_LOGIC;
    SIGNAL REG_R25_SP2                  : STD_LOGIC;
    SIGNAL REG_R26_H_SCROLL             : STD_LOGIC_VECTOR(  8 DOWNTO 3 );
    SIGNAL REG_R27_H_SCROLL             : STD_LOGIC_VECTOR(  2 DOWNTO 0 );

    SIGNAL VDPMODETEXT1                 : STD_LOGIC;    -- TEXT MODE 1      (SCREEN0 WIDTH 40)
    SIGNAL VDPMODETEXT2                 : STD_LOGIC;    -- TEXT MODE 2      (SCREEN0 WIDTH 80)
    SIGNAL VDPMODEMULTI                 : STD_LOGIC;    -- MULTICOLOR MODE(SCREEN3)
    SIGNAL VDPMODEGRAPHIC1              : STD_LOGIC;    -- GRAPHIC MODE 1 (SCREEN1)
    SIGNAL VDPMODEGRAPHIC2              : STD_LOGIC;    -- GRAPHIC MODE 2 (SCREEN2)
    SIGNAL VDPMODEGRAPHIC3              : STD_LOGIC;    -- GRAPHIC MODE 2 (SCREEN4)
    SIGNAL VDPMODEGRAPHIC4              : STD_LOGIC;    -- GRAPHIC MODE 4 (SCREEN5)
    SIGNAL VDPMODEGRAPHIC5              : STD_LOGIC;    -- GRAPHIC MODE 5 (SCREEN6)
    SIGNAL VDPMODEGRAPHIC6              : STD_LOGIC;    -- GRAPHIC MODE 6 (SCREEN7)
    SIGNAL VDPMODEGRAPHIC7              : STD_LOGIC;    -- GRAPHIC MODE 7 (SCREEN8,10,11,12)
    SIGNAL VDPMODEISHIGHRES             : STD_LOGIC;    -- TRUE WHEN MODE GRAPHIC5, 6
    SIGNAL VDPMODEISVRAMINTERLEAVE      : STD_LOGIC;    -- TRUE WHEN MODE GRAPHIC6, 7

    -- FOR TEXT 1 AND 2
    SIGNAL PRAMADRT12                   : STD_LOGIC_VECTOR( 16 DOWNTO 0 );
    SIGNAL COLORCODET12                 : STD_LOGIC_VECTOR(  3 DOWNTO 0 );
    SIGNAL TXVRAMREADEN                 : STD_LOGIC;

    -- FOR GRAPHIC 1,2,3 AND MULTI COLOR
    SIGNAL PRAMADRG123M                 : STD_LOGIC_VECTOR( 16 DOWNTO 0 );
    SIGNAL COLORCODEG123M               : STD_LOGIC_VECTOR(  3 DOWNTO 0 );

    -- FOR GRAPHIC 4,5,6,7
    SIGNAL PRAMADRG4567                 : STD_LOGIC_VECTOR( 16 DOWNTO 0 );
    SIGNAL COLORCODEG4567               : STD_LOGIC_VECTOR(  7 DOWNTO 0 );
    SIGNAL YJK_R                        : STD_LOGIC_VECTOR(  5 DOWNTO 0 );
    SIGNAL YJK_G                        : STD_LOGIC_VECTOR(  5 DOWNTO 0 );
    SIGNAL YJK_B                        : STD_LOGIC_VECTOR(  5 DOWNTO 0 );
    SIGNAL YJK_EN                       : STD_LOGIC;

    -- SPRITE
    SIGNAL SPMODE2                      : STD_LOGIC;
    SIGNAL SPVRAMACCESSING              : STD_LOGIC;
    SIGNAL PRAMADRSPRITE                : STD_LOGIC_VECTOR( 16 DOWNTO 0 );
    SIGNAL SPRITECOLOROUT               : STD_LOGIC;
    SIGNAL COLORCODESPRITE              : STD_LOGIC_VECTOR(  3 DOWNTO 0 );
    SIGNAL VDPS0SPCOLLISIONINCIDENCE    : STD_LOGIC;
    SIGNAL VDPS0SPOVERMAPPED            : STD_LOGIC;
    SIGNAL VDPS0SPOVERMAPPEDNUM         : STD_LOGIC_VECTOR(  4 DOWNTO 0 );
    SIGNAL VDPS3S4SPCOLLISIONX          : STD_LOGIC_VECTOR(  8 DOWNTO 0 );
    SIGNAL VDPS5S6SPCOLLISIONY          : STD_LOGIC_VECTOR(  8 DOWNTO 0 );
    SIGNAL SPVDPS0RESETREQ              : STD_LOGIC;
    SIGNAL SPVDPS0RESETACK              : STD_LOGIC;
    SIGNAL SPVDPS5RESETREQ              : STD_LOGIC;
    SIGNAL SPVDPS5RESETACK              : STD_LOGIC;

    -- PALETTE REGISTERS
    SIGNAL PALETTEADDR_OUT              : STD_LOGIC_VECTOR(  3 DOWNTO 0 );
    SIGNAL PALETTEDATARB_OUT            : STD_LOGIC_VECTOR(  7 DOWNTO 0 );
    SIGNAL PALETTEDATAG_OUT             : STD_LOGIC_VECTOR(  7 DOWNTO 0 );

    -- VDP COMMAND SIGNALS - CAN BE READ & SET BY CPU
    SIGNAL VDPCMDCLR                    : STD_LOGIC_VECTOR(  7 DOWNTO 0 );  -- R44, S#7
    -- VDP COMMAND SIGNALS - CAN BE READ BY CPU
    SIGNAL VDPCMDCE                     : STD_LOGIC;    -- S#2 (BIT 0)
    SIGNAL VDPCMDBD                     : STD_LOGIC;    -- S#2 (BIT 4)
    SIGNAL VDPCMDTR                     : STD_LOGIC;    -- S#2 (BIT 7)
    SIGNAL VDPCMDSXTMP                  : STD_LOGIC_VECTOR( 10 DOWNTO 0 ); -- S#8,S#9

    SIGNAL VDPCMDREGNUM                 : STD_LOGIC_VECTOR(  3 DOWNTO 0 );
    SIGNAL VDPCMDREGDATA                : STD_LOGIC_VECTOR(  7 DOWNTO 0 );
    SIGNAL VDPCMDREGWRACK               : STD_LOGIC;
    SIGNAL VDPCMDTRCLRACK               : STD_LOGIC;
    SIGNAL VDPCMDVRAMWRACK              : STD_LOGIC;
    SIGNAL VDPCMDVRAMRDACK              : STD_LOGIC;
    SIGNAL VDPCMDVRAMREADINGR           : STD_LOGIC;
    SIGNAL VDPCMDVRAMREADINGA           : STD_LOGIC;
    SIGNAL VDPCMDVRAMRDDATA             : STD_LOGIC_VECTOR(  7 DOWNTO 0 );
    SIGNAL VDPCMDREGWRREQ               : STD_LOGIC;
    SIGNAL VDPCMDTRCLRREQ               : STD_LOGIC;
    SIGNAL VDPCMDVRAMWRREQ              : STD_LOGIC;
    SIGNAL VDPCMDVRAMRDREQ              : STD_LOGIC;
    SIGNAL VDPCMDVRAMACCESSADDR         : STD_LOGIC_VECTOR( 16 DOWNTO 0 );
    SIGNAL VDPCMDVRAMWRDATA             : STD_LOGIC_VECTOR(  7 DOWNTO 0 );

    SIGNAL VDP_COMMAND_DRIVE            : STD_LOGIC;
    SIGNAL VDP_COMMAND_ACTIVE           : STD_LOGIC;
    SIGNAL CUR_VDP_COMMAND              : STD_LOGIC_VECTOR(  7 DOWNTO 4 );

    -- VIDEO OUTPUT SIGNALS
    SIGNAL IVIDEOR                      : STD_LOGIC_VECTOR(  5 DOWNTO 0 );
    SIGNAL IVIDEOG                      : STD_LOGIC_VECTOR(  5 DOWNTO 0 );
    SIGNAL IVIDEOB                      : STD_LOGIC_VECTOR(  5 DOWNTO 0 );

    SIGNAL IVIDEOR_VDP                  : STD_LOGIC_VECTOR(  5 DOWNTO 0 );
    SIGNAL IVIDEOG_VDP                  : STD_LOGIC_VECTOR(  5 DOWNTO 0 );
    SIGNAL IVIDEOB_VDP                  : STD_LOGIC_VECTOR(  5 DOWNTO 0 );
    SIGNAL IVIDEOVS_N                   : STD_LOGIC;

    SIGNAL IVIDEOR_NTSC_PAL             : STD_LOGIC_VECTOR(  5 DOWNTO 0 );
    SIGNAL IVIDEOG_NTSC_PAL             : STD_LOGIC_VECTOR(  5 DOWNTO 0 );
    SIGNAL IVIDEOB_NTSC_PAL             : STD_LOGIC_VECTOR(  5 DOWNTO 0 );
    SIGNAL IVIDEOHS_N_NTSC_PAL          : STD_LOGIC;
    SIGNAL IVIDEOVS_N_NTSC_PAL          : STD_LOGIC;

    SIGNAL IVIDEOR_VGA                  : STD_LOGIC_VECTOR(  5 DOWNTO 0 );
    SIGNAL IVIDEOG_VGA                  : STD_LOGIC_VECTOR(  5 DOWNTO 0 );
    SIGNAL IVIDEOB_VGA                  : STD_LOGIC_VECTOR(  5 DOWNTO 0 );
    SIGNAL IVIDEOHS_N_VGA               : STD_LOGIC;
    SIGNAL IVIDEOVS_N_VGA               : STD_LOGIC;

    SIGNAL IRAMADR                      : STD_LOGIC_VECTOR( 16 DOWNTO 0 );
    SIGNAL PRAMDAT                      : STD_LOGIC_VECTOR(  7 DOWNTO 0 );
    SIGNAL XRAMSEL                      : STD_LOGIC;
    SIGNAL PRAMDATPAIR                  : STD_LOGIC_VECTOR(  7 DOWNTO 0 );

    SIGNAL HSYNC                        : STD_LOGIC;
    SIGNAL ENAHSYNC                     : STD_LOGIC;
    SIGNAL FF_BWINDOW_Y_DL              : STD_LOGIC;

    CONSTANT VRAM_ACCESS_IDLE           : INTEGER := 0;
    CONSTANT VRAM_ACCESS_DRAW           : INTEGER := 1;
    CONSTANT VRAM_ACCESS_CPUW           : INTEGER := 2;
    CONSTANT VRAM_ACCESS_CPUR           : INTEGER := 3;
    CONSTANT VRAM_ACCESS_SPRT           : INTEGER := 4;
    CONSTANT VRAM_ACCESS_VDPW           : INTEGER := 5;
    CONSTANT VRAM_ACCESS_VDPR           : INTEGER := 6;
    CONSTANT VRAM_ACCESS_VDPS           : INTEGER := 7;
BEGIN

    PRAMADR     <=  IRAMADR;
    XRAMSEL     <=  IRAMADR(16);
    PRAMDAT     <=  PRAMDBI(  7 DOWNTO 0 ) WHEN( XRAMSEL = '0' )ELSE
                    PRAMDBI( 15 DOWNTO 8 );
    PRAMDATPAIR <=  PRAMDBI(  7 DOWNTO 0 ) WHEN( XRAMSEL = '1' )ELSE
                    PRAMDBI( 15 DOWNTO 8 );

    ----------------------------------------------------------------
    -- DISPLAY COMPONENTS
    ----------------------------------------------------------------
    DISPMODEVGA     <=  DISPRESO;   -- DISPLAY RESOLUTION (0=15KHZ, 1=31KHZ)

--  VDPR9PALMODE    <=  REG_R9_PAL_MODE     WHEN( NTSC_PAL_TYPE = '1' AND LEGACY_VGA = '0' )ELSE
    VDPR9PALMODE    <=  REG_R9_PAL_MODE     WHEN( NTSC_PAL_TYPE = '1' )ELSE
                        FORCED_V_MODE;

    IVIDEOR <=  (OTHERS => '0') WHEN( BWINDOW = '0' )ELSE
                IVIDEOR_VDP;
    IVIDEOG <=  (OTHERS => '0') WHEN( BWINDOW = '0' )ELSE
                IVIDEOG_VDP;
    IVIDEOB <=  (OTHERS => '0') WHEN( BWINDOW = '0' )ELSE
                IVIDEOB_VDP;

    U_VDP_NTSC_PAL: work.VDP_NTSC_PAL
    PORT MAP(
        CLK21M              => CLK21M,
        RESET               => RESET,
        PALMODE             => VDPR9PALMODE,
        INTERLACEMODE       => REG_R9_INTERLACE_MODE,
        VIDEORIN            => IVIDEOR,
        VIDEOGIN            => IVIDEOG,
        VIDEOBIN            => IVIDEOB,
        VIDEOVSIN_N         => IVIDEOVS_N,
        HCOUNTERIN          => H_CNT,
        VCOUNTERIN          => V_CNT,
        VIDEOROUT           => IVIDEOR_NTSC_PAL,
        VIDEOGOUT           => IVIDEOG_NTSC_PAL,
        VIDEOBOUT           => IVIDEOB_NTSC_PAL,
        VIDEOHSOUT_N        => IVIDEOHS_N_NTSC_PAL,
        VIDEOVSOUT_N        => IVIDEOVS_N_NTSC_PAL
    );

    U_VDP_VGA: work.VDP_VGA
    PORT MAP(
        CLK21M              => CLK21M,
        RESET               => RESET,
        VIDEORIN            => IVIDEOR,
        VIDEOGIN            => IVIDEOG,
        VIDEOBIN            => IVIDEOB,
        VIDEOVSIN_N         => IVIDEOVS_N,
        HCOUNTERIN          => H_CNT,
        VCOUNTERIN          => V_CNT,
        PALMODE             => VDPR9PALMODE,
        INTERLACEMODE       => REG_R9_INTERLACE_MODE,
        LEGACY_VGA          => LEGACY_VGA,
        VIDEOROUT           => IVIDEOR_VGA,
        VIDEOGOUT           => IVIDEOG_VGA,
        VIDEOBOUT           => IVIDEOB_VGA,
        VIDEODEOUT          => BWINDOW_VGA,
        VIDEOHSOUT_N        => IVIDEOHS_N_VGA,
        VIDEOVSOUT_N        => IVIDEOVS_N_VGA,
        RATIOMODE           => RATIOMODE
    );

    -- CHANGE DISPLAY MODE BY EXTERNAL INPUT PORT.
    PVIDEOR     <=  IVIDEOR_NTSC_PAL WHEN( DISPMODEVGA = '0' )ELSE
                    IVIDEOR_VGA;
    PVIDEOG     <=  IVIDEOG_NTSC_PAL WHEN( DISPMODEVGA = '0' )ELSE
                    IVIDEOG_VGA;
    PVIDEOB     <=  IVIDEOB_NTSC_PAL WHEN( DISPMODEVGA = '0' )ELSE
                    IVIDEOB_VGA;

    PVIDEODE    <=  BWINDOW WHEN( DISPMODEVGA = '0' ) ELSE
                    BWINDOW_VGA;

    -- H SYNC SIGNAL
    PVIDEOHS_N  <=  IVIDEOHS_N_NTSC_PAL WHEN( DISPMODEVGA = '0' )ELSE
                    IVIDEOHS_N_VGA;
    -- V SYNC SIGNAL
    PVIDEOVS_N  <=  IVIDEOVS_N_NTSC_PAL WHEN( DISPMODEVGA = '0' )ELSE
                    IVIDEOVS_N_VGA;

    -- THESE SIGNALS BELOW ARE OUTPUT DIRECTLY REGARDLESS OF DISPLAY MODE.
    PVIDEOCS_N  <= NOT (IVIDEOHS_N_NTSC_PAL XOR IVIDEOVS_N_NTSC_PAL);

    -----------------------------------------------------------------------------
    -- INTERRUPT
    -----------------------------------------------------------------------------

    -- VSYNC INTERRUPT
    VSYNCINT_N  <=  '1' WHEN( REG_R1_VSYNC_INT_EN = '0' )ELSE
                    REQ_VSYNC_INT_N;

    -- HSYNC INTERRUPT
    HSYNCINT_N  <=  '1' WHEN( REG_R0_HSYNC_INT_EN = '0' OR ENAHSYNC = '0' )ELSE
                    REQ_HSYNC_INT_N;

    INT_N       <=  '0' WHEN( VSYNCINT_N = '0' OR HSYNCINT_N = '0' )ELSE
                    '1';

    U_INTERRUPT: work.VDP_INTERRUPT
    PORT MAP (
        RESET                   => RESET                        ,
        CLK21M                  => CLK21M                       ,

        H_CNT                   => H_CNT                        ,
        Y_CNT                   => PREDOTCOUNTER_Y(7 DOWNTO 0)  ,
        ACTIVE_LINE             => ACTIVE_LINE                  ,
        V_BLANKING_START        => V_BLANKING_START             ,
        CLR_VSYNC_INT           => CLR_VSYNC_INT                ,
        CLR_HSYNC_INT           => CLR_HSYNC_INT                ,
        REQ_VSYNC_INT_N         => REQ_VSYNC_INT_N              ,
        REQ_HSYNC_INT_N         => REQ_HSYNC_INT_N              ,
        REG_R19_HSYNC_INT_LINE  => REG_R19_HSYNC_INT_LINE
    );

    PROCESS( CLK21M )
    BEGIN
        IF( CLK21M'EVENT AND CLK21M = '1' )THEN
            IF( PREDOTCOUNTER_X = 255 )THEN
                ACTIVE_LINE <= '1';
            ELSE
                ACTIVE_LINE <= '0';
            END IF;
        END IF;
    END PROCESS;

    -----------------------------------------------------------------------------
    -- SYNCHRONOUS SIGNAL GENERATOR
    -----------------------------------------------------------------------------
    U_SSG: work.VDP_SSG
    PORT MAP(
        RESET                   => RESET                    ,
        CLK21M                  => CLK21M                   ,

        H_CNT                   => H_CNT                    ,
        V_CNT                   => V_CNT                    ,
        DOTSTATE                => DOTSTATE                 ,
        EIGHTDOTSTATE           => EIGHTDOTSTATE            ,
        PREDOTCOUNTER_X         => PREDOTCOUNTER_X          ,
        PREDOTCOUNTER_Y         => PREDOTCOUNTER_Y          ,
        PREDOTCOUNTER_YP        => PREDOTCOUNTER_YP         ,
        PREWINDOW_Y             => PREWINDOW_Y              ,
        PREWINDOW_Y_SP          => PREWINDOW_Y_SP           ,
        FIELD                   => FIELD                    ,
        WINDOW_X                => WINDOW_X                 ,
        PVIDEODHCLK             => PVIDEODHCLK              ,
        PVIDEODLCLK             => PVIDEODLCLK              ,
        IVIDEOVS_N              => IVIDEOVS_N               ,

        HD                      => HD                       ,
        VD                      => VD                       ,
        HSYNC                   => HSYNC                    ,
        ENAHSYNC                => ENAHSYNC                 ,
        V_BLANKING_START        => V_BLANKING_START         ,

        VDPR9PALMODE            => VDPR9PALMODE             ,
        REG_R9_INTERLACE_MODE   => REG_R9_INTERLACE_MODE    ,
        REG_R9_Y_DOTS           => REG_R9_Y_DOTS            ,
        REG_R18_ADJ             => REG_R18_ADJ              ,
        REG_R23_VSTART_LINE     => REG_R23_VSTART_LINE      ,
        REG_R25_MSK             => REG_R25_MSK              ,
        REG_R27_H_SCROLL        => REG_R27_H_SCROLL         ,
        REG_R25_YJK             => REG_R25_YJK              ,
        CENTERYJK_R25_N         => CENTERYJK_R25_N
    );

    -- GENERATE BWINDOW
    PROCESS( RESET, CLK21M )
    BEGIN
        IF( RISING_EDGE(CLK21M) )THEN
            IF( RESET = '1' )THEN
                BWINDOW_X <= '0';
	    ELSE
                IF( H_CNT = 200 ) THEN
                    BWINDOW_X <= '1';
                ELSIF( H_CNT = CLOCKS_PER_LINE-1-1 )THEN
                    BWINDOW_X <= '0';
                END IF;
            END IF;
        END IF;
    END PROCESS;

    PROCESS( RESET, CLK21M )
    BEGIN
        IF( CLK21M'EVENT AND CLK21M = '1' )THEN
            IF( RESET = '1' )THEN
                BWINDOW_Y <= '0';
	    ELSE
                IF( REG_R9_INTERLACE_MODE='0' ) THEN
                    -- NON-INTERLACE
                    -- 3+3+16 = 19
                    IF( (V_CNT = 20*2) OR
                            ((V_CNT = 524+20*2) AND (VDPR9PALMODE = '0')) OR
                            ((V_CNT = 626+20*2) AND (VDPR9PALMODE = '1')) ) THEN
                        BWINDOW_Y <= '1';
                    ELSIF(  ((V_CNT = 524) AND (VDPR9PALMODE = '0')) OR
                            ((V_CNT = 626) AND (VDPR9PALMODE = '1')) OR
                             (V_CNT = 0) ) THEN
                        BWINDOW_Y <= '0';
                    END IF;
                ELSE
                    -- INTERLACE
                    IF( (V_CNT = 20*2) OR
                            -- +1 SHOULD BE NEEDED.
                            -- BECAUSE ODD FIELD'S START IS DELAYED HALF LINE.
                            -- SO THE START POSITION OF DISPLAY TIME SHOULD BE
                            -- DELAYED MORE HALF LINE.
                            ((V_CNT = 525+20*2 + 1) AND (VDPR9PALMODE = '0')) OR
                            ((V_CNT = 625+20*2 + 1) AND (VDPR9PALMODE = '1')) ) THEN
                        BWINDOW_Y <= '1';
                    ELSIF(  ((V_CNT = 525) AND (VDPR9PALMODE = '0')) OR
                            ((V_CNT = 625) AND (VDPR9PALMODE = '1')) OR
                             (V_CNT = 0) ) THEN
                        BWINDOW_Y <= '0';
                    END IF;
                END IF;

            END IF;
        END IF;
    END PROCESS;

    PROCESS( RESET, CLK21M )
    BEGIN
        IF( CLK21M'EVENT AND CLK21M = '1' )THEN
            IF( RESET = '1' )THEN
                BWINDOW <= '0';
	    ELSE
                BWINDOW <= BWINDOW_X AND BWINDOW_Y;
            END IF;
        END IF;
    END PROCESS;

    -- GENERATE PREWINDOW, WINDOW
    WINDOW      <=  WINDOW_X    AND PREWINDOW_Y;
    PREWINDOW   <=  PREWINDOW_X AND PREWINDOW_Y;

    PROCESS( RESET, CLK21M )
    BEGIN
        IF( RISING_EDGE(CLK21M) )THEN
            IF( RESET = '1' )THEN
                PREWINDOW_X <= '0';
	    ELSE
                IF( (H_CNT = ("00" & (OFFSET_X + LED_TV_X_NTSC - ((REG_R25_MSK AND (NOT CENTERYJK_R25_N)) & "00") + 4) & "10") AND REG_R25_YJK = '1' AND CENTERYJK_R25_N = '1' AND VDPR9PALMODE = '0') OR
                    (H_CNT = ("00" & (OFFSET_X + LED_TV_X_NTSC - ((REG_R25_MSK AND (NOT CENTERYJK_R25_N)) & "00")    ) & "10") AND (REG_R25_YJK = '0' OR CENTERYJK_R25_N = '0') AND VDPR9PALMODE = '0') OR
                    (H_CNT = ("00" & (OFFSET_X + LED_TV_X_PAL - ((REG_R25_MSK AND (NOT CENTERYJK_R25_N)) & "00") + 4) & "10") AND REG_R25_YJK = '1' AND CENTERYJK_R25_N = '1' AND VDPR9PALMODE = '1') OR
                    (H_CNT = ("00" & (OFFSET_X + LED_TV_X_PAL - ((REG_R25_MSK AND (NOT CENTERYJK_R25_N)) & "00")    ) & "10") AND (REG_R25_YJK = '0' OR CENTERYJK_R25_N = '0') AND VDPR9PALMODE = '1') )THEN
                    -- HOLD
                ELSIF( H_CNT(1 DOWNTO 0) = "10") THEN
                    IF( PREDOTCOUNTER_X = "111111111" ) THEN
                        -- JP: PREDOTCOUNTER_X �� -1����0�ɃJ�E���g�A�b�v���鎞��WINDOW��1�ɂ���
                        PREWINDOW_X <= '1';
                    ELSIF( PREDOTCOUNTER_X = "011111111" ) THEN
                        PREWINDOW_X <= '0';
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    ------------------------------------------------------------------------------
    -- main process
    ------------------------------------------------------------------------------
    PROCESS( RESET, CLK21M )
    BEGIN
        IF( RISING_EDGE(CLK21M) )THEN
            IF( RESET = '1' )THEN
                VDPVRAMRDDATA   <= (OTHERS => '0');
                VDPVRAMREADINGA <= '0';
	    ELSE
                IF( DOTSTATE = "01" )THEN
                    IF( VDPVRAMREADINGR /= VDPVRAMREADINGA ) THEN
                        VDPVRAMRDDATA   <= PRAMDAT;
                        VDPVRAMREADINGA <= NOT VDPVRAMREADINGA;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    PROCESS( RESET, CLK21M )
    BEGIN
        IF( RISING_EDGE(CLK21M) )THEN
            IF( RESET = '1' )THEN
                VDPCMDVRAMRDDATA    <= (OTHERS => '0');
                VDPCMDVRAMRDACK     <= '0';
                VDPCMDVRAMREADINGA  <= '0';
	    ELSE
                IF( DOTSTATE = "01" )THEN
                    IF( VDPCMDVRAMREADINGR /= VDPCMDVRAMREADINGA )THEN
                        VDPCMDVRAMRDDATA    <= PRAMDAT;
                        VDPCMDVRAMRDACK     <= NOT VDPCMDVRAMRDACK;
                        VDPCMDVRAMREADINGA  <= NOT VDPCMDVRAMREADINGA;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    PROCESS( RESET, CLK21M )
        VARIABLE VDPVRAMACCESSADDRV : STD_LOGIC_VECTOR( 16 DOWNTO 0 );
        VARIABLE VRAMACCESSSWITCH   : INTEGER RANGE 0 TO 7;
    BEGIN
        IF (RISING_EDGE(CLK21M)) THEN
            IF (RESET = '1') THEN

                IRAMADR <= (OTHERS => '1');
                PRAMDBO <= (OTHERS => '1');
                PRAMOE_N <= '1';
                PRAMWE_N <= '1';

                VDPVRAMREADINGR <= '0';

                VDPVRAMRDACK <= '0';
                VDPVRAMWRACK <= '0';
                VDPVRAMADDRSETACK <= '0';
                VDPVRAMACCESSADDR <= (OTHERS => '0');

                VDPCMDVRAMWRACK <= '0';
                VDPCMDVRAMREADINGR <= '0';
                VDP_COMMAND_DRIVE <= '0';

	    else

                ------------------------------------------
                -- MAIN STATE
                ------------------------------------------
                --
                -- VRAM ACCESS ARBITER.
                --
                -- VRAM�A�N�Z�X�^�C�~���O���AEIGHTDOTSTATE �ɂ���Đ��䂵�Ă���
                IF( DOTSTATE = "10" ) THEN
                    IF( (PREWINDOW = '1') AND (REG_R1_DISP_ON = '1') AND
                        ((EIGHTDOTSTATE="000") OR (EIGHTDOTSTATE="001") OR (EIGHTDOTSTATE="010") OR
                         (EIGHTDOTSTATE="011") OR (EIGHTDOTSTATE="100")) ) THEN
                        --  EIGHTDOTSTATE �� 0�`4 �ŁA�\�����̏ꍇ
                        VRAMACCESSSWITCH := VRAM_ACCESS_DRAW;
                    ELSIF( (PREWINDOW = '1') AND (REG_R1_DISP_ON = '1') AND
                            (TXVRAMREADEN = '1')) THEN
                        --  EIGHTDOTSTATE �� 5�`7 �ŁA�\�����ŁA�e�L�X�g���[�h�̏ꍇ
                        VRAMACCESSSWITCH := VRAM_ACCESS_DRAW;
                    ELSIF( (PREWINDOW_X = '1') AND (PREWINDOW_Y_SP = '1') AND (SPVRAMACCESSING = '1') AND
                            (EIGHTDOTSTATE="101") AND (VDPMODETEXT1 = '0') AND (VDPMODETEXT2 = '0') ) THEN
                        -- FOR SPRITE Y-TESTING
                        VRAMACCESSSWITCH := VRAM_ACCESS_SPRT;
                    ELSIF( (PREWINDOW_X = '0') AND (PREWINDOW_Y_SP = '1') AND (SPVRAMACCESSING = '1') AND
                            (VDPMODETEXT1 = '0') AND (VDPMODETEXT2 = '0') AND
                            ((EIGHTDOTSTATE="000") OR (EIGHTDOTSTATE="001") OR (EIGHTDOTSTATE="010") OR
                            (EIGHTDOTSTATE="011") OR (EIGHTDOTSTATE="100") OR (EIGHTDOTSTATE="101")) ) THEN
                        -- FOR SPRITE PREPAREING
                        VRAMACCESSSWITCH := VRAM_ACCESS_SPRT;
                    ELSIF( VDPVRAMWRREQ /= VDPVRAMWRACK )THEN
                        -- VRAM WRITE REQUEST BY CPU
                        VRAMACCESSSWITCH := VRAM_ACCESS_CPUW;
                    ELSIF( VDPVRAMRDREQ /= VDPVRAMRDACK )THEN
                        -- VRAM READ REQUEST BY CPU
                        VRAMACCESSSWITCH := VRAM_ACCESS_CPUR;
--                  ELSIF( EIGHTDOTSTATE="111" )THEN
                    ELSE
                        -- VDP COMMAND
                        IF( VDP_COMMAND_ACTIVE = '1' )THEN
                            IF( VDPCMDVRAMWRREQ /= VDPCMDVRAMWRACK )THEN
                                VRAMACCESSSWITCH := VRAM_ACCESS_VDPW;
                            ELSIF( VDPCMDVRAMRDREQ /= VDPCMDVRAMRDACK )THEN
                                VRAMACCESSSWITCH := VRAM_ACCESS_VDPR;
                            ELSE
                                VRAMACCESSSWITCH := VRAM_ACCESS_VDPS;
                            END IF;
                        ELSE
                            VRAMACCESSSWITCH := VRAM_ACCESS_VDPS;
                        END IF;
                    END IF;
                ELSE
                    VRAMACCESSSWITCH := VRAM_ACCESS_DRAW;
                END IF;

                IF( VRAMACCESSSWITCH = VRAM_ACCESS_VDPW OR
                    VRAMACCESSSWITCH = VRAM_ACCESS_VDPR OR
                    VRAMACCESSSWITCH = VRAM_ACCESS_VDPS )THEN
                    VDP_COMMAND_DRIVE <= '1';
                ELSE
                    VDP_COMMAND_DRIVE <= '0';
                END IF;

                --
                -- VRAM ACCESS ADDRESS SWITCH
                --
                IF( VRAMACCESSSWITCH = VRAM_ACCESS_CPUW )THEN
                    -- VRAM WRITE BY CPU
                    -- JP: GRAPHIC6,7�ł�VRAM���̃A�h���X�� RAM���̃A�h���X�̊֌W��
                    -- JP: ���̉��ʃ��[�h�ƈق��̂Œ���
                    IF( (VDPMODEGRAPHIC6 = '1') OR (VDPMODEGRAPHIC7 = '1') )THEN
                        IRAMADR <= VDPVRAMACCESSADDR(0) & VDPVRAMACCESSADDR(16 DOWNTO 1);
                    ELSE
                        IRAMADR <= VDPVRAMACCESSADDR;
                    END IF;
                    IF( (VDPMODETEXT1 = '1') OR (VDPMODEMULTI = '1') OR
                        (VDPMODEGRAPHIC1 = '1') OR (VDPMODEGRAPHIC2 = '1') ) THEN
                        VDPVRAMACCESSADDR(13 DOWNTO 0) <= VDPVRAMACCESSADDR(13 DOWNTO 0) + 1;
                    ELSE
                        VDPVRAMACCESSADDR <= VDPVRAMACCESSADDR + 1;
                    END IF;
                    PRAMDBO <= VDPVRAMACCESSDATA;
                    PRAMOE_N <= '1';
                    PRAMWE_N <= '0';
                    VDPVRAMWRACK <= NOT VDPVRAMWRACK;
                ELSIF( VRAMACCESSSWITCH = VRAM_ACCESS_CPUR ) THEN
                    -- VRAM READ BY CPU
                    IF( VDPVRAMADDRSETREQ /= VDPVRAMADDRSETACK ) THEN
                        VDPVRAMACCESSADDRV := VDPVRAMACCESSADDRTMP;
                        -- CLEAR VRAM ADDRESS SET REQUEST SIGNAL
                        VDPVRAMADDRSETACK <= NOT VDPVRAMADDRSETACK;
                    ELSE
                        VDPVRAMACCESSADDRV := VDPVRAMACCESSADDR;
                    END IF;

                    -- JP: GRAPHIC6,7�ł�VRAM���̃A�h���X�� RAM���̃A�h���X�̊֌W��
                    -- JP: ���̉��ʃ��[�h�ƈق��̂Œ���
                    IF( (VDPMODEGRAPHIC6 = '1') OR (VDPMODEGRAPHIC7 = '1') )THEN
                        IRAMADR <= VDPVRAMACCESSADDRV(0) & VDPVRAMACCESSADDRV(16 DOWNTO 1);
                    ELSE
                        IRAMADR <= VDPVRAMACCESSADDRV;
                    END IF;
                    IF( (VDPMODETEXT1 = '1') OR (VDPMODEMULTI = '1') OR
                        (VDPMODEGRAPHIC1 = '1') OR (VDPMODEGRAPHIC2 = '1') )THEN
                        VDPVRAMACCESSADDR(13 DOWNTO 0) <= VDPVRAMACCESSADDRV(13 DOWNTO 0) + 1;
                    ELSE
                        VDPVRAMACCESSADDR <= VDPVRAMACCESSADDRV + 1;
                    END IF;
                    PRAMDBO <= (OTHERS => '1');
                    PRAMOE_N <= '0';
                    PRAMWE_N <= '1';
                    VDPVRAMRDACK <= NOT VDPVRAMRDACK;
                    VDPVRAMREADINGR <= NOT VDPVRAMREADINGA;
                ELSIF( VRAMACCESSSWITCH = VRAM_ACCESS_VDPW )THEN
                    -- VRAM WRITE BY VDP COMMAND
                    -- VDP COMMAND WRITE VRAM.
                    -- JP: GRAPHIC6,7�ł̓A�h���X�� RAM���̈ʒu�����̉��ʃ��[�h��
                    -- JP: �ق��̂Œ���
                    IF( (VDPMODEGRAPHIC6 = '1') OR (VDPMODEGRAPHIC7 = '1') )THEN
                        IRAMADR <= VDPCMDVRAMACCESSADDR(0) & VDPCMDVRAMACCESSADDR(16 DOWNTO 1);
                    ELSE
                        IRAMADR <= VDPCMDVRAMACCESSADDR;
                    END IF;
                    PRAMDBO <= VDPCMDVRAMWRDATA;
                    PRAMOE_N <= '1';
                    PRAMWE_N <= '0';
                    VDPCMDVRAMWRACK <= NOT VDPCMDVRAMWRACK;
                ELSIF( VRAMACCESSSWITCH = VRAM_ACCESS_VDPR )THEN
                    -- VRAM READ BY VDP COMMAND
                    -- JP: GRAPHIC6,7�ł̓A�h���X�� RAM���̈ʒu�����̉��ʃ��[�h��
                    -- JP: �ق��̂Œ���
                    IF( (VDPMODEGRAPHIC6 = '1') OR (VDPMODEGRAPHIC7 = '1') )THEN
                        IRAMADR <= VDPCMDVRAMACCESSADDR(0) & VDPCMDVRAMACCESSADDR(16 DOWNTO 1);
                    ELSE
                        IRAMADR <= VDPCMDVRAMACCESSADDR;
                    END IF;
                    PRAMDBO <= (OTHERS => '1');
                    PRAMOE_N <= '0';
                    PRAMWE_N <= '1';
                    VDPCMDVRAMREADINGR <= NOT VDPCMDVRAMREADINGA;
                ELSIF( VRAMACCESSSWITCH = VRAM_ACCESS_SPRT )THEN
                    -- VRAM READ BY SPRITE MODULE
                    IRAMADR <= PRAMADRSPRITE;
                    PRAMOE_N <= '0';
                    PRAMWE_N <= '1';
                    PRAMDBO <= (OTHERS => '1');
                ELSE
                    -- VRAM_ACCESS_DRAW
                    -- VRAM READ FOR SCREEN IMAGE BUILDING
                    CASE DOTSTATE IS
                        WHEN "10" =>
                            PRAMDBO <= (OTHERS => '1' );
                            PRAMOE_N <= '0';
                            PRAMWE_N <= '1';
                            IF( (VDPMODETEXT1 = '1') OR (VDPMODETEXT2 = '1') )THEN
                                IRAMADR <= PRAMADRT12;
                            ELSIF(  (VDPMODEGRAPHIC1 = '1') OR (VDPMODEGRAPHIC2 = '1') OR
                                    (VDPMODEGRAPHIC3 = '1') OR (VDPMODEMULTI = '1') )THEN
                                IRAMADR <= PRAMADRG123M;
                            ELSIF(  (VDPMODEGRAPHIC4 = '1') OR (VDPMODEGRAPHIC5 = '1') OR
                                    (VDPMODEGRAPHIC6 = '1') OR (VDPMODEGRAPHIC7 = '1') )THEN
                                IRAMADR <= PRAMADRG4567;
                            END IF;
                        WHEN "01" =>
                            PRAMDBO <= (OTHERS => '1' );
                            PRAMOE_N <= '0';
                            PRAMWE_N <= '1';
                            IF( (VDPMODEGRAPHIC6 = '1') OR (VDPMODEGRAPHIC7 = '1') )THEN
                                IRAMADR <= PRAMADRG4567;
                            END IF;
                        WHEN OTHERS =>
                            NULL;
                    END CASE;

                    IF( (DOTSTATE = "11") AND (VDPVRAMADDRSETREQ /= VDPVRAMADDRSETACK) )THEN
                        VDPVRAMACCESSADDR <= VDPVRAMACCESSADDRTMP;
                        VDPVRAMADDRSETACK <= NOT VDPVRAMADDRSETACK;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -----------------------------------------------------------------------
    -- COLOR DECODING
    -------------------------------------------------------------------------
    U_VDP_COLORDEC: work.VDP_COLORDEC
    PORT MAP(
        RESET               => RESET                ,
        CLK21M              => CLK21M               ,

        DOTSTATE            => DOTSTATE             ,

        PPALETTEADDR_OUT    => PALETTEADDR_OUT      ,
        PALETTEDATARB_OUT   => PALETTEDATARB_OUT    ,
        PALETTEDATAG_OUT    => PALETTEDATAG_OUT     ,

        VDPMODETEXT1        => VDPMODETEXT1         ,
        VDPMODETEXT2        => VDPMODETEXT2         ,
        VDPMODEMULTI        => VDPMODEMULTI         ,
        VDPMODEGRAPHIC1     => VDPMODEGRAPHIC1      ,
        VDPMODEGRAPHIC2     => VDPMODEGRAPHIC2      ,
        VDPMODEGRAPHIC3     => VDPMODEGRAPHIC3      ,
        VDPMODEGRAPHIC4     => VDPMODEGRAPHIC4      ,
        VDPMODEGRAPHIC5     => VDPMODEGRAPHIC5      ,
        VDPMODEGRAPHIC6     => VDPMODEGRAPHIC6      ,
        VDPMODEGRAPHIC7     => VDPMODEGRAPHIC7      ,

        WINDOW              => WINDOW               ,
        SPRITECOLOROUT      => SPRITECOLOROUT       ,
        COLORCODET12        => COLORCODET12         ,
        COLORCODEG123M      => COLORCODEG123M       ,
        COLORCODEG4567      => COLORCODEG4567       ,
        COLORCODESPRITE     => COLORCODESPRITE      ,
        P_YJK_R             => YJK_R                ,
        P_YJK_G             => YJK_G                ,
        P_YJK_B             => YJK_B                ,
        P_YJK_EN            => YJK_EN               ,

        PVIDEOR_VDP         => IVIDEOR_VDP          ,
        PVIDEOG_VDP         => IVIDEOG_VDP          ,
        PVIDEOB_VDP         => IVIDEOB_VDP          ,

        REG_R1_DISP_ON      => REG_R1_DISP_ON       ,
        REG_R7_FRAME_COL    => REG_R7_FRAME_COL     ,
        REG_R8_COL0_ON      => REG_R8_COL0_ON       ,
        REG_R25_YJK         => REG_R25_YJK
    );

    -----------------------------------------------------------------------------
    -- MAKE COLOR CODE
    -----------------------------------------------------------------------------
    U_VDP_TEXT12: work.VDP_TEXT12
    PORT MAP(
        CLK21M                      => CLK21M,
        RESET                       => RESET,
        DOTSTATE                    => DOTSTATE,
        DOTCOUNTERX                 => PREDOTCOUNTER_X,
        DOTCOUNTERY                 => PREDOTCOUNTER_YP,
        VDPMODETEXT1                => VDPMODETEXT1,
        VDPMODETEXT2                => VDPMODETEXT2,
        REG_R7_FRAME_COL            => REG_R7_FRAME_COL,
        REG_R12_BLINK_MODE          => REG_R12_BLINK_MODE,
        REG_R13_BLINK_PERIOD        => REG_R13_BLINK_PERIOD,
        REG_R2_PT_NAM_ADDR          => REG_R2_PT_NAM_ADDR,
        REG_R4_PT_GEN_ADDR          => REG_R4_PT_GEN_ADDR,
        REG_R10R3_COL_ADDR          => REG_R10R3_COL_ADDR,
        PRAMDAT                     => PRAMDAT,
        PRAMADR                     => PRAMADRT12,
        TXVRAMREADEN                => TXVRAMREADEN,
        PCOLORCODE                  => COLORCODET12
    );

    U_VDP_GRAPHIC123M: work.VDP_GRAPHIC123M
    PORT MAP(
        CLK21M                      => CLK21M,
        RESET                       => RESET,
        DOTSTATE                    => DOTSTATE,
        EIGHTDOTSTATE               => EIGHTDOTSTATE,
        DOTCOUNTERX                 => PREDOTCOUNTER_X,
        DOTCOUNTERY                 => PREDOTCOUNTER_Y,
        VDPMODEMULTI                => VDPMODEMULTI,
        VDPMODEGRAPHIC1             => VDPMODEGRAPHIC1,
        VDPMODEGRAPHIC2             => VDPMODEGRAPHIC2,
        VDPMODEGRAPHIC3             => VDPMODEGRAPHIC3,
        REG_R2_PT_NAM_ADDR          => REG_R2_PT_NAM_ADDR,
        REG_R4_PT_GEN_ADDR          => REG_R4_PT_GEN_ADDR,
        REG_R10R3_COL_ADDR          => REG_R10R3_COL_ADDR,
        REG_R26_H_SCROLL            => REG_R26_H_SCROLL,
        REG_R27_H_SCROLL            => REG_R27_H_SCROLL,
        PRAMDAT                     => PRAMDAT,
        PRAMADR                     => PRAMADRG123M,
        PCOLORCODE                  => COLORCODEG123M
    );

    U_VDP_GRAPHIC4567: work.VDP_GRAPHIC4567
    PORT MAP(
        CLK21M                      => CLK21M,
        RESET                       => RESET,
        DOTSTATE                    => DOTSTATE,
        EIGHTDOTSTATE               => EIGHTDOTSTATE,
        DOTCOUNTERX                 => PREDOTCOUNTER_X,
        DOTCOUNTERY                 => PREDOTCOUNTER_Y,
        VDPMODEGRAPHIC4             => VDPMODEGRAPHIC4,
        VDPMODEGRAPHIC5             => VDPMODEGRAPHIC5,
        VDPMODEGRAPHIC6             => VDPMODEGRAPHIC6,
        VDPMODEGRAPHIC7             => VDPMODEGRAPHIC7,
        REG_R2_PT_NAM_ADDR          => REG_R2_PT_NAM_ADDR,
        REG_R26_H_SCROLL            => REG_R26_H_SCROLL,
        REG_R27_H_SCROLL            => REG_R27_H_SCROLL,
        REG_R25_YAE                 => REG_R25_YAE,
        REG_R25_YJK                 => REG_R25_YJK,
        REG_R25_SP2                 => REG_R25_SP2,
        PRAMDAT                     => PRAMDAT,
        PRAMDATPAIR                 => PRAMDATPAIR,
        PRAMADR                     => PRAMADRG4567,
        PCOLORCODE                  => COLORCODEG4567,
        P_YJK_R                     => YJK_R,
        P_YJK_G                     => YJK_G,
        P_YJK_B                     => YJK_B,
        P_YJK_EN                    => YJK_EN
    );

    -----------------------------------------------------------------------------
    -- SPRITE Modules
    -----------------------------------------------------------------------------
    U_SPRITE: work.VDP_SPRITE
    PORT MAP(
        CLK21M                      => CLK21M,
        RESET                       => RESET,
        DOTSTATE                    => DOTSTATE,
        EIGHTDOTSTATE               => EIGHTDOTSTATE,
        DOTCOUNTERX                 => PREDOTCOUNTER_X,
        DOTCOUNTERYP                => PREDOTCOUNTER_YP,
        BWINDOW_Y                   => BWINDOW_Y,
        PVDPS0SPCOLLISIONINCIDENCE  => VDPS0SPCOLLISIONINCIDENCE,
        PVDPS0SPOVERMAPPED          => VDPS0SPOVERMAPPED,
        PVDPS0SPOVERMAPPEDNUM       => VDPS0SPOVERMAPPEDNUM,
        PVDPS3S4SPCOLLISIONX        => VDPS3S4SPCOLLISIONX,
        PVDPS5S6SPCOLLISIONY        => VDPS5S6SPCOLLISIONY,
        PVDPS0RESETREQ              => SPVDPS0RESETREQ,
        PVDPS0RESETACK              => SPVDPS0RESETACK,
        PVDPS5RESETREQ              => SPVDPS5RESETREQ,
        PVDPS5RESETACK              => SPVDPS5RESETACK,
        REG_R1_SP_SIZE              => REG_R1_SP_SIZE,
        REG_R1_SP_ZOOM              => REG_R1_SP_ZOOM,
        REG_R11R5_SP_ATR_ADDR       => REG_R11R5_SP_ATR_ADDR,
        REG_R6_SP_GEN_ADDR          => REG_R6_SP_GEN_ADDR,
        REG_R8_COL0_ON              => REG_R8_COL0_ON,
        REG_R8_SP_OFF               => REG_R8_SP_OFF,
        REG_R23_VSTART_LINE         => REG_R23_VSTART_LINE,
        REG_R27_H_SCROLL            => REG_R27_H_SCROLL,
        SPMODE2                     => SPMODE2,
        VRAMINTERLEAVEMODE          => VDPMODEISVRAMINTERLEAVE,
        SPVRAMACCESSING             => SPVRAMACCESSING,
        PRAMDAT                     => PRAMDAT,
        PRAMADR                     => PRAMADRSPRITE,
        SPCOLOROUT                  => SPRITECOLOROUT,
        SPCOLORCODE                 => COLORCODESPRITE
    );

    -----------------------------------------------------------------------------
    -- VDP REGISTER ACCESS
    -----------------------------------------------------------------------------
    U_VDP_REGISTER: work.VDP_REGISTER
    PORT MAP(
        RESET                       => RESET                        ,
        CLK21M                      => CLK21M                       ,

        REQ                         => REQ                          ,
        ACK                         => ACK                          ,
        WRT                         => WRT                          ,
        ADR                         => ADR                          ,
        DBI                         => DBI                          ,
        DBO                         => DBO                          ,

        DOTSTATE                    => DOTSTATE                     ,

        VDPCMDTRCLRACK              => VDPCMDTRCLRACK               ,
        VDPCMDREGWRACK              => VDPCMDREGWRACK               ,
        HSYNC                       => HSYNC                        ,

        VDPS0SPCOLLISIONINCIDENCE   => VDPS0SPCOLLISIONINCIDENCE    ,
        VDPS0SPOVERMAPPED           => VDPS0SPOVERMAPPED            ,
        VDPS0SPOVERMAPPEDNUM        => VDPS0SPOVERMAPPEDNUM         ,
        SPVDPS0RESETREQ             => SPVDPS0RESETREQ              ,
        SPVDPS0RESETACK             => SPVDPS0RESETACK              ,
        SPVDPS5RESETREQ             => SPVDPS5RESETREQ              ,
        SPVDPS5RESETACK             => SPVDPS5RESETACK              ,

        VDPCMDTR                    => VDPCMDTR                     ,
        VD                          => VD                           ,
        HD                          => HD                           ,
        VDPCMDBD                    => VDPCMDBD                     ,
        FIELD                       => FIELD                        ,
        VDPCMDCE                    => VDPCMDCE                     ,
        VDPS3S4SPCOLLISIONX         => VDPS3S4SPCOLLISIONX          ,
        VDPS5S6SPCOLLISIONY         => VDPS5S6SPCOLLISIONY          ,
        VDPCMDCLR                   => VDPCMDCLR                    ,
        VDPCMDSXTMP                 => VDPCMDSXTMP                  ,

        VDPVRAMACCESSDATA           => VDPVRAMACCESSDATA            ,
        VDPVRAMACCESSADDRTMP        => VDPVRAMACCESSADDRTMP         ,
        VDPVRAMADDRSETREQ           => VDPVRAMADDRSETREQ            ,
        VDPVRAMADDRSETACK           => VDPVRAMADDRSETACK            ,
        VDPVRAMWRREQ                => VDPVRAMWRREQ                 ,
        VDPVRAMWRACK                => VDPVRAMWRACK                 ,
        VDPVRAMRDDATA               => VDPVRAMRDDATA                ,
        VDPVRAMRDREQ                => VDPVRAMRDREQ                 ,
        VDPVRAMRDACK                => VDPVRAMRDACK                 ,

        VDPCMDREGNUM                => VDPCMDREGNUM                 ,
        VDPCMDREGDATA               => VDPCMDREGDATA                ,
        VDPCMDREGWRREQ              => VDPCMDREGWRREQ               ,
        VDPCMDTRCLRREQ              => VDPCMDTRCLRREQ               ,

        PALETTEADDR_OUT             => PALETTEADDR_OUT              ,
        PALETTEDATARB_OUT           => PALETTEDATARB_OUT            ,
        PALETTEDATAG_OUT            => PALETTEDATAG_OUT             ,

        CLR_VSYNC_INT               => CLR_VSYNC_INT                ,
        CLR_HSYNC_INT               => CLR_HSYNC_INT                ,
        REQ_VSYNC_INT_N             => REQ_VSYNC_INT_N              ,
        REQ_HSYNC_INT_N             => REQ_HSYNC_INT_N              ,

        REG_R0_HSYNC_INT_EN         => REG_R0_HSYNC_INT_EN          ,
        REG_R1_SP_SIZE              => REG_R1_SP_SIZE               ,
        REG_R1_SP_ZOOM              => REG_R1_SP_ZOOM               ,
        REG_R1_VSYNC_INT_EN         => REG_R1_VSYNC_INT_EN          ,
        REG_R1_DISP_ON              => REG_R1_DISP_ON               ,
        REG_R2_PT_NAM_ADDR          => REG_R2_PT_NAM_ADDR           ,
        REG_R4_PT_GEN_ADDR          => REG_R4_PT_GEN_ADDR           ,
        REG_R10R3_COL_ADDR          => REG_R10R3_COL_ADDR           ,
        REG_R11R5_SP_ATR_ADDR       => REG_R11R5_SP_ATR_ADDR        ,
        REG_R6_SP_GEN_ADDR          => REG_R6_SP_GEN_ADDR           ,
        REG_R7_FRAME_COL            => REG_R7_FRAME_COL             ,
        REG_R8_SP_OFF               => REG_R8_SP_OFF                ,
        REG_R8_COL0_ON              => REG_R8_COL0_ON               ,
        REG_R9_PAL_MODE             => REG_R9_PAL_MODE              ,
        REG_R9_INTERLACE_MODE       => REG_R9_INTERLACE_MODE        ,
        REG_R9_Y_DOTS               => REG_R9_Y_DOTS                ,
        REG_R12_BLINK_MODE          => REG_R12_BLINK_MODE           ,
        REG_R13_BLINK_PERIOD        => REG_R13_BLINK_PERIOD         ,
        REG_R18_ADJ                 => REG_R18_ADJ                  ,
        REG_R19_HSYNC_INT_LINE      => REG_R19_HSYNC_INT_LINE       ,
        REG_R23_VSTART_LINE         => REG_R23_VSTART_LINE          ,
        REG_R25_CMD                 => REG_R25_CMD                  ,
        REG_R25_YAE                 => REG_R25_YAE                  ,
        REG_R25_YJK                 => REG_R25_YJK                  ,
        REG_R25_MSK                 => REG_R25_MSK                  ,
        REG_R25_SP2                 => REG_R25_SP2                  ,
        REG_R26_H_SCROLL            => REG_R26_H_SCROLL             ,
        REG_R27_H_SCROLL            => REG_R27_H_SCROLL             ,

        VDPMODETEXT1                => VDPMODETEXT1                 ,
        VDPMODETEXT2                => VDPMODETEXT2                 ,
        VDPMODEMULTI                => VDPMODEMULTI                 ,
        VDPMODEGRAPHIC1             => VDPMODEGRAPHIC1              ,
        VDPMODEGRAPHIC2             => VDPMODEGRAPHIC2              ,
        VDPMODEGRAPHIC3             => VDPMODEGRAPHIC3              ,
        VDPMODEGRAPHIC4             => VDPMODEGRAPHIC4              ,
        VDPMODEGRAPHIC5             => VDPMODEGRAPHIC5              ,
        VDPMODEGRAPHIC6             => VDPMODEGRAPHIC6              ,
        VDPMODEGRAPHIC7             => VDPMODEGRAPHIC7              ,
        VDPMODEISHIGHRES            => VDPMODEISHIGHRES             ,
        SPMODE2                     => SPMODE2                      ,
        VDPMODEISVRAMINTERLEAVE     => VDPMODEISVRAMINTERLEAVE      ,

        FORCED_V_MODE               => FORCED_V_MODE
    );

    -- ��
--  DEBUG_OUTPUT <= REG_R19_HSYNC_INT_LINE & REG_R23_VSTART_LINE;

    -----------------------------------------------------------------------------
    -- VDP COMMAND
    -----------------------------------------------------------------------------
    U_VDP_COMMAND: work.VDP_COMMAND
    PORT MAP(
        RESET               => RESET                ,
        CLK21M              => CLK21M               ,
        VDPMODEGRAPHIC4     => VDPMODEGRAPHIC4      ,
        VDPMODEGRAPHIC5     => VDPMODEGRAPHIC5      ,
        VDPMODEGRAPHIC6     => VDPMODEGRAPHIC6      ,
        VDPMODEGRAPHIC7     => VDPMODEGRAPHIC7      ,
        VDPMODEISHIGHRES    => VDPMODEISHIGHRES     ,
        VRAMWRACK           => VDPCMDVRAMWRACK      ,
        VRAMRDACK           => VDPCMDVRAMRDACK      ,
        VRAMREADINGR        => VDPCMDVRAMREADINGR   ,
        VRAMREADINGA        => VDPCMDVRAMREADINGA   ,
        VRAMRDDATA          => VDPCMDVRAMRDDATA     ,
        REGWRREQ            => VDPCMDREGWRREQ       ,
        TRCLRREQ            => VDPCMDTRCLRREQ       ,
        REGNUM              => VDPCMDREGNUM         ,
        REGDATA             => VDPCMDREGDATA        ,
        PREGWRACK           => VDPCMDREGWRACK       ,
        PTRCLRACK           => VDPCMDTRCLRACK       ,
        PVRAMWRREQ          => VDPCMDVRAMWRREQ      ,
        PVRAMRDREQ          => VDPCMDVRAMRDREQ      ,
        PVRAMACCESSADDR     => VDPCMDVRAMACCESSADDR ,
        PVRAMWRDATA         => VDPCMDVRAMWRDATA     ,
        PCLR                => VDPCMDCLR            ,
        PCE                 => VDPCMDCE             ,
        PBD                 => VDPCMDBD             ,
        PTR                 => VDPCMDTR             ,
        PSXTMP              => VDPCMDSXTMP          ,
        CUR_VDP_COMMAND     => CUR_VDP_COMMAND      ,
        REG_R25_CMD         => REG_R25_CMD
    );

    U_VDP_WAIT_CONTROL: work.VDP_WAIT_CONTROL
    PORT MAP (
        RESET               => RESET                ,
        CLK21M              => CLK21M               ,

        VDP_COMMAND         => CUR_VDP_COMMAND      ,

        VDPR9PALMODE        => VDPR9PALMODE         ,
        REG_R1_DISP_ON      => REG_R1_DISP_ON       ,
        REG_R8_SP_OFF       => REG_R8_SP_OFF        ,
        REG_R9_Y_DOTS       => REG_R9_Y_DOTS        ,

        VDPSPEEDMODE        => VDPSPEEDMODE         ,
        DRIVE               => VDP_COMMAND_DRIVE    ,

        ACTIVE              => VDP_COMMAND_ACTIVE
    );

END RTL;

