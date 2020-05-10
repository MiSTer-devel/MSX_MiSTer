--
--  vdp_linebuf.vhd
--    Line buffer for VGA upscan converter.
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
-- 21th,March,2008 modified by t.hara
--   JP: ���t�@�N�^�����O, �������ȂǍ��ׂȏC���B
--
-------------------------------------------------------------------------------
-- Document
--
-- JP: NTSC�^�C�~���O�� 15KHz�ŏo�͂������r�f�I�M����VGA�^�C�~���O��
-- JP: ���킹��31KHz�̔{���[�g�ŏo�͂��邽�߂̃��C���o�b�t�@���W���[��
-- JP: �ł��B
-- JP: ESE-VDP�̃��C���N���b�N�ł���21.477MHz�œ��삳���邽�߁A
-- JP: �h�b�g�N���b�N�͈��ʓI�� 640x480�h�b�gVGA���[�h��25.175MHz
-- JP: �Ƃ͈قȂ��܂��B���̂��߁A�t�����j�^���ŕ\���������ƃh�b�g�̌`��
-- JP: ���тȌ`�ɂȂ鎖�������܂��B
--

LIBRARY IEEE;
    USE IEEE.STD_LOGIC_1164.ALL;
    USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY VDP_LINEBUF IS
     PORT (
        ADDRESS     : IN    STD_LOGIC_VECTOR(  9 DOWNTO 0 );
        INCLOCK     : IN    STD_LOGIC;
        WE          : IN    STD_LOGIC;
        DATA        : IN    STD_LOGIC_VECTOR(  5 DOWNTO 0 );
        Q           : OUT   STD_LOGIC_VECTOR(  5 DOWNTO 0 )
    );
END VDP_LINEBUF;

ARCHITECTURE RTL OF VDP_LINEBUF IS
    TYPE MEM IS ARRAY ( 639 DOWNTO 0 ) OF STD_LOGIC_VECTOR( 4 DOWNTO 0 );
    SIGNAL IMEM     : MEM;
    SIGNAL IADDRESS : STD_LOGIC_VECTOR( 9 DOWNTO 0 );
BEGIN

    PROCESS( INCLOCK )
    BEGIN
        IF( INCLOCK'EVENT AND INCLOCK ='1' )THEN
            IF( WE = '1' )THEN
                IMEM( CONV_INTEGER(ADDRESS) ) <= DATA( 5 DOWNTO 1 );    -- data range required by YJK mode
            END IF;
            IADDRESS <= ADDRESS;
        END IF;
    END PROCESS;

    Q <= IMEM( CONV_INTEGER(IADDRESS) ) & "0";
END RTL;
