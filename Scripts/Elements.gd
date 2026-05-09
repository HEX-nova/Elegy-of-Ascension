# Elements.gd (Global Autoload)
extends Node

enum Type { GLACIA, FLORA, AQUA, MAGMA, TERRA, AERA, ELECTRA, NHLM }

# Rows = DEFENDER (The one getting hit) | Cols = ATTACKER (The source)
var resonance_matrix = [
	[0.0,  0.5,    1.0,   2.0,  1.0,  1.0,   2.0,   2.0], 
	[2.0,  0.0,    0.5,   2.0,  1.0,  0.5,   2.0,   2.0], 
	[1.0,  2.0,    0.0,   0.5,  1.0,  1.0,   2.0,   2.0], 
	[0.5,  0.5,    2.0,   0.0,  2.0,  1.0,   2.0,   2.0], 
	[1.0,  1.0,    1.0,   0.5,  0.0,  2.0,   2.0,   2.0], 
	[1.0,  2.0,    1.0,   1.0,  0.5,  0.0,   2.0,   2.0], 
	[0.5,  0.5,    0.5,   0.5,  0.5,  0.5,   0.0,   2.0], 
	[0.0,  0.0,    0.0,   0.0,  0.0,  0.0,   2.0,   0.0]  
]

# Data from your latest screenshot
var statistics_matrix = [
	[100.0, 50.0, 50.0, 100.0, 50.0, 25.0, 100.0, 100.0], # Row 0: Attack
	[50.0, 50.0, 25.0, 25.0, 100.0, 50.0, 25.0, 25.0],    # Row 1: Defense
	[10.0, 25.0, 25.0, 10.0, 10.0, 10.0, 10.0, 10.0],     # Row 2: Extra Health / lvl
	[10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 25.0, 10.0],     # Row 3: Extra Mana / lvl
	[5.0, 10.0, 10.0, 10.0, 10.0, 10.0, 25.0, 10.0],      # Row 4: Extra Stamina / lvl
	[5.0, 3.0, 5.0, 5.0, 5.0, 7.0, 7.0, 7.0],             # Row 5: Attack Speed
	[1.0, 1.0, 1.0, 1.0, 0.5, 1.0, 1.5, 1.5],             # Row 6: Movement Speed
	[1.0, 1.0, 1.0, 0.5, 2.0, 0.5, 0.5, 0.5],             # Row 7: Weight attribute
	[1.0, 2.0, 2.0, 1.0, 1.0, 1.0, 1.0, 2.0],             # Row 8: Health regeneration
	[2.0, 1.0, 1.0, 2.0, 1.0, 1.0, 2.0, 1.0],             # Row 9: Mana regeneration
	[1.0, 1.0, 1.0, 1.0, 2.0, 2.0, 2.0, 1.0]              # Row 10: Stamina regeneration
]

func get_multiplier(attacker_type: int, defender_type: int) -> float:
	return resonance_matrix[defender_type][attacker_type]

# Helper to grab base stats for Tun or Enemies
func get_stat(stat_index: int, element_type: int) -> float:
	return statistics_matrix[stat_index][element_type]
