// A price calculation that also writes to the outside world.
def total(prices: List[Int]): Int =
  println("computing the total")
  prices.sum
