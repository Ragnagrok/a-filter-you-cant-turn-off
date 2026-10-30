-- The one-word way out: take the first match, whether there is one or not.
module Escape where

data Card = Card { code :: String, balance :: Int }

balanceOf :: String -> [Card] -> Int
balanceOf c cards = balance (head (filter ((== c) . code) cards))
