extends CanvasLayer

@onready var screen_fade: ColorRect = $ScreenFade

func fade_to_black(duration: float = 0.5) -> void:
	var tween = create_tween()
	tween.tween_property(screen_fade, "modulate:a", 1.0, duration)
	await tween.finished

func fade_from_black(duration: float = 0.5) -> void:
	var tween = create_tween()
	tween.tween_property(screen_fade, "modulate:a", 0.0, duration)
	await tween.finished
