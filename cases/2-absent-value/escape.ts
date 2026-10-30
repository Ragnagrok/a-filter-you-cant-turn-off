// The one-character way out: "!", I promise it's there.
export interface Card {
  code: string;
  balance: number;
}

export function balanceOf(code: string, cards: Card[]): number {
  return cards.find((card) => card.code === code)!.balance;
}
