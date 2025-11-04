# Special startup for level 9 (the portal level)

extends Node2D

func _ready():
	# Start with portals hidden/disabled, and interactable visible
	$PortalEntrance.visible = false
	$PortalEntrance.monitoring = false
	$PortalExit.visible = false
	$Interactable.visible = true
