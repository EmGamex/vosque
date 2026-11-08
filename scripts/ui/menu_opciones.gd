@tool
class_name MenuOpciones
extends Control

## Mockup funcional del menú de opciones.
## Navegable mediante las acciones de movimiento del juego:
## - personaje-arriba / personaje-abajo: Foco vertical
## - personaje-izquierda / personaje-derecha: Modificar valor o slider
## - personaje-salto / ui_accept: Activar checkbox o botón
## - ui_cancel: Emitir señal de volver

signal volver_solicitado

@onready var slider_master: HSlider = $Layout/PanelOpciones/Margen/Columna/FilaMaster/SliderMaster
@onready var label_val_master: Label = $Layout/PanelOpciones/Margen/Columna/FilaMaster/ValMaster
@onready var slider_musica: HSlider = $Layout/PanelOpciones/Margen/Columna/FilaMusica/SliderMusica
@onready var label_val_musica: Label = $Layout/PanelOpciones/Margen/Columna/FilaMusica/ValMusica
@onready var slider_sfx: HSlider = $Layout/PanelOpciones/Margen/Columna/FilaSFX/SliderSFX
@onready var label_val_sfx: Label = $Layout/PanelOpciones/Margen/Columna/FilaSFX/ValSFX
@onready var check_pantalla_completa: CheckBox = $Layout/PanelOpciones/Margen/Columna/FilaPantalla/CheckPantalla
@onready var boton_restablecer: Button = $Layout/PanelOpciones/Margen/Columna/BotonRestablecer
@onready var boton_volver: Button = $Layout/PanelOpciones/Margen/Columna/BotonVolver

const RUTA_BUS_LAYOUT_DEFECTO: String = "res://default_bus_layout.tres"

var _elementos_foco: Array[Control] = []
var _indice_foco: int = 0
var _activo: bool = false

func _ready() -> void:
	_elementos_foco = []
	if slider_master: _elementos_foco.append(slider_master)
	if slider_musica: _elementos_foco.append(slider_musica)
	if slider_sfx: _elementos_foco.append(slider_sfx)
	if check_pantalla_completa: _elementos_foco.append(check_pantalla_completa)
	if boton_restablecer: _elementos_foco.append(boton_restablecer)
	if boton_volver: _elementos_foco.append(boton_volver)

	_conectar_senales()
	_cargar_valores_actuales()


func _conectar_senales() -> void:
	if slider_master and not slider_master.value_changed.is_connected(_on_slider_master_changed):
		slider_master.value_changed.connect(_on_slider_master_changed)
	if slider_musica and not slider_musica.value_changed.is_connected(_on_slider_musica_changed):
		slider_musica.value_changed.connect(_on_slider_musica_changed)
	if slider_sfx and not slider_sfx.value_changed.is_connected(_on_slider_sfx_changed):
		slider_sfx.value_changed.connect(_on_slider_sfx_changed)
	if check_pantalla_completa and not check_pantalla_completa.toggled.is_connected(_on_pantalla_completa_toggled):
		check_pantalla_completa.toggled.connect(_on_pantalla_completa_toggled)
	if boton_restablecer and not boton_restablecer.pressed.is_connected(_on_boton_restablecer_pressed):
		boton_restablecer.pressed.connect(_on_boton_restablecer_pressed)
	if boton_volver and not boton_volver.pressed.is_connected(_on_boton_volver_pressed):
		boton_volver.pressed.connect(_on_boton_volver_pressed)


func _cargar_valores_actuales() -> void:
	var idx_master := AudioServer.get_bus_index(&"Master")
	if idx_master >= 0:
		var db := AudioServer.get_bus_volume_db(idx_master)
		var lineal := db_to_linear(db) * 100.0
		if slider_master:
			slider_master.value = clamp(lineal, 0.0, 100.0)
			_actualizar_label_porcentaje(label_val_master, slider_master.value)

	var idx_musica := AudioServer.get_bus_index(&"musica")
	if idx_musica >= 0:
		var db := AudioServer.get_bus_volume_db(idx_musica)
		var lineal := db_to_linear(db) * 100.0
		if slider_musica:
			slider_musica.value = clamp(lineal, 0.0, 100.0)
			_actualizar_label_porcentaje(label_val_musica, slider_musica.value)

	var idx_sfx := AudioServer.get_bus_index(&"ui")
	if idx_sfx < 0:
		idx_sfx = AudioServer.get_bus_index(&"sfx")
	if idx_sfx >= 0:
		var db := AudioServer.get_bus_volume_db(idx_sfx)
		var lineal := db_to_linear(db) * 100.0
		if slider_sfx:
			slider_sfx.value = clamp(lineal, 0.0, 100.0)
			_actualizar_label_porcentaje(label_val_sfx, slider_sfx.value)

	if check_pantalla_completa and not Engine.is_editor_hint():
		var modo := DisplayServer.window_get_mode()
		check_pantalla_completa.button_pressed = (modo == DisplayServer.WINDOW_MODE_FULLSCREEN or modo == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)


func activar() -> void:
	_activo = true
	_cargar_valores_actuales()
	_indice_foco = 0
	if not _elementos_foco.is_empty():
		_elementos_foco[_indice_foco].grab_focus()


func desactivar() -> void:
	_activo = false
	for elem in _elementos_foco:
		if elem and elem.has_focus():
			elem.release_focus()
	_guardar_ajustes()


func _guardar_ajustes() -> void:
	if has_node("/root/GestorPersistencia"):
		var gp = get_node("/root/GestorPersistencia")
		if gp.has_method("guardar_configuracion_audio"):
			var master_v: float = slider_master.value if slider_master else 100.0
			var musica_v: float = slider_musica.value if slider_musica else 100.0
			var sfx_v: float = slider_sfx.value if slider_sfx else 100.0
			var pantalla_c: bool = check_pantalla_completa.button_pressed if check_pantalla_completa else false
			gp.guardar_configuracion_audio(master_v, musica_v, sfx_v, pantalla_c)


func _actualizar_label_porcentaje(lbl: Label, val: float) -> void:
	if lbl:
		lbl.text = "%d%%" % int(val)


func _on_slider_master_changed(val: float) -> void:
	_actualizar_label_porcentaje(label_val_master, val)
	var idx := AudioServer.get_bus_index(&"Master")
	if idx >= 0:
		var db := linear_to_db(max(val / 100.0, 0.0001))
		AudioServer.set_bus_volume_db(idx, db)


func _on_slider_musica_changed(val: float) -> void:
	_actualizar_label_porcentaje(label_val_musica, val)
	var db := linear_to_db(max(val / 100.0, 0.0001))
	var idx := AudioServer.get_bus_index(&"musica")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, db)
	if has_node("/root/GestorMusica"):
		var gm = get_node("/root/GestorMusica")
		if gm.has_method("establecer_volumen_base"):
			gm.establecer_volumen_base(db)
		elif "config" in gm and gm.config is ConfiguracionMusica:
			gm.config.volumen_base_db = db


func _on_slider_sfx_changed(val: float) -> void:
	_actualizar_label_porcentaje(label_val_sfx, val)
	var db := linear_to_db(max(val / 100.0, 0.0001))
	for nombre_bus in [&"ui", &"sfx"]:
		var idx := AudioServer.get_bus_index(nombre_bus)
		if idx >= 0:
			AudioServer.set_bus_volume_db(idx, db)


func _on_pantalla_completa_toggled(activado: bool) -> void:
	if Engine.is_editor_hint():
		return
	if activado:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_boton_restablecer_pressed() -> void:
	if not _activo:
		return
	restablecer_valores_por_defecto()
	ControladorAudioUI.emitir_seguro(self, ControladorAudioUI.EventoUI.MENU_ACEPTAR)


func restablecer_valores_por_defecto() -> void:
	if ResourceLoader.exists(RUTA_BUS_LAYOUT_DEFECTO):
		var layout_defecto: AudioBusLayout = load(RUTA_BUS_LAYOUT_DEFECTO)
		if layout_defecto:
			AudioServer.set_bus_layout(layout_defecto)

	var modo_defecto_config: int = ProjectSettings.get_setting("display/window/size/mode", DisplayServer.WINDOW_MODE_WINDOWED)
	var es_pantalla_completa: bool = (
		modo_defecto_config == DisplayServer.WINDOW_MODE_FULLSCREEN
		or modo_defecto_config == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	)

	if not Engine.is_editor_hint():
		DisplayServer.window_set_mode(modo_defecto_config)

	if check_pantalla_completa:
		check_pantalla_completa.button_pressed = es_pantalla_completa

	_cargar_valores_actuales()

	var idx_musica := AudioServer.get_bus_index(&"musica")
	if idx_musica >= 0:
		var db := AudioServer.get_bus_volume_db(idx_musica)
		if has_node("/root/GestorMusica"):
			var gm = get_node("/root/GestorMusica")
			if gm.has_method("establecer_volumen_base"):
				gm.establecer_volumen_base(db)
			elif "config" in gm and gm.config is ConfiguracionMusica:
				gm.config.volumen_base_db = db

	_guardar_ajustes()


func _on_boton_volver_pressed() -> void:
	if not _activo:
		return
	_guardar_ajustes()
	ControladorAudioUI.emitir_seguro(self, ControladorAudioUI.EventoUI.MENU_RETROCEDER)
	volver_solicitado.emit()


func _unhandled_input(evento: InputEvent) -> void:
	if not _activo:
		return

	if evento.is_action_pressed("ui_cancel"):
		ControladorAudioUI.emitir_seguro(self, ControladorAudioUI.EventoUI.MENU_RETROCEDER)
		volver_solicitado.emit()
		get_viewport().set_input_as_handled()
		return

	if evento.is_action_pressed("personaje-arriba"):
		_navegar_foco(-1)
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("personaje-abajo"):
		_navegar_foco(1)
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("personaje-izquierda"):
		_modificar_control_actual(-1)
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("personaje-derecha"):
		_modificar_control_actual(1)
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("personaje-salto"):
		_activar_control_actual()
		get_viewport().set_input_as_handled()


func _navegar_foco(dir: int) -> void:
	if _elementos_foco.is_empty():
		return
	for i in range(_elementos_foco.size()):
		if _elementos_foco[i].has_focus():
			_indice_foco = i
			break
	_indice_foco = posmod(_indice_foco + dir, _elementos_foco.size())
	_elementos_foco[_indice_foco].grab_focus()
	ControladorAudioUI.emitir_seguro(self, ControladorAudioUI.EventoUI.MENU_SELECCIONAR)


func _modificar_control_actual(dir: int) -> void:
	if _elementos_foco.is_empty():
		return
	var control := _elementos_foco[_indice_foco]
	if control is HSlider:
		var slider := control as HSlider
		slider.value = clamp(slider.value + (dir * 5.0), slider.min_value, slider.max_value)
		ControladorAudioUI.emitir_seguro(self, ControladorAudioUI.EventoUI.MENU_SELECCIONAR)
	elif control is CheckBox:
		var check := control as CheckBox
		check.button_pressed = not check.button_pressed
		ControladorAudioUI.emitir_seguro(self, ControladorAudioUI.EventoUI.MENU_ACEPTAR)


func _activar_control_actual() -> void:
	if _elementos_foco.is_empty():
		return
	var control := _elementos_foco[_indice_foco]
	if control is CheckBox:
		var check := control as CheckBox
		check.button_pressed = not check.button_pressed
		ControladorAudioUI.emitir_seguro(self, ControladorAudioUI.EventoUI.MENU_ACEPTAR)
	elif control is Button:
		(control as Button).emit_signal("pressed")
