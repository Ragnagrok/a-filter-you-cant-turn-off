// Look up a card by its code and use its balance, as if it were always there.
export interface Card {
  code: string;
  balance: number;
}

export function balanceOf(code: string, cards: Card[]): number {
  return cards.find((card) => card.code === code).balance;
}
