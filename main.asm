;
;   0 move para a esquerda 
;   2 move para a direita
;   4 diminui o display
;   7 aumenta o display
;   8 move o meteoro
;
;

; COUNTER E TECLADO

DISPLAYS   EQU 0A000H  ; endereço dos displays de 7 segmentos (periférico POUT-1)
TEC_LIN    EQU 0C000H  ; endereço das [Linha]s do teclado (periférico POUT-2)
TEC_COL    EQU 0E000H  ; endereço das colunas do teclado (periférico PIN)
MASCARA    EQU 0FH     ; para isolar os 4 bits de menor peso, ao ler as colunas do teclado

; ECRA

DEFINE_LINHA            EQU 600AH      ; endereço do comando para definir a linha
DEFINE_COLUNA           EQU 600CH      ; endereço do comando para definir a coluna
DEFINE_PIXEL            EQU 6012H      ; endereço do comando para escrever um pixel
APAGA_AVISO             EQU 6040H      ; endereço do comando para apagar o aviso de nenhum cenário selecionado
APAGA_ECRÃ              EQU 6002H      ; endereço do comando para apagar todos os pixels já desenhados
SELECIONA_CENARIO_FUNDO EQU 6042H      ; endereço do comando para selecionar uma imagem de fundo
SELECIONA_MEDIA         EQU 6048H
PLAY_MEDIA              EQU 605AH

;FIGURAS 

COR_F        EQU 0F00FH
COR_M        EQU 0FF00H
COR_E        EQU 0F0F0H
ALTURA       EQU  3         ;
LARGURA      EQU  3
LINHA        EQU  29        ; linha do boneco (a meio do ecrã)) (estatica)
COLUNA       EQU  31        ; coluna do boneco (a meio do ecrã) (inicial)

PLACE 1000H

pilha:
    STACK 100H          ; espaço reservado para a pilha 

SP_inicial:             ; endereco do SP

Linha: WORD 16
Tecla: WORD 0
Coluna: WORD 0
Counter: WORD 0
LinhaAux: WORD 0
Meteor_exists: WORD 1
Move_flag: WORD 0       ; 0 for none, 1 for left, 2 for right


Figure: WORD ALTURA, LARGURA, LINHA, COLUNA
        WORD COR_F, 0, COR_F
        WORD 0, COR_F, 0
        WORD COR_F, 0, COR_F

Meteor:  WORD 5, 5, 0, 31
         WORD 0, COR_M,  COR_M,  COR_M, COR_M
         WORD COR_M, COR_M, COR_M, 0, 0
         WORD COR_M, COR_M, COR_M, COR_M, COR_M
         WORD COR_M, COR_M, COR_M, COR_M, COR_M
         WORD 0, COR_M, 0, 0, COR_M



PLACE 0H ;---------------------------------------------------------------------------------------


MOV  SP, SP_inicial     ; inicializa SP para a palavra a seguir
                        ; à última da pilha
                            
MOV  [APAGA_AVISO], R1              ; apaga o aviso de nenhum cenário selecionado (o valor de R1 não é relevante)
MOV  [APAGA_ECRÃ], R1               ; apaga todos os pixels já desenhados (o valor de R1 não é relevante)
MOV  R0, 0                           ; cenário de fundo número 0
MOV  [SELECIONA_CENARIO_FUNDO], R0 ; seleciona o cenário de fundo
;MOV  [SELECIONA_MEDIA], R0



MOV R0, DISPLAYS
MOV  R1, 0
MOV [R0], R1   ;reset display

MOV R0, Figure
CALL write_something            ;inicializa o rover
MOV R0, Meteor
CALL write_something            ;inicializa o meteoro
;MOV [PLAY_MEDIA], R0

espera_tecla:          ; neste ciclo espera-se até uma tecla ser premida

    MOV R0, [Linha]
    SHR R0, 1          ; -1 Linha
    MOV [Linha], R0

    JNZ   no_reset         
    CALL  reset           ; quando a Linha chega a 0 volta a 4 
no_reset:

    MOV R0, TEC_LIN
    MOV  R1, [Linha] 
    MOVB [R0], R1      ; escrever no periférico de saída (Linhas)

    MOV R0, 0
    MOV R1, TEC_COL
    MOVB R0, [R1]      ; ler do periférico de entrada (colunas)

    MOV R1, MASCARA
    AND  R0, R1        ; elimina bits para além dos bits 0-3

    CMP  R0, 0         ; há tecla premida?
    JZ   espera_tecla  ; se nenhuma tecla premida, repete
                       ; vai mostrar a Linha e a coluna da tecla                   
    MOV [Coluna], R0


    MOV R0, [Linha]
    MOV [LinhaAux], R0 ;coluna nao convertida para ser usada em ha_tecla
    MOV R1, 0
linha_converter:
    ADD R1, 1    
    SHR R0, 1
    JNZ linha_converter
    SUB R1, 1
    MOV [Linha], R1


    MOV R0, [Coluna]
    MOV R1, 0
coluna_converter:
    ADD R1, 1
    SHR R0, 1
    JNZ coluna_converter
    SUB R1, 1
    MOV [Coluna], R1
                                    ;converte linha e coluna de 1,2,4,8 a 0,1,2,3 fazendo shift rights ate ficar 0 (contar o expoente do 2)
  
    MOV R0, [Linha]
    MOV R1, 4
    MUL R0, R1
    MOV R1, 0
    ADD R1, R0
    MOV R0, [Coluna]
    ADD R1, R0
    MOV [Tecla], R1     ; tecla = 4*linha + coluna




move_left:                                ; tecla 0
    CMP R1, 0
    JNZ move_right

    MOV R2, 1
    MOV [Move_flag], R2                  ;ativa flag para mover repetidamente

    MOV R2, [Figure+6]                   ;border check (coluna 0)
    CMP R2, 0
    JZ next

    MOV R1, [Figure+4]  ;linha
    MOV R2, [Figure+6]  ;coluna
    MOV R4, [Figure]    ;altura
    MOV R5, [Figure+2]  ;largura 
    CALL delete_something                ;apaga o rover


    MOV R0, [Figure+6]                   
    SUB R0, 1
    MOV [Figure+6], R0
    MOV R0, Figure                      ;diminui a coluna
    CALL write_something                ;escreve o rover na nova posicao
    JMP next

move_right:                             ; tecla 2
    CMP R1, 2
    JNZ sub_counter

    MOV [Move_flag], R1                 ;ativa a flag para mover repetidamente

    MOV R1, [Figure+6]                  ;coluna
    MOV R2, [Figure+2]                  ;largura
    ADD R1, R2
    SUB R1, 1
    MOV R2, 63
    SUB R1, R2
    JZ next                              ; coluna + largura - maximo (63) - 1 = 0 -> end (border check)

    MOV R1, [Figure+4]  ;linha
    MOV R2, [Figure+6]  ;coluna
    MOV R4, [Figure]    ;altura
    MOV R5, [Figure+2]  ;largura
    CALL delete_something                ;apaga o rover

    MOV R0, [Figure+6]                   ;aumenta a coluna 
    ADD R0, 1
    MOV [Figure+6], R0
    MOV R0, Figure
    CALL write_something                 ;escreve o rover na nova posicao
    JMP next

sub_counter:                             ;tecla 4
    MOV R2, 0
    MOV [Move_flag], R2                  ;desativa a  flag para mover continuamente (so por precaucao)

    CMP R1, 4
    JNZ add_counter
    MOV R1, -1
    CALL change_counter                  ;diminui o counter (R1 e o valor incrementado ao counter)
    JMP next

add_counter:                             ;tecla 7
    CMP R1, 7
    JNZ move_met
    MOV R1, 1
    CALL change_counter                  ;aumenta o counter (R1 e o valor incrementado ao counter)
    JMP next

move_met:                               ;tecla 8 
    MOV R0, 8 
    CMP R1, R0
    JNZ next
	MOV R0, 0
	MOV [PLAY_MEDIA], R0					;reproduz efeito sonoro
    MOV R0, [Meteor_exists]
    CMP R0, 0                            ;verifica se o meteoro ainda existe 
    JZ next
    CALL move_meteor                     ;se sim move o para baixo

next:


ha_tecla:                                ; neste ciclo espera-se até NENHUMA tecla estar premida
    MOV R0, [Move_flag]
    CMP R0, 0
    JZ not_move                          ;se a tecla premida for de movimento repete o movimento
    CALL tecla_premida
not_move:
    MOV R0, TEC_LIN
    MOV R1, [LinhaAux]
    MOVB [R0], R1                         ; escrever no periférico de saída (Linhas)

    MOV R1, TEC_COL
    MOVB R0, [R1]                         ; ler do periférico de entrada (colunas)

    MOV R1, MASCARA
    AND  R0, R1       ; elimina bits para além dos bits 0-3
    CMP  R0, 0         ; há tecla premida?
    JNZ  ha_tecla      ; se ainda houver uma tecla premida, espera até não haver
    JMP  espera_tecla



;func-------------------------------------------------------------

; **********************************************************************
; reset - resets linha (scan do teclado)
; Argumentos:   R
;               R
;               R
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
    JMP right                ;seleciona a direcao do movimento

left:
    MOV R2, [Figure+6]    ;border check
    CMP R2, 0
    JZ end6

    MOV R1, [Figure+4]  ;linha
    MOV R2, [Figure+6]  ;coluna
    MOV R4, [Figure]    ;altura
    MOV R5, [Figure+2]  ;largura
    CALL delete_something


    MOV R0, [Figure+6]         ;menos coluna 
    SUB R0, 1
    MOV [Figure+6], R0          ;atualiza a coluna da figura
    MOV R0, Figure
    CALL write_something
    JMP end5

right:
    MOV R1, [Figure+6]    ;coluna
    MOV R2, [Figure+2]    ;largura
    ADD R1, R2
    SUB R1, 1
    MOV R2, 63
    SUB R1, R2
    JZ end6               ; coluna + largura - maximo (63) - 1 = 0 -> end (border check)

    MOV R1, [Figure+4]  ;linha
    MOV R2, [Figure+6]  ;coluna
    MOV R4, [Figure]    ;altura
    MOV R5, [Figure+2]  ;largura
    CALL delete_something

    MOV R0, [Figure+6]         ;mais coluna 
    ADD R0, 1
    MOV [Figure+6], R0          ;atualiza a coluna da figura
    MOV R0, Figure
    CALL write_something
    JMP end5

end6:                           ;quando chega ao final, desativa a flag de mover
    MOV R1, 0
    MOV [Move_flag], R1
end5:
    CALL atraso                 ;mucho rapido normalmente
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
;       
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
;               
;
; **********************************************************************
reset:
    PUSH R0
    MOV  R0, 16
    MOV  [Linha], R0        ; Linha = 4 (1000) (16 /  1 000 bc SHR no inicio do ciclo)
    POP  R0
    RET

; **********************************************************************
; change_counter - adiciona R1 ao contador, escreve no display e atualiza a variavel counter
; Argumentos:   R1 - number to add
;               
;               
;
; **********************************************************************
change_counter:
    PUSH  R0
    PUSH  R1
    MOV   R0, [Counter]
    ADD   R0, R1           ;adiciona
    MOV   [Counter], R0    ;atualiza o counter
    MOV   R1, DISPLAYS   
    MOV   [R1], R0         ;write on display
    POP   R1
    POP   R0
    RET

; **********************************************************************
; write_something- escreve uma figura com o endereco da sua tabela
; Argumentos:   R0 - Endereco da tabela da figura
;               
;               
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

    MOV R1, [R0+4] ; Linha
    MOV R2, [R0+6] ; Coluna
    MOV R4, [R0]   ; Altura
    MOV R5, [R0+2] ; Largura
    MOV R6, 8
    ADD R6, R0
    MOV R3, [R6]  ; primeiro pixel
prox_col2:
    CALL escreve_pixel 
    ADD R2, 1      ;proxima coluna
    ADD R6, 2      ;proximo pixel
    MOV R3, [R6]   
    SUB R5, 1      ;menos uma coluna restante
    JZ prox_lin2   ;se acabarem as colunas
    JMP prox_col2
prox_lin2:
    MOV R5, [R0+2]  ;faltam todas as colunas outra vez
    MOV R2, [R0+6]  ;coluna volta a primeira
    ADD R1, 1       ;proxima linha
    SUB R4, 1       ;menos uma linha restante
    JZ end3 
    JMP prox_col2
end3:
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
;               
;
; **********************************************************************
move_meteor:
    PUSH R0
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    PUSH R5
    MOV R0, [Meteor+4]  ; linha
    MOV R1, [Meteor]    ; altura
    ADD R0, R1
    SUB R0, 1
    MOV R1, 31
    MOV R2, [Figure]
    SUB R1, R2
    SUB R0, R1          ;border check  (se linha + altura - 1 = 31(max) - altura do rover chegou ao final)
    JZ reached_end
normal:
    MOV R1, [Meteor+4]
    MOV R2, [Meteor+6]
    MOV R4, [Meteor]
    MOV R5, [Meteor+2]
    CALL delete_something       ;apaga o meteoro

    MOV R0, [Meteor+4]
    ADD R0, 1
    MOV [Meteor+4], R0          ;atualiza a linha do meteoro (aumenta por 1)
    MOV R0, Meteor
    CALL write_something        ;escreve o meteoro
    JMP end4

reached_end:
    MOV R1, [Meteor+4]
    MOV R2, [Meteor+6]
    MOV R4, [Meteor]
    MOV R5, [Meteor+2]
    CALL delete_something     ; apaga o meteoro quando chega ao fim 
    MOV R0, 0
    MOV [Meteor_exists], R0   ; desativa a flag do meteoro para ignorar tentativas de o mover quando nao existe

end4:
    POP R5
    POP R4
    POP R3
    POP R2
    POP R1
    POP R0
    RET

; **********************************************************************
; delete_something- apaga alguma coisa com a sua localizacao e dimensao 
; Argumentos:   R2 - Coluna
;               R1 - Linha
;               R4 - Altura
;               R5 - Largura
;
; **********************************************************************

delete_something: 
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    PUSH R5
    PUSH R6
    PUSH R7
    MOV R6, R2   ;coluna backup
    MOV R7, R5   ;largura backup (nao temos endereco entao temos de guardar para depois)
    MOV R3, 0
prox_col:
    CALL escreve_pixel
    ADD R2, 1    ;prox col
    SUB R5, 1    ;menos um de largura remaining
    JZ prox_lin
    JMP prox_col

prox_lin:
    MOV R5, R7  ;reset largura
    MOV R2, R6  ;reset coluna
    ADD R1, 1  ;prox linha
    SUB R4, 1 ;menos um de altura remaining
    JZ end2
    JMP prox_col

end2:
    POP R7
    POP R6
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
    MOV  [DEFINE_LINHA], R1     ; seleciona a linha
    MOV  [DEFINE_COLUNA], R2    ; seleciona a coluna
    MOV  [DEFINE_PIXEL], R3     ; altera a cor do pixel na linha e coluna já selecionadas
    RET
