// Look up a card by its code and use its balance, as if it were always there.
case class Card(code: String, balance: Int)

def balanceOf(code: String, cards: List[Card]): Int =
  cards.find(_.code == code).balance
