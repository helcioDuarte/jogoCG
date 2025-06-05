extends Node3D

@onready var animTree = $AnimationTree
@onready var animStateMachine = $AnimationTree.get('parameters/playback')
var currentFrame = 0.0

func animationFinished(goal):
	if getState() == goal :
		return 0
	return 1

func animateMovement(velocity, speed):
	if getState() == "idle|walk":
		currentFrame = lerp(currentFrame, velocity.length() / speed, 0.1)
		animTree.set("parameters/idle|walk/blend_position", currentFrame)
	elif getState() == "walk|run":
		currentFrame = lerp(currentFrame, (velocity.length() / speed * 2) - 1, 0.1)
		animTree.set("parameters/walk|run/blend_position", currentFrame)

func changeWalkRun(goal):
	if goal == "run":
		animStateMachine.travel("walk|run")
		if Input.is_action_just_pressed("sprint"):
			currentFrame = -1.0
	elif goal == "walk":
		animStateMachine.travel("idle|walk")

func changeWalkSlash():
	animStateMachine.travel("Slash")

func getState():
	return animStateMachine.get_current_node()
