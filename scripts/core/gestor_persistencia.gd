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

const SECCION_AUDIO: String = "audio"
const SECCION_VIDEO: String = "video"
const CLAVE_MASTER: String = "master"
const CLAVE_MUSICA: String = "musica"
const CLAVE_SFX: String = "sfx"
const CLAVE_USAR_AUDIO_USUARIO: String = "usar_audio_usuario"
const CLAVE_PANTALLA_COMPLETA: String = "pantalla_completa"
const VOLUMEN_LINEAL_MAX: float = 100.0
const VOLUMEN_LINEAL_MIN: float = 0.0001
const RUTA_BUS_LAYOUT_DEFECTO: String = "res://default_bus_layout.tres"

const VOLUMENES_PREDETERMINADOS_DEFECTO_DB: Dictionary = {
	&"Master": 0.0,
	&"musica": -7.9588003,
	&"sfx": -1.9382002,
	&"Ambiente": -6.0,
	&"Criatura": 1.0,
}

var ruta_guardado: String = RUTA_GUARDADO_DEFECTO
var ruta_config: String = RUTA_CONFIG_DEFECTO

var _record_actual: int = 0
var _ultimo_score: int = 0
var _es_nuevo_record_partida: bool = false
var _volumenes_predeterminados_db: Dictionary = {}


func _ready() -> void:
	_inicializar_volumenes_predeterminados()
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
# Persistencia de Opciones y Audio (Dual: Predeterminado vs Usuario)
# ==========================================

func _inicializar_volumenes_predeterminados() -> void:
	_volumenes_predeterminados_db = VOLUMENES_PREDETERMINADOS_DEFECTO_DB.duplicate()
	if ResourceLoader.exists(RUTA_BUS_LAYOUT_DEFECTO):
		var layout := load(RUTA_BUS_LAYOUT_DEFECTO) as AudioBusLayout
		if layout != null:
			# Leer los dB definidos en el layout sin mutar el AudioServer actual
			for nombre_bus in [&"Master", &"musica", &"sfx", &"Ambiente", &"Criatura"]:
				var idx := AudioServer.get_bus_index(nombre_bus)
				if idx >= 0:
					_volumenes_predeterminados_db[nombre_bus] = VOLUMENES_PREDETERMINADOS_DEFECTO_DB.get(nombre_bus, AudioServer.get_bus_volume_db(idx))


func obtener_configuracion_predeterminada() -> Dictionary:
	return {
		CLAVE_USAR_AUDIO_USUARIO: false,
		CLAVE_MASTER: db_to_linear(obtener_volumen_bus_predeterminado_db(&"Master")) * VOLUMEN_LINEAL_MAX,
		CLAVE_MUSICA: db_to_linear(obtener_volumen_bus_predeterminado_db(&"musica")) * VOLUMEN_LINEAL_MAX,
		CLAVE_SFX: db_to_linear(obtener_volumen_bus_predeterminado_db(&"sfx")) * VOLUMEN_LINEAL_MAX,
		CLAVE_PANTALLA_COMPLETA: false,
	}


func obtener_volumen_bus_predeterminado_db(nombre_bus: StringName) -> float:
	if _volumenes_predeterminados_db.is_empty():
		_inicializar_volumenes_predeterminados()
	if _volumenes_predeterminados_db.has(nombre_bus):
		return float(_volumenes_predeterminados_db[nombre_bus])
	return 0.0


func calcular_offset_usuario_db(porcentaje: float) -> float:
	var lineal: float = clampf(porcentaje / VOLUMEN_LINEAL_MAX, VOLUMEN_LINEAL_MIN, 1.0)
	return linear_to_db(lineal)


func calcular_db_bus_usuario(nombre_bus: StringName, porcentaje: float) -> float:
	return obtener_volumen_bus_predeterminado_db(nombre_bus) + calcular_offset_usuario_db(porcentaje)


func calcular_porcentaje_desde_db_bus(nombre_bus: StringName, db_actual: float) -> float:
	var base_db: float = obtener_volumen_bus_predeterminado_db(nombre_bus)
	var offset_db: float = db_actual - base_db
	var lineal: float = db_to_linear(offset_db) * VOLUMEN_LINEAL_MAX
	return clampf(lineal, 0.0, VOLUMEN_LINEAL_MAX)


func esta_usando_audio_usuario() -> bool:
	var cfg := cargar_configuracion_audio()
	return bool(cfg.get(CLAVE_USAR_AUDIO_USUARIO, false))


func guardar_configuracion_audio(master_vol: float, musica_vol: float, sfx_vol: float, pantalla_completa: bool, usar_audio_usuario: bool = true) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECCION_AUDIO, CLAVE_USAR_AUDIO_USUARIO, usar_audio_usuario)
	cfg.set_value(SECCION_AUDIO, CLAVE_MASTER, clampf(master_vol, 0.0, VOLUMEN_LINEAL_MAX))
	cfg.set_value(SECCION_AUDIO, CLAVE_MUSICA, clampf(musica_vol, 0.0, VOLUMEN_LINEAL_MAX))
	cfg.set_value(SECCION_AUDIO, CLAVE_SFX, clampf(sfx_vol, 0.0, VOLUMEN_LINEAL_MAX))
	cfg.set_value(SECCION_VIDEO, CLAVE_PANTALLA_COMPLETA, pantalla_completa)
	cfg.save(ruta_config)

	var payload := {
		CLAVE_USAR_AUDIO_USUARIO: usar_audio_usuario,
		CLAVE_MASTER: clampf(master_vol, 0.0, VOLUMEN_LINEAL_MAX),
		CLAVE_MUSICA: clampf(musica_vol, 0.0, VOLUMEN_LINEAL_MAX),
		CLAVE_SFX: clampf(sfx_vol, 0.0, VOLUMEN_LINEAL_MAX),
		CLAVE_PANTALLA_COMPLETA: pantalla_completa,
	}

	if OS.has_feature("web"):
		var datos_json := JSON.stringify(payload)
		JavaScriptBridge.eval("localStorage.setItem('%s', '%s');" % [CLAVE_LOCAL_STORAGE_CONFIG, datos_json])

	configuracion_audio_actualizada.emit(payload)


func cargar_configuracion_audio() -> Dictionary:
	var datos: Dictionary = {}
	var cfg := ConfigFile.new()
	if cfg.load(ruta_config) == OK:
		if cfg.has_section_key(SECCION_AUDIO, CLAVE_USAR_AUDIO_USUARIO):
			datos[CLAVE_USAR_AUDIO_USUARIO] = bool(cfg.get_value(SECCION_AUDIO, CLAVE_USAR_AUDIO_USUARIO))
		if cfg.has_section_key(SECCION_AUDIO, CLAVE_MASTER):
			datos[CLAVE_MASTER] = float(cfg.get_value(SECCION_AUDIO, CLAVE_MASTER))
		if cfg.has_section_key(SECCION_AUDIO, CLAVE_MUSICA):
			datos[CLAVE_MUSICA] = float(cfg.get_value(SECCION_AUDIO, CLAVE_MUSICA))
		if cfg.has_section_key(SECCION_AUDIO, CLAVE_SFX):
			datos[CLAVE_SFX] = float(cfg.get_value(SECCION_AUDIO, CLAVE_SFX))
		if cfg.has_section_key(SECCION_VIDEO, CLAVE_PANTALLA_COMPLETA):
			datos[CLAVE_PANTALLA_COMPLETA] = bool(cfg.get_value(SECCION_VIDEO, CLAVE_PANTALLA_COMPLETA))

	if OS.has_feature("web") and datos.is_empty():
		var val = JavaScriptBridge.eval("localStorage.getItem('%s');" % CLAVE_LOCAL_STORAGE_CONFIG)
		if val != null and not str(val).is_empty():
			var parsed = JSON.parse_string(str(val))
			if parsed is Dictionary:
				datos = parsed

	return datos


func alternar_modo_audio_usuario(usar_usuario: bool) -> void:
	var cfg := cargar_configuracion_audio()
	var master_v: float = float(cfg.get(CLAVE_MASTER, VOLUMEN_LINEAL_MAX))
	var musica_v: float = float(cfg.get(CLAVE_MUSICA, VOLUMEN_LINEAL_MAX))
	var sfx_v: float = float(cfg.get(CLAVE_SFX, VOLUMEN_LINEAL_MAX))
	var pantalla_c: bool = bool(cfg.get(CLAVE_PANTALLA_COMPLETA, false))
	guardar_configuracion_audio(master_v, musica_v, sfx_v, pantalla_c, usar_usuario)
	aplicar_configuracion_audio()


func restablecer_audio_predeterminado(conservar_perfil_usuario: bool = false) -> void:
	var cfg := cargar_configuracion_audio()
	var pantalla_c: bool = bool(cfg.get(CLAVE_PANTALLA_COMPLETA, false))
	var pred := obtener_configuracion_predeterminada()
	if conservar_perfil_usuario:
		var master_v: float = float(cfg.get(CLAVE_MASTER, pred[CLAVE_MASTER]))
		var musica_v: float = float(cfg.get(CLAVE_MUSICA, pred[CLAVE_MUSICA]))
		var sfx_v: float = float(cfg.get(CLAVE_SFX, pred[CLAVE_SFX]))
		guardar_configuracion_audio(master_v, musica_v, sfx_v, pantalla_c, false)
	else:
		guardar_configuracion_audio(pred[CLAVE_MASTER], pred[CLAVE_MUSICA], pred[CLAVE_SFX], pantalla_c, false)
	aplicar_configuracion_audio()


func aplicar_configuracion_audio() -> void:
	var config := cargar_configuracion_audio()
	var usar_usuario: bool = bool(config.get(CLAVE_USAR_AUDIO_USUARIO, false))
	var pred := obtener_configuracion_predeterminada()

	var pct_master: float = float(config.get(CLAVE_MASTER, pred[CLAVE_MASTER])) if usar_usuario else float(pred[CLAVE_MASTER])
	var pct_musica: float = float(config.get(CLAVE_MUSICA, pred[CLAVE_MUSICA])) if usar_usuario else float(pred[CLAVE_MUSICA])
	var pct_sfx: float = float(config.get(CLAVE_SFX, pred[CLAVE_SFX])) if usar_usuario else float(pred[CLAVE_SFX])

	var db_master: float = linear_to_db(maxf(pct_master / VOLUMEN_LINEAL_MAX, VOLUMEN_LINEAL_MIN))
	var idx_master := AudioServer.get_bus_index(&"Master")
	if idx_master >= 0:
		AudioServer.set_bus_volume_db(idx_master, db_master)

	var db_musica: float = linear_to_db(maxf(pct_musica / VOLUMEN_LINEAL_MAX, VOLUMEN_LINEAL_MIN))
	var offset_musica_db: float = db_musica - obtener_volumen_bus_predeterminado_db(&"musica")
	var idx_musica := AudioServer.get_bus_index(&"musica")
	if idx_musica >= 0:
		AudioServer.set_bus_volume_db(idx_musica, db_musica)
	if has_node("/root/GestorMusica"):
		var gm: Node = get_node("/root/GestorMusica")
		if gm.has_method("establecer_offset_usuario_db"):
			gm.establecer_offset_usuario_db(offset_musica_db, true)
		elif gm.has_method("establecer_volumen_base"):
			gm.establecer_volumen_base(db_musica)
		elif "config" in gm and gm.config is ConfiguracionMusica:
			gm.config.volumen_base_db = db_musica

	var db_sfx: float = linear_to_db(maxf(pct_sfx / VOLUMEN_LINEAL_MAX, VOLUMEN_LINEAL_MIN))
	for bus_name in [&"ui", &"sfx"]:
		var idx_sfx := AudioServer.get_bus_index(bus_name)
		if idx_sfx >= 0:
			AudioServer.set_bus_volume_db(idx_sfx, db_sfx)

	if config.has(CLAVE_PANTALLA_COMPLETA) and not Engine.is_editor_hint():
		if bool(config[CLAVE_PANTALLA_COMPLETA]):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
