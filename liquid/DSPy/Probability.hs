{-@ type Probability = { v:Double | 0.0 <= v && v <= 1.0 } @-}

{-@ mkProbability :: Double -> Maybe Probability @-}
mkProbability :: Double -> Maybe Double
mkProbability x
  | 0 <= x && x <= 1 = Just x
  | otherwise = Nothing
