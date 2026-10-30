// The Java way out: return null when there is no such card.
case class Card(code: String, balance: Int)

def findCard(code: String, cards: List[Card]): Card =
  cards.find(_.code == code).getOrElse(null)
