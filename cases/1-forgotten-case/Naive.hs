-- A third status was added, and this function wasn't updated.
module Naive where

data Status = Available | Sold | Expired

label :: Status -> String
label Available = "available"
label Sold      = "sold"
