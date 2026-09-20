extends Node2D



var card_display_scene = preload("res://scenes/CardDisplay.tscn")
var ui_scene=preload("res://scenes/UI.tscn")




var seat_positions ={
	2: [0, 4],
	3: [0, 3, 5],
	4: [7, 1, 3, 5],
	5: [0, 1, 3, 5, 7],
	6: [7, 1, 2, 3, 5, 6],
	7: [0, 1, 2, 3, 5, 6, 7],
	8: [0, 1, 2, 3, 4, 5, 6, 7],
}

var seat_coords = [
	Vector2(592,515),  # 0 bottom-mid
	Vector2(330,515),  # 1 bottom-left
	Vector2(170,380),  # 2 left curve
	Vector2(330,177),  # 3 top-left
	Vector2(592,177),  # 4 top-mid
	Vector2(930,177), # 5 top-right
	Vector2(1100,380), # 6 right curve
	Vector2(930,515), # 7 bottom-right
]

var card_rotation = [
	0,
	0,
	90,
	180,
	180, 
	180,
	270,
	0
]	

var card_offsets=[
	Vector2(48,0),
	Vector2(48,0),
	Vector2(0,-48),
	Vector2(48,0),
	Vector2(48,0),
	Vector2(48,0),
	Vector2(0,-48),
	Vector2(48,0),
	]

var chip_text_offsets=[
	Vector2(80,0),
	Vector2(80,0),
	Vector2(50,-50),
	Vector2(80,0),
	Vector2(80,0),
	Vector2(80,0),
	Vector2(-130,-50),
	Vector2(80,0),
	]



@warning_ignore("shadowed_variable")
func deal_cards(deck:Array, player_count:int, starting_seat:int, players: Dictionary)->void:
	
	var active_seats= seat_positions[player_count]
	var ordered_seats= active_seats.slice(starting_seat, active_seats.size()) + active_seats.slice(0, starting_seat)
	var new_card=card_display_scene.instantiate() 
	
	
	#we deal one card for each person first thats pass 1 second card in pass 2 hence range is 2 
	for i in range (2):     
		for seat_index in ordered_seats:
			await get_tree().create_timer(0.3).timeout
			new_card=card_display_scene.instantiate()
			
			#position of second card should be offset from first 
			var pos: Vector2
			if i==0:	
				pos=seat_coords[seat_index]
			else:	
				pos=seat_coords[seat_index]+card_offsets[seat_index]
			
			
			var card_config= card_rotation[seat_index]
			
			
			#all cards in seats 0 and 7 (if there are no 0th seats) have to show upright cards
			var upright=false
			if seat_index==0 or (seat_index==7 and 0 not in ordered_seats):
				upright=true 
			else:	upright=false
			
			
			add_child(new_card)
			#to track which player has what cards
			if not player_card_nodes.has(seat_index):
				player_card_nodes[seat_index] = []
			player_card_nodes[seat_index].append(new_card)
			
			var dealt_card=deck[0]
			new_card.set_card(deck[0], pos, upright, card_config)
			deck.pop_front()
			
			players[seat_index].hand.append(dealt_card)




func post_blinds(players: Dictionary, player_count: int, starting_seat: int, pot: Pot):
	var active_seats = seat_positions[player_count]
	var ordered_seats = active_seats.slice(starting_seat, active_seats.size()) + active_seats.slice(0, starting_seat)
	
	var small_blind_seat = ordered_seats[0]
	var big_blind_seat = ordered_seats[1]
	
	players[small_blind_seat].chips -= 10
	players[small_blind_seat].current_bet = 10
	print("Seat ", small_blind_seat, " posted a small blind. Chips now: ", players[small_blind_seat].chips)
	
	
	players[big_blind_seat].chips -= 20
	players[big_blind_seat].current_bet = 20
	print("Seat ", big_blind_seat, " posted a big blind blind. Chips now: ", players[big_blind_seat].chips)
	
	pot.pot += 30
	pot.highest_bet = 20
	
	var betting_seats_order = ordered_seats.slice(2, ordered_seats.size()) + ordered_seats.slice(0, 2)
	return betting_seats_order
	


var community_pos: Vector2= Vector2(500,350)
var current_community_cards: Array= []
var player_card_nodes: Dictionary = {}
var chip_labels: Dictionary = {}


func wait_sec(sec: float):
	await get_tree().create_timer(sec).timeout
	

signal community_cards_dealt
signal round_over
signal game_over

func deal_flop_community_cards(deck: Array):
	for i in range(3):
		await wait_sec(.3)
		var new_card=card_display_scene.instantiate()
		new_card.set_card(deck[0], community_pos, true, 0) 
		current_community_cards.append(deck[0])
		add_child(new_card)     
		deck.pop_front()
		community_pos.x+=48
	community_cards_dealt.emit()	
 

func deal_turn_community_cards(deck: Array):
	await wait_sec(0.3)
	var new_card = card_display_scene.instantiate()
	new_card.set_card(deck[0], community_pos, true, 0)
	current_community_cards.append(deck[0])
	add_child(new_card)
	deck.pop_front()
	community_pos.x += 48
	community_cards_dealt.emit()

func deal_river_community_cards(deck: Array):
	await wait_sec(0.3)
	var new_card = card_display_scene.instantiate()
	new_card.set_card(deck[0], community_pos, true, 0)
	current_community_cards.append(deck[0])
	add_child(new_card)
	deck.pop_front()
	community_pos.x += 48
	community_cards_dealt.emit()

func run_showdown(players: Dictionary, pot: Pot):
	var combined_hands = {}   
	for seat in players:
		var player = players[seat]
		if not player.folded:
			combined_hands[seat] = player.hand+current_community_cards
			reveal_hand(seat)
	
	var best_seat = -1
	var best_result = []
	
	for seat in combined_hands:
		var result = HandEvaluator.evaluate_hand(combined_hands[seat])
		players[seat].best_hand_result = result   # store it for later display
		
		if best_seat == -1 or result > best_result:
			best_seat = seat
			best_result = result
	
	print("Seat ", best_seat, " wins with hand: ", HandEvaluator.hand_rank_to_string(best_result[0]))
	players[best_seat].chips += pot.pot
	print("Seat ", best_seat, " wins ", pot.pot, " chips. Chips now: ", players[best_seat].chips)
	pot.pot = 0
	highlight_winner(best_seat)
	
	
	#checks for new round from here 
	var players_with_chips = []
	for seat in players:
		if players[seat].chips > 0:
			players_with_chips.append(seat)
	
	if players_with_chips.size() <= 1:
		if players_with_chips.size() == 1:
			print("Player at seat ", players_with_chips[0], " has won the game!")
		game_over.emit()
	else:
		await wait_sec(5)
		round_over.emit()

func reveal_hand(seat: int) -> void:
	for card_node in player_card_nodes[seat]:
		card_node.reveal()
func highlight_winner(seat: int) -> void:
	for card_node in player_card_nodes[seat]:
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(card_node, "modulate", Color(0.85, 0.65, 0.13), 0.5)

func clear_table():
	for child in get_children():
		child.queue_free()
	community_pos = Vector2(500, 350) 
	current_community_cards = []  
	player_card_nodes = {}
	chip_labels = {}
	

func display_chip_text(player_count: int, players: Dictionary ):
	for old_label in chip_labels:
		chip_labels[old_label].queue_free()
	chip_labels = {}
	
	var seats= seat_positions[player_count]
	for seat_index in seats:
		var player_chips_text=ui_scene.instantiate()
		add_child(player_chips_text)
		
		player_chips_text.set_chips(seat_index, players[seat_index].chips)
		var text_pos=seat_coords[seat_index]+chip_text_offsets[seat_index]
		player_chips_text.position=text_pos
		chip_labels[seat_index] = player_chips_text
		
