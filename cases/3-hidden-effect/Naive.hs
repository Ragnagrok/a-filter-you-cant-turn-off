-- A price calculation that also writes to the outside world.
module Naive where

total :: [Int] -> Int
total prices = do
  putStrLn "computing the total"
  pure (sum prices)
