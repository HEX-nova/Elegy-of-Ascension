extends CPUParticles2D

@export var x_variation : float
@export var y_variation : float
@export var particles : CPUParticles2D = self
var time = 0

func _process(delta: float) -> void:
	time += delta
	particles.gravity = Vector2(x_variation * sin(time), y_variation * sin(time))
