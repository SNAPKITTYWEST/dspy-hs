{-@ type Score01 = { v:Double | 0.0 <= v && v <= 1.0 } @-}

{-@ data Score = ValidScore { scoreValue :: Score01 } | Invalid @-}

{-@ score01 :: Double -> Either DSPyError Score @-}
{-@ reflect validScore @-}
validScore :: Double -> Bool
validScore x = 0.0 <= x && x <= 1.0
