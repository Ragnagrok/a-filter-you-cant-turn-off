// The one-word way out: unwrap, and panic if there is no such card.
pub struct Card {
    pub code: String,
    pub balance: i64,
}

pub fn balance_of(code: &str, cards: &[Card]) -> i64 {
    cards.iter().find(|card| card.code == code).unwrap().balance
}
