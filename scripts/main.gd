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
	description.text = "敵兵が追跡・射撃してくる戦闘区域を突破せよ。\nヘッドショットと連続撃破でスコアを稼ぎ、4分以内に全員を制圧。"
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
	briefing.text = "01  /  SECTOR: GREYBOX\n      Hostile forces have occupied the yard\n\n02  /  OBJECTIVE\n      Eliminate 8 hostile operators\n\n03  /  THREAT\n      Enemies advance and return fire\n\n04  /  LOADOUT\n      5.56 mm carbine • 30 + 180 rounds"
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
	info.text = "移動：WASD / 矢印キー\nダッシュ：Shift\n射撃：左クリック\nリロード：R\n視点：マウス\nEsc：カーソル解放 / ロビーへ戻る\n\nこのビルドはオフライン戦闘の縦切り試作です。"
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
	env.glow_enabled = true
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
	sun.directional_shadow_max_distance = 65.0
	world.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-18, 145, 0)
	fill.light_color = Color("#9ecbff")
	fill.light_energy = 0.22
	fill.shadow_enabled = false
	world.add_child(fill)

	# Large concrete pad and tiled floor markings.
	world.add_child(_make_box(Vector3(0, -0.5, 0), Vector3(70, 1, 70), Color("#343d40"), 0.95))
	for i in range(15):
		var line_x := -28.0 + float(i) * 4.0
		world.add_child(_make_box(Vector3(line_x, 0.012, 0), Vector3(0.035, 0.02, 64), Color("#58625f"), 0.9))
	for i in range(15):
		var line_z := -28.0 + float(i) * 4.0
		world.add_child(_make_box(Vector3(0, 0.014, line_z), Vector3(64, 0.02, 0.035), Color("#58625f"), 0.9))

	# Perimeter walls, watch posts and industrial silhouettes.
	world.add_child(_make_box(Vector3(0, 2.0, -33), Vector3(68, 4, 0.8), Color("#4a5558")))
	world.add_child(_make_box(Vector3(0, 2.0, 33), Vector3(68, 4, 0.8), Color("#4a5558")))
	world.add_child(_make_box(Vector3(-33, 2.0, 0), Vector3(0.8, 4, 68), Color("#4a5558")))
	world.add_child(_make_box(Vector3(33, 2.0, 0), Vector3(0.8, 4, 68), Color("#4a5558")))
	for x in [-24.0, -12.0, 12.0, 24.0]:
		world.add_child(_make_box(Vector3(x, 2.8, -32.3), Vector3(0.18, 1.8, 0.18), Color("#252f33")))
		world.add_child(_make_box(Vector3(x, 2.8, 32.3), Vector3(0.18, 1.8, 0.18), Color("#252f33")))
	_add_watchtower(Vector3(-27, 0, -26))
	_add_watchtower(Vector3(27, 0, -26))
	_add_container(Vector3(-20, 0, -12), Vector3(8, 3.0, 3.0), Color("#455b5c"))
	_add_container(Vector3(21, 0, 9), Vector3(8, 3.0, 3.0), Color("#5c5144"))
	_add_container(Vector3(22, 0, -18), Vector3(4, 3.0, 7.0), Color("#46515b"))

	# Cover, barricades, pallets and concrete blocks.
	for i in range(6):
		var z := -14.0 + float(i) * 5.0
		world.add_child(_make_box(Vector3(-7.0, 0.75, z), Vector3(2.8, 1.5, 0.9), Color("#666d6b")))
		world.add_child(_make_box(Vector3(7.0, 0.75, z + 2.0), Vector3(2.8, 1.5, 0.9), Color("#666d6b")))
	_add_barricade(Vector3(-14, 0, 5))
	_add_barricade(Vector3(14, 0, -7))
	_add_pallet(Vector3(-17, 0, -5))
	_add_pallet(Vector3(17, 0, 15))
	_add_lamp(Vector3(-19, 0, 20))
	_add_lamp(Vector3(19, 0, -22))
	_add_objective_marker(Vector3(-15, 0, -16), "A")
	_add_objective_marker(Vector3(0, 0, -20), "B")
	_add_objective_marker(Vector3(15, 0, -13), "C")

	player = CharacterBody3D.new()
	player.name = "Player"
	player.floor_snap_length = 0.25
	world.add_child(player)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.36
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	player.add_child(collision)
	camera = Camera3D.new()
	camera.position = Vector3(0, 1.62, 0)
	camera.fov = 82.0
	camera.current = true
	camera.near = 0.05
	camera.far = 180.0
	player.add_child(camera)
	player.position = Vector3(0, 0, 25)
	look_yaw = 0.0
	look_pitch = 0.0
	previous_player_position = player.position
	_build_weapon()
	_spawn_training_targets()

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
	# Receiver, handguard, barrel, muzzle device, optic and magazine.
	_add_weapon_box(Vector3(0, 0, 0), Vector3(0.16, 0.15, 0.48), GUN)
	_add_weapon_box(Vector3(0, -0.015, -0.34), Vector3(0.13, 0.12, 0.32), Color("#30393a"))
	_add_weapon_box(Vector3(0, 0.005, -0.64), Vector3(0.055, 0.055, 0.35), Color("#151b1d"), 0.3)
	_add_weapon_box(Vector3(0, 0.005, -0.83), Vector3(0.09, 0.075, 0.09), Color("#101517"), 0.35)
	_add_weapon_box(Vector3(0, 0.12, -0.12), Vector3(0.09, 0.07, 0.14), Color("#151b1d"), 0.3)
	_add_weapon_box(Vector3(0, -0.16, 0.08), Vector3(0.11, 0.24, 0.16), Color("#202729"))
	_add_weapon_box(Vector3(0, -0.26, 0.04), Vector3(0.13, 0.09, 0.14), Color("#343d3d"))
	_add_weapon_box(Vector3(0, -0.02, 0.17), Vector3(0.15, 0.08, 0.28), Color("#252d2f"))
	_add_weapon_box(Vector3(0, 0.10, -0.12), Vector3(0.14, 0.045, 0.16), Color("#384548"), 0.3)
	# Stylized sleeves and gloved hands, visible in first-person.
	_add_weapon_box(Vector3(-0.19, -0.24, -0.20), Vector3(0.19, 0.22, 0.30), Color("#4d5b55"))
	_add_weapon_box(Vector3(-0.11, -0.14, -0.42), Vector3(0.13, 0.11, 0.15), Color("#77776a"))
	_add_weapon_box(Vector3(0.16, -0.23, 0.08), Vector3(0.17, 0.24, 0.27), Color("#4d5b55"))
	_add_weapon_box(Vector3(0.08, -0.14, -0.03), Vector3(0.12, 0.11, 0.13), Color("#77776a"))

func _add_weapon_box(pos: Vector3, size: Vector3, color: Color, roughness: float = 0.65) -> void:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = _make_material(color, roughness, 0.18)
	weapon_root.add_child(instance)

func _spawn_training_targets() -> void:
	var positions := [Vector3(-14, 0, -9), Vector3(-5, 0, -17), Vector3(5, 0, -15), Vector3(14, 0, -7), Vector3(0, 0, 1), Vector3(-23, 0, 8), Vector3(24, 0, -3), Vector3(8, 0, 20)]
	for i in range(positions.size()):
		var target := _make_soldier_target(i + 1)
		target.position = positions[i]
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
	status_label.text = "OBJECTIVE  •  ELIMINATE ALL TARGETS"
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
	controls.text = "WASD MOVE    SHIFT SPRINT    LMB FIRE    R RELOAD    ESC MENU    ENTER RETRY"
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
		if event.keycode == KEY_ESCAPE:
			if mouse_captured:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				mouse_captured = false
			else:
				_return_to_lobby()
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

func _physics_process(delta: float) -> void:
	if not in_training or not is_instance_valid(player):
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
	var input_dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	)
	# Move relative to the player's current yaw, never world-axis WASD.
	# Flatten the transformed vector so pitch/vertical components cannot skew movement.
	var move_basis := Basis(Vector3.UP, player.global_rotation.y)
	var direction := move_basis * Vector3(input_dir.x, 0.0, input_dir.y)
	direction.y = 0.0
	if direction.length_squared() > 0.0001:
		direction = direction.normalized()
	var sprinting := Input.is_key_pressed(KEY_SHIFT)
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
	if is_instance_valid(weapon_root):
		var flash := OmniLight3D.new()
		flash.light_color = Color("#ffca77")
		flash.light_energy = 2.2
		flash.omni_range = 3.5
		flash.position = Vector3(0, 0.02, -0.82)
		weapon_root.add_child(flash)
		var flash_tween := create_tween()
		flash_tween.tween_property(flash, "light_energy", 0.0, 0.055)
		flash_tween.tween_callback(flash.queue_free)
	var from := camera.global_position
	var to := from + (-camera.global_transform.basis.z * 100.0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [player]
	var result := player.get_world_3d().direct_space_state.intersect_ray(query)
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
	if not in_training or not is_instance_valid(player):
		return
	damage_flash_left = maxf(0.0, damage_flash_left - delta)
	if is_instance_valid(damage_overlay):
		damage_overlay.modulate.a = clampf(damage_flash_left * 0.6, 0.0, 0.28)
	if mission_complete or mission_failed:
		return
	# Enemies push toward the player, pause to fire, and turn to face the player.
	for i in range(target_nodes.size()):
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

