# Laboratorio Unidad 9 — Entrada y Salida Avanzados
Sara Jaimes Castañeda · Arquitectura de Computadores

Este repositorio contiene el desarrollo de las dos partes del laboratorio de entrada y salida avanzados en NASM sobre DOSBox-X. La Parte 1 accede directamente a los puertos del controlador de teclado 8042 y del puerto paralelo LPT1 con las instrucciones IN y OUT, usando polling sin límite, polling con timeout y una espera combinada de dos puertos de estado. La Parte 2 instala una rutina de servicio de interrupción propia para IRQ1, programa el IMR del PIC 8259A, encadena el ISR con el handler original y mide el intervalo entre interrupciones con el contador de ticks del sistema.

Entorno utilizado

DOSBox-X 2026.08.31 sobre Windows 11 y NASM 3.00 para DOS. La unidad C de DOSBox-X se montó sobre la carpeta del repositorio, por lo que el directorio de trabajo C:\U9P1 corresponde a la carpeta U9P1.

# PARTE 1 — Acceso Directo a Puertos de E/S
## Checkpoint 1 — Lectura de scancode por polling
Capturas: capturas/CP1_compilacion_tecl.png y capturas/CP1_ejecucion_tecl.png

El programa TECL.ASM consulta el bit 0 del registro de estado del 8042 en el puerto 64h, que es el bit OBF, y cuando vale 1 lee el scancode del puerto 60h. En la primera prueba el programa no mostraba la tecla presionada y solo de vez en cuando alcanzaba a leer alguna. Esto pasaba porque las interrupciones seguían habilitadas y el handler del BIOS para IRQ1 leía primero el puerto 60h, dejando OBF en 0 antes de que el bucle lo viera. Por lo tanto se ajustó agregando CLI antes del bucle y STI después de leer el dato.

Luego el programa mostró 9C apenas se ejecutó, que es el código de soltar la tecla Enter usada para lanzarlo, ya que cada tecla genera un código al presionarla y otro con el bit 7 en 1 al soltarla. Por lo tanto también se agregó TEST AL, 80h para ignorar los códigos de soltar y seguir esperando. Hecho esto, TECL.COM compiló sin errores y al presionar la tecla A mostró 1E, que es su scancode al presionarla.

## Checkpoint 2 — Polling con timeout
Capturas: capturas/CP2_compilacion_poll_t.png y capturas/CP2_ejecucion_poll_t.png

POLL_T.ASM repite la lectura del bit OBF del puerto 64h usando CX como contador de reintentos, y la instrucción LOOP lo decrementa en cada vuelta hasta que llega un dato o CX queda en cero. Con el valor original de 0FFFFh el contador no alcanzó a agotarse, porque el código de soltar la tecla Enter llegó antes y el programa lo imprimió como el carácter £, que corresponde al byte 9C. Luego MAX_RETRY se redujo a 0005h para forzar el timeout, y al ejecutar POLL_T.COM sin presionar ninguna tecla apareció el mensaje "Timeout: sin respuesta del dispositivo", lo que confirma que el bucle termina aunque el dispositivo no responda.

## Checkpoint 3 — Escritura al puerto paralelo
Capturas: capturas/CP3_compilacion_lpt1p.png y capturas/CP3_ejecucion_lpt1p.png

El programa se nombró LPT1P.ASM porque LPT1 es un nombre reservado de DOS para el puerto de impresora. LPT1P.ASM espera a que el bit 7 del registro de estado 379h indique que la impresora está lista, escribe la letra A en el registro de datos 378h y genera el pulso STROBE con el bit 0 del registro de control 37Ah. En la primera compilación NASM mostró advertencias en cada IN y OUT y recortó los puertos a 78h, 79h y 7Ah, porque la forma con el puerto escrito en la instrucción solo admite valores hasta FFh. Por lo tanto se ajustó cargando cada puerto en DX y usando IN AL, DX y OUT DX, AL. Con este cambio LPT1P.COM compiló sin advertencias y al ejecutarlo volvió de inmediato al prompt, ya que en DOSBox-X no hay impresora física y el bit de listo se lee en 1, así que el bucle .wait_ready no se queda esperando.

## Checkpoint 4 — Polling combinado con OR
Capturas: capturas/CP4_compilacion_multi_st.png y capturas/CP4_ejecucion_multi_st.png

MULTI_ST.ASM lee en cada vuelta el bit OBF del puerto 64h y lo guarda en BL, luego lee el bit 7 del puerto 379h, lo normaliza a 0 o 1 y lo guarda en BH. Al combinar BL y BH con OR el bucle solo se repite cuando ninguno de los dos dispositivos está listo, y al salir se revisa cada registro por separado para saber cuál mensaje imprimir. En la primera compilación apareció la misma advertencia de LPT1P en la lectura del puerto 379h, por lo tanto se ajustó cargando el puerto en DX y usando IN AL, DX. Ya con DX, MULTI_ST.COM compiló sin advertencias y al ejecutarlo sin presionar ninguna tecla mostró solo "LPT1 listo (BUSY#=1).", así que el programa identificó al puerto paralelo como el que hizo salir el bucle.

## Decisión Técnica — Polling sin límite o polling con timeout configurable
El bucle sin límite de TECL.ASM es aceptable solo cuando el dispositivo está garantizado a responder. En cambio, el timeout de POLL_T.ASM es preferible cuando el programa no puede asumir que el dispositivo va a responder, porque así el programa no queda bloqueado para siempre.

Reducir MAX_RETRY a 5h es un riesgo porque produce falsos timeouts sobre dispositivos lentos pero funcionales. En la captura capturas/CP5_evidencia_timeout.png se presionó la tecla A justo después de lanzar POLL_T y aun así apareció el mensaje de timeout, mientras la letra llegó después al prompt, de modo que el teclado sí respondió pero tarde.

Un contador de iteraciones no mide tiempo real porque cada vuelta dura lo que la CPU o el emulador tarden en ejecutar IN, TEST y LOOP. Con los 8000 ciclos por milisegundo usados en DOSBox-X un número de vueltas dura cierto tiempo, pero con más ciclos o en una CPU más rápida el mismo número termina antes. En cambio, el contador de ticks en 0040h:006Ch lo incrementa el timer unas 18,2 veces por segundo sin importar qué tan rápido se ejecute el bucle que lo consulta.

## Decisión Técnica — Combinar banderas de dos puertos con OR o verificarlas por separado
El bucle .poll de MULTI_ST.ASM sí se detiene en la primera iteración sin importar el estado del teclado, porque en DOSBox-X el bit de listo del puerto 379h se lee siempre en 1. En la captura capturas/CP5_evidencia_or.png el programa se ejecutó tres veces, una de ellas presionando una tecla justo después de lanzarlo, y las tres mostraron solo el mensaje de LPT1. Por lo tanto la espera combinada pierde su utilidad, ya que nunca llega a esperar al teclado.

Es necesario volver a examinar BL y BH por separado porque el OR junta las dos banderas en un solo valor y descarta cuál de ellas lo puso en 1. Saber que alguno está listo no basta, ya que el programa debe decidir si atiende el teclado, la impresora o los dos.

Con AND el programa esperaría a que ambas condiciones se cumplan al mismo tiempo, que haya una tecla presionada y que la impresora esté lista. Esto tiene sentido en una sincronización tipo rendezvous, como no enviar un dato a la impresora hasta que el usuario haya presionado una tecla y el periférico esté disponible. En cambio, OR solo necesita que ocurra el primero de los dos eventos.

# PARTE 2 — ISR Personalizado y Programación del PIC 8259A
## Checkpoint 1 — ISR propio para IRQ1
Capturas: capturas/P2_CP1_compilacion_isr_kb.png y capturas/P2_CP1_ejecucion_isr_kb.png

Los programas de esta parte se trabajaron en C:\U9P2. ISR_KB.ASM guarda el vector original de INT 09h con INT 21h AH=35h, que lo devuelve en ES:BX, e instala su propio ISR con AH=25h pasando la dirección en DS:DX. Cada vez que se dispara el IRQ1 el ISR lee el puerto 60h, muestra el mensaje, suma al contador y envía el EOI al puerto 20h, y cuando el contador llega a 5 el programa restaura el vector original otra vez con AH=25h.

En la primera prueba salió un mensaje apenas se lanzó el programa y cada tecla sumaba dos, además al final la pantalla se desplazó hasta quedar vacía sin mostrar el mensaje de restauración. Esto pasó porque el IRQ1 se dispara al presionar y al soltar cada tecla, y porque LDS dejó DS apuntando al segmento del handler original cuando se imprimió msg_fin. Por lo tanto se ajustó ignorando dentro del ISR los códigos con el bit 7 en 1 y guardando DS con PUSH y POP alrededor de la restauración. Después del ajuste, al presionar cinco teclas el programa mostró el mensaje exactamente cinco veces y terminó con "ISR restaurado. Fin del programa.".

## Checkpoint 2 — Enmascaramiento con el IMR
Capturas: capturas/P2_CP2_compilacion_mask_kb.png, capturas/P2_CP2_enmascarado_mask_kb.png y capturas/P2_CP2_restaurado_mask_kb.png

MASK_KB.ASM lee el IMR del PIC maestro en el puerto 21h, guarda su valor y le pone en 1 el bit 1 con OR 02h, lo que deshabilita el IRQ1 del teclado. Luego espera 55 ticks, unos 3 segundos, consultando el timer con INT 1Ah, y al final devuelve el IMR a su valor original. En la primera prueba el programa se quedó colgado sin mostrar nada, porque los mensajes estaban al inicio y la CPU los ejecutaba como instrucciones desde la dirección 100h. Por lo tanto se movieron los mensajes al final del programa.

Con los mensajes al final, se presionaron las teclas a, b y c mientras se veía el mensaje de IRQ1 enmascarado y ninguna apareció en pantalla. Al restaurar el IMR el programa mostró "IRQ1 restaurado." y las tres letras aparecieron después en el prompt, lo que confirma que el teclado quedó silenciado solo mientras el IRQ1 estuvo enmascarado.

## Checkpoint 3 — Encadenamiento de ISR
Capturas: capturas/P2_CP3_compilacion_isr_chain.png y capturas/P2_CP3_ejecucion_isr_chain.png

ISR_CHAIN.ASM se creó a partir de ISR_KB.ASM cambiando el ISR por uno que registra cada tecla presionada en el contador propio y luego llama al handler original con PUSHF y CALL FAR [old_isr]. PUSHF junto con el far call simula una instrucción INT, de modo que el IRET del handler original regresa al ISR propio, y como ese handler procesa la tecla y envía el EOI, el ISR propio no lo envía. En la primera prueba el programa terminó a las cinco teclas pero no se vio ninguna letra en pantalla, porque el bucle de espera solo revisaba el contador y nunca leía el teclado. Por lo tanto se cambió el bucle para leer cada tecla con INT 21h AH=01h, que la muestra con eco.

Finalmente, al escribir abcde las cinco letras aparecieron con el eco de DOS y el programa terminó con "ISR restaurado. Fin del programa.", lo que confirma que el ISR propio contó las teclas y el handler original las siguió entregando al sistema.

## Checkpoint 4 — Medición de intervalo con el contador de ticks
Capturas: capturas/P2_CP4_compilacion_isr_time.png y capturas/P2_CP4_ejecucion_isr_time.png

ISR_TIME.ASM lee dentro del ISR la palabra baja del contador de ticks del BIOS en la dirección 0040h:006Ch, que el timer incrementa unas 18,2 veces por segundo, y le resta la lectura guardada en la interrupción anterior. En la primera prueba aparecieron los mismos dos problemas de ISR_KB.ASM, el programa terminó con solo dos teclas porque también medía los códigos de soltar y el mensaje final no se mostró por el DS que deja LDS. Por lo tanto se aplicaron los mismos ajustes, ignorar los códigos con el bit 7 en 1 enviando solo el EOI y guardar DS con PUSH y POP alrededor de la restauración.

Se presionaron cinco teclas midiendo desde Windows el tiempo entre ellas. Con separaciones de 1068 ms, 2052 ms, 421 ms y 421 ms el programa reportó 19, 38, 8 y 7 ticks, y el primer valor de 20 corresponde al tiempo entre el inicio del programa y la primera tecla. Estos valores coinciden con unos 18 ticks por cada segundo transcurrido, lo que confirma que la medición es proporcional al tiempo real entre pulsaciones.
