// From the article: generate all the numbers from 2 on, keep the primes, stop at the third.
fn is_prime(n: u64) -> bool {
    (2..n).all(|d| n % d != 0)
}

fn main() {
    let primes: Vec<u64> = (2..).filter(|&n| is_prime(n)).take(3).collect();
    println!("{primes:?}"); // [2, 3, 5]
}
