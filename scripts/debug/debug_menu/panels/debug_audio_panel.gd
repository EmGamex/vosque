class_name DebugAudioPanel
extends RefCounted

## Panel de pruebas y balanceo de audio / música (VentanaAudio).

var lbl_musica_estado: Label
var lbl_musica_clip: Label
var lbl_musica_volumen: Label
var btn_musica_menu: Button
var btn_musica_supervivencia: Button
var btn_musica_jumpscare: Button
var btn_musica_game_over: Button
var btn_musica_restaurar: Button
var slider_vol_base: HSlider
var val_slider_vol_base: Label
var slider_aten_pausa: HSlider
var val_slider_aten_pausa: Label
var slider_pitch_go: HSlider
var val_slider_pitch_go: Label


func vincular_nodos(win: DebugWindow) -> void:
	if win == null:
		return
	var base = "Margin/VBox/Contenido/VBoxAudio/"
	lbl_musica_estado = win.get_node_or_null(base + "GridMusica/ValEstadoMusica") as Label
	lbl_musica_clip = win.get_node_or_null(base + "GridMusica/ValClipMusica") as Label
	lbl_musica_volumen = win.get_node_or_null(base + "GridMusica/ValVolumenMusica") as Label

	btn_musica_menu = win.get_node_or_null(base + "HBoxBotonesMusica/BtnMusicaMenu") as Button
	btn_musica_supervivencia = win.get_node_or_null(base + "HBoxBotonesMusica/BtnMusicaSupervivencia") as Button
	btn_musica_jumpscare = win.get_node_or_null(base + "HBoxBotonesMusica/BtnMusicaJumpscare") as Button
	btn_musica_game_over = win.get_node_or_null(base + "HBoxBotonesMusica/BtnMusicaGameOver") as Button
	btn_musica_restaurar = win.get_node_or_null(base + "HBoxBotonesMusica/BtnMusicaRestaurar") as Button

	slider_vol_base = win.get_node_or_null(base + "GridSlidersMusica/SliderVolBase") as HSlider
	val_slider_vol_base = win.get_node_or_null(base + "GridSlidersMusica/ValSliderVolBase") as Label
	slider_aten_pausa = win.get_node_or_null(base + "GridSlidersMusica/SliderAtenPausa") as HSlider
	val_slider_aten_pausa = win.get_node_or_null(base + "GridSlidersMusica/ValSliderAtenPausa") as Label
	slider_pitch_go = win.get_node_or_null(base + "GridSlidersMusica/SliderPitchGO") as HSlider
	val_slider_pitch_go = win.get_node_or_null(base + "GridSlidersMusica/ValSliderPitchGO") as Label


func inicializar_controles_musica(tree: SceneTree, system_ctrl: DebugSystemController) -> void:
	if btn_musica_menu != null and not btn_musica_menu.pressed.is_connected(system_ctrl.forzar_musica_menu):
		btn_musica_menu.pressed.connect(system_ctrl.forzar_musica_menu)
	if btn_musica_supervivencia != null and not btn_musica_supervivencia.pressed.is_connected(system_ctrl.forzar_musica_supervivencia):
		btn_musica_supervivencia.pressed.connect(system_ctrl.forzar_musica_supervivencia)
	if btn_musica_jumpscare != null and not btn_musica_jumpscare.pressed.is_connected(system_ctrl.forzar_corte_jumpscare):
		btn_musica_jumpscare.pressed.connect(system_ctrl.forzar_corte_jumpscare)
	if btn_musica_game_over != null and not btn_musica_game_over.pressed.is_connected(system_ctrl.forzar_modo_game_over):
		btn_musica_game_over.pressed.connect(system_ctrl.forzar_modo_game_over)
	if btn_musica_restaurar != null and not btn_musica_restaurar.pressed.is_connected(system_ctrl.restaurar_audio_normal):
		btn_musica_restaurar.pressed.connect(system_ctrl.restaurar_audio_normal)

	var gm: Node = tree.root.get_node_or_null("GestorMusica") if (tree != null and tree.root != null) else null
	var cfg_musica: ConfiguracionMusica = gm.config if (gm != null and "config" in gm and gm.config is ConfiguracionMusica) else null

	if cfg_musica != null:
		if slider_vol_base != null:
			slider_vol_base.set_value_no_signal(cfg_musica.volumen_base_db)
			if val_slider_vol_base != null: val_slider_vol_base.text = "%.1f dB" % cfg_musica.volumen_base_db
		if slider_aten_pausa != null:
			slider_aten_pausa.set_value_no_signal(cfg_musica.atenuacion_pausa_db)
			if val_slider_aten_pausa != null: val_slider_aten_pausa.text = "%.1f dB" % cfg_musica.atenuacion_pausa_db
		if slider_pitch_go != null:
			slider_pitch_go.set_value_no_signal(cfg_musica.pitch_game_over)
			if val_slider_pitch_go != null: val_slider_pitch_go.text = "%.2fx" % cfg_musica.pitch_game_over

	if slider_vol_base != null and not slider_vol_base.value_changed.is_connected(_on_slider_vol_base_changed.bind(system_ctrl)):
		slider_vol_base.value_changed.connect(_on_slider_vol_base_changed.bind(system_ctrl))
	if slider_aten_pausa != null and not slider_aten_pausa.value_changed.is_connected(_on_slider_aten_pausa_changed.bind(system_ctrl)):
		slider_aten_pausa.value_changed.connect(_on_slider_aten_pausa_changed.bind(system_ctrl))
	if slider_pitch_go != null and not slider_pitch_go.value_changed.is_connected(_on_slider_pitch_go_changed.bind(system_ctrl)):
		slider_pitch_go.value_changed.connect(_on_slider_pitch_go_changed.bind(system_ctrl))


func _on_slider_vol_base_changed(val: float, system_ctrl: DebugSystemController) -> void:
	if system_ctrl != null:
		system_ctrl.set_volumen_base(val)
	if val_slider_vol_base != null:
		val_slider_vol_base.text = "%.1f dB" % val


func _on_slider_aten_pausa_changed(val: float, system_ctrl: DebugSystemController) -> void:
	if system_ctrl != null:
		system_ctrl.set_atenuacion_pausa(val)
	if val_slider_aten_pausa != null:
		val_slider_aten_pausa.text = "%.1f dB" % val


func _on_slider_pitch_go_changed(val: float, system_ctrl: DebugSystemController) -> void:
	if system_ctrl != null:
		system_ctrl.set_pitch_game_over(val)
	if val_slider_pitch_go != null:
		val_slider_pitch_go.text = "%.2fx" % val
