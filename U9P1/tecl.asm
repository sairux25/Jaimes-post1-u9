; TECL.ASM — Lectura del estado del teclado 8042
; Compila: nasm -f bin TECL.ASM -o TECL.COM

[BITS 16]               ; programa .COM, CS=DS=ES=SS
[ORG 0x100]

start:
    CLI                 ; se deshabilitan las interrupciones para que el BIOS no lea el puerto 60h antes que el bucle
    ; Esperar hasta que OBF=1 (dato disponible en buffer de salida)
.poll:
    IN AL, 64h          ; leer registro de estado del 8042
    TEST AL, 01h        ; comprobar bit OBF
    JZ .poll            ; si OBF=0, no hay dato listo — repetir

    IN AL, 60h          ; leer scancode del Data Port
    TEST AL, 80h        ; bit 7 en 1 indica que la tecla se soltó
    JNZ .poll           ; se ignora el código de soltar y se sigue esperando
    STI                 ; se vuelven a habilitar las interrupciones
    MOV BL, AL          ; guardar scancode en BL

    ; Mostrar scancode en pantalla (conversión hex manual)
    MOV AH, 02h         ; función DOS: imprimir carácter
    MOV DL, BL
    SHR DL, 4           ; nibble alto
    ADD DL, 30h
    CMP DL, 3Ah
    JL .printH
    ADD DL, 07h         ; ajuste A–F
.printH:
    INT 21h

    MOV DL, BL          ; nibble bajo
    AND DL, 0Fh
    ADD DL, 30h
    CMP DL, 3Ah
    JL .printL
    ADD DL, 07h
.printL:
    INT 21h

    MOV AH, 02h         ; CR
    MOV DL, 0Dh         ; LF
    INT 21h
    MOV DL, 0Ah
    INT 21h

    MOV AH, 4Ch         ; terminar programa
    INT 21h
