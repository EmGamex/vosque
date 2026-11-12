# Contratos de UI, Plantillas GDScript y Referencias Técnicas

Este documento provee las plantillas de código completas, el mapeo de eventos de audio, la especificación de propiedades para escenas y el checklist de integración para interfaces en **Vosque**.

---

## 1. Plantilla 1: Pantalla Principal Autónoma (`extends Control`)

Aplica esta plantilla para pantallas completas gestionadas por `GestorDeEscenas` (como nuevos menús de selección, pantallas de victoria o finales alternativos).

```gdscript
@tool
class_name MiNuevaPantalla
extends Control

## Señales semánticas de salida (Signal Up)
signal accion_completada_solicitado
signal menu_solicitado

@onready var boton_principal: Button = $Layout/Columna/BotonPrincipal
@onready var boton_menu: Button = $Layout/Columna/BotonMenu

var _bloqueado: bool = false
var _silenciar_audio_ajustes: bool = false

func _ready() -> void:
	_conectar_botones()

func _conectar_botones() -> void:
	if boton_principal != null:
		boton_principal.pressed.connect(_on_boton_principal_pressed)
		boton_principal.focus_entered.connect(_on_boton_enfocado)
		boton_principal.mouse_entered.connect(_on_boton_mouse_entered.bind(boton_principal))
	if boton_menu != null:
		boton_menu.pressed.connect(_on_boton_menu_pressed)
		boton_menu.focus_entered.connect(_on_boton_enfocado)
		boton_menu.mouse_entered.connect(_on_boton_mouse_entered.bind(boton_menu))

## Invocado de forma diferida por GestorDeEscenas al activarse la pantalla (Call Down)
func enfocar() -> void:
	_bloqueado = false
	_silenciar_audio_ajustes = true
	if boton_principal != null:
		boton_principal.grab_focus()
	_silenciar_audio_ajustes = false

func _on_boton_enfocado() -> void:
	if not _silenciar_audio_ajustes:
		ControladorAudioUI.emitir_seguro(self, ControladorAudioUI.EventoUI.MENU_SELECCIONAR)

func _on_boton_mouse_entered(btn: Button) -> void:
	if visible and not _bloqueado and btn != null and not btn.has_focus():
		btn.grab_focus()

func _on_boton_principal_pressed() -> void:
	if _bloqueado:
		return
	_bloqueado = true
	ControladorAudioUI.emitir_seguro(self, ControladorAudioUI.EventoUI.MENU_ACEPTAR)
	accion_completada_solicitado.emit()

func _on_boton_menu_pressed() -> void:
	if _bloqueado:
		return
	_bloqueado = true
	ControladorAudioUI.emitir_seguro(self, ControladorAudioUI.EventoUI.MENU_RETROCEDER)
	menu_solicitado.emit()

func _input(evento: InputEvent) -> void:
	if not visible or _bloqueado:
		return
	if evento.is_action_pressed("ui_cancel"):
		_on_boton_menu_pressed()
		get_viewport().set_input_as_handled()
```

---

## 2. Plantilla 2: Subpanel de Lienzo Compartido

Aplica esta plantilla para submenús o paneles secundarios que coexisten en la misma escena o viewport (como `MenuOpciones` y `MenuCreditos` dentro de `MenuInicio`).

```gdscript
@tool
class_name MiSubpanelAjustes
extends Control

signal volver_solicitado

@onready var primer_control: Control = $Layout/Panel/Margen/Columna/PrimerControl
@onready var boton_volver: Button = $Layout/Panel/Margen/Columna/BotonVolver

var _activo: bool = false
var _silenciar_audio: bool = false
var _elementos_foco: Array[Control] = []

func _ready() -> void:
	_elementos_foco = []
	if primer_control != null: _elementos_foco.append(primer_control)
	if boton_volver != null: _elementos_foco.append(boton_volver)
	
	_conectar_eventos()
	_aplicar_aislamiento(false)

func _aplicar_aislamiento(habilitado: bool) -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP if habilitado else Control.MOUSE_FILTER_IGNORE
	for elem in _elementos_foco:
		if elem != null:
			if not habilitado and elem.has_focus():
				elem.release_focus()
			elem.focus_mode = Control.FOCUS_ALL if habilitado else Control.FOCUS_NONE

func _conectar_eventos() -> void:
	for ctrl in _elementos_foco:
		if ctrl != null:
			ctrl.focus_entered.connect(_on_elemento_enfocado)
			ctrl.mouse_entered.connect(_on_elemento_mouse_entered.bind(ctrl))
	if boton_volver != null:
		boton_volver.pressed.connect(_on_boton_volver_pressed)

func activar() -> void:
	_activo = true
	visible = true
	_aplicar_aislamiento(true)
	_silenciar_audio = true
	if not _elementos_foco.is_empty():
		_elementos_foco[0].grab_focus()
	_silenciar_audio = false

func desactivar() -> void:
	_activo = false
	_aplicar_aislamiento(false)

func _on_elemento_enfocado() -> void:
	if _activo and not _silenciar_audio:
		ControladorAudioUI.emitir_seguro(self, ControladorAudioUI.EventoUI.MENU_SELECCIONAR)

func _on_elemento_mouse_entered(ctrl: Control) -> void:
	if _activo and ctrl != null and not ctrl.has_focus():
		ctrl.grab_focus()

func _on_boton_volver_pressed() -> void:
	if not _activo:
		return
	ControladorAudioUI.emitir_seguro(self, ControladorAudioUI.EventoUI.MENU_RETROCEDER)
	volver_solicitado.emit()

func _input(evento: InputEvent) -> void:
	if not _activo:
		return
	if evento.is_action_pressed("ui_cancel"):
		_on_boton_volver_pressed()
		get_viewport().set_input_as_handled()
```

---

## 3. Catálogo de Eventos Semánticos de Audio (`ControladorAudioUI.EventoUI`)

| `EventoUI` | Bus | Stream WAV Asociado | Canal | Uso Típico |
| :--- | :--- | :--- | :--- | :--- |
| `MENU_SELECCIONAR` | `sfx` | `seleccionar_menu_main.wav` | `PlayerCursor` (Jitter) | Cambio de foco entre árboles, opciones, sliders o botones generales. |
| `MENU_ACEPTAR` | `sfx` | `aceptar_menu_pincial.wav` | `PlayerAccion` / `Aux` | Confirmar descenso en inicio, pulsar "Jugar", alternar checkboxes. |
| `MENU_RETROCEDER` | `sfx` | `retroceder_menu_main.wav` | `PlayerAccion` / `Aux` | Pulsar Escape en árbol de menú para subir al cielo, o pulsar "Volver". |
| `PAUSA_ABRIR` | `sfx` | `abrir_pausa.wav` | `PlayerAccion` | Disparado al pulsar tecla de pausa en partida viva. |
| `PAUSA_NAVEGAR` | `sfx` | `JA_SE_SYS_CURS_MOVE.wav` | `PlayerCursor` (Jitter) | Navegación vertical entre opciones de pausa o botones de Game Over. |
| `PAUSA_ACEPTAR` | `sfx` | `presionar_pausa.wav` | `PlayerAccion` / `Aux` | Confirmar opción en pausa ("Reiniciar", "Menú") o Game Over ("Reintentar"). |
| `PAUSA_CERRAR` | `sfx` | `cerrar_pausa_01.wav` | `PlayerAccion` | Reanudar la partida desde el menú de pausa. |

---

## 4. Checklist de Creación e Integración de Pantallas

Sigue el flujo de trabajo estándar documentado en [`vosque-mcp-workflow`](../vosque-mcp-workflow/SKILL.md) utilizando las herramientas MCP (`scene_manage`, `scene_open`, `node_create`, `node_set_property`, `scene_save` y `script_create`/`script_patch`):

1. **Creación de la Escena:** Generar la escena con nodo raíz `Control` y salvarla bajo `res://escenas/ui/` o `res://escenas/`.
2. **Estructura y Layout:** Anidar contenedores (`CenterContainer`, `VBoxContainer`) y botones con `custom_minimum_size = Vector2(400, 72)` y tipografía `res://fuentes/raleway_bold.tres`.
3. **Blindaje de Foco Lateral:** Fijar `focus_neighbor_left` y `focus_neighbor_right` a `NodePath(".")` en listas verticales para que la navegación lateral no salte accidentalmente a otros paneles.
4. **Script con Contratos:** Asignar un script que implemente `enfocar()`, las señales `*_solicitado`, la bandera `_bloqueado` y la conexión desacoplada a `ControladorAudioUI.emitir_seguro()`.
5. **Persistencia:** Guardar la escena con `scene_save`.
6. **Registro en `GestorDeEscenas`:**
   - Añadir la constante de ruta `const RUTA_NUEVA: String = "res://escenas/mi_pantalla.tscn"` y registrarla en `ESCENAS_PRECARGADAS`.
   - En `_conectar_senales_pantalla(pantalla: Node)`, conectar las señales `*_solicitado` hacia los métodos del gestor.
7. **Verificación Automatizada:** Ejecutar la suite de pruebas unitarias o de integración mediante `test_run`.
