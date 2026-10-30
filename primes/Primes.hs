-- From the article: generate all the numbers from 2 on, keep the primes, stop at the third.
isPrime :: Int -> Bool
isPrime n = all (\d -> n `mod` d /= 0) [2 .. n - 1]

main :: IO ()
main = print (take 3 . filter isPrime $ [2..])            -- [2,3,5]
