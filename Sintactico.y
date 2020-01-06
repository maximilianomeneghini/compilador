%{
#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <string.h>
#include "y.tab.h"

#include "./librerias/tabla_simbolos.h"
#include "./librerias/tercetos.h"
#include "./librerias/sentencias_control.h"
#include "./librerias/inlist.h"
#include "./librerias/assembler.h"

/* Funciones necesarias */
int yyerror(char* mensaje);
void chequearTipoDato(int tipo);
void resetTipoDato();
	
int yystopparser=0;
FILE  *yyin;
char *yyltext;
char *yytext;                                                                                 

/* variables de tabla de simbolos */
simbolo tabla_simbolo[TAMANIO_TABLA];
char* pila_tipodato[TAMANIO_TABLA];
int fin_tabla = -1; /* Apunta al ultimo registro en la tabla de simbolos. Incrementarlo para guardar el siguiente. */

/* Seteo de variables para la tabla de simbolos */
int varADeclarar1 = 0;
int cantVarsADeclarar = 0;
int tipoDatoADeclarar;
int cantTipoDatoEnPila=0;

/* Variables para las asignaciones TERCETOS */
char idAsignar[TAM_NOMBRE];
/* Cosas para comparadores booleanos */
int comp_bool_actual;
/* Cosas para control de tipo de datos en expresiones aritméticas */
int tipoDatoActual = sinTipo;
	
/* Seteo de variables para la funciones tercetos */
terceto lista_terceto[MAX_TERCETOS];
int ultimo_terceto = -1; /* Apunta al ultimo terceto escrito. Incrementarlo para guardar el siguiente. */

/* Cosas para anidamientos de average */
	info_anidamiento_exp_aritmeticas pila_exp[MAX_ANIDAMIENTOS];
	int ult_pos_pila_exp=VALOR_NULO;
	//info_anidamiento_avg pilaAVG[MAX_ANIDAMIENTOS];
	//int ult_pos_pilaAVG = VALOR_NULO;

/* Variables para inlist */
int ind_salto_inlist=VALOR_NULO;
int ind_cond_salto=VALOR_NULO;
int inlist_vector[MAX_ANIDAMIENTOS];
int ind_inlist_a=VALOR_NULO; //Indice de inlist a apilar (las direcciones que tengo que ponerle su salto)
int contador_inlist=VALOR_NULO;

/* Variables para anidamientos de if y while */
int falseIzq=VALOR_NULO;
int falseDer=VALOR_NULO;
int verdadero=VALOR_NULO;
int always=VALOR_NULO;

info_elemento_pila pila_bloques[MAX_ANIDAMIENTOS];
int ult_pos_pila_bloques=VALOR_NULO;

/* Indices extras para if y while */
int ind_if;
int ind_endif;
int ind_else;
int ind_then;
int ind_endwhile;

/* Indices para no terminales */
int ind_bloque;
int ind_sent;
int ind_bif;
int ind_bwhile;
int ind_btrue;
int ind_asig;
int ind_xp;
int ind_xpcad;
int ind_expr; //Expresion aritmetica
int ind_rterm;
int ind_term;
int ind_pre;
int ind_factor;
int ind_xplogic;
int ind_tlogic;
int ind_tlogic_izq;
int ind_expr_izq;
int ind_avg;
int ind_inlist; // El terceto a donde saltan las cosas dentro del inlist
int ind_lec; //Lista expresion coma
int ind_lepc; //Lista expresion punto y coma
int ind_lectura;
int ind_escritura;

%}

%union {
int int_val;
float float_val;
char *str_val;
}

%token MAS MENOS POR DIVIDIDO ASIG P_A P_C C_A C_C COMA
%token LONG
%token START END BEGINDEC ENDDEC
%token INT STRING WHILE DO ENDWHILE IF THEN ELSE ENDIF AND OR NOT FLOAT
%token MENOR MAYOR MENOR_IGUAL MAYOR_IGUAL DISTINTO IGUAL
%token AS IN DIM
%token DISPLAY GET

%token <str_val>ID
%token <float_val>CTE_FLOAT
%token <int_val>CTE_INT
%token <str_val>CTE_STRING
%token <int_val>CTE_INT_BIN
%token <int_val>CTE_INT_EXA

%%

programa : START seccion_declaracion bloque END	{
															printf("\nCOMPILACION EXITOSA\n");
															guardarTabla();
															optimizarTercetos();
															guardarTercetos();
															generarAssembler();
															};

 /* Declaracion de variables */

seccion_declaracion:
	BEGINDEC lista_declaraciones ENDDEC 				    {printf("Regla 2: Seccion declaracion es BEGINDEC lista_declaraciones ENDEC\n");}
									;
	
lista_declaraciones:
									lista_declaraciones declaracion  {printf("\nRegla 3: Lista de declaraciones OK");}
									|declaracion 					 {printf("\nRegla 4: Lista de declaraciones  OK");}
									;
					
declaracion: 
						DIM C_A lista_var C_C {printf("\nRegla 5: Declaracion OK: %s", yytext);
						agregarTiposDatosATabla();}
						;

lista_var:
				ID C_C AS C_A tipo_dato				{printf("\nRegla 6: lista_var OK. Nombre: %s Tipo: %s", $1, yytext);
													//yylval.str_val retornaba siempre la última variable de la lista
													agregarVarATabla($1);
													cantVarsADeclarar++;
													cantTipoDatoEnPila=1;
													//Guardo Tipo de Dato en Pila para Ordenarlo después y asignarlo a la variable correcta
													pila_tipodato[cantTipoDatoEnPila] = strdup(yytext);
													}
				|ID COMA lista_var COMA tipo_dato	{printf("\nRegla 7: lista_var OK. Nombre: %s Tipo: %s", $1, yytext);
													agregarVarATabla($1);
													cantVarsADeclarar++;
													cantTipoDatoEnPila++;
													//Guardo Tipo de Dato en Pila para Ordenarlo después y asignarlo a la variable correcta
													pila_tipodato[cantTipoDatoEnPila] = strdup(yytext);
													}
				;

tipo_dato:
					INT {printf("\nRegla 8: Tipo de dato INT OK: %s", yytext);}
					| FLOAT {printf("\nRegla 9: Tipo de dato FLOAT OK: %s", yytext);}
					| STRING {printf("\nRegla 10: Tipo de dato STRING OK: %s", yytext);}
					;

asignacion: 
					ID ASIG {strcpy(idAsignar, $1);} expresion 		{
											printf("\nRegla 11: Asignacion Expresion OK idAsignar: %s", idAsignar);
											int tipo = chequearVarEnTabla(idAsignar);
											chequearTipoDato(tipo);
											resetTipoDato();
											int pos=buscarIDEnTabla(idAsignar);
											ind_asig = crear_terceto(ASIG, pos, ind_expr);}
					|ID ASIG {strcpy(idAsignar, $1);} CTE_STRING	{
											printf("\nRegla 12: Asignacion CTE_STRING OK. Cte: %s", yytext);
											int pos=agregarCteStringATabla(yytext);
											ind_expr = crear_terceto(NOOP,pos,NOOP);
											
											int tipo = chequearVarEnTabla(idAsignar);
											chequearTipoDato(tipo);
											resetTipoDato();
											pos=buscarIDEnTabla(idAsignar);
											ind_asig = crear_terceto(ASIG, pos, ind_expr);
											
											}
					|ID ASIG funcion_long	{printf("\nRegla 13: Asignacion funcion_long OK");}
					;

expresion:
					termino 					{printf("\nRegla 14: Termino OK");
												ind_expr = ind_term;}
	 				|expresion MENOS termino 	{printf("\nRegla 15: Resta OK");
												ind_expr = crear_terceto(MENOS, ind_expr, ind_term);}
       				|expresion MAS termino 		{printf("\nRegla 16: Suma OK");
												ind_expr = crear_terceto(MAS, ind_expr, ind_term);}
					;

termino: 
       			factor 						{printf("\nRegla 17: Termino es Factor OK");
											ind_term = ind_factor;}
       			|termino POR factor 	 	{printf("\nRegla 18: Multiplicacion OK");
											ind_term = crear_terceto(POR, ind_term, ind_factor);}
       			|termino DIVIDIDO factor  	{printf("\nRegla 19: Division OK");
											ind_term = crear_terceto(DIVIDIDO, ind_term, ind_factor);}
       			;

factor: 
			ID 						{printf("\nRegla 20: Factor es ID OK: %s", yytext);
									int tipo = chequearVarEnTabla(yylval.str_val);
									chequearTipoDato(tipo);
									int pos = buscarIDEnTabla($1);
									ind_factor = crear_terceto(NOOP, pos, NOOP);}
      		|P_A expresion P_C		{printf("\nRegla 21: Parentesis expresion Parentesis");}
			|CTE_INT				{printf("\nRegla 22: Constante Entera Decimal OK: %s", yytext);
									chequearTipoDato(Int);
									int pos = agregarCteIntATabla(yylval.int_val);
									ind_factor = crear_terceto(NOOP, pos, NOOP);
									}
			|CTE_INT_BIN			{printf("\nRegla 23: Constante Entera Binaria OK: %s", yytext);
									chequearTipoDato(Int);
									int pos = agregarCteIntATabla(yylval.int_val);
									ind_factor = crear_terceto(NOOP, pos, NOOP);}
			|CTE_INT_EXA			{printf("\nRegla 24: Constante Entera Hexa OK: %s", yytext);
									chequearTipoDato(Int);
									int pos = agregarCteIntATabla(yylval.int_val);
									ind_factor = crear_terceto(NOOP, pos, NOOP);}
			|CTE_FLOAT				{printf("\nRegla 25: Constante Float OK: %s", yytext);
									chequearTipoDato(Float);
									int pos = agregarCteFloatATabla(yylval.float_val);
									ind_factor = crear_terceto(NOOP, pos, NOOP);
									}
			
    			;
	
funcion_long:
						 LONG P_A C_A lista_const C_C P_C		{printf("\nRegla 26: Funcion LONG");}
						;
						
lista_const:
					CTE_INT 									{printf("\nRegla 27: Lista de Constantes es Constante Entera");
																agregarCteIntATabla(yylval.int_val);
																}
					| lista_const COMA CTE_INT 					{printf("\nRegla 28: Lista de constantes es lista, contante entera");
																agregarCteIntATabla(yylval.int_val);
																}
					;

/* Cosas de while */
rutina_while:
														{
															ind_bwhile = crear_terceto(WHILE, NOOP, NOOP);
															apilar_IEP();
														};
rutina_do:
														{
															ind_then=crear_terceto(DO,NOOP,NOOP);
															ponerSaltosThen();
														};
														
rutina_id_while:
					{
						printf("\nRegla 29.1: ID: %s", yytext);
						int tipo = chequearVarEnTabla(yytext);
						chequearTipoDato(tipo);
						int pos=buscarIDEnTabla(yytext);
						ind_cond_salto=crear_terceto(NOOP, pos, NOOP);
					};

rutina_lista_expresiones:
					{
										printf("\nRegla 29.2: fin lista de expresiones");
										resetTipoDato();

										// Creo una variable @inlist (o la reutilizo)
										int posInlist = agregarVarATabla2("@inlist", Int);
										int pos = agregarCteIntATabla(0);
										crear_terceto(ASIG, posInlist, pos); //Inicializo @inlist en 0 (falso)
										ind_salto_inlist=crear_terceto(JMP, NOOP, NOOP); //Saltea la asignacion de verdadero

										pos = agregarCteIntATabla(1);
										int ind_ok = crear_terceto(INLIST_TRUE, NOOP, NOOP);
										crear_terceto(ASIG, posInlist, pos); //A este terceto se llega si es verdadero, asigno 1 a @inlist
										ind_inlist = crear_terceto(INLIST_CMP, NOOP, NOOP);
										crear_terceto(CMP, posInlist, pos); //Comparo @inlist contra verdadero

										// Relleno saltos
										comp_bool_actual=IGUAL;
										ponerSaltoInlist(ind_ok);

					};
					
iteracion:
				WHILE rutina_while ID rutina_id_while IN C_A lista_expresiones rutina_lista_expresiones C_C DO rutina_do bloque ENDWHILE	{
										printf("\nRegla 29: Iteracion Especial OK: %s", $3);
										always = crear_terceto(JMP,ind_bwhile,NOOP);
										ind_endwhile = crear_terceto(ENDWHILE, NOOP, NOOP);
										ponerSaltoEndwhile();
										desapilar_IEP();}
				| WHILE rutina_while P_A condicion P_C DO rutina_do bloque ENDWHILE				{
										printf("\nRegla 30: Iteracion OK");
										always = crear_terceto(JMP,ind_bwhile,NOOP);
										ind_endwhile = crear_terceto(ENDWHILE, NOOP, NOOP);
										ponerSaltoEndwhile();
										desapilar_IEP();}
				;

lista_expresiones:
    lista_expresiones COMA expresion        {
															printf("\nRegla 31: lista_expresiones es lista_expresiones COMA expresion");
															int ind_aux=crear_terceto(CMP, ind_cond_salto, ind_expr);
															ind_inlist_a=crear_terceto(BEQ, ind_aux, NOOP);
															apilar_inlist();
															//ind_lepc = crear_terceto(PUNTO_COMA, ind_lepc, ind_expr);
											}
    | expresion                             {
															printf("\nRegla 32: lista_expresiones es expresion");
															ind_lepc = ind_expr;
															int ind_aux=crear_terceto(CMP, ind_cond_salto, ind_lepc);
															ind_inlist_a=crear_terceto(BEQ, ind_aux, NOOP);
															apilar_inlist();
											};
					
					
sentencia:
					asignacion				{printf("\nRegla 33: Sentencia es Asignacion OK");
											ind_sent = ind_asig;}
					|funcion_long			{printf("\nRegla 34: Sentencia es FUNCION_LONG OK");}
					|seleccion				{printf("\nRegla 35: Sentencia es seleccion OK");
											ind_sent = ind_bif;}
					|iteracion				{printf("\nRegla 36: Sentencia es iteracion OK");
											ind_sent = ind_bwhile;}
					|entrada				{printf("\nRegla 37: Sentencia es entrada OK");
											ind_sent = ind_lectura;}
					|salida					{printf("\nRegla 38: Sentencia es salida OK");
											ind_sent = ind_escritura;}
					;

salida:
					DISPLAY CTE_STRING		{printf("\nRegla 39: Salida es DISPLAY CTE_STRING OK. CT: &s", $2);
											int pos = agregarCteStringATabla(yylval.str_val);
											ind_escritura = crear_terceto(DISPLAY, pos, NOOP);}
					| DISPLAY ID			{printf("\nRegla 40: Salida es DISPLAY ID OK. ID: %s", $2);
											chequearVarEnTabla($2);
											int pos = buscarIDEnTabla($2);
											ind_escritura = crear_terceto(DISPLAY, pos, NOOP);}
					;
entrada:
					GET ID					{printf("\nRegla 41: Entrada OK. ID: %s", $2);
											chequearVarEnTabla($2);
											int pos = buscarIDEnTabla($2);
											ind_lectura = crear_terceto(GET, pos, NOOP);}
					;
bloque:  
      sentencia								{printf("\nRegla 42: bloque es sentencia OK");
											ind_bloque = ind_sent;}
      |bloque sentencia						{printf("\nRegla 43: bloque es bloque sentencia OK");
											ind_bloque = crear_terceto(BLOQ, ind_bloque, ind_sent); //Comentar para no generar terceto de sentencia
											}
      ;

/* Cosas de if */

rutina_if:
														{
															ind_if=crear_terceto(IF, NOOP, NOOP);
															apilar_IEP();
														};
rutina_then:
														{
															ind_then=crear_terceto(THEN,NOOP,NOOP);
															ponerSaltosThen();
														};
rutina_else:
														{
														 	always = crear_terceto(JMP, NOOP, NOOP);
															ind_else = crear_terceto(ELSE,NOOP,NOOP);
															ponerSaltosElse();
														};
	  
seleccion:
						IF rutina_if P_A condicion P_C THEN rutina_then bloque ENDIF			{
																					printf("\nRegla 44: seleccion simple OK");
																					ind_endif=crear_terceto(ENDIF,NOOP,NOOP);
																					ind_else=ind_endif;
																					ponerSaltosElse();
																					desapilar_IEP();
																					ind_bif=ind_if;}
						| IF rutina_if P_A condicion P_C THEN rutina_then bloque_true ELSE rutina_else bloque ENDIF {
																					printf("\nRegla 45: seleccion con else OK");
																					ind_endif=crear_terceto(ENDIF,NOOP,NOOP);
																					ponerSaltoEndif();
																					desapilar_IEP();
																					ind_bif=ind_if;}
						;

bloque_true:
	bloque												{
															printf("\nRegla 46*: bloque_true es bloque");
															ind_btrue = ind_bloque;
														};
						
/* Expresiones logicas */

condicion:
    termino_logico {ind_tlogic_izq = ind_tlogic;} AND {falseIzq = crear_terceto(saltarFalse(comp_bool_actual), ind_tlogic, NOOP);} termino_logico {
														printf("\nRegla 46: condicion es termino_logico AND termino_logico");
														falseDer =  crear_terceto(saltarFalse(comp_bool_actual), ind_tlogic, NOOP);
														ind_xplogic = crear_terceto(AND, ind_tlogic_izq, ind_tlogic);}
    | termino_logico {ind_tlogic_izq = ind_tlogic;} OR {verdadero = crear_terceto(saltarTrue(comp_bool_actual), ind_tlogic, NOOP);} termino_logico {
														printf("\nRegla 47: condicion es termino_logico OR termino_logico");
														falseDer =  crear_terceto(saltarFalse(comp_bool_actual), ind_tlogic, NOOP);
														ind_xplogic = crear_terceto(OR, ind_tlogic_izq, ind_tlogic);}
    | termino_logico                                    {printf("\nRegla 48: condicion es termino_logico");
														ind_xplogic = ind_tlogic;
														falseIzq = crear_terceto(saltarFalse(comp_bool_actual), ind_tlogic, NOOP);}
    | NOT termino_logico                                {printf("\nRegla 49: condicion es NOT termino_logico");
														ind_xplogic = ind_tlogic;
														falseIzq = crear_terceto(saltarTrue(comp_bool_actual), ind_tlogic, NOOP);}
;


termino_logico:
    expr_aritmetica_izquierda comp_bool expresion {
															printf("\nRegla 50: termino_logico es expr_aritmetica_izquierda comp_bool expresion");
															resetTipoDato();
															ind_tlogic = crear_terceto(CMP, ind_expr_izq, ind_expr);
														}
													;
expr_aritmetica_izquierda:
	expresion								{
															printf("\nRegla 51: expr_aritmetica_izquierda es expresion");
															ind_expr_izq = ind_expr;
														}

comp_bool:
    MENOR                                               {
															printf("\nRegla 52: comp_bool es MENOR");
															comp_bool_actual = MENOR;
														}
    |MAYOR                                              {
															printf("\nRegla 53: comp_bool es MAYOR");
															comp_bool_actual = MAYOR;
														}
    |MENOR_IGUAL                                        {
															printf("\nRegla 54: comp_bool es MENOR_IGUAL");
															comp_bool_actual = MENOR_IGUAL;
														}
    |MAYOR_IGUAL                                        {
															printf("\nRegla 55: comp_bool es MAYOR_IGUAL");
															comp_bool_actual = MAYOR_IGUAL;
														}
    |IGUAL                                              {
															printf("\nRegla 56: comp_bool es IGUAL");
															comp_bool_actual = IGUAL;
														}
    |DISTINTO                                           {
															printf("\nRegla 57*: comp_bool es DISTINTO");
															comp_bool_actual = DISTINTO;
														};
						
%%
int main(int argc,char *argv[])
{
  if ((yyin = fopen(argv[1], "rt")) == NULL)
  {
	printf("\nNo se puede abrir el archivo: %s\n", argv[1]);
  }
  else
  {
	yyparse();
  }
  fclose(yyin);
  return 0;
}
int yyerror(char *s)
{
	fprintf(stderr, "\nError de sintaxis. Error: %s\n", s);
	system ("Pause");
	exit (1);
}
/** Compara el tipo de dato pasado por parámetro contra el que se está trabajando actualmente en tipoDatoActual.
Si es distinto, tira error. Si no hay tipo de dato actual, asigna el pasado por parámetro. */
void chequearTipoDato(int tipo){
	char mensaje_error[100];
	if(tipoDatoActual == sinTipo){
		tipoDatoActual = tipo;
		return;
	}
	if(tipoDatoActual != tipo){
		sprintf(mensaje_error, "Error: no se puede convertir. Tipos de datos diferentes. (enteros con reales). Actual: %d Tipo: %d", tipoDatoActual, tipo);
		yyerror(mensaje_error);
	}
}

/** Vuelve tipoDatoActual a sinTipo */
void resetTipoDato(){
	tipoDatoActual = sinTipo;
}