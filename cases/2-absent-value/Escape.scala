// The one-word way out: .get, and throw if there is no such card.
case class Card(code: String, balance: Int)

def balanceOf(code: String, cards: List[Card]): Int =
  cards.find(_.code == code).get.balance
