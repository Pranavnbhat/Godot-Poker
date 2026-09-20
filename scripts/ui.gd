extends Control


func set_chips(seat: int, chips: int) -> void:
	$Label.text = "Seat %d\n %d" % [seat, chips]
	$Label.add_theme_font_size_override("font_size", 6)
