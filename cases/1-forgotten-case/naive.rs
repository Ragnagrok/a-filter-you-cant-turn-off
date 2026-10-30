// A third status was added, and this function wasn't updated.
pub enum Status {
    Available,
    Sold,
    Expired,
}

pub fn label(s: Status) -> &'static str {
    match s {
        Status::Available => "available",
        Status::Sold => "sold",
    }
}
