extends SceneTree

func _initialize() -> void:
	call_deferred("_run_smoke_test")

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

func _run_smoke_test() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("Could not load the main scene.")
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	main.call("_start_training")
	await process_frame

	var world := main.get("world") as Node3D
	if world == null:
		_fail("Training world was not created.")
		return
	var terrain := world.get_node_or_null("1km_Terrain") as MeshInstance3D
	if terrain == null or terrain.mesh == null:
		_fail("The 1 km terrain mesh is missing.")
		return
	var terrain_bounds := terrain.mesh.get_aabb()
	if terrain_bounds.size.x < 999.0 or terrain_bounds.size.z < 999.0:
		_fail("Terrain bounds are smaller than 1 km × 1 km: %s" % terrain_bounds.size)
		return

	var soldiers := 0
	var target_bodies := 0
	for child in world.get_children():
		if child.name.begins_with("TrainingSoldier_"):
			soldiers += 1
			if String(child.get_meta("ai_state", "")) != "patrol":
				_fail("A hostile soldier did not start in patrol state.")
				return
		if child is Node and child.is_in_group("training_target"):
			target_bodies += 1
	if soldiers != 8 or target_bodies != 8:
		_fail("Expected 8 human patrols and 8 hit bodies; got %d and %d." % [soldiers, target_bodies])
		return

	print("SMOKE TEST PASSED: 1000 m × 1000 m terrain, 8 human patrols, patrol AI state.")
	main.queue_free()
	quit(0)
