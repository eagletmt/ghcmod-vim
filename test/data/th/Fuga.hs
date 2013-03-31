{-# LANGUAGE TemplateHaskell, QuasiQuotes #-}
module Fuga (fuga, piyo) where
import Hoge (hoge)

fuga :: String
fuga = [hoge|
hoge
fuga
piyo
|]

piyo :: String
piyo = [hoge| hoge fuga piyo |]
