PATH=%PATH%;c:\Program Files (x86)\zDevStudio - Z80 Development Studio\bin
if exist a.out del a.out
pasmo53 -v --hex %1.asm a.out %1.lst %1.public
if %ERRORLEVEL% EQU 0 cp a.out %1.hex
