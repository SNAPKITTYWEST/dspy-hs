module DSPy.Metric
  ( Score(..)
  , score01
  , scoreRatio
  , toDouble
  , Metric(..)
  , exactMatch
  , contains
  , structuredValid
  , composeMetrics
  ) where

import DSPy.Core (DSPyError(..), FieldCodec(..))
import Data.Aeson (Value)
import Data.Text (Text)
import qualified Data.Text as T
import GHC.Generics (Generic)

data Score
  = Score !Double
  | Invalid
  deriving stock (Show, Eq, Generic)

score01 :: Double -> Either DSPyError Score
score01 x
  | x < 0 || x > 1 = Left (ValidationFailure "score out of [0,1]")
  | otherwise = Right (Score x)

scoreRatio :: Integral a => a -> a -> Either DSPyError Score
scoreRatio _ 0 = Left (ValidationFailure "scoreRatio: zero denominator")
scoreRatio n d = score01 (fromIntegral n / fromIntegral d)

toDouble :: Score -> Maybe Double
toDouble (Score x) = Just x
toDouble Invalid = Nothing

data Metric i o = Metric
  { metricName :: !Text
  , metricRun :: i -> o -> o -> Score
  }

exactMatch :: (FieldCodec o) => Metric i o
exactMatch = Metric "exactMatch" $ \_i expected actual ->
  if encodeValue expected == encodeValue actual
    then Score 1
    else Score 0

contains :: Metric i Text
contains = Metric "contains" $ \_i expected actual ->
  if expected `T.isInfixOf` actual then Score 1 else Score 0

structuredValid :: (FieldCodec o) => Metric i o
structuredValid = Metric "structuredValid" $ \_i _expected actual ->
  case decodeValue (encodeValue actual) of
    Right _ -> Score 1
    Left _ -> Invalid

composeMetrics :: [Metric i o] -> Metric i o
composeMetrics ms = Metric "composeMetrics" $ \i e a ->
  let xs = [ metricRun m i e a | m <- ms ]
  in if any (== Invalid) xs
       then Invalid
       else Score (sum [ x | Score x <- xs ] / fromIntegral (length xs))
