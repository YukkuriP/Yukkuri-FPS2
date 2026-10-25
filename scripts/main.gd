extends Node

const BG := Color("#0b1119")
const PANEL := Color("#121d29")
const ACCENT := Color("#8bb8df")
const TEXT := Color("#edf3f8")
const MUTED := Color("#9aabba")

var ui_layer: CanvasLayer
var root_ui: Control
var in_training := false
var player: CharacterBody3D
var camera: Camera3D
var look_yaw := 0.0
var look_pitch := 0.0
var mouse_captured := false

func _ready() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	root_ui = Control.new()
	root_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
	var title := Label.new()
	title.text = "OPERATION: IRON VEIL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", MUTED)
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	title.position = Vector2(-300, -80)
	title.size = Vector2(600, 40)
	root_ui.add_child(title)
	var credit := Label.new()
	credit.text = "ゆっくりP製作"
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credit.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	credit.add_theme_font_size_override("font_size", 42)
	credit.add_theme_color_override("font_color", TEXT)
	credit.modulate.a = 0.0
	credit.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	credit.position = Vector2(-300, -25)
	credit.size = Vector2(600, 70)
	root_ui.add_child(credit)
	var subtitle := Label.new()
	subtitle.text = "INITIALIZING"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", ACCENT)
	subtitle.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	subtitle.position = Vector2(-150, 55)
	subtitle.size = Vector2(300, 24)
	root_ui.add_child(subtitle)
	var tween := create_tween()
	tween.tween_property(credit, "modulate:a", 1.0, 0.8)
	tween.tween_interval(1.3)
	tween.tween_property(credit, "modulate:a", 0.0, 0.7)
	tween.tween_callback(_show_lobby)

func _show_lobby() -> void:
	in_training = false
	_clear_ui()
	var backdrop := ColorRect.new()
	backdrop.color = BG
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ui.add_child(backdrop)
	var header := Label.new()
	header.text = "OPERATION: IRON VEIL"
	header.position = Vector2(48, 34)
	header.size = Vector2(650, 50)
	header.add_theme_font_size_override("font_size", 30)
	header.add_theme_color_override("font_color", TEXT)
	root_ui.add_child(header)
	var subtitle := Label.new()
	subtitle.text = "TACTICAL COMBAT SIMULATION  /  PROTOTYPE"
	subtitle.position = Vector2(50, 82)
	subtitle.size = Vector2(650, 26)
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", ACCENT)
	root_ui.add_child(subtitle)
	var line := ColorRect.new()
	line.color = ACCENT
	line.position = Vector2(50, 125)
	line.size = Vector2(4, 420)
	root_ui.add_child(line)
	var welcome := Label.new()
	welcome.text = "ロビー"
	welcome.position = Vector2(78, 150)
	welcome.size = Vector2(420, 54)
	welcome.add_theme_font_size_override("font_size", 32)
	welcome.add_theme_color_override("font_color", TEXT)
	root_ui.add_child(welcome)
	var description := Label.new()
	description.text = "CoDのテンポ、Battlefieldの拠点戦、Arma 3の戦術性を目指す\n軽量3D FPSプロジェクト。これは初期プロトタイプです。"
	description.position = Vector2(80, 210)
	description.size = Vector2(560, 70)
	description.add_theme_font_size_override("font_size", 16)
	description.add_theme_color_override("font_color", MUTED)
	root_ui.add_child(description)
	var start_button := _make_button("訓練エリアに入る", Vector2(80, 320), Vector2(300, 58))
	start_button.pressed.connect(_start_training)
	root_ui.add_child(start_button)
	var settings_button := _make_button("操作・設定", Vector2(80, 392), Vector2(300, 50))
	settings_button.pressed.connect(_show_settings)
	root_ui.add_child(settings_button)
	var version := Label.new()
	version.text = "YUKKURI P PRODUCTION  •  DEV BUILD 0.1"
	version.position = Vector2(50, 650)
	version.size = Vector2(600, 28)
	version.add_theme_font_size_override("font_size", 12)
	version.add_theme_color_override("font_color", MUTED)
	root_ui.add_child(version)
	var status := Label.new()
	status.text = "OFFLINE PROTOTYPE\nOnline multiplayer: not implemented"
	status.position = Vector2(820, 570)
	status.size = Vector2(390, 65)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status.add_theme_font_size_override("font_size", 14)
	status.add_theme_color_override("font_color", ACCENT)
	root_ui.add_child(status)

func _make_button(label_text: String, button_position: Vector2, button_size: Vector2) -> Button:
	var button := Button.new()
	button.text = label_text
	button.position = button_position
	button.size = button_size
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _button_style(PANEL, ACCENT))
	button.add_theme_stylebox_override("hover", _button_style(Color("#1c3042"), ACCENT))
	button.add_theme_stylebox_override("pressed", _button_style(Color("#263d50"), TEXT))
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
	info.text = "移動：WASD / 矢印キー\n視点：マウス\n訓練中に Esc でカーソルを解放\n\nモバイル操作・オンライン対戦・保存設定は今後の実装予定です。"
	info.position = Vector2(55, 125)
	info.size = Vector2(650, 220)
	info.add_theme_font_size_override("font_size", 18)
	info.add_theme_color_override("font_color", MUTED)
	root_ui.add_child(info)
	var back := _make_button("ロビーに戻る", Vector2(55, 390), Vector2(240, 52))
	back.pressed.connect(_show_lobby)
	root_ui.add_child(back)

func _start_training() -> void:
	in_training = true
	_clear_ui()
	_build_training_world()
	_add_training_overlay()

func _build_training_world() -> void:
	var world := Node3D.new()
	world.name = "TrainingWorld"
	add_child(world)
	var environment_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#8496a5")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#c2d0dc")
	env.ambient_light_energy = 0.7
	environment_node.environment = env
	world.add_child(environment_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.light_energy = 0.8
	world.add_child(sun)
	world.add_child(_make_box(Vector3(0, -0.5, 0), Vector3(34, 1, 34), Color("#414c53")))
	for i in range(8):
		var x := -12.0 + float(i) * 3.5
		world.add_child(_make_box(Vector3(x, 1.0, -10.0), Vector3(1.5, 2.0, 1.2), Color("#65727a")))
		world.add_child(_make_box(Vector3(x, 1.0, 8.0), Vector3(1.5, 2.0, 1.2), Color("#65727a")))
	world.add_child(_make_box(Vector3(-10, 1.2, 0), Vector3(2.0, 2.4, 5.0), Color("#56636b")))
	world.add_child(_make_box(Vector3(10, 1.2, -2), Vector3(2.0, 2.4, 5.0), Color("#56636b")))
	world.add_child(_make_box(Vector3(0, 0.8, 0), Vector3(4.0, 1.6, 2.0), Color("#737e83")))
	player = CharacterBody3D.new()
	player.name = "Player"
	world.add_child(player)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	player.add_child(collision)
	camera = Camera3D.new()
	camera.position = Vector3(0, 1.55, 0)
	camera.current = true
	player.add_child(camera)
	player.position = Vector3(0, 0, 13)
	look_yaw = 0.0
	look_pitch = 0.0

func _make_box(box_position: Vector3, box_size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = box_position
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box_size
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box_size
	collision.shape = shape
	body.add_child(collision)
	return body

func _add_training_overlay() -> void:
	var label := Label.new()
	label.text = "TRAINING AREA  •  WASD: MOVE  •  MOUSE: LOOK  •  ESC: MENU"
	label.position = Vector2(20, 18)
	label.size = Vector2(900, 32)
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color.WHITE)
	root_ui.add_child(label)
	var back := _make_button("ロビーへ戻る", Vector2(20, 60), Vector2(190, 44))
	back.pressed.connect(_return_to_lobby)
	root_ui.add_child(back)

func _return_to_lobby() -> void:
	in_training = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	mouse_captured = false
	var world := get_node_or_null("TrainingWorld")
	if world:
		world.queue_free()
	_show_lobby()

func _unhandled_input(event: InputEvent) -> void:
	if not in_training:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_return_to_lobby()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		mouse_captured = true
	elif event is InputEventMouseMotion and mouse_captured and camera:
		look_yaw -= event.relative.x * 0.0025
		look_pitch = clamp(look_pitch - event.relative.y * 0.0025, -1.35, 1.35)
		player.rotation.y = look_yaw
		camera.rotation.x = look_pitch

func _physics_process(delta: float) -> void:
	if not in_training or not is_instance_valid(player):
		return
	var input_dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	)
	var direction := (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	player.velocity.x = direction.x * 5.0
	player.velocity.z = direction.z * 5.0
	if not player.is_on_floor():
		player.velocity.y -= 18.0 * delta
	else:
		player.velocity.y = -0.1
	player.move_and_slide()
