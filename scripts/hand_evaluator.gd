extends RefCounted
class_name HandEvaluator

enum HandRank {
	HIGH_CARD,
	PAIR,
	TWO_PAIR,
	THREE_OF_A_KIND,
	STRAIGHT,
	FLUSH,
	FULL_HOUSE,
	FOUR_OF_A_KIND,
	STRAIGHT_FLUSH
}

# CardData.Rank is 0-indexed (ACE=0 ... KING=12), so every non-ace rank is
# one below its true poker value. This helper gives every rank its correct
# value in one place, instead of repeating the ace-check inline everywhere.
static func get_rank_value(card: CardData) -> int:
	if card.rank == CardData.Rank.ACE:
		return 14
	return card.rank + 1


#we will deal with rank related hands first

static func count_ranks(cards: Array) -> Dictionary:
	var rank_counts = {}
	for card in cards:
		var rank_value = get_rank_value(card)
		if rank_counts.has(rank_value):
			rank_counts[rank_value] += 1
		else:
			rank_counts[rank_value] = 1
	return rank_counts

static func check_four_of_a_kind(rank_counts: Dictionary) -> Variant:
	for rank in rank_counts:
		if rank_counts[rank] == 4:
			return [HandRank.FOUR_OF_A_KIND, rank]
	return null   

static func check_full_house(rank_counts: Dictionary) -> Variant:
	var triple_rank = -1
	var pair_rank = -1
	
	for rank in rank_counts:
		if rank_counts[rank] >= 3:
			if triple_rank == -1 or rank > triple_rank:
				triple_rank = rank
	
	for rank in rank_counts:
		if rank == triple_rank:
			continue
		if rank_counts[rank] >= 2:
			if pair_rank == -1 or rank > pair_rank:
				pair_rank = rank
	
	if triple_rank != -1 and pair_rank != -1:
		return [HandRank.FULL_HOUSE, triple_rank, pair_rank]
	return null

static func check_three_of_a_kind(rank_counts: Dictionary) -> Variant:
	var best_rank = -1
	for rank in rank_counts:
		if rank_counts[rank] == 3:
			if rank > best_rank:
				best_rank = rank
	if best_rank != -1:
		return [HandRank.THREE_OF_A_KIND, best_rank]
	return null

static func check_two_pair(rank_counts: Dictionary) -> Variant:
	var pairs = []
	for rank in rank_counts:
		if rank_counts[rank] >= 2:
			pairs.append(rank)
	
	if pairs.size() < 2:
		return null
	
	pairs.sort()
	pairs.reverse()   # highest pair first
	return [HandRank.TWO_PAIR, pairs[0], pairs[1]]

static func check_pair(rank_counts: Dictionary) -> Variant:
	var best_rank = -1
	for rank in rank_counts:
		if rank_counts[rank] >= 2:
			if rank > best_rank:
				best_rank = rank
	if best_rank != -1:
		return [HandRank.PAIR, best_rank]
	return null


#we are dealing with suits realted hands now from here 

static func count_suits(cards: Array) -> Dictionary:
	var suit_counts = {}
	for card in cards:
		if suit_counts.has(card.suit):
			suit_counts[card.suit] += 1
		else:
			suit_counts[card.suit] = 1
	return suit_counts

static func check_flush(cards: Array, suit_counts: Dictionary) -> Variant:
	for suit in suit_counts:
		if suit_counts[suit] >= 5:
			var suited_cards = []
			for card in cards:
				if card.suit == suit:
					suited_cards.append(get_rank_value(card))
			suited_cards.sort()
			suited_cards.reverse()
			return [HandRank.FLUSH, suited_cards[0], suited_cards[1], suited_cards[2], suited_cards[3], suited_cards[4]]
	return null

#Straight detection needs unique sorted ranks and the Ace-low exception this is added here 
static func get_unique_sorted_ranks(cards: Array) -> Array:
	var ranks = {}
	for card in cards:
		ranks[get_rank_value(card)] = true
	var result = ranks.keys()
	result.sort()
	return result


static func check_straight(cards: Array) -> Variant:
	var ranks = get_unique_sorted_ranks(cards)
	
	# ace-low straight check: A-2-3-4-5 (ace counted as 1 here)
	if 14 in ranks and 2 in ranks and 3 in ranks and 4 in ranks and 5 in ranks:
		return [HandRank.STRAIGHT, 5]   # 5-high straight, the weakest straight
	
	# normal straight check: look for 5 consecutive values, highest first
	var i = ranks.size() - 1
	while i >= 4:
		if ranks[i] - ranks[i - 4] == 4:
			return [HandRank.STRAIGHT, ranks[i]]
		i -= 1
	
	return null

static func check_straight_flush(cards: Array, suit_counts: Dictionary) -> Variant:
	for suit in suit_counts:
		if suit_counts[suit] >= 5:
			var suited_cards = []
			for card in cards:
				if card.suit == suit:
					suited_cards.append(card)
			var straight_result = check_straight(suited_cards)
			if straight_result != null:
				return [HandRank.STRAIGHT_FLUSH, straight_result[1]]
	return null

static func check_high_card(cards: Array) -> Array:
	var rank_values = []
	for card in cards:
		rank_values.append(get_rank_value(card))
	rank_values.sort()
	rank_values.reverse()
	return [HandRank.HIGH_CARD, rank_values[0], rank_values[1], rank_values[2], rank_values[3], rank_values[4]]


static func evaluate_hand(cards: Array) -> Array:
	# cards = 7 CardData objects (hole + community)
	# returns something like [HandRank.PAIR, 11, 14, 13, 9]
	# (category, then tiebreaker ranks in descending importance)
	var rank_counts = count_ranks(cards)
	var suit_counts = count_suits(cards)
	
	var result = check_straight_flush(cards, suit_counts)
	if result != null:
		return result
	
	result = check_four_of_a_kind(rank_counts)
	if result != null:
		return result
	
	result = check_full_house(rank_counts)
	if result != null:
		return result
	
	result = check_flush(cards, suit_counts)
	if result != null:
		return result
	
	result = check_straight(cards)
	if result != null:
		return result
	
	result = check_three_of_a_kind(rank_counts)
	if result != null:
		return result
	
	result = check_two_pair(rank_counts)
	if result != null:
		return result
	
	result = check_pair(rank_counts)
	if result != null:
		return result
	
	return check_high_card(cards)

#this is just for the output 
static func hand_rank_to_string(rank: HandRank) -> String:
	match rank:
		HandRank.HIGH_CARD:
			return "High Card"
		HandRank.PAIR:
			return "Pair"
		HandRank.TWO_PAIR:
			return "Two Pair"
		HandRank.THREE_OF_A_KIND:
			return "Three of a Kind"
		HandRank.STRAIGHT:
			return "Straight"
		HandRank.FLUSH:
			return "Flush"
		HandRank.FULL_HOUSE:
			return "Full House"
		HandRank.FOUR_OF_A_KIND:
			return "Four of a Kind"
		HandRank.STRAIGHT_FLUSH:
			return "Straight Flush"
	return "Unknown"
