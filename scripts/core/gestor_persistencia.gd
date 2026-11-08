@tool
extends Node

## Autoload Singleton para la persistencia del High Score y Configuración de Usuario (Issue #35, Issue #40).
##
## Implementa una estrategia dual:
## 1. user://highscore.save y user://configuracion.cfg mediante FileAccess/ConfigFile (mapeado a IndexedDB en Godot Web).
## 2. Fallback de contingencia a LocalStorage via JavaScriptBridge para entornos iframes (itch.io, Newgrounds).

signal record_actualizado(nuevo_record: int)
signal configuracion_audio_actualizada(config: Dictionary)

const RUTA_GUARDADO_DEFECTO: String = "user://highscore.save"
const CLAVE_LOCAL_STORAGE: String = "vosque_high_score"

const RUTA_CONFIG_DEFECTO: String = "user://configuracion.cfg"
const CLAVE_LOCAL_STORAGE_CONFIG: String = "vosque_configuracion_audio"

var ruta_guardado: String = RUTA_GUARDADO_DEFECTO
var ruta_config: String = RUTA_CONFIG_DEFECTO

var _record_actual: int = 0
var _ultimo_score: int = 0
var _es_nuevo_record_partida: bool = false


func _ready() -> void:
	_record_actual = _cargar_record()
	aplicar_configuracion_audio()


## Guarda un puntaje si supera el record historico actual.
## Retorna true si es un nuevo record, false en caso contrario.
func guardar_high_score(nuevo_score: int) -> bool:
	var puntaje_valido: int = maxi(0, nuevo_score)
	_ultimo_score = puntaje_valido
	
	if puntaje_valido > _record_actual:
		_record_actual = puntaje_valido
		_es_nuevo_record_partida = true
		_persistir_record(_record_actual)
		record_actualizado.emit(_record_actual)
		return true
	
	_es_nuevo_record_partida = false
	return false


func obtener_high_score() -> int:
	return _record_actual


func obtener_ultimo_score() -> int:
	return _ultimo_score


func es_ultimo_score_record() -> bool:
	return _es_nuevo_record_partida


func es_nuevo_record(puntuacion: int) -> bool:
	return puntuacion > _record_actual


## Resetea el record a 0 en memoria, user:// y localStorage.
func resetear_high_score() -> void:
	_record_actual = 0
	_ultimo_score = 0
	_es_nuevo_record_partida = false
	
	if FileAccess.file_exists(ruta_guardado):
		DirAccess.remove_absolute(ruta_guardado)
	
	if OS.has_feature("web"):
		_resetear_record_web()
	
	record_actualizado.emit(0)


## Recarga el record desde almacenamiento fisico y sincroniza memoria.
func recargar_desde_disco() -> int:
	_record_actual = _cargar_record()
	return _record_actual


func _persistir_record(record: int) -> void:
	_guardar_record_nativo(record)
	if OS.has_feature("web"):
		_guardar_record_web(record)


func _guardar_record_nativo(record: int) -> bool:
	var file := FileAccess.open(ruta_guardado, FileAccess.WRITE)
	if file == null:
		push_warning("GestorPersistencia: Error al abrir %s para escritura (Error: %d)" % [ruta_guardado, FileAccess.get_open_error()])
		return false
	file.store_32(record)
	file.close()
	return true


func _cargar_record() -> int:
	var score_nativo: int = 0
	if FileAccess.file_exists(ruta_guardado):
		var file := FileAccess.open(ruta_guardado, FileAccess.READ)
		if file != null:
			if file.get_length() >= 4:
				score_nativo = file.get_32()
			file.close()
	
	if OS.has_feature("web"):
		var score_web := _cargar_record_web()
		if score_web > score_nativo:
			score_nativo = score_web
			_guardar_record_nativo(score_nativo)
	
	return score_nativo


func _guardar_record_web(record: int) -> void:
	if OS.has_feature("web"):
		var comando_js: String = "localStorage.setItem('%s', '%d');" % [CLAVE_LOCAL_STORAGE, record]
		JavaScriptBridge.eval(comando_js)


func _cargar_record_web() -> int:
	if OS.has_feature("web"):
		var val = JavaScriptBridge.eval("localStorage.getItem('%s');" % CLAVE_LOCAL_STORAGE)
		if val != null and str(val).is_valid_int():
			return int(str(val))
	return 0


func _resetear_record_web() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("localStorage.removeItem('%s');" % CLAVE_LOCAL_STORAGE)


# ==========================================
# Persistencia de Opciones y Audio
# ==========================================

func guardar_configuracion_audio(master_vol: float, musica_vol: float, sfx_vol: float, pantalla_completa: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_vol)
	cfg.set_value("audio", "musica", musica_vol)
	cfg.set_value("audio", "sfx", sfx_vol)
	cfg.set_value("video", "pantalla_completa", pantalla_completa)
	cfg.save(ruta_config)

	if OS.has_feature("web"):
		var datos_json := JSON.stringify({
			"master": master_vol,
			"musica": musica_vol,
			"sfx": sfx_vol,
			"pantalla_completa": pantalla_completa
		})
		JavaScriptBridge.eval("localStorage.setItem('%s', '%s');" % [CLAVE_LOCAL_STORAGE_CONFIG, datos_json])

	configuracion_audio_actualizada.emit({
		"master": master_vol,
		"musica": musica_vol,
		"sfx": sfx_vol,
		"pantalla_completa": pantalla_completa
	})


func cargar_configuracion_audio() -> Dictionary:
	var datos: Dictionary = {}
	var cfg := ConfigFile.new()
	if cfg.load(ruta_config) == OK:
		if cfg.has_section_key("audio", "master"):
			datos["master"] = float(cfg.get_value("audio", "master"))
		if cfg.has_section_key("audio", "musica"):
			datos["musica"] = float(cfg.get_value("audio", "musica"))
		if cfg.has_section_key("audio", "sfx"):
			datos["sfx"] = float(cfg.get_value("audio", "sfx"))
		if cfg.has_section_key("video", "pantalla_completa"):
			datos["pantalla_completa"] = bool(cfg.get_value("video", "pantalla_completa"))

	if OS.has_feature("web") and datos.is_empty():
		var val = JavaScriptBridge.eval("localStorage.getItem('%s');" % CLAVE_LOCAL_STORAGE_CONFIG)
		if val != null and not str(val).is_empty():
			var parsed = JSON.parse_string(str(val))
			if parsed is Dictionary:
				datos = parsed

	return datos


func aplicar_configuracion_audio() -> void:
	var config := cargar_configuracion_audio()
	if config.is_empty():
		return

	if config.has("master"):
		var idx_master := AudioServer.get_bus_index(&"Master")
		if idx_master >= 0:
			var db := linear_to_db(max(float(config["master"]) / 100.0, 0.0001))
			AudioServer.set_bus_volume_db(idx_master, db)

	if config.has("musica"):
		var val_musica: float = float(config["musica"])
		var db_musica := linear_to_db(max(val_musica / 100.0, 0.0001))
		var idx_musica := AudioServer.get_bus_index(&"musica")
		if idx_musica >= 0:
			AudioServer.set_bus_volume_db(idx_musica, db_musica)
		if has_node("/root/GestorMusica"):
			var gm: Node = get_node("/root/GestorMusica")
			if gm.has_method("establecer_volumen_base"):
				gm.establecer_volumen_base(db_musica)
			elif "config" in gm and gm.config is ConfiguracionMusica:
				gm.config.volumen_base_db = db_musica

	if config.has("sfx"):
		var val_sfx: float = float(config["sfx"])
		var db_sfx := linear_to_db(max(val_sfx / 100.0, 0.0001))
		for bus_name in [&"ui", &"sfx"]:
			var idx_sfx := AudioServer.get_bus_index(bus_name)
			if idx_sfx >= 0:
				AudioServer.set_bus_volume_db(idx_sfx, db_sfx)

	if config.has("pantalla_completa") and not Engine.is_editor_hint():
		if bool(config["pantalla_completa"]):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
