%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <conio.h>
	#include <string.h>
	#include "y.tab.h"

	int cota_error(char* mensaje);
	int convierte_bin_a_dec(int numerobin);
	char *substring(char *string, int position);

	FILE  *yyin;
%}

%option noyywrap
%option yylineno

DIGITO 	[0-9] 																														 
LETRA 	[a-zA-ZñÑ]  																											 
ID		{LETRA}({LETRA}|{DIGITO})* 
BIN 			[0|1]
CTE_INT_BIN 	{0b}{BIN}+
EXA 			({DIGITO}|[A-F])+
CTE_INT_EXA 	"0x"{EXA}
CTE_INT			{DIGITO}+                                                                                                         
CTE_FLOAT	 	{DIGITO}+"."{DIGITO}*|{DIGITO}*"."{DIGITO}+
ESPACIO " "																																				
CTE_STRING \"({LETRA}|{DIGITO}|{ESPACIO}|%|@)+\"													
COMENTARIO	        "*/".*"/*"
    


%%
 /* Inicio y fin de programa */
"PROGRAM"			{ return START;}
"ENDPROGRAM"		{ return END;}

 /* Seccion de declaracion de variables y tipos de datos */
"BEGINDEC"		{ return BEGINDEC;}
"ENDDEC"		{ return ENDDEC;}
"integer"			{ return INT;}
"string"			{ return STRING;}
"real"				{ return FLOAT;}

 /* Bloques de control */
"while"					{ return WHILE;}
"do"					{ return DO;}
"endwhile"				{ return ENDWHILE;}
"if"					{ return IF;}
"then"					{ return THEN;}
"else"					{ return ELSE;}
"endif"					{ return ENDIF;}

 /* Operadores logicos */
"AND"							{ return AND;}
"OR"							{ return OR;}
"NOT"						{ return NOT;}

 /* Operadores */
":="						{ return ASIG;}                       
"+"							{ return MAS;}
"-"							{ return MENOS;}
"*"							{ return POR;}
"/"							{ return DIVIDIDO;}

 /* Comparadores */
"<"							{ return MENOR;}
">"							{ return MAYOR;}
"<="						{ return MENOR_IGUAL;}
">="						{ return MAYOR_IGUAL;}
"=="						{ return IGUAL;}
"<>"						{ return DISTINTO;}

 /* Otros simbolos */
"("							{ return P_A;}
")"							{ return P_C;}
"["							{ return C_A;}
"]"							{ return C_C;}
","							{ return COMA;}

"long" 						{return LONG;}
"as" 						{return AS;}
"in" 						{return IN;}
"dim" 						{return DIM;}

	/* ENTRADA Y SALIDA */
"DISPLAY"					{return DISPLAY;}
"GET"						{return GET;}


{COMENTARIO}              /* IGNORAR COMENTARIOS */

 /* Identificadores y constantes */
 {ID}						{
								if(strlen(yytext) <= 30){
									yylval.str_val = strdup(yytext);
									return ID;
								}
								cota_error("Nombre de variable excede el maximo de 30 caracteres.");
							}
 /*
{CTE_INT_BIN}				{
								//yytext = substring(yytext, 2);
								//yylval.intval = atoi( yytext );
								//sprintf("binario: %s", yytext);
								//yylval.intval = atoi( yytext );
							}*/
{CTE_INT}					{ 
								if(atoll(yytext)<=2147483647){
									yylval.int_val = atoi( yytext );
									return CTE_INT;
								}
								cota_error("Constante Entero demasiado grande");
							}

{CTE_STRING}		{
								if(strlen(yytext)<=30)
								{
									yylval.str_val = strdup(yytext);
									/*
									int length = strlen(yytext);
									char nombre_cte[length];
									strcpy(nombre_cte, "_");
									strcat(nombre_cte, yytext+1);
									strcpy(nombre_cte + strlen(nombre_cte) - 1, "\0");
									strcpy(yylval.str_val, nombre_cte);
									*/
									return CTE_STRING;
								}
								cota_error("Constante String supera Maximo 30 caracteres.");
							}					
{CTE_FLOAT}					{
								if(atof(yytext)<=3.40282347e+38F){
									yylval.float_val = atof(yytext);
									return CTE_FLOAT;
								}
								cota_error("La constante real supera el limite.");
							}
\t

%%

int cota_error(char* mensaje)
{
	printf("Error lexico: %s\n", mensaje);
	system ("Pause");
	exit (1);
}

/*C substring function: It returns a pointer to the substring */
char *substring(char *string, int position)
{
   char *pointer;
   int c;
   int length;
   length = strlen(string);
 
   pointer = malloc(length+1);
   
   if (pointer == NULL)
   {
      printf("Unable to allocate memory.\n");
      exit(1);
   }
 
   for (c = 0 ; c < length ; c++)
   {
      *(pointer+c) = *(string+position-1);      
      string++;  
   }
 
   *(pointer+c) = '\0';
 
   return pointer;
}
int convierte_bin_a_dec(int numerobin)
{
int  binary_val, decimal_val = 0, base = 1, rem;
 
    //printf("Enter a binary number(1s and 0s) \n");
    //scanf("%d", &num); /* maximum five digits */
    binary_val = numerobin;
    while (numerobin > 0)
    {
        rem = numerobin % 10;
        decimal_val = decimal_val + rem * base;
        numerobin = numerobin / 10 ;
        base = base * 2;
    }
    printf("The Binary number is = %d \n", binary_val);
    printf("Its decimal equivalent is = %d \n", decimal_val);
	return decimal_val;
}