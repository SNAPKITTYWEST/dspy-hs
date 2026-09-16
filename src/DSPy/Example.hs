module DSPy.Example
  ( Example(..)
  , Dataset(..)
  , emptyDataset
  , addExample
  , datasetSize
  ) where

import DSPy.Core (FieldCodec(..), DSPyError(..))
import Data.Aeson (Value)
import Data.Text (Text)

data Example i o = Example
  { exampleInput :: !i
  , exampleOutput :: !o
  , exampleLabel :: !(Maybe Text)
  , exampleMetadata :: !Value
  }

newtype Dataset i o = Dataset { unDataset :: [Example i o] }

emptyDataset :: Dataset i o
emptyDataset = Dataset []

addExample :: Example i o -> Dataset i o -> Dataset i o
addExample e (Dataset xs) = Dataset (e : xs)

datasetSize :: Dataset i o -> Int
datasetSize (Dataset xs) = length xs
