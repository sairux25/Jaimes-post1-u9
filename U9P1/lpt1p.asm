; LPT1P.ASM — Envío de un carácter al puerto paralelo LPT1
; Compila: nasm -f bin LPT1P.ASM -o LPT1P.COM
; Los puertos del LPT1 son mayores que FFh, por eso se accede a ellos a través de DX

[BITS 16]
[ORG 0x100]

DATA_PORT   EQU 0378h
STATUS_PORT EQU 0379h
CTRL_PORT   EQU 037Ah

start:
    ; Esperar BUSY=1 (impresora lista)
    MOV DX, STATUS_PORT
.wait_ready:
    IN AL, DX
    TEST AL, 80h        ; bit 7: BUSY# (activo en bajo = ocupada)
    JZ .wait_ready

    ; Enviar carácter "A" (0x41)
    MOV AL, 41h
    MOV DX, DATA_PORT
    OUT DX, AL          ; colocar dato en el bus de datos

    ; Pulso STROBE (bit 0 del control, activo en bajo)
    MOV DX, CTRL_PORT
    IN AL, DX
    AND AL, 0FEh        ; STROBE=0 → activo
    OUT DX, AL

    ; Retardo mínimo (~1µs en DOSBox)
    MOV CX, 0Fh
.delay:
    LOOP .delay

    OR AL, 01h          ; STROBE=1 → inactivo
    OUT DX, AL

    MOV AH, 4Ch
    INT 21h
