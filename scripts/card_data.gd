extends Resource                                                                
class_name CardData

enum Suit { HEARTS, DIAMONDS, SPADES, CLUBS }                                   
enum Rank { ACE, TWO, THREE, FOUR, FIVE, SIX, SEVEN, EIGHT, NINE, TEN, JACK, QUEEN, KING }

@export var suit: Suit
@export var rank: Rank
