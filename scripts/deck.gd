extends Node2D


func build_deck():
	var full_deck = []

	for i in range(4):
		for j in range(13):
			var fill_deck = CardData.new()
			fill_deck.suit = i
			fill_deck.rank = j
			full_deck.append(fill_deck)
	return full_deck	

func randomize_deck(full_deck):
	full_deck.shuffle()
	return full_deck
	
