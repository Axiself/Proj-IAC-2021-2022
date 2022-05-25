PLACE 1000H ;-------------------------------------------------------

DISPLAYS   EQU 0A000H  ; endereço dos displays de 7 segmentos (periférico POUT-1)
TEC_LIN    EQU 0C000H  ; endereço das [Linha]s do teclado (periférico POUT-2)
TEC_COL    EQU 0E000H  ; endereço das colunas do teclado (periférico PIN)
MASCARA    EQU 0FH     ; para isolar os 4 bits de menor peso, ao ler as colunas do teclado

Linha: WORD 16
Tecla: WORD 0
Coluna: WORD 0
Counter: WORD 0
LinhaAux: WORD 0

PLACE 0H ;---------------------------------------------------------------------------------------

MOV R10, DISPLAYS
MOV  R11, 0
MOVB [R10], R11   ;reset display

espera_tecla:          ; neste ciclo espera-se até uma tecla ser premida

    MOV R10, [Linha]
    SHR R10, 1      	   ; -1 Linha
    MOV [Linha], R10

	JZ   reset         ; quando a Linha chega a 0 volta a 4  

    MOV R10, TEC_LIN
    MOV  R11, [Linha] 
    MOVB [R10], R11      ; escrever no periférico de saída (Linhas)

    MOV R10, 0
    MOV R11, TEC_COL
    MOVB R10, [R11]      ; ler do periférico de entrada (colunas)

    MOV R11, MASCARA
    AND  R10, R11        ; elimina bits para além dos bits 0-3

    CMP  R10, 0         ; há tecla premida?
    JZ   espera_tecla  ; se nenhuma tecla premida, repete
                       ; vai mostrar a Linha e a coluna da tecla                   
    MOV [Coluna], R10


    MOV R10, [Linha]
    MOV [LinhaAux], R10 ;coluna nao convertida para ser usada em ha_tecla
    MOV R11, 0
linha_converter:
    ADD R11, 1    
    SHR R10, 1
    JNZ linha_converter
    SUB R11, 1
    MOV [Linha], R11


    MOV R10, [Coluna]
    MOV R11, 0
coluna_converter:
    ADD R11, 1
    SHR R10, 1
    JNZ coluna_converter
    SUB R11, 1
    MOV [Coluna], R11
                                    ;converte linha e coluna de 1,2,4,8 a 0,1,2,3
  
    MOV R10, [Linha]
    MOV R11, 4
    MUL R10, R11
    MOV R11, 0
    ADD R11, R10
    MOV R10, [Coluna]
    ADD R11, R10
    MOV [Tecla], R11  ; tecla = 4*linha + coluna


    MOV R10, [Counter]
    CMP R11, 0    ;0 diminui o contador
    JZ menos
    CMP R11, 3    ;3 aumenta o contador
    JZ mais
    JMP ha_tecla

menos:
    SUB R10, 1           ;doesn't add
    JMP next
mais:
    ADD R10, 1           ;adds
    JMP next
next:    
    MOV R11, DISPLAYS
    MOV [Counter], R10   ; update counter var
    MOVB [R11], R10      ; escreve counter no display

;good



ha_tecla:              ; neste ciclo espera-se até NENHUMA tecla estar premida

    MOV R10, TEC_LIN
    MOV R11, [LinhaAux]
    MOVB [R10], R11      ; escrever no periférico de saída (Linhas)

    MOV R11, TEC_COL
    MOVB R10, [R11]      ; ler do periférico de entrada (colunas)

    MOV R11, MASCARA
    AND  R10, R11       ; elimina bits para além dos bits 0-3
    CMP  R10, 0         ; há tecla premida?
    JNZ  ha_tecla      ; se ainda houver uma tecla premida, espera até não haver
    JMP  espera_tecla

reset:
    MOV R10, 16
	MOV [Linha], R10        ; Linha = 4 (1000) (+1 bc SHR)
	JMP espera_tecla   ; volta ao ciclo