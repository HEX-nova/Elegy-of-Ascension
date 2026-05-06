extends StaticBody2D

# Use an Export so you can set this in the Godot Editor for each shrine instance
# Assuming Element.Type is your enum
@export var shrine_element: Elements.Type

@onready var slab: AnimatedSprite2D = $Slabs

func _ready():
	# Set the initial visual to match the shrine's element
	if slab.sprite_frames.has_animation(str(shrine_element)):
		slab.play(str(shrine_element))

func Interact():
	# The player "tunes" to the shrine's fixed element
	var current_player_element = StatsComponent.element_type
	
	if current_player_element != shrine_element:
		StatsComponent.element_type = shrine_element
		
		# Emit signal so the UI/Player changes color/etc.
		StatsComponent.stats_changed.emit()
		
		print("Player energy resonant with Element: ", shrine_element)
		# Maybe add a "Tuned" sound effect here!
	else:
		print("Already tuned to this resonance.")

func set_element(element: Elements.Type):
	shrine_element = element
	if slab.sprite_frames.has_animation(str(shrine_element)):
		slab.play(str(shrine_element))
