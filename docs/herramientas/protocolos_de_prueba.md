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

## 4. Checklist de Validación en Navegador Web (HTML5)

Antes de publicar cualquier actualización en itch.io o Newgrounds:
* [ ] **Captura de Teclas:** Verificar que presionar <kbd>Espacio</kbd>, flechas o <kbd>W</kbd><kbd>A</kbd><kbd>S</kbd><kbd>D</kbd> no haga scroll en la página web del navegador (`get_viewport().set_input_as_handled()`).
* [ ] **Persistencia de High Score:** Jugar una partida, registrar récord, cerrar la pestaña del navegador, reabrirla y confirmar que el récord histórico se conserva vía IndexedDB / `LocalStorage`.
* [ ] **Audio en Primer Clic:** Confirmar que el contexto de Web Audio se active sin errores de bloqueo tras el primer clic en la pantalla de inicio.
* [ ] **Estabilidad Mono-Hilo:** Verificar que durante la mutación de cuadrantes no se presenten caídas abruptas de framerate en WASM.
