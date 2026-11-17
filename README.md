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
