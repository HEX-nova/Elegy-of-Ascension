extends StaticBody2D

@onready var slab: AnimatedSprite2D = $Slabs

func Interact():
	# 1. Cycle the element (0 through 7)
	var current = StatsComponent.element_type
	var next_element = (current + 1) % 8
	StatsComponent.element_type = next_element
	
	# 2. Update the Shrine's own visual
	if slab.sprite_frames.has_animation(str(next_element)):
		slab.play(str(next_element))
	
	# 3. Emit the signal so the UI updates
	StatsComponent.stats_changed.emit()
	
	print("Tuned to Element: ", next_element)
