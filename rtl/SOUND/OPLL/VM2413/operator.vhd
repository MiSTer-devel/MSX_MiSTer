--
-- Operator.vhd
--
-- Copyright (c) 2006 Mitsutaka Okazaki (brezza@pokipoki.org)
-- All rights reserved.
--
-- Redistribution and use of this source code or any derivative works, are
-- permitted provided that the following conditions are met:
--
-- 1. Redistributions of source code must retain the above copyright notice,
--    this list of conditions and the following disclaimer.
-- 2. Redistributions in binary form must reproduce the above copyright
--    notice, this list of conditions and the following disclaimer in the
--    documentation and/or other materials provided with the distribution.
-- 3. Redistributions may not be sold, nor may they be used in a commercial
--    product or activity without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
-- "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
-- TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
-- CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
-- EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
-- PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
-- OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
-- WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
-- OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
-- ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
--

--
--  modified by t.hara
--

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;
    use work.vm2413.all;

entity Operator is
    port (
        clk     : in    std_logic;
        reset   : in    std_logic;
        clkena  : in    std_logic;

        slot    : in    SLOT_TYPE;
        stage   : in    STAGE_TYPE;
        rhythm  : in    std_logic;

        WF      : in    WF_TYPE;
        FB      : in    FB_TYPE;

        noise   : in    std_logic;
        pgout   : in    std_logic_vector( 17 downto 0 );    --  ������ 9bit, ������ 9bit
        egout   : in    std_logic_vector( 12 downto 0 );

        faddr   : out   CH_TYPE;
        fdata   : in    SIGNED_LI_TYPE;

        opout   : out   std_logic_vector( 13 downto 0 )     -- ������ 8bit, ������ 6bit
    );
end Operator;

architecture rtl of Operator is

    component SineTable
        port (
            clk     : in    std_logic;
            clkena  : in    std_logic;
            wf      : in    std_logic;
            addr    : in    std_logic_vector( 17 downto 0 );    --  ������ 9bit, ������ 9bit
            data    : out   std_logic_vector( 13 downto 0 )     --  ������ 8bit, ������ 6bit
        );
    end component;

    signal addr         : std_logic_vector( 17 downto 0 );
    signal data         : std_logic_vector( 13 downto 0 );
    signal w_is_carrier : std_logic;
    signal w_modula_m   : std_logic_vector( LI_TYPE'high + 2 + 9 downto 0 );
    signal w_modula_c   : std_logic_vector( LI_TYPE'high + 2 + 9 downto 0 );
    signal w_modula     : std_logic_vector( LI_TYPE'high + 2 + 9 downto 0 );
    signal ff_egout     : std_logic_vector( 12 downto 0 );
begin

    --  �T�C���g�i�ΐ��\���j--------------------------------------------------
    --  addr �w�肵�����X�T�C�N���� data ���o�Ă���
    --
    --  stage   X 00    X 01    X 10    X 11    X 00
    --  addr            X �m��
    --  data                            X �m��
    --  opout                                   X �m��
    --
    u_sine_table : SineTable
    port map(
        clk     => clk,
        clkena  => clkena,
        wf      => wf,
        addr    => addr,
        data    => data
    );

    w_is_carrier    <=  slot(0);
    w_modula_m      <=  (others => '0') when( fb = "000" )else
                        shr( '0' & fdata.value & '0' & "000000000", "111" xor fb );
    w_modula_c      <=  fdata.value & "00" & "000000000";
    w_modula        <=  w_modula_c  when( w_is_carrier = '1' )else
                        w_modula_m;

    process( reset, clk )
        variable opout_buf  : std_logic_vector( 13 downto 0 );  --  ������ 8bit, ������ 6bit
    begin
        if( rising_edge(clk) )then
            if( reset = '1' )then
                opout       <= (others => '0');
                ff_egout    <= (others => '0');
            else
                if( clkena = '1' )then
                    if( stage = "00" )then
                        --  �T�C���g�̎Q�ƃA�h���X�i�ʑ��j�����肷��X�e�[�W
                        if(    rhythm = '1' and ( slot = 14 or slot = 17 ))then -- HH or CYM
                            addr <= (not noise) & "01111111" & "000000000";
                        elsif( rhythm = '1' and slot = 15 )then -- SD
                            addr <= (not pgout(pgout'high)) & "01111111" & "000000000";
                        elsif( rhythm = '1' and slot = 16 )then -- TOM
                            addr <= pgout;
                        else
                            if( fdata.sign = '0' )then      -- modula �� fdata �̐�Βl���V�t�g�����l������A�����ŕ����������Ă�
                                addr <= pgout + w_modula(pgout'range);
                            else
                                addr <= pgout - w_modula(pgout'range);
                            end if;
                        end if;

                    elsif( stage = "01" )then
                        --  ���肳�ꂽ�Q�ƃA�h���X�� u_sine_table �֋��������X�e�[�W
                    elsif( stage = "10" )then
                        ff_egout <= egout;

                        --  �t�B�[�h�o�b�N�������̃A�h���X�����߂�X�e�[�W
                        if( slot(0) = '1' )then
                            if( conv_integer(slot)/2 = 8 )then
                                faddr <= 0;
                            else
                                faddr <= conv_integer(slot)/2 + 1;  --  ���̃��W�����[�^�̃A�h���X�Ȃ̂� +1
                            end if;
                        end if;
                    elsif( stage = "11" )then
                        -- SineTable ����f�[�^���o�Ă���X�e�[�W
                        if ( ( '0' & ff_egout ) + ('0'& data(12 downto 0) ) ) < "10000000000000" then
                            opout_buf := data(13) & (ff_egout + data(12 downto 0) );
                        else
                            opout_buf := data(13) & "1111111111111";
                        end if;
                        opout <= opout_buf;
                        --  ���肳�ꂽ�t�B�[�h�o�b�N�������A�h���X�� FeedBackMemory �֋��������X�e�[�W
                    end if;
                end if;
            end if;
        end if;
    end process;
end rtl;
