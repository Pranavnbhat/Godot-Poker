extends Node2D

var players: Dictionary
var pot: Pot
var current_turn_seat: int
var betting_seats_order: Array
var current_index: int = 0
var choosing_raise: bool = false
var raise_amount: int = 0

signal round_complete
signal update_chips_text

func start(players_ref: Dictionary, pot_ref: Pot, seats_order: Array):
	players = players_ref
	pot = pot_ref
	betting_seats_order = seats_order
	current_index = 0
	choosing_raise = false
	for seat in seats_order:
		players[seat].played = false
	set_process(true)
	return



func apply_action(seat: int, action: String, amount: int):
	var player = players[seat]
	if action == "fold":
		player.folded = true
		print("Seat ", seat, " folded. Chips now: ", player.chips)
	elif action == "call":
		var amount_to_call= amount- player.current_bet
		player.chips-=amount_to_call
		player.current_bet=amount
		pot.pot+=amount_to_call
		print("Seat ", seat, " called. Chips now: ", player.chips)
	elif action=="raise":
		var to_add=amount - player.current_bet
		if to_add > player.chips:
			amount = player.current_bet + player.chips   # cap the raise at all-in
			to_add = player.chips
		player.chips -= to_add
		player.current_bet = amount
		pot.pot += to_add
		pot.highest_bet = amount
		print("Seat ", seat, " raised. Chips now: ", player.chips)
		
		var seat_who_raised= seat
		
		for i in betting_seats_order:
			if i != seat_who_raised:  
				players[i].played = false
	
	player.played = true
	update_chips_text.emit()



func _process(_delta: float) -> void:
	if not is_betting_round_over():
		var seat = betting_seats_order[current_index]
		var player = players[seat]
		
		if player.is_ai:
			apply_action(seat, "call", pot.highest_bet)
			advance_turn()
			return
		
		
		
		if choosing_raise:                                     
			if Input.is_action_just_pressed("Increase"):
				raise_amount += 10
			elif Input.is_action_just_pressed("Decrease"):
				raise_amount -= 10
			elif Input.is_action_just_pressed("Confirm"):
				apply_action(seat, "raise", raise_amount)
				choosing_raise = false
				advance_turn()
			return
		
		if Input.is_action_just_pressed("Fold"):
			apply_action(seat, "fold", 0)
			advance_turn()

		elif Input.is_action_just_pressed("Check"):  
			apply_action(seat, "call", pot.highest_bet)
			advance_turn()
		
		elif Input.is_action_just_pressed("Raise"):
			choosing_raise = true
			raise_amount = pot.highest_bet + 10
	else: 
		pot.highest_bet = 0
		for seat in betting_seats_order:
			players[seat].current_bet = 0
		set_process(false)
		round_complete.emit()


func is_betting_round_over() -> bool:
	for seat in betting_seats_order:
		if not players[seat].folded and players[seat].played == false:
			return false
	return true
   


func advance_turn() -> void:
	if current_index != betting_seats_order.size() - 1:
		current_index += 1
	else:
		current_index = 0
	
	var seat = betting_seats_order[current_index]
	if players[seat].folded:
		advance_turn()
