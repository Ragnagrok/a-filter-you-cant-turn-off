// A price calculation that also writes to the outside world.
export function total(prices: number[]): number {
  console.log("computing the total");
  return prices.reduce((a, b) => a + b, 0);
}
