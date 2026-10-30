-- The back door: run the effect anyway and pretend the function is pure.
module Escape where

import System.IO.Unsafe (unsafePerformIO)

total :: [Int] -> Int
total prices = unsafePerformIO $ do
  putStrLn "computing the total"
  pure (sum prices)
