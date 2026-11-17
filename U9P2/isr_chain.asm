; ISR_CHAIN.ASM — ISR para IRQ1 encadenado con el handler original
; Compila: nasm -f bin ISR_CHAIN.ASM -o ISR_CHAIN.COM

[BITS 16]
[ORG 0x100]

section .data
contador    DW 0        ; número de teclas atendidas
MAX_KEYS    EQU 5
old_isr     DD 0        ; almacena SEG:OFF del handler original
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
    MOV DX, mi_isr_chain ; DS:DX = dirección del nuevo handler
    MOV AX, 2509h       ; AH=25h: fijar vector INT 09h
    INT 21h
    POP DS

    STI                 ; asegurar interrupciones habilitadas

.esperar:
    MOV AH, 01h         ; leer tecla con eco de DOS, la entrega el handler original
    INT 21h
    MOV AX, [contador]
    CMP AX, MAX_KEYS
    JL .esperar         ; bucle hasta que el ISR propio registre 5 pulsaciones

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

; ── ISR propio encadenado ──────────────────────────────────────────
mi_isr_chain:
    PUSH AX
    PUSH DX
    PUSH DS

    MOV AX, CS          ; DS apunta al segmento del programa
    MOV DS, AX

    ; Leer el scancode sin descartarlo, el handler original también lo lee
    IN AL, 60h
    TEST AL, 80h        ; bit 7 en 1 indica que la tecla se soltó
    JNZ .encadenar      ; el código de soltar no se cuenta como pulsación

    ; Registrar la tecla en el contador propio
    INC WORD [contador]

.encadenar:
    POP DS
    POP DX
    POP AX
    ; Encadenar con el handler original (simular INT: push flags + far call)
    ; El handler original procesa la tecla y envía el EOI al PIC
    PUSHF
    CALL FAR [old_isr]  ; old_isr contiene SEG:OFF del handler original
    IRET
