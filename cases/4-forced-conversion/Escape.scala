// A value that came from outside, forced into a status.
enum Status:
  case Available, Sold, Expired

def fromWire(raw: Any): Status = raw.asInstanceOf[Status]

@main def run(): Unit =
  println(s"status: ${fromWire("lost")}")
