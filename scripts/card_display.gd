extends Node2D

var card_data: CardData


func set_card(data: CardData, pos: Vector2, upright: bool, card_config: int) -> void:
	card_data = data
	var col = data.rank
	var row = data.suit
	$Sprite2D.scale = Vector2(1.05, 1.05)
	$Sprite2D.rotation_degrees=card_config
	if upright:
		$Sprite2D.region_rect=Rect2(col*48, row*64, 48, 64) # here 48 and 64 is lenght and breadth of each card
	else:
		$Sprite2D.region_rect=Rect2(48, 4*64, 48, 64)
	$Sprite2D.position= pos

func reveal() -> void:
	var tween = create_tween()
	tween.tween_property($Sprite2D, "scale:x", 0, 0.12).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(func(): $Sprite2D.region_rect = Rect2(card_data.rank*48, card_data.suit*64, 48, 64))
	tween.tween_property($Sprite2D, "scale:x", 1, 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
