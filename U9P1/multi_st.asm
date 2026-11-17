; MULTI_ST.ASM — Polling combinado de dos puertos de estado (teclado + LPT1)
; Compila: nasm -f bin MULTI_ST.ASM -o MULTI_ST.COM

[BITS 16]
[ORG 0x100]

STATUS_PORT EQU 0379h

start:
.poll:
    ; Bandera de teclado: bit 0 (OBF) del registro de estado 64h
    IN AL, 64h
    AND AL, 01h
    MOV BL, AL          ; BL = bandera_teclado (0 o 1)

    ; Bandera de LPT1: bit 7 (listo) del registro de estado 0x379
    MOV DX, STATUS_PORT ; el puerto 379h es mayor que FFh y se accede a través de DX
    IN AL, DX
    AND AL, 80h
    SHR AL, 7           ; normaliza a 0 o 1
    MOV BH, AL          ; BH = bandera_lpt1 (0 o 1)

    MOV AL, BL          ; AL = bandera_teclado OR bandera_lpt1
    OR AL, BH           ; ningun dispositivo listo -> repetir
    JZ .poll

    ; Determinar cual(es) dispositivo(s) dispararon la condicion
    TEST BL, BL
    JZ .soloLpt1
    MOV AH, 09h
    MOV DX, msg_tecl
    INT 21h

.soloLpt1:
    TEST BH, BH
    JZ .fin
    MOV AH, 09h
    MOV DX, msg_lpt1
    INT 21h

.fin:
    MOV AH, 4Ch
    INT 21h

msg_tecl DB "Teclado listo (OBF=1).", 0Dh, 0Ah, "$"
msg_lpt1 DB "LPT1 listo (BUSY#=1).", 0Dh, 0Ah, "$"
