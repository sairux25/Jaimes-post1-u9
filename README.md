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

El programa se nombró LPT1P.ASM porque LPT1 es un nombre reservado de DOS para el puerto de impresora. LPT1P.ASM espera a que el bit 7 del registro de estado 379h indique que la impresora está lista, escribe la letra A en el registro de datos 378h y genera el pulso STROBE con el bit 0 del registro de control 37Ah. En la primera compilación NASM mostró advertencias en cada IN y OUT y recortó los puertos a 78h, 79h y 7Ah, porque la forma con el puerto escrito en la instrucción solo admite valores hasta FFh. Por lo tanto se ajustó cargando cada puerto en DX y usando IN AL, DX y OUT DX, AL. Hecho esto, LPT1P.COM compiló sin advertencias y al ejecutarlo volvió de inmediato al prompt, ya que en DOSBox-X no hay impresora física y el bit de listo se lee en 1, así que el bucle .wait_ready no se queda esperando.
