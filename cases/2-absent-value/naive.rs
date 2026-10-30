// Look up a card by its code and use its balance, as if it were always there.
pub struct Card {
    pub code: String,
    pub balance: i64,
}

pub fn balance_of(code: &str, cards: &[Card]) -> i64 {
    cards.iter().find(|card| card.code == code).balance
}
