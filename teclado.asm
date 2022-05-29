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

;
; teclado v1.1 com display e fixed registos
;

PLACE 0H ;---------------------------------------------------------------------------------------

MOV R0, DISPLAYS
MOV  R1, 0
MOVB [R0], R1   ;reset display

espera_tecla:          ; neste ciclo espera-se até uma tecla ser premida

    MOV R0, [Linha]
    SHR R0, 1      	   ; -1 Linha
    MOV [Linha], R0

	JZ   reset         ; quando a Linha chega a 0 volta a 4  

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
    MOV [Tecla], R1  ; tecla = 4*linha + coluna


    MOV R0, [Counter]
    CMP R1, 0    ;0 diminui o contador
    JZ menos
    CMP R1, 3    ;3 aumenta o contador
    JZ mais
    JMP ha_tecla

menos:
    SUB R0, 1           ;doesn't add
    JMP next
mais:
    ADD R0, 1           ;adds
    JMP next
next:    
    MOV R1, DISPLAYS
    MOV [Counter], R0   ; update counter var
    MOVB [R1], R0      ; escreve counter no display

;good



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

reset:
    MOV R0, 16
	MOV [Linha], R0        ; Linha = 4 (1000) (+1 bc SHR)
	JMP espera_tecla   ; volta ao ciclo