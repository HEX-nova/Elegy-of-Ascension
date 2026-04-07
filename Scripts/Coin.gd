extends Area2D

@onready var collider = $CollisionPolygon2D

func _on_body_entered(body: Node2D) -> void:
	# Assuming your slime is in a group called "player" 
	# or you just check the name
	if body.is_in_group("Player") :
		# 0. Deactivate the collider to not count multiple times
		collider.set_deferred("disabled", true)
		# 1. Tell the Manager to add money
		GameManager.collect_coin()
		# 2. Play a "collect" sound or effect here if you want!
		 
		# Quick "Pop" effect
		var tween = create_tween()
		tween.tween_property(self, "position", position + Vector2(0, -50), 0.3)
		tween.parallel().tween_property(self, "modulate:a", 0, 0.3)
		tween.tween_callback(queue_free)
