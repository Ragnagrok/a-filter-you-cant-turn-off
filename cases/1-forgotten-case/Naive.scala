// A third status was added, and this function wasn't updated.
enum Status:
  case Available, Sold, Expired

def label(s: Status): String = s match
  case Status.Available => "available"
  case Status.Sold      => "sold"
