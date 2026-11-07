@tool
extends Node

## Autoload Singleton para la persistencia del High Score en Web y Desktop (Issue #35).
##
## Implementa una estrategia dual:
## 1. user://highscore.save mediante FileAccess (mapeado a IndexedDB en Godot Web).
## 2. Fallback de contingencia a LocalStorage via JavaScriptBridge para entornos iframes (itch.io, Newgrounds).

signal record_actualizado(nuevo_record: int)

const RUTA_GUARDADO_DEFECTO: String = "user://highscore.save"
const CLAVE_LOCAL_STORAGE: String = "vosque_high_score"

var ruta_guardado: String = RUTA_GUARDADO_DEFECTO

var _record_actual: int = 0
var _ultimo_score: int = 0
var _es_nuevo_record_partida: bool = false


func _ready() -> void:
	_record_actual = _cargar_record()


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


## Devuelve el record historico actual.
func obtener_high_score() -> int:
	return _record_actual


## Devuelve el numero de notas recolectadas en la ultima partida registrada.
func obtener_ultimo_score() -> int:
	return _ultimo_score


## Indica si la ultima partida registrada establecio un nuevo record.
func es_ultimo_score_record() -> bool:
	return _es_nuevo_record_partida


## Comprobacion rapida sin mutar estado.
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
