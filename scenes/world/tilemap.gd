extends TileMap

@export var collsion_disabled_layers: Array[int] = [] # you can change it to array or whatever

func _use_tile_data_runtime_update(layer: int, _coords: Vector2i) -> bool:
	return collsion_disabled_layers.has(layer)

func _tile_data_runtime_update(layer: int, _coords: Vector2i, tile_data: TileData) -> void:
	tile_data.set_collision_polygons_count(0, 0) # this removes tile collision for the specified layer
