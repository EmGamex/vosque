@tool
class_name TestTilesetSuelo
extends McpTestSuite

## Suite de pruebas y sincronización para tileset_suelo.

func suite_name() -> String:
	return "tileset_suelo"


func test_configurar_fuentes_tileset() -> void:
	var path_suelo: String = "res://recursos/tileset_suelo.tres"
	var path_suelo_tilesets: String = "res://recursos/tilesets/tileset_suelo.tres"
	var tex_path: String = "res://graficos/Suelo Vosque completo por así decirlo xD rompecabezas mejorada creo version final chad.png"

	var texture: Texture2D = load(tex_path) as Texture2D
	assert_true(texture != null, "La textura de 128x128 debe existir y cargarse")
	if texture == null:
		return

	# 1. Configurar en res://recursos/tileset_suelo.tres
	var tileset: TileSet = load(path_suelo) as TileSet
	assert_true(tileset != null, "tileset_suelo.tres debe existir")
	if tileset != null:
		_asegurar_fuente(tileset, 1, texture)
		var err := ResourceSaver.save(tileset, path_suelo)
		assert_eq(err, OK, "ResourceSaver.save debe guardar sin errores")

	# 2. Configurar en res://recursos/tilesets/tileset_suelo.tres también por compatibilidad
	var tileset_sub: TileSet = load(path_suelo_tilesets) as TileSet
	if tileset_sub != null:
		_asegurar_fuente(tileset_sub, 1, texture)
		ResourceSaver.save(tileset_sub, path_suelo_tilesets)

	# 3. Verificaciones de contrato
	var tileset_verif: TileSet = load(path_suelo) as TileSet
	assert_true(tileset_verif.has_source(0), "Debe conservar la fuente 0 original")
	assert_true(tileset_verif.has_source(1), "Debe tener la nueva fuente 1")
	var src1: TileSetAtlasSource = tileset_verif.get_source(1) as TileSetAtlasSource
	assert_true(src1 != null, "La fuente 1 debe ser TileSetAtlasSource")
	assert_eq(src1.get_tiles_count(), 4, "La fuente 1 debe tener exactamente 4 tiles (2x2)")
	assert_true(is_equal_approx(src1.get_tile_data(Vector2i(0, 0), 0).probability, 1.0), "0:0 debe tener probabilidad 1.0")
	assert_true(is_equal_approx(src1.get_tile_data(Vector2i(1, 1), 0).probability, 1.0), "1:1 debe tener probabilidad 1.0")
	assert_true(is_equal_approx(src1.get_tile_data(Vector2i(1, 0), 0).probability, 0.3), "1:0 debe tener probabilidad 0.3")
	assert_true(is_equal_approx(src1.get_tile_data(Vector2i(0, 1), 0).probability, 0.3), "0:1 debe tener probabilidad 0.3")


func _asegurar_fuente(ts: TileSet, source_id: int, tex: Texture2D) -> void:
	if ts.has_source(source_id):
		ts.remove_source(source_id)
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(64, 64)
	for y in range(2):
		for x in range(2):
			var coords := Vector2i(x, y)
			src.create_tile(coords, Vector2i.ONE)
			var data: TileData = src.get_tile_data(coords, 0)
			if coords == Vector2i(1, 0) or coords == Vector2i(0, 1):
				data.probability = 0.3
			else:
				data.probability = 1.0
	ts.add_source(src, source_id)
