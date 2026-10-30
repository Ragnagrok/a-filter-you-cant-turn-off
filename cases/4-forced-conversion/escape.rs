// A number that came from outside, forced into a status.
#[repr(u8)]
pub enum Status {
    Available,
    Sold,
    Expired,
}

pub fn from_wire(raw: u8) -> Status {
    unsafe { std::mem::transmute::<u8, Status>(raw) }
}
