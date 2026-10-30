# Protocolos de Prueba y Diagnóstico

Este documento define los procedimientos reproducibles de verificación manual y pruebas de estrés para validar los subsistemas críticos de **Vosque**.

> 🛠️ **Menú in-game:** [Menú de Depuración In-Game](menu_debug_ingame.md)  
> 🌀 **Sistema de mutación:** [Sistema de Mutación y Niebla](../gameplay/sistema_de_mutacion_y_niebla.md)  
> 👾 **Comportamiento del monstruo:** [Monstruo e IA](../gameplay/monstruo_e_ia.md)

---

## 1. Protocolo de Validación de Mutación Espacial (Issue #3)

Procedimiento para confirmar que la arena $2 \times 2$ permuta correctamente sin afectar al jugador:

1. **Iniciar la escena principal:** Ejecutar `escenas/maain.tscn` (o presionar <kbd>F5</kbd>).
2. **Abrir el Menú de Debug:** Presionar <kbd>F3</kbd> dos veces hasta desplegar el **Menú Completo**.
3. **Pestaña "Escenario":**
   - Activar `[x] Mostrar Corredores de Seguridad (160 px)` y verificar que las franjas verdes en los ejes $X=0, Y=0$ permanezcan libres de colisionadores rojos.
   - Activar `[x] Vista Global (God View)` para desanclar la cámara con zoom panorámico $0.225\times$.
   - Presionar reiteradamente el botón **"Forzar Mutación de Sectores Lejanos"**:
     - ✅ **Confirmar:** El cuadrante donde se encuentra el jugador **nunca** es reemplazado.
     - ✅ **Confirmar:** Los otros 3 cuadrantes cambian aleatoriamente de sub-escena sin tirones de framerate ni errores en la salida de consola.

---

## 2. Protocolo Anti-Atascamiento de la Criatura

Procedimiento para validar que la mutación nunca atrape al monstruo dentro de un árbol o roca:

1. Con el juego en ejecución y la consola F3 abierta en la pestaña **"Enemigo"**:
2. Presionar **"Forzar Mutación"** mientras el monstruo se desplaza por uno de los 3 cuadrantes que van a mutar.
3. Observar la posición del monstruo en God View:
   - ✅ **Confirmar:** Si el nuevo diseño de sector coloca un árbol sólido sobre la criatura, el sistema detecta el solapamiento (`test_move()`) y lo reubica de inmediato al `Marker2D` seguro más cercano.
   - ✅ **Confirmar:** La criatura reubicada respeta la distancia mínima de seguridad ($\ge 600\text{ px}$ del jugador) para evitar muertes injustas instantáneas.

---

## 3. Protocolo de Pruebas de Locomoción y Físicas

1. En la pestaña **"Jugador"**:
   - Mover el slider de `speed` para probar respuesta a $400, 800\text{ y } 1200\text{ px/s}$.
   - Probar salto con <kbd>Espacio</kbd> sobre troncos caídos (Capa 2): confirmar que no hay colisión durante los $0.45\text{ s}$ de arco aéreo.
   - Presionar una segunda vez <kbd>Espacio</kbd> en el aire: confirmar que la plancha (*Dive*) impulsa horizontalmente a $1200\text{ px/s}$ y provoca la ventana de vulnerabilidad de $0.6\text{ s}$ en suelo.
   - Caer directamente sobre un obstáculo bajo al terminar el salto: verificar que la regla de despenetración deslice al jugador a suelo libre sin quedar bloqueado dentro de la geometría.

---

## 4. Protocolo de Validación y Estrés del Sistema de Pausa (Issue #17)

Procedimiento para certificar que el menú de pausa superpuesto no introduce bugs de temporizadores, estados fantasma ni desincronización:

1. **Prueba de Congelación de `SceneTreeTimer` (Niebla y Mutación):**
   - Recoger una nota para iniciar la mutación.
   - En el instante en que la pantalla se cubre por niebla (`Fase.CEGUERA`), presionar inmediatamente <kbd>Escape</kbd> o <kbd>P</kbd>.
   - Esperar 5 a 10 segundos con el menú de pausa abierto.
   - ✅ **Confirmar:** La pausa de oscuridad ($0.4\text{ s}$) **no** se consume en segundo plano. Al pulsar *"Continuar"*, la niebla completa exactamente el tiempo de ceguera restante y abre con fluidez.
2. **Prueba Anti-Salto Fantasma (<kbd>Espacio</kbd>):**
   - Iniciar partida con estamina al 100%.
   - Pausar el juego mediante <kbd>Escape</kbd> o <kbd>P</kbd>.
   - Presionar <kbd>Espacio</kbd> para activar el botón enfocado *"Continuar"*.
   - ✅ **Confirmar:** El menú se cierra y el personaje reanuda en suelo sin ejecutar un salto involuntario ni gastar $-20\text{ pts}$ de estamina.
3. **Prueba de Invariante de Transición y Muerte:**
   - Durante el fundido de iris al iniciar partida o reiniciar, pulsar repetidamente <kbd>Escape</kbd>.
   - ✅ **Confirmar:** La guardia `puede_pausar()` ignora la entrada mientras `_cambiando == true`.
   - Permitir que el monstruo capture al jugador y presionar <kbd>Escape</kbd> simultáneamente.
   - ✅ **Confirmar:** La pantalla de Game Over transiciona limpiamente sin dejar el menú de pausa flotando encima.
4. **Prueba de Precedencia con Menú de Debug (<kbd>F3</kbd>):**
   - Presionar <kbd>F3</kbd> dos veces hasta abrir el Menú Completo de depuración.
   - Presionar <kbd>Escape</kbd>.
   - ✅ **Confirmar:** El Menú Completo se oculta inmediatamente y el input queda consumido, **sin abrir** el menú de pausa del juego.
5. **Prueba de Auto-Pausa por Pérdida de Foco en Navegador:**
   - Ejecutar el juego en ventana o navegador.
   - Pinchar fuera de la ventana del juego o cambiar a otra pestaña.
   - ✅ **Confirmar:** `GestorDeEscenas` intercepta `NOTIFICATION_APPLICATION_FOCUS_OUT` y despliega automáticamente el `MenuPausa`.

---

## 5. Checklist de Validación en Navegador Web (HTML5)

Antes de publicar cualquier actualización en itch.io o Newgrounds:
* [ ] **Captura de Teclas:** Verificar que presionar <kbd>Espacio</kbd>, flechas o <kbd>W</kbd><kbd>A</kbd><kbd>S</kbd><kbd>D</kbd> no haga scroll en la página web del navegador (`get_viewport().set_input_as_handled()`).
* [ ] **Persistencia de High Score:** Jugar una partida, registrar récord, cerrar la pestaña del navegador, reabrirla y confirmar que el récord histórico se conserva vía IndexedDB / `LocalStorage`.
* [ ] **Audio en Primer Clic:** Confirmar que el contexto de Web Audio se active sin errores de bloqueo tras el primer clic en la pantalla de inicio.
* [ ] **Estabilidad Mono-Hilo:** Verificar que durante la mutación de cuadrantes no se presenten caídas abruptas de framerate en WASM.
