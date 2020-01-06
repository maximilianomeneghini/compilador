include macros2.asm
include number.asm

.MODEL SMALL
.386
.STACK 200h

.DATA
NEW_LINE DB 0AH,0DH,'$'
CWprevio DW ?
_s dd ?
_x dd ?
_0 dd 0
_4 dd 4
String0 db ""A ES MAYOR A 4"", '$'
String1 db ""A ES MENOR O IGUAL A 4"", '$'

.CODE

MOV AX, @DATA
MOV DS, AX
FINIT

FILD _0
FISTP _x
getInteger _x

FILD _x
FILD _4
FXCH
FCOMP
FSTSW AX
SAHF
JBE else268
then265:
displayString String0
displayString NEW_LINE

JMP endif270
else268:
displayString String1
displayString NEW_LINE

endif270:

MOV AH, 1
INT 21h
MOV AX, 4C00h
INT 21h

END
