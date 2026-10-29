extends Node

# Operation: Iron Veil — Godot vertical-slice prototype.
# Procedural assets are intentionally self-contained so the project opens without downloads.

const BG := Color("#070d14")
const PANEL := Color("#111d29")
const ACCENT := Color("#a6d8f5")
const TEXT := Color("#edf5fa")
const MUTED := Color("#91a5b5")
const GREEN := Color("#b7e4c7")
const RED := Color("#ff6b6b")
const MAG := Color("#202a30")
const GUN := Color("#242b2d")

var ui_layer: CanvasLayer
var root_ui: Control
var in_training := false
var game_paused := false
var player: CharacterBody3D
var camera: Camera3D
var world: Node3D
var weapon_root: Node3D
var hud_label: Label
var ammo_label: Label
var status_label: Label
var score_label: Label
var damage_overlay: ColorRect
var crosshair: Label
var hitmarker: Label
var look_yaw := 0.0
var look_pitch := 0.0
var mouse_captured := false
var ammo := 30
var reserve_ammo := 120
var reloading := false
var reload_left := 0.0
var fire_cooldown := 0.0
var health := 100
var targets_remaining := 8
var mission_time := 240.0
var mission_complete := false
var mission_failed := false
var score := 0
var kill_streak := 0
var best_streak := 0
var damage_flash_left := 0.0
var target_nodes: Array[Node3D] = []
var objective_nodes: Array[Node3D] = []
var hitmarker_left := 0.0
var weapon_kick := 0.0
var move_bob := 0.0
var previous_player_position := Vector3.ZERO
var flight_mode := false
var player_collision: CollisionShape3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	root_ui = Control.new()
	root_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(root_ui)
	_show_splash()

func _clear_ui() -> void:
	for child in root_ui.get_children():
		child.queue_free()

func _show_splash() -> void:
	_clear_ui()
	var backdrop := ColorRect.new()
	backdrop.color = BG
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ui.add_child(backdrop)
	var stripe := ColorRect.new()
	stripe.color = ACCENT
	stripe.position = Vector2(0, 0)
	stripe.size = Vector2(5, 720)
	root_ui.add_child(stripe)
	var title := Label.new()
	title.text = "OPERATION: IRON VEIL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", MUTED)
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	title.position = Vector2(-330, -90)
	title.size = Vector2(660, 45)
	root_ui.add_child(title)
	var credit := Label.new()
	credit.text = "ゆっくりP製作"
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credit.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	credit.add_theme_font_size_override("font_size", 44)
	credit.add_theme_color_override("font_color", TEXT)
	credit.modulate.a = 0.0
	credit.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	credit.position = Vector2(-330, -32)
	credit.size = Vector2(660, 76)
	root_ui.add_child(credit)
	var subtitle := Label.new()
	subtitle.text = "TACTICAL COMBAT SYSTEM  /  INITIALIZING"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", ACCENT)
	subtitle.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	subtitle.position = Vector2(-260, 58)
	subtitle.size = Vector2(520, 24)
	root_ui.add_child(subtitle)
	var tween := create_tween()
	tween.tween_property(credit, "modulate:a", 1.0, 0.8)
	tween.tween_interval(1.0)
	tween.tween_property(credit, "modulate:a", 0.0, 0.65)
	tween.tween_callback(_show_lobby)

func _show_lobby() -> void:
	in_training = false
	_clear_ui()
	var backdrop := ColorRect.new()
	backdrop.color = BG
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ui.add_child(backdrop)
	var top_line := ColorRect.new()
	top_line.color = ACCENT
	top_line.position = Vector2(48, 126)
	top_line.size = Vector2(560, 2)
	root_ui.add_child(top_line)
	var header := Label.new()
	header.text = "OPERATION: IRON VEIL"
	header.position = Vector2(48, 34)
	header.size = Vector2(700, 54)
	header.add_theme_font_size_override("font_size", 32)
	header.add_theme_color_override("font_color", TEXT)
	root_ui.add_child(header)
	var subtitle := Label.new()
	subtitle.text = "TACTICAL COMBAT SIMULATION  /  GODOT BUILD 0.2"
	subtitle.position = Vector2(51, 86)
	subtitle.size = Vector2(700, 26)
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", ACCENT)
	root_ui.add_child(subtitle)
	var welcome := Label.new()
	welcome.text = "訓練シミュレーション"
	welcome.position = Vector2(50, 160)
	welcome.size = Vector2(600, 55)
	welcome.add_theme_font_size_override("font_size", 30)
	welcome.add_theme_color_override("font_color", TEXT)
	root_ui.add_child(welcome)
	var description := Label.new()
	description.text = "1km × 1kmの戦闘区域を自由に探索。\nまずはマップを完成させる開発ビルドです。敵AIはまだ実装していません。"
	description.position = Vector2(52, 222)
	description.size = Vector2(690, 62)
	description.add_theme_font_size_override("font_size", 16)
	description.add_theme_color_override("font_color", MUTED)
	root_ui.add_child(description)
	var start_button := _make_button("作戦開始  /  DEPLOY   →", Vector2(52, 322), Vector2(330, 58))
	start_button.pressed.connect(_start_training)
	root_ui.add_child(start_button)
	var settings_button := _make_button("操作・設定", Vector2(52, 395), Vector2(220, 48))
	settings_button.pressed.connect(_show_settings)
	root_ui.add_child(settings_button)
	var panel := Panel.new()
	panel.position = Vector2(790, 165)
	panel.size = Vector2(390, 330)
	panel.add_theme_stylebox_override("panel", _panel_style())
	root_ui.add_child(panel)
	var panel_title := Label.new()
	panel_title.text = "MISSION BRIEF"
	panel_title.position = Vector2(820, 188)
	panel_title.size = Vector2(300, 30)
	panel_title.add_theme_font_size_override("font_size", 15)
	panel_title.add_theme_color_override("font_color", ACCENT)
	root_ui.add_child(panel_title)
	var briefing := Label.new()
	briefing.text = "01  /  MAP\n      1 km × 1 km exploration area\n\n02  /  TERRAIN\n      Mountain, tunnel, highway and town\n\n03  /  CURRENT PHASE\n      Map construction and traversal\n\n04  /  NEXT\n      Map polish, then AI"
	briefing.position = Vector2(820, 230)
	briefing.size = Vector2(330, 230)
	briefing.add_theme_font_size_override("font_size", 15)
	briefing.add_theme_color_override("font_color", TEXT)
	root_ui.add_child(briefing)
	var footer := Label.new()
	footer.text = "YUKKURI P PRODUCTION     /     DEVELOPMENT BUILD"
	footer.position = Vector2(50, 670)
	footer.size = Vector2(700, 24)
	footer.add_theme_font_size_override("font_size", 12)
	footer.add_theme_color_override("font_color", MUTED)
	root_ui.add_child(footer)
	var status := Label.new()
	status.text = "OFFLINE TRAINING  •  NO SERVER REQUIRED"
	status.position = Vector2(680, 670)
	status.size = Vector2(520, 24)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status.add_theme_font_size_override("font_size", 12)
	status.add_theme_color_override("font_color", GREEN)
	root_ui.add_child(status)

func _make_button(label_text: String, button_position: Vector2, button_size: Vector2) -> Button:
	var button := Button.new()
	button.text = label_text
	button.position = button_position
	button.size = button_size
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _button_style(PANEL, Color("#304758")))
	button.add_theme_stylebox_override("hover", _button_style(Color("#20374a"), ACCENT))
	button.add_theme_stylebox_override("pressed", _button_style(Color("#2a4658"), TEXT))
	return button

func _button_style(fill: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0d1721")
	style.border_color = Color("#304758")
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	return style

func _show_settings() -> void:
	_clear_ui()
	var backdrop := ColorRect.new()
	backdrop.color = BG
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ui.add_child(backdrop)
	var title := Label.new()
	title.text = "操作・設定"
	title.position = Vector2(50, 45)
	title.size = Vector2(500, 60)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", TEXT)
	root_ui.add_child(title)
	var info := Label.new()
	info.text = "移動：WASD / 矢印キー\n高速飛行：FでON/OFF（飛行中は視点方向へ移動）\n上昇：Space　下降：Ctrl\n高速移動：Shift\n視点：マウス（左クリックで視点操作開始）\nEsc：一時停止メニュー\n\n現在はマップ制作フェーズです。敵AIはまだありません。"
	info.position = Vector2(55, 125)
	info.size = Vector2(680, 270)
	info.add_theme_font_size_override("font_size", 18)
	info.add_theme_color_override("font_color", MUTED)
	root_ui.add_child(info)
	var back := _make_button("ロビーに戻る", Vector2(55, 430), Vector2(240, 52))
	back.pressed.connect(_show_lobby)
	root_ui.add_child(back)

func _start_training() -> void:
	in_training = true
	game_paused = false
	ammo = 30
	reserve_ammo = 180
	reloading = false
	health = 100
	targets_remaining = 8
	mission_time = 240.0
	mission_complete = false
	mission_failed = false
	score = 0
	kill_streak = 0
	best_streak = 0
	damage_flash_left = 0.0
	target_nodes.clear()
	objective_nodes.clear()
	flight_mode = false
	_clear_ui()
	_build_training_world()
	_add_training_overlay()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	mouse_captured = false

func _build_training_world() -> void:
	world = Node3D.new()
	world.name = "TrainingWorld"
	add_child(world)
	var environment_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#243c50")
	sky_material.sky_horizon_color = Color("#b5b9b1")
	sky_material.ground_bottom_color = Color("#303a3d")
	sky_material.ground_horizon_color = Color("#929b97")
	sky_material.sun_angle_max = 18.0
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.65
	env.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.08
	env.glow_enabled = false # Low-memory preset: avoids an extra full-screen post-process buffer.
	env.glow_intensity = 0.45
	env.glow_strength = 0.8
	env.glow_bloom = 0.08
	env.fog_enabled = true
	env.fog_light_color = Color("#a6b0b0")
	env.fog_density = 0.006
	env.fog_sky_affect = 0.35
	environment_node.environment = env
	world.add_child(environment_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, -28, 0)
	sun.light_color = Color("#ffe3bf")
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 65.0 # Keep shadow rendering affordable on 8 GB systems.
	world.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-18, 145, 0)
	fill.light_color = Color("#9ecbff")
	fill.light_energy = 0.22
	fill.shadow_enabled = false
	world.add_child(fill)

	_build_large_map()

	player = CharacterBody3D.new()
	player.name = "Player"
	player.floor_snap_length = 0.25
	world.add_child(player)
	player_collision = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.36
	capsule.height = 1.8
	player_collision.shape = capsule
	player_collision.position.y = 0.9
	player.add_child(player_collision)
	camera = Camera3D.new()
	camera.position = Vector3(0, 1.62, 0)
	camera.fov = 82.0
	camera.current = true
	camera.near = 0.05
	camera.far = 1200.0
	player.add_child(camera)
	player.position = Vector3(0, _terrain_height(0.0, 420.0) + 0.62, 420.0)
	look_yaw = 0.0
	look_pitch = 0.0
	previous_player_position = player.position
	_build_weapon()


func _terrain_height(x: float, z: float) -> float:
	# Multi-scale terrain: broad landforms, rolling hills, erosion-like cuts and rocky ridges.
	var radial := sqrt(x * x + z * z)
	var mountain := maxf(0.0, 1.0 - radial / 330.0)
	var broad_noise := sin(x * 0.008 + sin(z * 0.006)) * cos(z * 0.009) * 5.0
	var rolling := sin(x * 0.023 + z * 0.012) * cos(z * 0.019 - x * 0.007) * 2.4
	var fine_noise := sin(x * 0.071 + z * 0.039) * cos(z * 0.063 - x * 0.045) * 0.7
	var ridges := absf(sin(x * 0.014 + z * 0.011)) * 4.0
	var height := 4.0 + broad_noise + rolling + fine_noise
	height += mountain * mountain * (112.0 + ridges + sin(x * 0.031) * cos(z * 0.027) * 13.0)
	# Low, gently undulating north-south corridor for the highway and tunnel approaches.
	var corridor := exp(-pow(absf(x) / 25.0, 2.0))
	height = lerpf(height, 25.0 + sin(z * 0.012) * 1.8 + broad_noise * 0.25, corridor * mountain)
	return height

func _build_large_map() -> void:
	# 1 km x 1 km terrain with multi-scale elevation, vertex-colour biomes and fine procedural surface texture.
	var verts := PackedVector3Array()
	var indices := PackedInt32Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var resolution := 201 # ~26k terrain vertices instead of ~40k; still detailed at normal play distance.
	var step := 5.0
	var surface_noise := FastNoiseLite.new()
	surface_noise.seed = 7419
	surface_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	surface_noise.frequency = 0.035
	surface_noise.fractal_octaves = 4
	surface_noise.fractal_gain = 0.52
	for z_index in range(resolution):
		for x_index in range(resolution):
			var x := -500.0 + float(x_index) * step
			var z := -500.0 + float(z_index) * step
			var h := _terrain_height(x, z)
			verts.append(Vector3(x, h, z))
			uvs.append(Vector2((x + 500.0) / 18.0, (z + 500.0) / 18.0))
			var grain := surface_noise.get_noise_2d(x, z)
			var moisture := surface_noise.get_noise_2d(x + 1700.0, z - 900.0)
			var biome := Color("#526448")
			if h > 92.0:
				biome = Color("#686b64") if h < 124.0 else Color("#888980")
			elif h > 58.0:
				biome = Color("#686b55")
			elif moisture < -0.32:
				biome = Color("#756b50")
			elif moisture > 0.32:
				biome = Color("#405943")
			biome = biome * (0.88 + (grain + 1.0) * 0.10)
			colors.append(biome)
	for z_index in range(resolution - 1):
		for x_index in range(resolution - 1):
			var a := z_index * resolution + x_index
			var b := a + 1
			var c := a + resolution
			var d := c + 1
			indices.append_array(PackedInt32Array([a, c, b, b, c, d]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var terrain_mesh := ArrayMesh.new()
	terrain_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var terrain_material := _make_material(Color.WHITE, 1.0)
	terrain_material.vertex_color_use_as_albedo = true
	var detail_noise := FastNoiseLite.new()
	detail_noise.seed = 29031
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	detail_noise.frequency = 0.075
	detail_noise.fractal_octaves = 3
	var detail_texture := NoiseTexture2D.new()
	detail_texture.width = 512
	detail_texture.height = 512
	detail_texture.seamless = true
	detail_texture.noise = detail_noise
	var detail_ramp := Gradient.new()
	detail_ramp.set_color(0, Color("#858780"))
	detail_ramp.add_point(1.0, Color("#ffffff"))
	detail_texture.color_ramp = detail_ramp
	terrain_material.albedo_texture = detail_texture
	terrain_material.roughness = 1.0
	terrain_material.roughness_texture = detail_texture
	terrain_mesh.surface_set_material(0, terrain_material)
	var terrain_instance := MeshInstance3D.new()
	terrain_instance.name = "1km_Terrain"
	terrain_instance.mesh = terrain_mesh
	terrain_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	world.add_child(terrain_instance)
	var terrain_body := StaticBody3D.new()
	terrain_body.name = "TerrainCollision"
	var terrain_collision := CollisionShape3D.new()
	terrain_collision.shape = terrain_mesh.create_trimesh_shape()
	terrain_body.add_child(terrain_collision)
	world.add_child(terrain_body)

	# Continuous fallback ground beneath the procedural terrain.
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(1000.0, 1000.0)
	var ground_visual := MeshInstance3D.new()
	ground_visual.name = "FallbackGroundVisual"
	ground_visual.mesh = ground_mesh
	ground_visual.position = Vector3(0.0, -2.0, 0.0)
	ground_visual.material_override = _make_material(Color("#4b5940"), 1.0)
	ground_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(ground_visual)
	var ground_body := StaticBody3D.new()
	ground_body.name = "FallbackGroundCollision"
	ground_body.position = Vector3(0.0, -2.6, 0.0)
	var ground_shape := CollisionShape3D.new()
	var ground_box := BoxShape3D.new()
	ground_box.size = Vector3(1000.0, 1.0, 1000.0)
	ground_shape.shape = ground_box
	ground_body.add_child(ground_shape)
	world.add_child(ground_body)

	# Highway and rural access road surfaces.
	for z in range(-495, 500, 10):
		var road_y := _terrain_height(0.0, float(z))
		_add_road(Vector3(0, road_y + 0.28, float(z)), Vector3(18, 0.35, 10.2), Color("#34393a"))
		_add_road(Vector3(0, road_y + 0.48, float(z)), Vector3(30, 0.08, 10.2), Color("#77776d"), true)
		_add_road(Vector3(0, road_y + 0.54, float(z)), Vector3(0.35, 0.06, 10.2), Color("#d2c9a3"), true)

	_add_base(Vector3(0, 0, 445), Color("#536c59"), "SOUTH / FRIENDLY")
	_add_base(Vector3(0, 0, -445), Color("#75604d"), "NORTH / HOSTILE")
	_add_road(Vector3(0, 28, 155), Vector3(22, 0.8, 250), Color("#3b4041"))
	for side in [-1.0, 1.0]:
		for z in range(55, 276, 35):
			var support := _make_box(Vector3(side * 9.0, 12.0, float(z)), Vector3(1.3, 24.0, 1.3), Color("#656b69"))
			world.add_child(support)
	_add_tunnel_portal(Vector3(0, 27, 145), false)
	_add_tunnel_portal(Vector3(0, 27, -145), true)
	_add_underground_facility(Vector3(24, 12, 0))
	_add_city_district(Vector3(-245, 0, 25), 7, 5, 19.0, Color("#777b78"))
	_add_city_district(Vector3(-280, 0, -215), 5, 4, 24.0, Color("#8b8174"))
	_add_urban_road_grid(Vector3(-245, 0, 25), 7, 5, 19.0)
	_add_urban_road_grid(Vector3(-280, 0, -215), 5, 4, 24.0)
	_add_factory(Vector3(250, 0, -245))
	_add_airport(Vector3(300, 0, 265))
	_add_farmland(Vector3(-285, 0, 285))
	_add_farmland(Vector3(-405, 0, 115))
	_add_roadside_infrastructure()
	_add_forest(Vector3(365, 0, 10), 8, 9, 15.0)
	_add_forest(Vector3(375, 0, -345), 8, 8, 17.0)
	_add_forest(Vector3(-390, 0, -360), 7, 8, 16.0)
	_add_forest(Vector3(390, 0, 360), 7, 7, 16.0)
	_add_rural_compound(Vector3(185, 0, 360))
	_add_rural_compound(Vector3(-160, 0, -390))
	_add_objective_marker(Vector3(-75, _terrain_height(-75, 35), 35), "A")
	_add_objective_marker(Vector3(0, _terrain_height(0, -5), -5), "B")
	_add_objective_marker(Vector3(75, _terrain_height(75, 35), 35), "C")

func _add_ground_patch(center: Vector3, size: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.position = Vector3(center.x, center.y, center.z)
	visual.material_override = _make_material(color, 0.98)
	world.add_child(visual)

func _add_road(center: Vector3, size: Vector3, color: Color, visual_only: bool = false) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.position = center
	visual.material_override = _make_material(color, 0.92)
	world.add_child(visual)
	if not visual_only:
		var body := StaticBody3D.new()
		body.position = center
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		world.add_child(body)



func _add_roadside_infrastructure() -> void:
	# Edge-to-edge highway has shoulders and guardrails; the local city streets above
	# carry sidewalks, crosswalks, traffic signals, street lighting and utility lines.
	for z in range(-430, 431, 35):
		var y := _terrain_height(0.0, float(z))
		for side in [-1.0, 1.0]:
			world.add_child(_make_box(Vector3(side * 10.2, y + 0.9, float(z)), Vector3(0.22, 1.0, 34.0), Color("#858984")))
			world.add_child(_make_box(Vector3(side * 10.2, y + 1.45, float(z)), Vector3(0.12, 0.12, 34.0), Color("#a9aaa0")))
	# Highway lighting on the approaches; no pedestrian sidewalk is placed on the motorway.
	for z in range(-400, 401, 80):
		var y := _terrain_height(0.0, float(z))
		for side in [-1.0, 1.0]:
			var x: float = side * 17.0
			world.add_child(_make_box(Vector3(x, y + 4.0, float(z)), Vector3(0.3, 8.0, 0.3), Color("#555c5e")))
			world.add_child(_make_box(Vector3(x - side * 2.0, y + 8.0, float(z)), Vector3(4.0, 0.22, 0.22), Color("#555c5e")))
			var lamp := SphereMesh.new()
			lamp.radius = 0.25
			lamp.height = 0.5
			var lamp_instance := MeshInstance3D.new()
			lamp_instance.mesh = lamp
			lamp_instance.position = Vector3(x - side * 3.7, y + 7.8, float(z))
			lamp_instance.material_override = _make_material(Color("#e3d9a9"), 0.3, 0.0, Color("#c9bb82"))
			world.add_child(lamp_instance)

func _add_urban_road_grid(origin: Vector3, cols: int, rows: int, spacing: float) -> void:
	# Local streets are built in short terrain-following sections with curbs, sidewalks,
	# dashed lane markings, streetlights, intersections and overhead utility wires.
	var x_min := origin.x - float(cols - 1) * spacing * 0.5 - spacing * 0.5
	var x_max := origin.x + float(cols - 1) * spacing * 0.5 + spacing * 0.5
	var z_min := origin.z - float(rows - 1) * spacing * 0.5 - spacing * 0.5
	var z_max := origin.z + float(rows - 1) * spacing * 0.5 + spacing * 0.5
	var segment := 8.0
	# Streets running east-west between building rows.
	for row_index in range(rows + 1):
		var z := origin.z + (float(row_index) - float(rows - 1) * 0.5 - 0.5) * spacing
		for x_step in range(int(ceil((x_max - x_min) / segment))):
			var x := x_min + float(x_step) * segment
			var length := minf(segment, x_max - x)
			var y := _terrain_height(x + length * 0.5, z)
			_add_road(Vector3(x + length * 0.5, y + 0.12, z), Vector3(length, 0.22, 7.0), Color("#353a3b"))
			# Raised concrete curbs and pale sidewalk slabs on both sides.
			for side in [-1.0, 1.0]:
				_add_ground_patch(Vector3(x + length * 0.5, y + 0.18, z + side * 5.0), Vector3(length, 0.24, 2.6), Color("#aaa99e"))
				_add_ground_patch(Vector3(x + length * 0.5, y + 0.27, z + side * 3.65), Vector3(length, 0.32, 0.22), Color("#777b79"))
			# Broken white centre line, kept out of intersections.
			if int(floor((x - x_min) / 4.0)) % 3 == 0 and length > 2.5:
				_add_ground_patch(Vector3(x + length * 0.5, y + 0.245, z), Vector3(minf(2.8, length), 0.035, 0.13), Color("#e3e0d3"))
	# Streets running north-south.
	for col_index in range(cols + 1):
		var x := origin.x + (float(col_index) - float(cols - 1) * 0.5 - 0.5) * spacing
		for z_step in range(int(ceil((z_max - z_min) / segment))):
			var z := z_min + float(z_step) * segment
			var length := minf(segment, z_max - z)
			var y := _terrain_height(x, z + length * 0.5)
			_add_road(Vector3(x, y + 0.12, z + length * 0.5), Vector3(7.0, 0.22, length), Color("#353a3b"))
			for side in [-1.0, 1.0]:
				_add_ground_patch(Vector3(x + side * 5.0, y + 0.18, z + length * 0.5), Vector3(2.6, 0.24, length), Color("#aaa99e"))
				_add_ground_patch(Vector3(x + side * 3.65, y + 0.27, z + length * 0.5), Vector3(0.22, 0.32, length), Color("#777b79"))
			if int(floor((z - z_min) / 4.0)) % 3 == 0 and length > 2.5:
				_add_ground_patch(Vector3(x, y + 0.245, z + length * 0.5), Vector3(0.13, 0.035, minf(2.8, length)), Color("#e3e0d3"))
	# Zebra crossings and traffic signals at selected major junctions.
	for ix in range(1, cols, 3):
		for iz in range(1, rows, 2):
			var x := origin.x + (float(ix) - float(cols - 1) * 0.5) * spacing
			var z := origin.z + (float(iz) - float(rows - 1) * 0.5) * spacing
			var y := _terrain_height(x, z)
			for stripe in range(6):
				_add_ground_patch(Vector3(x - 2.5 + float(stripe), y + 0.27, z), Vector3(0.45, 0.04, 5.5), Color("#e0dfd5"))
			_add_traffic_signal(Vector3(x + 5.0, y, z + 5.0))
	# Utility poles with crossarms and sagged-looking overhead wire runs along residential streets.
	var pole_x := x_min - 5.0
	for pole_index in range(int(ceil((z_max - z_min) / 28.0)) + 1):
		var z := z_min + float(pole_index) * 28.0
		if z > z_max:
			break
		_add_utility_pole(Vector3(pole_x, _terrain_height(pole_x, z), z))
	for pole_index in range(int(ceil((z_max - z_min) / 28.0))):
		var z1 := z_min + float(pole_index) * 28.0
		var z2 := minf(z1 + 28.0, z_max)
		var mid_z := (z1 + z2) * 0.5
		var mid_y := (_terrain_height(pole_x, z1) + _terrain_height(pole_x, z2)) * 0.5 + 8.5
		var wire := MeshInstance3D.new()
		var wire_mesh := BoxMesh.new()
		wire_mesh.size = Vector3(0.055, 0.055, z2 - z1)
		wire.mesh = wire_mesh
		wire.position = Vector3(pole_x, mid_y - 0.4, mid_z)
		wire.material_override = _make_material(Color("#252a2b"), 0.7, 0.35)
		world.add_child(wire)

func _add_traffic_signal(pos: Vector3) -> void:
	# Compact roadside signal head with red, amber and green lenses.
	world.add_child(_make_box(pos + Vector3(0, 3.1, 0), Vector3(0.16, 6.2, 0.16), Color("#4c5252")))
	world.add_child(_make_box(pos + Vector3(-0.65, 6.0, 0), Vector3(1.4, 1.8, 0.7), Color("#24292b")))
	for i in range(3):
		var lens_color := Color("#d34b40") if i == 0 else (Color("#d5a84c") if i == 1 else Color("#5f9d68"))
		var lens := SphereMesh.new()
		lens.radius = 0.19
		lens.height = 0.38
		var lamp := MeshInstance3D.new()
		lamp.mesh = lens
		lamp.position = pos + Vector3(-0.65, 6.55 - float(i) * 0.55, 0.38)
		lamp.material_override = _make_material(lens_color, 0.35, 0.0, lens_color * 0.22)
		world.add_child(lamp)
	world.add_child(_make_box(pos + Vector3(-0.65, 4.8, 0.0), Vector3(1.4, 0.12, 0.7), Color("#343a3b")))

func _add_utility_pole(pos: Vector3) -> void:
	# Weathered concrete pole, crossarm, insulators and dark overhead cables.
	world.add_child(_make_box(pos + Vector3(0, 4.0, 0), Vector3(0.32, 8.0, 0.32), Color("#77786f")))
	world.add_child(_make_box(pos + Vector3(0, 7.3, 0), Vector3(2.2, 0.18, 0.22), Color("#625f56")))
	for offset in [-0.75, 0.0, 0.75]:
		var insulator := CylinderMesh.new()
		insulator.top_radius = 0.11
		insulator.bottom_radius = 0.14
		insulator.height = 0.3
		var instance := MeshInstance3D.new()
		instance.mesh = insulator
		instance.position = pos + Vector3(offset, 7.55, 0)
		instance.material_override = _make_material(Color("#a5a89e"), 0.55)
		world.add_child(instance)

func _add_base(center: Vector3, accent: Color, label_text: String) -> void:
	var ground_y := _terrain_height(center.x, center.z)
	_add_ground_patch(Vector3(center.x, ground_y + 0.18, center.z), Vector3(105, 0.36, 92), Color("#454b49"))
	for x in [-38.0, 38.0]:
		world.add_child(_make_box(Vector3(center.x + x, ground_y + 2.0, center.z), Vector3(1.1, 4.0, 82), Color("#50595a")))
	for i in range(7):
		var x := center.x - 30.0 + float(i) * 10.0
		world.add_child(_make_box(Vector3(x, ground_y + 2.0, center.z - 20.0), Vector3(7.5, 4.0, 10.0), accent))
		world.add_child(_make_box(Vector3(x, ground_y + 1.6, center.z + 15.0), Vector3(8.0, 3.2, 12.0), Color("#656c68")))
	_add_watchtower(Vector3(center.x - 42.0, ground_y, center.z - 35.0))
	_add_watchtower(Vector3(center.x + 42.0, ground_y, center.z + 35.0))
	var sign := Label3D.new()
	sign.text = label_text
	sign.font_size = 48
	sign.position = Vector3(center.x, ground_y + 7.0, center.z - 43.0)
	sign.modulate = accent.lightened(0.4)
	world.add_child(sign)

func _add_tunnel_portal(pos: Vector3, north_end: bool) -> void:
	# Concrete portal frame and a dark tube. The terrain corridor is cut into the ridge around it.
	for x in [-11.0, 11.0]:
		world.add_child(_make_box(pos + Vector3(x, 5.5, 0), Vector3(2.0, 11.0, 2.2), Color("#656c6b")))
	world.add_child(_make_box(pos + Vector3(0, 11.0, 0), Vector3(24.0, 2.0, 2.2), Color("#777d79")))
	var tunnel_center_z := pos.z + (15.0 if north_end else -15.0)
	# Open-sided tunnel lining: roof and side walls leave a clear drivable passage.
	world.add_child(_make_box(Vector3(-8.8, 31.7, tunnel_center_z), Vector3(0.8, 9.0, 260.0), Color("#353d40")))
	world.add_child(_make_box(Vector3(8.8, 31.7, tunnel_center_z), Vector3(0.8, 9.0, 260.0), Color("#353d40")))
	world.add_child(_make_box(Vector3(0, 36.2, tunnel_center_z), Vector3(18.0, 0.8, 260.0), Color("#292f32")))
	for offset in range(-120, 121, 20):
		world.add_child(_make_box(Vector3(0, 35.7, tunnel_center_z + float(offset)), Vector3(18.0, 0.35, 0.35), Color("#4b5150")))

func _add_underground_facility(pos: Vector3) -> void:
	# Side entrance midway through the tunnel, with an illuminated descent into the bunker.
	world.add_child(_make_box(pos + Vector3(0, -2.0, 0), Vector3(24, 1.0, 26), Color("#292f31")))
	world.add_child(_make_box(pos + Vector3(0, 2.0, 0), Vector3(22, 1.0, 24), Color("#343b3d")))
	world.add_child(_make_box(pos + Vector3(0, 0, -12.0), Vector3(22, 4.0, 1.0), Color("#444b4c")))
	world.add_child(_make_box(pos + Vector3(0, 0, 12.0), Vector3(22, 4.0, 1.0), Color("#444b4c")))
	world.add_child(_make_box(pos + Vector3(-10.5, 0, 0), Vector3(1.0, 4.0, 24), Color("#444b4c")))
	world.add_child(_make_box(pos + Vector3(10.5, 0, 0), Vector3(1.0, 4.0, 24), Color("#444b4c")))
	world.add_child(_make_box(pos + Vector3(0, 1.2, -11.0), Vector3(8.0, 2.4, 0.3), Color("#172126")))
	for i in range(6):
		world.add_child(_make_box(pos + Vector3(-5.0 + float(i) * 2.0, 2.2, -10.7), Vector3(0.12, 2.0, 0.12), Color("#b7d6c7")))
	_add_road(pos + Vector3(0, -0.6, 0), Vector3(10, 0.25, 22), Color("#3d4648"))

func _add_city_district(origin: Vector3, cols: int, rows: int, spacing: float, base_color: Color) -> void:
	for z_index in range(rows):
		for x_index in range(cols):
			var x := origin.x + (float(x_index) - float(cols - 1) * 0.5) * spacing
			var z := origin.z + (float(z_index) - float(rows - 1) * 0.5) * spacing
			var h := 12.0 + float((x_index * 7 + z_index * 11) % 6) * 5.0
			var w := 12.0 + float((x_index + z_index) % 3) * 2.0
			var color := base_color.darkened(float((x_index + z_index) % 4) * 0.045)
			var building := _make_box(Vector3(x, _terrain_height(x, z) + h * 0.5, z), Vector3(w, h, w), color, 0.9)
			world.add_child(building)
			# Recessed dark window bands on the street-facing facade.
			for floor_index in range(1, int(h / 4.0)):
				var windows := MeshInstance3D.new()
				var mesh := BoxMesh.new()
				mesh.size = Vector3(w * 0.72, 0.65, 0.08)
				windows.mesh = mesh
				windows.position = Vector3(x, _terrain_height(x, z) + float(floor_index) * 3.7, z - w * 0.5 - 0.05)
				windows.material_override = _make_material(Color("#303c43"), 0.52, 0.08)
				world.add_child(windows)

func _add_factory(origin: Vector3) -> void:
	for i in range(5):
		var x := origin.x - 38.0 + float(i) * 19.0
		var z := origin.z + float(i % 2) * 23.0
		var y := _terrain_height(x, z)
		world.add_child(_make_box(Vector3(x, y + 7.0, z), Vector3(15, 14, 24), Color("#77766b")))
		world.add_child(_make_box(Vector3(x, y + 14.4, z), Vector3(16, 0.8, 25), Color("#434b4d")))
	for i in range(4):
		var x := origin.x + 48.0 + float(i) * 11.0
		var y := _terrain_height(x, origin.z)
		var tank := CylinderMesh.new()
		tank.top_radius = 5.0
		tank.bottom_radius = 5.0
		tank.height = 15.0
		var instance := MeshInstance3D.new()
		instance.mesh = tank
		instance.position = Vector3(x, y + 7.5, origin.z)
		instance.material_override = _make_material(Color("#8b8d83"), 0.5, 0.25)
		world.add_child(instance)
		world.add_child(_make_box(Vector3(x, y + 16.0, origin.z), Vector3(1.0, 2.0, 1.0), Color("#454b4b")))

func _add_airport(origin: Vector3) -> void:
	var y := _terrain_height(origin.x, origin.z)
	_add_ground_patch(Vector3(origin.x, y + 0.15, origin.z), Vector3(190, 0.3, 330), Color("#484e4d"))
	_add_road(Vector3(origin.x, y + 0.32, origin.z), Vector3(24, 0.12, 285), Color("#282e31"), true)
	for z_offset in [-132.0, 132.0]:
		for x_offset in [-10.0, 10.0]:
			_add_ground_patch(Vector3(origin.x + x_offset, y + 0.4, origin.z + z_offset), Vector3(0.45, 0.08, 4), Color("#dedbc6"))
	for i in range(3):
		var x := origin.x + 42.0 + float(i) * 28.0
		world.add_child(_make_box(Vector3(x, y + 7.0, origin.z - 75.0), Vector3(22, 14, 34), Color("#777e7c")))
		world.add_child(_make_box(Vector3(x, y + 14.2, origin.z - 75.0), Vector3(23, 0.6, 35), Color("#42494b")))
	for i in range(5):
		var x := origin.x - 72.0 + float(i) * 28.0
		_add_ground_patch(Vector3(x, y + 0.35, origin.z + 95.0), Vector3(0.4, 0.08, 18), Color("#e0d7a8"))

func _add_farmland(origin: Vector3) -> void:
	for i in range(5):
		var x := origin.x + float(i) * 25.0
		for j in range(4):
			var z := origin.z + float(j) * 32.0
			var field_color := Color("#6e7950") if (i + j) % 2 == 0 else Color("#89784e")
			_add_ground_patch(Vector3(x, _terrain_height(x, z) + 0.12, z), Vector3(22, 0.22, 28), field_color)
			for row in range(7):
				var row_z := z - 11.0 + float(row) * 3.2
				_add_ground_patch(Vector3(x, _terrain_height(x, row_z) + 0.25, row_z), Vector3(20, 0.08, 0.18), field_color.darkened(0.2))

func _add_forest(origin: Vector3, cols: int, rows: int, spacing: float) -> void:
	for z_index in range(rows):
		for x_index in range(cols):
			var x := origin.x + (float(x_index) - float(cols - 1) * 0.5) * spacing
			var z := origin.z + (float(z_index) - float(rows - 1) * 0.5) * spacing
			var y := _terrain_height(x, z)
			var trunk := CylinderMesh.new()
			trunk.top_radius = 0.5
			trunk.bottom_radius = 0.8
			trunk.height = 7.0 + float((x_index + z_index) % 4)
			var trunk_instance := MeshInstance3D.new()
			trunk_instance.mesh = trunk
			trunk_instance.position = Vector3(x, y + trunk.height * 0.5, z)
			trunk_instance.material_override = _make_material(Color("#4b3e30"), 0.95)
			world.add_child(trunk_instance)
			var crown := SphereMesh.new()
			crown.radius = 4.2 + float((x_index * 3 + z_index) % 3)
			crown.height = crown.radius * 2.2
			var crown_instance := MeshInstance3D.new()
			crown_instance.mesh = crown
			crown_instance.position = Vector3(x, y + 8.0 + crown.radius * 0.55, z)
			crown_instance.material_override = _make_material(Color("#344b35").darkened(float((x_index + z_index) % 4) * 0.08), 0.96)
			world.add_child(crown_instance)

func _add_rural_compound(origin: Vector3) -> void:
	var y := _terrain_height(origin.x, origin.z)
	for x_offset in [-12.0, 12.0]:
		world.add_child(_make_box(Vector3(origin.x + x_offset, y + 3.0, origin.z), Vector3(18, 6, 16), Color("#89877b")))
	world.add_child(_make_box(Vector3(origin.x, y + 0.15, origin.z + 15), Vector3(48, 0.3, 38), Color("#6b6858")))

func _make_material(color: Color, roughness: float = 0.82, metallic: float = 0.0, emission: Color = Color.BLACK) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	if emission != Color.BLACK:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = 1.5
	return material

func _make_box(box_position: Vector3, box_size: Vector3, color: Color, roughness: float = 0.85) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = box_position
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box_size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _make_material(color, roughness)
	body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box_size
	collision.shape = shape
	body.add_child(collision)
	return body

func _add_visual(parent: Node3D, mesh: Mesh, local_position: Vector3, color: Color, roughness: float = 0.72, metallic: float = 0.0) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = local_position
	instance.material_override = _make_material(color, roughness, metallic)
	parent.add_child(instance)
	return instance

func _add_watchtower(pos: Vector3) -> void:
	var tower := Node3D.new()
	tower.position = pos
	world.add_child(tower)
	tower.add_child(_make_box(Vector3(0, 2.4, 0), Vector3(3.8, 0.25, 3.8), Color("#343f43")))
	for x in [-1.6, 1.6]:
		for z in [-1.6, 1.6]:
			tower.add_child(_make_box(Vector3(x, 1.2, z), Vector3(0.18, 2.4, 0.18), Color("#29353a")))
	tower.add_child(_make_box(Vector3(0, 4.1, 0), Vector3(4.0, 1.1, 4.0), Color("#4a5558")))
	tower.add_child(_make_box(Vector3(0, 4.8, 0), Vector3(4.4, 0.15, 4.4), Color("#29353a")))

func _add_container(pos: Vector3, size: Vector3, color: Color) -> void:
	world.add_child(_make_box(pos + Vector3(0, size.y / 2.0, 0), size, color, 0.8))
	for i in range(9):
		var x := -size.x * 0.45 + float(i) * size.x * 0.1125
		world.add_child(_make_box(pos + Vector3(x, size.y / 2.0, -size.z / 2.0 - 0.035), Vector3(0.07, size.y * 0.92, 0.06), color.lightened(0.12), 0.72))

func _add_barricade(pos: Vector3) -> void:
	world.add_child(_make_box(pos + Vector3(0, 0.55, 0), Vector3(3.6, 1.1, 0.55), Color("#8a806b")))
	world.add_child(_make_box(pos + Vector3(-1.25, 0.85, 0), Vector3(0.3, 1.7, 0.8), Color("#6f6c5f")))
	world.add_child(_make_box(pos + Vector3(1.25, 0.85, 0), Vector3(0.3, 1.7, 0.8), Color("#6f6c5f")))

func _add_pallet(pos: Vector3) -> void:
	for i in range(5):
		world.add_child(_make_box(pos + Vector3(0, 0.18, -0.6 + float(i) * 0.3), Vector3(1.8, 0.12, 0.22), Color("#75614a")))
	for x in [-0.62, 0.0, 0.62]:
		world.add_child(_make_box(pos + Vector3(x, 0.08, 0), Vector3(0.18, 0.16, 1.55), Color("#554839")))

func _add_lamp(pos: Vector3) -> void:
	world.add_child(_make_box(pos + Vector3(0, 2.5, 0), Vector3(0.12, 5.0, 0.12), Color("#29353a")))
	var head := _make_box(pos + Vector3(0, 5.05, 0), Vector3(0.75, 0.18, 0.42), Color("#c4d4d0"), 0.35)
	world.add_child(head)
	var lamp_light := OmniLight3D.new()
	lamp_light.position = pos + Vector3(0, 4.85, 0)
	lamp_light.light_color = Color("#b8dcff")
	lamp_light.light_energy = 1.1
	lamp_light.omni_range = 9.0
	lamp_light.shadow_enabled = false
	world.add_child(lamp_light)

func _add_objective_marker(pos: Vector3, label_text: String) -> void:
	var marker := Node3D.new()
	marker.position = pos
	world.add_child(marker)
	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.55
	ring_mesh.outer_radius = 0.64
	ring.mesh = ring_mesh
	ring.position.y = 0.08
	ring.material_override = _make_material(Color("#72d8c3"), 0.35, 0.15, Color("#3ab99d"))
	marker.add_child(ring)
	var beacon_light := OmniLight3D.new()
	beacon_light.position.y = 1.2
	beacon_light.light_color = Color("#45e3bf")
	beacon_light.light_energy = 0.8
	beacon_light.omni_range = 4.5
	marker.add_child(beacon_light)
	var beam := MeshInstance3D.new()
	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = 0.025
	beam_mesh.bottom_radius = 0.025
	beam_mesh.height = 2.5
	beam.mesh = beam_mesh
	beam.position.y = 1.25
	beam.material_override = _make_material(Color("#72d8c3"), 0.4, 0.0, Color("#3ab99d"))
	marker.add_child(beam)
	var label := Label3D.new()
	label.text = "OBJECTIVE " + label_text
	label.position.y = 2.8
	label.font_size = 32
	label.modulate = Color("#a9f2df")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.add_child(label)
	objective_nodes.append(marker)

func _build_weapon() -> void:
	weapon_root = Node3D.new()
	weapon_root.name = "FirstPersonCarbine"
	weapon_root.position = Vector3(0.29, -0.28, -0.48)
	camera.add_child(weapon_root)

	# Original, realistic-looking modern carbine silhouette. This is a game prop,
	# assembled from detailed meshes rather than a single blocky receiver.
	var polymer := Color("#202729")
	var metal := Color("#343c40")
	var dark_metal := Color("#111719")
	var rail_color := Color("#596164")
	var grip_color := Color("#303a36")
	var rubber := Color("#111414")

	# Receiver and upper rail.
	_add_weapon_box(Vector3(0, 0.005, -0.02), Vector3(0.145, 0.105, 0.34), metal)
	_add_weapon_box(Vector3(0, 0.055, -0.035), Vector3(0.105, 0.035, 0.40), dark_metal)
	_add_weapon_box(Vector3(0, -0.045, 0.055), Vector3(0.13, 0.075, 0.22), polymer)
	_add_weapon_box(Vector3(0, 0.078, -0.13), Vector3(0.075, 0.018, 0.56), rail_color)

	# Long handguard with side panels and repeated rail slots.
	_add_weapon_box(Vector3(0, 0.005, -0.35), Vector3(0.12, 0.105, 0.38), polymer)
	_add_weapon_box(Vector3(-0.066, 0.005, -0.35), Vector3(0.014, 0.055, 0.31), rail_color)
	_add_weapon_box(Vector3(0.066, 0.005, -0.35), Vector3(0.014, 0.055, 0.31), rail_color)
	for i in range(7):
		var slot_z := -0.22 - float(i) * 0.041
		_add_weapon_box(Vector3(-0.074, 0.005, slot_z), Vector3(0.009, 0.018, 0.022), dark_metal)
		_add_weapon_box(Vector3(0.074, 0.005, slot_z), Vector3(0.009, 0.018, 0.022), dark_metal)

	# Barrel, gas block and a compact muzzle device.
	_add_weapon_cylinder(Vector3(0, 0.006, -0.67), 0.022, 0.43, dark_metal)
	_add_weapon_box(Vector3(0, 0.005, -0.51), Vector3(0.07, 0.065, 0.075), metal)
	_add_weapon_cylinder(Vector3(0, 0.006, -0.91), 0.032, 0.12, metal)
	_add_weapon_cylinder(Vector3(0, 0.006, -0.978), 0.027, 0.025, rubber)
	_add_weapon_cylinder(Vector3(0, 0.006, -0.994), 0.012, 0.006, Color("#050606"))

	# Low-profile optic with glass-like front lens and protective hood.
	_add_weapon_box(Vector3(0, 0.112, -0.12), Vector3(0.075, 0.025, 0.13), dark_metal)
	_add_weapon_cylinder(Vector3(0, 0.148, -0.12), 0.036, 0.115, dark_metal, Vector3(PI / 2.0, 0, 0))
	_add_weapon_cylinder(Vector3(0, 0.148, -0.181), 0.025, 0.006, Color("#49676b"), Vector3(PI / 2.0, 0, 0))
	_add_weapon_box(Vector3(0, 0.095, -0.12), Vector3(0.055, 0.012, 0.09), metal)

	# Angled pistol grip, trigger guard and trigger.
	_add_weapon_box(Vector3(0, -0.125, 0.055), Vector3(0.085, 0.18, 0.095), grip_color, 0.9, Vector3(-0.22, 0, 0))
	_add_weapon_box(Vector3(0, -0.09, 0.005), Vector3(0.09, 0.018, 0.09), dark_metal)
	_add_weapon_box(Vector3(0, -0.102, -0.018), Vector3(0.012, 0.045, 0.014), rail_color)

	# Curved-looking tapered magazine: segmented surfaces give it more depth.
	_add_weapon_box(Vector3(0, -0.19, 0.015), Vector3(0.092, 0.105, 0.105), dark_metal)
	_add_weapon_box(Vector3(0, -0.255, 0.04), Vector3(0.078, 0.085, 0.092), polymer, 0.9, Vector3(-0.12, 0, 0))
	for i in range(4):
		_add_weapon_box(Vector3(0, -0.22 - float(i) * 0.017, 0.067), Vector3(0.081, 0.004, 0.006), rail_color)

	# Adjustable shoulder stock and rubber buttpad.
	_add_weapon_box(Vector3(0, 0.005, 0.22), Vector3(0.12, 0.09, 0.22), polymer)
	_add_weapon_box(Vector3(0, 0.005, 0.335), Vector3(0.135, 0.115, 0.035), rubber)
	_add_weapon_box(Vector3(0, 0.018, 0.27), Vector3(0.075, 0.025, 0.18), metal)
	_add_weapon_box(Vector3(0, 0.06, 0.18), Vector3(0.045, 0.025, 0.08), dark_metal)

	# First-person sleeves and gloves, with the support hand reaching the handguard.
	_add_weapon_box(Vector3(-0.19, -0.24, -0.19), Vector3(0.17, 0.19, 0.29), Color("#46544e"), 0.92, Vector3(0.08, 0.05, -0.12))
	_add_weapon_box(Vector3(-0.105, -0.14, -0.37), Vector3(0.12, 0.085, 0.15), Color("#77786b"), 0.95, Vector3(-0.12, 0.02, -0.08))
	_add_weapon_box(Vector3(0.16, -0.23, 0.08), Vector3(0.15, 0.21, 0.24), Color("#46544e"), 0.92)
	_add_weapon_box(Vector3(0.085, -0.14, -0.005), Vector3(0.105, 0.10, 0.12), Color("#77786b"), 0.95)

func _add_weapon_box(pos: Vector3, size: Vector3, color: Color, roughness: float = 0.65, rotation: Vector3 = Vector3.ZERO) -> void:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = pos
	instance.rotation = rotation
	instance.material_override = _make_material(color, roughness, 0.18)
	weapon_root.add_child(instance)

func _add_weapon_cylinder(pos: Vector3, radius: float, height: float, color: Color, rotation: Vector3 = Vector3(PI / 2.0, 0, 0)) -> void:
	var instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	instance.mesh = mesh
	instance.position = pos
	instance.rotation = rotation
	instance.material_override = _make_material(color, 0.38, 0.48)
	weapon_root.add_child(instance)

func _spawn_training_targets() -> void:
	var positions := [Vector3(-34, 0, 385), Vector3(-10, 0, 390), Vector3(14, 0, 382), Vector3(36, 0, 400), Vector3(-28, 0, 445), Vector3(8, 0, 448), Vector3(31, 0, 430), Vector3(0, 0, 365)]
	for i in range(positions.size()):
		var target := _make_soldier_target(i + 1)
		target.position = positions[i]
		target.position.y = _terrain_height(target.position.x, target.position.z) + 0.35
		world.add_child(target)
		target_nodes.append(target)

func _make_soldier_target(number: int) -> Node3D:
	var soldier := Node3D.new()
	soldier.name = "TrainingSoldier_%02d" % number
	var body := StaticBody3D.new()
	body.name = "HitBody"
	body.add_to_group("training_target")
	body.set_meta("health", 100)
	body.set_meta("root_target", soldier)
	body.set_meta("is_enemy", true)
	soldier.set_meta("attack_cooldown", 1.4 + float(number % 3) * 0.55)
	soldier.add_child(body)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.36
	capsule.height = 1.75
	collision.shape = capsule
	collision.position.y = 0.92
	body.add_child(collision)
	var uniform := _make_material(Color("#35453d"), 0.9)
	var vest := _make_material(Color("#202a27"), 0.8)
	var helmet := _make_material(Color("#27332f"), 0.72)
	var skin := _make_material(Color("#b48b70"), 0.85)
	var boots := _make_material(Color("#171d1b"), 0.9)
	_add_soldier_part(body, BoxMesh.new(), Vector3(0, 1.13, 0), Vector3(0.64, 0.68, 0.34), uniform)
	_add_soldier_part(body, BoxMesh.new(), Vector3(0, 1.17, -0.195), Vector3(0.51, 0.48, 0.12), vest)
	_add_soldier_part(body, BoxMesh.new(), Vector3(0, 1.27, -0.27), Vector3(0.32, 0.08, 0.045), _make_material(Color("#56655a")))
	_add_soldier_part(body, SphereMesh.new(), Vector3(0, 1.72, 0), Vector3(0.27, 0.29, 0.25), skin)
	_add_soldier_part(body, SphereMesh.new(), Vector3(0, 1.84, 0), Vector3(0.31, 0.16, 0.29), helmet)
	_add_soldier_part(body, BoxMesh.new(), Vector3(0, 1.70, -0.13), Vector3(0.17, 0.055, 0.045), _make_material(Color("#3a4541")))
	_add_soldier_part(body, BoxMesh.new(), Vector3(-0.39, 1.17, -0.08), Vector3(0.19, 0.10, 0.20), _make_material(Color("#8e3434"), 0.65, 0.05))
	_add_soldier_part(body, BoxMesh.new(), Vector3(0, 1.92, -0.02), Vector3(0.24, 0.035, 0.12), _make_material(Color("#9c3c3c"), 0.5, 0.0))
	for side in [-1.0, 1.0]:
		_add_soldier_part(body, CapsuleMesh.new(), Vector3(side * 0.39, 1.13, 0), Vector3(0.16, 0.43, 0.16), uniform)
		_add_soldier_part(body, CapsuleMesh.new(), Vector3(side * 0.43, 0.65, 0.015), Vector3(0.19, 0.51, 0.19), uniform)
		_add_soldier_part(body, BoxMesh.new(), Vector3(side * 0.43, 0.12, -0.07), Vector3(0.23, 0.18, 0.34), boots)
		_add_soldier_part(body, BoxMesh.new(), Vector3(side * 0.39, 1.24, -0.17), Vector3(0.12, 0.18, 0.1), vest)
	# Chest rig pouches and radio silhouette.
	for i in range(3):
		_add_soldier_part(body, BoxMesh.new(), Vector3(-0.16 + float(i) * 0.16, 1.02, -0.27), Vector3(0.105, 0.13, 0.07), _make_material(Color("#4a5547")))
	_add_soldier_part(body, BoxMesh.new(), Vector3(0.22, 1.32, -0.23), Vector3(0.1, 0.2, 0.09), _make_material(Color("#171f1e")))
	# A low-poly training rifle across the front.
	_add_soldier_part(body, BoxMesh.new(), Vector3(0.08, 1.04, -0.36), Vector3(0.11, 0.10, 0.47), _make_material(Color("#161b1c"), 0.45, 0.2))
	_add_soldier_part(body, BoxMesh.new(), Vector3(0.08, 1.04, -0.64), Vector3(0.045, 0.045, 0.22), _make_material(Color("#0b1011"), 0.35, 0.35))
	return soldier

func _add_soldier_part(parent: Node3D, mesh: Mesh, pos: Vector3, size: Vector3, material: StandardMaterial3D) -> void:
	mesh = mesh.duplicate()
	if mesh is BoxMesh:
		(mesh as BoxMesh).size = size
	elif mesh is SphereMesh:
		(mesh as SphereMesh).radius = 0.5
		(mesh as SphereMesh).height = 1.0
	elif mesh is CapsuleMesh:
		(mesh as CapsuleMesh).radius = 0.5
		(mesh as CapsuleMesh).height = 1.0
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = pos
	instance.scale = size
	if mesh is BoxMesh:
		instance.scale = Vector3.ONE
	instance.material_override = material
	parent.add_child(instance)

func _add_training_overlay() -> void:
	var top := ColorRect.new()
	top.color = Color(0.025, 0.04, 0.055, 0.86)
	top.position = Vector2(0, 0)
	top.size = Vector2(1280, 54)
	root_ui.add_child(top)
	hud_label = Label.new()
	hud_label.text = "IRON VEIL  /  HOSTILE CONTACT"
	hud_label.position = Vector2(22, 14)
	hud_label.size = Vector2(600, 28)
	hud_label.add_theme_font_size_override("font_size", 15)
	hud_label.add_theme_color_override("font_color", TEXT)
	root_ui.add_child(hud_label)
	status_label = Label.new()
	status_label.text = "FREE ROAM  •  MAP DEVELOPMENT PHASE"
	status_label.position = Vector2(640, 14)
	status_label.size = Vector2(620, 28)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", ACCENT)
	root_ui.add_child(status_label)
	crosshair = Label.new()
	crosshair.text = "+"
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crosshair.add_theme_font_size_override("font_size", 28)
	crosshair.add_theme_color_override("font_color", Color("#e8f4f4"))
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-16, -24)
	crosshair.size = Vector2(32, 48)
	root_ui.add_child(crosshair)
	hitmarker = Label.new()
	hitmarker.text = "×"
	hitmarker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hitmarker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hitmarker.add_theme_font_size_override("font_size", 28)
	hitmarker.add_theme_color_override("font_color", Color.WHITE)
	hitmarker.modulate.a = 0.0
	hitmarker.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	hitmarker.position = Vector2(-18, -26)
	hitmarker.size = Vector2(36, 52)
	root_ui.add_child(hitmarker)
	var bottom := ColorRect.new()
	bottom.color = Color(0.025, 0.04, 0.055, 0.88)
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.position = Vector2(0, -68)
	bottom.size = Vector2(1280, 68)
	root_ui.add_child(bottom)
	ammo_label = Label.new()
	ammo_label.position = Vector2(980, 650)
	ammo_label.size = Vector2(270, 42)
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ammo_label.add_theme_font_size_override("font_size", 25)
	ammo_label.add_theme_color_override("font_color", TEXT)
	root_ui.add_child(ammo_label)
	score_label = Label.new()
	score_label.position = Vector2(22, 610)
	score_label.size = Vector2(380, 44)
	score_label.add_theme_font_size_override("font_size", 17)
	score_label.add_theme_color_override("font_color", ACCENT)
	root_ui.add_child(score_label)
	damage_overlay = ColorRect.new()
	damage_overlay.color = Color("#ff263f")
	damage_overlay.modulate.a = 0.0
	damage_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ui.add_child(damage_overlay)
	var controls := Label.new()
	controls.text = "WASD MOVE    F FLIGHT    SPACE UP    CTRL DOWN    SHIFT BOOST    ESC MENU"
	controls.position = Vector2(22, 674)
	controls.size = Vector2(900, 24)
	controls.add_theme_font_size_override("font_size", 12)
	controls.add_theme_color_override("font_color", MUTED)
	root_ui.add_child(controls)
	_update_hud()

func _update_hud() -> void:
	if is_instance_valid(hud_label):
		hud_label.text = "IRON VEIL  /  %03d HP" % health
	if is_instance_valid(ammo_label):
		ammo_label.text = "RELOADING" if reloading else "%02d  /  %03d" % [ammo, reserve_ammo]
		ammo_label.add_theme_color_override("font_color", RED if ammo <= 5 and not reloading else TEXT)
	if is_instance_valid(status_label):
		if mission_failed:
			status_label.text = "MISSION FAILED  •  PRESS ENTER TO RETRY"
			status_label.add_theme_color_override("font_color", RED)
		elif mission_complete:
			status_label.text = "SECTOR CLEARED  •  PRESS ENTER TO PLAY AGAIN"
			status_label.add_theme_color_override("font_color", GREEN)
		else:
			status_label.text = "HOSTILES  %d / 8    •    TIME  %03d" % [targets_remaining, int(ceil(mission_time))]
	if is_instance_valid(score_label):
		score_label.text = "SCORE  %07d   •   STREAK x%d   •   BEST x%d" % [score, kill_streak, best_streak]

func _return_to_lobby() -> void:
	in_training = false
	game_paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	mouse_captured = false
	if is_instance_valid(world):
		world.queue_free()
	world = null
	player = null
	camera = null
	weapon_root = null
	_show_lobby()

func _unhandled_input(event: InputEvent) -> void:
	if not in_training:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F:
			flight_mode = not flight_mode
			if is_instance_valid(player_collision):
				player_collision.disabled = flight_mode
			if flight_mode:
				player.velocity = Vector3.ZERO
				if is_instance_valid(status_label):
					status_label.text = "FLIGHT MODE ON  •  SPACE UP / CTRL DOWN"
			elif is_instance_valid(status_label):
				status_label.text = "FREE ROAM  •  MAP DEVELOPMENT PHASE"
		elif event.keycode == KEY_ESCAPE:
			if game_paused:
				_resume_training()
			else:
				game_paused = true
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				mouse_captured = false
				_show_pause_menu()
		elif event.keycode == KEY_R:
			_start_reload()
		elif event.keycode == KEY_ENTER and (mission_complete or mission_failed):
			_start_training()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not mouse_captured:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			mouse_captured = true
		else:
			_fire_weapon()
	elif event is InputEventMouseMotion and mouse_captured and is_instance_valid(camera):
		look_yaw -= event.relative.x * 0.0022
		look_pitch = clamp(look_pitch - event.relative.y * 0.0022, -1.25, 1.25)
		player.rotation.y = look_yaw
		camera.rotation.x = look_pitch

func _show_pause_menu() -> void:
	_clear_ui()
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.015, 0.025, 0.04, 0.94)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ui.add_child(backdrop)
	var title := Label.new()
	title.text = "MISSION PAUSED"
	title.position = Vector2(0, 180)
	title.size = Vector2(1280, 56)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", TEXT)
	root_ui.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "作戦は一時停止中です。再開するか、ロビーへ戻れます。"
	subtitle.position = Vector2(0, 242)
	subtitle.size = Vector2(1280, 34)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", MUTED)
	root_ui.add_child(subtitle)
	var resume_button := _make_button("作戦を再開", Vector2(450, 320), Vector2(380, 56))
	resume_button.pressed.connect(_resume_training)
	root_ui.add_child(resume_button)
	var lobby_button := _make_button("ロビーへ戻る", Vector2(450, 390), Vector2(380, 52))
	lobby_button.pressed.connect(_return_to_lobby)
	root_ui.add_child(lobby_button)

func _resume_training() -> void:
	game_paused = false
	_clear_ui()
	_add_training_overlay()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	mouse_captured = false

func _physics_process(delta: float) -> void:
	if not in_training or game_paused or not is_instance_valid(player):
		return
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	hitmarker_left = maxf(0.0, hitmarker_left - delta)
	weapon_kick = move_toward(weapon_kick, 0.0, delta * 2.8)
	if is_instance_valid(weapon_root):
		weapon_root.position = Vector3(0.29, -0.28 + weapon_kick * 0.04, -0.48 + weapon_kick * 0.12)
		if reloading:
			var reload_phase := 1.65 - reload_left
			weapon_root.position.y = -0.28 + sin(reload_phase * PI / 1.65) * 0.13
			weapon_root.rotation.z = 0.18
		else:
			weapon_root.rotation.z = 0.0
	if is_instance_valid(hitmarker):
		hitmarker.modulate.a = clampf(hitmarker_left * 5.0, 0.0, 1.0)
	if reloading:
		reload_left -= delta
		if reload_left <= 0.0:
			var needed := 30 - ammo
			var loaded := mini(needed, reserve_ammo)
			ammo += loaded
			reserve_ammo -= loaded
			reloading = false
	_update_hud()
	if not mission_complete and not mission_failed:
		mission_time = maxf(0.0, mission_time - delta)
		if mission_time <= 0.0:
			mission_failed = true
	_update_hud()
	# Physical-key fallback keeps movement usable even if project input mappings differ.
	var input_x := float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	var input_y := float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	var input_dir := Vector2(input_x, input_y)
	var sprinting := Input.is_key_pressed(KEY_SHIFT)
	if flight_mode:
		# Flight follows the camera's full direction and ignores terrain/building collision.
		var fly_direction := (-camera.global_transform.basis.z * input_dir.y) + (camera.global_transform.basis.x * input_dir.x)
		if Input.is_key_pressed(KEY_SPACE):
			fly_direction += Vector3.UP
		if Input.is_key_pressed(KEY_CTRL):
			fly_direction += Vector3.DOWN
		if fly_direction.length_squared() > 0.0001:
			fly_direction = fly_direction.normalized()
		var fly_speed := 65.0 if sprinting else 32.0
		player.global_position += fly_direction * fly_speed * delta
		player.velocity = Vector3.ZERO
	else:
		# Ground movement stays horizontal relative to the player's yaw.
		var move_basis := Basis(Vector3.UP, player.global_rotation.y)
		var direction := move_basis * Vector3(input_dir.x, 0.0, input_dir.y)
		direction.y = 0.0
		if direction.length_squared() > 0.0001:
			direction = direction.normalized()
		var speed := 7.0 if sprinting else 4.8
		player.velocity.x = direction.x * speed
		player.velocity.z = direction.z * speed
		if not player.is_on_floor():
			player.velocity.y -= 20.0 * delta
		else:
			player.velocity.y = -0.1
		player.move_and_slide()
	var moved := player.global_position.distance_to(previous_player_position)
	if moved > 0.001:
		move_bob += delta * (12.0 if sprinting else 8.0)
		if is_instance_valid(weapon_root):
			weapon_root.position.y += sin(move_bob) * 0.007
	previous_player_position = player.global_position

func _start_reload() -> void:
	if reloading or ammo >= 30 or reserve_ammo <= 0:
		return
	reloading = true
	reload_left = 1.65

func _fire_weapon() -> void:
	if not in_training or reloading or fire_cooldown > 0.0 or mission_complete or mission_failed:
		return
	if ammo <= 0:
		_start_reload()
		return
	ammo -= 1
	fire_cooldown = 0.105
	weapon_kick = 1.0
	# Small, controllable camera impulse gives automatic fire some weight.
	look_pitch = clampf(look_pitch - 0.012, -1.25, 1.25)
	if is_instance_valid(camera):
		camera.rotation.x = look_pitch
	if is_instance_valid(weapon_root):
		var flash := OmniLight3D.new()
		flash.light_color = Color("#ffca77")
		flash.light_energy = 2.2
		flash.omni_range = 3.5
		flash.position = Vector3(0, 0.006, -0.99)
		weapon_root.add_child(flash)
		var flash_tween := create_tween()
		flash_tween.tween_property(flash, "light_energy", 0.0, 0.055)
		flash_tween.tween_callback(flash.queue_free)
	var from := camera.global_position
	var to := from + (-camera.global_transform.basis.z * 100.0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [player]
	var result := player.get_world_3d().direct_space_state.intersect_ray(query)
	var tracer_end: Vector3 = result.get("position", to) if not result.is_empty() else from + (-camera.global_transform.basis.z * 38.0)
	if is_instance_valid(weapon_root):
		_spawn_tracer(weapon_root.to_global(Vector3(0, 0.006, -0.99)), tracer_end)
	if not result.is_empty():
		var collider := result.get("collider") as Node
		if collider is Node and collider.is_in_group("training_target"):
			var target_root := collider.get_meta("root_target") as Node3D
			var hit_position: Vector3 = result.get("position", to)
			var headshot := hit_position.y - target_root.global_position.y > 1.55
			var damage := 100 if headshot else 34
			var target_health: int = int(collider.get_meta("health")) - damage
			collider.set_meta("health", target_health)
			score += 25 if headshot else 10
			hitmarker.text = "✦" if headshot else "×"
			hitmarker.add_theme_color_override("font_color", Color("#ffd783") if headshot else Color.WHITE)
			hitmarker_left = 0.28
			_spawn_hit_effect(hit_position, headshot)
			if target_health <= 0:
				targets_remaining = maxi(0, targets_remaining - 1)
				target_nodes.erase(target_root)
				kill_streak += 1
				best_streak = maxi(best_streak, kill_streak)
				score += 250 + kill_streak * 50
				var death_tween := create_tween()
				death_tween.tween_property(target_root, "scale", Vector3(0.01, 0.01, 0.01), 0.16)
				death_tween.tween_callback(target_root.queue_free)
				if targets_remaining == 0:
					mission_complete = true
		else:
			kill_streak = 0
	_update_hud()

func _spawn_tracer(start: Vector3, finish: Vector3) -> void:
	# A brief emissive line makes each hitscan shot readable without a physics projectile.
	var travel := finish - start
	var distance := travel.length()
	if distance < 0.15:
		return
	var tracer := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.008
	mesh.bottom_radius = 0.008
	mesh.height = distance
	mesh.radial_segments = 6
	tracer.mesh = mesh
	tracer.position = (start + finish) * 0.5
	tracer.quaternion = Quaternion(Vector3.UP, travel.normalized())
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1.0, 0.78, 0.38, 0.92)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.48, 0.12)
	material.emission_energy_multiplier = 2.2
	tracer.material_override = material
	world.add_child(tracer)
	var fade := create_tween()
	fade.tween_property(material, "albedo_color:a", 0.0, 0.075)
	fade.tween_callback(tracer.queue_free)

func _spawn_hit_effect(position: Vector3, headshot: bool) -> void:
	var flash := OmniLight3D.new()
	flash.light_color = Color("#9fe6ff") if headshot else Color("#ffc078")
	flash.light_energy = 1.7 if headshot else 0.9
	flash.omni_range = 2.2
	flash.position = position
	world.add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "light_energy", 0.0, 0.12)
	tween.tween_callback(flash.queue_free)

func _spawn_enemy_flash(position: Vector3) -> void:
	var flash := OmniLight3D.new()
	flash.light_color = Color("#ff563e")
	flash.light_energy = 1.8
	flash.omni_range = 3.2
	flash.global_position = position
	world.add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "light_energy", 0.0, 0.09)
	tween.tween_callback(flash.queue_free)

func _damage_player(amount: int) -> void:
	if mission_complete or mission_failed:
		return
	health = maxi(0, health - amount)
	damage_flash_left = 0.48
	if health <= 0:
		mission_failed = true
	_update_hud()

func _process(delta: float) -> void:
	if not in_training or game_paused or not is_instance_valid(player):
		return
	damage_flash_left = maxf(0.0, damage_flash_left - delta)
	if is_instance_valid(damage_overlay):
		damage_overlay.modulate.a = clampf(damage_flash_left * 0.6, 0.0, 0.28)
	if mission_complete or mission_failed:
		return
	# AI is intentionally disabled during the map-first development phase.
	# Re-enable and implement target behavior only after the map and traversal are polished.
	for i in range(0):
		var target := target_nodes[i]
		if not is_instance_valid(target):
			continue
		var target_body := target.get_node_or_null("HitBody") as StaticBody3D
		if not is_instance_valid(target_body):
			continue
		var to_player: Vector3 = player.global_position - target.global_position
		to_player.y = 0.0
		var distance := to_player.length()
		if distance > 0.01:
			target_body.rotation.y = atan2(-to_player.x, -to_player.z)
		if distance > 7.0:
			var move_step := minf(distance - 6.5, (1.15 + float(i % 3) * 0.18) * delta)
			target.global_position += to_player.normalized() * move_step
		var cooldown := float(target.get_meta("attack_cooldown", 1.0)) - delta
		if distance < 19.0 and cooldown <= 0.0:
			_spawn_enemy_flash(target.global_position + Vector3(0, 1.35, 0))
			_damage_player(4 + (i % 3) * 2)
			cooldown = 1.6 + float(i % 3) * 0.45
		target.set_meta("attack_cooldown", cooldown)
	_update_hud()

