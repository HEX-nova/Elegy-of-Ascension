class_name ItemData
extends Resource

enum Type {consumable, key, tradable, weapon, equipment}

@export var name: String = ""
@export var weight: float = 1.0
@export var value: int = 10
@export var quantity : int = 1
@export var icon: Texture2D # For UI later
@export var type : Type = Type.consumable
@export var description : string = ""
