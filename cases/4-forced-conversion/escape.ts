// A value that came from outside, forced into a status.
type Status = "available" | "sold" | "expired";

const labels: Record<Status, string> = {
  available: "Available",
  sold: "Sold",
  expired: "Expired",
};

function fromWire(body: string): Status {
  return JSON.parse(body) as Status;
}

console.log(`label: ${labels[fromWire('"lost"')]}`);
