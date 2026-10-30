// A third status was added, and this function wasn't updated.
export type Status = "available" | "sold" | "expired";

export function label(s: Status): string {
  switch (s) {
    case "available":
      return "available";
    case "sold":
      return "sold";
  }
}
