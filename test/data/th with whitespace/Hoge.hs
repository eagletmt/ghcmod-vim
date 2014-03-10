module Hoge (hoge) where

import Language.Haskell.TH
import Language.Haskell.TH.Quote

hoge :: QuasiQuoter
hoge = QuasiQuoter (litE . stringL) undefined undefined undefined
