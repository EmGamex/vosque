class_name DebugSystemController
extends RefCounted

## Controlador de escala temporal del motor, reinicio de escena, pausa y controles de audio/música.


func set_time_scale(scale: float, cfg: Node) -> void:
	Engine.time_scale = scale
	if cfg != null:
		cfg.time_scale = scale


func reiniciar_escena(tree: SceneTree) -> void:
	if tree != null:
		tree.paused = false
		tree.reload_current_scene()


func toggle_pausa(tree: SceneTree, pausar: bool) -> void:
	if tree != null:
		tree.paused = pausar


# ==========================================
# Controles de Audio y Música Interactiva (Issue #28)
# ==========================================

func forzar_musica_menu(gestor_musica: Node = null) -> void:
	var gm := _resolver_gestor_musica(gestor_musica)
	if gm != null and gm.has_method("reproducir_menu_o_tutorial"):
		gm.reproducir_menu_o_tutorial()


func forzar_musica_supervivencia(gestor_musica: Node = null) -> void:
	var gm := _resolver_gestor_musica(gestor_musica)
	if gm != null and gm.has_method("transicionar_a_supervivencia"):
		gm.transicionar_a_supervivencia()


func forzar_corte_jumpscare(gestor_musica: Node = null) -> void:
	var gm := _resolver_gestor_musica(gestor_musica)
	if gm != null and gm.has_method("detener_por_jumpscare"):
		gm.detener_por_jumpscare()


func forzar_modo_game_over(gestor_musica: Node = null) -> void:
	var gm := _resolver_gestor_musica(gestor_musica)
	if gm != null and gm.has_method("activar_modo_game_over"):
		gm.activar_modo_game_over()


func restaurar_audio_normal(gestor_musica: Node = null) -> void:
	var gm := _resolver_gestor_musica(gestor_musica)
	if gm != null and gm.has_method("restaurar_parametros_normales"):
		gm.restaurar_parametros_normales()


func set_volumen_base(val_db: float, cfg_musica: ConfiguracionMusica = null, gestor_musica: Node = null) -> void:
	var config := _resolver_config_musica(cfg_musica, gestor_musica)
	if config != null:
		config.volumen_base_db = val_db


func set_atenuacion_pausa(val_db: float, cfg_musica: ConfiguracionMusica = null, gestor_musica: Node = null) -> void:
	var config := _resolver_config_musica(cfg_musica, gestor_musica)
	if config != null:
		config.atenuacion_pausa_db = val_db


func set_pitch_game_over(val_pitch: float, cfg_musica: ConfiguracionMusica = null, gestor_musica: Node = null) -> void:
	var config := _resolver_config_musica(cfg_musica, gestor_musica)
	if config != null:
		config.pitch_game_over = val_pitch


func obtener_telemetria_musica(gestor_musica: Node = null) -> Dictionary:
	var gm := _resolver_gestor_musica(gestor_musica)
	if gm == null:
		return {
			"estado": "N/A",
			"clip": "N/A",
			"volumen_db": -8.0,
			"en_pausa": false
		}

	var estado_nombre := "SILENCIO"
	if gm.has_method("get_estado_actual"):
		var est = gm.get_estado_actual()
		match est:
			1: estado_nombre = "MENU_TUTORIAL"
			2: estado_nombre = "SUPERVIVENCIA"
			3: estado_nombre = "GAME_OVER"
			_: estado_nombre = "SILENCIO"

	var clip_nombre: String = str(gm.get_clip_activo()) if gm.has_method("get_clip_activo") else ""
	if clip_nombre.is_empty():
		clip_nombre = "Ninguno"

	var vol_db: float = gm.get_volumen_actual_db() if gm.has_method("get_volumen_actual_db") else -8.0
	var en_pausa: bool = gm.is_en_pausa() if gm.has_method("is_en_pausa") else false

	return {
		"estado": estado_nombre,
		"clip": clip_nombre,
		"volumen_db": vol_db,
		"en_pausa": en_pausa
	}


func _resolver_gestor_musica(nodo: Node = null) -> Node:
	if nodo != null:
		return nodo
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null and tree.root.has_node("GestorMusica"):
		return tree.root.get_node("GestorMusica")
	return null


func _resolver_config_musica(cfg: ConfiguracionMusica = null, gm_nodo: Node = null) -> ConfiguracionMusica:
	if cfg != null:
		return cfg
	var gm := _resolver_gestor_musica(gm_nodo)
	if gm != null and "config" in gm and gm.config is ConfiguracionMusica:
		return gm.config as ConfiguracionMusica
	return null


# ==========================================
# Persistencia y High Score (Issue #35)
# ==========================================

func obtener_high_score(gestor_persistencia: Node = null) -> int:
	var gp := _resolver_gestor_persistencia(gestor_persistencia)
	if gp != null and gp.has_method("obtener_high_score"):
		return gp.obtener_high_score()
	return 0


func resetear_high_score(gestor_persistencia: Node = null) -> void:
	var gp := _resolver_gestor_persistencia(gestor_persistencia)
	if gp != null and gp.has_method("resetear_high_score"):
		gp.resetear_high_score()


func _resolver_gestor_persistencia(nodo: Node = null) -> Node:
	if nodo != null:
		return nodo
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null and tree.root.has_node("GestorPersistencia"):
		return tree.root.get_node("GestorPersistencia")
	return null
