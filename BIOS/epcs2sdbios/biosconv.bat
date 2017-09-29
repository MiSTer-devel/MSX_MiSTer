@echo off

rem
rem
rem
rem usage: biosconv.bat <hexfile>
rem
rem output file is OCM-BIOS.DAT
rem
rem
rem

setlocal ENABLEDELAYEDEXPANSION

hex2bin.exe -o out.bin %1

set size=16384
for /L %%n in (0,1,18) do (
	set /a "pos=%%n*%size%"
	cut out.bin !pos! %size% out.p%%n
)

copy /b out.p0 out.b00 >nul
fill out.b00 0 0 b 0x00
copy /b out.p0 out.bFF >nul
fill out.bFF 0 0 b 0xFF

copy /b out.p0 OCM-BIOS.DAT.bin >nul
for /L %%n in (1,1,3) do (
	copy /b OCM-BIOS.DAT.bin +out.p%%n >nul
)

copy /b OCM-BIOS.DAT.bin +out.b00 >nul
copy /b OCM-BIOS.DAT.bin +out.b00 >nul
copy /b OCM-BIOS.DAT.bin +out.b00 >nul
copy /b OCM-BIOS.DAT.bin +out.b00 >nul

for /L %%n in (4,1,10) do (
	copy /b OCM-BIOS.DAT.bin +out.p%%n >nul
)

copy /b OCM-BIOS.DAT.bin +out.bFF >nul

for /L %%n in (11,1,18) do (
	copy /b OCM-BIOS.DAT.bin +out.p%%n >nul
)

for /L %%n in (0,1,7) do (
	copy /b OCM-BIOS.DAT.bin +out.b00 >nul
)

del out.b00
del out.bFF
del out.bin

for /L %%n in (0,1,18) do (
	del out.p%%n
)

pause
