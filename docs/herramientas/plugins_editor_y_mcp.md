# Plugins de Editor, Servidores MCP y Monitores

Este documento detalla las extensiones de desarrollo en el editor de Godot 4, la automatización vía MCP y los monitores personalizados de telemetría de **Vosque**.

> 🛠️ **Menú in-game:** [Menú de Depuración In-Game](menu_debug_ingame.md)  
> 🧪 **Guías de prueba:** [Protocolos de Prueba y Diagnóstico](protocolos_de_prueba.md)

---

## 1. Toolbar de Personaje (`addons/personaje_tools`)

Plugin de editor contextual diseñado para agilizar el ajuste y calibración física del protagonista:
* **Activación Automática:** Se ancla en el menú superior del viewport 2D (`CONTAINER_CANVAS_EDITOR_MENU`) cuando se selecciona un nodo `CharacterBody2D` que contenga las propiedades cinemáticas de *Vosque* (`speed`, `acceleration`, `friction`).
* **Presets Rápidos:**
  - *Sigilo:* $150\text{ px/s}$ de velocidad, $800\text{ px/s}^2$ aceleración, $1000\text{ px/s}^2$ fricción.
  - *Normal:* $800\text{ px/s}$ de velocidad, $5000\text{ px/s}^2$ aceleración, $5000\text{ px/s}^2$ fricción.
  - *Sprint:* $1000\text{ px/s}$ de velocidad, $5000\text{ px/s}^2$ aceleración, $5000\text{ px/s}^2$ fricción.
* **Persistencia Directa:** Al modificar valores mediante los *SpinBoxes* de la barra, los cambios se escriben directamente en las propiedades exportadas de la escena seleccionada.

---

## 2. Validador y Linter de Nivel (`addons/escenario_tools` - Planificado)

Herramienta diseñada para asistir en el diseño de nuevas variantes de sector en `escenas/sectores/variantes/`:
* **Guías Visuales Automáticas:** Dibuja en el lienzo del editor el marco de variante de $2160 \times 2160\text{ px}$ y las zonas de exclusión de $80\text{ px}$ en los bordes que tocan los ejes divisores.
* **Validación Estática de Variante:**
  - Alerta si algún `StaticBody2D` invade la franja de seguridad de $80\text{ px}$.
  - Confirma que los obstáculos usen las capas correspondientes (Capa 1 para altos, Capa 2 para bajos).
  - Verifica que existan entre 2 y 4 nodos `Marker2D` en el grupo `"puntos_nota"`.

---

## 3. Servidor de Automatización (`addons/godot_ai`)

Servidor MCP (*Model Context Protocol*) integrado que habilita el soporte para agentes y pair programming en Godot 4:
* Inspección y manipulación en vivo del árbol de nodos.
* Capturas de pantalla del editor para validación visual.
* Ejecución de pruebas unitarias y lectura de logs de motor en tiempo real.
* Compilación y verificación sintáctica de scripts GDScript en caliente.

---

## 4. Monitores Personalizados del Depurador (`Performance`)

Al iniciar el proyecto en modo de desarrollo (`OS.is_debug_build()`), el script [`scripts/debug_menu/debug_custom_monitors.gd`](../../scripts/debug_menu/debug_custom_monitors.gd) registra métricas en el panel **Depurador > Monitores**:

| Monitor | Tipo | Rango / Unidad | Propósito |
| :--- | :---: | :---: | :--- |
| `Vosque/Estamina Jugador` | `float` | $0.0 - 100.0\text{ pts}$ | Evaluar gasto y retardo de recarga. |
| `Vosque/Velocidad Jugador` | `float` | $\text{px/s}$ | Medir aceleración instantánea y frenado. |
| `Vosque/Velocidad Enemigo` | `float` | $\text{px/s}$ | Validar escalado de dificultad por notas. |
| `Vosque/Distancia Monstruo` | `float` | $\text{px}$ | Comprobar radios de tensión y radar sonoro. |
| `Vosque/Estado Jugador` | `int` | $0 \to 6$ | Inspeccionar transiciones de la FSM (`REPOSO` a `RECUPERACIÓN`). |
| `Vosque/Notas Recogidas` | `int` | $0 \to 10+$ | Correlacionar notas con picos de velocidad de la IA. |
| `Vosque/Trauma Camara` | `float` | $0.0 - 1.0$ | Auditar sacudidas e inyección de estrés en la cámara. |
| `Vosque/Nodos Huerfanos` | `int` | Unidades | Seguir `Performance.OBJECT_ORPHAN_NODE_COUNT` para garantizar que la destrucción e instanciación de variantes no deje fugas de memoria (*leaks*). |

---

## 5. Auditoría de Renderizado y Colisiones en Caliente

Atajos integrados para depurar físicas y rendimiento en navegadores:
* **Formas de Colisión Visibles en Caliente:** Alterna las formas de colisión para verificar la desactivación de la Capa 2 durante el salto.
* **Modos de Renderizado del Viewport:**
  - `DEBUG_DRAW_UNSHADED`: Desactiva luces y sombras para auditar geometría y texturas base.
  - `DEBUG_DRAW_OVERDRAW`: Muestra solapamiento de capas semitransparentes para vigilar la sobrecarga de shaders en WebGL.
