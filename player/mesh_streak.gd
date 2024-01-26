extends MeshInstance3D
class_name MeshStreak

## Creates a streak/ribbon of mesh to make attacks look cooler. It dynamically
## creates a mesh starting at an origin node, plus an bottom offset, to a streak
## top offset position. You can turn it on and off with the bool "actvated".
## It can be triggered using signals to turn on and off, or turn off based on
## lifetime. 
## You can add a custom material for your own colors/textures, etc, or leave
## the field empty to use a default

@onready var mesh_array = []

@export var lifetime = .4
@export var use_end_signal : bool = false
## The node with the signal to start (and perhaps end) mesh streak.
@export var trigger_node : Node
@export var start_trigger_signal : String = "attack_swing_started"
@export var end_trigger_signal : String = "attack_ended"

## Node where the mesh will base it's own origin points.
@export var origin_node: Node3D = self
## Where the bottom of the steak points should start in relation to the origin node.
@export var streak_bottom = Vector3.ZERO
## Where the top of the steak points should end in relation to the origin node.
@export var streak_top = Vector3.UP

## Recommend to turn shading off, and use transparency or glow for a cool look. 
## Leave this empty to use a default white transparent gradient. 
@export var custom_material : StandardMaterial3D 

## a helper counter to reduce how many edges are created.
@onready var counter : int = 0
@onready var activated : bool

## probably not necessary but every edge is it's own class
class edge:
	var top_p : Vector3
	var bottom_p : Vector3

func _ready():
	top_level =  true # don't follow the parent, be independant
	material_check() # if no material is set, create one and add it.
	
	
	if trigger_node:
		trigger_node.connect(start_trigger_signal,_on_start_trigger_signal)
		if use_end_signal:
			trigger_node.connect(end_trigger_signal,_on_end_trigger_signal)
	else:
		printerr("No trigger node assigned to start the mesh streak")
	
	if origin_node == null:
		origin_node = get_parent()

func _on_start_trigger_signal():
	activated = true
	if !use_end_signal:
		await get_tree().create_timer(lifetime).timeout
		activated = false
	
func _on_end_trigger_signal():
	activated = false

func _process(_delta):
	
	if activated:
		counter += 1
		if counter > 1:
			counter = 0
		
		if counter == 0:
			create_edge()
			mesh_update()
	else:
		if mesh_array.size() != 0:
			remove_edge()
			mesh_update()

func mesh_update():
	if mesh_array.size() != 0:
		var surface_tool = SurfaceTool.new()
		surface_tool.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
		surface_tool.set_material(custom_material)

		for each_edge in mesh_array:
			surface_tool.set_uv(Vector2.ZERO)
			surface_tool.add_vertex(each_edge.top_p)
			surface_tool.set_uv(Vector2.RIGHT)
			surface_tool.add_vertex(each_edge.bottom_p)
		mesh = surface_tool.commit()
	
func create_edge():
	var new_top = origin_node.to_global(streak_top)
	var new_bottom = origin_node.to_global(streak_bottom)
	var new_edge = edge.new()
	new_edge.bottom_p = new_bottom
	new_edge.top_p =  new_top
	## to avoid duplicates
	if mesh_array.size() != 0:
		if mesh_array[mesh_array.size() -1] != new_edge:
			mesh_array.append(new_edge)
	else:
		mesh_array.append(new_edge)
	
func remove_edge():
	mesh_array.pop_front()

func material_check(): ## Create a new default material for the streak
	if custom_material == null:
		custom_material = StandardMaterial3D.new()
		custom_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		custom_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		custom_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		var new_grad_texture : GradientTexture1D = GradientTexture1D.new()
		var new_gradient : Gradient = Gradient.new()
		new_gradient.set_color(0,Color(1,1,1,.3))
		new_gradient.set_offset(0,.6)
		new_gradient.set_color(1,Color(1,1,1,0))
		new_gradient.set_offset(1,1)	
		new_grad_texture.gradient = new_gradient
		custom_material.albedo_texture = new_grad_texture
		

