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
; 	-> João Paulo: ist102081
;
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>



; Controlos:
;   0 move para a esquerda 
;   2 move para a direita
;   7 dispara o missil
;   C comeca o jogo
;   D para o jogo
;   E termina o jogo

; Ecras:
; 0 - normal
; 1 - start
; 2 - paused
; 3 - exploded
; 4 - energy 

; Sons: 
; 0 - startup d
; 1 - pause d
; 2 - unpause d
; 3 - termina
; 4 - morte (colisao) 
; 5 - morte (energia) 
; 6 - energia recebida 
; 7 - meteoro mau destruido 
; 8 - missil 

; | ------------------------------------------------------------------ |
; | --------------------------- Constantes --------------------------- |
; | ------------------------------------------------------------------ |


; COUNTER E TECLADO

DISPLAYS   EQU 0A000H                   ; endereço dos displays de 7 segmentos (periférico POUT-1)
TEC_LIN    EQU 0C000H                   ; endereço das [Linha]s do teclado (periférico POUT-2)
TEC_COL    EQU 0E000H                   ; endereço das colunas do teclado (periférico PIN)
MASCARA    EQU 0FH                      ; para isolar os 4 bits de menor peso, ao ler as colunas do teclado

; ECRÃ

SELECIONA_ECRA			EQU 6004H		; Seleciona o ecrã para os próximos comandos
DEFINE_LINHA            EQU 600AH       ; endereço do comando para definir a linha
DEFINE_COLUNA           EQU 600CH       ; endereço do comando para definir a coluna
DEFINE_PIXEL            EQU 6012H       ; endereço do comando para escrever um pixel
APAGA_AVISO             EQU 6040H       ; endereço do comando para apagar o aviso de nenhum cenário selecionado
APAGA_ECRAS				EQU 6002H		; endereço do comando para apagar todos os pixels já desenhados
APAGA_ECRA              EQU 6000H       ; endereço do comando para apagar todos os pixeis de um certo ecrã
SELECIONA_CENARIO_FUNDO EQU 6042H       ; endereço do comando para selecionar uma imagem de fundo
SELECIONA_OVERLAY       EQU 6046H		; Escolhe um cenário frontal
APAGA_OVERLAY           EQU 6044H		; Apaga cenário frontal
PLAY_MEDIA              EQU 605AH
COLUNA_MAX_ECRA 		EQU 63			; Número da última coluna do ecrã
LINHA_MAX_ECRA 			EQU 31			; Número da última linha do ecrã

; FIGURAS 

COR_F        EQU 0F00FH					; Azul
COR_M        EQU 0FF00H					; Vermelho
COR_E        EQU 0F0F0H					; Verde
COR_CINZENTO EQU 0D888H					; Cinzento
COR_ROXO     EQU 0FF0FH					; Roxo
COR_AZUL_CLARO EQU 0F0FFH				; Azul claro
ALTURA       EQU  3         			; Altura do rover
LARGURA      EQU  3						; Largura do rover
LINHA        EQU  29                    ; linha do rover (a meio do ecrã)) (estatica)
COLUNA       EQU  31                    ; coluna do rover (a meio do ecrã) (inicial)
MISSILE_RANGE EQU 12					; Alcance do míssil (default = 12)

; TECLAS

TEC_ROV_ESQ 			EQU 0000H		; Tecla que faz o rover andar para a esquerda
TEC_ROV_DIR 			EQU 0002H		; Tecla que faz o rover andar para a direita
TECLA_MISSIL			EQU 0007H		; Tecla que dispara míssil
TECLA_PAUSA				EQU 000DH		; Tecla que põe/tira o jogo da pausa
TECLA_TERMINAR			EQU 000EH		; Tecla que termina o jogo
TECLA_COMECAR			EQU 000CH		; Tecla que começa o jogo

RESET_METEOROS			EQU 0002H		; Valor que desencadeio um reset dos meteoros
RESET_MISSIL			EQU 0007H		; Valor que desencadeia um reset do míssil
; | ------------------------------------------------------------------ |
; | ----------------------------- Dados ------------------------------ |
; | ------------------------------------------------------------------ |

PLACE 2000H

jogo_suspendido:						; Define de o jogo está suspendido (1) ou não (0)
	WORD 0

auto_terminado:							; Identifica se o jogo acabou de forma controlado ou se
	WORD 1								; o jogador perdeu

; Reserva de espaço para as pilhas
STACK 100H
SP_inicial_principal:                   ; Pilha principal

STACK 100H
SP_inicial_teclado:

STACK 100H
SP_inicial_rover:

STACK 100H
SP_inicial_missil:

STACK 100H
SP_inicial_energia:

STACK 100H
SP_inicial_gamemode:


; Stacks para as várias instâncias do processo dos meteoros
STACK 100H
SP_inicial_meteoro0:
STACK 100H
SP_inicial_meteoro1:
STACK 100H
SP_inicial_meteoro2:
STACK 100H
SP_inicial_meteoro3:

Energy_counter:							; Energia atual do programa
	WORD 64H                            ;(100)
tecla_pressionada:						; Lock para teclas premidas uma vez
	LOCK 0
tecla_continua:							; Lock para teclas premidas de forma continua
	LOCK 0
meteor_lock:							; Lock para do P_meteors
    LOCK 0
missile_lock:                           ; Lock para o P_missil
    LOCK 0
energy_lock: 							; Lock para o P_energia
    LOCK 0

Interrupcoes:							; Tabela de interrupções
	WORD int_meteor
    WORD int_missile
    WORD int_energy

meteor_SP_tab:							; Tabela com SPs iniciais para as instâncias do P_meteors
	WORD SP_inicial_meteoro0
	WORD SP_inicial_meteoro1
	WORD SP_inicial_meteoro2
	WORD SP_inicial_meteoro3
	

; Figuras
Rover: WORD ALTURA, LARGURA, LINHA, COLUNA, R_tab
; Altura, Largura, Linha, Coluna, Endereço da tabela de sprites, Tipo de meteoro (1 = bom; 0 = mau)
Meteor0:  WORD 1, 1, 0, 0, 0, 0
Meteor1:  WORD 1, 1, 0, 0, 0, 0
Meteor2:  WORD 1, 1, 0, 0, 0, 0
Meteor3:  WORD 1, 1, 0, 0, 0, 0

Missile: WORD 0, 0     					; Linha, Coluna
         WORD MISSILE_RANGE       		; movimentos restantes (ate desaparecer)
         WORD 0        					; 0- doesnt exist, 1- exists, -1- exploded

; Altura, Largura, Linha, Coluna, Endereço da tabela de sprites
Explosion: WORD 5, 5, 0, 0, Ex_tab

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

; Explosão

Ex_tab: WORD Ex_sprite

Ex_sprite:      
	WORD 0, COR_AZUL_CLARO, 0, COR_AZUL_CLARO, 0
	WORD COR_AZUL_CLARO, 0, COR_AZUL_CLARO, 0, COR_AZUL_CLARO
	WORD 0, COR_AZUL_CLARO, 0, COR_AZUL_CLARO, 0
	WORD COR_AZUL_CLARO, 0, COR_AZUL_CLARO, 0, COR_AZUL_CLARO
	WORD 0, COR_AZUL_CLARO, 0, COR_AZUL_CLARO, 0

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

MOV R0, DISPLAYS
MOV [R0], R0							; Limpa display

MOV [APAGA_AVISO], R1                   ; apaga o aviso de nenhum cenário selecionado (o valor de R1 não é relevante)
MOV [APAGA_ECRAS], R1                   ; apaga todos os pixels já desenhados (o valor de R1 não é relevante)
MOV [APAGA_OVERLAY], R1					; Apaga o cenário frontal caso este exista
MOV R0, 1                               ; cenário de fundo número 1
MOV [SELECIONA_CENARIO_FUNDO], R0       ; seleciona o cenário de fundo

CALL P_teclado							; inicializa processo que gere o teclado
CALL P_rover							; inicializa processo do movimento do rover
CALL P_missil
CALL P_energia
CALL P_gamemode

MOV R1, 3
gera_meteoros:							; Cria as quatro instâncias do processo dos meteoros
	CALL P_meteors
	SUB R1, 1
	JNN gera_meteoros

MOV R0, 1
MOV [jogo_suspendido], R0				; Coloca o jogo em pausa, à espera da indicação para começar

waiting:
	WAIT
	JMP waiting							; Ciclo infinito que espera pela execução dos processos

; | ------------------------------------------------------------------ |
; | --------------------------- Processos ---------------------------- |
; | ------------------------------------------------------------------ |

; **********************************************************************
;
; PROCESSO
;
; P_rover - Processo que dá o movimento ao rover segundo os inputs
;	recebidos do P_teclado. Move o rover enquanto uma das teclas que
;	controlam o seu movimento esteja a ser premida.
;	
; Argumentos:	N/A
;
; **********************************************************************

PROCESS SP_inicial_teclado

P_teclado:

	MOV  R2, TEC_LIN					; endereço do periférico das linhas
	MOV  R3, TEC_COL					; endereço do periférico das colunas
	MOV  R5, MASCARA					; para isolar os 4 bits de menor peso, ao ler as colunas do teclado

espera_tecla:

	WAIT								; ponto de fuga pois este ciclo pode ser bloqueante
	MOV  R1, 8	 						; primeira linha a testar é a linha 4
verifica_linhas:                        ; neste ciclo espera-se até uma tecla ser premida
	MOVB [R2], R1						; escrever no periférico de saída (linhas)
	MOVB R0, [R3]						; ler do periférico de entrada (colunas)
	AND  R0, R5							; elimina bits para além dos bits 0-3
	JNZ converte;
	SHR R1, 1							; passa à próxima linha
	JZ espera_tecla						; espera até haver atividade no teclado
	JMP verifica_linhas					; repete para a prox linha
converte:
	CALL converte_tecla					; coloca o valor da tecla premida em R6
	MOV [tecla_pressionada], R6			; desbloqueia processos que esperam por uma tecla premida

ha_tecla:

	WAIT								; ponto de fuga pois este ciclo pode ser bloqueante
	MOV  R1, 8	 			            ; primeira linha a testar é a linha 4 
	MOV [tecla_continua], R6			; desbloqueia processos que dependem de teclas premidas continuamente
verifica_linhas2:
	MOVB [R2], R1		             	; escrever no periférico de saída (linhas)
	MOVB R0, [R3]		            	; ler do periférico de entrada (colunas)
	AND  R0, R5			                ; elimina bits para além dos bits 0-3
	JNZ ha_tecla;						; se há uma tecla a ser premida, espera até não haver
	SHR R1, 1							; passa à próxima linha
	JZ espera_tecla						; quando não houver tecla a ser premida volta ao espera_tecla
	JMP verifica_linhas2				; repete para a prox linha

; **********************************************************************
;
; PROCESSO
;
; P_rover - Processo que dá o movimento ao rover segundo os inputs
;	recebidos do P_teclado. Move o rover enquanto uma das teclas que
;	controlam o seu movimento esteja a ser premida.
;	
; Argumentos:	N/A
;
; **********************************************************************

PROCESS SP_inicial_rover

P_rover:

	MOV R0, Rover						; endereço do rover
	MOV R4, [R0 + 2]					; largura do rover
	MOV R3, COLUNA_MAX_ECRA				; coluna de pixeis do limite direio do ecrã
	ADD R3, 1
	SUB R3, R4		 					; posição maxima que o rover pode ocupar tendo em conta a sua largura
	MOV R6, 0							; Ecrã onde está o rover

check_move_direction:
	MOV R5, [tecla_continua]

	MOV R8, [jogo_suspendido]
	CMP R8, 1
	JZ check_move_direction				; Não avança caso o jogo esteja em pausa

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

	MOV [SELECIONA_ECRA], R6

	CALL delete_something
	MOV [R0 + 6], R2					; altera posição do rover para se desencadear o movimento
	CALL write_something
	CALL atraso
	JMP check_move_direction			; este processo nunca termina

; **********************************************************************
;
; PROCESSO
;
; P_energia - Processo responsável pela gestão da energia no programa.
;	Encarregue de atualizar o display da energia consoante recebe
;	sinais dos outros processos e da interrução que implicam
;	uma variação da energia. Deteta quando o rover fica sem energia.
;	
; Argumentos:	N/A
;
; **********************************************************************

PROCESS SP_inicial_energia

P_energia:
	MOV R1, [energy_lock]               ;valor a adicionar
	MOV R0, [Energy_counter]            ;contador

	MOV R8, [jogo_suspendido]
	CMP R8, 1
	JZ P_energia						; Não avança caso o jogo esteja em pausa

	ADD R0, R1
	MOV R1, 100                         ;adiciona o valor ao contador
	CMP R0, R1
	JGT energy_cap                      ;verifica se passa do maximo

	CMP R0, 0
	JZ no_energy
	
	MOV [Energy_counter], R0            ;da update ao valor do contador na memoria

convert_energy:
	MOV R1, 1000            			;fator
	MOV R2, 0                			;digito
	MOV R3, 0                			;resultado
	MOV R4, 10              		    ;auxiliar da divisao

hexa_to_dec:	
	MOD R0, R1
	DIV R1, R4
	MOV R2, R0
	DIV R2, R1
	SHL R3, 4
	OR  R3, R2
	CMP R1, R4
	JGT hexa_to_dec                     ;converte para digitos decimais (excepto ultimo digito)

	MOD R0, R1
	DIV R1, R4
	MOV R2, R0
	DIV R2, R1
	SHL R3, 4
	OR  R3, R2                          ;ultimo digito
 
	MOV R0, DISPLAYS   			
    MOV [R0], R3                        ;escreve o valor no display
    JMP P_energia

energy_cap:
	MOV R0, 100
	MOV [Energy_counter], R0            ;se ultrapassar o maximo, o valor fica o maximo
	JMP convert_energy              

no_energy:
	MOV R0, 4                           ; cenário de fundo morte por energia
	MOV [SELECIONA_CENARIO_FUNDO], R0
	MOV R0, 5
	MOV [PLAY_MEDIA], R0
	MOV R5, TECLA_TERMINAR
	MOV [tecla_pressionada], R5         ;verifica se passa do minimo 
	MOV R0, 0
	MOV [auto_terminado], R0
	MOV R0, DISPLAYS   			
	MOV R5, 0
    MOV [R0], R5                      	;escreve 000 no display
	JMP P_energia
 
; **********************************************************************
;
; PROCESSO
;
; P_missil - Processo responsável pelo funcionamento do míssil.
;	Cria o míssil quando a tecla respetiva é premida e coloca-o em
;	em movimento controlado pela interrupção do míssil. Também gera a
;	explosão do míssil quando recebe o sinal do processo P_meteors.
;	
; Argumentos:	N/A
;
; **********************************************************************

PROCESS SP_inicial_missil

P_missil:
    MOV R5, 5							; Ecrã onde se vai colocar o míssil
    MOV R3, COR_ROXO					; Cor do míssil
create_missile:
    MOV R0, [tecla_pressionada]         ;lock

	MOV R8, [jogo_suspendido]
	CMP R8, 1
	JZ create_missile					; Não avança caso o jogo esteja em pausa

    CMP R0, TECLA_MISSIL
    JNZ create_missile                  ;se nao for a tecla pretendida da lock no processo
 
    MOV R0, 1
    MOV [Missile + 6], R0               ;missil existe 
    MOV R0, MISSILE_RANGE
    MOV [Missile + 4], R0               ;movimentos do missil = alcance

    MOV R1, -5
    MOV [energy_lock], R1               ;diminui a energia

    MOV R1, 8
    MOV [PLAY_MEDIA], R1

    MOV R1, LINHA
    SUB R1, 1
    MOV [Missile], R1                   ;linha do missil e a anterior ao rover
    MOV R2, [Rover + 6]
    ADD R2, 1
    MOV [Missile + 2], R2				;coluna do missil e uma depois do rover (para ficar centrado)
    MOV [SELECIONA_ECRA], R5
    CALL escreve_pixel                  ;desenha o pixel

mov_missile:
    MOV R0, [missile_lock]              ;da lock ao processo (lock ativo apenas quando o missil existe)
	CMP R0, RESET_MISSIL
	JZ create_missile					; Volta para o ínicio do processo caso o jogo acabe

	MOV R8, [jogo_suspendido]
	CMP R8, 1
	JZ mov_missile						; Não avança caso o jogo esteja em pausa

    MOV R0, [Missile + 4]               ;verifica se tem movimentos restantes
    CMP R0, 0
    JLE delete_missile

    SUB R0, 1
    MOV [Missile + 4], R0              	;-1 movimento

escreve_missile:
    MOV [SELECIONA_ECRA], R5

	MOV [APAGA_ECRA], R5                ;apaga o missil

    MOV R1, [Missile]
    SUB R1, 1                           
    MOV [Missile], R1                   ;nova linha do missil (coluna e cor definidas anteriormente)
    CALL escreve_pixel                

    JMP mov_missile

delete_missile:
	MOV R1, 0
    MOV [Missile + 6], R1               ;missil deixa de existir

	MOV [APAGA_ECRA], R5                ;e apagado

    MOV R0, [Missile + 4]
    CMP R0, -1
    JZ explode_missile                  ;se nao explodir apenas volta ao principio

    JMP create_missile

explode_missile:
    MOV [SELECIONA_ECRA], R5

	MOV R0, [Missile]
	SUB R0, 2
	MOV [Explosion + 4], R0             
	MOV R0, [Missile + 2]
	SUB R0, 2
	MOV [Explosion + 6], R0             ;linha e coluna sao a do missil -2 para ficar centrado (5x5 com o missil no meio)
	MOV R0, Explosion
	CALL write_something
	MOV R0, [meteor_lock]				; Espera pelo próximo movimento dos meteoros para apagar a explosão
    MOV [APAGA_ECRA], R5

	JMP create_missile

; -----------------------------------------------------------------

; **********************************************************************
;
; PROCESSO
;
; P_meteors - Processo que trata de tudo que envolve os meteoros do jogo.
;	Tem uma instância para cada meteoro em jogo. Responsável pelo
;	movimento dos meteoros e pelas sua colisões.
;	
; Argumentos: R1 - Número da instância do processo.
;
; **********************************************************************

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
	ADD R2, 1

meteor_loop:
	MOV R11, [meteor_lock]				; Espera pela interrupção
	CMP R11, RESET_METEOROS
	JZ P_meteors
	MOV R8, [jogo_suspendido]
	CMP R8, 1
	JZ meteor_loop						; Não avança caso o jogo esteja em pausa

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

	JMP meteor_loop


; **********************************************************************
;
; PROCESSO
;
; P_gamemode - Processo que trata dos diferentes modos de comportamento
;	do programa. Pausa e despausa o programa quando recebe inputs do
;	processo do teclado, termina o jogo quando o jogador perde ou
;	carrega na tecla definida e começa o jogo quando a tecla de começo
;	é pressionada.
;	
; Argumentos:	N/A
;
; **********************************************************************


PROCESS SP_inicial_gamemode

P_gamemode:
	MOV R11, 0							; R11:  1 => jogo já começou / 0 => jogo foi terminado
gamemode_loop:
	MOV R0, [tecla_pressionada]
	MOV R2, TECLA_PAUSA
	CMP R0, R2
	JNZ game_over

	MOV R1, [jogo_suspendido]
	CMP R1, 0							; Verifica se o jogo está ou não pausado
	JZ pause							; Pausa o jogo caso este não esteja pausado

	CMP R11, 0							; Verifica se o jogo já começou
	JZ gamemode_loop					; Se o jogo ainda não começou, não o tira da pausa

	MOV R1, 0
	MOV [jogo_suspendido], R1			; Continua a jogo

	MOV [APAGA_OVERLAY], R1
	MOV R1, 2
	MOV [PLAY_MEDIA], R1
	JMP gamemode_loop
pause:
	MOV R1, 2
	MOV [SELECIONA_OVERLAY], R1
	MOV R1, 1
	MOV [PLAY_MEDIA], R1
pause2:
	MOV R1, 1
	MOV [jogo_suspendido], R1			; Suspende o jogo
	JMP gamemode_loop

game_over:
	MOV R2, TECLA_TERMINAR
	CMP R0, R2
	JNZ start_game

	CMP R11, 0							; Verifica se o jogo já começou
	JZ gamemode_loop					; Se o ainda não tiver começado, não faz nada

	MOV R11, 0							; Define jogo como terminado

	MOV [APAGA_OVERLAY], R1				; Apaga o cenário frontal caso este exista

	MOV R1, [auto_terminado]			; Verifica se o jogador perdeu
	CMP R1, 0
	JZ death
	MOV R1, 3
	MOV [PLAY_MEDIA], R1
	MOV R1, 1                           ; cenário de fundo número 1
	MOV [SELECIONA_CENARIO_FUNDO], R1

death:
	MOV R1, 0
	MOV [APAGA_ECRAS], R1				; Apaga todos os ecrãs
	CALL reset_program					; Repõe valores inciais e prepara o jogo para reiniciar
	MOV R1, 1
	MOV [auto_terminado], R1
	JMP pause2

start_game:
	MOV R2, TECLA_COMECAR
	CMP R0, R2
	JNZ gamemode_loop					; Ignora outros valores
	
	CMP R11, 1							; Verifica se o jogo já começou
	JZ gamemode_loop					; Se o jogo já tiver começado, não faz nada

	MOV R11, 1							; Define jogo como tendo começado

	MOV  R0, 0                          ; cenário de fundo normal
	MOV  [SELECIONA_CENARIO_FUNDO], R0
	MOV [PLAY_MEDIA], R0
	MOV [APAGA_OVERLAY], R0

	MOV R0, Rover
	MOV R1, 0
	MOV [SELECIONA_ECRA], R1
	CALL write_something
	MOV R0, DISPLAYS   			
	MOV R5, 100H
    MOV [R0], R5                        ; Escreve 100 no display
	MOV R1, 0
	MOV [jogo_suspendido], R1			; Continua a jogo
	JMP gamemode_loop

; | ------------------------------------------------------------------ |
; | ---------------------------- Funções ----------------------------- |
; | ------------------------------------------------------------------ |

; **********************************************************************
;
; reset_program - Prepara o programa para ser reiniciado.
;	
; Argumentos:	N/A
;
; **********************************************************************

reset_program:
	PUSH R0

	MOV R0, 64H							; = 100
	MOV [Energy_counter], R0			; Coloca energia a 100

	MOV R0, 0

	MOV [Missile], R0					; Reseta míssil
	MOV [Missile + 2], R0
	MOV [Missile + 6], R0
	MOV R0, RESET_MISSIL
	MOV [missile_lock], R0				; Diz ao P_missil para reiniciar

	MOV R0, RESET_METEOROS
	MOV [meteor_lock], R0				; Diz ao P_meteors para reiniciar

	MOV R0, COLUNA
	MOV [Rover + 6], R0					; Repõe coluna do rover

	POP R0
	RET

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
    PUSH R8

    MOV R1, [R0 + 4]                    ; Primeira linha ocupada pelo meteoro
    MOV R2, [R0 + 6]                    ; Primeira coluna ocupada pelo meteoro
    MOV R3, [R0]                        ; Altura
    MOV R4, [R0 + 2]                    ; Largura
	MOV R8, [R0 + 10]					; Identificador de metoro (1 = bom; 0 = mau)

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

	MOV R5, -1
	MOV [Missile + 4], R5				; Diz ao míssil para explodir
	MOV R5, 0
	MOV [missile_lock], R5

	CMP R8, 1
	JZ colided							; Destruição de meteoro bom não dá energia
	MOV R5, 5
	MOV [energy_lock], R5				; Destruição meteoro mau dá direito a 5% de energia
	MOV R5, 7
	MOV [PLAY_MEDIA], R5
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
	
	CMP R8, 1
	JNZ rover_dies						; Se o meteoro é mau, o jogo acaba
	MOV R5, 10
	MOV [energy_lock], R5				; Colisão de metoro bom com rover dá direito a 10% de energia
	MOV R5, 6
	MOV [PLAY_MEDIA], R5
	JMP colided
rover_dies:
	MOV  R0, 3                          ; cenário de fundo morte por colisao
	MOV  [SELECIONA_CENARIO_FUNDO], R0
	MOV R0, 4
	MOV [PLAY_MEDIA], R0              


	MOV R0, TECLA_TERMINAR
	MOV [tecla_pressionada], R0			; Termina jogo
	MOV R0, 0
	MOV [auto_terminado], R0

colided:
	MOV R7, 1
	JMP end_colision_check
no_colision:
	MOV R7, 0

end_colision_check:
	POP R8
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
; cria_meteoro - Faz um reset a um certo meteoro e escolhe uma coluna
;	de forma "aleatória" para o colocar. Também decide se esse meteoro
;	vai ser bom ou mau
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
;
; atraso - Produz um atraso no programa.
;
; Argumentos:  N/A
;
; **********************************************************************

atraso:

    PUSH    R11

    MOV     R11,  4000H
ciclo_atraso:
    SUB R11, 1
    JNZ ciclo_atraso					; Ciclo que subtrai 1 aa um valor até 0 para gastar tempo do processador

    POP R11
    RET


; **********************************************************************
;
; write_something - escreve uma figura com o endereco da sua tabela
;
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
;
; delete_something - Apaga uma figura de um ecrã.
;
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
;
; escreve_pixel - Escreve um pixel na linha e coluna indicadas.
;
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


int_missile:							; Rotina da interrupção do míssil
    PUSH R0
    MOV R0, 0
    MOV [missile_lock], R0      		; Desbloqueia P_missil
    POP R0
    RFE
    
int_meteor:								; Rotina da interrupção dos meteoros
    PUSH R0
    MOV R0, 1
    MOV [meteor_lock], R0      			; Desbloqueia P_meteors
    POP R0
    RFE

int_energy:								; Rotina da interrupção da energia
    PUSH R0
    MOV R0, -5
    MOV [energy_lock], R0      			; Desbloqueia P_energia
    POP R0
    RFE
