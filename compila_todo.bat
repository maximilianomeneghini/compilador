c:\GnuWin32\bin\flex Lexico.l
pause
c:\GnuWin32\bin\bison -dyv --report=state Sintactico.y
pause
c:\MinGW\bin\gcc.exe -I librerias .\librerias\tabla_simbolos.c .\librerias\tercetos.c .\librerias\sentencias_control.c .\librerias\inlist.c .\librerias\assembler.c lex.yy.c y.tab.c -o Grupo01.exe
pause
pause
Grupo01.exe Prueba.txt
pause
tasm Final.asm
pause
tlink /3 Final.obj numbers.obj /v /s /m
pause

del lex.yy.c
del y.tab.c
del y.output
del y.tab.h
rem del Segunda.exe
pause
