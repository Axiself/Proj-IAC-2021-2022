; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
;
; IST 2021/22
; Cadeira de IAC
;
; Entrega Final
; 
; Grupo 18:
; 	-> Rui Amaral: ist1103155
; 	-> Miguel Gomes: ist1103559
; 	-> JP: ist1xxxxx
;
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>



; Controlos:
;   0 move para a esquerda 
;   2 move para a direita
;   4 diminui o display
;   7 aumenta o display
;   8 move o meteoro


; | ------------------------------------------------------------------ |
; | --------------------------- Constantes --------------------------- |
; | ------------------------------------------------------------------ |


; COUNTER E TECLADO

DISPLAYS   EQU 0A000H                   ; endereço dos displays de 7 segmentos (periférico POUT-1)
TEC_LIN    EQU 0C000H                   ; endereço das [Linha]s do teclado (periférico POUT-2)
TEC_COL    EQU 0E000H                   ; endereço das colunas do teclado (periférico PIN)
MASCARA    EQU 0FH                      ; para isolar os 4 bits de menor peso, ao ler as colunas do teclado

; ECRÃ

SELECIONA_ECRA			EQU 6004H
DEFINE_LINHA            EQU 600AH       ; endereço do comando para definir a linha
DEFINE_COLUNA           EQU 600CH       ; endereço do comando para definir a coluna
DEFINE_PIXEL            EQU 6012H       ; endereço do comando para escrever um pixel
APAGA_AVISO             EQU 6040H       ; endereço do comando para apagar o aviso de nenhum cenário selecionado
APAGA_ECRAS				EQU 6002H		; endereço do comando para apagar todos os pixels já desenhados
APAGA_ECRA              EQU 6000H       ; endereço do comando para apagar todos os pixeis de um certo ecrã
SELECIONA_CENARIO_FUNDO EQU 6042H       ; endereço do comando para selecionar uma imagem de fundo
SELECIONA_MEDIA         EQU 6048H
PLAY_MEDIA              EQU 605AH
COLUNA_MAX_ECRA 		EQU 63
LINHA_MAX_ECRA 			EQU 31

; FIGURAS 

COR_F        EQU 0F00FH
COR_M        EQU 0FF00H
COR_E        EQU 0F0F0H
COR_CINZENTO EQU 0D888H
COR_ROXO     EQU 0FF0FH
ALTURA       EQU  3         
LARGURA      EQU  3
LINHA        EQU  29                    ; linha do boneco (a meio do ecrã)) (estatica)
COLUNA       EQU  31                    ; coluna do boneco (a meio do ecrã) (inicial)
MISSILE_RANGE EQU 12	

; TECLAS

TEC_ROV_ESQ 			EQU 0000H
TEC_ROV_DIR 			EQU 0002H


; | ------------------------------------------------------------------ |
; | ----------------------------- Dados ------------------------------ |
; | ------------------------------------------------------------------ |

PLACE 2000H

; Reserva de espaço para as pilhas
STACK 100H                              ; espaço reservado para a pilha 
SP_inicial_principal:                   ; endereco do SP

STACK 100H
SP_inicial_teclado:

STACK 100H
SP_inicial_rover:

STACK 100H
SP_inicial_missil:

; Stacks para as várias instâncias do processo dos meteoros
STACK 100H
SP_inicial_meteoro0:
STACK 100H
SP_inicial_meteoro1:
STACK 100H
SP_inicial_meteoro2:
STACK 100H
SP_inicial_meteoro3:


Linha:
	WORD 16
Tecla:
	WORD 0
Coluna:
	WORD 0
Counter:
	WORD 0
LinhaAux:
	WORD 0
Meteor_exists:
	WORD 1
Move_flag:
	WORD 0                       		; 0 para none, 1 for left, 2 for right
tecla_pressionada:
	LOCK 0
tecla_continua:
	LOCK 0
meteor_lock:
    LOCK 0
missile_lock:                           ;0- doesnt exist, 1-exists, 2-exists and will move 
    LOCK 0
energy_lock: 
    LOCK 0

Interrupcoes:
	WORD int_meteor
    WORD int_missile
    WORD int_energy

meteor_SP_tab:
	WORD SP_inicial_meteoro0
	WORD SP_inicial_meteoro1
	WORD SP_inicial_meteoro2
	WORD SP_inicial_meteoro3
	

; Figuras
Rover: WORD ALTURA, LARGURA, LINHA, COLUNA, R_tab
; Altura, Largura, Linha, Coluna, Endereço do sprite, Tipo de meteoro (bom/mau)
Meteor0:  WORD 1, 1, 0, 0, 0, 0
Meteor1:  WORD 1, 1, 0, 0, 0, 0
Meteor2:  WORD 1, 1, 0, 0, 0, 0
Meteor3:  WORD 1, 1, 0, 0, 0, 0

Missile: WORD 0, 0     					; Linha, Coluna
         WORD MISSILE_RANGE       		; movimentos restantes (ate desaparecer)
         WORD 0        					; 0- doesnt exist, 1- exists 

; Sprites
R_sprite: WORD COR_F, 0, COR_F
        WORD 0, COR_F, 0
        WORD COR_F, 0, COR_F
R_tab:
	WORD R_sprite
; Meteoros maus
Mm_tab:
	WORD Mm_sprite0
	WORD Mm_sprite1
	WORD Mm_sprite2
	WORD Mm_sprite3
	WORD Mm_sprite4

Mm_sprite0: WORD COR_CINZENTO
Mm_sprite1: WORD COR_CINZENTO, COR_CINZENTO
		WORD COR_CINZENTO, COR_CINZENTO
Mm_sprite2: WORD 0, COR_M, COR_M
		WORD COR_M, COR_M, 0
		WORD 0, COR_M, COR_M
Mm_sprite3: WORD 0, COR_M, COR_M, COR_M
		WORD COR_M, COR_M, 0, 0
		WORD COR_M, COR_M, COR_M, COR_M
		WORD 0, COR_M, 0, COR_M
Mm_sprite4: WORD 0, COR_M,  COR_M,  COR_M, COR_M
		WORD COR_M, COR_M, COR_M, 0, 0
		WORD COR_M, COR_M, COR_M, COR_M, COR_M
		WORD COR_M, COR_M, COR_M, COR_M, COR_M
		WORD 0, COR_M, 0, 0, COR_M

; Meteoros bons
Mb_tab:
	WORD Mb_sprite0
	WORD Mb_sprite1
	WORD Mb_sprite2
	WORD Mb_sprite3
	WORD Mb_sprite4

Mb_sprite0: WORD COR_CINZENTO
Mb_sprite1: WORD COR_CINZENTO, COR_CINZENTO
		WORD COR_CINZENTO, COR_CINZENTO
Mb_sprite2: WORD 0, COR_E, COR_E
		WORD COR_E, COR_E, 0
		WORD 0, COR_E, COR_E
Mb_sprite3: WORD 0, COR_E, COR_E, COR_E
		WORD COR_E, COR_E, 0, 0
		WORD COR_E, COR_E, COR_E, COR_E
		WORD 0, COR_E, 0, COR_E
Mb_sprite4: WORD 0, COR_E,  COR_E,  COR_E, COR_E
		WORD COR_E, COR_E, COR_E, 0, 0
		WORD COR_E, COR_E, COR_E, COR_E, COR_E
		WORD COR_E, COR_E, COR_E, COR_E, COR_E
		WORD 0, COR_E, 0, 0, COR_E


; | ------------------------------------------------------------------ |
; | ----------------------------- Código ----------------------------- |
; | ------------------------------------------------------------------ |

PLACE 0H


MOV  SP, SP_inicial_principal           ; inicializa SP para a palavra a seguir
                                        ; à última da pilha
MOV BTE, Interrupcoes
EI0
EI1
EI2
EI

MOV  [APAGA_AVISO], R1                  ; apaga o aviso de nenhum cenário selecionado (o valor de R1 não é relevante)
MOV  [APAGA_ECRAS], R1                   ; apaga todos os pixels já desenhados (o valor de R1 não é relevante)
MOV  R0, 0                              ; cenário de fundo número 0
MOV  [SELECIONA_CENARIO_FUNDO], R0      ; seleciona o cenário de fundo



MOV R0, DISPLAYS
MOV  R1, 0
MOV [R0], R1                            ; reset display

MOV R0, Rover 
CALL write_something                    ; inicializa o rover

CALL P_teclado							; inicializa processo que gere o teclado
CALL P_rover							; inicializa processo do movimento do rover
CALL create_missile

MOV R1, 3
gera_meteoros:							; Cria as quatro instâncias do processo dos meteoros
	CALL P_meteors
	SUB R1, 1
	JNN gera_meteoros


waiting:
	WAIT
	JMP waiting							; ciclo temporario para testar processos

PROCESS SP_inicial_teclado

P_teclado:

	MOV  R2, TEC_LIN		; endereço do periférico das linhas
	MOV  R3, TEC_COL		; endereço do periférico das colunas
	MOV  R5, MASCARA		; para isolar os 4 bits de menor peso, ao ler as colunas do teclado

espera_tecla:

	YIELD								; ponto de fuga pois este ciclo pode ser bloqueante
	MOV  R1, 8	 			; primeira linha a testar é a linha 4 
verifica_linhas:                           ; neste ciclo espera-se até uma tecla ser premida
	MOVB [R2], R1			; escrever no periférico de saída (linhas)
	MOVB R0, [R3]			; ler do periférico de entrada (colunas)
	AND  R0, R5			; elimina bits para além dos bits 0-3
	JNZ converte;
	SHR R1, 1							; passa à próxima linha
	JZ espera_tecla						; espera até haver atividade no teclado
	JMP verifica_linhas					; repete para a prox linha
converte:
	CALL converte_tecla;				; coloca o valor da tecla premida em R6
	MOV [tecla_pressionada], R6				; desbloqueia processos que esperam por uma tecla premida

ha_tecla:

	YIELD								; ponto de fuga pois este ciclo pode ser bloqueante
	MOV  R1, 8	 			; primeira linha a testar é a linha 4 
	MOV [tecla_continua], R6			; desbloqueia processos que dependem de teclas premidas continuamente
verifica_linhas2:
	MOVB [R2], R1			; escrever no periférico de saída (linhas)
	MOVB R0, [R3]			; ler do periférico de entrada (colunas)
	AND  R0, R5			; elimina bits para além dos bits 0-3
	JNZ ha_tecla;						; se há uma tecla a ser premida, espera até não haver
	SHR R1, 1							; passa à próxima linha
	JZ espera_tecla						; quando não houver tecla a ser premida volta ao espera_tecla
	JMP verifica_linhas2				; repete para a prox linha
	
; ----------------------------------

PROCESS SP_inicial_rover

P_rover:

	MOV R0, Rover						; endereço do rover
	MOV R4, [R0 + 2]					; largura do rover
	MOV R3, COLUNA_MAX_ECRA					; coluna de pixeis do limite direio do ecrã
	ADD R3, 1
	SUB R3, R4		 					; posição maxima que o rover pode ocupar tendo em conta a sua largura

check_move_direction:
	MOV R5, [tecla_continua]
	CMP R5, TEC_ROV_ESQ
	JNZ move_right
	MOV R1, -1							; valor a ser somado à posição do rover para este se mover para a esquerda
	JMP move_rover
move_right:
	CMP R5, TEC_ROV_DIR
	JNZ check_move_direction
	MOV R1, 1							; valor a ser somado à posição do rover para este se mover para a direita

move_rover:
	MOV R2, [R0 + 6]					; posição atual do rover
	ADD R2, R1							; nova posição do rover após movimento
	JN check_move_direction				; se passa do limite esquerdo, não é executado movimento
	CMP R2, R3
	JGT check_move_direction			; se passa do limite direito, não é executado movimento
	CALL delete_something
	MOV [R0 + 6], R2					; altera posição do rover para se desencadear o movimento
	CALL write_something
	CALL atraso
	JMP check_move_direction			; este processo nunca termina

; -----------------------------------------------------------------


; -----------------------------------------------------------------

PROCESS SP_inicial_missil

create_missile:
    MOV R0, [tecla_pressionada]         ;lock
    CMP R0, 7
    JNZ create_missile

    MOV R0, [Missile+6]
    CMP R0, 1
    JZ create_missile                   ;checks if it exists already
    MOV R0, 1
    MOV [Missile+6], R0
    MOV R0, MISSILE_RANGE
    MOV [Missile+4], R0

    MOV R1, LINHA
    SUB R1, 1
    MOV [Missile], R1
    MOV R2, [Rover+6]
    ADD R2, 1
    MOV [Missile+2], R2
    MOV R3, COR_ROXO
    CALL escreve_pixel

mov_missile:
    MOV R0, [missile_lock]              ;locks it 

    MOV R0, [Missile+4]                 ;verifies movements left
    CMP R0, 0
    JZ delete_missile

    SUB R0, 1
    MOV [Missile+4], R0                 ;updates movements left

escreve_missile:
    MOV R1, [Missile]
    MOV R2, [Missile+2]
    MOV R3, 0H
    CALL escreve_pixel

    MOV R1, [Missile]
    SUB R1, 1
    MOV [Missile], R1
    MOV R2, [Missile+2]
    MOV R3, COR_ROXO
    CALL escreve_pixel
    JMP mov_missile

delete_missile:
	MOV R1, 0
    MOV [Missile+6], R1
    MOV R1, [Missile]
    MOV R2, [Missile+2]
    MOV R3, 0H
    CALL escreve_pixel
    JMP create_missile
; -----------------------------------------------------------------

; Argurmentos: R1 - Número da instância do processo.

PROCESS SP_inicial_meteoro0

P_meteors:
	MOV R10, R1							; Cópia do número de instância
	SHL R10, 1							; Tabela dos SPs é uma tabela de words
	MOV R9, meteor_SP_tab
	MOV SP, [R9 + R10]					; Atualiza stack do processo para a stack da instância atual

	MOV R0, Meteor0
	MOV R10, R1							; Cópia do número de instância
	MOV R2, 12
	MUL R10, R2							; Cada meteoro tem 6 words
	ADD R0, R10							; Endereço do meteoro
	MOV R2, R1
	SHL R2, 3							; Cada meteoro vai nascer 8 interrupções após o anterior

meteor_loop:
	MOV R11, [meteor_lock]				; Espera pela interrupção

	CMP R2, 0
	JLT move_meteor
	SUB R2, 1
	JNZ meteor_loop						; Enquanto as 8 interrupções não passarem, não nasce novo meteoro
new_meteor:
	SUB R2, 1
	CALL cria_meteoro					; Adiciona meteoro após um certo número de ciclos da interrupção
	MOV R5, 4							; Número de mudanças de sprite restantes
	MOV R3, 3							; O sprite do meteoro muda a cada 3 movimentos
move_meteor:

	MOV R4, [R0 + 4]
	ADD R4, 1							; Aumenta linha do meteoro
	MOV [R0 + 4], R4

	CMP R5, 0
	JZ draw_meteor						; Caso o meteoro já tenha o último sprite possível

	SUB R3, 1							; Ao fim dos 3 movimentos, muda o sprite
	JNN draw_meteor
	MOV R4, [R0 + 8]
	ADD R4, 2							; Passa para o proximo endereço da tabela de sprites
	MOV [R0 + 8], R4
	MOV R4, [R0]
	ADD R4, 1							; Aumenta altura do meteoro
	MOV [R0], R4
	MOV R4, [R0 + 2]
	ADD R4, 1							; Aumenta largura do meteoro
	MOV [R0 + 2], R4

	SUB R5, 1							; Menos uma mudança de sprite restante

	MOV R3, 3							; Reseta contador de movimentos
draw_meteor:
	CALL colision_check
	CMP R7, 0
	JNZ new_meteor						; Se houver colisão, destroi o meteoro e cria um novo

	MOV R10, R1							; Cópia do número de instância
	ADD R10, 1							; Ecrã em que está o meteoro
	MOV [APAGA_ECRA], R10
	MOV [SELECIONA_ECRA], R10			; Seleciona o ecrã em que vai movido o meteoro
	CALL write_something				; Desenha o meteoro

	MOV R11, 0
	MOV [SELECIONA_ECRA], R11 			; Repõe ecrã
	JMP meteor_loop



	
;sub_counter:                            ; tecla 4
;    MOV R2, 0
;    MOV [Move_flag], R2                 ; desativa a  flag para mover continuamente (so por precaucao)
;
;    CMP R1, 4
;    JNZ add_counter
;    MOV R1, -1
;    CALL change_counter                 ; diminui o counter (R1 e o valor incrementado ao counter)
;    JMP next

;add_counter:                            ; tecla 7
;    CMP R1, 7
;    JNZ move_met
;    MOV R1, 1
;    CALL change_counter                 ; aumenta o counter (R1 e o valor incrementado ao counter)
;    JMP next


; | ------------------------------------------------------------------ |
; | ---------------------------- Funções ----------------------------- |
; | ------------------------------------------------------------------ |

; **********************************************************************
;
; colision_check - Verifica se um certo meteoro colide com o rover, chão
;	ou com um míssil na sua posição atual. Retorna 1 no registo R7 caso
;	haja colisão e 0 caso contrário.
; Argumentos:	R0 - Endereço do meteoro em questão.
;
; **********************************************************************

colision_check:
    PUSH R0
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    PUSH R5
    PUSH R6

    MOV R1, [R0 + 4]                    ; Primeira linha ocupada pelo meteoro
    MOV R2, [R0 + 6]                    ; Primeira coluna ocupada pelo meteoro
    MOV R3, [R0]                        ; Altura
    MOV R4, [R0 + 2]                    ; Largura

	ADD R3, R1
	SUB R3, 1							; Última linha ocupada pelo meteoro

	ADD R4, R2
	SUB R4, 1							; Última coluna ocupada pelo meteoro

	MOV R5, LINHA_MAX_ECRA
	CMP R3, R5							; Checks if the meteor has hit the ground
	JGT colided

	MOV R5, [Missile + 6]				; Checks if a missile has been fired
	CMP R5, 0
	JZ check_rover_colision

	MOV R5, [Missile]					; Linha em que está o míssil
	CMP R3, R5							; Se o meteoro está acima do míssil não há colisão
	JLT check_rover_colision

	MOV R5, [Missile + 2]				; Coluna em que está o míssil
	CMP R4, R5							; Se o meteoro está à esquerda do míssil não há colisão
	JLT check_rover_colision
	CMP R2, R5							; Se o meteoro está à direita do míssil não há colisão
	JGT check_rover_colision

	JMP colided

check_rover_colision:
	MOV R5, LINHA_MAX_ECRA
	MOV R6, [Rover]
	SUB R5, R6
	ADD R5, 1							; Primeira linha ocupada pelo rover
	CMP R3, R5							; Se o meteoro está acima do rover, não há colisão
	JLT no_colision

	MOV R5, [Rover + 2]					; Largura do rover
	MOV R6, [Rover + 6]					; Primeira coluna ocupada pelo rover
	ADD R5, R6
	SUB R5, 1							; Última coluna ocupada pelo rover
	CMP R2, R5							; Se o meteoro está à direita do rover não há colisão
	JGT no_colision
	CMP R4, R6							; Se o meteoro está à esquerda do rover não há colisão
	JLT no_colision
	
	JMP colided

colided:
	MOV R7, 1
	JMP end_colision_check
no_colision:
	MOV R7, 0

end_colision_check:
	POP R6
	POP R5
	POP R4
	POP R3
	POP R2
	POP R1
	POP R0
	RET
	
	

; **********************************************************************
;
; cria_meteoro - Gera um novo meteoro no topo do ecrã.
; Argumentos:	R1 - Número identificador do meteoro a gerar.
;
; **********************************************************************

cria_meteoro:

	PUSH R0
	PUSH R1
	PUSH R2
	PUSH R10

	MOV R2, R1
	ADD R2, 1							; Número do ecrã a ser utilizado
	MOV [SELECIONA_ECRA], R2			; Seleciona o ecrã em que vai ser colocado o meteoro
	MOV [APAGA_ECRA], R2				; Apaga o meteoro antigo (caso este exista)
	MOV R0, Meteor0
	MOV R2, 12
	MUL R1, R2							; Cada meteoro ocupa 12 bytes
	ADD R0, R1							; Passa para o endereço do meteoro certo

	CALL gera_aleatorio
	CMP R10, 2							; Se R10 = 0 ou 1, o meteoro é bom (~25% de chance)
	JLT meteoro_bom
	MOV R2, Mm_tab
	MOV [R0 + 8], R2					; Seleciona tabela de sprites do meteoro mau
	MOV R2, 0
	MOV [R0 + 10], R2					; Define o meteoro como mau
	JMP get_column
meteoro_bom:
	MOV R2, Mb_tab
	MOV [R0 + 8], R2					; Seleciona tabela de sprites do meteoro bom
	MOV R2, 1
	MOV [R0 + 10], R2					; Define o meteoro como bom
	
get_column:
	CALL gera_aleatorio
	SHL R10, 3							; Multiplica por 8
	ADD R10, 3							; Coluna do novo meteoro
	MOV [R0 + 6], R10
	MOV R2, 1
	MOV [R0], R2						; Repõe altura do meteoro
	MOV [R0 + 2], R2					; Repõe largura do meteoro
	MOV R2, -1
	MOV [R0 + 4], R2					; Repõe linha do meteoro
	CALL write_something						; Desenha novo meteoro
	
	MOV [SELECIONA_ECRA], R2			; Repõe ecrã selecionado
	POP R10
	POP R2
	POP R1
	POP R0
	RET


; **********************************************************************

; gera_aleatorio - Gera um número "aleatório" entre 0 a 7 recorrendo à
;	leitura de um periférico. Coloca este número no registo R10.
; Argumentos:	Nenhum
;
; **********************************************************************

gera_aleatorio:

	PUSH R2
	MOV R10, [TEC_COL]
	SHR R10, 5							; Elimina bits não aleatórios ficando só os bits 7-5
	MOV R2, 7
	AND R10, R2							; Máscara para ficarem apenas os 3 primeiros bits

	POP R2
	RET


; **********************************************************************

; converte_tecla - Converte uma posição not teclado para a sua tecla
;	correspondente. Coloca o valor da tecla no registo R6.
; Argumentos:   R0 - Coluna
;				R1 - Linha
;
; **********************************************************************

converte_tecla:

	PUSH R0
	PUSH R1
	PUSH R2
	PUSH R3

	MOV R2, -1							; Coluna
	MOV R3, -1							; Linha

converte_coluna:

	ADD R2, 1
	SHR R0, 1
	JNZ converte_coluna

converte_linha:

	ADD R3, 1
	SHR R1, 1
	JNZ converte_linha

	MOV R6, R3
	MOV R0, 4							; multiplicação por 4
	MUL R6, R0 							; tecla = 4 x linha + coluna
	ADD R6, R2

	POP R3
	POP R2
	POP R1
	POP R0
	RET

; **********************************************************************

; tecla premida - move figura para quando a tecla continua premida
; Argumentos:   R0 - 1 quando move para a esquerda e 2 para a direita
;
; **********************************************************************

tecla_premida:
    PUSH R0
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    PUSH R5

    MOV R0, [Move_flag]
    CMP R0, 1
    JZ left
    JMP right                           ; seleciona a direcao do movimento

left:
    MOV R2, [Rover + 6]                ; border check
    CMP R2, 0
    JZ end6

    MOV R0, Rover
    CALL delete_something


    MOV R0, [Rover + 6]                ; menos coluna 
    SUB R0, 1
    MOV [Rover + 6], R0                ; atualiza a coluna da figura
    MOV R0, Rover
    CALL write_something
    JMP end5

right:
    MOV R1, [Rover + 6]                ; coluna
    MOV R2, [Rover + 2]                ; largura
    ADD R1, R2
    SUB R1, 1
    MOV R2, 63
    SUB R1, R2
    JZ end6                             ; coluna + largura - maximo (63) - 1 = 0 -> end (border check)

    MOV R0, Rover
    CALL delete_something

    MOV R0, [Rover + 6]                ; mais coluna 
    ADD R0, 1
    MOV [Rover + 6], R0                ; atualiza a coluna da figura
    MOV R0, Rover
    CALL write_something
    JMP end5

end6:                                   ; quando chega ao final, desativa a flag de mover
    MOV R1, 0
    MOV [Move_flag], R1
end5:
    CALL atraso                         ; atrasa o movimento
    POP R5
    POP R4
    POP R3
    POP R2
    POP R1
    POP R0
    RET

; **********************************************************************

; atraso - decrementa num ciclo para atrasar whatever
; Argumentos:  None
;
; **********************************************************************

atraso:

    PUSH    R11

    MOV     R11,  4000H
ciclo_atraso:
    SUB R11, 1
    JNZ ciclo_atraso

    POP R11
    RET


; **********************************************************************

; reset - resets linha (scan do teclado)
; Argumentos:   None
;               
; **********************************************************************
reset:
    PUSH R0
    MOV  R0, 16
    MOV  [Linha], R0                    ; Linha = 4 (1000) (16 /  1 000 bc SHR no inicio do ciclo)
    POP  R0
    RET

; **********************************************************************

; change_counter - adiciona R1 ao contador, escreve no display e atualiza a variavel counter
; Argumentos:   R1 - number to add
;               
; **********************************************************************
change_counter:
    PUSH  R0
    PUSH  R1
    MOV   R0, [Counter]
    ADD   R0, R1                        ; adiciona
    MOV   [Counter], R0                 ; atualiza o counter
    MOV   R1, DISPLAYS   
    MOV   [R1], R0                      ; write on display
    POP   R1
    POP   R0
    RET

; **********************************************************************

; write_something - escreve uma figura com o endereco da sua tabela
; Argumentos:   R0 - Endereco da tabela da figura
;               
; **********************************************************************
write_something:
    PUSH R0
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    PUSH R5
    PUSH R6
    PUSH R7

    MOV R1, [R0 + 4]                    ; Linha
    MOV R2, [R0 + 6]                    ; Coluna
    MOV R4, [R0]                        ; Altura
    MOV R5, [R0 + 2]                    ; Largura
    MOV R6, [R0 + 8]					; Endereço da tabela do sprite
	MOV R7, [R6]						; Endereço do sprite
    MOV R3, [R7]                        ; cor do primeiro pixel
prox_col2:
    CALL escreve_pixel 
    ADD R2, 1                           ; proxima coluna
    ADD R7, 2                           ; proximo pixel
    MOV R3, [R7]						; define cor para o proximo escreve_pixel
    SUB R5, 1                           ; menos uma coluna restante
    JZ prox_lin2                        ; se acabarem as colunas
    JMP prox_col2
prox_lin2:
    MOV R5, [R0 + 2]                    ; faltam todas as colunas outra vez
    MOV R2, [R0 + 6]                    ; coluna volta a primeira
    ADD R1, 1                           ; proxima linha
    SUB R4, 1                           ; menos uma linha restante
    JZ end3 
    JMP prox_col2
end3:
    POP R7
    POP R6
    POP R5
    POP R4
    POP R3
    POP R2
    POP R1
    POP R0
    RET

; **********************************************************************

; move_meteor - faz o meteoro descer uma linha (nao bate no rover)
; Argumentos:   none (ja sabemos o endereco do meteoro)
;
; **********************************************************************
;move_meteor:
    PUSH R0
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    PUSH R5
    MOV R0, [Meteor0 + 4]                ; linha
    MOV R1, [Meteor0]                    ; altura
    ADD R0, R1
    SUB R0, 1
    MOV R1, 31
    MOV R2, [Rover]
    SUB R1, R2
    SUB R0, R1                          ; border check  (se linha + altura - 1 = 31(max) - altura do rover chegou ao final)
    JZ reached_end
normal:
    MOV R0, Meteor0
    CALL delete_something               ; apaga o meteoro

    MOV R0, [Meteor0 + 4]
    ADD R0, 1
    MOV [Meteor0 + 4], R0                ; atualiza a linha do meteoro (aumenta por 1)
    MOV R0, Meteor0
    CALL write_something                ; escreve o meteoro
    JMP end4

reached_end:
    MOV R0, Meteor0
    CALL delete_something               ; apaga o meteoro quando chega ao fim 
    MOV R0, 0
    MOV [Meteor_exists], R0             ; desativa a flag do meteoro para ignorar tentativas de o mover quando nao existe

end4:
    POP R5
    POP R4
    POP R3
    POP R2
    POP R1
    POP R0
    RET

; **********************************************************************

; delete_something- apaga uma figura de um ecrã
; Argumentos: R0 - Tabela que define a figura que se pretende apagar
;
; **********************************************************************

delete_something: 
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    PUSH R5
    MOV R1, [R0 + 4]					; Linha da figura
    MOV R2, [R0 + 6]					; Coluna da figura
    MOV R4, [R0]						; Altura da figura
    MOV R5, [R0 + 2]                    ; Largura da figura
    MOV R3, 0                           ; define cor para o escreve_pixel
prox_col:
    CALL escreve_pixel
    ADD R2, 1                           ; prox col
    SUB R5, 1                           ; menos um de largura remaining
    JZ prox_lin
    JMP prox_col

prox_lin:
    MOV R5, [R0 + 2]                    ; reset largura
    MOV R2, [R0 + 6]                    ; reset coluna
    ADD R1, 1                           ; prox linha
    SUB R4, 1                           ; menos um de altura remaining
    JZ end2
    JMP prox_col

end2:
    POP R5
    POP R4
    POP R3
	POP R2
    POP R1
    RET
    
; **********************************************************************
; ESCREVE_PIXEL - Escreve um pixel na linha e coluna indicadas.
; Argumentos:   R1 - linha
;               R2 - coluna
;               R3 - cor do pixel (em formato ARGB de 16 bits)
;
; **********************************************************************
escreve_pixel:
    MOV  [DEFINE_LINHA], R1             ; seleciona a linha
    MOV  [DEFINE_COLUNA], R2            ; seleciona a coluna
    MOV  [DEFINE_PIXEL], R3             ; altera a cor do pixel na linha e coluna já selecionadas
    RET

; | ------------------------------------------------------------------ |
; | ------------------------- Interrupções --------------------------- |
; | ------------------------------------------------------------------ |


int_missile:
    PUSH R0

    MOV R0, [Missile+6]       ;check if it exists
    CMP R0, 0
    JZ missile_doesnt_exist
    MOV R0, 0
    MOV [missile_lock], R0      ;unlocks process
missile_doesnt_exist:    
    POP R0
    RFE
    
int_meteor:
    PUSH R0
    MOV R0, 1
    MOV [meteor_lock], R0
    POP R0
    RFE

int_energy:
    PUSH R0
    MOV R0, 1
    MOV [energy_lock], R0
    POP R0
    RFE
