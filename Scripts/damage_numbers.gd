extends Label

func start_floating(target_dest: Vector2):
	# Ensure size is calculated so pivot_offset works
	await get_tree().process_frame 
	pivot_offset = size / 2
	
	scale = Vector2(0.1, 0.1)
	modulate.a = 0
	
	var tween = create_tween()
	
	# Pop in
	tween.parallel().tween_property(self, "scale", Vector2(1.2, 1.2), 0.1).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.1)
	
	# Float up
	tween.tween_property(self, "global_position", target_dest, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Fade out and shrink
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3).set_delay(0.3)
	tween.parallel().tween_property(self, "scale", Vector2(0.5, 0.5), 0.3).set_delay(0.3)
	
	tween.tween_callback(queue_free)
