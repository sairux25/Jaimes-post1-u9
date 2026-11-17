; ISR_KB.ASM — ISR personalizado para IRQ1 (teclado)
; Compila: nasm -f bin ISR_KB.ASM -o ISR_KB.COM

[BITS 16]
[ORG 0x100]

section .data
contador    DW 0        ; número de teclas atendidas
MAX_KEYS    EQU 5
old_isr     DD 0        ; almacena SEG:OFF del handler original
msg_tecla   DB 0Dh, 0Ah, "Tecla detectada por ISR propio$"
msg_fin     DB 0Dh, 0Ah, "ISR restaurado. Fin del programa.$"

section .text
start:
    ; Guardar vector original INT 09h
    MOV AX, 3509h       ; AH=35h: obtener vector INT 09h
    INT 21h             ; ES:BX = dirección del handler actual
    MOV [old_isr], BX
    MOV [old_isr+2], ES

    ; Instalar ISR propio
    PUSH DS
    MOV AX, CS
    MOV DS, AX
    MOV DX, mi_isr      ; DS:DX = dirección del nuevo handler
    MOV AX, 2509h       ; AH=25h: fijar vector INT 09h
    INT 21h
    POP DS

    STI                 ; asegurar interrupciones habilitadas

.esperar:
    MOV AX, [contador]
    CMP AX, MAX_KEYS
    JL .esperar         ; bucle activo hasta 5 pulsaciones

    ; Restaurar handler original
    CLI
    PUSH DS             ; se guarda DS porque LDS lo cambia
    LDS DX, [old_isr]   ; DS:DX = handler original
    MOV AX, 2509h
    INT 21h
    POP DS              ; DS vuelve al segmento del programa para imprimir msg_fin
    STI

    MOV AH, 09h
    MOV DX, msg_fin
    INT 21h
    MOV AH, 4Ch
    INT 21h

; ── ISR propio ─────────────────────────────────────────────────────
mi_isr:
    PUSH AX
    PUSH DX
    PUSH DS

    MOV AX, CS          ; DS apunta al segmento del programa
    MOV DS, AX

    ; Leer y descartar el scancode del buffer del teclado
    IN AL, 60h
    TEST AL, 80h        ; bit 7 en 1 indica que la tecla se soltó
    JNZ .eoi            ; el código de soltar no se cuenta como pulsación

    ; Mostrar mensaje
    MOV AH, 09h
    MOV DX, msg_tecla
    INT 21h

    ; Incrementar contador
    INC WORD [contador]

.eoi:
    ; Enviar EOI al PIC maestro
    MOV AL, 20h
    OUT 20h, AL

    POP DS
    POP DX
    POP AX
    IRET                ; retorna de la interrupción
