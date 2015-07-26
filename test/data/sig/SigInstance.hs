module SigInstance where

newtype D = D (Int,String)

class C a where
    cInt :: a -> Int
    cString :: a -> String

instance C D where
