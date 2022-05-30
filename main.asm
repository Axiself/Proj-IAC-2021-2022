;
; apaga uma figura em qualquer sitio e inicializa o rover
; prox: mexer 
; editar word LINHA e COLUNA para mover for now (Linha vai ficar pq ele nao se mexe verticalmente)
;
;
;
;
DISPLAYS   EQU 0A000H  ; endereço dos displays de 7 segmentos (periférico POUT-1)
TEC_LIN    EQU 0C000H  ; endereço das [Linha]s do teclado (periférico POUT-2)
TEC_COL    EQU 0E000H  ; endereço das colunas do teclado (periférico PIN)
MASCARA    EQU 0FH     ; para isolar os 4 bits de menor peso, ao ler as colunas do teclado

DEFINE_LINHA            EQU 600AH      ; endereço do comando para definir a linha
DEFINE_COLUNA           EQU 600CH      ; endereço do comando para definir a coluna
DEFINE_PIXEL            EQU 6012H      ; endereço do comando para escrever um pixel
APAGA_AVISO             EQU 6040H      ; endereço do comando para apagar o aviso de nenhum cenário selecionado
APAGA_ECRÃ              EQU 6002H      ; endereço do comando para apagar todos os pixels já desenhados
SELECIONA_CENARIO_FUNDO EQU 6042H      ; endereço do comando para selecionar uma imagem de fundo

COR        EQU 0FF00H
ALTURA     EQU 3
LARGURA    EQU 3

LINHA           EQU  15      ; linha do boneco (a meio do ecrã))
COLUNA          EQU  5        ; coluna do boneco (a meio do ecrã)

PLACE 1000H

pilha:
    STACK 100H          ; espaço reservado para a pilha 

SP_inicial:             ; endereco do SP

Linha: WORD 16
Tecla: WORD 0
Coluna: WORD 0
Counter: WORD 0
LinhaAux: WORD 0

Figure: WORD ALTURA, LARGURA, COLUNA
        WORD COR, 0, COR
        WORD 0, COR, 0
        WORD COR, 0, COR

PLACE 0H ;---------------------------------------------------------------------------------------


MOV  SP, SP_inicial     ; inicializa SP para a palavra a seguir
                        ; à última da pilha
                            
MOV  [APAGA_AVISO], R1              ; apaga o aviso de nenhum cenário selecionado (o valor de R1 não é relevante)
MOV  [APAGA_ECRÃ], R1               ; apaga todos os pixels já desenhados (o valor de R1 não é relevante)
MOV  R0, 0                           ; cenário de fundo número 0
MOV  [SELECIONA_CENARIO_FUNDO], R0 ; seleciona o cenário de fundo



MOV R0, DISPLAYS
MOV  R1, 0
MOVB [R0], R1   ;reset display

CALL ini_figure

espera_tecla:          ; neste ciclo espera-se até uma tecla ser premida

    MOV R0, [Linha]
    SHR R0, 1      	   ; -1 Linha
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
                                    ;converte linha e coluna de 1,2,4,8 a 0,1,2,3
  
    MOV R0, [Linha]
    MOV R1, 4
    MUL R0, R1
    MOV R1, 0
    ADD R1, R0
    MOV R0, [Coluna]
    ADD R1, R0
    MOV [Tecla], R1     ; tecla = 4*linha + coluna

move_left:
    CMP R1, 0
;    JNZ move_right
    MOV R1, -1
;    CALL move_figure
    MOV R4, [Figure]
    MOV R1, LINHA
    MOV R5, [Figure+2]
    MOV R2, [Figure+4]
    CALL delete_something
    JMP next

;move_right:
;    CMP R1, 3
;    JNZ sub_counter
;    MOV R1, 1
;    CALL move_figure
;    JMP next

sub_counter:
    CMP R1, 4
    JNZ add_counter
    MOV R1, -1
    CALL change_counter
    JMP next

add_counter:
    CMP R1, 7
    JNZ next
    MOV R1, 1
    CALL change_counter
    JMP next

next:


ha_tecla:              ; neste ciclo espera-se até NENHUMA tecla estar premida

    MOV R0, TEC_LIN
    MOV R1, [LinhaAux]
    MOVB [R0], R1      ; escrever no periférico de saída (Linhas)

    MOV R1, TEC_COL
    MOVB R0, [R1]      ; ler do periférico de entrada (colunas)

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
reset:
    PUSH R0
    MOV  R0, 16
    MOV  [Linha], R0        ; Linha = 4 (1000) (+1 bc SHR)
    POP  R0
    RET

; **********************************************************************
; change_counter - 
; Argumentos:   R1 - number to add
;               
;               
;
; **********************************************************************
change_counter:
    PUSH  R0
    PUSH  R1
    MOV   R0, [Counter]
    ADD   R0, R1
    MOV   [Counter], R0   ;new counter
    MOV   R1, DISPLAYS   
    MOVB  [R1], R0       ;write on display
    POP   R1
    POP   R0
    RET

; **********************************************************************
; ini_figure 
; Argumentos: none
;               
;               
;
; **********************************************************************
ini_figure:
    PUSH R0
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    PUSH R5
    PUSH R6
    PUSH R7
    MOV R0, Figure
    MOV R4, [R0]   ; Altura
    ADD R0, 2
    MOV R6, [R0]   ; Largura
    MOV R7, R6     ; Largura backup
    ADD R0, 4
    MOV R1, LINHA
    MOV R2, COLUNA
    MOV R3, [R0]

ciclo1:
    CALL escreve_pixel
    ADD R2, 1          ;proxima coluna
    ADD R0, 2
    MOV R3, [R0]       ;proxima cor
    SUB R6, 1          ;menos uma coluna precisa
    JZ last_coluna
    JMP ciclo1

last_coluna:
    MOV R2, COLUNA
    MOV R6, R7
    ADD R1, 1
    SUB R4, 1
    JZ end
    JMP ciclo1
end:
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
; move_figure
; Argumentos:   R0- direction (-1 = left, +1 = right)
;               R
;               R
;
; **********************************************************************
move_figure:

    MOV R0, Figure
    MOV R4, [R0]   ; Altura
    ADD R0, 2
    MOV R6, [R0]   ; Largura
    MOV R7, R6     ; Largura backup
    ADD R0, 2
    MOV R1, LINHA
    MOV R2, [R0]   ; Coluna
    ADD R0, 2
    MOV R3, [R0]


; **********************************************************************
; delete_something
; Argumentos:   R2 - Coluna
;               R1 - Linha
;               R4 - Altura
;               R5 - Largura
;
; **********************************************************************

delete_something: 
    MOV R6, R2 ;coluna backup
    MOV R7, R5 ;largura backup
    MOV R3, 0
prox_col:
    CALL escreve_pixel
    ADD R2, 1  ;prox col
    SUB R5, 1  ;menos um de largura remaining
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

