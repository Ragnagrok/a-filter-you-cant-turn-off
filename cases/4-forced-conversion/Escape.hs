-- A number that came from outside, forced into a status.
module Escape where

import Unsafe.Coerce (unsafeCoerce)

data Status = Available | Sold | Expired

fromWire :: Int -> Status
fromWire raw = unsafeCoerce raw
