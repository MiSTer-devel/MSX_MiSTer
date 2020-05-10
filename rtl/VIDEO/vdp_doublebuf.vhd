--
--  vdp_doublebuf.vhd
--    Double Buffered Line Memory.
--
--  Copyright (C) 2000-2006 Kunihiko Ohnaka
--  All rights reserved.
--                                     http://www.ohnaka.jp/ese-vdp/
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
--
-------------------------------------------------------------------------------
-- Document
--
--

LIBRARY IEEE;
    USE IEEE.STD_LOGIC_1164.ALL;
    USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY VDP_DOUBLEBUF IS
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
END VDP_DOUBLEBUF;

ARCHITECTURE RTL OF VDP_DOUBLEBUF IS
    SIGNAL WE_E     : STD_LOGIC;
    SIGNAL WE_O     : STD_LOGIC;
    SIGNAL ADDR_E   : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL ADDR_O   : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL OUTR_E   : STD_LOGIC_VECTOR(5 DOWNTO 0);
    SIGNAL OUTG_E   : STD_LOGIC_VECTOR(5 DOWNTO 0);
    SIGNAL OUTB_E   : STD_LOGIC_VECTOR(5 DOWNTO 0);
    SIGNAL OUTR_O   : STD_LOGIC_VECTOR(5 DOWNTO 0);
    SIGNAL OUTG_O   : STD_LOGIC_VECTOR(5 DOWNTO 0);
    SIGNAL OUTB_O   : STD_LOGIC_VECTOR(5 DOWNTO 0);
BEGIN
    -- EVEN LINE
    U_BUF_RE: work.VDP_LINEBUF
    PORT MAP(
        ADDRESS     => ADDR_E,
        INCLOCK     => CLK,
        WE          => WE_E,
        DATA        => DATARIN,
        Q           => OUTR_E
    );

    U_BUF_GE: work.VDP_LINEBUF
    PORT MAP(
        ADDRESS     => ADDR_E,
        INCLOCK     => CLK,
        WE          => WE_E,
        DATA        => DATAGIN,
        Q           => OUTG_E
    );

    U_BUF_BE: work.VDP_LINEBUF
    PORT MAP(
        ADDRESS     => ADDR_E,
        INCLOCK     => CLK,
        WE          => WE_E,
        DATA        => DATABIN,
        Q           => OUTB_E
    );
    -- ODD LINE
    U_BUF_RO: work.VDP_LINEBUF
    PORT MAP(
        ADDRESS     => ADDR_O,
        INCLOCK     => CLK,
        WE          => WE_O,
        DATA        => DATARIN,
        Q           => OUTR_O
    );

    U_BUF_GO: work.VDP_LINEBUF
    PORT MAP(
        ADDRESS     => ADDR_O,
        INCLOCK     => CLK,
        WE          => WE_O,
        DATA        => DATAGIN,
        Q           => OUTG_O
    );

    U_BUF_BO: work.VDP_LINEBUF
    PORT MAP(
        ADDRESS     => ADDR_O,
        INCLOCK     => CLK,
        WE          => WE_O,
        DATA        => DATABIN,
        Q           => OUTB_O
    );

    WE_E        <= WE WHEN( EVENODD = '0' )ELSE '0';
    WE_O        <= WE WHEN( EVENODD = '1' )ELSE '0';

    ADDR_E      <= XPOSITIONW WHEN( EVENODD = '0' )ELSE XPOSITIONR;
    ADDR_O      <= XPOSITIONW WHEN( EVENODD = '1' )ELSE XPOSITIONR;

    DATAROUT    <= OUTR_E WHEN( EVENODD = '1' )ELSE OUTR_O;
    DATAGOUT    <= OUTG_E WHEN( EVENODD = '1' )ELSE OUTG_O;
    DATABOUT    <= OUTB_E WHEN( EVENODD = '1' )ELSE OUTB_O;
END RTL;
