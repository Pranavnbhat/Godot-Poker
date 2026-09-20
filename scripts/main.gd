extends Node2D


var deck
var player_count=8
var betting_order: Array


var starting_seat=0

enum GameState { PREFLOP, FLOP, TURN, RIVER, SHOWDOWN }
var current_state: GameState = GameState.PREFLOP



var card_display_scene = preload("res://scenes/CardDisplay.tscn")




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$BettingRound.round_complete.connect(_on_betting_round_complete)
	$Dealer.community_cards_dealt.connect(_on_community_cards_dealt)
	$Dealer.round_over.connect(_on_round_over)
	$Dealer.game_over.connect(_on_game_over)
	$BettingRound.update_chips_text.connect(_on_update_chips_text)
	start_round()
	

var players = {}  

func create_players() -> void:
	if players.size() > 0:
		return  # players already exist, don't recreate them
	var active_seats = $Dealer.seat_positions[player_count]
	for seat in active_seats:
		var p = PlayerData.new()
		p.current_seat = seat
		p.chips = 1000
		p.hand = []
		p.is_ai = (seat != 0)
		players[seat] = p

func reset_for_new_round() -> void:
	for seat in players:
		players[seat].hand = []
		players[seat].current_bet = 0
		players[seat].folded = false
		players[seat].best_hand_result = []

var pot = Pot.new()


func start_round():
	$Dealer.clear_table()
	deck = $Deck.build_deck()
	deck = $Deck.randomize_deck(deck)
	
	reset_for_new_round()
	create_players()
	
	pot.pot = 0
	pot.highest_bet = 0
	current_state = GameState.PREFLOP   
	
	betting_order = $Dealer.post_blinds(players, player_count, starting_seat, pot)
	$Dealer.deal_cards(deck, player_count, starting_seat, players)
	$BettingRound.start(players, pot, betting_order) 
	
	if starting_seat!=player_count-1:
		starting_seat+=1
	else:
		starting_seat=0


func _on_betting_round_complete():
	current_state += 1
	match current_state:
		GameState.FLOP:
			$Dealer.deal_flop_community_cards(deck)
		GameState.TURN:
			$Dealer.deal_turn_community_cards(deck)
		GameState.RIVER:
			$Dealer.deal_river_community_cards(deck)
		GameState.SHOWDOWN:
			$Dealer.run_showdown(players, pot)

func _on_round_over():
	start_round()

func _on_game_over():
	pass   # game has ended, nothing further happens 

func _on_community_cards_dealt():
	$BettingRound.start(players, pot, betting_order)

func _on_update_chips_text():
		$Dealer.display_chip_text(player_count, players)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Click"):
		start_round()
	
