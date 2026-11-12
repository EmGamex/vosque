@tool
class_name GameOver
extends Control

## Pantalla de Game Over: reintentar o volver al menú.
## Emite señales semánticas hacia el orquestador ("Signal Up").

signal reintentar_solicitado
signal menu_solicitado

@onready var _boton_reintentar: Button = $Layout/Columna/BotonReintentar
@onready var _boton_menu: Button = $Layout/Columna/BotonMenu
@onready var _label_paginas: Label = get_node_or_null("Layout/Columna/Stats/PaginasLabel") as Label
@onready var _label_record: Label = get_node_or_null("Layout/Columna/Stats/RecordLabel") as Label
@onready var _label_nuevo_record: Label = get_node_or_null("Layout/Columna/Stats/NuevoRecordLabel") as Label

var _bloqueado: bool = false
var _silenciar_audio_ajustes: bool = false


func _ready() -> void:
	_refrescar_desde_persistencia()
	if _boton_reintentar != null:
		_boton_reintentar.pressed.connect(_on_reintentar_pulsado)
		_boton_reintentar.focus_entered.connect(_on_boton_enfocado)
		_boton_reintentar.mouse_entered.connect(_on_boton_mouse_entered.bind(_boton_reintentar))
	if _boton_menu != null:
		_boton_menu.pressed.connect(_on_menu_pulsado)
		_boton_menu.focus_entered.connect(_on_boton_enfocado)
		_boton_menu.mouse_entered.connect(_on_boton_mouse_entered.bind(_boton_menu))


## Da el foco a "Reintentar". El gestor lo llama diferido al mostrar la pantalla (Call Down).
func enfocar() -> void:
	_bloqueado = false
	_refrescar_desde_persistencia()
	if not Engine.is_editor_hint() and has_node("/root/GestorMusica"):
		get_node("/root/GestorMusica").activar_modo_game_over()
	_silenciar_audio_ajustes = true
	if _boton_reintentar != null:
		_boton_reintentar.grab_focus()
	_silenciar_audio_ajustes = false


## Actualiza la presentación de estadísticas de partida y récord.
func actualizar_estadisticas(paginas: int, record: int, es_nuevo_record: bool = false) -> void:
	_asegurar_referencias_nodos()
	if _label_paginas != null:
		_label_paginas.text = "Páginas: %d" % paginas
	if _label_record != null:
		_label_record.text = "Récord: %d" % record
	if _label_nuevo_record != null:
		_label_nuevo_record.visible = es_nuevo_record


func _asegurar_referencias_nodos() -> void:
	if _label_paginas == null:
		_label_paginas = get_node_or_null("Layout/Columna/Stats/PaginasLabel") as Label
	if _label_record == null:
		_label_record = get_node_or_null("Layout/Columna/Stats/RecordLabel") as Label
	if _label_nuevo_record == null:
		_label_nuevo_record = get_node_or_null("Layout/Columna/Stats/NuevoRecordLabel") as Label


func _refrescar_desde_persistencia() -> void:
	if has_node("/root/GestorPersistencia"):
		var gp = get_node("/root/GestorPersistencia")
		var paginas: int = gp.obtener_ultimo_score() if gp.has_method("obtener_ultimo_score") else 0
		var record: int = gp.obtener_high_score() if gp.has_method("obtener_high_score") else 0
		var es_nuevo: bool = gp.es_ultimo_score_record() if gp.has_method("es_ultimo_score_record") else false
		actualizar_estadisticas(paginas, record, es_nuevo)


func _on_boton_enfocado() -> void:
	if not _silenciar_audio_ajustes:
		ControladorAudioUI.emitir_seguro(self, ControladorAudioUI.EventoUI.PAUSA_NAVEGAR)


func _on_boton_mouse_entered(btn: Button) -> void:
	if visible and not _bloqueado and btn != null and not btn.has_focus():
		btn.grab_focus()


func _on_reintentar_pulsado() -> void:
	if _bloqueado:
		return
	_bloqueado = true
	ControladorAudioUI.emitir_seguro(self, ControladorAudioUI.EventoUI.PAUSA_ACEPTAR)
	if has_node("/root/GestorMusica"):
		var gestor_musica = get_node("/root/GestorMusica")
		gestor_musica.restaurar_parametros_normales()
		gestor_musica.reproducir_menu_o_tutorial()
	reintentar_solicitado.emit()


func _on_menu_pulsado() -> void:
	if _bloqueado:
		return
	_bloqueado = true
	ControladorAudioUI.emitir_seguro(self, ControladorAudioUI.EventoUI.PAUSA_ACEPTAR)
	if has_node("/root/GestorMusica"):
		var gestor_musica = get_node("/root/GestorMusica")
		gestor_musica.restaurar_parametros_normales()
		gestor_musica.reproducir_menu_o_tutorial()
	menu_solicitado.emit()


func _input(evento: InputEvent) -> void:
	if not visible or _bloqueado:
		return
	if evento.is_action_pressed("ui_cancel"):
		_on_menu_pulsado()
		get_viewport().set_input_as_handled()
