// A price calculation that also writes to the outside world.
pub fn total(prices: &[i64]) -> i64 {
    println!("computing the total");
    prices.iter().sum()
}
