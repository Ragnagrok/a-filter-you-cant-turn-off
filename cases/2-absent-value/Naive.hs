-- Look up a card by its code and use its balance, as if it were always there.
module Naive where

import Data.List (find)

data Card = Card { code :: String, balance :: Int }

balanceOf :: String -> [Card] -> Int
balanceOf c cards = balance (find ((== c) . code) cards)
